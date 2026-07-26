# ToonAge — Independent Assessment

**Date:** 2026-07-25
**Scope:** Verification pass over the shipped code, the four existing planning docs, and the ~190 reference addons installed alongside it.
**Method:** Everything below was checked against the filesystem, the TOC, and the live SavedVariables. Claims sourced only from a planning doc are labeled as such.

This is deliberately *not* another roadmap. `IMPROVEMENT_PLAN.md` already covers the feature gaps well and I am not re-deriving it. This document covers what that plan does not: whether the claims are true, what the code does under load, and what the reference-addon extraction strategy actually costs.

---

## 1. Headline: it is real, and it runs

The single most important fact, and one none of the planning docs establish:

**ToonAge has loaded and run in-game, across at least 7 characters, with zero captured errors.**

```
_ptr_/WTF/Account/250587#1/SavedVariables/ToonAge.lua   33,364 bytes   2026-07-25 14:38
                                          ToonAge.lua.bak
```

- `["errorLog"] = { }` — empty. The addon's own 200-entry error capture ran across many sessions and caught nothing.

  **The write path was verified, not assumed.** An empty log is only evidence if it *could* have been written to. `Init.lua:153` and `:166` log via `if TA.ErrorLog then TA.ErrorLog:Log(...) end`, and `TA:RegisterModule` only populates `TA.modules.ErrorLog` — so that guard would silently no-op unless `TA.ErrorLog` is separately assigned. It is: `Modules/ErrorLog.lua:237` does `TA.ErrorLog = EL`, with a comment at :234 explaining exactly why. `EL:Log` (:33–52) appends to `TA.db.errorLog`, which is the SavedVariables key above, and trims at `MAX_LOG_SIZE = 200`. Nothing clears it on login — `:35` and `:191` use `or {}` guards, and the only wipe is the explicit `EL:Clear()` at :63–67. The log is genuinely empty because nothing errored.
- `xpHistory` holds real per-character telemetry (Flann-Vargoth L11 HUNTER @ 967 xp/hr, Talis-Vargoth L4 MAGE @ 27,375 xp/hr, plus five 80–82s).
- Structural integrity is clean: **all 78 TOC entries exist on disk, and no `.lua`/`.xml` under `Core/ Modules/ Data/ Libs/` is missing from the TOC.** Zero orphans, zero dangling loads. For a 35,653-line addon that is genuinely unusual.

So this is not a generated codebase that has never been executed. That reframes everything below from "does it work" to "how well is it built."

**Verified totals:** 35,653 lines Lua, 78 loaded files, **51 registered modules** (`.context.md` says "35+" — undercount).

---

## 2. Documentation drift is the most urgent problem

You have five planning docs. They contradict each other, and the newest one is the least accurate.

### `ARCHITECTURE.md` (modified Jul 25 16:43 — the newest file in the repo) describes an addon that does not exist

Every file named in its "Front-End," "Brains," and "Bridges" sections was checked. Results:

| Claimed in ARCHITECTURE.md | Actual |
|---|---|
| `Modules/UI_Selection.lua` | **ABSENT** |
| `Modules/UI_Tracker.lua` | **ABSENT** |
| `Modules/MinimapPins.lua` | **ABSENT** |
| `Modules/LoadoutManager.lua` | **ABSENT** |
| `Modules/RoleCoach.lua` | **ABSENT** |
| `Modules/EncounterBridge.lua` | **ABSENT** |
| `Core/GuideEngine.lua` | **ABSENT** |
| `Modules/PartySync.lua` | **ABSENT** |
| `Tools/extract_handynotes.py` | **ABSENT** |
| `Modules/TooltipScorer.lua` | exists |
| `Modules/QuestRewardAdvisor.lua` | exists |
| `Modules/AutoMount.lua` | exists |

Nine of twelve named files do not exist. The document's entire Section III ("Interoperability Bridges") rests on `C_AddOns.IsAddOnLoaded()` handshakes with TSM, Auctionator, BigWigs, and DBM. Actual `IsAddOnLoaded` call sites in the whole codebase: **three, all in `GuideImporter.lua`** (lines 112–115, 483), all checking for BtWQuests. There is no TSM bridge, no Auctionator bridge, no BigWigs/DBM encounter bridge, and no `ENCOUNTER_START` handler.

`ARCHITECTURE.md` reads as a design aspiration written in the present tense. That is fine as a vision doc — it is actively harmful as the file named `ARCHITECTURE.md` in the repo root, because it is the first thing any reader (human or AI) treats as ground truth.

### The drift runs in the other direction too

