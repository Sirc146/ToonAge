-- ToonAge/Modules/Gear/Gear.lua (Anniversary — TBC Classic / 20506)
-- Cap-aware gear scoring and an upgrade finder over your bags.
--
-- ─── HOW "HIT > EVERYTHING UNTIL CAPPED" IS ACTUALLY IMPLEMENTED ───────────
--
-- The brief asks for "item with Hit is ALWAYS better until capped". Taken
-- literally that is wrong in a way that would hand out bad advice: a ring with
-- 4 hit rating would outrank one with 40 attack power and 20 crit, and an item
-- carrying 200 hit when you need 12 would be scored as if all 200 counted.
--
-- What is implemented instead is marginal value, which is what the brief is
-- reaching for:
--
--   * Rating that closes a gap you actually have is multiplied by CAP_PRIORITY.
--     While you are under the cap, hit genuinely does outrank raw throughput,
--     and by a wide margin.
--   * Rating BEYOND the gap collapses to SURPLUS_VALUE — near zero. Hit past
--     the cap does literally nothing in TBC, and scoring it as if it did is how
--     people end up 4% over.
--   * An item is only split this way for caps that apply to YOUR role. Spell hit
--     on a healer scores zero, because healing spells cannot miss.
--
-- So a 12-hit item beats a 40-AP item when you need 12 hit, and loses to it the
-- moment you are capped. That is the behaviour the brief wants, arrived at
-- through the arithmetic rather than through a blanket rule.
--
-- The cap side of this is exact (see Core/TBCStats.lua). The weights are
-- approximations and are labelled as such in the UI — see Data/TBCWeights.lua.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("Gear", M)

-- How much a point of rating is worth while it still closes a gap, relative to
-- its own base weight. Large on purpose: under the cap, this is the priority.
local CAP_PRIORITY  = 3.00
-- What a point is worth once the gap is closed. Not zero, because a future
-- weapon swap or a target change can reopen the gap — but close enough that it
-- never wins a comparison.
local SURPLUS_VALUE = 0.05

-- ─── CAP STATE ─────────────────────────────────────────────────────────────

--- How much RATING of each capped stat you still need. nil means the cap does
--- not apply to your role; 0 means it applies and is already met.
--- @return table {HIT=n|nil, SPELLHIT=n|nil, EXP=n|nil, DEFENSE=n|nil}, table meta
function M:GetCapGaps()
    local S = TA.TBCStats
    local caps = TA:GetModule("StatCaps")
    local gaps, meta = {}, { approximate = false }

    if not (S and caps and caps.Collect) then return gaps, meta end

    local ok, data = pcall(caps.Collect, caps)
    if not ok or not data then return gaps, meta end

    meta.context = data.context
    meta.role    = data.role

    if data.caps.meleeHit then
        local rating, source = S:PercentToRating("HIT_MELEE", data.caps.meleeHit.needed)
        gaps.HIT = rating or 0
        if source ~= "derived" then meta.approximate = true end
    end

    if data.caps.spellHit then
        local rating, source = S:PercentToRating("HIT_SPELL", data.caps.spellHit.needed)
        gaps.SPELLHIT = rating or 0
        if source ~= "derived" then meta.approximate = true end
    end

    if data.caps.expertise then
        local perPoint, source = S:GetExpertiseRatingPerPoint()
        gaps.EXP = perPoint and (data.caps.expertise.needed * perPoint) or 0
        if source ~= "derived" then meta.approximate = true end
    end

    if data.caps.defense then
        local perPoint, source = S:GetDefenseRatingPerPoint()
        gaps.DEFENSE = perPoint and (data.caps.defense.needed * perPoint) or 0
        if source ~= "derived" then meta.approximate = true end
    end

    return gaps, meta
end

-- ─── SCORING ───────────────────────────────────────────────────────────────

