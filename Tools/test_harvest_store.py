#!/usr/bin/env python3
"""Harvest store v3 and the move from foreverHarvest -- Modules/Infrastructure/Harvester.lua (harvest spec T3).

R12 is the contract: no record is lost. This runs the real core (with the real
Core/Caps.lua and HarvestFormat.lua) on a store shaped like today's Forever one:

  * every section keeps exactly its records (counted per section, nested tables
    included), scalars survive, and it is the SAME table under the new key
  * the old key is gone; version is 3; the client block is stamped from what the
    client reports (via Caps), channel "unknown" until the player sets it
  * both keys present (an older build ran after the move): records merge, the
    already-stored record wins, nothing is dropped
  * fresh store, Clear, Touch / TouchTable section times, Count, the export
    registry, Meta and a stamped export
  * a moved or merged store's harvest range starts "unknown": its old records
    carry no write time, so they are never dated to the day of the move
  * the SavedVariables tripwire (Core/Init.lua GuardCounts) counts the same before
    and after the move, so the move is never reported as "shrank"

Usage:  python Tools/test_harvest_store.py [-v]
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


core_src = read("Modules/Infrastructure/Harvester.lua")
# Since T4 the core runs the catalog engine and the shared probes, so it names
# client APIs. Each must already be in the Forever API manifest (G3 owns the
# manifest; Tools/test_enginegate.py re-measures it from the shipped files).
manifest = read("Data/Forever/ApiManifest.lua")
check("every namespaced API the core names is in the Forever manifest",
      sorted(set(n for n in re.findall(r"\bC_[A-Za-z]+\.[A-Za-z0-9_]+", core_src) if f'["{n}"]' not in manifest)), [])

FOREVER_STORE = r"""{
    version = 2, catalogBuild = "70205", trainerFormat = 2, trainerProfPurged = true,
    trainerApi = "GetNumTrainerServices=yes | MAGE: services=16 recorded=16",
    items   = { [2589] = "Linen Cloth\t5", [118] = "Minor Healing Potion\t5", [6948] = "Hearthstone\t1" },
    spells  = { ["MAGE:133"] = "Fireball\t1\tFire\tRank 1\t\t1", ["MAGE:116"] = "Frostbolt\t4\tFrost\tRank 1\t\t4" },
    talents = { ["MAGE:T:1:1"] = "1\t1\t11\t\tImp FB\t0\t5\t18", ["MAGE:T:1:2"] = "1\t2\t12\t\tX\t1\t3\t18" },
    chars   = { ["Player-1-A"] = "Eramali\tClassic Beta PvE\tMAGE\tScourge\t18\t3\t16001",
                ["Player-1-B"] = "Malefice\tClassic Beta PvE\tWARRIOR\tScourge\t1\t3\t16001" },
    racials = { ["Scourge:Horde:7744"] = "Will of the Forsaken\tRacial\t\tMAGE\tRemoves fear" },
    trainer = { MAGE = { ["10097"] = "Mithril Bar\t\t0\tunavailable\t1", ["2657"] = "Smelt Copper\t\t1\tavailable\t1",
                         ["3307"] = "Iron Bar\t\t0\tunavailable\t1" } },
    talentGeo   = { ["MAGE:1:1"] = "1\t2\t\t\t0\t\t1", ["MAGE:1:2"] = "2\t2\t\t\t0\t\t2" },
    talentGates = { ["MAGE:1"] = "" },
    talentConds = { ["MAGE:5"] = "5\tfalse", ["MAGE:6"] = "10\tfalse" },
    talentApi   = { MAGE = "ID,activeEntry" },
    catalog     = { ["133"] = "Fireball\tRank 1\t1", ["143"] = "Fireball\tRank 2\t6" },
    catalogPasses = { "pass 2: +3 ranks, 0 still blank" },
    counts = {},
}"""

WORLD = r"""
ToonAge = { flavor = "forever", version = "2.0.0-dev.1" }
-- Since T4 the core also registers the DataHarvester module when it loads.
function ToonAge:RegisterModule(n, m) self.modules = self.modules or {}; self.modules[n] = m end
WOW_PROJECT_ID = 18
function GetBuildInfo() return "1.60.1", "70205", "Sep 30 2026", 16001 end
NOW = 1791100000
function time() NOW = NOW + 1 return NOW end
function date(fmt, t) return os.date(fmt, t) end
"""


def fresh_runtime():
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(WORLD)
    L.execute(read("Core/Caps.lua"))
    L.execute(read("Modules/Infrastructure/HarvestFormat.lua"))
    L.execute(core_src)
    return L


COUNT = r"""
function COUNT_SECTIONS(s)
    local out = {}
    for k, v in pairs(s) do
        if type(v) == "table" and k ~= "client" and k ~= "times" then
            local n = 0
            local function walk(t) for _, x in pairs(t) do if type(x) == "table" then walk(x) else n = n + 1 end end end
            walk(v)
            out[k] = n
        end
    end
    return out
