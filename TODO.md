# ToonAge — Working TODO

**Written 2026-07-25, end of session.** This is the working queue.
`IMPROVEMENT_PLAN.md` is the strategic roadmap; this is what to actually pick up next.

Items are grouped by *why they matter*, not by size. Each says what it is, where it
lives, and — where it isn't obvious — why it's worth doing.

---

## 🔴 P0 — Do these first, in this order

### 1. Commit the work
70 files uncommitted against 7 total commits. Tonight produced engine changes,
22 verified map IDs, and four bug fixes that exist **only on this disk**. Branch,
then commit. Everything below is lower priority than not losing this.

### 2. `/reload` and smoke-test
Everything except the map-ID data was written but **never executed**. Watch
`/ta errors` after login and after a fight. Specifically at risk:

- `Core/Init.lua` — `QueueUIRefresh`, the 0.15s event coalescer
- `Core/UI.lua` — `Refresh(events)` and the three-way `TAB_EVENTS` filter
- `Modules/CombatState.lua` — `when` predicates, `AlreadyActive`, `IsLongRamp`
- `Modules/Rotation.lua` — `GetPredictionPriorities` chain/priorities fallback
- `Modules/TargetMarker.lua` — the icon frame pool
- `Modules/RestOptimizer.lua` — the NaN crash fix
- `Modules/QuestTracker.lua` — `MapZoneDistance` specificity ranking
- `Core/Utils.lua` — six new API wrappers

### 3. Three in-game captures (minutes each, unblock other work)

- [ ] **`/coord` in the Midnight intro area.** Settles whether
      `TAG_Midnight_Intro.lua`'s nine `coord.map = 2434` values are genuine Dead
      Scar coordinates or need re-recording. Only the guide's `zone` was
      corrected — x/y are map-relative and can't be fixed by swapping the ID.
      This is the last unresolved item from the map-ID work.
- [ ] **`/tateleports` on the mage.** The 17 teleport spellIDs were filled from
      knowledge, not read from a live spellbook. Destinations are verified;
      spellIDs are not. (Benign failure mode — a wrong ID means the route
      silently doesn't appear — but it's a one-command fix.)
- [ ] **Combat-test rotation on a level 90 hunter.** Three fixes converge there:
      the TTD filter that skipped nearly every ability once a target dropped
      below 3s to die; the blank prediction bar in 5-mans (Survival's `aoe` view
      has `chain` but no `priorities`); and the new aura-aware suggestion rule.

---

## 🟠 P1 — Phase 1's last item

### 4. Fill guide coordinates — **393 of 449 are stubs (87%)**

The only Phase 1 item left, and the addon's single largest gap: roughly 2,000
lines of navigation code (Arrow, NavHud, AntTrail, MapPins, CoordResolver)
running on 13% real data. Nothing in Phase 2 or 3 improves this, and every guide
feature compounds off it.

Order by payoff — this is extremely lopsided:

| File | Stubs | Share of remaining work |
|---|--:|--:|
| `TAG_Hallowfall.lua` | **309** | **79%** |
| `TAG_Eversong_Midnight.lua` | 35 | 9% |
| `TAG_Naigtal.lua` | 21 | 5% |
| `TAG_Silvermoon_Midnight.lua` | 15 | 4% |
| `TAG_Exiles_Reach.lua` | 13 | 3% |

Use `/coord` — it now logs account-wide and survives reloads and character
swaps. `/coord dump` exports the batch; `/coord clear` resets.

**Before starting Hallowfall:** see item 12 (licensing). If the WoW-Pro
Community grants an exception, their `TWW_Hallowfall.lua` has 473 coordinates
with quest IDs in a near-1:1 schema match, and this becomes a scripting job
instead of a walking job. Worth sending the email before committing days to it.

---

## 🟡 P2 — Code debt with real consequences

### 5. `Core/GuideManager.lua` is dead code
168 lines, 13 public methods, a listener pattern — and **zero callers**. Its own
header carries a TODO to migrate `QuestTracker` onto it; that never happened.
It loads on every login. Finish the migration or delete the file. Leaving it is
worse than either, because it reads as infrastructure something depends on.

### 6. Split `TAG_Naigtal.lua`
Only 4 of its 21 steps are Naigtal. The other 17 are the Void Assaults chain,
which starts in Zul'Aman and runs through Voidstorm. Re-keyed to Quel'Thalas
(2537) as a stopgap so those 17 steps can auto-select at all. The step tags
already draw the line for a clean split.

### 7. Author rotation `when` conditions
Engine is built (`Data/RotationConditions.lua`); 15 conditions applied;
**~640 entries remain**. Do this spec-by-spec against real play.

**Do not auto-derive from the `why` prose.** That was tried and rejected: it
would have gated tank active mitigation (`Ironfur`, `Shield Block`,
`Ignore Pain`, `Purifying Brew`) behind low health, and gated 2-target cleave
*fillers* behind 3+ enemies. 154 entries "matched" a pattern; only 15 were safe.
Confidently-wrong conditions are worse than none — they actively hide correct
abilities.

