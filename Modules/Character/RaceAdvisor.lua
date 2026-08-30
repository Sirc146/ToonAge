-- ToonAge/Modules/Character/RaceAdvisor.lua (Anniversary — TBC Classic / 20506)
-- Your racial traits, and specifically the ones that move a number on the
-- Stat Caps tab.
--
-- The split between "this changes your hit cap" and "this is reference text" is
-- enforced in Data/TBCRaces.lua, not here — see that file's header.

-- ─── Module Setup ──────────────────────────────────────────────────────────
local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("RaceAdvisor", M)

-- ─── Render: Character Panel ───────────────────────────────────────────────
function M:Render(content, side)
    L:CharacterSidebar(side)

    local token, localizedName = U.GetPlayerRace()
    local data = TA.Data.RaceTraits[token]
    local mech = TA.Data.RaceMechanics[token]
    local y = -8

    if not data then
        y = L:SectionHeader(content, y, "RACIAL TRAITS")
        y = L:Paragraph(content, y, string.format(
            "No trait data for race token '%s' (%s). Nothing is being guessed — the tab is "
            .. "empty rather than showing another race's traits.", token, localizedName),
            { color = L.C_WARNING })
        L:Finish(content, y)
        return
    end

    -- ── The part that changes your maths ──────────────────────────────
    y = L:SectionHeader(content, y, "AFFECTS YOUR STAT BUDGET",
        "These are counted by the Stat Caps and Gear tabs. Everything below this "
        .. "section is reference only.")

    local hasMechanical = false

    if mech and mech.weaponSkill then
        hasMechanical = true
        local names = {}
        for skillName, bonus in pairs(mech.weaponSkill) do
            names[#names + 1] = string.format("%s +%d", skillName, bonus)
        end
        table.sort(names)

        y = L:DataRow(content, y, {
            label = "Weapon skill bonus", value = mech.source, status = "good", bold = true,
            note = table.concat(names, ", ")
                .. " — five points of weapon skill is one percent less hit needed against "
                .. "a boss, roughly 16 hit rating at level 70 freed for other stats.",
        })
    end

    -- NOTE: a race with BOTH a melee/ranged hit bonus and a spell hit bonus
    -- would only ever show the spell value here — `or` picks one, and the
    -- generic "Hit chance" label does not say which. No current TBC race data
    -- sets both fields at once, but the row silently drops one bonus the day
    -- Data/TBCRaces.lua ever does.
    if mech and (mech.meleeHitPercent or mech.spellHitPercent) then
        hasMechanical = true
        y = L:DataRow(content, y, {
            label = "Hit chance", value = string.format("+%s", U.Pct(mech.spellHitPercent or mech.meleeHitPercent)),
            status = "good", bold = true,
            note = mech.source .. " — already subtracted from every hit target this addon shows you. "
                .. "The client's rating API does not report it, so it is added explicitly.",
        })
    end

    if mech and mech.dodgePercent then
        hasMechanical = true
        y = L:DataRow(content, y, {
            label = "Dodge", value = string.format("+%s", U.Pct(mech.dodgePercent)),
            status = "good", bold = true,
            note = mech.source .. " — already included in your character sheet's dodge number.",
        })
    end

    if not hasMechanical then
        y = L:Paragraph(content, y, string.format(
            "%s has no racial that changes a cap or a rating in TBC. That is not a gap in "
            .. "the data — the traits below are genuinely all utility and flavour.", data.name))
    end

    y = L:Spacer(y, 6)
    y = L:Divider(content, y)

    -- ── Full trait list ───────────────────────────────────────────────
    y = L:SectionHeader(content, y, string.upper(data.name) .. " TRAITS")

    for _, trait in ipairs(data.traits) do
        y = L:DataRow(content, y, {
            label  = trait.n .. (trait.combat and "  |cFFFFD100● combat|r" or ""),
            value  = "",
            status = trait.combat and "neutral" or "dim",
            note   = trait.d,
        })
    end

    -- ── Advice ────────────────────────────────────────────────────────
    y = L:Spacer(y, 6)
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "WHAT IT MEANS FOR YOU")
    y = L:Paragraph(content, y, data.advice, { color = L.C_PRIMARY, size = 10 })

    y = L:Spacer(y, 6)
    y = L:Paragraph(content, y,
        "Trait descriptions are reference text. Exact percentages on resistances and stun "
        .. "effects shifted between expansions — the two things this addon computes with "
        .. "(weapon skill and hit) are the ones shown at the top, and those are TBC-stable.")

    L:Finish(content, y)
end
