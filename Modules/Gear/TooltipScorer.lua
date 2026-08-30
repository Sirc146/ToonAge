-- ToonAge/Modules/Gear/TooltipScorer.lua
-- Tooltip Upgrade Arrows — hooks GameTooltip and ItemRefTooltip, appends
-- upgrade/downgrade % to item tooltips by scoring via Gear.CalculateItemScore
-- vs equipped item(s). For dual-slot items (rings/trinkets), compares against
-- BOTH equipped items and shows the best comparison.
-- Reference: Pawn\Pawn.lua ~line 2716 (PawnUpdateTooltip)

local TA = ToonAge
local U = TA.Utils

local TooltipScorer = {}
TA:RegisterModule("TooltipScorer", TooltipScorer)

-- ── Slot mapping ──────────────────────────────────────────────────────────────
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_HOLDABLE = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_RANGED = { 16 },
    INVTYPE_RANGEDRIGHT = { 16 },
}

-- ── Dual-slot equip locations (rings, trinkets, weapons) ──────────────────────
local DUAL_SLOT_LOCS = {
    INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true,
    INVTYPE_WEAPON = true,
}

-- ── Unicode indicators ────────────────────────────────────────────────────────
local ARROW_UP = "\226\150\178" -- ▲ (U+25B2)
local ARROW_DOWN = "\226\150\188" -- ▼ (U+25BC)
local ARROW_SIDE = "\226\149\144" -- ═ (U+2550)

local COLOR_GREEN = "|cFF4AFF7A"
local COLOR_RED = "|cFFFF4444"
local COLOR_YELLOW = "|cFFFFD100"
local COLOR_CYAN = "|cFF00FFFF"
local COLOR_END = "|r"

-- ── Cache ─────────────────────────────────────────────────────────────────────
local cache = {} -- { [itemLink] = { result, time } }
local CACHE_TTL = 0.5 -- seconds

-- ── Configuration ─────────────────────────────────────────────────────────────
local function GetThreshold()
    -- Configurable threshold: only show indicators when |pct| > threshold
    -- Default 0.5%; user can override via TA.db.tooltipThreshold
    if TA.db and TA.db.tooltipThreshold then
        return TA.db.tooltipThreshold
    end
    return 0.5
end

-- ── Core scoring ──────────────────────────────────────────────────────────────
local function ScoreItem(itemLink)
    if not itemLink then
        return 0
    end
    local Gear = TA:GetModule("Gear")
    if not Gear or not Gear.CalculateItemScore then
        return 0
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        return 0
    end
    local specID = GetSpecializationInfo(specIndex)
    if not specID then
        return 0
    end

    local ok, score = pcall(Gear.CalculateItemScore, itemLink, specID, "pve")
    if ok and type(score) == "number" then
        return score
    end
    return 0
end

--- For dual-slot items, compute comparison against each equipped slot individually
--- and return the BEST comparison (most favorable to the new item).
--- @return number bestPct, number newScore, number bestEquippedScore, boolean allEmpty
local function CompareDualSlot(itemLink, slots)
    local newScore = ScoreItem(itemLink)
    if newScore <= 0 then
        return 0, 0, 0, false
    end

    local bestPct = -math.huge
    local bestEquippedScore = 0
    local allEmpty = true

    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            allEmpty = false
            local eqScore = ScoreItem(equippedLink)
            if eqScore > 0 then
                local pct = ((newScore - eqScore) / eqScore) * 100
                if pct > bestPct then
                    bestPct = pct
                    bestEquippedScore = eqScore
                end
            else
                -- Equipped item scored 0 (unusual), treat as empty for this slot
                bestPct = math.huge
                bestEquippedScore = 0
            end
        end
    end

    if allEmpty then
        return 0, newScore, 0, true
    end

    if bestPct == math.huge then
        return 0, newScore, 0, true
    end

    return bestPct, newScore, bestEquippedScore, false
end

--- For single-slot items, compare against the one equipped item.
--- @return number pct, number newScore, number equippedScore, boolean isEmpty
local function CompareSingleSlot(itemLink, slots)
    local newScore = ScoreItem(itemLink)
    if newScore <= 0 then
        return 0, 0, 0, false
    end

    local slotID = slots[1]
    local equippedLink = GetInventoryItemLink("player", slotID)
    if not equippedLink then
        return 0, newScore, 0, true
    end

    local eqScore = ScoreItem(equippedLink)
    if eqScore <= 0 then
        return 0, newScore, 0, true
    end

    local pct = ((newScore - eqScore) / eqScore) * 100
    return pct, newScore, eqScore, false
end

