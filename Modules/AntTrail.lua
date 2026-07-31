-- ToonAge/Modules/AntTrail.lua
-- Ant Trail system — renders a breadcrumb path of upcoming quest steps
-- on the NavHud and world map, showing where to go next in sequence.
--
-- Uses CoordResolver for coordinates (priority cascade across all sources).
-- Hooks into NavHud's tick for HUD rendering, and provides data to Arrow.
--
-- Visual: faded dots connected by thin lines, getting more transparent
-- the further ahead in the sequence they are. Current step is bright,
-- next steps fade out progressively.

local TA = ToonAge
local U  = TA.Utils

local AntTrail = {}
TA:RegisterModule("AntTrail", AntTrail)

-- ── Constants ─────────────────────────────────────────────────────────────────
local MAX_TRAIL_DOTS   = 8      -- max upcoming steps to show on trail
local DOT_SIZE_CURRENT = 10     -- pixels for current waypoint
local DOT_SIZE_FUTURE  = 6      -- pixels for upcoming waypoints
local LINE_THICKNESS   = 1.5    -- trail line thickness
local ALPHA_CURRENT    = 1.0
local ALPHA_DECAY      = 0.12   -- alpha drops by this per step ahead
local TRAIL_COLOR      = { 1.0, 0.82, 0.0 }    -- gold
local TRAIL_COLOR_DIM  = { 0.55, 0.40, 0.08 }  -- dark gold for lines
local UPDATE_INTERVAL  = 0.25   -- seconds between trail recalculation

-- ── State ─────────────────────────────────────────────────────────────────────
AntTrail.trailDots  = {}   -- reusable dot textures on NavHud
AntTrail.trailLines = {}   -- reusable line textures on NavHud
AntTrail.lastUpdate = 0
AntTrail.hookActive = false
AntTrail.waypoints  = {}   -- resolved waypoint positions for current trail

-- ── Trail calculation ─────────────────────────────────────────────────────────

