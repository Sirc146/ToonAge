# ToonAge 2.0 — Phase Journal

**Append-only.** Newest entry at the bottom. Never rewrite history; correct a
prior entry by adding a new one that supersedes it.

Every entry uses absolute dates. Every entry separates **verified** from
**assumed**. Every entry ends with what the next session should do first.

---

## Entry 001 — Stage 0: Post-Mortem & Architecture Scaffolding

**Date:** 2026-07-31
**Phase:** Stage 0
**Status:** ✅ Complete
**Baseline:** commit `4d95743`, branch `chore/pre-refactor-snapshot`

### Completed

**Workspace established** at `_ptr_/Interface/AddOns/ToonAge/Rebuild-2.0/`:

| File | Contents |
|---|---|
| `README.md` | Index + pointers to pre-existing root docs |
| `DIRECTIVE.md` | Standing contract: persona, six SDLC capabilities, execution protocol, premise corrections |
| `STAGE0_POSTMORTEM.md` | Measured legacy inventory and structural findings |
| `JOURNAL.md` | This file |

Markdown-only and unreferenced by `ToonAge.toc`, so it is inert to the game
client and to `check_lua.py`.

**Legacy inventory (measured):**
- Rewrite surface: **30,404 lines / 1.31 MB** of logic across **61** files (`Core/` 7 files / 3,814 lines + `Modules/` 54 files / 26,590 lines).
- Carry-forward: **8,030 lines / 427 KB** of static `Data/` across 19 files — migration *validation* only, no rewrite work.
- **55** registered modules; heaviest is `QuestTracker.lua` at 3,699 lines (12% of all logic).

**Code-smell baseline recorded** (the numbers 2.0 will be measured against):
17 `OnUpdate` handlers · 12 `InCombatLockdown` guards · 154 `pcall` sites ·
2 raw `print()` sites.

### Verified (evidence in hand, not inferred)

1. **The 12.0 secret-value crash is RESOLVED, not open.** Error logged
   06:13:34; fix `4d95743` committed 06:25:41 — 12 minutes later. The
   `ToonAgeDB.errorLog` entry is a historical artifact. Confirmed by comparing
   epoch `1785503614` against the commit timestamp, and by reading the fix at
   `Core/Utils.lua:44-53`.
2. **`_retail_/` is a clobber-zone.** `Tools/deploy.ps1:93` runs
   `robocopy /MIR`. Anything written there that isn't in `_ptr_` gets deleted.
   All work goes in `_ptr_`.
3. **No AceDB exists.** `Libs/` contains only `LibStub.lua`. Persistence is a
   hand-rolled `ToonAgeDB` global with `DB_DEFAULTS` in `Core/Init.lua`.
4. **No *file-scope* global namespace leaks exist.** Every file-scope global is a
   required WoW global (`ToonAge`, `BINDING_*`, `SLASH_*`). **This does not cover
   function-scope leaks** — see *Assumed* item 5.
5. **DevOps gap is real.** No `.github/workflows/`, no `.pkgmeta`, no
   `X-Curse-Project-ID`, no `X-Wago-ID` in `ToonAge.toc`.
6. **Git remote pre-exists:** `origin` = `https://github.com/Sirc146/ToonAge.git`.
   No repository was created and nothing was pushed during Stage 0.
7. **`Rebuild-2.0/` will be deployed to `_retail_`.** `Tools/deploy.ps1:91`
   excludes only `.git`, `Tools`, `Archive`, `Monk`, `.claude`. Inert (markdown,
   not TOC-referenced) but see **D-5**.

### Assumed (NOT verified — do not build on these without checking)

- **The full `DB_DEFAULTS` shape has not been read.** Only the ~25 head lines of
  live `SavedVariables` were inspected (root keys: `errorLog`, `logLevel`,
  `xpHistory`, `minimap`, `safeMode`). The authoritative schema is in
  `Core/Init.lua` and is unread.
- **The 17 `OnUpdate` handlers have not been individually audited.** The count is
  real; whether each is throttled is unknown.
- **The 12 `InCombatLockdown` guards have not been checked for correct placement.**
  12 guards across 56 modules is thin, but thin ≠ wrong until each protected-frame
  path is traced.
- **Function-scope global leaks are UNKNOWN.** The namespace scan was
  column-0-anchored and can only see file-scope assignments. An indented
  `foo = 5` (missing `local`) inside any function body would not appear. Needs a
  real linter (`luacheck`); recorded as deferred work below. Correcting an
  earlier over-broad claim made in this same entry.
