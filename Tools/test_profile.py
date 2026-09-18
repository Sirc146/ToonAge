#!/usr/bin/env python3
"""
ToonAge -- Profile (per-flavor gating) tests
============================================
Executes the real Core/Environment.lua + Core/Profile.lua in an embedded Lua
5.1 runtime under stubbed clients and asserts the profile layer resolves the
right profile and gates modules correctly.

Also loads the real Core/Init.lua and drives TA:InitModules() with fake modules
to prove the flavor gate actually SKIPS a module the active profile does not
ship -- i.e. the wiring, not just the predicate.

Why this matters: on a TBC or MoP client, retail-only modules must not
initialise (they'd error against APIs that don't exist, or worse, show wrong
advice). The profile is the product decision that prevents that; this test is
the guarantee the decision is enforced at init time.

Setup:  python -m pip install --user lupa
Usage:  python Tools/test_profile.py [-v]
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv


def _read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def _client(project_id, interface_code):
    return f"""
    WOW_PROJECT_ID = {project_id}
    GetBuildInfo = function() return "x","0","d",{interface_code} end
    ToonAge = {{}}
    """


def load_profile(project_id, interface_code):
    """Environment + Profile only (no Init). Returns (lua, TA)."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(_client(project_id, interface_code))
    lua.execute(_read("Core/Environment.lua"))
    lua.execute(_read("Core/Profile.lua"))
    return lua, lua.globals().ToonAge


# ── Assertion framework ───────────────────────────────────────────────────────
_results = []


