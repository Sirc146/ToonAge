# ToonAge — 10/10 AIO Improvement Plan

**Date:** 2026-07-23  
**Philosophy:** First it works, then we make it pretty. Own everything. Future-proof for expansions.

---

## CURRENT STATE ASSESSMENT (Score: 6.5/10)

### What's Already Strong
- **Architecture:** Clean module system, event-driven, pcall error handling, frame pooling, zero dependencies (LibStub only). This is production-grade engineering.
- **Rotation Helper:** Unique among guide addons. No competitor bundles combat priority with leveling guidance.
- **Stat-Weight Gear Scoring:** Built-in Pawn equivalent with PvE/PvP modes per spec.
- **Navigation Stack:** Arrow + NavHud + AntTrail + MapPins — covers FarmHud's job natively.
- **Endgame Relevance:** Weekly vault tracking + Delves + Alt Tracker means ToonAge doesn't go silent at max level.
- **Automation:** Auto-accept/turn-in, cutscene skip, auto-equip, gossip handling all present.
- **Talent Advisor:** Per-spec builds for M+/Raid/Solo with import string support.
- **Settings/Onboarding:** Full settings panel + first-login experience already done.
- **Dev Infrastructure:** Error logging, dev helpers, Python data-fetch tools, ROADMAP file.

