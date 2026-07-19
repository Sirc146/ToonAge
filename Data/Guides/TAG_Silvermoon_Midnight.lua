-- ToonAge/Data/Guides/TAG_Silvermoon_Midnight.lua
-- STUB -- auto-generated from WoWDB PTR HTML dump
-- Quest ORDER is sorted by questID (approximate).
-- TODO: verify order in-game with /taquestscan, fill coords.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["silvermoon_midnight"] = {
    id       = "silvermoon_midnight",
    title    = "Midnight: Silvermoon City",
    -- Silvermoon City has its own classic map ID (2441 in live WoW 10.x).
    -- On Midnight PTR it may have a new ID.  Confirm with /coord in-game.
    -- Using 0 for now so we don't collide with eversong_midnight (also stub).
    zone     = 0,
    minLevel = 83,   -- narrowed midpoint so AutoSelectGuide prefers this guide
    maxLevel = 87,   -- for 83-87 level band, Eversong for 80-85
    steps = {
        -- Step 1  [Silvermoon City]
        {
            type    = "quest",
            questID = 92105,
            text    = "Papers, Please!",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 2  [Silvermoon City]
        {
            type    = "quest",
            questID = 92120,
            text    = "To Understand Magic",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 3  [Silvermoon City]
        {
            type    = "quest",
            questID = 93687,
            text    = "Taste True Power",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 4  [Silvermoon City]
        {
            type    = "quest",
            questID = 93697,
            text    = "Shimmering Melodies",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 5  [Silvermoon City]
        {
            type    = "quest",
            questID = 93698,
            text    = "Splintered Radiance",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 6  [Silvermoon City]
        {
            type    = "quest",
            questID = 93709,
            text    = "Stocking the Staples",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 7  [Silvermoon City]
        {
            type    = "quest",
            questID = 94012,
            text    = "Lost Lil' Strider",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 8  [Silvermoon City]
        {
            type    = "quest",
            questID = 94380,
            text    = "Ranger Captain's Summons",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 9  [Silvermoon City]
        {
            type    = "quest",
            questID = 94385,
            text    = "Void Assaults: Eversong Woods",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 10  [Silvermoon City]
        {
            type    = "quest",
            questID = 94474,
            text    = "The Great Vault",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 11  [Silvermoon City]
        {
            type    = "quest",
            questID = 94835,
            text    = "Early Morning Training: Week 1 of 4",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 12  [Silvermoon City]
        {
            type    = "quest",
            questID = 94836,
            text    = "Late Night Training: Week 2 of 4",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 13  [Silvermoon City]
        {
            type    = "quest",
            questID = 94837,
            text    = "Midnight Training: Week 2 of 3",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 14  [Silvermoon City]
        {
            type    = "quest",
            questID = 95245,
            text    = "Midnight: World Tour",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
        -- Step 15  [Silvermoon City]
        {
            type    = "quest",
            questID = 96080,
            text    = "Void Strike",
            coord   = { map = 0, x = 0.00, y = 0.00 },
        },
    },
}
