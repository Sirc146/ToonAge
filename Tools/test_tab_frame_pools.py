#!/usr/bin/env python3
"""Repeated tab renders must not allocate frames.

The in-game self-test (Modules/Infrastructure/TestHarness.lua
CountDescendants, then the perf loop in SuitePerf) counts every descendant
of the content and side panes that has no _laKind. That count is the
"frames discarded per re-render". Layout rows set _laKind and are skipped.
Anything else is reported as orphaned.

A Mage on Forever showed Talents 112, Professions 14, Spells 6. This drives
the same render functions twice. The second pass must call CreateFrame zero
times, and CountDescendants must stay 0. The 112-frame talent case is 3
trees, 52 nodes (one button and one glow each), 3 holders, the scroll, its
child, and the three frames UIPanelScrollFrameTemplate adds.

Usage:  python3 Tools/test_tab_frame_pools.py [-v]
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
    IsSecret = function() return false end,
    Glyph = function() return "-" end,
    GetPlayerName = function() return "Mage" end,
    GetPlayerLevel = function() return 17 end,
    GetPlayerClassLocalized = function() return "Mage" end,
    GetPlayerClass = function() return "MAGE" end,
    GetPlayerRace = function() return "Human", "Human" end,
    GetPlayerSpec = function() return nil, nil end,
    GetSpecLabel = function() return "" end,
    GetAverageIlvl = function() return 0, 0 end,
    InferRole = function() return "Caster" end,
    RankNumberFromSubtext = function() return nil end,
}
ToonAge._ApplyBackdrop = function() end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = "ChatFontNormal"
UIParent = nil

created = 0
linesMade = 0

local function Widget(kind, name)
    local f = {
        kind = kind, name = name, _children = {}, _regions = {},
        _shown = true, scripts = {}, _text = "", _fontSize = 10,
        _points = {},
    }
    local mt = {
        __index = function(_, key)
            if type(key) ~= "string" then return nil end
            if key == "GetChildren" then
                return function(self) return unpack(self._children) end
            end
            -- Data fields stay nil. Unknown WoW methods are no-ops so a
            -- texture call does not have to be listed to draw the grid.
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
        local pt = { a = a, b = b, c = c, d = d, e = e }
        self._points[#self._points + 1] = pt
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
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:SetScript(ev, fn) self.scripts[ev] = fn end
    function f:GetScript(ev) return self.scripts[ev] end
    function f:SetFrameLevel(n) self.level = n end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:GetStringWidth()
        return string.len(self._text or "") * (self._fontSize or 10) * 0.5
    end
    function f:GetStringHeight() return (self._fontSize or 10) + 2 end
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
        linesMade = linesMade + 1
        local line = Widget("Line")
        line._parent = self
        self._lines = self._lines or {}
        self._lines[#self._lines + 1] = line
        return line
    end
    function f:SetScrollChild(child)
        self._scrollChild = child
        if child then child:SetParent(self) end
    end
    function f:GetScrollChild() return self._scrollChild end
    function f:SetVerticalScroll(n) self.scroll = n end
    function f:GetVerticalScroll() return self.scroll or 0 end
    function f:EnableMouse() end
    function f:EnableMouseWheel() end
    return f
end

function CreateFrame(kind, name, parent, template)
    created = created + 1
    local f = Widget(kind or "Frame", name)
    f.template = template
    if name then _G[name] = f end
    if parent then f:SetParent(parent) end
    if template == "UIPanelScrollFrameTemplate" then
        local barName = (name or "Scroll") .. "ScrollBar"
        local bar = CreateFrame("Slider", barName, f)
        CreateFrame("Button", barName .. "ScrollUpButton", bar)
        CreateFrame("Button", barName .. "ScrollDownButton", bar)
    end
    if template == "InputBoxTemplate" or template == "BackdropTemplate" then
        f._template = template
    end
    return f
end

UIParent = CreateFrame("Frame", "UIParent")

-- Same rule as Modules/Infrastructure/TestHarness.lua CountDescendants.
function CountDescendants(f)
    if not (f and f.GetChildren) then return 0 end
    local n = 0
    for _, c in ipairs({ f:GetChildren() }) do
        if not c._laKind then
            n = n + 1 + CountDescendants(c)
        end
    end
    return n
end

function CountAll(f)
    if not (f and f.GetChildren) then return 0 end
    local n = 0
    for _, c in ipairs({ f:GetChildren() }) do
        n = n + 1 + CountAll(c)
    end
    return n
end

function Rebuild(pane)
    if pane and ToonAge.Layout and ToonAge.Layout.ReleasePane then
        ToonAge.Layout:ReleasePane(pane)
    end
    if not (pane and pane.GetChildren) then return end
    for _, child in ipairs({ pane:GetChildren() }) do
        if child.Hide then child:Hide() end
        if child.SetParent then child:SetParent(nil) end
    end
end

GameTooltip = {
    SetOwner = function() end,
    SetText = function() end,
    AddLine = function() end,
    Show = function() end,
    Hide = function() end,
}

function UnitLevel() return 17 end
function UnitClass() return "Mage", "MAGE" end
function UnitName() return "Mage" end
function GetBuildInfo() return "Forever", "70938", "date", 16001 end
"""


