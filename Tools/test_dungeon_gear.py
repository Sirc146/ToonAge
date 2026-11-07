#!/usr/bin/env python3
"""Retail tooltip and Dungeon Gear Check must not call removed item globals.

Gear.lua InjectTooltipScore (the TooltipDataProcessor hook) used to call
GetItemInfoInstant. DungeonGear:GetFormattedSuggestions, reached from the
Dungeon Gear Check button, called GetDetailedItemLevelInfo. Both globals
are nil on Retail. The calls go through TA.Compat, and a missing function
returns instead of throwing.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_tbc_boot as boot  # noqa: E402
import test_tbc_render as render  # noqa: E402
from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"  -> {detail}" if detail and not ok else ""))


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


gear = read("Modules/Gear/Gear.lua")
tip = gear[gear.index("local function InjectTooltipScore"):gear.index("local function OnTooltipSetItem")]
check("tooltip score does not call the GetItemInfoInstant global",
      "GetItemInfoInstant(" not in tip.replace("TA.Compat.GetItemInfoInstant", "COMPAT_INSTANT"))
check("tooltip score reads equip location through the nil-safe helper",
      "ReadItemInstant(itemLink)" in tip and 'type(fn) ~= "function"' in gear)

lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(boot.TBC_PRELUDE)
lua.execute(render.OVERRIDES)
lua.execute(r"""
WOW_PROJECT_ID = 1
ToonAge = { modules = {}, Data = {}, LOG = { OUTPUT = 1, INFO = 2 }, charDB = {}, db = {}, Utils = {} }
local TA = ToonAge
function TA:RegisterModule(n, m) self.modules[n] = m; self[n] = m end
function TA:GetModule(n) return self.modules[n] end
function TA:Raw() end
function TA:RegisterEvent() end
GetSpecialization = function() return nil end
GetInventoryItemLink = function(_, slot)
    -- Chest is the empty, weakest slot. It has a Strength piece in the table.
    if slot == 5 then return nil end
    return "item:other"
end
GLOBAL_ILVL = 0
GetDetailedItemLevelInfo = function()
    GLOBAL_ILVL = GLOBAL_ILVL + 1
    error("raw GetDetailedItemLevelInfo")
end
C_Item = {
    GetDetailedItemLevelInfo = function(link)
        C_ILVL = (C_ILVL or 0) + 1
        return 210
    end,
}
""")
lua.execute(read("Core/Compat/API.lua"))
lua.execute(read("Modules/Gear/DungeonGear.lua"))
lua.execute(r"""
    ToonAge.modules.Gear = {}
    local DG = ToonAge.DungeonGear
    local ok, err = pcall(function() LINES = DG:GetFormattedSuggestions() end)
    OK = ok
    ERR = tostring(err)
    N = LINES and #LINES or -1
    GLOBAL_N = GLOBAL_ILVL
    C_N = C_ILVL or 0
    ToonAge.Compat.GetDetailedItemLevelInfo = nil
    GetDetailedItemLevelInfo = nil
    local ok2, err2 = pcall(function() LINES2 = DG:GetFormattedSuggestions() end)
    OK2 = ok2
    ERR2 = tostring(err2)
""")
check("dungeon check does not throw when the global is nil", lua.eval("OK") is True)
if not lua.eval("OK"):
    print("        ", lua.eval("ERR"))
check("dungeon check read ilvl from C_Item", (lua.eval("C_N") or 0) > 0, lua.eval("C_N"))
check("dungeon check did not call the global", lua.eval("GLOBAL_N") == 0, lua.eval("GLOBAL_N"))
check("dungeon check still suggests a slot", (lua.eval("N") or 0) > 0, lua.eval("N"))
check("dungeon check does not throw when both ilvl APIs are missing", lua.eval("OK2") is True)
if not lua.eval("OK2"):
    print("        ", lua.eval("ERR2"))

# Tooltip hook: Retail C_Item only. The removed global must not be called,
# and clearing the Compat function must not throw inside the hook.
lua.execute(r"""
ITEMS = {
  heart = { id = 158075, loc = "INVTYPE_NECK",
            stats = { ITEM_MOD_STAMINA_SHORT = 6, ITEM_MOD_CRIT_RATING_SHORT = 7,
                      ITEM_MOD_HASTE_RATING_SHORT = 7, ITEM_MOD_MASTERY_RATING_SHORT = 7 } },
}
C_Item.GetItemStats = function(link) return ITEMS[link] and ITEMS[link].stats end
C_Item.GetItemInfoInstant = function(link)
    local it = ITEMS[link]
    if it then return it.id, "Armor", "Misc", it.loc end
