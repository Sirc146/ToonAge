-- ToonAge/Core/Compat/API.lua  (SHARED ENGINE — cross-flavor API shims)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- ToonAgeOne runs on every WoW flavor from one codebase. Different flavors
-- expose the SAME game concept through DIFFERENT function names / calling
-- conventions:
--
--   * bag slot count:  Retail/MoP  C_Container.GetContainerNumSlots(bag)
--                      old Classic  GetContainerNumSlots(bag)            (global)
--   * spell info:      Retail       C_Spell.GetSpellInfo(id) -> table
--                      Classic      GetSpellInfo(id)         -> multiret
--   * item info:       Retail       C_Item.GetItemInfo(item)
--                      Classic      GetItemInfo(item)        (still current)
--   * addon loaded:    Retail       C_AddOns.IsAddOnLoaded(name)
--                      Classic      IsAddOnLoaded(name)
--   * talent tabs:     Classic-fam  GetNumTalentTabs / GetTalentTabInfo
--                      Retail        no equivalent (loadout system) -> nil
--
-- These are pure SURFACE differences: both sides describe the same underlying
-- concept, only the call changed. That is precisely the class of difference a
-- shim should absorb — as noted in Core/Environment.lua, this is the part that
-- IS shimmable. Game-RULE differences (talent numbers, stat caps) are NOT
-- shimmed here; those live in per-flavor Data/<Flavor>/*.lua.
--
-- Detection is done ONCE at file load (below) rather than per call. WOW_PROJECT
-- never changes mid-session, so re-testing `C_Container and ...` on every bag
-- scan would be wasted work in the addon's hottest paths (Gear/AutoEquip scan
-- every bag slot).
--
-- Consumers should call TA.Compat.* (or the U.* delegators in Core/Utils.lua
-- that forward here) rather than the raw globals, so a future API removal on
-- any flavor is a one-line fix in this file.
--
-- Load order: after Core/Environment.lua (so TA exists and flavor is known),
-- before Core/Utils.lua (which delegates its container/spell/item wrappers
-- here).
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge or {}
ToonAge = TA

local C = {}
TA.Compat = C

-- ─── Resolve underlying implementations once ───────────────────────────────
-- Resolve at call time. A load-time cache kept a nil global forever, and on
-- TBC a present C_Container namespace does not mean every method exists.
-- `or global()` also throws when the method returns 0 (falsy) and the global
-- is missing. Only call a value that is actually a function.
local function FirstFn(nsFn, globalFn)
    if type(nsFn) == "function" then return nsFn end
    if type(globalFn) == "function" then return globalFn end
    return nil
end

-- ── Container / bags ───────────────────────────────────────────────────────

--- @param bag number
--- @return number slot count (0 if the API is unavailable)
function C.GetContainerNumSlots(bag)
    local fn = FirstFn(C_Container and C_Container.GetContainerNumSlots, GetContainerNumSlots)
    if not fn then return 0 end
    return fn(bag) or 0
end

--- @return string|nil item link in the given bag slot
function C.GetContainerItemLink(bag, slot)
    local fn = FirstFn(C_Container and C_Container.GetContainerItemLink, GetContainerItemLink)
    if not fn then return nil end
    return fn(bag, slot)
end

--- @return number|nil itemID in the given bag slot
function C.GetContainerItemID(bag, slot)
    local fn = FirstFn(C_Container and C_Container.GetContainerItemID, GetContainerItemID)
    if not fn then return nil end
    return fn(bag, slot)
end

--- Retail returns a table; old Classic returns a multi-value tuple. Callers
--- that need cross-flavor behaviour should prefer GetContainerItemLink/ID above
--- and treat this as raw passthrough where they already branch on shape.
function C.GetContainerItemInfo(bag, slot)
    local fn = FirstFn(C_Container and C_Container.GetContainerItemInfo, GetContainerItemInfo)
    if not fn then return nil end
    return fn(bag, slot)
end

--- Pick an item up off a bag slot. Nil-safe: a missing global is not called.
function C.PickupContainerItem(bag, slot)
    local fn = FirstFn(C_Container and C_Container.PickupContainerItem, PickupContainerItem)
    if not fn then return false end
    fn(bag, slot)
    return true
end

-- ── Spells ───────────────────────────────────────────────────────────────
-- Normalized to a stable shape regardless of flavor:
--   GetSpellName(id)    -> string|nil
--   GetSpellTexture(id) -> number|nil (icon file id)
--   GetSpellInfo(id)    -> name, icon, castTime   (three values, both flavors)

function C.GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    if GetSpellInfo then return (GetSpellInfo(spellID)) end
    return nil
end

function C.GetSpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.iconID
    end
    if GetSpellTexture then return GetSpellTexture(spellID) end
    return nil
end

function C.GetSpellInfo(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then return info.name, info.iconID, info.castTime end
        return nil
    end
    if GetSpellInfo then
        local name, _, icon, castTime = GetSpellInfo(spellID)
        return name, icon, castTime
    end
    return nil
end

function C.GetSpellCooldown(spellID)
    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then return info.startTime, info.duration, info.isEnabled end
        return nil
    end
    if type(GetSpellCooldown) == "function" then
        return GetSpellCooldown(spellID)
    end
    return nil
end

function C.IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        if C_SpellBook.IsSpellKnown(spellID) then return true end
    end
    if IsSpellKnown then return IsSpellKnown(spellID) and true or false end
    return false
end

-- ── Items ──────────────────────────────────────────────────────────────────

function C.GetItemInfo(item)
    if C_Item and type(C_Item.GetItemInfo) == "function" then
        return C_Item.GetItemInfo(item)
    end
    if type(GetItemInfo) == "function" then return GetItemInfo(item) end
    return nil
end

function C.GetItemStats(itemLink)
    if not itemLink then return nil end
    if C_Item and type(C_Item.GetItemStats) == "function" then
        return C_Item.GetItemStats(itemLink)
    end
    if type(GetItemStats) == "function" then return GetItemStats(itemLink) end
    return nil
end

-- ── Addons ───────────────────────────────────────────────────────────────

function C.IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    if IsAddOnLoaded then return IsAddOnLoaded(name) end
    return false
end

function C.GetAddOnMetadata(name, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, field)
    end
    if GetAddOnMetadata then return GetAddOnMetadata(name, field) end
    return nil
end

-- ── Talent tabs (Classic family only) ──────────────────────────────────────
-- Retail has no tree/tab talent API (it uses the C_Traits loadout system), so
-- these return nil/0 there. Classic-family flavors (Vanilla/TBC/Wrath/Cata/
-- Mists) use the old tab API. Providing these here lets a shared module ask
-- "does this client have talent tabs?" without each one re-testing the globals.

--- @return boolean whether the old tab-based talent API exists on this client
-- Forever's talents are C_ClassTalents / C_Traits. The old tab globals must
-- not be called there even if a stub exists.
function C.HasTalentTabs()
    if TA and TA.IsForever then return false end
    return type(GetNumTalentTabs) == "function" and type(GetTalentTabInfo) == "function"
end

function C.GetNumTalentTabs()
    if not C.HasTalentTabs() then return 0 end
    return GetNumTalentTabs() or 0
end

function C.GetTalentTabInfo(tabIndex)
    if not C.HasTalentTabs() then return nil end
    return GetTalentTabInfo(tabIndex)
end

function C.GetTalentInfo(tabIndex, talentIndex)
    if TA and TA.IsForever then return nil end
    if type(GetTalentInfo) ~= "function" then return nil end
    return GetTalentInfo(tabIndex, talentIndex)
end

--- Spec from the talent tree with the most points. Used on clients with no
--- spec API (Classic Era, TBC, and Mists when C_SpecializationInfo is absent).
--- Returns nil when no tree has 10 or more points, or when two trees tie.
--- Forever never reaches this: HasTalentTabs is false there, and spec comes
--- from C.SpecFromTraitSections instead.
--- @return number|nil tabIndex, string|nil name
function C.SpecFromTalentTabs()
    if not C.HasTalentTabs() then return nil end
    local okN, n = pcall(GetNumTalentTabs)
    if not okN or type(n) ~= "number" or n <= 0 then return nil end
    local bestName, bestPoints, bestIndex = nil, -1, nil
    local tie = false
    for i = 1, n do
        local ok, a, b, c, d, e = pcall(GetTalentTabInfo, i)
        if ok then
            local name, points
            if type(a) == "string" and type(c) == "number" then
                name, points = a, c
            elseif type(b) == "string" and type(e) == "number" then
                name, points = b, e
            elseif type(a) == "string" and type(b) == "number" then
                name, points = a, b
            end
            points = tonumber(points) or 0
            if points > bestPoints then
                bestPoints, bestName, bestIndex, tie = points, name, i, false
            elseif points > 0 and points == bestPoints then
                tie = true
            end
        end
    end
    if tie or not bestName or bestPoints < 10 then return nil end
    return bestIndex, bestName
end

-- ── Forever specs (one C_Traits tree, sections inside it) ───────────────────
-- Measured on Forever 1.60.1 (interface 16001, project 18), level 1 Rogue:
--   * Talents are C_Traits, not GetTalentTabInfo. The Rogue tree is one tree
--     of 53 nodes. GetTreeInfo gates are spentAmountRequired conditions of
--     5, 10, 15, 20 and 30 -- the classic row locks, once per section.
--   * A spellbook tab is not a spec. At level 1 the book already has General,
--     Combat and Assassination, and C_SkillInfo lists Combat (38) and
--     Assassination (253) as class skills. Those lines exist before any
--     talent point is spent, so they are never read here.
-- Sections are the columns of that one tree (subTreeID when the client splits
-- them that way, otherwise posX). Points are the sum of purchased ranks in
-- the section. The section with strictly the most points is the spec. Zero
-- points, or a tie, is no spec. Names follow classic tab order left to right,
-- and only when the column count matches -- a mismatched layout is unnamed
-- rather than labelled wrong.

local SECTION_NAMES = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER  = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE   = { "Assassination", "Combat", "Subtlety" },
    PRIEST  = { "Discipline", "Holy", "Shadow" },
    SHAMAN  = { "Elemental", "Enhancement", "Restoration" },
    MAGE    = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID   = { "Balance", "Feral", "Restoration" },
}

local GATE_POINTS = { [5] = true, [10] = true, [15] = true, [20] = true, [30] = true }

local function CopyList(src)
    local out = {}
    for i, v in ipairs(src or {}) do out[i] = v end
    return out
end

--- Distinct spentAmountRequired values that are the classic row gates.
--- @param conditions table condID -> { spentAmountRequired = n } or an array of those
--- @return table sorted list, possibly empty
function C.SpentGateAmounts(conditions)
    local seen = {}
    local function take(c)
        if type(c) ~= "table" then return end
        local n = tonumber(c.spentAmountRequired)
        if n and GATE_POINTS[n] then seen[n] = true end
    end
    if type(conditions) ~= "table" then return {} end
    for k, v in pairs(conditions) do
        if type(v) == "table" then take(v) else take(k) end
    end
    local list = {}
    for n in pairs(seen) do list[#list + 1] = n end
    table.sort(list)
    return list
end

local function ColumnKey(nodes)
    -- Shared posX (a handful of columns) is the classic three-tree layout.
    -- Many distinct x values are a grid: split where the gap jumps.
    local byX = {}
    for _, n in ipairs(nodes) do
        if type(n.posX) == "number" then
            local x = math.floor(n.posX + 0.5)
            byX[x] = byX[x] or {}
            byX[x][#byX[x] + 1] = n
        end
    end
    local keys = {}
    for x in pairs(byX) do keys[#keys + 1] = x end
    table.sort(keys)
    if #keys < 2 then return nil end
    local groups
    if #keys <= 6 then
        groups = {}
        for _, x in ipairs(keys) do groups[#groups + 1] = byX[x] end
    else
        local gaps = {}
        for i = 1, #keys - 1 do gaps[#gaps + 1] = keys[i + 1] - keys[i] end
        local sorted = CopyList(gaps)
        table.sort(sorted)
        local typical = sorted[math.max(1, math.floor(#sorted * 0.4))]
        if not typical or typical < 1 then typical = 1 end
        groups = { {} }
        for i, x in ipairs(keys) do
            if i > 1 and (x - keys[i - 1]) > typical * 3 then
                groups[#groups + 1] = {}
            end
            local dest = groups[#groups]
            for _, n in ipairs(byX[x]) do dest[#dest + 1] = n end
        end
    end
    if not groups or #groups < 2 then return nil end
    return groups
end

local function SubTreeGroups(nodes)
    local buckets, order = {}, {}
    local missing = false
    for _, n in ipairs(nodes) do
        if n.subTreeID == nil then missing = true break end
        local id = n.subTreeID
        if not buckets[id] then
            buckets[id] = {}
            order[#order + 1] = id
        end
        buckets[id][#buckets[id] + 1] = n
    end
    if missing or #order < 2 then return nil end
    table.sort(order, function(a, b)
        local function minX(id)
            local x
            for _, n in ipairs(buckets[id]) do
                if type(n.posX) == "number" and (not x or n.posX < x) then x = n.posX end
            end
            return x or 0
        end
        local xa, xb = minX(a), minX(b)
        if xa ~= xb then return xa < xb end
        return tostring(a) < tostring(b)
    end)
    local groups = {}
    for _, id in ipairs(order) do groups[#groups + 1] = buckets[id] end
    return groups
end

local function EdgeGroups(nodes, conditions)
    if #nodes < 2 then return nil end
    local parent = {}
    local function find(x)
        parent[x] = parent[x] or x
        if parent[x] ~= x then parent[x] = find(parent[x]) end
        return parent[x]
    end
    local function union(a, b)
        if a == nil or b == nil then return end
        a, b = find(a), find(b)
        if a ~= b then parent[a] = b end
    end
    local byID = {}
    for _, n in ipairs(nodes) do
        if n.nodeID ~= nil then byID[n.nodeID] = n; find(n.nodeID) end
    end
    for _, n in ipairs(nodes) do
        if n.nodeID ~= nil and type(n.edges) == "table" then
            for _, target in ipairs(n.edges) do union(n.nodeID, target) end
        end
        if n.nodeID ~= nil and type(n.conditionIDs) == "table" and type(conditions) == "table" then
            for _, cid in ipairs(n.conditionIDs) do
                local c = conditions[cid]
                if type(c) == "table" and c.topLeftNodeID ~= nil then
                    union(n.nodeID, c.topLeftNodeID)
                end
            end
        end
    end
    local buckets, order = {}, {}
    for _, n in ipairs(nodes) do
        if n.nodeID == nil then return nil end
        local root = find(n.nodeID)
        if not buckets[root] then
            buckets[root] = {}
            order[#order + 1] = root
        end
        buckets[root][#buckets[root] + 1] = n
    end
    if #order < 2 then return nil end
    table.sort(order, function(a, b)
        local function minX(id)
            local x
            for _, n in ipairs(buckets[id]) do
                if type(n.posX) == "number" and (not x or n.posX < x) then x = n.posX end
            end
            return x or 0
        end
        local xa, xb = minX(a), minX(b)
        if xa ~= xb then return xa < xb end
        return tostring(a) < tostring(b)
    end)
    local groups = {}
    for _, id in ipairs(order) do groups[#groups + 1] = buckets[id] end
    return groups
end

--- Group trait nodes into sections and sum purchased ranks.
--- nodes: { nodeID, rank, posX, posY, subTreeID, conditionIDs, edges }
--- conditions: condID -> { spentAmountRequired, topLeftNodeID } from
--- GetTreeInfo gates + GetConditionInfo. Gate thresholds are not themselves
--- the sections; they lock rows inside a section.
--- @return table sections { index, points, posX, nodes }
function C.GroupTraitSections(nodes, conditions)
    if type(nodes) ~= "table" then return {} end
    -- A node behind a gate inherits the anchor's column when it has no posX.
    local byID = {}
    for _, n in ipairs(nodes) do
        if type(n) == "table" and n.nodeID ~= nil then byID[n.nodeID] = n end
    end
    if type(conditions) == "table" then
        for _, n in ipairs(nodes) do
            if type(n) == "table" and n.posX == nil and type(n.conditionIDs) == "table" then
                for _, cid in ipairs(n.conditionIDs) do
                    local c = conditions[cid]
                    local anchor = type(c) == "table" and byID[c.topLeftNodeID]
                    if anchor and type(anchor.posX) == "number" then
                        n.posX = anchor.posX
                        break
                    end
                end
            end
        end
    end
    local groups = SubTreeGroups(nodes) or ColumnKey(nodes) or EdgeGroups(nodes, conditions)
    if not groups then groups = { nodes } end
    local sections = {}
    for i, col in ipairs(groups) do
        local points, minX = 0, nil
        for _, n in ipairs(col) do
            if type(n) == "table" then
                points = points + (tonumber(n.rank) or 0)
                if type(n.posX) == "number" and (not minX or n.posX < minX) then minX = n.posX end
            end
        end
        sections[#sections + 1] = { index = i, points = points, posX = minX, nodes = col }
    end
    return sections
end

--- The winning section, or nil when there is nothing to choose (under two
--- sections, no points, or a tie). Name is set only when classToken's classic
--- tab order has exactly as many entries as there are sections.
--- @return number|nil index, string|nil name, number|nil points
function C.SpecFromSections(sections, classToken)
    if type(sections) ~= "table" or #sections < 2 then return nil end
    local best, bestPts, tie = nil, 0, false
    for _, s in ipairs(sections) do
        local p = tonumber(s.points) or 0
        if p > bestPts then
            best, bestPts, tie = s, p, false
        elseif p > 0 and p == bestPts then
            tie = true
        end
    end
    if tie or not best or bestPts < 1 then return nil end
    local names = SECTION_NAMES[classToken]
    if not names or #names ~= #sections then return nil end
    local name = names[best.index]
    if not name then return nil end
    return best.index, name, bestPts
end

--- Fill section.name from classic tab order. Unmatched layouts stay unnamed.
function C.LabelSections(sections, classToken)
    local names = SECTION_NAMES[classToken]
    if type(sections) ~= "table" or not names or #names ~= #sections then return sections end
    for i, s in ipairs(sections) do s.name = names[i] end
    return sections
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a = pcall(fn, ...)
    if not ok then return nil end
    return a
end

local function NodeRank(info)
    if type(info) ~= "table" then return 0 end
    local r = tonumber(info.activeRank)
    if r == nil then r = tonumber(info.ranksPurchased) end
    return r or 0
end

local function ReadConditions(configID, treeID)
    local conditions = {}
    if not (C_Traits and type(C_Traits.GetTreeInfo) == "function") then return conditions end
    local ti = Call(C_Traits.GetTreeInfo, configID, treeID)
    if type(ti) ~= "table" or type(ti.gates) ~= "table" then return conditions end
    for _, g in ipairs(ti.gates) do
        if type(g) == "table" and g.conditionID ~= nil
            and type(C_Traits.GetConditionInfo) == "function" then
            local ci = Call(C_Traits.GetConditionInfo, configID, g.conditionID)
            if type(ci) == "table" then
                conditions[g.conditionID] = {
                    spentAmountRequired = tonumber(ci.spentAmountRequired),
                    topLeftNodeID = g.topLeftNodeID,
                    isMet = ci.isMet,
                }
            end
        end
    end
    return conditions
end

local function ReadNodes(configID, treeID)
    local nodes = {}
    if not (C_Traits and type(C_Traits.GetTreeNodes) == "function"
        and type(C_Traits.GetNodeInfo) == "function") then
        return nodes
    end
    local list = Call(C_Traits.GetTreeNodes, treeID)
    if type(list) ~= "table" then return nodes end
    for _, nodeID in ipairs(list) do
        local info = Call(C_Traits.GetNodeInfo, configID, nodeID)
        if type(info) == "table" then
            local edges = {}
            if type(info.visibleEdges) == "table" then
                for _, e in ipairs(info.visibleEdges) do
                    if type(e) == "table" and e.targetNode ~= nil then
                        edges[#edges + 1] = e.targetNode
                    end
                end
            end
            nodes[#nodes + 1] = {
                nodeID = nodeID,
                rank = NodeRank(info),
                posX = tonumber(info.posX),
                posY = tonumber(info.posY),
                subTreeID = info.subTreeID,
                conditionIDs = info.conditionIDs,
                edges = edges,
            }
        end
    end
    return nodes
end

local function PlayerClassToken()
    if type(UnitClass) ~= "function" then return nil end
    local ok, _, token = pcall(UnitClass, "player")
    if not ok then return nil end
    return token
end

--- Live read of every section on the active trait config.
--- One tree is split into columns. Several trees are one section each.
--- Does not read the spellbook or C_SkillInfo.
--- @return table|nil sections
function C.ReadTraitSections()
    if not (C_ClassTalents and type(C_ClassTalents.GetActiveConfigID) == "function") then
        return nil
    end
    if not (C_Traits and type(C_Traits.GetConfigInfo) == "function") then return nil end
    local configID = Call(C_ClassTalents.GetActiveConfigID)
    if not configID then return nil end
    local cfg = Call(C_Traits.GetConfigInfo, configID)
    if type(cfg) ~= "table" or type(cfg.treeIDs) ~= "table" or #cfg.treeIDs == 0 then
        return nil
    end
    local classToken = PlayerClassToken()
    local sections
    if #cfg.treeIDs == 1 then
        local treeID = cfg.treeIDs[1]
        local nodes = ReadNodes(configID, treeID)
        local conditions = ReadConditions(configID, treeID)
        sections = C.GroupTraitSections(nodes, conditions)
    else
        sections = {}
        for i, treeID in ipairs(cfg.treeIDs) do
            ReadConditions(configID, treeID)
            local points = 0
            for _, n in ipairs(ReadNodes(configID, treeID)) do
                points = points + (n.rank or 0)
            end
            sections[#sections + 1] = { index = i, points = points, posX = i, nodes = {} }
        end
    end
    return C.LabelSections(sections, classToken)
end

--- Spec from points spent per trait section. nil when no section leads.
--- @return number|nil index, string|nil name, number|nil points
function C.SpecFromTraitSections()
    local sections = C.ReadTraitSections()
    if not sections then return nil end
    return C.SpecFromSections(sections, PlayerClassToken())
end

-- ── Waypoint APIs (arrow probe) ──────────────────────────────────────────
-- The harvest map probe asks these on every client. Feature code must not
-- call them itself: ApiGuard reports a name from the manifest as missing,
-- and the type check below covers a client whose manifest has not measured
-- the name yet. A missing function is not called.
-- Texture:SetRotation is a widget method, not a global, so ApiGuard has no
-- path for it. ProbeTextureSetRotation is the one place that samples it.

local function WaypointAllowed(path)
    if TA.HasAPI and not TA:HasAPI(path) then return false end
    return true
end

--- One position API, with no fallback. The probe prints a line per name, so
--- the namespaced function and the legacy global are resolved separately.
function C.MapPositionFn(path)
    if not WaypointAllowed(path) then return nil end
    if path == "C_Map.GetPlayerMapPosition" then
        if not (C_Map and type(C_Map.GetPlayerMapPosition) == "function") then return nil end
        return function(mapID, unit) return C_Map.GetPlayerMapPosition(mapID, unit) end
    end
    if path == "GetPlayerMapPosition" then
        if type(GetPlayerMapPosition) ~= "function" then return nil end
        return function(unit) return GetPlayerMapPosition(unit or "player") end
    end
    return nil
end

--- The function for a waypoint API path, or nil when ApiGuard or this client
--- says it is not there. Player position tries C_Map.GetPlayerMapPosition
--- first and falls back to the legacy global.
function C.WaypointFn(path)
    if path == "C_Map.GetPlayerMapPosition" then
        return C.MapPositionFn("C_Map.GetPlayerMapPosition") or C.MapPositionFn("GetPlayerMapPosition")
    end
    if path == "GetPlayerMapPosition" then
        return C.MapPositionFn("GetPlayerMapPosition")
    end
    if not WaypointAllowed(path) then return nil end
    if path == "IsInInstance" then
        if type(IsInInstance) ~= "function" then return nil end
        return function() return IsInInstance() end
    end
    if path == "UnitPosition" then
        if type(UnitPosition) ~= "function" then return nil end
        return function(unit) return UnitPosition(unit) end
    end
    if path == "C_Map.GetBestMapForUnit" then
        if not (C_Map and type(C_Map.GetBestMapForUnit) == "function") then return nil end
        return function(unit) return C_Map.GetBestMapForUnit(unit) end
    end
    if path == "C_Map.GetWorldPosFromMapPos" then
        if not (C_Map and type(C_Map.GetWorldPosFromMapPos) == "function") then return nil end
        return function(mapID, pos) return C_Map.GetWorldPosFromMapPos(mapID, pos) end
    end
    return nil
end

function C.APIPresent(path)
    return type(C.WaypointFn(path)) == "function"
end

--- false, "missing" when the API is absent. Otherwise the pcall result.
function C.CallAPI(path, ...)
    local fn = C.WaypointFn(path)
    if type(fn) ~= "function" then return false, "missing" end
    return pcall(fn, ...)
end

--- "ok", or "error", message, or "missing". Samples Texture:SetRotation(0).
--- The frame and texture are created once and kept on the DataHarvester module.
function C.ProbeTextureSetRotation()
    local host = (TA.modules and TA.modules.DataHarvester) or C
    local tex = host._probeRotationTex
    if type(tex) ~= "table" then
        if type(CreateFrame) ~= "function" then return "missing" end
        local frame = host._probeRotationFrame
        if type(frame) ~= "table" or type(frame.CreateTexture) ~= "function" then
            local okF, made = pcall(CreateFrame, "Frame")
            if not okF or type(made) ~= "table" or type(made.CreateTexture) ~= "function" then
                return "missing"
            end
            frame = made
            host._probeRotationFrame = frame
        end
        local okT, madeT = pcall(frame.CreateTexture, frame)
        if not okT or type(madeT) ~= "table" then return "missing" end
        tex = madeT
        host._probeRotationTex = tex
    end
    if type(tex.SetRotation) ~= "function" then return "missing" end
    local okR, err = pcall(tex.SetRotation, tex, 0)
    if okR then return "ok" end
    return "error", err
end

--- The functions Forever 1.60.1 does not have. Each call is behind a type
--- check so a missing global is nil, not an error. The call text is what
--- puts the name in the ApiGuard manifest (Tools/gen_api_manifest.py).
--- Not invoked at load; ApiGuard resolves the names without calling them.
function C.GuardMissingForeverAPIs()
    -- The parenthesis is the call the manifest scanner records. pcall keeps a
    -- present-but-broken stub from taking the caller down.
    if type(GetTalentTabInfo) == "function" then pcall(function() return GetTalentTabInfo(1) end) end
    if type(UnitAttackBothHands) == "function" then pcall(function() return UnitAttackBothHands("player") end) end
    if type(UnitRangedAttack) == "function" then pcall(function() return UnitRangedAttack("player") end) end
    if type(UnitDefense) == "function" then pcall(function() return UnitDefense("player") end) end
    if type(GetSpellLevelLearned) == "function" then pcall(function() return GetSpellLevelLearned(0) end) end
    if C_Spell and type(C_Spell.GetSpellRank) == "function" then
        pcall(function() return C_Spell.GetSpellRank(0) end)
    end
end

return C
