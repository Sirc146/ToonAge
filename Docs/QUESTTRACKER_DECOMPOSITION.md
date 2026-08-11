# QuestTracker.lua Decomposition Plan

**File:** `Modules/Navigation/QuestTracker.lua`
**Current size:** 3,842 lines (10% of codebase)
**Goal:** Split into 4 focused files, each under 1,200 lines.

---

## Current Function Map (by natural seam)

### Seam 1: Step Evaluation & Guide Logic (lines 38–755)
~717 lines — The "brain" that decides what step to show next.

| Function | Line | Purpose |
|---|---|---|
| `IsComplete()` | 38 | Quest completion check |
| `IsInLog()` | 43 | Quest in quest log |
| `IsReadyForTurnIn()` | 48 | Quest ready to turn in |
| `QT:GetQuestStatus()` | 59 | Composite status |
| `QT:IsStepApplicable()` | 69 | Step filtering (class/race/level) |
| `IsPlayerFlying()` | 92 | Flight state |
| `IsObjectiveFinished()` | 100 | Objective completion |
| `QT:IsStepComplete()` | 108 | Full step evaluation |
| `QT:IsPrerequisiteMet()` | 185 | Prerequisite check |
| `QT:PassesRankFilter()` | 211 | Optional/difficulty filter |
| `QT:IsActiveConditionMet()` | 224 | Dynamic conditions |
| `QT:IsLootMet()` | 231 | Loot requirement |
| `QT:SetSticky()` | 240 | Pin step to display |
| `QT:RemoveSticky()` | 249 | Unpin step |
| `QT:SkipStep()` | 259 | Mark step skipped |
| `QT:ShouldShowStep()` | 284 | Visibility composite |
| `QT:ApplySpatialRouting()` | 324 | Reorder by proximity |
| `QT:FastForward()` | 378 | Skip completed steps |
| `MapZoneDistance()` | 480 | Zone distance scoring |
| `MapIsInZone()` | 492 | Zone membership |
| `QT:GetSortedGuideList()` | 496 | Sort guides by relevance |
| `QT:SetGuide()` | 507 | Activate a guide |
| `QT:SmartMatchGuideFromLog()` | 527 | Match guide from quest log |
| `QT:AutoSelectGuide()` | 580 | Automatic guide selection |
| `QT:Diagnose()` | 670 | Debug diagnostic |
| `QT:CycleGuide()` | 733 | Next/prev guide |
| `QT:SaveState()` | 744 | Persist stepIdx/guideID |
| `GetGuideExpectedQuestIDs()` | 755 | Guide quest ID extraction |

**Proposed file:** `Modules/Navigation/QuestLogic.lua`

---

### Seam 2: Auto-Quest & Gossip Automation (lines 772–1020)
~248 lines — The automation system (auto-accept, auto-turn-in, gossip handling).

| Function | Line | Purpose |
|---|---|---|
| `QT:HandleAutoQuest()` | 772 | Auto-accept/turn-in/gossip |
| `QT:UpdateBlizzardTrackerVisibility()` | 981 | Replace Blizzard tracker |
| `QT:OnEvent()` | 992 | Event dispatch |
| `QT:Init()` | 1021 | Module initialization |

**Proposed file:** Stays in `QuestTracker.lua` (this IS the module core).

---

### Seam 3: Tracker Window & UI (lines 1127–2480)
~1,353 lines — All the floating window rendering, window management, and UI helpers.

| Function | Line | Purpose |
|---|---|---|
| `ApplyBD()` | 1127 | Backdrop helper |
| `Divider()` | 1133 | Separator helper |
| `MakeBtn()` | 1141 | Button factory |
| `MakeCheckbox()` | 1163 | Checkbox factory |
| `QT:InitWindow()` | 1206 | Window construction |
| `QT:UpdateQuestItemButton()` | 1506 | Quest item button |
| `QT:UpdateWindow()` | 1585 | Full window rebuild |
| `QT:RenderStatusLine()` | 1930 | Distance/ETA line |
| `QT:ToggleWindow()` | 2050 | Show/hide window |
| `QT:AnalyzeQuestLog()` | 2084 | Quest log analysis |
| `QT:ShowQuestLogCleanup()` | 2144 | Cleanup popup |
| `QT:AnalyzeQuestProgress()` | 2228 | Progress analysis |
| `QT:ShowQuestLogAdvisor()` | 2303 | Advisor popup |
| `QT:GetUnrelatedQuests()` | 2371 | Find unrelated quests |
| `QT:ShowDropUnrelatedPopup()` | 2403 | Drop popup |

