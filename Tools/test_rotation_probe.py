#!/usr/bin/env python3
"""
ToonAge -- rotation self-test probe scope
==========================================
On a Forever Mage, /ta test warned GetSpellInfo missed for Mutilate 1310707
six times and Blessing of Light 19977, 19978, 19979 twice each.

Blessing of Light is removed from the Forever list. The check still walks
every class in this version's rotation file. GetSpellInfo reads the client
spell database, not the spellbook, so other classes stay in the probe. Each
remaining id is reported once, and a miss for another class says so.
Mutilate 1310707 stays, at level 40. No cross-expansion id is added.

Usage:  python3 Tools/test_rotation_probe.py [-v]
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


def check(name, got, want):
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


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { Data = {} }; ToonAge.Utils = { IsSecret = function() return false end }")
    lua.execute(read("Modules/Infrastructure/RotationLists.lua"))
    lua.execute(read("Data/Forever/RotationLists.lua"))
    return lua


PROBE = r"""
    local RL = ToonAge.RotationLists
    local miss = { [1310707] = true, [19977] = true, [19978] = true, [19979] = true, [133] = true }
    local misses = RL.Misses(function(id)
        if miss[id] then return nil end
        return { name = "Spell" }
    end)
    local counts, found = {}, {}
    for _, row in ipairs(misses) do
        counts[row.id] = (counts[row.id] or 0) + 1
        found[row.id] = row
    end
    C1310707 = counts[1310707] or 0
    C19977 = counts[19977] or 0
    C19978 = counts[19978] or 0
    C19979 = counts[19979] or 0
    C133 = counts[133] or 0
    MUTILATE = found[1310707]
    LIGHT = found[19977]
    FIRE = found[133]
    local function line(row, class)
        if type(RL.MissLine) ~= "function" or type(row) ~= "table" then return "" end
        return RL.MissLine(row, class)
    end
    MAGE_MUTILATE = line(MUTILATE, "MAGE")
    MAGE_LIGHT = line(LIGHT, "MAGE")
    MAGE_FIRE = line(FIRE, "MAGE")
    ROGUE_MUTILATE = line(MUTILATE, "ROGUE")
    UNKNOWN_MUTILATE = line(MUTILATE, nil)
"""


def test_probe():
    lua = runtime()
    lua.execute(PROBE)
    check("Mutilate 1310707 is still probed on a full-file check", lua.eval("C1310707") > 0, True)
    check("Mutilate 1310707 is reported once", lua.eval("C1310707"), 1)
    check("Blessing of Light 19977 is not probed", lua.eval("C19977"), 0)
    check("Blessing of Light 19978 is not probed", lua.eval("C19978"), 0)
    check("Blessing of Light 19979 is not probed", lua.eval("C19979"), 0)
    check("Fireball 133 is reported once", lua.eval("C133"), 1)
    check("Mutilate's class is Rogue", lua.eval("MUTILATE.class"), "ROGUE")
    check("Blessing of Light is absent from the probe hits", lua.eval("LIGHT"), None)
    check("Fireball's class is Mage", lua.eval("FIRE.class"), "MAGE")
    check("a Mage sees Mutilate labeled as not their class",
          lua.eval("MAGE_MUTILATE"),
          "rotation spell 1310707 (Mutilate, ROGUE, not your class): GetSpellInfo missed")
    check("a removed Blessing of Light produces no miss line",
          lua.eval("MAGE_LIGHT"), "")
    check("a Mage's own miss is not labeled as another class",
          lua.eval("MAGE_FIRE"),
          "rotation spell 133 (Fireball, MAGE): GetSpellInfo missed")
    check("a Rogue's Mutilate miss is their own class",
          lua.eval("ROGUE_MUTILATE"),
          "rotation spell 1310707 (Mutilate, ROGUE): GetSpellInfo missed")
    check("an unknown player class is not called 'not your class'",
          "not your class" in (lua.eval("UNKNOWN_MUTILATE") or ""), False)


def test_files():
    harness = read("Modules/Infrastructure/TestHarness.lua")
    forever = read("Data/Forever/RotationLists.lua")
    check("the self-test still probes the whole version file",
          "RL.Misses(C_Spell.GetSpellInfo)" in harness, True)
    check("the self-test prints the labeled miss line",
          "RL.MissLine(" in harness, True)
    rows = [line for line in forever.splitlines() if "spellID=1310707" in line]
    spec = forever.split("Assassination = {", 1)[1].split("Combat = {", 1)[0]
    band_2039 = spec.split("['20-39']", 1)[1].split("['40-59']", 1)[0]
    band_40 = spec.split("['40-59']", 1)[1]
    check("Mutilate 1310707 stays in the Forever list", len(rows), 4)
    check("Mutilate is absent from the 20-39 band", "spellID=1310707" not in band_2039, True)
    check("Sinister Strike stays a 20-39 builder", "name='Sinister Strike'" in band_2039, True)
    check("Backstab stays a 20-39 builder", "name='Backstab'" in band_2039, True)
    check("Mutilate is present at 40+", band_40.count("spellID=1310707"), 4)
    check("every Mutilate 1310707 row is level 40",
          all("level=40" in line for line in rows), True)
    check("no Mutilate 1310707 row stays at level 30",
          any("level=30" in line for line in rows), False)
    check("Mutilate keeps rank id 1310707",
          all("rankIDs={1310707, 399956, 1241582, 1241584}" in line for line in rows), True)
    check("Mutilate stays unverified",
          bool(rows) and all(
              "name='Mutilate'" in line and "verified=false" in line for line in rows
          ), True)
    check("Mutilate level note no longer says 21-pt at 30",
          "Mutilate is a 21-pt talent at 30" not in forever, True)
    check("Mutilate level note says Row 7 at level 40",
          "Mutilate is Row 7 at level 40" in forever, True)
    check("no Blessing of Light spell row", "name='Blessing of Light'" not in forever, True)
    check("no Blessing of Light spellID", "spellID=19977" not in forever, True)
    check("no Blessing of Light rank list", "rankIDs={19977, 19978, 19979}" not in forever, True)
    check("TBC Blessing of Light rank 27144 was not added", "27144" in forever, False)
    check("TBC Mutilate 1329 was not added", "spellID=1329" in forever, False)
    talents = read("Data/Forever/Talents.lua")
    check("Mutilate talent keeps spell 1310707 at level 40",
          'spell = 1310707, name = "Mutilate", maxRanks = 1, level = 40' in talents, True)
    check("Vanilla Blessing of Light is unchanged",
          "spellID=19977" in read("Data/Vanilla/RotationLists.lua"), True)
    check("TBC Blessing of Light is unchanged",
          "spellID=19977" in read("Data/TBC/RotationLists.lua"), True)
    check("Retail Mutilate stays level 12",
          "spellID=1329, name='Mutilate', rankIDs={1329}, level=12" in read("Data/Retail/RotationLists.lua"), True)


def main():
    test_probe()
    test_files()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
