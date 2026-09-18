# ToonAgeOne — Trunk Reconciliation Manifest (Task 1)

Generated during the ToonAgeOne unification. This records how the single
Mainline trunk was assembled from the diverged source copies, so the decision
is auditable and no unique work is silently lost.

## Sources

| Copy | Role | Git tip | Notes |
|---|---|---|---|
| PTR | **Trunk** | `0d2f514` (branch `2.0`) | Richest build, 122 Lua files, holds `Core/StatEngine.lua` and unique uncommitted work. |
| XPTR | Reconciled in | `f3d6ff8` (branch `2.0`) | Diverged sibling. |
| Beta | (none) | — | Empty folder — no addon installed. Beta is a *test target* for the Mainline line, not a separate build. Its client build number is appended to the Mainline TOC `## Interface` list when a beta cycle is active. |

## PTR vs XPTR — commit graph

- Merge-base of the two branches is exactly XPTR's tip `f3d6ff8`.
- PTR contains **8 commits** XPTR does not (StatEngine, data-sources reference,
  rotation/talent/profession/stat data expansion, Anniversary build notes/brief,
  Bindings.xml TOC fix, UI-layout bug docs).
- XPTR contains **0 commits** PTR does not.

Conclusion: at the committed level, PTR is a strict superset of XPTR.

## PTR vs XPTR — working-tree (uncommitted) content

Files modified in XPTR's working tree, compared by final content to PTR:

| File | Result | Decision |
|---|---|---|
| `Core/UI.lua` | identical | either (kept PTR) |
| `Modules/Infrastructure/ErrorLog.lua` | identical | either (kept PTR) |
| `Bindings.xml` | identical | either (kept PTR) |
| `Modules/Gear/Gear.lua` | differs | **PTR** — routes scoring through `TA.StatEngine` (DR-aware); XPTR still calls old `SW:ScoreItem`. StatEngine exists only on PTR. |
| `ToonAge.toc` | differs | **PTR** — lists `Core\StatEngine.lua`; XPTR does not. |
| `Modules/Progression/Delves.lua` | differs | **PTR** — has corrected Midnight Season 2 tier table (266→305, loot caps at T8). XPTR still carries the old PTR stub table (iLvlMin 0/170/220). |

Conclusion: **PTR wins every differing file.** XPTR has no unique final content
that needs salvaging. No XPTR-only work was dropped.

## Carried into ToonAgeOne trunk

- Full addon payload from PTR: `Core/`, `Data/`, `Libs/`, `Modules/`,
  `Bindings.xml`, `ToonAge.toc` — 122 Lua files (verified equal count).
- Dev support kept: `Tools/`, `Docs/`, `.github/`, `.rules.md`, `README.md`,
  `LICENSE.md`, `.gitignore`, `CLAUDE.md`.

## Intentionally dropped (not carried)

- `.git/` — old history; ToonAgeOne gets a fresh git history.
- `.claude/`, `.cursor/`, `.kiro/`, `semantic-review/` — per-machine AI tooling,
  not part of the shipped addon and excluded from packaged releases anyway.

## Source-copy safety

No source-copy folder (PTR/XPTR/Beta/Retail/Classic/Anniversary) was modified or
deleted. All construction happened inside `ToonAgeOne/`. Old copies are archived
(labeled), never deleted, and only after Task 11 verification passes.
