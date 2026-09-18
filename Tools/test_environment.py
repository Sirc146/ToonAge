#!/usr/bin/env python3
"""
ToonAge -- Environment (flavor detection) tests
===============================================
Executes the real Core/Environment.lua in an embedded Lua 5.1 runtime (the
version WoW uses) against a stubbed WOW_PROJECT_ID / GetBuildInfo, once per
client flavor, and asserts the flags it sets.

Why this matters: Core/Profile.lua keys off TA.flavor / TA.IsRetail /
TA.IsClassicFamily to decide which modules initialize and which Data namespace
to load. A wrong detection value silently loads the wrong flavor's content --
exactly the failure mode the single-engine build exists to avoid. This is the
only place that logic can be checked without launching six different clients.

Setup
-----
    python -m pip install --user lupa

Usage
-----
    python Tools/test_environment.py       # run all
    python Tools/test_environment.py -v    # show each assertion
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


def detect(project_id, interface_code):
    """Load Environment.lua under a stubbed client and return the ToonAge table."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    # Minimal stub: Environment.lua reads WOW_PROJECT_ID and GetBuildInfo()'s
    # 4th return (interface code). It also references CreateFrame only inside
    # the (now-removed) TBC guard rail; the shared version has no such call, so
    # nothing else is needed.
    prelude = f"""
    WOW_PROJECT_ID = {project_id if project_id is not None else "nil"}
    GetBuildInfo = function()
        -- version, build, date, tocversion(interface code)
        return "12.0.0", "00000", "Jan 1 2026", {interface_code if interface_code is not None else "nil"}
    end
    ToonAge = {{}}
    """
    lua.execute(prelude)
    lua.execute(_read("Core/Environment.lua"))
    return lua.globals().ToonAge


# ── Tiny assertion framework (mirrors test_onboarding.py) ─────────────────────
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


# Real interface codes per flavor, so the range-based disambiguation is
# exercised with realistic values, not just the project ID.
#   retail 120007 (Midnight PTR line) · TBC 20506 · vanilla 11507
#   wrath 30403 · cata 40402 · mists 50504
CASES = [
    # label,     project_id, interface, flavor,     is_retail, is_classic_family
    ("Retail",        1, 120007, "retail",  True,  False),
    ("Classic Era",   2, 11507,  "vanilla", False, True),
    ("TBC Anniv",     5, 20506,  "tbc",     False, True),
    ("Wrath",        11, 30403,  "wrath",   False, True),
    ("Cata",         14, 40402,  "cata",    False, True),
    ("Mists (MoP)",  19, 50504,  "mists",   False, True),
]


def test_each_flavor():
    section("per-flavor detection")
    for label, pid, ic, flavor, is_retail, is_family in CASES:
        ta = detect(pid, ic)
        check(f"{label}: flavor",            ta.flavor,          flavor)
        check(f"{label}: IsRetail",          ta.IsRetail or False, is_retail)
        check(f"{label}: IsClassicFamily",   ta.IsClassicFamily or False, is_family)


def test_exactly_one_flavor_true():
    section("exactly one flavor boolean true")
    flags = ("IsRetail", "IsClassicEra", "IsTBC", "IsWrath", "IsCata", "IsMists")
    for label, pid, ic, *_ in CASES:
        ta = detect(pid, ic)
        true_count = sum(1 for f in flags if getattr(ta, f) or False)
        check(f"{label}: exactly one of six flags set", true_count, 1)


def test_tbc_old_client_gotcha():
    section("TBC old-client fallback (project id 2 + TBC-range interface)")
    # The original 2021 TBC client reported Classic Era's project id (2) with a
    # TBC-range interface number. Detection must still resolve it to TBC, not
    # vanilla.
    ta = detect(2, 20504)
    check("old TBC build -> IsTBC", ta.IsTBC, True)
    check("old TBC build -> not classic-era flavor", ta.flavor, "tbc")


def test_unknown_client():
    section("unknown / future client")
    # WoW Forever and any unlisted project id must resolve to 'unknown', never
    # silently to a real flavor whose data would be wrong for it.
    ta = detect(999, 130000)
    check("unlisted project id -> unknown", ta.flavor, "unknown")
    check("unlisted -> not retail", ta.IsRetail or False, False)
    # Missing WOW_PROJECT_ID entirely (very old client) must not error and must
    # not claim a real flavor.
    ta = detect(None, 11200)
    check("nil project id -> unknown", ta.flavor, "unknown")


def test_forever():
    section("WoW Forever (Mainline project id, 1.60.x interface)")
    # Captured from the 2026-09 beta client: WOW_PROJECT_MAINLINE with 16001.
    ta = detect(1, 16001)
    check("forever flavor",            ta.flavor, "forever")
    check("IsForever true",            ta.IsForever, True)
    check("not retail",                ta.IsRetail, False)
    check("not classic family",        ta.IsClassicFamily or False, False)
    check("interface recorded",        ta.interfaceCode, 16001)
    # Retail must stay retail: Midnight and any future mainline build.
    for iface in (120000, 120100, 120105, 130000):
        ta = detect(1, iface)
        check(f"mainline {iface} -> retail", ta.flavor, "retail")
        check(f"mainline {iface} not forever", ta.IsForever or False, False)
    # A classic-family client with a low interface code must not become forever.
    ta = detect(5, 20506)
    check("tbc stays tbc",             ta.flavor, "tbc")
    check("tbc not forever",           ta.IsForever or False, False)


def test_isflavor_helper():
    section("TA:IsFlavor helper")
    ta = detect(1, 120007)
    check("IsFlavor('retail') true",          ta.IsFlavor(ta, "retail"), True)
    check("IsFlavor('tbc','mists') false",    ta.IsFlavor(ta, "tbc", "mists"), False)
    check("IsFlavor('tbc','retail') true",    ta.IsFlavor(ta, "tbc", "retail"), True)


def main():
    test_each_flavor()
    test_exactly_one_flavor_true()
    test_tbc_old_client_gotcha()
    test_unknown_client()
    test_forever()
    test_isflavor_helper()

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} assertions passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
