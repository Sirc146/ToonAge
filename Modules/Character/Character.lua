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

-- DR (diminishing-returns) soft-cap RATING thresholds — file-scoped (not
-- local to UpdateData) because both UpdateData's stat-row rendering AND
-- BuildUI's OnEnter tooltip closure need to read it, and BuildUI runs once
-- at setup time while UpdateData re-runs on every refresh; a local declared
-- inside UpdateData is invisible to a closure created back in BuildUI.
--
-- These are Blizzard's actual secondary-stat DR breakpoints — the rating at
-- which each stat crosses its 20%-effectiveness-lost tier — confirmed
-- identical across all 39 specs via icy-veins/Wowhead's published DR tables
-- (Patch 12.1 "Midnight" Season 2). Comparing RATING against these (not a
-- flat percentage of the displayed effect %) is what fixes the false "DR
-- cap" positive on stats like Preservation Evoker's Mastery, whose % per
-- rating point runs much higher than other specs' — see the longer comment
-- at the DR_SOFT_CAP use-site in UpdateData for the full explanation.
-- First DR bracket (the 30%-effect breakpoint) in RATING, level 90, Patch
-- 12.0.1 "Midnight" — verified maxroll.gg 2026 "Stat Diminishing Returns".
-- These are the rating at which each secondary FIRST begins losing value
-- (−10% per point beyond this). The earlier 1760/1840/2160 values were the
-- SECOND bracket (the −20% breakpoint), so the old "DR soft cap" readout
-- fired one whole tier late — a stat was already inside its first −10% band
-- before the UI called it capped. Kept in exact sync with Core/StatEngine.lua's
-- DR_BRACKETS (first bound of each). Mastery shares Crit's rating bounds.
local DR_SOFT_CAP = {
    CRIT    = 1380,
    HASTE   = 1320,
    MASTERY = 1380,
    VERS    = 1620,
}

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

    -- Secondary stat rows (4 slots, populated by UpdateData)
    -- Collapsible section header — clickable divider toggles row visibility
    local secHeader = Divider("SECONDARY STATS")
    local secSectionOpen = true

    -- Make the divider header clickable to toggle secondary stats visibility
    if secHeader then
        local hitbox = CreateFrame("Button", nil, content)
        hitbox:SetSize(w, 18)
        hitbox:SetPoint("TOPLEFT", secHeader, "TOPLEFT", -4, 4)
        hitbox:SetPoint("BOTTOMRIGHT", secHeader, "BOTTOMRIGHT", w, -4)
        hitbox:SetScript("OnClick", function()
            secSectionOpen = not secSectionOpen
            for i = 1, 4 do
                local rw = Character.widgets.secRows[i]
                if rw and rw.row then
                    if secSectionOpen then rw.row:Show() else rw.row:Hide() end
                end
            end
            if secSectionOpen then
                secHeader:SetText("\226\150\188 SECONDARY STATS")
            else
                secHeader:SetText("\226\150\182 SECONDARY STATS")
            end
        end)
        hitbox:SetScript("OnEnter", function()
            secHeader:SetTextColor(0.92, 0.90, 0.87, 1)
        end)
        hitbox:SetScript("OnLeave", function()
            secHeader:SetTextColor(0.62, 0.59, 0.55, 1)
        end)
        secHeader:SetText("\226\150\188 SECONDARY STATS")
    end

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

        -- Single sub-line used for DR cap warning or VERS damage-reduction info
        local subLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
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
            local capRating = DR_SOFT_CAP[s.key]
            GameTooltip:AddDoubleLine("DR soft cap", string.format("%d rating", capRating), 0.7,0.7,0.7, 0.6,0.6,0.6)
            if s.rating >= capRating then
                local suggestion = s.redirectTarget and ("Redirect itemization into " .. s.redirectTarget .. " instead.")
                                                     or "Every secondary is capped — prioritize item level instead."
                GameTooltip:AddLine("At or past DR soft cap.", 1, 0.27, 0.27, true)
                GameTooltip:AddLine(suggestion, 0.9, 0.7, 0.3, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        self.widgets.secRows[i] = { row=row, fill=fill, nameLbl=nameLbl, pctLbl=pctLbl,
                                     ratingLbl=ratingLbl, badgeLbl=badgeLbl, subLbl=subLbl }
        cy = cy - 52
    end

    -- Weighted score row — collapsible
    cy = cy - 4
    self.widgets.scoreDiv = Divider("WEIGHTED SCORE")
    local scoreSectionOpen = true
    local scoreRow = CreateFrame("Frame", nil, content, "BackdropTemplate")
    scoreRow:SetSize(w, 34)
    scoreRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, cy)
    Backdrop(scoreRow, 0.06, 0.04, 0.00, 1, 1, 0.82, 0, 0.40)

    -- Make weighted score divider clickable
    if self.widgets.scoreDiv then
        local scoreHitbox = CreateFrame("Button", nil, content)
        scoreHitbox:SetSize(w, 18)
        scoreHitbox:SetPoint("TOPLEFT", self.widgets.scoreDiv, "TOPLEFT", -4, 4)
        scoreHitbox:SetPoint("BOTTOMRIGHT", self.widgets.scoreDiv, "BOTTOMRIGHT", w, -4)
        scoreHitbox:SetScript("OnClick", function()
            scoreSectionOpen = not scoreSectionOpen
            if scoreSectionOpen then
                scoreRow:Show()
                Character.widgets.scoreDiv:SetText("\226\150\188 WEIGHTED SCORE")
            else
                scoreRow:Hide()
                Character.widgets.scoreDiv:SetText("\226\150\182 WEIGHTED SCORE")
            end
        end)
        scoreHitbox:SetScript("OnEnter", function()
            Character.widgets.scoreDiv:SetTextColor(0.92, 0.90, 0.87, 1)
        end)
        scoreHitbox:SetScript("OnLeave", function()
            Character.widgets.scoreDiv:SetTextColor(0.62, 0.59, 0.55, 1)
        end)
        self.widgets.scoreDiv:SetText("\226\150\188 WEIGHTED SCORE")
    end

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
    -- (DR_SOFT_CAP is file-scoped above GetVers() — see comment there — so
    -- both this function and BuildUI's tooltip closure share the same table.)
    local RANK_COLORS = {
        [1] = { 0.76, 0.35, 1.00 },
        [2] = { 0.29, 1.00, 0.48 },
        [3] = { 0.78, 0.73, 0.48 },
        [4] = { 0.45, 0.40, 0.30 },
    }
    local RANK_LABELS = { "#1 Priority", "#2 Priority", "#3", "#4" }

    -- Combat-rating indices below correspond to Blizzard's CR_* constants:
    -- CR_CRIT_MELEE=9, CR_HASTE_MELEE=18, CR_MASTERY=26, CR_VERSATILITY_DAMAGE_DONE=29.
    -- The previous 1/3/14 values were CR_WEAPON_SKILL, CR_DODGE, and
    -- CR_HIT_TAKEN_SPELL — none of which track Crit/Haste/Mastery at all, so
    -- GetCombatRating always returned 0 for those three (only Versatility's
    -- index of 29 was ever correct). The displayed % values were unaffected
    -- (GetCritChance/GetHaste/GetMasteryEffect are separate, correct calls) —
    -- only the "N rating" readout under each stat was silently wrong.
    local secondaries = {
        { key="CRIT",    name="Critical Strike", pct=SafeCall(GetCritChance),    rating=SafeCall(GetCombatRating, 9)  },
        { key="HASTE",   name="Haste",           pct=SafeCall(GetHaste),         rating=SafeCall(GetCombatRating, 18) },
        { key="MASTERY", name="Mastery",         pct=SafeCall(GetMasteryEffect), rating=SafeCall(GetCombatRating, 26) },
        { key="VERS",    name="Versatility",     pct=GetVers(),                  rating=SafeCall(GetCombatRating, 29) },
    }
    -- Priority weight per stat. When the live DR-aware StatEngine is available
    -- AND we're showing the player's OWN active spec (so live combat ratings
    -- apply), use the engine's MARGINAL value — the worth of the NEXT rating
    -- point at the player's current rating, with diminishing returns, pet
    -- inheritance, and tank leans folded in. This is what makes the priority
    -- ordering DR-honest: a stat you've already stacked past its soft cap
    -- correctly falls in rank instead of staying #1 on its static weight.
    -- Off-spec views and PvP mode fall back to the static directional weight.
    local playerSpecID = U.GetPlayerSpecID and U.GetPlayerSpecID()
    local useEngine = TA.StatEngine and pvxMode ~= "pvp" and specID == playerSpecID
    for _, s in ipairs(secondaries) do
        -- staticWeight = spec's directional weight (stable across DR state) —
        -- drives the WEIGHTED SCORE headline so that number stays comparable.
        -- weight = the priority ranking key: DR-aware marginal value when the
        -- live engine is active, else the static weight. The two differ once a
        -- stat is past its soft cap, which is exactly the point of the engine.
        s.staticWeight = weights[s.key] or 0.5
        if useEngine then
            s.weight = TA.StatEngine:GetMarginalValue(s.key, specID)
        else
            s.weight = s.staticWeight
        end
    end
    table.sort(secondaries, function(a, b) return a.weight > b.weight end)

    -- Highest-priority stat that ISN'T at/past the DR soft cap — the actual
    -- redirect target recommended to any stat that is capped. secondaries is
    -- already sorted highest-priority-first (by marginal value when the engine
    -- is active, else by static weight), so the first uncapped entry found is
    -- the correct answer. nil only when every secondary is capped (a real
    -- near-BiS scenario, not a bug) — handled with a distinct message.
    local redirectTarget = nil
    for _, s in ipairs(secondaries) do
        if s.rating < DR_SOFT_CAP[s.key] then
            redirectTarget = s.name
            break
        end
    end

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

        -- DR fill bar — proportion of THIS stat's own rating-based soft cap,
        -- not a shared percentage scale (see DR_SOFT_CAP comment above).
        local capRating = DR_SOFT_CAP[s.key]
        local isCapped  = s.rating >= capRating
        local fillW = math.max((row.row:GetWidth() - 2) * math.min(s.rating / capRating, 1.0), 1)
        row.fill:SetWidth(fillW)
        if isCapped then
            row.fill:SetColorTexture(0.75, 0.10, 0.10, 0.20)
        elseif i == 1 then
            row.fill:SetColorTexture(0.45, 0.08, 0.75, 0.18)
        else
            row.fill:SetColorTexture(0.18, 0.42, 0.18, 0.16)
        end

        -- Sub-line: DR cap warning takes priority; VERS shows damage reduction below cap
        s.redirectTarget = redirectTarget  -- stashed on the stat table so the OnEnter tooltip can reuse it
        if isCapped then
            local suggestion = redirectTarget and ("redirect into " .. redirectTarget)
                                              or "all secondaries capped — prioritize item level"
            row.subLbl:SetText("|cFFFF4444DR cap — " .. suggestion .. "|r")
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

        -- Headline WEIGHTED SCORE uses the STATIC directional weight so the
        -- number is stable and comparable across gear/DR states (the DR effect
        -- is already shown per-row via the badge, fill bar and cap warning).
        -- Mixing the DR-scaled marginal weight in here would make the same
        -- character's score drop as they gear into a soft cap, conflating stat
        -- magnitude with DR state.
        totalScore = totalScore + s.staticWeight * s.pct
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
