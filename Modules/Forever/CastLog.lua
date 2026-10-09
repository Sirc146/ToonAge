-- ToonAge/Modules/Forever/CastLog.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS IS ──────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Step 1 of "your play vs the best play": a record of what you cast, in
-- order, per fight. The comparison against a sourced rotation is built on
-- top of this once the record is proven safe on this client.
--
-- WHY IT LOOKS LIKE THIS. The Combat tab (CombatRecorder) raised "ToonAge has
-- been blocked from an action only available to the Blizzard UI" on Forever
-- and is banned here. TASecretProbe, a separate addon, recorded 25 casts in
-- one fight on 2026-09-27 with no popup. This file copies the probe's method
-- exactly and nothing else:
--
--   * its OWN frame -- never ToonAge's shared event frame
--   * RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") -- player only
--   * PLAYER_REGEN_DISABLED / ENABLED for fight boundaries
--   * NO combat log, NO action-bar scan, NO power/health/aura/cooldown reads
--     (all secret in combat on Forever -- measured by the probe)
--
-- Measured by the probe: spellID in the cast event is plain, not secret.
-- It is still checked with issecretvalue before any use.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render

local M = {}
TA:RegisterModule("ForeverCastLog", M)

local MAX_FIGHTS       = 20     -- kept per character
local MAX_CASTS        = 600    -- per fight
local MIN_FIGHT_SECS   = 5      -- shorter is a stray mob, not a fight
local GCD_SECONDS      = 1.5    -- Vanilla-era base global cooldown

local isSecret = _G.issecretvalue or function() return false end
local SpellName   -- defined below; used by the coach block

-- ── Store ─────────────────────────────────────────────────────────────────

local function Store()
    if not TA.charDB then return nil end
    TA.charDB.castLog = TA.charDB.castLog or { fights = {} }
    TA.charDB.castLog.fights = TA.charDB.castLog.fights or {}
    return TA.charDB.castLog
end

-- ── Recording (the only code that runs in combat) ─────────────────────────

local current   -- { start = GetTime(), stamp = time(), casts = { {dt, spellID}, ... } }

-- Pulls happen BEFORE combat starts: Charge, Hunter's Mark, a Smite or a
-- Lightning Bolt cast from range all land before PLAYER_REGEN_DISABLED. The
-- last few out-of-combat casts are kept so a fight's opener is really its
-- opener. They are stored with a negative time.
local PREPULL_SECONDS = 3
local PREPULL_MAX     = 4
local prepull = {}

