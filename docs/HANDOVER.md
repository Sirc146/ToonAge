# ToonAge — Sirc’s Shared Team Record

Single shared record for Christopher (Sirc / Sirc146) and the ToonAge team. All plans, decisions and final approvals lead to Sirc.

The repo https://github.com/Sirc146/ToonAge on branch `test` is the single source of truth. Sister files in this repo: [README.md](../README.md) (human overview), [AGENTS.md](../AGENTS.md) (standing rules and bot workflow), [HISTORY.md](HISTORY.md) (superseded and already-tried archive), [architecture.md](architecture.md) (clients, TOCs, modules, API audit). Box copies, including `/workspace/toonage-docs/`, are drafts only until approved and committed.

**Updated:** November 9, 2026, 9:10 PM PST. **Repo:** https://github.com/Sirc146/ToonAge · **Integration:** `test`.
**Trunk mapping: UNKNOWN.** Some scripts assume `main`; Sirc must confirm the agreed trunk before freshness checks or measurements. Do not silently change branches.

## 1 PROJECT OVERVIEW

ToonAge is a multi-client WoW addon: shared Lua engine, per-client data/modules/TOCs, Python verification, and observed client data feeding advice. Readouts are not the same as reliable personalized guidance.

### Owner, team and mandatory workflow

| Who | Responsibility |
|---|---|
| **Christopher / Sirc** | Owner, final authority and sole in-game tester. Approves scope, specs, merges, installs, releases and accepted risks. |
| Riley | Codes, prepares PRs, packages and installs approved exact builds with backups and settings preserved. |
| Glitch | Tests, cross-class/client regression and GitHub go/no-go. |
| Warden | Checks rules, QA, provenance and independent correctness. |
| Gilder | Art, layout, readable copy and visual go/no-go; preserve Talents art. |
| Chronicler | Data and research; official sources first, exact-client evidence and conflicts. |
| Conductor | Coordinates with Sirc, records plans/dependencies/decisions, maintains this shared record. |

**Workflow rule:** plan with Conductor, write the plan here, then obtain Sirc’s applicable approval. **Every bot reads `AGENTS.md`, `docs/HANDOVER.md` and `docs/HISTORY.md` from the repo before working and records its part afterward as a commit**: dated scope/card, source/head, changes, tests, review, merge/install state, blockers and next step. If the file or evidence is inaccessible, ask a concrete question; do not guess. No bot was notified or dispatched by this documentation draft. Christopher: **“I'd rather have everything working off git.”** After a verified live test: **“After each verified test and its working it's pushed up.”**
Small feature branches and reviewed PRs target `test`; a plan, static GO or relayed approval is not blanket authority. Native approvals must be received directly where required. Preserve Sirc’s exact words; do not turn historical permissions into new ones. Release tags still need his explicit approval. Docs and code changes go in as their own commits so one can be rolled back if needed.

### Product decisions — settled unless Sirc changes them

- Optional level-aware guidance from 1–60 into the endgame: **what, why, alternatives**. Suggestions, not requirements, to help someone who does not know yet tune **their own** playstyle. Easy to ignore, collapse or skip; no rigid script or automated play.
- **Every tab ends in a next step**, based on what the toon actually does, equips, knows and progresses through. Harvest records observations; advice remains a separate, sourced interpretation.
- Gate suggestions on learned spells/ranks/talents, usable equipment, actual points/conditions and relevant context. Spell-name equality is not class/rank provenance. Unknown never means zero, free, owned or “up to date.”
- Mage first, then Sirc’s Warrior **tank and melee DPS**, then Troll Hunter; Hunter spec/level and Warrior details remain UNKNOWN. Validate all classes/specs and tank/healer/melee/ranged contexts, not relabeled damage lists.
- **Vespera has no chosen spec (November 9, 8:02 PM PST).** Frost was selector demonstration. Explicit selection controls guidance; none defaults to Fire. Casts, gear and talents may suggest, never silently select, spend points, respec or edit saves.
- **Playstyle readout: requested, not specified.** Observe actual casts over time, suggest which spec/style the pattern resembles and explain supporting observations. Define window, minimum evidence, retention/reset, context separation and uncertainty before build. Existing Casts log is only an input.
- Separate informational **gear lean** may show school-power or tank/DPS tendencies. It may disagree with casting style; it does not prove intent or optimality. Weighted claims require verified Forever class/spec/role/level/gear/context data. Cast-based design can proceed without numeric weights.
- Capabilities cross nominal roles: threat, mitigation, healing/support, damage and resource tools depend on encounter/toolkit. Mage/Hunter tanking are Sirc’s flexibility examples, **not verified Forever tank certifications**. Never manufacture unsafe tests.
- Sirc likes **“reckless and fun”**; explain tradeoffs without inventing mechanics or unsafe pulls. Preserve Talents artwork, geometry, textures and visual identity.
- Static BiS is never truth. Use verified dynamic/imported weights or explicitly label a heuristic; never invent numbers or import Retail weights. Talent routes and the planning hub remain future work: chosen role/style → route → readable gear/stat priorities → what next/why/how.
- Coexist with ElvUI, MelloUI/Questie, Zygor, WowUp and specialist tools where appropriate; do not rebuild aura engines/boss mods or assume another addon’s data is accessible. ForeverGear/SkillUp remain external specialists unless Sirc decides otherwise.
- Cross-client consistency: same meaningful UX, language and fact→action pattern; per-client mechanics/APIs. Hide an inapplicable view with a reason rather than a blank pane.
- Visual rules: glass shell/title/navigation/copy/settings/export surfaces only, solid readable content; never glass-on-glass, glass rows/cards or traffic-light window buttons. Gilder’s visual GO is required. Native Options → AddOns configuration versus quick-use drawer is the direction; implementation UNKNOWN. Class/custom themes and raised 3 D arrow remain preferences, not proof of delivery.
- Vendor upgrade notice requested: corner badge + tooltip line + one vendor-window line, merchant-event refresh, no popups or automatic purchase. Built/live status UNKNOWN; accessible item/merchant data and honest scoring are prerequisites.

### Standing rules and data rule

Verbatim standing rules (imported November 9, 2026, 8:19 PM PST), button interpretation, freshness order, launch gate, scores and the data rule are in [AGENTS.md](../AGENTS.md). Do not fork that wording here.

### Prior context (Muse export)

Authoritative prior-context source for Sirc’s decisions, roles, harvest-first vision, branch discipline and gates: `Muse-ToonAge-Context-Export.txt`, covering October 3–November 8; read in full November 9 at 8:26 PM PST. Historical reports are not promoted to current verification. Source SHA256: `5e6e522e6cfe9fab6b81ae43406c9edbc794305bd3c280dc9f3d069ec9cf929f`.
Stored verbatim words (line wrapping normalized only):
- “my Friday and Jarvis to Iron Man” — October 4.
- “the trusted advisor from gear to journey.” — October 4, clarified October 7/8.
- “a key factor to how we can build the others the way we want them” — October 4, Harvest.
- “i like the role choice but its not guiding me in the right direction for spell” — October 8.
- “Launch day: re-source every guide reference for cap 60” — October 3; completion UNKNOWN.
- “Every tab ends in a next step.” — October 3.

Known direction: Now = prioritized fact→action briefing; Character = readiness audit; Gear = transparent upgrades; Talents = interactive planner; Spells = rank/training where applicable, toolkit/spec/glyph analysis only where supported; Pets = companion care; PvP = clear progress; Scrolls = consumable readiness; Casts = post-fight mirror, witness never pilot; Harvest = sensor array; SessionCheck feeds Now. Now/Pets/SessionCheck are targets, not claims of today’s visible Forever tabs.
The earlier crew gate was Riley build → Glitch test → Warden rules → Sirc in-game verification → Glitch final upload GO/push, with Gilder’s visual GO separately. Whether “upload” means test distribution or final launch remains UNKNOWN; do not pretend tonight’s static reviews satisfy unreported live acceptance.
Historical recipe recording worked as stored, but that does not establish automatic batch-calculator ownership/yield ingestion. G3/profile-requires was unbuilt at the October 24 audit; present full contract/export-button coverage remains UNKNOWN pending audit. Beta must never seed live; separation implementation UNKNOWN. Attune relevance and the old bare-backup decision are settled; do not reopen them without Sirc.

### Additional dated product/policy items

Source attribution is in **History (before Nov 2026)**; these are only the additions absent from Muse, not a competing authority.
- July 26, 2026: **“dont break down in days just phases”**. Replacement reporting classifies each addon as **replaced / partial / not replaced**, with a reason, not a made-up score: **“I need to see whats replaced and what is not and what is partial. and I need to know what the reasoning it cannot be replaced”**.
- July 31, 2026: **“I dont want block i want a modern ux look like wow does and i want the layout how they do”**. Class themes, a Blizzard theme and a ToonAge theme pack; level-gated panels must not misinform. Later October 4–5 glass rules govern this direction; no reskin or implementation is implied.
- July 31 talent-tree goal: build/test an interactive tree in game and see +/- DPS or stat-weight effects. **Paraphrase only: the exact requested verbatim quote was not supplied in this handoff (UNKNOWN).** Do not fabricate it. G13 must establish a valid model before numeric deltas; G16 covers the route/planner, preserving art and real prerequisites.
- Verify-first rule: **“I won't design against a guess.”** Transparent mode is also an imported item; exact behavior, settings and current implementation are UNKNOWN from the supplied handoff. Later glass/readability rules still govern.
- Gathering Radar: current implementation UNKNOWN. A current `test` filename audit found `Core/MinimapButton.lua` and GatherTracker modules, but no Radar-named path; that does not prove absence. All requested behaviors remain **UNVERIFIED**, gated on safe button/copy-window checks: blips at `Minimap:SetAlpha(0.15)`; Plan B ghosted terrain around 0.2; originals + active flag in SavedVariables and restoration surviving Reload UI; click-through including MinimapCluster children; MinimapButton scaling. No typed probes.
- July 26 separate Markdown policy documents: license rules, privacy, support and related topics; the complete four-document naming/scope is UNKNOWN. **Current `test` tree and file check, November 9:** `LICENSE.md` and `.rules.md` exist; the full non-truncated Markdown filename inventory has no separately named privacy/support document. Content under other documents and compliance with the requested split remain UNKNOWN. Do not treat filenames as proof of complete policy coverage.
- Requested policy copy, not verified behavior: **“Use this addon at your own risk.”** **“Do not use it to automate gameplay or to collect other players' personal data.”** **“Saved variables are stored locally.”** **“Optional telemetry is opt-in only.”** Check actual behavior/defaults and legal wording before claiming compliance; Sirc approves any policy change. Fresh `LICENSE.md` uses author **Sirc**, not the conflicting all-caps import.


