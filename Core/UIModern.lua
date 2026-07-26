-- ToonAge/Core/UIModern.lua
-- Modernization layer: typography, backdrop helpers, animation utilities,
-- collapsible sections, and side-drawer integration.
--
-- Loaded AFTER Core/UI.lua (added to TOC below UI.lua).
-- All utilities hang off TA.Modern so modules can opt-in incrementally.

local TA = ToonAge
TA.Modern = TA.Modern or {}
local M = TA.Modern

-- =============================================================================
-- SECTION 1 — TYPOGRAPHY
-- =============================================================================
-- WoW ships several clean fonts. We pick sans-serif options that render well
-- at small sizes without looking dated. FRIZQT is the cleanest built-in sans.
-- NumberFont_OutlineThick_Mono_Small is monospace for data columns.

M.FONT_HEADER  = "Fonts\\FRIZQT__.TTF"   -- clean sans-serif, bold via OUTLINE
M.FONT_BODY    = "Fonts\\FRIZQT__.TTF"   -- same face, normal weight (no outline)
M.FONT_CAPTION = "Fonts\\FRIZQT__.TTF"   -- small captions
M.FONT_MONO    = "Fonts\\ARIALN.TTF"     -- monospace-like for numbers/data

-- Size hierarchy (establishes visual weight without relying on color alone)
M.SIZE_H1      = 14
M.SIZE_H2      = 12
M.SIZE_H3      = 11
M.SIZE_BODY    = 10
M.SIZE_CAPTION = 9
M.SIZE_TINY    = 8

-- Color palette — neutral tones replace the gold/amber legacy look
M.CLR_TEXT_PRIMARY   = { 0.92, 0.90, 0.87, 1.00 }  -- warm white
M.CLR_TEXT_SECONDARY = { 0.62, 0.59, 0.55, 1.00 }  -- muted gray
M.CLR_TEXT_ACCENT    = { 0.40, 0.75, 1.00, 1.00 }  -- cool blue accent
M.CLR_TEXT_SUCCESS   = { 0.30, 0.92, 0.40, 1.00 }  -- green
M.CLR_TEXT_WARNING   = { 1.00, 0.65, 0.20, 1.00 }  -- orange
M.CLR_TEXT_DANGER    = { 1.00, 0.35, 0.30, 1.00 }  -- red

-- =============================================================================
-- SECTION 2 — BACKDROP HELPERS
-- =============================================================================
-- Modern flat backdrops: slightly translucent, thin 1px borders, no textures.

M.BACKDROP_FLAT = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

--- Apply a modern translucent backdrop to a frame.
--- @param frame Frame - must inherit BackdropTemplate
--- @param style string|nil - "panel", "card", "input", "header", or nil (default panel)
function M:ApplyBackdrop(frame, style)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(self.BACKDROP_FLAT)

    if style == "card" then
        frame:SetBackdropColor(0.08, 0.08, 0.10, 0.92)
        frame:SetBackdropBorderColor(0.28, 0.28, 0.32, 0.60)
    elseif style == "input" then
        frame:SetBackdropColor(0.04, 0.04, 0.05, 0.95)
        frame:SetBackdropBorderColor(0.22, 0.22, 0.26, 0.50)
    elseif style == "header" then
        frame:SetBackdropColor(0.12, 0.12, 0.14, 0.96)
        frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 0.50)
    elseif style == "success" then
        frame:SetBackdropColor(0.04, 0.10, 0.04, 0.92)
        frame:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.55)
    elseif style == "danger" then
        frame:SetBackdropColor(0.10, 0.04, 0.04, 0.92)
        frame:SetBackdropBorderColor(0.90, 0.30, 0.25, 0.55)
    elseif style == "warning" then
        frame:SetBackdropColor(0.10, 0.07, 0.02, 0.92)
        frame:SetBackdropBorderColor(0.90, 0.60, 0.15, 0.50)
    else  -- "panel" / default
        frame:SetBackdropColor(0.06, 0.06, 0.08, 0.94)
        frame:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.50)
    end
end


-- =============================================================================
-- SECTION 2B — DOUBLE-PANE GLASS BACKDROP
-- =============================================================================
-- The premium "frosted glass" look: a solid dark base layer for text readability,
-- a frosted texture overlay for depth, a crisp 1px opaque border, and a drop
-- shadow frame behind the panel for perceived elevation.
--
-- This is the primary styling call for all major panels (main frame, drawer,
-- options). Card-level elements should continue using M:ApplyBackdrop("card").

