-- ToonAge guide data: Midnight: Crimson Rogue
-- Kind: APR side chain (Zul'Aman/Eversong)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2393-Midnight-Crimson-Rogue"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 11 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 10 accept steps where ATT and converted APR coords share a map: median 0.03, p90 0.06, max 0.06 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2437 Zul'Aman


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_crimson_rogue"] = {
    id = "midnight_crimson_rogue", title = "Midnight: Crimson Rogue", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90,
    nextGuide = nil,
    steps = {
        { type = "accept", questID = 91822, text = "The Regent's Request",
          coord = { map = 2393, x = 0.525, y = 0.783 } },  -- giver coord: ATT
        { type = "quest",  questID = 91822, text = "The Regent's Request (objective 1)",
          coord = { map = 2393, x = 0.336, y = 0.360 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91822, text = "Turn in: The Regent's Request",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 91823, text = "Lines Cut, Tongues Silenced",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- giver coord: ATT
        { type = "accept", questID = 91824, text = "The Thieves' Trail",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- giver coord: ATT
        { type = "accept", questID = 91825, text = "Dead Men Keep No Secrets",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- giver coord: ATT
        { type = "quest",  questID = 91823, text = "Lines Cut, Tongues Silenced (objective 1) [1/4]",
          coord = { map = 2395, x = 0.628, y = 0.698 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91825, text = "Dead Men Keep No Secrets (objective 1)",
          coord = { map = 2395, x = 0.631, y = 0.707 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91823, text = "Lines Cut, Tongues Silenced (objective 1) [2/4]",
          coord = { map = 2395, x = 0.631, y = 0.707 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91823, text = "Lines Cut, Tongues Silenced (objective 1) [3/4]",
          coord = { map = 2395, x = 0.626, y = 0.712 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91823, text = "Lines Cut, Tongues Silenced (objective 1) [4/4]",
          coord = { map = 2395, x = 0.620, y = 0.706 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91824, text = "The Thieves' Trail (objective 1)",
          coord = { map = 2395, x = 0.622, y = 0.705 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91823, text = "Turn in: Lines Cut, Tongues Silenced",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91824, text = "Turn in: The Thieves' Trail",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91825, text = "Turn in: Dead Men Keep No Secrets",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 91826, text = "Tripwire Tango",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- giver coord: ATT
        { type = "quest",  questID = 91826, text = "Tripwire Tango (objective 1)",
          coord = { map = 2395, x = 0.619, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91826, text = "Tripwire Tango (objective 2)",
          coord = { map = 2395, x = 0.619, y = 0.684 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91826, text = "Turn in: Tripwire Tango",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 91827, text = "No Loose Ends",
          coord = { map = 2395, x = 0.619, y = 0.683 } },  -- giver coord: ATT
        { type = "turnin", questID = 91827, text = "Turn in: No Loose Ends",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        -- (APR: grind/continue to level 90 before the next step)
        { type = "accept", questID = 91828, text = "A Favor for the Lion",
          coord = { map = 2393, x = 0.525, y = 0.783 } },  -- giver coord: ATT
        { type = "quest",  questID = 91828, text = "A Favor for the Lion (objective 1)",
          coord = { map = 2393, x = 0.527, y = 0.787 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91828, text = "A Favor for the Lion (objective 2)",
          coord = { map = 2437, x = 0.405, y = 0.718 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91828, text = "Turn in: A Favor for the Lion",
          coord = { map = 2437, x = 0.404, y = 0.717 } },  -- APR route coord (converted)
        { type = "accept", questID = 91829, text = "One by One",
          coord = { map = 2437, x = 0.404, y = 0.717 } },  -- giver coord: ATT
        { type = "accept", questID = 91830, text = "Intercepted",
          coord = { map = 2437, x = 0.404, y = 0.717 } },  -- giver coord: ATT
        { type = "accept", questID = 91831, text = "Keys Are Optional",
          coord = { map = 2437, x = 0.404, y = 0.717 } },  -- giver coord: ATT
        { type = "quest",  questID = 91831, text = "Keys Are Optional (objective 1) [1/4]",
          coord = { map = 2437, x = 0.398, y = 0.718 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [1/6]",
          coord = { map = 2437, x = 0.398, y = 0.713 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91831, text = "Keys Are Optional (objective 1) [2/4]",
          coord = { map = 2437, x = 0.376, y = 0.712 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [2/6]",
          coord = { map = 2437, x = 0.373, y = 0.711 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [3/6]",
          coord = { map = 2437, x = 0.379, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [4/6]",
          coord = { map = 2437, x = 0.383, y = 0.699 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [5/6]",
          coord = { map = 2437, x = 0.388, y = 0.701 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91830, text = "Intercepted (objective 1) [6/6]",
          coord = { map = 2437, x = 0.382, y = 0.708 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91831, text = "Keys Are Optional (objective 1) [3/4]",
          coord = { map = 2437, x = 0.363, y = 0.714 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91831, text = "Keys Are Optional (objective 1) [4/4]",
          coord = { map = 2437, x = 0.366, y = 0.735 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91829, text = "One by One (objective 1)",
          coord = { map = 2437, x = 0.376, y = 0.728 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91829, text = "One by One (objective 2)",
          coord = { map = 2437, x = 0.383, y = 0.737 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91829, text = "Turn in: One by One",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91830, text = "Turn in: Intercepted",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91831, text = "Turn in: Keys Are Optional",
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 91918, text = "Delves: Measure Once, Cut Twice",
          coord = { map = 2437, x = 0.404, y = 0.717 } },  -- giver coord: ATT
        { type = "quest",  questID = 91918, text = "Delves: Measure Once, Cut Twice (objective 3)",
          coord = nil },  -- no coord: inside Zul'Aman (uiMap 2437), APR position not convertible on an outdoor map; scenario/instance step
        { type = "quest",  questID = 91918, text = "Delves: Measure Once, Cut Twice (objective 2)",
          coord = nil },  -- no coord: inside Zul'Aman (uiMap 2437), APR position not convertible on an outdoor map; scenario/instance step
        { type = "turnin", questID = 91918, text = "Turn in: Delves: Measure Once, Cut Twice",
          coord = { map = 2393, x = 0.525, y = 0.783 } },  -- APR route coord (converted)
    },
}