## 2 CURRENT CODEBASE & STRUCTURE

Clients, TOCs, module layout, the dual-gate rule, install boundaries, existing test/syntax/package commands and the missing-API audit are in [architecture.md](architecture.md).

**Audit baseline:** `4555883f13a34f911628ea5946c7e5c316e1ae3e`. **Latest reported installed merge:** `c9c5308a`; source/docs tree read on `test` in the prior documentation pass. Runtime ZIPs omit `.git`, `.github`, `Tools` and `Docs`: they are not development checkouts or the approved Forever install method.

## 3 COMPLETED WORK AND CURRENT DELIVERY

| Work | Prepared / merged / installed evidence | In-game boundary |
|---|---|---|
| PR58 reputation | In baseline/test, merge `d1d270e2fa…`; prior 102 faction + 19 engine-gate checks; installed per earlier byte audit. | Native within-standing/header comparison still pending. Visible rows only, no header mutation; 200-row cap/partial reporting; negative/NaN wording was a nonblocking concern. |
| PR59 profession dedup | In baseline/test, merge `74f54bdc72…`; 100 checks reported, installed. | Vespera single rows appear to hold, not all-toon certification. Drop child only if displayed parent AND name/rank/max match. Keep roots 393/197/185; matching children 2947/2945/2948 are examples. |
| PR61 manual calculator | Baseline/test `4555883`; prior math/UI checks 93/52; files installed, Camelot-only wiring. | Controls/result/persistence UNKNOWN. Manual prices, quantities, vendor/deposit/time inputs produce conditional estimate, not realized profit; no ownership/recipe/bank/AH ingestion or crafting/trading. |
| PR62 Mage | Riley reports merged `test` **c9c5308a**, installed Jarvis Forever **November 9, 8:21 PM PST**; CI 42754488472 green; 425/425 hashes match, no deletes, SavedVariables identical. | **Stage 4 / 8/10 delivery index; NOT live-validated.** Local package audited, PC/runtime/method not independently checked. |

PR62 reviewed head `ea90c034`; normal merge, no force-push. Backup reported: `_forever_\Interface\ToonAge-backup-20261109-201958` (425 verified). Local package `/workspace/ToonAge-test-c9c5308.zip`: 425 files, SHA256 `ced4d25fa46488415347efcae5620d587e263e409180885a6942d24cdbe3cb9c`. Relative to the 424-file baseline: MageGuidance added; RotationLists, Rotation and Camelot TOC changed; no files removed. The package is evidence, not a Forever install instruction.
Riley-reported Sirc message in Riley’s chat at **8:09 PM PST**: **“Merge PR #62 into test once the final copy commit passes review and CI, then install on Jarvis with a backup and settings preserved.”** Conductor has not seen it directly. The final independent-review verdict was not included in the delivery handoff: UNKNOWN; do not invent a GO or keep an already-reported merge waiting.

### PR62 review/content record — attributed, not rerun here

- Lineage: f126e768 → recovered 064314 b 4 → 9a8f9b7a → 2f797da7 → ea90c034 → reported merge c9c5308a. Earlier prepared/hold states are historical, not current.
- 2f797da7: one follow-up, 84 additions/26 deletions, MageGuidance and its test; CI 42752531358 reported green, 62/62 suites, Mage 154/154, eight TOCs, ZIP 19/19. Glitch exact-head GO, Warden/Gilder GOs, Chronicler fact confirmation.
- ea90c034: copy-only delta, Warden GO carried, Gilder art/copy GO, Glitch GO; Chronicler confirmed facts, not a release GO role. CI 42753560847 passed; Glitch UTC-environment run 62/62, Mage 156/156, ZIP 19/19; syntax parsed 199 files plus MageGuidance. 12,288 selection comparisons matched earlier heads; 28 rank cases include nil/unknown. Static only.
- Rank-hint gate is **lower-bound only**, not a bounded two-level window; PR description reportedly matches. Nonblocking `MageGuidance.lua:535–536` comment still needs lower-bound wording. Earlier `:581` copy target was “no verified live timing number”; all five copy fixes reported present. Do not retain fixed copy as a blocker without new evidence.
- `Conditional tips` label consistency was previously unconfirmed; Gilder now gives copy GO, but exhaustive location audit is not separately itemized. Next: Vespera Spells screenshot for length/labels after safe preflight and Reload UI button; no screenshot/pass claimed yet.
- Periods/spell 145 fixed; Missiles says “page lists Missiles without a Missile Barrage condition”; wand says “finish with the wand instead of spending mana,” with page-stated no-pushback rationale; Frostbolt qualified post-core-talents. Wowhead lines are page-stated, Chronicler-confirmed, not unverified quotes; actual 70862 behavior is separate. Only two guides readable, spell/class pages 403.
- Curse table 20/rank-list 18 conflict remains. Official October 15 beta stationary/Shoot text is UNVERIFIED live and not a timing gate. Remove disproven extra-spell-damage wand scaling and Frost Blast from current-target guidance; do not import stale Improved Fire Blast wording. Reference: https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696.

### Earlier source work retained in baseline — not broad live certification

| Reference | Source-level work / boundary |
|---|---|
| PR42 `b652f246c0…` | Item wrappers, removed globals, spell-return normalization; not universal API certification. |
| PR37 `81a0387185…` | Theme tokens; historical commit said not yet consumed, not a completed reskin. |
| PR35 `196b4e7fbd…` | Sidebar identity helpers; not character planning. |
| `0e006750f1…` | Talent layout from coordinates; preserve geometry/art. |
| `8c93d020eb…`, `6f99e7f717…`, `5a6573e83d…` | On-demand harvest/trainer/catalog text work; catalog is not class ownership. |
| `0bb023e363…` | Data/package presence checks, not runtime proof. |
| `f293acf51d…`, `ec3bb90abc…` | Gilder glyph/chevron assets, preserve artwork. |
| `32b265a18a…`, `30d7abf12f…` | Legacy rotation plumbing, not reliable guidance. |

## 4 PENDING TASKS & ROADMAP

### Live fix list — November 9, 2026, 7:36 PM PST export

Vespera level 15 Mage, Forever 70862/interface 16001: **89 pass, 0 fail, 32 warn, 1 skip**; correct flavor/TOC, ten rendered tabs, empty error log for that run. Not post-PR62 acceptance or all-feature certification.
1. **Training P0:** actual 3,018-row catalog + 29 current spells reproduce false Attack Rank 1@10 offline: player 6603 collides by name with unrelated 3606/22048. Require positive class/spell/rank provenance, not blacklist or deletion of accurate raw catalog data. Keep valid due-rank controls and distinguish observed trainer availability from sourced hints.
2. **REGRESSION:** Muse October 3/beta 70205 reported 0.0 discarded frames/all eight tabs; current 70862 has Talents 112/Professions 14 per rerender. Root cause/workload equivalence UNKNOWN. PR60 and separate profession pooling need review; no pooling fix installed. Preserve art, input focus/text and distinct roots.
3. **ApiGuard:** 93/110 present, 17 absent; audit of 60 loaded Lua files/20 direct sites plus helpers found **no unguarded call for those 17**. Ten wrapper smoke cases pass. This does not certify semantics or all clients.
4. **Swapped labels:** `Core/ApiGuard.lua:124–125` mixes GetBuildInfo return 4/interface and return 1/version. Proposed readable build 1.60.1.70862/interface 16001, not implemented. Split PR56 label/probe/readable-zero work; native UnitDefenseSkill 71, 0 and UnitWeaponAttackPower 83, 7, 0 already observed, hit modifiers 0 versus unreadable n/a are distinct.
5. **Rotation lookup:** 12 warnings concern four IDs: Mutilate 1310707 and Blessing of Light 19977–19979. Cache misses are not removal proof. Baseline “0 guides resident” was generic-stack state, not a dedicated MageGuidance loading test; PR62 is now reported installed.
6. **Data corrections:** Touch of the Grave 1260201 tooltip 30%, not old 10%; item 3382 Elixirs/subclass 2, not Potions/subclass 1. Matching fields/history retained; no source import performed.
7. **Professions:** Comprehension 3012 native 14/75, minLevel 6; Comprehend Scroll 1296017 known. Wrong-domain trade-skill 0/0 must not override native state. Dedup appears to hold narrowly; calculator widgets/math/persistence remain untested.
8. **Acquisition/traits:** Study 1302508 known, nominal 6, first-seen 13 is not unlock; Research Access 97286 turn-in recorded. Curse 475 researched 18 versus table 20 is not settled by level 15 absence; Decimation needs Warlock evidence. 53 Mage mappings/18 conditions observed; Accelerant definition 11069 is bound, not automatically a cast/aura ID or universal level unlock.

### Missing-API audit

The 17 manifest absences, pinned call sites, guarded results and the live 93/110 ApiGuard summary are in [architecture.md](architecture.md). **No unguarded loaded call found** for those 17. Guards do not certify arguments/returns or other clients.

