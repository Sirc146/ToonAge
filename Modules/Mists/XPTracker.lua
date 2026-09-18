-- ToonAge/Modules/XPTracker.lua (Classic — MoP 50504)
-- XP/Hour Dashboard: tracks XP gain rate, predicts level-up ETA,
-- compares leveling speed across alts. Shows inline in tracker status.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local XP = {}
TA:RegisterModule("XPTracker", XP)

-- ── State ─────────────────────────────────────────────────────────────────────
XP.sessionStart    = 0
XP.sessionXP       = 0
XP.samples         = {}      -- { {time, totalXP}, ... } rolling window
XP.lastKnownXP    = 0
XP.lastKnownMax   = 0
XP.levelStartTime  = 0
local SAMPLE_WINDOW = 300    -- 5 minutes rolling average
local MAX_SAMPLES   = 60

-- ── Core XP functions ─────────────────────────────────────────────────────────

local function GetTotalXP()
    return UnitXP("player") or 0
end

local function GetMaxXP()
    return UnitXPMax("player") or 1
end

local function GetLevel()
    return UnitLevel("player") or 1
end

local function IsMaxLevel()
    -- MoP Classic max level is 90
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 90
    return GetLevel() >= maxLevel
end

-- ── XP/Hour calculation ───────────────────────────────────────────────────────

function XP:RecordSample()
    local now = GetTime()
    local currentXP = GetTotalXP()

    -- Track session total
    if currentXP > self.lastKnownXP and self.lastKnownXP > 0 then
        local gained = currentXP - self.lastKnownXP
        self.sessionXP = self.sessionXP + gained
    end
    self.lastKnownXP = currentXP
    self.lastKnownMax = GetMaxXP()

    -- Add to rolling samples
    table.insert(self.samples, { time = now, xp = currentXP, level = GetLevel() })

    -- Trim old samples outside the window
    while #self.samples > MAX_SAMPLES do
        table.remove(self.samples, 1)
    end
    while #self.samples > 1 and (now - self.samples[1].time) > SAMPLE_WINDOW do
        table.remove(self.samples, 1)
    end
end

