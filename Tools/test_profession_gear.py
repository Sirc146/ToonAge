#!/usr/bin/env python3
"""
ToonAge -- retail profession gear suggestions
=============================================
Under each profession card, retail draws the tool and two accessories from
C_TradeSkillUI's slot calls. Weights come from specialization points plus a
base skill weight. Stat names and GetItemStats keys stay in the data file.

  * No slot calls -> no row.
  * A better bag item is named with the upgrade marker 4px after the name.
  * The tooltip names the stat and the path points, from the data file.
  * An item that does not clear the margin is not suggested.
  * A closed bank keeps the cache. An open bank replaces it.
  * Equip is a secure button and is not armed in combat.

Usage:  python3 Tools/test_profession_gear.py [-v]
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
            return self.modules[name]
        end
    """)
    return lua


FRAME = r"""
local function Mock(name)
    local f = { _name = name }
    setmetatable(f, { __index = function(s, k)
        if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
        local fn
        if k == "CreateTexture" or k == "CreateFontString" then
            fn = function() return Mock(name .. "_child") end
        elseif k == "SetScript" then
            fn = function(self, script, handler)
                self._scripts = self._scripts or {}
                self._scripts[script] = handler
                return self
            end
        elseif k == "GetScript" then
            fn = function(self, script)
                return self._scripts and self._scripts[script]
            end
        else
            fn = function() return s end
        end
        rawset(s, k, fn)
        return fn
    end })
    return f
end
CreateFrame = function() return Mock("frame") end
UIParent = CreateFrame()
GameTooltip = Mock("tip")
"""

CLIENT = r"""
NUM_BAG_SLOTS = 4
NUM_BANKBAGSLOTS = 7
BANK_CONTAINER = -1
BANK_SLOTS = 0

Enum = {
    Profession = { Blacksmithing = 1 },
    ProfessionsSpecPathState = { Locked = 0, Progressing = 1, Completed = 2 },
}

local ITEMS = {
    ["item:10"] = { name = "Worn Hammer", equipLoc = "INVTYPE_PROFESSION_TOOL", subclass = 1, stats = { multicraft = 1 } },
    ["item:99"] = { name = "Better Hammer", equipLoc = "INVTYPE_PROFESSION_TOOL", subclass = 1, stats = { multicraft = 5 } },
    ["item:70"] = { name = "Herbalist Sickle", equipLoc = "INVTYPE_PROFESSION_TOOL", subclass = 4, stats = { multicraft = 100 } },
    ["item:77"] = { name = "Cached Charm", equipLoc = "INVTYPE_PROFESSION_GEAR", subclass = 1, stats = { multicraft = 3 } },
    ["item:88"] = { name = "Bank Charm", equipLoc = "INVTYPE_PROFESSION_GEAR", subclass = 1, stats = { multicraft = 9 } },
    ["item:501"] = { name = "Crafted Hammer", equipLoc = "INVTYPE_PROFESSION_TOOL", subclass = 1, stats = { multicraft = 8 } },
}

local function Row(item)
    if type(item) == "number" then item = "item:" .. tostring(item) end
    return ITEMS[item]
end

function GetItemInfo(item)
    local row = Row(item)
    if not row then return nil end
    return row.name, item, 2, 10, 1, "Profession", "Tool", 1, row.equipLoc, nil, 0, 19, row.subclass
end

C_Item = {
    GetItemStats = function(item)
        local row = Row(item)
        if not row then return nil end
        local key = STAT_KEY
        return { [key] = row.stats.multicraft }
    end,
}

C_TradeSkillUI = {
    GetProfessionSkillLineID = function(prof)
        if prof == 1 then return 164 end
        return nil
    end,
    GetProfessionSlots = function(prof)
        if prof == 1 then return { 20, 21, 22 } end
        return nil
    end,
}

C_ProfSpecs = {
    GetConfigIDForSkillLine = function(id)
        if id == 2907 then return 55 end
        return nil
    end,
    GetSpecTabIDsForSkillLine = function(id)
        if id == 2907 then return { 9 } end
        return nil
    end,
    GetTabInfo = function() return { rootNodeID = 100 } end,
    GetRootPathForTab = function() return 100 end,
    GetChildrenForPath = function(pathID)
        if pathID == 100 then return { 200, 300 } end
        return {}
    end,
    GetStateForPath = function(pathID)
        if pathID == 300 then return 0 end
        return 1
    end,
    GetSpendEntryForPath = function(pathID) return pathID + 1000 end,
}

C_Traits = {
    GetNodeInfo = function(configID, nodeID)
        if configID ~= 55 then return nil end
        if nodeID == 200 then return { ranksPurchased = 25, entryIDs = { 1200 } } end
        if nodeID == 300 then return { ranksPurchased = 40, entryIDs = { 1300 } } end
        if nodeID == 100 then return { ranksPurchased = 0, entryIDs = { 1100 } } end
        return nil
    end,
}

function GetInventoryItemLink(unit, slot)
    if unit == "player" and slot == 20 then return "item:10" end
    return nil
end
function GetInventoryItemID(unit, slot)
    if unit == "player" and slot == 20 then return 10 end
    return nil
end

local BAG = {
    [0] = { [1] = "item:99", [2] = "item:70" },
}
function GetContainerNumSlots(bag)
    if bag == 0 then return 2 end
    if bag == -1 then return BANK_SLOTS end
    return 0
end
function GetContainerItemLink(bag, slot)
    if bag == -1 and slot == 1 and BANK_SLOTS > 0 then return "item:88" end
    local b = BAG[bag]
    return b and b[slot] or nil
end
function GetContainerItemID(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

ToonAge.Utils = {
    GetItemInfo = GetItemInfo,
    GetContainerNumSlots = GetContainerNumSlots,
    GetContainerItemLink = GetContainerItemLink,
    GetContainerItemID = GetContainerItemID,
    MarkItemName = function(text, kind)
        return text
    end,
    GearMark = function() return "" end,
    RequestItemInfo = function(id) ASKED = id end,
}
ToonAge.charDB = {
    professionGearBank = {
        { itemID = 77, name = "Cached Charm", link = "item:77",
          equipLoc = "INVTYPE_PROFESSION_GEAR", subclassID = 1 },
    },
}
"""