`.context.md`'s "CURRENT GAPS" list claims **"No auto-mount module"** — but `Modules/AutoMount.lua` exists (259 lines), is in the TOC, is toggle-registered in `Init.lua:37`, and has live settings persisted in SavedVariables (`["autoMount"] = { ["enabled"] = true, ["delay"] = 1.5 }`). It is not just built, it is *in use*. Same file also lists "Tooltip scorer needs Pawn-style upgrade %" as a gap while `IMPROVEMENT_PLAN.md` §R1 marks it "✅ Already hooks OnTooltipSetItem."

### Recommendation

Collapse five docs to two. `.bootstrap.md` already tells a reader to load all five in order — which currently means loading three mutually inconsistent descriptions of the same codebase.

- **Keep** `IMPROVEMENT_PLAN.md` as the single roadmap. It is the strongest doc here: honest self-score, real competitor matrix, and the Phase-R "reference addon absorption" section is genuinely good thinking.
- **Keep** `.rules.md` as the style guide. It is accurate and useful.
- **Rewrite** `ARCHITECTURE.md` to describe the 51 modules that exist, or rename it `VISION.md` and date it. — **✅ Done 2026-07-25.** Rebuilt from the TOC and verified against source: load order, module contract, event dispatch, all 51 modules with their interface flags, data layer, and a §8 debt list. Unbuilt ideas are quarantined in §9 and labelled. `.bootstrap.md`'s reading list now points at it and marks the superseded docs.
- **Fold** `.context.md` into the rewritten architecture doc — its module registry is 80% correct and worth salvaging, its gap list is stale.
- **Fold** `.competitors.md` into `IMPROVEMENT_PLAN.md`, which already contains a superset of it as a matrix.
- **And this file.** It is currently the sixth doc, which would be a poor way to close a section complaining about five. Intended lifecycle: fold §3 (code findings) and §5 (licensing) into `IMPROVEMENT_PLAN.md` as a Phase 0, apply the §5.3 map-ID fixes, then delete this file. If you'd rather keep it, keep it *dated* and treat it as a point-in-time audit that is never updated — not as a living description of the addon. That is the failure mode `ARCHITECTURE.md` is currently in.

---

## 3. Code quality findings

Overall the code is better than the docs. Error handling is disciplined, the module contract is consistent, and the Blizzard-API migration work is mostly careful. Specific issues, ranked:

### 3.1 No event debouncing — violates the project's own rule (highest impact)

`Core/Init.lua:206–229` fans every one of 16 persistent events out across every module, then rebuilds the open UI tab:

```lua
TA:UpdateModules(event, ...)
if TA.UI and TA.UI:IsVisible() then
    TA.UI:Refresh(event)
end
```

`Core/UI.lua` — `frame:Refresh(event)` ignores `event` entirely and calls `self:SetTab(self.activeTab)`, a **full tab teardown and rebuild**.

`UpdateModules` walks all 51 registered modules but only pcalls those that implement a handler (`if mod.OnEvent and not mod._disabled`). **33 of 51 modules define `OnEvent`**, so the real per-event cost is a 51-entry table walk plus 33 pcall'd dispatches — not 51. The dispatch half of this is therefore moderate, not alarming.

The `UI:Refresh` half is the actual problem. The registered event list (`Init.lua:176–195`) includes `BAG_UPDATE`, `UNIT_INVENTORY_CHANGED`, and `PLAYER_EQUIPMENT_CHANGED`. `BAG_UPDATE` fires once per bag per change — looting a single stack can fire it 5+ times in a frame. Each fire triggers a full teardown-and-rebuild of whatever tab is open, regardless of whether that tab has anything to do with bags. If that tab is Gear (1,344 lines, full inventory scan with `GetItemInfo` per slot), this is a visible hitch every time you loot.

`.rules.md` line 87 says: *"Debounce high-frequency events (QUEST_LOG_UPDATE → 0.15s coalesce)."* `Core/Init.lua` contains zero `C_Timer` calls and no throttle of any kind. The individual modules do throttle (QuestTracker has 12 timer/throttle references, Gear 5, Arrow 5) — the gap is entirely in the central dispatcher.

**Fix:** coalesce in `Init.lua` — hold a dirty-flag set, flush on a 0.15s `C_Timer.After`, and make `UI:Refresh(event)` actually consult `event` so a `BAG_UPDATE` doesn't rebuild the Talents tab.

### 3.2 `DB_DEFAULTS` sub-tables are aliased, not copied

`Core/Init.lua:66–70`:

```lua
for k, v in pairs(DB_DEFAULTS) do
    if db[k] == nil then
        db[k] = v          -- table values assigned by reference
    end
end
```

On a fresh install `db.modules` **is** `DB_DEFAULTS.modules`, not a copy. `/ta toggle NavHud` (`Init.lua:338`) then mutates the defaults table itself. The deep-default blocks at lines 74–97 don't rescue this — they only backfill *missing* sub-keys and hand back the same aliased table.

