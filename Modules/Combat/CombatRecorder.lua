-- ToonAge/Modules/Combat/CombatRecorder.lua
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS RECORDS, AND WHY IT IS THE ONLY HONEST WAY TO ANSWER ────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Two questions this addon could not answer before:
--
--   "What should I press now?"       -- needs to know what you pressed before,
--                                       in what state, and what came of it.
--   "Which of my buttons are dead?"  -- needs to know what is on your bars and
--                                       which of it you never actually use.
--
-- They are the same question at different timescales, and both need the same
-- record. Nothing in this addon had ever read the combat log, so neither could
-- be answered at all: CombatState knows the present perfectly and has no
-- memory and no outcomes.
--
-- Everything here is measured from your own play. That matters beyond
-- accuracy: authored rotation data goes stale every patch and needs a person
-- to re-verify 37 specs, while a record of what you cast and what it did is
-- true by construction and never needs maintaining. When the two disagree, the
-- log is right and the data file is out of date.
--
-- ── WHAT IT DELIBERATELY DOES NOT DO ──────────────────────────────────────
--
-- It does not keep a raw event log. A busy fight is thousands of combat log
-- lines; stored verbatim they would fill SavedVariables in an evening and make
-- the file slow to write. Everything is AGGREGATED as it arrives -- counts and
-- totals per spell -- so the store grows with the number of abilities you own,
-- not with the time you play.
--
-- It does not decide anything. No weights, no rankings, no "you should".
-- This file only writes down what happened. Judgement belongs above it, and
-- has to earn its numbers from this record first.
--
-- ── COST ──────────────────────────────────────────────────────────────────
--
-- COMBAT_LOG_EVENT_UNFILTERED is the highest-frequency event in the game --
-- every hit by every unit in range. The handler therefore does the cheapest
-- possible thing first: read the payload, compare the source GUID to the
-- player's, and return. Anything that is not yours costs one string compare.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local R = {}
TA:RegisterModule("CombatRecorder", R)

local STORE_VERSION = 1

-- Caps. An ability set is finite, so these are generous ceilings that exist to
-- stop a corrupt or hostile value growing the file without bound, not to
-- ration normal play.
local MAX_SPELLS = 2000
local MAX_BARS   = 200

-- Below this, a fight is a stray mob and its numbers are noise in the average.
local MIN_FIGHT_SECONDS = 5

local playerGUID   -- resolved at login; nil until then, which gates recording

-- ── Guarded client calls ──────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e
end

-- ── Store ─────────────────────────────────────────────────────────────────

local function Store()
    if not TA.charDB then return nil end
    local s = TA.charDB.combatLog
    if not s then
        s = { version = STORE_VERSION }
        TA.charDB.combatLog = s
    end
    -- Backfill rather than reset: a store written by an older version still
    -- holds real fights and must survive a schema bump.
    s.spells  = s.spells  or {}   -- [spellID] = { name, casts, damage, healing, ... }
    s.bars    = s.bars    or {}   -- [spellID] = true, what is on your action bars
    s.known   = s.known   or {}   -- [spellID] = true, what your spellbook has
    s.fights  = s.fights  or 0
    s.seconds = s.seconds or 0
    s.gcds    = s.gcds    or 0
    return s
end

local function SpellRow(s, spellID, spellName)
    local row = s.spells[spellID]
    if not row then
        local n = 0
        for _ in pairs(s.spells) do n = n + 1 end
        if n >= MAX_SPELLS then return nil end
        row = { name = spellName or tostring(spellID), casts = 0,
                damage = 0, healing = 0, firstSeen = time() }
        s.spells[spellID] = row
    end
    -- A name learned later is better than the numeric placeholder written when
    -- the spell was first seen before its data had loaded.
    if spellName and row.name ~= spellName then row.name = spellName end
    return row
end

-- ── The combat log ────────────────────────────────────────────────────────

-- Only these carry information worth aggregating. Everything else returns
-- immediately; the table lookup is cheaper than a chain of comparisons.
local INTERESTING = {
    SPELL_CAST_SUCCESS   = "cast",
    SPELL_DAMAGE         = "damage",
    SPELL_PERIODIC_DAMAGE= "damage",
    SPELL_HEAL           = "healing",
    SPELL_PERIODIC_HEAL  = "healing",
    SWING_DAMAGE         = "swing",
    SPELL_AURA_APPLIED   = "aura",
    SPELL_AURA_REMOVED   = "auragone",
}

