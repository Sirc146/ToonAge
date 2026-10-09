-- ToonAge: Midnight standalone reputation route - Ritual Sites (factionID 2792). Generated 2026-10-09 PT by Grok Bot.
-- Order: one-time quests in leveling-guide order (campaign/zone order = efficient travel), then repeatables (dailies/weeklies/WQ/events,
-- nearest-neighbour ordered per map in their source files). Steps are copied verbatim from the guide files (fromGuide = source guide id),
-- including accept/objective/turn-in steps for each quest. rep amounts: Wowhead quest pages. See midnight/reputations.lua for totals.

local TA = ToonAge or {}
ToonAge = TA
TA.RepRoutes = TA.RepRoutes or {}
TA.RepRoutes[2792] = {
    factionID = 2792,
    name = "Ritual Sites",
    steps = {
        {
            text = "Ritual Problems",
            type = "quest",
            rep = {
                { amount = 1000, factionID = 2792 },
            },
            coord = { x = 0.477, map = 2393, y = 0.496 },
            provider = { npcID = 257416 },
            questID = 94382,
            prerequisites = { 94383 },
            fromGuide = "midnight_event_ritual_sites",
        },
    },
    oneTimeQuests = 1,
    repeatableQuests = 1,
}
