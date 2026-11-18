#!/usr/bin/env python3
"""Forever Casts tab: spec buttons and the fight summary use the left slot.

The slot is the one from Core/LeftPanel.lua. Registration, build, refresh and
release are exercised here. The right pane keeps What you cast, Opener, and
Compared with the guide. Other flavors do not register. This does not open
the game client.
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
ToonAge = {
    modules = {}, Layout = nil, IsForever = false, flavor = "retail",
    Data = { ForeverCoach = { MAGE = {
        Arcane = { buff = { "Arcane Intellect", "Frost Armor|Mage Armor" }, opener = { "Frostbolt" }, core = { "Arcane Blast" } },
        Fire = { buff = { "Arcane Intellect", "Frost Armor|Mage Armor" }, opener = { "Fireball" }, core = { "Fireball" } },
        Frost = { buff = { "Arcane Intellect", "Frost Armor" }, opener = { "Frostbolt" }, core = { "Frostbolt" } },
    } } },
    charDB = { castLog = { fights = {} }, coachSpec = { MAGE = "Frost" }, coachSpecManual = { MAGE = true } },
    UI = {},
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
ToonAge.Utils = {
    GREEN = "|cFF4AFF7A", ORANGE = "|cFFFF9A1A", RED = "|cFFFF4444", GREY = "|cFF888780",
    Glyph = function() return "*" end,
}
ToonAge._ApplyBackdrop = function() end

local casts = {}
for i = 1, 16 do casts[i] = { (i - 1) * 1.5, 133 } end
casts[17] = { 24, 116 }
casts[18] = { 25.5, 133 }
FIGHT = { stamp = 1700000000, dur = 30, active = 27, casts = casts }
ToonAge.charDB.castLog.fights[1] = FIGHT

function UnitClass() return "Mage", "MAGE" end
function UnitLevel() return 12 end
function InCombatLockdown() return false end
function issecretvalue() return false end
function date() return "03:15" end
function time() return 1700000000 end

C_Spell = { GetSpellName = function(id)
    if id == 133 then return "Fireball" end
    if id == 116 then return "Frostbolt" end
    return nil
end }
Enum = { SpellBookSpellBank = { Player = 0 } }
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function()
        return { name = "Mage", itemIndexOffset = 0, numSpellBookItems = 4 }
    end,
    GetSpellBookItemInfo = function(i)
        local names = { "Fireball", "Frostbolt", "Arcane Intellect", "Frost Armor" }
        return { name = names[i] }
    end,
}
C_UnitAuras = {
    GetAuraDataByIndex = function(_, i)
        if i == 1 then return { name = "Arcane Intellect" } end
        return nil
    end,
}

local function Widget(kind, name)
    local f = {
        _kind = kind, _name = name, _children = {}, _regions = {},
        _shown = true, scripts = {}, _text = "", _fontSize = 10,
        _points = {}, _width = 0, _height = 0, _level = 1, _wrap = false,
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
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:ClearAllPoints() self._points = {} end
    function f:SetPoint(a, b, c, d, e)
        self._points[#self._points + 1] = { a = a, b = b, c = c, d = d, e = e }
    end
    function f:SetSize(w, h) self._width = w; self._height = h end
    function f:SetWidth(w) self._width = w end
    function f:SetHeight(h) self._height = h end
    function f:GetWidth() return self._width or 0 end
    function f:GetHeight() return self._height or 0 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:GetStringWidth()
        return string.len(self._text or "") * (self._fontSize or 10) * 0.5
    end
    function f:GetStringHeight()
        local line = (self._fontSize or 10) + 2
        local tw = self:GetStringWidth()
        local w = self._width or 0
        if self._wrap and w > 1 and tw > w then
            return line * math.ceil(tw / w)
        end
        return line
    end
    function f:SetTextColor(r, g, b, a) self._r, self._g, self._b, self._a = r, g, b, a end
    function f:SetJustifyH() end
    function f:SetWordWrap(v) self._wrap = v and true or false end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    function f:SetFrameLevel(n) self._level = n end
    function f:GetFrameLevel() return self._level or 1 end
    function f:EnableMouse() end
    function f:EnableMouseWheel() end
    function f:SetVerticalScroll(n) self._scroll = n end
    function f:GetVerticalScroll() return self._scroll or 0 end
    function f:SetScrollChild(child)
        self._scrollChild = child
        if child then child:SetParent(self) end
    end
    function f:GetScrollChild() return self._scrollChild end
    function f:SetColorTexture() end
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
    return f
end

function CreateFrame(kind, name, parent, template)
    local f = Widget(kind or "Frame", name)
    f._template = template
    if parent then f:SetParent(parent) end
    if template == "UIPanelScrollFrameTemplate" then
        local bar = CreateFrame("Slider", (name or "Scroll") .. "ScrollBar", f)
        CreateFrame("Button", nil, bar)
        CreateFrame("Button", nil, bar)
    end
    return f
end

GameTooltip = {
    SetOwner = function() end, SetText = function() end, AddLine = function() end,
    Show = function() end, Hide = function() end,
}

function MakeUI()
    local sidebar = CreateFrame("Frame")
    sidebar:SetSize(210, 500)
    sidebar:SetFrameLevel(2)
    local sideScroll = CreateFrame("ScrollFrame")
    sideScroll:SetParent(sidebar)
    sideScroll:SetSize(184, 492)
    local side = CreateFrame("Frame")
    side:SetSize(184, 120)
    side._laPane = true
    sideScroll:SetScrollChild(side)
    return {
        sidebar = sidebar, sideScroll = sideScroll, sideChild = side, sideWidth = 184,
    }
end

function Pane()
    local f = CreateFrame("Frame")
    f:SetSize(660, 400)
    f._laPane = true
    return f
end

function Blob(root)
    local out, seen = {}, {}
    local function walk(frame)
        if type(frame) ~= "table" or seen[frame] then return end
        seen[frame] = true
        if frame.GetText and frame.IsShown and frame:IsShown() then
            local t = frame:GetText()
            if type(t) == "string" and t ~= "" then out[#out + 1] = t end
        end
        if frame.GetRegions then
            for _, region in ipairs({ frame:GetRegions() }) do walk(region) end
        end
        if frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do walk(child) end
        end
    end
    walk(root)
    return table.concat(out, "\n")
end

function ShownCount(root)
    local n, seen = 0, {}
    local function walk(frame)
        if type(frame) ~= "table" or seen[frame] then return end
        seen[frame] = true
        if frame.IsShown and frame:IsShown() and frame.GetText and frame:GetText() ~= "" then
            n = n + 1
        end
        if frame.GetRegions then
            for _, region in ipairs({ frame:GetRegions() }) do walk(region) end
        end
        if frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do walk(child) end
        end
    end
    walk(root)
    return n
end

function ValueX(row)
    local fs = row and row.value
    if not fs then return nil end
    for i = #fs._points, 1, -1 do
        if fs._points[i].a == "TOPLEFT" then return fs._points[i].d end
    end
    return nil
end

function FindRow(root, label)
    local found
    local function walk(frame)
        if found or type(frame) ~= "table" then return end
        if frame._laKind == "DataRow" and frame.label and frame.label:GetText() == label then
            found = frame
            return
        end
        if frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do walk(child) end
        end
    end
    walk(root)
    return found
end

function FindButton(root, label)
    local found
    local function walk(frame)
        if found or type(frame) ~= "table" then return end
        if frame._laKind == "Button" and frame.lbl and frame.lbl:GetText() == label then
            found = frame
            return
        end
        if frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do walk(child) end
        end
    end
    walk(root)
    return found
end

function Fits(fs)
    if not fs then return false end
    local w = fs:GetWidth() or 0
    local tw = fs:GetStringWidth() or 0
    if w <= 0 or w + 0.01 >= tw then return true end
    if fs._wrap and (fs:GetHeight() or 0) + 0.01 >= (fs:GetStringHeight() or 0) then
        return true
    end
    return false
end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Core/LeftPanel.lua"))
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Forever/CastLog.lua"))
    lua.execute(r"""
