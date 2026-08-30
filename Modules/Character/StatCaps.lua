-- ToonAge/Modules/Character/StatCaps.lua (Anniversary — TBC Classic / 20506)
-- "You need X more Hit." The tab this addon exists for.
--
-- Every number shown here is computed from your level, your weapon skill, your
-- race and the target you pick — never read out of a level-70 lookup table.
-- See the header of Core/TBCStats.lua for why that distinction matters.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("StatCaps", M)

-- ─── GATHERING THE INPUTS ────────────────────────────────────────────────────

-- Context resolution lives in Core/TBCStats.lua so PvP mode cannot be honoured
-- in some tabs and forgotten in others.
local function ContextKey()
    return TA.TBCStats:ActiveContextKey()
end

--- All hit that GetCombatRatingBonus cannot see — racial AND talent — with the
--- breakdown so the tab can attribute every point instead of showing a total.
--- @return number meleeBonus, number spellBonus, table sources
local function BonusHit()
    return TA.TBCStats:GetBonusHit()
end

--- Weapon skill for the weapon actually equipped, and how sure we are.
--- @return number skill, boolean measured, string label
local function ActiveWeaponSkill()
    local Scan = TA.SkillScan
    if not Scan then return U.GetPlayerLevel() * 5, false, "assumed maximum" end

    local skill, measured = Scan:GetActiveWeaponSkill()
    if measured then
        return skill, true, "from your equipped main hand"
    end
    return skill, false, "assumed maximum — no weapon equipped, or the API did not answer"
end

local function IsDualWielding()
    local Scan = TA.SkillScan
    if not Scan then return false end
    local eq = Scan:GetEquippedWeaponSkill()
    return eq.dualWield or false
end

--- Format a percentage shortfall as "X.X% (about N rating)" when a conversion
--- is available, and as a bare percentage when it is not. The rating half is
--- omitted rather than guessed — see Core/TBCStats.lua GetRatingPerPercent.
local function ShortfallText(ratingKey, pctNeeded)
    if pctNeeded <= 0 then return "" end

    local rating, source = TA.TBCStats:PercentToRating(ratingKey, pctNeeded)
    if not rating then
        return string.format("%s more", U.Pct(pctNeeded))
    end

    local qualifier = (source == "derived") and "" or " approx."
    return string.format("%s more  (%s%s rating)", U.Pct(pctNeeded), U.Rating(rating), qualifier)
end

-- ─── THE CAPS ────────────────────────────────────────────────────────────────

--- Assemble every cap relevant to this character. Returned as data so the chat
--- command and the tab render the same numbers from the same source.
function M:Collect()
    local S   = TA.TBCStats
    local ctxKey = ContextKey()
    -- NOTE: U.InferRole() (Core/Utils.lua) infers HEALER only from a manual /ta role
    -- override — it is never inferred from class or talent tree. A Holy Paladin,
    -- Restoration Druid or Restoration Shaman without a shield equipped comes back as
    -- "MELEE" here, so `physical` below is true for them and this tab shows melee hit
    -- and expertise cap targets that are meaningless to a pure healer, instead of the
    -- noCaps message a HEALER role gets further down.
    local role = U.InferRole()

    local skill, skillMeasured, skillLabel = ActiveWeaponSkill()
    local dualWield = IsDualWielding()
    local meleeBonus, spellBonus, hitSources = BonusHit()

    local out = {
        context       = S:GetContext(ctxKey),
        role          = role,
        weaponSkill   = skill,
        skillMeasured = skillMeasured,
        skillLabel    = skillLabel,
        dualWield     = dualWield,
        hitSources    = hitSources,
        meleeBonus    = meleeBonus,
        spellBonus    = spellBonus,
        caps          = {},
    }

    local physical = (role == "MELEE" or role == "RANGED" or role == "TANK")
    local magical  = (role == "CASTER")

    if physical then
        out.caps.meleeHit = S:GetMeleeHitCap({
            contextKey = ctxKey, weaponSkill = skill,
            dualWield = dualWield, bonusHitPercent = meleeBonus,
        })
        out.caps.expertise = S:GetExpertiseCap({ contextKey = ctxKey, weaponSkill = skill })
    end

    if magical then
        out.caps.spellHit = S:GetSpellHitCap({ contextKey = ctxKey, bonusHitPercent = spellBonus })
    end

    -- Defense's uncrittable threshold is a PvE mechanic. Player crits are reduced
    -- by resilience, not by defense skill, and there is no crit-immunity number
    -- to reach against a player at all. Showing a 490 defense target in PvP mode
    -- would send a tank chasing a stat that does nothing to them in an arena.
    out.pvp = TA.db and TA.db.pvpMode or false

    if role == "TANK" and not out.pvp then
        out.caps.defense = S:GetDefenseCap({ contextKey = ctxKey })
        out.caps.armor   = S:GetArmorInfo({ contextKey = ctxKey })
    end

    if out.pvp then
        out.resilience = S:GetResilience()
    end

    -- A healer needs neither hit nor expertise, and saying so is more useful
    -- than showing an empty tab.
    out.noCaps = (role == "HEALER")

    return out
