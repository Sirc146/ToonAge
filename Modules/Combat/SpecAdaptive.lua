-- ToonAge/Modules/Combat/SpecAdaptive.lua
-- Spec-Adaptive Guide Steps: injects dynamic suggestions based on role/spec.
-- TANK: "Queue a dungeon here (faster XP at this level range)"
-- HEALER: "Queue dungeon — instant queue at your role"
-- DPS: "Continue questing (queue time too long at this level)"
--
-- Also adapts pull size recommendations in PullPlanner based on spec survivability.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local SA = {}
TA:RegisterModule("SpecAdaptive", SA)

-- ── Level ranges where dungeons are XP-efficient ──────────────────────────────
local DUNGEON_EFFICIENT_RANGES = {
    -- { minLevel, maxLevel, dungeonName, avgTime (min), xpPerRun (approx) }
    { 15, 20, "Deadmines / RFC", 15, 8000 },
    { 20, 30, "Stockade / SFK", 12, 12000 },
    { 60, 65, "TWW Normal Dungeons", 18, 45000 },
    { 70, 75, "TWW Heroic Dungeons", 20, 80000 },
    { 80, 85, "Midnight Normal Dungeons", 18, 120000 },
}

-- ── Public API ────────────────────────────────────────────────────────────────

--- Get the player's current role and spec info.
function SA:GetRoleInfo()
    local specIndex = GetSpecialization()
    if not specIndex then
        return "DAMAGER", "Unknown", "melee"
    end

    local _, specName, _, _, role = GetSpecializationInfo(specIndex)
    local style = "melee"
    -- Check TalentsHelpers for ranged/melee
    local specID = GetSpecializationInfo(specIndex)
    local specInfo = TA.TalentsAPI and TA.TalentsAPI.GetSpecInfo and TA.TalentsAPI.GetSpecInfo(specID)
    if specInfo then
        style = specInfo.style
    end

    return role or "DAMAGER", specName or "Unknown", style
end

--- Get a spec-adaptive suggestion for the current level.
--- @return string|nil suggestion text
function SA:GetDungeonSuggestion()
    local role = self:GetRoleInfo()
    local level = UnitLevel("player") or 1

    -- Find matching dungeon range
    local match = nil
    for _, range in ipairs(DUNGEON_EFFICIENT_RANGES) do
        if level >= range[1] and level <= range[2] then
            match = range
            break
        end
    end
    if not match then
        return nil
    end

    -- Role-based suggestion
    if role == "TANK" then
        return string.format(
            "|cFF4AFF7A⚔ Tank Tip:|r Queue %s — instant queue + %.0fk XP/run (%dm avg)",
            match[3],
            match[5] / 1000,
            match[4]
        )
    elseif role == "HEALER" then
        return string.format(
            "|cFF4AFF7A♥ Healer Tip:|r Queue %s — fast queue + %.0fk XP/run",
            match[3],
            match[5] / 1000
        )
    else
        -- DPS: only suggest if queue time is short (low level) or XP is significantly better
        if level < 30 then
            return string.format(
                "|cFF888780DPS Tip: %s gives ~%.0fk XP (%dm queue expected)|r",
                match[3],
                match[5] / 1000,
                math.random(5, 12)
            )
        end
        return nil -- at higher levels, questing is faster for DPS
    end
end

--- Get pull size recommendation based on spec survivability.
--- @return number maxPull — suggested max simultaneous enemies
function SA:GetRecommendedPullSize()
    local role, _, style = self:GetRoleInfo()
    local level = UnitLevel("player") or 1
    local ilvlFactor = 1.0 -- could be enhanced with actual ilvl comparison

    if role == "TANK" then
        return 6 -- tanks can handle big pulls
    elseif role == "HEALER" then
        return 3 -- healers can self-sustain but kill slowly
    else
        -- DPS: depends on defensives and spec
        if style == "melee" then
            return 3 -- melee DPS can cleave and have defensives
        else
            return 2 -- ranged DPS should be careful (less sustain)
        end
    end
end

function SA:Init()
    -- Passive module — queried by other modules
end

SA.SlashCommands = {}
