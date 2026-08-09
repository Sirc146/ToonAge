-- ToonAge/Modules/DeathRecovery.lua
-- Death Recovery Intelligence: after dying, shows smart resurrection options
-- with cost/benefit analysis instead of just a corpse arrow.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local DR = {}
TA:RegisterModule("DeathRecovery", DR)

-- ── Constants ─────────────────────────────────────────────────────────────────
local SPIRIT_RES_DEBUFF_DURATION = 600  -- 10 minutes of resurrection sickness
local SPIRIT_RES_DURABILITY_LOSS = 0.25 -- 25% durability loss

-- ── State ─────────────────────────────────────────────────────────────────────
DR.deathTime     = 0
DR.deathMap      = 0
DR.deathX        = 0
DR.deathY        = 0
DR.shownAdvice   = false

-- ── Analysis ──────────────────────────────────────────────────────────────────

--- Calculate the estimated repair cost at current gear level.
function DR:EstimateRepairCost()
    -- Rough estimate: ilvl × slot count × gold-per-durability-point
    local totalDurability = 0
    local totalMax = 0
    for slot = 1, 18 do
        if slot ~= 4 then  -- skip shirt
            local current, maximum = GetInventoryItemDurability(slot)
            if current and maximum then
                totalDurability = totalDurability + current
                totalMax = totalMax + maximum
            end
        end
    end

    if totalMax == 0 then return 0 end

    -- Approximate repair cost based on item level
    -- At ilvl 600+, full repair is roughly 200-500g
    local avgIlvl = GetAverageItemLevel and select(1, GetAverageItemLevel()) or 500
    local fullRepairGold = avgIlvl * 0.5  -- rough approximation

    -- Spirit res only costs 25% durability
    local spiritResCost = fullRepairGold * SPIRIT_RES_DURABILITY_LOSS
    return spiritResCost, fullRepairGold
end

--- Analyze death situation and provide recommendation.
--- @return table advice — { recommendation, corpseRunTime, spiritResSaves, repairCost, ... }
function DR:Analyze()
    local now = GetTime()
    local timeSinceDeath = now - self.deathTime

    -- Estimate corpse run time (distance from spirit healer to corpse)
    -- We can't easily calculate this without knowing graveyard location,
    -- but we can use elapsed time as a proxy after the player has been
    -- running for a bit.
    local corpseRunEstimate = 30  -- default: assume 30 seconds to body

    -- Get player level for sickness check (no sickness below level 10)
    local level = UnitLevel("player") or 1
    local hasSicknessRisk = level >= 10

    -- Calculate cost/benefit
    local spiritResCost, _ = self:EstimateRepairCost()
    local timeSaved = corpseRunEstimate  -- time saved by spirit res

    local advice = {
        hasSicknessRisk = hasSicknessRisk,
        spiritResCost   = spiritResCost,
        timeSaved       = timeSaved,
        recommendation  = "corpserun",  -- default: run back
    }

    -- Decision logic
    if not hasSicknessRisk then
        -- Below level 10: spirit res is FREE (no sickness, no durability loss)
        advice.recommendation = "spiritres"
        advice.reason = "No resurrection sickness below level 10 — spirit res is free!"
    elseif timeSaved > 45 and spiritResCost < 50 then
        -- Long run + cheap repair: spirit res might be worth it
        advice.recommendation = "consider_spirit"
        advice.reason = string.format("Spirit res saves ~%ds but costs ~%dg repair", timeSaved, spiritResCost)
    else
        advice.recommendation = "corpserun"
        advice.reason = "Run back to corpse — saves gold and avoids 10min sickness"
    end

    return advice
end

-- ── Display ───────────────────────────────────────────────────────────────────

function DR:ShowDeathAdvice()
    if self.shownAdvice then return end
    self.shownAdvice = true

    local advice = self:Analyze()

    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Death Recovery ━━━|r")

    if advice.recommendation == "spiritres" then
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A  ► Spirit Resurrect (recommended)|r")
        TA:Raw(TA.LOG.OUTPUT, "    " .. advice.reason)
    elseif advice.recommendation == "consider_spirit" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100  ► Consider Spirit Res:|r " .. advice.reason)
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780  ► Or run back to corpse (free, but slower)|r")
    else
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A  ► Run back to corpse (recommended)|r")
        TA:Raw(TA.LOG.OUTPUT, "    " .. advice.reason)
    end

    -- Tip: nearby quest objectives after res
    local QT = TA:GetModule("QuestTracker")
    if QT and QT.guideID then
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780  After res: guide continues from current step.|r")
    end
end

-- ── Event handling ────────────────────────────────────────────────────────────

function DR:OnEvent(event, ...)
    if event == "PLAYER_DEAD" then
        self.deathTime = GetTime()
        self.deathMap = C_Map.GetBestMapForUnit("player") or 0
        self.shownAdvice = false

        local pos = self.deathMap > 0 and C_Map.GetPlayerMapPosition(self.deathMap, "player")
        if pos then
            self.deathX, self.deathY = pos:GetXY()
        end

        -- Show advice after a short delay (let the release dialog appear)
        C_Timer.After(1.5, function()
            DR:ShowDeathAdvice()
        end)

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        self.shownAdvice = true  -- stop showing after res
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function DR:Init()
    TA.eventFrame:RegisterEvent("PLAYER_DEAD")
    TA.eventFrame:RegisterEvent("PLAYER_ALIVE")
    TA.eventFrame:RegisterEvent("PLAYER_UNGHOST")
end

DR.SlashCommands = {}
