-- ToonAge/Modules/TBC/ProfessionAdvisor.lua (Anniversary — TBC Classic / 20506)
-- The professions tab draws the shared cards (ProfessionBoard). /ta profs
-- still prints the TBC perk summary from Data/TBC/TBCProfessions.lua.
--
-- Professions for that summary come from Core/SkillScan.lua, not
-- GetProfessions() — that API arrived in Wrath (3.0) and does not exist on
-- this client.

local TA = ToonAge
local L  = TA.Layout

local M = {}
TA:RegisterModule("ProfessionAdvisor", M)

function M:Render(content, side)
    local board = TA.GetModule and TA:GetModule("ProfessionBoard")
    if board and board.Render then
        return board:Render(content, side)
    end
    if L and L.EmptyState then
        L:EmptyState(content, "No professions learned.")
    end
end

M.SlashCommands = {
    profs = function(self)
        local Scan = TA.SkillScan
        local mine = Scan and Scan:GetProfessions() or {}
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100--- Professions ---|r")
        if #mine == 0 then
            TA:Raw(TA.LOG.OUTPUT, "  None found.")
            return
        end
        for _, prof in ipairs(mine) do
            local perk = TA.Data.Professions[prof.name]
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s %d/%d — %s",
                prof.name, prof.rank, prof.maxRank,
                perk and perk.summary or "no perk data"))
        end
    end,
}
