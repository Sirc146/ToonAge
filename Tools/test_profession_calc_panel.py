#!/usr/bin/env python3
"""Professions calculator inputs live in the left-panel slot only.

The right pane keeps the result. Other flavors and other tabs keep the
character block they already had. Empty fields stay unknown. The linen
batch is still 63 gold.

This does not open the game client.
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
ToonAge = { flavor = "forever", IsForever = true, modules = {}, UI = {}, db = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:HasAPI() return true end
ToonAge.Utils = {
    GetPlayerName = function() return "Sirc" end,
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

local function Widget(kind)
    local f = {
        _kind = kind, _children = {}, _regions = {}, _shown = true,
        scripts = {}, _text = "", _fontSize = 10, _width = 0, _height = 0,
        _points = {},
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
    end
    function f:GetParent() return self._parent end
    function f:GetChildren() return unpack(self._children) end
    function f:GetRegions() return unpack(self._regions) end
    function f:Hide() self._shown = false end
    function f:Show() self._shown = true end
    function f:IsShown() return self._shown end
    function f:ClearAllPoints() self._points = {} end
    function f:SetPoint(a, b, c, d, e)
        self._points[#self._points + 1] = { a = a, e = e }
        if type(d) == "number" and type(e) == "number" then
            self._point = { x = d, y = e }
        end
    end
    function f:SetSize(w, h) self._width = w; self._height = h end
    function f:SetWidth(w) self._width = w end
    function f:SetHeight(h) self._height = h end
    function f:GetWidth() return self._width or 0 end
    function f:GetHeight() return self._height or 0 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:SetFontObject() end
    function f:SetTextColor() end
    function f:SetColorTexture() end
    function f:SetDrawLayer() end
    function f:SetVertexColor() end
    function f:SetJustifyH() end
    function f:SetWordWrap() end
    function f:SetTextInsets() end
    function f:SetAutoFocus(v) self._autoFocus = v end
    function f:SetMultiLine() end
    function f:SetFocus() self.focused = true end
    function f:ClearFocus() self.focused = false end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    function f:SetFrameLevel(n) self._level = n end
    function f:GetFrameLevel() return self._level or 1 end
    function f:SetFrameStrata() end
    function f:GetFrameStrata() return "MEDIUM" end
    function f:EnableMouse() end
    function f:EnableMouseWheel() end
    function f:SetVerticalScroll(n) self._scroll = n end
    function f:GetVerticalScroll() return self._scroll or 0 end
    function f:SetScrollChild(child)
        self._scrollChild = child
        if child then child:SetParent(self) end
    end
    function f:GetScrollChild() return self._scrollChild end
    function f:GetStringWidth()
        return string.len(self._text or "") * (self._fontSize or 10) * 0.55
    end
    function f:GetStringHeight() return (self._fontSize or 10) + 2 end
    function f:CreateFontString()
        local fs = Widget("FontString")
        self._regions[#self._regions + 1] = fs
        return fs
    end
    function f:CreateTexture()
        local tex = Widget("Texture")
        self._regions[#self._regions + 1] = tex
        return tex
    end
    return f
end

function CreateFrame(kind, _, parent, template)
    local f = Widget(kind or "Frame")
    f._template = template
    if parent then f:SetParent(parent) end
    if template == "UIPanelScrollFrameTemplate" then
        local bar = CreateFrame("Slider", nil, f)
        CreateFrame("Button", nil, bar)
        CreateFrame("Button", nil, bar)
    end
    return f
end

GameTooltip = { lines = {} }
function GameTooltip:SetOwner() end
function GameTooltip:SetText(text) self.lines = { text } end
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = text end
function GameTooltip:Show() end
function GameTooltip:Hide() self.lines = {} end

function PaneText(pane)
    local parts = {}
    local function walk(frame)
        if not frame then return end
        if frame._shown ~= false and type(frame._text) == "string" and frame._text ~= "" then
            parts[#parts + 1] = frame._text
        end
        if frame.label and frame.label._text and frame.label._text ~= "" and frame._shown ~= false then
            parts[#parts + 1] = frame.label._text
        end
        for _, child in ipairs({ frame:GetChildren() }) do walk(child) end
        for _, region in ipairs({ frame:GetRegions() }) do
            if region._shown ~= false and type(region._text) == "string" and region._text ~= "" then
                parts[#parts + 1] = region._text
            end
        end
    end
    walk(pane)
    return table.concat(parts, "\n")
end

function CountBoxes(pane)
    local n = 0
    local function walk(frame)
        if not frame or not frame.GetChildren then return end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child._kind == "EditBox" and child._shown and not child.hidden then n = n + 1 end
            walk(child)
        end
    end
    walk(pane)
    return n
end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Core/LeftPanel.lua"))
    lua.execute(read("Modules/Character/ProfessionBatch.lua"))
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(r"""
content = CreateFrame("Frame")
content:SetSize(667, 400)
content._laPane = true
sidebar = CreateFrame("Frame")
sidebar:SetSize(210, 500)
sideScroll = CreateFrame("ScrollFrame", nil, sidebar)
side = CreateFrame("Frame")
side:SetSize(184, 120)
side._laPane = true
sideScroll:SetScrollChild(side)
ToonAge.ProfessionSkills = { Collect = function()
    return { reader = "skillinfo", cards = { { id = 197, name = "Tailoring", rank = 23, max = 75 } } }
end }
ToonAge.UI = {
    contentChild = content, sideChild = side, sideScroll = sideScroll,
    sidebar = sidebar, sideWidth = 184, activeTab = "professions",
}
local B = ToonAge.modules.ProfessionBoard
local PB = ToonAge.ProfessionBatch
ToonAge.UI._leftPanelDefer = true
B:Render(content, side)
mounted = ToonAge:MountLeftPanel(ToonAge.UI, "professions")
ToonAge.UI._leftPanelDefer = nil
slot = ToonAge.UI._leftSlot
slotBoxes = CountBoxes(slot.content)
sideBoxes = CountBoxes(side)
contentBoxes = CountBoxes(content)
rightText = PaneText(content)
needShown = string.find(rightText, "Need: ", 1, true) ~= nil
    and string.find(rightText, "Reagent 1 price", 1, true) ~= nil
    and string.find(rightText, "Output 1 listing", 1, true) ~= nil
