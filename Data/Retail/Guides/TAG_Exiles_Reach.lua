-- ToonAge guide data: Exile's Reach (Retail New Player Experience, levels 1-10)
-- Generated 2026-10-08 for /workspace/wow-kb. Format: { type, questID, text, [class], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
--
-- VERIFICATION / SOURCES
--  * questIDs + order: Azeroth Pilot Reloaded route files Routes/ExilesReach/ExilesReach_{Alliance,Horde}.lua
--    (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, last commit 2026-10-07 UTC).
--  * Quest names: every questID was checked against Wowhead's tooltip API (nether.wowhead.com/tooltip/quest/<id>) on 2026-10-08.
--  * accept coords: quest giver ("provider") coords from AllTheThings
--    (.contrib/.db/standard/02 - Outdoor Zones/Exiles Reach.lua, github.com/ATTWoWAddon/AllTheThings) where present.
--  * quest/turnin coords (and accepts ATT lacks): APR world coords converted to uiMap 1409 percent with a linear fit
--    calibrated on 110 APR pickup points vs ATT giver coords: mapX = -0.0296016*aprX - 15.4388 ; mapY = -0.0443813*aprY + 63.5575
--    (max residual 0.39 map-%, median 0.04). These are derived, not hand-measured; spot-check in game with CoordHarvester.
--  * Ship quests (Warming Up / Stand Your Ground / Brace for Impact) happen on the boat maps 1726 (Alliance) / 1727 (Horde);
--    no reliable coords, so coord = nil.
--  * Post-11.2.7: Lady Jaina Proudmoore / Thrall replace Captain Garrick / Warlord Breka Grimaxe as some givers (ATT notes);
--    "Forbidden Quilboar Necromancy" renamed "Forbidden Quilboar Shadow Magic". The 11.2.7 "What's Your Specialty?" /
--    "Home Is Where the Hearth Is" / "Aiding the Dragon Isles" (Kalecgos, The Waking Shores) and the old capital-city
--    spec quests are NOT part of the APR route and are omitted here. Midnight (12.x) changes to the NPE: UNVERIFIED.
--  * DK / DH / Evoker cannot start in Exile's Reach.
--
-- AUDIT OF THE OLD TAG_Exiles_Reach.lua (hand-written file in the ToonAge addon)
--  1. Faction mix-up: questIDs 59926-59984 are the HORDE versions, but 55991 (An End to Beginnings) is the ALLIANCE one
--     (Horde = 59985). The file has no faction field, so Alliance players would never match the Horde IDs.
--  2. "Choose Your Specialization" block is wrong: 90840 = Horde 11.2.7 "What's Your Specialty?" (not Warrior-only);
--     60343 = "Welcome to Orgrimmar", 60344 = "Finding Your Way", 60345 = "License to Ride" (not DK/Paladin/Hunter spec quests);
--     60346-60353/60355/60357 are Horde capital class quests mapped to the WRONG classes (60346 = Druid, 60347 = Hunter,
--     60348 = Mage, 60349 = Monk, 60350 = Paladin, 60351 = Priest, 60352 = Rogue, 60353 = Shaman, 60355 = Warlock, 60357 = Warrior)
--     and were REMOVED in 11.2.7 (ATT timeline). 90843 = "Aiding the Dragon Isles", not an Evoker quest. DK/DH/Evoker entries are impossible.
--  3. 59933 "Enhanced Combat Tactics" is the non-Monk version (Monk = 59934); 59937 "Taming the Wilds" is Hunter-only.
--  4. "Brace for Impact" (59928) is a talk-to quest with an immediate turn-in, not a cutscene objective; ship quests are not on map 1409.
--  5. Every coordinate in that file is wrong (e.g. Murloc Mania giver is 61.8,82.8 not 58,82; Darkmaul quests are at ~40,32, not 20-26,48-58).
--  6. Objective text ("Kill 6 Murlocs", "Kill 8 Quilboar", "Destroy 3 Shadow Totems", "Cook 4 Boar Ribs") is invented.
--  7. Missing quests: Choppy Booster Mk. 5 (59940), Re-sizing the Situation (59941), The Re-Deather (59942), Stocking Up on Supplies (59950),
--     all class trainer quests, Harpy Culling (59945), Purge the Totems (59946), Westward Bound (59948), Who Lurks in the Pit (59949),
--     Freeing the Light (54933), Killclaw the Terrible (56839), Controlling Their Stones (59981), Adventurers Wanted: Chromie's Call (62568).
--  The APR-derived TAG_ExilesReach_{Alliance,Horde}.lua files already have CORRECT questIDs (matched to APR) but all coords are 0,0.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["exiles_reach_alliance"] = {
    id = "exiles_reach_alliance", title = "Exile's Reach (Alliance)", faction = "Alliance", expansion = "starter",
    zone = 1409, minLevel = 1, maxLevel = 10,
    nextGuide = nil, -- APR continues to "84-DF01A-Stormwind" (Dragonflight-intro route); set to your own guide id
    steps = {
        { type = "accept", questID = 56775, text = "Warming Up",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "quest", questID = 56775, text = "Warming Up (objective 1)",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "turnin", questID = 56775, text = "Turn in: Warming Up",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "accept", questID = 58209, text = "Stand Your Ground",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "quest", questID = 58209, text = "Stand Your Ground (objective 1)",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "turnin", questID = 58209, text = "Turn in: Stand Your Ground",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "accept", questID = 58208, text = "Brace for Impact",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "turnin", questID = 58208, text = "Turn in: Brace for Impact",
          coord = nil },  -- no 1409 coord (ship map 1726)
        { type = "accept", questID = 55122, text = "Murloc Mania",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 55122, text = "Murloc Mania (objective 1)",
          coord = { map = 1409, x = 0.604, y = 0.795 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55122, text = "Turn in: Murloc Mania",
          coord = { map = 1409, x = 0.618, y = 0.829 } },  -- coord: APR route (converted)
        { type = "accept", questID = 54951, text = "Emergency First Aid",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 54951, text = "Emergency First Aid (objective 2)",
          coord = { map = 1409, x = 0.617, y = 0.834 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54951, text = "Emergency First Aid (objective 3)",
          coord = { map = 1409, x = 0.613, y = 0.826 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54951, text = "Emergency First Aid (objective 1)",
          coord = { map = 1409, x = 0.615, y = 0.822 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 54951, text = "Turn in: Emergency First Aid",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- coord: APR route (converted)
        { type = "accept", questID = 54952, text = "Finding the Lost Expedition",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 54952, text = "Finding the Lost Expedition (objective 1)",
          coord = { map = 1409, x = 0.584, y = 0.757 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 54952, text = "Turn in: Finding the Lost Expedition",
          coord = { map = 1409, x = 0.583, y = 0.744 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55174, text = "Cooking Meat",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 55174, text = "Cooking Meat (objective 1)",
          coord = { map = 1409, x = 0.585, y = 0.717 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55174, text = "Cooking Meat (objective 2)",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55174, text = "Turn in: Cooking Meat",
          coord = { map = 1409, x = 0.583, y = 0.744 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "DRUID",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "DRUID",
          coord = { map = 1409, x = 0.592, y = 0.729 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "DRUID",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55173, text = "Northbound", class = "HUNTER",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- giver coord: ATT
        { type = "turnin", questID = 55173, text = "Turn in: Northbound", class = "HUNTER",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59342, text = "Taming the Wilds", class = "HUNTER",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 59342, text = "Taming the Wilds (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.608, y = 0.711 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59342, text = "Turn in: Taming the Wilds", class = "HUNTER",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "MAGE",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.575, y = 0.723 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "MAGE",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59339, text = "Enhanced Combat Tactics", class = "MONK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59339, text = "Enhanced Combat Tactics (objective 1,2)", class = "MONK",
          coord = { map = 1409, x = 0.580, y = 0.722 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59339, text = "Turn in: Enhanced Combat Tactics", class = "MONK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "PALADIN",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.592, y = 0.729 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "PALADIN",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "PRIEST",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.579, y = 0.734 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "PRIEST",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "ROGUE",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.593, y = 0.735 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "ROGUE",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55173, text = "Northbound", class = "ROGUE",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- giver coord: ATT
        { type = "turnin", questID = 55173, text = "Turn in: Northbound", class = "ROGUE",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "SHAMAN",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "SHAMAN",
          coord = { map = 1409, x = 0.577, y = 0.728 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "SHAMAN",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "WARLOCK",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "WARLOCK",
          coord = { map = 1409, x = 0.579, y = 0.734 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "WARLOCK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59254, text = "Enhanced Combat Tactics", class = "WARRIOR",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59254, text = "Enhanced Combat Tactics (objective 1)", class = "WARRIOR",
          coord = { map = 1409, x = 0.575, y = 0.723 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59254, text = "Turn in: Enhanced Combat Tactics", class = "WARRIOR",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55173, text = "Northbound",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- giver coord: ATT
        { type = "turnin", questID = 55173, text = "Turn in: Northbound",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55186, text = "Down with the Quilboar",
          coord = { map = 1409, x = 0.627, y = 0.699 } },  -- giver coord: ATT
        { type = "accept", questID = 55184, text = "Quilboar Shadow Magic",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 55184, text = "Quilboar Shadow Magic (objective 1)",
          coord = { map = 1409, x = 0.603, y = 0.616 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55186, text = "Down with the Quilboar (objective 1)",
          coord = { map = 1409, x = 0.589, y = 0.629 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55186, text = "Turn in: Down with the Quilboar",
          coord = { map = 1409, x = 0.562, y = 0.591 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55184, text = "Turn in: Quilboar Shadow Magic",
          coord = { map = 1409, x = 0.562, y = 0.591 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55193, text = "The Scout-o-Matic 5000",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 55193, text = "The Scout-o-Matic 5000 (objective 1)",
          coord = { map = 1409, x = 0.560, y = 0.588 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55193, text = "Turn in: The Scout-o-Matic 5000",
          coord = { map = 1409, x = 0.561, y = 0.590 } },  -- coord: APR route (converted)
        { type = "accept", questID = 56034, text = "Re-sizing the Situation",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 56034, text = "Re-sizing the Situation (objective 1)",
          coord = { map = 1409, x = 0.568, y = 0.583 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 56034, text = "Turn in: Re-sizing the Situation",
          coord = { map = 1409, x = 0.562, y = 0.590 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55879, text = "Ride of the Scientifically Enhanced Boar",
          coord = { map = 1409, x = 0.562, y = 0.590 } },  -- giver coord: ATT
        { type = "quest", questID = 55879, text = "Ride of the Scientifically Enhanced Boar (objective 1)",
          coord = { map = 1409, x = 0.564, y = 0.584 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55879, text = "Ride of the Scientifically Enhanced Boar (objective 2)",
          coord = { map = 1409, x = 0.527, y = 0.541 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55879, text = "Ride of the Scientifically Enhanced Boar (objective 3)",
          coord = { map = 1409, x = 0.510, y = 0.527 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55879, text = "Turn in: Ride of the Scientifically Enhanced Boar",
          coord = { map = 1409, x = 0.525, y = 0.533 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55194, text = "Stocking Up on Supplies",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- giver coord: ATT
        { type = "quest", questID = 55194, text = "Stocking Up on Supplies (objective 1,2)",
          coord = { map = 1409, x = 0.522, y = 0.552 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55194, text = "Turn in: Stocking Up on Supplies",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59355, text = "A Hunter's Trap", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59352, text = "A Mage's Knowledge", class = "MAGE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59347, text = "A Monk's Focus", class = "MONK",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 58923, text = "A Paladin's Service", class = "PALADIN",
          coord = { map = 1409, x = 0.520, y = 0.554 } },  -- giver coord: ATT
        { type = "accept", questID = 58953, text = "A Priest's End", class = "PRIEST",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 58917, text = "A Rogue's End", class = "ROGUE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59002, text = "A Shaman's Duty", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.556 } },  -- giver coord: ATT
        { type = "accept", questID = 58962, text = "A Warlock's Bargain", class = "WARLOCK",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 58914, text = "A Warrior's End", class = "WARRIOR",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59350, text = "A Druid's Form", class = "DRUID",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 59350, text = "A Druid's Form (objective 1)", class = "DRUID",
          coord = { map = 1409, x = 0.453, y = 0.492 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59350, text = "Turn in: A Druid's Form", class = "DRUID",
          coord = { map = 1409, x = 0.454, y = 0.492 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59355, text = "A Hunter's Trap (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59355, text = "A Hunter's Trap (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.522, y = 0.530 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59355, text = "A Hunter's Trap (objective 3)", class = "HUNTER",
          coord = { map = 1409, x = 0.518, y = 0.516 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59355, text = "Turn in: A Hunter's Trap", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59356, text = "Hunting the Stalker", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 59356, text = "Hunting the Stalker (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.518, y = 0.534 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59356, text = "Turn in: Hunting the Stalker", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "accept", questID = 60168, text = "The Art of Taming", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 60168, text = "The Art of Taming (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 60168, text = "The Art of Taming (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 60168, text = "The Art of Taming (objective 3)", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 60168, text = "Turn in: The Art of Taming", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59352, text = "A Mage's Knowledge (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.519, y = 0.498 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59352, text = "Turn in: A Mage's Knowledge", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59354, text = "The Best Way to Use Sheep", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- giver coord: ATT
        { type = "quest", questID = 59354, text = "The Best Way to Use Sheep (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59354, text = "The Best Way to Use Sheep (objective 2)", class = "MAGE",
          coord = { map = 1409, x = 0.536, y = 0.556 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59354, text = "Turn in: The Best Way to Use Sheep", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59347, text = "A Monk's Focus (objective 1)", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.495 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59347, text = "Turn in: A Monk's Focus", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.494 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59349, text = "One Last Spar", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.494 } },  -- giver coord: ATT
        { type = "quest", questID = 59349, text = "One Last Spar (objective 1)", class = "MONK",
          coord = { map = 1409, x = 0.534, y = 0.498 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59349, text = "Turn in: One Last Spar", class = "MONK",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55965, text = "Westward Bound",
          coord = { map = 1409, x = 0.530, y = 0.550 } },  -- giver coord: ATT
        { type = "quest", questID = 58953, text = "A Priest's End (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.537 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58953, text = "Turn in: A Priest's End", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.537 } },  -- coord: APR route (converted)
        { type = "accept", questID = 58960, text = "Resurrecting the Recruits", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- giver coord: ATT
        { type = "quest", questID = 58960, text = "Resurrecting the Recruits (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.562, y = 0.534 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58960, text = "Turn in: Resurrecting the Recruits", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58917, text = "A Rogue's End (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58917, text = "A Rogue's End (objective 2)", class = "ROGUE",
          coord = { map = 1409, x = 0.449, y = 0.553 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58917, text = "Turn in: A Rogue's End", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- coord: APR route (converted)
        { type = "accept", questID = 58933, text = "The Deadliest of Poisons", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- giver coord: ATT
        { type = "quest", questID = 58933, text = "The Deadliest of Poisons (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.558 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58933, text = "The Deadliest of Poisons (objective 2)", class = "ROGUE",
          coord = { map = 1409, x = 0.485, y = 0.515 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58933, text = "Turn in: The Deadliest of Poisons", class = "ROGUE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59002, text = "A Shaman's Duty (objective 1)", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.513 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59002, text = "A Shaman's Duty (objective 2)", class = "SHAMAN",
          coord = { map = 1409, x = 0.522, y = 0.555 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59002, text = "A Shaman's Duty (objective 3)", class = "SHAMAN",
          coord = { map = 1409, x = 0.542, y = 0.570 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59002, text = "Turn in: A Shaman's Duty", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.556 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55196, text = "The Harpy Problem",
          coord = { map = 1409, x = 0.535, y = 0.523 } },  -- giver coord: ATT
        { type = "quest", questID = 58962, text = "A Warlock's Bargain (objective 1)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.459 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58962, text = "A Warlock's Bargain (objective 2)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.458 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58962, text = "A Warlock's Bargain (objective 3)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.458 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58914, text = "Turn in: A Warrior's End", class = "WARRIOR",
          coord = { map = 1409, x = 0.514, y = 0.478 } },  -- coord: APR route (converted)
        { type = "accept", questID = 58915, text = "Hjalmar's Final Execution", class = "WARRIOR",
          coord = { map = 1409, x = 0.515, y = 0.478 } },  -- giver coord: ATT
        { type = "quest", questID = 58915, text = "Hjalmar's Final Execution (objective 1)", class = "WARRIOR",
          coord = { map = 1409, x = 0.514, y = 0.478 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55196, text = "Turn in: The Harpy Problem",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55763, text = "The Rescue of Meredy Huntswell",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- giver coord: ATT
        { type = "accept", questID = 55881, text = "Purge the Totems",
          coord = { map = 1409, x = 0.569, y = 0.462 } },  -- giver coord: ATT
        { type = "accept", questID = 55764, text = "Harpy Culling",
          coord = { map = 1409, x = 0.569, y = 0.462 } },  -- giver coord: ATT
        { type = "quest", questID = 55763, text = "The Rescue of Meredy Huntswell (objective 1)",
          coord = { map = 1409, x = 0.542, y = 0.415 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55764, text = "Harpy Culling (objective 1)",
          coord = { map = 1409, x = 0.588, y = 0.415 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55763, text = "Turn in: The Rescue of Meredy Huntswell",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55764, text = "Turn in: Harpy Culling",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55881, text = "Turn in: Purge the Totems",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55882, text = "Message to Base",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- giver coord: ATT
        { type = "accept", questID = 54933, text = "Freeing the Light",
          coord = { map = 1409, x = 0.581, y = 0.502 } },  -- giver coord: ATT
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 1)",
          coord = { map = 1409, x = 0.574, y = 0.496 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 2)",
          coord = { map = 1409, x = 0.584, y = 0.491 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 3)",
          coord = { map = 1409, x = 0.590, y = 0.506 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 4)",
          coord = { map = 1409, x = 0.578, y = 0.511 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58923, text = "A Paladin's Service (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58923, text = "Turn in: A Paladin's Service", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "accept", questID = 58946, text = "The Divine's Shield", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.522 } },  -- giver coord: ATT
        { type = "quest", questID = 58946, text = "The Divine's Shield (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "quest", questID = 58946, text = "The Divine's Shield (objective 2)", class = "PALADIN",
          coord = { map = 1409, x = 0.571, y = 0.526 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58946, text = "Turn in: The Divine's Shield", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.522 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 54933, text = "Turn in: Freeing the Light",
          coord = { map = 1409, x = 0.581, y = 0.501 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55882, text = "Turn in: Message to Base",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58962, text = "Turn in: A Warlock's Bargain", class = "WARLOCK",
          coord = { map = 1409, x = 0.526, y = 0.454 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 58915, text = "Turn in: Hjalmar's Final Execution", class = "WARRIOR",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55965, text = "Turn in: Westward Bound",
          coord = { map = 1409, x = 0.511, y = 0.595 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55639, text = "Who Lurks in the Pit",
          coord = { map = 1409, x = 0.511, y = 0.595 } },  -- giver coord: ATT
        { type = "quest", questID = 55639, text = "Who Lurks in the Pit (objective 1)",
          coord = { map = 1409, x = 0.509, y = 0.604 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55639, text = "Who Lurks in the Pit (objective 2)",
          coord = { map = 1409, x = 0.475, y = 0.603 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55639, text = "Who Lurks in the Pit (objective 3)",
          coord = { map = 1409, x = 0.477, y = 0.602 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55639, text = "Turn in: Who Lurks in the Pit",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 56344, text = "To Darkmaul Citadel",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- giver coord: ATT
        { type = "accept", questID = 56839, text = "Killclaw the Terrible",
          coord = { map = 1409, x = 0.487, y = 0.542 } },  -- giver coord: ATT
        { type = "quest", questID = 56839, text = "Killclaw the Terrible (objective 1)",
          coord = { map = 1409, x = 0.455, y = 0.545 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 56839, text = "Turn in: Killclaw the Terrible",
          coord = { map = 1409, x = 0.434, y = 0.511 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 56344, text = "Turn in: To Darkmaul Citadel",
          coord = { map = 1409, x = 0.489, y = 0.492 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55981, text = "Right Beneath Their Eyes",
          coord = { map = 1409, x = 0.489, y = 0.492 } },  -- giver coord: ATT
        { type = "quest", questID = 55981, text = "Right Beneath Their Eyes (objective 1)",
          coord = { map = 1409, x = 0.490, y = 0.492 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55981, text = "Right Beneath Their Eyes (objective 2)",
          coord = { map = 1409, x = 0.451, y = 0.433 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55981, text = "Right Beneath Their Eyes (objective 3)",
          coord = { map = 1409, x = 0.456, y = 0.380 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55981, text = "Right Beneath Their Eyes (objective 4)",
          coord = { map = 1409, x = 0.456, y = 0.375 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55981, text = "Turn in: Right Beneath Their Eyes",
          coord = { map = 1409, x = 0.401, y = 0.323 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55988, text = "Like Ogres to the Slaughter",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- giver coord: ATT
        { type = "accept", questID = 55990, text = "Controlling their Stones",
          coord = { map = 1409, x = 0.401, y = 0.323 } },  -- giver coord: ATT
        { type = "accept", questID = 55989, text = "Catapult Destruction",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- giver coord: ATT
        { type = "quest", questID = 55990, text = "Controlling their Stones (objective 2)",
          coord = { map = 1409, x = 0.440, y = 0.373 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55990, text = "Controlling their Stones (objective 1)",
          coord = { map = 1409, x = 0.475, y = 0.343 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55990, text = "Controlling their Stones (objective 3)",
          coord = { map = 1409, x = 0.427, y = 0.408 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55989, text = "Catapult Destruction (objective 1)",
          coord = { map = 1409, x = 0.449, y = 0.411 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55988, text = "Like Ogres to the Slaughter (objective 1)",
          coord = { map = 1409, x = 0.463, y = 0.365 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55989, text = "Turn in: Catapult Destruction",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55988, text = "Turn in: Like Ogres to the Slaughter",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- coord: APR route (converted)
        { type = "quest", questID = 55990, text = "Controlling their Stones (objective 4)",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55990, text = "Turn in: Controlling their Stones",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55992, text = "Dungeon: Darkmaul Citadel",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- giver coord: ATT
        { type = "quest", questID = 55992, text = "Dungeon: Darkmaul Citadel (objective 1)",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55992, text = "Turn in: Dungeon: Darkmaul Citadel",
          coord = { map = 1409, x = 0.396, y = 0.319 } },  -- coord: APR route (converted)
        { type = "accept", questID = 55991, text = "An End to Beginnings",
          coord = { map = 1409, x = 0.396, y = 0.319 } },  -- giver coord: ATT
        { type = "quest", questID = 55991, text = "An End to Beginnings (objective 1)",
          coord = { map = 1409, x = 0.403, y = 0.326 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 55991, text = "Turn in: An End to Beginnings",
          coord = nil },  -- outside Exile's Reach (uiMap 84); coord not converted
        { type = "accept", questID = 62567, text = "Adventurers Wanted: Chromie's Call (leave tutorial, say Yes to gossip)",
          coord = nil },  -- outside Exile's Reach (uiMap 84); coord not converted
        { type = "turnin", questID = 62567, text = "Turn in: Adventurers Wanted: Chromie's Call",
          coord = nil },  -- outside Exile's Reach (uiMap 84); coord not converted
    },
}

TA.GuideData["exiles_reach_horde"] = {
    id = "exiles_reach_horde", title = "Exile's Reach (Horde)", faction = "Horde", expansion = "starter",
    zone = 1409, minLevel = 1, maxLevel = 10,
    nextGuide = nil, -- APR continues to "85-DF01H-Orgrimmar" (Dragonflight-intro route); set to your own guide id
    steps = {
        { type = "accept", questID = 59926, text = "Warming Up",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "quest", questID = 59926, text = "Warming Up (objective 1)",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "turnin", questID = 59926, text = "Turn in: Warming Up",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "accept", questID = 59927, text = "Stand Your Ground",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "quest", questID = 59927, text = "Stand Your Ground (objective 1)",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "turnin", questID = 59927, text = "Turn in: Stand Your Ground",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "accept", questID = 59928, text = "Brace for Impact",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "turnin", questID = 59928, text = "Turn in: Brace for Impact",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "accept", questID = 59929, text = "Murloc Mania",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 59929, text = "Murloc Mania (objective 1)",
          coord = { map = 1409, x = 0.604, y = 0.798 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59929, text = "Turn in: Murloc Mania",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59930, text = "Emergency First Aid",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 59930, text = "Emergency First Aid (objective 2)",
          coord = { map = 1409, x = 0.617, y = 0.834 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59930, text = "Emergency First Aid (objective 3)",
          coord = { map = 1409, x = 0.613, y = 0.826 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59930, text = "Emergency First Aid (objective 1)",
          coord = { map = 1409, x = 0.615, y = 0.822 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59930, text = "Turn in: Emergency First Aid",
          coord = { map = 1409, x = 0.618, y = 0.829 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59931, text = "Finding the Lost Expedition",
          coord = { map = 1409, x = 0.618, y = 0.828 } },  -- giver coord: ATT
        { type = "quest", questID = 59931, text = "Finding the Lost Expedition (objective 1,4)",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59931, text = "Turn in: Finding the Lost Expedition",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59932, text = "Cooking Meat",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59932, text = "Cooking Meat (objective 1)",
          coord = { map = 1409, x = 0.579, y = 0.717 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59932, text = "Cooking Meat (objective 2)",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59932, text = "Turn in: Cooking Meat",
          coord = { map = 1409, x = 0.583, y = 0.744 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "DRUID",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "DRUID",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "DRUID",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59937, text = "Taming the Wilds", class = "HUNTER",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 59937, text = "Taming the Wilds (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.608, y = 0.711 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59937, text = "Turn in: Taming the Wilds", class = "HUNTER",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "MAGE",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "MAGE",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59934, text = "Enhanced Combat Tactics", class = "MONK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59934, text = "Enhanced Combat Tactics (objective 1,2)", class = "MONK",
          coord = { map = 1409, x = 0.580, y = 0.722 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59934, text = "Turn in: Enhanced Combat Tactics", class = "MONK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "PALADIN",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "PALADIN",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "PRIEST",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "PRIEST",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "ROGUE",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "ROGUE",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "SHAMAN",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "SHAMAN",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "SHAMAN",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "WARLOCK",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "WARLOCK",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "WARLOCK",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59933, text = "Enhanced Combat Tactics", class = "WARRIOR",
          coord = { map = 1409, x = 0.584, y = 0.746 } },  -- giver coord: ATT
        { type = "quest", questID = 59933, text = "Enhanced Combat Tactics (objective 1)", class = "WARRIOR",
          coord = { map = 1409, x = 0.580, y = 0.740 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59933, text = "Turn in: Enhanced Combat Tactics", class = "WARRIOR",
          coord = { map = 1409, x = 0.583, y = 0.746 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59935, text = "Northbound",
          coord = { map = 1409, x = 0.583, y = 0.745 } },  -- giver coord: ATT
        { type = "turnin", questID = 59935, text = "Turn in: Northbound",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59938, text = "Down with the Quilboar",
          coord = { map = 1409, x = 0.627, y = 0.699 } },  -- giver coord: ATT
        { type = "accept", questID = 59939, text = "Forbidden Quilboar Shadow Magic",
          coord = { map = 1409, x = 0.627, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 59938, text = "Down with the Quilboar (objective 1)",
          coord = { map = 1409, x = 0.589, y = 0.628 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59939, text = "Forbidden Quilboar Shadow Magic (objective 1)",
          coord = { map = 1409, x = 0.609, y = 0.613 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59938, text = "Turn in: Down with the Quilboar",
          coord = { map = 1409, x = 0.562, y = 0.591 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59939, text = "Turn in: Forbidden Quilboar Shadow Magic",
          coord = { map = 1409, x = 0.562, y = 0.591 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59940, text = "The Choppy Booster Mk. 5",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 59940, text = "The Choppy Booster Mk. 5 (objective 1)",
          coord = { map = 1409, x = 0.560, y = 0.588 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59940, text = "Turn in: The Choppy Booster Mk. 5",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59941, text = "Re-sizing the Situation",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 59941, text = "Re-sizing the Situation (objective 1)",
          coord = { map = 1409, x = 0.569, y = 0.576 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59941, text = "Turn in: Re-sizing the Situation",
          coord = { map = 1409, x = 0.562, y = 0.590 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59942, text = "The Re-Deather",
          coord = { map = 1409, x = 0.561, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 59942, text = "The Re-Deather (objective 1)",
          coord = { map = 1409, x = 0.560, y = 0.587 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59942, text = "The Re-Deather (objective 2)",
          coord = { map = 1409, x = 0.560, y = 0.587 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59942, text = "The Re-Deather (objective 3)",
          coord = { map = 1409, x = 0.510, y = 0.527 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59942, text = "Turn in: The Re-Deather",
          coord = { map = 1409, x = 0.525, y = 0.533 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59950, text = "Stocking Up on Supplies",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- giver coord: ATT
        { type = "quest", questID = 59950, text = "Stocking Up on Supplies (objective 1)",
          coord = { map = 1409, x = 0.524, y = 0.556 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59950, text = "Stocking Up on Supplies (objective 2)",
          coord = { map = 1409, x = 0.524, y = 0.556 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59950, text = "Turn in: Stocking Up on Supplies",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59951, text = "A Druid's Form", class = "DRUID",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59952, text = "A Hunter's Trap", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59954, text = "A Mage's Knowledge", class = "MAGE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59956, text = "A Monk's Focus", class = "MONK",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59958, text = "A Paladin's Service", class = "PALADIN",
          coord = { map = 1409, x = 0.520, y = 0.554 } },  -- giver coord: ATT
        { type = "accept", questID = 59961, text = "A Priest's End", class = "PRIEST",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59967, text = "A Rogue's End", class = "ROGUE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59969, text = "A Shaman's Duty", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.556 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59970, text = "A Warlock's Bargain", class = "WARLOCK",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "accept", questID = 59971, text = "A Warrior's End", class = "WARRIOR",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 59951, text = "A Druid's Form (objective 1)", class = "DRUID",
          coord = { map = 1409, x = 0.453, y = 0.492 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59951, text = "Turn in: A Druid's Form", class = "DRUID",
          coord = { map = 1409, x = 0.454, y = 0.492 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59952, text = "A Hunter's Trap (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59952, text = "A Hunter's Trap (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.522, y = 0.530 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59952, text = "A Hunter's Trap (objective 3)", class = "HUNTER",
          coord = { map = 1409, x = 0.518, y = 0.516 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59952, text = "Turn in: A Hunter's Trap", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59953, text = "Hunting the Stalker", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 59953, text = "Hunting the Stalker (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.518, y = 0.534 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59953, text = "Turn in: Hunting the Stalker", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "accept", questID = 60162, text = "The Art of Taming", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- giver coord: ATT
        { type = "quest", questID = 60162, text = "The Art of Taming (objective 1)", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 60162, text = "The Art of Taming (objective 2)", class = "HUNTER",
          coord = { map = 1409, x = 0.524, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 60162, text = "The Art of Taming (objective 3)", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 60162, text = "Turn in: The Art of Taming", class = "HUNTER",
          coord = { map = 1409, x = 0.523, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59954, text = "A Mage's Knowledge (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.519, y = 0.498 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59954, text = "Turn in: A Mage's Knowledge", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59955, text = "The Best Way to Use Sheep", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- giver coord: ATT
        { type = "quest", questID = 59955, text = "The Best Way to Use Sheep (objective 1)", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59955, text = "The Best Way to Use Sheep (objective 2)", class = "MAGE",
          coord = { map = 1409, x = 0.536, y = 0.556 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59955, text = "Turn in: The Best Way to Use Sheep", class = "MAGE",
          coord = { map = 1409, x = 0.522, y = 0.554 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59956, text = "A Monk's Focus (objective 1)", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.495 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59956, text = "Turn in: A Monk's Focus", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.494 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59957, text = "One Last Spar", class = "MONK",
          coord = { map = 1409, x = 0.526, y = 0.494 } },  -- giver coord: ATT
        { type = "quest", questID = 59957, text = "One Last Spar (objective 1)", class = "MONK",
          coord = { map = 1409, x = 0.534, y = 0.498 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59957, text = "Turn in: One Last Spar", class = "MONK",
          coord = { map = 1409, x = 0.523, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59948, text = "Westward Bound",
          coord = { map = 1409, x = 0.529, y = 0.564 } },  -- giver coord: ATT
        { type = "quest", questID = 59961, text = "A Priest's End (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59961, text = "Turn in: A Priest's End", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59965, text = "Resurrecting the Recruits", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- giver coord: ATT
        { type = "quest", questID = 59965, text = "Resurrecting the Recruits (objective 1)", class = "PRIEST",
          coord = { map = 1409, x = 0.562, y = 0.534 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59965, text = "Turn in: Resurrecting the Recruits", class = "PRIEST",
          coord = { map = 1409, x = 0.561, y = 0.536 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59967, text = "A Rogue's End (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59967, text = "A Rogue's End (objective 2)", class = "ROGUE",
          coord = { map = 1409, x = 0.449, y = 0.553 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59967, text = "Turn in: A Rogue's End", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59968, text = "The Deadliest of Poisons", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.561 } },  -- giver coord: ATT
        { type = "quest", questID = 59968, text = "The Deadliest of Poisons (objective 1)", class = "ROGUE",
          coord = { map = 1409, x = 0.456, y = 0.558 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59968, text = "The Deadliest of Poisons (objective 2)", class = "ROGUE",
          coord = { map = 1409, x = 0.485, y = 0.515 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59968, text = "Turn in: The Deadliest of Poisons", class = "ROGUE",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59969, text = "A Shaman's Duty (objective 1)", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.513 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59969, text = "A Shaman's Duty (objective 2)", class = "SHAMAN",
          coord = { map = 1409, x = 0.522, y = 0.555 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59969, text = "A Shaman's Duty (objective 3)", class = "SHAMAN",
          coord = { map = 1409, x = 0.542, y = 0.570 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59969, text = "Turn in: A Shaman's Duty", class = "SHAMAN",
          coord = { map = 1409, x = 0.523, y = 0.556 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59943, text = "The Harpy Problem",
          coord = { map = 1409, x = 0.537, y = 0.521 } },  -- giver coord: ATT
        { type = "quest", questID = 59970, text = "A Warlock's Bargain (objective 1)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.459 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59970, text = "A Warlock's Bargain (objective 2)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.458 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59970, text = "A Warlock's Bargain (objective 3)", class = "WARLOCK",
          coord = { map = 1409, x = 0.525, y = 0.458 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59971, text = "Turn in: A Warrior's End", class = "WARRIOR",
          coord = { map = 1409, x = 0.514, y = 0.478 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59972, text = "Hjalmar's Final Execution", class = "WARRIOR",
          coord = { map = 1409, x = 0.515, y = 0.478 } },  -- giver coord: ATT
        { type = "quest", questID = 59972, text = "Hjalmar's Final Execution (objective 1)", class = "WARRIOR",
          coord = { map = 1409, x = 0.514, y = 0.478 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59943, text = "Turn in: The Harpy Problem",
          coord = { map = 1409, x = 0.569, y = 0.462 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59945, text = "Harpy Culling",
          coord = { map = 1409, x = 0.569, y = 0.462 } },  -- giver coord: ATT
        { type = "accept", questID = 59944, text = "The Rescue of Herbert Gloomburst",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- giver coord: ATT
        { type = "accept", questID = 59946, text = "Purge the Totems",
          coord = { map = 1409, x = 0.569, y = 0.462 } },  -- giver coord: ATT
        { type = "quest", questID = 59944, text = "The Rescue of Herbert Gloomburst (objective 1)",
          coord = { map = 1409, x = 0.542, y = 0.415 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59945, text = "Harpy Culling (objective 1)",
          coord = { map = 1409, x = 0.591, y = 0.429 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59945, text = "Turn in: Harpy Culling",
          coord = { map = 1409, x = 0.569, y = 0.461 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59944, text = "Turn in: The Rescue of Herbert Gloomburst",
          coord = { map = 1409, x = 0.569, y = 0.461 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59946, text = "Turn in: Purge the Totems",
          coord = { map = 1409, x = 0.569, y = 0.461 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59947, text = "Message to Base",
          coord = { map = 1409, x = 0.568, y = 0.461 } },  -- giver coord: ATT
        { type = "accept", questID = 54933, text = "Freeing the Light",
          coord = { map = 1409, x = 0.581, y = 0.502 } },  -- giver coord: ATT
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 1)",
          coord = { map = 1409, x = 0.574, y = 0.496 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 2)",
          coord = { map = 1409, x = 0.584, y = 0.491 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 3)",
          coord = { map = 1409, x = 0.590, y = 0.506 } },  -- coord: APR route (converted)
        { type = "quest", questID = 54933, text = "Freeing the Light (objective 4)",
          coord = { map = 1409, x = 0.578, y = 0.511 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59958, text = "A Paladin's Service (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59958, text = "Turn in: A Paladin's Service", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "accept", questID = 60174, text = "The Divine's Shield", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.522 } },  -- giver coord: ATT
        { type = "quest", questID = 60174, text = "The Divine's Shield (objective 1)", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.521 } },  -- coord: APR route (converted)
        { type = "quest", questID = 60174, text = "The Divine's Shield (objective 2)", class = "PALADIN",
          coord = { map = 1409, x = 0.571, y = 0.526 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 60174, text = "Turn in: The Divine's Shield", class = "PALADIN",
          coord = { map = 1409, x = 0.575, y = 0.522 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 54933, text = "Turn in: Freeing the Light",
          coord = { map = 1409, x = 0.581, y = 0.502 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59947, text = "Turn in: Message to Base",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59970, text = "Turn in: A Warlock's Bargain", class = "WARLOCK",
          coord = { map = 1409, x = 0.526, y = 0.454 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59972, text = "Turn in: Hjalmar's Final Execution", class = "WARRIOR",
          coord = { map = 1409, x = 0.520, y = 0.552 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59948, text = "Turn in: Westward Bound",
          coord = { map = 1409, x = 0.511, y = 0.595 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59949, text = "Who Lurks in the Pit",
          coord = { map = 1409, x = 0.511, y = 0.595 } },  -- giver coord: ATT
        { type = "quest", questID = 59949, text = "Who Lurks in the Pit (objective 1)",
          coord = { map = 1409, x = 0.505, y = 0.598 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59949, text = "Who Lurks in the Pit (objective 2)",
          coord = { map = 1409, x = 0.475, y = 0.603 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59949, text = "Who Lurks in the Pit (objective 3)",
          coord = { map = 1409, x = 0.477, y = 0.602 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59949, text = "Turn in: Who Lurks in the Pit",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59975, text = "To Darkmaul Citadel",
          coord = { map = 1409, x = 0.521, y = 0.553 } },  -- giver coord: ATT
        { type = "accept", questID = 56839, text = "Killclaw the Terrible",
          coord = { map = 1409, x = 0.487, y = 0.542 } },  -- giver coord: ATT
        { type = "quest", questID = 56839, text = "Killclaw the Terrible (objective 1)",
          coord = { map = 1409, x = 0.455, y = 0.545 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 56839, text = "Turn in: Killclaw the Terrible",
          coord = { map = 1409, x = 0.434, y = 0.511 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59975, text = "Turn in: To Darkmaul Citadel",
          coord = { map = 1409, x = 0.489, y = 0.492 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59978, text = "Right Beneath Their Eyes",
          coord = { map = 1409, x = 0.489, y = 0.493 } },  -- giver coord: ATT
        { type = "quest", questID = 59978, text = "Right Beneath Their Eyes (objective 1)",
          coord = { map = 1409, x = 0.490, y = 0.492 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59978, text = "Right Beneath Their Eyes (objective 2)",
          coord = { map = 1409, x = 0.451, y = 0.433 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59978, text = "Right Beneath Their Eyes (objective 3)",
          coord = { map = 1409, x = 0.456, y = 0.380 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59978, text = "Right Beneath Their Eyes (objective 4)",
          coord = { map = 1409, x = 0.456, y = 0.375 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59978, text = "Right Beneath Their Eyes (objective 6)",
          coord = { map = 1409, x = 0.406, y = 0.325 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59978, text = "Turn in: Right Beneath Their Eyes",
          coord = { map = 1409, x = 0.401, y = 0.323 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59981, text = "Controlling their Stones",
          coord = { map = 1409, x = 0.402, y = 0.324 } },  -- giver coord: ATT
        { type = "accept", questID = 59980, text = "Catapult Destruction",
          coord = { map = 1409, x = 0.403, y = 0.324 } },  -- giver coord: ATT
        { type = "accept", questID = 59979, text = "Like Ogres to the Slaughter",
          coord = { map = 1409, x = 0.402, y = 0.325 } },  -- giver coord: ATT
        { type = "quest", questID = 59981, text = "Controlling their Stones (objective 2)",
          coord = { map = 1409, x = 0.440, y = 0.373 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59981, text = "Controlling their Stones (objective 1)",
          coord = { map = 1409, x = 0.475, y = 0.343 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59981, text = "Controlling their Stones (objective 3)",
          coord = { map = 1409, x = 0.427, y = 0.408 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59979, text = "Like Ogres to the Slaughter (objective 1)",
          coord = { map = 1409, x = 0.449, y = 0.411 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59980, text = "Catapult Destruction (objective 1)",
          coord = { map = 1409, x = 0.449, y = 0.411 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59979, text = "Turn in: Like Ogres to the Slaughter",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59980, text = "Turn in: Catapult Destruction",
          coord = { map = 1409, x = 0.402, y = 0.323 } },  -- coord: APR route (converted)
        { type = "quest", questID = 59981, text = "Controlling their Stones (objective 4)",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59981, text = "Turn in: Controlling their Stones",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59984, text = "Dungeon: Darkmaul Citadel",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- giver coord: ATT
        { type = "quest", questID = 59984, text = "Dungeon: Darkmaul Citadel (objective 1)",
          coord = { map = 1409, x = 0.399, y = 0.321 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59984, text = "Turn in: Dungeon: Darkmaul Citadel",
          coord = { map = 1409, x = 0.396, y = 0.319 } },  -- coord: APR route (converted)
        { type = "accept", questID = 59985, text = "An End to Beginnings",
          coord = { map = 1409, x = 0.396, y = 0.319 } },  -- giver coord: ATT
        { type = "quest", questID = 59985, text = "An End to Beginnings (objective 1)",
          coord = { map = 1409, x = 0.403, y = 0.326 } },  -- coord: APR route (converted)
        { type = "turnin", questID = 59985, text = "Turn in: An End to Beginnings",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "accept", questID = 62568, text = "Adventurers Wanted: Chromie's Call (leave tutorial, say Yes to gossip)",
          coord = nil },  -- no 1409 coord (ship map 1727)
        { type = "turnin", questID = 62568, text = "Turn in: Adventurers Wanted: Chromie's Call",
          coord = nil },  -- no 1409 coord (ship map 1727)
    },
}
