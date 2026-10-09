-- ToonAge guide data: Midnight (12.x) Harandar: MAIN CAMPAIGN storyline only
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Midnight leveling 80-90.
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Harandar-Campaign-Only"
--    in Routes/Midnight/Midnight-Harandar.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 53 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 50 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 0.17 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: campaign only.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2413 Harandar, 2576 The Den
--  * Harandar = uiMap 2413 (its own instance map 2694, not on the Eastern Kingdoms continent); The Den = 2576. The route starts in Silvermoon/Eversong.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_harandar_campaign"] = {
    id = "midnight_harandar_campaign", title = "Midnight: Harandar (Campaign)", expansion = "midnight",
    zone = 2413, minLevel = 80, maxLevel = 90, order = 20,
    nextGuide = "midnight_zulaman_campaign",
    steps = {
        -- (APR: grind/continue to level 83 before the next step - skipped when the warband has achievement 42045)
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
        { type = "turnin", questID = 86907, text = "Turn in: The Den of Echoes",
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
        { type = "turnin", questID = 86911, text = "Turn in: Echoes and Memories",
          coord = { map = 2413, x = 0.361, y = 0.443 } },  -- APR route coord (converted)
        { type = "accept", questID = 90094, text = "Echo of the Hunt",
          coord = { map = 2413, x = 0.361, y = 0.443 } },  -- giver coord: ATT
        { type = "quest",  questID = 90094, text = "Echo of the Hunt (objective 1)",
          coord = { map = 2413, x = 0.362, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90094, text = "Echo of the Hunt (objective 3,2)",
          coord = { map = 2413, x = 0.355, y = 0.459 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90094, text = "Turn in: Echo of the Hunt",
          coord = { map = 2413, x = 0.349, y = 0.428 } },  -- APR route coord (converted)
        { type = "accept", questID = 90095, text = "Echo of the Call",
          coord = { map = 2413, x = 0.349, y = 0.428 } },  -- giver coord: ATT
        { type = "quest",  questID = 90095, text = "Echo of the Call (objective 1)",
          coord = { map = 2413, x = 0.349, y = 0.427 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90095, text = "Echo of the Call (objective 2)",
          coord = { map = 2413, x = 0.342, y = 0.437 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90095, text = "Turn in: Echo of the Call",
          coord = { map = 2413, x = 0.339, y = 0.448 } },  -- APR route coord (converted)
        { type = "accept", questID = 86912, text = "Down the Rootways",
          coord = { map = 2413, x = 0.339, y = 0.448 } },  -- giver coord: ATT
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 1)",
          coord = { map = 2413, x = 0.389, y = 0.469 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 2)",
          coord = { map = 2413, x = 0.392, y = 0.546 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86912, text = "Down the Rootways (objective 3)",
          coord = { map = 2413, x = 0.342, y = 0.431 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86912, text = "Turn in: Down the Rootways",
          coord = { map = 2413, x = 0.348, y = 0.250 } },  -- APR route coord (converted)
        { type = "accept", questID = 86913, text = "A Hut in Har'mara",
          coord = { map = 2413, x = 0.348, y = 0.250 } },  -- giver coord: ATT
        { type = "turnin", questID = 86913, text = "Turn in: A Hut in Har'mara",
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
        { type = "turnin", questID = 86956, text = "Turn in: The Traveling Flowers",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86914, text = "Turn in: Tending to Har'mara",
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- APR route coord (converted)
        { type = "accept", questID = 86910, text = "Koozat's Trample",
          coord = { map = 2413, x = 0.349, y = 0.250 } },  -- giver coord: ATT
        { type = "quest",  questID = 86910, text = "Koozat's Trample (objective 1)",
          coord = { map = 2413, x = 0.356, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86910, text = "Turn in: Koozat's Trample",
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
        { type = "turnin", questID = 89034, text = "Turn in: Burning Bitterblooms",
          coord = { map = 2413, x = 0.357, y = 0.252 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86973, text = "Turn in: Halting Harm in Har'mara",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86942, text = "Turn in: Culling the Spread",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 86944, text = "Seeds of the Rift",
          coord = { map = 2413, x = 0.357, y = 0.253 } },  -- giver coord: ATT
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 1)",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 2)",
          coord = { map = 2413, x = 0.348, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86944, text = "Seeds of the Rift (objective 3)",
          coord = { map = 2413, x = 0.349, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86944, text = "Turn in: Seeds of the Rift",
          coord = { map = 2413, x = 0.349, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 86930, text = "To Sow the Seed",
          coord = { map = 2413, x = 0.349, y = 0.249 } },  -- giver coord: ATT
        { type = "turnin", questID = 93416, text = "Turn in: Delver's Call: The Gulf of Memory",
          coord = { map = 2413, x = 0.542, y = 0.531 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86930, text = "Turn in: To Sow the Seed",
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
        { type = "turnin", questID = 86864, text = "Turn in: Watch the Den",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- APR route coord (converted)
        { type = "accept", questID = 86836, text = "The Hunter Awaits",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- giver coord: ATT
        { type = "quest",  questID = 86836, text = "The Hunter Awaits (objective 2)",
          coord = { map = 2413, x = 0.543, y = 0.557 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86836, text = "The Hunter Awaits (objective 1)",
          coord = { map = 2413, x = 0.619, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86836, text = "Turn in: The Hunter Awaits",
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
        { type = "turnin", questID = 86851, text = "Turn in: The Foundation of Aln",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86855, text = "Turn in: Consequences of Our Duty",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 86856, text = "Dampening the Call",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 86856, text = "Dampening the Call (objective 1)",
          coord = { map = 2413, x = 0.620, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86856, text = "Turn in: Dampening the Call",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 86857, text = "Descent into the Rift",
          coord = { map = 2413, x = 0.619, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 1)",
          coord = { map = 2413, x = 0.641, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 2)",
          coord = { map = 2413, x = 0.640, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86857, text = "Descent into the Rift (objective 3)",
          coord = { map = 2413, x = 0.617, y = 0.562 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86857, text = "Turn in: Descent into the Rift",
          coord = { map = 2413, x = 0.617, y = 0.561 } },  -- APR route coord (converted)
        { type = "accept", questID = 86858, text = "The Madness Roots Deep",
          coord = { map = 2413, x = 0.617, y = 0.561 } },  -- giver coord: ATT
        { type = "quest",  questID = 86858, text = "The Madness Roots Deep (objective 1)",
          coord = { map = 2413, x = 0.598, y = 0.574 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86858, text = "Turn in: The Madness Roots Deep",
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
        { type = "turnin", questID = 86859, text = "Turn in: Grinding Out a Solution",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86860, text = "Turn in: Before They Grow",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86861, text = "Turn in: Herding Manifestations",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86862, text = "The Greater They Aln",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86862, text = "The Greater They Aln (objective 1)",
          coord = { map = 2413, x = 0.649, y = 0.573 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86862, text = "The Greater They Aln (objective 2)",
          coord = { map = 2413, x = 0.650, y = 0.574 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86862, text = "Turn in: The Greater They Aln",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86865, text = "In Search of the Problem",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86865, text = "In Search of the Problem (objective 1)",
          coord = { map = 2413, x = 0.631, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86865, text = "Turn in: In Search of the Problem",
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
        { type = "turnin", questID = 86866, text = "Turn in: Can We Heal This?",
          coord = { map = 2413, x = 0.320, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94677, text = "Turn in: The Missing Rootwarden",
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
        { type = "turnin", questID = 86882, text = "Turn in: Alndust in Right Hands",
          coord = { map = 2413, x = 0.332, y = 0.760 } },  -- APR route coord (converted)
        { type = "accept", questID = 86867, text = "Into the Lightbloom",
          coord = { map = 2413, x = 0.332, y = 0.760 } },  -- giver coord: ATT
        { type = "quest",  questID = 86867, text = "Into the Lightbloom (objective 1)",
          coord = { map = 2413, x = 0.333, y = 0.759 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86867, text = "Into the Lightbloom (objective 2,3)",
          coord = { map = 2413, x = 0.333, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86867, text = "Turn in: Into the Lightbloom",
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
          coord = nil, noArrow = true },  -- no coord: APR step has none
        { type = "turnin", questID = 86877, text = "Turn in: Righteous Pruning",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86880, text = "Turn in: Our Beloved, Returned",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86881, text = "Turn in: At the Root",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- APR route coord (converted)
        { type = "accept", questID = 86890, text = "Tell the People What You Have Seen",
          coord = { map = 2413, x = 0.306, y = 0.772 } },  -- giver coord: ATT
        { type = "quest",  questID = 86890, text = "Tell the People What You Have Seen (objective 1)",
          coord = { map = 2413, x = 0.501, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86890, text = "Tell the People What You Have Seen (objective 2)",
          coord = { map = 2413, x = 0.501, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86890, text = "Turn in: Tell the People What You Have Seen",
          coord = { map = 2413, x = 0.532, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86883, text = "The Frenzied March",
          coord = { map = 2413, x = 0.532, y = 0.555 } },  -- giver coord: ATT
        { type = "quest",  questID = 86883, text = "The Frenzied March (objective 1)",
          coord = { map = 2413, x = 0.534, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86883, text = "Turn in: The Frenzied March",
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
        { type = "turnin", questID = 86884, text = "Turn in: Cull and Burn",
          coord = { map = 2395, x = 0.622, y = 0.595 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86885, text = "Turn in: Stem the Tides",
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
        { type = "turnin", questID = 86887, text = "Turn in: Expeditious Retreat",
          coord = { map = 2395, x = 0.587, y = 0.572 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86891, text = "Turn in: A Last Resort",
          coord = { map = 2395, x = 0.587, y = 0.572 } },  -- APR route coord (converted)
        { type = "accept", questID = 86892, text = "Survive",
          coord = { map = 2395, x = 0.587, y = 0.573 } },  -- giver coord: ATT
        { type = "quest",  questID = 86892, text = "Survive (objective 1)",
          coord = { map = 2395, x = 0.586, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86892, text = "Survive (objective 2)",
          coord = { map = 2395, x = 0.588, y = 0.571 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86892, text = "Turn in: Survive",
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
        { type = "turnin", questID = 86896, text = "Turn in: Light Finds a Way",
          coord = { map = 2395, x = 0.607, y = 0.568 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86894, text = "Turn in: The Gift of Aln'hara",
          coord = { map = 2395, x = 0.608, y = 0.568 } },  -- APR route coord (converted)
        { type = "accept", questID = 86897, text = "Quelling the Frenzy",
          coord = { map = 2395, x = 0.608, y = 0.568 } },  -- giver coord: ATT
        { type = "quest",  questID = 86897, text = "Quelling the Frenzy (objective 1)",
          coord = { map = 2395, x = 0.628, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86897, text = "Turn in: Quelling the Frenzy",
          coord = { map = 2395, x = 0.584, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86898, text = "Rise of the Haranir",
          coord = { map = 2395, x = 0.584, y = 0.554 } },  -- giver coord: ATT
        { type = "turnin", questID = 86898, text = "Turn in: Rise of the Haranir",
          coord = { map = 2393, x = 0.366, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 91084, text = "Looming Shadows",
          coord = { map = 2393, x = 0.366, y = 0.684 } },  -- giver coord: ATT
        { type = "accept", questID = 95324, text = "The War Beyond the Roots",
          coord = { map = 2393, x = 0.365, y = 0.685 } },  -- giver coord: ATT
        { type = "turnin", questID = 91084, text = "Turn in: Looming Shadows",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95324, text = "Turn in: The War Beyond the Roots",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}
