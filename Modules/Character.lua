-- ToonAge/Modules/Character.lua (Classic — MoP 5.4.x / Interface 50504)
-- Character tab: stat breakdown with weights.
-- Adapted from Retail version:
--   - No Versatility stat (does not exist in MoP)
--   - Added Hit/Expertise (MoP rating stats)
--   - Uses GetSpecialization()/GetSpecializationInfo() (available in MoP)
--   - No 3D PlayerModel (uses simpler identity text instead)
--   - No CreateColor() gradient calls (not available in MoP)

local TA = ToonAge
local U  = TA.Utils
local SW = TA.Data.StatWeights

local Character = {}
TA:RegisterModule("Character", Character)

Character.pvxMode     = "pve"
Character.widgets     = {}
Character.lastContent = nil

-- ── Events ────────────────────────────────────────────────────────────
function Character:OnEvent(event, ...)
    if not (TA.UI and TA.UI.activeTab == "character") then return end

    if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        self.lastContent = nil
        self:Render(TA.UI.contentChild, TA.UI.sideChild)
    elseif event == "PLAYER_LEVEL_UP"
        or event == "UNIT_INVENTORY_CHANGED"
        or event == "PLAYER_EQUIPMENT_CHANGED" then
        self:UpdateData()
    end
end

-- ── Numeric helpers ───────────────────────────────────────────────────
local function SafeNum(v)
    if not v then return 0 end
    local ok, n = pcall(function() return v + 0 end)
    return (ok and type(n) == "number") and n or 0
end

local function SafeCall(fn, ...)
    local ok, v = pcall(fn, ...)
    return ok and SafeNum(v) or 0
end

-- ── Backdrop shorthand ────────────────────────────────────────────────
local function Backdrop(frame, br, bg, bb, ba, er, eg, eb, ea)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(br or 0.03, bg or 0.03, bb or 0.03, ba or 0.95)
    frame:SetBackdropBorderColor(er or 0.35, eg or 0.28, eb or 0.06, ea or 0.40)
end

-- ── Sidebar: character identity ───────────────────────────────────────
function Character:RenderSidebar(sideChild)
    local container = sideChild
    if not container then return end

    local y = -12

    local nameF = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameF:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
    nameF:SetText(UnitName("player") or "")
    nameF:SetTextColor(1, 0.82, 0, 1)
    nameF:SetPoint("TOPLEFT", container, "TOPLEFT", 12, y)
    nameF:SetWidth(container:GetWidth() - 16)
    nameF:SetJustifyH("LEFT")
    y = y - 22

    local _, specName = U.GetPlayerSpec()
    local class       = U.GetPlayerClass()
    local classLabel  = class:lower():gsub("^%l", string.upper)
    local subF = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    subF:SetText("Level " .. U.GetPlayerLevel() .. "  ·  " .. (specName or classLabel) .. " " .. classLabel)
    subF:SetTextColor(0.72, 0.67, 0.52, 1)
    subF:SetPoint("TOPLEFT", container, "TOPLEFT", 12, y)
    subF:SetWidth(container:GetWidth() - 16)
    subF:SetJustifyH("LEFT")
    y = y - 18

    local ilvlF = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlF:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    ilvlF:SetText("Item Level  " .. U.GetAverageIlvl())
    ilvlF:SetTextColor(0.64, 0.21, 0.93, 1)
    ilvlF:SetPoint("TOPLEFT", container, "TOPLEFT", 12, y)
    ilvlF:SetWidth(container:GetWidth() - 16)
    ilvlF:SetJustifyH("LEFT")
    y = y - 18

    local roleStr  = U.IsHealer() and "Healer" or U.IsTank() and "Tank" or "DPS"
    local groupStr = U.GetGroupType() == "solo"  and "Solo"
                  or U.GetGroupType() == "party" and "Party"
                  or "Raid"
    local ctxF = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ctxF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    ctxF:SetText(roleStr .. "  ·  " .. groupStr)
    ctxF:SetTextColor(0.48, 0.42, 0.28, 1)
    ctxF:SetPoint("TOPLEFT", container, "TOPLEFT", 12, y)
    ctxF:SetWidth(container:GetWidth() - 16)
    ctxF:SetJustifyH("LEFT")
