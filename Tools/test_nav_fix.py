#!/usr/bin/env python3
"""Auto-select follows the current map and the quest log.

A level 90 player standing in Khaz Algar used to land on Midnight:
Zul'Aman step 572, then flip to Midnight: Void Assaults. Pass 2 of
AutoSelectGuide ignored the map and picked whichever guide's level
midpoint was closest. Pass 4 picked any guide at all.

The HUD and arrow defaulted off (and the HUD wrote that off into
saved vars), so the scale and opacity sliders changed a frame that
was never on screen. Opacity must stay at or above 0.25. The HUD
anchor is the center of UIParent unless the player dragged it.
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
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


BOOT = r"""
ToonAge = {
    modules = {},
    flavor = "retail",
    IsRetail = true,
    Guides = {},
    GuideData = {},
    LOG = { OUTPUT = 1, INFO = 2 },
    db = {},
    charDB = { tracker = {}, navhud = {}, arrow = {} },
}
function ToonAge:RegisterModule(name, mod)
    self.modules[name] = mod
    self[name] = mod
end
function ToonAge:GetModule(name)
    local mod = self.modules[name]
    if not mod or mod._disabled or mod._profileSkipped then return nil end
    return mod
end
function ToonAge:GetRegisteredModule(name)
    return self.modules[name]
