-- ToonAge/Data/RotationConditions.lua
-- Reusable predicates for rotation entries' `when` field.
--
-- Why this exists
-- ───────────────
-- Rotation entries used to carry `condition = "On cooldown"` — a *display string*
-- for the tooltip, never evaluated by anything. The next-3 prediction bar was
-- therefore a static priority list: it re-sorted only on real cooldowns, so it
-- showed the same two or three spells alternating regardless of resources, auras,
-- target count, or health. This file makes conditions executable.
--
-- Contract
-- ────────
--   { spellID=..., name="...", when = C.And(C.PowerAtLeast(35), C.NoDebuff(589)) }
--
-- A `when` predicate receives (CombatState.state, entry) and returns true if the
-- ability is worth suggesting right now. Most predicates ignore the second
-- argument; proc-aware ones such as ExecuteOrProc use it to read the spellID.
-- Returning false removes it from consideration
-- for that slot; it does NOT disable the ability. Predicates must be cheap and
-- side-effect free — GetNextN runs them up to 3x per entry at 0.15s intervals.
--
-- IMPORTANT: `when` is advisory, not a hard gate. An entry with no `when` is
-- always eligible, so partial coverage is safe — a spec with no conditions
-- authored behaves exactly as it did before.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
TA.Data = TA.Data or {}

local C = {}
TA.Data.RotationConditions = C

-- ── Introspection registry ────────────────────────────────────────────────────
-- Predicates are closures, so the spellIDs inside them can't be read back. Each
-- constructor records what it was built from, keyed weakly by the closure, so
-- /ta spellaudit can list and verify every aura ID a rotation depends on. A wrong
-- aura ID never errors -- the rule just never fires.
C._meta = setmetatable({}, { __mode = "k" })
local function Tag(fn, info)
    C._meta[fn] = info
    return fn
end

