-- ToonAge/Modules/Character.lua
-- Character tab: 3D model portrait, full stat breakdown with weights and DR visualisers
--
-- Architecture: BuildUI constructs frames once per tab-open; UpdateData only
-- mutates text/colors on events, avoiding frame creation on every stat tick.

local TA = ToonAge
local U  = TA.Utils
local SW = TA.Data.StatWeights

local Character = {}
TA:RegisterModule("Character", Character)

Character.pvxMode     = "pve"
Character.widgets     = {}
Character.sideFrames  = {}   -- tracks 3D model for cleanup on tab reopen
Character.lastContent = nil

-- ── Events ────────────────────────────────────────────────────────────
function Character:OnEvent(event, ...)
    if not (TA.UI and TA.UI.activeTab == "character") then return end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Spec change alters the sidebar overlay text, so force full rebuild
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

local function GetVers()
    local ok, cr = pcall(GetCombatRating, 29)
    if ok and cr then return SafeCall(GetVersatilityBonus, SafeNum(cr)) end
    return 0
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

-- ── Sidebar: 3D portrait with identity overlay ────────────────────────
-- Parented to TA.UI.sidebar (the persistent frame, not the scroll child)
-- so the model is not clipped by the scroll region.
function Character:RenderSidebar(sideChild)
    local container = TA.UI.sidebar
    if not container then return end

    local model = CreateFrame("PlayerModel", nil, container)
    model:SetAllPoints(container)
    model:SetFrameLevel(container:GetFrameLevel() + 5)
    model:SetUnit("player")
    model:SetAnimation(0)
    model:SetCamDistanceScale(1.10)
    model:SetFacing(math.pi / 8)
    model:SetPosition(0, 0, -0.05)
    table.insert(self.sideFrames, model)

    -- Bottom gradient so text overlays are readable
    local fade = model:CreateTexture(nil, "OVERLAY")
    fade:SetPoint("BOTTOMLEFT",  model, "BOTTOMLEFT",  0, 0)
    fade:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
    fade:SetHeight(180)
    fade:SetGradient("VERTICAL",
        CreateColor(0.04, 0.03, 0.01, 0),
        CreateColor(0.04, 0.03, 0.01, 0.96))

    -- Right-edge fade into the content border
    local edge = model:CreateTexture(nil, "OVERLAY")
    edge:SetPoint("TOPRIGHT",    model, "TOPRIGHT",    0, 0)
    edge:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
    edge:SetWidth(28)
    edge:SetGradient("HORIZONTAL",
        CreateColor(0, 0, 0, 0),
        CreateColor(0.04, 0.03, 0.01, 0.85))

    local nameF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameF:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
    nameF:SetText(UnitName("player") or "")
    nameF:SetTextColor(1, 0.82, 0, 1)
    nameF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 74)
    nameF:SetWidth(container:GetWidth() - 16)
    nameF:SetJustifyH("LEFT")

    local _, specName = U.GetPlayerSpec()
    local class       = U.GetPlayerClass()
    local classLabel  = class:lower():gsub("^%l", string.upper)
    local subF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    subF:SetText("Level " .. U.GetPlayerLevel() .. "  ·  " .. (specName or classLabel) .. " " .. classLabel)
    subF:SetTextColor(0.72, 0.67, 0.52, 1)
    subF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 52)
    subF:SetWidth(container:GetWidth() - 16)
    subF:SetJustifyH("LEFT")

    local ilvlF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlF:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    ilvlF:SetText("Item Level  " .. U.GetAverageIlvl())
    ilvlF:SetTextColor(0.64, 0.21, 0.93, 1)
    ilvlF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 30)
    ilvlF:SetWidth(container:GetWidth() - 16)
    ilvlF:SetJustifyH("LEFT")

    local roleStr  = U.IsHealer() and "Healer" or U.IsTank() and "Tank" or "DPS"
    local groupStr = U.GetGroupType() == "solo"  and "Solo"
                  or U.GetGroupType() == "party" and "Party / M+"
                  or "Raid"
    local ctxF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ctxF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    ctxF:SetText(roleStr .. "  ·  " .. groupStr)
    ctxF:SetTextColor(0.48, 0.42, 0.28, 1)
    ctxF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 10)
    ctxF:SetWidth(container:GetWidth() - 16)
    ctxF:SetJustifyH("LEFT")

    -- Hide the model when this sideChild is replaced (tab switch)
    sideChild:HookScript("OnHide", function() model:Hide() end)
