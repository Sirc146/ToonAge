# ToonAge 2.0 — Project State

Records only **what is true now** and **what is undecided**; edit in place. Full
rule in [DIRECTIVE.md](DIRECTIVE.md) §4. Cap ~200 lines — cut before adding.
(Predecessor `JOURNAL.md` is in git at `7e1cb09`.)

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

**2.0 has now run in the game — measured 2026-08-02, see below.** Only an
in-game run has authority; syntax and behaviour suites do not.

### Test harness — `ToonAge_20test`

Installed in `_ptr_` and `_retail_`, not in git. It is the live addon with
`Core/Init.lua` swapped for the 2.0 draft. Enable it *instead of* `ToonAge`,
never alongside — both declare `ToonAgeDB` and the same compartment globals.

**Status: loaded and ran clean on PTR.** Measured 2026-08-02, correcting the
previous "never successfully loaded" claim in this file.

`_ptr_/.../SavedVariables/ToonAge_20test.lua` exists — 4,956 B, written
2026-08-01 07:02. It holds a fully-populated `ToonAgeDB` (Ellacait-Vargoth, 90
HUNTER: modules, char scope, professions, tasks) and **`errorLog` is empty**.
Dispositive because: `ToonAge_20test/Core/Init.lua:15` sets
`ADDON_NAME = "ToonAge_20test"` and gates init at `:753`, so the silent-no-init
trap below does not apply; and sibling `ToonAge.lua` still dates 07-31 23:46,
so 1.x was not loaded that session (WoW rewrites SV at logout) — 2.0 built this
DB alone, satisfying "never alongside". An empty `errorLog` across a full login
means the F-1 boot split, the dispatcher and the DB accessors survived a client.

That last point is only meaningful because error capture is **verified still
wired** in the harness: `seterrorhandler` is installed by
`Modules/ErrorLog.lua:214`, which the harness does *not* swap (it swaps
`Core/Init.lua` only), and the 2.0 draft carries six `TA.ErrorLog:Log` sites to
1.x's five — adding `OnEvent` (`:620`) and `CombatDefer` (`:706`). The capture
path also demonstrably works, since 1.x recorded a real `StripMarkup` fault into
retail's SV. So the empty log is a measurement, not a silent no-op.

**Not yet measured:** `/ta dispatch` and `/ta health` output, retail, and combat
load. Persistence proves boot, not throughput.

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
| D-8 | Port the ~729 lines of QuestTracker/Gear methods the Classic build calls but never defines? | **Open — gates whether Classic is usable at all.** See "structurally incomplete" below. Alternative: cut the call sites and ship a smaller Classic scope. |

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

