# ToonAge — Master README & Living Work Tracker

> **Single Source of Truth** to prevent duplicate work across sessions, branches, and flavors.
> Update this file whenever a phase lands, a bug is fixed, or a milestone changes status.
> Never put private names, character names, personal PC paths, or secrets here (`Tools/check_pii_hygiene.py` enforces this).

- **Project:** ToonAge (`Sirc146/ToonAge`, GitHub · CurseForge `1734520` · Wago `56ndnjG9`)
- **Version:** `v2.0.0-dev.1` · **Language:** Lua 5.1
- **Lead Client:** **WoW Forever** (`1.60.1`, build `71037`, interface `16001`, `ToonAge_Camelot.toc`)
- **Other Supported Flavors:** Retail (`ToonAge_Mainline.toc`), TBC Anniversary (`ToonAge_TBC.toc`), Mists Classic (`ToonAge_Mists.toc`), Classic Era (`ToonAge_Vanilla.toc`), Cata (`ToonAge_Cata.toc`), Wrath (`ToonAge_Wrath.toc`)
- **Last Verified State:** `2026-11-21` · HEAD `antigravity/phase8-loot-watch-and-libraries` (`87` automated test suites · `8/8` TOCs parse clean · `0` PII/hygiene findings across `485+` files)

---

## 1. Standing Rules (Non-Negotiable)

1. **Owner Approval Gate:** Only **the owner's direct word** approves pushes to GitHub, merges to `test`/`main`, flavor installs (`build_flavors.ps1 -Install`), deletions, or release tags (`v*`).
2. **Never Touch `_retail_`:** Only install to `_forever_` when testing Forever work; keep `_retail_` untouched unless explicitly instructed.
3. **Read-Only Honesty:** Never spend talent points, cast protected spells, modify Blizzard action buttons, or invent stat weights / fake BiS / raid-sim DPS scores. Mark uncertain facts `UNVERIFIED` or `UNKNOWN`.
4. **Strict Forever `1.60.1` API & Pool Invariants:**
   - Every `C_<NS>.<Method>` call in `ToonAge_Camelot.toc` MUST exist in `Data/Forever/ApiManifest.lua` (`Tools/test_enginegate.py`).
   - Guard combat-secret values with `issecretvalue` / `canaccessvalue`.
   - Only call `SetScript("OnClick", ...)` on `Button` objects (never `Frame`).
   - Reused tab frames MUST set `_laKind` (`0` `CreateFrame` churn on pass 2; `CountDescendants(content) == 0`).
   - Regenerate `Core/Init.lua` event routes via `python Tools/gen_event_routes.py` whenever adding events to `M.Events`.
5. **Hygiene:** Zero emojis in `.lua`/`.py`, zero `TODO`/`FIXME` placeholders, zero PII or personal PC paths (`Tools/check_pii_hygiene.py`).

---

## 2. Active Branch Stack (All Local / Unpushed Pending Owner Word)

Base: `origin/test @ 6eeb530` (do NOT drop/pop `stash@{0}`; do NOT rebase/force-push shared branches).

