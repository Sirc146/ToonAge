-- CharacterAdvisor/Core/Utils.lua
-- Shared utility functions available to all modules via CharacterAdvisor.Utils

local CA = CharacterAdvisor
CA.Utils = {}
local U = CA.Utils

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
    return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
end

function U.GetSpellCooldown(spellID)
    local start, duration = GetSpellCooldown(spellID)
    if not start then return 0, 0 end
    return start, duration
end

-- ── Item utilities ────────────────────────────────────────────────────
function U.GetEquippedItemID(slot)
    return GetInventoryItemID("player", slot)
end

function U.GetItemIlvl(itemLink)
    if not itemLink then return 0 end
    local _, _, _, ilvl = GetItemInfo(itemLink)
    return ilvl or 0
end

function U.GetItemQuality(itemLink)
    if not itemLink then return 1 end
    local _, _, quality = GetItemInfo(itemLink)
    return quality or 1
end

-- Get equipped item ilvl by slot ID
function U.GetEquippedIlvl(slotID)
    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then return 0 end
    local link = GetInventoryItemLink("player", slotID)
    return U.GetItemIlvl(link)
end

-- ── Average ilvl ──────────────────────────────────────────────────────
-- GetAverageItemLevel() returns: overall, equipped
-- "equipped" matches the character sheet exactly — best-of-two-rings,
-- two-hand vs dual-wield weighting, empty slot penalties all included.
function U.GetAverageIlvl()
    local _, equipped = GetAverageItemLevel()
    return math.floor(equipped or 0)
end

-- Per-slot ilvl used by the Gear tab for individual slot display
-- Slot IDs: 1=Head 2=Neck 3=Shoulder 4=Back 5=Chest 8=Wrist
--           9=Hands 10=Waist 11=Legs 12=Feet 13=Ring1 14=Ring2
--           15=Trinket1 16=Trinket2 17=MainHand 18=OffHand
function U.GetSlotIlvl(slotID)
    local link = GetInventoryItemLink("player", slotID)
    return link and U.GetItemIlvl(link) or 0
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
