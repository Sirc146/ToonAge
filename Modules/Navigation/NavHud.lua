-- ToonAge/Modules/NavHud.lua (Classic — MoP 50504)
-- FarmHud-style transparent rotated HUD overlay for quest/guide navigation.
-- Shows quest waypoints, guide step pins, and cardinal directions on a
-- transparent circular display that rotates with the player's facing direction.
--
-- Classic adaptation:
--   - Removed dragonriding-specific features
--   - No C_Timer.NewTicker — uses OnUpdate throttle or C_Timer.After loop
--   - GetPlayerFacing() works in MoP Classic
--   - C_Map.GetBestMapForUnit / GetPlayerMapPosition available
--   - Simplified pin system (no dynamic flight layer)
--   - SetCVar("rotateMinimap") works in MoP Classic

local TA = ToonAge
local U  = TA.Utils

local NavHud = {}
TA:RegisterModule("NavHud", NavHud)

-- ── Constants ─────────────────────────────────────────────────────────────────

local HUD_SCALE       = 1.4    -- minimap content scale
local UPDATE_HZ       = 1/30   -- 30fps
local CARDINAL_RADIUS = 0.47   -- distance from center as fraction of HUD radius
local RANGE_CIRCLE_PCT = 0.435 -- proximity circle as fraction of HUD size
local MAX_PINS        = 5      -- max upcoming guide step pins shown
local PIN_SIZE        = 16     -- pixels per waypoint pin

-- ── NavHud Settings (saved in charDB.navhud) ──────────────────────────────────
local NAVHUD_DEFAULTS = {
    visible         = false,
    scale           = 1.4,
    opacity         = 0.85,
    showCardinals   = true,
    showCoords      = true,
    showDistance     = true,
    showStepText    = true,
    showRing        = true,
    showPins        = true,
    pinSize         = 16,
    maxPins         = 5,
}

local function GetSetting(key)
    if TA.charDB and TA.charDB.navhud and TA.charDB.navhud[key] ~= nil then
        return TA.charDB.navhud[key]
    end
    return NAVHUD_DEFAULTS[key]
end

local function SetSetting(key, value)
    if not TA.charDB then return end
    TA.charDB.navhud = TA.charDB.navhud or {}
    TA.charDB.navhud[key] = value
end

NavHud.GetSetting = GetSetting
NavHud.SetSetting = SetSetting

-- Pin colors by step type
local PIN_COLORS = {
    pickup    = { 0.29, 1.00, 0.48, 1.0 },
    turnin    = { 1.00, 0.82, 0.00, 1.0 },
    objective = { 1.00, 0.67, 0.20, 1.0 },
    waypoint  = { 0.12, 0.74, 1.00, 1.0 },
    quest     = { 1.00, 0.82, 0.00, 1.0 },
    travel    = { 0.12, 0.74, 1.00, 1.0 },
    npc       = { 0.47, 1.00, 0.47, 1.0 },
    default   = { 0.88, 0.83, 0.65, 1.0 },
}

-- Cardinal direction data
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
NavHud.pins        = {}
NavHud.cardinals   = {}
NavHud.hudRadius   = 0
NavHud.throttle    = 0

-- ── Frame Construction ────────────────────────────────────────────────────────