--- Score one item.
--- @param link string itemLink
--- @param role string
--- @param gaps table from GetCapGaps
--- @return number score, table breakdown, number unknownKeys
function M:ScoreItem(link, role, gaps)
    if not link or not GetItemStats then return 0, {}, 0 end

    local ok, raw = pcall(GetItemStats, link)
    if not ok or type(raw) ~= "table" then return 0, {}, 0 end

    local stats, unknown = TA.Data.NormaliseStats(raw)
    -- Sockets are pulled out BEFORE weighting. An empty socket is a hole, not a
    -- stat, and scoring it as one would rank an unfilled item above a filled one.
    local sockets, socketCount = TA.Data.ExtractSockets(stats)
    local weights = TA.Data.GetWeights(role)
    local breakdown, score = {}, 0

    -- Local copy: each item is scored against the same starting gap, so two
    -- items are compared fairly rather than the second one being scored as
    -- though the first were already equipped.
    local remaining = {}
    for key, value in pairs(gaps) do remaining[key] = value end

    for statKey, amount in pairs(stats) do
        if amount ~= 0 then
            local weight = weights[statKey]

            -- Spell hit is worthless to a healer, and melee hit is worthless to
            -- a caster. Absent from the role's weight table means exactly that.
            if weight and weight > 0 then
                local capKey = TA.Data.StatToCap[statKey]
                local gap = capKey and remaining[statKey]

                if gap ~= nil then
                    local useful  = math.min(amount, math.max(gap, 0))
                    local surplus = amount - useful
                    local value = useful * weight * CAP_PRIORITY
                                + surplus * weight * SURPLUS_VALUE
                    score = score + value
                    remaining[statKey] = math.max(gap - useful, 0)

                    breakdown[#breakdown + 1] = {
                        stat = statKey, amount = amount, value = value,
                        useful = useful, surplus = surplus, capped = (useful == 0),
                    }
                else
                    local value = amount * weight
                    score = score + value
                    breakdown[#breakdown + 1] = { stat = statKey, amount = amount, value = value }
                end
            end
        end
    end

    table.sort(breakdown, function(a, b) return a.value > b.value end)
    return score, breakdown, unknown, sockets, socketCount
end

-- ─── EQUIPPED + UPGRADE SEARCH ─────────────────────────────────────────────

-- Which inventory slots an item's equip location can go into.
local EQUIP_TO_SLOTS = {
    INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3},
    INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5}, INVTYPE_WAIST = {6},
    INVTYPE_LEGS = {7}, INVTYPE_FEET = {8}, INVTYPE_WRIST = {9},
    INVTYPE_HAND = {10}, INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14},
    INVTYPE_CLOAK = {15}, INVTYPE_WEAPONMAINHAND = {16},
    INVTYPE_WEAPONOFFHAND = {17}, INVTYPE_HOLDABLE = {17}, INVTYPE_SHIELD = {17},
    INVTYPE_2HWEAPON = {16}, INVTYPE_WEAPON = {16, 17},
    INVTYPE_RANGED = {18}, INVTYPE_RANGEDRIGHT = {18}, INVTYPE_THROWN = {18},
    INVTYPE_RELIC = {18},
}

function M:GetEquippedScores(role, gaps)
    local out, totalUnknown = {}, 0
    for _, slot in ipairs(U.STAT_SLOTS) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        if link then
            local score, breakdown, unknown, sockets, socketCount = self:ScoreItem(link, role, gaps)
            totalUnknown = totalUnknown + unknown
            local name, _, quality, ilvl, _, _, _, _, equipLoc = U.GetItemInfo(link)

            -- An item whose worth is in an on-use or a proc cannot be compared
            -- to one that was scored fully. Flag it here so nothing downstream
            -- treats its score as meaningful.
            local hidden, reason = false, nil
            if TA.TooltipScan then
                hidden, reason = TA.TooltipScan:HasHiddenValue(link, score, equipLoc)
            end

            out[slot] = {
                slot = slot, link = link, name = name, quality = quality,
                ilvl = U.SafeNum(ilvl), score = score, breakdown = breakdown,
                equipLoc = equipLoc, unscoreable = hidden, unscoreableWhy = reason,
                sockets = sockets, socketCount = socketCount or 0,
            }
        end
    end
    return out, totalUnknown
