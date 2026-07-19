-- ToonAge/Modules/CombatState.lua
-- Lightweight combat state snapshot for smart rotation priority highlighting.
--
-- Architecture (inspired by WeakAuras trigger system):
--   • Event-driven primary updates (UNIT_POWER, UNIT_AURA, SPELL_COOLDOWN_CHANGED)
--   • Throttled secondary polling (0.1s) for periodic re-evaluation
--   • Exposes a simple state table that Rotation.lua queries for highlighting
--   • NO state prediction, NO ability handlers (that's Hekili's job)
--   • Goal: "which row should glow" based on what's currently true
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local CS = {}
TA:RegisterModule("CombatState", CS)

-- ── State table ───────────────────────────────────────────────────────────────
-- Readable by Rotation.lua and any module that needs combat context.

CS.state = {
    inCombat     = false,
    health       = 100,
    healthMax    = 100,
    healthPct    = 100,
    power        = 0,        -- primary resource (mana, rage, energy, etc.)
    powerMax     = 100,
    powerPct     = 0,
    powerType    = 0,        -- Enum.PowerType
    comboPoints  = 0,        -- for rogues/druids/etc.
    targetExists = false,
    targetHealth = 100,
    targetPct    = 100,
    buffs        = {},       -- [spellID] = { stacks=N, expires=T }
    debuffs      = {},       -- [spellID] = { stacks=N, expires=T } (on target)
    cooldowns    = {},       -- [spellID] = { start=T, duration=D, charges=N }
    gcd          = 0,        -- remaining GCD in seconds
    aoeCount     = 1,        -- estimated enemies nearby (from nameplates)
}

-- ── Internal throttle ─────────────────────────────────────────────────────────
local POLL_INTERVAL = 0.1
local pollTicker    = nil
local dirty         = true   -- set true on any event, cleared after snapshot

-- ── Snapshot functions ────────────────────────────────────────────────────────

local function UpdateHealth()
    local s = CS.state
    s.health    = tonumber(UnitHealth("player")) or 0
    s.healthMax = tonumber(UnitHealthMax("player")) or 1
    if s.healthMax > 0 then
        s.healthPct = s.health / s.healthMax * 100
    else
        s.healthPct = 100
    end
end

local function UpdatePower()
    local s = CS.state
    s.powerType = UnitPowerType("player") or 0
    s.power     = tonumber(UnitPower("player")) or 0
    s.powerMax  = tonumber(UnitPowerMax("player")) or 1
    if s.powerMax > 0 then
        s.powerPct = s.power / s.powerMax * 100
    else
        s.powerPct = 0
    end

    -- Combo points (if applicable)
    local cpMax = tonumber(UnitPowerMax("player", Enum.PowerType.ComboPoints)) or 0
    if s.powerType == Enum.PowerType.ComboPoints or cpMax > 0 then
        s.comboPoints = tonumber(UnitPower("player", Enum.PowerType.ComboPoints)) or 0
    else
        s.comboPoints = 0
    end
end

local function UpdateTarget()
    local s = CS.state
    s.targetExists = UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
    if s.targetExists then
        local h = tonumber(UnitHealth("target")) or 0
        local hMax = tonumber(UnitHealthMax("target")) or 1
        s.targetHealth = h
        s.targetPct    = (hMax > 0) and (h / hMax * 100) or 100
    else
        s.targetHealth = 0
        s.targetPct    = 100
    end
end

local function UpdateBuffs()
    local s = CS.state
    wipe(s.buffs)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        if auraData.spellId then
            s.buffs[auraData.spellId] = {
                stacks  = auraData.applications or 0,
                expires = auraData.expirationTime or 0,
            }
        end
    end
end

local function UpdateDebuffsOnTarget()
    local s = CS.state
    wipe(s.debuffs)
    if not s.targetExists then return end
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetDebuffDataByIndex("target", i, "PLAYER")
        if not auraData then break end
        if auraData.spellId then
            s.debuffs[auraData.spellId] = {
                stacks  = auraData.applications or 0,
                expires = auraData.expirationTime or 0,
            }
        end
    end
end

local function UpdateCooldowns(spellIDs)
    local s = CS.state
    -- Only update specific spellIDs if provided, otherwise skip (too expensive to scan all)
    if not spellIDs then return end
    for _, spellID in ipairs(spellIDs) do
        local cdInfo = C_Spell.GetSpellCooldown(spellID)
        if cdInfo then
            s.cooldowns[spellID] = {
                start    = cdInfo.startTime or 0,
                duration = cdInfo.duration or 0,
                charges  = 0,
            }
            -- Check charges
            local charges = C_Spell.GetSpellCharges(spellID)
            if charges then
                s.cooldowns[spellID].charges = charges.currentCharges or 0
            end
        end
    end
end

local function UpdateGCD()
    local s = CS.state
    local start, duration = GetSpellCooldown(61304)  -- GCD spell (hidden global)
    if start and start > 0 and duration and duration > 0 then
        local remaining = (start + duration) - GetTime()
        s.gcd = remaining > 0 and remaining or 0
    else
        s.gcd = 0
    end
end

local function UpdateAoeCount()
    local s = CS.state
    -- Count hostile nameplates as a proxy for nearby enemies
    local count = 0
    local nameplates = C_NamePlate.GetNumNamePlates and C_NamePlate.GetNumNamePlates() or 0
    -- Iterate nameplates (up to 40)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            count = count + 1
        end
    end
    s.aoeCount = math.max(1, count)
end

