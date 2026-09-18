# ToonAge TBC Anniversary Accuracy Audit

**Date:** 2026-09-16 · **Client:** 2.5.x (Interface 20506) · **Live content:** Phase 3 (Black Temple / Hyjal, launched 2026-08-27) and Arena Season 3.
**Scope:** all 11 TBC tabs (Character, Stat Caps, Gear, Talents, Rotation, Spells, Weapons, Racials, Professions, Pets, PvP), 9 classes and 27 specs, levels 1 → 70, PvE and PvP.

Severity: **S1** = wrong number or advice that changes what the player does · **S2** = misleading or incomplete · **S3** = cosmetic.

## What already held up

- **Rating conversions at 70** match hitcap.io's TBC table: hit 15.77, spell hit 12.62, crit 22.08, haste 15.77, expertise 3.94 per point, defense 2.37, resilience 39.42.
- **Caps** are derived from formulas, not flat constants: 9% melee / 16% spell / 26 expertise / 490 defense vs +3, and 5% / 3% against same-level targets while leveling. Below level 60 the engine refuses to guess a conversion instead of inventing one. That's correct, because no source for the sub-60 formula could be verified.
- **Arena points formula and bracket factors** (0.76 / 0.88 / 1.00) are correct.
- **Talent builds and rotations** carry per-entry sources and confidence grades. Spot-checks against Wowhead/Icy Veins held. One real dispute: Fury 21/40 Death Wish (Wowhead) vs Rampage builds (Icy Veins) — the file already names both.

## Fixed

### S1
1. **Draenei hit racial was given to every class as both melee and spell hit.** In TBC it is class-specific:
   - Heroic Presence (+1% melee/ranged): Warrior, Paladin, Hunter.
   - Inspiring Presence (+1% spell): Mage, Priest, Shaman.

   A Draenei Enhancement Shaman was told they needed 1% less melee hit than they do. The Racials tab now labels the hit racial as melee/ranged or spell.
2. **Talent hit:**
   - **Shaman Elemental Precision:** 2% per rank (6% at 3/3), not 1%.
   - **Nature's Guidance** (3% melee and spell) and **Dual Wield Specialization** (Enhancement, up to 6%, only while dual wielding) were missing, so an Enhancement Shaman could be told to find up to 9% hit they already had. Source: Icy Veins' "Totem of Wrath + Elemental Precision + Nature's Guidance = 12%".
   - **Surefooted:** 3 ranks at 1% each, not a single 3% rank.
   - **Protection Paladin Precision:** now counts toward spell hit too (true since patch 2.3).
3. **Defense cap ignored other crit reduction.** A bear with 3/3 Survival of the Fittest needs **415**, not 490; resilience also lowers the cap. Both are now subtracted.
4. **Warriors and Paladins were marked "Plate from level 1."** They learn Plate at 40 and wear Mail before that, so low-level Mail upgrades were flagged as downgrades.
5. **Pet food:**
   - The list held only pre-Outland food with no levels, so a level-70 hunter was pointed at food their pet refuses: pets won't eat food 30+ levels below them (Petopia).
   - Rebuilt with the exact vendor ladders (5 → 65) for all six diets, including the Outland 65 tier. The picker prefers at-or-above-level food and warns when only low-level food is in your bags.
   - The old sort also fed basic food ahead of "Well Fed" food, the opposite of its own comment.
6. **AutoEquip ranked items by raw item level on TBC.** It called a Gear function that didn't exist on this client, so it could equip higher-ilvl gear with the wrong stats (e.g. spell plate on a warrior). It now uses the Gear tab's cap-aware score.

### S2
7. **Data/TBC/StatWeights.lua was the Mists of Pandaria table** (Mastery, Monks, Death Knights) and was loaded on TBC. Removed from `ToonAge_TBC.toc`. The file is still on disk, unused; you can delete it.
8. **PvP DR table:**
   - Kidney Shot is its own category.
   - Blind shares with Cyclone.
   - Sap and Gouge share with Polymorph, Freezing Trap, Wyvern Sting and Repentance.
   - Scatter Shot and Dragon's Breath form their own category.
   - Removed Psychic Horror and Turn Evil (Wrath abilities).

   Source: Icy Veins TBC Subtlety PvP guide.
9. **41-point talents:** Arms is Endless Rage, not Blood Frenzy; Restoration Druid is Tree of Life. Lifebloom is trained at 64, not a talent.
10. **Professions, where Wrath features were described as TBC:**
    - **Jewelcrafting:** jewelcrafter-only gems don't exist yet.
    - **Leatherworking:** Fur Lining bracer enchants don't exist yet.
    - **Tailoring:** tailor-only spellthreads don't exist yet; TBC spellthread is tradeable.
    - **Enchanting:** there is no attack power ring enchant — the melee option is Striking, +2 weapon damage.
