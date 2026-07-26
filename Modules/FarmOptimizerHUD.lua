-- ToonAge/Modules/FarmOptimizerHUD.lua
-- UI/HUD layer for the real-time farming optimizer.
-- Renders efficiency stats, smart suggestions, cluster highlights, and
-- session summaries as a subtle coach overlay. Auto-hides when not farming.

local TA = ToonAge
local U  = TA.Utils

local FOHUD = {}
TA:RegisterModule("FarmOptimizerHUD", FOHUD)

local FO = TA.Data.FarmOptimizer

-- ── Constants ─────────────────────────────────────────────────────────────────
local GATHERING_PROFS = { [182] = true, [186] = true, [393] = true } -- Herb, Mining, Skinning
local UPDATE_INTERVAL = 2       -- seconds between HUD refreshes
local MAX_CLUSTERS    = 5       -- max cluster circles on NavHud
local CIRCLE_SIZE_MIN = 24      -- pixels, weakest cluster
local CIRCLE_SIZE_MAX = 56      -- pixels, strongest cluster
local PANEL_W, PANEL_H         = 180, 130
local SUMMARY_W, SUMMARY_H     = 260, 200
local FADE_DURATION   = 0.4     -- seconds for fade animations
local AUTO_HIDE_DELAY = 15      -- seconds of inactivity before panel fades

-- ── State ─────────────────────────────────────────────────────────────────────
local hasGatherProf   = false
local hudPanel        = nil
local suggestionBar   = nil
local summaryPanel    = nil
local updateTicker    = nil
local circlePool      = {}
local hookInstalled   = false
local panelPos        = { point = "TOPRIGHT", x = -20, y = -120 }
local lastSuggestion  = ""
local lastActivity    = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

local function GradeColor(grade)
    local c = FO.GRADE_COLORS and FO.GRADE_COLORS[grade]
    return c and c or { 0.88, 0.83, 0.65 }
end

local function HeatColor(heat)
    local c = FO.HEAT_COLORS and FO.HEAT_COLORS[heat]
    return c and c or { 0.60, 0.60, 0.60 }
end

local function ApplyBackdrop(frame)
    if TA.Modern and TA.Modern.ApplyGlassBackdrop then
        TA.Modern:ApplyGlassBackdrop(frame)
    elseif frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame:SetBackdropColor(0.05, 0.05, 0.06, 0.88)
        frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)
    end
end

local function FadeIn(frame, duration)
    if not frame then return end
    UIFrameFadeIn(frame, duration or FADE_DURATION, frame:GetAlpha(), 1.0)
end

local function FadeOut(frame, duration, callback)
    if not frame then return end
    local info = {
        mode        = "OUT",
        timeToFade  = duration or FADE_DURATION,
        startAlpha  = frame:GetAlpha(),
        endAlpha    = 0,
        finishedFunc = callback,
    }
    UIFrameFade(frame, info)
end

-- ── Profession Gate ───────────────────────────────────────────────────────────
local function CheckGatheringProfession()
    local profs = { GetProfessions() }
    for i = 1, 2 do
        local idx = profs[i]
        if idx then
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
            if GATHERING_PROFS[skillLine] then return true end
        end
    end
    return false
end

-- ── Efficiency HUD Panel ──────────────────────────────────────────────────────
local function CreateHUDPanel()
    if hudPanel then return hudPanel end

    local f = CreateFrame("Frame", "ToonAgeFarmHUD", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint(panelPos.point, UIParent, panelPos.point, panelPos.x, panelPos.y)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(50)
    f:SetClampedToScreen(true)
    f:SetAlpha(0)
    f:Hide()

    ApplyBackdrop(f)

    -- Draggable
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        panelPos.point = point
        panelPos.x = x
        panelPos.y = y
    end)

    -- Labels
    local yOff = -10
    local function MakeLabel(size, justify)
        local fs = f:CreateFontString(nil, "OVERLAY")
        fs:SetFont(STANDARD_TEXT_FONT, size, "")
        fs:SetJustifyH(justify or "LEFT")
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", 10, yOff)
        fs:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, yOff)
        if TA.Modern and TA.Modern.CLR_TEXT_PRIMARY then
            local c = TA.Modern.CLR_TEXT_PRIMARY
            fs:SetTextColor(c[1], c[2], c[3], c[4])
        else
            fs:SetTextColor(0.92, 0.90, 0.87, 1.00)
        end
        yOff = yOff - (size + 6)
        return fs
    end

    f.nodesPerMin = MakeLabel(18, "CENTER")  -- large stat
    f.goldPerHour = MakeLabel(10, "LEFT")
    f.grade       = MakeLabel(10, "LEFT")
    f.heat        = MakeLabel(10, "LEFT")
    f.session     = MakeLabel(10, "LEFT")

    hudPanel = f
    return f
