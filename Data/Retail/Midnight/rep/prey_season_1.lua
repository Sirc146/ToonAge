-- ToonAge: Midnight standalone reputation route - Prey: Season 1 (factionID 2764). Generated 2026-10-09 PT by Grok Bot.
-- Order: one-time quests in leveling-guide order (campaign/zone order = efficient travel), then repeatables (dailies/weeklies/WQ/events,
-- nearest-neighbour ordered per map in their source files). Steps are copied verbatim from the guide files (fromGuide = source guide id),
-- including accept/objective/turn-in steps for each quest. rep amounts: Wowhead quest pages. See midnight/reputations.lua for totals.

local TA = ToonAge or {}
ToonAge = TA
TA.RepRoutes = TA.RepRoutes or {}
TA.RepRoutes[2764] = {
    factionID = 2764,
    name = "Prey: Season 1",
    steps = {
        {
            text = "To the Sanctum!",
            type = "accept",
            questID = 93086,
            coord = { x = 0.196, map = 2393, y = 0.136 },
            fromGuide = "midnight_prey",
        },
        {
            text = "Turn in: To the Sanctum!",
            type = "turnin",
            coord = { x = 0.567, map = 2393, y = 0.654 },
            questID = 93086,
            rep = {
                { amount = 4000, factionID = 2764 },
            },
            fromGuide = "midnight_prey",
        },
    },
    oneTimeQuests = 1,
    repeatableQuests = 0,
}
