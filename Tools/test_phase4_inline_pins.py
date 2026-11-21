#!/usr/bin/env python3
"""Tests for Phase 4 Inline Cleanup & Smart Pins.

Verifies:
1. Rotation._DueAndCoverage skips auto-attack entries (Attack, Auto Shot, Shoot, Throw).
2. Character tab embeds live XP/hr & ETA inline on Experience bar and omits legacy popup buttons.
3. SessionCheck:Summary() + Now:Render() render inline session delta with zero ShowCopyWindow popups.
4. GatherTracker:GetSummary() + ProfessionBoard:Render() render inline Gathering log card.
5. Pins auto-learns Study locations, deduplicates within 3 map units, merges AllLibraries,
   routes to nearest library on current continent with cross-continent fallback, and toggles to clear.
6. Scrolls tab renders toggleable library & Light Feathers pin buttons.

Usage:  python3 Tools/test_phase4_inline_pins.py [-v]
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
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


PRELUDE = r"""
ToonAge = {
    modules = {},
    Data = {},
    flavor = "forever",
    IsForever = true,
    version = "test",
    LOG = { OUTPUT = 0, INFO = 3 },
    db = {},
    charDB = {
        gatherHistory = {
            [1413] = {
                { type = "herb", x = 0.4, y = 0.5 },
                { type = "herb", x = 0.45, y = 0.55 },
                { type = "ore",  x = 0.3, y = 0.2 },
            },
            [1411] = {
                { type = "skin", x = 0.6, y = 0.6 },
            },
        },
    },
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name)
    local m = self.modules[name]
    if not m or m._disabled then return nil end
    return m
end
function ToonAge:GetRegisteredModule(name) return self.modules[name] end
function ToonAge:Print() end
function ToonAge:Raw() end
function ToonAge:RegisterEvent() end
_copyWindowCalls = 0
function ToonAge:ShowCopyWindow() _copyWindowCalls = _copyWindowCalls + 1 end
ToonAge._ApplyBackdrop = function() end
ToonAge.Utils = {
    IsSecret = function() return false end,
    StripMarkup = function(s) return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end,
    Trim = function(s) return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "") end,
    Glyph = function() return "-" end,
    SafeNum = function(v, fb) return tonumber(v) or fb end,
    RankNumberFromSubtext = function(s) return tonumber(tostring(s or ""):match("Rank (%d+)")) end,
    SpellRankTableName = function() return "ForeverSpellRanks" end,
    AssignSpellRanks = function() end,
    SpellRankHigher = function(a, b) return (a.learned or 0) > (b.learned or 0) end,
    GetPlayerName = function() return "Examplechar" end,
    GetPlayerLevel = function() return 19 end,
    GetPlayerClassLocalized = function() return "Mage" end,
    GetPlayerClass = function() return "MAGE" end,
    GetPlayerRace = function() return "Undead", "Scourge" end,
    GetPlayerSpec = function() return 0, "Arcane" end,
}

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = "ChatFontNormal"
UIParent = nil
issecretvalue = function() return false end

UnitName = function() return "Examplechar" end
UnitLevel = function() return 19 end
UnitClass = function() return "Mage", "MAGE" end
UnitRace = function() return "Undead", "Scourge" end
UnitFactionGroup = function() return "Horde", "Horde" end
UnitGUID = function() return "Player-1-EXAMPLE" end
GetRealmName = function() return "TestRealm" end
UnitXP = function() return 5573 end
UnitXPMax = function() return 21300 end
GetXPExhaustion = function() return 3778 end
UnitHealth = function() return 420 end
UnitHealthMax = function() return 420 end
UnitPower = function() return 680 end
UnitPowerMax = function() return 680 end
UnitStat = function() return 20, 20, 0, 0 end
UnitArmor = function() return 100, 100, 0, 0 end
UnitResistance = function() return 0, 0, 0, 0 end
GetInventoryItemID = function(_, slot)
    if slot == 16 then return 2001 end
    return nil
end
GetInventoryItemLink = function() return nil end
GetAverageItemLevel = function() return 12 end
GetMoney = function() return 19131 end
GetMoneyString = function() return "1g 91s 31c" end
GetSubZoneText = function() return "Hall of Arcana" end
C_Map = { GetBestMapForUnit = function() return 1413 end }
C_Item = {
    GetItemNameByID = function(id) return id == 2001 and "Apprentice Staff" or nil end,
    GetItemInfo = function(id) return id == 2001 and "Apprentice Staff" or nil end,
}
C_Spell = {
    GetSpellName = function(sid) return sid == 1296999 and "Study" or nil end,
}
C_Timer = { After = function() end }
GameTooltip = setmetatable({}, { __index = function() return function() end end })