end

-- ── One-time UI construction ──────────────────────────────────────────
function Character:BuildUI(content, sidebar)
    self.widgets = {}

    local w, padL = content:GetWidth() - 28, 14
    local cy = -10

    -- Build sidebar portrait first
    self:RenderSidebar(sidebar)

    local function Divider(label)
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        f:SetText(label)
        f:SetTextColor(0.55, 0.40, 0.08, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        cy = cy - 14
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  cy)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, cy)
        line:SetColorTexture(0.55, 0.40, 0.08, 0.35)
        cy = cy - 8
        return f
    end

    -- Mode toggle button
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
    self.widgets.primName:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    self.widgets.primName:SetTextColor(0.78, 0.73, 0.48, 1)
    self.widgets.primName:SetPoint("LEFT", primRow, "LEFT", 12, 4)

    self.widgets.primVal = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.primVal:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    self.widgets.primVal:SetTextColor(1, 0.82, 0, 1)
    self.widgets.primVal:SetPoint("RIGHT", primRow, "RIGHT", -14, 4)

    self.widgets.primSub = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.primSub:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    self.widgets.primSub:SetTextColor(0.45, 0.40, 0.28, 1)
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

    -- Secondary stat rows (4 slots, populated by UpdateData)
    Divider("SECONDARY STATS")
    self.widgets.secRows = {}

    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },
        [2] = { 0.29, 1.00, 0.48 },
        [3] = { 0.78, 0.73, 0.48 },
        [4] = { 0.45, 0.40, 0.30 },
    }

    for i = 1, 4 do
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(w, 46)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        Backdrop(row, 0.03, 0.03, 0.03, 0.95)

        local fill = row:CreateTexture(nil, "BACKGROUND")
        fill:SetPoint("TOPLEFT",    row, "TOPLEFT",    1, -1)
        fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1,  1)

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        nameLbl:SetTextColor(0.72, 0.68, 0.52, 1)
        nameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        local pctLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctLbl:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
        pctLbl:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -4)

        local ratingLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ratingLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        ratingLbl:SetTextColor(0.42, 0.38, 0.26, 1)
        ratingLbl:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)

        local badgeLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        badgeLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        badgeLbl:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -12, 5)

        -- Single sub-line used for DR cap warning or VERS damage-reduction info
        local subLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        subLbl:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -1)

        row:SetScript("OnEnter", function(btn)
            local s = btn._statData
            if not s then return end
            local rc = RANK_COLORS[btn._rank] or RANK_COLORS[4]
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(s.name, 1, 0.82, 0)
            GameTooltip:AddDoubleLine("Rating",  string.format("%d", math.floor(s.rating)),    0.7,0.7,0.7, 1,1,1)
            GameTooltip:AddDoubleLine("Percent", string.format("%.2f%%", s.pct),               0.7,0.7,0.7, rc[1],rc[2],rc[3])
            GameTooltip:AddDoubleLine("Weight (" .. (Character.pvxMode == "pve" and "PvE" or "PvP") .. ")",
                string.format("%.2f", s.weight), 0.7,0.7,0.7, rc[1],rc[2],rc[3])
            if s.key == "VERS" then
                GameTooltip:AddDoubleLine("Damage reduction", string.format("%.2f%%", s.pct / 2), 0.7,0.7,0.7, 0.45,0.60,0.75)
            end
            if s.pct >= 33.0 then
                GameTooltip:AddLine("At or past DR soft cap.", 1, 0.27, 0.27, true)
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
    self.widgets.scoreDiv = Divider("WEIGHTED SCORE")
    local scoreRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    scoreRow:SetSize(w, 34)
    scoreRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(scoreRow, 0.06, 0.04, 0.00, 1, 1, 0.82, 0, 0.40)

    self.widgets.scoreLbl = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.scoreLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    self.widgets.scoreLbl:SetTextColor(0.78, 0.73, 0.48, 1)
    self.widgets.scoreLbl:SetPoint("LEFT", scoreRow, "LEFT", 12, 0)

    self.widgets.scoreVal = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.widgets.scoreVal:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
    self.widgets.scoreVal:SetTextColor(1, 0.82, 0, 1)
    self.widgets.scoreVal:SetPoint("RIGHT", scoreRow, "RIGHT", -12, 0)

    cy = cy - 40
    content:SetHeight(math.abs(cy) + 20)
end

-- ── Live data update ──────────────────────────────────────────────────
-- Mutates existing widgets only — no frame creation.
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

    -- Secondaries sorted by weight
    local SOFT_CAP = 33.0
    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },
        [2] = { 0.29, 1.00, 0.48 },
        [3] = { 0.78, 0.73, 0.48 },
        [4] = { 0.45, 0.40, 0.30 },
    }
    local RANK_LABELS = { "#1 Priority", "#2 Priority", "#3", "#4" }

    local secondaries = {
        { key="CRIT",    name="Critical Strike", pct=SafeCall(GetCritChance),    rating=SafeCall(GetCombatRating, 1)  },
        { key="HASTE",   name="Haste",           pct=SafeCall(GetHaste),         rating=SafeCall(GetCombatRating, 3)  },
        { key="MASTERY", name="Mastery",         pct=SafeCall(GetMasteryEffect), rating=SafeCall(GetCombatRating, 14) },
        { key="VERS",    name="Versatility",     pct=GetVers(),                  rating=SafeCall(GetCombatRating, 29) },
    }
    for _, s in ipairs(secondaries) do s.weight = weights[s.key] or 0.5 end
    table.sort(secondaries, function(a, b) return a.weight > b.weight end)

    local totalScore = 0

    for i, s in ipairs(secondaries) do
        local row = self.widgets.secRows[i]
        local rc  = RANK_COLORS[i]

        -- Store data for tooltip (no closures needed)
        row.row._statData = s
        row.row._rank     = i

        -- Border highlight for top priority
        if i == 1 then
            row.row:SetBackdropBorderColor(0.55, 0.18, 0.85, 0.55)
        else
            row.row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.40)
        end

        -- DR fill bar
        local fillW = math.max((row.row:GetWidth() - 2) * math.min(s.pct / SOFT_CAP, 1.0), 1)
        row.fill:SetWidth(fillW)
        if s.pct >= SOFT_CAP then
            row.fill:SetColorTexture(0.75, 0.10, 0.10, 0.20)
        elseif i == 1 then
            row.fill:SetColorTexture(0.45, 0.08, 0.75, 0.18)
        else
            row.fill:SetColorTexture(0.18, 0.42, 0.18, 0.16)
        end

        -- Sub-line: DR cap warning takes priority; VERS shows damage reduction below cap
        if s.pct >= SOFT_CAP then
            row.subLbl:SetText("|cFFFF4444DR cap — redirect into " .. RANK_LABELS[1] .. " stat|r")
        elseif s.key == "VERS" then
            row.subLbl:SetText(string.format("|cFF7399BF%.2f%% damage reduction|r", s.pct / 2))
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
    self.widgets.scoreDiv:SetText("WEIGHTED SCORE  (" .. (pvxMode == "pve" and "PvE" or "PvP") .. ")")
    self.widgets.scoreLbl:SetText("Relative stat value for " .. (specName or "this spec"))
    totalScore = totalScore + primWeight * (effPrimary / 500)
    self.widgets.scoreVal:SetText(string.format("%.1f", totalScore))
end

-- ── Render entry point ────────────────────────────────────────────────
function Character:Render(content, sidebar)
    if self.lastContent ~= content then
        -- Clean up old 3D model before building new sidebar
        for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
        self.sideFrames = {}

        self:BuildUI(content, sidebar)
        self.lastContent = content
    end
    self:UpdateData()
end
