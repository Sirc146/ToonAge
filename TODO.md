# ToonAge — Working TODO

**Written 2026-07-25. Refreshed 2026-07-26.** This is the working queue.
`IMPROVEMENT_PLAN.md` is the strategic roadmap; this is what to actually pick up next.

**Done since it was written** (verified against the tree, not assumed):
item 1 (committed — `48f9c4d`, `25c3ee3`), item 5 (`Core/GuideManager.lua` deleted),
item 15 (`Data/Zones.lua` → `Data/ItemLevels.lua`), item 16 (`.context.md`,
`.competitors.md`, `ASSESSMENT_2026-07-25.md` all gone; `Archive/` and `Monk/` are
now untracked). Struck through below rather than deleted, so the numbering that
other docs reference still holds.

Items are grouped by *why they matter*, not by size. Each says what it is, where it
lives, and — where it isn't obvious — why it's worth doing.

---

## 🔴 P0 — Do these first, in this order

### 1. ~~Commit the work~~ ✅ DONE 2026-07-26
Landed in `48f9c4d` (snapshot) and `25c3ee3` (doc purge + GuideManager removal +
Zones→ItemLevels rename), on branch `chore/pre-refactor-snapshot`.

### 2. `/reload` and smoke-test
Everything except the map-ID data was written but **never executed**. Watch
`/ta errors` after login and after a fight.

**Added 2026-07-26 — this session's changes, also never executed:**

- `Core/Init.lua` — `CopyDefault` on every defaults write, and `/ta reset` now
  calls `InitDB()`. Test on a **fresh install** (rename the SavedVariables file):
  `/ta toggle` a module, then `/ta reset`, then confirm the toggle came back on.
- `Modules/CombatState.lua` — `IsLongRamp` lost its tag branch. Confirm DoTs
  still get suppressed below 3s TTD, and that nothing *else* got suppressed.
- `Modules/FarmOptimizer.lua` — handler is now pcall-wrapped and receives
  `FarmOpt` as arg 1. Loot something with a gathering profession active.
