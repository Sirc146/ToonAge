-- ToonAge/Modules/Rotation.lua
-- Rotation tab: spell priority list with real icons, drag-to-bar, auto-updates on talent/level change

local TA   = ToonAge
local U    = TA.Utils
local R    = TA.Data.Rotations
local S    = TA.Data.Spells

local Rotation = {}
TA:RegisterModule("Rotation", Rotation)

-- ── State ──────────────────────────────────────────────────────────────
Rotation.currentView    = "solo"   -- solo | aoe | st
Rotation.currentSpecID  = nil
Rotation.currentLevel   = nil
Rotation.currentRole    = nil
Rotation.frames         = {}

-- ── Init ───────────────────────────────────────────────────────────────
function Rotation:Init()
    local specID = U.GetPlayerSpec()
    self.currentSpecID = specID
    self.currentLevel  = U.GetPlayerLevel()
    self.currentRole   = UnitGroupRolesAssigned("player") or "DAMAGER"

    local groupType = U.GetGroupType()
    if groupType == "solo" then
        self.currentView = "solo"
    elseif groupType == "raid" then
        self.currentView = "st"
    else
        self.currentView = "aoe"
    end

    -- Initialize the floating prediction bar
    self:InitPredictBar()

    -- Default to visible on first login (key missing = new install)
    TA.charDB.predictBar = TA.charDB.predictBar or { visible = true }
    if TA.charDB.predictBar.visible then
        self.predictBar:Show()
    end
end

-- ── Event handler ──────────────────────────────────────────────────────
function Rotation:OnEvent(event, ...)
    if event == "PLAYER_TALENT_UPDATE"
    or event == "ACTIVE_TALENT_GROUP_CHANGED"
    or event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_LEVEL_UP" then
        self.currentSpecID = U.GetPlayerSpec()
        self.currentLevel  = U.GetPlayerLevel()
        self.currentRole   = UnitGroupRolesAssigned("player") or "DAMAGER"

        if TA.UI and TA.UI.activeTab == "rotation" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end

    if event == "GROUP_ROSTER_UPDATE" then
        local groupType = U.GetGroupType()
        if groupType == "solo" then
            self.currentView = "solo"
        elseif groupType == "raid" then
            self.currentView = "st"
        else
            self.currentView = "aoe"
        end
    end
end

--- Get a priority list for prediction, falling back when the active view has none.
--- Three views in Data/Rotations.lua ship a `chain` (a fixed teaching sequence)
--- instead of `priorities`: Preservation Evoker aoe, Augmentation Evoker aoe, and
--- Survival Hunter aoe. GetNextN needs `priorities`, so on those specs the
--- next-3 bar silently went blank — and since `currentView` is set to "aoe" for
--- any 5-man group, that happened every dungeon. Fall back to the spec's solo
--- list so the bar keeps working, rather than showing nothing.
--- @return table|nil priorities, boolean usedFallback
function Rotation:GetPredictionPriorities(specID, view)
    local rotData = R:Get(specID, view)
    if rotData and rotData.priorities then return rotData.priorities, false end

    local soloData = R:Get(specID, "solo")
    if soloData and soloData.priorities then return soloData.priorities, true end

    return nil, false
end

-- ── Main render ────────────────────────────────────────────────────────
function Rotation:Render(content, sidebar)
    for _, f in ipairs(self.frames) do
        f:Hide()
        f:SetParent(nil)
    end
    self.frames = {}

    local specID    = self.currentSpecID or U.GetPlayerSpec()
    local level     = self.currentLevel  or U.GetPlayerLevel()
    local rotData   = R:Get(specID, self.currentView)
    local groupType = U.GetGroupType()

    self:RenderSidebar(sidebar, specID, level, groupType)
    self:RenderContent(content, rotData or {}, specID, level)
end

