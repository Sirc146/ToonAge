-- ToonAge/Modules/Professions.lua
-- Dynamic UI Renderer pulling from Data/Professions_Data.lua

local TA = ToonAge
local U  = TA.Utils
local P  = TA.Data.Professions

local Professions = {}
TA:RegisterModule("Professions", Professions)

Professions.frames = {}
Professions.sideFrames = {}
Professions.selectedSkillLine = nil

function Professions:OnEvent(event, ...)
    -- PLAYER_ENTERING_WORLD is intentionally NOT handled here.
    -- At that point TA:InitUI() has not yet been called, so TA.UI is nil and
    -- the render attempt would be a silent no-op (or worse, an error).
    -- Initial profession data is captured via OnLogin's charDB snapshot instead.
    if event == "SKILL_LINES_CHANGED" then
        if TA.UI and TA.UI.activeTab == "professions" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end
end

function Professions:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}
    
    local playerProfs = U.GetProfessions()
    
    -- Default selection to the first available profession if none selected
    if #playerProfs > 0 and not self.selectedSkillLine then
        self.selectedSkillLine = playerProfs[1].skillLine
    elseif #playerProfs == 0 then
        self.selectedSkillLine = nil
    end

    self:RenderSidebar(sidebar, playerProfs)
    self:RenderContent(content)
end

function Professions:RenderSidebar(parent, playerProfs)
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    local y = -8
    local w = parent:GetWidth() - 12

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    title:SetText("YOUR PROFESSIONS")
    title:SetTextColor(0.55, 0.40, 0.08, 1)
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    table.insert(self.sideFrames, title)

    if #playerProfs == 0 then
        local noProf = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noProf:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        noProf:SetText("No professions learned.")
        noProf:SetTextColor(0.5, 0.5, 0.5, 1)
        noProf:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        table.insert(self.sideFrames, noProf)
        return
    end

    for _, prof in ipairs(playerProfs) do
        local isSelected = (prof.skillLine == self.selectedSkillLine)
        
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(w, 42)
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
        ico:SetSize(24, 24)
        ico:SetPoint("LEFT", btn, "LEFT", 8, 0)
        ico:SetTexture(prof.icon)
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        lbl:SetText(prof.name)
        lbl:SetTextColor(isSelected and 1 or 0.78, isSelected and 0.82 or 0.73, isSelected and 0 or 0.48, 1)
        lbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 40, -8)

        local rankLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rankLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        rankLbl:SetText("Skill: " .. prof.rank .. " / " .. prof.maxRank)
        rankLbl:SetTextColor(0.55, 0.44, 0.25, 1)
        rankLbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 40, -22)

        btn:SetScript("OnClick", function()
            self.selectedSkillLine = prof.skillLine
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end)

        y = y - 46
        table.insert(self.sideFrames, btn)
    end
end

function Professions:RenderContent(parent)
    if not self.selectedSkillLine then return end

    local y = -10
    local padL = 10
    local w = parent:GetWidth() - 20
    
    local profData = P:GetBySkillLine(self.selectedSkillLine) or P:GetSecondaryBySkillLine(self.selectedSkillLine)
    
    local function AddLabel(text, size, r, g, b, indent, wrapWidth)
        local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 11, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", padL + (indent or 0), y)
        f:SetWidth(wrapWidth or w - (indent or 0))
        f:SetJustifyH("LEFT")
        f:SetWordWrap(true)
        y = y - f:GetStringHeight() - 4
        table.insert(self.frames, f)
        return f
    end

    if not profData then
        AddLabel("Database metrics for this profession are currently unsupported or pending update.", 12, 1, 0.27, 0.27)
        return
    end

    -- Title & Benefit
    AddLabel(string.upper(profData.name) .. " ADVISOR", 13, 1, 0.82, 0)
    y = y - 4
    AddLabel("|cFFFFD100Strategic Benefit:|r " .. (profData.personalBenefit or profData.benefit or "Utility profession."), 10, 0.78, 0.73, 0.48)
    y = y - 10

    -- Standard vs Secondary Profession Fork
    if profData.type == "secondary" then
        AddLabel("Secondary Profession Logic", 11, 0.55, 0.40, 0.08)
        AddLabel(profData.firstPath, 10, 0.29, 1.00, 0.48)
        return
    end

    -- Gear Slots Array Mapping
    if profData.gearSlots then
        AddLabel("RECOMMENDED EQUIPMENT OPTIMIZATION", 10, 0.55, 0.40, 0.08)
        y = y - 2
        
        for slotKey, slotInfo in pairs(profData.gearSlots) do
            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetSize(w, 36)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            row:SetBackdropColor(0.04, 0.04, 0.04, 1)
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.3)
            table.insert(self.frames, row)

            local sTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sTitle:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            sTitle:SetText(slotInfo.name or slotKey:upper())
            sTitle:SetTextColor(0.55, 0.44, 0.25, 1)
            sTitle:SetPoint("LEFT", row, "LEFT", 10, 6)

            local sRec = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sRec:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            sRec:SetText(slotInfo.recommended)
            sRec:SetTextColor(1, 0.82, 0, 1)
            sRec:SetPoint("LEFT", row, "LEFT", 130, 6)

            local sStats = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sStats:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            sStats:SetText(slotInfo.bonuses .. "  |cFF888780(" .. slotInfo.source .. ")|r")
            sStats:SetPoint("LEFT", row, "LEFT", 10, -8)

            y = y - 40
        end
        y = y - 10
    end

    -- Talent Nodes Priority Tracker
    if profData.talentTree then
        AddLabel("KNOWLEDGE POINT (KP) DEPLOYMENT PATH", 10, 0.55, 0.40, 0.08)
        
        if profData.talentTree.permanenceWarning then
            AddLabel("⚠ " .. profData.talentTree.permanenceWarning, 9, 1, 0.4, 0.4)
            y = y - 6
        end

        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(w, 40)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
        card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        card:SetBackdropColor(0.04, 0.08, 0.04, 1)
        card:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.4)
        table.insert(self.frames, card)

        local pTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pTitle:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        pTitle:SetText("First Path Priority: " .. (profData.firstPath or "General Mastery"))
        pTitle:SetTextColor(0.29, 1.00, 0.48, 1)
        pTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -6)

        local pDesc = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pDesc:SetFont(STANDARD_TEXT_FONT, 9)
        pDesc:SetText(profData.firstPathReason or "Critical early expansion progression.")
        pDesc:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -20)
        pDesc:SetWidth(w - 20)
        pDesc:SetWordWrap(true)
        pDesc:SetJustifyH("LEFT")
        
        y = y - math.max(46, pDesc:GetStringHeight() + 30)
    end

    parent:SetHeight(math.abs(y) + 20)
end
