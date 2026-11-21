-- ToonAge/Modules/Forever/TalentIntel.lua  (WoW Forever)
--
-- Pure talent intelligence helpers for Modules/Forever/Talents.lua and Now.lua:
--   1. Spell-Filter Pills & live tooltip description reader (cached, secret-safe)
--   2. Exact Level-Unlock calculation (Lv 10..60 from spent/unspent + gate)
--   3. Full Sandbox Plan Mode (+1/-1 scratchpad, Multi-Milestone Roadmap, Saved Plans)
--   4. Live Reality Callouts: deterministic single-spell tooltip math,
--      ForeverCastLog actual cast-share mirror, and ForeverGear stat match.
--
-- Never calls any C_Traits spend/commit API. Never invents stat weights or BiS.

local TA = ToonAge
local TI = {}
TA.TalentIntel = TI

local TALENT_MIN_LEVEL = 10
local MAX_LEVEL        = 60
local MAX_TALENT_PTS   = 51   -- Vanilla cap 60: 1 point per level from 10..60
local PLAN_HONEST_NOTE = "Read-only planner & live tooltip math. Never spends points or claims raid-sim BiS."

local SLOT_ORDER = { "Solo", "Dungeon", "PvP" }

local EQUIP_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Secret(v)
    if v == nil then return false end
    if TA.Utils and TA.Utils.IsSecret and TA.Utils.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function PlainStr(v)
    if v == nil or Secret(v) then return nil end
    if type(v) ~= "string" then return nil end
    if TA.Utils and TA.Utils.StripMarkup then
        v = TA.Utils.StripMarkup(v)
    else
        v = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    return v ~= "" and v or nil
end

local function PlainNum(v)
    if v == nil or Secret(v) then return nil end
    return tonumber(tostring(v))
end

-- ─── 1. LIVE SPELL DESCRIPTION READER (CACHED) ─────────────────────────────

local descCache = {}

function TI.ClearCache()
    descCache = {}
end