--- Calculate XP per hour based on rolling samples.
--- @return number xpPerHour, number xpPerMinute
function XP:GetRate()
    if #self.samples < 2 then return 0, 0 end

    local first = self.samples[1]
    local last  = self.samples[#self.samples]
    local timeDiff = last.time - first.time
    if timeDiff < 5 then return 0, 0 end  -- need at least 5 seconds of data

    -- Handle level-ups within the window (XP resets to 0)
    local totalGained = 0
    for i = 2, #self.samples do
        local prev = self.samples[i-1]
        local cur  = self.samples[i]
        if cur.level > prev.level then
            -- Level-up occurred: gained was (prevMax - prevXP) + curXP
            totalGained = totalGained + cur.xp  -- approximate
        elseif cur.xp >= prev.xp then
            totalGained = totalGained + (cur.xp - prev.xp)
        end
    end

    local xpPerSec = totalGained / timeDiff
    return xpPerSec * 3600, xpPerSec * 60
end

--- Calculate ETA to next level.
--- @return number seconds, or -1 if max level or no data
function XP:GetLevelETA()
    if IsMaxLevel() then return -1 end

    local _, xpPerMin = self:GetRate()
    if xpPerMin <= 0 then return -1 end

    local remaining = self.lastKnownMax - self.lastKnownXP
    return remaining / xpPerMin * 60  -- seconds
end

--- Get formatted ETA string for display.
function XP:GetETAString()
    local eta = self:GetLevelETA()
    if eta < 0 then return "" end
    if eta < 60 then return string.format("|cFF4AFF7A<1m to %d|r", GetLevel() + 1) end
    if eta < 3600 then
        return string.format("|cFF4AFF7ALvl %d in %dm|r", GetLevel() + 1, math.floor(eta / 60))
    end
    return string.format("|cFFFFD100Lvl %d in %dh %dm|r", GetLevel() + 1,
        math.floor(eta / 3600), math.floor((eta % 3600) / 60))
end

--- Get session summary string.
function XP:GetSessionSummary()
    local elapsed = GetTime() - self.sessionStart
    local xpPerHour = self:GetRate()
    local pct = self.lastKnownMax > 0 and (self.lastKnownXP / self.lastKnownMax * 100) or 0

    return {
        sessionTime = elapsed,
        sessionXP   = self.sessionXP,
        xpPerHour   = xpPerHour,
        currentXP   = self.lastKnownXP,
        maxXP       = self.lastKnownMax,
        pct         = pct,
        level       = GetLevel(),
        eta         = self:GetLevelETA(),
    }
end

-- ── Rested XP tracking ────────────────────────────────────────────────────────

function XP:GetRestedInfo()
    local rested = GetXPExhaustion() or 0
    local isResting = IsResting()
    local maxRested = self.lastKnownMax * 1.5  -- rested cap is 150% of current level
    local restedPct = maxRested > 0 and (rested / maxRested * 100) or 0
    return rested, isResting, restedPct
end

-- ── Cross-alt comparison (saved to account DB) ────────────────────────────────

function XP:SaveAltData()
    if not TA.db then return end
    TA.db.xpHistory = TA.db.xpHistory or {}

    local key = TA.charKey or (UnitName("player") .. "-" .. GetRealmName())
    TA.db.xpHistory[key] = TA.db.xpHistory[key] or {}

    local entry = TA.db.xpHistory[key]
    entry.level     = GetLevel()
    entry.class     = select(2, UnitClass("player"))
    entry.xpPerHour = self:GetRate()
    entry.lastSeen  = time()
end

function XP:GetAltComparison()
    if not TA.db or not TA.db.xpHistory then return nil end

    local myRate = self:GetRate()
    if myRate <= 0 then return nil end

    local currentKey = TA.charKey or ""
    local comparisons = {}

    for key, data in pairs(TA.db.xpHistory) do
        if key ~= currentKey and data.xpPerHour and data.xpPerHour > 0 then
            local diff = ((myRate - data.xpPerHour) / data.xpPerHour) * 100
            table.insert(comparisons, {
                name    = key,
                class   = data.class,
                level   = data.level,
                rate    = data.xpPerHour,
                diffPct = diff,
            })
        end
    end

    return comparisons
end

-- ── Event handling ────────────────────────────────────────────────────────────

function XP:OnEvent(event, ...)
    if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        self:RecordSample()
        -- Save alt data periodically
        if math.random(1, 5) == 1 then self:SaveAltData() end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function XP:Init()
    if IsMaxLevel() then return end  -- no point tracking at max level

    TA.eventFrame:RegisterEvent("PLAYER_XP_UPDATE")

    self.sessionStart  = GetTime()
    self.lastKnownXP   = GetTotalXP()
    self.lastKnownMax  = GetMaxXP()
    self.levelStartTime = GetTime()

    -- Sample every 10 seconds
    C_Timer.NewTicker(10, function()
        if not IsMaxLevel() then
            XP:RecordSample()
        end
    end)

    -- Save alt data periodically (every 60s)
    C_Timer.NewTicker(60, function()
        XP:SaveAltData()
    end)
end

-- ── Slash command ─────────────────────────────────────────────────────────────

XP.SlashCommands = {
    xp = function(self)
        if IsMaxLevel() then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA XP]|r Max level reached — no XP tracking needed.")
            return
        end

        local s = self:GetSessionSummary()
        local mins = math.floor(s.sessionTime / 60)

        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge XP Dashboard ━━━|r")
        TA:Raw(TA.LOG.OUTPUT, string.format("  Level: |cFFFFFFFF%d|r  (%.1f%%)", s.level, s.pct))
        TA:Raw(TA.LOG.OUTPUT, string.format("  XP/Hour: |cFF4AFF7A%s|r",
            U.FormatNumber and U.FormatNumber(s.xpPerHour) or string.format("%.0f", s.xpPerHour)))
        TA:Raw(TA.LOG.OUTPUT, string.format("  Session: %s XP in %dm",
            U.FormatNumber and U.FormatNumber(s.sessionXP) or tostring(s.sessionXP), mins))

        if s.eta > 0 then
            local etaMins = math.floor(s.eta / 60)
            TA:Raw(TA.LOG.OUTPUT, string.format("  |cFF4AFF7ALevel %d ETA: %dm|r", s.level + 1, etaMins))
        end

        -- Rested info
        local rested, isResting, restedPct = self:GetRestedInfo()
        if rested > 0 then
            TA:Raw(TA.LOG.OUTPUT, string.format("  Rested: %s (%.0f%%) %s",
                U.FormatNumber and U.FormatNumber(rested) or tostring(rested),
                restedPct,
                isResting and "|cFF4AFF7A(resting now)|r" or ""))
        end

        -- Alt comparison
        local alts = self:GetAltComparison()
        if alts and #alts > 0 then
            TA:Raw(TA.LOG.OUTPUT, "  |cFF888780Compared to your alts:|r")
            for _, alt in ipairs(alts) do
                local sign = alt.diffPct >= 0 and "+" or ""
                local color = alt.diffPct >= 0 and "|cFF4AFF7A" or "|cFFFF6666"
                TA:Raw(TA.LOG.OUTPUT, string.format("    %s — %s%s%.0f%%|r faster",
                    alt.name, color, sign, alt.diffPct))
            end
        end
    end,
}
