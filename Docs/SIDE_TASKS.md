# ToonAge — Side Tasks for Claude Sessions

**Purpose:** Self-contained tasks you can hand to a new Claude/Kiro session.
Each task has everything needed to execute without prior context.

---

## Task 1: Render Weekly Tasks in the Tab UI

**File:** `Modules/Progression/Weekly.lua`
**Goal:** Add a visual task checklist below the Great Vault section.

**Context:** The backend is already built. `TA.charDB.tasks.list` is an array of `{id, text, reset, category, done}`. Methods exist: `Weekly:GetTasksByCategory()`, `Weekly:ToggleTask(taskID)`, `Weekly:GetTaskSummary()`.

**Instructions:**
1. In `Weekly:Render()`, after the vault footer section (after the final `content:SetHeight()` call at ~line 330), add a new section.
2. Add a separator and "WEEKLY TASKS" header matching the vault header style.
3. Show a summary line: "5/9 tasks done this week"
4. Render each task as a clickable row:
   - Green checkmark or grey circle based on `task.done`
   - Task text
   - Category badge (right-aligned, small grey text)
   - Reset type indicator (daily vs weekly, small text)
   - `OnClick` calls `Weekly:ToggleTask(task.id)` then refreshes the row
5. Group tasks by category with small section headers.
6. Move the `content:SetHeight()` call to AFTER the tasks section so scroll works.
7. Use the same `Track()`, `MkBackdrop()`, and color patterns already in the file.

**Test:** `/reload`, open ToonAge, click Weekly tab. Tasks should appear below vault. Click a task to toggle it.

---

## Task 2: Verify Vault Scoring API

**File:** None (in-game verification)
**Goal:** Determine if we can get item links from vault rewards for stat-weight scoring.

**Instructions:**
1. Log into Retail (12.0.7) with a character that has vault progress.
2. Run these commands:
```
/dump C_WeeklyRewards.GetExampleRewardItemHyperlinks
/dump C_WeeklyRewards.CanClaimRewards()
/run local acts = C_WeeklyRewards.GetActivities(1); for i,a in ipairs(acts) do print(i, a.id, a.progress, a.threshold, a.rewardItemIlvl) end
```
3. If `GetExampleRewardItemHyperlinks` exists, try: `/dump C_WeeklyRewards.GetExampleRewardItemHyperlinks(1)`
4. Record what fields are available on the activity table.
5. Update `Docs/EVOLUTION_TRACKER.md` section 1B with findings.

**What we need to know:** Can we get an actual item link from vault rewards before they're claimed? If yes, we can run `CalculateItemScore()` on it. If no, we fall back to ilvl-only display.

---

## Task 3: World Quest API Exploration

**File:** None (in-game verification), then new module or section in Weekly.lua
**Goal:** Map out the C_TaskQuest API for world quest tracking.

**Instructions:**
1. Log into Retail at max level in a zone with world quests.
2. Run:
```
/run local mapID = C_Map.GetBestMapForUnit("player"); print("Map:", mapID); local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID); print("WQs:", quests and #quests or "nil")
/run local mapID = C_Map.GetBestMapForUnit("player"); local qs = C_TaskQuest.GetQuestsForPlayerByMapID(mapID); if qs then for i,q in ipairs(qs) do if i <= 5 then print(q.questId, q.x, q.y, C_TaskQuest.GetQuestTimeLeftMinutes(q.questId) .. "min") end end end
```
3. For each quest found, check reward type:
```
/run local qid = QUEST_ID_HERE; print("Gold:", GetQuestLogRewardMoney(qid)); local n = GetNumQuestLogRewards(qid); for i=1,n do local name,_,_,_,_,iid = GetQuestLogRewardInfo(i, qid); print("Item:", name, iid) end
```
4. Document the API shape and which fields are reliably present.
5. Create `Modules/Progression/WorldQuests.lua` as a registered module with:
   - `Init()` that registers `QUEST_LOG_UPDATE`
   - `GetFilteredQuests(mapID, filter)` where filter is "gear"/"gold"/"rep"/"mats"
   - Returns sorted array of `{questId, title, reward, timeLeft, x, y}`

---

## Task 4: Fill Guide Coordinates (Manual — In-Game Work)

