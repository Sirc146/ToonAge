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
-- GetSpellName(id)    -> string|nil
-- GetSpellTexture(id) -> number|nil (icon file id)
-- GetSpellInfo(id)    -> the legacy multi-return, on every client:
--   name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon
-- C_Spell.GetSpellInfo has two shapes. Retail returns a table (or nil when
-- the spell is missing). Rank has no field there, so it is nil, and
-- originalIcon is originalIconID. Some clients still return the legacy
-- multi-value from that same function: name, rank, icon, castTime, minRange,
-- maxRange, spellID, originalIcon. Both come back in that order. Callers
-- that write `local name, _, icon = GetSpellInfo(id)` keep working.
-- GetSpellCooldown(id) -> start, duration, enabled, modRate
-- isEnabled on the C_Spell table is a boolean. The legacy third value is
-- 1 or 0. A secret is returned as-is: comparing it would throw.

local function LegacyEnabled(v)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, v)
        if ok and secret == true then return v end
    end
    if v == true then return 1 end
    if v == false then return 0 end
    return v
end

function C.GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    if GetSpellInfo then return (GetSpellInfo(spellID)) end
    return nil
end

function C.GetSpellTexture(spellID)
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local info, _, icon = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" then return info.iconID end
        if icon ~= nil then return icon end
    end
    if type(GetSpellTexture) == "function" then return GetSpellTexture(spellID) end
    return nil
end

function C.GetSpellInfo(spellID)
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local a, b, c, d, e, f, g, h = C_Spell.GetSpellInfo(spellID)
        if a == nil then return nil end
        if type(a) == "table" then
            return a.name, nil, a.iconID, a.castTime,
                a.minRange, a.maxRange, a.spellID, a.originalIconID
        end
        return a, b, c, d, e, f, g, h
    end
    if type(GetSpellInfo) == "function" then
        return GetSpellInfo(spellID)
    end
    return nil
end

function C.GetSpellCooldown(spellID)
    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
        if a == nil then return nil end
        if type(a) == "table" then
            return a.startTime, a.duration, LegacyEnabled(a.isEnabled), a.modRate
        end
        return a, b, c, d
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

--- true, false, or nil when no spell API answered. Each lookup is pcall'd.
--- IsPlayerSpell first, then IsSpellKnown, then C_SpellBook.IsSpellKnown.
--- A throw is a miss for that variant, not an error for the caller.
function C.PlayerKnowsSpell(spellID)
    if type(spellID) ~= "number" then return nil end
    local answered = false
    if type(IsPlayerSpell) == "function" then
        local ok, known = pcall(function() return IsPlayerSpell(spellID) end)
        if ok and known == true then return true end
        if ok and known == false then answered = true end
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(function() return IsSpellKnown(spellID) end)
        if ok and known == true then return true end
        if ok and known == false then answered = true end
    end
    if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
        local ok, known = pcall(function() return C_SpellBook.IsSpellKnown(spellID) end)
        if ok and known == true then return true end
        if ok and known == false then answered = true end
    end
    if answered then return false end
    return nil
end

-- ── Items ──────────────────────────────────────────────────────────────────

local function ValueUnusable(v)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, v)
        if not ok or secret == true then return true end
    end
    return false
end

function C.PlayerGUID()
    if TA and TA.HasAPI and not TA:HasAPI("UnitGUID") then return nil end
    if type(UnitGUID) ~= "function" then return nil end
    local ok, guid = pcall(function() return UnitGUID("player") end)
    if not ok or ValueUnusable(guid) or type(guid) ~= "string" then return nil end
    local okBlank, blank = pcall(function() return guid == "" end)
    if not okBlank or blank then return nil end
    return guid
end

function C.ClientBuild()
    if TA and TA.HasAPI and not TA:HasAPI("GetBuildInfo") then return {} end
    if type(GetBuildInfo) ~= "function" then return {} end
    local ok, version, build, _, iface = pcall(function() return GetBuildInfo() end)
    if not ok then return {} end
    local function plain(v)
        if ValueUnusable(v) then return nil end
        if type(v) ~= "string" and type(v) ~= "number" then return nil end
        return v
    end
    return { version = plain(version), build = plain(build), interface = plain(iface) }
end

