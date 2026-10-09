-- ToonAge guide data: Midnight (12.x) "Arator's Journey" campaign chapter (Eastern Kingdoms tour: Burning Steppes, Eastern Plaguelands,
-- Tirisfal / Scarlet Halls, Arathi Highlands, Isle of Quel'Danas, Arcantina)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Midnight leveling 80-90.
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-Arators-Journey"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 32 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 24 accept steps where ATT and converted APR coords share a map: median 0.05, p90 0.09, max 0.12 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: campaign only.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 14 Arathi Highlands, 18 Tirisfal Glades, 23 Eastern Plaguelands, 36 Burning Steppes, 2372 Arathi Highlands, 2393 Silvermoon City, 2424 Isle of Quel'Danas, 2438 Scarlet Halls, 2541 Arcantina
--  * Separate APR route (not a zone): offered after the Eversong campaign and after Voidstorm; APR chains it to Harandar.
--    Whether it is mandatory for the main campaign is UNVERIFIED (APR treats it as an alternative next route).
--  * Arathi Highlands here is uiMap 2372 (current-era Arathi map used by ATT), not classic 14; Scarlet Halls 2438 and Arcantina 2541 are
--    ATT giver maps (micro/instance maps).

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_arators_journey"] = {
    id = "midnight_arators_journey", title = "Midnight: Arator's Journey", expansion = "midnight",
    zone = 2395, minLevel = 80, maxLevel = 90,
    nextGuide = "midnight_harandar_campaign",
    steps = {
        { type = "accept", questID = 89193, text = "Arator",
          coord = { map = 2393, x = 0.455, y = 0.704 } },  -- giver coord: ATT
        { type = "turnin", questID = 89193, text = "Turn in: Arator", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.458, y = 0.658 } },  -- APR route coord (converted)
        { type = "accept", questID = 86837, text = "Meet at the Sunwell",
          coord = { map = 2393, x = 0.458, y = 0.658 } },  -- giver coord: ATT
        { type = "quest",  questID = 86837, text = "Meet at the Sunwell (objective 1)",
          coord = { map = 2393, x = 0.453, y = 0.604 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86837, text = "Turn in: Meet at the Sunwell", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2424, x = 0.529, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 86838, text = "Renewal for the Weary",
          coord = { map = 2424, x = 0.529, y = 0.552 } },  -- giver coord: ATT
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [1/10]", useItem = 237811,
          coord = { map = 2424, x = 0.521, y = 0.456 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [2/10]", useItem = 237811,
          coord = { map = 2424, x = 0.517, y = 0.452 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [3/10]", useItem = 237811,
          coord = { map = 2424, x = 0.517, y = 0.444 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [4/10]", useItem = 237811,
          coord = { map = 2424, x = 0.518, y = 0.437 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [5/10]", useItem = 237811,
          coord = { map = 2424, x = 0.522, y = 0.432 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [6/10]", useItem = 237811,
          coord = { map = 2424, x = 0.529, y = 0.432 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [7/10]", useItem = 237811,
          coord = { map = 2424, x = 0.534, y = 0.439 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [8/10]", useItem = 237811,
          coord = { map = 2424, x = 0.535, y = 0.445 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [9/10]", useItem = 237811,
          coord = { map = 2424, x = 0.535, y = 0.453 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86838, text = "Renewal for the Weary (objective 1) [10/10]", useItem = 237811,
          coord = { map = 2424, x = 0.529, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86838, text = "Turn in: Renewal for the Weary", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2424, x = 0.529, y = 0.552 } },  -- APR route coord (converted)
        { type = "accept", questID = 86839, text = "Relics of Light's Hope",
          coord = { map = 2424, x = 0.529, y = 0.552 } },  -- giver coord: ATT
        { type = "quest",  questID = 86839, text = "Relics of Light's Hope (objective 2)",
          coord = { map = 2424, x = 0.529, y = 0.552 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86839, text = "Turn in: Relics of Light's Hope", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 23, x = 0.739, y = 0.536 } },  -- APR route coord (converted)
        { type = "accept", questID = 86840, text = "Flickering Hope",
          coord = { map = 23, x = 0.739, y = 0.536 } },  -- giver coord: ATT
        { type = "quest",  questID = 86840, text = "Flickering Hope (objective 1)",
          coord = { map = 23, x = 0.726, y = 0.513 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86840, text = "Turn in: Flickering Hope", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 23, x = 0.739, y = 0.536 } },  -- APR route coord (converted)
        { type = "accept", questID = 86841, text = "Relics of Paladins Past",
          coord = { map = 23, x = 0.739, y = 0.536 } },  -- giver coord: ATT
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 1)",
          coord = { map = 23, x = 0.758, y = 0.521 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 3)",
          coord = { map = 23, x = 0.788, y = 0.470 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 5)",
          coord = { map = 23, x = 0.795, y = 0.460 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 6)",
          coord = { map = 23, x = 0.798, y = 0.450 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 4)",
          coord = { map = 23, x = 0.790, y = 0.439 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86841, text = "Relics of Paladins Past (objective 2)",
          coord = { map = 23, x = 0.777, y = 0.454 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86841, text = "Turn in: Relics of Paladins Past", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 23, x = 0.739, y = 0.536 } },  -- APR route coord (converted)
        { type = "accept", questID = 86842, text = "Scarlet Power",
          coord = { map = 23, x = 0.738, y = 0.535 } },  -- giver coord: ATT
        { type = "quest",  questID = 86842, text = "Scarlet Power (objective 1)",
          coord = { map = 23, x = 0.739, y = 0.537 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86842, text = "Scarlet Power (objective 2)",
          coord = { map = 18, x = 0.825, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86842, text = "Scarlet Power (objective 3)",
          coord = { map = 18, x = 0.852, y = 0.319 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86842, text = "Scarlet Power (objective 4)",
          coord = { map = 18, x = 0.853, y = 0.323 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 86842, text = "Turn in: Scarlet Power", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 18, x = 0.558, y = 0.920 } },  -- APR route coord (converted); scenario/instance step
        { type = "accept", questID = 86843, text = "Light Miswielded",
          coord = { map = 2438, x = 0.473, y = 0.908 } },  -- giver coord: ATT; scenario/instance step
        { type = "accept", questID = 86844, text = "Light Repurposed",
          coord = { map = 2438, x = 0.473, y = 0.908 } },  -- giver coord: ATT; scenario/instance step
        { type = "quest",  questID = 86844, text = "Light Repurposed (objective 1)",
          coord = { map = 18, x = 0.571, y = 0.901 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86844, text = "Light Repurposed (objective 2)",
          coord = { map = 18, x = 0.573, y = 0.873 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86843, text = "Light Miswielded (objective 1)",
          coord = { map = 18, x = 0.558, y = 0.886 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 86844, text = "Light Repurposed (objective 3)",
          coord = { map = 18, x = 0.550, y = 0.843 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 86843, text = "Turn in: Light Miswielded", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 18, x = 0.552, y = 0.856 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 86844, text = "Turn in: Light Repurposed", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 18, x = 0.552, y = 0.856 } },  -- APR route coord (converted); scenario/instance step
        { type = "accept", questID = 92136, text = "Infusion of Hope",
          coord = { map = 2438, x = 0.413, y = 0.288 } },  -- giver coord: ATT; scenario/instance step
        { type = "quest",  questID = 92136, text = "Infusion of Hope (objective 1)",
          coord = { map = 18, x = 0.552, y = 0.856 } },  -- APR route coord (converted); scenario/instance step
        { type = "quest",  questID = 92136, text = "Infusion of Hope (objective 2)",
          coord = { map = 18, x = 0.552, y = 0.856 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 92136, text = "Turn in: Infusion of Hope", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2424, x = 0.526, y = 0.559 } },  -- APR route coord (converted)
        { type = "accept", questID = 86902, text = "Relinquishing Relics",
          coord = { map = 2424, x = 0.526, y = 0.559 } },  -- giver coord: ATT
        { type = "quest",  questID = 86902, text = "Relinquishing Relics (objective 3)",
          coord = { map = 2424, x = 0.535, y = 0.453 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86902, text = "Relinquishing Relics (objective 2)",
          coord = { map = 2424, x = 0.529, y = 0.458 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86902, text = "Relinquishing Relics (objective 4)",
          coord = { map = 2424, x = 0.521, y = 0.456 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86902, text = "Relinquishing Relics (objective 5)",
          coord = { map = 2424, x = 0.517, y = 0.450 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86902, text = "Relinquishing Relics (objective 6)",
          coord = { map = 2424, x = 0.525, y = 0.459 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86902, text = "Turn in: Relinquishing Relics", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2424, x = 0.526, y = 0.559 } },  -- APR route coord (converted)
        { type = "accept", questID = 86845, text = "The Sunwalker Path",
          coord = { map = 2424, x = 0.526, y = 0.559 } },  -- giver coord: ATT
        { type = "quest",  questID = 86845, text = "The Sunwalker Path (objective 1)",
          coord = { map = 2424, x = 0.526, y = 0.559 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86845, text = "The Sunwalker Path (objective 2)",
          coord = { map = 2424, x = 0.525, y = 0.560 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86845, text = "Turn in: The Sunwalker Path", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 14, x = 0.689, y = 0.377 } },  -- APR route coord (converted)
        { type = "accept", questID = 91000, text = "A Humble Servant",
          coord = { map = 2372, x = 0.689, y = 0.377 } },  -- giver coord: ATT
        { type = "accept", questID = 86846, text = "Resupplying Our Suppliers",
          coord = { map = 2372, x = 0.689, y = 0.377 } },  -- giver coord: ATT
        { type = "quest",  questID = 86846, text = "Resupplying Our Suppliers (objective 1)",
          coord = { map = 14, x = 0.681, y = 0.377 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86846, text = "Resupplying Our Suppliers (objective 3)",
          coord = { map = 14, x = 0.700, y = 0.356 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86846, text = "Resupplying Our Suppliers (objective 2)",
          coord = { map = 14, x = 0.692, y = 0.349 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86846, text = "Resupplying Our Suppliers (objective 4)",
          coord = { map = 14, x = 0.684, y = 0.319 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86846, text = "Resupplying Our Suppliers (objective 5)",
          coord = { map = 14, x = 0.693, y = 0.334 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91000, text = "A Humble Servant (objective 1)",
          coord = { map = 14, x = 0.690, y = 0.336 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91000, text = "Turn in: A Humble Servant", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 14, x = 0.685, y = 0.322 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86846, text = "Turn in: Resupplying Our Suppliers", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 14, x = 0.685, y = 0.322 } },  -- APR route coord (converted)
        { type = "accept", questID = 89338, text = "Gathering Plowshares",
          coord = { map = 2372, x = 0.685, y = 0.322 } },  -- giver coord: ATT
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 1)",
          coord = { map = 14, x = 0.685, y = 0.322 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 2) [1/4]",
          coord = { map = 14, x = 0.700, y = 0.410 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 3) [1/4]",
          coord = { map = 14, x = 0.709, y = 0.412 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 2) [2/4]",
          coord = { map = 14, x = 0.709, y = 0.432 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 3) [2/4]",
          coord = { map = 14, x = 0.700, y = 0.445 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 2) [3/4]",
          coord = { map = 14, x = 0.693, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 2) [4/4]",
          coord = { map = 14, x = 0.679, y = 0.463 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 3) [3/4]",
          coord = { map = 14, x = 0.668, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89338, text = "Gathering Plowshares (objective 3) [4/4]",
          coord = { map = 14, x = 0.661, y = 0.452 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89338, text = "Turn in: Gathering Plowshares", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 14, x = 0.685, y = 0.322 } },  -- APR route coord (converted)
        { type = "accept", questID = 86822, text = "One Final Relic",
          coord = { map = 2372, x = 0.686, y = 0.320 } },  -- giver coord: ATT
        { type = "quest",  questID = 86822, text = "One Final Relic (objective 1)",
          coord = { map = 14, x = 0.686, y = 0.320 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86822, text = "One Final Relic (objective 2)",
          coord = { map = 36, x = 0.334, y = 0.483 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86822, text = "Turn in: One Final Relic", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 86823, text = "The Dark Horde",
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- giver coord: ATT
        { type = "accept", questID = 86824, text = "None Left Standing",
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- giver coord: ATT
        { type = "accept", questID = 86825, text = "Faithful Servant, Faithless Cause",
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- giver coord: ATT
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [1/6]", useItem = 239130,
          coord = { map = 36, x = 0.355, y = 0.492 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [2/6]", useItem = 239130,
          coord = { map = 36, x = 0.368, y = 0.507 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [3/6]", useItem = 239130,
          coord = { map = 36, x = 0.405, y = 0.523 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [4/6]", useItem = 239130,
          coord = { map = 36, x = 0.394, y = 0.551 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [5/6]", useItem = 239130,
          coord = { map = 36, x = 0.351, y = 0.551 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86824, text = "None Left Standing (objective 1) [6/6]", useItem = 239130,
          coord = { map = 36, x = 0.328, y = 0.526 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86825, text = "Faithful Servant, Faithless Cause (objective 1)",
          coord = { map = 36, x = 0.438, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86825, text = "Faithful Servant, Faithless Cause (objective 2)",
          coord = { map = 36, x = 0.438, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86823, text = "The Dark Horde (objective 1)",
          coord = { map = 36, x = 0.383, y = 0.532 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86823, text = "Turn in: The Dark Horde", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86824, text = "Turn in: None Left Standing", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86825, text = "Turn in: Faithful Servant, Faithless Cause", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 91391, text = "Still Scouting",
          coord = { map = 36, x = 0.335, y = 0.486 } },  -- giver coord: ATT
        { type = "turnin", questID = 91391, text = "Turn in: Still Scouting", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- APR route coord (converted)
        { type = "accept", questID = 86827, text = "Due Recognition",
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- giver coord: ATT
        { type = "accept", questID = 86826, text = "Nagosh the Scarred",
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- giver coord: ATT
        { type = "accept", questID = 91842, text = "Disarm the Dark Horde",
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- giver coord: ATT
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [1/8]",
          coord = { map = 36, x = 0.199, y = 0.349 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [2/8]",
          coord = { map = 36, x = 0.217, y = 0.340 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [3/8]",
          coord = { map = 36, x = 0.232, y = 0.317 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [4/8]",
          coord = { map = 36, x = 0.249, y = 0.304 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86826, text = "Nagosh the Scarred (objective 1,2)",
          coord = { map = 36, x = 0.240, y = 0.285 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [5/8]",
          coord = { map = 36, x = 0.238, y = 0.289 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [6/8]",
          coord = { map = 36, x = 0.239, y = 0.267 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [7/8]",
          coord = { map = 36, x = 0.198, y = 0.237 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91842, text = "Disarm the Dark Horde (objective 1) [8/8]",
          coord = { map = 36, x = 0.189, y = 0.242 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86827, text = "Due Recognition (objective 1)",
          coord = { map = 36, x = 0.240, y = 0.285 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86827, text = "Turn in: Due Recognition", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86826, text = "Turn in: Nagosh the Scarred", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91842, text = "Turn in: Disarm the Dark Horde", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- APR route coord (converted)
        { type = "accept", questID = 86828, text = "Not Just a Troll's Bane",
          coord = { map = 36, x = 0.211, y = 0.398 } },  -- giver coord: ATT
        { type = "turnin", questID = 86828, text = "Turn in: Not Just a Troll's Bane", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- APR route coord (converted)
        { type = "accept", questID = 86831, text = "Warriors Without a Warlord",
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- giver coord: ATT
        { type = "accept", questID = 86830, text = "A True Horde of Dark Horde",
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- giver coord: ATT
        { type = "quest",  questID = 86831, text = "Warriors Without a Warlord (objective 1,2)",
          coord = { map = 36, x = 0.310, y = 0.340 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86830, text = "A True Horde of Dark Horde (objective 1,2)",
          coord = { map = 36, x = 0.350, y = 0.360 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86831, text = "Turn in: Warriors Without a Warlord", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86830, text = "Turn in: A True Horde of Dark Horde", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- APR route coord (converted)
        { type = "accept", questID = 86829, text = "A Landmark Moment",
          coord = { map = 36, x = 0.316, y = 0.376 } },  -- giver coord: ATT
        { type = "turnin", questID = 86829, text = "Turn in: A Landmark Moment", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.368, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 91726, text = "Unstoppable Force",
          coord = { map = 36, x = 0.368, y = 0.510 } },  -- giver coord: ATT
        { type = "quest",  questID = 91726, text = "Unstoppable Force (objective 1)",
          coord = { map = 36, x = 0.368, y = 0.511 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91726, text = "Unstoppable Force (objective 2)",
          coord = { map = 36, x = 0.367, y = 0.511 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91726, text = "Turn in: Unstoppable Force", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 36, x = 0.368, y = 0.511 } },  -- APR route coord (converted)
        { type = "accept", questID = 86832, text = "A Worthy Forge",
          coord = { map = 36, x = 0.367, y = 0.511 } },  -- giver coord: ATT
        { type = "quest",  questID = 86832, text = "A Worthy Forge (objective 1)",
          coord = { map = 36, x = 0.368, y = 0.508 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86832, text = "Turn in: A Worthy Forge", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.458, y = 0.655 } },  -- APR route coord (converted)
        { type = "accept", questID = 86833, text = "A Bulwark Remade",
          coord = { map = 2393, x = 0.458, y = 0.655 } },  -- giver coord: ATT
        { type = "quest",  questID = 86833, text = "A Bulwark Remade (objective 1)",
          coord = { map = 2393, x = 0.405, y = 0.660 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86833, text = "A Bulwark Remade (objective 2)",
          coord = { map = 2393, x = 0.405, y = 0.662 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86833, text = "A Bulwark Remade (objective 3)",
          coord = { map = 2393, x = 0.405, y = 0.660 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86833, text = "Turn in: A Bulwark Remade", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.405, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 86903, text = "The Arcantina",
          coord = { map = 2393, x = 0.406, y = 0.661 } },  -- giver coord: ATT
        { type = "quest",  questID = 86903, text = "The Arcantina (objective 1)", useItem = 248131,
          coord = { map = 2393, x = 0.407, y = 0.661 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86903, text = "The Arcantina (objective 2)",
          coord = nil },  -- no coord: inside Arcantina (uiMap 2541), APR position not convertible on an outdoor map
        { type = "quest",  questID = 86903, text = "The Arcantina (objective 3)",
          coord = nil },  -- no coord: inside Arcantina (uiMap 2541), APR position not convertible on an outdoor map
        { type = "quest",  questID = 86903, text = "The Arcantina (objective 4)",
          coord = nil },  -- no coord: inside Arcantina (uiMap 2541), APR position not convertible on an outdoor map
        { type = "turnin", questID = 86903, text = "Turn in: The Arcantina", rep = { { factionID = 2710, amount = 100 } },
          coord = nil },  -- no coord: inside Arcantina (uiMap 2541), APR position not convertible on an outdoor map
        { type = "accept", questID = 91787, text = "The Journey Ends",
          coord = { map = 2541, x = 0.522, y = 0.606 } },  -- giver coord: ATT
        { type = "turnin", questID = 91787, text = "Turn in: The Journey Ends", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
    },
}