**Open PRs, as last read:** PR57 Health/Mana head `ba776cec41f1ba0d55110c6d03d2bb88bfee0f3e`, unmerged: guards/wording, not numeric dashes fixed; canaccessvalue live behavior UNKNOWN. PR60 pooling head `1b251c23c880b7254667dbaeade57b58828d10c7`, unmerged, reported 223 tests; re-review current head. Preserve secrecy and art; a secure native display does not authorize addon numeric access.
Legacy Forever static approximate beta 70245 lists remain UNVERIFIED outside the installed Mage slice; redraw is not learned-state adaptation. Learned-recipe ingestion, bank/AH capture (no AH recorder), talent routes, full gear what-next scoring and planning narrative are unbuilt.

### Five product phases — not days

| Phase | Exit criteria / Sirc’s gate |
|---|---|
| 1 Reliable Mage + Training | Accept installed exact Mage build; provenance fix preserves real ranks, no false Attack; calculator controls and wand evidence checked. New scopes approved separately. |
| 2 Class leveling guides | One sourced class/spec/role/band at a time through 60; learned/unlearned/rank/equipment negatives and cross-class regression; unavailable characters NOT TESTED. |
| 3 Roles/specs/routes | Capability-aware tank/healer/melee/ranged lessons and chosen-role routes; actual points/conditions/Legacy, no rigid labels or forced spend; Talents art preserved. |
| 4 Per-toon planning | What next/why/how joins readable gear/stats, learned skills, professions/reputation/goals; no invented weights, ownership, yields or profit. |
| 5 Endgame/PvP | Separate 50–60, level 60 activities and PvP lessons; current effects/DR/cost/cap evidence. “60+” is journey, not invented levels 61+. Sirc chooses objectives. |

### AGILE/KANBAN EXECUTION PLAN — Sirc’s team / Sirc146/ToonAge / test

Plan with Conductor and record it here before work. Only small, approved feature-branch commits/PRs to `test`; no large chunks or unrelated rewrites. No calendar-day breakdown. These commit messages are proposals, not performed commits; recording game results does not itself require a code change or reinstall.
**Before every individual game check:** Sirc performs the explained SavedVariables backup, checks harvest counts and installed=agreed-trunk/client/version, then uses addon buttons/copyable windows. Trunk mapping is UNKNOWN until Sirc confirms it. Missing button is blocked; no typed probes. Launch requires 0 fails, every warning triaged, clean Error Log after real play.

| Kanban column | Entry/exit | WIP suggestion |
|---|---|---:|
| Backlog | Named gap, evidence, owner/dependency; no work implied. | Uncapped |
| Ready | Reproduced or specified, sources and acceptance named, Sirc scope approval. | 3 |
| In Progress | One bounded behavior, fresh failing regression where appropriate. | 1 |
| Review | Exact head/diff, green checks, Glitch + Warden; Gilder for visuals, Chronicler for facts. | 1 |
| Test (in-game) | Approved exact artifact, backup/rollback, wait for Sirc. PR62 currently here after preflight. | 1 |
| Done | Applicable offline/review gates and Sirc’s recorded scenario acceptance, or accepted research deliverable. | — |

**Prioritized mitigation roadmap:** (1) G01 accept the already-installed Mage guide; (2) G03 remove false Training advice; (3) G02 repair diagnostic labels; (4) G04/G05 investigate frame regressions; (5) G06 bounded mechanics/calculator/wand checks. G07 source triage can progress separately without enlarging a code PR. Then G08/G09 actual Warrior/Hunter context, G10–G12 class/role/band curricula, G13 verified stats, G14/G15 playstyle/advisory slices, G16 routes/hub and G17–G24 scoped economy/progression/API/QA/imported audits. Respect dependencies, not a single giant sequential feature drop.
**Why task 3 is labels:** G02 is P0/quick win in the gap plan; G04/G05 are P1/stability. Training stays ahead for trust. Frame regressions follow next; they are not forgotten or declared harmless.

#### First task 1 — Spells acceptance of installed c9c5308a (G01)

Owners: Sirc tests; Conductor records; Glitch/Warden evaluate; Gilder checks Spells length/labels; Riley only if a new scoped fix is needed. Do not reinstall an older candidate or mix a comment change into this baseline measurement.
| Bite-sized proposed commit | Definition of Done |
|---|---|
| `docs(guidance): define installed Mage acceptance checks` | Record unchanged c9c5308a provenance, backup/freshness preflight and button-only scenarios: Reload UI → Spells; Module Health/Error Log copy windows; learned/unlearned/rank redraw, none→Fire/explicit selections, available wand states. Missing tools NOT TESTED; no respec/purchase. |
| `docs(guidance): record c9c5308a live acceptance` | After Sirc actually checks it, record dated pass/fail/NOT TESTED, exact build, screenshot for Gilder, clean/dirty real-play log and warning dispositions. Stage 5 only for passed exact scenarios; failures open a tiny follow-up. Not completed merely by writing this plan. |

The nonblocking rank-hint comment follow-up remains G01; do not hold or silently replace the installed bytes for it.

#### First task 2 — Attack Rank 1@10 provenance (G03)

Owners: Riley implementation, Chronicler identity evidence, Glitch/Warden independent QA, Sirc game acceptance. Preserve the populated catalog and real rank controls; never blacklist the Attack name.
| Bite-sized proposed commit | Definition of Done |
|---|---|
| `test(training): reproduce Attack rank provenance collision` | Nonpersonal fixture joins player 6603 and foreign 3606/22048 to reproduce the false row; include genuine due-rank, unknown provenance and per-toon isolation controls. Fails for the intended bug, not a broken fixture. |
| `fix(training): require spell and class provenance` | Collision test green; unknown/foreign catalog rows cannot extend player chains by name; legitimate class ranks remain. Narrow cache/schema changes only if needed. |
| `fix(training): distinguish rank hints from trainer evidence` | UI/tests distinguish sourced expected ranks, future/unknown coverage and observed trainer availability; never call catalog guesses train-now proof. |
| `docs(training): record reviewed and in-game regression results` | Final-head relevant tests/TOCs/package and Glitch/Warden review pass; Sirc approves any install, then same-data button/native-trainer comparison has no false Attack and preserves a legitimate due rank. No catalog reset or forced purchase. |

#### First task 3 — ApiGuard build/interface labels (G02)

Owners: Riley, Glitch/Warden, Gilder diagnostic copy, Sirc native comparison. Separate labels from PR56 probes and PR57 numeric-vitals access.
| Bite-sized proposed commit | Definition of Done |
|---|---|
| `test(diagnostics): reproduce swapped build and interface labels` | Synthetic GetBuildInfo fixture catches reversed version/build/interface and unknown-field handling. No client probe or new API dependency. |
| `fix(diagnostics): correct build and interface labels` | Fixture green; readable client version/build and interface 16001 are not swapped; no unrelated probe, flavor or layout changes. |
| `docs(diagnostics): record client label acceptance` | Exact-head tests/review pass; after Sirc-approved deployment and each-case preflight, button-opened Module Health output matches native build/interface, clean error log, warning disposition recorded. |

**Prompt for validation — addressed to the team bots:**
> Conductor, Riley, Glitch, Warden, Gilder and Chronicler: read `AGENTS.md`, `docs/HANDOVER.md` and `docs/HISTORY.md` from the repo before work and validate this phase/Kanban plan against Sirc146/ToonAge on `test`. Confirm the current head, exact c9c5308a installation provenance, trunk mapping, real TOCs/Profile gates, existing tests and open PR57/60. Diagnose freshness, version, cross-client differences, button-opened health/errors and Git history before code. Preserve Sirc’s settled choices, art, data and learned/equipment gates. Validate the three first tasks and each tiny commit’s DoD; list assumptions, UNKNOWNs, source/build conflicts and missing dependencies. Official sources first. Do not invent a weight, timing, full SHA or live pass. Ask Sirc concrete questions through Conductor. Wait for applicable approval before PR/merge/install/release; do not contact another bot just because this plan names it. Record your dated part afterward as a commit. After each verified test and its working it's pushed up. Return only the next reviewable green slice and Sirc’s button/copy-window acceptance steps; no large code drop.

### Gap closure plan — all G01–G24 retained

All cards inherit the standing backup/freshness/button/launch gates and Sirc approval; repeating them per row is unnecessary. D=existing delivered scope, P=prepared fix/research; /10 indexes are stage×2, not quality. Other than G01 and baseline PR58/59/61, no new fix here is claimed merged/installed. UNKNOWN implementation is not silently scored as proven absence.

#### G01 — PR62 installed: verify freshness/method and live acceptance
**Owners:** Riley engineering/deployment; Glitch + Warden QA; Gilder art/copy; Chronicler facts; independent reviewer final gate. **Priority:** P0 / release gate. **D:** 4 Mage guide now reported installed; live validation UNKNOWN (8/10). **P:** 4 reviewed artifact now reported merged/installed, not merely prepared (8/10).
**Approach:** Reported merge/install complete at 8:21 PM PST: c9c5308a, CI 42754488472, Jarvis 425/425 hashes, no deletes, backup/settings preserved. Local 425-file package checked. Confirm Forever build_flavors -Install method (UNKNOWN) and agreed-trunk freshness before measuring; then live acceptance via buttons. Lower-bound comment 535–536 remains nonblocking. **Depends on:** Current PC install/method/branch equality and final independent-review verdict are not independently observed here. Riley-reported approval/reviews retained; do not keep a completed merge waiting in this plan. Per-test backup and zero-fail/triaged-warning/clean-real-play-log gates apply.
- **C 1** `docs(guidance): align rank-hint comment with lower-bound gate` — **DoD:** Optional tiny comment-only commit makes 535–536 accurate; if created, re-run syntax/relevant tests and obtain exact-head delta review. No logic change and no requirement to delay a permitted release for this nonblocking nit.
- **C 2** `docs(release): record approved Mage artifact and acceptance` — **DoD:** Record reviewed full SHA, CI, artifact hash, merge SHA, backup/target/settings/rollback and separate install result only after those actions actually occur; no invented full SHA or advance-to-Done from this plan.
**Current execution:** First task 1 is live acceptance of unchanged installed bytes; the comment-only C1 is independent/nonblocking.
**Sirc:** Confirm trunk mapping/install method; perform own explained backup before each check; use Reload UI, Spells, Module Health/Error Log buttons and copyable windows. Send Vespera Spells screenshot to Gilder for length/labels; test learned/rank/selector behavior without respec. Do not report live pass from installed hashes.

