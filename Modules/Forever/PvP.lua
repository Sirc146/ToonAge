-- ToonAge/Modules/Forever/PvP.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- Reliable live PvP tactical & readiness tab across:
--   1. Live PvP Context Banner (PvP server / Contested / Hostile / Flagged + unflag
--      timer / Free-For-All Arena / Active Battleground match) + Now tab alert
--   2. Forever Battleground Bracket & Marks guide (WSG, AB, Darkspear Islands 15v15, AV)
--   3. Live PvP Readiness Checklist (PvP Trinket equipped vs in bags, PvP consumables &
--      Engineering tools, live buffs, and active Talents PvP Plan slot)
--   4. Live Enemy Target Dossier + Spellbook-aware Racial & Class Matchups (zero text
--      truncation, includes utility racials like Shadowmeld, Walk on Air, Skysight, Eureka!)
--   5. Session & Lifetime Honor/HK ledger + quick links to Talents & Casts.
--
-- Facts only from live client reads and harvested Data/Forever/Racials.lua.
-- Never guesses server honor rates or hidden ratings.

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverPvP", M)

-- When this login started: the clock for the session honor rate.
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, _, isInitialLogin)
        self:UnregisterAllEvents()
        if not TA.charDB then return end
        if isInitialLogin or not TA.charDB.pvpLoginAt then
            TA.charDB.pvpLoginAt = time and time() or nil
        end
        M._sessionStart = TA.charDB.pvpLoginAt
    end)
end

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Secret(v)
    if v == nil then return false end
    if U and U.IsSecret and U.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function Num(v)
    if v == nil or Secret(v) then return nil end
    return tonumber(v)
end

local function Str(v)
    if v == nil or Secret(v) or type(v) ~= "string" then return nil end
    return v ~= "" and v or nil
end

local function Show(value, fmt)
    if value == nil then return "n/a" end
    if fmt then return string.format(fmt, value) end
    return tostring(value)
end

local function OpenTab(tabID)
    if TA.Layout and TA.Layout.OpenTab then
        TA.Layout:OpenTab(tabID)
    elseif TA.UI and TA.UI.SetTab then
        TA.UI:SetTab(tabID)
    end
end

-- ─── 1. LIVE PVP CONTEXT (SERVER / FLAG / AREA / MATCH) ───────────────────

--- Read live PvP context: whether in a BG/Arena match, FFA zone, flagged
--- (with countdown timer), contested/hostile world zone, or safe zone.
function M.ReadContext()
    local inInst, instType = Try(IsInInstance)
    local zoneType = Str(Try(GetZonePVPInfo))
    local zoneName = Str(Try(GetRealZoneText)) or Str(Try(GetZoneText)) or "Current zone"
    local flagged = Try(UnitIsPVP, "player") == true
    local ffa = Try(UnitIsPVPFreeForAll, "player") == true
    local timerMs = Num(Try(GetPVPTimer))

    local mode = "safe"
    local badge = "Safe (Unflagged)"
    local status = "good"
    local active = false
    local detail = zoneName

    if inInst == true and (instType == "pvp" or instType == "arena") then
        mode = "match"
        badge = "In PvP Match"
        status = "warn"
        active = true
        detail = string.format("%s (%s)", zoneName, instType == "arena" and "Arena" or "Battleground")
    elseif ffa or zoneType == "arena" then
        mode = "ffa"
        badge = "Free-For-All PvP"
        status = "warn"
        active = true
        detail = zoneName .. " — anyone can attack you here"
    elseif flagged then
        mode = "flagged"
        active = true
        status = "warn"
        if timerMs and timerMs > 0 and timerMs < 300000 then
            local secs = math.floor(timerMs / 1000)
            badge = string.format("Flagged (drops in %d:%02d)", math.floor(secs / 60), secs % 60)
        else
            badge = "PvP Flagged (Active)"
        end
        local zTag = zoneType and (" · " .. zoneType) or ""
        detail = zoneName .. zTag
    elseif zoneType == "contested" or zoneType == "hostile" or zoneType == "combat" then
        mode = "contested"
        active = true
        status = "warn"
        badge = (zoneType == "hostile") and "Hostile Territory" or "Contested Territory"
        detail = zoneName .. " — World PvP risk"
    elseif zoneType == "sanctuary" then
        mode = "safe"
        badge = "Sanctuary"
        status = "good"
        detail = zoneName .. " — PvP disabled"
    elseif zoneType == "friendly" then
        mode = "safe"
        badge = "Friendly Territory"
        status = "good"
        detail = zoneName .. " — Unflagged"
    end

    return {
        mode = mode,
        badge = badge,
        status = status,
        active = active,
        flagged = flagged,
        ffa = ffa,
        zoneType = zoneType,
        zoneName = zoneName,
        detail = detail,
    }
