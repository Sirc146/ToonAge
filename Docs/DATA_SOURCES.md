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

---

## Addon-Development / API References (governs the shared ENGINE, not Data)

The table above governs game-FACT DATA (`Data/**`). The sources below govern the
ENGINE — `Core/Environment.lua`, `Core/Compat/API.lua`, the TOCs, and any code
touching version-specific WoW APIs. Consult these before adding a flavor,
shimming an API, or reacting to a patch that changes the API surface.

| Source | URL | Canonical for | Used in ToonAgeOne |
|---|---|---|---|
| Warcraft Wiki — API | warcraft.wiki.gg/wiki/World_of_Warcraft_API | Living Lua API reference: functions, events, widgets, secure code, TOC format, per-patch API change lists. Community authority for the in-game addon API. | `WOW_PROJECT_ID` constants + interface numbers in `Core/Environment.lua`; TOC `## Interface` values; C_* vs global shim decisions in `Core/Compat/API.lua`. |
| Warcraft Wiki — Secret Values / patch notes | warcraft.wiki.gg (patch pages) | Midnight "Secret Values" restrictions + breaking API changes. Retail combat data is display-only. | Taint/secret handling in `Core/Utils.lua`; re-check each retail patch. |
| Gethe/wow-ui-source | github.com/Gethe/wow-ui-source | Mirror of Blizzard FrameXML/UI source; branches track live/PTR/beta. Ground truth for real signatures. | Verifying signatures before shimming (container, spell, talent-tab). |
| In-game `/api` + `/dump` | (in client) | Only official in-client API surface. `/dump WOW_PROJECT_ID` + `select(4,GetBuildInfo())` give a client's exact detection constants. | Capturing a NEW flavor's project ID + interface number (e.g. WoW Forever, on its Beta) to activate its Environment branch. |
| AddOn Studio wiki | addonstudio.org | AddOn structure, TOC format, Global/Widget API, secure templates. | TOC authoring (Task 6), packaging fields. |
| wowprogramming.com | wowprogramming.com | Foundational Lua 5.1 / frames / events (WoW Programming book companion). | Fundamentals; the Lua 5.1 env our lupa tests emulate. |
| CurseForge / WoWInterface / Wago.io | curseforge.com/wow · wowinterface.com · wago.io | Hosting + open-source addons to study (ElvUI/WeakAuras multi-TOC + `.pkgmeta`). Our distribution targets. | Multi-TOC + BigWigs packager pattern (Tasks 6, 10). |
| BigWigs packager | github.com/BigWigsMods/packager | De-facto GitHub Action: builds per-flavor packages, uploads to CurseForge/Wago/WowUp/WoWInterface from one tag. | Task 10 pipeline + `.pkgmeta`. |
| Ketho/BlizzardInterfaceResources | github.com/Ketho/BlizzardInterfaceResources | Extracted globals, enums, strings, templates. | Resolving enum/global names across flavors. |
| Blizzard Developer Portal | develop.battle.net | Official WEB Game Data / Profile APIs. NOT the in-game Lua API. | Only for external companion tools. |

### Rule of thumb for the engine
- Shimmable API-SURFACE difference (renamed function, same concept — e.g.
  `C_Container.GetContainerNumSlots` vs global `GetContainerNumSlots`) → wrapper
  in `Core/Compat/API.lua`, verified vs Warcraft Wiki + wow-ui-source.
- Game-RULE difference (talent numbers, stat caps, tier tables) → NOT shimmed;
  goes in per-flavor `Data/<Flavor>/**`, verified vs Wowhead / Icy-Veins /
  Warcraft Tavern.

### Capturing a new flavor's detection constants
On the new client, run: `/dump WOW_PROJECT_ID` and
`/run print(select(4, GetBuildInfo()))`. Add the project ID to `PROJECT_IDS` +
a branch in `Core/Environment.lua`, and the interface number to that flavor's
TOC `## Interface` line. No other engine change is required.

---

## Quest / Guide Databases (per flavor)

For `Data/Guides/**`, GuideParser, QuestTracker, Arrow, MapPins, CoordResolver.
All are community-verified against live servers; ToonAge extracts game FACTS
(quest IDs, coords, chains) only — never editorial guide prose.

| Source | Coverage | Use |
|---|---|---|
| Wowhead (wowhead.com — version dropdown; `/forever/`, `/classic/`) | Retail/Midnight, Classic Era, MoP Classic, TBC Anniversary, **and a live Forever DB at wowhead.com/forever/database** | Primary: quest IDs, rewards, coords, chains, dungeon loot. |
| Warcraft Wiki (warcraft.wiki.gg) | All versions | Clean per-zone quest tables + long chains (search "<Zone> quests"); also the API authority. |
| Warcraft Tavern (warcrafttavern.com) | Midnight, Classic Era, TBC Anniversary, MoP Classic, SoD | Multi-version searchable DB, kept current. |
| RestedXP (restedxp.com) | Classic Era, Hardcore, SoD, MoP Classic, Retail, Anniversary | Route ORDER reference (quest-ID sequence — a game fact); already imported via `Tools/import_apr_routes.py`. |
| In-game addons Questie / Wholly+Grail | Classic family strongest | High-accuracy cross-check of quest DB in-client. |