#### G02 — ApiGuard swapped build/interface labels
**Owners:** Riley; Glitch + Warden QA; Gilder diagnostic copy. **Priority:** P0 / quick win. **D:** 4 installed label bug (8/10). **P:** 2 fix approach specified; no implementation claimed (4/10).
**Approach:** Isolate Core/ApiGuard.lua label repair from PR56 probe changes. Read GetBuildInfo tuple correctly; show version/build/interface without reversing labels. Keep missing-capability reporting honest. **Depends on:** Pinned 124–125 and live 1.60.1.70862/interface 16001 evidence; no need to obtain the 17 missing optional legacy APIs.
- **C 1** `test(diagnostics): reproduce swapped build and interface labels` — **DoD:** Synthetic GetBuildInfo fixture catches swapped labels, including unknown fields, without requiring a game session.
- **C 2** `fix(diagnostics): correct build and interface labels` — **DoD:** Fixture green; output distinguishes client version/build from interface 16001; no unrelated API/probe changes.
- **C3** `docs(diagnostics): record client label acceptance` — **DoD:** Follow First task 3: exact-head review/tests and Sirc’s backed-up button-window/native comparison; actual results and warning dispositions only.
**Sirc:** Approve a tiny independent fix/install; compare diagnostic text to native client after approved deployment.

#### G03 — Training Attack Rank 1@10 false positive
**Owners:** Riley; Glitch + Warden QA; Chronicler provenance. **Priority:** P0 / trust. **D:** 4 installed bug (8/10). **P:** 2 fix specified/reproduced; no fix code claimed (4/10).
**Approach:** Require positive spell/class/rank provenance before extending a player rank chain. Player 6603 must not join 3606/22048 by Attack name alone. Unknown provenance stays unknown; do not delete valid raw catalog identities or blacklist the name. Distinguish sourced expected ranks from observed trainer availability. **Depends on:** Existing live-input reproduction; training.csv 72 unresolved; class/skill/trainer evidence. Keep legitimate Arcane Intellect/Fire Blast/Frostbolt positive controls and cross-toon isolation.
- **C 1** `test(training): reproduce Attack rank provenance collision` — **DoD:** Synthetic nonpersonal fixture reproduces false row and includes legitimate-rank/unknown-provenance/per-toon controls.
- **C 2** `fix(training): require spell and class provenance` — **DoD:** False row gone in harness, legitimate controls remain; unobserved trainer availability not claimed.
- **C3** `fix(training): distinguish rank hints from trainer evidence` — **DoD:** Follow First task 2: UI/tests distinguish expected ranks and unknown future coverage from observed trainer availability; never label a guess train-now proof.
- **C 3** `docs(training): record independent review and live acceptance` — **DoD:** Relevant suites/TOCs/review pass; record exact candidate and actual same-data in-game outcome, including a legitimate due rank.
**Sirc:** Approve separate scope/install; compare same populated catalog before/after and native trainer at a normal visit. No catalog reset or forced spell purchase.

#### G04 — Talents 112-frame rerender churn
**Owners:** Riley PR60; Glitch + Warden QA; Gilder art/layout. **Priority:** P1 / stability. **D:** 4 installed 112-frame churn (8/10). **P:** 3 PR60 prepared, unmerged; fresh review/live test outstanding (6/10).
**Approach:** REGRESSION to investigate: historical Oct 3/70205 reported 0.0 discarded frames/all 8 tabs versus current 70862 Talents 112/Professions 14; root cause/workload comparability UNKNOWN. Re-review unmerged PR60; reuse holders/buttons/glows and clear stale tooltip/hover/selection ownership. Preserve all Talents art, coordinates, textures and tree identity. **Depends on:** PR60 exact current head/review must be rechecked; live 112 discarded per rerender; trait IDs/condition gates are separate from art.
- **C 1** `test(talents): cover repeated render and stale ownership` — **DoD:** Fixture counts creations after warm-up and exercises tree switch/hover/empty state.
- **C 2** `fix(talents): finalize reviewed pooling without art changes` — **DoD:** Bounded frame pool stops per-render growth, handlers/state reset, tests green and art diff accepted by Gilder; adapt existing PR60 rather than duplicate it.
- **C 3** `docs(talents): record pooling and visual acceptance` — **DoD:** Christopher repeats tab/tree changes; no new churn warnings, stale glow or visual drift in supported cases; exact build recorded.
**Sirc:** Approve exact PR60 candidate separately; screenshot before/after and repeat renders at normal sizes. No respec required.

#### G05 — Professions 14-frame rerender churn
**Owners:** Riley; Glitch + Warden QA; Gilder UI. **Priority:** P1 / stability. **D:** 4 installed 14-frame churn (8/10). **P:** 2 narrow approach specified; no prepared code claimed (4/10).
**Approach:** REGRESSION to investigate: historical Oct 3/70205 reported 0.0 discarded frames/all 8 tabs versus current 70862 Talents 112/Professions 14; root cause/workload comparability UNKNOWN. Separate profession-card/input pooling fix from dedup and calculator math. Reuse/reset dynamic frames; retain typed calculator values and focus across ordinary refreshes. **Depends on:** Live 14 discarded per rerender; PR59 dedup appears to hold for Vespera; calculator fixture available. Do not suppress distinct skill roots.
- **C 1** `test(professions): cover rerender frames and input persistence` — **DoD:** Repeated-render, root/child and calculator-input controls isolate churn from dedup.
- **C 2** `fix(professions): reuse cards and preserve inputs` — **DoD:** No steady per-render frame growth; stale children hidden/reset; dedup and input tests green.
- **C 3** `docs(professions): record frame and persistence acceptance` — **DoD:** Actual repeated tab/skill refresh has no churn regression, duplicated/lost rows or lost typed input after approved install.
**Sirc:** Approve separate fix; compare native professions, repeat renders, and test calculator focus/text survival. Report not tested rather than purchasing a profession.

#### G06 — Mage live mechanics, calculator and optional wand DPS
**Owners:** Chronicler evidence; Riley only for later scoped extension; Glitch + Warden QA; Gilder explanations. **Priority:** P1 / short live checks. **D:** 4 existing readouts/calculator files; 0 optional wand-DPS extension (8/10). **P:** 1 mechanic research/extension proposal; live checks outstanding (2/10).
**Approach:** Use the existing in-game checklist: usable wand/Shoot movement versus stationary timing (official beta 0.5 s, not a verified live timing number); Heating Up/Fire Blast effects; Accelerant current tooltip/definition; Missile Barrage learned-state/proc conditions; calculator synthetic 10 g/600 g-per-active-hour result and persistence; native Curse 475 requirement 18 vs 20. Study possession already settled; acquisition prerequisites remain separate. Keep a future optional wand-DPS choice separate from unchanged PR62 finish/conserve text. **Depends on:** Christopher’s actual learned talents/equipment; observed 53 nodes do not prove cast/aura behavior. No fabricated timings, spell-damage scaling, thresholds or talent unlock levels. Calculator TOC/tab rendering already observed, controls still unverified.
- **C 1** `docs(test): define bounded Mage and calculator observations` — **DoD:** Each check has actual available tools, expected research versus unknown live behavior, report fields and safe stopping conditions; missing talent/tool is not tested.
- **C 2** `docs(data): reconcile captured Mage mechanic fields` — **DoD:** Only observed fields get ledger decisions with source/build; unknown acquisition/timing stays unresolved.
- **C 3** `feat(spells): add reviewed optional wand DPS choice` — **DoD:** Future-only after design/evidence/scope approval: known Shoot+usable equipped wand gates, optional what/why text, negative tests, no universal superiority or unverified 0.5 s gate; independent review and separate acceptance.
**Sirc:** During ordinary safe play, capture tooltips/known ranks/gear and effects already available; inspect trainer without buying; run manual calculator fixture. Do not respec/learn talents or expose a group to danger just to test.

#### G07 — Triage 3,329 unresolved claims and research drift
**Owners:** Chronicler primary; Glitch + Warden ledger QA; Riley only for later approved imports. **Priority:** P1 / data foundation. **D:** 0 complete verified dataset in addon; scoped ledgers exist locally (0/10). **P:** 1 remaining research; existing prepared ledger evidence retained; no addon import (2/10).
**Approach:** Work by live impact, not raw row count: Mage → Warrior tank/DPS → Troll Hunter → other roles; then profession/economy bundles. Separate verified constituent fields from unresolved whole priority/recipe bundles. Reconcile revision 4 shared-file drift explicitly without overwriting the frozen original inventory. Keep verified ours/use better sourced/add/remove proven inaccurate/unresolved; never remove for absence. **Depends on:** 19 CSV ledgers/counts.json, live 70862 export, source/build/date and exact identity joins; eight changed shared research files and two honest integrity failures. Official Blizzard first, then Wowhead/Icy Veins/warcraft.wiki.gg/Forever-specific sources; hotfix-effective dates matter.
- **C 1** `docs(data): prioritize unresolved claims and reconcile research revisions` — **DoD:** Inventory all 3,329 IDs by area/impact, record old/new hashes and a reviewed reconciliation, without marking unknowns solved.
- **C 2** `docs(data): adjudicate one sourced field batch` — **DoD:** Small class/band or recipe-field batch includes source URL/version and explicit conflict decision; no aggregate whole-bundle verification from one matched ID.
- **C 3** `test(data): verify ledger counts and provenance after each batch` — **DoD:** Counts reconcile, allowed decisions/IDs/source paths are consistent; changed-source failures are resolved by documented reconciliation, never disabled/rebaselined silently.
**Sirc:** Decide true preference conflicts, first professions and acceptable untested scope. Supply only missing live evidence; no need to repeat already-settled Vespera scans.

