#!/usr/bin/env python3
"""Tests for Modules/Forever/Talents.lua Plan Mode, Node Detail, What-If, and pooled dock.

Verifies:
- M.NodeDetail (rank, gate, prereqs, unlocks, missing ID)
- M.PlanRoute (deep chains, ranked ancestor skip, cycle safety, gate arithmetic, zero spend calls)
- M.WhatIfRank (non-spending rank projection, unspent budget, 0-unspent +1 preview)
- M.GetNextPlannedPoint (no target, active route, gate blocker, maxed target, combat secret)
- Pooled TATalentDetailDock: 0 CreateFrame calls on second render, CountDescendants == 0,
  node click / Set Plan Target / What-If toggle in-place with zero C_Traits spend calls.

Usage:  python3 Tools/test_forever_talents_plan.py [-v]
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
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


PRELUDE = r"""
ToonAge = { modules = {}, Data = {}, flavor = "forever", IsForever = true, version = "test" }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
ToonAge.Utils = {
    IsSecret = function(v) return type(v) == "table" and v._secret == true end,
    Glyph = function() return "-" end,
    GetPlayerName = function() return "Examplechar" end,
    GetPlayerLevel = function() return 25 end,
    GetPlayerClassLocalized = function() return "Mage" end,
    GetPlayerClass = function() return "MAGE" end,
    GetPlayerRace = function() return "Human", "Human" end,
}
ToonAge._ApplyBackdrop = function() end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = "ChatFontNormal"
UIParent = nil

Enum = {
    TraitNodeEntryType = { SpendSquare = 1, SpendCapstoneSquare = 14 },
    TraitEdgeType = { VisualOnly = 0, SufficientForAvailability = 2, RequiredForAvailability = 3 },
}

issecretvalue = function(v) return type(v) == "table" and v._secret == true end

spendCalls = 0
createdFrames = 0

