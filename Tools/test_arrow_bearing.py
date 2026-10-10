#!/usr/bin/env python3
"""Arrow bearing matches GetPlayerFacing, which is counter-clockwise from north.

The old atan2(dx, -dy) was clockwise, so a spot to the east drew the arrow
west. Facing is GetPlayerFacing or the direction of a real step. The minimap
rotation is not a substitute, and a nil facing hides the arrow.
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
        MINIMAP_FACING_CALLS = 0
        Minimap = {
            GetFacing = function()
                MINIMAP_FACING_CALLS = MINIMAP_FACING_CALLS + 1
                return 1.23
            end,
        }
        PX, PY = 0.50, 0.50
        FACING = 0
        NOW = 1000
        function GetPlayerFacing() return FACING end
        function GetTime() return NOW end
        C_Map = {
            GetBestMapForUnit = function() return 84 end,
            GetPlayerMapPosition = function()
                return { GetXY = function() return PX, PY end }
            end,
            GetMapInfo = function() return nil end,
        }
        ToonAge = { modules = {}, LOG = { OUTPUT = 0, INFO = 3 } }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        function ToonAge:GetModule() return nil end
        function ToonAge:Raw() end
        function ToonAge:Print() end
    """)
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
    """)
    return lua


def g(lua, name):
    return lua.eval(name)


def check_source(rel, label):
    src = read(rel)
    stripped = src.replace("GetPlayerFacing", "")
    check(f"{label} does not read the minimap facing", "GetFacing" not in stripped)
    check(f"{label} bearing is counter-clockwise", "math.atan2(-(dx or 0), -(dy or 0))" in src)
    check(f"{label} no longer uses the clockwise bearing", "math.atan2(dx, -dy)" not in src)
    check(f"{label} movement fallback is not clockwise", "math.atan2(mdx, -mdy)" not in src)


def check_cardinals(rel, label):
    lua = load(rel)
    b = lua.eval("ToonAge.modules.Arrow.Bearing")
    check(f"{label} north is 0", near(b(0, -1), 0))
    check(f"{label} west is +pi/2", near(b(-1, 0), PI / 2))
    check(f"{label} south is pi", near(b(0, 1), PI))
    check(f"{label} east is -pi/2", near(b(1, 0), -PI / 2))


def check_tick(rel, label):
    lua = load(rel)
    place = lua.eval("Place")
    go = lua.eval("Go")
    # Facing north. East and west must turn opposite ways, not the same way.
    place(0.50, 0.50, 0, 1000)
    go(0.60, 0.50)
    check(f"{label} an eastern spot turns the arrow east",
          near(g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot"), -PI / 2))
    check(f"{label} an eastern spot shows the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), True)
    place(0.50, 0.50, 0, 1001)
    go(0.40, 0.50)
    check(f"{label} a western spot turns the arrow west",
          near(g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot"), PI / 2))

    # Face north, run north. The arrow stays aimed at the top and the yards fall.
    lua = load(rel)
    place = lua.eval("Place")
    go = lua.eval("Go")
    place(0.50, 0.50, 0, 2000)
    go(0.50, 0.30)
    far = g(lua, "ToonAge.modules.Arrow.frame.distF.text")
    rot_far = g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot")
    place(0.50, 0.40, 0, 2001)
    go(0.50, 0.30)
    near_yd = g(lua, "ToonAge.modules.Arrow.frame.distF.text")
    rot_near = g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot")
    check(f"{label} running north keeps the arrow aimed up",
          near(rot_far, 0) and near(rot_near, 0))
    check(f"{label} running north drops the yards",
          far == "400 yds" and near_yd == "200 yds")

    # No player facing and no step yet: hide. The minimap must not fill in.
    lua = load(rel)
    lua.execute("FACING = nil")
    lua.eval("Go")(0.60, 0.50)
    check(f"{label} a nil facing hides the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), False)
    check(f"{label} a nil facing does not ask the minimap",
          g(lua, "MINIMAP_FACING_CALLS"), 0)

    # Step east toward an eastern mark. The arrow points up (you are facing it).
    lua.execute("PX, PY, NOW = 0.50, 0.50, 3000")
    lua.eval("Go")(0.70, 0.50)
    lua.execute("PX, NOW = 0.55, 3001")
    lua.eval("Go")(0.70, 0.50)
    check(f"{label} a step east is a counter-clockwise facing",
          near(g(lua, "ToonAge.modules.Arrow.frame.arrowTex.rot"), 0))
    check(f"{label} a step east shows the arrow",
          g(lua, "ToonAge.modules.Arrow.frame.arrowTex.shown"), True)
    check(f"{label} movement fallback does not ask the minimap",
          g(lua, "MINIMAP_FACING_CALLS"), 0)

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