#### G08 — Warrior tank AND melee-DPS capture and guidance
**Owners:** Chronicler role data; Riley guides; Glitch + Warden QA; Gilder role copy. **Priority:** P1 / next toon. **D:** 0 reliable role guidance (0/10). **P:** 1 original Fury + conditional role research; no Warrior live capture here (2/10).
**Approach:** Treat tank and melee DPS as separate chosen contexts on the same toon. Capture current level/race, book/ranks, talents/Legacy, stance, shield/weapon and ordinary encounter context; source threat/mitigation/taunt/facing/Rage reserve separately from damage/interrupt/positioning. Nominal roles are not rigid limits: source/observe actual threat/mitigation/support capability; Mage/Hunter tanking are product examples, not certified current roles. **Depends on:** Christopher’s actual Warrior capture; do not infer role from spec label, damage counts or shield alone. Source candidate Fury/Protection packets are not curricula or live certification.
- **C 1** `docs(warrior): capture role and tool evidence` — **DoD:** Two context records clearly separate observed learned tools from unavailable/untested ones; no raw personal save in a public PR.
- **C 2** `test(warrior): cover tank and DPS learned-state gates` — **DoD:** Fixture checks shield/stance/weapon/talent conditions and role choice, including missing tools.
- **C 3** `feat(warrior): add one explained role-band slice` — **DoD:** One reviewed band/context only; tank threat/mitigation is not a relabeled damage priority; actual optional advice matches evidence.
**Sirc:** Confirm Warrior’s level and intended tank/DPS contexts; capture each during normal play, no respec, forced dangerous pull or group experiment. Approve each small role-band release.

#### G09 — Troll Hunter capture and selected-spec guidance
**Owners:** Chronicler; Riley; Glitch + Warden QA; Gilder. **Priority:** P1 / next toon. **D:** 0 reliable Hunter guide (0/10). **P:** 1 BM original research + conditional other-spec packets; not live verified (2/10).
**Approach:** Ask intended Hunter spec/playstyle; capture current level, ranged weapon/ammo if relevant, pet/talents/known spells and Troll racial tooltip. Validate learned range/positioning, pet threat, shot pacing, traps and Berserking rather than assuming Mage/wand behavior. Nominal roles are not rigid limits: source/observe actual threat/mitigation/support capability; Mage/Hunter tanking are product examples, not certified current roles. **Depends on:** Hunter spec remains unknown; official shot/trap notes and conditional spec packets need live-context confirmation. Do not silently assign BM or assume Survival branch.
- **C 1** `docs(hunter): record chosen context and native evidence` — **DoD:** Spec/level/pet/weapon/racial states recorded, uncertain fields labeled; actual Hunter captures not copied from Mage.
- **C 2** `test(hunter): cover ranged pet and learned-tool gates` — **DoD:** Positive and missing-pet/weapon/talent cases, per-toon isolation and movement advice source qualification pass.
- **C 3** `feat(hunter): add one sourced selected-spec band` — **DoD:** Only learned usable tools suggested; pacing/pet/mob context explained and opt-outs preserved; no unsupported dead-zone number.
**Sirc:** Choose intended spec or keep it undecided explicitly; provide Troll Hunter scans/tooltips and ordinary movement/pet observations. Approve one band at a time.

#### G10 — Mage remaining bands and the other eight classes 1–60
**Owners:** Chronicler data; Riley one slice per PR; Glitch + Warden regression; Gilder copy. **Priority:** P2 / class rollout. **D:** 0 reliable complete 1–60 guide across classes (0/10). **P:** 1 original draft/conditional research; Mage 10–19 guide is now stage 4; the remaining corpus is research (2/10).
**Approach:** Do not repeat Riley’s Mage 10–19 comparison. Reconcile Mage 1–9/20–49, then remaining Warrior/Hunter bands, Druid first usable tactical rules, Priest/Warlock/Rogue/Paladin/Shaman. Maintain nine-class ×27-spec ×role ×band register; split 20–29/30–39 only by actual per-rule conditions, not copied pooled counts. Recheck Paladin rework and Warlock 70753 source mismatch. **Depends on:** G03 provenance, G07 source reconciliation, G08/G09 toon evidence. Original Druid 0/10 active; research decisions/conditional packets do not activate runtime rules.
- **C 1** `docs(guidance): source one missing class band` — **DoD:** One bounded spec/role/band has URLs/build, ranked identities, acquisition/conditions and explained alternatives; unknowns explicit.
- **C 2** `test(guidance): cover that band and cross-class isolation` — **DoD:** Learned/unlearned/rank-change/level-edge/equipment/talent and all-class nonactivation cases pass.
- **C 3** `feat(guidance): deliver one reviewed class-band slice` — **DoD:** Small data+integration PR only after approval; TOC/regression/package green; game acceptance only for actually tested characters.
**Sirc:** Approve class order after Warrior/Hunter; identify playable classes for testing. Unavailable characters/specs remain not tested, not stage 5.

#### G11 — Alternate specs, tanks and healer curricula
**Owners:** Chronicler; Riley; Glitch + Warden QA; Gilder role explanations. **Priority:** P2 / role rollout. **D:** 0 reliable alternate-role curricula (0/10). **P:** 1 source-context packets; no complete course prepared (2/10).
**Approach:** Extend remaining specs with separate contexts: Warrior/Paladin Protection and Druid Bear threat/mitigation; Holy/Discipline Priest, Holy Paladin, Restoration Druid/Shaman triage/mana/cast protection/dispels. Distinguish Cat/Bear and conditional Survival branches. Do not invent HPM ratios, safe-HP cutoffs, threat telemetry or restricted combat reads. Nominal roles are not rigid limits: source/observe actual threat/mitigation/support capability; Mage/Hunter tanking are product examples, not certified current roles. **Depends on:** G10 band infrastructure, actual talent/gear gates, role choice and accessible APIs. Healer/tank source-context packets exist but lower-band/rank curricula and live validation do not.
- **C 1** `docs(roles): specify one role-spec-band lesson` — **DoD:** What/why/alternatives, tool prerequisites and restricted/unavailable signals documented separately from DPS priorities.
- **C 2** `test(roles): enforce learned context and unavailable states` — **DoD:** Nil/secret/missing-equipment and wrong-role fixtures pass; no unavailable triage API assumed.
- **C 3** `feat(roles): add one bounded tank or healer lesson` — **DoD:** Reviewed optional lesson only; preserve existing damage branch and explicit role switch; live evidence scope recorded.
**Sirc:** Say which healer/tank characters are available; test only ordinary supported encounters. Never withhold healing or manufacture danger for a test.

#### G12 — Levels 50–60, 60+ journey and PvP
**Owners:** Chronicler; Riley; Glitch + Warden; Gilder. **Priority:** P2 / curriculum gaps. **D:** 0 complete 50–60/endgame/PvP curricula (0/10). **P:** 1 conditional 27 late/endgame+28 PvP packets; not full guidance (2/10).
**Approach:** Turn 27 conditional late/endgame spec packets and 28 PvP contexts into separate researched lessons. 50–60 rank/talent transitions, level 60 dungeons/raids/professions, and PvP positioning/control/peel/dispels/resources need different criteria. 60+ means endgame journey, not invented levels 61+. Source PvP costs/caps/DR/effects explicitly. **Depends on:** G10/G11 role branches and live accessible tools; current activity/season sources. No blanket tier ranking or universal rotation from one context paragraph.
- **C 1** `docs(curriculum): specify one late-level or activity lesson` — **DoD:** Exact class/spec/role/band or level 60 activity and source/effective version attached; no numeric-cap invention.
- **C 2** `test(curriculum): cover context and unlock boundaries` — **DoD:** Learning/talent/gear plus PvE/PvP separation; PvE taunt/threat rules not assumed to control human players.
- **C 3** `feat(curriculum): add one reviewed endgame or PvP lesson` — **DoD:** Small independently reviewed slice with opt-out and source labels; only tested scenarios accepted.
**Sirc:** Choose first endgame activity and PvP mode/role; capture existing season/vendor facts without buying or queueing just for tests. Approve separate lessons.

#### G13 — Forever stat priorities and weights
**Owners:** Chronicler research; Glitch + Warden fact QA; Riley only after design; Gilder readable uncertainty. **Priority:** P2 / research prerequisite. **D:** 0 verified Forever weighting feature (0/10). **P:** 0 verified weighting model; research requested, not fabricated (0/10).
**Approach:** Research official Blizzard first, then Wowhead/Icy Veins and supporting API/Forever sources. Record class/spec/role, build/hotfix, level/gear/weapon/context, definition, units and limits. Qualitative priorities are not numeric weights. If reliable weights are unavailable, say so; do not invent weights or import Retail values. Static BiS must never be truth; only verified dynamic/imported weights or explicitly labeled heuristic (never fabricated numeric weights). **Depends on:** Readable accessible stats and exact school-specific/item effects; source gaps may block weighted gear-lean/scoring, not the factual readout or cast-based design.
- **C 1** `docs(stats): inventory build-qualified stat sources` — **DoD:** One selected context has explicit source/weight availability, contradictions and applicability; absent official numbers stay absent.
- **C 2** `docs(stats): specify bounded priorities and unknowns` — **DoD:** Keep sourced qualitative order distinct from verified numeric model; no unsupported thresholds, percentages or universal normalization.
- **C 3** `test(stats): validate model provenance and missing-data handling` — **DoD:** Only if a model is approved: fixtures reject unsupported class/context/units and unreadable inputs before any weighted feature is implemented.
**Sirc:** Pick first toon/spec/role/context to research; accept qualitative-only or unknown output if sources cannot justify numeric weights.

