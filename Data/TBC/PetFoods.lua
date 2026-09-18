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
-- Rebuilt 2026-09-16. Pets won't eat food 30 or more levels below them, and
-- food at or above the pet's level gives the most happiness (Petopia feeding
-- FAQ; Wowhead TBC Feed Pet tooltip: "Using food close to the pet's level will
-- have a better result"). The old list was all pre-Outland food with no level
-- data, so a level-70 hunter was offered food their pet would refuse.
--
-- level: the food's level (= required level for players). The standard vendor
--        food ladders below (5/15/25/35/45/55/65) are exact. nil = a drop or
--        cooked item whose level is not recorded here; used only when nothing
--        with a known level fits.
-- conjured: mage food. Ranked last — whether pets accept conjured food is not
--        verified on this client, so it is never preferred over real food.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.PetFoods = {}
local F = TA.Data.PetFoods

local function ladder(diet, names)
    local levels = { 5, 15, 25, 35, 45, 55, 65 }
    for i, name in ipairs(names) do
        if name then F.ITEMS[name] = { diet = diet, level = levels[i] } end
    end
end

F.ITEMS = {}

-- Standard vendor foods, levels 5 → 65 (Outland vendors sell the 65 tier).
ladder("Meat",   { "Tough Jerky", "Haunch of Meat", "Mutton Chop", "Wild Hog Shank", "Cured Ham Steak", "Roasted Quail", "Smoked Talbuk Venison" })
ladder("Bread",  { "Tough Hunk of Bread", "Freshly Baked Bread", "Moist Cornbread", "Mulgore Spice Bread", "Soft Banana Bread", "Homemade Cherry Pie", "Mag'har Grainbread" })
ladder("Cheese", { "Darnassian Bleu", "Dalaran Sharp", "Dwarven Mild", "Stormwind Brie", "Fine Aged Cheddar", "Alterac Swiss", "Garadar Sharp" })
ladder("Fruit",  { "Shiny Red Apple", "Tel'Abim Banana", "Snapvine Watermelon", "Goldenbark Apple", "Moon Harvest Pumpkin", "Deep Fried Plantains", "Telaari Grapes" })
ladder("Fungus", { "Forest Mushroom Cap", "Red-speckled Mushroom", "Spongy Morel", "Delicious Cave Mold", "Raw Black Truffle", "Dried King Bolete", "Zangar Caps" })
ladder("Fish",   { "Slitherskin Mackerel", "Longjaw Mud Snapper", "Bristle Whisker Catfish", "Rockscale Cod", "Striped Yellowtail", "Spinefin Halibut", "Sunspring Carp" })

-- Common drops / cooked food without a recorded level.
for name, diet in pairs({
    ["Chunk of Boar Meat"] = "Meat", ["Stringy Wolf Meat"] = "Meat", ["Tender Wolf Meat"] = "Meat",
    ["Big Bear Haunch"] = "Meat", ["Small Spider Leg"] = "Meat", ["Lean Wolf Flank"] = "Meat",
    ["Roasted Boar Meat"] = "Meat", ["Smoked Bear Meat"] = "Meat",
    ["Clefthoof Meat"] = "Meat", ["Talbuk Venison"] = "Meat", ["Buzzard Meat"] = "Meat", ["Raptor Ribs"] = "Meat",
    ["Raw Brilliant Smallfish"] = "Fish", ["Raw Longjaw Mud Snapper"] = "Fish",
    ["Raw Bristle Whisker Catfish"] = "Fish", ["Raw Loch Frenzy"] = "Fish", ["Raw Rockscale Cod"] = "Fish",
    ["Poached Sunscale Salmon"] = "Fish",
    ["Mightberry"] = "Fruit",
}) do
    if not F.ITEMS[name] then F.ITEMS[name] = { diet = diet } end
end

F.ITEMS["Conjured Bread"] = { diet = "Bread", conjured = true }

function F:Get(itemName)
    return itemName and self.ITEMS[itemName]
end

--- Food a pet of `petLevel` will actually eat (not 30+ levels below it).
function F:IsEdible(entry, petLevel)
    if not entry then return false end
    if not entry.level or not petLevel then return true end
    return entry.level > petLevel - 30
end

--- Sort key: lower is better.
---   1  known level, at or above the pet's level (full value) — cheapest first
---   2  known level, below the pet's level but still edible — highest first
---   3  unknown level
---   4  conjured
function F:Rank(entry, petLevel)
    if entry.conjured then return 4, 0 end
    if not entry.level or not petLevel then return 3, 0 end
    if entry.level >= petLevel then return 1, entry.level end
    return 2, -entry.level
end
