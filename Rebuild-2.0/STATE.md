# ToonAge 2.0 — Project State

**Replaces `JOURNAL.md`** (50 KB of append-only session narrative, deleted
2026-08-01). The old content is in git at `7e1cb09` if it is ever wanted.

**The rule that replaces "append-only":** git log records *what changed* and
when. This file records only **what is true now** and **what is undecided**.
Edit it in place. Do not append a section because work happened — append only
when a decision changes or a fact is newly measured. If this file grows past
~200 lines, something has gone wrong.

---

## Where things stand

### 1.x — branch `main`, shipping

81 Lua files in the TOC. Offline suites green: `check_lua.py` 81 files parsed,
`test_onboarding.py` 87 checks.

### 2.0 — branch `2.0`, draft only

`Rebuild-2.0/Core/Init.lua` — a rewrite of the event dispatcher plus fixes
F-1…F-7. **It is not in `ToonAge.toc` and the game client has never loaded it.**
Offline: `test_dispatch.py` 86 checks, `mutate_dispatch.py` 17 mutations all
caught.

**The single most important open item: 2.0 has never run in the game.** Only an
in-game run has authority; syntax and behaviour suites do not.

### Test harness — `ToonAge_20test`

Installed in `_ptr_` and `_retail_`, not in git. It is the live addon with
`Core/Init.lua` swapped for the 2.0 draft. Enable it *instead of* `ToonAge`,
never alongside — both declare `ToonAgeDB` and the same compartment globals.

**Status: built and verified on disk, never successfully loaded.** No
`SavedVariables/ToonAge_20test.lua` exists in either client, which is the proof.
It ships `## DefaultState: disabled`, so it must be ticked by hand, and a
newly-added addon folder is only enumerated at client launch — `/reload` will
not find it.

---

## What 2.0 actually changes — the entire scope

**The dispatcher.** 1.x broadcasts every event to all 55 registered modules via
`pairs()`, `pcall`-ing `OnEvent` on the 35 that define one. `BAG_UPDATE` fires
~5× per loot, so a single loot costs ~175 `pcall` invocations. 2.0 builds
`event → subscriber[]` lists and dispatches only to subscribers, in deterministic
registration order — which also fixes module init order varying per login.

**Fail-open by design.** A 2-arg `RegisterModule` call keeps broadcasting exactly
as 1.x. All 55 existing registrations are 2-arg, so nothing changes until a
module opts in; `/ta dispatch` reports who is still on the legacy path. A
fail-closed default would have silently killed 35 handlers.

| Fix | What it does |
|---|---|
| F-1 | Boot split: `InitAccountDB` at `ADDON_LOADED`, `InitCharDB` at `PLAYER_LOGIN`, everything else at first `PLAYER_ENTERING_WORLD` (1.x timing preserved). |
| F-2 | One list of built-in command names; 1.x's second hardcoded list had drifted. |
| F-3 | `BUILTIN` hoisted to file scope — 1.x rebuilt it plus ~16 closures on every `/ta`. |
| F-4 | Combat guard on frame-affecting commands; 1.x had zero in this file. |
| F-5 | One log-level source; `TA.logLevel` mirror removed. |
| F-6 | `FuzzyScore` bounded before allocating. |
| F-7 | `GetDB()`/`GetCharDB()` accessors; `/ta reset` rebuilds both scopes. |

---

## Measured facts that are easy to get wrong

- **No AceDB.** `Libs/` holds only `LibStub.lua`. Persistence is a hand-rolled
  `ToonAgeDB` global with `DB_DEFAULTS` in `Core/Init.lua`.
- **`ADDON_NAME` is hardcoded** at `Rebuild-2.0/Core/Init.lua:15` and gates all
  initialisation at `:753`. A copy in a differently-named folder loads, defines
  everything, and **silently never initializes**.
- **`Bindings.xml` is auto-loaded by WoW and is not in the TOC.** Any scan that
  derives "reachable code" from the TOC alone will wrongly call its five
  `ToonAge_Toggle*` globals dead.
- **`_retail_/Interface/AddOns/ToonAge` is a `robocopy /MIR` target**
  (`Tools/deploy.ps1:40`). Never edit it. *Sibling* folders are not mirrored and
  are safe.
- **No file-scope global leaks.** Function-scope leaks are unmeasured and need a
  real linter.
- 55 modules registered; 35 define `OnEvent`; 18 also self-register events on
  their own frames, so a module's declared event list is not a complete picture.

**Legacy baseline** (measured 2026-07-31; the numbers 2.0 is judged against —
absorbed from `STAGE0_POSTMORTEM.md` before deleting it):
30,404 lines of logic across 61 files · 8,030 lines of static `Data/` ·
heaviest module `QuestTracker.lua` at 3,699 lines ·
17 `OnUpdate` handlers · 12 `InCombatLockdown` guards · 154 `pcall` sites.

---

## Open decisions

| # | Decision | Status |
|---|---|---|
| D-1 | AceDB-3.0, or keep hand-rolled `ToonAgeDB`? | **Open — gates the whole database half of 2.0.** `xpHistory` and `errorLog` are unbounded-growth shapes. |
| D-2 | Is `QuestTracker.lua` (3,699 lines, 12% of logic) in scope? | Open |
| D-4 | Publish to CurseForge, Wago, or both? | Deferred with Stage 4 |
| D-5 | Exclude `Rebuild-2.0/` from `deploy.ps1`? | Open — one line at `Tools/deploy.ps1:91` |
| D-7 | Mainline-only, no Classic? | **Answered 2026-08-01: Classic IS a goal.** The earlier "Classic is a second addon, not a port" recommendation is **withdrawn** — it was wrong, see below. |