def load_gear(lua):
    lua.execute(read("Core/Utils.lua"))
    lua.execute("REAL_MARK = ToonAge.Utils.MarkItemName")
    lua.execute(read("Data/Retail/ProfessionSkills.lua"))
    lua.execute(read("Data/Retail/professions_retail.lua"))
    lua.execute(read("Modules/Character/ProfessionGear.lua"))
    # The client stub replaces Utils. Put the real marker back: the test
    # has to see the 4px upgrade texture, not a stand-in.
    lua.execute(CLIENT)
    lua.execute(r"""
        local data = ToonAge.Data.ProfessionGear
        for _, stat in ipairs(data.stats) do
            if stat.id == "multicraft" then
                STAT_KEY = stat.key
                STAT_NAME = stat.name
            end
        end
        data.paths = {
            { id = 200, name = "X", stats = { "multicraft" } },
            { id = 300, name = "Locked Path", stats = { "resourcefulness" } },
        }
        ToonAge.Utils.MarkItemName = REAL_MARK
        ToonAge.Utils.GetItemInfo = GetItemInfo
        ToonAge.Utils.GetContainerNumSlots = GetContainerNumSlots
        ToonAge.Utils.GetContainerItemLink = GetContainerItemLink
        ToonAge.Utils.GetContainerItemID = GetContainerItemID
        CARD = {
            id = 164,
            name = "Blacksmithing",
            segments = { { id = 2907, current = true, label = "Midnight" } },
        }
    """)


