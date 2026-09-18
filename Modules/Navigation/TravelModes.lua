-- ToonAge/Modules/TravelModes.lua
-- Travel-state helper consumed by Arrow.lua for ETA.
--
-- GetUnitSpeed is intentionally NOT used here: it returns a "secret number"
-- when called from a tainted execution context (OnUpdate tainted by addon
-- interaction with secure frames), and any comparison of secret numbers throws
-- a Lua error ("attempt to compare secret number value").
-- Mount-state APIs (IsFlying, IsMounted, IsPlayerDynamicFlying) are
-- unrestricted and return normal booleans regardless of taint state.

local TA = ToonAge
local TM = {}
TA:RegisterModule("TravelModes", TM)

-- Approximate yards-per-second for each travel mode.
-- These are typical values; actual speed varies by mount and player speed%.
-- ETA is approximate so this precision is sufficient.
local SPEED = {
    dragonride = 32,   -- dynamic flight base cruise
    flying     = 22,   -- 310% flying mount
    mounted    = 14,   -- 200% ground mount
    running    =  7,   -- 100% ground (walking/running blended)
}

function TM:GetMode()
    if IsPlayerDynamicFlying and IsPlayerDynamicFlying() then return "dragonride" end
    if IsFlying()  then return "flying"  end
    if IsMounted() then return "mounted" end
    return "running"
end

function TM:GetSpeed()
    return SPEED[self:GetMode()] or 7
end

function TM:Init() end
