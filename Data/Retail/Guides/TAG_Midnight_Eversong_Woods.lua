-- ToonAge guide data: Midnight (12.x) Eversong Woods: MAIN CAMPAIGN storyline only
-- Generated 2026-10-08. Format: { type, questID, text, [faction], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- uiMapIDs: 2395 Eversong Woods, 2393 Silvermoon City, 2424 Isle of Quel'Danas (Wowhead zone map ID list; matches APR/ATT).
--
-- SOURCES / VERIFICATION
--  * Step order + questIDs: APR route "2393-Eversong-Woods-Campaign-Only" (Routes/Midnight/Midnight-Eversong-Woods.lua,
--    github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, master as of 2026-10-08; route condition Level 80, next = Harandar).
--  * Every quest name was verified on Wowhead's tooltip API (nether.wowhead.com/tooltip/quest/<id>), 2026-10-08.
--  * accept coords = quest giver coords from AllTheThings ".contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/{Quests,Eversong Woods/Quests}.lua".
--  * Other coords: APR world coords converted with per-map linear fits calibrated on ATT giver coords:
--      2395: x = -0.0106127*aprX + 1.5658 ; y = -0.0159294*aprY + 161.9255  (136 pts, max residual 0.09 map-%)
--      2393: x = -0.0356311*aprX - 118.8464 ; y = -0.0534863*aprY + 522.7010 (33 pts, max residual 0.15 map-%)
--    A point is assigned to 2393 if it falls inside the Silvermoon map, else 2395. Derived, not hand-measured.
--  * faction = "Alliance"/"Horde" marks the faction-split "Paved in Ash" (86735 A / 86736 H) steps.
--  * Scenario "Void Walk With Me" (86636) runs in instance map 2502; its interior steps have no coord.
--  * Side quests, the "sojourner" full route, and renown are NOT included. Midnight 12.1.5 (Oct 13 2026) may change this.
--
-- vs. the existing ToonAge TAG_Midnight_Eversong_Woods.lua: not audited line-by-line here (see report).

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_eversong_campaign"] = {
    id = "midnight_eversong_campaign", title = "Midnight: Eversong Woods (Campaign)", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90,
    nextGuide = nil, -- APR continues to Harandar campaign
    steps = {
        { type = "accept", questID = 86733, text = "Silvermoon Negotiations",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 86733, text = "Silvermoon Negotiations (objective 1)",
          coord = { map = 2393, x = 0.456, y = 0.677 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86733, text = "Turn in: Silvermoon Negotiations",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 86734, text = "Diplomacy",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest", questID = 86734, text = "Diplomacy (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86734, text = "Turn in: Diplomacy",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 86735, text = "Paved in Ash", faction = "Alliance",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 86736, text = "Paved in Ash", faction = "Horde",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 7)", faction = "Alliance",
          coord = { map = 2393, x = 0.457, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 7)", faction = "Horde",
          coord = { map = 2393, x = 0.457, y = 0.628 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 4)", faction = "Alliance",
          coord = { map = 2393, x = 0.508, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 4)", faction = "Horde",
          coord = { map = 2393, x = 0.508, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 1)", faction = "Alliance",
          coord = { map = 2393, x = 0.565, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 1)", faction = "Horde",
          coord = { map = 2393, x = 0.565, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 3)", faction = "Alliance",
          coord = { map = 2393, x = 0.510, y = 0.713 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 3)", faction = "Horde",
          coord = { map = 2393, x = 0.510, y = 0.713 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 5)", faction = "Horde",
          coord = { map = 2393, x = 0.525, y = 0.783 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 2)", faction = "Alliance",
          coord = { map = 2393, x = 0.526, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 2)", faction = "Horde",
          coord = { map = 2393, x = 0.526, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest", questID = 86735, text = "Paved in Ash (objective 6)", faction = "Alliance",
          coord = { map = 2393, x = 0.602, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest", questID = 86736, text = "Paved in Ash (objective 6)", faction = "Horde",
          coord = { map = 2393, x = 0.691, y = 0.676 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86735, text = "Turn in: Paved in Ash", faction = "Alliance",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86736, text = "Turn in: Paved in Ash", faction = "Horde",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 86737, text = "Fair Breeze, Light Bloom",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- giver coord: ATT
        { type = "quest", questID = 86737, text = "Fair Breeze, Light Bloom (objective 1)",
          coord = { map = 2393, x = 0.453, y = 0.706 } },  -- APR route coord (converted)
        { type = "quest", questID = 86737, text = "Fair Breeze, Light Bloom (objective 3)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86737, text = "Turn in: Fair Breeze, Light Bloom",
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "accept", questID = 86738, text = "Sharpmaw",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86739, text = "Fairbreeze Favors",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86740, text = "Displaced Denizens",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "quest", questID = 86738, text = "Sharpmaw (objective 1)",
          coord = { map = 2395, x = 0.458, y = 0.479 } },  -- APR route coord (converted)
        { type = "quest", questID = 86738, text = "Sharpmaw (objective 2)",
          coord = { map = 2395, x = 0.458, y = 0.479 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 2) [1/3]",
          coord = { map = 2395, x = 0.476, y = 0.465 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 2) [1/3]",
          coord = { map = 2395, x = 0.476, y = 0.465 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 1) [1/3]",
          coord = { map = 2395, x = 0.472, y = 0.463 } },  -- APR route coord (converted)
        { type = "quest", questID = 86739, text = "Fairbreeze Favors (objective 4) [1/3]",
          coord = { map = 2395, x = 0.465, y = 0.459 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 1) [2/3]",
          coord = { map = 2395, x = 0.459, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest", questID = 86739, text = "Fairbreeze Favors (objective 4) [2/3]",
          coord = { map = 2395, x = 0.456, y = 0.455 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 1) [3/3]",
          coord = { map = 2395, x = 0.455, y = 0.460 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 2) [2/3]",
          coord = { map = 2395, x = 0.456, y = 0.468 } },  -- APR route coord (converted)
        { type = "quest", questID = 86739, text = "Fairbreeze Favors (objective 4) [3/3]",
          coord = { map = 2395, x = 0.447, y = 0.450 } },  -- APR route coord (converted)
        { type = "quest", questID = 86740, text = "Displaced Denizens (objective 2) [3/3]",
          coord = { map = 2395, x = 0.448, y = 0.440 } },  -- APR route coord (converted)
        { type = "quest", questID = 86739, text = "Fairbreeze Favors (objective 1,2,3)",
          coord = { map = 2395, x = 0.458, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86740, text = "Turn in: Displaced Denizens",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86738, text = "Turn in: Sharpmaw",
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86739, text = "Turn in: Fairbreeze Favors",
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "accept", questID = 86741, text = "Lightbloom Looming",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "quest", questID = 86741, text = "Lightbloom Looming (objective 1)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "quest", questID = 86741, text = "Lightbloom Looming (objective 2)",
          coord = { map = 2395, x = 0.417, y = 0.471 } },  -- APR route coord (converted)
        { type = "quest", questID = 86741, text = "Lightbloom Looming (objective 3,4)",
          coord = { map = 2395, x = 0.400, y = 0.489 } },  -- APR route coord (converted)
        { type = "quest", questID = 86741, text = "Lightbloom Looming (objective 5)",
          coord = { map = 2395, x = 0.397, y = 0.506 } },  -- APR route coord (converted)
        { type = "quest", questID = 86741, text = "Lightbloom Looming (objective 6)",
          coord = { map = 2395, x = 0.397, y = 0.515 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86741, text = "Turn in: Lightbloom Looming",
          coord = { map = 2395, x = 0.397, y = 0.516 } },  -- APR route coord (converted)
        { type = "accept", questID = 86743, text = "Trimming the Lightbloom",
          coord = { map = 2395, x = 0.397, y = 0.516 } },  -- giver coord: ATT
        { type = "accept", questID = 86742, text = "Curious Cultivation",
          coord = { map = 2395, x = 0.397, y = 0.516 } },  -- giver coord: ATT
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 1) [1/3]",
          coord = { map = 2395, x = 0.407, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 1) [2/3]",
          coord = { map = 2395, x = 0.401, y = 0.554 } },  -- APR route coord (converted)
        { type = "quest", questID = 86743, text = "Trimming the Lightbloom (objective 1)",
          coord = { map = 2395, x = 0.401, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 1) [3/3]",
          coord = { map = 2395, x = 0.423, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 2)",
          coord = { map = 2395, x = 0.440, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 3,4)",
          coord = { map = 2395, x = 0.439, y = 0.564 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86743, text = "Turn in: Trimming the Lightbloom",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 86742, text = "Curious Cultivation (objective 5)",
          coord = { map = 2395, x = 0.458, y = 0.553 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86742, text = "Turn in: Curious Cultivation",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- APR route coord (converted)
        { type = "accept", questID = 86744, text = "Seeking Truth",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- giver coord: ATT
        { type = "quest", questID = 86744, text = "Seeking Truth (objective 1)",
          coord = { map = 2395, x = 0.459, y = 0.555 } },  -- APR route coord (converted)
        { type = "quest", questID = 86744, text = "Seeking Truth (objective 2)",
          coord = { map = 2395, x = 0.463, y = 0.551 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86744, text = "Turn in: Seeking Truth",
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "accept", questID = 86745, text = "Silvermoon Must Know",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest", questID = 86745, text = "Silvermoon Must Know (objective 1)",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86745, text = "Turn in: Silvermoon Must Know",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86621, text = "The Wayward Magister",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest", questID = 86621, text = "The Wayward Magister (objective 2)",
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest", questID = 86621, text = "The Wayward Magister (objective 1)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest", questID = 86621, text = "The Wayward Magister (objective 3)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest", questID = 86621, text = "The Wayward Magister (objective 4)",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86621, text = "Turn in: The Wayward Magister",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86623, text = "Appeal to the Void",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "accept", questID = 86624, text = "Rational Explanation",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [10%]",
          coord = { map = 2395, x = 0.481, y = 0.680 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [25%]",
          coord = { map = 2395, x = 0.485, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [35%]",
          coord = { map = 2395, x = 0.478, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 1) [1/4]",
          coord = { map = 2395, x = 0.477, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [50%]",
          coord = { map = 2395, x = 0.477, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [65%]",
          coord = { map = 2395, x = 0.489, y = 0.665 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 1) [2/4]",
          coord = { map = 2395, x = 0.489, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [75%]",
          coord = { map = 2395, x = 0.487, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2) [85%]",
          coord = { map = 2395, x = 0.491, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 1) [3/4]",
          coord = { map = 2395, x = 0.493, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 2)",
          coord = { map = 2395, x = 0.494, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 1) [4/4]",
          coord = { map = 2395, x = 0.489, y = 0.696 } },  -- APR route coord (converted)
        { type = "quest", questID = 86623, text = "Appeal to the Void (objective 1)",
          coord = { map = 2395, x = 0.488, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest", questID = 86623, text = "Appeal to the Void (objective 2)",
          coord = { map = 2395, x = 0.467, y = 0.715 } },  -- APR route coord (converted)
        { type = "quest", questID = 86623, text = "Appeal to the Void (objective 3)",
          coord = { map = 2395, x = 0.454, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 3)",
          coord = { map = 2395, x = 0.490, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest", questID = 86624, text = "Rational Explanation (objective 4)",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86624, text = "Turn in: Rational Explanation",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86623, text = "Turn in: Appeal to the Void",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 90907, text = "The First to Know",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 90907, text = "The First to Know (objective 1)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest", questID = 90907, text = "The First to Know (objective 2)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest", questID = 90907, text = "The First to Know (objective 3)",
          coord = { map = 2395, x = 0.471, y = 0.684 } },  -- APR route coord (converted)
        { type = "quest", questID = 90907, text = "The First to Know (objective 4)",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90907, text = "Turn in: The First to Know",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 86622, text = "Chance Meeting",
          coord = { map = 2395, x = 0.472, y = 0.682 } },  -- giver coord: ATT
        { type = "quest", questID = 86622, text = "Chance Meeting (objective 1)",
          coord = { map = 2395, x = 0.467, y = 0.639 } },  -- APR route coord (converted)
        { type = "quest", questID = 86622, text = "Chance Meeting (objective 2)",
          coord = { map = 2395, x = 0.467, y = 0.637 } },  -- APR route coord (converted)
        { type = "quest", questID = 86622, text = "Chance Meeting (objective 3)",
          coord = { map = 2395, x = 0.467, y = 0.637 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86622, text = "Turn in: Chance Meeting",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "accept", questID = 86626, text = "The Ransacked Lab",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 86626, text = "The Ransacked Lab (objective 1) [1/3]",
          coord = { map = 2395, x = 0.477, y = 0.699 } },  -- APR route coord (converted)
        { type = "quest", questID = 86626, text = "The Ransacked Lab (objective 1) [2/3]",
          coord = { map = 2395, x = 0.476, y = 0.698 } },  -- APR route coord (converted)
        { type = "quest", questID = 86626, text = "The Ransacked Lab (objective 1) [3/3]",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest", questID = 86626, text = "The Ransacked Lab (objective 2)",
          coord = { map = 2395, x = 0.478, y = 0.699 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86626, text = "Turn in: The Ransacked Lab",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86632, text = "The Battle for Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "accept", questID = 90509, text = "The Traitors of Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "accept", questID = 90493, text = "The Heart of Tranquillien",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- giver coord: ATT
        { type = "quest", questID = 90509, text = "The Traitors of Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.476, y = 0.676 } },  -- APR route coord (converted)
        { type = "quest", questID = 90509, text = "The Traitors of Tranquillien (objective 3)",
          coord = { map = 2395, x = 0.494, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest", questID = 90509, text = "The Traitors of Tranquillien (objective 2)",
          coord = { map = 2395, x = 0.477, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest", questID = 86632, text = "The Battle for Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.484, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest", questID = 90493, text = "The Heart of Tranquillien (objective 1)",
          coord = { map = 2395, x = 0.484, y = 0.675 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86632, text = "Turn in: The Battle for Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90493, text = "Turn in: The Heart of Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90509, text = "Turn in: The Traitors of Tranquillien",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- APR route coord (converted)
        { type = "accept", questID = 90494, text = "The Missing Magister",
          coord = { map = 2395, x = 0.490, y = 0.685 } },  -- giver coord: ATT
        { type = "quest", questID = 90494, text = "The Missing Magister (objective 1)",
          coord = { map = 2395, x = 0.473, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest", questID = 90494, text = "The Missing Magister (objective 2)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest", questID = 90494, text = "The Missing Magister (objective 3)",
          coord = { map = 2395, x = 0.472, y = 0.683 } },  -- APR route coord (converted)
        { type = "quest", questID = 90494, text = "The Missing Magister (objective 4)",
          coord = { map = 2395, x = 0.471, y = 0.684 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90494, text = "Turn in: The Missing Magister",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- APR route coord (converted)
        { type = "accept", questID = 86781, text = "Face the Past",
          coord = { map = 2395, x = 0.477, y = 0.698 } },  -- giver coord: ATT
        { type = "quest", questID = 86781, text = "Face the Past (objective 1)",
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest", questID = 86781, text = "Face the Past (objective 2)",
          coord = { map = 2395, x = 0.371, y = 0.740 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86781, text = "Turn in: Face the Past",
          coord = { map = 2395, x = 0.370, y = 0.740 } },  -- APR route coord (converted)
        { type = "accept", questID = 86634, text = "The Past Keeps Watch",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- giver coord: ATT
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [1/6]",
          coord = { map = 2395, x = 0.385, y = 0.726 } },  -- APR route coord (converted)
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [2/6]",
          coord = { map = 2395, x = 0.385, y = 0.737 } },  -- APR route coord (converted)
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [3/6]",
          coord = { map = 2395, x = 0.386, y = 0.750 } },  -- APR route coord (converted)
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [4/6]",
          coord = { map = 2395, x = 0.381, y = 0.752 } },  -- APR route coord (converted)
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [5/6]",
          coord = { map = 2395, x = 0.374, y = 0.758 } },  -- APR route coord (converted)
        { type = "quest", questID = 86634, text = "The Past Keeps Watch (objective 1) [6/6]",
          coord = { map = 2395, x = 0.361, y = 0.754 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86634, text = "Turn in: The Past Keeps Watch",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 86633, text = "Comprehend the Void",
          coord = { map = 2395, x = 0.370, y = 0.740 } },  -- giver coord: ATT
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 2)",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- APR route coord (converted)
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 1)",
          coord = { map = 2395, x = 0.374, y = 0.747 } },  -- APR route coord (converted)
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 3) [1/4]",
          coord = { map = 2395, x = 0.375, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 3) [2/4]",
          coord = { map = 2395, x = 0.371, y = 0.749 } },  -- APR route coord (converted)
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 3) [3/4]",
          coord = { map = 2395, x = 0.373, y = 0.744 } },  -- APR route coord (converted)
        { type = "quest", questID = 86633, text = "Comprehend the Void (objective 3) [4/4]",
          coord = { map = 2395, x = 0.376, y = 0.746 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86633, text = "Turn in: Comprehend the Void",
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86635, text = "To Deatholme",
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- giver coord: ATT
        { type = "quest", questID = 86635, text = "To Deatholme (objective 1,2)",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86635, text = "Turn in: To Deatholme",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "accept", questID = 86636, text = "Void Walk With Me",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- giver coord: ATT
        { type = "quest", questID = 86636, text = "Void Walk With Me (objective 1)",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 86636, text = "Void Walk With Me (objective 2)",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 86636, text = "Void Walk With Me (objective 3)",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 86636, text = "Turn in: Void Walk With Me",
          coord = { map = 2395, x = 0.447, y = 0.852 } },  -- APR route coord (converted)
        { type = "accept", questID = 86637, text = "Anything but Reprieve",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- giver coord: ATT
        { type = "quest", questID = 86637, text = "Anything but Reprieve (objective 1)",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86637, text = "Turn in: Anything but Reprieve",
          coord = { map = 2395, x = 0.527, y = 0.616 } },  -- APR route coord (converted)
        { type = "accept", questID = 86639, text = "What's Left",
          coord = { map = 2395, x = 0.527, y = 0.616 } },  -- giver coord: ATT
        { type = "accept", questID = 86638, text = "Choking Tendrils",
          coord = { map = 2395, x = 0.526, y = 0.616 } },  -- giver coord: ATT
        { type = "quest", questID = 86639, text = "What's Left (objective 2)",
          coord = { map = 2395, x = 0.535, y = 0.594 } },  -- APR route coord (converted)
        { type = "quest", questID = 86639, text = "What's Left (objective 3)",
          coord = { map = 2395, x = 0.547, y = 0.610 } },  -- APR route coord (converted)
        { type = "quest", questID = 86639, text = "What's Left (objective 5)",
          coord = { map = 2395, x = 0.548, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest", questID = 86639, text = "What's Left (objective 4)",
          coord = { map = 2395, x = 0.559, y = 0.574 } },  -- APR route coord (converted)
        { type = "quest", questID = 86638, text = "Choking Tendrils (objective 1)",
          coord = { map = 2395, x = 0.550, y = 0.593 } },  -- APR route coord (converted)
        { type = "quest", questID = 86639, text = "What's Left (objective 1)",
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
        { type = "quest", questID = 86642, text = "A Foe Unseen (objective 1) [1/5]",
          coord = { map = 2395, x = 0.606, y = 0.517 } },  -- APR route coord (converted)
        { type = "quest", questID = 86642, text = "A Foe Unseen (objective 1) [2/5]",
          coord = { map = 2395, x = 0.606, y = 0.524 } },  -- APR route coord (converted)
        { type = "quest", questID = 86642, text = "A Foe Unseen (objective 1) [3/5]",
          coord = { map = 2395, x = 0.630, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest", questID = 86642, text = "A Foe Unseen (objective 1) [4/5]",
          coord = { map = 2395, x = 0.621, y = 0.503 } },  -- APR route coord (converted)
        { type = "quest", questID = 86642, text = "A Foe Unseen (objective 1) [5/5]",
          coord = { map = 2395, x = 0.633, y = 0.484 } },  -- APR route coord (converted)
        { type = "quest", questID = 86641, text = "Old Scars (objective 1)",
          coord = { map = 2395, x = 0.621, y = 0.497 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86641, text = "Turn in: Old Scars",
          coord = { map = 2395, x = 0.644, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86642, text = "Turn in: A Foe Unseen",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 86643, text = "Following the Root",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- giver coord: ATT
        { type = "quest", questID = 86643, text = "Following the Root (objective 2)",
          coord = { map = 2395, x = 0.645, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 1)",
          coord = { map = 2395, x = 0.568, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 3) [1/4]",
          coord = { map = 2395, x = 0.565, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 3) [2/4]",
          coord = { map = 2395, x = 0.565, y = 0.658 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 3) [3/4]",
          coord = { map = 2395, x = 0.556, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 3) [4/4]",
          coord = { map = 2395, x = 0.553, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest", questID = 86643, text = "Following the Root (objective 4)",
          coord = { map = 2395, x = 0.551, y = 0.655 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86643, text = "Turn in: Following the Root",
          coord = { map = 2395, x = 0.548, y = 0.656 } },  -- APR route coord (converted)
        { type = "accept", questID = 86644, text = "Gods Before Us",
          coord = { map = 2395, x = 0.548, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest", questID = 86644, text = "Gods Before Us (objective 1)",
          coord = { map = 2395, x = 0.548, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest", questID = 86644, text = "Gods Before Us (objective 2)",
          coord = { map = 2395, x = 0.546, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest", questID = 86644, text = "Gods Before Us (objective 3)",
          coord = { map = 2395, x = 0.546, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest", questID = 86644, text = "Gods Before Us (objective 4)",
          coord = { map = 2395, x = 0.540, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest", questID = 86644, text = "Gods Before Us (objective 5)",
          coord = { map = 2395, x = 0.536, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86644, text = "Turn in: Gods Before Us",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 86646, text = "An Impasse",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 86646, text = "An Impasse (objective 1)",
          coord = { map = 2395, x = 0.539, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86646, text = "Turn in: An Impasse",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 86647, text = "Beat of Blood",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- giver coord: ATT
        { type = "turnin", questID = 86647, text = "Turn in: Beat of Blood",
          coord = { map = 2395, x = 0.552, y = 0.814 } },  -- APR route coord (converted)
        { type = "accept", questID = 86648, text = "Light Guide Us",
          coord = { map = 2395, x = 0.551, y = 0.814 } },  -- giver coord: ATT
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [1/8]",
          coord = { map = 2395, x = 0.566, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [2/8]",
          coord = { map = 2395, x = 0.566, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [3/8]",
          coord = { map = 2395, x = 0.573, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [4/8]",
          coord = { map = 2395, x = 0.573, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [5/8]",
          coord = { map = 2395, x = 0.578, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [6/8]",
          coord = { map = 2395, x = 0.582, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [7/8]",
          coord = { map = 2395, x = 0.589, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 3) [8/8]",
          coord = { map = 2395, x = 0.593, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 1)",
          coord = { map = 2395, x = 0.592, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 4)",
          coord = { map = 2395, x = 0.594, y = 0.814 } },  -- APR route coord (converted)
        { type = "quest", questID = 86648, text = "Light Guide Us (objective 5)",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86648, text = "Turn in: Light Guide Us",
          coord = { map = 2395, x = 0.602, y = 0.814 } },  -- APR route coord (converted)
        { type = "accept", questID = 86649, text = "Past Redemption",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- giver coord: ATT
        { type = "quest", questID = 86649, text = "Past Redemption (objective 1)",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86649, text = "Turn in: Past Redemption",
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- APR route coord (converted)
        { type = "accept", questID = 86650, text = "Fractured",
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- giver coord: ATT
        { type = "quest", questID = 86650, text = "Fractured (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86650, text = "Turn in: Fractured",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- APR route coord (converted)
    },
}