spec = ToonAge:LeftPanelSpec("professions")
top = nil
for _, pt in ipairs(slot.scroll._points) do
    if pt.a == "TOPLEFT" then top = pt.e end
end
slotBelow = top == -(4 + side:GetHeight() + 4)

local function Row(key)
    local function walk(frame)
        if not frame or not frame.GetChildren then return nil end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child.fieldKey == key then return child end
            local found = walk(child)
            if found then return found end
        end
    end
    return walk(slot.content)
end
local xs, ws = {}, {}
local aligned = true
local trunc = false
for _, key in ipairs({ "n", "vendor", "lostCraft", "reag1price", "out1count", "seconds" }) do
    local row = Row(key)
    local box = PB.boxes[key]
    if not row or not row._point or not box or not box._point then aligned = false
    else
        xs[box._point.x] = true
        ws[row.label._width] = true
        local measured = row.label:GetStringWidth() or 0
        if measured + 4 > (row.label._width or 0) then trunc = true end
    end
end
local nx, nw = 0, 0
for _ in pairs(xs) do nx = nx + 1 end
for _ in pairs(ws) do nw = nw + 1 end
oneColumn = aligned and nx == 1 and nw == 1 and not trunc

local vendor = Row("vendor")
vendor.scripts.OnEnter(vendor)
vendorTip = table.concat(GameTooltip.lines, "\n")
tipVerbatim = string.find(vendorTip, "Vendor buy for the whole batch, in gold. Enter 0 when there is no vendor material.", 1, true) ~= nil
local price = Row("reag1price")
price.scripts.OnEnter(price)
priceTip = table.concat(GameTooltip.lines, "\n")
priceVerbatim = string.find(priceTip, "Reagent 1 listing price, in gold each. Not a completed sale.", 1, true) ~= nil

reagentsOpen = string.find(PaneText(slot.content), "- Reagents", 1, true) ~= nil
outputOpen = string.find(PaneText(slot.content), "- Output", 1, true) ~= nil
depositsOpen = string.find(PaneText(slot.content), "- Deposits", 1, true) ~= nil

local function ClickLabel(text)
    local fn
    local function walk(frame)
        if fn or not frame or not frame.GetChildren then return end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child.lbl and child.lbl._text == text and child.scripts.OnClick then
                fn = child.scripts.OnClick
                return
            end
            walk(child)
        end
    end
    walk(slot.content)
    if fn then fn() end
