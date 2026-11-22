-- ToonAge/Core/UI.lua
-- Main frame, tab bar, sidebar, WoW-native styling

local TA = ToonAge
local U  = TA.Utils

-- ── Constants ─────────────────────────────────────────────────────────
local FRAME_WIDTH        = 900
local FRAME_HEIGHT       = 580
local SIDEBAR_WIDTH      = 210
local TAB_HEIGHT_CLASSIC = 30
local TAB_HEIGHT_MODERN  = 34   -- 34 title + 34 tabs = 68px Modern Azeroth crown
local TITLEBAR_H         = 34
local CONTENT_PAD        = 14   -- internal padding for content area
local ROW_PAD            = 6    -- extra vertical space between rows

-- Ordered for flow: your build (Character/Gear/Talents/Rotation), then
-- what to do with it (Delves/Weekly), then side systems (Professions/Pets).
local DEFAULT_TABS = {
    { id = "character",   label = "Character",   module = "Character"   },
    { id = "guide",       label = "Guide",       module = "QuestTracker" },
    { id = "reputations", label = "Reputation",  module = "FactionTracker" },
    { id = "gear",        label = "Gear",        module = "Gear"        },
    { id = "talents",     label = "Talents",     module = "Talents"     },
    { id = "rotation",    label = "Rotation",    module = "Rotation"    },
    { id = "delves",      label = "Delves",      module = "Delves"      },
    { id = "weekly",      label = "Weekly",      module = "Weekly"      },
    { id = "professions", label = "Professions", module = "Professions" },
    { id = "pets",        label = "Pets",        module = "Pets"        },
}

local ICON_DIR  = "Interface\\AddOns\\ToonAge\\Media\\icons\\"
local GLASS_DIR = "Interface\\AddOns\\ToonAge\\Media\\glass\\"

-- Monochrome white silhouettes tinted via SetVertexColor. Modern Azeroth shows
-- glyphs on every tab; Classic keeps the original three.
local TAB_GLYPH = {
    now         = ICON_DIR .. "tab_now_32.tga",
    character   = ICON_DIR .. "tab_character_32.tga",
    gear        = ICON_DIR .. "tab_gear_32.tga",
    professions = ICON_DIR .. "tab_professions_32.tga",
    reputations = ICON_DIR .. "tab_reputation_32.tga",
    talents     = ICON_DIR .. "tab_talents_32.tga",
    spells      = ICON_DIR .. "tab_spells_32.tga",
    pets        = ICON_DIR .. "tab_pets_32.tga",
    pvp         = ICON_DIR .. "tab_pvp_32.tga",
    scrolls     = ICON_DIR .. "tab_scrolls_32.tga",
    casts       = ICON_DIR .. "tab_casts_32.tga",
    harvest     = ICON_DIR .. "tab_harvest_32.tga",
    guide       = ICON_DIR .. "tab_guide_32.tga",
    rotation    = ICON_DIR .. "tab_rotation_32.tga",
    delves      = ICON_DIR .. "tab_delves_32.tga",
    weekly      = ICON_DIR .. "tab_weekly_32.tga",
    caps        = ICON_DIR .. "tab_caps_32.tga",
    weapons     = ICON_DIR .. "tab_weapons_32.tga",
    racials     = ICON_DIR .. "tab_racials_32.tga",
}
local CLASSIC_TAB_GLYPH = {
    professions = true,
    pets        = true,
    racials     = true,
}
local TAB_GLYPH_PX = 20

local function IsModernSkin()
    return TA.Theme and TA.Theme.active and TA.Theme.active.name == "modern_azeroth"
end

local function ActiveTabHeight()
    return IsModernSkin() and TAB_HEIGHT_MODERN or TAB_HEIGHT_CLASSIC
end

local function ActiveAccent()
    local a = TA.Theme and TA.Theme.active and TA.Theme.active.accent
    if type(a) == "table" and type(a.primary) == "table" then
        return a.primary
    end
    return { 0.40, 0.75, 1.00, 1.00 }
end

local function TintTab(btn, hot, isActive)
    local modern = IsModernSkin()
    local accent = ActiveAccent()
    local r, g, b
    if modern then
        if isActive then
            r, g, b = 0.961, 0.969, 0.980
        elseif hot then
            r, g, b = 0.788, 0.804, 0.824
        else
            r, g, b = 0.549, 0.576, 0.604
        end
    else
        r, g, b = 0.55, 0.52, 0.48
        if hot or isActive then r, g, b = 0.92, 0.90, 0.87 end
    end
    if btn.label then btn.label:SetTextColor(r, g, b, 1) end
    if btn.glyph and btn.glyph.SetVertexColor then
        if modern and isActive then
            btn.glyph:SetVertexColor(accent[1], accent[2], accent[3], 1)
        else
            btn.glyph:SetVertexColor(r, g, b, 1)
        end
    end
    if btn.activeLine then
        if modern then
            btn.activeLine:SetColorTexture(accent[1], accent[2], accent[3], 1.00)
        else
            btn.activeLine:SetColorTexture(0.40, 0.75, 1.00, 1.00)
        end
    end
    if btn.hoverBg then
        if modern and isActive then
            btn.hoverBg:SetColorTexture(accent[1], accent[2], accent[3], 0.14)
            btn.hoverBg:Show()
        elseif modern and hot then
            btn.hoverBg:SetColorTexture(1, 1, 1, 0.06)
            btn.hoverBg:Show()
        else
            btn.hoverBg:Hide()
        end
    end
end

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

local function ApplyDrawerTheme(drawer)
    if not drawer then return end
    if IsModernSkin() then
        local t = TA.Theme.active
        local fill = (t.glass and t.glass.sheet_fill) or { 0.063, 0.094, 0.133, 0.86 }
        local rim  = (t.glass and t.glass.sheet_rim) or { 1, 1, 1, 0.16 }
        ApplyBackdrop(drawer, fill[1], fill[2], fill[3], fill[4], rim[1], rim[2], rim[3], rim[4])
    else
        ApplyBackdrop(drawer, 0.04, 0.04, 0.05, 0.97, 0.55, 0.40, 0.08, 0.80)
    end
end

-- ── Clean a frame's content completely ───────────────────────────────
-- WoW's GetChildren() only returns Frame objects, not FontStrings or
-- Textures. To truly clear a content pane we destroy and recreate it.
-- Frame recycler pool (file-scope, persists across tab switches)
local _framePool = { content = {}, side = {} }

