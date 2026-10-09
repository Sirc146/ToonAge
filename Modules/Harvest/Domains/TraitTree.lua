-- ToonAge/Modules/Harvest/Domains/TraitTree.lua  (harvest domain: the modern talent tree)
--
-- The talent system modern-API clients run (Forever: three trees, loadout
-- tabs, Apply Changes -- confirmed on the live client 2026-09-22), read from
-- C_Traits: every node, what it defines, and what rank YOU put in it.
--
-- Why it is worth recording: a recommendation engine needs to know what a
-- talent is worth in this game, and nobody has published that. What CAN be
-- known is what people actually pick at each level. That is observation, and
-- it starts here.
--
-- Every client API call goes through TA.Caps (spec R2). Moved here from
-- Modules/Forever/DataHarvester.lua in T4. Clients with the Vanilla-style
-- talent globals use Domains/TalentTrees.lua instead.
--
--   talents["CLASS:T:tree:node"] = tree, node, entry, spellID, name, yourRank,
--                                  maxRank, level
--   talentGeo["CLASS:tree:node"] = posX, posY, edges, conditions, type,
--                                  subTreeID, icon
--   talentGates / talentConds / talentApi -- tree gates, condition records,
--                                  and the GetNodeInfo field names seen

local TA = ToonAge
local Hv, Caps = TA.Harvester, TA.Caps

local Try, Put, Clean, Size = Hv.Try, Hv.Put, Hv.Clean, Hv.Size

local MAX_TALENTS = 2000   -- the talent set is small and finite by nature

