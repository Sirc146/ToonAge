#!/usr/bin/env python3
"""Harvest export formatter -- Modules/Infrastructure/HarvestFormat.lua (harvest spec T2).

Checks:
  * the header carries every R9 stamp field, prints "unknown" for anything not
    recorded, and never guesses a channel
  * records are emitted verbatim (key TAB stored line), sorted
  * nested sections flatten to "outer:inner" keys (trainer[CLASS][id])
  * paging: 400 per page, clamping, page 0 = everything
  * R10: the in-game path (formatter loaded into a ToonAge table) and the Tools
    path (Tools/export_harvest.lua reading a saved file) produce identical
    section files -- only the "exported" time is allowed to differ
  * the exporter reads a pre-move save (foreverHarvest) and states only what
    its records say (catalog build, character-record interface)
  * a store moved from foreverHarvest exports "harvested unknown .. <last>"
  * neither file names a namespaced client API (the manifest scans shipped files)

Usage:  python Tools/test_harvest_format.py [-v]
"""
import os
import re
import sys
import tempfile

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


FMT = os.path.join(ROOT, "Modules/Infrastructure/HarvestFormat.lua")
EXP = os.path.join(ROOT, "Tools/export_harvest.lua")
fmt_src = open(FMT, encoding="utf-8").read()
exp_src = open(EXP, encoding="utf-8").read()
for name, s in (("HarvestFormat.lua", fmt_src), ("export_harvest.lua", exp_src)):
    check(f"{name} names no namespaced client API",
          re.findall(r"\bC_[A-Za-z]+\.[A-Za-z0-9_]+", s), [])
fmt_code = "\n".join(l.split("--", 1)[0] for l in fmt_src.splitlines())
check("formatter makes no client or os calls",
      re.findall(r"\b(?:os\.|date\(|GetBuildInfo|io\.)", fmt_code), [])

# A store in the CURRENT (pre-move, v2) shape, plus a v3 client block variant.
STORE_V2 = r"""
{
  version = 2,
  catalogBuild = "70205",
  items = { [2589] = "Linen Cloth\t5\t1\t0\t7\t5\tTrade Goods\tCloth\t\t0\t",
            [118]  = "Minor Healing Potion\t5\t1\t1\t0\t1\tConsumable\tPotion\t\t0\t" },
  chars = { ["Player-1-0A"] = "Eramali\tClassic Beta PvE\tMAGE\tScourge\t18\t3\t16001",
            ["Player-1-0B"] = "Malefice\tClassic Beta PvE\tWARRIOR\tScourge\t1\t3\t16001" },
  trainer = { MAGE = { ["133"] = "Fireball\tRank 1\t1\tused\t1791057815",
                       ["143"] = "Fireball\tRank 2\t6\tavailable\t1791057815" } },
  catalogPasses = { "pass 2: +3 ranks, 0 still blank" },
  counts = {},
}
"""

L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute("ToonAge = { version = 'in-game-table', modules = {} }")   # the in-game path
L.execute(fmt_src)
F = L.eval("ToonAge.HarvestFormat")
store = L.eval(STORE_V2)

META = L.eval(r"""{ flavor = "forever", version = "1.60.1", build = "70205", interface = "16001",
                     project = 18, channel = "beta", harvestedFirst = "2026-09-26",
                     harvestedLast = "2026-10-04", exported = "2026-10-04 15:10", store = 3,
                     toonage = "2.0.0-dev.1" }""")

def lua_list(t):
    if isinstance(t, tuple):      # F.Lines returns lines, page, pages
        t = t[0]
    return [t[i] for i in range(1, len(t) + 1)]

# ── Header ───────────────────────────────────────────────────────────────
h = lua_list(F.Header(META, "trainer", 0, 1, 1, 2, 2))
check("header line 1 names section and count", h[0], "-- ToonAge harvest · trainer · all 2 records")
check("header line 2 carries client stamps",
      h[1], "-- client forever · 1.60.1 · build 70205 · interface 16001 · project 18 · channel beta")
