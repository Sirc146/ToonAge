-- ToonAge/Modules/Character/ProfessionGear.lua
-- Retail profession gear under each profession card.
--
-- Three slots, the tool and two accessories, from C_TradeSkillUI's profession
-- slot calls. Specialization points come from C_ProfSpecs (tabs, path states,
-- points spent). Which stat a path improves, and the GetItemStats key for
-- that stat, live in Data/Retail/professions_retail.lua. This file does not
-- name a stat.
--
-- Loaded on retail only. A client without the slot calls never shows the row.
-- Classic-era skill bonuses (a fishing pole, mining gloves) are later work.

local TA = ToonAge
TA.modules = TA.modules or {}

local PG = {}
TA.ProfessionGear = PG
TA:RegisterModule("ProfessionGear", PG)

PG.CACHE_KEY = "professionGearBank"
PG.LOCK_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_lock_16.tga"

local function Lookup(path)
    local Caps = TA.Caps
    if Caps and Caps.Fn then
        local fn = Caps.Fn(path)
        if type(fn) == "function" then return fn end
    end
    local node = _G
    for seg in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[seg]
        if node == nil then return nil end
    end
    if type(node) == "function" then return node end
    return nil
end

function PG.CombatLocked()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

--- nil live means the bank was closed. Keep the previous cache. A table,
--- even an empty one, is a live read and replaces it. An unresolved open
--- visit also keeps the previous cache.
function PG.NextBankCache(previous, live, unresolved)
    if live == nil or unresolved then return previous end
    return live
end

function PG.SlotCallsReady()
    return Lookup("C_TradeSkillUI.GetProfessionSlots")
        and Lookup("C_TradeSkillUI.GetProfessionSkillLineID")
        and true or false
end

local function EachProfession(fn)
    local enum = Enum and Enum.Profession
    if type(enum) ~= "table" then return end
    for _, id in pairs(enum) do
        if type(id) == "number" then fn(id) end
    end
end

