-- ToonAge/Modules/Forever/Talents.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of your talent trees: points spent per tree, every talent you have
-- ranked, and -- the part that needs no researched data at all -- which nodes
-- you could spend a point on right now.
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

--- Tree display names.
---
--- C_Traits hands back tree IDs, not names -- the "Arcane / Fire / Frost"
--- headings in Blizzard's own window come from the specialisation list. So the
--- names are taken from there, and ONLY when the count matches the number of
--- trees; otherwise the trees are numbered. A mislabelled tree is worse than an
--- unlabelled one.
local function TreeNames(count)
    local names = {}
    -- Forever ships ONE combined tree per class (measured 2026-09-29/30:
    -- configInfo.treeIDs has a single entry for all 9 classes, 50-54 nodes).
    -- The spec list is absent here (GetNumSpecializations/GetSpecializationInfo),
    -- so the honest label for a single tree is the class itself.
    if count == 1 then
        local className = Try(UnitClass, "player")
        if className and not (issecretvalue and issecretvalue(className)) then
            names[1] = tostring(className) .. " talents"
        end
        return names
    end
    local n = Num(Try(GetNumSpecializations))
    if n and n == count then
        for i = 1, n do
            local _, specName = Try(GetSpecializationInfo, i)
            names[i] = specName and tostring(specName) or nil
        end
    end
    return names
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

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderTrees(content, y, trees, totalSpent, unspent)
    y = L:SectionHeader(content, y, "Talents",
        string.format("%d point%s spent.", totalSpent, totalSpent == 1 and "" or "s"))

    -- Points per tree as bars against the group's own scale: the comparison
    -- that matters is between your three trees, and there is no cap to measure
    -- against -- the same reasoning as the attribute bars.
    local counts = {}
    for _, t in ipairs(trees) do counts[#counts + 1] = t.spent end
    local scale = L.StatScale and L:StatScale(counts) or nil

    for _, t in ipairs(trees) do
        if scale and L.StatBar then
            y = L:StatBar(content, y, {
                label = t.name, value = t.spent, scale = scale, text = tostring(t.spent),
            })
        else
            y = L:DataRow(content, y, { label = t.name, value = tostring(t.spent) })
        end
    end

    if unspent and unspent > 0 then
        y = L:Paragraph(content, y,
            string.format("%d unspent point%s.", unspent, unspent == 1 and "" or "s"),
            { color = L.C_WARNING })
    end
    return y
end

local function RenderRanked(content, y, trees)
    for _, t in ipairs(trees) do
        if #t.ranked > 0 then
            y = L:Divider(content, y)
            y = L:SectionHeader(content, y, t.name,
                string.format("%d point%s", t.spent, t.spent == 1 and "" or "s"))
            for _, r in ipairs(t.ranked) do
                y = L:DataRow(content, y, {
                    label = r.name,
                    value = string.format("%d / %d", r.rank, r.max),
                })
            end
        end
    end
    return y
end

local function RenderAvailable(content, y, trees, unspent)
    local any = false
    for _, t in ipairs(trees) do if #t.available > 0 then any = true break end end
    if not any then return y end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Open to you now",
        "Nodes the client says a point can go into.")

    for _, t in ipairs(trees) do
        for _, a in ipairs(t.available) do
            -- One tree: the tree name repeats on every row and adds nothing.
            local value = (#trees > 1) and t.name or ""
            y = L:DataRow(content, y, { label = a.name, value = value, status = "dim" })
        end
    end

    y = L:Paragraph(content, y,
        (unspent and unspent > 0)
            and "These are the nodes your unspent points can reach. Which of them is worth taking is not something this addon claims to know."
            or  "Listed for when you next have a point. Availability is the client's answer; value is not.",
        { color = L.C_DIM })
    return y
end

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

local function RenderFooter(content, y)
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Not here yet")
    y = L:Paragraph(content, y,
        "Recommended builds need to know what a talent is worth in THIS game, "
        .. "and no verified numbers exist for it. What can be built honestly is "
        .. "measured rather than guessed: the recorder writes down what you and "
        .. "other characters actually pick, and a recommendation grown from that "
        .. "is observation, not invention.")
    return y
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

    local configID = ActiveConfig()
    local cfg = configID and C_Traits and C_Traits.GetConfigInfo
                and Try(C_Traits.GetConfigInfo, configID) or nil
    local treeIDs = (type(cfg) == "table" and type(cfg.treeIDs) == "table") and cfg.treeIDs or nil

    if not treeIDs or #treeIDs == 0 then
        y = RenderNoTraits(content, y, level)
        y = RenderFooter(content, y)
        L:Finish(content, y)
        return
    end

    local names = TreeNames(#treeIDs)
    local trees, totalSpent, unspent = {}, 0, nil
    for i, treeID in ipairs(treeIDs) do
        local ranked, available, spent = ReadTree(configID, treeID)
        trees[#trees + 1] = {
            name = names[i] or ("Tree " .. i),
            ranked = ranked, available = available, spent = spent,
        }
        totalSpent = totalSpent + spent
        local cur = TreeCurrency(configID, treeID)
        if cur then unspent = (unspent or 0) + cur end
    end

    y = RenderTrees(content, y, trees, totalSpent, unspent)
    y = RenderRanked(content, y, trees)
    y = RenderAvailable(content, y, trees, unspent)
    y = RenderFooter(content, y)
    L:Finish(content, y)
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
