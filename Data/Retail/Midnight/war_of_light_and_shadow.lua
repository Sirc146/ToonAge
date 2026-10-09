-- ToonAge guide data: Midnight: The War of Light and Shadow (post-campaign, level 90)
-- Kind: post-campaign chapter
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2395-The-War-of-Light-and-Shadow"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 40 quest IDs resolved.
--  * Accept coords: quest-giver coords from AllTheThings (github.com/ATTWoWAddon/AllTheThings master,
--    .contrib/.db/standard/02 - Outdoor Zones/16 Quel'Thalas/*/Quests.lua; MAP.MIDNIGHT.* constants from shared/lib/Constants/Maps.lua).
--  * All other coords: APR world positions converted EXACTLY with UiMapAssignment DB2 bounds (wago.tools, 12.1.0.69933), no curve fitting:
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    A point inside a city/sub-zone map of the step's zone uses that map (e.g. Silvermoon 2393 inside Eversong 2395). Conversion is
--    only attempted on maps of the same continent (instance MapID) as the APR step zone; scenario/micro-map steps that cannot be
--    converted are coord = nil (never 0,0).
--    Cross-check on this route: 38 accept steps where ATT and converted APR coords share a map: median 0.04, p90 0.07, max 0.49 map-%.
--  * useItem = <itemID>: APR "Button" field; item checked on Wowhead tooltip (Quest Item + Use:). useItemVerified = false if not.
--  * faction = "Alliance"/"Horde": APR faction-only steps. Untagged steps are shared (Midnight campaign quest IDs are faction-neutral
--    except where tagged).
--  * Steps with UNVERIFIED in the trailing comment are inferred. Grep "UNVERIFIED".
--  * APR "HasAchievement 42045" alternative steps (warband has finished the campaign -> scouting-map skip) are omitted (0 steps);
--    "DontHaveAchievement 42045" steps are kept and tagged in their comment. APR "Grind" level gates are kept as comments.
--  * Side quests ("sojourner" routes), APR Fillers, flight-path/hearth/portal-only steps are not included: see Kind above.
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 680 Suramar, 2239 Amirdrassil, 2393 Silvermoon City, 2395 Eversong Woods, 2405 Voidstorm, 2424 Isle of Quel'Danas, 2443 Silvermoon City


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_war_of_light_and_shadow"] = {
    id = "midnight_war_of_light_and_shadow", title = "Midnight: The War of Light and Shadow (post-campaign, level 90)", expansion = "midnight",
    zone = 2395, minLevel = 90, maxLevel = 90,
    nextGuide = "midnight_curse_of_ulatek",
    steps = {
        -- (APR: grind/continue to level 90 before the next step)
        { type = "accept", questID = 94957, text = "War of Light and Shadow",
          coord = { map = 2393, x = 0.455, y = 0.704 } },  -- giver coord: ATT
        { type = "quest",  questID = 94957, text = "War of Light and Shadow (objective 1)",
          coord = { map = 2424, x = 0.531, y = 0.587 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94957, text = "Turn in: War of Light and Shadow",
          coord = { map = 2424, x = 0.531, y = 0.587 } },  -- APR route coord (converted)
        { type = "accept", questID = 90777, text = "Feeding the Flame",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 90777, text = "Feeding the Flame (objective 1)",
          coord = { map = 2424, x = 0.531, y = 0.587 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90777, text = "Feeding the Flame (objective 1,3)",
          coord = { map = 2424, x = 0.502, y = 0.587 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90777, text = "Feeding the Flame (objective 3)",
          coord = { map = 2424, x = 0.515, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90777, text = "Feeding the Flame (objective 2)",
          coord = { map = 2424, x = 0.542, y = 0.580 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90777, text = "Turn in: Feeding the Flame", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2424, x = 0.531, y = 0.587 } },  -- APR route coord (converted)
        { type = "accept", questID = 88696, text = "The Devouring Citadel",
          coord = { map = 2424, x = 0.531, y = 0.587 } },  -- giver coord: ATT
        { type = "quest",  questID = 88696, text = "The Devouring Citadel (objective 1)",
          coord = { map = 2424, x = 0.519, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88696, text = "The Devouring Citadel (objective 2)",
          coord = { map = 2405, x = 0.454, y = 0.638 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88696, text = "Turn in: The Devouring Citadel", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 88697, text = "Clarity of Purpose",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- giver coord: ATT
        { type = "quest",  questID = 88697, text = "Clarity of Purpose (objective 1)",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88697, text = "Clarity of Purpose (objective 2)",
          coord = { map = 2405, x = 0.454, y = 0.632 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88697, text = "Clarity of Purpose (objective 3)",
          coord = { map = 2405, x = 0.455, y = 0.630 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88697, text = "Clarity of Purpose (objective 4)",
          coord = { map = 2405, x = 0.459, y = 0.639 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88697, text = "Clarity of Purpose (objective 5)",
          coord = { map = 2405, x = 0.458, y = 0.641 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88697, text = "Turn in: Clarity of Purpose", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 88698, text = "Master of Mayhem",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- giver coord: ATT
        { type = "accept", questID = 88699, text = "Powerless",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- giver coord: ATT
        { type = "quest",  questID = 88699, text = "Powerless (objective 1)",
          coord = { map = 2405, x = 0.459, y = 0.678 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88699, text = "Powerless (objective 2)",
          coord = { map = 2405, x = 0.479, y = 0.687 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88699, text = "Powerless (objective 3)",
          coord = { map = 2405, x = 0.469, y = 0.727 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88699, text = "Powerless (objective 4)",
          coord = { map = 2405, x = 0.468, y = 0.701 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88698, text = "Master of Mayhem (objective 1)",
          coord = { map = 2405, x = 0.468, y = 0.713 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88698, text = "Turn in: Master of Mayhem", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88699, text = "Turn in: Powerless", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 88700, text = "Two Tons of Metal and Holy Fire",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- giver coord: ATT
        { type = "quest",  questID = 88700, text = "Two Tons of Metal and Holy Fire (objective 1)",
          coord = { map = 2405, x = 0.451, y = 0.633 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88700, text = "Two Tons of Metal and Holy Fire (objective 2)",
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 88700, text = "Turn in: Two Tons of Metal and Holy Fire", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 91417, text = "Seek out Arator",
          coord = { map = 2405, x = 0.454, y = 0.631 } },  -- giver coord: ATT
        { type = "turnin", questID = 91417, text = "Turn in: Seek out Arator",
          coord = { map = 2405, x = 0.460, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 88701, text = "The Memory Remains",
          coord = { map = 2405, x = 0.460, y = 0.649 } },  -- giver coord: ATT
        { type = "accept", questID = 88702, text = "Aegis of the Redeemer",
          coord = { map = 2405, x = 0.460, y = 0.649 } },  -- giver coord: ATT
        { type = "quest",  questID = 88701, text = "The Memory Remains (objective 1)",
          coord = { map = 2405, x = 0.467, y = 0.612 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88702, text = "Aegis of the Redeemer (objective 1)",
          coord = { map = 2405, x = 0.467, y = 0.612 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88701, text = "Turn in: The Memory Remains", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "turnin", questID = 88702, text = "Turn in: Aegis of the Redeemer", rep = { { factionID = 2710, amount = 50 } },
          coord = nil },  -- no coord: APR step has none
        { type = "accept", questID = 91426, text = "The People's Champion",
          coord = { map = 2405, x = 0.463, y = 0.632 } },  -- giver coord: ATT
        { type = "turnin", questID = 91426, text = "Turn in: The People's Champion",
          coord = { map = 2405, x = 0.463, y = 0.633 } },  -- APR route coord (converted)
        { type = "accept", questID = 88703, text = "The Night Before",
          coord = { map = 2405, x = 0.463, y = 0.632 } },  -- giver coord: ATT
        { type = "quest",  questID = 88703, text = "The Night Before (objective 1)",
          coord = { map = 2405, x = 0.517, y = 0.650 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88703, text = "The Night Before (objective 2)",
          coord = { map = 2405, x = 0.517, y = 0.650 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88703, text = "Turn in: The Night Before", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2405, x = 0.517, y = 0.649 } },  -- APR route coord (converted)
        { type = "accept", questID = 88704, text = "The Patient Hunter",
          coord = { map = 2405, x = 0.517, y = 0.650 } },  -- giver coord: ATT
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 1)",
          coord = { map = 2405, x = 0.525, y = 0.660 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 2)",
          coord = { map = 2405, x = 0.533, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 3)",
          coord = { map = 2405, x = 0.540, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 4)",
          coord = { map = 2405, x = 0.550, y = 0.643 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 5)",
          coord = { map = 2405, x = 0.553, y = 0.642 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88704, text = "The Patient Hunter (objective 6)",
          coord = { map = 2405, x = 0.554, y = 0.643 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88704, text = "Turn in: The Patient Hunter", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2405, x = 0.563, y = 0.651 } },  -- APR route coord (converted)
        { type = "accept", questID = 88705, text = "Killing Blow",
          coord = { map = 2405, x = 0.563, y = 0.651 } },  -- giver coord: ATT
        { type = "quest",  questID = 88705, text = "Killing Blow (objective 1)",
          coord = { map = 2405, x = 0.563, y = 0.651 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88705, text = "Killing Blow (objective 2)",
          coord = { map = 2405, x = 0.564, y = 0.652 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88705, text = "Killing Blow (objective 3)",
          coord = { map = 2405, x = 0.561, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88705, text = "Turn in: Killing Blow", rep = { { factionID = 2710, amount = 100 } },
          coord = { map = 2405, x = 0.559, y = 0.648 } },  -- APR route coord (converted)
        { type = "accept", questID = 88706, text = "Nothing Stands Forever",
          coord = { map = 2405, x = 0.559, y = 0.648 } },  -- giver coord: ATT
        { type = "quest",  questID = 88706, text = "Nothing Stands Forever (objective 1)",
          coord = { map = 2405, x = 0.452, y = 0.629 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88706, text = "Turn in: Nothing Stands Forever", rep = { { factionID = 2710, amount = 1000 } },
          coord = { map = 2405, x = 0.452, y = 0.629 } },  -- APR route coord (converted)
        { type = "accept", questID = 88709, text = "The Voidspire",
          coord = { map = 2405, x = 0.454, y = 0.630 } },  -- giver coord: ATT
        { type = "quest",  questID = 88709, text = "The Voidspire (objective 2)",
          coord = { map = 2405, x = 0.445, y = 0.661 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88709, text = "The Voidspire (objective 2)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "quest",  questID = 88709, text = "The Voidspire (objective 3)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 88709, text = "Turn in: The Voidspire", rep = { { factionID = 2710, amount = 1500 } },
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "accept", questID = 90724, text = "The Broken Sky",
          coord = { map = 2405, x = 0.445, y = 0.661 } },  -- giver coord: ATT; scenario/instance step
        { type = "turnin", questID = 90724, text = "Turn in: The Broken Sky", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 92520, text = "Wake of the Darkwell",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 1)",
          coord = { map = 2424, x = 0.497, y = 0.815 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 2)",
          coord = { map = 2424, x = 0.458, y = 0.685 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 4) [1/4]",
          coord = { map = 2424, x = 0.513, y = 0.627 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 4) [2/4]",
          coord = { map = 2424, x = 0.479, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 4) [3/4]",
          coord = { map = 2424, x = 0.411, y = 0.576 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 4) [4/4]",
          coord = { map = 2424, x = 0.356, y = 0.453 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92520, text = "Wake of the Darkwell (objective 3)",
          coord = { map = 2424, x = 0.452, y = 0.390 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92520, text = "Turn in: Wake of the Darkwell", rep = { { factionID = 2710, amount = 1000 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 88920, text = "The Kaldorei",
          coord = { map = 2393, x = 0.459, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 88920, text = "The Kaldorei (objective 1)",
          coord = { map = 2393, x = 0.458, y = 0.703 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88920, text = "The Kaldorei (objective 2)",
          coord = { map = 2393, x = 0.475, y = 0.696 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88920, text = "Turn in: The Kaldorei", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- APR route coord (converted)
        { type = "accept", questID = 88923, text = "Children of the Stars",
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- giver coord: ATT
        { type = "quest",  questID = 88923, text = "Children of the Stars (objective 2)",
          coord = { map = 2239, x = 0.484, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88923, text = "Children of the Stars (objective 1)",
          coord = { map = 2239, x = 0.483, y = 0.704 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88923, text = "Children of the Stars (objective 3)",
          coord = { map = 2239, x = 0.484, y = 0.705 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88923, text = "Turn in: Children of the Stars", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- APR route coord (converted)
        { type = "accept", questID = 88925, text = "Awaken the Ancient of War",
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- giver coord: ATT
        { type = "accept", questID = 88927, text = "Awaken the Ancient Protector",
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- giver coord: ATT
        { type = "accept", questID = 88937, text = "Awaken the Ancient of Lore",
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- giver coord: ATT
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 1)",
          coord = { map = 2239, x = 0.450, y = 0.719 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 2) [1/4]",
          coord = { map = 2239, x = 0.455, y = 0.703 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 2) [2/4]",
          coord = { map = 2239, x = 0.436, y = 0.672 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 2) [3/4]",
          coord = { map = 2239, x = 0.424, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 2) [4/4]",
          coord = { map = 2239, x = 0.411, y = 0.688 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88927, text = "Awaken the Ancient Protector (objective 3)",
          coord = { map = 2239, x = 0.452, y = 0.723 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 1)",
          coord = { map = 2239, x = 0.507, y = 0.515 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 2)",
          coord = { map = 2239, x = 0.512, y = 0.528 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 2) [1/3]",
          coord = { map = 2239, x = 0.512, y = 0.528 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 2) [2/3]",
          coord = { map = 2239, x = 0.503, y = 0.516 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 2) [3/3]",
          coord = { map = 2239, x = 0.507, y = 0.496 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88925, text = "Awaken the Ancient of War (objective 3)",
          coord = { map = 2239, x = 0.510, y = 0.510 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88937, text = "Awaken the Ancient of Lore (objective 1)",
          coord = { map = 2239, x = 0.568, y = 0.650 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88937, text = "Awaken the Ancient of Lore (objective 2)",
          coord = { map = 2239, x = 0.644, y = 0.689 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88937, text = "Awaken the Ancient of Lore (objective 3)",
          coord = { map = 2239, x = 0.566, y = 0.651 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88925, text = "Turn in: Awaken the Ancient of War", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88927, text = "Turn in: Awaken the Ancient Protector", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88937, text = "Turn in: Awaken the Ancient of Lore", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2239, x = 0.483, y = 0.707 } },  -- APR route coord (converted)
        { type = "accept", questID = 88922, text = "The Quel'dorei",
          coord = { map = 2239, x = 0.483, y = 0.705 } },  -- giver coord: ATT
        { type = "turnin", questID = 88922, text = "Turn in: The Quel'dorei", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- APR route coord (converted)
        { type = "accept", questID = 88939, text = "Rest for the Restless",
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- giver coord: ATT
        { type = "accept", questID = 88938, text = "Symbols of the Past",
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- giver coord: ATT
        { type = "quest",  questID = 88938, text = "Symbols of the Past (objective 2)",
          coord = { map = 2395, x = 0.302, y = 0.908 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88938, text = "Symbols of the Past (objective 3)",
          coord = { map = 2395, x = 0.304, y = 0.925 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88939, text = "Rest for the Restless (objective 1)",
          coord = { map = 2395, x = 0.319, y = 0.929 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88939, text = "Turn in: Rest for the Restless", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88938, text = "Turn in: Symbols of the Past", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- APR route coord (converted)
        { type = "accept", questID = 88941, text = "For Quel'Thalas",
          coord = { map = 2395, x = 0.312, y = 0.914 } },  -- giver coord: ATT
        { type = "quest",  questID = 88941, text = "For Quel'Thalas (objective 1)",
          coord = { map = 2393, x = 0.458, y = 0.955 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88941, text = "For Quel'Thalas (objective 2)",
          coord = { map = 2393, x = 0.456, y = 0.949 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88941, text = "Turn in: For Quel'Thalas", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.458, y = 0.705 } },  -- APR route coord (converted)
        { type = "accept", questID = 88928, text = "The Shal'dorei",
          coord = { map = 2393, x = 0.457, y = 0.700 } },  -- giver coord: ATT
        { type = "quest",  questID = 88928, text = "The Shal'dorei (objective 1)",
          coord = { map = 2393, x = 0.475, y = 0.696 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88928, text = "Turn in: The Shal'dorei", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 680, x = 0.705, y = 0.742 } },  -- APR route coord (converted)
        { type = "accept", questID = 88930, text = "Drained Mana",
          coord = { map = 680, x = 0.705, y = 0.742 } },  -- giver coord: ATT
        { type = "accept", questID = 88929, text = "An Illusion!",
          coord = { map = 680, x = 0.706, y = 0.743 } },  -- giver coord: ATT
        { type = "quest",  questID = 88930, text = "Drained Mana (objective 1)",
          coord = { map = 680, x = 0.702, y = 0.770 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88930, text = "Drained Mana (objective 2)",
          coord = { map = 680, x = 0.707, y = 0.797 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88930, text = "Drained Mana (objective 3)",
          coord = { map = 680, x = 0.716, y = 0.794 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88929, text = "An Illusion! (objective 1)", useItem = 248920,
          coord = { map = 680, x = 0.701, y = 0.763 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88930, text = "Drained Mana (objective 4)",
          coord = { map = 680, x = 0.704, y = 0.747 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88930, text = "Turn in: Drained Mana", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 680, x = 0.706, y = 0.743 } },  -- APR route coord (converted)
        { type = "turnin", questID = 88929, text = "Turn in: An Illusion!", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 680, x = 0.706, y = 0.743 } },  -- APR route coord (converted)
        { type = "accept", questID = 88919, text = "Into the Darkway",
          coord = { map = 680, x = 0.706, y = 0.743 } },  -- giver coord: ATT
        { type = "turnin", questID = 88919, text = "Turn in: Into the Darkway", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.404, y = 0.329 } },  -- APR route coord (converted)
        { type = "accept", questID = 88942, text = "The Elves are Going to War",
          coord = { map = 2393, x = 0.404, y = 0.329 } },  -- giver coord: ATT
        { type = "turnin", questID = 88942, text = "Turn in: The Elves are Going to War", rep = { { factionID = 2710, amount = 1000 } },
          coord = { map = 2393, x = 0.458, y = 0.701 } },  -- APR route coord (converted)
        { type = "accept", questID = 88769, text = "The Battle of the Bridge",
          coord = { map = 2393, x = 0.459, y = 0.703 } },  -- giver coord: ATT
        { type = "quest",  questID = 88769, text = "The Battle of the Bridge (objective 1)",
          coord = { map = 2443, x = 0.456, y = 0.031 } },  -- APR route coord (converted); scenario/instance step
        { type = "turnin", questID = 88769, text = "Turn in: The Battle of the Bridge", rep = { { factionID = 2710, amount = 1000 } },
          coord = { map = 2424, x = 0.526, y = 0.902 } },  -- APR route coord (converted)
        { type = "accept", questID = 88710, text = "March on Quel'Danas",
          coord = { map = 2424, x = 0.526, y = 0.902 } },  -- giver coord: ATT
        { type = "quest",  questID = 88710, text = "March on Quel'Danas (objective 1)",
          coord = { map = 2424, x = 0.497, y = 0.875 } },  -- APR route coord (converted)
        { type = "quest",  questID = 88710, text = "March on Quel'Danas (objective 2)",
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "turnin", questID = 88710, text = "Turn in: March on Quel'Danas", rep = { { factionID = 2710, amount = 1000 } },
          coord = nil },  -- no coord: APR step has none; scenario/instance step
        { type = "accept", questID = 92689, text = "A Path Forward",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "accept", questID = 90876, text = "Reluctant Hand",
          coord = { map = 2393, x = 0.534, y = 0.601 } },  -- giver coord: ATT
        { type = "quest",  questID = 90876, text = "Reluctant Hand (objective 2)",
          coord = { map = 2393, x = 0.538, y = 0.585 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90876, text = "Reluctant Hand (objective 1)",
          coord = { map = 2393, x = 0.543, y = 0.598 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90876, text = "Reluctant Hand (objective 3)",
          coord = { map = 2393, x = 0.543, y = 0.590 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90876, text = "Turn in: Reluctant Hand", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.542, y = 0.594 } },  -- APR route coord (converted)
        { type = "accept", questID = 90871, text = "The Silversun Compact",
          coord = { map = 2393, x = 0.401, y = 0.895 } },  -- giver coord: ATT
        { type = "quest",  questID = 90871, text = "The Silversun Compact (objective 1)",
          coord = { map = 2393, x = 0.397, y = 0.873 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90871, text = "The Silversun Compact (objective 2)",
          coord = { map = 2393, x = 0.415, y = 0.864 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90871, text = "The Silversun Compact (objective 3)",
          coord = { map = 2393, x = 0.412, y = 0.888 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90871, text = "Turn in: The Silversun Compact", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2393, x = 0.412, y = 0.889 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92689, text = "Turn in: A Path Forward", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- APR route coord (converted)
        { type = "accept", questID = 90861, text = "Those Left Behind",
          coord = { map = 2393, x = 0.454, y = 0.703 } },  -- giver coord: ATT
        { type = "turnin", questID = 90861, text = "Turn in: Those Left Behind", rep = { { factionID = 2710, amount = 10 } },
          coord = { map = 2424, x = 0.527, y = 0.584 } },  -- APR route coord (converted)
        { type = "accept", questID = 90862, text = "In Times of Need",
          coord = { map = 2424, x = 0.527, y = 0.584 } },  -- giver coord: ATT
        { type = "quest",  questID = 90862, text = "In Times of Need (objective 2)",
          coord = { map = 2424, x = 0.562, y = 0.606 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90862, text = "In Times of Need (objective 4)",
          coord = { map = 2424, x = 0.526, y = 0.675 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90862, text = "In Times of Need (objective 3)",
          coord = { map = 2424, x = 0.484, y = 0.649 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90862, text = "In Times of Need (objective 1)",
          coord = { map = 2424, x = 0.382, y = 0.579 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90862, text = "Turn in: In Times of Need", rep = { { factionID = 2710, amount = 50 } },
          coord = { map = 2424, x = 0.526, y = 0.461 } },  -- APR route coord (converted)
        { type = "accept", questID = 90867, text = "From Darkness, Light",
          coord = { map = 2424, x = 0.526, y = 0.461 } },  -- giver coord: ATT
        { type = "quest",  questID = 90867, text = "From Darkness, Light (objective 1)",
          coord = { map = 2424, x = 0.526, y = 0.461 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90867, text = "Turn in: From Darkness, Light", rep = { { factionID = 2710, amount = 1000 } },
          coord = { map = 2424, x = 0.526, y = 0.459 } },  -- APR route coord (converted)
    },
}
