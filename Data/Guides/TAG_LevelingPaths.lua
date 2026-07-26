-- ToonAge/Data/Guides/TAG_LevelingPaths.lua
-- Stub guide registrations for ALL major leveling paths 1-90.
-- These provide Guide Tab coverage and nextGuide chaining so the
-- player always has a path. Stubs with 0 quest steps will trigger
-- Quest Log Follow mode in the tracker, giving the player arrow
-- guidance from Blizzard's native quest tracking system.
--
-- As real guide data is added (via PTR walkthrough or data pipeline),
-- these stubs are replaced by full guides in their own TAG_*.lua files.
-- If a full guide file exists with the same ID, it overwrites the stub
-- (TA.GuideData is a table — last write wins, and full guides load after this file).

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER: Register a stub guide (minimal data, triggers Quest Log Follow mode)
-- ═══════════════════════════════════════════════════════════════════════════════
local function Stub(id, title, expansion, minLevel, maxLevel, zone, nextGuide)
    -- Don't overwrite if a real guide already exists (loaded from its own TAG_ file)
    if TA.GuideData[id] then return end
    TA.GuideData[id] = {
        id        = id,
        title     = title,
        expansion = expansion,
        zone      = zone or 0,
        minLevel  = minLevel,
        maxLevel  = maxLevel,
        nextGuide = nextGuide,
        steps     = {},  -- Empty = triggers Quest Log Follow mode
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- STARTER ZONES (Level 1-10)
-- ═══════════════════════════════════════════════════════════════════════════════
-- exiles_reach is in its own file (TAG_Exiles_Reach.lua) — don't stub it
Stub("starter_human",       "Northshire Valley",       "starter", 1, 10, 0, "midnight_intro")
Stub("starter_dwarf",       "Coldridge Valley",        "starter", 1, 10, 0, "midnight_intro")
Stub("starter_gnome",       "Gnomeregan",              "starter", 1, 10, 0, "midnight_intro")
Stub("starter_nightelf",    "Shadowglen",              "starter", 1, 10, 0, "midnight_intro")
Stub("starter_draenei",     "Ammen Vale",              "starter", 1, 10, 0, "midnight_intro")
Stub("starter_worgen",      "Gilneas",                 "starter", 1, 10, 0, "midnight_intro")
Stub("starter_orc",         "Valley of Trials",        "starter", 1, 10, 0, "midnight_intro")
Stub("starter_troll",       "Echo Isles",              "starter", 1, 10, 0, "midnight_intro")
Stub("starter_undead",      "Deathknell",              "starter", 1, 10, 0, "midnight_intro")
Stub("starter_tauren",      "Camp Narache",            "starter", 1, 10, 0, "midnight_intro")
Stub("starter_bloodelf",    "Sunstrider Isle",         "starter", 1, 10, 0, "midnight_intro")
Stub("starter_goblin",      "Kezan",                   "starter", 1, 10, 0, "midnight_intro")
Stub("starter_pandaren",    "Wandering Isle",          "starter", 1, 10, 0, "midnight_intro")
Stub("starter_dracthyr",    "Forbidden Reach",         "starter", 58, 60, 0, "hallowfall")
Stub("starter_dk",          "Acherus: Death Knight",   "starter", 8, 10, 0, "midnight_intro")
Stub("starter_dh",          "Mardum: Demon Hunter",    "starter", 8, 10, 0, "midnight_intro")

-- ═══════════════════════════════════════════════════════════════════════════════
-- BATTLE FOR AZEROTH (Level 10-50, default Chromie Time path)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("bfa_tiragarde",       "BFA: Tiragarde Sound",    "bfa", 10, 50, 942,  "bfa_drustvar")
Stub("bfa_drustvar",        "BFA: Drustvar",           "bfa", 10, 50, 896,  "bfa_stormsong")
Stub("bfa_stormsong",       "BFA: Stormsong Valley",   "bfa", 10, 50, 1161, nil)
Stub("bfa_zuldazar",        "BFA: Zuldazar",           "bfa", 10, 50, 862,  "bfa_nazmir")
Stub("bfa_nazmir",          "BFA: Nazmir",             "bfa", 10, 50, 863,  "bfa_voldun")
Stub("bfa_voldun",          "BFA: Vol'dun",            "bfa", 10, 50, 864,  nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHADOWLANDS (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("sl_bastion",          "SL: Bastion",             "sl", 10, 50, 1533, "sl_maldraxxus")
Stub("sl_maldraxxus",       "SL: Maldraxxus",         "sl", 10, 50, 1536, "sl_ardenweald")
Stub("sl_ardenweald",       "SL: Ardenweald",         "sl", 10, 50, 1565, "sl_revendreth")
Stub("sl_revendreth",       "SL: Revendreth",         "sl", 10, 50, 1525, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- DRAGONFLIGHT (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("df_waking_shores",    "DF: The Waking Shores",   "df", 10, 50, 2022, "df_ohnahran")
Stub("df_ohnahran",         "DF: Ohn'ahran Plains",    "df", 10, 50, 2023, "df_azure_span")
Stub("df_azure_span",       "DF: The Azure Span",      "df", 10, 50, 2024, "df_thaldraszus")
Stub("df_thaldraszus",      "DF: Thaldraszus",         "df", 10, 50, 2025, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LEGION (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("legion_azsuna",       "Legion: Azsuna",          "legion", 10, 50, 630, "legion_valsharah")
Stub("legion_valsharah",    "Legion: Val'sharah",      "legion", 10, 50, 641, "legion_highmountain")
Stub("legion_highmountain", "Legion: Highmountain",    "legion", 10, 50, 650, "legion_stormheim")
Stub("legion_stormheim",    "Legion: Stormheim",       "legion", 10, 50, 634, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- WARLORDS OF DRAENOR (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("wod_frostfire",       "WoD: Frostfire Ridge",    "wod", 10, 50, 525, "wod_gorgrond")
Stub("wod_shadowmoon",      "WoD: Shadowmoon Valley",  "wod", 10, 50, 539, "wod_gorgrond")
Stub("wod_gorgrond",        "WoD: Gorgrond",           "wod", 10, 50, 543, "wod_talador")
Stub("wod_talador",         "WoD: Talador",            "wod", 10, 50, 535, "wod_spires")
Stub("wod_spires",          "WoD: Spires of Arak",     "wod", 10, 50, 542, "wod_nagrand")
Stub("wod_nagrand",         "WoD: Nagrand",            "wod", 10, 50, 550, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- MISTS OF PANDARIA (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("mop_jade_forest",     "MoP: Jade Forest",        "mop", 10, 50, 371, "mop_krasarang")
Stub("mop_krasarang",       "MoP: Krasarang Wilds",    "mop", 10, 50, 418, "mop_kun_lai")
Stub("mop_kun_lai",         "MoP: Kun-Lai Summit",     "mop", 10, 50, 379, "mop_townlong")
Stub("mop_townlong",        "MoP: Townlong Steppes",   "mop", 10, 50, 388, "mop_dread_wastes")
Stub("mop_dread_wastes",    "MoP: Dread Wastes",       "mop", 10, 50, 422, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CATACLYSM (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("cata_hyjal",          "Cata: Mount Hyjal",       "cata", 10, 50, 198, "cata_deepholm")
Stub("cata_vashj",          "Cata: Vashj'ir",          "cata", 10, 50, 203, "cata_deepholm")
Stub("cata_deepholm",       "Cata: Deepholm",          "cata", 10, 50, 207, "cata_uldum")
Stub("cata_uldum",          "Cata: Uldum",             "cata", 10, 50, 249, "cata_twilight")
Stub("cata_twilight",       "Cata: Twilight Highlands", "cata", 10, 50, 241, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- WRATH OF THE LICH KING (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("wotlk_borean",        "WotLK: Borean Tundra",    "wotlk", 10, 50, 114, "wotlk_dragonblight")
Stub("wotlk_howling",       "WotLK: Howling Fjord",    "wotlk", 10, 50, 117, "wotlk_dragonblight")
Stub("wotlk_dragonblight",  "WotLK: Dragonblight",     "wotlk", 10, 50, 115, "wotlk_grizzly")
Stub("wotlk_grizzly",       "WotLK: Grizzly Hills",    "wotlk", 10, 50, 116, "wotlk_zuldrak")
Stub("wotlk_zuldrak",       "WotLK: Zul'Drak",         "wotlk", 10, 50, 121, "wotlk_sholazar")
Stub("wotlk_sholazar",      "WotLK: Sholazar Basin",   "wotlk", 10, 50, 119, "wotlk_storm_peaks")
Stub("wotlk_storm_peaks",   "WotLK: Storm Peaks",      "wotlk", 10, 50, 120, "wotlk_icecrown")
Stub("wotlk_icecrown",      "WotLK: Icecrown",         "wotlk", 10, 50, 118, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- BURNING CRUSADE (Level 10-50, Chromie Time)
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("tbc_hellfire",        "TBC: Hellfire Peninsula",  "tbc", 10, 50, 100, "tbc_zangarmarsh")
Stub("tbc_zangarmarsh",     "TBC: Zangarmarsh",        "tbc", 10, 50, 102, "tbc_terokkar")
Stub("tbc_terokkar",        "TBC: Terokkar Forest",    "tbc", 10, 50, 104, "tbc_nagrand")
Stub("tbc_nagrand",         "TBC: Nagrand",            "tbc", 10, 50, 107, "tbc_blades_edge")
Stub("tbc_blades_edge",     "TBC: Blade's Edge Mtns",  "tbc", 10, 50, 105, "tbc_netherstorm")
Stub("tbc_netherstorm",     "TBC: Netherstorm",        "tbc", 10, 50, 109, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLASSIC (Level 10-50, Chromie Time) — Main hubs only
-- ═══════════════════════════════════════════════════════════════════════════════
Stub("classic_westfall",    "Classic: Westfall",        "classic", 10, 50, 52,  "classic_redridge")
Stub("classic_redridge",    "Classic: Redridge Mtns",   "classic", 10, 50, 49,  "classic_duskwood")
Stub("classic_duskwood",    "Classic: Duskwood",        "classic", 10, 50, 47,  "classic_stv")
Stub("classic_stv",         "Classic: Stranglethorn",   "classic", 10, 50, 224, nil)
Stub("classic_barrens",     "Classic: The Barrens",     "classic", 10, 50, 63,  "classic_ashenvale")
Stub("classic_ashenvale",   "Classic: Ashenvale",       "classic", 10, 50, 63,  "classic_stonetalon")
Stub("classic_stonetalon",  "Classic: Stonetalon Mtns", "classic", 10, 50, 65,  nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- THE WAR WITHIN (Level 70-80)
-- ═══════════════════════════════════════════════════════════════════════════════
-- hallowfall is in its own file (TAG_Hallowfall.lua) — don't stub it
Stub("tww_isle_of_dorn",    "TWW: Isle of Dorn",       "warwithin", 70, 80, 2248, "tww_ringing_deeps")
Stub("tww_ringing_deeps",   "TWW: The Ringing Deeps",  "warwithin", 70, 80, 2214, "hallowfall")
Stub("tww_azj_kahet",       "TWW: Azj-Kahet",         "warwithin", 70, 80, 2255, nil)

-- ═══════════════════════════════════════════════════════════════════════════════
-- MIDNIGHT (Level 80-90) — Full guides in own TAG_ files, just ensure chaining
-- ═══════════════════════════════════════════════════════════════════════════════
-- midnight_intro, eversong_midnight, silvermoon_midnight, naigtal all in own files
