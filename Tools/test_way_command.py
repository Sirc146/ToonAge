#!/usr/bin/env python3
"""/ta way, bare /way, and /ta talentsync.

Players type coordinates on a 0-100 scale. The arrow stores 0-1. A zone name
or a mapID may precede the pair, and a label may follow it. Bare /way is
registered only when TomTom is not loaded and nobody else already owns the
command. /ta talentsync calls Data/Retail/Talents.lua SyncFromBetterTalents.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def near(got, want):
    return got is not None and abs(float(got) - want) < 0.0001


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


BOOT = r"""
_lines = {}
ToonAge = {
    modules = {},
    LOG = { OUTPUT = 0, INFO = 3, DEBUG = 4 },
    Utils = {},
    Data = {},
    TalentsAPI = {},
}
function ToonAge:RegisterModule(name, mod)
    self.modules[name] = mod
    self[name] = mod
end
function ToonAge:RegisterEvent() end
function ToonAge:Raw(_, msg) _lines[#_lines + 1] = tostring(msg) end
function ToonAge:Print(_, _, msg) _lines[#_lines + 1] = tostring(msg) end
SlashCmdList = {}
C_Map = {
    GetBestMapForUnit = function() return 84 end,
    GetMapInfo = function(id)
        if id == 84 then return { name = "Stormwind City", mapType = 3 } end
        if id == 14 then return { name = "Arathi Highlands", mapType = 3 } end
        if id == 2372 then return { name = "Arathi Highlands", mapType = 3 } end
        return nil
    end,
}
function Way(args)
    _lines = {}
    local A = ToonAge.modules.Arrow
    A:ClearWaypoint()
    A.SlashCommands.way(A, args)
    local wp = A.manualWaypoint
    WAY_MAP = wp and wp.map or nil
    WAY_X = wp and wp.x or nil
    WAY_Y = wp and wp.y or nil
    WAY_TITLE = wp and wp.title or nil
    WAY_TEXT = table.concat(_lines, "\n")
end
function BootArrow()
    local A = ToonAge.modules.Arrow
    A.InitFrame = function() end
    A:Init()
end
"""


def load_arrow(rel):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read(rel))
    return lua


def g(lua, name):
    return lua.eval(name)


def check_arrow(rel, label):
    lua = load_arrow(rel)
    check(f"{label} registers way", g(lua, "type(ToonAge.modules.Arrow.SlashCommands.way)"), "function")

    lua.execute('Way("45.2 67.8 My Place")')
    check(f"{label} current map", g(lua, "WAY_MAP"), 84)
    check(f"{label} x is divided by 100", near(g(lua, "WAY_X"), 0.452))
    check(f"{label} y is divided by 100", near(g(lua, "WAY_Y"), 0.678))
    check(f"{label} label is kept", g(lua, "WAY_TITLE"), "My Place")

    lua.execute('Way("45,2 67,8")')
    check(f"{label} comma decimals divide by 100", near(g(lua, "WAY_X"), 0.452) and near(g(lua, "WAY_Y"), 0.678))

    lua.execute('Way("2393 10 20 My Spot")')
    check(f"{label} mapID is accepted", g(lua, "WAY_MAP"), 2393)
    check(f"{label} mapID x is divided by 100", near(g(lua, "WAY_X"), 0.10))
    check(f"{label} mapID y is divided by 100", near(g(lua, "WAY_Y"), 0.20))
    check(f"{label} mapID label is kept", g(lua, "WAY_TITLE"), "My Spot")

    lua.execute('Way("Stormwind City 12.5 34 The Bank")')
    check(f"{label} zone name resolves", g(lua, "WAY_MAP"), 84)
    check(f"{label} zone x is divided by 100", near(g(lua, "WAY_X"), 0.125))
    check(f"{label} zone y is divided by 100", near(g(lua, "WAY_Y"), 0.34))
    check(f"{label} zone label is kept", g(lua, "WAY_TITLE"), "The Bank")

    lua.execute('Way("Nopeville 10 20")')
    check(f"{label} unknown zone sets nothing", g(lua, "WAY_MAP") is None)
    check(f"{label} unknown zone is reported", "Unknown zone: Nopeville" in g(lua, "WAY_TEXT"))

    lua.execute("BootArrow()")
    check(f"{label} bare /way is registered", g(lua, "SLASH_TOONAGEWAY1"), "/way")
    lua.execute('ToonAge.modules.Arrow:ClearWaypoint(); SlashCmdList.TOONAGEWAY("10 20 Bare")')
    wp = g(lua, "ToonAge.modules.Arrow.manualWaypoint")
    check(f"{label} bare /way divides by 100",
          wp is not None and wp.map == 84 and near(wp.x, 0.10) and near(wp.y, 0.20) and wp.title == "Bare")

    claimed = load_arrow(rel)
    claimed.execute(r"""
        C_AddOns = { IsAddOnLoaded = function(name) return name == "TomTom" end }
        BootArrow()
        TOMTOM_STILL = SLASH_TOONAGEWAY1
        TOMTOM_HANDLER = SlashCmdList.TOONAGEWAY
    """)
    check(f"{label} C_AddOns.IsAddOnLoaded blocks /way", g(claimed, "TOMTOM_STILL") is None)
    check(f"{label} TomTom leaves no ToonAge handler", g(claimed, "TOMTOM_HANDLER") is None)

    classic = load_arrow(rel)
    classic.execute(r"""
        C_AddOns = nil
        IsAddOnLoaded = function(name) return name == "TomTom" end
        BootArrow()
        CLASSIC_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} IsAddOnLoaded blocks /way", g(classic, "CLASSIC_WAY") is None)

    thrown = load_arrow(rel)
    thrown.execute(r"""
        C_AddOns = { IsAddOnLoaded = function() error("missing") end }
        IsAddOnLoaded = function(name) return name == "TomTom" end
        BootArrow()
        THROWN_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} a throwing C_AddOns check still honors IsAddOnLoaded", g(thrown, "THROWN_WAY") is None)

    foreign = load_arrow(rel)
    foreign.execute(r"""
        SLASH_TOMTOMWAY1 = "/way"
        SlashCmdList.TOMTOM_WAY = function() end
        BootArrow()
        FOREIGN_OURS = SLASH_TOONAGEWAY1
        FOREIGN_THEIRS = SlashCmdList.TOMTOM_WAY
    """)
    check(f"{label} an existing /way is not replaced", g(foreign, "FOREIGN_OURS") is None)
    check(f"{label} the other handler is left in place", g(foreign, "type(FOREIGN_THEIRS)"), "function")

    later = load_arrow(rel)
    later.execute(r"""
        BootArrow()
        C_AddOns = { IsAddOnLoaded = function(name) return name == "TomTom" end }
        SLASH_TOMTOMWAY1 = "/way"
        ToonAge.modules.Arrow:RegisterBareWay()
        LATER_OURS = SLASH_TOONAGEWAY1
        LATER_THEIRS = SLASH_TOMTOMWAY1
    """)
    check(f"{label} drops /way once TomTom is loaded", g(later, "LATER_OURS") is None)
    check(f"{label} TomTom's /way stays", g(later, "LATER_THEIRS"), "/way")


def check_talents():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read("Data/Retail/Talents.lua"))
    lua.execute(read("Modules/Character/Talents.lua"))
    lua.execute(r"""
        local T = ToonAge.Data.Talents
        local spec = T:GetBySpecID(265)
        spec.builds.mplus.string = "KEEP"
        BetterTalents = {
            BuildData = {
                Affliction = { mplus_overall = "NEW", raid_mythic = "RAIDSTR" },
            },
        }
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        MPLUS = spec.builds.mplus.string
        RAID = spec.builds.raid.string
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        SECOND = table.concat(_lines, "\n")
        MPLUS2 = spec.builds.mplus.string
        RAID2 = spec.builds.raid.string
        BetterTalents = nil
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        MISSING = table.concat(_lines, "\n")
    """)
    check("talentsync keeps a pasted string", g(lua, "MPLUS"), "KEEP")
    check("talentsync fills an empty raid string", g(lua, "RAID"), "RAIDSTR")
    check("a second talentsync does not overwrite",
          g(lua, "MPLUS2") == "KEEP" and g(lua, "RAID2") == "RAIDSTR")
    check("a second talentsync says nothing new was filled",
          "No empty build slots were filled." in g(lua, "SECOND"))
    check("talentsync without BetterTalents explains itself",
          "BetterTalents is not loaded" in g(lua, "MISSING"))
    check("the data comment points at /ta talentsync",
          "/ta talentsync" in read("Data/Retail/Talents.lua"))


def main():
    check_arrow("Modules/Navigation/Arrow.lua", "retail")
    check_arrow("Modules/Mists/Arrow.lua", "mists")
    check_talents()
    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
