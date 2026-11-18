#!/usr/bin/env python3
"""DataRow: a value wider than the 96px box wraps, and the row grows.

Forever PvP draws "Blood Fury, Hardiness, Shatter Curse" and the session
per-hour line into that box with word wrap off, so the text paints past the
row. Short values (a bag count, a rank) stay one line at the same height:
those rows are every other tab.

UI scale 0.64 scales the whole window together. The value font stays 11,
the same size as a short row, and the extra line is inside the row rather
than clipped or shrunk.

Usage:  python3 Tools/test_datarow_wrap.py [-v]
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

# Known Forever PvP values that do not fit the 96px box.
RACIAL = "Blood Fury, Hardiness, Shatter Curse"
PER_HOUR = "120 honor, 4.5 kills  (45 min)"
SHORT = "4 / 20"
VALUE_BOX = 96
# Content column beside the sidebar: Core/UI.lua contentWidth is 667.
CONTENT_W = 667


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


def natural_width(text, size=11):
    """Same estimate the Lua widget stub uses."""
    return max(len(text), 1) * (size * 0.55)


PRELUDE = r"""
ToonAge = { modules = {}, Data = {}, Utils = {} }
function ToonAge:RegisterModule(name, module)
    self.modules[name] = module
    self[name] = module
end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
GameTooltip = setmetatable({}, { __index = function() return function() end end })
USE_UNBOUNDED = true

