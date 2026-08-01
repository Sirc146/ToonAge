-- CharacterAdvisor/Data/Professions.lua
-- Profession talent trees, gear slots, quality thresholds (Midnight 12.0.5)

local CA = CharacterAdvisor
CA.Data = CA.Data or {}
CA.Data.Professions = {}
local P = CA.Data.Professions

-- ── Profession gear slot IDs ───────────────────────────────────────────
-- In Midnight, profession gear uses dedicated equip slots
-- These are read via GetInventoryItemID with the prof-specific slot indices
P.GEAR_SLOTS = {
    tool       = "PROFESSION_TOOL_SLOT",      -- Slot 0 per profession context
    accessory1 = "PROFESSION_ACCESSORY_SLOT1",
    accessory2 = "PROFESSION_ACCESSORY_SLOT2",
}

-- ── Quality thresholds ─────────────────────────────────────────────────
-- Format: { skill=number, label=string, personalBenefit=string }
-- skill = effective skill needed (base + gear bonus)

-- ── Herbalism ─────────────────────────────────────────────────────────
P[182] = {  -- skillLine ID for Herbalism
    name       = "Herbalism",
    type       = "gathering",
    icon       = 136246,
    maxSkill   = 100,
    firstPath  = "Bountiful Harvest",
    firstPathReason = "Maximises herb yield per node while leveling — more mats = faster skill gain. Swap to Finesse branch at skill 75 for rare herb proc chance.",
    personalBenefit = "Gather Duskbloom and Voidpetal — core materials for healing flasks that increase HPS by ~8%. Free consumables every week.",

    gearSlots = {
        tool = {
            name        = "Herb Gathering Tool",
            recommended = "Midnight Herbalist's Sickle",
            bonuses     = "+15 Herbalism skill, +10 Deftness",
            source      = "Crafted (Blacksmithing 50) or AH",
            skillBonus  = 15,
        },
        accessory1 = {
            name        = "Herbalism Accessory 1",
            recommended = "Herbalist's Gathering Gloves",
            bonuses     = "+8 Deftness",
            source      = "Crafted (Leatherworking 25) or AH",
            skillBonus  = 8,
        },
        accessory2 = {
            name        = "Herbalism Accessory 2",
            recommended = "Verdant Gathering Charm",
            bonuses     = "+8 Finesse",
            source      = "Crafted (Jewelcrafting 25) or AH",
            skillBonus  = 8,
        },
    },

    thresholds = {
        { skill=1,   rank=1, label="Common herbs (Rank 1)",        benefit="Gather basic Midnight herbs" },
        { skill=25,  rank=2, label="Rank 2 herbs (improved yield)", benefit="More herbs per node" },
        { skill=50,  rank=3, label="Rank 3 herbs (craft mats)",     benefit="Gather rare-quality herbs for potions" },
        { skill=75,  rank=4, label="Voidpetal — healing flask mat", benefit="Flask of Midnight Clarity material" },
        { skill=100, rank=5, label="Prismatic Nightbloom (rare)",   benefit="Best herb — requires Finesse stat" },
    },

    talentTree = {
        -- ⚠ PERMANENT — cannot be reset. Plan before spending KP.
        -- KP sources: first-craft bonus (1 KP each new recipe), open-world treasures, weekly quests
        archetypes = {
            { archetype="mastery",  name="Botany",           kpRequired=1,  desc="General Mastery tree (far left) — global +Skill across all herbs. Milestone at 40 KP: MOUNTED GATHERING unlocked (harvest without dismounting — changes farming entirely)", recommended=true, firstPick=true },
            { archetype="spec",     name="Bountiful Harvest",kpRequired=1,  desc="End-Item Spec — maximises herb yield per node. Primary stat: Finesse (+baseline herbs per gather). Take first while leveling skill.", recommended=true, firstPick=true },
            { archetype="utility",  name="Deftness",         kpRequired=10, desc="Quality-of-Life — faster gather animation (Deftness stat). Critical for avoiding open-world aggro and farming efficiency.", recommended=false },
            { archetype="market",   name="Rare Seeker / Perception", kpRequired=75, desc="Market Efficiency — Perception stat scales chance to find ultra-rare herbs (Null Lotus, rare elementals). Take at skill 75.", recommended=true, swapAt=75 },
        },
        permanenceWarning = "⚠ Profession talent choices are PERMANENT — unlike combat talents, KP cannot be refunded. Botany (mounted gathering at 40 KP) is the highest-value milestone. Prioritize it before branching.",
        rows = {
            {
                { name="Botany (General Mastery)", desc="+Skill all herbs · 40 KP = Mounted Gathering", recommended=true,  skillReq=1,  firstPick=true,  archetype="mastery" },
                { name="Bountiful Harvest",        desc="Finesse: +herbs per node",                      recommended=true,  skillReq=1,  firstPick=true,  archetype="spec"    },
                { name="Deftness Track",           desc="Deftness: faster animation",                    recommended=false, skillReq=10, firstPick=false, archetype="utility" },
            },
            {
                { name="Verdant Bounty",   desc="+1 herb on Finesse proc",         recommended=true,  skillReq=1,   archetype="spec"    },
                { name="Swift Gathering",  desc="Deftness +15 — near-instant picks", recommended=false, skillReq=25,  archetype="utility" },
                { name="Perception Nodes", desc="Perception: rare herb discovery",  recommended=false, skillReq=25,  archetype="market"  },
            },
            {
                { name="Plentiful Yield",  desc="+2 herbs on proc (Finesse)",       recommended=true,  skillReq=50,  archetype="spec"   },
                { name="Fleet of Foot",    desc="+8% move speed between nodes",      recommended=false, skillReq=50,  archetype="utility" },
                { name="Rare Seeker",      desc="Perception doubles rare chance",    recommended=true,  skillReq=75,  archetype="market", swapNote="Priority at skill 75" },
            },
            {
                { name="Master Botanist",  desc="Capstone: all yields +25%",         recommended=true,  skillReq=100, isCapstone=true, archetype="mastery" },
                { name="Nightbloom Whisperer", desc="Prismatic proc (Perception)", recommended=true,  skillReq=100, isCapstone=true, archetype="market"  },
            },
        },
    },
}

