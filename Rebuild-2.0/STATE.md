# ToonAge 2.0 — Project State

Records only **what is true now** and **what is undecided**; edit in place. Full
rule in [DIRECTIVE.md](DIRECTIVE.md) §4. Cap ~200 lines — cut before adding.
(Predecessor `JOURNAL.md` is in git at `7e1cb09`.)

---

## Where things stand

**Branches.** `main` = `4d95743` (shipping, matches the deployed retail commit).
`2.0` = the rebuild, ahead of `main`. `classic` = the MoP fork. `2.0` and
`classic` are each **ahead 1 and unpushed** as of 2026-08-02.

**Offline suites — all green, re-run 2026-08-02:** `check_lua.py` 81 files ·
`test_onboarding.py` 87 checks · `test_dispatch.py` 86 checks ·
`mutate_dispatch.py` 17/17 mutations caught. Classic build syntax-checked for
the first time: 36/36, and all 36 TOC entries resolve to real files.

> **Dev environment is not self-provisioning.** `luaparser` (for `check_lua`)
> and `lupa` (for both behaviour suites) were **absent** on 2026-08-02 and were
> installed with `python -m pip install --user`. A green result recorded in this
> file is not evidence the suite can run on a fresh machine — check first.

### 2.0 — branch `2.0`, draft only

`Rebuild-2.0/Core/Init.lua` rewrites the event dispatcher plus fixes F-1…F-7.
**It is not in `ToonAge.toc`; the shipping client has never loaded it.**

### Test harness — `ToonAge_20test`

Installed in `_ptr_` and `_retail_`, not in git. The live addon with
`Core/Init.lua` swapped for the 2.0 draft. Enable it *instead of* `ToonAge`,
never alongside — both declare `ToonAgeDB` and the same compartment globals.

**Boot is proven on PTR** (2026-08-02). Its SavedVariables holds a fully
populated `ToonAgeDB` (Ellacait-Vargoth, 90 HUNTER) with an **empty
`errorLog`**, and error capture is verified still wired: `seterrorhandler` is
installed by `Modules/ErrorLog.lua:214`, which the harness does not swap. So the
empty log is a measurement, not a silent no-op — the F-1 boot split, the
dispatcher and the DB accessors survived a real client.

**Not yet measured:** `/ta dispatch`, `/ta health`, retail, and combat load.
Persistence proves boot, not throughput.

---

## What 2.0 actually changes — the entire scope

**The dispatcher.** 1.x broadcasts every event to all 55 registered modules via
`pairs()`, `pcall`-ing `OnEvent` on the 35 that define one. `BAG_UPDATE` fires
~5× per loot, so one loot costs ~175 `pcall` invocations. 2.0 builds
`event → subscriber[]` lists and dispatches only to subscribers, in deterministic
registration order — which also fixes module init order varying per login.

**Fail-open by design.** A 2-arg `RegisterModule` call keeps broadcasting exactly
as 1.x. All 55 existing registrations are 2-arg, so nothing changes until a
module opts in; `/ta dispatch` reports who is still on the legacy path. A
fail-closed default would have silently killed 35 handlers.

| Fix | What it does |
|---|---|
| F-1 | Boot split: `InitAccountDB` at `ADDON_LOADED`, `InitCharDB` at `PLAYER_LOGIN`, rest at first `PLAYER_ENTERING_WORLD` (1.x timing preserved). |
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
  (`Tools/deploy.ps1:40`). Never edit it. *Sibling* folders are not mirrored.
- **`/ta apiprobe` only prints.** `Core/ApiGuard.lua:156` maps it to a local
  `Report()` at `:107` — no SavedVariables write. Output is **unrecoverable
  after logout** and must be captured with `/ta copychat` while logged in.
  (Commit `48e7e20` made the *other* probes persist; it did not change this one.)
- **`_classic_` is outside git** — an unversioned working folder. Fixes made
  there exist nowhere else until copied into a `classic` checkout by hand.
