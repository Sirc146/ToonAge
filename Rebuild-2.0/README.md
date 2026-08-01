# ToonAge 2.0 — Rebuild Workspace

Nothing in this folder is loaded by the game. No file here is referenced by
`ToonAge.toc`, so it is inert to the WoW client.

| File | Purpose |
|---|---|
| [DIRECTIVE.md](DIRECTIVE.md) | The standing contract. Read first. |
| [STATE.md](STATE.md) | What is true now, what is undecided, what is next. Read second. |
| `Core/Init.lua` | The 2.0 dispatcher draft. Not in the TOC; never loaded by the client. |

**Test coverage warning.** `Tools/check_lua.py` parses the files listed in
`ToonAge.toc`, so it does **not** cover anything in this folder. The 2.0 draft's
only syntax coverage comes from `python Tools/test_dispatch.py` executing it in
embedded Lua 5.1 — if it runs, it parsed. Run `python Tools/mutate_dispatch.py`
after changing either: it backs each fix out and proves the suite goes red.
A suite never seen to fail is not evidence; that check caught two hollow tests
the first time it ran.

Root docs (`../.rules.md`, `../ARCHITECTURE.md`, `../TODO.md`) remain
authoritative for 1.x. This workspace links to them; it does not restate them.
