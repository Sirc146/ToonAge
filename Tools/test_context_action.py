#!/usr/bin/env python3
"""
ToonAge -- shared context-action button
=======================================
One secure button, above the action bars, reused by the Overload reminder
and by guide quest items. Quest items win. Secure changes and the keybind
wait until the player is out of combat.

Usage:  python3 Tools/test_context_action.py [-v]
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


def check(name, got, want):
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


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { modules = {} }")
    lua.execute(r"""
        function ToonAge:RegisterModule(name, module)
            self.modules[name] = module
        end
        function ToonAge:GetModule(name)
            local mod = self.modules[name]
            if not mod or mod._disabled or mod._profileSkipped then return nil end
            return mod
        end
    """)
    lua.execute(read("Modules/Infrastructure/ContextAction.lua"))
    lua.execute(read("Modules/Navigation/QuestContext.lua"))
    return lua


FRAME = r"""
local function Mock(name)
    local f = { _name = name or "frame", _shown = false, _attrs = {}, _sets = 0, _shows = 0, _hides = 0 }
    function f:SetSize() end
    function f:SetFrameStrata() end
    function f:SetMovable() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:RegisterForClicks() end
    function f:SetClampedToScreen() end
    function f:SetBackdrop() end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor(r, g, b) self._rgb = { r, g, b } end
    function f:SetPoint(a, b, c, d, e) self._point = { a, c, d, e } end
    function f:ClearAllPoints() end
    function f:SetScript(which, fn) self[which] = fn end
    function f:SetAllPoints() end
    function f:SetDrawEdge() end
    function f:SetTexCoord() end
    function f:SetText(text) self._text = text end
    function f:SetFont() end
    function f:SetJustifyH() end
    function f:SetTextColor() end
    function f:Hide() self._hides = self._hides + 1; self._shown = false end
    function f:Show() self._shows = self._shows + 1; self._shown = true end
    function f:SetTexture(path) self._tex = path end
    function f:SetCooldown(start, duration) self._swipe = { start, duration } end
    function f:SetAttribute(k, v) self._attrs[k] = v; self._sets = self._sets + 1 end
    function f:CreateTexture()
        local t = Mock(name .. "_tex")
        t.SetTexture = function(_, path) f._icon = path; t._tex = path end
        return t
    end
    function f:CreateFontString() return Mock(name .. "_fs") end
    return f
