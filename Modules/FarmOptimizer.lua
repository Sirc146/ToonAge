-- ToonAge/Modules/FarmOptimizer.lua
-- Real-time farming optimizer brain module.
-- ALL data is session-local — lost on logout/reload. No charDB writes.
-- Provides: efficiency tracking, cluster detection, heat mapping,
-- smart suggestions, and profession-aware route scoring.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local FarmOpt = {}
TA:RegisterModule("FarmOptimizer", FarmOpt)

local FO = TA.Data.FarmOptimizer

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSTANTS & SHORTCUTS
-- ═══════════════════════════════════════════════════════════════════════════════

local SCORING            = FO.SCORING
local GATHER_SUBCLASS    = FO.GATHER_SUBCLASS
local ITEM_VALUES        = FO.ITEM_VALUES
local DEFAULT_VALUE      = FO.DEFAULT_ITEM_VALUE
local HEAT_COLORS        = FO.HEAT_COLORS
local GRADE_COLORS       = FO.GRADE_COLORS
local PROFESSION_SKILLS  = FO.PROFESSION_SKILLLINES

local POSITION_RING_SIZE = 20
local GetTime            = GetTime

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. PROFESSION DETECTION
-- ═══════════════════════════════════════════════════════════════════════════════

local cachedProfs = nil

function FarmOpt:GetGatheringProfessions()
    if cachedProfs then return cachedProfs end

    cachedProfs = {}
    local ok, prof1, prof2 = pcall(GetProfessions)
    if not ok then return cachedProfs end

    local slots = { prof1, prof2 }
    for _, slot in ipairs(slots) do
        if slot then
            local _, _, skillLine = pcall(GetProfessionInfo, slot)
            if skillLine then
                if skillLine == PROFESSION_SKILLS.HERBALISM then
                    cachedProfs.herbalism = true
                elseif skillLine == PROFESSION_SKILLS.MINING then
                    cachedProfs.mining = true
                elseif skillLine == PROFESSION_SKILLS.SKINNING then
                    cachedProfs.skinning = true
                end
            end
        end
    end

    return cachedProfs
end

function FarmOpt:HasGatheringProfession()
    local profs = self:GetGatheringProfessions()
    return profs.herbalism or profs.mining or profs.skinning or false
end

local function InvalidateProfCache()
    cachedProfs = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. SESSION DATA ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

FarmOpt.session = nil

local function CreateSession()
    return {
        startTime    = GetTime(),
        nodes        = {},
        totalDistance = 0,
        totalIdleTime  = 0,
        totalCombatTime = 0,
        positions    = {},
        combatStart  = nil,
        herbCount    = 0,
        oreCount     = 0,
        skinCount    = 0,
    }
end

function FarmOpt:ResetSession()
    self.session = CreateSession()
    self.rollingWindow = {}
    self.clusters = {}
    self.lastHeat = nil
end

function FarmOpt:IsActive()
    return self.session ~= nil and #self.session.nodes > 0
end

local function EnsureSession()
    if not FarmOpt.session then
        FarmOpt.session = CreateSession()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. MINIMAP NODE SCANNER (LOOT_OPENED)
-- ═══════════════════════════════════════════════════════════════════════════════

local function DetectGatherType()
    local numItems = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, numItems do
        local ok, link = pcall(GetLootSlotLink, i)
        if ok and link then
            local ok2, _, _, _, _, classID, subclassID = pcall(GetItemInfoInstant, link)
            if ok2 and classID == 7 then
                if subclassID == GATHER_SUBCLASS.HERB then return "herb" end
                if subclassID == GATHER_SUBCLASS.ORE  then return "ore" end
                if subclassID == GATHER_SUBCLASS.LEATHER then return "skin" end
            end
        end
    end
    return nil
end

local function DetectSkinning()
    -- Skinning: loot from a creature (check last target)
    if UnitExists("target") and UnitIsDead("target") and UnitCreatureType("target") then
        local numItems = GetNumLootItems and GetNumLootItems() or 0
        for i = 1, numItems do
            local ok, link = pcall(GetLootSlotLink, i)
            if ok and link then
                local ok2, _, _, _, _, classID, subclassID = pcall(GetItemInfoInstant, link)
                if ok2 and classID == 7 and subclassID == GATHER_SUBCLASS.LEATHER then
                    return true
                end
            end
        end
    end
    return false