- Module count `55` is `grep`-derived (56 `RegisterModule` hits minus the
  definition at `Core/Init.lua:257`). Cross-checked against 54 `.lua` files in
  `Modules/` — the surplus registration is expected, since `Core/` files also
  register. Not individually enumerated.

### Two directive premises corrected

Recorded in `DIRECTIVE.md §5`. The AceDB migration premise and the
global-namespace-leak premise are both false for this codebase. Neither blocks
Stage 0; both would have produced wasted work if left standing.

### Open Decisions — awaiting user

| # | Decision | Why it matters |
|---|---|---|
| D-1 | **Adopt AceDB-3.0 in 2.0, or keep hand-rolled `ToonAgeDB`?** | Determines the entire migration design. Ace brings profiles/namespaces but adds a library dependency to an addon that currently ships one 1.4 KB lib. |
| D-2 | **Is `QuestTracker.lua` (3,699 lines) in scope for 2.0, or frozen as-is?** | It is 12% of all logic. Including it roughly doubles the rewrite budget. |
| D-3 | **New repo, or a `2.0` branch in the existing `Sirc146/ToonAge`?** | **Recommendation: branch in the existing repo, do not create a new one.** Four reasons: (1) `git diff main..2.0` is the highest-value review tool in a line-by-line rewrite — a separate repo destroys it permanently; (2) this journal and the post-mortem cite commits (`4d95743`) that a new repo would orphan; (3) `main` keeps shipping 1.x while 2.0 is unstable; (4) CurseForge/Wago project IDs bind to one repo — re-registering is avoidable churn. A rewrite is a branch event, not a repository event. |
| D-6 | **Daily push cadence, gated on a green check?** | **Recommendation: yes.** See "Proposed daily close ritual" below. |
| D-7 | **Per-flavor locations for retail / PTR / classic?** | **Recommendation: one repo, one branch, multiple TOC files — and Classic stays out of scope.** See "Flavor architecture" below. |
| D-4 | **Publish targets — CurseForge, Wago, or both?** | Determines which metadata tags and packager config Stage 4 produces. |
| D-5 | **Should `Rebuild-2.0/` ship to `_retail_`?** | It is not in `deploy.ps1`'s exclusion list, so the next deploy copies planning docs into the playable addon. Harmless but untidy. One-line fix: add `'Rebuild-2.0'` to `$exclude` at `Tools/deploy.ps1:91`. Not done — modifying a legacy tool is outside Stage 0's read-only remit. |

### Next Session — start here

**Blocking:** Stage 1 cannot begin until the user supplies **(A)** or **(B)** per
`DIRECTIVE.md §4.2`. This is by design, not a stall.

- **If (A) — the SavedVariables schema:** re-architect the 2.0 database and
  migration path. Before designing, read the full `DB_DEFAULTS` block in
  `Core/Init.lua` (the schema gap flagged under *Assumed* above). Priority
  scalability targets are `xpHistory` and `errorLog` — both unbounded-growth
  shapes. Answer **D-1** first; it gates the design.
- **If (B) — a legacy Lua block:** output the structural flaw analysis *before*
  any 2.0 code, per `DIRECTIVE.md §4.3`. If the user has no preference on which
  block, recommend `Core/Init.lua` (979 lines) — it owns module registration,
  `DB_DEFAULTS`, and the `pcall` wrapping, so it gates everything downstream.

**Not started, deliberately deferred (avoid scope creep):**
- Stage 4 DevOps: `.pkgmeta`, GitHub Actions workflow, TOC metadata tags.
- `OnUpdate` throttle audit (17 sites).
- Taint-surface audit (12 `InCombatLockdown` guards).
- **Function-scope global leak audit** — needs `luacheck` or equivalent; the
  Stage 0 scan could not see indented missing-`local` assignments.
- `Tools/deploy.ps1` exclusion for `Rebuild-2.0/` (see D-5).

**Nothing in the legacy codebase was modified during Stage 0.** The teardown was
read-only; the only writes were the four new files in `Rebuild-2.0/`.

---

## Flavor Architecture — retail / PTR / classic (D-7)

### Retail and PTR are the same flavor. They need no separation.

Both are **Mainline**. A single TOC serves both via a multi-version `Interface`
line, which `ToonAge.toc` **already does today**:

```
## Interface: 120007, 120100
```

