-- ToonAge/Core/Utils.lua (Anniversary — TBC Classic / Interface 20506)
-- Shared utilities. Forked from the _classic_ (MoP) copy.
--
-- Differences from the MoP Classic build that matter:
--   - No specialization system at all. GetSpecialization/GetSpecializationInfo
--     do not exist in TBC; "spec" is inferred from talent points per tree.
--   - No GetProfessions (arrived in 3.0) — professions come from Core/SkillScan.
--   - No GetAverageItemLevel — computed from equipped items.
--   - No C_Container — bare container globals, though the dual-path binding is
--     kept because it costs nothing and removes a whole class of guess.
--   - No C_Spell, no C_AddOns, no C_Traits.

local TA = ToonAge
TA.Utils = {}
local U = TA.Utils

-- ─── SAFETY WRAPPERS ────────────────────────────────────────────────────────

function U.StripMarkup(s)
    if s == nil then return "", false end
    local ok, out = pcall(function()
        local t = tostring(s)
        t = t:gsub("|c%x%x%x%x%x%x%x%x", "")
        t = t:gsub("|C%x%x%x%x%x%x%x%x", "")
        t = t:gsub("|r", "")
        t = t:gsub("|H.-|h(.-)|h", "%1")
        t = t:gsub("|T.-|t", "")
        t = t:gsub("|A.-|a", "")
        t = t:gsub("|n", "\n")
        return t
    end)
    if ok then return out, false end
    return "<unreadable value>", true
end

function U.SafeNum(val, fallback)
    if val == nil then return fallback or 0 end
    local n = tonumber(tostring(val))
    return n or (fallback or 0)
end

-- FIXME: on success this returns `true, <func's results...>` instead of just
-- <func's results...> — results[1] is pcall's own success boolean and is never
-- stripped before `unpack(results)` (confirmed: SafeCall(function() return 10,20
-- end) yields true, 10, 20, not 10, 20). The failure path compounds it by
-- returning a bare `false` with different arity than the success path. Currently
-- unused anywhere in this addon, so nothing depends on the broken shape yet —
-- but the first caller that does `local a, b = U.SafeCall(f)` will silently get
-- (true, 10) instead of (10, 20). Should be `return unpack(results, 2)`.
function U.SafeCall(func, ...)
    if type(func) ~= "function" then return false end
    local results = { pcall(func, ...) }
    if results[1] then
        for i = 2, #results do
            if type(results[i]) == "number" or type(results[i]) == "userdata" then
                results[i] = tonumber(tostring(results[i])) or 0
            end
        end
        return unpack(results)
    end
    return false
end

--- Call a function and return its first result as a number, 0 on any failure.
--- Also returns whether the call actually succeeded, so callers can tell
--- "the API said zero" apart from "the API is not there".
--- @return number value, boolean ok
function U.SafeGetNum(func, ...)
    if type(func) ~= "function" then return 0, false end
    local ok, val = pcall(func, ...)
    if ok and val ~= nil then
        local n = tonumber(tostring(val))
        return n or 0, true
    end
    return 0, false
end

--- True when a global function actually exists on this client.
function U.HasAPI(name)
    return type(_G[name]) == "function"
end

-- ─── COLOUR & QUALITY FORMATTING ───────────────────────────────────────────

-- ── Colour helpers ────────────────────────────────────────────────────
U.GOLD    = "|cFFFFD100"
U.GREEN   = "|cFF4AFF7A"
U.ORANGE  = "|cFFFF9A1A"
U.RED     = "|cFFFF4444"
U.GREY    = "|cFF888780"
U.PURPLE  = "|cFF9988FF"
U.WHITE   = "|cFFFFFFFF"
U.CLOSE   = "|r"

function U.Colour(text, colour)
    return (colour or U.WHITE) .. tostring(text) .. U.CLOSE
end

function U.Gold(text)   return U.Colour(text, U.GOLD)   end
function U.Green(text)  return U.Colour(text, U.GREEN)  end
function U.Orange(text) return U.Colour(text, U.ORANGE) end
function U.Red(text)    return U.Colour(text, U.RED)    end
function U.Grey(text)   return U.Colour(text, U.GREY)   end

-- ── Item quality colours ─────────────────────────────────────────────
local QUALITY_COLOURS = {
    [0] = "|cFF9D9D9D", [1] = "|cFFFFFFFF", [2] = "|cFF1EFF00",
    [3] = "|cFF0070DD", [4] = "|cFFA335EE", [5] = "|cFFFF8000",
    [6] = "|cFFE6CC80", [7] = "|cFF0CF4EC",
}

