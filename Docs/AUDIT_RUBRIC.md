# ToonAge Master Rubric v2 — Addon & WoW Game Data

**Purpose:** One canonical scoring rubric for ToonAge, replacing the legacy multi-bot rubric and the older 2026-08-08 audit checklist.
- **Part 1** scores ToonAge code, PRs, installs, and releases (12 criteria, weighted to 100, with 7 hard fails).
- **Part 2** scores the WoW game guidance ToonAge shows: roles, specs, theorycrafting, races, reputation, consumables, content, gear, enchants/gems, professions, and live character telemetry across every WoW version.

---

## How to Score (Applies to Part 1 & Part 2)

```
Overall = sum(score * weight) / sum(weight of scored criteria)
```

1. **Check hard fails first.** Any hit makes the overall `0.0`. Stop there.
2. **Score each touched criterion `0` to `10`** (whole or half numbers) with linked tool or source evidence.
3. **Mark untouched criteria `N/A`.** Its weight drops out of the denominator.
4. **Compute the weighted overall** rounded to 1 decimal (`python Tools/score_rubric.py` automates Part 1).
5. **Compare to the merge / release bar.** Passing the bar is a recommendation; only **the owner's direct approval** pushes, merges to `test`/`main`, installs, deletes, or tags releases.

---

# Part 1: Addon & PR Quality Rubric

## Criteria and Weights

| # | Criterion | Weight | Objective Gate / Automated Tool |
|---:|---|---:|---|
| 1 | Multi-Flavor Stability & Live Health | 15 | `Tools/check_lua.py --toc` on all 8 TOCs + `build_flavors.ps1 -Check` + in-game `/ta test` (`0 fail`) |
| 2 | API Guards & Combat-Secret Safety | 10 | `Tools/test_enginegate.py` + `Tools/test_compat.py` + `issecretvalue`/`canaccessvalue` + `Frame` vs `Button` strictness |
| 3 | Tests, Mutate-Red Proof & CI | 10 | All `Tools/test_*.py` green (0 TZ-flaky tests) + new tests for changed behavior + mutate-red proof |
| 4 | Performance, Memory & Frame Pooling | 8 | `Tools/test_tab_frame_pools.py` + 0 `CreateFrame` pass-2 churn + `CountDescendants == 0` + 0 Blizzard taint |
| 5 | Data Honesty & Source Verification | 10 | Live client reads over guesses; source URLs cited; `UNVERIFIED` flagged; zero invented BiS/weights |
| 6 | Cross-Tab Cohesion & Deferral | 8 | Shared data loop (`Now` <-> `Talents` <-> `Spells` <-> `PvP` <-> `Casts` <-> `Gear`); `AddonBridge` deferral intact |
| 7 | UX, Modern Azeroth Craft & Zero Clutter | 10 | Token-driven (`Core/Theme.lua`), zero glass-on-glass, non-traffic-light controls, zero clipped text, inline over popups |
| 8 | SavedVariables & Migration Safety | 6 | `Tools/test_migrations.py` green; settings survive `/reload` & installs; backup before risky schema changes |
| 9 | Security, PII & Asset Licensing | 8 | `Tools/check_pii_hygiene.py` clean (0 secrets, personal paths, PII, emojis) + asset license provenance |
| 10 | Git Discipline & Owner Approval | 7 | One-topic feature branches; direct owner approval for push/merge/install/delete/tag; never rebase shared branches |
| 11 | Release & Packaging | 5 | `Tools/test_release_zip.py` + `Tools/check_release_zip.py`; `.pkgmeta` excludes dev/WTF; CurseForge + Wago parity |
| 12 | Docs & Living State | 3 | `Docs/STATE.md` & `Docs/AUDIT_RUBRIC.md` match tool-verified state; zero stale claims or PII |
| | **Total** | **100** | *(Localization is Deferred at `0` wt until `Locales/` is introduced, then takes 4 pts)* |

## Hard Fails (Any Hit Scores `0.0`)

