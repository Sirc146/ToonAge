# ToonAge Retail Accuracy Audit — Midnight 12.1 (Season 2)

**Date:** 2026-09-16 · **Client:** Mainline 12.1 (live since 2026-08-11) · **Scope:** all 9 Retail tabs, all 13 classes / 40 specs, all roles, level 1 → 90, PvE and PvP.
**Next:** TBC Anniversary, then Mists Classic (separate audits — their rules and API differ).

Severity: **S1** = shows wrong advice or breaks a feature · **S2** = incomplete or misleading · **S3** = cosmetic or low-impact.

---

## 1. Summary

| Tab | Before | After this pass | Remaining |
|---|---|---|---|
| Character (stat weights, DR) | 39/40 specs; DR wrong while leveling | 40/40; DR scales by level; spec breakpoints | Weights are one row per spec (see §4) |
| Talents | Invented build names, 24/26 import strings broken | Hero tree per content for 40 specs from Icy Veins 12.1; broken strings removed | No import strings until captured in game |
| Rotation | Devourer missing; 4 wrong spellIDs; removed abilities; missing core abilities | Devourer added; IDs fixed; Shadow updated; 79 verified entries added | ~370 IDs not yet verified in game (`/ta spellaudit`) |
| Gear | Wrong enchant slots (TWW set); enchant nag on every slot | Midnight slots; no nag while leveling or below Champion ilvl | Enchant ID map empty until real IDs captured |
| Delves | Brann (TWW companion); tier estimate used loot ilvl | Valeera; estimate uses recommended ilvl; crest track per tier | — |
| Weekly | World boss, Spark of Omens, Callings (Shadowlands) | Lairs, Spark of Tides, outdoor events; saved lists migrated | "Not fully interactive" — needs repro details |
| Professions | Inspiration (removed in TWW), invented item/node names | Stat model corrected (Concentration/Ingenuity, 2 consumable ranks) | **Tree/gear data still largely unverified — needs a dedicated pass** |
| Pets | Not changed | — | Not audited in depth this pass |
| Guide / Dungeons | Dungeons table is The War Within Season 1 | — | **S2:** needs Season 2 pool (8 dungeons) |

---

## 2. Findings and fixes

### S1 — fixed
1. **Devourer (specID 1480) missing from every data file.** Added to StatWeights, Rotations (verified spellIDs), Talents, TalentsPvP, role/style table, weapon map, name map.
2. **Talent import strings:** decoding the loadout header showed 24 of 26 strings carried the wrong spec ID or serialization version (e.g. Windwalker and Mistweaver strings decoded to Brewmaster, Affliction and Destruction to Demonology). All removed; the copy button hides until you capture a real loadout.
3. **Invented PvE build names** (e.g. "Balance Affinity Heal", "Careful Aim Execute", "Radiant Spark Funnel") replaced with Icy Veins 12.1 hero-tree picks for raid, M+ and solo; the PvP build now uses the hero tree from TalentsPvP.
4. **Wrong spellIDs** (a wrong ID fails silently — the entry never shows): Kill Shot used 271788 (**Serpent Sting**) ×4; Eternity Surge used 368847 (**Firestorm**) ×3 plus Spells.lua; Tentacle Slam used 303832 (**NPC ability**); Protection Hammer of the Righteous used 204019 (**Blessed Hammer**).
5. **Shadow Priest (12.1 rework):** Mind Sear and Void Eruption no longer exist → Voidform; added Void Volley (Voidform grants 3); Shadow Halo ID corrected.
6. **Holy Paladin** listed Hammer of Light (Templar-only; Holy's trees are Herald of the Sun and Lightsmith) → removed.
7. **Gear enchant slots** used The War Within's set: Back and Wrist flagged "Missing Enchant" while Head and Shoulder were never checked. Now Head, Shoulder, Chest, Legs, Feet, Rings, Weapons (Off Hand only if it's a weapon). The sidebar flagged every slot including neck and trinkets — fixed.
8. **Delves:** companion is Valeera Sanguinar (not Brann); tier estimate compared equipped ilvl to *loot* ilvl, so anyone at 295+ showed "Tier 11". Now uses recommended ilvl 170→309; shows loot, bounty and vault ilvl; Bountiful from Tier 4; crest track per tier (T1-4 Adventurer, T5-6 Veteran, T7-10 Champion, T11 Hero); removed stale "233 / 253 iLvl" hints and the incorrect "Tier 11 for Myth".
9. **DR while leveling:** DR brackets are defined at 30% effect, but the engine compared ratings to level-90 numbers, so DR never applied below 90. Bounds now scale by live rating-per-%. The Character tab's "DR soft cap" uses the same scaling.

