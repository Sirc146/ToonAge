# WoW Forever — build brief

Working notes for the Forever flavor. Everything here is either observed
first-hand on the beta client or marked as unverified. Nothing in this file is
shipped as advice until it is confirmed in-game.

## Client facts (observed, 2026-09)

| | |
|---|---|
| Install folder | `_classic_beta_` |
| Executable | `WowB.exe` |
| Product tag (`.flavor.info`) | `wow_classic_beta` |
| `WOW_PROJECT_ID` | `WOW_PROJECT_MAINLINE` (1) — **unverified in-game** |
| Interface | `16001` (client reports version **1.60.1**, seen in ToonAge's own header) |
| API surface | Mainline / Midnight (12.1.5-era), per Blizzard in the WoW UI Discord |

The project id and interface come from community capture, not from our own
`/dump` yet. Detection in `Core/Environment.lua` keys off "Mainline project id
with an interface below 100000", which holds for either value as long as the
client stays on the 1.6x line.

**Which TOC the client picks: `ToonAge_Mainline.toc`.** Confirmed in-game on
2026-09-19 — the addon list showed the Mainline title, not the Forever one, so
Blizzard's flavor suffix for this client is `_Mainline` and `ToonAge_Forever.toc`
never matches. It is kept in case a dedicated suffix appears later; until then
Forever loads the full Retail file set and is held back entirely by the profile
gate in `Core/Profile.lua`, which is why the window opens with no tabs. The
Mainline TOC title therefore says "Retail" rather than "Midnight": one TOC now
serves both clients and cannot name either.

**Addons were switched off in the beta earlier on 2026-09-19, then enabled.** ToonAge now loads and renders on the beta client, so the probe addon can be
run whenever the addon system is available.

Blizzard has said Forever carries Midnight's addon API restrictions, and that
the beta loads addons and keybinds from the Retail folder — which is why
Retail addons throw errors on it: they test the build number, see five digits,
and fall back to Classic code paths this client no longer has.

## Professions (observed in-game, empty state)

The profession window shows:

* **Two primary slots**, any combination of gathering and production.
* **Three secondaries**: Cooking, Fishing, First Aid.

So this is the Vanilla shape, not the Retail one: First Aid exists again, and
there is no Archaeology. Retail's `GetProfessions()` returns first aid in the
slot Retail leaves empty — worth confirming, because a Forever profession
module reads that slot.

## Stats (observed in-game, level 3 Mage, no gear equipped)

The character sheet uses Retail's panel layout (collapsible General / Primary
Attributes / Weapons sections) over the Vanilla stat model:

* Primary attributes are **Strength, Agility, Intellect, Stamina, Spirit**.
  Spirit is back.
* No Retail secondaries visible — no Mastery, no Versatility, and nothing
  resembling an item-level readout.
* General shows Health, Mana and Movement Speed; Weapons shows damage range
  and attack power.

Consequence for gear scoring: Forever needs its own weight tables shaped like
the TBC ones (flat attributes, Spirit as a real stat, no expertise, no
resilience, no DR curves), NOT `Core/StatEngine.lua`, which models Retail's
diminishing returns. `Data/Forever/` will look much more like `Data/TBC/` than
`Data/Retail/`.

Scrolled further (same character), the remaining sections are:

* **Weapons** — Main Hand damage range, Attack Power.
* **Modifiers** — Critical Strike as a percentage (4.6% naked), no rating.
* **Defense** — **Defense 13 / 15**, Dodge %, Armor.
* **Resistances** — five schools, Arcane / Fire / Frost / Nature / Shadow, all
  0 naked. No Holy resistance, same as Vanilla.

That is the whole pane at level 3 with nothing equipped. Absent: spell power,
hit, haste, parry, block, mp5 and item level. Some of those are probably
hidden while zero rather than missing outright, so the list has to be
re-checked on a geared caster and a geared tank before it is treated as
complete.

Defense as a skill with a cap ("13 / 15" = current / max for level) is the
Vanilla/TBC model, and resistances are back as their own block. Nothing on the
pane is expressed as a rating. That makes `Core/TBCStats.lua` and
`Core/SkillScan.lua` — cap-aware skills, percentage stats, no DR — the right
engine to extend for Forever, minus expertise and resilience, which are TBC
additions that do not exist here.

