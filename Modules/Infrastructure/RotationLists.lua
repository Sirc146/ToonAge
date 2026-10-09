-- ToonAge/Modules/Infrastructure/RotationLists.lua
-- Reads the per-version rotation list (TA.Data.RotationLists).
--
-- Each version's TOC loads only its own file. The shape is class, then spec,
-- then level band, then a single-target list and an AoE list. An entry is a
-- spell name, a rank chain, and a verified flag. verified = false is shown
-- as approximate. A file-level unverified flag marks every entry the same way.
--
-- The rank used at runtime is the highest rank in that chain the character
-- knows. IsPlayerSpell is checked first, then IsSpellKnown. Rank subtext is
-- not read. Retail Rogue prefers Deathstalker for Assassination and Subtlety,
-- and Trickster for Outlaw. The same preference applies on Forever.
--
-- This file names no C_ function except C_Spell.GetSpellInfo, and only inside
-- the diagnostics check. Combat suggestions on Retail and Forever come from
-- C_AssistedCombat in the rotation modules, not from here.

local TA = ToonAge
TA.Data = TA.Data or {}

local RL = {}
TA.RotationLists = RL

RL.EMPTY = "No verified rotation yet"

-- Retail Rogue, then Forever Rogue, use these hero trees when the data has them.
local HERO = {
    ROGUE = {
        assassination = "Deathstalker",
        subtlety = "Deathstalker",
        outlaw = "Trickster",
    },
}

local SKIP_KEY = {
    unverified = true, flavor = true, note = true, notes = true,
    source = true, comment = true, hero = true, bands = true,
}

local function Soft(text)
    if type(text) ~= "string" then return "" end
    return (text:lower():gsub("[^%a]", ""))
end

local function Token(text)
    if type(text) ~= "string" then return "" end
    return (text:upper():gsub("[^A-Z]", ""))
end

function RL.FileUnverified(data)
    return type(data) == "table" and data.unverified and true or false
end

function RL.ClassNode(data, classToken)
    if type(data) ~= "table" then return nil end
    local want = Token(classToken)
    if want == "" then return nil end
    for key, node in pairs(data) do
        if type(key) == "string" and type(node) == "table" and not SKIP_KEY[key]
            and Token(key) == want then
            return node
        end
    end
    return nil
end

