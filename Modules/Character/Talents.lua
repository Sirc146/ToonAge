-- ToonAge/Modules/Talents.lua
-- Role-aware talent advisor: match scoring, role badges, debounced refresh

local TA = ToonAge
local U  = TA.Utils
local T  = TA.Data.Talents
local TAPI = TA.TalentsAPI

local Talents = {}
TA:RegisterModule("Talents", Talents)

Talents.frames         = {}
Talents.sideFrames     = {}
Talents.selectedSpecID = nil
Talents.viewBuildType  = nil

-- Stat proxy helper (same as Gear.lua — duplicated here to avoid cross-module
-- dependency since Gear.lua's version is file-local).
local function CleanProxyValue(val)
    if not val then return 0 end
    if type(val) == "number" then return val end
    return tonumber(tostring(val):match("([%d%.%-]+)")) or 0
end

-- ── Debounce ──────────────────────────────────────────────────────────────
local refreshTimer = nil
local function ScheduleRefresh()
    if refreshTimer then return end
    refreshTimer = C_Timer.After(0.25, function()
        refreshTimer = nil
        if TA.UI and TA.UI.activeTab == "talents" then
            Talents:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end)
end

-- ── Events ────────────────────────────────────────────────────────────────
function Talents:OnEvent(event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        self.selectedSpecID = nil
        self.viewBuildType  = nil
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_TALENT_UPDATE"
    or event == "ACTIVE_TALENT_GROUP_CHANGED"
    or event == "GROUP_ROSTER_UPDATE"
    or event == "TRAIT_CONFIG_UPDATED" then
        ScheduleRefresh()
    end
end

-- ── Helpers ───────────────────────────────────────────────────────────────
local function GetGroupMode()
    if IsInRaid()  then return "raid"  end
    if IsInGroup() then return "mplus" end
    return "solo"
end

-- Returns display label + RGB for a specID based on role/style
local RoleDisplay = {
    TANK_melee     = { label="Tank",       r=0.29, g=0.65, b=1.00 },
    TANK_ranged    = { label="Tank",       r=0.29, g=0.65, b=1.00 },
    HEALER_melee   = { label="Healer",     r=0.29, g=1.00, b=0.48 },
    HEALER_ranged  = { label="Healer",     r=0.29, g=1.00, b=0.48 },
    DAMAGER_melee  = { label="Melee DPS",  r=1.00, g=0.42, b=0.29 },
    DAMAGER_ranged = { label="Ranged DPS", r=1.00, g=0.72, b=0.29 },
}
local function RoleOf(specID)
    local info = TAPI.GetSpecInfo(specID)
    return RoleDisplay[info.role .. "_" .. info.style] or RoleDisplay["DAMAGER_melee"]
end

local function GetSpecNameByID(specID)
    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(specID)
        if name then return name end
    end
    for i = 1, (GetNumSpecializations() or 4) do
        local id, name = GetSpecializationInfo(i)
        if id == specID then return name end
    end
    return "Spec " .. tostring(specID)
end

-- ── Main render entry ─────────────────────────────────────────────────────

--- Aggressively hide all talent-related content panels and child frames.
--- Called before any render to prevent Z-index pileups from interrupted renders.
local function HideAllTalentPanels(frames, sideFrames)
    -- Hide tracked frames
    for _, f in ipairs(frames) do
        if f and f.Hide then f:Hide() end
        if f and f.SetParent then f:SetParent(nil) end
    end
    for _, f in ipairs(sideFrames) do
        if f and f.Hide then f:Hide() end
        if f and f.SetParent then f:SetParent(nil) end
    end
end

function Talents:Render(content, sidebar)
    HideAllTalentPanels(self.frames, self.sideFrames)
    self.frames     = {}
    self.sideFrames = {}

    local activeSpecID = U.GetPlayerSpec()
    if not activeSpecID then return end

    if not self.selectedSpecID then self.selectedSpecID = activeSpecID end
    if not self.viewBuildType  then self.viewBuildType  = GetGroupMode() end

    self:RenderSidebar(sidebar, activeSpecID)
    local ok, err = pcall(self.RenderContent, self, content, activeSpecID)
    if not ok then
        -- On render failure, ensure no partial frames leak
        HideAllTalentPanels(self.frames, self.sideFrames)
        local errF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        errF:SetText("|cFFFF4444Talent render error:|r\n" .. tostring(err))
        errF:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -14)
        errF:SetWidth(content:GetWidth() - 28)
        errF:SetWordWrap(true)
        table.insert(self.frames, errF)
    end
end

-- ── Content ───────────────────────────────────────────────────────────────
function Talents:RenderContent(content, activeSpecID)
    local padL = 10
    local y    = -10
    local w    = content:GetWidth() - 20
    local specID = self.selectedSpecID

    local function Track(f) table.insert(self.frames, f) return f end

    local function AddText(text, size, r, g, b)
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 11, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        f:SetWidth(w)
        f:SetJustifyH("LEFT")
        f:SetWordWrap(true)
        y = y - f:GetStringHeight() - 4
        Track(f)
        return f
    end

    local function AddLine()
        local ln = content:CreateTexture(nil, "ARTWORK")
        ln:SetHeight(1)
        ln:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  y)
        ln:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
        ln:SetColorTexture(0.55, 0.40, 0.08, 0.3)
        y = y - 8
        Track(ln)
    end

    -- ── Header ─────────────────────────────────────────────────────────
    local specName = GetSpecNameByID(specID)
    local rdsp     = RoleOf(specID)
    local roleHex  = string.format("%02x%02x%02x",
        math.floor(rdsp.r * 255), math.floor(rdsp.g * 255), math.floor(rdsp.b * 255))
    local roleTag  = "|cFF" .. roleHex .. rdsp.label .. "|r"

    AddText(specName:upper() .. "  " .. roleTag, 13, 1, 0.82, 0)
    if specID ~= activeSpecID then
        local activeName = GetSpecNameByID(activeSpecID)
        AddText("Browsing — your active spec is |cFFFFD100" .. activeName .. "|r", 9, 0.5, 0.5, 0.5)
    end
    y = y - 2
    AddLine()

    -- ── Build type selector ─────────────────────────────────────────────
    local types = T.BuildTypes or {
        { key="mplus", label="Mythic+" }, { key="raid", label="Raid" },
        { key="delves", label="Delves" }, { key="pvp", label="PvP" },
        { key="solo", label="Leveling" },
    }
    local btnW   = math.floor(w / #types) - 2
    local bx     = padL
    for _, bt in ipairs(types) do
        local active = (self.viewBuildType == bt.key)
        local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
        btn:SetSize(btnW, 26)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", bx, y)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        if active then
            btn:SetBackdropColor(0.12, 0.09, 0.00, 1)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        else
            btn:SetBackdropColor(0.04, 0.04, 0.04, 1)
            btn:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.25)
        end
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        lbl:SetText(bt.label)
        lbl:SetTextColor(active and 1 or 0.55, active and 0.82 or 0.44, active and 0 or 0.25, 1)
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        btn:SetScript("OnClick", function()
            self.viewBuildType = bt.key
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end)
        Track(btn)
        bx = bx + btnW + 3
    end
    y = y - 32

    -- Visual break between the build-type row and whatever comes next
    -- (the Class/Spec/Hero/PvP tab row, or the recommended-build card) —
    -- these are two separate control groups and were reading as one
    -- crowded block with only a few px between them.
    AddLine()
    y = y - 6

    -- ── PvP mode: delegate to TalentsPvP module for the full advisor ────
    if self.viewBuildType == "pvp" then
        local PvPAdvisor = TA:GetModule("TalentsPvP")
        if PvPAdvisor and PvPAdvisor.Render then
            -- Pass the current cursor position so PvPAdvisor draws BELOW the
            -- header + build-type row already drawn above, instead of both
            -- starting at the top of the same content frame and overlapping.
            PvPAdvisor:Render(content, sidebar, y)
            return
        end
        -- Fall through to generic build display if PvP module unavailable
    else
        -- Leaving PvP view: TalentsPvP owns a separate tracked-frame list from
        -- this module's self.frames/self.sideFrames, so HideAllTalentPanels()
        -- at the top of Talents:Render never touches its frames. Without this,
        -- its header/hero-recommendation/tab-bar/panel content from the last
        -- PvP render stays visible, overlapping whatever we draw below.
        local PvPAdvisor = TA:GetModule("TalentsPvP")
        if PvPAdvisor and PvPAdvisor.Hide then
            PvPAdvisor:Hide()
        end
    end

    -- ── Fetch build data ────────────────────────────────────────────────
    local dbSpec = T:GetBySpecID(specID)
    if not dbSpec then
        AddText("No build data available for this specialization yet.", 11, 0.5, 0.5, 0.5)
        content:SetHeight(math.abs(y) + 20)
        return
    end

    local build = dbSpec.builds[self.viewBuildType] or dbSpec.builds.solo
    if not build then
        AddText("No build for this content type.", 11, 0.5, 0.5, 0.5)
        content:SetHeight(math.abs(y) + 20)
        return
    end

    -- Override the import string with user-saved custom build if one exists.
    -- The user clicks "Save Current as X Build" to capture their live loadout
    -- as the recommended code for this content type. This takes priority over
    -- the static data in Data/Talents.lua.
    local customStr = TA.charDB and TA.charDB.customBuilds
                   and TA.charDB.customBuilds[specID]
                   and TA.charDB.customBuilds[specID][self.viewBuildType]
    if customStr and customStr ~= "" then
        -- Create a merged build table so we don't mutate the source data
        build = {
            name   = build.name .. " |cFF4AFF7A(Your Saved)|r",
            desc   = build.desc,
            string = customStr,
            nodes  = build.nodes,
            levelPath = build.levelPath,
        }
    end

    -- ── Match score card (only when node data exists) ───────────────────
    if build.nodes and #build.nodes > 0 then
        local activeIDs = TAPI.GetActiveTalentIDs()
        -- count hits directly so we don't call GetActiveTalentIDs twice
        local activeSet, hitCount, totalNodes = {}, 0, #build.nodes
        for _, id in ipairs(activeIDs) do activeSet[id] = true end
        for _, id in ipairs(build.nodes) do
            if activeSet[id] then hitCount = hitCount + 1 end
        end
        local pct = math.floor((hitCount / totalNodes) * 100)
        local pr, pg, pb
        if     pct >= 80 then pr,pg,pb = 0.29, 1.00, 0.48
        elseif pct >= 50 then pr,pg,pb = 1.00, 0.82, 0.00
        else                  pr,pg,pb = 1.00, 0.27, 0.27 end

        local mcard = CreateFrame("Frame", nil, content, "BackdropTemplate")
        mcard:SetSize(w, 46)
        mcard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        mcard:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        mcard:SetBackdropColor(0.03, 0.05, 0.03, 1)
        mcard:SetBackdropBorderColor(pr * 0.6, pg * 0.6, pb * 0.6, 0.7)
        Track(mcard)

        local mHdr = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mHdr:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        mHdr:SetText("BUILD MATCH")
        mHdr:SetTextColor(0.45, 0.45, 0.45, 1)
        mHdr:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -7)

        local mPct = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mPct:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
        mPct:SetText(pct .. "%")
        mPct:SetTextColor(pr, pg, pb, 1)
        mPct:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -14)

        local barX = 78
        local barW = w - barX - 12
        local barBG = mcard:CreateTexture(nil, "ARTWORK")
        barBG:SetSize(barW, 6)
        barBG:SetPoint("LEFT", mcard, "LEFT", barX, 5)
        barBG:SetColorTexture(0.12, 0.12, 0.12, 1)

        local fill = math.max(1, math.floor(barW * pct / 100))
        local barFG = mcard:CreateTexture(nil, "ARTWORK")
        barFG:SetSize(fill, 6)
        barFG:SetPoint("LEFT", mcard, "LEFT", barX, 5)
        barFG:SetColorTexture(pr, pg, pb, 1)

        local mNodes = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mNodes:SetFont(STANDARD_TEXT_FONT, 9)
        mNodes:SetText(hitCount .. " / " .. totalNodes .. " key talents active")
        mNodes:SetTextColor(0.50, 0.50, 0.50, 1)
        mNodes:SetPoint("LEFT", mcard, "LEFT", barX, -7)

        y = y - 54
    end

    -- ── Recommended build card ──────────────────────────────────────────
    local hasString = build.string and build.string ~= ""
    local cardH     = hasString and 88 or 64
    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetSize(w, cardH)
    card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    card:SetBackdropColor(0.05, 0.04, 0.02, 1)
    card:SetBackdropBorderColor(1, 0.82, 0, 0.4)
    Track(card)

    local cName = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cName:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    cName:SetText(build.name or "Recommended Build")
    cName:SetTextColor(1, 0.82, 0, 1)
    cName:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)

    local cDesc = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cDesc:SetFont(STANDARD_TEXT_FONT, 10)
    cDesc:SetText(build.desc or "")
    cDesc:SetTextColor(0.72, 0.68, 0.52, 1)
    cDesc:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -28)
    cDesc:SetWidth(w - 20)
    cDesc:SetWordWrap(false)

    if hasString then
        local cpBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
        cpBtn:SetSize(150, 26)
        cpBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
        cpBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        cpBtn:SetBackdropColor(0.10, 0.08, 0.00, 1)
        cpBtn:SetBackdropBorderColor(1, 0.82, 0, 0.55)
        Track(cpBtn)

        local cpLbl = cpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cpLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        cpLbl:SetText("Copy Import String")
        cpLbl:SetAllPoints(cpBtn)
        cpLbl:SetJustifyH("CENTER")

        cpBtn:SetScript("OnClick", function()
            if InCombatLockdown() then
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Cannot copy talent string during combat.")
                return
            end
            self:OpenSafeCopyFrame(build.name, build.string)
        end)

        -- "Import / Replace" button (left of copy button)
        local impBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
        impBtn:SetSize(100, 26)
        impBtn:SetPoint("RIGHT", cpBtn, "LEFT", -4, 0)
        impBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        impBtn:SetBackdropColor(0.02, 0.04, 0.08, 1)
        impBtn:SetBackdropBorderColor(0.29, 0.65, 1.00, 0.55)
        Track(impBtn)
        local impLbl = impBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        impLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        impLbl:SetText("Import / Replace")
        impLbl:SetTextColor(0.29, 0.65, 1.00, 1)
        impLbl:SetAllPoints(impBtn)
        impLbl:SetJustifyH("CENTER")
        impBtn:SetScript("OnClick", function()
            self:OpenImportFrame()
        end)

        -- Anchored to impBtn's left edge (not a fixed width) so it never
        -- runs underneath either button, regardless of how many buttons
        -- end up sharing this row in the future.
        local cStr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cStr:SetFont(STANDARD_TEXT_FONT, 9)
        cStr:SetText(U.Truncate(build.string, 60))
        cStr:SetTextColor(0.38, 0.38, 0.38, 1)
        cStr:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 34)
        cStr:SetPoint("RIGHT", impBtn, "LEFT", -8, 0)
        cStr:SetWordWrap(false)
    else
        -- No import string available — show Import button prominently
        local impBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
        impBtn:SetSize(180, 26)
        impBtn:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
        impBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        impBtn:SetBackdropColor(0.02, 0.04, 0.08, 1)
        impBtn:SetBackdropBorderColor(0.29, 0.65, 1.00, 0.7)
        Track(impBtn)
        local impLbl = impBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        impLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        impLbl:SetText("Import or Capture Build")
        impLbl:SetTextColor(0.29, 0.65, 1.00, 1)
        impLbl:SetAllPoints(impBtn)
        impLbl:SetJustifyH("CENTER")
        impBtn:SetScript("OnClick", function()
            self:OpenImportFrame()
        end)

        local noStr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noStr:SetFont(STANDARD_TEXT_FONT, 9)
        noStr:SetText("|cFF4A4A4ANo import string yet — click to add one.|r")
        noStr:SetPoint("LEFT", impBtn, "RIGHT", 8, 0)
    end

    y = y - cardH - 10

    -- ── 0-Max Milestone & Readiness Card ─────────────────────────────────
    local playerLevel = UnitLevel("player")
    local maxLevel    = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local _, eqILvl   = GetAverageItemLevel()
    local isMaxLevel  = (playerLevel >= maxLevel)

    -- Card height differs: endgame has 4 rows, leveling has talent progression + milestone
    local hasLevelPath = not isMaxLevel and build.levelPath and next(build.levelPath)
    local mh = isMaxLevel and 106 or (hasLevelPath and 120 or 86)
    local mcard = CreateFrame("Frame", nil, content, "BackdropTemplate")
    mcard:SetSize(w, mh)
    mcard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    mcard:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    if isMaxLevel then
        mcard:SetBackdropColor(0.04, 0.03, 0.01, 1)
        mcard:SetBackdropBorderColor(1.00, 0.82, 0.00, 0.45)
    else
        mcard:SetBackdropColor(0.02, 0.04, 0.06, 1)
        mcard:SetBackdropBorderColor(0.29, 0.65, 1.00, 0.45)
    end
    Track(mcard)

    -- Header label
    local mHdrTxt = isMaxLevel
        and ("ENDGAME  ·  " .. math.floor(eqILvl) .. " iLvl equipped")
        or  ("LEVELING  ·  Level " .. playerLevel .. " of " .. maxLevel)
    local mHdr = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    mHdr:SetText(mHdrTxt)
    mHdr:SetTextColor(isMaxLevel and 1 or 0.29, isMaxLevel and 0.82 or 0.65, isMaxLevel and 0 or 1.00, 1)
    mHdr:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -8)

    -- Thin divider below header
    local mDiv = mcard:CreateTexture(nil, "ARTWORK")
    mDiv:SetHeight(1)
    mDiv:SetPoint("TOPLEFT",  mcard, "TOPLEFT",  10, -22)
    mDiv:SetPoint("TOPRIGHT", mcard, "TOPRIGHT", -10, -22)
    mDiv:SetColorTexture(isMaxLevel and 1 or 0.29, isMaxLevel and 0.82 or 0.65, isMaxLevel and 0 or 1, 0.12)

    if isMaxLevel then
        -- ── Endgame readiness rows ──────────────────────────────────────
        -- Updated for Midnight Season 2 "Curse of Ula'tek" (patch 12.1),
        -- cross-checked against icy-veins/koroboost/method.gg gearing guides,
        -- 2026-08-31. Update these thresholds each major patch / season reset.
        local thresholds = {
            { label = "Delves    (Tier 8)",   req = 290 },
            { label = "LFR       (Raid)",     req = 292 },
            { label = "Normal    (Raid)",     req = 305 },
            { label = "Mythic+   (Base key)", req = 292 },
        }
        for i, row in ipairs(thresholds) do
            local ry = -26 - (i - 1) * 18
            local ready = eqILvl >= row.req

            local rowLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowLbl:SetFont(STANDARD_TEXT_FONT, 10)
            rowLbl:SetText(row.label)
            rowLbl:SetTextColor(0.60, 0.56, 0.42, 1)
            rowLbl:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, ry)

            local rdyLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rdyLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            rdyLbl:SetText(ready and "|cFF4AFF7A\226\156\147 Ready|r" or ("|cFFFF5555\226\156\151 Need " .. row.req .. "|r"))
            rdyLbl:SetPoint("TOPRIGHT", mcard, "TOPRIGHT", -10, ry)
        end
    else
        -- ── Leveling phase ──────────────────────────────────────────────
        local levelsLeft = maxLevel - playerLevel

        local subLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subLbl:SetFont(STANDARD_TEXT_FONT, 9)
        subLbl:SetText(levelsLeft .. " levels until max  ·  talent tree unlocks at level 10")
        subLbl:SetTextColor(0.42, 0.42, 0.42, 1)
        subLbl:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -26)

        -- Show the current talent to take + next 3 upcoming as a progression path
        local adviceLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        adviceLbl:SetFont(STANDARD_TEXT_FONT, 10)
        adviceLbl:SetWidth(w - 20)
        adviceLbl:SetJustifyH("LEFT")
        adviceLbl:SetWordWrap(true)
        adviceLbl:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -42)

        if playerLevel < 10 then
            adviceLbl:SetText("Reach |cFFFFD100level 10|r to unlock your first talent point.")
            adviceLbl:SetTextColor(0.70, 0.70, 0.70, 1)
        elseif build.levelPath then
            -- Find current level's talent + next 3 upcoming
            local pathLines = {}
            local found = 0
            for lvl = playerLevel, playerLevel + 20 do
                local t = build.levelPath[lvl]
                if t then
                    found = found + 1
                    if lvl == playerLevel then
                        pathLines[#pathLines + 1] = "|cFF4AFF7A→ Lvl " .. lvl .. ":|r |cFFFFD100" .. t .. "|r  ← take now"
                    else
                        pathLines[#pathLines + 1] = "|cFF888780  Lvl " .. lvl .. ":|r " .. t
                    end
                    if found >= 4 then break end
                end
            end
            if #pathLines > 0 then
                adviceLbl:SetText(table.concat(pathLines, "\n"))
                adviceLbl:SetTextColor(0.70, 0.70, 0.70, 1)
            else
                adviceLbl:SetText("|cFF555555No step-by-step path for your current level — follow the build above.|r")
                adviceLbl:SetTextColor(0.50, 0.50, 0.50, 1)
            end
        else
            adviceLbl:SetText("|cFF555555No step-by-step path defined yet — follow the build above.|r")
            adviceLbl:SetTextColor(0.50, 0.50, 0.50, 1)
        end

        -- Milestone hint at bottom of card
        local mileTxt
        if     playerLevel < 10 then mileTxt = "Milestone \226\134\146 Level 10: talent tree opens"
        elseif playerLevel < 30 then mileTxt = "Milestone \226\134\146 Level 30: Heroic dungeons & queued content"
        elseif playerLevel < 50 then mileTxt = "Milestone \226\134\146 Level 50: Delves unlock  ·  Normal dungeons scale"
        elseif playerLevel < 70 then mileTxt = "Milestone \226\134\146 Level 70: World quests, M0, previous-expansion raids"
        elseif playerLevel < 71 then mileTxt = "Milestone \226\134\146 Level 71: Hero talents unlock"
        elseif playerLevel < 81 then mileTxt = "Milestone \226\134\146 Level 81: next talent tier (verify in-game — unconfirmed for this build)"
        else                         mileTxt = "Milestone \226\134\146 Approaching max — endgame content unlocking soon" end

        local mileLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mileLbl:SetFont(STANDARD_TEXT_FONT, 8)
        mileLbl:SetText(mileTxt)
        mileLbl:SetTextColor(0.29, 0.65, 1.00, 0.70)
        mileLbl:SetPoint("BOTTOMLEFT", mcard, "BOTTOMLEFT", 10, 6)
    end

    y = y - mh - 8

    -- ── Your current loadout string (active spec only) ──────────────────
    if specID == activeSpecID
    and C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        local cfgID = C_ClassTalents.GetActiveConfigID()
        if cfgID and C_Traits and C_Traits.GenerateImportString then
            local exportStr = C_Traits.GenerateImportString(cfgID)
            if exportStr and exportStr ~= "" then
                AddLine()
                AddText("|cFF555555Your loadout:|r  " .. U.Truncate(exportStr, 68), 9, 0.45, 0.45, 0.45)
                y = y - 2

                -- "Save as Recommended" button: captures the player's current live
                -- loadout string and sets it as the recommended build for the
                -- currently viewed content type. This is how you fill in the
                -- import strings for PvP/Delves builds with YOUR personal loadout.
                local viewType = self.viewBuildType or "solo"
                local saveBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
                saveBtn:SetSize(200, 22)
                saveBtn:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                saveBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
                saveBtn:SetBackdropColor(0.04, 0.08, 0.04, 1)
                saveBtn:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.6)
                Track(saveBtn)
                local saveLbl = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                saveLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
                saveLbl:SetText("Save Current as \"" .. viewType:upper() .. "\" Build")
                saveLbl:SetTextColor(0.29, 1.00, 0.48, 1)
                saveLbl:SetAllPoints(saveBtn)
                saveLbl:SetJustifyH("CENTER")

                local capExportStr = exportStr
                local capViewType  = viewType
                local capSpecID    = specID
                saveBtn:SetScript("OnClick", function()
                    -- Save into charDB so it persists across sessions
                    TA.charDB.customBuilds = TA.charDB.customBuilds or {}
                    TA.charDB.customBuilds[capSpecID] = TA.charDB.customBuilds[capSpecID] or {}
                    TA.charDB.customBuilds[capSpecID][capViewType] = capExportStr
                    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Talents]|r Saved your current loadout as the |cFF4AFF7A"
                        .. capViewType:upper() .. "|r build for " .. GetSpecNameByID(capSpecID) .. ".")
                    -- Refresh to show the saved string
                    self:Render(TA.UI.contentChild, TA.UI.sideChild)
                end)
                y = y - 28
            end
        end
    end

    -- ── Gear-based spec recommendation ──────────────────────────────────
    -- Scores your current equipped gear against every spec your class can play,
    -- using ToonAge's stat weights. If a different spec would score meaningfully
    -- higher for the selected content type (pvp vs pve), surface a recommendation.
    --
    -- WEAPON COMPATIBILITY: Excludes weapon slots when the equipped weapon type
    -- is incompatible with a candidate spec. Examples:
    --   • Survival Hunter uses polearms — BM/MM can't use them (need bows/guns)
    --   • Prot Paladin uses 1H + Shield — Ret can't use shields
    --   • Arms Warrior uses 2H — Fury can dual-wield but scoring a 2H for Fury
    --     dual-wield isn't meaningful without the second weapon in bags
    -- When weapons are excluded, the comparison only uses armor + accessories,
    -- which gives a fair "your secondary stats lean toward X" recommendation.

    if specID == activeSpecID then
        local numSpecs = GetNumSpecializations() or 0
        local pvxMode  = (self.viewBuildType == "pvp") and "pvp" or "pve"
        local scores   = {}
        local bestSpec, bestScore = nil, 0
        local weaponNotes = {}  -- [specID] = note about weapon incompatibility

        -- Determine equipped weapon types for compatibility checks
        local mhLink  = GetInventoryItemLink("player", 16)
        local ohLink  = GetInventoryItemLink("player", 17)
        local mhEquipLoc, ohEquipLoc
        if mhLink then
            local _, _, _, _, _, _, _, _, loc = GetItemInfo(mhLink)
            mhEquipLoc = loc
        end
        if ohLink then
            local _, _, _, _, _, _, _, _, loc = GetItemInfo(ohLink)
            ohEquipLoc = loc
        end

        -- Weapon compatibility rules per spec.
        -- Returns true if the spec CAN use the currently equipped weapon setup.
        -- If false, weapons should be excluded from that spec's gear score.
        local RANGED_LOCS = {
            INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true,
        }
        local MELEE_2H_LOCS = {
            INVTYPE_2HWEAPON = true,
        }
        local MELEE_1H_LOCS = {
            INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true,
        }
        local SHIELD_LOCS = {
            INVTYPE_SHIELD = true,
        }

        -- Spec weapon expectations (specID → what weapon setup they need)
        -- nil = can use anything / flexible (casters with staff OR 1H+OH, etc.)
        -- The goal is to EXCLUDE weapon slot scores when the equipped weapon
        -- is clearly incompatible — not to be overly restrictive on flexible specs.
        local SPEC_WEAPON_NEEDS = {
            -- Hunter
            [253] = "ranged",    -- BM: bow/gun/crossbow
            [254] = "ranged",    -- MM: bow/gun/crossbow
            [255] = "melee_2h",  -- Survival: polearm/staff (melee 2H)
            -- Warrior
            [71]  = "melee_2h",  -- Arms: 2H weapon
            [72]  = "dual_wield",-- Fury: two 1H (or two 2H with Titan's Grip — edge case)
            [73]  = "melee_1h_shield", -- Prot: 1H + Shield
            -- Paladin
            [65]  = nil,         -- Holy: 1H+Shield, 2H staff, or 1H+OH — flexible
            [66]  = "melee_1h_shield", -- Prot: 1H + Shield
            [70]  = "melee_2h",  -- Ret: 2H weapon
            -- Death Knight
            [250] = "melee_2h",  -- Blood: 2H weapon
            [251] = "dual_wield",-- Frost: dual-wield 1H (2H Frost exists but is niche)
            [252] = "melee_2h",  -- Unholy: 2H weapon
            -- Druid
            [102] = nil,         -- Balance: staff / 1H+OH / polearm — flexible
            [103] = nil,         -- Feral: staff / polearm / 1H+OH — flexible
            [104] = nil,         -- Guardian: staff / polearm — flexible
            [105] = nil,         -- Restoration: staff / 1H+OH — flexible
            -- Shaman
            [262] = nil,         -- Elemental: 1H+Shield, staff, etc. — flexible
            [263] = "dual_wield",-- Enhancement: dual-wield 1H weapons
            [264] = nil,         -- Restoration: 1H+Shield, staff — flexible
            -- Monk
            [268] = nil,         -- Brewmaster: staff, polearm, 1H+OH, dual-wield — flexible
            [269] = nil,         -- Windwalker: same as Brewmaster — flexible
            [270] = nil,         -- Mistweaver: same — flexible
            -- Rogue
            [259] = "dual_wield",-- Assassination: dual daggers
            [260] = "dual_wield",-- Outlaw: dual-wield (MH sword/axe/mace, OH any 1H)
            [261] = "dual_wield",-- Subtlety: dual daggers
            -- Demon Hunter
            [577] = "dual_wield",-- Havoc: dual warglaives/1H
            [581] = "dual_wield",-- Vengeance: dual warglaives/1H
            -- Mage
            [62]  = nil,         -- Arcane: staff / 1H+OH — flexible
            [63]  = nil,         -- Fire: staff / 1H+OH — flexible
            [64]  = nil,         -- Frost: staff / 1H+OH — flexible
            -- Priest
            [256] = nil,         -- Discipline: staff / 1H+OH — flexible
            [257] = nil,         -- Holy: staff / 1H+OH — flexible
            [258] = nil,         -- Shadow: staff / 1H+OH — flexible
            -- Warlock
            [265] = nil,         -- Affliction: staff / 1H+OH — flexible
            [266] = nil,         -- Demonology: staff / 1H+OH — flexible
            [267] = nil,         -- Destruction: staff / 1H+OH — flexible
            -- Evoker
            [1467] = nil,        -- Devastation: flexible (evoker weapon types)
            [1468] = nil,        -- Preservation: flexible
            [1473] = nil,        -- Augmentation: flexible
        }

        local function WeaponCompatible(candidateSpecID)
            local need = SPEC_WEAPON_NEEDS[candidateSpecID]
            if not need then return true end  -- no restriction

            if need == "ranged" then
                return mhEquipLoc and RANGED_LOCS[mhEquipLoc] or false
            elseif need == "melee_2h" then
                return mhEquipLoc and MELEE_2H_LOCS[mhEquipLoc] or false
            elseif need == "melee_1h_shield" then
                local has1H = mhEquipLoc and (MELEE_1H_LOCS[mhEquipLoc] or false)
                local hasShield = ohEquipLoc and (SHIELD_LOCS[ohEquipLoc] or false)
                return has1H and hasShield
            elseif need == "dual_wield" then
                -- Needs a weapon in both hands (not a 2H, not a shield in MH)
                local mhOK = mhEquipLoc and (MELEE_1H_LOCS[mhEquipLoc] or false)
                local ohOK = ohEquipLoc and (MELEE_1H_LOCS[ohEquipLoc]
                          or ohEquipLoc == "INVTYPE_WEAPONOFFHAND" or false)
                return mhOK and ohOK
            end
            return true
        end

        for i = 1, numSpecs do
            local sID = GetSpecializationInfo(i)
            if sID then
                local sw = TA.Data.StatWeights[sID]
                if sw then
                    local total = 0
                    local weaponsIncluded = WeaponCompatible(sID)

                    for slotID = 1, 17 do
                        if slotID == 4 then
                            -- skip shirt
                        elseif (slotID == 16 or slotID == 17) and not weaponsIncluded then
                            -- skip weapon slots for specs that can't use our weapons
                        else
                            local link = GetInventoryItemLink("player", slotID)
                            if link then
                                local rawStats = C_Item.GetItemStats(link)
                                if rawStats then
                                    local stats = {
                                        INT     = CleanProxyValue(rawStats["ITEM_MOD_INTELLECT_SHORT"]),
                                        AGI     = CleanProxyValue(rawStats["ITEM_MOD_AGILITY_SHORT"]),
                                        STR     = CleanProxyValue(rawStats["ITEM_MOD_STRENGTH_SHORT"]),
                                        STAM    = CleanProxyValue(rawStats["ITEM_MOD_STAMINA_SHORT"]),
                                        CRIT    = CleanProxyValue(rawStats["ITEM_MOD_CRIT_RATING_SHORT"]),
                                        HASTE   = CleanProxyValue(rawStats["ITEM_MOD_HASTE_RATING_SHORT"]),
                                        MASTERY = CleanProxyValue(rawStats["ITEM_MOD_MASTERY_RATING_SHORT"]),
                                        VERS    = CleanProxyValue(rawStats["ITEM_MOD_VERSATILITY_SHORT"]),
                                    }
                                    local weights = sw[pvxMode] or sw.pve
                                    if weights then
                                        for stat, value in pairs(stats) do
                                            total = total + (weights[stat] or 0.2) * value
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if not weaponsIncluded then
                        weaponNotes[sID] = true
                    end

                    scores[sID] = math.floor(total)
                    if total > bestScore then
                        bestScore = total
                        bestSpec  = sID
                    end
                end
            end
        end

        local activeScore = scores[activeSpecID] or 0
        -- Show recommendation if another spec scores 5%+ higher
        if bestSpec and bestSpec ~= activeSpecID and activeScore > 0 then
            local pctDiff = math.floor(((bestScore - activeScore) / activeScore) * 100)
            if pctDiff >= 5 then
                AddLine()
                local recName = GetSpecNameByID(bestSpec)
                AddText("|cFFFF9A1AGEAR SUGGESTS:|r Your equipped stats score |cFF1EFF00" .. pctDiff
                    .. "%|r higher for |cFFFFD100" .. recName .. "|r (" .. pvxMode:upper() .. " mode).", 10, 1, 0.6, 0.2)
                AddText("|cFF888780This means your current gear has more of the stats that " .. recName
                    .. " values. Consider respeccing or regearing if you want to stay " .. GetSpecNameByID(activeSpecID) .. ".|r", 9, 0.5, 0.5, 0.5)
                if weaponNotes[bestSpec] then
                    AddText("|cFFFF8800⚠ Weapon excluded:|r Your equipped weapon type isn't usable by "
                        .. recName .. ". Score is based on armor + accessories only — you'd need a different weapon to actually respec.", 9, 0.7, 0.5, 0.2)
                end
                y = y - 4

                -- Show all spec scores as a comparison
                local sortedSpecs = {}
                for sID, score in pairs(scores) do
                    table.insert(sortedSpecs, { id = sID, score = score })
                end
                table.sort(sortedSpecs, function(a, b) return a.score > b.score end)
                for _, entry in ipairs(sortedSpecs) do
                    local sName = GetSpecNameByID(entry.id)
                    local isActive = (entry.id == activeSpecID)
                    local color = isActive and "|cFF4AFF7A" or "|cFFAAAAAA"
                    local tag   = isActive and " ← active" or ""
                    local wpnTag = weaponNotes[entry.id] and " |cFF888780(no weapon)|r" or ""
                    AddText(color .. sName .. "|r: " .. U.FormatNumber(entry.score) .. " gear score" .. tag .. wpnTag, 9, 0.6, 0.6, 0.6)
                end
                y = y - 4
            end
        end
    end

    content:SetHeight(math.abs(y) + 20)
end

-- ── Sidebar ───────────────────────────────────────────────────────────────
function Talents:RenderSidebar(parent, activeSpecID)
    local y = -8
    local w = parent:GetWidth() - 12

    local function Track(f) table.insert(self.sideFrames, f) return f end

    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hdr:SetText("SPECIALIZATIONS")
    hdr:SetTextColor(0.62, 0.59, 0.55, 1)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    Track(hdr)

    -- Class color for active highlight (borderless text token style)
    local _, playerClass = UnitClass("player")
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]
    local cr, cg, cb = 0.40, 0.75, 1.00  -- fallback accent blue
    if classColor then cr, cg, cb = classColor.r, classColor.g, classColor.b end

    local numSpecs = GetNumSpecializations() or 3
    for i = 1, numSpecs do
        local id, name, _, icon = GetSpecializationInfo(i)
        if id then
            local isSelected = (id == self.selectedSpecID)
            local isActive   = (id == activeSpecID)
            local rdsp       = RoleOf(id)

            -- Borderless text-token button (no heavy box backdrop)
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(w, 46)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
            btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            if isSelected then
                btn:SetBackdropColor(cr * 0.15, cg * 0.15, cb * 0.15, 0.95)
                btn:SetBackdropBorderColor(cr, cg, cb, 0.80)
            else
                btn:SetBackdropColor(0.04, 0.04, 0.05, 0.80)
                btn:SetBackdropBorderColor(0.20, 0.20, 0.24, 0.30)
            end

            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(22, 22)
            ico:SetPoint("LEFT", btn, "LEFT", 6, 0)
            ico:SetTexture(icon)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            lbl:SetText(name .. (isActive and " |cFF4AFF7A●|r" or ""))
            -- Class-colored when selected, neutral when not
            if isSelected then
                lbl:SetTextColor(cr, cg, cb, 1)
            else
                lbl:SetTextColor(0.72, 0.70, 0.65, 1)
            end
            lbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 34, -7)

            local roleLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            roleLbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            roleLbl:SetText(rdsp.label)
            roleLbl:SetTextColor(rdsp.r, rdsp.g, rdsp.b, 0.75)
            roleLbl:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 34, 7)

            btn:SetScript("OnClick", function()
                self.selectedSpecID = id
                self.viewBuildType  = GetGroupMode()
                self:Render(TA.UI.contentChild, TA.UI.sideChild)
            end)

            y = y - 50
            Track(btn)
        end
    end

    y = y - 4
    local div = parent:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("TOPLEFT",  parent, "TOPLEFT",  4, y)
    div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
    div:SetColorTexture(0.55, 0.40, 0.08, 0.2)
    y = y - 8
    Track(div)

    -- ── Role display for the selected spec ─────────────────────────────
    -- Pure DPS specs get a plain label; tanks/healers get a highlighted badge.
    local roleHdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    roleHdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    roleHdr:SetText("ROLE")
    roleHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    roleHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    Track(roleHdr)

    local rinfo = TAPI.GetSpecInfo(self.selectedSpecID)
    if rinfo.role == "DAMAGER" then
        local styleTxt = rinfo.style == "ranged" and "Ranged DPS" or "Melee DPS"
        local rdot     = rinfo.style == "ranged" and {1.00, 0.72, 0.29} or {1.00, 0.42, 0.29}
        local roleBadge = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        roleBadge:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        roleBadge:SetText(styleTxt)
        roleBadge:SetTextColor(rdot[1], rdot[2], rdot[3], 1)
        roleBadge:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
        y = y - 18
        Track(roleBadge)
    else
        local roleLabel = rinfo.role == "TANK" and "Tank" or "Healer"
        local rc = rinfo.role == "TANK"
            and {r=0.29, g=0.65, b=1.00}
            or  {r=0.29, g=1.00, b=0.48}

        local rbtn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        rbtn:SetSize(w - 4, 28)
        rbtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
        rbtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        rbtn:SetBackdropColor(rc.r * 0.10, rc.g * 0.10, rc.b * 0.10, 1)
        rbtn:SetBackdropBorderColor(rc.r, rc.g, rc.b, 0.7)
        Track(rbtn)

        local rlbl = rbtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rlbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        rlbl:SetText(roleLabel)
        rlbl:SetTextColor(rc.r, rc.g, rc.b, 1)
        rlbl:SetAllPoints(rbtn)
        rlbl:SetJustifyH("CENTER")

        y = y - 34
    end

    y = y - 6
    local footer = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    footer:SetFont(STANDARD_TEXT_FONT, 8)
    footer:SetText("Auto-mode: |cFFFFD100" .. GetGroupMode():upper() .. "|r\n(updates by group type)")
    footer:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    footer:SetWidth(w)
    footer:SetJustifyH("LEFT")
    Track(footer)
