#!/usr/bin/env python3
"""Midnight campaign guides load, and authored guides have no 0,0 coordinates.

Eversong, Harandar, Zul'Aman and Voidstorm are the campaign. Arator's Journey
is the side route offered after Eversong. The Darkening Sky is optional.
Scenario steps carry no waypoint. 86528 is the hollow approximate marker.
Map 14 and 2372 are both Arathi Highlands. useItem steps use the shared
context-action button.
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


def toc_guides(rel):
    names = []
    for line in read(rel).splitlines():
        line = line.strip()
        if line.startswith("Data\\Retail\\Guides\\") and line.endswith(".lua"):
            names.append(line.replace("\\", "/"))
    return names


BOOT = r"""
ToonAge = {
    modules = {},
    flavor = "retail",
    GuideData = {},
    Guides = {},
    LOG = { OUTPUT = 1, INFO = 2 },
    db = { contextActionKey = "SHIFT-1" },
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
function ToonAge:Raw() end
"""

WIDGET = r"""
local function Widget()
    local w = { _attrs = {}, _shown = false }
    function w:SetSize(a, b) self._w, self._h = a, b end
    function w:SetText(t) self._text = t end
    function w:SetAttribute(k, v) self._attrs[k] = v end
    function w:SetBackdropBorderColor(r, g, b, a) self._border = { r, g, b, a } end
    function w:Hide() self._shown = false end
    function w:Show() self._shown = true end
    function w:CreateTexture() return Widget() end
    function w:CreateFontString() return Widget() end
    function w:CreateFrame() return Widget() end
    setmetatable(w, { __index = function() return function() end end })
    return w
end
UIParent = Widget()
function CreateFrame() return Widget() end
GameTooltip = Widget()
InCombatLockdown = function() return false end
function SetOverrideBindingClick() end
function ClearOverrideBinding() end
C_Map = {
    GetMapInfo = function(id)
        if id == 2372 then return { name = "Arathi Highlands", parentMapID = 13 } end
        if id == 2393 then return { name = "Silvermoon City", parentMapID = 2395 } end
        return nil
    end,
    GetBestMapForUnit = function() return 14 end,
}
C_QuestLog = {
    GetNextWaypoint = function() return 2405, 0.5, 0.5 end,
    GetLogIndexForQuestID = function() return 1 end,
}
"""


def main():
    retail = toc_guides("ToonAge.toc")
    mainline = toc_guides("ToonAge_Mainline.toc")
    check("both retail TOCs list the same guides", retail, mainline)
    joined = "\n".join(retail)
    check("Eversong is before Harandar",
          joined.find("TAG_Midnight_Eversong_Woods.lua") < joined.find("TAG_Midnight_Harandar.lua"))
    check("Harandar is before Zul'Aman",
          joined.find("TAG_Midnight_Harandar.lua") < joined.find("TAG_Midnight_Zulaman.lua"))
    check("Zul'Aman is before Voidstorm",
          joined.find("TAG_Midnight_Zulaman.lua") < joined.find("TAG_Midnight_Voidstorm.lua"))
    check("Arator's Journey is listed", "TAG_Midnight_Arators_Journey.lua" in joined)
    camelot = read("ToonAge_Camelot.toc")
    check("Forever TOC does not load the Arathi side route",
          "TAG_Midnight_Arators_Journey.lua" in camelot, False)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read("Core/Utils.lua"))
    for rel in retail:
        lua.execute(read(rel))
    lua.execute(read("Modules/Navigation/GuideParser.lua"))

    lua.execute(r"""
        local r = ToonAge.GuideParser:AuditLoaded()
        AUDIT = r
        MID_N = #r.midnight
        MID_1 = r.midnight[1]
        FAIL_N = #r.failed
        BAD = r.bad
        LOADED = r.loaded
        DATA = r.data
        STUBS = r.stubs
        USES = r.useItems
        NILC = r.nilCoord
        NOARROW = r.noArrow
        SAW14 = r.saw14
        SAW2372 = r.saw2372
        HOLO = r.holokey
    """)
    check("every guide data file loaded", lua.eval("FAIL_N"), 0)
    check("guides are resident", lua.eval("LOADED") == lua.eval("DATA") and lua.eval("LOADED") > 0)
    check("no authored guide has a 0,0 coordinate", lua.eval("BAD"), 0)
    check("Midnight audit is clean", lua.eval("MID_N"), 0)
    if lua.eval("MID_N") != 0:
        print("        first:", lua.eval("MID_1"))
    check("19 useItem steps", lua.eval("USES"), 19)
    check("13 scenario steps", lua.eval("NILC"), 13)
    check("those 13 steps suppress the waypoint", lua.eval("NOARROW"), 13)
    check("map 14 is present", lua.eval("SAW14"), True)
    check("map 2372 is present", lua.eval("SAW2372"), True)
    check("86528 is approximate", lua.eval("HOLO"), True)
    check("stub guides are reported, not failed", lua.eval("STUBS") > 0)

    lua.execute(WIDGET)
    lua.execute(read("Modules/Navigation/Arrow.lua"))
    lua.execute(r"""
        local A = ToonAge.Arrow
        SAME = A.SameMap(14, 2372)
        SAME_SELF = A.SameMap(14, 14)
        DIFF = A.SameMap(14, 2395)
        AREA = A.SameArea(14, 2372)
        CHILD = A.SameArea(2393, 2395)
        NOT_AREA = A.SameArea(14, 2395)
        NAME14 = A.MapName(14)
        NAME2372 = A.MapName(2372)
        TOK14 = A.TokenIsMapID(14)
        TOK2372 = A.TokenIsMapID(2372)
        A:ParseWayCommand("14 68.9 37.7 Stromgarde")
        WAY_MAP = A.manualWaypoint.map
        WAY_X = A.manualWaypoint.x
        WAY_Y = A.manualWaypoint.y
        A:ParseWayCommand("2372 68.5 32.2")
        WAY2 = A.manualWaypoint.map
        local m, x, y = A.GetEffectiveCoord({
            questID = 91958, noArrow = true, text = "inside the den",
        })
        NA_M, NA_X, NA_Y = m, x, y
        m, x, y = A.GetEffectiveCoord({ questID = 99, text = "live" })
        LIVE_M = m
        C_QuestLog.GetLogIndexForQuestID = function() return nil end
        local ok = pcall(function()
            m, x, y = A.GetEffectiveCoord({ text = "no coord" })
            NIL_M, NIL_X, NIL_Y = m, x, y
        end)
        NIL_OK = ok
        HOLLOW = ToonAge.Utils.WaypointHollow({
            estimated = true, coord = { map = 2405, x = 0.357, y = 0.792 },
        })
        local step
        for _, s in ipairs(ToonAge.Guides.midnight_voidstorm_campaign.steps) do
            if s.questID == 86528 and s.type == "accept" then step = s end
        end
        HOLLOW_STEP = ToonAge.Utils.WaypointHollow(step)
        TIP = ToonAge.Utils.CoordsEstimated(step)
    """)
    check("map 14 and 2372 are the same zone", lua.eval("SAME"), True)
    check("a map matches itself", lua.eval("SAME_SELF"), True)
    check("Arathi is not Eversong", lua.eval("DIFF"), False)
    check("14 resolves onto 2372 without GetMapInfo", lua.eval("AREA"), True)
    check("a child map still matches its parent", lua.eval("CHILD"), True)
    check("Arathi does not match Eversong", lua.eval("NOT_AREA"), False)
    check("map 14 is named Arathi Highlands", lua.eval("NAME14"), "Arathi Highlands")
    check("map 2372 is named Arathi Highlands", lua.eval("NAME2372"), "Arathi Highlands")
    check("/ta way accepts map 14", lua.eval("TOK14"), True)
    check("/ta way accepts map 2372", lua.eval("TOK2372"), True)
    check("/ta way 14 sets the classic map", lua.eval("WAY_MAP"), 14)
    check("/ta way 2372 sets the current map", lua.eval("WAY2"), 2372)
    check("map 14 x is the stored coordinate", abs(lua.eval("WAY_X") - 0.689) < 0.0001)
    check("map 14 y is the stored coordinate", abs(lua.eval("WAY_Y") - 0.377) < 0.0001)
    check("a noArrow step has no waypoint", (lua.eval("NA_M"), lua.eval("NA_X"), lua.eval("NA_Y")), (0, 0, 0))
    check("a step with no stored coord can still use the live waypoint", lua.eval("LIVE_M"), 2405)
    check("a missing coord does not crash", lua.eval("NIL_OK"), True)
    check("a missing coord is not 0,0 drawn as a point",
          (lua.eval("NIL_M"), lua.eval("NIL_X"), lua.eval("NIL_Y")), (0, 0, 0))
    check("estimated steps use the hollow marker", lua.eval("HOLLOW"), True)
    check("86528 uses the hollow marker", lua.eval("HOLLOW_STEP"), True)
    check("86528 says the coordinate is approximate", lua.eval("TIP"), True)

    lua.execute(read("Modules/Infrastructure/ContextAction.lua"))
    lua.execute(read("Modules/Navigation/QuestContext.lua"))
    lua.execute(read("Modules/Navigation/QuestTracker.lua"))
    lua.execute(r"""
        local QT = ToonAge.QuestTracker
        local rows = {
            { id = "midnight_voidstorm_campaign", minLevel = 80, order = 40 },
            { id = "midnight_eversong_campaign", minLevel = 80, order = 10 },
            { id = "Midnight", minLevel = 80 },
            { id = "midnight_arators_journey", minLevel = 80, order = 15 },
            { id = "midnight_harandar_campaign", minLevel = 80, order = 20 },
            { id = "midnight_zulaman_campaign", minLevel = 80, order = 30 },
            { id = "midnight_darkening_sky", minLevel = 80, order = 35 },
            { id = "a_low", minLevel = 10 },
        }
        table.sort(rows, QT.CompareGuides)
        ORDER = {}
        for i, row in ipairs(rows) do ORDER[i] = row.id end
        local note = QT.CompletionNote(ToonAge.Guides.midnight_eversong_campaign)
        NOTE = note
        local CA = ToonAge.ContextAction
        local QC = ToonAge.QuestContext
        SIZE = CA.BUTTON_SIZE
        GOLD = CA.FRAME_GOLD[1]
        QC.IsNear = function() return true end
        QC.IsTargeting = function() return false end
        QC.HoveredQuest = function() return nil end
        QC.OwnedQuests = function() return {} end
        QC.LogIndex = function() return nil end
        QC.ReadSpecial = function() return nil end
        GetItemCount = function() return 1 end
        local tracker = ToonAge:GetModule("QuestTracker")
        local ids = {}
        local button
        for _, gid in ipairs({
            "midnight_eversong_campaign", "midnight_harandar_campaign",
            "midnight_zulaman_campaign", "midnight_voidstorm_campaign",
            "midnight_arators_journey", "midnight_darkening_sky",
        }) do
            local guide = ToonAge.Guides[gid]
            for i, step in ipairs(guide.steps) do
                if type(step.useItem) == "number" then
                    tracker.guideID = gid
                    tracker.stepIdx = i
                    QC:Refresh()
                    local plan = CA._plan
                    local action = plan and plan.action
                    ids[#ids + 1] = step.useItem
                    if action ~= "item:" .. tostring(step.useItem) then
                        USE_BAD = gid .. " " .. tostring(action)
                    end
                    button = CA._button
                end
            end
        end
        USE_N = #ids
        USE_BAD = USE_BAD or ""
        BTN_W = button and button._w
        BTN_H = button and button._h
        BTN_GOLD = button and button._border and button._border[1]
        KEY = button and button.keyText and button.keyText._text
        -- The quest log's own item still wins over useItem.
        QC.LogIndex = function() return 1 end
        QC.ReadSpecial = function() return { itemID = 1, name = "Game Item", texture = "Interface\\Icons\\INV_Misc_QuestionMark" } end
        tracker.stepIdx = nil
        for i, step in ipairs(ToonAge.Guides.midnight_arators_journey.steps) do
            if step.useItem then tracker.stepIdx = i break end
        end
        QC:Refresh()
        GAME_WINS = CA._plan and CA._plan.action
    """)
    want_order = [
        "a_low",
        "midnight_eversong_campaign",
        "midnight_arators_journey",
        "midnight_harandar_campaign",
        "midnight_zulaman_campaign",
        "midnight_darkening_sky",
        "midnight_voidstorm_campaign",
        "Midnight",
    ]
    got_order = [lua.eval(f"ORDER[{i}]") for i in range(1, 9)]
    check("guide list order is Eversong, the side route, then Harandar, Zul'Aman, Voidstorm",
          got_order, want_order)
    note = lua.eval("NOTE")
    check("finishing Eversong chains to Harandar", "Harandar" in note)
    check("finishing Eversong offers Arator's Journey", "Arator" in note)
    check("the shared button is 44px", lua.eval("SIZE"), 44)
    check("every useItem step reaches the context button", lua.eval("USE_N"), 19)
    check("useItem actions match the step", lua.eval("USE_BAD"), "")
    check("the button is drawn at 44px", (lua.eval("BTN_W"), lua.eval("BTN_H")), (44, 44))
    check("the button uses the gold frame", abs(lua.eval("BTN_GOLD") - 0.910) < 0.001)
    check("the button shows the keybind", lua.eval("KEY"), "S-1")
    check("the quest-log item wins over useItem", lua.eval("GAME_WINS"), "Game Item")

    failed = sum(1 for ok in _results if not ok)
    print(f"  {len(_results) - failed}/{len(_results)} checks passed")
    return failed == 0


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
