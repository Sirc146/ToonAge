-- ToonAge/Data/Professions.lua
-- Profession talent trees, gear slots, quality thresholds (Midnight 12.0.5)
--
-- EXPANSION HISTORY:
--   Pre-Dragonflight:  No specialization trees. Linear skill bar only.
--   Dragonflight (10.x): First introduction of specialization trees, profession
--                         gear (tool + 2 accessories), crafting stats (Resourcefulness,
--                         Inspiration, Multicraft, Crafting Speed). KP system.
--   The War Within (11.x): Refined DF system. Same stat names, updated trees.
--                           Specializations remained core. Some professions got
--                           rebalanced paths.
--   Midnight (12.x): Further specialization evolution. New trees (Engineering 4-tree).
--                    Expansion-specific path names (e.g. Alchemy: "Potion Prowess"
--                    instead of "Potion Mastery"). Same gear/stat framework.
--
-- The addon detects which expansion tier a profession is using based on the
-- profession's recipe context (C_TradeSkillUI expansion info) and displays
-- terminology appropriate to that tier.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Professions = {}
local P = TA.Data.Professions

-- ── Expansion era definitions ──────────────────────────────────────────
-- Used to determine which UI/terminology to show.
-- hasSpecializations: whether this era has talent trees (Dragonflight+)
-- hasGear: whether profession gear slots exist (Dragonflight+)
-- hasCraftingStats: whether Resourcefulness/Inspiration/etc exist (Dragonflight+)
-- specUnlock: profession skill level where specializations become available
-- charLevelReq: character level needed to learn ANY profession tier (all = 5)
-- zoneAccessLevel: minimum character level to enter the expansion's zones
P.EXPANSION_ERAS = {
    Classic = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Classic",
        maxSkill = 300,
        charLevelReq = 5,
        zoneAccessLevel = 1,
        note = "All zones scale; recipes from vendors and world drops",
    },
    TBC = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Burning Crusade",
        maxSkill = 75,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Portal to Outland; recipes from vendors, world drops, rep vendors",
    },
    Wrath = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Wrath of the Lich King",
        maxSkill = 75,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Boat/zeppelin to Northrend; rep vendor recipes (Sons of Hodir, etc.)",
    },
    Cataclysm = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Cataclysm",
        maxSkill = 75,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Hyjal/Vashj'ir entry; vendors + world drops",
    },
    Pandaria = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Mists of Pandaria",
        maxSkill = 75,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Portal to Jade Forest; rep vendor recipes (Shado-Pan, etc.)",
    },
    Draenor = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Warlords of Draenor",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Garrison buildings unlock profession recipes",
    },
    Legion = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Legion",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Profession questlines in Broken Isles; dungeon/raid recipe drops",
    },
    BFA = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Battle for Azeroth",
        maxSkill = 150,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Kul Tiras/Zandalar; faction-specific recipes",
    },
    Shadowlands = {
        hasSpecializations = false,
        hasGear = false,
        hasCraftingStats = false,
        label = "Shadowlands",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 10,
        note = "Oribos; covenant-tied crafting",
    },
    Dragonflight = {
        hasSpecializations = true,
        hasGear = true,
        hasCraftingStats = true,
        label = "Dragonflight",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 60,
        specUnlock = 25,
        note = "Crafting stations required; knowledge from treasures, renown, first-crafts",
    },
    TheWarWithin = {
        hasSpecializations = true,
        hasGear = true,
        hasCraftingStats = true,
        label = "The War Within",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 70,
        specUnlock = 25,
        note = "Isle of Dorn; new profession gear tiers; new knowledge sources",
    },
    Midnight = {
        hasSpecializations = true,
        hasGear = true,
        hasCraftingStats = true,
        label = "Midnight",
        maxSkill = 100,
        charLevelReq = 5,
        zoneAccessLevel = 70,
        specUnlock = 25,
        note = "Quel'Thalas; void-touched crafting systems; new spec trees",
    },
}

-- ── Skill milestones (Dragonflight+ specialization system) ─────────────
-- These are universal across all DF/TWW/Midnight professions.
P.SPEC_MILESTONES = {
    { skill = 1, label = "Learn profession + equip gear + gather knowledge items" },
    { skill = 25, label = "Specializations unlock — first talent tree opens, begin investing KP" },
    { skill = 50, label = "Second specialization branch unlocks — advanced recipes + gear upgrades" },
    { skill = 75, label = "Third branch unlocks — high-end recipes, rare crafts, high-tier gear" },
    { skill = 100, label = "Max tier — all branches open, maximum crafting quality potential" },
}

-- ── Crafting stat definitions (Dragonflight+) ──────────────────────────
-- These stats only exist on profession gear from Dragonflight onward.
P.CRAFTING_STATS = {
    Resourcefulness = { desc = "Chance to use fewer materials when crafting", icon = 4549478 },
    Inspiration = { desc = "Chance to craft at a higher quality than expected", icon = 4549477 },
    Multicraft = { desc = "Chance to craft additional items", icon = 4549476 },
    CraftingSpeed = { desc = "Reduces time to craft items", icon = 4549475 },
    -- Gathering-specific stats (same era):
    Deftness = { desc = "Faster gathering speed", icon = 4549474 },
    Finesse = { desc = "Chance to gather more materials", icon = 4549473 },
    Perception = { desc = "Chance to find rare materials while gathering", icon = 4549472 },
}

--- Returns the expansion era for a given profession context.
--- Uses C_TradeSkillUI if available; falls back to "Midnight" for current content.
function P:GetExpansionEra(skillLineID)
    -- If the API can tell us which expansion this profession belongs to, use it.
    -- Otherwise default to Midnight (current expansion).
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
        if ok and info and info.expansionName then
            -- Map API expansion name to our era key
            local nameMap = {
                ["Dragonflight"] = "Dragonflight",
                ["The War Within"] = "TheWarWithin",
                ["Midnight"] = "Midnight",
            }
            local era = nameMap[info.expansionName]
            if era then
                return era
            end
        end
    end
    return "Midnight"
end

--- Returns whether the given expansion era supports specialization trees.
function P:EraHasSpecializations(era)
    local e = self.EXPANSION_ERAS[era]
    return e and e.hasSpecializations or false
