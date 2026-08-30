-- ToonAge/Core/Utils.lua (Classic)
-- Shared utility functions — adapted for Cataclysm Classic APIs
-- Key differences from Retail:
--   - No C_Spell namespace → use GetSpellInfo/GetSpellCooldown globals
--   - No C_Container → use GetContainerItemLink/GetContainerNumSlots globals
--   - No C_Item.RequestLoadItemDataByID → retry via timer
--   - No C_AddOns → use IsAddOnLoaded/GetAddOnInfo globals
--   - No C_Traits/C_ClassTalents → talent functions return nil

local TA = ToonAge
TA.Utils = {}
local U = TA.Utils

-- ══════════════════════════════════════════════════════════════════════════════
-- ── TAINT SAFETY UTILITIES ────────────────────────────────────────────────────
-- Classic doesn't have the same taint severity as 12.x Retail, but SafeNum
-- is still useful for nil-safety and type coercion.
-- ══════════════════════════════════════════════════════════════════════════════

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

function U.SafeCall(func, ...)
    local results = { pcall(func, ...) }
    if results[1] then
        for i = 2, #results do
            if type(results[i]) == "number" or type(results[i]) == "userdata" then
                results[i] = tonumber(tostring(results[i])) or 0
            end
        end
        return unpack(results)
    else
        return false
    end
end

function U.SafeGetNum(func, ...)
    local ok, val = pcall(func, ...)
    if ok and val ~= nil then
        local n = tonumber(tostring(val))
        return n or 0
    end
    return 0
end

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

-- ── Item quality colours ─────────────────────────────────────────────
local QUALITY_COLOURS = {
    [0] = "|cFF9D9D9D",  -- Poor (grey)
    [1] = "|cFFFFFFFF",  -- Common (white)
    [2] = "|cFF1EFF00",  -- Uncommon (green)
    [3] = "|cFF0070DD",  -- Rare (blue)
    [4] = "|cFFA335EE",  -- Epic (purple)
    [5] = "|cFFFF8000",  -- Legendary (orange)
    [6] = "|cFFE6CC80",  -- Artifact
    [7] = "|cFF0CF4EC",  -- Heirloom
}

function U.QualityColour(quality)
    return QUALITY_COLOURS[quality or 1] or QUALITY_COLOURS[1]
end

function U.ColourItemName(name, quality)
    return U.Colour(name, U.QualityColour(quality))
end