end
function ToonAge:RegisterEvent() end
function ToonAge:Raw() end
ToonAge.Utils = {
    WAYPOINT_SIZE_DEFAULT = 48,
    TEX_WAYPOINT = "Interface\\AddOns\\ToonAge\\waypoint",
    TEX_WAYPOINT_ARRIVED = "Interface\\AddOns\\ToonAge\\waypoint_arrived",
    WaypointSize = function(size) return size or 48 end,
    DeferToZygor = function() return false end,
    AddEstimatedTip = function() end,
    Glyph = function() return "" end,
}
"""

WIDGET = r"""
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
local function Widget()
    local w = {
        _points = {},
        _shown = false,
        _scale = 1,
        _alpha = 1,
        _scripts = {},
    }
    function w:SetPoint(point, rel, relPoint, x, y)
        self._points[#self._points + 1] = { point, relPoint, x, y }
        self._point = point
        self._rel = rel
        self._relPoint = relPoint
        self._x = x or 0
        self._y = y or 0
    end
    function w:ClearAllPoints()
        self._points = {}
    end
    function w:GetPoint()
        return self._point, self._rel, self._relPoint, self._x, self._y
    end
    function w:SetScale(s) self._scale = s end
    function w:GetScale() return self._scale end
    function w:SetAlpha(a) self._alpha = a end
    function w:GetAlpha() return self._alpha end
    function w:GetHeight() return 1080 end
    function w:GetWidth() return 1920 end
    function w:Show() self._shown = true end
    function w:Hide() self._shown = false end
    function w:IsShown() return self._shown end
    function w:IsVisible() return self._shown end
    function w:CreateTexture() return Widget() end
    function w:CreateFontString() return Widget() end
    function w:SetScript(name, fn) self._scripts[name] = fn end
    function w:GetFrameLevel() return self._level or 1 end
    function w:SetFrameLevel(n) self._level = n end
    function w:GetWidth() return self._w or 1920 end
    setmetatable(w, { __index = function() return function() end end })
    return w
end
UIParent = Widget()
function CreateFrame(_, name, parent)
    local w = Widget()
    w._name = name
    w._parent = parent
    return w
end
GameTooltip = Widget()
function GetCVar() return "0" end
function SetCVar() end
C_Timer = {
    After = function(_, fn) fn() end,
    NewTicker = function() return { Cancel = function() end } end,
}
"""

MAPS = r"""
local MAPS = {
    [2339] = { name = "Dornogal", parentMapID = 2248 },
    [2248] = { name = "Isle of Dorn", parentMapID = 2274 },
    [2274] = { name = "Khaz Algar", parentMapID = 13 },
    [2437] = { name = "Zul'Aman", parentMapID = 2537 },
    [2537] = { name = "Quel'Thalas", parentMapID = 13 },
}
PLAYER_MAP = 2339
function UnitLevel() return 90 end
C_Map = {
    GetBestMapForUnit = function() return PLAYER_MAP end,
    GetMapInfo = function(id) return MAPS[id] end,
}
local LOG = {
    { questID = 100, title = "Restoring Jade's Purity", isHeader = false },
    { questID = 94382, title = "Ritual Problems", isHeader = false },
}
C_QuestLog = {
    GetNumQuestLogEntries = function() return #LOG end,
    GetInfo = function(i) return LOG[i] end,
    IsQuestFlaggedCompleted = function() return false end,
    GetLogIndexForQuestID = function(id)
        for i, row in ipairs(LOG) do
            if row.questID == id then return i end
        end
        return nil
    end,
}
function SetLog(rows)
    LOG = rows
end
"""

GUIDES = r"""
ToonAge.Guides = {
    dorn = {
        id = "dorn", title = "The War Within: Isle of Dorn",
        zone = 2248, minLevel = 70, maxLevel = 80,
        steps = {
            { type = "quest", questID = 100, text = "Restoring Jade's Purity" },
        },
    },
    zul = {
        id = "zul", title = "Midnight: Zul'Aman (Campaign)",
        zone = 2437, minLevel = 80, maxLevel = 90,
        steps = {
            { type = "travel", text = "[Travel] Different zone" },
            { type = "quest", questID = 572, text = "Dirty Deeds" },
        },
    },
    naigtal = {
        id = "naigtal", title = "Midnight: Void Assaults & Naigtal",
        zone = 2537, minLevel = 86, maxLevel = 90,
        steps = {
            { type = "quest", questID = 1, text = "step" },
            { type = "quest", questID = 2, text = "step" },
            { type = "quest", questID = 3, text = "step" },
            { type = "quest", questID = 4, text = "step" },
            { type = "quest", questID = 94382, text = "Ritual Problems" },
        },
    },
}
"""


def main():
    settings = read("Modules/Infrastructure/Settings.lua")
    check("opacity slider cannot go below 0.25",
          'MakeSliderRow(content, y, w, "  NavHud Opacity", 0.25, 1.0, 0.05,' in settings)
    check("scale slider stays in a reasonable range",
          'MakeSliderRow(content, y, w, "  NavHud Scale", 0.5, 2.0, 0.1,' in settings)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read("Modules/Navigation/QuestTracker.lua"))
    lua.execute(MAPS)
    lua.execute(GUIDES)
    lua.execute(r"""
        local QT = ToonAge.QuestTracker
        local picks = {}
        QT.SetGuide = function(self, id)
            picks[#picks + 1] = id
            self.guideID = id
            self._noZoneGuide = false
        end
        QT:AutoSelectGuide()
        QT:AutoSelectGuide()
        PICKS = table.concat(picks, ",")
        GUIDE = QT.guideID or ""
        FLAG = QT._noZoneGuide and true or false
        FITS = QT.GuideFits and QT:GuideFits("dorn") or false
        if QT.GuideFits then ZUL_FITS = QT:GuideFits("zul") else ZUL_FITS = "missing" end
    """)
    check("zone and log quest beat a closer Midnight level band",
          lua.eval("GUIDE"), "dorn")
    check("auto-select does not set the guide twice", lua.eval("PICKS"), "dorn")
    check("the Dorn guide fits this map and log", lua.eval("FITS"), True)
    check("Zul'Aman does not fit Khaz Algar", lua.eval("ZUL_FITS"), False)
    check("a match clears the no-guide flag", lua.eval("FLAG"), False)

    lua.execute(r"""
        local QT = ToonAge.QuestTracker
        local picks = {}
        QT.guideID = nil
        QT._noZoneGuide = false
        QT.SetGuide = function(self, id)
            picks[#picks + 1] = id
            self.guideID = id
        end
        -- Only the Midnight quest is in the log. It is not this zone.
        SetLog({ { questID = 94382, title = "Ritual Problems", isHeader = false } })
        ToonAge.Guides.dorn = nil
        QT:AutoSelectGuide()
        local first = QT.guideID
        ToonAge.Guides.naigtal = ToonAge.Guides.naigtal
        QT:AutoSelectGuide()
        NOMATCH = QT.guideID or ""
        NOFLAG = QT._noZoneGuide and true or false
        NOPICKS = table.concat(picks, ",")
        MSG = QT.NoZoneGuideMessage and QT:NoZoneGuideMessage() or ""
        QT.window = {
            guideTitleF = { SetText = function(s, t) s._text = t end, _text = "" },
            stepTextF = { SetText = function(s, t) s._text = t end, _text = "" },
            stepNumF = { SetText = function() end },
            stepBadgeF = { SetText = function() end },
        }
        if not QT.guideID then QT:UpdateWindow() end
        TITLE = QT.window.guideTitleF._text or ""
        BODY = QT.window.stepTextF._text or ""
        FIRST = first or ""
    """)
    check("no zone and log match leaves the guide empty", lua.eval("NOMATCH"), "")
    check("the first pass did not grab Zul'Aman", lua.eval("FIRST"), "")
    check("nothing is selected on the second pass either", lua.eval("NOPICKS"), "")
    check("the tracker records that this zone has no guide", lua.eval("NOFLAG"), True)
    check("the message names the zone gap", lua.eval("MSG"), "No guide for this zone")
    title = lua.eval("TITLE") or ""
    body = lua.eval("BODY") or ""
    check("the tracker title shows the message", "No guide for this zone" in title)
    check("the tracker body shows the message", "No guide for this zone" in body)

    lua.execute(r"""
        -- Guides appear one after another. The old level pass flipped
        -- from Zul'Aman (midpoint 85) to Void Assaults (midpoint 88).
        local QT = ToonAge.QuestTracker
        local picks = {}
        QT.SetGuide = function(self, id)
            picks[#picks + 1] = id
            self.guideID = id
        end
        QT.guideID = nil
        ToonAge.Guides = {
            zul = {
                id = "zul", title = "Midnight: Zul'Aman (Campaign)",
                zone = 2437, minLevel = 80, maxLevel = 90,
                steps = { { type = "quest", questID = 572, text = "Dirty Deeds" } },
            },
        }
        -- His log quests are not in either Midnight guide. The level
        -- pass still used to take Zul'Aman, then Void Assaults.
        SetLog({
            { questID = 100, title = "Restoring Jade's Purity", isHeader = false },
            { questID = 94382, title = "Ritual Problems", isHeader = false },
        })
        QT:AutoSelectGuide()
        ToonAge.Guides.naigtal = {
            id = "naigtal", title = "Midnight: Void Assaults & Naigtal",
            zone = 2537, minLevel = 86, maxLevel = 90,
            steps = { { type = "quest", questID = 5, text = "Void Assaults" } },
        }
        QT:AutoSelectGuide()
        FLIP = table.concat(picks, ",")
    """)
    check("a later Midnight guide does not replace the first", lua.eval("FLIP"), "")

    hud = lua51.LuaRuntime(unpack_returned_tuples=True)
    hud.execute(BOOT)
    hud.execute(WIDGET)
    hud.execute(read("Modules/Navigation/Arrow.lua"))
    hud.execute(read("Modules/Navigation/NavHud.lua"))
    hud.execute(r"""
        local A = ToonAge.Arrow
        local H = ToonAge.NavHud
        ToonAge.charDB = { arrow = { visible = false }, navhud = { visible = false, userChose = true } }
        A:Init()
        SAVED_OFF = A.ShouldShowOnLogin and A:ShouldShowOnLogin() or false
        H:Init()
        CHOSE_OFF = H.GetSetting("visible")
        SHOWN_OFF = H:IsVisible() and true or false

        ToonAge.charDB = { arrow = {}, navhud = { visible = false } }
        A.frame:Hide()
        A:Init()
        DEFAULT_ON = A.ShouldShowOnLogin and A:ShouldShowOnLogin() or false
        ARROW_SHOWN = A.frame:IsShown() and true or false
        H:Init()
        POISON_ON = H.GetSetting("visible")
        HUD_SHOWN = H:IsVisible() and true or false

        A.frame = nil
        A:Toggle()
        TOGGLE_SHOWN = A.frame and A.frame:IsShown() and true or false
        A:Toggle()
        TOGGLE_HIDDEN = A.frame and (not A.frame:IsShown()) and true or false

        H.SetSetting("scale", 1.40)
        H.SetSetting("opacity", 0.85)
        H:ApplySettings()
        local function scaleOf(frame)
            if frame and frame.GetScale then return frame:GetScale() end
            return -1
        end
        local function alphaOf(frame)
            if frame and frame.GetAlpha then return frame:GetAlpha() end
            return -1
        end
        S140 = scaleOf(A.frame)
        O085 = alphaOf(A.frame)
        HS140 = scaleOf(H.frame)
        HO085 = alphaOf(H.frame)
        H.SetSetting("opacity", 1.00)
        H:ApplySettings()
        O100 = alphaOf(A.frame)
        H.SetSetting("scale", 2.50)
        H.SetSetting("opacity", 0.10)
        H:ApplySettings()
        S250 = H.GetSetting("scale")
        O010 = H.GetSetting("opacity")
        AS250 = scaleOf(A.frame)
        AO010 = alphaOf(A.frame)

        local pt = H.frame and H.frame._points and H.frame._points[#H.frame._points]
        ANCHOR = pt and (pt[1] .. ":" .. tostring(pt[2]) .. ":" .. tostring(pt[3]) .. ":" .. tostring(pt[4])) or ""
        ToonAge.charDB.navhud.x = 15
        ToonAge.charDB.navhud.y = -20
        ToonAge.charDB.navhud.point = "TOPLEFT"
        ToonAge.charDB.navhud.relPoint = "BOTTOMLEFT"
        ToonAge.charDB.navhud.userPlaced = nil
        if H.ApplyAnchor then H:ApplyAnchor() end
        local function pointOf(frame)
            local row = frame and frame._points and frame._points[#frame._points]
            if not row then return "" end
            return row[1] .. ":" .. tostring(row[2]) .. ":" .. tostring(row[3]) .. ":" .. tostring(row[4])
        end
        STALE = pointOf(H.frame)
        ToonAge.charDB.navhud.userPlaced = true
        if H.ApplyAnchor then H:ApplyAnchor() end
        DRAG = pointOf(H.frame)
    """)
    check("a saved arrow off stays off", hud.eval("SAVED_OFF"), False)
    check("a chosen HUD off stays off", hud.eval("CHOSE_OFF"), False)
    check("a chosen HUD off is not shown", hud.eval("SHOWN_OFF"), False)
    check("retail arrow defaults on", hud.eval("DEFAULT_ON"), True)
    check("retail arrow is shown on login", hud.eval("ARROW_SHOWN"), True)
    check("a saved HUD off from the old default turns on", hud.eval("POISON_ON"), True)
    check("the HUD is shown when that default is repaired", hud.eval("HUD_SHOWN"), True)
    check("toggle shows the arrow immediately", hud.eval("TOGGLE_SHOWN"), True)
    check("toggle hides the arrow immediately", hud.eval("TOGGLE_HIDDEN"), True)
    check("scale 1.40 reaches the arrow", hud.eval("S140"), 1.4)
    check("opacity 0.85 reaches the arrow", hud.eval("O085"), 0.85)
    check("scale 1.40 reaches the HUD", hud.eval("HS140"), 1.4)
    check("opacity 0.85 reaches the HUD", hud.eval("HO085"), 0.85)
    check("opacity 1.00 reaches the arrow", hud.eval("O100"), 1.0)
    check("scale 2.50 clamps to 2", hud.eval("S250"), 2.0)
    check("opacity 0.10 clamps to 0.25", hud.eval("O010"), 0.25)
    check("clamped scale reaches the arrow", hud.eval("AS250"), 2.0)
    check("clamped opacity reaches the arrow", hud.eval("AO010"), 0.25)
    check("default anchor is the center of UIParent", hud.eval("ANCHOR"), "CENTER:CENTER:0:0")
    check("a stored offset is ignored until a drag", hud.eval("STALE"), "CENTER:CENTER:0:0")
    check("a drag keeps the saved point", hud.eval("DRAG"), "TOPLEFT:BOTTOMLEFT:15:-20")

    passed, total = sum(_results), len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
