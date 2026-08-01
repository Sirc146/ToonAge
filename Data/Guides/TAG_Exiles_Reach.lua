-- ToonAge/Data/Guides/TAG_Exiles_Reach.lua
-- Exile's Reach does not exist in Classic (Mists of Pandaria).
-- This stub registers the guide ID so references don't error,
-- but contains no steps.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Guides = TA.Data.Guides or {}

table.insert(TA.Data.Guides, {
    id        = "exiles_reach",
    title     = "Exile's Reach (Not Available)",
    expansion = "starter",
    zone      = 0,
    minLevel  = 1,
    maxLevel  = 10,
    nextGuide = nil,
    classic   = true,
    note      = "Exile's Reach does not exist in Mists of Pandaria Classic. Use race-specific starting zones instead.",
    steps     = {},
})
