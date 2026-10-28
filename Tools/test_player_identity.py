#!/usr/bin/env python3
"""Professions sidebar identity helpers.

Forever's Professions tab draws Core/Layout.lua's CharacterSidebar. That
sidebar calls four helpers that used to exist only in Core/TBCUtils.lua, so
on every other flavor the call was nil and the panel stopped drawing.

The helpers live in Core/Utils.lua now. Game APIs are asked from
Core/Compat/API.lua, after ApiGuard. A missing answer is "" rather than nil.
GetSpecLabel reads the name GetPlayerSpec already resolved; it does not add
a Mists specialization path.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def body(src, name, nxt):
    i = src.index(f"function {name}")
    j = src.index(f"\nfunction {nxt}")
    return src[i:j]


def raw_call(src, name):
    return re.search(r"(?<![\w.])" + name + r"\s*\(", src) is not None


PRELUDE = r"""
ToonAge = { IsForever = true, modules = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:HasAPI(path) return true end

texts = {}
function MockFrame(name)
    local f = { _name = name }
    setmetatable(f, { __index = function(s, k)
        if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
        local fn = function() return s end
        rawset(s, k, fn)
        return fn
    end })
    f.GetStringHeight = function() return 12 end
    f.GetStringWidth = function() return 40 end
    f.GetWidth = function() return 202 end
    f.CreateFontString = function() return MockFrame("fs") end
    f.CreateTexture = function() return MockFrame("tex") end
    f.SetText = function(s, t)
        texts[#texts + 1] = t
        rawset(s, "_text", t)
        return s
    end
    return f
end
CreateFrame = function() return MockFrame("frame") end
UnitLevel = function() return 60 end
"""


def boot(extra=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    if extra:
        lua.execute(extra)
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Core/Utils.lua"))
    return lua


def grab(lua, expr):
    lua.execute("_answer = " + expr)
    return lua.globals()._answer


def main():
    utils = read("Core/Utils.lua")
    compat = read("Core/Compat/API.lua")
    layout = read("Core/Layout.lua")
    tbc = read("Core/TBCUtils.lua")

    name_fn = body(utils, "U.GetPlayerName", "U.GetPlayerLevel")
    class_fn = body(utils, "U.GetPlayerClassLocalized", "U.GetPlayerRace")
    race_fn = body(utils, "U.GetPlayerRace", "U.GetPlayerSpec")
    spec_fn = body(utils, "U.GetSpecLabel", "U.GetPlayerRole")

    check("name helper does not call UnitName", raw_call(name_fn, "UnitName"), False)
    check("class helper does not call UnitClass", raw_call(class_fn, "UnitClass"), False)
    check("race helper does not call UnitRace", raw_call(race_fn, "UnitRace"), False)
    check("spec label does not call GetSpecialization", "GetSpecialization" not in spec_fn, True)
    check("spec label does not call C_SpecializationInfo", "C_SpecializationInfo" not in spec_fn, True)
    check("UnitName is guarded", 'TA:HasAPI("UnitName")' in compat, True)
    check("UnitClass is guarded", 'TA:HasAPI("UnitClass")' in compat, True)
    check("UnitRace is guarded", 'TA:HasAPI("UnitRace")' in compat, True)
    check("sidebar still asks for the race", "U.GetPlayerRace()" in layout, True)
    check("TBC no longer owns the race helper", "function U.GetPlayerRace(" not in tbc, True)

    lua = boot()
    U = lua.globals().ToonAge.Utils
    check("missing name is empty", U.GetPlayerName(), "")
    check("missing class is empty", U.GetPlayerClassLocalized(), "")
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("missing race token is empty", lua.globals().raceToken, "")
    check("missing race name is empty", lua.globals().raceName, "")
    check("missing spec label is empty", U.GetSpecLabel(), "")

    lua.execute(r"""
    UnitName = function() return nil end
    UnitClass = function() return nil, nil end
    UnitRace = function() return nil, nil end
    """)
    check("nil name is empty", U.GetPlayerName(), "")
    check("nil class is empty", U.GetPlayerClassLocalized(), "")
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("nil race token is empty", lua.globals().raceToken, "")
    check("nil race name is empty", lua.globals().raceName, "")

    lua.execute(r"""
    UnitName = function() return "Sirc" end
    UnitClass = function() return "Rogue", "ROGUE" end
    UnitRace = function() return "Night Elf", "NightElf" end
    raceCalls = 0
    """)
    check("name passes through", U.GetPlayerName(), "Sirc")
    check("localized class passes through", U.GetPlayerClassLocalized(), "Rogue")
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("race token passes through", lua.globals().raceToken, "NightElf")
    check("race name passes through", lua.globals().raceName, "Night Elf")

    lua.execute(r"""
    raceCalls = 0
    UnitRace = function() raceCalls = raceCalls + 1; return "Orc", "Orc" end
    function ToonAge:HasAPI(path) return path ~= "UnitRace" end
    """)
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("guarded race token is empty", lua.globals().raceToken, "")
    check("guarded race name is empty", lua.globals().raceName, "")
    check("guarded race is not called", lua.globals().raceCalls, 0)

    lua.execute(r"""
    function ToonAge:HasAPI() return true end
    secret = {}
    issecretvalue = function(v) return v == secret end
    UnitName = function() return secret end
    UnitClass = function() return secret, secret end
    UnitRace = function() return secret, secret end
    """)
    check("secret name is empty", U.GetPlayerName(), "")
    check("secret class is empty", U.GetPlayerClassLocalized(), "")
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("secret race token is empty", lua.globals().raceToken, "")
    check("secret race name is empty", lua.globals().raceName, "")

    lua.execute(r"""
    issecretvalue = nil
    ToonAge.IsForever = false
    ToonAge.IsClassicEra = false
    ToonAge.IsTBC = false
    GetSpecialization = function() return nil end
    GetSpecializationInfo = function() return 259, "Assassination", "", 0 end
    """)
    check("mists with no spec label is empty", U.GetSpecLabel(), "")
    lua.execute("GetSpecialization = function() return 1 end")
    check("mists spec label uses the existing name", U.GetSpecLabel(), "Assassination")

    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(r"""
    UnitName = function() return "Sirc" end
    UnitClass = function() return "Rogue", "ROGUE" end
    UnitRace = function() return "Night Elf", "NightElf" end
    ToonAge.ProfessionSkills = { Collect = function() return { reader = true, cards = {} } end }
    texts = {}
    drawError = nil
    local ok, err = pcall(function()
        ToonAge.modules.ProfessionBoard:Render(MockFrame("content"), MockFrame("side"))
    end)
    if not ok then drawError = tostring(err) end
    joined = table.concat(texts, "\n")
    """)
    check("professions tab draws", lua.globals().drawError, None)
    joined = lua.globals().joined
    check("sidebar shows the name", "Sirc" in joined, True)
    check("sidebar shows the race", "Night Elf" in joined, True)
    check("sidebar shows the class", "Rogue" in joined, True)

    lua.execute(r"""
    UnitName = nil
    UnitClass = nil
    UnitRace = nil
    GetSpecialization = nil
    GetSpecializationInfo = nil
    ToonAge.IsForever = true
    texts = {}
    drawError = nil
    local ok, err = pcall(function()
        ToonAge.modules.ProfessionBoard:Render(MockFrame("content"), MockFrame("side"))
    end)
    if not ok then drawError = tostring(err) end
    """)
    check("professions tab draws with no identity APIs", lua.globals().drawError, None)

    lua.execute(r"""
    ToonAge.IsTBC = true
    ToonAge.IsForever = false
    GetNumTalentTabs = function() return 3 end
    GetTalentTabInfo = function(tab)
        local names = { "Beast Mastery", "Marksmanship", "Survival" }
        return names[tab], "icon", (tab == 1 and 7 or 0)
    end
    GetUnspentTalentPoints = function() return 1 end
    UnitClass = function() return "Hunter", "HUNTER" end
    UnitRace = function() return "Orc", "Orc" end
    """)
    lua.execute(read("Core/TBCUtils.lua"))
    label = U.GetSpecLabel()
    check("tbc spec label still reports unspent", "unspent" in str(label), True)
    lua.execute("raceToken, raceName = ToonAge.Utils.GetPlayerRace()")
    check("tbc race token still passes through", lua.globals().raceToken, "Orc")
    check("tbc race name is not nil", lua.globals().raceName, "Orc")

    passed, total = sum(_results), len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
