# Stage 0 — Legacy Post-Mortem

**Date:** 2026-07-31
**Baseline commit:** `4d95743` on branch `chore/pre-refactor-snapshot`
**Method:** static inventory of the git-tracked source tree at
`_ptr_/Interface/AddOns/ToonAge/`. Everything below is measured, not estimated.

---

## 1. The Rewrite Surface

The headline "2.4 MB addon" is misleading as a workload figure. Separating logic
from static data converts a 90-module rewrite into a tractable ledger:

| Class | Files (`.lua`) | Lines | Bytes | Disposition |
|---|---|---|---|---|
| `Data/` (13 root + 6 `Guides/`) | 19 | 8,030 | 427 KB | **Ports forward verbatim.** Static tables. No logic debt. |
| `Core/` | 7 | 3,814 | 162 KB | **Rewrite.** The framework itself. |
| `Modules/` | 54 | 26,590 | 1,144 KB | **Rewrite / triage.** 55 registered modules. |
| **Logic total** | **61** | **30,404** | **1.31 MB** | The actual 2.0 surface. |

<small>File counts measured via `find`; `Modules/` additionally contains one
non-Lua file, `MapPins.xml`.</small>

**Consequence for scope control:** ~25% of the byte weight is inert data that
needs migration *validation* but not migration *work*. Stage planning should
never spend a phase on `Data/`.

### Heaviest logic units (rewrite risk concentrates here)

| Lines | File |
|---|---|
| 3,699 | `Modules/QuestTracker.lua` |
| 1,369 | `Modules/Gear.lua` |
| 1,177 | `Modules/Talents.lua` |
| 1,131 | `Modules/DevHelpers.lua` |
| 979 | `Core/Init.lua` |
| 915 | `Core/UI.lua` |

`QuestTracker.lua` alone is 12% of all logic lines and is the single largest
technical-debt concentration in the codebase.

---

## 2. Code Smell Baseline (measured, pre-rewrite)

These are the numbers 2.0 will be measured against. Recorded now so improvement
is provable rather than asserted.

| Metric | Count | Read |
|---|---|---|
| `OnUpdate` handlers | 17 | **Primary GC/CPU risk.** Each needs a throttle audit in Stage 2. |
| `InCombatLockdown()` guards | 12 | Thin relative to 56 modules. Taint-surface audit required. |
| `pcall` sites | 154 | Healthy density — the `.rules.md` convention is being followed. |
| Raw `print()` sites | 2 | Log funnel is nearly complete; 2 stragglers to route through `db.logLevel`. |
| `RegisterModule` registrations | 55 | Module contract is real and consistently applied. (56 grep hits minus the definition at `Core/Init.lua:257`.) |

### Namespace hygiene — a directive premise that did not survive contact

The directive lists "global namespace leaks" as a target smell. **At file scope,
none exist.** Every file-scope global assignment is a WoW-mandated global:

- `ToonAge = ToonAge or {}` — the addon namespace (required)
- `BINDING_HEADER_TOONAGE`, `BINDING_NAME_*` (5) — keybinding registration (required)
- `SLASH_*` (many, in `DevHelpers.lua` / `FarmOptimizer.lua`) — slash command registration (required)

**Finding:** the existing module pattern (`local TA = ToonAge; local M = {}`) is
sound and should be *carried into* 2.0, not replaced.

**Scope limit on this finding.** It rests on a column-0-anchored scan, which
detects only *file-scope* assignments. It cannot see the more common defect —
`foo = 5` written inside a function body where `local foo = 5` was meant, which is
indented and therefore invisible to that pattern. Absence of those is **not**
claimed. Proving it requires a real Lua linter (`luacheck` or equivalent) and is
recorded as deferred work, alongside the `OnUpdate` and taint audits. Until that
runs, this finding justifies *not prioritizing* file-scope leaks; it does not
justify closing the namespace question.

---

## 3. The 12.0 Secret-Value Problem — the real API constraint

The directive's "12.0+ payload changes" has a concrete, documented instance in
this repository. This is the canonical case study for the 2.0 API-guard design.

**TOC target:** `## Interface: 120007, 120100` — the addon already targets 12.0.x.

**The failure, from live `SavedVariables` (`ToonAgeDB.errorLog`):**

