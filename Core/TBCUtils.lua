-- ToonAge/Core/TBCUtils.lua  (TBC flavor — extends the SHARED Core/Utils.lua)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- ToonAgeOne uses ONE shared Core/Utils.lua on every flavor. The TBC modules
-- (Modules/TBC/*), however, need a set of utility functions that are
-- TBC-specific game concepts with no retail equivalent:
--
--   * old-style talent-TREE reading (GetNumTalentTabs/GetTalentTabInfo) — retail
--     has no talent tabs (it uses the C_Traits loadout system)
--   * hit/expertise/resilience RATING formatting and stat-slot tables
--   * spellbook + action-bar RANK scanning (TBC spells have ranks; retail does
--     not) to find "missing spell ranks on your bars"
--   * role inference from talent tree / shapeshift form / weapon subtype
--
-- Following the ElvUI model (shared Core + a small per-flavor addition file,
-- see Docs/DATA_SOURCES.md "Reference implementations"), these live here and are
-- added ONTO the shared TA.Utils rather than forking Utils.lua. This file is
-- listed ONLY by ToonAge_TBC.toc, so retail never loads it and the shared Utils
-- stays flavor-neutral.
--
-- Source: extracted verbatim (with their bugfix history intact) from the
-- Anniversary build's Core/Utils.lua, the copy these modules were written
-- against. Load order: after Core/Utils.lua (extends TA.Utils), before the TBC
-- modules that call these functions.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

-- ── Formatting: percentages, ratings, scores ──────────────────────────────

--- A percentage value (e.g. 5.23) as "5.2%". WoW's rating-bonus APIs already
--- return plain percentage numbers, not fractions, so no *100 here.
function U.Pct(value, decimals)
    value = U.SafeNum(value)
    return string.format("%." .. (decimals or 1) .. "f%%", value)
end

--- A combat rating (Attack Power, resilience, defense, ...) as a whole number.
function U.Rating(value)
    return tostring(math.floor(U.SafeNum(value) + 0.5))
end

--- A gear/stat-weight score, one decimal place.
function U.Score(value)
    return string.format("%.1f", U.SafeNum(value))
end

-- ── Equipment slots (standard INVSLOT_* numbering, unchanged since vanilla) ─
U.SLOT_NAMES = {
    [1]  = "Head",       [2]  = "Neck",       [3]  = "Shoulder",  [4]  = "Shirt",
    [5]  = "Chest",      [6]  = "Waist",      [7]  = "Legs",      [8]  = "Feet",
    [9]  = "Wrist",      [10] = "Hands",      [11] = "Ring 1",    [12] = "Ring 2",
    [13] = "Trinket 1",  [14] = "Trinket 2",  [15] = "Back",      [16] = "Main Hand",
    [17] = "Off Hand",   [18] = "Ranged",     [19] = "Tabard",
}

--- Slots worth stat-scoring — every equipment slot except Shirt (4) and
--- Tabard (19), which never carry stats.
U.STAT_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

-- ── Player identity (race + localized class) ───────────────────────────────

--- Localized class name for display (e.g. "Warrior"), vs U.GetPlayerClass()'s
--- English token (e.g. "WARRIOR") used for table lookups.
function U.GetPlayerClassLocalized()
    local localizedClass = UnitClass("player")
    return localizedClass or "Unknown"
end

--- Race as (token, localizedName) — token matches the English keys used by
--- Data/TBC/TBCRaces.lua's RaceMechanics table ("Human", "Orc", "Dwarf", ...).
function U.GetPlayerRace()
    local localizedName, token = UnitRace("player")
    return token or "Unknown", localizedName or "Unknown"
end

-- ── Talent trees (old tab-based API — TBC/Classic only) ────────────────────

--- Reads one talent tab across client versions. The Anniversary client has
--- shipped two shapes of GetTalentTabInfo:
---   name, iconTexture, pointsSpent, ...                      (original 2.x)
---   id, name, description, icon, pointsSpent, background, ... (4.4.0+ engine)
--- Picking one position silently reads 0 points on the other, which is how a
--- talented character ended up labelled "No talents spent".
--- @return string|nil name, number pointsSpent
local function ReadTalentTab(tab)
    local r = { pcall(GetTalentTabInfo, tab) }
    if not r[1] then return nil, 0 end
    if type(r[2]) == "number" and type(r[3]) == "string" then
        return r[3], U.SafeNum(r[6])
    end
    return r[2], U.SafeNum(r[4])
end

--- Sum of spent ranks in a tab from the per-talent API. Used to confirm a tab
--- that reports zero, because the per-talent rank is the authoritative value.
local function CountTabRanks(tab)
    if type(GetNumTalents) ~= "function" or type(GetTalentInfo) ~= "function" then return nil end
    local n = U.SafeNum((select(2, pcall(GetNumTalents, tab))))
    local sum = 0
    for i = 1, n do
        local ok, _, _, _, _, rank = pcall(GetTalentInfo, tab, i)
        if ok then sum = sum + U.SafeNum(rank) end
    end
    return sum
end

--- Talent points available but not yet spent.
function U.GetUnspentTalentPoints()
    if type(GetUnspentTalentPoints) == "function" then
        local ok, v = pcall(GetUnspentTalentPoints)
        if ok and v then return U.SafeNum(v) end
    end
    if type(UnitCharacterPoints) == "function" then
        local ok, v = pcall(UnitCharacterPoints, "player")
        if ok and v then return U.SafeNum(v) end
    end
    return 0
end

--- @return string deepestTreeName, number pointsInIt, table trees, number total
function U.GetTalentSummary()
    if type(GetNumTalentTabs) ~= "function" or type(GetTalentTabInfo) ~= "function" then
        return "Talents n/a", 0, {}, 0
    end

    local okTabs, numTabs = pcall(GetNumTalentTabs)
    numTabs = okTabs and U.SafeNum(numTabs) or 0
    local trees = {}
    local total = 0
    local bestName, bestPoints = "No talents spent", 0

    for tab = 1, numTabs do
        local name, pointsSpent = ReadTalentTab(tab)
        if name then
            if pointsSpent == 0 then
                pointsSpent = CountTabRanks(tab) or 0
            end
            trees[#trees + 1] = { name = name, points = pointsSpent }
            total = total + pointsSpent
            if pointsSpent > bestPoints then
                bestPoints = pointsSpent
                bestName = name
            end
        end
    end

    return bestName, bestPoints, trees, total
end

--- "Spec" label for the sidebar — the deepest talent tree's name, with a
--- reminder when points are waiting to be spent.
function U.GetSpecLabel()
    local name, points, _, total = U.GetTalentSummary()
    local unspent = U.GetUnspentTalentPoints()
    if total == 0 then
        if unspent > 0 then
            return string.format("|cFFFF9A1A%d talent point%s unspent|r", unspent, unspent == 1 and "" or "s")
        end
        return name
    end
    local label = string.format("%s (%d)", name, points)
    if unspent > 0 then
        label = label .. string.format("  |cFFFF9A1A+%d unspent|r", unspent)
    end
    return label
end

--- Live points spent in a named talent tree, matched case-insensitively.
function U.GetTalentPointsInTree(treeName)
    if not treeName or treeName == "" then return 0 end
    local _, _, trees = U.GetTalentSummary()
    local wanted = tostring(treeName):lower()
    for _, t in ipairs(trees) do
        if t.name and tostring(t.name):lower() == wanted then
            return t.points or 0
        end
    end
    return 0
end

-- ── Role inference (tree / shapeshift form / weapon subtype) ───────────────

local TREE_ROLE = {
    WARRIOR = { Protection = "TANK" },
    PALADIN = { Holy = "HEALER", Protection = "TANK", Retribution = "MELEE" },
    PRIEST  = { Holy = "HEALER", Discipline = "HEALER", Shadow = "CASTER" },
    SHAMAN  = { Elemental = "CASTER", Enhancement = "MELEE", Restoration = "HEALER" },
    DRUID   = { Balance = "CASTER", Restoration = "HEALER" },
}

local FERAL_FORM_ROLE = {
    [5487] = "TANK",   -- Bear Form
    [9634] = "TANK",   -- Dire Bear Form
    [768]  = "MELEE",  -- Cat Form
}

--- Live shapeshift-form role for a Feral Druid, or nil if not in a recognized
--- form (caster form / Travel / Moonkin-Tree handled by TREE_ROLE / API absent).
function U.GetFeralFormRole()
    if type(GetNumShapeshiftForms) ~= "function" or type(GetShapeshiftFormInfo) ~= "function" then
        return nil
    end
    local numForms = U.SafeGetNum(GetNumShapeshiftForms)
    for i = 1, numForms do
        local ok, _, isActive, _, spellID = pcall(GetShapeshiftFormInfo, i)
        if ok and isActive and spellID and FERAL_FORM_ROLE[spellID] then
            return FERAL_FORM_ROLE[spellID]
        end
    end
    return nil
end

--- Coarse role for gear-weight/cap-target selection: TANK/HEALER/CASTER/
--- MELEE/RANGED. Manual /ta role override wins; else tree, else shapeshift
--- (feral), else weapon subtype, else MELEE default.
function U.InferRole()
    local override = TA.charDB and TA.charDB.roleOverride
    if override and override ~= "auto" then
        return override
    end

    local class = U.GetPlayerClass()
    if class == "MAGE" or class == "WARLOCK" then
        return "CASTER"
    elseif class == "HUNTER" then
        return "RANGED"
    end

    local treeName = U.GetTalentSummary()
    local classTrees = TREE_ROLE[class]
    if classTrees and treeName and classTrees[treeName] then
        return classTrees[treeName]
    end

    if class == "DRUID" and treeName == "Feral Combat" then
        return U.GetFeralFormRole() or "MELEE"
    end

    if class == "PRIEST" then
        return "CASTER"
    end

    local mainHandLink = GetInventoryItemLink and GetInventoryItemLink("player", 16)
    if mainHandLink then
        local _, _, _, _, _, _, itemSubType = U.GetItemInfo(mainHandLink)
        if itemSubType == "Wand" or itemSubType == "Staves" then
            return "CASTER"
        elseif itemSubType == "Bows" or itemSubType == "Guns"
            or itemSubType == "Crossbows" or itemSubType == "Thrown" then
            return "RANGED"
        end
    end

    return "MELEE"
end

-- ── Spell-rank scanning (TBC spells have ranks; used by "missing ranks") ────

--- Resolves a spellbook slot's spellID across client-version return shapes.
local function ResolveSpellBookID(slot, bookType)
    if type(GetSpellBookItemInfo) ~= "function" then return nil end
    local ok, a, b = pcall(GetSpellBookItemInfo, slot, bookType)
    if not ok then return nil end
    if type(a) == "table" then
        return a.spellID or a.actionID or a.id
    end
    if (a == "SPELL" or a == "FUTURESPELL") and b then
        return b
    end
    return nil
end

--- @return table byName, table idRanks (spellID -> rank), table slots (name -> {slot, spellID})
--- `slots` points at the spellbook slot holding the HIGHEST rank of each name,
--- so the Spells tab can pick that exact rank up onto the cursor.
function U.ScanSpellbook()
    local byName, idRanks, slots = {}, {}, {}
    if type(GetNumSpellTabs) ~= "function" or type(GetSpellBookItemName) ~= "function" then
        return byName, idRanks, slots
    end
    local numTabs = U.SafeGetNum(GetNumSpellTabs)
    for tab = 1, numTabs do
        local ok, _, _, offset, numSpells = pcall(GetSpellTabInfo, tab)
        offset, numSpells = U.SafeNum(offset), U.SafeNum(numSpells)
        if ok and numSpells > 0 then
            for i = 1, numSpells do
                local slot = offset + i
                local nameOk, name, rankText = pcall(GetSpellBookItemName, slot, BOOKTYPE_SPELL)
                local passiveOk, isPassive = pcall(IsPassiveSpell, slot, BOOKTYPE_SPELL)
                if nameOk and name and name ~= "" and not (passiveOk and isPassive) then
                    local rankNum = (rankText and tonumber(rankText:match("(%d+)"))) or 0
                    local spellID = ResolveSpellBookID(slot, BOOKTYPE_SPELL)
                    if not byName[name] or rankNum > byName[name] then
                        byName[name] = rankNum
                        slots[name] = { slot = slot, spellID = spellID }
                    elseif not slots[name] then
                        slots[name] = { slot = slot, spellID = spellID }
                    end
                    if spellID and (not idRanks[spellID] or rankNum > idRanks[spellID]) then
                        idRanks[spellID] = rankNum
                    end
                end
            end
        end
    end
    return byName, idRanks, slots
end

--- Highest rank of each spell NAME currently on any of the 6 standard bars.
--- Second return: name -> action slot holding the LOWEST rank of that spell
--- (the one an "upgrade" should replace).
function U.ScanActionBarRanks(idRanks)
    idRanks = idRanks or select(2, U.ScanSpellbook())
    local result, lowSlot, lowRank, idsOnBar = {}, {}, {}, {}
    if type(GetActionInfo) ~= "function" then return result, lowSlot, idsOnBar end
    local aliases = (TA.charDB and TA.charDB.spellBarAliases) or {}
    for slot = 1, 120 do
        local ok, actionType, id = pcall(GetActionInfo, slot)
        if ok and actionType == "spell" and id then
            idsOnBar[id] = idsOnBar[id] or slot
            local infoOk, name = pcall(GetSpellInfo, id)
            -- Some spells show a different name in the spellbook than on the bar
            -- (Hunter "Call Scorpid" is the Call Pet action). Aliases recorded
            -- when ToonAge places a spell map the bar id back to the book name.
            if aliases[id] then name = aliases[id]; infoOk = true end
            if infoOk and name then
                local rankNum = idRanks[id] or 0
                if not result[name] or rankNum > result[name] then
                    result[name] = rankNum
                end
                if not lowRank[name] or rankNum < lowRank[name] then
                    lowRank[name] = rankNum
                    lowSlot[name] = slot
                end
            end
        end
    end
    return result, lowSlot, idsOnBar
end

-- ── Putting spells on bars ──────────────────────────────────────────────────
-- Standard bar slot ranges on the Classic engine, in the order a player is most
-- likely to see them.
local BAR_RANGES = {
    { first = 1,  last = 12, name = "Main bar" },
    { first = 61, last = 72, name = "Bottom left bar" },
    { first = 49, last = 60, name = "Bottom right bar" },
    { first = 25, last = 36, name = "Right bar" },
    { first = 37, last = 48, name = "Right bar 2" },
    { first = 13, last = 24, name = "Main bar page 2" },
}

--- Every standard bar slot, in BAR_RANGES order.
function U.StandardBarSlots()
    local out = {}
    for _, r in ipairs(BAR_RANGES) do
        for slot = r.first, r.last do out[#out + 1] = slot end
    end
    return out
end

--- First empty standard action slot. @return slot, barName, position
function U.FindEmptyActionSlot()
    if type(HasAction) ~= "function" then return nil end
    for _, r in ipairs(BAR_RANGES) do
        for slot = r.first, r.last do
            local ok, has = pcall(HasAction, slot)
            if ok and not has then return slot, r.name, slot - r.first + 1 end
        end
    end
    return nil
end

--- Name of the bar holding an action slot. @return barName, position
function U.ActionSlotName(slot)
    for _, r in ipairs(BAR_RANGES) do
        if slot >= r.first and slot <= r.last then return r.name, slot - r.first + 1 end
    end
    return "Action bar", slot
end

--- Puts a spellbook spell on the cursor (drag source for the Spells tab).
--- @return boolean ok
function U.PickupSpellFromBook(entry)
    if not entry then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    if entry.slot and type(PickupSpellBookItem) == "function" then
        if pcall(PickupSpellBookItem, entry.slot, BOOKTYPE_SPELL) then return true end
    end
    if entry.spellID and type(PickupSpell) == "function" then
        if pcall(PickupSpell, entry.spellID) then return true end
    end
    return false
end

--- Records which action id a spellbook spell became on the bar, so a spell whose
--- bar name differs from its book name is not reported missing forever.
function U.RememberBarAlias(entry, slot)
    if not (entry and slot and TA.charDB and GetActionInfo) then return end
    local ok, actionType, id = pcall(GetActionInfo, slot)
    if ok and actionType == "spell" and id then
        TA.charDB.spellBarAliases = TA.charDB.spellBarAliases or {}
        local nameOk, barName = pcall(GetSpellInfo, id)
        if not nameOk or barName ~= entry.name then
            TA.charDB.spellBarAliases[id] = entry.name
        end
    end
end

--- Extra copies of the same spell on the standard bars (the first copy is kept).
--- @return table extras  array of { slot, spellID, name }
function U.FindDuplicateBarSpells()
    local extras, seen = {}, {}
    if type(GetActionInfo) ~= "function" then return extras end
    for _, slot in ipairs(U.StandardBarSlots()) do
        local ok, actionType, id = pcall(GetActionInfo, slot)
        if ok and actionType == "spell" and id then
            if seen[id] then
                local _, name = pcall(GetSpellInfo, id)
                extras[#extras + 1] = { slot = slot, spellID = id, name = name or tostring(id) }
            else
                seen[id] = slot
            end
        end
    end
    return extras
end

--- Clears the given action slots (out of combat only). @return removed count
function U.ClearActionSlots(list)
    if InCombatLockdown and InCombatLockdown() then return 0 end
    if type(PickupAction) ~= "function" then return 0 end
    local removed = 0
    for _, e in ipairs(list) do
        if ClearCursor then ClearCursor() end
        if pcall(PickupAction, e.slot) then removed = removed + 1 end
        if ClearCursor then ClearCursor() end
    end
    return removed
end

--- Places a spellbook spell into an action slot (out of combat only). Whatever
--- was in that slot is cleared off the cursor, so an upgrade replaces the old rank.
--- @return boolean ok, string message
function U.PlaceSpellOnBar(entry, slot)
    if InCombatLockdown and InCombatLockdown() then
        return false, "Can't change action bars in combat."
    end
    if not slot then return false, "No empty action bar slot on your standard bars." end
    if type(PlaceAction) ~= "function" then return false, "This client doesn't allow placing actions." end
    -- Never add a second copy: if this spell's id is already on a bar, stop.
    local _, _, idsOnBar = U.ScanActionBarRanks()
    if entry.spellID and idsOnBar[entry.spellID] and idsOnBar[entry.spellID] ~= slot then
        local bar, pos = U.ActionSlotName(idsOnBar[entry.spellID])
        U.RememberBarAlias(entry, idsOnBar[entry.spellID])
        return false, string.format("%s is already on %s slot %d.", entry.name, bar, pos)
    end
    if ClearCursor then ClearCursor() end
    if not U.PickupSpellFromBook(entry) then return false, "Couldn't pick up that spell." end
    -- The cursor knows the real action id this becomes; if that id is already on
    -- a bar (a spell named differently in the book), don't place another copy.
    if GetCursorInfo then
        local okC, kind, _, _, cursorID = pcall(GetCursorInfo)
        cursorID = tonumber(cursorID)
        if okC and kind == "spell" and cursorID and idsOnBar[cursorID] and idsOnBar[cursorID] ~= slot then
            if ClearCursor then ClearCursor() end
            if TA.charDB then
                TA.charDB.spellBarAliases = TA.charDB.spellBarAliases or {}
                TA.charDB.spellBarAliases[cursorID] = entry.name
            end
            local bar, pos = U.ActionSlotName(idsOnBar[cursorID])
            return false, string.format("%s is already on %s slot %d.", entry.name, bar, pos)
        end
    end
    local ok = pcall(PlaceAction, slot)
    if ClearCursor then ClearCursor() end
    if not ok then return false, "Couldn't place that spell." end
    U.RememberBarAlias(entry, slot)
    local bar, pos = U.ActionSlotName(slot)
    return true, string.format("%s slot %d", bar, pos)
end

--- Diff of the two scans: known spells whose highest rank isn't matched on the
--- bars. Each entry: { name, knownRank, barRank, onBar }.
function U.FindMissingSpellRanks()
    local known, idRanks, slots = U.ScanSpellbook()
    local onBars, lowSlot, idsOnBar = U.ScanActionBarRanks(idRanks)
    local missing = {}
    for name, knownRank in pairs(known) do
        local barRank = onBars[name]
        local bestID = slots[name] and slots[name].spellID
        if bestID and idsOnBar[bestID] then
            barRank = knownRank   -- the exact spell is on a bar, whatever it is called there
        end
        if not barRank or barRank < knownRank then
            missing[#missing + 1] = {
                name = name, knownRank = knownRank,
                barRank = barRank or 0, onBar = barRank ~= nil,
                slot = slots[name] and slots[name].slot,
                spellID = slots[name] and slots[name].spellID,
                barSlot = lowSlot[name],
            }
        end
    end
    table.sort(missing, function(a, b) return a.name < b.name end)
    return missing
end
