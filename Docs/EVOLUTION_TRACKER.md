# ToonAge Evolution Tracker

**Last Updated:** 2026-08-08
**Status:** Phase 1-3 COMPLETE + Audit fixes + Full leveling coverage + Evolution features
**Branch:** `2.0`

---

## What Was Completed This Session

### Structure & Pipeline
- [x] Full 2.0 folder restructure (PTR, Retail, Classic all aligned)
- [x] Modules organized into 8 domain subdirectories (Navigation, Combat, Gear, Character, Progression, Farming, Automation, Infrastructure)
- [x] Data files renamed for consistency (TA_Enchants → Enchants, FarmOptimizer_Data → FarmRoutes, Professions_Data → Professions)
- [x] Docs/ folder created, planning docs consolidated
- [x] Cruft removed (Rebuild-2.0/, Archive/, Monk/, TODO.md, .bootstrap.md, PRIVACY.md, TestBar.lua)
- [x] TOC updated and validated (82 entries PTR, 36 Classic)
- [x] GitHub Actions release workflow (.github/workflows/release.yml)
- [x] Tools/release.ps1 (tag-and-push automation)
- [x] Tester lock in Core/Init.lua (auto-activates on -dev versions)
- [x] deploy.ps1 updated to exclude .github and Docs
- [x] Docs/TESTER_SETUP.md written for testers
- [x] Full copies deployed to E:\OneDrive\Desktop\ToonAge\Retail and \Classic

