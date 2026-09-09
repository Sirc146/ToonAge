# ToonAge — Authoritative Data Sources & Gap Analysis

This file maps every external WoW data source to what ToonAge extracts from it,
and identifies what data domains are still missing. Use it to know WHERE to
verify data and WHAT canonical source governs each domain.

**Licensing note:** Game facts (item/quest/NPC/spell IDs, map IDs, stat cap
values, drop sources) are not copyrightable — reading them off any source is
fine. Editorial content (guide text, strategy prose, opinion) is NOT copied.
See `.bootstrap.md` licensing rules.

---

## Source-by-Source Reference

### Wowhead (wowhead.com, ptr.wowhead.com, classic.wowhead.com)
**What ToonAge takes:** item IDs, quest IDs, NPC IDs, spell IDs, drop sources,
drop rates, item stats, enchant IDs, gem data, housing decor catalog.
**Used for:** validating `Data/` IDs, gear drop sources, enchant→profession map.
**Canonical for:** raw game facts across all content.

### Icy Veins (icy-veins.com)
**What ToonAge takes:** stat priority rank order, talent build direction,
rotation priority, consumable recommendations.
**Currently used in:** `Data/StatWeights.lua` (primary source), `Data/Talents.lua`.
**Canonical for:** human-readable class guidance, beginner-friendly priorities.

### SimulationCraft (simulationcraft.org)
**What ToonAge takes:** APL (Action Priority List) rotation logic, stat scaling
formulas, DR breakpoints.
**Currently used in:** `Data/Rotations.lua` rotation conditions should align to APLs.
**Canonical for:** EXACT rotation logic and the math behind the precision engine.
**GAP:** Not yet directly cross-referenced. Rotation conditions authored for 5/39 specs only.

### Raidbots (raidbots.com)
**What ToonAge takes:** sim methodology (Top Gear, Droptimizer), stat weight output.
**Canonical for:** the .001-accurate stat weight target the precision engine must match.
**GAP:** No SimC-parity stat engine yet — still using directional rank-order weights.

### Bloodmallet (bloodmallet.com)
**What ToonAge takes:** trinket rankings, tier set value, stat-stacking charts.
**Canonical for:** trinket/tier BiS ordering.
**GAP:** ToonAge has NO trinket ranking data at all.

### Archon (archon.gg)
**What ToonAge takes:** meta talent builds, stat priorities, gear from top logs.
**Canonical for:** "what top players actually run" (data-driven, not opinion).
**GAP:** Not referenced. Talent builds are guide-sourced, not log-derived.

### Warcraft Logs (warcraftlogs.com)
**What ToonAge takes:** cast frequency, gear/talent of top parses, BiS validation.
**Canonical for:** ground-truth of optimal play.
**GAP:** No integration. Could inform rotation frequency and BiS.

### Subcreation (subcreation.net)
**What ToonAge takes:** M+ meta, tier lists, spec representation.
**Canonical for:** M+ dungeon meta and spec viability.
**GAP:** No tier-list / meta-viability data in ToonAge.

### Skill Capped + Murlok.io + Drustvar (PvP)
**What ToonAge takes:** PvP talent builds, comp data, PvP stat priorities from ladder.
**Currently used in:** `Data/TalentsPvP.lua`, `Data/StatWeights.lua` (PvP weights).
**Canonical for:** PvP builds and stat priorities.
**Status:** PARTIALLY covered — PvP talents + weights exist. Comp data missing.

### Raider.IO (raider.io)
**What ToonAge takes:** M+ score API, character progression.
**Canonical for:** player skill/progress benchmarking.
**GAP:** No Raider.IO API integration (would need addon-side, they have an addon).

### RestedXP / Zygor (leveling routes)
**What ToonAge takes:** route ORDER (quest ID sequence — game facts only).
**Currently used in:** guide generation via APR import (`Tools/import_apr_routes.py`).
**Status:** COVERED via APR — 20,896 steps across 45 guides.

### Warcraft Tavern + Classic Wowhead (Classic/TBC)
**What ToonAge takes:** stat caps, weapon skill data, attunement chains, Classic BiS.
**Currently used in:** Anniversary edition `Data/TBC*.lua` files.
**Status:** COVERED for TBC Anniversary edition.

---

## GAP ANALYSIS — What ToonAge Is Missing