-- ── Tooltip evaluation ────────────────────────────────────────────────────────
function TooltipScorer:EvaluateItem(tooltip, itemLink)
    if not itemLink or itemLink == "" then
        return
    end

    -- Avoid processing on comparison/shopping tooltips
    if tooltip == ShoppingTooltip1 or tooltip == ShoppingTooltip2 then
        return
    end

    -- Check cache
    local now = GetTime()
    local cached = cache[itemLink]
    if cached and (now - cached.time) < CACHE_TTL then
        self:AppendLine(tooltip, cached.pct, cached.newScore, cached.eqScore, cached.isEmpty)
        return
    end

    -- Get equip location
    local ok, itemName, _, _, _, _, _, _, equipLoc = pcall(GetItemInfo, itemLink)
    if not ok then
        return
    end
    if not equipLoc or equipLoc == "" then
        return
    end

    local slots = EQUIP_LOC_TO_SLOT[equipLoc]
    if not slots then
        return
    end

    -- Score comparison: dual-slot items compare against both equipped
    local pct, newScore, eqScore, isEmpty
    if DUAL_SLOT_LOCS[equipLoc] and #slots > 1 then
        pct, newScore, eqScore, isEmpty = CompareDualSlot(itemLink, slots)
    else
        pct, newScore, eqScore, isEmpty = CompareSingleSlot(itemLink, slots)
    end

    -- Bail if scoring failed
    if newScore <= 0 and not isEmpty then
        return
    end

    -- Cache result
    cache[itemLink] = {
        pct = pct,
        newScore = newScore,
        eqScore = eqScore,
        isEmpty = isEmpty,
        time = now,
    }

    self:AppendLine(tooltip, pct, newScore, eqScore, isEmpty)
end

function TooltipScorer:AppendLine(tooltip, pct, newScore, eqScore, isEmpty)
    if not tooltip or not tooltip.AddLine then
        return
    end

    local threshold = GetThreshold()

    if isEmpty then
        -- New indicator for empty slots
        local text = string.format(
            "%s%s New%s  %s(%d)%s",
            COLOR_GREEN,
            ARROW_UP,
            COLOR_END,
            COLOR_CYAN,
            math.floor(newScore),
            COLOR_END
        )
        tooltip:AddLine(text)
    elseif pct > threshold then
        -- Upgrade
        local text = string.format(
            "%s%s +%.1f%% upgrade%s  (%d vs %d)",
            COLOR_GREEN,
            ARROW_UP,
            pct,
            COLOR_END,
            math.floor(newScore),
            math.floor(eqScore)
        )
        tooltip:AddLine(text)
    elseif pct < -threshold then
        -- Downgrade
        local text = string.format(
            "%s%s %.1f%% downgrade%s  (%d vs %d)",
            COLOR_RED,
            ARROW_DOWN,
            pct,
            COLOR_END,
            math.floor(newScore),
            math.floor(eqScore)
        )
        tooltip:AddLine(text)
    elseif math.abs(pct) <= threshold then
        -- Sidegrade (within threshold)
        local text = string.format(
            "%s%s %.1f%% sidegrade%s  (%d vs %d)",
            COLOR_YELLOW,
            ARROW_SIDE,
            pct,
            COLOR_END,
            math.floor(newScore),
            math.floor(eqScore)
        )
        tooltip:AddLine(text)
    end

    tooltip:Show()
end

-- ── Hook helpers ──────────────────────────────────────────────────────────────
local function HookLegacyTooltip(tooltip)
    if not tooltip or not tooltip.HookScript then
        return
    end
    local ok, err = pcall(function()
        tooltip:HookScript("OnTooltipSetItem", function(tt)
            local _, itemLink = tt:GetItem()
            if itemLink then
                TooltipScorer:EvaluateItem(tt, itemLink)
            end
        end)
    end)
    if not ok then
        U:Debug("TooltipScorer: legacy hook failed for " .. (tooltip:GetName() or "unknown") .. ": " .. tostring(err))
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function TooltipScorer:Init()
    -- Initialize default threshold in saved variables if not present
    if TA.db and TA.db.tooltipThreshold == nil then
        TA.db.tooltipThreshold = 0.5
    end

    -- Modern WoW (10.0+) uses TooltipDataProcessor
    if
        TooltipDataProcessor
        and TooltipDataProcessor.AddTooltipPostCall
        and Enum
        and Enum.TooltipDataType
        and Enum.TooltipDataType.Item
    then
        local ok, err = pcall(function()
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
                if not data or not data.hyperlink then
                    return
                end
                -- Process GameTooltip and ItemRefTooltip (not shopping/comparison)
                if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
                    return
                end
                TooltipScorer:EvaluateItem(tooltip, data.hyperlink)
            end)
        end)

        if not ok then
            -- Fallback to legacy if modern API errors
            U:Debug("TooltipScorer: TooltipDataProcessor failed, using legacy: " .. tostring(err))
            HookLegacyTooltip(GameTooltip)
            HookLegacyTooltip(ItemRefTooltip)
        end
    else
        -- Legacy fallback for older builds (pre-10.0)
        HookLegacyTooltip(GameTooltip)
        HookLegacyTooltip(ItemRefTooltip)
    end
end
