# ToonAge — Sirc’s Shared Team Record

Single shared record for Christopher (Sirc / Sirc146) and the ToonAge team. All plans, decisions and final approvals lead to Sirc.

The repo https://github.com/Sirc146/ToonAge on branch `test` is the single source of truth. Sister files in this repo: [README.md](../README.md) (human overview), [AGENTS.md](../AGENTS.md) (standing rules and bot workflow), [HISTORY.md](HISTORY.md) (superseded and already-tried archive), [architecture.md](architecture.md) (clients, TOCs, modules, API audit). Box copies, including `/workspace/toonage-docs/`, are drafts only until approved and committed.

**Updated:** November 11, 2026. **Repo:** https://github.com/Sirc146/ToonAge · **Integration:** `test`.
**Trunk mapping: SETTLED — `test`.** Confirmed by Sirc November 11, 2026: installs come from `test`, PRs target `test`, `main` and release tags are held for his separate approval. This settles the UNKNOWN flagged in the November 9 draft; do not silently change branches.
**Merge note (Nov 11, 2026):** this file is PR #63's HANDOVER with the November 11 restructure merged into it. The G01–G24 cards, first-task tables, live fix list, product decisions, and evidence below are PR #63's, kept intact. The overlay adds the guardrails, the Muse/merge rules, the pull/push/commit timing, the CurseForge release card, the Gemini/Copilot/snippet sections, and the test-status template. It replaces the standalone restructured draft — do not save that draft as a second HANDOVER. Merged Nov 11, 2026 with `WoW-AddOn-Build-Workflow.md` (workspace/user/files/WoW-AddOn-Build-Workflow.md) — the six phases, four gates, Blizzard policy, Phase 0 setup, hand-off contracts, and task prompt below come from it, translated to ToonAge's settled rules (see “How this merge was done” in the phases section).
**When PR #63 merges — remove these conditionals (verified Nov 11, 2026: PR #63 is 2 commits ahead of `test`, fast-forward, 0 conflicts, 5 files (README.md, AGENTS.md, docs/HANDOVER.md, docs/HISTORY.md, docs/architecture.md) — Riley merges it in one action; Muse cannot merge from here. Sequencing: PR #63 still carries the old 476-line HANDOVER, so commit this merged file to the PR branch (grok/docs-source-of-truth) FIRST, then merge — if PR #63 merges as it stands, the old HANDOVER lands on `test`):** (1) this merge note itself — its content lives in the Team work log; (2) the Gemini prompt parenthetical "(Until PR #63 merges, the live files on test are .rules.md and Docs/ARCHITECTURE.md. Do not use CLAUDE.md — it is archived.)"; (3) the Copilot section parenthetical "(`.rules.md` until PR #63 merges)". After that, this file describes one state: `AGENTS.md` + `docs/` on `test`.

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

Muse (formerly Pepper) audits, coordinates, and assists with snippets; not a builder on a branch. Claude Code and Kiro are archived as builders — they no longer implement or build features. Snippets from them, if Sirc brings them, arrive as outside code under the snippet rules below.

**Workflow rule:** plan with Conductor, write the plan here, then obtain Sirc’s applicable approval. If Conductor is unreachable, work pauses — no bot proceeds on its own spec or takes a decision to Sirc directly. **Every bot reads `AGENTS.md`, `docs/HANDOVER.md` and `docs/HISTORY.md` from the repo before working and records its part afterward as a commit**: dated scope/card, source/head, changes, tests, review, merge/install state, blockers and next step. If the file or evidence is inaccessible, ask a concrete question; do not guess. Christopher: **“I'd rather have everything working off git.”** After a verified live test: **“After each verified test and its working it's pushed up.”**
Small feature branches and reviewed PRs target `test`; a plan, static GO or relayed approval is not blanket authority. Native approvals must be received directly where required. Preserve Sirc’s exact words; do not turn historical permissions into new ones. Release tags still need his explicit approval. Docs and code changes go in as their own commits so one can be rolled back if needed.

### Guardrails — hard rules, no exceptions (added Nov 11, 2026)

