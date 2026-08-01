-- CharacterAdvisor/Modules/Pets.lua
local CA = CharacterAdvisor
local U  = CA.Utils

local Pets = {}
CA:RegisterModule("Pets", Pets)

Pets.frames = {}

function Pets:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        if CA.UI and CA.UI.activeTab == "pets" then
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end
    end
end

function Pets:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local class = U.GetPlayerClass()
    local mapID = U.GetCurrentMapID()
    local y = -10
    local padL = 10
    local w = content:GetWidth() - 20

    local function DrawRow(title, desc, r, g, b)
        local box = CreateFrame("Frame", nil, content, "BackdropTemplate")
        box:SetSize(w, 44)
        box:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        box:SetBackdropColor(0.05, 0.05, 0.05, 1)
        box:SetBackdropBorderColor(r, g, b, 0.3)
        table.insert(self.frames, box)

        local t = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        t:SetText(title)
        t:SetTextColor(r, g, b, 1)
        t:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -6)

        local d = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        d:SetFont(STANDARD_TEXT_FONT, 9)
        d:SetText(desc)
        d:SetTextColor(0.78, 0.73, 0.48, 1)
        d:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -22)

        y = y - 50
    end

    if class == "HUNTER" or class == "WARLOCK" then
        DrawRow("Utility Summon Configuration", "PvE: Ferocity pet (Primal Rage/Leech)  ·  PvP: Cunning pet (Master's Call Master)", 1, 0.82, 0)
    else
        DrawRow("Standard Identity Matrix", "Non-pet class tracking baseline. Class uses weapon metrics exclusively.", 0.55, 0.44, 0.25)
    end

    if mapID == 2434 or mapID == 2436 then
        DrawRow("◆ Zone Advantage Alert: Void/Undead Presence Detected", "Deploy DRAGONKIN family battle pets to execute type-advantage bonus damage matrix counters.", 1, 0.27, 0.27)
    else
        DrawRow("◆ Zone Advantage Alert: Neutral Environment", "Standard open-world scaling parameters active. Use preferred companion options.", 0.29, 1.00, 0.48)
    end
end