| Phase | Branch | Commit | Status | Summary |
|---|---|---|---|---|
| **1a** | `antigravity/phase1a-modern-azeroth-tokens` | `af313cc` | Done (local) | `Core/Theme.lua` Modern Azeroth tokens, 3 theme packs (`class` default, `toonage_gold`, `blizzard`), reduced motion, classic fallback |
| **1b** | `antigravity/phase1b-talents-plan-dock` | `f23608f` | Done (local) | Read-only Talents Plan Mode (`NodeDetail`, `PlanRoute`, `WhatIfRank`, `GetNextPlannedPoint`, pooled `TATalentDetailDock`) |
| **2** | `antigravity/phase2-modern-azeroth-shell` | `e1900ae` | Done (local, live-verified) | 68px Liquid Glass shell (`UI.lua`/`UIModern.lua`), 7 TGAs, `Now` lead tab, Settings drawer auto-fit + Appearance packs, Reputation standing bars, 2-col Professions batch UI, `Talents` `OnClick` Frame-vs-Button fix, `Media\glass` in `build_flavors.ps1` |
| **3** | `antigravity/phase3-talents-intelligence` | `1b19f9f` | Done (local) | `TalentIntel.lua`: Spell-Filter Pills + spotlight dimming, `Lxx` unlock badges, Sandbox (`+1/-1`, Shift/Right-Click, 51-pt cap), Multi-Milestone Roadmap, `Solo`/`Dungeon`/`PvP` Saved Plans -> `Now`, live tooltip Math + `Casts` + `Gear` dock callouts |
| **4** | `antigravity/phase4-inline-cleanup-pins` | `749c3dc` | Done (local) | Removed legacy Character popup row; inline XP/hr + ETA on Experience bar; inline `Since` delta on `Now`; inline `Gathering log` on `Professions`; filtered `"Attack Rank 1"`; toggle-to-clear Library & Light Feathers pins on `Scrolls` + auto-learn `Study` spots |
| **5** | `antigravity/phase5-spells-playbook` | `aa34b8e` | Done (local) | `SpellPlaybook.lua`: replaced Lv 10-19 Mage experimental disclaimer wall with working 9-class, Lv 1-60 Playbook (`Single Target`/`Opener`/`AoE`/`Emergency`/`DPS & DPM`, Spec cycler, live buff/wand checks, Casts & Trainer tags) |
| **6** | `antigravity/phase6-pvp-readiness` | `c68db43` | Done (local) | `PvP.lua` v2: Live Status/Flag/Timer/Zone/BG banner + `Now` Priority 1 alert, Forever BG brackets (incl. 15v15 Darkspear Islands), Readiness checklist (trinket/consumables/plan slot), untruncated utility racials, live spellbook CC counter map, Target Dossier |
| **7** | `antigravity/phase7-rubric-v2-and-hygiene` | `1bbaddb` | Done (local) | Unified Master Rubric v2 (`Docs/AUDIT_RUBRIC.md`, Part 1 + Part 2 Sections A-L + filled Forever/Remix professions matrix), `Tools/check_pii_hygiene.py`, `Tools/score_rubric.py`, `Tools/test_rubric_tools.py`, fixed TZ-flaky `test_harvest_capture.py` |
| **8** | `antigravity/phase8-loot-watch-and-libraries` | `b33fca7` | Pushed to `origin` (installed `_forever_`) | `LootWatch.lua`, all-continent Study libraries, regenerated `EVENT_ROUTES`, `MEDIA.md` (102 TGAs), `MASTER_README.md` |
| **9** | `antigravity/phase9-roadmap-backup-reagents` | *in progress* | Local (Roadmap `1.2` + `2A`) | Pre-install SavedVariables auto-backup in `build_flavors.ps1` (last 10 snapshots under `%LOCALAPPDATA%\ToonAge\Backups`); verified Forever reagent IDs `17020`/`17031`/`17032` in `Data/Forever/Reagents.lua` (0 `UNKNOWN` rows on Scrolls) |

---

## 3. Forever Tab & Module Ownership Map (Do Not Duplicate)