-- ── Full snapshot ─────────────────────────────────────────────────────────────

function CS:Snapshot()
    local s = self.state
    s.inCombat = UnitAffectingCombat("player") or false
    pcall(UpdateHealth)
    pcall(UpdatePower)
    pcall(UpdateTarget)
    pcall(UpdateBuffs)
    pcall(UpdateDebuffsOnTarget)
    pcall(UpdateGCD)
    pcall(UpdateAoeCount)
    dirty = false
end

-- ── Polling ticker ────────────────────────────────────────────────────────────

local function OnPoll()
    if not CS.state.inCombat and not dirty then return end
    CS:Snapshot()
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Check if a specific buff is active on the player.
--- @param spellID number
--- @return boolean active, number stacks, number remainingSec
function CS:HasBuff(spellID)
    local b = self.state.buffs[spellID]
    if not b then return false, 0, 0 end
    local remaining = b.expires > 0 and (b.expires - GetTime()) or 999
    return remaining > 0, b.stacks, remaining
end

--- Check if a specific debuff is active on the target (cast by player).
--- @param spellID number
--- @return boolean active, number stacks, number remainingSec
function CS:HasDebuff(spellID)
    local d = self.state.debuffs[spellID]
    if not d then return false, 0, 0 end
    local remaining = d.expires > 0 and (d.expires - GetTime()) or 999
    return remaining > 0, d.stacks, remaining
end

--- Check if a spell is off cooldown and usable.
--- @param spellID number
--- @return boolean ready, number remaining
function CS:IsReady(spellID)
    local cd = self.state.cooldowns[spellID]
    if not cd then
        -- Not tracked yet — do a live check
        local cdInfo = C_Spell.GetSpellCooldown(spellID)
        if not cdInfo then return true, 0 end
        local remaining = (cdInfo.startTime + cdInfo.duration) - GetTime()
        return remaining <= 0, math.max(0, remaining)
    end
    local remaining = (cd.start + cd.duration) - GetTime()
    if remaining <= 0 then return true, 0 end
    return false, remaining
end

--- Get the recommended "next ability" index from a priority list.
--- Evaluates: spell is known, off cooldown, meets level requirement.
--- Returns the index into the priorities array, or nil.
--- @param priorities table — array of rotation entry tables
--- @param playerLevel number
--- @return number|nil bestIndex, table|nil bestEntry
function CS:GetNextAbility(priorities, playerLevel)
    if not priorities then return nil, nil end
    local now = GetTime()

    for i, entry in ipairs(priorities) do
        local dominated = false
        repeat  -- single-pass block for "continue" via break

            -- Skip cooldowns section (those are situational)
            if entry.isCd or entry.isMajorCd then dominated = true; break end

            -- Level gate
            if entry.unlockLv and playerLevel < entry.unlockLv then dominated = true; break end

            -- Must be a known spell
            if entry.spellID then
                local isKnown = IsSpellKnown(entry.spellID) or IsPlayerSpell(entry.spellID)
                if not isKnown then dominated = true; break end

                -- Must be off cooldown (or have charges available)
                local cdInfo = C_Spell.GetSpellCooldown(entry.spellID)
                if cdInfo and cdInfo.duration > 1.5 then
                    -- On real cooldown (not just GCD)
                    local remaining = (cdInfo.startTime + cdInfo.duration) - now
                    if remaining > 0.1 then
                        -- Check charges
                        local charges = C_Spell.GetSpellCharges(entry.spellID)
                        if not charges or charges.currentCharges == 0 then
                            dominated = true; break
                        end
                    end
                end

                -- Must be usable (resource, etc.)
                local usable = C_Spell.IsSpellUsable(entry.spellID)
                if usable == false then dominated = true; break end
            end

        until true

        -- This ability passes all checks — it's the "next best" action
        if not dominated then
            return i, entry
        end
    end

    return nil, nil
end

-- ── Event handling ────────────────────────────────────────────────────────────

function CS:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self.state.inCombat = true
        dirty = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.state.inCombat = false
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then UpdateHealth() end
        if unit == "target" then UpdateTarget() end
    elseif event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then UpdatePower(); dirty = true end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then UpdateBuffs(); dirty = true end
        if unit == "target" then UpdateDebuffsOnTarget() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateTarget()
        UpdateDebuffsOnTarget()
        dirty = true
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        UpdateAoeCount()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function CS:Init()
    -- Register combat-relevant events
    local ef = TA.eventFrame
    ef:RegisterEvent("PLAYER_REGEN_DISABLED")
    ef:RegisterEvent("PLAYER_REGEN_ENABLED")
    ef:RegisterEvent("UNIT_HEALTH")
    ef:RegisterEvent("UNIT_POWER_FREQUENT")
    ef:RegisterEvent("UNIT_AURA")
    ef:RegisterEvent("PLAYER_TARGET_CHANGED")
    ef:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    ef:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Do NOT snapshot during Init — UnitHealth() is tainted during addon load.
    -- Defer first snapshot until the player is fully in the world (2s delay)
    -- and the ticker will keep it updated after that.
    C_Timer.After(2, function()
        local ok, err = pcall(CS.Snapshot, CS)
        if not ok and TA.debug then
            print("|cFFFF4444[TA CombatState]|r Deferred snapshot failed: " .. tostring(err))
        end
    end)

    -- Start polling ticker (only does work in combat or when dirty)
    pollTicker = C_Timer.NewTicker(POLL_INTERVAL, OnPoll)
end

-- No slash commands — this is a background service module
CS.SlashCommands = {}