#### G14 — Cast-based + gear-lean playstyle readout
**Owners:** Riley observation/design; Chronicler verified signatures/weights; Glitch + Warden QA; Gilder advisory copy/art. **Priority:** P2 / product specification. **D:** 0 playstyle inference/gear-lean feature (0/10). **P:** 1 requested, not specified; gear-weight dependency open (2/10).
**Approach:** Observe actual player casts over time and describe which spec/playstyle the pattern resembles, with reasons and uncertainty, to help the player tune their own style. Separate observed casts from informational equipped-gear lean; they may disagree. Availability/level/encounter/pet/weapon context matters. A suggestion is not a requirement, performance score or automatic spec choice. Selector always wins; none defaults Fire for Vespera. **Depends on:** Existing Casts log is only an input, not long-term classifier proof. Define observation window, minimum evidence, retention/reset, session/context separation and explanation UX before build. Cast-based design can proceed without weights; weighted gear lean waits for G13. Strong-lean thresholds/signatures/algorithm remain unspecified.
- **C 1** `docs(playstyle): specify cast and gear evidence channels` — **DoD:** Christopher approves observation scope/window/privacy/reset and examples of reasons/uncertainty; distinguish frequent available spells from intent; requested feature is not silently treated as a finished spec.
- **C 2** `test(playstyle): cover sparse mixed and contrary signals` — **DoD:** Synthetic Mage/Warrior/Hunter histories, few/no casts, level changes, mixed school/roles, gear change and explicit-selector disagreement never auto-select/respec or invent confidence numbers.
- **C 3** `feat(playstyle): add one bounded advisory readout` — **DoD:** Only after spec/data approval: readable reasoned cast-pattern suggestion; separate gear cue only with verified model; optional/collapsible, no overriding selector; regression and Christopher feedback required.
**Sirc:** Choose acceptable history scope and presentation; evaluate whether reasons describe real play and help tune it. No need to pick a spec now; confirm/reject suggestions freely.

#### G15 — EVERY tab as-you-go advisory suggestions
**Owners:** Riley wiring; Chronicler evidence; Gilder unobtrusive copy/UI; Glitch + Warden QA. **Priority:** P2 / cross-tab product specification. **D:** 0 cross-tab advisory layer; factual tabs 4 (0/10). **P:** 1 requested, not a completed UI specification (2/10).
**Approach:** Each of ten tabs gets relevant optional suggestions from what the toon actually does/equips/knows and observed progress. Give what/why/alternatives to guide someone who does not know yet and help tune their own playstyle; suggestions, not requirements. Easy to collapse/skip; do not replace factual views or automate play. Harvest-first sensor→facts→advice; every tab ends in a next step. Future Now/Pets/SessionCheck targets are separate from the ten visible tabs. **Depends on:** Per-tab relevance matrix below, learned/equipment/provenance/access gates; G13 only for weighted claims, G14 for inferred style. No one giant ten-tab rewrite; no invented default collapsed state.
- **C 1** `docs(advice): specify per-tab evidence and advisory copy` — **DoD:** All ten tabs have a purpose, allowed input, missing-data response and optional what/why example; Christopher reviews tone before coding.
- **C 2** `test(advice): cover one tab context and opt-out` — **DoD:** One tab’s known/unknown/stale/nil/secret and switch-toon cases never produce unavailable actions; ignoring/collapsing advice does not hide facts.
- **C 3** `feat(advice): add one unobtrusive evidence-backed tab slice` — **DoD:** One tab per PR, using shared approved evidence shape; exact-source reasons/opt-out visible; repeat for remaining tabs only after acceptance.
**Sirc:** Approve first tab and tone/placement; confirm suggestions help without becoming requirements, intrusive prompts or a forced spec. Other tabs remain backlog until individually delivered.

#### G16 — Talent routes → gear/stat priorities → character planning hub
**Owners:** Riley; Chronicler route/goal data; Gilder preserve Talents art; Glitch + Warden QA. **Priority:** P3 / routes and hub. **D:** 0 route recommendations/planning hub (0/10). **P:** 1 goals/live correspondence only; no route/hub code prepared (2/10).
**Approach:** Player-chosen role/spec plus confirmed style feeds a changeable reasoned talent route, constrained by actual points/conditions/Legacy. Then connect readable gear/stats, professions/reputation/PvP goals to one attainable next step with what/why/how. Preserve Talents art/geometry and never spend points, respec, equip or navigate automatically. **Depends on:** G10/G11 verified lessons, G13 stats for weighted advice, G14 optional preferences, G15 advice contract; live 53 Mage nodes/18 conditions do not yet supply full route arithmetic. Hub is not a replacement for external BiS tools.
- **C 1** `docs(planning): specify one toon route and next-step contract` — **DoD:** Actual point/prerequisite/Legacy state, role, alternatives and unavailable-data handling documented; user can change direction.
- **C 2** `test(planning): cover route prerequisites and goal dependencies` — **DoD:** Insufficient points/conditions, unfamiliar gear/stat data, per-toon isolation and optional deviating choices pass; no fixed-level unlock shortcuts.
- **C 3** `feat(planning): add one art-preserving route and hub slice` — **DoD:** One spec/role at a time; sourced next step and alternatives, no unsupported score; art review plus applicable in-game tests before acceptance.
**Sirc:** Choose one first goal/role/context; confirm route fits the desired style and can be ignored or changed. Screenshot art before/after; no forced talent spend.

#### G17 — Learned recipes, recipe yields, bank/AH and per-toon economy
**Owners:** Chronicler data; Riley capture/logic; Glitch + Warden QA; Gilder uncertainty copy. **Priority:** P3 / profession/economy branch. **D:** 0 learned-recipe ingestion/bank/AH; manual calculator files 4 (0/10). **P:** 1 research/scaffolding; no capture implementation prepared (2/10).
**Approach:** Keep calculator honestly manual. Verify learned ownership, effective native quantity/min–max/perks and recipe acquisition before automatic costing; resolve 24 missing effect/reagent pairs and 25 null-vs-zero skill semantics separately. Add recipe ingestion, bank then AH observations as separate explicitly approved domains; timestamp/source/ownership required. No AH recorder code currently exists. **Depends on:** G06 calculator interaction, G07 recipe/material triage, actual API guards/schema; 1,367 matched datamined fields do not prove live yields. User must choose professions and capture scope.
- **C 1** `docs(economy): define one profession ownership and yield contract` — **DoD:** Specify IDs, known/unreadable, snapshot age and per-toon Legacy modifiers; unknown yield is never 1/free.
- **C 2** `feat(professions): add one guarded learned-recipe read path` — **DoD:** Future approved tiny implementation with negative/ownership/per-toon tests; native comparison; no bank/AH or crafting mixed in.
- **C 3** `docs(economy): specify separate bank and AH capture cards` — **DoD:** Each future domain has verified API/security/retention/access criteria, timestamped observations and independent tests; no trade/listing/purchase automation or profit certainty.
**Sirc:** Choose first toon/profession; inspect native recipes without crafting/buying. Approve each future capture domain separately; only then supply normal bank/AH observations.

#### G18 — Reputation comparison and profession dedup edge cases
**Owners:** Riley only if reproduced; Chronicler semantics; Glitch + Warden QA; Gilder copy. **Priority:** P3 / progression branch. **D:** 4 PR58/59 merged+installed; dedup appears to hold narrowly (8/10). **P:** 1 remaining semantic/edge-case research; no new fix prepared (2/10).
**Approach:** Preserve PR58 visible-row policy and PR59 distinct roots. Compare native non-Neutral within-standing versus cumulative text, collapsed headers and header-with-rep if present. Verify native versus ToonAge profession duplicates before changing dedup. Do not expand native headers automatically or fabricate rewards/quests-left. **Depends on:** Vespera single-row dedup observed narrowly; reputation.csv 4 unresolved; native header capability and actual recurrence remain unknown.
- **C 1** `test(progression): cover observed representation edge cases` — **DoD:** Use synthetic API fixtures for cumulative bounds/headers and distinct profession roots; do not claim a live header-with-rep exists from a fixture.
- **C 2** `fix(progression): correct only a reproduced semantic mismatch` — **DoD:** If evidence warrants: tiny value/wording fix preserving native panel state and distinct roots; otherwise retain current code and explicit unknown.
- **C 3** `docs(progression): record native comparison and planning boundary` — **DoD:** Christopher reports pass/fail/not-tested; no automatic reward/profession plan until sourced ownership/goals exist.
**Sirc:** Compare native panels during ordinary use; send actual duplicate/mismatched values if any. Approve a fix only if a new reproducible issue exists.

#### G19 — Health/Mana PR57, API semantics and four lookup-ID warnings
**Owners:** Riley; Glitch + Warden API QA; Chronicler identities; Gilder unavailable-state copy. **Priority:** P3 / honest readable stats. **D:** 4 readouts/fallbacks; numeric-vitals limitation unresolved (8/10). **P:** 3 PR57 availability/wording candidate, not numeric fix; other semantic work 1 (6/10).
**Approach:** Separate PR57 access/wording from numeric-vitals goal; never bypass secret/refused values. Retain capability-guarded fallbacks (17 missing names have no unguarded loaded call found), test return semantics and clear unavailable versus zero. Investigate 12 warnings for 4 IDs 1310707/19977/19978/19979 by exact identity/load/cache, not blind replacement. Split PR56 verified probes from G02 labels. **Depends on:** Exact PR57 current review/head; API-GUARD-AUDIT and live probe evidence; missing API/cache result is not a removed-spell proof. No new dependency installation is part of this review.
- **C 1** `test(api): cover readable zero refused values and identity misses` — **DoD:** Mock present/absent/secret APIs and exact-ID fallback paths, preserving all-client flavor isolation.
- **C 2** `fix(api): apply only reviewed capability or identity corrections` — **DoD:** Only proven field/guard/shape fixes; no inferred private number or unexplained spell-ID substitutions; numeric fix remains unknown if unavailable.
- **C 3** `docs(api): record client-specific acceptance limits` — **DoD:** Relevant suites/TOCs pass; Christopher compares accessible native values after separately approved install; not all-client certification.
**Sirc:** Approve PR57/probe changes separately, compare visible values only; report unavailable as unavailable. Supply normal cache/tooltip evidence for missing IDs if accessible.

