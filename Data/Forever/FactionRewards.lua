-- ToonAge/Data/Forever/FactionRewards.lua
--
-- Sourced WoW Forever (1.60.1) faction reward milestones by standing tier.
-- Pure data: zero executable logic, zero client API calls.
--
-- Indexed by English faction name (case-insensitive lookup in FactionTracker)
-- so it augments live client rows cleanly even where Forever faction IDs
-- have not yet been probed by Harvest.
--
-- Sources:
--   https://www.icy-veins.com/wow-forever/darkspear-islands-battleground-guide
--   https://www.wowhead.com/forever/guide/reputations

local TA = ToonAge
TA.Data = TA.Data or {}

local IV_DI  = "https://www.icy-veins.com/wow-forever/darkspear-islands-battleground-guide"
local WH_REP = "https://www.wowhead.com/forever/guide/reputations"

TA.Data.ForeverFactionRewards = {
    meta = {
        version = "1.60.1",
        sources = { IV_DI, WH_REP },
        tierOrder = { "Friendly", "Honored", "Revered", "Exalted" },
    },

    factions = {
        {
            name = "Darkspear Raiders",
            side = "Horde",
            category = "Battleground",
            activity = "Darkspear Islands (15v15 BG)",
            quartermaster = "Creeg Bothunk (Merchant Coast, The Barrens)",
            source = IV_DI,
            tiers = {
                Friendly = "Darkspear Voodoo Seal & Relentless Raider's Seal (Trinkets)",
                Honored  = "Cloak, Darkspear Signet / Insurgent's Band, Darkspear Warding Pendant",
                Revered  = "Darkspear Insurgent's Spellblade, Raider's Reaper & Off-Hands",
                Exalted  = "iLvl 65 Shoulders & Gloves (all armor types), Battle Tabard, +1 Legacy Point",
            },
        },
        {
            name = "Theramore Expeditionary Force",
            side = "Alliance",
            category = "Battleground",
            activity = "Darkspear Islands (15v15 BG)",
            quartermaster = "Bryanna Embreeze (Northwatch Hold, Dustwallow Marsh)",
            source = IV_DI,
            tiers = {
                Friendly = "Enriched Seal & Volunteer's Lucky Seal (Trinkets)",
                Honored  = "Cloak, Theramore Signet / Militant's Band, Seal of the Expedition",
                Revered  = "Theramore Expedition Weapons & Off-Hands",
                Exalted  = "iLvl 65 Shoulders & Gloves (all armor types), Battle Tabard, +1 Legacy Point",
            },
        },
        {
            name = "Warsong Outriders",
            side = "Horde",
            category = "Battleground",
            activity = "Warsong Gulch (10v10 BG)",
            quartermaster = "Kelm Hargunth (Northern Barrens)",
            source = WH_REP,
            tiers = {
                Friendly = "Warsong Bandages & PvP Potions",
                Honored  = "PvP Rings & Level-Bracket Trinkets",
                Revered  = "Epic Bracers & Cloak",
                Exalted  = "Epic Legs, Boots & Warsong Battle Tabard",
            },
        },
        {
            name = "Silverwing Sentinels",
            side = "Alliance",
            category = "Battleground",
            activity = "Warsong Gulch (10v10 BG)",
            quartermaster = "Illiyana Moonblaze (Ashenvale)",
            source = WH_REP,
            tiers = {
                Friendly = "Silverwing Bandages & PvP Potions",
                Honored  = "PvP Rings & Level-Bracket Trinkets",
                Revered  = "Epic Bracers & Cloak",
                Exalted  = "Epic Legs, Boots & Silverwing Battle Tabard",
            },
        },
        {
            name = "The Defilers",
            side = "Horde",
            category = "Battleground",
            activity = "Arathi Basin (15v15 BG)",
            quartermaster = "Rutherford Twyn (Hammerfall, Arathi Highlands)",
            source = WH_REP,
            tiers = {
                Friendly = "Arathi PvP Bandages & Rations",
                Honored  = "PvP Belts (all armor types)",
                Revered  = "Epic Boots & Cloak",
                Exalted  = "Epic Shoulders & Defiler's Tabard",
            },
        },
        {
            name = "The League of Arathor",
            side = "Alliance",
            category = "Battleground",
            activity = "Arathi Basin (15v15 BG)",
            quartermaster = "Samuel Hawke (Refuge Pointe, Arathi Highlands)",
            source = WH_REP,
            tiers = {
                Friendly = "Arathi PvP Bandages & Rations",
                Honored  = "PvP Belts (all armor types)",
                Revered  = "Epic Boots & Cloak",
                Exalted  = "Epic Shoulders & Arathor Battle Tabard",
            },
        },
        {
            name = "Frostwolf Clan",
            side = "Horde",
            category = "Battleground",
            activity = "Alterac Valley (40v40 BG)",
            quartermaster = "Jekyll Flandring (Alterac Mountains)",
            source = WH_REP,
            tiers = {
                Friendly = "AV Insignia Upgrade & Consumes",
                Honored  = "Cloaks, Trinkets & Ring Upgrades",
                Revered  = "Epic Off-Hands & Armor",
                Exalted  = "The Unstoppable Force, Epic Weapons & Frostwolf Howler",
            },
        },
        {
            name = "Stormpike Guard",
            side = "Alliance",
            category = "Battleground",
            activity = "Alterac Valley (40v40 BG)",
            quartermaster = "Gaelden Hammersmith (Alterac Mountains)",
            source = WH_REP,
            tiers = {
                Friendly = "AV Insignia Upgrade & Consumes",
                Honored  = "Cloaks, Trinkets & Ring Upgrades",
                Revered  = "Epic Off-Hands & Armor",
                Exalted  = "The Unstoppable Force, Epic Weapons & Stormpike Battle Charger",
            },
        },
        {
            name = "Argent Dawn",
            side = "Both",
            category = "PvE",
            activity = "Plaguelands & Undead Dungeons",
            quartermaster = "Quartermaster Miranda Breechlock (Light's Hope Chapel)",
            source = WH_REP,
            tiers = {
                Friendly = "Argent Dawn Commission & Starter Patterns",
                Honored  = "Shoulder Enchants & Resistance Recipes",
                Revered  = "Enchant Bracer - Healing, Blessed Sunfruit & Attunement Discount",
                Exalted  = "Epic Shoulder Enchants & Free Raid Attunement",
            },
        },
        {
            name = "Thorium Brotherhood",
            side = "Both",
            category = "Crafting",
            activity = "Searing Gorge & Blackrock Depths",
            quartermaster = "Lokhtos Darkbargainer (Grim Guzzler, BRD)",
            source = WH_REP,
            tiers = {
                Friendly = "Dark Iron & Fiery Core Starter Recipes",
                Honored  = "30+ Blacksmithing, Tailoring, LW & Enchanting Plans",
                Revered  = "Fire Resistance & Dark Iron Armor Plans",
                Exalted  = "Masterwork Raid Weapon & Armor Recipes",
            },
        },
        {
            name = "Timbermaw Hold",
            side = "Both",
            category = "PvE",
            activity = "Felwood & Winterspring",
            quartermaster = "Meilosh (Timbermaw Hold Tunnel)",
            source = WH_REP,
            tiers = {
                Friendly = "Safe Tunnel Passage & Starter Patterns",
                Honored  = "Agility Weapon Enchants, Tailoring & LW Patterns",
                Revered  = "Endgame Resistance & Stat Recipes",
                Exalted  = "Defender of the Timbermaw Trinket & Lv 60 Rewards",
            },
        },
    },
}