M.GLASS_BACKDROP_BASE = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

M.GLASS_BACKDROP_FROST = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "",
    edgeSize = 0,
}

M.GLASS_SHADOW_BACKDROP = {
    bgFile   = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
}

--- Apply the double-pane frosted glass backdrop to a major panel frame.
--- Creates: base layer (solid dark) → frosted overlay → 1px opaque border → drop shadow.
--- @param frame Frame - must inherit BackdropTemplate
--- @param opts table|nil - optional overrides { noShadow=bool, baseTint={r,g,b,a}, frostTint={r,g,b,a} }
function M:ApplyGlassBackdrop(frame, opts)
    if not frame or not frame.SetBackdrop then return end
    opts = opts or {}

    -- ── Layer 1: Solid dark base (visibility shield) ──────────────────
    frame:SetBackdrop(self.GLASS_BACKDROP_BASE)
    local bt = opts.baseTint or { 0.05, 0.05, 0.06, 0.90 }
    frame:SetBackdropColor(bt[1], bt[2], bt[3], bt[4])
    -- 100% opaque border for sharp definition
    local bc = opts.borderColor or { 0.30, 0.30, 0.35, 1.00 }
    frame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4])

    -- ── Layer 2: Frosted glass overlay texture ────────────────────────
    if not frame._glassFrost then
        local frost = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frost:SetAllPoints(frame)
        frost:SetFrameLevel(frame:GetFrameLevel() + 1)
        frame._glassFrost = frost
    end
    frame._glassFrost:SetBackdrop(self.GLASS_BACKDROP_FROST)
    local ft = opts.frostTint or { 0.08, 0.08, 0.10, 0.60 }
    frame._glassFrost:SetBackdropColor(ft[1], ft[2], ft[3], ft[4])
    frame._glassFrost:Show()

    -- ── Layer 3: Drop shadow (perceived elevation) ────────────────────
    if not opts.noShadow then
        if not frame._glassShadow then
            local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
            shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
            shadow:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
            frame._glassShadow = shadow
        end
        frame._glassShadow:SetBackdrop(self.GLASS_SHADOW_BACKDROP)
        frame._glassShadow:SetBackdropBorderColor(0, 0, 0, 0.70)
        frame._glassShadow:Show()
    end
end

--- Remove glass backdrop layers (useful when switching styles dynamically).
function M:ClearGlassBackdrop(frame)
    if not frame then return end
    if frame._glassFrost then frame._glassFrost:Hide() end
    if frame._glassShadow then frame._glassShadow:Hide() end
end


--- Apply a colored glow border (2px inset glow texture around a frame).
--- Used for gear slot status indicators instead of text brackets.
--- @param frame Frame
--- @param r number
--- @param g number
--- @param b number
--- @param a number|nil
function M:ApplyGlowBorder(frame, r, g, b, a)
    a = a or 0.7
    if not frame._modernGlow then
        local glow = frame:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\WHITE8X8")
        glow:SetAllPoints(frame)
        glow:SetBlendMode("ADD")
        frame._modernGlow = glow

        -- Create inner mask to make it a border effect (inset by 2px)
        local mask = frame:CreateTexture(nil, "OVERLAY", nil, 1)
        mask:SetTexture("Interface\\Buttons\\WHITE8X8")
        mask:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        mask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        frame._modernGlowMask = mask
    end
    frame._modernGlow:SetVertexColor(r, g, b, a * 0.35)
    frame._modernGlow:Show()
    -- The mask uses the frame's own backdrop color to punch through
    frame._modernGlowMask:SetVertexColor(0.06, 0.06, 0.08, 0.94)
    frame._modernGlowMask:Show()
end

--- Remove glow border from a frame.
function M:ClearGlowBorder(frame)
    if frame._modernGlow then frame._modernGlow:Hide() end
    if frame._modernGlowMask then frame._modernGlowMask:Hide() end
end

-- =============================================================================
-- SECTION 3 — GRADIENT STATUS STRIP
-- =============================================================================
-- A thin gradient bar at the bottom of a card frame indicating status at a glance.

