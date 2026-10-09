-- ToonAge guide data: Midnight: Voidstorm (Campaign + side quests)
-- Kind: APR "sojourner" route
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Voidstorm"
--    in Routes/Midnight/Midnight-Voidstorm.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 151 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 139 accept steps where ATT and converted APR coords share a map: median 0.05, p90 0.13, max 0.53 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (2 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 882 Eredath, 2393 Silvermoon City, 2405 Voidstorm, 2424 Isle of Quel'Danas, 2444 Slayer's Rise, 2527 Lair of Predaxas


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_voidstorm_full"] = {
    id = "midnight_voidstorm_full", title = "Midnight: Voidstorm (Campaign + side quests)", expansion = "midnight",
    zone = 2405, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_war_of_light_and_shadow",
    steps = {
        -- (APR: grind/continue to level 88 before the next step)
        { type = "accept", questID = 92061, text = "Rising Storm",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT; only if warband lacks achievement 42045
        { type = "quest",  questID = 92061, text = "Rising Storm (objective 2)",
          coord = { map = 2393, x = 0.456, y = 0.464 } },  -- APR route coord (converted); only if warband lacks achievement 42045
        { type = "quest",  questID = 92061, text = "Rising Storm (objective 1)",
          coord = { map = 2393, x = 0.387, y = 0.470 } },  -- APR route coord (converted); only if warband lacks achievement 42045
        { type = "turnin", questID = 92061, text = "Turn in: Rising Storm",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted); only if warband lacks achievement 42045
        { type = "accept", questID = 86543, text = "Magisters' Terrace: Homecoming",
          coord = { map = 2393, x = 0.453, y = 0.702 } },  -- giver coord: ATT
        { type = "quest",  questID = 86543, text = "Magisters' Terrace: Homecoming (objective 1)",
          coord = { map = 2424, x = 0.619, y = 0.152 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86543, text = "Magisters' Terrace: Homecoming (objective 3)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 86543, text = "Turn in: Magisters' Terrace: Homecoming",
          coord = { map = 2393, x = 0.351, y = 0.658 } },  -- APR route coord (converted)
        { type = "accept", questID = 86549, text = "No Fear of the Dark",
          coord = { map = 2393, x = 0.352, y = 0.658 } },  -- giver coord: ATT
        { type = "quest",  questID = 86549, text = "No Fear of the Dark (objective 1)",
          coord = { map = 2393, x = 0.353, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86549, text = "No Fear of the Dark (objective 3)",
          coord = { map = 2393, x = 0.353, y = 0.661 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86549, text = "Turn in: No Fear of the Dark", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.343, y = 0.604 } },  -- APR route coord (converted)
        { type = "accept", questID = 86558, text = "Save a Piece of Mind",
          coord = { map = 2405, x = 0.343, y = 0.605 } },  -- giver coord: ATT
        { type = "accept", questID = 86557, text = "A Matter of Strife and Death",
          coord = { map = 2405, x = 0.344, y = 0.605 } },  -- giver coord: ATT
        { type = "quest",  questID = 86558, text = "Save a Piece of Mind (objective 1) [1/3]",
          coord = { map = 2405, x = 0.347, y = 0.588 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86557, text = "A Matter of Strife and Death (objective 1)",
          coord = { map = 2405, x = 0.362, y = 0.601 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86558, text = "Save a Piece of Mind (objective 1) [2/3]",
          coord = { map = 2405, x = 0.362, y = 0.601 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86558, text = "Save a Piece of Mind (objective 1) [3/3]",
          coord = { map = 2405, x = 0.362, y = 0.580 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86557, text = "A Matter of Strife and Death (objective 1)",
          coord = { map = 2405, x = 0.356, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86557, text = "Turn in: A Matter of Strife and Death", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86558, text = "Turn in: Save a Piece of Mind", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 86559, text = "The Far, Far Frontier",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- giver coord: ATT
        { type = "quest",  questID = 86559, text = "The Far, Far Frontier (objective 1)",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86559, text = "The Far, Far Frontier (objective 2)",
          coord = { map = 2405, x = 0.369, y = 0.587 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86559, text = "Turn in: The Far, Far Frontier", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.313, y = 0.544 } },  -- APR route coord (converted)
        { type = "accept", questID = 86562, text = "Dancing with Death",
          coord = { map = 2405, x = 0.313, y = 0.544 } },  -- giver coord: ATT
        { type = "accept", questID = 86561, text = "A Strange, Different World",
          coord = { map = 2405, x = 0.313, y = 0.543 } },  -- giver coord: ATT
        { type = "quest",  questID = 86562, text = "Dancing with Death (objective 3)",
          coord = { map = 2405, x = 0.278, y = 0.534 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86562, text = "Dancing with Death (objective 2)",
          coord = { map = 2405, x = 0.261, y = 0.532 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86562, text = "Dancing with Death (objective 1)",
          coord = { map = 2405, x = 0.281, y = 0.503 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86561, text = "A Strange, Different World (objective 1)",
          coord = { map = 2405, x = 0.282, y = 0.525 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86562, text = "Turn in: Dancing with Death", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86561, text = "Turn in: A Strange, Different World", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 86565, text = "No Prayer for the Wicked",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- giver coord: ATT
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 1)",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 2)",
          coord = { map = 2405, x = 0.262, y = 0.515 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 3)",
          coord = { map = 2405, x = 0.265, y = 0.511 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86565, text = "Turn in: No Prayer for the Wicked", rep = { { factionID = 2699, amount = 1500 } },
          coord = { map = 2405, x = 0.354, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 86536, text = "Reliable Enemies",
          coord = { map = 2405, x = 0.354, y = 0.591 } },  -- giver coord: ATT
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 1)",
          coord = { map = 2405, x = 0.354, y = 0.590 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 2)",
          coord = { map = 2405, x = 0.366, y = 0.730 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 3)",
          coord = { map = 2405, x = 0.367, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86536, text = "Turn in: Reliable Enemies", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.366, y = 0.730 } },  -- APR route coord (converted)
        { type = "accept", questID = 86531, text = "Work Disruption",
          coord = { map = 2405, x = 0.366, y = 0.730 } },  -- giver coord: ATT
        { type = "accept", questID = 86530, text = "First, The Shells",
          coord = { map = 2405, x = 0.367, y = 0.731 } },  -- giver coord: ATT
        { type = "quest",  questID = 86530, text = "First, The Shells (objective 2)",
          coord = { map = 2405, x = 0.367, y = 0.731 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86530, text = "First, The Shells (objective 1)",
          coord = { map = 2405, x = 0.365, y = 0.761 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86531, text = "Work Disruption (objective 1)",
          coord = { map = 2405, x = 0.365, y = 0.761 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86531, text = "Turn in: Work Disruption", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86528, text = "Turn in: A Cracked Holokey", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86530, text = "Turn in: First, The Shells", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- APR route coord (converted)
        { type = "accept", questID = 86538, text = "Second, The Fuel",
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- giver coord: ATT
        { type = "accept", questID = 86537, text = "Network Insecurity",
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- giver coord: ATT
        { type = "quest",  questID = 86537, text = "Network Insecurity (objective 1)",
          coord = { map = 2405, x = 0.342, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86537, text = "Network Insecurity (objective 2)",
          coord = { map = 2405, x = 0.335, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86537, text = "Network Insecurity (objective 3)",
          coord = { map = 2405, x = 0.337, y = 0.794 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86537, text = "Network Insecurity (objective 4)",
          coord = { map = 2405, x = 0.346, y = 0.780 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86537, text = "Network Insecurity (objective 5)",
          coord = { map = 2405, x = 0.346, y = 0.780 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86538, text = "Second, The Fuel (objective 1)",
          coord = { map = 2405, x = 0.341, y = 0.793 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86537, text = "Turn in: Network Insecurity", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86538, text = "Turn in: Second, The Fuel", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- APR route coord (converted)
        { type = "accept", questID = 86539, text = "A Naaru!",
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- giver coord: ATT
        { type = "turnin", questID = 86539, text = "Turn in: A Naaru!", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.394, y = 0.822 } },  -- APR route coord (converted)
        { type = "accept", questID = 86540, text = "Third, Blow It Up",
          coord = { map = 2405, x = 0.393, y = 0.822 } },  -- giver coord: ATT
        { type = "accept", questID = 88768, text = "Agents of Darkness",
          coord = { map = 2405, x = 0.394, y = 0.822 } },  -- giver coord: ATT
        { type = "accept", questID = 86541, text = "Just In Case...",
          coord = { map = 2405, x = 0.394, y = 0.821 } },  -- giver coord: ATT
        { type = "quest",  questID = 88768, text = "Agents of Darkness (objective 2)",
          coord = { map = 2405, x = 0.411, y = 0.850 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88768, text = "Agents of Darkness (objective 1)",
          coord = { map = 2405, x = 0.387, y = 0.875 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86540, text = "Third, Blow It Up (objective 1) [1/5]",
          coord = { map = 2405, x = 0.374, y = 0.887 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86540, text = "Third, Blow It Up (objective 1) [2/5]",
          coord = { map = 2405, x = 0.374, y = 0.884 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86540, text = "Third, Blow It Up (objective 1) [3/5]",
          coord = { map = 2405, x = 0.374, y = 0.886 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86540, text = "Third, Blow It Up (objective 1) [4/5]",
          coord = { map = 2405, x = 0.372, y = 0.884 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86540, text = "Third, Blow It Up (objective 1) [5/5]",
          coord = { map = 2405, x = 0.371, y = 0.885 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88768, text = "Agents of Darkness (objective 3)",
          coord = { map = 2405, x = 0.378, y = 0.855 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86541, text = "Just In Case... (objective 1)",
          coord = { map = 2405, x = 0.381, y = 0.865 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86541, text = "Just In Case... (objective 2)",
          coord = { map = 2405, x = 0.386, y = 0.838 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88768, text = "Turn in: Agents of Darkness", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.380, y = 0.834 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86540, text = "Turn in: Third, Blow It Up", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.380, y = 0.832 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86541, text = "Turn in: Just In Case...", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.379, y = 0.832 } },  -- APR route coord (converted)
        { type = "accept", questID = 86542, text = "Flicker in the Dark",
          coord = { map = 2405, x = 0.380, y = 0.832 } },  -- giver coord: ATT
        { type = "quest",  questID = 86542, text = "Flicker in the Dark (objective 1)",
          coord = { map = 2405, x = 0.379, y = 0.833 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86542, text = "Flicker in the Dark (objective 2)",
          coord = { map = 2405, x = 0.385, y = 0.838 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86542, text = "Flicker in the Dark (objective 3)",
          coord = { map = 2405, x = 0.387, y = 0.855 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86542, text = "Flicker in the Dark (objective 4)",
          coord = { map = 2405, x = 0.387, y = 0.855 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86542, text = "Turn in: Flicker in the Dark", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.416, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 89249, text = "Overwhelmed",
          coord = { map = 2405, x = 0.416, y = 0.788 } },  -- giver coord: ATT
        { type = "turnin", questID = 89249, text = "Turn in: Overwhelmed", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86544, text = "Post-Mortem",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 2)",
          coord = { map = 2405, x = 0.418, y = 0.748 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 4) [1/3]",
          coord = { map = 2405, x = 0.417, y = 0.746 } },  -- APR route coord (converted)
        { type = "accept", questID = 91884, text = "The Illusion of Motion",
          coord = { map = 2405, x = 0.414, y = 0.740 } },  -- giver coord: ATT
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 5)",
          coord = { map = 2405, x = 0.415, y = 0.738 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 6)",
          coord = { map = 2405, x = 0.416, y = 0.732 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 3)",
          coord = { map = 2405, x = 0.422, y = 0.742 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 4) [2/3]",
          coord = { map = 2405, x = 0.421, y = 0.753 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 4) [3/3]",
          coord = { map = 2405, x = 0.423, y = 0.754 } },  -- APR route coord (converted)
        { type = "accept", questID = 90910, text = "Overwhelming Darkness",
          coord = { map = 2405, x = 0.424, y = 0.754 } },  -- giver coord: ATT
        { type = "quest",  questID = 90910, text = "Overwhelming Darkness (objective 1)",
          coord = { map = 2405, x = 0.424, y = 0.754 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86544, text = "Turn in: Post-Mortem", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86545, text = "The Light's Brand",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 1)",
          coord = { map = 2405, x = 0.412, y = 0.726 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 3)",
          coord = { map = 2405, x = 0.410, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 4)",
          coord = { map = 2405, x = 0.412, y = 0.727 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86545, text = "Turn in: The Light's Brand", rep = { { factionID = 2699, amount = 1500 } },
          coord = { map = 2405, x = 0.411, y = 0.727 } },  -- APR route coord (converted)
        { type = "accept", questID = 86509, text = "Friend or Fiend",
          coord = { map = 2405, x = 0.412, y = 0.727 } },  -- giver coord: ATT
        { type = "quest",  questID = 86509, text = "Friend or Fiend (objective 1)",
          coord = { map = 2405, x = 0.513, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86509, text = "Turn in: Friend or Fiend", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.514, y = 0.729 } },  -- APR route coord (converted)
        { type = "accept", questID = 86510, text = "Domus Penumbra",
          coord = { map = 2405, x = 0.514, y = 0.729 } },  -- giver coord: ATT
        { type = "quest",  questID = 86510, text = "Domus Penumbra (objective 1)",
          coord = { map = 2405, x = 0.526, y = 0.729 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86510, text = "Domus Penumbra (objective 3)",
          coord = { map = 2405, x = 0.516, y = 0.700 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86510, text = "Domus Penumbra (objective 4)",
          coord = { map = 2405, x = 0.512, y = 0.693 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86510, text = "Domus Penumbra (objective 2)",
          coord = { map = 2405, x = 0.532, y = 0.682 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86510, text = "Turn in: Domus Penumbra", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- APR route coord (converted)
        { type = "accept", questID = 90571, text = "The Lay of the Beast",
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- giver coord: ATT
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [1/3]",
          coord = { map = 2405, x = 0.475, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [2/3]",
          coord = { map = 2405, x = 0.494, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [3/3]",
          coord = { map = 2405, x = 0.514, y = 0.560 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90571, text = "Turn in: The Lay of the Beast", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- APR route coord (converted)
        { type = "accept", questID = 86511, text = "Edge of the Abyss",
          coord = { map = 2405, x = 0.511, y = 0.680 } },  -- giver coord: ATT
        { type = "quest",  questID = 86511, text = "Edge of the Abyss (objective 1)",
          coord = { map = 2405, x = 0.544, y = 0.743 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86511, text = "Turn in: Edge of the Abyss", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.544, y = 0.743 } },  -- APR route coord (converted)
        { type = "accept", questID = 86512, text = "The Harvest",
          coord = { map = 2405, x = 0.543, y = 0.743 } },  -- giver coord: ATT
        { type = "accept", questID = 86513, text = "Face the Tide",
          coord = { map = 2405, x = 0.543, y = 0.743 } },  -- giver coord: ATT
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 2) [1/4]",
          coord = { map = 2405, x = 0.552, y = 0.738 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 2) [2/4]",
          coord = { map = 2405, x = 0.548, y = 0.733 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [1/6]",
          coord = { map = 2405, x = 0.550, y = 0.733 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [2/6]",
          coord = { map = 2405, x = 0.550, y = 0.730 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 2) [3/4]",
          coord = { map = 2405, x = 0.562, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [3/6]",
          coord = { map = 2405, x = 0.561, y = 0.721 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 2) [4/4]",
          coord = { map = 2405, x = 0.560, y = 0.720 } },  -- APR route coord (converted)
        { type = "accept", questID = 90782, text = "The Nethersent",
          coord = { map = 2405, x = 0.562, y = 0.719 } },  -- giver coord: ATT
        { type = "quest",  questID = 90782, text = "The Nethersent (objective 1)",
          coord = { map = 2405, x = 0.562, y = 0.719 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [4/6]",
          coord = { map = 2405, x = 0.565, y = 0.707 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [5/6]",
          coord = { map = 2405, x = 0.566, y = 0.706 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 3) [6/6]",
          coord = { map = 2405, x = 0.573, y = 0.713 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86512, text = "The Harvest (objective 1)",
          coord = { map = 2405, x = 0.559, y = 0.725 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86513, text = "Face the Tide (objective 1)",
          coord = { map = 2405, x = 0.559, y = 0.725 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86513, text = "Turn in: Face the Tide", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.556, y = 0.727 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86512, text = "Turn in: The Harvest", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.556, y = 0.728 } },  -- APR route coord (converted)
        { type = "accept", questID = 86514, text = "Lady of the Pit",
          coord = { map = 2405, x = 0.556, y = 0.728 } },  -- giver coord: ATT
        { type = "quest",  questID = 86514, text = "Lady of the Pit (objective 1)",
          coord = { map = 2405, x = 0.555, y = 0.765 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86514, text = "Lady of the Pit (objective 2)",
          coord = { map = 2405, x = 0.555, y = 0.765 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86514, text = "Lady of the Pit (objective 3)",
          coord = { map = 2405, x = 0.556, y = 0.786 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86514, text = "Lady of the Pit (objective 4)",
          coord = { map = 2405, x = 0.556, y = 0.786 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86514, text = "Turn in: Lady of the Pit", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- APR route coord (converted)
        { type = "accept", questID = 86516, text = "All Become Prey",
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- giver coord: ATT
        { type = "accept", questID = 86517, text = "Vanished in the Void",
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- giver coord: ATT
        { type = "accept", questID = 86515, text = "Hollow Hunger",
          coord = { map = 2405, x = 0.607, y = 0.736 } },  -- giver coord: ATT
        { type = "quest",  questID = 86515, text = "Hollow Hunger (objective 1)",
          coord = { map = 2405, x = 0.642, y = 0.756 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86515, text = "Hollow Hunger (objective 2)",
          coord = { map = 2405, x = 0.642, y = 0.756 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86517, text = "Vanished in the Void (objective 1)",
          coord = { map = 2405, x = 0.604, y = 0.789 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86517, text = "Vanished in the Void (objective 2)",
          coord = { map = 2405, x = 0.612, y = 0.808 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86517, text = "Vanished in the Void (objective 3)",
          coord = { map = 2405, x = 0.624, y = 0.824 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86517, text = "Vanished in the Void (objective 4)",
          coord = { map = 2405, x = 0.624, y = 0.824 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86516, text = "All Become Prey (objective 1,2)", useItem = 237807,
          coord = { map = 2405, x = 0.627, y = 0.764 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86517, text = "Turn in: Vanished in the Void", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.608, y = 0.737 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86515, text = "Turn in: Hollow Hunger", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.607, y = 0.736 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86516, text = "Turn in: All Become Prey", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- APR route coord (converted)
        { type = "accept", questID = 86518, text = "The Mantle of Predation",
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- giver coord: ATT
        { type = "quest",  questID = 86518, text = "The Mantle of Predation (objective 2)",
          coord = { map = 2405, x = 0.608, y = 0.736 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86518, text = "The Mantle of Predation (objective 3) [1/2]",
          coord = { map = 2405, x = 0.634, y = 0.785 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86518, text = "The Mantle of Predation (objective 3) [2/2]",
          coord = { map = 2405, x = 0.626, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86518, text = "The Mantle of Predation (objective 4)",
          coord = { map = 2405, x = 0.644, y = 0.809 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86518, text = "Turn in: The Mantle of Predation", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.603, y = 0.764 } },  -- APR route coord (converted)
        { type = "accept", questID = 86519, text = "Abyssus, Abyssum",
          coord = { map = 2405, x = 0.603, y = 0.764 } },  -- giver coord: ATT
        { type = "quest",  questID = 86519, text = "Abyssus, Abyssum (objective 1)",
          coord = { map = 2405, x = 0.606, y = 0.766 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86519, text = "Abyssus, Abyssum (objective 2)",
          coord = { map = 2405, x = 0.609, y = 0.769 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86519, text = "Turn in: Abyssus, Abyssum", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.601, y = 0.762 } },  -- APR route coord (converted)
        { type = "accept", questID = 86520, text = "Hunt the Light",
          coord = { map = 2405, x = 0.601, y = 0.762 } },  -- giver coord: ATT
        { type = "quest",  questID = 86520, text = "Hunt the Light (objective 1)",
          coord = { map = 2405, x = 0.639, y = 0.617 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86520, text = "Turn in: Hunt the Light", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.641, y = 0.618 } },  -- APR route coord (converted)
        { type = "accept", questID = 86521, text = "Nexus-Point Xenas: Eclipse",
          coord = { map = 2405, x = 0.641, y = 0.618 } },  -- giver coord: ATT
        { type = "quest",  questID = 86521, text = "Nexus-Point Xenas: Eclipse (objective 3)",
          coord = nil },  -- no coord: APR step has none
        { type = "quest",  questID = 86521, text = "Nexus-Point Xenas: Eclipse (objective 4)",
          coord = { map = 2405, x = 0.459, y = 0.646 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86521, text = "Turn in: Nexus-Point Xenas: Eclipse", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.460, y = 0.646 } },  -- APR route coord (converted)
        { type = "accept", questID = 86522, text = "Daylight is Breaking",
          coord = { map = 2405, x = 0.460, y = 0.646 } },  -- giver coord: ATT
        { type = "turnin", questID = 86522, text = "Turn in: Daylight is Breaking", rep = { { factionID = 2699, amount = 1500 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 95276, text = "The Last Push",
          coord = { map = 2393, x = 0.454, y = 0.706 } },  -- giver coord: ATT
        { type = "accept", questID = 92939, text = "It's Not Just a Rock!",
          coord = { map = 2405, x = 0.369, y = 0.585 } },  -- giver coord: ATT
        { type = "accept", questID = 88755, text = "Scholarly Pursuits",
          coord = { map = 2405, x = 0.358, y = 0.586 } },  -- giver coord: ATT
        { type = "accept", questID = 91557, text = "Message to the Molt",
          coord = { map = 2405, x = 0.355, y = 0.588 } },  -- giver coord: ATT
        { type = "turnin", questID = 91557, text = "Turn in: Message to the Molt",
          coord = { map = 2444, x = 0.184, y = 0.994 } },  -- APR route coord (converted)
        { type = "accept", questID = 91559, text = "Virulent Vermin",
          coord = { map = 2405, x = 0.359, y = 0.483 } },  -- giver coord: ATT
        { type = "accept", questID = 91558, text = "Pestilent Petals",
          coord = { map = 2405, x = 0.359, y = 0.483 } },  -- giver coord: ATT
        { type = "quest",  questID = 91558, text = "Pestilent Petals (objective 1)",
          coord = { map = 2444, x = 0.163, y = 0.965 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91559, text = "Virulent Vermin (objective 1)",
          coord = { map = 2444, x = 0.163, y = 0.965 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91559, text = "Turn in: Virulent Vermin", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91558, text = "Turn in: Pestilent Petals",
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "accept", questID = 91560, text = "Expunging Explorers",
          coord = { map = 2405, x = 0.346, y = 0.438 } },  -- giver coord: ATT
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 1)",
          coord = { map = 2444, x = 0.154, y = 0.895 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 2)",
          coord = { map = 2444, x = 0.155, y = 0.895 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 3)",
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 4)",
          coord = { map = 2444, x = 0.156, y = 0.896 } },  -- APR route coord (converted)
        { type = "accept", questID = 93801, text = "Calculated Culling",
          coord = { map = 2405, x = 0.347, y = 0.438 } },  -- giver coord: ATT
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [1/6]",
          coord = { map = 2444, x = 0.135, y = 0.931 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [2/6]",
          coord = { map = 2444, x = 0.141, y = 0.944 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [3/6]",
          coord = { map = 2444, x = 0.146, y = 0.973 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [4/6]",
          coord = { map = 2444, x = 0.135, y = 0.995 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [5/6]",
          coord = { map = 2444, x = 0.118, y = 0.973 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 5) [6/6]",
          coord = { map = 2444, x = 0.123, y = 0.953 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93801, text = "Calculated Culling (objective 1)",
          coord = { map = 2444, x = 0.142, y = 0.947 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91560, text = "Expunging Explorers (objective 6)",
          coord = { map = 2444, x = 0.126, y = 0.898 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91560, text = "Turn in: Expunging Explorers", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93801, text = "Turn in: Calculated Culling", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "accept", questID = 91561, text = "Bloodborne Pathogen",
          coord = { map = 2405, x = 0.346, y = 0.438 } },  -- giver coord: ATT
        { type = "quest",  questID = 91561, text = "Bloodborne Pathogen (objective 1)",
          coord = { map = 2444, x = 0.101, y = 0.912 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91561, text = "Turn in: Bloodborne Pathogen", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2444, x = 0.155, y = 0.894 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92939, text = "It's Not Just a Rock! (objective 1)",
          coord = { map = 2405, x = 0.385, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92939, text = "Turn in: It's Not Just a Rock!", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- APR route coord (converted)
        { type = "accept", questID = 92944, text = "Sifting Through Void",
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- giver coord: ATT
        { type = "quest",  questID = 92944, text = "Sifting Through Void (objective 1)",
          coord = { map = 2405, x = 0.402, y = 0.568 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92944, text = "Sifting Through Void (objective 2)",
          coord = { map = 2405, x = 0.395, y = 0.578 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92944, text = "Turn in: Sifting Through Void", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- APR route coord (converted)
        { type = "accept", questID = 92946, text = "Buried in the Dark",
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- giver coord: ATT
        { type = "quest",  questID = 92946, text = "Buried in the Dark (objective 1)",
          coord = { map = 2405, x = 0.402, y = 0.568 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92946, text = "Buried in the Dark (objective 2)",
          coord = { map = 2405, x = 0.387, y = 0.588 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92946, text = "Buried in the Dark (objective 3)",
          coord = { map = 2405, x = 0.393, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92946, text = "Buried in the Dark (objective 4)",
          coord = { map = 2405, x = 0.397, y = 0.583 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92946, text = "Turn in: Buried in the Dark", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- APR route coord (converted)
        { type = "accept", questID = 92948, text = "In Over My Head",
          coord = { map = 2405, x = 0.402, y = 0.561 } },  -- giver coord: ATT
        { type = "quest",  questID = 92948, text = "In Over My Head (objective 1)",
          coord = { map = 2405, x = 0.402, y = 0.568 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92948, text = "In Over My Head (objective 2)",
          coord = { map = 2405, x = 0.397, y = 0.559 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92948, text = "Turn in: In Over My Head", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.371, y = 0.590 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88755, text = "Turn in: Scholarly Pursuits", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 87388, text = "A Bigger Beast",
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- giver coord: ATT
        { type = "accept", questID = 87391, text = "Sampling the Local Fare",
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- giver coord: ATT
        { type = "quest",  questID = 87388, text = "A Bigger Beast (objective 1)",
          coord = { map = 2405, x = 0.411, y = 0.638 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87391, text = "Sampling the Local Fare (objective 1)",
          coord = { map = 2405, x = 0.411, y = 0.638 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87391, text = "Sampling the Local Fare (objective 2)",
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87388, text = "Turn in: A Bigger Beast", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87391, text = "Turn in: Sampling the Local Fare", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 87672, text = "Void is in the Air",
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- giver coord: ATT
        { type = "accept", questID = 88653, text = "Yolks on You",
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- giver coord: ATT
        { type = "quest",  questID = 87672, text = "Void is in the Air (objective 1) [1/3]", useItem = 267614,
          coord = { map = 2405, x = 0.400, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87672, text = "Void is in the Air (objective 1) [2/3]",
          coord = { map = 2405, x = 0.413, y = 0.638 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87672, text = "Void is in the Air (objective 1) [3/3]",
          coord = { map = 2405, x = 0.404, y = 0.665 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88653, text = "Yolks on You (objective 1)",
          coord = { map = 2405, x = 0.419, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88653, text = "Turn in: Yolks on You", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87672, text = "Turn in: Void is in the Air", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 88708, text = "Violent Conclusions",
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- giver coord: ATT
        { type = "quest",  questID = 88708, text = "Violent Conclusions (objective 1)",
          coord = { map = 2405, x = 0.411, y = 0.615 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88708, text = "Violent Conclusions (objective 2)",
          coord = { map = 2405, x = 0.393, y = 0.683 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88708, text = "Turn in: Violent Conclusions", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.412, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 90845, text = "Distant Memories",
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- giver coord: ATT
        { type = "accept", questID = 90844, text = "Fits of Lucidity",
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- giver coord: ATT
        { type = "quest",  questID = 90844, text = "Fits of Lucidity (objective 1)",
          coord = { map = 2405, x = 0.471, y = 0.702 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90845, text = "Distant Memories (objective 1)",
          coord = { map = 2405, x = 0.471, y = 0.702 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90844, text = "Fits of Lucidity (objective 2)",
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90844, text = "Turn in: Fits of Lucidity", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90845, text = "Turn in: Distant Memories", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- APR route coord (converted)
        { type = "accept", questID = 90847, text = "Truth From Power",
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- giver coord: ATT
        { type = "quest",  questID = 90847, text = "Truth From Power (objective 1,2)",
          coord = { map = 2405, x = 0.449, y = 0.713 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90847, text = "Turn in: Truth From Power", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- APR route coord (converted)
        { type = "accept", questID = 90848, text = "She Started the Fire",
          coord = { map = 2405, x = 0.447, y = 0.686 } },  -- giver coord: ATT
        { type = "turnin", questID = 90910, text = "Turn in: Overwhelming Darkness", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- APR route coord (converted)
        { type = "accept", questID = 91339, text = "Smothered in the Crib",
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- giver coord: ATT
        { type = "accept", questID = 91340, text = "For Violence's Sake",
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- giver coord: ATT
        { type = "quest",  questID = 91339, text = "Smothered in the Crib (objective 1)",
          coord = { map = 2405, x = 0.477, y = 0.783 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91340, text = "For Violence's Sake (objective 1)",
          coord = { map = 2405, x = 0.477, y = 0.783 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91339, text = "Turn in: Smothered in the Crib", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91340, text = "Turn in: For Violence's Sake", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- APR route coord (converted)
        { type = "accept", questID = 91341, text = "Unlimited",
          coord = { map = 2405, x = 0.479, y = 0.786 } },  -- giver coord: ATT
        { type = "quest",  questID = 91341, text = "Unlimited (objective 1)",
          coord = { map = 2405, x = 0.480, y = 0.787 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91341, text = "Turn in: Unlimited", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.477, y = 0.787 } },  -- APR route coord (converted)
        { type = "accept", questID = 91343, text = "Ambition's Reward",
          coord = { map = 2527, x = 0.509, y = 0.453 } },  -- giver coord: ATT
        { type = "quest",  questID = 91343, text = "Ambition's Reward (objective 1)",
          coord = { map = 2405, x = 0.471, y = 0.796 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91884, text = "Turn in: The Illusion of Motion", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.488, y = 0.823 } },  -- APR route coord (converted)
        { type = "accept", questID = 91885, text = "Drain You",
          coord = { map = 2405, x = 0.488, y = 0.823 } },  -- giver coord: ATT
        { type = "quest",  questID = 91885, text = "Drain You (objective 1)", useItem = 249433,
          coord = { map = 2405, x = 0.504, y = 0.784 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91885, text = "Turn in: Drain You", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.488, y = 0.823 } },  -- APR route coord (converted)
        { type = "accept", questID = 91886, text = "Voices of Omens",
          coord = { map = 2405, x = 0.488, y = 0.823 } },  -- giver coord: ATT
        { type = "quest",  questID = 91886, text = "Voices of Omens (objective 1)",
          coord = { map = 2405, x = 0.434, y = 0.862 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91886, text = "Voices of Omens (objective 2)",
          coord = { map = 2405, x = 0.455, y = 0.872 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91886, text = "Voices of Omens (objective 3)",
          coord = { map = 2405, x = 0.475, y = 0.893 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91886, text = "Turn in: Voices of Omens", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.448, y = 0.822 } },  -- APR route coord (converted)
        { type = "accept", questID = 91887, text = "Dominion of Deceit",
          coord = { map = 2405, x = 0.446, y = 0.823 } },  -- giver coord: ATT
        { type = "quest",  questID = 91887, text = "Dominion of Deceit (objective 1)",
          coord = { map = 2405, x = 0.429, y = 0.833 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91343, text = "Turn in: Ambition's Reward", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.424, y = 0.754 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91887, text = "Turn in: Dominion of Deceit", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.414, y = 0.740 } },  -- APR route coord (converted)
        { type = "accept", questID = 91145, text = "The Conquered Heroes",
          coord = { map = 2405, x = 0.518, y = 0.719 } },  -- giver coord: ATT
        { type = "accept", questID = 91363, text = "Harvest of Darkness",
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- giver coord: ATT
        { type = "accept", questID = 93810, text = "Masters' Perch",
          coord = { map = 2405, x = 0.514, y = 0.676 } },  -- giver coord: ATT
        { type = "accept", questID = 90914, text = "A Born Killer",
          coord = { map = 2405, x = 0.512, y = 0.684 } },  -- giver coord: ATT
        { type = "quest",  questID = 91363, text = "Harvest of Darkness (objective 1,2)",
          coord = { map = 2405, x = 0.543, y = 0.714 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90914, text = "A Born Killer (objective 1)",
          coord = { map = 2405, x = 0.559, y = 0.725 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91363, text = "Turn in: Harvest of Darkness", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- APR route coord (converted)
        { type = "accept", questID = 91380, text = "Belly of the Beast",
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- giver coord: ATT
        { type = "turnin", questID = 90914, text = "Turn in: A Born Killer", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.512, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 90915, text = "Artifice of Aggression",
          coord = { map = 2405, x = 0.512, y = 0.684 } },  -- giver coord: ATT
        { type = "quest",  questID = 90915, text = "Artifice of Aggression (objective 1)",
          coord = { map = 2405, x = 0.513, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90915, text = "Artifice of Aggression (objective 2)",
          coord = { map = 2405, x = 0.513, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90915, text = "Artifice of Aggression (objective 3)",
          coord = { map = 2405, x = 0.509, y = 0.687 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90915, text = "Artifice of Aggression (objective 4)",
          coord = { map = 2405, x = 0.513, y = 0.686 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90915, text = "Turn in: Artifice of Aggression", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.512, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 90916, text = "Seek to Destroy",
          coord = { map = 2405, x = 0.512, y = 0.684 } },  -- giver coord: ATT
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 1)",
          coord = { map = 2405, x = 0.512, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 2)",
          coord = { map = 2405, x = 0.512, y = 0.678 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 3)",
          coord = { map = 2405, x = 0.512, y = 0.677 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 4)",
          coord = { map = 2405, x = 0.517, y = 0.689 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 5)",
          coord = { map = 2405, x = 0.524, y = 0.694 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91380, text = "Belly of the Beast (objective 6)",
          coord = { map = 2405, x = 0.535, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91380, text = "Turn in: Belly of the Beast", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- APR route coord (converted)
        { type = "accept", questID = 91382, text = "Mighty and Superior",
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- giver coord: ATT
        { type = "quest",  questID = 91382, text = "Mighty and Superior (objective 1)",
          coord = { map = 2405, x = 0.480, y = 0.754 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91382, text = "Mighty and Superior (objective 2)",
          coord = { map = 2405, x = 0.480, y = 0.749 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91382, text = "Mighty and Superior (objective 3)",
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91382, text = "Turn in: Mighty and Superior", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.521, y = 0.674 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90916, text = "Turn in: Seek to Destroy", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- APR route coord (converted)
        { type = "accept", questID = 90917, text = "Harvester of Savagery",
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- giver coord: ATT
        { type = "accept", questID = 90918, text = "The Unforgiven",
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- giver coord: ATT
        { type = "quest",  questID = 90918, text = "The Unforgiven (objective 2)",
          coord = { map = 2405, x = 0.647, y = 0.633 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90918, text = "The Unforgiven (objective 1)",
          coord = { map = 2405, x = 0.662, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90918, text = "The Unforgiven (objective 3)",
          coord = { map = 2405, x = 0.648, y = 0.599 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90917, text = "Harvester of Savagery (objective 1)", useItem = 248593,
          coord = { map = 2405, x = 0.630, y = 0.618 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90917, text = "Turn in: Harvester of Savagery", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90918, text = "Turn in: The Unforgiven", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- APR route coord (converted)
        { type = "accept", questID = 90919, text = "The Fiend That Failed",
          coord = { map = 2405, x = 0.613, y = 0.619 } },  -- giver coord: ATT
        { type = "quest",  questID = 90919, text = "The Fiend That Failed (objective 1)",
          coord = { map = 2405, x = 0.634, y = 0.585 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90919, text = "Turn in: The Fiend That Failed", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- APR route coord (converted)
        { type = "accept", questID = 90920, text = "Warmth for the Soul",
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- giver coord: ATT
        { type = "quest",  questID = 90920, text = "Warmth for the Soul (objective 1)",
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90920, text = "Turn in: Warmth for the Soul", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- APR route coord (converted)
        { type = "accept", questID = 90923, text = "Shepherd of Fear",
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- giver coord: ATT
        { type = "accept", questID = 90922, text = "The Fallen Wake",
          coord = { map = 2405, x = 0.591, y = 0.567 } },  -- giver coord: ATT
        { type = "quest",  questID = 90923, text = "Shepherd of Fear (objective 1)",
          coord = { map = 2405, x = 0.580, y = 0.540 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90922, text = "The Fallen Wake (objective 1) [1/3]",
          coord = { map = 2405, x = 0.579, y = 0.548 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90922, text = "The Fallen Wake (objective 1) [2/3]",
          coord = { map = 2444, x = 0.688, y = 0.990 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90922, text = "The Fallen Wake (objective 1) [3/3]",
          coord = { map = 2444, x = 0.636, y = 0.920 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90923, text = "Shepherd of Fear (objective 2)",
          coord = { map = 2444, x = 0.591, y = 0.912 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90922, text = "The Fallen Wake (objective 2)",
          coord = { map = 2444, x = 0.510, y = 0.931 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90923, text = "Shepherd of Fear (objective 3)",
          coord = { map = 2405, x = 0.473, y = 0.491 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90923, text = "Turn in: Shepherd of Fear", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.473, y = 0.491 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90922, text = "Turn in: The Fallen Wake", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.473, y = 0.491 } },  -- APR route coord (converted)
        { type = "accept", questID = 90924, text = "The Wicked End",
          coord = { map = 2405, x = 0.473, y = 0.491 } },  -- giver coord: ATT
        { type = "quest",  questID = 90924, text = "The Wicked End (objective 1)",
          coord = { map = 2405, x = 0.462, y = 0.497 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90924, text = "The Wicked End (objective 2)",
          coord = { map = 2405, x = 0.461, y = 0.500 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91145, text = "The Conquered Heroes (objective 1)",
          coord = { map = 2405, x = 0.468, y = 0.566 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91145, text = "The Conquered Heroes (objective 2) [1/3]",
          coord = { map = 2405, x = 0.468, y = 0.565 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91145, text = "The Conquered Heroes (objective 2) [2/3]",
          coord = { map = 2405, x = 0.469, y = 0.563 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91145, text = "The Conquered Heroes (objective 2) [3/3]",
          coord = { map = 2405, x = 0.468, y = 0.560 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91145, text = "The Conquered Heroes (objective 3)",
          coord = { map = 2405, x = 0.470, y = 0.545 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91145, text = "Turn in: The Conquered Heroes", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.540, y = 0.840 } },  -- APR route coord (converted)
        { type = "accept", questID = 91147, text = "Cut Her Strings",
          coord = { map = 2444, x = 0.540, y = 0.840 } },  -- giver coord: ATT
        { type = "accept", questID = 91146, text = "Flickering Light",
          coord = { map = 2444, x = 0.540, y = 0.840 } },  -- giver coord: ATT
        { type = "quest",  questID = 91146, text = "Flickering Light (objective 1) [1/3]",
          coord = { map = 2444, x = 0.508, y = 0.780 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91146, text = "Flickering Light (objective 1) [2/3]",
          coord = { map = 2444, x = 0.516, y = 0.733 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91146, text = "Flickering Light (objective 1) [3/3]",
          coord = { map = 2444, x = 0.475, y = 0.750 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91146, text = "Turn in: Flickering Light", rep = { { factionID = 2699, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "quest",  questID = 91147, text = "Cut Her Strings (objective 1)",
          coord = { map = 2444, x = 0.495, y = 0.793 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91147, text = "Turn in: Cut Her Strings", rep = { { factionID = 2699, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 91148, text = "Strung Along",
          coord = { map = 2444, x = 0.565, y = 0.864 } },  -- giver coord: ATT
        { type = "quest",  questID = 91148, text = "Strung Along (objective 1)",
          coord = { map = 2444, x = 0.540, y = 0.839 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91148, text = "Strung Along (objective 2)",
          coord = { map = 2444, x = 0.540, y = 0.839 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91148, text = "Strung Along (objective 3)",
          coord = { map = 2444, x = 0.444, y = 0.870 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91148, text = "Turn in: Strung Along", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2444, x = 0.441, y = 0.871 } },  -- APR route coord (converted)
        { type = "accept", questID = 91149, text = "Bury Me Not",
          coord = { map = 2444, x = 0.441, y = 0.871 } },  -- giver coord: ATT
        { type = "quest",  questID = 91149, text = "Bury Me Not (objective 1)",
          coord = { map = 2444, x = 0.441, y = 0.871 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91149, text = "Bury Me Not (objective 2)",
          coord = { map = 2444, x = 0.444, y = 0.874 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91149, text = "Bury Me Not (objective 3)",
          coord = { map = 2444, x = 0.419, y = 0.725 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91149, text = "Bury Me Not (objective 4)",
          coord = { map = 2444, x = 0.419, y = 0.725 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91149, text = "Turn in: Bury Me Not", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2444, x = 0.441, y = 0.871 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93810, text = "Turn in: Masters' Perch", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2444, x = 0.399, y = 0.837 } },  -- APR route coord (converted)
        { type = "accept", questID = 92603, text = "O Lonely Star",
          coord = { map = 2444, x = 0.399, y = 0.842 } },  -- giver coord: ATT
        { type = "quest",  questID = 92603, text = "O Lonely Star (objective 1)",
          coord = { map = 2444, x = 0.399, y = 0.842 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92603, text = "O Lonely Star (objective 2)",
          coord = { map = 2444, x = 0.399, y = 0.842 } },  -- APR route coord (converted)
        { type = "accept", questID = 92390, text = "Risk for Research",
          coord = { map = 2444, x = 0.398, y = 0.842 } },  -- giver coord: ATT
        { type = "accept", questID = 91565, text = "Voidscar Arena: The Grief Spire", faction = "Alliance",
          coord = { map = 2444, x = 0.408, y = 0.840 } },  -- giver coord: ATT
        { type = "accept", questID = 91566, text = "Voidscar Arena: The Hate Spire", faction = "Horde",
          coord = { map = 2444, x = 0.348, y = 0.804 } },  -- giver coord: ATT
        { type = "quest",  questID = 92390, text = "Risk for Research (objective 1)",
          coord = { map = 2444, x = 0.630, y = 0.662 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92390, text = "Turn in: Risk for Research", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2444, x = 0.628, y = 0.661 } },  -- APR route coord (converted)
        { type = "accept", questID = 92155, text = "Object Exorcism",
          coord = { map = 2444, x = 0.628, y = 0.662 } },  -- giver coord: ATT
        { type = "quest",  questID = 92155, text = "Object Exorcism (objective 3)",
          coord = { map = 2444, x = 0.654, y = 0.650 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92155, text = "Object Exorcism (objective 1)",
          coord = { map = 2444, x = 0.651, y = 0.610 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92155, text = "Object Exorcism (objective 2)",
          coord = { map = 2444, x = 0.641, y = 0.609 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92155, text = "Turn in: Object Exorcism", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.647, y = 0.642 } },  -- APR route coord (converted)
        { type = "accept", questID = 92156, text = "It Follows Me",
          coord = { map = 2444, x = 0.647, y = 0.641 } },  -- giver coord: ATT
        { type = "quest",  questID = 92156, text = "It Follows Me (objective 1)", useItem = 251278,
          coord = { map = 2444, x = 0.651, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92156, text = "Turn in: It Follows Me", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.647, y = 0.641 } },  -- APR route coord (converted)
        { type = "accept", questID = 92157, text = "Ritual Activity",
          coord = { map = 2444, x = 0.647, y = 0.642 } },  -- giver coord: ATT
        { type = "quest",  questID = 92157, text = "Ritual Activity (objective 1) [1/3]",
          coord = { map = 2444, x = 0.630, y = 0.665 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92157, text = "Ritual Activity (objective 1) [2/3]",
          coord = { map = 2444, x = 0.629, y = 0.665 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92157, text = "Ritual Activity (objective 1) [3/3]",
          coord = { map = 2444, x = 0.628, y = 0.663 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92157, text = "Ritual Activity (objective 2)",
          coord = { map = 2444, x = 0.627, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92157, text = "Ritual Activity (objective 3)",
          coord = { map = 2444, x = 0.628, y = 0.665 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92157, text = "Turn in: Ritual Activity", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.629, y = 0.662 } },  -- APR route coord (converted)
        { type = "accept", questID = 92158, text = "Let It In",
          coord = { map = 2444, x = 0.629, y = 0.662 } },  -- giver coord: ATT
        { type = "quest",  questID = 92158, text = "Let It In (objective 1)",
          coord = { map = 2444, x = 0.690, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92158, text = "Let It In (objective 2)",
          coord = { map = 2444, x = 0.690, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92158, text = "Let It In (objective 3)",
          coord = { map = 2444, x = 0.691, y = 0.623 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92158, text = "Turn in: Let It In", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2444, x = 0.692, y = 0.623 } },  -- APR route coord (converted)
        { type = "accept", questID = 92159, text = "A Final Destination",
          coord = { map = 2444, x = 0.691, y = 0.622 } },  -- giver coord: ATT
        { type = "quest",  questID = 92159, text = "A Final Destination (objective 1)",
          coord = { map = 2444, x = 0.573, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92159, text = "A Final Destination (objective 2)",
          coord = { map = 2444, x = 0.585, y = 0.466 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92159, text = "Turn in: A Final Destination", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2444, x = 0.574, y = 0.474 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92603, text = "Turn in: O Lonely Star", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2444, x = 0.396, y = 0.381 } },  -- APR route coord (converted)
        { type = "accept", questID = 92604, text = "Speak in Blood",
          coord = { map = 2444, x = 0.395, y = 0.382 } },  -- giver coord: ATT
        { type = "accept", questID = 92605, text = "Honest as Bone",
          coord = { map = 2444, x = 0.395, y = 0.381 } },  -- giver coord: ATT
        { type = "quest",  questID = 92604, text = "Speak in Blood (objective 1)",
          coord = { map = 2444, x = 0.343, y = 0.358 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92605, text = "Honest as Bone (objective 1)",
          coord = { map = 2444, x = 0.343, y = 0.358 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92604, text = "Turn in: Speak in Blood", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92605, text = "Turn in: Honest as Bone", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- APR route coord (converted)
        { type = "accept", questID = 92606, text = "Take Up Your Gift",
          coord = { map = 2444, x = 0.331, y = 0.363 } },  -- giver coord: ATT
        { type = "quest",  questID = 92606, text = "Take Up Your Gift (objective 1)",
          coord = { map = 2444, x = 0.331, y = 0.363 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92606, text = "Take Up Your Gift (objective 2)",
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92606, text = "Take Up Your Gift (objective 3)",
          coord = { map = 2444, x = 0.329, y = 0.380 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92606, text = "Turn in: Take Up Your Gift", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- APR route coord (converted)
        { type = "accept", questID = 92607, text = "And Carve New Shapes",
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- giver coord: ATT
        { type = "quest",  questID = 92607, text = "And Carve New Shapes (objective 1)",
          coord = { map = 2444, x = 0.331, y = 0.364 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92607, text = "And Carve New Shapes (objective 2)",
          coord = { map = 2444, x = 0.286, y = 0.350 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92607, text = "Turn in: And Carve New Shapes", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2444, x = 0.333, y = 0.371 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91566, text = "Voidscar Arena: The Hate Spire (objective 2)", faction = "Horde",
          coord = { map = 2444, x = 0.238, y = 0.546 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91566, text = "Turn in: Voidscar Arena: The Hate Spire", rep = { { factionID = 2699, amount = 10 }, { factionID = 2770, amount = 40 } }, faction = "Horde",
          coord = { map = 2444, x = 0.235, y = 0.543 } },  -- APR route coord (converted)
        { type = "accept", questID = 94845, text = "Voidscar Arena: The Bastion of Might", faction = "Horde",
          coord = { map = 2444, x = 0.236, y = 0.542 } },  -- giver coord: ATT
        { type = "accept", questID = 94844, text = "Voidscar Arena: For My Horde", faction = "Horde",
          coord = { map = 2444, x = 0.236, y = 0.542 } },  -- giver coord: ATT
        { type = "quest",  questID = 94844, text = "Voidscar Arena: For My Horde (objective 1)", faction = "Horde", useItem = 266183,
          coord = { map = 2444, x = 0.357, y = 0.661 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94845, text = "Voidscar Arena: The Bastion of Might (objective 1)", faction = "Horde",
          coord = { map = 2444, x = 0.357, y = 0.661 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94845, text = "Turn in: Voidscar Arena: The Bastion of Might", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.589 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94844, text = "Turn in: Voidscar Arena: For My Horde", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.589 } },  -- APR route coord (converted)
        { type = "accept", questID = 94848, text = "Voidscar Arena: Pre-Provoked Violence", faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.590 } },  -- giver coord: ATT
        { type = "accept", questID = 94849, text = "Voidscar Arena: A Familiar Grudge", faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.590 } },  -- giver coord: ATT
        { type = "quest",  questID = 94849, text = "Voidscar Arena: A Familiar Grudge (objective 1)", faction = "Horde",
          coord = { map = 2444, x = 0.617, y = 0.846 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94848, text = "Voidscar Arena: Pre-Provoked Violence (objective 1)", faction = "Horde",
          coord = { map = 2444, x = 0.604, y = 0.736 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94848, text = "Turn in: Voidscar Arena: Pre-Provoked Violence", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.589 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94849, text = "Turn in: Voidscar Arena: A Familiar Grudge", rep = { { factionID = 2699, amount = 100 }, { factionID = 2770, amount = 400 } }, faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.589 } },  -- APR route coord (converted)
        { type = "accept", questID = 94855, text = "Voidscar Arena: Setting It Aside", faction = "Horde",
          coord = { map = 2444, x = 0.506, y = 0.590 } },  -- giver coord: ATT
        { type = "turnin", questID = 94855, text = "Turn in: Voidscar Arena: Setting It Aside", rep = { { factionID = 2699, amount = 10 }, { factionID = 2770, amount = 40 } }, faction = "Horde",
          coord = { map = 2444, x = 0.535, y = 0.215 } },  -- APR route coord (converted)
        { type = "accept", questID = 91603, text = "Voidscar Arena: Two Against One", faction = "Horde",
          coord = { map = 2444, x = 0.535, y = 0.215 } },  -- giver coord: ATT
        { type = "accept", questID = 91605, text = "Voidscar Arena: The Wrong Side", faction = "Horde",
          coord = { map = 2444, x = 0.537, y = 0.215 } },  -- giver coord: ATT
        { type = "quest",  questID = 91565, text = "Voidscar Arena: The Grief Spire (objective 2)", faction = "Alliance",
          coord = { map = 2444, x = 0.740, y = 0.754 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91565, text = "Turn in: Voidscar Arena: The Grief Spire", rep = { { factionID = 2699, amount = 10 }, { factionID = 2770, amount = 40 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.740, y = 0.754 } },  -- APR route coord (converted)
        { type = "accept", questID = 91597, text = "Voidscar Arena: For My Alliance", faction = "Alliance",
          coord = { map = 2444, x = 0.740, y = 0.756 } },  -- giver coord: ATT
        { type = "accept", questID = 91583, text = "Voidscar Arena: The Bastion of Valor", faction = "Alliance",
          coord = { map = 2444, x = 0.740, y = 0.756 } },  -- giver coord: ATT
        { type = "quest",  questID = 91583, text = "Voidscar Arena: The Bastion of Valor (objective 1)", faction = "Alliance",
          coord = { map = 2444, x = 0.653, y = 0.758 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91597, text = "Voidscar Arena: For My Alliance (objective 1)", faction = "Alliance", useItem = 260948,
          coord = { map = 2444, x = 0.653, y = 0.758 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91597, text = "Turn in: Voidscar Arena: For My Alliance", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.508, y = 0.587 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91583, text = "Turn in: Voidscar Arena: The Bastion of Valor", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.508, y = 0.587 } },  -- APR route coord (converted)
        { type = "accept", questID = 91598, text = "Voidscar Arena: Pre-Provoked Violence", faction = "Alliance",
          coord = { map = 2444, x = 0.509, y = 0.587 } },  -- giver coord: ATT
        { type = "accept", questID = 91599, text = "Voidscar Arena: A Familiar Grudge", faction = "Alliance",
          coord = { map = 2444, x = 0.509, y = 0.587 } },  -- giver coord: ATT
        { type = "quest",  questID = 91599, text = "Voidscar Arena: A Familiar Grudge (objective 1)", faction = "Alliance",
          coord = { map = 2444, x = 0.313, y = 0.699 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91598, text = "Voidscar Arena: Pre-Provoked Violence (objective 1)", faction = "Alliance",
          coord = { map = 2444, x = 0.359, y = 0.663 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91598, text = "Turn in: Voidscar Arena: Pre-Provoked Violence", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.508, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91599, text = "Turn in: Voidscar Arena: A Familiar Grudge", rep = { { factionID = 2699, amount = 100 }, { factionID = 2770, amount = 400 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.508, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 91600, text = "Voidscar Arena: Setting It Aside", faction = "Alliance",
          coord = { map = 2444, x = 0.509, y = 0.587 } },  -- giver coord: ATT
        { type = "turnin", questID = 91600, text = "Turn in: Voidscar Arena: Setting It Aside", rep = { { factionID = 2699, amount = 10 }, { factionID = 2770, amount = 40 } }, faction = "Alliance",
          coord = { map = 2444, x = 0.537, y = 0.215 } },  -- APR route coord (converted)
        { type = "accept", questID = 91605, text = "Voidscar Arena: The Wrong Side", faction = "Alliance",
          coord = { map = 2444, x = 0.537, y = 0.215 } },  -- giver coord: ATT
        { type = "accept", questID = 91603, text = "Voidscar Arena: Two Against One", faction = "Alliance",
          coord = { map = 2444, x = 0.535, y = 0.215 } },  -- giver coord: ATT
        { type = "quest",  questID = 91603, text = "Voidscar Arena: Two Against One (objective 2)",
          coord = { map = 2444, x = 0.567, y = 0.127 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [1/6]",
          coord = { map = 2444, x = 0.571, y = 0.132 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 3) [1/4]",
          coord = { map = 2444, x = 0.563, y = 0.128 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 3) [2/4]",
          coord = { map = 2444, x = 0.545, y = 0.129 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [2/6]",
          coord = { map = 2444, x = 0.541, y = 0.132 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [3/6]",
          coord = { map = 2444, x = 0.532, y = 0.133 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 3) [3/4]",
          coord = { map = 2444, x = 0.522, y = 0.132 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91603, text = "Voidscar Arena: Two Against One (objective 1)",
          coord = { map = 2444, x = 0.506, y = 0.126 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 3) [4/4]",
          coord = { map = 2444, x = 0.504, y = 0.128 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [4/6]",
          coord = { map = 2444, x = 0.504, y = 0.111 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [5/6]",
          coord = { map = 2444, x = 0.503, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 2) [6/6]",
          coord = { map = 2444, x = 0.524, y = 0.161 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91605, text = "Voidscar Arena: The Wrong Side (objective 1)",
          coord = { map = 2444, x = 0.528, y = 0.151 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91605, text = "Turn in: Voidscar Arena: The Wrong Side", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } },
          coord = { map = 2444, x = 0.538, y = 0.113 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91603, text = "Turn in: Voidscar Arena: Two Against One", rep = { { factionID = 2699, amount = 50 }, { factionID = 2770, amount = 200 } },
          coord = { map = 2444, x = 0.535, y = 0.113 } },  -- APR route coord (converted)
        { type = "accept", questID = 91606, text = "Voidscar Arena: Clearing House",
          coord = { map = 2444, x = 0.537, y = 0.113 } },  -- giver coord: ATT
        { type = "quest",  questID = 91606, text = "Voidscar Arena: Clearing House (objective 1)",
          coord = { map = 2444, x = 0.536, y = 0.067 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91606, text = "Voidscar Arena: Clearing House (objective 2)",
          coord = { map = 2444, x = 0.535, y = 0.113 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91606, text = "Turn in: Voidscar Arena: Clearing House", rep = { { factionID = 2699, amount = 100 }, { factionID = 2770, amount = 400 } },
          coord = { map = 2444, x = 0.535, y = 0.113 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90782, text = "Turn in: The Nethersent", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.399, y = 0.490 } },  -- APR route coord (converted)
        { type = "accept", questID = 90866, text = "Universal Language",
          coord = { map = 2405, x = 0.399, y = 0.490 } },  -- giver coord: ATT
        { type = "turnin", questID = 90848, text = "Turn in: She Started the Fire", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2444, x = 0.224, y = 0.997 } },  -- APR route coord (converted)
        { type = "accept", questID = 90851, text = "Eating Their Own",
          coord = { map = 2405, x = 0.377, y = 0.484 } },  -- giver coord: ATT
        { type = "accept", questID = 90852, text = "Techno-Magnetic Pulse",
          coord = { map = 2405, x = 0.377, y = 0.484 } },  -- giver coord: ATT
        { type = "quest",  questID = 90852, text = "Techno-Magnetic Pulse (objective 3)",
          coord = { map = 2444, x = 0.248, y = 0.957 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90852, text = "Techno-Magnetic Pulse (objective 1) [1/3]",
          coord = { map = 2444, x = 0.252, y = 0.959 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90852, text = "Techno-Magnetic Pulse (objective 1) [2/3]",
          coord = { map = 2444, x = 0.252, y = 0.925 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90852, text = "Techno-Magnetic Pulse (objective 1) [3/3]",
          coord = { map = 2444, x = 0.207, y = 0.937 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90852, text = "Techno-Magnetic Pulse (objective 2)",
          coord = { map = 2444, x = 0.205, y = 0.923 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90851, text = "Eating Their Own (objective 1)",
          coord = { map = 2444, x = 0.231, y = 0.942 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90851, text = "Turn in: Eating Their Own", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.193, y = 0.898 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90852, text = "Turn in: Techno-Magnetic Pulse", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.193, y = 0.898 } },  -- APR route coord (converted)
        { type = "accept", questID = 93396, text = "Bursting at the Seams",
          coord = { map = 2405, x = 0.363, y = 0.440 } },  -- giver coord: ATT
        { type = "quest",  questID = 93396, text = "Bursting at the Seams (objective 1)",
          coord = { map = 2444, x = 0.193, y = 0.898 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93396, text = "Turn in: Bursting at the Seams", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.193, y = 0.898 } },  -- APR route coord (converted)
        { type = "accept", questID = 90858, text = "Repress the Oppressors",
          coord = { map = 2405, x = 0.363, y = 0.440 } },  -- giver coord: ATT
        { type = "quest",  questID = 90858, text = "Repress the Oppressors (objective 1)",
          coord = { map = 2444, x = 0.176, y = 0.857 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90858, text = "Turn in: Repress the Oppressors", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.219, y = 0.797 } },  -- APR route coord (converted)
        { type = "accept", questID = 90860, text = "Shedding the Yoke",
          coord = { map = 2405, x = 0.374, y = 0.395 } },  -- giver coord: ATT
        { type = "quest",  questID = 90860, text = "Shedding the Yoke (objective 1)",
          coord = { map = 2444, x = 0.212, y = 0.753 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90866, text = "Universal Language (objective 1)",
          coord = { map = 2444, x = 0.292, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90866, text = "Turn in: Universal Language", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.262, y = 0.987 } },  -- APR route coord (converted)
        { type = "accept", questID = 90872, text = "Drenched In It",
          coord = { map = 2405, x = 0.394, y = 0.480 } },  -- giver coord: ATT
        { type = "quest",  questID = 90872, text = "Drenched In It (objective 1)",
          coord = { map = 2444, x = 0.259, y = 0.987 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90872, text = "Drenched In It (objective 2)",
          coord = { map = 2444, x = 0.261, y = 0.986 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90872, text = "Turn in: Drenched In It", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.351, y = 0.885 } },  -- APR route coord (converted)
        { type = "accept", questID = 90873, text = "These Violent Delights",
          coord = { map = 2444, x = 0.350, y = 0.887 } },  -- giver coord: ATT
        { type = "accept", questID = 90874, text = "Their Violent Ends",
          coord = { map = 2444, x = 0.350, y = 0.887 } },  -- giver coord: ATT
        { type = "quest",  questID = 90873, text = "These Violent Delights (objective 2) [1/3]",
          coord = { map = 2444, x = 0.329, y = 0.876 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90873, text = "These Violent Delights (objective 2) [2/3]",
          coord = { map = 2444, x = 0.374, y = 0.904 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90873, text = "These Violent Delights (objective 2) [3/3]",
          coord = { map = 2444, x = 0.415, y = 0.907 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90873, text = "These Violent Delights (objective 1)", useItem = 244173,
          coord = { map = 2444, x = 0.363, y = 0.866 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90874, text = "Their Violent Ends (objective 1)",
          coord = { map = 2444, x = 0.363, y = 0.866 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90873, text = "Turn in: These Violent Delights", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.351, y = 0.885 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90874, text = "Turn in: Their Violent Ends", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2444, x = 0.351, y = 0.885 } },  -- APR route coord (converted)
        { type = "accept", questID = 90875, text = "Across Worlds",
          coord = { map = 2444, x = 0.350, y = 0.887 } },  -- giver coord: ATT
        { type = "quest",  questID = 90875, text = "Across Worlds (objective 1)",
          coord = { map = 2444, x = 0.331, y = 0.811 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90875, text = "Across Worlds (objective 2)",
          coord = { map = 2405, x = 0.395, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90875, text = "Across Worlds (objective 3,4)",
          coord = { map = 2444, x = 0.261, y = 0.989 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90875, text = "Turn in: Across Worlds", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2444, x = 0.261, y = 0.989 } },  -- APR route coord (converted)
        -- (APR: grind/continue to level 90 before the next step)
        { type = "turnin", questID = 95276, text = "Turn in: The Last Push",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 92657, text = "The Brewing Storm",
          coord = { map = 2405, x = 0.360, y = 0.599 } },  -- giver coord: ATT
        { type = "turnin", questID = 92657, text = "Turn in: The Brewing Storm", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 2405, x = 0.263, y = 0.684 } },  -- APR route coord (converted)
        { type = "accept", questID = 92658, text = "Tactical Acquisition",
          coord = { map = 2405, x = 0.263, y = 0.684 } },  -- giver coord: ATT
        { type = "accept", questID = 92659, text = "Resource Denial",
          coord = { map = 2405, x = 0.263, y = 0.684 } },  -- giver coord: ATT
        { type = "quest",  questID = 92659, text = "Resource Denial (objective 1)",
          coord = { map = 2405, x = 0.301, y = 0.631 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92658, text = "Turn in: Tactical Acquisition", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.357, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92659, text = "Turn in: Resource Denial", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.357, y = 0.668 } },  -- APR route coord (converted)
        { type = "accept", questID = 92660, text = "Null Implements",
          coord = { map = 2405, x = 0.357, y = 0.668 } },  -- giver coord: ATT
        { type = "accept", questID = 92661, text = "Hammer Meet Anvil",
          coord = { map = 2405, x = 0.357, y = 0.669 } },  -- giver coord: ATT
        { type = "quest",  questID = 92660, text = "Null Implements (objective 1)",
          coord = { map = 2405, x = 0.335, y = 0.677 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92660, text = "Null Implements (objective 2)",
          coord = { map = 2405, x = 0.329, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92661, text = "Hammer Meet Anvil (objective 1)",
          coord = { map = 2405, x = 0.325, y = 0.706 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92660, text = "Null Implements (objective 3)",
          coord = { map = 2405, x = 0.323, y = 0.710 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92661, text = "Hammer Meet Anvil (objective 2)",
          coord = { map = 2405, x = 0.338, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92660, text = "Turn in: Null Implements", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.312, y = 0.683 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92661, text = "Turn in: Hammer Meet Anvil", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.312, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 92662, text = "Core Collapse",
          coord = { map = 2405, x = 0.312, y = 0.682 } },  -- giver coord: ATT
        { type = "quest",  questID = 92662, text = "Core Collapse (objective 1)",
          coord = { map = 2405, x = 0.316, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92662, text = "Core Collapse (objective 2)",
          coord = { map = 2405, x = 0.312, y = 0.682 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92662, text = "Core Collapse (objective 3)",
          coord = { map = 2405, x = 0.318, y = 0.695 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92662, text = "Turn in: Core Collapse", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.312, y = 0.682 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90860, text = "Turn in: Shedding the Yoke", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.510, y = 0.689 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90924, text = "The Wicked End (objective 3)",
          coord = { map = 2405, x = 0.512, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90924, text = "Turn in: The Wicked End", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.512, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 94623, text = "Building the Voidforge",
          coord = { map = 2405, x = 0.512, y = 0.684 } },  -- giver coord: ATT
        { type = "accept", questID = 91533, text = "What We Leave Behind",
          coord = { map = 2405, x = 0.537, y = 0.699 } },  -- giver coord: ATT
        { type = "quest",  questID = 91533, text = "What We Leave Behind (objective 1,2)",
          coord = { map = 2405, x = 0.537, y = 0.699 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91533, text = "Turn in: What We Leave Behind",
          coord = { map = 2405, x = 0.419, y = 0.748 } },  -- APR route coord (converted)
        { type = "accept", questID = 91535, text = "Home Sweet Grave",
          coord = { map = 2405, x = 0.418, y = 0.748 } },  -- giver coord: ATT
        { type = "accept", questID = 91536, text = "Like a Weed",
          coord = { map = 2405, x = 0.418, y = 0.748 } },  -- giver coord: ATT
        { type = "quest",  questID = 91535, text = "Home Sweet Grave (objective 1)",
          coord = { map = 2405, x = 0.432, y = 0.758 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91536, text = "Like a Weed (objective 1)",
          coord = { map = 2405, x = 0.433, y = 0.741 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91535, text = "Turn in: Home Sweet Grave",
          coord = { map = 2405, x = 0.419, y = 0.745 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91536, text = "Turn in: Like a Weed",
          coord = { map = 2405, x = 0.419, y = 0.745 } },  -- APR route coord (converted)
        { type = "accept", questID = 91537, text = "Confronting It",
          coord = { map = 2405, x = 0.419, y = 0.745 } },  -- giver coord: ATT
        { type = "quest",  questID = 91537, text = "Confronting It (objective 1)",
          coord = { map = 2405, x = 0.419, y = 0.746 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91537, text = "Confronting It (objective 2)",
          coord = { map = 2405, x = 0.396, y = 0.763 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91537, text = "Turn in: Confronting It",
          coord = { map = 2405, x = 0.419, y = 0.745 } },  -- APR route coord (converted)
        { type = "accept", questID = 91541, text = "Unchecked Emotions",
          coord = { map = 2405, x = 0.419, y = 0.745 } },  -- giver coord: ATT
        { type = "turnin", questID = 91541, text = "Turn in: Unchecked Emotions",
          coord = { map = 2405, x = 0.521, y = 0.696 } },  -- APR route coord (converted)
        { type = "accept", questID = 91542, text = "The Town Inside Me",
          coord = { map = 2405, x = 0.521, y = 0.696 } },  -- giver coord: ATT
        { type = "quest",  questID = 91542, text = "The Town Inside Me (objective 1)",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91542, text = "The Town Inside Me (objective 2)",
          coord = { map = 2405, x = 0.534, y = 0.703 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91542, text = "The Town Inside Me (objective 3)",
          coord = { map = 2405, x = 0.525, y = 0.727 } },  -- APR route coord (converted)
        { type = "accept", questID = 93970, text = "Researching the Storm",
          coord = { map = 2405, x = 0.526, y = 0.729 } },  -- giver coord: ATT
        { type = "quest",  questID = 93970, text = "Researching the Storm (objective 1)",
          coord = { map = 2405, x = 0.526, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93970, text = "Turn in: Researching the Storm", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.526, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91542, text = "Turn in: The Town Inside Me", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.624, y = 0.825 } },  -- APR route coord (converted)
        { type = "accept", questID = 91544, text = "Familiar Energies",
          coord = { map = 2405, x = 0.624, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 91543, text = "Retaking Control",
          coord = { map = 2405, x = 0.624, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 91963, text = "Running Amok",
          coord = { map = 2405, x = 0.624, y = 0.824 } },  -- giver coord: ATT
        { type = "quest",  questID = 91544, text = "Familiar Energies (objective 1)",
          coord = { map = 2405, x = 0.624, y = 0.825 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91544, text = "Familiar Energies (objective 2)",
          coord = { map = 2405, x = 0.611, y = 0.806 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91544, text = "Familiar Energies (objective 3)",
          coord = { map = 2405, x = 0.596, y = 0.791 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91544, text = "Familiar Energies (objective 4)",
          coord = { map = 2405, x = 0.594, y = 0.772 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91543, text = "Retaking Control (objective 2,1)", useItem = 248724,
          coord = { map = 2405, x = 0.603, y = 0.782 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91963, text = "Running Amok (objective 1)",
          coord = { map = 2405, x = 0.603, y = 0.782 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91544, text = "Familiar Energies (objective 5)",
          coord = { map = 2405, x = 0.585, y = 0.783 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91543, text = "Turn in: Retaking Control", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.582, y = 0.786 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91963, text = "Turn in: Running Amok", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.582, y = 0.786 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91544, text = "Turn in: Familiar Energies", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.582, y = 0.786 } },  -- APR route coord (converted)
        { type = "accept", questID = 91545, text = "Stronger Than Before",
          coord = { map = 2405, x = 0.582, y = 0.786 } },  -- giver coord: ATT
        { type = "quest",  questID = 91545, text = "Stronger Than Before (objective 1)",
          coord = { map = 2405, x = 0.582, y = 0.786 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91545, text = "Stronger Than Before (objective 2)",
          coord = { map = 2405, x = 0.572, y = 0.787 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91545, text = "Turn in: Stronger Than Before", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.521, y = 0.696 } },  -- APR route coord (converted)
        { type = "accept", questID = 91546, text = "To Be Changed",
          coord = { map = 2405, x = 0.520, y = 0.696 } },  -- giver coord: ATT
        { type = "quest",  questID = 91546, text = "To Be Changed (objective 1)",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "accept", questID = 92505, text = "Truth of the Past",
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 92505, text = "Truth of the Past (objective 1)",
          coord = { map = 2405, x = 0.532, y = 0.705 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92505, text = "Turn in: Truth of the Past", rep = { { factionID = 2699, amount = 10 } },
          coord = { map = 882, x = 0.529, y = 0.142 } },  -- APR route coord (converted)
        { type = "accept", questID = 92506, text = "The Soul Price",
          coord = { map = 882, x = 0.529, y = 0.142 } },  -- giver coord: ATT
        { type = "quest",  questID = 92506, text = "The Soul Price (objective 1)",
          coord = { map = 882, x = 0.511, y = 0.206 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92506, text = "Turn in: The Soul Price", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 882, x = 0.529, y = 0.142 } },  -- APR route coord (converted)
        { type = "accept", questID = 92507, text = "A More Potent Foe",
          coord = { map = 882, x = 0.529, y = 0.142 } },  -- giver coord: ATT
        { type = "quest",  questID = 92507, text = "A More Potent Foe (objective 1)",
          coord = { map = 882, x = 0.529, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92507, text = "A More Potent Foe (objective 2)",
          coord = { map = 882, x = 0.533, y = 0.134 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92507, text = "Turn in: A More Potent Foe", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 92508, text = "The Mark of Sacrifice",
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- giver coord: ATT
        { type = "accept", questID = 92509, text = "One Cruel Implement",
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 92508, text = "The Mark of Sacrifice (objective 1)",
          coord = { map = 2405, x = 0.312, y = 0.528 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92509, text = "One Cruel Implement (objective 1)",
          coord = { map = 2405, x = 0.312, y = 0.528 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92508, text = "The Mark of Sacrifice (objective 2)",
          coord = { map = 2405, x = 0.292, y = 0.519 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92509, text = "One Cruel Implement (objective 2)",
          coord = { map = 2405, x = 0.292, y = 0.519 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92508, text = "Turn in: The Mark of Sacrifice", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92509, text = "Turn in: One Cruel Implement", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 92510, text = "Dark Infusion",
          coord = { map = 2405, x = 0.532, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 92510, text = "Dark Infusion (objective 1)",
          coord = { map = 2444, x = 0.727, y = 0.900 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92510, text = "Dark Infusion (objective 2)",
          coord = { map = 2444, x = 0.727, y = 0.901 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92510, text = "Dark Infusion (objective 3)",
          coord = { map = 2444, x = 0.728, y = 0.899 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92510, text = "Dark Infusion (objective 4)",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92510, text = "Turn in: Dark Infusion", rep = { { factionID = 2699, amount = 100 } },
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "accept", questID = 92511, text = "Event Horizon",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- giver coord: ATT
        { type = "quest",  questID = 92511, text = "Event Horizon (objective 2)",
          coord = { map = 2405, x = 0.539, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92511, text = "Event Horizon (objective 3)",
          coord = { map = 2405, x = 0.521, y = 0.733 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92511, text = "Event Horizon (objective 1)",
          coord = { map = 2405, x = 0.519, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92511, text = "Event Horizon (objective 4)",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92511, text = "Event Horizon (objective 5)",
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92511, text = "Turn in: Event Horizon", rep = { { factionID = 2699, amount = 50 } },
          coord = { map = 2405, x = 0.521, y = 0.696 } },  -- APR route coord (converted)
        { type = "accept", questID = 92512, text = "Devourer",
          coord = { map = 2405, x = 0.521, y = 0.696 } },  -- giver coord: ATT
        { type = "quest",  questID = 92512, text = "Devourer (objective 1)",
          coord = { map = 2405, x = 0.511, y = 0.561 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92512, text = "Devourer (objective 2)",
          coord = { map = 2405, x = 0.515, y = 0.558 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92512, text = "Devourer (objective 3)",
          coord = { map = 2405, x = 0.522, y = 0.696 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92512, text = "Turn in: Devourer", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2405, x = 0.522, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91546, text = "To Be Changed (objective 2)",
          coord = { map = 2393, x = 0.323, y = 0.873 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91546, text = "Turn in: To Be Changed", rep = { { factionID = 2699, amount = 250 } },
          coord = { map = 2393, x = 0.316, y = 0.880 } },  -- APR route coord (converted)
    },
}
