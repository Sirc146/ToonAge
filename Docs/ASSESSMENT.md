# ToonAge assessment

Reviewed 2026-10-09 from the source tree, the offline test suite, and the
current interface table on Warcraft Wiki (TOC format). No game client was
available in this review, so nothing here is a claim that a feature was
clicked through in game. "Working" means the code and data for that feature
are loaded on that client and the offline tests that cover them pass.
"Partly working" means the feature exists but a known gap keeps it from
doing the job. "Broken" means it is present and will mislead or fail.
"Missing" means that client does not ship it.

The owner's bar is that the addon works before any visual polish. This
document is about that bar.

## How the flavors are split

WoW loads one TOC. Each target client has one, and the unsuffixed
`ToonAge.toc` is a copy of the Retail file list for a retail client this
project does not recognise yet.

| Client | TOC | Interface | Profile |
|---|---|---|---|
| Retail (Midnight) | `ToonAge_Mainline.toc` | 120100 live, 120105 test, 120001 beta | `retail`, allow every registered module |
| WoW Forever | `ToonAge_Camelot.toc` | 16001 | `forever`, explicit allow-list |
| Mists Classic | `ToonAge_Mists.toc` | 50504 | `mists`, leveling companion |
| TBC Anniversary | `ToonAge_TBC.toc` | 20506 | `tbc`, advisory companion |
| Classic Era | `ToonAge_Vanilla.toc` | 11509 | `vanilla`, scaffold |

Those interface numbers match the wiki table as of this review. They were
not changed. Cataclysm (`ToonAge_Cata.toc`, 40402) and Wrath
(`ToonAge_Wrath.toc`, 30405) also exist. They are the same kind of empty
scaffold as Classic Era. They are not target clients for this review.

The filename `ToonAge_Camelot.toc` is required. The Forever client's loader
still matches Blizzard's old codename. A file named `ToonAge_Forever.toc`
is not read.

## Feature ratings

### Retail (Midnight)

The full product. 133 Lua files in the TOC, all parsed. This is the only
client with a guide engine, a rotation engine, delves, and a weekly view.

| Area | State | Notes |
|---|---|---|
| Guides | Partly working | 45 guide files and about 21,300 steps with quest IDs. 21,289 of 21,345 coordinates are `0, 0`. Only Exile's Reach and the Midnight intro have real coordinates. The arrow, ant trail, and map pins have almost nothing to point at. Quest order can still be shown. |
| Gear scoring | Working | `Core/StatEngine.lua` plus `Data/Retail/StatWeights.lua`. Offline gear tests pass. Weights are static and will drift every season until someone refreshes them. |
| Rotations | Partly working | `Data/Retail/Rotations.lua` is about 9,700 lines of priority data, and `CombatState` tracks live conditions. Midnight refuses the combat log, so damage and healing are not recorded; casts come from spell-cast events. Target-cast tracking was missing from the high-frequency route until this review. |
| Talents | Partly working | Live tree reads go through `C_Traits` / `C_ClassTalents`, with static builds in `Data/Retail/Talents.lua`. A talent revamp needs a data pass and an in-game check. The code guards the APIs. |
| Professions | Partly working | `Data/Retail/Professions.lua` and a Professions tab. Profession specialization APIs move often. Not confirmed on a current character. |
| Farm routes | Partly working | There are no route polylines. `Data/Retail/FarmRoutes.lua` is gold-per-item guesses, and the Midnight herb and ore IDs in it are labeled placeholders (`220001` and similar). Using those numbers would score the wrong items. Gathering nodes can be recorded while you play. |
| Dungeons | Partly working | `Data/Retail/Dungeons.lua`, dungeon gear, dungeon guide, and delves are all on the Retail TOC. Season item levels and crest costs go stale. Needs a pass against the current season. |
| Character tab | Working | Spec, item level, and stat readout are implemented and covered by the retail data tests. Compare a live character sheet before trusting a weight. |
| Minimap / compartment | Working | The Retail TOC registers the addon compartment, and login still creates the round minimap button. Both should appear. Compartment click handlers are global functions in `Core/Init.lua`. |

`C_Navigation.GetDestination` is gone on 12.1 and the call is guarded, so
its removal does not error. It also no longer supplies coordinates. That
matches the empty guide coordinates above.

### WoW Forever

