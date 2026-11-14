# ToonAge — Agent instructions

Standing instructions for every bot working on ToonAge. Christopher (Sirc / Sirc146) is owner and final authority. The repo https://github.com/Sirc146/ToonAge on `test` is the single source of truth. Box copies, including `/workspace/toonage-docs/`, are drafts only until he approves them and they are committed.

Sister files: [README.md](README.md), [docs/HANDOVER.md](docs/HANDOVER.md), [docs/HISTORY.md](docs/HISTORY.md), [docs/architecture.md](docs/architecture.md).

## Purpose and non-goals

**Purpose:** ToonAge is a multi-client WoW addon (shared Lua engine, per-client data/modules/TOCs, Python verification, and observed client data feeding advice). Help Sirc ship optional, skippable, sourced guidance — what, why, alternatives — so a player who does not know yet can tune their own playstyle. Readouts are not the same as reliable personalized guidance.

**Non-goals:** Do not automate gameplay, spend talents, respec, buy, navigate, or collect other players' personal data. Do not duplicate Zygor or WowUp, or rebuild aura engines, boss mods, or quest-guide systems. Do not invent stat weights, timings, or Retail imports. Do not treat Harvest observations as finished advice. Do not silently change branches, settled decisions, or Talents artwork.

## When to use

Use these instructions whenever you plan, code, review, research, install, document, or test ToonAge. Plan with Conductor and read the repo files below before any of that work. If the file or evidence is inaccessible, ask a concrete question; do not guess. A plan, static GO, or relayed approval is not blanket authority. Native approvals must be received directly where required.

## Read-first rule

Every bot reads `AGENTS.md`, `docs/HANDOVER.md` and `docs/HISTORY.md` **from the repo** (Sirc146/ToonAge, `test`, unless Sirc names another approved ref) before working, and records its own part in `docs/HANDOVER.md` afterward **as a commit**: dated scope/card, source/head, changes, tests, review, merge/install state, blockers and next step. Check `docs/HISTORY.md` before retrying something that may already have been tried. Box copies are drafts only and are not the source of truth.

Christopher: **“I'd rather have everything working off git.”**

## Inputs, outputs, and done criteria

**Inputs:** An approved scope, the exact repo head/ref, official sources, and (for game measurement) Sirc’s own backed-up SavedVariables plus button/copy-window evidence. Preserve Sirc’s exact words; do not turn historical permissions into new ones.

**Outputs:** Small, reviewed feature-branch commits/PRs that target `test`; dated HANDOVER entries; existing test-command results with counts, SHA and exceptions. No large unrelated rewrites.

**Done:** Applicable offline/review gates and Sirc’s recorded scenario acceptance, or an accepted research deliverable. Installed is not live-verified. Merged is not launch GO. Stage 5 only for passed exact scenarios.

Christopher’s workflow after a change is live-tested, verbatim:

> After each verified test and its working it's pushed up

That means: change → Sirc’s live test passes → push to the repo promptly as a small commit and record the result in `docs/HANDOVER.md`. Release tags still need his explicit approval. Docs and code changes go in as their own commits so one can be rolled back if needed.

README.md and docs/HANDOVER.md are updated in the same push after each verified test.

## Standing rules (imported) — November 9, 2026, 8:19 PM PST

Source: standing-rule handoff relayed through Riley. The underlying memory file was not independently opened for that handoff. Supplied wording retained verbatim:

- Diagnostic output goes in a copyable window, never in chat. Never ask him to run /dump or /run probes; in-game checks are ToonAge buttons.
- He prefers in-addon buttons over slash commands.
- Back up SavedVariables before every test, and confirm the installed build equals trunk before measuring.
- Go/No-Go launch gates: 0 fails, every warning triaged, and a clean error log after real play.
- Release tags only with his explicit approval.
- Verify every API per client; nothing carries over from Retail by assumption.
- Diagnose before coding, in this order: install freshness (repo_status.ps1, build_flavors.ps1 -Check), version stamp, cross-client differential, /ta health, /ta errors, git log.
- Scores are numbers out of 10, never labels. The scorecard currently uses 0-5 completion stages; keep those, but add a /10 score per category.
- Preserve his words verbatim. Mark anything uncertain as UNVERIFIED or UNKNOWN. Include dates. Don't change settled decisions.
- Complete outputs with no placeholders.
- Keep it terse; 'deep:' means expand.
- He runs backup PowerShell commands himself, with each command explained.
- He uses Zygor and WowUp; don't duplicate them.