-- ── Skinning ──────────────────────────────────────────────────────────
P[393] = {  -- skillLine ID for Skinning
    name       = "Skinning",
    type       = "gathering",
    icon       = 134366,
    maxSkill   = 100,
    firstPath  = "Bountiful Harvest",
    firstPathReason = "More leather per kill while leveling. At skill 50 invest in Finesse for rare hide procs that enable craftable gear upgrades.",
    personalBenefit = "Gather Midnight Dragonhide — used in crafted mail armor upgrades directly relevant to Preservation. Effective skill 60 with BIS profession gear unlocks Rank 3 hides immediately.",

    gearSlots = {
        tool = {
            name        = "Skinning Knife",
            recommended = "Midnight Skinner's Blade",
            bonuses     = "+15 Skinning skill, +10 Bountiful Harvest",
            source      = "Crafted (Blacksmithing 50) or AH",
            skillBonus  = 15,
        },
        accessory1 = {
            name        = "Skinning Accessory 1",
            recommended = "Skinner's Grips",
            bonuses     = "+8 Bountiful Harvest",
            source      = "Crafted (Leatherworking 25) or AH",
            skillBonus  = 8,
        },
        accessory2 = {
            name        = "Skinning Accessory 2",
            recommended = "Beast Tracker's Charm",
            bonuses     = "+8 Finesse",
            source      = "Crafted (Jewelcrafting 25) or AH",
            skillBonus  = 8,
        },
    },

    thresholds = {
        { skill=1,   rank=1, label="Common leather",                benefit="Basic crafting material" },
        { skill=25,  rank=2, label="Rank 2 leather (improved)",     benefit="Better yield per beast" },
        { skill=50,  rank=3, label="Midnight Dragonhide",           benefit="Craft mail armor upgrade mats" },
        { skill=75,  rank=4, label="Rare hides",                    benefit="High-quality gear crafting material" },
        { skill=100, rank=5, label="Prismatic Scale (best mat)",    benefit="Requires Finesse — top craft material" },
    },

    talentTree = {
        permanenceWarning = "⚠ PERMANENT — KP cannot be refunded. Skinning has no mounted-gathering milestone but Deftness (speed) is essential for farming efficiently.",
        rows = {
            {
                { name="Skinning Mastery",   desc="General Mastery: +Skill all leather", recommended=true,  skillReq=1,  firstPick=true,  archetype="mastery" },
                { name="Bountiful Harvest",  desc="Finesse: +leather per skin",           recommended=true,  skillReq=1,  firstPick=true,  archetype="spec"    },
                { name="Swift Skinner",      desc="Deftness: faster skin animation",      recommended=false, skillReq=1,  firstPick=false, archetype="utility" },
            },
            {
                { name="Plentiful Hides",    desc="+1 leather on Finesse proc",           recommended=true,  skillReq=1,   archetype="spec"    },
                { name="Beast Tracking",     desc="Skinnable beasts shown on minimap",    recommended=false, skillReq=25,  archetype="utility" },
                { name="Perception Track",   desc="Perception: rare hide discovery",      recommended=false, skillReq=25,  archetype="market"  },
            },
            {
                { name="Dragonhide Mastery", desc="Midnight Dragonhide +50% yield",       recommended=true,  skillReq=50,  archetype="spec"    },
                { name="Efficient Cuts",     desc="Deftness on tagged-beast nodes",        recommended=false, skillReq=50,  archetype="utility" },
                { name="Rare Hide Seeker",   desc="Perception doubles rare hide chance",   recommended=true,  skillReq=75,  archetype="market", swapNote="Priority at skill 75" },
            },
            {
                { name="Master Skinner",     desc="Capstone: all yields +25%",             recommended=true,  skillReq=100, isCapstone=true, archetype="mastery" },
                { name="Prismatic Scale Hunter", desc="Prismatic Scale proc (Perception)",recommended=true,  skillReq=100, isCapstone=true, archetype="market"  },
            },
        },
    },
}

