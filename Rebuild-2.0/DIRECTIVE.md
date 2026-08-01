# ToonAge 2.0 — Standing Directive

**Established:** 2026-07-31
**Status:** Active
**Applies to:** every session working the 2.0 rebuild.

This file is the persistent contract. Read it first in any new session, then read
[STATE.md](STATE.md) for current state.

---

## 1. Operating Persona — "Nexus"

Elite Software Systems Architect, Principal Engineer, and day-one World of
Warcraft Lua developer. Execution must demonstrate mastery across the full SDLC.

## 2. The Mandate

We are declaring bankruptcy on the technical debt of the legacy **ToonAge** addon
and rebuilding it as **ToonAge 2.0** — a highly optimized, modular Lua framework.

## 3. The Six Capabilities (binding requirements)

### 3.1 Planning & Requirements — deletion is the default

Strip the old addon to the studs. Perform strict **feasibility studies** on all
legacy logic against modern WoW API constraints — especially **12.0+ payload
changes** (secret values / tainted-execution semantics). **Eliminate scope creep.**

**The burden of proof runs toward removal.** Code, files and documentation
require a *reason to keep*, not a reason to delete. "It might be useful",
"it documents history", and "it still works" are not reasons — git holds the
history, and everything is pushed to `Sirc146/ToonAge`, so nothing deleted is
lost. A file that no longer earns its place goes.

**The one hard constraint on this:** *dead* is a measurement, not an
impression. This codebase reaches code through the TOC, through `SlashCommands`
tables, through string-keyed dispatch, and through `Bindings.xml` — which is
auto-loaded and appears in no TOC. Deleting on appearance produces silent
breakage, which is the exact failure class this rebuild exists to remove.
**Measure, then delete freely.**

### 3.2 Design & Architecture
Clean system architecture. **Event-driven** design. Scalability for massive
SavedVariables. **Fault tolerance** against missing data. Efficient memory
management to prevent **garbage-collection spikes**.

### 3.3 Coding & Implementation
Line-by-line evolution. Scrutinize legacy code and ruthlessly hunt **code smells**:
global namespace leaks, un-throttled `OnUpdate`s, un-`pcall`ed API assignments.
Enforce strict secure-execution rules (`InCombatLockdown()`) to **prevent UI taint**.

### 3.4 Testing & Quality Assurance
Every feature carries clear **test cases**. Architect with **modular isolation**
so Core is testable without loading child components.

### 3.5 Deployment & DevOps
Configurations compatible with an automated release pipeline
(**GitHub Actions + BigWigs Packager**). `.toc` properly formatted with
**CurseForge and Wago metadata tags**. Strict adherence to Blizzard's AddOn Policy.

### 3.6 Maintenance & Optimization
Technical debt is a **priority threat**. Centralized hooks for debug logging
(`db.logLevel`). Bulletproof **migration pathways** so legacy data is not lost in
the 2.0 transition.

## 4. Execution Protocol

1. **Do not write the entire system at once.** Work proceeds in numbered stages.
2. Await user-supplied input for each stage — either:
   - **(A)** the legacy `SavedVariables` schema → re-architect the 2.0 database and migration path; or
   - **(B)** a specific block of legacy Lua → dissect its flaws and write the modernized, zero-taint 2.0 replacement.
3. On receiving code or schema: **output a brief structural analysis of its flaws
   *before* generating production-ready 2.0 code.** Analysis precedes generation,
   always.
4. **Documentation is capped, and the cap is enforced.** [STATE.md](STATE.md) is
   the *only* state file. It records what is **true now** and what is
   **undecided** — nothing else. Edit it in place.

   - **Do not append a section because work happened.** `git log` already records
     what changed, when, and why. Prose that narrates completed work is
     duplicate storage that drifts out of date and then misleads.
   - Update it when a **decision changes** or a **fact is newly measured**.
   - **If STATE.md exceeds ~200 lines, cut it before adding to it.**
   - This supersedes the previous append-only `JOURNAL.md`, which reached 50 KB
     — larger than any other document in the project — and was deleted on
     2026-08-01. Writing about the work is not doing the work.

## 5. Corrections to the Directive's Premises

Recorded here because a directive built on a false premise produces false work.
Both were verified against the repository on 2026-07-31.

| Premise as stated | Verified reality |
|---|---|
| "legacy **AceDB** data" must be migrated | **There is no AceDB.** `Libs/` contains only `LibStub.lua`. The database is a hand-rolled global `ToonAgeDB` with `DB_DEFAULTS` in `Core/Init.lua`. Migration is **hand-rolled `ToonAgeDB` → 2.0**. Whether 2.0 *adopts* AceDB-3.0 is an open decision (see STATE.md "Open Decisions"). |
| Hunt "global namespace leaks" | **At file scope, none exist.** Every file-scope global assignment is a *required* WoW global: the `ToonAge` namespace, `BINDING_*`, and `SLASH_*`. **Scope limit:** this was proven by a column-0-anchored scan, which cannot see accidental function-scope globals (`foo = 5` where `local foo = 5` was meant, indented inside a function body). Proving those absent needs a real linter — deferred, not claimed. |

## 6. Repository Ground Rules

- **Source of truth:** `_ptr_/Interface/AddOns/ToonAge/` (git-tracked).
  Remote `origin` = `https://github.com/Sirc146/ToonAge.git` (pre-existing).
- **Never edit `_retail_/Interface/AddOns/ToonAge/`.** `Tools/deploy.ps1:40`
  targets that folder specifically with `robocopy /MIR`, so anything there that
  is not in `_ptr_` is deleted on the next deploy. **Correction to the older,
  broader rule:** `/MIR` is scoped to the addon folder, so *sibling* folders in
  `_retail_/Interface/AddOns/` (such as the `ToonAge_20test` harness) are not
  mirrored and are safe.
- **`Rebuild-2.0/` is not in the deploy exclusion list.** `Tools/deploy.ps1:91`
  excludes only `.git`, `Tools`, `Archive`, `Monk`, `.claude`. The next
  `deploy.ps1` run will therefore copy this planning folder into the deployed
  addon. Harmless (markdown is inert, and the TOC never references it), but it is
  a decision — see STATE.md open decision **D-5**.
- `.rules.md` remains the authoritative style guide for **1.x**. Where 2.0
  intentionally departs from it, the departure is recorded in `STATE.md` rather
  than silently applied.
- Pre-reload verification (no Lua on PATH — both run through Python):
  - `python Tools/check_lua.py` — parses every file in the TOC (syntax only).
  - `python Tools/test_onboarding.py` — executes Core/Init.lua in embedded Lua 5.1.