### S2 — fixed
10. **Missing core abilities** added with Wowhead-verified IDs (all gated by "spell known", so untalented ones stay hidden):
    - **Affliction:** Shadow Bolt, Drain Soul (no filler before)
    - **Destruction:** Channel Demonfire, Dimensional Rift
    - **Discipline:** Shadow Word: Death
    - **Holy Priest:** Holy Word: Chastise, Prayer of Healing
    - **Restoration Shaman:** Earth Shield
    - **Enhancement:** Flame Shock
    - **Elemental:** Frost Shock
    - **Beast Mastery:** Call of the Wild, Bloodshed, Dire Beast
    - **Survival:** Coordinated Assault, Fury of the Eagle, Flanking Strike
    - **Devastation:** Firestorm, Tip the Scales
    - **Augmentation:** Fire Breath, Azure Strike, Blistering Scales, Time Skip
    - **Fire and Frost Mage:** Shifting Power
    - **Brewmaster:** Black Ox Brew, Rushing Jade Wind
    - **Mistweaver:** Sheilun's Gift, Jadefire Stomp
    - **Guardian:** Moonfire, Maul
    - **Frost DK:** Frostscythe, Death and Decay
    - **Holy Paladin:** Holy Prism, Eternal Flame, Avenging Crusader
11. **Item level tracks:** crest and content sources corrected. Heroic dungeons are Veteran, not Adventurer; Mythic+ starts at Champion; Hero crests come from +4–8 keys and Delve Tier 11; Myth from +9 keys and Mythic raid; 12.1 Heroic raid vault gives Myth 1/6.
12. **Talents leveling milestones:** removed unsupported claims (Heroic dungeons at 30, Delves at 50). Now: talents at 10, hero talents at 71 (one point per level), Midnight zones 80–90, Apex talents from 81, cap 90.
13. **Weekly tasks:** Kill World Boss → Clear a Lair (12.1); Spark of Omens → Spark of Tides; Callings (Shadowlands) → weekly outdoor events. Existing saved task lists are migrated only where the text is still the old default, so your own edits are never touched.
14. **Enchants map:** every key was a sequential placeholder (74001…) that could never match a real item, so it was emptied, with instructions for capturing real IDs.
15. **Professions:** Inspiration → Ingenuity + Concentration (cap 1000, ~1 per 6 min); Midnight consumables have 2 quality ranks, gear 5.

### Still open
- **S2 Professions data** (`Data/Retail/Professions.lua`, 81 KB): node names, gear names and "personal benefit" text are largely unverifiable. For example it names "Mastery of the Dreamer" (a Dragonflight enchant) and "Midnight Dragonhide". It needs a dedicated research pass per profession (11 professions).
- **S2 Dungeons / DungeonGear:** still The War Within / Midnight Season 1. Season 2 pool: Altar of Fangs, Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena, King's Rest, Temple of Sethraliss, Ruby Life Pools. Boss encounter IDs must come from the in-game journal, not guesses.
- **S2 Rotation IDs:** about 370 existing IDs were only spot-checked (4 of the roughly 12 checked were wrong). Run **`/ta spellaudit`** out of combat on retail — it lists every ID that doesn't exist or doesn't match its name on the live client.
- **S2 Rotation ordering:** Icy Veins 12.1 priorities differ in order for several specs:
  - **Arcane:** Prismatic Bolt and the Arcane Salvo loop (Apex, 81+) are not modeled.
  - **Unholy:** Festering Scythe is missing.
  - **Windwalker:** Zenith, Slicing Winds and Rushing Wind Kick are missing (Midnight IDs not verified).