local function strip(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    return (text:gsub("|r", ""))
end

local function Widget(kind)
    local f = {
        _kind = kind, _children = {}, _regions = {}, _width = 0, _height = 0,
        _fontSize = 10, _text = "", _wordWrap = false, _anchors = {}, _shown = true,
        _scripts = {}, _mouse = false,
    }
    function f:_natural()
        return math.max(#strip(self._text), 1) * ((self._fontSize or 10) * 0.55)
    end
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
    function f:SetFont(_, size, flags)
        if size then self._fontSize = size end
        self._flags = flags or ""
    end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetTextColor() end
    function f:SetJustifyH(j) self._justify = j end
    function f:SetWordWrap(v) self._wordWrap = v and true or false end
    function f:SetNonSpaceWrap(v) self._nonSpaceWrap = v and true or false end
    function f:GetStringWidth()
        -- Displayed width. A constrained box reports the box, not the
        -- unwrapped line, which is why a 96px value hides its own overflow.
        local natural = self:_natural()
        local width = self._width or 0
        if width > 0 then return math.min(natural, width) end
        return natural
    end
    function f:GetUnboundedStringWidth()
        if not USE_UNBOUNDED then return nil end
        return self:_natural()
    end
    function f:GetStringHeight()
        -- Height 0 does not wrap on Forever. The line runs past the box.
        local size = self._fontSize or 10
        local line = size + 2
        local natural = self:_natural()
        local width = self._width or 0
        local canWrap = self._wordWrap and width > 0 and (self._height or 0) > 0
        if not canWrap then return line end
        return math.max(1, math.ceil(natural / width)) * line
    end
    function f:SetScript(name, fn) self._scripts[name] = fn end
    function f:GetScript(name) return self._scripts[name] end
    function f:EnableMouse(v) self._mouse = v and true or false end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetDrawLayer() end
    function f:SetColorTexture() end
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
    lua.execute(
        f"RACIAL = {RACIAL!r}\nPER_HOUR = {PER_HOUR!r}\nSHORT = {SHORT!r}\n"
        f"CONTENT_W = {CONTENT_W}\n"
    )
    return lua


def draw(lua, label, value, note=None, tooltip=False, bold=False):
    note_lit = "nil"
    if note is not None:
        note_lit = repr(note)
    tip = '{ "full text" }' if tooltip else "nil"
    lua.execute(f"""
        content = CreateFrame("Frame")
        content:SetWidth(CONTENT_W)
        content._laPane = true
        local L = ToonAge.Layout
        NEXT_Y, ROW = L:DataRow(content, -8, {{
            label = {label!r},
            value = {value!r},
            note = {note_lit},
            tooltip = {tip},
            bold = {str(bold).lower()},
        }})
        HAS_TIP = ROW:GetScript("OnEnter") ~= nil
    """)
    return lua.globals()


def test_fixtures_overflow_the_box():
    check("racial list is wider than the value box", natural_width(RACIAL) > VALUE_BOX, True)
    check("per-hour line is wider than the value box", natural_width(PER_HOUR) > VALUE_BOX, True)
    check("a short count fits the value box", natural_width(SHORT) < VALUE_BOX, True)


def _anchor(g, widget):
    return g.lastAnchor(widget)


def _value_right(g, row):
    anchor = _anchor(g, row.value)
    return float(anchor.x or 0) + float(row.value._width or 0)


def test_short_row_is_unchanged():
    lua = load_layout()
    g = draw(lua, "Light Feather", SHORT)
    row = g.ROW
    one_line = float(row.value._fontSize) + 2
    check("short row stays one line tall", float(row._height), 20.0)
    check("short value does not wrap", bool(row.value._wordWrap), False)
    check("short value keeps the 96px box", float(row.value._width), float(VALUE_BOX))
    check("short value stays right-justified", str(row.value._justify), "RIGHT")
    anchor = _anchor(g, row.value)
    check("short value stays left-anchored in its box", str(anchor.point), "TOPLEFT")
    check("short value ends before the row edge", _value_right(g, row) <= float(row._width) - 8, True)
    check("short value font stays 11", float(row.value._fontSize), 11.0)
    check("short row advance is the single line plus the gap",
          float(g.NEXT_Y), -8.0 - 20.0 - 2.0)
    check("short value is shorter than the row", one_line < float(row._height), True)


def test_short_note_stays_put():
    lua = load_layout()
    g = draw(lua, "Orc", "burst", note="one line")
    row = g.ROW
    note_anchor = _anchor(g, row.note)
    check("short note row stays the note height", float(row._height), 32.0)
    check("short note stays on the second line", float(note_anchor.y), -16.0)
    check("short noted value does not wrap", bool(row.value._wordWrap), False)
    check("short note is shown", bool(row.note._shown), True)


def test_long_value_wraps_and_grows():
    lua = load_layout()
    g = draw(lua, "Orc", RACIAL, tooltip=True)
    row = g.ROW
    one_line = float(row.value._fontSize) + 2
    value_h = float(row.value._height or 0)
    check("racial value is still the full list", str(row.value._text), RACIAL)
    check("racial value wraps inside the box", bool(row.value._wordWrap), True)
    check("racial value keeps the 96px box", float(row.value._width), float(VALUE_BOX))
    check("racial value font stays 11 at UI scale 0.64", float(row.value._fontSize), 11.0)
    check("racial value is more than one line", value_h > one_line, True)
    check("racial value is the wrapped text, not the measure box", value_h < 120, True)
    check("racial row grows to hold the wrapped value",
          float(row._height) >= 2 + value_h, True)
    check("racial row is taller than a short row", float(row._height) > 20, True)
    check("racial row advance matches the grown height",
          float(g.NEXT_Y), -8.0 - float(row._height) - 2.0)
    check("racial value ends before the row edge", _value_right(g, row) <= float(row._width) - 8, True)
    anchor = _anchor(g, row.value)
    check("racial value stays in the right-hand box", str(anchor.point), "TOPLEFT")
    check("racial tooltip script is kept", bool(g.HAS_TIP), True)


def test_per_hour_wraps_onto_a_second_line():
    lua = load_layout()
    g = draw(lua, "Per hour (this session)", PER_HOUR)
    row = g.ROW
    one_line = float(row.value._fontSize) + 2
    value_h = float(row.value._height or 0)
    check("per-hour text is kept in full", str(row.value._text), PER_HOUR)
    check("per-hour value wraps", bool(row.value._wordWrap), True)
    check("per-hour value is a second line", value_h >= one_line * 2 - 0.1, True)
    check("per-hour row grows with the value", float(row._height) >= 2 + value_h, True)
    check("per-hour font stays 11", float(row.value._fontSize), 11.0)


def test_long_value_pushes_the_note_down():
    lua = load_layout()
    g = draw(lua, "Orc", RACIAL, note="Your Will of the Forsaken breaks their War Stomp.")
    row = g.ROW
    value_h = float(row.value._height or 0)
    note_anchor = _anchor(g, row.note)
    note_top = -float(note_anchor.y or 0)
    # Value text starts 2px under the row top.
    value_bottom = 2 + value_h
    check("noted racial value wraps", bool(row.value._wordWrap), True)
    check("note starts at or below the wrapped value", note_top >= value_bottom - 0.1, True)
    check("note row grows past the single-line note", float(row._height) > 32, True)
    check("note stays inside the grown row",
          note_top + float(row.note._height or 0) <= float(row._height), True)
    check("note is still shown", bool(row.note._shown), True)


def test_pool_reuses_a_short_row_unchanged():
    lua = load_layout()
    lua.execute(f"""
        content = CreateFrame("Frame")
        content:SetWidth(CONTENT_W)
        content._laPane = true
        local L = ToonAge.Layout
        local _, longRow = L:DataRow(content, -8, {{
            label = "Orc", value = RACIAL, tooltip = {{ RACIAL }},
        }})
        LONG_ROW = longRow
        L:ReleasePane(content)
        local nextY, shortRow = L:DataRow(content, -8, {{
            label = "Light Feather", value = SHORT,
        }})
        SHORT_ROW = shortRow
        SHORT_NEXT = nextY
        SAME = shortRow == longRow
        SHORT_TIP = shortRow:GetScript("OnEnter") ~= nil
        USE_UNBOUNDED = false
        local _, fallbackRow = L:DataRow(content, -40, {{
            label = "Per hour (this session)", value = PER_HOUR,
        }})
        FALLBACK_ROW = fallbackRow
    """)
    g = lua.globals()
    row = g.SHORT_ROW
    check("pooled frame is the racial row", bool(g.SAME), True)
    check("pooled short row is one line tall", float(row._height), 20.0)
    check("pooled short value does not wrap", bool(row.value._wordWrap), False)
    check("pooled short value box is 96px", float(row.value._width), float(VALUE_BOX))
    check("pooled short text is the count", str(row.value._text), SHORT)
    check("pooled short row drops the racial tooltip", bool(g.SHORT_TIP), False)
    check("pooled short note is hidden", bool(row.note._shown), False)
    check("pooled short advance is unchanged", float(g.SHORT_NEXT), -8.0 - 20.0 - 2.0)
    fallback = g.FALLBACK_ROW
    check("wrap still happens without GetUnboundedStringWidth",
          bool(fallback.value._wordWrap), True)
    check("fallback row grows for the per-hour line",
          float(fallback._height) > 20, True)


def test_bold_short_row_stays_one_line():
    lua = load_layout()
    g = draw(lua, "Rank", "Knight", bold=True)
    row = g.ROW
    check("bold short row stays 20px", float(row._height), 20.0)
    check("bold short value does not wrap", bool(row.value._wordWrap), False)
    check("bold short value keeps its outline", "OUTLINE" in str(row.value._flags or ""), True)


def main():
    test_fixtures_overflow_the_box()
    test_short_row_is_unchanged()
    test_short_note_stays_put()
    test_long_value_wraps_and_grows()
    test_per_hour_wraps_onto_a_second_line()
    test_long_value_pushes_the_note_down()
    test_pool_reuses_a_short_row_unchanged()
    test_bold_short_row_stays_one_line()
    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
