# ToonAge Anniversary Edition — Build Brief

**Target:** `C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\ToonAge`
**Interface:** 20506 (TBC Classic Anniversary)
**Level range:** 1-70
**Start from:** Level 1, fresh character

---

## What Makes TBC Different From Retail (everything the addon must account for)

### Stat Caps (CRITICAL — #1 priority for gearing)
- **Melee Hit cap:** 9% (142 rating at level 70)
- **Spell Hit cap:** 16% (202 rating at level 70)  
- **Expertise cap:** 26 (6.5%, 214 rating at level 70)
- **Defense cap:** 490 heroics, 540 raids (uncrittable)
- **Armor cap:** 75% physical damage reduction (35880 armor at level 70)
- **Crit cap:** ~72% for most specs (before hit goes over crit table)
- Stats below cap = wasted DPS/survivability. MUST show "You need X more Hit"

### Weapon Skills (unique to Classic)
- Each weapon type has a skill 1-350
- Skill below cap = increased miss/glancing blow penalty
- Must actively level weapons by hitting mobs
- Race bonuses: Human +5 Sword/Mace, Orc +5 Axe, Troll +5 Bow, Dwarf +5 Gun, Gnome +5 Dagger/1H Sword

### Race Attributes (combat-relevant)
- Human: +5 Sword/Mace skill, +10% rep, Perception (stealth detect)
- Orc: +5 Axe skill, Blood Fury (+AP), Hardiness (25% stun resist)
- Troll: +5 Bow/Throwing, Berserking (haste), +5% Beast damage
- Dwarf: +5 Gun, Stoneform (bleed/poison/disease immunity)
- Night Elf: +1% Dodge, Shadowmeld
- Undead: Will of the Forsaken (fear break), +10 Shadow Resist
- Tauren: +5% HP, War Stomp (AoE stun)
- Blood Elf: Arcane Torrent (silence + resource), +10 Arcane Resist
- Draenei: +1% Hit (party aura), Gift of Naaru (HoT)

### Talent System
- 61 points at level 70 (not modern loadouts)
- Three trees per class, invest points sequentially
- Cannot freely swap — costs gold, respec gets expensive
- Spec choice is a bigger commitment

### Professions (combat bonuses)
- Enchanting: Ring enchants (exclusive)
- Jewelcrafting: JC-only gems (better than normal)
- Leatherworking: Drums of Battle (haste for party)
- Tailoring: Spellthread (leg enchant)
- Blacksmithing: Extra socket on bracers/gloves (later TBC)
- Alchemy: Mixology (better flask effect)

### Gearing
- No warforging/titanforging
- Gem sockets (Red/Yellow/Blue/Meta) with socket bonuses
- Enchants on every slot
- Set bonuses matter significantly
- Badge gear (from heroics) as catch-up
- Arena rating gates certain PvP gear

### Attunements
- Karazhan: quest chain required to enter
- SSC/TK: quest chains + heroic dungeon completions
- Hyjal/BT: prior tier kills required
- Tracking attunement progress is valuable

---

## Modules Needed for Anniversary

### MUST HAVE (Core value)
1. **StatCaps** — show hit/expertise/defense vs cap, "you need X more"
2. **WeaponSkill** — track all weapon skills, suggest where to level them
3. **ClassicGear** — scoring with caps as priority (hit > all until capped)
4. **RaceAdvisor** — show racial bonuses, how they affect stat budget
5. **Character** — adapted for TBC stats (Spirit, Mp5, spell power, attack power)
6. **Arrow/Navigation** — same as retail, coordinates work the same
7. **QuestTracker** — same guide format works

### NICE TO HAVE
8. **AttunementTracker** — quest chain progress toward raid access
9. **ProfessionAdvisor** — which profession combos are best for your class/role
10. **GemAdvisor** — optimal gems per socket color considering bonuses
11. **EnchantChecklist** — what enchants you're missing on each slot

---

## Build Strategy

1. Copy the MoP Classic skeleton (`_classic_` ToonAge folder structure)
2. Change TOC to `## Interface: 20506`
3. Replace `Data/StatWeights.lua` with TBC-specific weights (Hit > all until capped)
4. Add `Core/ClassicStats.lua` with cap tables and race data
5. Adapt `Modules/Character/Character.lua` for TBC stat display
6. Adapt `Modules/Gear/Gear.lua` scoring: item with Hit is ALWAYS better until capped
7. Add weapon skill to Character tab
8. Test with Zygor TBC as reference (already installed)

---

## Key API Differences (20506 vs retail)

- No `C_Traits` (old talent API: `GetTalentInfo(tab, index)`)
- No `C_WeeklyRewards` (no vault — use badge/token tracking)
- No `C_Container` verified — may use bare globals like old Classic
- `GetCombatRating(CR_HIT_MELEE)` exists for hit rating
- `GetExpertise()` exists for expertise
- `GetDodgeChance()`, `GetParryChance()`, `GetBlockChance()` for tanks
- `GetSpellBonusDamage(school)` for casters
- `GetAttackPowerForStat(stat, value)` for physical DPS
- Verify ALL APIs with `/dump` before coding

---

## Reference Addons (installed on _anniversary_)
- ZygorGuidesViewerClassicTBCAnniv — full TBC guide system, compare UX
- ElvUI + ToxiUI — UI reference for frame styling
- DugisGuideViewerZ — alternate guide system
