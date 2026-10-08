# Spec — Harvest as the sensor array on every client

**Status:** APPROVED by Christopher, 2026-10-04 16:43, with D1-D6 decided as recommended (§8). Implementation is T1-T10, one commit each, each with its own in-game check.
**Load-bearing constraint (Christopher):** Forever must behave exactly as it does now before any other client gets a pack.
**Author:** Claude (implementer). **Verifies in-game:** Christopher. **Audits:** Pepper.
**Trunk at spec time:** files read on 2026-10-04 at about 15:00: `Modules/Forever/DataHarvester.lua` (1,518 lines, 71,700 bytes), `Modules/Infrastructure/CoordHarvester.lua`, `Core/Profile.lua`, `Core/ApiGuard.lua`, `Docs/G3_API_GATE.md`, `Tools/gen_forever_data.lua`, `Tools/test_harvester.py`, and all eight TOCs.
**Sequencing:** Christopher, 2026-10-04: build now, without waiting for G3. The G3 tradeoff becomes a design constraint (§4.2).

---

## 1. Problem

Today the Harvest tab exists only on Forever. Every other client's features run on frozen data in `Data/<Client>/*.lua`, typed in from outside sources. Two problems follow from that:

- The project's honesty rule ("every claim sourced and version-stamped") is met only where someone researched the number.
- Nothing tells us when a client patch changes the ground truth.

Forever proved the alternative works:
- The client is the source. The player is the instrument. The store records what the client said, verbatim.
- Consumers read that. On Forever the Spells tab's rank table comes from harvested trainer ranks and catalog entries (`Forever/Rotation.lua:391-450`).
- `Tools/gen_forever_data.lua` turns a harvest into shipped `Data/Forever/*.lua` files.

**Goal.** Every client records what it actually exposes, and every client's features can consume that recording instead of assumptions.

---

## 2. Requirements

**R1 — Shared core.** A client-agnostic harvester core lives in shared infrastructure, following the `CoordHarvester` precedent (§3.2). It owns:
- recording,
- the store,
- export,
- the full report,
- the Harvest tab.

**R2 — Swappable detection layer.** One module answers "what does this client expose", with a clean interface that G3's capability resolver can replace later without touching any harvester or probe pack.
- No probe pack does its own detection: no `_G[name]`, no `X and X.Y` existence checks, no `type(fn) == "function"`.
- A test enforces this.

**R3 — Per-client probe packs.** Each client loads a pack that declares which data domains it harvests and any probes specific to that client. The TOC is the packaging gate: a client's TOC lists only its own pack.

**R4 — Per-client harvest lists with named consumers.** §5 is the contract.
- Each domain on each client names its consumer, marked **existing** (code reads it today) or **planned** (a spec or feature will read it).
- No domain ships without a consumer line.

**R5 — Verbatim store.** The store records what the client returned. Interpretation happens in consumers, never in the harvester. The tab keeps its sentence: "Nothing here is interpreted, weighted or ranked."

**R6 — Beta-only sections stay on Forever.** These are:
- the world refresh log,
- the Comprehension and scroll probes,
- the `C_SkillInfo` skill-line probes.

**R7 — UX unchanged in kind.**
- Button-driven, one clickable button per action. No feature is reachable only from the command line. The existing `/ta report`, `/ta probe` and `/ta catalog` stay as aliases.
- Every result opens in the popup copy window, never in chat.

**R8 — Export gap 1.** The Export row gains **Trainer ranks** and **Spell catalog** buttons. On the current Forever harvest those are about 39 ranks and 85 catalog entries. The export row is data-driven, so each client shows exactly the sections it harvests.

**R9 — Export gap 2: stamps.** Every export, in game or from the saved file, carries:
- the client flavor,
- the client version,
- the build number,
- the interface number,
- the project ID,
- the channel,
- the harvest date range,
- the export time,
- the store version,
- the ToonAge version.

The channel follows the S3 decision: an explicit value or `unknown`, never guessed from realm names.

**R10 — Export from both paths.** The in-game buttons and a Tools script reading the saved file produce byte-identical section output, from one shared formatter.

**R11 — Silent, idempotent, bounded.** Kept from DataHarvester's header rules:
- No frames, no chat spam.
- First-seen records are skipped cheaply.
- Every table has a hard cap.
- New: no scan runs during combat lockdown. A missed scan is caught by the next event or by Full report.