local function OnCast(spellID)
    if spellID == nil or isSecret(spellID) then return end
    if not current then
        prepull[#prepull + 1] = { GetTime(), spellID }
        if #prepull > PREPULL_MAX then table.remove(prepull, 1) end
        return
    end
    local n = #current.casts
    if n >= MAX_CASTS then return end
    current.casts[n + 1] = { GetTime() - current.start, spellID }
end

local function FightStart()
    local now = GetTime()
    current = { start = now, stamp = time(), casts = {} }
    for _, c in ipairs(prepull) do
        if now - c[1] <= PREPULL_SECONDS then
            current.casts[#current.casts + 1] = { c[1] - now, c[2] }
        end
    end
    prepull = {}
end

local castBegan, channelBegan

local function AddActive(from)
    if not current or not from then return end
    local dt = GetTime() - from
    if dt and dt > 0 and dt < 30 then
        current.active = (current.active or 0) + dt
    end
end

local function FightEnd()
    if castBegan then AddActive(castBegan); castBegan = nil end
    if channelBegan then AddActive(channelBegan); channelBegan = nil end
    local f = current
    current = nil
    if not f then return end
    local dur = GetTime() - f.start
    if dur < MIN_FIGHT_SECS or #f.casts == 0 then return end
    local s = Store()
    if not s then return end
    table.insert(s.fights, 1, { stamp = f.stamp, dur = dur, casts = f.casts, active = f.active or 0 })
    while #s.fights > MAX_FIGHTS do table.remove(s.fights) end
    if TA.QueueUIRefresh then TA:QueueUIRefresh("CASTLOG_FIGHT") end
end

-- ── Coach: your casts against the guide (out of combat only) ──────────────

local COACH_FIGHTS = 10    -- judged over your most recent fights
local CORE_SHARE   = 0.5   -- a core ability missing from over half of fights is flagged
local MIN_JUDGED   = 3     -- fewer fights than this: describe, do not judge

local function SplitAlts(entry)
    local t = {}
    for part in tostring(entry):gmatch("[^|]+") do t[#t + 1] = part end
    return t
end

--- Names of the class spells in your spellbook (every line except General).
--- The same C_SpellBook walk DataHarvester runs on Forever.
local function KnownClassSpells()
    local known = {}
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return known end
    local okN, lines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if not okN or type(lines) ~= "number" or isSecret(lines) then return known end
    for line = 1, lines do
        local ok, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if ok and type(info) == "table" and info.numSpellBookItems and info.name ~= "General" then
            for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local ok2, item = pcall(C_SpellBook.GetSpellBookItemInfo, i,
                    Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player)
                if ok2 and type(item) == "table" and item.name and not isSecret(item.name) then
                    known[item.name] = true
                end
            end
        end
    end
    return known
end

--- Your current buffs by name. Readable out of combat (TASecretProbe baseline).
local function CurrentBuffs()
    local have = {}
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return have, false end
    for i = 1, 40 do
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok then return have, false end
        if type(a) ~= "table" then break end
        if a.name and not isSecret(a.name) then have[a.name] = true end
    end
    return have, true
end

local function AnyKnown(known, entry)
    for _, n in ipairs(SplitAlts(entry)) do if known[n] then return n end end
end

--- Compare recent fights with the reference. Pure: no client calls.
--- @return table { judged, lines = { {text, status} }, extra = { name = count } }
function M.Analyse(fights, ref, known, buffs, buffsReadable)
    local out = { judged = 0, lines = {}, extra = {} }
    local function add(text, status) out.lines[#out.lines + 1] = { text, status } end

    local named = {}
    for _, role in ipairs({ "buff", "opener", "core" }) do
        for _, e in ipairs(ref[role] or {}) do
            for _, n in ipairs(SplitAlts(e)) do named[n] = true end
        end
    end

    local use = {}
    for i = 1, math.min(COACH_FIGHTS, #fights) do use[#use + 1] = fights[i] end
    out.judged = #use

    -- Per fight: names cast, first class cast, longest same-spell streaks.
    local perFight = {}
    for _, f in ipairs(use) do
        local seen, first, streaks, prev, run = {}, nil, {}, nil, 0
        for _, c in ipairs(f.casts) do
            local n = c.name
            if n and known[n] then
                seen[n] = (seen[n] or 0) + 1
                first = first or n
                if n == prev then run = run + 1 else run = 1; prev = n end
                if run > (streaks[n] or 0) then streaks[n] = run end
                if not named[n] then out.extra[n] = (out.extra[n] or 0) + 1 end
            end
        end
        perFight[#perFight + 1] = { seen = seen, first = first, streaks = streaks }
    end

    -- Buffs: checked now, out of combat.
    for _, e in ipairs(ref.buff or {}) do
        local have = AnyKnown(known, e)
        if have then
            local up = false
            for _, n in ipairs(SplitAlts(e)) do if buffs[n] then up = true end end
            if not buffsReadable then
                add(have .. ": can't read your buffs right now.", "dim")
            elseif up then
                add(have .. " is up.", "good")
            else
                add(have .. " is not up. The guide keeps it active at all times.", "bad")
            end
        end
    end

    if out.judged < MIN_JUDGED then
        add(string.format("%d fight%s recorded; judging starts at %d.",
            out.judged, out.judged == 1 and "" or "s", MIN_JUDGED), "dim")
        return out
    end

    -- Opener.
    local openers = {}
    for _, e in ipairs(ref.opener or {}) do
        for _, n in ipairs(SplitAlts(e)) do if known[n] then openers[#openers + 1] = n end end
    end
    if #openers > 0 then
        local hit = 0
        for _, pf in ipairs(perFight) do
            for _, n in ipairs(openers) do if pf.first == n then hit = hit + 1; break end end
        end
        local share = hit / #perFight
        add(string.format("Opened with %s in %d of %d fights.",
            table.concat(openers, " or "), hit, #perFight),
            share >= CORE_SHARE and "good" or "warn")
    end

    -- Core abilities.
    for _, e in ipairs(ref.core or {}) do
        local alts = {}
        for _, a in ipairs(SplitAlts(e)) do if known[a] then alts[#alts + 1] = a end end
        if #alts > 0 then
            local n = table.concat(alts, " or ")
            local hit = 0
            for _, pf in ipairs(perFight) do
                for _, a in ipairs(alts) do if pf.seen[a] then hit = hit + 1; break end end
            end
            local share = hit / #perFight
            if share >= CORE_SHARE then
                add(string.format("%s: used in %d of %d fights.", n, hit, #perFight), "good")
            else
                add(string.format("%s: used in only %d of %d fights. The guide has it in the priority.",
                    n, hit, #perFight), "bad")
            end
        end
    end

    -- Abilities the guide calls out when they show up often (not a priority).
    for _, e in ipairs(ref.flag or {}) do
        local n = AnyKnown(known, e)
        if n then
            local hit = 0
            for _, pf in ipairs(perFight) do if pf.seen[n] then hit = hit + 1 end end
            if hit > 0 then
                add(string.format("%s showed up in %d of %d fights. The guide treats that as filler you should not lean on.",
                    n, hit, #perFight), "warn")
            end
        end
    end

    -- Limits (e.g. Arcane Blast at most 4 in a row).
    for _, lim in ipairs(ref.limit or {}) do
        local n, max = lim[1], lim[2]
        if known[n] then
            local over = 0
            for _, pf in ipairs(perFight) do if (pf.streaks[n] or 0) > max then over = over + 1 end end
            if over > 0 then
                add(string.format("%s cast more than %d times in a row in %d fight%s. The guide stops at %d.",
                    n, max, over, over == 1 and "" or "s", max), "warn")
            end
        end
    end
    return out
end

local SPEC_NAMES = {}
local function SpecsFor(classToken)
    local c = TA.Data and TA.Data.ForeverCoach and TA.Data.ForeverCoach[classToken]
    if not c then return nil end
    if not SPEC_NAMES[classToken] then
        local t = {}
        for spec in pairs(c) do t[#t + 1] = spec end
        table.sort(t)
        SPEC_NAMES[classToken] = t
    end
    return c, SPEC_NAMES[classToken]
end

local GUIDE_WRITTEN_FOR = 20   -- level cap the coach references were written for

-- Talent-name hints. A point in a talent whose name contains one of these
-- words counts for that spec. The tree with the most such points wins.
-- A manual button pick overrides this. No points means no guess.
local SPEC_HINTS = {
    MAGE = {
        Fire   = { "fire", "pyro", "ignite", "inciner", "scorch", "combust", "flame" },
        Frost  = { "frost", "ice", "winter", "shatter", "cold" },
        Arcane = { "arcane", "evocat", "presence of mind" },
    },
    DRUID = {
        Balance = { "moon", "wrath", "star", "nature" },
        Feral = { "cat", "bear", "claw", "rip", "feral", "maul" },
        Restoration = { "rejuven", "regrowth", "heal", "swiftmend" },
    },
    HUNTER = {
        ["Beast Mastery"] = { "beast", "pet", "aspect of the" },
        Marksmanship = { "mark", "aimed", "scatter" },
        Survival = { "trap", "survival", "wyvern" },
    },
    PALADIN = {
        Holy = { "holy", "flash", "cleanse" },
        Protection = { "protection", "consecr", "righteous defense" },
        Retribution = { "retrib", "seal of command", "crusader" },
    },
    PRIEST = {
        Discipline = { "discipl", "inner focus", "power infusion" },
        Holy = { "holy", "renew", "smite" },
        Shadow = { "shadow", "mind", "vampir" },
    },
    ROGUE = {
        Assassination = { "mutilate", "poison", "cold blood" },
        Combat = { "blade flurry", "adrenaline", "sword" },
        Subtlety = { "hemorrhage", "premed", "shadowstep", "ghostly" },
    },
    SHAMAN = {
        Elemental = { "elemental", "lightning", "flame shock" },
        Enhancement = { "stormstrike", "dual", "windfury" },
        Restoration = { "healing wave", "chain heal", "earth shield" },
    },
    WARLOCK = {
        Affliction = { "afflict", "curse", "drain", "agony" },
        Demonology = { "demon", "fel", "master demon" },
        Destruction = { "destruct", "conflag", "shadowburn", "immolate" },
    },
    WARRIOR = {
        Arms = { "mortal strike", "sweeping", "overpower" },
        Fury = { "bloodthirst", "whirlwind", "enrage" },
        Protection = { "shield slam", "devastate", "last stand" },
    },
}

local function DetectSpec(token)
    local hints = SPEC_HINTS[token]
    if not hints then return nil end
    local FT = TA.GetModule and TA:GetModule("ForeverTalents")
    local ranked = FT and FT.RankedTalents and FT:RankedTalents()
    if type(ranked) ~= "table" then return nil end
    local score = {}
    for spec in pairs(hints) do score[spec] = 0 end
    for _, t in ipairs(ranked) do
        local name = type(t.name) == "string" and t.name:lower() or ""
        local rank = tonumber(t.rank) or 0
        if rank > 0 and name ~= "" then
            for spec, words in pairs(hints) do
                for _, w in ipairs(words) do
                    if name:find(w, 1, true) then
                        score[spec] = score[spec] + rank
                        break
                    end
                end
            end
        end
    end
    local best, bestN, second = nil, 0, 0
    for spec, n in pairs(score) do
        if n > bestN then
            second, bestN, best = bestN, n, spec
        elseif n > second then
            second = n
        end
    end
    if not best or bestN < 1 or bestN == second then return nil end
    return best
end

local VERDICT_COLOUR = { good = U.GREEN, warn = U.ORANGE, bad = U.RED, dim = U.GREY }

local function RenderCoach(content, y, s)
    local _, token = UnitClass("player")
    local specs, order = SpecsFor(token)
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Compared with the guide")
    if not specs then
        return L:Paragraph(content, y, "No checked reference for your class yet.", { color = L.C_DIM })
    end

    TA.charDB.coachSpec = TA.charDB.coachSpec or {}
    TA.charDB.coachSpecManual = TA.charDB.coachSpecManual or {}
    local detected = DetectSpec(token)
    local chosen = TA.charDB.coachSpecManual[token] and TA.charDB.coachSpec[token] or detected
    local buttons = {}
    for _, spec in ipairs(order) do
        buttons[#buttons + 1] = { label = spec, active = (spec == chosen), onClick = function()
            TA.charDB.coachSpec[token] = spec
            TA.charDB.coachSpecManual[token] = true
            if L.RefreshUI then L:RefreshUI() end
        end }
    end
    y = L:ButtonRow(content, y, buttons, { label = "Your spec:" })
    if not chosen or not specs[chosen] then
        return L:Paragraph(content, y, "Pick your spec to compare your casts with its guide.",
            { color = L.C_DIM })
    end

    local ref = specs[chosen]
    local known = KnownClassSpells()
    local buffs, readable = CurrentBuffs()
    local fights = {}
    for i, f in ipairs(s.fights) do
        local copy = { casts = {} }
        for j, c in ipairs(f.casts) do copy.casts[j] = { name = SpellName(c[2]) } end
        fights[i] = copy
    end

    local a = M.Analyse(fights, ref, known, buffs, readable)
    for _, ln in ipairs(a.lines) do
        y = L:Bullet(content, y, (VERDICT_COLOUR[ln[2]] or "") .. ln[1] .. "|r")
    end
    local extras = {}
    for n, c in pairs(a.extra) do extras[#extras + 1] = string.format("%s (%d fights)", n, c) end
    table.sort(extras)
    if #extras > 0 then
        y = L:Paragraph(content, y, "Not in the guide's priority -- worth checking if it earns its "
            .. "cast: " .. table.concat(extras, ", "), { color = L.C_SECONDARY })
    end
    y = L:Paragraph(content, y, "Reference: Icy Veins " .. chosen .. " guide (written for the "
        .. "beta's level-20 cap). Only abilities in your spellbook are judged.", { color = L.C_DIM })
    -- Version stamp (2026-10-03). The references were written for the beta's
    -- level-20 cap. The beta cap rises to 30 during the test, the beta closes
    -- 2026-10-21 and live launches 2026-11-04 at cap 60, so the comparison
    -- carries its own expiry instead of quietly turning into wrong advice.
    local level = tonumber(UnitLevel("player")) or 0
    local now = time and time() or 0
    local BETA_END = 1792566000            -- 2026-10-21 00:00 PDT
    local stale
    if level > GUIDE_WRITTEN_FOR then
        stale = string.format("You are level %d; this reference was written for level %d. "
            .. "Treat its priority as a starting point, not a check.", level, GUIDE_WRITTEN_FOR)
    elseif now > BETA_END then
        stale = "This reference was written for the beta. Live Forever may differ until it is "
            .. "re-checked against a launch guide."
    end
    if stale then
        y = L:Paragraph(content, y, stale, { color = L.C_WARNING })
    end
    return y
end

-- ── Render (out of combat reads of plain, stored data) ────────────────────

function SpellName(id)
    local n
    if C_Spell and C_Spell.GetSpellName then
        local ok, v = pcall(C_Spell.GetSpellName, id); if ok then n = v end
    end
    if n == nil or isSecret(n) then return "spell " .. tostring(id) end
    return n
end

local function Summarise(f)
    -- Ranks are separate spell IDs. Merge by name so Arcane Missiles is one row.
    local counts, order = {}, {}
    for _, c in ipairs(f.casts) do
        local name = SpellName(c[2])
        if not counts[name] then counts[name] = 0; order[#order + 1] = name end
        counts[name] = counts[name] + 1
    end
    table.sort(order, function(a, b) return counts[a] > counts[b] end)
    return counts, order
end

function M:Render(content, side)
    L = L or TA.Layout
    if not L then return end
    local FC = TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then pcall(FC.RenderSidebarPublic, FC, side) end

    local s = Store()
    local y = -8
    local f = s and s.fights[1]
    if not f then
        y = L:SectionHeader(content, y, "Casts")
        y = L:Paragraph(content, y,
            "Nothing recorded yet. Fight something for more than "
            .. MIN_FIGHT_SECS .. " seconds; each fight's casts appear here in order.")
        L:Finish(content, y)
        return
    end

    local mins = f.dur / 60
    local total = #f.casts
    local maxCasts = math.floor(f.dur / GCD_SECONDS)
    local _, classToken = UnitClass("player")
    local CASTERS = { MAGE = true, WARLOCK = true, PRIEST = true, SHAMAN = true, DRUID = true, EVOKER = true }
    local active = tonumber(f.active) or 0
    local activePct = (f.dur and f.dur > 0) and math.min(100, (active / f.dur) * 100) or 0
    y = L:SectionHeader(content, y, "Last fight",
        date("%H:%M", f.stamp) .. string.format("  ·  %d fights kept", #s.fights))
    y = L:DataRow(content, y, { label = "Length", value = string.format("%.0f sec", f.dur) })
    y = L:DataRow(content, y, { label = "Casts", value = tostring(total),
        note = string.format("%.1f per minute", mins > 0 and total / mins or 0) })
    if CASTERS[classToken] then
        local past = activePct >= 90
        y = L:CapBar(content, y, {
            label = "Active time",
            value = string.format("%d%%", math.floor(activePct + 0.5)),
            current = active,
            cap = f.dur,
            capped = past,
            fillRGB = past and { 0.275, 0.784, 0.416 } or { 0.45, 0.52, 0.58 },
            tickAt = 0.90,
            note = "Cast and channel time over the fight. Target is 90%.",
        })
        y = L:DataRow(content, y, { label = "Global cooldowns used",
            value = maxCasts > 0 and string.format("%d%%", math.min(100, math.floor(100 * total / maxCasts))) or "n/a",
            note = string.format("%d casts out of at most %d at a %.1f s global cooldown.",
                total, maxCasts, GCD_SECONDS) })
    else
        y = L:DataRow(content, y, { label = "Global cooldowns used",
            value = maxCasts > 0 and string.format("%d%%", math.min(100, math.floor(100 * total / maxCasts))) or "n/a",
            note = string.format("%d casts out of at most %d at a %.1f s global cooldown.",
                total, maxCasts, GCD_SECONDS) })
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "What you cast")
    local counts, order = Summarise(f)
    for _, name in ipairs(order) do
        y = L:DataRow(content, y, { label = name, value = tostring(counts[name]),
            note = string.format("%.0f%% of casts", 100 * counts[name] / total) })
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Opener", "Your first casts, in order.")
    local open = {}
    for i = 1, math.min(6, total) do
        open[#open + 1] = string.format("%s (%.1fs)", SpellName(f.casts[i][2]), f.casts[i][1])
    end
    local chev = "|TInterface\\AddOns\\ToonAge\\Media\\icons\\util_chevron_16.tga:10:10:0:0|t"
    y = L:Paragraph(content, y, table.concat(open, "  " .. chev .. "  "), { color = L.C_PRIMARY })

    if InCombatLockdown and InCombatLockdown() then
        y = L:Divider(content, y)
        y = L:Paragraph(content, y, "The comparison with the guide appears after combat.",
            { color = L.C_DIM })
    else
        y = RenderCoach(content, y, s)
    end
    L:Finish(content, y)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────

function M:Init()
    if not TA.IsForever then self._disabled = true; return end
    local fr = CreateFrame("Frame")
    local function RegUnit(ev)
        if fr.RegisterUnitEvent then pcall(fr.RegisterUnitEvent, fr, ev, "player") end
    end
    RegUnit("UNIT_SPELLCAST_SUCCEEDED")
    RegUnit("UNIT_SPELLCAST_START")
    RegUnit("UNIT_SPELLCAST_STOP")
    RegUnit("UNIT_SPELLCAST_INTERRUPTED")
    RegUnit("UNIT_SPELLCAST_FAILED")
    RegUnit("UNIT_SPELLCAST_CHANNEL_START")
    RegUnit("UNIT_SPELLCAST_CHANNEL_STOP")
    pcall(fr.RegisterEvent, fr, "PLAYER_REGEN_DISABLED")
    pcall(fr.RegisterEvent, fr, "PLAYER_REGEN_ENABLED")
    fr:SetScript("OnEvent", function(_, event, unit, _, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            OnCast(spellID)
        elseif event == "UNIT_SPELLCAST_START" then
            castBegan = GetTime()
        elseif event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "UNIT_SPELLCAST_FAILED" then
            AddActive(castBegan)
            castBegan = nil
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            channelBegan = GetTime()
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            AddActive(channelBegan)
            channelBegan = nil
        elseif event == "PLAYER_REGEN_DISABLED" then
            FightStart()
        elseif event == "PLAYER_REGEN_ENABLED" then
            FightEnd()
        end
    end)
    self._frame = fr
end

return M