**Files:** `Data/Guides/TAG_Hallowfall.lua` (309 steps, all stubs)
**Goal:** Replace stub coords with real ones.

**Instructions:**
1. Log into PTR, travel to Hallowfall.
2. At each quest location, run: `/run local m=C_Map.GetBestMapForUnit("player"); local p=C_Map.GetPlayerMapPosition(m,"player"); print(m, string.format("%.2f, %.2f", p.x*100, p.y*100))`
3. Open `Data/Guides/TAG_Hallowfall.lua` and update each step's `coord = { map = XXXX, x = XX.XX, y = XX.XX }`
4. The zone mapID for Hallowfall is **2215** (verified).
5. Start with the first 20 steps — even partial progress is valuable.
6. Commit with message: "Fill Hallowfall coords (steps 1-N)"

---

## Task 5: Classic Character Tab Fix

**File:** `Modules/Character/Character.lua` (Classic copy at `_classic_`)
**Goal:** Fix the blank Character tab on Classic.

**Context:** The tab renders blank. `Render()` calls `BuildUI()` which uses:
- `GetSpecialization()` — may not exist on MoP Classic
- `GetSpecializationInfo()` — may not exist
- `GetCombatRating()` — exists but signature may differ
- `BackdropTemplate` in `CreateFrame()` — exists on 5.5.4 (confirmed)

**Instructions:**
1. Log into MoP Classic, run: `/dump GetSpecialization, GetSpecializationInfo, GetActiveSpecGroup`
2. The Classic equivalent is `GetActiveSpecGroup()` + `GetSpecializationInfo(specIndex, false, false, nil, UnitSex("player"))`
3. Add guards in `Character:BuildUI()` and `Character:UpdateData()`:
   - If `GetSpecialization` is nil, use `GetActiveSpecGroup`
   - If stat APIs return nil, show "N/A" instead of erroring
4. Test: Open ToonAge panel → Character tab should show stats.

---

## Task 6: Commit and Push the Restructure

**Goal:** Get the current restructure into git and push to GitHub.

**Instructions:**
1. `cd` to the repo: `C:\Program Files (x86)\World of Warcraft\_ptr_\Interface\AddOns\ToonAge`
2. Stage everything:
```powershell
git add -A
git status  # Review — should show renames, new Docs/, deleted cruft
git commit -m "2.0 restructure: domain-based module layout, clean Data names, Docs/, pipeline"
```
3. Push:
```powershell
git push origin 2.0
```
4. Verify at: https://github.com/Sirc146/ToonAge/tree/2.0

---

## Task 7: First Release Test

**Goal:** Test the full release pipeline end-to-end.

**Instructions:**
1. After Task 6 (committed and pushed), run:
```powershell
.\Tools\release.ps1 -Version "2.0.0-dev.1" -Message "First dev build: folder restructure complete"
```
2. Check GitHub Actions: https://github.com/Sirc146/ToonAge/actions
3. Verify a Release appears with `ToonAge-v2.0.0-dev.1.zip`
4. Download the ZIP, verify it contains a single `ToonAge/` folder at the top level
5. Try adding via WowUp URL: `https://github.com/Sirc146/ToonAge`

**Prerequisite:** GitHub repo Settings → Actions → General → Workflow permissions → Read and write

---

## Task Priority Order

| # | Task | Can do without game? | Dependency | Status |
|---|---|---|---|---|
| 6 | Commit & push restructure | Yes | None | **COMPLETED — 2026-08-08, commit dc56774** |
| 7 | First release test | Yes | Task 6 | READY — run `.\Tools\release.ps1 -Version "2.0.0-dev.1" -Message "First dev build"` then check GitHub Actions |
| 1 | Render weekly tasks in UI | Yes (code only) | None | NOT STARTED |
| 5 | Classic Character fix | Needs Classic client | None | NOT STARTED |
| 2 | Vault scoring API verify | Needs Retail client | None | NOT STARTED |
| 3 | World Quest API explore | Needs Retail client | None | NOT STARTED |
| 4 | Fill guide coords | Needs PTR client | None | NOT STARTED |

Start with 6 → 7 → 1 if working outside the game.
Start with 2 → 3 → 5 if in-game.