--- Every aura reference inside a predicate tree: array of { kind, id }.
function C.AuraRefs(fn, out)
    out = out or {}
    local info = type(fn) == "function" and C._meta[fn]
    if not info then return out end
    if info.id then out[#out + 1] = { kind = info.kind, id = info.id } end
    if info.children then
        for _, child in ipairs(info.children) do C.AuraRefs(child, out) end
    end
    return out
end

-- ── Combinators ───────────────────────────────────────────────────────────────

function C.And(...)
    local fns = { ... }
    return Tag(function(s)
        for i = 1, #fns do
            if not fns[i](s) then
                return false
            end
        end
        return true
    end, { kind = "And", children = fns })
end

function C.Or(...)
    local fns = { ... }
    return Tag(function(s)
        for i = 1, #fns do
            if fns[i](s) then
                return true
            end
        end
        return false
    end, { kind = "Or", children = fns })
end

function C.Not(fn)
    return Tag(function(s)
        return not fn(s)
    end, { kind = "Not", children = { fn } })
end

-- ── Aura helpers ──────────────────────────────────────────────────────────────
-- state.buffs / state.debuffs are [spellID] = { stacks = N, expires = T }

--- Remaining seconds on an aura, or 0 if absent. Auras with no expiry
--- (permanent/stance-like) report a large number so "about to fall off"
--- checks never fire on them.
local function Remaining(tbl, spellID)
    local a = tbl and tbl[spellID]
    if not a then
        return 0
    end
    if not a.expires or a.expires == 0 then
        return 999
    end
    local left = a.expires - GetTime()
    return left > 0 and left or 0
end

C.Remaining = Remaining

function C.HasBuff(spellID)
    return Tag(function(s)
        return Remaining(s.buffs, spellID) > 0
    end, { kind = "HasBuff", id = spellID })
end

function C.NoBuff(spellID)
    return Tag(function(s)
        return Remaining(s.buffs, spellID) <= 0
    end, { kind = "NoBuff", id = spellID })
end

function C.HasDebuff(spellID)
    return Tag(function(s)
        return Remaining(s.debuffs, spellID) > 0
    end, { kind = "HasDebuff", id = spellID })
end

function C.NoDebuff(spellID)
    return Tag(function(s)
        return Remaining(s.debuffs, spellID) <= 0
    end, { kind = "NoDebuff", id = spellID })
end

--- Buff stacks at or above N (e.g. combo-point-like or ramping procs).
--- Is a buff up, matched by the NAME of `spellID` rather than its id?
--- For talents whose granted buff has an id of its own that is not published
--- anywhere reliable (Darkest Night is the standing example: 457058 is the
--- passive, and the buff it grants carries a different id), matching on the
--- talent's own localized name is correct where a guessed id is not.
function C.HasBuffNamed(spellID)
    return Tag(function(s)
        local CS = ToonAge.CombatState
        local nm = CS and CS._SpellName and CS._SpellName(spellID)
        if not nm then return false end
        return (s.buffNames and s.buffNames[nm]) ~= nil
    end, { kind = "HasBuffNamed", id = spellID })
end

function C.BuffStacks(spellID, n)
    return Tag(function(s)
        local a = s.buffs and s.buffs[spellID]
        return (a and (a.stacks or 1) or 0) >= n
    end, { kind = "BuffStacks", id = spellID })
end

--- The standard DoT-refresh window: absent, or inside the last `seconds`.
--- This is the single most useful predicate in the file — recasting a DoT that
--- has most of its duration left is the most common rotation mistake, and it is
--- mechanically wrong for every spec, so it needs no per-spec theorycraft.
function C.DebuffRefresh(spellID, seconds)
    seconds = seconds or 4
    return Tag(function(s)
        return Remaining(s.debuffs, spellID) <= seconds
    end, { kind = "DebuffRefresh", id = spellID })
end

function C.BuffRefresh(spellID, seconds)
    seconds = seconds or 4
    return Tag(function(s)
        return Remaining(s.buffs, spellID) <= seconds
    end, { kind = "BuffRefresh", id = spellID })
end

-- ── Resources ─────────────────────────────────────────────────────────────────

function C.PowerAtLeast(n)
    return function(s)
        return (s.power or 0) >= n
    end
end

function C.PowerBelow(n)
    return function(s)
        return (s.power or 0) < n
    end
end

function C.PowerPctAtLeast(pct)
    return function(s)
        return (s.powerPct or 0) >= pct
    end
end

function C.PowerPctBelow(pct)
    return function(s)
        return (s.powerPct or 0) < pct
    end
end

function C.ComboAtLeast(n)
    return function(s)
        return (s.comboPoints or 0) >= n
    end
end

function C.ComboBelow(n)
    return function(s)
        return (s.comboPoints or 0) < n
    end
end

-- ── Health ────────────────────────────────────────────────────────────────────

function C.HealthBelow(pct)
    return function(s)
        return (s.healthPct or 100) < pct
    end
end

function C.HealthAtLeast(pct)
    return function(s)
        return (s.healthPct or 100) >= pct
    end
end

--- Emergency defensive window.
function C.Hurt()
    return C.HealthBelow(60)
end
function C.Critical()
    return C.HealthBelow(35)
end

-- ── Target ────────────────────────────────────────────────────────────────────

function C.TargetBelow(pct)
    return function(s)
        return (s.targetPct or 100) < pct
    end
end

--- Execute range. Most execute abilities sit at 20% or 35%.
function C.Execute(pct)
    return C.TargetBelow(pct or 20)
end

--- Execute range **or** the spell is castable right now.
---
--- Use this rather than bare Execute() for any execute ability with a proc that
--- enables it early — Kill Shot under Pack Leader, Hammer of Wrath during
--- Avenging Wrath, and so on. Blizzard's own usability check already knows about
--- those procs, so deferring to it is both simpler and more correct than trying
--- to enumerate proc spellIDs per spec.
---
--- Relies on the predicate receiving the entry as its second argument.
function C.ExecuteOrProc(pct)
    pct = pct or 20
    return function(s, entry)
        if (s.targetPct or 100) < pct then
            return true
        end
        local id = entry and entry.spellID
        if id and C_Spell and C_Spell.IsSpellUsable then
            local ok, usable = pcall(C_Spell.IsSpellUsable, id)
            if ok and usable then
                return true
            end
        end
        return false
    end
end

-- ── Group health (healers) ────────────────────────────────────────────────────
-- Read from CombatState.state.group. When group health isn't readable
-- (group.known == false) these return true: a condition may fail to promote a
-- heal, but must never hide one because data was missing.

--- The lowest-health group member (you included) is below `pct`.
function C.AllyBelow(pct)
    pct = pct or 85
    return Tag(function(s)
        local g = s.group
        if not (g and g.known) then return true end
        return (g.lowestPct or 100) < pct
    end, { kind = "AllyBelow" })
end

--- At least `n` group members are below `pct` (n is capped at group size,
--- so a 3-target AoE heal still works in a 2-person group).
function C.GroupHurt(n, pct)
    n, pct = n or 3, pct or 90
    return Tag(function(s)
        local g = s.group
        if not (g and g.known) then return true end
        local need = math.min(n, g.members or n)
        local count = (pct <= 50 and g.hurt50) or (pct <= 75 and g.hurt75) or g.hurt90 or 0
        return count >= math.max(1, need)
    end, { kind = "GroupHurt" })
end

--- The spell is usable right now, per the client. For abilities that replace
--- another only while something is active that isn't a player buff -- Void Blast
--- during Entropic Rift (a ground effect), Blightfall during Dark Transformation
--- (a pet buff) -- the client's usability check is the only reliable signal.
function C.Usable()
    return Tag(function(s, entry)
        local id = entry and entry.spellID
        if id and C_Spell and C_Spell.IsSpellUsable then
            local ok, usable = pcall(C_Spell.IsSpellUsable, id)
            return ok and usable and true or false
        end
        return true
    end, { kind = "Usable" })
end

--- Target will live long enough for a ramping ability to pay off.
function C.TargetLives(seconds)
    seconds = seconds or 6
    return function(s)
        return (s.targetTTD or 999) >= seconds
    end
end

function C.TargetDying(seconds)
    seconds = seconds or 4
    return function(s)
        return (s.targetTTD or 999) < seconds
    end
end

-- ── Target count ──────────────────────────────────────────────────────────────

function C.AoE(n)
    n = n or 3
    return function(s)
        return (s.aoeCount or 1) >= n
    end
end

function C.SingleTarget(maxN)
    maxN = maxN or 2
    return function(s)
        return (s.aoeCount or 1) <= maxN
    end
end

--- At least `n` enemies engaged near the player.
---
--- Reads the SAME engaged-enemy count the AoE/SingleTarget predicates use:
--- CombatState.state.aoeCount, which UpdateAoeCount() in CombatState.lua fills
--- from hostile nameplates filtered to those actually in combat with you or
--- your group (unpulled packs are deliberately excluded). There is no separate
--- radius scan in the trunk, so "in range" here means "engaged and on a
--- nameplate" -- the only enemy count the engine measures.
---
--- NOTE for review: against the current state this is functionally identical to
--- C.AoE(n). It is added as the blueprint's named reaction predicate; a true
--- distance-based count would need a new per-frame scan in CombatState, which
--- the combat-UI performance rules (blueprint section 9) rule out. If a
--- distinct range metric is ever wanted, add the field in CombatState and point
--- this predicate at it -- the authored rules do not change.
function C.EnemiesInRange(n)
    n = n or 1
    return function(s)
        return (s.aoeCount or 1) >= n
    end
end

-- ── Misc ──────────────────────────────────────────────────────────────────────

function C.InCombat()
    return function(s)
        return s.inCombat == true
    end
end

--- True while the player is moving -- for suggesting instants over hard casts.
---
--- Movement is read from GetUnitSpeed("player"): return value > 0 means moving.
--- Two things in the trunk shape how this is read, and both are deliberate:
---
---   1. Secret values. Modules/Navigation/TravelModes.lua documents that
---      GetUnitSpeed returns a SECRET number in a tainted/combat context, and
---      comparing a secret number throws. A rotation predicate runs in exactly
---      that context, so the speed is checked with issecretvalue first and the
---      predicate degrades to false (not moving / unknown) rather than risking a
---      throw -- consistent with the blueprint's "secrets read stale/unknown,
---      never zero" and "false skips the slot, never disables."
---
---   2. Caps. The task asks to read a possibly-absent hook through TA.Caps.
---      REVIEW FLAG: Core/Caps.lua is NOT in the retail (Mainline) TOC -- it
---      ships only on the Camelot/TBC TOCs -- while THIS file ships only on
---      Mainline/fallback. So on the one client that loads RotationConditions,
---      TA.Caps is currently absent. This predicate therefore uses TA.Caps.Call
---      WHEN it exists (future-proof for when G3 wires Caps everywhere) and
---      falls back to a guarded direct GetUnitSpeed otherwise. Either path
---      degrades to false, never crashes. Flagging the choice per instructions
---      rather than assuming Caps is present.
local function IsSecretValue(v)
    local f = _G and _G.issecretvalue
    if type(f) ~= "function" then return false end
    local ok, r = pcall(f, v)
    return ok and r == true
end

function C.PlayerMoving()
    return function()
        local Caps = ToonAge and ToonAge.Caps
        if Caps and Caps.Call then
            -- Caps.Call never throws; it packs a secret return as the literal
            -- "secret". A number > 0 means moving; anything else is not-moving
            -- or unknown.
            local ok, speed = Caps.Call("GetUnitSpeed", "player")
            if ok and type(speed) == "number" then
                return speed > 0
            end
            return false
        end
        -- Fallback: no Caps on this client. Call the global directly, guarded
        -- against both absence and secret-value comparison.
        local fn = _G and _G.GetUnitSpeed
        if type(fn) ~= "function" then return false end
        local ok, speed = pcall(fn, "player")
        if not ok or speed == nil or IsSecretValue(speed) then return false end
        return type(speed) == "number" and speed > 0
    end
end

--- Always true. Useful as an explicit "no condition, and that's deliberate"
--- marker so a reviewer can tell it apart from an entry nobody has looked at.
function C.Always()
    return function()
        return true
    end
end
