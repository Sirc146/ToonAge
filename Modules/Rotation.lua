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

    local views = {
        { id="solo", label="Solo / Leveling", dot={0.33, 0.60, 1.00} },
        { id="aoe",  label="Group AoE (M+)",  dot={1.00, 0.60, 0.10} },
        { id="st",   label="Group ST (Raid)", dot={0.29, 1.00, 0.48} },
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

    content:SetHeight(math.abs(y) + 20)
end