A separate product on purpose. The Camelot TOC does not load Retail data
or Retail modules. What ships is a readout of what this client reports,
plus a harvester that is how Forever data gets measured.

| Area | State | Notes |
|---|---|---|
| Guides | Missing | No guide files and no guide modules. Existing guides describe other games. |
| Gear scoring | Partly working | The Gear tab lists equipped items and the stats on them. It does not score upgrades. There is no weight table, and there should not be one until it is measured on this client. |
| Rotations | Missing | The Spells tab is a spellbook readout, not a priority list. The combat recorder is banned: loading it raised a Blizzard-UI-only action block. A cast log on the player's own spell-cast event is the replacement. |
| Talents | Partly working | Readout of the trees and points spent, from harvested data. No recommended build. |
| Professions | Missing | No profession advisor. The harvester can record trainer rows. |
| Farm routes | Missing | `GatherTracker` can record nodes. The HUD that used to draw them is not in this TOC, and the draw path is nil-guarded. |
| Dungeons | Missing | No dungeon or weekly modules. |
| Character tab | Working | Readout of what the client says about this character. Offline tests cover it. It does not rank anything. |
| Minimap / compartment | Partly working | The minimap button is in the TOC. The addon compartment is not declared. Forever has blocked some addon actions before, so the button still needs an in-game look. |

### Mists of Pandaria Classic

A leveling companion: character, gear, pet care, and a guide stack. The
guide stack has no guide. Offline Mists data tests pass (47 assertions).
This build has not been confirmed in a Mists client during this review.
The project's own accuracy note (2026-09-16) already fixed several wrong
gear rules; those fixes are in the tree.

| Area | State | Notes |
|---|---|---|
| Guides | Broken | The only file is an empty Exile's Reach stub, and that zone does not exist in Mists. The Guide tab is hidden when no guide has steps, so the player is not walked to a fake zone. The navigation modules still load and have nothing to follow. |
| Gear scoring | Partly working | Spec weights, hit and expertise caps, armor proficiency, and auto-equip are implemented and tested offline. Most melee specs share one template. Breakpoints such as a Balance haste cap are not encoded. Spirit-to-hit was assumed, not measured on a character sheet. |
| Rotations | Missing | No rotation module on this TOC. |
| Talents | Missing | MoP talents are six tiers of three choices. Neither the Retail loadout code nor the TBC point-tree code is loaded, and there is no Mists replacement. |
| Professions | Missing | No profession module or data. |
| Farm routes | Missing | Node recording only. No routes. |
| Dungeons | Missing | No dungeon list, loot table, or guide. |
| Character tab | Partly working | Spec, caps, and armor. Same caveats as gear scoring. |
| Minimap / compartment | Working | Shared minimap button. No compartment entry, which is correct on a Classic client. |

Mists modules are copies under `Modules/Mists/`, not the Retail files with
a flavor check. A fix in one tree does not land in the other.

### TBC Classic (Anniversary)

An advisor, not a leveler. The TOC says questing stays with Zygor. Boot,
data, and render tests pass. Interface 20506 matches the Anniversary
client.

| Area | State | Notes |
|---|---|---|
| Guides | Missing | By design. No guide files on this TOC. |
| Gear scoring | Working | Hard caps (hit, expertise, defense), not Retail diminishing returns. Auto-equip uses that score. Offline tests pass. Still worth a look at a level 70 character sheet. |
| Rotations | Partly working | Static priority lists per spec in `Data/TBC/TBCRotations.lua`. Not a live "press this next" button. |
| Talents | Partly working | Suggested builds and a hit-from-talents table. The addon does not spend talent points for you. |
| Professions | Partly working | Profession advisor and profession data are on the TOC. |
| Farm routes | Missing | No gather module on this TOC. |
| Dungeons | Missing | No dungeon module. Gear advice is not a per-boss loot list. |
| Character tab | Working | Character, stat caps, weapon skill, and racials are separate tabs and are on the allow-list. |
| Minimap / compartment | Working | Shared minimap button. No compartment, which is correct here. |

### Classic Era

The client is recognised. The addon can load. It does not advise.

