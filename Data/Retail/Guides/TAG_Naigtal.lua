-- ToonAge/Data/Guides/TAG_Naigtal.lua
-- STUB -- auto-generated from WoWDB PTR HTML dump
-- Quest ORDER is sorted by questID (approximate).
-- TODO: verify order in-game with /taquestscan, fill coords.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["naigtal"] = {
    id       = "naigtal",
    title    = "Midnight: Void Assaults & Naigtal",
    expansion = "midnight",

    -- Keyed to Quel'Thalas (2537), the region, NOT to Naigtal (2600).
    --
    -- Despite the file name, only 4 of this guide's 21 steps are Naigtal steps.
    -- The other 17 are the Void Assaults chain, which starts in Zul'Aman and
    -- runs through Voidstorm before reaching Naigtal at all. Keying the guide to
    -- its *final* zone meant those 17 steps could never be auto-selected — the
    -- player is in Zul'Aman, the guide claims 2600, no match. Naigtal is also
    -- gated content, so the 17 open-world steps are the part most players can
    -- actually reach first.
    --
    -- 2537 matches anywhere in Quel'Thalas. That is safe now that
    -- QuestTracker's MapZoneDistance ranks by specificity: standing in Eversong,
    -- the Eversong guide wins at distance 0 and this one loses at distance 1.
    -- In Zul'Aman it matches uncontested.
    --
    -- Proper fix is to split this into a Void Assaults guide and a Naigtal
    -- guide, which the step tags already imply. Until then, per-step coord.map
    -- is the right place to record each step's real zone — all 21 are stubs.
    zone     = 2537,
    minLevel = 86,   -- Naigtal is the final Midnight leveling zone (86-90)
    maxLevel = 90,
    steps = {
        -- Step 1  [Void Assaults]
        {
            type    = "quest",
            questID = 94386,
            text    = "Void Assaults: Zul'Aman",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 2  [Void Assaults]
        {
            type    = "quest",
            questID = 95575,
            text    = "Forest Mana Spores",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 3  [Void Assaults]
        {
            type    = "quest",
            questID = 96048,
            text    = "The Time to Strike",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 4  [Void Assaults]
        {
            type    = "quest",
            questID = 96049,
            text    = "Stalkers of the Stars",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 5  [Void Assaults]
        {
            type    = "quest",
            questID = 96052,
            text    = "Through the Mana Rift",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 6  [Void Assaults]
        {
            type    = "quest",
            questID = 96054,
            text    = "Surveying the Mana-Bog",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 7  [Naigtal]
        {
            type    = "quest",
            questID = 96293,
            text    = "Mush-Vroom!",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 8  [Void Assaults]
        {
            type    = "quest",
            questID = 96472,
            text    = "The Nexus-Captain",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 9  [Void Assaults]
        {
            type    = "quest",
            questID = 96522,
            text    = "Oh Captain, Die Captain!",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 10  [Void Assaults]
        {
            type    = "quest",
            questID = 96534,
            text    = "Preparing for Threats",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 11  [Void Assaults]
        {
            type    = "quest",
            questID = 96547,
            text    = "Weaken Their Forces",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 12  [Naigtal]
        {
            type    = "quest",
            questID = 96548,
            text    = "High Spore",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 13  [Void Assaults]
        {
            type    = "quest",
            questID = 96572,
            text    = "Malfunctioning Nullframe",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 14  [Naigtal]
        {
            type    = "quest",
            questID = 96668,
            text    = "Subdue the Spore Storm",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 15  [Naigtal]
        {
            type    = "quest",
            questID = 96693,
            text    = "Nexus Port Tendril Sling",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 16  [Void Assaults]
        {
            type    = "quest",
            questID = 96703,
            text    = "Veterans of the Great Dark",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 17  [Void Assaults]
        {
            type    = "quest",
            questID = 96708,
            text    = "To the Voidstorm and Beyond!",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 18  [Void Assaults]
        {
            type    = "quest",
            questID = 96717,
            text    = "Showdown on Naigtal",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 19  [Void Assaults]
        {
            type    = "quest",
            questID = 96726,
            text    = "Sparks of War: Naigtal",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 20  [Void Assaults]
        {
            type    = "quest",
            questID = 96809,
            text    = "Exterior Manaforge Translocator",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 21  [Void Assaults]
        {
            type    = "quest",
            questID = 97072,
            text    = "A Swampy Welcome to Naigtal",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
    },
}
