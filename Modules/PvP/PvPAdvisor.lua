-- ToonAge/Modules/PvP/PvPAdvisor.lua (Anniversary — TBC Classic / 20506)
-- Arena and battleground advisor.
--
-- ─── WHY PVP IS A MODE AND NOT JUST A TAB ────────────────────────────────────
--
-- Bolting a PvP tab onto a PvE addon would leave the other five tabs lying to
-- you. An enemy player is a SAME-LEVEL target, so the moment you care about PvP:
--
--   melee hit cap   9%  ->  5%
--   spell hit cap  16%  ->  3%
--   expertise      26   ->  far less, and worth little
--   defense        490  ->  meaningless (player crits are cut by resilience)
--   resilience     0    ->  a top-three stat
--
-- A caster gearing to 16% spell hit for arena is throwing away roughly thirteen
-- percent of hit — over 160 rating at level 70 — on nothing at all. That is the
-- single largest avoidable gearing mistake in TBC, and it is invisible unless
-- the addon changes its mind about the target.
--
-- So `db.pvpMode` flips one flag and five behaviours follow from it, through
-- TBCStats:ActiveContextKey() and Data.GetWeights(). This tab explains the mode
-- and shows what only matters in PvP; the Caps and Gear tabs do the maths.
--
-- UNVERIFIED on 20506: every arena and honor API below. All are pcall-guarded
-- and report their own absence — see /ta apiprobe.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("PvPAdvisor", M)

-- ─── CLIENT READS ─────────────────────────────────────────────────────────────

--- Arena teams, as much as this client will tell us.
--- @return table teams, boolean apiPresent
local function ReadArenaTeams()
    if type(GetNumArenaTeams) ~= "function" or type(GetArenaTeam) ~= "function" then
        return {}, false
    end

    local count = U.SafeGetNum(GetNumArenaTeams)
    local teams = {}

    -- WARN: GetArenaTeam's real return signature on 20506 is UNVERIFIED (see the
    -- file-header note), and Blizzard's documented shape returns separate
    -- season vs. week played/win counts for the player (four numbers), not one
    -- combined "playerPlayed". pcall only catches a hard error, not a field
    -- landing one slot off — if the live order differs from the guess below,
    -- this silently reads a plausible-looking but wrong number into
    -- team.playerPlayed, which feeds straight into the "have you played enough
    -- games this week to be paid" qualifies check further down.
    for i = 1, count do
        local ok, name, size, rating, weekPlayed, weekWins,
              seasonPlayed, seasonWins, playerPlayed, playerRating = pcall(GetArenaTeam, i)
        if ok and name then
            teams[#teams + 1] = {
                name         = name,
                size         = U.SafeNum(size),
                rating       = U.SafeNum(rating),
                weekPlayed   = U.SafeNum(weekPlayed),
                weekWins     = U.SafeNum(weekWins),
                seasonPlayed = U.SafeNum(seasonPlayed),
                seasonWins   = U.SafeNum(seasonWins),
                playerPlayed = U.SafeNum(playerPlayed),
                playerRating = U.SafeNum(playerRating),
            }
        end
    end
    return teams, true
end

local function BracketFactor(size)
    for _, b in ipairs(TA.Data.ArenaBrackets) do
        if b.size == size then return b.factor, b.label end
    end
    return 1.0, tostring(size) .. "v" .. tostring(size)
end

--- Name-based check for a PvP trinket. Explicitly a guess: there is no API that
--- says "this trinket breaks crowd control", so this matches English names and
--- says so rather than pretending to certainty.
local function HasPvPTrinket()
    -- NOTE: "Battlemaster" is a Wrath-era trinket line (Battlemaster's Medallion
    -- and friends, Season 5+), not a TBC one — this addon has a documented
    -- history of PvP/Classic data leaking into other builds (see the header fix
    -- in Modules/Infrastructure/ErrorLog.lua). Harmless here since it just never
    -- matches on a TBC client, but it means an actual TBC-only trinket name
    -- could be the one that's missing from this list instead.
    local patterns = { "Insignia of the", "Medallion of the", "Battlemaster" }
    for _, slot in ipairs({ 13, 14 }) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        if link then
            local name = U.GetItemInfo(link)
            if name then
                for _, pattern in ipairs(patterns) do
                    if name:find(pattern, 1, true) then return true, name end
                end
            end
        end
    end
    return false
end

-- ─── RENDER ───────────────────────────────────────────────────────────────────