end
C_Item.GetDetailedItemLevelInfo = function() return 75 end
INSTANT_GLOBAL = 0
GetItemInfoInstant = function()
    INSTANT_GLOBAL = INSTANT_GLOBAL + 1
    error("raw GetItemInfoInstant")
end
GetItemInfo = function(link)
    local it = ITEMS[link]
    if it then return link, link, 3, 75, 70, "Armor", "Misc", 1, it.loc end
end
GetInventoryItemLink = function(_, slot) if slot == 2 then return "heart" end end
GetSpecialization = function() return 1 end
GetSpecializationInfo = function() return 259, "Assassination", "", "", "DAMAGER" end
RATINGS = {}
GetCombatRating = function(i) return RATINGS[i] or 0 end
GetCombatRatingBonus = function() return 0 end
UnitExists = function() return false end
UnitLevel = function() return 80 end
GetProfessions = function() end
HOOKS = {}
TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) HOOKS[#HOOKS + 1] = fn end }
Enum = { TooltipDataType = { Item = 1 } }
ItemRefTooltip = GameTooltip
""")
for rel in ("Core/Utils.lua", "Data/Retail/StatWeights.lua", "Core/StatEngine.lua", "Modules/Gear/Gear.lua"):
    lua.execute(read(rel))
lua.execute(r"""
    local Gear = ToonAge.modules.Gear
    local okInit, errInit = pcall(function() Gear:Init() end)
    INIT_OK = okInit
    INIT_ERR = tostring(errInit)
    local tt = GameTooltip
    tt.GetItem = function() return "Heart", "heart" end
    tt.AddLine = function() end
    tt.AddDoubleLine = function() end
    tt.Show = function() end
    tt.GetName = function() return "GameTooltip" end
    local ok, err = pcall(function() HOOKS[1](tt, {}) end)
    HOOK_OK = ok
    HOOK_ERR = tostring(err)
    GLOBAL_INSTANT = INSTANT_GLOBAL
    -- Score the item without touching item APIs, so this only exercises
    -- the tooltip hook's own GetItemInfoInstant call.
    Gear.CalculateItemScore = function() return 10 end
    ToonAge.Compat.GetItemInfoInstant = nil
    GetItemInfoInstant = nil
    tt["TA_INJECTED"] = nil
    local ok2, err2 = pcall(function() HOOKS[1](tt, {}) end)
    HOOK2_OK = ok2
    HOOK2_ERR = tostring(err2)
""")
check("gear init registers the tooltip hook", lua.eval("INIT_OK") is True)
if not lua.eval("INIT_OK"):
    print("        ", lua.eval("INIT_ERR"))
check("item tooltip hook does not throw", lua.eval("HOOK_OK") is True)
if not lua.eval("HOOK_OK"):
    print("        ", lua.eval("HOOK_ERR"))
check("item tooltip hook does not call global GetItemInfoInstant", lua.eval("GLOBAL_INSTANT") == 0, lua.eval("GLOBAL_INSTANT"))
check("item tooltip hook survives a missing GetItemInfoInstant", lua.eval("HOOK2_OK") is True)
if not lua.eval("HOOK2_OK"):
    print("        ", lua.eval("HOOK2_ERR"))

passed = sum(_results)
print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
sys.exit(0 if passed == len(_results) else 1)