**Answered:** D-3 — 2.0 lives on a branch in the existing `Sirc146/ToonAge`, not
a new repo. D-6 — push when green. D-7 — Classic is in scope.

---

## Classic — branch `classic`, and why the earlier assessment was wrong

Found at `_classic_/Interface/AddOns/ToonAge`, outside the repo and in no git
history. Now preserved on branch `classic` (branched from `main`, so
`git diff main..classic` works). **It is a real adaptation, not an abandoned
stub.**

**Scope:** 38 TOC entries. Keeps QuestTracker, the Guide stack, Arrow, AntTrail,
NavHud, MapPins, CoordResolver, XPTracker, RestOptimizer, DeathRecovery,
GatherTracker, Character, Gear. Drops every spec/talent/rotation/profession/
endgame module. That is a coherent **leveling-and-navigation** addon — which is
what Classic players use.

**It is already API-adapted.** `Core/Utils.lua`'s header documents each
substitution: no `C_Spell` → `GetSpellInfo` globals; no `C_Container` →
`GetContainerItemLink`; no `C_AddOns` → `IsAddOnLoaded`; no
`C_Traits`/`C_ClassTalents` → talent functions return nil. `Data/ApiManifest.lua`
annotates `C_Map` as *"available in Cata Classic"* and `C_QuestLog` as *"mostly
available"*. `Core/ApiGuard.lua` resolves all 58 manifest entries against the
running client and reports what is missing.

**Two corrections recorded so they are not repeated:**

1. An earlier scan reported "retail-only APIs used in the classic build —
   `C_Traits` 2 hits, `GetSpecialization` 15 hits". **Those hits are comments
   documenting the absence, and guarded calls** (`if not GetSpecialization then
   return nil end`). Counting raw grep hits as usage produced a false verdict.
2. The claim "`C_QuestLog` and `C_Map` do not exist in a 5.5.4 client" was
   asserted, not measured, and the repository's own manifest already said
   otherwise.

**Open risk, unmeasured:** `Utils.lua` says "adapted for **Cataclysm** Classic",
but `ToonAge.toc` targets `## Interface: 50504` — **Mists of Pandaria**. The
adaptation was written against a different expansion than the TOC targets.

**Never run.** No SavedVariables exist in `_classic_/WTF`. The next step is to
load it and run **`/ta apiprobe`**, which reports exactly which of the 58 APIs
resolve on a live MoP client. That answers the Cata-vs-MoP gap with a
measurement instead of a guess.

---

## Next, in order

1. **Cleanup** (in progress) — see the ledger below.
2. **Smoke-test the 2.0 draft in-game.** Enable `ToonAge 2.0 TEST` only, then
   `/ta health`, `/ta dispatch`, `/ta errors`. `/ta dispatch` is the discriminator:
   it does not exist in 1.x, so if it is unknown, the harness is not loaded.
3. **Migrate modules to declared events**, starting with real `BAG_UPDATE`
   consumers, and watch `/ta dispatch` shrink.
4. **Answer D-1** and design the database half.

---

## Cleanup ledger — 2026-08-01

**Done:** `JOURNAL.md` (50,412 B) and `STAGE0_POSTMORTEM.md` (8,131 B) deleted;
2.0 workspace prose 65,811 → 13,025 B.

**Done:** `AddOns/Archive/CharacterAdvisor` (25 files, 232,468 B) preserved to
branch `pre-git-characteradvisor` (`ef6437a`) and verified retrievable from the
remote. It is the **only** copy of ToonAge's predecessor: dated 2026-06-27, a
week before initial commit `5cdec6c`, with `Modules/Rotation.lua` differing by
hash — genuinely pre-git content, in no repository until now. WoW never loaded
it (the client scans `AddOns/<Name>/<Name>.toc` one level deep; this TOC is two
levels down). *Folder deletion still pending — needs a permission the session
does not have.*

**Pending, same reason:** `Archive/` (19,885 B) and `Monk/` (1,058 B) inside the
addon — orphaned, absent from the TOC, recoverable from `main`'s history.

**Why the dead code exists — measured, and it is not a missed cleanup.** Of 29
candidates traced through the full history with `git log -S`, **28 never had a
caller in any commit** — the definition landed and no call was ever written.
Cause: symmetric API surfaces written up front and partially consumed.
`RotationConditions.lua` defines 29 predicates in logical pairs and uses 8;
`ExecuteOrProc` is called 15 times while `NoBuff`, `ComboBelow`, `SingleTarget`
and 18 others were never called once.

Exactly **one** was genuinely abandoned: `TargetMarker.UnmarkAll`, orphaned when
commit `25c3ee3` ("purge stale docs, remove dead GuideManager") removed its
caller. So prior cleanup did leave something behind — one function, not the
pattern.

**Correction to an earlier claim in this ledger's first draft:** the
`RotationConditions` entries were called "probably string-keyed from rotation
data". They are not — zero quoted-string references, zero calls. They are dead
and safe to cut. **`Bindings.xml` remains the real trap**: it is auto-loaded,
appears in no TOC, and its five `ToonAge_Toggle*` globals will look dead to any
TOC-derived scan. `ToonAge_ToggleTestBar` is live there.

**Prose inventory at cleanup time:** 177,845 B across 12 files, against
1,755,760 B of code. `TODO.md` (34 KB), `IMPROVEMENT_PLAN.md` (26 KB) and
`ARCHITECTURE.md` (24 KB) overlap heavily and have been wrong in both
directions — describing modules never built, and marking shipped features as
TODO. Consolidation is pending one decision on which survives.
