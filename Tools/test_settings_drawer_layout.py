#!/usr/bin/env python3
"""Settings drawer rows: labels stay left of ON/OFF, sliders reserve their height.

The drawer is about 230px wide. MakeToggleRow used to leave the label at its
natural width, so "Navigation Arrow (compass arrow...)" ran through the OFF
text. MakeSliderRow advanced 36px, which is the caption plus the track and
not the Low/High line OptionsSliderTemplate draws under the track, so the
next row sat on that line.

Usage:  python3 Tools/test_settings_drawer_layout.py [-v]
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

LABELS = (
    "Navigation Arrow (compass arrow pointing to waypoint)",
    "NavHud (transparent FarmHud-style overlay with nodes & waypoints)",
    "World Map Pins (numbered step markers on world map)",
)
# DrawerContentWidth(420) in Core/UI.lua.
CONTENT_W = 230
# OptionsSliderTemplate draws Low/High under the track. The old advance was 36.
SLIDER_FLOOR = 44


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
ToonAge = { modules = {}, Data = {} }
function ToonAge:RegisterModule(name, module)
    self.modules[name] = module
    self[name] = module
end
function ToonAge:GetModule(name) return self.modules[name] end
function ToonAge:GetRegisteredModule(name) return self.modules[name] end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
wipe = function(t) for k in pairs(t) do t[k] = nil end end

local function strip(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

local function Widget(kind)
    local f = { _kind = kind, _children = {}, _regions = {}, _width = 0, _height = 0,
                _fontSize = 10, _text = "", _wordWrap = false, _anchors = {} }
    function f:SetParent(parent)
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
        if type(rel) == "number" then
            self._anchors[#self._anchors + 1] = { point = point, x = rel, y = relPoint }
        else
            self._anchors[#self._anchors + 1] = {
                point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0,
            }
        end
    end
    function f:ClearAllPoints() self._anchors = {} end
    function f:SetFont(_, size) self._fontSize = size or self._fontSize end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetTextColor() end
    function f:SetJustifyH(j) self._justify = j end
    function f:SetWordWrap(v) self._wordWrap = v and true or false end
    function f:GetStringWidth()
        return math.max(#strip(self._text), 1) * ((self._fontSize or 10) * 0.55)
    end
    function f:GetStringHeight()
        local size = self._fontSize or 10
        local natural = self:GetStringWidth()
        local width = self._width or 0
        if not self._wordWrap or width <= 0 then return size + 4 end
        local lines = math.max(1, math.ceil(natural / width))
        return lines * (size + 4)
    end
    function f:SetScript() end
    function f:SetBackdrop() end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    function f:SetOrientation() end
    function f:SetMinMaxValues() end
    function f:SetValueStep() end
    function f:SetObeyStepOnDrag() end
    function f:SetValue() end
    function f:Hide() self._hidden = true end
    function f:Show() self._hidden = false end
    function f:IsShown() return not self._hidden end
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
    function f:SetColorTexture() end
    return f
end

function CreateFrame(kind, _, parent, template)
    local f = Widget(kind or "Frame")
    f._template = template
    if parent then f:SetParent(parent) end
    if template == "OptionsSliderTemplate" then
        -- FrameXML anchors these to the track. Low/High hang below it.
        f.Low = f:CreateFontString()
        f.Low:SetFont(STANDARD_TEXT_FONT, 10, "")
        f.Low:SetText("LOW")
        f.Low:SetHeight(12)
        f.High = f:CreateFontString()
        f.High:SetFont(STANDARD_TEXT_FONT, 10, "")
        f.High:SetText("HIGH")
        f.High:SetHeight(12)
        f.Text = f:CreateFontString()
        f.Text:SetText("")
    end
    return f
end

function upvalue(fn, wanted)
    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if not name then return nil end
        if name == wanted then return val end
        i = i + 1
    end
end

function anchor(widget)
    local list = widget._anchors
    return list[#list]
end

function status_left(row, status)
    local a = anchor(status)
    local right = row:GetWidth() + (a.x or 0)
    return right - status:GetStringWidth()
end

function label_right(label)
    local a = anchor(label)
    local left = a.x or 0
    local width = label:GetWidth()
    if not width or width <= 0 then width = label:GetStringWidth() end
    return left + width
end
"""


def load():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Infrastructure/Settings.lua"))
    lua.execute(r"""
        local Settings = ToonAge.modules.Settings
        MakeToggleRow = upvalue(Settings.Render, "MakeToggleRow")
        MakeChoiceRow = upvalue(Settings.Render, "MakeChoiceRow")
        MakeSliderRow = upvalue(Settings.Render, "MakeSliderRow")
    """)
    return lua