**WoW Forever quest data:** Wowhead's Forever database is already live and will
keep expanding through Beta (Sept 17 2026) → launch (Nov 4 2026). Cross-check
Wowhead (details) + Warcraft Wiki (clean chains) for the Forever `Data/Forever/`
guides when that flavor's content is authored (Task 9 fill-in).

## Module → source quick map

| ToonAge module / data | Primary source(s) |
|---|---|
| Guides / QuestTracker / Arrow / MapPins / CoordResolver | Wowhead (coords) + Warcraft Wiki (chains) + RestedXP (route order) |
| Gear / StatEngine / StatWeights / ItemLevels / Enchants / TooltipScorer | Wowhead (items/stats/enchants) + Icy-Veins/Wowhead BiS + Bloodmallet/Raidbots (sims) |
| Spells / Talents / TalentsPvP / Rotations / RotationConditions / SpecAdaptive | Icy-Veins + Wowhead class guides + SimulationCraft APLs; Classic talent calculators for classic family |
| Professions / ProfQuesting | Wowhead profession DB + wow-professions.com |
| Pets / PetCare | Wowhead pet DB + Warcraftpets.com + Petopia (classic hunter pets) |
| Dungeons / DungeonGuide / Delves / DungeonGear | Wowhead Journal + Icy-Veins dungeon guides + Raider.IO/WarcraftLogs (current difficulty) |
| Farming / FarmRoutes / GatherTracker | Wowhead farming guides + map pins |
| Progression / Weekly / WorldQuests / AltTracker | Wowhead weekly/WQ/rep trackers + Raider.IO/WoWProgress |
| Core / Compat / Environment / TOC (engine) | Warcraft Wiki API + Gethe/wow-ui-source + in-game `/api` (see API references section above) |

**Coordinate/navigation note:** Wowhead map hover gives coords; in-game
`C_Map.*` APIs (documented on Warcraft Wiki) are authoritative at runtime; the
HereBeDragons library and TomTom/TomCat's Coordinates are the community
reference implementations to study for the navigation modules.

---

## Reference implementations studied (installed clients, 2026-09)

Confirmed the ToonAgeOne single-engine/multi-flavor design against mature addons
actually installed across the local WoW clients (`C:\Program Files (x86)\World of
Warcraft\_retail_ | _ptr_ | _classic_ | _classic_era_ | _anniversary_ | _beta_ |
_xptr_`). These are authoritative working examples of the pattern.

### ElvUI (closest structural match)
- One folder, per-flavor suffixed TOCs only (no generic fallback):
  `ElvUI_Mainline.toc` (Interface 120100), `_TBC.toc` (20506), `_Vanilla.toc`,
  `_Wrath.toc`, `_Mists.toc`. Headers IDENTICAL except `## Interface` + title tag
  — exactly the ToonAge_Mainline/_TBC approach.
- Each flavor TOC lists a SINGLE file: `Game\load_<flavor>.xml`, which
  `<Script>`/`<Include>`s the SHARED code first, then a smaller flavor-specific
  set.
- Folder layout: `Game/Shared/`, `Game/Mainline/`, `Game/TBC/`, `Game/Classic/`,
  `Game/Mists/`, `Game/Wrath/`. Shared code authored ONCE; flavors add only files
  for concepts that don't exist elsewhere (TBC adds Hit/SpellHit/Spirit/Ammo
  datatexts — the TBC stat concepts — but reuses shared Core/API/Layout/module
  loader).
- KEY CONFIRMATION: ElvUI does NOT ship a separate TBC copy of Core/API/Layout.
  One shared `Shared\General\API.lua` (their equivalent of our
  `Core/Compat/API.lua`) absorbs flavor API differences. Validates the ToonAgeOne
  rule: use the shared trunk Core on every flavor; bring in only genuinely
  flavor-specific files, namespaced under `Data/<Flavor>/` + `Modules/<Flavor>/`.

### Details! and BigWigs (packager + fallback pattern)
- Both ship the suffixed set PLUS a generic `.toc` fallback (like our Mainline +
  generic ToonAge.toc) — confirms the fallback approach is legitimate/common.
- Both use the BigWigs packager (`.pkgmeta` + tag-driven GitHub Action) uploading
  per-flavor packages to CurseForge/Wago/WoWInterface — the exact Task 10
  pipeline. BigWigs content sub-addons use single `_Mainline.toc` files.

### Also installed (multi-TOC corpus to study)
Angleur, BetterBags, BtWTodo, DataStore_* suite, HandyNotes_* — all ship the
`_TBC/_Vanilla/_Cata/_Mists/_Wrath` + generic pattern.
