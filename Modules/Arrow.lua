-- ToonAge/Modules/Arrow.lua
-- Draggable, scroll-to-resize, right-click-lockable HUD arrow.
-- Layout: gold arrow -> white distance -> grey ETA -> gold objective title
--
-- Bearing math (WoW specifics):
--   Map-y increases SOUTHWARD, so atan2(dx, -dy) gives a clockwise bearing
--   where 0 = North, matching GetPlayerFacing() conventions.

local TA = ToonAge
local U  = TA.Utils

local Arrow = {}
TA:RegisterModule("Arrow", Arrow)

Arrow.frame        = nil
Arrow.throttle     = 0
Arrow.currentAngle = nil   -- lerped rotation state; nil = snap on next Tick
local UPDATE_HZ  = 0.03   -- ~33 Hz for smooth rotation
local LERP_RATE  = 0.35   -- fraction of the remaining angle closed per tick (higher = more responsive)

local ARROW_W, ARROW_H = 80, 100

-- Shortest-path angle interpolation (avoids spinning the long way around
-- when the target bearing crosses the -pi/pi wrap boundary).
local function LerpAngle(current, target, factor)
    local twoPi = math.pi * 2
    local diff  = (target - current + math.pi) % twoPi - math.pi
    return current + diff * factor
end

-- ── Helpers ───────────────────────────────────────────────────────────────

local function GetTargetStep()
    local QT = TA:GetModule("QuestTracker")
    if not (QT and QT.guideID and QT.stepIdx) then return nil end
    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return nil end
    return guide.steps[QT.stepIdx]
end

-- Distance/ETA math lives in Core/Utils.lua (TA.Utils) so QuestTracker.lua
-- can show identical numbers for the same step without duplicating it here.
local function GetTravelSpeed()
    local TM = TA:GetModule("TravelModes")
    return (TM and TM:GetSpeed()) or 7
end

-- Resolve a step's map/x/y, falling back to Blizzard's own live quest
-- waypoint API when the guide's stored coord is an unrecorded stub
-- (map=0,x=0,y=0). C_QuestLog.GetNextWaypoint is the same data source that
-- powers the default UI's built-in supertracking arrow — real, verified
-- per-quest data instead of a guessed zone-center/last-NPC fallback.
local function GetEffectiveCoord(step)
    -- PRIORITY 1: Blizzard's live quest waypoint system.
    -- GetNextWaypoint only works for supertracked/watched quests.
    if step.questID and C_QuestLog.GetNextWaypoint then
        -- Make sure the quest is tracked so waypoint data is available
        local questID = step.questID
        local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIdx then
            local wpMap, wpX, wpY = C_QuestLog.GetNextWaypoint(questID)
            if wpMap and wpX and wpY and (wpX ~= 0 or wpY ~= 0) then
                return wpMap, wpX, wpY
            end
        end
    end

    -- PRIORITY 2: Quest POI markers on the map (works for most tracked quests)
    if step.questID and C_QuestLog.GetLogIndexForQuestID then
        local questID = step.questID
        local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIdx then
            local currentMap = C_Map.GetBestMapForUnit("player")
            if currentMap and C_Map.GetMapPosFromWorldPos then
                -- Try to get quest POI via the map system
                if QuestPOIGetIconInfo then
                    local completed, posX, posY = QuestPOIGetIconInfo(questID)
                    if posX and posY and (posX ~= 0 or posY ~= 0) then
                        return currentMap, posX, posY
                    end
                end
            end
        end
    end

    -- PRIORITY 3: Manual guide coords
    local coordMap = step.coord.map or 0
    local cx, cy   = step.coord.x, step.coord.y
    if coordMap ~= 0 or cx ~= 0 or cy ~= 0 then
        return coordMap, cx, cy
    end

    -- Nothing available
    return 0, 0, 0
end
-- Exposed on the module table so QuestTracker.lua can reuse the exact same
-- resolution (including the live-waypoint fallback) for its distance/ETA
-- display, instead of duplicating this logic.
Arrow.GetEffectiveCoord = GetEffectiveCoord

