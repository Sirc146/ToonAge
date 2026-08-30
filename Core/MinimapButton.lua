-- ToonAge/Core/MinimapButton.lua (Classic)
-- Draggable minimap button — identical to Retail (pure frame API).

local TA = ToonAge

function TA:InitMinimap()
    if self.minimapBtn then return end

    local btn = CreateFrame("Button", "ToonAgeMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

    -- Icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", btn, "CENTER", -1, 1)
    icon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")

    -- Border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- Radial orbit
    local ORBIT_RADIUS = 78
    local angle = (TA.db and TA.db.minimap and TA.db.minimap.position) or 45

    local function UpdatePosition()
        btn:SetPoint("CENTER", Minimap, "CENTER",
            ORBIT_RADIUS * math.cos(math.rad(angle)),
            ORBIT_RADIUS * math.sin(math.rad(angle)))
    end

    local function TrackCursor()
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        local scale  = Minimap:GetEffectiveScale()
        mx = mx / scale
        my = my / scale
        angle = math.deg(math.atan2(my - cy, mx - cx))
        UpdatePosition()
    end

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", TrackCursor)
        self:LockHighlight()
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
        if TA.db and TA.db.minimap then
            TA.db.minimap.position = angle
        end
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            TA:ToggleUI()
        elseif button == "RightButton" then
            TA.db.useUnifiedUI = not TA.db.useUnifiedUI
            TA:ApplyLayout()
            local mode = TA.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout: " .. mode)
        elseif button == "MiddleButton" then
            local minimized = not (TA.db.minimap.minimized or false)
            TA.db.minimap.minimized = minimized
            if minimized then
                icon:Hide()
                border:Hide()
            else
                icon:Show()
                border:Show()
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD100ToonAge|r |cFF888780Classic|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open / close main panel", 0, 1, 0)
        GameTooltip:AddLine("Right-click: swap layout", 1, 0.82, 0)
        GameTooltip:AddLine("Middle-click: hide / show button icon", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Drag: reposition button", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()

    if TA.db.minimap.minimized then
        icon:Hide()
        border:Hide()
    end

    self.minimapBtn = btn
end
