-- ToonAge/Data/Forever/Reagents.lua
--
-- Forever reagent restock list. Every item ID below is verified against the
-- Icy Veins WoW Forever item database (db.icy-veins.com/wow-forever/items/*).
--
-- Light Feather 17056:
--   https://db.icy-veins.com/wow-forever/items/17056
--   Slow Fall (130), Levitate, Study (1302508), Bundle of Scrolls; stack 20.
-- Arcane Powder 17020:
--   https://db.icy-veins.com/wow-forever/items/17020
--   Arcane Brilliance reagent; stack 20.
-- Rune of Teleportation 17031:
--   https://db.icy-veins.com/wow-forever/items/17031
--   Mage Teleport reagent; stack 20.
-- Rune of Portals 17032:
--   https://db.icy-veins.com/wow-forever/items/17032
--   Mage Portal reagent; stack 20.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ForeverReagents = {
    {
        itemID = 17056,
        name = "Light Feather",
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
        itemID = 17020,
        name = "Arcane Powder",
        defaultTarget = 20,
        source = "https://db.icy-veins.com/wow-forever/items/17020",
        uses = {
            { name = "Arcane Brilliance" },
        },
    },
    {
        itemID = 17031,
        name = "Rune of Teleportation",
        defaultTarget = 10,
        source = "https://db.icy-veins.com/wow-forever/items/17031",
        uses = {
            { name = "Teleport" },
        },
    },
    {
        itemID = 17032,
        name = "Rune of Portals",
        defaultTarget = 10,
        source = "https://db.icy-veins.com/wow-forever/items/17032",
        uses = {
            { name = "Portal" },
        },
    },
}