def test_sources_stay_in_the_data_file():
    src = read("Modules/Character/ProfessionGear.lua")
    board = read("Modules/Character/ProfessionBoard.lua")
    for word in ("Multicraft", "Resourcefulness", "Ingenuity", "Deftness",
                 "Finesse", "Perception", "ITEM_MOD_", "Crafting Speed"):
        check(f"scorer does not contain {word}", word in src, False)
    check("board does not name the spec API", "C_ProfSpecs" in board, False)
    check("board does not name the slot API", "GetProfessionSlots" in board, False)
    camelot = read("ToonAge_Camelot.toc")
    check("forever toc skips the gear module", "ProfessionGear.lua" in camelot, False)
    check("forever toc skips the gear table", "professions_retail.lua" in camelot, False)
    for toc in ("ToonAge.toc", "ToonAge_Mainline.toc"):
        text = read(toc)
        check(f"{toc} lists the gear module", "Modules\\Character\\ProfessionGear.lua" in text, True)
        check(f"{toc} lists the gear table", "Data\\Retail\\professions_retail.lua" in text, True)
    for toc in ("ToonAge_TBC.toc", "ToonAge_Mists.toc", "ToonAge_Vanilla.toc"):
        text = read(toc)
        check(f"{toc} does not list the gear module", "ProfessionGear.lua" in text, False)


def test_weights_and_margin():
    lua = runtime()
    load_gear(lua)
    lua.execute(r"""
        local PG = ToonAge.ProfessionGear
        local data = ToonAge.Data.ProfessionGear
        local spent = PG.ReadSpent(CARD)
        WEIGHTS, SOURCES = PG.BuildWeights(data, spent)
        LINE = PG.Explain(STAT_NAME, SOURCES.multicraft.points, SOURCES.multicraft.path)
        local skillKey
        for _, stat in ipairs(data.stats) do
            if stat.id == data.skillStat then skillKey = stat.key end
        end
        SKILL_W = WEIGHTS[skillKey]
        MULTI_W = WEIGHTS[STAT_KEY]
        local resKey
        for _, stat in ipairs(data.stats) do
            if stat.id == "resourcefulness" then resKey = stat.key end
        end
        RES_W = WEIGHTS[resKey]
    """)
    check("base skill weight is kept", lua.eval("SKILL_W"), 1)
    check("path points become that stat's weight", lua.eval("MULTI_W"), 25)
    check("a locked path adds no weight", lua.eval("RES_W"), None)
    check("current expansion spec is the one that was read",
          lua.eval("SOURCES.multicraft.points"), 25)
    name = lua.eval("STAT_NAME")
    check("tooltip uses the data-file stat name and the path",
          lua.eval("LINE"), f"+{name}, matches your 25 pts in X")
    check("shipped data file names Multicraft", name, "Multicraft")
    check("a tie does not beat the margin", lua.eval("ToonAge.ProfessionGear.Beats(10, 10, 0)"), False)
    check("clearing the margin beats", lua.eval("ToonAge.ProfessionGear.Beats(11, 10, 0)"), True)
    check("inside the margin does not", lua.eval("ToonAge.ProfessionGear.Beats(15, 10, 5)"), False)