-- ── Sidebar ────────────────────────────────────────────────────────────
function Rotation:RenderSidebar(parent, specID, level, groupType)
    local y = -8

    local function AddLabel(text, r, g, b, size)
        local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 10, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 1, g or 0.82, b or 0, 1)
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        f:SetWidth(parent:GetWidth() - 12)
        f:SetJustifyH("LEFT")
        y = y - (f:GetStringHeight() + 4)
        table.insert(self.frames, f)
        return f
    end

    local function AddDivider()
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
        line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
        line:SetColorTexture(0.30, 0.30, 0.35, 0.4)
        y = y - 8
        table.insert(self.frames, line)
    end

    AddLabel("View", 0.62, 0.59, 0.55, 9)
    AddDivider()

    local viewLabels = self:GetViewLabels()
    local views = {
        { id="solo", label=viewLabels.solo,  dot={0.33, 0.60, 1.00} },
        { id="aoe",  label=viewLabels.aoe,   dot={1.00, 0.60, 0.10} },
        { id="st",   label=viewLabels.st,    dot={0.29, 1.00, 0.48} },
    }

    for _, view in ipairs(views) do
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetHeight(24)
        btn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  4, y)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

        local isActive = (self.currentView == view.id)
        if isActive then
            btn:SetBackdropColor(0.10, 0.08, 0.00, 1)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.8)
        else
            btn:SetBackdropColor(0.06, 0.06, 0.06, 1)
            btn:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.3)
        end

        local dot = btn:CreateTexture(nil, "ARTWORK")
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", btn, "LEFT", 8, 0)
        dot:SetColorTexture(view.dot[1], view.dot[2], view.dot[3], 1)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        lbl:SetText(view.label)
        lbl:SetTextColor(isActive and 1 or 0.55, isActive and 0.82 or 0.44, isActive and 0 or 0.25, 1)
        lbl:SetPoint("LEFT", btn, "LEFT", 22, 0)
        lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        lbl:SetJustifyH("LEFT")

        btn:SetScript("OnClick", function()
            self.currentView = view.id
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end)

        y = y - 28
        table.insert(self.frames, btn)
    end

    AddDivider()
    AddLabel("Character state", 0.62, 0.59, 0.55, 9)

    local _, specName = U.GetPlayerSpec()
    local statRows = {
        { "Level", tostring(level) },
        { "Spec",  specName or "Unknown" },
        { "Group", groupType == "solo" and "Solo" or groupType == "party" and "Party" or "Raid" },
    }
    for _, row in ipairs(statRows) do
        local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        f:SetText("|cFF8B7040" .. row[1] .. "|r  " .. row[2])
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        f:SetWidth(parent:GetWidth() - 12)
        y = y - 16
        table.insert(self.frames, f)
    end

    AddDivider()
    AddLabel("Overlay", 0.62, 0.59, 0.55, 9)

    -- Prediction bar toggle
    local predictBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    predictBtn:SetHeight(22)
    predictBtn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  4, y)
    predictBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
    predictBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

    local isBarVisible = self.predictBar and self.predictBar:IsVisible()
    predictBtn:SetBackdropColor(isBarVisible and 0.08 or 0.04, isBarVisible and 0.12 or 0.04, isBarVisible and 0.06 or 0.04, 1)
    predictBtn:SetBackdropBorderColor(isBarVisible and 0.20 or 0.35, isBarVisible and 0.92 or 0.28, isBarVisible and 0.40 or 0.06, 0.8)

    local predictLbl = predictBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    predictLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    predictLbl:SetText((isBarVisible and "|cFF4AFF7A●|r " or "|cFF666666●|r ") .. "Next 3 Bar")
    predictLbl:SetPoint("LEFT", predictBtn, "LEFT", 8, 0)
    predictLbl:SetTextColor(isBarVisible and 0.92 or 0.55, isBarVisible and 0.90 or 0.44, isBarVisible and 0.87 or 0.30, 1)

    predictBtn:SetScript("OnClick", function()
        self:TogglePredictBar()
        -- Refresh sidebar to update button state
        if TA.UI and TA.UI.activeTab == "rotation" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end)
    y = y - 26
    table.insert(self.frames, predictBtn)

    parent:SetHeight(math.abs(y) + 10)
end

