-- ToonAge/Modules/Character/ProfessionAdvisor.lua (Anniversary — TBC Classic / 20506)
-- Which professions give combat power, and what yours are actually doing for you.
--
-- Professions come from Core/SkillScan.lua, not GetProfessions() — that API
-- arrived in Wrath (3.0) and does not exist on this client. Calling it is one of
-- the copied-forward assumptions that would crash at login.
--
-- Perk data is matched by English profession name (Data/TBCProfessions.lua). On
-- a localized client the match misses and the row says so, rather than showing a
-- different profession's perks.

-- ─── Module Setup ──────────────────────────────────────────────────────────
local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("ProfessionAdvisor", M)

-- ── Tier Labels ───────────────────────────────────────────────────────
local TIER_LABEL = {
    top       = { text = "top tier",   status = "good" },
    high      = { text = "strong",     status = "good" },
    medium    = { text = "situational",status = "warn" },
    gathering = { text = "gathering",  status = "dim"  },
    secondary = { text = "secondary",  status = "dim"  },
}

-- ─── Render: Character Panel ───────────────────────────────────────────────
function M:Render(content, side)
    L:CharacterSidebar(side)

    local role = U.InferRole()
    local y = -8

    -- ── What you have ─────────────────────────────────────────────────
    -- Note the two-step: GetProfessions returns two values, and
    -- `Scan and Scan:GetProfessions() or {}` would silently discard the second.
    local Scan = TA.SkillScan
    local mine, unmatched = {}, {}
    if Scan then mine, unmatched = Scan:GetProfessions() end

    local primaries, secondaries = {}, {}
    for _, prof in ipairs(mine) do
        table.insert(prof.isSecondary and secondaries or primaries, prof)
    end

    -- ─── Profession Row Renderer ───────────────────────────────────────────
    --- One profession, with its perk bullets underneath.
    local function RenderProfession(yy, prof)
        local perk = TA.Data.Professions[prof.name]
        local tier = perk and TIER_LABEL[perk.tier] or nil
        local rank = TA.Data.GetTier(prof.maxRank)

        -- The maxRank the client reports is the CURRENT tier ceiling, not 375.
        -- Saying "N points to the cap" without naming the tier reads as "N
        -- points until you are finished", which is wrong at every step but the
        -- last — and hides the fact that the next step is a trainer, not a grind.
        --
        -- NOTE: if GetTier() does not recognize prof.maxRank (an off-curve cap —
        -- e.g. a rep- or quest-granted bonus to the skill ceiling), `rank` comes
        -- back nil and all three branches below are skipped. The row still
        -- renders, just silently without any cap/tier-up guidance.
        local note = perk and perk.summary or "No perk data for this name."
        local status = tier and tier.status or "dim"

        if rank and prof.rank >= prof.maxRank and rank.nextName then
            note = note .. string.format(
                "  |cFFFF9A1A%s maxed — train %s (to %d) at %s.|r",
                rank.name, rank.nextName, rank.nextCap, rank.where)
            status = "warn"
        elseif rank and prof.rank < prof.maxRank then
            note = note .. string.format("  |cFF888780%d to the %s cap.|r",
                prof.maxRank - prof.rank, rank.name)
        elseif rank and not rank.nextName then
            note = note .. "  |cFF4AFF7AMaster — fully trained.|r"
        end

        local tierTag = rank and ("  |cFF555049" .. rank.name .. "|r") or ""

        yy = L:DataRow(content, yy, {
            label  = prof.name .. (tier and ("  |cFF555049" .. tier.text .. "|r") or "") .. tierTag,
            value  = string.format("%d / %d", prof.rank, prof.maxRank),
            status = status,
            bold   = true,
            note   = note,
        })

        if perk then
            for _, line in ipairs(perk.perks) do
                yy = L:Bullet(content, yy, line, { color = L.C_SECONDARY })
            end
            if perk.note then
                yy = L:Bullet(content, yy, perk.note, { color = L.C_DIM, marker = "›" })
            end
            yy = L:Spacer(yy, 4)
        end
        return yy
    end

    -- ── Primaries ─────────────────────────────────────────────────────
    local level    = U.GetPlayerLevel()
    local minLevel = TA.Data.PROFESSION_MIN_LEVEL or 5
    local slots    = TA.Data.PRIMARY_SLOTS or 2

    y = L:SectionHeader(content, y, "YOUR PROFESSIONS",
        string.format("%d of %d primary slots used.", math.min(#primaries, slots), slots))

    if level < minLevel then
        -- The brief has this addon starting at level 1, so this is a state a
        -- real user hits. Recommending a profession they cannot learn for
        -- another four levels is worse than saying nothing.
        y = L:Paragraph(content, y, string.format(
            "|cFFFF9A1AProfessions unlock at level %d.|r You are level %d — %d to go. "
            .. "That gate covers everything: primaries, gathering and the secondary skills alike.",
            minLevel, level, minLevel - level), { color = L.C_WARNING })
        y = L:Paragraph(content, y,
            "The recommendation below is still worth reading now, so you know which trainer "
            .. "to walk to the moment you ding.")
    elseif #primaries == 0 then
        y = L:Paragraph(content, y, string.format(
            "No primary professions learned yet — both slots are free, and you have been "
            .. "eligible since level %d. You can swap later, but unlearning wipes the skill, "
            .. "so the first pick is worth getting right.", minLevel))
    else
        for _, prof in ipairs(primaries) do
            y = RenderProfession(y, prof)
        end
    end

    -- ── Secondaries ───────────────────────────────────────────────────
    -- Cooking, First Aid and Fishing do not consume a primary slot, so they are
    -- shown separately rather than padding the "2 of 2" count.
    if level >= minLevel then
        y = L:Spacer(y, 4)
        y = L:SectionHeader(content, y, "SECONDARY SKILLS",
            "All three are learnable and none of them uses a primary slot — there is no "
            .. "reason not to have every one.")

        for _, prof in ipairs(secondaries) do
            y = RenderProfession(y, prof)
        end

        -- Name what is missing. A silent absence reads as "the addon didn't find
        -- it"; a named absence is a to-do.
        local have = {}
        for _, prof in ipairs(secondaries) do have[prof.name] = true end

        local missing = {}
        for _, name in ipairs({ "Cooking", "First Aid", "Fishing" }) do
            if not have[name] then missing[#missing + 1] = name end
        end

        if #missing > 0 then
            y = L:Paragraph(content, y, string.format(
                "|cFFFF9A1ANot learned yet:|r %s. Free to pick up, and Cooking in particular "
                .. "stops being optional once you are raiding — the Well Fed buffs are worth "
                .. "20-30 of a stat for the whole night.", table.concat(missing, ", ")),
                { color = L.C_WARNING })
        end
    end

    -- ── Anything profession-shaped we could not name ──────────────────
    if #unmatched > 0 then
        local names = {}
        for _, line in ipairs(unmatched) do
            names[#names + 1] = string.format("%s (%d/%d)", line.name, line.rank, line.maxRank)
        end
        y = L:Spacer(y, 4)
        y = L:Paragraph(content, y, string.format(
            "|cFF888780Not shown as professions:|r %s. These are skill lines shaped like a "
            .. "profession — riding and languages both are — but not on the known list, so "
            .. "they are named rather than guessed at. If one of these IS a profession, this "
            .. "is a non-English client and the name lookup needs mapping.",
            table.concat(names, ", ")), { color = L.C_DIM })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ── What you should have ──────────────────────────────────────────
    local advice = TA.Data.ProfessionAdvice[role]
    y = L:SectionHeader(content, y, "BEST FOR A " .. role)

    if advice then
        y = L:DataRow(content, y, {
            label = "Recommended pair", value = table.concat(advice.best, " + "),
            status = "good", bold = true, note = advice.why,
        })
        y = L:Paragraph(content, y, "Also good: " .. table.concat(advice.also, ", "))
    end

    -- ─── GATHER NOW, CRAFT AT 70 ───────────────────────────────────────────
    local plan = TA.Data.GetLevelingPlan(role)
    if plan then
        y = L:Spacer(y, 6)
        y = L:Divider(content, y)

        local atCap = level >= 70
        y = L:SectionHeader(content, y,
            atCap and "TIME TO SWAP" or "GATHER NOW, CRAFT AT 70",
            atCap and "You are at level cap — this is the point the plan was built for."
                   or "Level gatherers while you level, bank the mats, and arrive at 70 able "
                      .. "to skill up a craft without buying a thing.")

        if plan.moot then
            -- The caster/healer case. Saying "gather Mining" here would be
            -- actively wrong advice, so the plan reports that it does not apply.
            y = L:DataRow(content, y, {
                label  = "Take from level 5",
                value  = table.concat(plan.targets, " + "),
                status = "good", bold = true,
                note   = "Never swap. These two are the exception to the whole plan.",
            })
            y = L:Paragraph(content, y, string.format(
                "|cFF4AFF7A%s do not need a gathering profession at any point.|r Cloth drops "
                .. "off humanoids the entire way up, and Enchanting feeds itself on the quest "
                .. "greens you would have vendored. They supply themselves AS you level, which "
                .. "is why you take them at the start rather than banking for them — there is "
                .. "nothing to bank and nothing to drop.",
                table.concat(plan.targets, " and ")), { color = L.C_SUCCESS })
            y = L:Bullet(content, y,
                "Levelling them alongside your character is also cheaper than levelling them "
                .. "at 70: you consume the cloth and greens as they arrive, instead of buying "
                .. "375 skill points' worth at once.", { color = L.C_SECONDARY })
        else
            local gatherList = {}
            for _, f in ipairs(plan.feeders) do gatherList[#gatherList + 1] = f end
            if plan.spare then gatherList[#gatherList + 1] = plan.spare end

            y = L:DataRow(content, y, {
                label  = atCap and "Drop these" or "Take these now",
                value  = table.concat(gatherList, " + "),
                status = atCap and "warn" or "good", bold = true,
                note   = plan.spare
                    and string.format("%s feeds your target crafts directly. %s is the spare "
                        .. "slot — it feeds nothing you want, so it is there purely to sell.",
                        table.concat(plan.feeders, " and "), plan.spare)
                    or string.format("Both feed your target crafts directly: %s.",
                        table.concat(plan.targets, " and ")),
            })

            y = L:DataRow(content, y, {
                label  = atCap and "Take these instead" or "Swap to these at 70",
                value  = table.concat(plan.targets, " + "),
                status = atCap and "good" or "neutral", bold = true,
                note   = atCap
                    and "Bank the mats first. Unlearning wipes the skill to zero, so make sure "
                        .. "you have what you need before you drop anything."
                    or "Bank everything you gather. You will skill these from 1 to 375 on "
                       .. "mats you already own instead of gold you do not.",
            })

            for _, caveat in ipairs(plan.caveats) do
                y = L:Bullet(content, y, caveat, { color = L.C_WARNING, marker = "!" })
            end

            -- The core argument for the plan, stated once and plainly: two
            -- crafting professions at 70 means zero gatherers at 70.
            y = L:Bullet(content, y, string.format(
                "At 70 you will hold %s and |cFFFFD100no gathering profession at all|r. Every "
                .. "mat for both skill-ups has to be banked or bought. That is the whole "
                .. "argument for gathering first — it is the cheaper route, not merely an "
                .. "alternative one.", table.concat(plan.targets, " + ")),
                { color = L.C_PRIMARY, marker = "★" })

            y = L:Bullet(content, y,
                "Unlearning is permanent in the sense that matters: the skill drops to zero. "
                .. "There is no parking a profession and picking it back up where you left it.",
                { color = L.C_SECONDARY })

            if not atCap then
                y = L:Bullet(content, y, string.format(
                    "You are level %d. Nothing needs deciding until 70 — gather until then.",
                    level), { color = L.C_SECONDARY })
            end
        end
    end

    y = L:Spacer(y, 6)
    y = L:Divider(content, y)

    -- ── Reference table ───────────────────────────────────────────────
    y = L:SectionHeader(content, y, "ALL PROFESSIONS BY COMBAT VALUE")

    -- WARN: `order` is the complete list of tiers this table will ever show.
    -- Any profession whose data.tier string is not one of these five keys
    -- never enters `byTier[tier]` below, so the whole group silently vanishes
    -- from the reference list instead of appearing miscolored — a typo or a
    -- new tier added in Data/TBCProfessions.lua fails invisibly here.
    local order = { "top", "high", "medium", "gathering", "secondary" }
    local byTier = {}
    for name, data in pairs(TA.Data.Professions) do
        byTier[data.tier] = byTier[data.tier] or {}
        table.insert(byTier[data.tier], { name = name, data = data })
    end

    local haveIt = {}
    for _, prof in ipairs(mine) do haveIt[prof.name] = true end

    for _, tier in ipairs(order) do
        local group = byTier[tier]
        if group then
            table.sort(group, function(a, b) return a.name < b.name end)
            local label = TIER_LABEL[tier]
            for _, entry in ipairs(group) do
                y = L:DataRow(content, y, {
                    label  = entry.name .. (haveIt[entry.name] and "  |cFFFFD100● yours|r" or ""),
                    value  = label and label.text or tier,
                    status = label and label.status or "dim",
                    note   = entry.data.summary,
                })
            end
        end
    end

    y = L:Spacer(y, 6)
    y = L:Paragraph(content, y,
        "Three items commonly listed as TBC profession perks belong to Wrath and are absent "
        .. "here: Blacksmithing socket recipes, Alchemy's Mixology, and the Herbalism / Mining / "
        .. "Skinning self-buffs. Engineering, which most TBC lists omit, is the strongest of them all.")

    L:Finish(content, y)
end

-- ─── Slash Commands ────────────────────────────────────────────────────────
M.SlashCommands = {
    profs = function(self)
        local Scan = TA.SkillScan
        local mine = Scan and Scan:GetProfessions() or {}
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Professions ━━━|r")
        if #mine == 0 then
            TA:Raw(TA.LOG.OUTPUT, "  None found.")
            return
        end
        for _, prof in ipairs(mine) do
            local perk = TA.Data.Professions[prof.name]
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s %d/%d — %s",
                prof.name, prof.rank, prof.maxRank,
                perk and perk.summary or "no perk data"))
        end
    end,
}
