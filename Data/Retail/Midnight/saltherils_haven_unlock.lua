-- ToonAge guide data: Midnight: Unlock Saltheril's Haven dailies (level 90)
-- Kind: daily-hub unlock
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2413-Midnight-Unlock-daily-Saltherils-Haven"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 11 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 1 accept steps where ATT and converted APR coords share a map: median 0.06, p90 0.06, max 0.06 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_saltherils_haven_unlock"] = {
    id = "midnight_saltherils_haven_unlock", title = "Midnight: Unlock Saltheril's Haven dailies (level 90)", expansion = "midnight",
    zone = 2395, minLevel = 90, maxLevel = 90,
    nextGuide = "midnight_prey",
    steps = {
        { type = "accept", questID = 95245, text = "Midnight: World Tour",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 95245, text = "Midnight: World Tour (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 91627, text = "Saltheril's Haven",
          coord = { map = 2393, x = 0.457, y = 0.626 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91627, text = "Turn in: Saltheril's Haven",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 91628, text = "Honored Guests",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91628, text = "Honored Guests (objective 4)",
          coord = { map = 2393, x = 0.243, y = 0.715 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91628, text = "Honored Guests (objective 2)",
          coord = { map = 2393, x = 0.336, y = 0.513 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91628, text = "Honored Guests (objective 3)",
          coord = { map = 2393, x = 0.446, y = 0.720 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91628, text = "Honored Guests (objective 5)",
          coord = { map = 2393, x = 0.528, y = 0.634 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91628, text = "Turn in: Honored Guests",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 91629, text = "High Esteem",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91629, text = "High Esteem (objective 3)",
          coord = { map = 2395, x = 0.434, y = 0.476 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91629, text = "High Esteem (objective 4)",
          coord = { map = 2395, x = 0.435, y = 0.476 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91629, text = "High Esteem (objective 1)",
          coord = { map = 2395, x = 0.435, y = 0.475 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91629, text = "High Esteem (objective 2)",
          coord = { map = 2395, x = 0.435, y = 0.475 } },  -- APR route coord (converted)
        { type = "accept", questID = 93200, text = "A Handful of Voidlight Marl",
          coord = { map = 2395, x = 0.435, y = 0.474 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93200, text = "Turn in: A Handful of Voidlight Marl",
          coord = { map = 2395, x = 0.435, y = 0.474 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91629, text = "High Esteem (objective 5)",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91629, text = "Turn in: High Esteem",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 91693, text = "The Subtle Game",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91693, text = "The Subtle Game (objective 1)",
          coord = { map = 2395, x = 0.424, y = 0.467 } },  -- APR route coord (converted)
        { type = "accept", questID = 91977, text = "Less Lawless",
          coord = { map = 2395, x = 0.424, y = 0.467 } },  -- APR route coord (converted)
        { type = "accept", questID = 89276, text = "Light Snacks",
          coord = { map = 2395, x = 0.426, y = 0.462 } },  -- APR route coord (converted)
        { type = "accept", questID = 92002, text = "Dangerous Showpieces",
          coord = { map = 2395, x = 0.428, y = 0.456 } },  -- APR route coord (converted)
        { type = "accept", questID = 90575, text = "Fortify the Runestones: Farstriders",
          coord = { map = 2395, x = 0.429, y = 0.464 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91693, text = "Turn in: The Subtle Game",
          coord = { map = 2395, x = 0.427, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 91966, text = "Saltheril's Soiree",
          coord = { map = 2395, x = 0.429, y = 0.464 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91966, text = "Saltheril's Soiree (objective 1) [20%]",
          coord = { map = 2395, x = 0.430, y = 0.467 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91966, text = "Saltheril's Soiree (objective 1) [40%]",
          coord = { map = 2395, x = 0.426, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91966, text = "Saltheril's Soiree (objective 1) [60%]",
          coord = { map = 2395, x = 0.426, y = 0.469 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91966, text = "Saltheril's Soiree (objective 1) [80%]",
          coord = { map = 2395, x = 0.423, y = 0.461 } },  -- APR route coord (converted)
    },
}