| Tab / Feature | Primary Files | Shared Data / Cross-Tab Feeds |
|---|---|---|
| **Shell & Theme** | `Core/Theme.lua`, `Core/UI.lua`, `Core/UIModern.lua`, `Core/Layout.lua` | Drives all tabs; Settings Appearance switcher updates live |
| **Now (Lead Tab)** | `Modules/Forever/Now.lua` | Pulls from `ForeverSessionCheck:Summary`, `ForeverRotation:TrainableNow`, `ForeverTalents.GetNextPlannedPoint`, `ForeverPvP.GetAlert`, `ForeverCharacter`, `DataHarvester` |
| **Character** | `Modules/Forever/Character.lua` | 3D portrait sidebar (`RenderSidebarPublic` shared across tabs), inline `XPTracker` rate/ETA, stats, weapon/Defense skills |
| **Gear** | `Modules/Forever/Gear.lua`, `StatPriority.lua`, `GearAdvice.lua` | Equipped totals, upgrade arrows, defers to Polestar/Pawn via `AddonBridge` |
| **Professions** | `Modules/Character/ProfessionBoard.lua`, `ProfessionSkills.lua`, `ProfessionBatch.lua` | 2-col batch calculator + inline `GatherTracker:GetSummary` Gathering log |
| **Reputation** | `Modules/Progression/FactionTracker.lua` | Standing colors/badges, client group headers, in-tier progress bars |
| **Talents** | `Modules/Forever/Talents.lua`, `Modules/Forever/TalentIntel.lua` | Pooled tree, Filter Pills, `Lxx` badges, Sandbox/Saved Plans (`TA.charDB.talentPlans`), live Math/Casts/Gear dock |
| **Spells** | `Modules/Forever/SpellPlaybook.lua`, `Rotation.lua`, `MageSuggest.lua`, `MageGuidance.lua` | 9-class Playbook, live buffs/wand, Tooltip DPS & DPM, Trainer Due, Bar Rank Check, optional research draft toggle |
| **PvP** | `Modules/Forever/PvP.lua` | Live flag/zone/BG context, Forever brackets (WSG/AB/Darkspear/AV), trinket/consumables readiness, spellbook-aware racial clashes, Target Dossier |
| **Scrolls** | `Modules/Forever/Scrolls.lua`, `Restock.lua`, `Pins.lua` | Tooltip-parsed scroll verdicts, Comprehension (`3012`), reagent restock, toggleable nearest Library & Light Feathers AH pins + Study auto-learning |
| **Casts** | `Modules/Forever/CastLog.lua` | Out-of-combat fight cast recorder (feeds `TalentIntel` & `SpellPlaybook`) |
| **Harvest** | `Modules/Infrastructure/Harvester.lua`, `Modules/Harvest/*` | Client data recorder & export (`Data/Forever/*.lua`) |
| **Dungeon Loot Watch** | `Modules/Forever/LootWatch.lua` | Private pooled toast (`TALootWatchToast`, `/ta lootwatch`, Settings toggle), resets per run |
| **Settings** | `Modules/Infrastructure/Settings.lua` | Auto-fit drawer, Appearance packs, Loot Watch toggle/preview, Quick Actions |

---

## 4. Rubric v2 Baseline Scores (Verified `2026-11-21`)

Full criteria, weights, and hard fails live in [Docs/AUDIT_RUBRIC.md](AUDIT_RUBRIC.md). Run `python Tools/score_rubric.py` anytime to re-measure Part 1.

- **Part 1 (Addon & PR Quality):** **9.5 / 10.0** (Merge Bar `>= 8.0`: **PASS** · `0` Hard Fails · `8/8` TOCs · `87/87` test suites · `0` PII findings)
- **Part 2 (Forever `1.60.1` Character & Game Data):** **7.5 / 10.0** (Strongest: Racials `9.5`, Live Telemetry `9.5` · Biggest upside: Enchants `5.0`, Consumables/Reagents `6.0`, Reputation unlocks `6.5`, Multi-class SpellRanks `8.0`)

---

## 5. Roadmap to 10 / 10 (Working Queue)

Check items off here as they complete so nothing is rebuilt twice.

