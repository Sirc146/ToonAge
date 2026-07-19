-- ToonAge/Modules/NavHud.lua
-- FarmHud-style transparent rotated HUD overlay for quest/guide navigation.
-- Shows quest waypoints, guide step pins, and gathering nodes on a
-- transparent circular display that rotates with the player's facing direction.
--
-- Architecture (inspired by FarmHud):
--   • Embedded <Minimap> widget at alpha=0 for native tracking blips (herbs/ore/NPCs)
--   • Custom pin system for guide waypoints using bearing math
--   • Cardinal direction labels (N/S/E/W) manually positioned via rotation
--   • Click-through by default (BACKGROUND strata, mouse disabled)
--   • 30fps C_Timer.NewTicker for pin/label updates
--   • Toggle via /ta hud or keybind
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local NavHud = {}
TA:RegisterModule("NavHud", NavHud)

-- ── Constants ─────────────────────────────────────────────────────────────────

local HUD_SCALE       = 1.4    -- minimap content scale (FarmHud default)
local UPDATE_HZ       = 1/30   -- 30fps ticker
local CARDINAL_RADIUS = 0.47   -- distance from center as fraction of HUD radius
local RANGE_CIRCLE_PCT = 0.435 -- gather/proximity circle as fraction of HUD size
local MAX_PINS        = 5      -- max upcoming guide step pins shown
local PIN_SIZE        = 16     -- pixels per waypoint pin
local HUD_ALPHA       = 1.0    -- blip visibility (minimap bg is always 0)

-- Pin colors by step type
local PIN_COLORS = {
    pickup    = { 0.29, 1.00, 0.48, 1.0 },  -- green
    turnin    = { 1.00, 0.82, 0.00, 1.0 },  -- gold
    objective = { 1.00, 0.67, 0.20, 1.0 },  -- orange
    waypoint  = { 0.12, 0.74, 1.00, 1.0 },  -- blue
    quest     = { 1.00, 0.82, 0.00, 1.0 },  -- gold
    travel    = { 0.12, 0.74, 1.00, 1.0 },  -- blue
    npc       = { 0.47, 1.00, 0.47, 1.0 },  -- green
    default   = { 0.88, 0.83, 0.65, 1.0 },  -- parchment
}

-- Cardinal direction data: label, angle in radians (clockwise from north)
local CARDINAL_DATA = {
    { label = "N",  rad = 0 },
    { label = "NE", rad = math.pi * 0.25 },
    { label = "E",  rad = math.pi * 0.50 },
    { label = "SE", rad = math.pi * 0.75 },
    { label = "S",  rad = math.pi },
    { label = "SW", rad = math.pi * 1.25 },
    { label = "W",  rad = math.pi * 1.50 },
    { label = "NW", rad = math.pi * 1.75 },
}

-- ── State ─────────────────────────────────────────────────────────────────────

NavHud.frame       = nil
NavHud.ticker      = nil
NavHud.pins        = {}      -- reusable pin frames
NavHud.cardinals   = {}      -- FontString references
NavHud.hudRadius   = 0       -- computed half-size in pixels

-- ── Frame Construction ────────────────────────────────────────────────────────

