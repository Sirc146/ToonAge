-- ToonAge guide data: Midnight: Haranir allied race starting experience
-- Kind: race start (Race = Haranir)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2413-Midnight-Haranir-Start"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 7 quest IDs resolved.
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
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 84 Stormwind City, 85 Orgrimmar, 2413 Harandar


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_haranir_start"] = {
    id = "midnight_haranir_start", title = "Midnight: Haranir allied race starting experience", expansion = "midnight",
    zone = 2413, minLevel = 80, maxLevel = 90,
    nextGuide = nil,
    steps = {
        { type = "accept", questID = 90957, text = "Initiation Day",
          coord = { map = 2413, x = 0.348, y = 0.249 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90957, text = "Initiation Day (objective 1)",
          coord = { map = 2413, x = 0.367, y = 0.246 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90957, text = "Turn in: Initiation Day",
          coord = { map = 2413, x = 0.353, y = 0.233 } },  -- APR route coord (converted)
        { type = "accept", questID = 90958, text = "Roots Above All",
          coord = { map = 2413, x = 0.353, y = 0.233 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90958, text = "Roots Above All (objective 1)",
          coord = { map = 2413, x = 0.357, y = 0.234 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90958, text = "Roots Above All (objective 2)",
          coord = { map = 2413, x = 0.366, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90958, text = "Turn in: Roots Above All",
          coord = { map = 2413, x = 0.353, y = 0.233 } },  -- APR route coord (converted)
        { type = "accept", questID = 90959, text = "Traditional Duties",
          coord = { map = 2413, x = 0.353, y = 0.235 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90959, text = "Traditional Duties (objective 1)",
          coord = { map = 2413, x = 0.354, y = 0.234 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90959, text = "Traditional Duties (objective 2)",
          coord = { map = 2413, x = 0.354, y = 0.273 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90959, text = "Traditional Duties (objective 3)",
          coord = { map = 2413, x = 0.356, y = 0.278 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90959, text = "Traditional Duties (objective 4)",
          coord = { map = 2413, x = 0.356, y = 0.280 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90959, text = "Turn in: Traditional Duties",
          coord = { map = 2413, x = 0.340, y = 0.269 } },  -- APR route coord (converted)
        { type = "accept", questID = 90960, text = "My Story, My Legacy",
          coord = { map = 2413, x = 0.340, y = 0.269 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 1)",
          coord = { map = 2413, x = 0.336, y = 0.282 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 2)",
          coord = { map = 2413, x = 0.336, y = 0.282 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 3)",
          coord = { map = 2413, x = 0.333, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 4)",
          coord = { map = 2413, x = 0.333, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 5)",
          coord = { map = 2413, x = 0.324, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 6)",
          coord = { map = 2413, x = 0.319, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90960, text = "My Story, My Legacy (objective 7)",
          coord = { map = 2413, x = 0.319, y = 0.275 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90960, text = "Turn in: My Story, My Legacy",
          coord = { map = 2413, x = 0.319, y = 0.274 } },  -- APR route coord (converted)
        { type = "accept", questID = 90961, text = "Stranger in a New Land",
          coord = { map = 2413, x = 0.319, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90961, text = "Stranger in a New Land (objective 1)",
          coord = { map = 2413, x = 0.319, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90961, text = "Stranger in a New Land (objective 2)",
          coord = { map = 2413, x = 0.318, y = 0.274 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90961, text = "Turn in: Stranger in a New Land", faction = "Alliance",
          coord = { map = 84, x = 0.530, y = 0.153 } },  -- APR route coord (converted)
        { type = "accept", questID = 94445, text = "Choose a Path", faction = "Alliance",
          coord = { map = 84, x = 0.530, y = 0.153 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94445, text = "Choose a Path (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.562, y = 0.173 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94445, text = "Turn in: Choose a Path", faction = "Alliance",
          coord = { map = 84, x = 0.538, y = 0.124 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90961, text = "Turn in: Stranger in a New Land", faction = "Horde",
          coord = { map = 85, x = 0.394, y = 0.795 } },  -- APR route coord (converted)
        { type = "accept", questID = 94444, text = "Choose a Path", faction = "Horde",
          coord = { map = 85, x = 0.394, y = 0.795 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94444, text = "Choose a Path (objective 1)", faction = "Horde",
          coord = { map = 85, x = 0.408, y = 0.802 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94444, text = "Turn in: Choose a Path", faction = "Horde",
          coord = { map = 85, x = 0.401, y = 0.794 } },  -- APR route coord (converted)
    },
}