-- ── Alchemy ───────────────────────────────────────────────────────────
P[171] = {
    name       = "Alchemy",
    type       = "crafting",
    icon       = 136240,
    maxSkill   = 100,
    firstPath  = "Potion Mastery",
    firstPathReason = "Unlocks double-proc on healing potions used in combat — immediate HPS gain. Swap to Flask Mastery at skill 50 for permanent stat flasks.",
    personalBenefit = "Craft Elixir of the Preservation (+8% HPS) and Flask of Midnight Clarity (+Mastery) for free. Never buy consumables again.",

    gearSlots = {
        tool = { name="Alchemist's Tool", recommended="Midnight Alchemist's Stone", bonuses="+15 Alchemy, +10 Resourcefulness", source="Crafted (Alchemy 50)", skillBonus=15 },
        accessory1 = { name="Alchemy Accessory 1", recommended="Vial Harness", bonuses="+8 Inspiration", source="Crafted or AH", skillBonus=8 },
        accessory2 = { name="Alchemy Accessory 2", recommended="Transmutation Focus", bonuses="+8 Resourcefulness", source="Crafted or AH", skillBonus=8 },
    },

    thresholds = {
        { skill=1,   rank=1, label="Rank 1 potions/flasks",    benefit="Basic healing and mana potions" },
        { skill=25,  rank=2, label="Rank 2 quality",           benefit="Stronger potions, higher proc chance" },
        { skill=50,  rank=3, label="Flasks — personal stat",   benefit="Flask of Midnight Clarity (+Mastery)" },
        { skill=75,  rank=4, label="Elixir of Preservation",   benefit="+8% HPS — best healer flask in Midnight" },
        { skill=100, rank=5, label="Cauldron crafting",        benefit="Raid cauldron for entire group" },
    },

    talentTree = {
        rows = {
            {
                { name="Potion Mastery",   desc="Double-proc healing potions in combat", recommended=true, skillReq=1,  firstPick=true },
                { name="Transmutation",    desc="Convert materials at favourable rates",  recommended=false, skillReq=1, firstPick=false },
                { name="Flask Mastery",    desc="Higher quality flask output",            recommended=false, skillReq=10, firstPick=false, swapAt=50 },
            },
            {
                { name="Alchemical Mastery", desc="Proc chance +15% on all crafts",     recommended=true, skillReq=1,  firstPick=true },
                { name="Efficient Mixing",   desc="10% chance to use fewer reagents",    recommended=false, skillReq=25, firstPick=false },
                { name="Inspired Flask",     desc="Chance to craft rank 3 flasks",       recommended=true, skillReq=50, firstPick=false },
            },
            {
                { name="Midnight Formulas", desc="Unlocks Elixir of Preservation recipe", recommended=true, skillReq=75, firstPick=false },
                { name="Resourcefulness",   desc="50% chance to refund a reagent",       recommended=false, skillReq=50, firstPick=false },
                { name="Extended Duration", desc="+30 min to all flask durations",        recommended=false, skillReq=75, firstPick=false },
            },
            {
                { name="Grand Alchemist",   desc="Capstone: all potions/flasks rank 3+", recommended=true, skillReq=100, firstPick=false, isCapstone=true },
                { name="Raid Cauldron",     desc="Craft group cauldron for 10+ players",  recommended=true, skillReq=100, firstPick=false, isCapstone=true },
            },
        },
    },
}

