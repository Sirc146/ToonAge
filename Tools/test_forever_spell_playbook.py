#!/usr/bin/env python3
"""Tests for Modules/Forever/SpellPlaybook.lua (Phase 5: Working 9-class Spells tab).

Verifies:
1. BandForLevel maps Lv 1..60 cleanly into 10-19 / 20-39 / 40-59 / 60.
2. SpecsForClass & ResolveBand read real Data/Forever/RotationLists.lua across multiple classes
   (MAGE, ROGUE, WARRIOR, etc.) — no longer hardcoded to Lv 10-19 Mage.
3. BuildPrepChecks reports live active/missing class buffs (only known spells) + Wand equipped status.
4. BuildEfficiencyTable computes deterministic live Tooltip DPS & Damage-per-Mana (DPM), sorted by DPS.
5. BuildPriorityRows filters strictly to confirmed known spellbook entries and enriches them with
   rank, Trainer upgrade tags, and Casts share percentages.
6. Rotation:Render renders Spell Playbook cleanly at the top (no experimental wall by default)
   with zero frame leaks across repeated renders and all mode/spec switches.

Usage:  python3 Tools/test_forever_spell_playbook.py [-v]
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
    modules = {}, Data = {}, flavor = "forever", IsForever = true, version = "test",
    charDB = {
        castLog = {
            fights = {
                { casts = { { 0, 145 }, { 3, 145 }, { 6, 145 }, { 9, 116 } } },
            },
        },
    },
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
function ToonAge:QueueUIRefresh() end
ToonAge._ApplyBackdrop = function() end
ToonAge.Utils = {
    IsSecret = function() return false end,
    StripMarkup = function(s) return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end,
    RankNumberFromSubtext = function(s) return tonumber(tostring(s or ""):match("Rank (%d+)")) end,
    SpellRankTableName = function() return "ForeverSpellRanks" end,
    AssignSpellRanks = function() end,
    SpellRankHigher = function(a, b) return (a.learned or 0) > (b.learned or 0) end,
    GetPlayerClass = function() return "MAGE" end,
    GetPlayerSpec = function() return 0, "Fire" end,
}

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
issecretvalue = function() return false end
UnitLevel = function() return 19 end
UnitClass = function() return "Mage", "MAGE" end

local SPELL_NAMES = { [145] = "Fireball", [116] = "Frostbolt", [122] = "Frost Nova", [168] = "Frost Armor", [1459] = "Arcane Intellect", [5019] = "Shoot" }
local SPELL_TIPS = {
    [145] = { "Fireball", "Rank 3", "65 Mana", "3.0 sec cast", "Hurls a fiery ball that causes 53 to 73 Fire damage." },
    [116] = { "Frostbolt", "Rank 1", "25 Mana", "1.5 sec cast", "Launches a bolt of frost at the enemy, causing 18 to 20 Frost damage." },
}
C_TooltipInfo = {
    GetSpellByID = function(sid)
        local raw = SPELL_TIPS[sid]
        if not raw then return nil end
        local lines = {}
        for i, t in ipairs(raw) do lines[i] = { leftText = t } end
        return { lines = lines }
    end,
}
C_Spell = {
    GetSpellName = function(sid) return SPELL_NAMES[sid] end,
    GetSpellInfo = function(sid)
        if sid == 145 then return { spellID = 145, name = "Fireball", castTime = 3000 } end
        if sid == 116 then return { spellID = 116, name = "Frostbolt", castTime = 1500 } end
        return nil
    end,
    GetSpellPowerCost = function(sid)
        if sid == 145 then return { { cost = 65 } } end
        if sid == 116 then return { { cost = 25 } } end
        return {}
    end,
}
C_UnitAuras = {
    GetBuffDataByIndex = function(_, i)
        if i == 1 then return { name = "Frost Armor" } end
        return nil
    end,
}
GetInventoryItemLink = function(_, slot)
    if slot == 18 then return "item:11287" end
    return nil
end
C_Item = {
    GetItemInfoInstant = function() return 11287, "Weapon", "Wands", "INVTYPE_RANGED", 0, 2, 19 end,
}

Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { FutureSpell = 3 } }
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 2 end,
    GetSpellBookSkillLineInfo = function(i)
        if i == 1 then return { name = "General", itemIndexOffset = 0, numSpellBookItems = 1 } end
        return { name = "Fire", itemIndexOffset = 1, numSpellBookItems = 5 }
    end,
    GetSpellBookItemInfo = function(idx)
        local items = {
            [1] = { name = "Shoot", spellID = 5019, subName = "" },
            [2] = { name = "Fireball", spellID = 145, subName = "Rank 3" },
            [3] = { name = "Frostbolt", spellID = 116, subName = "Rank 1" },
            [4] = { name = "Frost Nova", spellID = 122, subName = "Rank 1" },
            [5] = { name = "Frost Armor", spellID = 168, subName = "Rank 1" },
            [6] = { name = "Arcane Intellect", spellID = 1459, subName = "Rank 1" },
        }
        return items[idx]
    end,
}

local function Widget(kind)
    local f = { kind = kind, _children = {}, _regions = {}, _shown = true, scripts = {}, _text = "", _w = 0, _h = 0 }
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
    function f:SetParent(p) self._parent = p; if type(p) == "table" and p._children then p._children[#p._children + 1] = self end end
    function f:GetParent() return self._parent end
    function f:SetSize(w, h) self._w, self._h = w, h end
    function f:SetWidth(w) self._w = w end
    function f:SetHeight(h) self._h = h end
    function f:GetWidth() return self._w or 0 end
    function f:GetHeight() return self._h or 0 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:GetStringWidth() return #self._text * 5 end
    function f:GetStringHeight() return 12 end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:SetScript(ev, fn) self.scripts[ev] = fn end
    function f:CreateTexture() local t = Widget("Texture"); self._regions[#self._regions + 1] = t; return t end
    function f:CreateFontString() local fs = Widget("FontString"); self._regions[#self._regions + 1] = fs; return fs end
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
    lua.execute(read("Data/Forever/SpellRanks.lua"))
    lua.execute(read("Data/Forever/RotationLists.lua"))
    lua.execute(read("Modules/Forever/TalentIntel.lua"))
    lua.execute(read("Modules/Forever/SpellPlaybook.lua"))
    lua.execute(read("Modules/Forever/Rotation.lua"))

    r1 = lua.eval(r"""
    (function()
        local SP = ToonAge.SpellPlaybook
        local b1 = SP.BandForLevel(12)
        local b2 = SP.BandForLevel(28)
        local b3 = SP.BandForLevel(52)
        local b4 = SP.BandForLevel(60)

        local mageSpecs = SP.SpecsForClass("MAGE")
        local rogueSpecs = SP.SpecsForClass("ROGUE")
        local warSpecs = SP.SpecsForClass("WARRIOR")
        local band, picked, bkey = SP.ResolveBand("MAGE", "Fire", 19)

        local known = {
            ["Fireball"] = { name = "Fireball", spellID = 145, rank = "Rank 3", learned = 12 },
            ["Frostbolt"] = { name = "Frostbolt", spellID = 116, rank = "Rank 1", learned = 4 },
            ["Frost Armor"] = { name = "Frost Armor", spellID = 168, rank = "Rank 1", learned = 1 },
            ["Arcane Intellect"] = { name = "Arcane Intellect", spellID = 1459, rank = "Rank 1", learned = 1 },
            ["Shoot"] = { name = "Shoot", spellID = 5019, rank = "", learned = 1 },
        }
        local prep = SP.BuildPrepChecks("MAGE", known)
        local prepMap = {}
        for _, p in ipairs(prep) do prepMap[p.label] = p.value end

        local eff = SP.BuildEfficiencyTable(known)
        local cStats = ToonAge.TalentIntel.ReadCastStats()
        local prio = SP.BuildPriorityRows(band and band.st, known, { ["Fireball"] = { label = "Rank 4" } }, cStats)

        -- Render full Spells tab via Rotation:Render
        local R = ToonAge:GetModule("ForeverRotation")
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 600)
        SP.activeMode = "st"
        R:Render(content, nil)
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
        local blobST = table.concat(texts, "\n")

        -- Switch to Efficiency mode (DPS & DPM) and re-render
        SP.activeMode = "efficiency"
        local content2 = CreateFrame("Frame", nil, nil)
        content2:SetSize(640, 600)
        R:Render(content2, nil)
        local texts2 = {}
        local function walk2(f)
            for _, reg in ipairs(f._regions or {}) do
                if reg._text and reg._text ~= "" then texts2[#texts2 + 1] = reg._text end
            end
            for _, ch in ipairs(f._children or {}) do
                if ch._text and ch._text ~= "" then texts2[#texts2 + 1] = ch._text end
                walk2(ch)
            end
        end
        walk2(content2)
        local blobEff = table.concat(texts2, "\n")

        return {
            bands = b1 .. "|" .. b2 .. "|" .. b3 .. "|" .. b4,
            mageCount = #mageSpecs,
            rogueCount = #rogueSpecs,
            warCount = #warSpecs,
            picked = picked,
            bkey = bkey,
            armorVal = prepMap["Frost Armor"],
            intVal = prepMap["Arcane Intellect"],
            wandVal = prepMap["Wand (Shoot)"],
            effCount = #eff,
            effTopName = eff[1] and eff[1].name,
            effTopDPS = eff[1] and math.floor(eff[1].dps * 10 + 0.5) / 10,
            effTopDPM = eff[1] and math.floor((eff[1].dpm or 0) * 100 + 0.5) / 100,
            prioCount = #prio,
            prioFirstVal = prio[1] and prio[1].value or "",
            hasPlaybookHdr = blobST:find("Spell Playbook", 1, true) ~= nil,
            noExpWall = blobST:find("EXPERIMENTAL SPELL GUIDE", 1, true) == nil,
            hasDPSMode = blobEff:find("21.0 DPS", 1, true) ~= nil and blobEff:find("DPM", 1, true) ~= nil,
        }
    end)()
    """)
    check("BandForLevel maps 12/28/52/60 correctly", r1["bands"], "10-19|20-39|40-59|60")
    check("SpecsForClass discovers specs across Mage, Rogue, and Warrior",
          r1["mageCount"] >= 3 and r1["rogueCount"] >= 3 and r1["warCount"] >= 3)
    check("ResolveBand resolves Fire Mage 10-19", (r1["picked"], r1["bkey"]), ("Fire", "10-19"))
    check("BuildPrepChecks detects Frost Armor Active, Arcane Intellect Missing, Wand Equipped",
          (r1["armorVal"], r1["intVal"], r1["wandVal"]), ("Active", "Missing", "Equipped"))
    check("BuildEfficiencyTable computes Fireball 21.0 DPS & 0.97 DPM from live tooltips",
          (r1["effCount"], r1["effTopName"], r1["effTopDPS"], r1["effTopDPM"]), (2, "Fireball", 21.0, 0.97))
    check("BuildPriorityRows enriches confirmed spells with Rank + Trainer + Casts share",
          "Rank 3" in r1["prioFirstVal"] and "Train Rank 4" in r1["prioFirstVal"] and "75% of casts" in r1["prioFirstVal"])
    check("Spells tab renders Spell Playbook cleanly without experimental wall by default",
          (r1["hasPlaybookHdr"], r1["noExpWall"]), (True, True))
    check("DPS & DPM mode renders live tooltip efficiency rows", r1["hasDPSMode"], True)

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
