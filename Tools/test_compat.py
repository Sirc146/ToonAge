#!/usr/bin/env python3
"""
ToonAge -- Compat (cross-flavor API shim) tests
================================================
Executes the real Core/Compat/API.lua in an embedded Lua 5.1 runtime under two
stubbed client environments and asserts each shim resolves to the RIGHT
underlying call and returns the normalized shape.

  * "retail": C_Container / C_Spell / C_Item / C_AddOns present; no bare globals.
  * "classic": only the bare globals (GetContainerNumSlots, GetSpellInfo, ...);
    C_* namespaces absent. Also has the old tab-based talent API.

Why this matters: Gear/AutoEquip/PetCare call U.GetContainerNumSlots (which
delegates here) on every bag slot; a shim that picks the wrong call, or that
re-tests the namespace per call, is either broken or slow in the addon's
hottest path. And a spell/talent shim that returns the wrong SHAPE
(table vs tuple) silently corrupts every consumer.

Note: TA.Compat.* are dot-functions (no `self`), so they are called directly
as C.Fn(args) -- no leading table argument.

Setup:  python -m pip install --user lupa
Usage:  python Tools/test_compat.py [-v]
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


# ── Stub environments ─────────────────────────────────────────────────────────
# Each returns a sentinel value that identifies WHICH underlying call ran, so a
# shim picking the wrong path fails loudly rather than returning a plausible-
# looking value from the wrong API.

RETAIL_ENV = r"""
ToonAge = {}
C_Container = {
    GetContainerNumSlots = function(bag) return 100 + bag end,
    GetContainerItemLink = function(bag, slot) return "retail-link-"..bag.."-"..slot end,
    GetContainerItemID   = function(bag, slot) return 5000 + slot end,
    GetContainerItemInfo = function(bag, slot) return { itemID = 9000 + slot } end,
}
C_Spell = {
    GetSpellName = function(id) return "RetailSpell"..id end,
    GetSpellInfo = function(id) return { name = "RetailSpell"..id, iconID = 700 + id, castTime = 1500 } end,
    GetSpellCooldown = function(id) return { startTime = 10, duration = 20, isEnabled = true } end,
}
C_SpellBook = { IsSpellKnown = function(id) return id == 42 end }
C_Item = { GetItemInfo = function(item) return "RetailItem" end }
C_AddOns = {
    IsAddOnLoaded  = function(name) return name == "Loaded" end,
    GetAddOnMetadata = function(name, field) return "retail-meta" end,
}
"""

CLASSIC_ENV = r"""
ToonAge = {}
GetContainerNumSlots = function(bag) return 200 + bag end
GetContainerItemLink = function(bag, slot) return "classic-link-"..bag.."-"..slot end
GetContainerItemID   = function(bag, slot) return 6000 + slot end
GetContainerItemInfo = function(bag, slot) return "tex", 1, false, 2 end
GetSpellInfo = function(id) return "ClassicSpell"..id, "rank", 800 + id, 2000 end
GetSpellTexture = function(id) return 800 + id end
GetSpellCooldown = function(id) return 5, 15, 1 end
IsSpellKnown = function(id) return id == 99 end
GetItemInfo = function(item) return "ClassicItem" end
IsAddOnLoaded = function(name) return name == "ClassicLoaded" end
GetAddOnMetadata = function(name, field) return "classic-meta" end
GetNumTalentTabs = function() return 3 end
GetTalentTabInfo = function(tab) return "Tab"..tab end
GetTalentInfo = function(tab, idx) return "Talent"..tab.."-"..idx end
"""


def load(env):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(env)
    lua.execute(_read("Core/Compat/API.lua"))
    return lua, lua.globals().ToonAge.Compat


# ── Tiny assertion framework ─────────────────────────────────────────────────
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


def test_retail_container():
    section("retail: container -> C_Container")
    _, C = load(RETAIL_ENV)
    check("num slots via C_Container",  C.GetContainerNumSlots(1), 101)
    check("item link via C_Container",  C.GetContainerItemLink(2, 3), "retail-link-2-3")
    check("item id via C_Container",    C.GetContainerItemID(0, 4), 5004)


def test_classic_container():
    section("classic: container -> bare globals")
    _, C = load(CLASSIC_ENV)
    check("num slots via global",  C.GetContainerNumSlots(1), 201)
    check("item link via global",  C.GetContainerItemLink(2, 3), "classic-link-2-3")
    check("item id via global",    C.GetContainerItemID(0, 4), 6004)


def test_retail_spell_shape():
    section("retail: spell shim normalizes C_Spell table -> name/icon/castTime")
    _, C = load(RETAIL_ENV)
    check("spell name",  C.GetSpellName(5), "RetailSpell5")
    name, icon, cast = C.GetSpellInfo(5)
    check("GetSpellInfo name",     name, "RetailSpell5")
    check("GetSpellInfo icon",     icon, 705)
    check("GetSpellInfo castTime", cast, 1500)
    check("spell texture (iconID)", C.GetSpellTexture(5), 705)
    check("IsSpellKnown true for 42",  C.IsSpellKnown(42), True)
    check("IsSpellKnown false for 1",  C.IsSpellKnown(1), False)


def test_classic_spell_shape():
    section("classic: spell shim normalizes global tuple -> name/icon/castTime")
    _, C = load(CLASSIC_ENV)
    check("spell name",  C.GetSpellName(5), "ClassicSpell5")
    name, icon, cast = C.GetSpellInfo(5)
    check("GetSpellInfo name",     name, "ClassicSpell5")
    check("GetSpellInfo icon",     icon, 805)
    check("GetSpellInfo castTime", cast, 2000)
    check("IsSpellKnown true for 99", C.IsSpellKnown(99), True)


def test_item_and_addon():
    section("item + addon shims both flavors")
    _, C = load(RETAIL_ENV)
    check("retail item -> C_Item",     C.GetItemInfo(1), "RetailItem")
    check("retail addon loaded true",  C.IsAddOnLoaded("Loaded"), True)
    check("retail addon loaded false", C.IsAddOnLoaded("Nope"), False)
    check("retail metadata",           C.GetAddOnMetadata("X", "Version"), "retail-meta")
    _, C = load(CLASSIC_ENV)
    check("classic item -> global",    C.GetItemInfo(1), "ClassicItem")
    check("classic addon loaded true", C.IsAddOnLoaded("ClassicLoaded"), True)


def test_talent_tabs():
    section("talent tabs: classic has them, retail does not")
    _, C = load(CLASSIC_ENV)
    check("classic HasTalentTabs",  C.HasTalentTabs(), True)
    check("classic num tabs",       C.GetNumTalentTabs(), 3)
    check("classic tab info",       C.GetTalentTabInfo(2), "Tab2")
    _, C = load(RETAIL_ENV)
    check("retail HasTalentTabs",   C.HasTalentTabs(), False)
    check("retail num tabs -> 0",   C.GetNumTalentTabs(), 0)
    check("retail tab info -> nil", C.GetTalentTabInfo(1), None)


def test_missing_api_degrades():
    section("missing API degrades safely, does not error")
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    lua.execute(_read("Core/Compat/API.lua"))
    C = lua.globals().ToonAge.Compat
    check("num slots with no API -> 0",   C.GetContainerNumSlots(1), 0)
    check("item link with no API -> nil", C.GetContainerItemLink(1, 1), None)
    check("HasTalentTabs with no API",    C.HasTalentTabs(), False)


def main():
    test_retail_container()
    test_classic_container()
    test_retail_spell_shape()
    test_classic_spell_shape()
    test_item_and_addon()
    test_talent_tabs()
    test_missing_api_degrades()

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