-- ── Enchanting ────────────────────────────────────────────────────────
P[333] = {
    name       = "Enchanting",
    type       = "crafting",
    icon       = 136244,
    maxSkill   = 100,
    firstPath  = "Weapon Mastery",
    firstPathReason = "Unlocks highest-tier weapon enchants for healers first — Mastery of the Dreamer is your best weapon enchant. Free self-enchanting saves gold every tier.",
    personalBenefit = "Enchant your own weapon (Mastery of the Dreamer), rings (+200 Mastery each), and armor. Never pay AH prices. Disenchant unwanted drops for mats.",

    gearSlots = {
        tool = { name="Enchanting Rod", recommended="Midnight Void Rod", bonuses="+15 Enchanting, +10 Inspiration", source="Crafted (Enchanting 50)", skillBonus=15 },
        accessory1 = { name="Enchanting Accessory 1", recommended="Runescribed Gloves", bonuses="+8 Resourcefulness", source="Crafted or AH", skillBonus=8 },
        accessory2 = { name="Enchanting Accessory 2", recommended="Disenchanter's Lens", bonuses="+8 Finesse", source="Crafted or AH", skillBonus=8 },
    },

    thresholds = {
        { skill=1,   rank=1, label="Basic enchants",            benefit="Simple stat enchants for any slot" },
        { skill=25,  rank=2, label="Ring enchants",             benefit="+Mastery on both rings — ~200 stat free" },
        { skill=50,  rank=3, label="Weapon enchants",           benefit="Mastery of the Dreamer — best healer weapon enchant" },
        { skill=75,  rank=4, label="Rank 2 weapon enchants",    benefit="Higher proc chance and stat value" },
        { skill=100, rank=5, label="Rank 3 — Prismatic enchant", benefit="Best-in-slot enchant for all slots" },
    },

    talentTree = {
        rows = {
            {
                { name="Weapon Mastery",    desc="Unlocks healer weapon enchants first", recommended=true, skillReq=1,  firstPick=true },
                { name="Armor Mastery",     desc="Unlocks chest/legs enchants",          recommended=false, skillReq=1, firstPick=false },
                { name="Jewel Mastery",     desc="Unlocks ring/neck enchants",           recommended=false, skillReq=1, firstPick=false },
            },
            {
                { name="Inspired Runing",   desc="+15% chance to proc higher rank",      recommended=true, skillReq=1,  firstPick=true },
                { name="Efficient Disenchanting", desc="More mats from disenchanting",   recommended=false, skillReq=25, firstPick=false },
                { name="Careful Inscription", desc="Reduces quality variance",           recommended=false, skillReq=25, firstPick=false },
            },
            {
                { name="Mastery of the Dreamer", desc="Unlocks best healer weapon enchant", recommended=true, skillReq=50, firstPick=false },
                { name="Resourcefulness",   desc="Chance to refund enchanting mats",      recommended=false, skillReq=50, firstPick=false },
                { name="Extended Imbue",    desc="+1 hour to all enchant proc durations", recommended=false, skillReq=75, firstPick=false },
            },
            {
                { name="Grand Enchanter",   desc="Capstone: all enchants are rank 3",    recommended=true, skillReq=100, firstPick=false, isCapstone=true },
                { name="Prismatic Rune",    desc="Craft Prismatic enchants (+all stats)", recommended=true, skillReq=100, firstPick=false, isCapstone=true },
            },
        },
    },
}


