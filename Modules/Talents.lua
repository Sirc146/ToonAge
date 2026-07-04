-- CharacterAdvisor/Modules/Talents.lua
-- Role-aware talent advisor: match scoring, role badges, debounced refresh

local CA = CharacterAdvisor
local U  = CA.Utils
local T  = CA.Data.Talents
local TA = CA.TalentsAPI

local Talents = {}
CA:RegisterModule("Talents", Talents)

Talents.frames         = {}
Talents.sideFrames     = {}
Talents.selectedSpecID = nil
Talents.viewBuildType  = nil

-- ── Debounce ──────────────────────────────────────────────────────────────
local refreshTimer = nil
local function ScheduleRefresh()
    if refreshTimer then return end
    refreshTimer = C_Timer.After(0.25, function()
        refreshTimer = nil
        if CA.UI and CA.UI.activeTab == "talents" then
            Talents:Render(CA.UI.contentChild, CA.UI.sideChild)
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
    local info = TA.GetSpecInfo(specID)
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
function Talents:Render(content, sidebar)
    for _, f in ipairs(self.frames)     do f:Hide(); f:SetParent(nil) end
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.frames     = {}
    self.sideFrames = {}

    local activeSpecID = U.GetPlayerSpec()
    if not activeSpecID then return end

    if not self.selectedSpecID then self.selectedSpecID = activeSpecID end
    if not self.viewBuildType  then self.viewBuildType  = GetGroupMode() end

    self:RenderSidebar(sidebar, activeSpecID)
    self:RenderContent(content, activeSpecID)
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
    local types  = { {key="mplus",label="Mythic+"}, {key="raid",label="Raid"}, {key="solo",label="Solo"} }
    local btnW   = math.floor(w / 3) - 2
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
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end)
        Track(btn)
        bx = bx + btnW + 3
    end
    y = y - 32

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

    -- ── Match score card (only when node data exists) ───────────────────
    if build.nodes and #build.nodes > 0 then
        local activeIDs = TA.GetActiveTalentIDs()
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
        local cStr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cStr:SetFont(STANDARD_TEXT_FONT, 9)
        cStr:SetText(U.Truncate(build.string, 60))
        cStr:SetTextColor(0.38, 0.38, 0.38, 1)
        cStr:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 34)
        cStr:SetWidth(w - 170)

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
                print("|cFFFFD100[CA]|r Cannot copy talent string during combat.")
                return
            end
            self:OpenSafeCopyFrame(build.name, build.string)
        end)
    else
        local noStr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noStr:SetFont(STANDARD_TEXT_FONT, 9)
        noStr:SetText("|cFF4A4A4AImport string not yet added for this spec.|r")
        noStr:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 10)
    end

    y = y - cardH - 10

    -- ── 0-Max Milestone & Readiness Card ─────────────────────────────────
    local playerLevel = UnitLevel("player")
    local maxLevel    = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local _, eqILvl   = GetAverageItemLevel()
    local isMaxLevel  = (playerLevel >= maxLevel)

    -- Card height differs: endgame has 4 rows, leveling has title + 2 lines + hint
    local mh = isMaxLevel and 106 or 86
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
        -- Update these thresholds each major patch / season reset.
        local thresholds = {
            { label = "Delves    (Tier 8)",   req = 580 },
            { label = "LFR       (Raid)",     req = 567 },
            { label = "Normal    (Raid)",     req = 590 },
            { label = "Mythic+   (Base key)", req = 580 },
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

        -- Next talent from build.levelPath, or a sensible fallback
        local nextTalent = build.levelPath and build.levelPath[playerLevel]
        local adviceLbl = mcard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        adviceLbl:SetFont(STANDARD_TEXT_FONT, 10)
        adviceLbl:SetWidth(w - 20)
        adviceLbl:SetJustifyH("LEFT")
        adviceLbl:SetPoint("TOPLEFT", mcard, "TOPLEFT", 10, -42)

        if playerLevel < 10 then
            adviceLbl:SetText("Reach |cFFFFD100level 10|r to unlock your first talent point.")
            adviceLbl:SetTextColor(0.70, 0.70, 0.70, 1)
        elseif nextTalent then
            adviceLbl:SetText("Next talent to take:  |cFFFFD100" .. nextTalent .. "|r")
            adviceLbl:SetTextColor(0.70, 0.70, 0.70, 1)
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
        if cfgID and C_ClassTalents.GetExportString then
            local exportStr = C_ClassTalents.GetExportString(cfgID)
            if exportStr and exportStr ~= "" then
                AddLine()
                AddText("|cFF555555Your loadout:|r  " .. U.Truncate(exportStr, 68), 9, 0.45, 0.45, 0.45)
                y = y - 2
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
    hdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    hdr:SetText("SPECIALIZATIONS")
    hdr:SetTextColor(0.55, 0.40, 0.08, 1)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    Track(hdr)

    local numSpecs = GetNumSpecializations() or 3
    for i = 1, numSpecs do
        local id, name, _, icon = GetSpecializationInfo(i)
        if id then
            local isSelected = (id == self.selectedSpecID)
            local isActive   = (id == activeSpecID)
            local rdsp       = RoleOf(id)

            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(w, 46)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
            btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            if isSelected then
                btn:SetBackdropColor(0.12, 0.09, 0.02, 1)
                btn:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            else
                btn:SetBackdropColor(0.04, 0.04, 0.04, 1)
                btn:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.25)
            end

            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(22, 22)
            ico:SetPoint("LEFT", btn, "LEFT", 6, 0)
            ico:SetTexture(icon)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            lbl:SetText(name .. (isActive and " |cFF4AFF7A●|r" or ""))
            lbl:SetTextColor(isSelected and 1 or 0.78, isSelected and 0.82 or 0.73, isSelected and 0 or 0.48, 1)
            lbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 34, -7)

            local roleLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            roleLbl:SetFont(STANDARD_TEXT_FONT, 8)
            roleLbl:SetText(rdsp.label)
            roleLbl:SetTextColor(rdsp.r, rdsp.g, rdsp.b, 0.75)
            roleLbl:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 34, 7)

            btn:SetScript("OnClick", function()
                self.selectedSpecID = id
                self.viewBuildType  = GetGroupMode()
                self:Render(CA.UI.contentChild, CA.UI.sideChild)
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

    local rinfo = TA.GetSpecInfo(self.selectedSpecID)
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

    local cf = CreateFrame("Frame", "CharacterAdvisorCopyFrame", UIParent, "BackdropTemplate")
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

    local eb = CreateFrame("EditBox", nil, cf, "BackdropTemplate")
    eb:SetSize(416, 24)
    eb:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -32)
    eb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    eb:SetBackdropColor(0.08, 0.08, 0.08, 1)
    eb:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    eb:SetMultiLine(false)
    eb:SetAutoFocus(true)
    eb:SetFont(STANDARD_TEXT_FONT, 9)
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
