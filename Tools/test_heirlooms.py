#!/usr/bin/env python3
"""Heirloom scan decisions, without a WoW client.

The suggestion rule is item level only: a piece is listed when it beats the
equipped item, or the slot is empty. Retail copy must not claim a bonus-XP
gain. Mists copy must. Era and TBC skip. Forever stays off unless the flag
is flipped.
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


src = read("Modules/Gear/Heirlooms.lua")

lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(r"""
ToonAge = {}
function ToonAge:RegisterModule(name, mod)
    HEIR = mod
end
""")
lua.execute(src)

chunk = r"""
local M = HEIR
local fail = {}
local function eq(name, got, want)
    if got ~= want then
        fail[#fail + 1] = name .. " got " .. tostring(got) .. " want " .. tostring(want)
    end
end

eq("era skips", M.ScanMode("vanilla", true, false), "skip")
eq("tbc skips", M.ScanMode("tbc", true, false), "skip")
eq("forever off", M.ScanMode("forever", true, false), "off")
eq("forever flag uses collection", M.ScanMode("forever", true, true), "collection")
eq("forever flag bags", M.ScanMode("forever", false, true), "bags")
eq("retail collection", M.ScanMode("retail", true, false), "collection")
eq("retail missing api", M.ScanMode("retail", false, false), "missing-api")
eq("mists bags", M.ScanMode("mists", false, false), "bags")
eq("mists collection", M.ScanMode("mists", true, false), "collection")
eq("flag default", M.FOREVER_ENABLED, false)
eq("create absent", M.CreateHeirloomMode(), "absent")

local retail = M.Advice("retail")
local mists = M.Advice("mists")
eq("retail denies bonus xp", retail:find("do not grant bonus experience") ~= nil, true)
eq("retail names the patch", retail:find("9.0.1") ~= nil, true)
eq("mists keeps bonus xp", mists:find("still grant bonus experience") ~= nil, true)
eq("era card", M.EmptyCopy("skip", "vanilla", 0, 0), "No heirlooms here")
local _, tbcSentence = M.EmptyCopy("skip", "tbc", 0, 0)
eq("tbc card", tbcSentence:find("Burning Crusade") ~= nil, true)

local function item(id, ilvl, slots, where)
    return { itemID = id, ilvl = ilvl, slots = slots, where = where or "bag", name = "Loom " .. id }
end

local one = M.Suggest({ item(1, 20, { 1 }) }, {})
eq("empty slot suggests", #one, 1)
eq("empty slot id", one[1].slot, 1)

local weaker = M.Suggest({ item(1, 10, { 1 }) }, { [1] = { ilvl = 25, itemID = 9 } })
eq("weaker heirloom hidden", #weaker, 0)

local better = M.Suggest({ item(1, 30, { 1 }) }, { [1] = { ilvl = 12, itemID = 9 } })
eq("stronger heirloom shown", #better, 1)
eq("records equipped ilvl", better[1].eqIlvl, 12)

local worn = M.Suggest({ item(7, 40, { 5 }) }, { [5] = { ilvl = 10, itemID = 7 } })
eq("already equipped hidden", #worn, 0)

local unknown = M.Suggest({ item(1, 40, { 1 }) }, { [1] = { itemID = 9 } })
eq("unknown equipped ilvl hidden", #unknown, 0)

local rings = M.Suggest({
    item(1, 15, { 11, 12 }),
    item(2, 28, { 11, 12 }),
}, {
    [11] = { ilvl = 20, itemID = 3 },
    [12] = { ilvl = 5, itemID = 4 },
})
eq("two rings, one winner", #rings, 1)
eq("winner fills the weaker ring", rings[1].slot, 12)
eq("winner is the stronger loom", rings[1].item.itemID, 2)

local both = M.Suggest({
    item(1, 30, { 11, 12 }),
    item(2, 28, { 11, 12 }),
}, {})
eq("two empty rings take two looms", #both, 2)

local deduped = M.Dedupe({
    { itemID = 5, where = "collection", name = "C" },
    { itemID = 5, where = "bank", name = "B" },
    { itemID = 5, where = "bag", name = "A" },
})
eq("dedupe keeps one", #deduped, 1)
eq("bag beats bank and collection", deduped[1].where, "bag")

eq("cloth on warlock", M.CanWear(4, 1, 1, "WARLOCK", nil, "retail"), true)
eq("plate on warlock", M.CanWear(4, 4, 1, "WARLOCK", nil, "retail"), false)
eq("mail on warlock", M.CanWear(4, 3, 1, "WARLOCK", nil, "retail"), false)
eq("shield on warlock", M.CanWear(4, 6, 1, "WARLOCK", "INVTYPE_SHIELD", "retail"), false)
eq("cloth on a forever mage", M.CanWear(4, 1, 1, "MAGE", nil, "forever"), true)
eq("leather on a forever mage", M.CanWear(4, 2, 1, "MAGE", nil, "forever"), false)
eq("mail on a forever mage", M.CanWear(4, 3, 1, "MAGE", nil, "forever"), false)
eq("plate on a forever mage", M.CanWear(4, 4, 1, "MAGE", nil, "forever"), false)
eq("shield on a forever mage", M.CanWear(4, 6, 1, "MAGE", "INVTYPE_SHIELD", "forever"), false)
eq("cloak on a forever mage", M.CanWear(4, 1, 1, "MAGE", "INVTYPE_CLOAK", "forever"), true)
eq("wand kept for a mage", M.CanWear(2, 19, 1, "MAGE", "INVTYPE_RANGEDRIGHT", "forever"), true)
eq("plate on warrior", M.CanWear(4, 4, 4, "WARRIOR", nil, "retail"), true)
eq("shield on warrior", M.CanWear(4, 6, 4, "WARRIOR", "INVTYPE_SHIELD", "retail"), true)
eq("shield on paladin", M.CanWear(4, 6, 4, "PALADIN", nil, "retail"), true)
eq("shield on shaman", M.CanWear(4, 6, 3, "SHAMAN", nil, "retail"), true)
eq("shield on hunter", M.CanWear(4, 6, 3, "HUNTER", nil, "retail"), false)
eq("mail on warrior retail", M.CanWear(4, 3, 4, "WARRIOR", nil, "retail"), false)
eq("mail on warrior mists", M.CanWear(4, 3, 4, "WARRIOR", nil, "mists"), true)
eq("cloak on warrior", M.CanWear(4, 1, 4, "WARRIOR", "INVTYPE_CLOAK", "retail"), true)
eq("unknown class excluded", M.CanWear(nil, 4, 4, "WARRIOR", nil, "retail"), false)
eq("unknown subclass excluded", M.CanWear(4, nil, 1, "WARLOCK", nil, "retail"), false)
eq("weapon kept", M.CanWear(2, 7, 1, "WARLOCK", nil, "retail"), true)

ToonAge.flavor = "retail"
C_Heirloom = { GetHeirloomInfo = function() return "Tattered Dreadmist" end }
InCombatLockdown = function() return true end
eq("combat does not open the journal", M.OpenHeirloom({ itemID = 9, name = "Helm" }), "combat")
InCombatLockdown = function() return false end
local calls = {}
local shown = 0
CollectionsJournal_LoadUI = function() calls[#calls + 1] = "load" end
ToggleCollectionsJournal = function(tab) calls[#calls + 1] = "tab:" .. tostring(tab) end
C_Heirloom = {
    GetHeirloomInfo = function() return "Tattered Dreadmist" end,
    SetSearch = function(name) calls[#calls + 1] = "search:" .. tostring(name) end,
    CreateHeirloom = function() calls[#calls + 1] = "create" end,
}
ToonAge.Compat = { GetItemInfo = function() return "Tattered Dreadmist Robe" end }
eq("row searches the journal", M.OpenHeirloom({ itemID = 9, link = "item:9" }), "searched")
eq("loaded the journal UI", calls[1], "load")
eq("closed journal uses toggle", calls[2], "tab:4")
eq("searched the item name", calls[3], "search:Tattered Dreadmist Robe")
eq("did not create the heirloom", calls[4], nil)
eq("closed journal did not call Show", shown, 0)
C_Heirloom.SetSearch = nil
calls = {}
eq("missing SetSearch still opens the tab", M.OpenHeirloom({ itemID = 9 }), "opened")
eq("fallback still loaded the UI", calls[1], "load")
eq("fallback still toggled the tab", calls[2], "tab:4")
eq("fallback did not search", calls[3], nil)
ToonAge.Compat.GetItemInfo = function() return nil end
eq("name falls back to GetHeirloomInfo", M.HeirloomName({ itemID = 9 }), "Tattered Dreadmist")
local probe = table.concat(M.JournalProbe(), "\n")
eq("probe names LoadUI", probe:find("CollectionsJournal_LoadUI present", 1, true) ~= nil, true)
eq("probe names SetTab", probe:find("CollectionsJournal_SetTab absent", 1, true) ~= nil, true)
eq("probe names selected tab", probe:find("PanelTemplates_GetSelectedTab absent", 1, true) ~= nil, true)
eq("probe names frame SetTab", probe:find("CollectionsJournal.SetTab absent", 1, true) ~= nil, true)
eq("probe names toggle", probe:find("ToggleCollectionsJournal present", 1, true) ~= nil, true)
eq("probe names C_Heirloom", probe:find("C_Heirloom present", 1, true) ~= nil, true)
eq("probe names the tab index", probe:find("Heirloom tab index 4", 1, true) ~= nil, true)
eq("probe names SetSearch", probe:find("C_Heirloom.SetSearch absent", 1, true) ~= nil, true)
eq("probe does not create", probe:find("CreateHeirloom present, not called", 1, true) ~= nil, true)

COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS = 9
eq("tab prefers the blizzard constant", M.HeirloomTab(), 9)
COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS = nil
Enum = { CollectionsJournalTab = { Heirlooms = 7 } }
eq("tab prefers the enum", M.HeirloomTab(), 7)
Enum = nil
eq("tab falls back to 4", M.HeirloomTab(), 4)

InCombatLockdown = function() return true end
local notes = {}
ToonAge.LOG = { OUTPUT = 1 }
ToonAge.Print = function(_, _, _, text) notes[#notes + 1] = text end
calls = {}
local combatProbe = table.concat(M.JournalProbe(), "\n")
eq("probe in combat does not toggle", #calls, 0)
eq("probe in combat still reports the api", combatProbe:find("C_Heirloom present", 1, true) ~= nil, true)
eq("probe in combat hint", combatProbe:find("Leave combat to open the Heirloom Journal.", 1, true) ~= nil, true)
eq("probe in combat prints the hint", notes[1], "Leave combat to open the Heirloom Journal.")
InCombatLockdown = function() return false end

calls = {}
shown = 0
C_Heirloom.SetSearch = function(name) calls[#calls + 1] = "search:" .. tostring(name) end
ToonAge.Compat.GetItemInfo = function() return "Tattered Dreadmist Robe" end
local toggled = 0
ToggleCollectionsJournal = function() toggled = toggled + 1 end
CollectionsJournal = {
    IsShown = function() return true end,
    GetSelectedTab = function() return 4 end,
    Show = function() shown = shown + 1 end,
}
eq("shown journal is searched", M.OpenHeirloom({ itemID = 9, link = "item:9" }), "searched")
eq("shown journal is not toggled", toggled, 0)
eq("shown journal is not Show()", shown, 0)
eq("shown journal searched", calls[1], "search:Tattered Dreadmist Robe")

calls = {}
shown = 0
toggled = 0
CollectionsJournal_SetTab = function(_, tab) calls[#calls + 1] = "settab:" .. tostring(tab) end
CollectionsJournal.GetSelectedTab = function() return 1 end
CollectionsJournal.SetTab = function(_, tab) calls[#calls + 1] = "frameset:" .. tostring(tab) end
eq("open journal switches tabs", M.OpenHeirloom({ itemID = 9, link = "item:9" }), "searched")
eq("open journal used SetTab", calls[1], "settab:4")
eq("open journal did not use frame SetTab", calls[2], "search:Tattered Dreadmist Robe")
eq("open journal was not toggled", toggled, 0)
eq("open journal was not Show()", shown, 0)

calls = {}
shown = 0
CollectionsJournal = {
    IsShown = function() return false end,
    Show = function() shown = shown + 1 end,
    SetTab = function(_, tab) calls[#calls + 1] = "frameset:" .. tostring(tab) end,
}
ToggleCollectionsJournal = function(tab) calls[#calls + 1] = "tab:" .. tostring(tab) end
eq("hidden journal toggles", M.OpenHeirloom({ itemID = 9, link = "item:9" }), "searched")
eq("hidden journal toggle carries the tab", calls[2], "tab:4")
eq("hidden journal does not call Show", shown, 0)

notes = {}
calls = {}
C_Heirloom = nil
eq("missing C_Heirloom does not open", M.OpenHeirloom({ itemID = 9, name = "Helm" }), "unavailable")
eq("missing C_Heirloom prints no hint", #notes, 0)
eq("missing C_Heirloom does not toggle", #calls, 0)
eq("missing C_Heirloom click is off", M.JournalClickEnabled(), false)
C_Heirloom = { SetSearch = function() notes[#notes + 1] = "search" end }
for _, flavor in ipairs({ "tbc", "vanilla", "forever" }) do
    ToonAge.flavor = flavor
    notes = {}
    calls = {}
    eq(flavor .. " click stays off", M.JournalClickEnabled(), false)
    eq(flavor .. " open does nothing", M.OpenHeirloom({ itemID = 9, name = "Helm" }), "unavailable")
    eq(flavor .. " prints no hint", #notes, 0)
end
ToonAge.flavor = "retail"
eq("retail click is on when C_Heirloom exists", M.JournalClickEnabled(), true)
local hr, hg, hb, ha = M.RowHover()
eq("hover is gold", hr, 1)
eq("hover gold green", hg, 0.82)
eq("hover gold blue", hb, 0)
eq("hover alpha is low", ha ~= nil and ha > 0 and ha < 0.4, true)
C_Heirloom = nil
eq("no hover without C_Heirloom", M.RowHover(), nil)
C_Heirloom = {}
for _, flavor in ipairs({ "tbc", "vanilla", "forever" }) do
    ToonAge.flavor = flavor
    eq(flavor .. " has no hover", M.RowHover(), nil)
end
ToonAge.flavor = "retail"

local ids = M.BankContainers(4, 7, -1)
eq("main bank plus seven bags", #ids, 8)
eq("main bank is first", ids[1], -1)
eq("first bank bag", ids[2], 5)
eq("last bank bag", ids[8], 11)

local kept = M.NextBankCache({ { itemID = 1 } }, nil)
eq("closed bank keeps cache", kept[1].itemID, 1)
local cleared = M.NextBankCache({ { itemID = 1 } }, {})
eq("open empty bank clears cache", #cleared, 0)
local written = M.NextBankCache(nil, { { itemID = 9 } })
eq("open bank writes cache", written[1].itemID, 9)

local rec = M.BankRecord({ itemID = 3, name = "X", bag = 5, slot = 1, equipLoc = "INVTYPE_HEAD", ilvl = 12 })
eq("cache record drops the bag", rec.bag, nil)
eq("cache record drops the slot", rec.slot, nil)
eq("cache record keeps the item", rec.itemID, 3)
eq("cache record keeps equip loc", rec.equipLoc, "INVTYPE_HEAD")

eq("mists hides upgrade pips", M.UpgradePipCount("mists", 4), 0)
eq("mists hides pips even when the count is missing", M.UpgradePipCount("mists", nil), 0)
eq("retail keeps one pip per tier", M.UpgradePipCount("retail", 4), 4)
eq("retail caps a wild pip count", M.UpgradePipCount("retail", 40), 16)
eq("a missing tier count draws nothing", M.UpgradePipCount("retail", nil), 0)

local bagLine = M.DetailLine("Head", "20", 10, "bag")
eq("bag line omits the bank", bagLine:find("in your bank", 1, true) == nil, true)
local bankLine = M.DetailLine("Head", "20", nil, "bank")
eq("bank line says in your bank", bankLine:find("in your bank", 1, true) ~= nil, true)
eq("bank line names the empty slot", bankLine:find("empty slot", 1, true) ~= nil, true)

if #fail > 0 then
    return table.concat(fail, "\n")
end
return ""
"""
errors = lua.execute(chunk)
check("suggestion and copy rules", errors, "")

check("literal GetHeirloomItemIDs", "C_Heirloom.GetHeirloomItemIDs" in src, True)
check("literal PlayerHasHeirloom", "C_Heirloom.PlayerHasHeirloom" in src, True)
check("literal GetHeirloomInfo", "C_Heirloom.GetHeirloomInfo" in src, True)
check("literal GetHeirloomMaxUpgradeLevel", "C_Heirloom.GetHeirloomMaxUpgradeLevel" in src, True)
check("does not call CreateHeirloom", "pcall(C_Heirloom.CreateHeirloom" not in src, True)
check("journal hint", "Click it in the journal to create it." in src, True)
check("row opens the journal", "M.OpenHeirloom(item)" in src, True)
check("no separate journal button", "Open Heirloom Journal" not in src, True)
check("name colour", "00CCFF" in src, True)
check("pip texture", "util_pip_8.tga" in src, True)
check("lock texture", "util_lock_16.tga" in src, True)
check("secure item attribute", '"type", "item"' in src, True)
check("regen requeue", "PLAYER_REGEN_ENABLED" in src, True)
check("bank open event", "BANKFRAME_OPENED" in src, True)
check("bank slot event", "PLAYERBANKSLOTS_CHANGED" in src, True)
check("bank close snapshot", "BANKFRAME_CLOSED" in src, True)
check("per character bank cache", "heirloomBank" in src, True)
check("mists hides upgrade pips", 'if flavor == "mists" then return 0 end' in src, True)
check("bank note is muted text", 'SetText("In bank")' in src, True)
check("bank rows are not equip buttons", 'MakePlainButton(line, "In bank"' not in src, True)
check("reads containers through the wrapper", "U.GetContainerNumSlots" in src, True)
check("item instant goes through Compat", "TA.Compat.GetItemInfoInstant" in src, True)
check("equippable goes through Compat", "TA.Compat.IsEquippableItem" in src, True)
check("ilvl goes through Compat", "TA.Compat.GetDetailedItemLevelInfo" in src, True)
check("does not call the GetItemInfoInstant global", "pcall(GetItemInfoInstant" not in src, True)
check("owned check remains", "C_Heirloom.PlayerHasHeirloom" in src, True)

for toc, want in (
    ("ToonAge_Mainline.toc", True),
    ("ToonAge.toc", True),
    ("ToonAge_Mists.toc", True),
    ("ToonAge_TBC.toc", True),
    ("ToonAge_Vanilla.toc", False),
    ("ToonAge_Camelot.toc", False),
):
    listed = "Modules\\Gear\\Heirlooms.lua" in read(toc)
    check(f"{toc} lists Heirlooms", listed, want)

ui = read("Core/UI.lua")
check("era empty card", "Classic Era has no heirloom items" in ui, True)
harness = read("Modules/Infrastructure/TestHarness.lua")
check("self-test probes the collection API", "C_Heirloom collection API" in harness, True)
check("self-test reports SetSearch", "Heirloom.SetSearch" in harness, True)
check("self-test reports journal load", "CollectionsJournal_LoadUI" in harness, True)
check("self-test reports the tab switch", "ToggleCollectionsJournal" in harness, True)
check("self-test reports CollectionsJournal_SetTab", "CollectionsJournal_SetTab" in harness, True)
check("self-test reports PanelTemplates_GetSelectedTab", "PanelTemplates_GetSelectedTab" in harness, True)
check("self-test reports CollectionsJournal.SetTab", "CollectionsJournal.SetTab" in harness, True)
check("self-test reports C_Heirloom", 'S(INFO, "C_Heirloom "' in harness, True)
check("self-test reports the tab index", "Heirloom tab index " in harness, True)
check("self-test records CreateHeirloom", "CreateHeirloom" in harness, True)
check("closed journal is not opened with Show", "frame.Show" not in src, True)
check("click is gated on C_Heirloom", "function M.JournalClickEnabled()" in src, True)
check("row click checks the hover gate", 'item.where ~= "bank" and hr' in src, True)
check("hover gold is 1, 0.82, 0", "return 1, 0.82, 0, 0.18" in src, True)
check("hover starts hidden", "highlight:Hide()" in src, True)
check("fallback tab is marked unverified", "UNVERIFIED" in src, True)
profile = read("Core/Profile.lua")
check("tbc profile allows the module", "Heirlooms" in profile, True)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