- **Working branch is `test`.** Installs come from `test`. PRs target `test`. Feature work goes on `<builder>/<feature>` branches and merges into `test` only. `main` and releases are held for Sirc's separate approval — nothing merges to `main`, and no release is cut, without his direct word.
- **Merge timing (model in use):** merge to `test` after review + CI, on Sirc's direct word — then install from `test`, then Sirc live-checks. Installs come from `test`, so a change cannot be live-checked before it merges; that is why PRs #58, #59, #61, and #62 were all merged into `test` before his live check. The full sequence is in "Pull / push / commit / merge / install / live-check" below.
- **Push when verified, not once a day.** As soon as a change has passed its gates, push it. Do not hold finished work for a daily close-out. The daily summary still happens — what shipped, what stayed behind and why, what is waiting on Sirc and since when, and what is first tomorrow — and it never freezes building.
- **A merged change that breaks the game is reverted, not patched in place.** If a live-check or real play finds a regression from a merged change, the change comes out of `test` with a revert commit, the install goes back to the previous head and is re-verified, and the card goes back to In progress. The fix is a new small commit through the normal steps — never a quiet edit on `test`.
- **Riley opens and merges PRs — only on Sirc's direct word.** Glitch is the GitHub owner on the roster and holds the go / no-go on uploads, but Riley is the one who actually opens and merges PRs, and only when Sirc has said so directly. No bot merges on another bot's say-so, and no bot merges its own work.
- **Back up SavedVariables before every test — whichever client is being tested.** Not Forever only. A test that risks the saved data without a backup does not run.
- **Forever first.** Test on Forever first, then the other clients a card requires. Never edit the `_retail_` AddOns folder.
- **Release tags (`v*`) need Sirc's approval before pushing.** Pushing a `v*` tag builds the zip, publishes a GitHub release with `release.json` for WowUp, and uploads to CurseForge and Wago — so a tag is a release, not a bookmark. No tag goes up without his direct word.
- **Git is the only store; one backup folder on the PC.** Code, docs, and approved evidence live in git (`Sirc146/ToonAge`) — the repo is the single source of truth, and box/PC copies are drafts until committed. On the PC, keep one backup folder only: the bare repo backup (`ToonAge-full-backup.git`, refreshed after each verified test/release) plus dated SavedVariables backups. No second working copy, no local-only branches, no data that lives only on the PC. If a local branch holds work, it goes to git as a branch or it is retired — it does not stay PC-only. (Sirc, Nov 11, 2026.)
- **Buttons — verified in code; sighting is Sirc's 30-second check.** The Self-test button exists in code (`Modules/Infrastructure/TestHarness.lua:1582`, `ToonAgeSelfTestButton`, title bar) but only shows on dev builds (version contains `-dev`) or when `/ta debug` is on at login. The Module Health button exists in code (`Modules/Infrastructure/Settings.lua:839`, `AddBtn("Module Health", ...)`; output to the copyable window per `Core/Init.lua:1587`). What is still open is the in-game sighting on the installed build — see the check-card in "Open checks for Sirc." The Settings → Debug "Run Self-test" button (Settings.lua:840) shows on any build — that is the check; do not type `/ta debug`. If a needed button genuinely does not exist, that is a card to build it — not a reason to type a probe, and the check waits until the card is done. The wrong-edition notice goes to chat by design.
- **Data rule.** Verify game facts against official sources plus Wowhead and Icy Veins. Merge what checks out. Remove something only with disproving evidence. Flag anything unverified for Sirc — never silently present it as fact. The Stats role may also use the Battle.net Game Data web API offline to generate data tables (Game Data only, never Profile endpoints); the client ID and secret live in a local `.env`, never in the repo and never in a bot's prompt.
- **Guidance is suggestions, and stays optional.** Word guidance as suggestions, never commands. Roles and recommendations follow what the character can actually do. BiS lists are never presented as fact.
- **No bot names an API function, event, or interface number from memory.** It cites the verified source (architecture.md, the harvest record, or the official source behind it) or stops and asks for research. Model memory is not a source.
- **No placeholder functions, no commented-out code, no TODO left in a PR.** A PR that carries any of those is not reviewed.
- **No bot holds an upload token.** CurseForge and GitHub tokens live only in GitHub Actions secrets.

### Open checks for Sirc — the remaining UNKNOWNs (added Nov 11, 2026)

Three checks to close before the doc is settled. Two need Sirc; the third needs one line from Riley. Each names exactly what to look at and what closes it.

1. **Buttons — in-game sighting (Sirc, in-game, 30 seconds).** Both buttons are verified in code (see Guardrails for files and lines). Open ToonAge on Forever and confirm Module Health and Run Self-test are in Settings → Debug, and the Self-test button is in the title bar on a dev build. If the title-bar Self-test button is missing, check the installed version first: on a non-dev build that is expected — use Settings → Debug → Run Self-test instead (Settings.lua:840, shows on any build). Do not type `/ta debug`. Closes when Sirc reports both seen (or which one is missing, which becomes a card).
2. **CurseForge and Wago secrets (Sirc only, repo Settings).** In the repo, Settings → Secrets and variables → Actions: confirm the `CF_API_KEY` and `WAGO_API_TOKEN` secrets exist, and the `X-Curse-Project-ID` and `X-Wago-ID` variables exist. Cross-check: the last Package and Release run log prints either "CurseForge token is set" or "CF_API_KEY is not set. CurseForge upload will be skipped." Never paste a token in chat, in a doc, or in a commit. Closes when Sirc reports set or missing for each of the four.
3. **The 8:21 Forever install method (one line from Riley).** The script supports it — `Tools/build_flavors.ps1 -Install` exists on `test` (verified Nov 11). What is still open is which command Riley actually ran for the Nov 9, 8:21 PM install: `build_flavors.ps1 -Install`, or something else? Closes when Riley answers in one line; if it was not the approved method, the install is re-done with the approved method before any measurement from it is trusted.

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
| commit `e060761` | Combat reaction predicates (target casting/interruptible, enemies in range, player moving, ally needs dispel, target has stealable, incoming damage) with CombatState scans. On both `main` (HEAD) and `test`; `main` is fully contained in `test` (verified on a full clone, Nov 11, 2026). |

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
**Before every individual game check:** Sirc performs the explained SavedVariables backup, checks harvest counts and installed=agreed-trunk/client/version, then uses addon buttons/copyable windows. Trunk is `test` (settled November 11, 2026). Missing button is blocked; no typed probes. Launch requires 0 fails, every warning triaged, clean Error Log after real play.

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

