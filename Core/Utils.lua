-- ToonAge/Core/Utils.lua (Anniversary — TBC Classic / Interface 20506)
-- Shared utility functions.
--
-- Corrected 2026-09-06: this file's header and the GetSpecialization comment
-- below previously claimed a Cataclysm Classic, then a Mists of Pandaria
-- Classic, target. Both were wrong — direct inspection of the live TOC
-- (ToonAge.toc, ## Interface: 20506) confirms this addon is actually TBC
-- Classic Anniversary. Neither Cata nor MoP ever shipped on this client.
--
-- This file predates that discovery and still carries some dead weight left
-- over from whatever build it was copied from: GetPlayerSpec/GetPlayerRole/
-- IsHealer/IsTank/IsDPS (below) call GetSpecialization(), which does not
-- exist before Mists of Pandaria (5.0.4) and is therefore always nil on this
-- client — those five functions are permanently non-functional stubs here.
-- Same story for U.GetProfessions/U.GetProfessionInfo further down: the raw
-- GetProfessions() global arrived in patch 3.0 (per Core/SkillScan.lua's own
-- header comment) and doesn't exist on TBC either — the real profession read
-- path this build actually uses is Core/SkillScan.lua's own addon-defined
-- Scan:GetProfessions() method, which scans the skill list instead; that is
-- what Modules/Character/ProfessionAdvisor.lua calls, not these two.
-- This is confirmed harmless: no TBC-native module in this build calls any
-- of these seven (Modules/Character/Character.lua documents the spec-ID gap
-- in its own header and deliberately avoids branching on it), and every
-- other Retail/Cata/MoP-only API below (C_Container, C_Map,
-- GetAverageItemLevel, etc.) is guarded with an existence check before use,
-- so none of it throws on load — it just falls back or returns an empty/zero
-- result. Left in place rather than deleted so a future module doesn't reach
-- for GetPlayerSpec() or GetProfessions() and get a confusing silent nil;
-- TODO clean these seven out once nothing references them.
--
-- Key differences from Retail:
--   - No C_Spell namespace → use GetSpellInfo/GetSpellCooldown globals
--   - No C_Container on TBC → use GetContainerItemLink/GetContainerNumSlots globals
--   - No C_Item.RequestLoadItemDataByID → retry via timer
--   - No C_AddOns → use IsAddOnLoaded/GetAddOnInfo globals
--   - No C_Traits/C_ClassTalents → TBC uses three-tree talent points instead;
--     talent-point functions below return nil/false and are unused by any
--     TBC-native module (see Data/TBCTalentHit.lua for the real talent read path)

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

-- ── Stat/rating/score formatting ───────────────────────────────────────
-- Fixed 2026-09-07: U.Pct/U.Rating/U.Score were called from StatCaps.lua,
-- RaceAdvisor.lua, WeaponSkill.lua, Character.lua, PvPAdvisor.lua, and
-- Gear.lua (~60 call sites combined) but were never defined anywhere in this
-- file — every tab that touched a stat cap, a rating, or a gear score threw
-- "attempt to call a nil value" and aborted mid-render.

--- A percentage value (e.g. 5.23) as "5.2%". WoW's rating-bonus APIs
--- (GetCombatRatingBonus, etc.) already return plain percentage numbers, not
--- fractions, so no *100 here.
function U.Pct(value, decimals)
    value = U.SafeNum(value)
    return string.format("%." .. (decimals or 1) .. "f%%", value)
end

--- A combat rating (Attack Power, resilience rating, defense rating, ...) as
--- a whole number — the " rating" / " resilience" suffix is added by callers.
function U.Rating(value)
    return tostring(math.floor(U.SafeNum(value) + 0.5))
end

--- A gear/stat-weight score, one decimal place.
function U.Score(value)
    return string.format("%.1f", U.SafeNum(value))
end

-- ── Equipment slots ───────────────────────────────────────────────────
-- Fixed 2026-09-07: U.SLOT_NAMES/U.STAT_SLOTS were used throughout
-- Modules/Gear/Gear.lua but never defined. Standard WoW INVSLOT_* numbering,
-- unchanged since vanilla/TBC.
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

--- Localized class name for display (e.g. "Warrior"), as opposed to
--- U.GetPlayerClass()'s English token (e.g. "WARRIOR") used for table
--- lookups. Fixed 2026-09-07: this function was called from Core/Layout.lua
--- (the character sidebar shared by every tab), Modules/Character/
--- RaceAdvisor.lua, Modules/Character/WeaponSkill.lua, and Core/TBCStats.lua
--- but was never defined anywhere in this file — every one of those Render()
--- calls threw "attempt to call a nil value" and aborted before drawing
--- anything, which is why the whole panel came back empty on first test.
function U.GetPlayerClassLocalized()
    local localizedClass = UnitClass("player")
    return localizedClass or "Unknown"
end

--- Race as (token, localizedName) — token matches the English keys used by
--- Data/TBCRaces.lua's RaceMechanics table ("Human", "Orc", "Dwarf", ...).
--- Fixed 2026-09-07, same missing-function bug as GetPlayerClassLocalized
--- above: called from 4 real files, defined in none of them.
function U.GetPlayerRace()
    local localizedName, token = UnitRace("player")
    return token or "Unknown", localizedName or "Unknown"
end

--- TBC has no single "spec" — three point-allocation talent trees per class
--- instead (see the GetSpecialization block below, which is dead on this
--- client). Reads the live talent trees via GetTalentTabInfo.
--- @return string deepestTreeName, number pointsInIt, table trees ({name, points} per tab), number totalPointsSpent
--- Fixed 2026-09-07: called from Modules/Character/Character.lua and
--- Modules/PvP/PvPAdvisor.lua as U.GetTalentSummary() but never defined
--- anywhere in this file.
function U.GetTalentSummary()
    if type(GetNumTalentTabs) ~= "function" or type(GetTalentTabInfo) ~= "function" then
        return "Talents n/a", 0, {}, 0
    end

    local numTabs = U.SafeGetNum(GetNumTalentTabs)
    local trees = {}
    local total = 0
    local bestName, bestPoints = "No talents spent", 0

    for tab = 1, numTabs do
        -- Fixed 2026-09-09: GetTalentTabInfo(tab) returns
        -- name, iconTexture, pointsSpent, background, previewPointsSpent —
        -- pointsSpent is the 3rd return value. This used to capture the 4th
        -- (background, which this client leaves nil) into pointsSpent
        -- instead, so every character always read 0 points spent in every
        -- tree no matter how many were actually spent (confirmed via a
        -- level 65 Frost Mage with 56 points spent in Frost showing "No
        -- talents yet" / all-zero trees in-game).
        local ok, name, _, pointsSpent = pcall(GetTalentTabInfo, tab)
        if ok and name then
            pointsSpent = U.SafeNum(pointsSpent)
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

--- "Spec" label for the sidebar — just the deepest talent tree's name.
--- Fixed 2026-09-07: called from Core/Layout.lua's CharacterSidebar (used by
--- every tab) but never defined anywhere in this file.
function U.GetSpecLabel()
    local name = U.GetTalentSummary()
    return name
end

--- Live points spent in a named talent tree (e.g. "Shadow", "Protection"),
--- matched case-insensitively against GetTalentTabInfo()'s tree names.
--- Added 2026-09-07 for the secondary/hybrid capability suggestions feature
--- (Data/TBCSecondaryRoles.lua, Modules/Character/TalentBuilds.lua) — each
--- suggestion there names a required tree and a point threshold, and this is
--- how eligibility against the player's LIVE talents gets checked, rather
--- than guessing from class alone. Returns 0 if the tree name doesn't match
--- any of the player's three tabs (e.g. the name is wrong, or the API isn't
--- available) — callers treat that as "not eligible," not as an error.
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