-- ── Number formatting ─────────────────────────────────────────────────
function U.FormatNumber(n)
    if not n then return "0" end
    n = math.floor(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fk", n / 1000)
    end
    return tostring(n)
end

function U.FormatIlvl(ilvl)
    return string.format("%d", math.floor(ilvl or 0))
end

-- ── Player identity ───────────────────────────────────────────────────
function U.GetPlayerName()
    return UnitName("player") or "Unknown"
end

function U.GetPlayerLevel()
    return UnitLevel("player") or 1
end

function U.GetPlayerClass()
    local _, class = UnitClass("player")
    return class or "UNKNOWN"
end

-- Cata Classic has GetSpecialization() and GetSpecializationInfo()
function U.GetPlayerSpec()
    if not GetSpecialization then return nil, nil, nil end
    local specIndex = GetSpecialization()
    if not specIndex then return nil, nil, nil end
    local id, name, _, icon = GetSpecializationInfo(specIndex)
    return id, name, icon
end

function U.GetPlayerRole()
    if not GetSpecialization then return "NONE" end
    local specIndex = GetSpecialization()
    if not specIndex then return "NONE" end
    local _, _, _, _, role = GetSpecializationInfo(specIndex)
    return role or "NONE"
end

function U.IsHealer()
    return U.GetPlayerRole() == "HEALER"
end

function U.IsTank()
    return U.GetPlayerRole() == "TANK"
end

function U.IsDPS()
    return U.GetPlayerRole() == "DAMAGER"
end

-- ── Group detection ───────────────────────────────────────────────────
function U.GetGroupType()
    if IsInRaid() then return "raid"
    elseif IsInGroup() then return "party"
    else return "solo" end
end

function U.GetGroupSize()
    if IsInRaid() then return GetNumGroupMembers()
    elseif IsInGroup() then return GetNumGroupMembers()
    else return 1 end
end

-- ── Zone detection ────────────────────────────────────────────────────
function U.GetCurrentZone()
    return GetRealZoneText() or "Unknown"
end

function U.GetCurrentMapID()
    -- C_Map.GetBestMapForUnit exists in Cata Classic
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
    return nil
end

function U.IsInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance, instanceType
end

-- ── Spell utilities (Classic: use globals, no C_Spell) ────────────────
function U.GetSpellName(spellID)
    if not spellID then return nil end
    local name = GetSpellInfo(spellID)
    return name
end

function U.GetSpellTexture(spellID)
    if not spellID then return nil end
    local _, _, icon = GetSpellInfo(spellID)
    return icon
end

function U.IsSpellKnown(spellID)
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    return false
end

--- Cooldown for a spell. Classic uses the global GetSpellCooldown directly.
--- @return number start, number duration
function U.GetSpellCooldown(spellID)
    if not spellID then return 0, 0 end
    local start, duration = GetSpellCooldown(spellID)
    if not start then return 0, 0 end
    return start, duration
end

--- Spell info lookup. Classic GetSpellInfo returns: name, rank, icon, castTime, ...
--- @return string|nil name, number|nil iconID, number|nil castTime
function U.GetSpellInfo(spellID)
    if not spellID then return nil end
    local name, _, icon, castTime = GetSpellInfo(spellID)
    return name, icon, castTime
end

-- ── Addon-presence utilities (Classic: use globals, no C_AddOns) ──────
function U.IsAddOnLoaded(name)
    if IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

function U.GetAddOnTitle(name)
    if GetAddOnInfo then
        return select(2, GetAddOnInfo(name))
    end
    return nil
end

-- ── Item utilities ────────────────────────────────────────────────────
function U.GetEquippedItemID(slot)
    return GetInventoryItemID("player", slot)
end

--- GetItemInfo wrapper. Classic uses the global directly.
function U.GetItemInfo(item)
    if not item then return nil end
    return GetItemInfo(item)
end

-- ── Container utilities ────────────────────────────────────────────────
-- MoP Classic (5.5.4) uses C_Container; older Classic Era uses bare globals.
-- Detect once at load and bind the correct functions.
local _GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local _GetContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
local _GetContainerItemID   = (C_Container and C_Container.GetContainerItemID)   or GetContainerItemID

function U.GetContainerNumSlots(bag)
    if not _GetContainerNumSlots then return 0 end
    return _GetContainerNumSlots(bag) or 0
end

function U.GetContainerItemLink(bag, slot)
    if not _GetContainerItemLink then return nil end
    return _GetContainerItemLink(bag, slot)
end

function U.GetContainerItemID(bag, slot)
    if not _GetContainerItemID then return nil end
    return _GetContainerItemID(bag, slot)
end

function U.GetContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        -- C_Container.GetContainerItemInfo returns a table
        return C_Container.GetContainerItemInfo(bag, slot)
    elseif GetContainerItemInfo then
        -- Old Classic: returns texture, count, locked, quality, readable, lootable, link, filtered, noValue, itemID
        return GetContainerItemInfo(bag, slot)
    end
    return nil
end

-- ── Async item data ───────────────────────────────────────────────────
-- No C_Item.RequestLoadItemDataByID in Classic. We just call GetItemInfo()
-- which triggers a server request, then handle GET_ITEM_INFO_RECEIVED.

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

    -- Already cached?
    if U.GetItemInfo(itemID) then
        if callback then callback(itemID, true) end
        return true
    end

    local entry = pendingItems[itemID]
    if not entry then
        entry = { callbacks = {}, requested = GetTime() }
        pendingItems[itemID] = entry

        -- In Classic, calling GetItemInfo on an uncached item triggers a server query
        GetItemInfo(itemID)

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

function U.GetItemIlvl(itemLink)
    if not itemLink then return 0 end
    local _, _, _, ilvl = U.GetItemInfo(itemLink)
    return ilvl or 0
end

function U.GetItemQuality(itemLink)
    if not itemLink then return 1 end
    local _, _, quality = U.GetItemInfo(itemLink)
    return quality or 1
end

-- ── Average ilvl ──────────────────────────────────────────────────────
-- GetAverageItemLevel exists in Cata Classic
function U.GetAverageIlvl()
    if GetAverageItemLevel then
        local _, equipped = GetAverageItemLevel()
        return math.floor(equipped or 0)
    end
    -- Fallback: compute from equipped items
    local total, count = 0, 0
    for slot = 1, 18 do
        if slot ~= 4 then -- skip shirt
            local link = GetInventoryItemLink("player", slot)
            if link then
                local ilvl = U.GetItemIlvl(link)
                if ilvl > 0 then
                    total = total + ilvl
                    count = count + 1
                end
            end
        end
    end
    return count > 0 and math.floor(total / count) or 0
end

-- ── Talent utilities (Classic: no C_Traits) ───────────────────────────
-- These return nil/false since Classic doesn't have the Retail talent system
function U.GetTalentString()
    return nil
end

function U.IsNodeSelected(nodeID)
    return false
end

-- ── Profession utilities ──────────────────────────────────────────────
-- GetProfessions() and GetProfessionInfo() work in Cata Classic
function U.GetProfessions()
    local profs = {}
    if not GetProfessions then return profs end
    local p1, p2, p3, p4, p5, p6 = GetProfessions()
    for _, profIndex in ipairs({p1, p2, p3, p4, p5, p6}) do
        if profIndex then
            local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(profIndex)
            if name then
                table.insert(profs, {
                    index    = profIndex,
                    name     = name,
                    icon     = icon,
                    rank     = rank,
                    maxRank  = maxRank,
                    skillLine = skillLine,
                })
            end
        end
    end
    return profs
end

-- ── Table utilities ───────────────────────────────────────────────────
function U.TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function U.CopyTable(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = U.CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function U.TableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

-- ── String utilities ──────────────────────────────────────────────────
function U.Trim(s)
    return s:match("^%s*(.-)%s*$")
end

function U.Truncate(s, len)
    if #s > len then
        return s:sub(1, len - 3) .. "..."
    end
    return s
end

-- ── Distance / travel ─────────────────────────────────────────────────
local YARD_SCALE = 2000

function U.ComputeDistance(px, py, tx, ty)
    local dx = (tx - px) * YARD_SCALE
    local dy = (ty - py) * YARD_SCALE
    return math.sqrt(dx * dx + dy * dy)
end

function U.FormatDistance(yards)
    if yards >= 1000 then
        return string.format("%.1f km", (yards * 0.9144) / 1000)
    end
    return string.format("%d yds", math.floor(yards))
end

function U.FormatETA(yards, speed)
    if not speed or speed <= 0 then return "" end
    local secs = yards / speed
    if secs < 60 then
        return string.format("%ds", math.ceil(secs))
    else
        return string.format("%dm %ds", math.floor(secs / 60), math.ceil(secs % 60))
    end
end

-- ── Time formatting ───────────────────────────────────────────────────
function U.FormatTime(seconds)
    if seconds >= 3600 then
        return string.format("%dh %dm", math.floor(seconds/3600), math.floor((seconds%3600)/60))
    elseif seconds >= 60 then
        return string.format("%dm %ds", math.floor(seconds/60), math.floor(seconds%60))
    else
        return string.format("%ds", math.floor(seconds))
    end
end

-- ── Texture path helper ───────────────────────────────────────────────
function U.GetTextureStr(texturePath, size)
    size = size or 16
    return string.format("|T%s:%d|t", texturePath, size)
end

function U.GetSpellTextureStr(spellID, size)
    local tex = U.GetSpellTexture(spellID)
    if not tex then return "" end
    return U.GetTextureStr(tex, size or 16)
end
