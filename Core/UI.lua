-- ToonAge/Core/UI.lua (Classic)
-- Main frame, tab bar, sidebar — adapted for Classic (3 tabs)

local TA = ToonAge
local U  = TA.Utils

-- ── Constants ─────────────────────────────────────────────────────────
local FRAME_WIDTH   = 900
local FRAME_HEIGHT  = 580
local SIDEBAR_WIDTH = 210
local TAB_HEIGHT    = 30
local TITLEBAR_H    = 34
local CONTENT_PAD   = 14
local ROW_PAD       = 6

-- Classic tabs: Character, Guide, Gear, Pet Care (no Talents/Rotation/Delves/Weekly/Prof)
local TABS = {
    { id = "character",   label = "Character",   module = "Character"    },
    { id = "guide",       label = "Guide",       module = "QuestTracker" },
    { id = "gear",        label = "Gear",        module = "Gear"         },
    { id = "petcare",     label = "Pet Care",    module = "PetCare"      },
}

-- Events that should trigger a rebuild for each tab
local TAB_EVENTS = {
    character = { PLAYER_LEVEL_UP = true, UNIT_INVENTORY_CHANGED = true, PLAYER_EQUIPMENT_CHANGED = true, ACTIVE_TALENT_GROUP_CHANGED = true },
    guide     = { QUEST_ACCEPTED = true, ZONE_CHANGED_NEW_AREA = true, ZONE_CHANGED = true },
    gear      = { UNIT_INVENTORY_CHANGED = true, PLAYER_EQUIPMENT_CHANGED = true, BAG_UPDATE = true, GET_ITEM_INFO_RECEIVED = true },
    -- PetCare only shows a class-quest reminder gated on spell-known state, so
    -- the events that can flip that are level-up and learning a new spell.
    petcare   = { PLAYER_LEVEL_UP = true, SPELLS_CHANGED = true },
}

-- Events known to be irrelevant to ANY tab (nameplate churn, combat, etc.)
local UI_IRRELEVANT = {
    NAME_PLATE_UNIT_ADDED = true,
    NAME_PLATE_UNIT_REMOVED = true,
    PLAYER_REGEN_DISABLED = true,
    PLAYER_REGEN_ENABLED = true,
    PLAYER_DEAD = true,
    PLAYER_ALIVE = true,
    PLAYER_UNGHOST = true,
}

-- ── Backdrop helper ───────────────────────────────────────────────────
local FLAT_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- ── Backdrop compatibility ────────────────────────────────────────────────────
-- MoP Classic (50504) runs the modern client engine, where SetBackdrop was
-- removed from the base Frame API and lives on BackdropTemplateMixin. Frames
-- must either be created with the "BackdropTemplate" template or have the mixin
-- applied after the fact.
--
-- This file and UIModern.lua create their frames with no template -- they are
-- the two Cata-era Core files, written before the split -- while all eight
-- Modules/ files already pass "BackdropTemplate" correctly. That mismatch is
-- what crashed InitUI at UI.lua:49 on the first-ever Classic login.
--
-- The mixin is applied here rather than at CreateFrame because an unknown
-- template string is itself a hard error, and the template's availability on
-- this client is not yet measured. This route is safe either way: if the mixin
-- is unavailable the frame simply goes unstyled and the addon keeps loading,
-- and the fact is recorded rather than swallowed -- an unstyled panel is a
-- cosmetic loss, a failed InitUI takes the whole addon down.
local function EnsureBackdrop(frame)
    if frame.SetBackdrop then return true end

    if type(Mixin) == "function" and type(BackdropTemplateMixin) == "table" then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropLoaded then frame:OnBackdropLoaded() end
    end

    if not frame.SetBackdrop then
        -- Report once. Silence here is the exact failure this addon exists to
        -- avoid: a nil backdrop that looks like a styling bug, not an API gap.
        if not TA._backdropUnavailable then
            TA._backdropUnavailable = true
            if TA.ErrorLog then
                TA.ErrorLog:Log("UI Backdrop",
                    "SetBackdrop absent and BackdropTemplateMixin unavailable; frames render unstyled", "")
            end
        end
        return false
    end
    return true
end

local function ApplyBackdrop(frame, br, bg, bb, ba, er, eg, eb, ea)
    if not EnsureBackdrop(frame) then return end
    frame:SetBackdrop(FLAT_BACKDROP)
    frame:SetBackdropColor(br or 0.05, bg or 0.04, bb or 0.02, ba or 0.98)
    frame:SetBackdropBorderColor(er or 0.55, eg or 0.40, eb or 0.08, ea or 0.70)
end

TA._EnsureBackdrop = EnsureBackdrop

-- ── Frame pool ────────────────────────────────────────────────────────
local _framePool = { content = {}, side = {} }

