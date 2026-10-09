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

local function Line(id, name, secondary, gate)
    local row = { id = id, name = name, secondary = secondary and true or false }
    if type(gate) == "table" then
        row.class = gate.class
        row.minLevel = gate.minLevel
    end
    return row
end

TA.Data.ProfessionSkills = {
    unverified = true,
    prefer     = { "skillinfo" },
    cap        = 300,
    headers    = { "Professions", "Secondary Skills" },
    -- Not on this client. The reader hides a reported line whose name is here.
    absent = { "Jewelcrafting", "Inscription", "Archaeology" },
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
        -- Mage only, and only from level 6. Other classes do not see the row.
        Line(3012, "Comprehension", true, { class = "MAGE", minLevel = 6 }),
        -- A rogue skill, matched by the name the client reports. No skill
        -- line id has been measured, so this row does not invent one.
        Line(nil, "Poisons", false, { class = "ROGUE" }),
    },
}