end

local function ComputeLootValue()
    local totalValue = 0
    local primaryItemID = nil
    local numItems = GetNumLootItems and GetNumLootItems() or 0

    for i = 1, numItems do
        local ok, link = pcall(GetLootSlotLink, i)
        if ok and link then
            local ok2, itemID = pcall(GetItemInfoInstant, link)
            if ok2 and itemID then
                local qty = select(3, GetLootSlotInfo(i)) or 1
                local value = ITEM_VALUES[itemID] or DEFAULT_VALUE
                totalValue = totalValue + (value * qty)
                if not primaryItemID then primaryItemID = itemID end
            end
        end
    end

    return totalValue, primaryItemID
end

local function RecordGatherNode()
    local gatherType = DetectGatherType()

    -- Check for skinning via creature target if no herb/ore detected
    if not gatherType and DetectSkinning() then
        gatherType = "skin"
    end

    if not gatherType then return end

    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not mapID then return end

    local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok2 or not pos then return end

    local px, py = pos:GetXY()
    if px == 0 and py == 0 then return end

    EnsureSession()

    local value, itemID = ComputeLootValue()
    local now = GetTime()

    local entry = {
        x      = px,
        y      = py,
        mapID  = mapID,
        type   = gatherType,
        itemID = itemID,
        value  = value,
        time   = now,
    }

    -- Add to session
    table.insert(FarmOpt.session.nodes, entry)

    -- Behavior tracking
    if gatherType == "herb" then
        FarmOpt.session.herbCount = FarmOpt.session.herbCount + 1
    elseif gatherType == "ore" then
        FarmOpt.session.oreCount = FarmOpt.session.oreCount + 1
    elseif gatherType == "skin" then
        FarmOpt.session.skinCount = FarmOpt.session.skinCount + 1
    end

    -- Add to rolling window
    table.insert(FarmOpt.rollingWindow, entry)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. PLAYER MOVEMENT TRACKER
-- ═══════════════════════════════════════════════════════════════════════════════

local movementTicker = nil
local lastPos        = nil
local lastPosTime    = 0
local idleStart      = nil
local posRing        = {}
local posRingIdx     = 0

