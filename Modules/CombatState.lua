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
    targetTTD    = 999,      -- Time-To-Die estimate (seconds); 999 = unknown/long-lived
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
    -- 12.0 PTR: UnitHealth/UnitHealthMax can return "secret number" values
    -- when execution is tainted. We must catch ALL errors including arithmetic
    -- on the result. Use a full pcall around the entire calculation.
    local ok, health, healthMax = pcall(function()
        local h = UnitHealth("player")
        local hm = UnitHealthMax("player")
        -- Force through tonumber to strip secret flag (may still fail)
        h = tonumber(tostring(h)) or 0
        hm = tonumber(tostring(hm)) or 1
        return h, hm
    end)
    if ok and health then
        s.health    = health
        s.healthMax = healthMax or 1
        s.healthPct = (s.healthMax > 0) and (s.health / s.healthMax * 100) or 100
    end
    -- On failure: leave previous values intact (don't zero them out)
end

local function UpdatePower()
    local s = CS.state
    -- 12.0 PTR: Same taint issue as health. Full pcall around all arithmetic.
    local ok, pType, power, powerMax, cp = pcall(function()
        local pt = UnitPowerType("player") or 0
        local p  = tonumber(tostring(UnitPower("player"))) or 0
        local pm = tonumber(tostring(UnitPowerMax("player"))) or 1
        local cpts = 0
        local cpMax2 = tonumber(tostring(UnitPowerMax("player", Enum.PowerType.ComboPoints))) or 0
        if pt == Enum.PowerType.ComboPoints or cpMax2 > 0 then
            cpts = tonumber(tostring(UnitPower("player", Enum.PowerType.ComboPoints))) or 0
        end
        return pt, p, pm, cpts
    end)
    if ok and power then
        s.powerType  = pType or 0
        s.power      = power
        s.powerMax   = powerMax or 1
        s.powerPct   = (s.powerMax > 0) and (s.power / s.powerMax * 100) or 0
        s.comboPoints = cp or 0
    end
end

local function UpdateTarget()
    local s = CS.state
    s.targetExists = UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
    if s.targetExists then
        local ok, h, hm = pcall(function()
            local th = tonumber(tostring(UnitHealth("target"))) or 0
            local thm = tonumber(tostring(UnitHealthMax("target"))) or 1
            return th, thm
        end)
        if ok and h then
            s.targetHealth = h
            s.targetPct    = (hm and hm > 0) and (h / hm * 100) or 100
        end
    else
        s.targetHealth = 0
        s.targetPct    = 100
    end
end

-- ── Time-To-Die (TTD) estimation ──────────────────────────────────────────────
-- Tracks target HP change rate over a 3-second sliding window.
-- If target is losing HP steadily, estimates seconds until death.
local TTD_WINDOW = 3.0       -- seconds of history to consider
local ttdSamples = {}        -- { { time, healthPct }, ... }

local function UpdateTTD()
    local s = CS.state
    if not s.targetExists then
        s.targetTTD = 999
        wipe(ttdSamples)
        return
    end

    local now = GetTime()
    table.insert(ttdSamples, { time = now, pct = s.targetPct })

    -- Trim old samples outside the window
    while #ttdSamples > 0 and (now - ttdSamples[1].time) > TTD_WINDOW do
        table.remove(ttdSamples, 1)
    end

    -- Need at least 2 samples to compute rate
    if #ttdSamples < 2 then
        s.targetTTD = 999
        return
    end

    -- Calculate HP loss rate (% per second) using first and last sample
    local oldest = ttdSamples[1]
    local newest = ttdSamples[#ttdSamples]
    local dt = newest.time - oldest.time
    if dt < 0.5 then
        s.targetTTD = 999
        return
    end

    local dpct = oldest.pct - newest.pct  -- positive = losing health
    if dpct <= 0 then
        -- Target is healing or stable
        s.targetTTD = 999
        return
    end

    local ratePctPerSec = dpct / dt
    -- Estimate time to reach 0% from current
    s.targetTTD = s.targetPct / ratePctPerSec
end

local function UpdateBuffs()
    local s = CS.state
    wipe(s.buffs)
    for i = 1, 40 do
        local ok, auraData = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not auraData then break end
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
        -- 12.0 PTR: GetDebuffDataByIndex can error when tainted
        local ok, auraData = pcall(C_UnitAuras.GetDebuffDataByIndex, "target", i, "PLAYER")
        if not ok or not auraData then break end
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
    local start, duration = U.GetSpellCooldown(61304)  -- 61304 = the hidden GCD spell
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
    pcall(UpdateTTD)
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

-- Does this ability need time to pay off (DoT / setup / ramp)? Used to suppress
-- it when the target is about to die.
--
-- This used to be inlined in GetNextN's if/elseif chain, where it had a bug that
-- silently swallowed abilities: entering the branch skipped the entry whether or
-- not it was actually long-ramp, because the computed result was discarded rather
-- than acted on. Since nearly every entry carries `tags`, that meant almost the
-- whole priority list was skipped once targetTTD dropped below 3 — the prediction
-- bar would stall or blank right as a mob was dying.
local function IsLongRamp(entry)
    if entry.tags then
        for _, tag in ipairs(entry.tags) do
            if tag == "dot" or tag == "setup" or tag == "ramp" then return true end
        end
    end
    -- Name-based fallback for entries whose tags don't say so.
    if entry.name then
        local ln = entry.name:lower()
        if ln:find("mark") or (ln:find("shock") and ln:find("flame"))
        or ln:find("corruption") or ln:find("agony")
        or ln:find("moonfire") or ln:find("sunfire")
        or ln:find("rake") or ln:find("rip")
        or ln:find("rupture") or ln:find("garrote")
        or ln:find("pain") or ln:find("vampiric")
        or ln:find("immolate") or ln:find("unstable") then
            return true
        end
    end
    return false
end

--- Evaluate an entry's `when` predicate (see Data/RotationConditions.lua).
--- Absent or erroring predicates are treated as "eligible" — a bad condition
--- must never hide an ability, only fail to promote it.
--- @return boolean eligible
local function PassesWhen(entry, state)
    if not entry.when then return true end
    -- Predicates receive (state, entry); the entry lets proc-aware conditions
    -- such as C.ExecuteOrProc consult the spellID.
    local ok, want = pcall(entry.when, state, entry)
    if not ok then
        if TA.ErrorLog then
            TA.ErrorLog:Log("Rotation condition",
                string.format("%s (%s): %s", entry.name or "?",
                    tostring(entry.spellID), tostring(want)), "")
        end
        return true
    end
    return want ~= false
end

--- Is this ability already active as an aura, with meaningful duration left?
---
--- This is the one dynamic rule that needs no per-spec authoring: recasting a
--- DoT or self-buff that still has most of its duration remaining is wrong for
--- every spec in the game. Most damage-over-time and maintenance-buff spells
--- apply an aura whose spellID matches the cast, so this catches them
--- generically. Abilities that apply no aura simply never match.
---
--- Deliberately *not* applied to `isCd`/`isMajorCd` entries (already excluded
--- from prediction) or to entries with an explicit `when` — an author who wrote
--- a condition has said what they mean, and this should not second-guess it.
local AURA_REFRESH_WINDOW = 4  -- seconds; refresh inside this is fine (pandemic-ish)

local function AlreadyActive(entry, state)
    if entry.when then return false end
    local id = entry.spellID
    if not id then return false end

    local d = state.debuffs and state.debuffs[id]
    if d and d.expires and d.expires > 0 then
        if (d.expires - GetTime()) > AURA_REFRESH_WINDOW then return true end
    end

    local b = state.buffs and state.buffs[id]
    if b and b.expires and b.expires > 0 then
        if (b.expires - GetTime()) > AURA_REFRESH_WINDOW then return true end
    end

    return false
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

            -- Suppress long-ramp abilities on a target that's about to die
            if IsLongRamp(entry) and self.state.targetTTD and self.state.targetTTD < 3 then
                dominated = true; break
            end

            -- Must be a known spell
            if entry.spellID then
                local isKnown = U.IsSpellKnown(entry.spellID)
                if not isKnown then dominated = true; break end

                -- Authored condition (Data/RotationConditions.lua)
                if not PassesWhen(entry, self.state) then dominated = true; break end

                -- Already ticking as a DoT/self-buff — don't suggest a re-cast
                if AlreadyActive(entry, self.state) then dominated = true; break end

                -- Must be off cooldown (or have charges available)
                -- 12.0 PTR: cdInfo fields can be tainted secret numbers
                local cdOk = pcall(function()
                    local cdInfo = C_Spell.GetSpellCooldown(entry.spellID)
                    if cdInfo then
                        local dur = tonumber(tostring(cdInfo.duration)) or 0
                        if dur > 1.5 then
                            local st = tonumber(tostring(cdInfo.startTime)) or 0
                            local remaining = (st + dur) - GetTime()
                            if remaining > 0.1 then
                                local charges = C_Spell.GetSpellCharges(entry.spellID)
                                if not charges or charges.currentCharges == 0 then
                                    error("blocked")
                                end
                            end
                        end
                    end
                end)
                if not cdOk then dominated = true; break end

                -- Must be usable (resource, etc.)
                if C_Spell.IsSpellUsable then
                    local usOk, usable = pcall(C_Spell.IsSpellUsable, entry.spellID)
                    if usOk and usable == false then dominated = true; break end
                end
            end

        until true

        -- This ability passes all checks — it's the "next best" action
        if not dominated then
            return i, entry
        end
    end

    return nil, nil
end

--- Get the top N recommended abilities from the priority list with
--- GCD-forward simulation. After each ability is "selected," the engine
--- simulates that GCD has elapsed and that spell is on cooldown, then
--- re-evaluates for the next ability. This produces a true 3-GCD
--- lookahead rather than just "3 things available right now."
--- @param priorities table — array of rotation entry tables
--- @param playerLevel number
--- @param count number — how many abilities to return (default 3)
--- @return table — array of { index=number, entry=table } (up to count entries)
function CS:GetNextN(priorities, playerLevel, count)
    count = count or 3
    local results = {}
    if not priorities then return results end
    local now = GetTime()

    -- Simulated state: tracks which spellIDs have been "used" and at what
    -- simulated future time they become available again.
    local simUsed = {}       -- [spellID] = simulated CD end time
    local simTime = now      -- advances by GCD after each selection
    local GCD_LENGTH = 1.5   -- base GCD (haste would reduce, but 1.5 is safe)

    -- Get current haste for more accurate GCD estimate
    -- 12.0 PTR: GetHaste() can return a tainted "secret number"
    local ok, hasteVal = pcall(function()
        return tonumber(tostring(GetHaste and GetHaste() or 0)) or 0
    end)
    local hastePercent = (ok and hasteVal) or 0
    if hastePercent > 0 then
        GCD_LENGTH = math.max(0.75, 1.5 / (1 + hastePercent / 100))
    end

    for pass = 1, count do
        local bestEntry = nil
        local bestIndex = nil

        for i, entry in ipairs(priorities) do
            -- Skip cooldowns section
            if entry.isCd or entry.isMajorCd then
                -- skip
            elseif entry.unlockLv and playerLevel < entry.unlockLv then
                -- skip — level gated
            elseif IsLongRamp(entry) and self.state.targetTTD and self.state.targetTTD < 3 then
                -- TTD filter: suppress long-ramp abilities (DoTs, marks, setup)
                -- when the target will die before they pay off.
            elseif entry.spellID then
                local dominated = false
                repeat
                    local isKnown = U.IsSpellKnown(entry.spellID)
                    if not isKnown then dominated = true; break end

                    -- Authored condition (Data/RotationConditions.lua).
                    if not PassesWhen(entry, self.state) then dominated = true; break end

                    -- Generic aura rule: don't re-suggest a DoT/self-buff that is
                    -- already ticking. Only applied on the first simulated slot —
                    -- by slots 2 and 3 the aura may legitimately need refreshing,
                    -- and we can't model its decay accurately that far ahead.
                    if pass == 1 and AlreadyActive(entry, self.state) then
                        dominated = true; break
                    end

                    -- Check if this spell was already "used" in a prior simulated GCD
                    -- For spells with no CD (fillers): prevent picking same spell
                    -- in consecutive slots (real gameplay alternates)
                    if simUsed[entry.spellID] then
                        if simUsed[entry.spellID] > simTime then
                            -- Still on simulated cooldown
                            local charges = C_Spell.GetSpellCharges(entry.spellID)
                            local realCharges = charges and charges.currentCharges or 0
                            local usedCount = 0
                            for _, r in ipairs(results) do
                                if r.entry.spellID == entry.spellID then usedCount = usedCount + 1 end
                            end
                            if realCharges <= usedCount then
                                dominated = true; break
                            end
                        else
                            -- Spell CD has "expired" in sim, but don't repeat
                            -- the same filler back-to-back (looks wrong on the bar)
                            local lastPicked = results[#results]
                            if lastPicked and lastPicked.entry.spellID == entry.spellID then
                                dominated = true; break
                            end
                        end
                    end

                    -- Check real cooldown state adjusted for simulated time offset
                    -- 12.0 PTR: cdInfo fields can be tainted secret numbers
                    local cdBlocked = pcall(function()
                        local cdInfo = C_Spell.GetSpellCooldown(entry.spellID)
                        if cdInfo then
                            local dur = tonumber(tostring(cdInfo.duration)) or 0
                            if dur > 1.5 then
                                local cdStart = tonumber(tostring(cdInfo.startTime)) or 0
                                local cdEnd = cdStart + dur
                                if cdEnd > simTime + 0.1 then
                                    local charges = C_Spell.GetSpellCharges(entry.spellID)
                                    if not charges or charges.currentCharges == 0 then
                                        error("blocked")  -- signal to outer pcall
                                    end
                                end
                            end
                        end
                    end)
                    if not cdBlocked then dominated = true; break end

                    -- Resource check (only for first pass — we can't predict regen accurately)
                    if pass == 1 and C_Spell.IsSpellUsable then
                        local usOk, usable = pcall(C_Spell.IsSpellUsable, entry.spellID)
                        if usOk and usable == false then dominated = true; break end
                    end
                until true

                if not dominated and not bestEntry then
                    bestEntry = entry
                    bestIndex = i
                end
            end

            if bestEntry then break end  -- found best for this pass
        end

        if bestEntry then
            table.insert(results, { index = bestIndex, entry = bestEntry })

            -- Simulate: advance time by GCD and mark this spell as used
            simTime = simTime + GCD_LENGTH
            if bestEntry.spellID then
                -- Estimate the spell's cooldown for simulation
                -- 12.0 PTR: cdInfo.duration can be tainted
                local spellCD = GCD_LENGTH
                pcall(function()
                    local cdInfo = C_Spell.GetSpellCooldown(bestEntry.spellID)
                    if cdInfo then
                        local dur = tonumber(tostring(cdInfo.duration)) or 0
                        if dur > 1.5 then spellCD = dur end
                    end
                end)
                simUsed[bestEntry.spellID] = now + spellCD
            end
        else
            break  -- no more abilities available in simulated future
        end
    end

    return results
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
    -- CombatState uses its OWN event frame — NOT TA.eventFrame.
    -- This prevents taint propagation from other modules (MapPins, CoordResolver,
    -- etc.) from contaminating health/power/aura queries with "secret" values.
    -- Taint flows through shared frames; an isolated frame stays clean.
    local csFrame = CreateFrame("Frame", "TACombatStateFrame")
    self._eventFrame = csFrame

    csFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    csFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    csFrame:RegisterEvent("UNIT_HEALTH")
    csFrame:RegisterEvent("UNIT_POWER_FREQUENT")
    csFrame:RegisterEvent("UNIT_AURA")
    csFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    csFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    csFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    csFrame:SetScript("OnEvent", function(_, event, ...)
        if CS.OnEvent then
            local ok, err = pcall(CS.OnEvent, CS, event, ...)
            if not ok and TA.ErrorLog then
                TA.ErrorLog:Log("CombatState OnEvent", tostring(err), "")
            end
        end
    end)

    -- Do NOT snapshot during Init — UnitHealth() may be tainted during addon load.
    -- Defer first snapshot until the player is fully in the world (2s delay)
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