function R:OnCombatLog()
    if not playerGUID then return end

    local info = Try(CombatLogGetCurrentEventInfo)
    if not info then return end

    -- Positional, because this is the hot path and building a table per event
    -- would allocate thousands of times a fight.
    local _, subEvent, _, sourceGUID, _, _, _,
          _, _, _, _,
          spellID, spellName, _, amount = CombatLogGetCurrentEventInfo()

    -- The cheap exit: not yours, not our business.
    if sourceGUID ~= playerGUID then return end

    local kind = INTERESTING[subEvent]
    if not kind then return end

    local s = Store()
    if not s then return end

    if kind == "swing" then
        -- Melee autoattack carries no spell id: the 11 base parameters are
        -- followed straight by the amount, which is the same slot the SPELL_*
        -- events use for spellID. So the value already destructured above as
        -- `spellID` IS the swing amount -- no second call to the log needed,
        -- and that matters on the hottest path in the addon.
        local row = SpellRow(s, -1, "Melee")
        if row then row.damage = (row.damage or 0) + (tonumber(spellID) or 0) end
        return
    end

    if not spellID then return end
    local row = SpellRow(s, spellID, spellName)
    if not row then return end

    if kind == "cast" then
        row.casts   = (row.casts or 0) + 1
        row.lastSeen = time()
        s.gcds = (s.gcds or 0) + 1
        self._lastCast = spellID
    elseif kind == "damage" then
        row.damage  = (row.damage or 0) + (tonumber(amount) or 0)
    elseif kind == "healing" then
        row.healing = (row.healing or 0) + (tonumber(amount) or 0)
    elseif kind == "aura" then
        -- A proc you were given. Counting these against the casts that consume
        -- them is how "procs you let expire" gets answered later.
        row.auraGained = (row.auraGained or 0) + 1
    elseif kind == "auragone" then
        row.auraLost = (row.auraLost or 0) + 1
    end
end

-- ── Bars and spellbook ────────────────────────────────────────────────────
--
-- The waste question needs three sets, and the differences between them are
-- the whole answer:
--
--   known but not on bars  -> you have forgotten you own it
--   on bars but never cast -> dead space on your bars
--   cast but no output     -> a button that does nothing for you

function R:ScanBars()
    local s = Store()
    if not s then return end
    wipe(s.bars)
    local n = 0
    -- 120 slots covers every bar page on every client that has them.
    for slot = 1, 120 do
        local kind, id = Try(GetActionInfo, slot)
        if kind == "spell" and id then
            s.bars[id] = true
            n = n + 1
            if n >= MAX_BARS then break end
        end
    end
end

function R:ScanSpellbook()
    local s = Store()
    if not s then return end
    wipe(s.known)

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local lines = Try(C_SpellBook.GetNumSpellBookSkillLines) or 0
        for line = 1, lines do
            local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if type(info) == "table" and info.numSpellBookItems then
                for i = info.itemIndexOffset + 1,
                        info.itemIndexOffset + info.numSpellBookItems do
                    local item = Try(C_SpellBook.GetSpellBookItemInfo, i,
                                     Enum and Enum.SpellBookSpellBank
                                          and Enum.SpellBookSpellBank.Player)
                    if type(item) == "table" and item.spellID then
                        s.known[item.spellID] = true
                    end
                end
            end
        end
        if next(s.known) then return end
    end

    -- Legacy spellbook, for clients without C_SpellBook.
    local tabs = Try(GetNumSpellTabs) or 0
    for tab = 1, tabs do
        local _, _, offset, num = Try(GetSpellTabInfo, tab)
        for i = (offset or 0) + 1, (offset or 0) + (num or 0) do
            local _, id = Try(GetSpellBookItemInfo, i, "spell")
            if id then s.known[id] = true end
        end
    end
end

-- ── Fight boundaries ──────────────────────────────────────────────────────

function R:OnCombatStart()
    self._combatStart = GetTime and GetTime() or nil
end

function R:OnCombatEnd()
    local s = Store()
    if not s or not self._combatStart then return end
    local dur = (GetTime and GetTime() or 0) - self._combatStart
    self._combatStart = nil
    -- Short scraps distort every per-fight average, so they are counted as
    -- neither a fight nor its seconds. Their casts are already recorded.
    if dur < MIN_FIGHT_SECONDS then return end
    s.fights  = (s.fights or 0) + 1
    s.seconds = (s.seconds or 0) + dur
end

-- ── Events ────────────────────────────────────────────────────────────────

function R:OnEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLog()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:OnCombatEnd()
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        self:ScanBars()
    elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB"
        or event == "LEARNED_SPELL_IN_SKILL_LINE" then
        self:ScanSpellbook()
    end
end

function R:OnEnterWorld()
    playerGUID = Try(UnitGUID, "player")
    self:ScanBars()
    self:ScanSpellbook()
end

-- ── Init ──────────────────────────────────────────────────────────────────

function R:Init()
    playerGUID = Try(UnitGUID, "player")

    TA:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    TA:RegisterEvent("PLAYER_REGEN_DISABLED")
    TA:RegisterEvent("PLAYER_REGEN_ENABLED")
    TA:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    TA:RegisterEvent("SPELLS_CHANGED")
    TA:RegisterEvent("LEARNED_SPELL_IN_TAB")
    TA:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r CombatRecorder recording.")
    end
end