local function DistanceMapUnits(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function OnMovementTick()
    if not FarmOpt.session then return end

    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not mapID then return end

    local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok2 or not pos then return end

    local px, py = pos:GetXY()
    if px == 0 and py == 0 then return end

    local now = GetTime()

    if lastPos then
        local dist = DistanceMapUnits(px, py, lastPos.x, lastPos.y)
        local yards = dist * SCORING.YARDS_PER_MAP_UNIT

        FarmOpt.session.totalDistance = FarmOpt.session.totalDistance + yards

        -- Idle detection
        if yards < 0.5 then  -- less than 0.5 yards in interval = stationary
            if not idleStart then
                idleStart = now
            elseif (now - idleStart) > SCORING.IDLE_THRESHOLD then
                FarmOpt.session.totalIdleTime = FarmOpt.session.totalIdleTime
                    + SCORING.POSITION_INTERVAL
            end
        else
            idleStart = nil
        end
    end

    -- Update last position
    lastPos = { x = px, y = py }
    lastPosTime = now

    -- Ring buffer for recent positions
    posRingIdx = (posRingIdx % POSITION_RING_SIZE) + 1
    posRing[posRingIdx] = { x = px, y = py, time = now }

    -- Prune rolling window on each tick
    FarmOpt:PruneWindow()
end

local function StartMovementTicker()
    if movementTicker then return end
    movementTicker = C_Timer.NewTicker(SCORING.POSITION_INTERVAL, OnMovementTick)
end

local function StopMovementTicker()
    if movementTicker then
        movementTicker:Cancel()
        movementTicker = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. ROLLING WINDOW MEMORY
-- ═══════════════════════════════════════════════════════════════════════════════

FarmOpt.rollingWindow = {}

function FarmOpt:PruneWindow()
    local now = GetTime()
    local cutoff = now - SCORING.WINDOW_DURATION
    local window = self.rollingWindow
    local i = 1
    while i <= #window do
        if window[i].time < cutoff then
            table.remove(window, i)
        else
            i = i + 1
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. EFFICIENCY CALCULATOR
-- ═══════════════════════════════════════════════════════════════════════════════

function FarmOpt:GetNodesPerMinute()
    local window = self.rollingWindow
    if #window < 1 then return 0 end

    local now = GetTime()
    local oldest = window[1].time
    local elapsed = now - oldest
    if elapsed < 1 then return 0 end

    return #window / (elapsed / 60)
end

function FarmOpt:GetGoldPerHour()
    local window = self.rollingWindow
    if #window < 1 then return 0 end

    local now = GetTime()
    local oldest = window[1].time
    local elapsed = now - oldest
    if elapsed < 1 then return 0 end

    local totalValue = 0
    for _, entry in ipairs(window) do
        totalValue = totalValue + (entry.value or 0)
    end

    -- Extrapolate to hourly, convert copper to gold
    local hourly = (totalValue / elapsed) * 3600
    return hourly / 10000  -- copper to gold
end

function FarmOpt:GetAvgDistancePerNode()
    if not self.session or #self.session.nodes < 1 then return 0 end
    return self.session.totalDistance / #self.session.nodes
end

function FarmOpt:GetAvgTimePerNode()
    local window = self.rollingWindow
    if #window < 2 then return 0 end

    local now = GetTime()
    local oldest = window[1].time
    local elapsed = now - oldest
    return elapsed / #window
end

function FarmOpt:GetEfficiencyGrade()
    local npm = self:GetNodesPerMinute()
    if npm >= SCORING.GRADE_A then return "A" end
    if npm >= SCORING.GRADE_B then return "B" end
    if npm >= SCORING.GRADE_C then return "C" end
    if npm >= SCORING.GRADE_D then return "D" end
    return "F"
end

function FarmOpt:GetRouteScore()
    -- Composite score 0-100 combining multiple metrics
    local npm = self:GetNodesPerMinute()
    local grade = self:GetEfficiencyGrade()

    -- Nodes/minute score (0-40 points, capped at GRADE_A threshold)
    local npmScore = math.min(npm / SCORING.GRADE_A, 1.0) * 40

    -- Idle penalty (0-20 points lost for excessive idle)
    local idlePenalty = 0
    if self.session and self.session.startTime then
        local elapsed = GetTime() - self.session.startTime
        if elapsed > 0 then
            local idleRatio = self.session.totalIdleTime / elapsed
            idlePenalty = math.min(idleRatio * 40, 20)
        end
    end

    -- Combat penalty (0-15 points lost for time in combat)
    local combatPenalty = 0
    if self.session and self.session.startTime then
        local elapsed = GetTime() - self.session.startTime
        if elapsed > 0 then
            local combatRatio = self.session.totalCombatTime / elapsed
            combatPenalty = math.min(combatRatio * 30, 15)
        end
    end

    -- Distance efficiency (0-25 points; less distance per node = better)
    local distScore = 25
    local avgDist = self:GetAvgDistancePerNode()
    if avgDist > 0 then
        -- Ideal ~150 yards per node; penalize linearly beyond that
        distScore = math.max(0, 25 - math.max(0, (avgDist - 150) / 20))
    end

    local total = npmScore + distScore - idlePenalty - combatPenalty
    return math.max(0, math.min(100, math.floor(total + 0.5)))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. CLUSTER DETECTION ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

FarmOpt.clusters = {}

function FarmOpt:DetectClusters()
    local window = self.rollingWindow
    if #window < SCORING.CLUSTER_MIN_NODES then
        self.clusters = {}
        return
    end

    local now = GetTime()
    local radius = SCORING.CLUSTER_RADIUS
    local radiusSq = radius * radius
    local assigned = {}
    local newClusters = {}

    for i, node in ipairs(window) do
        if not assigned[i] then
            -- Start a potential cluster around this node
            local clusterNodes = { node }
            assigned[i] = true

            for j = i + 1, #window do
                if not assigned[j] then
                    local other = window[j]
                    if node.mapID == other.mapID then
                        local dx = node.x - other.x
                        local dy = node.y - other.y
                        if (dx * dx + dy * dy) <= radiusSq then
                            table.insert(clusterNodes, other)
                            assigned[j] = true
                        end
                    end
                end
            end

            if #clusterNodes >= SCORING.CLUSTER_MIN_NODES then
                -- Compute centroid
                local cx, cy = 0, 0
                local lastTime = 0
                for _, n in ipairs(clusterNodes) do
                    cx = cx + n.x
                    cy = cy + n.y
                    if n.time > lastTime then lastTime = n.time end
                end
                cx = cx / #clusterNodes
                cy = cy / #clusterNodes

                -- Strength fades over time since last node
                local age = now - lastTime
                local strength = math.max(0, 1.0 - (age / SCORING.CLUSTER_FADE_TIME))

                table.insert(newClusters, {
                    cx           = cx,
                    cy           = cy,
                    nodes        = clusterNodes,
                    strength     = strength,
                    lastNodeTime = lastTime,
                    mapID        = node.mapID,
                })
            end
        end
    end

    self.clusters = newClusters
end

function FarmOpt:GetActiveClusters()
    local active = {}
    for _, cluster in ipairs(self.clusters) do
        if cluster.strength > 0 then
            table.insert(active, cluster)
        end
    end
    return active
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. ZONE HEAT RATING
-- ═══════════════════════════════════════════════════════════════════════════════

function FarmOpt:GetZoneHeat()
    local count = #self.rollingWindow
    if count >= SCORING.HEAT_HOT then return "Hot" end
    if count >= SCORING.HEAT_WARM then return "Warm" end
    return "Cold"
end

function FarmOpt:GetHeatColor()
    local heat = self:GetZoneHeat()
    local color = HEAT_COLORS[heat] or HEAT_COLORS.Cold
    return color[1], color[2], color[3]
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. PROFESSION BEHAVIOR ANALYZER
-- ═══════════════════════════════════════════════════════════════════════════════

function FarmOpt:GetPrimaryBehavior()
    if not self.session then return "mixed" end

    local h = self.session.herbCount
    local o = self.session.oreCount
    local s = self.session.skinCount
    local total = h + o + s

    if total < 1 then return "mixed" end

    -- If one type accounts for 70%+ of gathers, it's the primary
    if h / total >= 0.70 then return "herb" end
    if o / total >= 0.70 then return "ore" end
    if s / total >= 0.70 then return "skin" end

    return "mixed"
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 10. SMART SUGGESTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

local lastSuggestionTime = 0
local SUGGESTION_COOLDOWN = 15  -- don't spam suggestions

function FarmOpt:GetSuggestion()
    local now = GetTime()
    if (now - lastSuggestionTime) < SUGGESTION_COOLDOWN then return nil end

    -- Check idle
    if idleStart and (now - idleStart) > 10 then
        lastSuggestionTime = now
        return "Movement paused \226\128\148 timer still running"
    end

    -- Heat transition: was Hot, now Cold
    local currentHeat = self:GetZoneHeat()
    if self.lastHeat == "Hot" and currentHeat == "Cold" then
        self.lastHeat = currentHeat
        lastSuggestionTime = now
        return "This area is cooling down"
    end
    self.lastHeat = currentHeat

    -- Hot zone + good efficiency
    if currentHeat == "Hot" then
        local grade = self:GetEfficiencyGrade()
        if grade == "A" or grade == "B" then
            lastSuggestionTime = now
            return "Hot zone detected \226\128\148 stay here"
        end
    end

    -- Efficiency trending down (compare last 2 min vs previous 2 min)
    if #self.rollingWindow >= 4 then
        local recentCount, olderCount = 0, 0
        local twoMinAgo = now - 120
        local fourMinAgo = now - 240

        for _, entry in ipairs(self.rollingWindow) do
            if entry.time >= twoMinAgo then
                recentCount = recentCount + 1
            elseif entry.time >= fourMinAgo then
                olderCount = olderCount + 1
            end
        end

        if olderCount > 0 and recentCount < (olderCount * 0.5) then
            lastSuggestionTime = now
            return "Efficiency dropping \226\128\148 consider moving"
        end
    end

    -- Cluster forming in a direction
    self:DetectClusters()
    local clusters = self:GetActiveClusters()
    if #clusters > 0 and lastPos then
        local best = clusters[1]
        for _, c in ipairs(clusters) do
            if c.strength > best.strength then best = c end
        end

        -- Determine cardinal direction
        local dx = best.cx - lastPos.x
        local dy = best.cy - lastPos.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > SCORING.CLUSTER_RADIUS then
            local direction
            if math.abs(dx) > math.abs(dy) then
                direction = dx > 0 and "east" or "west"
            else
                direction = dy > 0 and "south" or "north"
            end
            lastSuggestionTime = now
            return "Cluster forming to the " .. direction
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 11. EVENT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "LOOT_OPENED" then
        RecordGatherNode()

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        EnsureSession()
        FarmOpt.session.combatStart = GetTime()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        if FarmOpt.session and FarmOpt.session.combatStart then
            local duration = GetTime() - FarmOpt.session.combatStart
            FarmOpt.session.totalCombatTime = FarmOpt.session.totalCombatTime + duration
            FarmOpt.session.combatStart = nil
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Mark zone change; keep session running but update clusters
        if FarmOpt:IsActive() then
            FarmOpt:DetectClusters()
        end

    elseif event == "PLAYER_LEAVING_WORLD" then
        -- End session cleanly
        StopMovementTicker()

    elseif event == "SKILL_LINES_CHANGED" then
        InvalidateProfCache()
        -- Re-check if we should start the ticker
        if FarmOpt:HasGatheringProfession() then
            StartMovementTicker()
        end
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 12. INIT
-- ═══════════════════════════════════════════════════════════════════════════════

function FarmOpt:Init()
    -- Register events
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    eventFrame:RegisterEvent("SKILL_LINES_CHANGED")

    -- Initialize session
    self.session = CreateSession()
    self.rollingWindow = {}
    self.clusters = {}
    self.lastHeat = nil

    -- Start movement tracker if player has gathering
    if self:HasGatheringProfession() then
        StartMovementTicker()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 13. SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

local function PrintSessionSummary()
    if not FarmOpt:IsActive() then
        print("|cff00ccff[ToonAge FarmOpt]|r No active session data.")
        return
    end

    local s = FarmOpt.session
    local elapsed = GetTime() - s.startTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)

    local npm = FarmOpt:GetNodesPerMinute()
    local gph = FarmOpt:GetGoldPerHour()
    local grade = FarmOpt:GetEfficiencyGrade()
    local score = FarmOpt:GetRouteScore()
    local heat = FarmOpt:GetZoneHeat()
    local behavior = FarmOpt:GetPrimaryBehavior()

    local gradeColor = GRADE_COLORS[grade] or { 1, 1, 1 }
    local gradeHex = string.format("|cff%02x%02x%02x",
        gradeColor[1] * 255, gradeColor[2] * 255, gradeColor[3] * 255)

    print("|cff00ccff[ToonAge FarmOpt]|r Session Summary:")
    print(string.format("  Duration: %dm %ds | Nodes: %d | Type: %s",
        minutes, seconds, #s.nodes, behavior))
    print(string.format("  Nodes/min: %.1f | Gold/hr: %.0fg", npm, gph))
    print(string.format("  Grade: %s%s|r | Score: %d/100 | Heat: %s",
        gradeHex, grade, score, heat))
    print(string.format("  Distance: %.0f yds | Idle: %.0fs | Combat: %.0fs",
        s.totalDistance, s.totalIdleTime, s.totalCombatTime))

    local suggestion = FarmOpt:GetSuggestion()
    if suggestion then
        print(string.format("  Tip: %s", suggestion))
    end
end

local function HandleSlash(msg)
    msg = (msg or ""):lower():trim()
    if msg == "reset" then
        FarmOpt:ResetSession()
        print("|cff00ccff[ToonAge FarmOpt]|r Session reset.")
    else
        PrintSessionSummary()
    end
end

SLASH_TOONAGEFARM1 = "/farm"
SLASH_TOONAGEFARM2 = "/fo"
SlashCmdList["TOONAGEFARM"] = HandleSlash

SLASH_TOONAGEFARMRESET1 = "/farmreset"
SlashCmdList["TOONAGEFARMRESET"] = function()
    FarmOpt:ResetSession()
    print("|cff00ccff[ToonAge FarmOpt]|r Session reset.")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════════

FarmOpt:Init()
