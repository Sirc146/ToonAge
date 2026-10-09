-- ToonAge/Data/Mists/ProfessionSkills.lua
-- Mists skill caps and skill lines for the shared profession cards.
--
-- One bar. GetProfessions / GetProfessionInfo report the current rank, so
-- `prefer` lists the single-bar reader and not the retail segment reader.
-- 600 is the Zen Master ceiling, used only when the client omits max rank.

local TA = ToonAge
TA.Data = TA.Data or {}

local function Line(id, name, secondary)
    return { id = id, name = name, secondary = secondary and true or false }
end

TA.Data.ProfessionSkills = {
    unverified = false,
    prefer     = { "professions" },
    cap        = 600,
    headers    = { "Professions", "Secondary Skills" },
    lines = {
        Line(171, "Alchemy"),
        Line(164, "Blacksmithing"),
        Line(333, "Enchanting"),
        Line(202, "Engineering"),
        Line(182, "Herbalism"),
        Line(773, "Inscription"),
        Line(755, "Jewelcrafting"),
        Line(165, "Leatherworking"),
        Line(186, "Mining"),
        Line(393, "Skinning"),
        Line(197, "Tailoring"),
        Line(794, "Archaeology", true),
        Line(185, "Cooking",     true),
        Line(129, "First Aid",   true),
        Line(356, "Fishing",     true),
    },
}
