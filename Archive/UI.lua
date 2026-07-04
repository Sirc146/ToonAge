-- CharacterAdvisor/UI.lua
-- Core User Interface Frame Window Manager with Protected View Interceptions

local CA = CharacterAdvisor
local U  = CA.Utils

CA.UI = CA.UI or {}
local UI = CA.UI

UI.activeTab = "character"
UI.frame = nil

local TABS = {
    { id = "character",   label = "Character" },
    { id = "gear",        label = "Gear" },
    { id = "talents",     label = "Talents" },
    { id = "rotation",    label = "Rotation" },
    { id = "pets",        label = "Pets" },
    { id = "weekly",      label = "Weekly" },
    { id = "delves",      label = "Delves" },
    { id = "professions", label = "Professions" },
}

function UI:Init()
    if self.frame then return end

    local f = CreateFrame("Frame", "CharacterAdvisorFrame", UIParent, "BackdropTemplate")
    f:SetSize(820, 500)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    f:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
    f:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.8)
    self.frame = f

    -- Top Tab Sheet Navigation Row Bar
    self.tabButtons = {}
    local tabX = 12
    for _, tInfo in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f, "BackdropTemplate")
        b:SetSize(85, 24)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", tabX, -10)
        b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        
        local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        lbl:SetText(tInfo.label)
        lbl:SetAllPoints(b)
        b.lbl = lbl

        b:SetScript("OnClick", function()
            self.activeTab = tInfo.id
            self:SelectTab(tInfo.id)
        end)
        
        self.tabButtons[tInfo.id] = b
        tabX = tabX + 88
    end

    -- Split View Container Allocation
    local side = CreateFrame("ScrollFrame", nil, f, "BackdropTemplate")
    side:SetSize(180, 440)
    side:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -45)
    side:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    side:SetBackdropColor(0.01, 0.01, 0.01, 1)
    side:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.2)
    
    local sideChild = CreateFrame("Frame", nil, side)
    sideChild:SetSize(180, 1)
    side:SetScrollChild(sideChild)
    self.sideChild = sideChild

    local main = CreateFrame("ScrollFrame", nil, f, "BackdropTemplate")
    main:SetSize(600, 440)
    main:SetPoint("TOPLEFT", f, "TOPLEFT", 204, -45)
    main:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    main:SetBackdropColor(0.01, 0.01, 0.01, 1)
    main:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.2)
    
    local contentChild = CreateFrame("Frame", nil, main)
    contentChild:SetSize(600, 1)
    main:SetScrollChild(contentChild)
    self.contentChild = contentChild

    f:Hide()
    self:SelectTab(self.activeTab)
end

function UI:Toggle()
    if not self.frame then self:Init() end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:SelectTab(self.activeTab) end
end

-- Protected Tab Switching Architecture (Shields lines 38 & 215 from crashes)
function UI:SelectTab(tabID)
    if not self.frame then return end
    
    for id, btn in pairs(self.tabButtons) do
        if id == tabID then
            btn:SetBackdropColor(0.12, 0.10, 0.02, 1)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.9)
            btn.lbl:SetTextColor(1, 0.82, 0, 1)
        else
            btn:SetBackdropColor(0.04, 0.04, 0.04, 1)
            btn:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.3)
            btn.lbl:SetTextColor(0.6, 0.53, 0.35, 1)
        end
    end

    local mod = CA:GetModule(tabID:gsub("^%l", string.upper))
    if mod and mod.Render then
        -- Intercept and safely isolate execution faults if module data contains errors
        local success, err = pcall(function()
            mod:Render(self.contentChild, self.sideChild)
        end)
        
        if not success then
            -- Error block containment fallback: Draw error message without crashing the parent window
            self.contentChild:SetHeight(80)
            local errText = self.contentChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
            errText:SetText("|cFFFF4444Error rendering sub-tab parameters:|r\n" .. tostring(err))
            errText:SetPoint("TOPLEFT", self.contentChild, "TOPLEFT", 10, -10)
            errText:SetWidth(580)
            errText:SetJustifyH("LEFT")
        end
    end
end