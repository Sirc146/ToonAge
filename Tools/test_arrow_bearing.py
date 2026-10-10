#!/usr/bin/env python3
"""Arrow distance and bearing come from world yards, not the map fraction.

C_Map.GetWorldPosFromMapPos (through Compat) returns continentID and a
vector whose x points north and y points west, already in yards.
dN = tN - pN, dW = tW - pW, distance = sqrt(dN^2 + dW^2),
bearing = atan2(dW, dN). targetAngle = bearing - GetPlayerFacing.

A missing world API, or two different continents, hides the distance and
falls back to the map bearing atan2(-dx, -dy). A nil facing with no step
hides the arrow.
"""
import math
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

PI = math.pi


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def near(got, want, eps=1e-6):
    if got is None:
        return False
    # South is pi and -pi; both are the same direction.
    d = (float(got) - float(want) + PI) % (2 * PI) - PI
    return abs(d) < eps


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def load(rel):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        PX, PY = 0.50, 0.50
        FACING = 0
        NOW = 1000
        HAS_WORLD = true
        WORLD_FRAME = "north"
        SPLIT_X = nil
        VEC_CALLS = 0
        function GetPlayerFacing() return FACING end
        function GetTime() return NOW end
        function CreateVector2D(x, y)
            VEC_CALLS = VEC_CALLS + 1
            return { x = x, y = y }
        end
        C_Map = {
            GetBestMapForUnit = function() return 84 end,
            GetPlayerMapPosition = function()
                return { GetXY = function() return PX, PY end }
            end,
            GetMapInfo = function() return nil end,
            GetWorldPosFromMapPos = function(mapID, vec)
                local north, west
                if WORLD_FRAME == "zero" then
                    north, west = 0, -vec.x * 800
                elseif WORLD_FRAME == "swap" then
                    north, west = vec.x * 800, vec.y * 800
                else
                    north, west = -vec.y * 800, -vec.x * 800
                end
                local cont = 1
                if SPLIT_X and vec.x > SPLIT_X then cont = 2 end
                return cont, { x = north, y = west }
            end,
        }
        ToonAge = {
            modules = {},
            LOG = { OUTPUT = 0, INFO = 3 },
        }
        function ToonAge:HasAPI(name)
            if not HAS_WORLD and (name == "C_Map.GetWorldPosFromMapPos" or name == "CreateVector2D") then
                return false
            end
            return true
        end
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        function ToonAge:GetModule() return nil end
        function ToonAge:Raw() end
        function ToonAge:Print() end
    """)
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Core/Utils.lua"))
    lua.execute(read(rel))
    lua.execute(r"""
        local function Piece()
            local p = { shown = true, text = "", rot = nil }
            function p:SetTexture() end
            function p:SetSize() end
            function p:SetAlpha() end
            function p:SetRotation(a) self.rot = a end
            function p:SetVertexColor(r, g, b, a) self.r, self.g, self.b, self.a = r, g, b, a end
            function p:Show() self.shown = true end
            function p:Hide() self.shown = false end
            function p:SetText(t) self.text = t end
            function p:SetTextColor(r, g, b, a) self.r, self.g, self.b, self.a = r, g, b, a end
            function p:SetPoint() end
            function p:IsVisible() return self.shown end
            return p
        end
        function Frame()
            local f = Piece()
            f.arrowTex = Piece()
            f.greyTex = Piece()
            f.distF = Piece()
            f.etaF = Piece()
            f.titleF = Piece()
            return f
        end
        local A = ToonAge.modules.Arrow
        local f = Frame()
        A.frame = f
        function Place(x, y, facing, t)
            PX, PY, FACING, NOW = x, y, facing, t
        end
        function Go(tx, ty)
            A:SetWaypoint(84, tx, ty, "Mark")
            A:Tick(f)
        end
        function GoCoord(tx, ty)
            A:SetWaypoint(84, tx, ty)
            A:Tick(f)
        end
    """)
    return lua


def g(lua, name):
    return lua.eval(name)


def rot(lua):
    return g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot")


def dist(lua):
    return g(lua, "ToonAge.modules.Arrow.frame.distF.text")


def check_source(rel, label):
    src = read(rel)
    stripped = src.replace("GetPlayerFacing", "")
    check(f"{label} does not call the minimap facing", "GetFacing" not in stripped)
    check(f"{label} map fallback is counter-clockwise", "math.atan2(-(dx or 0), -(dy or 0))" in src)
    check(f"{label} world bearing is atan2(west, north)", "math.atan2(dW, dN)" in src)
    check(f"{label} no longer uses the clockwise bearing", "math.atan2(dx, -dy)" not in src)
    check(f"{label} movement fallback is not clockwise", "math.atan2(mdx, -mdy)" not in src)
    check(f"{label} does not guess yards from zone size", "ComputeDistance" not in src)
    check(f"{label} does not call the world API itself", "GetWorldPosFromMapPos" not in src)


def check_cardinals(rel, label):
    lua = load(rel)
    b = lua.eval("ToonAge.modules.Arrow.Bearing")
    check(f"{label} map north is 0", near(b(0, -1), 0))
    check(f"{label} map west is +pi/2", near(b(-1, 0), PI / 2))
    check(f"{label} map south is pi", near(b(0, 1), PI))
    check(f"{label} map east is -pi/2", near(b(1, 0), -PI / 2))


def check_tick(rel, label):
    lua = load(rel)
    place = lua.eval("Place")
    go = lua.eval("Go")
    # Player at map (0.5, 0.5). World yards are -mapY*800 north and -mapX*800 west,
    # so 0.125 of the map is 100 yards. Facing north.
    place(0.50, 0.50, 0, 1000)
    go(0.50, 0.375)
    check(f"{label} 100 yards north is distance 100", dist(lua), "100 yd")
    check(f"{label} 100 yards north is angle 0", near(rot(lua), 0))
    check(f"{label} world position went through CreateVector2D",
          g(lua, "VEC_CALLS") > 0)
    check(f"{label} a typed label is body text",
          near(g(lua, "ToonAge.modules.Arrow.frame.titleF.r"), 0.92, 1e-3)
          and near(g(lua, "ToonAge.modules.Arrow.frame.titleF.g"), 0.90, 1e-3)
          and near(g(lua, "ToonAge.modules.Arrow.frame.titleF.b"), 0.87, 1e-3))

    place(0.50, 0.50, 0, 1001)
    go(0.375, 0.50)
    check(f"{label} 100 yards west is +pi/2", near(rot(lua), PI / 2))
    check(f"{label} 100 yards west is distance 100", dist(lua), "100 yd")

    place(0.50, 0.50, 0, 1002)
    go(0.625, 0.50)
    check(f"{label} 100 yards east is -pi/2", near(rot(lua), -PI / 2))
    check(f"{label} 100 yards east is distance 100", dist(lua), "100 yd")
    check(f"{label} an eastern spot shows the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), True)

    place(0.50, 0.50, 0, 1003)
    go(0.50, 0.625)
    check(f"{label} 100 yards south is pi", near(rot(lua), PI))
    check(f"{label} 100 yards south is distance 100", dist(lua), "100 yd")

    place(0.50, 0.50, PI / 2, 1004)
    go(0.375, 0.50)
    check(f"{label} facing west at a western target points up", near(rot(lua), 0))

    # World north can be 0. That is a position, not a missing API.
    lua.execute('WORLD_FRAME = "zero"')
    place(0.50, 0.50, 0, 1005)
    go(0.375, 0.50)
    check(f"{label} a world north of 0 still reports 100 yards west", dist(lua), "100 yd")
    check(f"{label} a world north of 0 still points west", near(rot(lua), PI / 2))
    lua.execute('WORLD_FRAME = "north"')

    # Face north, run north. The arrow stays aimed at the top and the yards fall.
    lua = load(rel)
    place = lua.eval("Place")
    go = lua.eval("Go")
    place(0.50, 0.50, 0, 2000)
    go(0.50, 0.25)
    far = dist(lua)
    rot_far = rot(lua)
    place(0.50, 0.375, 0, 2001)
    go(0.50, 0.25)
    near_yd = dist(lua)
    rot_near = rot(lua)
    check(f"{label} running north keeps the arrow aimed up",
          near(rot_far, 0) and near(rot_near, 0))
    check(f"{label} running north drops the yards",
          far == "200 yd" and near_yd == "100 yd")

    # No player facing and no step yet: hide. Do not aim north.
    lua = load(rel)
    lua.execute("FACING = nil")
    lua.eval("Go")(0.625, 0.50)
    check(f"{label} a nil facing hides the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), False)

    # Step east toward an eastern mark. The arrow points up (you are facing it).
    lua.execute("PX, PY, NOW = 0.50, 0.50, 3000")
    lua.eval("Go")(0.70, 0.50)
    lua.execute("PX, NOW = 0.55, 3001")
    lua.eval("Go")(0.70, 0.50)
    check(f"{label} a step east is a counter-clockwise facing", near(rot(lua), 0))
    check(f"{label} a step east shows the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), True)

    # The step is read in world yards. Here map-east is world-north, and the
    # target is map-south of the new spot (world-west). Map fractions would
    # aim the other way.
    lua = load(rel)
    lua.execute("FACING = nil")
    lua.execute('WORLD_FRAME = "swap"')
    lua.execute("PX, PY, NOW = 0.50, 0.50, 3500")
    lua.eval("Go")(0.60, 0.70)
    lua.execute("PX, NOW = 0.60, 3501")
    lua.eval("Go")(0.60, 0.70)
    check(f"{label} movement fallback uses the world frame", near(rot(lua), PI / 2))

    # Walk away from the mark. The line is body-colored text, not a red code.
    lua = load(rel)
    lua.execute("FACING = 0")
    lua.execute("PX, PY, NOW = 0.50, 0.40, 4000")
    lua.eval("Go")(0.50, 0.30)
    lua.execute("PX, PY, NOW = 0.50, 0.55, 4001")
    lua.eval("Go")(0.50, 0.30)
    check(f"{label} moving away is plain body text",
          g(lua, "ToonAge.modules.Arrow.frame.etaF.text"), "moving away")
    eta_r = g(lua, "ToonAge.modules.Arrow.frame.etaF.r")
    eta_g = g(lua, "ToonAge.modules.Arrow.frame.etaF.g")
    eta_b = g(lua, "ToonAge.modules.Arrow.frame.etaF.b")
    check(f"{label} moving away uses body color",
          near(eta_r, 0.92, 1e-3) and near(eta_g, 0.90, 1e-3) and near(eta_b, 0.87, 1e-3))

    # A bare coordinate pair is body text. A typed name stays gold (above).
    lua = load(rel)
    lua.eval("Place")(0.50, 0.50, 0, 5000)
    lua.eval("GoCoord")(0.45, 0.67)
    check(f"{label} a coordinate title reads 45.00, 67.00",
          g(lua, "ToonAge.modules.Arrow.frame.titleF.text"), "45.00, 67.00")
    tr = g(lua, "ToonAge.modules.Arrow.frame.titleF.r")
    tg = g(lua, "ToonAge.modules.Arrow.frame.titleF.g")
    tb = g(lua, "ToonAge.modules.Arrow.frame.titleF.b")
    check(f"{label} a coordinate title uses body color",
          near(tr, 0.92, 1e-3) and near(tg, 0.90, 1e-3) and near(tb, 0.87, 1e-3))

    # Missing world API: hide the yards, keep the map bearing.
    lua = load(rel)
    lua.execute("HAS_WORLD = false")
    lua.eval("Place")(0.50, 0.50, 0, 6000)
    lua.eval("Go")(0.625, 0.50)
    check(f"{label} a missing world API hides the distance", dist(lua), "")
    check(f"{label} a missing world API keeps the map bearing", near(rot(lua), -PI / 2))

    # Different continents: same fallback.
    lua = load(rel)
    lua.execute("SPLIT_X = 0.55")
    lua.eval("Place")(0.50, 0.50, 0, 7000)
    lua.eval("Go")(0.625, 0.50)
    check(f"{label} a continent change hides the distance", dist(lua), "")
    check(f"{label} a continent change keeps the map bearing", near(rot(lua), -PI / 2))


def main():
    for rel, label in (
        ("Modules/Navigation/Arrow.lua", "retail"),
        ("Modules/Mists/Arrow.lua", "mists"),
    ):
        check_source(rel, label)
        check_cardinals(rel, label)
        check_tick(rel, label)
    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
