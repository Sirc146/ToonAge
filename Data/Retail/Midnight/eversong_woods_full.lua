-- ToonAge guide data: Midnight: Eversong Woods (Campaign + side quests)
-- Kind: APR "sojourner" route = campaign + all side quests
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2393-Eversong-Woods"
--    in Routes/Midnight/Midnight-Eversong-Woods.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 153 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 124 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.06, max 0.18 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2393 Silvermoon City, 2395 Eversong Woods, 2424 Isle of Quel'Danas, 2579 Wartha'nan Crypts


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_eversong_full"] = {
    id = "midnight_eversong_full", title = "Midnight: Eversong Woods (Campaign + side quests)", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_harandar_full",
    steps = {
        { type = "accept", questID = 86733, text = "Silvermoon Negotiations",
          coord = { map = 2424, x = 0.525, y = 0.882 } },  -- giver coord: ATT
        { type = "accept", questID = 93723, text = "Crafters Needed",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93723, text = "Crafters Needed (objective 1)",
          coord = { map = 2393, x = 0.450, y = 0.556 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93723, text = "Turn in: Crafters Needed",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93724, text = "Crafting Orders: Alchemy",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93726, text = "Crafting Orders: Blacksmithing",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93727, text = "Crafting Orders: Engineering",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93728, text = "Crafting Orders: Inscription",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93729, text = "Crafting Orders: Jewelcrafting",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93730, text = "Crafting Orders: Tailoring",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 93731, text = "Crafting Orders: Leatherworking",
          coord = { map = 2393, x = 0.450, y = 0.552 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93731, text = "Crafting Orders: Leatherworking (objective 1)",
          coord = { map = 2393, x = 0.431, y = 0.558 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93731, text = "Turn in: Crafting Orders: Leatherworking",
          coord = { map = 2393, x = 0.431, y = 0.558 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93727, text = "Crafting Orders: Engineering (objective 1)",
          coord = { map = 2393, x = 0.435, y = 0.540 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93727, text = "Turn in: Crafting Orders: Engineering",
          coord = { map = 2393, x = 0.435, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93726, text = "Crafting Orders: Blacksmithing (objective 1)",
          coord = { map = 2393, x = 0.438, y = 0.513 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93726, text = "Turn in: Crafting Orders: Blacksmithing",
          coord = { map = 2393, x = 0.437, y = 0.518 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93728, text = "Crafting Orders: Inscription (objective 1)",
          coord = { map = 2393, x = 0.468, y = 0.515 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93728, text = "Turn in: Crafting Orders: Inscription",
          coord = { map = 2393, x = 0.469, y = 0.516 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93724, text = "Crafting Orders: Alchemy (objective 1)",
          coord = { map = 2393, x = 0.470, y = 0.520 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93724, text = "Turn in: Crafting Orders: Alchemy",
          coord = { map = 2393, x = 0.470, y = 0.520 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93729, text = "Crafting Orders: Jewelcrafting (objective 1)",
          coord = { map = 2393, x = 0.479, y = 0.551 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93729, text = "Turn in: Crafting Orders: Jewelcrafting",
          coord = { map = 2393, x = 0.482, y = 0.551 } },  -- APR route coord (converted)
        { type = "quest",  questID = 93730, text = "Crafting Orders: Tailoring (objective 1)",
          coord = { map = 2393, x = 0.482, y = 0.541 } },  -- APR route coord (converted)
        { type = "turnin", questID = 93730, text = "Turn in: Crafting Orders: Tailoring",
          coord = { map = 2393, x = 0.482, y = 0.540 } },  -- APR route coord (converted)
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
        { type = "turnin", questID = 86735, text = "Turn in: Paved in Ash", rep = { { factionID = 2710, amount = 50 } }, faction = "Alliance",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86736, text = "Turn in: Paved in Ash", rep = { { factionID = 2710, amount = 50 } }, faction = "Horde",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 86737, text = "Fair Breeze, Light Bloom",
          coord = { map = 2393, x = 0.454, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 86737, text = "Fair Breeze, Light Bloom (objective 1)",
          coord = { map = 2393, x = 0.453, y = 0.705 } },  -- APR route coord (converted)
        { type = "accept", questID = 91386, text = "Mad to Measure",
          coord = { map = 2393, x = 0.484, y = 0.545 } },  -- giver coord: ATT
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 1)",
          coord = { map = 2393, x = 0.486, y = 0.544 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 2)",
          coord = { map = 2393, x = 0.489, y = 0.540 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 3)",
          coord = { map = 2393, x = 0.486, y = 0.548 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 4)",
          coord = { map = 2393, x = 0.488, y = 0.540 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 5)",
          coord = { map = 2393, x = 0.488, y = 0.543 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91386, text = "Mad to Measure (objective 6)",
          coord = { map = 2393, x = 0.487, y = 0.549 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91386, text = "Turn in: Mad to Measure", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.488, y = 0.550 } },  -- APR route coord (converted)
        { type = "accept", questID = 92408, text = "Material Gains",
          coord = { map = 2393, x = 0.488, y = 0.550 } },  -- giver coord: ATT
        { type = "accept", questID = 92396, text = "Calling in the Cavalry",
          coord = { map = 2395, x = 0.501, y = 0.342 } },  -- giver coord: ATT
        { type = "quest",  questID = 92396, text = "Calling in the Cavalry (objective 1)",
          coord = { map = 2393, x = 0.441, y = 0.941 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92408, text = "Turn in: Material Gains", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.335, y = 0.984 } },  -- APR route coord (converted)
        { type = "accept", questID = 91388, text = "Uncommon Threads",
          coord = { map = 2395, x = 0.469, y = 0.356 } },  -- giver coord: ATT
        { type = "quest",  questID = 91388, text = "Uncommon Threads (objective 1)", useItem = 250919,
          coord = { map = 2393, x = 0.327, y = 0.969 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91388, text = "Turn in: Uncommon Threads", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.335, y = 0.984 } },  -- APR route coord (converted)
        { type = "accept", questID = 91389, text = "Clothes Make the Man",
          coord = { map = 2395, x = 0.469, y = 0.356 } },  -- giver coord: ATT
        { type = "quest",  questID = 91389, text = "Clothes Make the Man (objective 1)",
          coord = { map = 2393, x = 0.312, y = 0.958 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91389, text = "Clothes Make the Man (objective 2)",
          coord = { map = 2393, x = 0.313, y = 0.955 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91389, text = "Clothes Make the Man (objective 3)",
          coord = { map = 2393, x = 0.274, y = 0.943 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91389, text = "Turn in: Clothes Make the Man", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.274, y = 0.943 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86737, text = "Fair Breeze, Light Bloom (objective 3)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86737, text = "Turn in: Fair Breeze, Light Bloom", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "accept", questID = 86738, text = "Sharpmaw",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86739, text = "Fairbreeze Favors",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 86740, text = "Displaced Denizens",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "accept", questID = 87392, text = "Cargo Conspiracy",
          coord = { map = 2395, x = 0.469, y = 0.452 } },  -- giver coord: ATT
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
        { type = "quest",  questID = 87392, text = "Cargo Conspiracy (objective 1)",
          coord = { map = 2395, x = 0.463, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87392, text = "Cargo Conspiracy (objective 2)",
          coord = { map = 2395, x = 0.459, y = 0.451 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86740, text = "Turn in: Displaced Denizens", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86738, text = "Turn in: Sharpmaw", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86739, text = "Turn in: Fairbreeze Favors", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.467, y = 0.458 } },  -- APR route coord (converted)
        { type = "accept", questID = 86741, text = "Lightbloom Looming",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- giver coord: ATT
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 1)",
          coord = { map = 2395, x = 0.467, y = 0.457 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87392, text = "Cargo Conspiracy (objective 3)",
          coord = { map = 2395, x = 0.470, y = 0.460 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87392, text = "Cargo Conspiracy (objective 4)",
          coord = { map = 2395, x = 0.471, y = 0.463 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87392, text = "Turn in: Cargo Conspiracy", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.469, y = 0.452 } },  -- APR route coord (converted)
        { type = "accept", questID = 87393, text = "Warranted Search",
          coord = { map = 2395, x = 0.469, y = 0.452 } },  -- giver coord: ATT
        { type = "accept", questID = 87394, text = "Supplier Surveillance",
          coord = { map = 2395, x = 0.469, y = 0.452 } },  -- giver coord: ATT
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 2)",
          coord = { map = 2395, x = 0.417, y = 0.471 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 3,4)",
          coord = { map = 2395, x = 0.399, y = 0.489 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 5)",
          coord = { map = 2395, x = 0.397, y = 0.506 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86741, text = "Lightbloom Looming (objective 6)",
          coord = { map = 2395, x = 0.396, y = 0.515 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86741, text = "Turn in: Lightbloom Looming", rep = { { factionID = 2710, amount = 50 } },
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
        { type = "quest",  questID = 92396, text = "Calling in the Cavalry (objective 2)",
          coord = { map = 2395, x = 0.393, y = 0.567 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 1) [3/3]",
          coord = { map = 2395, x = 0.423, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 2)",
          coord = { map = 2395, x = 0.440, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86742, text = "Curious Cultivation (objective 3,4)",
          coord = { map = 2395, x = 0.439, y = 0.564 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86743, text = "Turn in: Trimming the Lightbloom", rep = { { factionID = 2710, amount = 10 } },
          coord = nil },  -- no coord: APR step has none
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
        { type = "turnin", questID = 86744, text = "Turn in: Seeking Truth", rep = { { factionID = 2710, amount = 1500 } },
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "accept", questID = 86745, text = "Silvermoon Must Know",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest",  questID = 86745, text = "Silvermoon Must Know (objective 1)",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86745, text = "Turn in: Silvermoon Must Know", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- APR route coord (converted)
        { type = "accept", questID = 86621, text = "The Wayward Magister",
          coord = { map = 2395, x = 0.473, y = 0.554 } },  -- giver coord: ATT
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 2)",
          coord = { map = 2395, x = 0.474, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92396, text = "Calling in the Cavalry (objective 3)",
          coord = { map = 2395, x = 0.534, y = 0.543 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 1)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 3)",
          coord = { map = 2395, x = 0.492, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86621, text = "The Wayward Magister (objective 4)",
          coord = { map = 2395, x = 0.477, y = 0.696 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86621, text = "Turn in: The Wayward Magister", rep = { { factionID = 2710, amount = 10 } },
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
        { type = "turnin", questID = 86624, text = "Turn in: Rational Explanation", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.477, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86623, text = "Turn in: Appeal to the Void", rep = { { factionID = 2710, amount = 50 } },
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
        { type = "turnin", questID = 90907, text = "Turn in: The First to Know", rep = { { factionID = 2710, amount = 50 } },
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
        { type = "turnin", questID = 86626, text = "Turn in: The Ransacked Lab", rep = { { factionID = 2710, amount = 50 } },
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
        { type = "turnin", questID = 86632, text = "Turn in: The Battle for Tranquillien", rep = { { factionID = 2710, amount = 100 } },
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
        { type = "turnin", questID = 86781, text = "Turn in: Face the Past", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.370, y = 0.740 } },  -- APR route coord (converted)
        { type = "accept", questID = 86634, text = "The Past Keeps Watch",
          coord = { map = 2395, x = 0.370, y = 0.741 } },  -- giver coord: ATT
        { type = "accept", questID = 94370, text = "Slithering Closer",
          coord = { map = 2395, x = 0.373, y = 0.739 } },  -- giver coord: ATT
        { type = "accept", questID = 92021, text = "Graveblossom Gardening",
          coord = { map = 2395, x = 0.375, y = 0.725 } },  -- giver coord: ATT
        { type = "accept", questID = 92022, text = "A Venomous Vocation",
          coord = { map = 2395, x = 0.375, y = 0.725 } },  -- giver coord: ATT
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
        { type = "turnin", questID = 86634, text = "Turn in: The Past Keeps Watch", rep = { { factionID = 2710, amount = 50 } },
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
        { type = "turnin", questID = 86633, text = "Turn in: Comprehend the Void", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- APR route coord (converted)
        { type = "accept", questID = 86635, text = "To Deatholme",
          coord = { map = 2395, x = 0.373, y = 0.747 } },  -- giver coord: ATT
        { type = "quest",  questID = 92021, text = "Graveblossom Gardening (objective 1)",
          coord = { map = 2395, x = 0.390, y = 0.748 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92022, text = "A Venomous Vocation (objective 1)",
          coord = { map = 2395, x = 0.390, y = 0.748 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92021, text = "Turn in: Graveblossom Gardening", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.375, y = 0.725 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92022, text = "Turn in: A Venomous Vocation", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.375, y = 0.725 } },  -- APR route coord (converted)
        { type = "accept", questID = 92023, text = "Suspicious Sundries",
          coord = { map = 2395, x = 0.375, y = 0.725 } },  -- giver coord: ATT
        { type = "turnin", questID = 94370, text = "Turn in: Slithering Closer", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "accept", questID = 91493, text = "Not What I Ordered",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- giver coord: ATT
        { type = "quest",  questID = 91493, text = "Not What I Ordered (objective 1)",
          coord = { map = 2395, x = 0.389, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91493, text = "Turn in: Not What I Ordered",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "accept", questID = 91505, text = "Daggers in My Spine",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- giver coord: ATT
        { type = "accept", questID = 91494, text = "One Elf's Trash, Another Elf's Treasure",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- giver coord: ATT
        { type = "accept", questID = 91495, text = "Familiar Faces in Peril",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- giver coord: ATT
        { type = "quest",  questID = 91494, text = "One Elf's Trash, Another Elf's Treasure (objective 1)", useItem = 247593,
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91495, text = "Familiar Faces in Peril (objective 1)",
          coord = { map = 2395, x = 0.368, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91495, text = "Familiar Faces in Peril (objective 3)",
          coord = { map = 2395, x = 0.375, y = 0.650 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91495, text = "Familiar Faces in Peril (objective 2)",
          coord = { map = 2395, x = 0.356, y = 0.679 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91494, text = "One Elf's Trash, Another Elf's Treasure (objective 2)", useItem = 247593,
          coord = { map = 2395, x = 0.370, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91505, text = "Daggers in My Spine (objective 1)",
          coord = { map = 2395, x = 0.370, y = 0.652 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91495, text = "Turn in: Familiar Faces in Peril",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91505, text = "Turn in: Daggers in My Spine",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91494, text = "Turn in: One Elf's Trash, Another Elf's Treasure",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- APR route coord (converted)
        { type = "accept", questID = 91504, text = "Arcane Amassing",
          coord = { map = 2395, x = 0.390, y = 0.616 } },  -- giver coord: ATT
        { type = "quest",  questID = 91504, text = "Arcane Amassing (objective 2)",
          coord = { map = 2395, x = 0.335, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91504, text = "Arcane Amassing (objective 1)",
          coord = { map = 2395, x = 0.335, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91504, text = "Turn in: Arcane Amassing",
          coord = { map = 2395, x = 0.402, y = 0.613 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92023, text = "Suspicious Sundries (objective 1)",
          coord = { map = 2395, x = 0.393, y = 0.611 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92023, text = "Suspicious Sundries (objective 2)",
          coord = { map = 2395, x = 0.396, y = 0.606 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92023, text = "Suspicious Sundries (objective 3)",
          coord = { map = 2395, x = 0.407, y = 0.601 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92023, text = "Turn in: Suspicious Sundries", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.407, y = 0.601 } },  -- APR route coord (converted)
        { type = "accept", questID = 92024, text = "House Call",
          coord = { map = 2395, x = 0.407, y = 0.601 } },  -- giver coord: ATT
        { type = "quest",  questID = 92024, text = "House Call (objective 1)",
          coord = { map = 2395, x = 0.376, y = 0.721 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92024, text = "House Call (objective 2)",
          coord = { map = 2395, x = 0.375, y = 0.723 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92024, text = "House Call (objective 3)",
          coord = { map = 2395, x = 0.374, y = 0.721 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92024, text = "Turn in: House Call", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.375, y = 0.721 } },  -- APR route coord (converted)
        { type = "accept", questID = 92025, text = "Flowers for Amalthea",
          coord = { map = 2395, x = 0.374, y = 0.721 } },  -- giver coord: ATT
        { type = "quest",  questID = 92025, text = "Flowers for Amalthea (objective 1)",
          coord = { map = 2395, x = 0.328, y = 0.788 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92025, text = "Flowers for Amalthea (objective 2)",
          coord = { map = 2395, x = 0.328, y = 0.788 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92025, text = "Flowers for Amalthea (objective 3)",
          coord = { map = 2395, x = 0.328, y = 0.788 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92025, text = "Flowers for Amalthea (objective 4)",
          coord = { map = 2395, x = 0.328, y = 0.788 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92025, text = "Turn in: Flowers for Amalthea", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.328, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 93850, text = "Windrunner Spire: Haunting Melodies",
          coord = { map = 2395, x = 0.355, y = 0.791 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86635, text = "To Deatholme (objective 1,2)",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86635, text = "Turn in: To Deatholme", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- APR route coord (converted)
        { type = "accept", questID = 86636, text = "Void Walk With Me",
          coord = { map = 2395, x = 0.443, y = 0.847 } },  -- giver coord: ATT
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 1)",
          coord = nil },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 2)",
          coord = nil },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "quest",  questID = 86636, text = "Void Walk With Me (objective 3)",
          coord = nil },  -- no coord: inside Eversong Woods (uiMap 2395), APR position not convertible on an outdoor map; scenario/instance step
        { type = "turnin", questID = 86636, text = "Turn in: Void Walk With Me",
          coord = { map = 2395, x = 0.447, y = 0.852 } },  -- APR route coord (converted)
        { type = "accept", questID = 86637, text = "Anything but Reprieve",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- giver coord: ATT
        { type = "quest",  questID = 86637, text = "Anything but Reprieve (objective 1)",
          coord = { map = 2395, x = 0.446, y = 0.853 } },  -- APR route coord (converted)
        { type = "accept", questID = 87399, text = "Facing the Sun",
          coord = { map = 2395, x = 0.505, y = 0.782 } },  -- giver coord: ATT
        { type = "accept", questID = 91271, text = "A Fish!",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- giver coord: ATT
        { type = "quest",  questID = 91271, text = "A Fish! (objective 1)",
          coord = { map = 2395, x = 0.498, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 2)",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 3)",
          coord = { map = 2395, x = 0.492, y = 0.762 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 4)",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 5)",
          coord = { map = 2395, x = 0.487, y = 0.754 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 6)",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91271, text = "A Fish! (objective 7)",
          coord = { map = 2395, x = 0.487, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91271, text = "Turn in: A Fish!", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "accept", questID = 91328, text = "Secret Ingredients",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- giver coord: ATT
        { type = "accept", questID = 91090, text = "Pesky Pests",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- giver coord: ATT
        { type = "quest",  questID = 91090, text = "Pesky Pests (objective 1)",
          coord = { map = 2395, x = 0.493, y = 0.756 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91090, text = "Pesky Pests (objective 2)",
          coord = { map = 2395, x = 0.481, y = 0.753 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91328, text = "Secret Ingredients (objective 2,1)",
          coord = { map = 2395, x = 0.481, y = 0.753 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91090, text = "Turn in: Pesky Pests", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91328, text = "Turn in: Secret Ingredients", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "accept", questID = 91137, text = "Lost in Light",
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- giver coord: ATT
        { type = "quest",  questID = 91137, text = "Lost in Light (objective 1)",
          coord = { map = 2395, x = 0.502, y = 0.740 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91137, text = "Turn in: Lost in Light", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.488, y = 0.767 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87399, text = "Facing the Sun (objective 1)",
          coord = { map = 2395, x = 0.511, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87399, text = "Turn in: Facing the Sun", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.505, y = 0.782 } },  -- APR route coord (converted)
        { type = "accept", questID = 87400, text = "Scattered in Sunbeams",
          coord = { map = 2395, x = 0.505, y = 0.782 } },  -- giver coord: ATT
        { type = "accept", questID = 87401, text = "Gardener Mishap",
          coord = { map = 2395, x = 0.505, y = 0.781 } },  -- giver coord: ATT
        { type = "quest",  questID = 87400, text = "Scattered in Sunbeams (objective 1) [1/3]",
          coord = { map = 2395, x = 0.532, y = 0.739 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87400, text = "Scattered in Sunbeams (objective 1) [2/3]",
          coord = { map = 2395, x = 0.523, y = 0.748 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87400, text = "Scattered in Sunbeams (objective 1) [3/3]",
          coord = { map = 2395, x = 0.515, y = 0.735 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87401, text = "Gardener Mishap (objective 1)",
          coord = { map = 2395, x = 0.524, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87400, text = "Turn in: Scattered in Sunbeams", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.505, y = 0.782 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87401, text = "Turn in: Gardener Mishap", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.505, y = 0.781 } },  -- APR route coord (converted)
        { type = "accept", questID = 87402, text = "The Light Provides",
          coord = { map = 2395, x = 0.505, y = 0.781 } },  -- giver coord: ATT
        { type = "quest",  questID = 87402, text = "The Light Provides (objective 1)", useItem = 246441,
          coord = { map = 2395, x = 0.513, y = 0.767 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87402, text = "The Light Provides (objective 2)",
          coord = { map = 2395, x = 0.514, y = 0.765 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87402, text = "Turn in: The Light Provides", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.505, y = 0.781 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86637, text = "Turn in: Anything but Reprieve", rep = { { factionID = 2710, amount = 10 } },
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
        { type = "turnin", questID = 86638, text = "Turn in: Choking Tendrils", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.535, y = 0.546 } },  -- APR route coord (converted)
        { type = "accept", questID = 86640, text = "Premonition",
          coord = { map = 2395, x = 0.535, y = 0.546 } },  -- giver coord: ATT
        { type = "turnin", questID = 86640, text = "Turn in: Premonition", rep = { { factionID = 2710, amount = 10 } },
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
        { type = "turnin", questID = 86641, text = "Turn in: Old Scars", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86642, text = "Turn in: A Foe Unseen", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- APR route coord (converted)
        { type = "accept", questID = 86643, text = "Following the Root",
          coord = { map = 2395, x = 0.645, y = 0.487 } },  -- giver coord: ATT
        { type = "quest",  questID = 86643, text = "Following the Root (objective 2)",
          coord = { map = 2395, x = 0.645, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92396, text = "Calling in the Cavalry (objective 4)",
          coord = { map = 2395, x = 0.616, y = 0.627 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92396, text = "Turn in: Calling in the Cavalry", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.617, y = 0.629 } },  -- APR route coord (converted)
        { type = "accept", questID = 92397, text = "Dawnstar Defense",
          coord = { map = 2395, x = 0.617, y = 0.629 } },  -- giver coord: ATT
        { type = "quest",  questID = 92397, text = "Dawnstar Defense (objective 1)",
          coord = { map = 2395, x = 0.617, y = 0.627 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92397, text = "Turn in: Dawnstar Defense", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.617, y = 0.629 } },  -- APR route coord (converted)
        { type = "accept", questID = 92398, text = "And Then They Came",
          coord = { map = 2395, x = 0.617, y = 0.629 } },  -- giver coord: ATT
        { type = "quest",  questID = 92398, text = "And Then They Came (objective 1)",
          coord = { map = 2395, x = 0.607, y = 0.624 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92398, text = "And Then They Came (objective 2)",
          coord = { map = 2395, x = 0.607, y = 0.623 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92398, text = "Turn in: And Then They Came", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.617, y = 0.629 } },  -- APR route coord (converted)
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
        { type = "turnin", questID = 86643, text = "Turn in: Following the Root", rep = { { factionID = 2710, amount = 10 } },
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
        { type = "turnin", questID = 86644, text = "Turn in: Gods Before Us", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 86646, text = "An Impasse",
          coord = { map = 2579, x = 0.171, y = 0.365 } },  -- giver coord: ATT
        { type = "quest",  questID = 86646, text = "An Impasse (objective 1)",
          coord = { map = 2395, x = 0.539, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86646, text = "Turn in: An Impasse",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- APR route coord (converted)
        { type = "accept", questID = 86647, text = "Beat of Blood",
          coord = { map = 2395, x = 0.547, y = 0.682 } },  -- giver coord: ATT
        { type = "turnin", questID = 86647, text = "Turn in: Beat of Blood", rep = { { factionID = 2710, amount = 10 } },
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
        { type = "turnin", questID = 86648, text = "Turn in: Light Guide Us", rep = { { factionID = 2710, amount = 1500 } },
          coord = { map = 2395, x = 0.603, y = 0.814 } },  -- APR route coord (converted)
        { type = "accept", questID = 86649, text = "Past Redemption",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 86649, text = "Past Redemption (objective 1)",
          coord = { map = 2395, x = 0.602, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86649, text = "Turn in: Past Redemption", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- APR route coord (converted)
        { type = "accept", questID = 86650, text = "Fractured",
          coord = { map = 2395, x = 0.606, y = 0.815 } },  -- giver coord: ATT
        { type = "quest",  questID = 86650, text = "Fractured (objective 1)",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86650, text = "Turn in: Fractured", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 94393, text = "Career Counseling",
          coord = { map = 2393, x = 0.332, y = 0.741 } },  -- giver coord: ATT
        { type = "accept", questID = 94396, text = "Down a Peg",
          coord = { map = 2393, x = 0.332, y = 0.741 } },  -- giver coord: ATT
        { type = "accept", questID = 89383, text = "One Adventurous Hatchling",
          coord = { map = 2395, x = 0.568, y = 0.356 } },  -- giver coord: ATT
        { type = "accept", questID = 89384, text = "A Hungry Flock",
          coord = { map = 2395, x = 0.568, y = 0.356 } },  -- giver coord: ATT
        { type = "accept", questID = 89386, text = "A Roost-ed Development",
          coord = { map = 2395, x = 0.568, y = 0.356 } },  -- giver coord: ATT
        { type = "quest",  questID = 89383, text = "One Adventurous Hatchling (objective 1)",
          coord = { map = 2393, x = 0.561, y = 0.973 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89384, text = "A Hungry Flock (objective 1)",
          coord = { map = 2395, x = 0.532, y = 0.361 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89386, text = "A Roost-ed Development (objective 1)",
          coord = { map = 2395, x = 0.532, y = 0.361 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89383, text = "Turn in: One Adventurous Hatchling", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.667, y = 0.984 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89384, text = "Turn in: A Hungry Flock", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.667, y = 0.984 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89386, text = "Turn in: A Roost-ed Development", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.667, y = 0.984 } },  -- APR route coord (converted)
        { type = "accept", questID = 91342, text = "If You Want It Done Right",
          coord = { map = 2395, x = 0.574, y = 0.399 } },  -- giver coord: ATT
        { type = "accept", questID = 91452, text = "Range of Knowledge",
          coord = { map = 2395, x = 0.574, y = 0.399 } },  -- giver coord: ATT
        { type = "quest",  questID = 91452, text = "Range of Knowledge (objective 2)",
          coord = { map = 2395, x = 0.565, y = 0.406 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91452, text = "Range of Knowledge (objective 1)",
          coord = { map = 2395, x = 0.572, y = 0.421 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91452, text = "Range of Knowledge (objective 3)",
          coord = { map = 2395, x = 0.569, y = 0.431 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91342, text = "If You Want It Done Right (objective 1)",
          coord = { map = 2395, x = 0.568, y = 0.419 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91452, text = "Range of Knowledge (objective 4)",
          coord = { map = 2395, x = 0.567, y = 0.410 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91452, text = "Range of Knowledge (objective 5)",
          coord = { map = 2395, x = 0.567, y = 0.410 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91342, text = "Turn in: If You Want It Done Right", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.567, y = 0.410 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91452, text = "Turn in: Range of Knowledge", repUnverified = true,
          coord = { map = 2395, x = 0.567, y = 0.410 } },  -- APR route coord (converted)
        { type = "accept", questID = 91462, text = "To the Central Tower",
          coord = { map = 2395, x = 0.567, y = 0.408 } },  -- giver coord: ATT
        { type = "accept", questID = 91345, text = "To the North Tower",
          coord = { map = 2395, x = 0.567, y = 0.408 } },  -- giver coord: ATT
        { type = "turnin", questID = 91345, text = "Turn in: To the North Tower", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.497, y = 0.483 } },  -- APR route coord (converted)
        { type = "accept", questID = 91347, text = "Strider Stampede",
          coord = { map = 2395, x = 0.497, y = 0.483 } },  -- giver coord: ATT
        { type = "quest",  questID = 91347, text = "Strider Stampede (objective 1)",
          coord = { map = 2395, x = 0.504, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91347, text = "Strider Stampede (objective 2)",
          coord = { map = 2395, x = 0.508, y = 0.488 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91347, text = "Strider Stampede (objective 3)",
          coord = { map = 2395, x = 0.509, y = 0.491 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91347, text = "Strider Stampede (objective 4)",
          coord = { map = 2395, x = 0.504, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91347, text = "Turn in: Strider Stampede", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.504, y = 0.485 } },  -- APR route coord (converted)
        { type = "accept", questID = 94388, text = "Second Time's a Choice",
          coord = { map = 2395, x = 0.445, y = 0.454 } },  -- giver coord: ATT
        { type = "quest",  questID = 87394, text = "Supplier Surveillance (objective 1)",
          coord = { map = 2395, x = 0.405, y = 0.443 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87394, text = "Supplier Surveillance (objective 2)",
          coord = { map = 2395, x = 0.395, y = 0.452 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87394, text = "Supplier Surveillance (objective 3)",
          coord = { map = 2395, x = 0.396, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87394, text = "Supplier Surveillance (objective 4)",
          coord = { map = 2395, x = 0.396, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87393, text = "Warranted Search (objective 1)",
          coord = { map = 2395, x = 0.394, y = 0.445 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87393, text = "Turn in: Warranted Search", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.395, y = 0.450 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87394, text = "Turn in: Supplier Surveillance", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.395, y = 0.450 } },  -- APR route coord (converted)
        { type = "accept", questID = 87395, text = "Below the Brine",
          coord = { map = 2395, x = 0.395, y = 0.450 } },  -- giver coord: ATT
        { type = "quest",  questID = 87395, text = "Below the Brine (objective 1)", useItem = 239022,
          coord = { map = 2395, x = 0.394, y = 0.441 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87395, text = "Below the Brine (objective 2)", useItem = 239022,
          coord = { map = 2395, x = 0.394, y = 0.435 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87395, text = "Turn in: Below the Brine", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- APR route coord (converted)
        { type = "accept", questID = 87397, text = "Cargo Collateral",
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- giver coord: ATT
        { type = "accept", questID = 87396, text = "Dead to Rights",
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- giver coord: ATT
        { type = "quest",  questID = 87396, text = "Dead to Rights (objective 1)",
          coord = { map = 2395, x = 0.348, y = 0.450 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87397, text = "Cargo Collateral (objective 1)",
          coord = { map = 2395, x = 0.348, y = 0.450 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87397, text = "Turn in: Cargo Collateral", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87396, text = "Turn in: Dead to Rights", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- APR route coord (converted)
        { type = "accept", questID = 87398, text = "Smuggler Showdown",
          coord = { map = 2395, x = 0.358, y = 0.438 } },  -- giver coord: ATT
        { type = "quest",  questID = 87398, text = "Smuggler Showdown (objective 2)",
          coord = { map = 2395, x = 0.376, y = 0.443 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87398, text = "Turn in: Smuggler Showdown", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.378, y = 0.446 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94388, text = "Turn in: Second Time's a Choice", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.411, y = 0.385 } },  -- APR route coord (converted)
        { type = "accept", questID = 88977, text = "Reenact the Crime",
          coord = { map = 2395, x = 0.411, y = 0.385 } },  -- giver coord: ATT
        { type = "accept", questID = 88978, text = "Tracking the Trail",
          coord = { map = 2395, x = 0.411, y = 0.385 } },  -- giver coord: ATT
        { type = "quest",  questID = 88977, text = "Reenact the Crime (objective 1)", useItem = 238730,
          coord = { map = 2395, x = 0.411, y = 0.385 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88977, text = "Reenact the Crime (objective 2) [1/3]", useItem = 238730,
          coord = { map = 2395, x = 0.412, y = 0.392 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88977, text = "Reenact the Crime (objective 2) [2/3]", useItem = 238730,
          coord = { map = 2395, x = 0.403, y = 0.387 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88977, text = "Reenact the Crime (objective 2) [3/3]", useItem = 238730,
          coord = { map = 2395, x = 0.396, y = 0.389 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88978, text = "Tracking the Trail (objective 1)",
          coord = { map = 2395, x = 0.407, y = 0.391 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88978, text = "Turn in: Tracking the Trail", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.396, y = 0.391 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88977, text = "Turn in: Reenact the Crime", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.396, y = 0.391 } },  -- APR route coord (converted)
        { type = "accept", questID = 88979, text = "Caught Red-Handed",
          coord = { map = 2395, x = 0.385, y = 0.396 } },  -- giver coord: ATT
        { type = "quest",  questID = 88979, text = "Caught Red-Handed (objective 1)",
          coord = { map = 2395, x = 0.383, y = 0.393 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88979, text = "Caught Red-Handed (objective 2)",
          coord = { map = 2395, x = 0.381, y = 0.392 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88979, text = "Turn in: Caught Red-Handed", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.398, y = 0.393 } },  -- APR route coord (converted)
        { type = "accept", questID = 90544, text = "Thief at Bark",
          coord = { map = 2395, x = 0.399, y = 0.393 } },  -- giver coord: ATT
        { type = "quest",  questID = 90544, text = "Thief at Bark (objective 1)",
          coord = { map = 2395, x = 0.389, y = 0.386 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90544, text = "Turn in: Thief at Bark", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.389, y = 0.386 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91462, text = "Turn in: To the Central Tower", repUnverified = true,
          coord = { map = 2395, x = 0.486, y = 0.576 } },  -- APR route coord (converted)
        { type = "accept", questID = 91348, text = "See a Mana 'bout a Wyrm",
          coord = { map = 2395, x = 0.486, y = 0.576 } },  -- giver coord: ATT
        { type = "quest",  questID = 91348, text = "See a Mana 'bout a Wyrm (objective 1)",
          coord = { map = 2395, x = 0.484, y = 0.565 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91348, text = "See a Mana 'bout a Wyrm (objective 2)",
          coord = { map = 2395, x = 0.486, y = 0.577 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91348, text = "See a Mana 'bout a Wyrm (objective 3)",
          coord = { map = 2395, x = 0.486, y = 0.576 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91348, text = "Turn in: See a Mana 'bout a Wyrm", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.486, y = 0.576 } },  -- APR route coord (converted)
        { type = "accept", questID = 91463, text = "To the South Tower",
          coord = { map = 2395, x = 0.486, y = 0.576 } },  -- giver coord: ATT
        { type = "turnin", questID = 91463, text = "Turn in: To the South Tower",
          coord = { map = 2395, x = 0.439, y = 0.755 } },  -- APR route coord (converted)
        { type = "accept", questID = 91349, text = "The Dark Part of the Woods",
          coord = { map = 2395, x = 0.439, y = 0.755 } },  -- giver coord: ATT
        { type = "quest",  questID = 91349, text = "The Dark Part of the Woods (objective 1)", useItem = 248244,
          coord = { map = 2395, x = 0.448, y = 0.780 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91349, text = "The Dark Part of the Woods (objective 2)",
          coord = { map = 2395, x = 0.429, y = 0.791 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91349, text = "The Dark Part of the Woods (objective 3)",
          coord = { map = 2395, x = 0.429, y = 0.791 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91349, text = "The Dark Part of the Woods (objective 4)",
          coord = { map = 2395, x = 0.428, y = 0.792 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91349, text = "Turn in: The Dark Part of the Woods", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.435, y = 0.750 } },  -- APR route coord (converted)
        { type = "accept", questID = 91350, text = "A Real Assignment",
          coord = { map = 2395, x = 0.435, y = 0.750 } },  -- giver coord: ATT
        { type = "turnin", questID = 91350, text = "Turn in: A Real Assignment", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.594, y = 0.688 } },  -- APR route coord (converted)
        { type = "accept", questID = 91384, text = "Recovery Mission",
          coord = { map = 2395, x = 0.594, y = 0.688 } },  -- giver coord: ATT
        { type = "accept", questID = 91383, text = "Tidy Up",
          coord = { map = 2395, x = 0.594, y = 0.689 } },  -- giver coord: ATT
        { type = "quest",  questID = 91383, text = "Tidy Up (objective 1,2)",
          coord = { map = 2395, x = 0.594, y = 0.681 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91384, text = "Recovery Mission (objective 1)",
          coord = { map = 2395, x = 0.594, y = 0.691 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91384, text = "Turn in: Recovery Mission", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.594, y = 0.688 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91383, text = "Turn in: Tidy Up", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.594, y = 0.688 } },  -- APR route coord (converted)
        { type = "accept", questID = 91385, text = "A Ranger's Spirit",
          coord = { map = 2395, x = 0.594, y = 0.688 } },  -- giver coord: ATT
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 1)",
          coord = { map = 2395, x = 0.595, y = 0.671 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 2)",
          coord = { map = 2395, x = 0.594, y = 0.666 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 3)",
          coord = { map = 2395, x = 0.592, y = 0.663 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 4)",
          coord = { map = 2395, x = 0.589, y = 0.659 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 5)",
          coord = { map = 2395, x = 0.591, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 6)",
          coord = { map = 2395, x = 0.589, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 7)",
          coord = { map = 2395, x = 0.590, y = 0.643 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 8)",
          coord = { map = 2395, x = 0.592, y = 0.640 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 9)",
          coord = { map = 2395, x = 0.594, y = 0.638 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91385, text = "A Ranger's Spirit (objective 10)",
          coord = { map = 2395, x = 0.595, y = 0.630 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91385, text = "Turn in: A Ranger's Spirit", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.595, y = 0.671 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94396, text = "Turn in: Down a Peg", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.083, y = 0.376 } },  -- APR route coord (converted)
        { type = "accept", questID = 86997, text = "Spellbook Scuffle",
          coord = { map = 2395, x = 0.394, y = 0.175 } },  -- giver coord: ATT
        { type = "quest",  questID = 86997, text = "Spellbook Scuffle (objective 1)",
          coord = { map = 2393, x = 0.047, y = 0.369 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86997, text = "Turn in: Spellbook Scuffle", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.015, y = 0.419 } },  -- APR route coord (converted)
        { type = "accept", questID = 86998, text = "Training Arc",
          coord = { map = 2395, x = 0.374, y = 0.187 } },  -- giver coord: ATT
        { type = "quest",  questID = 86998, text = "Training Arc (objective 1)",
          coord = { map = 2393, x = 0.034, y = 0.396 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86998, text = "Turn in: Training Arc", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.052, y = 0.418 } },  -- APR route coord (converted)
        { type = "accept", questID = 87002, text = "Academic Aspirations",
          coord = { map = 2395, x = 0.385, y = 0.187 } },  -- giver coord: ATT
        { type = "quest",  questID = 87002, text = "Academic Aspirations (objective 2)",
          coord = { map = 2393, x = 0.040, y = 0.407 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87002, text = "Turn in: Academic Aspirations", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.079, y = 0.370 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94393, text = "Turn in: Career Counseling", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.189, y = 0.280 } },  -- APR route coord (converted)
        { type = "accept", questID = 91284, text = "A Path Not Yet Chosen",
          coord = { map = 2395, x = 0.426, y = 0.146 } },  -- giver coord: ATT
        { type = "accept", questID = 91292, text = "A Test of the Arcane",
          coord = { map = 2395, x = 0.432, y = 0.147 } },  -- giver coord: ATT
        { type = "accept", questID = 91291, text = "A Test of Blood",
          coord = { map = 2395, x = 0.430, y = 0.138 } },  -- giver coord: ATT
        { type = "quest",  questID = 91291, text = "A Test of Blood (objective 2)",
          coord = { map = 2393, x = 0.217, y = 0.284 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91291, text = "Turn in: A Test of Blood", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2393, x = 0.202, y = 0.253 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91284, text = "A Path Not Yet Chosen (objective 2)",
          coord = { map = 2393, x = 0.202, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 91288, text = "A Test of the Hunt",
          coord = { map = 2395, x = 0.422, y = 0.133 } },  -- giver coord: ATT
        { type = "quest",  questID = 91292, text = "A Test of the Arcane (objective 1)",
          coord = { map = 2393, x = 0.168, y = 0.476 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91288, text = "A Test of the Hunt (objective 1)",
          coord = { map = 2393, x = 0.157, y = 0.303 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91292, text = "Turn in: A Test of the Arcane", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.210, y = 0.283 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91284, text = "A Path Not Yet Chosen (objective 3)",
          coord = { map = 2393, x = 0.210, y = 0.283 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91288, text = "Turn in: A Test of the Hunt", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.175, y = 0.236 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91284, text = "A Path Not Yet Chosen (objective 1)",
          coord = { map = 2393, x = 0.175, y = 0.236 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91284, text = "Turn in: A Path Not Yet Chosen", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.190, y = 0.280 } },  -- APR route coord (converted)
        { type = "accept", questID = 91301, text = "How to Train Your Protege",
          coord = { map = 2395, x = 0.426, y = 0.146 } },  -- giver coord: ATT
        { type = "quest",  questID = 91301, text = "How to Train Your Protege (objective 1)",
          coord = { map = 2393, x = 0.190, y = 0.280 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91301, text = "How to Train Your Protege (objective 2)",
          coord = { map = 2393, x = 0.332, y = 0.741 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91301, text = "Turn in: How to Train Your Protege", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.332, y = 0.741 } },  -- APR route coord (converted)
        { type = "accept", questID = 87455, text = "Trials and Tabulations",
          coord = { map = 2393, x = 0.576, y = 0.688 } },  -- giver coord: ATT
        { type = "accept", questID = 90835, text = "Murder Row: Rumors Abound",
          coord = { map = 2393, x = 0.560, y = 0.636 } },  -- giver coord: ATT
        { type = "accept", questID = 90669, text = "Gold is Gold",
          coord = { map = 2393, x = 0.545, y = 0.615 } },  -- giver coord: ATT
        { type = "turnin", questID = 90835, text = "Turn in: Murder Row: Rumors Abound", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.517, y = 0.642 } },  -- APR route coord (converted)
        { type = "accept", questID = 90837, text = "Murder Row: Traces of Fel",
          coord = { map = 2393, x = 0.517, y = 0.642 } },  -- giver coord: ATT
        { type = "accept", questID = 90818, text = "Murder Row: Loose Lips",
          coord = { map = 2393, x = 0.517, y = 0.642 } },  -- giver coord: ATT
        { type = "quest",  questID = 90818, text = "Murder Row: Loose Lips (objective 1) [1/3]",
          coord = { map = 2393, x = 0.524, y = 0.636 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90837, text = "Murder Row: Traces of Fel (objective 1) [1/5]",
          coord = { map = 2393, x = 0.511, y = 0.562 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90818, text = "Murder Row: Loose Lips (objective 1) [2/3]",
          coord = { map = 2393, x = 0.523, y = 0.606 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90837, text = "Murder Row: Traces of Fel (objective 1) [2/5]",
          coord = { map = 2393, x = 0.520, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90837, text = "Murder Row: Traces of Fel (objective 1) [3/5]",
          coord = { map = 2393, x = 0.548, y = 0.611 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90818, text = "Murder Row: Loose Lips (objective 1) [3/3]",
          coord = { map = 2393, x = 0.514, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90837, text = "Murder Row: Traces of Fel (objective 1) [4/5]",
          coord = { map = 2393, x = 0.506, y = 0.582 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90837, text = "Murder Row: Traces of Fel (objective 1) [5/5]",
          coord = { map = 2393, x = 0.522, y = 0.559 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90837, text = "Turn in: Murder Row: Traces of Fel", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.562, y = 0.567 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90818, text = "Turn in: Murder Row: Loose Lips", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.562, y = 0.567 } },  -- APR route coord (converted)
        { type = "accept", questID = 90819, text = "Murder Row: Acting the Part",
          coord = { map = 2393, x = 0.561, y = 0.567 } },  -- giver coord: ATT
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 1)",
          coord = { map = 2393, x = 0.562, y = 0.567 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 2) [1/3]",
          coord = { map = 2393, x = 0.530, y = 0.527 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 2) [2/3]",
          coord = { map = 2393, x = 0.565, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 2) [3/3]",
          coord = { map = 2393, x = 0.506, y = 0.480 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 3)",
          coord = { map = 2393, x = 0.563, y = 0.541 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 4)",
          coord = { map = 2393, x = 0.577, y = 0.521 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 5)",
          coord = { map = 2393, x = 0.577, y = 0.521 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90819, text = "Murder Row: Acting the Part (objective 6)",
          coord = { map = 2393, x = 0.580, y = 0.520 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90819, text = "Turn in: Murder Row: Acting the Part", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.545, y = 0.548 } },  -- APR route coord (converted)
        { type = "accept", questID = 90821, text = "Murder Row: Harbored Secrets",
          coord = { map = 2393, x = 0.545, y = 0.548 } },  -- giver coord: ATT
        { type = "turnin", questID = 90669, text = "Turn in: Gold is Gold", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.540, y = 0.341 } },  -- APR route coord (converted)
        { type = "accept", questID = 89199, text = "A Small Task",
          coord = { map = 2393, x = 0.540, y = 0.341 } },  -- giver coord: ATT
        { type = "quest",  questID = 89199, text = "A Small Task (objective 1)",
          coord = { map = 2393, x = 0.540, y = 0.339 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89199, text = "A Small Task (objective 2) [1/4]",
          coord = { map = 2393, x = 0.537, y = 0.334 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89199, text = "A Small Task (objective 2) [2/4]",
          coord = { map = 2393, x = 0.540, y = 0.328 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89199, text = "A Small Task (objective 2) [3/4]",
          coord = { map = 2393, x = 0.545, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89199, text = "A Small Task (objective 2) [4/4]",
          coord = { map = 2393, x = 0.543, y = 0.340 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89199, text = "Turn in: A Small Task", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.541, y = 0.339 } },  -- APR route coord (converted)
        { type = "accept", questID = 89200, text = "Unraveling Wards",
          coord = { map = 2393, x = 0.541, y = 0.339 } },  -- giver coord: ATT
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 1) [1/5]",
          coord = { map = 2393, x = 0.536, y = 0.338 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 2) [1/5]",
          coord = { map = 2393, x = 0.536, y = 0.338 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 1) [2/5]",
          coord = { map = 2393, x = 0.493, y = 0.425 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 2) [2/5]",
          coord = { map = 2393, x = 0.493, y = 0.425 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 1) [3/5]",
          coord = { map = 2393, x = 0.528, y = 0.445 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 2) [3/5]",
          coord = { map = 2393, x = 0.528, y = 0.444 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 1) [4/5]",
          coord = { map = 2393, x = 0.536, y = 0.769 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 2) [4/5]",
          coord = { map = 2393, x = 0.536, y = 0.769 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89200, text = "Unraveling Wards (objective 1) [5/5]",
          coord = { map = 2393, x = 0.315, y = 0.678 } },  -- APR route coord (converted)
        { type = "accept", questID = 92729, text = "Hounded and Hassled",
          coord = { map = 2393, x = 0.357, y = 0.690 } },  -- giver coord: ATT
        { type = "turnin", questID = 89200, text = "Turn in: Unraveling Wards", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.374, y = 0.743 } },  -- APR route coord (converted)
        { type = "accept", questID = 89201, text = "Outschemed",
          coord = { map = 2393, x = 0.374, y = 0.743 } },  -- giver coord: ATT
        { type = "quest",  questID = 89201, text = "Outschemed (objective 1)",
          coord = { map = 2393, x = 0.378, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89201, text = "Outschemed (objective 2)",
          coord = { map = 2393, x = 0.389, y = 0.755 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89201, text = "Turn in: Outschemed", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.388, y = 0.757 } },  -- APR route coord (converted)
        { type = "accept", questID = 89202, text = "Stir the Nest",
          coord = { map = 2393, x = 0.388, y = 0.757 } },  -- giver coord: ATT
        { type = "accept", questID = 94012, text = "Lost Lil' Strider",
          coord = { map = 2393, x = 0.418, y = 0.764 } },  -- giver coord: ATT
        { type = "quest",  questID = 94012, text = "Lost Lil' Strider (objective 1)",
          coord = { map = 2393, x = 0.367, y = 0.708 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94012, text = "Lost Lil' Strider (objective 2)",
          coord = { map = 2393, x = 0.309, y = 0.669 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94012, text = "Lost Lil' Strider (objective 3)",
          coord = { map = 2393, x = 0.363, y = 0.665 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92729, text = "Turn in: Hounded and Hassled", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.355, y = 0.578 } },  -- APR route coord (converted)
        { type = "accept", questID = 92728, text = "Dogged Disturbances",
          coord = { map = 2393, x = 0.354, y = 0.578 } },  -- giver coord: ATT
        { type = "quest",  questID = 92728, text = "Dogged Disturbances (objective 1)",
          coord = { map = 2393, x = 0.343, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92728, text = "Turn in: Dogged Disturbances", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.353, y = 0.578 } },  -- APR route coord (converted)
        { type = "accept", questID = 92868, text = "He Went Thataway",
          coord = { map = 2393, x = 0.354, y = 0.578 } },  -- giver coord: ATT
        { type = "turnin", questID = 92868, text = "Turn in: He Went Thataway", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.448, y = 0.604 } },  -- APR route coord (converted)
        { type = "accept", questID = 92869, text = "Fishy Dis-pondencies",
          coord = { map = 2393, x = 0.448, y = 0.604 } },  -- giver coord: ATT
        { type = "quest",  questID = 92869, text = "Fishy Dis-pondencies (objective 1)",
          coord = { map = 2393, x = 0.457, y = 0.604 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92869, text = "Turn in: Fishy Dis-pondencies", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.448, y = 0.604 } },  -- APR route coord (converted)
        { type = "accept", questID = 92870, text = "Scoot Along Now",
          coord = { map = 2393, x = 0.448, y = 0.604 } },  -- giver coord: ATT
        { type = "quest",  questID = 92870, text = "Scoot Along Now (objective 1)",
          coord = { map = 2393, x = 0.423, y = 0.619 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [1/8]",
          coord = { map = 2393, x = 0.504, y = 0.575 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [2/8]",
          coord = { map = 2393, x = 0.509, y = 0.597 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [3/8]",
          coord = { map = 2393, x = 0.514, y = 0.599 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [4/8]",
          coord = { map = 2393, x = 0.519, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [5/8]",
          coord = { map = 2393, x = 0.526, y = 0.589 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [6/8]",
          coord = { map = 2393, x = 0.531, y = 0.596 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [7/8]",
          coord = { map = 2393, x = 0.532, y = 0.596 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89202, text = "Stir the Nest (objective 1) [8/8]",
          coord = { map = 2393, x = 0.541, y = 0.611 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89202, text = "Turn in: Stir the Nest", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.518, y = 0.638 } },  -- APR route coord (converted)
        { type = "accept", questID = 89203, text = "Mutual Benefit",
          coord = { map = 2393, x = 0.518, y = 0.638 } },  -- giver coord: ATT
        { type = "quest",  questID = 89203, text = "Mutual Benefit (objective 1)",
          coord = { map = 2393, x = 0.518, y = 0.638 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89203, text = "Turn in: Mutual Benefit", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.518, y = 0.638 } },  -- APR route coord (converted)
        { type = "accept", questID = 89204, text = "Five Finger Discount",
          coord = { map = 2393, x = 0.518, y = 0.638 } },  -- giver coord: ATT
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 1)",
          coord = { map = 2393, x = 0.486, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 2)",
          coord = { map = 2393, x = 0.495, y = 0.623 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 3)",
          coord = { map = 2393, x = 0.359, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 4)",
          coord = { map = 2393, x = 0.357, y = 0.615 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92870, text = "Turn in: Scoot Along Now", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.357, y = 0.690 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 5)",
          coord = { map = 2393, x = 0.426, y = 0.529 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89204, text = "Five Finger Discount (objective 6)",
          coord = { map = 2393, x = 0.405, y = 0.525 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89204, text = "Turn in: Five Finger Discount", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2393, x = 0.508, y = 0.611 } },  -- APR route coord (converted)
        { type = "accept", questID = 89205, text = "Cutting a Key",
          coord = { map = 2393, x = 0.508, y = 0.611 } },  -- giver coord: ATT
        { type = "quest",  questID = 89205, text = "Cutting a Key (objective 1)",
          coord = { map = 2393, x = 0.510, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89205, text = "Cutting a Key (objective 2)",
          coord = { map = 2393, x = 0.508, y = 0.612 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89205, text = "Cutting a Key (objective 3)",
          coord = { map = 2393, x = 0.508, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89205, text = "Cutting a Key (objective 4)",
          coord = { map = 2393, x = 0.508, y = 0.613 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89205, text = "Cutting a Key (objective 5)",
          coord = { map = 2393, x = 0.509, y = 0.609 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89205, text = "Turn in: Cutting a Key", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.543, y = 0.338 } },  -- APR route coord (converted)
        { type = "accept", questID = 89206, text = "Break and Enter",
          coord = { map = 2393, x = 0.543, y = 0.338 } },  -- giver coord: ATT
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 1)",
          coord = { map = 2393, x = 0.543, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [1/6]",
          coord = { map = 2393, x = 0.542, y = 0.338 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [2/6]",
          coord = { map = 2393, x = 0.539, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [3/6]",
          coord = { map = 2393, x = 0.537, y = 0.332 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [4/6]",
          coord = { map = 2393, x = 0.539, y = 0.327 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [5/6]",
          coord = { map = 2393, x = 0.544, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89206, text = "Break and Enter (objective 2) [6/6]",
          coord = { map = 2393, x = 0.544, y = 0.334 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89206, text = "Turn in: Break and Enter", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.542, y = 0.338 } },  -- APR route coord (converted)
        { type = "accept", questID = 89207, text = "Rats Can Bite",
          coord = { map = 2393, x = 0.543, y = 0.339 } },  -- giver coord: ATT
        { type = "quest",  questID = 89207, text = "Rats Can Bite (objective 1)",
          coord = { map = 2393, x = 0.541, y = 0.333 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89207, text = "Turn in: Rats Can Bite", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2393, x = 0.530, y = 0.332 } },  -- APR route coord (converted)
        { type = "accept", questID = 89208, text = "What We're Owed",
          coord = { map = 2393, x = 0.530, y = 0.332 } },  -- giver coord: ATT
        { type = "quest",  questID = 90821, text = "Murder Row: Harbored Secrets (objective 1)",
          coord = { map = 2393, x = 0.322, y = 0.260 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90821, text = "Murder Row: Harbored Secrets (objective 2)",
          coord = { map = 2393, x = 0.340, y = 0.265 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90821, text = "Murder Row: Harbored Secrets (objective 3)",
          coord = { map = 2393, x = 0.340, y = 0.265 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90821, text = "Turn in: Murder Row: Harbored Secrets", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.322, y = 0.260 } },  -- APR route coord (converted)
        { type = "accept", questID = 90822, text = "Murder Row: One Fel Swoop",
          coord = { map = 2393, x = 0.322, y = 0.260 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89208, text = "What We're Owed (objective 1)",
          coord = { map = 2393, x = 0.374, y = 0.745 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89208, text = "Turn in: What We're Owed", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.374, y = 0.745 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94012, text = "Turn in: Lost Lil' Strider",
          coord = { map = 2393, x = 0.418, y = 0.764 } },  -- APR route coord (converted)
        { type = "accept", questID = 93965, text = "Pet Wranglin'",
          coord = { map = 2393, x = 0.418, y = 0.764 } },  -- giver coord: ATT
        { type = "turnin", questID = 87455, text = "Turn in: Trials and Tabulations", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.334, y = 0.893 } },  -- APR route coord (converted)
        { type = "accept", questID = 87456, text = "Souvenirs Scattered",
          coord = { map = 2393, x = 0.334, y = 0.894 } },  -- giver coord: ATT
        { type = "accept", questID = 87457, text = "What We Do Best",
          coord = { map = 2393, x = 0.334, y = 0.894 } },  -- giver coord: ATT
        { type = "quest",  questID = 87456, text = "Souvenirs Scattered (objective 2)",
          coord = { map = 2393, x = 0.330, y = 0.892 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87457, text = "What We Do Best (objective 1)",
          coord = { map = 2393, x = 0.335, y = 0.901 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87456, text = "Souvenirs Scattered (objective 3)",
          coord = { map = 2393, x = 0.336, y = 0.897 } },  -- APR route coord (converted)
        { type = "quest",  questID = 87456, text = "Souvenirs Scattered (objective 1)",
          coord = { map = 2393, x = 0.337, y = 0.901 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87456, text = "Turn in: Souvenirs Scattered", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.333, y = 0.904 } },  -- APR route coord (converted)
        { type = "turnin", questID = 87457, text = "Turn in: What We Do Best", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2393, x = 0.333, y = 0.904 } },  -- APR route coord (converted)
        { type = "accept", questID = 87458, text = "Debts Paid",
          coord = { map = 2393, x = 0.333, y = 0.904 } },  -- giver coord: ATT
        { type = "turnin", questID = 87458, text = "Turn in: Debts Paid", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2393, x = 0.576, y = 0.688 } },  -- APR route coord (converted)
        -- (APR: grind/continue to level 90 before the next step)
        { type = "accept", questID = 90546, text = "Missing Paladins", faction = "Alliance",
          coord = { map = 2393, x = 0.532, y = 0.696 } },  -- giver coord: ATT
        { type = "accept", questID = 90547, text = "Missing Paladins", faction = "Horde",
          coord = { map = 2393, x = 0.532, y = 0.697 } },  -- giver coord: ATT
        { type = "turnin", questID = 90546, text = "Turn in: Missing Paladins", rep = { { factionID = 2710, amount = 10 } }, faction = "Alliance",
          coord = { map = 2395, x = 0.440, y = 0.670 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90547, text = "Turn in: Missing Paladins", rep = { { factionID = 2710, amount = 10 } }, faction = "Horde",
          coord = { map = 2395, x = 0.441, y = 0.670 } },  -- APR route coord (converted)
        { type = "accept", questID = 90548, text = "Twilight Missive",
          coord = { map = 2395, x = 0.441, y = 0.670 } },  -- giver coord: ATT
        { type = "accept", questID = 90549, text = "Signs of the Struggle",
          coord = { map = 2395, x = 0.440, y = 0.670 } },  -- giver coord: ATT
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [1/6]",
          coord = { map = 2395, x = 0.431, y = 0.680 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [2/6]",
          coord = { map = 2395, x = 0.429, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [3/6]",
          coord = { map = 2395, x = 0.433, y = 0.691 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [4/6]",
          coord = { map = 2395, x = 0.433, y = 0.699 } },  -- APR route coord (converted)
        { type = "accept", questID = 90550, text = "A Somber Sun", faction = "Horde",
          coord = { map = 2395, x = 0.433, y = 0.698 } },  -- giver coord: ATT
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [5/6]",
          coord = { map = 2395, x = 0.440, y = 0.695 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90549, text = "Signs of the Struggle (objective 1) [6/6]",
          coord = { map = 2395, x = 0.444, y = 0.697 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90548, text = "Twilight Missive (objective 1)",
          coord = { map = 2395, x = 0.436, y = 0.685 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90548, text = "Turn in: Twilight Missive", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.441, y = 0.670 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90550, text = "Turn in: A Somber Sun", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.441, y = 0.670 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90549, text = "Turn in: Signs of the Struggle", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.440, y = 0.670 } },  -- APR route coord (converted)
        { type = "accept", questID = 90551, text = "Captured Information",
          coord = { map = 2395, x = 0.441, y = 0.670 } },  -- giver coord: ATT
        { type = "quest",  questID = 90551, text = "Captured Information (objective 1)",
          coord = { map = 2395, x = 0.422, y = 0.693 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90551, text = "Captured Information (objective 2)",
          coord = { map = 2395, x = 0.416, y = 0.723 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90551, text = "Turn in: Captured Information", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- APR route coord (converted)
        { type = "accept", questID = 90552, text = "Interrogation",
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- giver coord: ATT
        { type = "quest",  questID = 90552, text = "Interrogation (objective 1)",
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90552, text = "Interrogation (objective 2)",
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90552, text = "Turn in: Interrogation", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- APR route coord (converted)
        { type = "accept", questID = 90570, text = "To the Ruins of Deatholme",
          coord = { map = 2395, x = 0.416, y = 0.722 } },  -- giver coord: ATT
        { type = "turnin", questID = 90570, text = "Turn in: To the Ruins of Deatholme", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- APR route coord (converted)
        { type = "accept", questID = 90555, text = "Blessing of Freedom",
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- giver coord: ATT
        { type = "accept", questID = 90553, text = "Executing the Blades",
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- giver coord: ATT
        { type = "accept", questID = 90554, text = "Leave Ashes in Your Wake",
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- giver coord: ATT
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 1)",
          coord = { map = 2395, x = 0.418, y = 0.830 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 2)",
          coord = { map = 2395, x = 0.422, y = 0.837 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 4)",
          coord = { map = 2395, x = 0.413, y = 0.859 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 5)",
          coord = { map = 2395, x = 0.416, y = 0.862 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 3)",
          coord = { map = 2395, x = 0.423, y = 0.852 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 9)",
          coord = { map = 2395, x = 0.424, y = 0.890 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 8)",
          coord = { map = 2395, x = 0.441, y = 0.885 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 7)",
          coord = { map = 2395, x = 0.452, y = 0.874 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90555, text = "Blessing of Freedom (objective 6)",
          coord = { map = 2395, x = 0.434, y = 0.858 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90553, text = "Executing the Blades (objective 1)",
          coord = { map = 2395, x = 0.434, y = 0.856 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90554, text = "Leave Ashes in Your Wake (objective 1)",
          coord = { map = 2395, x = 0.434, y = 0.856 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90553, text = "Turn in: Executing the Blades", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 90554, text = "Turn in: Leave Ashes in Your Wake", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 90555, text = "Turn in: Blessing of Freedom", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 90556, text = "Cutting off the Head",
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- giver coord: ATT
        { type = "quest",  questID = 90556, text = "Cutting off the Head (objective 1)",
          coord = { map = 2395, x = 0.413, y = 0.885 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90556, text = "Cutting off the Head (objective 2)",
          coord = { map = 2395, x = 0.444, y = 0.814 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90556, text = "Turn in: Cutting off the Head", rep = { { factionID = 2710, amount = 250 } },
          coord = { map = 2395, x = 0.444, y = 0.812 } },  -- APR route coord (converted)
    },
}