-- ── Spell row renderer ────────────────────────────────────────────────
-- Returns the pixel height consumed (caller advances y by this amount).
function Rotation:RenderSpellRow(parent, y, w, padL, entry, isCD, isNext)
    local h = isCD and 36 or 46

    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(w, h)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
    row:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    if isNext then
        -- "Press Next" highlight: bright green glow border
        row:SetBackdropColor(0.04, 0.12, 0.02, 0.98)
        row:SetBackdropBorderColor(0.20, 0.92, 0.40, 0.95)
    elseif entry.isMajorCd then
        row:SetBackdropColor(0.12, 0.06, 0.00, 0.95)
        row:SetBackdropBorderColor(1.00, 0.55, 0.00, 0.65)
    elseif isCD then
        row:SetBackdropColor(0.08, 0.04, 0.00, 0.95)
        row:SetBackdropBorderColor(0.70, 0.50, 0.08, 0.50)
    else
        row:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
        row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.40)
    end
    table.insert(self.frames, row)

    -- Left badge: priority number or CD tag
    local badgeW = 26
    local badgeLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badgeLbl:SetFont(STANDARD_TEXT_FONT, entry.priority and 13 or 8, "OUTLINE")
    badgeLbl:SetText(entry.priority and tostring(entry.priority) or (entry.isMajorCd and "MJCD" or "CD"))
    badgeLbl:SetTextColor(1, entry.priority and 0.82 or 0.55, 0, 1)
    badgeLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
    badgeLbl:SetWidth(badgeW)
    badgeLbl:SetJustifyH("CENTER")

    -- Spell icon
    local iconSize = h - 10
    local iconLeft = badgeW + 10
    if entry.spellID then
        local tex = U.GetSpellTexture(entry.spellID)
        local ico = row:CreateTexture(nil, "ARTWORK")
        ico:SetSize(iconSize, iconSize)
        ico:SetPoint("LEFT", row, "LEFT", iconLeft, 0)
        ico:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    local textLeft = iconLeft + iconSize + 6

    -- Spell name
    local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLbl:SetFont(STANDARD_TEXT_FONT, isCD and 10 or 11, "OUTLINE")
    nameLbl:SetText(entry.name or "Unknown")
    nameLbl:SetTextColor(isCD and 0.90 or 1, isCD and 0.72 or 0.82, isCD and 0.42 or 0, 1)
    nameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", textLeft, -5)
    nameLbl:SetWidth(w - textLeft - 8)
    nameLbl:SetJustifyH("LEFT")

    -- Why explanation (bottom of row)
    if entry.why then
        local whyLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        whyLbl:SetFont(STANDARD_TEXT_FONT, 9)
        whyLbl:SetText(entry.why)
        whyLbl:SetTextColor(0.52, 0.48, 0.34, 1)
        whyLbl:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", textLeft, 5)
        whyLbl:SetWidth(w - textLeft - 8)
        whyLbl:SetJustifyH("LEFT")
        whyLbl:SetWordWrap(false)
    end

    -- "Press Next" indicator on right side
    if isNext then
        local nextLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nextLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        nextLbl:SetText("|cFF4AFF7ANEXT ►|r")
        nextLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    end

    return h + 4
end