- **No file-scope global leaks.** Function-scope leaks are unmeasured and need a
  real linter.
- 55 modules registered; 35 define `OnEvent`; 18 also self-register events on
  their own frames, so a module's declared event list is not a complete picture.
- **Grep hits are not usage.** An earlier scan called Classic broken over
  `C_Traits`/`GetSpecialization` hits that were comments and guarded calls
  (`if not GetSpecialization then return nil end`). Counting raw hits produced a
  false verdict.

**Legacy baseline** (measured 2026-07-31; what 2.0 is judged against):
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
| D-8 | Port the ~729 lines of QuestTracker/Gear methods the Classic build calls but never defines? | **Open — gates whether Classic is usable at all.** Alternative: cut the call sites and ship a smaller Classic scope. |

**Answered:** D-3 — 2.0 lives on a branch in `Sirc146/ToonAge`, not a new repo.
D-6 — push when green. D-7 — **Classic is in scope**; the earlier "Classic is a
second addon, not a port" recommendation is withdrawn.

---

## Classic — branch `classic`

**Scope:** 38 TOC entries. Keeps QuestTracker, the Guide stack, Arrow, AntTrail,
NavHud, MapPins, CoordResolver, XPTracker, RestOptimizer, DeathRecovery,
GatherTracker, Character, Gear. Drops every spec/talent/rotation/profession/
endgame module — a coherent **leveling-and-navigation** addon, which is what
Classic players use.

**It is genuinely API-adapted.** `Core/Utils.lua`'s header documents each
substitution (`GetSpellInfo` for `C_Spell`, `GetContainerItemLink` for
`C_Container`, `IsAddOnLoaded` for `C_AddOns`, talent functions return nil).
`Core/ApiGuard.lua` resolves all 58 `Data/ApiManifest.lua` entries against the
running client.

**It ran for the first time on 2026-08-02 and mostly works.** Real character
`Asirc-Myzrael` (41 HUNTER) persisted `xpHistory`, professions, `gatherHistory`
and six enabled modules. First-login crash in `InitUI`, dead `MapPins`, and a
stale TOC entry are **fixed and committed at `8e871b2`** — captured from the
unversioned `_classic_` folder, where they had been the only copy.

**Two things remain unmeasured, and both matter:**

1. **`BackdropTemplateMixin` / `Mixin` exist on 5.5.4 — inferred, not proven.**
   The fix is a runtime shim (`EnsureBackdrop`, `Core/UI.lua:65`) chosen because
   an unknown template string is itself a hard error. Confirm with
   `/dump type(BackdropTemplateMixin), type(Mixin)`. If confirmed, the durable
   fix is to pass `"BackdropTemplate"` at `CreateFrame` and retire the shim.
2. **The manifest targets the wrong client.** `Data/ApiManifest.lua` documents
   "Cataclysm Classic (**40402**) expected API availability" while the TOC and 26
   of 31 files target MoP `50504`. `Utils.lua` substitutes *globals* for
   namespaces it believes absent — correct for 40402, but Blizzard has since
   backported several `C_*` namespaces into Classic and removed some matching
   globals. If a global it depends on is gone in 5.5.4 the substitution fails
   **silently**. Do not "fix" these against a guessed signature; `/ta apiprobe`
   settles all 58 entries.

**The port is structurally incomplete (D-8).** Five methods are called but never
defined — found by a defined-vs-called scan with PTR as a control:

| Missing | Called at (Classic) | Defined in PTR | Size |
|---|---|---|---|
| `QT:UpdateWindow` | 7 sites incl. `:818` | `:1585` | ~341 lines |
| `Gear:Render` | `:198` | `:373` | ~252 lines |
| `QT:CheckProximityAdvance` | `:814`, in an `OnUpdate` | `:3359` | ~70 lines |
| `QT:ShowToast` | `:317`, `:334`, `:344` | `:2968` | ~41 lines |
| `QT:ToggleWindow` | `:730` | `:2050` | ~25 lines |