Scope is limited: on the next login `ToonAgeDB` deserializes as a fresh table so `db[k] ~= nil` and no aliasing occurs. So the blast radius is first-run-session only. Still worth fixing — it's two lines and the pattern will bite harder as `DB_DEFAULTS` grows.

### 3.3 `/ta reset` leaves dangling references

`Init.lua:295–298` sets `ToonAgeDB = nil` and prints "please reload." But `TA.db`, `TA.charDB`, and every module's cached reference still point at the old table. Anything that writes settings between the reset and the `/reload` writes into an orphan. Low severity given the printed instruction, but `TA.db = nil; TA.charDB = nil` alongside it costs nothing.

### 3.4 Deprecated-API usage is inconsistent, not broken

48 bare-global calls to APIs that have `C_*` replacements. Important nuance: **the container APIs are correctly guarded.** `AutoEquip.lua:97`, `:266`, `:296` and `QuestTracker.lua:1497`, `:1507` all use the proper pattern:

```lua
local slots = C_Container and C_Container.GetContainerNumSlots(bag)
           or GetContainerNumSlots(bag)
```

That is careful, forward-compatible code. The inconsistency is elsewhere:

- `Core/Utils.lua:193` uses `C_Spell.GetSpellInfo` — but `Utils.lua:202` uses bare `GetSpellCooldown`.
- `CombatState.lua` uses `C_Spell.GetSpellCooldown` at lines 199, 293, 331, 466, 509 — then bare `GetSpellCooldown(61304)` at line 217.
- `TalentsHelpers.lua:456` uses bare `GetSpellInfo`.
- `DungeonTalents.lua:60` uses bare `GetAddOnInfo("BetterTalents")` where `C_AddOns.GetAddOnInfo` is the current form.

These currently work — the globals still exist as compat shims at Interface 120007. The risk is that Blizzard has been retiring these shims expansion by expansion, and the mixed usage means a future break will surface in three unrelated modules at once rather than one wrapper. Route them all through `Core/Utils.lua` so there is exactly one call site per API.

The 19 bare `GetItemInfo` calls are the largest group and the lowest risk — that global is not currently on a deprecation path.

### 3.5 `QuestTracker.lua` is 3,672 lines — 10% of the codebase in one file

More than 2.7× the next-largest module (`Gear.lua`, 1,344). It carries the tracker window, FFWD sync, auto-quest, the quest-item button, and coordinate handling. Not urgent — it works and its error log is clean — but it is the file most likely to resist the Phase 2/3 changes the plan schedules for it, and the obvious split (tracker UI / auto-quest automation / quest-item button) falls out naturally.

### 3.6 Clean bills of health

- **No file-scope global leaks.** Scanned all of `Core/ Modules/ Data/` for column-0 assignments to undeclared identifiers: zero, outside the intentional `ToonAge`, `SLASH_*`, `BINDING_*` globals and the Bindings.xml/AddonCompartment entry points. In a 190-addon environment this matters, and it was done right.
- **Only 6 `OnUpdate` handlers** across the whole addon (MinimapButton, Arrow, QuestTracker, Rotation, TargetMarker). Restrained.
- **`pcall` discipline is real,** not just documented — every `Init` and `OnEvent` genuinely goes through it (`Init.lua:149`, `:163`) with `ErrorLog` fallback.
- **51 modules registered, 11 toggleable.** Worth widening: `Rotation`, `TooltipScorer`, `NameplateObjectives`, `RoleMorph`, `TargetMarker`, and `AntTrail` are all cosmetic/opinionated enough that users will want them off, and each one off is 1/51 of the dispatch cost in §3.1.

---

## 4. The content gap, measured

`IMPROVEMENT_PLAN.md` calls guide coordinates the #1 critical item. Exact current state:

| Guide file | Steps | Coords | Stubs | Complete |
|---|---:|---:|---:|---:|
| `TAG_Hallowfall.lua` | 309 | 309 | **309** | 0% |
| `TAG_Eversong_Midnight.lua` | 35 | 35 | **35** | 0% |
| `TAG_Naigtal.lua` | 21 | 21 | **21** | 0% |
| `TAG_Silvermoon_Midnight.lua` | 15 | 15 | **15** | 0% |
| `TAG_Exiles_Reach.lua` | 60 | 60 | 13 | 78% |
| `TAG_Midnight_Intro.lua` | 10 | 9 | 0 | 100% |
| `TAG_LevelingPaths.lua` | 0 | 0 | 0 | — |
| **Total** | **450** | **449** | **393** | **12%** |

**393 of 449 coordinates are stubs (88%).** The plan's estimate of 380/449 was close. Hallowfall alone is 309 of them — 79% of the entire problem is one file.

Put plainly: the navigation stack (Arrow, NavHud, AntTrail, MapPins, CoordResolver — roughly 2,000 lines of well-built code) is driving on 12% real data. This is the correct #1 priority and nothing else in the plan competes with it.

---

