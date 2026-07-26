# ToonAge — Architecture

**What this document is:** a description of the code that exists, generated from the TOC and verified against source on 2026-07-25.

**What it is not:** a roadmap. Planned work lives in `IMPROVEMENT_PLAN.md`. Anything in this file that is not yet built is confined to §9 and explicitly labelled.

> **Rule for editing this file.** Every claim here should be checkable with one `grep`. If you are describing something you intend to build, it goes in `IMPROVEMENT_PLAN.md` or §9 — never in the body. The previous version of this document described nine files that did not exist, which cost real debugging time.

**Scale:** 78 files loaded by the TOC · 51 registered modules · ~35,700 lines Lua · Interface 120007 (Midnight 12.0.x PTR)
**Dependencies:** LibStub only. No Ace, no HereBeDragons, no TomTom. Zero hard runtime dependencies, by design.

---

## 1. Load order and boot sequence

The TOC load order matters and is not alphabetical:

```
Libs/LibStub.lua
Core/         Init → Utils → GuideManager → UI → UIModern → MinimapButton
Data/         static tables, then Data/Guides/TAG_*.lua
Modules/      TalentsHelpers, DevHelpers, ErrorLog first, then the rest
```

`Core/Init.lua` must load first — it creates the `ToonAge` global and `TA:RegisterModule`, which every subsequent file calls at load time. `Core/Utils.lua` must precede all modules, since most bind `local U = TA.Utils` at file scope.

Boot is driven by two one-shot events in `Init.lua`:

| Event | Action |
|---|---|
| `ADDON_LOADED` | Unregisters itself. SavedVariables are not reliable yet — nothing else happens here. |
| `PLAYER_ENTERING_WORLD` | Unregisters itself, calls `TA:OnLogin()`. |

`TA:OnLogin()` runs in this order: `InitDB()` → profession snapshot → `InitModules()` → `InitUI()` → `InitMinimap()` → `ApplyLayout()` → slash command registration. The ordering is load-bearing: `ApplyLayout` reparents `Arrow.frame` and `QuestTracker.window`, so it must run after both `InitModules` and `InitUI`.

---

## 2. The module contract

```lua
local TA = ToonAge
local U  = TA.Utils
local M  = {}
TA:RegisterModule("MyModule", M)
```

A module may implement any of four optional entry points:

| Method | Called by | Purpose |
|---|---|---|
| `M:Init()` | `TA:InitModules()` at login | Setup, event registration, frame creation |
| `M:OnEvent(event, ...)` | `TA:UpdateModules()` | Event handling |
| `M:Render(content, sidebar)` | `UI:SetTab()` | Draw this module's tab |
| `M.SlashCommands` | `TA:SlashCommand()` | Table of `name → function(mod, args)` |

**Both `Init` and `OnEvent` are wrapped in `pcall` by `Init.lua`** (lines ~149 and ~163). A module that throws is logged to `TA.ErrorLog` and disabled for that call, never crashing the addon. This is why the registry in §4 lists an interface column — it tells you which hooks a module actually uses.

Modules are toggled via `TA.db.modules[name]`; a module set to `false` gets `_disabled = true` and is skipped by both `InitModules` and `UpdateModules`. Only 11 of 51 modules are currently toggleable (see `DB_DEFAULTS.modules` in `Init.lua`).

---

## 3. Event dispatch

Most events funnel through a single frame, `TA.eventFrame`. Two sources register on it:

1. **`PERSISTENT_EVENTS`** in `Init.lua` — 16 events registered at file load.
2. **Individual modules** in their `Init()` — roughly 28 more, e.g. QuestTracker's nine quest events, `Gear.lua`'s `INSPECT_READY`, `XPTracker`'s `PLAYER_XP_UPDATE`.

Both land in the same handler, which does:

```lua
TA:UpdateModules(event, ...)   -- fan out to all enabled modules with an OnEvent
TA:QueueUIRefresh(event)       -- coalesced UI rebuild
```

