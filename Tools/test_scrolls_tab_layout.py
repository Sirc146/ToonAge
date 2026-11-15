#!/usr/bin/env python3
"""Scrolls tab: footer wraps to the content width, Light Feather shows bags / target.

The footer sentence is one FontString. A height of 0 does not wrap, so the
scroll frame clips it ("classify correctly the first ti"). The bag count is
DataRow's value, anchored to the row's right edge, which draws blank here.
The note underneath is what remains: "need 20  bank 0".

Usage:  python3 Tools/test_scrolls_tab_layout.py [-v]
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

FOOTER = (
    "Read from each item's own tooltip (its Classes: and Requires lines), not from a list, "
    "so new scrolls classify correctly the first time you loot them. Hover any item for "
    "the same answer on its tooltip."
)


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


PRELUDE = r"""
ToonAge = { modules = {}, Data = {}, Utils = {} }
function ToonAge:RegisterModule(name, module)
    self.modules[name] = module
    self[name] = module
end
function ToonAge:GetModule(name)
    local mod = self.modules[name]
    if not mod or mod._disabled then return nil end
    return mod
end
ToonAge._ApplyBackdrop = function() end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
GameTooltip = setmetatable({}, { __index = function() return function() end end })

local function strip(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    return (text:gsub("|r", ""))
end

local function Widget(kind)
    local f = {
        _kind = kind, _children = {}, _regions = {}, _width = 0, _height = 0,
        _fontSize = 10, _text = "", _wordWrap = false, _anchors = {}, _shown = true,
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
    function f:SetSize(w, h) self._width = w; self._height = h end
    function f:SetWidth(w) self._width = w end
    function f:SetHeight(h) self._height = h end
    function f:GetWidth() return self._width or 0 end
    function f:GetHeight() return self._height or 0 end
    function f:SetPoint(point, rel, relPoint, x, y)
        self._anchors[#self._anchors + 1] = {
            point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0,
        }
    end
    function f:ClearAllPoints() self._anchors = {} end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetTextColor() end
    function f:SetJustifyH(j) self._justify = j end
    function f:SetWordWrap(v) self._wordWrap = v and true or false end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:GetStringWidth()
        return math.max(#strip(self._text), 1) * ((self._fontSize or 10) * 0.5)
    end
    function f:GetStringHeight()
        -- Height 0 is the Forever case: the string does not wrap, so the
        -- scroll frame clips the single line at the right edge.
        local size = self._fontSize or 10
        local natural = self:GetStringWidth()
        local width = self._width or 0
        local canWrap = self._wordWrap and width > 0 and (self._height or 0) > 0
        if not canWrap then return size + 2 end
        return math.max(1, math.ceil(natural / width)) * (size + 2)
    end
    function f:SetScript() end
    function f:EnableMouse() end
    function f:SetDrawLayer() end
    function f:SetColorTexture() end
    function f:SetTexture() end
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

function CreateFrame(kind, _, parent)
    local f = Widget(kind or "Frame")
    if type(parent) == "table" and parent._children then
        f._parent = parent
        parent._children[#parent._children + 1] = f
    end
    return f
end

function lastAnchor(widget)
    local list = widget._anchors
    return list[#list]
end
"""


def load_layout():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    return lua


def test_footer_wraps_to_content_width():
    lua = load_layout()
    lua.execute(f'FOOTER = {FOOTER!r}')
    # Content column beside the sidebar: Core/UI.lua contentWidth is 667.
    lua.execute(r"""
        content = CreateFrame("Frame")
        content:SetWidth(667)
        local L = ToonAge.Layout
        WIDTH = L:Width(content)
        START = -8
        NEXT = L:Paragraph(content, START, FOOTER, { color = "dim" })
        FS = content._regions[#content._regions]
    """)
    g = lua.globals()
    fs = g.FS
    width = float(g.WIDTH)
    advance = float(g.START) - float(g.NEXT)
    one_line = float(fs._fontSize) + 2
    check("footer width is the content width", float(fs._width) == width, True)
    check("footer width stays inside the pane", float(fs._width) <= 667 - 28, True)
    check("footer word wrap is on", bool(fs._wordWrap), True)
    check("footer is not left at height 0", float(fs._height) > one_line, True)
    check("footer advance covers the wrapped lines", advance > one_line + 8, True)
    # The live clip was mid-word. A wrapped string's box is inside the pane.
    check("footer box ends at the content width",
          14 + float(fs._width) <= 667, True)


def test_feather_count_is_inside_the_row():
    lua = load_layout()
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Infrastructure/AddonBridge.lua"))
    lua.execute(read("Data/Forever/Reagents.lua"))
    lua.execute(read("Modules/Forever/Restock.lua"))
    lua.execute(r"""
        TA = ToonAge
        TA.IsForever = true
        TA.db = {}
        GetItemCount = function(id, bank)
            if id ~= 17056 then return 0 end
            if bank == true then return 6 end
            return 4
        end
        content = CreateFrame("Frame")
        content:SetWidth(667)
        TA.ForeverRestock:Draw(content, -8)
        ROW = nil
        for i = 1, #content._children do
            local child = content._children[i]
            if child._laKind == "DataRow" and child.value and child.value:GetText() == "4 / 20" then
                ROW = child
            end
        end
    """)
    g = lua.globals()
    row = g.ROW
    check("Light Feather row was drawn", row is not None, True)
    if row is None:
        return
    anchor = g.lastAnchor(row.value)
    note = str(row.note._text or "")
    check("bag count text is bags over the settings target", str(row.value._text), "4 / 20")
    check("bag count is not anchored to the right edge", anchor.point, "TOPLEFT")
    check("bag count has a width inside the row", float(row.value._width or 0) > 0, True)
    if anchor.point == "TOPRIGHT" or anchor.point == "RIGHT":
        right = float(row._width) + float(anchor.x or 0)
    else:
        right = float(anchor.x or 0) + float(row.value._width or 0)
    check("bag count ends before the row's right edge", right <= float(row._width) - 8, True)
    check("bank count stays on the note", "bank 2" in note, True)
    check("need stays on the note", "need 16" in note, True)


def test_counts_are_marked_unverified():
    restock = read("Modules/Forever/Restock.lua")
    manifest = read("Data/Forever/ApiManifest.lua")
    api = read("Core/Compat/API.lua")
    check("restock reads counts through Compat.ItemCounts", "ItemCounts" in restock, True)
    check("ItemCounts asks includeBank false then true",
          "includeBank" in api and "GetItemCount" in api, True)
    for name in ("C_Item.GetItemCount", "C_Container.GetItemCount", "GetItemCount"):
        check(f"Forever manifest lists {name} as a call site", name in manifest, True)
    # The manifest is call sites, not a probe result. Which function Forever
    # actually implements cannot be known from this tree.
    check("the unprovable client answer is marked UNVERIFIED", "UNVERIFIED" in restock, True)


def main():
    test_footer_wraps_to_content_width()
    test_feather_count_is_inside_the_row()
    test_counts_are_marked_unverified()
    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
