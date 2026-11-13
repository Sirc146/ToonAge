#!/usr/bin/env python3
"""Forever reagent restock: Light Feather, guarded counts, read-only MelloUI.

Runs the real Compat, AddonBridge, Forever reagent list and Restock module
under Lua 5.1. A missing Light Feather, a thrown count call, or a write into
a MelloUI Restock saved variable fails this suite.

Usage:  python3 Tools/test_scrolls_restock.py [-v]
"""
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

HOST_NAMES = (
    "MelloUI_RestockDB",
    "MelloRestockDB",
    "MelloUIRestockDB",
    "MelloUI_Restock",
    "MelloRestock",
)
SOURCE = "https://db.icy-veins.com/wow-forever/items/17056"


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def fresh():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, Data = {} }
        function ToonAge:RegisterModule(name, module)
            self.modules[name] = module
            self[name] = module
        end
        function ToonAge:GetModule(name)
            local mod = self.modules[name]
            if not mod or mod._disabled then return nil end
            return mod
        end
        C_AddOns = { IsAddOnLoaded = function() return false end }
        IsPlayerSpell = nil
        IsSpellKnown = nil
        C_SpellBook = nil
        C_Item = nil
        C_Container = nil
        GetItemCount = nil
    """)
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Infrastructure/AddonBridge.lua"))
    lua.execute(read("Data/Forever/Reagents.lua"))
    lua.execute(read("Modules/Forever/Restock.lua"))
    lua.execute("TA = ToonAge; TA.IsForever = true; TA.db = {}")
    return lua


def find_row(rows, item_id):
    if rows is None:
        return None
    # lupa table, 1-based
    i = 1
    while True:
        row = rows[i]
        if row is None:
            return None
        if int(row["itemID"] or 0) == item_id:
            return row
        i += 1


def test_catalog_and_toc():
    text = read("Data/Forever/Reagents.lua")
    check("17056 is the sourced item", re.findall(r"itemID\s*=\s*(\d+)", text), ["17056"])
    check("source url is on the list", SOURCE in text, True)
    check("Study 1302508 is named", "1302508" in text and "Study" in text, True)
    check("Slow Fall is named", "Slow Fall" in text, True)
    check("Levitate is named", "Levitate" in text, True)
    check("three reagents stay UNKNOWN", text.count('status = "UNKNOWN"'), 3)

    camelot = read("ToonAge_Camelot.toc")
    check("Camelot lists the reagent data", "Data\\Forever\\Reagents.lua" in camelot, True)
    check("Camelot lists the restock module", "Modules\\Forever\\Restock.lua" in camelot, True)
    for name in (
        "ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_Mists.toc", "ToonAge_TBC.toc",
        "ToonAge_Vanilla.toc", "ToonAge_Cata.toc", "ToonAge_Wrath.toc",
    ):
        body = read(name)
        check(f"{name} does not list Reagents.lua", "Reagents.lua" in body, False)
        check(f"{name} does not list Restock.lua", "Restock.lua" in body, False)

    api = read("Core/Compat/API.lua")
    fn = api.split("function C.ItemCounts", 1)[1].split("\nfunction ", 1)[0]
    order = [fn.find(name) for name in (
        "C_Item.GetItemCount", "C_Container.GetItemCount", "pcall(GetItemCount",
    )]
    check("count variants are in fallback order", order[0] < order[1] < order[2], True)
    check("each count variant is pcall'd", fn.count("pcall(") >= 3, True)
    knows = api.split("function C.PlayerKnowsSpell", 1)[1].split("\nfunction ", 1)[0]
    check("IsPlayerSpell is pcall'd", "pcall(function() return IsPlayerSpell(spellID) end)" in knows, True)
    check("IsSpellKnown is pcall'd", "pcall(function() return IsSpellKnown(spellID) end)" in knows, True)
    check("IsPlayerSpell is asked before IsSpellKnown",
          knows.find("IsPlayerSpell") < knows.find("IsSpellKnown"), True)

    for rel in (
        "Modules/Forever/Restock.lua",
        "Data/Forever/Reagents.lua",
        "Modules/Forever/Scrolls.lua",
        "Modules/Infrastructure/Settings.lua",
        "Core/Compat/API.lua",
    ):
        body = read(rel)
        for host in HOST_NAMES:
            assigned = re.search(rf"(?<![\w.]){host}\s*=[^=]", body)
            check(f"{rel} does not assign {host}", assigned is None, True)


def test_count_fallback():
    lua = fresh()
    lua.execute(r"""
        CALLS = {}
        local function note(name) CALLS[#CALLS + 1] = name end
        C_Item = { GetItemCount = function(id, bank)
            note("C_Item")
            if bank == true then return 5 end
            return 2
        end }
        C_Container = { GetItemCount = function()
            note("C_Container")
            error("should not run")
        end }
        GetItemCount = function()
            note("global")
            error("should not run")
        end
        HAVE, BANK, WHICH = TA.Compat.ItemCounts(17056)
        N = #CALLS
        FIRST = CALLS[1]
    """)
    g = lua.globals()
    check("C_Item supplies the bag count", int(g.HAVE), 2)
    check("bank is the remainder, not added to bags", int(g.BANK), 3)
    check("winner is C_Item.GetItemCount", g.WHICH, "C_Item.GetItemCount")
    check("C_Item is the only variant called", int(g.N), 2)
    check("first call is C_Item", g.FIRST, "C_Item")

    lua = fresh()
    lua.execute(r"""
        CALLS = {}
        local function note(name) CALLS[#CALLS + 1] = name end
        C_Item = { GetItemCount = function() note("C_Item"); error("missing") end }
        C_Container = { GetItemCount = function(id, bank)
            note("C_Container")
            if bank == nil then return nil end
            error("not an item id")
        end }
        GetItemCount = function(id, bank)
            note("global")
            if bank == true then return 9 end
            return 4
        end
        HAVE, BANK, WHICH = TA.Compat.ItemCounts(17056)
        local function at(name)
            for i = 1, #CALLS do
                if CALLS[i] == name then return i end
            end
            return 0
        end
        ORDER_OK = at("C_Item") > 0 and at("C_Item") < at("C_Container") and at("C_Container") < at("global")
    """)
    g = lua.globals()
    check("a throwing C_Item falls through", g.WHICH, "GetItemCount")
    check("global bag count is used", int(g.HAVE), 4)
    check("global bank remainder", int(g.BANK), 5)
    check("order is C_Item, then C_Container, then global", bool(g.ORDER_OK), True)

    lua = fresh()
    lua.execute(r"""
        CALLS = {}
        local function note(name) CALLS[#CALLS + 1] = name end
        C_Item = nil
        C_Container = { GetItemCount = function(id, bank)
            note("C_Container")
            if type(id) ~= "number" then error("no") end
            if bank == true then return 3 end
            return 3
        end }
        GetItemCount = function() note("global"); return 99 end
        HAVE, BANK, WHICH = TA.Compat.ItemCounts(17056)
        GLOBALS = 0
        for i = 1, #CALLS do if CALLS[i] == "global" then GLOBALS = GLOBALS + 1 end end
    """)
    g = lua.globals()
    check("C_Container is used when it accepts an item id", g.WHICH, "C_Container.GetItemCount")
    check("C_Container bag count", int(g.HAVE), 3)
    check("equal bank flag means bank 0", int(g.BANK), 0)
    check("global is not called after C_Container works", int(g.GLOBALS), 0)

    lua = fresh()
    lua.execute(r"""
        C_Item = { GetItemCount = function() error("no") end }
        C_Container = { GetItemCount = function() error("no") end }
        GetItemCount = function() error("no") end
        OK, HAVE = pcall(function() return TA.Compat.ItemCounts(17056) end)
    """)
    g = lua.globals()
    check("all-missing count does not throw", bool(g.OK), True)
    check("all-missing count is nil", g.HAVE, None)

    lua = fresh()
    lua.execute(r"""
        IsPlayerSpell = function() error("no") end
        IsSpellKnown = function(id) return id == 1302508 end
        THREW = false
        local ok, known = pcall(function() return TA.Compat.PlayerKnowsSpell(1302508) end)
        SPELL_OK, SPELL_KNOWN = ok, known
        IsPlayerSpell = nil
        IsSpellKnown = nil
        C_SpellBook = nil
        local ok2, known2 = pcall(function() return TA.Compat.PlayerKnowsSpell(1302508) end)
        NONE_OK, NONE_KNOWN = ok2, known2
        IsPlayerSpell = function(id) return id == 1302508 end
        IsSpellKnown = function() error("later") end
        local ok3, known3 = pcall(function() return TA.Compat.PlayerKnowsSpell(1302508) end)
        FIRST_OK, FIRST_KNOWN = ok3, known3
    """)
    g = lua.globals()
    check("spell lookup survives a throwing IsPlayerSpell", bool(g.SPELL_OK), True)
    check("IsSpellKnown answers after IsPlayerSpell throws", bool(g.SPELL_KNOWN), True)
    check("no spell API does not throw", bool(g.NONE_OK), True)
    check("no spell API is nil, not false", g.NONE_KNOWN, None)
    check("IsPlayerSpell true is known", bool(g.FIRST_OK) and bool(g.FIRST_KNOWN), True)


def test_rows_and_host():
    lua = fresh()
    lua.execute(r"""
        GetItemCount = function(id, bank)
            if bank == true then return 6 end
            return 1
        end
        IsPlayerSpell = function(id) return id == 1302508 end
        function summary()
            local rows = TA.ForeverRestock:Rows()
            local out = {}
            for i = 1, #rows do
                local r = rows[i]
                out[i] = table.concat({
                    tostring(r.itemID),
                    r.name or "",
                    r.haveText or "",
                    tostring(r.need),
                    r.warning or "",
                    r.label or "",
                    r.studyText or "",
                    tostring(r.bank),
                    r.source or "",
                }, "|")
            end
            RESULT = table.concat(out, "\n")
        end
        summary()
        FEATHER_QTY = nil
        local own = TA.db.addonBridge.restock
        for i = 1, #own do
            if own[i].id == 17056 then FEATHER_QTY = own[i].qty end
        end
    """)
    g = lua.globals()
    text = g.RESULT
    check("feather row shows bags over target", "17056|Light Feather|1 / 20|19|need 19|" in text, True)
    check("bank is labeled on its own", "|5|standalone" in text, True)
    check("study warning when the spell is known",
          "Light Feather is below target and Study is known" in text, True)
    check("default target is stored on ToonAge", int(g.FEATHER_QTY), 20)
    check("Arcane Powder is UNKNOWN", "nil|Arcane Powder|UNKNOWN|" in text, True)
    check("Rune of Teleportation is UNKNOWN", "nil|Rune of Teleportation|UNKNOWN|" in text, True)
    check("Rune of Portals is UNKNOWN", "nil|Rune of Portals|UNKNOWN|" in text, True)

    lua.execute(r"""
        IsPlayerSpell = function() return false end
        IsSpellKnown = function() return false end
        summary()
    """)
    check("no study warning when the spell is not known",
          "Study is known" in lua.globals().RESULT, False)

    lua.execute(r"""
        GetItemCount = nil
        summary()
    """)
    check("missing count APIs say count unavailable",
          "count unavailable" in lua.globals().RESULT, True)
    check("missing count does not invent a need",
          "need " in lua.globals().RESULT, False)

    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI_Restock" end
        MelloUI_RestockDB = { items = { { id = 123, qty = 2 } }, extra = "keep" }
        MelloRestockDB = { sentinel = 1 }
        MelloUIRestockDB = { sentinel = 2 }
        MelloUI_Restock = { db = { items = { { id = 999, qty = 8 } } } }
        MelloRestock = { db = { items = { { id = 998, qty = 8 } } } }
        function snap()
            return MelloUI_RestockDB.items[1].id .. ":" .. MelloUI_RestockDB.items[1].qty
                .. ":" .. tostring(MelloUI_RestockDB.extra)
                .. ":" .. MelloRestockDB.sentinel
                .. ":" .. MelloUIRestockDB.sentinel
                .. ":" .. MelloUI_Restock.db.items[1].qty
                .. ":" .. MelloRestock.db.items[1].qty
        end
        GetItemCount = function() return 0 end
        BEFORE = snap()
        local rows = TA.ForeverRestock:Rows()
        TA.ForeverRestock:SetTarget(17056, 7)
        TA.ForeverRestock:Nudge(123, 1)
        AFTER = snap()
        local lines = {}
        rows = TA.ForeverRestock:Rows()
        for i = 1, #rows do
            local r = rows[i]
            lines[i] = tostring(r.itemID) .. "|" .. (r.label or "") .. "|" .. tostring(r.target) .. "|" .. (r.source or "")
        end
        MERGED = table.concat(lines, "\n")
        OWN = ""
        local own = TA.db.addonBridge.restock
        for i = 1, #own do
            OWN = OWN .. own[i].id .. ":" .. own[i].qty .. ","
        end
    """)
    g = lua.globals()
    check("reading and editing misses every host restock global", g.AFTER, g.BEFORE)
    check("host item is labeled from MelloUI Restock",
          "123|from MelloUI Restock|" in g.MERGED, True)
    check("standalone feather stays on the merged list",
          "17056|" in g.MERGED, True)
    check("our target is not replaced by the host quantity",
          "17056:7" in g.OWN, True)
    check("nudging a host item stores the target on ToonAge",
          "123:3" in g.OWN, True)

    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function() return false end
        MelloUI_Restock = nil
        MelloRestock = nil
        function snap()
            return MelloUI_RestockDB.items[1].id .. ":" .. MelloUI_RestockDB.items[1].qty
                .. ":" .. tostring(MelloUI_RestockDB.extra)
                .. ":" .. MelloRestockDB.sentinel
                .. ":" .. MelloUIRestockDB.sentinel
        end
        BEFORE = snap()
        local rows = TA.ForeverRestock:Rows()
        local lines = {}
        for i = 1, #rows do
            lines[i] = tostring(rows[i].itemID) .. "|" .. (rows[i].label or "") .. "|" .. tostring(rows[i].target)
        end
        ALONE = table.concat(lines, "\n")
        AFTER = snap()
    """)
    g = lua.globals()
    check("standalone feather remains without the host", "17056|" in g.ALONE, True)
    check("standalone feather is not labeled from MelloUI",
          "17056|from MelloUI Restock" in g.ALONE, False)
    check("a saved host item stays on our list without the host label",
          "123||3" in g.ALONE, True)
    check("a present but unloaded host table is not written", g.AFTER, g.BEFORE)

    lua = fresh()
    lua.execute(r"""
        MelloUI_RestockDB = { items = { { id = 123, qty = 2 } }, extra = "keep" }
        MelloRestockDB = { sentinel = 1 }
        MelloUIRestockDB = { sentinel = 2 }
        function snap()
            return MelloUI_RestockDB.items[1].qty .. ":" .. MelloUI_RestockDB.extra
                .. ":" .. MelloRestockDB.sentinel .. ":" .. MelloUIRestockDB.sentinel
        end
        GetItemCount = function() return 0 end
        BEFORE = snap()
        local rows = TA.ForeverRestock:Rows()
        local saw = false
        for i = 1, #rows do
            if rows[i].itemID == 123 then saw = true end
        end
        SAW = saw
        AFTER = snap()
        FEATHER = false
        for i = 1, #rows do
            if rows[i].itemID == 17056 and (rows[i].label or "") == "" then FEATHER = true end
        end
    """)
    g = lua.globals()
    check("an unloaded host list is not merged", bool(g.SAW), False)
    check("standalone feather still shows when the host is absent", bool(g.FEATHER), True)
    check("an unloaded host table is not written", g.AFTER, g.BEFORE)


def main():
    test_catalog_and_toc()
    test_count_fallback()
    test_rows_and_host()
    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