- **S3 Import strings:** capture real ones with `/ta talentscan` or "Save Current as X Build".
- **Weekly "not fully interactive"** — need to know what doesn't respond.

---

## 3. Stat weights check (PvE, primary build)

Compared with Icy Veins 12.1 stat pages (updated 2026-08-10) and the Styka Sheets S2 table:
- The **39 existing specs match Icy Veins' primary order** where checked: Holy Priest, Balance, Beast Mastery, Shadow.
- Styka disagrees on several specs (e.g. Holy Priest Haste-first), but Icy Veins, the more authoritative source, supports the data as it stands.
- **Devourer** was added with an unresolved disagreement:
  - Wowhead and Styka: Haste to ~800, then Crit ≥ Mastery.
  - Method: Mastery first.
  - Kept the 2-of-3 order; the new `softCaps = { HASTE = 800 }` drops Haste to the spec's lowest weight past 800 (level-scaled).
- **Structural limit (S2):** each spec has one PvE row, but priorities split by hero tree or content for several specs:
  - **Holy Priest:** Raid is Crit > Mastery > Vers > Haste; M+ is Crit > Vers > Haste > Mastery.
  - **Beast Mastery:** single-target and M+ differ.
  - **Balance:** Elune's Chosen and Keeper of the Grove differ.
  - **Shadow:** differs per hero tree × content.

  Recommend adding `pve_raid` / `pve_mplus` rows keyed off the Talents content selector.

## 4. Role frameworks

- **Tanks:** Rotation data for all 7 tanks includes active mitigation (Shield Block/Ignore Pain, Ironfur/Frenzied Regeneration, Death Strike, Shield of the Righteous, Soul Cleave/Demon Spikes, Purifying/Celestial Brew). StatEngine applies tank multipliers (Stamina ×1.40, Versatility ×1.20, Armor ×1.25). Block, parry and dodge are not itemized secondaries on retail gear, so effective-health math uses Stamina, Armor and Versatility.
- **Healers:** Ramp healers (Discipline, Preservation) carry setup notes, and reactive healers (Holy Priest, Restoration Shaman, Mistweaver) have their key spells after this pass. Mana economy is not modeled numerically (Innervate is now 25% mana on 3 min for Restoration Druid in 12.1).
- **Real-time intake/uptime tracking:** limited by Midnight's addon rules. Player auras are "secret" in combat (see §5), so recommendations are out-of-combat or rely on the Cooldown Manager.

## 5. PvP

- **Premise correction (Retail):** since 12.0, `COMBAT_LOG_EVENT_UNFILTERED` errors on register, and enemy auras, cooldowns and health are secret values in combat, instances and PvP. CLEU-based enemy cooldown, DR or burst trackers can't be built. Blizzard's replacements are `C_SpellDiminish` (DR), the Cooldown Manager, and restricted `C_CombatLog`/`C_DamageMeter`. ToonAge already handles secret values (`Core/Utils.lua`) and has no CLEU code.
- **What the PvP tab can do, and does:** Versatility/Stamina-weighted PvP stat rows (40 specs), a hero tree per spec with sample-size notes, PvP talent picks with alternatives, and class matchup tips.
- **Devourer PvP:** hero tree and stat order are low confidence — no PvP-specific source published.

## 6. Leveling 1 → 90

- **Spells:** rotation entries are gated by "spell known", so the list is correct at any level. `unlockLv` labels exist on 44 entries (display only).
- **Stats:** DR now scales with level (§2.9). Enchant warnings are suppressed below max level and below Champion ilvl, so it no longer nags about gold spent on gear you'll replace.
- **Talents:** hero trees apply from 71. The only step-by-step level path (Survival) used a pre-12.1 tree and was removed with the broken strings.
- **Low-level specs:** 1444–1456 (levels 1–9, no spec chosen) fall through to the rotation fallback and "no build data" text, which is correct.

## 7. Architecture and future-proofing (Retail)