end

--- Returns whether the given expansion era supports profession gear.
function P:EraHasGear(era)
    local e = self.EXPANSION_ERAS[era]
    return e and e.hasGear or false
end

-- ── Profession gear slot IDs ───────────────────────────────────────────
-- In Dragonflight+, profession gear uses dedicated equip slots
-- These are read via GetInventoryItemID with the prof-specific slot indices
P.GEAR_SLOTS = {
    tool = "PROFESSION_TOOL_SLOT", -- Slot 0 per profession context
    accessory1 = "PROFESSION_ACCESSORY_SLOT1",
    accessory2 = "PROFESSION_ACCESSORY_SLOT2",
}

-- ── Quality thresholds ─────────────────────────────────────────────────
-- Format: { skill=number, label=string, personalBenefit=string }
-- skill = effective skill needed (base + gear bonus)

-- ── Herbalism ─────────────────────────────────────────────────────────
P[182] = { -- skillLine ID for Herbalism
    name = "Herbalism",
    type = "gathering",
    icon = 136246,
    maxSkill = 100,
    firstPath = "Bountiful Harvest",
    firstPathReason = "Maximises herb yield per node while leveling — more mats = faster skill gain. Swap to Finesse branch at skill 75 for rare herb proc chance.",
    personalBenefit = "Gather Duskbloom and Voidpetal — core materials for healing flasks that increase HPS by ~8%. Free consumables every week.",

    gearSlots = {
        tool = {
            name = "Herb Gathering Tool",
            recommended = "Midnight Herbalist's Sickle",
            bonuses = "+15 Herbalism skill, +10 Deftness",
            source = "Crafted (Blacksmithing 50) or AH",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Herbalism Accessory 1",
            recommended = "Herbalist's Gathering Gloves",
            bonuses = "+8 Deftness",
            source = "Crafted (Leatherworking 25) or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Herbalism Accessory 2",
            recommended = "Verdant Gathering Charm",
            bonuses = "+8 Finesse",
            source = "Crafted (Jewelcrafting 25) or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Common herbs (Rank 1)", benefit = "Gather basic Midnight herbs" },
        { skill = 25, rank = 2, label = "Rank 2 herbs (improved yield)", benefit = "More herbs per node" },
        {
            skill = 50,
            rank = 3,
            label = "Rank 3 herbs (craft mats)",
            benefit = "Gather rare-quality herbs for potions",
        },
        {
            skill = 75,
            rank = 4,
            label = "Voidpetal — healing flask mat",
            benefit = "Flask of Midnight Clarity material",
        },
        {
            skill = 100,
            rank = 5,
            label = "Prismatic Nightbloom (rare)",
            benefit = "Best herb — requires Finesse stat",
        },
    },

    talentTree = {
        -- ⚠ PERMANENT — cannot be reset. Plan before spending KP.
        -- KP sources: first-craft bonus (1 KP each new recipe), open-world treasures, weekly quests
        archetypes = {
            {
                archetype = "mastery",
                name = "Botany",
                kpRequired = 1,
                desc = "General Mastery tree (far left) — global +Skill across all herbs. Milestone at 40 KP: MOUNTED GATHERING unlocked (harvest without dismounting — changes farming entirely)",
                recommended = true,
                firstPick = true,
            },
            {
                archetype = "spec",
                name = "Bountiful Harvest",
                kpRequired = 1,
                desc = "End-Item Spec — maximises herb yield per node. Primary stat: Finesse (+baseline herbs per gather). Take first while leveling skill.",
                recommended = true,
                firstPick = true,
            },
            {
                archetype = "utility",
                name = "Deftness",
                kpRequired = 10,
                desc = "Quality-of-Life — faster gather animation (Deftness stat). Critical for avoiding open-world aggro and farming efficiency.",
                recommended = false,
            },
            {
                archetype = "market",
                name = "Rare Seeker / Perception",
                kpRequired = 75,
                desc = "Market Efficiency — Perception stat scales chance to find ultra-rare herbs (Null Lotus, rare elementals). Take at skill 75.",
                recommended = true,
                swapAt = 75,
            },
        },
        permanenceWarning = "⚠ Profession talent choices are PERMANENT — unlike combat talents, KP cannot be refunded. Botany (mounted gathering at 40 KP) is the highest-value milestone. Prioritize it before branching.",
        rows = {
            {
                {
                    name = "Botany (General Mastery)",
                    desc = "+Skill all herbs · 40 KP = Mounted Gathering",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "mastery",
                },
                {
                    name = "Bountiful Harvest",
                    desc = "Finesse: +herbs per node",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "spec",
                },
                {
                    name = "Deftness Track",
                    desc = "Deftness: faster animation",
                    recommended = false,
                    skillReq = 10,
                    firstPick = false,
                    archetype = "utility",
                },
            },
            {
                {
                    name = "Verdant Bounty",
                    desc = "+1 herb on Finesse proc",
                    recommended = true,
                    skillReq = 1,
                    archetype = "spec",
                },
                {
                    name = "Swift Gathering",
                    desc = "Deftness +15 — near-instant picks",
                    recommended = false,
                    skillReq = 25,
                    archetype = "utility",
                },
                {
                    name = "Perception Nodes",
                    desc = "Perception: rare herb discovery",
                    recommended = false,
                    skillReq = 25,
                    archetype = "market",
                },
            },
            {
                {
                    name = "Plentiful Yield",
                    desc = "+2 herbs on proc (Finesse)",
                    recommended = true,
                    skillReq = 50,
                    archetype = "spec",
                },
                {
                    name = "Fleet of Foot",
                    desc = "+8% move speed between nodes",
                    recommended = false,
                    skillReq = 50,
                    archetype = "utility",
                },
                {
                    name = "Rare Seeker",
                    desc = "Perception doubles rare chance",
                    recommended = true,
                    skillReq = 75,
                    archetype = "market",
                    swapNote = "Priority at skill 75",
                },
            },
            {
                {
                    name = "Master Botanist",
                    desc = "Capstone: all yields +25%",
                    recommended = true,
                    skillReq = 100,
                    isCapstone = true,
                    archetype = "mastery",
                },
                {
                    name = "Nightbloom Whisperer",
                    desc = "Prismatic proc (Perception)",
                    recommended = true,
                    skillReq = 100,
                    isCapstone = true,
                    archetype = "market",
                },
            },
        },
    },
}