That is the mechanism working as designed. Splitting retail from PTR would create
two artifacts that must be kept in lockstep, to solve a problem the `Interface`
line already solves. **Recommendation: change nothing here.**

The *local folder* separation the user observed (`_retail_` vs `_ptr_`) is a
**deployment** concern, and `Tools/deploy.ps1` already handles it — it takes
`-Client _retail_ | _classic_era_ | _anniversary_` and treats `_ptr_` as the
repository. That design is sound and carries into 2.0 unchanged.

### Classic is a real flavor — but it is a TOC file, not a repo or a branch

Blizzard's client auto-selects `AddonName_<Flavor>.toc` when present, falling back
to `AddonName.toc`. The standard multi-flavor layout is **one repo, one branch,
several TOCs**:

| File | Client |
|---|---|
| `ToonAge.toc` or `ToonAge_Mainline.toc` | Retail + PTR |
| `ToonAge_Vanilla.toc` | Classic Era |
| `ToonAge_Mists.toc` | Classic progression |

BigWigs Packager is **built for exactly this** — it reads every flavor TOC from a
single branch and uploads each with the correct CurseForge/Wago game-version tag.
Per-flavor branches or repos actively fight the tooling that directive §3.5
requires, and force every shared fix to be applied N times.

### But Classic support is severe scope creep — recommend NOT doing it

Measured retail-only API dependency across the current logic layer:

| API | Files depending on it | Exists in Classic? |
|---|---|---|
| `GetSpecialization` | 21 | ❌ No spec system |
| `C_Map.GetBestMapForUnit` | 18 | ⚠️ Partial |
| `C_QuestLog` | 14 | ⚠️ Different shape |
| `C_Traits` | 10 | ❌ No talent trees |
| `C_ClassTalents` | 9 | ❌ |

ToonAge's spine — specs, talent trees, rotations, delves, modern professions —
**does not exist in Classic**. This is not a port with compatibility shims; it is
a second addon sharing a name. Adding it to the 2.0 rebuild would multiply a
30,404-line rewrite by an unbounded factor.

**Recommendation:** ship 2.0 as Mainline-only (retail + PTR, one TOC, as today).
Structure the 2.0 Core so a flavor TOC *could* be added later — keep API access
behind `Core/ApiGuard.lua` rather than calling Blizzard APIs directly from
modules — but **do not build Classic support in the 2.0 scope**. This is directive
§3.1 ("eliminate scope creep") applied to the largest available temptation.

---

## Proposed Daily Close Ritual (pending user approval — D-3, D-6)

Branch model: work on `2.0` in the **existing** `Sirc146/ToonAge` repo. `main`
stays 1.x and shippable. No new repository.

**The gate has three tiers, and only the third one actually proves anything:**

| Tier | Command | What it proves | What it does *not* prove |
|---|---|---|---|
| 1. Syntax | `python Tools/check_lua.py` | Every TOC file parses. Catches unbalanced `end`, missing `then`. | Nothing about correctness — the tool says so itself. |
| 2. Execution | `python Tools/test_onboarding.py` | Core/Init.lua actually *runs* in embedded Lua 5.1. | Nothing about live API behavior or taint. |
| 3. In-game | `/reload`, then `/ta errors` | The real gate. Empty error log after exercising touched modules. | Only what you exercised. |

**Do not treat tier 1 as "verified no errors."** A green `check_lua.py` on
tainted or secret-value-handling code is meaningless — the 12.0 crash documented
in the post-mortem passed syntax checking cleanly. Tier 3 is the gate that has
authority; tiers 1–2 just fail fast and cheaply before you reload.

**Sequence, once all three are green:**

```
git checkout 2.0
git add -A
git commit           # message states what was verified, not just what changed
git push origin 2.0
```

**Rules for this ritual (applies once D-3/D-6 are approved):**
- **Never push red.** A broken `2.0` tip destroys the branch's value as a known-good
  restore point.
- If the day ends dirty, commit to a scratch branch (`wip/<date>`) instead of
  pushing `2.0`. Unpushed work is a bigger risk than an untidy branch.
- Every push day gets a journal entry here. The commit log records *what changed*;
  this journal records *what was decided and what remains unknown* — git cannot
  reconstruct that.
- `git pull` before starting, in case work happened on another machine.

---

## Entry 002 — Stage 1 (Option B): `Core/Init.lua` Flaw Analysis

