#!/usr/bin/env python3
"""
ToonAge -- Forever talent grid
==============================
Columns and rows are the rank order of posX and posY. A gated node carries
its own lock. posY that grows upward is flipped. Node size follows the
tab-bar widths, then the grid shrinks to the content width.

Usage:  python3 Tools/test_forever_talents.py [-v]
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


def load():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
ToonAge = { Data = {}, modules = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
ToonAge.Utils = { IsSecret = function() return false end }
""")
    lua.execute((ROOT / "Modules/Forever/Talents.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
local M = ToonAge.modules.ForeverTalents

local function add(nodes, id, x, y, rank, max, conds, edges)
    nodes[#nodes + 1] = {
        id = id, posX = x, posY = y, rank = rank or 0, max = max or 1,
        conditionIDs = conds or {}, edges = edges or {}, name = "N" .. id,
    }
end

function build()
    local nodes, conds = {}, {}
    for x = 0, 11 do
        add(nodes, 1000 + x, x * 100, 0, 0, 1, {}, {})
    end
    for y = 1, 6 do
        add(nodes, 2000 + y, 0, y * 100, 0, 1, {}, {})
    end
    -- Fill the measured shape: 12 distinct x, 7 distinct y.
    -- Eight gates, two of them sharing a row with a different amount,
    -- so a row is not one gate.
    nodes[1].rank, nodes[1].max = 0, 1                 -- available
    nodes[2].rank, nodes[2].max = 2, 5                 -- partial, "2/5"
    nodes[3].rank, nodes[3].max = 5, 5                 -- maxed
    nodes[2].edges = { { targetNode = 1000 } }
    nodes[1].edges = { { targetNode = 1001 } }         -- same edge, drawn once

    local function gate(id, cid, req, met)
        for _, n in ipairs(nodes) do
            if n.id == id then n.conditionIDs = { cid } end
        end
        conds[cid] = { spentRequired = req, isMet = met }
    end
    -- Extra nodes on rows that need two different gates. Their x values
    -- are already in the 12, so the column count does not grow.
    add(nodes, 3002, 100, 100, 0, 1, {}, {})
    add(nodes, 3003, 200, 200, 0, 1, {}, {})
    add(nodes, 3004, 300, 300, 0, 1, {}, {})

    gate(2001, 1, 5,  false)   -- row y=100, unmet
    gate(3002, 2, 5,  true)    -- same row, this node is open
    gate(2002, 3, 10, false)
    gate(3003, 4, 15, false)   -- same row as the 10, label stays 10
    gate(2003, 5, 10, false)
    gate(3004, 6, 15, false)
    gate(2004, 7, 20, false)
    gate(2005, 8, 30, false)
    return nodes, conds
end

function place(window, avail, nodes, conds)
    return M.Layout(nodes, conds, { windowWidth = window, availWidth = avail, spent = 0 })
end

function cell(plan, id)
    for i = 1, #plan.cells do
        if plan.cells[i].id == id then return plan.cells[i] end
    end
end

function reportText(diag)
    return table.concat(diag.lines, "\n")
end
""")
    return lua


def main():
    lua = load()
    M = lua.globals().ToonAge.modules.ForeverTalents
    check("full window uses 40px nodes", M.NodePx(900), 40)
    check("740 is still the full breakpoint", M.NodePx(740), 40)
    check("739 is the compact breakpoint", M.NodePx(739), 36)
    check("676 is still compact", M.NodePx(676), 36)
    check("675 is the glyph breakpoint", M.NodePx(675), 28)
    check("568 uses the small node", M.NodePx(568), 28)
    check("header names spent and unspent", M.Header(12, 3), "12 points spent · 3 to spend")
    check("one point stays singular", M.Header(1, 0), "1 point spent · 0 to spend")
    check("partial badge is rank over max", M.Badge(2, 5), "2/5")
    check("a single-rank node has no badge", M.Badge(1, 1), None)
    check("rank zero has no badge", M.Badge(0, 5), None)
    check("maxed beats the lock", M.NodeState(5, 5, True), "maxed")
    check("a bought rank is partial", M.NodeState(2, 5, True), "partial")
    check("an unmet gate with no rank is locked", M.NodeState(0, 1, True), "locked")
    check("an open node is available", M.NodeState(0, 1, False), "available")
    check("gold is not a rank state", M.NodeState(0, 1, False) != "gold", True)
    check("lines are 2px", M.LINE_PX, 2)

    theme = M.Theme
    check("maxed is pale yellow", round(theme.maxed[1] * 255), 251)
    check("maxed green channel", round(theme.maxed[2] * 255), 224)
    check("maxed blue channel", round(theme.maxed[3] * 255), 143)
    check("available is green", round(theme.available[2] * 255) > round(theme.available[1] * 255), True)
    check("partial frame is white", theme.partial[1], 1)
    check("partial frame is white throughout", theme.partial[2] == 1 and theme.partial[3] == 1, True)
    check("gold is the hover colour", round(theme.gold[1] * 255), 232)
    check("gold green channel", round(theme.gold[2] * 255), 179)
    check("gold blue channel", round(theme.gold[3] * 255), 90)
    check("locked talents are dimmed", M.LOCK_ALPHA, 0.5)
    check("the lock uses the shared icon", "util_lock_16" in M.LOCK_TEXTURE, True)
    check("a 5-point lock says what it requires", M.LockTip(5), "Requires 5 points spent")
    check("a 30-point lock says what it requires", M.LockTip(30), "Requires 30 points spent")
    check("an open node has no lock text", lua.eval("ToonAge.modules.ForeverTalents.LockTip(nil)"), None)

    lua.execute("nodes, conds = build()")
    lua.execute("plan = place(900, 640, nodes, conds)")
    plan = lua.globals().plan
    check("twelve columns", plan.columns, 12)
    check("seven rows", plan.rows, 7)
    check("posY increases downward", plan.yDown, True)
    check("downward layout is not flipped", plan.flipped, False)
    check("wide window is not scaled", plan.scale, 1)
    check("wide window keeps 40px nodes", plan.nodePx, 40)
    check("wide grid fits 640", plan.width <= 640, True)
    check("line thickness stays 2", plan.linePx, 2)

    lua.execute("c = cell(plan, 1001)")
    cell = lua.globals().c
    check("partial node shows 2/5", cell.badge, "2/5")
    check("partial node is white-framed", cell.state, "partial")
    lua.execute("c = cell(plan, 1002)")
    check("filled node is maxed", lua.globals().c.state, "maxed")
    lua.execute("c = cell(plan, 1000)")
    check("ungated node is available", lua.globals().c.state, "available")

    lua.execute("c = cell(plan, 2001)")
    check("unmet node on a shared row is locked", lua.globals().c.locked, True)
    check("that lock names its own 5 points", lua.globals().c.lockTip, "Requires 5 points spent")
    lua.execute("c = cell(plan, 3002)")
    check("met node beside it stays open", lua.globals().c.locked, False)
    check("the open neighbour has no lock", lua.globals().c.lockTip, None)
    lua.execute("c = cell(plan, 2002)")
    check("the 10-point node carries its own lock", lua.globals().c.lockTip, "Requires 10 points spent")
    lua.execute("c = cell(plan, 3003)")
    check("the 15-point neighbour is not folded into that lock", lua.globals().c.lockTip, "Requires 15 points spent")
    lua.execute("c = cell(plan, 2005)")
    check("the 30-point node carries its own lock", lua.globals().c.lockTip, "Requires 30 points spent")
    check("there is no row label", plan.rowLabels, None)

    check("a repeated edge is one line", len(plan.lines), 1)
    check("that line joins the two nodes", plan.lines[1].a == 1000 and plan.lines[1].b == 1001, True)

    text = lua.eval("reportText(ToonAge.modules.ForeverTalents.Diagnose(nodes, conds))")
    check("self-test says posY increases downward", "posY increases downward" in text, True)
    check("self-test does not flip a downward tree", "layout flipped" in text, False)
    check("self-test names the 5-point gate", "condition 1 requires 5 points, gates nodes 2001" in text, True)
    check("self-test names the open 5-point gate", "condition 2 requires 5 points, gates nodes 3002" in text, True)
    check("self-test names the 30-point gate", "condition 8 requires 30 points, gates nodes 2005" in text, True)
    check("eight conditions are listed", text.count("talent gate condition"), 8)

    # Cheap gates at a larger posY: the axis grows upward, so the layout flips
    # and the 5-point node moves to the top.
    lua.execute(r"""
flipNodes = {
    { id = 1, posX = 0, posY = 500, rank = 0, max = 1, conditionIDs = { 1 }, edges = {} },
    { id = 2, posX = 0, posY = 0,   rank = 0, max = 1, conditionIDs = { 2 }, edges = {} },
}
flipConds = {
    [1] = { spentRequired = 5,  isMet = false },
    [2] = { spentRequired = 30, isMet = false },
}
flip = ToonAge.modules.ForeverTalents.Layout(flipNodes, flipConds, { windowWidth = 900, availWidth = 640, spent = 0 })
""")
    flip = lua.globals().flip
    check("upward posY is detected", flip.yDown, False)
    check("upward layout is flipped", flip.flipped, True)
    lua.execute("c = cell(flip, 1)")
    check("the 5-point node is on top after the flip", lua.globals().c.row, 1)
    lua.execute("c = cell(flip, 2)")
    check("the 30-point node is below it", lua.globals().c.row, 2)
    flipText = lua.eval("reportText(ToonAge.modules.ForeverTalents.Diagnose(flipNodes, flipConds))")
    check("self-test logs the flip", "posY increases upward; layout flipped" in flipText, True)

    # The narrow window: glyph-sized nodes, then scaled to the content width
    # a 568px window actually has beside the sidebar.
    lua.execute("narrow = place(568, 307, nodes, conds)")
    narrow = lua.globals().narrow
    check("568 starts from 28px nodes", narrow.nodePx, 28)
    check("568 grid fits the content width", narrow.width <= 307, True)
    check("568 grid is scaled down", narrow.scale < 1, True)
    check("568 still has 12 columns", narrow.columns, 12)

    # Live read: each node's conditionIDs, both field names, no rank subtext.
    lua.execute(r"""
subtextCalls = 0
condCalls = 0
C_ClassTalents = { GetActiveConfigID = function() return 7 end }
C_Spell = {
    GetSpellName = function() return "Fireball" end,
    GetSpellTexture = function() return 135812 end,
    GetSpellSubtext = function() subtextCalls = subtextCalls + 1; return "Rank 2" end,
}
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1111 } } end,
    GetTreeCurrencyInfo = function() return { { quantity = 4 } } end,
    GetTreeNodes = function() return { 10, 11 } end,
    GetNodeInfo = function(_, id)
        if id == 10 then
            return {
                posX = 0, posY = 0, activeRank = 2, maxRanks = 5,
                conditionIDs = { 101 },
                visibleEdges = { { targetNode = 11 } },
                activeEntry = { entryID = 1 }, entryIDs = { 1 },
            }
        end
        return {
            posX = 400, posY = 200, activeRank = 0, maxRanks = 1,
            conditionIDs = { 102 },
            visibleEdges = { { targetNode = 10 } },
            entryIDs = { 2 },
        }
    end,
    GetConditionInfo = function(_, cid)
        condCalls = condCalls + 1
        if cid == 101 then return { spentAmountRequired = 5, isMet = true } end
        return { spentRequired = 10, isMet = false }
    end,
    GetEntryInfo = function(_, eid) return { definitionID = eid } end,
    GetDefinitionInfo = function() return { spellID = 133 } end,
}
readNodes, readConds, readErr, readSpent, readUnspent = ToonAge.modules.ForeverTalents.ReadGrid()
readPlan = ToonAge.modules.ForeverTalents.Layout(readNodes, readConds, { windowWidth = 900, availWidth = 640, spent = readSpent })
readReport = reportText(ToonAge.modules.ForeverTalents.Diagnose(readNodes, readConds))
""")
    g = lua.globals()
    check("read grid returns both nodes", len(g.readNodes), 2)
    check("read spent is the sum of ranks", g.readSpent, 2)
    check("read unspent comes from the currency", g.readUnspent, 4)
    check("header from the live read", M.Header(g.readSpent, g.readUnspent), "2 points spent · 4 to spend")
    check("both conditions were asked for", g.condCalls, 2)
    check("rank subtext was not consulted", g.subtextCalls, 0)
    check("a met gate does not lock", lua.eval("cell(readPlan, 10).locked"), False)
    check("an unmet gate locks only that node", lua.eval("cell(readPlan, 11).locked"), True)
    check("that node's lock names 10 points", lua.eval("cell(readPlan, 11).lockTip"), "Requires 10 points spent")
    check("the met node has no lock text", lua.eval("cell(readPlan, 10).lockTip"), None)
    check("spentAmountRequired is accepted", "condition 101 requires 5 points, gates nodes 10" in g.readReport, True)
    check("spentRequired is accepted", "condition 102 requires 10 points, gates nodes 11" in g.readReport, True)
    check("the edge is kept", len(g.readPlan.lines), 1)
    check("partial badge from the live rank", lua.eval("cell(readPlan, 10).badge"), "2/5")

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