end

-- ── Safe copy frame ────────────────────────────────────────────────────────
-- Created once; reused on subsequent calls to avoid widget accumulation.
function Talents:OpenSafeCopyFrame(buildName, importString)
    if self.copyFrame then
        self.copyFrame.label:SetText("Ctrl+C to copy:  " .. (buildName or "Import String"))
        self.copyFrame.editbox:SetText(importString or "")
        self.copyFrame.editbox:HighlightText()
        self.copyFrame.editbox:SetFocus()
        self.copyFrame:Show()
        return
    end

    local cf = CreateFrame("Frame", "ToonAgeCopyFrame", UIParent, "BackdropTemplate")
    cf:SetSize(440, 110)
    cf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    cf:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    cf:SetBackdropColor(0.02, 0.02, 0.02, 0.98)
    cf:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    cf:SetFrameStrata("DIALOG")
    cf:SetMovable(true)
    cf:EnableMouse(true)
    cf:RegisterForDrag("LeftButton")
    cf:SetScript("OnDragStart", cf.StartMoving)
    cf:SetScript("OnDragStop",  cf.StopMovingOrSizing)

    local lbl = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    lbl:SetText("Ctrl+C to copy:  " .. (buildName or "Import String"))
    lbl:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -12)
    cf.label = lbl

    local eb = CreateFrame("EditBox", nil, cf, "InputBoxTemplate")
    eb:SetSize(416, 24)
    eb:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -32)
    eb:SetMultiLine(false)
    eb:SetAutoFocus(true)
    eb:SetText(importString or "")
    eb:HighlightText()
    eb:SetScript("OnEscapePressed", function() cf:Hide() end)
    cf.editbox = eb

    local closeBtn = CreateFrame("Button", nil, cf, "BackdropTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -12, 10)
    closeBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    closeBtn:SetBackdropColor(0.15, 0.03, 0.03, 1)
    closeBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)
    local cLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    cLbl:SetText("Close")
    cLbl:SetAllPoints(closeBtn)
    cLbl:SetJustifyH("CENTER")
    closeBtn:SetScript("OnClick", function() cf:Hide() end)

    self.copyFrame = cf
    cf:Show()