Still unverified: whether weapon skill exists as its own capped skill (TBC's
`UnitAttackBothHands` / `UnitRangedAttack`), what the spell-power and mp5
lines look like on a geared caster, and whether `C_Item.GetItemStats` returns
the Vanilla `ITEM_MOD_*` keys — Spirit especially, since Retail dropped it.
All three need a `/dump` from a character with gear on.

**Answered by harvest, 2026-09-26** (level 15 Undead Mage, spells seen at 14, + level 1 Warrior;
raw exports in `Docs/harvest/2026-09-26/`):

* **Spell power is a real item stat.** `C_Item.GetItemStats` returns
  `ITEM_MOD_SPELL_POWER_SHORT` on leveling greens: Reinforced Linen Cape (+1),
  Heavy Linen Gloves (+1), Darkwood Staff (+6 with +3 Stamina),
  Disciple's Pants of the Elder (+1 Int, +1 SP, +1 Spirit). This is NOT
  Vanilla itemization, so Forever gear scoring must weight spell power.
* **Spirit comes through as `ITEM_MOD_SPIRIT_SHORT`** (Blue Linen Vest +2).
* **Armor is `RESISTANCE0_NAME`, weapon DPS is
  `ITEM_MOD_DAMAGE_PER_SECOND_SHORT`.** No mp5 seen yet.
* **Spell ranks exist.** The spellbook holds each rank as its own spell ID
  (Fireball 133/143/145, Frostbolt 116/205, Conjure Water 5504/5505).
* **Talents are three trees per class through one `C_Traits` tree** (Mage
  1112, Warrior 1117), 1 point per level from 10 (5/5 Improved Fireball at
  14). The trees are NOT Vanilla's: they add Fingers of Frost, Hot Streak,
  Missile Barrage, Arcane Blast (`400xxx` IDs), Ice Lance (`1312002`), and new
  Warrior talents (Precision, Weaponmaster, Spearing Strike, Boundless Rage,
  Vanguard, Master of Defense, Raging Blows, Bloodthrill). Classic Era talent
  builds cannot be reused.

## Profession slots do NOT match Retail's order (observed 2026-09-19)

Retail's `GetProfessions()` returns six slots in a fixed order: primary 1,
primary 2, archaeology, fishing, cooking, first aid. **Forever does not.** A
character with Tailoring, Enchanting, Cooking and First Aid returned First Aid
in the slot Retail uses for archaeology, so positional labelling printed
"Archaeology: First Aid".

Rule for any Forever code touching professions: use the position only to tell
first primary from second, and label everything else with the name
`GetProfessionInfo` reports for that slot. That is correct whatever order this
game returns, and it is localized, which a hardcoded label is not.

## PvP ranks (observed in-game, fresh character)

The PvP window is the Vanilla rank ladder, rebuilt rather than copied:

* Ranks by name, starting at **Civilian** (rank 0), running to **Rank 14**.
* A **Rank Points** bar — 0 / 750 at Civilian — instead of Retail honor levels.
* "Each week, the Rank Points cap is increased, up to a maximum of 24750 for
  Rank 14." That is an accumulating weekly cap, NOT Vanilla's percentile
  standing-and-decay formula: no bracket competition, and nothing suggesting
  points are lost for a quiet week. Worth re-reading in-game at a higher rank
  before ToonAge states it as fact.
* Rewards are tied to ranks ("Next Rewards at Rank 1" — Faction Tabard) and
  purchased at the Hall of Legends / Champion's Hall.

For a ToonAge PvP advisor this is a weekly-progress problem: points now, the
current week's cap, points per honor kill, and which rank unlocks the next
reward the player cares about. Closer to the Weekly tab's shape than to the
Retail PvP module. Note that Vanilla-era gear has no Resilience, so PvP gear
advice here is rank rewards and stat weights, not a resilience target.