end

--- Bag items that outscore what is in the matching slot.
--- Bags are scanned only when this tab renders, never on a timer — the
--- performance rules in .rules.md forbid inventory sweeps on events.
function M:FindUpgrades(role, gaps, equipped)
    local upgrades = {}

    for bag = 0, 4 do
        local slots = U.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local link = U.GetContainerItemLink(bag, slot)
            if link then
                local name, _, quality, ilvl, minLevel, _, _, _, equipLoc = U.GetItemInfo(link)
                local targetSlots = equipLoc and EQUIP_TO_SLOTS[equipLoc]

                -- WARN: a two-handed candidate (INVTYPE_2HWEAPON -> slot 16 only) is
                -- scored against the main-hand item alone. Equipping it also clears
                -- slot 17, but that off-hand item's score is never subtracted from
                -- `gain` below. For any dual-wielder (Rogue, Fury Warrior, Enhancement
                -- Shaman, Retribution/Ret-hybrid builds, Hunter) this can recommend a
                -- 2H "upgrade" that is actually a net loss once the off-hand piece is
                -- accounted for.
                if targetSlots and U.SafeNum(minLevel) <= U.GetPlayerLevel() then
                    local score = self:ScoreItem(link, role, gaps)

                    local candidateHidden = false
                    if TA.TooltipScan then
                        candidateHidden = TA.TooltipScan:HasHiddenValue(link, score, equipLoc)
                    end

                    -- Compare against the WEAKER of the candidate slots: replacing
                    -- your worse ring is the upgrade, not replacing your better one.
                    -- This is the one place paired slots genuinely matter, and it
                    -- is why rings and trinkets need their own handling at all.
                    --
                    -- Slots holding an unscoreable item are SKIPPED as replacement
                    -- targets. Their score is not a real number, so "beats it" is
                    -- not a real comparison — this is what stopped a green ring
                    -- being offered as an upgrade over Bloodlust Brooch.
                    --
                    -- NOTE: if BOTH slots of a pair (rings, trinkets) hold an
                    -- unscoreable item, `worstSlot` never gets set — every candidate
                    -- for that slot type is silently dropped below, with no row and
                    -- no message. A player wearing two on-use trinkets (a common TBC
                    -- loadout) stops seeing trinket upgrades at all, not just the
                    -- ones that fail to beat the current pair.
                    local worstSlot, worstScore, blockedByHidden
                    for _, s in ipairs(targetSlots) do
                        local cur = equipped[s]
                        if cur and cur.unscoreable then
                            blockedByHidden = true
                        else
                            local curScore = cur and cur.score or -1
                            if not worstScore or curScore < worstScore then
                                worstSlot, worstScore = s, curScore
                            end
                        end
                    end

                    if worstSlot and score > (worstScore or -1) then
                        upgrades[#upgrades + 1] = {
                            link = link, name = name, quality = quality,
                            ilvl = U.SafeNum(ilvl), score = score,
                            slot = worstSlot, currentScore = worstScore,
                            gain = score - math.max(worstScore or 0, 0),
                            unscoreable = candidateHidden,
                            blockedByHidden = blockedByHidden,
                        }
                    end
                end
            end
        end
    end

    table.sort(upgrades, function(a, b) return a.gain > b.gain end)
    return upgrades
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

