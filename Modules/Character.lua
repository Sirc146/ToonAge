-- CharacterAdvisor/Modules/Character.lua
-- Character tab: 3D model portrait, full stat breakdown with weights and DR visualisers

local CA = CharacterAdvisor
local U  = CA.Utils
local SW = CA.Data.StatWeights

local Character = {}
CA:RegisterModule("Character", Character)

Character.frames     = {}
Character.sideFrames = {}
Character.pvxMode    = "pve"

-- ── Events ────────────────────────────────────────────────────────────
function Character:OnEvent(event, ...)
    if event == "PLAYER_LEVEL_UP"
    or event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "UNIT_INVENTORY_CHANGED"
    or event == "PLAYER_EQUIPMENT_CHANGED" then
        if CA.UI and CA.UI.activeTab == "character" then
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end
    end
end

-- ── Numeric helpers ───────────────────────────────────────────────────
local function SafeNum(v)
    if not v then return 0 end
    if type(v) == "number" then return v end
    return tonumber(tostring(v):match("([%d%.%-]+)")) or 0
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

-- ── Sidebar: full-height 3D portrait with identity overlay ────────────
function Character:RenderSidebar(sideChild)
    -- Parent the model to the actual sidebar container so it is not clipped
    -- by the scroll frame. CA.UI.sidebar is the full-height sidebar frame.
    local container = CA.UI.sidebar
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

    -- Bottom-up gradient so text overlays are readable
    local fade = model:CreateTexture(nil, "OVERLAY")
    fade:SetPoint("BOTTOMLEFT",  model, "BOTTOMLEFT",  0, 0)
    fade:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
    fade:SetHeight(180)
    fade:SetGradient("VERTICAL",
        CreateColor(0.04, 0.03, 0.01, 0),
        CreateColor(0.04, 0.03, 0.01, 0.96))

    -- Right-edge fade into the content pane border
    local edge = model:CreateTexture(nil, "OVERLAY")
    edge:SetPoint("TOPRIGHT",    model, "TOPRIGHT",    0,  0)
    edge:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0,  0)
    edge:SetWidth(28)
    edge:SetGradient("HORIZONTAL",
        CreateColor(0, 0, 0, 0),
        CreateColor(0.04, 0.03, 0.01, 0.85))

    -- Character name
    local nameF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameF:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
    nameF:SetText(UnitName("player") or "")
    nameF:SetTextColor(1, 0.82, 0, 1)
    nameF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 74)
    nameF:SetWidth(container:GetWidth() - 16)
    nameF:SetJustifyH("LEFT")

    -- Level · Spec · Class
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

    -- Item level
    local ilvlF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlF:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    ilvlF:SetText("Item Level  " .. U.GetAverageIlvl())
    ilvlF:SetTextColor(0.64, 0.21, 0.93, 1)
    ilvlF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 30)
    ilvlF:SetWidth(container:GetWidth() - 16)
    ilvlF:SetJustifyH("LEFT")

    -- Role · Group context
    local roleStr  = U.IsHealer() and "Healer" or U.IsTank() and "Tank" or "DPS"
    local groupStr = U.GetGroupType() == "solo" and "Solo"
                     or U.GetGroupType() == "party" and "Party / M+"
                     or "Raid"
    local ctxF = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ctxF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    ctxF:SetText(roleStr .. "  ·  " .. groupStr)
    ctxF:SetTextColor(0.48, 0.42, 0.28, 1)
    ctxF:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 12, 10)
    ctxF:SetWidth(container:GetWidth() - 16)
    ctxF:SetJustifyH("LEFT")

    -- Tear down when the tab changes (sideChild is rebuilt on every tab switch)
    sideChild:HookScript("OnHide", function() model:Hide() end)
end

