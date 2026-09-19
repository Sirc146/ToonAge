#!/usr/bin/env python3
"""Usage reporting: the three gates, and what may be recorded.

The point of these tests is that analytics stay OFF unless every gate is open,
and that nothing identifying can ever reach Wago. Usage:  python Tools/test_analytics.py [-v]
"""
import sys, glob, os
from lupa import LuaRuntime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want):
    ok = got == want
    _res.append(ok)
    if VERBOSE or not ok:
        print(("[  ok  ] " if ok else "[ FAIL ] ") + name)
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")


def load(lua_setup):
    lua = LuaRuntime()
    lua.execute(lua_setup)
    lua.execute(open(os.path.join(ROOT, "Core/Analytics.lua"), encoding="utf-8").read())
    return lua


BASE = """
ToonAge = { flavor = "retail", db = {}, charDB = { tracker = {} }, modules = { a = 1, b = 2 },
            Utils = { ZygorLoaded = function() return false end, DeferToZygor = function() return false end } }
recorded = {}
local function rec(kind) return function(_, name, value) recorded[#recorded+1] = { kind = kind, name = name, value = value } end end
fakeSink = { Switch = rec("switch"), IncrementCounter = rec("inc"), SetCounter = rec("set"), DecrementCounter = rec("dec") }
"""

NO_LIB = BASE + "LibStub = function() return nil end\n"
WITH_LIB = BASE + """
LibStub = function() return { RegisterAddon = function() return fakeSink end } end
"""
NO_ID = BASE + """
LibStub = function() return { RegisterAddon = function() return false end } end
"""

# ── Gate 1: no shim / no Wago App ─────────────────────────────────────────
lua = load(NO_LIB)
A = lua.globals().ToonAge.Analytics
A.Init(A)
check("no shim -> disabled", A.enabled, False)
A.Switch(A, "client:retail", True)
check("no shim -> records nothing", len(list(lua.globals().recorded.values())), 0)

# ── Gate 2: no project id in the TOC ──────────────────────────────────────
lua = load(NO_ID)
A = lua.globals().ToonAge.Analytics
A.Init(A)
check("no X-Wago-ID -> disabled", A.enabled, False)

# ── Gate 3: player opted out in ToonAge settings ──────────────────────────
lua = load(WITH_LIB)
lua.execute("ToonAge.db.analytics = false")
A = lua.globals().ToonAge.Analytics
A.Init(A)
check("opted out -> disabled", A.enabled, False)
A.RecordSession(A)
check("opted out -> records nothing", len(list(lua.globals().recorded.values())), 0)

# ── All gates open ────────────────────────────────────────────────────────
lua = load(WITH_LIB)
A = lua.globals().ToonAge.Analytics
A.Init(A)
check("all gates open -> enabled", A.enabled, True)
A.RecordSession(A)
rows = [dict(r) for r in lua.globals().recorded.values()]
names = [r["name"] for r in rows]
check("session recorded something", len(rows) > 0, True)
check("exactly one client flavor true",
      sum(1 for r in rows if str(r["name"]).startswith("client:") and r["value"] is True), 1)
check("records the running flavor", "client:retail" in names, True)
check("module count reported", "modules:loaded" in names, True)

# Nothing identifying, ever: names are fixed strings chosen here, and no value
# recorded may be a string (only booleans and numbers reach Wago).
BANNED = ("name", "realm", "guild", "character", "account", "server", "guid", "toon")
for n in names:
    low = str(n).lower()
    check(f"key '{n}' carries no identifier word",
          any(b in low for b in BANNED), False)
for r in rows:
    check(f"value for '{r['name']}' is not a string", isinstance(r["value"], str), False)

# ── TOC wiring ────────────────────────────────────────────────────────────
for toc in sorted(glob.glob(os.path.join(ROOT, "ToonAge*.toc"))):
    txt = open(toc, encoding="utf-8").read()
    base = os.path.basename(toc)
    check(f"{base}: has the Wago project id", "## X-Wago-ID: 56ndnjG9" in txt, True)
    check(f"{base}: declares WagoAnalytics optional",
          "## OptionalDependencies: WagoAnalytics" in txt, True)
    check(f"{base}: loads the shim", "Libs\\WagoAnalytics\\Shim.lua" in txt, True)
    check(f"{base}: loads Core\\Analytics.lua", "Core\\Analytics.lua" in txt, True)
    # The shim calls LibStub, so it must load after it.
    check(f"{base}: shim loads after LibStub",
          txt.index("Libs\\LibStub.lua") < txt.index("Libs\\WagoAnalytics\\Shim.lua"), True)

passed, total = sum(_res), len(_res)
print(f"\n[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
