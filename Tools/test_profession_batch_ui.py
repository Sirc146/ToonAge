#!/usr/bin/env python3
"""Professions calculator widgets against the real layout and a real rebuild.

Core/UI.lua RebuildChild hides every child of the scroll pane and sets its
parent to nil before the tab draws again. A bare EditBox has no font, so
typed text is invisible, and its default auto-focus steals the keyboard.

The default form is 14 boxes. The measured broken draw had all 14 parented,
none with a font, and no Escape or Enter handler. Hide plus SetParent(nil)
then left parented 0, visible 0, one box still focused, and the typed text
still on that box. This mock does not clear focus or text inside Hide or
SetParent, so that snapshot stays observable. The next draw has to put all
14 back, with a font, both keys, auto-focus off, and the text kept.
Label rectangles come from Core/Layout.lua. This does not open the game client.
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


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


PRELUDE = r"""
ToonAge = { flavor = "forever", IsForever = true, modules = {}, UI = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:HasAPI() return true end
ToonAge.Utils = {
    GetPlayerName = function() return "Tester" end,
    GetPlayerLevel = function() return 12 end,
    GetPlayerClassLocalized = function() return "Mage" end,
    GetPlayerRace = function() return "Human", "Human" end,
    GetSpecLabel = function() return "" end,
    GetAverageIlvl = function() return 0, 0 end,
    InferRole = function() return "Caster" end,
}
ToonAge._ApplyBackdrop = function() end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = { name = "ChatFontNormal" }
Focused = nil

local function Widget(kind)
    local f = {
        _kind = kind, _children = {}, _regions = {}, _log = {},
        _shown = true, hidden = false, _level = 0, _strata = nil,
        _width = 0, _height = 0, _fontSize = 10, _text = "",
        scripts = {},
    }
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
            parent._children[#parent._children + 1] = self
        end
        self._log[#self._log + 1] = "SetParent"
    end
    function f:GetParent() return self._parent end
    function f:GetChildren() return unpack(self._children) end
    function f:GetRegions() return unpack(self._regions) end
    function f:Hide()
        -- Same as the client pane rebuild: hidden, but still focused,
        -- and the characters the player typed are still on the widget.
        self._shown = false
        self.hidden = true
    end
    function f:Show()
        self._shown = true
        self.hidden = false
        self._log[#self._log + 1] = "Show"
        -- A bare EditBox auto-focuses. SetAutoFocus(false) before Show
        -- is what keeps it from taking the keyboard.
        if self._kind == "EditBox" and self._autoFocus ~= false then
            self:SetFocus()
        end
    end
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:IsShown() return self._shown end
    function f:ClearAllPoints() self._point = nil end
    function f:SetPoint(a, b, c, d, e)
        self._log[#self._log + 1] = "SetPoint"
        if type(d) == "number" and type(e) == "number" then
            self._point = { x = d, y = e }
        elseif type(b) == "number" and type(c) == "number" then
            self._point = { x = b, y = c }
        end
    end
    function f:SetSize(w, h) self._width = w; self._height = h end
    function f:SetWidth(w) self._width = w end
    function f:SetHeight(h) self._height = h end
    function f:GetWidth() return self._width or 0 end
    function f:GetHeight() return self._height or 0 end
    function f:SetText(t)
        self._text = t or ""
        -- An EditBox SetText puts the caret at the end. A pane rebuild that
        -- writes every field therefore jumps a mid-string caret.
        if self._kind == "EditBox" then self._cursor = string.len(self._text) end
    end
    function f:GetText() return self._text end
    function f:GetCursorPosition() return self._cursor or 0 end
    function f:SetCursorPosition(pos) self._cursor = pos end
    function f:SetFont(file, size, flags)
        self._font = file
        self._fontSize = size or self._fontSize
        self._fontFlags = flags
    end
    function f:SetFontObject(obj) self._fontObject = obj end
    function f:SetTextColor() end
    function f:SetJustifyH() end
    function f:SetWordWrap() end
    function f:SetTextInsets() end
    function f:SetAutoFocus(v) self._autoFocus = v; self._autoFocusSet = true end
    function f:SetMultiLine(v) self._multiLine = v end
    function f:SetMaxLetters() end
    function f:SetFocus()
        if Focused and Focused ~= self then Focused.focused = false end
        Focused = self
        self.focused = true
    end
    function f:ClearFocus()
        self.focused = false
        if Focused == self then Focused = nil end
    end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    function f:SetFrameLevel(level) self._level = level end
    function f:GetFrameLevel() return self._level or 0 end
    function f:SetFrameStrata(strata) self._strata = strata end
    function f:GetFrameStrata() return self._strata end
    function f:EnableMouse() end
    function f:SetColorTexture() end
    function f:SetTexture() end
    function f:SetTexCoord() end
    function f:SetDrawLayer() end
    function f:CreateFontString()
        local fs = Widget("FontString")
        fs._parent = self
        self._regions[#self._regions + 1] = fs
        return fs
    end
    function f:CreateTexture()
        local tex = Widget("Texture")
        tex._parent = self
        self._regions[#self._regions + 1] = tex
        return tex
    end
    function f:GetStringHeight()
        local size = self._fontSize or 10
        local text = self._text or ""
        local textW = string.len(text) * size * 0.55
        local width = self._width
        if not width or width <= 0 then return math.max(size, 12) end
        local lines = math.max(1, math.ceil(textW / width))
        return lines * (size + 3)
    end
    function f:GetStringWidth()
        local size = self._fontSize or 10
        return string.len(self._text or "") * size * 0.55
    end
    return f
end

function CreateFrame(kind, _, parent, template)
    local f = Widget(kind or "Frame")
    f._template = template
    if parent then f:SetParent(parent) end
    return f
end

GameTooltip = setmetatable({}, { __index = function() return function() end end })

-- Core/UI.lua RebuildChild, the child loop: Hide() then SetParent(nil).
function RebuildChildLike(pane)
    for _, region in ipairs({ pane:GetRegions() }) do
        region:Hide()
        if region.SetText then region:SetText("") end
    end
    for _, child in ipairs({ pane:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
        child._log = {}
    end
end

function LogOrder(box)
    local parentAt, pointAt, showAt
    for i, name in ipairs(box._log) do
        if name == "SetParent" then parentAt = i end
        if name == "SetPoint" and not pointAt then pointAt = i end
        if name == "Show" and not showAt then showAt = i end
    end
    if not parentAt or not pointAt or not showAt then return false end
    return parentAt < pointAt and pointAt < showAt
end

function Collect(pane)
    local labels, boxes = {}, {}
    for _, region in ipairs({ pane:GetRegions() }) do
        if region._shown and region._text and region._text ~= "" and region._point then
            local h = region:GetStringHeight()
            labels[#labels + 1] = {
                top = region._point.y, bottom = region._point.y - h,
                x = region._point.x, w = region._width or 0, h = h, text = region._text,
            }
        end
    end
    for _, child in ipairs({ pane:GetChildren() }) do
        if child._kind == "EditBox" and child._shown and child._point then
            boxes[#boxes + 1] = child
        end
    end
    return labels, boxes
end

function Separated(aTop, aBottom, bTop, bBottom)
    local gap = 2
    if aBottom - bTop >= gap then return true end
    if bBottom - aTop >= gap then return true end
    return false
end

function HorizontalOverlap(ax, aw, bx, bw)
    return ax < bx + bw and bx < ax + aw
end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
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
ToonAge.ProfessionSkills = { Collect = function()
    return { reader = "skillinfo", cards = { { id = 197, name = "Schneiderei", rank = 23, max = 75 } } }
end }
ToonAge.UI = { contentChild = content, sideChild = side, activeTab = "professions" }
local B = ToonAge.modules.ProfessionBoard
local PB = ToonAge.ProfessionBatch

-- Default calculator: 7 shared fields, 5 on the first reagent, 2 on the first output.
B:Render(content, side)

local function Tally(pane)
    local row = {
        total = 0, parented = 0, visible = 0, focused = 0, font = 0,
        escape = 0, enter = 0, template = 0, autoOff = 0, single = 0,
        levelOk = 0, strataOk = 0, fitOk = 0, orderOk = 0,
    }
    for _, box in pairs(PB.boxes) do
        row.total = row.total + 1
        local onPane = false
        for _, child in ipairs({ pane:GetChildren() }) do
            if child == box then onPane = true end
        end
        if onPane then row.parented = row.parented + 1 end
        if box._shown then row.visible = row.visible + 1 end
        if box.focused then row.focused = row.focused + 1 end
        local obj = box._fontObject
        local objName = type(obj) == "table" and obj.name or obj
        if type(box._font) == "string" and box._font ~= "" and (box._fontSize or 0) >= 10 and objName == "ChatFontNormal" then
            row.font = row.font + 1
        end
        if box.scripts.OnEscapePressed then row.escape = row.escape + 1 end
        if box.scripts.OnEnterPressed then row.enter = row.enter + 1 end
        if box._template == "InputBoxTemplate" then row.template = row.template + 1 end
        if box._autoFocus == false then row.autoOff = row.autoOff + 1 end
        if box._multiLine == false then row.single = row.single + 1 end
        if (box._level or 0) >= pane:GetFrameLevel() + 1 then row.levelOk = row.levelOk + 1 end
        if box._strata == nil or box._strata == pane:GetFrameStrata() then row.strataOk = row.strataOk + 1 end
        if box._point and box._point.x + box._width <= pane:GetWidth() and box._width <= 160 and box._width >= 40 then
            row.fitOk = row.fitOk + 1
        end
        if LogOrder(box) then row.orderOk = row.orderOk + 1 end
    end
    return row
end

first = Tally(content)
local probe = PB.boxes.n
probe:SetText("7")
probe:SetFocus()
RebuildChildLike(content)
local parented, visible, focused = 0, 0, 0
for _, box in pairs(PB.boxes) do
    local onPane = false
    for _, child in ipairs({ content:GetChildren() }) do
        if child == box then onPane = true end
    end
    if onPane then parented = parented + 1 end
    if box._shown then visible = visible + 1 end
    if box.focused then focused = focused + 1 end
end
afterRebuild = {
    parented = parented, visible = visible, focused = focused,
    textKept = (probe:GetText() == "7") and 1 or 0,
}
B:Render(content, side)
second = Tally(content)
textAfter = PB.boxes.n:GetText()
focusAfter = 0
for _, box in pairs(PB.boxes) do if box.focused then focusAfter = focusAfter + 1 end end
local sample = PB.boxes.n
sample:SetFocus()
sample.scripts.OnEscapePressed(sample)
escapeClears = sample.focused == false and sample:GetText() == "7"
sample:SetFocus()
sample.scripts.OnEnterPressed(sample)
enterClears = sample.focused == false and sample:GetText() == "7"
tabMoves = sample.scripts.OnTabPressed ~= nil

RebuildChildLike(content)
PB.form.reagents = 8
PB.form.outputs = 4
content:SetSize(667, 400)
B:Render(content, side)
local labels, boxes = Collect(content)
local lowest = 0
overlap = false
for _, box in ipairs(boxes) do
    local bottom = box._point.y - box._height
    if bottom < lowest then lowest = bottom end
end
for _, label in ipairs(labels) do
    for _, box in ipairs(boxes) do
        local bTop = box._point.y
        local bBottom = bTop - box._height
        if HorizontalOverlap(label.x, label.w, box._point.x, box._width)
            and not Separated(label.top, label.bottom, bTop, bBottom) then
            overlap = true
        end
    end
end
scrollOk = #boxes >= 55 and content:GetHeight() >= math.abs(lowest)
manyCount = #boxes

RebuildChildLike(content)
content:SetSize(280, 400)
B:Render(content, side)
labels, boxes = Collect(content)
local vendorLabel, vendorBox
for _, label in ipairs(labels) do
    if string.find(label.text, "Vendor buy for the whole batch", 1, true) then vendorLabel = label end
end
for _, box in ipairs(boxes) do
    if box.fieldKey == "vendor" then vendorBox = box end
end
narrowWrap = vendorLabel ~= nil and vendorLabel.h > 24
narrowClear = vendorLabel ~= nil and vendorBox ~= nil and (vendorLabel.bottom - vendorBox._point.y) >= 2
narrowOverlap = false
narrowFit = true
for _, box in ipairs(boxes) do
    if not box._point or box._point.x + box._width > content:GetWidth() then narrowFit = false end
end
for _, label in ipairs(labels) do
    for _, box in ipairs(boxes) do
        local bTop = box._point.y
        local bBottom = bTop - box._height
        if HorizontalOverlap(label.x, label.w, box._point.x, box._width)
            and not Separated(label.top, label.bottom, bTop, bBottom) then
            narrowOverlap = true
        end
    end
end

RebuildChildLike(content)
content:SetSize(667, 400)
PB.form.reagents = 1
PB.form.outputs = 2
B:Render(content, side)
local function Put(key, value)
    local box = PB.boxes[key]
    if box then box:SetText(value) end
end
Put("n", "1")
Put("cut", "0.05")
Put("vendor", "1")
Put("lostCraft", "2")
Put("lostRaw", "1")
Put("refund", "5")
Put("seconds", "120")
Put("reag1need", "30")
Put("reag1owned", "20")
Put("reag1price", "2")
Put("reag1buyQty", "10")
Put("reag1buyPrice", "3")
Put("out1count", "1")
Put("out1price", "100")
Put("out2count", "1")
Put("out2price", "40")
for _, button in ipairs({ content:GetChildren() }) do
    if button._kind == "Button" and button.lbl and button.lbl._text == "Calculate batch" and button.scripts.OnClick then
        button.scripts.OnClick()
    end
end
calcNet = PB.lastResult and PB.lastResult.net
local function PaneText()
    local parts = {}
    for _, region in ipairs({ content:GetRegions() }) do
        if region._shown and type(region._text) == "string" and region._text ~= "" then
            parts[#parts + 1] = region._text
        end
    end
    return table.concat(parts, "\n")
end
local function Click(label)
    for _, button in ipairs({ content:GetChildren() }) do
        if button._kind == "Button" and button.lbl and button.lbl._text == label and button.scripts.OnClick then
            button.scripts.OnClick()
        end
    end
end
estimateShown = string.find(PaneText(), "63.0000", 1, true) ~= nil
local draws = 0
local realRender = B.Render
function B:Render(a, b)
    draws = draws + 1
    return realRender(self, a, b)
end
local box = PB.boxes.seconds
box:SetText("1920")
box:SetCursorPosition(2)
box:SetFocus()
local changed = box.scripts.OnTextChanged
local atFirst = draws
if changed then changed(box, true) end
firstDraws = draws - atFirst
firstCursor = box:GetCursorPosition()
firstFocused = box.focused == true
firstText = box:GetText()
afterType = PaneText()
typeClears = changed ~= nil and string.find(afterType, "63.0000", 1, true) == nil and string.find(afterType, "outdated", 1, true) ~= nil
box:SetText("19320")
box:SetCursorPosition(3)
local atSecond = draws
if changed then changed(box, true) end
secondDraws = draws - atSecond
secondCursor = box:GetCursorPosition()
secondFocused = box.focused == true
secondText = box:GetText()
secondOutdated = string.find(PaneText(), "outdated", 1, true) ~= nil and string.find(PaneText(), "63.0000", 1, true) == nil
typeKeepsValue = PB.boxes.n:GetText() == "1"
Click("Calculate batch")
if changed then changed(PB.boxes.n, false) end
falseKeeps = changed ~= nil and string.find(PaneText(), "63.0000", 1, true) ~= nil
local renders = 0
local original = B.Render
function B:Render(a, b)
    renders = renders + 1
    if renders > 3 then error("render loop") end
    return original(self, a, b)
end
for _, box in pairs(PB.boxes) do
    local set = box.SetText
    function box:SetText(value)
        set(self, value)
        local fn = self.scripts.OnTextChanged
        if fn then fn(self, false) end
    end
end
renders = 0
B:Render(content, side)
rebuildOnce = renders == 1
rebuildKeepsValue = PB.boxes.n:GetText() == "1"
rebuildKeepsEstimate = string.find(PaneText(), "63.0000", 1, true) ~= nil
renders = 0
Click("Add output")
addOnce = renders == 1
afterAdd = PaneText()
addClears = string.find(afterAdd, "63.0000", 1, true) == nil and string.find(afterAdd, "Conditional listing estimate", 1, true) == nil and string.find(afterAdd, "outdated", 1, true) ~= nil
tabStill = PB.boxes.n.scripts.OnTabPressed ~= nil
PB.boxes.n:SetFocus()
PB.boxes.n.scripts.OnEscapePressed(PB.boxes.n)
escapeStill = PB.boxes.n.focused == false
""")
    g = lua.globals()
    check("first draw parents 14 boxes", g.first.parented, 14)
    check("first draw shows 14 boxes", g.first.visible, 14)
    check("first draw gives all 14 a font", g.first.font, 14)
    check("first draw gives all 14 an escape handler", g.first.escape, 14)
    check("first draw gives all 14 an enter handler", g.first.enter, 14)
    check("first draw uses InputBoxTemplate on all 14", g.first.template, 14)
    check("first draw turns auto focus off on all 14", g.first.autoOff, 14)
    check("first draw keeps the boxes single line", g.first.single, 14)
    check("first draw does not steal focus", g.first.focused, 0)
    check("after RebuildChild parented is 0", g.afterRebuild.parented, 0)
    check("after RebuildChild visible is 0", g.afterRebuild.visible, 0)
    check("after RebuildChild the focused box stays focused", g.afterRebuild.focused, 1)
    check("after RebuildChild the typed text is still on the box", g.afterRebuild.textKept, 1)
    check("the next draw parents 14 again", g.second.parented, 14)
    check("the next draw shows 14 again", g.second.visible, 14)
    check("the next draw keeps the typed text", g.textAfter, "7")
    check("the next draw clears focus left on the detached box", g.focusAfter, 0)
    check("parent is restored before position and show", g.second.orderOk, 14)
    check("escape clears focus and keeps the text", g.escapeClears, True)
    check("enter clears focus and keeps the text", g.enterClears, True)
    check("tab still moves to the next field", g.tabMoves, True)
    check("box frame level is above the pane", g.second.levelOk, 14)
    check("box strata stays on the pane strata", g.second.strataOk, 14)
    check("a 160-wide box stays inside the pane", g.second.fitOk, 14)
    check("many rows stay inside the scroll height", g.scrollOk, True)
    check("many rows actually draw", g.manyCount >= 55, True)
    check("labels do not cover inputs", g.overlap, False)
    check("a long label wraps on a narrow pane", g.narrowWrap, True)
    check("the wrapped label stays above its input", g.narrowClear, True)
    check("wrapped labels do not cover inputs", g.narrowOverlap, False)
    check("narrow inputs stay inside the pane", g.narrowFit, True)
    check("the button still submits the typed linen batch", g.calcNet, 63)
    check("the successful estimate is on the pane", g.estimateShown, True)
    check("typing dispatches OnTextChanged and drops the old estimate", g.typeClears, True)
    check("the first mid-string edit does not rebuild the pane", g.firstDraws, 0)
    check("the first mid-string edit keeps the caret", g.firstCursor, 2)
    check("the first mid-string edit keeps focus", g.firstFocused, True)
    check("the first mid-string edit keeps the typed text", g.firstText, "1920")
    check("a later keystroke does not rebuild an outdated pane", g.secondDraws, 0)
    check("a later keystroke keeps the caret", g.secondCursor, 3)
    check("a later keystroke keeps focus", g.secondFocused, True)
    check("a later keystroke keeps the typed text", g.secondText, "19320")
    check("the estimate stays visibly outdated", g.secondOutdated, True)
    check("typing keeps the other field value", g.typeKeepsValue, True)
    check("a programmatic text change does not drop the estimate", g.falseKeeps, True)
    check("rebuilding with SetText does not loop", g.rebuildOnce, True)
    check("a rebuild keeps the typed value", g.rebuildKeepsValue, True)
    check("a rebuild keeps the current estimate", g.rebuildKeepsEstimate, True)
    check("adding an output redraws once", g.addOnce, True)
    check("adding an empty output drops the old estimate", g.addClears, True)
    check("tab still works after an edit", g.tabStill, True)
    check("escape still clears focus after an edit", g.escapeStill, True)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