**Date:** 2026-07-31
**Phase:** Stage 1 — analysis complete, 2.0 code NOT yet written
**Status:** ⏸ Paused at session end. Analysis is durable; resume at "Next Session" below.
**Subject:** `Core/Init.lua`, 979 lines, read in full.

### Headline finding — the bankruptcy premise does not hold for this file

`Core/Init.lua` is **well-engineered code**, not a debt pile. Before listing
defects, the record must state this, because it changes the rebuild strategy:

- Comments document *why*, including **reverted** attempts and their reasons
  (the per-character defaults note at lines 193–209 explains what was tried, why
  it failed, and names the test that would catch a regression).
- `CopyDefault` / `ApplyDefaults` (lines 157–191) correctly solve the
  defaults-reference-sharing bug that most addons ship with forever.
- The Safe Mode design (two independent mechanisms — per-session auto-disable,
  persisted manual boot) is genuinely thoughtful, including *not* persisting
  transient failures.
- The log funnel (`TA.LOG` / `Print` / `Raw` / `Printf`) is complete and
  correctly places `OUTPUT` outside the severity scale.

**Strategic consequence:** "strip to the studs" is the wrong instruction for this
file. **Recommendation: 2.0 keeps Init.lua's structure and semantics, and
replaces exactly one subsystem — the event dispatcher.** A rewrite would be net
value-destroying here. This is directive §3.1 (eliminate scope creep) applied to
the rebuild's own premise.

### The one architectural defect that justifies Stage 1 — broadcast dispatch

**`TA:UpdateModules` (lines 356–387) is a broadcast bus, not event-driven
architecture.**

Every persistent event iterates **all 55 registered modules** via `pairs()` and
`pcall`s `OnEvent` on each of the **35** that define one — regardless of whether
that module cares about the event.

Measured cost: `BAG_UPDATE` fires roughly 5× per loot (once per bag).
**5 × 35 = ~175 `pcall` invocations per single loot action**, each allocating,
to service the handful of modules that actually want `BAG_UPDATE`. This is the
GC-spike source directive §3.2 names, and it is the strongest argument in the
whole codebase for a 2.0 Core.

**Compounding: `pairs()` order is nondeterministic.** It governs both
`InitModules` (line 328) and `UpdateModules` (line 357). Module *initialisation
order* therefore varies between logins. Any implicit inter-module dependency
works intermittently — the worst class of bug to diagnose in the field.

**2.0 design (recommended):** modules declare their events at registration;
Core builds `event → subscriber[]` lists; dispatch touches only subscribers, in
a **deterministic registration order**. This is a Core-local change — the 35
`OnEvent` handlers keep their existing signature, so it does not cascade.

### Confirmed defects (smaller, all real)

| # | Location | Defect | Fix |
|---|---|---|---|
| F-1 | L427–432 | **`ADDON_LOADED` does nothing but unregister.** The comment "SavedVariables not available yet" is **factually wrong** — SavedVariables *are* guaranteed loaded when `ADDON_LOADED` fires for your own addon. Init is needlessly deferred to `PLAYER_ENTERING_WORLD`. | Move `InitDB` to `ADDON_LOADED`; keep UI init on `PLAYER_ENTERING_WORLD`. |
| F-2 | L846–848 vs L654 | **Duplicate command registry has already drifted.** `verbose` is handled at L654 but is missing from the hardcoded `builtins` list, so `/ta verb` never prefix-matches. | Single source of truth; derive the name list from the table. |
| F-3 | L555–642 | **`BUILTIN` table + ~16 closures are re-allocated on every `/ta` invocation.** It is a file-scope constant declared function-local. | Hoist to file scope, build once. |
| F-4 | whole file | **Zero `InCombatLockdown()` guards** (verified: count is 0). `/ta layout` → `ApplyLayout()` moves frames, and is reachable from a `SetItemRef` hyperlink click — a tainted execution path. Directive §3.3 violation. | Guard frame-affecting commands; defer to `PLAYER_REGEN_ENABLED`. |
| F-5 | L246, L667–668 | `TA.logLevel` and `db.logLevel` are two sources of truth kept in sync by hand. | Single accessor. |
| F-6 | L808–827 | `FuzzyScore` is O(n·m) and allocates a `used` table per candidate, called in a loop over all commands. | Cheap, but bound it. |
| F-7 | L568–581 | `/ta reset` orphans module-cached DB subtables — **acknowledged honestly in-code**, still requires a reload. | 2.0: access DB via accessor, never cache subtables. |

### Verified this session

