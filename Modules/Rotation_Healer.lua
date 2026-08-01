-- CharacterAdvisor/Data/Rotation_Healer.lua
local CA = CharacterAdvisor
if not CA then return end
CA.Data = CA.Data or {}
CA.Data.Rotations = CA.Data.Rotations or {}
local R = CA.Data.Rotations

R.HEALER = R.HEALER or {}

-- Example template for Restoration Druid (specID 105)
R.HEALER[105] = {
    healing       = { tip = "Base healing priority", priorities = {}, chain = {} },
    healing_raid  = { tip = "Raid healing",          priorities = {}, chain = {} },
    healing_delve = { tip = "Delve healing",         priorities = {}, chain = {} },
    healing_pvp   = { tip = "PvP healing",           priorities = {}, chain = {} },
}