function NavHud:CreateHud()
    local f = CreateFrame("Frame", "TANavHud", UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(2)
    f:EnableMouse(false)
    f:SetToplevel(false)
    f:Hide()

    -- Size to screen height (circular)
    local size = UIParent:GetHeight()
    f:SetSize(size, size)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- ── Range/proximity circle ────────────────────────────────────────
    local circle = f:CreateTexture(nil, "ARTWORK")
    circle:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    circle:SetVertexColor(0.12, 0.74, 1.00, 0.15)
    circle:SetSize(size * RANGE_CIRCLE_PCT, size * RANGE_CIRCLE_PCT)
    circle:SetPoint("CENTER", f, "CENTER")
    f.rangeCircle = circle

    -- ── Proximity ring ────────────────────────────────────────────────
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
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(1, 0.82, 0, 1)
        tex:SetAllPoints(pin)
        pin.tex = tex

        local num = pin:CreateFontString(nil, "OVERLAY")
        num:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        num:SetTextColor(0, 0, 0, 1)
        num:SetPoint("CENTER", pin, "CENTER", 0, 0)
        pin.numLabel = num

        pin:Hide()
        self.pins[i] = pin
    end

    -- ── OnUpdate for tick ─────────────────────────────────────────────
    f:SetScript("OnUpdate", function(_, elapsed)
        self.throttle = self.throttle + elapsed
        if self.throttle < UPDATE_HZ then return end
        self.throttle = 0
        self:Tick()
    end)

    self.frame = f
    self.hudRadius = size / 2
end

-- ── Tick — 30fps update ───────────────────────────────────────────────────────

function NavHud:Tick()
    if not self.frame or not self.frame:IsShown() then return end

    local bearing = GetPlayerFacing()
    if not bearing then
        local Arrow = TA:GetModule("Arrow")
        bearing = (Arrow and Arrow._lastFacing) or 0
    end

    -- ── Update cardinal labels ────────────────────────────────────────
    local showCardinals = GetSetting("showCardinals")
    local radius = self.hudRadius * CARDINAL_RADIUS
    for _, fs in ipairs(self.cardinals) do
        if showCardinals then
            local x = math.sin(fs.rad + bearing) * radius
            local y = math.cos(fs.rad + bearing) * radius
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", self.frame, "CENTER", x, y)
            fs:Show()
        else
            fs:Hide()
        end
    end

    -- ── Update coordinate display ─────────────────────────────────────
    local showCoords = GetSetting("showCoords")
    local showDist   = GetSetting("showDistance")
    local showStep   = GetSetting("showStepText")
    if self.frame.coordText then self.frame.coordText:SetShown(showCoords) end
    if self.frame.distText  then self.frame.distText:SetShown(showDist) end
    if self.frame.stepText  then self.frame.stepText:SetShown(showStep) end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if currentMap then
        local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
        if pos then
            local px, py = pos:GetXY()
            if showCoords then
                self.frame.coordText:SetFormattedText("%.1f, %.1f", px * 100, py * 100)
            end

            if GetSetting("showPins") then
                self:UpdatePins(px, py, bearing, currentMap)
            else
                self:HideAllPins()
            end
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

    local pinIdx = 0

    for i = QT.stepIdx, math.min(QT.stepIdx + MAX_PINS - 1, #guide.steps) do
        local step = guide.steps[i]
        if not step then break end

        repeat  -- continue wrapper
            if not step.coord then break end
            if step.type == "text" then break end
            if step.noArrow then break end

            -- Get effective coord via Arrow module or direct step coord
            local coordMap, cx, cy = 0, 0, 0
            if Arrow and Arrow.GetEffectiveCoord then
                coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
            elseif step.coord then
                coordMap, cx, cy = step.coord.map or 0, step.coord.x or 0, step.coord.y or 0
            end

            if coordMap == 0 and cx == 0 and cy == 0 then break end
            if coordMap ~= 0 and coordMap ~= currentMap then break end

            pinIdx = pinIdx + 1
            if pinIdx > MAX_PINS then break end

            local pin = self.pins[pinIdx]

            -- Calculate screen position relative to player
            local dx = cx - playerX
            local dy = cy - playerY
            local dist = math.sqrt(dx * dx + dy * dy)
            local angle = math.atan2(dx, -dy)
            local screenAngle = angle - bearing

            local maxNorm = 0.15
            local normDist = math.min(dist / maxNorm, 1.0)
            local hudDist = normDist * self.hudRadius * 0.85
            local screenX = math.sin(screenAngle) * hudDist
            local screenY = math.cos(screenAngle) * hudDist

            pin:ClearAllPoints()
            pin:SetPoint("CENTER", self.frame, "CENTER", screenX, screenY)
            pin:Show()

            local color = PIN_COLORS[step.type] or PIN_COLORS.default
            pin.tex:SetVertexColor(unpack(color))

            local relNum = i - QT.stepIdx + 1
            pin.numLabel:SetText(relNum)

            -- First pin (current step) is larger and shows distance
            if i == QT.stepIdx then
                pin:SetSize(PIN_SIZE * 1.5, PIN_SIZE * 1.5)
                local yards = U.ComputeDistance(playerX, playerY, cx, cy)
                self.frame.distText:SetText(U.FormatDistance(yards))

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

function NavHud:ApplySettings()
    if not self.frame then return end
    self.frame:SetScale(GetSetting("scale") or 1.0)
    self.frame:SetAlpha(GetSetting("opacity") or 1.0)
    local showRing = GetSetting("showRing")
    if self.frame.ring       then self.frame.ring:SetShown(showRing) end
    if self.frame.rangeCircle then self.frame.rangeCircle:SetShown(showRing) end
end

function NavHud:Show()
    if not self.frame then self:CreateHud() end
    self.frame:Show()
    self:ApplySettings()

    -- Force rotate minimap on
    self._prevRotate = GetCVar("rotateMinimap")
    SetCVar("rotateMinimap", "1")

    if TA.charDB then
        TA.charDB.navhud = TA.charDB.navhud or {}
        TA.charDB.navhud.visible = true
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA NavHud]|r Shown. Type |cFFFFD100/ta hud|r to hide.")
end

function NavHud:Hide()
    if self.frame then self.frame:Hide() end

    if self._prevRotate then
        SetCVar("rotateMinimap", self._prevRotate)
        self._prevRotate = nil
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
    if TA.charDB then
        TA.charDB.navhud = TA.charDB.navhud or {}
        for k, v in pairs(NAVHUD_DEFAULTS) do
            if TA.charDB.navhud[k] == nil then
                TA.charDB.navhud[k] = v
            end
        end
    end

    -- Restore visibility from saved state
    if GetSetting("visible") then
        C_Timer.After(1, function()
            NavHud:Show()
        end)
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────

local function PrintHudSettings()
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge NavHud Settings]|r")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100scale|r = " .. GetSetting("scale") .. "  (HUD size)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100opacity|r = " .. GetSetting("opacity") .. "  (overall transparency)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showCardinals|r = " .. tostring(GetSetting("showCardinals")) .. "  (N/S/E/W)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showCoords|r = " .. tostring(GetSetting("showCoords")) .. "  (coordinates)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showDistance|r = " .. tostring(GetSetting("showDistance")) .. "  (yards to waypoint)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showStepText|r = " .. tostring(GetSetting("showStepText")) .. "  (step description)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showRing|r = " .. tostring(GetSetting("showRing")) .. "  (proximity circle)")
    TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100showPins|r = " .. tostring(GetSetting("showPins")) .. "  (waypoint pins)")
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  Change: |cFFFFD100/ta hud set <key> <value>|r")
end

