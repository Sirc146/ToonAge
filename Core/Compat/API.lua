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
--- Forever never reaches this: HasTalentTabs is false there.
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

return C