Classic defines 22 `QT:` methods against PTR's 47 — 25 definitions dropped, call
sites left behind. **~729 lines missing before any API adaptation.** Only
`UpdateWindow` surfaced in the log because `InitWindow` aborts at `:818` first.

---

## Next, in order

1. **`/ta apiprobe` + `/ta copychat` on every installed client.** Seed data for
   `Core/Compat.lua`; nothing in the multi-client plan proceeds without it.
   Classic is the highest-value run — it settles the manifest gap above.
   Not blocked by the QuestTracker fault, which aborts only that module's init.
2. **Finish the 2.0 smoke test.** Enable `ToonAge 2.0 TEST` only, then
   `/ta dispatch`, `/ta health`, `/ta errors`. `/ta dispatch` is the
   discriminator — it does not exist in 1.x.
3. **Decide D-8**, now that the Classic build boots and the gap is bounded.
4. **Migrate modules to declared events**, starting with real `BAG_UPDATE`
   consumers, and watch `/ta dispatch` shrink.
5. **Answer D-1** and design the database half.

## Installed clients — from root `.build.info`, 2026-08-02

Five installed products. `_beta_` has a folder but **no `.build.info` row**, so
it is not an installed product — do not treat the folder as a target.

| Folder | Product | Version | ToonAge present |
|---|---|---|---|
| `_retail_` | `wow` | 12.0.7.68887 | yes (deployed, `4d95743` — current, needs only the probe) |
| `_ptr_` | `wowt` | 12.1.0.68914 | yes (**the repository**) |
| `_classic_` | `wow_classic` | 5.5.4 (MoP) | yes (unversioned copy; branch `classic`) |
| `_classic_era_` | `wow_classic_era` | 1.15.9.68940 | **no** |
| `_anniversary_` | `wow_anniversary` | 2.5.6.68941 | **no** |

`ToonAge.toc` declares `## Interface: 120007, 120100` only. Deploying it to
`_classic_era_` or `_anniversary_` would install an API-incompatible addon —
they are not deploy targets without a build targeting `11509` / `20506`.

> ⚠️ **`deploy.ps1 -Client _classic_` is destructive unless branch `classic` is
> checked out.** The script `/MIR`s whatever the working tree holds — run from
> `main` or `2.0` it would mirror the 82-file mainline build over the 38-file
> Classic port, deleting it from disk. Silent, though now recoverable from
> `8e871b2`. Same hazard in reverse: never deploy `classic` to `_retail_`.

---

## Cleanup ledger

**Pending deletion — needs a permission no session has had yet:**
`AddOns/Archive/CharacterAdvisor` (25 files, 232,468 B; preserved to branch
`pre-git-characteradvisor` at `ef6437a` and verified retrievable from the
remote — the only copy of ToonAge's predecessor), plus `Archive/` (19,885 B)
and `Monk/` (1,058 B) inside the addon. All three are absent from the TOC.

**Why the dead code exists — measured, not a missed cleanup.** Of 29 candidates
traced with `git log -S`, **28 never had a caller in any commit**: symmetric API
surfaces written up front and partially consumed. `RotationConditions.lua`
defines 29 predicates in pairs and uses 8; the unused ones have zero calls and
zero quoted-string references, so they are dead and safe to cut. Exactly one was
genuinely abandoned: `TargetMarker.UnmarkAll`, orphaned by `25c3ee3`.

**Doc consolidation, still pending one decision.** `TODO.md` (34 KB),
`IMPROVEMENT_PLAN.md` (26 KB) and `ARCHITECTURE.md` (24 KB) overlap heavily and
have been wrong in both directions. `TODO.md`'s "PICK UP HERE" block is dated
2026-07-26 and is stale — it lists four clients (there are five) and its "one
command owed" framing predates this file. **Do not plan from it.**
