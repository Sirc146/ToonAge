# ToonAge 2.0 — Rebuild Workspace

Planning workspace and staging area for the 2.0 rebuild. Nothing here is loaded
by the game: no file in this folder is referenced by `ToonAge.toc`, so it is
inert to the WoW client.

**This folder is no longer markdown-only.** As of Entry 003 it also holds 2.0
Lua drafts under `Core/`.

> **Consequence worth knowing:** `Tools/check_lua.py` parses the files listed in
> `ToonAge.toc`, so it does **not** cover anything in here. A 2.0 draft gets its
> syntax coverage only from the test that executes it — currently
> `python Tools/test_dispatch.py`, which loads `Core/Init.lua` into embedded
> Lua 5.1. If it runs, it parsed. A draft with no test has no coverage at all.

## Read in this order

| File | Purpose |
|---|---|
| [DIRECTIVE.md](DIRECTIVE.md) | The standing contract — persona, six SDLC capabilities, execution protocol. Read first in any new session. |
| [JOURNAL.md](JOURNAL.md) | Append-only phase log. Current state, what's next, open decisions. Read second. |
| [STAGE0_POSTMORTEM.md](STAGE0_POSTMORTEM.md) | Legacy inventory and structural findings from the teardown. |

## 2.0 source drafts

| File | Status | Test |
|---|---|---|
| `Core/Init.lua` | Draft — dispatcher + F-1…F-7 complete. Not wired into the TOC. | `python Tools/test_dispatch.py` (86 checks) |

`python Tools/mutate_dispatch.py` backs each fix out of the 2.0 draft one at a
time and proves the suite goes red, then restores. `.rules.md`: *"A suite that
has never been seen to fail is not evidence."* It caught two hollow tests the
first time it ran — see JOURNAL Entry 003. Run it after changing either file.

## Pre-existing documentation (not superseded)

These live at the addon root and remain authoritative for 1.x. This workspace
**links** to them; it does not restate or replace them.

- `../.rules.md` — development rules & style guide for 1.x
- `../ARCHITECTURE.md` — current system architecture
- `../IMPROVEMENT_PLAN.md` — prior improvement backlog
- `../TODO.md` — outstanding work items
- `../.bootstrap.md` — session bootstrap notes