end

-- ─── RENDER ──────────────────────────────────────────────────────────────────

local function RenderContextPicker(content, y, activeKey)
    local S = TA.TBCStats

    -- PvP mode pins the target: an enemy player is your level, full stop. The
    -- picker is shown greyed rather than hidden, so it is obvious WHY the caps
    -- moved when the mode was switched.
    if TA.db and TA.db.pvpMode then
        y = L:SectionHeader(content, y, "TARGET — |cFFFF6E6EPVP|r",
            "Pinned to same-level: an enemy player is your level. There is no +3 target "
            .. "in an arena, so the raid figures do not apply here at all.")
        y = L:Paragraph(content, y,
            "|cFFFFD100/ta pvp|r switches back to PvE and unpins this.", { color = L.C_SECONDARY })
        return L:Spacer(y, 6)
    end

    y = L:SectionHeader(content, y, "TARGET",
        "Every cap below is relative to what you are fighting. This is not a preference — "
        .. "the hit cap against a same-level mob and against a raid boss are different numbers.")

    -- NOTE: the "3 * 6" gap and "/ 4" width below hardcode S.CONTEXTS (Core/TBCStats.lua)
    -- having exactly 4 entries. Adding or removing a context there without updating this
    -- math will overlap or gap the row of buttons instead of erroring.
    local w = L:Width(content)
    local btnW = math.floor((w - 3 * 6) / 4)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(w, 24)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, math.floor(y))

    for i, ctx in ipairs(S.CONTEXTS) do
        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(btnW, 22)
        btn:SetPoint("TOPLEFT", row, "TOPLEFT", math.floor((i - 1) * (btnW + 6)), 0)

        local active = (ctx.key == activeKey)
        if TA._ApplyBackdrop then
            if active then
                TA._ApplyBackdrop(btn, 0.16, 0.13, 0.02, 1.00, 1.00, 0.82, 0.00, 1.00)
            else
                TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1.00, 0.30, 0.28, 0.24, 1.00)
            end
        end

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        lbl:SetPoint("CENTER")
        lbl:SetText(ctx.label)
        if active then
            lbl:SetTextColor(1, 0.82, 0, 1)
        else
            lbl:SetTextColor(0.62, 0.59, 0.55, 1)
        end

        btn:SetScript("OnClick", function()
            TA.db.capContext = ctx.key
            if TA.UI then TA.UI:Refresh() end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ctx.label, 1, 0.82, 0)
            GameTooltip:AddLine(ctx.note, 0.9, 0.9, 0.9, true)
            GameTooltip:AddLine("Target level " .. (U.GetPlayerLevel() + ctx.delta), 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    y = y - 30

    local auto = TA.db and TA.db.capContext == "auto"
    y = L:Paragraph(content, y, auto
        and ("|cFF4AFF7AAuto|r — following your level. Below 70 that means same-level mobs, "
             .. "at 70 it switches to raid bosses. Click a button above to pin it.")
        or  ("Pinned. |cFFFFD100/ta context auto|r to follow your level again."))

    return L:Spacer(y, 6)
end

--- Resilience block. Deliberately NOT a CapBar: resilience has no cap and no
--- breakpoint, and drawing it as progress toward a target would invent one.
--- A function rather than inline code because healers take an early return out
--- of Render and still need this — PvP healers are the ones who need it most.
local function RenderResilience(content, y, res)
    if not res then return y end

    y = L:Spacer(y, 4)
    y = L:SectionHeader(content, y, "RESILIENCE",
        "No cap and no breakpoint — pure mitigation, shown as what it currently "
        .. "buys you rather than as progress toward a number.")

    y = L:DataRow(content, y, {
        label = "Resilience rating", value = U.Rating(res.rating), bold = true,
        status = res.hasAny and "good" or "bad",
        note = res.hasAny
            and (res.measured and "Read from the client."
                 or "|cFFFF9A1AConverted from the level formula|r — GetCombatRatingBonus did not answer.")
            or "|cFFFF4444You have none.|r Any resilience beats none, and the honor-gear "
               .. "floor is cheap and needs no arena rating at all.",
    })

    if res.hasAny then
        y = L:DataRow(content, y, { label = "Chance to be crit",
            value = "-" .. U.Pct(res.critReduction), status = "good" })
        y = L:DataRow(content, y, { label = "Damage from crits that land",
            value = "-" .. U.Pct(res.critDamageReduction), status = "good",
            note = "Twice the crit-chance reduction. Against burst specs this half matters "
                .. "more, because it applies to every crit you fail to avoid." })
        y = L:DataRow(content, y, { label = "Damage over time taken",
            value = "-" .. U.Pct(res.dotReduction), status = "good" })
    end

    return L:Spacer(y, 4)
end

function M:Render(content, side)
    L:CharacterSidebar(side)

    local data = self:Collect()
    local y = -8

    y = RenderContextPicker(content, y, data.context.key)
    y = L:Divider(content, y)

    -- ── Weapon skill note: it changes the hit and expertise caps, so it is
    --    stated before the caps that depend on it rather than buried later.
    local maxSkill = U.GetPlayerLevel() * 5
    if data.weaponSkill < maxSkill then
        y = L:Paragraph(content, y, string.format(
            "|cFFFF9A1AYour weapon skill is %d of a possible %d.|r Each missing point adds "
            .. "miss chance and raises every cap below. Level the weapon before you gear for the gap.",
            data.weaponSkill, maxSkill), { color = L.C_WARNING })
        y = L:Spacer(y, 4)
    end

    if data.noCaps then
        y = L:SectionHeader(content, y, "NO OFFENSIVE CAPS APPLY",
            "You are playing a healing role.")
        y = L:Paragraph(content, y,
            "Healing spells cannot miss, so spell hit is worth exactly nothing to you — "
            .. "if an item's only advantage is hit rating, it is a downgrade. There is no "
            .. "expertise or defense target either.")
        y = L:Spacer(y, 6)
        y = L:Bullet(content, y, "Mana per 5 seconds is close to healing power in value — see the Gear tab.")
        y = L:Bullet(content, y, "If you off-tank or off-DPS, set your role with |cFFFFD100/ta role|r.")
        -- Healers return early, but a PvP healer is the single biggest consumer
        -- of the resilience readout — they are the kill target in most comps.
        y = RenderResilience(content, y, data.resilience)
        L:Finish(content, y)
        return
    end

    -- ── Melee / ranged hit ────────────────────────────────────────────
    local hit = data.caps.meleeHit
    if hit then
        local label = (data.role == "RANGED") and "Ranged Hit" or "Melee Hit"
        local note
        if hit.capped then
            note = string.format("Capped. %s over — that surplus is doing nothing, spend it elsewhere.",
                U.Pct(hit.current - hit.cap))
        else
            note = "Need " .. ShortfallText("HIT_MELEE", hit.needed)
        end

        local tooltip = {
            string.format("Target: level %d (%s)", hit.targetLevel, hit.context.label),
            string.format("Weapon skill %d vs target defense %d",
                hit.weaponSkill, TA.TBCStats:TargetDefense(hit.targetLevel)),
            string.format("Base miss on specials: %s", U.Pct(hit.cap)),
        }
        if hit.fromOther and hit.fromOther > 0 then
            table.insert(tooltip, string.format("Includes %s from %s",
                U.Pct(hit.fromOther), "talents and racials — see the breakdown below"))
        end
        if hit.dualWield then
            table.insert(tooltip, string.format(
                "Dual wielding adds %s miss to white swings only. That is not reachable "
                .. "with gear and you should not try — gear to the %s special-attack cap.",
                U.Pct(hit.whiteCap - hit.cap), U.Pct(hit.cap)))
        end

        y = L:CapBar(content, y, {
            label   = label,
            value   = string.format("%s / %s", U.Pct(hit.current), U.Pct(hit.cap)),
            current = hit.current, cap = hit.cap,
            capped  = hit.capped, urgent = hit.needed > 3,
            note    = note, tooltip = tooltip,
        })
    end

    -- ── Spell hit ─────────────────────────────────────────────────────
    local shit = data.caps.spellHit
    if shit then
        local note
        if shit.capped then
            note = string.format("Capped. %s over.", U.Pct(shit.current - shit.cap))
        else
            note = "Need " .. ShortfallText("HIT_SPELL", shit.needed)
        end

        local tooltip = {
            string.format("Target: level %d (%s)", shit.targetLevel, shit.context.label),
            string.format("Base spell miss at this level gap: %s", U.Pct(shit.baseMiss)),
            "1% of that miss cannot be removed by hit at any gear level, which is why "
                .. "the cap is one point below the base miss.",
        }
        if shit.fromOther and shit.fromOther > 0 then
            table.insert(tooltip, string.format("Includes %s from %s",
                U.Pct(shit.fromOther), "talents and racials — see the breakdown below"))
        end
        table.insert(tooltip, "Talent-granted hit is not counted here — the client does not "
            .. "report it through the rating API.")

        y = L:CapBar(content, y, {
            label   = "Spell Hit",
            value   = string.format("%s / %s", U.Pct(shit.current), U.Pct(shit.cap)),
            current = shit.current, cap = shit.cap,
            capped  = shit.capped, urgent = shit.needed > 5,
            note    = note, tooltip = tooltip,
        })
    end

    -- ── Expertise ─────────────────────────────────────────────────────
    local exp = data.caps.expertise
    if exp then
        local note
        if exp.capped then
            note = "Dodge is fully removed. Parry only matters if you are in front of the target."
        else
            local rating, source = TA.TBCStats:PercentToRating("EXPERTISE",
                (exp.cap - exp.current) * 0.25)
            if rating then
                note = string.format("Need %d more expertise (%s%s rating)",
                    exp.needed, U.Rating(rating), source == "derived" and "" or " approx.")
            else
                note = string.format("Need %d more expertise", exp.needed)
            end
        end

        y = L:CapBar(content, y, {
            label   = "Expertise",
            value   = string.format("%d / %d", exp.current, exp.cap),
            current = exp.current, cap = exp.cap,
            capped  = exp.capped, urgent = false,
            note    = note,
            tooltip = {
                string.format("Target dodges %s at your weapon skill (%d vs %d defense)",
                    U.Pct(exp.targetDodge), exp.weaponSkill,
                    TA.TBCStats:TargetDefense(exp.targetLevel)),
                "Each point of expertise removes 0.25% avoidance.",
                string.format("You currently remove %s.", U.Pct(exp.pctRemoved)),
                string.format("Attacking from the front you would need %d to also cover parry — "
                    .. "almost nobody gears for that.", exp.frontCap),
                "The build brief quotes 214 rating for this cap. That is the level 80 figure; "
                    .. "at 70 it is roughly 102.",
            },
        })
    end

    -- ── Defense ───────────────────────────────────────────────────────
    local def = data.caps.defense
    if def then
        local note
        if def.capped then
            note = string.format("Uncrittable, with %d defense to spare — that surplus is "
                .. "worth much less than the point that got you here.",
                def.current - def.cap)
        else
            note = string.format("Need %d more defense skill — you can still be critically hit "
                .. "for %s of your health bar at a time.",
                def.needed, U.Pct(def.critTaken - def.critRemoved))
        end

        y = L:CapBar(content, y, {
            label   = "Defense (uncrittable)",
            value   = string.format("%d / %d", def.current, def.cap),
            current = def.current, cap = def.cap,
            capped  = def.capped, urgent = not def.capped,
            note    = note,
            tooltip = {
                string.format("Base %d from level, +%d from defense rating",
                    def.baseDefense, def.fromRating),
                string.format("A level %d attacker crits you for %s before mitigation",
                    def.targetLevel, U.Pct(def.critTaken)),
                "Each defense point above your level's base removes 0.04% crit taken.",
                "The cap is playerLevel*5 + 140 — 490 at level 70, for heroics and raids "
                    .. "alike. The build brief's separate '540 raids' figure is the level 80 number.",
            },
        })
    end

    -- ── Armor ─────────────────────────────────────────────────────────
    local armor = data.caps.armor
    if armor then
        y = L:CapBar(content, y, {
            label   = "Armor mitigation",
            value   = string.format("%s of %s", U.Pct(armor.reduction), U.Pct(armor.capPct)),
            current = armor.reduction, cap = armor.capPct,
            capped  = armor.capped,
            note    = armor.capped
                and "At the 75% hard cap — further armor does nothing."
                or string.format("%s armor. The 75%% cap needs %s against a level %d attacker.",
                    U.FormatNumber(armor.armor), U.FormatNumber(armor.capArmor), armor.attackerLvl),
            tooltip = {
                "reduction = armor / (armor + 467.5 * attackerLevel - 22167.5), hard capped at 75%",
                "Unlike the other caps this one is essentially unreachable in TBC gear — "
                    .. "it is here as a reference point, not a target.",
            },
        })
    end

    y = RenderResilience(content, y, data.resilience)

    -- ── Provenance ────────────────────────────────────────────────────
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "WHERE THESE NUMBERS COME FROM")

    y = L:Bullet(content, y, string.format("Weapon skill %d — %s.", data.weaponSkill, data.skillLabel),
        { color = data.skillMeasured and L.C_SECONDARY or L.C_WARNING })

    for _, line in ipairs(TA.TBCStats:ConfidenceReport()) do
        y = L:Bullet(content, y, line, { color = L.C_SECONDARY })
    end

    -- Every point of hit the rating API cannot see, attributed. An unexplained
    -- total here would be indistinguishable from a bug.
    if data.hitSources and #data.hitSources > 0 then
        y = L:Spacer(y, 2)
        y = L:Bullet(content, y, string.format(
            "Hit not reported by the rating API: |cFF4AFF7A+%s melee|r, |cFF4AFF7A+%s spell|r. "
            .. "Already subtracted from the targets above.",
            U.Pct(data.meleeBonus or 0), U.Pct(data.spellBonus or 0)),
            { color = L.C_PRIMARY })

        for _, src in ipairs(data.hitSources) do
            local text
            if src.override then
                text = "|cFFFFD100Manual override in force|r — talent and racial detection is "
                    .. "ignored. |cFF888780/ta hitbonus off|r to go back to automatic."
            elseif src.failed then
                text = "|cFFFF9A1ATalent hit could not be read|r — the talent API did not answer, "
                    .. "so any hit from talents is NOT counted and the targets above are too high."
            else
                text = string.format("+%s from %s%s", U.Pct(src.amount), src.label,
                    src.school and (" |cFF888780(" .. src.school .. ")|r") or "")
                if src.unverified then
                    text = text .. " |cFF888780· value unverified|r"
                end
                if src.overRank then
                    text = text .. " |cFFFF4444· rank above expected maximum, value clamped|r"
                end
            end
            y = L:Bullet(content, y, text, { color = L.C_SECONDARY, marker = "›" })
        end

        y = L:Bullet(content, y,
            "If any of this is wrong, |cFFFFD100/ta hitbonus <melee%> <spell%>|r overrides it "
            .. "entirely and is always trusted over detection.",
            { color = L.C_DIM, marker = " " })
    end

    y = L:Bullet(content, y,
        "Caps are computed from level, weapon skill and target level — not read from a "
        .. "level-70 table. |cFFFFD100/ta dumpme|r prints the checks that confirm the API "
        .. "behind them.", { color = L.C_DIM })

    L:Finish(content, y)