Also note: `IsLongRamp` checks for `dot`/`setup`/`ramp` tags that **do not exist
anywhere in the data** — only 5 tags are used (`core`, `active`, `cd`,
`defensive`, `aoe`). Only its name-based fallback ever fires. Either add the
tags or drop the tag branch.

### 8. `QuestTracker.lua` is 3,673 lines
10% of the codebase, 2.7× the next-largest module. Holds the tracker window,
fast-forward sync, auto-quest, and the quest-item button — which is the natural
three-way split.

### 9. Two small `Core/Init.lua` fixes
- `DB_DEFAULTS` sub-tables are assigned **by reference**, so on a fresh install
  `db.modules` *is* `DB_DEFAULTS.modules` and `/ta toggle` mutates the defaults.
  First-session-only blast radius, two-line fix.
- `/ta reset` sets `ToonAgeDB = nil` but leaves `TA.db` and `TA.charDB` pointing
  at the orphaned table until reload.

### 10. Modules outside the error net
`DungeonGuide.lua` and `FarmOptimizer.lua` own private event frames, so their
handlers never pass through `UpdateModules`' `pcall`. Errors there surface as
raw Lua errors rather than `ErrorLog` entries. Worth knowing when debugging;
worth fixing if either misbehaves.

### 11. Only 11 of 51 modules are toggleable
`Rotation`, `TooltipScorer`, `NameplateObjectives`, `RoleMorph`, `TargetMarker`,
and `AntTrail` are opinionated enough that users will want them off — and each
one disabled is one fewer dispatch per event.

---

## 🟢 P3 — Data quality and housekeeping

### 12. Send two licensing emails
- **WoW-Pro Community** (`github.com/Ludovicus-Maior/WoW-Pro-Guides`) — their
  guides are CC BY-NC-**ND**. NoDerivs forbids reformatting their route data
  into ToonAge's schema, and being free doesn't exempt us. A written exception
  would collapse item 4 from days of walking into a scripting task.
- **APR authors** — their TOC says *"All Rights Reserved: You are free to fork
  and modify on GitHub, please ask us about anything else."* Extraction is
  "anything else." Just ask.

**Never extract from Zygor or Dugi** (both installed under `_retail_`). Paid
commercial products whose route data *is* the product.

### 13. Remaining map IDs to verify
- `2600` Naigtal — gated content, not yet unlocked. Accepted on strong external
  evidence (two addons, one with an explicit in-game `/dump` note, from a source
  that matched 6/6 IDs verified here). Confirm when the zone unlocks.
- Emerald Dream — its portal entries were **removed** rather than left pointing
  at 2215 (Hallowfall). Re-add once the real destination is confirmed.
- Unwalked Midnight zones: Zul'Aman 2437, Val 2599, Broken Throne 2585,
  Daggerspine Point 2594.
- Horde mage teleport destinations (Alliance set is fully verified).
- `85` Orgrimmar — the one hub ID not personally confirmed. Low risk.

### 14. Move the portal database into `Data/`
`TravelRouter.PORTALS` is a large literal table inside a module, violating the
project's own static-data-lives-in-`Data/` rule — and it's why `.rules.md` tells
you to update `Data/Zones.lua` with portal connections, which is the wrong file.
Move to `Data/Portals.lua`.

### 15. `Data/Zones.lua` is misnamed
It holds Season 1 item-level track data (`Z.TYPE`, `Z.TRACKS`, `Z.READINESS`,
`Z.UPGRADE_SOURCES`), not zone geography. Rename when convenient, and fix the
`.rules.md` line that describes it wrongly.

### 16. Finish the doc consolidation
`.context.md` and `.competitors.md` are marked superseded in `.bootstrap.md` but
still present — deletion is the owner's call. `ASSESSMENT_2026-07-25.md` is a
dated point-in-time audit; fold its findings into `IMPROVEMENT_PLAN.md` and
delete, or keep it dated and never update it.

Also: `Monk/` (2-file skeleton) and `Archive/` are tracked in git and probably
shouldn't be.

### 17. Opportunistic API migration
19 bare `GetItemInfo` calls remain across `Gear.lua`, `AutoEquip.lua`,
`RoleMorph.lua`, and others. Not on a deprecation path, and `U.GetItemInfo`
exists for new code — migrate when already editing the surrounding function.

---

## Phase 2 / 3 / 4 (from `IMPROVEMENT_PLAN.md`, unchanged)

- **Phase 2** — Dungeon guides, reputation module, War Within zone coverage,
  achievement/Loremaster layer
- **Phase 3** — Gold & economy, mounts collection, party sync, quest NPC markers,
  custom stat-weight import, custom AltTracker tasks
  *(§3.5 condition-based rotation: engine built ahead of schedule, data pending —
  see item 7)*
- **Phase 4** — Expansion metadata, data pipeline automation, seasonal checklist

---

## Where things stand

**Phase 1 is one item from complete.** Items 1–3 are hygiene and verification;
item 4 is the actual remaining work, and it needs playtime rather than code.

Everything in P2 and P3 is real but none of it is blocking. If tomorrow only
produces "committed, smoke-tested, and 100 Hallowfall coords recorded," that is
a better day than clearing all of P2.