- 35 modules define an `OnEvent` handler (they use local aliases, e.g.
  `function AutoMount:OnEvent`, not `function M:OnEvent` — an earlier grep for
  the `M:` form returned 0 and was wrong; corrected here).
- 18 modules *also* self-register events via their own frames, so the broadcast
  bus is not even the only dispatch path in play.
- `InCombatLockdown` appears **0** times in `Core/Init.lua`.
- `verbose` is absent from the `builtins` array at L846–848 (F-2 confirmed).

### NOT done — deliberately

**No 2.0 code was written.** Directive §4.3 requires analysis before generation;
analysis is complete, generation is the next unit of work. Nothing in the legacy
codebase was modified this session — `Rebuild-2.0/` remains the only write target.

### Next Session — start here

1. **Write `Core/Init.lua` 2.0** — scope is the **event dispatcher only**
   (subscriber lists + deterministic ordering), plus F-1 through F-7. Preserve
   `CopyDefault`/`ApplyDefaults`, the Safe Mode design, and the log funnel
   verbatim — they are assets, not debt.
2. **Test cases to write alongside** (directive §3.4): dispatch reaches only
   subscribers; registration order is stable across runs; a throwing subscriber
   does not block its siblings; auto-disable still trips at 10 errors.
3. **Still blocking:** **D-1** (adopt AceDB-3.0 or keep hand-rolled?) gates the
   database half of 2.0. The dispatcher work does **not** depend on it and can
   proceed first — recommended.
4. Open decisions **D-1 … D-7** remain unanswered. **D-3** (branch, don't create a
   new repo) and **D-7** (Mainline-only, no Classic) carry standing
   recommendations and just need a yes/no.

---

## Entry 003 — Stage 1 (Option B): `Core/Init.lua` 2.0 written

**Date:** 2026-07-31
**Phase:** Stage 1 — generation complete for the dispatcher scope
**Status:** ✅ Code written and tested offline. ⚠️ Never run in the game.
**Artifacts:** `Rebuild-2.0/Core/Init.lua` (draft), `Tools/test_dispatch.py` (84 checks)

### Completed

Entry 002's analysis is now implemented. Scope held exactly to what that entry
declared: the event dispatcher, plus F-1…F-7. Everything Entry 002 judged an
asset was carried forward with its comments intact — `CopyDefault` /
`ApplyDefaults`, the Safe Mode two-mechanism design, the log funnel, the
coalesced UI refresh, and the slash-link hook.

**The dispatcher.** Modules may now declare their events at registration;
Core builds `event → subscriber[]` lists and dispatches only to subscribers, in
deterministic registration order (`TA.moduleOrder`, an array shadowing the
existing keyed map). `InitModules` walks the same array, so **module init order
is now fixed at TOC load order instead of varying per login** — the second half
of the Entry 002 defect.

**Measured, not asserted** (`test_dispatch_volume_against_legacy`, which runs
the same workload against both the 1.x and 2.0 files): 55 modules registered,
35 with an `OnEvent` handler, `BAG_UPDATE` fired 5× (roughly one loot).

| | Handler invocations per simulated loot |
|---|---|
| 1.x broadcast | **175** |
| 2.0, three modules migrated | **15** |
| 2.0, nothing migrated yet | **175** — identical to 1.x, by design |

### The design decision that matters most — dispatch is fail-OPEN

`RegisterModule(name, module, events)`:

| `events` | Meaning |
|---|---|
| `nil` (2-arg call) | **Legacy broadcast.** Receives every non-core event, exactly as 1.x. |
| `{}` | Declared; subscribes to nothing. |
| `{...}` | Declared; receives only those. |

All 55 existing registrations are 2-arg and therefore keep working untouched.
This is not politeness — **a module that stops receiving events raises nothing
and prints nothing.** It is the same silent-failure shape as the 12.1.0
`C_Navigation.GetDestination` removal recorded in `.rules.md`: guarded call, no
error, always nil. A fail-closed default would have silently killed 35 handlers.

Migration is therefore per-module and opt-in, and `/ta dispatch` (new) reports
who is still on the legacy path — otherwise "is module X migrated?" is
unanswerable in-game, and an explicit empty declaration is indistinguishable
from no declaration.

### F-1 was a trap, and the fix is not what Entry 002 proposed

Entry 002 said: *"Move `InitDB` to `ADDON_LOADED`."* Its premise is correct —
SavedVariables **are** available at `ADDON_LOADED` for your own addon, and 1.x's
comment to the contrary was wrong. **But moving `InitDB` wholesale would have
introduced a worse bug than the one it fixed.**

