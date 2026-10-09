-- ToonAge guide data: Midnight: Intro (Stormwind/Orgrimmar -> Quel'Thalas)
-- Kind: campaign intro (level 80; skipped if warband has achievement 42045)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2432-Midnight-Intro"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 18 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 0 accept steps where ATT and converted APR coords share a map: median 0.00, p90 0.00, max 0.00 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 85 Orgrimmar, 2424 Isle of Quel'Danas, 2537 Quel'Thalas, 2565 Isle of Quel'Danas, 2566 Isle of Quel'Danas


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_intro"] = {
    id = "midnight_intro", title = "Midnight: Intro (Stormwind/Orgrimmar -> Quel'Thalas)", expansion = "midnight",
    zone = 2537, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_eversong_campaign",
    steps = {
        { type = "accept", questID = 91281, text = "Midnight",
          coord = { map = 85, x = 0.530, y = 0.775 } },  -- giver coord: ATT
        { type = "quest",  questID = 91281, text = "Midnight (objective 1)", faction = "Horde",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91281, text = "Turn in: Midnight", faction = "Horde",
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 88719, text = "A Voice from the Light", faction = "Horde",
          coord = { map = 85, x = 0.530, y = 0.775 } },  -- giver coord: ATT
        { type = "quest",  questID = 88719, text = "A Voice from the Light (objective 1)", faction = "Horde", useItem = 239151,
          coord = nil },  -- no coord: APR step has none
        { type = "quest",  questID = 91281, text = "Midnight (objective 1)", faction = "Alliance",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91281, text = "Turn in: Midnight", faction = "Alliance",
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 88719, text = "A Voice from the Light", faction = "Alliance",
          coord = { map = 85, x = 0.530, y = 0.775 } },  -- giver coord: ATT
        { type = "quest",  questID = 88719, text = "A Voice from the Light (objective 1)", faction = "Alliance", useItem = 239151,
          coord = nil },  -- no coord: APR step has none
        { type = "quest",  questID = 88719, text = "A Voice from the Light (objective 2)", useItem = 239151,
          coord = { map = 2537, x = 0.264, y = 0.132 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88719, text = "Turn in: A Voice from the Light",
          coord = { map = 2537, x = 0.262, y = 0.129 } },  -- APR route coord (converted)
        { type = "accept", questID = 86769, text = "Last Bastion of the Light",
          coord = { map = 2537, x = 0.262, y = 0.129 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86769, text = "Turn in: Last Bastion of the Light",
          coord = { map = 2537, x = 0.257, y = 0.142 } },  -- APR route coord (converted)
        { type = "accept", questID = 86770, text = "Champions of Quel'Danas",
          coord = { map = 2537, x = 0.257, y = 0.142 } },  -- APR route coord (converted)
        { type = "accept", questID = 86780, text = "Where Heroes Hold",
          coord = { map = 2537, x = 0.257, y = 0.142 } },  -- APR route coord (converted)
        { type = "accept", questID = 89271, text = "My Son",
          coord = { map = 2537, x = 0.257, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86770, text = "Champions of Quel'Danas (objective 1)",
          coord = { map = 2537, x = 0.255, y = 0.129 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89271, text = "My Son (objective 1)",
          coord = { map = 2537, x = 0.253, y = 0.157 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86770, text = "Champions of Quel'Danas (objective 2)",
          coord = { map = 2537, x = 0.249, y = 0.155 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86780, text = "Where Heroes Hold (objective 1)",
          coord = { map = 2537, x = 0.254, y = 0.152 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86770, text = "Champions of Quel'Danas (objective 3)",
          coord = { map = 2537, x = 0.248, y = 0.142 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86770, text = "Turn in: Champions of Quel'Danas",
          coord = { map = 2537, x = 0.235, y = 0.141 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86780, text = "Turn in: Where Heroes Hold",
          coord = { map = 2537, x = 0.235, y = 0.141 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89271, text = "Turn in: My Son",
          coord = { map = 2537, x = 0.235, y = 0.141 } },  -- APR route coord (converted)
        { type = "accept", questID = 86805, text = "The Hour of Need",
          coord = { map = 2537, x = 0.235, y = 0.141 } },  -- APR route coord (converted)
        { type = "accept", questID = 89012, text = "A Safe Path",
          coord = { map = 2537, x = 0.235, y = 0.141 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89012, text = "A Safe Path (objective 1)",
          coord = { map = 2537, x = 0.248, y = 0.152 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86805, text = "The Hour of Need (objective 1)", useItem = 248239,
          coord = { map = 2537, x = 0.242, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86805, text = "The Hour of Need (objective 2)",
          coord = { map = 2537, x = 0.247, y = 0.157 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86805, text = "Turn in: The Hour of Need",
          coord = { map = 2537, x = 0.247, y = 0.168 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89012, text = "Turn in: A Safe Path",
          coord = { map = 2537, x = 0.247, y = 0.168 } },  -- APR route coord (converted)
        { type = "accept", questID = 86806, text = "Luminous Wings",
          coord = { map = 2537, x = 0.247, y = 0.168 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86806, text = "Luminous Wings (objective 1)",
          coord = { map = 2537, x = 0.247, y = 0.170 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86806, text = "Luminous Wings (objective 3) [1/3]",
          coord = { map = 2537, x = 0.237, y = 0.190 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86806, text = "Luminous Wings (objective 3) [2/3]",
          coord = { map = 2537, x = 0.222, y = 0.196 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86806, text = "Luminous Wings (objective 3) [3/3]",
          coord = { map = 2537, x = 0.221, y = 0.208 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86806, text = "Luminous Wings (objective 2)",
          coord = { map = 2537, x = 0.240, y = 0.194 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86806, text = "Turn in: Luminous Wings",
          coord = { map = 2537, x = 0.247, y = 0.168 } },  -- APR route coord (converted)
        { type = "accept", questID = 86807, text = "The Gate",
          coord = { map = 2537, x = 0.247, y = 0.167 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86807, text = "The Gate (objective 1)",
          coord = { map = 2537, x = 0.247, y = 0.131 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86807, text = "Turn in: The Gate",
          coord = { map = 2537, x = 0.247, y = 0.131 } },  -- APR route coord (converted)
        { type = "accept", questID = 91274, text = "Severing the Void",
          coord = { map = 2565, x = 0.497, y = 0.214 } },  -- giver coord: ATT
        { type = "accept", questID = 86834, text = "Voidborn Banishing",
          coord = { map = 2565, x = 0.497, y = 0.214 } },  -- giver coord: ATT
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 1) [1/5]",
          coord = { map = 2537, x = 0.250, y = 0.124 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 1) [2/5]",
          coord = { map = 2537, x = 0.254, y = 0.123 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86834, text = "Voidborn Banishing (objective 2)",
          coord = { map = 2537, x = 0.258, y = 0.120 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 1) [3/5]",
          coord = { map = 2537, x = 0.251, y = 0.111 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86834, text = "Voidborn Banishing (objective 1)",
          coord = { map = 2537, x = 0.250, y = 0.109 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 2) [4/5]",
          coord = { map = 2537, x = 0.249, y = 0.103 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 1) [4/5]",
          coord = { map = 2537, x = 0.249, y = 0.103 } },  -- APR route coord (converted)
        { type = "accept", questID = 90849, text = "Light Show",
          coord = { map = 2537, x = 0.242, y = 0.104 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [1/6]",
          coord = { map = 2537, x = 0.239, y = 0.095 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [2/6]",
          coord = { map = 2537, x = 0.243, y = 0.098 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [3/6]",
          coord = { map = 2537, x = 0.244, y = 0.096 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [4/6]",
          coord = { map = 2537, x = 0.242, y = 0.102 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [5/6]",
          coord = { map = 2537, x = 0.241, y = 0.104 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 2) [6/6]",
          coord = { map = 2537, x = 0.237, y = 0.104 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90849, text = "Light Show (objective 1)",
          coord = { map = 2537, x = 0.240, y = 0.096 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90849, text = "Turn in: Light Show",
          coord = { map = 2537, x = 0.237, y = 0.104 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86834, text = "Voidborn Banishing (objective 3)",
          coord = { map = 2537, x = 0.238, y = 0.111 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91274, text = "Severing the Void (objective 1) [5/5]",
          coord = { map = 2537, x = 0.242, y = 0.116 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91274, text = "Turn in: Severing the Void",
          coord = { map = 2537, x = 0.256, y = 0.106 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86834, text = "Turn in: Voidborn Banishing",
          coord = { map = 2537, x = 0.256, y = 0.106 } },  -- APR route coord (converted)
        { type = "accept", questID = 86811, text = "Ethereal Eradication",
          coord = { map = 2537, x = 0.256, y = 0.106 } },  -- APR route coord (converted)
        { type = "accept", questID = 86848, text = "Light's Arsenal",
          coord = { map = 2537, x = 0.255, y = 0.106 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86811, text = "Ethereal Eradication (objective 2)",
          coord = { map = 2537, x = 0.264, y = 0.097 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [1/7]",
          coord = { map = 2537, x = 0.263, y = 0.098 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [2/7]",
          coord = { map = 2537, x = 0.261, y = 0.109 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [3/7]",
          coord = { map = 2537, x = 0.260, y = 0.110 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [4/7]",
          coord = { map = 2537, x = 0.261, y = 0.110 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [5/7]",
          coord = { map = 2537, x = 0.260, y = 0.109 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [6/7]",
          coord = { map = 2537, x = 0.254, y = 0.100 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86848, text = "Light's Arsenal (objective 1) [7/7]",
          coord = { map = 2537, x = 0.255, y = 0.099 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86811, text = "Ethereal Eradication (objective 1)",
          coord = { map = 2537, x = 0.261, y = 0.103 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86848, text = "Turn in: Light's Arsenal",
          coord = { map = 2537, x = 0.255, y = 0.106 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86811, text = "Turn in: Ethereal Eradication",
          coord = { map = 2537, x = 0.256, y = 0.106 } },  -- APR route coord (converted)
        { type = "accept", questID = 86849, text = "Wrath Unleashed",
          coord = { map = 2537, x = 0.256, y = 0.106 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86849, text = "Wrath Unleashed (objective 1)",
          coord = { map = 2537, x = 0.256, y = 0.073 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86849, text = "Wrath Unleashed (objective 2,3)",
          coord = { map = 2537, x = 0.256, y = 0.073 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86849, text = "Turn in: Wrath Unleashed",
          coord = { map = 2537, x = 0.257, y = 0.074 } },  -- APR route coord (converted)
        { type = "accept", questID = 86850, text = "Broken Sun",
          coord = { map = 2537, x = 0.257, y = 0.074 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86850, text = "Broken Sun (objective 1)",
          coord = { map = 2537, x = 0.244, y = 0.084 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86850, text = "Broken Sun (objective 2)",
          coord = { map = 2537, x = 0.268, y = 0.167 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86850, text = "Turn in: Broken Sun",
          coord = { map = 2537, x = 0.271, y = 0.153 } },  -- APR route coord (converted)
        { type = "accept", questID = 86852, text = "Light's Last Stand",
          coord = { map = 2566, x = 0.518, y = 0.813 } },  -- giver coord: ATT
        { type = "quest",  questID = 86852, text = "Light's Last Stand (objective 1)",
          coord = { map = 2537, x = 0.271, y = 0.153 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86852, text = "Light's Last Stand (objective 2)",
          coord = { map = 2537, x = 0.271, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86852, text = "Light's Last Stand (objective 4)",
          coord = { map = 2537, x = 0.271, y = 0.137 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86852, text = "Turn in: Light's Last Stand", rep = { { factionID = 2710, amount = 500 } },
          coord = { map = 2424, x = 0.527, y = 0.882 } },  -- APR route coord (converted)
    },
}
