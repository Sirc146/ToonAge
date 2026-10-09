#!/usr/bin/env python3
"""
ToonAge -- Forever Spells tab rank check
========================================
Executes the real Modules/Forever/Rotation.lua in Lua 5.1 and exercises the
two pure pieces of the action-bar rank check:

  RankNumber    "Rank 3" -> 3, anything without a number -> nil
  FindOutdated  spellbook groups + bar slots -> slots holding a lower rank

The rule under test: ranks come ONLY from rank text. Spell IDs are never used
to order ranks, so a spellbook with no rank text must report ranked=false and
flag nothing.

Fixture spell IDs are one ID per rank (Forever probe): Frostbolt 116/205,
Fireball 133/143/145/3140. 3140 is rank 4; the check still uses rank text.

Usage:  python Tools/test_forever_rankcheck.py [-v]
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")


def load():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
    ToonAge = { Utils = {}, modules = {} }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    """)
    lua.execute((ROOT / "Modules/Forever/Rotation.lua").read_text(encoding="utf-8"))
    return lua, lua.eval("ToonAge.modules.ForeverRotation")


def main():
    lua, M = load()
    rank = M._RankNumber
    check("Rank 3 -> 3", rank("Rank 3"), 3)
    check("Rank 12 -> 12", rank("Rank 12"), 12)
    check("no number -> nil", rank("Racial"), None)
    check("nil -> nil", rank(None), None)

    find = lua.eval("""function(M, case)
        local lines, bars
        if case == "ranked" then
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116, rank = "Rank 1" },
                { name = "Frostbolt", spellID = 205, rank = "Rank 2" } } },
              { name = "Fire", spells = {
                { name = "Fireball", spellID = 133, rank = "Rank 1" },
                { name = "Fireball", spellID = 143, rank = "Rank 2" },
                { name = "Fireball", spellID = 145, rank = "Rank 3" },
                { name = "Fireball", spellID = 3140, rank = "Rank 4" } } },
              { name = "General", spells = {
                { name = "Attack", spellID = 6603 } } } }
            bars = { { slot = 7, spellID = 143 }, { slot = 2, spellID = 116 },
                     { slot = 3, spellID = 205 }, { slot = 1, spellID = 6603 },
                     { slot = 9, spellID = 99999 } }
        elseif case == "current" then
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116, rank = "Rank 1" },
                { name = "Frostbolt", spellID = 205, rank = "Rank 2" } } } }
            bars = { { slot = 1, spellID = 205 } }
        else -- "unranked": same IDs, no rank text at all
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116 },
                { name = "Frostbolt", spellID = 205 } } } }
            bars = { { slot = 1, spellID = 116 } }
        end
        local out, ranked = M._FindOutdated(lines, bars)
        local parts = {}
        for _, o in ipairs(out) do
            parts[#parts + 1] = o.slot .. ":" .. o.name .. ":" .. o.have .. "/" .. o.best
        end
        return table.concat(parts, ","), ranked
    end""")

    got, ranked = find(M, "ranked")
    check("ranked: flags low ranks in slot order", got, "2:Frostbolt:1/2,7:Fireball:2/4")
    check("ranked: reports ranks available", ranked, True)

    got, ranked = find(M, "current")
    check("current: nothing flagged", got, "")
    check("current: ranked", ranked, True)

    got, ranked = find(M, "unranked")
    check("unranked: nothing flagged (no ID guessing)", got, "")
    check("unranked: ranked=false", ranked, False)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
