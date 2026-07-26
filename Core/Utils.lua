-- ToonAge/Core/Utils.lua
-- Shared utility functions available to all modules via ToonAge.Utils

local TA = ToonAge
TA.Utils = {}
local U = TA.Utils

-- ══════════════════════════════════════════════════════════════════════════════
-- ── TAINT SAFETY UTILITIES (12.0 PTR) ─────────────────────────────────────────
-- WoW 12.0 PTR marks many API return values as "secret numbers" when addon
-- execution is tainted. These can't be used in arithmetic or comparisons.
-- SafeNum strips the taint via tonumber(tostring(x)). SafeCall wraps an
-- entire function in pcall so taint errors are silently caught.
-- ══════════════════════════════════════════════════════════════════════════════

--- Convert a potentially tainted "secret number" to a safe Lua number.
--- Returns the number, or the fallback (default 0) if conversion fails.
--- @param val any — the potentially tainted value
--- @param fallback number|nil — value to return on failure (default 0)
--- @return number
function U.SafeNum(val, fallback)
    if val == nil then return fallback or 0 end
    local n = tonumber(tostring(val))
    return n or (fallback or 0)
end

--- Safely call a WoW API function that might return tainted values.
--- Returns: ok (bool), followed by sanitized return values (numbers are cleaned).
--- On failure, returns false and the fallback values.
--- @param func function — the function to call
--- @param ... any — arguments to pass
--- @return boolean, any...
function U.SafeCall(func, ...)
    local results = { pcall(func, ...) }
    if results[1] then
        -- Success — sanitize numeric returns
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

--- Safely get a numeric value from a WoW API, returning fallback on taint/error.
--- Usage: local hp = U.SafeGetNum(UnitHealth, "player", 0)
--- @param func function
--- @param ... any — args to func (last numeric arg is NOT the fallback)
--- @return number
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

-- ── Item quality colours (matches WoW quality colour system) ─────────
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

function U.GetPlayerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return nil, nil, nil end
    local id, name, _, icon = GetSpecializationInfo(specIndex)
    return id, name, icon
end

function U.GetPlayerRole()
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
    local role = U.GetPlayerRole()
    return role == "DAMAGER"
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
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID
end

function U.IsInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance, instanceType
end

-- ── Spell utilities ───────────────────────────────────────────────────
function U.GetSpellName(spellID)
    local name = C_Spell.GetSpellName(spellID)
    return name
end

function U.GetSpellTexture(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.iconID
end

function U.IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        if C_SpellBook.IsSpellKnown(spellID) then return true end
    elseif IsSpellKnown and IsSpellKnown(spellID) then
        return true
    end
    return IsPlayerSpell(spellID) or false
end

--- Cooldown for a spell, normalised to the pre-11.0 (start, duration) shape.
--- Every caller in the addon should go through this rather than touching
--- C_Spell.GetSpellCooldown or the bare global directly — see .rules.md.
--- @return number start, number duration — both 0 when off cooldown/unknown
function U.GetSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if not info then return 0, 0 end
        return info.startTime or 0, info.duration or 0
    end
    local start, duration = GetSpellCooldown(spellID)
    if not start then return 0, 0 end
    return start, duration
end

--- Spell name/icon/castTime lookup. C_Spell.GetSpellInfo returns a table in
--- 11.0+; the bare global is a compat shim that Blizzard has been retiring
--- API-by-API, so route through here instead of calling either directly.
--- @return string|nil name, number|nil iconID, number|nil castTime
function U.GetSpellInfo(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if not info then return nil end
        return info.name, info.iconID, info.castTime
    end
    local name, _, icon, castTime = GetSpellInfo(spellID)
    return name, icon, castTime
end

-- ── Addon-presence utilities ──────────────────────────────────────────
--- Is another addon loaded? Used for optional interop checks only — ToonAge
--- never hard-depends on another addon (see .rules.md).
function U.IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

--- Returns the addon's display title, or nil if it isn't installed.
function U.GetAddOnTitle(name)
    if C_AddOns and C_AddOns.GetAddOnInfo then
        return select(2, C_AddOns.GetAddOnInfo(name))
    elseif GetAddOnInfo then
        return select(2, GetAddOnInfo(name))
    end
    return nil
end

-- ── Item utilities ────────────────────────────────────────────────────
function U.GetEquippedItemID(slot)
    return GetInventoryItemID("player", slot)
end

--- Single call site for GetItemInfo. The bare global is still current at
--- Interface 120007, but C_Item is where Blizzard is moving it — keeping one
--- wrapper means a future removal is a one-line fix, not a 19-site hunt.
function U.GetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    end
    return GetItemInfo(item)
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
-- GetAverageItemLevel() returns: overall, equipped
-- "equipped" matches the character sheet exactly — best-of-two-rings,
-- two-hand vs dual-wield weighting, empty slot penalties all included.
function U.GetAverageIlvl()
    local _, equipped = GetAverageItemLevel()
    return math.floor(equipped or 0)
end

-- ── Talent utilities ──────────────────────────────────────────────────
function U.GetTalentString()
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end
    return C_Traits.GenerateImportString(configID)
end

function U.IsNodeSelected(nodeID)
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return false end
    local config = C_Traits.GetConfigInfo(configID)
    if not config then return false end
    for _, treeID in ipairs(config.treeIDs) do
        local nodeInfo = C_Traits.GetNodeInfo(treeID, nodeID)
        if nodeInfo and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
            return true, nodeInfo.activeRank
        end
    end
    return false
end

-- ── Profession utilities ──────────────────────────────────────────────
function U.GetProfessions()
    local profs = {}
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
-- Flat-map approximation: WoW map coords are normalized [0,1]; this scale
-- factor converts normalized distance to approximate yards. Shared by
-- Arrow.lua (HUD waypoint) and QuestTracker.lua (in-window distance/ETA)
-- so both display identical numbers for the same step.
local YARD_SCALE = 2000

function U.ComputeDistance(px, py, tx, ty)
    local dx = (tx - px) * YARD_SCALE
    local dy = (ty - py) * YARD_SCALE
    return math.sqrt(dx * dx + dy * dy)
end

function U.FormatDistance(yards)
    if yards >= 1000 then
        -- Convert yards to meters (1 yd = 0.9144 m) before dividing into km —
        -- yards/1000 was being mislabeled "km", ~9% short of the real value.
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
