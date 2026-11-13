-- ToonAge/Data/Forever/Reagents.lua
--
-- Forever reagent restock list. An item id is included only when a Forever
-- source names it, or when Data/Forever already has that id. Names without
-- an id are UNKNOWN and are not counted.
--
-- Light Feather 17056:
--   https://db.icy-veins.com/wow-forever/items/17056
--   That page names Slow Fall, Levitate, and Bundle of Scrolls, and gives
--   max stack 20. Study 1302508 is the spell this list warns on. It is not
--   in the harvested Data/Forever/Spells.lua. Slow Fall 130 is (learned 12).
--   Levitate and Bundle of Scrolls have no spell id in this repo.
--
-- Arcane Powder, Rune of Teleportation, and Rune of Portals are classic Mage
-- reagent names. No item id for them exists in Data/Forever, so they stay
-- UNKNOWN. Do not fill those ids in from another expansion.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ForeverReagents = {
    {
        itemID = 17056,
        name = "Light Feather",
        -- Starting target is the max stack on the source page. Settings edits it.
        defaultTarget = 20,
        source = "https://db.icy-veins.com/wow-forever/items/17056",
        uses = {
            { spellID = 1302508, name = "Study" },
            { spellID = 130, name = "Slow Fall" },
            { name = "Levitate" },
            { name = "Bundle of Scrolls" },
        },
    },
    {
        name = "Arcane Powder",
        status = "UNKNOWN",
        note = "Classic Mage reagent. No item id in Data/Forever. Not counted.",
    },
    {
        name = "Rune of Teleportation",
        status = "UNKNOWN",
        note = "Classic Mage reagent. No item id in Data/Forever. Not counted.",
    },
    {
        name = "Rune of Portals",
        status = "UNKNOWN",
        note = "Classic Mage reagent. No item id in Data/Forever. Not counted.",
    },
}
