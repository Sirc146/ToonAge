#!/usr/bin/env python3
"""Forever pins: the arrow and map pins ship on the Camelot TOC only.

Waypoint and supertrack calls stay behind type() and pcall. Library
coordinates are the Icy Veins points. Every auction-house coordinate in
the pin table carries a source URL. No MelloUI path is referenced.
"""
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
_results = []


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if not ok or "-v" in sys.argv:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def listed(toc_name):
    out = []
    for ln in read(toc_name).splitlines():
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        token = s.split("[")[0].strip().replace("\\", "/")
        if token.lower().endswith((".lua", ".xml")):
            out.append(token)
    return out


def code_only(text):
    text = re.sub(r"--.*$", "", text, flags=re.M)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def main():
    camelot = listed("ToonAge_Camelot.toc")
    check("Camelot lists Arrow.lua", "Modules/Navigation/Arrow.lua" in camelot, True)
    check("Camelot lists MapPins.lua", "Modules/Navigation/MapPins.lua" in camelot, True)
    check("Camelot lists Pins.lua", "Modules/Forever/Pins.lua" in camelot, True)

    mainline = read("ToonAge_Mainline.toc")
    check("Mainline does not list Forever pins", "Modules/Forever/Pins.lua" not in mainline, True)
    check("Mainline does not claim interface 16001", "16001" not in mainline, True)
    for toc in ("ToonAge.toc", "ToonAge_TBC.toc", "ToonAge_Mists.toc",
                "ToonAge_Vanilla.toc", "ToonAge_Cata.toc", "ToonAge_Wrath.toc"):
        body = read(toc)
        check(f"{toc} does not list Forever pins", "Modules/Forever/Pins.lua" not in body, True)

    names = (
        "SetUserWaypoint",
        "CanSetUserWaypointOnMap",
        "SetSuperTrackedUserWaypoint",
    )
    for rel in camelot:
        if not rel.endswith(".lua"):
            continue
        raw = read(rel)
        code = code_only(raw)
        lines = code.splitlines()
        for name in names:
            for i, line in enumerate(lines):
                if name not in line:
                    continue
                window = "\n".join(lines[max(0, i - 8):i + 6])
                check(f"{rel}:{i + 1} {name} is behind type()", "type(" in window, True)
                check(f"{rel}:{i + 1} {name} is inside pcall", "pcall" in window, True)

    pins = read("Modules/Forever/Pins.lua")
    check("library Horde x", "x = 73.7" in pins, True)
    check("library Horde y", "y = 33.1" in pins, True)
    check("library Alliance x", "x = 49.0" in pins, True)
    check("library Alliance y", "y = 86.5" in pins, True)
    check("Owen id is the Icy Veins id", "npcID = 211022" in pins, True)
    check("Garion id is the Icy Veins id", "npcID = 211033" in pins, True)

    # Every coordinate entry in the pin file cites an http source in the
    # same table. A block is the text between braces.
    blocks = re.findall(r"\{[^{}]*\}", pins)
    coord_blocks = [b for b in blocks if re.search(r"\bx\s*=", b) and re.search(r"\by\s*=", b)]
    check("coordinate blocks exist", len(coord_blocks) >= 8, True)
    missing = [b.strip().splitlines()[0] for b in coord_blocks if 'source = "http' not in b]
    check("every coordinate block cites a source", missing, [])

    check("TomTom is asked only when loaded", "TomTomLoaded" in pins, True)
    check("TomTom AddWaypoint is type-checked", "type(TomTom.AddWaypoint)" in pins, True)
    check("TomTom AddWaypoint is inside pcall", "pcall(TomTom.AddWaypoint" in pins, True)

    for rel in ("Modules/Forever/Pins.lua", "Modules/Navigation/Arrow.lua",
                "Modules/Navigation/MapPins.lua", "Core/Compat/API.lua",
                "ToonAge_Camelot.toc"):
        check(f"no MelloUI path in {rel}", "MelloUI" not in read(rel), True)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, LOG = { OUTPUT = 0, INFO = 3 } }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        function ToonAge:GetModule() return nil end
        function ToonAge:GetRegisteredModule() return nil end
        function ToonAge:HasAPI() return true end
        function ToonAge:Print() end
        function ToonAge:Raw() end
        ToonAge.Utils = {}
    """)
    lua.execute(read("Modules/Forever/Pins.lua"))
    cap = lua.eval("ToonAge.modules.ForeverPins.BeamCaption")
    check("caption with a known speed", cap(717, 717 / 120), "717 yd · about 2 min")
    check("caption omits ETA when speed is unknown", cap(717, None), "717 yd")
    check("caption omits ETA when standing", cap(40, 0), "40 yd")
    needs = lua.eval("ToonAge.modules.ForeverPins.NeedsFeathers")
    check("zero feathers is short of the target", needs(0, 1), True)
    check("one feather is not short of one", needs(1, 1), False)
    check("an unread count is not short", needs(None, 1), False)
    nearest = lua.eval("ToonAge.modules.ForeverPins.NearestIndex")
    origin = lua.eval("{ north = 0, west = 0, cont = 1 }")
    points = lua.eval("{ { north = 10, west = 0, cont = 1 }, { north = 3, west = 0, cont = 1 }, { cont = 2, north = 1, west = 0 } }")
    check("nearest index skips another continent", nearest(origin, points), 2)

    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(r"""
        CALLS = {}
        C_Map = {}
        C_SuperTrack = {}
        UiMapPoint = nil
    """)
    tried = lua.eval("ToonAge.Compat.TryUserWaypoint(84, 0.5, 0.5)")
    check("missing waypoint function does not throw", tried, False)

    lua.execute(r"""
        C_Map.SetUserWaypoint = function() CALLS[#CALLS + 1] = "set" end
        C_Map.CanSetUserWaypointOnMap = function() return false end
        C_SuperTrack.SetSuperTrackedUserWaypoint = function() CALLS[#CALLS + 1] = "track" end
        UiMapPoint = { CreateFromCoordinates = function() return { ok = true } end }
    """)
    blocked = lua.eval("ToonAge.Compat.TryUserWaypoint(84, 0.5, 0.5)")
    check("CanSet false skips SetUserWaypoint", blocked, False)
    check("CanSet false made no set call", lua.eval("#CALLS"), 0)

    lua.execute("C_Map.CanSetUserWaypointOnMap = function() return true end")
    placed = lua.eval("ToonAge.Compat.TryUserWaypoint(84, 0.49, 0.86)")
    check("present waypoint calls succeed", placed, True)
    check("supertrack ran after the waypoint", lua.eval("CALLS[1]"), "set")
    check("supertrack was the second call", lua.eval("CALLS[2]"), "track")

    lua.execute(r"""
        C_Item = { GetItemCount = function() error("no") end }
        C_Container = { GetItemCount = function() return 0 end }
        GetItemCount = function() return 9 end
    """)
    check("item count falls through a throwing C_Item", lua.eval("ToonAge.Compat.CountItem(17056)"), 0)

    # Owen Thadd's pin is drawn from the stored target, not from the player
    # and not from a nil coordinate (canvas center) or a 0x0 canvas (origin).
    lua.execute(read("Modules/Navigation/MapPins.lua"))
    lua.execute(r"""
        ToonAge.flavor = "forever"
        local Arrow = {
            manualWaypoint = {
                map = 1458, zone = "Undercity",
                x = 73.7 / 100, y = 33.1 / 100,
                title = "Owen Thadd",
            },
        }
        function ToonAge:GetModule(name)
            if name == "Arrow" then return Arrow end
            return nil
        end
        CANVAS = { w = 1000, h = 800 }
        function CANVAS:GetWidth() return self.w end
        function CANVAS:GetHeight() return self.h end
        POINT = {}
        local pin = {}
        function pin:ClearAllPoints()
            POINT.x, POINT.y = nil, nil
        end
        function pin:SetPoint(point, rel, relPoint, x, y)
            POINT.point = point
            POINT.rel = rel
            POINT.relPoint = relPoint
            POINT.x = x
            POINT.y = y
        end
        function pin:GetMap()
            return { GetCanvas = function() return CANVAS end }
        end
        -- Forever's ApplyCurrentPosition: a missing coordinate is the canvas
        -- center, and a zero size is offset 0 (the canvas TOPLEFT).
        function pin:SetPosition(x, y)
            local w, h = CANVAS:GetWidth(), CANVAS:GetHeight()
            self:SetPoint("CENTER", CANVAS, "TOPLEFT", (x or 0.5) * (w or 0), -((y or 0.5) * (h or 0)))
        end
        local map = { playerX = 0.214, playerY = 0.482 }
        function map:GetMapID() return 1458 end
        function map:GetCanvas() return CANVAS end
        function map:AcquirePin()
            -- Dropped coordinates. The canvas formula then anchors at the
            -- center, or at 0,0 when the canvas has no size.
            pin:SetPosition(nil, nil)
            return pin
        end
        local DP = ToonAge.modules.MapPins.DataProvider
        function DP:GetMap() return map end
        PLACED = DP:PlaceForeverPin()
        OWEN_X = POINT.x
        OWEN_Y = POINT.y
        OWEN_POINT = POINT.point
        OWEN_REL = POINT.relPoint
        PLAYER_X = map.playerX * CANVAS.w
        PLAYER_Y = -(map.playerY * CANVAS.h)
    """)
    def near(v):
        return round(v, 4) if isinstance(v, float) else v

    ox = lua.eval("OWEN_X")
    oy = lua.eval("OWEN_Y")
    px = lua.eval("PLAYER_X")
    py = lua.eval("PLAYER_Y")
    check("library pin was placed", lua.eval("PLACED"), True)
    check("Owen anchor is the target x, not the player", near(ox), round(73.7 / 100 * 1000, 4))
    check("Owen anchor is the target y, not the player", near(oy), round(-(33.1 / 100 * 800), 4))
    check("Owen anchor is not the player arrow", (near(ox), near(oy)) != (near(px), near(py)), True)
    check("Owen anchor is not the canvas center", (round(ox, 4), round(oy, 4)) != (500.0, -400.0), True)
    check("Owen anchor is not the canvas origin", (round(ox, 4), round(oy, 4)) != (0.0, 0.0), True)
    check("pin point is the canvas top-left", (lua.eval("OWEN_POINT"), lua.eval("OWEN_REL")), ("CENTER", "TOPLEFT"))

    lua.execute(r"""
        CANVAS.w, CANVAS.h = 0, 0
        POINT.x, POINT.y = nil, nil
        local DP = ToonAge.modules.MapPins.DataProvider
        DP:PlaceForeverPin()
        ZERO_X, ZERO_Y = POINT.x, POINT.y
        CANVAS.w, CANVAS.h = 1000, 800
        local again = DP.OnCanvasSizeChanged and DP:OnCanvasSizeChanged()
        SIZED_X, SIZED_Y = POINT.x, POINT.y
    """)
    zx, zy = lua.eval("ZERO_X"), lua.eval("ZERO_Y")
    check("a 0x0 canvas does not anchor at the origin", (zx, zy) != (0, 0), True)
    sx, sy = lua.eval("SIZED_X"), lua.eval("SIZED_Y")
    check("size change puts Owen on the target x", near(sx), round(73.7 / 100 * 1000, 4))
    check("size change puts Owen on the target y", near(sy), round(-(33.1 / 100 * 800), 4))

    # Cross-continent beam, nearest library, and clear. The map pin test above
    # does not cover the screen beam.
    lua.execute(read("Modules/Navigation/Arrow.lua"))
    lua.execute(r"""
        local function info(id)
            local rows = {
                [1] = { mapType = 2, parentMapID = 0, name = "Kalimdor" },
                [2] = { mapType = 2, parentMapID = 0, name = "Eastern Kingdoms" },
                [10] = { mapType = 3, parentMapID = 1, name = "The Barrens" },
                [20] = { mapType = 3, parentMapID = 2, name = "Undercity" },
                [11] = { mapType = 3, parentMapID = 1, name = "Orgrimmar" },
                [30] = { mapType = 4, parentMapID = 1, name = "Ragefire Chasm" },
            }
            return rows[id]
        end
        local A = ToonAge.modules.Arrow
        REL_OTHER = A.ContinentRelation(10, 20, info)
        REL_SAME = A.ContinentRelation(10, 11, info)
        REL_INST = A.ContinentRelation(10, 30, info)
        DRAW_OTHER = A.ShouldDrawMarker(REL_OTHER)
        DRAW_SAME = A.ShouldDrawMarker(REL_SAME)
        NOTICE = A.OtherContinentText("Undercity")
        local y0, b0 = A.WorldBearing(0, 0, 0, 100)
        local y1, b1 = A.WorldBearing(40, 0, 0, 100)
        BEAR_Y0, BEAR_B0, BEAR_Y1 = y0, b0, y1
        AUTO_IN = A.ShouldAutoClear(true, 8, A.CLEAR_ON_ARRIVAL_YARDS)
        AUTO_OUT = A.ShouldAutoClear(true, 9, A.CLEAR_ON_ARRIVAL_YARDS)
        AUTO_OTHER = A.ShouldAutoClear(false, 1, A.CLEAR_ON_ARRIVAL_YARDS)
        AUTO_NIL = A.ShouldAutoClear(true, nil, A.CLEAR_ON_ARRIVAL_YARDS)

        local P = ToonAge.modules.ForeverPins
        local owen = P.LIBRARIES.Horde
        local wabang = P.AUCTION.Horde[1]
        local function contOf(place)
            if place.zone == "Orgrimmar" then return 1 end
            if place.zone == "Undercity" then return 2 end
            return nil
        end
        local function worldOf(place)
            if place.zone == "Orgrimmar" then return { cont = 1, north = 10, west = 0 } end
            return { cont = 1, north = 400, west = 0 }
        end
        local origin = { cont = 1, north = 0, west = 0 }
        ONE = P.ChooseLibrary({ owen }, 1, contOf, origin, worldOf)
        NEAR = P.ChooseLibrary({ owen, wabang }, 1, contOf, origin, worldOf)
        local function bothKalimdor(place)
            return 1
        end
        NEAREST = P.ChooseLibrary(
            { { name = "Far", zone = "Undercity", x = owen.x, y = owen.y },
              { name = "Near", zone = "Orgrimmar", x = wabang.x, y = wabang.y } },
            1, bothKalimdor, origin, worldOf)

        REMOVED, CLEARED_UW = nil, false
        TomTom = { RemoveWaypoint = function(_, uid) REMOVED = uid end }
        ToonAge.Compat = ToonAge.Compat or {}
        function ToonAge.Compat.ClearUserWaypoint() CLEARED_UW = true return true end
        ToonAge.charDB = { arrow = { waypoint = { map = 20 }, visible = true, manualWaypoint = { x = 1 } }, activeWaypoint = { map = 20 } }
        ToonAge.LOG = ToonAge.LOG or { OUTPUT = 0 }
        function ToonAge:Raw() end
        function ToonAge:GetModule(name)
            if name == "Arrow" then return A end
            if name == "MapPins" then return { Refresh = function() end } end
            return nil
        end
        A.manualWaypoint = { map = 20, x = 0.737, y = 0.331, title = "Owen Thadd", zone = "Undercity" }
        A._tomtomUid = "only-ours"
        A._userWaypointSet = true
        A.frame = {
            hidden = false,
            Hide = function(self) self.hidden = true end,
            beamTex = { hidden = false, Hide = function(self) self.hidden = true end },
            menu = { Hide = function() end },
        }
        A:ClearActiveWaypoint("button")
        GONE = A.manualWaypoint
        FRAME_HIDDEN = A.frame.hidden
        BEAM_HIDDEN = A.frame.beamTex.hidden
        SAVED = ToonAge.charDB.arrow.waypoint
        SAVED_MANUAL = ToonAge.charDB.arrow.manualWaypoint
        SAVED_ACTIVE = ToonAge.charDB.activeWaypoint
        SAVED_VISIBLE = ToonAge.charDB.arrow.visible
    """)
    Arel = lua.eval("REL_OTHER")
    check("Barrens to Undercity is another continent", Arel, "other")
    check("another continent hides the marker", lua.eval("DRAW_OTHER"), False)
    check("Barrens to Orgrimmar is the same continent", lua.eval("REL_SAME"), "same")
    check("the same continent draws the marker", lua.eval("DRAW_SAME"), True)
    check("an instance hides the marker", lua.eval("ToonAge.modules.Arrow.ShouldDrawMarker(REL_INST)"), False)
    check("other continent notice names the zone", lua.eval("NOTICE"), "Other continent: Undercity")
    check("bearing is east of the player", round(lua.eval("BEAR_B0"), 4), round(3.141592653589793 / 2, 4))
    check("moving the player changes the distance", lua.eval("BEAR_Y0") != lua.eval("BEAR_Y1"), True)
    check("inside the arrival radius clears", lua.eval("AUTO_IN"), True)
    check("outside the arrival radius stays", lua.eval("AUTO_OUT"), False)
    check("another map does not auto-clear", lua.eval("AUTO_OTHER"), False)
    check("a missing distance does not auto-clear", lua.eval("AUTO_NIL"), False)
    check("one library stays that library", lua.eval("ONE.name"), "Owen Thadd")
    check("nearest on this continent is Orgrimmar", lua.eval("NEAR.zone"), "Orgrimmar")
    check("two on one continent picks the nearer", lua.eval("NEAREST.name"), "Near")
    check("clear removes the waypoint", lua.eval("GONE"), None)
    check("clear removes only our TomTom pin", lua.eval("REMOVED"), "only-ours")
    check("clear removes the user waypoint we set", lua.eval("CLEARED_UW"), True)
    check("clear hides the arrow frame", lua.eval("FRAME_HIDDEN"), True)
    check("clear hides the beam", lua.eval("BEAM_HIDDEN"), True)
    check("clear drops the saved waypoint", lua.eval("SAVED"), None)
    check("clear drops the saved manual waypoint", lua.eval("SAVED_MANUAL"), None)
    check("clear drops the saved active waypoint", lua.eval("SAVED_ACTIVE"), None)
    check("clear does not leave the arrow visible", lua.eval("SAVED_VISIBLE"), False)

    # /way clear. Forever keeps the pinned clear. Retail matches the clear
    # from before that pin work: manual waypoint only, arrow stays up.
    lua.execute(r"""
        local A = ToonAge.modules.Arrow
        CLEARED_UW = false
        REMOVED = nil
        _lines = {}
        function ToonAge:Raw(_, msg) _lines[#_lines + 1] = tostring(msg) end
        REFRESHED = 0
        function ToonAge:GetModule(name)
            if name == "MapPins" then
                return { Refresh = function() REFRESHED = REFRESHED + 1 end }
            end
            return nil
        end
        ToonAge.IsForever = true
        ToonAge.flavor = "forever"
        FOREVER_GATE = A.OnForeverProfile()
        ToonAge.charDB = { arrow = { waypoint = { map = 20 }, visible = true, manualWaypoint = { x = 1 } }, activeWaypoint = { map = 20 } }
        ToonAge.db = { waypoint = { map = 20 } }
        A.manualWaypoint = { map = 20, x = 0.737, y = 0.331, title = "Owen Thadd" }
        A._arrived = true
        A._arrivedTime = 3
        A._tomtomUid = "cmd-ours"
        A._userWaypointSet = true
        A.frame = {
            hidden = false,
            Hide = function(self) self.hidden = true end,
            beamTex = { hidden = false, Hide = function(self) self.hidden = true end },
            menu = { Hide = function() end },
        }
        A:ParseWayCommand("clear")
        F_GONE = A.manualWaypoint
        F_FRAME = A.frame.hidden
        F_SAVED = ToonAge.charDB.arrow.waypoint
        F_VIS = ToonAge.charDB.arrow.visible
        F_DB = ToonAge.db.waypoint
        F_UW = CLEARED_UW
        F_TOM = REMOVED
        F_MSG = table.concat(_lines, "\n")
        F_REF = REFRESHED

        ToonAge.IsForever = true
        ToonAge.flavor = nil
        ISO_GATE = A.OnForeverProfile()
        CLEARED_UW = false
        _lines = {}
        ToonAge.charDB = { arrow = { waypoint = { map = 11 }, visible = true } }
        ToonAge.db = {}
        A.manualWaypoint = { map = 11, x = 0.2, y = 0.3 }
        A._userWaypointSet = false
        A._tomtomUid = nil
        A.frame.hidden = false
        A:ParseWayCommand("clear")
        ISO_GONE = A.manualWaypoint
        ISO_FRAME = A.frame.hidden
        ISO_SAVED = ToonAge.charDB.arrow.waypoint
        ISO_MSG = table.concat(_lines, "\n")

        ToonAge.IsForever = false
        ToonAge.flavor = "retail"
        ToonAge.profile = nil
        RETAIL_GATE = A.OnForeverProfile()
        CLEARED_UW = false
        REMOVED = nil
        _lines = {}
        REFRESHED = 0
        ToonAge.charDB = {
            arrow = { waypoint = { map = 84 }, visible = true, manualWaypoint = { x = 1 } },
            activeWaypoint = { map = 84 },
        }
        ToonAge.db = { waypoint = { map = 84 }, arrow = { waypoint = { map = 84 } } }
        A.manualWaypoint = { map = 84, x = 0.45, y = 0.67, title = "Bank" }
        A._arrived = true
        A._arrivedTime = 9
        A._otherSaid = "keep"
        A._tomtomUid = "retail-pin"
        A._userWaypointSet = true
        A.frame = {
            hidden = false,
            Hide = function(self) self.hidden = true end,
            beamTex = { hidden = false, Hide = function(self) self.hidden = true end },
            menu = { hidden = false, Hide = function(self) self.hidden = true end },
        }
        A:ParseWayCommand("clear")
        R_GONE = A.manualWaypoint
        R_ARRIVED = A._arrived
        R_TIME = A._arrivedTime
        R_OTHER = A._otherSaid
        R_FRAME = A.frame.hidden
        R_BEAM = A.frame.beamTex.hidden
        R_MENU = A.frame.menu.hidden
        R_SAVED_MAP = ToonAge.charDB.arrow.waypoint and ToonAge.charDB.arrow.waypoint.map
        R_MANUAL_X = ToonAge.charDB.arrow.manualWaypoint and ToonAge.charDB.arrow.manualWaypoint.x
        R_ACTIVE_MAP = ToonAge.charDB.activeWaypoint and ToonAge.charDB.activeWaypoint.map
        R_VIS = ToonAge.charDB.arrow.visible
        R_DB_MAP = ToonAge.db.waypoint and ToonAge.db.waypoint.map
        R_DB_ARROW_MAP = ToonAge.db.arrow.waypoint and ToonAge.db.arrow.waypoint.map
        R_UW = CLEARED_UW
        R_TOM = REMOVED
        R_UID = A._tomtomUid
        R_SET = A._userWaypointSet
        R_MSG = table.concat(_lines, "\n")
        R_REF = REFRESHED
        A.manualWaypoint = { map = 84, x = 0.1, y = 0.2 }
        A.frame.hidden = false
        A:ClearActiveWaypoint("menu")
        R_MENU_GONE = A.manualWaypoint
        R_MENU_FRAME = A.frame.hidden
        R_MENU_SAVED = ToonAge.charDB.arrow.waypoint and ToonAge.charDB.arrow.waypoint.map
        ToonAge.IsForever = nil
        ToonAge.flavor = nil
        NEITHER = A.OnForeverProfile()
    """)
    check("forever profile uses the pinned clear", lua.eval("FOREVER_GATE"), True)
    check("forever /way clear removes the waypoint", lua.eval("F_GONE"), None)
    check("forever /way clear removes our TomTom pin", lua.eval("F_TOM"), "cmd-ours")
    check("forever /way clear clears the user waypoint", lua.eval("F_UW"), True)
    check("forever /way clear hides the arrow", lua.eval("F_FRAME"), True)
    check("forever /way clear drops the saved waypoint", lua.eval("F_SAVED"), None)
    check("forever /way clear drops db.waypoint", lua.eval("F_DB"), None)
    check("forever /way clear hides the saved arrow", lua.eval("F_VIS"), False)
    check("forever /way clear refreshes map pins", lua.eval("F_REF"), 1)
    check("forever /way clear says Waypoint cleared",
          lua.eval("F_MSG"), "|cFFFFD100[TA Arrow]|r Waypoint cleared.")
    check("IsForever alone uses the pinned clear", lua.eval("ISO_GATE"), True)
    check("IsForever /way clear removes the waypoint", lua.eval("ISO_GONE"), None)
    check("IsForever /way clear hides the arrow", lua.eval("ISO_FRAME"), True)
    check("IsForever /way clear drops the saved waypoint", lua.eval("ISO_SAVED"), None)
    check("IsForever /way clear says Waypoint cleared",
          lua.eval("ISO_MSG"), "|cFFFFD100[TA Arrow]|r Waypoint cleared.")
    check("retail is not the Forever profile", lua.eval("RETAIL_GATE"), False)
    check("retail /way clear removes the manual waypoint", lua.eval("R_GONE"), None)
    check("retail /way clear clears the arrived flag", lua.eval("R_ARRIVED"), False)
    check("retail /way clear clears the arrived time", lua.eval("R_TIME") is None, True)
    check("retail /way clear leaves the other-continent flag", lua.eval("R_OTHER"), "keep")
    check("retail /way clear leaves the arrow frame up", lua.eval("R_FRAME"), False)
    check("retail /way clear leaves the beam up", lua.eval("R_BEAM"), False)
    check("retail /way clear leaves the menu up", lua.eval("R_MENU"), False)
    check("retail /way clear keeps the saved waypoint", lua.eval("R_SAVED_MAP"), 84)
    check("retail /way clear keeps the saved manual waypoint", lua.eval("R_MANUAL_X"), 1)
    check("retail /way clear keeps the saved active waypoint", lua.eval("R_ACTIVE_MAP"), 84)
    check("retail /way clear leaves the arrow visible", lua.eval("R_VIS"), True)
    check("retail /way clear keeps db.waypoint", lua.eval("R_DB_MAP"), 84)
    check("retail /way clear keeps db.arrow.waypoint", lua.eval("R_DB_ARROW_MAP"), 84)
    check("retail /way clear does not clear the user waypoint", lua.eval("R_UW"), False)
    check("retail /way clear does not remove the TomTom pin", lua.eval("R_TOM") is None, True)
    check("retail /way clear keeps the TomTom uid", lua.eval("R_UID"), "retail-pin")
    check("retail /way clear keeps the user-waypoint flag", lua.eval("R_SET"), True)
    check("retail /way clear says Manual waypoint cleared",
          lua.eval("R_MSG"), "|cFFFFD100[TA Arrow]|r Manual waypoint cleared.")
    check("retail /way clear does not refresh map pins", lua.eval("R_REF"), 0)
    check("retail menu Clear removes only the manual waypoint", lua.eval("R_MENU_GONE"), None)
    check("retail menu Clear leaves the arrow up", lua.eval("R_MENU_FRAME"), False)
    check("retail menu Clear keeps the saved waypoint", lua.eval("R_MENU_SAVED"), 84)
    check("no flavor and no IsForever is not Forever", lua.eval("NEITHER"), False)

    arrow_src = read("Modules/Navigation/Arrow.lua")
    settings = read("Modules/Infrastructure/Settings.lua")
    compat = read("Core/Compat/API.lua")
    guard = compat.split("function C.ClearUserWaypoint()", 1)[1].split("\nfunction ", 1)[0]
    check("lock control is on TAWaypointArrow", 'CreateFrame("Button", "TAWaypointArrow"' in arrow_src, True)
    check("lock tooltip is Right-click: Lock / Clear menu",
          "Right-click: Lock / Clear menu" in arrow_src, True)
    check("old lock tooltip is gone from the shared arrow",
          "Right-click: Lock / Unlock" not in arrow_src, True)
    check("ClearUserWaypoint stays behind HasAPI",
          'not TA:HasAPI("C_Map.ClearUserWaypoint")' in guard, True)
    check("ClearUserWaypoint stays inside pcall",
          "pcall(C_Map.ClearUserWaypoint)" in guard, True)
    check("shared arrow does not call C_Map.ClearUserWaypoint",
          "C_Map.ClearUserWaypoint" not in arrow_src, True)
    check("Clear button label", 'fs:SetText("Clear")' in arrow_src, True)
    check("Clear menu entry", 'item("Clear"' in arrow_src, True)
    check("settings Clear waypoint button", '"Clear waypoint"' in settings, True)

    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