def test_suggestions_bank_and_marker():
    lua = runtime()
    load_gear(lua)
    lua.execute("plan = ToonAge.ProfessionGear.Plan(CARD)")
    check("three slots", lua.eval("#plan.slots"), 3)
    check("tool shows the equipped item", lua.eval("plan.slots[1].equipped"), "Worn Hammer")
    check("empty accessory stays empty", lua.eval("plan.slots[3].equipped"), "Empty")
    suggestion = lua.eval("plan.slots[1].suggestion")
    check("suggested name comes first", suggestion.startswith("Better Hammer"), True)
    check("upgrade marker sits 4px after the name", ":16:16:4:0:" in suggestion, True)
    check("the other profession's tool is not suggested", "Herbalist" in (suggestion or ""), False)
    check("bag item can be equipped", lua.eval("plan.slots[1].equip"), "0 1")
    name = lua.eval("STAT_NAME")
    check("tooltip explains the winning stat",
          lua.eval("plan.slots[1].why[1]"), f"+{name}, matches your 25 pts in X")
    check("closed bank still suggests the cached accessory",
          lua.eval("plan.slots[2].suggestionPlain"), "Cached Charm")
    check("a bank item is not a secure equip", lua.eval("plan.slots[2].equip"), None)
    check("cache key is not the heirloom bank",
          lua.eval("ToonAge.charDB.heirloomBank"), None)
    check("closed bank keeps the saved item",
          lua.eval("ToonAge.charDB.professionGearBank[1].itemID"), 77)

    lua.execute(r"""
        BANK_SLOTS = 1
        plan = ToonAge.ProfessionGear.Plan(CARD)
    """)
    check("open bank replaces the cache",
          lua.eval("ToonAge.charDB.professionGearBank[1].itemID"), 88)
    check("open bank suggests the live item",
          lua.eval("plan.slots[2].suggestionPlain"), "Bank Charm")

    lua.execute(r"""
        BANK_SLOTS = 0
        local data = ToonAge.Data.ProfessionGear
        data.margin = 1000
        plan = ToonAge.ProfessionGear.Plan(CARD)
    """)
    check("below the margin is not suggested", lua.eval("plan.slots[1].suggestion"), None)
    check("below the margin has no equip", lua.eval("plan.slots[1].equip"), None)

    lua.execute(r"""
        local data = ToonAge.Data.ProfessionGear
        data.margin = 0
        data.items = {
            { itemID = 501, profession = 164, slot = "tool", source = "Craft", expansion = "Midnight" },
        }
        -- Nothing in the bags, so the listed craft is the candidate.
        GetContainerNumSlots = function() return 0 end
        ToonAge.Utils.GetContainerNumSlots = GetContainerNumSlots
        plan = ToonAge.ProfessionGear.Plan(CARD)
    """)
    check("listed craft is suggested when it wins",
          lua.eval("plan.slots[1].suggestionPlain"), "Crafted Hammer")
    check("listed craft says where it comes from", lua.eval("plan.slots[1].why[2]"), "Craft")
    check("an unowned craft is not a secure equip", lua.eval("plan.slots[1].equip"), None)

    lua.execute(r"""
        ToonAge.Data.ProfessionGear.items[1].expansion = "Dragonflight"
        plan = ToonAge.ProfessionGear.Plan(CARD)
    """)
    check("another expansion's craft is not a candidate",
          lua.eval("plan.slots[1].suggestion"), None)


