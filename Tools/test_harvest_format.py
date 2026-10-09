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
check("header line 3 names the source, and does not guess a class",
      h[2], "-- source all trainer · recorded by unknown · current character unknown")
check("header line 4 carries dates and versions",
      h[3], "-- harvested 2026-09-26 .. 2026-10-04 · exported 2026-10-04 15:10 · store v3 · ToonAge 2.0.0-dev.1")
empty = lua_list(F.Header(L.eval("{}"), "items", 1, 1, 1, 1, 1))
check("unrecorded fields print unknown",
      empty[1], "-- client unknown · unknown · build unknown · interface unknown · project unknown · channel unknown")
check("unrecorded source prints unknown, never a guessed class",
      empty[2], "-- source all items · recorded by unknown · current character unknown")
check("unrecorded dates print unknown",
      empty[3], "-- harvested unknown .. unknown · exported unknown · store vunknown · ToonAge unknown")
check("empty-string channel is unknown, not blank",
      "channel unknown" in lua_list(F.Header(L.eval('{ channel = "" }'), "x", 0, 1, 0, 0, 0))[1])

# ── Rows / verbatim / flatten ────────────────────────────────────────────
lines = lua_list(F.Lines(store, "trainer", 0, META))
check("nested trainer flattens to CLASS:key, sorted",
      lines[5:], ["MAGE:133\tFireball\tRank 1\t1\tused\t1791057815",
                  "MAGE:143\tFireball\tRank 2\t6\tavailable\t1791057815"])
check("blank line separates header and records", lines[4], "")
check("unfiltered export records who is in chars, and has no current character",
      lines[2], "-- source all trainer · recorded by Eramali, Malefice · current character unknown")
items = lua_list(F.Lines(store, "items", 0, META))
check("records are verbatim (stored line untouched)",
      items[5], "118\tMinor Healing Potion\t5\t1\t1\t0\t1\tConsumable\tPotion\t\t0\t")
check("keys sort by string form", [l.split("\t")[0] for l in items[5:]], ["118", "2589"])
check("array sections export by index", lua_list(F.Lines(store, "catalogPasses", 0, META))[5],
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
check("page 1 holds 400 records", len(p1) - 5, 400)
check("page 1 header range", p1[0], "-- ToonAge harvest · s · page 1/2 · records 1-400 of 401")
out2, page2, _ = F.Lines(big, "s", 2, META)
check("page 2 holds the last record", lua_list(out2)[5:], ["k0401\tv401"])
_, clamped, _ = F.Lines(big, "s", 9, META)
check("a page past the end clamps to the last", clamped, 2)
check("page 0 is every record", len(lua_list(F.Lines(big, "s", 0, META))) - 5, 401)

# ── Per-class default ────────────────────────────────────────────────────
# Account-wide rows from two classes. A class with nothing stored must not
# receive the other class's rows.
L.globals().META = META
L.execute(r"""
function scoped(token, display)
    local t = {}
    for k, v in pairs(META) do t[k] = v end
    t.class = token
    t.currentClass = display
    return t
end
CLASS_STORE = {
  chars = {
    ["Player-1-0A"] = "Eramali\tClassic Beta PvE\tMAGE\tScourge\t18\t3\t16001",
    ["Player-1-0H"] = "Huntsman\tClassic Beta PvE\tHUNTER\tOrc\t20\t2\t16001",
  },
  trainer = {
    MAGE = { ["133"] = "Fireball\tRank 1\t1\tused\t1" },
    HUNTER = { ["1978"] = "Serpent Sting\tRank 1\t4\tavailable\t1",
               ["3044"] = "Arcane Shot\tRank 1\t6\tavailable\t1" },
  },
  spells = {
    ["MAGE:133"] = "Fireball\t1\tFire\tRank 1\t\t1",
    ["HUNTER:1978"] = "Serpent Sting\t4\tMarksmanship\tRank 1\t\t4",
  },
  talents = { ["MAGE:T:1:1"] = "1\t1", ["HUNTER:T:2:1"] = "2\t1" },
  catalog = { ["133"] = "Fireball\tRank 1\t1", ["1978"] = "Serpent Sting\tRank 1\t4",
               ["145"] = "Fireball\tRank 2\t6" },
}
""")
klass = L.eval("CLASS_STORE")

def scoped_lines(section, token, display):
    meta = L.eval("scoped(%r, %r)" % (token, display))
    return lua_list(F.Lines(klass, section, 0, meta))

rogue_tr = scoped_lines("trainer", "ROGUE", "Rogue")
check("a class with no trainer rows says so, and does not dump other classes",
      rogue_tr[-1], "No ROGUE trainer data yet. Open a rogue trainer to record it.")
check("empty trainer export names that class and the current character",
      rogue_tr[2], "-- source ROGUE trainer · recorded by unknown · current character Rogue")
check("empty trainer export has no other class's keys",
      any(l.startswith("HUNTER:") or l.startswith("MAGE:") for l in rogue_tr), False)
hunter_tr = scoped_lines("trainer", "HUNTER", "Hunter")
check("hunter trainer export is only that class, recorded by that character",
      (hunter_tr[2], hunter_tr[5:]),
      ("-- source HUNTER trainer · recorded by Huntsman · current character Hunter",
       ["HUNTER:1978\tSerpent Sting\tRank 1\t4\tavailable\t1",
        "HUNTER:3044\tArcane Shot\tRank 1\t6\tavailable\t1"]))
check("spells default to the class",
      scoped_lines("spells", "ROGUE", "Rogue")[-1],
      "No ROGUE spell data yet. Open your spellbook to record it.")
check("talents default to the class",
      scoped_lines("talents", "MAGE", "Mage")[5:], ["MAGE:T:1:1\t1\t1"])
mage_cat = scoped_lines("catalog", "MAGE", "Mage")
check("catalog keeps spell IDs that class recorded, not the whole account",
      mage_cat[5:], ["133\tFireball\tRank 1\t1"])
check("catalog for a class with no recorded spell IDs is empty",
      scoped_lines("catalog", "ROGUE", "Rogue")[-1],
      "No ROGUE spell catalog data yet. Open a rogue trainer or your spellbook to record it.")
check("no class filter still exports every trainer class",
      [l.split("\t")[0] for l in lua_list(F.Lines(klass, "trainer", 0, META))[5:]],
      ["HUNTER:1978", "HUNTER:3044", "MAGE:133"])
check("saved-data label names the other class",
      L.eval("ToonAge.HarvestFormat.SavedLabel({'HUNTER'})"), "Showing saved Hunter data")
check("saved-data label joins several classes",
      L.eval("ToonAge.HarvestFormat.SavedLabel({'HUNTER', 'MAGE'})"),
      "Showing saved Hunter and Mage data")


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
    check("v3 store: source is the whole section, with no character to name",
          h3[2], "-- source all items · recorded by unknown · current character unknown")
    check("v3 store: harvest range from times, store and ToonAge versions",
          re.sub(r"exported [0-9: -]+ ·", "exported <t> ·", h3[3]),
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
          re.match(r"-- harvested unknown \.\. 2026-10-04 · exported ", h4[3]) is not None)

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