`InitDB` also built `charKey` from `UnitName("player")` / `GetRealmName()`, and
player unit data is not reliably populated that early on a cold login. With
1.x's `or "Unknown"` fallbacks this would not have errored — it would have
written a `char["Unknown-Unknown"]` bucket, losing the character's settings
with no visible symptom. **And it would very likely have looked correct on
`/reload`, which is how it would have been tested.**

The implemented fix is a three-phase split, structured so the exact tick at
which `UnitName` starts answering **does not matter**:

| Phase | Work |
|---|---|
| `ADDON_LOADED` | `InitAccountDB` — `ToonAgeDB`, `ApplyDefaults`, onboarding migration |
| `PLAYER_LOGIN` | `InitCharDB` (charKey), `InitModules`, UI, minimap, layout, slash commands |
| `PLAYER_ENTERING_WORLD` (first only) | `OnFirstWorldEnter` — the profession snapshot |

The profession snapshot is deliberately **last**. `GetProfessions()` returning
empty early would write an empty snapshot over a good one from last session —
silent data loss, no error. A missing character identity is now logged at
**ERROR** rather than silently producing `Unknown-Unknown`.

### F-2 … F-7, all implemented and all mutation-tested

| # | Fix |
|---|---|
| F-2 | `BUILTIN` is the **only** list of built-in command names; `GetAllCommandNames` derives from it. 1.x's second hardcoded array had already drifted — `verbose` was missing, so `/ta verb` never prefix-matched. Commands taking arguments (`toggle`, `verbose`) are ordinary entries, which is what makes one list sufficient. |
| F-3 | `BUILTIN` hoisted to file scope, built once, instead of the table + ~16 closures being reallocated on **every** `/ta` invocation. |
| F-4 | `RunWhenSafe` guards frame-affecting commands. `/ta layout` defers to `PLAYER_REGEN_ENABLED` in combat and **tells the user**, rather than silently dropping or tainting. 1.x had zero `InCombatLockdown` checks in this file. |
| F-5 | One verbosity source. `TA.logLevel` (the hand-synced mirror) is **gone**; `GetLogLevel`/`SetLogLevel` read and write `db.logLevel`. Verified safe by grep: no module outside `Core/Init.lua` ever read that field. |
| F-6 | `FuzzyScore` short-circuits before allocating when `min/max` length ratio cannot reach the 0.6 threshold, and rejects strings over 32 chars. |
| F-7 | `GetDB()` / `GetCharDB()` accessors, and `/ta reset` rebuilds **both** scopes. The reload requirement is still documented, because modules still cache subtables — the accessors exist so that can eventually be retired. |

### New in 2.0, not in Entry 002's list

- **`CORE_ONLY_EVENTS`.** Core registers `PLAYER_REGEN_ENABLED` for the combat
  queue, and owns the three boot events. Broadcast modules **never** receive
  these, even though the frame is registered for them. Without this rule,
  adding the combat guard would have started delivering `PLAYER_REGEN_ENABLED`
  to all 35 handlers, none of which have ever seen it. A dispatcher change must
  not hand modules new events as a side effect.
- **`SafeRegisterEvent`.** `RegisterEvent` errors outright on an event name the
  client does not know. Now that modules can declare arbitrary events, one
  module naming an event removed in a 12.x patch would otherwise stop the whole
  addon loading. The failure is contained to that module and reported.
- **The 17-entry `PERSISTENT_EVENTS` bottleneck is retired.** A module can
  declare an event that is not in that array and simply receive it.

### Verified (evidence in hand)

1. **Baseline was green before any work started** — `check_lua.py` 81 files,
   `test_onboarding.py` 87 checks. Established first, so "my change broke it"
   and "it was already red" could be told apart.
2. **Entry 002's analysis was re-checked against the file, not trusted.** All
   seven defects confirmed at the cited lines, including `verbose` absent from
   the `builtins` array (L846–848) and `InCombatLockdown` appearing **0** times.
3. **84 behaviour checks pass** — `python Tools/test_dispatch.py`.
4. **All 16 mutations are caught.** Per `.rules.md`, a suite that has never been
   seen to fail is not evidence. Each fix was backed out mechanically and the
   suite confirmed red, then restored.
