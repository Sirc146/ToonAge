-- ToonAge/Data/TBC/ProfessionSkills.lua
-- TBC skill caps and skill lines for the shared profession cards.
--
-- GetProfessions does not exist here. The reader walks GetSkillLineInfo and
-- keeps lines under the headers in this file. 375 is the Master ceiling,
-- used only when the client omits max rank. Names attach a skill line id
-- when the client reports the English name; a localized name stays without
-- an id rather than borrowing one.

local TA = ToonAge
TA.Data = TA.Data or {}

local function Line(id, name, secondary)
    return { id = id, name = name, secondary = secondary and true or false }
end

TA.Data.ProfessionSkills = {
    unverified = false,
    prefer     = { "skilllines" },
    cap        = 375,
    headers    = { "Professions", "Secondary Skills" },
    lines = {
        Line(171, "Alchemy"),
        Line(164, "Blacksmithing"),
        Line(333, "Enchanting"),
        Line(202, "Engineering"),
        Line(182, "Herbalism"),
        Line(755, "Jewelcrafting"),
        Line(165, "Leatherworking"),
        Line(186, "Mining"),
        Line(393, "Skinning"),
        Line(197, "Tailoring"),
        Line(185, "Cooking",   true),
        Line(129, "First Aid", true),
        Line(356, "Fishing",   true),
    },
}
