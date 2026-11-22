-- ToonAge/Modules/Forever/Talents.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- The talent tree as a grid. Columns and rows come from that tree's own
-- distinct posX and posY values, in rank order, so a tree is never forced
-- into a fixed shape. The grid shrinks to the content width instead of
-- scrolling sideways. When the tree is taller than the space under the
-- points header, that tree area scrolls on its own and the header stays put.
-- A node is locked from its own condition, not from the row it sits on.
-- The tab does not say which talent is best.
--
-- WHY IT WAS REWRITTEN. The previous version read GetNumTalentTabs /
-- GetTalentInfo, the Vanilla-era globals. Forever's talent window is the
-- MODERN one: three trees side by side, Primary and Secondary loadout tabs, an
-- "Unspent Talents" counter and an "Apply Changes" button -- screenshot
-- confirmed on the live client, 2026-09-22. That is the C_Traits system, so
-- the old globals never answered here and this tab printed "could not be read"
-- for its entire life. TellMeWhen reached the same conclusion independently
-- (see its Conditions/Categories/Talents.lua, which routes Camelot down the
-- Dragonflight branch), which is a second shipping addon agreeing.
--
-- WHAT IT STILL REFUSES TO DO. It does not say which talent is BEST. That
-- needs to know a fire talent's value against a frost one for THIS game, which
-- is stat weights nobody has verified -- the same missing data that keeps the
-- gear tab a readout. "Available to spend on" is a fact the client reports.
-- "Worth spending on" is not, and inventing it here would be the one thing
-- this build exists to avoid.
--
-- Everything is read through Try() and every field access is guarded: the
-- C_Traits field set differs between client generations, and a missing field
-- must drop one line from the tab rather than take the tab down.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverTalents", M)

-- Vanilla grants the first talent point at level 10. Below that the trees
-- legitimately hold nothing, which is a normal state to explain rather than an
-- API failure to warn about.
local TALENT_MIN_LEVEL = 10

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Num(v)
    if v == nil then return nil end
    return tonumber(tostring(v))
end

local function SpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local n = Try(C_Spell.GetSpellName, spellID)
        if n then return tostring(n) end
    end
    local n = Try(GetSpellInfo, spellID)
    if n then return tostring(n) end
    return nil
end

--- The active loadout's config id, or nil when the client has no trait system.
local function ActiveConfig()
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
    return Num(Try(C_ClassTalents.GetActiveConfigID))
end