**Proposed file:** `Modules/Navigation/TrackerWindow.lua`

---

### Seam 4: Tab Render & Guide Browser (lines 2482–3605)
~1,123 lines — The main panel tab render (expansion filter, guide cards, middle panel).

| Function | Line | Purpose |
|---|---|---|
| `QT:DetectBestExpansion()` | 2482 | Expansion auto-detect |
| `QT:Render()` | 2514 | Main panel render |
| `QT:ClassifyGuideExpansion()` | 2652 | Guide→expansion mapping |
| `QT:RenderMiddlePanel()` | 2687 | Content panel renderer |
| `QT:ShowToast()` | 3111 | Toast notification |
| `QT:GetStepContextHint()` | 3157 | Step context helper |
| `QT:ShowTrackerMenu()` | 3207 | Context menu dispatch |
| `QT:ShowTrackerMenuModern()` | 3216 | Modern context menu |
| `QT:ShowTrackerMenuLegacy()` | 3335 | Legacy context menu |
| `QT:CheckProximityAdvance()` | 3502 | Proximity auto-advance |
| `QT:InitDrawerMode()` | 3583 | Drawer mode setup |
| `QT:UpdateDrawer()` | 3604 | Drawer refresh |

**Proposed file:** `Modules/Navigation/GuideBrowserTab.lua`

---

## Proposed Final Structure

```
Modules/Navigation/
├── QuestTracker.lua        (~500 lines — Init, OnEvent, AutoQuest, state, slash commands)
├── QuestLogic.lua          (~720 lines — step evaluation, guide selection, fast-forward)
├── TrackerWindow.lua       (~1,350 lines — floating window, window management, popups)
├── GuideBrowserTab.lua     (~1,120 lines — tab Render, expansion filter, guide cards)
└── ... (Arrow, NavHud, etc.)
```

---

## Execution Plan

**Order matters — each file depends on the previous:**

1. **Extract `QuestLogic.lua` first** — it's pure logic, no UI. Other files call into it.
   - Move all step evaluation functions
   - Attach to `QT` (same module table, just defined in a separate file)
   - Add to TOC before QuestTracker.lua

2. **Extract `TrackerWindow.lua`** — the floating window
   - Move InitWindow, UpdateWindow, RenderStatusLine, ToggleWindow, all popups
   - Keep ApplyBD/Divider/MakeBtn as local helpers in this file

3. **Extract `GuideBrowserTab.lua`** — the tab render
   - Move Render, RenderMiddlePanel, DetectBestExpansion, ClassifyGuideExpansion
   - Also move ShowToast, context menus, CheckProximityAdvance, drawer mode

4. **QuestTracker.lua remains** as the slim orchestrator:
   - Module registration, Init, OnEvent, HandleAutoQuest
   - State vars (guideID, stepIdx, etc.)
   - Slash commands

**Key constraint:** All four files write methods onto the same `QT` table (which is the registered module). They just live in separate files. The TOC load order determines availability:
```
Modules\Navigation\QuestLogic.lua        ← loads first (pure logic)
Modules\Navigation\QuestTracker.lua      ← loads second (orchestrator, Init)
Modules\Navigation\TrackerWindow.lua     ← loads third (UI, needs Init to have run for charDB)
Modules\Navigation\GuideBrowserTab.lua   ← loads fourth (tab render)
```

---

## Risk Assessment

| Risk | Mitigation |
|---|---|
| Local helper functions won't be visible across files | Move to file scope in the file that uses them, or promote to QT:Method |
| TOC load order matters | QuestLogic first (no deps), then QuestTracker (sets up state), then UI files |
| `self` references break if module table changes | All files reference the same `QT` table via `local QT = TA:GetModule("QuestTracker")` at top |
| Testing: can't test without all files | Run `check_lua.py` on each file independently + full TOC check |

---

## When to Execute

This decomposition is a **refactoring-only** change — no new features, no behavior changes. Do it:
- After the current audit fixes are tested in-game
- Before adding new QuestTracker features (world content pivot already touches RenderMiddlePanel)
- In a single focused session with no other changes in the commit
