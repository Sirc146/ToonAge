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


def test_spec_from_talents():
    section("spec from talent tabs: most points, nil under 10, forever skips tabs")
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
ToonAge = {}
GetNumTalentTabs = function() return 3 end
pts = { 0, 16, 5 }
names = { "Arcane", "Fire", "Frost" }
GetTalentTabInfo = function(i) return names[i], "icon", pts[i] end
""")
    lua.execute(_read("Core/Compat/API.lua"))
    C = lua.globals().ToonAge.Compat
    idx, name = C.SpecFromTalentTabs()
    check("most points is Fire", name, "Fire")
    check("tab index 2", idx, 2)

    lua.execute("pts[1], pts[2], pts[3] = 0, 4, 3")
    check("under 10 points is nil", C.SpecFromTalentTabs(), None)

    lua.execute("pts[1], pts[2], pts[3] = 0, 12, 12")
    check("tie is nil", C.SpecFromTalentTabs(), None)

    lua.execute("ToonAge.IsForever = true")
    called = {"n": 0}
    lua.execute("""
GetNumTalentTabs = function() called = (called or 0) + 1; error("tabs") end
""")
    # rebind after the previous execute replaced the function; call and ensure no error
    check("forever does not use talent tabs", C.SpecFromTalentTabs(), None)


def test_pickup_container_item():
    section("pickup prefers C_Container and never calls a nil global")
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
ToonAge = {}
picked = nil
C_Container = { PickupContainerItem = function(b, s) picked = b .. ":" .. s end }
""")
    lua.execute(_read("Core/Compat/API.lua"))
    C = lua.globals().ToonAge.Compat
    check("pickup returns true", C.PickupContainerItem(2, 4), True)
    check("pickup recorded", lua.eval("picked"), "2:4")

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    lua.execute(_read("Core/Compat/API.lua"))
    C = lua.globals().ToonAge.Compat
    check("no pickup API returns false", C.PickupContainerItem(1, 1), False)


def _call(C, name, *args):
    fn = C[name]
    if fn is None:
        return None
    return fn(*args)


def _tuple(value, n):
    """Normalize a Lua multi-return (or a missing wrapper) to an n-tuple."""
    if value is None:
        return (None,) * n
    if not isinstance(value, tuple):
        value = (value,)
    if len(value) < n:
        value = value + (None,) * (n - len(value))
    return value[:n]


