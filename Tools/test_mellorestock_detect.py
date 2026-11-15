#!/usr/bin/env python3
"""MelloUI Restock is a module inside MelloUI, not its own addon.

WoW Forever (Jarvis, 2026-11-14): there is no MelloUI_Restock folder and no
SavedVariables file. MelloUI 2.1.51 loads Modules/Restock.lua, which sets
MelloUI.Restock and answers MelloUI:GetModule("Restock"). The character list
lives in the in-memory MelloUIDB["Restock"] table as list_<GUID> = "id:qty ...".

This runs the real Compat wrapper and AddonBridge. It fails while detection
only probes the legacy addon name.

Usage:  python3 Tools/test_mellorestock_detect.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

LABEL = "MelloUI Restock"


def as_int(v):
    if v is None:
        return None
    return int(v)


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
        ToonAge = { modules = {}, db = {} }
        function ToonAge:RegisterModule(name, module)
            self.modules[name] = module
            self[name] = module
        end
        UIParent = nil
        GameTooltip = nil
        C_AddOns = {
            IsAddOnLoaded = function() return false end,
            GetAddOnInfo = function(name) return name, name, "", true, true end,
        }
        IsAddOnLoaded = nil
        GetAddOnInfo = nil
        LibStub = nil
        UnitGUID = function() return nil end
    """)
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Infrastructure/AddonBridge.lua"))
    lua.execute("TA = ToonAge")
    return lua


def loaded_line(lua):
    lua.execute(r"""
        _loaded = TA.AddonBridge:IsLoaded("mellorest")
        _line = ""
        local lines = TA.AddonBridge:ReportLines()
        for i = 1, #lines do
            if lines[i]:sub(1, #("MelloUI Restock:")) == "MelloUI Restock:" then
                _line = lines[i]
            end
        end
        _label = ""
        for _, entry in ipairs(TA.AddonBridge.CATALOG) do
            if entry.id == "mellorest" then _label = entry.label end
        end
    """)
    g = lua.globals()
    return bool(g._loaded), g._line, g._label


def test_label():
    lua = fresh()
    _, _, label = loaded_line(lua)
    check("catalog label is the self-test name", label, LABEL)


def test_embedded_field():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = { Restock = { enabledByDefault = true } }
    """)
    loaded, line, _ = loaded_line(lua)
    check("MelloUI.Restock counts as loaded", loaded, True)
    check("report says MelloUI Restock loaded", line.startswith(LABEL + ": loaded"), True)
    check("not standalone while restock is inside MelloUI",
          bool(lua.eval("TA.AddonBridge:IsStandalone()")), False)


def test_embedded_getmodule():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = {
            GetModule = function(self, name)
                if name == "Restock" then return { enabledByDefault = true } end
            end,
        }
    """)
    loaded, line, _ = loaded_line(lua)
    check("GetModule('Restock') counts as loaded", loaded, True)
    check("GetModule path still uses the MelloUI Restock label",
          line.startswith(LABEL + ": loaded"), True)