function C.ReadTradeSkillRecipes()
    if TA and TA.HasAPI and not TA:HasAPI("C_TradeSkillUI.GetAllRecipeIDs") then
        return { status = "unavailable" }
    end
    if not (C_TradeSkillUI and type(C_TradeSkillUI.GetAllRecipeIDs) == "function"
        and type(C_TradeSkillUI.GetRecipeInfo) == "function") then
        return { status = "unavailable" }
    end
    local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if not ok or type(ids) ~= "table" or ValueUnusable(ids) then
        return { status = "unreadable", api = "C_TradeSkillUI" }
    end
    local professionID, withheld
    if type(C_TradeSkillUI.GetBaseProfessionInfo) == "function" then
        local okBase, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if okBase and type(base) == "table" and not ValueUnusable(base) then
            local pid = base.professionID
            if not ValueUnusable(pid) and type(pid) == "number" and pid == pid then
                professionID = pid
            end
        end
    end
    local rows = {}
    for _, id in ipairs(ids) do
        if ValueUnusable(id) or type(id) ~= "number" then
            withheld = true
        else
            local okRow, info = pcall(C_TradeSkillUI.GetRecipeInfo, id)
            if not okRow or type(info) ~= "table" or ValueUnusable(info) then
                withheld = true
            else
                local learned, name = info.learned, info.name
                if ValueUnusable(learned) or ValueUnusable(name) then
                    withheld = true
                else
                    local plainName
                    if type(name) == "string" then
                        local okName, blank = pcall(function() return name == "" end)
                        if okName and not blank then plainName = name end
                    end
                    rows[#rows + 1] = { id = id, name = plainName, learned = (learned == true) and true or nil }
                end
            end
        end
    end
    return {
        status = "read", api = "C_TradeSkillUI", professionID = professionID,
        rows = rows, withheld = withheld,
    }
end

function C.GetItemInfo(item)
    if C_Item and type(C_Item.GetItemInfo) == "function" then
        return C_Item.GetItemInfo(item)
    end
    if type(GetItemInfo) == "function" then return GetItemInfo(item) end
    return nil
end

--- True when the value is secret or the predicate itself fails.
--- A predicate error is not permission to compare the value.
local function SecretValue(v)
    if v == nil or type(issecretvalue) ~= "function" then return false end
    local ok, secret = pcall(issecretvalue, v)
    if not ok then return true end
    return secret == true
end

--- Nil when the flag is secret. A missing flag is false.
local function PlainFlag(v)
    if SecretValue(v) then return nil end
    if v == nil then return false end
    return v and true or false
end

--- How many faction rows the client will return. Nil when neither API exists,
--- or when the count is secret. Zero is a real empty list, not a missing function.
function C.GetNumFactions()
    local fn = FirstFn(C_Reputation and C_Reputation.GetNumFactions, GetNumFactions)
    if not fn then return nil end
    local ok, n = pcall(fn)
    if not ok or SecretValue(n) or type(n) ~= "number" then return nil end
    return n
end

--- One faction row. Retail's table and the classic multi-return are both
--- normalized. Nil when that index is empty or neither API exists.
function C.GetFactionDataByIndex(index)
    if type(index) ~= "number" then return nil end
    if C_Reputation and type(C_Reputation.GetFactionDataByIndex) == "function" then
        local ok, data = pcall(C_Reputation.GetFactionDataByIndex, index)
        if ok and type(data) == "table" then
            if SecretValue(data.isHeader) then return nil end
            return {
                name = data.name,
                factionID = data.factionID,
                reaction = data.reaction,
                currentStanding = data.currentStanding,
                currentReactionThreshold = data.currentReactionThreshold,
                nextReactionThreshold = data.nextReactionThreshold,
                isHeader = PlainFlag(data.isHeader),
                isChild = PlainFlag(data.isChild),
                isCollapsed = PlainFlag(data.isCollapsed),
            }
        end
    end
    if type(GetFactionInfo) == "function" then
        local ok, name, _, standingID, barMin, barMax, barValue, _, _, isHeader, isCollapsed, _, _, isChild, factionID =
            pcall(GetFactionInfo, index)
        if ok and not SecretValue(name) and type(name) == "string" and name ~= "" then
            if SecretValue(isHeader) then return nil end
            return {
                name = name,
                factionID = factionID,
                reaction = standingID,
                currentStanding = barValue,
                currentReactionThreshold = barMin,
                nextReactionThreshold = barMax,
                isHeader = PlainFlag(isHeader),
                isChild = PlainFlag(isChild),
                isCollapsed = PlainFlag(isCollapsed),
            }
        end
    end
    return nil
end

--- Open collapsed headers so the walk can see the factions under them.
--- False when this client has neither function.
function C.ExpandAllFactionHeaders()
    local fn = FirstFn(C_Reputation and C_Reputation.ExpandAllFactionHeaders, ExpandAllFactionHeaders)
    if not fn then return false end
    local ok = pcall(fn)
    return ok and true or false
end

--- Whether this client can open every header and close one again.
--- The wrappers above exist even when the client functions do not.
function C.FactionHeadersCanToggle()
    local expand = FirstFn(C_Reputation and C_Reputation.ExpandAllFactionHeaders, ExpandAllFactionHeaders)
    local collapse = FirstFn(C_Reputation and C_Reputation.CollapseFactionHeader, CollapseFactionHeader)
    return expand ~= nil, collapse ~= nil
end

--- Put one header back. False when this client has neither function.
function C.CollapseFactionHeader(index)
    local fn = FirstFn(C_Reputation and C_Reputation.CollapseFactionHeader, CollapseFactionHeader)
    if not fn or type(index) ~= "number" then return false end
    local ok = pcall(fn, index)
    return ok and true or false
end

local function ApiAllowed(path)
    if not (TA and TA.HasAPI) then return true end
    return TA:HasAPI(path) and true or false
end

function C.GetItemStats(itemLink)
    if not itemLink then return nil end
    local nsOk = ApiAllowed("C_Item.GetItemStats")
    local glOk = ApiAllowed("GetItemStats")
    if not nsOk and not glOk then return nil end
    -- C_Item first, then the global. Both calls sit inside pcall. A failed
    -- namespaced call falls through; a nil answer does not, matching the
    -- previous "return whatever the first present API returned".
    if nsOk and C_Item and type(C_Item.GetItemStats) == "function" then
        local ok, stats = pcall(function() return C_Item.GetItemStats(itemLink) end)
        if ok then return stats end
    end
    if glOk and type(GetItemStats) == "function" then
        local ok, stats = pcall(function() return GetItemStats(itemLink) end)
        if ok then return stats end
    end
    return nil
end

--- Equipped item link. Nil when the slot is empty or this client has no answer.
function C.GetInventoryItemLink(unit, slot)
    if not ApiAllowed("GetInventoryItemLink") then return nil end
    if type(GetInventoryItemLink) ~= "function" or type(slot) ~= "number" then return nil end
    local ok, link = pcall(function() return GetInventoryItemLink(unit or "player", slot) end)
    if not ok or type(link) ~= "string" or link == "" then return nil end
    return link
end

--- Loot window. Nil when the client has no loot API. Never calls a missing global.
function C.GetNumLootItems()
    if not ApiAllowed("GetNumLootItems") then return nil end
    if type(GetNumLootItems) ~= "function" then return nil end
    local ok, n = pcall(function() return GetNumLootItems() end)
    if not ok or type(n) ~= "number" then return nil end
    return n
end

function C.GetLootSlotLink(slot)
    if not ApiAllowed("GetLootSlotLink") then return nil end
    if type(GetLootSlotLink) ~= "function" then return nil end
    local ok, link = pcall(function() return GetLootSlotLink(slot) end)
    if not ok or type(link) ~= "string" or link == "" then return nil end
    return link
end

--- Quest reward and choice items. kind is the token the client documents
--- ("choice" or "reward"). Nil when that call is absent.
function C.GetQuestItemLink(kind, index)
    if not ApiAllowed("GetQuestItemLink") then return nil end
    if type(GetQuestItemLink) ~= "function" then return nil end
    if type(kind) ~= "string" or type(index) ~= "number" then return nil end
    local ok, link = pcall(function() return GetQuestItemLink(kind, index) end)
    if not ok or type(link) ~= "string" or link == "" then return nil end
    return link
end

function C.GetNumQuestChoices()
    if not ApiAllowed("GetNumQuestChoices") then return nil end
    if type(GetNumQuestChoices) ~= "function" then return nil end
    local ok, n = pcall(function() return GetNumQuestChoices() end)
    if not ok or type(n) ~= "number" then return nil end
    return n
end

function C.GetNumQuestRewards()
    if not ApiAllowed("GetNumQuestRewards") then return nil end
    if type(GetNumQuestRewards) ~= "function" then return nil end
    local ok, n = pcall(function() return GetNumQuestRewards() end)
    if not ok or type(n) ~= "number" then return nil end
    return n
end

--- Nil when the item is uncached or neither API exists. Never calls a nil.
function C.GetItemInfoInstant(item)
    if C_Item and type(C_Item.GetItemInfoInstant) == "function" then
        return C_Item.GetItemInfoInstant(item)
    end
    if type(GetItemInfoInstant) == "function" then return GetItemInfoInstant(item) end
    return nil
end

--- Extra flags (includeBank and the rest) are passed through. A missing API
--- returns nil, which is not the same as "the player has zero".
function C.GetItemCount(item, ...)
    if C_Item and type(C_Item.GetItemCount) == "function" then
        return C_Item.GetItemCount(item, ...)
    end
    if type(GetItemCount) == "function" then return GetItemCount(item, ...) end
    return nil
end

--- Bag count, then the extra amount sitting in the bank.
--- Variants, each pcall'd, in order:
---   C_Item.GetItemCount, C_Container.GetItemCount (only when that call
---   accepts an item id and returns a number), then global GetItemCount.
--- A throw or a non-number skips that variant. Nil bags means every variant
--- was missing, which the caller shows as "count unavailable".
--- The first return is bags only (includeBank false). The second is the
--- bank remainder, or nil when the bank flag could not be asked. Bank is
--- never folded into the bag count.
--- @return number|nil bags, number|nil bank, string|nil which
function C.ItemCounts(itemID)
    if type(itemID) ~= "number" then return nil, nil, nil end

    local function finish(bags, withBank, which)
        if type(bags) ~= "number" then return nil end
        local bank
        if type(withBank) == "number" and withBank >= bags then
            bank = withBank - bags
        end
        return bags, bank, which
    end

    local function from(ask, which)
        local ok, bags = ask(false)
        if not ok or type(bags) ~= "number" then
            ok, bags = ask(nil)
        end
        if not (ok and type(bags) == "number") then return nil end
        local okBank, withBank = ask(true)
        if not okBank then withBank = nil end
        return finish(bags, withBank, which)
    end

    if C_Item and type(C_Item.GetItemCount) == "function" then
        local bags, bank, which = from(function(includeBank)
            if includeBank == nil then
                return pcall(C_Item.GetItemCount, itemID)
            end
            return pcall(C_Item.GetItemCount, itemID, includeBank)
        end, "C_Item.GetItemCount")
        if bags ~= nil then return bags, bank, which end
    end

    -- C_Container.GetItemCount is not a documented bag API. Use it only when
    -- the call accepts an item id and comes back as a number.
    if C_Container and type(C_Container.GetItemCount) == "function" then
        local bags, bank, which = from(function(includeBank)
            if includeBank == nil then
                return pcall(C_Container.GetItemCount, itemID)
            end
            return pcall(C_Container.GetItemCount, itemID, includeBank)
        end, "C_Container.GetItemCount")
        if bags ~= nil then return bags, bank, which end
    end

    if type(GetItemCount) == "function" then
        local bags, bank, which = from(function(includeBank)
            if includeBank == nil then
                return pcall(GetItemCount, itemID)
            end
            return pcall(GetItemCount, itemID, includeBank)
        end, "GetItemCount")
        if bags ~= nil then return bags, bank, which end
    end

    return nil, nil, nil
end

function C.GetDetailedItemLevelInfo(item)
    if C_Item and type(C_Item.GetDetailedItemLevelInfo) == "function" then
        return C_Item.GetDetailedItemLevelInfo(item)
    end
    if type(GetDetailedItemLevelInfo) == "function" then return GetDetailedItemLevelInfo(item) end
    return nil
end

function C.IsEquippableItem(item)
    if C_Item and type(C_Item.IsEquippableItem) == "function" then
        return C_Item.IsEquippableItem(item)
    end
    if type(IsEquippableItem) == "function" then return IsEquippableItem(item) end
    return nil
end

--- r, g, b, hex. Retail 10.2.6+, Forever, Mists, TBC, and Era all return
--- those four values from C_Item.GetItemQualityColor and from the global.
function C.GetItemQualityColor(quality)
    if C_Item and type(C_Item.GetItemQualityColor) == "function" then
        return C_Item.GetItemQualityColor(quality)
    end
    if type(GetItemQualityColor) == "function" then return GetItemQualityColor(quality) end
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

--- name, title, notes, enabled, loadable, reason, security. Nil when the
--- client has neither the namespaced call nor the classic global.
function C.GetAddOnInfo(name)
    if C_AddOns and type(C_AddOns.GetAddOnInfo) == "function" then
        return C_AddOns.GetAddOnInfo(name)
    end
    if type(GetAddOnInfo) == "function" then
        return GetAddOnInfo(name)
    end
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

-- ── Map point → world yards ────────────────────────────────────────────────
-- C_Map.GetWorldPosFromMapPos returns continentID and a vector whose x points
-- north and whose y points west, already in yards. The arrow uses that for
-- distance and bearing. A missing API returns nil so the caller can hide the
-- distance instead of inventing a zone-sized yard.

--- @param mapID number
--- @param x number map fraction 0–1, east
--- @param y number map fraction 0–1, south
--- @return number|nil continentID
--- @return number|nil north  world x, yards
--- @return number|nil west   world y, yards
function C.WorldPosFromMapPos(mapID, x, y)
    if type(mapID) ~= "number" or mapID == 0 then return nil end
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    if TA.HasAPI and not TA:HasAPI("C_Map.GetWorldPosFromMapPos") then return nil end
    if TA.HasAPI and not TA:HasAPI("CreateVector2D") then return nil end
    if not (C_Map and type(C_Map.GetWorldPosFromMapPos) == "function") then return nil end
    if type(CreateVector2D) ~= "function" then return nil end
    local okVec, vec = pcall(CreateVector2D, x, y)
    if not okVec or not vec then return nil end
    local ok, continentID, world = pcall(C_Map.GetWorldPosFromMapPos, mapID, vec)
    if not ok or continentID == nil then return nil end
    if type(world) ~= "table" and type(world) ~= "userdata" then return nil end
    local north, west = world.x, world.y
    if type(north) ~= "number" or type(west) ~= "number" then
        if type(world.GetXY) == "function" then
            local okXY, a, b = pcall(world.GetXY, world)
            if okXY then north, west = a, b end
        end
    end
    if type(north) ~= "number" or type(west) ~= "number" then return nil end
    return continentID, north, west
end

-- ── Player identity ────────────────────────────────────────────────────────
-- UnitName, UnitClass and UnitRace. The sidebar helpers in Core/Utils.lua
-- call these rather than the globals. ApiGuard is asked first; a missing
-- function, a failed call, or a value that is not a plain string comes back
-- as "". A secret is not read and not converted.

local function Shown(v)
    local U = TA.Utils
    if U and type(U.IsSecret) == "function" and U.IsSecret(v) then return "" end
    if type(v) ~= "string" then return "" end
    return v
end

--- @return string name, or "" when the client has no answer
function C.UnitName(unit)
    if TA.HasAPI and not TA:HasAPI("UnitName") then return "" end
    if type(UnitName) ~= "function" then return "" end
    local ok, name = pcall(UnitName, unit or "player")
    if not ok then return "" end
    return Shown(name)
end

--- Game order: localized name, then English token (for example "Mage", "MAGE").
--- @return string localized, string token
function C.UnitClass(unit)
    if TA.HasAPI and not TA:HasAPI("UnitClass") then return "", "" end
    if type(UnitClass) ~= "function" then return "", "" end
    local ok, localized, token = pcall(UnitClass, unit or "player")
    if not ok then return "", "" end
    return Shown(localized), Shown(token)
end

--- "Horde" or "Alliance". Nil when the client will not say. A third faction
--- is not treated as either of those two.
function C.PlayerFaction()
    if TA.HasAPI and not TA:HasAPI("UnitFactionGroup") then return nil end
    if type(UnitFactionGroup) ~= "function" then return nil end
    local ok, _, token = pcall(function() return UnitFactionGroup("player") end)
    if not ok or type(token) ~= "string" then return nil end
    if token ~= "Horde" and token ~= "Alliance" then return nil end
    return token
end

--- Bag count. Nil means the count could not be read, which is not zero.
--- Each variant is called only when it is a function, and only inside pcall.
--- C_Item, then C_Container, then the global. The first number wins.
function C.CountItem(itemID)
    if type(itemID) ~= "number" then return nil end
    local function one(fn)
        if type(fn) ~= "function" then return nil end
        local ok, n = pcall(fn, itemID)
        if not ok or type(n) ~= "number" or n ~= n then return nil end
        return n
    end
    if not (TA.HasAPI and not TA:HasAPI("C_Item.GetItemCount")) then
        if C_Item and type(C_Item.GetItemCount) == "function" then
            local n = one(C_Item.GetItemCount)
            if n ~= nil then return n end
        end
    end
    if not (TA.HasAPI and not TA:HasAPI("C_Container.GetItemCount")) then
        if C_Container and type(C_Container.GetItemCount) == "function" then
            local n = one(C_Container.GetItemCount)
            if n ~= nil then return n end
        end
    end
    if TA.HasAPI and not TA:HasAPI("GetItemCount") then return nil end
    if type(GetItemCount) ~= "function" then return nil end
    local ok, n = pcall(function() return GetItemCount(itemID) end)
    if not ok or type(n) ~= "number" or n ~= n then return nil end
    return n
end

--- Player map id. Nil when the call is missing or does not return a number.
function C.BestMapForUnit(unit)
    if TA.HasAPI and not TA:HasAPI("C_Map.GetBestMapForUnit") then return nil end
    if not (C_Map and type(C_Map.GetBestMapForUnit) == "function") then return nil end
    local ok, id = pcall(C_Map.GetBestMapForUnit, unit or "player")
    if not ok or type(id) ~= "number" or id == 0 then return nil end
    return id
end

--- Map fractions 0-1 for the player on a map. Nil when unread.
function C.PlayerMapFraction(mapID)
    if type(mapID) ~= "number" then return nil end
    if TA.HasAPI and not TA:HasAPI("C_Map.GetPlayerMapPosition") then return nil end
    if not (C_Map and type(C_Map.GetPlayerMapPosition) == "function") then return nil end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok or type(pos) ~= "table" or type(pos.GetXY) ~= "function" then return nil end
    local okXY, x, y = pcall(pos.GetXY, pos)
    if not okXY or type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

--- UnitPosition yards: continent, north, west. The 4th return is compared
--- with GetWorldPosFromMapPos's continent only by the caller. Nil if unread.
function C.PlayerWorldPosition()
    if TA.HasAPI and not TA:HasAPI("UnitPosition") then return nil end
    if type(UnitPosition) ~= "function" then return nil end
    local ok, north, west, _, cont = pcall(function() return UnitPosition("player") end)
    if not ok or type(north) ~= "number" or type(west) ~= "number" then return nil end
    if type(cont) ~= "number" then cont = nil end
    return cont, north, west
end

--- Blizzard's user waypoint. Both the waypoint and the supertrack call are
--- unverified on Forever 70888. Each runs only when type() is function, and
--- only inside pcall. A missing call returns false. The addon's own arrow
--- still points.
function C.TryUserWaypoint(mapID, x, y)
    if type(mapID) ~= "number" or mapID <= 0 then return false end
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    if type(C_Map) ~= "table" then return false end
    if type(C_Map.CanSetUserWaypointOnMap) == "function" then
        if not (TA.HasAPI and not TA:HasAPI("C_Map.CanSetUserWaypointOnMap")) then
            local okCan, can = pcall(C_Map.CanSetUserWaypointOnMap, mapID)
            if not okCan or can ~= true then return false end
        end
    end
    if type(C_Map.SetUserWaypoint) ~= "function" then return false end
    if TA.HasAPI and not TA:HasAPI("C_Map.SetUserWaypoint") then return false end
    if type(UiMapPoint) ~= "table" or type(UiMapPoint.CreateFromCoordinates) ~= "function" then
        return false
    end
    local okPoint, point = pcall(UiMapPoint.CreateFromCoordinates, mapID, x, y)
    if not okPoint or point == nil then return false end
    local okSet = pcall(C_Map.SetUserWaypoint, point)
    if not okSet then return false end
    if type(C_SuperTrack) == "table"
        and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        if not (TA.HasAPI and not TA:HasAPI("C_SuperTrack.SetSuperTrackedUserWaypoint")) then
            pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        end
    end
    return true
end

--- Game order: localized name, then English token (for example "Night Elf", "NightElf").
--- @return string localized, string token
function C.UnitRace(unit)
    if TA.HasAPI and not TA:HasAPI("UnitRace") then return "", "" end
    if type(UnitRace) ~= "function" then return "", "" end
    local ok, localized, token = pcall(UnitRace, unit or "player")
    if not ok then return "", "" end
    return Shown(localized), Shown(token)
end

-- ── Mage suggestion reads ────────────────────────────────────────────────
-- Cooldowns stay on GetSpellCooldown above. These classify the other reads
-- the Forever Mage suggestion frame needs. A missing function or a secret
-- value comes back as nil / "unknown"; the caller skips that rule.

local function TriState(path, fn, spellID)
    if TA and TA.HasAPI and not TA:HasAPI(path) then return "unknown" end
    if type(fn) ~= "function" then return "unknown" end
    local ok, value = pcall(fn, spellID)
    if not ok or SecretValue(value) then return "unknown" end
    if value == true or value == 1 then return "yes" end
    if value == false or value == 0 then return "no" end
    return "unknown"
end

--- Same yes / no / unknown split MageGuidance uses: IsPlayerSpell, then
--- IsSpellKnown. A yes from either wins. Unknown from either, with no yes,
--- stays unknown.
function C.SpellLearned(spellID)
    if SecretValue(spellID) or type(spellID) ~= "number" then return "unknown" end
    local first = TriState("IsPlayerSpell", IsPlayerSpell, spellID)
    local second = TriState("IsSpellKnown", IsSpellKnown, spellID)
    if first == "yes" or second == "yes" then return "yes" end
    if first == "unknown" or second == "unknown" then return "unknown" end
    if first == "no" and second == "no" then return "no" end
    return "unknown"
end

--- Current mana and maximum mana, still raw. The caller tests each one
--- with issecretvalue / canaccessvalue before dividing.
function C.PlayerMana()
    if type(UnitPower) ~= "function" or type(UnitPowerMax) ~= "function" then
        return nil, nil
    end
    if TA and TA.HasAPI and (not TA:HasAPI("UnitPower") or not TA:HasAPI("UnitPowerMax")) then
        return nil, nil
    end
    local powerType = 0
    if Enum and Enum.PowerType then
        local mana = Enum.PowerType.Mana
        local okType, kind = pcall(type, mana)
        if okType and kind == "number" and not SecretValue(mana) then
            powerType = mana
        end
    end
    local okCur, current = pcall(UnitPower, "player", powerType)
    local okMax, maxValue = pcall(UnitPowerMax, "player", powerType)
    if not okCur or not okMax then return nil, nil end
    return current, maxValue
end

local function AuraRow(name, applications)
    if SecretValue(name) or type(name) ~= "string" or name == "" then return nil, true end
    local count
    if not SecretValue(applications) and type(applications) == "number" then
        count = applications
    end
    return { name = name, applications = count }, false
end

--- Player or target auras. Nil when neither C_UnitAuras nor AuraUtil is
--- there, or when a name in the list is secret (the rule stays unknown).
--- An empty list is a real read with nothing present.
function C.ReadAuras(unit, filter)
    unit = unit or "player"
    filter = filter or "HELPFUL"
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function"
        and not (TA and TA.HasAPI and not TA:HasAPI("C_UnitAuras.GetAuraDataByIndex")) then
        local out = {}
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
            if not ok or SecretValue(aura) then return nil end
            if aura == nil then return out end
            if type(aura) ~= "table" then return nil end
            local row, blocked = AuraRow(aura.name, aura.applications)
            if blocked then return nil end
            if row then out[#out + 1] = row end
        end
        return out
    end
    if AuraUtil and type(AuraUtil.ForEachAura) == "function" then
        local out, blocked = {}, false
        local ok = pcall(AuraUtil.ForEachAura, unit, filter, nil, function(a, _, c)
            if blocked then return end
            local name, apps = a, c
            if type(a) == "table" then name, apps = a.name, a.applications end
            local row, stop = AuraRow(name, apps)
            if stop then blocked = true; return end
            if row then out[#out + 1] = row end
        end)
        if not ok or blocked then return nil end
        return out
    end
    return nil
end

--- Duel distance (distIndex 3, about 10 yards) stands in for "too close"
--- on the Frost Nova suggestion. Nil when the query is missing or secret.
function C.TargetInMelee(unit)
    unit = unit or "target"
    if type(UnitExists) == "function" then
        local ok, exists = pcall(UnitExists, unit)
        if ok and exists == false then return false end
        if not ok or SecretValue(exists) then return nil end
    end
    if TA and TA.HasAPI and not TA:HasAPI("CheckInteractDistance") then return nil end
    if type(CheckInteractDistance) ~= "function" then return nil end
    local ok, dist = pcall(CheckInteractDistance, unit, 3)
    if not ok or SecretValue(dist) then return nil end
    return dist
end

function C.InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    if not ok or SecretValue(locked) then return false end
    return locked and true or false
end

-- ── Scroll probe (read-only) ───────────────────────────────────────────────
-- Settings > Debug on Forever asks these. Every name goes through HasAPI and
-- a pcall. A missing name is "MISSING"; a thrown call is "ERROR: ...".
-- Waypoint setters are not wrapped here. The probe may ask ProbeType for
-- them and must not call them.

local function Resolve(path)
    if type(path) ~= "string" or path == "" then
        return nil, "ERROR: bad path"
    end
    if TA and TA.HasAPI and not TA:HasAPI(path) then
        return nil, "MISSING"
    end
    local ok, value = pcall(function()
        local node = _G
        for seg in string.gmatch(path, "[^%.]+") do
            if type(node) ~= "table" then return nil end
            local okI, child = pcall(function() return node[seg] end)
            if not okI then error(child, 0) end
            node = child
        end
        return node
    end)
    if not ok then
        local msg = tostring(value)
        if msg:sub(1, 7) ~= "ERROR: " then msg = "ERROR: " .. msg end
        return nil, msg
    end
    if value == nil then return nil, "MISSING" end
    return value, nil
end

--- type() of a dotted or global name. Never calls the value.
--- @return string  "function" | "MISSING" | "ERROR: ..." | other type() result
function C.ProbeType(path)
    local value, err = Resolve(path)
    if err then return err end
    local ok, kind = pcall(type, value)
    if not ok then return "ERROR: " .. tostring(kind) end
    if kind == "nil" then return "MISSING" end
    return kind
end

local function Pack(ok, ...)
    local n = select("#", ...)
    local t = { n = n }
    for i = 1, n do t[i] = select(i, ...) end
    return ok, t
end

--- Call `thunk` only when `path` resolves to a function.
--- @return string status  "ok" | "MISSING" | "ERROR: ..."
--- @return table|nil packed  { n = count, [i] = return } when status is "ok"
local function GuardedPack(path, thunk)
    local state = C.ProbeType(path)
    if state ~= "function" then
        if type(state) == "string" and state:sub(1, 7) == "ERROR: " then
            return state
        end
        return "MISSING"
    end
    if type(thunk) ~= "function" then return "ERROR: no call" end
    local ok, packed = Pack(pcall(thunk))
    if not ok then
        local msg = packed[1]
        if type(msg) ~= "string" then msg = tostring(msg) end
        if msg:sub(1, 7) ~= "ERROR: " then msg = "ERROR: " .. msg end
        return msg
    end
    return "ok", packed
end

function C.ProbeDate()
    local status, packed = GuardedPack("date", function() return date() end)
    if status ~= "ok" then return status end
    if type(packed) ~= "table" or packed[1] == nil then return "nil" end
    local ok, text = pcall(tostring, packed[1])
    if not ok then return "ERROR: " .. tostring(text) end
    return text
end

function C.ProbeGetBuildInfo()
    return GuardedPack("GetBuildInfo", function() return GetBuildInfo() end)
end

function C.ProbeBestMap()
    return GuardedPack("C_Map.GetBestMapForUnit", function()
        return C_Map.GetBestMapForUnit("player")
    end)
end

--- Player position on mapID. Does not call the reader when mapID is not a number.
--- @return string status  "ok" | "nil" | "MISSING" | "ERROR: ..."
--- @return number|nil x
--- @return number|nil y
function C.ProbeMapXY(mapID)
    if type(mapID) ~= "number" then return "nil" end
    local status, packed = GuardedPack("C_Map.GetPlayerMapPosition", function()
        return C_Map.GetPlayerMapPosition(mapID, "player")
    end)
    if status ~= "ok" then return status end
    if type(packed) ~= "table" or (packed.n or 0) == 0 or packed[1] == nil then
        return "nil"
    end
    local pos, second = packed[1], packed[2]
    if type(pos) == "number" then
        if type(second) ~= "number" then return "nil" end
        return "ok", pos, second
    end
    local ok, x, y = pcall(function()
        local kind = type(pos)
        if kind ~= "table" and kind ~= "userdata" then return nil, nil end
        if type(pos.x) == "number" and type(pos.y) == "number" then
            return pos.x, pos.y
        end
        if type(pos.GetXY) == "function" then return pos:GetXY() end
        return nil, nil
    end)
    if not ok then return "ERROR: " .. tostring(x) end
    if type(x) ~= "number" or type(y) ~= "number" then return "nil" end
    return "ok", x, y
end

function C.ProbeIsSpellKnown(spellID)
    return GuardedPack("IsSpellKnown", function() return IsSpellKnown(spellID) end)
end

function C.ProbeIsPlayerSpell(spellID)
    return GuardedPack("IsPlayerSpell", function() return IsPlayerSpell(spellID) end)
end

function C.ProbeQuestFlagNS(questID)
    return GuardedPack("C_QuestLog.IsQuestFlaggedCompleted", function()
        return C_QuestLog.IsQuestFlaggedCompleted(questID)
    end)
end

function C.ProbeQuestFlagGlobal(questID)
    return GuardedPack("IsQuestFlaggedCompleted", function()
        return IsQuestFlaggedCompleted(questID)
    end)
end

function C.ProbeSkillLine(skillID)
    return GuardedPack("C_SkillInfo.GetSkillLineInfoByID", function()
        return C_SkillInfo.GetSkillLineInfoByID(skillID)
    end)
end

--- Bags only: the second argument is includeBank false on every counter.
function C.ProbeCItemCount(itemID)
    return GuardedPack("C_Item.GetItemCount", function()
        return C_Item.GetItemCount(itemID, false)
    end)
end

function C.ProbeCContainerCount(itemID)
    return GuardedPack("C_Container.GetItemCount", function()
        return C_Container.GetItemCount(itemID, false)
    end)
end

function C.ProbeGlobalItemCount(itemID)
    return GuardedPack("GetItemCount", function()
        return GetItemCount(itemID, false)
    end)
end

-- ── Session journal readers ───────────────────────────────────────────────
-- WoW Forever's login-to-logout journal calls these and nothing else.
-- Each one asks ApiGuard first, then refuses to call a value that is not a
-- function, and swallows a throw. A missing API is nil, which the journal
-- skips. None of these run at file load.

function C.ServerTime()
    if TA.HasAPI and not TA:HasAPI("time") then return nil end
    if type(time) ~= "function" then return nil end
    local ok, t = pcall(time)
    if not ok or type(t) ~= "number" then return nil end
    return t
end

function C.FormatTime(t)
    if type(t) ~= "number" then return "" end
    if TA.HasAPI and not TA:HasAPI("date") then return tostring(t) end
    if type(date) ~= "function" then return tostring(t) end
    local ok, text = pcall(date, "%Y-%m-%d %H:%M", t)
    if not ok or type(text) ~= "string" or text == "" then return tostring(t) end
    return text
end

function C.PlayerXP()
    if TA.HasAPI and not TA:HasAPI("UnitXP") then return nil end
    if type(UnitXP) ~= "function" then return nil end
    local ok, v = pcall(function() return UnitXP("player") end)
    if not ok or type(v) ~= "number" then return nil end
    return v
end

function C.PlayerMoney()
    if TA.HasAPI and not TA:HasAPI("GetMoney") then return nil end
    if type(GetMoney) ~= "function" then return nil end
    local ok, v = pcall(function() return GetMoney() end)
    if not ok or type(v) ~= "number" then return nil end
    return v
end

function C.ZoneText()
    if TA.HasAPI and not TA:HasAPI("GetZoneText") then return nil end
    if type(GetZoneText) ~= "function" then return nil end
    local ok, v = pcall(function() return GetZoneText() end)
    if not ok or type(v) ~= "string" or v == "" then return nil end
    return v
end

function C.RealZoneText()
    if TA.HasAPI and not TA:HasAPI("GetRealZoneText") then return nil end
    if type(GetRealZoneText) ~= "function" then return nil end
    local ok, v = pcall(function() return GetRealZoneText() end)
    if not ok or type(v) ~= "string" or v == "" then return nil end
    return v
end

--- name, mapType, parentMapID. Nil when the call is missing or not a table.
function C.MapInfo(mapID)
    if type(mapID) ~= "number" or mapID <= 0 then return nil end
    if TA.HasAPI and not TA:HasAPI("C_Map.GetMapInfo") then return nil end
    if not (C_Map and type(C_Map.GetMapInfo) == "function") then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok or type(info) ~= "table" then return nil end
    local name = type(info.name) == "string" and info.name ~= "" and info.name or nil
    local mapType = type(info.mapType) == "number" and info.mapType or nil
    local parent = type(info.parentMapID) == "number" and info.parentMapID or nil
    return { name = name, mapType = mapType, parentMapID = parent }
end

--- Drop the user waypoint this addon set. False when the call is absent.
function C.ClearUserWaypoint()
    if TA.HasAPI and not TA:HasAPI("C_Map.ClearUserWaypoint") then return false end
    if not (C_Map and type(C_Map.ClearUserWaypoint) == "function") then return false end
    return pcall(C_Map.ClearUserWaypoint) and true or false
end

--- uiMapID, zone name. Either may be nil when that API is absent.
function C.PlayerMap()
    local mapID, name
    if not (TA.HasAPI and not TA:HasAPI("C_Map.GetBestMapForUnit"))
        and C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, id = pcall(function() return C_Map.GetBestMapForUnit("player") end)
        if ok and type(id) == "number" and id > 0 then mapID = id end
    end
    if mapID and not (TA.HasAPI and not TA:HasAPI("C_Map.GetMapInfo"))
        and C_Map and type(C_Map.GetMapInfo) == "function" then
        local ok, info = pcall(function() return C_Map.GetMapInfo(mapID) end)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            name = info.name
        end
    end
    if not name then name = C.RealZoneText() or C.ZoneText() end
    return mapID, name
end

function C.QuestTitle(questID)
    if type(questID) ~= "number" then return nil end
    if TA.HasAPI and not TA:HasAPI("C_QuestLog.GetTitleForQuestID") then return nil end
    if not (C_QuestLog and type(C_QuestLog.GetTitleForQuestID) == "function") then return nil end
    local ok, title = pcall(function() return C_QuestLog.GetTitleForQuestID(questID) end)
    if not ok or type(title) ~= "string" or title == "" then return nil end
    return title
end

--- Item quality number, or nil when neither item API can answer.
function C.ItemQuality(item)
    if item == nil then return nil end
    if not (TA.HasAPI and not TA:HasAPI("C_Item.GetItemInfo"))
        and C_Item and type(C_Item.GetItemInfo) == "function" then
        local ok, a, _, quality = pcall(function() return C_Item.GetItemInfo(item) end)
        if ok then
            if type(a) == "table" and type(a.quality) == "number" then return a.quality end
            if type(quality) == "number" then return quality end
        end
    end
    if not (TA.HasAPI and not TA:HasAPI("GetItemInfo")) and type(GetItemInfo) == "function" then
        local ok, _, _, quality = pcall(function() return GetItemInfo(item) end)
        if ok and type(quality) == "number" then return quality end
    end
    return nil
end

--- true / false when UnitOnTaxi answers, nil when the API is absent.
function C.OnTaxi()
    if TA.HasAPI and not TA:HasAPI("UnitOnTaxi") then return nil end
    if type(UnitOnTaxi) ~= "function" then return nil end
    local ok, v = pcall(function() return UnitOnTaxi("player") end)
    if not ok or v == nil then return nil end
    return v == true or v == 1
end

return C
