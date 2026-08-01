-- CharacterAdvisor/Modules/Talents.lua
-- Polymorphic talent advice tracker with safe editbox font parameters & group rule filters

local CA = CharacterAdvisor
local U  = CA.Utils
local T  = CA.Data.Talents

local Talents = {}
CA:RegisterModule("Talents", Talents)

Talents.frames = {}
Talents.sideFrames = {}
Talents.selectedSpecID = nil
Talents.viewBuildType = nil -- Safe tracking state: nil defaults to group match criteria

function Talents:OnEvent(event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
        if CA.UI and CA.UI.activeTab == "talents" then
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end
    end
end

-- Systematic helper function to determine group type state mode matching Rotation tab parameters
local function GetSystematicGroupMode()
    if IsInRaid() then return "raid" end
    if IsInGroup() then return "mplus" end
    return "solo"
end

function Talents:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    local activeSpecID, specName, specIcon = U.GetPlayerSpec()
    if not activeSpecID then return end

    if not self.selectedSpecID then
        self.selectedSpecID = activeSpecID
    end

    local currentGroupMode = GetSystematicGroupMode()
    if not self.viewBuildType then
        self.viewBuildType = currentGroupMode
    end

    local padL, y = 10, -10
    local w = content:GetWidth() - 20

    -- ── 1. SIDEBAR NAVIGATION ────────────────────────────────────────────
    self:RenderSidebar(sidebar, activeSpecID)

    -- ── 2. MAIN TALENTS WINDOW DISPLAY PANEL ─────────────────────────────
    local function AddLabel(text, size, r, g, b)
        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 11, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        f:SetWidth(w)
        f:SetJustifyH("LEFT")
        f:SetWordWrap(true)
        y = y - f:GetStringHeight() - 4
        table.insert(self.frames, f)
        return f
    end

    -- Title Section Header Node
    local modeLabel = "Solo / Leveling"
    if self.viewBuildType == "mplus" then modeLabel = "Mythic+ AoE"
    elseif self.viewBuildType == "raid" then modeLabel = "Raid Single Target" end

    AddLabel("CURRENT TALENT CONFIGURATION ADVISOR — VIEWING: " .. modeLabel:upper(), 12, 1, 0.82, 0)
    y = y - 6

    -- Pull simulation profile entries from DB data definitions
    local dbSpecData = T:GetBySpecID(self.selectedSpecID)
    if not dbSpecData then
        AddLabel("No customized community build suggestions loaded for this specialization.", 11, 0.5, 0.5, 0.5)
        return
    end

    -- Match targeted layout sub-tier string config entries
    local targetedBuild = dbSpecData.builds[self.viewBuildType] or dbSpecData.builds["solo"]
    
    -- Current Loadout Box Node
    local stringCard = CreateFrame("Frame", nil, content, "BackdropTemplate")
    stringCard:SetSize(w, 40)
    stringCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    stringCard:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    stringCard:SetBackdropColor(0.04, 0.04, 0.04, 1)
    stringCard:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
    table.insert(self.frames, stringCard)

    local currentString = "Loading layout string parameters..."
    if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        local cfgID = C_ClassTalents.GetActiveConfigID()
        if cfgID then
            currentString = C_ClassTalents.GetExportString(cfgID) or "No Active String found"
        end
    end

    local strTxt = stringCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    strTxt:SetFont(STANDARD_TEXT_FONT, 9)
    strTxt:SetText(U.Truncate(currentString, 90))
    strTxt:SetTextColor(0.7, 0.7, 0.7, 1)
    strTxt:SetPoint("LEFT", stringCard, "LEFT", 10, 0)
    y = y - 46

    -- Overview Strategy Summary Box
    AddLabel("|cFFFFD100Strategy Note:|r " .. (targetedBuild.desc or "Standard performance layout profile configuration."), 10, 0.78, 0.73, 0.48)
    y = y - 6

    -- Main Build Target Interactive Focus Frame
    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetSize(w, 80)
    card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    card:SetBackdropColor(0.05, 0.04, 0.02, 1)
    card:SetBackdropBorderColor(1, 0.82, 0, 0.4)
    table.insert(self.frames, card)

    local cTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cTitle:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    cTitle:SetText("Recommended Loadout String Target:")
    cTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)

    local cStr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cStr:SetFont(STANDARD_TEXT_FONT, 9)
    cStr:SetText(U.Truncate(targetedBuild.string, 80))
    cStr:SetTextColor(0.29, 1.00, 0.48, 1)
    cStr:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -24)

    -- Safe Copy Action Button (Resolves Line 406 Error Parameter Exception)
    local cpBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
    cpBtn:SetSize(140, 24)
    cpBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 8)
    cpBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    cpBtn:SetBackdropColor(0.1, 0.08, 0, 1)
    cpBtn:SetBackdropBorderColor(1, 0.82, 0, 0.5)

    local cpLbl = cpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cpLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    cpLbl:SetText("Copy Import String")
    cpLbl:SetAllPoints(cpBtn)

    cpBtn:SetScript("OnClick", function()
        self:OpenSafeCopyFrame(content, targetedBuild.name, targetedBuild.string)
    end)

    y = y - 90

    -- ── 3. LIST ALL RECOMMENDED MATRIX ROWS ──────────────────────────────
    AddLabel("ALL RECOMMENDED BUILDS FOR THIS SPECIALIZATION", 10, 0.55, 0.40, 0.08)
    y = y - 4

    local rowMapping = {
        { key = "mplus", name = "Mythic+: M+ Pack Leader" },
        { key = "raid",  name = "Raid: Raid Pack Leader" },
        { key = "solo",  name = "Solo/Leveling: Open World Solo" },
    }

    for _, rowDef in ipairs(rowMapping) do
        local isCurrentView = (self.viewBuildType == rowDef.key)
        local buildInfo = dbSpecData.builds[rowDef.key]

        if buildInfo then
            local rowBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
            rowBtn:SetSize(w, 36)
            rowBtn:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            rowBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})

            if isCurrentView then
                rowBtn:SetBackdropColor(0.10, 0.08, 0.00, 1)
                rowBtn:SetBackdropBorderColor(1, 0.82, 0, 0.7)
            else
                rowBtn:SetBackdropColor(0.05, 0.05, 0.05, 1)
                rowBtn:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.2)
            end
            table.insert(self.frames, rowBtn)

            local rLbl = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            rLbl:SetText(rowDef.name .. (isCurrentView and "  |cFF4AFF7A[active view]|r" or ""))
            rLbl:SetTextColor(isCurrentView and 1 or 0.78, isCurrentView and 0.82 or 0.73, isCurrentView and 0 or 0.48, 1)
            rLbl:SetPoint("LEFT", rowBtn, "LEFT", 10, 8)

            local rStrText = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rStrText:SetFont(STANDARD_TEXT_FONT, 8)
            rStrText:SetText(U.Truncate(buildInfo.string, 95))
            rStrText:SetTextColor(0.5, 0.5, 0.5, 1)
            rStrText:SetPoint("LEFT", rowBtn, "LEFT", 10, -8)

            -- Structural Click Action: Mutates View Type on Selection
            rowBtn:SetScript("OnClick", function()
                self.viewBuildType = rowDef.key
                self:Render(content, sidebar)
            end)

            y = y - 42
        end
    end

    content:SetHeight(math.abs(y) + 20)
