#!/usr/bin/env python3
"""
ToonAge -- Forever talent grid
==============================
Columns and rows are the rank order of that tree's own posX and posY.
A Rogue tree is 12 by 7. A Warlock tree is 11 by 9, 52 nodes. Neither
shape is a clamp. A gated node carries its own lock. posY that grows
upward is flipped. Node size follows the tab-bar widths, then the grid
shrinks to the content width. A tree taller than the space under the
points header scrolls on its own; the header stays put.

Usage:  python3 Tools/test_forever_talents.py [-v]
"""
import struct
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


# The 13 talent frames. Masters are 64, the small cuts are 32, the badge is
# a wide chip, and the line texture is a short strip. All are white plus alpha.
TALENT_TGA = {
    "talent_square.tga": (64, 64),
    "talent_square_32.tga": (32, 32),
    "talent_circle.tga": (64, 64),
    "talent_circle_32.tga": (32, 32),
    "talent_square_focus.tga": (64, 64),
    "talent_square_focus_32.tga": (32, 32),
    "talent_circle_focus.tga": (64, 64),
    "talent_circle_focus_32.tga": (32, 32),
    "talent_glow_circle.tga": (64, 64),
    "talent_badge_fill.tga": (32, 16),
    "talent_badge_border.tga": (32, 16),
    "talent_edge.tga": (16, 8),
    "talent_arrow.tga": (32, 32),
}


def audit_textures():
    frame = ROOT / "Media" / "frame"
    icons = ROOT / "Media" / "icons"
    present = sorted(p.name for p in frame.glob("talent_*.tga"))
    check("Media/frame holds the 13 talent textures", present, sorted(TALENT_TGA))
    for name, (w, h) in TALENT_TGA.items():
        check(f"{name} stays out of Media/icons", (icons / name).is_file(), False)
        path = frame / name
        if not path.is_file():
            check(f"{name} is type 2 {w}x{h} 32-bit", None, (2, w, h, 32))
            check(f"{name} is white with alpha", False, True)
            continue
        data = path.read_bytes()
        hdr = data[:18]
        got_w, got_h = struct.unpack_from("<HH", hdr, 12)
        bpp = hdr[16]
        check(f"{name} is type 2 {w}x{h} 32-bit", (hdr[2], got_w, got_h, bpp), (2, w, h, 32))
        white = False
        if hdr[2] == 2 and bpp == 32 and got_w and got_h and len(data) >= 18 + hdr[0] + got_w * got_h * 4:
            pix = data[18 + hdr[0]:]
            white = True
            saw_alpha = False
            for i in range(got_w * got_h):
                b, g, r, a = pix[i * 4:i * 4 + 4]
                if a:
                    saw_alpha = True
                    if r != 255 or g != 255 or b != 255:
                        white = False
                        break
            white = white and saw_alpha
        check(f"{name} is white with alpha", white, True)


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
    -- Rogue's measured shape: 12 distinct x, 7 distinct y.
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

