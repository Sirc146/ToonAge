-- ToonAge/Core/UIModern.lua (Classic)
-- Typography, backdrop helpers, animation utilities.
--
-- CORRECTION 2026-08-02: this header previously read "Identical to Retail — all
-- constants and CreateFrame calls work in Cata Classic." That was asserted, not
-- measured, and it is false. The CreateFrame calls here pass no template, so on
-- MoP Classic (50504) the resulting frames have no SetBackdrop method and
-- M.ApplyBackdrop raised "attempt to call a nil value". Retail's UI.lua passes
-- "BackdropTemplate"; this file never did. See Core/UI.lua's EnsureBackdrop.

local TA = ToonAge
TA.Modern = TA.Modern or {}
local M = TA.Modern

-- =============================================================================
-- SECTION 1 — TYPOGRAPHY
-- =============================================================================

M.FONT_HEADER  = "Fonts\\FRIZQT__.TTF"
M.FONT_BODY    = "Fonts\\FRIZQT__.TTF"
M.FONT_CAPTION = "Fonts\\FRIZQT__.TTF"
M.FONT_MONO    = "Fonts\\ARIALN.TTF"

M.SIZE_H1      = 14
M.SIZE_H2      = 12
M.SIZE_H3      = 11
M.SIZE_BODY    = 10
M.SIZE_CAPTION = 9
M.SIZE_TINY    = 8

-- Color palette
M.CLR_TEXT_PRIMARY   = { 0.92, 0.90, 0.87, 1.00 }
M.CLR_TEXT_SECONDARY = { 0.62, 0.59, 0.55, 1.00 }
M.CLR_TEXT_ACCENT    = { 0.40, 0.75, 1.00, 1.00 }
M.CLR_TEXT_SUCCESS   = { 0.30, 0.92, 0.40, 1.00 }
M.CLR_TEXT_WARNING   = { 1.00, 0.65, 0.20, 1.00 }
M.CLR_TEXT_DANGER    = { 1.00, 0.35, 0.30, 1.00 }

-- =============================================================================
-- SECTION 2 — BACKDROP HELPERS
-- =============================================================================

M.BACKDROP_FLAT = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

M.BACKDROP_RAISED = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

--- Apply a flat modern backdrop to a frame.
function M.ApplyBackdrop(frame, opts)
    opts = opts or {}

    -- Core/UI.lua loads first (TOC lines 14, 15) and owns the compat shim, but
    -- fall back to a local existence check rather than assuming load order.
    if TA._EnsureBackdrop then
        if not TA._EnsureBackdrop(frame) then return end
    elseif not frame.SetBackdrop then
        return
    end

    local backdrop = opts.raised and M.BACKDROP_RAISED or M.BACKDROP_FLAT
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(
        opts.bgR or 0.06, opts.bgG or 0.05, opts.bgB or 0.04, opts.bgA or 0.95)
    frame:SetBackdropBorderColor(
        opts.borderR or 0.30, opts.borderG or 0.25, opts.borderB or 0.15, opts.borderA or 0.60)
end

--- Create a section card (rounded-look flat panel)
function M.CreateCard(parent, opts)
    opts = opts or {}
    local card = CreateFrame("Frame", nil, parent)
    M.ApplyBackdrop(card, { bgR = 0.08, bgG = 0.07, bgB = 0.05, bgA = 0.90 })
    return card
end

-- =============================================================================
-- SECTION 3 — FONT HELPERS
-- =============================================================================

--- Create a FontString with modern typography defaults.
function M.CreateLabel(parent, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, opts.layer or "OVERLAY")
    local font = opts.font or M.FONT_BODY
    local size = opts.size or M.SIZE_BODY
    local flags = opts.flags or ""
    fs:SetFont(font, size, flags)

    if opts.color then
        fs:SetTextColor(unpack(opts.color))
    else
        fs:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
    end

    if opts.text then fs:SetText(opts.text) end
    if opts.width then fs:SetWidth(opts.width) end
    if opts.wordWrap ~= false then fs:SetWordWrap(true) end

    return fs
end

--- Create a header label
function M.CreateHeader(parent, text, level)
    level = level or 1
    local size = level == 1 and M.SIZE_H1 or (level == 2 and M.SIZE_H2 or M.SIZE_H3)
    return M.CreateLabel(parent, {
        text = text,
        font = M.FONT_HEADER,
        size = size,
        flags = "OUTLINE",
        color = M.CLR_TEXT_PRIMARY,
    })
end

-- =============================================================================
-- SECTION 4 — PROGRESS BAR
-- =============================================================================

function M.CreateProgressBar(parent, opts)
    opts = opts or {}
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(opts.r or 0.40, opts.g or 0.75, opts.b or 1.00, opts.a or 0.90)
    bar:SetMinMaxValues(0, opts.max or 100)

    -- Background
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.07, 0.05, 0.80)

    -- Border
    M.ApplyBackdrop(bar, { bgR = 0, bgG = 0, bgB = 0, bgA = 0 })

    -- Label
    if opts.label then
        local label = bar:CreateFontString(nil, "OVERLAY")
        label:SetFont(M.FONT_BODY, M.SIZE_CAPTION)
        label:SetPoint("CENTER")
        label:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
        bar.label = label
    end

    return bar
end

-- =============================================================================
-- SECTION 5 — COLLAPSIBLE SECTION
-- =============================================================================

function M.CreateCollapsible(parent, title, opts)
    opts = opts or {}
    local section = CreateFrame("Frame", nil, parent)

    local header = CreateFrame("Button", nil, section)
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)

    local arrow = header:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(M.FONT_BODY, M.SIZE_BODY)
    arrow:SetPoint("LEFT", header, "LEFT", 4, 0)
    arrow:SetText("▼")
    arrow:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))

    local titleFS = header:CreateFontString(nil, "OVERLAY")
    titleFS:SetFont(M.FONT_HEADER, M.SIZE_H3, "OUTLINE")
    titleFS:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
    titleFS:SetText(title)
    titleFS:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))

    local body = CreateFrame("Frame", nil, section)
    body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    body:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -4)

    section.header = header
    section.body   = body
    section.collapsed = opts.collapsed or false

    local function UpdateState()
        if section.collapsed then
            arrow:SetText("►")
            body:Hide()
        else
            arrow:SetText("▼")
            body:Show()
        end
    end

    header:SetScript("OnClick", function()
        section.collapsed = not section.collapsed
        UpdateState()
    end)

    UpdateState()
    return section
end

-- =============================================================================
-- SECTION 6 — ROW LAYOUT HELPER
-- =============================================================================

--- Simple vertical layout: returns the Y offset for the next element.
function M.LayoutRow(parent, yOffset, height, padding)
    padding = padding or 6
    return yOffset - height - padding
end
