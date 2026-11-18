#!/usr/bin/env python3
"""Coordinate harvest must not persist a character name.

New rows are keyed by quest and step. They do not store a character name.
An older row that still has one is left in place, and the copy text never
prints it.

Usage:  python3 Tools/test_coord_harvester.py [-v]
"""
import os
import re
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


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


def strip_comments(src):
    return "\n".join(re.sub(r"--.*$", "", line) for line in src.split("\n"))


code = strip_comments(read("Modules/Infrastructure/CoordHarvester.lua"))
check("new rows do not call UnitName", re.search(r"(?<![\w.])UnitName\s*\(", code) is None)
check("new rows do not write charName", "charName" not in code)

WORLD = r"""
ToonAge = { modules = {}, db = { coordHarvest = {} } }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:RegisterEvent() end
function ToonAge:Raw() end
function ToonAge:ShowCopyWindow() end
function UnitName() return "FixtureToon" end
function time() return 1700000000 end
function date() return "2026-01-01 00:00" end
"""


def boot():
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(WORLD)
    L.execute(read("Modules/Infrastructure/CoordHarvester.lua"))
    return L, L.globals().ToonAge


L, TA = boot()
CH = TA.modules.CoordHarvester
L.execute(r"""
ToonAge.db.coordHarvest["9_turnin"] = {
    questID = 9, title = "Old Quest", type = "turnin",
    map = 1, x = 0.1, y = 0.2, timestamp = 1, charName = "LegacyToon",
}
""")
CH.Store(CH, "waypoint", 100, "A Quest Title", 1429, 0.51, 0.22)
new = TA.db.coordHarvest["100_waypoint"]
old = TA.db.coordHarvest["9_turnin"]
check("a new row has no character name", new.charName, None)
check("a new row still records the quest", (new.questID, new.title, new.type, new.map),
      (100, "A Quest Title", "waypoint", 1429))
check("an older row is left untouched", old.charName, "LegacyToon")
text = str(CH.Export(CH))
check("the copy text still includes the quest", "A Quest Title" in text and "Old Quest" in text)
check("the copy text omits the character name", "FixtureToon" not in text and "LegacyToon" not in text)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