local D = {
    id = "traitTree",
    needs = { "C_ClassTalents.GetActiveConfigID", "C_Traits" },
    -- CHARACTER_POINTS_CHANGED is the classic name; asked for too because the
    -- recorder has always rescanned talents on it.
    events = { "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "PLAYER_LEVEL_UP" },
    rescan = { { "trait tree", "ScanTraitTree" } },
    export = { { section = "talents", label = "Talents" } },
    summary = { { section = "talents", label = "Talent tree nodes" } },
}

--- One line per node: tree, node, entry, spellID, name, yourRank, maxRank, level.
function D:ScanTraitTree()
    local s = Hv:Store()
    if not s then return 0 end

    local configID = Try("C_ClassTalents.GetActiveConfigID")
    if not configID then return 0 end

    local cfg = Try("C_Traits.GetConfigInfo", configID)
    if type(cfg) ~= "table" or type(cfg.treeIDs) ~= "table" then return 0 end

    local _, class = Try("UnitClass", "player")
    class = class or "UNKNOWN"
    local level = Try("UnitLevel", "player") or 0
    local n = 0
    local rows = {}
    local hasTreeInfo = Caps.State("C_Traits.GetTreeInfo") == "present"

    local geoKeysSeen = false
    local geoWritten = false
    for _, treeID in ipairs(cfg.treeIDs) do
        -- Tree-level gates ("spend N points to unlock this row"), and the
        -- condition records nodes point at. Recorded raw, field names included.
        if hasTreeInfo then
            local ti = Try("C_Traits.GetTreeInfo", configID, treeID)
            if type(ti) == "table" then
                local gates = {}
                for _, g in ipairs(type(ti.gates) == "table" and ti.gates or {}) do
                    if type(g) == "table" then
                        gates[#gates + 1] = tostring(g.topLeftNodeID) .. ":" .. tostring(g.conditionID)
                    end
                end
                s.talentGates = s.talentGates or {}
                s.talentGates[class .. ":" .. tostring(treeID)] = table.concat(gates, ",")
                for _, g in ipairs(type(ti.gates) == "table" and ti.gates or {}) do
                    local ci = type(g) == "table" and g.conditionID
                        and Try("C_Traits.GetConditionInfo", configID, g.conditionID)
                    if type(ci) == "table" then
                        s.talentConds = s.talentConds or {}
                        s.talentConds[class .. ":" .. tostring(g.conditionID)] =
                            tostring(ci.spentAmountRequired) .. "\t" .. tostring(ci.isMet)
                    end
                end
            end
        end
        local nodes = Try("C_Traits.GetTreeNodes", treeID)
        if type(nodes) == "table" then
            for _, nodeID in ipairs(nodes) do
                local info = Try("C_Traits.GetNodeInfo", configID, nodeID)
                if type(info) == "table" then
                    local rank = info.activeRank or info.ranksPurchased or 0
                    local entryID = info.activeEntry and info.activeEntry.entryID
                    if not entryID and type(info.entryIDs) == "table" then
                        entryID = info.entryIDs[1]
                    end

                    local spellID, name
                    if entryID then
                        local entry = Try("C_Traits.GetEntryInfo", configID, entryID)
                        if type(entry) == "table" and entry.definitionID then
                            local def = Try("C_Traits.GetDefinitionInfo", entry.definitionID)
                            if type(def) == "table" then
                                spellID = def.spellID
                                if spellID then
                                    name = Try("C_Spell.GetSpellName", spellID)
                                end
                            end
                        end
                    end

                    -- Keyed by class + node, so the same node seen on two
                    -- characters of a class is one record. Per-character builds
                    -- are a separate, larger question; this is the vocabulary.
                    -- Geometry (2026-10-03): what a drawn tree and a point-path
                    -- planner need -- position, prerequisite edges, gating
                    -- conditions. Recorded only if the fields come back, and
                    -- the field names seen are logged once per class so the
                    -- next build reads what exists.
                    if not geoKeysSeen then
                        local ks = {}
                        for k in pairs(info) do ks[#ks + 1] = tostring(k) end
                        table.sort(ks)
                        s.talentApi = s.talentApi or {}
                        s.talentApi[class] = table.concat(ks, ",")
                        geoKeysSeen = true
                    end
                    local edges = {}
                    if type(info.visibleEdges) == "table" then
                        for _, e in ipairs(info.visibleEdges) do
                            if type(e) == "table" and e.targetNode then
                                edges[#edges + 1] = tostring(e.targetNode) .. ":" .. tostring(e.type or "")
                            end
                        end
                    end
                    local conds = {}
                    if type(info.conditionIDs) == "table" then
                        for _, c in ipairs(info.conditionIDs) do
                            conds[#conds + 1] = tostring(c)
                            local ci = Try("C_Traits.GetConditionInfo", configID, c)
                            if type(ci) == "table" then
                                s.talentConds = s.talentConds or {}
                                s.talentConds[class .. ":" .. tostring(c)] =
                                    tostring(ci.spentAmountRequired) .. "\t" .. tostring(ci.isMet)
                            end
                        end
                    end
                    geoWritten = true
                    s.talentGeo[class .. ":" .. tostring(treeID) .. ":" .. tostring(nodeID)] = table.concat({
                        Clean(info.posX), Clean(info.posY), table.concat(edges, ","),
                        table.concat(conds, ","), Clean(info.type), Clean(info.subTreeID),
                        Clean(spellID and Try("C_Spell.GetSpellTexture", spellID)),
                    }, "\t")

                    local key = class .. ":T:" .. tostring(treeID) .. ":" .. tostring(nodeID)
                    local rec = table.concat({
                            Clean(treeID), Clean(nodeID), Clean(entryID),
                            Clean(spellID), Clean(name), Clean(rank),
                            Clean(info.maxRanks), Clean(level),
                        }, "\t")
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
    end
    if geoWritten then Hv:Touch("talentGeo") end
    Hv:SaveCapture("talents", { rows = rows })
    return n
end

function D:OnEvent(event)
    self:ScanTraitTree()
end

function D:OnEnterWorld()
    self:ScanTraitTree()
end

-- ── Probe: talent-tree geometry ───────────────────────────────────────────
-- Does the tree carry what a drawn tree and a point planner need? Field
-- names of one node, then counts across this class's nodes.
D.probes = {
    talentGeometry = { title = "Talent tree geometry", run = function(P, L)
        local ok = pcall(D.ScanTraitTree, D)
        local s = Hv:Store()
        local _, class = Try("UnitClass", "player")
        L[#L + 1] = "GetNodeInfo fields: " .. tostring(s and s.talentApi and s.talentApi[class or ""] or "(none)")
        local n, pos, edges, conds = 0, 0, 0, 0
        local xs, ys = {}, {}
        for key, line in pairs((s and s.talentGeo) or {}) do
            if tostring(key):find("^" .. tostring(class) .. ":") then
                n = n + 1
                local f = Hv.Fields(line)
                if tonumber(f[1]) and tonumber(f[2]) then
                    pos = pos + 1
                    xs[f[1]] = true; ys[f[2]] = true
                end
                if f[3] and f[3] ~= "" then edges = edges + 1 end
                if f[4] and f[4] ~= "" then conds = conds + 1 end
            end
        end
        L[#L + 1] = ("nodes %d | with position %d (%d distinct x, %d distinct y) | with edges %d | with conditions %d%s")
            :format(n, pos, Size(xs), Size(ys), edges, conds, ok and "" or " | scan error")
        local gates = s and s.talentGates or {}
        for k, v in pairs(gates) do
            if tostring(k):find("^" .. tostring(class) .. ":") then L[#L + 1] = "gates " .. k .. " = " .. (v ~= "" and v or "(none)") end
        end
        local cn = 0
        for k, v in pairs((s and s.talentConds) or {}) do
            if tostring(k):find("^" .. tostring(class) .. ":") and cn < 8 then
                cn = cn + 1
                L[#L + 1] = "condition " .. k .. " spentRequired/isMet = " .. tostring(v):gsub("\t", " / ")
            end
        end
        P.Present(L, "C_Traits.GetTreeInfo present", "C_Traits.GetTreeInfo")
        P.Present(L, "C_Traits.GetConditionInfo present", "C_Traits.GetConditionInfo")
        P.Present(L, "C_Spell.GetSpellTexture present", "C_Spell.GetSpellTexture")
    end },
}

Hv:RegisterDomain(D)