### Classic Fixes
- [x] Bindings.xml — removed `category` attribute (MoP Classic doesn't support it) — STILL ERRORING, likely cosmetic across all addons
- [x] Container API — Utils.lua now tries C_Container first, falls back to bare globals
- [x] Gear.lua — all GetContainerItemLink/NumSlots calls routed through U.* wrappers
- [x] AutoEquip.lua — all GetContainerItemID calls routed through U.* wrappers
- [x] QuestTracker.lua — added stub methods (UpdateWindow, CheckProximityAdvance, ShowToast, ToggleWindow)
- [x] QuestTracker.lua — added Render method for Guide tab
- [x] Gear.lua — added Render method for Gear tab (Classic)
- [x] Stale WoW client copies removed (_retail_, _classic_ old, _ptr_ test harness, _retail_ test harness)

### Assessment Completed
- [x] Full tab-by-tab feature audit with scores
- [x] Cross-tab integration analysis
- [x] Community pain point research (Midnight forums, addon comparisons)
- [x] "Beyond 10/10" evolution features identified

---

## Remaining Work — Phase 1 (Make It Work)

### 1A: Render custom weekly tasks in Weekly tab UI
**File:** `Modules/Progression/Weekly.lua`
**Status:** COMPLETED — 2026-08-08, commit `60be962`

### 1B: Wire vault reward scoring through Gear's stat-weight engine
**File:** `Modules/Progression/Weekly.lua`
**Status:** COMPLETED — 2026-08-08, commit `241d746`

### 1C: Add world quest filter/tracker to Weekly tab
**File:** `Modules/Progression/WorldQuests.lua` (new), `Weekly.lua`, `ToonAge.toc`
**Status:** COMPLETED — 2026-08-08, commit `b017e70`

---

## Remaining Work — Phase 2 (Make It Functional)

### 2A: "What To Do Next" daily priority advisor
**File:** `Modules/Progression/Weekly.lua`
**Status:** COMPLETED — 2026-08-08, commit `201476b`

### 2B: Guide tab pivot to world content at max level
**File:** `Modules/Navigation/QuestTracker.lua`
**Status:** COMPLETED — 2026-08-08, commit `201476b`

### 2C: Author rotation conditions (top 5 specs)
**File:** `Data/Rotations.lua`
**Status:** COMPLETED — 2026-08-08, commit `201476b`
**Specs covered:** Retribution Paladin, Frost DK, BM Hunter, Fire Mage, Havoc DH

---

## Remaining Work — Phase 3 (Make It Pretty)

### 3: UX consistency pass
**Status:** COMPLETED — 2026-08-08, commit `cf10cac`
**What was delivered:**
- Unified Component Factory in UIModern.lua Section 8
- 11 standardized factory methods (SectionHeader, SubHeader, InfoCard, DataRow, ProgressBar, ActionButton, Badge, Divider, Spacer, EmptyState)
- All return (frame, newY) for layout chaining
- Consistent PAD=14, RPAD=8 spacing
- Hover feedback built into interactive components
- Status color propagation via `status` field
- `.rules.md` updated with complete typography/color/component reference
- Existing tabs work as-is; new code should adopt the factory pattern

---

## Anniversary Edition (TBC Classic, Interface 20506)

### AE-1: Build the Anniversary stat/gear advisor
**Target:** `_anniversary_\Interface\AddOns\ToonAge` (outside this git repo — unversioned, like `_classic_`)
**Spec:** `Docs/CLASSIC_ANNIVERSARY_BRIEF.md`
**Status:** BUILT, NOT YET TESTED IN GAME — 2026-08-16 [Claude]
**Intent:** Copy the `_classic_` core framework, strip all Navigation/guide modules
(player uses Dugi), and add TBC combat-math modules: StatCaps, WeaponSkill,
RaceAdvisor, ProfessionAdvisor, plus TBC-adapted Character and Gear.

**Delivered** — 20 Lua files + TOC + Bindings.xml, all parsing under
`Tools/check_lua.py` (run with absolute paths; `REPO_ROOT` points at `_ptr_`).
Six tabs: Character, Stat Caps, Gear, Weapons, Racials, Professions.

| File | Role |
|---|---|
| `Core/TBCStats.lua` | The engine. Caps COMPUTED from level/weapon skill/target level, never table lookups. Rating→percent derived from the live client (`GetCombatRating / GetCombatRatingBonus`) with a documented level-formula fallback. |
| `Core/SkillScan.lua` | Weapon skills + professions from skill lines. Expands collapsed headers and restores them by name. `GetProfessions()` is NOT used — it is a 3.0 API. |
| `Core/Layout.lua` | Component factory. Every builder returns the next `y`; all coords floored; `Finish()` sets scroll height from the same `y`. Replaces `UIModern.lua`, which is not in this build. |
| `Modules/Character/StatCaps.lua` | The flagship tab. Target-context picker, per-cap bars, provenance section. |
| `Modules/Gear/Gear.lua` | Cap-aware scoring + bag upgrade finder. |

**Design decisions worth not re-litigating:**
- Caps are TARGET-RELATIVE. "9% hit" is the +3-boss number; a levelling character
  fighting same-level mobs needs 5%. Context defaults to `auto` (same-level below
  70, +3 at 70) and is user-pinnable via `/ta context`.
- "Hit > everything until capped" is implemented as MARGINAL value, not a blanket
  rule: rating that closes a real gap scores ×3, rating past the cap scores ×0.05.
  A literal reading would rank a 4-hit ring over 40 AP + 20 crit.
- No spec IDs anywhere. `GetSpecialization()` does not exist on 20506 — that is
  exactly what made the `_classic_` Character tab render blank (SIDE_TASKS Task 5).
  Role is inferred from class + shield, overridable with `/ta role`.
- Unmapped `GetItemStats` keys are collected and reported by `/ta statkeys`
  rather than silently dropped.

### AE-2: PvP mode + trinket scoring bug
**Status:** BUILT, NOT YET TESTED — 2026-08-16 [Claude]

**PvP is a MODE, not a tab.** `db.pvpMode` flips one flag and five behaviours
follow, through `TBCStats:ActiveContextKey()` and `Data.GetWeights()`: cap target
pinned to same-level, melee hit 9%→5%, spell hit 16%→3%, defense uncrittable
dropped, PvP stat weights, resilience surfaced. Context resolution was duplicated
in four files and is now one function — that duplication was exactly how PvP mode
would have been honoured in some tabs and forgotten in others.

**Resilience** reads `CR_CRIT_TAKEN_MELEE` — note the name, there is no
`CR_RESILIENCE` in TBC, and searching for the obvious name would have silently
fallen through to the numeric guess.

**BUG FIXED — trinkets scored as zero.** `GetItemStats` returns static stats
only; it reports nothing for `Use:` or `Chance on hit:` lines. Bloodlust Brooch,
Icon of the Silver Crescent and Dragonspine Trophy therefore scored ~0, ranked
below a green with +8 Stamina, and would have been offered for replacement.
`Core/TooltipScan.lua` now detects unscoreable value (via Blizzard's own
localized `ITEM_SPELL_TRIGGER_*` globals, not hardcoded English) and such items
are marked "not ranked", excluded from "weakest slot", and skipped as replacement
targets. **The fix is detection, not estimation** — pricing an on-use needs
rotation and fight length, and a made-up number would look authoritative.

**Armor type check (Gear tab):** Hunters and Shamans unlock Mail at 40 and the
game never says so. Equipped subtypes are compared against what the class can
wear now; lighter slots are flagged as free armor.

### Rejected source data — do not re-add without verification
The user supplied cross-class reference dumps. The talent one-liners are used as
commentary keyed by talent NAME (the client supplies tier and rank, so the
dump's tier errors are moot). These were **not** encoded:
- **Weapon proficiency by class** — 6 of 9 classes wrong: Hunters can use swords
  and fist weapons, Paladins cannot use staves, Druids can use fist weapons and
  polearms, Mage/Warlock can use 1H swords, Rogues can use bows/guns/crossbows.
- **Talent compendium as structure** — missing Rogue, Priest and Shaman entirely,
  truncated mid-Druid-Restoration, and several tiers misplaced.
The client answers both exactly for the current character (`GetTalentInfo`,
skill window), which is why the live reader is the right path.

### Bindings.xml is dead on Classic clients — stop trying to fix it
**Observed on Anniversary, 2026-08-16:**
`Interface/AddOns/ToonAge/Bindings.xml:5 Unrecognized XML: Binding`

That file had the canonical `<Bindings>`/`<Binding>` structure, **no BOM**
(checked byte-for-byte: first bytes were `3C 42 69 6E...`), and no `category`
attribute — the fix this tracker already recorded for `_classic_`, where the
entry still reads "STILL ERRORING". So `category` was never the whole cause.

Remaining known cause is the missing schema namespace on the root element. That
has been added to the file, but it is **UNVERIFIED** and the file is **removed
from ToonAge.toc**, because this is the second failure of a purely cosmetic
feature and a login error costs more than one keybind is worth. The addon opens
via `/ta`, the minimap button, and closes with ESC.

`BINDING_HEADER_TOONAGE` / `BINDING_NAME_TOONAGE_TOGGLE` remain defined in
`Core/Init.lua` and are harmless no-ops while the XML is unloaded. Re-enabling is
one TOC line; the file's own header comment explains how.

**Do not re-add Bindings.xml to any Classic-flavour TOC without loading it on a
real client first.** Two attempts, two failures, zero verification runs.

### AE-3: Wrong-advice fixes (talent hit, sockets)
**Status:** BUILT, NOT YET TESTED — 2026-08-16 [Claude]

**Talent-granted hit was not counted.** `GetCombatRatingBonus` reports hit from
RATING only. A Fury warrior with 3/3 Precision had 3% more hit than the addon
could see, so Stat Caps — the flagship tab — was telling them to find another
~47 rating they already had. Wrong on roughly a third of specs, in the direction
of "buy more of a stat you have enough of".

`TBCStats:GetBonusHit()` now resolves in trust order: manual `/ta hitbonus`
override → talent detection (`Data/TBCTalentHit.lua`, walks `GetTalentInfo`) →
racial. The tab attributes every point, so an unexplained total cannot hide a bug.

School-specific hit is kept separate on purpose: Arcane Focus is arcane only,
Suppression affliction only, Shadow Focus shadow only. A Shadow priest at 5/5
Shadow Focus is capped for Mind Blast and NOT for Holy Fire. Flattening those
would trade an obvious wrong answer for a subtle one.

Talent values are **unverified** — knowledge, not a dump. Three guards: the
manual override always wins, detection shows provenance in the UI, and a rank
above the expected maximum is clamped and flagged rather than multiplied out.

**Empty sockets were invisible.** `EMPTY_SOCKET_*` keys were landing in
`UnknownStatKeys` and vanishing. Now mapped AND extracted before weighting —
`Data.ExtractSockets` strips them out, because an empty socket is a hole, not a
stat, and weighting it would rank an unfilled item above a filled one.

---

## DESCOPED — user called stop 2026-08-16

Not built, deliberately. Recorded so they are not rediscovered as bugs:

| Item | Why it matters |
|---|---|
| `Modules/Character/Talents.lua` | Live tree reader over `GetTalentInfo`. The user supplied one-line talent descriptions to layer on by NAME (client gives tier and rank, so the source's tier errors are moot). API dependency already in the manifest via the hit detection. |
| **Weapon DPS in scoring** | `GetItemStats` returns no damage or speed, so weapons are ranked on stats alone — a 2H with 100 DPS scores below a dagger with more Strength. Fix is `TooltipScan` + the `DPS_TEMPLATE` global. Highest remaining wrong-advice risk. |
| **Set bonuses** | T4/T5/T6 2pc/4pc invisible; the upgrade finder will suggest breaking a 4pc. Fix is `TooltipScan` on the set lines. Warn on breaking rather than trying to price the bonus. |
| Enchant checklist, Aldor/Scryer, attunements, resistance sets, consumables, hunter ammo, badge/rep gear, alt tracking | Missing but honest — no wrong advice results from their absence. |

**NEXT STEP — needs the game:** `/reload`, then `/ta apiprobe` and `/ta dumpme`.
The API list in `Data/ApiManifest.lua` has NOT been confirmed by a live dump;
the probe is the confirmation. Highest-risk assumptions: `CR_*` globals exist
(numeric fallbacks are used and flagged if not), `GetCombatRatingBonus` semantics
for expertise/defense (sidestepped via `GetExpertiseRatingPerPoint` /
`GetDefenseRatingPerPoint`, which derive from points the client states directly),
and the `ITEM_MOD_*` key strings.

**Interface 20506 confirmed** by reading the `## Interface:` line of three addons
already installed and working on `_anniversary_`: `ElvUI_TBC.toc`,
`ZygorGuidesViewerClassicTBCAnniv.toc`, `DugisGuideViewerZ.toc`.

**Two numbers in the brief are wrong — do not "fix" the code back to them:**
- Brief says expertise cap = "26 (6.5%, **214 rating** at level 70)". 214 is the
  *level 80* figure (8.197 rating/expertise). At 70 it is 3.94 rating/expertise,
  so 26 expertise ≈ **102** rating.
- Brief says defense cap "490 heroics, **540** raids". 540 is the WotLK level-80
  number — it is exactly `80*5 + 140`. TBC uncrittable is `playerLevel*5 + 140`,
  i.e. **490** at 70 for any +3 target, heroic or raid.

Both are computed, not hardcoded, in `Core/TBCStats.lua`.

---

## Beyond 10/10 — Future Features (Post Phase 3)

| Feature | Priority | Difficulty | Impact |
|---|---|---|---|
| Housing Decor Tracker tab | HIGH | MEDIUM | First-mover in Midnight market |
| Gem/Enchant optimizer per slot | HIGH | LOW | Direct upgrade advice |
| Tier set bonus tracking in Gear tab | MEDIUM | LOW | Missing basic info |
| Dungeon route planner on NavHud | MEDIUM | HIGH | M+ players want this |
| Interrupt/kick reminder overlay | MEDIUM | LOW | Fills gap left by Blizzard restrictions |
| XP stacking advisor (leveling) | LOW | LOW | Nice to have |
| Mount collection tab | LOW | MEDIUM | Completionists |
| Party guide sync via C_ChatInfo | LOW | MEDIUM | Social stickiness |

---

## Key Technical Notes for Next Session

1. **`CalculateItemScore` is local in Gear.lua but exposed as `Gear.CalculateItemScore`** — call via `TA:GetModule("Gear").CalculateItemScore(link, specID, mode)`
2. **Vault API may not give item links** — `C_WeeklyRewards.GetExampleRewardItemHyperlinks()` needs verification on live. If unavailable, score by ilvl × 3 as fallback (same as Gear.lua's no-stat-budget path)
3. **World Quest API:** `C_TaskQuest.GetQuestsForPlayerByMapID(mapID)` returns `{x, y, questId, numObjectives, ...}` — mapID for current zone via `C_Map.GetBestMapForUnit("player")`
4. **Weekly:Render() currently ends at line ~330** — append the tasks UI section after `content:SetHeight()`
5. **The Classic build has different issues** — don't port world quest features there (Classic WQs don't exist). Only tasks UI and the UX pass apply to Classic.
6. **Git state:** On branch `2.0`, working tree has unstaged restructure changes. Commit before starting new work.
7. **WowUp endpoint:** `https://api.github.com/repos/Sirc146/ToonAge/releases/latest`
8. **Repo permissions needed:** GitHub → Settings → Actions → General → Workflow permissions → Read and write

---

## How to Resume

1. Open this file: `Docs/EVOLUTION_TRACKER.md`
2. Start with Phase 1A (simplest, highest visibility)
3. Read `Weekly.lua` from line 330 onward — that's where to append the tasks UI
4. Use the pattern from the existing vault cards (Track/Label/MkBackdrop) for consistency
5. Test with `/reload` — the tasks should appear below vault progress
6. Then move to 1B (vault scoring) and 1C (world quests)