local function Widget(kind, name)
    local f = {
        kind = kind, name = name, _children = {}, _regions = {},
        _shown = true, scripts = {}, _text = "", _fontSize = 10,
        _points = {}, _tint = nil,
    }
    local mt = {
        __index = function(_, key)
            if type(key) ~= "string" then return nil end
            if key == "GetChildren" then
                return function(self) return unpack(self._children) end
            end
            local head = key:sub(1, 3)
            if head == "Set" or head == "Get" or head == "Ena" or head == "Is"
                or key == "Hide" or key == "Show" or key == "ClearAllPoints" then
                return function() end
            end
            return nil
        end,
    }
    setmetatable(f, mt)
    function f:SetParent(parent)
        if self._parent and self._parent._children then
            for i = #self._parent._children, 1, -1 do
                if self._parent._children[i] == self then
                    table.remove(self._parent._children, i)
                end
            end
        end
        self._parent = parent
        if type(parent) == "table" and parent._children then
            local seen = false
            for i = 1, #parent._children do
                if parent._children[i] == self then seen = true end
            end
            if not seen then parent._children[#parent._children + 1] = self end
        end
    end
    function f:GetParent() return self._parent end
    function f:ClearAllPoints() self._points = {} end
    function f:SetPoint(a, b, c, d, e)
        self._points[#self._points + 1] = { a = a, b = b, c = c, d = d, e = e }
    end
    function f:SetAllPoints(rel)
        self:ClearAllPoints()
        self:SetPoint("ALL", rel or self._parent)
    end
    function f:SetSize(w, h) self.w, self.h = w, h end
    function f:SetWidth(w) self.w = w end
    function f:SetHeight(h) self.h = h end
    function f:GetWidth() return self.w or 0 end
    function f:GetHeight() return self.h or 0 end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetScript(ev, fn) self.scripts[ev] = fn end
    function f:GetScript(ev) return self.scripts[ev] end
    function f:SetFrameLevel(n) self.level = n end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:SetVertexColor(r, g, b, a) self._tint = { r, g, b, a } end
    function f:SetColorTexture(r, g, b, a) self._colorTex = { r, g, b, a } end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:GetStringWidth() return string.len(self._text or "") * 5 end
    function f:GetStringHeight() return 12 end
    function f:CreateTexture()
        local tex = Widget("Texture")
        tex._parent = self
        self._regions[#self._regions + 1] = tex
        return tex
    end
    function f:CreateFontString()
        local fs = Widget("FontString")
        fs._parent = self
        self._regions[#self._regions + 1] = fs
        return fs
    end
    function f:CreateLine()
        local line = Widget("Line")
        line._parent = self
        self._lines = self._lines or {}
        self._lines[#self._lines + 1] = line
        return line
    end
    function f:SetScrollChild(ch) self._scrollChild = ch end
    function f:GetScrollChild() return self._scrollChild end
    function f:SetVerticalScroll(v) self._vscroll = v end
    function f:GetVerticalScroll() return self._vscroll or 0 end
    return f
end

function CreateFrame(kind, name, parent, template)
    createdFrames = createdFrames + 1
    local f = Widget(kind, name)
    if parent then f:SetParent(parent) end
    if name then _G[name] = f end
    if template == "UIPanelScrollFrameTemplate" then
        local bar = CreateFrame("Slider", name and (name .. "ScrollBar") or nil, f)
        f.ScrollBar = bar
    end
    return f
end

function CountDescendants(frame)
    if not frame or not frame.GetChildren then return 0 end
    local n = 0
    for _, child in ipairs({ frame:GetChildren() }) do
        if not child._laKind then
            n = n + 1 + CountDescendants(child)
        end
    end
    return n
end

UnitLevel = function() return 25 end

-- Synthetic 5-node tree with prerequisites and a 10-point gate:
-- 101 (Arcane Subtlety, 2/2, row 1) -> 102 (Arcane Focus, 0/5, row 2) -> 103 (Arcane Mind, 0/5, row 3, gate 10)
-- 104 (Improved Fireball, 3/5, row 1, no edges)
-- 105 (Ignite, 0/5, row 2, visual-only edge from 104)
local TREE_NODES = {
    [101] = {
        posX = 100, posY = 100, activeRank = 2, maxRanks = 2,
        entryIDs = { 201 }, conditionIDs = {},
        visibleEdges = { { targetNode = 102, type = 3 } },
    },
    [102] = {
        posX = 100, posY = 200, activeRank = 0, maxRanks = 5,
        entryIDs = { 202 }, conditionIDs = { 501 },
        visibleEdges = { { targetNode = 103, type = 3 } },
    },
    [103] = {
        posX = 100, posY = 300, activeRank = 0, maxRanks = 5,
        entryIDs = { 203 }, conditionIDs = { 502 },
        visibleEdges = {},
    },
    [104] = {
        posX = 200, posY = 100, activeRank = 3, maxRanks = 5,
        entryIDs = { 204 }, conditionIDs = {},
        visibleEdges = { { targetNode = 105, type = 0 } },
    },
    [105] = {
        posX = 200, posY = 200, activeRank = 0, maxRanks = 5,
        entryIDs = { 205 }, conditionIDs = { 501 },
        visibleEdges = {},
    },
}
local NAMES = {
    [301] = "Arcane Subtlety",
    [302] = "Arcane Focus",
    [303] = "Arcane Mind",
    [304] = "Improved Fireball",
    [305] = "Ignite",
}
local CONDS = {
    [501] = { spentRequired = 5, isMet = true },
    [502] = { spentRequired = 10, isMet = false },
}

C_ClassTalents = {
    GetActiveConfigID = function() return 77 end,
}
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1 } } end,
    GetTreeNodes = function() return { 101, 102, 103, 104, 105 } end,
    GetNodeInfo = function(_, id) return TREE_NODES[id] end,
    GetEntryInfo = function(_, entryID)
        return { definitionID = entryID + 100, type = 1 }
    end,
    GetDefinitionInfo = function(defID)
        return { spellID = defID }
    end,
    GetConditionInfo = function(_, cid) return CONDS[cid] end,
    GetTreeCurrencyInfo = function() return { { quantity = 2 } } end,
    -- Poison write APIs: Plan Mode must NEVER call any of these.
    PurchaseRank = function() spendCalls = spendCalls + 1; error("PurchaseRank forbidden") end,
    SetSelection = function() spendCalls = spendCalls + 1; error("SetSelection forbidden") end,
    CommitConfig = function() spendCalls = spendCalls + 1; error("CommitConfig forbidden") end,
}
C_Spell = {
    GetSpellName = function(sid) return NAMES[sid] end,
    GetSpellTexture = function() return 135812 end,
}
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Forever/Talents.lua"))

    # Activate Modern Azeroth with Mage class pack
    lua.execute('ToonAge.Theme:Select("modern_azeroth", "class", "MAGE")')

    # 1. Pure NodeDetail tests
    res = lua.execute("""
        local M = ToonAge:GetModule("ForeverTalents")
        local nodes, conds, err, spent, unspent = M.ReadGrid()
        local d102 = M.NodeDetail(nodes, conds, 102, spent)
        local d103 = M.NodeDetail(nodes, conds, 103, spent)
        local dNil = M.NodeDetail(nodes, conds, 9999, spent)
        return {
            err = err, spent = spent, unspent = unspent,
            n102 = d102.name, r102 = d102.rank, m102 = d102.max,
            l102 = d102.locked,
            p102_count = #d102.prereqs, p102_name = d102.prereqs[1] and d102.prereqs[1].name,
            p102_met = d102.prereqs[1] and d102.prereqs[1].met,
            u102_count = #d102.unlocks, u102_name = d102.unlocks[1] and d102.unlocks[1].name,
            l103 = d103.locked, tip103 = d103.lockTip,
            dNil = dNil == nil,
        }
    """)
    check("ReadGrid succeeds with spent=5, unspent=2", (res.err, res.spent, res.unspent), (None, 5, 2))
    check("NodeDetail 102 name/rank/max", (res.n102, res.r102, res.m102), ("Arcane Focus", 0, 5))
    check("NodeDetail 102 unlocked", res.l102, False)
    check("NodeDetail 102 prereq is Arcane Subtlety (met)", (res.p102_count, res.p102_name, res.p102_met), (1, "Arcane Subtlety", True))
    check("NodeDetail 102 unlocks Arcane Mind", (res.u102_count, res.u102_name), (1, "Arcane Mind"))
    check("NodeDetail 103 locked with tip", (res.l103, res.tip103), (True, "Requires 10 points spent"))
    check("NodeDetail unknown node returns nil", res.dNil, True)

    # 2. Pure PlanRoute tests (chain + gate math + cycle safety + maxed + invalid)
    res = lua.execute("""
        local M = ToonAge:GetModule("ForeverTalents")
        local nodes, conds, _, spent = M.ReadGrid()

        -- Target 103: 101 is already 2/2 (skipped), 102 needs 1 pt (spent 5->6),
        -- then 103 has gate 10 so gateNeed = 10 - 6 = 4, and 103 needs 5 pts.
        local r103 = M.PlanRoute(nodes, conds, 103, spent)

        -- Already maxed target 101
        local r101 = M.PlanRoute(nodes, conds, 101, spent)

        -- Invalid target
        local rBad = M.PlanRoute(nodes, conds, 9999, spent)

        -- Cyclic graph safety check
        local cycNodes = {
            { id = 1, name = "Alpha", posX = 0, posY = 0, rank = 0, max = 1,
              edges = { { targetNode = 2, type = 3 } } },
            { id = 2, name = "Beta", posX = 0, posY = 10, rank = 0, max = 1,
              edges = { { targetNode = 1, type = 3 } } },
        }
        local rCyc = M.PlanRoute(cycNodes, {}, 2, 0)

        return {
            valid = r103.valid,
            stepCount = #r103.steps,
            step1_id = r103.steps[1] and r103.steps[1].id,
            step1_pts = r103.steps[1] and r103.steps[1].pointsNeeded,
            step1_gateNeed = r103.steps[1] and r103.steps[1].gateNeed,
            step2_id = r103.steps[2] and r103.steps[2].id,
            step2_pts = r103.steps[2] and r103.steps[2].pointsNeeded,
            step2_gateNeed = r103.steps[2] and r103.steps[2].gateNeed,
            totalNeeded = r103.totalPointsNeeded,
            inPath101 = r103.inPath[101] ~= nil,
            inPath102 = r103.inPath[102],
            inPath103 = r103.inPath[103],
            edge102_103 = r103.inPathEdge["102:103"] == true,
            edge103_102 = r103.inPathEdge["103:102"] == true,
            hasHonest = type(r103.honestNote) == "string" and #r103.honestNote > 10,
            maxedValid = r101.valid,
            maxedFlag = r101.alreadyMaxed,
            maxedSteps = #r101.steps,
            badValid = rBad.valid,
            cycValid = rCyc.valid,
            cycSteps = #rCyc.steps,
            spendCalls = spendCalls,
        }
    """)
    check("PlanRoute 103 valid", res.valid, True)
    check("PlanRoute 103 has 2 steps (skips already-ranked 101)", res.stepCount, 2)
    check("PlanRoute 103 step 1 is 102 (1 pt, 0 gateNeed)", (res.step1_id, res.step1_pts, res.step1_gateNeed), (102, 1, 0))
    check("PlanRoute 103 step 2 is 103 (5 pts, 4 gateNeed)", (res.step2_id, res.step2_pts, res.step2_gateNeed), (103, 5, 4))
    check("PlanRoute 103 totalPointsNeeded = 1 + 4 + 5 = 10", res.totalNeeded, 10)
    check("PlanRoute 103 inPath maps 102->1, 103->2, omits 101", (res.inPath101, res.inPath102, res.inPath103), (False, 1, 2))
    check("PlanRoute 103 inPathEdge covers both edge directions", (res.edge102_103, res.edge103_102), (True, True))
    check("PlanRoute includes honestNote", res.hasHonest, True)
    check("PlanRoute maxed target 101 reports alreadyMaxed with 0 steps", (res.maxedValid, res.maxedFlag, res.maxedSteps), (True, True, 0))
    check("PlanRoute invalid target returns valid=false", res.badValid, False)
    check("PlanRoute cyclic graph terminates safely with 2 steps", (res.cycValid, res.cycSteps), (True, 2))
    check("PlanRoute never invokes C_Traits spend APIs", res.spendCalls, 0)

    # 3. WhatIfRank non-spending projection
    res = lua.execute("""
        local M = ToonAge:GetModule("ForeverTalents")
        local nodes, conds, _, spent = M.ReadGrid()
        local route = M.PlanRoute(nodes, conds, 103, spent)
        local c102 = { id = 102, rank = 0, max = 5 }
        local c103 = { id = 103, rank = 0, max = 5 }
        local c104 = { id = 104, rank = 3, max = 5 }

        M.whatIfEnabled = false
        local rOff, dOff = M.WhatIfRank(c102, route, 2)

        M.whatIfEnabled = true
        local r102, d102 = M.WhatIfRank(c102, route, 2)
        local r103, d103 = M.WhatIfRank(c103, route, 2)
        local r104, d104 = M.WhatIfRank(c104, route, 2)
        local rZero, dZero = M.WhatIfRank(c102, route, 0)
        M.whatIfEnabled = false

        return {
            off = { rOff, dOff },
            p102 = { r102, d102 },
            p103 = { r103, d103 },
            p104 = { r104, d104 },
            zero = { rZero, dZero },
            mutated = c102.rank ~= 0 or c103.rank ~= 0,
            spendCalls = spendCalls,
        }
    """)
    check("WhatIfRank OFF returns base rank (0, 0)", (res.off[1], res.off[2]), (0, 0))
    check("WhatIfRank ON with 2 unspent projects 102 to 1 (+1)", (res.p102[1], res.p102[2]), (1, 1))
    check("WhatIfRank ON with 2 unspent projects 103 to 1 (+1)", (res.p103[1], res.p103[2]), (1, 1))
    check("WhatIfRank ON leaves off-route 104 untouched (3, 0)", (res.p104[1], res.p104[2]), (3, 0))
    check("WhatIfRank ON with 0 unspent previews +1 on first step", (res.zero[1], res.zero[2]), (1, 1))
    check("WhatIfRank never mutates cell.rank", res.mutated, False)
    check("WhatIfRank never spends points", res.spendCalls, 0)

    # 4. GetNextPlannedPoint (Now-tab accessor + combat secret guard)
    res = lua.execute("""
        local M = ToonAge:GetModule("ForeverTalents")
        local nodes, conds, _, spent, unspent = M.ReadGrid()

        M.planTargetID = nil
        local noPlan = M.GetNextPlannedPoint(nodes, conds, spent, unspent)

        M.planTargetID = 103
        local active = M.GetNextPlannedPoint(nodes, conds, spent, unspent)

        -- Gate blocker test: if 102 is already ranked 1/5, next step is 103 with gateNeed=4
        local nodesGated = {}
        for i, n in ipairs(nodes) do
            local cp = {}
            for k, v in pairs(n) do cp[k] = v end
            if cp.id == 102 then cp.rank = 1 end
            nodesGated[i] = cp
        end
        local gated = M.GetNextPlannedPoint(nodesGated, conds, 6, 1)

        -- Already maxed target
        M.planTargetID = 101
        local maxed = M.GetNextPlannedPoint(nodes, conds, spent, unspent)

        -- Combat secret unspent
        M._lastUnspent = 2
        M._lastSpent = 5
        M.planTargetID = 103
        local sec = M.GetNextPlannedPoint(nodes, conds, spent, { _secret = true })

        M.planTargetID = nil
        return {
            noPlanHas = noPlan.hasPlan,
            noPlanSum = noPlan.summary,
            activeHas = active.hasPlan,
            activeNext = active.nextNodeName,
            activeGate = active.gateNeed,
            activeSum = active.summary,
            gatedNext = gated.nextNodeName,
            gatedNeed = gated.gateNeed,
            gatedSum = gated.summary,
            maxedFlag = maxed.alreadyMaxed,
            maxedSum = maxed.summary,
            secFlag = sec.isSecret,
            secSum = sec.summary,
        }
    """)
    check("GetNextPlannedPoint without target returns hasPlan=false", res.noPlanHas, False)
    check("GetNextPlannedPoint without target mentions unspent points", "2 unspent points" in res.noPlanSum, True)
    check("GetNextPlannedPoint toward 103 picks Arcane Focus next", (res.activeHas, res.activeNext, res.activeGate), (True, "Arcane Focus", 0))
    check("GetNextPlannedPoint gated target reports gateNeed=4", (res.gatedNext, res.gatedNeed), ("Arcane Mind", 4))
    check("GetNextPlannedPoint gated summary mentions spent gate", "needs 4 more spent in tree" in res.gatedSum, True)
    check("GetNextPlannedPoint maxed target flags alreadyMaxed", (res.maxedFlag, "is maxed" in res.maxedSum), (True, True))
    check("GetNextPlannedPoint combat secret flags isSecret and prefixes (in combat)", (res.secFlag, res.secSum.startswith("(in combat) ")), (True, True))

    # 5. Pooled TATalentDetailDock + interactive click + zero-churn second render
    res = lua.execute("""
        local M = ToonAge:GetModule("ForeverTalents")
        M.selectedID = nil
        M.planTargetID = nil
        M.whatIfEnabled = false

        local scroll = CreateFrame("ScrollFrame", "TATestOuterScroll")
        scroll:SetSize(640, 516)
        local content = CreateFrame("Frame", "TATestContent", scroll)
        content:SetSize(620, 516)
        local side = CreateFrame("Frame", "TATestSide")
        side:SetSize(210, 516)

        -- Pass 1: default render (no selection, no target) -> dock must not be created
        M:Render(content, side)
        local dockBeforeClick = _G.TATalentDetailDock ~= nil
        local orphanPass1 = CountDescendants(content)

        -- Find node button 103 inside TATalentTreeScroll's scrollChild -> holder
        local treeScroll = _G.TATalentTreeScroll
        local treeChild = treeScroll:GetScrollChild()
        local btn103, btn102
        for _, holder in ipairs(treeChild._children) do
            for _, child in ipairs(holder._children) do
                if child.id == 103 then btn103 = child end
                if child.id == 102 then btn102 = child end
            end
        end

        -- Click node 103 -> dock opens
        btn103.scripts.OnClick(btn103)
        local dock = _G.TATalentDetailDock
        local dockShownAfterClick = dock and dock:IsShown() or false
        local titleAfterClick = dock and dock.title:GetText() or ""
        local metaAfterClick = dock and dock.meta:GetText() or ""
        local noteAfterClick = dock and dock.noteLine:GetText() or ""
        local planBtnText1 = dock and dock.planBtn.label:GetText() or ""

        -- Click Set Plan Target
        dock.planBtn.scripts.OnClick(dock.planBtn)
        local targetAfterSet = M.planTargetID
        local planBtnText2 = dock.planBtn.label:GetText()
        local btn102InPlan = btn102._inPlan == true
        local btn103InPlan = btn103._inPlan == true

        -- Toggle What-If ON
        dock.whatIfBtn.scripts.OnClick(dock.whatIfBtn)
        local whatIfTextOn = dock.whatIfBtn.label:GetText()
        local btn102ProjDelta = btn102._projDelta
        local btn102Badge = btn102.badgeText and btn102.badgeText:GetText() or ""

        -- Second full render WITH selectedID + planTargetID + whatIfEnabled active:
        -- must allocate ZERO new frames and keep CountDescendants(content) == 0.
        local beforeSecond = createdFrames
        M:Render(content, side)
        local addedSecond = createdFrames - beforeSecond
        local orphanSecond = CountDescendants(content)

        -- Clear target and deselect node 103 -> dock hides cleanly
        dock.planBtn.scripts.OnClick(dock.planBtn)
        btn103.scripts.OnClick(btn103)
        local dockShownAfterClear = dock:IsShown()

        return {
            dockBeforeClick = dockBeforeClick,
            orphanPass1 = orphanPass1,
            dockShownAfterClick = dockShownAfterClick,
            titleAfterClick = titleAfterClick,
            metaAfterClick = metaAfterClick,
            noteAfterClick = noteAfterClick,
            planBtnText1 = planBtnText1,
            targetAfterSet = targetAfterSet,
            planBtnText2 = planBtnText2,
            btn102InPlan = btn102InPlan,
            btn103InPlan = btn103InPlan,
            whatIfTextOn = whatIfTextOn,
            btn102ProjDelta = btn102ProjDelta,
            btn102Badge = btn102Badge,
            addedSecond = addedSecond,
            orphanSecond = orphanSecond,
            dockShownAfterClear = dockShownAfterClear,
            spendCalls = spendCalls,
        }
    """)
    check("Default render does not create TATalentDetailDock", res.dockBeforeClick, False)
    check("Pass 1 has 0 orphaned descendants", res.orphanPass1, 0)
    check("Clicking node 103 opens TATalentDetailDock", res.dockShownAfterClick, True)
    check("Dock title shows node name, rank, and lock requirement", "Arcane Mind (0/5)" in res.titleAfterClick and "Requires 10 points spent" in res.titleAfterClick, True)
    check("Dock meta shows prereqs and unlocks", "Arcane Focus" in res.metaAfterClick and "Unlocks: none" in res.metaAfterClick, True)
    check("Dock noteLine carries honest non-spending disclaimer", "Never spends points" in res.noteAfterClick, True)
    check("Plan button initially reads Set Plan Target", res.planBtnText1, "Set Plan Target")
    check("Clicking Set Plan Target sets planTargetID=103 and switches label to Clear Target", (res.targetAfterSet, res.planBtnText2), (103, "Clear Target"))
    check("Setting plan target marks route nodes 102 and 103 as _inPlan", (res.btn102InPlan, res.btn103InPlan), (True, True))
    check("Clicking What-If toggles button to What-If: ON and previews 1/5 on node 102", (res.whatIfTextOn, res.btn102ProjDelta, res.btn102Badge), ("What-If: ON", 1, "1/5"))
    check("Second full render with active dock calls CreateFrame 0 times", res.addedSecond, 0)
    check("Second full render with active dock has 0 orphaned descendants", res.orphanSecond, 0)
    check("Clearing target and deselecting node hides dock", res.dockShownAfterClear, False)
    check("Interactive UI flow makes 0 C_Traits spend calls", res.spendCalls, 0)

    passed = sum(1 for r in _results if r)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