function U.QualityColour(quality)
    return QUALITY_COLOURS[quality or 1] or QUALITY_COLOURS[1]
end

function U.ColourItemName(name, quality)
    return U.Colour(name, U.QualityColour(quality))
end

-- ─── NUMBER FORMATTING ──────────────────────────────────────────────────────
-- Precision rules come from .kiro/steering/precision.md. Percentages that update
-- live are 1 dp; stat weights and scores are 2 dp; frame coordinates are floored
-- integers. Never a bare %f.

function U.FormatNumber(n)
    if not n then return "0" end
    n = math.floor(n)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000    then return string.format("%.1fk", n / 1000)    end
    return tostring(n)
end

--- Live-updating percentage: 1 decimal place.
function U.Pct(n)
    return string.format("%.1f%%", U.SafeNum(n))
end

--- Score / stat weight: 2 decimal places.
function U.Score(n)
    return string.format("%.2f", U.SafeNum(n))
end

--- Rating values are whole numbers in the UI — a fractional rating point does
--- not exist as something a player can acquire.
function U.Rating(n)
    return string.format("%d", math.floor(U.SafeNum(n) + 0.5))
end

function U.Floor(n)
    return math.floor(U.SafeNum(n))
end

-- ─── CHARACTER IDENTITY ─────────────────────────────────────────────────────

-- ── Player identity ───────────────────────────────────────────────────
function U.GetPlayerName()
    return UnitName("player") or "Unknown"
end

function U.GetPlayerLevel()
    return U.SafeNum(UnitLevel("player"), 1)
end

function U.GetPlayerClass()
    local _, class = UnitClass("player")
    return class or "UNKNOWN"
end

function U.GetPlayerClassLocalized()
    local localized = UnitClass("player")
    return localized or "Unknown"
end

function U.GetPlayerRace()
    local localized, token = UnitRace("player")
    return token or "Unknown", localized or token or "Unknown"
end

function U.GetPlayerFaction()
    local token = UnitFactionGroup("player")
    return token or "Neutral"
end

-- ─── SPEC INFERENCE (TBC has no specialization API) ────────────────────────
--
-- GetSpecialization() does not exist here. The MoP build's Character tab bailed
-- out at `if not specID then return end` and drew an empty panel — silently.
-- Nothing in this build may depend on a spec ID.
--
-- Instead: GetNumTalentTabs() / GetTalentTabInfo(tab) give points spent per
-- tree. The tree with the most points is the de-facto spec. Below ~10 points
-- that is meaningless, so it reports "Untalented" rather than picking a tree at
-- random on a level 12 character.

local MIN_POINTS_FOR_SPEC = 10

