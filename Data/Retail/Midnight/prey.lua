-- ToonAge guide data: Midnight: Prey system intro (level 90)
-- Kind: system unlock
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Midnight-Prey"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 5 quest IDs resolved.
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
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_prey"] = {
    id = "midnight_prey", title = "Midnight: Prey system intro (level 90)", expansion = "midnight",
    zone = 2395, minLevel = 90, maxLevel = 90,
    nextGuide = nil,
    steps = {
        -- (APR: grind/continue to level 90 before the next step)
        { type = "accept", questID = 95114, text = "Prey: A Crimson Summons",
          coord = { map = 2393, x = 0.476, y = 0.711 } },  -- APR route coord (converted)
        { type = "turnin", questID = 95114, text = "Turn in: Prey: A Crimson Summons",
          coord = { map = 2393, x = 0.567, y = 0.654 } },  -- APR route coord (converted)
        { type = "accept", questID = 92926, text = "Prey: Astalor's Initiative",
          coord = { map = 2393, x = 0.567, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92926, text = "Turn in: Prey: Astalor's Initiative",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "accept", questID = 92945, text = "The Power of Anguish",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92945, text = "The Power of Anguish (objective 1)",
          coord = { map = 2393, x = 0.199, y = 0.141 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92945, text = "The Power of Anguish (objective 2)",
          coord = { map = 2393, x = 0.201, y = 0.142 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92945, text = "The Power of Anguish (objective 3)",
          coord = { map = 2393, x = 0.200, y = 0.141 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92945, text = "The Power of Anguish (objective 4)",
          coord = { map = 2393, x = 0.200, y = 0.141 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92945, text = "The Power of Anguish (objective 5)",
          coord = { map = 2393, x = 0.201, y = 0.135 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92945, text = "Turn in: The Power of Anguish",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "accept", questID = 93043, text = "When Predator Becomes Prey",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93043, text = "When Predator Becomes Prey (objective 1)",
          coord = { map = 2393, x = 0.205, y = 0.140 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93043, text = "When Predator Becomes Prey (objective 2)",
          coord = { map = 2393, x = 0.199, y = 0.141 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93043, text = "Turn in: When Predator Becomes Prey",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "accept", questID = 93086, text = "To the Sanctum!",
          coord = { map = 2393, x = 0.196, y = 0.136 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93086, text = "Turn in: To the Sanctum!", rep = { { factionID = 2764, amount = 4000 } },
          coord = { map = 2393, x = 0.567, y = 0.654 } },  -- APR route coord (converted)
    },
}