def check(name, got, want):
    ok = got == want
    _results.append((ok, name, got, want))
    if VERBOSE or not ok:
        mark = "  ok  " if ok else " FAIL "
        print(f"[{mark}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def section(title):
    if VERBOSE:
        print(f"\n--- {title} " + "-" * max(0, 60 - len(title)))


def test_profile_resolution():
    section("active profile resolves from flavor")
    _, ta = load_profile(1, 120007)
    check("retail flavor",        ta.flavor, "retail")
    check("retail profile label", ta.GetProfile(ta).label, "Mainline (Retail)")
    check("retail data namespace", ta.DataNamespace(ta), "Retail")
    check("retail stat rules",     ta.StatRules(ta), "retail-dr")

    _, ta = load_profile(5, 20506)
    check("tbc profile label",     ta.GetProfile(ta).label, "TBC Anniversary")
    check("tbc data namespace",    ta.DataNamespace(ta), "TBC")
    check("tbc stat rules",        ta.StatRules(ta), "tbc-caps")

    _, ta = load_profile(19, 50504)
    check("mists data namespace",  ta.DataNamespace(ta), "Mists")


def test_retail_allow_all():
    section("retail = allow-all")
    _, ta = load_profile(1, 120007)
    # Any module name should be allowed on retail, even one never seen.
    # ModuleAllowed returns (allowed, reason); take the first value.
    allowed_gear = ta.ModuleAllowed(ta, "Gear")[0]
    allowed_arb  = ta.ModuleAllowed(ta, "SomeFutureModule")[0]
    check("retail allows Gear",          allowed_gear, True)
    check("retail allows arbitrary mod", allowed_arb, True)
    check("retail ModuleInProfile true", ta.ModuleInProfile(ta, "Anything"), True)


def test_nonretail_explicit_list():
    section("non-retail flavors gate by explicit list (TBC set populated Task 7)")
    _, ta = load_profile(5, 20506)
    # TBC ships an explicit module set: its own modules are allowed, but a
    # retail-only module (Delves) is NOT.
    check("tbc allows its own Gear",       ta.ModuleInProfile(ta, "Gear"), True)
    check("tbc allows StatCaps",           ta.ModuleInProfile(ta, "StatCaps"), True)
    check("tbc denies retail-only Delves", ta.ModuleInProfile(ta, "Delves"), False)
    allowed, reason = ta.ModuleAllowed(ta, "Delves")
    check("tbc ModuleAllowed(Delves) false", allowed, False)
    check("tbc reason mentions profile",   "TBC Anniversary" in (reason or ""), True)


def test_scaffolds_inert():
    section("cata/vanilla/forever scaffolds are inert")
    for pid, ic, dataname in [(14, 40402, "Cata"), (2, 11507, "Vanilla")]:
        _, ta = load_profile(pid, ic)
        check(f"{dataname}: scaffold flag", ta.GetProfile(ta).scaffold, True)
        check(f"{dataname}: no modules allowed", ta.ModuleInProfile(ta, "Gear"), False)
    # 'forever' IS reachable since the 2026-09 beta (Mainline id + 16001). It
    # ships shared infrastructure only: no game-rule module may be allowed,
    # because Data/Forever does not exist yet.
    _, ta = load_profile(1, 16001)
    check("forever flavor detected",     ta.flavor, "forever")
    fp = ta.GetProfile(ta)
    check("forever profile is scaffold", fp.scaffold, True)
    check("forever data namespace",      fp.data, "Forever")
    check("forever label",               fp.label, "WoW Forever (beta)")
    check("forever allows ErrorLog",     ta.ModuleInProfile(ta, "ErrorLog"), True)
    for mod in ("Gear", "Rotation", "QuestTracker", "Delves", "StatCaps", "Talents", "AutoEquip"):
        check(f"forever denies {mod}",   ta.ModuleInProfile(ta, mod), False)
    check("forever no retail data",      ta.DataNamespace(ta), "Forever")


def test_unknown_fallback():
    section("unknown client -> safe fallback profile")
    _, ta = load_profile(999, 130000)
    check("unknown flavor",             ta.flavor, "unknown")
    check("unknown profile flagged",    ta.GetProfile(ta).unknown, True)
    check("unknown allows nothing",     ta.ModuleInProfile(ta, "Gear"), False)
    check("unknown data namespace nil", ta.DataNamespace(ta), None)


# ── Wiring test: Init.lua actually skips profile-disallowed modules ───────────
INIT_PRELUDE = r"""
print = function(...) end
CreateFrame = function() 
    local f = {}
    setmetatable(f, { __index = function() return function() return f end end })
    return f
end
C_Timer = { After = function() end }
UnitName = function() return "T" end
GetRealmName = function() return "R" end
"""


def load_init_with_flavor(project_id, interface_code):
    """Full engine boot path: Init + Environment + Profile, then fake modules."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(INIT_PRELUDE)
    lua.execute(f"WOW_PROJECT_ID = {project_id}")
    lua.execute(f"GetBuildInfo = function() return 'x','0','d',{interface_code} end")
    lua.execute(_read("Core/Init.lua"))
    lua.execute(_read("Core/Environment.lua"))
    lua.execute(_read("Core/Profile.lua"))
    ta = lua.globals().ToonAge
    # Minimal DB so InitDB-less InitModules path works; set db.modules empty.
    lua.execute("ToonAge.db = { modules = {}, safeMode = false }")
    return lua, ta


def test_initmodules_gate():
    section("InitModules skips profile-disallowed modules")
    # On retail (allow-all), a fake module initialises.
    lua, ta = load_init_with_flavor(1, 120007)
    lua.execute("""
        _retailInit = false
        ToonAge:RegisterModule("FakeRetail", { Init = function() _retailInit = true end })
    """)
    ta.InitModules(ta)
    check("retail: module Init ran", lua.globals()._retailInit, True)

    # On TBC (empty module list), the same fake module must be skipped.
    lua, ta = load_init_with_flavor(5, 20506)
    lua.execute("""
        _tbcInit = false
        ToonAge:RegisterModule("FakeRetail", { Init = function() _tbcInit = true end })
    """)
    ta.InitModules(ta)
    check("tbc: module Init skipped", lua.globals()._tbcInit, False)
    mod = ta.modules.FakeRetail
    check("tbc: module marked disabled",        mod._disabled, True)
    check("tbc: module marked profileSkipped",  mod._profileSkipped, True)


def main():
    test_profile_resolution()
    test_retail_allow_all()
    test_nonretail_explicit_list()
    test_scaffolds_inert()
    test_unknown_fallback()
    test_initmodules_gate()

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
