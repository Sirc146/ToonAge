-- ToonAge guide data: MoP Classic (5.5.x): The Jade Forest (Alliance)
-- Generated 2026-10-08. Format: { type, questID, text, [class], [faction], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- uiMapID 371 (The Jade Forest); MoP-era uiMapIDs are shared by Retail and MoP Classic.
--
-- SOURCES / VERIFICATION
--  * Quest ORDER: APR Retail route "371-The Jade Forest - A" (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, Routes/MistsOfPandaria).
--    This is a RETAIL route used as a proxy; MoP Classic quest flow is the original 5.x flow and may differ in places.
--  * Every questID below EXISTS in MoP Classic: verified via Wowhead MoP Classic tooltip API
--    (nether.wowhead.com/mop-classic/tooltip/quest/<id>), and the text is the MoP Classic quest name.
--    Dropped as not in MoP Classic: none
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

TA.GuideData["mists_jade_forest_alliance"] = {
    coordsEstimated = true, -- converted from another map; spot-check in game
    id = "mists_jade_forest_alliance", title = "The Jade Forest (Alliance)", client = "mists", faction = "Alliance", zone = 371,
    nextGuide = nil, -- next: Valley of the Four Winds
    steps = {
        { type = "accept", questID = 31732, text = "Unleash Hell",
          coord = { map = 371, x = 0.420, y = 0.928 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31732, text = "Unleash Hell (objective 1,2,3,4)",
          coord = { map = 371, x = 0.420, y = 0.925 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31732, text = "Turn in: Unleash Hell",
          coord = { map = 371, x = 0.420, y = 0.927 } },  -- APR route coord (converted)
        { type = "accept", questID = 31733, text = "Touching Ground",
          coord = { map = 371, x = 0.420, y = 0.928 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31733, text = "Touching Ground (objective 1)",
          coord = { map = 371, x = 0.423, y = 0.928 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31733, text = "Turn in: Touching Ground",
          coord = { map = 371, x = 0.435, y = 0.907 } },  -- APR route coord (converted)
        { type = "accept", questID = 30069, text = "No Plan Survives Contact with the Enemy",
          coord = { map = 371, x = 0.436, y = 0.907 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31734, text = "Welcome Wagons",
          coord = { map = 371, x = 0.436, y = 0.907 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30069, text = "No Plan Survives Contact with the Enemy (objective 1,2)",
          coord = { map = 371, x = 0.448, y = 0.939 } },  -- APR route coord (converted)
        { type = "quest", questID = 31734, text = "Welcome Wagons (objective 1)",
          coord = { map = 371, x = 0.448, y = 0.939 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30069, text = "Turn in: No Plan Survives Contact with the Enemy",
          coord = { map = 371, x = 0.451, y = 0.950 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31734, text = "Turn in: Welcome Wagons",
          coord = { map = 371, x = 0.451, y = 0.950 } },  -- APR route coord (converted)
        { type = "accept", questID = 31735, text = "The Right Tool For The Job",
          coord = { map = 371, x = 0.452, y = 0.950 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31735, text = "The Right Tool For The Job (objective 1)",
          coord = { map = 371, x = 0.455, y = 0.952 } },  -- APR route coord (converted)
        { type = "quest", questID = 31735, text = "The Right Tool For The Job (objective 2)",
          coord = { map = 371, x = 0.459, y = 0.958 } },  -- APR route coord (converted)
        { type = "quest", questID = 31735, text = "The Right Tool For The Job (objective 3)",
          coord = { map = 371, x = 0.464, y = 0.964 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31735, text = "Turn in: The Right Tool For The Job",
          coord = { map = 371, x = 0.464, y = 0.963 } },  -- APR route coord (converted)
        { type = "accept", questID = 31736, text = "Envoy of the Alliance",
          coord = { map = 371, x = 0.464, y = 0.963 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31737, text = "The Cost of War",
          coord = { map = 371, x = 0.464, y = 0.963 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31737, text = "The Cost of War (objective 1,2)",
          coord = { map = 371, x = 0.444, y = 0.938 } },  -- APR route coord (converted)
        { type = "quest", questID = 31736, text = "Envoy of the Alliance (objective 1)",
          coord = { map = 371, x = 0.458, y = 0.850 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31736, text = "Turn in: Envoy of the Alliance",
          coord = { map = 371, x = 0.462, y = 0.847 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31737, text = "Turn in: The Cost of War",
          coord = { map = 371, x = 0.462, y = 0.847 } },  -- APR route coord (converted)
        { type = "accept", questID = 31738, text = "Pillaging Peons",
          coord = { map = 371, x = 0.462, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31739, text = "Priorities!",
          coord = { map = 371, x = 0.461, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29552, text = "Critical Condition",
          coord = { map = 371, x = 0.460, y = 0.846 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31738, text = "Pillaging Peons (objective 1)",
          coord = { map = 371, x = 0.425, y = 0.878 } },  -- APR route coord (converted)
        { type = "quest", questID = 29552, text = "Critical Condition (objective 1)",
          coord = { map = 371, x = 0.425, y = 0.878 } },  -- APR route coord (converted)
        { type = "quest", questID = 31739, text = "Priorities! (objective 1)",
          coord = { map = 371, x = 0.425, y = 0.878 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31739, text = "Turn in: Priorities!",
          coord = { map = 371, x = 0.395, y = 0.900 } },  -- APR route coord (converted)
        { type = "accept", questID = 31740, text = "Koukou's Rampage",
          coord = { map = 371, x = 0.396, y = 0.900 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31740, text = "Koukou's Rampage (objective 1)",
          coord = { map = 371, x = 0.393, y = 0.899 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29552, text = "Turn in: Critical Condition",
          coord = { map = 371, x = 0.461, y = 0.845 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31738, text = "Turn in: Pillaging Peons",
          coord = { map = 371, x = 0.462, y = 0.847 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31740, text = "Turn in: Koukou's Rampage",
          coord = { map = 371, x = 0.462, y = 0.847 } },  -- APR route coord (converted)
        { type = "accept", questID = 31741, text = "Twinspire Keep",
          coord = { map = 371, x = 0.461, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31744, text = "Unfair Trade",
          coord = { map = 371, x = 0.461, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31742, text = "Fractured Forces",
          coord = { map = 371, x = 0.461, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 31743, text = "Smoke Before Fire",
          coord = { map = 371, x = 0.461, y = 0.847 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31743, text = "Smoke Before Fire (objective 4)",
          coord = { map = 371, x = 0.432, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 31743, text = "Smoke Before Fire (objective 1)",
          coord = { map = 371, x = 0.408, y = 0.824 } },  -- APR route coord (converted)
        { type = "quest", questID = 31743, text = "Smoke Before Fire (objective 3)",
          coord = { map = 371, x = 0.401, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 31743, text = "Smoke Before Fire (objective 2)",
          coord = { map = 371, x = 0.414, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 31741, text = "Twinspire Keep (objective 1)",
          coord = { map = 371, x = 0.414, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 31744, text = "Unfair Trade (objective 1)",
          coord = { map = 371, x = 0.414, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 31742, text = "Fractured Forces (objective 2)",
          coord = { map = 371, x = 0.417, y = 0.802 } },  -- APR route coord (converted)
        { type = "quest", questID = 31742, text = "Fractured Forces (objective 1)",
          coord = { map = 371, x = 0.412, y = 0.802 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31741, text = "Turn in: Twinspire Keep",
          coord = { map = 371, x = 0.414, y = 0.796 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31742, text = "Turn in: Fractured Forces",
          coord = { map = 371, x = 0.414, y = 0.796 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31743, text = "Turn in: Smoke Before Fire",
          coord = { map = 371, x = 0.414, y = 0.796 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31744, text = "Turn in: Unfair Trade",
          coord = { map = 371, x = 0.414, y = 0.796 } },  -- APR route coord (converted)
        { type = "accept", questID = 30070, text = "The Fall of Ga'trul",
          coord = { map = 371, x = 0.414, y = 0.796 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 30070, text = "The Fall of Ga'trul (objective 1)",
          coord = { map = 371, x = 0.414, y = 0.785 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30070, text = "Turn in: The Fall of Ga'trul",
          coord = { map = 371, x = 0.414, y = 0.791 } },  -- APR route coord (converted)
        { type = "accept", questID = 31745, text = "Onward and Inward",
          coord = { map = 371, x = 0.414, y = 0.791 } },  -- APR route coord (converted)
        { type = "quest", questID = 31745, text = "Onward and Inward (objective 1)",
          coord = { map = 371, x = 0.415, y = 0.797 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31745, text = "Turn in: Onward and Inward",
          coord = { map = 371, x = 0.480, y = 0.884 } },  -- APR route coord (converted)
        { type = "accept", questID = 29555, text = "The White Pawn",
          coord = { map = 371, x = 0.480, y = 0.883 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29556, text = "Hozen Aren't Your Friends, Hozen Are Your Enemies",
          coord = { map = 371, x = 0.480, y = 0.883 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29555, text = "The White Pawn (objective 2)",
          coord = { map = 371, x = 0.503, y = 0.909 } },  -- APR route coord (converted)
        { type = "quest", questID = 29555, text = "The White Pawn (objective 1)",
          coord = { map = 371, x = 0.499, y = 0.903 } },  -- APR route coord (converted)
        { type = "quest", questID = 29556, text = "Hozen Aren't Your Friends, Hozen Are Your Enemies (objective 1)",
          coord = { map = 371, x = 0.503, y = 0.909 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29555, text = "Turn in: The White Pawn",
          coord = { map = 371, x = 0.504, y = 0.882 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29556, text = "Turn in: Hozen Aren't Your Friends, Hozen Are Your Enemies",
          coord = { map = 371, x = 0.504, y = 0.882 } },  -- APR route coord (converted)
        { type = "accept", questID = 29553, text = "The Missing Admiral",
          coord = { map = 371, x = 0.504, y = 0.882 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 29553, text = "Turn in: The Missing Admiral",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- APR route coord (converted)
        { type = "accept", questID = 29558, text = "The Path of War",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29559, text = "Freeing Our Brothers",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29560, text = "Ancient Power",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29560, text = "Ancient Power (objective 1)",
          coord = { map = 371, x = 0.546, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest", questID = 29558, text = "The Path of War (objective 1)",
          coord = { map = 371, x = 0.538, y = 0.808 } },  -- APR route coord (converted)
        { type = "quest", questID = 29559, text = "Freeing Our Brothers (objective 1)",
          coord = { map = 371, x = 0.538, y = 0.808 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29558, text = "Turn in: The Path of War",
          coord = { map = 371, x = 0.541, y = 0.824 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29559, text = "Turn in: Freeing Our Brothers",
          coord = { map = 371, x = 0.541, y = 0.824 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29560, text = "Turn in: Ancient Power",
          coord = { map = 371, x = 0.541, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 29759, text = "Kung Din",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29759, text = "Kung Din (objective 1)",
          coord = { map = 371, x = 0.546, y = 0.801 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29759, text = "Turn in: Kung Din",
          coord = { map = 371, x = 0.541, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 29562, text = "Jailbreak",
          coord = { map = 371, x = 0.541, y = 0.825 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29562, text = "Jailbreak (objective 1)",
          coord = { map = 371, x = 0.558, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29562, text = "Turn in: Jailbreak",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 29883, text = "The Pearlfin Situation",
          coord = { map = 371, x = 0.588, y = 0.819 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29885, text = "Road Rations",
          coord = { map = 371, x = 0.588, y = 0.819 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29883, text = "The Pearlfin Situation (objective 1)",
          coord = { map = 371, x = 0.587, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 29883, text = "The Pearlfin Situation (objective 4)",
          coord = { map = 371, x = 0.580, y = 0.805 } },  -- APR route coord (converted)
        { type = "quest", questID = 29883, text = "The Pearlfin Situation (objective 3)",
          coord = { map = 371, x = 0.587, y = 0.846 } },  -- APR route coord (converted)
        { type = "quest", questID = 29883, text = "The Pearlfin Situation (objective 2)",
          coord = { map = 371, x = 0.599, y = 0.839 } },  -- APR route coord (converted)
        { type = "quest", questID = 29885, text = "Road Rations (objective 1)",
          coord = { map = 371, x = 0.610, y = 0.843 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29883, text = "Turn in: The Pearlfin Situation",
          coord = { map = 371, x = 0.589, y = 0.819 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29885, text = "Turn in: Road Rations",
          coord = { map = 371, x = 0.589, y = 0.819 } },  -- APR route coord (converted)
        { type = "accept", questID = 29762, text = "Family Heirlooms",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29887, text = "The Elder's Instruments",
          coord = { map = 371, x = 0.587, y = 0.813 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29762, text = "Family Heirlooms (objective 1)",
          coord = { map = 371, x = 0.666, y = 0.873 } },  -- APR route coord (converted)
        { type = "quest", questID = 29887, text = "The Elder's Instruments (objective 1,2,3,4)",
          coord = { map = 371, x = 0.666, y = 0.873 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29762, text = "Turn in: Family Heirlooms",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29887, text = "Turn in: The Elder's Instruments",
          coord = { map = 371, x = 0.587, y = 0.813 } },  -- APR route coord (converted)
        { type = "accept", questID = 29894, text = "Spirits of the Water",
          coord = { map = 371, x = 0.587, y = 0.813 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29894, text = "Spirits of the Water (objective 1,2)",
          coord = { map = 371, x = 0.585, y = 0.829 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29894, text = "Turn in: Spirits of the Water",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 29733, text = "SI:7 Report: Lost in the Woods",
          coord = { map = 371, x = 0.589, y = 0.818 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29733, text = "SI:7 Report: Lost in the Woods (objective 1)",
          coord = { map = 371, x = 0.498, y = 0.708 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29733, text = "Turn in: SI:7 Report: Lost in the Woods",
          coord = { map = 371, x = 0.589, y = 0.818 } },  -- APR route coord (converted)
        { type = "accept", questID = 29725, text = "SI:7 Report: Fire From the Sky",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29725, text = "SI:7 Report: Fire From the Sky (objective 1)",
          coord = { map = 371, x = 0.506, y = 0.630 } },  -- APR route coord (converted)
        { type = "quest", questID = 29725, text = "SI:7 Report: Fire From the Sky (objective 2)",
          coord = { map = 371, x = 0.464, y = 0.619 } },  -- APR route coord (converted)
        { type = "quest", questID = 29725, text = "SI:7 Report: Fire From the Sky (objective 3)",
          coord = { map = 371, x = 0.477, y = 0.585 } },  -- APR route coord (converted)
        { type = "quest", questID = 29725, text = "SI:7 Report: Fire From the Sky (objective 4)",
          coord = { map = 371, x = 0.509, y = 0.630 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29725, text = "Turn in: SI:7 Report: Fire From the Sky",
          coord = { map = 371, x = 0.588, y = 0.819 } },  -- APR route coord (converted)
        { type = "accept", questID = 29726, text = "SI:7 Report: Hostile Natives",
          coord = { map = 371, x = 0.590, y = 0.819 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29726, text = "SI:7 Report: Hostile Natives (objective 1)",
          coord = { map = 371, x = 0.383, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest", questID = 29726, text = "SI:7 Report: Hostile Natives (objective 2)",
          coord = { map = 371, x = 0.388, y = 0.462 } },  -- APR route coord (converted)
        { type = "quest", questID = 29726, text = "SI:7 Report: Hostile Natives (objective 3)",
          coord = { map = 371, x = 0.389, y = 0.463 } },  -- APR route coord (converted)
        { type = "quest", questID = 29726, text = "SI:7 Report: Hostile Natives (objective 4)",
          coord = { map = 371, x = 0.392, y = 0.462 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29726, text = "Turn in: SI:7 Report: Hostile Natives",
          coord = { map = 371, x = 0.590, y = 0.819 } },  -- APR route coord (converted)
        { type = "accept", questID = 29727, text = "SI:7 Report: Take No Prisoners",
          coord = { map = 371, x = 0.588, y = 0.819 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29727, text = "SI:7 Report: Take No Prisoners (objective 1)",
          coord = { map = 371, x = 0.286, y = 0.544 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29727, text = "Turn in: SI:7 Report: Take No Prisoners",
          coord = { map = 371, x = 0.589, y = 0.819 } },  -- APR route coord (converted)
        { type = "accept", questID = 29903, text = "A Perfect Match",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29888, text = "Seek Out the Lorewalker",
          coord = { map = 371, x = 0.589, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29903, text = "A Perfect Match (objective 1)",
          coord = { map = 371, x = 0.593, y = 0.842 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29903, text = "Turn in: A Perfect Match",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 29904, text = "Bigger Fish to Fry",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29904, text = "Bigger Fish to Fry (objective 1)",
          coord = { map = 371, x = 0.637, y = 0.795 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29904, text = "Turn in: Bigger Fish to Fry",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 29905, text = "Let Them Burn",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29906, text = "Carp Diem",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29906, text = "Carp Diem (objective 1)",
          coord = { map = 371, x = 0.546, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest", questID = 29905, text = "Let Them Burn (objective 1)",
          coord = { map = 371, x = 0.555, y = 0.820 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29905, text = "Turn in: Let Them Burn",
          coord = { map = 371, x = 0.588, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29906, text = "Turn in: Carp Diem",
          coord = { map = 371, x = 0.588, y = 0.815 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29888, text = "Turn in: Seek Out the Lorewalker",
          coord = { map = 371, x = 0.537, y = 0.915 } },  -- APR route coord (converted)
        { type = "accept", questID = 29889, text = "Borrowed Brew",
          coord = { map = 371, x = 0.537, y = 0.915 } },  -- APR route coord (converted)
        { type = "quest", questID = 29889, text = "Borrowed Brew (objective 1)",
          coord = { map = 371, x = 0.537, y = 0.915 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29889, text = "Turn in: Borrowed Brew",
          coord = { map = 371, x = 0.536, y = 0.914 } },  -- APR route coord (converted)
        { type = "accept", questID = 31130, text = "A Visit with Lorewalker Cho",
          coord = { map = 371, x = 0.537, y = 0.913 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31130, text = "A Visit with Lorewalker Cho (objective 1)",
          coord = { map = 371, x = 0.537, y = 0.910 } },  -- APR route coord (converted)
        { type = "quest", questID = 31130, text = "A Visit with Lorewalker Cho (objective 2)",
          coord = { map = 371, x = 0.540, y = 0.907 } },  -- APR route coord (converted)
        { type = "quest", questID = 31130, text = "A Visit with Lorewalker Cho (objective 3)",
          coord = { map = 371, x = 0.540, y = 0.913 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31130, text = "Turn in: A Visit with Lorewalker Cho",
          coord = { map = 371, x = 0.540, y = 0.912 } },  -- APR route coord (converted)
        { type = "accept", questID = 29891, text = "Potency",
          coord = { map = 371, x = 0.540, y = 0.912 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29892, text = "Body",
          coord = { map = 371, x = 0.540, y = 0.912 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29893, text = "Hue",
          coord = { map = 371, x = 0.540, y = 0.912 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29891, text = "Potency (objective 1,2)",
          coord = { map = 371, x = 0.579, y = 0.900 } },  -- APR route coord (converted)
        { type = "quest", questID = 29893, text = "Hue (objective 1)",
          coord = { map = 371, x = 0.579, y = 0.900 } },  -- APR route coord (converted)
        { type = "quest", questID = 29892, text = "Body (objective 1)",
          coord = { map = 371, x = 0.578, y = 0.898 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29891, text = "Turn in: Potency",
          coord = { map = 371, x = 0.537, y = 0.906 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29892, text = "Turn in: Body",
          coord = { map = 371, x = 0.537, y = 0.906 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29893, text = "Turn in: Hue",
          coord = { map = 371, x = 0.537, y = 0.906 } },  -- APR route coord (converted)
        { type = "accept", questID = 29890, text = "Finding Your Center",
          coord = { map = 371, x = 0.538, y = 0.906 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29890, text = "Finding Your Center (objective 1)",
          coord = { map = 371, x = 0.546, y = 0.920 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29890, text = "Turn in: Finding Your Center",
          coord = { map = 371, x = 0.658, y = 0.792 } },  -- APR route coord (converted)
        { type = "accept", questID = 29898, text = "Sacred Waters",
          coord = { map = 371, x = 0.659, y = 0.793 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29899, text = "Rest in Peace",
          coord = { map = 371, x = 0.659, y = 0.793 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 29900, text = "An Ancient Legend",
          coord = { map = 371, x = 0.659, y = 0.793 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29898, text = "Sacred Waters (objective 1)",
          coord = { map = 371, x = 0.668, y = 0.821 } },  -- APR route coord (converted)
        { type = "quest", questID = 29898, text = "Sacred Waters (objective 2)",
          coord = { map = 371, x = 0.672, y = 0.816 } },  -- APR route coord (converted)
        { type = "quest", questID = 29898, text = "Sacred Waters (objective 3)",
          coord = { map = 371, x = 0.680, y = 0.819 } },  -- APR route coord (converted)
        { type = "quest", questID = 29900, text = "An Ancient Legend (objective 1)",
          coord = { map = 371, x = 0.667, y = 0.803 } },  -- APR route coord (converted)
        { type = "quest", questID = 29898, text = "Sacred Waters (objective 4)",
          coord = { map = 371, x = 0.664, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest", questID = 29900, text = "An Ancient Legend (objective 2)",
          coord = { map = 371, x = 0.664, y = 0.805 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29898, text = "Turn in: Sacred Waters",
          coord = { map = 371, x = 0.659, y = 0.794 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29899, text = "Turn in: Rest in Peace",
          coord = { map = 371, x = 0.659, y = 0.794 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29900, text = "Turn in: An Ancient Legend",
          coord = { map = 371, x = 0.659, y = 0.794 } },  -- APR route coord (converted)
        { type = "accept", questID = 29901, text = "Anduin's Decision",
          coord = { map = 371, x = 0.659, y = 0.793 } },  -- APR route coord (converted)
        { type = "quest", questID = 29901, text = "Anduin's Decision (objective 1)",
          coord = { map = 371, x = 0.659, y = 0.793 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29901, text = "Turn in: Anduin's Decision",
          coord = { map = 371, x = 0.588, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 29922, text = "In Search of Wisdom",
          coord = { map = 371, x = 0.589, y = 0.815 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 29922, text = "In Search of Wisdom (objective 1)",
          coord = { map = 371, x = 0.579, y = 0.825 } },  -- APR route coord (converted)
        { type = "turnin", questID = 29922, text = "Turn in: In Search of Wisdom",
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
        { type = "accept", questID = 30498, text = "Get Back Here!",
          coord = { map = 371, x = 0.558, y = 0.571 } },  -- APR route coord (converted)
        { type = "accept", questID = 30565, text = "An Unexpected Advantage",
          coord = { map = 371, x = 0.585, y = 0.822 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "accept", questID = 30568, text = "Helping the Cause",
          coord = { map = 371, x = 0.581, y = 0.806 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "turnin", questID = 30498, text = "Turn in: Get Back Here!",
          coord = { map = 371, x = 0.580, y = 0.807 } },  -- APR route coord (converted)
        { type = "quest", questID = 30568, text = "Helping the Cause (objective 2)",
          coord = { map = 371, x = 0.546, y = 0.800 } },  -- APR route coord (converted)
        { type = "quest", questID = 30568, text = "Helping the Cause (objective 1)",
          coord = { map = 371, x = 0.592, y = 0.836 } },  -- APR route coord (converted)
        { type = "quest", questID = 30568, text = "Helping the Cause (objective 3)",
          coord = { map = 371, x = 0.597, y = 0.872 } },  -- APR route coord (converted)
        { type = "quest", questID = 30565, text = "An Unexpected Advantage (objective 1,2)",
          coord = { map = 371, x = 0.634, y = 0.777 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30565, text = "Turn in: An Unexpected Advantage",
          coord = { map = 371, x = 0.585, y = 0.823 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30568, text = "Turn in: Helping the Cause",
          coord = { map = 371, x = 0.580, y = 0.807 } },  -- APR route coord (converted)
        { type = "accept", questID = 31362, text = "Last Piece of the Puzzle",
          coord = { map = 371, x = 0.588, y = 0.811 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31362, text = "Last Piece of the Puzzle (objective 1)",
          coord = { map = 371, x = 0.445, y = 0.669 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31362, text = "Turn in: Last Piece of the Puzzle",
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
        { type = "accept", questID = 31319, text = "Emergency Response",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- giver: ATT coord, confirmed vs Wowhead MoP Classic NPC spawn
        { type = "quest", questID = 31319, text = "Emergency Response (objective 1)",
          coord = { map = 371, x = 0.477, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest", questID = 31319, text = "Emergency Response (objective 2)",
          coord = { map = 371, x = 0.463, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest", questID = 31319, text = "Emergency Response (objective 3)",
          coord = { map = 371, x = 0.475, y = 0.592 } },  -- APR route coord (converted)
        { type = "quest", questID = 30500, text = "Residual Fallout (objective 1)",
          coord = { map = 371, x = 0.490, y = 0.616 } },  -- APR route coord (converted)
        { type = "quest", questID = 30502, text = "Jaded Heart (objective 1)",
          coord = { map = 371, x = 0.490, y = 0.616 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30500, text = "Turn in: Residual Fallout",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 30502, text = "Turn in: Jaded Heart",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- APR route coord (converted)
        { type = "turnin", questID = 31319, text = "Turn in: Emergency Response",
          coord = { map = 371, x = 0.492, y = 0.614 } },  -- APR route coord (converted)
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
