#!/usr/bin/env python3
"""Forever 1.60.1 probe: spec from C_Traits sections, not spellbook tabs.

The Rogue tree is one tree of 53 nodes. Gates are spentRequired conditions of
5, 10, 15, 20 and 30. Points in a section are purchased ranks. A spellbook
tab (Combat, Assassination) and class skill lines 38 and 253 are present at
level 1 and are not a chosen spec.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")


def load_compat():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
ToonAge = { IsForever = true, modules = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
called = { spellbook = 0, skill = 0, tabs = 0, tree = 0, cond = 0, node = 0 }
UnitClass = function() return "Rogue", "ROGUE" end
C_SpellBook = { GetNumSpellBookSkillLines = function()
    called.spellbook = called.spellbook + 1
    error("spellbook is not a spec")
end }
C_SkillInfo = {
    GetNumSkillLines = function() called.skill = called.skill + 1; error("class skill is not a spec") end,
    GetSkillLineInfo = function() called.skill = called.skill + 1; error("class skill is not a spec") end,
    GetSkillLineInfoByID = function(id)
        called.skill = called.skill + 1
        if id == 38 or id == 253 then error("class skill line is not a spec") end
        return nil
    end,
}
GetTalentTabInfo = function() called.tabs = called.tabs + 1; error("classic tabs") end
GetNumTalentTabs = function() called.tabs = called.tabs + 1; error("classic tabs") end

local NODES = {}
local id = 1
for col = 1, 3 do
    local n = (col == 3) and 17 or 18
    for i = 1, n do
        local rank = 0
        if col == 2 and i <= 4 then rank = 3 end
        NODES[id] = { activeRank = rank, posX = (col - 1) * 400, posY = i * 40, maxRanks = 5 }
        id = id + 1
    end
end
NODE = NODES

C_ClassTalents = { GetActiveConfigID = function() return 7 end }
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1111 } } end,
    GetTreeNodes = function()
        local t = {}
        for i = 1, 53 do t[i] = i end
        return t
    end,
    GetNodeInfo = function(_, nodeID)
        called.node = called.node + 1
        return NODE[nodeID]
    end,
    GetTreeInfo = function()
        called.tree = called.tree + 1
        local gates, cid = {}, 1
        for col = 1, 3 do
            for _, amt in ipairs({ 5, 10, 15, 20, 30 }) do
                gates[#gates + 1] = { conditionID = cid, topLeftNodeID = (col - 1) * 18 + 1 }
                cid = cid + 1
            end
        end
        return { ID = 1111, gates = gates }
    end,
    GetConditionInfo = function(_, cid)
        called.cond = called.cond + 1
        local amounts = { 5, 10, 15, 20, 30 }
        return { spentAmountRequired = amounts[((cid - 1) % 5) + 1], isMet = false }
    end,
}
""")
    lua.execute((ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8"))
    return lua


def main():
    lua = load_compat()
    C = lua.globals().ToonAge.Compat

    lua.globals().gateList = lua.eval("""
ToonAge.Compat.SpentGateAmounts({
    [1] = { spentAmountRequired = 5 },
    [2] = { spentAmountRequired = 10 },
    [3] = { spentAmountRequired = 15 },
    [4] = { spentAmountRequired = 20 },
    [5] = { spentAmountRequired = 30 },
    [6] = { spentAmountRequired = 25 },
})
""")
    lua.execute("""
function gateText()
    local t = {}
    for i = 1, #gateList do t[i] = tostring(gateList[i]) end
    return table.concat(t, ",")
end
""")
    check("row gates are 5, 10, 15, 20, 30", lua.eval("gateText()"), "5,10,15,20,30")

    idx, name, pts = C.SpecFromTraitSections()
    check("53-node rogue tree was walked", lua.eval("called.node"), 53)
    check("GetTreeInfo was read", lua.eval("called.tree") >= 1, True)
    check("fifteen gate conditions", lua.eval("called.cond"), 15)
    check("combat section wins", name, "Combat")
    check("combat is the middle section", idx, 2)
    check("twelve points in combat", pts, 12)
    check("spellbook was not consulted", lua.eval("called.spellbook"), 0)
    check("class skills were not consulted", lua.eval("called.skill"), 0)
    check("classic talent tabs were not consulted", lua.eval("called.tabs"), 0)

    lua.globals().sections = C.ReadTraitSections()
    check("three sections", lua.eval("#sections"), 3)
    check("left section is Assassination", lua.eval("sections[1].name"), "Assassination")
    check("right section is Subtlety", lua.eval("sections[3].name"), "Subtlety")
    check("level 1 sections can sit at zero", lua.eval("sections[1].points + sections[3].points"), 0)

    lua.execute("""
for i = 1, 53 do NODE[i].activeRank = 0 end
""")
    check("no points means no spec", C.SpecFromTraitSections(), None)

    lua.execute("""
for i = 1, 18 do NODE[i].activeRank = 1 end
for i = 19, 36 do NODE[i].activeRank = 1 end
""")
    check("a tie is not a spec", C.SpecFromTraitSections(), None)

    # A gated node with no posX inherits its column from the gate anchor.
    # Three columns, so the classic names apply. The middle column leads.
    pure = lua.eval(r"""
function()
    local nodes = {}
    local function add(id, rank, x, edges, conds)
        nodes[#nodes + 1] = { nodeID = id, rank = rank, posX = x, edges = edges, conditionIDs = conds }
    end
    add(1, 0, 0, { 2 }, nil)
    add(2, 5, nil, { 1 }, { 10 })
    add(3, 0, 400, { 4 }, nil)
    add(4, 11, nil, { 3 }, { 20 })
    add(5, 0, 800, { 6 }, nil)
    add(6, 0, nil, { 5 }, { 30 })
    local conditions = {
        [10] = { spentAmountRequired = 5, topLeftNodeID = 1 },
        [20] = { spentAmountRequired = 10, topLeftNodeID = 3 },
        [30] = { spentAmountRequired = 30, topLeftNodeID = 5 },
    }
    return ToonAge.Compat.SpecFromSections(
        ToonAge.Compat.GroupTraitSections(nodes, conditions), "ROGUE")
end
""")
    idx, name, pts = pure()
    check("gated node stays in its column", name, "Combat")
    check("gated column points include that node", pts, 11)

    # Missing globals must not throw, and a throwing stub must not escape.
    check("missing-API guard survives stubs", C.GuardMissingForeverAPIs(), None)
    lua.execute("""
GetTalentTabInfo = nil
UnitAttackBothHands = nil
UnitRangedAttack = nil
UnitDefense = nil
GetSpellLevelLearned = nil
C_Spell = nil
""")
    check("missing-API guard survives nils", C.GuardMissingForeverAPIs(), None)

    lua.execute((ROOT / "Core/Utils.lua").read_text(encoding="utf-8"))
    lua.execute("called.tabs = 0; for i = 1, 53 do NODE[i].activeRank = 0 end; NODE[20].activeRank = 6")
    spec = lua.eval("function() return ToonAge.Utils.GetPlayerSpec() end")
    got = spec()
    check("GetPlayerSpec on Forever is the trait section", got[1], "Combat")
    check("GetPlayerSpec does not use talent tabs", lua.eval("called.tabs"), 0)

    # Comprehension: max 0 hides, a real cap shows, nil-by-ID is absent.
    lua.execute("ToonAge.Utils = ToonAge.Utils or {}")
    lua.execute((ROOT / "Modules/Forever/Scrolls.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
function comp(kind)
    local M = ToonAge.modules.ForeverScrolls
    if kind == "zero" then return M.ReadComprehension({ skillLevel = 0, maxSkillLevel = 0 }, nil) end
    if kind == "mage" then return M.ReadComprehension({ skillLevel = 25, maxSkillLevel = 85 }, nil) end
    return M.ReadComprehension(nil, false)
end
""")
    comp = lua.eval("comp")
    r, m = comp("zero")
    check("non-mage comprehension max 0 has no rank", r, None)
    check("non-mage comprehension max is 0", m, 0)
    r, m = comp("mage")
    check("mage comprehension rank", r, 25)
    check("mage comprehension cap", m, 85)
    r, m = comp("missing")
    check("nil skill line is not a rank", r, None)
    check("nil skill line hides the row", m, 0)

    scrolls = (ROOT / "Modules/Forever/Scrolls.lua").read_text(encoding="utf-8")
    check("skill row hidden when the cap is 0", "myMax ~= 0" in scrolls, True)

    manifest = (ROOT / "Data/Forever/ApiManifest.lua").read_text(encoding="utf-8")
    for key in ("GetTalentTabInfo", "UnitAttackBothHands", "UnitRangedAttack",
                "UnitDefense", "GetSpellLevelLearned", "C_Spell.GetSpellRank",
                "C_Traits.GetTreeInfo", "C_Traits.GetNodeInfo", "C_Traits.GetConditionInfo",
                "C_Spell.GetSpellSubtext", "C_Spell.GetSpellLevelLearned"):
        check(f"manifest lists {key}", f'["{key}"]' in manifest, True)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
