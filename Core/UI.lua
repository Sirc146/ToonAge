-- ToonAge/Core/UI.lua
-- Main frame, tab bar, sidebar, WoW-native styling

local TA = ToonAge
local U  = TA.Utils

-- ── Constants ─────────────────────────────────────────────────────────
local FRAME_WIDTH   = 900
local FRAME_HEIGHT  = 580
local SIDEBAR_WIDTH = 210
local TAB_HEIGHT    = 30
local TITLEBAR_H    = 34
local CONTENT_PAD   = 14   -- internal padding for content area
local ROW_PAD       = 6    -- extra vertical space between rows

-- Ordered for flow: your build (Character/Gear/Talents/Rotation), then
-- what to do with it (Delves/Weekly), then side systems (Professions/Pets).
local TABS = {
    { id = "character",   label = "Character",   module = "Character"   },
    { id = "gear",        label = "Gear",        module = "Gear"        },
    { id = "talents",     label = "Talents",     module = "Talents"     },
    { id = "rotation",    label = "Rotation",    module = "Rotation"    },
    { id = "delves",      label = "Delves",      module = "Delves"      },
    { id = "weekly",      label = "Weekly",      module = "Weekly"      },
    { id = "professions", label = "Professions", module = "Professions" },
    { id = "pets",        label = "Pets",        module = "Pets"        },
}

-- Colours defined inline as literals (unpack on colour tables is unreliable in WoW Lua 5.1)

-- ── Backdrop helper ───────────────────────────────────────────────────
local FLAT_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function ApplyBackdrop(frame, br, bg, bb, ba, er, eg, eb, ea)
    frame:SetBackdrop(FLAT_BACKDROP)
    frame:SetBackdropColor(br or 0.05, bg or 0.04, bb or 0.02, ba or 0.98)
    frame:SetBackdropBorderColor(er or 0.55, eg or 0.40, eb or 0.08, ea or 0.70)
end

-- ── Clean a frame's content completely ───────────────────────────────
-- WoW's GetChildren() only returns Frame objects, not FontStrings or
-- Textures. To truly clear a content pane we destroy and recreate it.
local function RebuildChild(scrollFrame, width)
    local old = scrollFrame:GetScrollChild()
    if old then
        old:Hide()
        old:SetParent(nil)
    end
    local child = CreateFrame("Frame", nil, scrollFrame)
    child:SetSize(width, 1)
    scrollFrame:SetScrollChild(child)
    scrollFrame:SetVerticalScroll(0)
    return child
end

-- ── Main UI initialisation ────────────────────────────────────────────
-- Tabs a player can hide via the options panel. "character" is always
-- shown -- it's the anchor tab and disabling everything would leave an
-- empty window.
local function IsTabEnabled(tabID)
    if tabID == "character" then return true end
    return not (TA.db and TA.db.disabledTabs and TA.db.disabledTabs[tabID])
end

