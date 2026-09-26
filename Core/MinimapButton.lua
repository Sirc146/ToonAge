-- ToonAge/Core/MinimapButton.lua
-- Draggable minimap button — follows the guide's radial orbit pattern exactly.
-- OnUpdate is registered only during drag and unregistered immediately on drag stop.

local TA = ToonAge

function TA:InitMinimap()
    if self.minimapBtn then return end

    local btn = CreateFrame("Button", "ToonAgeMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

    -- ── Icon ──────────────────────────────────────────────────────────
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", btn, "CENTER", -1, 1)
    -- Use a character/advisor relevant icon; falls back gracefully
    icon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")
    -- Every other minimap button crops its icon square into the circle. Without
    -- this the corners of the art stick out past the border ring and ToonAge's
    -- button reads as a different shape from its neighbours.
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- ── Blizzard circular border overlay ─────────────────────────────
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- ── Radial orbit geometry ─────────────────────────────────────────
    -- Saved angle persists across sessions via SavedVariables.
    --
    -- The radius is MEASURED, not fixed. A hardcoded 78 assumes a 140-wide
    -- minimap; this client's is larger, so the button sat INSIDE the map next
    -- to the terrain instead of out on the ring with every other addon's.
    -- Half the minimap's real width plus a small offset puts it exactly where
    -- the neighbours sit, whatever size the minimap is or becomes.
    local function OrbitRadius()
        local w = (Minimap and Minimap.GetWidth and Minimap:GetWidth()) or 140
        if not w or w <= 0 then w = 140 end
        return (w / 2) + 10
    end

    local angle = (TA.db and TA.db.minimap and TA.db.minimap.position) or 45

    local function UpdatePosition()
        local r = OrbitRadius()
        btn:SetPoint("CENTER", Minimap, "CENTER",
            r * math.cos(math.rad(angle)),
            r * math.sin(math.rad(angle)))
    end

    -- ── Drag: OnUpdate only active during drag (guide pattern) ────────
    local function TrackCursor()
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        local scale  = Minimap:GetEffectiveScale()
        mx = mx / scale
        my = my / scale
        angle = math.deg(math.atan2(my - cy, mx - cx))
        UpdatePosition()   -- radius re-measured every frame, so a resized
                           -- minimap never strands the button mid-drag
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
        if TA.db and TA.db.minimap then
            TA.db.minimap.position = angle
        end
    end)

    -- ── Clicks ────────────────────────────────────────────────────────
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            TA:ToggleUI()
        elseif button == "RightButton" then
            -- Right-click: instantly swap between Unified HUD and Fragmented layout.
            -- This is the fastest access point — no menus needed.
            TA.db.useUnifiedUI = not TA.db.useUnifiedUI
            TA:ApplyLayout()
            local mode = TA.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout: " .. mode)
        elseif button == "MiddleButton" then
            -- Middle-click: hide / show button icon (minimized mode).
            -- Keeps the 31×31 hit area alive so the button can be found again.
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

    -- ── Tooltip ───────────────────────────────────────────────────────
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD100ToonAge|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open / close main panel", 0, 1, 0)
        local layoutMode = (TA.db and TA.db.useUnifiedUI) and "Unified HUD" or "Fragmented Windows"
        GameTooltip:AddLine("Right-click: swap layout  (now: " .. layoutMode .. ")", 1, 0.82, 0)
        GameTooltip:AddLine("Middle-click: hide / show button icon", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Drag: reposition button", 0.5, 0.5, 0.5)
        if TA.db and TA.db.minimap and TA.db.minimap.minimized then
            GameTooltip:AddLine("(Minimized — middle-click to restore)", 1, 0.82, 0)
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Place on minimap at saved position.
    --
    -- Re-placed on the events that change the minimap's size: at login the
    -- frame may not have its final width yet, and a UI-scale or resolution
    -- change moves the ring out from under the button.
    btn:RegisterEvent("PLAYER_ENTERING_WORLD")
    btn:RegisterEvent("DISPLAY_SIZE_CHANGED")
    btn:RegisterEvent("UI_SCALE_CHANGED")
    btn:SetScript("OnEvent", function() UpdatePosition() end)

    UpdatePosition()
    if C_Timer and C_Timer.After then
        -- One late pass: some clients finish sizing the minimap a frame or two
        -- after login, and the first placement would keep a stale radius.
        C_Timer.After(1, UpdatePosition)
    end

    -- Restore minimized state from SavedVariables
    if TA.db.minimap.minimized then
        icon:Hide()
        border:Hide()
    end

    self.minimapBtn = btn
end
