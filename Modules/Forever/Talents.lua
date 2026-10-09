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

local function Secret(v)
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
local function MinReq(node, conds)
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
local function NodeGate(node, conds, spent)
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
    local dim = btn.state == "locked" and not hot
    local alpha = dim and M.LOCK_ALPHA or 1
    if hot then rgb = theme.gold end
    if btn.frame and btn.frame.SetTexture then
        btn.frame:SetTexture(M.FrameFile(btn.shape, hot, btn._px))
        Tint(btn.frame, rgb, alpha)
    end
    if btn.glow then
        if hot then btn.glow:Show() else btn.glow:Hide() end
    end
    Tint(btn.badgeFill, rgb, alpha)
    Tint(btn.badgeBorder, rgb, alpha)
    if btn.icon then
        btn.icon:SetAlpha(dim and M.LOCK_ALPHA or 1)
        if btn.icon.SetDesaturated then btn.icon:SetDesaturated(btn.state == "locked") end
    end
    if btn.lock then
        if btn._locked then btn.lock:Show() else btn.lock:Hide() end
    end
end

local function DrawGrid(parent, y, plan, pad)
    local holder = CreateFrame("Frame", nil, parent)
    local width  = math.max(1, math.floor(plan.width + 0.5))
    local height = math.max(1, math.floor(plan.height + 0.5))
    holder:SetSize(width, height)
    -- 0 is a real inset. Only a missing pad uses the content margin.
    if pad == nil then pad = L.PAD end
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", pad, y)

    local buttons = {}
    for _, cell in ipairs(plan.cells) do
        local btn = CreateFrame("Button", nil, holder)
        btn:SetSize(math.floor(cell.w), math.floor(cell.h))
        btn:SetPoint("TOPLEFT", holder, "TOPLEFT", math.floor(cell.x), -math.floor(cell.y))
        btn.id = cell.id
        btn.state = cell.state
        btn.shape = cell.shape
        btn._px = cell.w
        btn._locked = cell.locked
        btn._baseLevel = btn:GetFrameLevel()

        local frame = btn:CreateTexture(nil, "BORDER")
        frame:SetAllPoints()
        btn.frame = frame

        local inset = math.max(2, math.floor(cell.w * 0.12))
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
        if cell.texture then
            icon:SetTexture(cell.texture)
        else
            icon:SetColorTexture(0.08, 0.08, 0.09, 1)
        end
        btn.icon = icon

        -- talent_glow_circle sits under this node. Hover lifts the node and
        -- the glow above the neighbours; the glow stays one level behind
        -- its own button so it does not cover the icon.
        local glow = CreateFrame("Frame", nil, holder)
        glow:SetPoint("TOPLEFT", btn, "TOPLEFT", -M.GLOW_OUTSET, M.GLOW_OUTSET)
        glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", M.GLOW_OUTSET, -M.GLOW_OUTSET)
        glow:EnableMouse(false)
        local gtex = glow:CreateTexture(nil, "BACKGROUND")
        gtex:SetAllPoints()
        gtex:SetTexture(M.TEX.glow)
        local gold = M.Theme.gold
        Tint(gtex, gold, 1)
        if gtex.SetBlendMode then gtex:SetBlendMode("ADD") end
        glow:Hide()
        btn.glow = glow

        if cell.badge then
            local bw = math.min(22, math.max(12, math.floor(cell.w * 0.55)))
            local bh = math.min(12, math.max(8, math.floor(cell.h * 0.32)))
            local fill = btn:CreateTexture(nil, "OVERLAY")
            fill:SetSize(bw, bh)
            fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
            fill:SetTexture(M.TEX.badgeFill)
            btn.badgeFill = fill
            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints(fill)
            border:SetTexture(M.TEX.badgeBorder)
            btn.badgeBorder = border
            local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            badge:SetPoint("CENTER", fill, "CENTER", 0, 0)
            badge:SetText(cell.badge)
            badge:SetTextColor(1, 1, 1, 1)
        end

        -- One lock per gated talent. The row used to carry a single "N pts"
        -- label; the requirement now belongs to the node it gates.
        local lock = btn:CreateTexture(nil, "OVERLAY")
        local lockPx = math.min(16, math.max(10, math.floor(cell.w * 0.4)))
        lock:SetSize(lockPx, lockPx)
        lock:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        lock:SetTexture(M.LOCK_TEXTURE)
        lock:Hide()
        btn.lock = lock

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
                if cell.lockTip then
                    GameTooltip:AddLine(cell.lockTip, 0.85, 0.75, 0.45)
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
        btn:SetScript("OnClick", function(self)
            if M.selectedID == self.id then M.selectedID = nil else M.selectedID = self.id end
            for _, other in pairs(buttons) do PaintNode(other) end
        end)
        PaintNode(btn)
        buttons[cell.id] = btn
    end

    -- Lines sit under the nodes and use the node's own center, so a resize
    -- of the button still meets in the middle. Thickness stays 2px.
    if holder.CreateLine then
        for _, ln in ipairs(plan.lines) do
            local a, b = buttons[ln.a], buttons[ln.b]
            if a and b then
                local ok, line = pcall(holder.CreateLine, holder, nil, "BACKGROUND")
                if ok and line then
                    pcall(function()
                        line:SetThickness(M.LINE_PX)
                        if line.SetTexture then
                            line:SetTexture(ln.texture or M.TEX.edge)
                        end
                        Tint(line, M.Theme.line, M.Theme.line[4])
                        line:SetStartPoint("CENTER", a)
                        line:SetEndPoint("CENTER", b)
                    end)
                end
            end
        end
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
local function MountTree(content, y, plans, paneH, treeH, treeW)
    local scroll = _G.TATalentTreeScroll
    if scroll and scroll.SetParent then
        scroll:SetParent(content)
        if scroll.Show then scroll:Show() end
    else
        scroll = CreateFrame("ScrollFrame", "TATalentTreeScroll", content, "UIPanelScrollFrameTemplate")
    end
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

    local old = scroll.GetScrollChild and scroll:GetScrollChild()
    if old and old.SetParent then
        if old.Hide then old:Hide() end
        old:SetParent(nil)
    end
    local child = CreateFrame("Frame", nil, scroll)
    local cw = math.max(1, math.floor((tonumber(treeW) or 1) + 0.5))
    local ch = math.max(1, math.floor((tonumber(treeH) or 1) + 0.5))
    child:SetSize(cw, ch)
    if scroll.SetScrollChild then scroll:SetScrollChild(child) end

    local yOff = 0
    for _, plan in ipairs(plans) do
        DrawGrid(child, yOff, plan, 0)
        yOff = yOff - (tonumber(plan.height) or 0) - TREE_GAP
    end

    local keep = tonumber(M._treeScroll) or 0
    local maxScroll = ch - math.floor(paneH + 0.5)
    if maxScroll < 0 then maxScroll = 0 end
    if keep < 0 then keep = 0 end
    if keep > maxScroll then keep = maxScroll end
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(keep) end
    return scroll
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
        y = RenderNoTraits(content, y, level)
        if err then
            y = L:Paragraph(content, y, tostring(err), { color = L.C_DIM })
        end
        L:Finish(content, y)
        return
    end

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

    -- The header stays on the content frame. `y` is where the tree starts,
    -- so the pane is whatever the content scroll still has under that line.
    y = L:SectionHeader(content, y, M.Header(spent, unspent))
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

    MountTree(content, y, plans, paneH, treeH, treeW)
    if scrolls then
        -- Match the viewport so the outer content scroll does not move
        -- the points header while the tree scrolls inside its pane.
        local view = ViewportHeight(content)
        if not view or view <= 0 then view = CONTENT_VIEW_FALLBACK end
        content:SetHeight(math.floor(view))
    else
        L:Finish(content, y - paneH - 8)
    end
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