--- Coarse role for gear-weight/cap-target selection: TANK/HEALER/CASTER/
--- MELEE/RANGED. Deliberately NOT inferred from class or talent tree —
--- only a manual /ta role override (TA.charDB.roleOverride, see
--- Modules/Character/StatCaps.lua's SlashCommands.role) can produce TANK or
--- HEALER. Without an override this falls back to reading the equipped
--- main-hand weapon type, so e.g. a Holy Paladin or Restoration Shaman with
--- no override reads as MELEE/CASTER by weapon, not by class — a known,
--- documented limitation (see the NOTE in StatCaps.lua:Collect()), not a bug
--- to silently "fix" by guessing from class here.
--- Fixed 2026-09-07: called from 9 real files (Layout.lua, Gear.lua,
--- StatCaps.lua, ProfessionAdvisor.lua, Character.lua, PvPAdvisor.lua) but
--- never defined anywhere in this file.
-- Fixed 2026-09-09 (first pass): this only ever recognised a Wand as "not
-- melee", but a caster's spellpower weapon (staff, sword, dagger) sits in
-- the MAIN-HAND slot (16) — Wands are equipped in the RANGED slot (18) and
-- were never read from there at all. So the Wand check below could
-- basically never fire for a real caster, and every Mage/Warlock/Priest
-- fell through to the MELEE default, driving gear scoring, stat caps and
-- the sidebar's role label to weight and recommend MELEE gear for them.
-- Reported via a level 65 Mage's Gear tab reading "Role: MELEE (inferred)"
-- and offering a two-handed sword/warhammer as a "Main Hand" upgrade.
--
-- Fixed 2026-09-09 (second pass): that first fix hard-set Priest to CASTER
-- unconditionally alongside Mage/Warlock — correct for Shadow, but wrong
-- for Holy/Discipline. A forced-CASTER Holy Priest got shown a spell hit %
-- target in Stat Caps that does nothing for a healer (healing spells cannot
-- miss), and switching specs between Shadow and Holy never changed the
-- detected role at all without a manual /ta role override — reported as
-- "on healers its showing DPS options... if I activate a different spec it
-- will not change the role for me". Mage/Warlock genuinely have no other
-- spec shape (every tree is a caster-DPS tree), so they stay hard-set. For
-- every class with a REAL role split across its trees (Warrior, Paladin,
-- Priest, Shaman, Druid), role is now read from the live deepest talent
-- tree via U.GetTalentSummary() — the same source the Talents/Rotation tabs
-- already trust — so it tracks a respec automatically instead of freezing
-- on whatever the weapon or class alone implied.
local TREE_ROLE = {
    WARRIOR = { Protection = "TANK" },
    PALADIN = { Holy = "HEALER", Protection = "TANK", Retribution = "MELEE" },
    PRIEST  = { Holy = "HEALER", Discipline = "HEALER", Shadow = "CASTER" },
    SHAMAN  = { Elemental = "CASTER", Enhancement = "MELEE", Restoration = "HEALER" },
    -- Feral Combat deliberately omitted: it covers both Bear tank and Cat
    -- DPS, and the tree alone can't tell those apart — that needs the
    -- current shapeshift form, not just points spent. Falls through to the
    -- weapon/MELEE default below, same as before, until overridden manually.
    DRUID   = { Balance = "CASTER", Restoration = "HEALER" },
}

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

    -- Priest never has a melee spec at all, so even with no clear talent
    -- lean yet (a fresh level with 0 points, or a mixed spread that hasn't
    -- committed to Shadow) CASTER is still the correct default — just no
    -- longer forced PAST a real Holy/Discipline investment above.
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

-- GetSpecialization()/GetSpecializationInfo() are MoP APIs (introduced in
-- patch 5.0.4). This addon's real TOC targets TBC Classic Anniversary
-- (Interface 20506), which predates single-specialization entirely — TBC
-- uses three point-allocation talent trees per class instead. Both calls
-- below are always nil on this client, so these five functions
-- (GetPlayerSpec/GetPlayerRole/IsHealer/IsTank/IsDPS) are dead stubs.
-- Confirmed unused by every TBC-native module in this build.
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

-- Added 2026-09-07 for the "spellbook has a spell/rank your action bars
-- don't" check (Modules/Character/Spells.lua, /ta spells).
--
-- FIXED 2026-09-07: the first version of ScanActionBarRanks got the rank of
-- an action-bar spell from GetSpellInfo(id)'s second return, on the
-- pre-existing (and, it turns out, wrong-for-this-client) assumption a few
-- lines above in this file that "Classic GetSpellInfo returns: name, rank,
-- icon, castTime". In testing every single spell that WAS correctly matched
-- by name still showed up as "bar has Rank 0" — including ones clearly
-- sitting on a visible bar slot in a screenshot — which only makes sense if
-- that second return isn't rank text at all on this client (most likely the
-- icon). GetSpellBookItemName's (name, rankText) pair, used below, is the
-- one place this file has actually confirmed real "Rank N" text. So instead
-- of trusting GetSpellInfo's positional return for rank, ScanSpellbook now
-- also builds a spellID -> rank map from the spellbook itself (resolving
-- each slot's spellID defensively, since GetSpellBookItemInfo's return
-- shape is exactly the kind of thing that has already changed across client
-- versions elsewhere), and ScanActionBarRanks looks a bar spell's rank up in
-- that map instead of asking GetSpellInfo for it a second, less reliable, way.

