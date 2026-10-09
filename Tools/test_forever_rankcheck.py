#!/usr/bin/env python3
"""
ToonAge -- Forever Spells tab rank check
========================================
Executes Core/Utils.lua and Modules/Forever/Rotation.lua in Lua 5.1.

Rank order comes from the position in Data/Forever/SpellRanks.lua. A spell
that is not in that file is ordered by trained level. GetSpellSubtext is
display text only: a loaded "Rank N" that disagrees with the chain is
reported, and an empty subtext is not a disagreement.

Fixture spell IDs are one ID per rank (Forever probe): Frostbolt 116/205,
Fireball 133/143/145/3140.

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

CHAINS = r"""
ToonAge.flavor = "forever"
ToonAge.Data = { ForeverSpellRanks = {
    Frostbolt = { { id = 116, learned = 4 }, { id = 205, learned = 8 } },
    Fireball = { { id = 133, learned = 1 }, { id = 143, learned = 6 },
                  { id = 145, learned = 12 }, { id = 3140, learned = 18 } },
} }
"""


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
    ToonAge = { modules = {} }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    """)
    lua.execute((ROOT / "Core/Utils.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / "Modules/Forever/Rotation.lua").read_text(encoding="utf-8"))
    lua.execute(CHAINS)
    return lua, lua.eval("ToonAge.modules.ForeverRotation"), lua.eval("ToonAge.Utils")


def main():
    lua, M, U = load()
    rank = M._RankNumber
    check("Rank 3 -> 3", rank("Rank 3"), 3)
    check("Rank 12 -> 12", rank("Rank 12"), 12)
    check("no number -> nil", rank("Racial"), None)
    check("nil -> nil", rank(None), None)
    check("empty subtext -> nil", rank(""), None)

    find = lua.eval(r"""function(M, case)
        local lines, bars
        if case == "ranked" or case == "lies" then
            ToonAge.Data = { ForeverSpellRanks = {
                Frostbolt = { { id = 116, learned = 4 }, { id = 205, learned = 8 } },
                Fireball = { { id = 133, learned = 1 }, { id = 143, learned = 6 },
                              { id = 145, learned = 12 }, { id = 3140, learned = 18 } },
            } }
            local lie = (case == "lies")
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116, rank = lie and "Rank 9" or "Rank 1" },
                { name = "Frostbolt", spellID = 205, rank = lie and "Rank 1" or "Rank 2" } } },
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
            ToonAge.Data = { ForeverSpellRanks = {
                Frostbolt = { { id = 116, learned = 4 }, { id = 205, learned = 8 } },
            } }
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116 },
                { name = "Frostbolt", spellID = 205 } } } }
            bars = { { slot = 1, spellID = 205 } }
        elseif case == "learned" then
            ToonAge.Data = {}
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116, learned = 4 },
                { name = "Frostbolt", spellID = 205, learned = 8 } } } }
            bars = { { slot = 4, spellID = 116, learned = 4 } }
        else -- subtext only: the text must not order ranks
            ToonAge.Data = {}
            lines = { { name = "Frost", spells = {
                { name = "Frostbolt", spellID = 116, rank = "Rank 1" },
                { name = "Frostbolt", spellID = 205, rank = "Rank 2" } } } }
            bars = { { slot = 1, spellID = 116, rank = "Rank 1" } }
        end
        local out, ranked = M._FindOutdated(lines, bars)
        local parts = {}
        for _, o in ipairs(out) do
            parts[#parts + 1] = o.slot .. ":" .. o.name .. ":" .. o.have .. "/" .. o.best
        end
        return table.concat(parts, ","), ranked
    end""")

    got, ranked = find(M, "ranked")
    check("chain: flags low ranks in slot order", got, "2:Frostbolt:1/2,7:Fireball:2/4")
    check("chain: reports ranks available", ranked, True)

    got, ranked = find(M, "lies")
    check("lying subtext does not change the chain", got, "2:Frostbolt:1/2,7:Fireball:2/4")
    check("lying subtext: still ranked", ranked, True)

    got, ranked = find(M, "current")
    check("current: nothing flagged", got, "")
    check("current: ranked from the chain with no subtext", ranked, True)

    got, ranked = find(M, "learned")
    check("no file: trained level orders the ranks", got, "4:Frostbolt:1/2")
    check("no file: ranked", ranked, True)

    got, ranked = find(M, "subtext")
    check("subtext alone flags nothing", got, "")
    check("subtext alone: ranked=false", ranked, False)

    disagree = lua.eval(r"""function(U)
        local chains = {
            Fireball = { { id = 133 }, { id = 143 }, { id = 145 } },
        }
        local function sub(id)
            if id == 133 then return "" end
            if id == 143 then return "Rank 2" end
            if id == 145 then return "Rank 2" end
        end
        local bad, checked, unloaded = U.SpellRankDisagreements(chains, sub)
        local first = bad[1]
        return #bad, checked, unloaded,
            first and first.id, first and first.file, first and first.got
    end""")
    nbad, checked, unloaded, sid, file_n, got_n = disagree(U)
    check("empty subtext is not a disagreement", nbad, 1)
    check("loaded subtext was checked", checked, 2)
    check("blank subtext counted unloaded", unloaded, 1)
    check("disagreement is spell 145", sid, 145)
    check("data file position is 3", file_n, 3)
    check("subtext read as rank 2", got_n, 2)

    src = (ROOT / "Modules/Forever/Rotation.lua").read_text(encoding="utf-8")
    check("asks the client to load empty subtext", "C_Spell.RequestLoadSpellData" in src, True)
    check("redraws when spell data arrives", "SPELL_DATA_LOAD_RESULT" in src, True)
    check("bar check does not parse subtext", "RankNumber(" not in src.split("local function FindOutdated")[1].split("M._FindOutdated")[0], True)

    harness = (ROOT / "Modules/Infrastructure/TestHarness.lua").read_text(encoding="utf-8")
    check("self-test compares the chain to subtext", "SpellRankDisagreements" in harness, True)
    check("self-test requests unloaded spell data", "RequestLoadSpellData" in harness, True)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