## 5. Reference-addon extraction: what's actually available, and the licensing trap

You asked about extracting guide data from the installed addons. I checked. **There is excellent data available, and the most attractive source is legally blocked.** This deserves a decision before any extraction work starts.

### 5.1 WoWPro — perfect data, prohibitive license

`WoWPro_Leveling/Retail/Neutral/TWW_Hallowfall.lua` contains **473 map coordinates** with quest IDs, zone IDs, objective indices, and step types, in a format that maps almost one-to-one onto ToonAge's schema:

```
A The Hallowed Path|QID|78658|PRE|81689|M|42.99,32.24|Z|2214; The Ringing Deeps|N|From Anduin Wrynn.|
C The Hallowed Path|QID|78658|M|36.67,23.95|Z|2214; The Ringing Deeps|QO|1|NC|N|Find the Gate to Hallowfall.|
T The Hallowed Path|QID|78658|M|68.43,45.07|Z|2215; Hallowfall|N|To Faerin.|
```

`A`/`C`/`T`/`R` → ToonAge's `accept`/`quest`/`turnin`/`travel`. `|M|` → `coord{x,y}`. `|Z|` → `coord.map`. `|QID|` → `questID`. `|QO|` → `objectiveIndex`. `|PRE|` → `precondition`. A converter is maybe 150 lines of Python and would fill Hallowfall's 309 stubs in an afternoon.

**But:** `WoWPro/WoWPro.toc` declares

```
## X-License: Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.
```

**NoDerivs.** CC BY-NC-**ND** specifically forbids distributing modified or adapted versions of the work. Reformatting their route data into ToonAge's schema and shipping it is exactly the derivative work that license prohibits. Non-commercial status does not help — ND is a separate restriction from NC, and ToonAge being free doesn't clear it. Also relevant: this is 16 MB of guides across all expansions, i.e. it would be a *very* visible copy.

There is a clean path: the WoW-Pro Community owns the copyright and is reachable at `github.com/Ludovicus-Maior/WoW-Pro-Guides`. Ask for a license exception or dual-license for ToonAge. Free addon, attribution offered, community project — a reasonable ask. Just get it in writing before extracting.

### 5.2 APR — ask first, but likely obtainable

`APR/APR.toc`:

```
## X-License: All Rights Reserved: You are free to fork and modify on GitHub, please ask us about anything else.
```

Explicitly reserves rights and explicitly invites you to ask. Extraction into a different addon is "anything else." Same recommendation: one email.

### 5.3 HandyNotes_Midnight — usable, and it solves a *different* problem than you think

This is the best near-term lead, but with an important correction to the plan's framing.

**What it gives you (verified):** ~448 node entries across 11 zone files with real, current PTR map IDs:

| Zone file | Nodes | Map IDs |
|---|---:|---|
| `harandar.lua` | 172 | 2413, 2576, 198, 2239, 116, 62, 641 |
| `zul_aman.lua` | 66 | 2437, 2536 |
| `eversong_woods.lua` | 62 | **2395**, 2393, 2424 |
| `voidstorm.lua` | 59 | 2405, 2444, 2526, 2527 |
| `delves.lua` | 30 | 2535, 2502, 2545, 2547, 2525, 2504, 2510, 2505, 2528, 2571, 2506, 2507 |
| `naigtal.lua` | 20 | **2600**, 2646 |
| `arcantina.lua` | 16 | 2541 |
| `val.lua` | 11 | 2599 |
| `broken_throne.lua` | 6 | 2585 |
| `daggerspine_point.lua` | 6 | 2594 |

**This immediately unblocks `IMPROVEMENT_PLAN.md` §1.2 ("Confirm PTR Map IDs"), which the plan calls High impact / Trivial effort and lists as a blocker for zone-based guide auto-selection.** All three blocked guides carry `zone = 0` today — verified at `TAG_Naigtal.lua:15`, `TAG_Eversong_Midnight.lua:19`, `TAG_Silvermoon_Midnight.lua:17`:

| Guide file | Current | Correct | Confidence |
|---|---|---|---|
| `TAG_Eversong_Midnight.lua:19` | `zone = 0` | **2395** | High — `abundance.lua` comments `ns.maps[2395], -- Eversong Woods` |
| `TAG_Silvermoon_Midnight.lua:17` | `zone = 0` | **2393** | High — commented twice: `eversong_woods.lua:36` (`local smc = Map({id = 2393…}) -- Silvermoon City`) and `delves.lua:284` |
| `TAG_Naigtal.lua:15` | `zone = 0` | **2600** | Medium — inferred, not commented. `naigtal.lua:22` binds 2600 to the primary `map` variable (2646 is a secondary, `vcr`). Spot-check in-game before committing. |