#### G20 — Offline QA, team evidence archive and reproducibility
**Owners:** Glitch + Warden QA; Chronicler source bundle; Riley packaging; Gilder art inventory; Christopher transfer approver. **Priority:** P3 / portable reproducible handoff. **D:** 0 research transfer; existing baseline tests/reports retained (0/10). **P:** 2 reproducibility/export approach; no transfer performed (4/10).
**Approach:** Retain historical 59/61 archive-run result and UTC-sensitive fixture/Git-metadata prerequisites; do not call all-green. Future authorized code work makes timezone fixture deterministic and runs release tests in legitimate full checkout/CI. Keep a Sirc-approved team evidence archive with research, ledgers, sources and hashes; box-local data is not automatically in the repo. No transfer performed. Imported token-regeneration/paste and Courier-Utility purpose remain Christopher-only UNKNOWNs; never collect tokens. Research export needs separate approval. **Depends on:** G07 drift reconciliation; exact branch/head and tool availability. No installs, clone, repo writes or export performed in this review; no secrets/SavedVariables in a public bundle.
- **C 1** `test(harvest): make timestamp fixture timezone deterministic` — **DoD:** Future approved test-only commit behaves consistently across normal local timezone and UTC without changing harvest semantics.
- **C 2** `docs(qa): record full-checkout CI and packaging evidence` — **DoD:** Run actual existing Tools tests and all TOCs on final head; separate missing .git/archive prerequisite from actual regression; do not weaken checks.
- **C 3** `docs(handover): inventory authorized portable research bundle` — **DoD:** File list/hashes/source licenses/scope reviewed; transfer happens only by explicit approval, with sensitive live files excluded unless separately authorized. Check the four requested policy-document scopes and actual privacy/telemetry behavior; legal changes need Sirc’s decision, not automatic generation.
**Sirc:** Choose approved export destination/scope and first research/test priorities; accept explicit untested classes. No transfer or installation approval is inferred from asking for this plan.

#### G21 — One-ring analyst targets and outstanding product verdicts
**Owners:** Christopher decisions; Chronicler audit; Riley scoped feature; Gilder UX; QA. **Priority:** P3 / imported-context audit. **D:** 0 delivered imported-target completion; current status UNKNOWN (0/10). **P:** 1 imported direction, not verified implementation (2/10).
**Approach:** Audit Now readiness/briefing, Pets care, SessionCheck→Now, consumable-readiness Scrolls and each imported target. Every tab ends in a next step, coexist with specialists. Record faction browser, popular-build source, one-ring verdicts, Weekly Dashboard and ship 8 vs 3 TOCs decisions; do not claim these features exist. **Depends on:** Muse export historical targets and current source/client audit; G15/G16 advice/evidence contract; popular builds must not undermine Harvest-first/player choice.
- **C 1** `docs(direction): reconcile one-ring targets and decisions` — **DoD:** Current feature/state/evidence and build/defer decision listed per target; UNKNOWNs retained, historical paths not invented. Addon verdicts use replaced / partial / not replaced with a reason; phases, not days.
- **C 2** `docs(advisor): specify one approved analyst slice` — **DoD:** One bounded target from sensor→facts→lines→UI→honesty with next step and meaningful client support; no giant replacement PR.
**Sirc:** Choose build/defer and curation sources; confirm one-ring verdicts/ship-set. Review mockups where appropriate; no automatic addon replacement.

#### G22 — Vendor-upgrade notice without purchases/popups
**Owners:** Riley; Chronicler stats/merchant facts; Gilder visual; QA. **Priority:** P3 / imported-context audit. **D:** 0 current verified notice; implementation UNKNOWN (0/10). **P:** 1 historical requested shape (2/10).
**Approach:** Audit current implementation first; requested badge+tooltip line+one vendor-window line, merchant-event refresh, no popups, no autobuy. Dynamic verified gear/context weights or explicitly heuristic; never static BiS truth. **Depends on:** G13 weights/priorities, accessible merchant API guarded per client; current built/live status UNKNOWN despite historical mock/probe reports.
- **C 1** `docs(vendor): audit current notice and specify missing behavior` — **DoD:** Separate existing from absent; exact shape, source/context/unknown model and native merchant fixtures specified.
- **C 2** `test(vendor): cover compare refresh and unavailable inputs` — **DoD:** Future approved fixture includes gear/vendor refresh, nil/secret/item failure, no purchase/popups; one scoped implementation only after approval.
**Sirc:** Confirm notice UX and first client; normal vendor-window buttons/tooltips only, no buying required. Gilder visual acceptance before ship.

#### G23 — Harvest-first capability gate, cross-client consistency and beta/live separation
**Owners:** Chronicler current data/API audit; Riley shared engine; QA; Gilder consistent UX. **Priority:** P3 / imported-context audit. **D:** 4 observed Forever recorder; full doctrine/G3 UNKNOWN (8/10). **P:** 1 imported gaps requiring audit (2/10).
**Approach:** Reconcile historical G 3 unbuilt status with current ModuleAllowed/requires/Caps; raw Harvest observations stay unweighted, advisor separate. Audit per-client export buttons/stamps and beta/live provenance isolation; never seed live from beta. Shared core/per-client probes, not copy-paste or Retail fallback. **Depends on:** Actual current source/TOCs and input schemas; historic docs/paths not sufficient. Build-flavors-only Forever install and agreed trunk/client mapping must be clear.
- **C 1** `docs(harvest): audit per-client capability and provenance gaps` — **DoD:** Current per-client matrix states requirements, buttons, return shapes, build/date/channel stamps and beta/live split UNKNOWNs.
- **C 2** `test(harvest): cover one capability or namespace boundary` — **DoD:** Future approved synthetic fixtures fail closed for unsupported API/wrong flavor/beta-live mix; one narrow fix at a time with baseline counts preserved.
**Sirc:** Decide beta/live retention policy if implementation remains absent; test buttons/copy windows on available clients after backups; missing client NOT TESTED.

#### G24 — Visual/documentation UNKNOWNs and glass constraints
**Owners:** Gilder art/UX; Riley only scoped changes; QA. **Priority:** P3 / imported-context audit. **D:** 0 verified closure of imported UNKNOWNs (0/10). **P:** 1 historical design decisions, not proof applied (2/10).
**Approach:** Audit settled Sirc casing edits, Docs/ placement and Settings 60 px overlap without treating historical UNKNOWN as current bug proof. Glass shell only, solid content, never glass-on-glass/rows/cards or traffic-light window buttons. Drawer quick-use vs native config, Now/talent mockups require actual status audit. **Depends on:** Exact current files/screenshots; preserve Talents art/geometry; Gilder visual GO. No separate reskin project or invented claim earlier fixes landed. Also audit class/Blizzard/ToonAge themes, level-gated panels, transparent-mode specification and Gathering Radar existence; all Radar behavior remains UNVERIFIED until button/copy-window checks. No typed probes or guesses about opacity/restoration/click-through/scaling.
- **C 1** `docs(ui): audit historical casing docs and overlap status` — **DoD:** Actual paths/screenshots and UNKNOWN results recorded; quotes/casing rules preserved verbatim. Include theme/level-gating/transparent-mode and Radar existence/behavior inventory without converting requests into delivered features.
- **C 2** `fix(ui): address one reproduced overlap or copy defect` — **DoD:** Future approved tiny change only, regression/art review; glass restrictions and readable facts preserved. If not reproduced, do not invent a fix.
**Sirc:** Supply current settings/normal-size screenshot if available; confirm Docs/ convention; approve any visual change separately. No traffic-light buttons.

### Every-tab advisory contract — requested, not implemented as a whole

| Tab | Actual input and as-you-go advice to specify | Required honesty/choice boundary |
|---|---|---|
| Character | Readable stats, current role/gear and confirmed goals → one relevant next step with reason. | No unreadable-vitals inference; player chooses priorities. |
| Gear | Equipped items and sourced stat context → explain a tradeoff or missing useful property. | No invented score/weight; gear lean informational, never spec selection. |
| Professions | Actual skills/owned recipes/materials where known → suggest a next learn/craft option and explain cost/benefit. | Until ownership/capture exists, manual inputs/unknowns stay explicit; no auto-craft/trade. |
| Reputation | Actual visible progress and sourced goal → explain relevant next progress option. | Collapsed/native state preserved; no invented rewards/quests-left. |
| Talents | Actual learned nodes, available points/conditions and chosen role → optional reasoned route/alternative. | Preserve art; no spending/respec, level-only unlock or forced build. |
| Spells | Actual learned ranks, cast context and selected spec → optional what/why/alternatives and honest training hints. | Positive provenance; no unlearned tool or unverified timing gate. |
| PvP | Observed mode/progression and learned tools → optional positioning/control/survival lesson. | No assumed DR/caps/matchups; PvE threat is not player control. |
| Scrolls | Known Comprehension/Comprehend Scroll and actually observed scroll requirements → explain an eligible next option. | Do not claim unobserved ownership/eligibility or automatically consume items. |
| Casts | Actual player casts over time and supported context → reasoned playstyle/spec-pattern suggestion. | Sparse/mixed evidence uncertain; never a skill grade or automatic selector change. |
| Harvest | Known evidence coverage/gaps for this toon → optional suggestion for a useful ordinary capture. | No automatic scan/navigation/forced repeated scans; already-settled facts need not be recaptured. |

Actual casts + learned state/equipment/progress → explainable advice → player-confirmed style/role and explicit selector → optional talent route → verified gear/stat priorities → per-toon hub. Professions/economy, reputation/PvP goals feed it; every tab can offer a supported small next step before the full hub exists. Gear/casts never override selection. Now/Pets/SessionCheck targets are in Prior context, not silently added to the ten visible tabs.