local function RenderModeToggle(content, y)
    local on = TA.db and TA.db.pvpMode
    local w = L:Width(content)

    local btn = CreateFrame("Button", nil, content)
    btn:SetSize(w, 34)
    btn:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, math.floor(y))
    if TA._ApplyBackdrop then
        if on then
            TA._ApplyBackdrop(btn, 0.22, 0.06, 0.06, 1.00, 1.00, 0.43, 0.43, 1.00)
        else
            TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1.00, 0.32, 0.30, 0.26, 1.00)
        end
    end

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    lbl:SetPoint("CENTER")
    if on then
        lbl:SetText("|cFFFF6E6EPvP MODE IS ON|r   —   click to return to PvE")
        lbl:SetTextColor(1, 0.85, 0.85, 1)
    else
        lbl:SetText("PvP mode is OFF   —   click to switch the whole addon to PvP")
        lbl:SetTextColor(0.62, 0.59, 0.55, 1)
    end

    btn:SetScript("OnClick", function()
        TA.db.pvpMode = not TA.db.pvpMode
        if TA.UI then TA.UI:Refresh() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("PvP mode", 1, 0.82, 0)
        GameTooltip:AddLine("Changes five things at once, so they cannot disagree:", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("• Cap target pinned to same-level (a player is your level)", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("• Melee hit cap 9% -> 5%, spell hit 16% -> 3%", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("• Gear weights swap to the PvP set", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("• Defense uncrittable target dropped", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("• Resilience surfaced on the Caps tab", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return y - 42
end

function M:Render(content, side)
    L:CharacterSidebar(side)

    local S = TA.TBCStats
    local role = U.InferRole()
    local on = TA.db and TA.db.pvpMode
    local y = -8

    y = RenderModeToggle(content, y)

    if not on then
        y = L:Paragraph(content, y,
            "While this is off, every other tab is gearing you for raid bosses. That is the "
            .. "right default — but it means the hit targets you see are three levels above "
            .. "you, and an enemy player never is.", { color = L.C_SECONDARY })
    end

    y = L:Divider(content, y)

    -- ─── What changes ─────────────────────────────────────────────────
    y = L:SectionHeader(content, y, "WHAT PVP CHANGES",
        "Computed against a same-level target, the way an arena actually works.")

    local sameHit  = S:GetMeleeHitCap({ contextKey = "same" })
    local sameSpell= S:GetSpellHitCap({ contextKey = "same" })
    local bossHit  = S:GetMeleeHitCap({ contextKey = "plus3" })
    local bossSpell= S:GetSpellHitCap({ contextKey = "plus3" })

    y = L:DataRow(content, y, {
        label = "Melee / ranged hit cap", value = U.Pct(sameHit.cap), bold = true,
        status = "neutral",
        note = string.format("Against a raid boss it is %s. Gearing to the raid number for "
            .. "arena wastes %s of hit — roughly %s rating at level 70.",
            U.Pct(bossHit.cap), U.Pct(bossHit.cap - sameHit.cap),
            U.Rating(select(1, S:PercentToRating("HIT_MELEE", bossHit.cap - sameHit.cap)) or 0)),
    })

    y = L:DataRow(content, y, {
        label = "Spell hit cap", value = U.Pct(sameSpell.cap), bold = true,
        status = "neutral",
        note = string.format("Against a raid boss it is %s. This is the largest PvE-to-PvP "
            .. "budget shift in the game — %s of hit freed for spell power and stamina.",
            U.Pct(bossSpell.cap), U.Pct(bossSpell.cap - sameSpell.cap)),
    })

    y = L:DataRow(content, y, {
        label = "Defense / uncrittable", value = "does not apply", status = "dim",
        note = "Player critical strikes are reduced by resilience, not by defense skill. "
            .. "There is no crit-immunity threshold against a player at any defense value.",
    })

    -- ─── Resilience ───────────────────────────────────────────────────
    local res = S:GetResilience()
    y = L:Spacer(y, 4)
    y = L:DataRow(content, y, {
        label = "Your resilience", value = U.Rating(res.rating), bold = true,
        status = res.hasAny and "good" or "bad",
        note = res.hasAny
            and string.format("-%s crit chance taken, -%s crit damage, -%s damage over time.",
                U.Pct(res.critReduction), U.Pct(res.critDamageReduction), U.Pct(res.dotReduction))
            or "|cFFFF4444None.|r The honor-gear floor costs no arena rating and is the "
               .. "single biggest survivability jump available to a fresh 70.",
    })

    for _, note in ipairs(TA.Data.ResilienceNotes) do
        y = L:Bullet(content, y, note, { color = L.C_SECONDARY })
    end

    -- ─── PvP trinket ──────────────────────────────────────────────────
    local hasTrinket, trinketName = HasPvPTrinket()
    y = L:Spacer(y, 4)
    y = L:DataRow(content, y, {
        label = "PvP trinket equipped", value = hasTrinket and "yes" or "not detected",
        status = hasTrinket and "good" or "warn",
        note = hasTrinket
            and (trinketName .. " — detected by name, so treat a 'yes' as likely rather than certain.")
            or "Checked by NAME only (Insignia / Medallion / Battlemaster) — no API reports "
               .. "'this trinket breaks crowd control', so a miss here may just be a naming "
               .. "mismatch. If you are carrying one, ignore this row.",
    })

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ─── POWER SPIKES ──────────────────────────────────────────────────
    -- Three of these are measured against your actual character. The fourth
    -- (weapons) is reference text, and is grouped last so the distinction
    -- between "this is your progress" and "this is advice" stays visible.
    y = L:SectionHeader(content, y, "POWER SPIKES",
        "PvP strength arrives in steps. Three of these four are read from your "
        .. "character; the last is guidance.")

    local class = U.GetPlayerClass()
    local level = U.GetPlayerLevel()

    -- ─── Spike 1: armor ───────────────────────────────────────────────
    local best, pending, switchLevel = TA.Data.BestArmorFor(class, level)
    local armorEntry = TA.Data.ClassArmor[class]
    if best then
        y = L:DataRow(content, y, {
            label  = "Armor spike",
            value  = pending and string.format("%s at %d", armorEntry.final, switchLevel)
                              or (best .. " — reached"),
            status = pending and "warn" or "good", bold = true,
            note   = pending
                and string.format("You wear %s now and unlock %s at level %d — %d levels away. "
                    .. "%s", best, armorEntry.final, switchLevel, switchLevel - level, armorEntry.note)
                or armorEntry.note,
        })
    end

    -- ─── Spike 2: talents ─────────────────────────────────────────────
    local _, deepest, trees = U.GetTalentSummary()
    deepest = deepest or 0
    local s31, s41 = TA.Data.TALENT_SPIKE_31, TA.Data.TALENT_SPIKE_41

    local talentValue, talentNote, talentStatus
    if deepest >= s41 then
        talentValue, talentStatus = "41-point reached", "good"
        talentNote = "Your deepest tree is fully invested. Both signature talents are available."
    elseif deepest >= s31 then
        talentValue, talentStatus = string.format("%d to the 41-point", s41 - deepest), "warn"
        talentNote = string.format("You have the 31-point talent. %d more points in the same "
            .. "tree unlocks the 41-point capstone.", s41 - deepest)
    else
        talentValue, talentStatus = string.format("%d to the 31-point", s31 - deepest), "warn"
        talentNote = string.format("Deepest tree has %d points. A tree's tier N needs 5*(N-1) "
            .. "points, so the 31-point talent opens at %d.", deepest, s31)
    end

    y = L:DataRow(content, y, {
        label = "Talent spike", value = talentValue, status = talentStatus, bold = true,
        note  = talentNote .. "  " .. (TA.Data.ClassSpikes[class] or ""),
    })

    if trees and #trees > 0 then
        local parts = {}
        for _, tree in ipairs(trees) do
            parts[#parts + 1] = string.format("%s %d", tree.name, tree.points)
        end
        y = L:Bullet(content, y, table.concat(parts, "   ·   "), { color = L.C_DIM, marker = "›" })
    end

    -- ─── Spike 3: stats ───────────────────────────────────────────────
    y = L:DataRow(content, y, {
        label  = "Stat spike",
        value  = res.hasAny and (U.Rating(res.rating) .. " resilience") or "no resilience",
        status = res.hasAny and "good" or "bad", bold = true,
        note   = string.format("Hit caps against a player are %s melee and %s spell — both far "
            .. "lower than the raid figures, which frees budget for stamina and resilience.",
            U.Pct(sameHit.cap), U.Pct(sameSpell.cap)),
    })

    -- ─── Spike 4: weapons and trinkets (reference) ────────────────────
    y = L:Spacer(y, 4)
    y = L:Bullet(content, y, "|cFFFFD100Weapon spike|r — reference, not measured:",
        { color = L.C_SECONDARY, marker = " " })
    for _, note in ipairs(TA.Data.WeaponSpikeNotes) do
        y = L:Bullet(content, y, note, { color = L.C_SECONDARY })
    end

    y = L:Spacer(y, 2)
    y = L:Bullet(content, y, "|cFFFFD100Trinket spike|r — reference, not measured:",
        { color = L.C_SECONDARY, marker = " " })
    for _, note in ipairs(TA.Data.TrinketSpikeNotes) do
        y = L:Bullet(content, y, note, { color = L.C_SECONDARY })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ─── Priorities ───────────────────────────────────────────────────
    y = L:SectionHeader(content, y, "PRIORITIES FOR A " .. role)
    for _, line in ipairs(TA.Data.PvPPriorities[role] or {}) do
        y = L:Bullet(content, y, line, { color = L.C_PRIMARY })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ─── Arena ────────────────────────────────────────────────────────
    local teams, apiPresent = ReadArenaTeams()
    y = L:SectionHeader(content, y, "ARENA")

    if not apiPresent then
        y = L:Paragraph(content, y,
            "The arena team API is not available on this client, so team ratings and point "
            .. "projections cannot be shown. |cFFFFD100/ta apiprobe|r confirms which calls "
            .. "resolved.", { color = L.C_WARNING })
    elseif #teams == 0 then
        y = L:Paragraph(content, y,
            "No arena teams. Points are paid per team per week, and you must play enough of "
            .. "the team's games to be paid at all — see the requirements below.")
    else
        for _, team in ipairs(teams) do
            local factor, label = BracketFactor(team.size)
            local points = TA.Data.ArenaPointsFor(team.rating, factor)

            local needed = TA.Data.ArenaMinGamesPerWeek
            local personalNeeded = math.ceil(team.weekPlayed * TA.Data.ArenaPersonalParticipation)
            local qualifies = team.weekPlayed >= needed and team.playerPlayed >= personalNeeded

            y = L:DataRow(content, y, {
                label  = string.format("%s  |cFF555049%s|r", team.name, label),
                value  = string.format("%d rating", team.rating),
                bold   = true,
                status = qualifies and "good" or "warn",
                note   = string.format(
                    "Projected %s points this week%s.  %d games played (%d needed), "
                    .. "you played %d.  Personal rating %d.",
                    U.Rating(points),
                    TA.Data.ArenaPointsUnverified and " |cFFFF9A1A(formula unverified)|r" or "",
                    team.weekPlayed, needed, team.playerPlayed, team.playerRating),
            })
        end
    end

    y = L:Bullet(content, y, string.format(
        "A team must play %d games a week, and you personally must play at least %d%% of "
        .. "them, to receive any points.",
        TA.Data.ArenaMinGamesPerWeek, TA.Data.ArenaPersonalParticipation * 100),
        { color = L.C_SECONDARY })
    y = L:Bullet(content, y,
        "The 5v5 bracket pays the most points for the same rating, then 3v3, then 2v2.",
        { color = L.C_SECONDARY })

    if TA.Data.ArenaPointsUnverified then
        y = L:Paragraph(content, y,
            "|cFFFF9A1AThe point projection uses the documented TBC curve and has not been "
            .. "checked against this client.|r Compare it to your first real payout — if it "
            .. "is off, the formula is one line to correct.", { color = L.C_WARNING })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ─── Diminishing returns ──────────────────────────────────────────
    y = L:SectionHeader(content, y, "DIMINISHING RETURNS",
        string.format("The most important PvP mechanic with no interface anywhere in the "
            .. "game: %s, then the chain resets after about %d seconds.",
            table.concat(TA.Data.DRChain, " → "), TA.Data.DRWindowSeconds))

    for _, cat in ipairs(TA.Data.DRCategories) do
        y = L:DataRow(content, y, {
            label = cat.name, value = "", status = "dim", note = cat.examples,
        })
    end

    for _, note in ipairs(TA.Data.DRNotes) do
        y = L:Bullet(content, y, note, { color = L.C_SECONDARY })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ─── Gear sources ─────────────────────────────────────────────────
    y = L:SectionHeader(content, y, "WHERE PVP GEAR COMES FROM")
    for _, src in ipairs(TA.Data.PvPGearSources) do
        y = L:DataRow(content, y, {
            label  = src.name,
            value  = src.gated and "|cFFFF9A1Arating gated|r" or "|cFF4AFF7Ano gate|r",
            status = src.gated and "warn" or "good",
            note   = src.cost .. " — " .. src.note,
        })
    end

    y = L:Paragraph(content, y, TA.Data.RatingGateWarning, { color = L.C_WARNING })

    L:Finish(content, y)
end

M.SlashCommands = {
    resilience = function()
        local res = TA.TBCStats:GetResilience()
        TA:Raw(TA.LOG.OUTPUT, string.format(
            "|cFFFFD100[ToonAge]|r Resilience %d — |cFF4AFF7A-%s|r crit taken, "
            .. "|cFF4AFF7A-%s|r crit damage, |cFF4AFF7A-%s|r damage over time.",
            res.rating, U.Pct(res.critReduction),
            U.Pct(res.critDamageReduction), U.Pct(res.dotReduction)))
    end,
}
