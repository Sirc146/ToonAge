-- ToonAge guide data: Midnight 12.1.5: The Purpose of Tomorrow
-- Kind: 12.1.5 story chapter (APR InterfaceVersion 120105; APR route key spells it "Propose"). 12.1.5 releases Oct 13 2026 - content may change
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-the-propose-of-Tomorrow"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 16 quest IDs resolved.
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
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2437 Zul'Aman, 2509 Vaults of Atal'Utek, 2512 The Coiled Isle, 2605 Silvermoon City


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_purpose_of_tomorrow"] = {
    id = "midnight_purpose_of_tomorrow", title = "Midnight 12.1.5: The Purpose of Tomorrow", expansion = "midnight",
    zone = 2393, minLevel = 80, maxLevel = 90,
    nextGuide = nil,
    steps = {
        { type = "accept", questID = 95533, text = "Quest 95533",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95533, text = "Quest 95533 (objective 1)",
          coord = { map = 2395, x = 0.508, y = 0.517 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95533, text = "Quest 95533 (objective 2)",
          coord = { map = 2395, x = 0.479, y = 0.369 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95533, text = "Quest 95533 (objective 3)",
          coord = { map = 2393, x = 0.317, y = 0.884 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95533, text = "Quest 95533 (objective 4)",
          coord = { map = 2393, x = 0.315, y = 0.884 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95533, text = "Quest 95533 (objective 5)",
          coord = { map = 2605, x = 0.457, y = 0.897 } },  -- APR route coord (converted); scenario/instance step;  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95533, text = "Quest 95533",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95187, text = "Quest 95187",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95187, text = "Quest 95187 (objective 2)",
          coord = { map = 2393, x = 0.393, y = 0.803 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95187, text = "Quest 95187 (objective 1)",
          coord = { map = 2393, x = 0.390, y = 0.801 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95187, text = "Quest 95187",
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95190, text = "Quest 95190",
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95192, text = "Quest 95192",
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95191, text = "Quest 95191",
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95190, text = "Quest 95190 (objective 3)",
          coord = { map = 2395, x = 0.605, y = 0.837 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95190, text = "Quest 95190 (objective 2)",
          coord = { map = 2395, x = 0.603, y = 0.804 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95190, text = "Quest 95190 (objective 1)",
          coord = { map = 2395, x = 0.609, y = 0.808 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95191, text = "Quest 95191 (objective 1,2,3)",
          coord = { map = 2395, x = 0.611, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95192, text = "Quest 95192 (objective 1)",
          coord = { map = 2395, x = 0.611, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95190, text = "Quest 95190",
          coord = { map = 2395, x = 0.624, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95192, text = "Quest 95192",
          coord = { map = 2395, x = 0.624, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95191, text = "Quest 95191",
          coord = { map = 2395, x = 0.625, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95193, text = "Quest 95193",
          coord = { map = 2395, x = 0.625, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95193, text = "Quest 95193 (objective 1,2)",
          coord = { map = 2395, x = 0.625, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95193, text = "Quest 95193",
          coord = { map = 2395, x = 0.624, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95197, text = "Quest 95197",
          coord = { map = 2395, x = 0.624, y = 0.814 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95197, text = "Quest 95197",
          coord = { map = 2437, x = 0.369, y = 0.179 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95199, text = "Quest 95199",
          coord = { map = 2437, x = 0.369, y = 0.179 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95200, text = "Quest 95200",
          coord = { map = 2437, x = 0.369, y = 0.179 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95199, text = "Quest 95199 (objective 1)",
          coord = { map = 2437, x = 0.355, y = 0.174 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95199, text = "Quest 95199 (objective 3)",
          coord = { map = 2437, x = 0.348, y = 0.167 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 98831, text = "Quest 98831",
          coord = { map = 2437, x = 0.345, y = 0.169 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95199, text = "Quest 95199 (objective 4)",
          coord = { map = 2437, x = 0.342, y = 0.176 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95199, text = "Quest 95199 (objective 2)",
          coord = { map = 2437, x = 0.333, y = 0.157 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95200, text = "Quest 95200 (objective 1)",
          coord = { map = 2437, x = 0.337, y = 0.156 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95200, text = "Quest 95200 (objective 2)",
          coord = { map = 2437, x = 0.355, y = 0.176 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95200, text = "Quest 95200",
          coord = { map = 2437, x = 0.357, y = 0.178 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95199, text = "Quest 95199",
          coord = { map = 2437, x = 0.358, y = 0.177 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95203, text = "Quest 95203",
          coord = { map = 2437, x = 0.358, y = 0.177 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95203, text = "Quest 95203 (objective 1,2)",
          coord = { map = 2437, x = 0.358, y = 0.177 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95203, text = "Quest 95203",
          coord = { map = 2512, x = 0.247, y = 0.583 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95208, text = "Quest 95208",
          coord = { map = 2512, x = 0.247, y = 0.583 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95206, text = "Quest 95206",
          coord = { map = 2512, x = 0.248, y = 0.582 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95208, text = "Quest 95208 (objective 1)",
          coord = { map = 2512, x = 0.261, y = 0.609 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95208, text = "Quest 95208 (objective 4)",
          coord = { map = 2512, x = 0.241, y = 0.648 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95208, text = "Quest 95208 (objective 3)",
          coord = { map = 2512, x = 0.275, y = 0.677 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95206, text = "Quest 95206 (objective 1) [92%]",
          coord = { map = 2512, x = 0.267, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95208, text = "Quest 95208 (objective 2)",
          coord = { map = 2512, x = 0.295, y = 0.627 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95206, text = "Quest 95206 (objective 1)",
          coord = { map = 2512, x = 0.267, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95208, text = "Quest 95208",
          coord = { map = 2512, x = 0.289, y = 0.651 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95206, text = "Quest 95206",
          coord = { map = 2512, x = 0.289, y = 0.651 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95209, text = "Quest 95209",
          coord = { map = 2512, x = 0.289, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95209, text = "Quest 95209 (objective 1)",
          coord = { map = 2512, x = 0.306, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95209, text = "Quest 95209 (objective 2)", useItem = 270342, useItemVerified = false,
          coord = { map = 2512, x = 0.306, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95209, text = "Quest 95209",
          coord = { map = 2512, x = 0.324, y = 0.649 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 95210, text = "Quest 95210",
          coord = { map = 2512, x = 0.325, y = 0.648 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95210, text = "Quest 95210 (objective 1)",
          coord = { map = 2509, x = 0.472, y = 0.796 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95210, text = "Quest 95210 (objective 2)",
          coord = { map = 2509, x = 0.473, y = 0.538 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95210, text = "Quest 95210 (objective 3)",
          coord = { map = 2509, x = 0.493, y = 0.535 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95210, text = "Quest 95210 (objective 4)",
          coord = { map = 2509, x = 0.546, y = 0.399 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 95210, text = "Quest 95210 (objective 5)",
          coord = { map = 2509, x = 0.494, y = 0.301 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "turnin", questID = 95210, text = "Quest 95210",
          coord = { map = 2509, x = 0.558, y = 0.300 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "accept", questID = 96707, text = "Quest 96707",
          coord = { map = 2509, x = 0.558, y = 0.300 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 96707, text = "Quest 96707 (objective 1)",
          coord = { map = 2509, x = 0.534, y = 0.145 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
        { type = "quest",  questID = 96707, text = "Quest 96707 (objective 2)",
          coord = { map = 2509, x = 0.534, y = 0.145 } },  -- APR route coord (converted);  UNVERIFIED name (not on Wowhead tooltip API)
    },
}