--- Resolves a spellbook slot's spellID across the two GetSpellBookItemInfo
--- shapes seen across client versions: legacy (itemType, id, ...) multiple
--- returns, or a single table with a spellID/actionID/id field. Returns nil
--- rather than guessing if neither shape matches.
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

--- Every spell name known in the spellbook, mapped to the highest rank
--- number currently known (0 for spells with no rank concept — most
--- non-damage/utility spells). Passives are excluded via IsPassiveSpell —
--- they're never meant to go on an action bar, so including them would just
--- be noise in the "missing from your bars" list.
--- @return table byName, table idRanks — idRanks maps spellID -> rank for
---         every spellbook entry that resolved a spellID; pass it into
---         ScanActionBarRanks so the two scans agree on what a "rank" is.
function U.ScanSpellbook()
    local byName, idRanks = {}, {}
    if type(GetNumSpellTabs) ~= "function" or type(GetSpellBookItemName) ~= "function" then
        return byName, idRanks
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
                    if not byName[name] or rankNum > byName[name] then
                        byName[name] = rankNum
                    end
                    local spellID = ResolveSpellBookID(slot, BOOKTYPE_SPELL)
                    if spellID and (not idRanks[spellID] or rankNum > idRanks[spellID]) then
                        idRanks[spellID] = rankNum
                    end
                end
            end
        end
    end
    return byName, idRanks
