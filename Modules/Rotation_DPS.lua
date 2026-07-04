-- CharacterAdvisor/Data/Rotation_DPS.lua
local CA = CharacterAdvisor
if not CA then return end
CA.Data = CA.Data or {}
CA.Data.Rotations = CA.Data.Rotations or {}
local R = CA.Data.Rotations

R.DPS = R.DPS or {}

-- Example empty template for a spec (fill in later)
R.DPS[253] = {
    solo_st   = { tip = "Solo single-target", priorities = {}, chain = {} },
    solo_aoe  = { tip = "Solo AoE",           priorities = {}, chain = {} },
    raid_st   = { tip = "Raid single-target", priorities = {}, chain = {} },
    raid_aoe  = { tip = "Raid AoE",           priorities = {}, chain = {} },
    delve_st  = { tip = "Delve single-target",priorities = {}, chain = {} },
    delve_aoe = { tip = "Delve AoE",          priorities = {}, chain = {} },
    pvp       = { tip = "PvP rotation",       priorities = {}, chain = {} },
}
