-- CharacterAdvisor/Data/Rotation_Tank.lua
local CA = CharacterAdvisor
if not CA then return end
CA.Data = CA.Data or {}
CA.Data.Rotations = CA.Data.Rotations or {}
local R = CA.Data.Rotations

R.TANK = R.TANK or {}

-- Example template for Protection Warrior (specID 73)
R.TANK[73] = {
    tank       = { tip = "Base tank rotation", priorities = {}, chain = {} },
    tank_raid  = { tip = "Raid tanking",       priorities = {}, chain = {} },
    tank_delve = { tip = "Delve tanking",      priorities = {}, chain = {} },
    tank_pvp   = { tip = "PvP tanking",        priorities = {}, chain = {} },
}
