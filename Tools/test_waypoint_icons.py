#!/usr/bin/env python3
"""Quest waypoint arrow and gear marks (style guide §19 and §20).

The nine textures live in Media/icons/. The drawing rules live in Core/Utils.lua
so the Retail and Mists arrows, and every gear comparison, share one implementation.

Usage:  python3 Tools/test_waypoint_icons.py [-v]
"""
import os
import struct
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


ICON = os.path.join(ROOT, "Media", "icons")
NEW = [
    "util_waypoint.tga", "util_waypoint_hollow.tga", "util_waypoint_arrived.tga",
    "util_upgrade.tga", "util_upgrade_16.tga",
    "util_downgrade.tga", "util_downgrade_16.tga",
    "util_sidegrade.tga", "util_sidegrade_16.tga",
]
WANT_SIZE = {
    "util_waypoint.tga": (64, 64), "util_waypoint_hollow.tga": (64, 64),
    "util_waypoint_arrived.tga": (64, 64),
    "util_upgrade.tga": (32, 32), "util_downgrade.tga": (32, 32), "util_sidegrade.tga": (32, 32),
    "util_upgrade_16.tga": (16, 16), "util_downgrade_16.tga": (16, 16), "util_sidegrade_16.tga": (16, 16),
}

DELIVERED = {
    "tab_pets.tga": (64, 64), "tab_pets_32.tga": (32, 32),
    "tab_professions.tga": (64, 64), "tab_professions_32.tga": (32, 32),
    "tab_racials.tga": (64, 64), "tab_racials_32.tga": (32, 32),
    "util_lock.tga": (64, 64), "util_lock_32.tga": (32, 32), "util_lock_16.tga": (16, 16),
}

tgas = [f for f in os.listdir(ICON) if f.endswith(".tga")]
check("folder holds the 98 delivered textures", len(tgas), 98)
for name in NEW:
    path = os.path.join(ICON, name)
    check(f"{name} is in Media/icons", os.path.isfile(path), True)
    if os.path.isfile(path):
        with open(path, "rb") as fh:
            hdr = fh.read(18)
        w, h = struct.unpack_from("<HH", hdr, 12)
        check(f"{name} is {WANT_SIZE[name][0]}x{WANT_SIZE[name][1]} type 2",
              (hdr[2], w, h), (2, WANT_SIZE[name][0], WANT_SIZE[name][1]))

for name, size in DELIVERED.items():
    path = os.path.join(ICON, name)
    check(f"{name} is in Media/icons", os.path.isfile(path), True)
    if os.path.isfile(path):
        with open(path, "rb") as fh:
            hdr = fh.read(18)
        w, h = struct.unpack_from("<HH", hdr, 12)
        check(f"{name} is {size[0]}x{size[1]} type 2",
              (hdr[2], w, h), (2, size[0], size[1]))

manifest = open(os.path.join(ICON, "MEDIA.md"), encoding="utf-8").read()
check("manifest counts 98 textures, the full named set",
      "98 TGA" in manifest and "named set is 98" in manifest)
check("manifest no longer lists those nine as missing",
      "still not in any archive" not in manifest and "util_lock_16.tga" in manifest)

ui = open(os.path.join(ROOT, "Core/UI.lua"), encoding="utf-8").read()
check("Professions tab uses its 20px glyph", "tab_professions_32.tga" in ui, True)
check("Pets tab uses its 20px glyph", "tab_pets_32.tga" in ui, True)
check("Racials tab uses its 20px glyph", "tab_racials_32.tga" in ui, True)

L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute("ToonAge = {}")
L.execute(open(os.path.join(ROOT, "Core/Utils.lua"), encoding="utf-8").read())
U = L.eval("ToonAge.Utils")

check("distance reads in yards", U.FormatDistance(124), "124 yd")
check("estimated distance takes a tilde", U.FormatDistance(124, True), "~124 yd")
check("a long distance keeps the tilde on the kilometre form", U.FormatDistance(2000, True), "~1.8 km")

check("default arrow size is 48", U.WaypointSize(None, False), 48)
check("arrow size clamps to 32 and 64", (U.WaypointSize(8, False), U.WaypointSize(90, False)), (32, 64))
check("hollow arrow is never drawn below 40", U.WaypointSize(32, True), 40)
check("a 48px hollow arrow stays 48", U.WaypointSize(48, True), 48)

def alpha(yards):
    got = U.WaypointArrowAlpha(yards)
    return (got[0], got[1]) if isinstance(got, tuple) else (got, None)

check("8 yards is a full arrow", alpha(8), (1, False))
check("5 yards is the arrived ring", alpha(5), (0, True))
check("6.5 yards is halfway faded", alpha(6.5), (0.5, False))

check("an estimated step uses the hollow arrow", U.WaypointHollow(L.eval("{ estimated = true }")), True)
check("an unverified step uses the hollow arrow", U.WaypointHollow(L.eval("{ unverified = true }")), True)
check("a checked step uses the solid arrow", U.WaypointHollow(L.eval("{ coord = { x = 1 } }")), False)

up = U.GearMark("upgrade", False)
down = U.GearMark("downgrade", False)
down_cmp = U.GearMark("downgrade", True)
side = U.GearMark("sidegrade", False)
check("upgrade mark is the 16px texture, 4px after the preceding text",
      "util_upgrade_16.tga:16:16:4:0:" in up)
check("upgrade tint is the success colour", ":77:235:102|t" in up)
check("downgrade is omitted outside a comparison", down, "")
check("downgrade in a comparison uses the danger colour",
      "util_downgrade_16.tga:16:16:4:0:" in down_cmp and ":255:89:77|t" in down_cmp)
check("sidegrade tint is text_muted", "util_sidegrade_16.tga:16:16:4:0:" in side and ":115:110:102|t" in side)
check("the mark is appended after the item name",
      U.MarkItemName("Linen Vest", "upgrade", True), "Linen Vest" + up)
check("a second pass does not stack marks",
      U.MarkItemName("Linen Vest" + up, "upgrade", True), "Linen Vest" + up)

for rel in ("Modules/Navigation/Arrow.lua", "Modules/Mists/Arrow.lua"):
    src = open(os.path.join(ROOT, rel), encoding="utf-8").read()
    check(f"{rel} paints through the shared arrow", "U.PaintQuestArrow" in src)
    check(f"{rel} does not tint the waypoint", "SetVertexColor(" not in src)
    check(f"{rel} hides with no player position", "U.RevealWaypoint(f, false)" in src)
    check(f"{rel} hides in instances", "U.InInstance()" in src)

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
