-- ToonAge/Core/UI.lua (Anniversary — TBC Classic / Interface 20506)
-- Main frame, tab bar, sidebar. Six tabs, all advisory — no guide, no map.

local TA = ToonAge
local U  = TA.Utils

-- ─── Constants ───────────────────────────────────────────────────────────────
local FRAME_WIDTH   = 900
local FRAME_HEIGHT  = 580
local SIDEBAR_WIDTH = 210
local TAB_HEIGHT    = 30
local TITLEBAR_H    = 34
local CONTENT_PAD   = 14

local TABS = {
    { id = "character", label = "Character",   module = "Character"         },
    { id = "caps",      label = "Stat Caps",   module = "StatCaps"          },
    { id = "gear",      label = "Gear",        module = "Gear"              },
    { id = "weapons",   label = "Weapons",     module = "WeaponSkill"       },
    { id = "racials",   label = "Racials",     module = "RaceAdvisor"       },
    { id = "profs",     label = "Profs",       module = "ProfessionAdvisor" },
    { id = "pvp",       label = "PvP",         module = "PvPAdvisor"        },
    { id = "petcare",   label = "Pet Care",    module = "PetCare"           },
}
-- NOTE: this tab's id ("pvp") is never reachable through TA:SlashCommand's
-- tabShortcuts table (Core/Init.lua) — "/ta pvp" is already claimed there by
-- the PvP-*mode* toggle (cmd == "pvp"), which returns before tabShortcuts is
-- even consulted. Opening this tab is mouse-only; there is no slash shortcut
-- for it the way there is for every other tab.

-- Which events warrant rebuilding which tab. An event absent from every list
-- refreshes nothing, which is the point — COMBAT_RATING_UPDATE fires often.
local TAB_EVENTS = {
    character = { PLAYER_LEVEL_UP=true, UNIT_INVENTORY_CHANGED=true, PLAYER_EQUIPMENT_CHANGED=true,
                  COMBAT_RATING_UPDATE=true, UNIT_STATS=true, UNIT_ATTACK_POWER=true,
                  CHARACTER_POINTS_CHANGED=true },
    caps      = { PLAYER_LEVEL_UP=true, PLAYER_EQUIPMENT_CHANGED=true, COMBAT_RATING_UPDATE=true,
                  SKILL_LINES_CHANGED=true, PLAYER_TARGET_CHANGED=true, UNIT_STATS=true },
    gear      = { UNIT_INVENTORY_CHANGED=true, PLAYER_EQUIPMENT_CHANGED=true, BAG_UPDATE=true,
                  GET_ITEM_INFO_RECEIVED=true, COMBAT_RATING_UPDATE=true },
    weapons   = { SKILL_LINES_CHANGED=true, PLAYER_EQUIPMENT_CHANGED=true, PLAYER_LEVEL_UP=true },
    racials   = { PLAYER_LEVEL_UP=true },
    profs     = { SKILL_LINES_CHANGED=true, PLAYER_LEVEL_UP=true },
    pvp       = { PLAYER_EQUIPMENT_CHANGED=true, COMBAT_RATING_UPDATE=true, PLAYER_LEVEL_UP=true },
    petcare   = { UNIT_PET=true, BAG_UPDATE=true, GET_ITEM_INFO_RECEIVED=true, PLAYER_LEVEL_UP=true, SPELLS_CHANGED=true },
}

-- ─── Backdrop compatibility ──────────────────────────────────────────────────
-- TBC Classic runs a client where SetBackdrop lives on BackdropTemplateMixin
-- rather than the base Frame API. Frames created with no template have no
-- SetBackdrop, and calling it is a hard error that would kill InitUI — which is
-- exactly what happened on the first MoP Classic login of the _classic_ build.
--
-- The mixin is applied after creation rather than passing a template string,
-- because an unknown template is itself a hard error and this client's template
-- list is not measured. Either way the addon keeps loading: worst case the
-- panel renders unstyled, and the fact is logged instead of looking like a
-- cosmetic bug.
local FLAT_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function EnsureBackdrop(frame)
    if frame.SetBackdrop then return true end

    if type(Mixin) == "function" and type(BackdropTemplateMixin) == "table" then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropLoaded then frame:OnBackdropLoaded() end
    end

    if not frame.SetBackdrop then
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
TA._ApplyBackdrop  = ApplyBackdrop