def regions(row):
    label, status = None, None
    i = 1
    while True:
        region = row._regions[i]
        if region is None:
            break
        if region._kind == "FontString":
            text = str(region._text or "")
            if "ON" in text or "OFF" in text or (status is None and text and label is not None):
                status = region
            elif label is None:
                label = region
        i += 1
    return label, status


def test_source_uses_helpers():
    settings = read("Modules/Infrastructure/Settings.lua")
    layout = read("Core/Layout.lua")
    check("Layout exports the label span", "function L:ToggleLabelWidth" in layout, True)
    check("Layout exports the wrapped row height", "function L:WrappedRowHeight" in layout, True)
    check("Layout exports the slider block height", "function L:SliderBlockHeight" in layout, True)
    check("toggle rows use ToggleLabelWidth", "ToggleLabelWidth" in settings, True)
    check("toggle rows use WrappedRowHeight", "WrappedRowHeight" in settings, True)
    check("slider rows use SliderBlockHeight", "SliderBlockHeight" in settings, True)


def test_toggle_labels():
    lua = load()
    g = lua.globals()
    make = g.MakeToggleRow
    for label in LABELS:
        lua.execute("PARENT = CreateFrame('Frame')")
        parent = g.PARENT
        start = -10
        nxt = make(parent, start, CONTENT_W, label,
                   lua.eval("function() return false end"),
                   lua.eval("function() end"))
        row = parent._children[1]
        text, status = regions(row)
        span = g.label_right(text)
        state = g.status_left(row, status)
        check(f"{label[:28]} stays left of the state", float(span) <= float(state) - 4, True)
        check(f"{label[:28]} width is constrained", float(text._width or 0) > 0, True)
        check(f"{label[:28]} wraps", bool(text._wordWrap), True)
        text_h = float(text.GetStringHeight(text))
        row_h = float(row.GetHeight(row))
        check(f"{label[:28]} row grows with the label", row_h + 0.01 >= text_h and row_h > 22, True)
        advance = float(start) - float(nxt)
        # The old row always returned y - 26. A wrapped label has to push
        # the next row further down than that.
        check(f"{label[:28]} next row starts below the wrap", advance > 26, True)


def test_slider_reserves_template_height():
    lua = load()
    g = lua.globals()
    make = g.MakeSliderRow
    lua.execute("PARENT = CreateFrame('Frame')")
    parent = g.PARENT
    y = -10
    y = make(parent, y, CONTENT_W, "  NavHud Scale", 0.5, 2.5, 0.1,
             lua.eval("function() return 1.4 end"),
             lua.eval("function() end"))
    first = -10 - float(y)
    y2 = make(parent, y, CONTENT_W, "  NavHud Opacity", 0.1, 1.0, 0.05,
              lua.eval("function() return 0.85 end"),
              lua.eval("function() end"))
    second = float(y) - float(y2)
    check("NavHud Scale reserves the template, not 36px", first >= SLIDER_FLOOR, True)
    check("NavHud Opacity reserves the template, not 36px", second >= SLIDER_FLOOR, True)
    # The helper is the floor the rows use. A private 36 no longer fits.
    has_helper = bool(lua.eval("type(ToonAge.Layout.SliderBlockHeight) == 'function'"))
    check("shared slider block helper exists", has_helper, True)
    if has_helper:
        height = float(lua.eval("ToonAge.Layout:SliderBlockHeight()"))
        check("shared slider block is at least the template", height >= SLIDER_FLOOR, True)
        check("rows advance by that shared block",
              abs(first - height) < 0.01 and abs(second - height) < 0.01, True)


def test_choice_row_same_rule():
    lua = load()
    g = lua.globals()
    lua.execute("PARENT = CreateFrame('Frame')")
    parent = g.PARENT
    label = "Account-Bound settings (share guide progress across characters)"
    g.MakeChoiceRow(
        parent, -10, CONTENT_W, label,
        lua.eval("{ { value = 'char', text = 'This character' }, { value = 'account', text = 'Account' } }"),
        lua.eval("function() return 'char' end"),
        lua.eval("function() end"),
    )
    row = parent._children[1]
    text, status = regions(row)
    check("choice label stays left of its state",
          float(g.label_right(text)) <= float(g.status_left(row, status)) - 4, True)
    check("choice row grows when the label wraps", float(row.GetHeight(row)) > 22, True)


def main():
    test_source_uses_helpers()
    test_toggle_labels()
    test_slider_reserves_template_height()
    test_choice_row_same_rule()
    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