- Trunk is SETTLED as `test` (Sirc, November 11, 2026 — installs come from `test`, PRs target `test`). Still open: confirm the actual 8:21 Forever build-flavors install method; final independent-review verdict was not supplied. Next is live acceptance, not pretending merge/install is still pending.
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
November 11, 2026 — Muse restructure merged into PR #63's HANDOVER (box copy, not committed): trunk mapping settled as `test` per Sirc; guardrails added (push-when-verified, Riley merge rule, Muse formerly Pepper, Claude/Kiro archived, tag approval, backup for whichever client is tested, buttons with UNVERIFIED existence + missing-button card, data rule, suggestion wording); merge-timing model written as merge-to-`test`-after-review+CI → install → live-check, matching PRs #58/#59/#61/#62 — Sirc confirmed this model Nov 11 ("merge to test first, then you test, and your go marks it Done"); CurseForge/Wago release card added (pipeline exists in release.yml; no `v*` tag on current `test` head `c9c5308`, newest dated release tag `v2.0.3` Sep 18, 2026; secret presence UNVERIFIED); Gemini/Copilot/snippet sections and test-status template added. The standalone restructured draft is superseded by this merged file — do not save it as a second HANDOVER. G01–G24 cards, first-task tables, and PR #63 evidence kept intact.
November 11, 2026 (later) — Muse: applied Conductor's 8.5/10 fixes — Gemini prompt pointed at the Test status template and Team work log (no section 9 exists); the two Team work log headings merged into this one; step 8 now names exactly what gets pushed after a go (the README and HANDOVER update commit); leftover draft sentence removed. Data rule added (Sirc, Nov 11): git is the only store — code, docs, and approved evidence live in `Sirc146/ToonAge`; one backup folder on the PC only (bare repo backup + dated SavedVariables backups), no second working copy or PC-only branches. Correction, same day: the "21 commits on main not in test" claim was withdrawn — it came from a shallow-clone check, and a full clone confirms `e060761` is in `test` and `main` has 0 commits not in `test`. The DISPUTED note and the reconciliation card were removed and the plain fact restored. `origin/reskin` does not exist on GitHub (only `cursor/ui-bugs-reskin-dba9`); nothing to retire, no action on that branch.
November 11, 2026 (later still) — Muse: closed what could be closed from the repo side — Self-test button verified in code (`Modules/Infrastructure/TestHarness.lua:1582`, gated on `-dev` version or `/ta debug` at login) and Module Health button verified in code (`Modules/Infrastructure/Settings.lua:839`, copy-window output per `Core/Init.lua:1587`); in-game sighting is now a 30-second check-card for Sirc. `Tools/build_flavors.ps1 -Install` verified in code; which command Riley ran at 8:21 is a one-line question for Riley. Secrets cannot be verified from a clone — check-card added for Sirc (repo Settings + run-log line). PR #63 verified mergeable: 2 commits ahead of `test`, fast-forward, 0 conflicts — Riley merges in one action; post-merge cleanup list added (3 conditional spots). Test status seeded with the PR #62 / G01 entry awaiting Sirc's Spells check plus #58/#59/#61 pending. Guardrails trimmed to a single full copy — Gemini prompt and validation prompt now point to it.
November 11, 2026 (later still) — Muse: 9.5/10 fixes — Open check 1 now points to Settings → Debug → Run Self-test (Settings.lua:840, shows on any build) instead of /ta debug; PR #63 file count corrected to 5 (README, AGENTS, HANDOVER, HISTORY, architecture); sequencing noted (commit this 647-line file to the PR branch before merging, or the old 476-line HANDOVER lands on test). The merge bot's name was removed from the file throughout at that point — reversed later the same day; see the next entry.
November 11, 2026 (later still) — Muse: Riley restored as an owner throughout — the file lists owners, so Riley is part of it (implementation and merge, only on Sirc's direct word). The earlier removal is reversed; the 9.5/10 fixes (Run Self-test button, 5 files, sequencing) stand.
November 11, 2026 (later still) — Muse: workflow fixes applied — Waiting on Sirc section seeded in Test status (G01 live check, PR #63 approval, buttons sighting, secrets check, #58/#59/#61 verification, with dates); daily summary now lists waiting items with dates and runs in the evening, plus a per-release workflow review; revert procedure added (revert commit, reinstall previous head, card back to In progress) as a guardrail and in step 8; ‘go with changes’ defined (fix commit, re-check only what changed); open-PR triage rule (Conductor owns the list, triage at each release, 30-day flag, no silent closes); red-CI rule and reviewer-disagreement path; Conductor-unreachable pause; branch naming <builder>/<feature>; PR contents rule; status timestamps with Conductor owning Done transitions; CurseForge/Wago project-existence card; Open-checks intro corrected.
November 11, 2026 (later still) — Muse: merged the build-workflow doc (`WoW-AddOn-Build-Workflow.md`) into this file — six phases, four gates (including a new feasibility gate), role mapping with two unowned roles (Release bot, Localization bot — Conductor covers both until Sirc assigns them), hand-off contracts, Blizzard policy table + EULA clauses, interface numbers (Forever 16001, Titan Reforged 38002 with no ToonAge TOC yet), Phase 0 verify-once list, task prompt, three-round escalation, 30-minute launch-gate session, CF_API_TOKEN note, API-citation and no-placeholder guardrails, Battle.net Game Data note. Kept without bending: test trunk, HANDOVER as the single record, <builder>/<feature> branches, build_flavors -Install only, check_lua.py/test_*.py gates. Not taken: separate SPEC/API/DATA/THEORY/DESIGN/LORE files, STATE.md, junction install, friends beta-testing process.
November 11, 2026 (later still) — Muse: applied Conductor's 9/10 fixes — premature approval line removed (approval has not happened yet; it goes back in only on real approval) and PR #63 returned to Waiting on Sirc; interface-numbers line corrected (Wrath 30405, Cata 40402, Titan Reforged has no TOC); CurseForge/Wago IDs verified in every TOC (1734520 / 56ndnjG9) — project-existence card and Phase 0 item 4 corrected; .pkgmeta gap recorded (AGENTS.md not ignored on test or PR #63; stale wago.yml comment) for Riley to fix in PR #63. 51 open PRs count confirmed.
November 11, 2026, 8:48 AM PT — Sirc approved the merged HANDOVER as the team workflow. His words: "Lets make this the workflow I Like this and let everyone know their part even Riley". Riley committed it to PR #63 with the .pkgmeta fix; merge still waits on Sirc's direct word to Riley or his own GitHub click.
Nov 9, 2026 ~8:21 PM PST (recorded Nov 11, 2026): Riley did NOT run `Tools/build_flavors.ps1 -Install` for the PR #62 install. The executor built the runtime from test c9c5308 on Riley's box and copied the 4 changed files (Modules/Forever/MageGuidance.lua added; RotationLists.lua, Rotation.lua, ToonAge_Camelot.toc changed) onto Jarvis by hand, after a fresh backup at `_forever_\Interface\ToonAge-backup-20261109-201958`. SavedVariables unchanged. Whole-install match to c9c5308 via build_flavors.ps1 is UNVERIFIED. Future installs use only `Tools/build_flavors.ps1 -Install` after a SavedVariables backup.
Nov 11, 2026 8:59 AM PST (relayed by Conductor): Sirc ran a read-only SHA256 check of `_forever_\Interface\AddOns\ToonAge` against the 425 files in ToonAge-test-c9c5308.zip (sha256 ced4d25f...): all 425 match exactly, none missing or different; the only extra file is `.rules.md`. SavedVariables backup: `C:\Users\calik\ToonAge-backups\SV-20261111-0859`. No reinstall needed for G01. The build_flavors.ps1 Forever install path (`_classic_beta_` instead of `_forever_`, line 156) is a pending card; held until it arrives.

### Pull / push / commit / merge / install / live-check — when each happens (added Nov 11, 2026)

One card, one branch, one sequence. Nothing here is blanket authority — each merge, install, and release needs Sirc's direct word at its own step.

1. **Pull.** The builder pulls the latest `test`, then branches `<builder>/<feature>` — `grok/<feature>`, `gemini/<feature>`, `copilot/<feature>`. Never build on `test` directly, never on `main`.
2. **Commit.** Small, incremental commits on the feature branch, one card at a time, each with a definition of done. No large code chunks, no commit that mixes two cards. Docs and code go in as their own commits so one can be rolled back.
3. **Push (feature branch).** Push the branch when the offline gates pass locally (`python Tools/check_lua.py`, the relevant `Tools/test_*.py`). CI runs on every push and every PR — a green CI run is the guarantee the checks ran on a clean machine. Pushing the branch is not merging it.
4. **Pull request to `test`.** Open the PR against `test`. A PR carries the card, the offline gate results, the head it was built from, and the review status. Review: Warden (rules), Glitch (offline tests + in-game checklist), Gilder (visuals, if any), Chronicler (facts). CI must be green. A PR with red CI is not reviewed until green — the branch owner fixes it or asks Conductor; Sirc may waive a red CI explicitly, and the waiver is recorded on the PR. If reviewers disagree, the disagreement goes to Sirc as a numbered decision question through Conductor, and the card does not proceed until he answers. Three failed rounds on one task escalate to Sirc through Conductor instead of looping. A plan, a static GO, or a relayed approval is not merge authority.
5. **Merge to `test`.** Riley merges, only on Sirc's direct word. This is the step PR #62's instruction shows: "Merge PR #62 into test once the final copy commit passes review and CI, then install on Jarvis with a backup and settings preserved." Before merging, commit this merged HANDOVER to the PR branch — PR #63 still carries the old 476-line version, and merging as it stands would land the old file on `test`. Merge happens *before* the live check, because installs come from `test` — Sirc cannot live-check a change that is not in `test` yet.
6. **Install from `test`.** Approved Forever install is `Tools/build_flavors.ps1 -Install` only, never the all-client release ZIP, never `Tools/deploy.ps1` (its `robocopy /MIR` can be destructive). Close WoW first; Sirc runs his own explained SavedVariables backup — for whichever client is being tested — and confirms the installed files and version match the agreed `test` head before measuring.
7. **Live-check (Sirc, in-game).** Buttons and copyable windows only — Reload UI, Spells, Module Health, Error Log. If a needed button does not exist, that is a card, not a typed probe; the check waits. Launch gate: 0 fails, every warning triaged, clean Error Log after a 30-minute normal play session.
8. **Push up after a verified test — the README and HANDOVER update commit.** Sirc's words: "After each verified test and its working it's pushed up." A go from Sirc moves the card to Done. What gets pushed then is exactly one thing: the docs update commit — the README and HANDOVER entries that mark the change verified (test status, work log, exact head, in-game result). The code is already on `test` by then; nothing code-related is pushed at this step. A no-go sends the card back with the finding — the fix is its own small commit and PR, back through steps 2–7. A ‘go with changes’ answer means the listed changes go in as a fix commit through steps 2–7, and the live-check then covers only what changed — not a full re-verification of the whole card. A regression found after merge is reverted, not patched: a revert commit takes the change out of `test`, the install goes back to the previous head and is re-verified, and the card goes back to In progress; the fix comes as a new small commit through the normal steps. Nothing is presented as finished on a passing offline suite alone.
9. **Release (separate approval).** Only on Sirc's direct word: push a `v*` tag, which runs the release pipeline (CurseForge and Wago uploads — see the next section). `main` merges and `live/*` snapshots are his separate approval too.


### The six phases and four gates — merged from the build-workflow doc (Nov 11, 2026)

The addon moves through six phases. Bots do the work inside each phase; Sirc approves four gates, and nothing crosses a gate without his spec approval, his in-game test, or his tag. Build has no gate of its own: code leaves it only through the Reviewer and the Tester. A failed in-game step sends the task back to Build; a game patch sends the project back to Research.

#### How this merge was done — kept, translated, not taken

- **Kept as settled:** trunk is `test` (never `main`); `docs/HANDOVER.md` is the single shared record; branches are `<builder>/<feature>`; the approved install is `Tools/build_flavors.ps1 -Install`; in-game checks use buttons and copyable windows; the merge-timing model (merge → install → live-check); push-when-verified; the offline gates are `Tools/check_lua.py` and `Tools/test_*.py`.
- **Translated:** the pipeline doc's `main` becomes `test` everywhere (release tags are cut from `test` on Sirc's approval); its `docs/STATE.md` role is played by this file plus Test status; its `feat/<criterion-id>` branches become `<builder>/<feature>`; its `luacheck` / LuaLS checks are a local option, not a gate — the gates are the repo's own scripts; its directory-junction install is not adopted.
- **Not taken:** separate `SPEC.md` / `API.md` / `DATA.md` / `THEORY.md` / `DESIGN.md` / `LORE.md` files — their jobs are done here by the G-cards, `architecture.md`, the harvest store, and Gilder's design direction. No second record is created. Friends-testing through a beta issue template is not adopted — there is no beta-tester process yet.

| Phase | Lead | With | Output | Human gate before the next phase |
| --- | --- | --- | --- | --- |
| 1. Planning | Conductor (with Sirc) | Gilder, Chronicler | Spec in the HANDOVER cards | Gate 1: spec approved |
| 2. Research | Chronicler | Riley (probes), Glitch (tests) | API/feasibility evidence | Gate 2: feasibility approved |
| 3. Build | Riley, checked by Warden | Gilder (UI review), Chronicler (string/fact review) | Merged pull requests to `test` | None |
| 4. Testing | Glitch (static) + Sirc (in-game) | Riley (fixes), Chronicler (expected values) | Static report, validation steps | Gate 3: in-game pass |
| 5. Release | Conductor prepares; Sirc tags | Muse (audits) | Release PR, changelog | Gate 4: push the tag |
| 6. Post-launch | Conductor (triage) | Chronicler (patch diffs) | Next milestone tasks | None |

| Gate | Sirc decides | Why an agent cannot |
| --- | --- | --- |
| 1. Spec approved | Scope, target game versions, what is out of scope | It is his addon |
| 2. Feasibility approved | Whether to cut or redesign features the API blocks — including the secret-value verdicts (works as specified, display-only, out of combat only, not possible) | Trade-off between what he wants and what the client allows |
| 3. In-game pass | The addon works in the live client | Agents cannot log in to WoW |
| 4. Release | Push the tag that triggers the upload | Publishing is public and tied to his accounts |

#### Role mapping — pipeline doc to ToonAge crew

| Pipeline role | ToonAge owner |
| --- | --- |
| Orchestrator | Conductor |
| Planner | Conductor (plans with Sirc; no separate Planner bot) |
| API Researcher | Chronicler (research) + Riley (runtime probes) + Glitch (tests) |
| Coder (Builder) | Riley |
| Reviewer | Warden |
| Tester (Static tester) | Glitch (static) + Sirc (in-game) |
| Release bot | Unowned — Conductor covers the release PR until Sirc assigns it; Sirc pushes the tag |
| Designer | Gilder |
| Stats bot | Chronicler |
| Theorycrafter | Chronicler |
| Lore bot | Chronicler (tone and names) |
| Localization bot | Unowned — strings stay in locale tables per the coding rules; Conductor assigns extraction per card until Sirc names an owner |
| Docs bot | Conductor (README/store page), with Muse auditing |
| Triage bot | Conductor (owns the open-PR list and issue triage) |

#### Hand-off contracts (ToonAge)

Every hand-off is a file or a pull request, never a chat summary.

| From | To | What is handed over | The receiver rejects it when |
| --- | --- | --- | --- |
| Conductor | Riley | Card with spec, API rows it may use, files it may touch | The criterion is vague or the API rows are missing |
| Chronicler | Riley, Glitch | Sourced data / rules with sources | A value has no source or no flavor |
| Riley | Warden | Pull request for one card | It touches files outside the card, or calls an unverified API |
| Warden | Glitch | Approved pull request | (Glitch runs regardless; failures go back to Riley) |
| Glitch | Sirc | In-game checklist + green static report | (Sirc runs the check; a failure returns to Riley with the diagnostics) |
| Sirc | Conductor | Go / no-go / go-with-changes, with the diagnostics pasted back | n/a |
| Conductor | Release (Sirc) | Release PR with changelog | An entry does not say what changed for the player |

**Resolving disagreements:** technical fact (does a function exist, is a value secret) — the verified source wins; if it is wrong, Chronicler corrects it and cites the source, nobody else edits it. Game numbers — the sourced data wins over the rule that uses it. What to build — the spec wins over design, theory, and lore; specialists propose changes to Conductor, they do not expand scope themselves. Feasibility beats desirability — a rule marked not possible is cut or redesigned, however good the theory. Anything two bots cannot settle in one round goes to Sirc through Conductor, as a question with the two options stated.

#### Interface numbers (verified Nov 11, 2026)

Source: the wiki's latest patch table and TOC format pages, via the build-workflow doc. Retail, Forever, Mists, TBC and Era match ToonAge's TOCs (the Mainline TOC also lists 120100 and 120001 alongside 120105). Classic Titan Reforged (38002) has no ToonAge TOC — ToonAge_Wrath.toc is 30405 (Wrath Classic). ToonAge_Cata.toc (40402) is not in the table below; the wiki lists Cataclysm Classic and Wrath Classic but with no current install folder.

| Client | TOC game type | Family | Install folder | Version | Interface |
| --- | --- | --- | --- | --- | --- |
| Retail (Midnight) | `standard` | mainline | `_retail_` | 12.1.5 | 120105 |
| Retail PTR | `standard` | mainline | `_ptr_` | 12.1.7 | 120107 |
| Forever | `forever` or `camelot` | mainline | `_forever_` | 1.60.1 | 16001 |
| Mists of Pandaria Classic | `mists` | classic | `_classic_` | 5.5.4 | 50504 |
| Classic Titan Reforged | `wrath` | classic | `_classic_titan_` | 3.80.2 | 38002 |
| Classic Anniversary (Burning Crusade) | `tbc` | classic | `_anniversary_` | 2.5.6 | 20506 |
| Classic Era | `vanilla` | classic | `_classic_era_` | 1.15.9 | 11509 |

**Forever is not a Classic client for API purposes.** The wiki puts it in the mainline family: its 1.60.1 patch includes all Modern changes up to 12.1.5. Secret-value behavior is therefore checked row by row on Forever instead of assuming it behaves like Classic Era. The `camelot` value may be renamed to `forever`, so TOC conditions list both. Remix is treated as Retail with a mode check (no ToonAge Remix handling yet). Plunderstorm and Talebound are excluded with `## ExcludeLoadGameType` unless the spec targets them — ToonAge's TOCs do not carry those lines today.

### Blizzard policy — blocking checks (merged Nov 11, 2026)

Blizzard's UI Add-On Development Policy has eight rules, and its seventh pulls in the End User License Agreement (last revised 21 March 2024). Each rule is assigned to a bot as a blocking check. This is a reading of the published text, not legal advice.

| Policy rule | What it means for the build | Checked by | When |
| --- | --- | --- | --- |
| 1. Free of charge | No paid tiers, download fees or paid services tied to the addon | Conductor, Sirc | Gate 1, release PR |
| 2. Code must be visible | No obfuscation or minification; the public repo and the shipped zip hold readable Lua | Warden, Sirc | Every PR, package dry run |
| 3. No harm to realms or players | No chat spam, no unnecessary disk reads, no frame-rate cost | Warden, Glitch | Every PR, in-game pass |
| 4. No advertising | No promotion of products or services in the addon | Chronicler, Conductor | String review |
| 5. No in-game donation requests | Donation links live on the CurseForge or GitHub page only | Chronicler, Conductor | String review, store page |
| 6. Age-appropriate content | All text and art within the game's Teen rating | Chronicler | String review |
| 7. Follow the Terms of Use and EULA | See the EULA rows below | Chronicler, Warden | Gate 2, every PR |
| 8. Blizzard may disable addon functionality | Every feature fails quietly when an API is removed or restricted | Riley, Chronicler | Build, patch-day loop |

**EULA clauses that shape the design**

| Clause | Paraphrase | Pipeline rule |
| --- | --- | --- |
| 1.C.ii, Cheating | Bars unauthorized code that automates control of the game or changes or facilitates gameplay | The addon displays and advises; it never issues actions for the player. Any feature that would act on the player's behalf is cut at Gate 2 |
| 1.C.vi, Data mining | Bars unauthorized software that reads data the platform generates; Blizzard may allow certain third-party user interfaces | Data is read only through the addon API. No memory reading, no packet reading, no companion program that inspects the client |
| 1.C.i, Derivative works | Bars reverse engineering, decompiling and modifying the platform | Research uses published API documentation and addon source, not decompiled client code |
| 1.C.iii, Commercial use | Bars exploiting the platform for unauthorized commercial purposes | Consistent with policy rule 1 |
| 2.B, Ownership | Blizzard owns game content, art, names and data | No Blizzard logos or ripped art in the logo or store page; in-game textures are referenced, not redistributed |
| 4, Consent to monitor | The client may scan for unauthorized third-party programs | No bot, script or tool in this workflow attaches to the running game |

The bots in this workflow are build tools that work on files in a repository. None of them runs inside or against the game client, which is why every in-game step belongs to Sirc.

### Phase 0 — one-time setup (adapted Nov 11, 2026)

The repo already exists, so this is a verify-once list, not a build step. Items only Sirc can check are marked.

1. Repo exists: `Sirc146/ToonAge`. Done.
2. Workflow permissions read and write (Settings → Actions → General) — the packager needs this to publish a GitHub release; without it the upload fails with "Resource not accessible by integration." **Verify (Sirc only — cannot be read from a clone).**
3. CurseForge project — see the project-existence card in the release section. Start it early: moderation runs Sunday to Thursday, 8 AM to 3 PM CET, first in first out.
4. Project ID in the TOC as `## X-Curse-Project-ID` — done. Every TOC carries `X-Curse-Project-ID: 1734520` and `X-Wago-ID: 56ndnjG9` (verified Nov 11, 2026).
5. API token — see the secrets check and the `CF_API_TOKEN` note in the release section.
6. Local tooling: VS Code with LuaLS and the WoW API extension, BugGrabber with BugSack in the game client. `luacheck` is a local option, not a gate.
7. Install method: the pipeline doc links the repo into the game with a directory junction. **Not adopted — ToonAge's only approved install is `Tools/build_flavors.ps1 -Install`.** Never the all-client release ZIP, never `Tools/deploy.ps1`.
8. `.pkgmeta` gap — `AGENTS.md` would ship in the zip. Verified Nov 11, 2026: `.pkgmeta` ignores `docs/` but not `AGENTS.md`, on both `test` and the PR #63 branch. Riley adds `AGENTS.md` to the ignore list in PR #63. The `.pkgmeta` comment saying it is ‘used by wago.yml’ is also stale — `wago.yml` no longer uploads — correct it in the same change.

### Open-PR triage — the backlog has an owner (added Nov 11, 2026)

Conductor owns the open-PR list. The HANDOVER tracks only the PRs with live cards; the rest (51 open as of Nov 11, 2026) are triaged, not ignored: at each release, Conductor runs a triage pass — merge, rebase, or close as superseded — and records the decision per PR. A PR with no activity for 30 days is flagged in the daily summary for a decision. No PR is closed silently; the close reason is recorded. The first triage pass is still awaiting Sirc's go.

### CurseForge and Wago uploads — how releases ship, and the fix if they don't (added Nov 11, 2026)

**How it already works.** The pipeline exists in `.github/workflows/release.yml`. One `v*` tag does three things: (1) build the zip plus `release.json` for WowUp; (2) publish the GitHub release; (3) hand the tag to BigWigsMods/packager, which uploads to CurseForge (`CF_API_KEY` + `X-Curse-Project-ID`) and Wago (`WAGO_API_TOKEN` + `X-Wago-ID`). Either secret may be absent — the packager skips a site it has no token for, and the workflow logs which one was skipped. `.github/workflows/wago.yml` no longer uploads; it only notes that publishing lives in `release.yml`. No `v*` tag, no upload — uploads never happen from a branch push or a PR merge.

**Current state (verified Nov 11, 2026).** No `v*` tag points at the current `test` head (`c9c5308`); the newest dated release tag is `v2.0.3` (Sep 18, 2026). So PRs #58/#59/#61/#62 have not reached CurseForge — correctly, because no release has been cut from them and releases need Sirc's approval. Whether the CurseForge and Wago secrets are configured in the repo is UNVERIFIED from here — secrets cannot be read from a clone, and the workflow only reports them at run time. Do not claim the tokens are set or missing without checking the run log or repo settings.

**Before the next release: confirm the project page.** The project ID is present in every TOC — `X-Curse-Project-ID: 1734520`, `X-Wago-ID: 56ndnjG9` (verified Nov 11, 2026) — so the project very likely exists. What still needs confirming is the project page itself: that CurseForge shows the ToonAge project under ID 1734520 (and Wago under 56ndnjG9). If the page does not show it, creating the project is a card for Sirc (project creation needs his CurseForge account). The fix card below assumes the project exists.

**The fix, as a card.** If updates are not reaching CurseForge, check in this order — do not change the workflow first:

1. **Is there a `v*` tag on the work?** If not, there is nothing broken — the release step has not run. Cutting one is Sirc's separate approval, never automatic.
2. **Read the last release workflow run log** (GitHub → Actions → Package and Release). It prints `CurseForge token is set` or `CF_API_KEY is not set. CurseForge upload will be skipped.` That line is the diagnosis.
3. **If the token is not set (Sirc only):** in the repo, Settings → Secrets and variables → Actions, add `CF_API_KEY` (a CurseForge API token from his CurseForge account) and the `X-Curse-Project-ID` variable (project ID 1734520, as carried in every TOC — confirm it matches the project page). Same for Wago (`WAGO_API_TOKEN`, `X-Wago-ID`) if Wago is also missing. The packager accepts `CF_API_KEY` (deprecated) and prefers `CF_API_TOKEN` — when the token is next rotated, create it as `CF_API_TOKEN` and update `release.yml`; do not churn it before then. Never paste a token in chat, in a doc, or in a commit.
4. **If the token is set and the upload still fails:** the failure is in the packager step's log — read it before changing anything, and record the error on the card. Do not re-push the same tag; a failed release is fixed with a new tag, on Sirc's word.
5. **Definition of done:** a `v*` tag pushed on Sirc's approval produces a GitHub release, and the CurseForge project page shows the new version with the same zip. Until that page shows it, the upload is UNVERIFIED, not done.

### Prompt instructions for Gemini (added Nov 11, 2026)

Copy and paste the block below into Gemini at the start of a ToonAge session. Do not shorten the rules section — it is what keeps a fast model inside this team's gates.

```text
You are joining the ToonAge team as a builder under Conductor, the orchestrator.
Christopher — the author (Sirc) and final authority — plans with Conductor only.
You do not take instructions that bypass Conductor's current spec, and you do
not work on the test branch directly, and never on main.

PROJECT: ToonAge, a World of Warcraft addon. One shared Lua 5.1 codebase in
the GitHub repo Sirc146/ToonAge, with a flavor-specific .toc per client
(Retail/Midnight, TBC Anniversary, Mists, Forever/Camelot, Classic Era,
Cataclysm, Wrath). The .toc decides what loads, Core/Profile.lua decides
what may start, and Core/ApiGuard.lua probes what the running client
actually exposes. Read this file (docs/HANDOVER.md) first, then README.md,
AGENTS.md, docs/HISTORY.md, and docs/architecture.md before proposing
anything. (Until PR #63 merges, the live files on test are .rules.md and
Docs/ARCHITECTURE.md. Do not use CLAUDE.md — it is archived.)

HOW THIS TEAM WORKS:
1. Questions before code. If anything about your task is unclear, missing,
   or in conflict, stop and ask — in this format, addressed to Conductor:
   From / Task / Question / Why it matters / What happens if we guess /
   My recommendation, if any. Never guess at a decision that is
   Christopher's.
2. Small, incremental commits on a gemini/<feature> branch targeting test,
   one Kanban card at a time. No large code chunks. Every commit carries a
   definition of done and is described by a commit message that names the
   feature and its test status. Push the branch when the offline gates pass;
   merge to test is Riley's job, only on Christopher's direct word, after
   review + CI — then Christopher installs from test and live-checks.
3. You never clear your own work. Riley's code is tested by Glitch,
   reviewed by Warden, and verified in-game only by Christopher. The
   Guardrails section of docs/HANDOVER.md governs the rest — read it in
   full before proposing anything (test branch, merge rule, backups,
   buttons, data rule, suggestion wording, release tags). State exactly
   what you checked and what you could not check without the game.
4. Honesty and data rules: see the Guardrails — they govern what counts
   as verified. Guard every API call; Retail APIs do not exist on older
   clients.
5. Update docs/HANDOVER.md — the Test status template and the Team work
   log — when your work changes state. No update, no handoff. Release
   tags (v*) need Christopher's approval before pushing.
6. Merges into test are Riley's job, only on Christopher's direct word.
   You never merge, and never merge your own work.

CURRENT PRIORITIES: P0, in order, is (1) the PR #62 Mage 10-19 guide live
check (G01), (2) attack and training provenance (G03), (3) swapped build
and interface labels (G02) — full card scopes and DoDs are in this file.
Then G04/G05 frame regressions, then the rest of G06–G24. Work only the
card Conductor assigns you.

Start by: summarising what you read in docs/HANDOVER.md in five lines,
listing the questions you would ask before touching code, and naming the
first bite-sized commit you would make. Post all three in the team chat, then wait for Conductor's go.
```

### Task prompt Conductor sends (merged Nov 11, 2026)

The prompt Conductor sends with every task. One task, one criterion, one branch.

```text
Role: <bot name>
Task: <one sentence, one acceptance criterion or one document section>
Inputs: <file paths and the exact rows or sections to read>
Output: <file path or branch name>
Done when: <checkable condition>
May touch: <files>
Must not: <scope limits>
On a blocker: write it to docs/HANDOVER.md under Blocked / waiting on a decision and stop.
```

### Instructions for Copilot (added Nov 11, 2026)

GitHub Copilot works inside the IDE, on the card Conductor assigned — it is a pair of hands at the keyboard, not a second planner. The repo already carries `.github/copilot-instructions.md`; that file and `AGENTS.md` (`.rules.md` until PR #63 merges) govern every suggestion, and this section governs how the team uses it.

- **One card, one branch, one suggestion at a time.** Open the card's `copilot/<feature>` branch, state the card and its definition of done in the chat before accepting code, and review every completion line by line. A suggestion that touches a file outside the card's scope is rejected, however good it looks.
- **Use Copilot for what it is good at here:** completing the module pattern from `AGENTS.md`, drafting the offline `Tools/test_*.py` case for a change, repeating an established UI component call (`TA.Modern:SectionHeader`, `DataRow`, `ActionButton`, and the rest) instead of hand-rolling a new one, and summarising a diff against the card's definition of done.
- **Never let Copilot invent the game.** It does not know whether an API exists on Forever, Mists, or TBC. Any API it proposes is UNVERIFIED until Chronicler checks it or a probe confirms it in-game. Reject unguarded API calls, Lua newer than 5.1, and any code that wipes or rewrites SavedVariables data instead of backfilling it.
- **Tests before trust.** After accepting a change, run `python Tools/check_lua.py` and the relevant `Tools/test_*.py` locally. The person running Copilot pastes the result into the team chat — Copilot cannot post to team chat itself. Copilot's confidence is not a test result.
- **Commits stay bite-sized.** Commit per card, naming the feature and its test status. No squashing several cards into one "misc fixes" commit, and never commit directly to `test` or `main`.

### Code snippets from Claude, Kiro, Gemini, and Muse (added Nov 11, 2026)

Christopher may bring in code snippets from outside the Grok team — from Claude, from Kiro, from Gemini, and Muse may assist with snippets as well. A snippet's origin does not change its status: outside code is a proposal, not a delivery. Claude Code and Kiro are archived as builders; their snippets, if Christopher brings them, go through exactly the same gates below.

- **In through Conductor.** Every snippet arrives through Conductor, who logs it against a Kanban card — or creates the card, in Questions, if none exists. Snippets are never pasted straight into the working tree, and never straight to `test` or `main`.
- **Attributed to its source.** The card and the eventual commit note the source — Claude, Kiro, Gemini, or Muse — and what the snippet is meant to do, in one line. Unattributed code does not get integrated.
- **Same gates, no exceptions.** Warden reviews it against `AGENTS.md`, Glitch runs the offline tests and writes the in-game checklist, Gilder clears it if it touches visuals, and Christopher verifies it in-game. A snippet from a trusted agent skips none of these.
- **Adapted, not transplanted.** Riley integrates the snippet into the module pattern and the flavor's profile and ApiGuard gates, in the smallest commit that works. If it collides with work already in flight, Conductor flags the collision to Christopher before anyone merges.
- **Rejected snippets stay on record.** If a snippet fails a gate, the card records what failed and why, so the same code is not re-proposed as new.

### Test status template and prompt for validation — for Sirc (added Nov 11, 2026)

Conductor keeps this section current. Each bot updates its own work as soon as its state changes — not at the end of the day from memory. If it is not recorded here, the team treats it as not settled.

```markdown
## Test status
- PR #62 / G01 — Experimental Mage 10-19 spell guide (Forever), test @ c9c5308 — offline checks: CI green, 425/425 hashes match, no deletes, SavedVariables identical; Glitch/Warden/Gilder GOs, Chronicler fact confirmation — rules review: clear — visual review: Gilder GO (copy/art) — in-game verified by Christopher: NO, awaiting Sirc's Spells check: Reload UI → Spells; Module Health / Error Log copy windows; learned/unlearned/rank redraw; explicit selector; wand states

## Done
- (none yet — first Done entry is PR #62's go from Sirc)

## In progress
- PR #62 / G01 — Mage acceptance live check — owner: Sirc — branch: test @ c9c5308 — what is left: Sirc's in-game check (see above)
- PR #58 — Forever reputations — merged to test Nov 8 — in-game verification pending
- PR #59 — Forever profession dedup — merged to test Nov 8 — in-game verification pending
- PR #61 — Manual profession batch calculator — merged to test Nov 8 — in-game verification pending
- PR #63 — merged HANDOVER committed, .pkgmeta fixed; owner Riley; merge waits on Sirc's direct word or GitHub click — since Nov 11, 2026

## Waiting on Sirc
- PR #62 / G01 live check (Spells tab) — waiting since Nov 9, 2026 (installed 8:21 PM)
- Buttons in-game sighting — waiting since Nov 11, 2026
- CurseForge/Wago secrets check — waiting since Nov 11, 2026
- PR #58 / #59 / #61 in-game verification — merged to test Nov 8, waiting since Nov 8, 2026

## Blocked / waiting on a decision
- (none)

## Next
- G03 Attack provenance, then G02 labels (First tasks 2 and 3)

## Team changes proposed
- (none)
```

Three rules keep it trustworthy: **no update here, no handoff**; **done means tested** — built but untested stays in progress; and **never rewrite history to look clean** — a failed test, a reverted change, and a wrong guess stay in the record, with what was learned. Every status line carries a date and who updated it; Conductor owns the Done transition on Sirc's go.

**Prompt for validation — addressed to Sirc.** Before any roadmap item is called finished, Conductor puts this to Christopher and waits for the answer. The team does not mark its own work validated. In-game checks follow the Guardrails.

> **Christopher — validation check.** For [feature / task] on [branch, targeting `test`]: offline checks [passed / failed — detail], Warden's rules review [clear / returned — detail], Gilder's visual review [clear / n/a], and Glitch's checklist is [attached / not yet written]. What this does not yet prove: [anything only the game can show]. Please reload the UI, open ToonAge on [client — Forever first], and run the check Glitch wrote (buttons and copy window, per the Guardrails — SavedVariables backup first) and confirm: does [expected result] happen? Then copy the diagnostics from the copyable window and paste them back. Reply go, no-go, or go with changes — the card moves to Done only on your go.

**Daily summary (not a freeze).** Once a day, in the evening, Conductor collects status from every bot and updates this record: what shipped, what stayed behind and why, what is waiting on Sirc (with dates), and what is first tomorrow. The summary never freezes building — verified work is pushed when verified. At each release, Conductor also re-reads the workflow sections above and proposes fixes to Sirc — the workflow gets reviewed, not just followed.
