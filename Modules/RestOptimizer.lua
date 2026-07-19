-- ToonAge/Modules/RestOptimizer.lua
-- Micro-Rest Optimization: tracks rested XP, suggests "one more quest to ding"
-- or "log off in inn, rested charges in 6h". Inn proximity detection.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local RO = {}
TA:RegisterModule("RestOptimizer", RO)

-- ── Constants ─────────────────────────────────────────────────────────────────
local RESTED_RATE_PER_HOUR = 0.05  -- 5% of level per 8 hours (in inn/capital)
local QUEST_AVG_XP_PCT    = 0.04   -- average quest = ~4% of a level

-- ── Public API ────────────────────────────────────────────────────────────────

--- Get a contextual rest suggestion based on current state.
--- @return string|nil suggestion — formatted text, or nil if nothing useful
function RO:GetSuggestion()
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 90
    if (UnitLevel("player") or 1) >= maxLevel then return nil end

    local currentXP = UnitXP("player") or 0
    local maxXP     = UnitXPMax("player") or 1
    local remaining = maxXP - currentXP
    local pct       = currentXP / maxXP
    local rested    = GetXPExhaustion() or 0
    local isResting = IsResting()

    -- Suggestion 1: "One more quest to ding"
    local avgQuestXP = maxXP * QUEST_AVG_XP_PCT
    if remaining <= avgQuestXP * 1.5 then
        local questsNeeded = math.ceil(remaining / avgQuestXP)
        return string.format("|cFF4AFF7A%d quest%s to level %d!|r",
            questsNeeded, questsNeeded > 1 and "s" or "", UnitLevel("player") + 1)
    end

    -- Suggestion 2: "Log off in an inn"
    if not isResting and rested == 0 and pct < 0.5 then
        return "|cFF55CCFFFind an inn before logging off — rested XP doubles quest gains.|r"
    end

    -- Suggestion 3: Rested XP depletion warning
    if rested > 0 and rested < maxXP * 0.1 then
        return string.format("|cFFFFD100Rested XP almost gone (%d remaining)|r", rested)
    end

    -- Suggestion 4: Full rested timer
    if isResting and rested < maxXP * 1.5 then
        local deficit = (maxXP * 1.5) - rested
        local hoursToFull = deficit / (maxXP * RESTED_RATE_PER_HOUR)
        if hoursToFull > 1 then
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
