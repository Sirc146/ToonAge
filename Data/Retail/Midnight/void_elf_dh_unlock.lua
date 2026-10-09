-- ToonAge guide data: Midnight: Unlock Void Elf Demon Hunter
-- Kind: unlock chain (level 70+)
-- Generated 2026-10-09 (PT). Format: { type, questID, text, [faction], [useItem], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933).
--
-- SOURCES / VERIFICATION
--  * Step order, questIDs, faction splits, objectives and usable-item buttons: Azeroth Pilot Reloaded route "2248-Unlock-void-elf-DH"
--    in Routes/Midnight/Midnight.lua (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, commit 2af0e55, 2026-10-07 14:01 PT).
--  * Quest names: Wowhead tooltip API (nether.wowhead.com/tooltip/quest/<id>), checked 2026-10-09. All 12 quest IDs resolved.
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
--  * uiMapIDs used here (UiMap DB2 12.1.0.69933): 2248 Isle of Dorn, 2371 K'aresh


local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["midnight_void_elf_dh_unlock"] = {
    id = "midnight_void_elf_dh_unlock", title = "Midnight: Unlock Void Elf Demon Hunter", expansion = "midnight",
    zone = 2371, minLevel = 80, maxLevel = 90,
    nextGuide = nil,
    steps = {
        { type = "accept", questID = 94933, text = "Lessons in the Void",
          coord = { map = 2248, x = 0.483, y = 0.446 } },  -- APR route coord (converted)
        { type = "quest",  questID = 94933, text = "Lessons in the Void (objective 2)",
          coord = { map = 2371, x = 0.609, y = 0.278 } },  -- APR route coord (converted)
        { type = "turnin", questID = 94933, text = "Turn in: Lessons in the Void",
          coord = { map = 2371, x = 0.609, y = 0.277 } },  -- APR route coord (converted)
        { type = "accept", questID = 90972, text = "A Common Cause",
          coord = { map = 2371, x = 0.609, y = 0.277 } },  -- APR route coord (converted)
        { type = "quest",  questID = 90972, text = "A Common Cause (objective 1)",
          coord = { map = 2371, x = 0.601, y = 0.297 } },  -- APR route coord (converted)
        { type = "turnin", questID = 90972, text = "Turn in: A Common Cause",
          coord = { map = 2371, x = 0.593, y = 0.242 } },  -- APR route coord (converted)
        { type = "accept", questID = 86786, text = "The Void Hunter",
          coord = { map = 2371, x = 0.593, y = 0.242 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86786, text = "The Void Hunter (objective 1)", useItem = 239074,
          coord = { map = 2371, x = 0.576, y = 0.223 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86786, text = "The Void Hunter (objective 2)", useItem = 239074,
          coord = { map = 2371, x = 0.573, y = 0.184 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86786, text = "The Void Hunter (objective 3)", useItem = 239074,
          coord = { map = 2371, x = 0.573, y = 0.184 } },  -- APR route coord (converted)
        { type = "quest",  questID = 86786, text = "The Void Hunter (objective 4)", useItem = 239074,
          coord = { map = 2371, x = 0.601, y = 0.297 } },  -- APR route coord (converted)
        { type = "turnin", questID = 86786, text = "Turn in: The Void Hunter",
          coord = { map = 2371, x = 0.601, y = 0.297 } },  -- APR route coord (converted)
        { type = "accept", questID = 89323, text = "Wasted Lands",
          coord = { map = 2371, x = 0.601, y = 0.297 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89323, text = "Wasted Lands (objective 1)",
          coord = { map = 2371, x = 0.789, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89323, text = "Turn in: Wasted Lands",
          coord = { map = 2371, x = 0.789, y = 0.535 } },  -- APR route coord (converted)
        { type = "accept", questID = 89324, text = "A Piece of Something Greater",
          coord = { map = 2371, x = 0.789, y = 0.535 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 3)",
          coord = { map = 2371, x = 0.768, y = 0.510 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 1)",
          coord = { map = 2371, x = 0.794, y = 0.480 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 2)",
          coord = { map = 2371, x = 0.801, y = 0.514 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 4)",
          coord = { map = 2371, x = 0.790, y = 0.535 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 5) [1/3]",
          coord = { map = 2371, x = 0.788, y = 0.536 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 5) [2/3]",
          coord = { map = 2371, x = 0.791, y = 0.531 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 5) [3/3]",
          coord = { map = 2371, x = 0.792, y = 0.536 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89324, text = "A Piece of Something Greater (objective 6)",
          coord = { map = 2371, x = 0.790, y = 0.534 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89324, text = "Turn in: A Piece of Something Greater",
          coord = { map = 2371, x = 0.789, y = 0.535 } },  -- APR route coord (converted)
        { type = "accept", questID = 89325, text = "The Void Confluence",
          coord = { map = 2371, x = 0.789, y = 0.535 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89325, text = "Turn in: The Void Confluence",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "accept", questID = 89326, text = "Distilled Darkness",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89326, text = "Distilled Darkness (objective 1)",
          coord = { map = 2371, x = 0.573, y = 0.218 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89326, text = "Distilled Darkness (objective 2)",
          coord = { map = 2371, x = 0.577, y = 0.236 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89326, text = "Turn in: Distilled Darkness",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "accept", questID = 89327, text = "Chaos",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89327, text = "Chaos (objective 1)",
          coord = { map = 2371, x = 0.585, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89327, text = "Chaos (objective 2)",
          coord = { map = 2371, x = 0.585, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89327, text = "Chaos (objective 3)",
          coord = { map = 2371, x = 0.585, y = 0.225 } },  -- APR route coord (converted)
        { type = "quest",  questID = 89327, text = "Chaos (objective 4)",
          coord = { map = 2371, x = 0.585, y = 0.226 } },  -- APR route coord (converted)
        { type = "turnin", questID = 89327, text = "Turn in: Chaos",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "accept", questID = 91044, text = "Hunger of the Void",
          coord = { map = 2371, x = 0.584, y = 0.226 } },  -- APR route coord (converted)
        { type = "quest",  questID = 91044, text = "Hunger of the Void (objective 1)",
          coord = { map = 2371, x = 0.609, y = 0.277 } },  -- APR route coord (converted)
        { type = "turnin", questID = 91044, text = "Turn in: Hunger of the Void", rep = { { factionID = 2658, amount = 500 } },
          coord = { map = 2371, x = 0.609, y = 0.277 } },  -- APR route coord (converted)
        { type = "accept", questID = 92630, text = "The Pursuit Continues",
          coord = { map = 2371, x = 0.609, y = 0.277 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92630, text = "The Pursuit Continues (objective 2)",
          coord = { map = 2371, x = 0.650, y = 0.404 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92630, text = "Turn in: The Pursuit Continues",
          coord = { map = 2371, x = 0.650, y = 0.406 } },  -- APR route coord (converted)
        { type = "accept", questID = 92631, text = "Abhorrent Gauntlet",
          coord = { map = 2371, x = 0.650, y = 0.406 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92631, text = "Abhorrent Gauntlet (objective 1)",
          coord = { map = 2371, x = 0.650, y = 0.439 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92631, text = "Turn in: Abhorrent Gauntlet",
          coord = { map = 2371, x = 0.650, y = 0.406 } },  -- APR route coord (converted)
        { type = "accept", questID = 92632, text = "Trial of Wrath",
          coord = { map = 2371, x = 0.650, y = 0.406 } },  -- APR route coord (converted)
        { type = "quest",  questID = 92632, text = "Trial of Wrath (objective 1)",
          coord = { map = 2371, x = 0.652, y = 0.498 } },  -- APR route coord (converted)
        { type = "turnin", questID = 92632, text = "Turn in: Trial of Wrath",
          coord = { map = 2371, x = 0.609, y = 0.278 } },  -- APR route coord (converted)
    },
}