function TA:InitUI()
    if self.UI then return end
    self.db.disabledTabs = self.db.disabledTabs or {}

    -- ── Outer frame ───────────────────────────────────────────────────
    local frame = CreateFrame("Frame", "ToonAgeFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    ApplyBackdrop(frame, 0.05, 0.04, 0.02, 0.98)
    frame:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.70)
    frame:Hide()

    -- ── Title bar ─────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(TITLEBAR_H)
    ApplyBackdrop(titleBar, 0.16, 0.12, 0.00, 1.00)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    titleLabel:SetText("ToonAge")
    titleLabel:SetTextColor(1.00, 0.82, 0.00, 1.00)
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", 34, 0)

    local versionLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    versionLabel:SetText("v" .. TA.version .. "  ·  Midnight 12.0.5")
    versionLabel:SetTextColor(0.55, 0.44, 0.25, 1.00)
    versionLabel:SetPoint("RIGHT", titleBar, "RIGHT", -36, 0)

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local optionsBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    optionsBtn:SetSize(20, 20)
    optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    local optIcon = optionsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optIcon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    optIcon:SetText("\226\154\153")  -- gear glyph
    optIcon:SetTextColor(0.55, 0.40, 0.08, 1)
    optIcon:SetAllPoints(optionsBtn)
    optIcon:SetJustifyH("CENTER")
    optionsBtn:SetScript("OnEnter", function() optIcon:SetTextColor(1, 0.82, 0, 1) end)
    optionsBtn:SetScript("OnLeave", function() optIcon:SetTextColor(0.55, 0.40, 0.08, 1) end)
    optionsBtn:SetScript("OnClick", function() TA:OpenOptionsFrame() end)

    -- ── Tab bar ───────────────────────────────────────────────────────
    local tabBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, -TITLEBAR_H)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -TITLEBAR_H)
    tabBar:SetHeight(TAB_HEIGHT)
    ApplyBackdrop(tabBar, 0.06, 0.05, 0.01, 1.00)

    -- ── Sidebar ───────────────────────────────────────────────────────
    local sidebarTop = -(TITLEBAR_H + TAB_HEIGHT)
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, sidebarTop)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    ApplyBackdrop(sidebar, 0.04, 0.03, 0.01, 1.00)

    local sideScroll = CreateFrame("ScrollFrame", "TASideScrollFrame", sidebar, "UIPanelScrollFrameTemplate")
    sideScroll:SetPoint("TOPLEFT",     sidebar, "TOPLEFT",     4, -4)
    sideScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -22, 4)

    local sideChild = CreateFrame("Frame", nil, sideScroll)
    sideChild:SetSize(SIDEBAR_WIDTH - 26, 400)
    sideScroll:SetScrollChild(sideChild)

    -- ── Content scroll area ───────────────────────────────────────────
    -- Positioned to the RIGHT of the sidebar, leaving a 1px gap for the border
    local contentLeft = SIDEBAR_WIDTH + 1
    local contentWidth = FRAME_WIDTH - contentLeft - 22  -- 22 = scrollbar width

    local contentScroll = CreateFrame("ScrollFrame", "TAContentScrollFrame", frame, "UIPanelScrollFrameTemplate")
    contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, sidebarTop)
    contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)

    local contentChild = CreateFrame("Frame", nil, contentScroll)
    contentChild:SetSize(contentWidth, 400)
    contentScroll:SetScrollChild(contentChild)

    -- ── Store references ──────────────────────────────────────────────
    frame.tabBar       = tabBar
    frame.sidebar      = sidebar
    frame.sideScroll   = sideScroll
    frame.contentScroll = contentScroll
    frame.contentWidth = contentWidth
    frame.sideWidth    = SIDEBAR_WIDTH - 26
    frame.tabButtons   = {}
    frame.activeTab    = nil
    -- Keep live references (rebuilt on each tab switch)
    frame.sideChild    = sideChild
    frame.contentChild = contentChild

    -- ── Build tab buttons ─────────────────────────────────────────────
    local tabX = 8
    for _, tabDef in ipairs(TABS) do
      if IsTabEnabled(tabDef.id) then
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetHeight(TAB_HEIGHT - 2)
        btn:SetPoint("LEFT", tabBar, "LEFT", tabX, 1)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        lbl:SetText(tabDef.label)
        lbl:SetTextColor(0.55, 0.40, 0.08, 1.00)
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        btn.label = lbl

        -- Gold underline for active tab
        local line = btn:CreateTexture(nil, "OVERLAY")
        line:SetHeight(2)
        line:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
        line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        line:SetColorTexture(1.00, 0.82, 0.00, 1.00)
        line:Hide()
        btn.activeLine = line

        btn.tabID  = tabDef.id
        btn.module = tabDef.module

        -- Size button to text width
        lbl:SetWidth(0)
        btn:SetWidth(lbl:GetStringWidth() + 26)
        tabX = tabX + btn:GetWidth() + 2

        btn:SetScript("OnClick", function()
            frame:SetTab(tabDef.id)
        end)
        btn:SetScript("OnEnter", function()
            if frame.activeTab ~= tabDef.id then
                lbl:SetTextColor(1.00, 0.82, 0.00, 1.00)
            end
        end)
        btn:SetScript("OnLeave", function()
            if frame.activeTab ~= tabDef.id then
                lbl:SetTextColor(0.55, 0.40, 0.08, 1.00)
            end
        end)

        frame.tabButtons[tabDef.id] = btn
      end
    end

    -- ── SetTab ────────────────────────────────────────────────────────
    function frame:SetTab(tabID)
        -- A saved lastTab may point at a tab the player has since disabled
        -- (e.g. from a previous session) -- fall back to the always-on tab.
        if not IsTabEnabled(tabID) then tabID = "character" end

        -- Update tab button states
        for id, btn in pairs(self.tabButtons) do
            local isActive = (id == tabID)
            if isActive then btn.label:SetTextColor(1.00, 0.82, 0.00, 1.00) else btn.label:SetTextColor(0.55, 0.40, 0.08, 1.00) end
            if isActive then btn.activeLine:Show() else btn.activeLine:Hide() end
        end
        self.activeTab = tabID
        TA.charDB.lastTab  = tabID

        -- Clean up persistent sidebar frames from all modules before switching.
        -- Modules may parent frames to TA.UI.sidebar (persistent) instead of
        -- sideChild (rebuilt below). Without this step those frames bleed into
        -- the next tab's sidebar.
        for _, mod in pairs(TA.modules) do
            if mod.sideFrames then
                for _, f in ipairs(mod.sideFrames) do
                    f:Hide()
                    f:SetParent(nil)
                end
                mod.sideFrames  = {}
                mod.lastContent = nil  -- force full sidebar rebuild on next render
            end
        end

        -- Rebuild content panes fresh — this is the key fix.
        -- Destroying and recreating avoids FontString/Texture bleed-through
        -- that GetChildren() misses.
        self.contentChild = RebuildChild(self.contentScroll, self.contentWidth)
        self.sideChild    = RebuildChild(self.sideScroll,    self.sideWidth)

        -- Ask the module to render into the fresh panes
        local tabDef
        for _, t in ipairs(TABS) do
            if t.id == tabID then tabDef = t; break end
        end
        if tabDef then
            local mod = TA:GetModule(tabDef.module)
            if mod and mod.Render then
                local ok, err = pcall(mod.Render, mod, self.contentChild, self.sideChild)
                if not ok then
                    -- Surface errors in the content pane instead of silently failing
                    local errF = self.contentChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    errF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
                    errF:SetText("|cFFFF4444Error rendering " .. tabID .. " tab:|r\n" .. tostring(err))
                    errF:SetPoint("TOPLEFT", self.contentChild, "TOPLEFT", 14, -14)
                    errF:SetWidth(self.contentWidth - 28)
                    errF:SetWordWrap(true)
                    errF:SetJustifyH("LEFT")
                    self.contentChild:SetHeight(200)
                end
            end
        end
    end

    -- ── Refresh on events ─────────────────────────────────────────────
    function frame:Refresh(event)
        if self.activeTab then
            self:SetTab(self.activeTab)
        end
    end

    -- ── Show: open to last tab ────────────────────────────────────────
    local origShow = frame.Show
    function frame:Show()
        origShow(self)
        self:SetTab(TA.charDB.lastTab or "character")
    end

    self.UI = frame