end

-- ─── 2. FOREVER BATTLEGROUND BRACKETS ──────────────────────────────────────

--- Exact Forever Battleground bracket & available BGs for character level.
function M.BracketInfo(level)
    local lv = tonumber(level) or 1
    if lv < 10 then
        return {
            open = false,
            bracket = "Under 10",
            position = "Unlock at Lv 10",
            bgs = {},
            summary = "Warsong Gulch opens at level 10.",
        }
    end
    local lo, hi
    if lv >= 60 then
        lo, hi = 60, 60
    else
        lo = math.floor(lv / 10) * 10
        hi = lo + 9
    end
    local bgs = { "Warsong Gulch" }
    if lv >= 20 then bgs[#bgs + 1] = "Arathi Basin" end
    if lv >= 30 then bgs[#bgs + 1] = "Darkspear Islands (15v15)" end
    if lv >= 51 then bgs[#bgs + 1] = "Alterac Valley" end

    local pos
    if lv >= 60 then
        pos = "Max level bracket"
    elseif lv >= hi - 1 then
        pos = "Top of bracket"
    elseif lv <= lo + 2 then
        pos = "Bottom of bracket"
    else
        pos = "Mid bracket"
    end
    local label = (lo == hi) and "Level 60" or string.format("%d-%d", lo, hi)
    return {
        open = true,
        bracket = label,
        position = pos,
        bgs = bgs,
        summary = table.concat(bgs, " · "),
    }
end

-- ─── 3. LIVE PVP READINESS CHECKLIST (TRINKET / CONSUMABLES / PLAN) ───────

local function ItemNameFromLink(link)
    if type(link) ~= "string" or Secret(link) then return nil end
    return link:match("%[(.-)%]")
end

local function IsPvPTrinketName(name)
    if type(name) ~= "string" then return false end
    local low = string.lower(name)
    return low:find("insignia of the horde", 1, true) ~= nil
        or low:find("insignia of the alliance", 1, true) ~= nil
        or low:find("pvp trinket", 1, true) ~= nil
        or low:find("medallion of the", 1, true) ~= nil
end

--- Scan equipped trinket slots (13/14) + bags for PvP trinket, consumables,
--- Engineering tools, Marks of Honor, and active Talents saved plan slot.
function M.ReadReadiness()
    local trinketState = "missing"
    local trinketName = nil
    for _, slot in ipairs({ 13, 14 }) do
        local link = Try(GetInventoryItemLink, "player", slot)
        local nm = ItemNameFromLink(link)
        if nm and IsPvPTrinketName(nm) then
            trinketState = "equipped"
            trinketName = nm
            break
        end
    end

    local bags = {
        bandages = 0,
        potions = 0,
        actionPots = 0,
        engineering = 0,
        marks = 0,
    }
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink then
        for bag = 0, 4 do
            local slots = Num(Try(C_Container.GetContainerNumSlots, bag)) or 0
            for slot = 1, slots do
                local link = Try(C_Container.GetContainerItemLink, bag, slot)
                local nm = ItemNameFromLink(link)
                if nm then
                    local low = string.lower(nm)
                    local cnt = 1
                    if C_Container.GetContainerItemInfo then
                        local info = Try(C_Container.GetContainerItemInfo, bag, slot)
                        if type(info) == "table" and Num(info.stackCount) then
                            cnt = Num(info.stackCount)
                        end
                    end
                    if trinketState == "missing" and IsPvPTrinketName(nm) then
                        trinketState = "in_bag"
                        trinketName = nm
                    elseif low:find("bandage", 1, true) then
                        bags.bandages = bags.bandages + cnt
                    elseif low:find("free action potion", 1, true)
                        or low:find("living action potion", 1, true)
                        or low:find("limited invulnerability potion", 1, true)
                        or low:find("swiftness potion", 1, true)
                        or low:find("invisibility potion", 1, true) then
                        bags.actionPots = bags.actionPots + cnt
                    elseif low:find("healing potion", 1, true) or low:find("mana potion", 1, true) then
                        bags.potions = bags.potions + cnt
                    elseif low:find("grenade", 1, true) or low:find("bomb", 1, true)
                        or low:find("reflector", 1, true) or low:find("net%-o%-matic")
                        or low:find("rocket boots", 1, true) then
                        bags.engineering = bags.engineering + cnt
                    elseif low:find("mark of honor", 1, true) then
                        bags.marks = bags.marks + cnt
                    end
                end
            end
        end
    end

    local planSlot = nil
    if TA.TalentIntel and type(TA.TalentIntel.ActiveSlot) == "function" then
        local _, sName = TA.TalentIntel.ActiveSlot()
        planSlot = sName
    end

    return {
        trinketState = trinketState,
        trinketName = trinketName,
        bags = bags,
        planSlot = planSlot,
    }
end

--- Expose a Priority-1 alert for Modules/Forever/Now.lua when the player is in
--- active PvP danger (in a match, FFA, flagged, or contested/hostile zone).
function M.GetAlert()
    local ctx = M.ReadContext()
    if not ctx or not ctx.active then return nil end
    local ready = M.ReadReadiness()
    local notes = { ctx.detail }
    if ready.trinketState == "in_bag" then
        notes[#notes + 1] = tostring(ready.trinketName or "PvP Trinket") .. " is in your bags — equip before fighting!"
    end
    if ready.bags.bandages == 0 and ready.bags.potions == 0 then
        notes[#notes + 1] = "No bandages or health/mana potions detected in bags."
    end
    return {
        priority = (ctx.mode == "match" or ctx.mode == "ffa" or ctx.flagged or ready.trinketState == "in_bag") and 1 or 2,
        category = "PvP",
        status = "warning",
        title = "PvP Active: " .. ctx.badge,
        value = (ready.trinketState == "in_bag") and "Equip trinket" or ctx.badge,
        detail = table.concat(notes, " "),
        actionLabel = "Open PvP",
        actionTab = "pvp",
    }
end

-- ─── 4. RANK & HONOR READS ─────────────────────────────────────────────────

-- Forever Season 1 non-decaying Rank 0..14 titles & cumulative Rank Point thresholds
-- (verified against live Forever 1.60.1 PvP UI: Rank 1 = 750, Rank 14 = 24,750).
local FOREVER_RANK_TITLES = {
    Horde = {
        [0] = "Civilian", [1] = "Scout", [2] = "Grunt", [3] = "Sergeant",
        [4] = "Senior Sergeant", [5] = "First Sergeant", [6] = "Stone Guard",
        [7] = "Blood Guard", [8] = "Legionnaire", [9] = "Centurion",
        [10] = "Champion", [11] = "Lieutenant General", [12] = "General",
        [13] = "Warlord", [14] = "High Warlord",
    },
    Alliance = {
        [0] = "Civilian", [1] = "Private", [2] = "Corporal", [3] = "Sergeant",
        [4] = "Master Sergeant", [5] = "Sergeant Major", [6] = "Knight",
        [7] = "Knight-Lieutenant", [8] = "Knight-Captain", [9] = "Knight-Champion",
        [10] = "Lieutenant Commander", [11] = "Commander", [12] = "Marshal",
        [13] = "Field Marshal", [14] = "Grand Marshal",
    },
}

local FOREVER_RANK_CUMULATIVE = {
    [0] = 0, [1] = 750, [2] = 1650, [3] = 2700, [4] = 3900, [5] = 5250,
    [6] = 6750, [7] = 8400, [8] = 10200, [9] = 12150, [10] = 14250,
    [11] = 16600, [12] = 19100, [13] = 21750, [14] = 24750,
}

local FOREVER_RANK_TIER = {
    [0] = 750, [1] = 900, [2] = 1050, [3] = 1200, [4] = 1350, [5] = 1500,
    [6] = 1650, [7] = 1800, [8] = 1950, [9] = 2100, [10] = 2350,
    [11] = 2500, [12] = 2650, [13] = 3000, [14] = 0,
}

function M.ReadForeverRank(faction)
    local raw = nil
    if TA.Compat and type(TA.Compat.ForeverPvPRank) == "function" then
        raw = TA.Compat.ForeverPvPRank()
    elseif C_MajorFactions and type(C_MajorFactions.GetMajorFactionData) == "function" then
        local d = Try(C_MajorFactions.GetMajorFactionData, 2800)
        if type(d) == "table" and Num(d.renownLevel) ~= nil then
            raw = {
                rank = Num(d.renownLevel) or 0,
                earned = Num(d.renownReputationEarned) or 0,
                threshold = Num(d.renownLevelThreshold),
            }
        end
    end
    if type(raw) ~= "table" then return nil end

    local r = math.max(0, math.min(14, tonumber(raw.rank) or 0))
    local titles = FOREVER_RANK_TITLES[faction] or FOREVER_RANK_TITLES.Horde
    local threshold = (raw.threshold and raw.threshold > 0) and raw.threshold or FOREVER_RANK_TIER[r]
    local earned = tonumber(raw.earned) or 0
    local baseTotal = FOREVER_RANK_CUMULATIVE[r] or 0
    local totalEarned = math.min(24750, baseTotal + earned)
    local nextTitle = (r < 14) and titles[r + 1] or nil
    local vendor = (faction == "Alliance") and "Champions' Hall (Stormwind)" or "Hall of Legends (Orgrimmar)"

    return {
        isForever = true,
        number = r,
        name = titles[r] or ("Rank " .. tostring(r)),
        nextRank = (r < 14) and (r + 1) or nil,
        nextTitle = nextTitle,
        earned = earned,
        threshold = threshold,
        progress = (threshold and threshold > 0) and math.max(0, math.min(1, earned / threshold)) or 1,
        totalEarned = totalEarned,
        totalMax = 24750,
        vendor = vendor,
    }
end

function M.ReadHonorCurrency()
    if TA.Compat and type(TA.Compat.HonorCurrency) == "function" then
        return TA.Compat.HonorCurrency()
    end
    return nil
end

local function ReadRank(faction)
    local foreverRank = M.ReadForeverRank(faction)
    if foreverRank then return foreverRank end

    local rankIndex = Num(Try(UnitPVPRank, "player"))
    if not rankIndex then return nil end

    local name, number = Try(GetPVPRankInfo, rankIndex, "player")
    if not name then
        name, number = Try(GetPVPRankInfo, rankIndex)
    end
    return {
        name     = name and tostring(name) or nil,
        number   = Num(number),
        progress = Num(Try(GetPVPRankProgress)),
    }
end

-- ─── 5. RACIAL & LIVE SPELLBOOK MATCHUPS ──────────────────────────────────

local RACE_NAMES = {
    Scourge = "Undead", NightElf = "Night Elf",
}
local function RaceName(key) return RACE_NAMES[key] or key end

local TAG_TEXT = {
    stun = "stuns", fear = "fear", charm = "charm", sleep = "sleep",
    snare = "roots/slows", bleed = "bleeds", poison = "poisons",
    disease = "diseases", curse = "curses",
}
local function TagText(list)
    local out = {}
    for i, t in ipairs(list or {}) do out[i] = TAG_TEXT[t] or t end
    return table.concat(out, ", ")
end

local function Cooldown(sec)
    if not sec then return nil end
    if sec >= 60 then return string.format("%dm CD", math.floor(sec / 60)) end
    return string.format("%ds CD", sec)
end

-- Utility PvP racials harvested in Data/Forever/Racials.lua whose impact isn't
-- solely removes/inflicts/detects/burst.
local UTILITY_PVP_RACIALS = {
    ["Shadowmeld"]     = "combat drop / ambush",
    ["Walk on Air"]    = "10s cliff glide",
    ["Skysight"]       = "+10% move/mount speed",
    ["Read Ley Line"]  = "+100% HP/mana regen",
    ["Eureka!"]        = "+10% dmg next 3 spells",
    ["Cannibalize"]    = "corpse HP/mana sustain",
    ["Plainsrunning"]  = "up to +30% run speed",
}

-- Known player CC / DoT spells mapped to racial-break tags so PvP matchups
-- reflect what THIS character can actually cast.
local SPELL_CC_TAGS = {
    ["Frost Nova"]         = "snare",
    ["Frostbolt"]          = "snare",
    ["Cone of Cold"]       = "snare",
    ["Entangling Roots"]   = "snare",
    ["Hamstring"]          = "snare",
    ["Concussive Shot"]    = "snare",
    ["Wing Clip"]          = "snare",
    ["Frost Shock"]        = "snare",
    ["Crippling Poison"]   = "snare",
    ["Psychic Scream"]     = "fear",
    ["Fear"]               = "fear",
    ["Howl of Terror"]     = "fear",
    ["Intimidating Shout"] = "fear",
    ["Hibernate"]          = "sleep",
    ["Cheap Shot"]         = "stun",
    ["Kidney Shot"]        = "stun",
    ["Hammer of Justice"]  = "stun",
    ["Bash"]               = "stun",
    ["Intercept"]          = "stun",
    ["Charge"]             = "stun",
    ["Rend"]               = "bleed",
    ["Garrote"]            = "bleed",
    ["Rupture"]            = "bleed",
    ["Rake"]               = "bleed",
    ["Rip"]                = "bleed",
    ["Deadly Poison"]      = "poison",
    ["Viper Sting"]        = "poison",
    ["Serpent Sting"]      = "poison",
    ["Devouring Plague"]   = "disease",
    ["Curse of Agony"]     = "curse",
    ["Curse of Tongues"]   = "curse",
    ["Curse of Exhaustion"] = "curse",
}

local CLASS_THREATS = {
    WARRIOR = "Gap closers (Charge/Intercept), Hamstring snare, Pummel interrupt, Intimidating Shout (Fear).",
    PALADIN = "Hammer of Justice (Stun), Divine Shield immunity, Blessing of Freedom (breaks roots/slows), Cleanse.",
    HUNTER  = "Scatter/Freezing Trap, Viper Sting (mana drain), Concussive Shot, Pet pushback.",
    ROGUE   = "Stealth openers (Cheap Shot/Ambush), Kick interrupt, Kidney Shot, Blind, Vanish reset.",
    PRIEST  = "Psychic Scream (Fear — WoTF breaks!), Dispel Magic, Power Word: Shield, Mana Burn.",
    SHAMAN  = "Earth Shock interrupt, Grounding Totem (eats next spell), Purge, Frost Shock.",
    MAGE    = "Counterspell interrupt, Polymorph, Frost Nova shatter burst, Blink (breaks stuns/roots).",
    WARLOCK = "Fear / Seduction (WoTF breaks!), Curse of Tongues (+cast time), Spell Lock, Death Coil.",
    DRUID   = "Shapeshifting breaks roots/Polymorph, Entangling Roots, Bash stun, stealth & HoT kiting.",
}

local function ReadKnownCCTags(knownOverride)
    local byTag = {}
    local function mark(nm)
        local tag = SPELL_CC_TAGS[nm]
        if tag then
            byTag[tag] = byTag[tag] or {}
            local list = byTag[tag]
            for _, x in ipairs(list) do if x == nm then return end end
            list[#list + 1] = nm
        end
    end
    if type(knownOverride) == "table" then
        for _, nm in ipairs(knownOverride) do mark(nm) end
        return byTag
    end
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return byTag end
    local n = Num(Try(C_SpellBook.GetNumSpellBookSkillLines)) or 0
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    for line = 1, n do
        local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if type(info) == "table" and info.numSpellBookItems then
            local off = Num(info.itemIndexOffset) or 0
            local cnt = Num(info.numSpellBookItems) or 0
            for i = off + 1, off + cnt do
                local item = Try(C_SpellBook.GetSpellBookItemInfo, i, bank)
                local nm = type(item) == "table" and Str(item.name) or nil
                if nm then mark(nm) end
            end
        end
    end
    return byTag
end

local function RacialsFor(race, faction, class)
    local data = TA.Data and TA.Data.ForeverRacials
    local list = data and data[race] and data[race][faction]
    if not list then return nil end
    local byName, order = {}, {}
    for _, r in ipairs(list) do
        local mine = r.classes == nil
        if not mine and class then
            for _, c in ipairs(r.classes) do if c == class then mine = true end end
        end
        local cur = byName[r.name]
        if not cur then
            byName[r.name] = r; order[#order + 1] = r.name
        elseif mine and cur.classes then
            byName[r.name] = r
        end
    end
    local out = {}
    for _, n in ipairs(order) do out[#out + 1] = byName[n] end
    return out
end
M._RacialsFor = RacialsFor

local function PvPOnly(list)
    local out = {}
    for _, r in ipairs(list or {}) do
        if r.removes or r.inflicts or r.detects or r.burst or UTILITY_PVP_RACIALS[r.name] then
            out[#out + 1] = r
        end
    end
    return out
end

local function Describe(r)
    local bits = {}
    if r.removes then bits[#bits + 1] = "breaks " .. TagText(r.removes) end
    if r.inflicts then bits[#bits + 1] = "inflicts " .. TagText(r.inflicts) end
    if r.detects == "stealth" then bits[#bits + 1] = "reveals stealth" end
    if r.burst then bits[#bits + 1] = "burst" end
    if #bits == 0 and UTILITY_PVP_RACIALS[r.name] then
        bits[#bits + 1] = UTILITY_PVP_RACIALS[r.name]
    end
    local cd = Cooldown(r.cooldown)
    return table.concat(bits, "; ") .. (cd and (" · " .. cd) or "")
end

local function Clashes(mine, theirs, myClass, myCCTags)
    local notes = {}
    local myRemoves, theirRemoves = {}, {}
    for _, r in ipairs(mine) do for _, t in ipairs(r.removes or {}) do myRemoves[t] = r end end
    for _, r in ipairs(theirs) do for _, t in ipairs(r.removes or {}) do theirRemoves[t] = r end end
    for _, r in ipairs(theirs) do
        for _, t in ipairs(r.inflicts or {}) do
            if myRemoves[t] then
                notes[#notes + 1] = { good = true, text = string.format(
                    "Your %s breaks their %s.", myRemoves[t].name, r.name) }
            else
                notes[#notes + 1] = { good = false, text = string.format(
                    "Their %s (%s) — no racial break.", r.name, TagText(r.inflicts)) }
            end
        end
        if r.detects == "stealth" and (myClass == "ROGUE" or myClass == "DRUID") then
            notes[#notes + 1] = { good = false, text = string.format(
                "Their %s reveals stealth — open from further out.", r.name) }
        end
        -- Spellbook-aware counter check: does their racial break a CC/DoT you actually know?
        if type(myCCTags) == "table" then
            for _, t in ipairs(r.removes or {}) do
                local spells = myCCTags[t]
                if type(spells) == "table" and #spells > 0 then
                    local sample = table.concat({ spells[1], spells[2] }, " / ")
                    notes[#notes + 1] = { good = false, text = string.format(
                        "Their %s breaks your %s.", r.name, sample) }
                end
            end
        end
    end
    for _, r in ipairs(mine) do
        for _, t in ipairs(r.inflicts or {}) do
            if theirRemoves[t] then
                notes[#notes + 1] = { good = false, text = string.format(
                    "Their %s breaks your %s.", theirRemoves[t].name, r.name) }
            end
        end
    end
    return notes
end
M._Clashes = Clashes

-- ─── RENDER SECTIONS ───────────────────────────────────────────────────────

local function RenderContextAndBrackets(content, y, ctx, bracket, ready)
    y = L:SectionHeader(content, y, "PvP Status & Readiness", ctx.detail)
    y = L:DataRow(content, y, {
        label = "Live status",
        value = ctx.badge,
        status = ctx.status,
    })
    y = L:DataRow(content, y, {
        label = "BG bracket (" .. bracket.bracket .. ")",
        value = bracket.position,
        note = bracket.summary,
        status = (bracket.position == "Top of bracket" or bracket.position == "Max level bracket") and "good" or "neutral",
    })

    local trinketVal, trinketStatus
    if ready.trinketState == "equipped" then
        trinketVal = tostring(ready.trinketName or "Equipped")
        trinketStatus = "good"
    elseif ready.trinketState == "in_bag" then
        trinketVal = "In bags — equip!"
        trinketStatus = "warn"
    else
        trinketVal = "None detected"
        trinketStatus = "dim"
    end
    y = L:DataRow(content, y, {
        label = "PvP Trinket",
        value = trinketVal,
        status = trinketStatus,
    })

    local b = ready.bags
    local stockText = string.format("%d bandages · %d pots · %d action pots",
        b.bandages, b.potions, b.actionPots)
    if b.engineering > 0 then
        stockText = stockText .. string.format(" · %d eng", b.engineering)
    end
    local marksNote = (b.marks > 0) and string.format("Marks of Honor in bags: %d (WSG/AB/Darkspear/AV)", b.marks) or nil
    y = L:DataRow(content, y, {
        label = "Consumables",
        value = stockText,
        note = marksNote,
        status = (b.bandages > 0 or b.potions > 0 or b.actionPots > 0) and "neutral" or "warn",
    })

    if ready.planSlot then
        y = L:DataRow(content, y, {
            label = "Talents plan slot",
            value = ready.planSlot,
            status = (ready.planSlot == "PvP") and "good" or "neutral",
        })
    end

    y = L:ButtonRow(content, y, {
        { label = "Open Talents (PvP Plan)", onClick = function() OpenTab("talents") end },
        { label = "Review fights (Casts)",   onClick = function() OpenTab("casts") end },
    })
    return y
end

local function RenderYourRacials(content, y, race, faction, class)
    local mine = RacialsFor(race, faction, class)
    if not mine then return y, nil end
    local pvp = PvPOnly(mine)
    y = L:SectionHeader(content, y, "Your racials in PvP",
        string.format("%s · %s", RaceName(race), faction))
    if #pvp == 0 then
        y = L:Paragraph(content, y, "None of your racials are active PvP tools; their value is passive.",
            { color = L.C_DIM })
    end
    for _, r in ipairs(pvp) do
        -- Put short CD in right value and full effect in wrapping note (zero truncation)
        y = L:DataRow(content, y, {
            label = r.name,
            value = Cooldown(r.cooldown) or "Passive",
            note = Describe(r),
            status = r.removes and "good" or (r.burst and "warn" or "neutral"),
            tooltipTitle = r.name,
            tooltip = { r.tooltip },
        })
    end
    return y, mine
end

local function RenderTarget(content, y, faction, class, mine, myCCTags)
    if not (Try(UnitExists, "target") and Try(UnitIsPlayer, "target")) then return y end
    if not Try(UnitIsEnemy, "player", "target") then return y end
    local _, tRace = Try(UnitRace, "target")
    local tFaction = Str(Try(UnitFactionGroup, "target"))
    if not Str(tRace) or not tFaction then return y end
    local tClassLoc, tClass = Try(UnitClass, "target")
    tClass = Str(tClass)
    local tLevel = Num(Try(UnitLevel, "target"))
    local theirs = PvPOnly(RacialsFor(tRace, tFaction, tClass) or {})
    local sub = string.format("%s%s %s (%s)",
        tLevel and ("Lv " .. tLevel .. " ") or "",
        RaceName(tRace),
        Str(tClassLoc) or "",
        tFaction)
    y = L:SectionHeader(content, y, "Enemy target dossier", sub)
    for _, x in ipairs(theirs) do
        y = L:DataRow(content, y, {
            label = x.name,
            value = Cooldown(x.cooldown) or "Passive",
            note = Describe(x),
            tooltipTitle = x.name,
            tooltip = { x.tooltip },
        })
    end
    if tClass and CLASS_THREATS[tClass] then
        y = L:Paragraph(content, y, "Key class threats: " .. CLASS_THREATS[tClass], { color = L.C_SECONDARY })
    end
    for _, n in ipairs(Clashes(PvPOnly(mine or {}), theirs, class, myCCTags)) do
        y = L:Paragraph(content, y, n.text, { color = n.good and L.C_SUCCESS or L.C_WARNING })
    end
    return y
end

local function RenderMatchups(content, y, race, faction, class, mine, myCCTags)
    local data = TA.Data and TA.Data.ForeverRacials
    if not data then return y end
    local enemy = (faction == "Alliance") and "Horde" or "Alliance"
    local races = {}
    for r, byFaction in pairs(data) do
        if byFaction[enemy] then races[#races + 1] = r end
    end
    table.sort(races, function(a, b) return RaceName(a) < RaceName(b) end)
    if #races == 0 then return y end

    y = L:SectionHeader(content, y, "Enemy races (" .. enemy .. ")",
        "Cross-checked against your live spellbook CC/DoTs & racials.")
    for _, r in ipairs(races) do
        local theirs = PvPOnly(RacialsFor(r, enemy, nil))
        local notes = Clashes(PvPOnly(mine or {}), theirs, class, myCCTags)
        local bad, good = 0, 0
        for _, n in ipairs(notes) do if n.good then good = good + 1 else bad = bad + 1 end end

        local summaryBits = {}
        local tip = {}
        for _, x in ipairs(theirs) do
            local d = Describe(x)
            summaryBits[#summaryBits + 1] = x.name .. " (" .. d .. ")"
            tip[#tip + 1] = x.name .. ": " .. d
        end
        for _, n in ipairs(notes) do
            tip[#tip + 1] = (n.good and "+ " or "- ") .. n.text
        end
        local noteParts = {}
        if #summaryBits > 0 then noteParts[#noteParts + 1] = table.concat(summaryBits, "  |  ") end
        for i, n in ipairs(notes) do
            if i <= 2 then noteParts[#noteParts + 1] = n.text end
        end

        y = L:DataRow(content, y, {
            label = RaceName(r),
            value = (#theirs > 0) and string.format("%d PvP %s", #theirs, #theirs == 1 and "racial" or "racials") or "Passive only",
            status = (bad > good) and "warn" or ((good > 0) and "good" or "neutral"),
            note = (#noteParts > 0) and table.concat(noteParts, "\n") or nil,
            noteColor = (bad > good) and "warn" or nil,
            tooltipTitle = RaceName(r) .. " (" .. enemy .. ")",
            tooltip = tip,
        })
    end
    return y
end

local function RenderStanding(content, y, rank, honorCur)
    local hasRank = type(rank) == "table"
    local hasHonor = type(honorCur) == "table"
    if not hasRank and not hasHonor then return y, false end

    local hdrRight = hasRank and rank.number ~= nil and string.format("Rank %d", rank.number) or nil
    y = L:SectionHeader(content, y, "Standing & Honor", hdrRight)

    if hasRank then
        y = L:DataRow(content, y, {
            label = "Current rank",
            value = string.format("Rank %d · %s", rank.number or 0, tostring(rank.name or "n/a")),
            bold = true,
            note = rank.isForever and ("Non-decaying Forever Rank Points · Rewards at " .. tostring(rank.vendor)) or nil,
        })
        if rank.isForever and rank.threshold and rank.threshold > 0 then
            local nextLbl = rank.nextRank
                and string.format("Rank %d (%s)", rank.nextRank, tostring(rank.nextTitle or ""))
                or "Next rank"
            y = L:CapBar(content, y, {
                label = "Rank Points to " .. nextLbl,
                value = string.format("%d / %d", rank.earned or 0, rank.threshold),
                current = rank.earned or 0,
                cap = rank.threshold,
                capped = (rank.earned or 0) >= rank.threshold,
            })
            y = L:DataRow(content, y, {
                label = "Total Rank 14 progress",
                value = string.format("%d / %d", rank.totalEarned or 0, rank.totalMax or 24750),
                note = "Weekly cap rises each week up to 24,750 for Rank 14.",
            })
        elseif rank.progress ~= nil then
            local pct = math.max(0, math.min(1, rank.progress))
            y = L:CapBar(content, y, {
                label = "Progress to next rank",
                value = string.format("%.0f%%", pct * 100),
                current = pct, cap = 1, capped = pct >= 1,
            })
        end
    end

    if hasHonor then
        local cap = (honorCur.maxQuantity and honorCur.maxQuantity > 0) and honorCur.maxQuantity or 25000
        y = L:CapBar(content, y, {
            label = "Spendable Honor",
            value = string.format("%d / %d", honorCur.quantity or 0, cap),
            current = honorCur.quantity or 0,
            cap = cap,
            capped = (honorCur.quantity or 0) >= cap,
        })
    end
    return y, true
end

local function RenderTally(content, y, title, fn, hasHonorCurrency)
    local hk, arg2, arg3 = Try(fn)
    hk = Num(hk)
    local honor = Num(arg3) or Num(arg2)
    if hk == nil and honor == nil then return y, false end

    y = L:SectionHeader(content, y, title)
    if hk ~= nil then
        y = L:DataRow(content, y, { label = "Honorable kills", value = Show(hk) })
    end
    if honor ~= nil and (honor > 0 or not hasHonorCurrency) then
        if honor == 0 and (hk or 0) > 0 then
            y = L:DataRow(content, y, {
                label = "Honor",
                value = "Rank Points / Currency",
                note = "Classic session honor reports 0 on Forever; Rank Points and spendable Honor track under Standing & Honor.",
            })
        else
            y = L:DataRow(content, y, { label = "Honor", value = Show(honor) })
        end
    end
    if fn == GetPVPSessionStats and M._sessionStart and time then
        local minutes = (time() - M._sessionStart) / 60
        if minutes >= 10 and ((honor or 0) > 0 or (hk or 0) > 0) then
            local perHour = 60 / minutes
            local paceVal
            if (honor or 0) > 0 then
                paceVal = string.format("%.0f hon · %.1f HK/hr", honor * perHour, (hk or 0) * perHour)
            else
                paceVal = string.format("%.1f HK/hr (%dm)", (hk or 0) * perHour, math.floor(minutes))
            end
            y = L:DataRow(content, y, { label = "Session pace", value = paceVal })
        end
    end
    return y, true
end

local function RenderFooter(content, y)
    y = L:Divider(content, y)
    y = L:Paragraph(content, y,
        "Live reads from this client & harvested Forever racials. Forever uses non-decaying Rank Points + spendable Honor; no rates or rank projections are guessed.",
        { color = L.C_DIM })
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local y = -8
    local level = Num(Try(UnitLevel, "player")) or 1
    local ctx = M.ReadContext()
    local bracket = M.BracketInfo(level)
    local ready = M.ReadReadiness()

    y = RenderContextAndBrackets(content, y, ctx, bracket, ready)
    y = L:Divider(content, y)

    local _, race = Try(UnitRace, "player")
    local faction = Str(Try(UnitFactionGroup, "player"))
    local _, class = Try(UnitClass, "player")
    race, class = Str(race), Str(class)
    local myCCTags = ReadKnownCCTags()

    if race and faction and TA.Data and TA.Data.ForeverRacials then
        local mine
        y, mine = RenderYourRacials(content, y, race, faction, class)
        y = RenderTarget(content, y, faction, class, mine, myCCTags)
        y = L:Divider(content, y)
        y = RenderMatchups(content, y, race, faction, class, mine, myCCTags)
        y = L:Divider(content, y)
    end

    local rank = ReadRank(faction)
    local honorCur = M.ReadHonorCurrency()
    local standingShown = false
    y, standingShown = RenderStanding(content, y, rank, honorCur)
    if standingShown then
        y = L:Divider(content, y)
    end

    local hasCur = type(honorCur) == "table"
    local shown
    y, shown = RenderTally(content, y, "This week",    GetPVPThisWeekStats, hasCur)
    y, shown = RenderTally(content, y, "Last week",    GetPVPLastWeekStats, hasCur)
    y, shown = RenderTally(content, y, "This session", GetPVPSessionStats, hasCur)
    y, shown = RenderTally(content, y, "Lifetime",     GetPVPLifetimeStats, hasCur)

    y = RenderFooter(content, y)
    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "PLAYER_TARGET_CHANGED",
    "PLAYER_PVP_RANK_CHANGED",
    "PLAYER_PVP_KILLS_CHANGED",
    "HONOR_CURRENCY_UPDATE",
    "CURRENCY_DISPLAY_UPDATE",
    "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
    "MAJOR_FACTION_UNLOCKED",
    "PLAYER_FLAGS_CHANGED",
    "UNIT_FACTION",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_EQUIPMENT_CHANGED",
}

return M