-- ─── Frame pool ──────────────────────────────────────────────────────────────
-- WoW never garbage-collects a frame, so scroll children are recycled rather
-- than abandoned on every refresh.
--
-- KNOWN LIMITATION, stated rather than hidden: only the scroll CHILD is pooled.
-- The rows, bars and buttons a Render() creates inside it are hidden and
-- unparented, not reused, so each refresh does allocate new frames. This is the
-- pattern the retail and _classic_ builds already use, kept here for
-- consistency, and it is tolerable because every event that reaches a tab is
-- state-changing (gear swap, level, skill tick, target change) rather than
-- periodic — nothing here refreshes on a timer. A real per-widget pool is the
-- correct fix if the Character or Gear tab is ever left open through a long
-- fight; it is not needed for the current event set.
local _framePool = { content = {}, side = {} }

local function RebuildChild(scrollFrame, width)
    local key = (width > 200) and "content" or "side"

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
        table.insert(_framePool[key], old)
    end

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

-- ─── UI OBJECT ───────────────────────────────────────────────────────────────

function TA:InitUI()
    if self.UI then return end

    local f = CreateFrame("Frame", "ToonAgeMainFrame", UIParent)
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    -- DIALOG, not HIGH: the _ptr_ build's bug list opens with "other addons
    -- bleed through", and this client runs ElvUI. A fully opaque backdrop on a
    -- DIALOG-strata frame is what stops that.
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    ApplyBackdrop(f, 0.05, 0.04, 0.02, 1.00, 0.55, 0.40, 0.08, 1.00)
    f:Hide()

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    tinsert(UISpecialFrames, "ToonAgeMainFrame")

    -- ── Title bar ─────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(TITLEBAR_H)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 14, 0)
    titleText:SetText("|cFFFFD100ToonAge|r |cFF888780Anniversary|r")

    f.contextLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.contextLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.contextLabel:SetPoint("RIGHT", titleBar, "RIGHT", -30, 0)
    f.contextLabel:SetTextColor(0.62, 0.59, 0.55, 1)

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Tab bar ───────────────────────────────────────────────────────
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetHeight(TAB_HEIGHT)
    tabBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)

    f.tabButtons = {}
    local tabWidth = math.floor((FRAME_WIDTH - SIDEBAR_WIDTH) / #TABS)
    for i, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tabWidth, TAB_HEIGHT)
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", math.floor((i - 1) * tabWidth), 0)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        btn.label = label

        local underline = btn:CreateTexture(nil, "ARTWORK")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  6, 0)
        underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)
        underline:SetColorTexture(1, 0.82, 0, 1)
        underline:Hide()
        btn.underline = underline

        btn:SetScript("OnClick", function() f:SetTab(tab.id) end)
        btn.tabID = tab.id
        f.tabButtons[i] = btn
    end

    -- ── Sidebar ───────────────────────────────────────────────────────
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(TITLEBAR_H + TAB_HEIGHT + 1))
    sidebar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    ApplyBackdrop(sidebar, 0.03, 0.03, 0.02, 1.00, 0.35, 0.28, 0.06, 0.60)
    f.sidebar = sidebar

    -- WARN: unlike contentScroll below, this ScrollFrame gets no
    -- EnableMouseWheel/OnMouseWheel handler and no scrollbar template. If a
    -- tab's Render() ever puts more into the sidebar than SIDEBAR_WIDTH x
    -- (frame height) can show, the overflow is simply unreachable — there is
    -- no way to scroll down to it.
    local sideScroll = CreateFrame("ScrollFrame", nil, sidebar)
    sideScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, -4)
    sideScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -4, 4)
    f.sideScroll = sideScroll

    -- ── Content area ──────────────────────────────────────────────────
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -(TITLEBAR_H + TAB_HEIGHT + 1))
    content:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMLEFT", 0, 0)
    f.content = content

    local contentScroll = CreateFrame("ScrollFrame", nil, content)
    contentScroll:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, -CONTENT_PAD)
    contentScroll:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -CONTENT_PAD, CONTENT_PAD)
    contentScroll:EnableMouseWheel(true)
    contentScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(current - (delta * 40), maxScroll)))
    end)
    f.contentScroll = contentScroll

    -- ── Methods ───────────────────────────────────────────────────────
    -- WARN: TA.db.lastTab is trusted as-is from SavedVariables with no check
    -- that it still names a tab in TABS above. If a saved value from an older
    -- build (or a future removal of a tab) no longer matches any tab.id, both
    -- the highlight loop in SetTab and the render loop in Refresh silently
    -- match nothing — no tab underlined, no content drawn, no error printed.
    -- Falling back to TABS[1].id when the lookup fails would be one line;
    -- right now it only guards against lastTab being absent, not being stale.
    f.activeTab = TA.db and TA.db.lastTab or TABS[1].id

    function f:SetTab(tabID)
        self.activeTab = tabID
        if TA.db then TA.db.lastTab = tabID end

        for _, btn in ipairs(self.tabButtons) do
            if btn.tabID == tabID then
                btn.label:SetTextColor(1, 0.82, 0, 1)
                btn.underline:Show()
            else
                btn.label:SetTextColor(0.62, 0.59, 0.55, 1)
                btn.underline:Hide()
            end
        end

        self:Refresh()
    end

    function f:IsVisible()
        return self:IsShown()
    end

    --- The label in the title bar naming which target the caps assume. Without
    --- it, "you need 4.2% more hit" is an unattributed number.
    function f:UpdateContextLabel()
        local S = TA.TBCStats
        if not S then return end
        local ctx = S:ActiveContext()
        if TA.db and TA.db.pvpMode then
            self.contextLabel:SetText(string.format(
                "|cFFFF6E6EPvP|r · caps vs %s  |cFF555049(/ta pvp)|r", ctx.label))
        else
            self.contextLabel:SetText(string.format("caps vs %s  |cFF555049(/ta context)|r", ctx.label))
        end
    end

    function f:Refresh(events)
        if events then
            local tabEvts = TAB_EVENTS[self.activeTab]
            local relevant = false
            for evt in pairs(events) do
                if tabEvts and tabEvts[evt] then relevant = true break end
            end
            if not relevant then return end
        end

        self:UpdateContextLabel()

        -- FIXME: `or` does not catch 0 — 0 is truthy in Lua, unlike most other
        -- languages. If GetWidth() ever returns 0 (plausible on the very
        -- first Refresh, called from SetTab at the end of InitUI, before the
        -- frame hierarchy has completed a layout pass) this expression keeps
        -- the 0 instead of falling back to the computed width, and
        -- RebuildChild gets called with width 0 — a zero-width scroll child
        -- that Render() draws into but nothing can be seen. Needs an explicit
        -- `(width and width > 0) and width or fallback` check, not `or`.
        local contentWidth = math.floor(self.contentScroll:GetWidth() or
            (FRAME_WIDTH - SIDEBAR_WIDTH - CONTENT_PAD * 2))
        local sideWidth = SIDEBAR_WIDTH - 8

        self.contentChild = RebuildChild(self.contentScroll, contentWidth)
        self.sideChild    = RebuildChild(self.sideScroll, sideWidth)

        for _, tab in ipairs(TABS) do
            if tab.id == self.activeTab then
                local mod = TA:GetModule(tab.module)
                if not mod then
                    TA.Layout:EmptyState(self.contentChild,
                        "The " .. tab.label .. " module is not loaded.")
                elseif mod._disabled then
                    TA.Layout:EmptyState(self.contentChild,
                        tab.label .. " is disabled.  |cFFFFD100/ta toggle " .. tab.module .. "|r")
                elseif mod.Render then
                    local ok, err = pcall(mod.Render, mod, self.contentChild, self.sideChild)
                    if not ok then
                        TA:Printf(TA.LOG.ERROR, nil, "Render error (%s): %s", tab.module, tostring(err))
                        if TA.ErrorLog then TA.ErrorLog:Log(tab.module .. " Render", tostring(err), "") end
                        TA.Layout:EmptyState(self.contentChild,
                            "|cFFFF4444" .. tab.label .. " failed to draw.|r  /ta errors")
                    end
                end
                break
            end
        end
    end

    f:SetTab(f.activeTab)
    self.UI = f
end
