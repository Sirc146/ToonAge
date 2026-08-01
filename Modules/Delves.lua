-- CharacterAdvisor/Modules/Delves.lua
local CA = CharacterAdvisor
local U  = CA.Utils
local Z  = CA.Data.Zones

local Delves = {}
CA:RegisterModule("Delves", Delves)

Delves.frames = {}

function Delves:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        if CA.UI and CA.UI.activeTab == "delves" then
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end
    end
end

function Delves:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local role = U.GetPlayerRole()
    local avgIlvl = U.GetAverageIlvl()
    local y = -10
    local padL = 10
    local w = content:GetWidth() - 20

    local function QuickBox(text, r, g, b)
        local box = CreateFrame("Frame", nil, content, "BackdropTemplate")
        box:SetSize(w, 40)
        box:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        box:SetBackdropColor(0.04, 0.04, 0.04, 1)
        box:SetBackdropBorderColor(r, g, b, 0.4)
        table.insert(self.frames, box)

        local t = box:CreateFontString(nil,"OVERLAY","GameFontNormal")
        t:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        t:SetText(text)
        t:SetTextColor(r, g, b, 1)
        t:SetPoint("LEFT", box, "LEFT", 8, 0)
        t:SetWidth(w-16)
        t:SetJustifyH("LEFT")

        y = y - 46
    end

    if role == "TANK" then
        QuickBox("⚔ Brann Companion Spec: FULL DPS mode (Amplify Threat/Execute Cooldowns)", 1, 0.82, 0)
    elseif role == "HEALER" then
        QuickBox("🛡 Brann Companion Spec: TANK mode (Enforce Threat Management and Clear Spacing)", 0.33, 0.60, 1)
    else
        QuickBox("💚 Brann Companion Spec: HEALER mode (Keeps fragile damage specs sustained via potions)", 0.29, 1.00, 0.48)
    end

    local ready, rec = Z:GetReadiness(avgIlvl)
    if avgIlvl >= 233 then
        QuickBox("✓ Live Cap Scan: Gearing matches Tier 5-8 parameters. Run Bountiful targets daily.", 0.29, 1.00, 0.48)
    else
        QuickBox("⚠ Progression Gate: Current ilvl " .. avgIlvl .. " is optimal for Tier 1-4 catch-up loops.", 1, 0.60, 0.10)
    end
end