local function BreakdownTooltip(entry)
    local lines = {}
    for i, b in ipairs(entry.breakdown) do
        if i > 8 then break end
        local label = TA.Data.StatLabels[b.stat] or b.stat
        if b.useful ~= nil then
            if b.capped then
                lines[#lines + 1] = string.format("%s %d — |cFF888780already capped, scored as surplus|r",
                    label, b.amount)
            elseif b.surplus > 0 then
                lines[#lines + 1] = string.format("%s %d — %d closes your gap, %d is surplus",
                    label, b.amount, b.useful, b.surplus)
            else
                lines[#lines + 1] = string.format("%s %d — |cFF4AFF7Aall of it closes your gap|r",
                    label, b.amount)
            end
        else
            lines[#lines + 1] = string.format("%s %d  (%s)", label, b.amount, U.Score(b.value))
        end
    end
    if #entry.breakdown == 0 then
        lines[#lines + 1] = "No stats this role values."
    end
    return lines
end

function M:Render(content, side)
    L:CharacterSidebar(side)

    local role = U.InferRole()
    local gaps, meta = self:GetCapGaps()
    local y = -8

    -- ── What the scoring is doing right now ───────────────────────────
    y = L:SectionHeader(content, y, "SCORING",
        string.format("Weighted for a %s. Rating that closes a cap gap is worth %.0fx its "
            .. "normal weight; rating past the cap is worth almost nothing.",
            role, CAP_PRIORITY))

    local gapLines = {}
    local gapOrder = { { "HIT", "melee/ranged hit" }, { "SPELLHIT", "spell hit" },
                       { "EXP", "expertise" }, { "DEFENSE", "defense" } }
    for _, entry in ipairs(gapOrder) do
        local gap = gaps[entry[1]]
        if gap ~= nil then
            if gap > 0 then
                gapLines[#gapLines + 1] = string.format("|cFFFF9A1A%s rating of %s|r",
                    U.Rating(gap), entry[2])
            else
                gapLines[#gapLines + 1] = string.format("|cFF4AFF7A%s capped|r", entry[2])
            end
        end
    end

    if #gapLines > 0 then
        y = L:Paragraph(content, y, "Still needed: " .. table.concat(gapLines, "  ·  "),
            { size = 10, color = L.C_PRIMARY })
    else
        y = L:Paragraph(content, y, "No stat caps apply to this role.")
    end

    if meta.approximate then
        y = L:Paragraph(content, y,
            "|cFFFF9A1ARating conversion is approximate|r — you hold too little rating for the "
            .. "client's own ratio to be readable, so the level formula was used. It sharpens "
            .. "automatically once you have some.", { color = L.C_WARNING })
    end

    y = L:Spacer(y, 4)
    y = L:Divider(content, y)

    -- ── Armor type ────────────────────────────────────────────────────
    -- Hunters and Shamans unlock Mail at 40 and the game never says so: no
    -- quest, no popup, the trainer simply starts offering it. Players run
    -- around at 45 in the leather they levelled in, giving up a large amount
    -- of armor for nothing. This is a straight comparison of each equipped
    -- piece's subtype against what the class can wear now.
    local equipped, unknownKeys = self:GetEquippedScores(role, gaps)
    local class = U.GetPlayerClass()
    local best, pending, switchLevel = TA.Data.BestArmorFor(class, U.GetPlayerLevel())

    if best then
        local lighter = {}
        for _, slot in ipairs(U.STAT_SLOTS) do
            local entry = equipped[slot]
            if entry and entry.link then
                local _, _, _, _, _, itemType, subType = U.GetItemInfo(entry.link)
                if itemType == "Armor" and TA.Data.IsLighterArmor(subType, best) then
                    lighter[#lighter + 1] = string.format("%s (%s)",
                        U.SLOT_NAMES[slot] or ("slot " .. slot), subType)
                end
            end
        end

        if #lighter > 0 then
            y = L:SectionHeader(content, y, "ARMOR TYPE")
            y = L:DataRow(content, y, {
                label  = string.format("%d slot(s) below %s", #lighter, best),
                value  = "|cFFFF9A1Afree armor|r", status = "warn", bold = true,
                note   = table.concat(lighter, ", ")
                    .. ".  You can wear " .. best .. " now — replacing these is a straight "
                    .. "armor gain with no stat trade-off.",
            })
            y = L:Spacer(y, 4)
            y = L:Divider(content, y)
        elseif pending then
            -- Only Hunters and Shamans reach here: everyone else has from == 1.
            local entry = TA.Data.ClassArmor[class]
            y = L:SectionHeader(content, y, "ARMOR TYPE")
            y = L:DataRow(content, y, {
                label  = "Next armor unlock",
                value  = string.format("%s at %d", entry.final, switchLevel),
                status = "neutral",
                note   = string.format("%d levels away. %s",
                    switchLevel - U.GetPlayerLevel(), entry.note),
            })
            y = L:Spacer(y, 4)
            y = L:Divider(content, y)
        end
    end

    -- ── Empty sockets ─────────────────────────────────────────────────
    -- Sockets are TBC's defining gearing mechanic and an empty one is pure loss
    -- with no in-game warning anywhere. This is the cheapest real upgrade most
    -- characters are carrying.
    local socketSlots, socketTotal = {}, 0
    for _, slot in ipairs(U.STAT_SLOTS) do
        local entry = equipped[slot]
        if entry and entry.socketCount and entry.socketCount > 0 then
            local parts = {}
            for colour, n in pairs(entry.sockets) do
                parts[#parts + 1] = (n > 1) and string.format("%d %s", n, colour) or colour
            end
            table.sort(parts)
            socketSlots[#socketSlots + 1] = string.format("%s: %s",
                U.SLOT_NAMES[slot] or ("slot " .. slot), table.concat(parts, ", "))
            socketTotal = socketTotal + entry.socketCount
        end
    end

    if socketTotal > 0 then
        y = L:SectionHeader(content, y, "EMPTY SOCKETS")
        y = L:DataRow(content, y, {
            label  = string.format("%d empty socket%s across %d item%s",
                socketTotal, socketTotal == 1 and "" or "s",
                #socketSlots, #socketSlots == 1 and "" or "s"),
            value  = "|cFFFF9A1A~" .. (socketTotal * TA.Data.SOCKET_APPROX_VALUE) .. " stats|r",
            status = "warn", bold = true,
            note   = table.concat(socketSlots, "   ·   ")
                .. ".  Roughly " .. TA.Data.SOCKET_APPROX_VALUE .. " points of a stat per socket "
                .. "at rare quality — an approximation, not a computed figure.",
        })
        y = L:Bullet(content, y,
            "A meta gem does nothing at all until its colour requirement is met, so check "
            .. "the meta last and gem the coloured sockets to satisfy it.",
            { color = L.C_SECONDARY })
        y = L:Bullet(content, y,
            "Socket bonuses are only worth matching colours for when the bonus beats the "
            .. "stat you give up — this tab does not yet read socket bonuses, so that call "
            .. "is still yours.", { color = L.C_DIM })
        y = L:Spacer(y, 4)
        y = L:Divider(content, y)
    end

    -- ── Upgrades ──────────────────────────────────────────────────────
    local upgrades = self:FindUpgrades(role, gaps, equipped)

    y = L:SectionHeader(content, y, "UPGRADES IN YOUR BAGS",
        "Scored against the weaker of the slots each item could fill.")

    if #upgrades == 0 then
        y = L:Paragraph(content, y, "Nothing in your bags beats what you are wearing.")
    else
        for i, up in ipairs(upgrades) do
            if i > 10 then break end

            local note = string.format("item level %d  ·  score %s vs %s equipped",
                up.ilvl, U.Score(up.score), U.Score(math.max(up.currentScore or 0, 0)))
            local status = "good"

            if up.unscoreable then
                note = note .. "  |cFFFF9A1A· this item also has an effect not counted in "
                    .. "the score, so the real gain is larger than shown.|r"
                status = "warn"
            end
            if up.blockedByHidden then
                note = note .. "  |cFF888780· your other " .. (U.SLOT_NAMES[up.slot] or "slot")
                    .. " pair holds an item with an effect, which was left out of the "
                    .. "comparison rather than guessed at.|r"
            end

            y = L:DataRow(content, y, {
                label  = U.ColourItemName(up.name or "?", up.quality)
                       .. "  |cFF555049→ " .. (U.SLOT_NAMES[up.slot] or "?") .. "|r",
                value  = "+" .. U.Score(up.gain),
                status = status, bold = true,
                note   = note,
                tooltip = { "Score gain is in weighted stat points, not a percentage.",
                            "Hover the equipped item below to see how its stats were counted." },
                tooltipTitle = up.name,
            })
        end
    end

    y = L:Spacer(y, 6)
    y = L:Divider(content, y)

    -- ── Equipped ──────────────────────────────────────────────────────
    y = L:SectionHeader(content, y, "EQUIPPED",
        "Hover a row to see which of its stats the cap logic actually counted.")

    -- NOTE: an empty slot (entry == nil below) never competes for `worstSlot` —
    -- the comparison only runs inside the `if entry then` branch. A genuinely
    -- empty slot is at least as bad as any filled one, so "Weakest slot" can
    -- point at a mediocre item while a totally unfilled slot (common while
    -- leveling — no cloak/trinket yet) goes unmentioned.
    local worstSlot, worstScore
    for _, slot in ipairs(U.STAT_SLOTS) do
        local entry = equipped[slot]
        local name = U.SLOT_NAMES[slot] or ("Slot " .. slot)

        if entry then
            -- Unscoreable items are excluded from "weakest slot": a trinket
            -- scoring 0 because its power is an on-use is not your weakest slot,
            -- and calling it that would point you at the wrong upgrade.
            if not entry.unscoreable and (not worstScore or entry.score < worstScore) then
                worstSlot, worstScore = slot, entry.score
            end

            local tooltip = BreakdownTooltip(entry)
            if entry.unscoreable then
                table.insert(tooltip, 1, "|cFFFF9A1ANot ranked|r — " .. (entry.unscoreableWhy or "value not visible to the scorer") .. ".")
                table.insert(tooltip, 2, "Its static stats are listed below, but they are not the "
                    .. "point of this item, so no total is shown.")
            end

            y = L:DataRow(content, y, {
                label   = name .. "  " .. U.ColourItemName(entry.name or "?", entry.quality),
                value   = entry.unscoreable and "|cFFFF9A1Anot ranked|r" or U.Score(entry.score),
                status  = entry.unscoreable and "warn" or "neutral",
                tooltip = tooltip,
                tooltipTitle = entry.name,
            })
        else
            y = L:DataRow(content, y, {
                label = name, value = "|cFFFF4444empty|r", status = "bad",
            })
        end
    end

    if worstSlot then
        y = L:Spacer(y, 4)
        y = L:Paragraph(content, y, string.format(
            "|cFFFFD100Weakest slot:|r %s. That is where an upgrade buys you the most.",
            U.SLOT_NAMES[worstSlot] or "?"), { color = L.C_PRIMARY })
    end

    -- ── Provenance ────────────────────────────────────────────────────
    y = L:Spacer(y, 6)
    y = L:Divider(content, y)
    y = L:Paragraph(content, y,
        "Cap targets are exact — computed from your level, weapon skill and target. "
        .. "The stat WEIGHTS behind these scores are community approximations and are not; "
        .. "use them to rank, not to predict a damage number.")

    if unknownKeys > 0 then
        y = L:Paragraph(content, y, string.format(
            "|cFFFF9A1A%d item stat(s) had keys this build does not recognise|r and were not "
            .. "scored. |cFFFFD100/ta statkeys|r lists them — send them over and they get mapped.",
            unknownKeys), { color = L.C_WARNING })
    end

    L:Finish(content, y)
end

M.SlashCommands = {
    statkeys = function()
        local keys = TA.Data.UnknownStatKeys or {}
        local list = {}
        for key, count in pairs(keys) do list[#list + 1] = { key = key, count = count } end
        table.sort(list, function(a, b) return a.count > b.count end)

        if #list == 0 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Every item stat key seen so far is mapped.")
            return
        end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Unmapped item stat keys ━━━|r")
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780These were skipped during scoring. Paste them back to get them mapped.|r")
        for _, entry in ipairs(list) do
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s  |cFF888780(seen %dx)|r", entry.key, entry.count))
        end
    end,
}