Note the stale comment at `TAG_Eversong_Midnight.lua:18`: *"instead of colliding with silvermoon_midnight (also zone=2434 stub)."* 2434 is wrong for both zones — Eversong is 2395 and Silvermoon is 2393, so there was never a collision to avoid. Drop the comment along with the fix.

**Separately — a real bug found while confirming these.** `TAG_Hallowfall.lua:13` has `zone = 2248, -- TODO: confirm with /coord`. **2248 is Isle of Dorn, not Hallowfall. Hallowfall is 2215.** Cross-checked directly against zone-ID labels in the installed WoWPro guides:

```
|Z|2214; The Ringing Deeps      |Z|2248; Isle of Dorn
|Z|2215; Hallowfall             |Z|2255; The Reckoning
|Z|2339; Dornogal
```

The addon's largest guide (309 steps) is currently pointed at the wrong zone. The `TODO` shows this was known to be unverified — it's now verified, and wrong.

(To be explicit about §5.1: a UiMapID is Blizzard game data, a fact with one correct value. Reading `2215` off a WoWPro line is not copying WoWPro's authorship, and none of the map IDs above carry any licensing question. The ND restriction applies to their *route data* — the ordering, waypoints, and step prose — not to integers that identify Blizzard's zones.)

Four one-line edits, available right now, no licensing question, no PTR playtime.

**What it does *not* give you:** HandyNotes nodes are treasures, rares, glyphs, and collectibles — **not quest-giver or quest-objective coordinates.** The plan's §R1 line ("Real guide coordinates (replaces 380/449 stub steps) ← HandyNotes_Midnight…") is optimistic. HandyNotes will not fill quest-step coords, because it does not contain them. It will fill a *treasure/rare overlay*, which is a nice MapPins feature and worth doing, but it is a different feature from the one that's blocking the Arrow.

Also note: none of the HandyNotes_* addons ship a license file or an `X-License` TOC field. Absent an explicit grant, default copyright applies — the same "ask first" situation as APR, just without anyone having written it down.

### 5.4 Zygor and Dugi are installed — and are the one hard no

Correcting a premise in your message: both **are** on this machine, on retail rather than PTR:

```
_retail_/Interface/AddOns/ZygorGuidesViewer    96 MB
_retail_/Interface/AddOns/DugisGuideViewerZ    56 MB
```

Do not extract from these. They are paid commercial products; their route data is the product. Copying it into a free redistributed addon is straightforward copyright infringement, exposes you personally, and would get ToonAge pulled from CurseForge/Wago on the first DMCA notice. `IMPROVEMENT_PLAN.md` is right to treat them as *behavioral* benchmarks — match what their UI does, never take what their data says.

### 5.5 The safe path, which you already own

`Tools/` already has the machinery: `fetch_wow_quests.py`, `blizzard_api.py`, `crawl_wowdb_quests.py`. The Battle.net Game Data API (`/data/wow/quest/{id}`) is licensed for exactly this use, is already in your `.rules.md` compliance section, and produces data with no attribution problem. It won't give you *route order* — that's the human judgment WoWPro and Zygor are actually selling — but it gives you quest chains and objectives, and `/taquestscan` in `DevHelpers.lua` already exists to record real coords as you walk.

**Suggested ordering:**
1. **Today, free:** fix `zone = 0` in the three Midnight guides (2395 / 2393 / 2600) and correct Hallowfall's `2248 → 2215`. Unblocks auto-select and points the 309-step guide at the right zone. (§1.2 done)
2. **This week, free:** build the HandyNotes coord decoder as a *MapPins treasure/rare overlay* — a real feature, correctly scoped, no license risk. Note it is not the quest-coord fix.
3. **Send two emails:** WoW-Pro Community (license exception) and the APR authors. Costs nothing, and a yes from WoW-Pro collapses the entire 393-stub problem to a scripting task.
4. **Meanwhile:** `/taquestscan` through Hallowfall on the PTR. 309 steps is real work, but it's the only path that is unambiguously yours and it's the path the plan already chose.

---

## 6. Where ToonAge actually stands against what's installed

Reframing §5 of `.competitors.md` as collision analysis rather than a feature race, since every addon ToonAge claims to replace is installed here and running:

| ToonAge module | Installed rival | Reality |
|---|---|---|
| `Arrow.lua` | TomTom | Plan already compared them directly and found Arrow ahead. Credible — 838 lines with facing gradient and speed-smoothed ETA. |
| `NavHud.lua` | FarmHud | Genuine parity, plan marks absorption done. |
| `TooltipScorer.lua` | Pawn | Pawn wins today (import strings, per-spec profiles). Gap is narrow and §1.3 targets it. `Gear.lua` already has the optional-Pawn check as the right interop model. |
| `Rotation.lua` | Hekili, MaxDps (14 class modules) | Not close, and the plan correctly declines to compete. Positioning as leveling-grade is right. |
| `QuestTracker.lua` | !KalielsTracker, BtWObjectiveFilter, WorldQuestTracker | Largest module, most-contested space. |
| `AltTracker.lua` | Altoholic + 15 DataStore modules, BtWTodo | The most crowded space on this machine. DataStore's cross-char persistence is a decade of work. Weakest competitive position. |
| `MapPins.lua` | ~60 HandyNotes modules | Don't fight this. HandyNotes *is* the ecosystem. |
| `GearSets.lua` | ItemRack, Outfitter, BtWLoadouts | §R3 already deprioritizes. Correct. |
| `TargetMarker.lua` | NumysAutoMarker | **No collision.** See correction below. |
| `Weekly.lua`, `Delves.lua`, `XPTracker.lua` | — | Genuinely uncontested. This is the moat. |

