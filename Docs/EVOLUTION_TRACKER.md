# ToonAge Evolution Tracker

**Last Updated:** 2026-08-08
**Status:** In Progress — Phase 1 not yet started in code
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
**Status:** NOT STARTED
**What exists:** Backend is complete — `InitTasks()`, `ToggleTask()`, `AddTask()`, `RemoveTask()`, `GetTasksByCategory()`, `CheckResets()` all work. Slash command `/ta todo` displays them in chat.
**What's needed:** Add a "WEEKLY TASKS" section after the vault footer in `Weekly:Render()`. Render each task as a clickable row (checkbox toggle). Group by category. Show completion progress summary. Wire the `ToggleTask()` call to OnClick.
**Key data:** `TA.charDB.tasks.list` — array of `{id, text, reset, category, done}`. `GetTasksByCategory()` returns them grouped.

### 1B: Wire vault reward scoring through Gear's stat-weight engine
**File:** `Modules/Progression/Weekly.lua`
**Status:** NOT STARTED
**What exists:** `Gear.CalculateItemScore(itemLink, specID, mode)` is exposed. Vault API gives `act.rewardItemIlvl` but NOT an item link — so direct scoring requires `C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityIndex)` (verify it exists on 12.0.7/12.1.0 first with `/dump`).
**What's needed:** In the vault tier card, if the tier is unlocked AND a reward link is obtainable, show the weighted score alongside ilvl. Format: "619 iLvl (+8% for you)" or "619 iLvl (sidegrade)". Falls back to raw ilvl if no link available.
**API to verify:** `C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityIndex)` — may not exist, may need alternative route.

### 1C: Add world quest filter/tracker to Weekly tab
**File:** `Modules/Progression/Weekly.lua` (or new `Modules/Progression/WorldQuests.lua`)
**Status:** NOT STARTED
**What's needed:**
- Use `C_TaskQuest.GetQuestsForPlayerByMapID(mapID)` to get active WQs
- Filter by reward type: gear (show stat-weight score), gold, reputation, profession mats
- Sort by value-per-time or by expiry (soonest first)
- Render in Weekly tab below tasks section, or as a sidebar panel
- "Show on Map" button per WQ that sets a Blizzard waypoint
**Key APIs:** `C_TaskQuest.GetQuestsForPlayerByMapID()`, `C_TaskQuest.GetQuestTimeLeftMinutes()`, `C_QuestLog.GetQuestTagInfo()`, `GetQuestLogRewardMoney()`, `C_QuestLog.GetQuestRewardCurrencies()`

---

## Remaining Work — Phase 2 (Make It Functional)

### 2A: "What To Do Next" daily priority advisor
**File:** New section at top of Weekly tab (or new sidebar widget)
**Status:** NOT STARTED
**Design:** Priority-ranked list of 3-5 recommendations based on:
- Vault progress gaps ("Run 2 more M+ for Tier 3")
- Daily/weekly reset proximity ("Calling expires in 3h")
- Expiring WQs with high value
- Profession cooldowns ready
- Conquest cap distance
- Bountiful delve not done

### 2B: Guide tab pivot to world content at max level
**File:** `Modules/Navigation/QuestTracker.lua`
**Status:** NOT STARTED
**What's needed:** When player is max level AND no leveling guide is active, the Guide tab should show:
- Active world quests in current zone
- Daily/weekly reputation quests
- Rare spawn timers (if trackable)
- "Suggested activity" from the Phase 2A advisor
**Currently:** Shows "No guide active" — dead end for max-level players.

### 2C: Author rotation conditions (top 5 specs)
**File:** `Data/RotationConditions.lua`
**Status:** Engine built, conditions not authored
**What's needed:** Write condition functions for the top 5 most-played specs that evaluate against `CombatState.state` for live prediction. Start with: Ret Paladin, Frost DK, BM Hunter, Fire Mage, Havoc DH (popular leveling/solo specs).
**Format:** Each entry: `{ spellID=X, condition = function(s) return s.powerPct > 80 end }`

---

## Remaining Work — Phase 3 (Make It Pretty)

### 3: UX consistency pass
**Status:** NOT STARTED
**Scope:**
- Unified card/row component pattern across all tabs
- Consistent padding (14px sides, 8px between rows)
- Typography hierarchy (13pt headers, 11pt body, 9pt metadata)
- Interactive feedback (hover states, click confirmation)
- Color language (green=good/done, gold=highlight/header, grey=inactive, red=warning)
- Smooth scrolling behavior
- Tab transition feels cohesive (no flash/flicker)

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
