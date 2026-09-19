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
| Interface | `16001` (1.60.x line) — **unverified in-game** |
| API surface | Mainline / Midnight (12.1.5-era), per Blizzard in the WoW UI Discord |

The project id and interface come from community capture, not from our own
`/dump` yet. Detection in `Core/Environment.lua` keys off "Mainline project id
with an interface below 100000", which holds for either value as long as the
client stays on the 1.6x line.

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