check("header line 3 carries dates and versions",
      h[2], "-- harvested 2026-09-26 .. 2026-10-04 · exported 2026-10-04 15:10 · store v3 · ToonAge 2.0.0-dev.1")
empty = lua_list(F.Header(L.eval("{}"), "items", 1, 1, 1, 1, 1))
check("unrecorded fields print unknown",
      empty[1], "-- client unknown · unknown · build unknown · interface unknown · project unknown · channel unknown")
check("unrecorded dates print unknown",
      empty[2], "-- harvested unknown .. unknown · exported unknown · store vunknown · ToonAge unknown")
check("empty-string channel is unknown, not blank",
      "channel unknown" in lua_list(F.Header(L.eval('{ channel = "" }'), "x", 0, 1, 0, 0, 0))[1])

# ── Rows / verbatim / flatten ────────────────────────────────────────────
lines = lua_list(F.Lines(store, "trainer", 0, META))
check("nested trainer flattens to CLASS:key, sorted",
      lines[4:], ["MAGE:133\tFireball\tRank 1\t1\tused\t1791057815",
                  "MAGE:143\tFireball\tRank 2\t6\tavailable\t1791057815"])
check("blank line separates header and records", lines[3], "")
items = lua_list(F.Lines(store, "items", 0, META))
check("records are verbatim (stored line untouched)",
      items[4], "118\tMinor Healing Potion\t5\t1\t1\t0\t1\tConsumable\tPotion\t\t0\t")
check("keys sort by string form", [l.split("\t")[0] for l in items[4:]], ["118", "2589"])
check("array sections export by index", lua_list(F.Lines(store, "catalogPasses", 0, META))[4],
      "1\tpass 2: +3 ranks, 0 still blank")
check("missing section returns nil", F.Lines(store, "nope", 0, META) in (None, (None,)), True)
check("empty section exports a header and no rows",
      lua_list(F.Lines(store, "counts", 0, META))[0], "-- ToonAge harvest · counts · all 0 records")
secs = lua_list(F.Sections(store))
check("sections are the table-valued fields, sorted",
      secs, ["catalogPasses", "chars", "counts", "items", "trainer"])

# ── Paging ───────────────────────────────────────────────────────────────
big = L.eval("(function() local t = {} for i = 1, 401 do t[string.format('k%04d', i)] = 'v' .. i end return { s = t } end)()")
out, page, pages = F.Lines(big, "s", 1, META)
p1 = lua_list(out)
check("401 records -> 2 pages", (page, pages), (1, 2))
check("page 1 holds 400 records", len(p1) - 4, 400)
check("page 1 header range", p1[0], "-- ToonAge harvest · s · page 1/2 · records 1-400 of 401")
out2, page2, _ = F.Lines(big, "s", 2, META)
check("page 2 holds the last record", lua_list(out2)[4:], ["k0401\tv401"])
_, clamped, _ = F.Lines(big, "s", 9, META)
check("a page past the end clamps to the last", clamped, 2)
check("page 0 is every record", len(lua_list(F.Lines(big, "s", 0, META))) - 4, 401)


def run_exporter(*args):
    """Run Tools/export_harvest.lua in its own Lua 5.1 runtime (no lua binary needed)."""
    R = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua_arg = R.eval("{}")
    lua_arg[0] = EXP
    for i, a in enumerate(args, 1):
        lua_arg[i] = a
    R.globals().arg = lua_arg
    try:
        R.execute(exp_src)
        return 0
    except Exception as e:   # a Lua error surfaces here; os.exit is only on bad input
        print(e)
        return 1

# ── R10: in-game path == Tools path ──────────────────────────────────────
def norm(text):
    return re.sub(r"exported [0-9: -]+ ·", "exported <t> ·", text)

