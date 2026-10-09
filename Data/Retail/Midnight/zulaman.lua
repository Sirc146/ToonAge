-- ToonAge guide data: Midnight (12.x) Zul'Aman: MAIN CAMPAIGN storyline only
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Midnight leveling 80-90.
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-ZulAman-Campaign-Only"
--    in Routes/Midnight/Midnight-Zulaman.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 47 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 47 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 0.14 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: campaign only.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2437 Zul'Aman, 2536 Atal'Aman
--  * Zul'Aman = uiMap 2437; Atal'Aman (outdoor) = 2536.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_zulaman_campaign"] = {
    id = "midnight_zulaman_campaign", title = "Midnight: Zul'Aman (Campaign)", expansion = "midnight",
    zone = 2437, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_voidstorm_campaign",
    steps = {
        -- (APR: grind/continue to level 83 before the next step - skipped when the warband has achievement 42045)
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
    },
}