--- Read description text and raw lines for one spellID via C_TooltipInfo.GetSpellByID.
--- Cached per spellID. Combat-secret safe.
function TI.ReadSpellDesc(spellID)
    if type(spellID) ~= "number" then return "", {} end
    local hit = descCache[spellID]
    if hit then return hit.desc, hit.lines end

    local lines = {}
    if C_TooltipInfo and C_TooltipInfo.GetSpellByID then
        local tip = Try(C_TooltipInfo.GetSpellByID, spellID)
        if type(tip) == "table" and type(tip.lines) == "table" then
            for _, ln in ipairs(tip.lines) do
                if type(ln) == "table" then
                    local left = PlainStr(ln.leftText)
                    if left then lines[#lines + 1] = left end
                end
            end
        end
    end

    -- Collect body lines: skip title (line 1) and short metadata lines (Rank, Cast time, Range, Mana)
    local body = {}
    for i = 2, #lines do
        local s = lines[i]
        local low = string.lower(s)
        local isMeta = low:find("^rank %d") ~= nil
            or low:find("^%d+ mana$") ~= nil
            or low:find("^%d+ yd range$") ~= nil
            or low == "instant"
            or low == "instant cast"
            or low:find("^%d+%.?%d* sec cast$") ~= nil
            or low:find("^next rank:") ~= nil
            or low:find("^requires ") ~= nil
        if not isMeta then
            body[#body + 1] = s
        end
    end
    local desc = table.concat(body, " ")
    if #lines > 0 then
        descCache[spellID] = { desc = desc, lines = lines }
    end
    return desc, lines
end

-- ─── 2. SPELL & PLAYSTYLE FILTER PILLS ─────────────────────────────────────

local PLAYSTYLE_FILTERS = {
    {
        key = "damage",
        label = "Damage",
        patterns = { "damage", "critical strike", "crit", "cast time", "casting time", "spell power", "attack power", "haste" },
    },
    {
        key = "mana",
        label = "Mana/Res",
        patterns = { "mana", "clearcasting", "regeneration", "spirit", "rage", "energy", "focus", "cost" },
    },
    {
        key = "control",
        label = "Control/Surv",
        patterns = { "chill", "freeze", "frozen", "snare", "stun", "root", "armor", "resist", "shield", "barrier", "health", "threat", "dodge", "parry", "block", "silence", "counterspell" },
    },
    {
        key = "aoe",
        label = "AoE",
        patterns = { "blizzard", "flamestrike", "arcane explosion", "cone of cold", "frost nova", "blast wave", "cleave", "whirlwind", "multi%-shot", "volley", "rain of fire", "hellfire", "consecration", "chain lightning", "area" },
    },
}

--- Known spell names from the player's spellbook (excluding General), used to
--- discover real spell filter pills referenced by the current talent tree.
local function KnownBookSpells()
    local names = {}
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return names end
    local numLines = PlainNum(Try(C_SpellBook.GetNumSpellBookSkillLines))
    if not numLines then return names end
    local seen = {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    for line = 1, numLines do
        local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if type(info) == "table" and info.name ~= "General" and info.numSpellBookItems then
            local off = PlainNum(info.itemIndexOffset) or 0
            local cnt = PlainNum(info.numSpellBookItems) or 0
            for i = off + 1, off + cnt do
                local item = Try(C_SpellBook.GetSpellBookItemInfo, i, bank)
                local nm = type(item) == "table" and PlainStr(item.name) or nil
                if nm and #nm >= 4 and not seen[nm] then
                    seen[nm] = true
                    names[#names + 1] = nm
                end
            end
        end
    end
    return names
end

--- Discover filter pills for the current talent tree:
--- All + matching Playstyle pills + top referenced class spell pills (up to 4).
function TI.DiscoverFilters(nodes, descFn, knownSpells)
    local pills = { { key = "all", label = "All", kind = "all" } }
    if type(nodes) ~= "table" or #nodes == 0 then return pills end

    local getDesc = descFn or function(n)
        if type(n.desc) == "string" then return n.desc end
        local d = TI.ReadSpellDesc(n.spellID)
        return d
    end

    local nodeTexts = {}
    for i, n in ipairs(nodes) do
        local d = getDesc(n) or ""
        nodeTexts[i] = string.lower((tostring(n.name or "")) .. " " .. d)
    end

    -- Add playstyle pills that match at least 1 node
    for _, pf in ipairs(PLAYSTYLE_FILTERS) do
        local hits = 0
        for _, txt in ipairs(nodeTexts) do
            for _, pat in ipairs(pf.patterns) do
                if txt:find(pat) then
                    hits = hits + 1
                    break
                end
            end
        end
        if hits > 0 then
            pills[#pills + 1] = { key = pf.key, label = pf.label, kind = "style", count = hits }
        end
    end

    -- Discover top class spells mentioned in multiple talent descriptions
    local candidates = {}
    local candSeen = {}
    local function addCand(nm)
        if type(nm) ~= "string" or #nm < 4 then return end
        local low = string.lower(nm)
        if candSeen[low] then return end
        candSeen[low] = true
        candidates[#candidates + 1] = { name = nm, low = low }
    end

    local book = knownSpells or KnownBookSpells()
    for _, nm in ipairs(book) do addCand(nm) end

    -- Also extract "Improved <Spell>" names straight from the tree itself so
    -- spell pills work even before the player has trained higher-level spells.
    for _, n in ipairs(nodes) do
        local nm = type(n.name) == "string" and n.name or ""
        local base = nm:match("^Improved%s+(.+)$")
        if base and #base >= 4 then addCand(base) end
    end

    local scored = {}
    for _, c in ipairs(candidates) do
        local hits = 0
        for _, txt in ipairs(nodeTexts) do
            if txt:find(c.low, 1, true) then
                hits = hits + 1
            end
        end
        if hits >= 2 then
            scored[#scored + 1] = { name = c.name, low = c.low, count = hits }
        end
    end
    table.sort(scored, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)

    for i = 1, math.min(#scored, 4) do
        local sp = scored[i]
        pills[#pills + 1] = {
            key = "spell:" .. sp.low,
            label = sp.name,
            kind = "spell",
            count = sp.count,
        }
    end

    return pills
end

--- True when one node matches the active filter key.
function TI.NodeMatchesFilter(node, desc, filterKey)
    if not filterKey or filterKey == "all" then return true end
    local txt = string.lower((tostring(node and node.name or "")) .. " " .. tostring(desc or ""))
    if filterKey:sub(1, 6) == "spell:" then
        local needle = filterKey:sub(7)
        return needle ~= "" and txt:find(needle, 1, true) ~= nil
    end
    for _, pf in ipairs(PLAYSTYLE_FILTERS) do
        if pf.key == filterKey then
            for _, pat in ipairs(pf.patterns) do
                if txt:find(pat) then return true end
            end
            return false
        end
    end
    return true
end

-- ─── 3. EXACT LEVEL-UNLOCK CALCULATION ─────────────────────────────────────

--- Exact character level at which a locked node's spent-point gate can open,
--- assuming 1 talent point per level from Lv 10..60.
--- Returns unlockLevel, pointsAway (both nil when already unlocked or unknown).
function TI.UnlockLevel(node, conds, spent, unspent, playerLevel, minReqFn, nodeGateFn)
    if type(node) ~= "table" then return nil, nil end
    local lvl = tonumber(playerLevel)
    if not lvl or lvl < TALENT_MIN_LEVEL then return nil, nil end
    local s = tonumber(spent) or 0
    local u = tonumber(unspent) or 0
    local locked, unmet = false, nil
    if type(nodeGateFn) == "function" then
        locked, unmet = nodeGateFn(node, conds or {}, s)
    end
    local req = unmet
    if not req and locked and type(minReqFn) == "function" then
        req = minReqFn(node, conds or {})
    end
    if not locked or type(req) ~= "number" then return nil, nil end
    local totalAvail = s + u
    local needMore = math.max(0, req - totalAvail)
    local unlockLv = math.min(MAX_LEVEL, lvl + needMore)
    return unlockLv, needMore
end

-- ─── 4. SANDBOX PLANNER, MULTI-MILESTONE ROADMAP & SAVED PLANS ─────────────

local fallbackStore = nil

function TI.GetStore()
    local root
    if TA.charDB then
        TA.charDB.talentPlans = TA.charDB.talentPlans or {}
        root = TA.charDB.talentPlans
    else
        fallbackStore = fallbackStore or {}
        root = fallbackStore
    end
    root.activeSlot = root.activeSlot or SLOT_ORDER[1]
    root.slots = root.slots or {}
    for _, name in ipairs(SLOT_ORDER) do
        root.slots[name] = root.slots[name] or { targets = {}, sandbox = {} }
        root.slots[name].targets = root.slots[name].targets or {}
        root.slots[name].sandbox = root.slots[name].sandbox or {}
    end
    if not root.slots[root.activeSlot] then
        root.slots[root.activeSlot] = { targets = {}, sandbox = {} }
    end
    return root
end

function TI.ActiveSlot()
    local st = TI.GetStore()
    return st.slots[st.activeSlot], st.activeSlot
end

function TI.CycleSlot()
    local st = TI.GetStore()
    local idx = 1
    for i, name in ipairs(SLOT_ORDER) do
        if name == st.activeSlot then idx = i; break end
    end
    local nextName = SLOT_ORDER[(idx % #SLOT_ORDER) + 1]
    st.activeSlot = nextName
    return st.slots[nextName], nextName
end

function TI.SelectSlot(name)
    if type(name) ~= "string" or name == "" then return TI.ActiveSlot() end
    local st = TI.GetStore()
    st.slots[name] = st.slots[name] or { targets = {}, sandbox = {} }
    st.slots[name].targets = st.slots[name].targets or {}
    st.slots[name].sandbox = st.slots[name].sandbox or {}
    st.activeSlot = name
    return st.slots[name], name
end

function TI.ToggleMilestone(nodeID)
    if nodeID == nil then return false end
    local slot = TI.ActiveSlot()
    for i, id in ipairs(slot.targets) do
        if id == nodeID then
            table.remove(slot.targets, i)
            return false
        end
    end
    slot.targets[#slot.targets + 1] = nodeID
    return true
end

function TI.HasMilestone(nodeID)
    if nodeID == nil then return false end
    local slot = TI.ActiveSlot()
    for _, id in ipairs(slot.targets) do
        if id == nodeID then return true end
    end
    return false
end

function TI.ClearMilestones()
    local slot = TI.ActiveSlot()
    slot.targets = {}
end

function TI.SandboxTotals(nodes, spent, playerLevel)
    local slot = TI.ActiveSlot()
    local added = 0
    local byID = {}
    if type(nodes) == "table" then
        for _, n in ipairs(nodes) do
            if type(n) == "table" and n.id ~= nil then byID[n.id] = n end
        end
    end
    for id, pts in pairs(slot.sandbox) do
        local n = tonumber(pts) or 0
        if n > 0 and (next(byID) == nil or byID[id] ~= nil) then
            added = added + n
        end
    end
    local curSpent = tonumber(spent) or 0
    local totalSpent = curSpent + added
    local lvl = tonumber(playerLevel) or TALENT_MIN_LEVEL
    local buildLevel = math.min(MAX_LEVEL, math.max(lvl, (TALENT_MIN_LEVEL - 1) + totalSpent))
    return {
        added = added,
        totalSpent = totalSpent,
        buildLevel = buildLevel,
        cap = MAX_TALENT_PTS,
    }
end

function TI.SandboxDelta(nodeID)
    local slot = TI.ActiveSlot()
    return tonumber(slot.sandbox[nodeID]) or 0
end

--- Add +1 planned point in Sandbox mode (never spends real talent points).
function TI.SandboxAdd(node, nodes, spent)
    if type(node) ~= "table" or node.id == nil then return false, "invalid node" end
    local slot = TI.ActiveSlot()
    local totals = TI.SandboxTotals(nodes, spent, TALENT_MIN_LEVEL)
    if totals.totalSpent >= MAX_TALENT_PTS then
        return false, "51-point cap (Lv 60) reached"
    end
    local base = tonumber(node.rank) or 0
    local max = tonumber(node.max) or 1
    local cur = tonumber(slot.sandbox[node.id]) or 0
    if base + cur >= max then
        return false, "already at max rank"
    end
    slot.sandbox[node.id] = cur + 1
    return true, nil
end

--- Remove -1 planned point in Sandbox mode.
function TI.SandboxRemove(nodeID)
    if nodeID == nil then return false end
    local slot = TI.ActiveSlot()
    local cur = tonumber(slot.sandbox[nodeID]) or 0
    if cur <= 0 then return false end
    if cur <= 1 then
        slot.sandbox[nodeID] = nil
    else
        slot.sandbox[nodeID] = cur - 1
    end
    return true
end

function TI.SandboxClear()
    local slot = TI.ActiveSlot()
    slot.sandbox = {}
end

--- Build a combined multi-milestone roadmap across all pinned targets.
function TI.BuildRoadmap(nodes, conds, targets, spent, unspent, playerLevel, planRouteFn)
    local out = {
        valid = false,
        steps = {},
        inPath = {},
        inPathEdge = {},
        milestones = {},
        totalPointsNeeded = 0,
        gateNeed = 0,
        nextNode = nil,
        honestNote = PLAN_HONEST_NOTE,
    }
    if type(nodes) ~= "table" or type(targets) ~= "table" or #targets == 0 or type(planRouteFn) ~= "function" then
        return out
    end

    local curSpent = tonumber(spent) or 0
    local curUnspent = tonumber(unspent) or 0
    local lvl = tonumber(playerLevel) or TALENT_MIN_LEVEL
    local simSpent = curSpent
    local stepSeen = {}
    local stepPts = {}

    for _, tid in ipairs(targets) do
        local r = planRouteFn(nodes, conds or {}, tid, simSpent)
        if type(r) == "table" and r.valid then
            out.valid = true
            for k, v in pairs(r.inPathEdge or {}) do
                if v then out.inPathEdge[k] = true end
            end
            for _, st in ipairs(r.steps or {}) do
                if not stepSeen[st.id] then
                    local idx = #out.steps + 1
                    local copy = {
                        id = st.id,
                        name = st.name,
                        rank = st.rank,
                        max = st.max,
                        pointsNeeded = st.pointsNeeded,
                        gate = st.gate,
                        gateNeed = st.gateNeed,
                    }
                    out.steps[idx] = copy
                    out.inPath[st.id] = idx
                    stepSeen[st.id] = idx
                    stepPts[st.id] = st.pointsNeeded or 0
                    if idx == 1 then out.gateNeed = st.gateNeed or 0 end
                    simSpent = simSpent + (st.gateNeed or 0) + (st.pointsNeeded or 0)
                else
                    -- If an earlier step was a 1-pt prereq and is now itself a
                    -- milestone target, bump its needed points to max.
                    local idx = stepSeen[st.id]
                    if (st.pointsNeeded or 0) > (stepPts[st.id] or 0) then
                        local extra = (st.pointsNeeded or 0) - (stepPts[st.id] or 0)
                        out.steps[idx].pointsNeeded = st.pointsNeeded
                        stepPts[st.id] = st.pointsNeeded
                        simSpent = simSpent + extra
                    end
                end
            end
            local ptsAway = math.max(0, simSpent - curSpent)
            local extraLevels = math.max(0, ptsAway - curUnspent)
            out.milestones[#out.milestones + 1] = {
                id = r.targetID,
                name = r.targetName,
                alreadyMaxed = r.alreadyMaxed,
                pointsAway = ptsAway,
                unlockLevel = math.min(MAX_LEVEL, lvl + extraLevels),
            }
        end
    end

    out.totalPointsNeeded = math.max(0, simSpent - curSpent)
    out.nextNode = out.steps[1]
    return out
end

-- ─── 5. LIVE REALITY CALLOUTS (SINGLE-SPELL MATH + CASTS + GEAR) ───────────

local SCHOOLS = { "Arcane", "Fire", "Frost", "Shadow", "Nature", "Holy" }

local function DetectSchool(text)
    local low = string.lower(tostring(text or ""))
    for _, sc in ipairs(SCHOOLS) do
        if low:find(string.lower(sc), 1, true) then
            return sc
        end
    end
    return nil
end

--- Read live base cast time (sec) and tooltip average damage for a named spell
--- in the player's spellbook, when available.
local function LiveSpellBaseline(spellName, lookupFn)
    if type(spellName) ~= "string" or spellName == "" then return nil end
    if type(lookupFn) == "function" then
        return lookupFn(spellName)
    end
    if not (C_Spell and C_Spell.GetSpellInfo) then return nil end
    local info = Try(C_Spell.GetSpellInfo, spellName)
    if type(info) ~= "table" then return nil end
    local sid = PlainNum(info.spellID)
    local castMs = PlainNum(info.castTime) or 0
    local castSec = castMs / 1000
    local avgDmg = nil
    if sid then
        local desc = TI.ReadSpellDesc(sid)
        local lo, hi = desc:match("(%d+)%s+to%s+(%d+)%s+%a*%s*damage")
        if lo and hi then
            avgDmg = (tonumber(lo) + tonumber(hi)) / 2
        else
            local flat = desc:match("for%s+(%d+)%s+%a*%s*damage")
            if flat then avgDmg = tonumber(flat) end
        end
    end
    local manaCost = nil
    if sid and C_Spell.GetSpellPowerCost then
        local costs = Try(C_Spell.GetSpellPowerCost, sid)
        if type(costs) == "table" and type(costs[1]) == "table" then
            manaCost = PlainNum(costs[1].cost)
        end
    end
    return { spellID = sid, castSec = castSec, avgDmg = avgDmg, manaCost = manaCost }
end

--- Deterministic single-spell tooltip math from a talent description.
--- Never invents raid DPS or stat weights; marks non-deterministic talents honestly.
function TI.SpellMath(node, desc, spellLookupFn)
    local text = tostring(desc or "")
    if text == "" then
        return { hasMath = false, text = "Effect: open tooltip in-game for live rank text." }
    end
    local low = string.lower(text)

    -- 1. Cast time reduction: "Reduces the casting time of your Frostbolt spell by 0.5 sec."
    local castSpell, castDelta = text:match("[Rr]educes the cast[ing]* time of [your ]*([A-Z][A-Za-z%s']-)%s+spell[s]* by (%d+%.?%d*) sec")
    if not castSpell then
        castSpell, castDelta = text:match("[Rr]educes the cast[ing]* time of ([A-Z][A-Za-z%s']-) by (%d+%.?%d*) sec")
    end
    if castSpell and tonumber(castDelta) then
        local d = tonumber(castDelta)
        local sp = castSpell:gsub("%s+$", "")
        local base = LiveSpellBaseline(sp, spellLookupFn)
        if base and base.castSec and base.castSec > d and base.castSec > 0 then
            local newCast = math.max(1.5, base.castSec - d)
            local pctGain = ((base.castSec / newCast) - 1) * 100
            local detail = string.format("Math (%s, tooltip): %.2fs -> %.2fs (+%.1f%% cast throughput",
                sp, base.castSec, newCast, pctGain)
            if base.avgDmg and base.avgDmg > 0 then
                detail = detail .. string.format(", %.1f -> %.1f single-spell DPS",
                    base.avgDmg / base.castSec, base.avgDmg / newCast)
            end
            return { hasMath = true, spellName = sp, pctGain = pctGain, text = detail .. ")" }
        end
        return {
            hasMath = true,
            spellName = sp,
            text = string.format("Math (%s, tooltip): -%.2fs cast time per tooltip (single-spell only).", sp, d),
        }
    end

    -- 2. Direct damage percentage: "Increases the damage done by your Fireball by 10%"
    local dmgSpell, dmgPct = text:match("[Ii]ncreases the damage done by [your ]*([A-Z][A-Za-z%s']-)%s+by (%d+%.?%d*)%%")
    if not dmgSpell then
        dmgSpell, dmgPct = text:match("[Ii]ncreases the damage of [your ]*([A-Z][A-Za-z%s']-)%s+by (%d+%.?%d*)%%")
    end
    if dmgSpell and tonumber(dmgPct) then
        local p = tonumber(dmgPct)
        local sp = dmgSpell:gsub("%s+spell[s]*$", ""):gsub("%s+$", "")
        local base = LiveSpellBaseline(sp, spellLookupFn)
        if base and base.avgDmg and base.avgDmg > 0 then
            local after = base.avgDmg * (1 + p / 100)
            return {
                hasMath = true,
                spellName = sp,
                pctGain = p,
                text = string.format("Math (%s, tooltip): +%.0f%% dmg (%.0f -> %.0f avg hit; tooltip-only).",
                    sp, p, base.avgDmg, after),
            }
        end
        return {
            hasMath = true,
            spellName = sp,
            pctGain = p,
            text = string.format("Math (%s, tooltip): +%.0f%% direct damage (single-spell tooltip math).", sp, p),
        }
    end

    -- 3. Critical strike chance bonus
    local critPct = low:match("critical strike chance[^%%]+by (%d+%.?%d*)%%")
    if critPct and tonumber(critPct) then
        local p = tonumber(critPct)
        -- Vanilla base spell crit multiplier is 1.5x (+0.5% expected dmg per 1% crit before crit-dmg talents)
        local est = p * 0.5
        return {
            hasMath = true,
            pctGain = est,
            text = string.format("Math (tooltip): +%.0f%% crit (~+%.1f%% avg dmg at 1.5x base crit).", p, est),
        }
    end

    -- 4. Mana cost reduction
    local manaPct = low:match("reduces the mana cost[^%%]+by (%d+%.?%d*)%%")
    if manaPct and tonumber(manaPct) then
        local p = tonumber(manaPct)
        return {
            hasMath = true,
            text = string.format("Math (tooltip): -%.0f%% mana cost (longer sustain before drinking).", p),
        }
    end

    return {
        hasMath = false,
        text = "Effect: utility/proc talent (no deterministic single-spell DPS formula).",
    }
end

--- Summarize recent recorded fights from ForeverCastLog (out of combat).
function TI.ReadCastStats(fightsOverride, spellNameFn)
    local fights = fightsOverride
    if fights == nil then
        fights = TA.charDB and TA.charDB.castLog and TA.charDB.castLog.fights or {}
    end
    local out = { fights = 0, totalCasts = 0, byName = {} }
    if type(fights) ~= "table" or #fights == 0 then return out end

    local getName = spellNameFn or function(sid)
        if C_Spell and C_Spell.GetSpellName then
            local n = PlainStr(Try(C_Spell.GetSpellName, sid))
            if n then return n end
        end
        return nil
    end

    local limit = math.min(#fights, 10)
    for i = 1, limit do
        local f = fights[i]
        if type(f) == "table" and type(f.casts) == "table" and #f.casts > 0 then
            out.fights = out.fights + 1
            for _, c in ipairs(f.casts) do
                local sid = type(c) == "table" and c[2] or nil
                local nm = sid and getName(sid) or nil
                if nm then
                    out.totalCasts = out.totalCasts + 1
                    local low = string.lower(nm)
                    local entry = out.byName[low]
                    if not entry then
                        entry = { name = nm, count = 0, pct = 0 }
                        out.byName[low] = entry
                    end
                    entry.count = entry.count + 1
                end
            end
        end
    end
    if out.totalCasts > 0 then
        for _, entry in pairs(out.byName) do
            entry.pct = math.floor((entry.count / out.totalCasts) * 100 + 0.5)
        end
    end
    return out
end

--- Match a talent's referenced spell(s) against your real Casts history.
function TI.CastReality(node, desc, castStats)
    local stats = castStats or TI.ReadCastStats()
    if not stats or stats.fights == 0 or stats.totalCasts == 0 then
        return "Casts: no fights logged yet (fight a mob to see your real cast share)."
    end
    local hay = string.lower((tostring(node and node.name or "")) .. " " .. tostring(desc or ""))
    local best = nil
    for low, entry in pairs(stats.byName) do
        if #low >= 4 and hay:find(low, 1, true) then
            if not best or entry.count > best.count then
                best = entry
            end
        end
    end
    if best then
        local tag = (best.pct >= 30) and "high match" or ((best.pct >= 10) and "active spell" or "low share")
        return string.format("Casts (%d %s): %s is %d%% of your casts (%d/%d) -- %s.",
            stats.fights, stats.fights == 1 and "fight" or "fights",
            best.name, best.pct, best.count, stats.totalCasts, tag)
    end
    -- Check if talent names a specific "Improved X" spell that was cast 0 times
    local nm = type(node and node.name) == "string" and node.name or ""
    local imp = nm:match("^Improved%s+(.+)$")
    if imp then
        return string.format("Casts (%d %s): %s cast 0%% recently -- rarely used.",
            stats.fights, stats.fights == 1 and "fight" or "fights", imp)
    end
    return string.format("Casts (%d %s, %d casts): passive/general talent.",
        stats.fights, stats.fights == 1 and "fight" or "fights", stats.totalCasts)
end

--- Sum live equipped item stats across gear slots via C_Item.GetItemStats.
function TI.ReadEquippedStats()
    local s = {
        arcane = 0, fire = 0, frost = 0, shadow = 0, nature = 0, holy = 0,
        spellPower = 0, crit = 0, hit = 0, intellect = 0, spirit = 0, attackPower = 0,
    }
    if not (GetInventoryItemLink and C_Item and C_Item.GetItemStats) then return s end
    for _, slotID in ipairs(EQUIP_SLOTS) do
        local link = Try(GetInventoryItemLink, "player", slotID)
        if type(link) == "string" and not Secret(link) then
            local tbl = Try(C_Item.GetItemStats, link)
            if type(tbl) == "table" then
                s.arcane      = s.arcane      + (PlainNum(tbl.ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT) or 0)
                s.fire        = s.fire        + (PlainNum(tbl.ITEM_MOD_FIRE_DAMAGE_DONE_SHORT) or 0)
                s.frost       = s.frost       + (PlainNum(tbl.ITEM_MOD_FROST_DAMAGE_DONE_SHORT) or 0)
                s.shadow      = s.shadow      + (PlainNum(tbl.ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT) or 0)
                s.nature      = s.nature      + (PlainNum(tbl.ITEM_MOD_NATURE_DAMAGE_DONE_SHORT) or 0)
                s.holy        = s.holy        + (PlainNum(tbl.ITEM_MOD_HOLY_DAMAGE_DONE_SHORT) or 0)
                s.spellPower  = s.spellPower  + (PlainNum(tbl.ITEM_MOD_SPELL_POWER_SHORT) or 0)
                                              + (PlainNum(tbl.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT) or 0)
                s.crit        = s.crit        + (PlainNum(tbl.ITEM_MOD_CRIT_RATING_SHORT) or 0)
                s.hit         = s.hit         + (PlainNum(tbl.ITEM_MOD_HIT_RATING_SHORT) or 0)
                s.intellect   = s.intellect   + (PlainNum(tbl.ITEM_MOD_INTELLECT_SHORT) or 0)
                s.spirit      = s.spirit      + (PlainNum(tbl.ITEM_MOD_SPIRIT_SHORT) or 0)
                s.attackPower = s.attackPower + (PlainNum(tbl.ITEM_MOD_ATTACK_POWER_SHORT) or 0)
            end
        end
    end
    return s
end

--- Match a talent's school / crit / resource tags against your live equipped gear.
function TI.GearReality(node, desc, stats, playerLevel)
    local eq = stats or TI.ReadEquippedStats()
    local txt = tostring(node and node.name or "") .. " " .. tostring(desc or "")
    local low = string.lower(txt)
    local school = DetectSchool(txt)
    local lvl = tonumber(playerLevel) or 0

    if school then
        local schoolKey = string.lower(school)
        local schoolDmg = tonumber(eq[schoolKey]) or 0
        local sp = tonumber(eq.spellPower) or 0
        if schoolDmg > 0 or sp > 0 then
            return string.format("Gear (%s): +%d %s dmg, +%d Spell Power equipped (scales this talent).",
                school, schoolDmg, school, sp)
        end
        return string.format("Gear (%s): +0 %s dmg, +%d Int, +%d Spi equipped.",
            school, school, tonumber(eq.intellect) or 0, tonumber(eq.spirit) or 0)
    end

    if low:find("critical") or low:find("crit") then
        local crit = tonumber(eq.crit) or 0
        if crit == 0 and lvl > 0 and lvl < 35 then
            return string.format("Gear: +0 Crit gear at Lv %d (flat dmg/mana talents trigger every cast).", lvl)
        end
        return string.format("Gear: +%d Crit, +%d Int, +%d Spell Power equipped.",
            crit, tonumber(eq.intellect) or 0, tonumber(eq.spellPower) or 0)
    end

    if low:find("mana") or low:find("spirit") or low:find("regeneration") then
        return string.format("Gear: +%d Intellect, +%d Spirit equipped.",
            tonumber(eq.intellect) or 0, tonumber(eq.spirit) or 0)
    end

    return string.format("Gear: +%d Spell Power, +%d Int, +%d Attack Power equipped.",
        tonumber(eq.spellPower) or 0, tonumber(eq.intellect) or 0, tonumber(eq.attackPower) or 0)
end

return TI