--- Add a status gradient strip to the bottom of a frame.
--- @param frame Frame
--- @param status string - "ok", "warning", "danger", "upgrade"
--- @param height number|nil - defaults to 3
function M:ApplyStatusStrip(frame, status, height)
    height = height or 3
    if not frame._statusStrip then
        local strip = frame:CreateTexture(nil, "ARTWORK", nil, 2)
        strip:SetHeight(height)
        strip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        strip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame._statusStrip = strip
    end

    local strip = frame._statusStrip
    strip:SetHeight(height)
    strip:Show()

    if status == "ok" then
        strip:SetGradient("HORIZONTAL",
            CreateColor(0.15, 0.70, 0.30, 0.8),
            CreateColor(0.15, 0.70, 0.30, 0.0))
    elseif status == "upgrade" then
        strip:SetGradient("HORIZONTAL",
            CreateColor(0.12, 1.00, 0.00, 0.9),
            CreateColor(0.12, 1.00, 0.00, 0.0))
    elseif status == "warning" then
        strip:SetGradient("HORIZONTAL",
            CreateColor(1.00, 0.65, 0.10, 0.8),
            CreateColor(1.00, 0.65, 0.10, 0.0))
    elseif status == "danger" then
        strip:SetGradient("HORIZONTAL",
            CreateColor(1.00, 0.30, 0.25, 0.9),
            CreateColor(1.00, 0.30, 0.25, 0.0))
    else
        strip:Hide()
    end
end

--- Remove status strip from a frame.
function M:ClearStatusStrip(frame)
    if frame._statusStrip then frame._statusStrip:Hide() end
end


-- =============================================================================
-- SECTION 4 — ANIMATION UTILITIES
-- =============================================================================
-- Smooth width/height transitions using WoW's AnimationGroup API.
-- These avoid the snap-open feel of raw Show()/Hide().

--- Animate a frame's width from current to target over duration seconds.
--- @param frame Frame
--- @param targetWidth number
--- @param duration number (seconds, default 0.25)
--- @param onFinish function|nil - callback when animation completes
function M:AnimateWidth(frame, targetWidth, duration, onFinish)
    duration = duration or 0.25
    local startWidth = frame:GetWidth()
    if math.abs(startWidth - targetWidth) < 1 then
        frame:SetWidth(targetWidth)
        if onFinish then onFinish() end
        return
    end

    -- Kill any existing width animation on this frame
    if frame._widthAnimTicker then
        frame._widthAnimTicker:Cancel()
        frame._widthAnimTicker = nil
    end

    local elapsed = 0
    local TICK = 0.016  -- ~60fps
    frame._widthAnimTicker = C_Timer.NewTicker(TICK, function(ticker)
        elapsed = elapsed + TICK
        local progress = math.min(elapsed / duration, 1.0)
        -- Ease-out cubic for smooth deceleration
        local eased = 1 - (1 - progress) ^ 3
        local w = startWidth + (targetWidth - startWidth) * eased
        frame:SetWidth(w)
        if progress >= 1.0 then
            ticker:Cancel()
            frame._widthAnimTicker = nil
            frame:SetWidth(targetWidth)
            if onFinish then onFinish() end
        end
    end)
end

--- Animate a frame's height from current to target over duration seconds.
--- @param frame Frame
--- @param targetHeight number
--- @param duration number (seconds, default 0.20)
--- @param onFinish function|nil
function M:AnimateHeight(frame, targetHeight, duration, onFinish)
    duration = duration or 0.20
    local startHeight = frame:GetHeight()
    if math.abs(startHeight - targetHeight) < 1 then
        frame:SetHeight(targetHeight)
        if onFinish then onFinish() end
        return
    end

    if frame._heightAnimTicker then
        frame._heightAnimTicker:Cancel()
        frame._heightAnimTicker = nil
    end

    local elapsed = 0
    local TICK = 0.016
    frame._heightAnimTicker = C_Timer.NewTicker(TICK, function(ticker)
        elapsed = elapsed + TICK
        local progress = math.min(elapsed / duration, 1.0)
        local eased = 1 - (1 - progress) ^ 3
        local h = startHeight + (targetHeight - startHeight) * eased
        frame:SetHeight(h)
        if progress >= 1.0 then
            ticker:Cancel()
            frame._heightAnimTicker = nil
            frame:SetHeight(targetHeight)
            if onFinish then onFinish() end
        end
    end)