-- Warlock's measured shape: 11 distinct x, 9 distinct y, 52 nodes.
-- 11 by 9 is 99 cells; only 52 are filled, and every column and row
-- still appears at least once.
function buildWarlock()
    local nodes = {}
    local id = 1
    local function put(x, y)
        add(nodes, id, x * 100, y * 100, 0, 1, {}, {})
        id = id + 1
    end
    for x = 0, 10 do
        local y = x
        if y > 8 then y = y - 9 end
        put(x, y)
    end
    local seen = {}
    for i = 1, #nodes do
        seen[nodes[i].posX .. ":" .. nodes[i].posY] = true
    end
    for y = 0, 8 do
        for x = 0, 10 do
            if #nodes >= 52 then break end
            local key = (x * 100) .. ":" .. (y * 100)
            if not seen[key] then
                put(x, y)
                seen[key] = true
            end
        end
        if #nodes >= 52 then break end
    end
    return nodes, {}
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
    audit_textures()
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
    check("hover and selection use a thicker ring", M.RING_PX > 1, True)
    check("the gold ring is 3px", M.RING_PX, 3)
    check("the glow extends past the node", M.GLOW_OUTSET >= 4, True)

    theme = M.Theme
    check("maxed is pale yellow", round(theme.maxed[1] * 255), 251)
    check("maxed green channel", round(theme.maxed[2] * 255), 224)
    check("maxed blue channel", round(theme.maxed[3] * 255), 143)
    check("available is green", round(theme.available[1] * 255), 70)
    check("available green channel", round(theme.available[2] * 255), 200)
    check("available blue channel", round(theme.available[3] * 255), 106)
    check("partial is the pale frame", round(theme.partial[1] * 255), 245)
    check("partial green channel", round(theme.partial[2] * 255), 247)
    check("partial blue channel", round(theme.partial[3] * 255), 250)
    check("locked frame is the dim grey", round(theme.locked[1] * 255), 122)
    check("locked green channel", round(theme.locked[2] * 255), 130)
    check("locked blue channel", round(theme.locked[3] * 255), 140)
    check("gold is the hover colour", round(theme.gold[1] * 255), 232)
    check("gold green channel", round(theme.gold[2] * 255), 179)
    check("gold blue channel", round(theme.gold[3] * 255), 90)
    check("locked talents are dimmed", M.LOCK_ALPHA, 0.5)
    check("the lock uses the shared icon", "util_lock_16" in M.LOCK_TEXTURE, True)
    check("the lock stays in Media/icons", "Media\\icons\\" in M.LOCK_TEXTURE, True)

    tex = M.TEX
    check("square master lives in Media/frame", "Media\\frame\\talent_square.tga" in tex.square, True)
    check("circle master lives in Media/frame", "Media\\frame\\talent_circle.tga" in tex.circle, True)
    check("40px uses the square master", M.FrameFile("square", False, 40), tex.square)
    check("36px still uses the square master", M.FrameFile("square", False, 36), tex.square)
    check("28px uses the square 32 cut", M.FrameFile("square", False, 28), tex.square32)
    check("hover on a circle uses the focus master", M.FrameFile("circle", True, 40), tex.circleFocus)
    check("hover on a small circle uses the focus 32 cut", M.FrameFile("circle", True, 28), tex.circleFocus32)
    check("a square entry is a square frame", M.Shape(1), "square")
    check("a capstone square entry is a square frame", M.Shape(14), "square")
    check("a circle entry is a circle frame", M.Shape(2), "circle")
    check("a missing entry type is a circle frame", lua.eval("ToonAge.modules.ForeverTalents.Shape(nil)"), "circle")
    check("a required edge is an arrow", M.EdgeArrow(3), True)
    check("a sufficient edge is an arrow", M.EdgeArrow(2), True)
    check("a visual-only edge stays a line", M.EdgeArrow(0), False)
    check("an edge with no type stays a line", lua.eval("ToonAge.modules.ForeverTalents.EdgeArrow(nil)"), False)
    check("the glow texture is talent_glow_circle", "talent_glow_circle.tga" in tex.glow, True)
    check("the badge has a fill and a border", "talent_badge_fill.tga" in tex.badgeFill and "talent_badge_border.tga" in tex.badgeBorder, True)
    check("a 5-point lock says what it requires", M.LockTip(5), "Requires 5 points spent")
    check("a 30-point lock says what it requires", M.LockTip(30), "Requires 30 points spent")
    check("an open node has no lock text", lua.eval("ToonAge.modules.ForeverTalents.LockTip(nil)"), None)

    lua.execute("nodes, conds = build()")
    lua.execute("plan = place(900, 640, nodes, conds)")
    plan = lua.globals().plan
    check("twelve columns", plan.columns, 12)
    check("seven rows", plan.rows, 7)
    check("rogue grid is 568 wide", plan.width, 568)
    # 7*40 + 6*8. Fits a 368px pane.
    check("rogue tree is 328 tall", plan.height, 328)
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
    check("an untyped edge uses talent_edge", "talent_edge.tga" in plan.lines[1].texture, True)
    check("that line is not an arrow", plan.lines[1].arrow, False)

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
    lua.execute("window = place(568, 568, nodes, conds)")
    check("the tree fits the 568px minimum width", lua.eval("window.width") <= 568, True)

    # Warlock is a different shape from the same layout. 11 distinct posX,
    # 9 distinct posY, 52 filled cells. Nothing in the module names 11 or 9.
    lua.execute("wnodes, wconds = buildWarlock()")
    lua.execute("wplan = place(900, 640, wnodes, wconds)")
    wplan = lua.globals().wplan
    check("warlock has 52 nodes", len(wplan.cells), 52)
    check("warlock has eleven columns", wplan.columns, 11)
    check("warlock has nine rows", wplan.rows, 9)
    check("warlock keeps 40px nodes", wplan.nodePx, 40)
    check("warlock grid is not scaled at 640", wplan.scale, 1)
    # 11*40 + 10*8.
    check("warlock grid is 520 wide", wplan.width, 520)
    # 9*40 + 8*8 = 424. The in-game estimate was about 468; this is that
    # tree at the real node size and gap, and it is still past 368.
    check("warlock tree is 424 tall", wplan.height, 424)
    check("warlock is taller than a 368px pane", wplan.height > 368, True)
    check("rogue fits a 368px pane", plan.height <= 368, True)

    lua.execute("roguePane, rogueScrolls = ToonAge.modules.ForeverTalents.TreePane(plan.height, 368)")
    lua.execute("warPane, warScrolls = ToonAge.modules.ForeverTalents.TreePane(wplan.height, 368)")
    g = lua.globals()
    check("rogue pane is the whole tree", g.roguePane, 328)
    check("rogue pane does not scroll", g.rogueScrolls, False)
    check("warlock pane stops at 368", g.warPane, 368)
    check("warlock pane scrolls", g.warScrolls, True)
    # 580 frame, title 34, tabs 30, header ending 34px down: 516 - 34.
    lua.execute("room = ToonAge.modules.ForeverTalents.TreeAvail(0, 34)")
    check("a 580px frame leaves 482px under the header", lua.globals().room, 482)
    lua.execute("fitPane, fitScrolls = ToonAge.modules.ForeverTalents.TreePane(wplan.height, room)")
    check("warlock fits the 580px frame", lua.globals().fitScrolls, False)
    check("that pane is the whole warlock tree", lua.globals().fitPane, 424)

    # Two trees that share coordinates must not collapse into one grid.
    lua.execute(r"""
mixed = {
    { id = 1, treeID = 11, posX = 0,   posY = 0, rank = 0, max = 1 },
    { id = 2, treeID = 11, posX = 100, posY = 0, rank = 0, max = 1 },
    { id = 3, treeID = 22, posX = 0,   posY = 0,   rank = 0, max = 1 },
    { id = 4, treeID = 22, posX = 0,   posY = 400, rank = 0, max = 1 },
    { id = 5, treeID = 22, posX = 100, posY = 800, rank = 0, max = 1 },
}
mixedPlans = ToonAge.modules.ForeverTalents.Plans(mixed, {}, { windowWidth = 900, availWidth = 640, spent = 0 })
merged = ToonAge.modules.ForeverTalents.Layout(mixed, {}, { windowWidth = 900, availWidth = 640, spent = 0 })
""")
    check("two trees stay two plans", len(lua.globals().mixedPlans), 2)
    check("the first tree is one row", lua.eval("mixedPlans[1].rows"), 1)
    check("the first tree is two columns", lua.eval("mixedPlans[1].columns"), 2)
    check("the second tree is three rows", lua.eval("mixedPlans[2].rows"), 3)
    check("the second tree is two columns", lua.eval("mixedPlans[2].columns"), 2)
    check("a merged layout would have used the taller tree", lua.eval("merged.rows"), 3)

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
                visibleEdges = { { targetNode = 11, type = 3 } },
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
    GetEntryInfo = function(_, eid)
        if eid == 1 then return { definitionID = eid, type = 1 } end
        return { definitionID = eid, type = 2 }
    end,
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
    check("a required edge uses talent_arrow", "talent_arrow.tga" in g.readPlan.lines[1].texture, True)
    check("that required edge points at the gated node", g.readPlan.lines[1].a == 10 and g.readPlan.lines[1].b == 11, True)
    check("the square entry is a square node", lua.eval("cell(readPlan, 10).shape"), "square")
    check("the circle entry is a circle node", lua.eval("cell(readPlan, 11).shape"), "circle")
    check("partial badge from the live rank", lua.eval("cell(readPlan, 10).badge"), "2/5")
    check("a live node keeps its tree id", lua.eval("readNodes[1].treeID"), 1111)

    # A second config: two trees, same coordinates, different shapes.
    lua.execute(r"""
C_Traits.GetConfigInfo = function() return { treeIDs = { 11, 22 } } end
C_Traits.GetTreeCurrencyInfo = function() return { { quantity = 1 } } end
C_Traits.GetTreeNodes = function(id)
    if id == 11 then return { 1, 2 } end
    return { 3, 4, 5 }
end
C_Traits.GetNodeInfo = function(_, id)
    local pos = {
        [1] = { 0, 0 }, [2] = { 300, 0 },
        [3] = { 0, 0 }, [4] = { 0, 400 }, [5] = { 300, 800 },
    }
    local p = pos[id]
    return { posX = p[1], posY = p[2], activeRank = 0, maxRanks = 1, entryIDs = { id } }
end
splitNodes = ToonAge.modules.ForeverTalents.ReadGrid()
splitPlans = ToonAge.modules.ForeverTalents.Plans(splitNodes, {}, { windowWidth = 900, availWidth = 640, spent = 0 })
""")
    check("the live read keeps both trees", len(lua.globals().splitNodes), 5)
    check("live plans do not merge the trees", len(lua.globals().splitPlans), 2)
    check("live first tree is 2 by 1", lua.eval("splitPlans[1].columns") == 2 and lua.eval("splitPlans[1].rows") == 1, True)
    check("live second tree is 2 by 3", lua.eval("splitPlans[2].columns") == 2 and lua.eval("splitPlans[2].rows") == 3, True)

    # Draw both shapes into a mocked window. The header stays on the content
    # frame. The scroll child is the tree. A 402px viewport leaves 368px
    # under the header (the pane that a 9-row tree overflows).
    lua.execute(r"""
local function widget()
    local f = { kids = {}, points = {}, scripts = {} }
    function f:SetSize(w, h) self.w, self.h = w, h end
    function f:SetWidth(w) self.w = w end
    function f:SetHeight(h) self.h = h end
    function f:GetWidth() return self.w or 0 end
    function f:GetHeight() return self.h or 0 end
    function f:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function f:ClearAllPoints() self.points = {} end
    function f:SetParent(p) self.parent = p end
    function f:GetParent() return self.parent end
    function f:CreateTexture() return widget() end
    function f:CreateFontString() return widget() end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    function f:EnableMouse() end
    function f:EnableMouseWheel(v) self.wheel = v end
    function f:Hide() self.hidden = true end
    function f:Show() self.hidden = false end
    function f:SetFrameLevel(n) self.level = n end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetScrollChild(c) self.child = c; if c then c.parent = self end end
    function f:GetScrollChild() return self.child end
    function f:SetVerticalScroll(n) self.scroll = n end
    function f:GetVerticalScroll() return self.scroll or 0 end
    function f:GetVerticalScrollRange()
        local ch = self.child and (self.child.h or 0) or 0
        local h = self.h or 0
        if ch > h then return ch - h end
        return 0
    end
    function f:SetAllPoints() end
    function f:SetTexture() end
    function f:SetColorTexture() end
    function f:SetAlpha() end
    function f:SetDesaturated() end
    function f:SetVertexColor() end
    function f:SetText() end
    function f:SetTextColor() end
    function f:SetBlendMode() end
    return f
end

CreateFrame = function(kind, name, parent, template)
    local f = widget()
    f.kind, f.name, f.template = kind, name, template
    f.parent = parent
    if parent and parent.kids then parent.kids[#parent.kids + 1] = f end
    if name then _G[name] = f end
    return f
end

ToonAge.Layout = { PAD = 14, C_DIM = { 0.5, 0.5, 0.5 } }
function ToonAge.Layout:Width() return 640 end
function ToonAge.Layout:SectionHeader(parent, y, title)
    self.headerParent = parent
    self.headerTitle = title
    return y - 26
end
function ToonAge.Layout:Finish(parent, y)
    parent:SetHeight(math.max(math.floor(math.abs(y) + 20), 40))
    self.finishY = y
end

local view = widget()
view:SetHeight(402)   -- 368px pane + the 34px header offset
local content = widget()
content.parent = view
talentContent = content

ToonAge.UI = { frame = { GetWidth = function() return 900 end } }

local function buttons(root)
    local n = 0
    for _, holder in ipairs(root.kids or {}) do
        for _, c in ipairs(holder.kids or {}) do
            if c.kind == "Button" then n = n + 1 end
        end
    end
    return n
end

local function show(nodes, conds)
    ToonAge.modules.ForeverTalents._treeScroll = 0
    ToonAge.modules.ForeverTalents.ReadGrid = function()
        return nodes, conds, nil, 3, 2
    end
    ToonAge.modules.ForeverTalents:Render(content, nil)
    local scroll = _G.TATalentTreeScroll
    local child = scroll:GetScrollChild()
    return {
        buttons = buttons(child),
        tree = child.h,
        pane = scroll.h,
        range = scroll:GetVerticalScrollRange(),
        template = scroll.template,
        title = ToonAge.Layout.headerTitle,
        contentH = content.h,
        headerOnContent = ToonAge.Layout.headerParent == content,
        headerOnChild = ToonAge.Layout.headerParent == child,
    }
end

warSnap = show(wnodes, wconds)
rogueSnap = show(nodes, conds)
""")
    g = lua.globals()
    war, rogue = g.warSnap, g.rogueSnap
    check("warlock draws 52 buttons", war.buttons, 52)
    check("warlock scroll child is the 424px tree", war.tree, 424)
    check("warlock pane is 368px", war.pane, 368)
    check("warlock scroll range is the overflow", war.range, 56)
    check("warlock header stays on the content frame", war.headerOnContent, True)
    check("warlock header is not the scroll child", war.headerOnChild, False)
    check("warlock header names the points", "points spent" in war.title, True)
    check("warlock content matches the viewport", war.contentH, 402)
    check("warlock scroll uses the panel template", war.template, "UIPanelScrollFrameTemplate")
    check("rogue draws every node", rogue.buttons, len(plan.cells))
    check("rogue scroll child is the 328px tree", rogue.tree, 328)
    check("rogue pane is the whole tree", rogue.pane, 328)
    check("rogue scroll range is zero", rogue.range, 0)
    check("rogue header stays on the content frame", rogue.headerOnContent, True)
    check("rogue header is not the scroll child", rogue.headerOnChild, False)
    check("rogue content is only as tall as the tree", rogue.contentH < 402, True)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