5. **Two mutations initially SURVIVED, and both were test bugs, not code bugs.**
   Recorded because the failure is instructive:
   - The ordering test read module state back *after* dispatch instead of
     recording delivery order from inside the handlers — so it would have passed
     even if dispatch walked `pairs()`. It asserted the thing it was named
     after without constraining it.
   - Nothing covered duplicate registration at all — a real hazard, since
     `moduleOrder` is an append-only array shadowing a keyed map, so a second
     registration under one name would have dispatched that module twice per
     event forever.
   Both tests were fixed; both mutations are now caught. **This is the entire
   argument for mutation testing**: the suite was 80/80 green while two of its
   claims were hollow.
6. **The legacy suites still pass unchanged** after all work — 81 files, 87
   checks. Nothing in `Core/`, `Modules/` or `Data/` was modified.

### Assumed / NOT verified — do not build on these

- **None of this has run in the game.** Zero reloads. Real frames, real taint,
  real SavedVariables persistence and real `InCombatLockdown` behaviour are all
  untested. Per the Entry 001 three-tier gate, **only tier 3 has authority**,
  and tiers 1–2 are all that has happened.
- **`UnitName("player")` timing at `ADDON_LOADED` was never measured.** The
  three-phase split is designed so the answer does not matter, but the
  underlying fact remains unmeasured and is not claimed either way.
- **`check_lua.py` does not cover `Rebuild-2.0/`** — it parses the TOC file
  list, and nothing here is in the TOC. The draft's syntax coverage comes
  *solely* from `test_dispatch.py` executing it.
- **The 2.0 file is not wired into `ToonAge.toc` and has never been loaded by
  the client.** It is a draft sitting beside the running 1.x file.
- Whether real modules can *usefully* declare narrow event sets is untested —
  Entry 002 noted 18 modules also self-register events on their own frames, so a
  module's declared list is **not** a complete picture of what it handles.

### Open decisions — still awaiting user

`D-1` … `D-7` all remain unanswered. Two are now more pressing than they were:

- **D-3 (branch vs. new repo)** — nothing can be committed until this is
  answered. Work is sitting on `chore/pre-refactor-snapshot`, and
  `Rebuild-2.0/` is still untracked. Standing recommendation: **branch `2.0` in
  the existing repo.**
- **D-5 (`Rebuild-2.0/` shipping to `_retail_`)** — worth slightly more now
  that this folder contains `.lua`. Still inert, because TOC-driven loading is
  the only path into the client, but the one-line `deploy.ps1:91` exclusion is
  now the difference between shipping planning docs and shipping a second,
  unreferenced `Core/Init.lua` into the played addon.

### Next Session — start here

1. **Adopt or discard, and decide where.** The draft is complete for its scope
   but wired to nothing. The cheapest honest next step is a **live smoke test**:
   answer D-3, put this on a `2.0` branch, point the TOC at the 2.0 `Core/Init.lua`
   in a **copy** of the addon folder, `/reload`, and run `/ta health`,
   `/ta dispatch`, `/ta errors`. That is tier 3, the only tier with authority.
2. **Then migrate modules incrementally.** Pick the handful that genuinely want
   `BAG_UPDATE` and give them declarations; watch `/ta dispatch` shrink the
   broadcast list. The perf win accrues per module — there is no big-bang step.
3. **Do not migrate blind.** Check whether a module also self-registers events
   on its own frame (18 do) before assuming its declared list is complete.
4. **D-1 still gates the database half of 2.0** and is untouched by this work.
   `xpHistory` and `errorLog` remain the unbounded-growth scalability targets.

**Legacy codebase modifications this session: none.** The only writes were
`Rebuild-2.0/Core/Init.lua`, `Tools/test_dispatch.py`, `Rebuild-2.0/README.md`
and this entry.

### Addendum to Entry 003 — three claims checked after the fact

Written same session, after review flagged that the entry above asserted two
things it had not actually verified. Counts updated: **86 checks, 17 mutations**.

**1. The removed/renamed 1.x surface was only half-grepped.** `TA.logLevel` was
checked; **`TA:InitDB` was not** — it had been split into `InitAccountDB` +
`InitCharDB` and the old name simply deleted. Grepped now: **no module calls
it.** The only 1.x callers are `Core/Init.lua` itself and
`Tools/test_onboarding.py`, which drives it directly at line 199.

A one-line compatibility shim was added anyway, on the same fail-open reasoning
as `UpdateModules`: the boot split is a Core concern, and a method nobody calls
costs one line while one that somebody calls fails at login. Covered by
`test_legacy_initdb_shim`.