end

-- ── One-time UI construction ──────────────────────────────────────────
function Character:BuildUI(content, sidebar)
    self.widgets = {}

    local w, padL = content:GetWidth() - 28, 14
    local cy = -10

    self:RenderSidebar(sidebar)

    local function Divider(label)
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        f:SetText(label)
        f:SetTextColor(0.62, 0.59, 0.55, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        cy = cy - 14
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  cy)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, cy)
        line:SetColorTexture(0.30, 0.30, 0.35, 0.40)
        cy = cy - 8
        return f
    end

    -- Mode toggle button (PvE/PvP)
    local modeBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    modeBtn:SetSize(80, 20)
    modeBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, cy)
    Backdrop(modeBtn, 0.10, 0.08, 0.00, 1, 1, 0.82, 0, 0.7)
    local modeLbl = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    modeLbl:SetTextColor(1, 0.82, 0, 1)
    modeLbl:SetAllPoints(modeBtn)
    modeBtn:SetScript("OnClick", function()
        Character.pvxMode = Character.pvxMode == "pve" and "pvp" or "pve"
        Character:UpdateData()
    end)
    self.widgets.modeLbl = modeLbl

    -- Primary attribute row
    Divider("PRIMARY ATTRIBUTE")
    local primRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    primRow:SetSize(w, 40)
    primRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(primRow, 0.08, 0.06, 0.01, 1, 1, 0.82, 0, 0.50)

    self.widgets.primName = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.primName:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    self.widgets.primName:SetTextColor(0.82, 0.78, 0.70, 1)
    self.widgets.primName:SetPoint("LEFT", primRow, "LEFT", 12, 4)

    self.widgets.primVal = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.primVal:SetFont("Fonts\\ARIALN.TTF", 18, "OUTLINE")
    self.widgets.primVal:SetTextColor(0.92, 0.90, 0.87, 1)
    self.widgets.primVal:SetPoint("RIGHT", primRow, "RIGHT", -14, 4)

    self.widgets.primSub = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.primSub:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.widgets.primSub:SetTextColor(0.50, 0.47, 0.42, 1)
    self.widgets.primSub:SetPoint("BOTTOMLEFT", primRow, "BOTTOMLEFT", 12, 5)

    cy = cy - 46

    -- Stamina / HP row
    local stamRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    stamRow:SetSize(w, 26)
    stamRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(stamRow, 0.03, 0.03, 0.03, 0.9)

    local stamLbl = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stamLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    stamLbl:SetText("Stamina")
    stamLbl:SetTextColor(0.52, 0.48, 0.36, 1)
    stamLbl:SetPoint("LEFT", stamRow, "LEFT", 12, 0)

    self.widgets.stamVal = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.stamVal:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    self.widgets.stamVal:SetTextColor(0.70, 0.66, 0.50, 1)
    self.widgets.stamVal:SetPoint("LEFT", stamRow, "LEFT", 120, 0)

    self.widgets.hpLbl = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.hpLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    self.widgets.hpLbl:SetTextColor(0.35, 0.56, 0.35, 1)
    self.widgets.hpLbl:SetPoint("RIGHT", stamRow, "RIGHT", -12, 0)

    cy = cy - 32

    -- Secondary stat rows (5: Crit, Haste, Mastery, Hit, Expertise)
    -- MoP does NOT have Versatility. It HAS Hit + Expertise as rating stats.
    Divider("SECONDARY STATS")

    self.widgets.secRows = {}

    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },
        [2] = { 0.29, 1.00, 0.48 },
        [3] = { 0.78, 0.73, 0.48 },
        [4] = { 0.45, 0.40, 0.30 },
        [5] = { 0.45, 0.40, 0.30 },
    }

    for i = 1, 5 do
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(w, 46)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        Backdrop(row, 0.03, 0.03, 0.03, 0.95)

        local fill = row:CreateTexture(nil, "BACKGROUND")
        fill:SetPoint("TOPLEFT",    row, "TOPLEFT",    1, -1)
        fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1,  1)

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        nameLbl:SetTextColor(0.82, 0.78, 0.70, 1)
        nameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        local pctLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctLbl:SetFont("Fonts\\ARIALN.TTF", 17, "OUTLINE")
        pctLbl:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -4)

        local ratingLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ratingLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        ratingLbl:SetTextColor(0.50, 0.47, 0.42, 1)
        ratingLbl:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)

        local badgeLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        badgeLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        badgeLbl:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -12, 5)

        local subLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        subLbl:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -1)

        row:SetScript("OnEnter", function(btn)
            local s = btn._statData
            if not s then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(s.name, 1, 0.82, 0)
            GameTooltip:AddDoubleLine("Rating",  string.format("%d", math.floor(s.rating)),  0.7,0.7,0.7, 1,1,1)
            GameTooltip:AddDoubleLine("Percent", string.format("%.2f%%", s.pct),             0.7,0.7,0.7, 1,1,1)
            GameTooltip:AddDoubleLine("Weight (" .. (Character.pvxMode == "pve" and "PvE" or "PvP") .. ")",
                string.format("%.2f", s.weight), 0.7,0.7,0.7, 1,0.82,0)
            if s.capped then
                GameTooltip:AddLine("|cFF4AFF7ACapped — excess rating is wasted.|r", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        self.widgets.secRows[i] = { row=row, fill=fill, nameLbl=nameLbl, pctLbl=pctLbl,
                                     ratingLbl=ratingLbl, badgeLbl=badgeLbl, subLbl=subLbl }
        cy = cy - 52
    end

    -- Weighted score row
    cy = cy - 4
    Divider("WEIGHTED SCORE")
    local scoreRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    scoreRow:SetSize(w, 34)
    scoreRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(scoreRow, 0.06, 0.04, 0.00, 1, 1, 0.82, 0, 0.40)

    self.widgets.scoreLbl = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.scoreLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    self.widgets.scoreLbl:SetTextColor(0.72, 0.68, 0.60, 1)
    self.widgets.scoreLbl:SetPoint("LEFT", scoreRow, "LEFT", 12, 0)

    self.widgets.scoreVal = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.scoreVal:SetFont("Fonts\\ARIALN.TTF", 17, "OUTLINE")
    self.widgets.scoreVal:SetTextColor(0.92, 0.90, 0.87, 1)
    self.widgets.scoreVal:SetPoint("RIGHT", scoreRow, "RIGHT", -12, 0)

    cy = cy - 40
    content:SetHeight(math.abs(cy) + 20)
end

-- ── Live data update ──────────────────────────────────────────────────
function Character:UpdateData()
    if not self.widgets.primName then return end

    local specID, specName = U.GetPlayerSpec()
    if not specID then return end

    local pvxMode = self.pvxMode
    self.widgets.modeLbl:SetText(pvxMode == "pve" and "Mode: PvE" or "Mode: PvP")

    -- Primary
    local primaryKey = SW:GetPrimary(specID)
    local statIndex  = primaryKey == "STR" and 1 or primaryKey == "AGI" and 2 or 4
    local _, effPrimary = UnitStat("player", statIndex)
    effPrimary = SafeNum(effPrimary)

    local weights    = SW:GetWeights(specID, pvxMode) or {}
    local primWeight = weights[primaryKey] or 1.0

    local STAT_NAMES = { STR="Strength", AGI="Agility", INT="Intellect" }
    self.widgets.primName:SetText(STAT_NAMES[primaryKey] or primaryKey)
    self.widgets.primVal:SetText(string.format("%d", effPrimary))
    self.widgets.primSub:SetText("Primary stat  ·  weight  " .. string.format("%.2f", primWeight))

    -- Stamina / HP
    local _, effStam = UnitStat("player", 3)
    self.widgets.stamVal:SetText(string.format("%d", SafeNum(effStam)))
    self.widgets.hpLbl:SetText("Max HP  " .. U.FormatNumber(UnitHealthMax("player")))

    -- MoP Secondaries: Crit, Haste, Mastery, Hit, Expertise
    -- GetCombatRating IDs in MoP: Crit=9, Haste=18, Mastery=26, Hit=6, Expertise=24
    -- GetCombatRatingBonus returns the percentage from rating
    local secondaries = {
        { key="CRIT",    name="Critical Strike",
          pct=SafeCall(GetCritChance),
          rating=SafeCall(GetCombatRating, 9) },
        { key="HASTE",   name="Haste",
          pct=SafeCall(GetHaste),
          rating=SafeCall(GetCombatRating, 18) },
        { key="MASTERY", name="Mastery",
          pct=SafeCall(GetMastery),
          rating=SafeCall(GetCombatRating, 26) },
        { key="HIT",     name="Hit",
          pct=SafeCall(GetCombatRatingBonus, 6),
          rating=SafeCall(GetCombatRating, 6) },
        { key="EXP",     name="Expertise",
          pct=SafeCall(GetCombatRatingBonus, 24),
          rating=SafeCall(GetCombatRating, 24) },
    }

    -- Check Hit/Exp caps
    for _, s in ipairs(secondaries) do
        s.weight = weights[s.key] or 0.5
        s.capped = false
        if s.key == "HIT" and SW:IsHitCapped(s.rating, specID) then
            s.capped = true
        elseif s.key == "EXP" and SW:IsExpCapped(s.rating, specID) then
            s.capped = true
        end
    end

    table.sort(secondaries, function(a, b) return a.weight > b.weight end)

    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },
        [2] = { 0.29, 1.00, 0.48 },
        [3] = { 0.78, 0.73, 0.48 },
        [4] = { 0.45, 0.40, 0.30 },
        [5] = { 0.45, 0.40, 0.30 },
    }
    local RANK_LABELS = { "#1 Priority", "#2 Priority", "#3", "#4", "#5" }

    local totalScore = 0

    for i, s in ipairs(secondaries) do
        local row = self.widgets.secRows[i]
        if not row then break end
        local rc  = RANK_COLORS[i] or RANK_COLORS[5]

        row.row._statData = s

        -- Border highlight for top priority
        if i == 1 then
            row.row:SetBackdropBorderColor(0.55, 0.18, 0.85, 0.55)
        else
            row.row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.40)
        end

        -- Fill bar (use pct as a proportion of a reasonable max)
        local maxPct = (s.key == "HIT" or s.key == "EXP") and 15 or 40
        local fillW = math.max((row.row:GetWidth() - 2) * math.min(s.pct / maxPct, 1.0), 1)
        row.fill:SetWidth(fillW)
        if s.capped then
            row.fill:SetColorTexture(0.20, 0.70, 0.20, 0.25)
        elseif i == 1 then
            row.fill:SetColorTexture(0.45, 0.08, 0.75, 0.18)
        else
            row.fill:SetColorTexture(0.18, 0.42, 0.18, 0.16)
        end

        -- Sub-line: cap status
        if s.capped then
            row.subLbl:SetText("|cFF4AFF7ACapped — reforge excess into other stats|r")
        else
            row.subLbl:SetText("")
        end

        row.nameLbl:SetText(s.name)
        row.pctLbl:SetText(string.format("%.2f%%", s.pct))
        row.pctLbl:SetTextColor(rc[1], rc[2], rc[3], 1)
        row.ratingLbl:SetText(string.format("%d rating", math.floor(s.rating)))
        row.badgeLbl:SetText(RANK_LABELS[i] .. "  w" .. string.format("%.2f", s.weight))
        row.badgeLbl:SetTextColor(rc[1], rc[2], rc[3], 0.85)

        totalScore = totalScore + s.weight * s.pct
    end

    -- Weighted score
    self.widgets.scoreLbl:SetText("Relative stat value for " .. (specName or "this spec"))
    totalScore = totalScore + primWeight * (effPrimary / 500)
    self.widgets.scoreVal:SetText(string.format("%.1f", totalScore))
end

-- ── Render entry point ────────────────────────────────────────────────
function Character:Render(content, sidebar)
    if self.lastContent ~= content then
        self:BuildUI(content, sidebar)
        self.lastContent = content
    end
    self:UpdateData()
end