-- ── Content renderer ──────────────────────────────────────────────────
function Rotation:RenderContent(content, rotData, specID, level)
    local y    = -10
    local padL = 14
    local w    = content:GetWidth() - 28

    local function AddDivider(label)
        if label then
            local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            f:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            f:SetText(label)
            f:SetTextColor(0.62, 0.59, 0.55, 1)
            f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            y = y - 14
            table.insert(self.frames, f)
        end
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  y)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
        line:SetColorTexture(0.30, 0.30, 0.35, 0.35)
        y = y - 8
        table.insert(self.frames, line)
    end

    -- Guard: empty data
    if not rotData or not rotData.priorities then
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        f:SetText("No rotation data for this spec. See Icy Veins or Method for current guidance.")
        f:SetTextColor(0.55, 0.50, 0.36, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        f:SetWidth(w)
        f:SetWordWrap(true)
        table.insert(self.frames, f)
        content:SetHeight(120)
        return
    end

    -- Overview tip
    if rotData.tip and rotData.tip ~= "" then
        AddDivider("OVERVIEW")
        local tipF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tipF:SetFont(STANDARD_TEXT_FONT, 10)
        tipF:SetText(rotData.tip)
        tipF:SetTextColor(0.72, 0.68, 0.52, 1)
        tipF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        tipF:SetWidth(w)
        tipF:SetJustifyH("LEFT")
        tipF:SetWordWrap(true)
        y = y - tipF:GetStringHeight() - 12
        table.insert(self.frames, tipF)
    end

    -- Split priorities into normal vs cooldown vs defensive sections
    local normal, cds, defensives = {}, {}, {}
    for _, entry in ipairs(rotData.priorities) do
        if entry.isCd or entry.isMajorCd or not entry.priority then
            -- Sub-categorize: defensives vs offensive cooldowns
            local isDefensive = false
            if entry.tags then
                for _, tag in ipairs(entry.tags) do
                    if tag == "defensive" or tag == "utility" then
                        isDefensive = true; break
                    end
                end
            end
            if isDefensive then
                table.insert(defensives, entry)
            else
                table.insert(cds, entry)
            end
        else
            table.insert(normal, entry)
        end
    end

    if #normal > 0 then
        AddDivider("PRIORITY LIST  (1 = cast first)")

        -- Query CombatState for the "press next" ability highlight
        local CS = TA:GetModule("CombatState")
        local nextIdx, nextEntry = nil, nil
        if CS and CS.GetNextAbility and CS.state.inCombat then
            nextIdx, nextEntry = CS:GetNextAbility(normal, level)
        end

        for idx, entry in ipairs(normal) do
            local isNext = (nextEntry and entry.spellID == nextEntry.spellID)
            y = y - self:RenderSpellRow(content, y, w, padL, entry, false, isNext)
        end
        y = y - 6
    end

    -- ── Cooldowns accordion ───────────────────────────────────────────
    local M = TA.Modern
    if #cds > 0 then
        if M and M.CreateCollapsibleSection then
            local cdSection = M:CreateCollapsibleSection(content, {
                title = "Cooldowns (" .. #cds .. ")",
                width = w,
                startOpen = true,
                contentHeight = (#cds * 40) + 8,
            })
            cdSection.frame:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            table.insert(self.frames, cdSection.frame)

            local cdY = -4
            for _, entry in ipairs(cds) do
                local h = self:RenderSpellRow(cdSection.content, cdY, w - 4, 2, entry, true)
                cdY = cdY - h
            end
            cdSection:SetContentHeight(math.abs(cdY) + 4)
            y = y - (cdSection.frame:GetHeight() + 8)
        else
            -- Fallback without Modern layer
            AddDivider("COOLDOWNS")
            for _, entry in ipairs(cds) do
                y = y - self:RenderSpellRow(content, y, w, padL, entry, true)
            end
            y = y - 6
        end
    end

    -- ── Utility / Defensives accordion ────────────────────────────────
    if #defensives > 0 then
        if M and M.CreateCollapsibleSection then
            local defSection = M:CreateCollapsibleSection(content, {
                title = "Utility / Defensives (" .. #defensives .. ")",
                width = w,
                startOpen = false,   -- collapsed by default to save space
                contentHeight = (#defensives * 40) + 8,
            })
            defSection.frame:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            table.insert(self.frames, defSection.frame)

            local defY = -4
            for _, entry in ipairs(defensives) do
                local h = self:RenderSpellRow(defSection.content, defY, w - 4, 2, entry, true)
                defY = defY - h
            end
            defSection:SetContentHeight(math.abs(defY) + 4)
            y = y - (defSection.frame:GetHeight() + 8)
        else
            AddDivider("UTILITY / DEFENSIVES")
            for _, entry in ipairs(defensives) do
                y = y - self:RenderSpellRow(content, y, w, padL, entry, true)
            end
            y = y - 6
        end
    end

    if #rotData.priorities == 0 then
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        f:SetText("Rotation priorities for this spec are being filled in.")
        f:SetTextColor(0.55, 0.50, 0.36, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        f:SetWidth(w)
        table.insert(self.frames, f)
        y = y - 20
    end

    -- ── Simulated Lookahead (Next 3) ──────────────────────────────────
    -- Rendered below the priority list — shows which 3 abilities would be
    -- pressed next based on current combat state evaluation.
    if rotData and rotData.priorities and #rotData.priorities > 0 then
        y = y - 8
        y = self:RenderPredictionInline(content, y, w, padL, rotData, level)
    end

    content:SetHeight(math.abs(y) + 20)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ── "Next 3" Prediction Bar ─────────────────────────────────────────────────
-- A horizontal bar showing the predicted next 3 abilities based on current
-- CombatState (resources, cooldowns, buffs). Renders both inline in the tab
-- and as a standalone floating bar during combat.
-- ══════════════════════════════════════════════════════════════════════════════

local PREDICTION_COUNT  = 3
local ICON_SIZE         = 40
local ICON_GAP          = 6
local PREDICT_UPDATE_HZ = 0.15  -- refresh rate for prediction bar (slightly slower than CombatState)

-- ── Role-aware view labels ─────────────────────────────────────────────────────
-- Returns context-appropriate names for the 3 prediction bar views based on
-- the player's current spec role: DPS gets Solo/AoE/ST, Healers get DPS/Heal/AoE Heal,
-- Tanks get DPS/Tank/AoE Tank.

function Rotation:GetViewLabels()
    local SW = TA.Data.StatWeights
    local specID = self.currentSpecID or U.GetPlayerSpec()
    local data = specID and SW and SW[specID]
    local role = data and data.role or "DAMAGER"

    if role == "HEALER" then
        return {
            solo = "DPS",
            aoe  = "Heal (M+)",
            st   = "Heal (Raid)",
        }
    elseif role == "TANK" then
        return {
            solo = "DPS",
            aoe  = "Tank (M+)",
            st   = "Tank (Boss)",
        }
    else
        return {
            solo = "Solo",
            aoe  = "AoE (M+)",
            st   = "ST (Raid)",
        }
    end
end

-- ── Floating Prediction Bar (combat overlay) ──────────────────────────────────

Rotation.predictBar = nil
Rotation.predictIcons = {}
Rotation._predictThrottle = 0

function Rotation:InitPredictBar()
    if self.predictBar then return end

    local bar = CreateFrame("Button", "TARotationPredictBar", UIParent, "BackdropTemplate")
    local totalW = (ICON_SIZE * PREDICTION_COUNT) + (ICON_GAP * (PREDICTION_COUNT - 1)) + 16
    bar:SetSize(totalW, ICON_SIZE + 16)
    bar:SetFrameStrata("HIGH")
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180)
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if TA.charDB then
            TA.charDB.predictBar = TA.charDB.predictBar or {}
            TA.charDB.predictBar.x = f:GetLeft()
            TA.charDB.predictBar.y = f:GetTop()
        end
    end)

    bar:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.02, 0.02, 0.02, 0.85)
    bar:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.70)

    -- Scroll-wheel resize (0.5x – 2.5x)
    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", function(f, delta)
        local s = math.max(0.5, math.min(f:GetScale() + delta * 0.1, 2.5))
        f:SetScale(s)
        if TA.charDB then
            TA.charDB.predictBar = TA.charDB.predictBar or {}
            TA.charDB.predictBar.scale = s
        end
    end)

    -- Right-click context: cycle view + lock toggle
    bar:EnableMouse(true)
    bar:RegisterForClicks("RightButtonUp")
    bar:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            -- Cycle view: solo → aoe → st → solo
            if self.currentView == "solo" then
                self.currentView = "aoe"
            elseif self.currentView == "aoe" then
                self.currentView = "st"
            else
                self.currentView = "solo"
            end
            local labels = self:GetViewLabels()
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Rotation]|r View: " .. (labels[self.currentView] or self.currentView))
            self:UpdatePrediction()
        end
    end)

    bar:SetScript("OnEnter", function(f)
        GameTooltip:SetOwner(f, "ANCHOR_TOP")
        GameTooltip:SetText("Next 3 Abilities", 1, 0.82, 0)
        local labels = self:GetViewLabels()
        GameTooltip:AddLine("View: " .. (labels[self.currentView] or self.currentView), 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 1, 1)
        local hint = labels.solo .. " / " .. labels.aoe .. " / " .. labels.st
        GameTooltip:AddLine("Right-click: Cycle (" .. hint .. ")", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Scroll: Resize", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Restore saved scale
    local savedBar = TA.charDB and TA.charDB.predictBar
    if savedBar and savedBar.scale then bar:SetScale(savedBar.scale) end

    -- Header label
    local header = bar:CreateFontString(nil, "OVERLAY")
    header:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    header:SetText("|cFF8B7040NEXT|r")
    header:SetPoint("TOPLEFT", bar, "TOPLEFT", 4, -2)

    -- Create icon frames
    local icons = {}
    for i = 1, PREDICTION_COUNT do
        local frame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        frame:SetSize(ICON_SIZE, ICON_SIZE)
        frame:SetPoint("LEFT", bar, "LEFT", 8 + (i - 1) * (ICON_SIZE + ICON_GAP), -2)
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetSize(ICON_SIZE - 4, ICON_SIZE - 4)
        tex:SetPoint("CENTER")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        frame.icon = tex

        local numLabel = frame:CreateFontString(nil, "OVERLAY")
        numLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        numLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        numLabel:SetTextColor(1, 0.82, 0, 0.9)
        numLabel:SetText(tostring(i))
        frame.numLabel = numLabel

        local nameLabel = frame:CreateFontString(nil, "OVERLAY")
        nameLabel:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        nameLabel:SetPoint("TOP", frame, "BOTTOM", 0, -1)
        nameLabel:SetWidth(ICON_SIZE + 10)
        nameLabel:SetJustifyH("CENTER")
        nameLabel:SetWordWrap(false)
        frame.nameLabel = nameLabel

        icons[i] = frame
    end
    self.predictIcons = icons

    -- OnUpdate ticker for live prediction refresh
    bar:SetScript("OnUpdate", function(_, elapsed)
        self._predictThrottle = self._predictThrottle + elapsed
        if self._predictThrottle < PREDICT_UPDATE_HZ then return end
        self._predictThrottle = 0
        self:UpdatePrediction()
    end)

    -- Restore position
    local saved = TA.charDB and TA.charDB.predictBar
    if saved and saved.x and saved.y then
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    end

    bar:Hide()  -- starts hidden; shown during combat
    self.predictBar = bar
end

function Rotation:UpdatePrediction()
    local CS = TA:GetModule("CombatState")
    if not CS then return end

    -- Auto-show the bar when entering combat (if user has it enabled)
    local inCombat = CS.state and CS.state.inCombat
    if inCombat and not self._wasInCombat then
        local saved = TA.charDB and TA.charDB.predictBar
        if saved and saved.visible and self.predictBar and not self.predictBar:IsVisible() then
            self.predictBar:Show()
        end
    end
    self._wasInCombat = inCombat or false

    local specID    = self.currentSpecID or U.GetPlayerSpec()
    local level     = self.currentLevel  or U.GetPlayerLevel()
    local priorities = self:GetPredictionPriorities(specID, self.currentView)

    if not priorities then
        -- Hide all icons
        for i = 1, PREDICTION_COUNT do
            self.predictIcons[i]:Hide()
        end
        return
    end

    local next3 = CS:GetNextN(priorities, level, PREDICTION_COUNT)

    for i = 1, PREDICTION_COUNT do
        local iconFrame = self.predictIcons[i]
        local prediction = next3[i]

        if prediction then
            local entry = prediction.entry
            local tex = entry.spellID and U.GetSpellTexture(entry.spellID)
            iconFrame.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconFrame.nameLabel:SetText(entry.name or "")

            -- Color: first = bright green, second = gold, third = dimmer gold
            if i == 1 then
                iconFrame:SetBackdropColor(0.04, 0.12, 0.02, 0.98)
                iconFrame:SetBackdropBorderColor(0.20, 0.92, 0.40, 0.95)
                iconFrame.nameLabel:SetTextColor(0.20, 0.92, 0.40)
            elseif i == 2 then
                iconFrame:SetBackdropColor(0.06, 0.04, 0.00, 0.98)
                iconFrame:SetBackdropBorderColor(1.00, 0.82, 0.00, 0.80)
                iconFrame.nameLabel:SetTextColor(1.00, 0.82, 0.00)
            else
                iconFrame:SetBackdropColor(0.04, 0.03, 0.00, 0.98)
                iconFrame:SetBackdropBorderColor(0.70, 0.55, 0.10, 0.60)
                iconFrame.nameLabel:SetTextColor(0.70, 0.55, 0.10)
            end

            iconFrame:Show()
        else
            iconFrame:Hide()
        end
    end
end

function Rotation:ShowPredictBar()
    if not self.predictBar then self:InitPredictBar() end
    self.predictBar:Show()
    self:UpdatePrediction()
end

function Rotation:HidePredictBar()
    if self.predictBar then self.predictBar:Hide() end
end

function Rotation:TogglePredictBar()
    if not self.predictBar then self:InitPredictBar() end
    if self.predictBar:IsVisible() then
        self:HidePredictBar()
        if TA.charDB then TA.charDB.predictBar = TA.charDB.predictBar or {}; TA.charDB.predictBar.visible = false end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Rotation]|r Prediction bar hidden.")
    else
        self:ShowPredictBar()
        if TA.charDB then TA.charDB.predictBar = TA.charDB.predictBar or {}; TA.charDB.predictBar.visible = true end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Rotation]|r Prediction bar shown.")
    end
