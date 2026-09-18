# ToonAge Mists of Pandaria Classic Accuracy Audit

**Date:** 2026-09-16 · **Client:** 5.5.x (Interface 50504) · **Live content:** Phase 5 (Siege of Orgrimmar).
**Scope:** the 4 Mists tabs (Character, Guide, Gear, Pet Care) plus AutoEquip, 11 classes / 34 specs, levels 1 → 90, PvE and PvP.

Severity: **S1** = wrong number or advice that changes what the player does · **S2** = misleading or incomplete · **S3** = cosmetic.

## What already held up
- **Item level data:** T14–T16 tiers, leveling brackets and readiness bands are plausible for 5.4.
- **Hit and expertise caps at 90:** 7.5% (2550 rating) melee/ranged hit, 15% (5100) spell hit, 7.5% expertise, and 15% expertise for tanks.
- **Pet feeding:** already removed. Patch 4.0.1 deleted happiness and Feed Pet.

## Fixed

### S1
1. **The caster hit cap ignored Expertise and Spirit.** In MoP, Expertise counts toward the 15% spell hit cap. Balance (Balance of Power), Elemental (Elemental Precision) and Shadow (Spiritual Precision) also convert Spirit to hit 1:1. The Character tab only compared hit rating against 5100, so a capped Shadow Priest was told to keep stacking hit.
   - The cap check now uses total hit % (spell-hit rating plus non-rating hit) plus Expertise %.
   - Caster Expertise weights were 0; they now equal Hit.
   - Spirit on the three converting specs was weighted 0.40; it now equals Hit.
2. **Caps were fixed rating values valid only at level 90.** At 60, 2550 rating is far more than 7.5%, so leveling characters were never shown as capped. Caps are now percentages:
   - **At 90:** boss caps (7.5% / 15% / 7.5% / 15% for tank expertise).
   - **Below 90 and in PvP mode:** same-level caps (3% / 6% / 3% / 6%).
3. **Armor proficiency ignored level:**
   - **Proficiency:** Warriors and Paladins wear Mail until Plate at 40, and Hunters and Shamans wear Leather until Mail at 40. The Gear tab rejected every piece below the class armor type, so a level-25 Hunter got no chest/leg/etc. upgrades at all.
   - **Armor Specialization (level 50):** lighter armor is allowed before 50 and rejected from 50, when wearing only your class armor type grants +5% primary stat.
   - **AutoEquip:** its separate veto had the same problem and now uses the shared rule.
4. **AutoEquip scored by raw item level.** It called `CalculateItemScore(link)` without a spec, which returned 0 and fell back to ilvl. It now defaults to the active spec and PvE/PvP mode. This is the same bug found on TBC.

### S2
5. **PvP stats were not scored.** Resilience and PvP Power were ignored, as were Dodge and Parry despite the tanks' weights. They are now read from items. Resilience and PvP Power count only in PvP mode.
6. **Pet Care text referred to a removed quest.**
   - It told hunters to complete "Taming the Beast", a quest chain removed in 4.0.1.
   - Since 5.0.4, class spells are learned automatically.
   - The card now says Tame Beast is auto-learned at 10 and to reload if it's missing.
7. **Guide tab:** no MoP leveling guides ship. The only data is an Exile's Reach stub, and that zone doesn't exist in MoP. The empty-state text now says so instead of implying guides exist.

## Not changed (needs data or your call)
- **Per-spec weights** are templated (most melee share identical numbers). Priorities are close enough for gear comparison, but they don't encode breakpoints such as the Balance haste soft cap (10,296 rating). A data pass against Icy Veins/Wowhead per spec is recommended.
- **Guide content:** needs MoP leveling guides (1–60 old world, 60–85 Outland/Northrend/Cata, 85–90 Pandaria) or hiding the tab.
- **Weapon auto-equip** stays manual, as before. Weapon proficiency can't be checked from the item alone.
- **Inference (unverified):**
  - The same-level caps assume base miss 3%, spell miss 6% and dodge 3%.
  - Spirit→hit is assumed to already be reflected in `GetCombatRatingBonus(CR_HIT_SPELL)`.
  - Verify in game: a Shadow Priest's character sheet hit % should change when you add Spirit.

## Tests
- `Tools/test_mists_data.py`: 47 assertions covering caster combined cap, Spirit/Expertise weights, leveling vs boss caps, tank expertise, healers, armor at 40/50, PvP stats, and AutoEquip scoring without a spec.
- All other suites pass.

## Sources
- [Icy Veins MoP Classic — Elemental stat priority](https://www.icy-veins.com/mists-of-pandaria-classic/elemental-shaman-pve-stat-priority) · [Shadow](https://www.icy-veins.com/mists-of-pandaria-classic/shadow-priest-pve-stat-priority) · [Balance](https://www.icy-veins.com/mists-of-pandaria-classic/balance-druid-pve-stat-priority)
- [Warcraft Tavern — Shadow Priest stat priority](https://www.warcrafttavern.com/mop/guides/pve-shadow-priest-stat-priority-reforging/)
- [Wowhead MoP Classic — Mail (spell 8737)](https://www.wowhead.com/mop-classic/spell=8737/mail)
- [Warcraft Wiki — Plate Specialization](https://warcraft.wiki.gg/wiki/Plate_Specialization_(warrior)) · [Tame Beast](https://warcraft.wiki.gg/wiki/Tame_Beast) · [Class trainer](https://warcraft.wiki.gg/wiki/Class_trainer)
