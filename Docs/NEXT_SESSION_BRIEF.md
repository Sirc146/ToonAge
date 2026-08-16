# ToonAge — Next Session Brief

**Priority:** Build the full Weekly Dashboard + character optimization flow.
**Vision:** "When I log in at ANY level, ToonAge tells me exactly what to do to make my toon the best it can be — right now, today."

---

## The Philosophy

This is NOT work to play the game. This is a **command center**. A dashboard that makes the player feel informed, empowered, and efficient from the moment they log in. Every tab should answer: "What should I do next to improve my character?"

---

## Session Priority #1: Weekly Tab → Full Dashboard

Reference addon: **Larias' Weekly Checklist** (installed at `_ptr_\Interface\AddOns\LariasWeeklyChecklist`)

### Features to Build (automated, personalized — not curated like Larias):

#### A. Currency Tracker Panel
- Show ALL relevant currencies in one block:
  - Adventurer Crests (current/cap)
  - Veteran Crests (current/cap)
  - Champion Crests (current/cap)
  - Hero Crests (current/cap)
  - Myth Crests (current/cap)
  - Sparks of Omens (current)
  - Catalyst charges (current)
  - Coffer Keys (current)
  - Conquest (current/cap)
  - Valor (if exists)
- API: `C_CurrencyInfo.GetCurrencyInfo(currencyID)` → `.quantity`, `.maxQuantity`
- Crest IDs need to be verified in-game: `/dump C_CurrencyInfo.GetCurrencyInfo(CURRENCY_ID)`
- Layout: compact grid, color-coded (green = uncapped, gold = at cap, grey = irrelevant for spec)

#### B. Crest Spending Advisor
- Read equipped gear item tracks (3/6, 4/6, etc.)
- Calculate: "Upgrading your weakest slot costs X crests of Y type"
- Show: "You have enough to upgrade: Chest 3/6h → 4/6h (60 Hero)"
- Priority: upgrade the slot with the highest stat-weight gain per crest spent
- Ties into Gear tab scoring — reuse `CalculateItemScore` to rank upgrade priority

#### C. ilvl Reward Reference (what gives what)
- M+ key level → end-of-dungeon ilvl → vault ilvl
- Raid difficulty → drop ilvl → vault ilvl
- Delve tier → reward ilvl → vault ilvl
- World content → ilvl range
- Rendered as a compact reference table (collapsible)
- Data source: `Data/ItemLevels.lua` (already exists, needs season 2 update)

#### D. Alt Summary (inline in Weekly tab or sidebar)
- Pull from AltTracker's existing `ToonAgeDB.char` data
- Show each character: name, class, ilvl, vault completion (3 dots per track), last login
- Highlight which alt needs the most work this week
- Click to switch to that character's data view

#### E. Temporal/Season Awareness
- Detect current season from API or hardcoded season-start date
- Label sections: "Season 2 Week 3" instead of generic "Weekly Tasks"
- Show days until reset: "Weekly reset in 2d 14h"
- Show days until season milestone if known

#### F. Upgrade Path Visualization
- "Your next 3 upgrades in priority order:"
  1. Chest 3/6h → 4/6h (60 Hero Crests) — +8% stat gain
  2. Ring 2/6v → 3/6v (45 Veteran Crests) — +5% stat gain  
  3. Weapon 5/6m → 6/6m (80 Myth Crests) — +12% stat gain
- Uses Gear module's scoring to rank by actual stat-weight improvement per crest

---

## Session Priority #2: First-Login Dashboard Feel

When ToonAge opens (`/ta` or minimap click), the FIRST thing the player sees should be actionable, not just a character portrait. The Character tab should lead with:

### "Your Toon Right Now" Summary Header:
- Name, Level, Spec, ilvl — one line
- "Next milestone: ilvl 590 for Normal Raid" — one line
- "Priority: Cap Hero Crests → Upgrade Chest" — one line
- Then the existing stat breakdown below

### Level-Aware Behavior:
- **Level 1-79:** Guide tab is default, shows leveling progress, XP/hour
- **Level 80-89:** Guide tab default, shows campaign progress + gear upgrades available
- **Level 90 (max):** Weekly tab is default, shows the full dashboard
- Store `db.defaultTab` and auto-switch based on level

---

## Session Priority #3: Remaining Rotation Conditions

34 specs still need `when` conditions in `Data/Rotations.lua`. Pattern established for 5 specs — extend to all. Key buff/debuff IDs per spec need to be verified in-game or from spell databases.

Specs to prioritize (most played at max level):
- Frost Mage (done), Fire Mage (done), Arcane
- Arms Warrior, Fury (high), Protection
- Shadow Priest, Holy, Disc
- Unholy DK, Blood
- Elemental Shaman, Enhancement, Resto
- Balance Druid, Feral, Guardian, Resto
- Affliction Lock, Demonology, Destruction
- Outlaw Rogue, Assassination, Subtlety
- Windwalker Monk, Brewmaster, Mistweaver
- Marksmanship Hunter (BM done), Survival
- Holy Paladin, Protection (Ret done)
- Augmentation Evoker, Devastation, Preservation

---

## Technical Notes for the Builder

- `C_CurrencyInfo.GetCurrencyInfo(id)` returns `{ name, quantity, maxQuantity, ... }`
- Crest currency IDs (verify in-game): likely 2806-2810 range (Season 2 Midnight)
- Item upgrade track: `C_ItemUpgrade.GetItemUpgradeInfo(itemLink)` or parse tooltip
- Weekly reset: `C_DateAndTime.GetSecondsUntilWeeklyReset()`
- Season detection: hardcode season-start epoch or detect from vault data availability
- Alt data: already in `ToonAgeDB.char[charKey]` with professionSnapshot, ilvl cached by Gear tab
- AltTracker module already has `GetCharacterSummaries()` or similar

---

## Reference Addons Installed (for game-fact extraction only):

| Addon | Use For |
|---|---|
| LariasWeeklyChecklist | UI/UX reference, feature checklist |
| APR | Quest routing sequences (already imported) |
| BtWQuests | Quest chain databases |
| Pawn | Stat weight comparison reference |
| AllTheThings | Collection completionism reference |
| HandyNotes_* | Coordinate databases |

---

## What "Evolved" Means

ToonAge isn't just a guide addon. It's a **character intelligence platform**:

1. **Any level:** Knows what's optimal for your level bracket and guides you there
2. **Any spec:** Rotation conditions + talent recommendations + gear scoring all spec-aware
3. **Any content:** Leveling, dungeons, raids, delves, PvP, farming, housing — one addon
4. **Personalized:** Reads YOUR gear, YOUR vault, YOUR currencies — not generic advice
5. **Zero setup:** Full Auto preset works instantly, everything adapts
6. **Self-improving:** CoordHarvester fills data as you play, gets better over time
7. **Independent:** Works without any other addon installed. Period.

The player should never need to alt-tab to Wowhead, open a spreadsheet, or think "what addon do I need for this?" ToonAge IS the answer.