end

--- Animate alpha (fade in/out).
--- @param frame Frame
--- @param targetAlpha number (0-1)
--- @param duration number
--- @param onFinish function|nil
function M:AnimateAlpha(frame, targetAlpha, duration, onFinish)
    duration = duration or 0.15
    local startAlpha = frame:GetAlpha()

    if frame._alphaAnimTicker then
        frame._alphaAnimTicker:Cancel()
        frame._alphaAnimTicker = nil
    end

    local elapsed = 0
    local TICK = 0.016
    frame._alphaAnimTicker = C_Timer.NewTicker(TICK, function(ticker)
        elapsed = elapsed + TICK
        local progress = math.min(elapsed / duration, 1.0)
        local eased = 1 - (1 - progress) ^ 3
        local a = startAlpha + (targetAlpha - startAlpha) * eased
        frame:SetAlpha(a)
        if progress >= 1.0 then
            ticker:Cancel()
            frame._alphaAnimTicker = nil
            frame:SetAlpha(targetAlpha)
            if onFinish then onFinish() end
        end
    end)
end


-- =============================================================================
-- SECTION 5 — COLLAPSIBLE SECTION (ACCORDION)
-- =============================================================================
-- Reusable widget: a clickable header that expands/collapses its content body.
-- Used in Character, Gear, and other tabs to save vertical space.
--
-- Usage:
--   local section = TA.Modern:CreateCollapsibleSection(parent, {
--       title       = "Secondary Stats",
--       width       = 400,
--       startOpen   = true,       -- optional, default true
--       contentHeight = 120,      -- optional fixed height, or omit for auto
--       anchorTo    = someFrame,  -- optional, what to anchor below
--       offsetY     = -8,         -- optional vertical offset from anchorTo
--   })
--   -- section.content is the child frame to parent your widgets into
--   -- section:SetCollapsed(true/false) to programmatically toggle
--   -- section:GetCollapsed() returns current state

--- @param parent Frame
--- @param opts table
--- @return table section object with .frame, .content, .header fields
function M:CreateCollapsibleSection(parent, opts)
    opts = opts or {}
    local title         = opts.title or "Section"
    local width         = opts.width or (parent:GetWidth() - 20)
    local startOpen     = opts.startOpen ~= false
    local contentHeight = opts.contentHeight or 80
    local HEADER_H      = 24
    local ANIM_DURATION = 0.18

    -- Container frame (holds header + content)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetWidth(width)
    container:SetHeight(startOpen and (HEADER_H + contentHeight) or HEADER_H)

    if opts.anchorTo then
        container:SetPoint("TOPLEFT", opts.anchorTo, "BOTTOMLEFT", 0, opts.offsetY or -8)
    end

    -- Header button
    local header = CreateFrame("Button", nil, container, "BackdropTemplate")
    header:SetSize(width, HEADER_H)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    self:ApplyBackdrop(header, "header")

    -- Arrow indicator
    local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetFont(self.FONT_BODY, self.SIZE_BODY, "OUTLINE")
    arrow:SetPoint("LEFT", header, "LEFT", 8, 0)
    arrow:SetTextColor(unpack(self.CLR_TEXT_SECONDARY))

    -- Title text
    local titleF = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleF:SetFont(self.FONT_HEADER, self.SIZE_H3, "OUTLINE")
    titleF:SetText(title)
    titleF:SetTextColor(unpack(self.CLR_TEXT_PRIMARY))
    titleF:SetPoint("LEFT", arrow, "RIGHT", 6, 0)

    -- Content area
    local content = CreateFrame("Frame", nil, container, "BackdropTemplate")
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
    content:SetSize(width, contentHeight)
    self:ApplyBackdrop(content, "card")

    -- State
    local section = {
        frame     = container,
        header    = header,
        content   = content,
        titleF    = titleF,
        arrow     = arrow,
        collapsed = not startOpen,
        contentHeight = contentHeight,
    }

    local function UpdateVisual()
        if section.collapsed then
            arrow:SetText("\226\150\182")  -- ▶ right-pointing triangle
            content:Hide()
            container:SetHeight(HEADER_H)
        else
            arrow:SetText("\226\150\188")  -- ▼ down-pointing triangle
            content:Show()
            container:SetHeight(HEADER_H + section.contentHeight)
        end
    end

    function section:SetCollapsed(collapsed)
        self.collapsed = collapsed
        UpdateVisual()
    end

    function section:GetCollapsed()
        return self.collapsed
    end

    function section:SetContentHeight(h)
        self.contentHeight = h
        content:SetHeight(h)
        if not self.collapsed then
            container:SetHeight(HEADER_H + h)
        end
    end

    function section:Toggle()
        self.collapsed = not self.collapsed
        if self.collapsed then
            content:Hide()
            M:AnimateHeight(container, HEADER_H, ANIM_DURATION)
        else
            content:Show()
            M:AnimateHeight(container, HEADER_H + self.contentHeight, ANIM_DURATION)
        end
        if self.collapsed then
            arrow:SetText("\226\150\182")
        else
            arrow:SetText("\226\150\188")
        end
    end

    -- Click handler
    header:SetScript("OnClick", function() section:Toggle() end)

    -- Hover highlight
    header:SetScript("OnEnter", function()
        titleF:SetTextColor(unpack(M.CLR_TEXT_ACCENT))
    end)
    header:SetScript("OnLeave", function()
        titleF:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
    end)

    -- Initial state
    UpdateVisual()

    return section
