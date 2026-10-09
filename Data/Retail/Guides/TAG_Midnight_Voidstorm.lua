-- ToonAge guide data: Midnight (12.x) Voidstorm: MAIN CAMPAIGN storyline only (+ optional 'The Darkening Sky' prologue as a 2nd guide)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Midnight leveling 80-90.
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Voidstorm-Campaign-Only + 2395-The-Darkening-Sky"
--    in Routes/Midnight/Midnight-Voidstorm.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 41 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 40 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.07, max 0.27 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (2 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: campaign only.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2405 Voidstorm, 2424 Isle of Quel'Danas
--  * Voidstorm = uiMap 2405 (instance map 2771); Slayer's Rise = 2444.
--  * 86528 "A Cracked Holokey" has no PickUp in APR: it starts from the Cracked Holokey item (241000) / object 504349 (ATT).
--    An accept step was added at the ATT coord (UNVERIFIED placement).
--  * Second guide midnight_darkening_sky = APR route "2395-The-Darkening-Sky" (Eversong/Silvermoon, 2 quests). APR only chains it from
--    the Zul'Aman sojourner route, not the campaign-only chain, so it is optional here (UNVERIFIED whether required).

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_voidstorm_campaign"] = {
    id = "midnight_voidstorm_campaign", title = "Midnight: Voidstorm (Campaign)", expansion = "midnight",
    zone = 2405, minLevel = 80, maxLevel = 90, order = 40,
    nextGuide = nil, -- APR continues with The War of Light and Shadow (level 90) or Arator's Journey
    steps = {
        -- (APR: grind/continue to level 88 before the next step - skipped when the warband has achievement 42045)
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
          coord = nil, noArrow = true },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 86543, text = "Turn in: Magisters' Terrace: Homecoming",
          coord = { map = 2393, x = 0.351, y = 0.658 } },  -- APR route coord (converted)
        { type = "accept", questID = 86549, text = "No Fear of the Dark",
          coord = { map = 2393, x = 0.352, y = 0.658 } },  -- giver coord: ATT
        { type = "quest",  questID = 86549, text = "No Fear of the Dark (objective 1)",
          coord = { map = 2393, x = 0.353, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86549, text = "No Fear of the Dark (objective 3)",
          coord = { map = 2393, x = 0.353, y = 0.661 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86549, text = "Turn in: No Fear of the Dark",
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
        { type = "turnin", questID = 86557, text = "Turn in: A Matter of Strife and Death",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86558, text = "Turn in: Save a Piece of Mind",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 86559, text = "The Far, Far Frontier",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- giver coord: ATT
        { type = "quest",  questID = 86559, text = "The Far, Far Frontier (objective 1)",
          coord = { map = 2405, x = 0.370, y = 0.586 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86559, text = "The Far, Far Frontier (objective 2)",
          coord = { map = 2405, x = 0.369, y = 0.587 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86559, text = "Turn in: The Far, Far Frontier",
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
        { type = "turnin", questID = 86562, text = "Turn in: Dancing with Death",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86561, text = "Turn in: A Strange, Different World",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 86565, text = "No Prayer for the Wicked",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- giver coord: ATT
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 1)",
          coord = { map = 2405, x = 0.274, y = 0.510 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 2)",
          coord = { map = 2405, x = 0.262, y = 0.515 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86565, text = "No Prayer for the Wicked (objective 3)",
          coord = { map = 2405, x = 0.265, y = 0.511 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86565, text = "Turn in: No Prayer for the Wicked",
          coord = { map = 2405, x = 0.354, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 86536, text = "Reliable Enemies",
          coord = { map = 2405, x = 0.354, y = 0.591 } },  -- giver coord: ATT
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 1)",
          coord = { map = 2405, x = 0.354, y = 0.590 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 2)",
          coord = { map = 2405, x = 0.366, y = 0.730 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86536, text = "Reliable Enemies (objective 3)",
          coord = { map = 2405, x = 0.367, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86536, text = "Turn in: Reliable Enemies",
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
        { type = "turnin", questID = 86531, text = "Turn in: Work Disruption",
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "accept",  questID = 86528, text = "A Cracked Holokey", estimated = true,
          coord = { map = 2405, x = 0.357, y = 0.792 } },  -- starts from Cracked Holokey (item 241000 / object 504349) per ATT; no APR PickUp - UNVERIFIED placement
        { type = "turnin", questID = 86528, text = "Turn in: A Cracked Holokey",
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86530, text = "Turn in: First, The Shells",
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
        { type = "turnin", questID = 86537, text = "Turn in: Network Insecurity",
          coord = { map = 2405, x = 0.363, y = 0.804 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86538, text = "Turn in: Second, The Fuel",
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- APR route coord (converted)
        { type = "accept", questID = 86539, text = "A Naaru!",
          coord = { map = 2405, x = 0.363, y = 0.806 } },  -- giver coord: ATT
        { type = "turnin", questID = 86539, text = "Turn in: A Naaru!",
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
        { type = "turnin", questID = 88768, text = "Turn in: Agents of Darkness",
          coord = { map = 2405, x = 0.380, y = 0.834 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86540, text = "Turn in: Third, Blow It Up",
          coord = { map = 2405, x = 0.380, y = 0.832 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86541, text = "Turn in: Just In Case...",
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
        { type = "turnin", questID = 86542, text = "Turn in: Flicker in the Dark",
          coord = { map = 2405, x = 0.416, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 89249, text = "Overwhelmed",
          coord = { map = 2405, x = 0.416, y = 0.788 } },  -- giver coord: ATT
        { type = "turnin", questID = 89249, text = "Turn in: Overwhelmed",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86544, text = "Post-Mortem",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 2)",
          coord = { map = 2405, x = 0.418, y = 0.748 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86544, text = "Post-Mortem (objective 4) [1/3]",
          coord = { map = 2405, x = 0.417, y = 0.746 } },  -- APR route coord (converted)
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
        { type = "turnin", questID = 86544, text = "Turn in: Post-Mortem",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86545, text = "The Light's Brand",
          coord = { map = 2405, x = 0.417, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 1)",
          coord = { map = 2405, x = 0.412, y = 0.726 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 3)",
          coord = { map = 2405, x = 0.410, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86545, text = "The Light's Brand (objective 4)",
          coord = { map = 2405, x = 0.412, y = 0.727 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86545, text = "Turn in: The Light's Brand",
          coord = { map = 2405, x = 0.411, y = 0.727 } },  -- APR route coord (converted)
        { type = "accept", questID = 86509, text = "Friend or Fiend",
          coord = { map = 2405, x = 0.412, y = 0.727 } },  -- giver coord: ATT
        { type = "quest",  questID = 86509, text = "Friend or Fiend (objective 1)",
          coord = { map = 2405, x = 0.513, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86509, text = "Turn in: Friend or Fiend",
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
        { type = "turnin", questID = 86510, text = "Turn in: Domus Penumbra",
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- APR route coord (converted)
        { type = "accept", questID = 90571, text = "The Lay of the Beast",
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- giver coord: ATT
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [1/3]",
          coord = { map = 2405, x = 0.475, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [2/3]",
          coord = { map = 2405, x = 0.494, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90571, text = "The Lay of the Beast (objective 2) [3/3]",
          coord = { map = 2405, x = 0.514, y = 0.560 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90571, text = "Turn in: The Lay of the Beast",
          coord = { map = 2405, x = 0.510, y = 0.679 } },  -- APR route coord (converted)
        { type = "accept", questID = 86511, text = "Edge of the Abyss",
          coord = { map = 2405, x = 0.511, y = 0.680 } },  -- giver coord: ATT
        { type = "quest",  questID = 86511, text = "Edge of the Abyss (objective 1)",
          coord = { map = 2405, x = 0.544, y = 0.743 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86511, text = "Turn in: Edge of the Abyss",
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
        { type = "turnin", questID = 86513, text = "Turn in: Face the Tide",
          coord = { map = 2405, x = 0.556, y = 0.727 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86512, text = "Turn in: The Harvest",
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
        { type = "turnin", questID = 86514, text = "Turn in: Lady of the Pit",
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
        { type = "turnin", questID = 86517, text = "Turn in: Vanished in the Void",
          coord = { map = 2405, x = 0.608, y = 0.737 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86515, text = "Turn in: Hollow Hunger",
          coord = { map = 2405, x = 0.607, y = 0.736 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86516, text = "Turn in: All Become Prey",
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
        { type = "turnin", questID = 86518, text = "Turn in: The Mantle of Predation",
          coord = { map = 2405, x = 0.603, y = 0.764 } },  -- APR route coord (converted)
        { type = "accept", questID = 86519, text = "Abyssus, Abyssum",
          coord = { map = 2405, x = 0.603, y = 0.764 } },  -- giver coord: ATT
        { type = "quest",  questID = 86519, text = "Abyssus, Abyssum (objective 1)",
          coord = { map = 2405, x = 0.606, y = 0.766 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86519, text = "Abyssus, Abyssum (objective 2)",
          coord = { map = 2405, x = 0.609, y = 0.769 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86519, text = "Turn in: Abyssus, Abyssum",
          coord = { map = 2405, x = 0.601, y = 0.762 } },  -- APR route coord (converted)
        { type = "accept", questID = 86520, text = "Hunt the Light",
          coord = { map = 2405, x = 0.601, y = 0.762 } },  -- giver coord: ATT
        { type = "quest",  questID = 86520, text = "Hunt the Light (objective 1)",
          coord = { map = 2405, x = 0.639, y = 0.617 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86520, text = "Turn in: Hunt the Light",
          coord = { map = 2405, x = 0.641, y = 0.618 } },  -- APR route coord (converted)
        { type = "accept", questID = 86521, text = "Nexus-Point Xenas: Eclipse",
          coord = { map = 2405, x = 0.641, y = 0.618 } },  -- giver coord: ATT
        { type = "quest",  questID = 86521, text = "Nexus-Point Xenas: Eclipse (objective 3)",
          coord = nil, noArrow = true },  -- no coord: APR step has none
        { type = "quest",  questID = 86521, text = "Nexus-Point Xenas: Eclipse (objective 4)",
          coord = { map = 2405, x = 0.459, y = 0.646 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86521, text = "Turn in: Nexus-Point Xenas: Eclipse",
          coord = { map = 2405, x = 0.460, y = 0.646 } },  -- APR route coord (converted)
        { type = "accept", questID = 86522, text = "Daylight is Breaking",
          coord = { map = 2405, x = 0.460, y = 0.646 } },  -- giver coord: ATT
        { type = "turnin", questID = 86522, text = "Turn in: Daylight is Breaking",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 95276, text = "The Last Push",
          coord = { map = 2393, x = 0.454, y = 0.706 } },  -- giver coord: ATT
        -- (APR: grind/continue to level 90 before the next step)
        { type = "turnin", questID = 95276, text = "Turn in: The Last Push",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}

TA.GuideData["midnight_darkening_sky"] = {
    id = "midnight_darkening_sky", title = "Midnight: The Darkening Sky (optional)", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90, order = 35, optional = true,
    nextGuide = "midnight_voidstorm_campaign",
    steps = {
        { type = "accept", questID = 91854, text = "Deepening Shadows",
          coord = { map = 2393, x = 0.454, y = 0.702 } },  -- giver coord: ATT
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 3) [1/5]",
          coord = { map = 2393, x = 0.448, y = 0.619 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 3) [2/5]",
          coord = { map = 2393, x = 0.439, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 3) [3/5]",
          coord = { map = 2393, x = 0.456, y = 0.580 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 3) [4/5]",
          coord = { map = 2393, x = 0.465, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 1)",
          coord = { map = 2393, x = 0.472, y = 0.593 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 3) [5/5]",
          coord = { map = 2393, x = 0.482, y = 0.613 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91854, text = "Deepening Shadows (objective 2)",
          coord = { map = 2393, x = 0.458, y = 0.816 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91854, text = "Turn in: Deepening Shadows",
          coord = { map = 2393, x = 0.454, y = 0.701 } },  -- APR route coord (converted)
        { type = "accept", questID = 91967, text = "You Know This Evil?",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 1)",
          coord = { map = 2393, x = 0.455, y = 0.366 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 2)",
          coord = { map = 2393, x = 0.455, y = 0.360 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 3)",
          coord = { map = 2393, x = 0.457, y = 0.361 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 4)",
          coord = { map = 2393, x = 0.458, y = 0.363 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 5)",
          coord = { map = 2393, x = 0.456, y = 0.364 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91967, text = "You Know This Evil? (objective 6)",
          coord = { map = 2393, x = 0.455, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91967, text = "Turn in: You Know This Evil?",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}