def test_item_wrappers_both_clients():
    """Load Compat twice: classic global only, then Retail C_Item only.

    Current Retail has no global GetItemInfo. Classic Era / TBC / Wrath / Cata
    / Mists / Forever may have no C_Item.GetItemInfo. Both must return the
    underlying values, and a missing function must come back nil rather than
    throw. An uncached item is a nil return, which callers have to tolerate.
    """
    section("item wrappers: global present, C_Item absent")
    classic = r"""
ToonAge = {}
C_Item = nil
GetItemInfo = function(item)
    if item == "missing" then return nil end
    return "GlobalName", "global-link", 7, 42
end
GetItemInfoInstant = function(item)
    if item == "missing" then return nil end
    return 99, "Armor", "Plate", "INVTYPE_HEAD", 135, 4, 4
end
GetItemCount = function(item, bank)
    if bank then return 5 end
    return 2
end
GetDetailedItemLevelInfo = function(item) return 200, 180, 190 end
IsEquippableItem = function(item) return item == "eq" end
GetItemQualityColor = function(q) return 1, 0, 0, "ffff0000" end
GetItemStats = function(item) return { ITEM_MOD_STAMINA_SHORT = 8 } end
"""
    lua, C = load(classic)
    check("classic wrapper present", C.GetItemInfo is not None, True)
    name, link, quality, ilvl = _tuple(_call(C, "GetItemInfo", "item:1"), 4)
    check("classic GetItemInfo name", name, "GlobalName")
    check("classic GetItemInfo link", link, "global-link")
    check("classic GetItemInfo quality", quality, 7)
    check("classic GetItemInfo ilvl", ilvl, 42)
    check("classic uncached item is nil", _call(C, "GetItemInfo", "missing"), None)
    iid, itype, isub, eloc, icon, classID, subID = _tuple(_call(C, "GetItemInfoInstant", "item:1"), 7)
    check("classic GetItemInfoInstant id", iid, 99)
    check("classic GetItemInfoInstant loc", eloc, "INVTYPE_HEAD")
    check("classic GetItemInfoInstant class", classID, 4)
    check("classic GetItemInfoInstant subclass", subID, 4)
    check("classic GetItemCount bags", _call(C, "GetItemCount", 1, False), 2)
    check("classic GetItemCount bank", _call(C, "GetItemCount", 1, True), 5)
    actual, preview, sparse = _tuple(_call(C, "GetDetailedItemLevelInfo", "item:1"), 3)
    check("classic detailed ilvl", actual, 200)
    check("classic detailed preview", preview, 180)
    check("classic equippable true", _call(C, "IsEquippableItem", "eq"), True)
    check("classic equippable false", _call(C, "IsEquippableItem", "no"), False)
    r, g, b, hx = _tuple(_call(C, "GetItemQualityColor", 5), 4)
    check("classic quality r", r, 1)
    check("classic quality g", g, 0)
    check("classic quality b", b, 0)
    check("classic quality hex", hx, "ffff0000")
    stats = _call(C, "GetItemStats", "item:1")
    check("classic stats stamina", stats["ITEM_MOD_STAMINA_SHORT"], 8)

    section("item wrappers: global absent, C_Item present")
    retail = r"""
ToonAge = {}
GetItemInfo = nil
GetItemInfoInstant = nil
GetItemCount = nil
GetDetailedItemLevelInfo = nil
IsEquippableItem = nil
GetItemQualityColor = nil
GetItemStats = nil
C_Item = {
    GetItemInfo = function(item)
        if item == "missing" then return nil end
        return "RetailName", "retail-link", 4, 80
    end,
    GetItemInfoInstant = function(item)
        return 50, "Weapon", "Sword", "INVTYPE_WEAPON", 1, 2, 7
    end,
    GetItemCount = function(item, bank) return bank and 9 or 3 end,
    GetDetailedItemLevelInfo = function(item) return 415, 400, 390 end,
    IsEquippableItem = function(item) return true end,
    GetItemQualityColor = function(q) return 0.1, 0.2, 0.3, "ff010203" end,
    GetItemStats = function(item) return { ITEM_MOD_VERSATILITY = 12 } end,
}
"""
    lua, C = load(retail)
    check("retail quality color global is nil", lua.eval("GetItemQualityColor"), None)
    name, link, quality, ilvl = _tuple(_call(C, "GetItemInfo", "item:9"), 4)
    check("retail GetItemInfo name", name, "RetailName")
    check("retail GetItemInfo quality", quality, 4)
    check("retail uncached item is nil", _call(C, "GetItemInfo", "missing"), None)
    iid, _, _, eloc, _, classID, subID = _tuple(_call(C, "GetItemInfoInstant", "item:9"), 7)
    check("retail GetItemInfoInstant id", iid, 50)
    check("retail GetItemInfoInstant loc", eloc, "INVTYPE_WEAPON")
    check("retail GetItemInfoInstant class", classID, 2)
    check("retail GetItemCount", _call(C, "GetItemCount", 9, True), 9)
    actual = _tuple(_call(C, "GetDetailedItemLevelInfo", "item:9"), 1)[0]
    check("retail detailed ilvl", actual, 415)
    check("retail equippable", _call(C, "IsEquippableItem", "x"), True)
    r, g, b, hx = _tuple(_call(C, "GetItemQualityColor", 3), 4)
    check("retail quality color r", r, 0.1)
    check("retail quality color g", g, 0.2)
    check("retail quality color b", b, 0.3)
    check("retail quality color hex", hx, "ff010203")
    stats = _call(C, "GetItemStats", "item:9")
    check("retail stats versatility", stats["ITEM_MOD_VERSATILITY"], 12)

    section("item wrappers: both present prefers C_Item; both absent is nil")
    both = r"""
ToonAge = {}
GetItemInfo = function() return "global" end
C_Item = { GetItemInfo = function() return "citem" end }
"""
    _, C = load(both)
    check("both present prefers C_Item", _call(C, "GetItemInfo", 1), "citem")

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    lua.execute(_read("Core/Compat/API.lua"))
    C = lua.globals().ToonAge.Compat
    check("no item API -> nil name", _call(C, "GetItemInfo", 1), None)
    check("no item API -> nil instant", _call(C, "GetItemInfoInstant", 1), None)
    check("no item API -> nil count", _call(C, "GetItemCount", 1), None)
    check("no item API -> nil ilvl", _call(C, "GetDetailedItemLevelInfo", 1), None)
    check("no item API -> nil equippable", _call(C, "IsEquippableItem", 1), None)
    check("no item API -> nil color", _call(C, "GetItemQualityColor", 1), None)
    check("no item API -> nil stats", _call(C, "GetItemStats", "x"), None)


def test_item_quality_color_shapes():
    """GetItemQualityColor is four returns on every live client.

    Retail 10.2.6+, Forever, Mists, TBC, and Era all return r, g, b, hex.
    The global is nil on current Retail, so that path must use C_Item.
    A table in the first return is unpacked only as a fallback.
    """
    section("quality color: four returns, global nil")
    lua, C = load(r"""
ToonAge = {}
GetItemQualityColor = nil
C_Item = { GetItemQualityColor = function(q) return 0.25, 0.5, 0.75, "ff4080bf" end }
""")
    check("global stays nil", lua.eval("GetItemQualityColor"), None)
    r, g, b, hx = _tuple(_call(C, "GetItemQualityColor", 4), 4)
    check("multi-return r", r, 0.25)
    check("multi-return g", g, 0.5)
    check("multi-return b", b, 0.75)
    check("multi-return hex", hx, "ff4080bf")

    section("quality color: four returns from the global")
    _, C = load(r"""
ToonAge = {}
C_Item = nil
GetItemQualityColor = function(q) return 1, 0.5, 0, "ffff8000" end
""")
    r, g, b, hx = _tuple(_call(C, "GetItemQualityColor", 5), 4)
    check("global multi-return r", r, 1)
    check("global multi-return g", g, 0.5)
    check("global multi-return b", b, 0)
    check("global multi-return hex", hx, "ffff8000")

    section("quality color: table is only a fallback")
    lua, C = load(r"""
ToonAge = {}
GetItemQualityColor = nil
C_Item = { GetItemQualityColor = function(q)
    return { r = 0.2, g = 0.4, b = 0.6, hex = "ff336699" }
end }
""")
    check("table-shape global is nil", lua.eval("GetItemQualityColor"), None)
    r, g, b, hx = _tuple(_call(C, "GetItemQualityColor", 3), 4)
    check("table fallback r", r, 0.2)
    check("table fallback g", g, 0.4)
    check("table fallback b", b, 0.6)
    check("table fallback hex", hx, "ff336699")


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
    test_item_wrappers_both_clients()
    test_item_quality_color_shapes()
    test_talent_tabs()
    test_spec_from_talents()
    test_pickup_container_item()
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