end


-- =============================================================================
-- SECTION 6 — SIDE-DRAWER (QUEST TRACKER INTEGRATION)
-- =============================================================================
-- Anchors the QuestTracker to the right edge of ToonAgeFrame as a slide-out
-- drawer with a toggle arrow button. Eliminates the floating window clutter.
--
-- Architecture:
--   - A drawer frame is created, anchored to the RIGHT edge of ToonAgeFrame.
--   - A toggle button sits on the border between main frame and drawer.
--   - When toggled open, the drawer slides out with AnimateWidth.
--   - QuestTracker renders its content into the drawer's scroll child.
--   - When the main frame is hidden, the drawer hides too.

M.DRAWER_WIDTH    = 280
M.DRAWER_MIN_W    = 0     -- collapsed width
M.DRAWER_ANIM_DUR = 0.25

--- Initialize the side-drawer system. Called once from TA:InitUI() after
--- the main frame exists.
function M:InitDrawer()
    local mainFrame = TA.UI
    if not mainFrame then return end
    if self.drawer then return end  -- already initialized

    -- ── Drawer frame ──────────────────────────────────────────────────
    local drawer = CreateFrame("Frame", "ToonAgeDrawer", mainFrame, "BackdropTemplate")
    drawer:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 0, 0)
    drawer:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMRIGHT", 0, 0)
    drawer:SetWidth(self.DRAWER_WIDTH)
    self:ApplyGlassBackdrop(drawer)
    drawer:SetFrameStrata("HIGH")
    drawer:SetClampedToScreen(true)

    -- Drawer title bar
    local drawerTitle = CreateFrame("Frame", nil, drawer, "BackdropTemplate")
    drawerTitle:SetPoint("TOPLEFT", drawer, "TOPLEFT", 0, 0)
    drawerTitle:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", 0, 0)
    drawerTitle:SetHeight(28)
    self:ApplyBackdrop(drawerTitle, "header")

    local drawerLabel = drawerTitle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    drawerLabel:SetFont(self.FONT_HEADER, self.SIZE_H3, "OUTLINE")
    drawerLabel:SetText("Guide Tracker")
    drawerLabel:SetTextColor(unpack(self.CLR_TEXT_PRIMARY))
    drawerLabel:SetPoint("LEFT", drawerTitle, "LEFT", 10, 0)

    -- Arrow toggle button (top-right of drawer title bar)
    local arrowBtn = CreateFrame("Button", nil, drawerTitle, "BackdropTemplate")
    arrowBtn:SetSize(54, 20)
    arrowBtn:SetPoint("RIGHT", drawerTitle, "RIGHT", -6, 0)
    self:ApplyBackdrop(arrowBtn, "card")

    local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrowLbl:SetFont(self.FONT_BODY, self.SIZE_CAPTION, "OUTLINE")
    arrowLbl:SetAllPoints(arrowBtn)
    arrowLbl:SetJustifyH("CENTER")
    arrowLbl:SetJustifyV("MIDDLE")
    arrowLbl:SetTextColor(unpack(self.CLR_TEXT_ACCENT))
    arrowLbl:SetText("Show \226\134\145")

    local function UpdateArrowBtnLabel()
        local Arrow = TA:GetModule("Arrow")
        if Arrow and Arrow.frame and Arrow.frame:IsVisible() then
            arrowLbl:SetText("Hide \226\134\145")
        else
            arrowLbl:SetText("Show \226\134\145")
        end
    end

    arrowBtn:SetScript("OnClick", function()
        local Arrow = TA:GetModule("Arrow")
        if Arrow and Arrow.Toggle then
            Arrow:Toggle()
        end
        UpdateArrowBtnLabel()
    end)
    arrowBtn:SetScript("OnEnter", function(f)
        arrowLbl:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(f, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Toggle Arrow", 1, 0.82, 0)
        GameTooltip:AddLine("Show/hide the HUD navigation arrow", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    arrowBtn:SetScript("OnLeave", function()
        arrowLbl:SetTextColor(unpack(M.CLR_TEXT_ACCENT))
        GameTooltip:Hide()
    end)

    -- Update label on show (in case arrow state changed while drawer was closed)
    drawer:HookScript("OnShow", function() UpdateArrowBtnLabel() end)
    C_Timer.After(0.1, UpdateArrowBtnLabel)

    -- Drawer scroll area (QuestTracker renders here)
    local drawerScroll = CreateFrame("ScrollFrame", "TADrawerScrollFrame", drawer, "UIPanelScrollFrameTemplate")
    drawerScroll:SetPoint("TOPLEFT", drawerTitle, "BOTTOMLEFT", 4, -4)
    drawerScroll:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -20, 4)

    local drawerChild = CreateFrame("Frame", nil, drawerScroll)
    drawerChild:SetSize(self.DRAWER_WIDTH - 28, 400)
    drawerScroll:SetScrollChild(drawerChild)

    -- ── Toggle button (sits on the border) ────────────────────────────
    local toggle = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
    toggle:SetSize(18, 48)
    toggle:SetPoint("RIGHT", mainFrame, "RIGHT", 18, 0)
    toggle:SetFrameStrata("HIGH")
    toggle:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
    self:ApplyBackdrop(toggle, "header")

    local toggleArrow = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggleArrow:SetFont(self.FONT_BODY, 14, "OUTLINE")
    toggleArrow:SetAllPoints(toggle)
    toggleArrow:SetJustifyH("CENTER")
    toggleArrow:SetJustifyV("MIDDLE")
    toggleArrow:SetTextColor(unpack(self.CLR_TEXT_SECONDARY))

    -- State
    local isOpen = true

    local function UpdateToggleArrow()
        if isOpen then
            toggleArrow:SetText("\194\187")  -- » (close/collapse)
        else
            toggleArrow:SetText("\194\171")  -- « (open/expand)
        end
    end

    local function SetDrawerOpen(open)
        isOpen = open
        UpdateToggleArrow()
        if open then
            drawer:Show()
            drawer:SetAlpha(0)
            self:AnimateWidth(drawer, self.DRAWER_WIDTH, self.DRAWER_ANIM_DUR)
            self:AnimateAlpha(drawer, 1.0, self.DRAWER_ANIM_DUR)
        else
            self:AnimateWidth(drawer, self.DRAWER_MIN_W, self.DRAWER_ANIM_DUR, function()
                drawer:Hide()
            end)
            self:AnimateAlpha(drawer, 0, self.DRAWER_ANIM_DUR * 0.8)
        end

        -- Persist state
        if TA.db then
            TA.db.drawerOpen = open
        end
    end

    toggle:SetScript("OnClick", function()
        SetDrawerOpen(not isOpen)
    end)
    toggle:SetScript("OnEnter", function()
        toggleArrow:SetTextColor(unpack(M.CLR_TEXT_ACCENT))
    end)
    toggle:SetScript("OnLeave", function()
        toggleArrow:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
    end)

    -- Restore state from DB
    local savedOpen = TA.db and TA.db.drawerOpen
    if savedOpen == nil then savedOpen = true end
    isOpen = savedOpen
    UpdateToggleArrow()
    if not isOpen then
        drawer:SetWidth(self.DRAWER_MIN_W)
        drawer:Hide()
    end

    -- Hide drawer when main frame hides
    mainFrame:HookScript("OnHide", function()
        drawer:Hide()
    end)
    mainFrame:HookScript("OnShow", function()
        if isOpen and not TA._drawerSuppressed then
            drawer:Show()
            drawer:SetWidth(M.DRAWER_WIDTH)
            drawer:SetAlpha(1)
        end
    end)

    -- Store references
    self.drawer       = drawer
    self.drawerScroll = drawerScroll
    self.drawerChild  = drawerChild
    self.drawerToggle = toggle
    self.SetDrawerOpen = SetDrawerOpen

    -- ── Activate QuestTracker drawer mode ─────────────────────────────
    -- QT:Init() runs before InitDrawer (modules init before UI), so the
    -- drawer-mode activation must happen here, after the drawer exists.
    if TA.db and TA.db.useUnifiedUI then
        local QT = TA:GetModule("QuestTracker")
        if QT and QT.InitDrawerMode then
            QT:InitDrawerMode()
        end
    end

    return drawer
end

--- Get the drawer content frame (for QuestTracker to render into).
--- Returns nil if drawer not initialized or the unified UI is disabled.
function M:GetDrawerContent()
    if not self.drawer then return nil end
    return self.drawerChild
end

--- Rebuild the drawer scroll child (same pattern as content/sidebar rebuild).
function M:RebuildDrawerChild()
    if not self.drawerScroll then return nil end
    local old = self.drawerScroll:GetScrollChild()
    if old then old:Hide(); old:SetParent(nil) end
    local child = CreateFrame("Frame", nil, self.drawerScroll)
    child:SetSize(self.DRAWER_WIDTH - 28, 1)
    self.drawerScroll:SetScrollChild(child)
    self.drawerScroll:SetVerticalScroll(0)
    self.drawerChild = child
    return child
end


-- =============================================================================
-- SECTION 7 — TYPOGRAPHY HELPERS
-- =============================================================================
-- Shorthand functions for creating consistently-styled FontStrings.

--- Create a header FontString (bold, larger).
--- @param parent Frame
--- @param text string
--- @param level number|nil - 1, 2, or 3 (default 2)
--- @return FontString
function M:CreateHeader(parent, text, level)
    level = level or 2
    local size = (level == 1) and self.SIZE_H1
              or (level == 2) and self.SIZE_H2
              or self.SIZE_H3
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self.FONT_HEADER, size, "OUTLINE")
    fs:SetText(text)
    fs:SetTextColor(unpack(self.CLR_TEXT_PRIMARY))
    return fs
end

--- Create a body text FontString (regular weight).
--- @param parent Frame
--- @param text string
--- @return FontString
function M:CreateBody(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self.FONT_BODY, self.SIZE_BODY, "OUTLINE")
    fs:SetText(text or "")
    fs:SetTextColor(unpack(self.CLR_TEXT_PRIMARY))
    return fs
end

--- Create a caption FontString (small, muted).
--- @param parent Frame
--- @param text string
--- @return FontString
function M:CreateCaption(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self.FONT_CAPTION, self.SIZE_CAPTION, "OUTLINE")
    fs:SetText(text or "")
    fs:SetTextColor(unpack(self.CLR_TEXT_SECONDARY))
    return fs
end

--- Create a data/number FontString (monospace-like).
--- @param parent Frame
--- @param text string
--- @return FontString
function M:CreateData(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self.FONT_MONO, self.SIZE_BODY, "OUTLINE")
    fs:SetText(text or "")
    fs:SetTextColor(unpack(self.CLR_TEXT_PRIMARY))
    return fs
end

--- Create a status indicator FontString (colored by status).
--- @param parent Frame
--- @param text string
--- @param status string - "ok", "warning", "danger", "upgrade"
--- @return FontString
function M:CreateStatus(parent, text, status)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self.FONT_BODY, self.SIZE_CAPTION, "OUTLINE")
    fs:SetText(text or "")
    local clr = self.CLR_TEXT_PRIMARY
    if status == "ok"      then clr = self.CLR_TEXT_SUCCESS end
    if status == "warning" then clr = self.CLR_TEXT_WARNING end
    if status == "danger"  then clr = self.CLR_TEXT_DANGER  end
    if status == "upgrade" then clr = self.CLR_TEXT_SUCCESS end
    fs:SetTextColor(unpack(clr))
    return fs
end