end
"""


def as_dict(t):
    return {k: t[k] for k in t.keys()}


# ── The move ─────────────────────────────────────────────────────────────
L = fresh_runtime()
L.execute(COUNT)
L.execute("OLD = " + FOREVER_STORE + "; ToonAge.db = { foreverHarvest = OLD, char = {} }")
g = L.globals()
before = as_dict(g.COUNT_SECTIONS(g.OLD))
Hv = L.eval("ToonAge.Harvester")
s = Hv.Store(Hv)
after = as_dict(g.COUNT_SECTIONS(s))
for sec, n in sorted(before.items()):
    check(f"move keeps every record: {sec} ({n})", after.get(sec), n)
check("the store is the same table under the new key", L.eval("ToonAge.db.harvest == OLD"))
check("the old key is gone", L.eval("ToonAge.db.foreverHarvest"), None)
check("store version is 3", s.version, 3)
for k, v in (("catalogBuild", "70205"), ("trainerFormat", 2), ("trainerProfPurged", True)):
    check(f"scalar survives: {k}", s[k], v)
c = s.client
check("client: moved-from recorded", c.migratedFrom, "foreverHarvest")
check("client: moved-from version recorded", c.migratedVersion, 2)
check("client: flavor", c.flavor, "forever")
check("client: version / build / interface from GetBuildInfo via Caps",
      (c.version, c.build, c.interface), ("1.60.1", "70205", 16001))
check("client: project from WOW_PROJECT_ID via Caps", c.project, 18)
check("client: channel unknown until the player sets it (D1)", c.channel, "unknown")
check("client: ToonAge version", c.toonage, "2.0.0-dev.1")
check("client: build recorded in buildsSeen", c.buildsSeen["70205"] is not None)
check("base sections backfilled (catalog, trainer, ...)", all(s[k] is not None for k in
      ("items", "spells", "talents", "chars", "counts", "racials", "trainer", "talentGeo", "catalog")))
check("a second call returns the same table", L.eval("ToonAge.Harvester:Store() == ToonAge.db.harvest"))

# ── Times, Count, TouchTable ─────────────────────────────────────────────
Hv.Touch(Hv, "items")
check("Touch stamps first and last", s.times["items"].first is not None and s.times["items"].last is not None)
first = s.times["items"].first
Hv.Touch(Hv, "items")
check("a later Touch keeps first, moves last",
      (s.times["items"].first == first, s.times["items"].last > first), (True, True))
Hv.TouchTable(Hv, s["spells"])
check("TouchTable finds the section of a section table", s.times["spells"] is not None)
Hv.TouchTable(Hv, L.eval("{}"))
check("TouchTable ignores a table that is not a section", len(list(s.times.keys())), 2)
check("Count includes nested trainer rows", Hv.Count(Hv, "trainer"), 3)

# ── Registry, Meta, stamped export ───────────────────────────────────────
for sec, label in (("items", "Items"), ("trainer", "Trainer ranks"), ("catalog", "Spell catalog"), ("items", "Items!")):
    Hv.RegisterExport(Hv, sec, label)
ex = Hv.Exports(Hv)
rows = [(ex[i].section, ex[i].label) for i in range(1, len(ex) + 1)]
check("registry keeps order, de-duplicates, relabels", rows,
      [("items", "Items!"), ("trainer", "Trainer ranks"), ("catalog", "Spell catalog")])
meta = Hv.Meta(Hv)
check("Meta carries the client stamp",
      (meta.flavor, meta.build, meta.interface, meta.project, meta.channel, meta.store),
      ("forever", "70205", 16001, 18, "unknown", 3))
check("moved store: harvest range ends at the last write",
      meta.harvestedLast is not None)
check("moved store: harvest range start is unknown (moved records carry no write time)",
      meta.harvestedFirst, None)
lines = Hv.ExportLines(Hv, "trainer", 0)
lines = lines[0] if isinstance(lines, tuple) else lines
lst = [lines[i] for i in range(1, len(lines) + 1)]
check("trainer export is stamped",
      lst[1], "-- client forever · 1.60.1 · build 70205 · interface 16001 · project 18 · channel unknown")
check("moved store export says the start is unknown, never today",
      re.match(r"-- harvested unknown \.\. \d{4}-\d\d-\d\d · exported ", lst[2]) is not None)
check("trainer export flattens CLASS:spellID", [l.split("\t")[0] for l in lst[4:]],
      ["MAGE:10097", "MAGE:2657", "MAGE:3307"])

# ── Both keys present: merge, nothing dropped ────────────────────────────
L2 = fresh_runtime()
L2.execute("""ToonAge.db = {
    harvest       = { version = 3, items = { [1] = "kept" }, client = { channel = "beta" } },
    foreverHarvest = { items = { [1] = "OLD", [2] = "new" }, chars = { x = "c" },
                       trainer = { MAGE = { a = "1" } } } }""")
H2 = L2.eval("ToonAge.Harvester")
s2 = H2.Store(H2)
check("merge: the stored record wins", s2["items"][1], "kept")
check("merge: records only the old key had are kept", (s2["items"][2], s2["chars"]["x"]), ("new", "c"))
check("merge: nested trainer rows are kept", s2["trainer"]["MAGE"]["a"], "1")
check("merge: the old key is gone", L2.eval("ToonAge.db.foreverHarvest"), None)
check("merge: a channel the player set is kept", s2.client.channel, "beta")
check("merge: recorded in the client block", s2.client.mergedFrom, "foreverHarvest")
H2.Touch(H2, "items")
check("merge: harvest range start is unknown (merged records carry no write time)",
      (H2.Meta(H2).harvestedFirst, H2.Meta(H2).harvestedLast is not None), (None, True))

# ── Fresh store and Clear ────────────────────────────────────────────────
L3 = fresh_runtime()
L3.execute("ToonAge.db = {}")
H3 = L3.eval("ToonAge.Harvester")
s3 = H3.Store(H3)
check("fresh: a new v3 store", (s3.version, s3.client.migratedFrom), (3, None))
H3.Touch(H3, "items")
m3 = H3.Meta(H3)
check("fresh: every record is dated, so the range has a real start and end",
      (m3.harvestedFirst is not None, m3.harvestedLast is not None), (True, True))
H3.Clear(H3)
check("Clear removes the store", L3.eval("ToonAge.db.harvest"), None)
check("after Clear a new empty store is made", H3.Store(H3).version, 3)
L4 = fresh_runtime()
check("no TA.db yet -> no store, no error", L4.eval("ToonAge.Harvester:Store()"), None)

# ── Tripwire counts the same before and after ────────────────────────────
init = read("Core/Init.lua")
m = re.search(r"local function GuardCounts\(db\)\n.*?\nend\n", init, re.S)
check("GuardCounts found in Core/Init.lua", m is not None)
if m:
    L5 = fresh_runtime()
    L5.execute(m.group(0).replace("local function GuardCounts", "function GuardCounts", 1))
    L5.execute("BEFORE_DB = { foreverHarvest = " + FOREVER_STORE + ", char = { a = {} } }")
    b = L5.eval("GuardCounts(BEFORE_DB)")
    before_c = (b["keys"], b["chars"], b["harvest"])
    L5.execute("ToonAge.db = BEFORE_DB")
    L5.eval("ToonAge.Harvester:Store()")
    a = L5.eval("GuardCounts(BEFORE_DB)")
    check("tripwire: same keys / chars / harvest counts after the move", (a["keys"], a["chars"], a["harvest"]), before_c)
    check("tripwire: harvest count is the real one (not zero)", before_c[2] > 0)

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
