# Offline client (`wowsim`)

`Tools/harness/wowsim.py` is one fake WoW client for the offline suites. It
embeds Lua 5.1 (lupa) and loads the files a TOC lists, in that order. Globals
come from a snapshot under `Tools/fixtures/api/`. A name the snapshot does not
list is nil, so a Retail-only call on the Forever snapshot fails here.

The only dependency is lupa (`Tools/requirements.txt`). Reports are JSON from
the standard library.

## Run a client

From the repo root:

```bash
python Tools/harness/wowsim.py forever --report /tmp/forever.json
python Tools/harness/wowsim.py retail
python Tools/harness/wowsim.py tbc
```

From Python:

```python
from harness.wowsim import World

world = World("forever")          # Tools/fixtures/api/forever.lua
world.load()                      # TOC order; one check per file
world.login()                     # ADDON_LOADED, then PLAYER_ENTERING_WORLD
world.fire_safe_events()          # read-only events; missing ones are skipped
world.render_tabs()               # TA.UI:SetTab for each profile tab
world.run_harness()               # TestHarness suites, one at a time
world.write_report("out.json")
```

`World("tbc", files=["Core/Init.lua"])` loads that list instead of the TOC.
`assign_saved("ToonAgeDB", chunk)` installs a Lua chunk that returns a table,
which is how `Tools/test_save_migrations.py` replays old saves.

`Tools/test_tbc_boot.py` boots `ToonAge_TBC.toc` this way. It still exports
`TBC_PRELUDE` because older TBC suites execute that string themselves.

## What the client implements

Frames answer an unknown PascalCase method with a callable stand-in that
returns the frame. A key that starts with `_` or a lowercase letter is data
and reads as nil, which is what `Core/Layout.lua` needs. `C_Timer.After`
queues callbacks. `drain` runs them in time order, at most 60 seconds of
virtual time and 8000 callbacks, so a suite that reschedules itself cannot
spin. Tickers are created and not pumped.

`RegisterEvent` on Forever and Retail throws unless the snapshot says that
event is present. `TA:RegisterEvent` records the throw as an unknown event.
The TBC snapshot does not enforce that: the old boot prelude accepted every
event, and `test_tbc_boot.py` depends on it.

Safe events (the same read-only list as `Modules/Infrastructure/TestHarness.lua`):

`PLAYER_EQUIPMENT_CHANGED`, `UNIT_INVENTORY_CHANGED`, `SKILL_LINES_CHANGED`,
`PLAYER_TALENT_UPDATE`, `UNIT_PET`, `PLAYER_XP_UPDATE`, `UNIT_STATS`,
`SPELLS_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `GET_ITEM_INFO_RECEIVED`.

Loot, merchant, quest-accept, and level-up are not fired.

## Report

```text
pass / fail / warn / skip / info
```

`info` is a TestHarness line, not a failure. Every check has `unverified`:
the snapshot names that check actually called (or the event it fired) whose
row is UNVERIFIED. A harness line takes the names touched during its whole
suite, because the suite's own result list is local to that file.

`snapshot_counts.unverified_by_source` is the count of UNVERIFIED rows per
`source`, across both `apis` and `events`.

## Snapshot files

Lua files that `return` one table. `python Tools/harness/snapshots.py`
rewrites `forever.lua`, `retail.lua`, and `tbc.lua` from the TOC call sites
plus the probe lists in that script. Review the diff. Do not hand-edit a
generated row and then regenerate.

```lua
["GetItemInfo"] = {
    status = "missing",   -- present | missing
    source = "probe",     -- probe | ui-source | wiki
    build = "70009",
    unverified = false,   -- true means UNVERIFIED
    kind = "function",    -- function | table | frame | number | string
},
```

Rules the loader enforces:

- `source = "probe"` must be `unverified = false`. That is an in-game result,
  not a guess.
- `wiki` and `ui-source` must be `unverified = true`.
- A `present` row is never given `source = "probe"` unless the probe named it.

Forever rows:

- Simulated client: 1.60.1, build **70009**, interface 16001, `WOW_PROJECT_ID` 1.
  Environment.lua records that builds up to 70124 still reported project id 1;
  the interface code is what marks Forever. That project-id note is not the
  2026-09-28 probe, so the `WOW_PROJECT_ID` row stays UNVERIFIED.
- Non-probe rows use build **70938** and `source = "wiki"`. Blizzard's Forever
  UI source for 70938 was not available when this was written, so nothing is
  tagged `ui-source`.
- Probe rows (build 70009, missing): `GetNumSkillLines`, `GetSkillLineInfo`,
  `UnitAttackBothHands`, `UnitDefense`, `UnitRangedAttack`, `GetNumTalentTabs`,
  `GetTalentTabInfo`, `GetTalentInfo`, global `GetItemInfo`, `GetSpellInfo`,
  `GetItemStats`, `GetSpellCooldown`, `GetItemInfoInstant`, `PickupContainerItem`,
  `GetSpecialization`, `UnitAura`, `GetPVPRankInfo`, `UnitPVPRank`, and the
  events `HONOR_CURRENCY_UPDATE` and `PLAYER_PET_CHANGED`.

Retail rows:

- Simulated client: 12.1.0, build **69933**, interface 120100, project id 1.
  Probe date 2026-09-28.
- Probe-missing: `GetSpellInfo`, `UnitAura`, `PickupContainerItem`,
  `GetNumTalentTabs`, `GetTalentTabInfo`, `GetPVPRankInfo`, `UnitPVPRank`.
- Probe-present: `GetItemInfoInstant`, `GetSpecialization`, `C_AssistedCombat`,
  `CreateFramePool`. `C_AssistedCombat.GetNextCastSpell` stays wiki: the probe
  named the namespace, not the method.

TBC rows are the old boot prelude (build string `00000`, interface 20506,
project id 5). Every row is wiki and UNVERIFIED. There is no TBC probe.

Player names in the snapshots and in `Tools/fixtures/saves/` are fake
(`Pebble-Fakeserver`, `Tbctest-Tbcrealm`). Do not put WTF or SavedVariables
from a real account in this tree.

## Add a client

1. Copy `Tools/fixtures/api/tbc.lua` to `Tools/fixtures/api/<id>.lua`.
2. Set `id`, `toc`, `interface`, `project_id`, `version`, `build`, `build_date`,
   and a synthetic `player`.
3. Add one row per API and event you are willing to claim. Use `source = "probe"`
   only for an in-game result you can point at, with that build and
   `unverified = false`. Everything else is `wiki` or `ui-source` and
   `unverified = true`.
4. Set `enforce_events = true` if `RegisterEvent` should reject names that are
   not `present`.
5. Boot it: `python Tools/harness/wowsim.py <id> --report /tmp/out.json`.
6. If a new TOC should feed the generator, add a `write_<id>()` in
   `Tools/harness/snapshots.py` and keep the probe lists in that file.

A present function with no special body returns nil, false, or 0 (Forever and
Retail only; the TBC set uses the prelude's return values). `engine.lua` holds
the few that need real behaviour: frames, timers, `GetBuildInfo`, unit
identity, `CreateFramePool`, `CreateColor`.