**Correction to an earlier draft of this section.** I initially flagged `TargetMarker.lua` as colliding with NumysAutoMarker over `SetRaidTarget`. That was wrong, and the source of the error is itself a finding. `TargetMarker.lua:12–14` says:

> This is NOT a raid marker (`SetRaidTarget` requires group lead / no restrictions in solo play but is intrusive). Instead we draw a custom texture on the nameplate frame — works in all situations without affecting other players.

The module never calls `SetRaidTarget`. It creates its own icon frame anchored above the nameplate. There is no conflict with NumysAutoMarker, and the design decision is the right one.

I trusted `.context.md`'s module registry, which describes TargetMarker as **"Auto raid-marker on targets."** That is not what the module does. Add it to the §2 drift list — and note the lesson: the registry table is accurate enough to be trusted and wrong often enough to burn you. Verify against the source before acting on it.

**The real issue in that file was a frame leak,** now fixed (§9).

---

## 7. Repo hygiene

**34 modified files are uncommitted**, against 7 total commits, the last of which is `b3ab930 feat: massive modular refactor`. The working tree includes changes to `Core/Init.lua`, `Core/UI.lua`, `QuestTracker.lua`, `Gear.lua`, `Talents.lua`, `Rotation.lua`, and all six guide files, plus five untracked planning docs.

Some meaningful fraction of 35k lines exists only on this disk with no commit behind it. `IMPROVEMENT_PLAN.md` §R notes a real bug fix landed during this work ("found and fixed a real unit-conversion bug in `U.FormatDistance`") — that fix is currently uncommitted.

Not proposing to act on this; flagging it because it's the largest single risk to the work itself. `Monk/` (skeleton, 2 files) and `Archive/` are also tracked and probably shouldn't be.

---

## 8. Verdict

`IMPROVEMENT_PLAN.md` self-scores **6.5/10**. Based on what's actually on disk and what's actually run, that is **slightly harsh on engineering and slightly generous on content.**

**Engineering: 7.5/10.** Clean module contract across 51 modules, genuine `pcall` discipline, zero global leaks, careful `C_Container` forward-compat, a perfect TOC, and — decisively — an empty error log after real multi-character play, with the write path verified rather than assumed. The `UI:Refresh` gap (§3.1) is the one thing keeping this out of the 8s, and it's a contained fix in one file.

**Content: 4/10.** 88% stub coordinates, and the one large guide that *has* a zone ID has the wrong one (§5.3). The navigation engine is far ahead of the data feeding it.

**Documentation: 3/10.** Five docs, three of them mutually contradictory, and the newest describes nine files that don't exist. This is the highest-leverage thing to fix because everything else — including every future AI-assisted session, per `.bootstrap.md`'s own instructions — is read through it.

The build order in `IMPROVEMENT_PLAN.md` is right and I'd change nothing about its priorities. The three things I'd insert ahead of Phase 1:

1. **Reconcile the docs** (§2) — half a day, and it stops every future session from building on a fiction.
2. **Make `UI:Refresh` consult its `event` argument** (§3.1) — `Core/Init.lua` + `Core/UI.lua`, and it's the difference between "smooth" and "hitches when you loot."
3. **Resolve the licensing question before extracting anything** (§5) — because the most tempting source, WoWPro, is the one that's actually prohibited, and finding that out after building the converter would be the expensive way to learn it.

Then Phase 1.2 (map IDs) is already done — the four values are in §5.3, including the Hallowfall `2248 → 2215` correction, which is the highest value-per-keystroke change available in this repo today.

---

## 9. Changes applied 2026-07-25

Everything above §9 is analysis. This section is the code that was actually changed. **Nothing here has been run in-game** — it is syntax-checked (brace/paren/bracket balance verified against untouched files as a control) but not play-tested. Reload and watch `/ta errors`.

### 9.1 Map IDs — 4 guide files

