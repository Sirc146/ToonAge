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

    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