local function ApplyHudSetting(msg)
    if not msg or msg == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Usage: /ta hud set <key> <value>")
        return
    end
    local key, valStr = msg:match("^(%S+)%s+(.+)$")
    if not key then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Usage: /ta hud set showCoords false")
        return
    end

    if NAVHUD_DEFAULTS[key] == nil then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Unknown setting: " .. key)
        return
    end

    local defaultVal = NAVHUD_DEFAULTS[key]
    local value
    if type(defaultVal) == "boolean" then
        value = (valStr == "true" or valStr == "1" or valStr == "on")
    elseif type(defaultVal) == "number" then
        value = tonumber(valStr)
        if not value then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Value must be a number for '" .. key .. "'")
            return
        end
    else
        value = valStr
    end

    SetSetting(key, value)
    if key == "scale" or key == "opacity" or key == "showRing" then
        NavHud:ApplySettings()
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA NavHud]|r " .. key .. " = " .. tostring(value))
end

NavHud.SlashCommands = {
    hud = function(self, args)
        local sub, rest = (args or ""):match("^(%S*)%s*(.*)$")
        sub = (sub or ""):lower()

        if sub == "" then
            self:Toggle()
        elseif sub == "settings" then
            PrintHudSettings()
        elseif sub == "set" then
            ApplyHudSetting(rest)
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Unknown subcommand '" .. sub .. "'. Try: settings, set")
        end
    end,
}