with tempfile.TemporaryDirectory() as tmp:
    sv = os.path.join(tmp, "ToonAge.lua")
    with open(sv, "w", encoding="utf-8") as fh:
        fh.write("ToonAgeDB = { foreverHarvest = " + STORE_V2 + " }\n")
    outdir = os.path.join(tmp, "out")
    check("exporter runs", run_exporter(sv, outdir, "beta"), 0)
    files = sorted(os.listdir(outdir)) if os.path.isdir(outdir) else []
    check("one file per section", files,
          ["catalogPasses.tsv", "chars.tsv", "counts.tsv", "items.tsv", "trainer.tsv"])
    # The meta a pre-move save can honestly state: what its records say.
    legacy_meta = L.eval(r"""{ flavor = "forever", build = "70205", interface = "16001",
                               channel = "beta", exported = "2026-10-04 15:10", store = 2 }""")
    for sec in ("items", "trainer", "chars", "catalogPasses", "counts"):
        path = os.path.join(outdir, sec + ".tsv")
        if not os.path.exists(path):
            continue
        tools_text = open(path, encoding="utf-8").read()
        game_text = F.Text(store, sec, legacy_meta)
        check(f"in-game and Tools output identical: {sec}", norm(tools_text), norm(game_text))
    hdr = open(os.path.join(outdir, "items.tsv"), encoding="utf-8").read().splitlines()[1]
    check("pre-move save: build from the catalog, interface from character records, channel from the argument",
          hdr, "-- client forever · unknown · build 70205 · interface 16001 · project unknown · channel beta")

    # No channel argument and none recorded -> unknown (never guessed from the realm).
    outdir2 = os.path.join(tmp, "out2")
    run_exporter(sv, outdir2)
    hdr2 = open(os.path.join(outdir2, "chars.tsv"), encoding="utf-8").read().splitlines()[1]
    check("no channel anywhere -> unknown, even with a 'Beta' realm in the records",
          hdr2.endswith("channel unknown"))

    # A v3 store: the client block wins, times give the harvest range.
    with open(sv, "w", encoding="utf-8") as fh:
        fh.write("""ToonAgeDB = { harvest = { version = 3,
            client = { flavor = "tbc", version = "2.5.6", build = "69795", interface = "20506",
                       project = 5, channel = "live", toonage = "2.0.0-dev.1" },
            times = { items = { first = 1790000000, last = 1791100000 } },
            items = { [1] = "x" } } }\n""")
    outdir3 = os.path.join(tmp, "out3")
    run_exporter(sv, outdir3)
    h3 = open(os.path.join(outdir3, "items.tsv"), encoding="utf-8").read().splitlines()
    check("v3 store: client block stamps the export",
          h3[1], "-- client tbc · 2.5.6 · build 69795 · interface 20506 · project 5 · channel live")
    check("v3 store: harvest range from times, store and ToonAge versions",
          re.sub(r"exported [0-9: -]+ ·", "exported <t> ·", h3[2]),
          "-- harvested 2026-09-21 .. 2026-10-04 · exported <t> · store v3 · ToonAge 2.0.0-dev.1")
    check("v3 store: client and times are not exported as sections",
          sorted(os.listdir(outdir3)), ["items.tsv"])

    # A v3 store moved from foreverHarvest: its old records carry no write
    # time, so the range starts unknown (same rule as Harvester.lua Meta).
    with open(sv, "w", encoding="utf-8") as fh:
        fh.write("""ToonAgeDB = { harvest = { version = 3,
            client = { flavor = "forever", build = "70205", interface = 16001,
                       migratedFrom = "foreverHarvest", migratedVersion = 2 },
            times = { items = { first = 1791100000, last = 1791100000 } },
            items = { [1] = "x" } } }\n""")
    outdir4 = os.path.join(tmp, "out4")
    run_exporter(sv, outdir4)
    h4 = open(os.path.join(outdir4, "items.tsv"), encoding="utf-8").read().splitlines()
    check("moved store: harvest range start is unknown, end is the last write",
          re.match(r"-- harvested unknown \.\. 2026-10-04 · exported ", h4[2]) is not None)

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