end
ClickLabel("- Deposits")
savedClosed = ToonAge.db.professionCalcGroups and ToonAge.db.professionCalcGroups.deposits == false
depositHidden = PB.boxes.lostCraft and PB.boxes.lostCraft.hidden == true
reagentsStill = string.find(PaneText(slot.content), "- Reagents", 1, true) ~= nil
ToonAge.db.professionCalcGroups.deposits = nil
B:Render(content, side)
ToonAge:MountLeftPanel(ToonAge.UI, "professions")
depositBack = PB.boxes.lostCraft and PB.boxes.lostCraft._shown == true and PB.boxes.lostCraft.hidden ~= true

-- Leaving the tab releases the slot. A tab that did not register does not mount.
ToonAge:ReleaseLeftPanel(ToonAge.UI)
releasedHidden = true
for _, box in pairs(PB.boxes) do
    if box._shown then releasedHidden = false end
end
otherMount = ToonAge:MountLeftPanel(ToonAge.UI, "character")

-- Another flavor draws the character block and no calculator.
ToonAge.IsForever = false
ToonAge.flavor = "tbc"
ToonAge:ClearLeftPanel("professions")
fresh = CreateFrame("Frame")
fresh:SetSize(184, 400)
fresh._laPane = true
freshContent = CreateFrame("Frame")
freshContent:SetSize(667, 400)
freshContent._laPane = true
B:Render(freshContent, fresh)
classicBoxes = CountBoxes(fresh)
classicText = PaneText(fresh)
onlySide = CreateFrame("Frame")
onlySide:SetSize(184, 400)
onlySide._laPane = true
ToonAge.Layout:CharacterSidebar(onlySide)
sidebarText = PaneText(onlySide)
classicSame = classicText == sidebarText

-- Math is the linen batch, and a blank deposit is unknown rather than zero.
ToonAge.IsForever = true
ToonAge.flavor = "forever"
PB.form = { outputs = 1, reagents = 1, text = {
    n = "1", cut = "0.05", vendor = "1", lostCraft = "", lostRaw = "1", refund = "",
    seconds = "120", reag1need = "30", reag1owned = "20", reag1price = "2",
    reag1buyQty = "10", reag1buyPrice = "3", out1count = "1", out1price = "100",
} }
PB.boxes = nil
blankInput = PB.InputFromForm()
blankUnknown = blankInput.lostCraftDeposit == nil and blankInput.refundableDeposit == nil
blankNotZero = blankInput.lostCraftDeposit ~= 0
linen = PB.CompareBatch({
    n = 1, cut = 0.05, vendorBuy = 1,
    lostCraftDeposit = 2, lostRawDeposit = 1, refundableDeposit = 5,
    activeSeconds = 120,
    reagents = { { need = 30, owned = 20, price = 2, buyQty = 10, buyPrice = 3 } },
    outputs = { { count = 1, price = 100 }, { count = 1, price = 40 } },
})
""")
    g = lua.globals()
    check("the professions slot mounts under the character block", g.mounted, True)
    check("the slot is positioned under the character block", g.slotBelow, True)
    check("the slot holds the calculator fields", g.slotBoxes >= 14, True)
    check("the character block itself has no fields", g.sideBoxes, 0)
    check("the right pane has no fields", g.contentBoxes, 0)
    check("an empty form says what is missing", g.needShown, True)
    check("only professions registered a slot", g.spec.place, "below")
    check("inputs share one column", g.oneColumn, True)
    check("the vendor sentence is the tooltip", g.tipVerbatim, True)
    check("the reagent price sentence is the tooltip", g.priceVerbatim, True)
    check("reagents start open", g.reagentsOpen, True)
    check("output starts open", g.outputOpen, True)
    check("deposits start open", g.depositsOpen, True)
    check("closing deposits is saved on the account", g.savedClosed, True)
    check("a closed group hides its field", g.depositHidden, True)
    check("closing deposits leaves reagents open", g.reagentsStill, True)
    check("a missing saved flag opens the group again", g.depositBack, True)
    check("leaving the tab hides the fields", g.releasedHidden, True)
    check("another tab does not mount the slot", g.otherMount, False)
    check("a non-forever professions tab has no fields", g.classicBoxes, 0)
    check("a non-forever left panel matches the character block", g.classicSame, True)
    check("a blank deposit stays unknown", g.blankUnknown, True)
    check("a blank deposit is not treated as zero", g.blankNotZero, True)
    check("the linen batch is still 63 gold", g.linen.net, 63)
    check("the linen batch is not realized profit", g.linen.realized, False)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