-- ── Skinning ──────────────────────────────────────────────────────────
P[393] = { -- skillLine ID for Skinning
    name = "Skinning",
    type = "gathering",
    icon = 134366,
    maxSkill = 100,
    firstPath = "Bountiful Harvest",
    firstPathReason = "More leather per kill while leveling. At skill 50 invest in Finesse for rare hide procs that enable craftable gear upgrades.",
    personalBenefit = "Gather Midnight Dragonhide — used in crafted mail armor upgrades directly relevant to Preservation. Effective skill 60 with BIS profession gear unlocks Rank 3 hides immediately.",

    gearSlots = {
        tool = {
            name = "Skinning Knife",
            recommended = "Midnight Skinner's Blade",
            bonuses = "+15 Skinning skill, +10 Bountiful Harvest",
            source = "Crafted (Blacksmithing 50) or AH",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Skinning Accessory 1",
            recommended = "Skinner's Grips",
            bonuses = "+8 Bountiful Harvest",
            source = "Crafted (Leatherworking 25) or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Skinning Accessory 2",
            recommended = "Beast Tracker's Charm",
            bonuses = "+8 Finesse",
            source = "Crafted (Jewelcrafting 25) or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Common leather", benefit = "Basic crafting material" },
        { skill = 25, rank = 2, label = "Rank 2 leather (improved)", benefit = "Better yield per beast" },
        { skill = 50, rank = 3, label = "Midnight Dragonhide", benefit = "Craft mail armor upgrade mats" },
        { skill = 75, rank = 4, label = "Rare hides", benefit = "High-quality gear crafting material" },
        {
            skill = 100,
            rank = 5,
            label = "Prismatic Scale (best mat)",
            benefit = "Requires Finesse — top craft material",
        },
    },

    talentTree = {
        permanenceWarning = "⚠ PERMANENT — KP cannot be refunded. Skinning has no mounted-gathering milestone but Deftness (speed) is essential for farming efficiently.",
        rows = {
            {
                {
                    name = "Skinning Mastery",
                    desc = "General Mastery: +Skill all leather",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "mastery",
                },
                {
                    name = "Bountiful Harvest",
                    desc = "Finesse: +leather per skin",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "spec",
                },
                {
                    name = "Swift Skinner",
                    desc = "Deftness: faster skin animation",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                    archetype = "utility",
                },
            },
            {
                {
                    name = "Plentiful Hides",
                    desc = "+1 leather on Finesse proc",
                    recommended = true,
                    skillReq = 1,
                    archetype = "spec",
                },
                {
                    name = "Beast Tracking",
                    desc = "Skinnable beasts shown on minimap",
                    recommended = false,
                    skillReq = 25,
                    archetype = "utility",
                },
                {
                    name = "Perception Track",
                    desc = "Perception: rare hide discovery",
                    recommended = false,
                    skillReq = 25,
                    archetype = "market",
                },
            },
            {
                {
                    name = "Dragonhide Mastery",
                    desc = "Midnight Dragonhide +50% yield",
                    recommended = true,
                    skillReq = 50,
                    archetype = "spec",
                },
                {
                    name = "Efficient Cuts",
                    desc = "Deftness on tagged-beast nodes",
                    recommended = false,
                    skillReq = 50,
                    archetype = "utility",
                },
                {
                    name = "Rare Hide Seeker",
                    desc = "Perception doubles rare hide chance",
                    recommended = true,
                    skillReq = 75,
                    archetype = "market",
                    swapNote = "Priority at skill 75",
                },
            },
            {
                {
                    name = "Master Skinner",
                    desc = "Capstone: all yields +25%",
                    recommended = true,
                    skillReq = 100,
                    isCapstone = true,
                    archetype = "mastery",
                },
                {
                    name = "Prismatic Scale Hunter",
                    desc = "Prismatic Scale proc (Perception)",
                    recommended = true,
                    skillReq = 100,
                    isCapstone = true,
                    archetype = "market",
                },
            },
        },
    },
}

