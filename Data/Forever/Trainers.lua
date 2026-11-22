-- ToonAge/Data/Forever/Trainers.lua
--
-- Sourced WoW Forever (1.60.1) Class Trainer & Mage Portal Trainer directory,
-- indexed by class and faction (Horde / Alliance), plus continent/zone metadata
-- for nearest-trainer routing and 1-click ForeverPins waypoints.
--
-- Pure data: zero executable logic, zero client API calls.
--
-- Sources (verified 2026-11-22):
--   * Warcraft Tavern Classic / Forever class & portal trainer directories
--   * Icy Veins Forever & Classic class trainer guides
--   * Live Forever 1.60.1 screenshot confirmation (Birgitte Cranston, Thunder Bluff:
--     Teleport: Thunder Bluff Lv 30 / Portal: Thunder Bluff Lv 50)
--   * Forever race/class expansions: Horde Undead Paladin (Undercity / Thunder Bluff;
--     none in Orgrimmar), Alliance Dwarf Shaman (Ironforge / Kharanos; none in
--     Stormwind or Darnassus).

local TA = ToonAge
TA.Data = TA.Data or {}

local SRC_WT = "https://www.warcrafttavern.com/wow-classic/guides/"
local SRC_IV = "https://www.icy-veins.com/wow-forever/"
local SRC_WF = "https://wowforever.one/"

-- Continent tags for clean same-continent matching when world coords are unavailable.
-- EK = Eastern Kingdoms, KAL = Kalimdor.
local ZONE_CONTINENT = {
    -- Eastern Kingdoms
    ["Undercity"]         = "EK",
    ["Tirisfal Glades"]   = "EK",
    ["Silverpine Forest"] = "EK",
    ["Hillsbrad Foothills"] = "EK",
    ["Alterac Mountains"] = "EK",
    ["Arathi Highlands"]  = "EK",
    ["Stormwind City"]    = "EK",
    ["Elwynn Forest"]     = "EK",
    ["Westfall"]          = "EK",
    ["Redridge Mountains"] = "EK",
    ["Duskwood"]          = "EK",
    ["Ironforge"]         = "EK",
    ["Dun Morogh"]        = "EK",
    ["Loch Modan"]        = "EK",
    ["Wetlands"]          = "EK",
    ["Stranglethorn Vale"] = "EK",
    ["Swamp of Sorrows"]  = "EK",
    ["Blasted Lands"]     = "EK",
    ["Badlands"]          = "EK",
    ["Searing Gorge"]     = "EK",
    ["Burning Steppes"]   = "EK",
    ["Western Plaguelands"] = "EK",
    ["Eastern Plaguelands"] = "EK",
    ["The Hinterlands"]   = "EK",
    -- Kalimdor
    ["Orgrimmar"]         = "KAL",
    ["Durotar"]           = "KAL",
    ["The Barrens"]       = "KAL",
    ["Thunder Bluff"]     = "KAL",
    ["Mulgore"]           = "KAL",
    ["Stonetalon Mountains"] = "KAL",
    ["Ashenvale"]         = "KAL",
    ["Thousand Needles"]  = "KAL",
    ["Desolace"]          = "KAL",
    ["Dustwallow Marsh"]  = "KAL",
    ["Feralas"]           = "KAL",
    ["Tanaris"]           = "KAL",
    ["Azshara"]           = "KAL",
    ["Felwood"]           = "KAL",
    ["Un'Goro Crater"]    = "KAL",
    ["Moonglade"]         = "KAL",
    ["Winterspring"]      = "KAL",
    ["Silithus"]          = "KAL",
    ["Darnassus"]         = "KAL",
    ["Teldrassil"]        = "KAL",
    ["Darkshore"]         = "KAL",
}

local function T(zone, district, x, y, cont, hub, npc, note)
    return {
        zone = zone,
        city = zone,
        district = district,
        name = (npc and (npc .. " (" .. zone .. ")")) or (zone .. " -- " .. district),
        npc = npc,
        x = x,
        y = y,
        continent = cont or ZONE_CONTINENT[zone],
        hubType = hub or "capital",
        note = note,
        source = SRC_WT,
    }
end

