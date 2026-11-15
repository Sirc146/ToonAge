# ToonAge — Architecture

Clients, TOCs, module layout, the dual-gate rule, and API-probe facts already verified in the shared record. This is not a claim of all-client live certification. Current delivery and the plan are in [HANDOVER.md](HANDOVER.md). Bot rules are in [AGENTS.md](../AGENTS.md).

**Audit baseline:** `4555883f13a34f911628ea5946c7e5c316e1ae3e`. **Latest reported installed merge:** `c9c5308a`; source/docs tree read on `test` in the November 9, 2026 documentation pass. Runtime ZIPs omit `.git`, `.github`, `Tools` and `Docs`: they are not development checkouts or the approved Forever install method.

## Module layout

| Area / real paths | Interaction / boundary |
|---|---|
| `Core/Init.lua`, `Environment.lua`, `Profile.lua` | Creates `TA`, DB/events/module registry; client/TOC detection and profile allow-lists. TOC load order matters. |
| `Core/Compat/API.lua`, `ApiGuard.lua`, `Caps.lua` | Guarded per-client API and recorder capabilities; do not confuse manifest absence with an unguarded crash. |
| `Core/State.lua`, `Utils.lua`, `UI.lua`, `UIModern.lua`, `Layout.lua`, `Theme.lua` | Shared state/UI/helpers; retain art, geometry, frame reuse and honest unavailable states. |
| `Core/TooltipScan.lua`, `SkillScan.lua`, `StatEngine.lua`, TBC helpers, `Analytics.lua`, `MinimapButton.lua` | Existing support modules; file presence is not all-client or feature certification. |
| `Data/Forever`, `Retail` (including Midnight/Guides), `TBC`, `Mists`, `Vanilla`, `Shared` | Flavor data. Forever Coach/legacy RotationLists do not prove role-aware learned-state guidance. Retail data/modules must never pollute another client. |
| `Modules/Forever/Rotation.lua`, `MageGuidance.lua`, shared `Infrastructure/RotationLists.lua` | Spells/Training and installed Mage slice; legacy static fallback is not a complete adaptive curriculum. |
| Forever Character/Gear/Talents/Pets/PvP/Scrolls/CastLog/SessionCheck/WorldRefresh | Flavor views; only the observed visible tabs are established. |
| `Modules/Character/ProfessionSkills.lua`, `ProfessionBoard.lua`, `ProfessionBatch.lua` | Skills → profession view; manual batch calculation. Ownership ingestion/bank/AH are separate gaps. |
| `Modules/Progression/FactionTracker.lua` | Native visible reputation rows; preserve collapsed-header state. |
| `Modules/Harvest/Domains`, `Packs/Forever.lua`, `Infrastructure/Harvester.lua`, `HarvestFormat.lua` | Captures spellbook/catalog/trainer/items/traits and other observed domains; not every domain loads on Forever. |
| Other module folders | Combat, Gear, Automation, Farming, Navigation, Mists, TBC and Infrastructure; inspect current gates before use. |
| `Media`, `Libs`, `Docs`, `Tools`, `Bindings.xml`, `.pkgmeta`, `.rules.md` | Art, libraries, docs and dev tools. CI uses `.github/workflows/ci.yml`, `release.yml`, `wago.yml`; inspect existing instructions without executing stale probes. |

`TA:RegisterModule`, `Init`, `OnEvent`, `Render` and guarded `TA:GetModule` calls are the shared pattern. TOCs declare `ToonAgeDB`/`ToonAgeGuard`; character state uses existing helpers including `TA.charDB`. Backfill defaults/migrations, never wipe data. Lua 5.1-compatible harness, event-driven updates and reusable frames; parse success does not prove API or live UI correctness.

## Dual-gate rule

Packaging and runtime eligibility both matter. Runtime file presence cannot bypass profile/client gates; the historical G3 gap still needs reconciliation. Dual-gate wording retained verbatim:

**“the TOC file is the packaging backstop (what actually gets loaded), and Core/Profile.lua is the runtime backstop (what is allowed to initialize).”**

Retail data/modules must never pollute other clients.

## Clients and TOCs