| File | Change |
|---|---|
| `TAG_Hallowfall.lua:13` | `zone = 2248` → **`2215`**. 2248 is Isle of Dorn. Fixes the 309-step guide. |
| `TAG_Eversong_Midnight.lua` | `zone = 0` → **`2395`**. Stale 2434-collision comment removed. |
| `TAG_Silvermoon_Midnight.lua` | `zone = 0` → **`2393`**. |
| `TAG_Naigtal.lua` | `zone = 0` → **`2600`**. Comment flags this one as inferred. |

This makes `QuestTracker:AutoSelectGuide` Pass 1 (level **+ zone**) fire where it previously always fell through to Pass 2 (level-only) — which is exactly what the old comments said they wanted.

**One risk to watch.** `MapIsInZone` (`QuestTracker.lua`) walks `parentMapID` upward, and `GetSortedGuideList` sorts by ascending `minLevel`. If Silvermoon (2393) turns out to be a *child* of Eversong (2395) in the map tree, then standing in Silvermoon at level 83–85 matches Eversong first (minLevel 80) and it wins the loop. I could not determine the parent relationship from static files — it's runtime `C_Map.GetMapInfo` data. If auto-select picks Eversong while you're in Silvermoon, that's the cause; the fix is to sort Pass 1 most-specific-first rather than by level.

### 9.2 Coalesced UI refresh — `Core/Init.lua`, `Core/UI.lua`

- New `TA:QueueUIRefresh(event)` in `Init.lua` collects events into a set and flushes once via `C_Timer.After(0.15, ...)`, per `.rules.md`'s own debounce rule. Drops events entirely when the panel is closed, re-checks visibility after the delay, and wraps the refresh in `pcall` + `ErrorLog` to match the module dispatch path.
- `frame:Refresh` in `UI.lua` now takes the event set and decides whether a rebuild is warranted.

**The filter is deliberately not a plain allow-list**, and this is worth understanding before editing it. My first cut was one, and it was a regression. Modules register their own events directly on `TA.eventFrame` — **28 events reach the dispatcher that never appear in `Init.lua`'s `PERSISTENT_EVENTS`**, including all nine of QuestTracker's quest events, `Gear.lua`'s `INSPECT_READY`, `XPTracker`'s `PLAYER_XP_UPDATE`, and `GuideBrowser`'s `SUPER_TRACKING_CHANGED`. A strict allow-list drops every one of them, so the Gear tab silently stops updating on inspect and Weekly goes stale — bugs that present as "the tab is just wrong sometimes," which is close to undiagnosable.

The shipped design is three-way:

1. Event is claimed by the **active tab** → rebuild.
2. Event is in **`UI_IRRELEVANT`** (nameplate churn, cinematics, combat enter/leave, death/res — 11 events no tab renders) → skip.
3. Event is **unaccounted for** → rebuild. Unknown means "assume it matters."

So adding a module with a new event degrades to today's always-rebuild behavior rather than silently breaking a tab. The filtering win comes almost entirely from rule 2, which is where the high-frequency churn actually lives.

Verified split across the 44 events that reach the dispatcher: 10 filtered (the nameplate/combat churn), 9 conservatively always-rebuilding (`INSPECT_READY`, `LOOT_OPENED`, `PLAYER_TARGET_CHANGED`, `GOSSIP_SHOW`, `QUEST_DETAIL`, `QUEST_PROGRESS`, `QUEST_GREETING`, `BAG_UPDATE_DELAYED`, `HEARTHSTONE_BOUND`), rest routed per-tab.

`guide` did get its own entry — QuestTracker demonstrably ignores `BAG_UPDATE` and `PET_STABLE_UPDATE`, and it's the default tab (`frame:Show()` falls back to `"guide"`), so leaving it always-rebuild would have meant the filtering did nothing for the most common case.

Net effect: looting rebuilds the open tab at most once per 150 ms and only if that tab shows something bag-related; combat nameplate churn no longer rebuilds anything.

### 9.3 API consolidation — `Core/Utils.lua` + 5 modules