**The Cata-vs-MoP gap is now bounded — measured 2026-08-02.** Not project-wide,
as previously feared: of 31 Lua files, **26 name MoP / `50504`**, matching the
TOC. Only four name Cataclysm — `Core/Utils.lua` (the 5-substitution list),
`Core/Init.lua`, `Core/UIModern.lua`, and `Data/ApiManifest.lua` ("Cataclysm
Classic (**40402**) expected API availability"). The risk is concentrated in
Core and, most of all, in the manifest `ApiGuard` checks against.

**Why this is a real risk and not just stale comments.** `Utils.lua` substitutes
*globals* for namespaces it believes absent: `GetSpellInfo` for `C_Spell`,
`GetContainerItemLink` for `C_Container`, `IsAddOnLoaded` for `C_AddOns`. Those
were correct for 40402. Blizzard has since **backported several `C_*` namespaces
into Classic clients and removed some of the matching globals**. If a global the
addon depends on is gone in 5.5.4, the substitution fails *silently* — the exact
failure class this project exists to remove. Do not "fix" any of these against a
guessed signature; `/ta apiprobe` measures all 58 entries against the running
client and settles it.

**Fixed 2026-08-02 — stale TOC entry.** The Classic TOC listed
`Modules\MapPins.xml`, which exists in **neither** the disk copy nor branch
`classic`. It is a leftover from the retail TOC: `Modules/MapPins.lua:7` states
the Classic port deliberately "uses simple `CreateFrame` pins parented to
`WorldMapFrame` instead" of `TAMapPinTemplate`. The line is removed from the
live `_classic_` copy. **Branch `classic` still carries it** and needs the same
one-line commit. Found by running `deploy.ps1`'s manifest check against the
Classic folder — which had never been done, because Classic never went through
`deploy.ps1`. Disk and branch are otherwise byte-identical across all 38 files.

**First Classic login: 2026-08-02 07:02 — it crashed in `InitUI`, and the cause
is the predicted one.** 14 errors, the first being
`Core/UI.lua:49: attempt to call a nil value` in `SetBackdrop`, via
`UI.lua:113 ApplyBackdrop` ← `Init.lua:332 InitUI` ← `Init.lua:277 OnLogin`.
All four line numbers match `_classic_` exactly and none match retail/PTR.

**Cause.** MoP Classic runs the modern client engine, where `SetBackdrop` was
removed from the base Frame API onto `BackdropTemplateMixin`. Frames need the
`"BackdropTemplate"` template or the mixin. Measured spread: 62 `SetBackdrop`
sites across 10 files, but **only `Core/UI.lua` and `Core/UIModern.lua` are
broken** — they are the sole files with zero `BackdropTemplate` usage. All eight
`Modules/` files pair correctly (`SetBackdrop` count ≤ `BackdropTemplate`
count). This is the Cata-era-Core / MoP-era-Modules split predicted above,
confirmed by a live crash: `UIModern.lua` was one of the four Cata files, and
its header asserted "Identical to Retail — all constants and CreateFrame calls
work in Cata Classic." That claim was false and has been corrected in place.

**Fixed 2026-08-02** via `EnsureBackdrop` at `Core/UI.lua:65`, applied at both
`ApplyBackdrop` chokepoints (`UI.lua:88`, `UIModern.lua:51`) — which covers all
four affected frames without touching a single `CreateFrame` call. The mixin
route was chosen over adding `"BackdropTemplate"` deliberately: an unknown
template string is itself a hard error, and that string's availability on 5.5.4
is **still unmeasured**. If the mixin is also unavailable the frame goes
unstyled, the addon keeps loading, and the gap is logged rather than swallowed.

**`BackdropTemplateMixin` and `Mixin` both exist on 5.5.4 — inferred, 07:08.**
The `UI.lua:49` error is absent from the 07:08:28 error-log pass while present
at 07:02:02 and 07:02:53, so `EnsureBackdrop` succeeded. It logs a
`"UI Backdrop"` entry when the mixin is unavailable, and `ErrorLog` was
demonstrably live at 07:08 (it captured two other faults); no such entry
appeared. Strong, but still an inference — confirm with
`/dump type(BackdropTemplateMixin), type(Mixin)`. If confirmed, the durable fix
is to pass `"BackdropTemplate"` at `CreateFrame` in those two files and retire
the shim.

### The Classic port is structurally incomplete — measured 2026-08-02

The backdrop crash was masking this. **Five methods are called but never
defined**, found by a per-file defined-vs-called scan (PTR run as a control to
strip false positives, where `self` is a frame inside a closure):

| Missing method | Called at (Classic) | Defined in PTR | Size |
|---|---|---|---|
| `QT:UpdateWindow` | 7 sites incl. `:818` | `:1585` | ~341 lines |
| `Gear:Render` | `:198` | `:373` | ~252 lines |
| `QT:CheckProximityAdvance` | `:814`, in an `OnUpdate` | `:3359` | ~70 lines |
| `QT:ShowToast` | `:317`, `:334`, `:344` | `:2968` | ~41 lines |
| `QT:ToggleWindow` | `:730` | `:2050` | ~25 lines |

Classic's QuestTracker defines 22 `QT:` methods against PTR's 47 — the port
dropped 25 definitions and left the call sites behind. **~729 lines of PTR logic
are missing, before any API adaptation.** QuestTracker is the centrepiece of the
"leveling-and-navigation" scope this build claims, so Classic is not merely
buggy: it is unfinished. Only `UpdateWindow` surfaced in the log because
`InitWindow` aborts at `:818` before reaching the rest.

**This resizes the Classic question.** The earlier "it is a real adaptation, not
an abandoned stub" verdict was right about *intent* — the API substitution work
is genuine — but wrong to imply completeness. Whether to port those 729 lines is
an open decision, not a bug fix. Recorded as **D-8**.

**Fixed 2026-08-02 — MapPins was fully dead.** `Modules/MapPins.lua:311`
registered `WORLD_MAP_UPDATE`, removed in the Legion 7.0 map rewrite. The throw
happened *before* the next line installed the `OnEvent` handler, so the
`ADDON_LOADED` branch never ran and the whole module was disabled by one bad
event name. Registration removed; map-open is still covered by the existing
`WorldMapFrame` Show/OnHide hooks. Refresh-on-zone-change is the only loss and
is **deliberately not replaced with a guessed event**.

**Classic now persists — first SavedVariables ever, 2026-08-02 07:08.**
`_classic_/WTF/Account/STREFF/SavedVariables/ToonAge.lua`, 3,496 B, with a
`.bak`. The "Never run / no SavedVariables exist" statement above is retired.

The file is one session behind by design — WoW flushes SV at reload/logout, so
it holds the six 07:02 errors and not the two from 07:08:28, which were still
in memory. Useful as a caution: **`/ta errors` in-game and the SV on disk will
disagree by one session**, and the disk copy is the older of the two.

**Most of Classic works.** Real character `Asirc-Myzrael` (41 HUNTER) persisted:
`xpHistory` (XPTracker), `prof1`/`prof2` = Mining/Engineering (Character),
`gatherHistory` (GatherTracker), plus six modules enabled — AutoMount,
GatherTracker, AutoEquip, MapPins, NavHud, CutsceneSkip. So the API-substitution
work in `Core/Utils.lua` is broadly sound on 5.5.4; the failures are confined to
the two Core UI files (fixed) and the incomplete QuestTracker/Gear port (D-8).

Next, still owed: **`/ta apiprobe`** captured with **`/ta copychat`** — output
is print-only and unrecoverable after logout. Not blocked by the QuestTracker
fault, which aborts only that module's init.

---

## Next, in order

1. **Finish the 2.0 smoke test.** Boot is proven; behaviour is not. Enable
   `ToonAge 2.0 TEST` only, then `/ta dispatch`, `/ta health`, `/ta errors`.
   `/ta dispatch` is the discriminator — it does not exist in 1.x.
2. **Run `/ta apiprobe` on every installed client.** This is the seed data for
   `Core/Compat.lua` and nothing in the multi-client plan proceeds without it.
   **`Core/ApiGuard.lua:156` maps `apiprobe` to `Report()`, which only prints —
   it does not write SavedVariables.** So the output cannot be recovered from
   disk after logout; it must be captured with `/ta copychat` while logged in.
   Classic (5.5.4 MoP) is the highest-value run: it settles the Cata-vs-MoP gap
   recorded below, which is currently a guess.
3. **Migrate modules to declared events**, starting with real `BAG_UPDATE`
   consumers, and watch `/ta dispatch` shrink.
4. **Answer D-1** and design the database half.

## Installed clients — from root `.build.info`, 2026-08-02

Five installed products, not the four TODO.md lists. `_beta_` has a folder but
**no `.build.info` row**, so it is not an installed product — do not treat the
folder as a target.

| Folder | Product | Version | ToonAge present |
|---|---|---|---|
| `_retail_` | `wow` | 12.0.7.68887 | yes (deployed, `4d95743`) |
| `_ptr_` | `wowt` | 12.1.0.68914 | yes (**the repository**) |
| `_classic_` | `wow_classic` | 5.5.4 (MoP) | yes (branch `classic`, never run) |
| `_classic_era_` | `wow_classic_era` | 1.15.9.68940 | **no** |
| `_anniversary_` | `wow_anniversary` | 2.5.6.68941 | **no** |

Mainline `ToonAge.toc` declares `## Interface: 120007, 120100` only. Deploying
it to `_classic_era_` or `_anniversary_` would install an out-of-date,
API-incompatible addon — those two are not deploy targets without a build that
targets `11509` / `20506` first.

**Retail is current.** `main` is `4d95743`, which is exactly the commit stamped
in `_retail_/.../DEPLOY_INFO.txt`. Retail needs no deploy — only the probe.
`2.0` is 8 ahead of `main`, 0 behind.

> ⚠️ **`deploy.ps1 -Client _classic_` is destructive unless branch `classic` is
> checked out.** The script `/MIR`s whatever the working tree holds. Run from
> `main` or `2.0` it would mirror the 82-file mainline build over the 38-file
> Classic adaptation, deleting the entire Classic port from disk. Recoverable
> from branch `classic`, but silent. Same hazard in reverse: never deploy
> `classic` to `_retail_`.

---

## Cleanup ledger — 2026-08-01

Completed cleanup is in `git log` and is not restated here (DIRECTIVE §4).
What remains true:

**Pending deletion — needs a permission no session has had yet:**
`AddOns/Archive/CharacterAdvisor` (25 files, 232,468 B; already preserved to
branch `pre-git-characteradvisor` at `ef6437a` and verified retrievable from
the remote — it is the only copy of ToonAge's predecessor), plus `Archive/`
(19,885 B) and `Monk/` (1,058 B) inside the addon. All three are absent from
the TOC and recoverable from history.

**Why the dead code exists — measured, not a missed cleanup.** Of 29 candidates
traced with `git log -S`, **28 never had a caller in any commit**: symmetric API
surfaces written up front and partially consumed. `RotationConditions.lua`
defines 29 predicates in pairs and uses 8 — the unused ones have zero calls and
zero quoted-string references, so they are dead and safe to cut. Exactly one was
genuinely abandoned: `TargetMarker.UnmarkAll`, orphaned by `25c3ee3`.

**Doc consolidation, still pending one decision.** `TODO.md` (34 KB),
`IMPROVEMENT_PLAN.md` (26 KB) and `ARCHITECTURE.md` (24 KB) overlap heavily and
have been wrong in both directions — describing modules never built, and marking
shipped features as TODO. `TODO.md`'s "PICK UP HERE" block is dated 2026-07-26
and is now stale in two ways: it lists four clients (there are five installed),
and its "one command owed" framing predates this file. Do not plan from it.
