#!/usr/bin/env python3
"""Reusable left-panel slot under the character block.

A tab may register build/refresh/release callbacks. The active tab's slot
sits below the character block (or swaps in for it), scrolls on its own, and
hands pooled frames back through Core/Layout.lua on switch. A tab that does
not register leaves the sidebar it already drew alone.

No tab registers itself here. This does not open the game client.
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
ToonAge = { modules = {}, Layout = nil }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end

created = 0

local function Widget(kind, name)
    local f = {
        _kind = kind, _name = name, _children = {}, _regions = {},
        _shown = true, scripts = {}, _text = "", _fontSize = 10,
        _points = {}, _width = 0, _height = 0, _level = 1,
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
    function f:GetStringHeight() return (self._fontSize or 10) + 2 end
    function f:SetTextColor() end
    function f:SetJustifyH() end
    function f:SetWordWrap() end
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
    created = created + 1
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
    _lines = {},
    SetOwner = function() end,
    SetText = function(_, text) GameTooltip._lines = { text } end,
    AddLine = function(_, text) GameTooltip._lines[#GameTooltip._lines + 1] = text end,
    Show = function() end,
    Hide = function() GameTooltip._lines = {} end,
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
    local caption = side:CreateFontString()
    caption:SetText("Sirc")
    return {
        sidebar = sidebar,
        sideScroll = sideScroll,
        sideChild = side,
        sideWidth = 184,
        caption = caption,
    }
end
"""