local function RebuildChild(scrollFrame, width, preserveScroll)
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
    if not preserveScroll then
        scrollFrame:SetVerticalScroll(0)
    end
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

--- Character when this flavor has it, otherwise the first tab that is on.
--- A scaffold that ships only Professions must not open onto a missing
--- Character tab and draw nothing.
local function FallbackTab(preferred)
    if preferred and IsTabEnabled(preferred) then return preferred end
    if IsTabEnabled("character") then return "character" end
    for _, t in ipairs(GetTabs()) do
        if IsTabEnabled(t.id) then return t.id end
    end
    return preferred or "character"
end

--- Tab exists on this client (flavor tab set + module loaded).
function TA:IsTabAvailable(tabID) return FindTab(tabID) ~= nil end
--- Tab exists AND the player hasn't switched it off in options.
function TA:IsTabEnabled(tabID) return IsTabEnabled(tabID) end

function TA:InitUI()
    if self.UI then return end
    self.db = self.db or {}
    self.charDB = self.charDB or {}
    self.db.disabledTabs = self.db.disabledTabs or {}

    -- Activate saved or default Modern Azeroth skin + Class Color accent pack.
    if self.Theme and self.Theme.Select then
        local skin = self.db.themeSkin or "modern_azeroth"
        local pack = self.db.themePack or "class"
        if self.Theme.SetReducedMotion then
            self.Theme:SetReducedMotion(self.db.reducedMotion == true)
        end
        self.Theme:Select(skin, pack)
    end

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
    ApplyBackdrop(frame, 0.05, 0.05, 0.06, 0.94)
    frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)
    frame:Hide()
    -- Esc closes the window (UISpecialFrames is how every Blizzard panel does it).
    -- The frame's Hide override below also closes the settings drawer.
    tinsert(UISpecialFrames, "ToonAgeFrame")

    -- ── Title bar (34px) ──────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(TITLEBAR_H)
    ApplyBackdrop(titleBar, 0.10, 0.10, 0.12, 1.00)

    -- Subtle top specular sheen for Liquid Glass crown (hidden on classic)
    local specTop = titleBar:CreateTexture(nil, "ARTWORK")
    specTop:SetPoint("TOPLEFT",  titleBar, "TOPLEFT",  1, -1)
    specTop:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -1, -1)
    specTop:SetHeight(16)
    specTop:SetTexture(GLASS_DIR .. "spec_top.tga")
    specTop:Hide()
    titleBar.specTop = specTop

    local titleRule = titleBar:CreateTexture(nil, "OVERLAY")
    titleRule:SetHeight(1)
    titleRule:SetPoint("BOTTOMLEFT",  titleBar, "BOTTOMLEFT",  1, 0)
    titleRule:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -1, 0)
    titleRule:SetColorTexture(1, 1, 1, 0.08)
    titleRule:Hide()
    titleBar.bottomRule = titleRule

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    titleBar.titleIcon = titleIcon

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    titleLabel:SetText("ToonAge")
    titleLabel:SetTextColor(0.92, 0.90, 0.87, 1.00)
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", 34, 0)
    titleBar.titleLabel = titleLabel

    local versionLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    local FLAVOR_NAME = {
        retail = "Midnight", tbc = "TBC Anniversary", mists = "Mists Classic",
        vanilla = "Classic Era", wrath = "Wrath Classic", cata = "Cataclysm Classic",
        forever = "Forever",
    }
    local build = (GetBuildInfo and select(1, GetBuildInfo())) or ""
    versionLabel:SetText("v" .. TA.version .. "  ·  "
        .. (FLAVOR_NAME[TA.flavor] or "WoW") .. (build ~= "" and (" " .. build) or ""))
    versionLabel:SetTextColor(0.55, 0.52, 0.45, 1.00)
    titleBar.versionLabel = versionLabel

    -- Custom 24x24 r6 window controls (no macOS traffic lights, no red Blizzard chrome).
    local function StyleControlPlate(btn, hover, isClose)
        if not btn.plate then return end
        if IsModernSkin() then
            btn.plate:Show()
            if hover then
                if isClose then
                    btn.plate:SetVertexColor(0.75, 0.24, 0.24, 0.72)
                else
                    local ac = ActiveAccent()
                    btn.plate:SetVertexColor(ac[1] * 0.30, ac[2] * 0.30, ac[3] * 0.30, 0.92)
                end
            else
                btn.plate:SetVertexColor(0.08, 0.12, 0.16, 0.85)
            end
        else
            if isClose then
                btn.plate:Show()
                btn.plate:SetVertexColor(hover and 0.65 or 0.42, 0.14, 0.14, 0.90)
            else
                btn.plate:Hide()
            end
        end
    end

    -- Right-to-left anchor chain: Close -> Options -> Help -> Copy -> Version
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -6, -5)
    closeBtn.plate = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBtn.plate:SetAllPoints()
    closeBtn.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
    closeBtn.icon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeBtn.icon:SetSize(12, 12)
    closeBtn.icon:SetPoint("CENTER")
    closeBtn.icon:SetTexture(ICON_DIR .. "util_close_16.tga")
    closeBtn.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
    closeBtn:SetScript("OnEnter", function(self)
        StyleControlPlate(self, true, true)
        self.icon:SetVertexColor(0.98, 0.98, 0.99, 1)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText("Close ToonAge", 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    closeBtn:SetScript("OnLeave", function(self)
        StyleControlPlate(self, false, true)
        self.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
        if GameTooltip then GameTooltip:Hide() end
    end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.closeBtn = closeBtn

    local optionsBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    frame.optionsBtn = optionsBtn   -- read by the self-test's settings suite (G9 check)
    optionsBtn:SetSize(24, 24)
    optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    optionsBtn.plate = optionsBtn:CreateTexture(nil, "BACKGROUND")
    optionsBtn.plate:SetAllPoints()
    optionsBtn.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
    optionsBtn.texIcon = optionsBtn:CreateTexture(nil, "ARTWORK")
    optionsBtn.texIcon:SetSize(14, 14)
    optionsBtn.texIcon:SetPoint("CENTER")
    optionsBtn.texIcon:SetTexture(ICON_DIR .. "util_settings_16.tga")
    optionsBtn.texIcon:SetVertexColor(0.79, 0.80, 0.82, 1)

    -- Help (?) and Copy chat: useful from every tab, so they live here rather
    -- than on one tab. Each runs the /ta command of the same name.
    local function TitleButton(anchor, text, width, tip, cmd)
        local b = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
        b.plate = b:CreateTexture(nil, "BACKGROUND")
        b.plate:SetAllPoints()
        b.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        fs:SetText(text)
        local textW = (fs.GetStringWidth and fs:GetStringWidth()) or width
        b:SetSize(math.max(textW + 14, width), 24)
        b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        fs:SetTextColor(0.62, 0.59, 0.55, 1)
        fs:SetAllPoints(b)
        fs:SetJustifyH("CENTER")
        b.label = fs
        b:SetScript("OnEnter", function(self)
            StyleControlPlate(self, true, false)
            fs:SetTextColor(0.96, 0.97, 0.98, 1)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tip, 1, 0.82, 0)
                GameTooltip:AddLine("/ta " .. cmd, 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function(self)
            StyleControlPlate(self, false, false)
            if IsModernSkin() then
                fs:SetTextColor(0.79, 0.80, 0.82, 1)
            else
                fs:SetTextColor(0.62, 0.59, 0.55, 1)
            end
            if GameTooltip then GameTooltip:Hide() end
        end)
        b:SetScript("OnClick", function() TA:SlashCommand(cmd) end)
        return b
    end
    local helpBtn = TitleButton(optionsBtn, "?", 24, "Commands", "help")
    local copyBtn = TitleButton(helpBtn, "Copy", 48, "Copy chat", "copy")
    frame.helpBtn = helpBtn
    frame.copyBtn = copyBtn

    versionLabel:SetPoint("RIGHT", copyBtn, "LEFT", -10, 0)
    versionLabel:SetWidth(165)
    versionLabel:SetJustifyH("RIGHT")
    versionLabel:SetWordWrap(false)
    local versionFull = versionLabel:GetText() or ""
    local versionHit = CreateFrame("Button", nil, titleBar)
    versionHit:SetAllPoints(versionLabel)
    versionHit:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(versionFull, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    versionHit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local optIcon = optionsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optIcon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    optIcon:SetText((ToonAge.Utils and ToonAge.Utils.Glyph and ToonAge.Utils.Glyph("settings")) or "*")
    optIcon:SetTextColor(0.62, 0.59, 0.55, 1)
    optIcon:SetAllPoints(optionsBtn)
    optIcon:SetJustifyH("CENTER")
    optionsBtn.optIcon = optIcon
    optionsBtn:SetScript("OnEnter", function(self)
        StyleControlPlate(self, true, false)
        if IsModernSkin() then
            self.texIcon:SetVertexColor(0.96, 0.97, 0.98, 1)
        else
            optIcon:SetTextColor(0.92, 0.90, 0.87, 1)
        end
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText("Settings & Theme Packs", 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    optionsBtn:SetScript("OnLeave", function(self)
        StyleControlPlate(self, false, false)
        if IsModernSkin() then
            self.texIcon:SetVertexColor(0.79, 0.80, 0.82, 1)
        else
            optIcon:SetTextColor(0.62, 0.59, 0.55, 1)
        end
        if GameTooltip then GameTooltip:Hide() end
    end)
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

    -- ── Tab bar (34px on Modern Azeroth = 68px crown; 30px on Classic) ─
    local tabBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, -TITLEBAR_H)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -TITLEBAR_H)
    tabBar:SetHeight(ActiveTabHeight())
    ApplyBackdrop(tabBar, 0.07, 0.07, 0.09, 1.00)

    local tabRule = tabBar:CreateTexture(nil, "OVERLAY")
    tabRule:SetHeight(1)
    tabRule:SetPoint("BOTTOMLEFT",  tabBar, "BOTTOMLEFT",  1, 0)
    tabRule:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", -1, 0)
    tabRule:SetColorTexture(1, 1, 1, 0.10)
    tabRule:Hide()
    tabBar.bottomRule = tabRule

    -- ── Sidebar (elevated solid dark well on Modern Azeroth) ──────────
    local sidebarTop = -(TITLEBAR_H + ActiveTabHeight())
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

    -- ── Solid dark content well (zero glass-on-glass on Modern Azeroth)
    local contentLeft = SIDEBAR_WIDTH + 1
    local contentWidth = FRAME_WIDTH - contentLeft - 22  -- 22 = scrollbar width

    local contentWell = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentWell:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, sidebarTop)
    contentWell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    ApplyBackdrop(contentWell, 0.043, 0.055, 0.071, 0.96, 0.043, 0.055, 0.071, 0.00)
    contentWell:Hide()

    local contentScroll = CreateFrame("ScrollFrame", "TAContentScrollFrame", frame, "UIPanelScrollFrameTemplate")
    contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, sidebarTop)
    contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)

    local contentChild = CreateFrame("Frame", nil, contentScroll)
    contentChild:SetSize(contentWidth, 400)
    contentScroll:SetScrollChild(contentChild)

    -- ── Store references ──────────────────────────────────────────────
    frame.titleBar      = titleBar
    frame.tabBar        = tabBar
    frame.sidebar       = sidebar
    frame.contentWell   = contentWell
    frame.sideScroll    = sideScroll
    frame.contentScroll = contentScroll
    frame.contentWidth  = contentWidth
    frame.sideWidth     = SIDEBAR_WIDTH - 26
    frame.tabButtons    = {}
    frame.activeTab     = nil
    frame._styleControlPlate = StyleControlPlate
    -- Keep live references (rebuilt on each tab switch)
    frame.sideChild     = sideChild
    frame.contentChild  = contentChild

    -- ── SetTab ────────────────────────────────────────────────────────
    -- Defined BEFORE RebuildTabs so RebuildTabs can call self:SetTab()
    -- at the end of its run without getting a nil-value error.
    function frame:SetTab(tabID)
        -- A saved lastTab may point at a tab the player has since disabled
        -- (e.g. from a previous session) -- fall back to the always-on tab.
        tabID = FallbackTab(tabID)

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
            TintTab(btn, isActive, isActive)
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
        -- that GetChildren() misses. When refreshing the SAME tab, keep the
        -- scroll position intact so the pane never flashes to scroll=0.
        self.contentChild = RebuildChild(self.contentScroll, self.contentWidth, sameTab)
        self.sideChild    = RebuildChild(self.sideScroll,    self.sideWidth,    sameTab)

        -- Restored right after the module renders below (synchronously first
        -- to eliminate any 1-frame snap to the top, plus a 0s fallback).
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

            -- Restore scroll immediately in the same frame so there is zero
            -- flash to the top, then confirm on the next frame if layout grew.
            if self._restoreScroll then
                local want, sf = self._restoreScroll, self.contentScroll
                self._restoreScroll = nil
                local function ApplyScroll()
                    if not (sf and sf.GetVerticalScrollRange) then return end
                    if sf.UpdateScrollChildRect then pcall(sf.UpdateScrollChildRect, sf) end
                    local maxScroll = sf:GetVerticalScrollRange() or 0
                    if maxScroll <= 0 then return end
                    sf:SetVerticalScroll(math.min(want, maxScroll))
                end
                ApplyScroll()
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, ApplyScroll)
                end
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
            local topY = -(TITLEBAR_H + ActiveTabHeight())
            if sideEmpty then
                self.sidebar:Hide()
                self.contentScroll:ClearAllPoints()
                self.contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     1, topY)
                self.contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
                if self.contentWell then
                    self.contentWell:ClearAllPoints()
                    self.contentWell:SetPoint("TOPLEFT",     frame, "TOPLEFT",     1, topY)
                    self.contentWell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
                end
                -- Update content child width for the wider area
                local fullW = FRAME_WIDTH - 1 - 22
                self.contentChild:SetWidth(fullW)
                self.contentWidth = fullW
            else
                -- Restore standard sidebar + content layout
                self.sidebar:Show()
                self.contentScroll:ClearAllPoints()
                local contentLeft = SIDEBAR_WIDTH + 1
                self.contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, topY)
                self.contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
                if self.contentWell then
                    self.contentWell:ClearAllPoints()
                    self.contentWell:SetPoint("TOPLEFT",     frame, "TOPLEFT",     contentLeft, topY)
                    self.contentWell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
                end
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

    -- Events that no tab renders: combat/nameplate/aura/power churn, cinematics,
    -- loot-chat, and death/res transitions. Any tab that explicitly claims one
    -- of these in TAB_EVENTS still refreshes; unclaimed tabs skip the rebuild.
    local UI_IRRELEVANT = {
        NAME_PLATE_UNIT_ADDED = true, NAME_PLATE_UNIT_REMOVED = true,
        UNIT_AURA = true, UNIT_POWER_UPDATE = true, SPELL_UPDATE_COOLDOWN = true,
        CHAT_MSG_LOOT = true, CHAT_MSG_COMBAT_XP_GAIN = true, START_LOOT_ROLL = true,
        PLAYER_CONTROL_LOST = true, PLAYER_CONTROL_GAINED = true,
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
            -- Never rebuild the active tab out from under the user while they
            -- are typing in one of its EditBoxes (e.g. Professions Batch inputs).
            if type(GetCurrentKeyBoardFocus) == "function" and self.contentChild then
                local focus = GetCurrentKeyBoardFocus()
                local cur = focus
                for _ = 1, 6 do
                    if not cur then break end
                    if cur == self.contentChild then return end
                    cur = cur.GetParent and cur:GetParent() or nil
                end
            end
        end

        self:SetTab(self.activeTab)
    end

    -- ── Show: open to last tab (or Now lead tab when available) ───────
    local origShow = frame.Show
    function frame:Show()
        origShow(self)
        -- Tabs may have changed while the window was closed (respec, pet).
        if self._tabSig ~= TabSignature() then self:RebuildTabs() end
        local defaultTab = IsTabEnabled("now") and "now" or "guide"
        self:SetTab(TA.charDB.lastTab or defaultTab)
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

    -- ── ApplyTheme — live re-skin (Modern Azeroth <-> Classic, packs) ─
    function frame:ApplyTheme()
        local modern = IsModernSkin()
        local tabH = ActiveTabHeight()
        local topY = -(TITLEBAR_H + tabH)
        local accent = ActiveAccent()
        local activeTheme = TA.Theme and TA.Theme.active

        tabBar:SetHeight(tabH)
        sidebar:ClearAllPoints()
        sidebar:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, topY)
        sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

        local leftX = (sidebar.IsShown and not sidebar:IsShown()) and 1 or (SIDEBAR_WIDTH + 1)
        contentScroll:ClearAllPoints()
        contentScroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     leftX, topY)
        contentScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
        contentWell:ClearAllPoints()
        contentWell:SetPoint("TOPLEFT",     frame, "TOPLEFT",     leftX, topY)
        contentWell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

        if modern and activeTheme and type(activeTheme.glass) == "table" then
            local g = activeTheme.glass
            local sf = g.shell_fill or { 0.059, 0.090, 0.122, 0.78 }
            local sr = g.shell_rim  or { 1.000, 1.000, 1.000, 0.16 }
            local bg = activeTheme.bg or {}
            local sb = bg.sidebar   or { 0.055, 0.075, 0.102, 0.96 }
            local cw = bg.content   or { 0.043, 0.055, 0.071, 0.96 }

            ApplyBackdrop(frame, sf[1], sf[2], sf[3], sf[4], sr[1], sr[2], sr[3], sr[4])
            if TA.Modern and TA.Modern.ApplyGlassBackdrop then
                pcall(TA.Modern.ApplyGlassBackdrop, TA.Modern, frame, {
                    baseTint = sf, borderColor = sr, noFrost = true,
                })
            end
            ApplyBackdrop(titleBar, sf[1], sf[2], sf[3], sf[4], 1, 1, 1, 0)
            ApplyBackdrop(tabBar,   sf[1], sf[2], sf[3], math.min(sf[4] + 0.04, 0.90), 1, 1, 1, 0)
            ApplyBackdrop(sidebar,  sb[1], sb[2], sb[3], sb[4], 1, 1, 1, 0.08)
            ApplyBackdrop(contentWell, cw[1], cw[2], cw[3], cw[4], cw[1], cw[2], cw[3], 0)
            contentWell:Show()

            titleBar.specTop:Show()
            titleBar.bottomRule:Show()
            tabBar.bottomRule:Show()

            titleBar.titleIcon:SetTexture(ICON_DIR .. "logo_mark_32.tga")
            titleBar.titleIcon:SetTexCoord(0, 1, 0, 1)
            if titleBar.titleIcon.SetVertexColor then
                -- logo_mark_32.tga is full-colour brand art (MEDIA.md); never re-tint.
                titleBar.titleIcon:SetVertexColor(1, 1, 1, 1)
            end
            titleBar.titleLabel:SetTextColor(0.961, 0.969, 0.980, 1)
            titleBar.versionLabel:SetTextColor(0.549, 0.576, 0.604, 1)

            if optionsBtn.texIcon then optionsBtn.texIcon:Show() end
            if optionsBtn.optIcon then optionsBtn.optIcon:Hide() end
            helpBtn.label:SetTextColor(0.788, 0.804, 0.824, 1)
            copyBtn.label:SetTextColor(0.788, 0.804, 0.824, 1)
        else
            ApplyBackdrop(frame, 0.05, 0.05, 0.06, 0.94, 0.30, 0.30, 0.35, 1.00)
            if TA.Modern and TA.Modern.ApplyGlassBackdrop then
                pcall(TA.Modern.ApplyGlassBackdrop, TA.Modern, frame)
            end
            ApplyBackdrop(titleBar, 0.10, 0.10, 0.12, 1.00, 0.30, 0.30, 0.35, 0.70)
            ApplyBackdrop(tabBar,   0.07, 0.07, 0.09, 1.00, 0.30, 0.30, 0.35, 0.70)
            ApplyBackdrop(sidebar,  0.05, 0.05, 0.06, 0.96, 0.30, 0.30, 0.35, 0.70)
            contentWell:Hide()

            titleBar.specTop:Hide()
            titleBar.bottomRule:Hide()
            tabBar.bottomRule:Hide()

            titleBar.titleIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Female")
            titleBar.titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if titleBar.titleIcon.SetVertexColor then
                titleBar.titleIcon:SetVertexColor(1, 1, 1, 1)
            end
            titleBar.titleLabel:SetTextColor(0.92, 0.90, 0.87, 1)
            titleBar.versionLabel:SetTextColor(0.55, 0.52, 0.45, 1)

            if optionsBtn.texIcon then optionsBtn.texIcon:Hide() end
            if optionsBtn.optIcon then optionsBtn.optIcon:Show() end
            helpBtn.label:SetTextColor(0.62, 0.59, 0.55, 1)
            copyBtn.label:SetTextColor(0.62, 0.59, 0.55, 1)
        end

        StyleControlPlate(closeBtn, false, true)
        StyleControlPlate(optionsBtn, false, false)
        StyleControlPlate(helpBtn, false, false)
        StyleControlPlate(copyBtn, false, false)

        for id, btn in pairs(self.tabButtons) do
            local isActive = (id == self.activeTab)
            TintTab(btn, isActive, isActive)
        end
        if TA._settingsDrawer then ApplyDrawerTheme(TA._settingsDrawer) end
    end

    -- ── RebuildTabs — callable at any time (e.g. from options panel) ──
    -- Destroys all existing tab buttons and recreates them from the current
    -- disabledTabs state, then re-selects the active tab (or "now"/"character"
    -- if it was disabled). Called once at init, then again any time the
    -- player toggles a tab in the options panel or switches skins.
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

        local modern = IsModernSkin()
        local tabH = ActiveTabHeight()
        tabBar:SetHeight(tabH)

        -- The Guide Tracker drawer follows the Guide tab: no tab, no drawer.
        if TA.Modern and TA.Modern.UpdateDrawerAvailability then
            pcall(TA.Modern.UpdateDrawerAvailability, TA.Modern)
        end

        local enabledTabs = {}
        for _, tabDef in ipairs(GetTabs()) do
            if IsTabEnabled(tabDef.id) then
                enabledTabs[#enabledTabs + 1] = tabDef
            end
        end

        -- Measure natural width first so 11-12 Forever tabs fit cleanly inside 900px
        -- without overflowing off the right edge.
        local barAvail = FRAME_WIDTH - 16
        local glyphPx = modern and 14 or TAB_GLYPH_PX
        local padLeft = modern and 7 or 6
        local padGap  = 4
        local padRight = modern and 8 or 8
        local tabGap = 2

        local created = {}
        local totalW = 0
        for _, tabDef in ipairs(enabledTabs) do
            local btn = CreateFrame("Button", nil, tabBar)
            btn:SetHeight(tabH - 2)

            local hoverBg = btn:CreateTexture(nil, "BACKGROUND")
            hoverBg:SetAllPoints()
            hoverBg:Hide()
            btn.hoverBg = hoverBg

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetText(tabDef.label)
            lbl:SetJustifyH("CENTER")
            lbl:SetWidth(0)
            btn.label = lbl

            local useGlyph = TAB_GLYPH[tabDef.id] and (modern or CLASSIC_TAB_GLYPH[tabDef.id])
            if useGlyph then
                local glyph = btn:CreateTexture(nil, "ARTWORK")
                glyph:SetSize(glyphPx, glyphPx)
                glyph:SetPoint("LEFT", btn, "LEFT", padLeft, 0)
                glyph:SetTexture(TAB_GLYPH[tabDef.id])
                btn.glyph = glyph
                lbl:SetPoint("LEFT", glyph, "RIGHT", padGap, 0)
                lbl:SetJustifyH("LEFT")
            else
                lbl:SetAllPoints(btn)
            end

            local line = btn:CreateTexture(nil, "OVERLAY")
            line:SetHeight(2)
            line:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
            line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            line:Hide()
            btn.activeLine = line

            btn.tabID  = tabDef.id
            btn.module = tabDef.module
            local textW = (lbl.GetStringWidth and lbl:GetStringWidth()) or (#tabDef.label * 6)
            local naturalW = btn.glyph and (padLeft + glyphPx + padGap + textW + padRight) or (textW + 24)
            btn._textW = textW
            btn._naturalW = naturalW
            totalW = totalW + naturalW + tabGap
            created[#created + 1] = { btn = btn, def = tabDef }
        end

        -- Tighten spacing automatically when many tabs are enabled (e.g., 12 on Forever)
        if totalW > barAvail and #created > 0 then
            glyphPx = modern and 12 or 16
            padLeft = 4
            padGap  = 3
            padRight = 5
            tabGap = 1
            totalW = 0
            for _, item in ipairs(created) do
                local b = item.btn
                if b.glyph then
                    b.glyph:SetSize(glyphPx, glyphPx)
                    b.glyph:ClearAllPoints()
                    b.glyph:SetPoint("LEFT", b, "LEFT", padLeft, 0)
                    b.label:ClearAllPoints()
                    b.label:SetPoint("LEFT", b.glyph, "RIGHT", padGap, 0)
                    b._naturalW = padLeft + glyphPx + padGap + b._textW + padRight
                else
                    b._naturalW = b._textW + 14
                end
                totalW = totalW + b._naturalW + tabGap
            end
        end

        local scale = (totalW > barAvail and totalW > 0) and (barAvail / totalW) or 1
        local tabX = 8
        for _, item in ipairs(created) do
            local btn = item.btn
            local tabDef = item.def
            local w = math.max(24, math.floor(btn._naturalW * scale))
            btn:SetWidth(w)
            btn:SetPoint("LEFT", tabBar, "LEFT", tabX, 1)
            tabX = tabX + w + tabGap

            TintTab(btn, false, false)

            btn:SetScript("OnClick", function()
                frame:SetTab(tabDef.id)
            end)
            btn:SetScript("OnEnter", function()
                if frame.activeTab ~= tabDef.id then TintTab(btn, true, false) end
            end)
            btn:SetScript("OnLeave", function()
                if frame.activeTab ~= tabDef.id then TintTab(btn, false, false) end
            end)

            self.tabButtons[tabDef.id] = btn
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

        -- Re-select the previously active tab, falling back to "now" or "character".
        local fallback = IsTabEnabled("now") and "now" or "character"
        local tabToShow = FallbackTab(self.activeTab or fallback)
        self:SetTab(tabToShow)
    end

    --- Panel shown when the running client has no ToonAge content yet.
    function frame:ShowNoContentNotice()
        local profile = (TA.GetProfile and TA:GetProfile()) or {}
        local label   = profile.label or "this client"

        if not self.noContent then
            local box = CreateFrame("Frame", nil, self)
            box:SetPoint("TOPLEFT", 24, -(ActiveTabHeight() + 28))
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

    -- Initial tab build + Modern Azeroth theme application.
    frame:RebuildTabs()
    frame:ApplyTheme()

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
            TA.Modern:InitDrawer()
        end)
    end
    frame:ApplyTheme()
end

--- Switch window skin ("modern_azeroth" | "classic"), accent pack ("class" |
--- "toonage_gold" | "blizzard"), or reduced motion live with zero /reload.
function TA:ApplyTheme(skin, pack, reducedMotion)
    self.db = self.db or {}
    if skin ~= nil then self.db.themeSkin = skin end
    if pack ~= nil then self.db.themePack = pack end
    if reducedMotion ~= nil then self.db.reducedMotion = reducedMotion and true or false end

    local activeSkin = self.db.themeSkin or "modern_azeroth"
    local activePack = self.db.themePack or "class"
    local skinChanged = self.Theme and self.Theme.active and (self.Theme.active.name ~= activeSkin)

    if self.Theme then
        if self.Theme.SetReducedMotion then
            self.Theme:SetReducedMotion(self.db.reducedMotion == true)
        end
        if self.Theme.Select then
            self.Theme:Select(activeSkin, activePack)
        end
    end

    if self.UI then
        if skinChanged and self.UI.RebuildTabs then
            self.UI:RebuildTabs()
        end
        if self.UI.ApplyTheme then
            self.UI:ApplyTheme()
        end
        if self.UI.activeTab and self.UI.SetTab then
            self.UI:SetTab(self.UI.activeTab)
        end
    end
    if self._settingsDrawer then
        ApplyDrawerTheme(self._settingsDrawer)
        if self._settingsDrawer.IsShown and self._settingsDrawer:IsShown()
            and self.RefreshSettingsDrawer then
            self:RefreshSettingsDrawer()
        end
    end
    if self._copyWindow and self._copyWindow.ApplyTheme then
        self._copyWindow:ApplyTheme()
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

-- Chat pastes get cut off past a few thousand characters. CopyPages defaults to
-- 3500 for chat-sized chunking, while ShowCopyWindow holds up to 60,000 chars
-- in a single EditBox so reports like /ta test copy in one Ctrl+C.
local COPY_PAGE_CHARS = 3500
local COPY_SINGLE_CHARS = 60000

function TA.CopyPages(text, limit)
    limit = tonumber(limit) or COPY_PAGE_CHARS
    if limit < 1 then limit = COPY_PAGE_CHARS end
    text = tostring(text or "")
    if #text <= limit then return { text } end
    local pages, i, n = {}, 1, #text
    while i <= n do
        if n - i + 1 <= limit then
            pages[#pages + 1] = text:sub(i)
            break
        end
        local chunk = text:sub(i, i + limit - 1)
        local br = 0
        for p in chunk:gmatch("()\n") do br = p end
        if br > 1 then
            pages[#pages + 1] = text:sub(i, i + br - 2)
            i = i + br
        else
            pages[#pages + 1] = chunk
            i = i + limit
        end
    end
    if #pages == 0 then pages[1] = "" end
    return pages
end

local function MakeCopyButton(parent, width, height, labelText)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn.plate = btn:CreateTexture(nil, "BACKGROUND")
    btn.plate:SetAllPoints()
    btn.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
    btn.plate:SetVertexColor(0.08, 0.12, 0.16, 0.90)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("CENTER")
    lbl:SetText(labelText or "")
    btn.label = lbl

    btn._enabled = true
    function btn:SetEnabled(v)
        self._enabled = v and true or false
        if self.ApplyStyle then self:ApplyStyle(false) end
    end
    function btn:IsEnabled()
        return self._enabled ~= false
    end
    function btn:ApplyStyle(hover)
        local ac = ActiveAccent()
        local modern = IsModernSkin()
        if not self._enabled then
            if self.plate then self.plate:SetVertexColor(0.06, 0.08, 0.10, 0.45) end
            if self.label then self.label:SetTextColor(0.45, 0.46, 0.48, 0.70) end
            return
        end
        if modern then
            if hover then
                self.plate:SetVertexColor(ac[1] * 0.34, ac[2] * 0.34, ac[3] * 0.34, 0.96)
                self.label:SetTextColor(0.98, 0.98, 0.99, 1.00)
            else
                self.plate:SetVertexColor(0.08, 0.12, 0.17, 0.92)
                self.label:SetTextColor(0.90, 0.92, 0.95, 1.00)
            end
        else
            if hover then
                self.plate:SetVertexColor(0.28, 0.21, 0.06, 0.95)
                self.label:SetTextColor(1.00, 0.92, 0.65, 1.00)
            else
                self.plate:SetVertexColor(0.14, 0.11, 0.05, 0.92)
                self.label:SetTextColor(0.92, 0.85, 0.65, 1.00)
            end
        end
    end
    btn:SetScript("OnEnter", function(self) self:ApplyStyle(true) end)
    btn:SetScript("OnLeave", function(self) self:ApplyStyle(false) end)
    btn:ApplyStyle(false)
    return btn
end

function TA:ShowCopyWindow(title, text, opts)
    local f = self._copyWindow
    if not f then
        f = CreateFrame("Frame", "ToonAgeCopyWindow", UIParent, "BackdropTemplate")
        f:SetSize(640, 480)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        -- Title bar matching the main Modern Azeroth window
        local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
        titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        titleBar:SetHeight(34)
        f.titleBar = titleBar

        local specTop = titleBar:CreateTexture(nil, "ARTWORK")
        specTop:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 0, 0)
        specTop:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
        specTop:SetHeight(16)
        specTop:SetTexture(GLASS_DIR .. "spec_top.tga")
        f.specTop = specTop

        local titleRule = titleBar:CreateTexture(nil, "OVERLAY")
        titleRule:SetHeight(1)
        titleRule:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
        titleRule:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
        titleRule:SetColorTexture(1, 1, 1, 0.10)
        f.titleRule = titleRule

        local hdr = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
        hdr:SetPoint("RIGHT", titleBar, "RIGHT", -38, 0)
        if hdr.SetJustifyH then hdr:SetJustifyH("LEFT") end
        f.header = hdr

        local close = CreateFrame("Button", nil, titleBar)
        close:SetSize(24, 24)
        close:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
        close.plate = close:CreateTexture(nil, "BACKGROUND")
        close.plate:SetAllPoints()
        close.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
        close.plate:SetVertexColor(0.08, 0.12, 0.16, 0.85)
        close.icon = close:CreateTexture(nil, "ARTWORK")
        close.icon:SetSize(12, 12)
        close.icon:SetPoint("CENTER")
        close.icon:SetTexture(ICON_DIR .. "util_close_16.tga")
        close.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
        close:SetScript("OnEnter", function(self)
            self.plate:SetVertexColor(0.75, 0.24, 0.24, 0.78)
            self.icon:SetVertexColor(0.98, 0.98, 0.99, 1)
        end)
        close:SetScript("OnLeave", function(self)
            self.plate:SetVertexColor(0.08, 0.12, 0.16, 0.85)
            self.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
        end)
        close:SetScript("OnClick", function() f:Hide() end)
        f.closeBtn = close

        -- Solid dark content well (zero glass-on-glass; high text contrast)
        local well = CreateFrame("Frame", nil, f, "BackdropTemplate")
        well:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
        well:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 42)
        ApplyBackdrop(well, 0.04, 0.05, 0.07, 0.95, 1, 1, 1, 0.08)
        f.well = well

        local scroll = CreateFrame("ScrollFrame", "ToonAgeCopyWindowScroll", well, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", well, "TOPLEFT", 8, -8)
        scroll:SetPoint("BOTTOMRIGHT", well, "BOTTOMRIGHT", -26, 8)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(570)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(edit)
        f.editBox = edit

        local sel = MakeCopyButton(f, 96, 24, "Select All")
        sel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
        sel:SetScript("OnClick", function()
            edit:SetFocus()
            edit:HighlightText()
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Selected -- press Ctrl+C to copy.")
        end)
        f.selectBtn = sel

        local prev = MakeCopyButton(f, 70, 24, "Prev")
        prev:SetPoint("LEFT", sel, "RIGHT", 8, 0)
        prev:SetScript("OnClick", function()
            if f.page and f.page > 1 then f:ShowPage(f.page - 1) end
        end)
        f.prevBtn = prev

        local nxt = MakeCopyButton(f, 70, 24, "Next")
        nxt:SetPoint("LEFT", prev, "RIGHT", 8, 0)
        nxt:SetScript("OnClick", function()
            if f.page and f.pages and f.page < #f.pages then f:ShowPage(f.page + 1) end
        end)
        f.nextBtn = nxt

        local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 16)
        status:SetTextColor(0.62, 0.65, 0.70, 1)
        f.statusText = status

        function f:ApplyTheme()
            local ac = ActiveAccent()
            if IsModernSkin() then
                local t = TA.Theme and TA.Theme.active
                local fill = (t and t.glass and t.glass.sheet_fill) or { 0.063, 0.094, 0.133, 0.92 }
                local rim  = (t and t.glass and t.glass.sheet_rim) or { 1, 1, 1, 0.18 }
                ApplyBackdrop(self, fill[1], fill[2], fill[3], math.max(fill[4] or 0.92, 0.92),
                    rim[1], rim[2], rim[3], rim[4])
                ApplyBackdrop(self.titleBar, 0.07, 0.10, 0.15, 0.96, ac[1], ac[2], ac[3], 0.35)
                if self.specTop then self.specTop:Show() end
                if self.well then
                    ApplyBackdrop(self.well, 0.035, 0.045, 0.065, 0.96, 1, 1, 1, 0.08)
                end
            else
                ApplyBackdrop(self, 0.05, 0.05, 0.06, 0.96, 0.85, 0.65, 0.13, 0.85)
                ApplyBackdrop(self.titleBar, 0.09, 0.09, 0.11, 0.98, 0.55, 0.40, 0.08, 0.60)
                if self.specTop then self.specTop:Hide() end
                if self.well then
                    ApplyBackdrop(self.well, 0.03, 0.03, 0.04, 0.96, 0.35, 0.28, 0.10, 0.50)
                end
            end
            if self.selectBtn and self.selectBtn.ApplyStyle then self.selectBtn:ApplyStyle(false) end
            if self.prevBtn and self.prevBtn.ApplyStyle then self.prevBtn:ApplyStyle(false) end
            if self.nextBtn and self.nextBtn.ApplyStyle then self.nextBtn:ApplyStyle(false) end
        end

        function f:ShowPage(n)
            local pages = self.pages or { "" }
            local total = #pages
            if n < 1 then n = 1 end
            if n > total then n = total end
            self.page = n
            local label = tostring(self.baseTitle or "")
            if total > 1 then label = label .. " part " .. n .. "/" .. total end
            local ac = ActiveAccent()
            local hex = string.format("%02X%02X%02X",
                math.floor((ac[1] or 1) * 255 + 0.5),
                math.floor((ac[2] or 0.82) * 255 + 0.5),
                math.floor((ac[3] or 0) * 255 + 0.5))
            self.header:SetText("|cFF" .. hex .. label .. "|r  |cFF9AA3B0(Ctrl+C to copy)|r")
            local chunk = pages[n] or ""
            self.editBox:SetText(chunk)
            self.editBox:SetCursorPosition(0)
            if total > 1 then
                self.prevBtn:Show()
                self.nextBtn:Show()
            else
                self.prevBtn:Hide()
                self.nextBtn:Hide()
            end
            if self.prevBtn.SetEnabled then self.prevBtn:SetEnabled(n > 1) end
            if self.nextBtn.SetEnabled then self.nextBtn:SetEnabled(n < total) end
            if self.statusText then
                local suffix = (total > 1) and (" · Page " .. n .. "/" .. total) or " · Single copy ready"
                self.statusText:SetText(tostring(#chunk) .. " chars" .. suffix)
            end
        end

        tinsert(UISpecialFrames, "ToonAgeCopyWindow")
        self._copyWindow = f
    end

    local pageLimit = (type(opts) == "table" and tonumber(opts.pageChars)) or COPY_SINGLE_CHARS
    f.baseTitle = title
    f.pages = self.CopyPages(Plain(text), pageLimit)
    if f.ApplyTheme then f:ApplyTheme() end
    f:ShowPage(1)
    f:Show()
    if f.editBox and f.editBox.SetFocus and f.editBox.HighlightText then
        pcall(f.editBox.SetFocus, f.editBox)
        pcall(f.editBox.HighlightText, f.editBox)
    end
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
local DRAWER_W         = 490
local DRAWER_SIDE_W    = 152
local function DrawerContentWidth(drawer)
    local w = (drawer and drawer:GetWidth()) or DRAWER_W
    return math.max(math.floor(w - 26 - DRAWER_SIDE_W - 20), 180)
end

function TA:RefreshSettingsDrawer()
    local drawer = self._settingsDrawer
    if not drawer then return end
    ApplyDrawerTheme(drawer)
    if drawer.titleLbl then
        if IsModernSkin() then
            drawer.titleLbl:SetText("ToonAge Settings")
            drawer.titleLbl:SetTextColor(0.961, 0.969, 0.980, 1)
        else
            drawer.titleLbl:SetText("|cFFFFD100ToonAge Settings|r")
        end
    end
    local old = drawer.scroll:GetScrollChild()
    if old then old:Hide(); old:SetParent(nil) end

    local content = CreateFrame("Frame", nil, drawer.scroll)
    content:SetWidth(DrawerContentWidth(drawer))
    content:SetHeight(1)
    drawer.scroll:SetScrollChild(content)
    drawer.scroll:SetVerticalScroll(0)
    drawer.content = content

    local Settings = self:GetModule("Settings")
    if Settings and Settings.Render then
        Settings:Render(content, drawer.sidebar)
    end

    -- Fit drawer height cleanly around the Quick Actions sidebar so nothing
    -- overflows past the bottom border (clamped to main window height).
    local sideH = (drawer.sidebar and drawer.sidebar.GetHeight and drawer.sidebar:GetHeight()) or 400
    local wantH = math.min(FRAME_HEIGHT, math.max(430, math.floor(sideH + 40)))
    drawer:SetHeight(wantH)
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
        drawer:SetSize(DRAWER_W, 460)
        drawer:SetFrameStrata("DIALOG")
        drawer:SetMovable(true)
        drawer:EnableMouse(true)
        drawer:RegisterForDrag("LeftButton")
        drawer:SetScript("OnDragStart", drawer.StartMoving)
        drawer:SetScript("OnDragStop", drawer.StopMovingOrSizing)
        drawer:SetClampedToScreen(true)
        ApplyDrawerTheme(drawer)
        drawer:Hide()
        tinsert(UISpecialFrames, "TASettingsDrawer")

        -- Title bar
        local titleLbl = drawer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        titleLbl:SetText("ToonAge Settings")
        titleLbl:SetPoint("TOPLEFT", drawer, "TOPLEFT", 12, -9)
        drawer.titleLbl = titleLbl

        local closeBtn = CreateFrame("Button", nil, drawer)
        closeBtn:SetSize(22, 22)
        closeBtn:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -6, -5)
        closeBtn.plate = closeBtn:CreateTexture(nil, "BACKGROUND")
        closeBtn.plate:SetAllPoints()
        closeBtn.plate:SetTexture(GLASS_DIR .. "button_r6.tga")
        closeBtn.plate:SetVertexColor(0.08, 0.12, 0.16, 0.85)
        closeBtn.icon = closeBtn:CreateTexture(nil, "ARTWORK")
        closeBtn.icon:SetSize(11, 11)
        closeBtn.icon:SetPoint("CENTER")
        closeBtn.icon:SetTexture(ICON_DIR .. "util_close_16.tga")
        closeBtn.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
        closeBtn:SetScript("OnEnter", function(self)
            self.plate:SetVertexColor(0.75, 0.24, 0.24, 0.72)
            self.icon:SetVertexColor(0.98, 0.98, 0.99, 1)
        end)
        closeBtn:SetScript("OnLeave", function(self)
            self.plate:SetVertexColor(0.08, 0.12, 0.16, 0.85)
            self.icon:SetVertexColor(0.79, 0.80, 0.82, 1)
        end)
        closeBtn:SetScript("OnClick", function() drawer:Hide() end)
        drawer.closeBtn = closeBtn

        local hdrRule = drawer:CreateTexture(nil, "OVERLAY")
        hdrRule:SetHeight(1)
        hdrRule:SetPoint("TOPLEFT", drawer, "TOPLEFT", 1, -30)
        hdrRule:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -1, -30)
        hdrRule:SetColorTexture(1, 1, 1, 0.08)

        -- Scroll frame inside drawer (clipped so child cards never bleed past bounds)
        local scroll = CreateFrame("ScrollFrame", "TASettingsDrawerScroll", drawer, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", drawer, "TOPLEFT", 4, -34)
        scroll:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -(28 + DRAWER_SIDE_W + 10), 8)
        if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end

        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(DrawerContentWidth(drawer))
        content:SetHeight(1)
        scroll:SetScrollChild(content)

        -- Quick Actions column. This used to be a hidden 1x1 frame, so every
        -- button Settings:RenderSidebar drew (Reset All Settings among them)
        -- existed but could never be clicked -- /ta test, 2026-09-28.
        local sidebar = CreateFrame("Frame", nil, drawer)
        sidebar:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -8, -32)
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
            if shrunk >= 260 then
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

    self:RefreshSettingsDrawer()
    drawer:Show()
end

-- ── Blizzard Settings registration ───────────────────────────────────────────
-- Registered lazily inside InitUI() (called from OnLogin after PLAYER_ENTERING_WORLD)
-- so Blizzard's Settings API is guaranteed to be loaded.  Doing this at file-load
-- time risks the Settings global not existing yet and aborting the rest of the file.
