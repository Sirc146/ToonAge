-- ToonAge guide data: MoP Classic (5.5.x): The Wandering Isle (Pandaren 1-10)
-- Generated 2026-10-08. Opener patched to the MoP-Classic class-specific chain (see steps). Format: { type, questID, text, [class], [faction], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- uiMapID 378 (The Wandering Isle); MoP-era uiMapIDs are shared by Retail and MoP Classic.
--
-- SOURCES / VERIFICATION
--  * Quest ORDER: APR Retail route "378-Panda Starting Zone" (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, Routes/MistsOfPandaria).
--    This is a RETAIL route used as a proxy; MoP Classic quest flow is the original 5.x flow and may differ in places.
--  * Every questID below EXISTS in MoP Classic: verified via Wowhead MoP Classic tooltip API
--    (nether.wowhead.com/mop-classic/tooltip/quest/<id>), and the text is the MoP Classic quest name.
--    Dropped as not in MoP Classic: none
--  * accept coords: ATT giver coord (".contrib/.db/standard/02 - Outdoor Zones/06 Pandaria/*.lua") kept ONLY when the
--    same NPC's MoP Classic spawn on Wowhead (nether.wowhead.com/mop-classic/tooltip/npc/<id>) is within 2 map-% of it.
--    (257 givers across both zones confirmed; median ATT-vs-MoP-Classic distance 0.1 map-%, so retail and Classic geometry match.)
--  * quest/turnin coords: APR retail world coords converted with a linear fit for uiMap 378:
--      x = -0.0374368*aprX + 186.4151 ; y = -0.0561732*aprY + 100.3208  (max residual < 0.3 map-%)
--  * Steps outside uiMap 378 (cities, sub-zone maps) have coord = nil.
--  * Level ranges (MoP Classic): Wandering Isle 1-10 (Pandaren only); Jade Forest 85-86 (Dungeon Finder data in mop_dungeon_finder_levels.csv).

--  * MoP-Classic-only quests NOT in this route (ATT timeline ADDED_5_0_4, REMOVED_7_0_3), done in the capital after choosing a faction:
--      30988 "The Alliance Way" (Alliance), 30989 "An Old Pit Fighter", 31014 "Hellscream's Gift" (Horde). Add them to the capital guides.
--  * Retail-only step dropped: none in this zone (81638 "Home Is Where the Hearthstone Is" was only in the Horde Jade Forest route).

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["mists_wandering_isle"] = {
    coordsEstimated = true, -- converted from another map; spot-check in game
    id = "mists_wandering_isle", title = "The Wandering Isle (Pandaren 1-10)", client = "mists", faction = "Neutral", zone = 378,
    nextGuide = nil, -- choose Alliance/Horde at the end ("The Hand of Destiny")
    steps = {
        -- MoP Classic (pre-Legion) opener is CLASS-SPECIFIC: "Much to Learn" then "The Lesson of the Iron Bough".
        -- IDs/classes from ATT (timeline ADDED_5_0_4, REMOVED_7_0_3 for Much to Learn) + verified on Wowhead MoP Classic.
        -- Retail (APR) uses only 30027 for everyone; that is NOT how MoP Classic works.
        { type = "accept", questID = 30039, text = "Much to Learn", class = "MONK",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30039, text = "Turn in: Much to Learn", class = "MONK",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30027, text = "The Lesson of the Iron Bough", class = "MONK",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30027, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "MONK",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30027, text = "Turn in: The Lesson of the Iron Bough", class = "MONK",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30040, text = "Much to Learn", class = "MAGE",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30040, text = "Turn in: Much to Learn", class = "MAGE",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30033, text = "The Lesson of the Iron Bough", class = "MAGE",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30033, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "MAGE",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30033, text = "Turn in: The Lesson of the Iron Bough", class = "MAGE",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30041, text = "Much to Learn", class = "HUNTER",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30041, text = "Turn in: Much to Learn", class = "HUNTER",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30034, text = "The Lesson of the Iron Bough", class = "HUNTER",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30034, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "HUNTER",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30034, text = "Turn in: The Lesson of the Iron Bough", class = "HUNTER",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30042, text = "Much to Learn", class = "PRIEST",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30042, text = "Turn in: Much to Learn", class = "PRIEST",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30035, text = "The Lesson of the Iron Bough", class = "PRIEST",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30035, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "PRIEST",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30035, text = "Turn in: The Lesson of the Iron Bough", class = "PRIEST",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30043, text = "Much to Learn", class = "ROGUE",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30043, text = "Turn in: Much to Learn", class = "ROGUE",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30036, text = "The Lesson of the Iron Bough", class = "ROGUE",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30036, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "ROGUE",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30036, text = "Turn in: The Lesson of the Iron Bough", class = "ROGUE",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30044, text = "Much to Learn", class = "SHAMAN",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30044, text = "Turn in: Much to Learn", class = "SHAMAN",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30037, text = "The Lesson of the Iron Bough", class = "SHAMAN",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30037, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "SHAMAN",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30037, text = "Turn in: The Lesson of the Iron Bough", class = "SHAMAN",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 30045, text = "Much to Learn", class = "WARRIOR",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- giver Master Shang Xi (53566): ATT coord
        { type = "turnin", questID = 30045, text = "Turn in: Much to Learn", class = "WARRIOR",
          coord = { map = 378, x = 0.567, y = 0.186 } },  -- ATT coord (Shang Xi)
        { type = "accept", questID = 30038, text = "The Lesson of the Iron Bough", class = "WARRIOR",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30038, text = "The Lesson of the Iron Bough (loot & equip class weapon)", class = "WARRIOR",
          coord = nil },  -- weapon rack location not verified per class
        { type = "turnin", questID = 30038, text = "Turn in: The Lesson of the Iron Bough", class = "WARRIOR",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- Shang Xi (same NPC)
        { type = "accept", questID = 29406, text = "The Lesson of the Sandy Fist",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29406, text = "The Lesson of the Sandy Fist (objective 1)",
          coord = { map = 378, x = 0.573, y = 0.192 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29406, text = "Turn in: The Lesson of the Sandy Fist",
          coord = { map = 378, x = 0.566, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 29524, text = "The Lesson of Stifled Pride",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29524, text = "The Lesson of Stifled Pride (objective 1)",
          coord = { map = 378, x = 0.603, y = 0.196 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29524, text = "Turn in: The Lesson of Stifled Pride",
          coord = { map = 378, x = 0.597, y = 0.191 } },  -- APR route coord (converted)
        { type = "accept", questID = 29408, text = "The Lesson of the Burning Scroll",
          coord = { map = 378, x = 0.597, y = 0.191 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29408, text = "The Lesson of the Burning Scroll (objective 2)",
          coord = { map = 378, x = 0.600, y = 0.204 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29408, text = "Turn in: The Lesson of the Burning Scroll",
          coord = { map = 378, x = 0.598, y = 0.192 } },  -- APR route coord (converted)
        { type = "accept", questID = 29409, text = "The Disciple's Challenge",
          coord = { map = 378, x = 0.597, y = 0.191 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29409, text = "The Disciple's Challenge (objective 1)",
          coord = { map = 378, x = 0.676, y = 0.227 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29409, text = "Turn in: The Disciple's Challenge",
          coord = { map = 378, x = 0.660, y = 0.228 } },  -- APR route coord (converted)
        { type = "accept", questID = 29410, text = "Aysa of the Tushui",
          coord = { map = 378, x = 0.567, y = 0.182 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29410, text = "Turn in: Aysa of the Tushui",
          coord = { map = 378, x = 0.551, y = 0.328 } },  -- APR route coord (converted)
        { type = "accept", questID = 29419, text = "The Missing Driver",
          coord = { map = 378, x = 0.551, y = 0.328 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29424, text = "Items of Utmost Importance",
          coord = { map = 378, x = 0.551, y = 0.328 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29419, text = "The Missing Driver (objective 1)",
          coord = { map = 378, x = 0.543, y = 0.274 } },  -- APR route coord (converted)
        { type = "quest", questID = 29424, text = "Items of Utmost Importance (objective 1)",
          coord = { map = 378, x = 0.543, y = 0.274 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29419, text = "Turn in: The Missing Driver",
          coord = { map = 378, x = 0.551, y = 0.323 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29424, text = "Turn in: Items of Utmost Importance",
          coord = { map = 378, x = 0.551, y = 0.323 } },  -- APR route coord (converted)
        { type = "accept", questID = 29414, text = "The Way of the Tushui",
          coord = { map = 378, x = 0.551, y = 0.326 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29414, text = "The Way of the Tushui (objective 1)",
          coord = { map = 378, x = 0.577, y = 0.358 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29414, text = "Turn in: The Way of the Tushui",
          coord = { map = 378, x = 0.575, y = 0.348 } },  -- APR route coord (converted)
        { type = "accept", questID = 29522, text = "Ji of the Huojin",
          coord = { map = 378, x = 0.575, y = 0.347 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29522, text = "Turn in: Ji of the Huojin",
          coord = { map = 378, x = 0.503, y = 0.213 } },  -- APR route coord (converted)
        { type = "accept", questID = 29417, text = "The Way of the Huojin",
          coord = { map = 378, x = 0.502, y = 0.213 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29417, text = "The Way of the Huojin (objective 1)",
          coord = { map = 378, x = 0.495, y = 0.220 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29417, text = "Turn in: The Way of the Huojin",
          coord = { map = 378, x = 0.503, y = 0.212 } },  -- APR route coord (converted)
        { type = "accept", questID = 29418, text = "Kindling the Fire",
          coord = { map = 378, x = 0.502, y = 0.213 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29523, text = "Fanning the Flames",
          coord = { map = 378, x = 0.502, y = 0.213 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29523, text = "Fanning the Flames (objective 1)",
          coord = { map = 378, x = 0.474, y = 0.313 } },  -- APR route coord (converted)
        { type = "quest", questID = 29418, text = "Kindling the Fire (objective 1)",
          coord = { map = 378, x = 0.479, y = 0.318 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29418, text = "Turn in: Kindling the Fire",
          coord = { map = 378, x = 0.503, y = 0.213 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29523, text = "Turn in: Fanning the Flames",
          coord = { map = 378, x = 0.503, y = 0.213 } },  -- APR route coord (converted)
        { type = "accept", questID = 29420, text = "The Spirit's Guardian",
          coord = { map = 378, x = 0.503, y = 0.215 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29420, text = "Turn in: The Spirit's Guardian",
          coord = { map = 378, x = 0.389, y = 0.254 } },  -- APR route coord (converted)
        { type = "accept", questID = 29664, text = "The Challenger's Fires",
          coord = { map = 378, x = 0.388, y = 0.255 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29664, text = "The Challenger's Fires (objective 1)",
          coord = { map = 378, x = 0.389, y = 0.254 } },  -- APR route coord (converted)
        { type = "quest", questID = 29664, text = "The Challenger's Fires (objective 4)",
          coord = { map = 378, x = 0.383, y = 0.250 } },  -- APR route coord (converted)
        { type = "quest", questID = 29664, text = "The Challenger's Fires (objective 2)",
          coord = { map = 378, x = 0.390, y = 0.239 } },  -- APR route coord (converted)
        { type = "quest", questID = 29664, text = "The Challenger's Fires (objective 3)",
          coord = { map = 378, x = 0.392, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29664, text = "Turn in: The Challenger's Fires",
          coord = { map = 378, x = 0.388, y = 0.255 } },  -- APR route coord (converted)
        { type = "accept", questID = 29421, text = "Only the Worthy Shall Pass",
          coord = { map = 378, x = 0.388, y = 0.255 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29421, text = "Only the Worthy Shall Pass (objective 1)",
          coord = { map = 378, x = 0.389, y = 0.246 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29421, text = "Turn in: Only the Worthy Shall Pass",
          coord = { map = 378, x = 0.388, y = 0.254 } },  -- APR route coord (converted)
        { type = "accept", questID = 29422, text = "Huo, the Spirit of Fire",
          coord = { map = 378, x = 0.388, y = 0.255 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29422, text = "Huo, the Spirit of Fire (objective 1)",
          coord = { map = 378, x = 0.393, y = 0.292 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29422, text = "Turn in: Huo, the Spirit of Fire",
          coord = { map = 378, x = 0.393, y = 0.292 } },  -- APR route coord (converted)
        { type = "accept", questID = 29423, text = "The Passion of Shen-zin Su",
          coord = { map = 378, x = 0.394, y = 0.295 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29423, text = "The Passion of Shen-zin Su (objective 1)",
          coord = { map = 378, x = 0.514, y = 0.463 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29423, text = "Turn in: The Passion of Shen-zin Su",
          coord = { map = 378, x = 0.514, y = 0.463 } },  -- APR route coord (converted)
        { type = "accept", questID = 29521, text = "The Singing Pools",
          coord = { map = 378, x = 0.514, y = 0.464 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29662, text = "Stronger Than Reeds",
          coord = { map = 378, x = 0.635, y = 0.419 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29521, text = "Turn in: The Singing Pools",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- APR route coord (converted)
        { type = "accept", questID = 29661, text = "The Lesson of Dry Fur",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29663, text = "The Lesson of the Balanced Rock",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29662, text = "Stronger Than Reeds (objective 1)",
          coord = { map = 378, x = 0.633, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest", questID = 29663, text = "The Lesson of the Balanced Rock (objective 1)",
          coord = { map = 378, x = 0.633, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest", questID = 29661, text = "The Lesson of Dry Fur (objective 1)",
          coord = { map = 378, x = 0.615, y = 0.479 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29662, text = "Turn in: Stronger Than Reeds",
          coord = { map = 378, x = 0.635, y = 0.420 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29661, text = "Turn in: The Lesson of Dry Fur",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29663, text = "Turn in: The Lesson of the Balanced Rock",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- APR route coord (converted)
        { type = "accept", questID = 29676, text = "Finding an Old Friend",
          coord = { map = 378, x = 0.656, y = 0.426 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29676, text = "Turn in: Finding an Old Friend",
          coord = { map = 378, x = 0.706, y = 0.387 } },  -- APR route coord (converted)
        { type = "accept", questID = 29666, text = "The Sting of Learning",
          coord = { map = 378, x = 0.706, y = 0.387 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29677, text = "The Sun Pearl",
          coord = { map = 378, x = 0.706, y = 0.387 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29666, text = "The Sting of Learning (objective 1)",
          coord = { map = 378, x = 0.732, y = 0.400 } },  -- APR route coord (converted)
        { type = "quest", questID = 29677, text = "The Sun Pearl (objective 1)",
          coord = { map = 378, x = 0.761, y = 0.465 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29666, text = "Turn in: The Sting of Learning",
          coord = { map = 378, x = 0.707, y = 0.386 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29677, text = "Turn in: The Sun Pearl",
          coord = { map = 378, x = 0.707, y = 0.386 } },  -- APR route coord (converted)
        { type = "accept", questID = 29678, text = "Shu, the Spirit of Water",
          coord = { map = 378, x = 0.784, y = 0.430 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29678, text = "Shu, the Spirit of Water (objective 1,2)",
          coord = { map = 378, x = 0.796, y = 0.385 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29678, text = "Turn in: Shu, the Spirit of Water",
          coord = { map = 378, x = 0.795, y = 0.382 } },  -- APR route coord (converted)
        { type = "accept", questID = 29679, text = "A New Friend",
          coord = { map = 378, x = 0.798, y = 0.393 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29679, text = "A New Friend (objective 1)",
          coord = { map = 378, x = 0.792, y = 0.374 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29679, text = "Turn in: A New Friend",
          coord = { map = 378, x = 0.798, y = 0.392 } },  -- APR route coord (converted)
        { type = "accept", questID = 29680, text = "The Source of Our Livelihood",
          coord = { map = 378, x = 0.798, y = 0.393 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29680, text = "Turn in: The Source of Our Livelihood",
          coord = { map = 378, x = 0.690, y = 0.650 } },  -- APR route coord (converted)
        { type = "accept", questID = 29769, text = "Rascals",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29770, text = "Still Good!",
          coord = { map = 378, x = 0.681, y = 0.664 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29769, text = "Rascals (objective 1)",
          coord = { map = 378, x = 0.739, y = 0.722 } },  -- APR route coord (converted)
        { type = "quest", questID = 29769, text = "Rascals (objective 1)",
          coord = { map = 378, x = 0.749, y = 0.721 } },  -- APR route coord (converted)
        { type = "quest", questID = 29770, text = "Still Good! (objective 2)",
          coord = { map = 378, x = 0.749, y = 0.721 } },  -- APR route coord (converted)
        { type = "quest", questID = 29770, text = "Still Good! (objective 3)",
          coord = { map = 378, x = 0.787, y = 0.709 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29770, text = "Turn in: Still Good!",
          coord = { map = 378, x = 0.682, y = 0.665 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29769, text = "Turn in: Rascals",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- APR route coord (converted)
        { type = "accept", questID = 29768, text = "Missing Mallet",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29771, text = "Stronger Than Wood",
          coord = { map = 378, x = 0.692, y = 0.667 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29768, text = "Missing Mallet (objective 1)",
          coord = { map = 378, x = 0.627, y = 0.768 } },  -- APR route coord (converted)
        { type = "quest", questID = 29771, text = "Stronger Than Wood (objective 1)",
          coord = { map = 378, x = 0.627, y = 0.768 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29771, text = "Turn in: Stronger Than Wood",
          coord = { map = 378, x = 0.691, y = 0.666 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29768, text = "Turn in: Missing Mallet",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- APR route coord (converted)
        { type = "accept", questID = 29772, text = "Raucous Rousing",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29772, text = "Raucous Rousing (objective 1)",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29772, text = "Turn in: Raucous Rousing",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- APR route coord (converted)
        { type = "accept", questID = 29774, text = "Not In the Face!",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29774, text = "Not In the Face! (objective 1)",
          coord = { map = 378, x = 0.690, y = 0.631 } },  -- APR route coord (converted)
        { type = "quest", questID = 29774, text = "Not In the Face! (objective 2)",
          coord = { map = 378, x = 0.693, y = 0.639 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29774, text = "Turn in: Not In the Face!",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- APR route coord (converted)
        { type = "accept", questID = 29775, text = "The Spirit and Body of Shen-zin Su",
          coord = { map = 378, x = 0.689, y = 0.650 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29775, text = "Turn in: The Spirit and Body of Shen-zin Su",
          coord = { map = 378, x = 0.515, y = 0.486 } },  -- APR route coord (converted)
        { type = "accept", questID = 29776, text = "Morning Breeze Village",
          coord = { map = 378, x = 0.516, y = 0.483 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29776, text = "Turn in: Morning Breeze Village",
          coord = { map = 378, x = 0.310, y = 0.368 } },  -- APR route coord (converted)
        { type = "accept", questID = 29778, text = "Rewritten Wisdoms",
          coord = { map = 378, x = 0.310, y = 0.367 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29783, text = "Stronger Than Stone",
          coord = { map = 378, x = 0.299, y = 0.398 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29777, text = "Tools of the Enemy",
          coord = { map = 378, x = 0.318, y = 0.397 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29778, text = "Rewritten Wisdoms (objective 1)",
          coord = { map = 378, x = 0.284, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 29777, text = "Tools of the Enemy (objective 1)",
          coord = { map = 378, x = 0.284, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 29783, text = "Stronger Than Stone (objective 1)",
          coord = { map = 378, x = 0.284, y = 0.495 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29777, text = "Turn in: Tools of the Enemy",
          coord = { map = 378, x = 0.318, y = 0.398 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29783, text = "Turn in: Stronger Than Stone",
          coord = { map = 378, x = 0.300, y = 0.398 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29778, text = "Turn in: Rewritten Wisdoms",
          coord = { map = 378, x = 0.309, y = 0.368 } },  -- APR route coord (converted)
        { type = "accept", questID = 29779, text = "The Direct Solution",
          coord = { map = 378, x = 0.310, y = 0.367 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29780, text = "Do No Evil",
          coord = { map = 378, x = 0.310, y = 0.367 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29781, text = "Monkey Advisory Warning",
          coord = { map = 378, x = 0.310, y = 0.367 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29782, text = "Stronger Than Bone",
          coord = { map = 378, x = 0.265, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest", questID = 29780, text = "Do No Evil (objective 1)",
          coord = { map = 378, x = 0.246, y = 0.351 } },  -- APR route coord (converted)
        { type = "quest", questID = 29779, text = "The Direct Solution (objective 1)",
          coord = { map = 378, x = 0.211, y = 0.344 } },  -- APR route coord (converted)
        { type = "quest", questID = 29781, text = "Monkey Advisory Warning (objective 1)",
          coord = { map = 378, x = 0.211, y = 0.344 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29779, text = "Turn in: The Direct Solution",
          coord = { map = 378, x = 0.233, y = 0.317 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29780, text = "Turn in: Do No Evil",
          coord = { map = 378, x = 0.233, y = 0.317 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29781, text = "Turn in: Monkey Advisory Warning",
          coord = { map = 378, x = 0.233, y = 0.317 } },  -- APR route coord (converted)
        { type = "accept", questID = 29784, text = "Balanced Perspective",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 29782, text = "Turn in: Stronger Than Bone",
          coord = { map = 378, x = 0.298, y = 0.397 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29784, text = "Turn in: Balanced Perspective",
          coord = { map = 378, x = 0.330, y = 0.358 } },  -- APR route coord (converted)
        { type = "accept", questID = 29785, text = "Dafeng, the Spirit of Air",
          coord = { map = 378, x = 0.329, y = 0.356 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29785, text = "Dafeng, the Spirit of Air (objective 1)",
          coord = { map = 378, x = 0.247, y = 0.697 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29785, text = "Turn in: Dafeng, the Spirit of Air",
          coord = { map = 378, x = 0.247, y = 0.697 } },  -- APR route coord (converted)
        { type = "accept", questID = 29786, text = "Battle for the Skies",
          coord = { map = 378, x = 0.248, y = 0.698 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29786, text = "Battle for the Skies (objective 1)",
          coord = { map = 378, x = 0.304, y = 0.599 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29786, text = "Turn in: Battle for the Skies",
          coord = { map = 378, x = 0.301, y = 0.603 } },  -- APR route coord (converted)
        { type = "accept", questID = 29787, text = "Worthy of Passing",
          coord = { map = 378, x = 0.300, y = 0.604 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29787, text = "Worthy of Passing (objective 1)",
          coord = { map = 378, x = 0.231, y = 0.528 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29787, text = "Turn in: Worthy of Passing",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- APR route coord (converted)
        { type = "accept", questID = 29788, text = "Unwelcome Nature",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29789, text = "Small, But Significant",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29788, text = "Unwelcome Nature (objective 1)",
          coord = { map = 378, x = 0.189, y = 0.488 } },  -- APR route coord (converted)
        { type = "quest", questID = 29789, text = "Small, But Significant (objective 1)",
          coord = { map = 378, x = 0.189, y = 0.488 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29788, text = "Turn in: Unwelcome Nature",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29789, text = "Turn in: Small, But Significant",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- APR route coord (converted)
        { type = "accept", questID = 29790, text = "Passing Wisdom",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29790, text = "Passing Wisdom (objective 1)",
          coord = { map = 378, x = 0.195, y = 0.512 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29790, text = "Turn in: Passing Wisdom",
          coord = { map = 378, x = 0.159, y = 0.492 } },  -- APR route coord (converted)
        { type = "accept", questID = 29791, text = "The Suffering of Shen-zin Su",
          coord = { map = 378, x = 0.158, y = 0.491 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29791, text = "The Suffering of Shen-zin Su (objective 1)",
          coord = { map = 378, x = 0.155, y = 0.489 } },  -- APR route coord (converted)
        { type = "quest", questID = 29791, text = "The Suffering of Shen-zin Su (objective 2)",
          coord = { map = 378, x = 0.330, y = 0.933 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29791, text = "Turn in: The Suffering of Shen-zin Su",
          coord = { map = 378, x = 0.514, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 29792, text = "Bidden to Greatness",
          coord = { map = 378, x = 0.513, y = 0.483 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29792, text = "Bidden to Greatness (objective 1)",
          coord = { map = 378, x = 0.516, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest", questID = 29792, text = "Bidden to Greatness (objective 2)",
          coord = { map = 378, x = 0.523, y = 0.682 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29792, text = "Turn in: Bidden to Greatness",
          coord = { map = 378, x = 0.501, y = 0.766 } },  -- APR route coord (converted)
        { type = "accept", questID = 30591, text = "Preying on the Predators",
          coord = { map = 378, x = 0.501, y = 0.766 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29795, text = "Stocking Stalks",
          coord = { map = 378, x = 0.502, y = 0.766 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29795, text = "Stocking Stalks (objective 1)",
          coord = { map = 378, x = 0.490, y = 0.781 } },  -- APR route coord (converted)
        { type = "quest", questID = 30591, text = "Preying on the Predators (objective 1)",
          coord = { map = 378, x = 0.490, y = 0.781 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29795, text = "Turn in: Stocking Stalks",
          coord = { map = 378, x = 0.502, y = 0.767 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30591, text = "Turn in: Preying on the Predators",
          coord = { map = 378, x = 0.502, y = 0.767 } },  -- APR route coord (converted)
        { type = "accept", questID = 30589, text = "Wrecking the Wreck",
          coord = { map = 378, x = 0.502, y = 0.766 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 30589, text = "Turn in: Wrecking the Wreck",
          coord = { map = 378, x = 0.364, y = 0.724 } },  -- APR route coord (converted)
        { type = "accept", questID = 30590, text = "Handle With Care",
          coord = { map = 378, x = 0.363, y = 0.724 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29793, text = "Evil from the Seas",
          coord = { map = 378, x = 0.364, y = 0.725 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29793, text = "Evil from the Seas (objective 1)",
          coord = { map = 378, x = 0.395, y = 0.723 } },  -- APR route coord (converted)
        { type = "quest", questID = 30590, text = "Handle With Care (objective 1)",
          coord = { map = 378, x = 0.395, y = 0.723 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29793, text = "Turn in: Evil from the Seas",
          coord = { map = 378, x = 0.364, y = 0.726 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30590, text = "Turn in: Handle With Care",
          coord = { map = 378, x = 0.364, y = 0.726 } },  -- APR route coord (converted)
        { type = "accept", questID = 29796, text = "Urgent News",
          coord = { map = 378, x = 0.364, y = 0.725 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29796, text = "Turn in: Urgent News",
          coord = { map = 378, x = 0.422, y = 0.864 } },  -- APR route coord (converted)
        { type = "accept", questID = 29794, text = "None Left Behind",
          coord = { map = 378, x = 0.422, y = 0.865 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29797, text = "Medical Supplies",
          coord = { map = 378, x = 0.422, y = 0.865 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29665, text = "From Bad to Worse",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29665, text = "From Bad to Worse (objective 1)",
          coord = { map = 378, x = 0.375, y = 0.848 } },  -- APR route coord (converted)
        { type = "quest", questID = 29797, text = "Medical Supplies (objective 1)",
          coord = { map = 378, x = 0.375, y = 0.848 } },  -- APR route coord (converted)
        { type = "quest", questID = 29794, text = "None Left Behind (objective 1)",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29665, text = "Turn in: From Bad to Worse",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29794, text = "Turn in: None Left Behind",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29797, text = "Turn in: Medical Supplies",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- APR route coord (converted)
        { type = "accept", questID = 29798, text = "An Ancient Evil",
          coord = { map = 378, x = 0.423, y = 0.864 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29798, text = "An Ancient Evil (objective 1)",
          coord = { map = 378, x = 0.364, y = 0.843 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29798, text = "Turn in: An Ancient Evil",
          coord = { map = 378, x = 0.364, y = 0.843 } },  -- APR route coord (converted)
        { type = "accept", questID = 30767, text = "Risking It All",
          coord = { map = 378, x = 0.365, y = 0.842 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30767, text = "Risking It All (objective 1)",
          coord = { map = 378, x = 0.392, y = 0.862 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30767, text = "Turn in: Risking It All",
          coord = { map = 378, x = 0.392, y = 0.862 } },  -- APR route coord (converted)
        { type = "accept", questID = 29799, text = "The Healing of Shen-zin Su",
          coord = { map = 378, x = 0.393, y = 0.862 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29799, text = "The Healing of Shen-zin Su (objective 1)",
          coord = { map = 378, x = 0.424, y = 0.852 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29799, text = "Turn in: The Healing of Shen-zin Su",
          coord = { map = 378, x = 0.394, y = 0.862 } },  -- APR route coord (converted)
        { type = "accept", questID = 29800, text = "New Allies",
          coord = { map = 378, x = 0.388, y = 0.863 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29800, text = "Turn in: New Allies",
          coord = { map = 378, x = 0.515, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 31450, text = "A New Fate",
          coord = { map = 378, x = 0.514, y = 0.483 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31450, text = "A New Fate (objective 1)",
          coord = { map = 378, x = 0.515, y = 0.484 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31450, text = "Turn in: A New Fate", faction = "Horde",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 31012, text = "Joining the Horde", faction = "Horde",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 31012, text = "Turn in: Joining the Horde", faction = "Horde",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 31013, text = "The Horde Way", faction = "Horde",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 31013, text = "Turn in: The Horde Way", faction = "Horde",
          coord = nil },  -- no verified coord
    },
}