-- ── Mining ────────────────────────────────────────────────────────────
P[186] = {  -- skillLine ID for Mining
    name       = "Mining",
    type       = "gathering",
    icon       = 136243,
    maxSkill   = 100,
    firstPath  = "Bountiful Harvest",
    firstPathReason = "More ore per node while leveling — faster skill gain. Swap to Finesse branch at skill 75 for rare metal procs (Midnight Voidore).",
    personalBenefit = "Gather Midnight Ironore and Voidore — materials for Blacksmithing gear upgrades and Engineering gadgets. Ore sells well on AH.",

    gearSlots = {
        tool = {
            name        = "Mining Pick",
            recommended = "Midnight Miner's Pick",
            bonuses     = "+15 Mining skill, +10 Bountiful Harvest",
            source      = "Crafted (Blacksmithing 50) or AH",
            skillBonus  = 15,
        },
        accessory1 = {
            name        = "Mining Accessory 1",
            recommended = "Miner's Sturdy Gloves",
            bonuses     = "+8 Bountiful Harvest",
            source      = "Crafted or AH",
            skillBonus  = 8,
        },
        accessory2 = {
            name        = "Mining Accessory 2",
            recommended = "Vein Tracker's Charm",
            bonuses     = "+8 Finesse",
            source      = "Crafted or AH",
            skillBonus  = 8,
        },
    },

    thresholds = {
        { skill=1,   rank=1, label="Common ore (basic mats)",        benefit="Midnight Ironore for Blacksmithing" },
        { skill=25,  rank=2, label="Rank 2 ore (improved yield)",    benefit="More ore per node" },
        { skill=50,  rank=3, label="Midnight Voidore (rare metal)",  benefit="Used in epic Blacksmithing gear" },
        { skill=75,  rank=4, label="Elementium veins (bonus mats)",  benefit="Bonus procs when mining void nodes" },
        { skill=100, rank=5, label="Prismatic Shard (rare proc)",    benefit="Best crafting metal — requires Finesse" },
    },

    talentTree = {
        rows = {
            {
                { name="Bountiful Harvest", desc="+1 ore per node",                recommended=true,  skillReq=1,  firstPick=true  },
                { name="Deep Seeker",       desc="Find ore nodes more easily",      recommended=false, skillReq=1,  firstPick=false },
                { name="Finesse",           desc="Rare metal proc chance",           recommended=false, skillReq=10, firstPick=false, swapAt=75 },
            },
            {
                { name="Plentiful Veins",   desc="+1 ore on large vein nodes",      recommended=true,  skillReq=1,  firstPick=true  },
                { name="Swift Strikes",     desc="Faster mining animation",          recommended=false, skillReq=25, firstPick=false },
                { name="Careful Extraction",desc="Reduces failed mining attempts",   recommended=false, skillReq=25, firstPick=false },
            },
            {
                { name="Voidore Mastery",   desc="Midnight Voidore yield +50%",     recommended=true,  skillReq=50, firstPick=false },
                { name="Efficient Mining",  desc="Mine faster on tagged nodes",      recommended=false, skillReq=50, firstPick=false },
                { name="Rare Vein Seeker",  desc="Doubles rare metal chance",        recommended=true,  skillReq=75, firstPick=false, swapNote="Take at skill 75" },
            },
            {
                { name="Master Miner",      desc="Capstone: all yields +25%",        recommended=true,  skillReq=100, firstPick=false, isCapstone=true },
                { name="Prismatic Seeker",  desc="Prismatic Shard proc chance",      recommended=true,  skillReq=100, firstPick=false, isCapstone=true },
            },
        },
    },
}


-- ── Profession Knowledge Point (KP) system ────────────────────────────
-- KP is a SEPARATE currency from skill — weekly-gated, strictly hard-capped
-- NOT the same as skill level. Permanent investment — cannot be reset.
P.KP_SOURCES = {
    { source="First-Craft Bonus",    amount=1,   note="Every NEW recipe crafted for the first time — also grants Artisan's Acuity" },
    { source="Open-World Treasures", amount="3-10", note="One-time hidden treasures in expansion zones — excavate for flat KP boosts" },
    { source="Weekly Service Contracts", amount="varies", note="Fulfil crafting orders or weekly profession quests in crafting districts" },
    { source="Artisan's Acuity",     amount="varies", note="Currency earned from first-crafts, spent on KP from vendors" },
}