**2. Moving the profession snapshot later is safe — and this was luck, not
judgement.** Moving the write from `OnLogin` to first `PLAYER_ENTERING_WORLD`
means it now lands **after** module `Init()` rather than before. Any module
reading `charDB.professionSnapshot` during `Init()` would have started seeing
last session's value, or `nil` on a fresh character — silently, which is the
exact failure shape this rewrite exists to remove.

Grepped: **`professionSnapshot` is written and never read.** Not by any module,
not by `Core/`. It is write-only account-wide data collection, consumed by
reading SavedVariables outside the game — which is what its 1.x comment meant by
"read back from SavedVariables afterward". The only `db.char` iteration in
`Modules/` is `DevHelpers.lua:481`, and that walks `coordLog`.

So the reordering is safe. **But the entry above justified it from a comment
rather than a grep, and a write-only field is exactly the kind of thing that
acquires a reader later.** If one appears, it must not read at `Init()` time.

**3. One mutation was passing on a crash, not on its assertion.** The
`identity failure made silent again` mutation deleted the whole `if` block, so
`name` stayed `nil` and the `name .. "-" .. server` concat threw *before*
`test_missing_identity_is_loud` could assert anything — 0 red checks, exit
non-zero. It proved the fallback existed, not that the failure was loud.

Replaced with a surgical variant that deletes **only** the `TA:Printf(ERROR)`
call and keeps both fallback assignments. The suite now goes red on the right
assertion (`an unavailable character identity is reported at ERROR`). The
loudness is genuinely under test; before this it was not.

*(`SafeRegisterEvent unwrapped` also reports 0 red checks, but there the crash
**is** the failure mode under test — Core failing to load. Left as is.)*

**Also checked and dismissed:** whether adding `dispatch` to `BUILTIN` made
`/ta d` newly ambiguous. It did not — `QuestTracker.lua:3345-3346` already
registers `diag` and `diagnose`, plus `drop` at 3329, so `d` has never
prefix-resolved to `debug` in 1.x either. No regression.

**4. Correction — Entry 003 over-applied F-1, and it was caught by audit.**
The draft as first written moved `InitModules` / `InitUI` / `InitMinimap` /
`ApplyLayout` from `PLAYER_ENTERING_WORLD` (where 1.x ran them) forward to
`PLAYER_LOGIN`. **F-1 never asked for that** — Entry 002's own wording was
*"move InitDB to ADDON_LOADED; keep UI init on PLAYER_ENTERING_WORLD."*

Moving module `Init()` earlier changes the world-data assumptions of all 55
modules simultaneously. Audited every module `Init` body for world-dependent
API calls; two touch them, and one is a genuine silent regression:

- `GuideBrowser:Init` — only tests `if C_SuperTrack then` (namespace existence)
  and registers an event. Harmless.
- **`TravelRouter:Init`** — reads `C_Map.GetBestMapForUnit("player")` to record
  `hearthZoneID`, guarded by `if mapID then`. At `PLAYER_LOGIN` that guard would
  fail *every* login, so the field would never be recorded — no error, no log
  line. The exact failure shape this rewrite exists to eliminate, reintroduced
  by the rewrite itself.

**Corrected.** Boot phases are now:

| Phase | Work |
|---|---|
| `ADDON_LOADED` | `InitAccountDB` — the actual F-1 fix |
| `PLAYER_LOGIN` | `InitCharDB` only (needs unit data, not world data) |
| `PLAYER_ENTERING_WORLD` (first) | `OnLogin` — snapshot, modules, UI, minimap, layout, slash commands. **Bit-for-bit 1.x timing.** |

`OnFirstWorldEnter` is retained as an alias for `OnLogin`. A mutation
(*"F-1 over-applied: module init pulled forward to PLAYER_LOGIN"*) now guards
against the regression returning. **17 mutations, all caught.**

The lesson generalises: *the safe default in a rewrite is to preserve legacy
timing unless the defect under repair specifically requires changing it.*

**Still standing from the entry above:** none of this has run in the game, and
F-4's justification (that `ApplyLayout` is reachable from a tainted `SetItemRef`
path) is inherited from Entry 002 — `Core/UI.lua` has not been read. The guard
is required by DIRECTIVE §3.3 regardless, and `InCombatLockdown` and taint are
distinct constraints, so keep the guard but do not treat that mechanism as
verified.

---