def load_talents(lua):
    lua.execute(PRELUDE)
    lua.execute(read("Modules/Forever/Talents.lua"))
    lua.execute(r"""
ToonAge.Layout = { PAD = 14, C_DIM = { 0.45, 0.43, 0.40 }, C_WARNING = { 1, 0.65, 0.2 } }
function ToonAge.Layout:Width() return 640 end
function ToonAge.Layout:SectionHeader(_, y, title)
    self.headerTitle = title
    return y - 26
end
function ToonAge.Layout:Paragraph(_, y) return y - 16 end
function ToonAge.Layout:Finish(parent, y)
    parent:SetHeight(math.max(math.floor(math.abs(y) + 20), 40))
end

local function nodes(perTree)
    local out, id = {}, 1
    for tree = 1, #perTree do
        for i = 1, perTree[tree] do
            local n = {
                id = id, treeID = tree, posX = (i - 1) * 100, posY = 0,
                rank = 0, max = 1, name = "N" .. id, conditionIDs = {}, edges = {},
            }
            if id == 1 then n.rank, n.max = 2, 5 end
            if id == 2 then n.conditionIDs = { 9 } end
            if id == 1 then n.edges = { { targetNode = 2 } } end
            out[#out + 1] = n
            id = id + 1
        end
    end
    return out
end

wideNodes = nodes({ 18, 17, 17 })
smallNodes = nodes({ 2 })
conds = { [9] = { spentRequired = 5, isMet = false } }

local view = CreateFrame("Frame")
view:SetHeight(402)
content = CreateFrame("Frame")
content:SetSize(667, 400)
content:SetParent(view)
content._laPane = true
ToonAge.UI = { frame = { GetWidth = function() return 900 end } }

local M = ToonAge.modules.ForeverTalents
local function draw(set)
    M.ReadGrid = function() return set, conds, nil, 3, 4 end
    M._treeScroll = 0
    local before = created
    local beforeLines = linesMade
    M:Render(content, nil)
    return created - before, linesMade - beforeLines
end

firstNew, firstLines = draw(wideNodes)
raw = CountAll(content)
orphans = CountDescendants(content)
local function snapshot()
    local scroll = _G.TATalentTreeScroll
    local child = scroll and scroll:GetScrollChild()
    local buttons, shown, badge, locked = {}, 0, nil, false
    local function walk(f)
        if not f then return end
        if f.kind == "Button" and f.id and f._shown and f._parent and f._parent._shown ~= false then
            local pt = f._points and f._points[1]
            buttons[f.id] = { frame = f, x = pt and pt.d or nil, y = pt and pt.e or nil, regions = #f._regions }
            shown = shown + 1
            for _, region in ipairs(f._regions or {}) do
                if region._text and region._text ~= "" then badge = region._text end
            end
            if f._locked and f.lock and f.lock._shown then locked = true end
        end
        for _, c in ipairs({ f:GetChildren() }) do walk(c) end
    end
    walk(child)
    local ids = {}
    for id in pairs(buttons) do ids[#ids + 1] = id end
    table.sort(ids)
    return { n = shown, buttons = buttons, ids = ids, badge = badge, locked = locked,
             scroll = scroll, kind = scroll and scroll._laKind or nil }
end
snap = snapshot()
secondNew, secondLines = draw(wideNodes)
snap2 = snapshot()
sameButtons = true
if #snap.ids ~= #snap2.ids then sameButtons = false end
for _, id in ipairs(snap.ids) do
    local a, b = snap.buttons[id], snap2.buttons[id]
    if not a or not b or a.frame ~= b.frame or a.x ~= b.x or a.y ~= b.y or a.regions ~= b.regions then
        sameButtons = false
    end
end
raw2 = CountAll(content)
orphans2 = CountDescendants(content)
thirdNew = draw(smallNodes)
rawSmall = CountAll(content)
fourthNew = draw(wideNodes)
rawBack = CountAll(content)
orphansBack = CountDescendants(content)
local again = snapshot()
backSame = snap.buttons[1] and again.buttons[1] and snap.buttons[1].frame == again.buttons[1].frame
""")


