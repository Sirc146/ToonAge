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
local DEFAULT_TABS = {
    { id = "character",   label = "Character",   module = "Character"   },
    { id = "guide",       label = "Guide",       module = "QuestTracker" },
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
-- Frame recycler pool (file-scope, persists across tab switches)
local _framePool = { content = {}, side = {} }

local function RebuildChild(scrollFrame, width)
    -- Frame recycler pool: prevents memory inflation from creating new frames
    -- on every tab switch. WoW's C-engine does NOT release unparented widget
    -- memory — so we reuse frames instead of abandoning them.
    -- Pool is defined at file scope (persists across calls).
    local old = scrollFrame:GetScrollChild()
    if old then
        -- Hand Core/Layout.lua's pooled rows and regions back first, so the
        -- orphaning below only touches frames nobody can reuse.
        if TA.Layout and TA.Layout.ReleasePane then
            pcall(TA.Layout.ReleasePane, TA.Layout, old)
        end
        old:Hide()
        -- Purge child regions (FontStrings, Textures) to prevent bleed-through
        for _, region in ipairs({ old:GetRegions() }) do
            region:Hide()
            if region.SetText then region:SetText("") end
        end
        -- Hide all child frames
        for _, child in ipairs({ old:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
        old:SetParent(nil)
        -- Return to pool based on width heuristic
        local key = (width > 200) and "content" or "side"
        table.insert(_framePool[key], old)
    end

    -- Try to reuse a pooled frame
    local key = (width > 200) and "content" or "side"
    local child = table.remove(_framePool[key])
    if child then
        child:SetParent(scrollFrame)
        child:SetSize(width, 1)
        child:Show()
        -- Re-purge in case anything lingered
        for _, region in ipairs({ child:GetRegions() }) do
            region:Hide()
            if region.SetText then region:SetText("") end
        end
        for _, c in ipairs({ child:GetChildren() }) do
            c:Hide()
            c:SetParent(nil)
        end
    else
        child = CreateFrame("Frame", nil, scrollFrame)
        child:SetSize(width, 1)
    end

    child._laPane = true          -- Core/Layout.lua recycles what it draws here
    scrollFrame:SetScrollChild(child)
    scrollFrame:SetVerticalScroll(0)
    return child
end

-- ── Main UI initialisation ────────────────────────────────────────────
-- ── Per-flavor tab set ───────────────────────────────────────────────
-- The active profile (Core/Profile.lua) may supply its own ordered tab list;
-- retail uses DEFAULT_TABS. Either way a tab is dropped when its module is not
-- registered or not allowed on this client, so a flavor never shows a tab that
-- would render blank (e.g. Delves/Weekly/Guide on TBC Anniversary).
--- True when at least one loaded guide has steps. A Guide tab (and its
--- Guide Tracker drawer) with no guide content only shows an empty panel, which
--- is the Mists Classic case today: its only guide file is an empty stub.
local function HasGuideContent()
    local sources = { TA.Guides, TA.GuideData, TA.Data and TA.Data.Guides }
    for i = 1, 3 do
        local src = sources[i]
        if type(src) == "table" then
            for _, g in pairs(src) do
                if type(g) == "table" and type(g.steps) == "table" and #g.steps > 0 then
                    return true
                end
            end
        end
    end
    return false
end
TA.HasGuideContent = HasGuideContent

-- Generic per-tab visibility conditions. A tab def may carry
-- `condition = "<key>"`; the matching function here decides whether the tab is
-- shown at all. This is the extensible successor to the hard-coded guide check
-- below: new conditional tabs add a key here and a `condition` field on the tab
-- rather than growing another `if tabDef.id == ...` branch. A condition that is
-- not registered is treated as "no opinion" (tab shown), so a typo fails open
-- rather than hiding a tab silently.
local TabConditions = {
    -- Pets: only classes that actually command a persistent pet. On Vanilla-era
    -- Forever that is Hunter and Warlock; every other class would see an empty
    -- tab, so it is hidden for them entirely.
    --
    -- Used by Forever, TBC and Mists (N5, 2026-10-04: the rule decided
    -- 2026-09-28 -- show Pets when a pet is out or the class keeps one -- now
    -- applies on every client; Retail has its own data-driven rule below).
    hasPetClass = function()
        -- UnitClass returns (localizedName, ENGLISH_TOKEN); the token is stable
        -- across locales, so gate on it.
        if UnitExists("pet") then return true end
        local _, token = UnitClass("player")
        if token == "HUNTER" or token == "WARLOCK" then return true end
        -- Mists of Pandaria Classic only: two specs keep a PERMANENT pet.
        --   Frost Mage  (spec 64)  -- Water Elemental has no duration since 4.0.1
        --   Unholy DK   (spec 252) -- Raise Dead summons a permanent ghoul
        --                            (Master of Ghouls, Unholy passive)
        -- GetSpecialization/GetSpecializationInfo exist from 5.0.4, so this is
        -- MoP-correct and guarded anyway. TBC/Vanilla-era Forever have neither
        -- class/spec pet (no DKs; the TBC Water Elemental lasts 45 s), so the
        -- check is skipped there rather than trusted to fail.
        if TA.flavor == "mists" and (token == "MAGE" or token == "DEATHKNIGHT")
           and type(GetSpecialization) == "function"
           and type(GetSpecializationInfo) == "function" then
            local idx = GetSpecialization()
            local specID = idx and GetSpecializationInfo(idx)
            return specID == 64 or specID == 252
        end
        return false
    end,
}
TA.TabConditions = TabConditions

-- Pets tab rule, Retail (2026-09-28 -- the rule Forever already follows): show
-- the tab when a pet is out, or when this class/spec keeps a PERMANENT pet
-- according to Data/Retail/Pets.lua's ClassPetDB (Hunter always); otherwise
-- hide it rather than show an empty tab. Spec names in ClassPetDB are English,
-- so on a non-English client only the "All"-spec entries and Hunter match.
local function RetailPetTabWanted()
    if UnitExists("pet") then return true end
    local _, token = UnitClass("player")
    if token == "HUNTER" then return true end
    local db = TA.Data and TA.Data.Pets and TA.Data.Pets.ClassPetDB
    local list = db and db[token]
    if type(list) ~= "table" then return false end
    local specName
    if GetSpecialization and GetSpecializationInfo then
        local idx = GetSpecialization()
        if idx then specName = select(2, GetSpecializationInfo(idx)) end
    end
    for _, p in ipairs(list) do
        if p.summonType == "Permanent" and (p.spec == "All" or p.spec == specName) then
            return true
        end
    end
    return false
end

local function TabAvailable(tabDef)
    if not TA:GetModule(tabDef.module) then return false end
    if TA.ModuleAllowed and not TA:ModuleAllowed(tabDef.module) then return false end
    if tabDef.id == "guide" and not HasGuideContent() then return false end
    if tabDef.id == "pets" and TA.flavor == "retail" and not RetailPetTabWanted() then return false end
    if tabDef.condition then
        local cond = TabConditions[tabDef.condition]
        if type(cond) == "function" then
            local ok, visible = pcall(cond)
            if ok and not visible then return false end
        end
    end
    return true
end

local function GetTabs()
    local source = (TA.ProfileTabs and TA:ProfileTabs()) or DEFAULT_TABS
    local list = {}
    for _, t in ipairs(source) do
        if TabAvailable(t) then list[#list + 1] = t end
    end
    return list
end

--- The enabled tab ids, in order. When a spec change, a pet appearing or a
--- level-up changes this, the tab bar is rebuilt (see Refresh and Show).
local function TabSignature()
    local ids = {}
    for _, t in ipairs(GetTabs()) do ids[#ids + 1] = t.id end
    return table.concat(ids, ",")
end

-- Events that can add or remove a tab (a conditional tab like Pets).
local TAB_SET_EVENTS = {
    UNIT_PET = true, PLAYER_SPECIALIZATION_CHANGED = true, ACTIVE_TALENT_GROUP_CHANGED = true,
    TRAIT_CONFIG_UPDATED = true, PLAYER_LEVEL_UP = true,
}

local function FindTab(tabID)
    for _, t in ipairs(GetTabs()) do
        if t.id == tabID then return t end
    end
    return nil
end

-- Tabs a player can hide via the options panel. "character" is always
-- shown -- it's the anchor tab and disabling everything would leave an
-- empty window. A tab this flavor doesn't ship counts as disabled, so a
-- saved lastTab or a /ta command for it falls back to Character.
local function IsTabEnabled(tabID)
    if not FindTab(tabID) then return false end
    if tabID == "character" then return true end
    return not (TA.db and TA.db.disabledTabs and TA.db.disabledTabs[tabID])
end

--- Tab exists on this client (flavor tab set + module loaded).
function TA:IsTabAvailable(tabID) return FindTab(tabID) ~= nil end
--- Tab exists AND the player hasn't switched it off in options.
function TA:IsTabEnabled(tabID) return IsTabEnabled(tabID) end

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
    -- Esc closes the window (UISpecialFrames is how every Blizzard panel does it).
    -- The frame's Hide override below also closes the settings drawer.
    tinsert(UISpecialFrames, "ToonAgeFrame")

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
    -- Label from the running client, not a hardcoded Retail string (the TBC
    -- Anniversary window used to say "Midnight 12.0.5").
    local FLAVOR_NAME = {
        retail = "Midnight", tbc = "TBC Anniversary", mists = "Mists Classic",
        vanilla = "Classic Era", wrath = "Wrath Classic", cata = "Cataclysm Classic",
        forever = "Forever",
    }
    local build = (GetBuildInfo and select(1, GetBuildInfo())) or ""
    versionLabel:SetText("v" .. TA.version .. "  ·  "
        .. (FLAVOR_NAME[TA.flavor] or "WoW") .. (build ~= "" and (" " .. build) or ""))
    versionLabel:SetTextColor(0.55, 0.52, 0.45, 1.00)
    -- Right-to-left anchor chain: Close → Options → Help → Copy → Version
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local optionsBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    frame.optionsBtn = optionsBtn   -- read by the self-test's settings suite (G9 check)
    optionsBtn:SetSize(20, 20)
    optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

    -- Help (?) and Copy chat: useful from every tab, so they live here rather
    -- than on one tab. Each runs the /ta command of the same name.
    local function TitleButton(anchor, text, width, tip, cmd)
        local b = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        fs:SetText(text)
        local textW = (fs.GetStringWidth and fs:GetStringWidth()) or width
        b:SetSize(math.max(textW + 16, width), 20)
        b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        fs:SetTextColor(0.62, 0.59, 0.55, 1)
        fs:SetAllPoints(b)
        fs:SetJustifyH("CENTER")
        b:SetScript("OnEnter", function(self)
            fs:SetTextColor(0.92, 0.90, 0.87, 1)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip, 1, 0.82, 0)
            GameTooltip:AddLine("/ta " .. cmd, 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() fs:SetTextColor(0.62, 0.59, 0.55, 1); GameTooltip:Hide() end)
        b:SetScript("OnClick", function() TA:SlashCommand(cmd) end)
        return b
    end
    local helpBtn = TitleButton(optionsBtn, "?", 20, "Commands", "help")
    local copyBtn = TitleButton(helpBtn, "Copy", 56, "Copy chat", "copy")

    versionLabel:SetPoint("RIGHT", copyBtn, "LEFT", -10, 0)
    versionLabel:SetWidth(150)
    versionLabel:SetJustifyH("RIGHT")
    versionLabel:SetWordWrap(false)
    local versionFull = versionLabel:GetText() or ""
    local versionHit = CreateFrame("Button", nil, titleBar)
    versionHit:SetAllPoints(versionLabel)
    versionHit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(versionFull, 1, 0.82, 0)
        GameTooltip:Show()
    end)
    versionHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local optIcon = optionsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optIcon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    optIcon:SetText("\226\154\153")  -- gear glyph
    optIcon:SetTextColor(0.62, 0.59, 0.55, 1)
    optIcon:SetAllPoints(optionsBtn)
    optIcon:SetJustifyH("CENTER")
    optionsBtn:SetScript("OnEnter", function() optIcon:SetTextColor(0.92, 0.90, 0.87, 1) end)
    optionsBtn:SetScript("OnLeave", function() optIcon:SetTextColor(0.62, 0.59, 0.55, 1) end)
    optionsBtn:SetScript("OnClick", function() TA:ToggleOptionsPanel() end)
    -- G9 (2026-10-04): no Settings module, no gear. The scaffold builds (Era,
    -- Cata, Wrath) ship none, and the gear opened an empty drawer there.
    -- InitModules runs before InitUI (Init.lua OnLogin), so GetModule already
    -- reflects this build. Width 1, not 0: Help/Copy still anchor to it.
    if not self:GetModule("Settings") then
        optionsBtn:SetWidth(1)
        optionsBtn:EnableMouse(false)
        optionsBtn:Hide()
        optionsBtn:SetScript("OnShow", function(b)
            if not TA:GetModule("Settings") then b:Hide() end
        end)
    end

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

        -- Keep the reader's place.
        --
        -- Refresh() re-runs SetTab on the CURRENT tab whenever a watched event
        -- fires, and RebuildChild ends with SetVerticalScroll(0). Scrolling down
        -- the gear list therefore lasted only until the next inventory or
        -- item-info event, which snapped the view back to the top -- looking for
        -- all the world like the scroll was broken.
        --
        -- Switching to a DIFFERENT tab still starts at the top, which is what
        -- anyone expects; only a rebuild of the tab you are already reading
        -- restores the offset.
        local sameTab = (self.activeTab == tabID)
        local keepScroll = sameTab and self.contentScroll
            and self.contentScroll:GetVerticalScroll() or 0

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

        -- Restored AFTER the module renders, below: the scroll range is zero
        -- until the child has its real height, so restoring here would clamp to
        -- nothing. Remembered now because RebuildChild has just zeroed it.
        self._restoreScroll = (keepScroll > 0) and keepScroll or nil

        -- Ask the module to render into the fresh panes
        local tabDef = FindTab(tabID)
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

            -- Put the view back where it was. One frame later: the scroll
            -- range is computed from the child's height, and that height was
            -- only just set by Finish() inside the render above.
            if self._restoreScroll and C_Timer and C_Timer.After then
                local want, sf = self._restoreScroll, self.contentScroll
                self._restoreScroll = nil
                C_Timer.After(0, function()
                    if not (sf and sf.GetVerticalScrollRange) then return end
                    local maxScroll = sf:GetVerticalScrollRange() or 0
                    if maxScroll <= 0 then return end
                    sf:SetVerticalScroll(math.min(want, maxScroll))
                end)
            end

            -- ── Guide tab conditional behavior ────────────────────────────
            -- In fragmented (independent windows) mode, clicking the Guide tab
            -- should also ensure the standalone tracker is visible, since the
            -- drawer is suppressed.
            if tabID == "guide" and TA.db and not TA.db.useUnifiedUI then
                local QT = TA:GetModule("QuestTracker")
                if QT and QT.window and QT.guideID and not QT.window:IsVisible() then
                    QT.window:Show()
                    QT:UpdateWindow()
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
    -- Which events can actually change what a given tab displays. Anything
    -- not listed for the active tab is skipped rather than triggering a full
    -- SetTab teardown/rebuild.
    --
    -- IMPORTANT — this is deliberately NOT a plain allow-list. Modules register
    -- their own events on TA.eventFrame (QuestTracker alone adds nine), so the
    -- set of events reaching Refresh is much larger than Init.lua's
    -- PERSISTENT_EVENTS and will grow as modules are added. A strict allow-list
    -- would silently stop refreshing a tab the day someone registers a new
    -- event — a bug that looks like "the tab is just stale sometimes."
    --
    -- So: an event that no tab claims and that isn't explicitly listed as
    -- UI-irrelevant below forces a rebuild. Unknown means "assume it matters."
    -- The filtering win comes from UI_IRRELEVANT, which is where the genuinely
    -- high-frequency churn lives.
    local TAB_EVENTS = {
        guide = {
            QUEST_ACCEPTED = true, QUEST_TURNED_IN = true,
            QUEST_LOG_UPDATE = true, UNIT_QUEST_LOG_CHANGED = true,
            QUEST_WATCH_LIST_CHANGED = true, QUEST_COMPLETE = true,
            QUEST_FINISHED = true, SUPER_TRACKING_CHANGED = true,
            ZONE_CHANGED = true, ZONE_CHANGED_NEW_AREA = true,
            PLAYER_LEVEL_UP = true, PLAYER_XP_UPDATE = true,
            -- Chromie Time selection UI (verified names, no payload, 9.0.1).
            CHROMIE_TIME_OPEN = true, CHROMIE_TIME_CLOSE = true,
        },
        character = {
            PLAYER_LEVEL_UP = true, PLAYER_EQUIPMENT_CHANGED = true,
            UNIT_INVENTORY_CHANGED = true, PLAYER_SPECIALIZATION_CHANGED = true,
            ACTIVE_TALENT_GROUP_CHANGED = true, SKILL_LINES_CHANGED = true,
            ZONE_CHANGED_NEW_AREA = true,
        },
        gear = {
            PLAYER_EQUIPMENT_CHANGED = true, UNIT_INVENTORY_CHANGED = true,
            BAG_UPDATE = true, GET_ITEM_INFO_RECEIVED = true,
            PLAYER_SPECIALIZATION_CHANGED = true, PLAYER_LEVEL_UP = true,
        },
        talents = {
            PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
            TRAIT_CONFIG_UPDATED = true, PLAYER_SPECIALIZATION_CHANGED = true,
            PLAYER_LEVEL_UP = true,
        },
        rotation = {
            PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
            TRAIT_CONFIG_UPDATED = true, PLAYER_SPECIALIZATION_CHANGED = true,
            PLAYER_LEVEL_UP = true,
        },
        professions = {
            SKILL_LINES_CHANGED = true, PLAYER_LEVEL_UP = true,
            GET_ITEM_INFO_RECEIVED = true,
        },
        pets = {
            PET_STABLE_UPDATE = true, UNIT_PET = true, PLAYER_LEVEL_UP = true,
        },
        weekly = {
            PLAYER_LEVEL_UP = true, CHAT_MSG_SYSTEM = true,
            ZONE_CHANGED_NEW_AREA = true, GROUP_ROSTER_UPDATE = true,
            -- World quest rewards load asynchronously; redraw when they arrive
            -- and when a quest is turned in.
            QUEST_LOG_UPDATE = true, QUEST_TURNED_IN = true,
        },
        delves = {
            PLAYER_LEVEL_UP = true, ZONE_CHANGED_NEW_AREA = true,
            CHAT_MSG_SYSTEM = true, GROUP_ROSTER_UPDATE = true,
            -- Fix (2026-09-13): the Delve Advisor's Progression card is driven
            -- by U.GetAverageIlvl(), but neither event that actually changes
            -- it was claimed here. PLAYER_EQUIPMENT_CHANGED/UNIT_INVENTORY_CHANGED
            -- are already claimed by "character"/"gear" above, so they were
            -- in CLAIMED_EVENTS and did NOT fall through to the "unknown
            -- event -> rebuild anyway" default -- they were simply swallowed
            -- for this tab. Loot from a delve run never refreshed the tier/
            -- iLvl display until an unrelated event (zone/roster change)
            -- happened to fire too.
            PLAYER_EQUIPMENT_CHANGED = true, UNIT_INVENTORY_CHANGED = true,
        },
    }

    -- Spec and talent changes redraw WHATEVER tab is open. Every tab shows
    -- the sidebar (spec, role) and most read role/spec for their advice, but
    -- these events were only claimed by character/gear/talents/rotation --
    -- and a claimed event is swallowed for every other tab. That is why the
    -- Delves (and Weekly, Professions, Pets...) tab kept showing the old
    -- role after a respec. TRAIT_CONFIG_UPDATED also covers the case where
    -- PLAYER_SPECIALIZATION_CHANGED fires before the new spec is readable.
    local SPEC_EVENTS = {
        PLAYER_SPECIALIZATION_CHANGED = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        TRAIT_CONFIG_UPDATED = true, PLAYER_TALENT_UPDATE = true,
    }

    -- TBC Anniversary tabs read combat ratings, stats and talent points that
    -- the retail tabs never claim. Merged only on that flavor so retail's
    -- refresh filtering is unchanged. (Carried over from the standalone
    -- Anniversary build's UI.lua.)
    if TA.flavor == "tbc" then
        local TBC_TAB_EVENTS = {
            character = { COMBAT_RATING_UPDATE = true, UNIT_STATS = true,
                          UNIT_ATTACK_POWER = true, CHARACTER_POINTS_CHANGED = true },
            caps      = { PLAYER_LEVEL_UP = true, PLAYER_EQUIPMENT_CHANGED = true,
                          COMBAT_RATING_UPDATE = true, SKILL_LINES_CHANGED = true,
                          PLAYER_TARGET_CHANGED = true, UNIT_STATS = true },
            gear      = { COMBAT_RATING_UPDATE = true },
            weapons   = { SKILL_LINES_CHANGED = true, PLAYER_EQUIPMENT_CHANGED = true,
                          PLAYER_LEVEL_UP = true },
            racials   = { PLAYER_LEVEL_UP = true },
            pvp       = { PLAYER_EQUIPMENT_CHANGED = true, COMBAT_RATING_UPDATE = true,
                          PLAYER_LEVEL_UP = true },
            talents   = { CHARACTER_POINTS_CHANGED = true },
            rotation  = { CHARACTER_POINTS_CHANGED = true },
            spells    = { LEARNED_SPELL_IN_TAB = true, ACTIONBAR_SLOT_CHANGED = true },
            pets      = { UNIT_HAPPINESS = true, PET_BAR_UPDATE = true, BAG_UPDATE = true },
        }
        for tabID, events in pairs(TBC_TAB_EVENTS) do
            TAB_EVENTS[tabID] = TAB_EVENTS[tabID] or {}
            for e in pairs(events) do
                TAB_EVENTS[tabID][e] = true
                -- These events were claimed here but never registered on the
                -- event frame, so talent, stat and action-bar changes did not
                -- refresh the TBC tabs (and Spells' "new spell" alert never
                -- fired). TA:RegisterEvent (Core/Init.lua) pcalls the
                -- registration AND records names this client doesn't know in
                -- TA.unknownEvents, so they show up in /ta health and the
                -- self-test instead of failing silently (G16, 2026-10-04).
                if TA.eventFrame and TA.RegisterEvent then TA:RegisterEvent(e) end
            end
        end
    end

    -- Tab refresh events declared by the active profile, on every flavor: the
    -- tab def's own `events` list plus whatever its module lists in M.Events.
    -- A tab missing from TAB_EVENTS never saw an event that another tab claimed
    -- (BAG_UPDATE belongs to "gear"), so Forever's Scrolls tab never rebuilt on
    -- a bag change -- /ta test, 2026-09-28. Claiming here also stops the other
    -- tabs rebuilding on events that only this one displays.
    for _, def in ipairs((TA.ProfileTabs and TA:ProfileTabs()) or {}) do
        local mod = TA:GetModule(def.module)
        local lists = { def.events, (mod and type(mod.Events) == "table") and mod.Events or nil }
        for i = 1, 2 do
            if type(lists[i]) == "table" then
                TAB_EVENTS[def.id] = TAB_EVENTS[def.id] or {}
                for _, e in ipairs(lists[i]) do TAB_EVENTS[def.id][e] = true end
            end
        end
    end

    -- Events that no tab renders: combat/nameplate churn, cinematics, and
    -- death/res transitions. These are the high-frequency ones worth filtering
    -- (NAME_PLATE_UNIT_ADDED/REMOVED fire constantly in combat). Anything not
    -- listed here and not claimed by a tab falls through to a rebuild.
    local UI_IRRELEVANT = {
        NAME_PLATE_UNIT_ADDED = true, NAME_PLATE_UNIT_REMOVED = true,
        CINEMATIC_START = true, PLAY_MOVIE = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true,
        READY_CHECK = true, PLAYER_LEAVING_WORLD = true,
    }

    -- Union of every event any tab claims. Used to tell "this event is known
    -- and simply isn't for the active tab" from "nobody has accounted for
    -- this event" — only the former is safe to skip.
    local CLAIMED_EVENTS = {}
    for _, events in pairs(TAB_EVENTS) do
        for event in pairs(events) do CLAIMED_EVENTS[event] = true end
    end

    --- Should this batch of events cause the active tab to rebuild?
    local function BatchAffectsTab(events, activeTab)
        local relevant = TAB_EVENTS[activeTab]
        for event in pairs(events) do
            if SPEC_EVENTS[event] then
                return true   -- sidebar spec/role + role-based advice on every tab
            end
            if relevant and relevant[event] then
                return true   -- directly affects what's on screen
            end
            if not (UI_IRRELEVANT[event] or CLAIMED_EVENTS[event]) then
                return true   -- unaccounted-for event: fail open, rebuild
            end
        end
        return false
    end

    --- @param events table|string|nil — set of event names from the coalescing
    ---        queue in Init.lua, a single event name, or nil to force a rebuild.
    function frame:Refresh(events)
        if not self.activeTab then return end

        -- A spec change or a pet coming out can show or hide a tab.
        if events then
            local evs = (type(events) == "table") and events or { [events] = true }
            for ev in pairs(evs) do
                if TAB_SET_EVENTS[ev] then
                    if self._tabSig ~= TabSignature() then
                        self:RebuildTabs()
                        return
                    end
                    break
                end
            end
        end

        if events then
            if type(events) ~= "table" then events = { [events] = true } end
            if not BatchAffectsTab(events, self.activeTab) then return end
        end

        self:SetTab(self.activeTab)
    end

    -- ── Show: open to last tab ────────────────────────────────────────
    local origShow = frame.Show
    function frame:Show()
        origShow(self)
        -- Tabs may have changed while the window was closed (respec, pet).
        if self._tabSig ~= TabSignature() then self:RebuildTabs() end
        self:SetTab(TA.charDB.lastTab or "guide")
    end

    -- The Settings drawer (TASettingsDrawer) is parented to UIParent, not to
    -- this frame, so it can be positioned independently below the main
    -- window — but that also means closing the main window never closed it
    -- on its own. Close it here so it can't be left open and orphaned.
    local origHide = frame.Hide
    function frame:Hide()
        origHide(self)
        if TA._settingsDrawer and TA._settingsDrawer:IsShown() then
            TA._settingsDrawer:Hide()
        end
    end

    -- ── RebuildTabs — callable at any time (e.g. from options panel) ──
    -- Destroys all existing tab buttons and recreates them from the current
    -- disabledTabs state, then re-selects the active tab (or "character"
    -- if it was disabled). Called once at init, then again any time the
    -- player toggles a tab in the options panel.
    -- NOTE: SetTab, Refresh, and Show must be defined above this function
    -- because RebuildTabs calls self:SetTab() at the end of its run.
    function frame:RebuildTabs()
        self._tabSig = TabSignature()
        -- Destroy existing tab buttons
        for _, btn in pairs(self.tabButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        self.tabButtons = {}

        local tabX = 8
        -- The Guide Tracker drawer follows the Guide tab: no tab, no drawer.
        if TA.Modern and TA.Modern.UpdateDrawerAvailability then
            pcall(TA.Modern.UpdateDrawerAvailability, TA.Modern)
        end

        for _, tabDef in ipairs(GetTabs()) do
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

        -- A flavor with no shipped content (Core/Profile.lua scaffolds: Classic
        -- Era, Cataclysm, Wrath, WoW Forever) has no tabs at all, and an empty
        -- window with no explanation reads as a broken addon rather than a
        -- deliberate one. Say so, in the window, instead of leaving it blank.
        if not next(self.tabButtons) then
            self:ShowNoContentNotice()
            return
        end
        if self.noContent then self.noContent:Hide() end

        -- Re-select the previously active tab, falling back to "character"
        -- if it was just disabled.
        local tabToShow = self.activeTab or "character"
        if not IsTabEnabled(tabToShow) then tabToShow = "character" end
        self:SetTab(tabToShow)
    end

    --- Panel shown when the running client has no ToonAge content yet.
    function frame:ShowNoContentNotice()
        local profile = (TA.GetProfile and TA:GetProfile()) or {}
        local label   = profile.label or "this client"

        if not self.noContent then
            local box = CreateFrame("Frame", nil, self)
            box:SetPoint("TOPLEFT", 24, -(TAB_HEIGHT + 28))
            box:SetPoint("BOTTOMRIGHT", -24, 24)

            local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOP", 0, -40)
            title:SetText("|cFFFFD100ToonAge|r")

            local body = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            body:SetPoint("TOP", title, "BOTTOM", 0, -16)
            body:SetWidth(460)
            body:SetJustifyH("CENTER")
            body:SetSpacing(4)
            box.body = body

            self.noContent = box
        end

        local version, _, _, iface = GetBuildInfo()
        self.noContent.body:SetText(
            "Loaded on |cFFFFFFFF" .. label .. "|r (" .. tostring(version)
            .. ", interface " .. tostring(iface) .. ").\n\n"
            .. "There is no gear, rotation or leveling content for this version yet, so\n"
            .. "ToonAge is deliberately staying quiet rather than giving you another\n"
            .. "expansion's numbers.\n\n"
            .. (profile.partial
                and ("Navigation, the guide tracker and leveling tools DO run here — import a\n"
                     .. "guide and the Guide tab appears. Gear, rotation and talent advice wait\n"
                     .. "for researched data for this version.\n\n")
                or "")
            .. "Error capture is running, so anything that breaks is still recorded:\n"
            .. "type |cFFFFD100/ta errors|r to see it, or |cFFFFD100/ta health|r for what loaded.")
        if TA.flavor == "vanilla" then
            if not self.noContent.heirloom then
                local card = CreateFrame("Frame", nil, self.noContent, "BackdropTemplate")
                card:SetSize(360, 108)
                card:SetPoint("TOP", self.noContent.body, "BOTTOM", 0, -18)
                ApplyBackdrop(card, 0.07, 0.07, 0.08, 0.94, 0.30, 0.28, 0.24, 1)
                local glyph = card:CreateTexture(nil, "ARTWORK")
                glyph:SetSize(24, 24)
                glyph:SetPoint("TOP", 0, -12)
                glyph:SetTexture("Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga")
                glyph:SetVertexColor(1, 0.82, 0)
                local heading = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                heading:SetPoint("TOP", glyph, "BOTTOM", 0, -6)
                heading:SetWidth(330)
                heading:SetJustifyH("CENTER")
                heading:SetText("No heirlooms here")
                heading:SetTextColor(1, 0.82, 0)
                local sentence = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                sentence:SetPoint("TOP", heading, "BOTTOM", 0, -4)
                sentence:SetWidth(330)
                sentence:SetJustifyH("CENTER")
                sentence:SetText("Classic Era has no heirloom items, so this scan stays off.")
                card.sentence = sentence
                self.noContent.heirloom = card
            end
            self.noContent.heirloom:Show()
        elseif self.noContent.heirloom then
            self.noContent.heirloom:Hide()
        end
        self.noContent:Show()
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
            -- The page used to be registered empty. Point at where the settings
            -- actually live, with one button that opens them.
            local bpTitle = blizzPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            bpTitle:SetPoint("TOPLEFT", 16, -16)
            bpTitle:SetText("ToonAge")
            local bpText = blizzPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            bpText:SetPoint("TOPLEFT", bpTitle, "BOTTOMLEFT", 0, -8)
            bpText:SetWidth(560)
            bpText:SetJustifyH("LEFT")
            bpText:SetText("ToonAge's settings live in its own window. Open it with /ta or the "
                .. "minimap button, then click the gear in its title bar.")
            local bpBtn = CreateFrame("Button", nil, blizzPanel, "UIPanelButtonTemplate")
            bpBtn:SetSize(190, 24)
            bpBtn:SetPoint("TOPLEFT", bpText, "BOTTOMLEFT", 0, -12)
            bpBtn:SetText("Open ToonAge settings")
            bpBtn:SetScript("OnClick", function()
                if TA.UI and not TA.UI:IsShown() then TA.UI:Show() end
                if not (TA._settingsDrawer and TA._settingsDrawer:IsShown()) then
                    TA:ToggleSettingsDrawer()
                end
            end)
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
            TA:Raw(TA.LOG.ERROR, "|cFFFFD100[TA]|r Blizzard Settings registration failed: " .. tostring(err))
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

-- ── Copyable text window ──────────────────────────────────────────────
-- Chat is the wrong place for a 56-line report: the frame is small, the
-- scrollback is shared with combat spam, and you cannot select any of it.
-- Anything long enough to want pasting into an issue goes here instead.
-- Colour codes are stripped, since they paste as literal |cFF... noise.
local function Plain(text)
    return (tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

function TA:ShowCopyWindow(title, text)
    local f = self._copyWindow
    if not f then
        f = CreateFrame("Frame", "ToonAgeCopyWindow", UIParent, "BackdropTemplate")
        f:SetSize(620, 460)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.05, 0.05, 0.06, 0.96)
        f:SetBackdropBorderColor(0.85, 0.65, 0.13, 0.85)

        local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", 12, -10)
        f.header = hdr

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetSize(24, 24)
        close:SetPoint("TOPRIGHT", -4, -4)

        local scroll = CreateFrame("ScrollFrame", "ToonAgeCopyWindowScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -32)
        scroll:SetPoint("BOTTOMRIGHT", -30, 40)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(560)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(edit)
        f.editBox = edit

        local sel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        sel:SetSize(90, 22)
        sel:SetPoint("BOTTOMLEFT", 12, 10)
        sel:SetText("Select All")
        sel:SetScript("OnClick", function()
            edit:SetFocus()
            edit:HighlightText()
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Selected — press Ctrl+C to copy.")
        end)

        tinsert(UISpecialFrames, "ToonAgeCopyWindow")
        self._copyWindow = f
    end

    f.header:SetText("|cFFFFD100" .. tostring(title) .. "|r  (Ctrl+A to select, Ctrl+C to copy)")
    f.editBox:SetText(Plain(text))
    f.editBox:SetCursorPosition(0)
    f:Show()
end

--- Collect a multi-line report, then put it where it can actually be read.
---
--- Chat is fine for a line or two. A 50-line module list, a diagnostic dump or
--- an API probe scrolls straight out of a chat frame that cannot be selected,
--- which is how you end up retyping output into a bug report. Anything past
--- `threshold` lines opens in the copy window instead, with one line left in
--- chat saying so.
---
--- Usage:
---     local r = TA:BeginReport("Tracker Diagnostics")
---     r:Add("step 4 of 19")
---     r:Finish()
function TA:BeginReport(title, threshold)
    local r = {
        title = title or "ToonAge",
        lines = {},
        threshold = threshold or 8,
    }

    function r:Add(text)
        self.lines[#self.lines + 1] = tostring(text)
    end

    function r:Addf(fmt, ...)
        self:Add(string.format(fmt, ...))
    end

    --- Returns true if the report went to the window rather than to chat.
    function r:Finish()
        local body = table.concat(self.lines, "\n")
        if #self.lines > self.threshold and TA.ShowCopyWindow then
            TA:ShowCopyWindow(self.title, body)
            TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r %s — %d lines, opened in a window you can select and paste.")
                  :format(self.title, #self.lines))
            return true
        end
        for _, line in ipairs(self.lines) do
            TA:Raw(TA.LOG.OUTPUT, line)
        end
        return false
    end

    return r
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
    local numTabRows = #GetTabs() - 1  -- "character" tab is always-on, not listed
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
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout switched to: " .. mode)
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
    for _, tabDef in ipairs(GetTabs()) do
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

--- Place the arrow during a layout swap, deferring to the user's own position.
---
--- ApplyLayout used to position the arrow from `db.unifiedPosition` or
--- `db.oldUiPositions.arrow`, while dragging the arrow saves to
--- `TA.charDB.arrow.x/y`. Two separate stores that never talked to each other,
--- so every layout swap discarded a moved arrow and re-applied the layout
--- default — and `oldUiPositions.arrow` defaults to `point = "CENTER"`, which
--- is why it landed dead centre.
---
--- It also called RegisterForDrag("LeftButton") unconditionally, silently
--- undoing a lock the user had set by right-clicking the arrow.
---
--- Same restore formula and same lock handling as Arrow:Init, so the arrow
--- ends up in one place regardless of which code path put it there.
--- @param arrowF Frame|nil
--- @param defaultPos table — { point, relativePoint, x, y } used only when unplaced
--- @param dx number|nil — layout-specific nudge, applied to the default only
--- @param dy number|nil
local function PositionArrow(arrowF, defaultPos, dx, dy)
    if not arrowF or not defaultPos then return end
    local saved = TA.charDB and TA.charDB.arrow

    arrowF:ClearAllPoints()
    if saved and saved.x and saved.y then
        arrowF:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        arrowF:SetPoint(defaultPos.point, UIParent, defaultPos.relativePoint,
                        defaultPos.x + (dx or 0), defaultPos.y + (dy or 0))
    end

    if saved and saved.locked then
        arrowF:RegisterForDrag()
    else
        arrowF:RegisterForDrag("LeftButton")
    end
end

function TA:ApplyLayout()
    local db = self.db
    if not db then return end

    local Arrow  = self:GetModule("Arrow")
    local QT     = self:GetModule("QuestTracker")
    local arrowF = Arrow  and Arrow.frame
    local guideF = QT     and QT.window
    local M      = self.Modern
    local drawer = M and M.drawer

    if db.useUnifiedUI then
        -- ── UNIFIED HUD ────────────────────────────────────────────────────────
        -- The drawer (attached to main frame) is the primary tracker view.
        -- The standalone floating window is hidden.

        -- 1) Hide standalone tracker window
        if guideF then
            guideF:Hide()
        end

        -- 2) Position arrow at unified position (unless the user placed it)
        PositionArrow(arrowF, db.unifiedPosition, -50, 10)

        -- 3) Allow the drawer's OnShow hook to function normally
        self._drawerSuppressed = false

        -- 4) Show drawer if main frame is visible and drawer exists
        --    (never when the Guide tab is off or not part of this client)
        if drawer and self.UI and self.UI:IsVisible() and not (M and M._guideDisabled) then
            if not drawer:IsVisible() then
                drawer:Show()
                drawer:SetWidth((M.DRAWER_WIDTH) or 280)
                drawer:SetAlpha(1)
            end
            -- Populate drawer content
            if QT and QT.UpdateDrawer then
                QT:UpdateDrawer()
            end
        end

    else
        -- ── FRAGMENTED (INDEPENDENT WINDOWS) ───────────────────────────────────
        -- The standalone tracker window is the primary view.
        -- The drawer is hidden and suppressed from auto-opening.

        -- 1) Suppress the drawer — prevents mainFrame OnShow hook from reopening it
        self._drawerSuppressed = true

        -- 2) Hide the drawer immediately
        if drawer and drawer:IsVisible() then
            drawer:Hide()
        end

        -- 3) Position arrow at its saved independent position
        PositionArrow(arrowF, db.oldUiPositions.arrow)

        -- 4) Show and position standalone tracker window
        if guideF then
            guideF:ClearAllPoints()
            local pos = db.oldUiPositions.guide
            guideF:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)

            -- Show tracker if a guide is active (and the Guide tab is on)
            if QT and QT.guideID and self:IsTabEnabled("guide") then
                guideF:Show()
                QT:UpdateWindow()
            end
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

