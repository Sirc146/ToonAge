-- ToonAge/Modules/Harvest/Domains/TalentTrees.lua  (harvest domain: Vanilla-style talent trees)
--
-- The tree SHAPE -- tab, tier, column, max rank -- from the legacy talent
-- globals (GetNumTalentTabs / GetTalentInfo), which Classic Era and TBC keep.
-- What a character happened to spend points on is not the point here.
--
-- No TOC lists this file yet: Forever has no legacy talent API (measured
-- 2026-10-04, self-test "absent: GetNumTalentTabs") and runs
-- Domains/TraitTree.lua; the Era and TBC packs (spec T6, T7) add it. Moved
-- here from Modules/Forever/DataHarvester.lua in T4, logic unchanged, every
-- client API call through TA.Caps (spec R2).
--
--   talents["CLASS:tab:index"] = tab name, talent name, tier, column, max rank

local TA = ToonAge
local Hv = TA.Harvester

local Try, Put, Clean = Hv.Try, Hv.Put, Hv.Clean

local MAX_TALENTS = 2000

local D = {
    id = "talentTrees",
    needs = { "GetNumTalentTabs", "GetTalentInfo" },
    events = { "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_LEVEL_UP" },
    rescan = { { "talents", "ScanTalents" } },
    export = { { section = "talents", label = "Talents" } },
    summary = { { section = "talents", label = "Talent tree nodes" } },
}

function D:ScanTalents()
    local s = Hv:Store()
    if not s then return 0 end

    local _, class = Try("UnitClass", "player")
    class = class or "UNKNOWN"
    local n = 0
    local rawTabs = Try("GetNumTalentTabs")
    if rawTabs == nil then return 0 end
    local rows = {}

    local numTabs = tonumber(rawTabs) or 0
    for tab = 1, numTabs do
        local tabName = Try("GetTalentTabInfo", tab)
        local numTalents = tonumber((Try("GetNumTalents", tab))) or 0
        for i = 1, numTalents do
            local name, _, tier, column, _, maxRank = Try("GetTalentInfo", tab, i)
            if name then
                local key = class .. ":" .. tab .. ":" .. i
                local rec = table.concat({ Clean(tabName), Clean(name), Clean(tier),
                                      Clean(column), Clean(maxRank) }, "\t")
                rows[key] = rec
                if s.talents[key] ~= nil then
                    s.talents[key] = rec
                    Hv:Touch("talents")
                elseif Put(s.talents, key, rec, MAX_TALENTS) then
                    n = n + 1
                end
            end
        end
    end
    Hv:SaveCapture("talents", { rows = rows })
    return n
end

function D:OnEvent(event)
    self:ScanTalents()
end

function D:OnEnterWorld()
    self:ScanTalents()
end

Hv:RegisterDomain(D)