| TOC | Interface(s) | X-Flavor / boundary |
|---|---|---|
| `ToonAge_Camelot.toc` | 16001 | Forever; only baseline TOC loading ProfessionBatch; MageGuidance at line 178 in installed package. |
| `ToonAge_Mainline.toc` | 120100, 120105, 120001 | Mainline, not Forever. |
| `ToonAge.toc` | 120100, 120105, 120001 | Fallback resembling Mainline, not universal. |
| `ToonAge_TBC.toc` | 20506 | TBC. |
| `ToonAge_Mists.toc` | 50504 | Mists. |
| `ToonAge_Vanilla.toc` | 11509 | Vanilla. |
| `ToonAge_Cata.toc` | 40402 | Cata. |
| `ToonAge_Wrath.toc` | 30405 | Wrath. |

Correct Forever flavor/TOC and ten visible tabs were observed November 9 at 7:36 PM PST. Do not rename the suffix, add 16001 to Mainline or load everything everywhere to mask uncertainty. Calculator widget interaction is still unverified.

## Installation boundaries

**Forever installation:** only `build_flavors -Install`, never the all-client release ZIP. Target pattern: `C:\Program Files (x86)\World of Warcraft\_<flavor>_\Interface\AddOns\ToonAge`; confirm the real client and avoid nested AddOns folders. The reported 8:21 PM install method is UNKNOWN, not presumed compliant.

`Update-ToonAge.ps1` was found locally, not in the pinned repo root/Tools or runtime ZIP. Historical capability audit: loops `_retail_`, `_forever_`, `_classic_beta_`, `_classic_`, `_anniversary_`, `_classic_era_`; refuses a running WoW; resolves then-current `test` SHA; backs up each existing client’s `WTF`, moves the old addon aside and skips `.git` destinations. It does not intentionally write settings back. It is multi-client, follows a moving branch, does not run CI/live tests and is not an atomic rollback system. **Not an approved Forever install path.** Its evidence path is in the HANDOVER evidence register.

`Tools/deploy.ps1` is not that method: its hierarchy assumptions and `robocopy /MIR` can be destructive. A historical updater could target several clients from a moving branch; it is not an approved Forever shortcut. Close WoW as appropriate, protect settings and use scoped authorization/rollback; no install commands were run here.

`release.yml` tags can publish GitHub/external releases; explicit Sirc approval is required. Package checks prove file presence, not client selection or live behavior.

## Existing test, syntax and package commands

Existing entry points, not permission to install dependencies or run anything on Sirc’s PC. Full development checkout required for Git-dependent tests; Python 3.12 matches CI, requirements are `luaparser` and `lupa`. All eight TOCs are checked by CI; 61 baseline suites, 62 reported after PR62. `Tools/ci-tests.yml` mirrors CI.

| Purpose | Existing command |
|---|---|
| Development dependencies (prefer a venv) | `python -m pip install -r Tools/requirements.txt` |
| Default TOC syntax only | `python Tools/check_lua.py` |
| Forever TOC syntax and missing-file check | `python Tools/check_lua.py --toc ToonAge_Camelot.toc` |
| Other client TOCs | Repeat `--toc` for every `ToonAge*.toc`; CI does all 8 |
| Specific file syntax | `python Tools/check_lua.py Modules/Forever/Rotation.lua` |
| All Lua files, including unlisted ones | `python Tools/check_lua.py --all` |
| Training/rank regression baseline | `python Tools/test_forever_rankcheck.py` |
| Legacy guidance-list regression | `python Tools/test_rotation_lists.py` |
| Reputation regression | `python Tools/test_faction_tracker.py` |
| Profession dedup regression | `python Tools/test_profession_skills.py` |
| Calculator math / UI | `python Tools/test_profession_batch.py` and `python Tools/test_profession_batch_ui.py` |
| Talents baseline regression | `python Tools/test_forever_talents.py` |
| Character / known Forever bugs | `python Tools/test_forever_character.py` and `python Tools/test_foreverbugs.py` |
| Shared compatibility / engine/profile gates | `python Tools/test_compat.py`, `python Tools/test_enginegate.py`, `python Tools/test_profile.py`, `python Tools/test_toc_set.py` |
| Full regression | Run each `Tools/test_*.py` exactly as `.github/workflows/ci.yml` does; 61 suites at baseline |
| Release-layout regression (requires `.git`) | `python Tools/test_release_zip.py` |
| Runtime ZIP completeness | `python Tools/check_release_zip.py /workspace/ToonAge-test-c9c5308.zip` |

