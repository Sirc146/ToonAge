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
    -- Main frame gets glass backdrop (applied after M loads via InitDrawer hook)
    ApplyBackdrop(frame, 0.05, 0.05, 0.06, 0.94)
    frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)
    frame:Hide()

    -- ── Title bar ─────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(TITLEBAR_H)
    ApplyBackdrop(titleBar, 0.10, 0.10, 0.12, 1.00)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    titleLabel:SetText("ToonAge")
    titleLabel:SetTextColor(0.92, 0.90, 0.87, 1.00)
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", 34, 0)

    local versionLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    versionLabel:SetText("v" .. TA.version .. "  ·  Midnight 12.0.5")
    versionLabel:SetTextColor(0.55, 0.52, 0.45, 1.00)
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
    optIcon:SetTextColor(0.62, 0.59, 0.55, 1)
    optIcon:SetAllPoints(optionsBtn)
    optIcon:SetJustifyH("CENTER")
    optionsBtn:SetScript("OnEnter", function() optIcon:SetTextColor(0.92, 0.90, 0.87, 1) end)
    optionsBtn:SetScript("OnLeave", function() optIcon:SetTextColor(0.62, 0.59, 0.55, 1) end)
    optionsBtn:SetScript("OnClick", function() TA:ToggleOptionsPanel() end)

    -- ── Tab bar ───────────────────────────────────────────────────────
    local tabBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, -TITLEBAR_H)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -TITLEBAR_H)
    tabBar:SetHeight(TAB_HEIGHT)
    ApplyBackdrop(tabBar, 0.07, 0.07, 0.09, 1.00)

    -- ── Sidebar ───────────────────────────────────────────────────────
    local sidebarTop = -(TITLEBAR_H + TAB_HEIGHT)
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, sidebarTop)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    ApplyBackdrop(sidebar, 0.05, 0.05, 0.06, 0.96)

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

    -- ── SetTab ────────────────────────────────────────────────────────
    -- Defined BEFORE RebuildTabs so RebuildTabs can call self:SetTab()
    -- at the end of its run without getting a nil-value error.
    function frame:SetTab(tabID)
        -- A saved lastTab may point at a tab the player has since disabled
        -- (e.g. from a previous session) -- fall back to the always-on tab.
        if not IsTabEnabled(tabID) then tabID = "character" end

        -- Update tab button states
        for id, btn in pairs(self.tabButtons) do
            local isActive = (id == tabID)
            if isActive then btn.label:SetTextColor(0.92, 0.90, 0.87, 1.00) else btn.label:SetTextColor(0.55, 0.52, 0.48, 1.00) end
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

            -- ── Dynamic panel resizing ────────────────────────────────────
            -- If the sidebar scroll child has no meaningful content (height ≤ 1
            -- means nothing was rendered into it) AND the module didn't parent
            -- persistent frames directly to the sidebar (like 3D models), hide
            -- the sidebar and expand content to consume the full frame width.
            local sideEmpty = (self.sideChild:GetHeight() <= 1)
            -- Check if the module parented persistent frames to the sidebar
            if sideEmpty and tabDef then
                local mod2 = TA:GetModule(tabDef.module)
                if mod2 and mod2.sideFrames and #mod2.sideFrames > 0 then
                    sideEmpty = false
                end
            end
            if sideEmpty then
                self.sidebar:Hide()
                self.contentScroll:ClearAllPoints()
                self.contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     1, sidebarTop)
                self.contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
                -- Update content child width for the wider area
                local fullW = FRAME_WIDTH - 1 - 22
                self.contentChild:SetWidth(fullW)
                self.contentWidth = fullW
            else
                -- Restore standard sidebar + content layout
                self.sidebar:Show()
                self.contentScroll:ClearAllPoints()
                local contentLeft = SIDEBAR_WIDTH + 1
                self.contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, sidebarTop)
                self.contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
                local normalW = FRAME_WIDTH - contentLeft - 22
                self.contentChild:SetWidth(normalW)
                self.contentWidth = normalW
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

    -- ── RebuildTabs — callable at any time (e.g. from options panel) ──
    -- Destroys all existing tab buttons and recreates them from the current
    -- disabledTabs state, then re-selects the active tab (or "character"
    -- if it was disabled). Called once at init, then again any time the
    -- player toggles a tab in the options panel.
    -- NOTE: SetTab, Refresh, and Show must be defined above this function
    -- because RebuildTabs calls self:SetTab() at the end of its run.
    function frame:RebuildTabs()
        -- Destroy existing tab buttons
        for _, btn in pairs(self.tabButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        self.tabButtons = {}

        local tabX = 8
        for _, tabDef in ipairs(TABS) do
            if IsTabEnabled(tabDef.id) then
                local btn = CreateFrame("Button", nil, tabBar)
                btn:SetHeight(TAB_HEIGHT - 2)
                btn:SetPoint("LEFT", tabBar, "LEFT", tabX, 1)

                local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                lbl:SetText(tabDef.label)
                lbl:SetTextColor(0.55, 0.52, 0.48, 1.00)
                lbl:SetAllPoints(btn)
                lbl:SetJustifyH("CENTER")
                btn.label = lbl

                -- Subtle underline for active tab (white instead of gold)
                local line = btn:CreateTexture(nil, "OVERLAY")
                line:SetHeight(2)
                line:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
                line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
                line:SetColorTexture(0.40, 0.75, 1.00, 1.00)
                line:Hide()
                btn.activeLine = line

                btn.tabID  = tabDef.id
                btn.module = tabDef.module

                lbl:SetWidth(0)
                btn:SetWidth(lbl:GetStringWidth() + 26)
                tabX = tabX + btn:GetWidth() + 2

                btn:SetScript("OnClick", function()
                    frame:SetTab(tabDef.id)
                end)
                btn:SetScript("OnEnter", function()
                    if frame.activeTab ~= tabDef.id then
                        lbl:SetTextColor(0.92, 0.90, 0.87, 1.00)
                    end
                end)
                btn:SetScript("OnLeave", function()
                    if frame.activeTab ~= tabDef.id then
                        lbl:SetTextColor(0.55, 0.52, 0.48, 1.00)
                    end
                end)

                self.tabButtons[tabDef.id] = btn
            end
        end

        -- Re-select the previously active tab, falling back to "character"
        -- if it was just disabled.
        local tabToShow = self.activeTab or "character"
        if not IsTabEnabled(tabToShow) then tabToShow = "character" end
        self:SetTab(tabToShow)
    end

    -- Initial tab build — all frame methods are now defined above this call.
    frame:RebuildTabs()

    self.UI = frame

    -- ── Blizzard Settings registration ───────────────────────────────────────
    -- Done here (inside InitUI, called from OnLogin after PLAYER_ENTERING_WORLD)
    -- so Settings and all Blizzard addon APIs are guaranteed available.
    -- A pcall guard ensures any API hiccup on future PTR builds cannot prevent
    -- the rest of ToonAge from loading.
    if not self._blizzOptionsPanel then
        local ok, err = pcall(function()
            local blizzPanel = CreateFrame("Frame")
            blizzPanel.name  = "ToonAge"
            if Settings and Settings.RegisterCanvasLayoutCategory then
                local cat = Settings.RegisterCanvasLayoutCategory(blizzPanel, blizzPanel.name)
                Settings.RegisterAddOnCategory(cat)
                TA._blizzOptionsPanel = blizzPanel
            elseif InterfaceOptions_AddCategory then
                InterfaceOptions_AddCategory(blizzPanel)
                TA._blizzOptionsPanel = blizzPanel
            end
        end)
        if not ok and TA.debug then
            print("|cFFFFD100[TA]|r Blizzard Settings registration failed: " .. tostring(err))
        end
    end

    -- ── Initialize the modern side-drawer ─────────────────────────────────────
    -- The drawer anchors to the right edge of the main frame and hosts the
    -- QuestTracker content inline (eliminating the separate floating window).
    -- Also applies the glass backdrop to the main frame now that M is loaded.
    if TA.Modern and TA.Modern.InitDrawer then
        pcall(function()
            TA.Modern:ApplyGlassBackdrop(frame)
            TA.Modern:InitDrawer()
        end)
    end
end

-- ── Options panel — toggle which tabs are shown ────────────────────────
-- Changes take effect immediately: the checkbox OnClick handler calls
-- frame:RebuildTabs() so the tab bar is updated without a /reload.
function TA:OpenOptionsFrame()
    if self.optionsFrame then
        self.optionsFrame:Show()
        return
    end

    -- Height: header (20) + layout section (48) + divider gap (16)
    --         + (numTabs-1) * 24 + footer (28)
    local numTabRows = #TABS - 1  -- "character" tab is always-on, not listed
    local of = CreateFrame("Frame", "ToonAgeOptionsFrame", UIParent, "BackdropTemplate")
    of:SetSize(300, 116 + numTabRows * 24)
    of:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    ApplyBackdrop(of, 0.05, 0.05, 0.06, 0.94)
    of:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)
    -- Apply glass backdrop if Modern is available
    if TA.Modern and TA.Modern.ApplyGlassBackdrop then
        TA.Modern:ApplyGlassBackdrop(of)
    end
    of:SetFrameStrata("DIALOG")
    of:SetMovable(true)
    of:EnableMouse(true)
    of:RegisterForDrag("LeftButton")
    of:SetScript("OnDragStart", of.StartMoving)
    of:SetScript("OnDragStop", of.StopMovingOrSizing)

    local hdr = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    hdr:SetText("|cFFFFD100ToonAge Options|r")
    hdr:SetPoint("TOPLEFT", of, "TOPLEFT", 12, -10)

    -- ── UI Layout Toggle ──────────────────────────────────────────────
    local layoutHdr = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layoutHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    layoutHdr:SetText("HUD LAYOUT")
    layoutHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    layoutHdr:SetPoint("TOPLEFT", of, "TOPLEFT", 12, -30)

    local layoutCb = CreateFrame("CheckButton", nil, of, "UICheckButtonTemplate")
    layoutCb:SetSize(20, 20)
    layoutCb:SetPoint("TOPLEFT", of, "TOPLEFT", 10, -46)
    layoutCb:SetChecked(TA.db and TA.db.useUnifiedUI ~= false)

    local layoutLbl = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layoutLbl:SetFont(STANDARD_TEXT_FONT, 11, "")
    layoutLbl:SetText("Use Unified Single-Frame HUD Layout")
    layoutLbl:SetTextColor(0.78, 0.73, 0.48, 1)
    layoutLbl:SetPoint("LEFT", layoutCb, "RIGHT", 2, 0)

    local layoutNote = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layoutNote:SetFont(STANDARD_TEXT_FONT, 9, "")
    layoutNote:SetText("  Unchecked = classic independent windows")
    layoutNote:SetTextColor(0.50, 0.47, 0.36, 1)
    layoutNote:SetPoint("TOPLEFT", layoutCb, "BOTTOMLEFT", 22, 2)

    -- OnShow: sync checkbox to current DB value each time the panel opens
    of:SetScript("OnShow", function()
        layoutCb:SetChecked(TA.db and TA.db.useUnifiedUI ~= false)
    end)

    layoutCb:SetScript("OnClick", function(self)
        TA.db.useUnifiedUI = self:GetChecked()
        TA:ApplyLayout()
        local mode = TA.db.useUnifiedUI and "Unified HUD" or "Fragmented Windows"
        print("|cFFFFD100[ToonAge]|r Layout switched to: " .. mode)
    end)

    -- ── Divider ───────────────────────────────────────────────────────
    local divider = of:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.55, 0.40, 0.08, 0.40)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  of, "TOPLEFT",  10, -76)
    divider:SetPoint("TOPRIGHT", of, "TOPRIGHT", -10, -76)

    -- ── Tab Visibility ────────────────────────────────────────────────
    local tabsHdr = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabsHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    tabsHdr:SetText("VISIBLE TABS")
    tabsHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    tabsHdr:SetPoint("TOPLEFT", of, "TOPLEFT", 12, -84)

    local y = -100
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
                -- Apply immediately — no /reload required.
                if TA.UI and TA.UI.RebuildTabs then
                    TA.UI:RebuildTabs()
                end
            end)

            y = y - 24
        end
    end

    local note = of:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    note:SetFont(STANDARD_TEXT_FONT, 9)
    note:SetText("|cFF4AFF7AAll changes apply immediately.|r")
    note:SetPoint("BOTTOMLEFT", of, "BOTTOMLEFT", 12, 10)

    local closeBtn = CreateFrame("Button", nil, of, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", of, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() of:Hide() end)

    self.optionsFrame = of
    of:Show()
end

-- ── ApplyLayout ───────────────────────────────────────────────────────────────
-- Switches between Unified HUD and Fragmented (independent windows) layouts.
-- Called on login (after all module Init()s) and whenever the player toggles
-- the setting via the options panel or the minimap button right-click.
--
-- Frame references:
--   Arrow.lua   exposes its frame as  TA:GetModule("Arrow").frame
--   QuestTracker exposes its window as TA:GetModule("QuestTracker").window
-- We use these rather than globals so the function works regardless of naming.

function TA:ApplyLayout()
    local db = self.db
    if not db then return end   -- called before InitDB? shouldn't happen, guard anyway

    local Arrow  = self:GetModule("Arrow")
    local QT     = self:GetModule("QuestTracker")
    local arrowF = Arrow  and Arrow.frame
    local guideF = QT     and QT.window

    if db.useUnifiedUI then
        -- ── UNIFIED HUD ────────────────────────────────────────────────────────
        -- The main ToonAge tab panel (self.UI / ToonAgeFrame) already serves as
        -- a persistent, draggable master frame.  We park the arrow and guide
        -- tracker next to it rather than inside it (they have their own strata
        -- and scroll-child logic that breaks when re-parented mid-session).
        --
        -- "Unified" in practice means: restore saved unified positions so the
        -- three pieces snap to a coherent cluster rather than wherever the player
        -- last scattered them.

        if arrowF then
            arrowF:ClearAllPoints()
            local pos = db.unifiedPosition
            -- Arrow sits just to the left of the main frame's default anchor
            arrowF:SetPoint(pos.point, UIParent, pos.relativePoint,
                pos.x - 50, pos.y + 10)
            -- Restore normal interactive drag in unified mode
            arrowF:RegisterForDrag("LeftButton")
        end

        if guideF then
            guideF:ClearAllPoints()
            local pos = db.unifiedPosition
            -- Guide tracker sits just to the right of the unified anchor
            guideF:SetPoint(pos.point, UIParent, pos.relativePoint,
                pos.x + 10, pos.y + 10)
        end

        if self.UI and not self.UI:IsVisible() then
            -- Don't force the tab panel open; just ensure it's un-hidden if it
            -- was hidden by the old-layout hide path below.
            -- The player still opens it manually via /ta or the minimap click.
        end

    else
        -- ── FRAGMENTED (OLD) LAYOUT ────────────────────────────────────────────
        -- Restore each window to its individually-saved position.

        if arrowF then
            arrowF:ClearAllPoints()
            local pos = db.oldUiPositions.arrow
            arrowF:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            arrowF:RegisterForDrag("LeftButton")
        end

        if guideF then
            guideF:ClearAllPoints()
            local pos = db.oldUiPositions.guide
            guideF:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end
    end

    -- After repositioning: ensure tracker is populated and visible if a guide is active
    if QT then
        if QT.guideID and guideF then
            guideF:Show()
            QT:UpdateWindow()
        end
    end
end

-- ── ToggleOptionsPanel ────────────────────────────────────────────────────────
-- Opens ToonAge's settings in the Blizzard Settings window (Patch 10.0+).
-- Falls back to the legacy InterfaceOptionsFrame path and, as a final fallback,
-- opens the in-addon options panel directly (so the gear button always works).

function TA:ToggleOptionsPanel()
    -- On 12.0.x PTR, Settings.OpenToCategory expects a numeric category ID
    -- (not a string name). Open a settings drawer below the main frame instead.
    self:ToggleSettingsDrawer()
end

-- ── Settings Drawer ───────────────────────────────────────────────────────────
-- A panel that slides down from the bottom of the main ToonAge frame.
-- Keeps settings separate from the playable tabs.

function TA:ToggleSettingsDrawer()
    local mainFrame = self.UI

    -- Create drawer on first use
    if not self._settingsDrawer then
        local drawer = CreateFrame("Frame", "TASettingsDrawer", UIParent, "BackdropTemplate")
        drawer:SetSize(FRAME_WIDTH, 400)
        drawer:SetFrameStrata("DIALOG")
        drawer:SetMovable(true)
        drawer:EnableMouse(true)
        drawer:RegisterForDrag("LeftButton")
        drawer:SetScript("OnDragStart", drawer.StartMoving)
        drawer:SetScript("OnDragStop", drawer.StopMovingOrSizing)
        drawer:SetClampedToScreen(true)
        ApplyBackdrop(drawer, 0.04, 0.04, 0.05, 0.97)
        drawer:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.8)
        drawer:Hide()

        -- Title bar
        local titleLbl = drawer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        titleLbl:SetText("|cFFFFD100ToonAge Settings|r")
        titleLbl:SetPoint("TOPLEFT", drawer, "TOPLEFT", 10, -8)

        local closeBtn = CreateFrame("Button", nil, drawer, "UIPanelCloseButton")
        closeBtn:SetSize(22, 22)
        closeBtn:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -2, -2)

        -- Scroll frame inside drawer
        local scroll = CreateFrame("ScrollFrame", "TASettingsDrawerScroll", drawer, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", drawer, "TOPLEFT", 4, -26)
        scroll:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -26, 4)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(FRAME_WIDTH - 30)
        content:SetHeight(1)
        scroll:SetScrollChild(content)

        -- Dummy sidebar (Settings module expects one)
        local sidebar = CreateFrame("Frame", nil, drawer)
        sidebar:SetSize(1, 1)
        sidebar:Hide()

        drawer.scroll  = scroll
        drawer.content = content
        drawer.sidebar = sidebar
        self._settingsDrawer = drawer
    end

    local drawer = self._settingsDrawer

    if drawer:IsShown() then
        drawer:Hide()
        return
    end

    -- Position: below main frame if visible, otherwise center of screen
    drawer:ClearAllPoints()
    if mainFrame and mainFrame:IsVisible() then
        drawer:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 0, -2)
    else
        drawer:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    end

    -- Rebuild content each time (settings may have changed)
    local old = drawer.scroll:GetScrollChild()
    if old then old:Hide(); old:SetParent(nil) end

    local content = CreateFrame("Frame", nil, drawer.scroll)
    content:SetWidth(FRAME_WIDTH - 30)
    content:SetHeight(1)
    drawer.scroll:SetScrollChild(content)
    drawer.scroll:SetVerticalScroll(0)
    drawer.content = content

    -- Render settings into the drawer
    local Settings = self:GetModule("Settings")
    if Settings and Settings.Render then
        Settings:Render(content, drawer.sidebar)
    end

    drawer:Show()
end

-- ── Blizzard Settings registration ───────────────────────────────────────────
-- Registered lazily inside InitUI() (called from OnLogin after PLAYER_ENTERING_WORLD)
-- so Blizzard's Settings API is guaranteed to be loaded.  Doing this at file-load
-- time risks the Settings global not existing yet and aborting the rest of the file.