```
Core/Utils.lua:50: attempt to index local 's'
(a secret string value, while execution tainted by 'ToonAge')
```

**Status: RESOLVED — verified, not assumed.**
The error logged at epoch `1785503614` = **2026-07-31 06:13:34**. The fix
`4d95743 "fix: StripMarkup died on the exact values it was added to capture"`
committed at **06:25:41** — 12 minutes *after* the error. The log entry is a
historical artifact of the bug it describes, not an open defect.

**The transferable lesson**, per the in-code comment now at `Core/Utils.lua:44-53`:

> Secrecy is **contagious through `string.format`**. A line built as
> `("%s"):format(tostring(aura.spellId))` is *itself* a secret string, and every
> string method on it — `gsub`, `len`, `sub`, `match` — raises "attempt to index a
> secret string value."

**2.0 architectural requirement derived from this:** any formatting or
presentation helper must be *non-throwing by contract*. A secret input yields a
marker value and the caller keeps running. A cosmetic function must never be the
reason a caller dies. This generalizes beyond `StripMarkup` and belongs in the
Core contract, not in individual call sites.

---

## 4. Database Reality (supersedes the directive's AceDB premise)

There is **no AceDB in this addon.** `Libs/` contains exactly one file:
`LibStub.lua` (1,376 bytes).

Actual persistence model, per `.rules.md` and `Core/Init.lua`:

- **Global:** `ToonAgeDB` (account-wide), declared `## SavedVariables: ToonAgeDB`
- **Per-character:** `ToonAgeDB.char["Name-Server"]`, accessed via `TA.charDB`
- **Defaults:** hand-rolled `DB_DEFAULTS` deep-merge in `Core/Init.lua`
- **Upgrade rule (existing, and correct):** never wipe user data on version
  upgrade — backfill missing keys only

Observed live root keys: `errorLog`, `logLevel`, `xpHistory`, `minimap`, `safeMode`.
Live file sizes: retail 9,973 bytes; PTR 8,832 bytes. Small today — but `xpHistory`
and `errorLog` are both unbounded-growth shapes and are the scalability targets.

**Migration path is therefore hand-rolled `ToonAgeDB` → 2.0**, not AceDB → AceDB.
Whether 2.0 should *adopt* AceDB-3.0 at all is an open decision for the user.

---

## 5. DevOps Gap (directive §3.5 currently unmet)

| Requirement | Status |
|---|---|
| GitHub Actions release pipeline | **Absent.** No `.github/workflows/` in the tree. |
| BigWigs Packager config | **Absent.** No `.pkgmeta`. |
| CurseForge metadata (`X-Curse-Project-ID`) | **Absent from `ToonAge.toc`.** |
| Wago metadata (`X-Wago-ID`) | **Absent from `ToonAge.toc`.** |
| Local deploy | Present — `Tools/deploy.ps1`, a `robocopy /MIR` copy to `_retail_`. Not a release pipeline. |

`ToonAge.toc` today carries: `Interface`, `Title`, `Notes`, `Author`, `Version`,
`DefaultState`, `SavedVariables`, and three `AddonCompartmentFunc*` hooks. It is
functional for local play and **not** publishable through an automated pipeline.

Recorded as a Stage 4 deliverable. Not fixed in Stage 0 — fixing it now would be
scope creep against directive §3.1.

---

## 6. Assets Worth Preserving

Rebuilding "to the studs" should not discard what already works. Carry forward:

- **The module contract** — `TA:RegisterModule("Name", M)` with `Init()` /
  `OnEvent()` / `Render()`, applied consistently across 56 modules.
- **Centralized error capture** — `TA.ErrorLog:Log(source, msg, stack)`, with
  Init.lua already `pcall`-wrapping every module `Init` and `OnEvent`. This is
  the fault-tolerance spine directive §3.2 asks for; it exists.
- **`Core/ApiGuard.lua` + `Data/ApiManifest.lua`** — an existing API-surface
  guard. Directly relevant to the 12.0 secret-value work.
- **The Python test harness** — `Tools/check_lua.py` (syntax-parses the whole TOC)
  and `Tools/test_onboarding.py` (executes Core in embedded Lua 5.1). Directive
  §3.4's "test Core without loading child components" is **already achievable**.
- **The `Data/` tree** — 8,030 lines of curated static data. Irreplaceable and
  debt-free.
