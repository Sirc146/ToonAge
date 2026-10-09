-- ToonAge guide data: Midnight 12.1: The Coiled Isle (side quests)
-- Kind: APR "sojourner" route (12.1, InterfaceVersion 120100)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2393-Coiled-Isle"
--    in Routes/Midnight/Midnight-Coiled-Isle.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 70 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 59 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.13, max 0.32 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2437 Zul'Aman, 2509 Vaults of Atal'Utek, 2512 The Coiled Isle, 2636 Vault of Restless Bones, 2640 Infested Tomb, 2644 Crypt of the Disgraced


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_coiled_isle"] = {
    id = "midnight_coiled_isle", title = "Midnight 12.1: The Coiled Isle (side quests)", expansion = "midnight",
    zone = 2512, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_purpose_of_tomorrow",
    steps = {
        { type = "accept", questID = 96523, text = "Living Legend",
          coord = { map = 2512, x = 0.594, y = 0.509 } },  -- giver coord: ATT
        { type = "quest",  questID = 96523, text = "Living Legend (objective 1)",
          coord = { map = 2512, x = 0.594, y = 0.509 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96523, text = "Turn in: Living Legend", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.456, y = 0.483 } },  -- APR route coord (converted)
        { type = "accept", questID = 96539, text = "Last Resort",
          coord = { map = 2437, x = 0.456, y = 0.483 } },  -- giver coord: ATT
        { type = "quest",  questID = 96539, text = "Last Resort (objective 1)",
          coord = { map = 2437, x = 0.455, y = 0.484 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96539, text = "Last Resort (objective 2)",
          coord = { map = 2437, x = 0.444, y = 0.481 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96539, text = "Turn in: Last Resort", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.444, y = 0.481 } },  -- APR route coord (converted)
        { type = "accept", questID = 96540, text = "Strong Hands",
          coord = { map = 2437, x = 0.444, y = 0.481 } },  -- giver coord: ATT
        { type = "quest",  questID = 96540, text = "Strong Hands (objective 1)",
          coord = { map = 2437, x = 0.442, y = 0.482 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96540, text = "Strong Hands (objective 2)",
          coord = { map = 2437, x = 0.439, y = 0.479 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96540, text = "Turn in: Strong Hands", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.436, y = 0.479 } },  -- APR route coord (converted)
        { type = "accept", questID = 96541, text = "Strong Mind",
          coord = { map = 2437, x = 0.436, y = 0.479 } },  -- giver coord: ATT
        { type = "quest",  questID = 96541, text = "Strong Mind (objective 1)",
          coord = { map = 2437, x = 0.437, y = 0.478 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96541, text = "Strong Mind (objective 2)",
          coord = { map = 2437, x = 0.437, y = 0.478 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96541, text = "Turn in: Strong Mind", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.456, y = 0.483 } },  -- APR route coord (converted)
        { type = "accept", questID = 96543, text = "Root of Survival",
          coord = { map = 2437, x = 0.456, y = 0.483 } },  -- giver coord: ATT
        { type = "quest",  questID = 96543, text = "Root of Survival (objective 1)",
          coord = { map = 2437, x = 0.455, y = 0.484 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96543, text = "Root of Survival (objective 3,2)",
          coord = { map = 2437, x = 0.451, y = 0.476 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96543, text = "Turn in: Root of Survival", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.455, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 96544, text = "Bravely Burning",
          coord = { map = 2437, x = 0.456, y = 0.483 } },  -- giver coord: ATT
        { type = "quest",  questID = 96544, text = "Bravely Burning (objective 2)",
          coord = { map = 2437, x = 0.457, y = 0.493 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96544, text = "Bravely Burning (objective 1)",
          coord = { map = 2437, x = 0.450, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96544, text = "Turn in: Bravely Burning", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.457, y = 0.490 } },  -- APR route coord (converted)
        { type = "accept", questID = 96545, text = "Strong Voice",
          coord = { map = 2437, x = 0.457, y = 0.490 } },  -- giver coord: ATT
        { type = "quest",  questID = 96545, text = "Strong Voice (objective 1)",
          coord = { map = 2437, x = 0.454, y = 0.484 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96545, text = "Turn in: Strong Voice", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.453, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 96546, text = "Strong Heart",
          coord = { map = 2437, x = 0.453, y = 0.487 } },  -- giver coord: ATT
        { type = "quest",  questID = 96546, text = "Strong Heart (objective 1)",
          coord = { map = 2437, x = 0.453, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96546, text = "Strong Heart (objective 2)",
          coord = { map = 2437, x = 0.454, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96546, text = "Strong Heart (objective 3)",
          coord = { map = 2437, x = 0.453, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96546, text = "Strong Heart (objective 4)",
          coord = { map = 2437, x = 0.453, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96546, text = "Turn in: Strong Heart", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.594, y = 0.509 } },  -- APR route coord (converted)
        { type = "accept", questID = 96110, text = "Venom Fishing: Proof is in the Ooze",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- giver coord: ATT
        { type = "accept", questID = 96089, text = "Somethin's Not Right",
          coord = { map = 2512, x = 0.570, y = 0.480 } },  -- giver coord: ATT
        { type = "quest",  questID = 96089, text = "Somethin's Not Right (objective 1)",
          coord = { map = 2512, x = 0.570, y = 0.481 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96089, text = "Somethin's Not Right (objective 2)",
          coord = { map = 2512, x = 0.570, y = 0.480 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96089, text = "Somethin's Not Right (objective 3)",
          coord = { map = 2512, x = 0.572, y = 0.485 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96089, text = "Turn in: Somethin's Not Right", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.572, y = 0.485 } },  -- APR route coord (converted)
        { type = "accept", questID = 96090, text = "Venemetic",
          coord = { map = 2512, x = 0.572, y = 0.484 } },  -- giver coord: ATT
        { type = "accept", questID = 93449, text = "Trouble in the Swamp",
          coord = { map = 2512, x = 0.575, y = 0.474 } },  -- giver coord: ATT
        { type = "accept", questID = 96439, text = "Gone Dark",
          coord = { map = 2512, x = 0.579, y = 0.467 } },  -- giver coord: ATT
        { type = "accept", questID = 96467, text = "Thirst for Knowledge",
          coord = { map = 2512, x = 0.579, y = 0.467 } },  -- giver coord: ATT
        { type = "accept", questID = 93841, text = "Ghosts of the Ring",
          coord = { map = 2512, x = 0.586, y = 0.472 } },  -- giver coord: ATT
        { type = "accept", questID = 94936, text = "A Bond of Brothers",
          coord = { map = 2512, x = 0.565, y = 0.431 } },  -- giver coord: ATT
        { type = "quest",  questID = 94936, text = "A Bond of Brothers (objective 1)",
          coord = { map = 2512, x = 0.556, y = 0.403 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94936, text = "A Bond of Brothers (objective 2)",
          coord = { map = 2512, x = 0.553, y = 0.397 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94936, text = "A Bond of Brothers (objective 3)",
          coord = { map = 2512, x = 0.550, y = 0.393 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94936, text = "A Bond of Brothers (objective 4)",
          coord = { map = 2512, x = 0.532, y = 0.374 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94936, text = "A Bond of Brothers (objective 5)",
          coord = { map = 2512, x = 0.532, y = 0.369 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94936, text = "Turn in: A Bond of Brothers", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.533, y = 0.351 } },  -- APR route coord (converted)
        { type = "accept", questID = 94937, text = "Too Quiet on the Northern Front",
          coord = { map = 2512, x = 0.532, y = 0.352 } },  -- giver coord: ATT
        { type = "quest",  questID = 94937, text = "Too Quiet on the Northern Front (objective 1)",
          coord = { map = 2512, x = 0.528, y = 0.342 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94937, text = "Too Quiet on the Northern Front (objective 2)",
          coord = { map = 2512, x = 0.529, y = 0.342 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94937, text = "Turn in: Too Quiet on the Northern Front", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.534, y = 0.335 } },  -- APR route coord (converted)
        { type = "accept", questID = 94941, text = "Saving Recruit Jabat",
          coord = { map = 2512, x = 0.534, y = 0.335 } },  -- giver coord: ATT
        { type = "quest",  questID = 94941, text = "Saving Recruit Jabat (objective 2)",
          coord = { map = 2512, x = 0.529, y = 0.331 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96439, text = "Turn in: Gone Dark",
          coord = { map = 2512, x = 0.445, y = 0.302 } },  -- APR route coord (converted)
        { type = "accept", questID = 96450, text = "Sideways",
          coord = { map = 2640, x = 0.807, y = 0.461 } },  -- giver coord: ATT
        { type = "quest",  questID = 96450, text = "Sideways (objective 1)",
          coord = { map = 2512, x = 0.439, y = 0.296 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96450, text = "Sideways (objective 3)",
          coord = { map = 2512, x = 0.433, y = 0.295 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96450, text = "Sideways (objective 2)",
          coord = { map = 2512, x = 0.431, y = 0.300 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96450, text = "Turn in: Sideways", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.429, y = 0.299 } },  -- APR route coord (converted)
        { type = "accept", questID = 96451, text = "A Child of Ula'tek",
          coord = { map = 2640, x = 0.207, y = 0.357 } },  -- giver coord: ATT
        { type = "quest",  questID = 96451, text = "A Child of Ula'tek (objective 1)",
          coord = { map = 2512, x = 0.429, y = 0.309 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96451, text = "Turn in: A Child of Ula'tek", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.434, y = 0.309 } },  -- APR route coord (converted)
        { type = "accept", questID = 96457, text = "Nothing Must Remain",
          coord = { map = 2640, x = 0.405, y = 0.722 } },  -- giver coord: ATT
        { type = "quest",  questID = 96457, text = "Nothing Must Remain (objective 1)",
          coord = { map = 2512, x = 0.435, y = 0.311 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96457, text = "Turn in: Nothing Must Remain", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.434, y = 0.309 } },  -- APR route coord (converted)
        { type = "accept", questID = 96458, text = "Last Promise",
          coord = { map = 2640, x = 0.405, y = 0.722 } },  -- giver coord: ATT
        { type = "quest",  questID = 96090, text = "Venemetic (objective 1)",
          coord = { map = 2512, x = 0.525, y = 0.371 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96110, text = "Venom Fishing: Proof is in the Ooze (objective 2)",
          coord = { map = 2512, x = 0.477, y = 0.496 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94941, text = "Turn in: Saving Recruit Jabat", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.565, y = 0.433 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96458, text = "Turn in: Last Promise", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.579, y = 0.467 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96090, text = "Turn in: Venemetic", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.572, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 96091, text = "Get the Balance Right",
          coord = { map = 2512, x = 0.572, y = 0.484 } },  -- giver coord: ATT
        { type = "turnin", questID = 96110, text = "Turn in: Venom Fishing: Proof is in the Ooze", rep = { { factionID = 2773, amount = 100 } },
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 98343, text = "Venom Fishing: My Second-Best",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- giver coord: ATT
        { type = "quest",  questID = 96091, text = "Get the Balance Right (objective 1)",
          coord = { map = 2512, x = 0.575, y = 0.488 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96091, text = "Get the Balance Right (objective 2)",
          coord = { map = 2512, x = 0.570, y = 0.481 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96091, text = "Get the Balance Right (objective 3)",
          coord = { map = 2512, x = 0.570, y = 0.481 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96091, text = "Get the Balance Right (objective 4)",
          coord = { map = 2512, x = 0.570, y = 0.480 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96091, text = "Turn in: Get the Balance Right", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.572, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 96092, text = "That Fool, Ruma",
          coord = { map = 2512, x = 0.572, y = 0.484 } },  -- giver coord: ATT
        { type = "quest",  questID = 98343, text = "Venom Fishing: My Second-Best (objective 1)",
          coord = { map = 2512, x = 0.516, y = 0.499 } },  -- APR route coord (converted)
        { type = "turnin", questID = 98343, text = "Turn in: Venom Fishing: My Second-Best",
          coord = { map = 2512, x = 0.516, y = 0.498 } },  -- APR route coord (converted)
        { type = "accept", questID = 98414, text = "A Request from the Captain",
          coord = { map = 2512, x = 0.516, y = 0.498 } },  -- giver coord: ATT
        { type = "turnin", questID = 98414, text = "Turn in: A Request from the Captain",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 96111, text = "Venom Fishing: Shell of Yourself",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- giver coord: ATT
        { type = "accept", questID = 93387, text = "Dealing with Pests",
          coord = { map = 2512, x = 0.611, y = 0.329 } },  -- giver coord: ATT
        { type = "quest",  questID = 93387, text = "Dealing with Pests (objective 1)",
          coord = { map = 2512, x = 0.609, y = 0.329 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93387, text = "Turn in: Dealing with Pests", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.609, y = 0.329 } },  -- APR route coord (converted)
        { type = "accept", questID = 93388, text = "Unusual Alchemy",
          coord = { map = 2512, x = 0.611, y = 0.329 } },  -- giver coord: ATT
        { type = "accept", questID = 93389, text = "Rocksblood",
          coord = { map = 2512, x = 0.611, y = 0.329 } },  -- giver coord: ATT
        { type = "turnin", questID = 93449, text = "Turn in: Trouble in the Swamp", rep = { { factionID = 2772, amount = 10 } },
          coord = { map = 2512, x = 0.630, y = 0.445 } },  -- APR route coord (converted)
        { type = "accept", questID = 93229, text = "Fried Eggs",
          coord = { map = 2512, x = 0.630, y = 0.445 } },  -- giver coord: ATT
        { type = "accept", questID = 93199, text = "Slithering in the Mire",
          coord = { map = 2512, x = 0.630, y = 0.445 } },  -- giver coord: ATT
        { type = "quest",  questID = 93388, text = "Unusual Alchemy (objective 1)",
          coord = { map = 2512, x = 0.640, y = 0.459 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93388, text = "Unusual Alchemy (objective 2)",
          coord = { map = 2512, x = 0.641, y = 0.458 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93389, text = "Rocksblood (objective 1)",
          coord = { map = 2512, x = 0.715, y = 0.372 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93389, text = "Rocksblood (objective 2)",
          coord = { map = 2512, x = 0.720, y = 0.335 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93388, text = "Unusual Alchemy (objective 3)",
          coord = { map = 2512, x = 0.690, y = 0.326 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93199, text = "Slithering in the Mire (objective 1)",
          coord = { map = 2512, x = 0.653, y = 0.399 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93388, text = "Unusual Alchemy (objective 4)",
          coord = { map = 2512, x = 0.653, y = 0.399 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93229, text = "Fried Eggs (objective 1)",
          coord = { map = 2512, x = 0.653, y = 0.399 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93229, text = "Turn in: Fried Eggs", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93199, text = "Turn in: Slithering in the Mire", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- APR route coord (converted)
        { type = "accept", questID = 93576, text = "The Search for Wa'kani",
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- giver coord: ATT
        { type = "quest",  questID = 93576, text = "The Search for Wa'kani (objective 1)",
          coord = { map = 2512, x = 0.651, y = 0.372 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93576, text = "Turn in: The Search for Wa'kani", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.647, y = 0.379 } },  -- APR route coord (converted)
        { type = "accept", questID = 94447, text = "Ophidia the Broodmother",
          coord = { map = 2512, x = 0.647, y = 0.379 } },  -- giver coord: ATT
        { type = "quest",  questID = 94447, text = "Ophidia the Broodmother (objective 1)",
          coord = { map = 2512, x = 0.636, y = 0.361 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94447, text = "Ophidia the Broodmother (objective 2)",
          coord = { map = 2512, x = 0.647, y = 0.379 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94447, text = "Ophidia the Broodmother (objective 3)",
          coord = { map = 2512, x = 0.661, y = 0.390 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94447, text = "Turn in: Ophidia the Broodmother", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- APR route coord (converted)
        { type = "accept", questID = 93239, text = "Scouts in the Swamp",
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- giver coord: ATT
        { type = "accept", questID = 93233, text = "Savagery Among the Ruins",
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- giver coord: ATT
        { type = "accept", questID = 93339, text = "Trinket Trading",
          coord = { map = 2512, x = 0.660, y = 0.390 } },  -- giver coord: ATT
        { type = "quest",  questID = 93239, text = "Scouts in the Swamp (objective 2)",
          coord = { map = 2512, x = 0.674, y = 0.407 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93239, text = "Scouts in the Swamp (objective 1)",
          coord = { map = 2512, x = 0.682, y = 0.345 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93239, text = "Scouts in the Swamp (objective 3)",
          coord = { map = 2512, x = 0.668, y = 0.334 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93233, text = "Savagery Among the Ruins (objective 1,2)",
          coord = { map = 2512, x = 0.680, y = 0.367 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93339, text = "Trinket Trading (objective 1)",
          coord = { map = 2512, x = 0.680, y = 0.367 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93239, text = "Turn in: Scouts in the Swamp", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.689, y = 0.372 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93233, text = "Turn in: Savagery Among the Ruins", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.689, y = 0.372 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93339, text = "Turn in: Trinket Trading", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.689, y = 0.372 } },  -- APR route coord (converted)
        { type = "accept", questID = 93340, text = "The Shadow Shard",
          coord = { map = 2512, x = 0.689, y = 0.372 } },  -- giver coord: ATT
        { type = "quest",  questID = 93340, text = "The Shadow Shard (objective 1)",
          coord = { map = 2512, x = 0.711, y = 0.383 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93340, text = "The Shadow Shard (objective 2)",
          coord = { map = 2512, x = 0.712, y = 0.383 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93340, text = "Turn in: The Shadow Shard", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.689, y = 0.372 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93389, text = "Rocksblood (objective 3)",
          coord = { map = 2512, x = 0.624, y = 0.307 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93389, text = "Turn in: Rocksblood", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.609, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93388, text = "Turn in: Unusual Alchemy", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.604, y = 0.330 } },  -- APR route coord (converted)
        { type = "accept", questID = 93390, text = "Acceptable Apprentice",
          coord = { map = 2512, x = 0.604, y = 0.331 } },  -- giver coord: ATT
        { type = "quest",  questID = 93390, text = "Acceptable Apprentice (objective 1)",
          coord = { map = 2512, x = 0.604, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93390, text = "Acceptable Apprentice (objective 2,3)",
          coord = { map = 2512, x = 0.604, y = 0.330 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93390, text = "Turn in: Acceptable Apprentice", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.604, y = 0.330 } },  -- APR route coord (converted)
        { type = "accept", questID = 93391, text = "Make it Stinky",
          coord = { map = 2512, x = 0.604, y = 0.331 } },  -- giver coord: ATT
        { type = "quest",  questID = 93391, text = "Make it Stinky (objective 1)",
          coord = { map = 2512, x = 0.620, y = 0.343 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93391, text = "Make it Stinky (objective 2)",
          coord = { map = 2512, x = 0.625, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93391, text = "Make it Stinky (objective 3)",
          coord = { map = 2512, x = 0.630, y = 0.329 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93391, text = "Turn in: Make it Stinky", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.604, y = 0.331 } },  -- APR route coord (converted)
        { type = "accept", questID = 93392, text = "Recovering Memories",
          coord = { map = 2512, x = 0.609, y = 0.326 } },  -- giver coord: ATT
        { type = "quest",  questID = 93392, text = "Recovering Memories (objective 1)",
          coord = { map = 2512, x = 0.650, y = 0.168 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93392, text = "Recovering Memories (objective 2)",
          coord = { map = 2512, x = 0.649, y = 0.165 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93392, text = "Turn in: Recovering Memories", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.609, y = 0.326 } },  -- APR route coord (converted)
        { type = "accept", questID = 93393, text = "A Little Kindness",
          coord = { map = 2512, x = 0.609, y = 0.326 } },  -- giver coord: ATT
        { type = "quest",  questID = 93393, text = "A Little Kindness (objective 1)",
          coord = { map = 2512, x = 0.604, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93393, text = "A Little Kindness (objective 2)",
          coord = { map = 2512, x = 0.611, y = 0.321 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93393, text = "A Little Kindness (objective 3,4)",
          coord = { map = 2512, x = 0.633, y = 0.282 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93393, text = "Turn in: A Little Kindness", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.610, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93841, text = "Turn in: Ghosts of the Ring", rep = { { factionID = 2772, amount = 10 } },
          coord = { map = 2512, x = 0.662, y = 0.533 } },  -- APR route coord (converted)
        { type = "accept", questID = 93842, text = "Bloom and Fade",
          coord = { map = 2512, x = 0.660, y = 0.533 } },  -- giver coord: ATT
        { type = "accept", questID = 93843, text = "Ectoplasmic Extractions",
          coord = { map = 2512, x = 0.660, y = 0.533 } },  -- giver coord: ATT
        { type = "quest",  questID = 93842, text = "Bloom and Fade (objective 1)",
          coord = { map = 2512, x = 0.674, y = 0.543 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93843, text = "Ectoplasmic Extractions (objective 1)",
          coord = { map = 2512, x = 0.674, y = 0.543 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93842, text = "Turn in: Bloom and Fade", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93843, text = "Turn in: Ectoplasmic Extractions", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- APR route coord (converted)
        { type = "accept", questID = 93849, text = "Ectoplasmic Emporium",
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- giver coord: ATT
        { type = "quest",  questID = 93849, text = "Ectoplasmic Emporium (objective 1)",
          coord = { map = 2512, x = 0.693, y = 0.522 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93849, text = "Ectoplasmic Emporium (objective 2)",
          coord = { map = 2512, x = 0.698, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93849, text = "Turn in: Ectoplasmic Emporium", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- APR route coord (converted)
        { type = "accept", questID = 93851, text = "Communing with Ghosts",
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- giver coord: ATT
        { type = "quest",  questID = 93851, text = "Communing with Ghosts (objective 1)",
          coord = { map = 2512, x = 0.693, y = 0.522 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93851, text = "Communing with Ghosts (objective 4)",
          coord = { map = 2512, x = 0.704, y = 0.527 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93851, text = "Turn in: Communing with Ghosts", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- APR route coord (converted)
        { type = "accept", questID = 93906, text = "Untethering the Two",
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- giver coord: ATT
        { type = "quest",  questID = 93906, text = "Untethering the Two (objective 1)",
          coord = { map = 2512, x = 0.730, y = 0.536 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93906, text = "Untethering the Two (objective 2)",
          coord = { map = 2512, x = 0.694, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93906, text = "Turn in: Untethering the Two", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.695, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96467, text = "Turn in: Thirst for Knowledge",
          coord = { map = 2512, x = 0.750, y = 0.626 } },  -- APR route coord (converted)
        { type = "accept", questID = 96469, text = "The Crypt of the Disgraced",
          coord = { map = 2512, x = 0.750, y = 0.626 } },  -- giver coord: ATT
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 1)",
          coord = { map = 2512, x = 0.736, y = 0.639 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 2)",
          coord = { map = 2512, x = 0.738, y = 0.641 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 2)",
          coord = { map = 2512, x = 0.735, y = 0.637 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 2)",
          coord = { map = 2512, x = 0.733, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 2)",
          coord = { map = 2512, x = 0.735, y = 0.645 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 2)",
          coord = { map = 2512, x = 0.742, y = 0.646 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96469, text = "The Crypt of the Disgraced (objective 5)",
          coord = { map = 2512, x = 0.743, y = 0.645 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96469, text = "Turn in: The Crypt of the Disgraced", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.743, y = 0.645 } },  -- APR route coord (converted)
        { type = "accept", questID = 96471, text = "Crumble and Tumble",
          coord = { map = 2644, x = 0.611, y = 0.597 } },  -- giver coord: ATT
        { type = "quest",  questID = 96471, text = "Crumble and Tumble (objective 1)",
          coord = { map = 2512, x = 0.746, y = 0.628 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96471, text = "Turn in: Crumble and Tumble", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.748, y = 0.625 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96092, text = "That Fool, Ruma (objective 1)",
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96092, text = "That Fool, Ruma (objective 2)", useItem = 274462,
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96092, text = "Turn in: That Fool, Ruma", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- APR route coord (converted)
        { type = "accept", questID = 96093, text = "It's a Satchel, Not a Bag",
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- giver coord: ATT
        { type = "quest",  questID = 96093, text = "It's a Satchel, Not a Bag (objective 1)",
          coord = { map = 2512, x = 0.556, y = 0.756 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 96093, text = "Turn in: It's a Satchel, Not a Bag", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- APR route coord (converted)
        { type = "accept", questID = 96094, text = "To the Forum",
          coord = { map = 2512, x = 0.645, y = 0.774 } },  -- giver coord: ATT
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [1/8]",
          coord = { map = 2512, x = 0.610, y = 0.835 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [2/8]",
          coord = { map = 2512, x = 0.593, y = 0.827 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [3/8]",
          coord = { map = 2512, x = 0.591, y = 0.822 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [4/8]",
          coord = { map = 2512, x = 0.593, y = 0.804 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [5/8]",
          coord = { map = 2512, x = 0.594, y = 0.795 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [6/8]",
          coord = { map = 2512, x = 0.600, y = 0.770 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [7/8]",
          coord = { map = 2512, x = 0.613, y = 0.773 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 1) [8/8]",
          coord = { map = 2512, x = 0.611, y = 0.764 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 2)",
          coord = { map = 2512, x = 0.547, y = 0.787 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 3)",
          coord = { map = 2512, x = 0.547, y = 0.787 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96111, text = "Venom Fishing: Shell of Yourself (objective 4)",
          coord = { map = 2512, x = 0.546, y = 0.787 } },  -- APR route coord (converted)
        { type = "accept", questID = 94031, text = "Bones of My Soul",
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- giver coord: ATT
        { type = "accept", questID = 94035, text = "Meat for the Bones",
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- giver coord: ATT
        { type = "accept", questID = 94036, text = "One Final Prisoner",
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- giver coord: ATT
        { type = "quest",  questID = 94035, text = "Meat for the Bones (objective 1)",
          coord = { map = 2512, x = 0.589, y = 0.679 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94031, text = "Bones of My Soul (objective 1)",
          coord = { map = 2512, x = 0.582, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94031, text = "Bones of My Soul (objective 2)",
          coord = { map = 2512, x = 0.570, y = 0.673 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94031, text = "Bones of My Soul (objective 3)",
          coord = { map = 2512, x = 0.569, y = 0.657 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94036, text = "One Final Prisoner (objective 1)",
          coord = { map = 2512, x = 0.571, y = 0.661 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94035, text = "Meat for the Bones (objective 2)",
          coord = { map = 2512, x = 0.578, y = 0.656 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94031, text = "Turn in: Bones of My Soul", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94035, text = "Turn in: Meat for the Bones", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94036, text = "Turn in: One Final Prisoner", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- APR route coord (converted)
        { type = "accept", questID = 94040, text = "Meat and Bone and Soul",
          coord = { map = 2512, x = 0.591, y = 0.680 } },  -- giver coord: ATT
        { type = "quest",  questID = 94040, text = "Meat and Bone and Soul (objective 1)",
          coord = { map = 2512, x = 0.684, y = 0.825 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94040, text = "Meat and Bone and Soul (objective 2,3,4)",
          coord = { map = 2512, x = 0.684, y = 0.825 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94040, text = "Meat and Bone and Soul (objective 5)",
          coord = { map = 2512, x = 0.683, y = 0.825 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94040, text = "Turn in: Meat and Bone and Soul", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.684, y = 0.826 } },  -- APR route coord (converted)
        { type = "accept", questID = 96095, text = "Sampling the Local Wildlife",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- giver coord: ATT
        { type = "accept", questID = 96096, text = "Scout Team Seven",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- giver coord: ATT
        { type = "quest",  questID = 96096, text = "Scout Team Seven (objective 2)",
          coord = { map = 2512, x = 0.249, y = 0.619 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96096, text = "Scout Team Seven (objective 4)",
          coord = { map = 2512, x = 0.267, y = 0.567 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96096, text = "Scout Team Seven (objective 1)",
          coord = { map = 2512, x = 0.295, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96096, text = "Scout Team Seven (objective 3)",
          coord = { map = 2512, x = 0.297, y = 0.669 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96096, text = "Scout Team Seven (objective 5)",
          coord = { map = 2512, x = 0.267, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96095, text = "Sampling the Local Wildlife (objective 1)",
          coord = { map = 2512, x = 0.262, y = 0.652 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96096, text = "Turn in: Scout Team Seven", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96095, text = "Sampling the Local Wildlife (objective 2)",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96095, text = "Turn in: Sampling the Local Wildlife", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "accept", questID = 96097, text = "What the Scouts Saw",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- giver coord: ATT
        { type = "quest",  questID = 96097, text = "What the Scouts Saw (objective 1)",
          coord = { map = 2512, x = 0.239, y = 0.645 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96097, text = "What the Scouts Saw (objective 2)",
          coord = { map = 2512, x = 0.239, y = 0.645 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96097, text = "Turn in: What the Scouts Saw", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "accept", questID = 96098, text = "The Final Reagents",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- giver coord: ATT
        { type = "quest",  questID = 96098, text = "The Final Reagents (objective 2)",
          coord = { map = 2512, x = 0.273, y = 0.597 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96098, text = "The Final Reagents (objective 1)",
          coord = { map = 2512, x = 0.275, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96098, text = "The Final Reagents (objective 3)",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96098, text = "Turn in: The Final Reagents", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "accept", questID = 96099, text = "La'una's Fate",
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- giver coord: ATT
        { type = "turnin", questID = 96094, text = "Turn in: To the Forum", rep = { { factionID = 2772, amount = 10 } },
          coord = { map = 2512, x = 0.238, y = 0.645 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96111, text = "Turn in: Venom Fishing: Shell of Yourself", rep = { { factionID = 2773, amount = 150 } },
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96099, text = "La'una's Fate (objective 1)", useItem = 274705,
          coord = { map = 2512, x = 0.570, y = 0.481 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96099, text = "Turn in: La'una's Fate", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.570, y = 0.480 } },  -- APR route coord (converted)
        { type = "accept", questID = 95521, text = "The Med'jai Medallion",
          coord = { map = 2509, x = 0.480, y = 0.518 } },  -- giver coord: ATT
        { type = "turnin", questID = 95521, text = "Turn in: The Med'jai Medallion", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.384, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 95522, text = "Guardians of Death, Guardians in Stone",
          coord = { map = 2509, x = 0.489, y = 0.642 } },  -- giver coord: ATT
        { type = "quest",  questID = 95522, text = "Guardians of Death, Guardians in Stone (objective 1,2)",
          coord = { map = 2512, x = 0.347, y = 0.556 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95522, text = "Turn in: Guardians of Death, Guardians in Stone", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.347, y = 0.556 } },  -- APR route coord (converted)
        { type = "accept", questID = 95523, text = "Worthy of the Past",
          coord = { map = 2509, x = 0.384, y = 0.344 } },  -- giver coord: ATT
        { type = "accept", questID = 95524, text = "The Unremembered",
          coord = { map = 2509, x = 0.384, y = 0.344 } },  -- giver coord: ATT
        { type = "quest",  questID = 95523, text = "Worthy of the Past (objective 1)",
          coord = { map = 2512, x = 0.355, y = 0.563 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95524, text = "The Unremembered (objective 1)",
          coord = { map = 2512, x = 0.351, y = 0.610 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95524, text = "The Unremembered (objective 2)",
          coord = { map = 2512, x = 0.367, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95523, text = "Turn in: Worthy of the Past", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.367, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95524, text = "Turn in: The Unremembered", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.367, y = 0.632 } },  -- APR route coord (converted)
        { type = "accept", questID = 95954, text = "An Ancient Foe",
          coord = { map = 2512, x = 0.367, y = 0.632 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95954, text = "An Ancient Foe (objective 1)",
          coord = { map = 2509, x = 0.363, y = 0.506 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95954, text = "Turn in: An Ancient Foe", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2509, x = 0.390, y = 0.485 } },  -- APR route coord (converted)
        { type = "accept", questID = 95525, text = "A Worthy Vigil",
          coord = { map = 2636, x = 0.830, y = 0.452 } },  -- giver coord: ATT
        { type = "turnin", questID = 95525, text = "Turn in: A Worthy Vigil", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.384, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 98415, text = "A Favor to the Captain",
          coord = { map = 2512, x = 0.516, y = 0.498 } },  -- giver coord: ATT
        { type = "turnin", questID = 98415, text = "Turn in: A Favor to the Captain",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 96112, text = "Venom Fishing: Maddening Concoction",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- giver coord: ATT
        { type = "quest",  questID = 96112, text = "Venom Fishing: Maddening Concoction (objective 1)",
          coord = { map = 2512, x = 0.595, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96112, text = "Venom Fishing: Maddening Concoction (objective 2)",
          coord = { map = 2512, x = 0.718, y = 0.520 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96112, text = "Venom Fishing: Maddening Concoction (objective 3)",
          coord = { map = 2512, x = 0.639, y = 0.350 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96112, text = "Venom Fishing: Maddening Concoction (objective 4)",
          coord = { map = 2512, x = 0.478, y = 0.496 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96112, text = "Venom Fishing: Maddening Concoction (objective 5)",
          coord = { map = 2512, x = 0.477, y = 0.496 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96112, text = "Turn in: Venom Fishing: Maddening Concoction", rep = { { factionID = 2773, amount = 200 } },
          coord = { map = 2512, x = 0.572, y = 0.485 } },  -- APR route coord (converted)
        { type = "accept", questID = 98416, text = "A Plea from the Captain",
          coord = { map = 2512, x = 0.516, y = 0.498 } },  -- giver coord: ATT
        { type = "turnin", questID = 98416, text = "Turn in: A Plea from the Captain",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 96113, text = "Venom Fishing: Maximum Potency",
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- giver coord: ATT
        { type = "quest",  questID = 96113, text = "Venom Fishing: Maximum Potency (objective 1)",
          coord = { map = 2509, x = 0.518, y = 0.529 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96113, text = "Venom Fishing: Maximum Potency (objective 2)",
          coord = { map = 2509, x = 0.518, y = 0.530 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96113, text = "Venom Fishing: Maximum Potency (objective 3)",
          coord = { map = 2512, x = 0.639, y = 0.084 } },  -- APR route coord (converted)
        { type = "quest",  questID = 96113, text = "Venom Fishing: Maximum Potency (objective 4)",
          coord = { map = 2512, x = 0.639, y = 0.083 } },  -- APR route coord (converted)
        { type = "turnin", questID = 96113, text = "Turn in: Venom Fishing: Maximum Potency", rep = { { factionID = 2773, amount = 250 } },
          coord = { map = 2512, x = 0.572, y = 0.486 } },  -- APR route coord (converted)
    },
}
