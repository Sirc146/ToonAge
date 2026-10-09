-- ToonAge guide data: Midnight: Harandar (Campaign + side quests)
-- Kind: APR "sojourner" route
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Harandar"
--    in Routes/Midnight/Midnight-Harandar.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 135 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 130 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 0.26 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2413 Harandar, 2576 The Den


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_harandar_full"] = {
    id = "midnight_harandar_full", title = "Midnight: Harandar (Campaign + side quests)", expansion = "midnight",
    zone = 2413, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_zulaman_full",
    steps = {
        -- (APR: grind/continue to level 83 before the next step)
        { type = "accept", questID = 89402, text = "Harandar",
          coord = { map = 2393, x = 0.455, y = 0.704 } },  -- giver coord: ATT
        { type = "turnin", questID = 89402, text = "Turn in: Harandar",
          coord = { map = 2395, x = 0.454, y = 0.455 } },  -- APR route coord (converted)
        { type = "accept", questID = 86899, text = "The Root Cause",
          coord = { map = 2395, x = 0.454, y = 0.455 } },  -- giver coord: ATT
        { type = "quest",  questID = 86899, text = "The Root Cause (objective 1)",
          coord = { map = 2395, x = 0.454, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86899, text = "The Root Cause (objective 2)",
          coord = { map = 2395, x = 0.451, y = 0.469 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86899, text = "Turn in: The Root Cause",
          coord = { map = 2413, x = 0.756, y = 0.536 } },  -- APR route coord (converted)
        { type = "accept", questID = 86900, text = "To Har'athir",
          coord = { map = 2413, x = 0.756, y = 0.536 } },  -- giver coord: ATT
        { type = "quest",  questID = 86900, text = "To Har'athir (objective 1,2)",
          coord = { map = 2413, x = 0.754, y = 0.518 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86900, text = "To Har'athir (objective 3)",
          coord = { map = 2413, x = 0.762, y = 0.503 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86900, text = "To Har'athir (objective 4)",
          coord = { map = 2413, x = 0.744, y = 0.524 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86900, text = "To Har'athir (objective 5)",
          coord = { map = 2413, x = 0.740, y = 0.511 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86900, text = "To Har'athir (objective 6)",
          coord = { map = 2413, x = 0.740, y = 0.509 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86900, text = "Turn in: To Har'athir",
          coord = { map = 2413, x = 0.700, y = 0.515 } },  -- APR route coord (converted)
        { type = "accept", questID = 86901, text = "The Rift and the Den",
          coord = { map = 2413, x = 0.700, y = 0.515 } },  -- giver coord: ATT
        { type = "quest",  questID = 86901, text = "The Rift and the Den (objective 2)",
          coord = { map = 2413, x = 0.549, y = 0.511 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86901, text = "Turn in: The Rift and the Den",
          coord = { map = 2413, x = 0.548, y = 0.512 } },  -- APR route coord (converted)
        { type = "accept", questID = 86929, text = "The Council Assembles",
          coord = { map = 2413, x = 0.548, y = 0.512 } },  -- giver coord: ATT
        { type = "quest",  questID = 86929, text = "The Council Assembles (objective 1)",
          coord = { map = 2413, x = 0.548, y = 0.512 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86929, text = "Turn in: The Council Assembles",
          coord = { map = 2413, x = 0.508, y = 0.534 } },  -- APR route coord (converted)
        { type = "accept", questID = 86907, text = "The Den of Echoes",
          coord = { map = 2576, x = 0.438, y = 0.543 } },  -- giver coord: ATT
        { type = "accept", questID = 93416, text = "Delver's Call: The Gulf of Memory",
          coord = { map = 2413, x = 0.529, y = 0.517 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86907, text = "Turn in: The Den of Echoes", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.388, y = 0.469 } },  -- APR route coord (converted)
        { type = "accept", questID = 86911, text = "Echoes and Memories",
          coord = { map = 2413, x = 0.388, y = 0.469 } },  -- giver coord: ATT
        { type = "quest",  questID = 86911, text = "Echoes and Memories (objective 1)",
          coord = { map = 2413, x = 0.388, y = 0.469 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86911, text = "Echoes and Memories (objective 2)",
          coord = { map = 2413, x = 0.375, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86911, text = "Echoes and Memories (objective 3)",
          coord = { map = 2413, x = 0.376, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86911, text = "Echoes and Memories (objective 4)",
          coord = { map = 2413, x = 0.362, y = 0.459 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86911, text = "Turn in: Echoes and Memories", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.361, y = 0.443 } },  -- APR route coord (converted)
        { type = "accept", questID = 90094, text = "Echo of the Hunt",
          coord = { map = 2413, x = 0.361, y = 0.443 } },  -- giver coord: ATT
        { type = "quest",  questID = 90094, text = "Echo of the Hunt (objective 1)",
          coord = { map = 2413, x = 0.362, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90094, text = "Echo of the Hunt (objective 3,2)",
          coord = { map = 2413, x = 0.355, y = 0.459 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90094, text = "Turn in: Echo of the Hunt", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.349, y = 0.428 } },  -- APR route coord (converted)
        { type = "accept", questID = 90095, text = "Echo of the Call",
          coord = { map = 2413, x = 0.349, y = 0.428 } },  -- giver coord: ATT
        { type = "quest",  questID = 90095, text = "Echo of the Call (objective 1)",
          coord = { map = 2413, x = 0.349, y = 0.427 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90095, text = "Echo of the Call (objective 2)",
          coord = { map = 2413, x = 0.342, y = 0.437 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90095, text = "Turn in: Echo of the Call", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.339, y = 0.448 } },  -- APR route coord (converted)
        { type = "accept", questID = 86912, text = "Down the Rootways",
          coord = { map = 2413, x = 0.339, y = 0.448 } },  -- giver coord: ATT
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 1)",
          coord = { map = 2413, x = 0.389, y = 0.469 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 2)",
          coord = { map = 2413, x = 0.392, y = 0.546 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 3)",
          coord = { map = 2413, x = 0.342, y = 0.431 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86912, text = "Turn in: Down the Rootways", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.348, y = 0.250 } },  -- APR route coord (converted)
        { type = "accept", questID = 86913, text = "A Hut in Har'mara",
          coord = { map = 2413, x = 0.348, y = 0.250 } },  -- giver coord: ATT
        { type = "turnin", questID = 86913, text = "Turn in: A Hut in Har'mara", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.349, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 86914, text = "Tending to Har'mara",
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- giver coord: ATT
        { type = "accept", questID = 86956, text = "The Traveling Flowers",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- giver coord: ATT
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [10%]",
          coord = { map = 2413, x = 0.360, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [17%]",
          coord = { map = 2413, x = 0.362, y = 0.249 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [24%]",
          coord = { map = 2413, x = 0.359, y = 0.244 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [31%]",
          coord = { map = 2413, x = 0.362, y = 0.244 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [41%]",
          coord = { map = 2413, x = 0.365, y = 0.244 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86956, text = "The Traveling Flowers (objective 2)",
          coord = { map = 2413, x = 0.369, y = 0.240 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [48%]",
          coord = { map = 2413, x = 0.371, y = 0.239 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [58%]",
          coord = { map = 2413, x = 0.374, y = 0.239 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86956, text = "The Traveling Flowers (objective 1)",
          coord = { map = 2413, x = 0.370, y = 0.258 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [65%]",
          coord = { map = 2413, x = 0.369, y = 0.256 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [72%]",
          coord = { map = 2413, x = 0.371, y = 0.259 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [82%]",
          coord = { map = 2413, x = 0.373, y = 0.261 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [89%]",
          coord = { map = 2413, x = 0.369, y = 0.268 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1) [99%]",
          coord = { map = 2413, x = 0.368, y = 0.268 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86914, text = "Tending to Har'mara (objective 1)",
          coord = { map = 2413, x = 0.367, y = 0.269 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86956, text = "The Traveling Flowers (objective 4)",
          coord = { map = 2413, x = 0.357, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86956, text = "The Traveling Flowers (objective 3)",
          coord = { map = 2413, x = 0.349, y = 0.274 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86956, text = "Turn in: The Traveling Flowers", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86914, text = "Turn in: Tending to Har'mara", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- APR route coord (converted)
        { type = "accept", questID = 86910, text = "Koozat's Trample",
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- giver coord: ATT
        { type = "quest",  questID = 86910, text = "Koozat's Trample (objective 1)",
          coord = { map = 2413, x = 0.356, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86910, text = "Turn in: Koozat's Trample", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 86973, text = "Halting Harm in Har'mara",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- giver coord: ATT
        { type = "accept", questID = 86942, text = "Culling the Spread",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- giver coord: ATT
        { type = "accept", questID = 89034, text = "Burning Bitterblooms",
          coord = { map = 2413, x = 0.357, y = 0.252 } },  -- giver coord: ATT
        { type = "quest",  questID = 86942, text = "Culling the Spread (objective 4)",
          coord = { map = 2413, x = 0.369, y = 0.240 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86942, text = "Culling the Spread (objective 3)",
          coord = { map = 2413, x = 0.370, y = 0.256 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86942, text = "Culling the Spread (objective 2,1)",
          coord = { map = 2413, x = 0.357, y = 0.277 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86973, text = "Halting Harm in Har'mara (objective 1)",
          coord = { map = 2413, x = 0.359, y = 0.256 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89034, text = "Burning Bitterblooms (objective 1)",
          coord = { map = 2413, x = 0.359, y = 0.256 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89034, text = "Turn in: Burning Bitterblooms", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.357, y = 0.252 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86973, text = "Turn in: Halting Harm in Har'mara", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86942, text = "Turn in: Culling the Spread", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 86944, text = "Seeds of the Rift",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- giver coord: ATT
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 1)",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 2)",
          coord = { map = 2413, x = 0.348, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 3)",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86944, text = "Turn in: Seeds of the Rift", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.349, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 86930, text = "To Sow the Seed",
          coord = { map = 2413, x = 0.349, y = 0.249 } },  -- giver coord: ATT
        { type = "turnin", questID = 93416, text = "Turn in: Delver's Call: The Gulf of Memory",
          coord = { map = 2413, x = 0.542, y = 0.531 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86930, text = "Turn in: To Sow the Seed", rep = { { factionID = 2704, amount = 1500 } },
          coord = { map = 2413, x = 0.508, y = 0.532 } },  -- APR route coord (converted)
        { type = "accept", questID = 86864, text = "Watch the Den",
          coord = { map = 2576, x = 0.442, y = 0.526 } },  -- giver coord: ATT
        { type = "quest",  questID = 86864, text = "Watch the Den (objective 3)",
          coord = { map = 2413, x = 0.541, y = 0.532 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86864, text = "Watch the Den (objective 2)",
          coord = { map = 2413, x = 0.509, y = 0.507 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86864, text = "Watch the Den (objective 1)",
          coord = { map = 2413, x = 0.509, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86864, text = "Watch the Den (objective 4)",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86864, text = "Turn in: Watch the Den", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- APR route coord (converted)
        { type = "accept", questID = 86836, text = "The Hunter Awaits",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- giver coord: ATT
        { type = "quest",  questID = 86836, text = "The Hunter Awaits (objective 2)",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86836, text = "The Hunter Awaits (objective 1)",
          coord = { map = 2413, x = 0.619, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86836, text = "Turn in: The Hunter Awaits", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.620, y = 0.546 } },  -- APR route coord (converted)
        { type = "accept", questID = 86855, text = "Consequences of Our Duty",
          coord = { map = 2413, x = 0.620, y = 0.546 } },  -- giver coord: ATT
        { type = "accept", questID = 86851, text = "The Foundation of Aln",
          coord = { map = 2413, x = 0.620, y = 0.546 } },  -- giver coord: ATT
        { type = "quest",  questID = 86855, text = "Consequences of Our Duty (objective 1) [1/5]", useItem = 243595,
          coord = { map = 2413, x = 0.579, y = 0.543 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86855, text = "Consequences of Our Duty (objective 1) [2/5]",
          coord = { map = 2413, x = 0.594, y = 0.568 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86855, text = "Consequences of Our Duty (objective 1) [3/5]",
          coord = { map = 2413, x = 0.606, y = 0.533 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86855, text = "Consequences of Our Duty (objective 1) [4/5]",
          coord = { map = 2413, x = 0.616, y = 0.536 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86855, text = "Consequences of Our Duty (objective 1) [5/5]",
          coord = { map = 2413, x = 0.626, y = 0.524 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86851, text = "The Foundation of Aln (objective 1)",
          coord = { map = 2413, x = 0.601, y = 0.533 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86851, text = "Turn in: The Foundation of Aln", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86855, text = "Turn in: Consequences of Our Duty", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 86856, text = "Dampening the Call",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 86856, text = "Dampening the Call (objective 1)",
          coord = { map = 2413, x = 0.620, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86856, text = "Turn in: Dampening the Call", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 86857, text = "Descent into the Rift",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 1)",
          coord = { map = 2413, x = 0.641, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 2)",
          coord = { map = 2413, x = 0.640, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 3)",
          coord = { map = 2413, x = 0.617, y = 0.562 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86857, text = "Turn in: Descent into the Rift", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.617, y = 0.561 } },  -- APR route coord (converted)
        { type = "accept", questID = 86858, text = "The Madness Roots Deep",
          coord = { map = 2413, x = 0.617, y = 0.561 } },  -- giver coord: ATT
        { type = "quest",  questID = 86858, text = "The Madness Roots Deep (objective 1)",
          coord = { map = 2413, x = 0.598, y = 0.574 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86858, text = "Turn in: The Madness Roots Deep", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.611, y = 0.573 } },  -- APR route coord (converted)
        { type = "accept", questID = 86859, text = "Grinding Out a Solution",
          coord = { map = 2413, x = 0.611, y = 0.573 } },  -- giver coord: ATT
        { type = "accept", questID = 86861, text = "Herding Manifestations",
          coord = { map = 2413, x = 0.611, y = 0.573 } },  -- giver coord: ATT
        { type = "accept", questID = 86860, text = "Before They Grow",
          coord = { map = 2413, x = 0.611, y = 0.573 } },  -- giver coord: ATT
        { type = "quest",  questID = 86861, text = "Herding Manifestations (objective 1) [1/3]",
          coord = { map = 2413, x = 0.626, y = 0.580 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86861, text = "Herding Manifestations (objective 1) [2/3]",
          coord = { map = 2413, x = 0.625, y = 0.592 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86861, text = "Herding Manifestations (objective 1) [3/3]",
          coord = { map = 2413, x = 0.634, y = 0.591 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86859, text = "Grinding Out a Solution (objective 1)",
          coord = { map = 2413, x = 0.651, y = 0.612 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86860, text = "Before They Grow (objective 2)",
          coord = { map = 2413, x = 0.651, y = 0.612 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86859, text = "Turn in: Grinding Out a Solution", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86860, text = "Turn in: Before They Grow", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86861, text = "Turn in: Herding Manifestations", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86862, text = "The Greater They Aln",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86862, text = "The Greater They Aln (objective 1)",
          coord = { map = 2413, x = 0.649, y = 0.573 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86862, text = "The Greater They Aln (objective 2)",
          coord = { map = 2413, x = 0.650, y = 0.574 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86862, text = "Turn in: The Greater They Aln", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86865, text = "In Search of the Problem",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86865, text = "In Search of the Problem (objective 1)",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86865, text = "Turn in: In Search of the Problem", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.313, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 86866, text = "Can We Heal This?",
          coord = { map = 2413, x = 0.314, y = 0.649 } },  -- giver coord: ATT
        { type = "accept", questID = 94677, text = "The Missing Rootwarden",
          coord = { map = 2413, x = 0.314, y = 0.649 } },  -- giver coord: ATT
        { type = "quest",  questID = 94677, text = "The Missing Rootwarden (objective 1) [1/3]",
          coord = { map = 2413, x = 0.310, y = 0.647 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94677, text = "The Missing Rootwarden (objective 1) [2/3]",
          coord = { map = 2413, x = 0.330, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94677, text = "The Missing Rootwarden (objective 1) [3/3]",
          coord = { map = 2413, x = 0.304, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86866, text = "Can We Heal This? (objective 1)",
          coord = { map = 2413, x = 0.320, y = 0.612 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86866, text = "Turn in: Can We Heal This?", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.320, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94677, text = "Turn in: The Missing Rootwarden", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.320, y = 0.614 } },  -- APR route coord (converted)
        { type = "accept", questID = 86882, text = "Alndust in Right Hands",
          coord = { map = 2413, x = 0.320, y = 0.614 } },  -- giver coord: ATT
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 1) [1/5]",
          coord = { map = 2413, x = 0.322, y = 0.618 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 1) [2/5]",
          coord = { map = 2413, x = 0.323, y = 0.627 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 1) [3/5]",
          coord = { map = 2413, x = 0.335, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 1) [4/5]",
          coord = { map = 2413, x = 0.328, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 1) [5/5]",
          coord = { map = 2413, x = 0.322, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86882, text = "Alndust in Right Hands (objective 2)",
          coord = { map = 2413, x = 0.332, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86882, text = "Turn in: Alndust in Right Hands", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.332, y = 0.760 } },  -- APR route coord (converted)
        { type = "accept", questID = 86867, text = "Into the Lightbloom",
          coord = { map = 2413, x = 0.332, y = 0.760 } },  -- giver coord: ATT
        { type = "quest",  questID = 86867, text = "Into the Lightbloom (objective 1)",
          coord = { map = 2413, x = 0.333, y = 0.759 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86867, text = "Into the Lightbloom (objective 2,3)",
          coord = { map = 2413, x = 0.333, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86867, text = "Turn in: Into the Lightbloom", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "accept", questID = 86874, text = "Culling the Light",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "accept", questID = 86881, text = "At the Root",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "accept", questID = 86880, text = "Our Beloved, Returned",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "accept", questID = 86877, text = "Righteous Pruning",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [1/6]",
          coord = { map = 2413, x = 0.285, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [2/6]",
          coord = { map = 2413, x = 0.297, y = 0.740 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [3/6]",
          coord = { map = 2413, x = 0.305, y = 0.739 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [4/6]",
          coord = { map = 2413, x = 0.330, y = 0.794 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86881, text = "At the Root (objective 1) [1/5]",
          coord = { map = 2413, x = 0.334, y = 0.809 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86881, text = "At the Root (objective 1) [2/5]",
          coord = { map = 2413, x = 0.326, y = 0.827 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86881, text = "At the Root (objective 1) [3/5]",
          coord = { map = 2413, x = 0.317, y = 0.863 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86881, text = "At the Root (objective 1) [4/5]",
          coord = { map = 2413, x = 0.303, y = 0.873 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [5/6]",
          coord = { map = 2413, x = 0.317, y = 0.831 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86880, text = "Our Beloved, Returned (objective 1) [6/6]",
          coord = { map = 2413, x = 0.299, y = 0.811 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86881, text = "At the Root (objective 1) [5/5]",
          coord = { map = 2413, x = 0.304, y = 0.793 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86874, text = "Culling the Light (objective 1)",
          coord = { map = 2413, x = 0.318, y = 0.783 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86877, text = "Righteous Pruning (objective 1)",
          coord = { map = 2413, x = 0.318, y = 0.783 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86874, text = "Turn in: Culling the Light",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 86877, text = "Turn in: Righteous Pruning", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86880, text = "Turn in: Our Beloved, Returned", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86881, text = "Turn in: At the Root", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "accept", questID = 86890, text = "Tell the People What You Have Seen",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "quest",  questID = 86890, text = "Tell the People What You Have Seen (objective 1)",
          coord = { map = 2413, x = 0.501, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86890, text = "Tell the People What You Have Seen (objective 2)",
          coord = { map = 2413, x = 0.501, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86890, text = "Turn in: Tell the People What You Have Seen", rep = { { factionID = 2704, amount = 1500 } },
          coord = { map = 2413, x = 0.532, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86883, text = "The Frenzied March",
          coord = { map = 2413, x = 0.532, y = 0.555 } },  -- giver coord: ATT
        { type = "quest",  questID = 86883, text = "The Frenzied March (objective 1)",
          coord = { map = 2413, x = 0.534, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86883, text = "Turn in: The Frenzied March", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2395, x = 0.622, y = 0.595 } },  -- APR route coord (converted)
        { type = "accept", questID = 86884, text = "Cull and Burn",
          coord = { map = 2395, x = 0.622, y = 0.595 } },  -- giver coord: ATT
        { type = "accept", questID = 86885, text = "Stem the Tides",
          coord = { map = 2395, x = 0.623, y = 0.595 } },  -- giver coord: ATT
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1)",
          coord = { map = 2395, x = 0.623, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1) [1/5]",
          coord = { map = 2395, x = 0.623, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1) [2/5]",
          coord = { map = 2395, x = 0.613, y = 0.592 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1) [3/5]",
          coord = { map = 2395, x = 0.611, y = 0.599 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1) [4/5]",
          coord = { map = 2395, x = 0.613, y = 0.608 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86885, text = "Stem the Tides (objective 1) [5/5]",
          coord = { map = 2395, x = 0.617, y = 0.600 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86884, text = "Cull and Burn (objective 1)",
          coord = { map = 2395, x = 0.610, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86884, text = "Turn in: Cull and Burn", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.622, y = 0.595 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86885, text = "Turn in: Stem the Tides", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.623, y = 0.595 } },  -- APR route coord (converted)
        { type = "accept", questID = 86887, text = "Expeditious Retreat",
          coord = { map = 2395, x = 0.623, y = 0.595 } },  -- giver coord: ATT
        { type = "accept", questID = 86891, text = "A Last Resort",
          coord = { map = 2395, x = 0.623, y = 0.595 } },  -- giver coord: ATT
        { type = "quest",  questID = 86887, text = "Expeditious Retreat (objective 2)",
          coord = { map = 2395, x = 0.616, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86891, text = "A Last Resort (objective 1)",
          coord = { map = 2395, x = 0.615, y = 0.597 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86891, text = "A Last Resort (objective 2)",
          coord = { map = 2395, x = 0.601, y = 0.591 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86887, text = "Expeditious Retreat (objective 1)",
          coord = { map = 2395, x = 0.599, y = 0.587 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86891, text = "A Last Resort (objective 3)",
          coord = { map = 2395, x = 0.605, y = 0.574 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86887, text = "Expeditious Retreat (objective 3)",
          coord = { map = 2395, x = 0.604, y = 0.569 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86887, text = "Turn in: Expeditious Retreat", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.587, y = 0.572 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86891, text = "Turn in: A Last Resort", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.587, y = 0.572 } },  -- APR route coord (converted)
        { type = "accept", questID = 86892, text = "Survive",
          coord = { map = 2395, x = 0.587, y = 0.573 } },  -- giver coord: ATT
        { type = "quest",  questID = 86892, text = "Survive (objective 1)",
          coord = { map = 2395, x = 0.586, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86892, text = "Survive (objective 2)",
          coord = { map = 2395, x = 0.588, y = 0.571 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86892, text = "Turn in: Survive", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2395, x = 0.587, y = 0.573 } },  -- APR route coord (converted)
        { type = "accept", questID = 86894, text = "The Gift of Aln'hara",
          coord = { map = 2395, x = 0.587, y = 0.573 } },  -- giver coord: ATT
        { type = "accept", questID = 86896, text = "Light Finds a Way",
          coord = { map = 2395, x = 0.587, y = 0.572 } },  -- giver coord: ATT
        { type = "quest",  questID = 86896, text = "Light Finds a Way (objective 1) [1/3]",
          coord = { map = 2395, x = 0.601, y = 0.548 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86896, text = "Light Finds a Way (objective 1) [2/3]",
          coord = { map = 2395, x = 0.620, y = 0.538 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86894, text = "The Gift of Aln'hara (objective 1)",
          coord = { map = 2395, x = 0.610, y = 0.557 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86896, text = "Light Finds a Way (objective 1)",
          coord = { map = 2395, x = 0.610, y = 0.557 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86896, text = "Turn in: Light Finds a Way", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.607, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86894, text = "Turn in: The Gift of Aln'hara", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2395, x = 0.608, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86897, text = "Quelling the Frenzy",
          coord = { map = 2395, x = 0.608, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86897, text = "Quelling the Frenzy (objective 1)",
          coord = { map = 2395, x = 0.628, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86897, text = "Turn in: Quelling the Frenzy", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2395, x = 0.584, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86898, text = "Rise of the Haranir",
          coord = { map = 2395, x = 0.584, y = 0.554 } },  -- giver coord: ATT
        { type = "turnin", questID = 86898, text = "Turn in: Rise of the Haranir", rep = { { factionID = 2704, amount = 1500 } },
          coord = { map = 2393, x = 0.366, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 91084, text = "Looming Shadows",
          coord = { map = 2393, x = 0.366, y = 0.684 } },  -- giver coord: ATT
        { type = "accept", questID = 95324, text = "The War Beyond the Roots",
          coord = { map = 2393, x = 0.365, y = 0.685 } },  -- giver coord: ATT
        { type = "turnin", questID = 91084, text = "Turn in: Looming Shadows", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95324, text = "Turn in: The War Beyond the Roots",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 90533, text = "Go Get Orweyna!",
          coord = { map = 2413, x = 0.471, y = 0.458 } },  -- giver coord: ATT
        { type = "accept", questID = 91550, text = "A Game of Silence and Shadow",
          coord = { map = 2413, x = 0.488, y = 0.443 } },  -- giver coord: ATT
        { type = "quest",  questID = 91550, text = "A Game of Silence and Shadow (objective 1)",
          coord = { map = 2413, x = 0.488, y = 0.443 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91550, text = "A Game of Silence and Shadow (objective 3) [1/4]",
          coord = { map = 2413, x = 0.495, y = 0.431 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91550, text = "A Game of Silence and Shadow (objective 3) [2/4]",
          coord = { map = 2413, x = 0.504, y = 0.408 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91550, text = "A Game of Silence and Shadow (objective 3) [3/4]",
          coord = { map = 2413, x = 0.514, y = 0.415 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91550, text = "A Game of Silence and Shadow (objective 3) [4/4]",
          coord = { map = 2413, x = 0.517, y = 0.395 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91550, text = "Turn in: A Game of Silence and Shadow", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.539, y = 0.413 } },  -- APR route coord (converted)
        { type = "accept", questID = 91551, text = "De-nest-stration",
          coord = { map = 2413, x = 0.539, y = 0.413 } },  -- giver coord: ATT
        { type = "accept", questID = 91552, text = "Feathered Fury",
          coord = { map = 2413, x = 0.539, y = 0.413 } },  -- giver coord: ATT
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1) [1/5]",
          coord = { map = 2413, x = 0.555, y = 0.442 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1) [2/5]",
          coord = { map = 2413, x = 0.564, y = 0.452 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1) [3/5]",
          coord = { map = 2413, x = 0.570, y = 0.461 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1) [4/5]",
          coord = { map = 2413, x = 0.552, y = 0.459 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1) [5/5]",
          coord = { map = 2413, x = 0.552, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91551, text = "De-nest-stration (objective 1)",
          coord = { map = 2413, x = 0.559, y = 0.451 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91552, text = "Feathered Fury (objective 1)",
          coord = { map = 2413, x = 0.559, y = 0.451 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91551, text = "Turn in: De-nest-stration", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.573, y = 0.490 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91552, text = "Turn in: Feathered Fury", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.573, y = 0.490 } },  -- APR route coord (converted)
        { type = "accept", questID = 91553, text = "Haranir Never Say Die!",
          coord = { map = 2413, x = 0.573, y = 0.490 } },  -- giver coord: ATT
        { type = "quest",  questID = 91553, text = "Haranir Never Say Die! (objective 1)",
          coord = { map = 2413, x = 0.577, y = 0.496 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91553, text = "Turn in: Haranir Never Say Die!",
          coord = { map = 2413, x = 0.584, y = 0.491 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90533, text = "Go Get Orweyna! (objective 1)",
          coord = { map = 2413, x = 0.542, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90533, text = "Go Get Orweyna! (objective 2)",
          coord = { map = 2413, x = 0.539, y = 0.552 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90533, text = "Go Get Orweyna! (objective 3)", useItem = 241125, useItemVerified = false,
          coord = { map = 2413, x = 0.471, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90533, text = "Turn in: Go Get Orweyna!", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.472, y = 0.458 } },  -- APR route coord (converted)
        { type = "accept", questID = 90534, text = "The Home of the Haranir",
          coord = { map = 2413, x = 0.472, y = 0.458 } },  -- giver coord: ATT
        { type = "quest",  questID = 90534, text = "The Home of the Haranir (objective 1)",
          coord = { map = 2413, x = 0.518, y = 0.505 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90534, text = "The Home of the Haranir (objective 2)",
          coord = { map = 2413, x = 0.510, y = 0.565 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90534, text = "The Home of the Haranir (objective 3)",
          coord = { map = 2413, x = 0.535, y = 0.540 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90534, text = "Turn in: The Home of the Haranir", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.513, y = 0.495 } },  -- APR route coord (converted)
        { type = "accept", questID = 90535, text = "Leave Your Mark",
          coord = { map = 2576, x = 0.479, y = 0.224 } },  -- giver coord: ATT
        { type = "quest",  questID = 90535, text = "Leave Your Mark (objective 1)",
          coord = { map = 2413, x = 0.513, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90535, text = "Leave Your Mark (objective 2)",
          coord = { map = 2413, x = 0.513, y = 0.495 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90535, text = "Turn in: Leave Your Mark", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.513, y = 0.494 } },  -- APR route coord (converted)
        { type = "accept", questID = 91872, text = "The Former Rootwarden",
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- giver coord: ATT
        { type = "accept", questID = 90537, text = "Late Bloomers",
          coord = { map = 2413, x = 0.370, y = 0.260 } },  -- giver coord: ATT
        { type = "accept", questID = 91585, text = "Fresh from the Garden",
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- giver coord: ATT
        { type = "accept", questID = 91586, text = "Soil-Based Alternatives",
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- giver coord: ATT
        { type = "accept", questID = 91587, text = "Carcass Cuisine",
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- giver coord: ATT
        { type = "quest",  questID = 91587, text = "Carcass Cuisine (objective 1)",
          coord = { map = 2413, x = 0.390, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91587, text = "Carcass Cuisine (objective 2)",
          coord = { map = 2413, x = 0.391, y = 0.225 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91585, text = "Fresh from the Garden (objective 1,2)",
          coord = { map = 2413, x = 0.403, y = 0.242 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91586, text = "Soil-Based Alternatives (objective 1)",
          coord = { map = 2413, x = 0.403, y = 0.242 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91585, text = "Turn in: Fresh from the Garden", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91587, text = "Turn in: Carcass Cuisine", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91586, text = "Turn in: Soil-Based Alternatives", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- APR route coord (converted)
        { type = "accept", questID = 91588, text = "Harandar's Kitchen",
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- giver coord: ATT
        { type = "quest",  questID = 91588, text = "Harandar's Kitchen (objective 3)",
          coord = { map = 2413, x = 0.411, y = 0.235 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91588, text = "Harandar's Kitchen (objective 2)",
          coord = { map = 2413, x = 0.402, y = 0.227 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91588, text = "Harandar's Kitchen (objective 1)",
          coord = { map = 2413, x = 0.397, y = 0.219 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91588, text = "Turn in: Harandar's Kitchen", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- APR route coord (converted)
        { type = "accept", questID = 91589, text = "Root Dash Delivery",
          coord = { map = 2413, x = 0.409, y = 0.232 } },  -- giver coord: ATT
        { type = "quest",  questID = 91589, text = "Root Dash Delivery (objective 1)",
          coord = { map = 2413, x = 0.408, y = 0.232 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91589, text = "Root Dash Delivery (objective 4,5)",
          coord = { map = 2413, x = 0.366, y = 0.269 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91589, text = "Root Dash Delivery (objective 2)",
          coord = { map = 2413, x = 0.365, y = 0.269 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91589, text = "Turn in: Root Dash Delivery", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.367, y = 0.268 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91872, text = "Turn in: The Former Rootwarden", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.425, y = 0.341 } },  -- APR route coord (converted)
        { type = "accept", questID = 91873, text = "Buffer Zone",
          coord = { map = 2413, x = 0.426, y = 0.341 } },  -- giver coord: ATT
        { type = "quest",  questID = 91873, text = "Buffer Zone (objective 1)",
          coord = { map = 2413, x = 0.406, y = 0.328 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91873, text = "Turn in: Buffer Zone", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.423, y = 0.342 } },  -- APR route coord (converted)
        { type = "accept", questID = 91875, text = "Natural Remedy",
          coord = { map = 2413, x = 0.423, y = 0.341 } },  -- giver coord: ATT
        { type = "quest",  questID = 91875, text = "Natural Remedy (objective 1)",
          coord = { map = 2413, x = 0.422, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91875, text = "Turn in: Natural Remedy", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.424, y = 0.344 } },  -- APR route coord (converted)
        { type = "accept", questID = 91874, text = "Flare Up",
          coord = { map = 2413, x = 0.423, y = 0.342 } },  -- giver coord: ATT
        { type = "quest",  questID = 91874, text = "Flare Up (objective 1)",
          coord = { map = 2413, x = 0.355, y = 0.367 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91874, text = "Turn in: Flare Up", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.426, y = 0.336 } },  -- APR route coord (converted)
        { type = "accept", questID = 91876, text = "Tending Hope",
          coord = { map = 2413, x = 0.426, y = 0.336 } },  -- giver coord: ATT
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [1/12]",
          coord = { map = 2413, x = 0.427, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [2/12]",
          coord = { map = 2413, x = 0.427, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [3/12]",
          coord = { map = 2413, x = 0.427, y = 0.341 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [4/12]",
          coord = { map = 2413, x = 0.427, y = 0.339 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [5/12]",
          coord = { map = 2413, x = 0.425, y = 0.340 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [6/12]",
          coord = { map = 2413, x = 0.427, y = 0.345 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [7/12]",
          coord = { map = 2413, x = 0.425, y = 0.344 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [8/12]",
          coord = { map = 2413, x = 0.424, y = 0.344 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [9/12]",
          coord = { map = 2413, x = 0.423, y = 0.343 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [10/12]",
          coord = { map = 2413, x = 0.423, y = 0.342 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [11/12]",
          coord = { map = 2413, x = 0.422, y = 0.338 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91876, text = "Tending Hope (objective 1) [12/12]",
          coord = { map = 2413, x = 0.423, y = 0.337 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91876, text = "Turn in: Tending Hope", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.425, y = 0.338 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90537, text = "Late Bloomers (objective 1)",
          coord = { map = 2413, x = 0.487, y = 0.321 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90537, text = "Late Bloomers (objective 2)",
          coord = { map = 2413, x = 0.487, y = 0.320 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90537, text = "Late Bloomers (objective 3)",
          coord = { map = 2413, x = 0.487, y = 0.322 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90537, text = "Late Bloomers (objective 4)",
          coord = { map = 2413, x = 0.488, y = 0.321 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90537, text = "Turn in: Late Bloomers", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- APR route coord (converted)
        { type = "accept", questID = 90540, text = "Rutaani Rescue",
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- giver coord: ATT
        { type = "accept", questID = 90569, text = "Back in the Bag",
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- giver coord: ATT
        { type = "quest",  questID = 90540, text = "Rutaani Rescue (objective 1)",
          coord = { map = 2413, x = 0.485, y = 0.266 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90569, text = "Back in the Bag (objective 1)",
          coord = { map = 2413, x = 0.485, y = 0.266 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90569, text = "Turn in: Back in the Bag", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90540, text = "Turn in: Rutaani Rescue", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- APR route coord (converted)
        { type = "accept", questID = 90963, text = "Caves of the Cleft",
          coord = { map = 2413, x = 0.489, y = 0.297 } },  -- giver coord: ATT
        { type = "turnin", questID = 90963, text = "Turn in: Caves of the Cleft", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.497, y = 0.233 } },  -- APR route coord (converted)
        { type = "accept", questID = 90601, text = "Gathering Glowshrooms",
          coord = { map = 2413, x = 0.497, y = 0.233 } },  -- giver coord: ATT
        { type = "accept", questID = 90602, text = "Gomphusta",
          coord = { map = 2413, x = 0.497, y = 0.233 } },  -- giver coord: ATT
        { type = "quest",  questID = 90602, text = "Gomphusta (objective 1)",
          coord = { map = 2413, x = 0.487, y = 0.216 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90602, text = "Gomphusta (objective 2)",
          coord = { map = 2413, x = 0.486, y = 0.224 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90601, text = "Gathering Glowshrooms (objective 1)",
          coord = { map = 2413, x = 0.491, y = 0.225 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90601, text = "Turn in: Gathering Glowshrooms", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.497, y = 0.233 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90602, text = "Turn in: Gomphusta", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.497, y = 0.233 } },  -- APR route coord (converted)
        { type = "accept", questID = 90467, text = "Tales of the Sky",
          coord = { map = 2413, x = 0.678, y = 0.275 } },  -- giver coord: ATT
        { type = "accept", questID = 90468, text = "Ugh, Chores!",
          coord = { map = 2413, x = 0.678, y = 0.275 } },  -- giver coord: ATT
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [1/6]",
          coord = { map = 2413, x = 0.692, y = 0.303 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [2/6]",
          coord = { map = 2413, x = 0.696, y = 0.296 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [3/6]",
          coord = { map = 2413, x = 0.702, y = 0.299 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [4/6]",
          coord = { map = 2413, x = 0.703, y = 0.304 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [5/6]",
          coord = { map = 2413, x = 0.704, y = 0.314 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90467, text = "Tales of the Sky (objective 1) [6/6]",
          coord = { map = 2413, x = 0.703, y = 0.320 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90468, text = "Ugh, Chores! (objective 1)",
          coord = { map = 2413, x = 0.694, y = 0.312 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90467, text = "Turn in: Tales of the Sky", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.694, y = 0.292 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90468, text = "Turn in: Ugh, Chores!", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.694, y = 0.292 } },  -- APR route coord (converted)
        { type = "accept", questID = 90469, text = "Carry On, Wayward Kuri",
          coord = { map = 2413, x = 0.694, y = 0.292 } },  -- giver coord: ATT
        { type = "quest",  questID = 90469, text = "Carry On, Wayward Kuri (objective 1)",
          coord = { map = 2413, x = 0.697, y = 0.266 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90469, text = "Turn in: Carry On, Wayward Kuri", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.697, y = 0.266 } },  -- APR route coord (converted)
        { type = "accept", questID = 90470, text = "Skyglass Scavenging",
          coord = { map = 2413, x = 0.697, y = 0.266 } },  -- giver coord: ATT
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [15%]",
          coord = { map = 2413, x = 0.704, y = 0.259 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [30%]",
          coord = { map = 2413, x = 0.710, y = 0.261 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [35%]",
          coord = { map = 2413, x = 0.709, y = 0.263 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [40%]",
          coord = { map = 2413, x = 0.708, y = 0.267 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [45%]",
          coord = { map = 2413, x = 0.711, y = 0.271 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [50%]",
          coord = { map = 2413, x = 0.713, y = 0.271 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [55%]",
          coord = { map = 2413, x = 0.714, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [60%]",
          coord = { map = 2413, x = 0.711, y = 0.282 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [65%]",
          coord = { map = 2413, x = 0.711, y = 0.285 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [70%]",
          coord = { map = 2413, x = 0.713, y = 0.286 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1) [85%]",
          coord = { map = 2413, x = 0.715, y = 0.288 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90470, text = "Skyglass Scavenging (objective 1)",
          coord = { map = 2413, x = 0.715, y = 0.284 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90470, text = "Turn in: Skyglass Scavenging", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.697, y = 0.266 } },  -- APR route coord (converted)
        { type = "accept", questID = 90474, text = "The Legend of Aln'sharan",
          coord = { map = 2413, x = 0.697, y = 0.266 } },  -- giver coord: ATT
        { type = "quest",  questID = 90474, text = "The Legend of Aln'sharan (objective 1)",
          coord = { map = 2413, x = 0.662, y = 0.255 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90474, text = "Turn in: The Legend of Aln'sharan", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.662, y = 0.255 } },  -- APR route coord (converted)
        { type = "accept", questID = 91346, text = "Supplicants to the Goddess",
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- giver coord: ATT
        { type = "quest",  questID = 91346, text = "Supplicants to the Goddess (objective 1)",
          coord = { map = 2413, x = 0.655, y = 0.280 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91346, text = "Turn in: Supplicants to the Goddess", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- APR route coord (converted)
        { type = "accept", questID = 91359, text = "Fungal Lashers B Gone",
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- giver coord: ATT
        { type = "accept", questID = 91360, text = "Weeding Out the Unwanted",
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- giver coord: ATT
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [1/8]",
          coord = { map = 2413, x = 0.640, y = 0.286 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [2/8]",
          coord = { map = 2413, x = 0.638, y = 0.290 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [3/8]",
          coord = { map = 2413, x = 0.628, y = 0.300 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [4/8]",
          coord = { map = 2413, x = 0.622, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [5/8]",
          coord = { map = 2413, x = 0.620, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [6/8]",
          coord = { map = 2413, x = 0.616, y = 0.310 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [7/8]",
          coord = { map = 2413, x = 0.620, y = 0.313 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91360, text = "Weeding Out the Unwanted (objective 1) [8/8]",
          coord = { map = 2413, x = 0.624, y = 0.311 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91359, text = "Fungal Lashers B Gone (objective 1)",
          coord = { map = 2413, x = 0.621, y = 0.283 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91359, text = "Turn in: Fungal Lashers B Gone", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91360, text = "Turn in: Weeding Out the Unwanted", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- APR route coord (converted)
        { type = "accept", questID = 91361, text = "Back on Duty?",
          coord = { map = 2413, x = 0.654, y = 0.281 } },  -- giver coord: ATT
        { type = "quest",  questID = 91361, text = "Back on Duty? (objective 1)",
          coord = { map = 2413, x = 0.663, y = 0.266 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91361, text = "Turn in: Back on Duty?", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.655, y = 0.281 } },  -- APR route coord (converted)
        { type = "accept", questID = 91063, text = "The Blooming Lattice",
          coord = { map = 2413, x = 0.654, y = 0.226 } },  -- giver coord: ATT
        { type = "turnin", questID = 91063, text = "Turn in: The Blooming Lattice", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- APR route coord (converted)
        { type = "accept", questID = 91065, text = "Purloining Petals",
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- giver coord: ATT
        { type = "accept", questID = 91086, text = "Nipping the Buds",
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- giver coord: ATT
        { type = "accept", questID = 91085, text = "Petal Bristles",
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- giver coord: ATT
        { type = "quest",  questID = 91086, text = "Nipping the Buds (objective 2)",
          coord = { map = 2413, x = 0.549, y = 0.316 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91065, text = "Purloining Petals (objective 2)",
          coord = { map = 2413, x = 0.545, y = 0.283 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91065, text = "Purloining Petals (objective 1)",
          coord = { map = 2413, x = 0.553, y = 0.283 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91065, text = "Purloining Petals (objective 4)",
          coord = { map = 2413, x = 0.553, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91065, text = "Purloining Petals (objective 3)",
          coord = { map = 2413, x = 0.549, y = 0.321 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91085, text = "Petal Bristles (objective 1)",
          coord = { map = 2413, x = 0.549, y = 0.301 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91086, text = "Nipping the Buds (objective 1)",
          coord = { map = 2413, x = 0.549, y = 0.301 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91065, text = "Turn in: Purloining Petals", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91085, text = "Turn in: Petal Bristles", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91086, text = "Turn in: Nipping the Buds", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- APR route coord (converted)
        { type = "accept", questID = 91088, text = "Behind the Falls",
          coord = { map = 2413, x = 0.608, y = 0.299 } },  -- giver coord: ATT
        { type = "turnin", questID = 91088, text = "Turn in: Behind the Falls", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.561, y = 0.248 } },  -- APR route coord (converted)
        { type = "accept", questID = 91136, text = "Memories in Stone",
          coord = { map = 2413, x = 0.561, y = 0.248 } },  -- giver coord: ATT
        { type = "quest",  questID = 91136, text = "Memories in Stone (objective 1)",
          coord = { map = 2413, x = 0.561, y = 0.248 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91136, text = "Memories in Stone (objective 2)",
          coord = { map = 2413, x = 0.561, y = 0.249 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91136, text = "Turn in: Memories in Stone", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.557, y = 0.265 } },  -- APR route coord (converted)
        { type = "accept", questID = 92882, text = "A Hunter's Plight",
          coord = { map = 2413, x = 0.694, y = 0.528 } },  -- giver coord: ATT
        { type = "accept", questID = 90615, text = "Be Grudge You",
          coord = { map = 2413, x = 0.703, y = 0.529 } },  -- giver coord: ATT
        { type = "accept", questID = 93421, text = "Delver's Call: The Grudge Pit",
          coord = { map = 2413, x = 0.712, y = 0.521 } },  -- APR route coord (converted)
        { type = "accept", questID = 92694, text = "Dusk Among Pigments",
          coord = { map = 2413, x = 0.705, y = 0.512 } },  -- giver coord: ATT
        { type = "accept", questID = 92865, text = "Feeding the Buds",
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- giver coord: ATT
        { type = "accept", questID = 92864, text = "Drift Them Away",
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- giver coord: ATT
        { type = "quest",  questID = 92882, text = "A Hunter's Plight (objective 1)",
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92882, text = "Turn in: A Hunter's Plight", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- APR route coord (converted)
        { type = "accept", questID = 92883, text = "A Hunter's Duty",
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- giver coord: ATT
        { type = "quest",  questID = 92883, text = "A Hunter's Duty (objective 5) [1/2]",
          coord = { map = 2413, x = 0.694, y = 0.436 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92883, text = "A Hunter's Duty (objective 5) [2/2]",
          coord = { map = 2413, x = 0.716, y = 0.400 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92883, text = "A Hunter's Duty (objective 3)",
          coord = { map = 2413, x = 0.717, y = 0.383 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92864, text = "Drift Them Away (objective 1,2)",
          coord = { map = 2413, x = 0.695, y = 0.389 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92865, text = "Feeding the Buds (objective 1)",
          coord = { map = 2413, x = 0.701, y = 0.428 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92883, text = "A Hunter's Duty (objective 2,4,1)",
          coord = { map = 2413, x = 0.701, y = 0.428 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92865, text = "Feeding the Buds (objective 2,3,4,5)",
          coord = { map = 2413, x = 0.696, y = 0.506 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92864, text = "Turn in: Drift Them Away", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92865, text = "Turn in: Feeding the Buds", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- APR route coord (converted)
        { type = "accept", questID = 92866, text = "Re-Hydra-ted",
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- giver coord: ATT
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 1) [1/4]",
          coord = { map = 2413, x = 0.694, y = 0.506 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 1) [2/4]",
          coord = { map = 2413, x = 0.695, y = 0.505 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 1) [3/4]",
          coord = { map = 2413, x = 0.696, y = 0.506 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 1) [4/4]",
          coord = { map = 2413, x = 0.698, y = 0.505 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92883, text = "Turn in: A Hunter's Duty", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.700, y = 0.529 } },  -- APR route coord (converted)
        { type = "accept", questID = 92884, text = "A Hunter's Weapon",
          coord = { map = 2413, x = 0.700, y = 0.529 } },  -- giver coord: ATT
        { type = "quest",  questID = 92884, text = "A Hunter's Weapon (objective 1)",
          coord = { map = 2413, x = 0.700, y = 0.527 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92884, text = "A Hunter's Weapon (objective 2)",
          coord = { map = 2413, x = 0.700, y = 0.527 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92884, text = "A Hunter's Weapon (objective 3)",
          coord = { map = 2413, x = 0.700, y = 0.528 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92884, text = "A Hunter's Weapon (objective 4)",
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92884, text = "Turn in: A Hunter's Weapon", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- APR route coord (converted)
        { type = "accept", questID = 92885, text = "A Hunter's Prey",
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- giver coord: ATT
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 4)",
          coord = { map = 2413, x = 0.699, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 2)",
          coord = { map = 2413, x = 0.690, y = 0.421 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 3)",
          coord = { map = 2413, x = 0.713, y = 0.411 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92866, text = "Re-Hydra-ted (objective 5)",
          coord = { map = 2413, x = 0.712, y = 0.403 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92866, text = "Turn in: Re-Hydra-ted", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.695, y = 0.506 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92694, text = "Turn in: Dusk Among Pigments", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.740, y = 0.531 } },  -- APR route coord (converted)
        { type = "accept", questID = 92695, text = "The Stroke of Storms",
          coord = { map = 2413, x = 0.740, y = 0.531 } },  -- giver coord: ATT
        { type = "quest",  questID = 92695, text = "The Stroke of Storms (objective 1)",
          coord = { map = 2413, x = 0.723, y = 0.557 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92695, text = "The Stroke of Storms (objective 2)",
          coord = { map = 2413, x = 0.724, y = 0.544 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92695, text = "The Stroke of Storms (objective 3)",
          coord = { map = 2413, x = 0.723, y = 0.557 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92695, text = "Turn in: The Stroke of Storms", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.724, y = 0.557 } },  -- APR route coord (converted)
        { type = "accept", questID = 92696, text = "Colors Born Anew",
          coord = { map = 2413, x = 0.724, y = 0.557 } },  -- giver coord: ATT
        { type = "quest",  questID = 92696, text = "Colors Born Anew (objective 1,2)",
          coord = { map = 2413, x = 0.722, y = 0.574 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90615, text = "Turn in: Be Grudge You", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "accept", questID = 90616, text = "You Strong?",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90616, text = "You Strong? (objective 1)",
          coord = { map = 2413, x = 0.716, y = 0.661 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90616, text = "Turn in: You Strong?", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "accept", questID = 90617, text = "A Few Fun Guys",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90617, text = "A Few Fun Guys (objective 1)",
          coord = { map = 2413, x = 0.720, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90617, text = "A Few Fun Guys (objective 2) [1/3]",
          coord = { map = 2413, x = 0.714, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90617, text = "A Few Fun Guys (objective 2) [2/3]",
          coord = { map = 2413, x = 0.707, y = 0.660 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90617, text = "A Few Fun Guys (objective 2) [3/3]",
          coord = { map = 2413, x = 0.709, y = 0.666 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90617, text = "Turn in: A Few Fun Guys", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "accept", questID = 90619, text = "What Doesn't Kill Them",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90619, text = "What Doesn't Kill Them (objective 1)",
          coord = { map = 2413, x = 0.721, y = 0.629 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90619, text = "What Doesn't Kill Them (objective 2)",
          coord = { map = 2413, x = 0.721, y = 0.625 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90619, text = "What Doesn't Kill Them (objective 3)",
          coord = { map = 2413, x = 0.719, y = 0.626 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90619, text = "Turn in: What Doesn't Kill Them", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.721, y = 0.629 } },  -- APR route coord (converted)
        { type = "accept", questID = 91450, text = "We Ready Now",
          coord = { map = 2413, x = 0.721, y = 0.629 } },  -- giver coord: ATT
        { type = "turnin", questID = 91450, text = "Turn in: We Ready Now",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- APR route coord (converted)
        { type = "accept", questID = 91270, text = "The Most Important Thing",
          coord = { map = 2413, x = 0.718, y = 0.639 } },  -- giver coord: ATT
        { type = "quest",  questID = 91270, text = "The Most Important Thing (objective 3)",
          coord = { map = 2413, x = 0.718, y = 0.639 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91270, text = "The Most Important Thing (objective )",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91270, text = "The Most Important Thing (objective 1)",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91270, text = "The Most Important Thing (objective 4)",
          coord = { map = 2413, x = 0.718, y = 0.639 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91270, text = "Turn in: The Most Important Thing", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.718, y = 0.639 } },  -- APR route coord (converted)
        { type = "accept", questID = 90620, text = "To the Ring",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90620, text = "To the Ring (objective 1)",
          coord = { map = 2413, x = 0.719, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90620, text = "To the Ring (objective 3)",
          coord = { map = 2413, x = 0.716, y = 0.660 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90620, text = "Turn in: To the Ring", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- APR route coord (converted)
        { type = "accept", questID = 90621, text = "Tiny Heroes' Journeys",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "accept", questID = 92616, text = "Mushrooming Courage",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "accept", questID = 92617, text = "Mushrooming Resilience",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "accept", questID = 92618, text = "Mushrooming Confidence",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90621, text = "Tiny Heroes' Journeys (objective 1)",
          coord = { map = 2413, x = 0.719, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92618, text = "Mushrooming Confidence (objective 1)",
          coord = { map = 2413, x = 0.677, y = 0.673 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92618, text = "Mushrooming Confidence (objective 2)",
          coord = { map = 2413, x = 0.677, y = 0.673 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92618, text = "Mushrooming Confidence (objective 3)",
          coord = { map = 2413, x = 0.677, y = 0.674 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92618, text = "Turn in: Mushrooming Confidence", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.677, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92616, text = "Mushrooming Courage (objective 1)",
          coord = { map = 2413, x = 0.691, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92617, text = "Mushrooming Resilience (objective 1)",
          coord = { map = 2413, x = 0.691, y = 0.666 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92616, text = "Turn in: Mushrooming Courage", rep = { { factionID = 2704, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 92617, text = "Turn in: Mushrooming Resilience", rep = { { factionID = 2704, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 90621, text = "Turn in: Tiny Heroes' Journeys", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "accept", questID = 90622, text = "Not-Yet Defeated Champions",
          coord = { map = 2413, x = 0.718, y = 0.640 } },  -- giver coord: ATT
        { type = "quest",  questID = 90622, text = "Not-Yet Defeated Champions (objective 3)",
          coord = { map = 2413, x = 0.715, y = 0.662 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90622, text = "Not-Yet Defeated Champions (objective 4)",
          coord = { map = 2413, x = 0.716, y = 0.660 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90622, text = "Turn in: Not-Yet Defeated Champions", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93421, text = "Turn in: Delver's Call: The Grudge Pit",
          coord = { map = 2413, x = 0.718, y = 0.641 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92696, text = "Turn in: Colors Born Anew", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.724, y = 0.557 } },  -- APR route coord (converted)
        { type = "accept", questID = 92697, text = "Hues of Tomorrow",
          coord = { map = 2413, x = 0.724, y = 0.557 } },  -- giver coord: ATT
        { type = "quest",  questID = 92697, text = "Hues of Tomorrow (objective 1)",
          coord = { map = 2413, x = 0.740, y = 0.532 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92697, text = "Turn in: Hues of Tomorrow", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.740, y = 0.532 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92885, text = "A Hunter's Prey (objective 1)",
          coord = { map = 2413, x = 0.690, y = 0.549 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92885, text = "A Hunter's Prey (objective 2)",
          coord = { map = 2413, x = 0.687, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92885, text = "Turn in: A Hunter's Prey", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.705, y = 0.507 } },  -- APR route coord (converted)
        { type = "accept", questID = 91375, text = "The Silence at Fungara Village",
          coord = { map = 2413, x = 0.333, y = 0.667 } },  -- giver coord: ATT
        { type = "accept", questID = 92732, text = "Light Disturbance",
          coord = { map = 2413, x = 0.314, y = 0.649 } },  -- giver coord: ATT
        { type = "turnin", questID = 92732, text = "Turn in: Light Disturbance", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.407, y = 0.630 } },  -- APR route coord (converted)
        { type = "accept", questID = 92736, text = "Light Stroll",
          coord = { map = 2413, x = 0.406, y = 0.630 } },  -- giver coord: ATT
        { type = "quest",  questID = 92736, text = "Light Stroll (objective 1) [1/4]",
          coord = { map = 2413, x = 0.409, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92736, text = "Light Stroll (objective 1) [2/4]",
          coord = { map = 2413, x = 0.408, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92736, text = "Light Stroll (objective 1) [3/4]",
          coord = { map = 2413, x = 0.412, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92736, text = "Light Stroll (objective 1) [4/4]",
          coord = { map = 2413, x = 0.417, y = 0.674 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92736, text = "Turn in: Light Stroll", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.417, y = 0.678 } },  -- APR route coord (converted)
        { type = "accept", questID = 92737, text = "Light Carnage",
          coord = { map = 2413, x = 0.417, y = 0.678 } },  -- giver coord: ATT
        { type = "accept", questID = 92738, text = "Potatoad Tots",
          coord = { map = 2413, x = 0.417, y = 0.678 } },  -- giver coord: ATT
        { type = "quest",  questID = 92737, text = "Light Carnage (objective 1)",
          coord = { map = 2413, x = 0.400, y = 0.695 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92738, text = "Potatoad Tots (objective 1)",
          coord = { map = 2413, x = 0.400, y = 0.695 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92737, text = "Turn in: Light Carnage", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.373, y = 0.723 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92738, text = "Turn in: Potatoad Tots", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.373, y = 0.723 } },  -- APR route coord (converted)
        { type = "accept", questID = 92739, text = "O.K. Bloomer",
          coord = { map = 2413, x = 0.373, y = 0.723 } },  -- giver coord: ATT
        { type = "quest",  questID = 92739, text = "O.K. Bloomer (objective 1)",
          coord = { map = 2413, x = 0.360, y = 0.742 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92739, text = "Turn in: O.K. Bloomer", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.314, y = 0.650 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91375, text = "Turn in: The Silence at Fungara Village", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.439, y = 0.717 } },  -- APR route coord (converted)
        { type = "accept", questID = 91376, text = "Little Monsters",
          coord = { map = 2413, x = 0.439, y = 0.717 } },  -- giver coord: ATT
        { type = "accept", questID = 91377, text = "Spawn of the Dead",
          coord = { map = 2413, x = 0.439, y = 0.717 } },  -- giver coord: ATT
        { type = "quest",  questID = 91376, text = "Little Monsters (objective 1)",
          coord = { map = 2413, x = 0.457, y = 0.702 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91377, text = "Spawn of the Dead (objective 1)",
          coord = { map = 2413, x = 0.457, y = 0.702 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91376, text = "Turn in: Little Monsters", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91377, text = "Turn in: Spawn of the Dead", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- APR route coord (converted)
        { type = "accept", questID = 91378, text = "You Are Legend",
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- giver coord: ATT
        { type = "accept", questID = 91379, text = "Decayed Land",
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- giver coord: ATT
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [1/8]",
          coord = { map = 2413, x = 0.427, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [2/8]",
          coord = { map = 2413, x = 0.422, y = 0.670 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [3/8]",
          coord = { map = 2413, x = 0.423, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [4/8]",
          coord = { map = 2413, x = 0.422, y = 0.664 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [5/8]",
          coord = { map = 2413, x = 0.427, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [6/8]",
          coord = { map = 2413, x = 0.434, y = 0.657 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [7/8]",
          coord = { map = 2413, x = 0.437, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91379, text = "Decayed Land (objective 1) [8/8]",
          coord = { map = 2413, x = 0.438, y = 0.669 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91378, text = "You Are Legend (objective 1)",
          coord = { map = 2413, x = 0.428, y = 0.666 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91378, text = "Turn in: You Are Legend", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91379, text = "Turn in: Decayed Land", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- APR route coord (converted)
        { type = "accept", questID = 91381, text = "Reticent Evil",
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- giver coord: ATT
        { type = "quest",  questID = 91381, text = "Reticent Evil (objective 1)",
          coord = { map = 2413, x = 0.458, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91381, text = "Reticent Evil (objective 2)",
          coord = { map = 2413, x = 0.458, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91381, text = "Turn in: Reticent Evil", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.441, y = 0.664 } },  -- APR route coord (converted)
        { type = "accept", questID = 90824, text = "My Brother's Alive!",
          coord = { map = 2413, x = 0.522, y = 0.551 } },  -- giver coord: ATT
        { type = "turnin", questID = 90824, text = "Turn in: My Brother's Alive!", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- APR route coord (converted)
        { type = "accept", questID = 90826, text = "The Healing Waters of Ahl'ua",
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- giver coord: ATT
        { type = "accept", questID = 90827, text = "Only the Poisonous Parts",
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- giver coord: ATT
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [1/6]",
          coord = { map = 2413, x = 0.404, y = 0.597 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [2/6]",
          coord = { map = 2413, x = 0.410, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [3/6]",
          coord = { map = 2413, x = 0.403, y = 0.563 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [4/6]",
          coord = { map = 2413, x = 0.404, y = 0.546 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [5/6]",
          coord = { map = 2413, x = 0.397, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90826, text = "The Healing Waters of Ahl'ua (objective 1) [6/6]",
          coord = { map = 2413, x = 0.410, y = 0.522 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90827, text = "Only the Poisonous Parts (objective 1)",
          coord = { map = 2413, x = 0.410, y = 0.576 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90827, text = "Turn in: Only the Poisonous Parts", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90826, text = "Turn in: The Healing Waters of Ahl'ua", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- APR route coord (converted)
        { type = "accept", questID = 90829, text = "Meeting My Mentor",
          coord = { map = 2413, x = 0.431, y = 0.614 } },  -- giver coord: ATT
        { type = "turnin", questID = 90829, text = "Turn in: Meeting My Mentor", rep = { { factionID = 2704, amount = 10 } },
          coord = { map = 2413, x = 0.639, y = 0.547 } },  -- APR route coord (converted)
        { type = "accept", questID = 90830, text = "The Path Will Reveal Itself",
          coord = { map = 2413, x = 0.639, y = 0.547 } },  -- giver coord: ATT
        { type = "accept", questID = 90831, text = "Doing Is Becoming",
          coord = { map = 2413, x = 0.639, y = 0.547 } },  -- giver coord: ATT
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 1)",
          coord = { map = 2413, x = 0.639, y = 0.547 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 2)",
          coord = { map = 2413, x = 0.630, y = 0.550 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 3)",
          coord = { map = 2413, x = 0.659, y = 0.585 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 4)",
          coord = { map = 2413, x = 0.645, y = 0.585 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 5)",
          coord = { map = 2413, x = 0.626, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 6)",
          coord = { map = 2413, x = 0.619, y = 0.598 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90830, text = "The Path Will Reveal Itself (objective 7)",
          coord = { map = 2413, x = 0.635, y = 0.600 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90831, text = "Doing Is Becoming (objective 1)",
          coord = { map = 2413, x = 0.635, y = 0.610 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90830, text = "Turn in: The Path Will Reveal Itself", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.629, y = 0.624 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90831, text = "Turn in: Doing Is Becoming", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.629, y = 0.624 } },  -- APR route coord (converted)
        { type = "accept", questID = 90832, text = "As Her Voice Goes Silent",
          coord = { map = 2413, x = 0.629, y = 0.624 } },  -- giver coord: ATT
        { type = "quest",  questID = 90832, text = "As Her Voice Goes Silent (objective 1) [1/2]",
          coord = { map = 2413, x = 0.630, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90832, text = "As Her Voice Goes Silent (objective 1) [2/2]",
          coord = { map = 2413, x = 0.628, y = 0.621 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90832, text = "As Her Voice Goes Silent (objective 2)",
          coord = { map = 2413, x = 0.630, y = 0.622 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90832, text = "As Her Voice Goes Silent (objective 3)",
          coord = { map = 2413, x = 0.630, y = 0.622 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90832, text = "Turn in: As Her Voice Goes Silent", rep = { { factionID = 2704, amount = 50 } },
          coord = { map = 2413, x = 0.629, y = 0.624 } },  -- APR route coord (converted)
        { type = "accept", questID = 90833, text = "The Final Rite",
          coord = { map = 2413, x = 0.629, y = 0.624 } },  -- giver coord: ATT
        { type = "quest",  questID = 90833, text = "The Final Rite (objective 1)",
          coord = { map = 2413, x = 0.610, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90833, text = "The Final Rite (objective 2)",
          coord = { map = 2413, x = 0.608, y = 0.607 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90833, text = "Turn in: The Final Rite", rep = { { factionID = 2704, amount = 100 } },
          coord = { map = 2413, x = 0.615, y = 0.602 } },  -- APR route coord (converted)
        { type = "accept", questID = 90834, text = "From This Point Forward",
          coord = { map = 2413, x = 0.616, y = 0.602 } },  -- giver coord: ATT
        { type = "turnin", questID = 90834, text = "Turn in: From This Point Forward", rep = { { factionID = 2704, amount = 250 } },
          coord = { map = 2413, x = 0.639, y = 0.547 } },  -- APR route coord (converted)
    },
}