-- ── Alchemy ───────────────────────────────────────────────────────────
P[171] = {
    name = "Alchemy",
    type = "crafting",
    icon = 136240,
    maxSkill = 100,
    expansion = "Midnight", -- expansion context for terminology
    firstPath = "Potion Prowess",
    firstPathReason = "Leverages Light/Void synergy for potions — double-proc on healing pots used in combat. Immediate HPS gain. Swap to Fluent in Flasks at skill 50 for permanent stat buffs.",
    personalBenefit = "Craft Elixir of the Preservation (+8% HPS) and Flask of Midnight Clarity (+Mastery) for free. Never buy consumables again.",

    -- Where recipes come from in each expansion era
    recipeSources = {
        Classic = { "Vendors", "World drops", "Dungeon/raid drops" },
        TBC = { "Vendors", "World drops", "Reputation vendors" },
        Wrath = { "Vendors", "World drops", "Reputation vendors" },
        Cataclysm = { "Vendors", "World drops", "Reputation vendors" },
        Pandaria = { "Vendors", "World drops", "Reputation vendors" },
        Draenor = { "Vendors", "Garrison buildings" },
        Legion = { "Vendors", "Profession questlines", "Dungeon/raid drops" },
        BFA = { "Vendors", "World drops", "Reputation vendors" },
        Shadowlands = { "Vendors", "World drops" },
        Dragonflight = {
            "Vendors",
            "Renown",
            "Profession treasures",
            "Work orders",
            "Dungeon/raid drops",
            "Transmute unlocks",
        },
        TheWarWithin = { "Vendors", "Renown", "Profession treasures", "Work orders", "Dungeon/raid drops" },
        Midnight = {
            "Vendors",
            "Renown",
            "Profession treasures",
            "Work orders",
            "Dungeon/raid drops",
            "Transmute unlocks",
        },
    },

    -- Expansion-specific terminology mapping
    -- Each expansion renamed the profession specialization paths differently.
    -- This ensures the addon displays the CORRECT names for the active expansion.
    expansionTerms = {
        Midnight = {
            kpName = "Knowledge Points",
            specPaths = { "Potion Prowess", "Fluent in Flasks", "Alchemical Mastery", "Transmutation Authority" },
            statNames = {
                resourcefulness = "Resourcefulness",
                inspiration = "Inspiration",
                multicraft = "Multicraft",
                craftingSpeed = "Crafting Speed",
            },
            slotLabel = "Profession Tool / Accessories",
        },
        TheWarWithin = {
            kpName = "Knowledge Points",
            specPaths = { "Potion Mastery", "Phial Mastery", "Alchemical Theory", "Transmutation" },
            statNames = {
                resourcefulness = "Resourcefulness",
                inspiration = "Inspiration",
                multicraft = "Multicraft",
                craftingSpeed = "Crafting Speed",
            },
            slotLabel = "Profession Tool / Accessories",
        },
        Dragonflight = {
            kpName = "Knowledge Points",
            specPaths = { "Potion Mastery", "Phial Mastery", "Alchemist's Expertise", "Transmutation" },
            statNames = {
                resourcefulness = "Resourcefulness",
                inspiration = "Inspiration",
                multicraft = "Multicraft",
                craftingSpeed = "Crafting Speed",
            },
            slotLabel = "Profession Tool / Accessories",
        },
    },

    gearSlots = {
        tool = {
            name = "Alchemist's Tool",
            recommended = "Midnight Alchemist's Stone",
            bonuses = "+15 Alchemy, +10 Resourcefulness",
            source = "Crafted (Alchemy 50)",
            skillBonus = 15,
            bestForPath = "Potion Prowess",
        },
        accessory1 = {
            name = "Alchemy Accessory 1",
            recommended = "Vial Harness",
            bonuses = "+8 Inspiration",
            source = "Crafted or AH",
            skillBonus = 8,
            bestForPath = "Fluent in Flasks",
        },
        accessory2 = {
            name = "Alchemy Accessory 2",
            recommended = "Transmutation Focus",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
            bestForPath = "Potion Prowess",
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 potions/flasks", benefit = "Basic healing and mana potions" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger potions, higher proc chance" },
        { skill = 50, rank = 3, label = "Flasks — personal stat", benefit = "Flask of Midnight Clarity (+Mastery)" },
        {
            skill = 75,
            rank = 4,
            label = "Elixir of Preservation",
            benefit = "+8% HPS — best healer flask in Midnight",
        },
        { skill = 100, rank = 5, label = "Cauldron crafting", benefit = "Raid cauldron for entire group" },
    },

    talentTree = {
        permanenceWarning = "⚠ PERMANENT — Knowledge Points cannot be refunded. Potion Prowess early → Fluent in Flasks at 50 is the standard progression for raiders.",
        rows = {
            {
                {
                    name = "Potion Prowess",
                    desc = "Light/Void potency — double-proc healing pots",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "spec",
                },
                {
                    name = "Transmutation Authority",
                    desc = "Convert materials at enhanced rates",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                    archetype = "market",
                },
                {
                    name = "Fluent in Flasks",
                    desc = "Higher quality flask output + extended duration",
                    recommended = false,
                    skillReq = 10,
                    firstPick = false,
                    archetype = "spec",
                    swapAt = 50,
                },
            },
            {
                {
                    name = "Alchemical Mastery",
                    desc = "Proc chance +15% on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                    archetype = "mastery",
                },
                {
                    name = "Efficient Mixing",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                    archetype = "utility",
                },
                {
                    name = "Inspired Flask",
                    desc = "Inspiration: chance to craft rank 3 flasks",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                    archetype = "spec",
                },
            },
            {
                {
                    name = "Midnight Formulas",
                    desc = "Unlocks Elixir of Preservation recipe",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                    archetype = "spec",
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                    archetype = "utility",
                },
                {
                    name = "Extended Duration",
                    desc = "+30 min to all flask durations",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                    archetype = "utility",
                },
            },
            {
                {
                    name = "Grand Alchemist",
                    desc = "Capstone: all potions/flasks rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                    archetype = "mastery",
                },
                {
                    name = "Raid Cauldron",
                    desc = "Craft group cauldron for 10+ players",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                    archetype = "spec",
                },
            },
        },
    },
}

