-- ToonAge/Data/TA_Enchants.lua
-- Midnight Expansion enchant → profession mapping.
-- Keys are the enchantID field from the item link (item:id:enchantID:...).
-- spellID is the crafting spell checked with IsSpellKnown() to verify recipe ownership.

local TA = ToonAge
TA.Data = TA.Data or {}

-- Emptied 2026-09-16. Every key here was a sequential placeholder (74001, 74002 ...)
-- with matching placeholder spellIDs (445001 ...), so no real item link's enchantID
-- ever matched and the profession/recipe checks in Gear.lua never ran. The enchant
-- NAMES were real Midnight enchants, but a name can't be matched against an item
-- link. Populate with verified IDs only: equip the enchanted item and read field 2
-- of the item string (`/dump GetInventoryItemLink("player", slot)`), and take the
-- recipe spellID from the Enchanting book. Until then Gear.lua reports a present
-- enchant as "Enchanted" and skips the profession check, which is correct behavior.
TA.Data.EnchantProfessionMap = {}