Unverified: which API exposes rank and rank points on this client. The Classic
calls (`UnitPVPRank`, `GetPVPRankInfo`) are part of the old global set this
client is said to have dropped, and Retail's `C_PvP` honor-level functions
describe a different system. Probe both before writing anything.

## Spell IDs (observed via /ta spellaudit on the beta, 2026-09-19)

Running the Retail spell audit on Forever is mostly noise — 483 of 641 Retail
IDs are absent, which is correct for a Vanilla-era game. The signal is in the
IDs that DID resolve, because they prove Forever kept Vanilla's original spell
IDs rather than renumbering:

| ID | Name on Forever | Note |
|---|---|---|
| 589 | Shadow Word: Pain | unchanged |
| 139 | Renew | unchanged |
| 703 | Garrote | unchanged |
| 1943 | Rupture | unchanged |
| 980 | **Bane of Agony** | Vanilla name, Retail calls it Agony |
| 48108 | Hot Streak | unchanged |
| 20271 | **Judgement** | Vanilla spelling, Retail dropped the second 'e' |
| 2050 | **Lesser Heal** | Retail reused this ID for Holy Word: Serenity |
| 8004 | **Lesser Healing Wave** | Retail reused it for Healing Surge |
| 2098 | **Eviscerate** | Retail reused it for Dispatch |
| 12472 | **Cold Snap** | Retail reused it for Icy Veins |
| 1122 | **Inferno** | Retail calls it Summon Infernal |
| 18540 | **Ritual of Doom** | Retail calls it Summon Doomguard |

Two conclusions for `Data/Forever`:

1. Vanilla spell IDs are the right starting point, not Retail's.
2. An ID existing is NOT proof it means the same thing. Blizzard reused several
   Vanilla IDs for unrelated Retail spells, so every ID has to be confirmed by
   the NAME the client reports, not assumed from a Retail data file.

Also absent: `61304` (the Retail GCD spell) and the Mistcrest upgrade
currencies `3442`–`3446`, so nothing in the Gear or rotation engines can lean
on those here.

## Camping (from published guides, NOT yet verified)

A Forever-only system, and a buff-management problem, which is the shape
ToonAge is already good at:

* A campfire placed outdoors makes a shared campsite. Basic holds 3 profession
  objects, Cooking-upgraded 5, advanced 10.
* Each nearby player contributes one object, so a full camp needs a group.
* Every profession unlocks three objects from 20 skill: sharpening wheel
  (attack power), faction banner (spirit), incense (intellect), alchemy lab
  (workspace). Advanced objects need blueprints from dungeon bosses.
* Buffs last an hour, do not stack with the equivalent class buff, and each
  contributed object carries an hour cooldown. You sit by the fire and become
  rested to receive them.
* Food gives stats plus experience — one example is +5% XP from kills for 15
  minutes.

Open question: how much of this the client exposes to addons. Camp buffs will
read as auras. Camp contents and object cooldowns may not be visible at all.

## Transmog (from published guides, NOT yet verified)

Two guides agree on the NPCs; coordinates come from Icy Veins only.

| Faction | NPC | Where | Coords |
|---|---|---|---|
| Alliance | Fyrenz Vishonar | Stormwind, Mage Quarter, behind the Mage Tower | 48.0, 84.5 |
| Horde | Mon'ye | Orgrimmar, Cleft of Shadow, upper level beside the Barber Shop | 46.1, 53.9 |

Map IDs if a waypoint is ever built: Stormwind 84, Orgrimmar 85 are the
Retail `uiMapID`s -- confirm with `C_Map.GetBestMapForUnit("player")` at each
NPC before shipping them.

System as described:

* Opt-in. Off on a new character until the player talks to the NPC.
* Slot-based, not item-based: a slot keeps its appearance when the item in it
  is replaced.
* Armor-type locked (no cloth appearance on a plate chest).
* Appearances learned on loot, account-wide for classes of the same armor
  type. Dungeon drops teach every eligible group member; raid drops teach only
  the winner.
* Small gold cost per change. Outfit slots: 2 free, up to 50, 10s to 100g
  each. "Situations" swap outfits by zone, mount, spec, weather, time of day.