-- ── Enchanting ────────────────────────────────────────────────────────
P[333] = {
    name = "Enchanting",
    type = "crafting",
    icon = 136244,
    maxSkill = 100,
    firstPath = "Weapon Mastery",
    firstPathReason = "Unlocks highest-tier weapon enchants for healers first — Mastery of the Dreamer is your best weapon enchant. Free self-enchanting saves gold every tier.",
    personalBenefit = "Enchant your own weapon (Mastery of the Dreamer), rings (+200 Mastery each), and armor. Never pay AH prices. Disenchant unwanted drops for mats.",

    gearSlots = {
        tool = {
            name = "Enchanting Rod",
            recommended = "Midnight Void Rod",
            bonuses = "+15 Enchanting, +10 Inspiration",
            source = "Crafted (Enchanting 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Enchanting Accessory 1",
            recommended = "Runescribed Gloves",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Enchanting Accessory 2",
            recommended = "Disenchanter's Lens",
            bonuses = "+8 Finesse",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Basic enchants", benefit = "Simple stat enchants for any slot" },
        { skill = 25, rank = 2, label = "Ring enchants", benefit = "+Mastery on both rings — ~200 stat free" },
        {
            skill = 50,
            rank = 3,
            label = "Weapon enchants",
            benefit = "Mastery of the Dreamer — best healer weapon enchant",
        },
        { skill = 75, rank = 4, label = "Rank 2 weapon enchants", benefit = "Higher proc chance and stat value" },
        {
            skill = 100,
            rank = 5,
            label = "Rank 3 — Prismatic enchant",
            benefit = "Best-in-slot enchant for all slots",
        },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Weapon Mastery",
                    desc = "Unlocks healer weapon enchants first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Armor Mastery",
                    desc = "Unlocks chest/legs enchants",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Jewel Mastery",
                    desc = "Unlocks ring/neck enchants",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Inspired Runing",
                    desc = "+15% chance to proc higher rank",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Disenchanting",
                    desc = "More mats from disenchanting",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Careful Inscription",
                    desc = "Reduces quality variance",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Mastery of the Dreamer",
                    desc = "Unlocks best healer weapon enchant",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "Chance to refund enchanting mats",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Extended Imbue",
                    desc = "+1 hour to all enchant proc durations",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Enchanter",
                    desc = "Capstone: all enchants are rank 3",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Rune",
                    desc = "Craft Prismatic enchants (+all stats)",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Mining ────────────────────────────────────────────────────────────
P[186] = { -- skillLine ID for Mining
    name = "Mining",
    type = "gathering",
    icon = 136243,
    maxSkill = 100,
    firstPath = "Bountiful Harvest",
    firstPathReason = "More ore per node while leveling — faster skill gain. Swap to Finesse branch at skill 75 for rare metal procs (Midnight Voidore).",
    personalBenefit = "Gather Midnight Ironore and Voidore — materials for Blacksmithing gear upgrades and Engineering gadgets. Ore sells well on AH.",

    gearSlots = {
        tool = {
            name = "Mining Pick",
            recommended = "Midnight Miner's Pick",
            bonuses = "+15 Mining skill, +10 Bountiful Harvest",
            source = "Crafted (Blacksmithing 50) or AH",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Mining Accessory 1",
            recommended = "Miner's Sturdy Gloves",
            bonuses = "+8 Bountiful Harvest",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Mining Accessory 2",
            recommended = "Vein Tracker's Charm",
            bonuses = "+8 Finesse",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Common ore (basic mats)", benefit = "Midnight Ironore for Blacksmithing" },
        { skill = 25, rank = 2, label = "Rank 2 ore (improved yield)", benefit = "More ore per node" },
        { skill = 50, rank = 3, label = "Midnight Voidore (rare metal)", benefit = "Used in epic Blacksmithing gear" },
        {
            skill = 75,
            rank = 4,
            label = "Elementium veins (bonus mats)",
            benefit = "Bonus procs when mining void nodes",
        },
        {
            skill = 100,
            rank = 5,
            label = "Prismatic Shard (rare proc)",
            benefit = "Best crafting metal — requires Finesse",
        },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Bountiful Harvest",
                    desc = "+1 ore per node",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Deep Seeker",
                    desc = "Find ore nodes more easily",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Finesse",
                    desc = "Rare metal proc chance",
                    recommended = false,
                    skillReq = 10,
                    firstPick = false,
                    swapAt = 75,
                },
            },
            {
                {
                    name = "Plentiful Veins",
                    desc = "+1 ore on large vein nodes",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Swift Strikes",
                    desc = "Faster mining animation",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Careful Extraction",
                    desc = "Reduces failed mining attempts",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Voidore Mastery",
                    desc = "Midnight Voidore yield +50%",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Efficient Mining",
                    desc = "Mine faster on tagged nodes",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Rare Vein Seeker",
                    desc = "Doubles rare metal chance",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                    swapNote = "Take at skill 75",
                },
            },
            {
                {
                    name = "Master Miner",
                    desc = "Capstone: all yields +25%",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Seeker",
                    desc = "Prismatic Shard proc chance",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Leatherworking ────────────────────────────────────────────────────
P[165] = {
    name = "Leatherworking",
    type = "crafting",
    icon = 4620678,
    maxSkill = 100,
    firstPath = "Leathercrafting",
    firstPathReason = "Unlocks leather and mail armor recipes first — matches Skinning output directly, so no wasted mats while leveling both together.",
    personalBenefit = "Craft your own leather and mail armor upgrades directly from Skinning drops — including Midnight Dragonhide gear. Pairs naturally with a Skinning gathering profession.",

    gearSlots = {
        tool = {
            name = "Leatherworking Tools",
            recommended = "Midnight Tanning Kit",
            bonuses = "+15 Leatherworking, +10 Multicraft",
            source = "Crafted (Leatherworking 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Leatherworking Accessory 1",
            recommended = "Tanner's Apron",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Leatherworking Accessory 2",
            recommended = "Stitching Awl",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 leather/mail", benefit = "Basic leather and mail armor recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger armor, higher stat budget" },
        {
            skill = 50,
            rank = 3,
            label = "Midnight Dragonhide gear",
            benefit = "Epic-track leather/mail using Dragonhide",
        },
        {
            skill = 75,
            rank = 4,
            label = "Armor kit upgrades",
            benefit = "Craftable armor kits for extra stats on any gear",
        },
        { skill = 100, rank = 5, label = "Prismatic-tier gear", benefit = "Best-in-slot craftable leather and mail" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Leathercrafting",
                    desc = "Unlocks leather armor recipes first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Mailcrafting",
                    desc = "Unlocks mail armor recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                    swapAt = 50,
                },
                {
                    name = "Kitcrafting",
                    desc = "Unlocks armor kit (stat enhancement) recipes",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Tanning Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Tanning",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Reinforced Stitching",
                    desc = "Chance to craft rank 3 armor directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Dragonhide Crafting",
                    desc = "Unlocks Midnight Dragonhide gear recipes",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Kit Mastery",
                    desc = "Armor kits grant +50% more stats",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Leatherworker",
                    desc = "Capstone: all leather/mail rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Tannery",
                    desc = "Craft Prismatic-tier leather and mail",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Blacksmithing ─────────────────────────────────────────────────────
P[164] = {
    name = "Blacksmithing",
    type = "crafting",
    icon = 4620670,
    maxSkill = 100,
    firstPath = "Weaponsmithing",
    firstPathReason = "Unlocks two-hand and plate weapon recipes first — best early damage upgrades for plate/weapon-dependent classes. Swap toward Armorsmithing at skill 50 once weapon BiS is covered.",
    personalBenefit = "Craft your own plate armor pieces and weapon upgrades — including profession tools other crafters and gatherers need (Miner's Pick, Skinner's Blade). Never buy plate gear from the AH.",

    gearSlots = {
        tool = {
            name = "Blacksmith's Hammer",
            recommended = "Midnight Forgehammer",
            bonuses = "+15 Blacksmithing, +10 Resourcefulness",
            source = "Crafted (Blacksmithing 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Blacksmithing Accessory 1",
            recommended = "Forge Apron",
            bonuses = "+8 Multicraft",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Blacksmithing Accessory 2",
            recommended = "Tempering Tongs",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 plate/weapons", benefit = "Basic plate armor and weapon recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger plate pieces, higher stat budget" },
        { skill = 50, rank = 3, label = "Midnight Voidore gear", benefit = "Epic-track plate armor using Voidore" },
        {
            skill = 75,
            rank = 4,
            label = "Weapon enchant sockets",
            benefit = "Sockets craftable into weapons for gem slots",
        },
        { skill = 100, rank = 5, label = "Prismatic-tier gear", benefit = "Best-in-slot craftable plate and weapons" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Weaponsmithing",
                    desc = "Unlocks two-hand and plate weapon recipes first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Armorsmithing",
                    desc = "Unlocks plate armor recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                    swapAt = 50,
                },
                {
                    name = "Toolsmithing",
                    desc = "Unlocks gathering-tool recipes (Pick/Blade/Sickle)",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Forge Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Smithing",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Reinforced Casts",
                    desc = "Chance to craft rank 3 armor directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Voidore Forging",
                    desc = "Unlocks Midnight Voidore gear recipes",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Socket Forging",
                    desc = "Craft gem sockets into weapons",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Blacksmith",
                    desc = "Capstone: all plate/weapons rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Forge",
                    desc = "Craft Prismatic-tier armor and weapons",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Tailoring ──────────────────────────────────────────────────────────
P[197] = {
    name = "Tailoring",
    type = "crafting",
    icon = 4620681,
    maxSkill = 100,
    firstPath = "Clothcrafting",
    firstPathReason = "Unlocks cloth armor recipes first — the core output of Tailoring. No gathering profession pair needed since Tailoring runs on cloth drops, not a dedicated gathering skill.",
    personalBenefit = "Craft your own cloth armor upgrades and exclusive Tailoring-only items (bags, embroidered cloaks) straight from cloth drops while leveling and raiding.",

    gearSlots = {
        tool = {
            name = "Tailoring Tools",
            recommended = "Midnight Sewing Kit",
            bonuses = "+15 Tailoring, +10 Multicraft",
            source = "Crafted (Tailoring 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Tailoring Accessory 1",
            recommended = "Weaver's Thimble",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Tailoring Accessory 2",
            recommended = "Embroidery Needle",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 cloth armor", benefit = "Basic cloth armor recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger cloth pieces, higher stat budget" },
        {
            skill = 50,
            rank = 3,
            label = "Midnight Silkweave gear",
            benefit = "Epic-track cloth armor using rare cloth",
        },
        {
            skill = 75,
            rank = 4,
            label = "Bags and containers",
            benefit = "Craftable large bags — universal utility item",
        },
        { skill = 100, rank = 5, label = "Prismatic-tier gear", benefit = "Best-in-slot craftable cloth armor" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Clothcrafting",
                    desc = "Unlocks cloth armor recipes first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Bagcrafting",
                    desc = "Unlocks bag/container recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Embroidery",
                    desc = "Unlocks cloak and cosmetic embroidery recipes",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Weaving Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Weaving",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Reinforced Seams",
                    desc = "Chance to craft rank 3 armor directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Silkweave Crafting",
                    desc = "Unlocks Midnight Silkweave gear recipes",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Spacious Bags",
                    desc = "Craftable bags gain +2 extra slots",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Tailor",
                    desc = "Capstone: all cloth armor rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Loom",
                    desc = "Craft Prismatic-tier cloth armor",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Jewelcrafting ─────────────────────────────────────────────────────
P[755] = {
    name = "Jewelcrafting",
    type = "crafting",
    icon = 4620677,
    maxSkill = 100,
    firstPath = "Gemcrafting",
    firstPathReason = "Unlocks gem-cutting recipes first — every other crafter and raider needs cut gems for socketed gear. Highest early demand of any Jewelcrafting path.",
    personalBenefit = "Cut your own gems for sockets, craft rings/necklaces with unique Jewelcrafter-only stat combos, and pair directly with a Mining gathering profession.",

    gearSlots = {
        tool = {
            name = "Jeweler's Tools",
            recommended = "Midnight Lapidary Kit",
            bonuses = "+15 Jewelcrafting, +10 Multicraft",
            source = "Crafted (Jewelcrafting 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Jewelcrafting Accessory 1",
            recommended = "Loupe of Precision",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Jewelcrafting Accessory 2",
            recommended = "Cutting Chisel",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 gems/jewelry", benefit = "Basic gem cuts and jewelry recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger gem stat budget" },
        { skill = 50, rank = 3, label = "Midnight Voidstone gems", benefit = "Epic-track gems using Voidstone" },
        {
            skill = 75,
            rank = 4,
            label = "Unique-equipped jewelry",
            benefit = "Jewelcrafter-only ring/necklace recipes",
        },
        { skill = 100, rank = 5, label = "Prismatic-tier gems", benefit = "Best-in-slot craftable gems and jewelry" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Gemcrafting",
                    desc = "Unlocks gem-cutting recipes first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Jewelrycrafting",
                    desc = "Unlocks ring/necklace recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Statuecrafting",
                    desc = "Unlocks profession-tool and trinket recipes",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Lapidary Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Cutting",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Precision Faceting",
                    desc = "Chance to craft rank 3 gems directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Voidstone Cutting",
                    desc = "Unlocks Midnight Voidstone gem recipes",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Unique Settings",
                    desc = "Unlocks Jewelcrafter-only jewelry recipes",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Jeweler",
                    desc = "Capstone: all gems/jewelry rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Facet",
                    desc = "Craft Prismatic-tier gems",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Inscription ───────────────────────────────────────────────────────
P[773] = {
    name = "Inscription",
    type = "crafting",
    icon = 4620676,
    maxSkill = 100,
    firstPath = "Glyphcrafting",
    firstPathReason = "Unlocks combat glyphs first — direct gameplay impact for your own character before branching into off-hand tomes or raid consumables.",
    personalBenefit = "Craft your own combat glyphs, off-hand casting tomes, and raid-consumable scrolls. Pairs directly with a Herbalism gathering profession for milling materials.",

    gearSlots = {
        tool = {
            name = "Inscription Tools",
            recommended = "Midnight Scribing Quill",
            bonuses = "+15 Inscription, +10 Multicraft",
            source = "Crafted (Inscription 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Inscription Accessory 1",
            recommended = "Scribe's Spectacles",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Inscription Accessory 2",
            recommended = "Inkwell of Focus",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 glyphs", benefit = "Basic combat glyph recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger glyph effects" },
        { skill = 50, rank = 3, label = "Off-hand tomes/relics", benefit = "Epic-track caster off-hand items" },
        { skill = 75, rank = 4, label = "Raid scroll consumables", benefit = "Group-wide buff scrolls for raids" },
        { skill = 100, rank = 5, label = "Prismatic-tier relics", benefit = "Best-in-slot craftable off-hand items" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Glyphcrafting",
                    desc = "Unlocks combat glyph recipes first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Relic Crafting",
                    desc = "Unlocks off-hand tome/relic recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Scrollcrafting",
                    desc = "Unlocks raid consumable scroll recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Scribing Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Milling",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Precise Inking",
                    desc = "Chance to craft rank 3 glyphs directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Tome Binding",
                    desc = "Unlocks epic-track off-hand tomes/relics",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Bulk Scrolls",
                    desc = "Craft raid scrolls in stacks of 3",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Scribe",
                    desc = "Capstone: all glyphs/relics rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Inkwell",
                    desc = "Craft Prismatic-tier relics",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Engineering ───────────────────────────────────────────────────────
P[202] = {
    name = "Engineering",
    type = "crafting",
    icon = 4620673,
    maxSkill = 100,
    firstPath = "Gadgetcrafting",
    firstPathReason = "Unlocks personal utility gadgets first (grappling hooks, portable repair bots) — the class-agnostic quality-of-life recipes every Engineer wants before branching into explosives or armor mods.",
    personalBenefit = "Craft utility gadgets, trinkets, and armor-slot mods available to no other profession. Pairs directly with a Mining gathering profession.",

    gearSlots = {
        tool = {
            name = "Engineering Tools",
            recommended = "Midnight Gearwrench Set",
            bonuses = "+15 Engineering, +10 Multicraft",
            source = "Crafted (Engineering 50)",
            skillBonus = 15,
        },
        accessory1 = {
            name = "Engineering Accessory 1",
            recommended = "Insulated Work Gloves",
            bonuses = "+8 Resourcefulness",
            source = "Crafted or AH",
            skillBonus = 8,
        },
        accessory2 = {
            name = "Engineering Accessory 2",
            recommended = "Precision Goggles",
            bonuses = "+8 Ingenuity",
            source = "Crafted or AH",
            skillBonus = 8,
        },
    },

    thresholds = {
        { skill = 1, rank = 1, label = "Rank 1 gadgets", benefit = "Basic utility gadget recipes" },
        { skill = 25, rank = 2, label = "Rank 2 quality", benefit = "Stronger gadget effects, shorter cooldowns" },
        {
            skill = 50,
            rank = 3,
            label = "Midnight Voidore tech",
            benefit = "Epic-track gadgets using Voidore components",
        },
        {
            skill = 75,
            rank = 4,
            label = "Armor-slot mods",
            benefit = "Craftable mods that socket into any gear slot",
        },
        { skill = 100, rank = 5, label = "Prismatic-tier tech", benefit = "Best-in-slot craftable gadgets and mods" },
    },

    talentTree = {
        rows = {
            {
                {
                    name = "Gadgetcrafting",
                    desc = "Unlocks personal utility gadgets first",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Munitions",
                    desc = "Unlocks explosives/ranged gadget recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
                {
                    name = "Armor Tech",
                    desc = "Unlocks armor-slot mod recipes first",
                    recommended = false,
                    skillReq = 1,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Tinker Mastery",
                    desc = "+15% proc chance on all crafts",
                    recommended = true,
                    skillReq = 1,
                    firstPick = true,
                },
                {
                    name = "Efficient Tinkering",
                    desc = "10% chance to use fewer reagents",
                    recommended = false,
                    skillReq = 25,
                    firstPick = false,
                },
                {
                    name = "Precision Assembly",
                    desc = "Chance to craft rank 3 gadgets directly",
                    recommended = true,
                    skillReq = 50,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Voidore Tinkering",
                    desc = "Unlocks Midnight Voidore tech recipes",
                    recommended = true,
                    skillReq = 75,
                    firstPick = false,
                },
                {
                    name = "Resourcefulness",
                    desc = "50% chance to refund a reagent",
                    recommended = false,
                    skillReq = 50,
                    firstPick = false,
                },
                {
                    name = "Modular Fitting",
                    desc = "Armor mods gain a second bonus stat",
                    recommended = false,
                    skillReq = 75,
                    firstPick = false,
                },
            },
            {
                {
                    name = "Grand Engineer",
                    desc = "Capstone: all gadgets/mods rank 3+",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
                {
                    name = "Prismatic Assembly",
                    desc = "Craft Prismatic-tier gadgets and mods",
                    recommended = true,
                    skillReq = 100,
                    firstPick = false,
                    isCapstone = true,
                },
            },
        },
    },
}

-- ── Profession Knowledge Point (KP) system ────────────────────────────
-- KP is a SEPARATE currency from skill — weekly-gated, strictly hard-capped
-- NOT the same as skill level. Permanent investment — cannot be reset.
P.KP_SOURCES = {
    {
        source = "First-Craft Bonus",
        amount = 1,
        note = "Every NEW recipe crafted for the first time — also grants Artisan's Acuity",
    },
    {
        source = "Open-World Treasures",
        amount = "3-10",
        note = "One-time hidden treasures in expansion zones — excavate for flat KP boosts",
    },
    {
        source = "Weekly Service Contracts",
        amount = "varies",
        note = "Fulfil crafting orders or weekly profession quests in crafting districts",
    },
    {
        source = "Artisan's Acuity",
        amount = "varies",
        note = "Currency earned from first-crafts, spent on KP from vendors",
    },
}

-- ── Profession secondary stats ─────────────────────────────────────────
-- Crafting stats
P.CRAFTING_STATS = {
    Multicraft = {
        type = "crafting",
        desc = "Chance to create duplicate items at zero extra material cost. Essential for Alchemy and Jewelcrafting — proccing 10 extra flasks from 1 set of mats = pure profit.",
    },
    Resourcefulness = {
        type = "crafting",
        desc = "Chance to refund a portion of the rarest raw materials used. Critical for heavy armor/weapon crafters working with expensive endgame alloys.",
    },
    Ingenuity = {
        type = "crafting",
        desc = "50-100% chance to fully refund your Concentration resource. Lets you bypass the weekly Concentration cap for guaranteed max-rank crafts.",
    },
}
-- Gathering stats
P.GATHERING_STATS = {
    Finesse = {
        type = "gathering",
        desc = "Chance to strip extra baseline resources from a single node. Directly spikes total ore/leather/herb volume per hour.",
    },
    Deftness = {
        type = "gathering",
        desc = "Drastically accelerates gathering channel speed. Mine an ore node in under a second — critical for avoiding open-world aggro.",
    },
    Perception = {
        type = "gathering",
        desc = "Scales chance to discover ultra-rare hidden materials in nodes. Needed to hunt high-value drops like Null Lotus or rare elemental elements.",
    },
}

-- ── Tree archetype taxonomy ────────────────────────────────────────────
P.TREE_ARCHETYPES = {
    mastery = {
        label = "General Mastery",
        desc = "Far left tree. Global efficiency — flat +Skill across all recipes. Makes hitting 5-star quality easier without burning Concentration.",
    },
    spec = {
        label = "End-Item Specialization",
        desc = "Commercial niche tree. Pick a specific item category to master — e.g. Blacksmithing: Blades vs Hafted Weapons.",
    },
    utility = {
        label = "Quality-of-Life Utility",
        desc = "Game-breaking operational perks. Most famous: Mounted Gathering at 40 KP in Botany/Mining Fundamentals — harvest without dismounting.",
    },
    market = {
        label = "Market Efficiency",
        desc = "Proc-based economy stats. Multicraft, Resourcefulness, Ingenuity nodes live here.",
    },
}

-- ── Mounted gathering milestone ────────────────────────────────────────
P.MOUNTED_GATHER_THRESHOLD = 40 -- KP in core Botany/Mining Fundamentals tree
P.MOUNTED_GATHER_PROFS = { "Herbalism", "Mining" }

-- ── Concentration system ───────────────────────────────────────────────
-- Concentration is a weekly-gated energy bar used to guarantee max-rank crafts
-- Ingenuity talent can refund it — bypassing weekly limits
P.CONCENTRATION = {
    weeklyGain = "~150 per week (estimate — verify in-game)",
    cost = "Varies by recipe tier — higher tier costs more",
    effect = "Guarantees maximum quality rank on the craft",
    refundStat = "Ingenuity — 50-100% refund chance per craft",
    note = "Time-gated resource — plan high-value crafts around weekly reset",
}

-- ── Lookup helpers ─────────────────────────────────────────────────────
function P:GetBySkillLine(skillLine)
    return self[skillLine]
end

function P:GetEffectiveSkill(profData, baseSkill)
    if not profData then
        return baseSkill or 0
    end
    local bonus = 0
    for _, slot in pairs(profData.gearSlots or {}) do
        bonus = bonus + (slot.skillBonus or 0)
    end
    return (baseSkill or 0) + bonus
end

function P:GetUnlockedThresholds(profData, effectiveSkill)
    local unlocked = {}
    for _, thresh in ipairs(profData.thresholds or {}) do
        if effectiveSkill >= thresh.skill then
            table.insert(unlocked, thresh)
        end
    end
    return unlocked
end

function P:GetNextThreshold(profData, effectiveSkill)
    for _, thresh in ipairs(profData.thresholds or {}) do
        if effectiveSkill < thresh.skill then
            return thresh
        end
    end
    return nil
end

-- ── Profession pairing recommendations ────────────────────────────────
P.PAIRS = {
    -- Gathering → Crafting pairs (saves buying materials)
    Mining = { "Blacksmithing", "Jewelcrafting", "Engineering" },
    Herbalism = { "Alchemy", "Inscription" },
    Skinning = { "Leatherworking" },
    -- Crafting self-sufficiency
    Alchemy = { "Herbalism" },
    Blacksmithing = { "Mining" },
    Leatherworking = { "Skinning" },
    Jewelcrafting = { "Mining" },
    Engineering = { "Mining" },
    Inscription = { "Herbalism" },
    Tailoring = {}, -- uses cloth drops, no gathering pair needed
    Enchanting = {}, -- uses disenchanted gear
}

-- ── Secondary professions (no slot cost per document) ─────────────────
P.SECONDARY = {
    [185] = {
        name = "Cooking",
        type = "secondary",
        icon = 133971,
        benefit = "Well Fed buff (+stats for 15-30min). Feasts feed entire raid group. Pairs with Fishing.",
        firstPath = "Food Mastery — unlocks better stat food before leveling cooking further",
    },
    [356] = {
        name = "Fishing",
        type = "secondary",
        icon = 136245,
        benefit = "Catches rare fish for Cooking recipes. Hidden treasure from casts (mounts, gold, crafting mats). Required for best raid food.",
        firstPath = "Angling — increases chance of rare catches. No wrong first choice.",
    },
    [794] = {
        name = "Archaeology",
        type = "secondary",
        icon = 441175,
        benefit = "Excavate artifacts for rare mounts, pets, toys, and transmog. No combat requirement.",
        firstPath = "Survey Mastery — faster find radius on digsites",
    },
}

-- ── Lookup: get pairing suggestion ────────────────────────────────────
function P:GetPairingSuggestion(profName)
    return self.PAIRS[profName] or {}
end

function P:GetSecondaryBySkillLine(skillLine)
    return self.SECONDARY[skillLine]
end