- **Version isolation:** already solid. Per-flavor TOCs load only their own data, `Environment.lua` + `Compat/API.lua` + `Profile.lua` gate modules, and tabs are hidden when their module isn't loaded.
- **SavedVariables:** `ApplyDefaults` backfills keys, but there is no schema-version stamp. This pass added a targeted migration for the weekly tasks. Recommend a `db.schemaVersion` + ordered migrations list before 12.2.
- **Memory:** the Mainline TOC loads all 45 guide files (~2.5 MB of Lua) and the 415 KB Rotations table at login. Load-on-demand guides would cut the resting footprint.
- **Upcoming:**
  - **12.1.5:** Labyrinths, Kith'ix raid, Aqir Invasions, Ascendant Venomstones. The Delves module's tier table is data-driven, so a Labyrinth ladder can reuse the same rec/loot/vault shape; `Z.CHASE_TIER_ILVL` already anticipates Venomstones.
  - **12.2 Eclipse:** Worldcore raid, Season 3 (full ilvl, crest and dungeon rebase). Also new race/class combos (Night Elf, Troll, Undead Paladins).
  - **Recurring each season:** rotate ItemLevels, the Delves tiers, Dungeons and Weekly text, then run `/ta spellaudit`.

## 8. Tests added

- `Tools/test_retail_data.py` (15 assertions): 40-spec coverage, import strings decode to their own spec, removed abilities and known-bad IDs stay out, delve tiers rise, Midnight enchant slots.
- `Tools/test_tab_set.py` (69 assertions, from the tab fix).
- All existing suites still pass; `check_lua` parses all 125 Mainline files.

## Sources

- Icy Veins class guides, Patch 12.1 (stat pages 2026-08-10; rotation/talent pages 2026-08-10 → 2026-09-08) — icy-veins.com/wow
- [Icy Veins — Full Patch 12.1 class changes](https://www.icy-veins.com/wow/news/full-reworks-and-tuning-all-season-2-class-changes-and-more-full-patch-12-1-curse-of-ulatek-content-update-notes/)
- [Icy Veins — Delves guide](https://www.icy-veins.com/wow/delves-guide) · [Five Mistcrests](https://www.icy-veins.com/wow/news/these-five-mistcrests-decide-how-fast-your-gear-climbs-in-midnight-season-2/) · [Patch 12.1 guide](https://www.icy-veins.com/wow/midnight-patch-12-1-guide)
- [Wowhead — Mythic+ Season overview](https://www.wowhead.com/guide/midnight/mythic-plus-season-overview) · [Devourer stat priority](https://www.wowhead.com/guide/classes/demon-hunter/devourer/stat-priority-pve-dps) · Wowhead spell tooltips (all added/changed spellIDs)
- [Method — Devourer stats](https://www.method.gg/guides/devourer-demon-hunter/stats-races-and-consumables) · [Season 2 dungeon rotation](https://www.method.gg/guides/wow-midnight-season-2-mythic-dungeon-rotation) · [Midnight enchants and gems](https://www.method.gg/guides/list-of-all-midnight-consumables-enchants-and-gems)
- [Styka Sheets — Season 2 stat priorities](https://stykasheets.com/midnight-season-2-stat-priorities/)
- [warcraft.wiki.gg — SpecializationID](https://warcraft.wiki.gg/wiki/SpecializationID) · [Patch 12.0.0 API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [Blizzard — Level Up Your Talents in Midnight](https://news.blizzard.com/en-us/article/24230699/level-up-your-talents-in-midnight)
- [ConquestCapped — Midnight profession stats](https://conquestcapped.com/guides/wow/wow-midnight-profession-stats/)
- [Blizzard Watch — 12.1 release](https://blizzardwatch.com/2026/07/28/wow-12-1-release-date/) · [12.2 Eclipse](https://blizzardwatch.com/2026/09/12/wow-midnight-patch-12-2-eclipse-xalatath-release-date/) · [Warcraft Tavern — 12.1.5 Labyrinths](https://www.warcrafttavern.com/wow/news/midnight-patch-12-1-5-labyrinths-raid-outdoor-event/)