### What's Weak / Missing
- **Guide Content Coverage:** Only 6 guides (3 Midnight stubs + Exile's Reach + Hallowfall + Intro). Zygor covers every zone in every expansion.
- **Guide Coords:** Most guides have stub coords (map=0, x=0, y=0). Arrow shows "No Loc" frequently.
- **Dungeon/Raid Guides:** Zero instance content. Zygor has full walkthroughs with role-specific boss strats.
- **Reputation/Dailies Module:** Not implemented. Zygor has a full dailies + reputation progression system.
- **Gold/Economy Guide:** Not implemented. Zygor has AH scanner + farming routes + crafting profit.
- **Achievement/Loremaster Layer:** Not implemented. Guide steps lack optional/achievement mode.
- **Rotation Sophistication:** Static priority lists vs Hekili's simulated future-state APL prediction.
- **Tooltip Upgrade Arrows:** TooltipScorer exists but doesn't inject Pawn-style % upgrade indicators.
- **Custom Stat Weight Import:** No way to paste Raidbots/SimC strings like Pawn allows.
- **Party/Group Sync:** No multi-player guide synchronization (WoW-Pro/RestedXP Multi have this).
- **Mounts/Transmog Collection:** Pets module exists but no mounts or transmog tracking.
- **Custom Task Creation:** AltTracker has built-in tasks only — no user-defined tasks like BtWTodo.
- **Dungeon Gear Finder:** DungeonGear.lua exists but no "which dungeon has most upgrades" system.
- **Auto-Mount:** Not implemented (Dugi has this).
- **Quest Icons on NPCs:** Not implemented (Zygor shows raid markers over quest NPCs).

---

## COMPETITOR GAP ANALYSIS

| Feature | Zygor | Dugi | Hekili | APR | WoW-Pro | BtWTodo | Pawn | FarmHud | ToonAge |
|---------|-------|------|--------|-----|---------|---------|------|---------|---------|
| Leveling guides (all zones) | ✅ | ✅ | — | ✅ | ✅ | — | — | — | ⚠️ 6 only |
| Dungeon walkthroughs | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Boss strategies per role | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Gear finder / BiS database | ✅ | ✅ | — | ❌ | ❌ | — | — | — | ⚠️ partial |
| Dungeon suggestions | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Stat-weight gear scoring | ✅ | ✅ | — | ❌ | ❌ | — | ✅ | — | ✅ |
| Tooltip upgrade indicators | ✅ | ✅ | — | ❌ | ❌ | — | ✅ | — | ⚠️ basic |
| Custom stat weight import | ❌ | ❌ | — | ❌ | ❌ | — | ✅ | — | ❌ |
| Rotation/priority helper | ❌ | ❌ | ✅ | ❌ | ❌ | — | — | — | ✅ |
| SimC APL prediction | ❌ | ❌ | ✅ | ❌ | ❌ | — | — | — | ❌ |
| Auto-accept/turn-in | ✅ | ✅ | — | ✅ | ❌ | — | — | — | ✅ |
| Cutscene skip | ❌ | ❌ | — | ✅ | ❌ | — | — | — | ✅ |
| Auto-equip upgrades | ✅ | ✅ | — | ❌ | ❌ | — | — | — | ✅ |
| Quest reward advisor | ✅ | ✅ | — | ❌ | ❌ | — | — | — | ⚠️ planned |
| Quest NPC icons | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Navigation arrow | ✅ | ✅ | — | ✅ | ✅ | — | — | — | ✅ |
| NavHud / FarmHud overlay | ❌ | ❌ | — | ❌ | ❌ | — | — | ✅ | ✅ |
| Ant-trail in instances | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ⚠️ open-world only |
| Reputation tracking | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Gold guide / AH scanner | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Farming routes | ✅ | ❌ | — | ❌ | ❌ | — | — | ✅ | ❌ |
| Pets + Mounts collection | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ⚠️ pets only |
| Achievements/Titles guide | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ❌ |
| Talent advisor | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ✅ |
| Weekly vault tracking | ❌ | ❌ | — | ❌ | ❌ | ✅ | — | — | ✅ |
| Alt character grid | ❌ | ❌ | — | ❌ | ❌ | ✅ | — | — | ✅ |
| Custom user tasks | ❌ | ❌ | — | ❌ | ❌ | ✅ | — | — | ❌ |
| Party guide sync | ❌ | ❌ | — | ❌ | ✅ | — | — | — | ❌ |
| Travel router | ✅ | ✅ | — | ❌ | ❌ | — | — | — | ✅ |
| Auto-dialogue selection | ✅ | ❌ | — | ✅ | ❌ | — | — | — | ✅ |
| Professions tracking | ✅ | ❌ | — | ❌ | ❌ | — | — | — | ✅ |
| Delves progression | ❌ | ❌ | — | ❌ | ❌ | — | — | — | ✅ |
| XP/hour + level ETA | ❌ | ❌ | — | ❌ | ❌ | — | — | — | ✅ |

**ToonAge's unique advantages over ALL competitors:** Rotation helper + endgame coaching + stat-weight gear + NavHud + zero dependencies — all in one addon.



---

## BLIZZARD ADDON POLICY COMPLIANCE CHECKLIST

ToonAge MUST remain compliant with all Blizzard addon development policies:

1. **FREE AND OPEN** — ToonAge is free. No premium tiers, no gated features, no subscription. Donations OK but never gate functionality. ✅ COMPLIANT
2. **NO EXECUTABLES** — Only Lua, XML, TOC, and approved media files (PNG/BLP). Python tools in `/Tools` are development-only scripts that run on the developer's machine — they never ship to or interact with the WoW client at runtime. ✅ COMPLIANT
3. **CLEAR CODE** — All `.lua` files must remain fully readable. No obfuscation, no minification, no encoded strings. ✅ COMPLIANT
4. **NO EXTERNAL ADVERTISING** — No third-party website ads in the UI. Only link to the addon's own GitHub for updates. ✅ COMPLIANT
5. **REMOTE DATA via Battle.net Developer Portal** — Any Python tools that fetch data from Blizzard APIs (talent trees, item stats, quest data) must:
   - Use OAuth 2.0 Client Credentials Flow for game-wide data (talents, items, realms)
   - Use OAuth 2.0 Authorization Code Flow for player-specific data (requires user consent)
   - Route through correct regional gateway (e.g., `us.api.blizzard.com`)
   - Include explicit `namespace` parameter (dynamic/profile)
   - Be registered at `community.developer.battle.net`
6. **LOCAL DATA via In-Game API** — Use WoW's built-in API (C_QuestLog, C_WeeklyRewards, C_Map, etc.) for all runtime data. Reference `/apii` (APIInterface addon) for live documentation.

### Policy Impact on Features
- **Gold Guide / AH Scanner:** Must use in-game `C_AuctionHouse` API only. No external price feeds.
- **Rotation Helper:** Must read only in-game state (buffs, cooldowns, power). No SimC server calls.
- **Update Notifications:** Can print "update available" in chat, but cannot auto-download or write files.
- **Data Fetch Tools:** Python scripts that call Battle.net API are dev-time only. Output is baked into static Lua data files shipped with the addon.

---

## PRIORITIZED IMPROVEMENT PLAN

### PHASE 1 — MAKE WHAT EXISTS ACTUALLY WORK (Weeks 1-3)
*"First it works." Fix the foundations so the current feature set is reliable.*

#### 1.1 Fill Guide Coordinates (HIGHEST IMPACT)
**Problem:** 5 of 6 guides have stub coords. Arrow shows "No Loc" constantly.  
**Solution:** Log into PTR, run `/taquestscan`, record coords at every NPC/objective.  
**Priority order:**
1. `TAG_Exiles_Reach.lua` — every new player starts here
2. `TAG_Midnight_Intro.lua` — already has real coords ✅
3. `TAG_Eversong_Midnight.lua` + `TAG_Silvermoon_Midnight.lua`
4. `TAG_Naigtal.lua`
5. `TAG_Hallowfall.lua` — biggest data lift (100+ steps)

**Concrete action:** In each zone, run:
```
/run print(C_Map.GetBestMapForUnit("player"))
```
Update `zone = <real mapID>` in each guide file. Record x/y at each quest giver.

#### 1.2 Confirm PTR Map IDs
**Problem:** Eversong, Silvermoon, Naigtal all have `zone=0` — breaks auto-select.  
**Solution:** Get real map IDs from PTR and update all three guide files.  
**Unblocks:** AutoSelectGuide by zone + level instead of level-only matching.

#### 1.3 Tooltip Upgrade Indicators (Pawn Parity)
**Problem:** TooltipScorer exists but is minimal. Players expect Pawn-style green arrows + % upgrade in tooltips.  
**Solution:** Enhance `TooltipScorer.lua` to:
- Hook `GameTooltip` and `ItemRefTooltip`
- Calculate stat-weight score using `Gear.lua`'s existing logic
- Show `▲ +12% upgrade` or `▼ -8% downgrade` line in tooltip
- Color-code: green = upgrade, red = downgrade, grey = sidegrade

#### 1.4 Quest Reward Advisor
**Problem:** Auto-quest does nothing at QUEST_COMPLETE with multiple rewards.  
**Solution:** When `GetNumQuestChoices() > 1`, overlay stat-weight scores on each reward option. Guide steps can specify `reward = itemID` for auto-selection when auto-quest is on.

#### 1.5 Auto-Mount
**Problem:** Players expect auto-mount after looting/combat ends (Dugi feature).  
**Solution:** New lightweight module `Modules/AutoMount.lua`:
- On PLAYER_REGEN_ENABLED (left combat), if outdoors + not in BG/Arena, wait 1.5s then mount
- Respect dragonriding vs flying vs ground based on zone capability
- Opt-in toggle in Settings
- Hold Shift to suppress (consistent with other auto- features)

---

### PHASE 2 — FILL THE CONTENT GAP (Weeks 3-8)
*"Content is king." Guide addons live or die by zone coverage.*

#### 2.1 Expand Leveling Guide Library
**Target:** Cover ALL current expansion leveling paths (minimum viable for "AIO"):
- War Within: Isle of Dorn (70-73), Ringing Deeps (72-76), Azj-Kahet (76-80)
- Midnight: Complete the existing 4 zone stubs with real data
- Exile's Reach: Already done, polish coords

**Method:** Use `Tools/fetch_wow_quests.py` to scaffold quest chains, then manually verify order + coords in-game.

#### 2.2 Dungeon Guide System
**Problem:** Zero instance content. This is Zygor's biggest selling point.  
**Solution:** New module `Modules/DungeonGuide.lua` + data file `Data/Dungeons.lua`:

```lua
-- Data/Dungeons.lua schema:
TA.Data.Dungeons = {
    [instanceID] = {
        name = "Murder Row",
        minLevel = 80,
        bosses = {
            {
                name = "Boss Name",
                journal = journalEncounterID,
                strat = {
                    tank = "Face away from group. Use active mitigation on Cleave.",
                    healer = "Heavy damage Phase 2. Save cooldowns for Enrage.",
                    dps = "Interrupt Shadow Bolt. Kill adds before boss at 30%.",
                },
                loot = { itemID1, itemID2, ... },  -- for gear finder
            },
        },
        route = {  -- ant-trail waypoints inside the instance
            { x=0.45, y=0.32, note="Pull first pack carefully" },
            ...
        },
    },
}
```

**Detection:** Hook `ZONE_CHANGED_NEW_AREA`, check `IsInInstance()`. If in a known dungeon, surface boss strats in the tracker based on current role.

#### 2.3 Reputation Module
**New file:** `Modules/Reputation.lua`  
**Features:**
- Show all current expansion factions with standing/renown level
- Cross-reference with Weekly.lua to highlight "worth doing for rep" activities
- Show reward milestones (gear, mounts, recipes) at each renown level
- Data source: `C_Reputation.GetFactionDataByID()`, `C_MajorFactions`

#### 2.4 Achievement / Loremaster Layer
**Problem:** No way to track side quests or achievements while leveling.  
**Solution:** Add `optional = true` flag to guide steps (schema already supports it). Add toggle in tracker: "Show optional steps" vs "Speed mode". Optional steps show achievement name + progress.



---

### PHASE 3 — COMPETITIVE PARITY FEATURES (Weeks 8-14)
*Match or beat every paid addon's key features.*

#### 3.1 Gold & Economy Module (Zygor Gold Guide equivalent)
**New files:** `Modules/GoldGuide.lua`, `Data/FarmingRoutes.lua`  
**Approach (Blizzard-compliant — no external price feeds):**
- **AH Scanner:** Use `C_AuctionHouse` API to scan categories on demand
- **Price Cache:** Store last-scan prices in SavedVariables per realm
- **Farming Routes:** Pre-defined gathering circuits stored as coord arrays in data files
  - Herb routes, ore routes, cloth farming spots per zone
  - Rendered on NavHud as waypoint loops
- **Crafting Profit Calculator:** Compare material cost (from AH scan) vs finished item sell price
- **Gold/Hour Tracker:** Track raw gold + vendor + AH income during farming sessions
- **No external data feeds** — all prices come from in-game AH API only

#### 3.2 Mounts Collection Module
**New file:** `Modules/Mounts.lua`  
**Features:**
- List all mounts with collected/uncollected status via `C_MountJournal`
- Filter by source (dungeon drop, reputation, achievement, vendor, etc.)
- Show acquisition steps for uncollected mounts (static data file)
- Highlight "easy wins" — mounts from soloable old content
- Cross-reference with DungeonGuide for dungeon-drop mounts

#### 3.3 Party Guide Sync
**Implementation:** Native addon messaging (no libraries needed):
- `C_ChatInfo.RegisterAddonMessagePrefix("TOONAGE")`
- Broadcast on PARTY channel: `"STEP|guideID|stepIdx"` when local stepIdx changes
- Receive: show party members' guide progress in tracker sidebar
- "Catch up" button to jump to party leader's step
- Works with WoW's built-in addon comm — zero external dependencies

#### 3.4 Quest NPC Icons (Zygor's "Quest Icons" feature)
**New file:** `Modules/QuestNpcMarker.lua`  
**How it works:**
- When a guide step has a `coord` and the player is within 40yd of an NPC
- Use `SetRaidTarget()` on the target NPC (star=talk, skull=kill, square=interact)
- Only marks when in solo play (don't override raid markers in groups)
- Opt-in setting, off by default

#### 3.5 Improved Rotation: Condition-Based Highlighting
**Problem:** Static priority lists can't match Hekili's state prediction.  
**Solution (pragmatic — don't try to be Hekili, be BETTER for leveling):**
- Add conditions to rotation entries that evaluate against `CombatState.state`:
  ```lua
  { spellID=X, condition = function(s) return s.powerPct > 80 end }
  ```
- Highlight only spells whose conditions are currently TRUE
- Show 3-step lookahead based on current state (not simulated future state)
- This is "good enough" for leveling/world content — Hekili is for raid min-maxing
- Add the **Custom Rotation Editor** (already pinned in PINNED_FEATURES.lua)

#### 3.6 Custom Stat Weight Import (Pawn Parity)
**Enhancement to:** `Modules/Settings.lua` + `Data/StatWeights.lua`  
**Feature:** Text input box in Settings where user can paste a Pawn string or SimC stat weights:
```
( Pawn: v1: "Custom": Intellect=1.60, Haste=1.20, CritRating=1.10, ... )
```
Parse and store in `charDB.customWeights[specID]`. When present, override the built-in weights.

#### 3.7 Custom Tasks in AltTracker (BtWTodo parity)
**Enhancement to:** `Modules/AltTracker.lua`  
**Feature:**
- "Add Task" button → text input for task name
- Tasks stored in `ToonAgeDB.customTasks = { {name, resetType="daily"|"weekly"|"midweek"} }`
- Check/uncheck per character per reset period
- Drag to reorder

---

### PHASE 4 — FUTURE-PROOFING & EXPANSION READINESS (Ongoing)

#### 4.1 Expansion-Proof Guide Architecture
**Already good:** Guide schema is zone-agnostic and supports any expansion.  
**Improvement:** Add guide metadata fields:
```lua
{
    expansion = "midnight",  -- filter guides by expansion
    patch = "12.0",          -- hide outdated guides when patch changes
    deprecated = false,      -- soft-hide without deleting
}
```

#### 4.2 Data Pipeline Automation
**Already exists:** Python tools for fetching talent/quest data.  
**Improvement:** Standardize the pipeline:
1. `Tools/fetch_wow_quests.py` → outputs `Data/Guides/TAG_*.lua` stubs
2. `Tools/fetch_talent_builds.py` → outputs `Data/Talents.lua`
3. `Tools/fetch_dungeon_data.py` (NEW) → outputs `Data/Dungeons.lua`
4. `Tools/update_stat_weights.py` (NEW) → fetches from community theorycrafting sources, outputs `Data/StatWeights.lua`
5. All tools authenticate via OAuth 2.0 Client Credentials Flow through `community.developer.battle.net`

#### 4.3 Seasonal Update Checklist
Every new season/patch:
1. Update `Data/StatWeights.lua` — new tier set changes stat priorities
2. Update `Delves.lua` TIERS table — iLvl breakpoints change each season
3. Update `Data/Dungeons.lua` — new M+ rotation
4. Run `fetch_talent_builds.py` — talent tree changes
5. Add new zone guide stubs via `fetch_wow_quests.py`
6. Update `Data/Zones.lua` portal database for new hub cities
7. Bump TOC `## Interface:` version number

#### 4.4 Version Update Notification
**Blizzard-compliant approach:**
- On login, check `TA.version` against a version string stored in a known guild/addon note, OR
- Simple approach: GitHub Releases page + PowerShell one-liner installer script
- In-game: print `[ToonAge] Update available: v1.2.0 → github.com/you/ToonAge/releases`
- NO auto-download (WoW sandbox prevents file writes — this is correct behavior)



---

## PRIORITY MATRIX — EFFORT vs IMPACT

**Status column audited against source 2026-07-25.** Four Phase 1 rows were marked
TODO while the code already shipped — which is how the tooltip work stayed
invisible for so long. Verify before trusting a TODO here.

| Feature | Impact | Effort | Phase | Status |
|---------|--------|--------|-------|--------|
| Fill guide coords | 🔴 Critical | Low (time, not code) | 1 | **TODO — 393/449 stubs (87%). The only Phase 1 item left.** |
| Tooltip upgrade arrows | 🔴 High | Low | 1 | ✅ DONE — `TooltipScorer.lua:204–231` renders ▲/▼ with a percentage |
| Quest reward advisor | 🟡 Medium | Low | 1 | ✅ DONE — `Modules/QuestRewardAdvisor.lua` |
| Auto-mount | 🟡 Medium | Low | 1 | ✅ DONE — `Modules/AutoMount.lua`, in active use |
| Map IDs confirmed | 🔴 High | Trivial | 1 | ✅ DONE — 22 IDs verified in-game; see TravelRouter.lua header |
| War Within zone guides | 🔴 Critical | Medium | 2 | TODO |
| Dungeon guide system | 🔴 High | High | 2 | TODO |
| Reputation module | 🟡 Medium | Medium | 2 | TODO |
| Achievement layer | 🟡 Medium | Low | 2 | TODO |
| Gold/economy module | 🟡 Medium | High | 3 | TODO |
| Mounts collection | 🟡 Medium | Medium | 3 | TODO |
| Party sync | 🟡 Medium | Medium | 3 | TODO |
| Quest NPC markers | 🟢 Nice | Low | 3 | TODO |
| Condition-based rotation | 🟡 Medium | High | 3 | 🟨 ENGINE DONE (ahead of schedule) — `Data/RotationConditions.lua` + `when` evaluation in `CombatState`. 15 conditions authored, ~640 entries pending |
| Custom stat weight import | 🟡 Medium | Low | 3 | TODO |
| Custom tasks (BtWTodo) | 🟢 Nice | Low | 3 | TODO |
| Expansion metadata | 🟢 Nice | Trivial | 4 | TODO |
| Dungeon data pipeline | 🟡 Medium | Medium | 4 | TODO |

---

## WHAT MAKES IT 10/10

A 10/10 AIO addon means:
1. **You never need another guide addon** — leveling, dungeons, dailies, gold, achievements all covered
2. **You never need Pawn** — stat weights + tooltip upgrades + import strings built in
3. **You never need Hekili for leveling** — rotation helper covers world content and dungeons
4. **You never need FarmHud** — NavHud already does this
5. **You never need BtWTodo** — weekly + alt tracker + custom tasks cover it
6. **You never need TomTom** — Arrow + coord system replaces it
7. **It works Day 1 of a new expansion** — data pipeline + guide architecture supports rapid updates
8. **It stays relevant at max level** — weekly vault, delves, gear finder, gold guide, reputation
9. **It's future-proof** — modular architecture means adding a new expansion is "add data files + new guide stubs"
10. **It's YOURS** — no subscription, no premium tier, no dependency on someone else's update schedule

---

## IMMEDIATE NEXT ACTIONS (Start Here)

### This Session
1. ✅ Assessment complete
2. ✅ Competitor analysis complete  
3. ✅ Improvement plan written

### Next Session — Phase 1 Quick Wins
1. **Enhance TooltipScorer.lua** — Add Pawn-style `▲ +X%` upgrade lines to item tooltips
2. **Create Modules/AutoMount.lua** — Simple auto-mount after combat with dragonriding awareness
3. **Quest Reward Advisor** — Add stat-weight overlay to QUEST_COMPLETE reward choices
4. **Fill coords** — Requires PTR playtime (you + your character walking through zones)

### Next Session — Phase 2 Content
1. **Create Data/Dungeons.lua** — Schema + first dungeon (Murder Row or Exile's Reach dungeon)
2. **Create Modules/DungeonGuide.lua** — Instance detection + boss strat display
3. **Create Modules/Reputation.lua** — Faction standings + renown tracker
4. **Stub War Within guides** — Use fetch_wow_quests.py for Isle of Dorn, Ringing Deeps, Azj-Kahet

---

## ARCHITECTURE DECISIONS FOR FUTURE-PROOFING

### Module Loading Pattern (already correct)
```
Core/ → loads first, provides TA global, Utils, UI framework
Data/ → static data files, no executable logic, easy to regenerate
Modules/ → self-registering modules with Init/OnEvent/Render pattern
Tools/ → dev-only Python scripts, never shipped to end users in-game
```

### Data Separation Principle
- **Static data** (spell IDs, talent trees, stat weights, zone coords) → `Data/` folder
- **Runtime state** (combat, quest progress, position) → module local variables
- **Persistent state** (settings, gear sets, task completion) → `ToonAgeDB` SavedVariables
- **Per-character state** (rotation prefs, guide progress) → `TA.charDB`

### Adding a New Expansion Checklist
1. Create guide stubs: `Data/Guides/TAG_NewZone.lua`
2. Update `Data/Zones.lua` with new mapIDs and portal connections
3. Update `Data/StatWeights.lua` if new specs/tuning changes
4. Update `Data/Rotations.lua` for new spells
5. Update `Data/Talents.lua` with new builds
6. Add new dungeons to `Data/Dungeons.lua`
7. Update TOC `## Interface:` number
8. Test → ship

---

## REFERENCE ADDON ABSORPTION PLAN

**Rule:** ~150 addons are installed here for study only — ToonAge has zero
runtime dependencies and stays that way (the one exception already in the
codebase, `Gear.lua`'s optional Pawn check, is the model: `if src=="pawn"
and Pawn and Pawn.GetSingleItemValue` — only used if present, never
required). Never call into a reference addon's API as a hard dependency;
port the *idea* into ToonAge's own code. This tracks that work by tab.

### PHASE R1 — Highest impact, lowest risk (do first)

| Target | Reference addon(s) | Tab / Module | Status |
|---|---|---|---|
| Real guide coordinates (replaces 380/449 stub steps) | `HandyNotes_Midnight`, `HandyNotes_MidnightTreasures`, `HandyNotes_MidnightCapital`, `HandyNotes_MidnightGlyphs`, `HandyNotes_NaigtalTeleports` | Guide tab — `Data/Guides/*.lua` | TODO — investigate HandyNotes data format next |
| Pawn-style tooltip upgrade % | `Pawn` | Gear tab — `TooltipScorer.lua` | ✅ Already hooks `OnTooltipSetItem`; verify output quality |

### PHASE R2 — Role Logic Engine (fills the capability audit's biggest gap)

| Target | Reference addon(s) | Tab / Module | Status |
|---|---|---|---|
| Healer HoT/shield/cooldown-alignment evaluation | `VuhDo` | Character tab — new logic, not just display | TODO |
| Tank threat/mitigation-uptime evaluation | `TankThreat` | Character tab — new logic, not just display | TODO |

### PHASE R3 — Polish already-strong areas

| Target | Reference addon(s) | Tab / Module | Status |
|---|---|---|---|
| Talent loadout switch/import UX review | `TalentLoadoutManager`, `BetterTalents`, `TalentTreeTweaks` | Talents tab | LOW PRIORITY — Talents/TalentsHelpers already meet or beat these on decode/leveling-path logic |
| Gear-set swap UX review | `Outfitter`, `ItemRack` | Gear tab — `GearSets.lua` | TODO |

### PHASE R4 — Lower priority / defer

| Target | Reference addon(s) | Tab / Module | Status |
|---|---|---|---|
| Crafting order / profession UX review | `TradeSkillMaster`, `ProfessionsAdvisor`, `CraftingOrders++` | Professions tab | TODO |
| Cross-character data patterns | `Altoholic`, `DataStore` family | AltTracker tab | TODO |
| Pet battle team management | `Rematch` | Pets tab | SKIP — Pets tab tracks collection, not battling |
| Full combat-log DPS/APL simulation | `Hekili`, `Simulationcraft` | Rotation tab | SKIP — against this addon's own stated design philosophy ("good enough for leveling," not a raid sim) |
| Live TSM/Auctionator price bridge | `TradeSkillMaster`, `Auctionator` | Gear/QuestRewardAdvisor | HOLD — would be a real runtime dependency, even if optional-checked like the Pawn pattern; confirm before building |

### Already done

- ✅ FarmHud → real scale/opacity/toggle options absorbed into `NavHud.lua` + `Settings.lua`
- ✅ TomTom → `Arrow.lua` compared directly; already matches or exceeds it (facing-color gradient, arrival pulse, speed-smoothed ETA, real `SetRotation`) — nothing to absorb
- ✅ Found and fixed a real unit-conversion bug in `U.FormatDistance` while doing that comparison (yards mislabeled as km)
- ✅ Grail → confirmed it has no coordinate data (only quest chain/NPC/zone metadata) — not useful for the coordinate gap; HandyNotes is the real lead
- ✅ Confirmed already built (not from scratch): `AutoMount.lua`, `TooltipScorer.lua`'s tooltip hook, `Data/Dungeons.lua`, `Modules/DungeonGuide.lua`
- ⬜ Not yet built: `Modules/Reputation.lua`, a party-sync module, an encounter-start/end tracker-hide bridge — all already scoped above in Phase 2/3 of the main plan