local TA = ToonAge
local M = TA:GetModule("ForeverCastLog")
ui = MakeUI()
TA.UI = ui

wide = Pane()
wide:SetWidth(400)
TA.Layout:DataRow(wide, -8, { label = "Bag", value = "4 / 20" })
defaultRow = FindRow(wide, "Bag")
defaultValueX = ValueX(defaultRow)
defaultValueW = defaultRow and defaultRow.value:GetWidth() or 0

retail = Pane()
ui._leftPanelDefer = false
M:Render(retail, ui.sideChild)
retailBlob = Blob(retail)
retailReg = TA:LeftPanelSpec("casts")

TA.IsForever = true
TA.flavor = "forever"
ui._leftPanelDefer = true
right = Pane()
M:Render(right, ui.sideChild)
ui._leftPanelDefer = nil
spec = TA:LeftPanelSpec("casts")
hasBuild = spec and type(spec.build) == "function"
hasRefresh = spec and type(spec.refresh) == "function"
hasRelease = spec and type(spec.release) == "function"
place = spec and (spec.place or "below")
mounted = spec and TA:MountLeftPanel(ui, "casts") or false
slot = ui._leftSlot
slotContent = slot and slot.content
slotBlob = slotContent and Blob(slotContent) or ""
rightBlob = Blob(right)
hostW = slot and slot.host and slot.host.width
hostPlace = slot and slot.host and slot.host.place
activeRow = FindRow(slotContent, "Active time")
gcdRow = FindRow(slotContent, "Global cooldowns used")
lengthRow = FindRow(slotContent, "Length")
activeX = ValueX(activeRow)
gcdX = ValueX(gcdRow)
lengthX = ValueX(lengthRow)
labelFits = Fits(activeRow and activeRow.label) and Fits(gcdRow and gcdRow.label)
    and Fits(lengthRow and lengthRow.label)