### Research readiness — original inventory, not implementation

All nine original packages are `research_draft`, `verifiedAsWhole=false`. “Active” is a local source gate, not installed/usage/live certification; later revision 4 needs explicit reconciliation.
| Class / original spec | Active / total rules | Original gap |
|---|---:|---|
| Mage / Fire (+inactive Arcane notes) | 29/37 | Installed 10–19 slice is not a complete class/spec course; wand DPS extension missing. |
| Priest / Shadow | 21/23 | Alternate healer specs and routes incomplete. |
| Warlock / Affliction | 16/19 | Source 70753, 40+ gap; Rain of Fire/Hellfire inactive. |
| Rogue / Combat | 24/29 | Eight active tactics inferred; other specs incomplete. |
| Warrior / Fury | 23/27 | Original set lacks tank curriculum; Sunder inactive. |
| Hunter / Beast Mastery | 23/26 | Low-level/positioning tactics partly inferred; other specs incomplete. |
| Paladin / Retribution | 19/21 | Original guide predates Ret rework. |
| Shaman / Enhancement | 14/16 | Inferred usage, 40+ and healer gaps. |
| Druid / Feral | 0/10 | Later conditional sources exist, original rules remain inactive. |

Original 20–39 pool is not separate 20–29/30–39 coverage. Original 50–60/PvP gaps are now supplemented by **27 conditional late/endgame spec packets and 28 PvP contexts** (Bear separate), not completed curricula. There are 27 spec labels, not 28; all-role/lower-band/rank/condition/live gaps remain. Official launch research describes 1–60; 60+ is endgame, not levels 61+. Do not redo Riley’s Mage 10–19 comparison; prioritize remaining Mage bands, Warrior/Hunter, then the others.

### Open decisions for Sirc

- Confirm trunk (`test` versus script assumptions of `main`) and actual 8:21 Forever build-flavors install method; final independent-review verdict was not supplied. Next is live acceptance, not pretending merge/install is still pending.
- Choose Hunter spec/context or explicitly leave undecided; Warrior tank/DPS workflow, available healer/other-class testers, first endgame/PvP objective and first toon/profession.
- Approve cast-history window/privacy/reset/retention, explanation UX and first advisory tab. Weighted lean needs valid research, not a preference vote. Vespera Frost/Fire intent stays closed.
- Decide faction browser, popular-build source, one-ring replacement verdicts, ship 8 versus 3 TOCs, Weekly Dashboard/Now and mockup timing. Replacement matrix format is settled; individual verdicts/full addon list/10th Rampage name remain UNKNOWN.
- Audit Sirc casing edits across remaining files, Docs/ placement and Settings 60 px overlap; current full application UNKNOWN (LICENSE author Sirc was freshly read). Earlier self-test/tab-height/Mists/date/timing items, theme/transparent-mode implementation and Radar existence/behaviors remain UNKNOWN/UNVERIFIED.
- Confirm four policy-document names/scope, review quoted license/privacy wording and actual telemetry defaults; no legal/policy change performed. Exact July 31 talent-tree quote remains unavailable; retain paraphrase without fabricating it.
- Resolve beta/live provenance split and retention, historic G3/current capability contract and per-client export/stamp coverage; no beta-to-live seeding. Old backup verdict UNKNOWN, but do not reopen the settled replacement bare-backup decision.
- Choose PR58/59/61 native-test priority: reputation comparison, duplicate edge cases, calculator controls/persistence. Single-row Vespera evidence does not certify all three.
- Credential metadata only: WowUp token expired November 7 as exported; later regeneration UNKNOWN. Sirc regenerates/pastes it into WowUp settings himself, never chat. Distinct imported label “WOWUP. IO” paste confirmation and “Courier-Utility” PAT purpose/authorization remain UNKNOWN; no token requested/read/changed or automatic revocation.

### Data verification status

Review evidence is dated November 9, 2026 PST; game source is the 7:36 PM PST live export, not a post-PR62 run. **7,771 claims:** 3,570 keep; 71 use theirs; 696 add; 105 remove proven inaccurate; 3,329 unresolved. The second source pass settled 965 prior unknowns; live ingest settled 254 more, added 292 observation claims plus 6 attributed handoff claims. No prior keep/use decision revoked; two previously unresolved records had proven stale fields, matching data retained.
- Current catalog 3,018; 29 current spells versus 31 pooled; 53 Mage mappings/18 condition records; 24 original Mage identities and 80 shipped rank fields corroborated. NPC/same-name/other-era entries and 26 nominal levels>60 forbid automatic player provenance. 1,090/1,430 legacy bundles have partial ID/name support, not whole priority verification.
- Study known/nominal 6 and Research Access turn-in observed; first-seen 13 is not unlock. Curse 18/20 and Decimation unresolved. Comprehension 3012/Comprehend Scroll 1296017, Touch of Grave 30% and item 3382 corrections are described above. 108 item records exact; 171 pooled observations added, not current ownership/scoring.
- Whole recipes remain unresolved despite scoped field matches: 1,391 original recipes, only 6 originally explicit output counts/1,385 missing; 1,367 matched baseline effect candidates do not prove native effective yields/perks. 24 missing pairs and 25 null-versus-zero semantics need separate evidence. Unknown is never one/free.

| Unresolved area | Claims | First closure gate |
|---|---:|---|
| Legacy priorities | 1430 | Separate identity, conditions, priority; Mage→Warrior→Hunter. |
| Recipe bundles | 1392 | Acquisition, effective output/perks; keep verified fields. |
| Materials | 256 | Units/recipe relations/version, not invented prices. |
| Other Forever | 161 | Equipped/learned/racial identity first; cache miss not removal. |
| Training | 72 | Positive provenance/acquisition; Curse native requirement. |
| Profession addon reference | 13 | Skill versus spell IDs/native API domains. |
| Reputation | 4 | Native bounds/header semantics and sourced progression. |
| Source conflicts | 1 | Warlock Decimation tooltip/effect evidence. |
| **Total** | **3329** | Keep/use/add/remove-proven-inaccurate/unresolved. |

**Warning triage:** 32 =17 missing-API notices +1 manifest summary +12 lookup occurrences/four IDs +2 frame-churn warnings. G19 owns semantic/identity investigation; G04/G05 own pooling. Categorization is not proof risks are fixed/accepted or launch GO.
**Offline boundary:** historical full archive runs 59/61; timezone-dependent Harvest fixture passes unchanged under UTC, release test requires Git metadata. Eight TOCs,303 Lua 5.1 compiles, actual runtime package check and 10 missing-wrapper cases passed in the recorded review. Last integrity run 178 pass/2 research-drift failures: at 7:55:26 PM PST eight Mage/Priest/Warlock research/notes files changed outside this reviewer’s writes. Pinned addon/live/recipe inputs unchanged; do not reset baseline or disable checks to hide drift. This rewrite does not claim a fresh game/test-suite run.

### Evidence register — provenance, not migration instructions

- `test` source audit baseline 4555883; runtime ZIP `/workspace/ToonAge-test-4555883.zip`,424 files, SHA256 `f2b54656bfe5fcda44add24800da613ea7de5bb1938e2afa7315ef796efe7126`; current Mage package/hash are in delivery record.
- `/workspace/toonage-verification/`: SUMMARY, COVERAGE, OPEN-QUESTIONS, IN-GAME-TEST-PLAN, API-GUARD-AUDIT, OFFLINE-TEST-RESULTS, 19 CSV ledgers and counts.json; these are detailed evidence, not a second authority overriding this team plan.
- Live source `live/ToonAge-forever-20261109-1936.lua` under that evidence folder; SHA256 `21171c512ef75057afe7c2745e1757f1e2df9aac669c7eb38a1a8b6e4bfe1d9d`; literal-only parse, never executed. Shared drift: `live/shared-input-drift.json`.
- Historical updater audit: `/workspace/toonage-install/Update-ToonAge.ps1`; not a Forever install endorsement.
- Research `/workspace/wow-kb/toonage-data/rotations/forever/` (READINESS, MAGE-SUBSET-MANIFEST, coverage plan, nine class Lua/Markdown pairs); recipes `/workspace/toonage-recipe-reference/`. Box-local files are not automatically in GitHub. Transfer only if Sirc explicitly approves scope; no bulk export/secrets or live-save publication.
- Scorecard Page: https://cursor.com/canvas/store-a17ec4df-ca26-4297-95c1-09089d4b4f8d/2e41af9f-16e6-47e0-85da-9bd9501f3f72. It carries stages/indexes and gap plan; original matrices are historical.


### History (before Nov 2026)

Superseded and already-tried items, earlier tools, Pepper who later named herself Muse, dual-gate wording and Muse-export quotes are in [HISTORY.md](HISTORY.md). Muse remains authoritative for prior direction, authority, roles, branches and gates.

### Team work log — append after each part

November 9, 2026, 9:03 PM PST — Conductor/executor documentation pass: backed up the 650-line record, centered it on Sirc’s team, retained all 24 G-cards/standing rules/quotes/data boundaries, and replaced obsolete first-task ordering with installed Mage acceptance → Training → labels. Fresh read-only `test` tree/LICENSE/.rules check supports the policy-doc filename findings; no repo writes, PRs, installs, bot messages or policy changes. Exact talent-tree quotation/transparent-mode details remain UNKNOWN, not invented. Sirc’s final decisions and live tests are still required.
November 9, 2026, 9:10 PM PST — Conductor/executor documentation draft (box only, not committed): split the 578-line shared record into README.md, AGENTS.md, docs/HANDOVER.md, docs/HISTORY.md and docs/architecture.md under `/workspace/toonage-docs/` in repo layout. The repo (Sirc146/ToonAge, `test`) is the intended source of truth; box copies are drafts. Standing rules, all 24 G-cards, Muse quotes and history items retained. Added Sirc’s git preference and “After each verified test and its working it's pushed up.” No repo writes, PRs, installs, bot messages or policy changes.
