#!/usr/bin/env python3
"""Tests for Phase 3 Talent Intelligence (Modules/Forever/TalentIntel.lua + Talents.lua + Now.lua).

Verifies:
1. Pillar 1 — Spell-Filter Pills + Level-Unlock Badges:
   - TI.ReadSpellDesc parses C_TooltipInfo.GetSpellByID, skips metadata lines, caches cleanly
   - TI.DiscoverFilters emits All, matching playstyle pills, and dynamically discovered spell pills
   - TI.NodeMatchesFilter matches/excludes accurately; clicking a pill dims non-matching nodes (alpha=0.22)
   - TI.UnlockLevel computes exact Lv 10..60 unlock level; locked nodes show pooled "L24" badge (0 new frames)
2. Pillar 2 — Full Sandbox Plan Mode (+1/-1 + Multi-Milestone Roadmap + Saved Plans -> Now tab):
   - TI.SandboxAdd / TI.SandboxRemove / TI.SandboxTotals enforce max rank and 51-pt cap, 0 spend API calls
   - Shift-Click (+1), Right-Click (-1), and dock +1/-1/Clr buttons work live
   - TI.ToggleMilestone + TI.BuildRoadmap compute multi-milestone roadmaps with unlock levels
   - TI.CycleSlot isolates Solo / Dungeon / PvP plans in TA.charDB.talentPlans (no cross-slot bleed)
   - M.GetNextPlannedPoint feeds Modules/Forever/Now.lua BuildItems() at Priority 1 when unspent > 0
3. Pillar 3 — Live Reality Callouts (Single-Spell Math + Casts + Gear):
   - TI.SpellMath calculates deterministic cast-time, direct-dmg%, crit%, mana-cost%, and honest utility fallback
   - TI.ReadCastStats + TI.CastReality report real ForeverCastLog cast share (high match / 0% / no fights)
   - TI.ReadEquippedStats + TI.GearReality report school dmg, low-level crit note, and Int/Spi stats
4. Zero Frame Churn & Strict WoW API Compliance:
   - Render Talents twice with TalentIntel active, filter active, milestone pinned, sandbox points, dock open:
     0 CreateFrame calls on pass 2, CountDescendants(content) == 0, 0 C_Traits spend calls, strict Button OnClick.

Usage:  python3 Tools/test_forever_talent_intel.py [-v]
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
    charDB = {
        castLog = {
            fights = {
                {
                    casts = {
                        { 0.0, 116 },
                        { 2.5, 116 },
                        { 5.0, 116 },
                        { 7.5, 116 },
                        { 10.0, 133 },
                        { 12.5, 122 },
                    },
                },
            },
        },
    },
    db = {},
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
ToonAge.Utils = {
    IsSecret = function(v) return type(v) == "table" and v._secret == true end,
    StripMarkup = function(s) return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end,
    Glyph = function() return "-" end,
    GetPlayerName = function() return "Examplechar" end,
    GetPlayerLevel = function() return 19 end,
    GetPlayerClassLocalized = function() return "Mage" end,
    GetPlayerClass = function() return "MAGE" end,
    GetPlayerRace = function() return "Human", "Human" end,
}
ToonAge._ApplyBackdrop = function() end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = "ChatFontNormal"
UIParent = nil

Enum = {
    TraitNodeEntryType = { SpendSquare = 1, SpendCapstoneSquare = 14 },
    TraitEdgeType = { VisualOnly = 0, SufficientForAvailability = 2, RequiredForAvailability = 3 },
    SpellBookSpellBank = { Player = 0 },
}

issecretvalue = function(v) return type(v) == "table" and v._secret == true end
_shiftDown = false
IsShiftKeyDown = function() return _shiftDown end

spendCalls = 0
createdFrames = 0
tooltipQueries = 0

local function Widget(kind, name)
    local f = {
        kind = kind, name = name, _children = {}, _regions = {},
        _shown = true, scripts = {}, _text = "", _fontSize = 10,
        _points = {}, _tint = nil, _alpha = 1, _desat = false,
        _registeredClicks = nil,
    }
    local mt = {
        __index = function(_, key)
            if type(key) ~= "string" then return nil end
            if key == "GetChildren" then
                return function(self) return unpack(self._children) end
            end
            local head = key:sub(1, 3)
            if head == "Set" or head == "Get" or head == "Ena" or head == "Is"
                or key == "Hide" or key == "Show" or key == "ClearAllPoints" then
                return function() end
            end
            return nil
        end,
    }
    setmetatable(f, mt)
    function f:RegisterForClicks(a, b) self._registeredClicks = { a, b } end
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
            local seen = false
            for i = 1, #parent._children do
                if parent._children[i] == self then seen = true end
            end
            if not seen then parent._children[#parent._children + 1] = self end
        end
    end
    function f:GetParent() return self._parent end
    function f:ClearAllPoints() self._points = {} end
    function f:SetPoint(a, b, c, d, e)
        self._points[#self._points + 1] = { a = a, b = b, c = c, d = d, e = e }
    end
    function f:SetAllPoints(rel)
        self:ClearAllPoints()
        self:SetPoint("ALL", rel or self._parent)
    end
    function f:SetSize(w, h) self.w, self.h = w, h end
    function f:SetWidth(w) self.w = w end
    function f:SetHeight(h) self.h = h end
    function f:GetWidth() return self.w or 0 end
    function f:GetHeight() return self.h or 0 end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetAlpha(a) self._alpha = a end
    function f:GetAlpha() return self._alpha end
    function f:SetDesaturated(d) self._desat = d and true or false end
    function f:SetScript(ev, fn)
        if ev == "OnClick" and self.kind ~= "Button" then
            error("Frame:SetScript(): Cannot assign script handler for 'onclick' (script type not supported by this object)")
        end
        self.scripts[ev] = fn
    end
    function f:GetScript(ev) return self.scripts[ev] end
    function f:SetFrameLevel(n) self.level = n end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:SetVertexColor(r, g, b, a) self._tint = { r, g, b, a } end
    function f:SetColorTexture(r, g, b, a) self._colorTex = { r, g, b, a } end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:GetStringWidth() return string.len(self._text or "") * 5 end
    function f:GetStringHeight() return 12 end
    function f:CreateTexture()
        local tex = Widget("Texture")
        tex._parent = self
        self._regions[#self._regions + 1] = tex
        return tex
    end
    function f:CreateFontString()
        local fs = Widget("FontString")
        fs._parent = self
        self._regions[#self._regions + 1] = fs
        return fs
    end
    function f:CreateLine()
        local line = Widget("Line")
        line._parent = self
        self._lines = self._lines or {}
        self._lines[#self._lines + 1] = line
        return line
    end
    function f:SetScrollChild(ch) self._scrollChild = ch end
    function f:GetScrollChild() return self._scrollChild end
    function f:SetVerticalScroll(v) self._vscroll = v end
    function f:GetVerticalScroll() return self._vscroll or 0 end
    function f:GetVerticalScrollRange() return 200 end
    return f
end

function CreateFrame(kind, name, parent)
    createdFrames = createdFrames + 1
    local f = Widget(kind, name)
    if parent then f:SetParent(parent) end
    if name then _G[name] = f end
    return f
end

function CountDescendants(frame)
    local n = 0
    for _, ch in ipairs({ frame:GetChildren() }) do
        if not ch._laKind then
            n = n + 1 + CountDescendants(ch)
        end
    end
    return n
end

_playerLevel = 19
UnitLevel = function() return _playerLevel end
UnitClass = function() return "Mage", "MAGE" end
GameTooltip = {
    _lines = {},
    SetOwner = function(self) self._lines = {} end,
    SetText = function(self, t) self._lines[#self._lines + 1] = t end,
    AddLine = function(self, t) self._lines[#self._lines + 1] = t end,
    Show = function() end,
    Hide = function() end,
}

-- Spell tooltips + spell info + spellbook stubs
local SPELL_TOOLTIPS = {
    [116]  = { "Frostbolt", "Rank 3", "50 Mana", "30 yd range", "2.5 sec cast", "Launches a bolt of frost at the enemy, causing 51 to 58 Frost damage and slowing movement speed." },
    [133]  = { "Fireball", "Rank 3", "65 Mana", "35 yd range", "3.0 sec cast", "Hurls a fiery ball that causes 53 to 73 Fire damage." },
    [122]  = { "Frost Nova", "Rank 1", "55 Mana", "Instant", "Blasts enemies near the caster for 19 to 21 Frost damage and freezes them in place." },
    [11070] = { "Improved Frostbolt", "Rank 1/5", "Reduces the casting time of your Frostbolt spell by 0.5 sec." },
    [11100] = { "Ice Shards", "Rank 1/5", "Increases the critical strike damage bonus of your Frost spells by 20%." },
    [11180] = { "Frostbite", "Rank 1/3", "Gives your Chill effects a 15% chance to freeze the target for 5 sec." },
    [11170] = { "Shatter", "Rank 1/5", "Increases the critical strike chance of all your spells against frozen targets by 10%." },
    [11129] = { "Improved Fireball", "Rank 1/5", "Reduces the casting time of your Fireball spell by 0.5 sec." },
    [11151] = { "Piercing Ice", "Rank 1/3", "Increases the damage done by your Frost spells by 6%." },
    [11185] = { "Frost Channeling", "Rank 1/3", "Reduces the mana cost of your Frost spells by 15%." },
    [11958] = { "Ice Barrier", "Rank 1/1", "Instantly shields you, absorbing 438 damage. Lasts 1 min." },
}

local SPELL_INFO = {
    ["Frostbolt"] = { spellID = 116, name = "Frostbolt", castTime = 2500 },
    ["Fireball"]  = { spellID = 133, name = "Fireball",  castTime = 3000 },
}

local SPELL_NAMES = {
    [116]   = "Frostbolt",
    [133]   = "Fireball",
    [122]   = "Frost Nova",
    [11070] = "Improved Frostbolt",
    [11100] = "Ice Shards",
    [11180] = "Frostbite",
    [11170] = "Shatter",
    [11129] = "Improved Fireball",
    [11151] = "Piercing Ice",
    [11185] = "Frost Channeling",
    [11958] = "Ice Barrier",
}

C_TooltipInfo = {
    GetSpellByID = function(sid)
        tooltipQueries = tooltipQueries + 1
        local raw = SPELL_TOOLTIPS[sid]
        if not raw then return nil end
        local lines = {}
        for i, txt in ipairs(raw) do lines[i] = { leftText = txt } end
        return { lines = lines }
    end,
}

C_Spell = {
    GetSpellName = function(sid) return SPELL_NAMES[sid] end,
    GetSpellTexture = function(sid) return 100000 + (tonumber(sid) or 0) end,
    GetSpellInfo = function(q)
        if type(q) == "string" then return SPELL_INFO[q] end
        return nil
    end,
    GetSpellPowerCost = function(sid)
        if sid == 116 then return { { cost = 50 } } end
        if sid == 133 then return { { cost = 65 } } end
        return {}
    end,
}

C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 2 end,
    GetSpellBookSkillLineInfo = function(line)
        if line == 1 then return { name = "General", itemIndexOffset = 0, numSpellBookItems = 1 } end
        return { name = "Frost", itemIndexOffset = 1, numSpellBookItems = 3 }
    end,
    GetSpellBookItemInfo = function(idx)
        local map = { [1] = "Attack", [2] = "Frostbolt", [3] = "Fireball", [4] = "Frost Nova" }
        return { name = map[idx] }
    end,
}

-- Equipped gear stub: +24 Frost dmg, +6 Spell Power, +12 Int, +8 Spi, +0 Crit
local EQUIP_LINKS = {
    [1] = "item:1001",
    [16] = "item:1002",
}
local EQUIP_STATS = {
    ["item:1001"] = { ITEM_MOD_FROST_DAMAGE_DONE_SHORT = 24, ITEM_MOD_INTELLECT_SHORT = 7 },
    ["item:1002"] = { ITEM_MOD_SPELL_POWER_SHORT = 6, ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_SPIRIT_SHORT = 8 },
}
GetInventoryItemLink = function(unit, slot)
    if unit ~= "player" then return nil end
    return EQUIP_LINKS[slot]
end
C_Item = {
    GetItemStats = function(link) return EQUIP_STATS[link] end,
}

-- Live C_ClassTalents + C_Traits stub (Frost/Fire mini-tree, 10 spent, 0 unspent at Lv 19)
_unspentPts = 0
local LIVE_TREE_NODES = {
    [101] = { ID = 101, posX = 0, posY = 0, activeRank = 5, maxRanks = 5, entryIDs = { 101 }, conditionIDs = {}, visibleEdges = { { targetNode = 102, type = 3 } } },
    [102] = { ID = 102, posX = 0, posY = 100, activeRank = 3, maxRanks = 3, entryIDs = { 102 }, conditionIDs = { 1 }, visibleEdges = { { targetNode = 103, type = 3 } } },
    [103] = { ID = 103, posX = 0, posY = 200, activeRank = 2, maxRanks = 3, entryIDs = { 103 }, conditionIDs = { 2 }, visibleEdges = { { targetNode = 104, type = 3 } } },
    [104] = { ID = 104, posX = 0, posY = 300, activeRank = 0, maxRanks = 5, entryIDs = { 104 }, conditionIDs = { 3 }, visibleEdges = { { targetNode = 105, type = 3 } } },
    [105] = { ID = 105, posX = 0, posY = 400, activeRank = 0, maxRanks = 1, entryIDs = { 105 }, conditionIDs = { 4 }, visibleEdges = {} },
    [106] = { ID = 106, posX = 100, posY = 0, activeRank = 0, maxRanks = 5, entryIDs = { 106 }, conditionIDs = {}, visibleEdges = {} },
    [107] = { ID = 107, posX = 100, posY = 200, activeRank = 0, maxRanks = 3, entryIDs = { 107 }, conditionIDs = { 3 }, visibleEdges = {} },
}
local ENTRY_SPELLS = {
    [101] = 11070, -- Improved Frostbolt
    [102] = 11180, -- Frostbite
    [103] = 11151, -- Piercing Ice
    [104] = 11170, -- Shatter (gate 15)
    [105] = 11958, -- Ice Barrier (gate 20)
    [106] = 11129, -- Improved Fireball
    [107] = 11185, -- Frost Channeling (gate 15)
}
local LIVE_CONDS = {
    [1] = { condID = 1, isMet = true, spentAmountRequired = 5 },
    [2] = { condID = 2, isMet = true, spentAmountRequired = 10 },
    [3] = { condID = 3, isMet = false, spentAmountRequired = 15 },
    [4] = { condID = 4, isMet = false, spentAmountRequired = 20 },
}

C_ClassTalents = {
    GetActiveConfigID = function() return 77 end,
}
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1 } } end,
    GetTreeNodes = function() return { 101, 102, 103, 104, 105, 106, 107 } end,
    GetNodeInfo = function(_, nid) return LIVE_TREE_NODES[nid] end,
    GetEntryInfo = function(_, eid) return { definitionID = eid, type = 1 } end,
    GetDefinitionInfo = function(did) return { spellID = ENTRY_SPELLS[did] } end,
    GetConditionInfo = function(_, cid) return LIVE_CONDS[cid] end,
    GetTreeCurrencyInfo = function() return { { quantity = _unspentPts } } end,
    PurchaseRank = function() spendCalls = spendCalls + 1 end,
    SetSelection = function() spendCalls = spendCalls + 1 end,
    CommitConfig = function() spendCalls = spendCalls + 1 end,
}
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Forever/TalentIntel.lua"))
    lua.execute(read("Modules/Forever/Talents.lua"))
    lua.execute(read("Modules/Forever/Now.lua"))

    # ── PILLAR 1: Spell-Filter Pills + Level-Unlock Badges ────────────────────
    r1 = lua.eval(r"""
    (function()
        local TI = ToonAge.TalentIntel
        local M  = ToonAge:GetModule("ForeverTalents")
        TI.ClearCache()
        tooltipQueries = 0

        local d1, lines1 = TI.ReadSpellDesc(11070)
        local qAfter1 = tooltipQueries
        local d1Cached = TI.ReadSpellDesc(11070)
        local qAfter2 = tooltipQueries

        -- Metadata skipped on full spell tooltip
        local dBolt = TI.ReadSpellDesc(116)

        local nodes, conds, _, spent, unspent = M.ReadGrid()
        local pills = TI.DiscoverFilters(nodes)
        local keys, labels = {}, {}
        for i, p in ipairs(pills) do
            keys[p.key] = true
            labels[i] = p.label
        end

        -- NodeMatchesFilter checks
        local frostNode = { name = "Improved Frostbolt" }
        local fireNode  = { name = "Improved Fireball" }
        local chanNode  = { name = "Frost Channeling" }
        local matchFrostBolt = TI.NodeMatchesFilter(frostNode, d1, "spell:frostbolt")
        local matchFireFrost = TI.NodeMatchesFilter(fireNode, TI.ReadSpellDesc(11129), "spell:frostbolt")
        local matchMana      = TI.NodeMatchesFilter(chanNode, TI.ReadSpellDesc(11185), "mana")
        local matchCtrl      = TI.NodeMatchesFilter({ name = "Frostbite" }, TI.ReadSpellDesc(11180), "control")

        -- Exact level-unlock math: Lv 19, 10 spent, 0 unspent -> gate 15 needs 5 more -> Lv 24
        local byID = {}
        for _, n in ipairs(nodes) do byID[n.id] = n end
        local ulv104, away104 = TI.UnlockLevel(byID[104], conds, 10, 0, 19, nil, function(node, cs)
            for _, cid in ipairs(node.conditionIDs or {}) do
                local c = cs[cid]
                if c and c.isMet == false then return true, c.spentRequired end
            end
            return false, nil
        end)
        local ulv105, away105 = TI.UnlockLevel(byID[105], conds, 10, 2, 19, nil, function(node, cs)
            for _, cid in ipairs(node.conditionIDs or {}) do
                local c = cs[cid]
                if c and c.isMet == false then return true, c.spentRequired end
            end
            return false, nil
        end)
        local ulv101 = TI.UnlockLevel(byID[101], conds, 10, 0, 19, nil, function() return false, nil end)

        return {
            d1 = d1,
            linesCount = #lines1,
            qAfter1 = qAfter1,
            qAfter2 = qAfter2,
            d1Cached = d1Cached,
            dBoltHasRank = dBolt:find("Rank 3", 1, true) ~= nil,
            dBoltHasDmg  = dBolt:find("51 to 58 Frost damage", 1, true) ~= nil,
            hasAll       = keys["all"] == true,
            hasDamage    = keys["damage"] == true,
            hasMana      = keys["mana"] == true,
            hasControl   = keys["control"] == true,
            hasFrostPill = keys["spell:frostbolt"] == true or keys["spell:frost"] == true or #pills >= 5,
            matchFrostBolt = matchFrostBolt,
            matchFireFrost = matchFireFrost,
            matchMana = matchMana,
            matchCtrl = matchCtrl,
            ulv104 = ulv104,
            away104 = away104,
            ulv105 = ulv105,
            away105 = away105,
            ulv101 = ulv101,
        }
    end)()
    """)
    check("ReadSpellDesc parses talent tooltip", "Frostbolt" in r1["d1"] and "0.5 sec" in r1["d1"])
    check("ReadSpellDesc caches per spellID (no repeat tooltip query)", (r1["qAfter1"], r1["qAfter2"]), (1, 1))
    check("ReadSpellDesc returns cached string identically", r1["d1Cached"], r1["d1"])
    check("ReadSpellDesc skips Rank/Mana metadata lines", r1["dBoltHasRank"], False)
    check("ReadSpellDesc preserves spell body damage text", r1["dBoltHasDmg"], True)
    check("DiscoverFilters includes All + Damage + Mana + Control",
          r1["hasAll"] and r1["hasDamage"] and r1["hasMana"] and r1["hasControl"])
    check("NodeMatchesFilter matches Frostbolt spell pill", r1["matchFrostBolt"], True)
    check("NodeMatchesFilter excludes Fireball under Frostbolt pill", r1["matchFireFrost"], False)
    check("NodeMatchesFilter matches Mana/Res pill", r1["matchMana"], True)
    check("NodeMatchesFilter matches Control/Surv pill", r1["matchCtrl"], True)
    check("UnlockLevel: Lv 19 + 10 spent + 0 unspent + 15-pt gate -> Lv 24 (5 away)",
          (r1["ulv104"], r1["away104"]), (24, 5))
    check("UnlockLevel: Lv 19 + 10 spent + 2 unspent + 20-pt gate -> Lv 27 (8 away)",
          (r1["ulv105"], r1["away105"]), (27, 8))
    check("UnlockLevel: unlocked node returns nil", r1["ulv101"], None)

    # ── PILLAR 2: Sandbox Plan Mode + Multi-Milestone Roadmap + Saved Plans -> Now ──
    r2 = lua.eval(r"""
    (function()
        local TI = ToonAge.TalentIntel
        local M  = ToonAge:GetModule("ForeverTalents")
        local Now = ToonAge:GetModule("ForeverNow")
        local nodes, conds, _, spent, unspent = M.ReadGrid()

        -- Default slot is Solo
        local _, s0 = TI.ActiveSlot()
        local byID = {}
        for _, n in ipairs(nodes) do byID[n.id] = n end

        -- Pin 2 milestones in Solo: Shatter (104) and Ice Barrier (105)
        local p1 = TI.ToggleMilestone(104)
        local p2 = TI.ToggleMilestone(105)
        local rm = TI.BuildRoadmap(nodes, conds, { 104, 105 }, 10, 0, 19, M.PlanRoute)

        -- Sandbox +1/-1 on Piercing Ice (103, currently 2/3)
        local okAdd1 = TI.SandboxAdd(byID[103], nodes, 10)
        local okAdd2, errMax = TI.SandboxAdd(byID[103], nodes, 10) -- should refuse: already 3/3
        local delta103 = TI.SandboxDelta(103)
        local sbTot = TI.SandboxTotals(nodes, 10, 19)

        -- Cycle to Dungeon slot: verify isolated empty milestones & sandbox
        local _, s1 = TI.CycleSlot()
        local dunMilestones = #(TI.ActiveSlot().targets)
        local dunDelta103 = TI.SandboxDelta(103)

        -- Cycle to PvP and back to Solo: Solo state persists in TA.charDB.talentPlans
        local _, s2 = TI.CycleSlot()
        local _, s3 = TI.CycleSlot()
        local soloMilestones = #(TI.ActiveSlot().targets)
        local soloDelta103 = TI.SandboxDelta(103)

        -- Remove -1 in Sandbox
        local okRem = TI.SandboxRemove(103)
        local deltaAfterRem = TI.SandboxDelta(103)

        -- Verify Now.lua BuildItems picks up active plan at Priority 1 when unspent > 0
        _unspentPts = 1
        local nextInfo = M.GetNextPlannedPoint()
        local nowItems = Now:BuildItems()
        local talentCard = nil
        for _, it in ipairs(nowItems) do
            if it.category == "Talents" then talentCard = it end
        end
        _unspentPts = 0

        -- Enforce 51-point cap
        local capOk, capErr = TI.SandboxAdd(byID[104], nodes, 51)

        return {
            s0 = s0, s1 = s1, s2 = s2, s3 = s3,
            p1 = p1, p2 = p2,
            rmValid = rm.valid,
            rmMilestoneCount = #rm.milestones,
            rmFirstName = rm.milestones[1] and rm.milestones[1].name,
            rmSecondName = rm.milestones[2] and rm.milestones[2].name,
            rmUnlock1 = rm.milestones[1] and rm.milestones[1].unlockLevel,
            rmUnlock2 = rm.milestones[2] and rm.milestones[2].unlockLevel,
            rmInPath104 = rm.inPath[104] ~= nil,
            rmInPath105 = rm.inPath[105] ~= nil,
            okAdd1 = okAdd1,
            okAdd2 = okAdd2,
            errMax = errMax,
            delta103 = delta103,
            sbAdded = sbTot.added,
            sbTotal = sbTot.totalSpent,
            dunMilestones = dunMilestones,
            dunDelta103 = dunDelta103,
            soloMilestones = soloMilestones,
            soloDelta103 = soloDelta103,
            okRem = okRem,
            deltaAfterRem = deltaAfterRem,
            capOk = capOk,
            capErr = capErr,
            nextHasPlan = nextInfo.hasPlan,
            nextSlot = nextInfo.slotName,
            nextSummary = nextInfo.summary,
            nowFound = talentCard ~= nil,
            nowPrio = talentCard and talentCard.priority,
            nowVal = talentCard and talentCard.value,
            nowTitle = talentCard and talentCard.title,
            nowDetail = talentCard and talentCard.detail,
            persistedInCharDB = ToonAge.charDB.talentPlans ~= nil
                and ToonAge.charDB.talentPlans.activeSlot == "Solo",
            spendCalls = spendCalls,
        }
    end)()
    """)
    check("Saved Plan slots cycle Solo -> Dungeon -> PvP -> Solo",
          (r2["s0"], r2["s1"], r2["s2"], r2["s3"]), ("Solo", "Dungeon", "PvP", "Solo"))
    check("Saved Plans persisted in TA.charDB.talentPlans", r2["persistedInCharDB"], True)
    check("Multi-Milestone Roadmap valid with 2 milestones (Shatter + Ice Barrier)",
          (r2["rmValid"], r2["rmMilestoneCount"], r2["rmFirstName"], r2["rmSecondName"]),
          (True, 2, "Shatter", "Ice Barrier"))
    check("Multi-Milestone Roadmap marks both targets inPath", r2["rmInPath104"] and r2["rmInPath105"])
    check("Multi-Milestone unlock levels advance monotonically",
          r2["rmUnlock1"] is not None and r2["rmUnlock2"] is not None and r2["rmUnlock2"] > r2["rmUnlock1"])
    check("SandboxAdd adds +1 up to max rank", (r2["okAdd1"], r2["delta103"]), (True, 1))
    check("SandboxAdd refuses exceeding max rank", (r2["okAdd2"], r2["errMax"]), (False, "already at max rank"))
    check("SandboxAdd enforces 51-point Lv 60 cap", (r2["capOk"], "51-point cap" in str(r2["capErr"])), (False, True))
    check("SandboxTotals reports added + totalSpent accurately", (r2["sbAdded"], r2["sbTotal"]), (1, 11))
    check("Dungeon slot isolated from Solo milestones & sandbox",
          (r2["dunMilestones"], r2["dunDelta103"]), (0, 0))
    check("Solo slot keeps milestones & sandbox after cycling back",
          (r2["soloMilestones"], r2["soloDelta103"]), (2, 1))
    check("SandboxRemove decrements cleanly", (r2["okRem"], r2["deltaAfterRem"]), (True, 0))
    check("Now.lua surfaces active Saved Plan at Priority 1 on level-up (1 unspent)",
          (r2["nowFound"], r2["nowPrio"], r2["nowVal"]), (True, 1, "1 to spend"))
    check("Now.lua detail includes [Solo] slot tag and next node",
          "[Solo]" in r2["nowDetail"] and "1 unspent" in r2["nowDetail"])
    check("Zero C_Traits spend calls across all Sandbox/Roadmap operations", r2["spendCalls"], 0)

    # ── PILLAR 3: Single-Spell Tooltip Math + Casts Reality + Gear Reality ────
    r3 = lua.eval(r"""
    (function()
        local TI = ToonAge.TalentIntel

        -- 1. Cast-time reduction math: Frostbolt 2.50s -> 2.00s (+25.0% cast throughput)
        local mCast = TI.SpellMath({ name = "Improved Frostbolt" }, TI.ReadSpellDesc(11070))
        -- 2. Direct damage % math
        local mDmg = TI.SpellMath({ name = "Improved Fireball" }, "Increases the damage done by your Fireball by 10%.")
        -- 3. Crit % math
        local mCrit = TI.SpellMath({ name = "Shatter" }, TI.ReadSpellDesc(11170))
        -- 4. Mana cost % math
        local mMana = TI.SpellMath({ name = "Frost Channeling" }, TI.ReadSpellDesc(11185))
        -- 5. Utility / proc honest fallback
        local mUtil = TI.SpellMath({ name = "Ice Barrier" }, TI.ReadSpellDesc(11958))

        -- Casts Reality from TA.charDB.castLog.fights (4 Frostbolt, 1 Fireball, 1 Frost Nova = 6 casts -> 67% Frostbolt)
        local cStats = TI.ReadCastStats()
        local cFrost = TI.CastReality({ name = "Improved Frostbolt" }, TI.ReadSpellDesc(11070), cStats)
        local cUnused = TI.CastReality({ name = "Improved Arcane Missiles" }, "Reduces pushback.", cStats)
        local cEmpty = TI.CastReality({ name = "Improved Frostbolt" }, TI.ReadSpellDesc(11070), { fights = 0, totalCasts = 0, byName = {} })

        -- Gear Reality from equipped items (+24 Frost dmg, +6 Spell Power, +12 Int, +8 Spi, +0 Crit)
        local eq = TI.ReadEquippedStats()
        local gFrost = TI.GearReality({ name = "Piercing Ice" }, TI.ReadSpellDesc(11151), eq, 19)
        local gCritLow = TI.GearReality({ name = "Shatter" }, "Increases critical strike chance by 10%.", eq, 19)
        local gMana = TI.GearReality({ name = "Spirit Focus" }, "Increases mana regeneration while casting.", eq, 19)

        return {
            mCastHas = mCast.hasMath,
            mCastText = mCast.text,
            mCastPct = math.floor((mCast.pctGain or 0) * 10 + 0.5) / 10,
            mDmgHas = mDmg.hasMath,
            mDmgText = mDmg.text,
            mCritHas = mCrit.hasMath,
            mCritText = mCrit.text,
            mManaHas = mMana.hasMath,
            mManaText = mMana.text,
            mUtilHas = mUtil.hasMath,
            mUtilText = mUtil.text,
            cFights = cStats.fights,
            cTotal = cStats.totalCasts,
            cFrost = cFrost,
            cUnused = cUnused,
            cEmpty = cEmpty,
            eqFrost = eq.frost,
            eqSP = eq.spellPower,
            eqInt = eq.intellect,
            gFrost = gFrost,
            gCritLow = gCritLow,
            gMana = gMana,
        }
    end)()
    """)
    check("SpellMath computes Frostbolt 2.50s -> 2.00s (+25.0% cast throughput)",
          (r3["mCastHas"], r3["mCastPct"], "2.50s -> 2.00s" in r3["mCastText"], "single-spell DPS" in r3["mCastText"]),
          (True, 25.0, True, True))
    check("SpellMath computes Fireball +10% avg hit tooltip math",
          (r3["mDmgHas"], "+10% dmg" in r3["mDmgText"], "63 -> 69" in r3["mDmgText"]),
          (True, True, True))
    check("SpellMath computes +10% crit (~+5.0% avg dmg at 1.5x)",
          (r3["mCritHas"], "+10% crit" in r3["mCritText"], "+5.0%" in r3["mCritText"]),
          (True, True, True))
    check("SpellMath computes -15% mana cost", (r3["mManaHas"], "-15% mana cost" in r3["mManaText"]), (True, True))
    check("SpellMath marks utility talent honestly (hasMath=false)",
          (r3["mUtilHas"], "no deterministic" in r3["mUtilText"]), (False, True))
    check("ReadCastStats tallies 1 fight, 6 casts", (r3["cFights"], r3["cTotal"]), (1, 6))
    check("CastReality flags Frostbolt 67% (4/6) as high match",
          "Frostbolt is 67%" in r3["cFrost"] and "high match" in r3["cFrost"])
    check("CastReality flags uncast Improved Arcane Missiles at 0%",
          "Arcane Missiles cast 0%" in r3["cUnused"])
    check("CastReality handles empty cast log gracefully", "no fights logged yet" in r3["cEmpty"])
    check("ReadEquippedStats sums +24 Frost, +6 SP, +12 Int",
          (r3["eqFrost"], r3["eqSP"], r3["eqInt"]), (24, 6, 12))
    check("GearReality shows matching +24 Frost dmg & +6 Spell Power",
          "+24 Frost dmg" in r3["gFrost"] and "+6 Spell Power" in r3["gFrost"])
    check("GearReality shows honest low-level +0 Crit note at Lv 19",
          "+0 Crit gear at Lv 19" in r3["gCritLow"])
    check("GearReality shows +12 Intellect, +8 Spirit for mana/regen talent",
          "+12 Intellect, +8 Spirit" in r3["gMana"])

    # ── PILLAR 4: Live UI Render, Filter Dimming, L24 Badges, Sandbox Clicks, 0 Frame Churn ──
    r4 = lua.eval(r"""
    (function()
        local TI = ToonAge.TalentIntel
        local M  = ToonAge:GetModule("ForeverTalents")
        TI.SelectSlot("Solo")
        TI.ClearMilestones()
        TI.SandboxClear()
        M.selectedID = 104 -- Shatter (locked, gate 15 -> L24)
        M.planTargetID = nil
        M.activeFilter = "all"
        M.sandboxEnabled = false

        local scrollParent = CreateFrame("Frame", "TestViewport", nil)
        scrollParent:SetSize(720, 560)
        local content = CreateFrame("Frame", "TestContent", scrollParent)
        content:SetSize(700, 500)

        -- Pass 1: initial mount
        M:Render(content, nil)
        local framesAfterPass1 = createdFrames
        local filterBarShown = _G.TATalentFilterBar and _G.TATalentFilterBar:IsShown() or false
        local dockShown = _G.TATalentDetailDock and _G.TATalentDetailDock:IsShown() or false
        local dockH = _G.TATalentDetailDock and _G.TATalentDetailDock:GetHeight() or 0
        local dockMath = _G.TATalentDetailDock and _G.TATalentDetailDock.mathLine:GetText() or ""
        local dockCasts = _G.TATalentDetailDock and _G.TATalentDetailDock.castsLine:GetText() or ""
        local dockGear = _G.TATalentDetailDock and _G.TATalentDetailDock.gearLine:GetText() or ""

        -- Find buttons for 104 (Shatter, locked -> L24 badge) and 106 (Improved Fireball)
        local child = _G.TATalentTreeScroll:GetScrollChild()
        local btns = {}
        local function collect(f)
            for _, ch in ipairs({ f:GetChildren() }) do
                if ch.kind == "Button" and ch.id then btns[ch.id] = ch end
                collect(ch)
            end
        end
        collect(child)
        local badge104 = btns[104] and btns[104].badgeText and btns[104].badgeText:GetText() or ""
        local clicksReg = btns[104] and btns[104]._registeredClicks and btns[104]._registeredClicks[2] or ""

        -- Click a filter pill (Mana/Res) and check dimming alpha on Improved Fireball (106) vs Frost Channeling (107)
        local whyHiddenOnAll = not (_G.TATalentFilterBar._whyBar and _G.TATalentFilterBar._whyBar:IsShown())
        local treeYBeforeWhy = _G.TATalentTreeScroll._points[1] and _G.TATalentTreeScroll._points[1].e or 0
        local manaPillBtn = nil
        for _, pb in ipairs(_G.TATalentFilterBar._pills) do
            if pb.label:GetText() == "Mana/Res" then manaPillBtn = pb end
        end
        if manaPillBtn then manaPillBtn.scripts.OnClick(manaPillBtn, "LeftButton") end
        local alphaFireUnderMana = btns[106] and btns[106].icon:GetAlpha() or -1
        local alphaChanUnderMana = btns[107] and btns[107].icon:GetAlpha() or -1
        local whyBar = _G.TATalentFilterBar._whyBar
        local whyShownUnderMana = whyBar and whyBar:IsShown() or false
        local whyDescMana = whyBar and whyBar.desc and whyBar.desc:GetText() or ""
        local whyTitleMana = whyBar and whyBar.title and whyBar.title:GetText() or ""
        local treeYAfterWhy = _G.TATalentTreeScroll._points[1] and _G.TATalentTreeScroll._points[1].e or 0

        -- Channeling pill explanation via TI.FilterInfo
        local chanInfo = TI.FilterInfo("spell:channeling", nil, nil)
        local chanWhy = chanInfo and chanInfo.why or ""

        -- Click Inspect Next -> selects Frost Channeling (107), then +Plan Next -> pins it, then Clear -> resets to All
        if whyBar and whyBar.inspectBtn and whyBar.inspectBtn.scripts.OnClick then
            whyBar.inspectBtn.scripts.OnClick(whyBar.inspectBtn, "LeftButton")
        end
        local selectedAfterInspect = M.selectedID
        if whyBar and whyBar.planBtn and whyBar.planBtn.scripts.OnClick then
            whyBar.planBtn.scripts.OnClick(whyBar.planBtn, "LeftButton")
        end
        local planLabelAfterPlan = whyBar and whyBar.planBtn and whyBar.planBtn.label:GetText() or ""
        if whyBar and whyBar.clearBtn and whyBar.clearBtn.scripts.OnClick then
            whyBar.clearBtn.scripts.OnClick(whyBar.clearBtn, "LeftButton")
        end
        local filterAfterClear = M.activeFilter
        local whyHiddenAfterClear = not (whyBar and whyBar:IsShown())
        -- Restore selectedID = 104 and clean milestones before sandbox tests below
        TI.ClearMilestones()
        M.selectedID = 104
        M.planTargetID = nil
        M:Render(content, nil)

        -- Click dock +1 button to enter Sandbox mode and add +1 to Shatter (104)
        _G.TATalentDetailDock.plusBtn.scripts.OnClick(_G.TATalentDetailDock.plusBtn, "LeftButton")
        local sandboxOnAfterPlus = M.sandboxEnabled
        local badge104AfterPlus = btns[104] and btns[104].badgeText and btns[104].badgeText:GetText() or ""

        -- Shift-Click on node 104 adds another +1 -> 2/5; Right-Click removes -1 -> 1/5
        _shiftDown = true
        btns[104].scripts.OnClick(btns[104], "LeftButton")
        _shiftDown = false
        local badge104AfterShift = btns[104] and btns[104].badgeText and btns[104].badgeText:GetText() or ""
        btns[104].scripts.OnClick(btns[104], "RightButton")
        local badge104AfterRight = btns[104] and btns[104].badgeText and btns[104].badgeText:GetText() or ""

        -- Pin Milestone on 104, then cycle Plan Slot -> verify no cross-slot planTargetID bleed
        _G.TATalentDetailDock.planBtn.scripts.OnClick(_G.TATalentDetailDock.planBtn, "LeftButton")
        local pinLabel = _G.TATalentDetailDock.planBtn.label:GetText()
        _G.TATalentFilterBar.slotBtn.scripts.OnClick(_G.TATalentFilterBar.slotBtn, "LeftButton")
        local slotBtnAfterCycle = _G.TATalentFilterBar.slotBtn.label:GetText()
        local planTargetAfterCycle = M.planTargetID

        -- Pass 2: full re-render must create ZERO new frames and leak ZERO descendants
        local beforePass2 = createdFrames
        M:Render(content, nil)
        local createdOnPass2 = createdFrames - beforePass2
        local leaked = CountDescendants(content)

        return {
            filterBarShown = filterBarShown,
            dockShown = dockShown,
            dockH = dockH,
            dockHasMath = dockMath:find("Math", 1, true) ~= nil,
            dockHasCasts = dockCasts:find("Casts", 1, true) ~= nil,
            dockHasGear = dockGear:find("Gear", 1, true) ~= nil,
            badge104 = badge104,
            clicksReg = clicksReg,
            alphaFireUnderMana = alphaFireUnderMana,
            alphaChanUnderMana = alphaChanUnderMana,
            whyHiddenOnAll = whyHiddenOnAll,
            whyShownUnderMana = whyShownUnderMana,
            whyDescMana = whyDescMana,
            whyTitleMana = whyTitleMana,
            treeShiftedDown = treeYAfterWhy < treeYBeforeWhy,
            chanWhy = chanWhy,
            selectedAfterInspect = selectedAfterInspect,
            planLabelAfterPlan = planLabelAfterPlan,
            filterAfterClear = filterAfterClear,
            whyHiddenAfterClear = whyHiddenAfterClear,
            sandboxOnAfterPlus = sandboxOnAfterPlus,
            badge104AfterPlus = badge104AfterPlus,
            badge104AfterShift = badge104AfterShift,
            badge104AfterRight = badge104AfterRight,
            pinLabel = pinLabel,
            slotBtnAfterCycle = slotBtnAfterCycle,
            planTargetAfterCycle = planTargetAfterCycle,
            framesAfterPass1 = framesAfterPass1,
            createdOnPass2 = createdOnPass2,
            leaked = leaked,
            spendCalls = spendCalls,
        }
    end)()
    """)
    check("TATalentFilterBar shown on render", r4["filterBarShown"], True)
    check("TATalentDetailDock shown with expanded Phase 3 height (132px)",
          (r4["dockShown"], r4["dockH"]), (True, 132))
    check("Detail Dock renders live Math + Casts + Gear callout lines",
          r4["dockHasMath"] and r4["dockHasCasts"] and r4["dockHasGear"])
    check("Locked node 104 displays exact L24 level-unlock badge", r4["badge104"], "L24")
    check("Talent node buttons register RightButtonUp for Sandbox -1", r4["clicksReg"], "RightButtonUp")
    check("Filter pill Mana/Res dims non-matching Fireball (0.22) and keeps Frost Channeling bright (1.0)",
          (abs(r4["alphaFireUnderMana"] - 0.22) < 0.01, r4["alphaChanUnderMana"] > 0.5),
          (True, True))
    check("Filter Why strip hidden on All, shown on Mana/Res with plain-English explanation + tree shift",
          (r4["whyHiddenOnAll"], r4["whyShownUnderMana"], "Clearcasting" in r4["whyDescMana"],
           "Mana/Res" in r4["whyTitleMana"], r4["treeShiftedDown"]),
          (True, True, True, True, True))
    check("TI.FilterInfo explains Channeling pushback & channeled ticks",
          "Arcane Missiles" in r4["chanWhy"] and "pushback" in r4["chanWhy"])
    check("Why strip Inspect Next selects Frost Channeling (107), +Plan Next marks Planned, Clear resets to all",
          (r4["selectedAfterInspect"], r4["planLabelAfterPlan"], r4["filterAfterClear"], r4["whyHiddenAfterClear"]),
          (107, "Planned", "all", True))
    check("Dock +1 enables Sandbox and shows 1/5 badge",
          (r4["sandboxOnAfterPlus"], r4["badge104AfterPlus"]), (True, "1/5"))
    check("Shift-Click adds +1 (2/5) and Right-Click removes -1 (1/5)",
          (r4["badge104AfterShift"], r4["badge104AfterRight"]), ("2/5", "1/5"))
    check("Pin Milestone toggles button label to Unpin Milestone", r4["pinLabel"], "Unpin Milestone")
    check("Cycling Plan Slot switches to Plan: Dungeon and clears cross-slot planTargetID",
          (r4["slotBtnAfterCycle"], r4["planTargetAfterCycle"]), ("Plan: Dungeon", None))
    check("Zero CreateFrame calls on pass 2 (full pool reuse)", r4["createdOnPass2"], 0)
    check("Zero leaked unpooled descendants under content", r4["leaked"], 0)
    check("Zero C_Traits spend calls across all live UI interactions", r4["spendCalls"], 0)

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
