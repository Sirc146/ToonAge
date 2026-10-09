-- ToonAge/Modules/Character/Professions.lua
-- Retail's professions tab. The card layout lives in ProfessionBoard so every
-- version draws the same chrome; this module keeps the tab's module name.

local TA = ToonAge

local Professions = {}
TA:RegisterModule("Professions", Professions)

function Professions:Render(content, sidebar)
    local board = TA.GetModule and TA:GetModule("ProfessionBoard")
    if board and board.Render then
        return board:Render(content, sidebar)
    end
end
