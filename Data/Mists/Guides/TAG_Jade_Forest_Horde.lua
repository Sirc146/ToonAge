-- ToonAge guide data: MoP Classic (5.5.x): The Jade Forest (Horde)
-- Generated 2026-10-08. Format: { type, questID, text, [class], [faction], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- uiMapID 371 (The Jade Forest); MoP-era uiMapIDs are shared by Retail and MoP Classic.
--
-- SOURCES / VERIFICATION
--  * Quest ORDER: APR Retail route "371-The Jade Forest - H" (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, Routes/MistsOfPandaria).
--    This is a RETAIL route used as a proxy; MoP Classic quest flow is the original 5.x flow and may differ in places.
--  * Every questID below EXISTS in MoP Classic: verified via Wowhead MoP Classic tooltip API
--    (nether.wowhead.com/mop-classic/tooltip/quest/<id>), and the text is the MoP Classic quest name.
--    Dropped as not in MoP Classic: [81638]
--  * accept coords: ATT giver coord (".contrib/.db/standard/02 - Outdoor Zones/06 Pandaria/*.lua") kept ONLY when the
--    same NPC's MoP Classic spawn on Wowhead (nether.wowhead.com/mop-classic/tooltip/npc/<id>) is within 2 map-% of it.
--    (257 givers across both zones confirmed; median ATT-vs-MoP-Classic distance 0.1 map-%, so retail and Classic geometry match.)
--  * quest/turnin coords: APR retail world coords converted with a linear fit for uiMap 371:
--      x = -0.0143179*aprX + 20.7491 ; y = -0.0214979*aprY + 78.4529  (max residual < 0.3 map-%)
--  * Steps outside uiMap 371 (cities, sub-zone maps) have coord = nil.
--  * Level ranges (MoP Classic): Wandering Isle 1-10 (Pandaren only); Jade Forest 85-86 (Dungeon Finder data in mop_dungeon_finder_levels.csv).

--  * The MoP Classic arrival chain (Stormwind/Orgrimmar -> airship/gunship to Pandaria) is NOT included; APR's retail
--    "84-MoP Intro"/"85-MoP Intro" routes differ from 5.x Classic. Start this guide on arrival in The Jade Forest.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["mists_jade_forest_horde"] = {
    coordsEstimated = true, -- converted from another map; spot-check in game
    id = "mists_jade_forest_horde", title = "The Jade Forest (Horde)", client = "mists", faction = "Horde", zone = 371,
    nextGuide = nil, -- next: Valley of the Four Winds
    steps = {
        { type = "accept", questID = 31765, text = "Paint it Red!",
          coord = { map = 371, x = 0.307, y = 0.102 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31765, text = "Paint it Red! (objective 1,2)",
          coord = { map = 371, x = 0.315, y = 0.110 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31765, text = "Turn in: Paint it Red!",
          coord = { map = 371, x = 0.310, y = 0.110 } },  -- APR route coord (converted)
        { type = "accept", questID = 31766, text = "Touching Ground",
          coord = { map = 371, x = 0.310, y = 0.110 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31766, text = "Touching Ground (objective 1)",
          coord = { map = 371, x = 0.315, y = 0.111 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31766, text = "Turn in: Touching Ground",
          coord = { map = 371, x = 0.315, y = 0.112 } },  -- APR route coord (converted)
        { type = "accept", questID = 31767, text = "Finish Them!",
          coord = { map = 371, x = 0.316, y = 0.113 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31768, text = "Fire Is Always the Answer",
          coord = { map = 371, x = 0.316, y = 0.113 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31767, text = "Finish Them! (objective 1)",
          coord = { map = 371, x = 0.340, y = 0.079 } },  -- APR route coord (converted)
        { type = "quest", questID = 31768, text = "Fire Is Always the Answer (objective 1)",
          coord = { map = 371, x = 0.340, y = 0.079 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31767, text = "Turn in: Finish Them!",
          coord = { map = 371, x = 0.347, y = 0.106 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31768, text = "Turn in: Fire Is Always the Answer",
          coord = { map = 371, x = 0.347, y = 0.106 } },  -- APR route coord (converted)
        { type = "accept", questID = 31769, text = "The Final Blow!",
          coord = { map = 371, x = 0.347, y = 0.106 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31769, text = "The Final Blow! (objective 1)",
          coord = { map = 371, x = 0.340, y = 0.098 } },  -- APR route coord (converted)
        { type = "quest", questID = 31769, text = "The Final Blow! (objective 2)",
          coord = { map = 371, x = 0.347, y = 0.098 } },  -- APR route coord (converted)
        { type = "quest", questID = 31769, text = "The Final Blow! (objective 3)",
          coord = { map = 371, x = 0.349, y = 0.104 } },  -- APR route coord (converted)
        { type = "quest", questID = 31769, text = "The Final Blow! (objective 4)",
          coord = { map = 371, x = 0.336, y = 0.106 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31769, text = "Turn in: The Final Blow!",
          coord = { map = 371, x = 0.336, y = 0.106 } },  -- APR route coord (converted)
        { type = "accept", questID = 31771, text = "Face to Face With Consequence",
          coord = { map = 371, x = 0.337, y = 0.106 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29694, text = "Regroup!",
          coord = { map = 371, x = 0.336, y = 0.106 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31770, text = "You're Either With Us Or...",
          coord = { map = 371, x = 0.336, y = 0.106 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31771, text = "Face to Face With Consequence (objective 1,2)",
          coord = { map = 371, x = 0.344, y = 0.106 } },  -- APR route coord (converted)
        { type = "quest", questID = 29694, text = "Regroup! (objective 1)",
          coord = { map = 371, x = 0.320, y = 0.133 } },  -- APR route coord (converted)
        { type = "accept", questID = 31773, text = "Prowler Problems",
          coord = { map = 371, x = 0.320, y = 0.133 } },  -- APR route coord (converted)
        { type = "accept", questID = 31978, text = "Priorities!",
          coord = { map = 371, x = 0.319, y = 0.132 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29694, text = "Regroup! (objective 3)",
          coord = { map = 371, x = 0.305, y = 0.116 } },  -- APR route coord (converted)
        { type = "quest", questID = 29694, text = "Regroup! (objective 2)",
          coord = { map = 371, x = 0.305, y = 0.072 } },  -- APR route coord (converted)
        { type = "quest", questID = 29694, text = "Regroup! (objective 4)",
          coord = { map = 371, x = 0.294, y = 0.084 } },  -- APR route coord (converted)
        { type = "quest", questID = 31773, text = "Prowler Problems (objective 1)",
          coord = { map = 371, x = 0.307, y = 0.117 } },  -- APR route coord (converted)
        { type = "quest", questID = 31978, text = "Priorities! (objective 1)",
          coord = { map = 371, x = 0.307, y = 0.117 } },  -- APR route coord (converted)
        { type = "quest", questID = 31770, text = "You're Either With Us Or... (objective 1)",
          coord = { map = 371, x = 0.292, y = 0.135 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31770, text = "Turn in: You're Either With Us Or...",
          coord = { map = 371, x = 0.291, y = 0.138 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31771, text = "Turn in: Face to Face With Consequence",
          coord = { map = 371, x = 0.291, y = 0.138 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31773, text = "Turn in: Prowler Problems",
          coord = { map = 371, x = 0.291, y = 0.138 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29694, text = "Turn in: Regroup!",
          coord = { map = 371, x = 0.291, y = 0.138 } },  -- APR route coord (converted)
        { type = "accept", questID = 31774, text = "Seeking Zin'jun",
          coord = { map = 371, x = 0.291, y = 0.137 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 31978, text = "Turn in: Priorities!",
          coord = { map = 371, x = 0.293, y = 0.135 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31774, text = "Turn in: Seeking Zin'jun",
          coord = { map = 371, x = 0.311, y = 0.175 } },  -- APR route coord (converted)
        { type = "accept", questID = 29765, text = "Cryin' My Eyes Out",
          coord = { map = 371, x = 0.311, y = 0.175 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29743, text = "Monstrosity",
          coord = { map = 371, x = 0.309, y = 0.175 } },  -- APR route coord (converted)
        { type = "quest", questID = 29743, text = "Monstrosity (objective 1)",
          coord = { map = 371, x = 0.293, y = 0.189 } },  -- APR route coord (converted)
        { type = "quest", questID = 29743, text = "Monstrosity (objective 2)",
          coord = { map = 371, x = 0.298, y = 0.213 } },  -- APR route coord (converted)
        { type = "quest", questID = 29743, text = "Monstrosity (objective 4)",
          coord = { map = 371, x = 0.299, y = 0.223 } },  -- APR route coord (converted)
        { type = "quest", questID = 29743, text = "Monstrosity (objective 3)",
          coord = { map = 371, x = 0.286, y = 0.221 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29743, text = "Turn in: Monstrosity",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 29765, text = "Cryin' My Eyes Out (objective 1,2,3,4)",
          coord = { map = 371, x = 0.298, y = 0.209 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29765, text = "Turn in: Cryin' My Eyes Out",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29804, text = "Seein' Red",
          coord = { map = 371, x = 0.311, y = 0.175 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29804, text = "Seein' Red (objective 1)",
          coord = { map = 371, x = 0.319, y = 0.222 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29804, text = "Turn in: Seein' Red",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- APR route coord (converted)
        { type = "accept", questID = 31775, text = "Assault on the Airstrip",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31776, text = "Strongarm Tactics",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31778, text = "Unreliable Allies",
          coord = { map = 371, x = 0.314, y = 0.217 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31777, text = "Choppertunity",
          coord = { map = 371, x = 0.311, y = 0.215 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31776, text = "Strongarm Tactics (objective 2)",
          coord = { map = 371, x = 0.296, y = 0.231 } },  -- APR route coord (converted)
        { type = "quest", questID = 31776, text = "Strongarm Tactics (objective 1)",
          coord = { map = 371, x = 0.302, y = 0.242 } },  -- APR route coord (converted)
        { type = "quest", questID = 31776, text = "Strongarm Tactics (objective 3)",
          coord = { map = 371, x = 0.278, y = 0.229 } },  -- APR route coord (converted)
        { type = "quest", questID = 31776, text = "Strongarm Tactics (objective 4)",
          coord = { map = 371, x = 0.278, y = 0.230 } },  -- APR route coord (converted)
        { type = "quest", questID = 31777, text = "Choppertunity (objective 1)",
          coord = { map = 371, x = 0.279, y = 0.245 } },  -- APR route coord (converted)
        { type = "quest", questID = 31775, text = "Assault on the Airstrip (objective 1)",
          coord = { map = 371, x = 0.279, y = 0.245 } },  -- APR route coord (converted)
        { type = "quest", questID = 31778, text = "Unreliable Allies (objective 1)",
          coord = { map = 371, x = 0.279, y = 0.245 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31777, text = "Turn in: Choppertunity",
          coord = { map = 371, x = 0.311, y = 0.215 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31778, text = "Turn in: Unreliable Allies",
          coord = { map = 371, x = 0.314, y = 0.217 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31775, text = "Turn in: Assault on the Airstrip",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31776, text = "Turn in: Strongarm Tactics",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- APR route coord (converted)
        { type = "accept", questID = 31779, text = "The Darkness Within",
          coord = { map = 371, x = 0.316, y = 0.219 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31779, text = "The Darkness Within (objective 1)",
          coord = { map = 371, x = 0.257, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31779, text = "Turn in: The Darkness Within",
          coord = { map = 371, x = 0.275, y = 0.242 } },  -- APR route coord (converted)
        { type = "accept", questID = 31999, text = "Nazgrim's Command",
          coord = { map = 371, x = 0.275, y = 0.242 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31999, text = "Turn in: Nazgrim's Command",
          coord = { map = 371, x = 0.284, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 29815, text = "Forensic Science",
          coord = { map = 371, x = 0.281, y = 0.248 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29821, text = "Missed Me By... That Much!",
          coord = { map = 371, x = 0.281, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29821, text = "Turn in: Missed Me By... That Much!",
          coord = { map = 371, x = 0.229, y = 0.306 } },  -- APR route coord (converted)
        { type = "accept", questID = 31112, text = "They're So Thorny!",
          coord = { map = 371, x = 0.229, y = 0.306 } },  -- APR route coord (converted)
        { type = "quest", questID = 29815, text = "Forensic Science (objective 1)",
          coord = { map = 371, x = 0.249, y = 0.267 } },  -- APR route coord (converted)
        { type = "quest", questID = 31112, text = "They're So Thorny! (objective 1)",
          coord = { map = 371, x = 0.249, y = 0.267 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31112, text = "Turn in: They're So Thorny!",
          coord = { map = 371, x = 0.280, y = 0.247 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29815, text = "Turn in: Forensic Science",
          coord = { map = 371, x = 0.281, y = 0.248 } },  -- APR route coord (converted)
        { type = "accept", questID = 29827, text = "Acid Rain",
          coord = { map = 371, x = 0.281, y = 0.248 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29827, text = "Acid Rain (objective 1,2)",
          coord = { map = 371, x = 0.280, y = 0.247 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29827, text = "Turn in: Acid Rain",
          coord = { map = 371, x = 0.281, y = 0.247 } },  -- APR route coord (converted)
        { type = "accept", questID = 29822, text = "Lay of the Land",
          coord = { map = 371, x = 0.284, y = 0.249 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29822, text = "Lay of the Land (objective 3)",
          coord = { map = 371, x = 0.277, y = 0.303 } },  -- APR route coord (converted)
        { type = "quest", questID = 29822, text = "Lay of the Land (objective 2)",
          coord = { map = 371, x = 0.262, y = 0.323 } },  -- APR route coord (converted)
        { type = "quest", questID = 29822, text = "Lay of the Land (objective 1)",
          coord = { map = 371, x = 0.319, y = 0.278 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29822, text = "Turn in: Lay of the Land",
          coord = { map = 371, x = 0.275, y = 0.326 } },  -- APR route coord (converted)
        { type = "accept", questID = 31121, text = "Stay a While, and Listen",
          coord = { map = 371, x = 0.275, y = 0.326 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31121, text = "Stay a While, and Listen (objective 1)",
          coord = { map = 371, x = 0.275, y = 0.325 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31121, text = "Turn in: Stay a While, and Listen",
          coord = { map = 371, x = 0.275, y = 0.326 } },  -- APR route coord (converted)
        { type = "accept", questID = 31132, text = "A Mile in My Shoes",
          coord = { map = 371, x = 0.275, y = 0.326 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 31132, text = "Turn in: A Mile in My Shoes",
          coord = { map = 371, x = 0.308, y = 0.340 } },  -- APR route coord (converted)
        { type = "accept", questID = 31134, text = "If These Stones Could Speak",
          coord = { map = 371, x = 0.308, y = 0.340 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31134, text = "If These Stones Could Speak (objective 1)",
          coord = { map = 371, x = 0.308, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest", questID = 31134, text = "If These Stones Could Speak (objective 2)",
          coord = { map = 371, x = 0.306, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest", questID = 31134, text = "If These Stones Could Speak (objective 3)",
          coord = { map = 371, x = 0.305, y = 0.341 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31134, text = "Turn in: If These Stones Could Speak",
          coord = { map = 371, x = 0.308, y = 0.340 } },  -- APR route coord (converted)
        { type = "accept", questID = 31152, text = "Peering Into the Past",
          coord = { map = 371, x = 0.308, y = 0.340 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31152, text = "Peering Into the Past (objective 1)",
          coord = { map = 371, x = 0.288, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31152, text = "Turn in: Peering Into the Past",
          coord = { map = 371, x = 0.288, y = 0.326 } },  -- APR route coord (converted)
        { type = "accept", questID = 31167, text = "Family Tree",
          coord = { map = 371, x = 0.288, y = 0.326 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31167, text = "Family Tree (objective 1)",
          coord = { map = 371, x = 0.287, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31167, text = "Turn in: Family Tree",
          coord = { map = 371, x = 0.288, y = 0.326 } },  -- APR route coord (converted)
        { type = "accept", questID = 29879, text = "Swallowed Whole",
          coord = { map = 371, x = 0.288, y = 0.326 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29879, text = "Swallowed Whole (objective 1,2)",
          coord = { map = 371, x = 0.235, y = 0.350 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29879, text = "Turn in: Swallowed Whole",
          coord = { map = 371, x = 0.262, y = 0.373 } },  -- APR route coord (converted)
        { type = "accept", questID = 29935, text = "Orders are Orders",
          coord = { map = 371, x = 0.262, y = 0.373 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29933, text = "The Bees' Knees",
          coord = { map = 371, x = 0.258, y = 0.379 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29924, text = "Kill Kher Shan",
          coord = { map = 371, x = 0.259, y = 0.387 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31241, text = "Wicked Wikkets",
          coord = { map = 371, x = 0.281, y = 0.389 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29924, text = "Kill Kher Shan (objective 1)",
          coord = { map = 371, x = 0.333, y = 0.416 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29924, text = "Turn in: Kill Kher Shan",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 31241, text = "Wicked Wikkets (objective 1)",
          coord = { map = 371, x = 0.308, y = 0.414 } },  -- APR route coord (converted)
        { type = "quest", questID = 29933, text = "The Bees' Knees (objective 1)",
          coord = { map = 371, x = 0.297, y = 0.446 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29933, text = "Turn in: The Bees' Knees",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29935, text = "Turn in: Orders are Orders",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- APR route coord (converted)
        { type = "accept", questID = 29936, text = "Instant Messaging",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 31241, text = "Turn in: Wicked Wikkets",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31261, text = "Turn in: Captain Jack's Dead",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- APR route coord (converted)
        { type = "quest", questID = 29936, text = "Instant Messaging (objective 1)",
          coord = { map = 371, x = 0.279, y = 0.468 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29936, text = "Turn in: Instant Messaging",
          coord = { map = 371, x = 0.282, y = 0.477 } },  -- APR route coord (converted)
        { type = "accept", questID = 29941, text = "Beyond the Horizon",
          coord = { map = 371, x = 0.282, y = 0.477 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29941, text = "Beyond the Horizon (objective 1)",
          coord = { map = 371, x = 0.283, y = 0.469 } },  -- APR route coord (converted)
        { type = "quest", questID = 29941, text = "Beyond the Horizon (objective 4)",
          coord = { map = 371, x = 0.279, y = 0.472 } },  -- APR route coord (converted)
        { type = "quest", questID = 29941, text = "Beyond the Horizon (objective 3)",
          coord = { map = 371, x = 0.270, y = 0.490 } },  -- APR route coord (converted)
        { type = "quest", questID = 29941, text = "Beyond the Horizon (objective 2)",
          coord = { map = 371, x = 0.272, y = 0.506 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29941, text = "Turn in: Beyond the Horizon",
          coord = { map = 371, x = 0.282, y = 0.477 } },  -- APR route coord (converted)
        { type = "accept", questID = 29937, text = "Furious Fowl",
          coord = { map = 371, x = 0.282, y = 0.477 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31239, text = "What's in a Name Name?",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29937, text = "Furious Fowl (objective 1)",
          coord = { map = 371, x = 0.302, y = 0.496 } },  -- APR route coord (converted)
        { type = "quest", questID = 31239, text = "What's in a Name Name? (objective 1)",
          coord = { map = 371, x = 0.308, y = 0.472 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31239, text = "Turn in: What's in a Name Name?",
          coord = { map = 371, x = 0.279, y = 0.471 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29937, text = "Turn in: Furious Fowl",
          coord = { map = 371, x = 0.272, y = 0.508 } },  -- APR route coord (converted)
        { type = "accept", questID = 29939, text = "Boom Bait",
          coord = { map = 371, x = 0.272, y = 0.507 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29942, text = "Silly Wikket, Slickies are for Hozen",
          coord = { map = 371, x = 0.270, y = 0.508 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29939, text = "Boom Bait (objective 1)",
          coord = { map = 371, x = 0.267, y = 0.554 } },  -- APR route coord (converted)
        { type = "quest", questID = 29942, text = "Silly Wikket, Slickies are for Hozen (objective 1)",
          coord = { map = 371, x = 0.267, y = 0.554 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29942, text = "Turn in: Silly Wikket, Slickies are for Hozen",
          coord = { map = 371, x = 0.270, y = 0.508 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29939, text = "Turn in: Boom Bait",
          coord = { map = 371, x = 0.272, y = 0.508 } },  -- APR route coord (converted)
        { type = "accept", questID = 29971, text = "The Scouts Return",
          coord = { map = 371, x = 0.272, y = 0.507 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29971, text = "Turn in: The Scouts Return",
          coord = { map = 371, x = 0.286, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 29730, text = "Scouting Report: Hostile Natives",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29730, text = "Scouting Report: Hostile Natives (objective 1)",
          coord = { map = 371, x = 0.383, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest", questID = 29730, text = "Scouting Report: Hostile Natives (objective 2)",
          coord = { map = 371, x = 0.389, y = 0.460 } },  -- APR route coord (converted)
        { type = "quest", questID = 29730, text = "Scouting Report: Hostile Natives (objective 3)",
          coord = { map = 371, x = 0.392, y = 0.462 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29730, text = "Turn in: Scouting Report: Hostile Natives",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- APR route coord (converted)
        { type = "accept", questID = 29731, text = "Scouting Report: On the Right Track",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29731, text = "Scouting Report: On the Right Track (objective 1)",
          coord = { map = 371, x = 0.486, y = 0.603 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29731, text = "Turn in: Scouting Report: On the Right Track",
          coord = { map = 371, x = 0.286, y = 0.475 } },  -- APR route coord (converted)
        { type = "accept", questID = 29823, text = "Scouting Report: The Friend of My Enemy",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29823, text = "Scouting Report: The Friend of My Enemy (objective 1)",
          coord = { map = 371, x = 0.498, y = 0.705 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29823, text = "Turn in: Scouting Report: The Friend of My Enemy",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- APR route coord (converted)
        { type = "accept", questID = 29824, text = "Scouting Report: Like Jinyu in a Barrel",
          coord = { map = 371, x = 0.286, y = 0.473 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29824, text = "Scouting Report: Like Jinyu in a Barrel (objective 1)",
          coord = { map = 371, x = 0.625, y = 0.821 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29824, text = "Turn in: Scouting Report: Like Jinyu in a Barrel",
          coord = { map = 371, x = 0.286, y = 0.474 } },  -- APR route coord (converted)
        { type = "accept", questID = 29943, text = "Guerrillas in our Midst",
          coord = { map = 371, x = 0.286, y = 0.475 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29968, text = "Green-ish Energy",
          coord = { map = 371, x = 0.307, y = 0.522 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29943, text = "Guerrillas in our Midst (objective 1)",
          coord = { map = 371, x = 0.301, y = 0.522 } },  -- APR route coord (converted)
        { type = "quest", questID = 29968, text = "Green-ish Energy (objective 1)",
          coord = { map = 371, x = 0.301, y = 0.522 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29943, text = "Turn in: Guerrillas in our Midst",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29966, text = "Burning Down the House",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 29966, text = "Burning Down the House (objective 1)",
          coord = { map = 371, x = 0.295, y = 0.540 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29966, text = "Turn in: Burning Down the House",
          coord = { map = 371, x = 0.286, y = 0.475 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29968, text = "Turn in: Green-ish Energy",
          coord = { map = 371, x = 0.272, y = 0.507 } },  -- APR route coord (converted)
        { type = "accept", questID = 29967, text = "Boom Goes the Doonamite!",
          coord = { map = 371, x = 0.272, y = 0.507 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29967, text = "Boom Goes the Doonamite! (objective 1)",
          coord = { map = 371, x = 0.289, y = 0.492 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29967, text = "Turn in: Boom Goes the Doonamite!",
          coord = { map = 371, x = 0.289, y = 0.491 } },  -- APR route coord (converted)
        { type = "accept", questID = 30015, text = "Dawn's Blossom",
          coord = { map = 371, x = 0.286, y = 0.475 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 30015, text = "Turn in: Dawn's Blossom",
          coord = { map = 371, x = 0.468, y = 0.461 } },  -- APR route coord (converted)
        { type = "accept", questID = 31230, text = "Welcome to Dawn's Blossom",
          coord = { map = 371, x = 0.471, y = 0.461 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31230, text = "Welcome to Dawn's Blossom (objective 3)",
          coord = { map = 371, x = 0.466, y = 0.458 } },  -- APR route coord (converted)
        { type = "quest", questID = 31230, text = "Welcome to Dawn's Blossom (objective 2)",
          coord = { map = 371, x = 0.457, y = 0.437 } },  -- APR route coord (converted)
        { type = "accept", questID = 32018, text = "His Name Was... Stormstout",
          coord = { map = 371, x = 0.457, y = 0.439 } },  -- APR route coord (converted)
        { type = "quest", questID = 31230, text = "Welcome to Dawn's Blossom (objective 1)",
          coord = { map = 371, x = 0.484, y = 0.445 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31230, text = "Turn in: Welcome to Dawn's Blossom",
          coord = { map = 371, x = 0.471, y = 0.461 } },  -- APR route coord (converted)
        { type = "accept", questID = 29716, text = "The Double Hozen Dare",
          coord = { map = 371, x = 0.466, y = 0.461 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29717, text = "Down Kitty!",
          coord = { map = 371, x = 0.466, y = 0.461 } },  -- APR route coord (converted)
        { type = "accept", questID = 29865, text = "The Silkwood Road",
          coord = { map = 371, x = 0.464, y = 0.458 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29866, text = "The Threads that Stick",
          coord = { map = 371, x = 0.466, y = 0.453 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29865, text = "The Silkwood Road (objective 1)",
          coord = { map = 371, x = 0.436, y = 0.490 } },  -- APR route coord (converted)
        { type = "quest", questID = 29866, text = "The Threads that Stick (objective 1)",
          coord = { map = 371, x = 0.436, y = 0.490 } },  -- APR route coord (converted)
        { type = "quest", questID = 29716, text = "The Double Hozen Dare (objective 1)",
          coord = { map = 371, x = 0.374, y = 0.464 } },  -- APR route coord (converted)
        { type = "quest", questID = 29717, text = "Down Kitty! (objective 1)",
          coord = { map = 371, x = 0.374, y = 0.464 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29716, text = "Turn in: The Double Hozen Dare",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 29717, text = "Turn in: Down Kitty!",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29723, text = "The Jade Witch",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 29723, text = "The Jade Witch (objective 1)",
          coord = { map = 371, x = 0.397, y = 0.463 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29865, text = "Turn in: The Silkwood Road",
          coord = { map = 371, x = 0.464, y = 0.458 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29866, text = "Turn in: The Threads that Stick",
          coord = { map = 371, x = 0.466, y = 0.453 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29723, text = "Turn in: The Jade Witch",
          coord = { map = 371, x = 0.464, y = 0.442 } },  -- APR route coord (converted)
        { type = "accept", questID = 29993, text = "Find the Boy",
          coord = { map = 371, x = 0.471, y = 0.460 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29925, text = "All We Can Spare",
          coord = { map = 371, x = 0.471, y = 0.461 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29576, text = "An Air of Worry",
          coord = { map = 371, x = 0.483, y = 0.460 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29617, text = "Tian Monastery",
          coord = { map = 371, x = 0.496, y = 0.458 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29881, text = "The Perfect Color",
          coord = { map = 371, x = 0.548, y = 0.453 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29993, text = "Turn in: Find the Boy",
          coord = { map = 371, x = 0.546, y = 0.441 } },  -- APR route coord (converted)
        { type = "accept", questID = 29995, text = "Shrine of the Dawn",
          coord = { map = 371, x = 0.546, y = 0.441 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29882, text = "Quill of Stingers",
          coord = { map = 371, x = 0.553, y = 0.453 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29881, text = "The Perfect Color (objective 1)",
          coord = { map = 371, x = 0.531, y = 0.442 } },  -- APR route coord (converted)
        { type = "quest", questID = 29882, text = "Quill of Stingers (objective 1)",
          coord = { map = 371, x = 0.531, y = 0.442 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29882, text = "Turn in: Quill of Stingers",
          coord = { map = 371, x = 0.553, y = 0.452 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29881, text = "Turn in: The Perfect Color",
          coord = { map = 371, x = 0.548, y = 0.453 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29995, text = "Turn in: Shrine of the Dawn",
          coord = { map = 371, x = 0.525, y = 0.381 } },  -- APR route coord (converted)
        { type = "accept", questID = 29920, text = "Getting Permission",
          coord = { map = 371, x = 0.525, y = 0.381 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29920, text = "Getting Permission (objective 2)",
          coord = { map = 371, x = 0.540, y = 0.384 } },  -- APR route coord (converted)
        { type = "quest", questID = 29920, text = "Getting Permission (objective 3)",
          coord = { map = 371, x = 0.535, y = 0.367 } },  -- APR route coord (converted)
        { type = "quest", questID = 29920, text = "Getting Permission (objective 1)",
          coord = { map = 371, x = 0.525, y = 0.355 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29920, text = "Turn in: Getting Permission",
          coord = { map = 371, x = 0.525, y = 0.381 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29925, text = "Turn in: All We Can Spare",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- APR route coord (converted)
        { type = "accept", questID = 29928, text = "I Have No Jade And I Must Scream",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29928, text = "I Have No Jade And I Must Scream (objective 1)",
          coord = { map = 371, x = 0.483, y = 0.320 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29928, text = "Turn in: I Have No Jade And I Must Scream",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- APR route coord (converted)
        { type = "accept", questID = 29926, text = "Calamity Jade",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29927, text = "Mann's Man",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29927, text = "Mann's Man (objective 1)",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 29927, text = "Turn in: Mann's Man",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29929, text = "Trapped!",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 29926, text = "Calamity Jade (objective 1,2)",
          coord = nil },  -- no verified coord
        { type = "quest", questID = 29929, text = "Trapped! (objective 1)",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 29929, text = "Turn in: Trapped!",
          coord = { map = 371, x = 0.462, y = 0.293 } },  -- APR route coord (converted)
        { type = "accept", questID = 29930, text = "What's Mined Is Yours",
          coord = { map = 371, x = 0.463, y = 0.294 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29930, text = "What's Mined Is Yours (objective 1)",
          coord = { map = 371, x = 0.462, y = 0.293 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29926, text = "Turn in: Calamity Jade",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29930, text = "Turn in: What's Mined Is Yours",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- APR route coord (converted)
        { type = "accept", questID = 29931, text = "The Serpent's Heart",
          coord = { map = 371, x = 0.509, y = 0.270 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29745, text = "The Sprites' Plight",
          coord = { map = 371, x = 0.486, y = 0.249 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29745, text = "The Sprites' Plight (objective 2)",
          coord = { map = 371, x = 0.491, y = 0.212 } },  -- APR route coord (converted)
        { type = "quest", questID = 29745, text = "The Sprites' Plight (objective 1)",
          coord = { map = 371, x = 0.490, y = 0.217 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29745, text = "Turn in: The Sprites' Plight",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29747, text = "Break the Cycle",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29748, text = "Simulacrumble",
          coord = { map = 371, x = 0.485, y = 0.205 } },  -- APR route coord (converted)
        { type = "quest", questID = 29747, text = "Break the Cycle (objective 1)",
          coord = { map = 371, x = 0.486, y = 0.204 } },  -- APR route coord (converted)
        { type = "quest", questID = 29748, text = "Simulacrumble (objective 1)",
          coord = { map = 371, x = 0.486, y = 0.204 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29747, text = "Turn in: Break the Cycle",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 29748, text = "Turn in: Simulacrumble",
          coord = nil },  -- no verified coord
        { type = "accept", questID = 29749, text = "An Urgent Plea",
          coord = { map = 371, x = 0.442, y = 0.149 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29749, text = "An Urgent Plea (objective 1)",
          coord = { map = 371, x = 0.442, y = 0.149 } },  -- APR route coord (converted)
        { type = "quest", questID = 29749, text = "An Urgent Plea (objective 2)",
          coord = { map = 371, x = 0.443, y = 0.154 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29749, text = "Turn in: An Urgent Plea",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "accept", questID = 29751, text = "Ritual Artifacts",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29750, text = "Vessels of the Spirit",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29752, text = "The Wayward Dead",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29751, text = "Ritual Artifacts (objective 1)",
          coord = { map = 371, x = 0.425, y = 0.157 } },  -- APR route coord (converted)
        { type = "quest", questID = 29751, text = "Ritual Artifacts (objective 2)",
          coord = { map = 371, x = 0.416, y = 0.143 } },  -- APR route coord (converted)
        { type = "quest", questID = 29751, text = "Ritual Artifacts (objective 3)",
          coord = { map = 371, x = 0.422, y = 0.170 } },  -- APR route coord (converted)
        { type = "quest", questID = 29750, text = "Vessels of the Spirit (objective 1)",
          coord = { map = 371, x = 0.417, y = 0.149 } },  -- APR route coord (converted)
        { type = "quest", questID = 29752, text = "The Wayward Dead (objective 1)",
          coord = { map = 371, x = 0.417, y = 0.149 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29750, text = "Turn in: Vessels of the Spirit",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29751, text = "Turn in: Ritual Artifacts",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29752, text = "Turn in: The Wayward Dead",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "accept", questID = 29753, text = "Back to Nature",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29756, text = "A Humble Offering",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29753, text = "Back to Nature (objective 1)",
          coord = { map = 371, x = 0.389, y = 0.109 } },  -- APR route coord (converted)
        { type = "quest", questID = 29756, text = "A Humble Offering (objective 1)",
          coord = { map = 371, x = 0.389, y = 0.109 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29753, text = "Turn in: Back to Nature",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29756, text = "Turn in: A Humble Offering",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- APR route coord (converted)
        { type = "accept", questID = 29754, text = "To Bridge Earth and Sky",
          coord = { map = 371, x = 0.442, y = 0.150 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29754, text = "To Bridge Earth and Sky (objective 1)",
          coord = { map = 371, x = 0.438, y = 0.125 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29754, text = "Turn in: To Bridge Earth and Sky",
          coord = { map = 371, x = 0.438, y = 0.125 } },  -- APR route coord (converted)
        { type = "accept", questID = 29755, text = "Pei-Back",
          coord = { map = 371, x = 0.438, y = 0.125 } },  -- APR route coord (converted)
        { type = "quest", questID = 29755, text = "Pei-Back (objective 1)",
          coord = { map = 371, x = 0.425, y = 0.104 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29755, text = "Turn in: Pei-Back",
          coord = { map = 371, x = 0.438, y = 0.125 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29617, text = "Turn in: Tian Monastery",
          coord = { map = 371, x = 0.449, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 29618, text = "The High Elder",
          coord = { map = 371, x = 0.449, y = 0.249 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29618, text = "Turn in: The High Elder",
          coord = { map = 371, x = 0.452, y = 0.250 } },  -- APR route coord (converted)
        { type = "accept", questID = 29619, text = "A Courteous Guest",
          coord = { map = 371, x = 0.449, y = 0.249 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29619, text = "A Courteous Guest (objective 1)",
          coord = { map = 371, x = 0.458, y = 0.275 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29619, text = "Turn in: A Courteous Guest",
          coord = { map = 371, x = 0.450, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 29620, text = "The Great Banquet",
          coord = { map = 371, x = 0.449, y = 0.249 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29620, text = "The Great Banquet (objective 1)",
          coord = { map = 371, x = 0.427, y = 0.231 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29620, text = "Turn in: The Great Banquet",
          coord = { map = 371, x = 0.427, y = 0.231 } },  -- APR route coord (converted)
        { type = "accept", questID = 29622, text = "Your Training Starts Now",
          coord = { map = 371, x = 0.431, y = 0.236 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29626, text = "Groundskeeper Wu",
          coord = { map = 371, x = 0.431, y = 0.236 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29632, text = "Becoming Battle-Ready",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29632, text = "Becoming Battle-Ready (objective 1)",
          coord = { map = 371, x = 0.432, y = 0.251 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29632, text = "Turn in: Becoming Battle-Ready",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- APR route coord (converted)
        { type = "accept", questID = 29633, text = "Zhi-Zhi, the Dextrous",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29634, text = "Husshun, the Wizened",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29633, text = "Zhi-Zhi, the Dextrous (objective 1)",
          coord = { map = 371, x = 0.430, y = 0.260 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29626, text = "Turn in: Groundskeeper Wu",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "accept", questID = 29627, text = "A Proper Weapon",
          coord = { map = 371, x = 0.416, y = 0.236 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29627, text = "A Proper Weapon (objective 2)",
          coord = { map = 371, x = 0.414, y = 0.241 } },  -- APR route coord (converted)
        { type = "quest", questID = 29627, text = "A Proper Weapon (objective 3)",
          coord = { map = 371, x = 0.417, y = 0.246 } },  -- APR route coord (converted)
        { type = "quest", questID = 29627, text = "A Proper Weapon (objective 1)",
          coord = { map = 371, x = 0.415, y = 0.245 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29627, text = "Turn in: A Proper Weapon",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "accept", questID = 29628, text = "A Strong Back",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29629, text = "A Steady Hand",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29630, text = "And a Heavy Fist",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29631, text = "Burning Bright",
          coord = { map = 371, x = 0.380, y = 0.237 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29629, text = "A Steady Hand (objective 1)",
          coord = { map = 371, x = 0.343, y = 0.207 } },  -- APR route coord (converted)
        { type = "quest", questID = 29631, text = "Burning Bright (objective 1)",
          coord = { map = 371, x = 0.343, y = 0.207 } },  -- APR route coord (converted)
        { type = "quest", questID = 29628, text = "A Strong Back (objective 1)",
          coord = { map = 371, x = 0.377, y = 0.175 } },  -- APR route coord (converted)
        { type = "quest", questID = 29630, text = "And a Heavy Fist (objective 1)",
          coord = { map = 371, x = 0.378, y = 0.222 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29631, text = "Turn in: Burning Bright",
          coord = { map = 371, x = 0.380, y = 0.237 } },  -- APR route coord (converted)
        { type = "quest", questID = 29628, text = "A Strong Back (objective 2)",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29628, text = "Turn in: A Strong Back",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29629, text = "Turn in: A Steady Hand",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29630, text = "Turn in: And a Heavy Fist",
          coord = { map = 371, x = 0.416, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29622, text = "Turn in: Your Training Starts Now",
          coord = { map = 371, x = 0.416, y = 0.283 } },  -- APR route coord (converted)
        { type = "accept", questID = 29623, text = "Perfection",
          coord = { map = 371, x = 0.416, y = 0.283 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29623, text = "Perfection (objective 1)",
          coord = { map = 371, x = 0.413, y = 0.274 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29623, text = "Turn in: Perfection",
          coord = { map = 371, x = 0.416, y = 0.283 } },  -- APR route coord (converted)
        { type = "accept", questID = 29624, text = "Attention",
          coord = { map = 371, x = 0.416, y = 0.283 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29624, text = "Attention (objective 1)",
          coord = { map = 371, x = 0.410, y = 0.269 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29624, text = "Turn in: Attention",
          coord = { map = 371, x = 0.416, y = 0.283 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29633, text = "Turn in: Zhi-Zhi, the Dextrous",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- APR route coord (converted)
        { type = "quest", questID = 29634, text = "Husshun, the Wizened (objective 1)",
          coord = { map = 371, x = 0.445, y = 0.240 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29634, text = "Turn in: Husshun, the Wizened",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- APR route coord (converted)
        { type = "accept", questID = 29635, text = "Xiao, the Eater",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29635, text = "Xiao, the Eater (objective 1)",
          coord = { map = 371, x = 0.431, y = 0.236 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29635, text = "Turn in: Xiao, the Eater",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- APR route coord (converted)
        { type = "accept", questID = 29636, text = "A Test of Endurance",
          coord = { map = 371, x = 0.432, y = 0.247 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29636, text = "Turn in: A Test of Endurance",
          coord = { map = 371, x = 0.389, y = 0.240 } },  -- APR route coord (converted)
        { type = "accept", questID = 29637, text = "The Rumpus",
          coord = { map = 371, x = 0.389, y = 0.240 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29637, text = "The Rumpus (objective 1)",
          coord = { map = 371, x = 0.389, y = 0.231 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29637, text = "Turn in: The Rumpus",
          coord = { map = 371, x = 0.389, y = 0.240 } },  -- APR route coord (converted)
        { type = "accept", questID = 29647, text = "Flying Colors",
          coord = { map = 371, x = 0.389, y = 0.240 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29647, text = "Turn in: Flying Colors",
          coord = { map = 371, x = 0.427, y = 0.231 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29576, text = "Turn in: An Air of Worry",
          coord = { map = 371, x = 0.435, y = 0.759 } },  -- APR route coord (converted)
        { type = "accept", questID = 29578, text = "Defiance",
          coord = { map = 371, x = 0.434, y = 0.759 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29579, text = "Rally the Survivors",
          coord = { map = 371, x = 0.434, y = 0.759 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29580, text = "Orchard-Supplied Hardware",
          coord = { map = 371, x = 0.432, y = 0.760 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29585, text = "Spitfire",
          coord = { map = 371, x = 0.432, y = 0.760 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29580, text = "Orchard-Supplied Hardware (objective 1)",
          coord = { map = 371, x = 0.440, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest", questID = 29578, text = "Defiance (objective 1,2)",
          coord = { map = 371, x = 0.440, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest", questID = 29579, text = "Rally the Survivors (objective 1)",
          coord = { map = 371, x = 0.440, y = 0.751 } },  -- APR route coord (converted)
        { type = "quest", questID = 29585, text = "Spitfire (objective 1)",
          coord = { map = 371, x = 0.440, y = 0.751 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29578, text = "Turn in: Defiance",
          coord = { map = 371, x = 0.435, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29579, text = "Turn in: Rally the Survivors",
          coord = { map = 371, x = 0.435, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29585, text = "Turn in: Spitfire",
          coord = { map = 371, x = 0.432, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29580, text = "Turn in: Orchard-Supplied Hardware",
          coord = { map = 371, x = 0.432, y = 0.759 } },  -- APR route coord (converted)
        { type = "accept", questID = 29586, text = "The Splintered Path",
          coord = { map = 371, x = 0.432, y = 0.759 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29586, text = "The Splintered Path (objective 1)",
          coord = { map = 371, x = 0.407, y = 0.741 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29586, text = "Turn in: The Splintered Path",
          coord = { map = 371, x = 0.409, y = 0.739 } },  -- APR route coord (converted)
        { type = "accept", questID = 29587, text = "Unbound",
          coord = { map = 371, x = 0.410, y = 0.739 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29670, text = "Maul Gormal",
          coord = { map = 371, x = 0.410, y = 0.739 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29670, text = "Maul Gormal (objective 1)",
          coord = { map = 371, x = 0.378, y = 0.763 } },  -- APR route coord (converted)
        { type = "quest", questID = 29587, text = "Unbound (objective 1)",
          coord = { map = 371, x = 0.395, y = 0.750 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29587, text = "Turn in: Unbound",
          coord = { map = 371, x = 0.409, y = 0.739 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29670, text = "Turn in: Maul Gormal",
          coord = { map = 371, x = 0.409, y = 0.739 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29931, text = "Turn in: The Serpent's Heart",
          coord = { map = 371, x = 0.483, y = 0.613 } },  -- APR route coord (converted)
        { type = "accept", questID = 30495, text = "Love's Labor",
          coord = { map = 371, x = 0.483, y = 0.613 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30495, text = "Love's Labor (objective 3)",
          coord = { map = 371, x = 0.481, y = 0.600 } },  -- APR route coord (converted)
        { type = "quest", questID = 30495, text = "Love's Labor (objective 4)",
          coord = { map = 371, x = 0.475, y = 0.606 } },  -- APR route coord (converted)
        { type = "quest", questID = 30495, text = "Love's Labor (objective 2)",
          coord = { map = 371, x = 0.469, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest", questID = 30495, text = "Love's Labor (objective 1)",
          coord = { map = 371, x = 0.463, y = 0.618 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30495, text = "Turn in: Love's Labor",
          coord = { map = 371, x = 0.483, y = 0.613 } },  -- APR route coord (converted)
        { type = "accept", questID = 29932, text = "The Temple of the Jade Serpent",
          coord = { map = 371, x = 0.483, y = 0.613 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29932, text = "The Temple of the Jade Serpent (objective 1)",
          coord = { map = 371, x = 0.558, y = 0.570 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29932, text = "Turn in: The Temple of the Jade Serpent",
          coord = { map = 371, x = 0.581, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 29997, text = "The Scryer's Dilemma",
          coord = { map = 371, x = 0.581, y = 0.586 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29998, text = "The Librarian's Quandary",
          coord = { map = 371, x = 0.581, y = 0.586 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29999, text = "The Rider's Bind",
          coord = { map = 371, x = 0.580, y = 0.590 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30005, text = "Lighting Up the Sky",
          coord = { map = 371, x = 0.580, y = 0.590 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29999, text = "The Rider's Bind (objective 3)",
          coord = { map = 371, x = 0.565, y = 0.584 } },  -- APR route coord (converted)
        { type = "quest", questID = 29999, text = "The Rider's Bind (objective 1)",
          coord = { map = 371, x = 0.591, y = 0.567 } },  -- APR route coord (converted)
        { type = "quest", questID = 29999, text = "The Rider's Bind (objective 2)",
          coord = { map = 371, x = 0.581, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29998, text = "Turn in: The Librarian's Quandary",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- APR route coord (converted)
        { type = "accept", questID = 30001, text = "Moth-Ridden",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30002, text = "Pages of History",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29999, text = "The Rider's Bind (objective 4)",
          coord = { map = 371, x = 0.559, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest", questID = 30001, text = "Moth-Ridden (objective 1)",
          coord = { map = 371, x = 0.561, y = 0.600 } },  -- APR route coord (converted)
        { type = "quest", questID = 30002, text = "Pages of History (objective 1)",
          coord = { map = 371, x = 0.561, y = 0.600 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30001, text = "Turn in: Moth-Ridden",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30002, text = "Turn in: Pages of History",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- APR route coord (converted)
        { type = "accept", questID = 30004, text = "Everything In Its Place",
          coord = { map = 371, x = 0.562, y = 0.604 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29997, text = "The Scryer's Dilemma (objective 1)",
          coord = { map = 371, x = 0.571, y = 0.558 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29997, text = "Turn in: The Scryer's Dilemma",
          coord = { map = 371, x = 0.575, y = 0.560 } },  -- APR route coord (converted)
        { type = "accept", questID = 30011, text = "A New Vision",
          coord = { map = 371, x = 0.575, y = 0.560 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30005, text = "Lighting Up the Sky (objective 1)",
          coord = { map = 371, x = 0.573, y = 0.584 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30004, text = "Turn in: Everything In Its Place",
          coord = { map = 371, x = 0.581, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30011, text = "Turn in: A New Vision",
          coord = { map = 371, x = 0.581, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29999, text = "Turn in: The Rider's Bind",
          coord = { map = 371, x = 0.580, y = 0.590 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30005, text = "Turn in: Lighting Up the Sky",
          coord = { map = 371, x = 0.580, y = 0.590 } },  -- APR route coord (converted)
        { type = "accept", questID = 30000, text = "The Jade Serpent",
          coord = { map = 371, x = 0.580, y = 0.590 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30000, text = "The Jade Serpent (objective 1)",
          coord = { map = 371, x = 0.516, y = 0.581 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30000, text = "Turn in: The Jade Serpent",
          coord = { map = 371, x = 0.558, y = 0.571 } },  -- APR route coord (converted)
        { type = "accept", questID = 30499, text = "Get Back Here!",
          coord = { map = 371, x = 0.558, y = 0.570 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 30499, text = "Turn in: Get Back Here!",
          coord = { map = 371, x = 0.280, y = 0.472 } },  -- APR route coord (converted)
        { type = "accept", questID = 30484, text = "Gauging Our Progress",
          coord = { map = 371, x = 0.280, y = 0.471 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30466, text = "Sufficient Motivation",
          coord = { map = 371, x = 0.280, y = 0.471 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30466, text = "Sufficient Motivation (objective 2)",
          coord = { map = 371, x = 0.281, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest", questID = 30484, text = "Gauging Our Progress (objective 2)",
          coord = { map = 371, x = 0.284, y = 0.478 } },  -- APR route coord (converted)
        { type = "quest", questID = 30484, text = "Gauging Our Progress (objective 1)",
          coord = { map = 371, x = 0.291, y = 0.509 } },  -- APR route coord (converted)
        { type = "quest", questID = 30484, text = "Gauging Our Progress (objective 3)",
          coord = { map = 371, x = 0.284, y = 0.519 } },  -- APR route coord (converted)
        { type = "quest", questID = 30484, text = "Gauging Our Progress (objective 4)",
          coord = { map = 371, x = 0.270, y = 0.549 } },  -- APR route coord (converted)
        { type = "quest", questID = 30466, text = "Sufficient Motivation (objective 1)",
          coord = { map = 371, x = 0.285, y = 0.474 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30466, text = "Turn in: Sufficient Motivation",
          coord = { map = 371, x = 0.280, y = 0.471 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30484, text = "Turn in: Gauging Our Progress",
          coord = { map = 371, x = 0.280, y = 0.471 } },  -- APR route coord (converted)
        { type = "accept", questID = 30485, text = "Last Piece of the Puzzle",
          coord = { map = 371, x = 0.282, y = 0.467 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30485, text = "Last Piece of the Puzzle (objective 1)",
          coord = { map = 371, x = 0.445, y = 0.669 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30485, text = "Turn in: Last Piece of the Puzzle",
          coord = { map = 371, x = 0.447, y = 0.671 } },  -- APR route coord (converted)
        { type = "accept", questID = 31303, text = "The Seal is Broken",
          coord = { map = 371, x = 0.447, y = 0.670 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31303, text = "The Seal is Broken (objective 1)",
          coord = { map = 371, x = 0.447, y = 0.670 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31303, text = "Turn in: The Seal is Broken",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- APR route coord (converted)
        { type = "accept", questID = 30500, text = "Residual Fallout",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30502, text = "Jaded Heart",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30504, text = "Emergency Response",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30504, text = "Emergency Response (objective 1)",
          coord = { map = 371, x = 0.481, y = 0.618 } },  -- APR route coord (converted)
        { type = "quest", questID = 30504, text = "Emergency Response (objective 2)",
          coord = { map = 371, x = 0.472, y = 0.625 } },  -- APR route coord (converted)
        { type = "quest", questID = 30504, text = "Emergency Response (objective 3)",
          coord = { map = 371, x = 0.468, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest", questID = 30504, text = "Emergency Response (objective 4)",
          coord = { map = 371, x = 0.480, y = 0.591 } },  -- APR route coord (converted)
        { type = "quest", questID = 30500, text = "Residual Fallout (objective 1)",
          coord = { map = 371, x = 0.490, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest", questID = 30502, text = "Jaded Heart (objective 1)",
          coord = { map = 371, x = 0.490, y = 0.616 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30500, text = "Turn in: Residual Fallout",
          coord = { map = 371, x = 0.493, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30502, text = "Turn in: Jaded Heart",
          coord = { map = 371, x = 0.493, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30504, text = "Turn in: Emergency Response",
          coord = { map = 371, x = 0.493, y = 0.614 } },  -- APR route coord (converted)
        { type = "accept", questID = 30648, text = "Moving On",
          coord = { map = 371, x = 0.493, y = 0.614 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30648, text = "Moving On (objective 1)",
          coord = { map = 371, x = 0.493, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30648, text = "Turn in: Moving On",
          coord = nil },  -- no verified coord
        { type = "turnin", questID = 32018, text = "Turn in: His Name Was... Stormstout",
          coord = nil },  -- no verified coord
    },
}
