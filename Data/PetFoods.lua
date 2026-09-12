-- ToonAge/Data/PetFoods.lua (Anniversary — TBC Classic / Interface 20506)
--
-- Curated lookup of common Classic/TBC pet-food items by diet category, used
-- by Modules/Character/PetCare.lua to auto-select what to feed. Diet strings
-- must match exactly what GetPetFoodTypes() returns for the active pet
-- ("Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus").
--
-- NOTE: hand-curated from well-known leveling-era drops and vendor foods —
-- not exhaustive. Tameable-pet zones add new food sources constantly and
-- this list will miss some; add entries here as gaps turn up in play.
--
-- tier: 0 = conjured (mage-made, free — fed first when present)
--       1 = basic (restores happiness only)
--       2 = "Well Fed" quality (bonus buff on the player too; still valid
--           pet food, and fed ahead of a plain tier-1 of the same diet
--           since it's strictly better value for the same bag slot)

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.PetFoods = {}
local F = TA.Data.PetFoods

-- ─── Food Database ──────────────────────────────────────────────────────

F.ITEMS = {
    -- Conjured (top priority whenever present)
    ["Conjured Bread"] = { diet = "Bread", tier = 0 },

    -- Meat
    ["Haunch of Meat"] = { diet = "Meat", tier = 1 },
    ["Chunk of Boar Meat"] = { diet = "Meat", tier = 1 },
    ["Stringy Wolf Meat"] = { diet = "Meat", tier = 1 },
    ["Tender Wolf Meat"] = { diet = "Meat", tier = 1 },
    ["Big Bear Haunch"] = { diet = "Meat", tier = 1 },
    ["Small Spider Leg"] = { diet = "Meat", tier = 1 },
    ["Lean Wolf Flank"] = { diet = "Meat", tier = 1 },
    ["Roasted Boar Meat"] = { diet = "Meat", tier = 2 },
    ["Cured Ham Steak"] = { diet = "Meat", tier = 2 },
    ["Smoked Bear Meat"] = { diet = "Meat", tier = 2 },

    -- Fish
    ["Raw Brilliant Smallfish"] = { diet = "Fish", tier = 1 },
    ["Raw Longjaw Mud Snapper"] = { diet = "Fish", tier = 1 },
    ["Raw Bristle Whisker Catfish"] = { diet = "Fish", tier = 1 },
    ["Raw Loch Frenzy"] = { diet = "Fish", tier = 1 },
    ["Raw Rockscale Cod"] = { diet = "Fish", tier = 1 },
    ["Rockscale Cod"] = { diet = "Fish", tier = 2 },
    ["Poached Sunscale Salmon"] = { diet = "Fish", tier = 2 },

    -- Bread
    ["Tough Hunk of Bread"] = { diet = "Bread", tier = 1 },
    ["Freshly Baked Bread"] = { diet = "Bread", tier = 1 },
    ["Moist Cornbread"] = { diet = "Bread", tier = 1 },

    -- Cheese
    ["Cheese Wheel"] = { diet = "Cheese", tier = 1 },
    ["Dwarven Mild"] = { diet = "Cheese", tier = 1 },
    ["Alterac Swiss"] = { diet = "Cheese", tier = 1 },

    -- Fruit
    ["Shiny Red Apple"] = { diet = "Fruit", tier = 1 },
    ["Snapvine Watermelon"] = { diet = "Fruit", tier = 1 },
    ["Goldenbark Apple"] = { diet = "Fruit", tier = 1 },
    ["Mightberry"] = { diet = "Fruit", tier = 1 },

    -- Fungus
    ["Spongy Morel"] = { diet = "Fungus", tier = 1 },
    ["Raw Black Truffle"] = { diet = "Fungus", tier = 1 },
}

-- ─── Lookups ──────────────────────────────────────────────────────────────

--- @return table|nil  { diet, tier } for a known food item name, or nil.
function F:Get(itemName)
    return itemName and self.ITEMS[itemName]
end