end

--- Highest rank of each spell NAME currently placed on any action bar slot.
--- Slots 1-120 cover all 6 standard action bars (Blizzard's flat slot
--- numbering already includes the extra MultiBar rows); stance/possess/
--- vehicle bars use a separate, form-specific slot range this deliberately
--- does not scan, since those are contextual rather than "your normal bars."
--- @param idRanks table|nil spellID -> rank map from ScanSpellbook's 2nd
---        return; scans the spellbook itself if not given one.
function U.ScanActionBarRanks(idRanks)
    idRanks = idRanks or select(2, U.ScanSpellbook())
    local result = {}
    if type(GetActionInfo) ~= "function" then return result end
    for slot = 1, 120 do
        local ok, actionType, id = pcall(GetActionInfo, slot)
        if ok and actionType == "spell" and id then
            local infoOk, name = pcall(GetSpellInfo, id)
            if infoOk and name then
                local rankNum = idRanks[id] or 0
                if not result[name] or rankNum > result[name] then
                    result[name] = rankNum
                end
            end
        end
    end
    return result
end

--- Diff of the two scans above: every known spell whose highest rank isn't
--- matched by an equal-or-higher rank anywhere on the action bars. Sorted
--- alphabetically. Each entry: { name, knownRank, barRank, onBar } — onBar
--- is false when the spell isn't placed anywhere at all (barRank is then
--- meaningless 0, not a real "rank 0"); onBar is true with barRank < knownRank
--- when it's on a bar but at a stale/lower rank.
function U.FindMissingSpellRanks()
    local known, idRanks = U.ScanSpellbook()
    local onBars = U.ScanActionBarRanks(idRanks)
    local missing = {}
    for name, knownRank in pairs(known) do
        local barRank = onBars[name]
        if not barRank or barRank < knownRank then
            missing[#missing + 1] = {
                name = name, knownRank = knownRank,
                barRank = barRank or 0, onBar = barRank ~= nil,
            }
        end
    end
    table.sort(missing, function(a, b) return a.name < b.name end)
    return missing
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
-- Dead stub on TBC (20506) — GetProfessions()/GetProfessionInfo() arrived in
-- patch 3.0. Guarded below so it just returns an empty table; the real
-- profession read path is Core/SkillScan.lua's Scan:GetProfessions(), used
-- by Modules/Character/ProfessionAdvisor.lua.
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
