---
inclusion: auto
---

# ToonAge — Collaboration Protocol

This file is loaded at the start of every Kiro/Claude session working on ToonAge.
It prevents duplicate work, code conflicts, and context loss between sessions.

---

## Rule 1: Read Before Writing

Before modifying ANY file, read these in order:
1. `Docs/EVOLUTION_TRACKER.md` — what's done, what's in progress, what's next
2. `Docs/SIDE_TASKS.md` — self-contained task definitions with status
3. The actual file you plan to modify — never write code you haven't read first

If a task is marked `[x]` or says "COMPLETED" — do not redo it.
If a task says "IN PROGRESS" — read the file to see how far it got before continuing.

---

## Rule 2: Claim Before Starting

When you begin a task:
1. Open `Docs/EVOLUTION_TRACKER.md`
2. Change the task status from "NOT STARTED" to "IN PROGRESS — [date] [agent]"
3. Write what you intend to do in one line

This prevents another session from starting the same work.

---

## Rule 3: Mark When Done

When you finish a task:
1. Change status to "COMPLETED — [date]"
2. List files modified
3. Note anything the next task depends on
4. Update `SIDE_TASKS.md` if the task there needs a status change

---

## Rule 4: Never Duplicate Code

Before adding a function, search for it first:
- `grep_search` for the function name across the codebase
- Check if a utility already exists in `Core/Utils.lua`
- Check if a module already exposes what you need via `TA:GetModule()`

Common traps:
- `CalculateItemScore` exists in `Gear.lua` — don't rewrite it
- `U.GetPlayerSpec()` exists in Utils — don't inline spec detection
- `U.SafeNum()` / `U.SafeCall()` exist — don't write your own pcall wrappers
- The frame pool pattern is in `Core/UI.lua` — use `Track()` in module renders

---

## Rule 5: Follow the Module Contract

Every new module MUST follow:
```lua
local TA = ToonAge
local U  = TA.Utils
local M  = {}
TA:RegisterModule("ModuleName", M)

function M:Init() end        -- optional, runs at login
function M:OnEvent(event, ...) end  -- optional, receives events
function M:Render(content, sidebar) end  -- optional, draws a tab
M.SlashCommands = {}         -- optional, /ta commands
```

Place in the correct `Modules/<Domain>/` subdirectory.
Add to `ToonAge.toc` in the matching section header.

---

## Rule 6: Git Discipline

- Always work on branch `2.0`
- Commit with descriptive messages: `"Phase 1A: render weekly tasks in tab UI"`
- Never force-push
- Never amend pushed commits
- Stage specific files, not `git add -A` (avoids committing temp files)
- Check `git status` before starting — if there are unstaged changes from a previous session, commit them first or understand what they are

---

## Rule 7: Classic vs Retail Awareness

- PTR (`_ptr_`) is the git repo and source of truth — edit HERE
- Retail (`_retail_`) is a deploy target — never edit directly, use `Tools/deploy.ps1`
- Classic (`_classic_`) is a separate unversioned copy — edits go there directly for now
- Not all features apply to Classic (no C_Traits, no C_WeeklyRewards, no world quests)
- Container API on Classic uses `C_Container.*` (not bare globals)
- When adding retail features, note "N/A Classic" in the tracker

---

## Rule 8: Test Before Declaring Done

- Run `python Tools/check_lua.py` after any code change (syntax check)
- Verify TOC entries resolve: every .lua/.xml in the TOC must exist on disk
- If you can't test in-game, say so explicitly — don't claim it works

---

## Rule 9: Handoff Notes

At the END of every session, if work is incomplete:
1. Update `EVOLUTION_TRACKER.md` with current state
2. If you created a new approach or pattern, document it in the file header
3. Leave a clear "NEXT STEP" note so the next session knows exactly where to pick up

---

## Project Quick Reference

| Item | Location |
|---|---|
| Git repo | `C:\Program Files (x86)\World of Warcraft\_ptr_\Interface\AddOns\ToonAge` |
| Branch | `2.0` |
| Remote | `https://github.com/Sirc146/ToonAge.git` |
| Classic copy | `C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\ToonAge` |
| Desktop backup | `E:\OneDrive\Desktop\ToonAge\Retail` and `\Classic` |
| Syntax check | `python Tools/check_lua.py` |
| Deploy to retail | `.\Tools\deploy.ps1 -Client _retail_` |
| Release | `.\Tools\release.ps1 -Version "X.Y.Z" -Message "desc"` |
| WowUp endpoint | `https://api.github.com/repos/Sirc146/ToonAge/releases/latest` |
| Style guide | `.rules.md` |
| TOC | `ToonAge.toc` (82 entries retail, 36 Classic) |