**R12 — No data loss.** The 106 talent, 93 item, 53 spell, 5 racial and 2 character records in the current Forever store, plus its trainer and catalog tables, survive migration intact. The test proves equal counts per section.

**R13 — Per-feature commits, branch-only pushes, no tags** without Christopher's approval. Each task is verified with `/ta test` on the client it touches, after `build_flavors.ps1 -Check` shows that client is current.

---

## 3. Audit

### 3.1 What `Modules/Forever/DataHarvester.lua` contains

Line references are to the trunk copy read on 2026-10-04.

| Piece | Lines | Class |
|---|---|---|
| `Try` guarded call | 73-78 | **core** (it becomes the detection layer's `Call`) |
| `Store()` with backfill | 84-104 | **core** (keyed under `TA.db.foreverHarvest` today) |
| `Count` / `Put` / `PutOrUpgrade` / `Clean` | 106-138 | **core** |
| Items: stat string, item info, item ID, equipped/bags/loot scans | 146-263 | **domain**, reusable on every client |
| Racials (tooltip via `C_TooltipInfo.GetSpellByID`) | 284-320 | **domain** |
| Spellbook (modern `C_SpellBook` path, plus legacy `GetSpellTabInfo` path) | 322-411 | **domain** (the legacy path already exists for Era and TBC) |
| Legacy talent trees (`GetNumTalentTabs` / `GetTalentInfo`) | 420-445 | **domain** (Era, TBC) |
| Trait tree (`C_Traits`: nodes, geometry, gates, conditions) | 461-584 | **domain** (Forever, Retail) |
| Character snapshot (GUID key) | 591-613 | **domain** |
| Bag-scan debounce | 617-625 | **core** |
| Trainer (format 2; already handles Classic Era's return order, line 696) | 640-736 | **domain** |
| Event fan-out | 738-769 | **core** (routes events to the domain packs) |
| Probe primitives `Show` / `Call` / `NS` | 779-813 | **core** |
| Probes: Client, Character sheet, Combat, Map | 821-825, 849-869, 994-1008 | **core** probe sections |
| Probes: Comprehension 3012, Comprehend Scroll 1296017 | 836-838 | **Forever-only** |
| Probes: `C_SkillInfo` skill lines | 871-892 | **Forever-only** (its comments describe it as a Forever finding) |
| Probes: talent-tree geometry | 894-934 | **domain** (trait tree) |
| Probes: spell ranks | 936-992 | **domain** (ranked clients) |
| Probes: scroll tooltips in bags | 1010-1031 | **Forever-only** |
| Export paging and stamps | 1050-1110 | **core** (the header moves to the shared formatter) |
| Spell catalog engine | 1139-1252 | **core** engine; the ID ranges (1134) are **client config** |
| Run all / Full report | 1268-1333 | **core** (it hardcodes 5 sections at 1266; becomes data-driven) |
| Tab render | 1339-1482 | **core** shell; the world refresh button (1411-1418) is **Forever-only** |
| Init `if not TA.IsForever` stand-down | 1489 | removed; the TOC plus profile gate replaces it |

**Detection done by hand today.** All of these become calls to the detection layer (§4.2):
- `C_X and C_X.Y` checks at lines 148, 170, 185, 237, 244, 285, 331, 346, 355, 464, 481, 493, 521, 556, 567, 648 and 1142.
- The `_G[n]` loop at 644-647.
- `Try(_G.IsTradeskillTrainer)` at 662.
- Raw globals passed into the probes' `Call`.

### 3.2 The `CoordHarvester` precedent

`Modules/Infrastructure/CoordHarvester.lua` is a module registered with `TA:RegisterModule`. Its pattern:
- It stores account-wide data per client under `TA.db.coordHarvest`.
- It registers its own events through `TA:RegisterEvent`.
- It has a hard cap (`MAX_ENTRIES = 2000`).
- Export returns text, and slash commands sit on the module.

It loads from the Forever, Mainline and fallback TOCs. The shared core follows the same shape.

### 3.3 Who reads the store today

All of these move to the new key in the same commit as the migration (task T3):

| Reader | Reads | What changes |
|---|---|---|
| `Modules/Forever/Rotation.lua:395-403` | `foreverHarvest.catalog`, `.trainer`, `.trainerFormat` | it reads through `TA.Harvester:Store()` instead |
| `Core/Init.lua:1095` `GuardCounts` (the SavedVariables tripwire) | `foreverHarvest` items, spells, talents, chars, racials | it counts the new key. If it didn't, migration would look like a "shrank" incident. |
| `Tools/gen_forever_data.lua:30` | `ToonAgeDB.foreverHarvest` | it reads `harvest`, falls back to `foreverHarvest`, and takes the S3 channel argument |
| `Tools/test_harvester.py` | pins Forever-only shipping (lines 91-102) | the pins are rewritten (§7, D6) |

### 3.4 API evidence per client

These rows come from the self-test reports of 2026-10-04, which I read this session.

| API | Forever 1.60.1 | Era 1.15.9 | TBC 2.5.6 | Mists 5.5.4 | Retail 12.1.0 |
|---|---|---|---|---|---|
| `C_SpellBook.GetNumSpellBookSkillLines` | present | absent | absent | absent | present |
| `GetNumTalentTabs` / `GetTalentTabInfo` | absent | present | present | present | absent |
| `C_ClassTalents.GetActiveConfigID` | present | absent | absent | absent | present |
| `C_Traits.GetConfigInfo` | present | present | present | present | present |
| `C_Item.GetItemStats` | present | absent | absent | absent | present |
| `C_TooltipInfo.GetHyperlink` | present | absent | absent | absent | present |
| `C_Spell.GetSpellSubtext` | present | present | present | present | present |
| `GetSpecialization` / `GetSpecializationInfo` | absent | absent | absent | absent | present |

**Not yet measured on Era, TBC or Mists:**
- `GetTrainerService*`
- `C_Spell.GetSpellName` and `C_Spell.GetSpellLevelLearned` (which the catalog engine needs)
- the global `GetItemStats`
- `C_TooltipInfo.GetSpellByID`
- `C_SpecializationInfo.*`

The first probe run on each client settles these: task T6-T9, step 1.

### 3.5 Premise correction (verified)

The brief asks for "spell ranks, trainer ranks, talent trees" on Era, TBC **and Mists**. Mists cannot provide the first two:
- Spell ranks were removed in **patch 4.0.1** ([warcraft.wiki.gg — downranking](https://warcraft.wiki.gg/wiki/downranking)).
- From **patch 5.0.4**, "New spells are now learned automatically. Class trainers are only needed to change talents, glyphs, class specialization, or to utilize the dual specialization feature." ([warcraft.wiki.gg — Class trainer](https://warcraft.wiki.gg/wiki/Class_trainer))

Mists Classic (5.5.4) follows the 5.x rules. Whether its trainers list anything at all is unverified, so the Mists pack runs the trainer **probe**, but no rank-table consumer depends on it. Mists harvests the spellbook with each spell's trained level (no rank text), its talent grid, specialization and glyphs instead (§5).

---

## 4. Design

### 4.1 Files and load order

```
Core/Caps.lua                              detection layer (§4.2). Not a module; a library like Core/Compat/API.lua
Modules/Infrastructure/HarvestFormat.lua   pure formatter: sort, flatten, stamp header. No WoW API calls; Tools dofile()s it
Modules/Infrastructure/Harvester.lua       core: store, record helpers, scheduler, event fan-out, export, full report, tab, catalog engine
Modules/Harvest/Domains/Items.lua          domain packs: logic only, every client API call through Caps
Modules/Harvest/Domains/Character.lua
Modules/Harvest/Domains/Spellbook.lua
Modules/Harvest/Domains/TalentTrees.lua    legacy trees (Era, TBC); MoP grid shape lives in the Mists pack
Modules/Harvest/Domains/TraitTree.lua      C_Traits (Forever, Retail)
Modules/Harvest/Domains/Trainer.lua
Modules/Harvest/Domains/Racials.lua
Modules/Harvest/Domains/Stats.lua          character-sheet numbers, verbatim
Modules/Harvest/Domains/Professions.lua
Modules/Harvest/Packs/Forever.lua          client packs: which domains, catalog ranges, client-only probes and buttons
Modules/Harvest/Packs/Era.lua
Modules/Harvest/Packs/TBC.lua
Modules/Harvest/Packs/Mists.lua
Modules/Harvest/Packs/Retail.lua
Tools/export_harvest.lua                   saved file -> stamped TSV per section, via HarvestFormat
```

- Each client's TOC lists: `Core\Caps.lua`, the formatter, the core, the domains that client uses, and **its own** pack.
- The module keeps the name `DataHarvester`, so profile allow-lists, the `harvest` tab entry, `/ta health` and the module toggles keep working. Only the file moves.
- `Modules/Forever/DataHarvester.lua` is deleted in T4, once parity is shown.

### 4.2 Detection layer — `Core/Caps.lua` (swappable; G3 replaces it)

```lua
TA.Caps = {
    Provider = "harvest-local",            -- "g3" once G3's resolver answers
    State = function(path) end,            -- "present" | "missing" | "secret"   (G3 §4.2 APIState vocabulary)
    Fn    = function(path) end,            -- the callable when present, else nil
    Call  = function(path, ...) end,       -- ok, ... ; never throws; a secret return comes back as the string "secret"
    Seen  = function() end,                -- { [path] = state } for every path asked this session
}
```

- `path` is a dotted name: `"C_Spell.GetSpellName"`, `"GetTrainerServiceInfo"`. It is resolved against `_G` one segment at a time. It is the same resolution `ApiGuard`'s `Resolve(path)` already does, but this layer does not depend on ApiGuard internals.
- **The swap.** When G3 lands, `State` delegates to `TA:APIState(path)` and `Provider = "g3"`. `Fn`, `Call` and `Seen` keep their behaviour. No domain or pack file changes. A test (§7) swaps in a stub provider and runs every pack unchanged.
- **Recorded verbatim.** On every scan the core writes `Seen()` into `store.api[path] = state`. The export therefore says what the client exposed, which is what a crowdsourced receiver needs.
- **Packs declare needs as data.** For example `needs = { "C_Traits.GetNodeInfo", ... }`. A domain whose required paths are missing is skipped, and the store records why. It is never treated as an error.

### 4.3 Store — `TA.db.harvest` (version 3)

```
TA.db.harvest = {
  version = 3,
  client  = { flavor, projectID, version, build, interface, channel, firstSeen, lastSeen },
  api     = { [path] = "present" | "missing" | "secret" },
  times   = { [section] = { first = t, last = t } },   -- when records were written, for R9's harvest-date range
  -- sections (each declared by a domain; a client stores only what its pack enables):
  items, chars, spells, racials, talents, talentGeo, talentGates, talentConds, talentApi,
  trainer, trainerFormat, trainerApi, catalog, catalogPasses, catalogBuild,
  stats, professions, specs, glyphs,
}
```

- Each WoW client keeps its own `WTF` tree, so one key per install is naturally one store per client.
- **Migration (one time, on Forever).** If `harvest` is absent and `foreverHarvest` is present:
  1. Move the table to `harvest`.
  2. Fill in `client`, `api` and `times`.
  3. Set `version = 3`.
  4. Set `foreverHarvest = nil`.

  Moving rather than copying avoids writing the same table twice into the saved file. The tripwire and all readers switch in the same commit (§3.3). Christopher's 14:16 robocopy backup is the rollback. **D2** asks whether to move or keep the old key.
- Caps stay as they are (items 20,000; spells 6,000; talents 2,000) and apply per section.

### 4.4 Domain and pack contract

```lua
TA.Harvester:RegisterDomain{
    id = "trainer", sections = { "trainer" }, needs = { "GetNumTrainerServices", "GetTrainerServiceInfo" },
    events = { "TRAINER_SHOW", "TRAINER_UPDATE" },  -- the core registers these via TA:RegisterEvent and routes them back
    scan = function(D, event) ... end,              -- D = record helpers + Caps
    probe = function(P) ... end,                    -- optional lines for the probe report
    export = { { section = "trainer", label = "Trainer ranks", flatten = "CLASS:key" } },
}

TA.Harvester:RegisterPack{
    client = "tbc",
    domains = { "items", "character", "spellbook", "talentTrees", "trainer", "catalog", "racials", "stats", "professions" },
    catalogRanges = { ... },                         -- client config; unmeasured ranges are marked so in the pack
    probes = function(P) ... end,                    -- client-only probe sections
    buttons = { ... },                               -- client-only tab rows (Forever: World refresh)
}
```

The core builds the Export row from the enabled domains' `export` entries. That is how R8's Trainer ranks and Spell catalog buttons appear, and how Retail shows Stats and Professions instead of Spells.

### 4.5 Export and stamps (R9, R10)

The shared header comes from `HarvestFormat.Header(meta, section, page, pages, first, last, total)`:

```
-- ToonAge harvest · trainer · page 1/1 · records 1-39 of 39
-- client forever · 1.60.1 · build 70205 · interface 16001 · project 18 · channel beta
-- harvested 2026-09-26 .. 2026-10-04 · exported 2026-10-04 15:10 · store v3 · ToonAge 2.0.0-dev.1
```

- **Channel in game:** the value stored in `client.channel`, set only by the Harvest tab's channel button. **D1** decides whether that button exists. Default is `unknown`.
- **Channel from the saved file:** `Tools/export_harvest.lua <ToonAge.lua> <outdir> [channel]`. The argument wins; if it is absent, the stored value is used; if neither exists, `unknown`. Never guessed (S3).
- **Harvest range:** the earliest and latest write in `times`. Records moved or merged in from `foreverHarvest` (D2) were written before the store kept write times, so a moved store prints `harvested unknown .. <last>`; the start is never dated to the day of the move. Reset starts a fresh store whose range is fully dated. The core, `export_harvest.lua` and `gen_forever_data.lua` share the rule (found in T3's in-game check, 2026-10-04: the first T3 build printed `2026-10-04 .. 2026-10-04` over records stored before T3 existed).
- **Nested tables** such as `trainer[CLASS][key]` flatten to `CLASS:key` rows, so every section exports as one sorted TSV.
- `gen_forever_data.lua` keeps writing `Data/Forever/*.lua` and gains the S3 header: build, interface, channel, harvest date.

### 4.6 Tab (R7)

- Same rows as today, built by the core from the active pack: Harvested-so-far counts, Full report, Export row with Prev and Next, Catalog scan (ranked clients only; renamed in T4 from "Spell catalog" so it can't be confused with the Copy button), Client probes, Dev tools, Reset with two clicks. Client-only rows come from the pack (`tabRows`; Forever: World refresh).
- New: one **Channel** row (unknown → beta → live → ptr), if D1 is approved.
- Every output goes to `TA:ShowCopyWindow`.

### 4.7 Combat and secret values

- Scans check `InCombatLockdown()` and defer to `PLAYER_REGEN_ENABLED`.
- A secret return (Retail 12.x, or Forever where measured) is stored as the literal `secret`. It is never treated as zero or as absent. This matches the honesty constraint ("stale-not-zero in combat").

---

## 5. Per-client harvest lists and consumers (the R4 contract)

Each cell is ✓ (harvest), probe (record the API state and shape only, pending measurement) or — (not harvested). Consumers are marked **E** (existing: code reads it today) or **P** (planned: named spec or feature).

| Domain | Forever | Era | TBC | Mists | Retail | Consumers |
|---|---|---|---|---|---|---|
| Items (stat blocks) | ✓ | ✓ | ✓ | ✓ | ✓ (D5: key) | E: Forever Gear, via `Data/Forever/Items.lua`. P: per-client gear-scoring calibration against frozen `StatWeights` |
| Character snapshot | ✓ | ✓ | ✓ | ✓ | ✓ | E: export context (which class and level produced a record) |
| Spellbook (name, line, rank text, trained level) | ✓ | ✓ | ✓ | ✓ (no rank text, §3.5) | — | E: Forever Spells tab. P: TBC Spells tab rank check (today reads live `U.ScanSpellbook`); Era trainer guidance |
| Trainer ranks | ✓ | ✓ | ✓ | probe | — | E: Forever Spells tab (`CatalogByName`). P: Era/TBC "what to train next", Now briefing |
| Spell catalog (ID walk) | ✓ | ✓ if `C_Spell.GetSpellName` + `GetSpellLevelLearned` exist (probe first) | same | — | — | E: Forever Spells tab, SessionCheck. P: Era/TBC trainer guidance |
| Talent trees, legacy | — | ✓ | ✓ | probe (MoP tier grid; shape unverified on 5.5.4) | — | P: talent renderer (`Docs/TALENT_RENDERER.md`, awaiting review); TBC TalentBuilds validation |
| Trait tree (`C_Traits`) | ✓ | — | — | — | ✓ | E: Forever Talents, and the renderer spec's geometry source. P: Retail Talents validation |
| Specialization | — | — | — | probe (S1: `C_SpecializationInfo.*`) | ✓ | P: Mists Character and Gear (S1), Retail StatEngine |
| Glyphs | — | — | — | probe | — | P: Mists Character (5.x glyph system) |
| Racials | ✓ | ✓ | ✓ | ✓ | ✓ | E: Forever PvP (`Data/Forever/Racials.lua`). P: TBC RaceAdvisor validation against `Data/TBC/TBCRaces.lua` |
| Character-sheet stats | probe (Forever's own probe sections) | ✓ | ✓ | ✓ | ✓ | P: Retail StatEngine and gear scoring; TBC StatCaps cross-check; Mists Character |
| Professions | probe | ✓ | ✓ | ✓ | ✓ | P: Retail Professions tab; TBC ProfessionAdvisor |
| World refresh log, Comprehension, scrolls, `C_SkillInfo` | ✓ | — | — | — | — | E: Forever Scrolls tab, WorldRefresh (R6) |

**Out of scope:** Wrath (scaffold with no installed client to verify on; `build_flavors` builds it but installs nothing). Cata was dropped as a flavor on 2026-10-08.

---

## 6. Tasks (per-feature commits; each ends with its verification)

| # | Task | Commit | Verify |
|---|---|---|---|
| T1 | `Core/Caps.lua` plus tests (interface, dotted resolve, secret mapping, provider swap) | `Harvest: swappable capability layer (Caps)` | Python tests |
| T2 | `HarvestFormat.lua` plus `Tools/export_harvest.lua`, with the shared stamp header | `Harvest: shared stamped formatter + saved-file exporter` | Test: in-game formatter output equals the Tools output on a fixture store |
| T3 | Core extraction to `Modules/Infrastructure/Harvester.lua`: store v3 plus migration, readers switched (Rotation, Init tripwire, generator plus S3 channel argument), data-driven Export row **with Trainer ranks and Spell catalog** (R8) | `Harvest: core into Infrastructure; store v3; trainer + catalog export` | Forever: counts equal before and after migration (the self-test reads them); `/ta test` 0 fail; both new buttons open the copy window with stamps |
| T4 | Domains split out of DataHarvester through Caps; Forever pack (probes, World refresh row, catalog ranges); delete `Modules/Forever/DataHarvester.lua` | `Harvest: domain packs + Forever pack; retire Forever/DataHarvester` | Forever: a rescan writes the same record counts; Full report covers the same sections; the static lint test shows no hand-rolled detection in the packs |
| T5 | Channel button (if D1) | `Harvest: explicit channel stamp` | Export header shows the chosen channel; `unknown` by default |
| T6 | TBC pack, TOC, profile tab | `Harvest: TBC pack` | TBC: `-Check` current, `/ta test` 0 fail, Run probes shows the API states, trainer visit records ranks, exports stamped |
| T7 | Era pack, TOC, profile (the scaffold gains `DataHarvester` and a Harvest tab, D4) | `Harvest: Era pack` | Era: same as TBC |
| T8 | Mists pack (spellbook with trained level, talent grid probe, spec and glyph probes) | `Harvest: Mists pack` | Mists: same, plus the probe answers S1's open question |
| T9 | Retail pack (items with D5 key, stats, professions, trait tree, spec), Mainline TOC, tab (D3) | `Harvest: Retail pack` | Retail and PTR: `/ta test` 0 fail, no new frames discarded, scans silent in combat |
| T10 | Docs: `FOREVER_BRIEF.md` pointer, `STATE.md` lines, README Harvest section | `Docs: harvest sensor array` | Read-through |

Order rule: T1-T4 must leave Forever's behaviour identical before any new client gets a pack.

**How T3 was cut (2026-10-04).** `Modules/Infrastructure/Harvester.lua` is the core *library*: the store (v3, the move from `foreverHarvest`), the client stamp, the section times, the stamped export and the Copy-row registry.
- `Modules/Forever/DataHarvester.lua` stays the registered module for now, and reads and exports through the core.
- T4 moves the rest into the core: the event fan-out, scans, probes, full report, catalog engine and tab. T4 also splits the domains out and deletes `Modules/Forever/DataHarvester.lua`.
- Cutting it this way keeps each commit small, and keeps Forever's behaviour identical at every step.

**How T4 was cut (2026-10-04).** The core (`Modules/Infrastructure/Harvester.lua`) is now the registered `DataHarvester` module: record helpers, `Try` through Caps, the event fan-out, the catalog engine, the shared probe sections, the Full report and the tab. Six domains (`Character`, `Items`, `Racials`, `Spellbook`, `TraitTree`, `Trainer`) and `Packs/Forever.lua` replace `Modules/Forever/DataHarvester.lua`, which is deleted. `Domains/TalentTrees.lua` (the legacy talent scan) exists but no TOC lists it until the Era and TBC packs; `test_harvest_packs.py` loads it.
- **Parity, measured.** The T3 recorder and the T4 code were run side by side on the same mocked Forever client and store, through the same events (`/tmp` harness, not shipped; its checks live on in `test_harvest_packs.py`). Store, registered events, slash commands, chat, the probe report and every export window came out byte-identical. The intended differences are listed below and nothing else differs.
- **Approved additions (Christopher, 2026-10-04):**
  - *Additive catalog scan.* A scan writes new and changed ranks and never removes a stored one. It builds into a separate table and merges at the end, so the Spells tab reads the full catalog while the walk runs and gets a fresh table afterwards. This is the regression for 2026-10-04 17:23, when a Mage session read 8 Warrior and Priest ranks blank and the old wipe-and-rebuild scan dropped them (85 -> 77). A mutation check confirms the test fails against the old behaviour.
  - *Scan button renamed.* The section is now "Catalog scan" and the button "Run catalog scan", so it can't be mistaken for the Copy row's "Spell catalog" button (which only opens a window).
  - *One-time repair.* `Packs/Forever.lua` adds back the 8 lost ranks, verbatim from the saved file of 17:21:36. Each is added only if missing, only when the client or catalog build is 70205, and only once (`catalogRepair` records how many were added).
  - *Trainer rows, option (a).* Profession trainers are recorded under `trainerProf[PROFESSION]`, never as class spells. Each visit is judged on its own rows: it is a class trainer's if any row needs a level above 1, or if `IsTradeskillTrainer()` says so. The profession is named by the visit's rank row ("Apprentice Mining" -> "Mining"). A one-time `Migrate` moves rows already misfiled, grouped by visit time; on the real store that is Blacksmith 23 + Mining 16 = 39, with none dropped (`trainerProfFiled`). The old one-time purge, which could delete such rows, is gone. The Copy row gains "Profession trainers", and the summary gains a "Profession trainers" row.
- **Other intended differences.**
  - The Full report's Rescan list loses the "talents ok" line. It was the legacy talent scan, a no-op on Forever (self-test: `GetNumTalentTabs` absent). A domain skipped for a missing need now prints `skipped: missing <path>` instead.
  - A Copy button for a section with no records yet opens a stamped 0-record window instead of doing nothing.
  - On an error, one failing domain no longer stops the domains after it for that event. The first error is still raised to the module dispatcher, so `/ta errors` logs it.
- **Routing.** `Tools/gen_event_routes.py` routes a high-frequency event only to modules whose own file names it. The core therefore names `"BAG_UPDATE_DELAYED"` (`ROUTED_EVENTS`), and a test fails if a domain uses a routed event the core does not name. `EVENT_ROUTES` in `Core/Init.lua` is unchanged.
- **Manifest (G3's).** The set of namespaced APIs the Forever TOC ships is unchanged (`test_enginegate.py` passes without regenerating the manifest). The manifest's per-API *file* lists still say `Modules/Forever/DataHarvester.lua`. TestHarness maps that path to the running `DataHarvester` module, so the self-test's warnings are unchanged. When G3 regenerates the manifest, the new paths (`Modules/Harvest/**`, `Modules/Infrastructure/Harvester.lua`) need `ModuleForFile` to map them to `DataHarvester`, or those warnings drop out.
- **Not in T4 (still to do).** The core does not yet write `Seen()` into `store.api` (§4.2), and scans do not yet defer during combat lockdown (R11). Both change Forever's behaviour, so they are proposed as their own commit before T6 (not yet approved). `Stats` and `Professions` are domains no client uses yet; they arrive with the packs that use them.

---

## 7. Tests

- `test_harvest_caps.py`:
  - interface shape;
  - dotted-path resolve;
  - `secret` is never collapsed to missing;
  - a stub provider swaps in and every pack runs unchanged;
  - **lint:** `Modules/Harvest/**` contains no `_G[`, no `type(...) == "function"`, and no `C_%w+ and C_%w+%.` existence patterns.
- `test_harvest_store.py`: migration from a copy of today's Forever store shape. Counts per section are equal, `foreverHarvest` is gone, and the tripwire counts the new key.
- `test_harvest_format.py`: header fields (R9), paging, trainer flattening, and identical output between the in-game and Tools paths.
- `test_harvest_packs.py` (T4; the mocked Forever client is `Tools/fixtures/harvest_world_forever.lua`):
  - each TOC loads the core plus exactly one pack;
  - Forever-only sections and buttons appear in no other TOC (R6);
  - each profile with a pack has a `harvest` tab.
- Rewrite the `test_harvester.py` pins at 91-102 (D6). Update `test_events.py` (both spellbook event names stay registered).
- A lupa smoke run per client pack with mocked APIs, modelled on `test_tbc_boot.py`: scans write records, and missing APIs are recorded, not thrown.

---

## 8. Decisions (approved 2026-10-04)

| # | Decision | Ruling |
|---|---|---|
| D1 | In-game channel stamp | **Channel button** on the Harvest tab (unknown -> beta -> live -> ptr), default `unknown`, set only by the player. Never guessed. |
| D2 | Store key | **Move** `foreverHarvest` to `harvest`, in the same commit as the tripwire and reader changes, with a per-section record-count test. |
| D3 | Tab visibility outside Forever | **Visible by default** on Era, TBC, Mists and Retail. |
| D4 | Era scaffold | **Approved**: Harvest becomes Era's first content. |
| D5 | Retail item key | **Item ID plus item-level variant** (the item string with bonus IDs, per-character fields stripped). |
| D6 | Retail harvester | **Reversed** the documented decision in `test_harvester.py:91-102` (no harvester in the Retail TOCs). Retail gets a pack. The pin comments are rewritten in T9 to record the reversal and why. |

The options as they were put to Christopher:


- **D1 — In-game channel.** Should there be a Channel button on the Harvest tab (unknown → beta → live → ptr, default unknown, set only by you)? Or should in-game exports always say `unknown`, with only the saved-file exporter's argument setting the channel? *Recommendation: the button. In-game exports are the ones that get pasted, so they need the stamp too.*
- **D2 — Store key.** Move `foreverHarvest` to `harvest` (one store shape on every client), or leave Forever on its old key? *Recommendation: move, in the same commit as the tripwire and reader changes.*
- **D3 — Visibility outside Forever.** Is the Harvest tab visible by default on Era, TBC, Mists and Retail, or behind a Settings toggle that starts off? Recording runs either way, since it is silent; this only decides whether the tab shows. *Recommendation: toggle, default off on live clients and on for Forever beta. This needs your product call.*
- **D4 — Era scaffold.** Adding `DataHarvester` and a Harvest tab makes the Era profile non-empty. That fits "minimal or readout-only", but it changes an inert scaffold. Confirm.
- **D5 — Retail item key.** The same item ID drops at many item levels on Retail (bonus IDs). Key by item ID only, matching the other clients, or by the item string with bonus IDs, stripping per-character fields? *Recommendation: the item string with bonus IDs on Retail. It stays verbatim, and an item-ID-only key would keep whichever item level was seen first.*
- **D6 — Reversed pin.** `test_harvester.py:91-102` documents a deliberate decision: no harvester in the Retail TOCs ("dead weight on every retail player's disk"). This spec reverses it for Retail. Your brief asks for every client, so I read it as approval. Confirm, and the pin comments get rewritten to say why.

---

## 9. Risks

- **Retail cost.** Retail sees far more items. The caps bound the saved file, and each per-section cap has a test. Scans stay debounced and run out of combat only.
- **The catalog engine on Era and TBC** depends on two `C_Spell` functions that are unverified there. Without them the domain is skipped and the store records the missing paths. The trainer domain still gives rank tables wherever a class trainer exists.
- **Migration.** A move that the tripwire didn't know about would fire a false "shrank" incident. That is why the tripwire changes in the same commit (T3).
- **G3 overlap.** G3 owns `ApiGuard` and the manifests. This spec touches neither. `Core/Caps.lua` is the one seam G3 later fills.