local function Widget(kind)
    local f = {
        kind = kind, _children = {}, _regions = {}, _shown = true, scripts = {},
        _text = "", _fontSize = 10, _w = 0, _h = 0,
    }
    setmetatable(f, {
        __index = function(_, key)
            if key == "GetChildren" then return function(self) return unpack(self._children) end end
            if key == "GetRegions" then return function(self) return unpack(self._regions) end end
            local head = type(key) == "string" and key:sub(1, 3) or ""
            if head == "Set" or head == "Get" or head == "Ena" or head == "Is"
                or key == "Hide" or key == "Show" or key == "ClearAllPoints" then
                return function() end
            end
            return nil
        end,
    })
    function f:SetParent(p)
        self._parent = p
        if type(p) == "table" and p._children then p._children[#p._children + 1] = self end
    end
    function f:GetParent() return self._parent end
    function f:SetSize(w, h) self._w, self._h = w, h end
    function f:SetWidth(w) self._w = w end
    function f:SetHeight(h) self._h = h end
    function f:GetWidth() return self._w or 0 end
    function f:GetHeight() return self._h or 0 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:SetFont(_, sz) if sz then self._fontSize = sz end end
    function f:GetStringWidth() return #self._text * 5 end
    function f:GetStringHeight() return 12 end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetScript(ev, fn) self.scripts[ev] = fn end
    function f:GetScript(ev) return self.scripts[ev] end
    function f:CreateTexture()
        local t = Widget("Texture"); t._parent = self; self._regions[#self._regions + 1] = t; return t
    end
    function f:CreateFontString()
        local fs = Widget("FontString"); fs._parent = self; self._regions[#self._regions + 1] = fs; return fs
    end
    return f
end

function CreateFrame(kind, name, parent)
    local f = Widget(kind)
    if parent then f:SetParent(parent) end
    if name then _G[name] = f end
    return f
end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Forever/Rotation.lua"))
    lua.execute(read("Modules/Forever/SessionCheck.lua"))
    lua.execute(read("Modules/Forever/Now.lua"))
    lua.execute(read("Modules/Forever/Character.lua"))
    lua.execute(read("Modules/Farming/GatherTracker.lua"))
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(read("Modules/Forever/Pins.lua"))
    lua.execute(read("Modules/Forever/Scrolls.lua"))

    # 1. Rotation._DueAndCoverage skips auto-attack entries (Attack, Auto Shot, Shoot, Throw)
    r1 = lua.eval(r"""
    (function()
        local R = ToonAge:GetModule("ForeverRotation")
        local lines = {
            { name = "General", spells = {
                { name = "Attack", spellID = 6603, learned = 1 },
                { name = "Shoot",  spellID = 5019, learned = 1 },
            }},
            { name = "Fire", spells = {
                { name = "Fireball", spellID = 145, learned = 12 },
            }},
        }
        local catalog = {
            ["Attack"]   = { { id = 6603, n = 1, learned = 1 }, { id = 99999, n = 2, learned = 10 } },
            ["Shoot"]    = { { id = 5019, n = 1, learned = 1 }, { id = 99998, n = 2, learned = 10 } },
            ["Fireball"] = { { id = 145, n = 3, learned = 12 }, { id = 3140, n = 4, learned = 18 } },
        }
        local due = R._DueAndCoverage(lines, catalog, 19)
        local names = {}
        for i, d in ipairs(due) do names[i] = d.name end
        return { count = #due, first = names[1], hasAttack = (names[1] == "Attack" or names[2] == "Attack") }
    end)()
    """)
    check("DueAndCoverage skips Attack/Shoot and returns only Fireball",
          (r1["count"], r1["first"], r1["hasAttack"]), (1, "Fireball", False))

    # 2. Character tab inline XP/hr + ETA, zero legacy popup buttons
    r2 = lua.eval(r"""
    (function()
        ToonAge:RegisterModule("XPTracker", {
            GetRate = function() return 14200, 236.6 end,
            GetLevelETA = function() return 3960 end,
        })
        local C = ToonAge:GetModule("ForeverCharacter")
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 500)
        C:Render(content, nil)
        local texts = {}
        local function walk(f)
            for _, reg in ipairs(f._regions or {}) do
                if reg._text and reg._text ~= "" then texts[#texts + 1] = reg._text end
            end
            for _, ch in ipairs(f._children or {}) do
                if ch._text and ch._text ~= "" then texts[#texts + 1] = ch._text end
                walk(ch)
            end
        end
        walk(content)
        local blob = table.concat(texts, "\n")
        return {
            hasRested = blob:find("3778 rested banked", 1, true) ~= nil,
            hasRate   = blob:find("14.2k XP/hr", 1, true) ~= nil,
            hasETA    = blob:find("Lv 20 in ~1h 06m", 1, true) ~= nil,
            noSince   = blob:find("Since last session", 1, true) == nil,
            noXPBtn   = blob:find("XP rate", 1, true) == nil,
            noGathBtn = blob:find("Gathering", 1, true) == nil,
            noLibBtn  = blob:find("Suggest library", 1, true) == nil,
        }
    end)()
    """)
    check("Character tab shows rested + XP/hr + Level ETA inline on Experience bar",
          (r2["hasRested"], r2["hasRate"], r2["hasETA"]), (True, True, True))
    check("Character tab removes legacy popup/chat-dump button row",
          (r2["noSince"], r2["noXPBtn"], r2["noGathBtn"], r2["noLibBtn"]), (True, True, True, True))

    # 3. SessionCheck:Summary() + Now:Render() inline delta, zero popups
    r3 = lua.eval(r"""
    (function()
        ToonAge.db.sessionSnap = {
            ["Player-1-EXAMPLE"] = {
                at = 1795240000,
                level = 18,
                equipped = { [16] = 1999 },
                due = {},
            },
        }
        local SC = ToonAge:GetModule("ForeverSessionCheck")
        local sum = SC:Summary()
        local Now = ToonAge:GetModule("ForeverNow")
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 500)
        Now:Render(content, nil)
        local texts = {}
        local function walk(f)
            for _, reg in ipairs(f._regions or {}) do
                if reg._text and reg._text ~= "" then texts[#texts + 1] = reg._text end
            end
            for _, ch in ipairs(f._children or {}) do walk(ch) end
        end
        walk(content)
        local blob = table.concat(texts, "\n")
        return {
            gained = sum.levelsGained,
            eqCount = #sum.equipChanges,
            eqName = sum.equipChanges[1],
            hasDeltaRow = blob:find("Level 18 -> 19 (+1)", 1, true) ~= nil,
            hasGearRow  = blob:find("1 gear swap", 1, true) ~= nil,
            copyPopups  = _copyWindowCalls,
        }
    end)()
    """)
    check("SessionCheck:Summary computes level gain + gear swap",
          (r3["gained"], r3["eqCount"], r3["eqName"]), (1, 1, "Apprentice Staff"))
    check("Now tab renders inline Since last login delta with zero modal popups",
          (r3["hasDeltaRow"], r3["hasGearRow"], r3["copyPopups"]), (True, True, 0))

    # 4. GatherTracker:GetSummary() + ProfessionBoard inline Gathering log card
    r4 = lua.eval(r"""
    (function()
        local GT = ToonAge:GetModule("GatherTracker")
        local sum = GT:GetSummary()
        ToonAge.ProfessionSkills = { Collect = function() return { reader = true, cards = {} } end }
        local PB = ToonAge:GetModule("ProfessionBoard")
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 500)
        PB:Render(content, nil)
        local texts = {}
        local function walk(f)
            for _, reg in ipairs(f._regions or {}) do
                if reg._text and reg._text ~= "" then texts[#texts + 1] = reg._text end
            end
            for _, ch in ipairs(f._children or {}) do walk(ch) end
        end
        walk(content)
        local blob = table.concat(texts, "\n")
        return {
            total = sum.total, zones = sum.zones,
            herbs = sum.herbs, ore = sum.ore, skin = sum.skin, here = sum.hereNodes,
            hasHeader = blob:find("Gathering log", 1, true) ~= nil,
            hasCounts = blob:find("2 herbs", 1, true) ~= nil and blob:find("1 ore", 1, true) ~= nil,
            hasHere   = blob:find("3 nodes recorded in your current zone", 1, true) ~= nil,
        }
    end)()
    """)
    check("GatherTracker:GetSummary counts herbs/ore/skin + current zone",
          (r4["total"], r4["zones"], r4["herbs"], r4["ore"], r4["skin"], r4["here"]),
          (4, 2, 2, 1, 1, 3))
    check("ProfessionBoard renders inline Gathering log card",
          (r4["hasHeader"], r4["hasCounts"], r4["hasHere"]), (True, True, True))

    # 5. Smart Pins: auto-learn Study spots, dedupe, continent routing, fallback, toggle-to-clear + Scrolls buttons
    r5 = lua.eval(r"""
    (function()
        local P = ToonAge:GetModule("ForeverPins")
        ToonAge.db.studyLibraries = nil
        -- Built-in Horde libraries now include Undercity (Owen Thadd) + Orgrimmar (Darkbriar Lodge Study)
        local builtInCount = #P.AllLibraries("Horde")
        local added1 = P.RecordStudySpot("Horde", "Thunder Bluff", 1456, 22.34, 18.67, "Spirit Rise")
        local addedDup = P.RecordStudySpot("Horde", "Thunder Bluff", 1456, 23.0, 19.0, "Spirit Rise")
        local allH = P.AllLibraries("Horde")

        -- Wire lightweight Arrow + Compat to test SuggestLibrary & ToggleLibraryPin
        local cleared = 0
        local lastPin = nil
        local Arrow = {
            manualWaypoint = nil,
            MapIDForZone = function(z)
                if z == "Undercity" then return 1458 end
                if z == "Orgrimmar" then return 1454 end
                if z == "Thunder Bluff" then return 1456 end
                return nil
            end,
            WalkContinent = function(id)
                if id == 1454 or id == 1456 or id == 1413 then return 1 end -- Kalimdor
                if id == 1458 then return 2 end -- Eastern Kingdoms
                return nil
            end,
            SetWaypoint = function(self, mapID, x, y, title)
                self.manualWaypoint = { map = mapID, x = x, y = y, title = title }
                lastPin = { map = mapID, title = title }
            end,
            ClearActiveWaypoint = function(self)
                self.manualWaypoint = nil
                cleared = cleared + 1
            end,
        }
        ToonAge:RegisterModule("Arrow", Arrow)
        ToonAge.Compat = {
            PlayerFaction = function() return "Horde" end,
            BestMapForUnit = function() return 1413 end, -- The Barrens (Kalimdor)
            PlayerMapFraction = function() return 0.5, 0.5 end,
            WorldPosFromMapPos = function(id, x, y)
                if id == 1413 then return 1, 100, 100 end
                if id == 1456 then return 1, 105, 102 end -- closer learned Thunder Bluff spot
                if id == 1454 then return 1, 140, 130 end -- built-in Orgrimmar Darkbriar Lodge
                return 2, 500, 500
            end,
            MapInfo = function() return nil end,
        }

        -- In Kalimdor with closer learned Spirit Rise spot -> picks Spirit Rise!
        local pinned1 = P:ToggleLibraryPin()
        local firstTitle = lastPin and lastPin.title
        local isPinAfter1 = P:IsPinned("library")

        -- Second toggle clears active pin!
        local pinned2 = P:ToggleLibraryPin()
        local isPinAfter2 = P:IsPinned("library")

        -- With no learned spots, Kalimdor Horde picks built-in Orgrimmar Darkbriar Lodge (not Undercity!)
        ToonAge.db.studyLibraries = nil
        local pinnedKalimdor = P:SuggestLibrary()
        local kalimdorTitle = lastPin and lastPin.title

        -- Scrolls tab renders library pin button
        local S = ToonAge:GetModule("ForeverScrolls")
        S.ScanBags = function() return {}, 0 end
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 500)
        S:Render(content, nil)
        local texts = {}
        local function walk(f)
            for _, reg in ipairs(f._regions or {}) do
                if reg._text and reg._text ~= "" then texts[#texts + 1] = reg._text end
            end
            for _, ch in ipairs(f._children or {}) do
                if ch._text and ch._text ~= "" then texts[#texts + 1] = ch._text end
                walk(ch)
            end
        end
        walk(content)
        local blob = table.concat(texts, "\n")

        return {
            builtInCount = builtInCount,
            added1 = added1,
            addedDup = addedDup,
            allCount = #allH,
            pinned1 = pinned1,
            firstTitle = firstTitle,
            isPinAfter1 = isPinAfter1,
            pinned2 = pinned2,
            isPinAfter2 = isPinAfter2,
            cleared = cleared,
            pinnedKalimdor = pinnedKalimdor,
            kalimdorTitle = kalimdorTitle,
            scrollsHasClearLib = blob:find("Clear library pin", 1, true) ~= nil,
            scrollsHasFeathers = blob:find("Pin Light Feathers AH", 1, true) ~= nil,
        }
    end)()
    """)
    check("RecordStudySpot saves new Study spot and deduplicates nearby coords",
          (r5["builtInCount"], r5["added1"], r5["addedDup"], r5["allCount"]), (2, True, False, 3))
    check("ToggleLibraryPin prefers closer learned Kalimdor Study spot",
          (r5["pinned1"], r5["firstTitle"], r5["isPinAfter1"]), (True, "Study: Spirit Rise", True))
    check("ToggleLibraryPin clears active pin on second click",
          (r5["pinned2"], r5["isPinAfter2"], r5["cleared"]), (False, False, 1))
    check("SuggestLibrary in Kalimdor picks built-in Orgrimmar Darkbriar Lodge (Study)",
          (r5["pinnedKalimdor"], r5["kalimdorTitle"]), (True, "Darkbriar Lodge (Study)"))
    check("Scrolls tab renders active library pin toggle & Light Feathers AH button",
          (r5["scrollsHasClearLib"], r5["scrollsHasFeathers"]), (True, True))

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
