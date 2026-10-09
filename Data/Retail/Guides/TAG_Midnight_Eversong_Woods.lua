-- ToonAge guide data: Midnight (12.x) Eversong Woods: MAIN CAMPAIGN storyline only (chapter 1)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Midnight leveling 80-90.
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2393-Eversong-Woods-Campaign-Only"
--    in Routes/Midnight/Midnight-Eversong-Woods.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 41 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 37 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 0.09 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: campaign only.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2424 Isle of Quel'Danas, 2579 Wartha'nan Crypts
--  * Eversong Woods = uiMap 2395 (zone); Silvermoon City = uiMap 2393 (city, child of 2395). Regenerated 2026-10-09 PT: replaces the
--    2026-10-08 version (which used fitted coords); 90493 "The Heart of Tranquillien" is included (APR step order).
--  * Scenario "Void Walk With Me" (86636) runs in instance map 2502 (Shadow Enclave); interior steps have coord = nil.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_eversong_campaign"] = {
    id = "midnight_eversong_campaign", title = "Midnight: Eversong Woods (Campaign)", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90, order = 10,
    nextGuide = "midnight_harandar_campaign",
    sideGuide = "midnight_arators_journey", -- offered after Eversong; the campaign continues to Harandar
    steps = {
        { type = "accept", questID = 86733, text = "Silvermoon Negotiations",
          coord = { map = 2424, x = 0.525, y = 0.882 } },  -- giver coord: ATT
        { type = "quest",  questID = 86733, text = "Silvermoon Negotiations (objective 1)",
          coord = { map = 2393, x = 0.457, y = 0.677 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86733, text = "Turn in: Silvermoon Negotiations",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 86734, text = "Diplomacy",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 86734, text = "Diplomacy (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86734, text = "Turn in: Diplomacy",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 86735, text = "Paved in Ash", faction = "Alliance",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 86736, text = "Paved in Ash", faction = "Horde",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 7)", faction = "Alliance",
          coord = { map = 2393, x = 0.457, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 7)", faction = "Horde",
          coord = { map = 2393, x = 0.457, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 4)", faction = "Alliance",
          coord = { map = 2393, x = 0.508, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 4)", faction = "Horde",
          coord = { map = 2393, x = 0.508, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 1)", faction = "Alliance",
          coord = { map = 2393, x = 0.565, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 1)", faction = "Horde",
          coord = { map = 2393, x = 0.565, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 3)", faction = "Alliance",
          coord = { map = 2393, x = 0.510, y = 0.712 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 3)", faction = "Horde",
          coord = { map = 2393, x = 0.510, y = 0.712 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 5)", faction = "Horde",
          coord = { map = 2393, x = 0.525, y = 0.782 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 2)", faction = "Alliance",
          coord = { map = 2393, x = 0.526, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 2)", faction = "Horde",
          coord = { map = 2393, x = 0.526, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86735, text = "Paved in Ash (objective 6)", faction = "Alliance",
          coord = { map = 2393, x = 0.602, y = 0.703 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86736, text = "Paved in Ash (objective 6)", faction = "Horde",
          coord = { map = 2393, x = 0.691, y = 0.676 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86735, text = "Turn in: Paved in Ash", faction = "Alliance",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86736, text = "Turn in: Paved in Ash", faction = "Horde",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 86737, text = "Fair Breeze, Light Bloom",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 86737, text = "Fair Breeze, Light Bloom (objective 1)",
          coord = { map = 2393, x = 0.453, y = 0.705 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86737, text = "Fair Breeze, Light Bloom (objective 3)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86737, text = "Turn in: Fair Breeze, Light Bloom",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "accept", questID = 86738, text = "Sharpmaw",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86739, text = "Fairbreeze Favors",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86740, text = "Displaced Denizens",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "quest",  questID = 86738, text = "Sharpmaw (objective 1)",
          coord = { map = 2395, x = 0.458, y = 0.479 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86738, text = "Sharpmaw (objective 2)",
          coord = { map = 2395, x = 0.458, y = 0.479 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 2) [1/3]",
          coord = { map = 2395, x = 0.476, y = 0.464 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 1) [1/3]",
          coord = { map = 2395, x = 0.472, y = 0.463 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86739, text = "Fairbreeze Favors (objective 4) [1/3]",
          coord = { map = 2395, x = 0.465, y = 0.459 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 1) [2/3]",
          coord = { map = 2395, x = 0.459, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86739, text = "Fairbreeze Favors (objective 4) [2/3]",
          coord = { map = 2395, x = 0.456, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 1) [3/3]",
          coord = { map = 2395, x = 0.455, y = 0.460 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 2) [2/3]",
          coord = { map = 2395, x = 0.456, y = 0.467 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86739, text = "Fairbreeze Favors (objective 4) [3/3]",
          coord = { map = 2395, x = 0.447, y = 0.450 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86740, text = "Displaced Denizens (objective 2) [3/3]",
          coord = { map = 2395, x = 0.448, y = 0.440 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86739, text = "Fairbreeze Favors (objective 1,2,3)",
          coord = { map = 2395, x = 0.458, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86740, text = "Turn in: Displaced Denizens",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86738, text = "Turn in: Sharpmaw",
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86739, text = "Turn in: Fairbreeze Favors",
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "accept", questID = 86741, text = "Lightbloom Looming",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 1)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 2)",
          coord = { map = 2395, x = 0.417, y = 0.471 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 3,4)",
          coord = { map = 2395, x = 0.399, y = 0.489 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 5)",
          coord = { map = 2395, x = 0.397, y = 0.506 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 6)",
          coord = { map = 2395, x = 0.396, y = 0.515 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86741, text = "Turn in: Lightbloom Looming",
          coord = { map = 2395, x = 0.397, y = 0.515 } },  -- APR route coord (converted)
        { type = "accept", questID = 86743, text = "Trimming the Lightbloom",
          coord = { map = 2395, x = 0.397, y = 0.516 } },  -- giver coord: ATT
        { type = "accept", questID = 86742, text = "Curious Cultivation",
          coord = { map = 2395, x = 0.397, y = 0.516 } },  -- giver coord: ATT
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 1) [1/3]",
          coord = { map = 2395, x = 0.407, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 1) [2/3]",
          coord = { map = 2395, x = 0.401, y = 0.554 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86743, text = "Trimming the Lightbloom (objective 1)",
          coord = { map = 2395, x = 0.401, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 1) [3/3]",
          coord = { map = 2395, x = 0.423, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 2)",
          coord = { map = 2395, x = 0.440, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 3,4)",
          coord = { map = 2395, x = 0.439, y = 0.564 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86743, text = "Turn in: Trimming the Lightbloom",
          coord = nil, noArrow = true },  -- no coord: APR step has none
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 5)",
          coord = { map = 2395, x = 0.458, y = 0.553 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86742, text = "Turn in: Curious Cultivation",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- APR route coord (converted)
        { type = "accept", questID = 86744, text = "Seeking Truth",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- giver coord: ATT
        { type = "quest",  questID = 86744, text = "Seeking Truth (objective 1)",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86744, text = "Seeking Truth (objective 2)",
          coord = { map = 2395, x = 0.463, y = 0.551 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86744, text = "Turn in: Seeking Truth",
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "accept", questID = 86745, text = "Silvermoon Must Know",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest",  questID = 86745, text = "Silvermoon Must Know (objective 1)",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86745, text = "Turn in: Silvermoon Must Know",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86621, text = "The Wayward Magister",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 2)",
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 1)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 3)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 4)",
          coord = { map = 2395, x = 0.477, y = 0.696 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86621, text = "Turn in: The Wayward Magister",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86623, text = "Appeal to the Void",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "accept", questID = 86624, text = "Rational Explanation",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [10%]",
          coord = { map = 2395, x = 0.481, y = 0.680 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [25%]",
          coord = { map = 2395, x = 0.485, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [35%]",
          coord = { map = 2395, x = 0.478, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 1) [1/4]",
          coord = { map = 2395, x = 0.477, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [50%]",
          coord = { map = 2395, x = 0.477, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [65%]",
          coord = { map = 2395, x = 0.489, y = 0.665 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 1) [2/4]",
          coord = { map = 2395, x = 0.489, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [75%]",
          coord = { map = 2395, x = 0.487, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2) [85%]",
          coord = { map = 2395, x = 0.491, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 1) [3/4]",
          coord = { map = 2395, x = 0.493, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 2)",
          coord = { map = 2395, x = 0.494, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 1) [4/4]",
          coord = { map = 2395, x = 0.489, y = 0.696 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86623, text = "Appeal to the Void (objective 1)",
          coord = { map = 2395, x = 0.488, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86623, text = "Appeal to the Void (objective 2)",
          coord = { map = 2395, x = 0.467, y = 0.715 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86623, text = "Appeal to the Void (objective 3)",
          coord = { map = 2395, x = 0.454, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 3)",
          coord = { map = 2395, x = 0.490, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86624, text = "Rational Explanation (objective 4)",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86624, text = "Turn in: Rational Explanation",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86623, text = "Turn in: Appeal to the Void",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 90907, text = "The First to Know",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest",  questID = 90907, text = "The First to Know (objective 1)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90907, text = "The First to Know (objective 2)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90907, text = "The First to Know (objective 3)",
          coord = { map = 2395, x = 0.471, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90907, text = "The First to Know (objective 4)",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90907, text = "Turn in: The First to Know",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 86622, text = "Chance Meeting",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- giver coord: ATT
        { type = "quest",  questID = 86622, text = "Chance Meeting (objective 1)",
          coord = { map = 2395, x = 0.467, y = 0.639 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86622, text = "Chance Meeting (objective 2)",
          coord = { map = 2395, x = 0.467, y = 0.637 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86622, text = "Chance Meeting (objective 3)",
          coord = { map = 2395, x = 0.467, y = 0.637 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86622, text = "Turn in: Chance Meeting",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "accept", questID = 86626, text = "The Ransacked Lab",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest",  questID = 86626, text = "The Ransacked Lab (objective 1) [1/3]",
          coord = { map = 2395, x = 0.477, y = 0.699 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86626, text = "The Ransacked Lab (objective 1) [2/3]",
          coord = { map = 2395, x = 0.476, y = 0.698 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86626, text = "The Ransacked Lab (objective 1) [3/3]",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86626, text = "The Ransacked Lab (objective 2)",
          coord = { map = 2395, x = 0.478, y = 0.699 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86626, text = "Turn in: The Ransacked Lab",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86632, text = "The Battle for Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "accept", questID = 90509, text = "The Traitors of Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "accept", questID = 90493, text = "The Heart of Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "quest",  questID = 90509, text = "The Traitors of Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.476, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90509, text = "The Traitors of Tranquillien (objective 3)",
          coord = { map = 2395, x = 0.494, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90509, text = "The Traitors of Tranquillien (objective 2)",
          coord = { map = 2395, x = 0.477, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86632, text = "The Battle for Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.484, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90493, text = "The Heart of Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.484, y = 0.675 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86632, text = "Turn in: The Battle for Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90493, text = "Turn in: The Heart of Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90509, text = "Turn in: The Traitors of Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 90494, text = "The Missing Magister",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- giver coord: ATT
        { type = "quest",  questID = 90494, text = "The Missing Magister (objective 1)",
          coord = { map = 2395, x = 0.473, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90494, text = "The Missing Magister (objective 2)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90494, text = "The Missing Magister (objective 3)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90494, text = "The Missing Magister (objective 4)",
          coord = { map = 2395, x = 0.471, y = 0.684 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90494, text = "Turn in: The Missing Magister",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86781, text = "Face the Past",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest",  questID = 86781, text = "Face the Past (objective 1)",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86781, text = "Face the Past (objective 2)",
          coord = { map = 2395, x = 0.371, y = 0.740 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86781, text = "Turn in: Face the Past",
          coord = { map = 2395, x = 0.370, y = 0.740 } },  -- APR route coord (converted)
        { type = "accept", questID = 86634, text = "The Past Keeps Watch",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- giver coord: ATT
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [1/6]",
          coord = { map = 2395, x = 0.384, y = 0.726 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [2/6]",
          coord = { map = 2395, x = 0.385, y = 0.737 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [3/6]",
          coord = { map = 2395, x = 0.386, y = 0.750 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [4/6]",
          coord = { map = 2395, x = 0.381, y = 0.752 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [5/6]",
          coord = { map = 2395, x = 0.374, y = 0.758 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86634, text = "The Past Keeps Watch (objective 1) [6/6]",
          coord = { map = 2395, x = 0.361, y = 0.754 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86634, text = "Turn in: The Past Keeps Watch",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 86633, text = "Comprehend the Void",
          coord = { map = 2395, x = 0.370, y = 0.740 } },  -- giver coord: ATT
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 2)",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 1)",
          coord = { map = 2395, x = 0.374, y = 0.747 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 3) [1/4]",
          coord = { map = 2395, x = 0.375, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 3) [2/4]",
          coord = { map = 2395, x = 0.371, y = 0.749 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 3) [3/4]",
          coord = { map = 2395, x = 0.373, y = 0.744 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86633, text = "Comprehend the Void (objective 3) [4/4]",
          coord = { map = 2395, x = 0.376, y = 0.746 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86633, text = "Turn in: Comprehend the Void",
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86635, text = "To Deatholme",
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 86635, text = "To Deatholme (objective 1,2)",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86635, text = "Turn in: To Deatholme",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "accept", questID = 86636, text = "Void Walk With Me",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- giver coord: ATT
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 1)",
          coord = nil, noArrow = true },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 2)",
          coord = nil, noArrow = true },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 3)",
          coord = nil, noArrow = true },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "turnin", questID = 86636, text = "Turn in: Void Walk With Me",
          coord = { map = 2395, x = 0.447, y = 0.852 } },  -- APR route coord (converted)
        { type = "accept", questID = 86637, text = "Anything but Reprieve",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- giver coord: ATT
        { type = "quest",  questID = 86637, text = "Anything but Reprieve (objective 1)",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86637, text = "Turn in: Anything but Reprieve",
          coord = { map = 2395, x = 0.527, y = 0.616 } },  -- APR route coord (converted)
        { type = "accept", questID = 86639, text = "What's Left",
          coord = { map = 2395, x = 0.527, y = 0.616 } },  -- giver coord: ATT
        { type = "accept", questID = 86638, text = "Choking Tendrils",
          coord = { map = 2395, x = 0.526, y = 0.616 } },  -- giver coord: ATT
        { type = "quest",  questID = 86639, text = "What's Left (objective 2)",
          coord = { map = 2395, x = 0.535, y = 0.594 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86639, text = "What's Left (objective 3)",
          coord = { map = 2395, x = 0.547, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86639, text = "What's Left (objective 5)",
          coord = { map = 2395, x = 0.548, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86639, text = "What's Left (objective 4)",
          coord = { map = 2395, x = 0.559, y = 0.574 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86638, text = "Choking Tendrils (objective 1)",
          coord = { map = 2395, x = 0.550, y = 0.593 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86639, text = "What's Left (objective 1)",
          coord = { map = 2395, x = 0.550, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86639, text = "Turn in: What's Left",
          coord = { map = 2395, x = 0.536, y = 0.546 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86638, text = "Turn in: Choking Tendrils",
          coord = { map = 2395, x = 0.535, y = 0.546 } },  -- APR route coord (converted)
        { type = "accept", questID = 86640, text = "Premonition",
          coord = { map = 2395, x = 0.535, y = 0.546 } },  -- giver coord: ATT
        { type = "turnin", questID = 86640, text = "Turn in: Premonition",
          coord = { map = 2395, x = 0.592, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 86641, text = "Old Scars",
          coord = { map = 2395, x = 0.592, y = 0.510 } },  -- giver coord: ATT
        { type = "accept", questID = 86642, text = "A Foe Unseen",
          coord = { map = 2395, x = 0.591, y = 0.510 } },  -- giver coord: ATT
        { type = "quest",  questID = 86642, text = "A Foe Unseen (objective 1) [1/5]",
          coord = { map = 2395, x = 0.606, y = 0.517 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86642, text = "A Foe Unseen (objective 1) [2/5]",
          coord = { map = 2395, x = 0.606, y = 0.524 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86642, text = "A Foe Unseen (objective 1) [3/5]",
          coord = { map = 2395, x = 0.630, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86642, text = "A Foe Unseen (objective 1) [4/5]",
          coord = { map = 2395, x = 0.621, y = 0.503 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86642, text = "A Foe Unseen (objective 1) [5/5]",
          coord = { map = 2395, x = 0.633, y = 0.484 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86641, text = "Old Scars (objective 1)",
          coord = { map = 2395, x = 0.622, y = 0.497 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86641, text = "Turn in: Old Scars",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86642, text = "Turn in: A Foe Unseen",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 86643, text = "Following the Root",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- giver coord: ATT
        { type = "quest",  questID = 86643, text = "Following the Root (objective 2)",
          coord = { map = 2395, x = 0.645, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 1)",
          coord = { map = 2395, x = 0.568, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 3) [1/4]",
          coord = { map = 2395, x = 0.565, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 3) [2/4]",
          coord = { map = 2395, x = 0.565, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 3) [3/4]",
          coord = { map = 2395, x = 0.556, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 3) [4/4]",
          coord = { map = 2395, x = 0.553, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86643, text = "Following the Root (objective 4)",
          coord = { map = 2395, x = 0.551, y = 0.655 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86643, text = "Turn in: Following the Root",
          coord = { map = 2395, x = 0.548, y = 0.656 } },  -- APR route coord (converted)
        { type = "accept", questID = 86644, text = "Gods Before Us",
          coord = { map = 2579, x = 0.437, y = 0.301 } },  -- giver coord: ATT
        { type = "quest",  questID = 86644, text = "Gods Before Us (objective 1)",
          coord = { map = 2395, x = 0.548, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86644, text = "Gods Before Us (objective 2)",
          coord = { map = 2395, x = 0.546, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86644, text = "Gods Before Us (objective 3)",
          coord = { map = 2395, x = 0.546, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86644, text = "Gods Before Us (objective 4)",
          coord = { map = 2395, x = 0.540, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86644, text = "Gods Before Us (objective 5)",
          coord = { map = 2395, x = 0.536, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86644, text = "Turn in: Gods Before Us",
          coord = nil, noArrow = true },  -- no coord: APR step has none
        { type = "accept", questID = 86646, text = "An Impasse",
          coord = { map = 2579, x = 0.171, y = 0.365 } },  -- giver coord: ATT
        { type = "quest",  questID = 86646, text = "An Impasse (objective 1)",
          coord = { map = 2395, x = 0.539, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86646, text = "Turn in: An Impasse",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 86647, text = "Beat of Blood",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- giver coord: ATT
        { type = "turnin", questID = 86647, text = "Turn in: Beat of Blood",
          coord = { map = 2395, x = 0.552, y = 0.814 } },  -- APR route coord (converted)
        { type = "accept", questID = 86648, text = "Light Guide Us",
          coord = { map = 2395, x = 0.551, y = 0.814 } },  -- giver coord: ATT
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [1/8]",
          coord = { map = 2395, x = 0.566, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [2/8]",
          coord = { map = 2395, x = 0.566, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [3/8]",
          coord = { map = 2395, x = 0.574, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [4/8]",
          coord = { map = 2395, x = 0.573, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [5/8]",
          coord = { map = 2395, x = 0.578, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [6/8]",
          coord = { map = 2395, x = 0.582, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [7/8]",
          coord = { map = 2395, x = 0.589, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 3) [8/8]",
          coord = { map = 2395, x = 0.593, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 1)",
          coord = { map = 2395, x = 0.593, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 4)",
          coord = { map = 2395, x = 0.594, y = 0.814 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86648, text = "Light Guide Us (objective 5)",
          coord = { map = 2395, x = 0.603, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86648, text = "Turn in: Light Guide Us",
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted)
        { type = "accept", questID = 86649, text = "Past Redemption",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 86649, text = "Past Redemption (objective 1)",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86649, text = "Turn in: Past Redemption",
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- APR route coord (converted)
        { type = "accept", questID = 86650, text = "Fractured",
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 86650, text = "Fractured (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86650, text = "Turn in: Fractured",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}