11. **Endgame rotations:**
    - **Arms:** Whirlwind costs 25 rage; it doesn't generate rage.
    - **Fire Mage:** the standard 48-point build can't take Icy Veins or Cold Snap.
    - **Subtlety:** has no Blade Flurry or Adrenaline Rush.
12. **Leveling rotations:**
    - **Protection Warrior:** questing advice said to dual-wield Devastate, but Devastate requires a shield.
    - **Level gates corrected:**
      - Ice Lance is trained at 66, not unlocked by Shatter at 25.
      - Icy Veins is about level 29, not 20.
      - Incinerate is baseline at 64, not a talent.
      - Wrath of Air Totem is trained at 64.
      - Shadow Word: Death is trained at 62.
    - Removed an unsupported Stoneclaw stun claim.
13. **Improved Blessing of Wisdom** is a Holy talent, not Protection.

### S3
14. **The Human Spirit** is +5% Spirit, not +10%.
15. **Spells tab:** notes that healers downrank on purpose, so rank warnings on Holy Light, Greater Heal or Healing Wave can be ignored.

## Role and version notes
- **Tanks:** defense, armor, block and avoidance weights exist per role. The uncrittable cap now accounts for talents and resilience. Bear druids are detected by form.
- **Healers:** Mp5 weighted close to +healing (TBC is a mana game); spell hit scored at zero. The rotation tab notes downranking.
- **PvP:** unlike Retail, the TBC client has no secret-value restrictions. Resilience math (−1% crit, −2% crit damage, −1% DoT per 1%) is correct, and PvP mode forces same-level caps (5% melee / 3% spell).
- **Structural limit (S2):** gear weights are per role (Melee / Ranged / Caster / Healer / Tank), not per spec. For example, Agility-based Rogues and Strength-based Warriors share the MELEE table (Strength 1.00, Agility 0.65), which undervalues Agility for Rogues and Feral Cats. Recommend splitting MELEE into STR and AGI variants.

## Needs your game client
- **Full restart required:** `ToonAge_TBC.toc` changed, so a `/reload` won't pick it up.
- **Conjured food:** whether pets accept it wasn't verifiable. It is now used only as a last resort.
- **`/ta hitbonus`:** still overrides detected talent hit if anything reads wrong.

## Tests
- `Tools/test_tbc_data.py` — 31 assertions: racial split, talent hit values, defense 490/415/465, Mail→Plate at 40, pet food rules, DR table, TOC contents.
- All other suites still pass; all 41 TBC TOC files parse.

## Sources
- [hitcap.io TBC rating converter](https://hitcap.io/tbc/rating-converter/)
- [Wowhead TBC — Heroic Presence](https://www.wowhead.com/tbc/spell=6562/heroic-presence) · [Inspiring Presence](https://www.wowhead.com/tbc/spell=28878/inspiring-presence) · [Surefooted](https://www.wowhead.com/tbc/spell=24283/surefooted) · [Dual Wield Specialization](https://www.wowhead.com/tbc/spell=30819/dual-wield-specialization) · [Feed Pet](https://www.wowhead.com/tbc/spell=6991/feed-pet) · [Fury talent builds](https://www.wowhead.com/tbc/guide/classes/warrior/dps-talent-builds-pve)
- [LootXP Hub — TBC Alliance racials](https://www.lootxphub.com/alliance-races-and-racial-traits-guide-for-tbc-classic/)
- [Icy Veins TBC — Elemental stat priority](https://www.icy-veins.com/tbc-classic/elemental-shaman-dps-pve-stat-priority) · [Enhancement guide](https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-guide) · [Subtlety PvP](https://www.icy-veins.com/tbc-classic/subtlety-rogue-pvp-guide) · [Fury builds](https://www.icy-veins.com/tbc-classic/fury-warrior-dps-pve-spec-builds-talents)
- [Boosting-Ground — TBC Survival talents](https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-survival-hunter-talents)
- [Petopia — Feeding your pet](https://www.wow-petopia.com/faq.php?id=diet)
- [Skill Capped — TBC Holy Paladin PvP talents](https://www.skill-capped.com/wowarticles/tbc/guides/holy-paladin-pvp-guide/talents/)
- [Blizzard Watch — TBC Anniversary phases](https://blizzardwatch.com/2026/01/29/burning-crusade-classic-anniversary-phase-release-dates/) · [Timesaver — Phase 3 live](https://timesaver.gg/blog/tbc-anniversary-phase-4-fury-of-the-sunwell)