--- Parent skill line -> profession enum and the inventory slot ids.
--- nil when the slot calls are missing or this skill line is not one of them.
function PG.LookupProfession(skillLineID)
    if not skillLineID or not PG.SlotCallsReady() then return nil, nil end
    local getSlots = Lookup("C_TradeSkillUI.GetProfessionSlots")
    local getLine = Lookup("C_TradeSkillUI.GetProfessionSkillLineID")
    local foundProf, foundSlots
    EachProfession(function(prof)
        if foundSlots then return end
        local okLine, line = pcall(getLine, prof)
        if okLine and line == skillLineID then
            -- A table of slot ids, or the same ids returned loose.
            local okSlots, a, b, c = pcall(getSlots, prof)
            local raw
            if okSlots and type(a) == "table" then
                raw = a
            elseif okSlots and type(a) == "number" then
                raw = { a, b, c }
            end
            if raw then
                local ids = {}
                for i = 1, 3 do
                    if type(raw[i]) == "number" then ids[#ids + 1] = raw[i] end
                end
                if #ids > 0 then
                    foundProf = prof
                    foundSlots = ids
                end
            end
        end
    end)
    return foundProf, foundSlots
end

function PG.CurrentExpansion()
    local data = TA.Data and TA.Data.ProfessionSkills
    if type(data) ~= "table" then return nil end
    for _, exp in ipairs(data.expansions or {}) do
        if type(exp) == "table" and exp.current then return exp.label end
    end
    return nil
end

local function Catalog(data)
    local byId = {}
    for _, stat in ipairs(data and data.stats or {}) do
        if type(stat) == "table" and stat.id then byId[stat.id] = stat end
    end
    return byId
end

local function MatchPath(data, path)
    if type(path) ~= "table" then return nil end
    for _, row in ipairs(data.paths or {}) do
        if type(row) == "table" and row.id ~= nil and path.id ~= nil and row.id == path.id then
            return row
        end
    end
    if type(path.name) == "string" and path.name ~= "" then
        for _, row in ipairs(data.paths or {}) do
            if type(row) == "table" and row.name == path.name then return row end
        end
    end
    return nil
end

--- weights keyed by the data file's GetItemStats key.
--- sources[stat id] = { points, path } for the path that spent the most.
function PG.BuildWeights(data, spent)
    local weights, sources = {}, {}
    if type(data) ~= "table" then return weights, sources end
    local byId = Catalog(data)
    local skill = byId[data.skillStat]
    if skill and skill.key then
        weights[skill.key] = tonumber(data.skillWeight) or 0
    end
    for _, path in ipairs(spent or {}) do
        local mapped = MatchPath(data, path)
        local points = tonumber(path.points) or 0
        if mapped and points > 0 then
            local pathName = path.name
            if type(pathName) ~= "string" or pathName == "" then pathName = mapped.name end
            for _, statId in ipairs(mapped.stats or {}) do
                local stat = byId[statId]
                if stat and stat.key then
                    weights[stat.key] = (weights[stat.key] or 0) + points
                    local prev = sources[statId]
                    if not prev or points > prev.points then
                        sources[statId] = { points = points, path = pathName }
                    end
                end
            end
        end
    end
    return weights, sources
end

function PG.Score(stats, weights)
    local total = 0
    if type(stats) ~= "table" or type(weights) ~= "table" then return 0 end
    for key, weight in pairs(weights) do
        total = total + (tonumber(stats[key]) or 0) * (tonumber(weight) or 0)
    end
    return total
end

function PG.Beats(candidate, equipped, margin)
    return (tonumber(candidate) or 0) > (tonumber(equipped) or 0) + (tonumber(margin) or 0)
end

--- "+Name, matches your N pts in Path" when the points come from a path.
function PG.Explain(name, points, path)
    if type(name) ~= "string" or name == "" then return nil end
    points = tonumber(points) or 0
    if points > 0 and type(path) == "string" and path ~= "" then
        return string.format("+%s, matches your %d pts in %s", name, points, path)
    end
    return "+" .. name
end

function PG.Reasons(data, candStats, eqStats, sources)
    local lines = {}
    for _, stat in ipairs(data and data.stats or {}) do
        local cand = tonumber(candStats and candStats[stat.key]) or 0
        local eq = tonumber(eqStats and eqStats[stat.key]) or 0
        if cand > eq then
            local src = sources and sources[stat.id]
            local line = PG.Explain(stat.name, src and src.points, src and src.path)
            if line then lines[#lines + 1] = line end
        end
    end
    return lines
end

function PG.MarkedName(name)
    local U = TA.Utils
    if U and U.MarkItemName then return U.MarkItemName(name or "", "upgrade") end
    return name or ""
end

function PG.EquipSetup(item)
    if type(item) ~= "table" or item.where ~= "bag" then return nil end
    if type(item.bag) ~= "number" or type(item.slot) ~= "number" then return nil end
    return tostring(item.bag) .. " " .. tostring(item.slot)
end

function PG.IsProfessionEquipLoc(equipLoc, data)
    for _, slot in ipairs(data and data.slots or {}) do
        if slot.equipLoc and slot.equipLoc == equipLoc then return true end
    end
    return false
end

function PG.RoleFor(equipLoc, data)
    for _, slot in ipairs(data and data.slots or {}) do
        if slot.equipLoc == equipLoc then return slot.role end
    end
    return nil
end

local function LockedState()
    local enum = Enum and Enum.ProfessionsSpecPathState
    if type(enum) == "table" and enum.Locked ~= nil then return enum.Locked end
    return 0
end

local function HasEntry(info, entryID)
    if type(info) ~= "table" or entryID == nil then return false end
    if type(info.entryIDs) == "table" then
        for _, id in ipairs(info.entryIDs) do
            if id == entryID then return true end
        end
    end
    local active = info.activeEntry
    if type(active) == "table" and active.entryID == entryID then return true end
    return false
end

local function PointsFromInfo(info)
    if type(info) ~= "table" or info.ranksPurchased == nil then return nil end
    return tonumber(info.ranksPurchased) or 0
end

local function PointsSpent(configID, pathID)
    local getNode = Lookup("C_Traits.GetNodeInfo")
    if getNode then
        local ok, info = pcall(getNode, configID, pathID)
        local points = ok and PointsFromInfo(info) or nil
        if points ~= nil then return points, info end
    end
    local entryFn = Lookup("C_ProfSpecs.GetSpendEntryForPath")
    local treeFn = Lookup("C_Traits.GetTreeNodes")
    if not (entryFn and getNode and treeFn) then return 0, nil end
    local okE, entryID = pcall(entryFn, pathID)
    local okT, nodes = pcall(treeFn, configID)
    if not (okE and entryID and okT and type(nodes) == "table") then return 0, nil end
    for _, nodeID in ipairs(nodes) do
        local okN, info = pcall(getNode, configID, nodeID)
        if okN and HasEntry(info, entryID) then
            local points = PointsFromInfo(info)
            if points ~= nil then return points, info end
        end
    end
    return 0, nil
end

local function NameFromNode(configID, info)
    if type(info) ~= "table" then return nil end
    local entryID
    if type(info.activeEntry) == "table" then entryID = info.activeEntry.entryID end
    if not entryID and type(info.entryIDs) == "table" then entryID = info.entryIDs[1] end
    local getEntry = Lookup("C_Traits.GetEntryInfo")
    local getDef = Lookup("C_Traits.GetDefinitionInfo")
    if not entryID or not getEntry or not getDef then return nil end
    local okE, entry = pcall(getEntry, configID, entryID)
    if not okE or type(entry) ~= "table" or not entry.definitionID then return nil end
    local okD, def = pcall(getDef, entry.definitionID)
    if okD and type(def) == "table" then
        local name = def.overrideName
        if type(name) == "string" and name ~= "" then return name end
    end
    return nil
end

local function WalkPaths(configID, pathID, rootNodeID, out, seen)
    if not pathID or seen[pathID] then return end
    seen[pathID] = true
    local state
    local getState = Lookup("C_ProfSpecs.GetStateForPath")
    if getState then
        local ok, value = pcall(getState, pathID, configID)
        if ok then state = value end
    end
    local points, info = 0, nil
    if state ~= nil and state ~= LockedState() then
        points, info = PointsSpent(configID, pathID)
        if pathID == rootNodeID and (not info) then
            local getNode = Lookup("C_Traits.GetNodeInfo")
            if getNode and rootNodeID then
                local ok, node = pcall(getNode, configID, rootNodeID)
                if ok and type(node) == "table" then
                    info = node
                    local ranked = PointsFromInfo(node)
                    if ranked ~= nil then points = ranked end
                end
            end
        end
    end
    out[#out + 1] = {
        id = pathID,
        name = NameFromNode(configID, info),
        points = points,
    }
    local getKids = Lookup("C_ProfSpecs.GetChildrenForPath")
    if getKids then
        local ok, kids = pcall(getKids, pathID)
        if ok and type(kids) == "table" then
            for _, child in ipairs(kids) do
                WalkPaths(configID, child, rootNodeID, out, seen)
            end
        end
    end
end

local function ReadOneSpec(skillLineID)
    local getConfig = Lookup("C_ProfSpecs.GetConfigIDForSkillLine")
    local getTabs = Lookup("C_ProfSpecs.GetSpecTabIDsForSkillLine")
    local getTab = Lookup("C_ProfSpecs.GetTabInfo")
    local getRoot = Lookup("C_ProfSpecs.GetRootPathForTab")
    if not (getConfig and getTabs and getRoot) then return nil end
    local okC, configID = pcall(getConfig, skillLineID)
    if not okC or type(configID) ~= "number" or configID == 0 then return nil end
    local okT, tabs = pcall(getTabs, skillLineID)
    if not okT or type(tabs) ~= "table" then return nil end
    local out = {}
    local seen = {}
    for _, tabID in ipairs(tabs) do
        local rootNodeID
        if getTab then
            local okInfo, info = pcall(getTab, tabID)
            if okInfo and type(info) == "table" then rootNodeID = info.rootNodeID end
        end
        local okR, root = pcall(getRoot, tabID)
        if okR and root then
            WalkPaths(configID, root, rootNodeID, out, seen)
        end
    end
    return out
end

function PG.SpecSkillLines(card)
    local out = {}
    if type(card) ~= "table" then return out end
    if type(card.segments) == "table" then
        for _, seg in ipairs(card.segments) do
            if type(seg) == "table" and seg.current and seg.id then
                out[#out + 1] = seg.id
            end
        end
    end
    if card.id then out[#out + 1] = card.id end
    return out
end

function PG.ReadSpent(card)
    local lines = PG.SpecSkillLines(card)
    if #lines == 0 and type(card) == "number" then lines = { card } end
    for _, id in ipairs(lines) do
        local spent = ReadOneSpec(id)
        if spent then return spent end
    end
    return {}
end

local function ItemInfo(item)
    local U = TA.Utils
    if U and type(U.GetItemInfo) == "function" then return U.GetItemInfo(item) end
    if type(GetItemInfo) == "function" then return GetItemInfo(item) end
end

local function StatsOf(link, itemID)
    local fn
    if C_Item and type(C_Item.GetItemStats) == "function" then
        fn = C_Item.GetItemStats
    elseif type(GetItemStats) == "function" then
        fn = GetItemStats
    end
    if not fn then return nil end
    local function Read(arg)
        if arg == nil then return nil end
        local ok, stats = pcall(fn, arg)
        if ok and type(stats) == "table" then return stats end
        return nil
    end
    return Read(link) or Read(itemID) or (itemID and Read("item:" .. tostring(itemID))) or nil
end

local function IDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function Remember(out, seen, item)
    if type(item) ~= "table" or not item.itemID or seen[item.itemID] then return end
    seen[item.itemID] = true
    out[#out + 1] = item
end

local function BankIDs()
    local bags = type(NUM_BAG_SLOTS) == "number" and NUM_BAG_SLOTS or 4
    local bankBags = type(NUM_BANKBAGSLOTS) == "number" and NUM_BANKBAGSLOTS or 7
    local main = type(BANK_CONTAINER) == "number" and BANK_CONTAINER or -1
    local ids = { main }
    for i = 1, bankBags do ids[#ids + 1] = bags + i end
    return ids
end

local function CarriedIDs()
    local n = type(NUM_BAG_SLOTS) == "number" and NUM_BAG_SLOTS or 4
    local ids = { 0 }
    for i = 1, n do ids[#ids + 1] = i end
    return ids
end

--- false when a link is present but its equip location is not cached yet.
local function ReadContainerItem(U, bag, slot, where)
    local link = U.GetContainerItemLink(bag, slot)
    local id = U.GetContainerItemID and U.GetContainerItemID(bag, slot) or nil
    if not link and not id then return nil end
    id = id or IDFromLink(link)
    local name, itemLink, _, _, _, _, _, _, equipLoc, _, _, _, subclassID = ItemInfo(link or id)
    if not equipLoc then
        PG.NoteUncached(id)
        return false
    end
    return {
        itemID = id,
        name = name,
        link = itemLink or link,
        equipLoc = equipLoc,
        subclassID = subclassID,
        where = where,
        bag = (where == "bag") and bag or nil,
        slot = (where == "bag") and slot or nil,
    }
end

local function CacheRecord(item)
    return {
        itemID = item.itemID,
        name = item.name,
        link = item.link,
        equipLoc = item.equipLoc,
        subclassID = item.subclassID,
    }
end

local function LoadBank(data)
    local saved = TA.charDB and TA.charDB[PG.CACHE_KEY]
    if type(saved) ~= "table" then return {} end
    local out = {}
    for _, row in ipairs(saved) do
        if type(row) == "table" and PG.IsProfessionEquipLoc(row.equipLoc, data) then
            out[#out + 1] = {
                itemID = row.itemID,
                name = row.name,
                link = row.link,
                equipLoc = row.equipLoc,
                subclassID = row.subclassID,
                where = "bank",
                role = PG.RoleFor(row.equipLoc, data),
            }
        end
    end
    return out
end

local function SaveBank(items)
    if type(TA.charDB) ~= "table" then return end
    local out = {}
    for _, item in ipairs(items or {}) do
        if item.equipLoc and item.itemID then out[#out + 1] = CacheRecord(item) end
    end
    TA.charDB[PG.CACHE_KEY] = out
end

--- nil, false when the bank is closed. A list and an unresolved flag when open.
local function ReadBankLive(data)
    local U = TA.Utils
    if not U or type(U.GetContainerNumSlots) ~= "function" or type(U.GetContainerItemLink) ~= "function" then
        return nil, false
    end
    local ids = BankIDs()
    local mainSlots = U.GetContainerNumSlots(ids[1]) or 0
    if mainSlots <= 0 then return nil, false end
    local found, unresolved = {}, false
    for _, bag in ipairs(ids) do
        local slots = U.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local item = ReadContainerItem(U, bag, slot, "bank")
            if item == false then
                unresolved = true
            elseif item and PG.IsProfessionEquipLoc(item.equipLoc, data) then
                item.role = PG.RoleFor(item.equipLoc, data)
                found[#found + 1] = item
            end
        end
    end
    return found, unresolved
end

function PG:CaptureBank()
    local data = TA.Data and TA.Data.ProfessionGear
    local live, unresolved = ReadBankLive(data)
    local nextCache = PG.NextBankCache(LoadBank(data), live, unresolved)
    if live ~= nil and not unresolved then SaveBank(nextCache) end
    return nextCache
end

local function Accepts(item, professionEnum, data)
    if not item or not PG.IsProfessionEquipLoc(item.equipLoc, data) then return false end
    if not professionEnum or item.subclassID == nil then return false end
    return item.subclassID == professionEnum
end

function PG.NoteUncached(itemID)
    if not itemID then return end
    PG._needItemInfo = true
    PG._asked = PG._asked or {}
    if PG._asked[itemID] then return end
    PG._asked[itemID] = true
    local U = TA.Utils
    if U and U.RequestItemInfo then U.RequestItemInfo(itemID) end
end

local function AttachStats(item)
    if item.stats then return item.stats end
    local stats = StatsOf(item.link, item.itemID)
    item.stats = stats
    if not stats then PG.NoteUncached(item.itemID) end
    return stats
end

local function ListedItems(data, professionID, expansion)
    local out = {}
    for _, row in ipairs(data and data.items or {}) do
        if type(row) == "table" and row.itemID and row.profession == professionID and row.slot then
            local okExp = (not row.expansion) or (expansion and row.expansion == expansion)
            if okExp then
                local equipLoc
                for _, slot in ipairs(data.slots or {}) do
                    if slot.role == row.slot then equipLoc = slot.equipLoc break end
                end
                out[#out + 1] = {
                    itemID = row.itemID,
                    name = row.name,
                    link = row.link,
                    equipLoc = equipLoc,
                    role = row.slot,
                    where = "list",
                    source = row.source,
                    profession = professionID,
                }
            end
        end
    end
    return out
end

function PG.CollectCandidates(data, professionID, professionEnum)
    local out, seen = {}, {}
    local U = TA.Utils
    if professionEnum and U and U.GetContainerNumSlots and U.GetContainerItemLink then
        for _, bag in ipairs(CarriedIDs()) do
            local slots = U.GetContainerNumSlots(bag) or 0
            for slot = 1, slots do
                local item = ReadContainerItem(U, bag, slot, "bag")
                if item == false then
                    PG._needItemInfo = true
                elseif Accepts(item, professionEnum, data) then
                    item.role = PG.RoleFor(item.equipLoc, data)
                    Remember(out, seen, item)
                end
            end
        end
    end
    local live, unresolved = ReadBankLive(data)
    local cached = LoadBank(data)
    local bank = PG.NextBankCache(cached, live, unresolved)
    if live ~= nil and not unresolved then SaveBank(bank) end
    if professionEnum then
        local bankItems = {}
        if live == nil or unresolved then
            for _, item in ipairs(bank or {}) do bankItems[#bankItems + 1] = item end
            if unresolved and live then
                for _, item in ipairs(live) do bankItems[#bankItems + 1] = item end
            end
        else
            for _, item in ipairs(live) do bankItems[#bankItems + 1] = item end
        end
        for _, item in ipairs(bankItems) do
            if Accepts(item, professionEnum, data) then
                item.role = item.role or PG.RoleFor(item.equipLoc, data)
                item.where = "bank"
                item.bag, item.slot = nil, nil
                Remember(out, seen, item)
            end
        end
    end
    for _, item in ipairs(ListedItems(data, professionID, PG.CurrentExpansion())) do
        Remember(out, seen, item)
    end
    for _, item in ipairs(out) do
        AttachStats(item)
        if (not item.name or item.name == "") and item.itemID then
            local name = ItemInfo(item.link or item.itemID)
            if type(name) == "string" and name ~= "" then item.name = name end
        end
    end
    return out
end

local function EquippedItem(slotID)
    local link
    if type(GetInventoryItemLink) == "function" then
        link = GetInventoryItemLink("player", slotID)
    end
    local id
    if type(GetInventoryItemID) == "function" then
        id = GetInventoryItemID("player", slotID)
    end
    id = id or IDFromLink(link)
    if not link and not id then return nil end
    local name = ItemInfo(link or id)
    local stats = StatsOf(link, id)
    if (link or id) and not stats then PG.NoteUncached(id) end
    return {
        itemID = id,
        name = (type(name) == "string" and name ~= "") and name or nil,
        link = link,
        stats = stats,
    }
end

local function Pick(candidates, role, weights, margin, equippedStats, used)
    local best, bestScore
    local eqScore = PG.Score(equippedStats, weights)
    for _, item in ipairs(candidates) do
        if item.role == role and item.itemID and not used[item.itemID] and item.stats then
            local score = PG.Score(item.stats, weights)
            if PG.Beats(score, eqScore, margin) and (not best or score > bestScore) then
                best = item
                bestScore = score
            end
        end
    end
    return best
end

--- nil when this client has no profession gear slots for the card.
function PG.Plan(card)
    if type(card) ~= "table" or not card.id then return nil end
    local prof, slots = PG.LookupProfession(card.id)
    if not slots then return nil end
    local data = TA.Data and TA.Data.ProfessionGear
    local defs = data and data.slots or {}
    local spent = PG.ReadSpent(card)
    local weights, sources = PG.BuildWeights(data, spent)
    local margin = data and data.margin or 0
    local candidates = data and PG.CollectCandidates(data, card.id, prof) or {}
    local equipped = {}
    local used = {}
    for i, slotID in ipairs(slots) do
        local item = EquippedItem(slotID)
        equipped[i] = item
        if item and item.itemID then used[item.itemID] = true end
    end
    local view = { slots = {} }
    for i, slotID in ipairs(slots) do
        local def = defs[i] or {}
        local item = equipped[i]
        local best
        if def.role then
            best = Pick(candidates, def.role, weights, margin, item and item.stats, used)
        end
        if best and best.itemID then used[best.itemID] = true end
        local why = {}
        if best and data then
            why = PG.Reasons(data, best.stats, item and item.stats, sources)
            if type(best.source) == "string" and best.source ~= "" then
                why[#why + 1] = best.source
            end
        end
        local equippedName = item and item.name
        if item and (not equippedName or equippedName == "") then
            if item.itemID then equippedName = "item:" .. tostring(item.itemID) end
        end
        local suggestion, plain
        if best then
            plain = best.name
            if not plain or plain == "" then plain = "item:" .. tostring(best.itemID) end
            suggestion = PG.MarkedName(plain)
        end
        view.slots[#view.slots + 1] = {
            label = def.label or "",
            equipped = equippedName or "Empty",
            empty = not equippedName,
            suggestion = suggestion,
            suggestionPlain = plain,
            why = why,
            equip = best and PG.EquipSetup(best) or nil,
            slotID = slotID,
        }
    end
    return view
end

function PG:FadeSecureButtons()
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.SetAlpha then btn:SetAlpha(0) end
        if btn.Disable then btn:Disable() end
    end
end

function PG:ReleaseSecureButtons()
    if PG.CombatLocked() then
        self:FadeSecureButtons()
        return
    end
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.Hide then btn:Hide() end
        if btn.SetParent then btn:SetParent(nil) end
    end
    self._secureButtons = {}
end

function PG:LockEquipButtons()
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.Disable then btn:Disable() end
        if btn.label and btn.label.Hide then btn.label:Hide() end
        if btn.lock and btn.lock.Show then btn.lock:Show() end
    end
end

function PG:ConfigureEquipButtons()
    if PG.CombatLocked() then
        self._redrawAfterCombat = true
        return
    end
    for _, btn in ipairs(self._secureButtons or {}) do
        PG.ArmEquip(btn, btn._setup, false)
    end
end

function PG.ArmEquip(btn, setup, locked)
    if not btn then return false end
    btn._setup = setup
    local combat = locked or PG.CombatLocked()
    if combat then
        if btn.Disable then btn:Disable() end
        if btn.label and btn.label.Hide then btn.label:Hide() end
        if btn.lock and btn.lock.Show then btn.lock:Show() end
        return false
    end
    if setup and btn.SetAttribute then
        btn:SetAttribute("type", "item")
        btn:SetAttribute("item", setup)
    end
    if btn.Enable then btn:Enable() end
    if btn.SetAlpha then btn:SetAlpha(1) end
    if btn.label and btn.label.Show then btn.label:Show() end
    if btn.lock and btn.lock.Hide then btn.lock:Hide() end
    return true
end

local function MakeEquipButton(anchor, setup)
    local template = "SecureActionButtonTemplate"
    if BackdropTemplateMixin then
        template = "SecureActionButtonTemplate,BackdropTemplate"
    end
    local parent = UIParent or anchor
    local btn = CreateFrame("Button", nil, parent, template)
    btn:SetSize(64, 22)
    local strata = anchor.GetFrameStrata and anchor:GetFrameStrata()
    if type(strata) ~= "string" then strata = "HIGH" end
    if btn.SetFrameStrata then btn:SetFrameStrata(strata) end
    local level = anchor.GetFrameLevel and anchor:GetFrameLevel()
    if type(level) ~= "number" then level = 1 end
    if btn.SetFrameLevel then btn:SetFrameLevel(level + 20) end
    if btn.RegisterForClicks then btn:RegisterForClicks("LeftButtonUp") end
    if btn.SetPoint then btn:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0) end
    local label = btn:CreateFontString(nil, "OVERLAY")
    if label.SetFont then
        local face = _G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
        label:SetFont(face, 10, "")
    end
    if label.SetPoint then label:SetPoint("CENTER") end
    if label.SetText then label:SetText("Equip") end
    btn.label = label
    local lock = btn:CreateTexture(nil, "OVERLAY")
    if lock.SetSize then lock:SetSize(16, 16) end
    if lock.SetPoint then lock:SetPoint("CENTER") end
    if lock.SetTexture then lock:SetTexture(PG.LOCK_TEXTURE) end
    if lock.Hide then lock:Hide() end
    btn.lock = lock
    PG._secureButtons = PG._secureButtons or {}
    PG._secureButtons[#PG._secureButtons + 1] = btn
    local combat = PG.CombatLocked()
    PG.ArmEquip(btn, setup, combat)
    if combat then PG._redrawAfterCombat = true end
    return btn
end

function PG:Begin()
    self:ReleaseSecureButtons()
end

function PG:Draw(parent, y, card)
    if not parent then return y end
    local view = PG.Plan(card)
    if not view then return y end
    local L = TA.Layout
    if not L or not L.ProfessionGearRow then return y end
    local nextY, row = L:ProfessionGearRow(parent, y, view)
    if row and row.cols and CreateFrame then
        for _, col in ipairs(row.cols) do
            if col._equip then MakeEquipButton(col, col._equip) end
        end
    end
    return nextY or y
end

function PG:Redraw()
    if PG.CombatLocked() then
        self._redrawAfterCombat = true
        self:LockEquipButtons()
        return
    end
    local ui = TA.UI
    if not (ui and ui.activeTab == "professions" and ui.contentChild) then return end
    local board = TA.GetModule and TA:GetModule("ProfessionBoard")
    if board and board.Render then
        board:Render(ui.contentChild, ui.sideChild)
    end
end

PG.Events = {
    "BAG_UPDATE",
    "GET_ITEM_INFO_RECEIVED",
    "UNIT_INVENTORY_CHANGED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED",
}

function PG:OnEvent(event)
    if event == "PLAYER_REGEN_DISABLED" then
        self:LockEquipButtons()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if self._redrawAfterCombat then
            self._redrawAfterCombat = nil
            self:Redraw()
        else
            self:ConfigureEquipButtons()
        end
        return
    end
    if event == "GET_ITEM_INFO_RECEIVED" then
        if not self._needItemInfo then return end
        self._needItemInfo = false
        self:Redraw()
        return
    end
    if event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED" or event == "PLAYERBANKSLOTS_CHANGED" then
        self:CaptureBank()
        self:Redraw()
        return
    end
    if event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
        self:Redraw()
    end
end

function PG:Init()
    self._secureButtons = {}
end