function NavHud:CreateHud()
    -- Main container: BACKGROUND strata, click-through
    local f = CreateFrame("Frame", "TANavHud", UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(2)
    f:EnableMouse(false)
    f:SetToplevel(false)
    f:Hide()

    -- Size to screen height (circular, fills vertically like FarmHud)
    local size = UIParent:GetHeight()
    f:SetSize(size, size)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- ── Minimap widget (native tracking blips) ────────────────────────
    -- WoW supports multiple Minimap widgets. We create one embedded in the
    -- HUD frame with alpha=0 (invisible background) and rotateMinimap on.
    -- The blip icons (herbs, ore, NPCs) render at full opacity on their own
    -- sublayer even when the minimap background is invisible.
    local mm = CreateFrame("Minimap", "TANavHudMinimap", f)
    mm:SetAllPoints(f)
    mm:SetAlpha(0)
    mm:EnableMouse(false)
    mm:SetZoom(0)  -- max zoom-out for widest detection range
    f.minimap = mm

    -- ── Range/proximity circle ────────────────────────────────────────
    local circle = f:CreateTexture(nil, "ARTWORK")
    circle:SetTexture("Interface\\AddOns\\ToonAge\\Modules\\NavHudCircle")
    -- Fallback to a simple ring if custom texture doesn't exist
    circle:SetColorTexture(0.12, 0.74, 1.00, 0.0)  -- invisible by default
    circle:SetSize(size * RANGE_CIRCLE_PCT, size * RANGE_CIRCLE_PCT)
    circle:SetPoint("CENTER", f, "CENTER")
    f.rangeCircle = circle

    -- Draw a simple ring using a texture atlas or procedural approach
    -- Since we can't guarantee a custom .tga shipped, use a circular texture
    -- from the game's own assets
    circle:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    circle:SetVertexColor(0.12, 0.74, 1.00, 0.15)

    -- ── Proximity ring (actual gather/interaction range) ──────────────
    local ring = f:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\Minimap-TrackingBorder")
    ring:SetVertexColor(0.12, 0.74, 1.00, 0.35)
    ring:SetSize(size * RANGE_CIRCLE_PCT, size * RANGE_CIRCLE_PCT)
    ring:SetPoint("CENTER", f, "CENTER")
    f.ring = ring

    -- ── Player dot (center indicator) ─────────────────────────────────
    local dot = f:CreateTexture(nil, "OVERLAY")
    dot:SetTexture("Interface\\Minimap\\MinimapArrow")
    dot:SetSize(20, 20)
    dot:SetPoint("CENTER", f, "CENTER")
    dot:SetVertexColor(1, 0.82, 0, 1)
    f.playerDot = dot

    -- ── Cardinal labels ───────────────────────────────────────────────
    local textFrame = CreateFrame("Frame", nil, f)
    textFrame:SetAllPoints(f)
    textFrame:SetFrameLevel(f:GetFrameLevel() + 2)
    f.textFrame = textFrame

    for i, data in ipairs(CARDINAL_DATA) do
        local fs = textFrame:CreateFontString(nil, "OVERLAY")
        fs:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        -- N/S/E/W are gold, diagonals are dimmer
        if i % 2 == 1 then
            fs:SetTextColor(1, 0.82, 0, 0.85)
        else
            fs:SetTextColor(1, 0.82, 0, 0.55)
            fs:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        end
        fs:SetText(data.label)
        fs.rad = data.rad
        self.cardinals[i] = fs
    end

    -- ── Distance / step text ──────────────────────────────────────────
    local distText = textFrame:CreateFontString(nil, "OVERLAY")
    distText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    distText:SetTextColor(1, 1, 1, 1)
    distText:SetPoint("CENTER", f, "CENTER", 0, -30)
    f.distText = distText

    local stepText = textFrame:CreateFontString(nil, "OVERLAY")
    stepText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    stepText:SetTextColor(0.88, 0.83, 0.65, 0.9)
    stepText:SetPoint("CENTER", f, "CENTER", 0, -46)
    stepText:SetWidth(250)
    stepText:SetWordWrap(false)
    f.stepText = stepText

    -- ── Coordinate display ────────────────────────────────────────────
    local coordText = textFrame:CreateFontString(nil, "OVERLAY")
    coordText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    coordText:SetTextColor(1, 0.82, 0, 0.7)
    coordText:SetPoint("CENTER", f, "CENTER", 0, -(size * CARDINAL_RADIUS * 0.52))
    f.coordText = coordText

    -- ── Waypoint pins ─────────────────────────────────────────────────
    for i = 1, MAX_PINS do
        local pin = CreateFrame("Frame", nil, textFrame)
        pin:SetSize(PIN_SIZE, PIN_SIZE)
        pin:SetFrameLevel(textFrame:GetFrameLevel() + 1)

        local tex = pin:CreateTexture(nil, "ARTWORK")
        tex:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
        tex:SetTexCoord(0.125, 0.175, 0.125, 0.175)  -- small circle area
        tex:SetAllPoints(pin)
        pin.tex = tex

        -- Fallback: simple colored square (more reliable across game versions)
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(1, 0.82, 0, 1)

        -- Number label on pin
        local num = pin:CreateFontString(nil, "OVERLAY")
        num:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        num:SetTextColor(0, 0, 0, 1)
        num:SetPoint("CENTER", pin, "CENTER", 0, 0)
        pin.numLabel = num

        pin:Hide()
        self.pins[i] = pin
    end

    self.frame = f
    self.hudRadius = size / 2
end

-- ── Tick — 30fps update ───────────────────────────────────────────────────────

function NavHud:Tick()
    if not self.frame or not self.frame:IsShown() then return end

    local bearing = GetPlayerFacing()
    if not bearing then
        -- Fallback: try to infer from Arrow module's last known facing
        local Arrow = TA:GetModule("Arrow")
        bearing = (Arrow and Arrow._lastFacing) or 0
    end

    -- ── Update cardinal labels ────────────────────────────────────────
    local radius = self.hudRadius * CARDINAL_RADIUS
    for _, fs in ipairs(self.cardinals) do
        local x = math.sin(fs.rad + bearing) * radius
        local y = math.cos(fs.rad + bearing) * radius
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", self.frame, "CENTER", x, y)
    end

    -- ── Update coordinate display ─────────────────────────────────────
    local currentMap = C_Map.GetBestMapForUnit("player")
    if currentMap then
        local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
        if pos then
            local px, py = pos:GetXY()
            self.frame.coordText:SetFormattedText("%.1f, %.1f", px * 100, py * 100)

            -- ── Update waypoint pins ──────────────────────────────────
            self:UpdatePins(px, py, bearing, currentMap)
        end
    end
end

-- ── Pin positioning ───────────────────────────────────────────────────────────

function NavHud:UpdatePins(playerX, playerY, bearing, currentMap)
    local QT = TA:GetModule("QuestTracker")
    local Arrow = TA:GetModule("Arrow")
    if not QT or not QT.guideID then
        self:HideAllPins()
        self.frame.distText:SetText("")
        self.frame.stepText:SetText("")
        return
    end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then self:HideAllPins(); return end

    local GP = TA:GetModule("GuideParser")
    local pinIdx = 0

    for i = QT.stepIdx, math.min(QT.stepIdx + MAX_PINS - 1, #guide.steps) do
        local step = guide.steps[i]
        if not step then break end  -- stop scanning (real break)

        repeat  -- continue wrapper
            if not step.coord then break end
            if step.type == "text" then break end
            if step.noArrow then break end

            -- Get effective coord (falls back to Blizzard waypoint data)
            local coordMap, cx, cy = 0, 0, 0
            if Arrow and Arrow.GetEffectiveCoord then
                coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
            elseif step.coord then
                coordMap, cx, cy = step.coord.map or 0, step.coord.x, step.coord.y
            end

            if coordMap == 0 and cx == 0 and cy == 0 then break end

            -- Zone check: skip pins from other zones
            if coordMap ~= 0 and coordMap ~= currentMap then break end

            pinIdx = pinIdx + 1
            if pinIdx > MAX_PINS then break end

            local pin = self.pins[pinIdx]

            -- Calculate screen position relative to player
            local dx = cx - playerX
            local dy = cy - playerY
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Angle from player to target (world space)
            local angle = math.atan2(dx, -dy)  -- same convention as Arrow.lua

            -- Rotate by player bearing so "ahead" is always up
            local screenAngle = angle - bearing

            -- Scale distance into HUD radius. Normalize using a sensible max range.
            -- At max zoom (0), minimap covers ~500 yards. Use 0.15 as max normalized
            -- distance on the map (roughly equivalent to minimap edge).
            local maxNorm = 0.15
            local normDist = math.min(dist / maxNorm, 1.0)

            -- Position within HUD
            local hudDist = normDist * self.hudRadius * 0.85  -- 85% of radius (leave room for cardinals)
            local screenX = math.sin(screenAngle) * hudDist
            local screenY = math.cos(screenAngle) * hudDist

            pin:ClearAllPoints()
            pin:SetPoint("CENTER", self.frame, "CENTER", screenX, screenY)
            pin:Show()

            -- Color by step type
            local color = PIN_COLORS[step.type] or PIN_COLORS.default
            pin.tex:SetVertexColor(unpack(color))

            -- Number label (relative to current step)
            local relNum = i - QT.stepIdx + 1
            pin.numLabel:SetText(relNum)

            -- First pin (current step) is larger and shows distance
            if i == QT.stepIdx then
                pin:SetSize(PIN_SIZE * 1.5, PIN_SIZE * 1.5)
                local yards = U.ComputeDistance(playerX, playerY, cx, cy)
                self.frame.distText:SetText(U.FormatDistance(yards))

                -- Step text (truncate)
                local text = step.text or ""
                if #text > 40 then text = text:sub(1, 37) .. "..." end
                self.frame.stepText:SetText(text)
            else
                pin:SetSize(PIN_SIZE, PIN_SIZE)
            end
        until true
    end

    -- Hide unused pins
    for i = pinIdx + 1, MAX_PINS do
        self.pins[i]:Hide()
    end

    -- If no pins were placed, clear text
    if pinIdx == 0 then
        self.frame.distText:SetText("")
        self.frame.stepText:SetText("")
    end
end

function NavHud:HideAllPins()
    for i = 1, MAX_PINS do
        self.pins[i]:Hide()
    end
end

-- ── Toggle / Control ──────────────────────────────────────────────────────────

function NavHud:Toggle()
    if not self.frame then
        self:CreateHud()
    end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function NavHud:Show()
    if not self.frame then self:CreateHud() end
    self.frame:Show()

    -- Force rotate minimap on (restore on hide)
    self._prevRotate = GetCVar("rotateMinimap")
    SetCVar("rotateMinimap", "1")

    -- Start ticker if not running
    if not self.ticker then
        self.ticker = C_Timer.NewTicker(UPDATE_HZ, function()
            NavHud:Tick()
        end)
    end

    if TA.charDB then
        TA.charDB.navhud = TA.charDB.navhud or {}
        TA.charDB.navhud.visible = true
    end
    print("|cFFFFD100[TA NavHud]|r Shown. Type |cFFFFD100/ta hud|r to hide.")
end

function NavHud:Hide()
    if self.frame then self.frame:Hide() end

    -- Restore rotateMinimap CVar
    if self._prevRotate then
        SetCVar("rotateMinimap", self._prevRotate)
        self._prevRotate = nil
    end

    -- Stop ticker
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    if TA.charDB then
        TA.charDB.navhud = TA.charDB.navhud or {}
        TA.charDB.navhud.visible = false
    end
end

function NavHud:IsVisible()
    return self.frame and self.frame:IsShown()
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function NavHud:Init()
    -- Defer frame creation until first use (lightweight at login)
    -- Restore visibility from saved state
    if TA.charDB and TA.charDB.navhud and TA.charDB.navhud.visible then
        -- Slight delay to let other modules initialize first (Arrow, QuestTracker)
        C_Timer.After(1, function()
            NavHud:Show()
        end)
    end
end

-- ── Slash command ─────────────────────────────────────────────────────────────

NavHud.SlashCommands = {
    hud = function(self) self:Toggle() end,
}
