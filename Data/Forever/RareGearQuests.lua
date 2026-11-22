-- ToonAge/Data/Forever/RareGearQuests.lua
--
-- Verified WoW Forever (1.60.1) Rare Gear Quests & notable drop-quest upgrades.
-- Pure data: zero executable logic, zero client API calls.
--
-- Schema for each entry in `quests`:
--   {
--       questID    = number|nil,          -- verified Forever quest ID (auto-hides once completed)
--       name       = string,              -- quest title
--       zone       = string,              -- zone where the quest starts or drops
--       giver      = string,              -- NPC name, rare mob, or drop item starting the quest
--       side       = "Horde"|"Alliance"|"Both",
--       minLevel   = number,              -- earliest level to surface
--       maxLevel   = number,              -- highest level where this upgrade stays relevant
--       classes    = { MAGE = true, ... }|nil, -- nil = any class
--       slot       = string,              -- e.g. "Weapon", "Chest", "Ring", "Trinket"
--       reward     = string,              -- reward item name / concise stats summary
--       howToStart = string,              -- exact how/where instructions to obtain it
--       source     = string,              -- verified Forever URL or harvest reference
--       verified   = boolean,             -- false stays clearly labeled UNVERIFIED
--   }
--
-- Populated strictly from verified Forever sources and owner-supplied lists.
-- Never invent quest IDs or item rewards from memory.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ForeverRareGearQuests = {
    meta = {
        version = "1.60.1",
        schema = "forever-rare-gear-quests-v1",
        note = "Verified Forever rare/drop quests that award notable gear upgrades, filtered by level, faction, and completion.",
    },
    quests = {},
}