def load_professions(lua):
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Character/ProfessionBatch.lua"))
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(r"""
content = CreateFrame("Frame")
content:SetSize(667, 400)
content:SetFrameLevel(4)
content:SetFrameStrata("MEDIUM")
content._laPane = true
side = CreateFrame("Frame")
side:SetSize(184, 400)
side:SetFrameLevel(4)
side._laPane = true
ToonAge.ProfessionSkills = { Collect = function()
    return { reader = "skillinfo", cards = { { id = 197, name = "Tailoring", rank = 23, max = 75 } } }
end }
ToonAge.UI = { contentChild = content, sideChild = side, activeTab = "professions" }
local B = ToonAge.modules.ProfessionBoard
local PB = ToonAge.ProfessionBatch
local before = created
B:Render(content, side)
firstNew = created - before
orphans = CountDescendants(content) + CountDescendants(side)
local function boxes()
    local n, marked, text = 0, 0, nil
    for _, box in pairs(PB.boxes) do
        n = n + 1
        if box._laKind then marked = marked + 1 end
        if box.fieldKey == "n" then text = box:GetText() end
    end
    return n, marked, text
end
boxCount, marked, _ = boxes()
PB.boxes.n:SetText("7")
Rebuild(content)
Rebuild(side)
local again = created
B:Render(content, side)
secondNew = created - again
orphans2 = CountDescendants(content) + CountDescendants(side)
boxCount2, marked2, kept = boxes()
""")


def test_professions():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    load_professions(lua)
    g = lua.globals()
    check("profession form has 14 fields", g.boxCount, 14)
    check("profession fields are marked reused", g.marked, 14)
    check("first profession render reports 0 orphans", g.orphans, 0)
    check("profession redraw creates no frames", g.secondNew, 0)
    check("profession redraw reports 0 orphans", g.orphans2, 0)
    check("profession redraw keeps 14 fields", g.boxCount2, 14)
    check("profession redraw keeps the typed batch size", g.kept, "7")


def load_spells(lua):
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Forever/MageGuidance.lua"))
    lua.execute(read("Modules/Forever/Rotation.lua"))
    lua.execute(r"""
content = CreateFrame("Frame")
content:SetSize(667, 800)
content:SetFrameLevel(4)
content._laPane = true
side = CreateFrame("Frame")
side:SetSize(184, 400)
side:SetFrameLevel(4)
side._laPane = true
ToonAge.UI = { frame = { GetWidth = function() return 900 end }, contentChild = content, sideChild = side }
ToonAge.Caps = { Call = function(path, ...)
    local fn = _G[path]
    if type(fn) ~= "function" then return false, "missing" end
    return true, fn(...)
end }
local M = ToonAge.modules.ForeverRotation
local before = created
M:Render(content, side)
firstNew = created - before
orphans = CountDescendants(content) + CountDescendants(side)
local scroll = _G.TAMageGuideCopyScroll
local copy = _G.TAMageGuideCopy
local notes = _G.TAMageGuideNotes
present = (scroll and copy and notes) and 1 or 0
copyText = copy and copy:GetText() or ""
Rebuild(content)
Rebuild(side)
local again = created
M:Render(content, side)
secondNew = created - again
orphans2 = CountDescendants(content) + CountDescendants(side)
local function marked(f) return f and f._laKind ~= nil end
marks = (marked(scroll) and marked(copy) and marked(notes)) and 1 or 0
copyText2 = copy and copy:GetText() or ""
""")


def test_spells():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    load_spells(lua)
    g = lua.globals()
    check("spell guide builds its scroll and both fields", g.present, 1)
    check("spell guide frames are marked reused", g.marks, 1)
    check("first spells render reports 0 orphans", g.orphans, 0)
    check("spells redraw creates no frames", g.secondNew, 0)
    check("spells redraw reports 0 orphans", g.orphans2, 0)
    check("spells redraw keeps the feedback text",
          g.copyText2 == g.copyText and g.copyText not in ("", None), True)


def test_talents():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    load_talents(lua)
    g = lua.globals()
    check("talent grid is the 112-frame Mage shape", g.raw, 112)
    check("first talent render reports 0 orphaned frames", g.orphans, 0)
    check("talent redraw creates no frames", g.secondNew, 0)
    check("talent redraw creates no lines", g.secondLines, 0)
    check("talent redraw keeps 112 frames", g.raw2, 112)
    check("talent redraw still reports 0 orphans", g.orphans2, 0)
    check("talent redraw keeps every node button", g.sameButtons, True)
    check("partial talent keeps its rank badge", g.snap2.badge, "2/5")
    check("gated talent stays locked", g.snap2.locked, True)
    check("the scroll is marked reused", g.snap.kind, "ForeverTalent")
    check("a smaller tree creates no frames", g.thirdNew, 0)
    check("a smaller tree drops the unused nodes", g.rawSmall < 112, True)
    check("growing back creates no frames", g.fourthNew, 0)
    check("growing back restores 112 frames", g.rawBack, 112)
    check("growing back reports 0 orphans", g.orphansBack, 0)
    check("growing back reuses the first button", g.backSame, True)


def main():
    test_talents()
    test_professions()
    test_spells()
    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
