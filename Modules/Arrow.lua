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
local UPDATE_HZ  = 0.05   -- 20 Hz for smooth rotation
local LERP_RATE  = 0.15   -- fraction of the remaining angle closed per tick

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
    local coordMap = step.coord.map or 0
    local cx, cy   = step.coord.x, step.coord.y

    if coordMap == 0 and cx == 0 and cy == 0
       and step.questID and C_QuestLog.GetNextWaypoint then
        local wpMap, wpX, wpY = C_QuestLog.GetNextWaypoint(step.questID)
        if wpMap and wpX and wpY then
            return wpMap, wpX, wpY
        end
    end

    return coordMap, cx, cy
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

-- ── Per-tick update ───────────────────────────────────────────────────────

function Arrow:Tick(f)
    local step = GetTargetStep()

    if not step or not step.coord then
        f.arrowTex:Hide()
        f.greyTex:Show()
        f.distF:SetText("---")
        f.etaF:SetText("")
        f.titleF:SetText("No Waypoint")
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
        return
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()

    f.greyTex:Hide()
    f.arrowTex:Show()

    local dx          = cx - px
    local dy          = cy - py
    local bearing     = math.atan2(dx, -dy)
    local facing      = GetPlayerFacing() or 0
    local targetAngle = bearing - facing

    self.currentAngle = self.currentAngle or targetAngle
    self.currentAngle = LerpAngle(self.currentAngle, targetAngle, LERP_RATE)
    f.arrowTex:SetRotation(self.currentAngle)

    local yards = U.ComputeDistance(px, py, cx, cy)
    f.distF:SetText(U.FormatDistance(yards))
    f.etaF:SetText(U.FormatETA(yards, GetTravelSpeed()))
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