-- ── Frame construction ────────────────────────────────────────────────────

function Arrow:InitFrame()
    local f = CreateFrame("Button", "TAWaypointArrow", UIParent)
    f:SetSize(ARROW_W, ARROW_H)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(fr)
        fr:StopMovingOrSizing()
        if TA.charDB then
            TA.charDB.arrow   = TA.charDB.arrow or {}
            TA.charDB.arrow.x = fr:GetLeft()
            TA.charDB.arrow.y = fr:GetTop()
        end
    end)

    -- Scroll-wheel resize (0.5x – 3.0x)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(fr, delta)
        local s = math.max(0.5, math.min(fr:GetScale() + delta * 0.1, 3.0))
        fr:SetScale(s)
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.scale = s end
    end)

    -- Right-click to toggle drag lock
    f:RegisterForClicks("RightButtonUp")
    f:SetScript("OnClick", function(fr, button)
        if button ~= "RightButton" then return end
        TA.charDB.arrow = TA.charDB.arrow or {}
        TA.charDB.arrow.locked = not TA.charDB.arrow.locked
        if TA.charDB.arrow.locked then
            fr:RegisterForDrag()
            print("|cFFFFD100[TA Arrow]|r Locked. Right-click to unlock.")
        else
            fr:RegisterForDrag("LeftButton")
            print("|cFFFFD100[TA Arrow]|r Unlocked. Drag to move.")
        end
    end)

    f:SetScript("OnEnter", function(fr)
        GameTooltip:SetOwner(fr, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Guide Arrow", 1, 0.82, 0)
        GameTooltip:AddLine("Right-click: Lock / Unlock", 1, 1, 1)
        GameTooltip:AddLine("Scroll: Resize", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Restore saved state
    local saved = TA.charDB and TA.charDB.arrow
    if saved and saved.scale then f:SetScale(saved.scale) end
    if saved and saved.x and saved.y then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
    if saved and saved.locked then f:RegisterForDrag() else f:RegisterForDrag("LeftButton") end
    f:Hide()

    -- Gold arrow (active, rotated each tick)
    local arrowTex = f:CreateTexture(nil, "ARTWORK")
    arrowTex:SetSize(52, 52)
    arrowTex:SetPoint("TOP", f, "TOP", 0, -4)
    arrowTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    arrowTex:SetVertexColor(1, 0.82, 0, 1)
    f.arrowTex = arrowTex

    -- Grey arrow (inactive — no coord or wrong zone)
    local greyTex = f:CreateTexture(nil, "ARTWORK")
    greyTex:SetSize(52, 52)
    greyTex:SetPoint("TOP", f, "TOP", 0, -4)
    greyTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    greyTex:SetVertexColor(0.35, 0.30, 0.20, 0.45)
    greyTex:Hide()
    f.greyTex = greyTex

    local distF = f:CreateFontString(nil, "OVERLAY")
    distF:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    distF:SetTextColor(1, 1, 1, 1)
    distF:SetPoint("TOP", arrowTex, "BOTTOM", 0, 0)
    distF:SetJustifyH("CENTER")
    f.distF = distF

    local etaF = f:CreateFontString(nil, "OVERLAY")
    etaF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    etaF:SetTextColor(0.80, 0.80, 0.80, 1)
    etaF:SetPoint("TOP", distF, "BOTTOM", 0, -2)
    etaF:SetJustifyH("CENTER")
    f.etaF = etaF

    local titleF = f:CreateFontString(nil, "OVERLAY")
    titleF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    titleF:SetTextColor(1, 0.82, 0, 1)
    titleF:SetPoint("TOP", etaF, "BOTTOM", 0, -4)
    titleF:SetWidth(180)
    titleF:SetWordWrap(false)
    titleF:SetJustifyH("CENTER")
    f.titleF = titleF

    f:SetScript("OnUpdate", function(_, elapsed)
        self.throttle = self.throttle + elapsed
        if self.throttle < UPDATE_HZ then return end
        self.throttle = 0
        self:Tick(f)
    end)

    self.frame = f
end

-- ── Color gradient helper ─────────────────────────────────────────────────
-- Interpolates between 3 colors based on t (0..1): bad → mid → good
local function ColorGradient(t, br,bg,bb, mr,mg,mb, gr,gg,gb)
    if t >= 1 then return gr, gg, gb end
    if t <= 0 then return br, bg, bb end
    if t < 0.5 then
        local p = t * 2
        return br + (mr - br) * p, bg + (mg - bg) * p, bb + (mb - bb) * p
    else
        local p = (t - 0.5) * 2
        return mr + (gr - mr) * p, mg + (gg - mg) * p, mb + (gb - mb) * p
    end
end

-- ETA speed smoothing state
local speedSamples = { 0, 0 }
local lastDist     = nil
local lastTime     = 0
local ARRIVAL_DIST = 10   -- yards — threshold for arrival state
local ARRIVAL_PULSE_RATE = 3  -- pulses per second

-- ── Per-tick update ───────────────────────────────────────────────────────

function Arrow:Tick(f)
    local step = GetTargetStep()

    if not step or not step.coord then
        f.arrowTex:Hide()
        f.greyTex:Show()
        f.distF:SetText("---")
        f.etaF:SetText("")
        f.titleF:SetText("No Waypoint")
        self._arrived = false
        return
    end

    -- Narrative / no-location steps (e.g. cutscene or flavor text): nothing
    -- to point at, so hide the arrow entirely rather than showing "No Loc".
    if step.type == "text" then
        f.arrowTex:Hide()
        f.greyTex:Hide()
        f.distF:SetText("")
        f.etaF:SetText("")
        f.titleF:SetText(step.text or "")
        self._arrived = false
        return
    end

    -- Objective label: live quest name > step text
    local label = step.text or ""
    if step.questID then
        local qTitle = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(step.questID)
        if qTitle and qTitle ~= "" then label = qTitle end
    end
    if #label > 35 then label = label:sub(1, 32) .. "..." end
    f.titleF:SetText(label)

    local coordMap, cx, cy = GetEffectiveCoord(step)

    -- Still nothing after trying the live quest-waypoint fallback — stub
    -- coords (map=0, x=0, y=0) must NOT be treated as a real waypoint, or
    -- the arrow would point at the map's top-left corner.
    if coordMap == 0 and cx == 0 and cy == 0 then
        f.arrowTex:Hide()
        f.greyTex:Show()
        f.distF:SetText("No Loc")
        f.etaF:SetText("")
        self._arrived = false
        return
    end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then return end

    -- Cross-zone detection (coordMap=0 with real coords = assume same zone)
    if coordMap ~= 0 and coordMap ~= currentMap then
        f.arrowTex:Hide()
        f.greyTex:Show()
        f.distF:SetText("Diff Zone")
        f.etaF:SetText("")
        self._arrived = false
        return
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()

    local dx          = cx - px
    local dy          = cy - py
    -- WoW map: Y increases southward. atan2(dx, -dy) gives clockwise bearing.
    -- GetPlayerFacing() returns counter-clockwise radians from north.
    -- The difference gives the screen-space rotation for the arrow texture.
    local bearing     = math.atan2(dx, -dy)
    local facing      = GetPlayerFacing()

    -- GetPlayerFacing() returns nil in instances/indoors on some builds,
    -- AND may be restricted entirely on 12.0 PTR builds. Fallback: infer
    -- facing direction from consecutive position samples.
    if not facing then
        -- Infer facing from movement direction
        if self._lastPx and self._lastPy then
            local mdx = px - self._lastPx
            local mdy = py - self._lastPy
            local moved = math.sqrt(mdx * mdx + mdy * mdy)
            if moved > 0.0001 then
                -- Player moved — use movement direction as facing
                facing = math.atan2(mdx, -mdy)
            else
                -- Standing still — use last known facing or 0
                facing = self._lastFacing or 0
            end
        else
            facing = 0
        end
    end
    self._lastPx = px
    self._lastPy = py
    self._lastFacing = facing

    local targetAngle = bearing - facing

    local yards = U.ComputeDistance(px, py, cx, cy)

    -- ── ARRIVAL STATE ─────────────────────────────────────────────────
    if yards <= ARRIVAL_DIST then
        if not self._arrived then
            self._arrived = true
            self.currentAngle = nil  -- reset lerp on next non-arrived tick
        end
        f.greyTex:Hide()
        f.arrowTex:Show()
        f.arrowTex:SetRotation(0)  -- point straight up

        -- Pulsing green glow to indicate arrival
        local pulse = 0.6 + 0.4 * math.sin(GetTime() * ARRIVAL_PULSE_RATE * math.pi * 2)
        f.arrowTex:SetVertexColor(0.20, 0.92, 0.40, pulse)

        f.distF:SetText("|cFF4AFF7AArrived|r")
        f.etaF:SetText("")
        return
    end

    self._arrived = false
    f.greyTex:Hide()
    f.arrowTex:Show()

    -- ── DIRECTIONAL COLOR GRADIENT ────────────────────────────────────
    -- perc = 1.0 when facing the waypoint, 0.0 when facing directly away
    local perc = math.abs((math.pi - math.abs(targetAngle)) / math.pi)
    -- Clamp to 0..1 (angles can slightly exceed pi due to lerp overshoot)
    perc = math.max(0, math.min(1, perc))

    local r, g, b = ColorGradient(perc,
        0.90, 0.20, 0.15,   -- red (facing away)
        1.00, 0.80, 0.10,   -- yellow (sideways)
        0.20, 0.92, 0.40    -- green (facing toward)
    )

    -- ── ROTATION (direct, no lerp) ───────────────────────────────────
    -- Set arrow rotation directly each frame so it responds instantly
    -- when the player turns. TomTom/APR use the same approach.
    f.arrowTex:SetRotation(targetAngle)
    f.arrowTex:SetVertexColor(r, g, b, 1)

    -- ── DISTANCE ──────────────────────────────────────────────────────
    f.distF:SetText(U.FormatDistance(yards))

    -- ── SPEED-SMOOTHED ETA ────────────────────────────────────────────
    -- Track distance changes over time and average over 2 samples to
    -- prevent ETA jitter from micro-movement and position snapping.
    local now = GetTime()
    local dt  = now - lastTime
    if dt > 0.1 and lastDist then
        local moved = lastDist - yards  -- positive if getting closer
        local instantSpeed = moved / dt
        -- Shift samples
        speedSamples[1] = speedSamples[2]
        speedSamples[2] = instantSpeed
    end
    lastDist = yards
    lastTime = now

    local avgSpeed = (speedSamples[1] + speedSamples[2]) / 2
    if avgSpeed > 0.5 then
        -- Player is actually moving toward the target
        local eta = yards / avgSpeed
        if eta < 3600 then
            local mins = math.floor(eta / 60)
            local secs = math.floor(eta % 60)
            f.etaF:SetText(string.format("|cFFCCCCCC%d:%02d ETA|r", mins, secs))
        else
            f.etaF:SetText("")
        end
    elseif avgSpeed < -0.5 then
        -- Moving away
        f.etaF:SetText("|cFFFF6666moving away|r")
    else
        -- Standing still or moving perpendicular — use fallback speed
        local fallbackSpeed = GetTravelSpeed()
        if fallbackSpeed > 0 then
            f.etaF:SetText(U.FormatETA(yards, fallbackSpeed))
        else
            f.etaF:SetText("")
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────

function Arrow:Toggle()
    if not self.frame then
        print("|cFFFF4444[TA]|r Arrow frame not initialised.")
        return
    end
    if self.frame:IsVisible() then
        self.frame:Hide()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = false end
        print("|cFFFFD100[TA Arrow]|r Hidden.")
    else
        self.frame:Show()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = true end
        print("|cFFFFD100[TA Arrow]|r Visible.")
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────

function Arrow:Init()
    self:InitFrame()
    local saved = TA.charDB and TA.charDB.arrow
    if saved and saved.visible then self.frame:Show() end
end

Arrow.SlashCommands = {
    arrow = function(self) self:Toggle() end,
}
