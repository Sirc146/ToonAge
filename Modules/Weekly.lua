-- ToonAge/Modules/Weekly.lua
local TA = ToonAge
local U  = TA.Utils

local Weekly = {}
TA:RegisterModule("Weekly", Weekly)

Weekly.frames = {}

function Weekly:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local y = -10
    local padL = 10
    local w = content:GetWidth() - 20

    local function ToggleRow(label, questID)
        local isDone = questID and C_QuestLog.IsQuestFlaggedCompleted(questID) or false

        local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        f:SetText((isDone and "|cFF4AFF7A[✓]|r " or "|cFFFF4444[ ]|r ") .. label)
        f:SetTextColor(isDone and 0.55 or 0.78, isDone and 0.55 or 0.73, isDone and 0.55 or 0.48, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        
        y = y - 20
        table.insert(self.frames, f)
    end

    ToggleRow("Expansion Core Weekly Campaign Cache", 80123)
    ToggleRow("Great Vault Metric Node 1: Dungeons/Keys cleared", 80124)
    ToggleRow("Great Vault Metric Node 2: Progression raid targets eliminated", 80125)
    ToggleRow("Bountiful Delve Vault Chest unlocked", 80126)
end