-- ToonAge/Data/Guides/TAG_Exiles_Reach.lua
-- Exile's Reach: New Player Experience (Level 1-10)
-- Zone mapID: 1409 (Exile's Reach), 1726 (Darkmaul Citadel sub-zone)
--
-- Notes:
--   • Class tutorial quests (steps 27-41 range) are gated by class field.
--   • "What's Your Specialty?" has unique questIDs per class — only one applies.
--   • All coords are stub (map=0) — requires PTR walkthrough to fill.
--   • Guide chains to midnight_intro after completion.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["exiles_reach"] = {
    id = "exiles_reach",
    title = "Exile's Reach",
    expansion = "starter",
    zone = 1409,
    minLevel = 1,
    maxLevel = 10,
    nextGuide = "midnight_intro", -- chains into Midnight intro after Exile's Reach
    steps = {
        -- ═══ CHAPTER 1: SHIPWRECK ═══
        {
            type = "accept",
            questID = 59926,
            text = "Warming Up",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },
        {
            type = "quest",
            questID = 59926,
            text = "Warming Up — attack the training dummies",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },
        {
            type = "turnin",
            questID = 59926,
            text = "Turn in Warming Up",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },

        {
            type = "accept",
            questID = 59927,
            text = "Stand Your Ground",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },
        {
            type = "quest",
            questID = 59927,
            text = "Defeat the sparring partner",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },
        {
            type = "turnin",
            questID = 59927,
            text = "Turn in Stand Your Ground",
            coord = { map = 1409, x = 0.56, y = 0.26 },
        },

        {
            type = "accept",
            questID = 59928,
            text = "Brace for Impact",
            coord = { map = 1409, x = 0.55, y = 0.25 },
        },
        {
            type = "quest",
            questID = 59928,
            text = "Watch the cutscene — ship is attacked",
            coord = { map = 1409, x = 0.55, y = 0.25 },
        },

        -- ═══ CHAPTER 2: BEACH SURVIVAL ═══
        {
            type = "accept",
            questID = 59929,
            text = "Murloc Mania",
            coord = { map = 1409, x = 0.58, y = 0.82 },
        },
        {
            type = "quest",
            questID = 59929,
            text = "Kill 6 Murlocs on the beach",
            coord = { map = 1409, x = 0.58, y = 0.82 },
        },

        {
            type = "accept",
            questID = 59930,
            text = "Emergency First Aid",
            coord = { map = 1409, x = 0.58, y = 0.82 },
        },
        {
            type = "quest",
            questID = 59930,
            text = "Heal 5 Injured Sailors",
            coord = { map = 1409, x = 0.58, y = 0.82 },
        },

        {
            type = "turnin",
            questID = 59929,
            text = "Turn in Murloc Mania",
            coord = { map = 1409, x = 0.52, y = 0.74 },
        },
        {
            type = "turnin",
            questID = 59930,
            text = "Turn in Emergency First Aid",
            coord = { map = 1409, x = 0.52, y = 0.74 },
        },

        -- ═══ CHAPTER 3: INLAND EXPEDITION ═══
        {
            type = "accept",
            questID = 59931,
            text = "Finding the Lost Expedition",
            coord = { map = 1409, x = 0.52, y = 0.74 },
        },
        {
            type = "quest",
            questID = 59931,
            text = "Head inland to find the expedition camp",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },

        {
            type = "accept",
            questID = 59932,
            text = "Cooking Meat",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },
        {
            type = "quest",
            questID = 59932,
            text = "Cook 4 Boar Ribs at the campfire",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },

        {
            type = "accept",
            questID = 59933,
            text = "Enhanced Combat Tactics",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },
        {
            type = "quest",
            questID = 59933,
            text = "Complete combat training with Brannon",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },

        -- ═══ CHAPTER 4: QUILBOAR CAMP ═══
        {
            type = "accept",
            questID = 59935,
            text = "Northbound",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },
        {
            type = "quest",
            questID = 59935,
            text = "Travel north to the Quilboar area",
            coord = { map = 1409, x = 0.42, y = 0.50 },
        },

        {
            type = "accept",
            questID = 59937,
            text = "Taming the Wilds",
            coord = { map = 1409, x = 0.42, y = 0.50 },
        },
        {
            type = "quest",
            questID = 59937,
            text = "Tame or defeat wild creatures",
            coord = { map = 1409, x = 0.42, y = 0.50 },
        },

        {
            type = "accept",
            questID = 59938,
            text = "Down with the Quilboar",
            coord = { map = 1409, x = 0.42, y = 0.50 },
        },
        {
            type = "quest",
            questID = 59938,
            text = "Kill 8 Quilboar",
            coord = { map = 1409, x = 0.40, y = 0.46 },
        },

        {
            type = "accept",
            questID = 59939,
            text = "Forbidden Quilboar Shadow Magic",
            coord = { map = 1409, x = 0.40, y = 0.46 },
        },
        {
            type = "quest",
            questID = 59939,
            text = "Destroy 3 Shadow Totems",
            coord = { map = 1409, x = 0.38, y = 0.44 },
        },

        -- ═══ CHAPTER 5: HENRY & HARPIES ═══
        {
            type = "accept",
            questID = 59943,
            text = "The Harpy Problem",
            coord = { map = 1409, x = 0.36, y = 0.36 },
        },
        {
            type = "quest",
            questID = 59943,
            text = "Clear the harpy nests",
            coord = { map = 1409, x = 0.34, y = 0.32 },
        },

        {
            type = "accept",
            questID = 59944,
            text = "The Rescue of Herbert Gloomburst",
            coord = { map = 1409, x = 0.34, y = 0.32 },
        },
        {
            type = "quest",
            questID = 59944,
            text = "Free Herbert from the cage",
            coord = { map = 1409, x = 0.32, y = 0.30 },
        },

        {
            type = "accept",
            questID = 59947,
            text = "Message to Base",
            coord = { map = 1409, x = 0.32, y = 0.30 },
        },
        {
            type = "quest",
            questID = 59947,
            text = "Return to camp with Henry's report",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },

        -- ═══ CHAPTER 6: DARKMAUL CITADEL ═══
        {
            type = "accept",
            questID = 59975,
            text = "To Darkmaul Citadel",
            coord = { map = 1409, x = 0.49, y = 0.63 },
        },
        {
            type = "quest",
            questID = 59975,
            text = "Travel to Darkmaul Citadel entrance",
            coord = { map = 1409, x = 0.26, y = 0.58 },
        },

        {
            type = "accept",
            questID = 59978,
            text = "Right Beneath Their Eyes",
            coord = { map = 1409, x = 0.26, y = 0.58 },
        },
        {
            type = "quest",
            questID = 59978,
            text = "Infiltrate the citadel courtyard",
            coord = { map = 1409, x = 0.24, y = 0.55 },
        },

        {
            type = "accept",
            questID = 59979,
            text = "Like Ogres to the Slaughter",
            coord = { map = 1409, x = 0.24, y = 0.55 },
        },
        {
            type = "quest",
            questID = 59979,
            text = "Kill 8 Darkmaul Ogres",
            coord = { map = 1409, x = 0.22, y = 0.52 },
        },

        {
            type = "accept",
            questID = 59980,
            text = "Catapult Destruction",
            coord = { map = 1409, x = 0.24, y = 0.55 },
        },
        {
            type = "quest",
            questID = 59980,
            text = "Destroy 2 Ogre Catapults",
            coord = { map = 1409, x = 0.20, y = 0.50 },
        },

        {
            type = "accept",
            questID = 59984,
            text = "Dungeon: Darkmaul Citadel",
            coord = { map = 1409, x = 0.20, y = 0.50 },
        },
        {
            type = "quest",
            questID = 59984,
            text = "Complete the Darkmaul Citadel dungeon (use LFG tool or enter the portal)",
            coord = { map = 1409, x = 0.18, y = 0.48 },
        },

        -- ═══ CHAPTER 7: DEPARTURE ═══
        {
            type = "turnin",
            questID = 55991,
            text = "An End to Beginnings — turn in at camp",
            coord = { map = 1409, x = 0.40, y = 0.32 },
        },

        {
            type = "accept",
            questID = 90842,
            text = "Home Is Where the Hearth Is",
            coord = { map = 1409, x = 0.40, y = 0.32 },
        },
        {
            type = "quest",
            questID = 90842,
            text = "Use your Hearthstone to return to the capital city",
            coord = { map = 1409, x = 0.40, y = 0.32 },
        },

        -- ═══ CLASS SPECIALIZATION QUEST (one per class — filter skips the rest) ═══
        {
            type = "quest",
            questID = 90840,
            text = "Choose Your Specialization",
            class = "WARRIOR",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60343,
            text = "Choose Your Specialization",
            class = "DEATHKNIGHT",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60344,
            text = "Choose Your Specialization",
            class = "PALADIN",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60345,
            text = "Choose Your Specialization",
            class = "HUNTER",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60346,
            text = "Choose Your Specialization",
            class = "ROGUE",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60347,
            text = "Choose Your Specialization",
            class = "PRIEST",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60348,
            text = "Choose Your Specialization",
            class = "SHAMAN",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60349,
            text = "Choose Your Specialization",
            class = "MAGE",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60350,
            text = "Choose Your Specialization",
            class = "WARLOCK",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60351,
            text = "Choose Your Specialization",
            class = "MONK",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60352,
            text = "Choose Your Specialization",
            class = "DRUID",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 60353,
            text = "Choose Your Specialization",
            class = "DEMONHUNTER",
            coord = { map = 0, x = 0, y = 0 },
        },
        {
            type = "quest",
            questID = 90843,
            text = "Choose Your Specialization",
            class = "EVOKER",
            coord = { map = 0, x = 0, y = 0 },
        },
    },
}