noteFits = Fits(activeRow and activeRow.note) and Fits(gcdRow and gcdRow.note)
noteTall = activeRow and activeRow.note and (activeRow.note:GetHeight() or 0) > (activeRow.note._fontSize or 10) + 2
frostBtn = FindButton(slotContent, "Frost")
arcaneBtn = FindButton(slotContent, "Arcane")
fireBtn = FindButton(slotContent, "Fire")
frostGold = frostBtn and frostBtn.lbl._r == 1 and frostBtn.lbl._g == 0.82 and frostBtn.lbl._b == 0
arcaneGold = arcaneBtn and arcaneBtn.lbl._r == 1 and arcaneBtn.lbl._g == 0.82 and arcaneBtn.lbl._b == 0
fireGold = fireBtn and fireBtn.lbl._r == 1 and fireBtn.lbl._g == 0.82 and fireBtn.lbl._b == 0
btnWide = frostBtn ~= nil and arcaneBtn ~= nil and fireBtn ~= nil
if btnWide then
    for _, b in ipairs({ frostBtn, arcaneBtn, fireBtn }) do
        if (b:GetWidth() or 0) < (b.lbl:GetStringWidth() or 0) then btnWide = false end
    end
end
activeDanger = activeRow and activeRow.value and activeRow.value._r == 1
    and activeRow.value._g == 0.35 and activeRow.value._b == 0.30
slotScrollShown = slot and slot.scroll:IsShown()
sideScrollShown = ui.sideScroll:IsShown()
if slot and slot.scroll then slot.scroll:SetHeight(50) end
if slot and slot.scroll and slot.scroll:GetScript("OnMouseWheel") then
    slot.scroll:GetScript("OnMouseWheel")(slot.scroll, -1)
end
slotScrolled = slot and slot.scroll:GetVerticalScroll() or 0
sideScrolled = ui.sideScroll:GetVerticalScroll() or 0

refreshed = false
if mounted then
    FIGHT.active = 9
    refreshed = TA:RefreshLeftPanel(ui)
end
refreshBlob = slotContent and Blob(slotContent) or ""
activeAfter = FindRow(slotContent, "Active time")
warnNotRed = activeAfter and activeAfter.value and not (
    activeAfter.value._r == 1 and activeAfter.value._g == 0.35 and activeAfter.value._b == 0.30)