**Button interpretation:** use **Module Health**, **Error Log**, **Run Self-test** and relevant Harvest buttons; diagnostic results stay in copyable windows. Labels were source-checked at `Settings.lua:839–843`; `Core/Init.lua:1580–1587` forces the health window. Historical slash labels in the quotation are report names, not instructions to type them. Missing button/window = UNKNOWN/blocked, never a probe workaround.
**Before EVERY individual game test:** Sirc runs his own explained SavedVariables backup command, verifies baseline harvest counts and installed files/version against the agreed trunk, then measures. A suspiciously small save or dropped counts is stop/no-go. Do not clear logs/data to manufacture a pass. Native panels/action-bar buttons are normal comparisons, not typed diagnostic Lua.
**Freshness order:** approved root/ref → `Tools/repo_status.ps1` and `Tools/build_flavors.ps1 -Check` → version stamp → cross-client differential → Module Health button → Error Log button → Git history. The scripts exist; `-Check` is report-only. `repo_status.ps1` can fetch/compare remotes/build temporary output and assumes `main`; confirm mapping first. No PC scripts were run here.
**Launch gate:** 0 fails, every warning triaged and any accepted risk approved, clean error log after real play. A previous 0-fail/32-warning scan is not launch GO. No secrets, `WTF` or SavedVariables in public packages.
**Scores:** keep stages **0 none, 1 researched, 2 specified, 3 prepared/reviewed, 4 installed, 5 verified in game**. Numeric /10 delivery index = 2 × named stage; prepared index likewise. This is ordinal evidence, not quality, percentage or effort. Merged is separate; no overall average. Installed bugs can be stage 4 and still fail acceptance.

## Data rule

Official Blizzard first, then Wowhead, Icy Veins, warcraft.wiki.gg and Forever-specific sources. Keep source URL/date/client/build/hotfix, identity, rank, acquisition and tactical claims separate. Exact current live observations outrank mismatched-version assumptions; official effective hotfixes can supersede raw-build fields.
**Keep verified ours · use better sourced fields · add supported gaps · remove proven inaccurate current-target claims with evidence · leave merely unverified items unresolved.** Preserve accurate constituent fields and historical audit evidence; no silent discard. Specific conflicts go to Sirc, not majority vote. Mark uncertainty **UNKNOWN/UNVERIFIED** and do not change settled decisions.

## Guardrails and constraints

- **Approval gates:** Sirc approves scope, specs, merges, installs, releases and accepted risks. Wait for applicable approval before PR/merge/install/release. Do not contact another bot just because a plan names it.
- **Backup before every test:** Sirc runs the explained SavedVariables PowerShell himself. Confirm installed files/version against the agreed trunk before measuring.
- **No release tags** without Christopher's explicit approval.
- **Copyable windows, not chat.** In-game checks are addon buttons, never `/dump` or `/run`.
- **Forever first** for current work. Never edit `_retail_/Interface/AddOns/ToonAge/` as a Forever fix, and never let Retail data/modules pollute another client. Approved Forever install is only `build_flavors -Install`, never the all-client release ZIP or `Update-ToonAge.ps1`. Do not use `Tools/deploy.ps1` as a Forever shortcut.
- **Official sources first;** flag UNVERIFIED. Outside URLs only as labeled read-only sources (Blizzard, Wowhead, Icy Veins, warcraft.wiki.gg, and Forever-specific sources).
- **Only Christopher's own locations.** Project paths must be his. Box-local evidence is not automatically in GitHub; transfer only with explicit approved scope.
- **No tokens or personal data.** Never collect tokens. The WowUp token expired November 7 as exported; later regeneration UNKNOWN. Sirc regenerates and pastes it into WowUp settings himself, never in chat. Distinct imported label “WOWUP. IO” paste confirmation and “Courier-Utility” PAT purpose/authorization remain UNKNOWN; no token requested, read, changed or automatically revoked.
- **Verify every API per client** against official docs/FrameXML and https://warcraft.wiki.gg/wiki/World_of_Warcraft_API. Retail evidence does not certify Forever. Never bypass refusal with arithmetic, conversion or UI pass-through. Use synthetic, nonpersonal fixtures.
- **Preserve Talents art,** geometry, textures and visual identity. Gilder’s visual GO is required for visual changes.
- Do not invent a weight, timing, full SHA or live pass.

## Minimal working example

In-game check (preferred). After Sirc has run his own explained SavedVariables backup and confirmed the installed build equals the agreed trunk, he clicks **Reload UI**, then **Spells** (or **Module Health** / **Error Log**). Diagnostic text stays in a copyable window. That is a complete check. Do not ask him to type `/ta health`, `/run` or `/dump` — those slash labels in the standing-rule quotation are historical report names.

Report-only freshness, only after Sirc has confirmed trunk mapping (currently UNKNOWN; some scripts assume `main`) and approved the root/ref:

```powershell
# Report only: compare installed clients to the agreed trunk. Does not install or change files.
Tools/build_flavors.ps1 -Check
```

Do not run install commands, `deploy.ps1` or PC scripts without applicable approval. No PC scripts were run for this documentation draft.