end
UIParent = Mock("parent")
CreateFrame = function(_, name) return Mock(name) end
GameTooltip = Mock("tip")
InCombatLockdown = function() return false end
BINDS = {}
CLEARS = 0
function SetOverrideBindingClick(_, _, key, buttonName, mouse)
    BINDS[#BINDS + 1] = { key = key, button = buttonName, mouse = mouse }
end
function ClearOverrideBinding() CLEARS = CLEARS + 1 end
"""


def test_files_and_settings():
    button = read("Modules/Infrastructure/ContextAction.lua")
    quest = read("Modules/Navigation/QuestContext.lua")
    check("shared button does not name C_QuestLog", "C_QuestLog" in button, False)
    check("shared button applies the override binding", "SetOverrideBindingClick" in button, True)
    check("shared button waits for combat to end", "PLAYER_REGEN_ENABLED" in button, True)
    check("quest items check the global first", "GetQuestLogSpecialItemInfo" in quest, True)
    check("quest items can use the namespaced lookup",
          "C_QuestLog.GetQuestLogSpecialItemInfo" in quest, True)
    for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_TBC.toc",
                "ToonAge_Mists.toc", "ToonAge_Camelot.toc", "ToonAge_Vanilla.toc"):
        check(f"{toc} lists the shared button",
              "Modules\\Infrastructure\\ContextAction.lua" in read(toc), True)
    for toc in ("ToonAge_Cata.toc", "ToonAge_Wrath.toc"):
        check(f"{toc} stays a core scaffold",
              "ContextAction.lua" in read(toc), False)
    for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_Mists.toc"):
        check(f"{toc} lists quest items",
              "Modules\\Navigation\\QuestContext.lua" in read(toc), True)
    for toc in ("ToonAge_TBC.toc", "ToonAge_Camelot.toc", "ToonAge_Vanilla.toc"):
        check(f"{toc} has no quest-item driver",
              "QuestContext.lua" in read(toc), False)
    check("forever still has no overload reminder",
          "ProfessionOverload.lua" in read("ToonAge_Camelot.toc"), False)
    settings = read("Modules/Infrastructure/Settings.lua")
    check("settings has the keybind section", "CONTEXT ACTION" in settings, True)
    check("settings row follows the module", 'Has("ContextAction")' in settings, True)
    check("the keybind label lives on the shared button",
          "Context action keybind" in button, True)
    check("mists settings has the keybind row",
          "Context action keybind" in read("Modules/Mists/Settings.lua")
          or "DrawKeybindRow" in read("Modules/Mists/Settings.lua"), True)
    check("diagnostics print the current source",
          "ContextAction:StatusLine" in read("Core/Init.lua"), True)
    check("the tracker no longer keeps a second item button",
          "TAQuestItemButton" in read("Modules/Navigation/QuestTracker.lua"), False)


def test_quest_item_rules():
    lua = runtime()
    lua.execute(r"""
        local CA = ToonAge.ContextAction
        local QC = ToonAge.QuestContext
        SPECIAL = QC.ParseSpecial("|cff9d9d9d|Hitem:2468::::::::1:::::::::|h[Dented Canteen]|h|r", "Interface\\Icons\\INV_Drink_01")
        NAME_ONLY = QC.ParseSpecial("Dented Canteen", "Interface\\Icons\\INV_Drink_01")
        EMPTY = QC.ParseSpecial("", nil)
        FROM_API = CA.QuestCandidate({
            special = { itemID = 2468, name = "Dented Canteen", texture = "icon" },
            fallbackID = 999,
            fallbackCount = 1,
            near = true,
        })
        FROM_GUIDE = CA.QuestCandidate({
            fallbackID = 999,
            fallbackCount = 1,
            near = true,
        })
        EMPTY_BAG = CA.QuestCandidate({
            fallbackID = 999,
            fallbackCount = 0,
            near = true,
        })
        UNKNOWN_BAG = CA.QuestCandidate({
            fallbackID = 999,
            near = true,
        })
        FAR = CA.QuestCandidate({
            special = { itemID = 2468, name = "Dented Canteen" },
            near = false,
            targeting = false,
        })
        TARGETED = CA.QuestCandidate({
            fallbackID = 999,
            fallbackCount = 1,
            targeting = true,
        })
        NEAR = CA.WithinRange(14, nil)
        FAR_YARDS = CA.WithinRange(16, 15)
        NAMES = CA.ObjectiveNames({ "Wolf 0/8", "Slain: Boar 1/3" })
        HIT = CA.TargetMatches("Wolf", nil, NAMES, nil)
        IDHIT = CA.TargetMatches("Renamed", 42, {}, { 42 })
        MISS = CA.TargetMatches("Deer", 7, NAMES, { 42 })
        GUID = CA.UnitID("Creature-0-1-2-3-42-9")
        OBJECT = CA.UnitID("GameObject-0-1-2-3-99-1")
        PLAYER = CA.UnitID("Player-1-2")
    """)
    check("a link yields the item id", lua.eval("SPECIAL.itemID"), 2468)
    check("a link keeps the texture", lua.eval("SPECIAL.texture"), "Interface\\Icons\\INV_Drink_01")
    check("a bare name is kept", lua.eval("NAME_ONLY.name"), "Dented Canteen")
    check("an empty lookup is nothing", lua.eval("EMPTY"), None)
    check("the quest-log item wins over the guide id", lua.eval("FROM_API.itemID"), 2468)
    check("the quest-log item is what the button uses", lua.eval("FROM_API.action"), "Dented Canteen")
    check("the guide id is the fallback", lua.eval("FROM_GUIDE.action"), "item:999")
    check("a missing bag item stays hidden", lua.eval("EMPTY_BAG"), None)
    check("an unknown bag count still offers the guide item", lua.eval("UNKNOWN_BAG.action"), "item:999")
    check("far from the objective and not targeting it stays hidden", lua.eval("FAR"), None)
    check("targeting the objective shows the item", lua.eval("TARGETED.action"), "item:999")
    check("the default range is 15 yards", lua.eval("NEAR"), True)
    check("past the step range is not near", lua.eval("FAR_YARDS"), False)
    check("objective text yields the creature name", lua.eval("NAMES[1]"), "wolf")
    check("the target name matches that creature", lua.eval("HIT"), True)
    check("a creature id matches", lua.eval("IDHIT"), True)
    check("a different target does not match", lua.eval("MISS"), False)
    check("creature guid id is the sixth field", lua.eval("GUID"), 42)
    check("gameobject guid id is the sixth field", lua.eval("OBJECT"), 99)
    check("players are not objectives", lua.eval("PLAYER"), None)

    lua.execute(r"""
        function GetQuestLogSpecialItemInfo()
            return "From Global", "global-icon"
        end
        C_QuestLog = { GetQuestLogSpecialItemInfo = function() return "From Namespace", "ns-icon" end }
        GLOBAL_WINS = ToonAge.QuestContext.ReadSpecial(3)
        GetQuestLogSpecialItemInfo = nil
        NAMESPACE = ToonAge.QuestContext.ReadSpecial(3)
        NONE = ToonAge.QuestContext.ReadSpecial(nil)
    """)
    check("GetQuestLogSpecialItemInfo is used when it exists",
          lua.eval("GLOBAL_WINS.name"), "From Global")
    check("the namespaced lookup runs when the global is missing",
          lua.eval("NAMESPACE.name"), "From Namespace")
    check("no log index does not ask", lua.eval("NONE"), None)


def test_priority_combat_and_binding():
    lua = runtime()
    lua.execute(FRAME)
    lua.execute(r"""
        local CA = ToonAge.ContextAction
        CA:Init()
        POINT = CA._button._point[1]
        GAP = CA._button._point[4]
        HIDES = CA._button._hides
        SHOWS = CA._button._shows
        SETS = CA._button._sets
        InCombatLockdown = function() return true end
        CA:Set("overload", {
            source = "overload", kind = "spell", action = 9001,
            icon = "Interface\\Icons\\INV_Misc_QuestionMark", priority = 10,
        })
        COMBAT_HIDES = CA._button._hides
        COMBAT_SHOWS = CA._button._shows
        COMBAT_SETS = CA._button._sets
        DIRTY = CA._dirty
        CA:SetKey("G")
        BINDS_IN_COMBAT = #BINDS
        InCombatLockdown = function() return false end
        CA:OnEvent("PLAYER_REGEN_ENABLED")
        SPELL = CA._button._attrs.spell
        KIND = CA._button._attrs.type
        SHOWN = CA._button._shown
        GOLD = CA._button._rgb[1]
        SOURCE = CA:StatusLine()
        BOUND = BINDS[#BINDS].key
        BOUND_BUTTON = BINDS[#BINDS].button
        CA:Set("quest item", {
            source = "quest item", kind = "item", action = "item:2468",
            itemID = 2468, icon = "Interface\\Icons\\INV_Drink_01", priority = 20,
            cooldown = { start = 10, duration = 4 },
        })
        ITEM = CA._button._attrs.item
        ITEM_KIND = CA._button._attrs.type
        ITEM_ICON = CA._button._icon
        SWIPE = CA._button.cooldown._swipe[1]
        QUEST_LINE = CA:StatusLine()
        SECRET = {}
        function issecretvalue(v) return v == SECRET end
        CA:Set("quest item", {
            source = "quest item", kind = "item", action = "item:2468",
            itemID = 2468, priority = 20,
            cooldown = { start = 1, duration = SECRET },
        })
        SWIPE_AFTER = CA._button.cooldown._swipe[1]
        CA:SetKey("SHIFT-F")
        KEY2 = BINDS[#BINDS].key
    """)
    check("the button sits above the action bars", lua.eval("POINT"), "BOTTOM")
    check("the default gap clears the bar", lua.eval("GAP"), 72)
    check("combat does not hide the button", lua.eval("COMBAT_HIDES"), lua.eval("HIDES"))
    check("combat does not show the button", lua.eval("COMBAT_SHOWS"), lua.eval("SHOWS"))
    check("combat does not change attributes", lua.eval("COMBAT_SETS"), lua.eval("SETS"))
    check("combat queues the change", lua.eval("DIRTY"), True)
    check("combat does not apply the keybind", lua.eval("BINDS_IN_COMBAT"), 0)
    check("leaving combat arms the queued spell", lua.eval("SPELL"), 9001)
    check("the secure type is spell", lua.eval("KIND"), "spell")
    check("leaving combat shows the button", lua.eval("SHOWN"), True)
    check("showing it starts the gold glow", lua.eval("GOLD"), 0.910)
    check("diagnostics name the overload", lua.eval("SOURCE"), "Context action: overload")
    check("the queued keybind is applied after combat", lua.eval("BOUND"), "G")
    check("the binding clicks the shared button", lua.eval("BOUND_BUTTON"), "TAContextActionButton")
    check("a quest item replaces the overload", lua.eval("ITEM"), "item:2468")
    check("the secure type becomes item", lua.eval("ITEM_KIND"), "item")
    check("the item icon is shown", lua.eval("ITEM_ICON"), "Interface\\Icons\\INV_Drink_01")
    check("the cooldown swipe uses the item cooldown", lua.eval("SWIPE"), 10)
    check("diagnostics name the quest item", lua.eval("QUEST_LINE"), "Context action: quest item")
    check("a secret cooldown is not passed to the swipe", lua.eval("SWIPE_AFTER"), 10)
    check("a shifted key is stored as a binding", lua.eval("KEY2"), "SHIFT-F")

    lua = runtime()
    lua.execute(FRAME)
    lua.execute(r"""
        ToonAge.charDB = { questItem = { x = 40, y = 80 } }
        local CA = ToonAge.ContextAction
        CA:Init()
        SAVED_POINT = CA._button._point[1]
        SAVED_X = CA._button._point[3]
        SAVED_Y = CA._button._point[4]
        IsShiftKeyDown = function() return true end
        CA:CaptureKey("F")
        CAPTURED = ToonAge.db.contextActionKey
        CA:CaptureKey("LSHIFT")
        STILL = ToonAge.db.contextActionKey
        CA:CaptureKey("ESCAPE")
        CLEARED = ToonAge.db.contextActionKey
    """)
    check("a saved quest-item position is reused", lua.eval("SAVED_POINT"), "TOPLEFT")
    check("the saved x is kept", lua.eval("SAVED_X"), 40)
    check("the saved y is kept", lua.eval("SAVED_Y"), 80)
    check("shift is part of the captured binding", lua.eval("CAPTURED"), "SHIFT-F")
    check("the modifier key alone does not replace it", lua.eval("STILL"), "SHIFT-F")
    check("escape clears the binding", lua.eval("CLEARED"), None)


def test_refresh_prefers_the_quest_item():
    lua = runtime()
    lua.execute(r"""
        local CA = ToonAge.ContextAction
        local QC = ToonAge.QuestContext
        ToonAge.modules.QuestTracker = {
            guideID = "demo",
            stepIdx = 1,
        }
        ToonAge.Guides = {
            demo = { steps = { { questID = 100, questItem = 999, text = "Use the canteen on the Wolf" } } },
        }
        function GetQuestLogIndexByID() return 4 end
        function GetQuestLogSpecialItemInfo() return "Dented Canteen", "icon" end
        function IsQuestLogSpecialItemInRange() return 1 end
        CA:Set("overload", {
            source = "overload", kind = "spell", action = 9001, priority = CA.OVERLOAD_PRIORITY,
        })
        QC:Refresh()
        WINNER = CA:StatusLine()
        ACTION = CA._offers["quest item"].action
        CA:Set("overload", nil)
        QC:Refresh()
        STILL = CA:StatusLine()
        IsQuestLogSpecialItemInRange = function() return 0 end
        UnitExists = function() return true end
        UnitName = function() return "Wolf" end
        UnitGUID = function() return "Creature-0-1-2-3-5-1" end
        QC:Refresh()
        BY_TARGET = CA:StatusLine()
        UnitName = function() return "Deer" end
        QC:Refresh()
        GONE = CA:StatusLine()
    """)
    check("the quest item wins over overload", lua.eval("WINNER"), "Context action: quest item")
    check("the button uses the quest-log item", lua.eval("ACTION"), "Dented Canteen")
    check("clearing overload leaves the quest item", lua.eval("STILL"), "Context action: quest item")
    check("targeting the objective shows the item when range says no",
          lua.eval("BY_TARGET"), "Context action: quest item")
    check("leaving the objective clears the quest item", lua.eval("GONE"), "Context action: none")


def main():
    test_files_and_settings()
    test_quest_item_rules()
    test_priority_combat_and_binding()
    test_refresh_prefers_the_quest_item()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
