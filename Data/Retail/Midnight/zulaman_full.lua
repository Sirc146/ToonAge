-- ToonAge guide data: Midnight: Zul'Aman (Campaign + side quests)
-- Kind: APR "sojourner" route
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-ZulAman"
--    in Routes/Midnight/Midnight-Zulaman.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 148 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 139 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 3.26 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2437 Zul'Aman, 2536 Atal'Aman


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_zulaman_full"] = {
    id = "midnight_zulaman_full", title = "Midnight: Zul'Aman (Campaign + side quests)", expansion = "midnight",
    zone = 2437, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_darkening_sky",
    steps = {
        -- (APR: grind/continue to level 83 before the next step)
        { type = "accept", questID = 86708, text = "The Gates of Zul'Aman",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "turnin", questID = 86708, text = "Turn in: The Gates of Zul'Aman",
          coord = { map = 2395, x = 0.601, y = 0.815 } },  -- APR route coord (converted)
        { type = "accept", questID = 86710, text = "The Line Must Be Drawn Here",
          coord = { map = 2395, x = 0.601, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 86710, text = "The Line Must Be Drawn Here (objective 1)",
          coord = { map = 2395, x = 0.603, y = 0.815 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86710, text = "The Line Must Be Drawn Here (objective 2)",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86710, text = "The Line Must Be Drawn Here (objective 3)",
          coord = { map = 2395, x = 0.604, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86710, text = "Turn in: The Line Must Be Drawn Here",
          coord = { map = 2395, x = 0.601, y = 0.815 } },  -- APR route coord (converted)
        { type = "accept", questID = 90749, text = "Our Mutual Enemy",
          coord = { map = 2395, x = 0.601, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 90749, text = "Our Mutual Enemy (objective 1)",
          coord = { map = 2536, x = 0.064, y = 0.473 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90749, text = "Turn in: Our Mutual Enemy", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.054, y = 0.470 } },  -- APR route coord (converted)
        { type = "accept", questID = 86868, text = "Goodwill Tour",
          coord = { map = 2536, x = 0.055, y = 0.470 } },  -- giver coord: ATT
        { type = "accept", questID = 86711, text = "Amani Clarion Call",
          coord = { map = 2536, x = 0.057, y = 0.478 } },  -- giver coord: ATT
        { type = "quest",  questID = 86711, text = "Amani Clarion Call (objective 1) [1/3]",
          coord = { map = 2536, x = 0.166, y = 0.475 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86711, text = "Amani Clarion Call (objective 1) [2/3]",
          coord = { map = 2536, x = 0.250, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86711, text = "Amani Clarion Call (objective 1) [3/3]",
          coord = { map = 2536, x = 0.360, y = 0.496 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86868, text = "Goodwill Tour (objective 1)",
          coord = { map = 2536, x = 0.342, y = 0.475 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86868, text = "Turn in: Goodwill Tour", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.460, y = 0.484 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86711, text = "Turn in: Amani Clarion Call", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.463, y = 0.488 } },  -- APR route coord (converted)
        { type = "accept", questID = 86717, text = "Show Us Your Worth",
          coord = { map = 2536, x = 0.463, y = 0.488 } },  -- giver coord: ATT
        { type = "accept", questID = 86719, text = "Important Amani",
          coord = { map = 2536, x = 0.463, y = 0.484 } },  -- giver coord: ATT
        { type = "quest",  questID = 86719, text = "Important Amani (objective 1)",
          coord = { map = 2536, x = 0.506, y = 0.198 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86719, text = "Important Amani (objective 2)",
          coord = { map = 2536, x = 0.356, y = 0.246 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86717, text = "Show Us Your Worth (objective 1)",
          coord = { map = 2536, x = 0.345, y = 0.169 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86719, text = "Important Amani (objective 3)",
          coord = { map = 2536, x = 0.168, y = 0.205 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86719, text = "Important Amani (objective 4)",
          coord = { map = 2536, x = 0.171, y = 0.200 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86719, text = "Important Amani (objective 5)",
          coord = { map = 2536, x = 0.165, y = 0.207 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86717, text = "Turn in: Show Us Your Worth", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.166, y = 0.204 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86719, text = "Turn in: Important Amani", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.166, y = 0.204 } },  -- APR route coord (converted)
        { type = "accept", questID = 86716, text = "Armed by Light",
          coord = { map = 2536, x = 0.166, y = 0.205 } },  -- giver coord: ATT
        { type = "accept", questID = 86721, text = "Everything We Worked For",
          coord = { map = 2536, x = 0.166, y = 0.205 } },  -- giver coord: ATT
        { type = "quest",  questID = 86721, text = "Everything We Worked For (objective 1) [1/4]",
          coord = { map = 2536, x = 0.163, y = 0.593 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86721, text = "Everything We Worked For (objective 1) [2/4]",
          coord = { map = 2536, x = 0.225, y = 0.615 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86721, text = "Everything We Worked For (objective 1) [3/4]",
          coord = { map = 2536, x = 0.235, y = 0.681 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86721, text = "Everything We Worked For (objective 1) [4/4]",
          coord = { map = 2536, x = 0.181, y = 0.760 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86716, text = "Armed by Light (objective 1)",
          coord = { map = 2536, x = 0.220, y = 0.664 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86721, text = "Everything We Worked For (objective 2)",
          coord = { map = 2536, x = 0.226, y = 0.803 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86716, text = "Turn in: Armed by Light", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.226, y = 0.799 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86721, text = "Turn in: Everything We Worked For", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.226, y = 0.799 } },  -- APR route coord (converted)
        { type = "accept", questID = 86712, text = "The Amani Stand Strong",
          coord = { map = 2536, x = 0.226, y = 0.799 } },  -- giver coord: ATT
        { type = "accept", questID = 86718, text = "Twilight Bled",
          coord = { map = 2536, x = 0.229, y = 0.793 } },  -- giver coord: ATT
        { type = "accept", questID = 86715, text = "Rituals Cut Short",
          coord = { map = 2536, x = 0.231, y = 0.799 } },  -- giver coord: ATT
        { type = "quest",  questID = 86718, text = "Twilight Bled (objective 1)",
          coord = { map = 2536, x = 0.347, y = 0.798 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86712, text = "The Amani Stand Strong (objective 1)",
          coord = { map = 2536, x = 0.344, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86715, text = "Rituals Cut Short (objective 1,2)",
          coord = { map = 2536, x = 0.344, y = 0.686 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86715, text = "Turn in: Rituals Cut Short", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.472, y = 0.469 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86718, text = "Turn in: Twilight Bled", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.475, y = 0.468 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86712, text = "Turn in: The Amani Stand Strong", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.491, y = 0.467 } },  -- APR route coord (converted)
        { type = "accept", questID = 86720, text = "Break the Blade",
          coord = { map = 2536, x = 0.475, y = 0.468 } },  -- giver coord: ATT
        { type = "quest",  questID = 86720, text = "Break the Blade (objective 1)",
          coord = { map = 2536, x = 0.492, y = 0.471 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86720, text = "Break the Blade (objective 2)",
          coord = { map = 2536, x = 0.492, y = 0.471 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86720, text = "Turn in: Break the Blade", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2536, x = 0.477, y = 0.478 } },  -- APR route coord (converted)
        { type = "accept", questID = 86722, text = "Heart of the Amani",
          coord = { map = 2536, x = 0.478, y = 0.478 } },  -- giver coord: ATT
        { type = "turnin", questID = 86722, text = "Turn in: Heart of the Amani", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.426, y = 0.668 } },  -- APR route coord (converted)
        { type = "accept", questID = 86723, text = "Isolation",
          coord = { map = 2437, x = 0.427, y = 0.668 } },  -- giver coord: ATT
        { type = "quest",  questID = 86723, text = "Isolation (objective 1)",
          coord = { map = 2437, x = 0.457, y = 0.655 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86723, text = "Turn in: Isolation", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.457, y = 0.655 } },  -- APR route coord (converted)
        { type = "accept", questID = 86652, text = "Left in the Shadows",
          coord = { map = 2437, x = 0.457, y = 0.655 } },  -- giver coord: ATT
        { type = "quest",  questID = 86652, text = "Left in the Shadows (objective 1)",
          coord = { map = 2437, x = 0.469, y = 0.673 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86652, text = "Left in the Shadows (objective 2)",
          coord = { map = 2437, x = 0.451, y = 0.677 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86652, text = "Left in the Shadows (objective 3)",
          coord = { map = 2437, x = 0.440, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86652, text = "Left in the Shadows (objective 4)",
          coord = { map = 2437, x = 0.438, y = 0.684 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86652, text = "Turn in: Left in the Shadows", rep = { { factionID = 2696, amount = 1500 } },
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 86653, text = "The Path of the Amani",
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- giver coord: ATT
        { type = "quest",  questID = 86653, text = "The Path of the Amani (objective 2)",
          coord = { map = 2437, x = 0.438, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86653, text = "The Path of the Amani (objective 1)",
          coord = { map = 2437, x = 0.516, y = 0.708 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86653, text = "Turn in: The Path of the Amani", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.516, y = 0.708 } },  -- APR route coord (converted)
        { type = "accept", questID = 86655, text = "De Ancient Path",
          coord = { map = 2437, x = 0.516, y = 0.708 } },  -- giver coord: ATT
        { type = "accept", questID = 89334, text = "Ahead of the Issue",
          coord = { map = 2437, x = 0.516, y = 0.708 } },  -- giver coord: ATT
        { type = "accept", questID = 86654, text = "Gnarldin Bashing",
          coord = { map = 2437, x = 0.516, y = 0.707 } },  -- giver coord: ATT
        { type = "quest",  questID = 86655, text = "De Ancient Path (objective 1) [1/4]",
          coord = { map = 2437, x = 0.537, y = 0.730 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89334, text = "Ahead of the Issue (objective 2)",
          coord = { map = 2437, x = 0.532, y = 0.742 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89334, text = "Ahead of the Issue (objective 3)",
          coord = { map = 2437, x = 0.552, y = 0.778 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86655, text = "De Ancient Path (objective 1) [2/4]",
          coord = { map = 2437, x = 0.552, y = 0.763 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89334, text = "Ahead of the Issue (objective 1)",
          coord = { map = 2437, x = 0.562, y = 0.749 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86655, text = "De Ancient Path (objective 1) [3/4]",
          coord = { map = 2437, x = 0.563, y = 0.738 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86655, text = "De Ancient Path (objective 1) [4/4]",
          coord = { map = 2437, x = 0.553, y = 0.709 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86654, text = "Gnarldin Bashing (objective 1)",
          coord = { map = 2437, x = 0.544, y = 0.732 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86655, text = "De Ancient Path (objective 2)",
          coord = { map = 2437, x = 0.519, y = 0.760 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86654, text = "Turn in: Gnarldin Bashing", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.520, y = 0.760 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86655, text = "Turn in: De Ancient Path", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.519, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89334, text = "Turn in: Ahead of the Issue", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.519, y = 0.759 } },  -- APR route coord (converted)
        { type = "accept", questID = 86656, text = "Brutal Feast",
          coord = { map = 2437, x = 0.519, y = 0.759 } },  -- giver coord: ATT
        { type = "quest",  questID = 86656, text = "Brutal Feast (objective 1)",
          coord = { map = 2437, x = 0.524, y = 0.810 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86656, text = "Brutal Feast (objective 2)",
          coord = { map = 2437, x = 0.524, y = 0.811 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86656, text = "Brutal Feast (objective 4) [1/3]",
          coord = { map = 2437, x = 0.524, y = 0.824 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86656, text = "Brutal Feast (objective 4) [2/3]",
          coord = { map = 2437, x = 0.532, y = 0.807 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86656, text = "Brutal Feast (objective 4) [3/3]",
          coord = { map = 2437, x = 0.532, y = 0.811 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86656, text = "Turn in: Brutal Feast", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.524, y = 0.810 } },  -- APR route coord (converted)
        { type = "accept", questID = 86809, text = "Test of Conviction",
          coord = { map = 2437, x = 0.524, y = 0.810 } },  -- giver coord: ATT
        { type = "quest",  questID = 86809, text = "Test of Conviction (objective 1)",
          coord = { map = 2437, x = 0.511, y = 0.790 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86809, text = "Test of Conviction (objective 2)",
          coord = { map = 2437, x = 0.510, y = 0.789 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86809, text = "Turn in: Test of Conviction", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.524, y = 0.810 } },  -- APR route coord (converted)
        { type = "accept", questID = 86657, text = "Shadebasin Watch",
          coord = { map = 2437, x = 0.524, y = 0.810 } },  -- giver coord: ATT
        { type = "quest",  questID = 86657, text = "Shadebasin Watch (objective 2)",
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86657, text = "Turn in: Shadebasin Watch", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- APR route coord (converted)
        { type = "accept", questID = 86658, text = "The Crypt in the Mist",
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- giver coord: ATT
        { type = "accept", questID = 86660, text = "Rescue from the Shadows",
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- giver coord: ATT
        { type = "quest",  questID = 86658, text = "The Crypt in the Mist (objective 1)",
          coord = { map = 2437, x = 0.393, y = 0.394 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86658, text = "The Crypt in the Mist (objective 2)",
          coord = { map = 2437, x = 0.379, y = 0.373 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86660, text = "Rescue from the Shadows (objective 1)",
          coord = { map = 2437, x = 0.379, y = 0.373 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86658, text = "The Crypt in the Mist (objective 3)",
          coord = { map = 2437, x = 0.375, y = 0.360 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86658, text = "Turn in: The Crypt in the Mist", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.368, y = 0.350 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86660, text = "Turn in: Rescue from the Shadows", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.368, y = 0.350 } },  -- APR route coord (converted)
        { type = "accept", questID = 86659, text = "Breaching the Mist",
          coord = { map = 2437, x = 0.368, y = 0.350 } },  -- giver coord: ATT
        { type = "quest",  questID = 86659, text = "Breaching the Mist (objective 1)",
          coord = { map = 2437, x = 0.355, y = 0.361 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86659, text = "Breaching the Mist (objective 2) [1/3]",
          coord = { map = 2437, x = 0.334, y = 0.345 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86659, text = "Breaching the Mist (objective 2) [2/3]",
          coord = { map = 2437, x = 0.340, y = 0.320 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86659, text = "Breaching the Mist (objective 2) [3/3]",
          coord = { map = 2437, x = 0.348, y = 0.309 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86659, text = "Breaching the Mist (objective 3)",
          coord = { map = 2437, x = 0.328, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86659, text = "Turn in: Breaching the Mist", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.324, y = 0.316 } },  -- APR route coord (converted)
        { type = "accept", questID = 92084, text = "Halazzi's Guile",
          coord = { map = 2437, x = 0.324, y = 0.316 } },  -- giver coord: ATT
        { type = "quest",  questID = 92084, text = "Halazzi's Guile (objective 1)",
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92084, text = "Turn in: Halazzi's Guile", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.324, y = 0.316 } },  -- APR route coord (converted)
        { type = "accept", questID = 86661, text = "Coals of a Dead Loa",
          coord = { map = 2437, x = 0.324, y = 0.316 } },  -- giver coord: ATT
        { type = "quest",  questID = 86661, text = "Coals of a Dead Loa (objective 1)",
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86661, text = "Turn in: Coals of a Dead Loa", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.385, y = 0.225 } },  -- APR route coord (converted)
        { type = "accept", questID = 86808, text = "The Riddled Speaker",
          coord = { map = 2437, x = 0.385, y = 0.225 } },  -- giver coord: ATT
        { type = "quest",  questID = 86808, text = "The Riddled Speaker (objective 1)",
          coord = { map = 2437, x = 0.550, y = 0.184 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86808, text = "Turn in: The Riddled Speaker", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 86663, text = "Embers to a Flame",
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- giver coord: ATT
        { type = "quest",  questID = 86663, text = "Embers to a Flame (objective 2)",
          coord = { map = 2437, x = 0.551, y = 0.182 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86663, text = "Embers to a Flame (objective 3)",
          coord = { map = 2437, x = 0.533, y = 0.219 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86663, text = "Embers to a Flame (objective 4)",
          coord = { map = 2437, x = 0.551, y = 0.183 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86663, text = "Turn in: Embers to a Flame", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 86664, text = "Seer or Sear",
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- giver coord: ATT
        { type = "quest",  questID = 86664, text = "Seer or Sear (objective 1)",
          coord = { map = 2437, x = 0.549, y = 0.215 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86664, text = "Seer or Sear (objective 2)",
          coord = { map = 2437, x = 0.529, y = 0.186 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86664, text = "Seer or Sear (objective 3)",
          coord = { map = 2437, x = 0.551, y = 0.182 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86664, text = "Turn in: Seer or Sear", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 86665, text = "Face in the Fire",
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- giver coord: ATT
        { type = "quest",  questID = 86665, text = "Face in the Fire (objective 1,2)",
          coord = { map = 2437, x = 0.551, y = 0.182 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86665, text = "Turn in: Face in the Fire", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 90772, text = "The Flames Rise Higher",
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- giver coord: ATT
        { type = "quest",  questID = 90772, text = "The Flames Rise Higher (objective 1)",
          coord = { map = 2437, x = 0.551, y = 0.183 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90772, text = "Turn in: The Flames Rise Higher", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 86666, text = "In the Shadow of Rebirth",
          coord = { map = 2437, x = 0.550, y = 0.183 } },  -- giver coord: ATT
        { type = "turnin", questID = 86666, text = "Turn in: In the Shadow of Rebirth", rep = { { factionID = 2696, amount = 1500 } },
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 86681, text = "Den of Nalorakk: A Taste of Vengeance",
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- giver coord: ATT
        { type = "quest",  questID = 86681, text = "Den of Nalorakk: A Taste of Vengeance (objective 1)",
          coord = { map = 2437, x = 0.436, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86681, text = "Den of Nalorakk: A Taste of Vengeance (objective 2) [1/3]",
          coord = { map = 2437, x = 0.436, y = 0.682 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86681, text = "Den of Nalorakk: A Taste of Vengeance (objective 2) [2/3]",
          coord = { map = 2437, x = 0.437, y = 0.685 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86681, text = "Den of Nalorakk: A Taste of Vengeance (objective 2) [3/3]",
          coord = { map = 2437, x = 0.439, y = 0.687 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86681, text = "Turn in: Den of Nalorakk: A Taste of Vengeance", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- APR route coord (converted)
        { type = "accept", questID = 86682, text = "Den of Nalorakk: Waking de Bear",
          coord = { map = 2437, x = 0.438, y = 0.683 } },  -- giver coord: ATT
        { type = "quest",  questID = 86682, text = "Den of Nalorakk: Waking de Bear (objective 1)",
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86682, text = "Turn in: Den of Nalorakk: Waking de Bear", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 91958, text = "Den of Nalorakk: Unforgiven",
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- giver coord: ATT
        { type = "quest",  questID = 91958, text = "Den of Nalorakk: Unforgiven (objective 3)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "quest",  questID = 91958, text = "Den of Nalorakk: Unforgiven (objective 4)",
          coord = { map = 2437, x = 0.316, y = 0.839 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91958, text = "Turn in: Den of Nalorakk: Unforgiven", rep = { { factionID = 2696, amount = 1500 } },
          coord = { map = 2437, x = 0.316, y = 0.839 } },  -- APR route coord (converted)
        { type = "accept", questID = 86683, text = "Hash'ey Away",
          coord = { map = 2437, x = 0.316, y = 0.839 } },  -- giver coord: ATT
        { type = "quest",  questID = 86683, text = "Hash'ey Away (objective 1)",
          coord = { map = 2437, x = 0.439, y = 0.688 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86683, text = "Hash'ey Away (objective 2)",
          coord = { map = 2437, x = 0.438, y = 0.687 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86683, text = "Turn in: Hash'ey Away", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.435, y = 0.688 } },  -- APR route coord (converted)
        { type = "accept", questID = 86684, text = "The Blade's Edge",
          coord = { map = 2437, x = 0.435, y = 0.688 } },  -- giver coord: ATT
        { type = "quest",  questID = 86684, text = "The Blade's Edge (objective 1)",
          coord = { map = 2437, x = 0.284, y = 0.774 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86684, text = "Turn in: The Blade's Edge", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.284, y = 0.774 } },  -- APR route coord (converted)
        { type = "accept", questID = 86687, text = "Conduit Crisis",
          coord = { map = 2437, x = 0.284, y = 0.774 } },  -- giver coord: ATT
        { type = "accept", questID = 86685, text = "Chip and Shatter",
          coord = { map = 2437, x = 0.284, y = 0.774 } },  -- giver coord: ATT
        { type = "accept", questID = 86686, text = "Light Indiscriminate",
          coord = { map = 2437, x = 0.284, y = 0.774 } },  -- giver coord: ATT
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 4) [1/3]",
          coord = { map = 2437, x = 0.273, y = 0.809 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 4) [2/3]",
          coord = { map = 2437, x = 0.277, y = 0.817 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 4) [3/3]",
          coord = { map = 2437, x = 0.269, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 3) [1/3]",
          coord = { map = 2437, x = 0.243, y = 0.805 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 3) [2/3]",
          coord = { map = 2437, x = 0.241, y = 0.798 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 3) [3/3]",
          coord = { map = 2437, x = 0.231, y = 0.799 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 2) [1/3]",
          coord = { map = 2437, x = 0.232, y = 0.754 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 2) [2/3]",
          coord = { map = 2437, x = 0.238, y = 0.743 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 2) [3/3]",
          coord = { map = 2437, x = 0.247, y = 0.745 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 1) [1/3]",
          coord = { map = 2437, x = 0.239, y = 0.714 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 1) [2/3]",
          coord = { map = 2437, x = 0.252, y = 0.700 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86687, text = "Conduit Crisis (objective 1) [3/3]",
          coord = { map = 2437, x = 0.262, y = 0.720 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86685, text = "Chip and Shatter (objective 1)",
          coord = { map = 2437, x = 0.262, y = 0.772 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86686, text = "Light Indiscriminate (objective 1)",
          coord = { map = 2437, x = 0.262, y = 0.772 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86686, text = "Turn in: Light Indiscriminate", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.257, y = 0.776 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86687, text = "Turn in: Conduit Crisis", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.257, y = 0.776 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86685, text = "Turn in: Chip and Shatter", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.257, y = 0.776 } },  -- APR route coord (converted)
        { type = "accept", questID = 91001, text = "Clear de Way",
          coord = { map = 2437, x = 0.257, y = 0.776 } },  -- giver coord: ATT
        { type = "quest",  questID = 91001, text = "Clear de Way (objective 1)",
          coord = { map = 2437, x = 0.225, y = 0.774 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91001, text = "Turn in: Clear de Way", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.225, y = 0.774 } },  -- APR route coord (converted)
        { type = "accept", questID = 86692, text = "Blade Shattered",
          coord = { map = 2437, x = 0.225, y = 0.774 } },  -- giver coord: ATT
        { type = "quest",  questID = 86692, text = "Blade Shattered (objective 1)",
          coord = { map = 2437, x = 0.225, y = 0.774 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86692, text = "Blade Shattered (objective 2)",
          coord = { map = 2437, x = 0.214, y = 0.774 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86692, text = "Turn in: Blade Shattered", rep = { { factionID = 2696, amount = 1500 } },
          coord = { map = 2437, x = 0.214, y = 0.774 } },  -- APR route coord (converted)
        { type = "accept", questID = 86693, text = "De Legend of de Hash'ey",
          coord = { map = 2437, x = 0.214, y = 0.774 } },  -- giver coord: ATT
        { type = "quest",  questID = 86693, text = "De Legend of de Hash'ey (objective 1)",
          coord = { map = 2437, x = 0.453, y = 0.662 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86693, text = "Turn in: De Legend of de Hash'ey", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.458, y = 0.655 } },  -- APR route coord (converted)
        { type = "accept", questID = 91062, text = "Broken Bridges",
          coord = { map = 2437, x = 0.457, y = 0.655 } },  -- giver coord: ATT
        { type = "quest",  questID = 91062, text = "Broken Bridges (objective 1)",
          coord = { map = 2437, x = 0.513, y = 0.544 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91062, text = "Turn in: Broken Bridges", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.508, y = 0.545 } },  -- APR route coord (converted)
        { type = "accept", questID = 91087, text = "Reports Returned",
          coord = { map = 2437, x = 0.508, y = 0.545 } },  -- giver coord: ATT
        { type = "turnin", questID = 91087, text = "Turn in: Reports Returned", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 93051, text = "The Final Exam",
          coord = { map = 2437, x = 0.431, y = 0.671 } },  -- giver coord: ATT
        { type = "accept", questID = 91206, text = "Loa Disturbance",
          coord = { map = 2437, x = 0.431, y = 0.679 } },  -- giver coord: ATT
        { type = "accept", questID = 93050, text = "Altar History",
          coord = { map = 2437, x = 0.435, y = 0.688 } },  -- giver coord: ATT
        { type = "quest",  questID = 93050, text = "Altar History (objective 3)",
          coord = { map = 2437, x = 0.431, y = 0.685 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93050, text = "Altar History (objective 2)",
          coord = { map = 2437, x = 0.431, y = 0.681 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93050, text = "Altar History (objective 1)",
          coord = { map = 2437, x = 0.440, y = 0.694 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93050, text = "Altar History (objective 4)",
          coord = { map = 2437, x = 0.434, y = 0.690 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93050, text = "Turn in: Altar History", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.434, y = 0.690 } },  -- APR route coord (converted)
        { type = "accept", questID = 92450, text = "Growing Up is Hard",
          coord = { map = 2437, x = 0.452, y = 0.698 } },  -- giver coord: ATT
        { type = "accept", questID = 89565, text = "The Path of Mourning",
          coord = { map = 2437, x = 0.454, y = 0.697 } },  -- giver coord: ATT
        { type = "accept", questID = 93047, text = "Butchery Basics",
          coord = { map = 2437, x = 0.456, y = 0.694 } },  -- giver coord: ATT
        { type = "accept", questID = 93257, text = "Revantusk at Risk",
          coord = { map = 2437, x = 0.459, y = 0.708 } },  -- giver coord: ATT
        { type = "accept", questID = 94867, text = "Lost in Atal'Abasi",
          coord = { map = 2437, x = 0.451, y = 0.683 } },  -- giver coord: ATT
        { type = "accept", questID = 93049, text = "Homework Support",
          coord = { map = 2437, x = 0.466, y = 0.680 } },  -- giver coord: ATT
        { type = "accept", questID = 93048, text = "Got No Rhythm",
          coord = { map = 2437, x = 0.468, y = 0.662 } },  -- giver coord: ATT
        { type = "quest",  questID = 93048, text = "Got No Rhythm (objective 1)",
          coord = { map = 2437, x = 0.469, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93048, text = "Got No Rhythm (objective 2)",
          coord = { map = 2437, x = 0.469, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93048, text = "Got No Rhythm (objective 3)",
          coord = { map = 2437, x = 0.468, y = 0.663 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93048, text = "Turn in: Got No Rhythm", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.468, y = 0.662 } },  -- APR route coord (converted)
        { type = "accept", questID = 88985, text = "Recuperating Returns",
          coord = { map = 2437, x = 0.457, y = 0.655 } },  -- giver coord: ATT; only if warband lacks achievement 42045
        { type = "accept", questID = 92163, text = "The Loa of Murlocs",
          coord = { map = 2437, x = 0.460, y = 0.651 } },  -- giver coord: ATT
        { type = "accept", questID = 89230, text = "A Lover Not a Fighter",
          coord = { map = 2437, x = 0.440, y = 0.662 } },  -- giver coord: ATT
        { type = "accept", questID = 89231, text = "A Fighter Not a Lover",
          coord = { map = 2437, x = 0.439, y = 0.660 } },  -- giver coord: ATT
        { type = "quest",  questID = 93051, text = "The Final Exam (objective 1)",
          coord = { map = 2437, x = 0.438, y = 0.647 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93051, text = "The Final Exam (objective 2)",
          coord = { map = 2437, x = 0.438, y = 0.647 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93051, text = "Turn in: The Final Exam", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.439, y = 0.647 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93049, text = "Homework Support (objective 1,2)",
          coord = { map = 2437, x = 0.450, y = 0.669 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93049, text = "Turn in: Homework Support", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.467, y = 0.680 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92450, text = "Growing Up is Hard (objective 1)",
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92450, text = "Turn in: Growing Up is Hard", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- APR route coord (converted)
        { type = "accept", questID = 92451, text = "I Think I Can",
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- giver coord: ATT
        { type = "quest",  questID = 92451, text = "I Think I Can (objective 1)",
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92451, text = "I Think I Can (objective 2)",
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92451, text = "I Think I Can (objective 3)",
          coord = { map = 2437, x = 0.481, y = 0.676 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92451, text = "Turn in: I Think I Can", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.487, y = 0.661 } },  -- APR route coord (converted)
        { type = "accept", questID = 92452, text = "Not According to Plan",
          coord = { map = 2437, x = 0.487, y = 0.661 } },  -- giver coord: ATT
        { type = "quest",  questID = 92452, text = "Not According to Plan (objective 1) [33%]",
          coord = { map = 2437, x = 0.475, y = 0.635 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92452, text = "Not According to Plan (objective 1) [66%]",
          coord = { map = 2437, x = 0.460, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92452, text = "Not According to Plan (objective 1)",
          coord = { map = 2437, x = 0.453, y = 0.611 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92452, text = "Turn in: Not According to Plan", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.446, y = 0.605 } },  -- APR route coord (converted)
        { type = "accept", questID = 92453, text = "Fearless",
          coord = { map = 2437, x = 0.446, y = 0.605 } },  -- giver coord: ATT
        { type = "quest",  questID = 92453, text = "Fearless (objective 1)",
          coord = { map = 2437, x = 0.452, y = 0.698 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92453, text = "Turn in: Fearless", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.452, y = 0.698 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89565, text = "Turn in: The Path of Mourning", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.459, y = 0.724 } },  -- APR route coord (converted)
        { type = "accept", questID = 89503, text = "Somber Siblings",
          coord = { map = 2437, x = 0.459, y = 0.724 } },  -- giver coord: ATT
        { type = "quest",  questID = 89503, text = "Somber Siblings (objective 1)",
          coord = { map = 2437, x = 0.464, y = 0.736 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93047, text = "Butchery Basics (objective 1)",
          coord = { map = 2437, x = 0.464, y = 0.736 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89503, text = "Turn in: Somber Siblings", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 89506, text = "Strong Ties",
          coord = { map = 2437, x = 0.462, y = 0.748 } },  -- giver coord: ATT
        { type = "quest",  questID = 89506, text = "Strong Ties (objective 1)",
          coord = { map = 2437, x = 0.474, y = 0.789 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89506, text = "Turn in: Strong Ties", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 89513, text = "Kindling Aplenty",
          coord = { map = 2437, x = 0.467, y = 0.780 } },  -- giver coord: ATT
        { type = "quest",  questID = 89513, text = "Kindling Aplenty (objective 1)",
          coord = { map = 2437, x = 0.484, y = 0.844 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89513, text = "Turn in: Kindling Aplenty", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 89559, text = "Reasonless Worship",
          coord = { map = 2437, x = 0.485, y = 0.851 } },  -- giver coord: ATT
        { type = "quest",  questID = 89559, text = "Reasonless Worship (objective 1)",
          coord = { map = 2437, x = 0.473, y = 0.876 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89559, text = "Turn in: Reasonless Worship", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 89560, text = "A Quiet Farewell",
          coord = { map = 2437, x = 0.473, y = 0.876 } },  -- giver coord: ATT
        { type = "quest",  questID = 89560, text = "A Quiet Farewell (objective 1)",
          coord = { map = 2437, x = 0.463, y = 0.913 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89560, text = "A Quiet Farewell (objective 2)",
          coord = { map = 2437, x = 0.463, y = 0.913 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89560, text = "A Quiet Farewell (objective 3)",
          coord = { map = 2437, x = 0.463, y = 0.913 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89560, text = "A Quiet Farewell (objective 4)",
          coord = { map = 2437, x = 0.463, y = 0.913 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89560, text = "A Quiet Farewell (objective 5)",
          coord = { map = 2437, x = 0.463, y = 0.913 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89560, text = "Turn in: A Quiet Farewell", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.463, y = 0.912 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93047, text = "Butchery Basics (objective 2)",
          coord = { map = 2437, x = 0.455, y = 0.695 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93047, text = "Turn in: Butchery Basics", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.456, y = 0.694 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94867, text = "Turn in: Lost in Atal'Abasi", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "accept", questID = 91069, text = "Vengeance for Tolbani",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- giver coord: ATT
        { type = "accept", questID = 91070, text = "Reclaim the Goods",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- giver coord: ATT
        { type = "accept", questID = 91071, text = "The Menace of Atal'Abasi",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- giver coord: ATT
        { type = "turnin", questID = 92163, text = "Turn in: The Loa of Murlocs", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- APR route coord (converted)
        { type = "accept", questID = 92164, text = "Murloc Madness",
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- giver coord: ATT
        { type = "accept", questID = 92165, text = "Fish Are Food, Not Friends",
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- giver coord: ATT
        { type = "accept", questID = 92166, text = "Following Suit",
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- giver coord: ATT
        { type = "quest",  questID = 92166, text = "Following Suit (objective 1)",
          coord = { map = 2437, x = 0.505, y = 0.626 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92166, text = "Following Suit (objective 2)",
          coord = { map = 2437, x = 0.498, y = 0.599 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92166, text = "Following Suit (objective 3)",
          coord = { map = 2437, x = 0.478, y = 0.562 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92166, text = "Following Suit (objective 4)",
          coord = { map = 2437, x = 0.478, y = 0.562 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92164, text = "Murloc Madness (objective 1)",
          coord = { map = 2437, x = 0.498, y = 0.595 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92165, text = "Fish Are Food, Not Friends (objective 1)",
          coord = { map = 2437, x = 0.498, y = 0.595 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92164, text = "Turn in: Murloc Madness", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92165, text = "Turn in: Fish Are Food, Not Friends", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92166, text = "Turn in: Following Suit", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- APR route coord (converted)
        { type = "accept", questID = 92167, text = "There Can Be Only One",
          coord = { map = 2437, x = 0.529, y = 0.601 } },  -- giver coord: ATT
        { type = "quest",  questID = 92167, text = "There Can Be Only One (objective 1,2)", useItem = 263446,
          coord = { map = 2437, x = 0.574, y = 0.596 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92167, text = "There Can Be Only One (objective 3)",
          coord = { map = 2437, x = 0.574, y = 0.596 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92167, text = "Turn in: There Can Be Only One", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.529, y = 0.602 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91071, text = "The Menace of Atal'Abasi (objective 1)",
          coord = { map = 2437, x = 0.523, y = 0.659 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [1/6]",
          coord = { map = 2437, x = 0.540, y = 0.663 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [2/6]",
          coord = { map = 2437, x = 0.503, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [3/6]",
          coord = { map = 2437, x = 0.484, y = 0.672 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [4/6]",
          coord = { map = 2437, x = 0.488, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [5/6]",
          coord = { map = 2437, x = 0.505, y = 0.644 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91069, text = "Vengeance for Tolbani (objective 1)",
          coord = { map = 2437, x = 0.515, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91070, text = "Reclaim the Goods (objective 1) [6/6]",
          coord = { map = 2437, x = 0.526, y = 0.623 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91069, text = "Turn in: Vengeance for Tolbani", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91070, text = "Turn in: Reclaim the Goods", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91071, text = "Turn in: The Menace of Atal'Abasi", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "accept", questID = 91556, text = "Loa's Flame",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- giver coord: ATT
        { type = "quest",  questID = 91556, text = "Loa's Flame (objective 1)",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91556, text = "Loa's Flame (objective 2)",
          coord = { map = 2437, x = 0.530, y = 0.627 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91556, text = "Turn in: Loa's Flame",
          coord = { map = 2437, x = 0.531, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89230, text = "A Lover Not a Fighter (objective 1)",
          coord = { map = 2437, x = 0.544, y = 0.732 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89231, text = "A Fighter Not a Lover (objective 1)",
          coord = { map = 2437, x = 0.544, y = 0.732 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89231, text = "A Fighter Not a Lover (objective 2)", useItem = 249231,
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 89230, text = "Turn in: A Lover Not a Fighter", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.444, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89231, text = "Turn in: A Fighter Not a Lover", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.444, y = 0.657 } },  -- APR route coord (converted)
        { type = "accept", questID = 89233, text = "Love Triangle",
          coord = { map = 2437, x = 0.444, y = 0.657 } },  -- giver coord: ATT
        { type = "quest",  questID = 89233, text = "Love Triangle (objective 1)",
          coord = { map = 2437, x = 0.444, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89233, text = "Turn in: Love Triangle", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.444, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91206, text = "Turn in: Loa Disturbance", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2536, x = 0.915, y = 0.178 } },  -- APR route coord (converted)
        { type = "accept", questID = 87254, text = "Curse Cleanse",
          coord = { map = 2437, x = 0.405, y = 0.494 } },  -- giver coord: ATT
        { type = "accept", questID = 87256, text = "Alternative Medicine",
          coord = { map = 2437, x = 0.405, y = 0.494 } },  -- giver coord: ATT
        { type = "quest",  questID = 87254, text = "Curse Cleanse (objective 1)",
          coord = { map = 2437, x = 0.424, y = 0.478 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87256, text = "Alternative Medicine (objective 1)",
          coord = { map = 2437, x = 0.424, y = 0.478 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87254, text = "Curse Cleanse (objective 2)",
          coord = { map = 2536, x = 0.914, y = 0.173 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87254, text = "Turn in: Curse Cleanse", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.915, y = 0.178 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87256, text = "Turn in: Alternative Medicine", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.915, y = 0.178 } },  -- APR route coord (converted)
        { type = "accept", questID = 87267, text = "Demands Unmet",
          coord = { map = 2437, x = 0.405, y = 0.494 } },  -- giver coord: ATT
        { type = "quest",  questID = 87267, text = "Demands Unmet (objective 1)",
          coord = { map = 2437, x = 0.389, y = 0.448 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87267, text = "Demands Unmet (objective 2)",
          coord = { map = 2437, x = 0.388, y = 0.449 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87267, text = "Demands Unmet (objective 3)",
          coord = { map = 2437, x = 0.394, y = 0.449 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87267, text = "Turn in: Demands Unmet", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2536, x = 0.915, y = 0.178 } },  -- APR route coord (converted)
        { type = "accept", questID = 87268, text = "Required Repentance",
          coord = { map = 2437, x = 0.405, y = 0.494 } },  -- giver coord: ATT
        { type = "quest",  questID = 87268, text = "Required Repentance (objective 1)",
          coord = { map = 2536, x = 0.918, y = 0.106 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87268, text = "Turn in: Required Repentance", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.915, y = 0.178 } },  -- APR route coord (converted)
        { type = "accept", questID = 87317, text = "Denial Denied",
          coord = { map = 2437, x = 0.405, y = 0.494 } },  -- giver coord: ATT
        { type = "quest",  questID = 87317, text = "Denial Denied (objective 1)",
          coord = { map = 2536, x = 0.914, y = 0.174 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87317, text = "Denial Denied (objective 2)",
          coord = { map = 2437, x = 0.389, y = 0.449 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87317, text = "Denial Denied (objective 3)",
          coord = { map = 2437, x = 0.389, y = 0.448 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87317, text = "Turn in: Denial Denied", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.388, y = 0.449 } },  -- APR route coord (converted)
        { type = "accept", questID = 92531, text = "The Medicine Loa's Shrine",
          coord = { map = 2437, x = 0.388, y = 0.449 } },  -- giver coord: ATT
        { type = "accept", questID = 93667, text = "Camp Stonewash",
          coord = { map = 2437, x = 0.442, y = 0.336 } },  -- giver coord: ATT
        { type = "accept", questID = 93575, text = "Maisara Caverns: Maisara Hungers",
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- APR route coord (converted)
        { type = "accept", questID = 91040, text = "Vexatious Vilebranch",
          coord = { map = 2437, x = 0.338, y = 0.336 } },  -- giver coord: ATT
        { type = "quest",  questID = 91040, text = "Vexatious Vilebranch (objective 1)",
          coord = { map = 2437, x = 0.336, y = 0.336 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91040, text = "Turn in: Vexatious Vilebranch",
          coord = { map = 2437, x = 0.336, y = 0.328 } },  -- APR route coord (converted)
        { type = "accept", questID = 93093, text = "Gnarldin Trophies",
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- giver coord: ATT
        { type = "accept", questID = 93094, text = "Scavenged Victory",
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- giver coord: ATT
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [1/6]",
          coord = { map = 2437, x = 0.284, y = 0.350 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [2/6]",
          coord = { map = 2437, x = 0.290, y = 0.364 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [3/6]",
          coord = { map = 2437, x = 0.285, y = 0.383 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [4/6]",
          coord = { map = 2437, x = 0.281, y = 0.370 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [5/6]",
          coord = { map = 2437, x = 0.268, y = 0.362 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93094, text = "Scavenged Victory (objective 1) [6/6]",
          coord = { map = 2437, x = 0.276, y = 0.351 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93093, text = "Gnarldin Trophies (objective 1)",
          coord = { map = 2437, x = 0.282, y = 0.358 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93093, text = "Turn in: Gnarldin Trophies", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93094, text = "Turn in: Scavenged Victory", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- APR route coord (converted)
        { type = "accept", questID = 93095, text = "Bitter Fury",
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- giver coord: ATT
        { type = "quest",  questID = 93095, text = "Bitter Fury (objective 1)",
          coord = { map = 2437, x = 0.256, y = 0.375 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93095, text = "Bitter Fury (objective 2)",
          coord = { map = 2437, x = 0.259, y = 0.375 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93095, text = "Turn in: Bitter Fury", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- APR route coord (converted)
        { type = "accept", questID = 93096, text = "Amani Honor",
          coord = { map = 2437, x = 0.289, y = 0.335 } },  -- giver coord: ATT
        { type = "quest",  questID = 93096, text = "Amani Honor (objective 1)",
          coord = { map = 2437, x = 0.293, y = 0.417 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93096, text = "Amani Honor (objective 2)",
          coord = { map = 2437, x = 0.293, y = 0.417 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88985, text = "Turn in: Recuperating Returns", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.284, y = 0.273 } },  -- APR route coord (converted); only if warband lacks achievement 42045
        { type = "accept", questID = 88986, text = "Blind the Bandits",
          coord = { map = 2437, x = 0.284, y = 0.273 } },  -- giver coord: ATT
        { type = "accept", questID = 88987, text = "Salvaged Sabotage",
          coord = { map = 2437, x = 0.284, y = 0.273 } },  -- giver coord: ATT
        { type = "quest",  questID = 88986, text = "Blind the Bandits (objective 1,2)", useItem = 238962,
          coord = { map = 2437, x = 0.298, y = 0.292 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88987, text = "Salvaged Sabotage (objective 1)",
          coord = { map = 2437, x = 0.298, y = 0.292 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88986, text = "Turn in: Blind the Bandits", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88987, text = "Turn in: Salvaged Sabotage", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- APR route coord (converted)
        { type = "accept", questID = 88988, text = "The Artisan's Apprentice",
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- giver coord: ATT
        { type = "quest",  questID = 88988, text = "The Artisan's Apprentice (objective 1)",
          coord = { map = 2437, x = 0.286, y = 0.276 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88988, text = "The Artisan's Apprentice (objective 2)",
          coord = { map = 2437, x = 0.285, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88988, text = "The Artisan's Apprentice (objective 3)",
          coord = { map = 2437, x = 0.285, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88988, text = "The Artisan's Apprentice (objective 4)",
          coord = { map = 2437, x = 0.285, y = 0.275 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88988, text = "Turn in: The Artisan's Apprentice", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- APR route coord (converted)
        { type = "accept", questID = 88989, text = "Another One Bites the Sawdust",
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- giver coord: ATT
        { type = "quest",  questID = 88989, text = "Another One Bites the Sawdust (objective 1)",
          coord = { map = 2437, x = 0.285, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88989, text = "Another One Bites the Sawdust (objective 2,3)",
          coord = { map = 2437, x = 0.317, y = 0.299 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88989, text = "Turn in: Another One Bites the Sawdust", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.284, y = 0.275 } },  -- APR route coord (converted)
        { type = "accept", questID = 91406, text = "Far from the Hinterlands",
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- giver coord: ATT
        { type = "accept", questID = 93178, text = "A Quiet Walk Interrupted",
          coord = { map = 2437, x = 0.368, y = 0.251 } },  -- giver coord: ATT
        { type = "quest",  questID = 91406, text = "Far from the Hinterlands (objective 1) [1/3]",
          coord = { map = 2437, x = 0.371, y = 0.262 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93178, text = "A Quiet Walk Interrupted (objective 1)",
          coord = { map = 2437, x = 0.384, y = 0.267 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91406, text = "Far from the Hinterlands (objective 1) [2/3]",
          coord = { map = 2437, x = 0.371, y = 0.235 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91406, text = "Far from the Hinterlands (objective 1) [3/3]",
          coord = { map = 2437, x = 0.381, y = 0.241 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91406, text = "Turn in: Far from the Hinterlands", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- APR route coord (converted)
        { type = "accept", questID = 91407, text = "The Eye of the Loa",
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- giver coord: ATT
        { type = "quest",  questID = 91407, text = "The Eye of the Loa (objective 1)",
          coord = { map = 2437, x = 0.360, y = 0.248 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91407, text = "The Eye of the Loa (objective 2)",
          coord = { map = 2437, x = 0.378, y = 0.246 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91407, text = "Turn in: The Eye of the Loa", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- APR route coord (converted)
        { type = "accept", questID = 91563, text = "Halazzi's Hunt",
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- giver coord: ATT
        { type = "turnin", questID = 91563, text = "Turn in: Halazzi's Hunt", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- APR route coord (converted)
        { type = "accept", questID = 91403, text = "Probable Paralytic",
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- giver coord: ATT
        { type = "accept", questID = 91404, text = "A Most Vile Venom",
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- giver coord: ATT
        { type = "quest",  questID = 91404, text = "A Most Vile Venom (objective 1)",
          coord = { map = 2437, x = 0.403, y = 0.357 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91404, text = "A Most Vile Venom (objective 2)",
          coord = { map = 2437, x = 0.404, y = 0.360 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93178, text = "A Quiet Walk Interrupted (objective 2)",
          coord = { map = 2437, x = 0.409, y = 0.309 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93178, text = "A Quiet Walk Interrupted (objective 3)",
          coord = { map = 2437, x = 0.415, y = 0.317 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93178, text = "A Quiet Walk Interrupted (objective 4)",
          coord = { map = 2437, x = 0.432, y = 0.324 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93178, text = "A Quiet Walk Interrupted (objective 5)",
          coord = { map = 2437, x = 0.458, y = 0.340 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91403, text = "Probable Paralytic (objective 1)",
          coord = { map = 2437, x = 0.390, y = 0.311 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91403, text = "Turn in: Probable Paralytic", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91404, text = "Turn in: A Most Vile Venom", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- APR route coord (converted)
        { type = "accept", questID = 91405, text = "Validating the Venom",
          coord = { map = 2437, x = 0.322, y = 0.316 } },  -- giver coord: ATT
        { type = "turnin", questID = 93178, text = "Turn in: A Quiet Walk Interrupted", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.368, y = 0.251 } },  -- APR route coord (converted)
        { type = "accept", questID = 93179, text = "Childlike Devotion",
          coord = { map = 2437, x = 0.368, y = 0.251 } },  -- giver coord: ATT
        { type = "quest",  questID = 93179, text = "Childlike Devotion (objective 1)",
          coord = { map = 2437, x = 0.368, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91405, text = "Validating the Venom (objective 1)",
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91405, text = "Validating the Venom (objective 2)",
          coord = { map = 2437, x = 0.372, y = 0.235 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91405, text = "Validating the Venom (objective 3)",
          coord = { map = 2437, x = 0.363, y = 0.250 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91405, text = "Turn in: Validating the Venom", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- APR route coord (converted)
        { type = "accept", questID = 91408, text = "Seeking Shadra",
          coord = { map = 2437, x = 0.361, y = 0.248 } },  -- giver coord: ATT
        { type = "quest",  questID = 91408, text = "Seeking Shadra (objective 1)",
          coord = { map = 2437, x = 0.397, y = 0.231 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91408, text = "Seeking Shadra (objective 2)",
          coord = { map = 2437, x = 0.391, y = 0.223 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91408, text = "Turn in: Seeking Shadra", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.392, y = 0.223 } },  -- APR route coord (converted)
        { type = "accept", questID = 91630, text = "Stolen Sight",
          coord = { map = 2437, x = 0.391, y = 0.223 } },  -- giver coord: ATT
        { type = "quest",  questID = 91630, text = "Stolen Sight (objective 1)",
          coord = { map = 2437, x = 0.388, y = 0.216 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91630, text = "Turn in: Stolen Sight", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.391, y = 0.223 } },  -- APR route coord (converted)
        { type = "accept", questID = 91409, text = "Dreaming of Spiders",
          coord = { map = 2437, x = 0.391, y = 0.223 } },  -- giver coord: ATT
        { type = "quest",  questID = 91409, text = "Dreaming of Spiders (objective 1)",
          coord = { map = 2437, x = 0.385, y = 0.225 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91409, text = "Dreaming of Spiders (objective 2)",
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91409, text = "Turn in: Dreaming of Spiders", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.387, y = 0.227 } },  -- APR route coord (converted)
        { type = "accept", questID = 91411, text = "Maisara Caverns: Deep in Maisara",
          coord = { map = 2437, x = 0.388, y = 0.227 } },  -- giver coord: ATT
        { type = "turnin", questID = 93667, text = "Turn in: Camp Stonewash", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.463, y = 0.262 } },  -- APR route coord (converted)
        { type = "accept", questID = 90481, text = "I Have a Permit",
          coord = { map = 2437, x = 0.463, y = 0.261 } },  -- giver coord: ATT
        { type = "quest",  questID = 93179, text = "Childlike Devotion (objective 2)",
          coord = { map = 2437, x = 0.523, y = 0.322 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93179, text = "Turn in: Childlike Devotion", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.523, y = 0.322 } },  -- APR route coord (converted)
        { type = "accept", questID = 93180, text = "Shrine Preparations",
          coord = { map = 2437, x = 0.523, y = 0.322 } },  -- giver coord: ATT
        { type = "quest",  questID = 93180, text = "Shrine Preparations (objective 1)",
          coord = { map = 2437, x = 0.508, y = 0.314 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93180, text = "Shrine Preparations (objective 2)",
          coord = { map = 2437, x = 0.514, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93180, text = "Shrine Preparations (objective 3,4,5)",
          coord = { map = 2437, x = 0.529, y = 0.313 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93180, text = "Turn in: Shrine Preparations", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.514, y = 0.306 } },  -- APR route coord (converted)
        { type = "accept", questID = 93181, text = "Temple and a Teapot",
          coord = { map = 2437, x = 0.514, y = 0.306 } },  -- giver coord: ATT
        { type = "quest",  questID = 93181, text = "Temple and a Teapot (objective 1)",
          coord = { map = 2437, x = 0.472, y = 0.245 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93181, text = "Temple and a Teapot (objective 2)",
          coord = { map = 2437, x = 0.523, y = 0.321 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93181, text = "Temple and a Teapot (objective 3)",
          coord = { map = 2437, x = 0.523, y = 0.320 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93181, text = "Turn in: Temple and a Teapot", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.523, y = 0.321 } },  -- APR route coord (converted)
        { type = "accept", questID = 93182, text = "Healing Homeward",
          coord = { map = 2437, x = 0.523, y = 0.322 } },  -- giver coord: ATT
        { type = "quest",  questID = 93182, text = "Healing Homeward (objective 1)",
          coord = { map = 2437, x = 0.367, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93182, text = "Turn in: Healing Homeward", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.367, y = 0.251 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90481, text = "I Have a Permit (objective 1)",
          coord = { map = 2437, x = 0.383, y = 0.209 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90481, text = "Turn in: I Have a Permit", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.463, y = 0.261 } },  -- APR route coord (converted)
        { type = "accept", questID = 90483, text = "A Witherbark Story",
          coord = { map = 2437, x = 0.473, y = 0.244 } },  -- giver coord: ATT
        { type = "accept", questID = 90485, text = "Afterthought Artifacts",
          coord = { map = 2437, x = 0.473, y = 0.244 } },  -- giver coord: ATT
        { type = "accept", questID = 90482, text = "Cuisine Connection",
          coord = { map = 2437, x = 0.472, y = 0.246 } },  -- giver coord: ATT
        { type = "quest",  questID = 90483, text = "A Witherbark Story (objective 1) [1/5]",
          coord = { map = 2437, x = 0.471, y = 0.248 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90483, text = "A Witherbark Story (objective 1) [2/5]",
          coord = { map = 2437, x = 0.471, y = 0.253 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90483, text = "A Witherbark Story (objective 1) [3/5]",
          coord = { map = 2437, x = 0.473, y = 0.260 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90483, text = "A Witherbark Story (objective 1) [4/5]",
          coord = { map = 2437, x = 0.473, y = 0.260 } },  -- APR route coord (converted)
        { type = "accept", questID = 90484, text = "Sightseeing Stegadon",
          coord = { map = 2437, x = 0.473, y = 0.261 } },  -- giver coord: ATT
        { type = "quest",  questID = 90483, text = "A Witherbark Story (objective 1) [5/5]",
          coord = { map = 2437, x = 0.479, y = 0.259 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90482, text = "Cuisine Connection (objective 1)",
          coord = { map = 2437, x = 0.498, y = 0.282 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90485, text = "Afterthought Artifacts (objective 3)",
          coord = { map = 2437, x = 0.495, y = 0.278 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90485, text = "Afterthought Artifacts (objective 1)",
          coord = { map = 2437, x = 0.489, y = 0.284 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90485, text = "Afterthought Artifacts (objective 2)",
          coord = { map = 2437, x = 0.484, y = 0.283 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90485, text = "Afterthought Artifacts (objective 4)",
          coord = { map = 2437, x = 0.487, y = 0.287 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90485, text = "Afterthought Artifacts (objective 5)",
          coord = { map = 2437, x = 0.487, y = 0.287 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90482, text = "Cuisine Connection (objective 2,3)",
          coord = { map = 2437, x = 0.490, y = 0.279 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90483, text = "Turn in: A Witherbark Story", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.473, y = 0.244 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90485, text = "Turn in: Afterthought Artifacts", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.473, y = 0.244 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90482, text = "Turn in: Cuisine Connection", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.472, y = 0.246 } },  -- APR route coord (converted)
        { type = "accept", questID = 90486, text = "Dangerous Delicacies",
          coord = { map = 2437, x = 0.472, y = 0.246 } },  -- giver coord: ATT
        { type = "quest",  questID = 90486, text = "Dangerous Delicacies (objective 1)",
          coord = { map = 2437, x = 0.471, y = 0.245 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90486, text = "Dangerous Delicacies (objective 2)",
          coord = { map = 2437, x = 0.470, y = 0.246 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90486, text = "Dangerous Delicacies (objective 3)",
          coord = { map = 2437, x = 0.471, y = 0.248 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90486, text = "Dangerous Delicacies (objective 4)",
          coord = { map = 2437, x = 0.471, y = 0.247 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90486, text = "Turn in: Dangerous Delicacies", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.471, y = 0.246 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90484, text = "Sightseeing Stegadon (objective 1)",
          coord = { map = 2437, x = 0.455, y = 0.239 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90484, text = "Sightseeing Stegadon (objective 2)",
          coord = { map = 2437, x = 0.454, y = 0.240 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90484, text = "Turn in: Sightseeing Stegadon", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.473, y = 0.261 } },  -- APR route coord (converted)
        { type = "accept", questID = 90568, text = "Unlikely Friends",
          coord = { map = 2437, x = 0.473, y = 0.244 } },  -- giver coord: ATT
        { type = "turnin", questID = 90568, text = "Turn in: Unlikely Friends", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.383, y = 0.209 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93575, text = "Maisara Caverns: Maisara Hungers (objective 1)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "quest",  questID = 91411, text = "Maisara Caverns: Deep in Maisara (objective 1)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "quest",  questID = 93575, text = "Maisara Caverns: Maisara Hungers (objective 2)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 91411, text = "Turn in: Maisara Caverns: Deep in Maisara",
          coord = { map = 2437, x = 0.388, y = 0.227 } },  -- APR route coord (converted)
        { type = "accept", questID = 91412, text = "Return of the Venom Queen",
          coord = { map = 2437, x = 0.387, y = 0.227 } },  -- giver coord: ATT
        { type = "quest",  questID = 91412, text = "Return of the Venom Queen (objective 1)",
          coord = { map = 2437, x = 0.386, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91412, text = "Return of the Venom Queen (objective 2)",
          coord = { map = 2437, x = 0.386, y = 0.225 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91412, text = "Turn in: Return of the Venom Queen",
          coord = { map = 2437, x = 0.388, y = 0.227 } },  -- APR route coord (converted)
        { type = "accept", questID = 91410, text = "Shared Loa",
          coord = { map = 2437, x = 0.387, y = 0.227 } },  -- giver coord: ATT
        { type = "turnin", questID = 91410, text = "Turn in: Shared Loa", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93575, text = "Turn in: Maisara Caverns: Maisara Hungers", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.441, y = 0.345 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93096, text = "Turn in: Amani Honor", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.443, y = 0.666 } },  -- APR route coord (converted)
        { type = "accept", questID = 92492, text = "Honorin' de Sacrifice",
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- giver coord: ATT
        { type = "accept", questID = 91813, text = "The Spiritpaw",
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- giver coord: ATT
        { type = "turnin", questID = 93257, text = "Turn in: Revantusk at Risk", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.402, y = 0.792 } },  -- APR route coord (converted)
        { type = "accept", questID = 93258, text = "Crab Clues",
          coord = { map = 2437, x = 0.402, y = 0.792 } },  -- giver coord: ATT
        { type = "quest",  questID = 93258, text = "Crab Clues (objective 3)",
          coord = { map = 2437, x = 0.383, y = 0.793 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93258, text = "Crab Clues (objective 1)",
          coord = { map = 2437, x = 0.396, y = 0.801 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93258, text = "Crab Clues (objective 2)",
          coord = { map = 2437, x = 0.388, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93258, text = "Turn in: Crab Clues", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.402, y = 0.792 } },  -- APR route coord (converted)
        { type = "accept", questID = 93260, text = "Caging Crawlers",
          coord = { map = 2437, x = 0.402, y = 0.792 } },  -- giver coord: ATT
        { type = "accept", questID = 93259, text = "Clobbering Crawlers",
          coord = { map = 2437, x = 0.402, y = 0.792 } },  -- giver coord: ATT
        { type = "turnin", questID = 91813, text = "Turn in: The Spiritpaw", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 91747, text = "Not Quite Nalorakk",
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- giver coord: ATT
        { type = "accept", questID = 91748, text = "Too Much Twilight",
          coord = { map = 2437, x = 0.413, y = 0.801 } },  -- giver coord: ATT
        { type = "quest",  questID = 91748, text = "Too Much Twilight (objective 1) [1/4]",
          coord = { map = 2437, x = 0.417, y = 0.810 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91748, text = "Too Much Twilight (objective 1) [2/4]",
          coord = { map = 2437, x = 0.424, y = 0.790 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91748, text = "Too Much Twilight (objective 1) [3/4]",
          coord = { map = 2437, x = 0.429, y = 0.801 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91748, text = "Too Much Twilight (objective 1) [4/4]",
          coord = { map = 2437, x = 0.430, y = 0.828 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91747, text = "Not Quite Nalorakk (objective 1)",
          coord = { map = 2437, x = 0.428, y = 0.807 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91748, text = "Turn in: Too Much Twilight", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.413, y = 0.801 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91747, text = "Turn in: Not Quite Nalorakk", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 91749, text = "It's Just Not Right",
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- giver coord: ATT
        { type = "quest",  questID = 91749, text = "It's Just Not Right (objective 1)",
          coord = { map = 2437, x = 0.443, y = 0.795 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91749, text = "It's Just Not Right (objective 2)",
          coord = { map = 2437, x = 0.445, y = 0.793 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91749, text = "Turn in: It's Just Not Right", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 93734, text = "Precious Trinkets",
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- giver coord: ATT
        { type = "quest",  questID = 93734, text = "Precious Trinkets (objective 1)",
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93734, text = "Precious Trinkets (objective 2)",
          coord = { map = 2437, x = 0.413, y = 0.799 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93734, text = "Turn in: Precious Trinkets", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.414, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 91750, text = "Perils of Trust",
          coord = { map = 2437, x = 0.413, y = 0.801 } },  -- giver coord: ATT
        { type = "quest",  questID = 91750, text = "Perils of Trust (objective 1)",
          coord = { map = 2437, x = 0.439, y = 0.822 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91750, text = "Turn in: Perils of Trust", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.413, y = 0.801 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [1/6]",
          coord = { map = 2437, x = 0.375, y = 0.812 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [2/6]",
          coord = { map = 2437, x = 0.363, y = 0.811 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [3/6]",
          coord = { map = 2437, x = 0.356, y = 0.817 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [4/6]",
          coord = { map = 2437, x = 0.347, y = 0.822 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [5/6]",
          coord = { map = 2437, x = 0.337, y = 0.833 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93260, text = "Caging Crawlers (objective 1) [6/6]",
          coord = { map = 2437, x = 0.322, y = 0.842 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93259, text = "Clobbering Crawlers (objective 1)",
          coord = { map = 2437, x = 0.328, y = 0.834 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93260, text = "Turn in: Caging Crawlers", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.322, y = 0.838 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93259, text = "Turn in: Clobbering Crawlers", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.322, y = 0.838 } },  -- APR route coord (converted)
        { type = "accept", questID = 93261, text = "A Crab of Unusual Size",
          coord = { map = 2437, x = 0.322, y = 0.838 } },  -- giver coord: ATT
        { type = "quest",  questID = 93261, text = "A Crab of Unusual Size (objective 1,2)",
          coord = { map = 2437, x = 0.335, y = 0.859 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93261, text = "Turn in: A Crab of Unusual Size", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.331, y = 0.790 } },  -- APR route coord (converted)
        { type = "accept", questID = 93792, text = "Blessings of the Loa",
          coord = { map = 2437, x = 0.431, y = 0.692 } },  -- giver coord: ATT
        { type = "quest",  questID = 93792, text = "Blessings of the Loa (objective 1)",
          coord = { map = 2437, x = 0.432, y = 0.692 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93792, text = "Turn in: Blessings of the Loa",
          coord = { map = 2437, x = 0.431, y = 0.692 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92492, text = "Turn in: Honorin' de Sacrifice", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.261, y = 0.645 } },  -- APR route coord (converted)
        { type = "accept", questID = 92493, text = "What Remains of Idago",
          coord = { map = 2437, x = 0.261, y = 0.645 } },  -- giver coord: ATT
        { type = "accept", questID = 92495, text = "Disruptin' de Blade",
          coord = { map = 2437, x = 0.261, y = 0.645 } },  -- giver coord: ATT
        { type = "quest",  questID = 92493, text = "What Remains of Idago (objective 1)",
          coord = { map = 2536, x = 0.014, y = 0.987 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92493, text = "What Remains of Idago (objective 2)",
          coord = { map = 2437, x = 0.234, y = 0.604 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92493, text = "What Remains of Idago (objective 3)",
          coord = { map = 2437, x = 0.241, y = 0.597 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92495, text = "Disruptin' de Blade (objective 1,2,3)",
          coord = { map = 2536, x = 0.005, y = 0.904 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92493, text = "Turn in: What Remains of Idago", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92495, text = "Turn in: Disruptin' de Blade", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- APR route coord (converted)
        { type = "accept", questID = 92496, text = "Spears Against de Shadow",
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- giver coord: ATT
        { type = "accept", questID = 92497, text = "Simply Magical",
          coord = { map = 2437, x = 0.212, y = 0.634 } },  -- giver coord: ATT
        { type = "quest",  questID = 92497, text = "Simply Magical (objective 2)",
          coord = { map = 2437, x = 0.205, y = 0.634 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92496, text = "Spears Against de Shadow (objective 1)",
          coord = { map = 2437, x = 0.210, y = 0.642 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92497, text = "Simply Magical (objective 1)",
          coord = { map = 2437, x = 0.208, y = 0.643 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92497, text = "Simply Magical (objective 3) [1/2]",
          coord = { map = 2437, x = 0.212, y = 0.635 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92497, text = "Simply Magical (objective 3) [2/2]",
          coord = { map = 2437, x = 0.212, y = 0.634 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92497, text = "Turn in: Simply Magical", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92496, text = "Turn in: Spears Against de Shadow", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- APR route coord (converted)
        { type = "accept", questID = 92499, text = "The Wisest Leaders Follow",
          coord = { map = 2437, x = 0.226, y = 0.639 } },  -- giver coord: ATT
        { type = "turnin", questID = 92499, text = "Turn in: The Wisest Leaders Follow", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.336, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 93440, text = "Personal History",
          coord = { map = 2437, x = 0.458, y = 0.655 } },  -- giver coord: ATT
        { type = "turnin", questID = 93440, text = "Turn in: Personal History", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2536, x = 0.460, y = 0.475 } },  -- APR route coord (converted)
        { type = "accept", questID = 93432, text = "Swords to Plowshares",
          coord = { map = 2536, x = 0.461, y = 0.475 } },  -- giver coord: ATT
        { type = "accept", questID = 93433, text = "Shrine, Sealed, Delivered",
          coord = { map = 2536, x = 0.462, y = 0.475 } },  -- giver coord: ATT
        { type = "quest",  questID = 93433, text = "Shrine, Sealed, Delivered (objective 3)",
          coord = { map = 2536, x = 0.345, y = 0.670 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93433, text = "Shrine, Sealed, Delivered (objective 2)",
          coord = { map = 2536, x = 0.258, y = 0.670 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93433, text = "Shrine, Sealed, Delivered (objective 1)",
          coord = { map = 2536, x = 0.207, y = 0.136 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93433, text = "Shrine, Sealed, Delivered (objective 4)",
          coord = { map = 2536, x = 0.345, y = 0.232 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93432, text = "Swords to Plowshares (objective 1)",
          coord = { map = 2536, x = 0.335, y = 0.474 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93432, text = "Turn in: Swords to Plowshares", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.453, y = 0.448 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93433, text = "Turn in: Shrine, Sealed, Delivered", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.453, y = 0.448 } },  -- APR route coord (converted)
        { type = "accept", questID = 93436, text = "Hex the Innocent, Disrupt the Guilty",
          coord = { map = 2536, x = 0.452, y = 0.449 } },  -- giver coord: ATT
        { type = "accept", questID = 93435, text = "Four Instigators",
          coord = { map = 2536, x = 0.454, y = 0.447 } },  -- giver coord: ATT
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [1/7]",
          coord = { map = 2536, x = 0.446, y = 0.349 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93435, text = "Four Instigators (objective 2)",
          coord = { map = 2536, x = 0.441, y = 0.318 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 1) [1/3]",
          coord = { map = 2536, x = 0.521, y = 0.192 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [2/7]",
          coord = { map = 2536, x = 0.493, y = 0.187 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [3/7]",
          coord = { map = 2536, x = 0.573, y = 0.205 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [4/7]",
          coord = { map = 2536, x = 0.521, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [5/7]",
          coord = { map = 2536, x = 0.524, y = 0.378 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 3)",
          coord = { map = 2536, x = 0.675, y = 0.472 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [6/7]",
          coord = { map = 2536, x = 0.525, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 2) [7/7]",
          coord = { map = 2536, x = 0.452, y = 0.692 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93435, text = "Four Instigators (objective 1)",
          coord = { map = 2536, x = 0.347, y = 0.804 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 1) [2/3]",
          coord = { map = 2536, x = 0.226, y = 0.807 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93435, text = "Four Instigators (objective 4)",
          coord = { map = 2536, x = 0.080, y = 0.392 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93435, text = "Four Instigators (objective 3)",
          coord = { map = 2536, x = 0.106, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93436, text = "Hex the Innocent, Disrupt the Guilty (objective 1) [3/3]",
          coord = { map = 2536, x = 0.079, y = 0.090 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93435, text = "Turn in: Four Instigators", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.459, y = 0.473 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93436, text = "Turn in: Hex the Innocent, Disrupt the Guilty", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2536, x = 0.459, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 93437, text = "In Their Own Blood",
          coord = { map = 2536, x = 0.459, y = 0.474 } },  -- giver coord: ATT
        { type = "quest",  questID = 93437, text = "In Their Own Blood (objective 1)",
          coord = { map = 2536, x = 0.345, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93437, text = "In Their Own Blood (objective 2)",
          coord = { map = 2536, x = 0.338, y = 0.475 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93437, text = "In Their Own Blood (objective 3)",
          coord = nil },  -- no coord: APR step has none
        { type = "quest",  questID = 93437, text = "In Their Own Blood (objective 4)",
          coord = { map = 2536, x = 0.636, y = 0.473 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93437, text = "Turn in: In Their Own Blood", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2536, x = 0.459, y = 0.475 } },  -- APR route coord (converted)
        -- (APR: grind/continue to level 90 before the next step)
        { type = "accept", questID = 91833, text = "Dirty Deeps",
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- giver coord: ATT
        { type = "turnin", questID = 91833, text = "Turn in: Dirty Deeps", rep = { { factionID = 2696, amount = 10 } },
          coord = { map = 2437, x = 0.449, y = 0.365 } },  -- APR route coord (converted)
        { type = "accept", questID = 91835, text = "Send Dem Home",
          coord = { map = 2437, x = 0.449, y = 0.365 } },  -- giver coord: ATT
        { type = "accept", questID = 91836, text = "Respect de Totem",
          coord = { map = 2437, x = 0.449, y = 0.366 } },  -- giver coord: ATT
        { type = "accept", questID = 91838, text = "De Vile Diminished",
          coord = { map = 2437, x = 0.449, y = 0.365 } },  -- giver coord: ATT
        { type = "quest",  questID = 91838, text = "De Vile Diminished (objective 1) [1/5]",
          coord = { map = 2437, x = 0.465, y = 0.375 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91838, text = "De Vile Diminished (objective 1) [2/5]",
          coord = { map = 2437, x = 0.461, y = 0.393 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91838, text = "De Vile Diminished (objective 1) [3/5]",
          coord = { map = 2437, x = 0.472, y = 0.398 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91838, text = "De Vile Diminished (objective 1) [4/5]",
          coord = { map = 2437, x = 0.464, y = 0.407 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91838, text = "De Vile Diminished (objective 1) [5/5]",
          coord = { map = 2437, x = 0.455, y = 0.422 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91835, text = "Send Dem Home (objective 1)", useItem = 248745, useItemVerified = false,
          coord = { map = 2437, x = 0.461, y = 0.404 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91836, text = "Respect de Totem (objective 1)",
          coord = { map = 2437, x = 0.461, y = 0.404 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91835, text = "Turn in: Send Dem Home", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91836, text = "Turn in: Respect de Totem", rep = { { factionID = 2696, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 91838, text = "Turn in: De Vile Diminished", rep = { { factionID = 2696, amount = 50 } },
          coord = { map = 2437, x = 0.472, y = 0.412 } },  -- APR route coord (converted)
        { type = "accept", questID = 91840, text = "One Will Not Rise",
          coord = { map = 2437, x = 0.471, y = 0.412 } },  -- giver coord: ATT
        { type = "quest",  questID = 91840, text = "One Will Not Rise (objective 1)",
          coord = { map = 2437, x = 0.484, y = 0.431 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91840, text = "Turn in: One Will Not Rise", rep = { { factionID = 2696, amount = 100 } },
          coord = { map = 2437, x = 0.386, y = 0.224 } },  -- APR route coord (converted)
        { type = "accept", questID = 91839, text = "Sacrifice Denied",
          coord = { map = 2437, x = 0.385, y = 0.223 } },  -- giver coord: ATT
        { type = "quest",  questID = 91839, text = "Sacrifice Denied (objective 1)",
          coord = { map = 2437, x = 0.373, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91839, text = "Turn in: Sacrifice Denied", rep = { { factionID = 2696, amount = 250 } },
          coord = { map = 2437, x = 0.373, y = 0.251 } },  -- APR route coord (converted)
    },
}