### HIGH PRIORITY (core value, players expect it)

| Gap | Source to pull from | Why it matters |
|---|---|---|
| **Precision stat engine (SimC-parity)** | SimulationCraft + Raidbots | "1000% accurate to .000" requirement — currently directional rank-order only |
| **Trinket rankings** | Bloodmallet | Players constantly ask "which trinket is best?" — zero data currently |
| **BiS gear targets per slot** | Wowhead + Archon | "What should I farm?" — DungeonGear has partial, no full BiS lists |
| **Rotation conditions for 34 remaining specs** | SimC APLs | Only 5/39 specs have live conditions; rest are static priority order |
| **Consumable recommendations** | Icy Veins + Wowhead | Best flask/food/pot/rune/oil per spec — scattered in Professions only |
| **Tier set bonus tracking** | Wowhead | Which tier pieces you have, what bonuses active — not tracked |

### MEDIUM PRIORITY

| Gap | Source | Why |
|---|---|---|
| **Gem recommendations per socket** | Wowhead + Icy Veins | Optimal gem per socket color + socket bonus consideration |
| **M+ dungeon routes / pull strats** | Subcreation + Wowhead | Trash routes, skip strats, per-dungeon tips |
| **Raid boss strategies (current tier)** | Wowhead + Method | Dungeons.lua has WoW-era bosses, needs current raid |
| **Spec meta viability / tier list** | Subcreation + Archon | "Is my spec good right now?" |
| **PvP comp recommendations** | Skill Capped + Murlok | "What comps work with my spec?" |
| **Weekly crest/currency caps** | Wowhead | For the Weekly dashboard (already specced in NEXT_SESSION_BRIEF) |

### LOWER PRIORITY

| Gap | Source | Why |
|---|---|---|
| **Housing decor catalog** | Wowhead | Midnight housing tracker |
| **Mount/pet collection sources** | Wowhead | Collection completionism |
| **Achievement/loremaster data** | Wowhead | Side content tracking |
| **Reputation/renown reward tables** | Wowhead | What each rep level unlocks |
| **Raider.IO score display** | Raider.IO addon API | Character benchmarking |

---

## What ToonAge ALREADY Has (don't rebuild)

| Domain | File | Source | Status |
|---|---|---|---|
| Stat weights (39 specs, PvE+PvP) | StatWeights.lua (50KB) | Icy Veins/Wowhead/Method | Directional (needs sim precision) |
| Rotation priorities (all specs) | Rotations.lua (406KB) | Icy Veins/SimC | Static order + 5 specs with conditions |
| PvE talents (all specs) | Talents.lua (42KB) | Icy Veins | Present |
| PvP talents (all specs) | TalentsPvP.lua (83KB) | Skill Capped/Murlok | Present |
| Professions (all) | Professions.lua (79KB) | Wowhead | Present |
| ilvl track data | ItemLevels.lua (21KB) | Wowhead + forums | Season 2 verified |
| Pets (hunter/collection) | Pets.lua (26KB) | Wowhead | Present |
| Leveling guides 1-90 | 45 guide files | APR routes | Coords via harvester |
| Dungeon strats (WoW era) | Dungeons.lua (8.5KB) | Wowhead/Method | Needs current tier |
| Enchant→profession map | Enchants.lua | Wowhead | Present |
| Farm routes | FarmRoutes.lua | Wowhead | Present |
| TBC stat caps/races/weapons | TBC*.lua (Anniversary) | Warcraft Tavern/Classic WH | Present |

---

## Recommended Build Order (highest value first)

1. **Precision stat engine** — the .000 accuracy requirement. SimC formulas, live DR calc. (Already specced in NEXT_SESSION_BRIEF.md §4)
2. **Trinket + BiS data** — Bloodmallet trinket ranks + Wowhead BiS per slot. New `Data/BiS.lua`.
3. **Consumables** — new `Data/Consumables.lua`: best flask/food/pot/rune/oil/gem per spec.
4. **Rotation conditions for remaining 34 specs** — align to SimC APLs.
5. **Tier set tracking** — detect equipped tier count, show active bonuses.
6. **Current-tier raid + M+ strats** — refresh Dungeons.lua for the live season.

Everything above is game-fact data (IDs, values, rankings) — extractable and
not copyrightable. The editorial "how to play" prose stays as our own wording.
