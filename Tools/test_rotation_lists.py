#!/usr/bin/env python3
"""
ToonAge -- per-version rotation lists
=====================================
The list is class, spec, level band, then single-target and AoE. The rank
shown is the highest one in the chain the character knows. verified = false
is approximate. An empty band is the "No verified rotation yet" card.
Retail Rogue prefers Deathstalker, Deathstalker, Trickster.

Usage:  python3 Tools/test_rotation_lists.py [-v]
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
    return lua


DATA = r"""
DATA = {
    unverified = false,
    ROGUE = {
        Assassination = {
            Deathstalker = {
                { min = 1, max = 80, st = {
                    { name = "Mutilate", ranks = { 1329, 5374, 10 }, verified = true },
                    { name = "Envenom", rankIDs = { 32645, 3 }, verified = false },
                }, aoe = {
                    { name = "Fan of Knives", ranks = { 51723 }, verified = true },
                } },
            },
            Fatebound = {
                { min = 1, max = 80, st = {
                    { name = "Ambush", ranks = { 8676 }, verified = true },
                }, aoe = {} },
            },
        },
        Subtlety = {
            Deathstalker = {
                { min = 1, max = 80, st = {
                    { name = "Backstab", ranks = { 53 }, verified = true },
                }, aoe = {} },
            },
            Trickster = {
                { min = 1, max = 80, st = {
                    { name = "Wrong Subtlety", ranks = { 1 }, verified = true },
                }, aoe = {} },
            },
        },
        Outlaw = {
            Trickster = {
                { min = 1, max = 80, st = {
                    { name = "Sinister Strike", ranks = { 1752 }, verified = true },
                }, aoe = {} },
            },
            Fatebound = {
                { min = 1, max = 80, st = {
                    { name = "Wrong Outlaw", ranks = { 2 }, verified = true },
                }, aoe = {} },
            },
        },
    },
    DEATHKNIGHT = {
        Blood = {
            ["1-54"] = { st = {}, aoe = {} },
            ["55-90"] = { st = {
                { name = "Death Strike", ranks = { 49998 }, verified = true },
            }, aoe = {} },
        },
    },
}
FOREVER = {
    unverified = true,
    ROGUE = {
        Combat = {
            { min = 1, max = 60, st = {
                { name = "Sinister Strike", ranks = { 1752, 1757 }, verified = true },
            }, aoe = {
                { name = "Blade Flurry", ranks = { 13877 }, verified = true },
            } },
        },
    },
}
"""


def test_rules():
    lua = runtime()
    lua.execute(DATA)
    lua.execute(r"""
        local RL = ToonAge.RotationLists
        function IsPlayerSpell(id) return id == 5374 or id == 32645 or id == 3 or id == 1752 end
        RANK = RL.PickRank({ 10, 5374, 7 })
        NONE = RL.PickRank({ 9, 8 })
        IsPlayerSpell = nil
        IsSpellKnown = function(id) return id == 3 end
        BY_KNOWN = RL.PickRank({ 10, 3, 7 })
        IsSpellKnown = nil
        TOP = RL.PickRank({ 10, 3, 7 })
        function IsPlayerSpell(id) return id == 5374 or id == 32645 or id == 1752 end
        ROGUE = RL.Resolve(DATA, "ROGUE", "Assassination", 60, "st")
        AOE = RL.Resolve(DATA, "ROGUE", "Assassination", 60, "aoe")
        SUB = RL.Resolve(DATA, "ROGUE", "Subtlety", 60, "st")
        OUT = RL.Resolve(DATA, "ROGUE", "Outlaw", 60, "st")
        LOW = RL.Resolve(DATA, "DEATHKNIGHT", "Blood", 40, "st")
        HIGH = RL.Resolve(DATA, "DEATHKNIGHT", "Blood", 70, "st")
        MISSING = RL.Resolve(DATA, "MAGE", "Frost", 70, "st")
        OTHER = RL.Resolve(DATA, "ROGUE", "Combat", 10, "st")
        PLAN = RL.BarPlan(ROGUE.spells, { spellID = 8676, name = "Ambush" }, true)
        QUIET = RL.BarPlan(ROGUE.spells, nil, true)
        FOREVER_VIEW = RL.Resolve(FOREVER, "ROGUE", "Combat", 20, "st")
        MISSES, COUNT, ASKED = RL.Misses(function(id)
            if id == 1329 then return nil end
            return { name = "Spell" }
        end, DATA)
    """)
    check("a known middle rank wins over a higher spell id", lua.eval("RANK"), 5374)
    check("an unknown chain shows its first rank", lua.eval("NONE"), 9)
    check("IsSpellKnown is used when IsPlayerSpell is missing", lua.eval("BY_KNOWN"), 3)
    check("without either spell API the last rank is shown", lua.eval("TOP"), 7)
    check("assassination uses Deathstalker", lua.eval("ROGUE.hero"), "Deathstalker")
    check("the Deathstalker builder is Mutilate", lua.eval("ROGUE.spells[1].name"), "Mutilate")
    check("Mutilate uses the known rank", lua.eval("ROGUE.spells[1].spellID"), 5374)
    check("a verified entry is not approximate", lua.eval("ROGUE.spells[1].approximate"), False)
    check("verified false is approximate", lua.eval("ROGUE.spells[2].approximate"), True)
    check("the fallback rank id is kept", lua.eval("ROGUE.spells[2].spellID"), 32645)
    check("aoe is a separate list", lua.eval("AOE.spells[1].name"), "Fan of Knives")
    check("subtlety uses Deathstalker", lua.eval("SUB.spells[1].name"), "Backstab")
    check("outlaw uses Trickster", lua.eval("OUT.spells[1].name"), "Sinister Strike")
    check("an empty low band is the card", lua.eval("LOW.empty"), True)
    check("the empty card has no spells", lua.eval("#LOW.spells"), 0)
    check("the Death Knight band from 55 has its spell", lua.eval("HIGH.spells[1].name"), "Death Strike")
    check("a class that is not in the file is left alone", lua.eval("MISSING"), None)
    check("a different spec is not the empty card", lua.eval("OTHER"), None)
    check("combat puts the assisted spell first", lua.eval("PLAN[1].spellID"), 8676)
    check("the assisted spell is the suggestion", lua.eval("PLAN[1].suggested"), True)
    check("the fixed list follows it", lua.eval("PLAN[2].name"), "Mutilate")
    check("a secret or missing suggestion leaves the fixed list", lua.eval("QUIET[1].name"), "Mutilate")
    check("a file-level unverified flag marks a verified entry", lua.eval("FOREVER_VIEW.spells[1].approximate"), True)
    check("GetSpellInfo misses are listed", lua.eval("MISSES[1].id"), 1329)
    check("the miss keeps the spell name", lua.eval("MISSES[1].name"), "Mutilate")
    check("one miss out of the ids that were walked", lua.eval("#MISSES") >= 1, True)


def test_files():
    lib = read("Modules/Infrastructure/RotationLists.lua")
    retail = read("Modules/Combat/Rotation.lua")
    forever = read("Modules/Forever/Rotation.lua")
    check("rank subtext is not a rank source", "GetSpellSubtext" in lib, False)
    check("the empty card text is exact", 'RL.EMPTY = "No verified rotation yet"' in lib, True)
    check("diagnostics use GetSpellInfo", "C_Spell.GetSpellInfo" in lib, True)
    check("retail combat suggestions are assisted combat", "C_AssistedCombat" in retail, True)
    check("retail checks a secret suggestion before using it",
          retail.index("IsSecret") < retail.index("type(id) ~= \"number\""), True)
    check("forever combat suggestions are assisted combat", "C_AssistedCombat" in forever, True)
    check("the self-test reports rotation misses",
          "RotationLists" in read("Modules/Infrastructure/TestHarness.lua"), True)
    check("health prints the rotation line",
          "RotationLists" in read("Core/Init.lua"), True)
    for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_TBC.toc",
                "ToonAge_Mists.toc", "ToonAge_Camelot.toc", "ToonAge_Vanilla.toc"):
        check(f"{toc} loads the rotation list reader",
              "Modules\\Infrastructure\\RotationLists.lua" in read(toc), True)
    for toc in ("ToonAge_Cata.toc", "ToonAge_Wrath.toc"):
        check(f"{toc} does not load rotation lists",
              "RotationLists.lua" in read(toc), False)
    for toc, data in (
        ("ToonAge.toc", "Data\\Retail\\"),
        ("ToonAge_TBC.toc", "Data\\TBC\\"),
        ("ToonAge_Mists.toc", "Data\\Mists\\"),
        ("ToonAge_Camelot.toc", "Data\\Forever\\"),
        ("ToonAge_Vanilla.toc", "Data\\Vanilla\\"),
    ):
        text = read(toc)
        foreign = []
        for other in ("Data\\Retail\\", "Data\\TBC\\", "Data\\Mists\\",
                      "Data\\Forever\\", "Data\\Vanilla\\"):
            if other != data and other in text:
                foreign.append(other)
        check(f"{toc} does not load another version's data", foreign, [])


def main():
    test_rules()
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
