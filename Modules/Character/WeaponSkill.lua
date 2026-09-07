-- ToonAge/Modules/Character/WeaponSkill.lua (Anniversary — TBC Classic / 20506)
-- Weapon skill per weapon type, and what each missing point costs you.
--
-- Weapon skill is the mechanic with no retail equivalent, and the one most
-- likely to be quietly wrecking a character: five points under cap against a
-- boss is two extra percent of misses on top of a raised hit cap, and nothing
-- in the default UI tells you.
--
-- The enumeration side effect (expanding skill headers) and why it is restored
-- is documented in Core/SkillScan.lua.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("WeaponSkill", M)

-- ─── ANALYSIS ────────────────────────────────────────────────────────────────

--- What a skill deficit costs against the current cap target.
--- @return number extraMissPct, number extraDodgePct
-- NOTE: also returns `ctx` (the active TBCStats context table) as a third value,
-- undocumented above — every call site destructures it as `miss, dodge, ctx`.
local function CostOfDeficit(skill)
    local S = TA.TBCStats
    local level = U.GetPlayerLevel()
    local ctx = S:ActiveContext()
    local tDefense = S:TargetDefense(level + ctx.delta)
    local maxSkill = level * 5

    local missAt   = S:MeleeMissChance(skill, tDefense)
    local missBest = S:MeleeMissChance(maxSkill, tDefense)
    local dodgeAt   = S:TargetDodgeChance(skill, tDefense)
    local dodgeBest = S:TargetDodgeChance(maxSkill, tDefense)

    return missAt - missBest, dodgeAt - dodgeBest, ctx
end

--- Equipped weapon skill lines, so they can be flagged in the list.
local function EquippedSkillNames()
    local Scan = TA.SkillScan
    local out = {}
    if not Scan then return out end

    local eq = Scan:GetEquippedWeaponSkill()
    local map = TA.Data.SubTypeToSkill or {}
    if eq.mainSubType and map[eq.mainSubType] then out[map[eq.mainSubType]] = "main hand" end
    if eq.offSubType  and map[eq.offSubType]  then
        out[map[eq.offSubType]] = out[map[eq.offSubType]] and "both hands" or "off hand"
    end
    return out, eq
end