-- Right-hand Quick Actions column inside the drawer.
-- The drawer hangs off the window's outside edge, so it is a side panel,
-- not a second copy of the 900-wide main frame.
local DRAWER_W         = 420
local DRAWER_SIDE_W    = 148
local function DrawerContentWidth(drawer)
    local w = (drawer and drawer:GetWidth()) or DRAWER_W
    return math.max(math.floor(w - 26 - DRAWER_SIDE_W - 16), 160)
end

function TA:ToggleSettingsDrawer()
    local mainFrame = self.UI

    -- G9: nothing to draw without the Settings module (scaffold builds, or the
    -- player switched it off). Say so once instead of opening an empty drawer.
    if not self:GetModule("Settings") then
        self:Print(self.LOG.OUTPUT, nil, "No settings panel on this client build.")
        return
    end

    -- Create drawer on first use
    if not self._settingsDrawer then
        local drawer = CreateFrame("Frame", "TASettingsDrawer", UIParent, "BackdropTemplate")
        drawer:SetSize(DRAWER_W, 400)
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
        tinsert(UISpecialFrames, "TASettingsDrawer")

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
        scroll:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -(26 + DRAWER_SIDE_W + 8), 4)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(DrawerContentWidth(drawer))
        content:SetHeight(1)
        scroll:SetScrollChild(content)

        -- Quick Actions column. This used to be a hidden 1x1 frame, so every
        -- button Settings:RenderSidebar drew (Reset All Settings among them)
        -- existed but could never be clicked -- /ta test, 2026-09-28.
        local sidebar = CreateFrame("Frame", nil, drawer)
        sidebar:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -8, -28)
        sidebar:SetSize(DRAWER_SIDE_W, 1)

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

    -- Attach to the window's outside edge. Flip to the left when the right
    -- side cannot hold the drawer. Same rule on every flavor: a drawer that
    -- opens underneath gets pushed up by SetClampedToScreen and covers the
    -- window (Forever ~60 px, Era ~233 px).
    drawer:ClearAllPoints()
    local function PlaceDrawer()
        drawer:ClearAllPoints()
        drawer:SetWidth(DRAWER_W)
        local gap = 8
        local dw = DRAWER_W
        if not (mainFrame and mainFrame:IsVisible() and mainFrame:GetRight()) then
            drawer:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
            return
        end
        local screenW = (UIParent and UIParent:GetWidth()) or 0
        local roomRight = screenW - (mainFrame:GetRight() or 0)
        local roomLeft = mainFrame:GetLeft() or 0
        local function fit(room)
            if room >= dw + gap then return dw end
            local shrunk = math.floor(room - gap)
            if shrunk >= 220 then
                drawer:SetWidth(shrunk)
                return shrunk
            end
            return nil
        end
        if fit(roomRight) then
            drawer:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", gap, 0)
        elseif fit(roomLeft) then
            drawer:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", -gap, 0)
        else
            drawer:SetWidth(dw)
            drawer:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", gap, 0)
        end
    end
    PlaceDrawer()

    -- Rebuild content each time (settings may have changed)
    local old = drawer.scroll:GetScrollChild()
    if old then old:Hide(); old:SetParent(nil) end

    local content = CreateFrame("Frame", nil, drawer.scroll)
    content:SetWidth(DrawerContentWidth(drawer))
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
