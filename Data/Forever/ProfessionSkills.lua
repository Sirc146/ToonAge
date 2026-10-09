-- ToonAge/Data/Forever/ProfessionSkills.lua
--
-- UNVERIFIED. Forever's profession caps and skill line ids have not been
-- confirmed by an in-game probe, apart from Comprehension (skill line 3012),
-- which the 2026-09-27 probe found outside GetProfessions(). The classic ids
-- below are the published vanilla skill lines, listed so a matching id can
-- be recognised. They are not a claim that Forever uses them. The tab says
-- so until a probe confirms the list.
--
-- prefer is skillinfo: C_SkillInfo.GetNumSkillLines / GetSkillLineInfo, which
-- that probe did confirm. The reader still checks that those calls exist
-- before using them.

local TA = ToonAge
TA.Data = TA.Data or {}

local function Line(id, name, secondary)
    return { id = id, name = name, secondary = secondary and true or false }
end

TA.Data.ProfessionSkills = {
    unverified = true,
    prefer     = { "skillinfo" },
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
        -- Measured: not returned by GetProfessions(); shown as a secondary.
        Line(3012, "Comprehension", true),
    },
}