--- Walk one tree.
--- @return table ranked  { {name, rank, max} }
--- @return table available  { {name, cost} } nodes a point can go into now
--- @return number spent
local function ReadTree(configID, treeID)
    local ranked, available, spent = {}, {}, 0
    if not (C_Traits and C_Traits.GetTreeNodes) then return ranked, available, spent end

    local nodes = Try(C_Traits.GetTreeNodes, treeID)
    if type(nodes) ~= "table" then return ranked, available, spent end

    for _, nodeID in ipairs(nodes) do
        local info = Try(C_Traits.GetNodeInfo, configID, nodeID)
        if type(info) == "table" then
            local rank = Num(info.activeRank) or Num(info.ranksPurchased) or 0
            local max  = Num(info.maxRanks) or 0
            spent = spent + rank

            -- Name the node by the spell its ACTIVE entry defines; for a choice
            -- node with nothing picked yet, the first entry stands in so the row
            -- still reads as something rather than as a node id.
            local entryID = info.activeEntry and info.activeEntry.entryID
            if not entryID and type(info.entryIDs) == "table" then entryID = info.entryIDs[1] end

            local name
            if entryID and C_Traits.GetEntryInfo then
                local entry = Try(C_Traits.GetEntryInfo, configID, entryID)
                if type(entry) == "table" and entry.definitionID and C_Traits.GetDefinitionInfo then
                    local def = Try(C_Traits.GetDefinitionInfo, entry.definitionID)
                    if type(def) == "table" then
                        name = SpellName(def.spellID) or (def.overrideName and tostring(def.overrideName))
                    end
                end
            end
            name = name or ("Node " .. tostring(nodeID))

            if rank > 0 then
                ranked[#ranked + 1] = { name = name, rank = rank, max = (max > 0) and max or rank }
            elseif info.canPurchaseRank == true then
                -- The client's own answer to "can a point go here right now".
                -- No judgement attached: it is availability, not a suggestion.
                available[#available + 1] = { name = name, cost = Num(info.entryIDsWithCommittedRanks) or 1 }
            end
        end
    end
    return ranked, available, spent
end

--- Ranked talents across every tree: { { name, rank }, ... }.
--- Casts uses this to tell Fire from Frost. Empty when the trait API is absent.
function M:RankedTalents()
    local configID = ActiveConfig()
    if not configID or not (C_Traits and C_Traits.GetConfigInfo) then return nil end
    local cfg = Try(C_Traits.GetConfigInfo, configID)
    local treeIDs = type(cfg) == "table" and cfg.treeIDs
    if type(treeIDs) ~= "table" then return nil end
    local out = {}
    for _, treeID in ipairs(treeIDs) do
        local ranked = ReadTree(configID, treeID)
        for _, r in ipairs(ranked) do
            out[#out + 1] = r
        end
    end
    return out
end

--- Unspent points for a tree, when the client reports a currency for it.
local function TreeCurrency(configID, treeID)
    if not (C_Traits and C_Traits.GetTreeCurrencyInfo) then return nil end
    local list = Try(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
    if type(list) ~= "table" then return nil end
    local total = 0
    local any = false
    for _, c in ipairs(list) do
        local q = Num(type(c) == "table" and c.quantity)
        if q then total = total + q; any = true end
    end
    return any and total or nil
end

-- ─── GRID ──────────────────────────────────────────────────────────────────
--
-- Each tree is placed from its own posX and posY. The rank of those
-- coordinates is the column and the row, so nothing here assumes a 12 by 7
-- grid. A measured Rogue tree is 12 columns by 7 rows. A measured Warlock
-- tree is 11 columns by 9 rows, 52 nodes. Both fall out of the coordinates.
-- Cells use that rank, not the raw pixel gap, and the grid shrinks to the
-- content width.
--
-- The points header stays on the content frame. The tree sits in a scroll
-- frame under it: as tall as the tree when that fits, and as tall as the
-- space under the header when it does not. A 7-row tree fits the usual
-- pane. A 9-row tree is taller than a pane of about 368px, so that one
-- scrolls.
--
-- Node size follows the tab-bar window breakpoints (style guide §5):
--   window >= 740  -> 40 px   (Full)
--   window >= 676  -> 36 px   (Compact)
--   below 676      -> 28 px   (Glyph; the window itself stops at 568)
--
-- Available, partial, and maxed colours live in M.Theme only. The frame art
-- in Media/frame is white with alpha, so SetVertexColor applies the state.
-- Hover and selection swap in the _focus frame and talent_glow_circle, both
-- tinted gold. A gated talent carries its own lock.

-- Same window cuts as the tab bar.
local BREAK_FULL    = 740
local BREAK_COMPACT = 676
local NODE_FULL     = 40
local NODE_COMPACT  = 36
local NODE_GLYPH    = 28

-- Gap between nodes, before the grid is scaled down to fit.
local GRID_GAP = 8

-- Core/UI.lua: the frame is 580, the title bar 34, the tab bar 30. The
-- content scroll fills the rest. Used when that scroll has no height yet.
local CONTENT_VIEW_FALLBACK = 580 - 34 - 30

-- The inner scrollbar hangs off the tree. Leave it room only while the
-- tree actually scrolls, so the last column stays visible.
local SCROLLBAR_PX = 18

-- Space between two trees in the same pane. A single tree adds none.
local TREE_GAP = 16

M.LINE_PX = 2
M.RING_PX = 3          -- the focus frame is this much heavier than the idle ring
M.GLOW_OUTSET = 6
M.LOCK_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_lock_16.tga"
M.LOCK_ALPHA = 0.5

-- White frame art. Masters at 40 and 36; the _32 cut below 32px (the 28px
-- glyph node, and anything the 568px window scales smaller than that).
local FRAME = "Interface\\AddOns\\ToonAge\\Media\\frame\\"
M.TEX = {
    square        = FRAME .. "talent_square.tga",
    square32      = FRAME .. "talent_square_32.tga",
    circle        = FRAME .. "talent_circle.tga",
    circle32      = FRAME .. "talent_circle_32.tga",
    squareFocus   = FRAME .. "talent_square_focus.tga",
    squareFocus32 = FRAME .. "talent_square_focus_32.tga",
    circleFocus   = FRAME .. "talent_circle_focus.tga",
    circleFocus32 = FRAME .. "talent_circle_focus_32.tga",
    glow          = FRAME .. "talent_glow_circle.tga",
    badgeFill     = FRAME .. "talent_badge_fill.tga",
    badgeBorder   = FRAME .. "talent_badge_border.tga",
    edge          = FRAME .. "talent_edge.tga",
    arrow         = FRAME .. "talent_arrow.tga",
}

M.Theme = {
    available = { 70 / 255, 200 / 255, 106 / 255 },    -- #46C86A
    partial   = { 245 / 255, 247 / 255, 250 / 255 },   -- #F5F7FA
    maxed     = { 251 / 255, 224 / 255, 143 / 255 },   -- #FBE08F
    locked    = { 122 / 255, 130 / 255, 140 / 255 },   -- #7A828C
    gold      = { 232 / 255, 179 / 255, 90 / 255 },    -- #E8B35A hover, selection, glow
    highlight = { 1, 0.957, 0.745 },
    line      = { 0.62, 0.58, 0.48, 0.90 },
}

--- Active focus colour for hover, selection, and glow. Reads Core/Theme.lua
--- when loaded so modern_azeroth tracks the active theme pack (Class / Gold /
--- Blizzard), and falls back to M.Theme.gold on classic or standalone runs.
function M.FocusColor()
    local active = TA.Theme and TA.Theme.active
    local t = active and active.talent
    if type(t) == "table" and type(t.focus) == "table" and t.focus[1] ~= nil then
        return t.focus
    end
    return M.Theme.gold
end

--- Active route highlight colour for planned talent paths.
function M.PlanRouteColor()
    local active = TA.Theme and TA.Theme.active
    local t = active and active.talent
    if type(t) == "table" and type(t.plan_route) == "table" and t.plan_route[1] ~= nil then
        return t.plan_route
    end
    return M.FocusColor()
end

-- ─── PLAN MODE & NODE DETAIL (READ-ONLY, NEVER SPENDS) ─────────────────────
-- Plan Mode computes a route to a player-chosen target through real
-- prerequisites and spent-point gates. It never calls any C_Traits spend or
-- commit API, and never claims DPS optimality.

M.planTargetID = nil
M.whatIfEnabled = false
M.sandboxEnabled = false
M.activeFilter = "all"

local Secret, MinReq, NodeGate

local PLAN_HONEST_NOTE = "Route to chosen target only. Never spends points or claims DPS optimality."

local function BuildNodeGraph(nodes)
    local byID = {}
    local incoming = {}
    local outgoing = {}
    if type(nodes) ~= "table" then return byID, incoming, outgoing end
    for _, n in ipairs(nodes) do
        if type(n) == "table" and n.id ~= nil then
            byID[n.id] = n
            incoming[n.id] = incoming[n.id] or {}
            outgoing[n.id] = outgoing[n.id] or {}
        end
    end
    local seen = {}
    local function addEdge(srcID, dstID)
        if not byID[srcID] or not byID[dstID] or srcID == dstID then return end
        local key = tostring(srcID) .. ">" .. tostring(dstID)
        if seen[key] then return end
        seen[key] = true
        outgoing[srcID][#outgoing[srcID] + 1] = dstID
        incoming[dstID][#incoming[dstID] + 1] = srcID
    end
    for _, n in ipairs(nodes) do
        if type(n) == "table" and n.id ~= nil and type(n.edges) == "table" then
            for _, e in ipairs(n.edges) do
                local tid, isArrow
                if type(e) == "table" then
                    tid = e.targetNode or e.targetNodeID
                    isArrow = M.EdgeArrow(e.type)
                else
                    tid = e
                    isArrow = false
                end
                if tid ~= nil and byID[tid] then
                    if isArrow then
                        addEdge(n.id, tid)
                    elseif type(n.posY) == "number" and type(byID[tid].posY) == "number"
                        and n.posY < byID[tid].posY then
                        addEdge(n.id, tid)
                    end
                end
            end
        end
    end
    return byID, incoming, outgoing
end

--- Client-verbatim details for one node: rank, gate status, prerequisites,
--- and downstream unlocks. Returns nil when nodeID is absent.
function M.NodeDetail(nodes, conditions, nodeID, spent)
    if nodeID == nil or type(nodes) ~= "table" then return nil end
    local byID, incoming, outgoing = BuildNodeGraph(nodes)
    local node = byID[nodeID]
    if not node then return nil end

    local rank = tonumber(node.rank) or 0
    local max = tonumber(node.max) or 1
    local locked, unmet = NodeGate(node, conditions or {}, spent)

    local prereqs = {}
    for _, pid in ipairs(incoming[nodeID] or {}) do
        local pn = byID[pid]
        if pn then
            local pr = tonumber(pn.rank) or 0
            local pm = tonumber(pn.max) or 1
            prereqs[#prereqs + 1] = {
                id = pid,
                name = pn.name or ("Node " .. tostring(pid)),
                rank = pr,
                max = pm,
                met = pr > 0,
            }
        end
    end
    table.sort(prereqs, function(a, b) return tostring(a.id) < tostring(b.id) end)

    local unlocks = {}
    for _, uid in ipairs(outgoing[nodeID] or {}) do
        local un = byID[uid]
        if un then
            unlocks[#unlocks + 1] = {
                id = uid,
                name = un.name or ("Node " .. tostring(uid)),
            }
        end
    end
    table.sort(unlocks, function(a, b) return tostring(a.id) < tostring(b.id) end)

    return {
        id = node.id,
        name = node.name or ("Node " .. tostring(node.id)),
        rank = rank,
        max = max,
        spellID = node.spellID,
        locked = locked and true or false,
        unmet = unmet,
        lockTip = locked and M.LockTip(unmet) or nil,
        prereqs = prereqs,
        unlocks = unlocks,
    }
end

--- Pure read-only route to a player-chosen target node through prerequisite
--- edges and spent-point gates. Cycle-safe; never mutates game state.
function M.PlanRoute(nodes, conditions, targetID, spent)
    if targetID == nil or type(nodes) ~= "table" then
        return { valid = false, steps = {}, inPath = {}, inPathEdge = {}, honestNote = PLAN_HONEST_NOTE }
    end
    local byID, incoming = BuildNodeGraph(nodes)
    local target = byID[targetID]
    if not target then
        return { valid = false, steps = {}, inPath = {}, inPathEdge = {}, honestNote = PLAN_HONEST_NOTE }
    end

    local curSpent = tonumber(spent) or 0
    local conds = conditions or {}
    local ordered = {}
    local visited = {}
    local inPathEdge = {}

    local function walk(id)
        if visited[id] then return end
        visited[id] = true
        local preds = incoming[id] or {}
        table.sort(preds, function(a, b) return tostring(a) < tostring(b) end)
        for _, pid in ipairs(preds) do
            if byID[pid] then
                inPathEdge[tostring(pid) .. ":" .. tostring(id)] = true
                inPathEdge[tostring(id) .. ":" .. tostring(pid)] = true
                walk(pid)
            end
        end
        ordered[#ordered + 1] = id
    end
    walk(targetID)

    local steps = {}
    local inPath = {}
    local projectedSpent = curSpent
    local totalNeeded = 0
    local firstGateNeed = 0

    for _, id in ipairs(ordered) do
        local n = byID[id]
        local rank = tonumber(n.rank) or 0
        local max = tonumber(n.max) or 1
        local need = 0
        if id == targetID then
            need = math.max(0, max - rank)
        else
            -- Prerequisite unlocks once at least 1 rank is purchased (or full
            -- rank if single-rank). Remaining ranks stay optional.
            need = (rank == 0) and 1 or 0
        end
        local gate = MinReq(n, conds)
        local locked, unmet = NodeGate(n, conds, curSpent)
        local req = unmet or (locked and gate) or gate
        local gateNeed = 0
        if req and projectedSpent < req then
            gateNeed = req - projectedSpent
        end
        if need > 0 then
            local idx = #steps + 1
            steps[idx] = {
                id = id,
                name = n.name or ("Node " .. tostring(id)),
                rank = rank,
                max = max,
                pointsNeeded = need,
                gate = req,
                gateNeed = gateNeed,
            }
            inPath[id] = idx
            if idx == 1 then firstGateNeed = gateNeed end
            projectedSpent = projectedSpent + gateNeed + need
            totalNeeded = totalNeeded + gateNeed + need
        end
    end

    local targetRank = tonumber(target.rank) or 0
    local targetMax = tonumber(target.max) or 1
    local alreadyMaxed = targetMax > 0 and targetRank >= targetMax
    local nextNode = steps[1]

    return {
        valid = true,
        targetID = targetID,
        targetName = target.name or ("Node " .. tostring(targetID)),
        alreadyMaxed = alreadyMaxed,
        steps = steps,
        inPath = inPath,
        inPathEdge = inPathEdge,
        totalPointsNeeded = totalNeeded,
        gateNeed = firstGateNeed,
        nextNode = nextNode,
        honestNote = PLAN_HONEST_NOTE,
    }
end

--- Non-spending What-If rank projection for one cell along a planned route.
--- Returns projectedRank, delta. Never writes or commits any talent point.
function M.WhatIfRank(cell, route, unspent)
    if type(cell) ~= "table" then return 0, 0 end
    local base = tonumber(cell.rank) or 0
    local max = tonumber(cell.max) or 1
    if not M.whatIfEnabled or type(route) ~= "table" or not route.valid then
        return base, 0
    end
    local idx = route.inPath and route.inPath[cell.id]
    if not idx then return base, 0 end
    local budget = tonumber(unspent) or 0
    if budget <= 0 then budget = 1 end
    local left = budget
    for i, st in ipairs(route.steps) do
        if left <= 0 then break end
        local add = math.min(st.pointsNeeded or 0, left)
        if i == idx then
            local proj = math.min(max, base + add)
            return proj, proj - base
        end
        left = left - add
    end
    return base, 0
end

--- Active planned route: uses TalentIntel's multi-milestone roadmap when
--- milestones are pinned in the active saved slot, otherwise falls back to
--- single-target M.PlanRoute(M.planTargetID).
function M.ActiveRoute(nodes, conditions, spent, unspent, playerLevel)
    local TI = TA.TalentIntel
    if TI and TI.ActiveSlot and TI.BuildRoadmap then
        local slot = TI.ActiveSlot()
        if slot and type(slot.targets) == "table" and #slot.targets > 0 then
            return TI.BuildRoadmap(nodes, conditions or {}, slot.targets, spent, unspent, playerLevel, M.PlanRoute)
        end
    end
    if M.planTargetID ~= nil then
        return M.PlanRoute(nodes, conditions or {}, M.planTargetID, spent)
    end
    return nil
end

--- Expose the next planned talent point for the Now briefing tab.
--- Reads active multi-milestone roadmap / sandbox / single target.
--- Never spends points; marks combat-secret values honestly without guessing.
function M.GetNextPlannedPoint(nodes, conditions, spent, unspent)
    local isSecret = false
    if nodes == nil then
        local ok, rn, rc, _, rs, ru = pcall(M.ReadGrid)
        if ok and type(rn) == "table" and #rn > 0 then
            nodes, conditions, spent, unspent = rn, rc, rs, ru
        elseif type(M._lastNodes) == "table" and #M._lastNodes > 0 then
            nodes, conditions, spent, unspent = M._lastNodes, M._lastConds, M._lastSpent, M._lastUnspent
            isSecret = true
        end
    end
    if Secret(unspent) or Secret(spent) then
        isSecret = true
        unspent = tonumber(M._lastUnspent) or 0
        spent = tonumber(M._lastSpent) or 0
    end
    local u = math.floor(tonumber(unspent) or 0)
    local s = math.floor(tonumber(spent) or 0)
    local lvl = Num(Try(UnitLevel, "player")) or 10
    local prefix = isSecret and "(in combat) " or ""

    local TI = TA.TalentIntel
    local slot, slotName
    if TI and TI.ActiveSlot then slot, slotName = TI.ActiveSlot() end
    local hasMilestones = slot and type(slot.targets) == "table" and #slot.targets > 0
    local sandboxTotals = (TI and TI.SandboxTotals and type(nodes) == "table") and TI.SandboxTotals(nodes, s, lvl) or nil
    local hasSandbox = sandboxTotals and sandboxTotals.added > 0

    if not hasMilestones and M.planTargetID == nil then
        if hasSandbox and type(nodes) == "table" then
            -- Find first unspent sandbox node to surface as next planned point
            local nextName, nextID
            for _, n in ipairs(nodes) do
                if (TI.SandboxDelta(n.id) or 0) > 0 then
                    nextName = n.name or ("Node " .. tostring(n.id))
                    nextID = n.id
                    break
                end
            end
            local summary = string.format("%s[%s] %d unspent. Sandbox +%d pts (Lv %d build). Next: %s.",
                prefix, tostring(slotName or "Solo"), u, sandboxTotals.added, sandboxTotals.buildLevel,
                tostring(nextName or "planned talent"))
            return {
                hasPlan = true,
                slotName = slotName,
                targetName = tostring(slotName or "Solo") .. " Sandbox",
                nextNodeID = nextID,
                nextNodeName = nextName,
                alreadyMaxed = false,
                unspent = u,
                gateNeed = 0,
                isSecret = isSecret,
                summary = summary,
                honestNote = PLAN_HONEST_NOTE,
            }
        end
        local summary
        if u > 0 then
            summary = string.format("%s%d unspent %s. Click any talent to set a plan target.",
                prefix, u, u == 1 and "point" or "points")
        else
            summary = prefix .. "No plan target set. Click any talent to inspect or plan a route."
        end
        return {
            hasPlan = false,
            unspent = u,
            isSecret = isSecret,
            summary = summary,
            honestNote = PLAN_HONEST_NOTE,
        }
    end

    if type(nodes) ~= "table" then
        return {
            hasPlan = false,
            unspent = u,
            isSecret = isSecret,
            summary = prefix .. "No plan target set. Click any talent to inspect or plan a route.",
            honestNote = PLAN_HONEST_NOTE,
        }
    end

    local route = M.ActiveRoute(nodes, conditions or {}, s, u, lvl)
    if not route or not route.valid then
        return {
            hasPlan = false,
            unspent = u,
            isSecret = isSecret,
            summary = prefix .. "Planned target not found in current tree.",
            honestNote = PLAN_HONEST_NOTE,
        }
    end
    local targetLabel = route.targetName
    local unlockLv = nil
    if type(route.milestones) == "table" and #route.milestones > 0 then
        local lastM = route.milestones[#route.milestones]
        targetLabel = lastM.name
        unlockLv = lastM.unlockLevel
        if #route.milestones > 1 then
            targetLabel = string.format("%s (+%d)", route.milestones[1].name, #route.milestones - 1)
        end
    end
    if route.alreadyMaxed or not route.nextNode then
        return {
            hasPlan = true,
            slotName = slotName,
            targetID = route.targetID,
            targetName = targetLabel,
            alreadyMaxed = true,
            unspent = u,
            gateNeed = 0,
            isSecret = isSecret,
            summary = string.format("%sPlanned target %s is maxed.", prefix, tostring(targetLabel or "target")),
            honestNote = PLAN_HONEST_NOTE,
        }
    end

    local nxt = route.nextNode
    local summary
    local slotTag = (hasMilestones and slotName) and ("[" .. slotName .. "] ") or ""
    local lvTag = (unlockLv and unlockLv > lvl) and string.format(" (Lv %d)", unlockLv) or ""
    if route.gateNeed > 0 then
        summary = string.format("%s%s%d unspent. Next: %s (needs %d more spent in tree).",
            prefix, slotTag, u, nxt.name, route.gateNeed)
    else
        summary = string.format("%s%s%d unspent. Next: %s (toward %s%s).",
            prefix, slotTag, u, nxt.name, tostring(targetLabel or "target"), lvTag)
    end
    return {
        hasPlan = true,
        slotName = slotName,
        targetID = route.targetID or (route.milestones and route.milestones[1] and route.milestones[1].id),
        targetName = targetLabel,
        nextNodeID = nxt.id,
        nextNodeName = nxt.name,
        alreadyMaxed = false,
        unspent = u,
        gateNeed = route.gateNeed,
        unlockLevel = unlockLv,
        isSecret = isSecret,
        summary = summary,
        honestNote = PLAN_HONEST_NOTE,
    }
end

--- Master frame at 32px and above; the _32 cut underneath.
function M.UsesSmallFrame(px)
    return (tonumber(px) or 40) < 32
end

--- Square only for the entry types Blizzard draws with a square template.
--- SpendSquare is 1 and SpendCapstoneSquare is 14 in Enum.TraitNodeEntryType.
--- A missing type, and every other entry type, is the circle that template
--- table falls back to.
function M.Shape(entryType)
    local E = Enum and Enum.TraitNodeEntryType
    local square = E and E.SpendSquare or 1
    local capSquare = E and E.SpendCapstoneSquare or 14
    if entryType == square or entryType == capSquare then return "square" end
    return "circle"
end

--- Idle or focus frame for this shape and drawn size.
function M.FrameFile(shape, hot, px)
    local small = M.UsesSmallFrame(px)
    local square = shape == "square"
    if hot then
        if square then return small and M.TEX.squareFocus32 or M.TEX.squareFocus end
        return small and M.TEX.circleFocus32 or M.TEX.circleFocus
    end
    if square then return small and M.TEX.square32 or M.TEX.square end
    return small and M.TEX.circle32 or M.TEX.circle
end

--- A prerequisite edge points one way. Visual-only connections stay lines.
--- SufficientForAvailability is 2 and RequiredForAvailability is 3.
function M.EdgeArrow(edgeType)
    if type(edgeType) ~= "number" then return false end
    local E = Enum and Enum.TraitEdgeType
    local sufficient = E and E.SufficientForAvailability or 2
    local required = E and E.RequiredForAvailability or 3
    return edgeType == sufficient or edgeType == required
end

Secret = function(v)
    if v == nil then return false end
    if U and U.IsSecret and U.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function Plain(v)
    if v == nil or Secret(v) then return nil end
    local ok, s = pcall(tostring, v)
    if not ok then return nil end
    return tonumber(s)
end

local function Round(n)
    return math.floor(n + 0.5)
end

function M.NodePx(windowWidth)
    local w = tonumber(windowWidth) or 900
    if w >= BREAK_FULL then return NODE_FULL end
    if w >= BREAK_COMPACT then return NODE_COMPACT end
    return NODE_GLYPH
end

function M.Header(spent, unspent)
    spent   = math.floor(tonumber(spent) or 0)
    unspent = math.floor(tonumber(unspent) or 0)
    local left
    if spent == 1 then
        left = "1 point spent"
    else
        left = string.format("%d points spent", spent)
    end
    return left .. " · " .. string.format("%d to spend", unspent)
end

--- "2/5" once a multi-rank node has a point in it. Rank 0 stays bare.
function M.Badge(rank, max)
    rank = tonumber(rank) or 0
    max  = tonumber(max) or 0
    if max <= 1 or rank <= 0 then return nil end
    return string.format("%d/%d", rank, max)
end

--- "Requires N points spent" for the lock on one gated talent.
function M.LockTip(amount)
    amount = tonumber(amount)
    if not amount then return nil end
    return string.format("Requires %d points spent", amount)
end

--- Rank wins over the gate for the frame colour: a bought rank is partial or
--- maxed. The lock is separate, and gold is not a state.
function M.NodeState(rank, max, locked)
    rank = tonumber(rank) or 0
    max  = tonumber(max) or 0
    if max > 0 and rank >= max then return "maxed" end
    if rank > 0 then return "partial" end
    if locked then return "locked" end
    return "available"
end

local function Ranks(values)
    local seen, list = {}, {}
    for _, v in ipairs(values) do
        if type(v) == "number" then
            local r = Round(v)
            if not seen[r] then
                seen[r] = true
                list[#list + 1] = r
            end
        end
    end
    table.sort(list)
    local map = {}
    for i, v in ipairs(list) do map[v] = i end
    return map, list
end

local function Usable(nodes)
    local out, xs, ys = {}, {}, {}
    if type(nodes) ~= "table" then return out, xs, ys end
    for _, n in ipairs(nodes) do
        if type(n) == "table" and type(n.posX) == "number" and type(n.posY) == "number" then
            out[#out + 1] = n
            xs[#xs + 1] = n.posX
            ys[#ys + 1] = n.posY
        end
    end
    return out, xs, ys
end

local function ReqOf(cond)
    if type(cond) ~= "table" then return nil end
    local req = cond.spentRequired
    if type(req) ~= "number" then req = cond.spentAmountRequired end
    if type(req) ~= "number" then return nil end
    return req
end

--- Lowest spent-requirement on this node, whether or not it is already met.
MinReq = function(node, conds)
    if type(node.conditionIDs) ~= "table" then return nil end
    local best
    for _, cid in ipairs(node.conditionIDs) do
        local req = ReqOf(conds and conds[cid])
        if req and (not best or req < best) then best = req end
    end
    return best
end

--- Locked when any of this node's own conditions is unmet. A neighbour on
--- the same row does not lock it. Returns locked, lowest unmet amount.
NodeGate = function(node, conds, spent)
    if type(node.conditionIDs) ~= "table" then return false, nil end
    local locked, lowest = false, nil
    for _, cid in ipairs(node.conditionIDs) do
        local c = conds and conds[cid]
        local req = ReqOf(c)
        local met
        if type(c) == "table" then met = c.isMet end
        -- A false isMet must stay false. `and/or` would swallow it.
        if met ~= true and met ~= false then
            if req and type(spent) == "number" then met = spent >= req end
        end
        if met == false then
            locked = true
            if req and (not lowest or req < lowest) then lowest = req end
        end
    end
    return locked, lowest
end

--- posY increases downward when the cheapest gate sits above the dearest
--- one (smaller posY on the smaller requirement). No spread: leave it
--- downward, which is the trait UI's own axis. Returns yDown.
local function YIncreasesDown(nodes, conds)
    local lowReq, highReq
    for _, n in ipairs(nodes) do
        local req = MinReq(n, conds)
        if req then
            if not lowReq or req < lowReq then lowReq = req end
            if not highReq or req > highReq then highReq = req end
        end
    end
    if not lowReq or not highReq or lowReq == highReq then return true end
    local function avg(req)
        local sum, n = 0, 0
        for _, node in ipairs(nodes) do
            if MinReq(node, conds) == req then
                sum = sum + node.posY
                n = n + 1
            end
        end
        if n == 0 then return nil end
        return sum / n
    end
    local a, b = avg(lowReq), avg(highReq)
    if not a or not b or a == b then return true end
    return a < b
end

local function GateReport(nodes, conds)
    local bucket = {}
    for _, n in ipairs(nodes) do
        if type(n.conditionIDs) == "table" and n.id ~= nil then
            for _, cid in ipairs(n.conditionIDs) do
                local key = cid
                bucket[key] = bucket[key] or {}
                bucket[key][#bucket[key] + 1] = n.id
            end
        end
    end
    local ids = {}
    for cid in pairs(bucket) do ids[#ids + 1] = cid end
    table.sort(ids, function(a, b)
        local sa = ReqOf(conds and conds[a]) or 999999
        local sb = ReqOf(conds and conds[b]) or 999999
        if sa ~= sb then return sa < sb end
        if type(a) == "number" and type(b) == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)
    local gates = {}
    for _, cid in ipairs(ids) do
        local who = bucket[cid]
        table.sort(who, function(a, b)
            if type(a) == "number" and type(b) == "number" then return a < b end
            return tostring(a) < tostring(b)
        end)
        gates[#gates + 1] = {
            id = cid,
            spent = ReqOf(conds and conds[cid]),
            nodes = who,
        }
    end
    return gates
end

local function JoinIds(list)
    local parts = {}
    for i, id in ipairs(list) do parts[i] = tostring(id) end
    if #parts == 0 then return "none" end
    return table.concat(parts, ", ")
end

function M.Diagnose(nodes, conditions)
    local usable, xs, ys = Usable(nodes)
    local _, xlist = Ranks(xs)
    local _, ylist = Ranks(ys)
    local yDown = YIncreasesDown(usable, conditions)
    local gates = GateReport(usable, conditions)
    local lines = {
        string.format("talent grid: %d columns, %d rows; posY increases %s%s",
            #xlist, #ylist,
            yDown and "downward" or "upward",
            yDown and "" or "; layout flipped"),
    }
    for _, g in ipairs(gates) do
        local req = g.spent and (tostring(g.spent) .. " points") or "an unknown amount"
        lines[#lines + 1] = string.format(
            "talent gate condition %s requires %s, gates nodes %s",
            tostring(g.id), req, JoinIds(g.nodes))
    end
    return {
        yDown = yDown,
        flipped = not yDown,
        columns = #xlist,
        rows = #ylist,
        gates = gates,
        lines = lines,
    }
end

local function Fit(nodePx, cols, avail)
    local natural = cols * nodePx + math.max(cols - 1, 0) * GRID_GAP
    local scale = 1
    if avail and avail > 0 and natural > avail then
        scale = avail / natural
    end
    local draw = math.max(1, math.floor(nodePx * scale + 0.5))
    local gap = math.max(0, math.floor(GRID_GAP * scale + 0.5))
    local function width()
        return cols * draw + math.max(cols - 1, 0) * gap
    end
    local w = width()
    -- Rounding can push the grid a pixel or two past the content width.
    -- Shrink the gap, then the nodes, so it never needs a horizontal scroll.
    -- The 568px window is the narrowest this has to fit.
    if avail and avail > 0 then
        while w > avail and gap > 0 do
            gap = gap - 1
            w = width()
        end
        while w > avail and draw > 1 do
            draw = draw - 1
            w = width()
        end
    end
    return draw, gap, w, scale
end

--- Place every node. Row 1 is the top of the tree. An unmet gate locks that
--- node only, and the lock text is that node's own requirement.
function M.Layout(nodes, conditions, opts)
    opts = opts or {}
    conditions = conditions or {}
    local usable, xs, ys = Usable(nodes)
    local xmap, xlist = Ranks(xs)
    local ymap, ylist = Ranks(ys)
    local diag = M.Diagnose(usable, conditions)
    local cols, rows = #xlist, #ylist
    local nodePx = M.NodePx(opts.windowWidth)
    local draw, gap, width, scale = 0, 0, 0, 1
    if cols > 0 then
        draw, gap, width, scale = Fit(nodePx, cols, opts.availWidth)
    end
    local height = 0
    if rows > 0 then
        height = rows * draw + math.max(rows - 1, 0) * gap
    end

    local cells = {}
    for _, n in ipairs(usable) do
        local col = xmap[Round(n.posX)]
        local yRank = ymap[Round(n.posY)]
        local row = diag.yDown and yRank or (rows + 1 - yRank)
        local locked, unmet = NodeGate(n, conditions, opts.spent)
        local rank = tonumber(n.rank) or 0
        local max = tonumber(n.max) or 0
        cells[#cells + 1] = {
            id = n.id,
            col = col,
            row = row,
            x = (col - 1) * (draw + gap),
            y = (row - 1) * (draw + gap),
            w = draw,
            h = draw,
            rank = rank,
            max = max,
            locked = locked and true or false,
            unmet = unmet,
            lockTip = locked and M.LockTip(unmet) or nil,
            state = M.NodeState(rank, max, locked),
            badge = M.Badge(rank, max),
            name = n.name,
            spellID = n.spellID,
            texture = n.texture,
            shape = n.shape or M.Shape(n.entryType),
        }
    end
    table.sort(cells, function(a, b)
        if a.row ~= b.row then return a.row < b.row end
        if a.col ~= b.col then return a.col < b.col end
        return tostring(a.id) < tostring(b.id)
    end)

    local byID = {}
    for _, cell in ipairs(cells) do
        if cell.id ~= nil and not byID[cell.id] then byID[cell.id] = cell end
    end
    local lines, seen = {}, {}
    local function note(srcId, dstId, arrow)
        if not byID[srcId] or not byID[dstId] or dstId == srcId then return end
        local a, b = srcId, dstId
        if tostring(b) < tostring(a) then a, b = b, a end
        local key = tostring(a) .. ":" .. tostring(b)
        local prev = seen[key]
        if not prev then
            seen[key] = { src = srcId, dst = dstId, arrow = arrow and true or false }
        elseif arrow and not prev.arrow then
            prev.src, prev.dst, prev.arrow = srcId, dstId, true
        end
    end
    for _, n in ipairs(usable) do
        if type(n.edges) == "table" then
            for _, e in ipairs(n.edges) do
                local tid, arrow
                if type(e) == "table" then
                    tid = e.targetNode or e.targetNodeID
                    arrow = M.EdgeArrow(e.type)
                else
                    tid = e
                end
                if tid ~= nil then note(n.id, tid, arrow) end
            end
        end
    end
    local keys = {}
    for key in pairs(seen) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local e = seen[key]
        local from, to = byID[e.src], byID[e.dst]
        lines[#lines + 1] = {
            a = e.src, b = e.dst,
            x1 = from.x + draw / 2, y1 = from.y + draw / 2,
            x2 = to.x + draw / 2,   y2 = to.y + draw / 2,
            arrow = e.arrow,
            texture = e.arrow and M.TEX.arrow or M.TEX.edge,
        }
    end

    return {
        nodePx = nodePx,
        drawPx = draw,
        gap = gap,
        scale = scale,
        width = width,
        height = height,
        columns = cols,
        rows = rows,
        yDown = diag.yDown,
        flipped = diag.flipped,
        cells = cells,
        lines = lines,
        linePx = M.LINE_PX,
        gates = diag.gates,
        report = diag.lines,
    }
end

--- One group per tree, in the order the nodes were read. Nodes with no
--- tree id stay together, which is the shape the layout tests build.
function M.GroupByTree(nodes)
    local groups, index = {}, {}
    if type(nodes) ~= "table" then return groups end
    for _, n in ipairs(nodes) do
        local key = false
        if type(n) == "table" and n.treeID ~= nil then key = n.treeID end
        local g = index[key]
        if not g then
            g = {}
            index[key] = g
            groups[#groups + 1] = g
        end
        g[#g + 1] = n
    end
    return groups
end

--- One layout per tree, each from that tree's own coordinates.
function M.Plans(nodes, conditions, opts)
    local plans = {}
    for _, group in ipairs(M.GroupByTree(nodes)) do
        plans[#plans + 1] = M.Layout(group, conditions, opts)
    end
    return plans
end

--- Height and width of the stacked trees. One tree is just its own size.
function M.StackHeight(plans)
    local height, width, n = 0, 0, 0
    if type(plans) ~= "table" then return 0, 0 end
    for _, plan in ipairs(plans) do
        n = n + 1
        if n > 1 then height = height + TREE_GAP end
        height = height + (tonumber(plan.height) or 0)
        local w = tonumber(plan.width) or 0
        if w > width then width = w end
    end
    return height, width
end

--- Pixels left for the tree under the points header. A missing viewport
--- falls back to the content scroll in the 580px frame.
function M.TreeAvail(viewport, headerPx)
    local view = tonumber(viewport)
    if not view or view <= 0 then view = CONTENT_VIEW_FALLBACK end
    local header = tonumber(headerPx) or 0
    if header < 0 then header = 0 end
    local avail = math.floor(view - header)
    if avail < 40 then avail = 40 end
    return avail
end

--- Pane height, and whether the tree has to scroll inside it.
--- Returns pane, scrolls.
function M.TreePane(treeHeight, avail)
    local tree = math.floor(tonumber(treeHeight) or 0)
    if tree < 0 then tree = 0 end
    local room = math.floor(tonumber(avail) or 0)
    if room < 0 then room = 0 end
    if room == 0 or tree <= room then
        return tree, false
    end
    return room, true
end

--- Live tree: one record per node, plus the condition map those nodes cite.
--- Returns nodes, conditions, err, spent, unspent.
function M.ReadGrid()
    local configID = ActiveConfig()
    if not configID then return nil, nil, "no config" end
    if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes) then
        return nil, nil, "traits unavailable"
    end
    local cfg = Try(C_Traits.GetConfigInfo, configID)
    local treeIDs = type(cfg) == "table" and cfg.treeIDs
    if type(treeIDs) ~= "table" or #treeIDs == 0 then
        return nil, nil, "no tree"
    end

    local nodes, conds = {}, {}
    local spent, unspent, sawCurrency = 0, 0, false

    local function learnCondition(cid)
        if conds[cid] or not (C_Traits.GetConditionInfo) then return end
        local ci = Try(C_Traits.GetConditionInfo, configID, cid)
        if type(ci) ~= "table" then
            conds[cid] = {}
            return
        end
        local req = Plain(ci.spentRequired)
        if req == nil then req = Plain(ci.spentAmountRequired) end
        local met = ci.isMet
        if Secret(met) or (met ~= true and met ~= false) then met = nil end
        conds[cid] = { spentRequired = req, isMet = met }
    end

    for _, treeID in ipairs(treeIDs) do
        local list = Try(C_Traits.GetTreeNodes, treeID)
        if type(list) == "table" then
            for _, nodeID in ipairs(list) do
                local info = Try(C_Traits.GetNodeInfo, configID, nodeID)
                if type(info) == "table" then
                    local posX, posY = Plain(info.posX), Plain(info.posY)
                    if posX and posY then
                        local rank = Plain(info.activeRank) or Plain(info.ranksPurchased) or 0
                        local max = Plain(info.maxRanks) or 0
                        spent = spent + rank

                        local entryID = info.activeEntry and not Secret(info.activeEntry) and info.activeEntry.entryID
                        if Secret(entryID) then entryID = nil end
                        if not entryID and type(info.entryIDs) == "table" then
                            entryID = info.entryIDs[1]
                            if Secret(entryID) then entryID = nil end
                        end
                        local name, spellID, texture, entryType
                        if entryID and C_Traits.GetEntryInfo then
                            local entry = Try(C_Traits.GetEntryInfo, configID, entryID)
                            if type(entry) == "table" then
                                entryType = Plain(entry.type)
                                if entry.definitionID and C_Traits.GetDefinitionInfo then
                                    local def = Try(C_Traits.GetDefinitionInfo, entry.definitionID)
                                    if type(def) == "table" then
                                        spellID = Plain(def.spellID)
                                        name = SpellName(spellID) or (def.overrideName and not Secret(def.overrideName) and tostring(def.overrideName))
                                        if spellID and C_Spell and C_Spell.GetSpellTexture then
                                            local tex = Try(C_Spell.GetSpellTexture, spellID)
                                            if tex and not Secret(tex) then texture = tex end
                                        end
                                    end
                                end
                            end
                        end

                        local conditionIDs = {}
                        if type(info.conditionIDs) == "table" then
                            for _, cid in ipairs(info.conditionIDs) do
                                local id = Plain(cid)
                                if id then
                                    conditionIDs[#conditionIDs + 1] = id
                                    learnCondition(id)
                                end
                            end
                        end
                        local edges = {}
                        if type(info.visibleEdges) == "table" then
                            for _, e in ipairs(info.visibleEdges) do
                                if type(e) == "table" then
                                    local tid = Plain(e.targetNode) or Plain(e.targetNodeID)
                                    if tid then
                                        edges[#edges + 1] = {
                                            targetNode = tid,
                                            isActive = (e.isActive == true),
                                            type = Plain(e.type),
                                        }
                                    end
                                else
                                    local tid = Plain(e)
                                    if tid then edges[#edges + 1] = { targetNode = tid } end
                                end
                            end
                        end

                        local id = Plain(nodeID) or nodeID
                        local tid = Plain(treeID) or treeID
                        nodes[#nodes + 1] = {
                            id = id, treeID = tid, posX = posX, posY = posY,
                            rank = rank, max = max,
                            name = name or ("Node " .. tostring(id)),
                            spellID = spellID, texture = texture,
                            entryType = entryType, shape = M.Shape(entryType),
                            conditionIDs = conditionIDs, edges = edges,
                        }
                    end
                end
            end
        end
        local cur = TreeCurrency(configID, treeID)
        if cur then
            unspent = unspent + cur
            sawCurrency = true
        end
    end
    return nodes, conds, nil, spent, sawCurrency and unspent or 0
end

function M.StatusLine()
    local ok, nodes, conds, err = pcall(M.ReadGrid)
    if not ok then return "Talents: grid could not be read" end
    if not nodes then return "Talents: " .. tostring(err or "no tree") end
    local diag = M.Diagnose(nodes, conds)
    local first = diag.lines and diag.lines[1] or "talent grid"
    return "Talents: " .. first .. string.format("; %d gates", #(diag.gates or {}))
end

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderNoTraits(content, y, level)
    y = L:SectionHeader(content, y, "Talents")
    if level and level > 0 and level < TALENT_MIN_LEVEL then
        y = L:Paragraph(content, y, string.format(
            "No talents yet. The first point comes at level %d -- you are level %d, "
            .. "so the trees have not opened. This tab fills in the moment you can "
            .. "spend a point.", TALENT_MIN_LEVEL, level))
        return y
    end
    y = L:Paragraph(content, y,
        "The talent trees could not be read. This client's talent window is the "
        .. "modern trait system, so ToonAge reads C_ClassTalents and C_Traits -- "
        .. "and one of those did not answer here.", { color = L.C_WARNING })
    y = L:Paragraph(content, y,
        "Worth reporting with |cFFFFD100/ta apiprobe|r, which lists exactly which "
        .. "calls this client exposes.")
    return y
end

-- ─── DRAW ──────────────────────────────────────────────────────────────────
-- Frame art is white with alpha. The state colour is a vertex tint. Hover
-- and selection use the focus cut of the same shape plus talent_glow_circle,
-- both in gold. Lines are CreateLine at 2px: talent_edge, or talent_arrow
-- when the edge is a prerequisite.

local function Tint(tex, rgb, alpha)
    if tex and tex.SetVertexColor then
        tex:SetVertexColor(rgb[1], rgb[2], rgb[3], alpha or 1)
    end
end

local function PaintNode(btn)
    local theme = M.Theme
    local rgb = theme[btn.state] or theme.available
    local hot = btn._hover or btn.id == M.selectedID
    local inPlan = (btn._inPlan == true) or ((btn._sandboxDelta or 0) > 0)
    local filterActive = (M.activeFilter ~= nil and M.activeFilter ~= "all")
    local filterMatch = filterActive and (btn._filterDim ~= true)
    local filterDim = (btn._filterDim == true) and not hot
    local dim = (btn.state == "locked" and not hot and not inPlan and not filterMatch) or filterDim
    local alpha = filterDim and 0.22 or (dim and M.LOCK_ALPHA or 1)
    if hot then
        rgb = M.FocusColor()
    elseif inPlan or filterMatch then
        rgb = M.PlanRouteColor()
    end
    if btn.frame and btn.frame.SetTexture then
        btn.frame:SetTexture(M.FrameFile(btn.shape, hot, btn._px))
        Tint(btn.frame, rgb, alpha)
    end
    if btn.glow then
        if hot then
            Tint(btn.glow.tex, rgb, 1)
            btn.glow:Show()
        else
            btn.glow:Hide()
        end
    end
    Tint(btn.badgeFill, rgb, alpha)
    Tint(btn.badgeBorder, rgb, alpha)
    if btn.icon then
        btn.icon:SetAlpha(alpha)
        if btn.icon.SetDesaturated then
            btn.icon:SetDesaturated((btn.state == "locked" and not inPlan and not filterMatch) or filterDim)
        end
    end
    if btn.lock then
        if btn._locked then btn.lock:Show() else btn.lock:Hide() end
    end
end

-- CreateFramePool is not on this client. Data/Forever/ApiManifest.lua does
-- not list it, and Core/Compat/API.lua does not shim it. The self-test
-- (TestHarness.lua CountDescendants) treats a frame with _laKind as reused.
-- A hidden anchor holds the idle nodes so the next render of this tab takes
-- them back instead of allocating another grid. One button and one glow per
-- node, plus a holder per tree, is the 112-frame leak on a 52-node window.
local gridFree = { holder = {}, button = {}, glow = {} }
local gridLive = { holder = {}, button = {}, glow = {} }
local gridAnchor

local function GridAnchor()
    if gridAnchor then return gridAnchor end
    gridAnchor = CreateFrame("Frame")
    gridAnchor:Hide()
    return gridAnchor
end

local function GridTake(kind, parent, build)
    local free = gridFree[kind]
    local f = free and table.remove(free)
    if not f then
        f = build()
        f._laKind = "ForeverTalent"
    end
    if f.SetParent then f:SetParent(parent) end
    if f.ClearAllPoints then f:ClearAllPoints() end
    if f.Show then f:Show() end
    local live = gridLive[kind]
    live[#live + 1] = f
    return f
end

local function GridReclaim()
    local anchor = GridAnchor()
    for kind, live in pairs(gridLive) do
        local free = gridFree[kind]
        for i = #live, 1, -1 do
            local f = live[i]
            live[i] = nil
            if f.Hide then f:Hide() end
            if f.ClearAllPoints then f:ClearAllPoints() end
            if f.SetScript then
                f:SetScript("OnEnter", nil)
                f:SetScript("OnLeave", nil)
                if kind == "button" then
                    f:SetScript("OnClick", nil)
                end
            end
            if f.SetParent then f:SetParent(anchor) end
            free[#free + 1] = f
        end
    end
end

local DOCK_H_BASIC = 84
local DOCK_H_INTEL = 132
local FILTER_BAR_H = 26

local function UpdateButtonBadge(btn, cell, route, unspent, unlockLv, playerLevel)
    local TI = TA.TalentIntel
    local sbDelta = (TI and TI.SandboxDelta) and TI.SandboxDelta(cell.id) or 0
    local projRank, projDelta = M.WhatIfRank(cell, route, unspent)
    if sbDelta > 0 then
        local base = tonumber(cell.rank) or 0
        local max = tonumber(cell.max) or 1
        projRank = math.min(max, base + sbDelta)
        projDelta = projRank - base
    end
    local dispBadge = cell.badge
    local isLevelBadge = false
    if projDelta > 0 then
        dispBadge = M.Badge(projRank, cell.max) or ("+" .. tostring(projDelta))
    elseif not dispBadge and cell.locked and unlockLv and playerLevel and unlockLv > playerLevel then
        dispBadge = "L" .. tostring(unlockLv)
        isLevelBadge = true
    end
    btn._projRank = projRank
    btn._projDelta = projDelta
    btn._sandboxDelta = sbDelta
    btn._unlockLv = unlockLv
    if dispBadge then
        local bw = math.min(24, math.max(12, math.floor(cell.w * 0.60)))
        local bh = math.min(12, math.max(8, math.floor(cell.h * 0.32)))
        if not btn.badgeFill then
            btn.badgeFill = btn:CreateTexture(nil, "OVERLAY")
            btn.badgeBorder = btn:CreateTexture(nil, "OVERLAY")
            btn.badgeText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        end
        local fill = btn.badgeFill
        fill:Show()
        fill:ClearAllPoints()
        fill:SetSize(bw, bh)
        fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        fill:SetTexture(M.TEX.badgeFill)
        local border = btn.badgeBorder
        border:Show()
        border:ClearAllPoints()
        border:SetAllPoints(fill)
        border:SetTexture(M.TEX.badgeBorder)
        local badge = btn.badgeText
        badge:Show()
        badge:ClearAllPoints()
        badge:SetPoint("CENTER", fill, "CENTER", 0, 0)
        badge:SetText(dispBadge)
        if projDelta > 0 then
            local hi = M.Theme.highlight
            badge:SetTextColor(hi[1], hi[2], hi[3], 1)
        elseif isLevelBadge then
            badge:SetTextColor(0.75, 0.82, 0.90, 1)
        else
            badge:SetTextColor(1, 1, 1, 1)
        end
    elseif btn.badgeFill then
        btn.badgeFill:Hide()
        btn.badgeBorder:Hide()
        btn.badgeText:Hide()
    end
end

local function TintEdge(line, ln, route)
    local planned = route and route.inPathEdge
        and (route.inPathEdge[tostring(ln.a) .. ":" .. tostring(ln.b)] == true)
    if planned then
        Tint(line, M.PlanRouteColor(), 0.95)
    else
        Tint(line, M.Theme.line, M.Theme.line[4])
    end
end

local function DrawGrid(parent, y, plan, pad, route, unspent, onSelect, allButtons, allLines, intelCtx)
    local holder = GridTake("holder", parent, function()
        return CreateFrame("Frame", nil, parent)
    end)
    local width  = math.max(1, math.floor(plan.width + 0.5))
    local height = math.max(1, math.floor(plan.height + 0.5))
    holder:SetSize(width, height)
    -- 0 is a real inset. Only a missing pad uses the content margin.
    if pad == nil then pad = L.PAD end
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", pad, y)

    local TI = TA.TalentIntel
    local buttons = {}
    for _, cell in ipairs(plan.cells) do
        local btn = GridTake("button", holder, function()
            local b = CreateFrame("Button", nil, holder)
            if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
            b.frame = b:CreateTexture(nil, "BORDER")
            b.frame:SetAllPoints()
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.lock = b:CreateTexture(nil, "OVERLAY")
            b.lock:SetTexture(M.LOCK_TEXTURE)
            return b
        end)
        btn:SetSize(math.floor(cell.w), math.floor(cell.h))
        btn:SetPoint("TOPLEFT", holder, "TOPLEFT", math.floor(cell.x), -math.floor(cell.y))
        btn.id = cell.id
        btn.state = cell.state
        btn.shape = cell.shape
        btn._px = cell.w
        btn._locked = cell.locked
        btn._hover = false
        btn._cell = cell
        btn._inPlan = (route and route.inPath and route.inPath[cell.id] ~= nil) or false
        local unlockLv = intelCtx and intelCtx.unlockByID and intelCtx.unlockByID[cell.id] or nil
        local nodeDesc = intelCtx and intelCtx.descByID and intelCtx.descByID[cell.id] or ""
        local filterKey = M.activeFilter or "all"
        btn._filterDim = (TI and filterKey ~= "all")
            and (not TI.NodeMatchesFilter(cell, nodeDesc, filterKey)) or false
        -- A reused node may still be at the raised hover level. Keep the
        -- level it had when it was first built.
        if not btn._taHomeLevel then
            btn._taHomeLevel = btn:GetFrameLevel() or 1
        end
        btn._baseLevel = btn._taHomeLevel
        if btn.frame.SetAllPoints then btn.frame:SetAllPoints() end

        local inset = math.max(2, math.floor(cell.w * 0.12))
        local icon = btn.icon
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
        if cell.texture then
            icon:SetTexture(cell.texture)
        else
            icon:SetColorTexture(0.08, 0.08, 0.09, 1)
        end

        -- talent_glow_circle sits under this node. Hover lifts the node and
        -- the glow above the neighbours; the glow stays one level behind
        -- its own button so it does not cover the icon.
        local glow = GridTake("glow", holder, function()
            local g = CreateFrame("Frame", nil, holder)
            g.tex = g:CreateTexture(nil, "BACKGROUND")
            g.tex:SetAllPoints()
            return g
        end)
        glow:SetPoint("TOPLEFT", btn, "TOPLEFT", -M.GLOW_OUTSET, M.GLOW_OUTSET)
        glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", M.GLOW_OUTSET, -M.GLOW_OUTSET)
        glow:EnableMouse(false)
        local gtex = glow.tex
        gtex:SetTexture(M.TEX.glow)
        Tint(gtex, M.FocusColor(), 1)
        if gtex.SetBlendMode then gtex:SetBlendMode("ADD") end
        glow:Hide()
        btn.glow = glow

        UpdateButtonBadge(btn, cell, route, unspent, unlockLv, intelCtx and intelCtx.playerLevel)

        -- One lock per gated talent. The row used to carry a single "N pts"
        -- label; the requirement now belongs to the node it gates.
        local lock = btn.lock
        local lockPx = math.min(16, math.max(10, math.floor(cell.w * 0.4)))
        lock:ClearAllPoints()
        lock:SetSize(lockPx, lockPx)
        lock:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        lock:SetTexture(M.LOCK_TEXTURE)
        lock:Hide()

        -- The glow sits one level under its own node, so the ring and icon
        -- stay visible. Hover lifts both above the other nodes; leave puts
        -- them back.
        local function levels(buttonLevel)
            buttonLevel = math.max(buttonLevel or 1, 1)
            btn:SetFrameLevel(buttonLevel)
            glow:SetFrameLevel(buttonLevel - 1)
        end
        levels(btn._baseLevel)
        local function raise()
            levels((holder:GetFrameLevel() or 0) + 20)
        end
        local function restore()
            levels(btn._baseLevel)
        end

        btn:SetScript("OnEnter", function(self)
            self._hover = true
            raise()
            PaintNode(self)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(cell.name or "Talent")
                if cell.badge then GameTooltip:AddLine(cell.badge, 1, 1, 1) end
                if (self._projDelta or 0) > 0 then
                    local pc = M.PlanRouteColor()
                    local modeTag = ((self._sandboxDelta or 0) > 0) and "Sandbox" or "What-If preview"
                    GameTooltip:AddLine(
                        string.format("%s: %d/%d (not spent)", modeTag, self._projRank, cell.max),
                        pc[1], pc[2], pc[3])
                end
                if cell.lockTip then
                    GameTooltip:AddLine(cell.lockTip, 0.85, 0.75, 0.45)
                end
                if self._unlockLv and intelCtx and intelCtx.playerLevel and self._unlockLv > intelCtx.playerLevel then
                    GameTooltip:AddLine(string.format("Unlockable at Level %d", self._unlockLv), 0.55, 0.78, 0.96)
                end
                if nodeDesc ~= "" then
                    GameTooltip:AddLine(nodeDesc, 0.82, 0.85, 0.88, true)
                end
                if M.sandboxEnabled then
                    GameTooltip:AddLine("Sandbox: Shift-Click +1 · Right-Click -1", 0.58, 0.65, 0.72)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self._hover = false
            restore()
            PaintNode(self)
            if GameTooltip then GameTooltip:Hide() end
        end)
        btn:SetScript("OnClick", function(self, mouseBtn)
            if M.sandboxEnabled and TI and intelCtx then
                if mouseBtn == "RightButton" then
                    M.selectedID = self.id
                    TI.SandboxRemove(self.id)
                    if onSelect then onSelect() end
                    return
                elseif IsShiftKeyDown and IsShiftKeyDown() then
                    M.selectedID = self.id
                    TI.SandboxAdd(cell, intelCtx.nodes, intelCtx.spent)
                    if onSelect then onSelect() end
                    return
                end
            end
            if M.selectedID == self.id then M.selectedID = nil else M.selectedID = self.id end
            for _, other in pairs(buttons) do PaintNode(other) end
            if onSelect then onSelect() end
        end)
        PaintNode(btn)
        buttons[cell.id] = btn
        if allButtons then allButtons[#allButtons + 1] = btn end
    end

    -- Lines sit under the nodes and use the node's own center, so a resize
    -- of the button still meets in the middle. Thickness stays 2px.
    -- The holder is pooled, so lines built on it stay and are restyled.
    holder._taLines = holder._taLines or {}
    local usedLines = 0
    if holder.CreateLine then
        for _, ln in ipairs(plan.lines) do
            local a, b = buttons[ln.a], buttons[ln.b]
            if a and b then
                usedLines = usedLines + 1
                local line = holder._taLines[usedLines]
                if not line then
                    local ok, created = pcall(holder.CreateLine, holder, nil, "BACKGROUND")
                    if ok and created then
                        line = created
                        holder._taLines[usedLines] = line
                    end
                end
                if line then
                    if line.Show then line:Show() end
                    pcall(function()
                        line:SetThickness(M.LINE_PX)
                        if line.SetTexture then
                            line:SetTexture(ln.texture or M.TEX.edge)
                        end
                        TintEdge(line, ln, route)
                        line:SetStartPoint("CENTER", a)
                        line:SetEndPoint("CENTER", b)
                    end)
                    if allLines then allLines[#allLines + 1] = { line = line, ln = ln } end
                end
            end
        end
    end
    for i = usedLines + 1, #holder._taLines do
        local extra = holder._taLines[i]
        if extra and extra.Hide then extra:Hide() end
    end

    return y - height - 8
end

local function ViewportHeight(content)
    local view = 0
    if content and content.GetParent then
        local parent = content:GetParent()
        if parent and parent.GetHeight then
            view = tonumber(parent:GetHeight()) or 0
        end
    end
    if view <= 0 and TA.UI and TA.UI.frame and TA.UI.frame.contentScroll
        and TA.UI.frame.contentScroll.GetHeight then
        view = tonumber(TA.UI.frame.contentScroll:GetHeight()) or 0
    end
    return view
end

--- Wheel the tree. The template's own handler moves the bar when it has one.
local function Wheel(self, delta)
    local bar = self.ScrollBar
    if bar and bar.SetValue and bar.GetValue and (not bar.IsVisible or bar:IsVisible()) then
        local step = 24
        if bar.GetHeight then
            local h = tonumber(bar:GetHeight())
            if h and h > 0 then step = h / 2 end
        end
        local val = (tonumber(bar:GetValue()) or 0) - (tonumber(delta) or 0) * step
        local minV, maxV = 0, 0
        if bar.GetMinMaxValues then minV, maxV = bar:GetMinMaxValues() end
        minV = tonumber(minV) or 0
        maxV = tonumber(maxV) or 0
        if val < minV then val = minV end
        if val > maxV then val = maxV end
        bar:SetValue(val)
        return
    end
    local cur = (self.GetVerticalScroll and tonumber(self:GetVerticalScroll())) or 0
    local maxScroll = (self.GetVerticalScrollRange and tonumber(self:GetVerticalScrollRange())) or 0
    local nxt = cur - (tonumber(delta) or 0) * 48
    if nxt < 0 then nxt = 0 end
    if nxt > maxScroll then nxt = maxScroll end
    if self.SetVerticalScroll then self:SetVerticalScroll(nxt) end
end

--- The points header is not a child of this frame. The scroll child is as
--- tall as the trees; the frame itself is only as tall as the pane.
local function MountTree(content, y, plans, paneH, treeH, treeW, route, unspent, onSelect, intelCtx)
    -- The anchor is created on the first mount so a later redraw does not
    -- allocate it. Reclaim runs before the grids are drawn again.
    GridAnchor()
    local scroll = _G.TATalentTreeScroll
    if scroll and scroll.SetParent then
        scroll:SetParent(content)
        if scroll.Show then scroll:Show() end
    else
        scroll = CreateFrame("ScrollFrame", "TATalentTreeScroll", content, "UIPanelScrollFrameTemplate")
    end
    -- The template's scrollbar is parented here. Marking the scroll skips
    -- that whole subtree in the self-test, and the frame itself is reused.
    scroll._laKind = "ForeverTalent"
    if scroll.ClearAllPoints then scroll:ClearAllPoints() end
    scroll:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, y)
    scroll:SetSize(math.max(1, L:Width(content)), math.max(1, math.floor(paneH + 0.5)))
    if scroll.EnableMouseWheel then scroll:EnableMouseWheel(true) end

    -- Wrap the template handler once. A later refresh must not nest it.
    if not scroll._taWheelHooked then
        scroll._taWheel = (scroll.GetScript and scroll:GetScript("OnMouseWheel")) or false
        scroll._taWheelHooked = true
        scroll:SetScript("OnMouseWheel", function(self, delta)
            if self._taWheel then self._taWheel(self, delta) else Wheel(self, delta) end
        end)
    end
    if not scroll._taVertHooked then
        scroll._taVert = (scroll.GetScript and scroll:GetScript("OnVerticalScroll")) or false
        scroll._taVertHooked = true
        scroll:SetScript("OnVerticalScroll", function(self, offset)
            M._treeScroll = offset
            if self._taVert then self._taVert(self, offset) end
        end)
    end

    local child = scroll.GetScrollChild and scroll:GetScrollChild()
    if not (child and child.SetSize) then
        child = CreateFrame("Frame", nil, scroll)
    end
    child._laKind = "ForeverTalent"
    if child.SetParent then child:SetParent(scroll) end
    if child.Show then child:Show() end
    local cw = math.max(1, math.floor((tonumber(treeW) or 1) + 0.5))
    local ch = math.max(1, math.floor((tonumber(treeH) or 1) + 0.5))
    child:SetSize(cw, ch)
    if scroll.SetScrollChild then scroll:SetScrollChild(child) end
    GridReclaim()

    local allButtons, allLines = {}, {}
    local yOff = 0
    for _, plan in ipairs(plans) do
        DrawGrid(child, yOff, plan, 0, route, unspent, onSelect, allButtons, allLines, intelCtx)
        yOff = yOff - (tonumber(plan.height) or 0) - TREE_GAP
    end

    local keep = tonumber(M._treeScroll) or 0
    local maxScroll = ch - math.floor(paneH + 0.5)
    if maxScroll < 0 then maxScroll = 0 end
    if keep < 0 then keep = 0 end
    if keep > maxScroll then keep = maxScroll end
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(keep) end
    return scroll, allButtons, allLines
end

local function FormatLinkNames(list, withRank)
    if type(list) ~= "table" or #list == 0 then return "none" end
    local parts = {}
    local limit = math.min(#list, 3)
    for i = 1, limit do
        local item = list[i]
        if withRank and item.rank ~= nil and item.max ~= nil then
            parts[i] = string.format("%s (%d/%d)", tostring(item.name), item.rank, item.max)
        else
            parts[i] = tostring(item.name)
        end
    end
    if #list > limit then
        parts[#parts + 1] = string.format("+%d more", #list - limit)
    end
    return table.concat(parts, ", ")
end

local function BuildDockButton(dock)
    local btn = CreateFrame("Button", nil, dock)
    btn._laKind = "ForeverTalent"
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bar = btn:CreateTexture(nil, "BORDER")
    btn.bar:SetHeight(1)
    btn.bar:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.bar:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    return btn
end

local function StyleDockButton(btn, text, active)
    local accent = active and M.PlanRouteColor() or M.FocusColor()
    if btn.bg and btn.bg.SetColorTexture then
        if active then
            btn.bg:SetColorTexture(accent[1] * 0.22, accent[2] * 0.22, accent[3] * 0.22, 0.94)
        else
            btn.bg:SetColorTexture(0.08, 0.11, 0.16, 0.94)
        end
    end
    if btn.bar and btn.bar.SetColorTexture then
        btn.bar:SetColorTexture(accent[1], accent[2], accent[3], active and 0.95 or 0.55)
    end
    if btn.label then
        btn.label:SetText(text)
        btn.label:SetTextColor(0.95, 0.97, 0.99, 1)
    end
end

local FILTER_WHY_H = 44

--- Pooled Spell & Playstyle Filter Pills + Saved Plan Slot selector bar
--- + inline "Why this filter?" explanation & Plan Next option strip.
--- Mounted only when TA.TalentIntel is loaded. 0 frame churn on redraw.
local function MountFilterBar(content, yTop, width, pills, refreshFn, nodes, intelCtx)
    local TI = TA.TalentIntel
    local bar = _G.TATalentFilterBar
    if not (TI and type(pills) == "table" and #pills > 0) then
        if bar and bar.Hide then bar:Hide() end
        return 0
    end
    if not bar then
        bar = CreateFrame("Frame", "TATalentFilterBar", content)
        bar._laKind = "ForeverTalent"
        bar._pills = {}
        bar.slotBtn = BuildDockButton(bar)
        bar.slotBtn:SetSize(78, 20)
        bar.slotBtn:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -3)

        -- Pooled "Why this filter?" strip right under the pills (hidden on All)
        local whyBar = CreateFrame("Frame", nil, bar)
        whyBar._laKind = "ForeverTalent"
        whyBar:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -(FILTER_BAR_H + 2))
        whyBar:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -(FILTER_BAR_H + 2))
        whyBar:SetHeight(FILTER_WHY_H)
        whyBar.bg = whyBar:CreateTexture(nil, "BACKGROUND")
        whyBar.bg:SetAllPoints()
        whyBar.bg:SetColorTexture(0.06, 0.09, 0.14, 0.88)
        whyBar.rule = whyBar:CreateTexture(nil, "BORDER")
        whyBar.rule:SetHeight(1)
        whyBar.rule:SetPoint("TOPLEFT")
        whyBar.rule:SetPoint("TOPRIGHT")
        whyBar.rule:SetColorTexture(0.32, 0.72, 0.96, 0.55)

        whyBar.title = whyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        whyBar.title:SetPoint("TOPLEFT", whyBar, "TOPLEFT", 8, -5)
        if whyBar.title.SetJustifyH then whyBar.title:SetJustifyH("LEFT") end

        whyBar.desc = whyBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        whyBar.desc:SetPoint("TOPLEFT", whyBar, "TOPLEFT", 8, -19)
        whyBar.desc:SetPoint("BOTTOMRIGHT", whyBar, "BOTTOMRIGHT", -226, 4)
        if whyBar.desc.SetJustifyH then whyBar.desc:SetJustifyH("LEFT") end
        if whyBar.desc.SetWordWrap then whyBar.desc:SetWordWrap(true) end

        whyBar.clearBtn = BuildDockButton(whyBar)
        whyBar.clearBtn:SetSize(48, 20)
        whyBar.clearBtn:SetPoint("RIGHT", whyBar, "RIGHT", -6, 0)

        whyBar.planBtn = BuildDockButton(whyBar)
        whyBar.planBtn:SetSize(82, 20)
        whyBar.planBtn:SetPoint("RIGHT", whyBar.clearBtn, "LEFT", -4, 0)

        whyBar.inspectBtn = BuildDockButton(whyBar)
        whyBar.inspectBtn:SetSize(82, 20)
        whyBar.inspectBtn:SetPoint("RIGHT", whyBar.planBtn, "LEFT", -4, 0)

        whyBar:Hide()
        bar._whyBar = whyBar
    end
    bar._laKind = "ForeverTalent"
    if bar.SetParent then bar:SetParent(content) end
    if bar.ClearAllPoints then bar:ClearAllPoints() end
    local activeKey = M.activeFilter or "all"
    local showWhy = (activeKey ~= "all") and (type(TI.FilterInfo) == "function")
    local totalH = showWhy and (FILTER_BAR_H + FILTER_WHY_H + 4) or FILTER_BAR_H
    local barW = math.max(220, math.floor((tonumber(width) or 480) + 0.5))
    bar:SetSize(barW, totalH)
    bar:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, yTop)
    if bar.Show then bar:Show() end

    -- Saved Plan slot cycler on the right edge (Solo / Dungeon / PvP)
    local _, slotName = TI.ActiveSlot()
    StyleDockButton(bar.slotBtn, "Plan: " .. tostring(slotName or "Solo"), false)
    bar.slotBtn:SetScript("OnClick", function()
        local newSlot = TI.CycleSlot()
        M.planTargetID = (newSlot and newSlot.targets and newSlot.targets[#newSlot.targets]) or nil
        if refreshFn then refreshFn() end
    end)

    local descByID = intelCtx and intelCtx.descByID or nil
    local maxX = barW - 84
    local curX = 0
    local used = 0
    for _, pill in ipairs(pills) do
        local labelTxt = pill.label
        local approxW = math.max(36, math.min(96, (#labelTxt * 6) + 14))
        if curX + approxW <= maxX then
            used = used + 1
            local btn = bar._pills[used]
            if not btn then
                btn = BuildDockButton(bar)
                bar._pills[used] = btn
            end
            btn._laKind = "ForeverTalent"
            if btn.ClearAllPoints then btn:ClearAllPoints() end
            btn:SetSize(approxW, 20)
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", curX, -3)
            local isActive = activeKey == pill.key
            StyleDockButton(btn, labelTxt, isActive)
            local pKey = pill.key
            btn:SetScript("OnClick", function()
                local wasAll = (M.activeFilter == nil or M.activeFilter == "all")
                if M.activeFilter == pKey and pKey ~= "all" then
                    M.activeFilter = "all"
                else
                    M.activeFilter = pKey
                end
                local nowAll = (M.activeFilter == nil or M.activeFilter == "all")
                if refreshFn then refreshFn() end
                if wasAll ~= nowAll and TA.QueueUIRefresh then
                    TA:QueueUIRefresh("TALENT_FILTER")
                end
            end)
            if btn.SetScript then
                btn:SetScript("OnEnter", function(self)
                    if not (GameTooltip and TI.FilterInfo) then return end
                    local fInfo = TI.FilterInfo(pKey, nodes, descByID)
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(fInfo.title .. " (" .. tostring(fInfo.matchCount) .. " talents)", 1, 0.85, 0.3, false)
                    GameTooltip:AddLine(fInfo.why, 0.92, 0.92, 0.95, true)
                    GameTooltip:AddLine("Click to highlight matching nodes & show Plan options.", 0.60, 0.72, 0.85, true)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function()
                    if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
                end)
            end
            if btn.Show then btn:Show() end
            curX = curX + approxW + 4
        end
    end
    for i = used + 1, #bar._pills do
        if bar._pills[i] and bar._pills[i].Hide then bar._pills[i]:Hide() end
    end

    local whyBar = bar._whyBar
    if whyBar then
        if showWhy then
            local info = TI.FilterInfo(activeKey, nodes, descByID)
            local nextNode = info.firstUnmaxed
            whyBar.title:SetText(string.format("%s · %d matching (%d unmaxed)",
                tostring(info.title), info.matchCount or 0, info.unmaxedCount or 0))
            whyBar.desc:SetText(info.why or "")
            StyleDockButton(whyBar.clearBtn, "Clear", false)
            whyBar.clearBtn:SetScript("OnClick", function()
                M.activeFilter = "all"
                if refreshFn then refreshFn() end
                if TA.QueueUIRefresh then TA:QueueUIRefresh("TALENT_FILTER") end
            end)
            if nextNode then
                StyleDockButton(whyBar.inspectBtn, "Inspect Next", false)
                whyBar.inspectBtn:SetScript("OnClick", function()
                    M.selectedID = nextNode.id
                    if refreshFn then refreshFn() end
                end)
                whyBar.inspectBtn:Show()

                local alreadyPlanned = TI.HasMilestone and TI.HasMilestone(nextNode.id) or false
                StyleDockButton(whyBar.planBtn, alreadyPlanned and "Planned" or "+Plan Next", alreadyPlanned)
                whyBar.planBtn:SetScript("OnClick", function()
                    M.selectedID = nextNode.id
                    if TI.ToggleMilestone then TI.ToggleMilestone(nextNode.id) end
                    M.planTargetID = nextNode.id
                    if refreshFn then refreshFn() end
                end)
                whyBar.planBtn:Show()
            else
                whyBar.inspectBtn:Hide()
                whyBar.planBtn:Hide()
            end
            whyBar:Show()
        else
            whyBar:Hide()
        end
    end
    return totalH
end

--- Pooled bottom Node Detail, Sandbox Plan Mode & Reality Callouts dock.
--- Hidden when neither a node nor a plan target/milestone/sandbox is active.
local function MountDetailDock(content, yTop, width, nodes, conds, spent, unspent, refreshFn, intelCtx)
    local TI = TA.TalentIntel
    local slot, slotName
    if TI and TI.ActiveSlot then slot, slotName = TI.ActiveSlot() end
    local hasMilestones = slot and type(slot.targets) == "table" and #slot.targets > 0
    local firstMilestone = hasMilestones and slot.targets[1] or nil
    local activeID = M.selectedID or M.planTargetID or firstMilestone
    local dock = _G.TATalentDetailDock
    if activeID == nil then
        if dock and dock.Hide then dock:Hide() end
        return 0
    end
    local detail = M.NodeDetail(nodes, conds, activeID, spent)
    if not detail then
        if dock and dock.Hide then dock:Hide() end
        return 0
    end

    local dockH = TI and DOCK_H_INTEL or DOCK_H_BASIC

    if not dock then
        dock = CreateFrame("Frame", "TATalentDetailDock", content)
        dock._laKind = "ForeverTalent"
        dock.bg = dock:CreateTexture(nil, "BACKGROUND")
        dock.bg:SetAllPoints()
        dock.topRule = dock:CreateTexture(nil, "BORDER")
        dock.topRule:SetHeight(1)
        dock.topRule:SetPoint("TOPLEFT", dock, "TOPLEFT", 0, 0)
        dock.topRule:SetPoint("TOPRIGHT", dock, "TOPRIGHT", 0, 0)
        dock.title = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dock.title:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -8)
        dock.meta = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dock.meta:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -25)
        dock.planLine = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dock.planLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -42)
        dock.mathLine = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dock.mathLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -60)
        dock.castsLine = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dock.castsLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -77)
        dock.gearLine = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dock.gearLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -94)
        dock.noteLine = dock:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        dock.noteLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -112)

        dock.planBtn = BuildDockButton(dock)
        dock.planBtn:SetSize(112, 22)
        dock.planBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -10, -8)

        dock.whatIfBtn = BuildDockButton(dock)
        dock.whatIfBtn:SetSize(112, 22)
        dock.whatIfBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -10, -34)

        dock.sandboxBtn = BuildDockButton(dock)
        dock.sandboxBtn:SetSize(112, 22)
        dock.sandboxBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -10, -60)

        dock.plusBtn = BuildDockButton(dock)
        dock.plusBtn:SetSize(34, 20)
        dock.plusBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -88, -86)

        dock.minusBtn = BuildDockButton(dock)
        dock.minusBtn:SetSize(34, 20)
        dock.minusBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -50, -86)

        dock.clearBtn = BuildDockButton(dock)
        dock.clearBtn:SetSize(36, 20)
        dock.clearBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -10, -86)
    end

    dock._laKind = "ForeverTalent"
    if dock.SetParent then dock:SetParent(content) end
    if dock.ClearAllPoints then dock:ClearAllPoints() end
    local dockW = math.max(220, math.floor((tonumber(width) or 480) + 0.5))
    dock:SetSize(dockW, dockH)
    dock:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, yTop)
    if dock.Show then dock:Show() end

    local cardBg = TA.Theme and TA.Theme.active and TA.Theme.active.bg and TA.Theme.active.bg.card
    if dock.bg and dock.bg.SetColorTexture then
        if type(cardBg) == "table" and cardBg[1] then
            dock.bg:SetColorTexture(cardBg[1], cardBg[2], cardBg[3], cardBg[4] or 0.96)
        else
            dock.bg:SetColorTexture(0.06, 0.08, 0.11, 0.96)
        end
    end
    local hasAnyPlan = (M.planTargetID ~= nil) or hasMilestones or M.sandboxEnabled
    local ruleColor = hasAnyPlan and M.PlanRouteColor() or M.FocusColor()
    if dock.topRule and dock.topRule.SetColorTexture then
        dock.topRule:SetColorTexture(ruleColor[1], ruleColor[2], ruleColor[3], 0.85)
    end

    local textW = math.max(120, dockW - 140)
    for _, fs in ipairs({ dock.title, dock.meta, dock.planLine, dock.mathLine, dock.castsLine, dock.gearLine, dock.noteLine }) do
        if fs and fs.SetWidth then fs:SetWidth(textW) end
        if fs and fs.SetJustifyH then fs:SetJustifyH("LEFT") end
        if fs and fs.SetWordWrap then fs:SetWordWrap(false) end
    end

    local unlockLv = intelCtx and intelCtx.unlockByID and intelCtx.unlockByID[detail.id] or nil
    local titleStr = string.format("%s (%d/%d)", detail.name, detail.rank, detail.max)
    if detail.lockTip then
        titleStr = titleStr .. " · " .. detail.lockTip
    end
    if unlockLv and intelCtx and intelCtx.playerLevel and unlockLv > intelCtx.playerLevel then
        titleStr = titleStr .. string.format(" (Lv %d)", unlockLv)
    end
    local isMilestone = TI and TI.HasMilestone and TI.HasMilestone(detail.id)
    local isTarget = (M.planTargetID == detail.id) or isMilestone
    if isTarget then
        titleStr = titleStr .. (TI and " [Milestone]" or " [Plan Target]")
    end
    dock.title:SetText(titleStr)
    dock.title:SetTextColor(0.95, 0.97, 0.99, 1)

    local metaStr = string.format("Prereqs: %s  |  Unlocks: %s",
        FormatLinkNames(detail.prereqs, true),
        FormatLinkNames(detail.unlocks, false))
    dock.meta:SetText(metaStr)
    dock.meta:SetTextColor(0.75, 0.80, 0.86, 1)

    local nextInfo = M.GetNextPlannedPoint(nodes, conds, spent, unspent)
    dock.planLine:SetText(nextInfo.summary or "")
    dock.planLine:SetTextColor(ruleColor[1], ruleColor[2], ruleColor[3], 1)

    if TI then
        local desc = (intelCtx and intelCtx.descByID and intelCtx.descByID[detail.id])
            or TI.ReadSpellDesc(detail.spellID)
        local mathInfo = TI.SpellMath(detail, desc)
        local castText = TI.CastReality(detail, desc, intelCtx and intelCtx.castStats)
        local gearText = TI.GearReality(detail, desc, intelCtx and intelCtx.gearStats, intelCtx and intelCtx.playerLevel)

        dock.mathLine:SetText(mathInfo.text or "")
        dock.mathLine:SetTextColor(0.96, 0.88, 0.56, 1)
        dock.mathLine:Show()

        dock.castsLine:SetText(castText or "")
        dock.castsLine:SetTextColor(0.72, 0.85, 0.94, 1)
        dock.castsLine:Show()

        dock.gearLine:SetText(gearText or "")
        dock.gearLine:SetTextColor(0.68, 0.88, 0.74, 1)
        dock.gearLine:Show()

        dock.noteLine:ClearAllPoints()
        dock.noteLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -112)
        local sbTotals = TI.SandboxTotals(nodes, spent, intelCtx and intelCtx.playerLevel)
        if sbTotals.added > 0 then
            dock.noteLine:SetText(string.format("[%s] Sandbox: +%d pts -> %d/51 (Lv %d build) · %s",
                tostring(slotName or "Solo"), sbTotals.added, sbTotals.totalSpent, sbTotals.buildLevel, PLAN_HONEST_NOTE))
        else
            dock.noteLine:SetText(PLAN_HONEST_NOTE)
        end
        dock.noteLine:SetTextColor(0.56, 0.62, 0.70, 1)

        dock.sandboxBtn:Show()
        dock.plusBtn:Show()
        dock.minusBtn:Show()
        dock.clearBtn:Show()

        StyleDockButton(dock.sandboxBtn, M.sandboxEnabled and "Sandbox: ON" or "Sandbox: OFF", M.sandboxEnabled)
        dock.sandboxBtn:SetScript("OnClick", function()
            M.sandboxEnabled = not M.sandboxEnabled
            if refreshFn then refreshFn() end
        end)

        StyleDockButton(dock.plusBtn, "+1", (TI.SandboxDelta(detail.id) or 0) > 0)
        dock.plusBtn:SetScript("OnClick", function()
            M.sandboxEnabled = true
            TI.SandboxAdd(detail, nodes, spent)
            if refreshFn then refreshFn() end
        end)

        StyleDockButton(dock.minusBtn, "-1", false)
        dock.minusBtn:SetScript("OnClick", function()
            TI.SandboxRemove(detail.id)
            if refreshFn then refreshFn() end
        end)

        StyleDockButton(dock.clearBtn, "Clr", false)
        dock.clearBtn:SetScript("OnClick", function()
            M.planTargetID = nil
            TI.ClearMilestones()
            TI.SandboxClear()
            if refreshFn then refreshFn() end
        end)
    else
        dock.mathLine:Hide()
        dock.castsLine:Hide()
        dock.gearLine:Hide()
        dock.sandboxBtn:Hide()
        dock.plusBtn:Hide()
        dock.minusBtn:Hide()
        dock.clearBtn:Hide()
        dock.noteLine:ClearAllPoints()
        dock.noteLine:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -64)
        dock.noteLine:SetText(PLAN_HONEST_NOTE)
        dock.noteLine:SetTextColor(0.56, 0.62, 0.70, 1)
    end

    local planBtnLabel
    if TI then
        if isTarget then
            planBtnLabel = "Unpin Milestone"
        elseif hasMilestones then
            planBtnLabel = "Add Milestone"
        else
            planBtnLabel = "Pin Milestone"
        end
    else
        planBtnLabel = isTarget and "Clear Target" or "Set Plan Target"
    end
    StyleDockButton(dock.planBtn, planBtnLabel, isTarget)
    dock.planBtn:SetScript("OnClick", function()
        if TI and TI.ToggleMilestone then
            local pinned = TI.ToggleMilestone(detail.id)
            if pinned then
                M.planTargetID = detail.id
            elseif M.planTargetID == detail.id then
                local sl = TI.ActiveSlot()
                M.planTargetID = (sl and sl.targets and sl.targets[#sl.targets]) or nil
            end
        else
            if M.planTargetID == detail.id then
                M.planTargetID = nil
            else
                M.planTargetID = detail.id
            end
        end
        if refreshFn then refreshFn() end
    end)

    StyleDockButton(dock.whatIfBtn, M.whatIfEnabled and "What-If: ON" or "What-If: OFF", M.whatIfEnabled)
    dock.whatIfBtn:SetScript("OnClick", function()
        M.whatIfEnabled = not M.whatIfEnabled
        if refreshFn then refreshFn() end
    end)

    return dockH
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local level = Num(Try(UnitLevel, "player")) or 0
    local y = -8

    local nodes, conds, err, spent, unspent = M.ReadGrid()
    if not nodes or #nodes == 0 then
        if _G.TATalentDetailDock and _G.TATalentDetailDock.Hide then
            _G.TATalentDetailDock:Hide()
        end
        if _G.TATalentFilterBar and _G.TATalentFilterBar.Hide then
            _G.TATalentFilterBar:Hide()
        end
        y = RenderNoTraits(content, y, level)
        if err then
            y = L:Paragraph(content, y, tostring(err), { color = L.C_DIM })
        end
        L:Finish(content, y)
        return
    end

    M._lastNodes = nodes
    M._lastConds = conds
    M._lastSpent = spent
    M._lastUnspent = unspent

    local windowW = 900
    if TA.UI and TA.UI.frame and TA.UI.frame.GetWidth then
        local w = TA.UI.frame:GetWidth()
        if type(w) == "number" and w > 0 then windowW = w end
    end
    local availW = L:Width(content)
    local function lay(width)
        return M.Plans(nodes, conds, {
            windowWidth = windowW,
            availWidth = width,
            spent = spent,
        })
    end
    local plans = lay(availW)
    local treeH, treeW = M.StackHeight(plans)
    M._report = plans[1] and plans[1].report

    -- Precompute Phase 3 intelligence context once per render (cached descriptions,
    -- exact unlock levels, Casts share, equipped Gear stats, and filter pills).
    local TI = TA.TalentIntel
    local intelCtx = nil
    local filterPills = nil
    if TI then
        local descByID, unlockByID = {}, {}
        for _, n in ipairs(nodes) do
            if n.id ~= nil then
                local d = TI.ReadSpellDesc(n.spellID)
                descByID[n.id] = d
                local ulv = TI.UnlockLevel(n, conds, spent, unspent, level, MinReq, NodeGate)
                if ulv then unlockByID[n.id] = ulv end
            end
        end
        filterPills = TI.DiscoverFilters(nodes, function(n) return descByID[n.id] or "" end)
        intelCtx = {
            nodes = nodes,
            spent = spent,
            playerLevel = level,
            descByID = descByID,
            unlockByID = unlockByID,
            castStats = TI.ReadCastStats(),
            gearStats = TI.ReadEquippedStats(),
        }
    end

    -- The header stays on the content frame. Filter bar sits right under it
    -- when TalentIntel is loaded.
    y = L:SectionHeader(content, y, M.Header(spent, unspent))
    local filterY = y
    local refreshPlanUI
    if TI and filterPills then
        local fH = MountFilterBar(content, filterY, availW, filterPills, function()
            if refreshPlanUI then refreshPlanUI() end
        end, nodes, intelCtx)
        if fH > 0 then y = y - fH - 4 end
    elseif _G.TATalentFilterBar and _G.TATalentFilterBar.Hide then
        _G.TATalentFilterBar:Hide()
    end

    local availH = M.TreeAvail(ViewportHeight(content), math.abs(y))
    local paneH, scrolls = M.TreePane(treeH, availH)
    if scrolls and availW > SCROLLBAR_PX + 40 then
        local plans2 = lay(availW - SCROLLBAR_PX)
        local treeH2, treeW2 = M.StackHeight(plans2)
        local pane2, scrolls2 = M.TreePane(treeH2, availH)
        if scrolls2 then
            plans, treeH, treeW = plans2, treeH2, treeW2
            paneH, scrolls = pane2, scrolls2
        end
    end

    local route = M.ActiveRoute(nodes, conds, spent, unspent, level)
    local _scroll, mountedButtons, mountedLines
    local function applyHeight(dockH)
        if scrolls then
            local view = ViewportHeight(content)
            if not view or view <= 0 then view = CONTENT_VIEW_FALLBACK end
            if dockH > 0 then
                local needed = math.abs(y - paneH - 8 - dockH) + 8
                content:SetHeight(math.max(math.floor(view), math.floor(needed)))
            else
                content:SetHeight(math.floor(view))
            end
        elseif dockH > 0 then
            L:Finish(content, y - paneH - 8 - dockH - 8)
        else
            L:Finish(content, y - paneH - 8)
        end
    end

    refreshPlanUI = function()
        local activeRoute = M.ActiveRoute(nodes, conds, spent, unspent, level)
        if TI and filterPills then
            local fH = MountFilterBar(content, filterY, availW, filterPills, refreshPlanUI, nodes, intelCtx)
            local newTreeY = (fH > 0) and (filterY - fH - 4) or filterY
            if newTreeY ~= y then
                y = newTreeY
                if _scroll then
                    if _scroll.ClearAllPoints then _scroll:ClearAllPoints() end
                    _scroll:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, y)
                end
            end
        end
        if mountedButtons then
            local fKey = M.activeFilter or "all"
            for _, btn in ipairs(mountedButtons) do
                btn._inPlan = (activeRoute and activeRoute.inPath and activeRoute.inPath[btn.id] ~= nil) or false
                if TI and intelCtx then
                    local d = intelCtx.descByID[btn.id] or ""
                    btn._filterDim = (fKey ~= "all") and (not TI.NodeMatchesFilter(btn._cell, d, fKey)) or false
                else
                    btn._filterDim = false
                end
                if btn._cell then
                    local ulv = intelCtx and intelCtx.unlockByID[btn.id] or nil
                    UpdateButtonBadge(btn, btn._cell, activeRoute, unspent, ulv, intelCtx and intelCtx.playerLevel)
                end
                PaintNode(btn)
            end
        end
        if mountedLines then
            for _, entry in ipairs(mountedLines) do
                pcall(TintEdge, entry.line, entry.ln, activeRoute)
            end
        end
        local dockH = MountDetailDock(content, y - paneH - 8, availW, nodes, conds, spent, unspent, refreshPlanUI, intelCtx)
        applyHeight(dockH)
    end

    _scroll, mountedButtons, mountedLines = MountTree(content, y, plans, paneH, treeH, treeW, route, unspent, refreshPlanUI, intelCtx)
    local dockH = MountDetailDock(content, y - paneH - 8, availW, nodes, conds, spent, unspent, refreshPlanUI, intelCtx)
    applyHeight(dockH)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "PLAYER_LEVEL_UP",
    "PLAYER_TALENT_UPDATE",
    "TRAIT_CONFIG_UPDATED",
    "CHARACTER_POINTS_CHANGED",
    "SPELLS_CHANGED",
}

return M