Added single call sites in `Utils.lua`, each with a `C_*`-first / bare-global-fallback shape so they work before and after Blizzard retires the shims: `U.GetSpellCooldown` (now returns the pre-11.0 `start, duration` shape from `C_Spell`'s table), `U.GetSpellInfo`, `U.GetItemInfo`, `U.IsAddOnLoaded`, `U.GetAddOnTitle`. `U.IsSpellKnown` now prefers `C_SpellBook.IsSpellKnown`.

Rerouted the outliers: `CombatState.lua:217` (bare `GetSpellCooldown` amid five `C_Spell` calls in the same file), `TalentsHelpers.lua:456` (bare `GetSpellInfo`; also added the missing `local U`), `DungeonTalents.lua:60` (bare `GetAddOnInfo`), and both hand-rolled `IsAddOnLoaded` ladders in `GuideImporter.lua`.

Verified there are no duplicate definitions shadowing the new helpers (one `function U.X` per name in `Utils.lua`), and that `U.GetSpellCooldown`'s changed internals reach only the single caller above.

Deliberately **not** changed, for the same reason in both cases — these globals are not on a deprecation path, wrappers now exist for new code, and rewriting working call sites in a repo with 34 uncommitted files is a bad trade:

- The **19 bare `GetItemInfo` calls** across `Gear.lua`, `AutoEquip.lua`, `RoleMorph.lua`, and others.
- The **8 bare `IsSpellKnown` calls** in `CombatState.lua:325,435`, `Gear.lua:291`, and `TravelRouter.lua:149,184`. Note the consequence: since `U.IsSpellKnown` now prefers `C_SpellBook.IsSpellKnown`, the codebase answers "is this spell known" two ways until these are migrated. Both are correct today; they could diverge if Blizzard changes one.

Migrate both sets opportunistically — whenever you're already editing the surrounding function.

### 9.4 Frame leak — `Modules/TargetMarker.lua`

`UnmarkNameplate` did `icon:SetParent(nil)` and dropped the reference. WoW does not garbage-collect frames — `.rules.md:88` says so explicitly ("Frame pool: reuse, never abandon"). Nameplates churn constantly, so every mob that entered and left render range leaked one frame plus two textures, for the whole session.

Replaced with a proper pool: `AcquireIcon` reuses from `TM.iconPool` or builds once; `ReleaseIcon` hides, clears points, reparents to `UIParent` (never `nil`) and returns it. Pulse timers moved onto the frame so recycled icons restart cleanly, and a hidden frame's `OnUpdate` doesn't fire, so parked icons cost nothing. Added `TM:UnmarkAll()` for a clean teardown path.

### 9.5 Docs — `ARCHITECTURE.md` rebuilt, `.bootstrap.md` corrected

`ARCHITECTURE.md` replaced wholesale, generated from the TOC and checked against source. Unbuilt ideas moved to a labelled §9 rather than deleted. `.bootstrap.md`'s reading list now points at it, marks `.context.md` / `.competitors.md` / `ROADMAP.lua` / `PINNED_FEATURES.lua` / this file as superseded, adds a "trust but verify" note, corrects the stale priority list (AutoMount and QuestRewardAdvisor were listed as TODO while shipping), and carries the §5 licensing findings — since it is the one file every future session reads first.

`.context.md` and `.competitors.md` were **not deleted**, only marked superseded. That's the user's call.

### 9.6 Map IDs are systematically unreliable — found while rewriting the docs

Checking `.rules.md`'s claim that `Data/Zones.lua` holds portal data (it doesn't — that's `TravelRouter.PORTALS`) surfaced a broader problem. The Midnight map IDs were invented by incrementing from a guessed parent: `TravelRouter.PORTALS` routed Quel'Thalas → Eversong/Silvermoon/Naigtal as **2435 / 2436 / 2437**. None are Midnight maps — 2435 and 2436 appear in no installed reference addon, and **2437 is Zul'Aman**. Corrected to 2395 / 2393 / 2600.

This is a nastier failure mode than the stub coords in §4. A `0,0` coord is visibly broken; a plausible wrong map ID routes the player confidently to the wrong continent.

**Two things left unfixed on purpose:**

- **`2434`** — the Quel'Thalas parent, used in `TravelRouter.PORTALS` *and* as `zone` plus every `coord.map` in `TAG_Midnight_Intro.lua`. Every other Midnight ID cross-checks against an installed addon; 2434 appears in none of them. This downgrades §4's "one complete guide" — its x/y values are real, but they may be anchored to a map that doesn't exist. I could not determine the right value from static files.
- **Three TWW portal entries** whose IDs contradict their own labels (`2215` → "Emerald Dream" but 2215 is Hallowfall; `2248` → "Khaz Algar" but that's Isle of Dorn; `2339` → "Hallowfall" but that's Dornogal). Which portals actually exist from Stormwind and Orgrimmar is a game-content question, not one answerable from another addon's files, so I flagged them in-file rather than guessing.

Both are marked with a `⚠ UNVERIFIED MAP IDs` block in `TravelRouter.lua` and in `ARCHITECTURE.md` §8.6. One PTR session with `/run print(C_Map.GetBestMapForUnit("player"))` settles all of it, and should happen before any further coordinate work.

### 9.7 Not done

- **`DB_DEFAULTS` aliasing** (§3.2) and **`/ta reset` dangling refs** (§3.3) — both small, both left alone as unrequested.
- **`QuestTracker.lua` split** (§3.5) — correctly a separate piece of work.
- **`Core/GuideManager.lua`** — 168 lines, 13 methods, zero consumers, loaded every login. Finish the migration its own header TODO describes, or delete it. Documented in `ARCHITECTURE.md` §8.1.
- **Moving `TravelRouter.PORTALS` into `Data/Portals.lua`** — it violates the project's static-data separation rule and is why `.rules.md` points at the wrong file.