def test_hidden_without_slots_and_combat_lock():
    lua = runtime()
    load_gear(lua)
    lua.execute(r"""
        C_TradeSkillUI.GetProfessionSlots = nil
        missing = ToonAge.ProfessionGear.Plan(CARD)
        C_TradeSkillUI.GetProfessionSlots = function(prof)
            if prof == 1 then return { 20, 21, 22 } end
        end
        btn = {}
        btn.SetAttribute = function(self, k, v) self[k] = v; self._set = true end
        btn.Disable = function(self) self._disabled = true end
        btn.Enable = function(self) self._enabled = true end
        btn.label = { Hide = function() end, Show = function() end }
        btn.lock = { Show = function() end, Hide = function() end }
        InCombatLockdown = function() return true end
        armed = ToonAge.ProfessionGear.ArmEquip(btn, "0 1", false)
        InCombatLockdown = function() return false end
        btn2 = {}
        btn2.SetAttribute = function(self, k, v) self[k] = v; self._set = true end
        btn2.Enable = function(self) self._enabled = true end
        btn2.label = { Show = function() end, Hide = function() end }
        btn2.lock = { Hide = function() end, Show = function() end }
        ToonAge.ProfessionGear.ArmEquip(btn2, "0 1", false)
    """)
    check("missing slot call hides the row", lua.eval("missing"), None)
    lua.execute(r"""
        C_TradeSkillUI.GetProfessionSlots = function(prof)
            if prof == 1 then return 20, 21, 22 end
        end
        loose = ToonAge.ProfessionGear.Plan(CARD)
        C_TradeSkillUI.GetProfessionSlots = function(prof)
            if prof == 1 then return { 20, 21, 22 } end
        end
    """)
    check("loose slot returns still make three slots", lua.eval("loose and #loose.slots"), 3)
    check("combat does not arm equip", lua.eval("armed"), False)
    check("combat sets no item attribute", lua.eval("btn._set"), None)
    check("combat disables the button", lua.eval("btn._disabled"), True)
    check("out of combat the button equips that bag slot", lua.eval("btn2.item"), "0 1")
    check("out of combat the button type is item", lua.eval("btn2.type"), "item")

    lua.execute(FRAME)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(r"""
        PARENT = CreateFrame()
        PARENT.GetWidth = function() return 480 end
        InCombatLockdown = function() return false end
        local y = ToonAge.ProfessionGear:Draw(PARENT, -20, CARD)
        DRAW_Y = y
        local btn = ToonAge.ProfessionGear._secureButtons[1]
        DRAW_SETUP = btn and btn._setup
        DRAW_TEXT = nil
    """)
    # The row is 76px plus the layout gap.
    check("gear row advances the layout", lua.eval("DRAW_Y"), -20 - 76 - 8)
    check("draw arms the bag slot", lua.eval("DRAW_SETUP"), "0 1")
    lua.execute(r"""
        C_TradeSkillUI.GetProfessionSlots = nil
        local y = ToonAge.ProfessionGear:Draw(PARENT, -20, CARD)
        HIDDEN_Y = y
    """)
    check("draw without slots leaves y alone", lua.eval("HIDDEN_Y"), -20)
    lua.execute(r"""
        local _, row = ToonAge.Layout:ProfessionGearRow(PARENT, -8, { slots = {
            { label = "Tool", equipped = "Worn", suggestionPlain = "Better",
              why = { "tool reason" } },
            { label = "Accessory", equipped = "Empty", suggestionPlain = "Charm",
              why = { "charm reason" } },
        } })
        TIP = {}
        GameTooltip.SetOwner = function() end
        GameTooltip.SetText = function(_, text) TIP[#TIP + 1] = text end
        GameTooltip.AddLine = function(_, text) TIP[#TIP + 1] = text end
        GameTooltip.Show = function() end
        row.cols[1]:GetScript("OnEnter")(row.cols[1])
        FIRST = TIP[2]
        TIP = {}
        row.cols[2]:GetScript("OnEnter")(row.cols[2])
        SECOND = TIP[2]
    """)
    check("first slot tooltip is that slot's reason", lua.eval("FIRST"), "tool reason")
    check("second slot tooltip is not the first slot's", lua.eval("SECOND"), "charm reason")


def test_board_asks_for_the_row():
    lua = runtime()
    lua.execute(r"""
        ToonAge.Layout = {
            CharacterSidebar = function() end,
            SectionHeader = function(_, _, y) return y - 8 end,
            Paragraph = function(_, _, y) return y - 8 end,
            ProfessionCard = function(_, _, y) return y - 58 end,
            Finish = function() end,
        }
        ToonAge.ProfessionSkills = {
            Collect = function()
                return { reader = "segments", cards = {
                    { id = 164, name = "Blacksmithing", rank = 1, max = 100 },
                } }
            end,
        }
    """)
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(read("Modules/Character/ProfessionGear.lua"))
    lua.execute(r"""
        DRAWN = 0
        function ToonAge.ProfessionGear:Draw(parent, y, card)
            DRAWN = DRAWN + 1
            DRAWN_ID = card.id
            return y - 40
        end
        function ToonAge.ProfessionGear:Begin() BEGAN = true end
        ToonAge.modules.ProfessionBoard:Render({}, nil)
    """)
    check("the board starts a gear pass", lua.eval("BEGAN"), True)
    check("the board draws one gear row per card", lua.eval("DRAWN"), 1)
    check("the row is that profession", lua.eval("DRAWN_ID"), 164)
    lua.execute(r"""
        ToonAge.ProfessionSkills.Collect = function()
            return { cards = {}, reader = nil }
        end
        DRAWN = 0
        ToonAge.modules.ProfessionBoard:Render({}, nil)
    """)
    check("no professions means no gear row", lua.eval("DRAWN"), 0)


def main():
    test_sources_stay_in_the_data_file()
    test_weights_and_margin()
    test_suggestions_bank_and_marker()
    test_hidden_without_slots_and_combat_lock()
    test_board_asks_for_the_row()
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