end

function Talents:RenderSidebar(parent, activeSpecID)
    local y = -8
    local w = parent:GetWidth() - 12

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    title:SetText("SELECT SPEC VIEW")
    title:SetTextColor(0.55, 0.40, 0.08, 1)
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    table.insert(self.sideFrames, title)

    -- Dynamic Class Spec Index Scraper System Integration
    local numSpecs = GetNumSpecializations() or 3
    for i = 1, numSpecs do
        local id, name, _, icon = GetSpecializationInfo(i)
        if id then
            local isSelected = (id == self.selectedSpecID)
            local isCurrentSpec = (id == activeSpecID)

            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(w, 36)
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
            ico:SetSize(20, 20)
            ico:SetPoint("LEFT", btn, "LEFT", 6, 0)
            ico:SetTexture(icon)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            lbl:SetText(name .. (isCurrentSpec and " |cFF4AFF7A*|r" or ""))
            lbl:SetTextColor(isSelected and 1 or 0.78, isSelected and 0.82 or 0.73, isSelected and 0 or 0.48, 1)
            lbl:SetPoint("LEFT", btn, "LEFT", 32, 0)

            -- Functional Sidebar Hook Integration
            btn:SetScript("OnClick", function()
                self.selectedSpecID = id
                -- Reset build selection filtering criteria back to native zone status rules
                self.viewBuildType = GetSystematicGroupMode()
                self:Render(CA.UI.contentChild, CA.UI.sideChild)
            end)

            y = y - 40
            table.insert(self.sideFrames, btn)
        end
    end

    -- Explicit Lower Context Indicator
    y = y - 10
    local footerText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    footerText:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    footerText:SetText("Showing advice for:\n|cFFFFD100" .. GetSystematicGroupMode():upper() .. "|r configurations\n(Changes automatically)")
    footerText:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    footerText:SetWidth(w)
    footerText:SetJustifyH("LEFT")
    table.insert(self.sideFrames, footerText)
end

-- ── 4. SAFE EDITBOX FRAME PIPELINE (Fixes Line 406 Flags Taint Crash) ──
function Talents:OpenSafeCopyFrame(parent, title, importString)
    -- Reuse existing frame — only create once to avoid widget accumulation
    if self.copyFrame then
        self.copyFrame.label:SetText("Press CTRL+C to Copy " .. title .. " Import String:")
        self.copyFrame.editbox:SetText(importString)
        self.copyFrame.editbox:HighlightText()
        self.copyFrame.editbox:SetFocus()
        self.copyFrame:Show()
        return
    end

    local cf = CreateFrame("Frame", "CharacterAdvisorCopyFrame", UIParent, "BackdropTemplate")
    cf:SetSize(420, 110)
    cf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    cf:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    cf:SetBackdropColor(0.02, 0.02, 0.02, 0.98)
    cf:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    cf:SetFrameStrata("DIALOG")

    local lbl = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    lbl:SetText("Press CTRL+C to Copy " .. title .. " Import String:")
    lbl:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -12)
    cf.label = lbl

    local eb = CreateFrame("EditBox", nil, cf, "BackdropTemplate")
    eb:SetSize(396, 24)
    eb:SetPoint("TOPLEFT", cf, "TOPLEFT", 12, -32)
    eb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    eb:SetBackdropColor(0.08, 0.08, 0.08, 1)
    eb:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    eb:SetMultiLine(false)
    eb:SetAutoFocus(true)
    eb:SetFont(STANDARD_TEXT_FONT, 9)
    eb:SetText(importString)
    eb:HighlightText()
    eb:SetScript("OnEscapePressed", function() cf:Hide() end)
    cf.editbox = eb

    local close = CreateFrame("Button", nil, cf, "BackdropTemplate")
    close:SetSize(80, 20)
    close:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -12, 10)
    close:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    close:SetBackdropColor(0.15, 0.03, 0.03, 1)
    close:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)

    local cLbl = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    cLbl:SetText("Close Window")
    cLbl:SetAllPoints(close)
    close:SetScript("OnClick", function() cf:Hide() end)

    self.copyFrame = cf
    cf:Show()
end