end

-- ── Options panel — toggle which tabs are shown ────────────────────────
-- Takes effect after /reload (the tab bar is only built once at InitUI).
function TA:OpenOptionsFrame()
    if self.optionsFrame then
        self.optionsFrame:Show()
        return
    end

    local of = CreateFrame("Frame", "ToonAgeOptionsFrame", UIParent, "BackdropTemplate")
    of:SetSize(280, 60 + (#TABS - 1) * 24)
    of:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    ApplyBackdrop(of, 0.05, 0.04, 0.02, 0.98)
    of:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.80)
    of:SetFrameStrata("DIALOG")
    of:SetMovable(true)
    of:EnableMouse(true)
    of:RegisterForDrag("LeftButton")
    of:SetScript("OnDragStart", of.StartMoving)
    of:SetScript("OnDragStop", of.StopMovingOrSizing)

    local hdr = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    hdr:SetText("|cFFFFD100Visible Tabs|r")
    hdr:SetPoint("TOPLEFT", of, "TOPLEFT", 12, -10)

    local y = -30
    for _, tabDef in ipairs(TABS) do
        if tabDef.id ~= "character" then
            local cb = CreateFrame("CheckButton", nil, of, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", of, "TOPLEFT", 10, y)
            cb:SetChecked(IsTabEnabled(tabDef.id))

            local lbl = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont(STANDARD_TEXT_FONT, 11, "")
            lbl:SetText(tabDef.label)
            lbl:SetTextColor(0.78, 0.73, 0.48, 1)
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)

            cb:SetScript("OnClick", function(self)
                TA.db.disabledTabs = TA.db.disabledTabs or {}
                TA.db.disabledTabs[tabDef.id] = not self:GetChecked() or nil
            end)

            y = y - 24
        end
    end

    local note = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    note:SetFont(STANDARD_TEXT_FONT, 9)
    note:SetText("|cFF888780Changes apply after /reload.|r")
    note:SetPoint("BOTTOMLEFT", of, "BOTTOMLEFT", 12, 10)

    local closeBtn = CreateFrame("Button", nil, of, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", of, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() of:Hide() end)

    self.optionsFrame = of
    of:Show()
end
