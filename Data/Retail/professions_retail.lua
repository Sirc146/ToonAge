-- ToonAge/Data/Retail/professions_retail.lua
-- Weights and candidates for retail profession gear.
--
-- The scorer does not name a stat. Keys are what C_Item.GetItemStats
-- returns; `name` is what a tooltip prints. Both change between expansions,
-- so they stay in this file.
--
-- `paths` maps a specialization path (by id, or by the name the client
-- reports) to the stat ids it improves. `items` lists craftable or buyable
-- gear for one expansion. Neither list is guessed here: path ids and item
-- ids come from the Chronicler table. An empty list is valid. Bag and bank
-- items are scored from their stats without being listed.
--
-- The GetItemStats keys below are the profession-gear names in use since
-- Dragonflight. The skill key is the slot for a tool's skill bonus if the
-- client returns one; a dump has not confirmed that name, so change it here
-- rather than in the scorer.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ProfessionGear = {
    -- A suggestion has to clear the equipped item by more than this.
    margin = 0,
    -- Stat id that always carries `skillWeight`, before specialization points.
    skillStat = "skill",
    skillWeight = 1,
    stats = {
        { id = "skill",            key = "ITEM_MOD_PROFESSION_SKILL",     name = "Skill" },
        { id = "multicraft",       key = "ITEM_MOD_MULTICRAFT_SHORT",      name = "Multicraft" },
        { id = "resourcefulness",  key = "ITEM_MOD_RESOURCEFULNESS_SHORT", name = "Resourcefulness" },
        { id = "craftingspeed",    key = "ITEM_MOD_CRAFTING_SPEED_SHORT",  name = "Crafting Speed" },
        { id = "ingenuity",        key = "ITEM_MOD_INGENUITY_SHORT",       name = "Ingenuity" },
        { id = "deftness",         key = "ITEM_MOD_DEFTNESS_SHORT",        name = "Deftness" },
        { id = "finesse",          key = "ITEM_MOD_FINESSE_SHORT",         name = "Finesse" },
        { id = "perception",       key = "ITEM_MOD_PERCEPTION_SHORT",      name = "Perception" },
    },
    -- Inventory order from GetProfessionSlots: tool, then two accessories.
    slots = {
        { role = "tool",      label = "Tool",      equipLoc = "INVTYPE_PROFESSION_TOOL" },
        { role = "accessory", label = "Accessory", equipLoc = "INVTYPE_PROFESSION_GEAR" },
        { role = "accessory", label = "Accessory", equipLoc = "INVTYPE_PROFESSION_GEAR" },
    },
    -- { id = <path id>, name = "<path name>", stats = { "<stat id>", ... } }
    paths = {},
    -- { itemID, profession = <parent skill line>, slot = "tool"|"accessory",
    --   source = "Craft"|"Buy", expansion = "<label of the current expansion>" }
    items = {},
}

-- Gathering Overload reminder. The button only appears for a node the
-- player is moused over or has as the soft target. Nothing here is a
-- distance scan.
--
-- Midnight calls the overloadable nodes Infused. A name that starts with
-- an allowPrefixes word can be overloaded. A name that starts with a
-- denyPrefixes word cannot, even when it also looks Infused. Skinning is
-- listed under `skipped` and has no spell. Charges come from
-- C_Spell.GetSpellCharges: one charge, a 12-hour recharge, and a second
-- charge once the profession has secondAtPoints. All of this is unverified.
--
-- `nodes` is an optional exact list (name or object id). The prefix rules
-- apply when that list does not name the object.
TA.Data.Overloads = {
    unverified = true,
    family = "Infused",
    charges = { base = 1, rechargeHours = 12, secondAtPoints = 40 },
    allowPrefixes = { "Lightfused", "Primal", "Voidbound", "Wild" },
    denyPrefixes = { "Lush", "Transplanted", "Rich" },
    spells = {
        { profession = 182, name = "Herbalism", spellID = 1223014 },
        { profession = 186, name = "Mining",    spellID = 1225392 },
    },
    skipped = {
        { profession = 393, name = "Skinning" },
    },
    -- { name = "<node name>", objectID = <id>, profession = <skill line>, spellID = <optional> }
    nodes = {},
}
