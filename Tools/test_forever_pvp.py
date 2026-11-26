#!/usr/bin/env python3
"""Tests for Phase 6 Forever PvP Tab v2 (Modules/Forever/PvP.lua + Now.lua).

Verifies:
1. ReadContext: In PvP Match, Free-For-All, Flagged + countdown timer, Contested, Safe.
2. BracketInfo: Under 10, 10-19 Top of bracket (WSG), 20-29 (WSG+AB), 30-39 (Darkspear Islands 15v15), 60 (all 4).
3. ReadReadiness: Equipped vs in-bag PvP trinket, bandages/potions/action pots/engineering/marks, Talents plan slot.
4. GetAlert + Now:BuildItems: Priority 1 alert when flagged/in-match/trinket-in-bag; nil when safe.
5. Utility racials (Shadowmeld, Walk on Air, Skysight, Cannibalize) + live spellbook-aware CC clashes
   (Mage Frost Nova / Frostbolt vs Gnome Escape Artist) + Enemy Target Dossier render.

Usage:  python3 Tools/test_forever_pvp.py [-v]
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
ToonAge = { modules = {}, Data = {}, flavor = "forever", IsForever = true, version = "test", charDB = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
ToonAge._ApplyBackdrop = function() end
ToonAge.Utils = {
    IsSecret = function() return false end,
    StripMarkup = function(s) return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end,
}

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
issecretvalue = function() return false end
time = function() return 10000 end

_ctx = { inInst = false, instType = "none", zoneType = "friendly", zoneName = "Orgrimmar", flagged = false, ffa = false, timer = 301000 }
IsInInstance = function() return _ctx.inInst, _ctx.instType end
GetZonePVPInfo = function() return _ctx.zoneType end
GetRealZoneText = function() return _ctx.zoneName end
UnitIsPVP = function() return _ctx.flagged end
UnitIsPVPFreeForAll = function() return _ctx.ffa end
GetPVPTimer = function() return _ctx.timer end

UnitLevel = function(u) return u == "target" and 20 or 19 end
UnitRace = function(u)
    if u == "target" then return "Gnome", "Gnome" end
    return "Undead", "Scourge"
end
UnitFactionGroup = function(u)
    if u == "target" then return "Alliance", "Alliance" end
    return "Horde", "Horde"
end
UnitClass = function(u)
    if u == "target" then return "Priest", "PRIEST" end
    return "Mage", "MAGE"
end
UnitExists = function(u) return u == "target" end
UnitIsPlayer = function(u) return u == "target" end
UnitIsEnemy = function(_, u) return u == "target" end

_equip = {}
GetInventoryItemLink = function(_, slot) return _equip[slot] end

_bags = {
    { link = "|cff0070dd|Hitem:18845|h[Insignia of the Horde]|h|r", count = 1 },
    { link = "|cffffffff|Hitem:3531|h[Thick Wool Bandage]|h|r", count = 12 },
    { link = "|cffffffff|Hitem:1710|h[Greater Healing Potion]|h|r", count = 4 },
    { link = "|cffffffff|Hitem:5634|h[Free Action Potion]|h|r", count = 2 },
    { link = "|cffffffff|Hitem:4390|h[Iron Grenade]|h|r", count = 5 },
    { link = "|cffffffff|Hitem:20558|h[Warsong Gulch Mark of Honor]|h|r", count = 3 },
}
C_Container = {
    GetContainerNumSlots = function(b) return b == 0 and #_bags or 0 end,
    GetContainerItemLink = function(b, s) return b == 0 and _bags[s] and _bags[s].link or nil end,
    GetContainerItemInfo = function(b, s) return b == 0 and _bags[s] and { stackCount = _bags[s].count } or nil end,
}

Enum = { SpellBookSpellBank = { Player = 0 } }
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { name = "Frost", itemIndexOffset = 0, numSpellBookItems = 2 } end,
    GetSpellBookItemInfo = function(i)
        if i == 1 then return { name = "Frost Nova" } end
        return { name = "Frostbolt" }
    end,
}

GetPVPSessionStats = function() return 44, 0 end
GetPVPLifetimeStats = function() return 44, 0, 0 end

C_MajorFactions = {
    GetMajorFactionData = function(fid)
        if fid == 2800 then
            return { renownLevel = 0, renownReputationEarned = 100, renownLevelThreshold = 750 }
        end
        return nil
    end,
}

C_CurrencyInfo = {
    GetCurrencyListSize = function() return 2 end,
    GetCurrencyListInfo = function(i)
        if i == 1 then return { isHeader = true, name = "Player vs. Player" } end
        return { isHeader = false, name = "Honor", quantity = 1250, maxQuantity = 25000 }
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
    function f:RegisterEvent() end
    function f:UnregisterAllEvents() end
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
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Data/Forever/Racials.lua"))
    lua.execute(read("Modules/Forever/TalentIntel.lua"))
    lua.execute(read("Modules/Forever/PvP.lua"))
    lua.execute(read("Modules/Forever/Now.lua"))

    r = lua.eval(r"""
    (function()
        local P = ToonAge:GetModule("ForeverPvP")
        local Now = ToonAge:GetModule("ForeverNow")

        -- 1. Context checks across all 5 states
        local cSafe = P.ReadContext()
        local alertSafe = P.GetAlert()

        _ctx.zoneType = "contested"; _ctx.zoneName = "Hillsbrad Foothills"
        local cCont = P.ReadContext()

        _ctx.flagged = true; _ctx.timer = 222000 -- 3:42 left
        local cFlag = P.ReadContext()
        local alertFlag = P.GetAlert()

        _ctx.ffa = true; _ctx.zoneName = "Gurubashi Arena"
        local cFFA = P.ReadContext()

        _ctx.inInst = true; _ctx.instType = "pvp"; _ctx.zoneName = "Warsong Gulch"; _ctx.ffa = false
        local cMatch = P.ReadContext()

        -- 2. Bracket checks
        local b8 = P.BracketInfo(8)
        local b19 = P.BracketInfo(19)
        local b22 = P.BracketInfo(22)
        local b35 = P.BracketInfo(35)
        local b60 = P.BracketInfo(60)

        -- 3. Readiness checks (trinket in bag vs equipped)
        ToonAge.TalentIntel.SelectSlot("PvP")
        local rdBag = P.ReadReadiness()
        _equip[13] = "|cff0070dd|Hitem:18845|h[Insignia of the Horde]|h|r"
        local rdEq = P.ReadReadiness()

        -- 4. Now tab picks up PvP Priority 1 alert
        _equip[13] = nil
        local nowItems = Now:BuildItems()
        local pvpCard = nil
        for _, it in ipairs(nowItems) do
            if it.category == "PvP" then pvpCard = it end
        end

        -- 5. Full render (Target Dossier + Spellbook Clashes + Utility Racials + Forever Standing & Honor)
        P._sessionStart = (time and time() or 10000) - 3600
        local fRank = P.ReadForeverRank("Horde")
        local hCur = P.ReadHonorCurrency()
        local content = CreateFrame("Frame", nil, nil)
        content:SetSize(640, 800)
        P:Render(content, nil)
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
            safeMode = cSafe.mode, safeAlertNil = (alertSafe == nil),
            contMode = cCont.mode,
            flagBadge = cFlag.badge,
            flagAlertPrio = alertFlag and alertFlag.priority,
            flagAlertTrinket = alertFlag and alertFlag.value,
            ffaMode = cFFA.mode,
            matchMode = cMatch.mode, matchDetail = cMatch.detail,
            b8Open = b8.open,
            b19 = b19.bracket .. "|" .. b19.position .. "|" .. b19.summary,
            b22 = b22.bracket .. "|" .. b22.position .. "|" .. b22.summary,
            b35HasDarkspear = b35.summary:find("Darkspear Islands", 1, true) ~= nil,
            b60Count = #b60.bgs,
            rdBagState = rdBag.trinketState,
            rdEqState = rdEq.trinketState,
            rdBand = rdBag.bags.bandages,
            rdPots = rdBag.bags.potions,
            rdAct = rdBag.bags.actionPots,
            rdEng = rdBag.bags.engineering,
            rdMarks = rdBag.bags.marks,
            rdPlan = rdBag.planSlot,
            nowHasPvP = pvpCard ~= nil,
            nowPrio = pvpCard and pvpCard.priority,
            hasTargetDossier = blob:find("Enemy target dossier", 1, true) ~= nil,
            hasPriestThreat = blob:find("Psychic Scream", 1, true) ~= nil,
            hasSpellbookClash = blob:find("Escape Artist breaks your Frost Nova", 1, true) ~= nil,
            hasShadowmeld = blob:find("Shadowmeld", 1, true) ~= nil,
            hasWalkOnAir = blob:find("Walk on Air", 1, true) ~= nil,
            hasCannibalize = blob:find("Cannibalize", 1, true) ~= nil,
            fRankTitle = fRank and fRank.name or "",
            fRankEarned = fRank and fRank.earned or -1,
            fRankThresh = fRank and fRank.threshold or -1,
            fRankTotalMax = fRank and fRank.totalMax or -1,
            hCurQty = hCur and hCur.quantity or -1,
            hasStandingSec = blob:find("Standing & Honor", 1, true) ~= nil,
            hasRankPtsBar = blob:find("100 / 750", 1, true) ~= nil,
            hasSpendHonor = blob:find("1250 / 25000", 1, true) ~= nil,
            hasSessionPace = blob:find("HK/hr", 1, true) ~= nil,
        }
    end)()
    """)
    check("Safe friendly zone has mode='safe' and no Now alert",
          (r["safeMode"], r["safeAlertNil"]), ("safe", True))
    check("Contested zone detected", r["contMode"], "contested")
    check("Flagged timer formatted as 3:42", r["flagBadge"], "Flagged (drops in 3:42)")
    check("Flagged with trinket in bag triggers Priority 1 Now alert ('Equip trinket')",
          (r["flagAlertPrio"], r["flagAlertTrinket"]), (1, "Equip trinket"))
    check("Free-For-All arena detected", r["ffaMode"], "ffa")
    check("Battleground match detected", (r["matchMode"], "Warsong Gulch" in r["matchDetail"]), ("match", True))
    check("Lv 8 under BG bracket", r["b8Open"], False)
    check("Lv 19 is 10-19 Top of bracket (Warsong Gulch)", r["b19"], "10-19|Top of bracket|Warsong Gulch")
    check("Lv 22 is 20-29 Bottom of bracket (WSG + AB)",
          r["b22"], "20-29|Bottom of bracket|Warsong Gulch · Arathi Basin")
    check("Lv 35 bracket includes Forever's Darkspear Islands (15v15)", r["b35HasDarkspear"], True)
    check("Lv 60 includes all 4 BGs", r["b60Count"], 4)
    check("ReadReadiness distinguishes in-bag vs equipped Insignia",
          (r["rdBagState"], r["rdEqState"]), ("in_bag", "equipped"))
    check("ReadReadiness tallies bandages/potions/actionPots/eng/marks + PvP plan slot",
          (r["rdBand"], r["rdPots"], r["rdAct"], r["rdEng"], r["rdMarks"], r["rdPlan"]),
          (12, 4, 2, 5, 3, "PvP"))
    check("Now.lua surfaces Priority 1 PvP readiness alert", (r["nowHasPvP"], r["nowPrio"]), (True, 1))
    check("Render includes Enemy Target Dossier & Priest class threats",
          (r["hasTargetDossier"], r["hasPriestThreat"]), (True, True))
    check("Render cross-checks Mage Frost Nova against Gnome Escape Artist", r["hasSpellbookClash"], True)
    check("Render includes utility PvP racials (Shadowmeld, Walk on Air, Cannibalize)",
          (r["hasShadowmeld"], r["hasWalkOnAir"], r["hasCannibalize"]), (True, True, True))
    check("ReadForeverRank reads Rank 0 Civilian 100/750 out of 24750 via Major Faction 2800",
          (r["fRankTitle"], r["fRankEarned"], r["fRankThresh"], r["fRankTotalMax"]),
          ("Civilian", 100, 750, 24750))
    check("ReadHonorCurrency reads live spendable Honor (1250) via C_CurrencyInfo",
          r["hCurQty"], 1250)
    check("Render shows Standing & Honor, 100 / 750 Rank Points bar, 1250 / 25000 Honor, and compact HK/hr pace",
          (r["hasStandingSec"], r["hasRankPtsBar"], r["hasSpendHonor"], r["hasSessionPace"]),
          (True, True, True, True))

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