local function RankList(entry)
    local raw = entry.ranks or entry.rankIDs or entry.rankIds or entry.ids or entry.spellIDs
    if type(raw) == "number" then return { raw } end
    if type(raw) ~= "table" then return {} end
    local out = {}
    for _, id in ipairs(raw) do
        id = tonumber(id)
        if id and id > 0 then out[#out + 1] = id end
    end
    return out
end

local function IsEntry(node)
    return type(node) == "table" and type(node.name) == "string"
        and (node.ranks or node.rankIDs or node.rankIds or node.ids or node.spellIDs)
end

local function ListFrom(band, mode)
    if type(band) ~= "table" then return nil end
    local keys = (mode == "aoe")
        and { "aoe", "AOE", "multi", "aoeList" }
        or { "st", "single", "singleTarget", "single_target" }
    for _, key in ipairs(keys) do
        if type(band[key]) == "table" then return band[key] end
    end
    return nil
end

local function ParseLevelKey(key)
    if type(key) ~= "string" then return nil end
    local a, b = key:match("^(%d+)%s*%-%s*(%d+)$")
    if a then return tonumber(a), tonumber(b) end
    local plus = key:match("^(%d+)%s*%+$")
    if plus then return tonumber(plus), 999 end
    local n = key:match("^(%d+)$")
    if n then local v = tonumber(n) return v, v end
    return nil
end

local function AsBand(node, lo, hi)
    if type(node) ~= "table" then return nil end
    local copy = {}
    for k, v in pairs(node) do copy[k] = v end
    copy.min = tonumber(copy.min or copy.minLevel or copy.from) or lo or 1
    copy.max = tonumber(copy.max or copy.maxLevel or copy.to) or hi or 999
    return copy
end

local function IsBand(node)
    if type(node) ~= "table" then return false end
    if ListFrom(node, "st") or ListFrom(node, "aoe") then return true end
    if node.min or node.minLevel or node.from or node.max or node.maxLevel then return true end
    return false
end

--- One hero's ordered bands. Level-range keys and array bands both work.
local function BandsOf(node)
    if type(node) ~= "table" then return {} end
    if type(node.bands) == "table" then return BandsOf(node.bands) end
    if IsBand(node[1]) or (type(node[1]) == "table" and (node[1].st or node[1].aoe or node[1].single)) then
        local out = {}
        for _, band in ipairs(node) do
            local row = AsBand(band)
            if row then out[#out + 1] = row end
        end
        return out
    end
    if IsBand(node) then return { AsBand(node) } end
    local keyed = {}
    for key, child in pairs(node) do
        local lo, hi = ParseLevelKey(key)
        if lo and type(child) == "table" then
            keyed[#keyed + 1] = AsBand(child, lo, hi)
        end
    end
    table.sort(keyed, function(a, b) return (a.min or 0) < (b.min or 0) end)
    return keyed
end

local function HeroNodes(specNode)
    if type(specNode) ~= "table" then return {} end
    if #BandsOf(specNode) > 0 then
        return { { name = specNode.hero, bands = BandsOf(specNode) } }
    end
    local heroes = {}
    for key, child in pairs(specNode) do
        if type(key) == "string" and type(child) == "table" and not SKIP_KEY[key]
            and not ParseLevelKey(key) then
            local bands = BandsOf(child)
            if #bands > 0 or IsBand(child) or type(child.bands) == "table" or child[1] then
                heroes[#heroes + 1] = { name = key, bands = bands }
            end
        end
    end
    table.sort(heroes, function(a, b) return Soft(a.name) < Soft(b.name) end)
    return heroes
end

local function SpecNode(classNode, specName)
    if type(classNode) ~= "table" then return nil, nil end
    if specName then
        local want = Soft(specName)
        for key, node in pairs(classNode) do
            if type(key) == "string" and type(node) == "table" and not SKIP_KEY[key]
                and Soft(key) == want then
                return node, key
            end
        end
        return nil, nil
    end
    return nil, nil
end

local function PreferHero(classToken, specName, heroes)
    if #heroes == 0 then return nil end
    if #heroes == 1 then return heroes[1] end
    local pref = HERO[Token(classToken)]
    local want = pref and specName and pref[Soft(specName)]
    if want then
        for _, hero in ipairs(heroes) do
            if Soft(hero.name) == Soft(want) then return hero end
        end
    end
    return heroes[1]
end

local function BandAt(bands, level)
    if not bands or #bands == 0 then return nil end
    if type(level) ~= "number" then
        local best = bands[1]
        for i = 2, #bands do
            if (bands[i].max or 0) > (best.max or 0) then best = bands[i] end
        end
        return best
    end
    local best
    for _, band in ipairs(bands) do
        local lo = band.min or 1
        local hi = band.max or 999
        if level >= lo and level <= hi then
            local span = hi - lo
            local bestSpan = best and ((best.max or 999) - (best.min or 1)) or nil
            if not best or span < bestSpan then best = band end
        end
    end
    return best
end

function RL.CanAsk()
    return type(IsPlayerSpell) == "function" or type(IsSpellKnown) == "function"
end

function RL.Knows(spellID)
    if type(spellID) ~= "number" then return false end
    if type(IsPlayerSpell) == "function" then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known == true then return true end
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known == true then return true end
    end
    return false
end

--- Highest known rank in chain order. The last known id wins, not the
--- largest spell id. When the character knows none of them, the first rank
--- is what the list shows. When neither spell API exists, the last rank is
--- shown so a client that cannot answer still has a row.
function RL.PickRank(ranks)
    if type(ranks) ~= "table" or #ranks == 0 then return nil end
    if not RL.CanAsk() then return ranks[#ranks] end
    local best
    for _, id in ipairs(ranks) do
        if RL.Knows(id) then best = id end
    end
    return best or ranks[1]
end

local function SpellsFrom(list, fileUnverified)
    local spells = {}
    if type(list) ~= "table" then return spells end
    for _, entry in ipairs(list) do
        if IsEntry(entry) then
            local ranks = RankList(entry)
            local id = RL.PickRank(ranks)
            local approximate = (fileUnverified or entry.verified == false) and true or false
            spells[#spells + 1] = {
                name = entry.name,
                spellID = id,
                ranks = ranks,
                verified = not approximate,
                approximate = approximate,
            }
        end
    end
    return spells
end

--- nil when this class is not in the file. empty when the band or the list
--- has no spells. Otherwise the spells for that level, with a rank picked.
function RL.Resolve(data, classToken, specName, level, mode)
    data = data or (TA.Data and TA.Data.RotationLists)
    local classNode = RL.ClassNode(data, classToken)
    if not classNode then return nil end
    mode = (mode == "aoe") and "aoe" or "st"
    local spec = SpecNode(classNode, specName)
    local heroes
    if specName and not spec then
        -- Named spec is not in this class. That is not an empty band.
        return nil
    end
    if spec then
        heroes = HeroNodes(spec)
    else
        -- No spec yet. One spec with spells can be shown. Several cannot,
        -- and a class whose bands are all empty (Mists Death Knight below 55)
        -- is the empty card rather than a guess.
        local names = {}
        for key, node in pairs(classNode) do
            if type(key) == "string" and type(node) == "table" and not SKIP_KEY[key] then
                names[#names + 1] = key
            end
        end
        table.sort(names)
        local filled
        local any = false
        for _, key in ipairs(names) do
            local hero = PreferHero(classToken, key, HeroNodes(classNode[key]))
            local band = hero and BandAt(hero.bands, level)
            local spells = band and SpellsFrom(ListFrom(band, mode), false) or {}
            any = true
            if #spells > 0 then
                if filled then return { empty = true, spells = {}, mode = mode } end
                filled = hero
            end
        end
        if not any then return { empty = true, spells = {}, mode = mode } end
        heroes = filled and { filled } or {}
    end
    local hero = PreferHero(classToken, specName, heroes)
    if not hero then
        return { empty = true, spells = {}, mode = mode }
    end
    local band = BandAt(hero.bands, level)
    if not band then
        return { empty = true, spells = {}, mode = mode, hero = hero.name }
    end
    local spells = SpellsFrom(ListFrom(band, mode), RL.FileUnverified(data))
    if #spells == 0 then
        return { empty = true, spells = {}, mode = mode, hero = hero.name }
    end
    return {
        empty = false,
        spells = spells,
        mode = mode,
        hero = hero.name,
        min = band.min,
        max = band.max,
    }
end

--- First three spells for the gold bar. In combat on Retail and Forever the
--- caller passes Assisted Combat's spell as the first slot. A secret result
--- is passed as nil, so the fixed list stays as it was set up.
function RL.BarPlan(spells, assisted, inCombat)
    local out = {}
    if inCombat and type(assisted) == "table" and type(assisted.spellID) == "number" then
        out[1] = {
            spellID = assisted.spellID,
            name = assisted.name or "",
            suggested = true,
        }
    end
    for _, spell in ipairs(spells or {}) do
        if #out >= 3 then break end
        if type(spell.spellID) == "number" then
            local dup = out[1] and out[1].spellID == spell.spellID
            if not dup then out[#out + 1] = spell end
        end
    end
    return out
end

function RL.DrawList(content, y, L, view, title)
    if not L then return y end
    y = L:SectionHeader(content, y, title or "ROTATION")
    if not view or view.empty or not view.spells or #view.spells == 0 then
        return L:Paragraph(content, y, RL.EMPTY)
    end
    for i, spell in ipairs(view.spells) do
        local text = string.format("%d. %s", i, spell.name or "")
        if spell.approximate then text = text .. "  (approximate)" end
        y = L:Bullet(content, y, text)
    end
    return y
end

local function WalkIDs(node, acc, seen)
    if type(node) ~= "table" or seen[node] then return end
    seen[node] = true
    if IsEntry(node) then
        for _, id in ipairs(RankList(node)) do
            acc[#acc + 1] = { id = id, name = node.name }
        end
        return
    end
    for _, child in pairs(node) do
        if type(child) == "table" then WalkIDs(child, acc, seen) end
    end
end

function RL.AllSpellIDs(data)
    data = data or (TA.Data and TA.Data.RotationLists)
    local acc = {}
    if type(data) == "table" then WalkIDs(data, acc, {}) end
    return acc
end

--- lookup(spellID) is C_Spell.GetSpellInfo. A miss is a failed call, a secret
--- name, or a result with no name. nil lookup means the function is absent.
function RL.Misses(lookup, data)
    data = data or (TA.Data and TA.Data.RotationLists)
    if type(data) ~= "table" then return nil, 0 end
    local ids = RL.AllSpellIDs(data)
    if type(lookup) ~= "function" then return {}, #ids, false end
    local U = TA.Utils
    local misses = {}
    for _, row in ipairs(ids) do
        local ok, info = pcall(lookup, row.id)
        local name = info
        if ok and type(info) == "table" then name = info.name end
        if not ok or (U and U.IsSecret and U.IsSecret(name)) or type(name) ~= "string" or name == "" then
            misses[#misses + 1] = row
        end
    end
    return misses, #ids, true
end

function RL.StatusLine()
    local lookup
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        lookup = C_Spell.GetSpellInfo
    end
    local misses, n, asked = RL.Misses(lookup)
    if not misses then return "Rotation spells: no list" end
    if not asked then
        return string.format("Rotation spells: %d ids, GetSpellInfo absent", n)
    end
    if #misses == 0 then
        return string.format("Rotation spells: %d ids, none missed", n)
    end
    local parts = {}
    local show = math.min(#misses, 8)
    for i = 1, show do
        parts[#parts + 1] = string.format("%s (%d)", misses[i].name or "?", misses[i].id)
    end
    local extra = ""
    if #misses > show then
        extra = string.format(" and %d more", #misses - show)
    end
    return string.format("Rotation spells: %d missed of %d: %s%s",
        #misses, n, table.concat(parts, ", "), extra)
end
