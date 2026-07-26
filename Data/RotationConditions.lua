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

-- ── Combinators ───────────────────────────────────────────────────────────────

function C.And(...)
    local fns = { ... }
    return function(s)
        for i = 1, #fns do
            if not fns[i](s) then return false end
        end
        return true
    end
end

function C.Or(...)
    local fns = { ... }
    return function(s)
        for i = 1, #fns do
            if fns[i](s) then return true end
        end
        return false
    end
end

function C.Not(fn)
    return function(s) return not fn(s) end
end

-- ── Aura helpers ──────────────────────────────────────────────────────────────
-- state.buffs / state.debuffs are [spellID] = { stacks = N, expires = T }

--- Remaining seconds on an aura, or 0 if absent. Auras with no expiry
--- (permanent/stance-like) report a large number so "about to fall off"
--- checks never fire on them.
local function Remaining(tbl, spellID)
    local a = tbl and tbl[spellID]
    if not a then return 0 end
    if not a.expires or a.expires == 0 then return 999 end
    local left = a.expires - GetTime()
    return left > 0 and left or 0
end

C.Remaining = Remaining

function C.HasBuff(spellID)
    return function(s) return Remaining(s.buffs, spellID) > 0 end
end

function C.NoBuff(spellID)
    return function(s) return Remaining(s.buffs, spellID) <= 0 end
end

function C.HasDebuff(spellID)
    return function(s) return Remaining(s.debuffs, spellID) > 0 end
end

function C.NoDebuff(spellID)
    return function(s) return Remaining(s.debuffs, spellID) <= 0 end
end

--- Buff stacks at or above N (e.g. combo-point-like or ramping procs).
function C.BuffStacks(spellID, n)
    return function(s)
        local a = s.buffs and s.buffs[spellID]
        return (a and (a.stacks or 1) or 0) >= n
    end
end

--- The standard DoT-refresh window: absent, or inside the last `seconds`.
--- This is the single most useful predicate in the file — recasting a DoT that
--- has most of its duration left is the most common rotation mistake, and it is
--- mechanically wrong for every spec, so it needs no per-spec theorycraft.
function C.DebuffRefresh(spellID, seconds)
    seconds = seconds or 4
    return function(s) return Remaining(s.debuffs, spellID) <= seconds end
end

function C.BuffRefresh(spellID, seconds)
    seconds = seconds or 4
    return function(s) return Remaining(s.buffs, spellID) <= seconds end
end

-- ── Resources ─────────────────────────────────────────────────────────────────

function C.PowerAtLeast(n)
    return function(s) return (s.power or 0) >= n end
end

function C.PowerBelow(n)
    return function(s) return (s.power or 0) < n end
end

function C.PowerPctAtLeast(pct)
    return function(s) return (s.powerPct or 0) >= pct end
end

function C.PowerPctBelow(pct)
    return function(s) return (s.powerPct or 0) < pct end
end

function C.ComboAtLeast(n)
    return function(s) return (s.comboPoints or 0) >= n end
end

function C.ComboBelow(n)
    return function(s) return (s.comboPoints or 0) < n end
end

-- ── Health ────────────────────────────────────────────────────────────────────

function C.HealthBelow(pct)
    return function(s) return (s.healthPct or 100) < pct end
end

function C.HealthAtLeast(pct)
    return function(s) return (s.healthPct or 100) >= pct end
end

--- Emergency defensive window.
function C.Hurt()      return C.HealthBelow(60) end
function C.Critical()  return C.HealthBelow(35) end

-- ── Target ────────────────────────────────────────────────────────────────────

function C.TargetBelow(pct)
    return function(s) return (s.targetPct or 100) < pct end
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
        if (s.targetPct or 100) < pct then return true end
        local id = entry and entry.spellID
        if id and C_Spell and C_Spell.IsSpellUsable then
            local ok, usable = pcall(C_Spell.IsSpellUsable, id)
            if ok and usable then return true end
        end
        return false
    end
end

--- Target will live long enough for a ramping ability to pay off.
function C.TargetLives(seconds)
    seconds = seconds or 6
    return function(s) return (s.targetTTD or 999) >= seconds end
end

function C.TargetDying(seconds)
    seconds = seconds or 4
    return function(s) return (s.targetTTD or 999) < seconds end
end

-- ── Target count ──────────────────────────────────────────────────────────────

function C.AoE(n)
    n = n or 3
    return function(s) return (s.aoeCount or 1) >= n end
end

function C.SingleTarget(maxN)
    maxN = maxN or 2
    return function(s) return (s.aoeCount or 1) <= maxN end
end

-- ── Misc ──────────────────────────────────────────────────────────────────────

function C.InCombat()
    return function(s) return s.inCombat == true end
end

--- Always true. Useful as an explicit "no condition, and that's deliberate"
--- marker so a reviewer can tell it apart from an entry nobody has looked at.
function C.Always()
    return function() return true end
end
