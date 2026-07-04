-- CharacterAdvisor/Data/Guides/CAG_Midnight_Intro.lua
-- Midnight expansion: Quel'Thalas introduction questline.
-- Self-registers into CA.GuideData on load (before Modules/ run).
-- Update questID and coord values with live PTR data as it becomes available.

local CA = CharacterAdvisor
CA.GuideData = CA.GuideData or {}

CA.GuideData["midnight_intro"] = {
    id       = "midnight_intro",
    title    = "Midnight: Quel'Thalas Intro",
    zone     = 2434,   -- PTR intro zone (update with live map ID)
    minLevel = 1,
    maxLevel = 20,
    steps = {
        {
            type = "text",
            text = "Welcome to Quel'Thalas. This guide covers the Midnight introduction questline. Follow the steps below.",
        },
        {
            type    = "quest",
            questID = 80001,
            text    = "Speak with the Ranger-Captain near the landing zone to accept 'Shadows at the Gate'.",
            coord   = { map = 2434, x = 0.52, y = 0.41 },
        },
        {
            type    = "quest",
            questID = 80002,
            text    = "Defeat the Amani scouting party threatening the outer walls (0/8).",
            coord   = { map = 2434, x = 0.47, y = 0.33 },
            precondition = { questID = 80001 },
        },
        {
            type    = "quest",
            questID = 80002,
            text    = "Return and turn in 'Shadows at the Gate' to the Ranger-Captain.",
            coord   = { map = 2434, x = 0.52, y = 0.41 },
        },
        {
            type  = "travel",
            text  = "Follow the road north-east toward the Ruins of Silvermoon. Watch for ambush packs.",
            coord = { map = 2434, x = 0.61, y = 0.28 },
        },
        {
            type    = "npc",
            text    = "Speak with Archivist Vandrel in the ruined library. This unlocks the Sunwell questline.",
            coord   = { map = 2434, x = 0.63, y = 0.27 },
            minLevel = 5,
        },
        {
            type    = "quest",
            questID = 80010,
            text    = "Accept 'The Sunwell's Echo' from Archivist Vandrel.",
            coord   = { map = 2434, x = 0.63, y = 0.27 },
        },
        {
            type    = "quest",
            questID = 80011,
            text    = "Collect 5 Sunwell Residue from the corrupted pools around the Ruins (0/5).",
            coord   = { map = 2434, x = 0.67, y = 0.24 },
            precondition = { questID = 80010 },
        },
        {
            type    = "quest",
            questID = 80011,
            text    = "Return the residue to Archivist Vandrel and turn in 'The Sunwell's Echo'.",
            coord   = { map = 2434, x = 0.63, y = 0.27 },
        },
        {
            type  = "action",
            text  = "Bind at the Quel'Thalas Forward Camp inn before proceeding to the second zone.",
            coord = { map = 2434, x = 0.55, y = 0.22 },
        },
    },
}
