-- ToonAge guide data: Midnight 12.1: The Curse of Ula'tek (Coiled Isle story, level 90)
-- Kind: 12.1 story chapter
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-the-curse-of-ulatek"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 70 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 63 accept steps where ATT and converted APR coords share a map: median 0.05, p90 0.07, max 2.77 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2413 Harandar, 2424 Isle of Quel'Danas, 2437 Zul'Aman, 2512 The Coiled Isle, 2536 Atal'Aman, 2576 The Den, 2639 Crypt of the Denied


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_curse_of_ulatek"] = {
    id = "midnight_curse_of_ulatek", title = "Midnight 12.1: The Curse of Ula'tek (Coiled Isle story, level 90)", expansion = "midnight",
    zone = 2512, minLevel = 90, maxLevel = 90,
    nextGuide = "midnight_coiled_isle",
    steps = {
        { type = "accept", questID = 92895, text = "Hagar's Invitation",
          coord = { map = 2393, x = 0.454, y = 0.701 } },  -- giver coord: ATT
        { type = "quest",  questID = 92895, text = "Hagar's Invitation (objective 1)",
          coord = { map = 2393, x = 0.370, y = 0.679 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92895, text = "Hagar's Invitation (objective 2)",
          coord = { map = 2413, x = 0.508, y = 0.532 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92895, text = "Turn in: Hagar's Invitation",
          coord = { map = 2413, x = 0.508, y = 0.532 } },  -- APR route coord (converted)
        { type = "accept", questID = 92899, text = "History Lesson",
          coord = { map = 2576, x = 0.439, y = 0.532 } },  -- giver coord: ATT
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [1/6]",
          coord = { map = 2413, x = 0.506, y = 0.527 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [2/6]",
          coord = { map = 2413, x = 0.506, y = 0.520 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [3/6]",
          coord = { map = 2413, x = 0.510, y = 0.521 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [4/6]",
          coord = { map = 2413, x = 0.516, y = 0.518 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [5/6]",
          coord = { map = 2413, x = 0.514, y = 0.533 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 1) [6/6]",
          coord = { map = 2413, x = 0.509, y = 0.537 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92899, text = "History Lesson (objective 2)",
          coord = { map = 2413, x = 0.508, y = 0.532 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92899, text = "Turn in: History Lesson",
          coord = { map = 2413, x = 0.508, y = 0.530 } },  -- APR route coord (converted)
        { type = "accept", questID = 92900, text = "A Favor for Kinduru",
          coord = { map = 2576, x = 0.435, y = 0.511 } },  -- giver coord: ATT
        { type = "quest",  questID = 92900, text = "A Favor for Kinduru (objective 3)",
          coord = { map = 2413, x = 0.544, y = 0.525 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92900, text = "A Favor for Kinduru (objective 4)",
          coord = { map = 2413, x = 0.388, y = 0.468 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92900, text = "Turn in: A Favor for Kinduru",
          coord = { map = 2413, x = 0.388, y = 0.468 } },  -- APR route coord (converted)
        { type = "accept", questID = 92901, text = "Revisionist History",
          coord = { map = 2413, x = 0.387, y = 0.468 } },  -- giver coord: ATT
        { type = "quest",  questID = 92901, text = "Revisionist History (objective 1)",
          coord = { map = 2413, x = 0.376, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92901, text = "Revisionist History (objective 2)",
          coord = { map = 2413, x = 0.357, y = 0.448 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92901, text = "Revisionist History (objective 3)",
          coord = { map = 2413, x = 0.350, y = 0.439 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92901, text = "Turn in: Revisionist History",
          coord = { map = 2413, x = 0.349, y = 0.440 } },  -- APR route coord (converted)
        { type = "accept", questID = 92904, text = "Return to Zul'Aman",
          coord = { map = 2413, x = 0.349, y = 0.440 } },  -- giver coord: ATT
        { type = "quest",  questID = 92904, text = "Return to Zul'Aman (objective 1)",
          coord = { map = 2413, x = 0.348, y = 0.439 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92904, text = "Return to Zul'Aman (objective 2)",
          coord = { map = 2536, x = 0.167, y = 0.229 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92904, text = "Turn in: Return to Zul'Aman",
          coord = { map = 2536, x = 0.165, y = 0.203 } },  -- APR route coord (converted)
        { type = "accept", questID = 92907, text = "Amani Answers",
          coord = { map = 2536, x = 0.164, y = 0.204 } },  -- giver coord: ATT
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 1)",
          coord = { map = 2536, x = 0.173, y = 0.199 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 2)",
          coord = { map = 2536, x = 0.158, y = 0.221 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 3)",
          coord = { map = 2536, x = 0.195, y = 0.171 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 4)",
          coord = { map = 2536, x = 0.184, y = 0.185 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 5)",
          coord = { map = 2536, x = 0.168, y = 0.204 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 6)",
          coord = { map = 2536, x = 0.143, y = 0.186 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 7)",
          coord = { map = 2536, x = 0.197, y = 0.193 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92907, text = "Amani Answers (objective 8)",
          coord = { map = 2536, x = 0.170, y = 0.205 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92907, text = "Turn in: Amani Answers",
          coord = { map = 2536, x = 0.169, y = 0.207 } },  -- APR route coord (converted)
        { type = "accept", questID = 92955, text = "The Tablets of Numazon",
          coord = { map = 2536, x = 0.169, y = 0.207 } },  -- giver coord: ATT
        { type = "turnin", questID = 92955, text = "Turn in: The Tablets of Numazon",
          coord = { map = 2437, x = 0.390, y = 0.388 } },  -- APR route coord (converted)
        { type = "accept", questID = 92957, text = "There's the Rub",
          coord = { map = 2437, x = 0.390, y = 0.388 } },  -- giver coord: ATT
        { type = "accept", questID = 92958, text = "Brain Drain",
          coord = { map = 2437, x = 0.390, y = 0.389 } },  -- giver coord: ATT
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [1/6]",
          coord = { map = 2437, x = 0.385, y = 0.383 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [2/6]",
          coord = { map = 2437, x = 0.382, y = 0.380 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [3/6]",
          coord = { map = 2437, x = 0.380, y = 0.369 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [4/6]",
          coord = { map = 2437, x = 0.377, y = 0.367 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [5/6]",
          coord = { map = 2437, x = 0.378, y = 0.379 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92957, text = "There's the Rub (objective 1) [6/6]",
          coord = { map = 2437, x = 0.369, y = 0.379 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92958, text = "Brain Drain (objective 1)",
          coord = { map = 2437, x = 0.375, y = 0.374 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92958, text = "Turn in: Brain Drain",
          coord = { map = 2437, x = 0.390, y = 0.389 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92957, text = "Turn in: There's the Rub",
          coord = { map = 2437, x = 0.390, y = 0.389 } },  -- APR route coord (converted)
        { type = "accept", questID = 92952, text = "Mission to Maisara",
          coord = { map = 2437, x = 0.390, y = 0.389 } },  -- giver coord: ATT
        { type = "quest",  questID = 92952, text = "Mission to Maisara (objective 1)",
          coord = { map = 2437, x = 0.390, y = 0.389 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92952, text = "Mission to Maisara (objective 2)",
          coord = { map = 2437, x = 0.445, y = 0.366 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92952, text = "Turn in: Mission to Maisara",
          coord = { map = 2437, x = 0.445, y = 0.367 } },  -- APR route coord (converted)
        { type = "accept", questID = 92953, text = "Memories of Malacrass",
          coord = { map = 2437, x = 0.445, y = 0.367 } },  -- giver coord: ATT
        { type = "accept", questID = 92951, text = "Digging Deeper",
          coord = { map = 2437, x = 0.445, y = 0.366 } },  -- giver coord: ATT
        { type = "quest",  questID = 92953, text = "Memories of Malacrass (objective 3)",
          coord = { map = 2437, x = 0.454, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92953, text = "Memories of Malacrass (objective 1)",
          coord = { map = 2437, x = 0.466, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92953, text = "Memories of Malacrass (objective 2)",
          coord = { map = 2437, x = 0.465, y = 0.413 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92951, text = "Digging Deeper (objective 1)",
          coord = { map = 2437, x = 0.455, y = 0.392 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92953, text = "Turn in: Memories of Malacrass",
          coord = { map = 2437, x = 0.445, y = 0.367 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92951, text = "Turn in: Digging Deeper",
          coord = { map = 2437, x = 0.445, y = 0.367 } },  -- APR route coord (converted)
        { type = "accept", questID = 92954, text = "Maisara Caverns: Master of Souls",
          coord = { map = 2437, x = 0.445, y = 0.366 } },  -- giver coord: ATT
        { type = "quest",  questID = 92954, text = "Maisara Caverns: Master of Souls (objective 3)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 92954, text = "Turn in: Maisara Caverns: Master of Souls",
          coord = { map = 2437, x = 0.445, y = 0.366 } },  -- APR route coord (converted)
        { type = "accept", questID = 93010, text = "The Serpent Shrine",
          coord = { map = 2437, x = 0.445, y = 0.366 } },  -- giver coord: ATT
        { type = "turnin", questID = 93010, text = "Turn in: The Serpent Shrine",
          coord = { map = 2536, x = 0.678, y = 0.472 } },  -- APR route coord (converted)
        { type = "accept", questID = 93011, text = "Legacy of the Amani",
          coord = { map = 2536, x = 0.678, y = 0.473 } },  -- giver coord: ATT
        { type = "quest",  questID = 93011, text = "Legacy of the Amani (objective 1)",
          coord = { map = 2536, x = 0.678, y = 0.472 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93011, text = "Legacy of the Amani (objective 2)",
          coord = { map = 2536, x = 0.631, y = 0.472 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93011, text = "Legacy of the Amani (objective 3)",
          coord = { map = 2536, x = 0.676, y = 0.476 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93011, text = "Turn in: Legacy of the Amani",
          coord = { map = 2437, x = 0.443, y = 0.667 } },  -- APR route coord (converted)
        { type = "accept", questID = 93012, text = "Dead End",
          coord = { map = 2437, x = 0.444, y = 0.667 } },  -- giver coord: ATT
        { type = "quest",  questID = 93012, text = "Dead End (objective 1)",
          coord = { map = 2437, x = 0.438, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93012, text = "Dead End (objective 2)",
          coord = { map = 2437, x = 0.436, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93012, text = "Dead End (objective 3) [1/3]",
          coord = { map = 2437, x = 0.436, y = 0.682 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93012, text = "Dead End (objective 3) [2/3]",
          coord = { map = 2437, x = 0.437, y = 0.685 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93012, text = "Dead End (objective 3) [3/3]",
          coord = { map = 2437, x = 0.439, y = 0.687 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93012, text = "Turn in: Dead End",
          coord = { map = 2437, x = 0.438, y = 0.684 } },  -- APR route coord (converted)
        { type = "accept", questID = 92916, text = "A Call for Aid",
          coord = { map = 2437, x = 0.437, y = 0.683 } },  -- giver coord: ATT
        { type = "turnin", questID = 92916, text = "Turn in: A Call for Aid",
          coord = { map = 2437, x = 0.370, y = 0.232 } },  -- APR route coord (converted)
        { type = "accept", questID = 92917, text = "Saving Those Bound",
          coord = { map = 2437, x = 0.370, y = 0.232 } },  -- giver coord: ATT
        { type = "accept", questID = 92919, text = "All Bark, All Bite",
          coord = { map = 2437, x = 0.370, y = 0.234 } },  -- giver coord: ATT
        { type = "quest",  questID = 92917, text = "Saving Those Bound (objective 2)",
          coord = { map = 2437, x = 0.381, y = 0.259 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92917, text = "Saving Those Bound (objective 1)",
          coord = { map = 2437, x = 0.383, y = 0.238 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92919, text = "All Bark, All Bite (objective 1)",
          coord = { map = 2437, x = 0.383, y = 0.238 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92917, text = "Turn in: Saving Those Bound",
          coord = { map = 2437, x = 0.375, y = 0.239 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92919, text = "Turn in: All Bark, All Bite",
          coord = { map = 2437, x = 0.375, y = 0.239 } },  -- APR route coord (converted)
        { type = "accept", questID = 93265, text = "Severing the Serpent's Head",
          coord = { map = 2437, x = 0.375, y = 0.239 } },  -- giver coord: ATT
        { type = "quest",  questID = 93265, text = "Severing the Serpent's Head (objective 1)",
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93265, text = "Severing the Serpent's Head (objective 2)",
          coord = { map = 2437, x = 0.375, y = 0.239 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93265, text = "Turn in: Severing the Serpent's Head",
          coord = { map = 2437, x = 0.374, y = 0.238 } },  -- APR route coord (converted)
        { type = "accept", questID = 92921, text = "To the Skybridge",
          coord = { map = 2437, x = 0.374, y = 0.238 } },  -- giver coord: ATT
        { type = "turnin", questID = 92921, text = "Turn in: To the Skybridge",
          coord = { map = 2437, x = 0.441, y = 0.544 } },  -- APR route coord (converted)
        { type = "accept", questID = 93266, text = "Drumming Up the Troops",
          coord = { map = 2437, x = 0.441, y = 0.544 } },  -- giver coord: ATT
        { type = "accept", questID = 93263, text = "It Just Had to Be...",
          coord = { map = 2437, x = 0.441, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 93266, text = "Drumming Up the Troops (objective 1) [1/5]",
          coord = { map = 2437, x = 0.448, y = 0.548 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93266, text = "Drumming Up the Troops (objective 1) [2/5]",
          coord = { map = 2437, x = 0.459, y = 0.545 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93266, text = "Drumming Up the Troops (objective 1) [3/5]",
          coord = { map = 2437, x = 0.469, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93266, text = "Drumming Up the Troops (objective 1) [4/5]",
          coord = { map = 2437, x = 0.473, y = 0.547 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93266, text = "Drumming Up the Troops (objective 1) [5/5]",
          coord = { map = 2437, x = 0.481, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93263, text = "It Just Had to Be... (objective 1)",
          coord = { map = 2437, x = 0.490, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93266, text = "Turn in: Drumming Up the Troops", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.501, y = 0.544 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93263, text = "Turn in: It Just Had to Be...", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2437, x = 0.501, y = 0.544 } },  -- APR route coord (converted)
        { type = "accept", questID = 92920, text = "Down With the Skies",
          coord = { map = 2437, x = 0.502, y = 0.544 } },  -- giver coord: ATT
        { type = "quest",  questID = 92920, text = "Down With the Skies (objective 1)",
          coord = { map = 2437, x = 0.506, y = 0.545 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92920, text = "Down With the Skies (objective 2)",
          coord = { map = 2437, x = 0.508, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92920, text = "Turn in: Down With the Skies", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2437, x = 0.511, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 92924, text = "What Lies Beyond the Fog",
          coord = { map = 2437, x = 0.511, y = 0.545 } },  -- giver coord: ATT
        { type = "turnin", questID = 92924, text = "Turn in: What Lies Beyond the Fog", rep = { { factionID = 2772, amount = 10 } },
          coord = { map = 2512, x = 0.578, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 95804, text = "The Children of Ula'tek",
          coord = { map = 2512, x = 0.578, y = 0.473 } },  -- giver coord: ATT
        { type = "quest",  questID = 95804, text = "The Children of Ula'tek (objective 1)",
          coord = { map = 2512, x = 0.578, y = 0.472 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95804, text = "Turn in: The Children of Ula'tek", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.578, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 93019, text = "Situation Normal, All Snaked Up",
          coord = { map = 2512, x = 0.578, y = 0.473 } },  -- giver coord: ATT
        { type = "accept", questID = 95564, text = "The Serpent's Tail",
          coord = { map = 2512, x = 0.579, y = 0.473 } },  -- giver coord: ATT
        { type = "quest",  questID = 95564, text = "The Serpent's Tail (objective 1)",
          coord = { map = 2512, x = 0.557, y = 0.444 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95564, text = "The Serpent's Tail (objective 2)",
          coord = { map = 2512, x = 0.522, y = 0.386 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95564, text = "The Serpent's Tail (objective 3)",
          coord = { map = 2512, x = 0.531, y = 0.365 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95564, text = "The Serpent's Tail (objective 4)",
          coord = { map = 2512, x = 0.511, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest",  questID = 95564, text = "The Serpent's Tail (objective 5)",
          coord = { map = 2512, x = 0.514, y = 0.314 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93019, text = "Situation Normal, All Snaked Up (objective 1)",
          coord = { map = 2512, x = 0.506, y = 0.367 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95564, text = "Turn in: The Serpent's Tail", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.470, y = 0.313 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93019, text = "Turn in: Situation Normal, All Snaked Up", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.470, y = 0.313 } },  -- APR route coord (converted)
        { type = "accept", questID = 93018, text = "Them That Were Lost",
          coord = { map = 2512, x = 0.470, y = 0.313 } },  -- giver coord: ATT
        { type = "accept", questID = 93022, text = "Fire, the Only Way to Be Sure",
          coord = { map = 2512, x = 0.470, y = 0.313 } },  -- giver coord: ATT
        { type = "quest",  questID = 93018, text = "Them That Were Lost (objective 1) [4/12]",
          coord = { map = 2512, x = 0.471, y = 0.299 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93018, text = "Them That Were Lost (objective 1) [8/12]",
          coord = { map = 2512, x = 0.447, y = 0.300 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93018, text = "Them That Were Lost (objective 1) [12/12]",
          coord = { map = 2512, x = 0.463, y = 0.276 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93022, text = "Fire, the Only Way to Be Sure (objective 1,2)",
          coord = { map = 2512, x = 0.462, y = 0.302 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93018, text = "Turn in: Them That Were Lost", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.459, y = 0.294 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93022, text = "Turn in: Fire, the Only Way to Be Sure", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.459, y = 0.294 } },  -- APR route coord (converted)
        { type = "accept", questID = 93023, text = "Death of Furies",
          coord = { map = 2512, x = 0.459, y = 0.294 } },  -- giver coord: ATT
        { type = "quest",  questID = 93023, text = "Death of Furies (objective 1)",
          coord = { map = 2512, x = 0.453, y = 0.285 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93023, text = "Turn in: Death of Furies", rep = { { factionID = 2772, amount = 100 } },
          coord = { map = 2512, x = 0.448, y = 0.279 } },  -- APR route coord (converted)
        { type = "accept", questID = 93024, text = "Come With Me",
          coord = { map = 2512, x = 0.448, y = 0.279 } },  -- giver coord: ATT
        { type = "quest",  questID = 93024, text = "Come With Me (objective 1)",
          coord = { map = 2512, x = 0.448, y = 0.279 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93024, text = "Come With Me (objective 2)",
          coord = { map = 2512, x = 0.446, y = 0.274 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93024, text = "Turn in: Come With Me", rep = { { factionID = 2772, amount = 1500 } },
          coord = { map = 2512, x = 0.583, y = 0.461 } },  -- APR route coord (converted)
        { type = "accept", questID = 93454, text = "Words to Hear",
          coord = { map = 2512, x = 0.584, y = 0.461 } },  -- giver coord: ATT
        { type = "turnin", questID = 93454, text = "Turn in: Words to Hear", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.584, y = 0.456 } },  -- APR route coord (converted)
        { type = "accept", questID = 92925, text = "The Glint of History",
          coord = { map = 2512, x = 0.584, y = 0.456 } },  -- giver coord: ATT
        { type = "quest",  questID = 92925, text = "The Glint of History (objective 1)",
          coord = { map = 2512, x = 0.475, y = 0.735 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92925, text = "The Glint of History (objective 2)",
          coord = { map = 2512, x = 0.474, y = 0.735 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92925, text = "Turn in: The Glint of History", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.475, y = 0.735 } },  -- APR route coord (converted)
        { type = "accept", questID = 92927, text = "Echoed Steps",
          coord = { map = 2512, x = 0.475, y = 0.735 } },  -- giver coord: ATT
        { type = "quest",  questID = 92927, text = "Echoed Steps (objective 1)",
          coord = { map = 2512, x = 0.469, y = 0.737 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92927, text = "Echoed Steps (objective 2)",
          coord = { map = 2512, x = 0.463, y = 0.745 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92927, text = "Echoed Steps (objective 3)",
          coord = { map = 2512, x = 0.458, y = 0.754 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92927, text = "Echoed Steps (objective 4)",
          coord = { map = 2512, x = 0.454, y = 0.760 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92927, text = "Turn in: Echoed Steps", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.452, y = 0.761 } },  -- APR route coord (converted)
        { type = "accept", questID = 92928, text = "What Was Buried",
          coord = { map = 2639, x = 0.699, y = 0.136 } },  -- giver coord: ATT
        { type = "accept", questID = 92929, text = "Lurking in the Dark",
          coord = { map = 2639, x = 0.699, y = 0.136 } },  -- giver coord: ATT
        { type = "quest",  questID = 92928, text = "What Was Buried (objective 1)",
          coord = { map = 2512, x = 0.454, y = 0.783 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92928, text = "What Was Buried (objective 3)",
          coord = { map = 2512, x = 0.440, y = 0.777 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92928, text = "What Was Buried (objective 2)",
          coord = { map = 2512, x = 0.434, y = 0.764 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92929, text = "Lurking in the Dark (objective 1)",
          coord = { map = 2512, x = 0.435, y = 0.763 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92928, text = "Turn in: What Was Buried", rep = { { factionID = 2772, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 92929, text = "Turn in: Lurking in the Dark", rep = { { factionID = 2772, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 92930, text = "Written by the Victors",
          coord = { map = 2639, x = 0.453, y = 0.452 } },  -- giver coord: ATT
        { type = "quest",  questID = 92930, text = "Written by the Victors (objective 1)",
          coord = { map = 2512, x = 0.440, y = 0.790 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92930, text = "Written by the Victors (objective 2)",
          coord = { map = 2512, x = 0.432, y = 0.788 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92930, text = "Turn in: Written by the Victors", rep = { { factionID = 2772, amount = 1500 } },
          coord = { map = 2512, x = 0.575, y = 0.491 } },  -- APR route coord (converted)
        { type = "accept", questID = 92931, text = "Delay the Venom",
          coord = { map = 2512, x = 0.575, y = 0.491 } },  -- giver coord: ATT
        { type = "quest",  questID = 92931, text = "Delay the Venom (objective 1)",
          coord = { map = 2512, x = 0.576, y = 0.490 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92931, text = "Delay the Venom (objective 2)",
          coord = { map = 2512, x = 0.575, y = 0.491 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92931, text = "Delay the Venom (objective 3)",
          coord = { map = 2512, x = 0.575, y = 0.490 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92931, text = "Delay the Venom (objective 5)",
          coord = { map = 2512, x = 0.573, y = 0.489 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92931, text = "Delay the Venom (objective 4)",
          coord = { map = 2512, x = 0.575, y = 0.477 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92931, text = "Turn in: Delay the Venom", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.640, y = 0.566 } },  -- APR route coord (converted)
        { type = "accept", questID = 92932, text = "Clear the Swamp",
          coord = { map = 2512, x = 0.640, y = 0.566 } },  -- giver coord: ATT
        { type = "accept", questID = 92933, text = "Haunted Shore",
          coord = { map = 2512, x = 0.640, y = 0.566 } },  -- giver coord: ATT
        { type = "quest",  questID = 92933, text = "Haunted Shore (objective 1)",
          coord = { map = 2512, x = 0.647, y = 0.592 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92932, text = "Clear the Swamp (objective 1)",
          coord = { map = 2512, x = 0.655, y = 0.608 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92933, text = "Haunted Shore (objective 2)",
          coord = { map = 2512, x = 0.655, y = 0.608 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92933, text = "Turn in: Haunted Shore", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.675, y = 0.623 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92932, text = "Turn in: Clear the Swamp", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.675, y = 0.623 } },  -- APR route coord (converted)
        { type = "accept", questID = 92938, text = "Site of Terror",
          coord = { map = 2512, x = 0.675, y = 0.623 } },  -- giver coord: ATT
        { type = "accept", questID = 93063, text = "Broken Spears",
          coord = { map = 2512, x = 0.675, y = 0.623 } },  -- giver coord: ATT
        { type = "quest",  questID = 92938, text = "Site of Terror (objective 1)",
          coord = { map = 2512, x = 0.672, y = 0.662 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92938, text = "Site of Terror (objective 2)",
          coord = { map = 2512, x = 0.712, y = 0.648 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92938, text = "Site of Terror (objective 3)",
          coord = { map = 2512, x = 0.705, y = 0.623 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93063, text = "Broken Spears (objective 1)",
          coord = { map = 2512, x = 0.685, y = 0.631 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92938, text = "Site of Terror (objective 4)",
          coord = { map = 2512, x = 0.703, y = 0.659 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93063, text = "Turn in: Broken Spears", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.703, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92938, text = "Turn in: Site of Terror", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.703, y = 0.658 } },  -- APR route coord (converted)
        { type = "accept", questID = 93064, text = "Awe of She",
          coord = { map = 2512, x = 0.703, y = 0.658 } },  -- giver coord: ATT
        { type = "quest",  questID = 93064, text = "Awe of She (objective 1)",
          coord = { map = 2512, x = 0.703, y = 0.658 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93064, text = "Turn in: Awe of She", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.692, y = 0.642 } },  -- APR route coord (converted)
        { type = "accept", questID = 92935, text = "Pushed to the Brink",
          coord = { map = 2512, x = 0.692, y = 0.642 } },  -- giver coord: ATT
        { type = "accept", questID = 92934, text = "Fuel the Calling",
          coord = { map = 2512, x = 0.693, y = 0.641 } },  -- giver coord: ATT
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 1) [2/12]",
          coord = { map = 2512, x = 0.704, y = 0.624 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 1) [5/12]",
          coord = { map = 2512, x = 0.686, y = 0.627 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 2)",
          coord = { map = 2512, x = 0.686, y = 0.627 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 1) [7/12]",
          coord = { map = 2512, x = 0.683, y = 0.634 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 1) [9/12]",
          coord = { map = 2512, x = 0.681, y = 0.645 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92934, text = "Fuel the Calling (objective 1) [12/12]",
          coord = { map = 2512, x = 0.680, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92935, text = "Pushed to the Brink (objective 1)",
          coord = { map = 2512, x = 0.685, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92934, text = "Turn in: Fuel the Calling", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.693, y = 0.641 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92935, text = "Turn in: Pushed to the Brink", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.692, y = 0.642 } },  -- APR route coord (converted)
        { type = "accept", questID = 92936, text = "The Summoning of Ula'tek",
          coord = { map = 2512, x = 0.692, y = 0.642 } },  -- giver coord: ATT
        { type = "quest",  questID = 92936, text = "The Summoning of Ula'tek (objective 1)",
          coord = { map = 2512, x = 0.691, y = 0.640 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92936, text = "Turn in: The Summoning of Ula'tek", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.703, y = 0.657 } },  -- APR route coord (converted)
        { type = "accept", questID = 92937, text = "Awakened Evil",
          coord = { map = 2512, x = 0.703, y = 0.657 } },  -- giver coord: ATT
        { type = "quest",  questID = 92937, text = "Awakened Evil (objective 1)",
          coord = { map = 2512, x = 0.703, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92937, text = "Awakened Evil (objective 2)",
          coord = { map = 2512, x = 0.690, y = 0.640 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92937, text = "Turn in: Awakened Evil", rep = { { factionID = 2772, amount = 1500 } },
          coord = { map = 2512, x = 0.575, y = 0.491 } },  -- APR route coord (converted)
        { type = "accept", questID = 93417, text = "The Vaults of Atal'Utek: Altar of Fangs",
          coord = { map = 2512, x = 0.575, y = 0.491 } },  -- giver coord: ATT
        { type = "quest",  questID = 93417, text = "The Vaults of Atal'Utek: Altar of Fangs (objective 1)",
          coord = { map = 2512, x = 0.378, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 98388, text = "Into the Vaults of Atal'Utek",
          coord = { map = 2512, x = 0.378, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 2)",
          coord = { map = 2512, x = 0.375, y = 0.617 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 3)",
          coord = { map = 2512, x = 0.377, y = 0.617 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 4)",
          coord = { map = 2512, x = 0.388, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 5)",
          coord = { map = 2512, x = 0.403, y = 0.573 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 6)",
          coord = { map = 2512, x = 0.389, y = 0.572 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 7)",
          coord = { map = 2512, x = 0.403, y = 0.573 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 8)",
          coord = { map = 2512, x = 0.361, y = 0.487 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98388, text = "Into the Vaults of Atal'Utek (objective 9)",
          coord = { map = 2512, x = 0.361, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 98388, text = "Turn in: Into the Vaults of Atal'Utek",
          coord = { map = 2512, x = 0.378, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 97640, text = "Vaults of Atal'Utek: One Coin Too Many",
          coord = { map = 2512, x = 0.378, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 98515, text = "Vaults of Atal'Utek: A Toxic Tour",
          coord = { map = 2512, x = 0.378, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 97640, text = "Vaults of Atal'Utek: One Coin Too Many (objective 1)",
          coord = { map = 2512, x = 0.392, y = 0.656 } },  -- APR route coord (converted)
        { type = "turnin", questID = 97640, text = "Turn in: Vaults of Atal'Utek: One Coin Too Many",
          coord = { map = 2512, x = 0.392, y = 0.656 } },  -- APR route coord (converted)
        { type = "accept", questID = 98428, text = "Vaults of Atal'Utek: The Altar of Corrosion",
          coord = { map = 2512, x = 0.392, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98428, text = "Vaults of Atal'Utek: The Altar of Corrosion (objective 1)",
          coord = { map = 2512, x = 0.392, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest",  questID = 98428, text = "Vaults of Atal'Utek: The Altar of Corrosion (objective 2)",
          coord = { map = 2512, x = 0.392, y = 0.655 } },  -- APR route coord (converted)
        { type = "turnin", questID = 98428, text = "Turn in: Vaults of Atal'Utek: The Altar of Corrosion",
          coord = { map = 2512, x = 0.392, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93417, text = "The Vaults of Atal'Utek: Altar of Fangs (objective 2)",
          coord = { map = 2512, x = 0.377, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93417, text = "The Vaults of Atal'Utek: Altar of Fangs (objective 3)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "quest",  questID = 93417, text = "The Vaults of Atal'Utek: Altar of Fangs (objective 5)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 93417, text = "Turn in: The Vaults of Atal'Utek: Altar of Fangs", rep = { { factionID = 2772, amount = 250 } },
          coord = { map = 2512, x = 0.573, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 93419, text = "Nature of Her Wounds",
          coord = { map = 2512, x = 0.573, y = 0.486 } },  -- giver coord: ATT
        { type = "quest",  questID = 93419, text = "Nature of Her Wounds (objective 1)",
          coord = { map = 2512, x = 0.574, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93419, text = "Nature of Her Wounds (objective 2)",
          coord = { map = 2512, x = 0.574, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93419, text = "Turn in: Nature of Her Wounds", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2512, x = 0.573, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 93418, text = "The Venomous Abyss",
          coord = { map = 2512, x = 0.573, y = 0.487 } },  -- giver coord: ATT
        { type = "quest",  questID = 93418, text = "The Venomous Abyss (objective 2)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 93418, text = "Turn in: The Venomous Abyss", rep = { { factionID = 2772, amount = 1500 } },
          coord = { map = 2512, x = 0.217, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 93420, text = "Lor'themar's Judgement",
          coord = { map = 2512, x = 0.217, y = 0.649 } },  -- giver coord: ATT
        { type = "quest",  questID = 93420, text = "Lor'themar's Judgement (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93420, text = "Turn in: Lor'themar's Judgement", rep = { { factionID = 2772, amount = 50 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 95973, text = "Echoes of the Darkwell",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "turnin", questID = 95973, text = "Turn in: Echoes of the Darkwell",
          coord = { map = 2393, x = 0.462, y = 0.472 } },  -- APR route coord (converted)
        { type = "accept", questID = 94519, text = "What Hope in the Light?",
          coord = { map = 2393, x = 0.462, y = 0.472 } },  -- giver coord: ATT
        { type = "quest",  questID = 94519, text = "What Hope in the Light? (objective 1)",
          coord = { map = 2424, x = 0.522, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94519, text = "Turn in: What Hope in the Light?",
          coord = { map = 2424, x = 0.522, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 94520, text = "Resurgence in Deatholme",
          coord = { map = 2424, x = 0.523, y = 0.487 } },  -- giver coord: ATT
        { type = "turnin", questID = 94520, text = "Turn in: Resurgence in Deatholme",
          coord = { map = 2395, x = 0.438, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 94521, text = "The Direct Method",
          coord = { map = 2395, x = 0.438, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 94522, text = "They Always Write It Down",
          coord = { map = 2395, x = 0.437, y = 0.824 } },  -- giver coord: ATT
        { type = "quest",  questID = 94522, text = "They Always Write It Down (objective 1)",
          coord = { map = 2395, x = 0.434, y = 0.846 } },  -- APR route coord (converted)
        { type = "accept", questID = 94523, text = "My Poor Beautiful Self",
          coord = { map = 2395, x = 0.430, y = 0.850 } },  -- giver coord: ATT
        { type = "quest",  questID = 94522, text = "They Always Write It Down (objective 2)",
          coord = { map = 2395, x = 0.414, y = 0.862 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94522, text = "They Always Write It Down (objective 3)",
          coord = { map = 2395, x = 0.417, y = 0.881 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94523, text = "My Poor Beautiful Self (objective 1)",
          coord = { map = 2395, x = 0.440, y = 0.886 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94522, text = "They Always Write It Down (objective 4)",
          coord = { map = 2395, x = 0.450, y = 0.874 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94521, text = "The Direct Method (objective 1)",
          coord = { map = 2395, x = 0.418, y = 0.882 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94523, text = "Turn in: My Poor Beautiful Self",
          coord = { map = 2395, x = 0.430, y = 0.850 } },  -- APR route coord (converted)
        { type = "accept", questID = 94521, text = "The Direct Method",
          coord = { map = 2395, x = 0.438, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 94522, text = "They Always Write It Down",
          coord = { map = 2395, x = 0.437, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 94524, text = "Under New Management",
          coord = { map = 2395, x = 0.429, y = 0.850 } },  -- giver coord: ATT
        { type = "accept", questID = 94525, text = "A Comeback Story",
          coord = { map = 2395, x = 0.430, y = 0.850 } },  -- giver coord: ATT
        { type = "quest",  questID = 94524, text = "Under New Management (objective 3)",
          coord = { map = 2395, x = 0.434, y = 0.863 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94524, text = "Under New Management (objective 2)",
          coord = { map = 2395, x = 0.434, y = 0.878 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94524, text = "Under New Management (objective 4)",
          coord = { map = 2395, x = 0.418, y = 0.862 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94525, text = "A Comeback Story (objective 1)",
          coord = { map = 2395, x = 0.431, y = 0.869 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94524, text = "Turn in: Under New Management",
          coord = { map = 2395, x = 0.427, y = 0.886 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94525, text = "Turn in: A Comeback Story",
          coord = { map = 2395, x = 0.427, y = 0.885 } },  -- APR route coord (converted)
        { type = "accept", questID = 94526, text = "Verifiably Untrustworthy",
          coord = { map = 2395, x = 0.427, y = 0.885 } },  -- giver coord: ATT
        { type = "quest",  questID = 94526, text = "Verifiably Untrustworthy (objective 1)",
          coord = { map = 2395, x = 0.426, y = 0.887 } },  -- APR coord converted on map 2395 (step zone 2512) - UNVERIFIED map
        { type = "quest",  questID = 94526, text = "Verifiably Untrustworthy (objective 2)",
          coord = { map = 2395, x = 0.426, y = 0.889 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94526, text = "Turn in: Verifiably Untrustworthy",
          coord = { map = 2395, x = 0.425, y = 0.892 } },  -- APR route coord (converted)
        { type = "accept", questID = 94527, text = "Null Space",
          coord = { map = 2395, x = 0.425, y = 0.892 } },  -- giver coord: ATT
        { type = "quest",  questID = 94527, text = "Null Space (objective 1)",
          coord = { map = 2395, x = 0.424, y = 0.894 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94527, text = "Null Space (objective 2)",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 94527, text = "Turn in: Null Space",
          coord = { map = 2437, x = 0.388, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 94528, text = "Carving Out Room",
          coord = { map = 2437, x = 0.388, y = 0.741 } },  -- giver coord: ATT
        { type = "accept", questID = 94529, text = "A Dark Shadow Looms",
          coord = { map = 2437, x = 0.389, y = 0.740 } },  -- giver coord: ATT
        { type = "quest",  questID = 94529, text = "A Dark Shadow Looms (objective 2) [1/3]",
          coord = { map = 2437, x = 0.385, y = 0.720 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94529, text = "A Dark Shadow Looms (objective 2) [2/3]",
          coord = { map = 2437, x = 0.370, y = 0.698 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94529, text = "A Dark Shadow Looms (objective 2) [3/3]",
          coord = { map = 2437, x = 0.357, y = 0.735 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94528, text = "Carving Out Room (objective 1)",
          coord = { map = 2437, x = 0.365, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94529, text = "Turn in: A Dark Shadow Looms",
          coord = { map = 2437, x = 0.389, y = 0.741 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94528, text = "Turn in: Carving Out Room",
          coord = { map = 2437, x = 0.389, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 94530, text = "The Call of the Void",
          coord = { map = 2437, x = 0.389, y = 0.740 } },  -- giver coord: ATT
        { type = "quest",  questID = 94530, text = "The Call of the Void (objective 1)",
          coord = { map = 2437, x = 0.389, y = 0.740 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94530, text = "The Call of the Void (objective 2)",
          coord = { map = 2437, x = 0.381, y = 0.732 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94530, text = "The Call of the Void (objective 3)",
          coord = { map = 2437, x = 0.387, y = 0.740 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94530, text = "Turn in: The Call of the Void",
          coord = { map = 2437, x = 0.388, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 94531, text = "Like Mother, Like Son",
          coord = { map = 2437, x = 0.388, y = 0.741 } },  -- giver coord: ATT
        { type = "turnin", questID = 94531, text = "Turn in: Like Mother, Like Son",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}