- `Modules/CoordResolver.lua` — only comments and the `sources` diagnostic
  changed. Run **`/ta coord`** (not `/coord`, which is DevHelpers' recorder).
  Two things to read off the output: it should say `C_Navigation (arrow only)`
  rather than plain `C_Navigation`, and whether `C_QuestLog POI` appears at all
  answers half of item 18 for free — that entry tests
  `C_QuestLog.GetNextWaypointForMap`, which is the function whose survival
  decides how `QuerySuperTrack` gets rewired.

**From the previous session, still unverified:**

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

### 5. ~~`Core/GuideManager.lua` is dead code~~ ✅ DONE 2026-07-26
Deleted in `25c3ee3`. The file is gone from `Core/`; `QuestTracker` was never
migrated onto it and now never will be.

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

~~Also note: `IsLongRamp` checks for `dot`/`setup`/`ramp` tags that do not exist
anywhere in the data.~~ ✅ DONE 2026-07-26 — claim re-verified by grep (zero
matches in `Data/`), tag branch dropped in `610e679`. The name-based fallback
now carries it outright. **The ~640 `when` conditions above are still open.**

### 8. `QuestTracker.lua` is 3,673 lines
10% of the codebase, 2.7× the next-largest module. Holds the tracker window,
fast-forward sync, auto-quest, and the quest-item button — which is the natural
three-way split.

### 9. ~~Two small `Core/Init.lua` fixes~~ ✅ DONE 2026-07-26 (`610e679`)
Both fixed. The by-reference bug was worse than described here: it also hit
`db.char`, `db.unifiedPosition` and each table inside `db.oldUiPositions`, and
because `/ta reset` re-derived from the mutated `DB_DEFAULTS`, a reset in the
same session did not actually reset. `CopyDefault` now guards every write.

### 10. ~~Modules outside the error net~~ ✅ DONE 2026-07-26 — **and this entry was mostly wrong**
The claim was that `DungeonGuide` and `FarmOptimizer` had unprotected handlers.
Checked all four private event frames in the addon:

| File | Line | Reality |
|---|--:|---|
| `Modules/CombatState.lua` | 661 | **Already pcall'd + ErrorLog.** Frame is private *on purpose* — see below |
| `Modules/DungeonGuide.lua` | 453 | **Already pcall'd + ErrorLog**, and passes `event` as the stack arg, which `UpdateModules` doesn't |
| `Modules/FarmOptimizer.lua` | 657 | Genuinely raw. **Fixed** — wrapped in the same pattern |
| `Modules/MapPins.lua` | 213 | One-shot `ADDON_LOADED` LOD bootstrap that unregisters itself. Left alone deliberately |

**Do not migrate CombatState onto `TA.eventFrame`.** Two independent reasons,
neither previously recorded outside a comment at `CombatState.lua:644-646`:

1. **Taint isolation.** Taint flows through shared frames. That frame reads
   health/power/aura, and routing it through the frame MapPins and CoordResolver
   also use is how those queries start returning secret values.
2. **Cost.** `UpdateModules` broadcasts every event to every module with one
   `pcall` each. `UNIT_HEALTH`, `UNIT_POWER_FREQUENT` and `UNIT_AURA` on the
   shared frame would mean ~51 pcalls per tick, against `.rules.md`'s own
   performance rules.

A private frame is the correct pattern for high-frequency or taint-sensitive
events. The rule is "every handler is pcall-wrapped," not "every handler is on
the shared frame."

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

### 15. ~~`Data/Zones.lua` is misnamed~~ ✅ DONE 2026-07-26
Renamed to `Data/ItemLevels.lua` in `25c3ee3`. Note this invalidates item 14's
premise: `.rules.md` no longer points you at `Zones.lua` for portal connections,
but `TravelRouter.PORTALS` is still a large literal inside a module and still
belongs in `Data/Portals.lua`.

### 16. ~~Finish the doc consolidation~~ ✅ DONE 2026-07-26
`.context.md`, `.competitors.md` and `ASSESSMENT_2026-07-25.md` are deleted.
`Monk/` and `Archive/` are untracked. `.bootstrap.md`'s SUPERSEDED section now
describes files that no longer exist and can be trimmed on the next doc pass.

### 18. 12.1.0 API audit — unfinished business
`Modules/CoordResolver.lua`'s `QuerySuperTrack` is **knowingly dead** pending a
live dump of the waypoint APIs (see the comment block in that function for the
exact `/dump` lines). Until it's rewired, every step that should resolve via
SuperTrack silently falls through to APR and then to the guide's stored coord.

Related: `.rules.md` and that same comment previously told you to run
`/taapiprobe`. **No such command has ever existed** — `DevHelpers.lua` defines
only `/tarecord`, `/taquestscan`, `/coord`, `/tateleports`, `/taweekly`, `/tadev`.
Both pointers now carry the raw `/dump` lines instead. If a probe command does
get built, seed it with measured values, not guesses.

**Confirmed removed 2026-07-26 — `C_ClassTalents.GetExportString` is `nil`.**
Live dump on this 12.0 client:

    /dump type(C_ClassTalents.GetExportString), type(C_ClassTalents.ImportLoadout), type(C_Traits.GenerateImportString)
    [1]="nil"   [2]="function"   [3]="function"
    /dump C_Traits.GetLoadoutSerializationVersion()   →   2

Four call sites, every one guarded with `if C_ClassTalents.GetExportString then`,
so nothing errors — they simply never run. Silent dead code, the same failure
mode as the 12.1.0 removals:

- `Modules/Talents.lua:559` — captures the live tree into `builds.*.string`.
  **This is why all 39 specs still have `string=""`**: the filler has been inert.
- `Modules/Talents.lua:1133` — user-facing export command, falls to its error branch
- `DevHelpers.lua:739`, `:762` — dev dump, silently skipped

Replacement is `C_Traits.GenerateImportString(configID)` — exists, and is already
used at `Core/Utils.lua:407`. Same input, same output.

**✅ Migrated and verified in-game 2026-07-26.** All 8 occurrences across
`Modules/Talents.lua` and `Modules/DevHelpers.lua` swapped;
`Modules/DungeonTalents.lua:99` already used the correct call, so the codebase is
now consistent. `check_lua.py` passes on all 77 files.

Runtime confirmation — existence was never the question, a non-empty return was:

    /dump C_Traits.GenerateImportString(C_ClassTalents.GetActiveConfigID())
    [1]="C8PAD57yiELKEty14ekTDtZEqMgxMG2lbwMM0gFzMzMGPwy8AAAAAAAmhxMLLz4BMz
         YYZGNDAAAwAAssMzMLmZmxMMzAmZDWwMGzMbGAA"

Real, dense string on a fully-spent tree. The capture path is live: the "Save as
Recommended" button at `Modules/Talents.lua:559` and `/tadev`'s loadout export
both work again for the first time since the removal.

Namespace guards restored to match the project's own idiom at
`DungeonTalents.lua:99` — `if C_Traits and C_Traits.GenerateImportString then`.
A bare symbol swap had left three sites indexing `C_Traits` unguarded while the
enclosing `if` still checked `C_ClassTalents`. `DevHelpers.lua:762` stays bare
on purpose: it is nested inside `:757`'s `if C_Traits and …`.

Guard *policy* deliberately unchanged: these guards convert a missing API into a
silent no-op rather than an error, which is exactly what hid this removal for
weeks. Worth deciding project-wide whether they should warn once instead of
failing quietly — but altering failure semantics is a bigger change than a
symbol swap, so it is not bundled here.

### 17. Opportunistic API migration
21 bare `GetItemInfo` calls remain across `Gear.lua`, `AutoEquip.lua`,
`RoleMorph.lua`, and others. Not on a deprecation path, and `U.GetItemInfo`
exists for new code — migrate when already editing the surrounding function.

**Verified safe 2026-07-26.** `U.GetItemInfo` prefers `C_Item.GetItemInfo`, and
nobody had ever confirmed that returns the same tuple as the global. It does —
18 values, every position identical (see `.rules.md` for the one-line re-check).
That matters because three call sites read by position, and a mismatch would
have given wrong values silently. Migration is safe to continue.

### 19. Talent build strings — source found, one test outstanding
`Data/Talents.lua` holds 39 specs × 3 builds with `string=""` and `nodes={}`;
`Data/TalentsPvP.lua` is the same. The copy button is gated on a non-empty
`string` (`Modules/Talents.lua:322`), which is why a recommended build shows a
name and description but no importable code. Item 18's dead capture path is the
upstream cause — this is a data gap sitting on top of an API regression.

**Icy Veins publishes Midnight 12.0.7 strings at level 90.** Verified by fetch
2026-07-26; plain text in the HTML, no JS rendering required. URL pattern:

    https://www.icy-veins.com/wow/{spec}-{class}-pve-{role}-spec-builds-talents

Confirmed on `unholy-death-knight-pve-dps-…` and `survival-hunter-pve-dps-…`.
Role slot is `dps|tank|healer`; tank/healer unverified — derive it from the
`SPECS` table in `Tools/fetch_talent_builds.py`, do not probe the site to find
out. Note the Survival M+ and Delves strings are byte-identical, so the parser
must tolerate duplicates.

Survival Hunter, single-target, Pack Leader, 12.0.7:

    C8PAAAAAAAAAAAAAAAAAAAAAAMgxMGWgNYGGawixMzMzYZAAAAAAwMmZmhZMmxMYMNDAAAADAMWWmZmFzMzMegZGDYmNADjxM2MA

**TESTED 2026-07-26 — partial import. The cause is a patch mismatch.**

    .build.info:  wow (retail) = 12.0.7.68887
                  wowt (PTR)   = 12.1.0.68914   ← _ptr_, what we develop against

Icy Veins documents **12.0.7**, i.e. live retail. This PTR is **12.1.0**. The
string parses — serialization version is still 2 — and places every node that
still exists, leaving gaps where 12.1.0 moved or changed them. That is the
partial fill observed on Ellacait (Survival, Pack Leader).

**Conclusion: no external site can supply valid 12.1.0 strings**, and none will
until 12.1.0 ships. Icy Veins, Wowhead and mmobuilds all track live 12.0.7.
In-game capture on the PTR is the only source of correct 12.1.0 data. This
reverses the earlier reading of the Icy Veins find — it is a real source, just
for a different patch than the one we build against.

Which makes item 18's `GetExportString` → `C_Traits.GenerateImportString`
migration a hard prerequisite rather than an optional cleanup: it is the only
working capture path, and nothing else can fill `string` on 12.1.0.

**Open decision — the TOC declares both patches:** `## Interface: 120007, 120100`.
So the addon targets retail 12.0.7 *and* PTR 12.1.0, and a single `string` field
cannot be correct for both. Either scope the data to one patch, or key strings
by interface version and select at runtime. Decide before filling 39 specs.

**Direction chosen 2026-07-26: harvest Icy Veins regardless of importability.**
A string that will not import is not the only useful output. Talent *names and
order* survive a patch bump far better than node IDs or encoded strings, so the
same page that yields a 12.0.7 string also yields guidance that is still correct
on 12.1.0 — "take Wildfire Bomb, then Guerrilla Tactics" guides a player through
the tree by hand when the code does not apply. That maps onto fields the schema
already has:

- `string`    — patch-specific, best-effort. Correct only for the patch it came
                from; hide the copy button when it does not match the client.
- `levelPath` — patch-resilient. The durable layer, and the one that makes the
                data worth collecting even when import fails.
- `nodes`     — patch-specific (C_Traits node IDs), same caveat as `string`.

Scope covers **PvE and PvP** builds, which also fills `Data/TalentsPvP.lua`
(every `importString` there is still `""`).

Same harvest should carry **stat weights/priorities**, which Icy Veins publishes
per spec. That feeds `weightSource` (currently `"built-in"` in SavedVariables)
and the Phase 3 "custom stat-weight import" item. Stat priorities are ordinary
text, so unlike loadout strings they carry across patches intact — likely the
highest-durability data on the page.

Wowhead and mmobuilds.com remain **unevaluated** (two guessed Wowhead URLs
404'd; scheme unknown, and JS-rendered pages may not yield to a simple fetcher).
Neither is worth probing while they track 12.0.7 — the constraint is the
client's tree, not the website.

**Capture works across spec switches** (verified 2026-07-26: switched spec,
re-ran the dump, got a different valid string). So the workflow is switch-spec →
dump → repeat, three specs per character, no relogging. That is what makes bulk
capture practical rather than theoretical.

Capture ceiling: **11 of 13 classes are already copied to
the PTR — 33 of 39 specs reachable with no further copies.** Missing are Priest
(Traeintha, 80) and Death Knight (Ellaeura, 71). Only Ellacait is level 90, so
every other capture would encode an 80-point spend — which is not what
`builds.mplus` and `builds.raid` imply. If level-appropriate strings are the
goal instead, the schema must record the level each string was captured at, or
71-, 80-, 82- and 90-point builds mix silently under one field name.

**Direct talent application WORKS on 12.1.0 — verified 2026-07-26.** Tested from
an insecure `/run` in the chat box, the same taint domain an addon runs in:

    /run C=C_ClassTalents.GetActiveConfigID() T=C_Traits.GetConfigInfo(C).treeIDs[1]
    /run print(pcall(C_Traits.PurchaseRank,C,94961)) print(pcall(C_ClassTalents.CommitConfig,C))
    → true true
      true true

`PurchaseRank` succeeded and `CommitConfig` committed. No "Interface action
failed because of an AddOn". `PurchaseRank`, `CommitConfig` and
`ResetTreeByCurrency` all exist and are callable.

Scope of the claim: this proves one node purchase plus a commit. A full build
(reset → many purchases → commit) is more surface, and some paths may still want
a hardware event. Strong signal, not a completed feature.

**This is how BtWLoadouts does it** (`Interface/AddOns/BtWLoadouts`, v1.20.22 —
Dragonflight-era, a design reference not a working Midnight example). It uses no
import strings at all: `PurchaseRank` + `SetSelection` to spend, `CommitConfig`
to apply, `ResetTreeByCurrency` / `RollbackConfig` around it. It absorbs patch
skew as bulk data — one ~1.4MB dataset per interface version
(`DFTalents.100002/100005/100007/100100.lua`), the TOC loading exactly one.
Version detection is runtime, not TOC: `select(4, GetBuildInfo())` in
`Versions.lua`, which is what distinguishes 12.0.7 from 12.1.0 at runtime —
`## Interface` cannot.

Consequence for the data model: `nodes` is now the highest-value field, not
`string`. Node IDs are patch-specific but **capturable in-game** from a built
tree, so they sidestep the external-source patch problem entirely. Division of
labour that falls out of this:

- **Icy Veins** → *which* talents (names, order, stat weights). Patch-resilient
  content, and the part that cannot be captured from a client.
- **In-game capture** → node IDs for the running patch. Enables direct apply.
- **Import strings** → optional convenience, patch-locked, lowest priority.

Blocked on: `U.IsNodeSelected` (`Core/Utils.lua:410`) passes `treeID` to
`C_Traits.GetNodeInfo` where the working form is `(configID, nodeID)` — confirmed
against `TalentsHelpers.lua:448`, `TalentsPvP.lua:89`, and the live test above.
Zero callers today, so no present impact, but it is exactly what a match-scoring
feature would call, and it would silently return false for every node.

Two constraints on any fetcher, both raised by the user:

- **Rate limiting is a requirement, not a nicety.** 39 specs is 39+ requests.
  Cache every response to disk, never re-fetch a cached page, sleep between
  requests, and identify honestly in the User-Agent. A bulk run with no cache
  is what gets an IP blocked — and re-fetches everything on the next run.
- **Redistribution.** These are Icy Veins' curated builds. Attribution in the
  data file and in the UI at minimum. See item 12 for the licensing precedent
  this project already follows.

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
