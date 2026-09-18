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
local _ContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local _ContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
local _ContainerItemID   = (C_Container and C_Container.GetContainerItemID)   or GetContainerItemID
local _ContainerItemInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo

-- ── Container / bags ───────────────────────────────────────────────────────

--- @param bag number
--- @return number slot count (0 if the API is unavailable)
function C.GetContainerNumSlots(bag)
    if not _ContainerNumSlots then return 0 end
    return _ContainerNumSlots(bag) or 0
end

--- @return string|nil item link in the given bag slot
function C.GetContainerItemLink(bag, slot)
    if not _ContainerItemLink then return nil end
    return _ContainerItemLink(bag, slot)
end

--- @return number|nil itemID in the given bag slot
function C.GetContainerItemID(bag, slot)
    if not _ContainerItemID then return nil end
    return _ContainerItemID(bag, slot)
end

--- Retail returns a table; old Classic returns a multi-value tuple. Callers
--- that need cross-flavor behaviour should prefer GetContainerItemLink/ID above
--- and treat this as raw passthrough where they already branch on shape.
function C.GetContainerItemInfo(bag, slot)
    if not _ContainerItemInfo then return nil end
    return _ContainerItemInfo(bag, slot)
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
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then return info.startTime, info.duration, info.isEnabled end
        return nil
    end
    if GetSpellCooldown then
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
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    end
    if GetItemInfo then return GetItemInfo(item) end
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
function C.HasTalentTabs()
    return (GetNumTalentTabs ~= nil) and (GetTalentTabInfo ~= nil)
end

function C.GetNumTalentTabs()
    if GetNumTalentTabs then return GetNumTalentTabs() or 0 end
    return 0
end

function C.GetTalentTabInfo(tabIndex)
    if GetTalentTabInfo then return GetTalentTabInfo(tabIndex) end
    return nil
end

function C.GetTalentInfo(tabIndex, talentIndex)
    if GetTalentInfo then return GetTalentInfo(tabIndex, talentIndex) end
    return nil
end

return C