`Tools/test_mage_level12_guidance.py` belongs to PR62/current Mage path. `test_forever_vitals.py` is PR57-specific, not a baseline suite. No configured luacheck/stylua/npm test target was established. Keep final command output, counts, SHA and exceptions; never claim a green suite from a fixture that never failed for the intended bug.

## API-check rule

Inspect Compat/Caps/Profile/ApiManifest before a call. Verify existence, arguments, return shape, events and secrecy on the exact client via Blizzard docs/FrameXML and https://warcraft.wiki.gg/wiki/World_of_Warcraft_API. Retail evidence does not certify Forever. Never bypass refusal with arithmetic, conversion or UI pass-through. Use synthetic, nonpersonal fixtures.

## Missing-API audit — exact baseline call sites

These are the 17 manifest absences; **no unguarded loaded call found**. Guards do not certify arguments/returns or other clients. Detailed inventory: `API-GUARD-AUDIT.md` and `live/direct-api-call-sites.json`. Live-fix context (November 9, 2026, 7:36 PM PST export): ApiGuard 93/110 present, 17 absent; audit of 60 loaded Lua files/20 direct sites plus helpers found **no unguarded call for those 17**. Ten wrapper smoke cases pass. This does not certify semantics or all clients.

| Missing API | Pinned source call sites / helper trace | Result |
|---|---|---|
| `C_MerchantFrame.GetItemLink` | `Modules/Forever/Gear.lua:1231–1235`; local `Try:33–37` | Namespace/member guard; Try checks function type and pcall; legacy merchant fallback remains. |
| `C_Spell.GetSpellRank` | `Core/Compat/API.lua:892–893`; `Modules/Harvest/Domains/Spellbook.lua:189` → `Harvester.lua:1221–1230` → `Caps.Fn` | Type guard or safe path resolver; absent rank API is not absence of rank data. |
| `GetItemInfo` | `Core/Compat/API.lua:266–271`; `Core/Utils.lua:380,783–785`; `Forever/Gear.lua:85,240` | Compat prefers C_Item, then type-checked global. Utils uses Compat; Gear passes optional global through checked Try. |
| `GetItemStats` | `Core/Compat/API.lua:367–373`; `Core/Utils.lua:909`; `Forever/Gear.lua:98` | Same checked modern/legacy fallback; missing result returns nil/empty presentation, not an unguarded global call. |
| `GetNumSkillLines` | `Modules/Forever/Scrolls.lua:199–205` | Both legacy functions type-checked before pcall; native C_SkillInfo preferred. |
| `GetSkillLineInfo` | `Modules/Forever/Scrolls.lua:199–205` | Same guard. |
| `GetNumTalentTabs` | `Core/Compat/API.lua:448–455,475–477` | `HasTalentTabs` rejects Forever, checks globals; pcall path also gated. |
| `GetTalentInfo` | `Core/Compat/API.lua:463–466` | Forever return + function-type guard. |
| `GetTalentTabInfo` | `Core/Compat/API.lua:448–460,482,887` | HasTalentTabs guard or explicit type+pcall probe. |
| `GetSpellCooldown` | `Core/Compat/API.lua:159–170` | Modern C_Spell preferred; global type-checked. Utils delegates to Compat. |
| `GetSpellInfo` | `Core/Compat/API.lua:125–129,143–156` | Name fallback truthiness guard; main info fallback type guard. Modern C_Spell path exists separately. |
| `GetSpecialization` | `Core/UI.lua:180–184,205–207` | Mists+type guards or paired truthiness guards in Retail-only helper; absent nil is safe. |
| `GetSpecializationInfo` | `Core/UI.lua:180–184,205–207` | Same paired guards. |
| `GetSpellLevelLearned` | `Core/Compat/API.lua:891`; `Harvest/Domains/Spellbook.lua:185–186` → checked probe | Type+pcall or safe resolver. **Missing bare global is not missing `C_Spell.GetSpellLevelLearned`**, which actually answered in the live probe. |
| `UnitAttackBothHands` | `Core/Compat/API.lua:888`; `Modules/Infrastructure/Harvester.lua:1258` → `P.Call:1221–1230` | Type+pcall or Caps.Fn. |
| `UnitDefense` | `Core/Compat/API.lua:890`; `Modules/Infrastructure/Harvester.lua:1260` → P.Call | Same. Native `UnitDefenseSkill` answered separately. |
| `UnitRangedAttack` | `Core/Compat/API.lua:889`; `Modules/Infrastructure/Harvester.lua:1259` → P.Call | Same. |