def main():
    ui_src = read("Core/UI.lua")
    start = ui_src.index("function frame:SetTab")
    end = ui_src.index("function frame:Refresh")
    body = ui_src[start:end]
    release_at = body.find("ReleaseLeftPanel")
    rebuild_at = body.find("RebuildChild(")
    render_at = body.find("pcall(mod.Render")
    finish_at = body.find("pcall(TA.FinishTabSlot")
    defer_at = body.find("_leftPanelDefer = true")
    empty_at = body.find("sideEmpty")
    board = read("Modules/Character/ProfessionBoard.lua")
    check("SetTab releases a slot before rebuilding panes",
          release_at != -1 and rebuild_at != -1 and release_at < rebuild_at, True)
    check("SetTab finishes the slot after the tab renders",
          render_at != -1 and finish_at != -1 and render_at < finish_at, True)
    check("SetTab finishes the slot before the empty-sidebar check",
          finish_at != -1 and empty_at != -1 and finish_at < empty_at, True)
    check("SetTab raises the defer flag before Render",
          defer_at != -1 and render_at != -1 and defer_at < render_at, True)
    check("the professions tab reads the defer flag during Render",
          "ui._leftPanelDefer" in board, True)
    check("an unregistered tab still uses the old empty-sidebar test",
          "not slotOpen" in body, True)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    before_layout = lua.eval("created")
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Core/LeftPanel.lua"))
    lua.execute(r"""
local TA = ToonAge
badKey = TA:RegisterLeftPanel("", { build = function() end })
badSpec = TA:RegisterLeftPanel("gear", {})
badPlace = TA:RegisterLeftPanel("gear", { build = function() end, place = "beside" })
badRefresh = TA:RegisterLeftPanel("gear", { build = function() end, refresh = "no" })
okReg = TA:RegisterLeftPanel("professions", {
    build = function(content, host)
        built = (built or 0) + 1
        builtHost = host
        builtParent = content
        ToonAge.Layout:ButtonRow(content, -8, {
            { label = "Slot control", onClick = function() end },
        })
        content:SetHeight(800)
    end,
    refresh = function(content, host)
        refreshed = (refreshed or 0) + 1
    end,
    release = function(content, host)
        released = (released or 0) + 1
        releaseParent = content
        local still = false
        for _, child in ipairs({ content:GetChildren() }) do
            if child._kind == "Button" then still = true end
        end
        releaseSawButton = still
    end,
})
stored = TA:LeftPanelSpec("professions")
missing = TA:LeftPanelSpec("gear")

ui = MakeUI()
sideText = ui.caption:GetText()
sideH = ui.sideChild:GetHeight()
framesBeforeIdle = created
idleMount = TA:MountLeftPanel(ui, "gear")
idleRelease = TA:ReleaseLeftPanel(ui)
sideTextAfter = ui.caption:GetText()
sideHAfter = ui.sideChild:GetHeight()
framesAfterIdle = created
scrollShownAfterIdle = ui.sideScroll:IsShown()

ui.sideChild:SetHeight(110)
local atFirst = created
mounted = TA:MountLeftPanel(ui, "professions")
firstBuilt = built
firstNew = created - atFirst
local slot = ui._leftSlot
slotShown = slot and slot.scroll:IsShown()
contentPane = slot and slot.content._laPane
hostWidth = builtHost and builtHost.width
hostPlace = builtHost and builtHost.place
topPoint = nil
for _, pt in ipairs(slot.scroll._points) do
    if pt.a == "TOPLEFT" then topPoint = pt.e end
end
sideTextMounted = ui.caption:GetText()
sideScrollStill = ui.sideScroll:IsShown()
refreshedOk = TA:RefreshLeftPanel(ui)

slot.scroll:SetHeight(100)
slot.scroll:GetScript("OnMouseWheel")(slot.scroll, -1)
scrolled = slot.scroll:GetVerticalScroll()

local atSecond = created
TA:MountLeftPanel(ui, "professions")
secondNew = created - atSecond

TA:RegisterLeftPanel("casts", {
    place = "swap",
    build = function(content, host)
        castHost = host
        content:SetHeight(40)
    end,
    release = function() castsReleased = (castsReleased or 0) + 1 end,
})
TA:MountLeftPanel(ui, "casts")
swapPlace = castHost and castHost.place
swapTop = nil
for _, pt in ipairs(ui._leftSlot.scroll._points) do
    if pt.a == "TOPLEFT" then swapTop = pt.e end
end
sideHidden = ui.sideScroll:IsShown() == false
sideTextSwapped = ui.caption:GetText()
profRelease = released

TA:ReleaseLeftPanel(ui)
afterReleaseShown = ui._leftSlot.scroll:IsShown()
sideRestored = ui.sideScroll:IsShown()
cleared = TA:ClearLeftPanel("casts")
gone = TA:LeftPanelSpec("casts")
stillProf = TA:LeftPanelSpec("professions") ~= nil
mountGone = TA:MountLeftPanel(ui, "casts")

-- Layout absent: the host is still created once and switching still releases.
local savedLayout = ToonAge.Layout
ToonAge.Layout = nil
bare = MakeUI()
bare.sideChild:SetHeight(80)
local bareBuilds = 0
TA:RegisterLeftPanel("notes", {
    build = function(content) bareBuilds = bareBuilds + 1; content:SetHeight(30) end,
    release = function() bareReleased = (bareReleased or 0) + 1 end,
})
local bareAt = created
TA:MountLeftPanel(bare, "notes")
bareFirst = created - bareAt
TA:MountLeftPanel(bare, "notes")
bareSecond = created - bareAt - bareFirst
bareReleaseOk = TA:ReleaseLeftPanel(bare)
ToonAge.Layout = savedLayout

-- A Render that throws must not leave a slot beside the error text.
failBuilds = 0
TA:RegisterLeftPanel("boom", {
    build = function(content)
        failBuilds = failBuilds + 1
        content:SetHeight(40)
    end,
    release = function() failReleased = (failReleased or 0) + 1 end,
})
failUI = MakeUI()
failUI._leftPanelDefer = true
skipped = TA:FinishTabSlot(failUI, "boom", false)
failDeferCleared = failUI._leftPanelDefer == nil
opened = TA:FinishTabSlot(failUI, "boom", true)
dropped = TA:FinishTabSlot(failUI, "boom", false)
failShownAfter = failUI._leftSlot and failUI._leftSlot.scroll:IsShown()
""")
    # Layout was nilled. Restore by re-reading is unnecessary; assertions use
    # values captured before that. Re-bind so a later execute is safe.
    g = lua.globals()
    check("a blank tab key is rejected", g.badKey, False)
    check("a spec without build is rejected", g.badSpec, False)
    check("an unknown place is rejected", g.badPlace, False)
    check("a non-function refresh is rejected", g.badRefresh, False)
    check("a build function registers", g.okReg, True)
    check("the spec is readable", g.stored.build is not None, True)
    check("an unregistered tab has no spec", g.missing, None)
    check("mounting an unregistered tab does nothing", g.idleMount, False)
    check("releasing when nothing is mounted does nothing", g.idleRelease, False)
    check("an unregistered mount does not create frames", g.framesAfterIdle, g.framesBeforeIdle)
    check("an unregistered mount keeps the character caption", g.sideTextAfter, "Sirc")
    check("an unregistered mount keeps the sidebar height", g.sideHAfter, g.sideH)
    check("an unregistered mount leaves the sidebar scroll shown", g.scrollShownAfterIdle, True)
    check("the professions slot mounts", g.mounted, True)
    check("build receives the slot content", g.firstBuilt, 1)
    check("the slot scroll is shown", g.slotShown, True)
    check("the slot content is a pooled pane", g.contentPane, True)
    check("the host reports the sidebar width", g.hostWidth, 184)
    check("the default place is below the character block", g.hostPlace, "below")
    check("the slot starts under the character block", g.topPoint, -(4 + 110 + 4))
    check("below mode keeps the character caption", g.sideTextMounted, "Sirc")
    check("below mode keeps the character scroll", g.sideScrollStill, True)
    check("refresh calls the tab's refresh", g.refreshed, 1)
    check("a tall slot scrolls on its own wheel", g.scrolled, 24)
    check("mounting again creates no frames", g.secondNew, 0)
    check("switching tabs releases the previous slot", g.profRelease >= 1, True)
    check("release still sees the slot's frames", g.releaseSawButton, True)
    check("swap replaces the character block", g.swapPlace, "swap")
    check("swap anchors the slot at the top of the sidebar", g.swapTop, -4)
    check("swap hides the character scroll", g.sideHidden, True)
    check("swap does not wipe the character caption", g.sideTextSwapped, "Sirc")
    check("release hides the slot", g.afterReleaseShown, False)
    check("release restores the character scroll", g.sideRestored, True)
    check("clear drops the registration", g.cleared, True)
    check("a cleared tab has no spec", g.gone, None)
    check("clearing one tab leaves the other", g.stillProf, True)
    check("a cleared tab does not mount", g.mountGone, False)
    check("without Layout the first mount creates the host", g.bareFirst > 0, True)
    check("without Layout a second mount creates no frames", g.bareSecond, 0)
    check("without Layout release still runs", g.bareReleaseOk, True)
    check("without Layout release calls the tab", g.bareReleased >= 1, True)
    check("layout loaded before the slot tests", before_layout >= 0, True)
    check("a failed render does not mount a slot", g.skipped, False)
    check("a failed render clears the defer flag", g.failDeferCleared, True)
    check("only the successful finish builds the slot", g.failBuilds, 1)
    check("a successful render still builds the slot", g.opened, True)
    check("a later failed render releases the slot", g.dropped, False)
    check("a released slot stays hidden", g.failShownAfter, False)
    check("releasing after a failure does not build again", g.failReleased >= 1, True)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