Open questions: whether Retail's `C_TransmogCollection` / `C_Transmog` exist
here (add to the ApiManifest probe), and whether "enabled" is readable per
character. Until then ToonAge has nothing to say about transmog beyond where
the NPC stands.

Sources: https://www.icy-veins.com/wow-forever/transmog-system ,
https://www.gamepur.com/guides/how-to-transmog-in-wow-forever

## Capital-city NPCs new to Forever (from Wowhead Forever DB, NOT yet verified in-game)

Only NPCs with new-range IDs or a Forever-only role. Vanilla NPCs that merely
appear in the Forever DB (Tawny Grisette 4554, Theodore Griffs 11835,
Rahauro 11833, Wilder Thistlenettle 656, General Marcus Jonathan) are left out:
being listed there does not mean they changed.

| NPC | ID | Where | Role |
|---|---|---|---|
| Garion Wendell <Librarian> | 211033 | Stormwind, Mage Quarter 37.6, 80.8 | Library books turn-in (Alliance) |
| Owen Thadd <Librarian> | 211022 | Undercity, Magic Quarter 73.4, 33.0 | Library books turn-in (Horde) |
| Afadra Dunwall <Lorekeeper of Ironforge> | 264943 | Ironforge, new passage left of the High Seat | Hall of Thanes dungeon gateway / quest turn-in |
| Thom Filch | 265003 | Ironforge | Linked to Hall of Thanes; role not yet documented |
| Morbin Lightbane | 266484 | Undercity | New ID; role not yet documented |

Library books: books are world objects; the librarian offers the quest only
while you carry one. Each turn-in gives a Comprehension Charm. 10 books:
Scholarly Pendant or Erudite's Amulet (ilvl 25). 20 books: Philanthropist's
Ring or Field Researcher's Loop (rogue, ilvl 40). The first 10 count toward 20.
A collection tracker is a candidate Forever-own module once book objects are
confirmed readable (quest log + item count, no world-object API assumed).

Maur Grimtotem (11834) is inside Ragefire Chasm, not Orgrimmar -- excluded.

Sources: https://foreverchanges.pro/library-books ,
https://www.wowhead.com/forever/npc=264943/afadra-dunwall

## Mage Comprehension scrolls (from published guides, NOT yet verified)

* Mages learn **Comprehend Scroll** from their trainer and use it on
  undeciphered scrolls found in the world. Reading scrolls levels a separate
  Mage skill, **Comprehension**.
* Undeciphered scroll tooltips name the requirement. Datamined examples:
  CWAL 1, VOCE WELL 15, THAW WORDS 50, DOST OREM 175.
* Same shape as Season of Discovery's Spell Notes, which deciphered into
  on-use items. In SoD that took a Comprehension Charm; the library books
  here also pay out Comprehension Charms. Whether Forever's deciphering
  still uses them is unknown.
* No one has a full list of what the scrolls turn into.

ToonAge angle (needs no game data table): tag scroll tooltips with
"Mage: Comprehension N -- you have X / can't read yet" or "Mage-only
decipher -- send to a mage", plus a bag list of held scrolls. Blocked on:
the exact tooltip line, and which API reports the Comprehension skill
(`GetProfessions` / `GetSkillLineInfo` / neither). Capture both first.

Sources: https://www.foreverwisp.com/guides/wow-forever-mage-comprehension-scrolls ,
https://www.zockify.com/forever/mage/

## What ToonAge does on Forever today

The `forever` profile ships **ErrorLog only**. No gear scoring, no rotations,
no quest automation, no advice of any kind. `ToonAge_Forever.toc` lists the
shared Core engine and nothing else.

## Before any of that changes

1. Confirm the client numbers in-game:
   `/dump WOW_PROJECT_ID, select(4, GetBuildInfo()), GetBuildInfo()`
2. Confirm which TOC the client picked — the addon list title says
   "ToonAge Forever" if the `_Forever` suffix works, "ToonAge Midnight" or
   plain "ToonAge" if it fell back.
3. Probe the profession and aura APIs on a live character before writing a
   module against them.
4. Build `Data/Forever/` from observed values. The beta caps at level 30, so
   anything above that is guesswork until launch on 4 November.