-- ─── RENDER ──────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L:CharacterSidebar(side)

    local Scan = TA.SkillScan
    local level = U.GetPlayerLevel()
    local maxSkill = level * 5
    local y = -8

    y = L:SectionHeader(content, y, "WEAPON SKILL",
        string.format("Maximum at level %d is %d. Every point below that adds miss "
            .. "chance AND target dodge — it costs you twice.", level, maxSkill))

    if not Scan then
        L:EmptyState(content, "The skill scanner is not loaded.")
        return
    end

    local equipped, eq = EquippedSkillNames()
    local scan = Scan:Scan()

    -- ── Equipped weapons first: this always works, with no side effects, even
    --    when the skill-list scan comes back empty.
    if eq and (eq.main or eq.off) then
        y = L:SectionHeader(content, y, "IN YOUR HANDS")

        local function EquippedRow(yy, slotName, info, subType)
            if not info then return yy end
            local deficit = math.max(maxSkill - info.total, 0)
            local status = deficit == 0 and "good" or (deficit >= 5 and "bad" or "warn")
            local note
            if deficit == 0 then
                note = "At maximum for your level."
            else
                local miss, dodge, ctx = CostOfDeficit(info.total)
                note = string.format(
                    "%d under. Against %s that is +%s miss and +%s target dodge.",
                    deficit, ctx.label:lower(), U.Pct(miss), U.Pct(dodge))
            end
            local value = string.format("%d / %d", info.total, maxSkill)
            if info.mod and info.mod > 0 then
                value = value .. string.format("  |cFF4AFF7A(+%d)|r", info.mod)
            end
            yy = L:DataRow(content, yy, {
                label = slotName .. (subType and ("  |cFF555049" .. subType .. "|r") or ""),
                value = value, status = status, bold = true, note = note,
            })
            return yy
        end

        y = EquippedRow(y, "Main hand", eq.main, eq.mainSubType)
        y = EquippedRow(y, "Off hand",  eq.off,  eq.offSubType)

        if eq.dualWield then
            y = L:Spacer(y, 4)
            y = L:Paragraph(content, y,
                "|cFFFF9A1ADual wielding|r adds a flat 19% miss to white swings that no amount "
                .. "of hit rating removes. Gear to the special-attack cap on the Stat Caps tab; "
                .. "chasing the white-swing number is a trap.")
        end
        y = L:Spacer(y, 6)
    end

    -- ── Full skill list ───────────────────────────────────────────────
    if #scan.weapons == 0 then
        y = L:Paragraph(content, y,
            "No weapon skill lines could be read. That usually means the skill window "
            .. "headers are collapsed and this build was not permitted to expand them — "
            .. "the equipped-weapon numbers above are unaffected and remain accurate.",
            { color = L.C_WARNING })
        L:Finish(content, y)
        return
    end

    local provenance = {}
    if scan.weaponHeaderSource then provenance[#provenance + 1] = scan.weaponHeaderSource end
    if scan.expandedSomething then
        provenance[#provenance + 1] = "skill headers were expanded to read this list and put back as they were"
    end

    y = L:SectionHeader(content, y, "ALL WEAPON SKILLS",
        #provenance > 0 and (table.concat(provenance, "; ")) or nil)

    local raceToken = U.GetPlayerRace()

    for _, line in ipairs(scan.weapons) do
        -- WARN: `line.rank` alone ignores `line.modifier` (Core/SkillScan.lua ReadLine
        -- captures it separately from GetSkillLineInfo). The equipped-weapon section
        -- above uses UnitAttackBothHands' own base+mod total, so a temporary skill
        -- bonus (enchant, consumable) can make "IN YOUR HANDS" and this full list
        -- disagree on the same weapon type's current skill.
        local deficit = math.max(line.maxRank - line.rank, 0)
        -- WARN: whether `line.rank` already bakes in the racial bonus is unverified —
        -- Core/SkillScan.lua's own file header lists "GetSkillLineInfo return order" as
        -- UNVERIFIED on 20506. If it does, adding `racial` again below (the "+N racial"
        -- badge, and `line.rank + racial` fed to CostOfDeficit two lines down) double
        -- counts it, understating the real deficit and its miss/dodge cost.
        local racial  = TA.Data.GetRacialWeaponSkill(raceToken, line.name)
        local status  = deficit == 0 and "good" or (deficit >= 5 and "bad" or "warn")

        local label = line.name
        if equipped[line.name] then
            label = label .. "  |cFFFFD100● " .. equipped[line.name] .. "|r"
        end
        if racial > 0 then
            label = label .. string.format("  |cFF4AFF7A+%d racial|r", racial)
        end

        local note
        if deficit == 0 then
            note = racial > 0
                and "Capped, and your racial bonus pushes you above the target's defense — "
                    .. "that is a genuinely lower hit cap."
                or nil
        else
            local miss, dodge, ctx = CostOfDeficit(line.rank + racial)
            note = string.format("%d under maximum — +%s miss, +%s dodge vs %s.",
                deficit, U.Pct(miss), U.Pct(dodge), ctx.label:lower())
        end

        y = L:DataRow(content, y, {
            label  = label,
            value  = string.format("%d / %d", line.rank, line.maxRank),
            status = status,
            note   = note,
        })
    end

    -- ── Advice ────────────────────────────────────────────────────────
    y = L:Spacer(y, 6)
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "LEVELLING A WEAPON SKILL")

    y = L:Bullet(content, y,
        "Skill only ticks up when you land a hit on something that still gives you "
        .. "experience or reputation. Grey mobs give nothing — a target dummy will not do it either.")
    y = L:Bullet(content, y,
        "The chance per swing falls as you approach the cap, so the last few points "
        .. "are the slow ones. Start early rather than at 70 with a new weapon type.")
    y = L:Bullet(content, y,
        "A new weapon type starts at 1 and has to be levelled from scratch. Picking up "
        .. "an upgrade in a weapon class you have never used is a real, temporary DPS loss.")
    y = L:Bullet(content, y,
        "Racial bonuses stack on top of the cap, so a Human with swords or an Orc with "
        .. "axes reaches a lower effective hit requirement than anyone else can.")

    local m = TA.Data.RaceMechanics[raceToken]
    if m and m.weaponSkill then
        y = L:Spacer(y, 4)
        local names = {}
        for skillName in pairs(m.weaponSkill) do names[#names + 1] = skillName end
        table.sort(names)
        y = L:Paragraph(content, y, string.format(
            "|cFF4AFF7AYour race favours:|r %s (%s). Using one of these lowers the hit "
            .. "percentage you need to reach.", table.concat(names, ", "), m.source),
            { color = L.C_SUCCESS })
    end

    L:Finish(content, y)
end

M.SlashCommands = {
    weaponskill = function(self)
        local Scan = TA.SkillScan
        if not Scan then return end
        local maxSkill = U.GetPlayerLevel() * 5
        local scan = Scan:Scan(true)
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Weapon skills ━━━|r")
        if #scan.weapons == 0 then
            TA:Raw(TA.LOG.OUTPUT, "  Could not read the skill list.")
            return
        end
        for _, line in ipairs(scan.weapons) do
            local deficit = maxSkill - line.rank
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s %s  %d/%d",
                deficit <= 0 and "|cFF4AFF7A✓|r" or "|cFFFF9A1A→|r",
                line.name, line.rank, line.maxRank))
        end
    end,
}