def test_getmodule_guarded():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = { GetModule = function() error("missing") end }
    """)
    loaded, line, _ = loaded_line(lua)
    check("a throwing GetModule is not loaded", loaded, False)
    check("a throwing GetModule stays not loaded", line.startswith(LABEL + ": not loaded"), True)

    lua.execute(r"""
        MelloUI = { GetModule = function() return "Restock" end }
    """)
    loaded, line, _ = loaded_line(lua)
    check("a non-table GetModule result is not loaded", loaded, False)
    check("a non-table result stays not loaded", line.startswith(LABEL + ": not loaded"), True)


def test_requires_mello_addon():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function() return false end
        MelloUI = { Restock = {} }
    """)
    loaded, line, _ = loaded_line(lua)
    check("a Restock table without the MelloUI addon is not loaded", loaded, False)
    check("unloaded MelloUI stays not loaded", line.startswith(LABEL + ": not loaded"), True)

    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = {}
    """)
    loaded, line, _ = loaded_line(lua)
    check("MelloUI without a Restock module is not loaded", loaded, False)
    check("missing Restock module stays not loaded", line.startswith(LABEL + ": not loaded"), True)


def test_classic_isaddonloaded():
    lua = fresh()
    lua.execute(r"""
        C_AddOns = nil
        IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = { Restock = {} }
    """)
    loaded, line, _ = loaded_line(lua)
    check("classic IsAddOnLoaded still detects the embedded module", loaded, True)
    check("classic path reports MelloUI Restock loaded",
          line.startswith(LABEL + ": loaded"), True)


def test_legacy_fallback():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI_Restock" end
    """)
    loaded, line, _ = loaded_line(lua)
    check("legacy MelloUI_Restock addon still counts", loaded, True)
    check("legacy addon still uses the MelloUI Restock label",
          line.startswith(LABEL + ": loaded"), True)

    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function() return false end
        MelloUI_Restock = {}
    """)
    loaded, _, _ = loaded_line(lua)
    check("legacy MelloUI_Restock global still counts", loaded, True)


def test_live_list_readonly():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = { Restock = { enabledByDefault = true } }
        CALLED = 0
        MelloUIDB = {
            Restock = {
                ["!enabled"] = true,
                below = 1,
                shopPanel = true,
                listH = 8,
                ["list_Player-1-OTHER"] = "99999:1",
                ["list_Player-1-ABC"] = "17031:10 17032:10 17020:20 17056:20 nope 12: :3",
                evil = function() CALLED = CALLED + 1 end,
            },
        }
        UnitGUID = function() return "Player-1-ABC" end
        BEFORE = MelloUIDB.Restock["list_Player-1-ABC"]
        LIST, SOURCE = TA.AddonBridge:ReadRestock()
        function qty(id)
            if type(LIST) ~= "table" or type(LIST.items) ~= "table" then return nil end
            for i = 1, #LIST.items do
                if LIST.items[i].id == id then return LIST.items[i].qty end
            end
        end
        QTY_FEATHER = qty(17056)
        QTY_POWDER = qty(17031)
        QTY_OTHER = qty(99999)
        N = 0
        if type(LIST) == "table" and type(LIST.items) == "table" then N = #LIST.items end
        HAS_EVIL = type(LIST) == "table" and LIST.evil ~= nil
        if type(LIST) == "table" and type(LIST.items) == "table" and LIST.items[1] then
            LIST.items[1].qty = 0
        end
        WROTE = TA.AddonBridge:WriteStandalone(MelloUIDB.Restock)
        AFTER = MelloUIDB.Restock["list_Player-1-ABC"]
    """)
    g = lua.globals()
    check("live settings are the melloui source", g.SOURCE, "melloui")
    check("Light Feather qty is read from list_<GUID>", as_int(g.QTY_FEATHER), 20)
    check("first reagent qty is read", as_int(g.QTY_POWDER), 10)
    check("four well-formed rows", as_int(g.N), 4)
    check("another character's list is not used", g.QTY_OTHER is None, True)
    check("a function on the settings table is not called", as_int(g.CALLED), 0)
    check("a function is not copied into the result", bool(g.HAS_EVIL), False)
    check("reading does not change the live string", g.AFTER, g.BEFORE)
    check("writing the live settings table is refused", bool(g.WROTE), False)
    check("refused write leaves the live string", g.AFTER, "17031:10 17032:10 17020:20 17056:20 nope 12: :3")


def test_no_guid_does_not_borrow_an_alt():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI" end
        MelloUI = { Restock = {} }
        MelloUIDB = { Restock = { ["list_Player-1-OTHER"] = "17056:20" } }
        ToonAge.HasAPI = function() return false end
        UnitGUID = function() return "Player-1-ABC" end
        LIST, SOURCE = TA.AddonBridge:ReadRestock()
        N = 0
        if type(LIST) == "table" and type(LIST.items) == "table" then N = #LIST.items end
    """)
    g = lua.globals()
    check("ApiGuard hiding UnitGUID still reports the host", g.SOURCE, "melloui")
    check("ApiGuard hiding UnitGUID does not read an alt list", as_int(g.N), 0)


def test_source_stays_in_memory():
    src = read("Modules/Infrastructure/AddonBridge.lua")
    for bad in ("LoadAddOn", "loadstring", "dofile", "SavedVariables"):
        check(f"bridge source has no {bad}", bad in src, False)
    check("bridge asks Compat, not C_AddOns directly",
          "C_AddOns" in src, False)
    check("embedded check names MelloUI.Restock", "MelloUI" in src and "Restock" in src, True)


def main():
    test_label()
    test_embedded_field()
    test_embedded_getmodule()
    test_getmodule_guarded()
    test_requires_mello_addon()
    test_classic_isaddonloaded()
    test_legacy_fallback()
    test_live_list_readonly()
    test_no_guid_does_not_borrow_an_alt()
    test_source_stays_in_memory()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print(f"{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