--- Build the trail waypoints from the current guide position forward.
--- Returns array of { map, x, y, source, stepIdx, text, type }
function AntTrail:BuildTrail()
    local QT = TA:GetModule("QuestTracker")
    local CR = TA:GetModule("CoordResolver")
    if not QT or not CR or not QT.guideID then return {} end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide or not guide.steps then return {} end

    local trail = {}
    local startIdx = QT.stepIdx or 1

    for i = startIdx, math.min(startIdx + MAX_TRAIL_DOTS - 1, #guide.steps) do
        local step = guide.steps[i]
        if not step then break end

        -- Skip non-navigable steps
        if step.type == "text" or step.noArrow then
            -- skip but don't count against MAX
        else
            local resolved = CR:Resolve(step.questID, step, step.objectiveIndex)
            if resolved and resolved.map and (resolved.x > 0 or resolved.y > 0 or resolved.worldX) then
                table.insert(trail, {
                    map      = resolved.map,
                    x        = resolved.x,
                    y        = resolved.y,
                    worldX   = resolved.worldX,
                    worldY   = resolved.worldY,
                    source   = resolved.source,
                    stepIdx  = i,
                    text     = step.text or "",
                    type     = step.type or "waypoint",
                    isCurrent = (i == startIdx),
                })
            end
        end
    end

    return trail
end

-- ── NavHud rendering ──────────────────────────────────────────────────────────

function AntTrail:UpdateOnNavHud()
    local NavHud = TA:GetModule("NavHud")
    if not NavHud or not NavHud.frame or not NavHud.frame:IsShown() then
        self:HideAll()
        return
    end

    -- Throttle updates
    local now = GetTime()
    if (now - self.lastUpdate) < UPDATE_INTERVAL then return end
    self.lastUpdate = now

    -- Rebuild trail
    self.waypoints = self:BuildTrail()

    -- Get player position and bearing
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then self:HideAll(); return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then self:HideAll(); return end

    local playerX, playerY = pos:GetXY()
    local bearing = GetPlayerFacing() or 0
    local hudRadius = NavHud.hudRadius or 300

    -- Position trail dots
    local prevScreenX, prevScreenY = nil, nil
    local dotIdx = 0

    for i, wp in ipairs(self.waypoints) do
        -- Only show waypoints in the same zone
        if wp.map ~= mapID then
            -- skip (different zone)
        elseif wp.x == 0 and wp.y == 0 and not wp.worldX then
            -- skip (no usable coords)
        else
            dotIdx = dotIdx + 1

            -- Calculate screen position (same math as NavHud pins)
            local dx = wp.x - playerX
            local dy = wp.y - playerY
            local dist = math.sqrt(dx * dx + dy * dy)
            local angle = math.atan2(dx, -dy)
            local screenAngle = angle - bearing
            local normDist = math.min(dist / 0.15, 1.0)
            local hudDist = normDist * hudRadius * 0.85
            local screenX = math.sin(screenAngle) * hudDist
            local screenY = math.cos(screenAngle) * hudDist

            -- Get or create dot
            local dot = self:GetDot(dotIdx, NavHud.frame)
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", NavHud.frame, "CENTER", screenX, screenY)

            -- Appearance based on position in trail
            local alpha = math.max(0.15, ALPHA_CURRENT - (i - 1) * ALPHA_DECAY)
            local size = wp.isCurrent and DOT_SIZE_CURRENT or DOT_SIZE_FUTURE

            dot:SetSize(size, size)
            dot:SetVertexColor(TRAIL_COLOR[1], TRAIL_COLOR[2], TRAIL_COLOR[3], alpha)
            dot:Show()

            -- Draw line from previous dot to this one
            if prevScreenX and dotIdx > 1 then
                local line = self:GetLine(dotIdx - 1, NavHud.frame)
                self:PositionLine(line, prevScreenX, prevScreenY, screenX, screenY, NavHud.frame)
                line:SetVertexColor(TRAIL_COLOR_DIM[1], TRAIL_COLOR_DIM[2], TRAIL_COLOR_DIM[3], alpha * 0.5)
                line:Show()
            end

            prevScreenX, prevScreenY = screenX, screenY
        end
    end

    -- Hide unused dots and lines
    for i = dotIdx + 1, #self.trailDots do
        if self.trailDots[i] then self.trailDots[i]:Hide() end
    end
    for i = dotIdx, #self.trailLines do
        if self.trailLines[i] then self.trailLines[i]:Hide() end
    end
end

-- ── Object pool ───────────────────────────────────────────────────────────────

function AntTrail:GetDot(index, parent)
    if self.trailDots[index] then return self.trailDots[index] end
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetTexture("Interface\\Buttons\\WHITE8X8")
    dot:SetSize(DOT_SIZE_FUTURE, DOT_SIZE_FUTURE)
    dot:Hide()
    self.trailDots[index] = dot
    return dot
end

function AntTrail:GetLine(index, parent)
    if self.trailLines[index] then return self.trailLines[index] end
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:Hide()
    self.trailLines[index] = line
    return line
end

function AntTrail:PositionLine(line, x1, y1, x2, y2, parent)
    -- Draw a line between two screen-space points using a rotated texture
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 2 then line:Hide(); return end

    local angle = math.atan2(dy, dx)
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2

    line:SetSize(length, LINE_THICKNESS)
    line:ClearAllPoints()
    line:SetPoint("CENTER", parent, "CENTER", cx, cy)

    -- Rotate the line texture
    -- WoW doesn't support texture rotation directly on textures attached to frames,
    -- so we use SetRotation on the texture (available since 8.0)
    if line.SetRotation then
        line:SetRotation(-angle)
    end
end

function AntTrail:HideAll()
    for _, dot in ipairs(self.trailDots) do dot:Hide() end
    for _, line in ipairs(self.trailLines) do line:Hide() end
end

-- ── Arrow integration ─────────────────────────────────────────────────────────
-- Provides resolved coordinates to ToonAge's Arrow module for the current step.

function AntTrail:GetCurrentWaypoint()
    if self.waypoints and #self.waypoints > 0 then
        return self.waypoints[1]
    end
    return nil
end

--- Get all trail waypoints (for Arrow module's multi-waypoint display)
function AntTrail:GetTrailWaypoints()
    return self.waypoints or {}
end

-- ── Hook into NavHud ──────────────────────────────────────────────────────────

function AntTrail:InstallHook()
    if self.hookActive then return end
    local NavHud = TA:GetModule("NavHud")
    if not NavHud then return end

    hooksecurefunc(NavHud, "Tick", function()
        AntTrail:UpdateOnNavHud()
    end)
    self.hookActive = true
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function AntTrail:Init()
    local NavHud = TA:GetModule("NavHud")
    if NavHud and NavHud.frame then
        self:InstallHook()
    else
        C_Timer.After(2, function()
            AntTrail:InstallHook()
        end)
    end
end

function AntTrail:OnEvent(event, ...)
    -- Rebuild trail on quest/zone changes
    if event == "QUEST_ACCEPTED" or event == "ZONE_CHANGED_NEW_AREA" then
        self.lastUpdate = 0  -- force immediate recalc on next tick
        local CR = TA:GetModule("CoordResolver")
        if CR then CR:ClearCache() end
    end
end

AntTrail.SlashCommands = {
    trail = function(self)
        local wp = self:BuildTrail()
        if #wp == 0 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Trail]|r No trail waypoints (no active guide or no coords available).")
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Trail]|r Run /ta coord to check available data sources.")
            return
        end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Trail]|r " .. #wp .. " waypoints in current trail:")
        for i, w in ipairs(wp) do
            local prefix = w.isCurrent and "|cFF4AFF7A→|r " or "  "
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s#%d [%s] %s (%.2f, %.2f) via %s",
                prefix, w.stepIdx, w.type, w.text:sub(1, 30), w.x, w.y, w.source or "?"))
        end
    end,
}