**`QueueUIRefresh` is the debounce layer** (`Init.lua`). `UI:Refresh` tears down and rebuilds the entire active tab, and some events are high-frequency — `BAG_UPDATE` fires once per bag per change. Events are collected into a set and flushed once via `C_Timer.After(0.15, ...)`. If the panel is closed the event is dropped outright.

`UI:Refresh` then decides whether the batch warrants a rebuild, using a three-way test in `Core/UI.lua`:

1. Event claimed by the **active tab** (`TAB_EVENTS`) → rebuild.
2. Event in **`UI_IRRELEVANT`** (nameplate churn, cinematics, combat enter/leave, death/res) → skip.
3. Event **unaccounted for** → rebuild.

Rule 3 is deliberate and must be preserved. Because modules register their own events, the set reaching `Refresh` is larger than `PERSISTENT_EVENTS` and grows whenever a module is added. A strict allow-list would silently stop refreshing a tab the day someone registers a new event. Unknown means "assume it matters."

**Two modules opt out of this dispatcher entirely** and own private event frames: `DungeonGuide.lua` (`PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `ENCOUNTER_START`/`_END`, `PLAYER_SPECIALIZATION_CHANGED`) and `FarmOptimizer.lua` (`LOOT_OPENED`, combat enter/leave, `ZONE_CHANGED_NEW_AREA`, `PLAYER_LEAVING_WORLD`, `SKILL_LINES_CHANGED`). Their events never reach `UpdateModules` or `QueueUIRefresh`, so they are also outside the `pcall` safety net that wraps every registered module's `OnEvent`. Worth knowing when debugging: an error in either module's handler surfaces as a raw Lua error, not an `ErrorLog` entry.

---

## 4. Module registry

Verified from source. **I** = has `Init`, **E** = has `OnEvent`, **R** = has `Render` (i.e. owns a tab), **S** = has `SlashCommands`.

### Guide, navigation, and questing

| Module | File | LOC | | Purpose |
|---|---|--:|---|---|
| QuestTracker | `QuestTracker.lua` | 3673 | IERS | Floating tracker window, live objectives, fast-forward sync, auto-quest |
| Arrow | `Arrow.lua` | 839 | IS | Draggable, scroll-to-resize, right-click-lockable HUD arrow |
| NavHud | `NavHud.lua` | 563 | IS | FarmHud-style transparent rotated HUD overlay |
| GuideImporter | `GuideImporter.lua` | 545 | IES | Discovers quest chains from installed BtWQuests expansion modules |
| GuideContextMenu | `GuideContextMenu.lua` | 468 | I | Guide switching via native Blizzard UI integration |
| GuideParser | `GuideParser.lua` | 383 | IS | Validates `TA.GuideData` at load, builds `TA.Guides` |
| GuideBrowser | `GuideBrowser.lua` | 331 | IES | Expansion → zone shelf for selecting guides |
| CoordResolver | `CoordResolver.lua` | 328 | IES | Coordinate resolution and fallback |
| AntTrail | `AntTrail.lua` | 281 | IES | Breadcrumb path of upcoming steps |
| MapPins | `MapPins.lua` + `.xml` | 235 | IS | World map pin overlay for step waypoints |
| TravelRouter | `TravelRouter.lua` | 323 | IES | Cross-zone route planning |
| TravelModes | `TravelModes.lua` | 37 | I | Mount-speed helper consumed by `Arrow.lua` for ETA |
| SpecAdaptive | `SpecAdaptive.lua` | 101 | IS | Injects role/spec-dependent step suggestions |
| DeathRecovery | `DeathRecovery.lua` | 155 | IES | Post-death resurrection guidance |
| Retrospective | `Retrospective.lua` | 141 | IS | "What did I miss" when out-levelling a zone |
| CutsceneSkip | `CutsceneSkip.lua` | 98 | IE | Auto-skips in-engine and movie cutscenes |

### Character, gear, and combat

| Module | File | LOC | | Purpose |
|---|---|--:|---|---|
| Gear | `Gear.lua` | 1345 | IER | Stat-weight evaluation, caching, PvE/PvP persistence, enchant audit |
| Talents | `Talents.lua` | 1178 | ER | Role-aware talent advisor with match scoring |
| Rotation | `Rotation.lua` | 846 | IERS | Spell priority list, drag-to-bar, prediction |
| TalentsPvP | `TalentsPvP.lua` | 720 | IERS | PvP talent advisor via `C_Traits` |
| CombatState | `CombatState.lua` | 596 | IES | Combat state snapshot feeding rotation highlighting |
| Character | `Character.lua` | 513 | ER | 3D portrait, stat breakdown with weights |
| GearSets | `GearSets.lua` | 373 | IE | Named equipment profiles with auto-swap |
| RoleMorph | `RoleMorph.lua` | 355 | IES | Per-role camera, nameplate, and CVar morphing |
| AutoEquip | `AutoEquip.lua` | 345 | IE | Auto-equips ilvl upgrades on loot |
| TooltipScorer | `TooltipScorer.lua` | 285 | I | Hooks `GameTooltip`/`ItemRefTooltip`, appends stat-weight score |
| TargetMarker | `TargetMarker.lua` | 253 | IES | Quest-objective icons above nameplates (pooled frames) |
| NameplateObjectives | `NameplateObjectives.lua` | 245 | IES | Quest objective markers on nameplates |
| PullPlanner | `PullPlanner.lua` | 187 | IES | Clusters nearby kill-objective mobs for AoE pulls |
| DungeonGear | `DungeonGear.lua` | 185 | IS | Cross-references weakest slots against dungeon loot |
| DungeonTalents | `DungeonTalents.lua` | 182 | IES | Recommends talent swaps on dungeon entry |
| QuestRewardAdvisor | `QuestRewardAdvisor.lua` | 368 | IE | Stat-weight scores on quest reward items at `QUEST_COMPLETE` |

> `TargetMarker` and `NameplateObjectives` overlap in scope; both draw custom textures on nameplates. Neither calls `SetRaidTarget` — that was a deliberate decision, documented in `TargetMarker.lua:12–14`, to avoid interfering with other players' raid marks.

### Progression, collections, and endgame

| Module | File | LOC | | Purpose |
|---|---|--:|---|---|
| Pets | `Pets.lua` | 901 | IER | Pet journal and collection tracking |
| AltQuickStart | `AltQuickStart.lua` | 725 | IS | "Quick Start" panel for alts |
| Weekly | `Weekly.lua` | 496 | IRS | Great Vault progress via `C_WeeklyRewards` |
| Delves | `Delves.lua` | 471 | ER | Brann advisor + delve tier progression |
| DungeonGuide | `DungeonGuide.lua` | 466 | IE | Boss strategies on instance transition |
| Professions | `Professions.lua` | 355 | ER | Renders from `Data/Professions_Data.lua` |
| AltTracker | `AltTracker.lua` | 337 | IRS | Multi-character task grid |
| XPTracker | `XPTracker.lua` | 268 | IES | XP/hour and level-up ETA |
| ProfQuesting | `ProfQuesting.lua` | 132 | IES | Surfaces profession nodes along the guide route |
| SocialAwareness | `SocialAwareness.lua` | 121 | IES | Detects friends/guildmates questing nearby |
| RestOptimizer | `RestOptimizer.lua` | 69 | IES | Rested XP tracking and stop-point suggestions |

### Farming and gathering

| Module | File | LOC | | Purpose |
|---|---|--:|---|---|
| FarmOptimizer | `FarmOptimizer.lua` | 750 | I | Real-time farming optimizer logic |
| FarmOptimizerHUD | `FarmOptimizerHUD.lua` | 540 | IS | UI layer for the above |
| GatherTracker | `GatherTracker.lua` | 261 | IES | Records node positions on `LOOT_OPENED` |

### Infrastructure

| Module | File | LOC | | Purpose |
|---|---|--:|---|---|
| Settings | `Settings.lua` | 615 | IRS | Unified settings panel |
| DevHelpers | `DevHelpers.lua` | 482 | IE | `/taquestscan`, `/tacoord`, quest recorder |
| ErrorLog | `ErrorLog.lua` | 238 | IS | Persistent error capture, 200 entries |
| Onboarding | `Onboarding.lua` | 221 | IS | First-login experience |
| AutoMount | `AutoMount.lua` | 260 | IES | Mounts after `PLAYER_REGEN_ENABLED` outdoors |

### Files that participate without registering

Beyond the `Core/` framework files (`Init`, `Utils`, `UI`, `UIModern`, `MinimapButton`), exactly two TOC-loaded files export functionality without going through `RegisterModule`. Verified with `grep -L "RegisterModule" Modules/*.lua`, which returns only the first:

- **`Modules/TalentsHelpers.lua`** (562 LOC) — exports `TA.TalentsAPI`. Blizzard import-string decoder and shared talent utilities. Loaded early because `Talents` and `TalentsPvP` depend on it.
- **`Core/GuideManager.lua`** (168 LOC) — exports `TA.GuideManager`, 13 public methods. **Currently has zero consumers.** See §8.

Consequence worth knowing: neither gets the `pcall` wrapper that `InitModules`/`UpdateModules` provide, because neither has an `Init` or `OnEvent` the dispatcher can see.

---

## 5. Data layer

Everything under `Data/` is static tables, no executable logic, regenerable from `Tools/`.

| File | LOC | Contents |
|---|--:|---|
| `Rotations.lua` | 1422 | Rotation priority per spec |
| `Professions_Data.lua` | 888 | Profession trees, gear slots, quality thresholds |
| `Talents.lua` | 585 | Build data for all 39 specs |
| `Pets.lua` | 334 | Pet families, tameable pets by zone, class summons |
| `StatWeights.lua` | 345 | Per-spec PvE and PvP stat weights |
| `Zones.lua` | 321 | **Season 1 item-level track data** — `Z.TYPE`, `Z.TRACKS`, `Z.READINESS`, `Z.UPGRADE_SOURCES`. The filename is misleading: it holds gear-progression breakpoints (keyed by map in places), *not* zone geography or portals. `.rules.md` currently tells you to update this file with "mapIDs and portal connections" — that instruction is wrong; see the note below. |
| `TalentsPvP.lua` | 297 | PvP node recommendations |
| `Dungeons.lua` | 185 | Boss strategies, consumed by `DungeonGuide` |
| `FarmOptimizer_Data.lua` | 137 | Farming route and node data |
| `Spells.lua` | 104 | Spell IDs |
| `TA_Enchants.lua` | 30 | Enchant → profession mapping |

> **The portal database is not in `Data/`.** It lives in `TravelRouter.PORTALS`, a large literal table at the top of `Modules/TravelRouter.lua`. That breaks the project's own static-data-lives-in-`Data/` separation principle, and it is why `.rules.md`'s "update `Data/Zones.lua` with new mapIDs and portal connections" points at the wrong file. Moving it to `Data/Portals.lua` is the clean fix. **It also currently contains wrong map IDs — see §8.6.**

### Guide schema (v2)

```lua
TA.GuideData["zone_id"] = {
    id, title, zone, minLevel, maxLevel, faction, nextGuide, expansion,
    steps = {
        { type, text, questID, coord = { map, x, y }, objectiveIndex,
          range, spec, class, race, faction, minLevel, questItem,
          reward, noArrow, optional,
          precondition = { questID, questComplete } },
    },
}
```

Step types: `pickup`, `turnin`, `quest`, `travel`, `action`, `npc`, `text`, `item`, `accept`.

`GuideParser` validates `TA.GuideData` at load and builds `TA.Guides`. Guide selection is `QuestTracker:AutoSelectGuide()`, which tries in order: smart match from quest log → level **+** zone → level only → level ≤ 10 starter fallback → first guide.

### Guide content status

| File | Steps | Coords | Stubs |
|---|--:|--:|--:|
| `TAG_Hallowfall.lua` | 309 | 309 | 309 |
| `TAG_Exiles_Reach.lua` | 60 | 60 | 13 |
| `TAG_Eversong_Midnight.lua` | 35 | 35 | 35 |
| `TAG_Naigtal.lua` | 21 | 21 | 21 |
| `TAG_Silvermoon_Midnight.lua` | 15 | 15 | 15 |
| `TAG_Midnight_Intro.lua` | 10 | 9 | 0 |
| **Total** | **450** | **449** | **393 (88%)** |

Four of the six carry a `STUB -- auto-generated from WoWDB PTR HTML dump` banner. **The navigation stack is driving on 12% real coordinate data** — this is the addon's single largest gap and the top item in `IMPROVEMENT_PLAN.md`.

`TAG_Midnight_Intro.lua` is the only guide with a full set of non-zero x/y values, but see §8.6 before treating it as verified: every one of its coords is anchored to map `2434`, an ID with no independent corroboration.

---

## 6. UI layer

Two layout modes, toggled by `db.useUnifiedUI` and applied by `TA:ApplyLayout()`:

- **Unified HUD** (default) — compass and tracker parented inside one draggable frame.
- **Fragmented** — each window floats independently; positions saved separately in `db.oldUiPositions`.

`Core/UI.lua` owns the 900×580 main frame, the tab bar, and frame pooling. Nine tabs are defined in its `TABS` array, each bound to the module that renders it:

`character` · `guide` (QuestTracker) · `gear` · `talents` · `rotation` · `delves` · `weekly` · `professions` · `pets`

`Core/UIModern.lua` provides typography, backdrop helpers, and the warm-neutral palette. Frames are pooled and reused — WoW does not garbage-collect frames, so abandoning one leaks for the session.

---

## 7. Persistence

```
ToonAgeDB                      -- account-wide, TA.db
ToonAgeDB.char["Name-Server"]  -- per-character, TA.charDB (TA.charKey)
ToonAgeDB.errorLog             -- ring buffer, 200 entries max
```

Defaults live in `DB_DEFAULTS` in `Init.lua` and are backfilled key-by-key on login. User data is never wiped on upgrade — missing keys are added, existing values are left alone.

> **Known issue:** the top-level backfill loop assigns table values by reference, so on a *fresh install* `db.modules` is the same table as `DB_DEFAULTS.modules` and `/ta toggle` mutates the defaults. Scope is limited to the first session, since SavedVariables deserialize into a fresh table on the next login.

---

## 8. Known architectural debt

Recorded here so it is not rediscovered. Fixes are scheduled in `IMPROVEMENT_PLAN.md`.

1. **`Core/GuideManager.lua` is dead code.** It was written as a "single source of truth" guide-state controller with a listener pattern, and its file header carries a TODO to migrate `QuestTracker` onto it. That migration never happened. It exports 13 methods and has **zero callers**; `QuestTracker` still owns `guideID`/`stepIdx` directly. It loads on every login. Either finish the migration or delete the file — leaving it is worse than both, because it reads as infrastructure that something depends on.

2. **`QuestTracker.lua` is 3,673 lines** — 10% of the codebase, 2.7× the next-largest module. It holds the tracker window, fast-forward sync, auto-quest, and the quest-item button. The natural split is along those seams.

3. **Mixed API generations.** Most Blizzard calls are correctly routed through `C_*` namespaces or through `Core/Utils.lua` wrappers, and the `C_Container` calls are properly guarded with fallbacks. Some bare globals remain — 19 `GetItemInfo`, 8 `IsSpellKnown`. These work at Interface 120007. New code should use the `Utils.lua` wrappers (`U.GetItemInfo`, `U.IsSpellKnown`, `U.GetSpellInfo`, `U.GetSpellCooldown`, `U.IsAddOnLoaded`, `U.GetAddOnTitle`) so a future removal is a one-line fix.

4. **Only 11 of 51 modules are toggleable.** Several opinionated modules (`Rotation`, `TooltipScorer`, `NameplateObjectives`, `RoleMorph`, `TargetMarker`, `AntTrail`) have no user off-switch.

5. **`Data/Zones.lua` holds ilvl data, not zones.** Rename when convenient. The portal database it is *supposed* to hold (per `.rules.md`) actually lives in `TravelRouter.PORTALS`.

6. **Map IDs are the weakest data in the addon, and wrong ones fail silently.** A stub coord (`0,0`) is visibly broken; a plausible-but-wrong map ID routes the player confidently to the wrong place. Several were invented by incrementing from a guessed parent. Verified and corrected on 2026-07-25:

   **Verified in-game via `/coord`, 2026-07-25:**

   | ID | Zone | Parent chain |
   |---|---|---|
   | 2537 | Quel'Thalas | Eastern Kingdoms 13 |
   | 2395 | Eversong Woods | Quel'Thalas 2537 |
   | 2393 | Silvermoon City | **Eversong 2395** > Quel'Thalas 2537 |
   | 2215 | Hallowfall | Khaz Algar 2274 |
   | 2248 | Isle of Dorn | Khaz Algar 2274 |
   | 2339 | Dornogal | Isle of Dorn 2248 > Khaz Algar 2274 |

   | Location | Was | Now | Note |
   |---|---|---|---|
   | `TAG_Hallowfall.lua` | 2248 | **2215** | 2248 is Isle of Dorn — a *sibling*, so the zone match failed entirely |
   | `TAG_Midnight_Intro.lua` `zone` | 2434 | **2537** | 2434 is Dead Scar, a sub-area of Eversong (`Data/Zones.lua:158`) |
   | `TAG_Eversong_Midnight.lua` | 0 | **2395** | |
   | `TAG_Silvermoon_Midnight.lua` | 0 | **2393** | |
   | `TAG_Naigtal.lua` | 0 | **2600** | still inferred — not yet walked |
   | `TravelRouter.PORTALS` ×6 | 2434/2435/2436/2437 | **2537/2395/2393/2600** | 2437 is Zul'Aman; 2435/2436 aren't Midnight maps |
   | `TravelRouter.PORTALS` ×3 | 2248 "Khaz Algar" | **2339 Dornogal** | relabelled to match where the portal lands |
   | `TravelRouter.PORTALS` ×2 | 2339 "Hallowfall", 2215 "Emerald Dream" | *removed* | one duplicated the Khaz Algar portal, the other pointed at Hallowfall |

   **Two consequences worth internalising:**

   - **Silvermoon nests inside Eversong.** Guide zone matching cannot take the first hit from a minLevel-sorted list — the broad parent guide beats the specific one. `MapZoneDistance` in `QuestTracker.lua` now ranks by specificity (exact > parent > grandparent). This was a live bug: at level 83–85 in Silvermoon you were served the Eversong guide.
   - **A wrong map ID is worse than a stub.** A `0,0` coord is visibly broken. `zone = 2248` on the Hallowfall guide looked plausible, matched nothing, and silently demoted the addon's largest guide to level-only selection.

   **Verification trip complete.** 22 map IDs were confirmed by standing in them, across both Midnight and Khaz Algar plus every mage-teleport hub. The confirmed Midnight tree:

   ```
   Quel'Thalas 2537
   ├── Eversong Woods 2395 ── Silvermoon City 2393
   ├── Harandar 2413 ──────── The Den 2576
   ├── Voidstorm 2405
   ├── Arcantina 2541
   └── Naigtal 2600 *
   ```

   `2600` could not be walked — Naigtal is gated content the account has not unlocked. It is accepted on external evidence: `HandyNotes_NaigtalTeleports/Core.lua:11` records it with the note *"Confirmed in-game via /dump C_Map.GetBestMapForUnit"*, and `HandyNotes_Midnight` — which supplied it — matched **6 of 6** IDs that were independently verified here.

   **Still open:** the nine `coord.map = 2434` values in `TAG_Midnight_Intro.lua`. Only that guide's `zone` field was corrected; x/y values are map-relative and cannot be remapped by changing the ID. Verify by running `/coord` at the first step's location — if it reports Dead Scar (2434) the coords are genuine, otherwise all nine need re-recording.

   **A guide-scoping problem surfaced by the same work:** `TAG_Naigtal.lua` is misnamed. Only 4 of its 21 steps are Naigtal; the other 17 are the Void Assaults chain, which begins in Zul'Aman and passes through Voidstorm. Keyed to its final zone (2600), those 17 steps could never auto-select. Re-keyed to Quel'Thalas 2537, which is safe only because `MapZoneDistance` now ranks by specificity. The real fix is to split it in two — the step tags already draw the line.

---

## 9. Not built

Everything in this section is **absent from the codebase**. It appeared in an earlier version of this document written in the present tense, which caused real confusion. It is retained here as design intent only.

| Idea | Status |
|---|---|
| `Modules/PartySync.lua` — broadcast guide steps over `C_ChatInfo.SendAddonMessage` | Not built. Scoped in `IMPROVEMENT_PLAN.md` §3.3 |
| `Modules/RoleCoach.lua` — healer HoT-uptime and tank threat/mitigation evaluation | Not built. Scoped in §R2 |
| `Modules/EncounterBridge.lua` — hide the HUD on `ENCOUNTER_START` so BigWigs/DBM own the screen | Not built. `DungeonGuide.lua:448–449` does register `ENCOUNTER_START`/`_END`, but on its own private frame and for boss-strategy display — it does not hide the ToonAge HUD or check for BigWigs/DBM |
| `Modules/LoadoutManager.lua` — composite talent + equipment + PvP swaps | Not built |
| `Modules/Reputation.lua` | Not built. Scoped in §2.3 |
| `Modules/Mounts.lua` | Not built. Scoped in §3.2 |
| TSM / Auctionator price bridge in `QuestRewardAdvisor` | Not built, and on hold — it would be a real runtime dependency |
| `Tools/extract_handynotes.py` | Not built |

**On interoperability generally:** ToonAge currently performs exactly one optional-addon handshake — `GuideImporter` checks for BtWQuests, via `U.IsAddOnLoaded`. `Gear.lua` has an optional Pawn check. There is no TSM, Auctionator, BigWigs, or DBM integration. The design rule (from `IMPROVEMENT_PLAN.md` §R) is that reference addons are studied and their *ideas* ported — never called as dependencies.

---

## 10. Where to look

| Task | Read first |
|---|---|
| Adding a module | `Core/Init.lua` (RegisterModule) + a small module such as `AutoMount.lua` |
| Changing the UI | `Core/UI.lua` (tabs, pooling) + `Core/UIModern.lua` (styling) |
| Guide content | `Modules/GuideParser.lua` (schema) + `Data/Guides/TAG_Midnight_Intro.lua` (the one complete guide) |
| Rotation work | `Modules/Rotation.lua` + `Modules/CombatState.lua` + `Data/Rotations.lua` |
| Gear work | `Modules/Gear.lua` + `Data/StatWeights.lua` |
| Event or refresh behaviour | `Core/Init.lua` (`QueueUIRefresh`) + `Core/UI.lua` (`Refresh`) |
| Coding standards | `.rules.md` |
| What to build next | `IMPROVEMENT_PLAN.md` |