| Area | State | Notes |
|---|---|---|
| Guides | Missing | No `Data/Vanilla`, no guide modules. |
| Gear scoring | Missing | Profile is a scaffold with an empty module list. Retail and TBC numbers are not applied. |
| Rotations | Missing | |
| Talents | Missing | |
| Professions | Missing | |
| Farm routes | Missing | |
| Dungeons | Missing | |
| Character tab | Missing | The window can open and say there is no content. It does not show a character advisor. |
| Minimap / compartment | Working | The minimap button is part of the shared core this TOC loads. There is no compartment entry. |

What Classic Era needs, and what this review did not invent: researched
vanilla stat weights, talent trees, spell ranks, and starting-zone guides,
then modules that read only that data, added to `ToonAge_Vanilla.toc` at
the same time the profile stops being a scaffold. Copying TBC or Mists
numbers onto Era would be the failure the scaffold exists to prevent.

## Code quality

The split between "what client is this" (`Core/Environment.lua`), "what
should run" (`Core/Profile.lua`), and "what files even load" (the TOC) is
sound. A wrong TOC now refuses to start product modules. SavedVariables
are deep-defaulted and migrated in `Core/Init.lua`; the migration tests
pass, and upgrades do not wipe the database.

The hard parts to maintain:

- Retail `Modules/Navigation/QuestTracker.lua` is about 3,700 lines. The
  Mists quest tracker is a second copy. Guide work has to be done twice,
  and it is easy to fix one and leave the other wrong.
- `Data/Retail/Rotations.lua` is a single 9,700-line data file. A bad edit
  is hard to review.
- The event-route table is generated by searching module source for event
  names. It works, and a stale table is now a test failure, but a mention
  in a comment is enough to add a module to a hot path.
- Mists, TBC, and Forever each carry their own Gear and Character modules.
  That isolation is why a Retail API change does not crash TBC. It is also
  why bug fixes do not travel.
- Many widgets call `SetBackdrop`. The ones inspected in the core UI pass
  `BackdropTemplate`, which modern clients require. A frame created without
  that template will error when it is shown. This was not mass-edited;
  it needs an in-game pass, not a blind rewrite.
- Midnight item IDs in the farm-value table are placeholders. They should
  be removed or replaced with real IDs before that table is trusted.
- `Tools/ci-tests.yml` described a GitHub workflow but lived outside
  `.github/workflows`, so nothing ran it. The parse step also checked only
  the unsuffixed TOC. Both are corrected in this change. The two copies
  must be kept identical.

## What this review changed

- Regenerated `EVENT_ROUTES` so `CombatState` receives
  `UNIT_SPELLCAST_SUCCEEDED`. The target-cast work named that event and
  the route table was never rebuilt, so the main dispatcher skipped it.
- Put CurseForge project id `1734520` in every TOC. The Wago id was
  already set.
- Pointed version tags at the BigWigs packager for CurseForge and Wago.
  The old Wago workflow passed `-d`, which tells the packager to skip
  every upload.
- Taught the syntax check to parse every TOC, and added that workflow
  where GitHub Actions will actually run it.
- Added Forever (interface 16001) to the WowUp `release.json` flavor list.

No interface numbers were changed. No visual layout was changed. No
Classic Era or Mists guide content was invented.

## Recommended order of work

1. Harvest real coordinates for the Retail guides, starting with Midnight
   zones. Until `x` and `y` are non-zero, the navigation stack cannot
   guide anyone. Do not hand-author thousands of coordinates.
2. Replace the placeholder Midnight herb and ore IDs, or stop scoring
   items that are not in the table.
3. Log into each target client once and run `/ta test` and `/ta health`.
   The offline suite cannot see frames, taint, or a missing API. Forever
   first if a beta client is up, then Retail, then TBC, then Mists.
   Classic Era should only be checked to confirm the scaffold opens and
   stays silent.
4. Decide whether Mists is a guide addon. If yes, it needs real 1-90
   routes and the Exile's Reach stub should go. If no, drop the unused
   navigation modules from `ToonAge_Mists.toc` so the client does not load
   them.
5. Add a Mists talent readout only after the tier API is confirmed in
   game. Do not port Retail `C_Traits` code onto that client.
6. Classic Era content is a research project. Keep the scaffold until the
   data exists. Wrath and Cataclysm can stay scaffolds; no current client
   in the target list loads them.
7. Split `QuestTracker.lua` only when a change is already going through
   that file. A rewrite for its own sake is how features break.
8. After the next Retail season, refresh stat weights, dungeon item
   levels, and rotation data. Treat that as recurring data work, not a
   one-time bug.