end

-- ── Smart Suggestion Bar ──────────────────────────────────────────────────────
local function CreateSuggestionBar()
    if suggestionBar then return suggestionBar end
    if not hudPanel then return end

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, 22)
    f:SetPoint("TOP", hudPanel, "BOTTOM", 0, -4)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(50)
    f:SetAlpha(0)
    f:Hide()

    ApplyBackdrop(f)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont(STANDARD_TEXT_FONT, 10, "")
    f.text:SetPoint("LEFT", 8, 0)
    f.text:SetPoint("RIGHT", -8, 0)
    f.text:SetJustifyH("CENTER")
    if TA.Modern and TA.Modern.CLR_TEXT_ACCENT then
        local c = TA.Modern.CLR_TEXT_ACCENT
        f.text:SetTextColor(c[1], c[2], c[3], c[4])
    else
        f.text:SetTextColor(0.40, 0.75, 1.00, 1.00)
    end

    suggestionBar = f
    return f
end

-- ── Session Summary Panel ─────────────────────────────────────────────────────
local function CreateSummaryPanel()
    if summaryPanel then return summaryPanel end

    local f = CreateFrame("Frame", "ToonAgeFarmSummary", UIParent, "BackdropTemplate")
    f:SetSize(SUMMARY_W, SUMMARY_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:Hide()

    ApplyBackdrop(f)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(STANDARD_TEXT_FONT, 12, "")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("|cFFFFD100Farm Session Summary|r")

    -- Body text (multi-line summary)
    f.body = f:CreateFontString(nil, "OVERLAY")
    f.body:SetFont(STANDARD_TEXT_FONT, 10, "")
    f.body:SetPoint("TOPLEFT", 12, -30)
    f.body:SetPoint("BOTTOMRIGHT", -12, 34)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")
    if TA.Modern and TA.Modern.CLR_TEXT_PRIMARY then
        local c = TA.Modern.CLR_TEXT_PRIMARY
        f.body:SetTextColor(c[1], c[2], c[3], c[4])
    else
        f.body:SetTextColor(0.92, 0.90, 0.87, 1.00)
    end

    -- Reset button
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(90, 22)
    btn:SetPoint("BOTTOM", 0, 8)
    btn:SetText("Reset Session")
    btn:SetScript("OnClick", function()
        local FarmOpt = TA:GetModule("FarmOptimizer")
        if FarmOpt and FarmOpt.ResetSession then
            FarmOpt:ResetSession()
        end
        FOHUD:UpdateSummary()
    end)

    -- Close button (top-right)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    summaryPanel = f
    return f
end

-- ── Update Logic ──────────────────────────────────────────────────────────────
local function UpdateHUD()
    if not hudPanel then return end

    local FarmOpt = TA:GetModule("FarmOptimizer")
    if not FarmOpt then return end

    -- Check if session active
    local session = FarmOpt.GetSession and FarmOpt:GetSession()
    if not session or (session.nodeCount or 0) == 0 then
        if hudPanel:IsShown() and (GetTime() - lastActivity) > AUTO_HIDE_DELAY then
            FadeOut(hudPanel, FADE_DURATION, function() hudPanel:Hide() end)
            if suggestionBar and suggestionBar:IsShown() then
                FadeOut(suggestionBar, FADE_DURATION, function() suggestionBar:Hide() end)
            end
        end
        return
    end

    lastActivity = GetTime()

    -- Show panel if hidden
    if not hudPanel:IsShown() then
        hudPanel:Show()
        FadeIn(hudPanel)
    end

    -- Nodes/min
    local npm = FarmOpt.GetNodesPerMinute and FarmOpt:GetNodesPerMinute() or 0
    local grade = FarmOpt.GetGrade and FarmOpt:GetGrade() or "F"
    local gc = GradeColor(grade)
    hudPanel.nodesPerMin:SetText(string.format("|cFF%02x%02x%02x%.1f|r /min",
        gc[1] * 255, gc[2] * 255, gc[3] * 255, npm))

    -- Gold/hour
    local gph = FarmOpt.GetGoldPerHour and FarmOpt:GetGoldPerHour() or 0
    hudPanel.goldPerHour:SetText(string.format("Gold/hr: |cFFFFD100%s|r",
        U.FormatGold and U:FormatGold(gph) or string.format("%.0fg", gph / 10000)))

    -- Grade
    hudPanel.grade:SetText(string.format("Route: |cFF%02x%02x%02x%s|r",
        gc[1] * 255, gc[2] * 255, gc[3] * 255, grade))

    -- Heat
    local heat = FarmOpt.GetHeat and FarmOpt:GetHeat() or "Cold"
    local hc = HeatColor(heat)
    hudPanel.heat:SetText(string.format("Zone: |cFF%02x%02x%02x%s|r",
        hc[1] * 255, hc[2] * 255, hc[3] * 255, heat))

    -- Session time
    local elapsed = session.elapsed or 0
    hudPanel.session:SetText("Session: " .. FormatTime(elapsed))

    -- Suggestion bar
    local suggestion = FarmOpt.GetSuggestion and FarmOpt:GetSuggestion() or ""
    if suggestion ~= "" then
        if not suggestionBar then CreateSuggestionBar() end
        if suggestion ~= lastSuggestion then
            lastSuggestion = suggestion
            suggestionBar.text:SetText(suggestion)
            if not suggestionBar:IsShown() then
                suggestionBar:Show()
                FadeIn(suggestionBar)
            else
                -- Flash on change
                FadeOut(suggestionBar, 0.15, function()
                    FadeIn(suggestionBar, 0.25)
                end)
            end
        end
    elseif suggestionBar and suggestionBar:IsShown() then
        FadeOut(suggestionBar, FADE_DURATION, function() suggestionBar:Hide() end)
        lastSuggestion = ""
    end
end

-- ── Summary Panel Update ──────────────────────────────────────────────────────
function FOHUD:UpdateSummary()
    if not summaryPanel then return end

    local FarmOpt = TA:GetModule("FarmOptimizer")
    if not FarmOpt then
        summaryPanel.body:SetText("No session data.")
        return
    end

    local session = FarmOpt.GetSession and FarmOpt:GetSession()
    if not session then
        summaryPanel.body:SetText("No active session.")
        return
    end

    local lines = {}

    -- Node counts by type
    local nodeCounts = session.nodeCounts or {}
    local totalNodes = session.nodeCount or 0
    table.insert(lines, string.format("Nodes: %d total", totalNodes))
    for ntype, count in pairs(nodeCounts) do
        table.insert(lines, string.format("  %s: %d", ntype, count))
    end

    -- Time breakdown
    local elapsed = session.elapsed or 0
    local idle    = session.idleTime or 0
    local combat  = session.combatTime or 0
    local active  = elapsed - idle - combat
    table.insert(lines, string.format("Time: %s (active %s, idle %s, combat %s)",
        FormatTime(elapsed), FormatTime(active), FormatTime(idle), FormatTime(combat)))

    -- Distance
    local dist = session.distance or 0
    table.insert(lines, string.format("Distance: %d yards", dist))

    -- Best area
    local bestArea = session.bestArea or "N/A"
    table.insert(lines, "Best area: " .. bestArea)

    -- Trend
    local trend = FarmOpt.GetTrend and FarmOpt:GetTrend() or "stable"
    local trendColors = { improving = "4AFF7A", declining = "FF4A4A", stable = "FFCC00" }
    local tc = trendColors[trend] or "FFCC00"
    table.insert(lines, string.format("Trend: |cFF%s%s|r", tc, trend))

    -- Gold
    local gold = FarmOpt.GetGoldPerHour and FarmOpt:GetGoldPerHour() or 0
    local goldEarned = session.goldEarned or 0
    table.insert(lines, string.format("Gold earned: |cFFFFD100%s|r",
        U.FormatGold and U:FormatGold(goldEarned) or string.format("%.0fg", goldEarned / 10000)))

    summaryPanel.body:SetText(table.concat(lines, "\n"))
end

function FOHUD:ToggleSummary()
    if not summaryPanel then CreateSummaryPanel() end
    if summaryPanel:IsShown() then
        summaryPanel:Hide()
    else
        self:UpdateSummary()
        summaryPanel:Show()
    end
end

-- ── Cluster Highlights on NavHud ──────────────────────────────────────────────
local function GetCircle(index, parent)
    if circlePool[index] then return circlePool[index] end

    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    tex:SetBlendMode("ADD")
    tex:Hide()
    circlePool[index] = tex
    return tex
end

local function HideAllCircles()
    for _, c in ipairs(circlePool) do
        c:Hide()
    end
end

local function RenderClusters()
    local NavHud = TA:GetModule("NavHud")
    if not NavHud or not NavHud.frame or not NavHud.frame:IsShown() then
        HideAllCircles()
        return
    end

    local FarmOpt = TA:GetModule("FarmOptimizer")
    if not FarmOpt or not FarmOpt.GetActiveClusters then
        HideAllCircles()
        return
    end

    local clusters = FarmOpt:GetActiveClusters()
    if not clusters or #clusters == 0 then
        HideAllCircles()
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then HideAllCircles(); return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then HideAllCircles(); return end

    local playerX, playerY = pos:GetXY()
    local bearing = GetPlayerFacing() or 0
    local hudRadius = NavHud.hudRadius or 300

    local idx = 0
    for _, cluster in ipairs(clusters) do
        if idx >= MAX_CLUSTERS then break end
        idx = idx + 1

        local circle = GetCircle(idx, NavHud.frame)

        -- Position via bearing math (same as GatherTracker)
        local dx = cluster.x - playerX
        local dy = cluster.y - playerY
        local dist = math.sqrt(dx * dx + dy * dy)
        local angle = math.atan2(dx, -dy)
        local screenAngle = angle - bearing

        local normDist = math.min(dist / 0.18, 1.0)
        local hudDist  = normDist * hudRadius * 0.85

        local screenX = math.sin(screenAngle) * hudDist
        local screenY = math.cos(screenAngle) * hudDist

        -- Size proportional to cluster strength
        local strength = cluster.strength or 0.5
        local size = CIRCLE_SIZE_MIN + (CIRCLE_SIZE_MAX - CIRCLE_SIZE_MIN) * strength

        circle:SetSize(size, size)
        circle:ClearAllPoints()
        circle:SetPoint("CENTER", NavHud.frame, "CENTER", screenX, screenY)

        -- Gold/orange, alpha fades as cluster weakens
        local alpha = 0.20 + (strength * 0.45)
        circle:SetVertexColor(1.00, 0.72, 0.10, alpha)
        circle:Show()
    end

    -- Hide unused circles
    for i = idx + 1, #circlePool do
        if circlePool[i] then circlePool[i]:Hide() end
    end
end

local function InstallNavHudHook()
    if hookInstalled then return end

    local NavHud = TA:GetModule("NavHud")
    if not NavHud then return end

    hooksecurefunc(NavHud, "Tick", function()
        if hasGatherProf then
            RenderClusters()
        end
    end)

    hookInstalled = true
end

-- ── Toggle ────────────────────────────────────────────────────────────────────
function FOHUD:Toggle()
    if not hasGatherProf then return end
    if not hudPanel then CreateHUDPanel(); CreateSuggestionBar() end

    if hudPanel:IsShown() then
        FadeOut(hudPanel, FADE_DURATION, function() hudPanel:Hide() end)
        if suggestionBar and suggestionBar:IsShown() then
            FadeOut(suggestionBar, FADE_DURATION, function() suggestionBar:Hide() end)
        end
    else
        hudPanel:Show()
        FadeIn(hudPanel)
        lastActivity = GetTime()
    end
end

-- Expose for keybind
TA.FarmOptimizerHUD = { Toggle = function() FOHUD:Toggle() end }

-- ── Slash Commands ────────────────────────────────────────────────────────────
FOHUD.SlashCommands = {
    farmhud = function(self)
        self:Toggle()
    end,
    farmsummary = function(self)
        self:ToggleSummary()
    end,
}

-- ── Init ──────────────────────────────────────────────────────────────────────
function FOHUD:Init()
    -- Profession gate: defer check slightly for API readiness
    C_Timer.After(1, function()
        hasGatherProf = CheckGatheringProfession()
        if not hasGatherProf then return end

        -- Lazy frame creation — build panels on first use
        CreateHUDPanel()
        CreateSuggestionBar()

        -- Start update ticker
        updateTicker = C_Timer.NewTicker(UPDATE_INTERVAL, UpdateHUD)

        -- Install NavHud hook for cluster rendering
        local NavHud = TA:GetModule("NavHud")
        if NavHud and NavHud.frame then
            InstallNavHudHook()
        else
            C_Timer.After(2, InstallNavHudHook)
        end
    end)
end