end

-- ─── CHAT ────────────────────────────────────────────────────────────────────

M.SlashCommands = {
    caps = function(self)
        local data = self:Collect()
        TA:Raw(TA.LOG.OUTPUT, string.format(
            "|cFFFFD100━━━ Stat caps vs %s ━━━|r  |cFF888780role %s, weapon skill %d|r",
            data.context.label, data.role, data.weaponSkill))

        if data.noCaps then
            TA:Raw(TA.LOG.OUTPUT, "  Healing role — no hit, expertise or defense target applies.")
            return
        end

        local function Line(name, cap, unit)
            if not cap then return end
            if cap.capped then
                TA:Raw(TA.LOG.OUTPUT, string.format("  |cFF4AFF7A✓|r %s — capped", name))
            else
                TA:Raw(TA.LOG.OUTPUT, string.format("  |cFFFF9A1A→|r %s — need %s more",
                    name, unit == "pct" and U.Pct(cap.needed) or tostring(cap.needed)))
            end
        end

        Line("Melee/ranged hit", data.caps.meleeHit, "pct")
        Line("Spell hit",        data.caps.spellHit, "pct")
        Line("Expertise",        data.caps.expertise, "points")
        Line("Defense",          data.caps.defense, "points")
    end,

    --- Manual override for hit the rating API cannot see. This is the reliable
    --- floor under talent detection: it needs no talent data to be correct, and
    --- it wins over everything the addon guessed.
    hitbonus = function(self, args)
        args = (args or ""):lower()

        if args == "off" or args == "auto" then
            TA.charDB.hitBonusMelee = nil
            TA.charDB.hitBonusSpell = nil
            TA:Print(TA.LOG.OUTPUT, nil, "Hit override cleared — back to talent and racial detection.")
            if TA.UI and TA.UI:IsVisible() then TA.UI:Refresh() end
            return
        end

        local melee, spell = args:match("^([%d%.]+)%s+([%d%.]+)$")
        if not melee then melee = args:match("^([%d%.]+)$") end

        if not melee then
            local m, s = TA.TBCStats:GetBonusHit()
            TA:Printf(TA.LOG.OUTPUT, nil,
                "Currently counting |cFFFFD100%s|r melee and |cFFFFD100%s|r spell hit from "
                .. "talents and racials.", U.Pct(m), U.Pct(s))
            TA:Raw(TA.LOG.OUTPUT, "  |cFF888780/ta hitbonus <melee%> <spell%>|r — set both")
            TA:Raw(TA.LOG.OUTPUT, "  |cFF888780/ta hitbonus <percent>|r — set melee only")
            TA:Raw(TA.LOG.OUTPUT, "  |cFF888780/ta hitbonus off|r — back to automatic detection")
            return
        end

        TA.charDB.hitBonusMelee = tonumber(melee) or 0
        TA.charDB.hitBonusSpell = tonumber(spell) or tonumber(melee) or 0
        TA:Printf(TA.LOG.OUTPUT, nil,
            "Hit override set: |cFFFFD100%s|r melee, |cFFFFD100%s|r spell. "
            .. "This now replaces talent and racial detection entirely.",
            U.Pct(TA.charDB.hitBonusMelee), U.Pct(TA.charDB.hitBonusSpell))
        if TA.UI and TA.UI:IsVisible() then TA.UI:Refresh() end
    end,

    role = function(self, args)
        local valid = { auto=true, TANK=true, HEALER=true, CASTER=true, MELEE=true, RANGED=true }
        local want = (args or ""):upper()
        if want == "AUTO" then want = "auto" end
        if valid[want] then
            TA.charDB.roleOverride = want
            TA:Printf(TA.LOG.OUTPUT, nil, "Role set to |cFFFFD100%s|r (was inferred as %s).",
                want, U.InferRole())
            if TA.UI and TA.UI:IsVisible() then TA.UI:Refresh() end
        else
            TA:Printf(TA.LOG.OUTPUT, nil,
                "Usage: /ta role <auto|tank|healer|caster|melee|ranged>  (currently %s)",
                U.InferRole())
        end
    end,
}

function M:OnEvent(event)
    -- The tab re-renders through UI:Refresh; nothing to cache here. Target
    -- changes matter because caps are target-relative, and UI.lua's TAB_EVENTS
    -- already routes PLAYER_TARGET_CHANGED to this tab.
end
