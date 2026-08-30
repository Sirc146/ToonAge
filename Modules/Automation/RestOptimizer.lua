-- ToonAge/Modules/Automation/RestOptimizer.lua
-- Micro-Rest Optimization: tracks rested XP, suggests "one more quest to ding"
-- or "log off in inn, rested charges in 6h". Inn proximity detection.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U = TA.Utils

local RO = {}
TA:RegisterModule("RestOptimizer", RO)

--- Is n a real, finite number safe to hand to string.format("%d")?
--- Guards against the NaN/inf that division by a zero XP maximum produces.
--- n ~= n is the standard NaN test; NaN is the only value not equal to itself.
local function IsFinite(n)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- ── Constants ─────────────────────────────────────────────────────────────────
local RESTED_RATE_PER_HOUR = 0.05 -- 5% of level per 8 hours (in inn/capital)
local QUEST_AVG_XP_PCT = 0.04 -- average quest = ~4% of a level

-- ── Public API ────────────────────────────────────────────────────────────────

--- Get a contextual rest suggestion based on current state.
--- @return string|nil suggestion — formatted text, or nil if nothing useful
function RO:GetSuggestion()
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 90
    if (UnitLevel("player") or 1) >= maxLevel then
        return nil
    end

    local currentXP = U.SafeNum(UnitXP("player"))
    local maxXP = U.SafeNum(UnitXPMax("player"))

    -- UnitXPMax can legitimately return 0 — during login before XP data arrives,
    -- and on XP-locked characters. `or 1` does not catch that, because 0 is not
    -- nil, so every ratio below became 0/0 (NaN) or n/0 (inf) and string.format
    -- raised "integer overflow attempting to store -nan(ind)".
    -- With no XP scale there is no meaningful suggestion to make.
    if maxXP <= 0 then
        return nil
    end

    local remaining = maxXP - currentXP
    local pct = currentXP / maxXP
    local rested = U.SafeNum(GetXPExhaustion())
    local isResting = IsResting()

    -- Suggestion 1: "One more quest to ding"
    local avgQuestXP = maxXP * QUEST_AVG_XP_PCT
    if avgQuestXP > 0 and remaining > 0 and remaining <= avgQuestXP * 1.5 then
        local questsNeeded = math.ceil(remaining / avgQuestXP)
        if IsFinite(questsNeeded) and questsNeeded >= 1 then
            return string.format(
                "|cFF4AFF7A%d quest%s to level %d!|r",
                questsNeeded,
                questsNeeded > 1 and "s" or "",
                (UnitLevel("player") or 1) + 1
            )
        end
    end

    -- Suggestion 2: "Log off in an inn"
    if not isResting and rested == 0 and pct < 0.5 then
        return "|cFF55CCFFFind an inn before logging off — rested XP doubles quest gains.|r"
    end

    -- Suggestion 3: Rested XP depletion warning
    if rested > 0 and rested < maxXP * 0.1 and IsFinite(rested) then
        return string.format("|cFFFFD100Rested XP almost gone (%d remaining)|r", rested)
    end

    -- Suggestion 4: Full rested timer
    if isResting and rested < maxXP * 1.5 then
        local deficit = (maxXP * 1.5) - rested
        local ratePerHour = maxXP * RESTED_RATE_PER_HOUR
        local hoursToFull = ratePerHour > 0 and (deficit / ratePerHour) or 0
        if IsFinite(hoursToFull) and hoursToFull > 1 then
            return string.format("|cFF888780Rested XP full in %.1f hours|r", hoursToFull)
        end
    end

    return nil
end

function RO:Init()
    -- Passive module — queried by XPTracker or QuestTracker on demand
end

function RO:OnEvent(event, ...)
    -- Could trigger suggestion display on PLAYER_UPDATE_RESTING
end

RO.SlashCommands = {}