clicked = false
arcaneBtn = FindButton(slotContent, "Arcane")
if arcaneBtn and arcaneBtn:GetScript("OnClick") then
    arcaneBtn:GetScript("OnClick")()
    clicked = TA.charDB.coachSpec.MAGE == "Arcane" and TA.charDB.coachSpecManual.MAGE == true
    TA:RefreshLeftPanel(ui)
end
arcaneNow = FindButton(slotContent, "Arcane")
frostNow = FindButton(slotContent, "Frost")
arcaneGoldNow = arcaneNow and arcaneNow.lbl._r == 1 and arcaneNow.lbl._g == 0.82 and arcaneNow.lbl._b == 0
frostGoldNow = frostNow and frostNow.lbl._r == 1 and frostNow.lbl._g == 0.82 and frostNow.lbl._b == 0

InCombatLockdown = function() return true end
ui._leftPanelDefer = true
combatRight = Pane()
M:Render(combatRight, ui.sideChild)
ui._leftPanelDefer = nil
if TA:LeftPanelSpec("casts") then TA:MountLeftPanel(ui, "casts") end
combatSlot = (ui._leftSlot and ui._leftSlot.content) and Blob(ui._leftSlot.content) or ""
combatRightBlob = Blob(combatRight)

InCombatLockdown = function() return false end
ui._leftPanelDefer = true
backRight = Pane()
M:Render(backRight, ui.sideChild)
ui._leftPanelDefer = nil
if TA:LeftPanelSpec("casts") then TA:MountLeftPanel(ui, "casts") end
backSlot = (ui._leftSlot and ui._leftSlot.content) and Blob(ui._leftSlot.content) or ""

released = TA:ReleaseLeftPanel(ui)
slotHidden = ui._leftSlot and ui._leftSlot.scroll:IsShown() == false
staleShown = (ui._leftSlot and ui._leftSlot.content) and ShownCount(ui._leftSlot.content) or -1
releaseBlob = (ui._leftSlot and ui._leftSlot.content) and Blob(ui._leftSlot.content) or nil
remounted = TA:LeftPanelSpec("casts") and TA:MountLeftPanel(ui, "casts") or false
remountBlob = (ui._leftSlot and ui._leftSlot.content) and Blob(ui._leftSlot.content) or ""