### Part 1 — Addon & Engineering (`9.6 -> 10.0`)
- [ ] **1.1 Live In-Game Sign-Off (Phases 4–9 on Forever):** Owner runs `/reload`, `/ta lootwatch`, tests `Scrolls` (0 `UNKNOWN` reagents + nearest library pin), checks `Spells`/`PvP`/`Now`/`Character`/`Professions`, and runs `/ta test` (`0 fail / 0 leaks`) -> Criterion `#1` `9.0 -> 10.0`.
- [x] **1.2 Automatic Pre-Install SavedVariables Backup:** Added timestamped `WTF\Account\*\SavedVariables\ToonAge*.lua` backup (last 10 snapshots in `<WoW>\ToonAge_Backups\<client>\`) before `-Install` in `Tools/build_flavors.ps1` -> Criterion `#8` `9.0 -> 10.0`.
- [x] **1.3 Living State Sync:** Created canonical `Docs/MASTER_README.md` and synced `Docs/STATE.md` -> Criterion `#12` `9.0 -> 10.0`.
- [x] **1.4 Feature Branches Pushed to GitHub (`origin`):** Pushed `antigravity/phase1a-*` through `antigravity/phase8-*` to `Sirc146/ToonAge` (`test`/`main` untouched pending owner merge approval).
- [ ] **1.5 Approved PR Merges & Release Tag:** Merge approved PRs into `test` and tag `v*` on owner's direct word -> `#10` & `#11` `-> 10.0`.

### Part 2 — Forever `1.60.1` Character & Game Data (`7.8 -> 10.0`)
- [x] **2A. Reagents & Consumables Data (`G: 6.0 -> 8.5`):** Verified Forever item IDs against `db.icy-veins.com/wow-forever/items/*` for `Arcane Powder` (`17020`), `Rune of Teleportation` (`17031`), and `Rune of Portals` (`17032`) in `Data/Forever/Reagents.lua` — zero `UNKNOWN` rows on `Scrolls`! *(Remaining for `9.5`: campsite buff stacking & expanded First Aid potions catalog.)*
- [ ] **2B. Forever Enchants & Faction Rewards (`J: 5.0 -> 9.0`, `F: 6.5 -> 9.0`):** Add sourced Forever enchant recommendations per slot/role (incl. enchanter-crafted relics) and Darkspear Islands / Classic faction reward unlocks in `Data/Forever/`.
- [ ] **2C. Multi-Class Spell Ranks & Generalized Live Combat Suggest HUD (`B: 8.0 -> 9.5`, `L: 9.5 -> 10.0`):** Harvest trainer rank chains for the remaining 7 non-Mage classes into `Data/Forever/SpellRanks.lua`; generalize `MageSuggest.lua` into a spec-aware live Combat Suggest HUD (Arcane/Fire/Frost first, then all 9 classes) with an in-tab toggle on `Spells`.
- [ ] **2D. Live Client Probes for PvP Currency & Profession Skill IDs (`K: 7.5 -> 9.5`):** Probe `C_CurrencyInfo` (Honor / Rank Points IDs), `GetBattlefieldStatus`, and primary profession skill-line IDs on live Forever `1.60.1` to unlock live Honor/Rank bars on `PvP` and flip `ProfessionSkills.lua` from `unverified = true` to verified.
- [ ] **2E. Optional Google Docs Mirror:** If Google Docs plugin is connected later, sync this file's sections to a read/review mirror in Google Drive while keeping `Docs/MASTER_README.md` as the git source of truth.

---

## 6. Verification Commands (Local Windows — Python 3.12)

```powershell
# Syntax check all TOCs
python Tools/check_lua.py --toc ToonAge_Camelot.toc

# Full Rubric v2 Part 1 automated scorecard (all 8 TOCs + all test suites + PII scan)
python Tools/score_rubric.py

# Fast Forever scorecard
python Tools/score_rubric.py --quick

# PII & hygiene scan only
python Tools/check_pii_hygiene.py

# Regenerate Core/Init.lua event routes after editing any M.Events table
python Tools/gen_event_routes.py

# Install & verify Forever ONLY (never run without owner approval; never touch _retail_)
.\Tools\build_flavors.ps1 -Flavor Forever -Install
.\Tools\build_flavors.ps1 -Flavor Forever -Check
```