-- ── Profession secondary stats ─────────────────────────────────────────
-- Crafting stats
P.CRAFTING_STATS = {
    Multicraft     = { type="crafting", desc="Chance to create duplicate items at zero extra material cost. Essential for Alchemy and Jewelcrafting — proccing 10 extra flasks from 1 set of mats = pure profit." },
    Resourcefulness= { type="crafting", desc="Chance to refund a portion of the rarest raw materials used. Critical for heavy armor/weapon crafters working with expensive endgame alloys." },
    Ingenuity      = { type="crafting", desc="50-100% chance to fully refund your Concentration resource. Lets you bypass the weekly Concentration cap for guaranteed max-rank crafts." },
}
-- Gathering stats
P.GATHERING_STATS = {
    Finesse        = { type="gathering", desc="Chance to strip extra baseline resources from a single node. Directly spikes total ore/leather/herb volume per hour." },
    Deftness       = { type="gathering", desc="Drastically accelerates gathering channel speed. Mine an ore node in under a second — critical for avoiding open-world aggro." },
    Perception     = { type="gathering", desc="Scales chance to discover ultra-rare hidden materials in nodes. Needed to hunt high-value drops like Null Lotus or rare elemental elements." },
}

-- ── Tree archetype taxonomy ────────────────────────────────────────────
P.TREE_ARCHETYPES = {
    mastery  = { label="General Mastery",       desc="Far left tree. Global efficiency — flat +Skill across all recipes. Makes hitting 5-star quality easier without burning Concentration." },
    spec     = { label="End-Item Specialization",desc="Commercial niche tree. Pick a specific item category to master — e.g. Blacksmithing: Blades vs Hafted Weapons." },
    utility  = { label="Quality-of-Life Utility",desc="Game-breaking operational perks. Most famous: Mounted Gathering at 40 KP in Botany/Mining Fundamentals — harvest without dismounting." },
    market   = { label="Market Efficiency",      desc="Proc-based economy stats. Multicraft, Resourcefulness, Ingenuity nodes live here." },
}

-- ── Mounted gathering milestone ────────────────────────────────────────
P.MOUNTED_GATHER_THRESHOLD = 40  -- KP in core Botany/Mining Fundamentals tree
P.MOUNTED_GATHER_PROFS     = {"Herbalism", "Mining"}

-- ── Concentration system ───────────────────────────────────────────────
-- Concentration is a weekly-gated energy bar used to guarantee max-rank crafts
-- Ingenuity talent can refund it — bypassing weekly limits
P.CONCENTRATION = {
    weeklyGain = "~150 per week (estimate — verify in-game)",
    cost       = "Varies by recipe tier — higher tier costs more",
    effect     = "Guarantees maximum quality rank on the craft",
    refundStat = "Ingenuity — 50-100% refund chance per craft",
    note       = "Time-gated resource — plan high-value crafts around weekly reset",
}

-- ── Lookup helpers ─────────────────────────────────────────────────────
function P:GetBySkillLine(skillLine)
    return self[skillLine]
end

function P:GetEffectiveSkill(profData, baseSkill)
    if not profData then return baseSkill or 0 end
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
    Mining     = {"Blacksmithing", "Jewelcrafting", "Engineering"},
    Herbalism  = {"Alchemy", "Inscription"},
    Skinning   = {"Leatherworking"},
    -- Crafting self-sufficiency
    Alchemy    = {"Herbalism"},
    Blacksmithing = {"Mining"},
    Leatherworking = {"Skinning"},
    Jewelcrafting = {"Mining"},
    Engineering = {"Mining"},
    Inscription = {"Herbalism"},
    Tailoring  = {},  -- uses cloth drops, no gathering pair needed
    Enchanting = {},  -- uses disenchanted gear
}

-- ── Secondary professions (no slot cost per document) ─────────────────
P.SECONDARY = {
    [185] = { name="Cooking",    type="secondary", icon=133971,
              benefit="Well Fed buff (+stats for 15-30min). Feasts feed entire raid group. Pairs with Fishing.",
              firstPath="Food Mastery — unlocks better stat food before leveling cooking further" },
    [356] = { name="Fishing",    type="secondary", icon=136245,
              benefit="Catches rare fish for Cooking recipes. Hidden treasure from casts (mounts, gold, crafting mats). Required for best raid food.",
              firstPath="Angling — increases chance of rare catches. No wrong first choice." },
    [794] = { name="Archaeology", type="secondary", icon=441175,
              benefit="Excavate artifacts for rare mounts, pets, toys, and transmog. No combat requirement.",
              firstPath="Survey Mastery — faster find radius on digsites" },
}

-- ── Lookup: get pairing suggestion ────────────────────────────────────
function P:GetPairingSuggestion(profName)
    return self.PAIRS[profName] or {}
end

function P:GetSecondaryBySkillLine(skillLine)
    return self.SECONDARY[skillLine]
end
