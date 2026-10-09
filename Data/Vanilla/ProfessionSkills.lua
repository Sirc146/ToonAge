-- ToonAge/Data/Vanilla/ProfessionSkills.lua
-- Classic Era skill caps and skill lines for the shared profession cards.
--
-- Same reader as TBC: GetSkillLineInfo, kept only under the headers below.
-- 300 is the Artisan ceiling, used only when the client omits max rank.
-- Jewelcrafting, Inscription and Archaeology are later expansions and are
-- not listed here.

local TA = ToonAge
TA.Data = TA.Data or {}

local function Line(id, name, secondary)
    return { id = id, name = name, secondary = secondary and true or false }
end

TA.Data.ProfessionSkills = {
    unverified = false,
    prefer     = { "skilllines" },
    cap        = 300,
    headers    = { "Professions", "Secondary Skills" },
    lines = {
        Line(171, "Alchemy"),
        Line(164, "Blacksmithing"),
        Line(333, "Enchanting"),
        Line(202, "Engineering"),
        Line(182, "Herbalism"),
        Line(165, "Leatherworking"),
        Line(186, "Mining"),
        Line(393, "Skinning"),
        Line(197, "Tailoring"),
        Line(185, "Cooking",   true),
        Line(129, "First Aid", true),
        Line(356, "Fishing",   true),
    },
}