end

-- ── Import & Assess frame ─────────────────────────────────────────────────────
-- A popup where the player can paste any talent import string (from a friend,
-- website, streamer, etc.) and ToonAge will:
--   1. Store it as the recommended build for the current content type
--   2. Show it in the "Copy Import String" button for future use
--   3. Score it against your current loadout (match %)
--
-- This also doubles as the "generate from my active talents" path: if the
-- player leaves the box empty and clicks "Use My Active Loadout", ToonAge
-- reads the live export string from C_ClassTalents and stores it.

function Talents:OpenImportFrame()
    if self.importFrame then
        self.importFrame:Show()
        self.importFrame.editbox:SetText("")
        self.importFrame.editbox:SetFocus()
        return
    end

    local cf = CreateFrame("Frame", "ToonAgeImportFrame", UIParent, "BackdropTemplate")
    cf:SetSize(480, 180)
    cf:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    cf:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    cf:SetBackdropColor(0.02, 0.02, 0.02, 0.98)
    cf:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    cf:SetFrameStrata("DIALOG")
    cf:SetMovable(true)
    cf:EnableMouse(true)
    cf:RegisterForDrag("LeftButton")
    cf:SetScript("OnDragStart", cf.StartMoving)
    cf:SetScript("OnDragStop",  cf.StopMovingOrSizing)

    -- Title
    local lbl = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    lbl:SetText("|cFFFFD100Import Talent Build|r")
    lbl:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -12)

    -- Instructions
    local inst = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inst:SetFont(STANDARD_TEXT_FONT, 9, "")
    inst:SetText("Paste a talent import string below (from Wowhead, Icy Veins, a friend, etc.)\nOr click 'Use My Active Loadout' to capture your currently equipped talents.")
    inst:SetTextColor(0.6, 0.6, 0.6, 1)
    inst:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -28)
    inst:SetWidth(456)

    -- EditBox for pasting
    local eb = CreateFrame("EditBox", nil, cf, "InputBoxTemplate")
    eb:SetSize(456, 24)
    eb:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -60)
    eb:SetMultiLine(false)
    eb:SetAutoFocus(true)
    eb:SetScript("OnEscapePressed", function() cf:Hide() end)
    cf.editbox = eb

    -- "Import & Save" button
    local importBtn = CreateFrame("Button", nil, cf, "BackdropTemplate")
    importBtn:SetSize(140, 26)
    importBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -92)
    importBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    importBtn:SetBackdropColor(0.04, 0.08, 0.04, 1)
    importBtn:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.7)
    local impLbl = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    impLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    impLbl:SetText("Import & Save")
    impLbl:SetTextColor(0.29, 1.00, 0.48, 1)
    impLbl:SetAllPoints(importBtn)
    impLbl:SetJustifyH("CENTER")
    importBtn:SetScript("OnClick", function()
        local str = eb:GetText():match("^%s*(.-)%s*$")
        if not str or #str < 20 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r String too short — paste a valid talent import string.")
            return
        end
        local specID = self.selectedSpecID or U.GetPlayerSpec()
        local viewType = self.viewBuildType or "solo"
        TA.charDB.customBuilds = TA.charDB.customBuilds or {}
        TA.charDB.customBuilds[specID] = TA.charDB.customBuilds[specID] or {}
        TA.charDB.customBuilds[specID][viewType] = str
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA Talents]|r Imported and saved as |cFF4AFF7A%s|r build for %s.",
            viewType:upper(), GetSpecNameByID(specID)))
        cf:Hide()
        if TA.UI and TA.UI.activeTab == "talents" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end)

    -- "Use My Active Loadout" button
    local activeBtn = CreateFrame("Button", nil, cf, "BackdropTemplate")
    activeBtn:SetSize(180, 26)
    activeBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)
    activeBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    activeBtn:SetBackdropColor(0.08, 0.04, 0.00, 1)
    activeBtn:SetBackdropBorderColor(1, 0.82, 0, 0.6)
    local actLbl = activeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    actLbl:SetText("Use My Active Loadout")
    actLbl:SetTextColor(1, 0.82, 0, 1)
    actLbl:SetAllPoints(activeBtn)
    actLbl:SetJustifyH("CENTER")
    activeBtn:SetScript("OnClick", function()
        if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r C_ClassTalents API not available.")
            return
        end
        local cfgID = C_ClassTalents.GetActiveConfigID()
        if not cfgID then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r No active talent config found.")
            return
        end
        local str = C_Traits and C_Traits.GenerateImportString and C_Traits.GenerateImportString(cfgID)
        if not str or str == "" then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r Could not generate export string from active loadout.")
            return
        end
        local specID = self.selectedSpecID or U.GetPlayerSpec()
        local viewType = self.viewBuildType or "solo"
        TA.charDB.customBuilds = TA.charDB.customBuilds or {}
        TA.charDB.customBuilds[specID] = TA.charDB.customBuilds[specID] or {}
        TA.charDB.customBuilds[specID][viewType] = str
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA Talents]|r Captured active loadout as |cFF4AFF7A%s|r build for %s.",
            viewType:upper(), GetSpecNameByID(specID)))
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780String:|r " .. str:sub(1, 60) .. "...")
        cf:Hide()
        if TA.UI and TA.UI.activeTab == "talents" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end)

    -- Status/feedback line
    local statusF = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusF:SetFont(STANDARD_TEXT_FONT, 9, "")
    statusF:SetText("|cFF888780Will save as: " .. (self.viewBuildType or "solo"):upper()
        .. " build for " .. GetSpecNameByID(self.selectedSpecID or U.GetPlayerSpec() or 0) .. "|r")
    statusF:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -124)
    statusF:SetWidth(456)
    cf.statusF = statusF

    -- Close button
    local closeBtn = CreateFrame("Button", nil, cf, "BackdropTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -12, 12)
    closeBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    closeBtn:SetBackdropColor(0.15, 0.03, 0.03, 1)
    closeBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)
    local cLbl2 = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cLbl2:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    cLbl2:SetText("Cancel")
    cLbl2:SetAllPoints(closeBtn)
    cLbl2:SetJustifyH("CENTER")
    closeBtn:SetScript("OnClick", function() cf:Hide() end)

    self.importFrame = cf
    cf:Show()
end