TA.charDB.castLog.fights = {}
ui._leftPanelDefer = true
emptyRight = Pane()
M:Render(emptyRight, ui.sideChild)
ui._leftPanelDefer = nil
emptyReg = TA:LeftPanelSpec("casts")
emptyMount = TA:MountLeftPanel(ui, "casts")
emptyBlob = Blob(emptyRight)
""")
    g = lua.globals()

    def has(blob, text):
        return text in str(blob or "")

    check("default data row keeps the value inset", g.defaultValueX, 260)
    check("default data row keeps the value width", g.defaultValueW, 96)
    check("another flavor does not register a casts slot", g.retailReg, None)
    check("another flavor still draws the summary on the right", has(g.retailBlob, "Active time"), True)
    check("another flavor still draws the spec buttons on the right", has(g.retailBlob, "Arcane"), True)
    check("another flavor still draws the guide on the right", has(g.retailBlob, "Compared with the guide"), True)

    check("forever casts registers a slot", g.spec is not None, True)
    check("the slot build is a function", bool(g.hasBuild), True)
    check("the slot refresh is a function", bool(g.hasRefresh), True)
    check("the slot release is a function", bool(g.hasRelease), True)
    check("the slot sits below the character block", g.place, "below")
    check("the casts slot mounts", bool(g.mounted), True)
    check("the host width is the 184-wide slot", g.hostW, 184)
    check("the mounted place is below", g.hostPlace, "below")
    check("the slot scroll is shown", bool(g.slotScrollShown), True)
    check("the character scroll stays shown", bool(g.sideScrollShown), True)

    check("build draws the spec buttons", has(g.slotBlob, "Arcane") and has(g.slotBlob, "Fire") and has(g.slotBlob, "Frost"), True)
    check("build draws the spec label", has(g.slotBlob, "Your spec:"), True)
    check("build draws active time", has(g.slotBlob, "Active time"), True)
    check("build draws the active-time percent", has(g.slotBlob, "90%"), True)
    check("build draws the active-time note", has(g.slotBlob, "Target is 90%."), True)
    check("build draws global cooldowns used", has(g.slotBlob, "Global cooldowns used"), True)
    check("build draws the cooldown note", has(g.slotBlob, "18 casts out of at most 20 at a 1.5 s global cooldown."), True)
    check("build draws the fight length", has(g.slotBlob, "30 sec"), True)
    check("build draws the cast count", has(g.slotBlob, "36.0 per minute"), True)
    check("build draws the fights-kept line", has(g.slotBlob, "fights kept"), True)
    check("build draws the intellect buff", has(g.slotBlob, "Arcane Intellect is up."), True)
    check("build draws the armor buff", has(g.slotBlob, "Frost Armor is not up."), True)
    check("the label column shares one value x",
          g.activeX is not None and g.activeX == g.gcdX and g.activeX == g.lengthX, True)
    check("summary labels are not clipped", bool(g.labelFits), True)
    check("summary notes are not clipped", bool(g.noteFits), True)
    check("the long active-time note wraps past one line", bool(g.noteTall), True)
    check("spec buttons are at least as wide as their text", bool(g.btnWide), True)
    check("the selected spec button is gold", bool(g.frostGold), True)
    check("an unselected spec button is not gold", bool(g.arcaneGold or g.fireGold), False)
    check("a healthy active time is not red", bool(g.activeDanger), False)
    check("the missing buff text is the existing red", has(g.slotBlob, "|cFFFF4444Frost Armor is not up."), True)
    without_miss = str(g.slotBlob).replace("|cFFFF4444Frost Armor is not up. The guide keeps it active at all times.|r", "")
    check("the buff that is up is not red", "|cFFFF4444" not in without_miss, True)

    check("the right pane keeps what you cast", has(g.rightBlob, "What you cast"), True)
    check("the right pane keeps the opener", has(g.rightBlob, "Opener"), True)
    check("the right pane keeps the guide comparison", has(g.rightBlob, "Compared with the guide"), True)
    check("the right pane keeps a cast name", has(g.rightBlob, "Fireball"), True)
    check("the right pane does not keep the spec buttons", has(g.rightBlob, "Your spec:"), False)
    check("the right pane does not keep active time", has(g.rightBlob, "Active time"), False)
    check("the right pane does not keep the buff check", has(g.rightBlob, "is not up"), False)

    check("the slot scrolls on its own wheel", g.slotScrolled, 24)
    check("the character scroll does not take that wheel", g.sideScrolled, 0)

    check("refresh returns", bool(g.refreshed), True)
    check("refresh updates active time from the same fight", has(g.refreshBlob, "30%"), True)
    check("refresh keeps the cooldown note", has(g.refreshBlob, "18 casts out of at most 20 at a 1.5 s global cooldown."), True)
    check("a short active time is still not red", bool(g.warnNotRed), True)
    check("a spec button still selects that spec", bool(g.clicked), True)
    check("refresh paints the newly selected spec gold", bool(g.arcaneGoldNow), True)
    check("refresh clears gold from the previous spec", bool(g.frostGoldNow), False)

    check("combat keeps the active-time summary", has(g.combatSlot, "Active time"), True)
    check("combat hides the spec buttons", has(g.combatSlot, "Your spec:"), False)
    check("combat hides the buff check", has(g.combatSlot, "is not up"), False)
    check("combat keeps the guide message on the right", has(g.combatRightBlob, "after combat"), True)
    check("leaving combat draws the spec buttons again", has(g.backSlot, "Your spec:"), True)

    check("release runs", bool(g.released), True)
    check("release hides the slot", bool(g.slotHidden), True)
    check("release leaves no shown text in the slot", g.staleShown, 0)
    check("release leaves no readable text in the slot", g.releaseBlob, "")
    check("a later mount builds the slot again", bool(g.remounted), True)
    check("a later mount draws the summary again", has(g.remountBlob, "Active time"), True)

    check("no fight clears the casts registration", g.emptyReg, None)
    check("no fight does not mount a slot", bool(g.emptyMount), False)
    check("no fight keeps the empty line on the right", has(g.emptyBlob, "Nothing recorded yet"), True)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
