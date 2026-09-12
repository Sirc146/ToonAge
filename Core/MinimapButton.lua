-- ToonAge/Core/MinimapButton.lua (Anniversary — TBC Classic / 20506)
-- Draggable minimap button. Pure frame API, no client-specific calls.
--
-- Forked from the _classic_ copy rather than copied: that version's right-click
-- toggles db.useUnifiedUI and calls TA:ApplyLayout(), neither of which exists in
-- this build — there is one window and no layout modes. Right-click jumps to
-- Stat Caps instead, which is the tab worth one click.

local TA = ToonAge

function TA:InitMinimap()
    if self.minimapBtn then return end
    if not Minimap then return end

    local btn = CreateFrame("Button", "ToonAgeMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

    -- ─── Icon & Border ────────────────────────────────────────────────────
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", btn, "CENTER", -1, 1)
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_InnerRage")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- ─── Radial Orbit Geometry ────────────────────────────────────────────
    local ORBIT_RADIUS = 78
    local angle = (TA.db and TA.db.minimap and TA.db.minimap.position) or 45

    local function UpdatePosition()
        -- Floored: a fractional frame position renders on a half pixel and
        -- blurs the icon (.kiro/steering/precision.md §4).
        btn:SetPoint("CENTER", Minimap, "CENTER",
            math.floor(ORBIT_RADIUS * math.cos(math.rad(angle))),
            math.floor(ORBIT_RADIUS * math.sin(math.rad(angle))))
    end

    -- ─── Drag: OnUpdate Only While Dragging ────────────────────────────────
    local function TrackCursor()
        local cx, cy = Minimap:GetCenter()
        if not cx then return end
        local mx, my = GetCursorPosition()
        local scale  = Minimap:GetEffectiveScale()
        if not scale or scale == 0 then return end
        angle = math.deg(math.atan2(my / scale - cy, mx / scale - cx))
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
            -- 2 dp is plenty for an orbit angle; more just churns SavedVariables.
            TA.db.minimap.position = tonumber(string.format("%.2f", angle))
        end
    end)

    -- ─── Clicks ─────────────────────────────────────────────────────────
    -- WARN: the MiddleButton branch below indexes TA.db.minimap.minimized
    -- with no nil-guard, unlike OnDragStop just above (which checks `TA.db
    -- and TA.db.minimap` first) and the minimized-restore check further down.
    -- If OnClick ever fires before TA.db.minimap exists — e.g. SavedVariables
    -- not yet loaded/defaulted — a middle-click here throws "attempt to index
    -- a nil value" instead of failing quietly like its siblings do.
    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            TA:ToggleUI()
        elseif button == "RightButton" then
            TA:ShowUI()
            if TA.UI and TA.UI.SetTab then TA.UI:SetTab("caps") end
        elseif button == "MiddleButton" then
            local minimized = not (TA.db.minimap.minimized or false)
            TA.db.minimap.minimized = minimized
            if minimized then icon:Hide(); border:Hide() else icon:Show(); border:Show() end
        end
    end)

    -- ─── Tooltip ────────────────────────────────────────────────────────
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD100ToonAge|r |cFF888780Anniversary|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open / close", 0, 1, 0)
        GameTooltip:AddLine("Right-click: jump to Stat Caps", 1, 0.82, 0)
        GameTooltip:AddLine("Middle-click: hide the icon", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Drag: reposition", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ─── Initial State ──────────────────────────────────────────────────
    UpdatePosition()

    if TA.db and TA.db.minimap and TA.db.minimap.minimized then
        icon:Hide()
        border:Hide()
    end

    self.minimapBtn = btn
end
