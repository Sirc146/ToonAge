-- CharacterAdvisor/Core/MinimapButton.lua
-- Draggable minimap button — follows the guide's radial orbit pattern exactly.
-- OnUpdate is registered only during drag and unregistered immediately on drag stop.

local CA = CharacterAdvisor

function CA:InitMinimap()
    if self.minimapBtn then return end

    local btn = CreateFrame("Button", "CharacterAdvisorMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- ── Icon ──────────────────────────────────────────────────────────
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", btn, "CENTER", -1, 1)
    -- Use a character/advisor relevant icon; falls back gracefully
    icon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")

    -- ── Blizzard circular border overlay ─────────────────────────────
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- ── Radial orbit geometry ─────────────────────────────────────────
    -- Saved angle persists across sessions via SavedVariables
    local ORBIT_RADIUS = 78
    local angle = (CA.db and CA.db.minimap and CA.db.minimap.position) or 45

    local function UpdatePosition()
        btn:SetPoint("CENTER", Minimap, "CENTER",
            ORBIT_RADIUS * math.cos(math.rad(angle)),
            ORBIT_RADIUS * math.sin(math.rad(angle)))
    end

    -- ── Drag: OnUpdate only active during drag (guide pattern) ────────
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
        -- Register OnUpdate ONLY while dragging — unregistered on stop
        self:SetScript("OnUpdate", TrackCursor)
        self:LockHighlight()
    end)

    btn:SetScript("OnDragStop", function(self)
        -- Unregister immediately — no wasted OnUpdate ticks at rest
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
        -- Persist position to SavedVariables
        if CA.db and CA.db.minimap then
            CA.db.minimap.position = angle
        end
    end)

    -- ── Clicks ────────────────────────────────────────────────────────
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            CA:ToggleUI()
        elseif button == "RightButton" then
            print("|cFFFFD100[CA]|r Type |cFFFFD100/ca|r for commands.")
        end
    end)

    -- ── Tooltip ───────────────────────────────────────────────────────
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD100Character Advisor|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open / close", 0, 1, 0)
        GameTooltip:AddLine("Right-click: commands", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Drag: reposition button", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Place on minimap at saved position
    UpdatePosition()

    self.minimapBtn = btn
end