TA.Data.ForeverTrainers = {
    meta = {
        version = "1.60.1",
        schema = "forever-trainers-v1",
        sources = { SRC_WT, SRC_IV, SRC_WF },
    },
    zoneContinent = ZONE_CONTINENT,

    -- Explicit city-gap advisories so players never fly to a capital without their trainer.
    notes = {
        PALADIN = {
            Horde = "Undead Paladins train in Undercity (primary) or Thunder Bluff; there is NO Paladin trainer in Orgrimmar.",
            Alliance = "Train in Stormwind City (Cathedral Square) or Ironforge (Mystic Ward); no Paladin trainer in Darnassus.",
        },
        SHAMAN = {
            Horde = "Train in Orgrimmar (Valley of Wisdom), Thunder Bluff (Spirit Rise), Razor Hill, Bloodhoof Village, or The Crossroads; no Shaman trainer in Undercity.",
            Alliance = "Dwarf Shamans train in Ironforge (primary) or Kharanos; there is NO Shaman trainer in Stormwind or Darnassus (take Deeprun Tram to Ironforge).",
        },
        DRUID = {
            Horde = "Train in Thunder Bluff (Elder Rise), Bloodhoof Village, or Moonglade; there is NO Druid trainer in Orgrimmar or Undercity.",
            Alliance = "Train in Stormwind City (The Park), Darnassus (Cenarion Enclave), Dolanaar, or Moonglade; no Druid trainer in Ironforge.",
        },
        MAGE = {
            Horde = "Class trainers in Orgrimmar, Undercity, Thunder Bluff, Brill, and Razor Hill. Portal trainers are city-specific.",
            Alliance = "Class trainers in Stormwind City, Ironforge, Goldshire, and Kharanos; no Mage trainer in Darnassus.",
        },
        WARLOCK = {
            Horde = "Train in Orgrimmar (Cleft of Shadow), Undercity (Apothecarium), Brill, and Razor Hill; no Warlock trainer in Thunder Bluff.",
            Alliance = "Train in Stormwind City (Mage Quarter), Ironforge (Forlorn Cavern), Goldshire, and Kharanos; no Warlock trainer in Darnassus.",
        },
        ROGUE = {
            Horde = "Train in Orgrimmar (Cleft of Shadow), Undercity (Rogues' Quarter), Brill, and Razor Hill; no Rogue trainer in Thunder Bluff.",
            Alliance = "Train in Stormwind City (Old Town), Ironforge (Forlorn Cavern), Darnassus, Goldshire, Kharanos, and Dolanaar.",
        },
    },

    classes = {
        MAGE = {
            Horde = {
                T("Orgrimmar",       "Valley of Spirits", 36.0, 82.0, "KAL", "capital"),
                T("Thunder Bluff",   "Spirit Rise",       24.0, 21.0, "KAL", "capital"),
                T("Undercity",       "Magic Quarter",     85.0, 11.0, "EK",  "capital"),
                T("Tirisfal Glades", "Brill",             61.0, 52.0, "EK",  "town"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
            },
            Alliance = {
                T("Stormwind City",  "Mage Quarter",      40.0, 74.0, "EK",  "capital"),
                T("Ironforge",       "Mystic Ward",       26.0, 67.0, "EK",  "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
            },
        },
        WARRIOR = {
            Horde = {
                T("Orgrimmar",       "Valley of Honor",   76.0, 31.0, "KAL", "capital"),
                T("Thunder Bluff",   "Hunter's Rise",     45.0, 59.0, "KAL", "capital"),
                T("Undercity",       "War Quarter",       47.0, 14.0, "EK",  "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Mulgore",         "Bloodhoof Village", 46.0, 60.0, "KAL", "town"),
                T("Tirisfal Glades", "Brill",             61.0, 52.0, "EK",  "town"),
            },
            Alliance = {
                T("Stormwind City",  "Old Town",          79.0, 45.0, "EK",  "capital"),
                T("Ironforge",       "Hall of Arms",      70.0, 85.0, "EK",  "capital"),
                T("Darnassus",       "Warrior's Terrace", 40.0, 36.0, "KAL", "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
                T("Teldrassil",      "Dolanaar",          55.0, 60.0, "KAL", "town"),
            },
        },
        HUNTER = {
            Horde = {
                T("Orgrimmar",       "Valley of Honor",   69.0, 14.0, "KAL", "capital"),
                T("Thunder Bluff",   "Hunter's Rise",     59.0, 25.0, "KAL", "capital"),
                T("Undercity",       "Inner Ring",        59.0, 19.0, "EK",  "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Mulgore",         "Bloodhoof Village", 46.0, 60.0, "KAL", "town"),
            },
            Alliance = {
                T("Stormwind City",  "Dwarven District",  61.0, 16.0, "EK",  "capital"),
                T("Ironforge",       "Military Ward",     66.0, 88.0, "EK",  "capital"),
                T("Darnassus",       "Cenarion Enclave",  50.0, 39.0, "KAL", "capital"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
                T("Teldrassil",      "Dolanaar",          55.0, 60.0, "KAL", "town"),
            },
        },
        ROGUE = {
            Horde = {
                T("Orgrimmar",       "Cleft of Shadow",   41.0, 53.0, "KAL", "capital"),
                T("Undercity",       "Rogues' Quarter",   74.0, 48.0, "EK",  "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Tirisfal Glades", "Brill",             61.0, 52.0, "EK",  "town"),
            },
            Alliance = {
                T("Stormwind City",  "Old Town",          75.0, 53.0, "EK",  "capital"),
                T("Ironforge",       "Forlorn Cavern",    52.0, 14.0, "EK",  "capital"),
                T("Darnassus",       "Craftsmen's Terrace", 37.0, 21.0, "KAL", "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
                T("Teldrassil",      "Dolanaar",          55.0, 60.0, "KAL", "town"),
            },
        },
        PRIEST = {
            Horde = {
                T("Orgrimmar",       "Valley of Spirits", 36.0, 85.0, "KAL", "capital"),
                T("Thunder Bluff",   "Spirit Rise",       24.0, 15.0, "KAL", "capital"),
                T("Undercity",       "War / Magic Ring",  47.0, 72.0, "EK",  "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Tirisfal Glades", "Brill",             61.0, 52.0, "EK",  "town"),
            },
            Alliance = {
                T("Stormwind City",  "Cathedral Square",  41.0, 26.0, "EK",  "capital"),
                T("Ironforge",       "Mystic Ward",       28.0, 59.0, "EK",  "capital"),
                T("Darnassus",       "Temple of the Moon", 39.0, 85.0, "KAL", "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
                T("Teldrassil",      "Dolanaar",          55.0, 60.0, "KAL", "town"),
            },
        },
        WARLOCK = {
            Horde = {
                T("Orgrimmar",       "Cleft of Shadow",   48.0, 45.0, "KAL", "capital"),
                T("Undercity",       "Magic Quarter",     85.0, 16.0, "EK",  "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Tirisfal Glades", "Brill",             61.0, 52.0, "EK",  "town"),
            },
            Alliance = {
                T("Stormwind City",  "Mage Quarter",      30.0, 80.0, "EK",  "capital"),
                T("Ironforge",       "Forlorn Cavern",    51.0, 10.0, "EK",  "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
            },
        },
        SHAMAN = {
            Horde = {
                T("Orgrimmar",       "Valley of Wisdom",  33.0, 38.0, "KAL", "capital"),
                T("Thunder Bluff",   "Spirit Rise",       22.0, 23.0, "KAL", "capital"),
                T("Durotar",         "Razor Hill",        52.0, 43.0, "KAL", "town"),
                T("Mulgore",         "Bloodhoof Village", 46.0, 60.0, "KAL", "town"),
                T("The Barrens",     "The Crossroads",    52.0, 30.0, "KAL", "town"),
            },
            Alliance = {
                T("Ironforge",       "Great Forge / Mystic", 55.0, 30.0, "EK", "capital",
                    "Eldrun Stormbreaker", "Forever Dwarf Shaman hub; no Shaman trainer in Stormwind or Darnassus."),
                T("Dun Morogh",      "Kharanos",          46.0, 52.0, "EK",  "town"),
            },
        },
        PALADIN = {
            Horde = {
                T("Undercity",       "War Quarter",       58.0, 90.0, "EK",  "capital",
                    "Garen Largo", "Primary Forever Undead Paladin hub; no Paladin trainer in Orgrimmar."),
                T("Thunder Bluff",   "Spirit Rise Enclave", 24.0, 20.0, "KAL", "capital",
                    nil, "Kalimdor Horde Paladin trainer; no Paladin trainer in Orgrimmar."),
            },
            Alliance = {
                T("Stormwind City",  "Cathedral Square",  55.0, 54.0, "EK",  "capital"),
                T("Ironforge",       "Mystic Ward",       25.0, 4.0,  "EK",  "capital"),
                T("Elwynn Forest",   "Goldshire",         42.0, 65.0, "EK",  "town"),
            },
        },
        DRUID = {
            Horde = {
                T("Thunder Bluff",   "Elder Rise",        77.0, 29.0, "KAL", "capital"),
                T("Mulgore",         "Bloodhoof Village", 46.0, 60.0, "KAL", "town"),
                T("Moonglade",       "Nighthaven",        52.0, 40.0, "KAL", "town"),
            },
            Alliance = {
                T("Stormwind City",  "The Park",          36.0, 64.0, "EK",  "capital"),
                T("Darnassus",       "Cenarion Enclave",  35.0, 11.0, "KAL", "capital"),
                T("Teldrassil",      "Dolanaar",          55.0, 60.0, "KAL", "town"),
                T("Moonglade",       "Nighthaven",        52.0, 40.0, "KAL", "town"),
            },
        },
    },

    -- Mage city-specific Portal Trainers (self Teleports at Lv 20/30/50, group Portals at Lv 40/50).
    magePortals = {
        {
            name = "Teleport: Orgrimmar", kind = "Teleport", side = "Horde", level = 20,
            npc = "Thuul", zone = "Orgrimmar", district = "Valley of Spirits (Spirit Lodge 2F)",
            x = 38.6, y = 85.8, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Undercity", kind = "Teleport", side = "Horde", level = 20,
            npc = "Lexington Mortaim", zone = "Undercity", district = "Magic Quarter (Upper Ring)",
            x = 84.6, y = 16.8, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Thunder Bluff", kind = "Teleport", side = "Horde", level = 30,
            npc = "Birgitte Cranston", zone = "Thunder Bluff", district = "Spirit Rise",
            x = 22.4, y = 16.4, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Orgrimmar", kind = "Portal", side = "Horde", level = 40,
            npc = "Thuul", zone = "Orgrimmar", district = "Valley of Spirits (Spirit Lodge 2F)",
            x = 38.6, y = 85.8, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Undercity", kind = "Portal", side = "Horde", level = 40,
            npc = "Lexington Mortaim", zone = "Undercity", district = "Magic Quarter (Upper Ring)",
            x = 84.6, y = 16.8, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Thunder Bluff", kind = "Portal", side = "Horde", level = 50,
            npc = "Birgitte Cranston", zone = "Thunder Bluff", district = "Spirit Rise",
            x = 22.4, y = 16.4, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Stormwind", kind = "Teleport", side = "Alliance", level = 20,
            npc = "Larimaine Purdue", zone = "Stormwind City", district = "Mage Quarter (Wizard's Sanctum)",
            x = 50.3, y = 86.0, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Ironforge", kind = "Teleport", side = "Alliance", level = 20,
            npc = "Milstaff Stormeye", zone = "Ironforge", district = "Mystic Ward (Hall of Mysteries)",
            x = 26.0, y = 8.6, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Darnassus", kind = "Teleport", side = "Alliance", level = 30,
            npc = "Elissa Dumas", zone = "Darnassus", district = "Temple of the Moon",
            x = 40.6, y = 82.0, reagent = "Rune of Teleportation", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Stormwind", kind = "Portal", side = "Alliance", level = 40,
            npc = "Larimaine Purdue", zone = "Stormwind City", district = "Mage Quarter (Wizard's Sanctum)",
            x = 50.3, y = 86.0, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Ironforge", kind = "Portal", side = "Alliance", level = 40,
            npc = "Milstaff Stormeye", zone = "Ironforge", district = "Mystic Ward (Hall of Mysteries)",
            x = 26.0, y = 8.6, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Portal: Darnassus", kind = "Portal", side = "Alliance", level = 50,
            npc = "Elissa Dumas", zone = "Darnassus", district = "Temple of the Moon",
            x = 40.6, y = 82.0, reagent = "Rune of Portals", verified = true, source = SRC_WT,
        },
        {
            name = "Teleport: Dalaran", kind = "Teleport", side = "Both", level = 50,
            npc = "Violet Citadel Portal Trainer", zone = "Alterac Mountains", district = "Dalaran (Violet Citadel)",
            x = 18.0, y = 78.0, reagent = "Rune of Teleportation", verified = false, source = SRC_WF,
        },
    },
}