--- @return string|nil treeName, number pointsInTree, table allTrees, number totalPoints
function U.GetTalentSummary()
    if not U.HasAPI("GetNumTalentTabs") or not U.HasAPI("GetTalentTabInfo") then
        return nil, 0, {}, 0
    end

    local numTabs = U.SafeGetNum(GetNumTalentTabs)
    if numTabs <= 0 then return nil, 0, {}, 0 end

    local trees, total = {}, 0
    local bestName, bestPoints = nil, -1

    for tab = 1, numTabs do
        local ok, name, _, pointsSpent = pcall(GetTalentTabInfo, tab)
        if ok and name then
            local pts = U.SafeNum(pointsSpent)
            trees[#trees + 1] = { index = tab, name = name, points = pts }
            total = total + pts
            if pts > bestPoints then
                bestName, bestPoints = name, pts
            end
        end
    end

    if bestPoints < MIN_POINTS_FOR_SPEC then
        return nil, bestPoints > 0 and bestPoints or 0, trees, total
    end
    return bestName, bestPoints, trees, total
end

--- Human-readable spec label, always safe to print.
function U.GetSpecLabel()
    local name, points, _, total = U.GetTalentSummary()
    if name then
        return name, points
    end
    if total and total > 0 then
        return "Untalented (" .. total .. " points spent)", total
    end
    return "No talents yet", 0
end

-- ─── ROLE INFERENCE ─────────────────────────────────────────────────────────
-- No UnitGroupRolesAssigned in TBC. Role drives which caps matter (a tank cares
-- about Defense, a caster about spell hit), so getting it wrong shows the wrong
-- advice — it is inferred from class plus talent tree, and callers can override.

local CASTER_CLASSES = {
    MAGE = true, WARLOCK = true, PRIEST = true,
}
local HYBRID_CASTER_TREES = {
    -- Localized tree names cannot be matched reliably, so hybrids resolve by
    -- class default and the player's own override, never by name matching.
}

--- @return string role  "TANK" | "HEALER" | "CASTER" | "MELEE" | "RANGED"
function U.InferRole()
    local override = TA.charDB and TA.charDB.roleOverride
    if override and override ~= "auto" then return override end

    local class = U.GetPlayerClass()

    if CASTER_CLASSES[class] then return "CASTER" end
    if class == "HUNTER" then return "RANGED" end
    if class == "ROGUE" then return "MELEE" end
    if class == "WARRIOR" then
        -- Shield equipped is the strongest available tank signal in TBC.
        return U.HasShieldEquipped() and "TANK" or "MELEE"
    end
    if class == "PALADIN" or class == "DRUID" or class == "SHAMAN" then
        if U.HasShieldEquipped() and class ~= "DRUID" then return "TANK" end
        return "MELEE"
    end
    return "MELEE"
end

function U.HasShieldEquipped()
    local link = GetInventoryItemLink and GetInventoryItemLink("player", 17)
    if not link then return false end
    local _, _, _, _, _, itemType, itemSubType = U.GetItemInfo(link)
    if not itemType then return false end
    return itemSubType == "Shields" or itemType == "Shield"
end

function U.IsTank()   return U.InferRole() == "TANK"   end
function U.IsCaster() return U.InferRole() == "CASTER" end

-- ─── GROUP & ZONE CONTEXT ───────────────────────────────────────────────────

-- ── Group detection ───────────────────────────────────────────────────
function U.GetGroupType()
    if IsInRaid and IsInRaid() then return "raid" end
    if IsInGroup and IsInGroup() then return "party" end
    -- TBC clients that predate IsInGroup still answer GetNumPartyMembers.
    if GetNumRaidMembers and U.SafeGetNum(GetNumRaidMembers) > 0 then return "raid" end
    if GetNumPartyMembers and U.SafeGetNum(GetNumPartyMembers) > 0 then return "party" end
    return "solo"
end

-- ── Zone detection ────────────────────────────────────────────────────
function U.GetCurrentZone()
    return GetRealZoneText() or "Unknown"
end

function U.IsInInstance()
    if not IsInInstance then return false, "none" end
    local inInstance, instanceType = IsInInstance()
    return inInstance, instanceType
end

-- ─── SPELL & ADDON COMPATIBILITY WRAPPERS ──────────────────────────────────

-- ── Spell utilities ───────────────────────────────────────────────────
function U.GetSpellName(spellID)
    if not spellID or not GetSpellInfo then return nil end
    local name = GetSpellInfo(spellID)
    return name
end

function U.GetSpellTexture(spellID)
    if not spellID or not GetSpellInfo then return nil end
    local _, _, icon = GetSpellInfo(spellID)
    return icon
end

-- ── Addon presence ────────────────────────────────────────────────────
function U.IsAddOnLoaded(name)
    if IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        return ok and loaded and true or false
    end
    return false
end

-- ─── ITEMS ──────────────────────────────────────────────────────────────────

--- GetItemInfo wrapper. TBC has no C_Item namespace; the global is the only path.
--- Positional returns used elsewhere in this build:
---   1 name, 2 link, 3 quality, 4 itemLevel, 5 minLevel, 6 itemType, 7 itemSubType,
---   9 equipSlot(inventory type string)
function U.GetItemInfo(item)
    if not item or not GetItemInfo then return nil end
    return GetItemInfo(item)
end

function U.GetItemIlvl(itemLink)
    if not itemLink then return 0 end
    local _, _, _, ilvl = U.GetItemInfo(itemLink)
    return U.SafeNum(ilvl)
end

function U.GetItemQuality(itemLink)
    if not itemLink then return 1 end
    local _, _, quality = U.GetItemInfo(itemLink)
    return U.SafeNum(quality, 1)
end

-- Equipment slots that carry stats. 4 (shirt) and 19 (tabard) never do.
U.STAT_SLOTS = { 1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18 }

U.SLOT_NAMES = {
    [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",[7]="Legs",
    [8]="Feet",[9]="Wrist",[10]="Hands",[11]="Ring 1",[12]="Ring 2",
    [13]="Trinket 1",[14]="Trinket 2",[15]="Back",[16]="Main Hand",
    [17]="Off Hand",[18]="Ranged",
}

--- TBC has no GetAverageItemLevel. Computed from equipped gear.
function U.GetAverageIlvl()
    local total, count = 0, 0
    for _, slot in ipairs(U.STAT_SLOTS) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        if link then
            local ilvl = U.GetItemIlvl(link)
            if ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        end
    end
    return count > 0 and math.floor(total / count) or 0, count
end

-- ── Container utilities ───────────────────────────────────────────────
-- TBC uses bare globals. The C_Container path is kept only so that a future
-- client change cannot silently break bag scanning.
local _GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local _GetContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink

function U.GetContainerNumSlots(bag)
    if not _GetContainerNumSlots then return 0 end
    return U.SafeGetNum(_GetContainerNumSlots, bag)
end

function U.GetContainerItemLink(bag, slot)
    if not _GetContainerItemLink then return nil end
    local ok, link = pcall(_GetContainerItemLink, bag, slot)
    return ok and link or nil
end

-- ── Async item data ───────────────────────────────────────────────────
local pendingItems = {}
local ITEM_REQUEST_TIMEOUT = 10

local function ToItemID(item)
    if type(item) == "number" then return item end
    if type(item) ~= "string" then return nil end
    return tonumber(item:match("item:(%d+)")) or tonumber(item)
end

function U.RequestItemInfo(item, callback)
    local itemID = ToItemID(item)
    if not itemID then
        if callback then callback(nil, false) end
        return false
    end

    if U.GetItemInfo(itemID) then
        if callback then callback(itemID, true) end
        return true
    end

    local entry = pendingItems[itemID]
    if not entry then
        entry = { callbacks = {}, requested = GetTime() }
        pendingItems[itemID] = entry
        if GetItemInfo then pcall(GetItemInfo, itemID) end

        C_Timer.After(ITEM_REQUEST_TIMEOUT, function()
            local stale = pendingItems[itemID]
            if stale and stale.requested == entry.requested then
                U.OnItemInfoReceived(itemID, false)
            end
        end)
    end

    if callback then table.insert(entry.callbacks, callback) end
    return false
end

function U.OnItemInfoReceived(itemID, success)
    local entry = pendingItems[itemID]
    if not entry then return end
    pendingItems[itemID] = nil
    for _, callback in ipairs(entry.callbacks) do
        local ok, err = pcall(callback, itemID, success and true or false)
        if not ok and TA.ErrorLog then
            TA.ErrorLog:Log("RequestItemInfo callback", tostring(err), tostring(itemID))
        end
    end
end

function U.PendingItemCount()
    local n = 0
    for _ in pairs(pendingItems) do n = n + 1 end
    return n
end

-- ─── TABLE & STRING UTILITIES ───────────────────────────────────────────────

-- ── Table utilities ───────────────────────────────────────────────────
function U.TableLength(t)
    local count = 0
    for _ in pairs(t or {}) do count = count + 1 end
    return count
end

-- NOTE: recurses into nested tables with no cycle guard and no depth limit —
-- a self-referential table (directly, or via a longer cycle) recurses forever
-- and blows the Lua call stack instead of erroring cleanly. Metatables are also
-- not copied, so a copy of a metatable-driven table loses its behaviour.
function U.CopyTable(t)
    local copy = {}
    for k, v in pairs(t or {}) do
        copy[k] = (type(v) == "table") and U.CopyTable(v) or v
    end
    return copy
end

function U.TableContains(t, value)
    for _, v in ipairs(t or {}) do
        if v == value then return true end
    end
    return false
end

-- ── String utilities ──────────────────────────────────────────────────
function U.Trim(s)
    return (tostring(s or "")):match("^%s*(.-)%s*$")
end

-- WARN: for len < 3, `len - 3` is negative and `s:sub(1, negative)` counts from
-- the end of the string rather than truncating from the front, so the result is
-- the ENTIRE original string with "..." appended — longer than the input, not
-- shorter (confirmed: Truncate("HelloWorld", 2) == "HelloWorld...", 13 chars for
-- a len=2 request). Currently unused anywhere in this addon, so nothing has hit
-- this yet, but any future caller passing a short len (e.g. truncating to a
-- narrow UI column) will get the opposite of what they asked for.
function U.Truncate(s, len)
    s = tostring(s or "")
    if #s > len then return s:sub(1, len - 3) .. "..." end
    return s
end

-- ─── TIME & TEXTURE FORMATTING ──────────────────────────────────────────────

-- ── Time formatting ───────────────────────────────────────────────────
function U.FormatTime(seconds)
    seconds = U.SafeNum(seconds)
    if seconds >= 3600 then
        return string.format("%dh %dm", math.floor(seconds/3600), math.floor((seconds%3600)/60))
    elseif seconds >= 60 then
        return string.format("%dm %ds", math.floor(seconds/60), math.floor(seconds%60))
    end
    return string.format("%ds", math.floor(seconds))
end

-- ── Texture helper ────────────────────────────────────────────────────
function U.GetTextureStr(texturePath, size)
    if not texturePath then return "" end
    return string.format("|T%s:%d|t", texturePath, size or 16)
end