end

-- ── Inline "Next 3" in the Rotation tab content ───────────────────────────────

function Rotation:RenderPredictionInline(content, y, w, padL, rotData, level)
    local CS = TA:GetModule("CombatState")
    if not CS then return y end

    -- Same chain-vs-priorities fallback as the floating bar.
    local priorities = rotData and rotData.priorities
    if not priorities then
        priorities = self:GetPredictionPriorities(
            self.currentSpecID or U.GetPlayerSpec(), self.currentView)
    end
    if not priorities then return y end

    local next3 = CS:GetNextN(priorities, level, PREDICTION_COUNT)
    if #next3 == 0 then return y end

    -- Section header
    local headerLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    headerLbl:SetText("SIMULATED LOOKAHEAD")
    headerLbl:SetTextColor(0.62, 0.59, 0.55, 1)
    headerLbl:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, headerLbl)
    y = y - 14

    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL,  y)
    line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    line:SetColorTexture(0.30, 0.30, 0.35, 0.35)
    y = y - 10
    table.insert(self.frames, line)

    -- Render 3 icon buttons in a horizontal row
    local inlineSize = 44
    local inlineGap  = 10
    local totalW2 = (inlineSize * PREDICTION_COUNT) + (inlineGap * (PREDICTION_COUNT - 1))
    local startX = padL + (w - totalW2) / 2  -- centered

    for i, prediction in ipairs(next3) do
        local entry = prediction.entry
        local frame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        frame:SetSize(inlineSize, inlineSize)
        frame:SetPoint("TOPLEFT", content, "TOPLEFT", startX + (i - 1) * (inlineSize + inlineGap), y)
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        if i == 1 then
            frame:SetBackdropColor(0.04, 0.12, 0.02, 0.98)
            frame:SetBackdropBorderColor(0.20, 0.92, 0.40, 0.95)
        elseif i == 2 then
            frame:SetBackdropColor(0.06, 0.04, 0.00, 0.98)
            frame:SetBackdropBorderColor(1.00, 0.82, 0.00, 0.80)
        else
            frame:SetBackdropColor(0.04, 0.03, 0.00, 0.98)
            frame:SetBackdropBorderColor(0.70, 0.55, 0.10, 0.60)
        end

        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetSize(inlineSize - 6, inlineSize - 6)
        tex:SetPoint("CENTER")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local texPath = entry.spellID and U.GetSpellTexture(entry.spellID)
        tex:SetTexture(texPath or "Interface\\Icons\\INV_Misc_QuestionMark")

        local numLbl = frame:CreateFontString(nil, "OVERLAY")
        numLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        numLbl:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -2)
        numLbl:SetText("|cFFFFD100" .. tostring(i) .. "|r")

        local nameLbl = frame:CreateFontString(nil, "OVERLAY")
        nameLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        nameLbl:SetPoint("TOP", frame, "BOTTOM", 0, -2)
        nameLbl:SetWidth(inlineSize + 16)
        nameLbl:SetJustifyH("CENTER")
        nameLbl:SetWordWrap(false)
        nameLbl:SetText(entry.name or "")
        if i == 1 then
            nameLbl:SetTextColor(0.20, 0.92, 0.40)
        elseif i == 2 then
            nameLbl:SetTextColor(1.00, 0.82, 0.00)
        else
            nameLbl:SetTextColor(0.70, 0.55, 0.10)
        end

        table.insert(self.frames, frame)
        table.insert(self.frames, nameLbl)
    end

    y = y - inlineSize - 20  -- space for icons + name labels

    return y
end

-- ── Extended event handling for prediction bar visibility ──────────────────────

-- The prediction bar's OnUpdate already refreshes at 0.15s.
-- We hook into it to auto-show/hide the bar based on combat state.
-- PLAYER_REGEN events are not on TA.eventFrame, so we check state directly.
Rotation._wasInCombat = false

-- ── Slash commands ────────────────────────────────────────────────────────────

Rotation.SlashCommands = {
    rotation = function(self) TA:OpenTab("rotation") end,
    predict  = function(self) self:TogglePredictBar() end,
}