local function RebuildChild(scrollFrame, width)
    local old = scrollFrame:GetScrollChild()
    if old then
        old:Hide()
        for _, region in ipairs({ old:GetRegions() }) do
            region:Hide()
            if region.SetText then region:SetText("") end
        end
        for _, child in ipairs({ old:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
        old:SetParent(nil)
        local key = (width > 200) and "content" or "side"
        table.insert(_framePool[key], old)
    end

    local key = (width > 200) and "content" or "side"
    local child = table.remove(_framePool[key])
    if child then
        child:SetParent(scrollFrame)
        child:SetSize(width, 1)
        child:Show()
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

    scrollFrame:SetScrollChild(child)
    scrollFrame:SetVerticalScroll(0)
    return child
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ── UI OBJECT ─────────────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════

function TA:InitUI()
    if self.UI then return end

    -- Main frame
    local f = CreateFrame("Frame", "ToonAgeMainFrame", UIParent)
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    ApplyBackdrop(f, 0.05, 0.04, 0.02, 0.98, 0.55, 0.40, 0.08, 0.70)
    f:Hide()

    -- Make draggable
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Close on Escape
    tinsert(UISpecialFrames, "ToonAgeMainFrame")

    -- ── Title bar ─────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(TITLEBAR_H)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 14, 0)
    titleText:SetText("|cFFFFD100ToonAge|r |cFF888780Classic|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Tab bar ───────────────────────────────────────────────────────
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetHeight(TAB_HEIGHT)
    tabBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)

    f.tabButtons = {}
    local tabWidth = (FRAME_WIDTH - SIDEBAR_WIDTH) / #TABS
    for i, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tabWidth, TAB_HEIGHT)
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", (i-1) * tabWidth, 0)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        btn.label = label

        btn:SetScript("OnClick", function()
            f:SetTab(tab.id)
        end)

        btn.tabID = tab.id
        f.tabButtons[i] = btn
    end

    -- ── Sidebar (right side, 210px) ───────────────────────────────────
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(TITLEBAR_H + TAB_HEIGHT + 1))
    sidebar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    ApplyBackdrop(sidebar, 0.03, 0.03, 0.02, 0.95, 0.35, 0.28, 0.06, 0.40)
    f.sidebar = sidebar

    -- Sidebar scroll
    local sideScroll = CreateFrame("ScrollFrame", nil, sidebar)
    sideScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, -4)
    sideScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -4, 4)
    f.sideScroll = sideScroll

    -- ── Content area (main, left of sidebar) ──────────────────────────
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -(TITLEBAR_H + TAB_HEIGHT + 1))
    content:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMLEFT", 0, 0)
    f.content = content

    -- Content scroll
    local contentScroll = CreateFrame("ScrollFrame", nil, content)
    contentScroll:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, -CONTENT_PAD)
    contentScroll:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -CONTENT_PAD, CONTENT_PAD)
    contentScroll:EnableMouseWheel(true)
    contentScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local new = current - (delta * 40)
        self:SetVerticalScroll(math.max(0, math.min(new, max)))
    end)
    f.contentScroll = contentScroll

    -- ── Methods ───────────────────────────────────────────────────────
    f.activeTab = TABS[1].id

    function f:SetTab(tabID)
        self.activeTab = tabID

        -- Update tab button highlights
        for _, btn in ipairs(self.tabButtons) do
            if btn.tabID == tabID then
                btn.label:SetTextColor(1, 0.82, 0, 1)
            else
                btn.label:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end

        self:Refresh()
    end

    function f:IsVisible()
        return self:IsShown()
    end

    function f:Refresh(events)
        -- If events provided, check if any are relevant to current tab
        if events then
            local tabEvts = TAB_EVENTS[self.activeTab]
            local dominated = true
            for evt in pairs(events) do
                if UI_IRRELEVANT[evt] then
                    -- skip
                elseif tabEvts and tabEvts[evt] then
                    dominated = false
                    break
                elseif not tabEvts then
                    dominated = false
                    break
                end
            end
            if dominated then return end
        end

        -- Rebuild content
        local contentWidth = self.contentScroll:GetWidth() or (FRAME_WIDTH - SIDEBAR_WIDTH - CONTENT_PAD * 2)
        local sideWidth = SIDEBAR_WIDTH - 8

        self.contentChild = RebuildChild(self.contentScroll, contentWidth)
        self.sideChild    = RebuildChild(self.sideScroll, sideWidth)

        -- Find the active module and call its Render
        for _, tab in ipairs(TABS) do
            if tab.id == self.activeTab then
                local mod = TA:GetModule(tab.module)
                if mod and mod.Render then
                    local ok, err = pcall(mod.Render, mod, self.contentChild, self.sideChild)
                    if not ok then
                        TA:Printf(TA.LOG.ERROR, nil, "Render error (%s): %s", tab.module, tostring(err))
                        if TA.ErrorLog then TA.ErrorLog:Log(tab.module .. " Render", tostring(err), "") end
                    end
                end
                break
            end
        end
    end

    -- Initial tab highlight
    f:SetTab(TABS[1].id)

    self.UI = f
end