-- ── Content: stat breakdown ───────────────────────────────────────────
function Character:Render(content, sidebar)
    for _, f in ipairs(self.frames)     do f:Hide(); f:SetParent(nil) end
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.frames     = {}
    self.sideFrames = {}

    local specID, specName = U.GetPlayerSpec()
    if not specID then return end

    self:RenderSidebar(sidebar)

    local w, padL = content:GetWidth() - 28, 14
    local cy = -10

    -- ── Helpers ───────────────────────────────────────────────────────
    local function Track(f) table.insert(self.frames, f); return f end

    local function Divider(label)
        local f = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        f:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        f:SetText(label)
        f:SetTextColor(0.55, 0.40, 0.08, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        cy = cy - 14
        local line = Track(content:CreateTexture(nil, "ARTWORK"))
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  cy)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, cy)
        line:SetColorTexture(0.55, 0.40, 0.08, 0.35)
        cy = cy - 8
    end

    -- ── PvE / PvP mode toggle ─────────────────────────────────────────
    local pvxMode = self.pvxMode
    local modeBtn = Track(CreateFrame("Button", nil, content, "BackdropTemplate"))
    modeBtn:SetSize(80, 20)
    modeBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, cy)
    Backdrop(modeBtn, 0.10, 0.08, 0.00, 1, 1, 0.82, 0, 0.7)
    local modeLbl = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    modeLbl:SetText(pvxMode == "pve" and "Mode: PvE" or "Mode: PvP")
    modeLbl:SetTextColor(1, 0.82, 0, 1)
    modeLbl:SetAllPoints(modeBtn)
    modeBtn:SetScript("OnClick", function()
        Character.pvxMode = Character.pvxMode == "pve" and "pvp" or "pve"
        Character:Render(CA.UI.contentChild, CA.UI.sideChild)
    end)

    -- ── Primary attribute ─────────────────────────────────────────────
    Divider("PRIMARY ATTRIBUTE")

    local primaryKey  = SW:GetPrimary(specID)
    local statIndex   = primaryKey == "STR" and 1 or primaryKey == "AGI" and 2 or 4
    local _, effPrimary = UnitStat("player", statIndex)
    effPrimary = SafeNum(effPrimary)

    local STAT_NAMES = { STR = "Strength", AGI = "Agility", INT = "Intellect" }

    local primRow = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
    primRow:SetSize(w, 40)
    primRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(primRow, 0.08, 0.06, 0.01, 1, 1, 0.82, 0, 0.50)

    local primName = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    primName:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    primName:SetText(STAT_NAMES[primaryKey] or primaryKey)
    primName:SetTextColor(0.78, 0.73, 0.48, 1)
    primName:SetPoint("LEFT", primRow, "LEFT", 12, 4)

    local primVal = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    primVal:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    primVal:SetText(string.format("%d", effPrimary))
    primVal:SetTextColor(1, 0.82, 0, 1)
    primVal:SetPoint("RIGHT", primRow, "RIGHT", -14, 4)

    local primSub = primRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    primSub:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    primSub:SetText("Primary stat  ·  weight  " .. string.format("%.2f", SW:GetWeights(specID, pvxMode) and SW:GetWeights(specID, pvxMode)[primaryKey] or 1.0))
    primSub:SetTextColor(0.45, 0.40, 0.28, 1)
    primSub:SetPoint("BOTTOMLEFT", primRow, "BOTTOMLEFT", 12, 5)

    cy = cy - 46

    -- Stamina / HP row
    local _, effStam = UnitStat("player", 3)
    effStam = SafeNum(effStam)

    local stamRow = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
    stamRow:SetSize(w, 26)
    stamRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(stamRow, 0.03, 0.03, 0.03, 0.9)

    local stamLbl = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stamLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    stamLbl:SetText("Stamina")
    stamLbl:SetTextColor(0.52, 0.48, 0.36, 1)
    stamLbl:SetPoint("LEFT", stamRow, "LEFT", 12, 0)

    local stamVal = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stamVal:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    stamVal:SetText(string.format("%d", effStam))
    stamVal:SetTextColor(0.70, 0.66, 0.50, 1)
    stamVal:SetPoint("LEFT", stamRow, "LEFT", 120, 0)

    local hpLbl = stamRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    hpLbl:SetText("Max HP  " .. U.FormatNumber(UnitHealthMax("player")))
    hpLbl:SetTextColor(0.35, 0.56, 0.35, 1)
    hpLbl:SetPoint("RIGHT", stamRow, "RIGHT", -12, 0)

    cy = cy - 32

    -- ── Secondary stats ───────────────────────────────────────────────
    Divider("SECONDARY STATS")

    local weights = SW:GetWeights(specID, pvxMode) or {}

    local secondaries = {
        { key="CRIT",    name="Critical Strike", pct=SafeCall(GetCritChance),    rating=SafeCall(GetCombatRating, 1)  },
        { key="HASTE",   name="Haste",           pct=SafeCall(GetHaste),         rating=SafeCall(GetCombatRating, 3)  },
        { key="MASTERY", name="Mastery",         pct=SafeCall(GetMasteryEffect), rating=SafeCall(GetCombatRating, 14) },
        { key="VERS",    name="Versatility",     pct=GetVers(),                  rating=SafeCall(GetCombatRating, 29) },
    }

    -- Rank by spec weight so we can badge them in priority order
    for _, s in ipairs(secondaries) do
        s.weight = weights[s.key] or 0.5
    end
    local byWeight = {}
    for i, s in ipairs(secondaries) do byWeight[i] = s end
    table.sort(byWeight, function(a, b) return a.weight > b.weight end)
    local rankOf = {}
    for rank, s in ipairs(byWeight) do rankOf[s.key] = rank end

    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },   -- purple  — #1 priority
        [2] = { 0.29, 1.00, 0.48 },   -- green   — #2
        [3] = { 0.78, 0.73, 0.48 },   -- cream   — #3
        [4] = { 0.45, 0.40, 0.30 },   -- dim     — #4
    }
    local RANK_LABELS = { "#1 Priority", "#2 Priority", "#3", "#4" }

    local SOFT_CAP = 33.0  -- percentage at which DR becomes severe

    for _, s in ipairs(secondaries) do
        local rank  = rankOf[s.key] or 4
        local rc    = RANK_COLORS[rank]
        local isTop = rank == 1

        -- Row frame
        local row = Track(CreateFrame("Button", nil, content, "BackdropTemplate"))
        row:SetSize(w, 46)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
        Backdrop(row, 0.03, 0.03, 0.03, 0.95)
        if isTop then
            row:SetBackdropBorderColor(0.55, 0.18, 0.85, 0.55)
        end

        -- DR fill bar (background texture, full width behind everything)
        local fillPct = math.min(s.pct / SOFT_CAP, 1.0)
        local fill = row:CreateTexture(nil, "BACKGROUND")
        fill:SetPoint("TOPLEFT",    row, "TOPLEFT",    1, -1)
        fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1,  1)
        fill:SetWidth(math.max((w - 2) * fillPct, 1))
        if s.pct >= SOFT_CAP then
            fill:SetColorTexture(0.75, 0.10, 0.10, 0.20)
        elseif isTop then
            fill:SetColorTexture(0.45, 0.08, 0.75, 0.18)
        else
            fill:SetColorTexture(0.18, 0.42, 0.18, 0.16)
        end

        -- Stat name
        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        nameLbl:SetText(s.name)
        nameLbl:SetTextColor(0.72, 0.68, 0.52, 1)
        nameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        -- Percentage — prominent, colour by rank
        local pctLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctLbl:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
        pctLbl:SetText(string.format("%.2f%%", s.pct))
        pctLbl:SetTextColor(rc[1], rc[2], rc[3], 1)
        pctLbl:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -4)

        -- Rating value (bottom-left)
        local ratingLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ratingLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        ratingLbl:SetText(string.format("%d rating", math.floor(s.rating)))
        ratingLbl:SetTextColor(0.42, 0.38, 0.26, 1)
        ratingLbl:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)

        -- Rank badge + weight (bottom-right)
        local badgeLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        badgeLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        badgeLbl:SetText(RANK_LABELS[rank] .. "  w" .. string.format("%.2f", s.weight))
        badgeLbl:SetTextColor(rc[1], rc[2], rc[3], 0.85)
        badgeLbl:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -12, 5)

        -- DR warning overlay
        if s.pct >= SOFT_CAP then
            local drWarn = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            drWarn:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            drWarn:SetText("|cFFFF4444DR cap — redirect into " .. (RANK_LABELS[1]) .. " stat|r")
            drWarn:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -1)
        end

        -- Versatility shows both offensive and defensive values
        if s.key == "VERS" then
            local drPct = s.pct / 2
            local versDR = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            versDR:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            versDR:SetText(string.format("%.2f%% damage reduction", drPct))
            versDR:SetTextColor(0.45, 0.60, 0.75, 1)
            versDR:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -1)
        end

        -- Tooltip
        local capturedS   = s
        local capturedRc  = rc
        local capturedMode = pvxMode
        row:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(capturedS.name, 1, 0.82, 0)
            GameTooltip:AddDoubleLine("Rating",   string.format("%d", math.floor(capturedS.rating)), 0.7,0.7,0.7, 1,1,1)
            GameTooltip:AddDoubleLine("Percent",  string.format("%.2f%%", capturedS.pct),            0.7,0.7,0.7, capturedRc[1],capturedRc[2],capturedRc[3])
            GameTooltip:AddDoubleLine("Weight (" .. (capturedMode == "pve" and "PvE" or "PvP") .. ")", string.format("%.2f", capturedS.weight), 0.7,0.7,0.7, capturedRc[1],capturedRc[2],capturedRc[3])
            if capturedS.key == "VERS" then
                GameTooltip:AddDoubleLine("Damage reduction", string.format("%.2f%%", capturedS.pct / 2), 0.7,0.7,0.7, 0.45,0.60,0.75)
            end
            if capturedS.pct >= SOFT_CAP then
                GameTooltip:AddLine("At or past DR soft cap.", 1, 0.27, 0.27, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        cy = cy - 52
    end

    -- ── Weighted score ────────────────────────────────────────────────
    cy = cy - 4
    Divider("WEIGHTED SCORE  (" .. (pvxMode == "pve" and "PvE" or "PvP") .. ")")

    -- Score = sum of (weight × pct) for secondaries, plus primary contribution
    local totalScore = 0
    for _, s in ipairs(secondaries) do
        totalScore = totalScore + s.weight * s.pct
    end
    local primW = weights[primaryKey] or 1.0
    totalScore = totalScore + primW * (effPrimary / 500)

    local scoreRow = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
    scoreRow:SetSize(w, 34)
    scoreRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(scoreRow, 0.06, 0.04, 0.00, 1, 1, 0.82, 0, 0.40)

    local scoreLbl = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scoreLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    scoreLbl:SetText("Relative stat value for " .. (specName or "this spec"))
    scoreLbl:SetTextColor(0.78, 0.73, 0.48, 1)
    scoreLbl:SetPoint("LEFT", scoreRow, "LEFT", 12, 0)

    local scoreVal = scoreRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scoreVal:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
    scoreVal:SetText(string.format("%.1f", totalScore))
    scoreVal:SetTextColor(1, 0.82, 0, 1)
    scoreVal:SetPoint("RIGHT", scoreRow, "RIGHT", -12, 0)

    cy = cy - 40

    content:SetHeight(math.abs(cy) + 20)
end