1. Any flavor fails to load, or a core tab crashes / taints Blizzard UI.
2. PII leak (owner's first name, character name, personal OS path) or secret in repo content, docs, or a release zip.
3. Rebase or force-push of a shared branch (`test` or `main`).
4. Push, merge to `test`/`main`, release tag, or destructive deletion without **the owner's direct approval**.
5. `SavedVariables` or `WTF` data included in a release zip.
6. Unlicensed or copyrighted code/art copied in (GPL/ARR/CC BY-NC-ND sources are ideas only).
7. Addon spends talent points, casts protected spells, or modifies Blizzard action buttons.

## Merge & Release Bars

- **Merge to `test`:** `0` hard fails · Overall `>= 8.0` · No scored criterion `< 6.0` · Criteria `#1`, `#9`, `#10` `>= 9.0` · CI green · Owner's direct approval.
- **Public Release (`v*` tag):** `0` hard fails · Overall `>= 9.0` · `#11` (Release & Packaging) `= 10` · In-game `/ta test` `0 fail` on Forever · Owner's direct approval.

## Anchors by Criterion (Part 1)

| # | Criterion | 10 (Target) | 7 (Acceptable w/ follow-up) | 4 (Below bar) | 0 (Fail) |
|---:|---|---|---|---|---|
| 1 | Multi-Flavor Stability | All 8 TOCs parse; `/ta test` 0 fail; owner live check passes; asset parity verified | All flavors load; 1 minor cosmetic/warn logged | Feature broken or Lua error on one flavor | Any flavor fails to load or core tab crashes (Hard Fail) |
| 2 | API & Secret Safety | Every `C_*` call manifested & guarded; `issecretvalue`/`canaccessvalue` checked; strict `Button` `OnClick` | Guarded; manifest lags by 1 item | Unguarded missing API off load path | Unguarded missing API on load path or combat crash |
| 3 | Tests & CI | All `Tools/test_*.py` green; new behavior tested; mutate-red proven; 0 TZ flakes | Green CI; edge case untested | Green CI; new behavior untested | CI red, skipped, or test disabled to pass |
| 4 | Perf & Frame Pooling | 0 `CreateFrame` churn on pass 2; `CountDescendants == 0`; throttled handlers; 0 taint | Clean with 1 minor off-hot-path nit | Visible frame churn or unprotected call | Combat taint or visible stall |
| 5 | Data Honesty | Live client reads or 2+ verified sources; `UNVERIFIED` flagged; zero fabricated weights | Sourced with some rows flagged `UNVERIFIED` | Single-site unflagged claim | Ships disproven data or deletes verified data without proof |
| 6 | Cohesion & Deferral | Shared state reflected across tabs; `AddonBridge` defers cleanly loaded & unloaded | Shared data used; 1 minor duplicate | Standalone tab duplicating owned data | Second score/arrow next to specialist or breaks sibling tab |
| 7 | UX & Zero Clutter | Matches Modern Azeroth spec; theme tokens; zero clipped text; inline over popups; classic fallback intact | Minor spacing/color nit | Hard-coded colors, clipped labels, or clutter popups | Traffic-light dots, glass-on-glass, or glass on non-Forever |
| 8 | SavedVariables | Versioned migration tested; backup taken; settings unchanged after reload/install | Settings preserved; migration untested | Setting resets (recoverable from backup) | Settings lost with no backup |
| 9 | Security, PII & Art | `check_pii_hygiene.py` clean; every asset original or license recorded | Clean; 1 original asset license note missing | Non-shipping finding fixed pre-merge | Secret, PII, personal path, or unlicensed code/art (Hard Fail) |
| 10 | Git & Approval | One-topic branch; clear test steps; owner's direct approval before push/merge/tag | Mixed 2 topics or thin test steps | Large mixed PR or skipped checks | Force-push shared branch or unapproved merge/delete (Hard Fail) |
| 11 | Release & Packaging | `check_release_zip.py` clean; 0 WTF/SV; CurseForge + Wago verified; tag approved | Zip clean; 1 upload target retried | Dev files shipped or TOC file missed | Unapproved tag or WTF/SV in zip (Hard Fail) |
| 12 | Docs & Living State | `Docs/STATE.md` & rubric match verified reality; unverified items labeled | Updated with 1 stale line | Not updated after behavior change | Claims unverified work as done or leaks PII |

---

# Part 2: Character & WoW Game-Data Rubric

Scores the **content and game guidance** ToonAge shows per spec, race, system, or content type in one WoW version. Uses the Part 1 weighted formula (`N/A` drops out). This is a rubric, not a tier list.

> **Data Rule:** Verify against official sources, in-game client probes/harvests, Wowhead, and Icy Veins. Keep ours where accurate, adopt theirs where more accurate, remove only what is proven inaccurate, and flag everything else `UNVERIFIED`. **Any advice from the wrong WoW version scores that row `0`.**

## A. Role Rubric (Tank / Healer / Melee DPS / Ranged DPS / Support)

- **Role coverage across versions:**
  - *Tank:* Retail: Prot Warrior, Prot Paladin, Blood DK, Guardian Druid, Brewmaster, Vengeance. Classic/Forever: Prot Warrior & Feral Bear core (Forever reworked talents expand viability); TBC adds Prot Paladin; Wrath allows any DK tree; Mists splits Guardian from Feral; SoD runes add tank options (`UNVERIFIED` by phase).

| Criterion | Wt | 10 | 7 | 4 | 0 | Evidence |
|---|---:|---|---|---|---|---|
| Threat / Role Output | 20 | Version model exact (Classic threat modifiers vs Retail); ST & AoE verified by 2 sources | Correct priority, 1 source, AoE thin | Generic, not version-tied | Wrong-era advice or missing | Version guide + logs/probe |
| Physical Mitigation / Throughput | 20 | Armor, avoidance, block, defense cap (where applicable) exact for version | Correct, 1 cap missing | Stats listed without caps | Defense cap in Cata+/Retail or missing in Classic | Stat page + paperdoll |
| Magic Mitigation & Resists | 10 | Spell mitigation & resist fights accurate (Classic/TBC) | Covered, 1 fight missing | Mentioned only | Wrong resist advice | Raid guides + item data |
| Self-Sustain / Resource Mgmt | 15 | Self-heals, absorbs, five-second rule / mana regen uptime exact | Listed, uptime thin | One tool listed | Missing or wrong | Logs + class guide |
| Cooldowns (Def & Off) | 15 | Full kit, exact CDs, encounter use cases | Kit right, use cases thin | Partial kit | CD from wrong era/spec | Per-flavor spell tooltips |
| Mobility & Utility | 20 | Taunts, interrupts, dispels, CC, raid utility exact | 1 utility missing | Mobility only | Ability absent in version | Per-flavor class spellbook |
| **Total** | **100** | | | | | |

## B. Class & Spec Guidance

| Criterion | Wt | 10 | 7 | 4 | 0 | Evidence |
|---|---:|---|---|---|---|---|
| Rotation & Priority | 18 | Matches sims/live spellbook + 2 guides for version & level | Matches 1 source | Partly right | Wrong or other-era | Spellbook + sims + guides |
| Stat Priority & Caps | 14 | Version-correct order & caps (never fake weights on Forever) | Order right, no weights | Generic order | Caps from wrong era | Guides + paperdoll + sims |
| Talents / Build | 14 | Exact system for version (trees/rows/modern/hero); per-content plans | 1 build for all content | Outdated build | Wrong talent system | Live C_Traits + calc |
| By-Level Coverage | 12 | Every level band (`10-19`, `20-39`, `40-59`, `60+`) covered accurately | Most bands | Max level only | Advises spells above level | Live trainer/spellbook |
| Gear & BiS / Deferral | 12 | Sourced per phase; defers to Polestar/Pawn when loaded | Minor phase lag | One list all phases | Items absent in flavor | Item DB + AddonBridge |
| Consumables & Professions | 8 | Version-correct consumes & profession pairings | 1 gap | Generic | Wrong-era items | Guides + item data |
| Version Availability | 12 | Zero spells, talents, or items from another era | 1 minor slip, flagged | Several slips | Core advice from wrong era (Spec Hard Fail) | Per-flavor probe/DB |
| Source Agreement | 10 | 2+ sources or in-game probe agree (conflicts shown) | 1 source | Flagged `UNVERIFIED` | Unsourced shown as fact | Citations per row |
| **Total** | **100** | | | | | |

## C. Theorycrafting

| Criterion | Wt | 10 | 7 | 4 | 0 | Evidence |
|---|---:|---|---|---|---|---|
| Source Quality | 20 | Sim tool (SimC/Raidbots Retail, wowsims Classic) or live deterministic tooltip math + patch notes | Maintained guide (IV/WH) | Forum/video only | No source | Profile/guide/tooltip link |
| Reproducibility | 20 | APL/formula shared; rerun reproduces exact result | Method described | Result only | Cannot rerun | APL or formula in code |
| Version & Patch Currency | 15 | Built for current patch/build | 1 minor patch behind | Old phase/season | Other version | Build/patch stamp |
| Sample Size & Logs | 15 | Large Warcraft Logs / sim sample or live `ForeverCastLog` history | Moderate sample | Few logs | Anecdote | Log query / cast history |
| Stated Assumptions | 15 | Fight length, targets, buffs, gear, talents stated | Most stated | Few | None | Source/dock footnote |
| Cross-Source Agreement | 15 | Sims, guides, and logs agree | Two agree | Conflict shown honestly | Conflict hidden | Side-by-side comparison |
| **Total** | **100** | *(Any TC claim scoring `< 6` may only display with an `UNVERIFIED` flag)* | | | | |

## D. Races & Racials (Updated with Harvested Forever `1.60.1` Data)

| Criterion | PvE Wt | PvP Wt | 10 | 7 | 4 | 0 |
|---|---:|---:|---|---|---|---|
| Throughput Value | 35 | 20 | Quantified by sims/tooltips for spec & version | Stated, not sim-backed | Listed only | Wrong effect/value |
| Defensive / Survival | 20 | 20 | Effect, CD, stacking & use cases exact | Use cases thin | Listed only | Wrong effect |
| Utility (incl. CC Break) | 15 | 30 | CC break, stun/fear/mobility/stealth tools + shared CD exact | 1 rule missing | Listed only | Wrong CD or breakable set |
| Role & Spec Fit | 15 | 15 | Scoped to usable weapons/roles/spellbook | Per role only | One verdict all | Claimed for unusable spec |
| Version-Correct Effect | 15 | 15 | Exact match to flavor tooltip & live probe | Minor lag, flagged | Other-era unflagged | Wrong-version racial (Race Hard Fail) |
| **Total** | **100** | **100** | | | | |

### Key Cross-Version Racial Delta Table (Forever `1.60.1` Verified via `Data/Forever/Racials.lua`)

| Racial | Cross-Version Changes & Forever `1.60.1` Verified Status |
|---|---|
| **Human — Will to Survive / Perception** | Classic Era/SoD: Perception only. 3.0.2+: Every Man for Himself (30s→90s shared CD). **Forever `1.60.1` (VERIFIED in-client):** Has BOTH `Perception` (`20600`, 3m CD, 20s stealth detect) AND `Will to Survive` (`1259718`, 3m CD, *"Instantly removes all Stun effects"*), plus `Sword Specialization` (+2% crit with swords). |
| **Undead — Will of the Forsaken / Cannibalize** | Classic: Fear/Charm/Sleep + 5s imm. 3.0.2+: imm removed; 3.3+: shared trinket CD. **Forever `1.60.1` (VERIFIED in-client):** `Will of the Forsaken` (`7744`, 2m CD, *"Instantly removes all Charm, Fear and Sleep effects"*); `Cannibalize` (`20577`, 2m CD, 7% HP + 7% Mana every 2s for 10s); `Touch of the Grave` passive drain. |
| **Orc — Hardiness / Shatter Curse / Blood Fury** | Classic: 25% stun resist → 2.0.1 15% → 3.0.2 stun duration reduction. **Forever `1.60.1` (VERIFIED in-client):** `Hardiness` (`20573`, passive: **20% shorter Stun duration**), `Shatter Curse` (`1299026`, 3m CD, removes/immune Curses & Banes + 15% magic DR for 8s), `Blood Fury` (`20572`, 2m CD, +10% AP & Spell Power 15s), `Axe Specialization` (+1% crit). |
| **Dwarf — Stoneform / Mace Spec** | **Forever `1.60.1` (VERIFIED in-client):** `Stoneform` (`20594`, 3m CD, removes/immune Bleed/Poison/Disease + 10% physical DR 8s); `Mace Specialization` (+1% crit with maces). |
| **Gnome — Escape Artist / Eureka!** | **Forever `1.60.1` (VERIFIED in-client):** `Escape Artist` (`20589`, 2m CD, removes movement impairing + **3s immunity**); `Eureka!` (2m CD, next 3 abilities -10% resource & +10% dmg/heal). |
| **Night Elf — Elune's Light / Shadowmeld** | **Forever `1.60.1` (VERIFIED in-client):** `Elune's Light` (`1259799`, 3m CD, +10% crit 15s); `Shadowmeld` (`20580`, 10s CD OOC / 2m CD in-combat drop). |
| **Tauren — War Stomp / Plainsrunning** | **Forever `1.60.1` (VERIFIED in-client):** `War Stomp` (`20549`, 2m CD, 0.5s cast, 2s AoE stun); `Plainsrunning` (`1259918`, up to +30% run speed); `Endurance` (+5% HP, +1% hit). |
| **Troll — Berserking / Regeneration** | **Forever `1.60.1` (VERIFIED in-client):** `Berserking` (`20554`, 3m CD, +10% cast/attack speed 10s); `Regeneration` (+10% HP regen, 10% in combat). |
| **Skyborne (Forever-exclusive, both factions)** | **Forever `1.60.1` (VERIFIED in-client):** `Walk on Air` (`1259416`, 2m CD, 10s controlled glide), `Wind Blessed` (+1% haste), Alliance `Read Ley Line` (+100% HP/Mana regen 15s / 15m), Horde `Skysight` (+10% move/mounted speed 30s / 15m). |

## E. Per-Version Scoring Notes

- **Classic Era:** 51-pt trees at 60 (hybrids normal); 9% melee hit vs +3 boss at 300 weapon skill; 440 defense cap; five-second rule & downranking; world buffs core.
- **Forever (`1.60.1`):** Vanilla world + modern Midnight client API (`C_Traits`, `C_SpellBook`, `C_SkillInfo`, combat secrets); reworked 51-pt talent trees; 9 classes (Paladin & Shaman on both factions); Skyborne race; non-decaying 14-rank PvP (`Rank Points` + spendable `Honor`); **Darkspear Islands** 15v15 BG; Mage **Comprehension (`3012`)** & Library Books (`Owen Thadd` / `Garion Wendell`); expanded First Aid (healing potions/poultices); 600+ new recipes.
- **TBC Anniv. / Wrath / Cata / Mists / Retail 12.x / Remix:** Always verify patch caps on Wowhead before writing static numbers into `Data/`.

## F. Reputation & Factions

| Criterion | Wt | 10 | 7 | 4 | 0 |
|---|---:|---|---|---|---|
| Unlock Accuracy | 30 | Every recipe/gear/mount/key at exact standing | 1 off, flagged | Partial | Non-existent unlock |
| Grind Time & Cost | 20 | Rep per source + gold/item cost current | Sources only | Vague | Wrong sources |
| Version Correctness | 20 | Exact system (standings / Renown / warband) | Minor slip | Mixed | Wrong system |
| Role & Profession Priority | 15 | Explains which reps matter for spec & professions | Generic | None | Misleading |
| Source & Currency | 15 | Sourced, current phase | Phase lag | Flagged | Unsourced as fact |
| **Total** | **100** | | | | |

- **Forever Faction Additions (Confirmed):** Standard Classic standings **plus** Darkspear Islands BG factions (**Darkspear Raiders** Horde at Merchant Coast, Barrens; **Theramore Expeditionary Force** Alliance at Northwatch Hold, Dustwallow Marsh) — Friendly through Exalted gear rewards. Other new Forever zone factions remain `UNVERIFIED` until probed.

## G. Consumables

| Criterion | Wt | 10 | 7 | 4 | 0 |
|---|---:|---|---|---|---|
| Correct Items per Version/Level | 25 | Every consume exists in flavor & level band | 1 minor slip | Max level only | Other-era item |
| Role & Spec Fit | 20 | Matches spec stat priority | Per role | Generic | Wrong stat |
| Stacking Rules | 15 | Flask/elixir/food/campsite buff stacking exact | 1 rule missing | Omitted | Non-stacking advice |
| Cost & Availability | 15 | Crafting source & cost noted | Source only | Neither | Unobtainable item |
| World Buffs & Timing | 15 | Classic world buffs exact; `N/A` where none | Timing thin | Mentioned | Advised where absent |
| Source & Currency | 10 | Sourced, current phase | Phase lag | Flagged `UNVERIFIED` | Unsourced as fact |
| **Total** | **100** | *(Forever note: First Aid crafts Healing Potions & poultices; campsite profession buffs do not stack with class buffs)* | | | |

## H. Content Types Matrix

| Content | Classic Era | SoD | TBC Anniv. | Wrath | Cata | Mists Classic | Retail 12.x | Remix | Forever |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Raids | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Heroic dungeons | No | No | Yes | Yes | Yes | Yes | Yes | No | No |
| Mythic+ | No | No | No | No | No | No | Yes | No | No |
| Challenge Mode | No | No | No | No | No | Yes | No | No | No |
| Delves | No | No | No | No | No | No | Yes | No | No |
| Arenas | No | No | Yes | Yes | Yes | Yes | Yes | No | No |
| Rated battlegrounds | No | No | No | No | Yes | Yes | Yes | No | No |
| Battlegrounds | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No | Yes *(WSG, AB, AV, Darkspear Islands 15v15)* |
| World PvP | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No | Yes *(PvP realms, `/pvp`, Gurubashi FFA)* |

*Content-specific sub-weights:* Raids (Spec/boss 30, BiS 30, Consumes 20, Role 20) · Dungeons (AoE/pull 30, Gear 30, Kicks/CC 25, Route 15) · M+/CM (Timer/burst 30, Defensives/kicks 25, Affixes 25, Key gear 20) · Delves (Solo/duo 35, Companion 25, Tier scaling 20, Rewards 20) · Arenas (Comp 30, CC/DR 30, Def trades 25, PvP gear 15) · Battlegrounds (Objective 30, Sustained/AoE 25, Mobility 25, Honor/Marks gear 20) · World PvP (Burst/survival 35, Escape/mobility 35, Flagging/consumes/trinket 30).

## I. Gear Systems & J. Enchants / Gems

- **Gear Systems (100 wt):** Item level & budget (20), Set bonuses & tier (20), Upgrade paths/currencies (20), Version-specific systems (20), Source & currency (20). *Forever:* Classic gear budget + reworked talents + 600+ new craft recipes + enchanter-crafted relics; endgame tier changes `UNVERIFIED` until level-60 raids open.
- **Enchants & Gems (100 wt):** Slot list per version (20), Best choice by role/spec (20), Sockets/meta/bonuses (20 — `N/A` on Classic/Forever where no sockets exist), Profession-only perks (15), Version availability (15), In-game accuracy (10).

## K. Professions (Gaps Researched & Filled for Forever & Remix)

| Criterion | Wt | 10 | 7 | 4 | 0 |
|---|---:|---|---|---|---|
| Gold Value | 15 | Sellable crafts/gathers with market source | Named, no market | Generic | Non-existent item |
| Character-Power Perks | 20 | Version perks exact (`N/A` where none) | 1 missing | Mentioned | Wrong-era perk |
| Leveling Cost & Time | 15 | Path, materials, cost & cap exact | Path, no cost | Cap only | Wrong cap/path |
| Class & Role Synergy | 15 | Best pairs per class/spec/role | Per role | Generic | Misleading |
| PvE & PvP Value | 15 | Separate PvE & PvP value (e.g. Eng gadgets) | One side | Vague | Wrong |
| In-Game Accuracy | 20 | Recipes, skill-ups, trainers match live probe | 1 mismatch flagged | Unchecked | Proven wrong |
| **Total** | **100** | | | | |

### Complete Professions Availability Matrix (Researched 2026-11-21)

| Profession | Classic Era | SoD | TBC Anniv. | Wrath | Cata | Mists Classic | Retail 12.x | Remix | Forever |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Alchemy (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Blacksmithing (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Enchanting (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300 + relics)* |
| Engineering (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Herbalism (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Leatherworking (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Mining (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Skinning (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Tailoring (primary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Jewelcrafting (primary) | No | No | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | No |
| Inscription (primary) | No | No | No | Yes | Yes | Yes | Yes | No *(disabled)* | No |
| Cooking (secondary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No *(disabled)* | Yes *(cap 300)* |
| Fishing (secondary) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Limited *(pools/Bronze only)* | Yes *(cap 300)* |
| First Aid (secondary) | Yes | Yes | Yes | Yes | Yes | Yes | No *(removed 8.0.1)* | No | Yes *(cap 300; expanded w/ Healing Pots & poultices)* |
| Archaeology (secondary) | No | No | No | No | Yes | Yes | Yes | No *(disabled)* | No |
| **Comprehension (secondary)** | No | No | No | No | No | No | No | No | **Yes *(Mage-only, skillID 3012, cap 300, verified in-client)*** |

*Skill caps:* Classic Era / SoD / Forever `300` · TBC `375` · Wrath `450` · Cata `525` · Mists `600` · Retail per-expansion + Knowledge Points & Quality Ranks.
*Remix note:* MoP Remix & Legion Remix disable standard primary/secondary profession trainers and crafting economies (Bronze & event drops replace them); Fishing remains usable in a limited capacity for Bronze/event pools.

## L. Live Character Telemetry & Honest Advisory (NEW — ToonAge Core Differentiator)

Static guides tell you what is true in general; ToonAge's edge is verifying guidance against **your live character right now**.

| Criterion | Wt | 10 | 7 | 4 | 0 | Evidence |
|---|---:|---|---|---|---|---|
| Spellbook-Confirmed Filtering | 25 | Playbook & matchups only show spells confirmed in live `C_SpellBook` | 1 unconfirmed hint flagged | Shows spells player doesn't know | Tells player to cast unlearned spell | Live `C_SpellBook` read |
| Live Cast & Combat Mirror | 25 | `ForeverCastLog` real cast shares & fight history inform Talents & Spells | Shown on 1 tab only | Collected, not surfaced | Fabricates cast shares or taints combat | `TalentIntel` + `SpellPlaybook` |
| Live Gear, Buff & Readiness Checks | 25 | Reads equipped school dmg, wand, PvP trinket, consumables, buffs, bar ranks | Misses 1 readiness sensor | Static reminder list | Claims equipped state without reading | Live bag/equip/aura scan |
| Honest Scope & Zero Auto-Play | 25 | Deterministic tooltip math only; marks utility/procs honestly; never auto-spends/casts | Minor wording ambiguity | Implies raid-sim optimality | Auto-spends points or invents fake BiS scores (Hard Fail) | Code review + unit tests |
| **Total** | **100** | | | | | |

---

## Reference Matrices

### Classes by Version
- **Classic 9 (Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid):** Present in ALL versions. *Faction note:* Paladin (Alliance-only) and Shaman (Horde-only) in Classic Era; **both factions** from TBC onward and in **Forever**.
- **Death Knight:** Wrath, Cata, Mists, Retail 12.x, Remix (`No` in Classic Era / SoD / TBC / Forever).
- **Monk:** Mists, Retail 12.x, Remix (`No` in earlier / Forever).
- **Demon Hunter:** Retail 12.x (Havoc/Vengeance/Devourer), Remix (`No` in Classic flavors / Forever).
- **Evoker:** Retail 12.x only (`No` in Legion Remix / Classic flavors / Forever).

### Races by Version
- **Classic 8 (Human, Dwarf, Night Elf, Gnome, Orc, Undead, Tauren, Troll):** Present in ALL versions.
- **Draenei & Blood Elf:** TBC through Retail/Remix (`No` in Classic Era / SoD / Forever).
- **Worgen & Goblin:** Cata through Retail/Remix (`No` in Forever).
- **Pandaren:** Mists through Retail/Remix (`No` in Forever).
- **Allied Races, Dracthyr, Earthen, Haranir:** Retail 12.x (and Remix pre-Haranir) only.
- **Skyborne (High Order Alliance / Windshaper Horde):** **Forever exclusive (`Yes` in Forever, `No` elsewhere).**

---

## Authoritative Sources
- Official Blizzard Patch Notes (`news.blizzard.com`), In-Game Harvest Probes (`Data/Forever/*.lua`, build `1.60.1.71037`), Wowhead (`wowhead.com/forever`), Icy Veins (`icy-veins.com/wow-forever`), Method (`method.gg`), Warcraft Wiki (`warcraft.wiki.gg`), SimulationCraft (`simulationcraft.org`), Raidbots (`raidbots.com`), WoWSims (`github.com/wowsims`), Warcraft Logs (`warcraftlogs.com`).
