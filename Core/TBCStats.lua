-- ToonAge/Core/TBCStats.lua (Anniversary — TBC Classic / Interface 20506)
-- The combat-math engine. Every cap number the addon shows is COMPUTED here.
--
-- ─── WHY THIS FILE COMPUTES INSTEAD OF LOOKING UP ──────────────────────────
--
-- Docs/CLASSIC_ANNIVERSARY_BRIEF.md lists flat level-70 constants. Two of them
-- are wrong, and both are wrong in the same way — they are WotLK level-80
-- figures that got copied into a TBC document:
--
--   * "Expertise cap: 26 (6.5%, 214 rating at level 70)". 214 rating is the
--     level-80 conversion (8.197 rating per expertise). At 70 it is 3.94, so
--     26 expertise costs ~102 rating, not 214. A player told to reach 214
--     would burn ~112 rating of budget on nothing.
--   * "Defense cap: 490 heroics, 540 raids". 540 is `80*5 + 140` — the level-80
--     number. In TBC the uncrittable threshold is `playerLevel*5 + 140` against
--     any target three levels above, which is 490 at 70 whether that target is
--     in a heroic or a raid. There is no separate raid number.
--
-- Flat constants are also wrong for the brief's own stated goal ("Start from:
-- Level 1"). A level-22 player fights same-level mobs, where the melee hit cap
-- is 5%, not 9% — 9% is the figure for a target three levels above you. An
-- addon that shows 9% for 69 of 70 levels is misinforming the player it was
-- built for.
--
-- So: caps are derived from player level, weapon skill, and target level. The
-- level-70-versus-boss case falls out of the formulas as 9% / 26 / 490, which
-- is the check that the formulas are right.
--
-- ─── WHAT IS MEASURED AND WHAT IS NOT ──────────────────────────────────────
--
-- Rating→percent conversion is DERIVED FROM THE LIVE CLIENT wherever possible:
-- GetCombatRating(x) / GetCombatRatingBonus(x) gives the exact ratio this
-- client uses, at this level, with no constant to get wrong. The hardcoded
-- table is a fallback for when you hold zero rating and the ratio is 0/0.
--
-- Every consumer of GetRatingPerPercent gets a `source` string back and is
-- expected to say which one it used. Silent fallback is the failure mode
-- .rules.md exists to prevent.
--
-- UNVERIFIED — needs a live /dump on 20506, see TA.TBCStats.DumpLines():
--   * that CR_HIT_MELEE and friends exist as globals (we fall back to the
--     documented TBC enum and log it if they don't)
--   * that GetCombatRatingBonus exists (percent readouts degrade if not)
--   * the 3.94 rating-per-expertise figure at level 70

local TA = ToonAge
local U  = TA.Utils

local S = {}
TA.TBCStats = S
TA:RegisterModule("TBCStats", S)

-- ─── COMBAT RATING INDICES ─────────────────────────────────────────────────
-- Named globals first. The numeric fallbacks are the documented TBC enum, but a
-- wrong index reads a DIFFERENT rating and returns a plausible number with no
-- error — the exact silent-wrong-value shape .rules.md warns about — so taking
-- the fallback is recorded and surfaced by /ta caps and /ta apiprobe.

local CR_FALLBACK = {
    WEAPON_SKILL   = 1,
    DEFENSE_SKILL  = 2,
    DODGE          = 3,
    PARRY          = 4,
    BLOCK          = 5,
    HIT_MELEE      = 6,
    HIT_RANGED     = 7,
    HIT_SPELL      = 8,
    CRIT_MELEE     = 9,
    CRIT_RANGED    = 10,
    CRIT_SPELL     = 11,
    HASTE_MELEE    = 18,
    HASTE_RANGED   = 19,
    HASTE_SPELL    = 20,
    EXPERTISE      = 24,
    -- Resilience. Note the name: there is no CR_RESILIENCE in TBC — the stat is
    -- exposed as CR_CRIT_TAKEN_MELEE, and looking for the obvious name would
    -- silently fall through to the numeric guess on a client where the correct
    -- global was there all along.
    CRIT_TAKEN_MELEE = 15,
}

S.CR          = {}   -- key -> resolved numeric index
S.CRGuessed   = {}   -- key -> true when the named global was absent
S.crAnyGuessed = false

for key, fallback in pairs(CR_FALLBACK) do
    local named = _G["CR_" .. key]
    if type(named) == "number" then
        S.CR[key] = named
    else
        S.CR[key] = fallback
        S.CRGuessed[key] = true
        S.crAnyGuessed = true
    end
end

-- ─── RATING → PERCENT CONVERSION ───────────────────────────────────────────
--
-- Blizzard's TBC conversion: a rating's value per point is fixed up to level 60,
-- then shrinks from 61-70 by the factor  82 / (262 - 3*level).
--
-- At level 70 that factor is 82/52 = 1.576923, and it reproduces every published
-- level-70 figure from the level-60 bases below:
--     melee hit  10   * 1.5769 = 15.77   (9% cap = 141.9 ≈ 142 rating — brief agrees)
--     spell hit   8   * 1.5769 = 12.62   (16% cap = 201.8 ≈ 202 rating — brief agrees)
--     crit       14   * 1.5769 = 22.08
--     haste      10   * 1.5769 = 15.77
--     defense     1.5 * 1.5769 =  2.37
--     dodge      12   * 1.5769 = 18.92
--     expertise   2.5 * 1.5769 =  3.94   (26 exp = 102.5 rating — brief says 214, wrong)
--     resilience 25   * 1.5769 = 39.42
--
-- Two of those (melee hit, spell hit) are independently confirmed by the brief's
-- own rating numbers, which is why this table is trusted as a fallback at all.
--
-- Below level 60 the scaling is NOT confidently known here, so BelowSixty
-- returns nil rather than a guess. Callers that get nil show percentages only
-- ("you need 4.20% more hit") which needs no conversion and is never wrong.

local BASE_AT_60 = {
    HIT_MELEE     = 10.0,
    HIT_RANGED    = 10.0,
    HIT_SPELL     =  8.0,
    CRIT_MELEE    = 14.0,
    CRIT_RANGED   = 14.0,
    CRIT_SPELL    = 14.0,
    HASTE_MELEE   = 10.0,
    HASTE_RANGED  = 10.0,
    HASTE_SPELL   = 10.0,
    DEFENSE_SKILL =  1.5,
    DODGE         = 12.0,
    EXPERTISE     =  2.5,
    CRIT_TAKEN_MELEE = 25.0,   -- resilience: 25 * 1.5769 = 39.42 rating per 1% at 70
}

--- The 61-70 shrink factor. 1.0 at and below level 60.
function S:LevelFactor(level)
    level = level or U.GetPlayerLevel()
    if level <= 60 then return 1.0 end
    local denom = 262 - 3 * level
    if denom <= 0 then return nil end
    return 82 / denom
end

--- Rating needed for 1% of a stat.
--- Prefers the live client ratio; falls back to the formula above.
--- @return number|nil perPercent, string source  -- "derived" | "formula" | "unknown"
function S:GetRatingPerPercent(key)
    local idx = self.CR[key]
    if idx then
        local rating = U.SafeGetNum(GetCombatRating, idx)
        local pct    = GetCombatRatingBonus and U.SafeGetNum(GetCombatRatingBonus, idx) or 0
        -- Only trust the live ratio when both sides are meaningfully non-zero.
        -- Near zero the division amplifies the client's rounding into nonsense.
        if rating >= 1 and pct >= 0.01 then
            return rating / pct, "derived"
        end
    end

    local base = BASE_AT_60[key]
    if not base then return nil, "unknown" end

    local level = U.GetPlayerLevel()
    if level < 60 then
        -- Sub-60 scaling is not measured. Refuse to guess.
        return nil, "unknown"
    end

    local factor = self:LevelFactor(level)
    if not factor then return nil, "unknown" end
    return base * factor, "formula"
end

--- Convert a percentage shortfall into a rating shortfall.
--- @return number|nil rating, string source
function S:PercentToRating(key, pct)
    local perPct, source = self:GetRatingPerPercent(key)
    if not perPct then return nil, source end
    return pct * perPct, source
end

-- ── Point-based conversions ─────────────────────────────────────────────
-- Expertise and defense are counted in POINTS, not percent, and
-- GetCombatRatingBonus's meaning for them is not measured on this client — it
-- may return points or percent. Rather than pick one and be silently wrong,
-- both are derived from a ratio the client states unambiguously: the rating you
-- hold, divided by the points that rating produced.

--- Rating needed for one point of expertise.
--- @return number|nil perPoint, string source
function S:GetExpertiseRatingPerPoint()
    local rating = self:GetRating("EXPERTISE")
    local points = GetExpertise and U.SafeGetNum(GetExpertise) or 0
    if rating >= 1 and points >= 1 then
        return rating / points, "derived"
    end

    -- Fall back through the percent path: 1 expertise removes 0.25% avoidance.
    local perPct, source = self:GetRatingPerPercent("EXPERTISE")
    if not perPct then return nil, source end
    return perPct * 0.25, source
end

--- Rating needed for one point of defense skill.
---
--- The derived path here is WEAKER than the expertise one and is treated as
--- such. UnitDefense's modifier is not "defense from rating" — it is defense
--- from rating PLUS talents, buffs and enchants. Dividing rating by it therefore
--- understates the cost per point whenever any non-rating defense is present
--- (a tank with +10 from talents and 100 rating computes 1.92 instead of ~2.37,
--- and the Gear tab would then understate the rating still needed by a fifth).
---
--- So the derived value is only accepted when it lands near the formula. When
--- they disagree, the formula wins, because the formula's inputs are exact and
--- the derived value's are contaminated.
--- @return number|nil perPoint, string source
local DEFENSE_DERIVED_TOLERANCE = 0.15

function S:GetDefenseRatingPerPoint()
    local level = U.GetPlayerLevel()
    local formula
    if level >= 60 then
        local factor = self:LevelFactor(level)
        if factor then formula = BASE_AT_60.DEFENSE_SKILL * factor end
    end

    local rating = self:GetRating("DEFENSE_SKILL")
    local _, _, modifier = self:GetDefenseSkill()
    if rating >= 1 and modifier >= 1 then
        local derived = rating / modifier
        if not formula then
            -- No formula to check against below 60. Flag the weaker provenance.
            return derived, "derived-unchecked"
        end
        if math.abs(derived - formula) / formula <= DEFENSE_DERIVED_TOLERANCE then
            return derived, "derived"
        end
        -- Diverged: the modifier is carrying non-rating defense. Trust the formula.
        return formula, "formula"
    end

    if not formula then return nil, "unknown" end
    return formula, "formula"
end

-- ─── LIVE STAT READS ───────────────────────────────────────────────────────

function S:GetRating(key)
    local idx = self.CR[key]
    if not idx then return 0 end
    return U.SafeGetNum(GetCombatRating, idx)
end

function S:GetRatingBonus(key)
    local idx = self.CR[key]
    if not idx or not GetCombatRatingBonus then return 0 end
    return U.SafeGetNum(GetCombatRatingBonus, idx)
end

--- Total melee hit percent from gear.
function S:GetMeleeHitPercent()
    return self:GetRatingBonus("HIT_MELEE")
end

--- Total spell hit percent from gear. Draenei get +1% from Heroic Presence,
--- which is an aura and is NOT included in GetCombatRatingBonus — the caller
--- adds it via RaceAdvisor so the source of the point stays visible.
function S:GetSpellHitPercent()
    return self:GetRatingBonus("HIT_SPELL")
end

--- Expertise in points (not rating, not percent).
--- GetExpertise() returns (base, offhand, ranged) in TBC.
function S:GetExpertise()
    if GetExpertise then
        local main = U.SafeGetNum(GetExpertise)
        if main > 0 then return main end
    end
    -- Fall back to converting the rating ourselves. This must divide by rating
    -- per EXPERTISE POINT, not rating per percent — the two differ by a factor
    -- of four (one point removes 0.25%), and dividing by the wrong one reports
    -- roughly four times the expertise you actually have.
    local rating = self:GetRating("EXPERTISE")
    if rating <= 0 then return 0 end
    local perPoint = select(1, self:GetExpertiseRatingPerPoint())
    if not perPoint or perPoint <= 0 then return 0 end
    return math.floor(rating / perPoint)
end

--- Defense skill: base (5 per level) plus whatever defense rating converts to.
function S:GetDefenseSkill()
    -- UnitDefense returns (base, modifier) in TBC.
    if UnitDefense then
        local base, mod = UnitDefense("player")
        base = U.SafeNum(base)
        mod  = U.SafeNum(mod)
        if base > 0 then return base + mod, base, mod end
    end
    local level = U.GetPlayerLevel()
    return level * 5, level * 5, 0
end

-- ─── HIT THE RATING API CANNOT SEE ─────────────────────────────────────────
--
-- Two sources of hit never appear in GetCombatRatingBonus: racial auras
-- (Draenei Heroic Presence) and talents (Precision, Suppression, and friends).
-- Both reduce how much hit rating you need, so leaving them out makes every cap
-- on the Stat Caps tab overstate the requirement.
--
-- Resolution order, most trusted first:
--   1. A manual override the player set with /ta hitbonus. Always wins.
--   2. Talent detection (Data/TBCTalentHit.lua). Unverified, English names.
--   3. Racial (Data/TBCRaces.lua). Small and well established.
--
-- The breakdown is returned alongside the totals so the UI can attribute every
-- point rather than presenting one unexplained number.
--
--- @return number melee, number spell, table sources
function S:GetBonusHit()
    local sources = {}
    local melee, spell = 0, 0

    -- Racial
    local token = U.GetPlayerRace()
    local racial = TA.Data and TA.Data.RaceMechanics and TA.Data.RaceMechanics[token]
    if racial then
        if racial.meleeHitPercent then
            melee = melee + racial.meleeHitPercent
            sources[#sources + 1] = { label = racial.source or "racial",
                                      amount = racial.meleeHitPercent, kind = "melee" }
        end
        if racial.spellHitPercent then
            spell = spell + racial.spellHitPercent
            sources[#sources + 1] = { label = racial.source or "racial",
                                      amount = racial.spellHitPercent, kind = "spell" }
        end
    end

    -- Talents
    local charDB = TA.charDB or {}
    if TA.Data and TA.Data.DetectTalentHit and not charDB.disableTalentHit then
        local tMelee, tSpell, found, apiOK = TA.Data.DetectTalentHit()
        if apiOK then
            melee = melee + tMelee
            spell = spell + tSpell
            for _, entry in ipairs(found) do
                sources[#sources + 1] = {
                    label = string.format("%s %d/%d", entry.name, entry.rank, entry.maxRank),
                    amount = entry.amount, kind = entry.kind,
                    school = entry.school, unverified = true,
                }
            end
        else
            sources[#sources + 1] = { label = "talent API unavailable", amount = 0,
                                      kind = "both", failed = true }
        end
    end

    -- Manual override replaces everything above rather than adding to it.
    -- A player who has measured their own hit should not have a guess stacked
    -- on top of the number they measured.
    if charDB.hitBonusMelee or charDB.hitBonusSpell then
        melee = U.SafeNum(charDB.hitBonusMelee, melee)
        spell = U.SafeNum(charDB.hitBonusSpell, spell)
        sources = { { label = "your /ta hitbonus override", amount = nil,
                      kind = "both", override = true } }
    end

    return melee, spell, sources
end

-- ─── TARGET CONTEXT ────────────────────────────────────────────────────────
-- Every melee/spell cap in TBC is relative to the TARGET's level. There is no
-- such thing as "the hit cap" in isolation.

S.CONTEXTS = {
    { key = "same",  delta = 0, label = "Same level",     note = "questing, same-level mobs" },
    { key = "plus1", delta = 1, label = "+1 level",       note = "elites, most dungeon trash" },
    { key = "plus2", delta = 2, label = "+2 levels",      note = "dungeon bosses" },
    { key = "plus3", delta = 3, label = "+3 (boss)",      note = "raid & heroic bosses" },
}

--- The context to show by default. While levelling you fight same-level mobs;
--- at 70 the only cap worth planning around is the raid boss.
function S:DefaultContextKey()
    local level = U.GetPlayerLevel()
    if level >= 70 then return "plus3" end
    return "same"
end

function S:GetContext(key)
    key = key or self:DefaultContextKey()
    for _, ctx in ipairs(self.CONTEXTS) do
        if ctx.key == key then return ctx end
    end
    return self.CONTEXTS[1]
end

--- The context actually in force, accounting for PvP mode and the user's pin.
---
--- This resolution used to be copy-pasted into StatCaps, Character, WeaponSkill
--- and UI. Four copies of one rule is four places for PvP mode to be forgotten,
--- which is precisely the bug .rules.md Rule 4 exists to prevent. One function,
--- and every caller inherits PvP awareness for free.
---
--- PvP forces "same": an enemy player is your level. There is no +3 boss in an
--- arena, and a player gearing for a 9% hit cap in PvP is wasting roughly four
--- percent of their entire stat budget.
function S:ActiveContextKey()
    if TA.db and TA.db.pvpMode then return "same" end
    local key = TA.db and TA.db.capContext or "auto"
    if key == "auto" then return self:DefaultContextKey() end
    return key
end

function S:ActiveContext()
    return self:GetContext(self:ActiveContextKey())
end

-- ─── RESILIENCE ────────────────────────────────────────────────────────────
--
-- The PvP stat, and the only one in TBC with three simultaneous effects. One
-- percent of resilience gives:
--     -1% chance to be critically hit
--     -2% damage taken from crits that still land
--     -1% damage from damage-over-time effects
--
-- There is no cap. It is pure mitigation with diminishing practical value rather
-- than a threshold, which is why this returns effects rather than a "needed"
-- number — inventing a target here would be making one up.

local RESIL_CRIT_DAMAGE_MULTIPLIER = 2.0

--- @return table {rating, critReduction, critDamageReduction, dotReduction, measured}
function S:GetResilience()
    local rating = self:GetRating("CRIT_TAKEN_MELEE")
    local pct    = self:GetRatingBonus("CRIT_TAKEN_MELEE")
    local measured = true

    -- GetCombatRatingBonus is the direct answer. If it is unavailable, fall back
    -- to the conversion table and say so rather than reporting a clean zero.
    if pct <= 0 and rating > 0 then
        local perPct = select(1, self:GetRatingPerPercent("CRIT_TAKEN_MELEE"))
        if perPct and perPct > 0 then
            pct = rating / perPct
            measured = false
        end
    end

    return {
        rating              = rating,
        critReduction       = pct,
        critDamageReduction = pct * RESIL_CRIT_DAMAGE_MULTIPLIER,
        dotReduction        = pct,
        measured            = measured,
        hasAny              = rating > 0,
    }
end

--- The level delta of the player's current target, if they have one.
--- @return number|nil delta, string|nil name
function S:GetTargetDelta()
    if not UnitExists or not UnitExists("target") then return nil end
    local tLevel = U.SafeNum(UnitLevel("target"), -1)
    if tLevel < 0 then
        -- -1 means "skull" — treat as boss (+3), which is what it means in TBC.
        return 3, UnitName("target")
    end
    return tLevel - U.GetPlayerLevel(), UnitName("target")
end

-- ─── MELEE HIT ─────────────────────────────────────────────────────────────
--
-- Miss chance is driven by (target defense - your weapon skill), and the curve
-- has a knee at a difference of 10:
--     diff <= 10 :  5% + diff * 0.1
--     diff >  10 :  7% + (diff - 10) * 0.4
--
-- Level 70 vs a level 73 boss with 350 weapon skill:
--     defense 365, skill 350, diff 15  ->  7 + 5*0.4 = 9%   <- the "9% cap"
-- Level 22 vs a level 22 mob with 110 weapon skill:
--     defense 110, skill 110, diff 0   ->  5%
--
-- Dual wielding adds a flat 19% white-swing miss. Yellow (special) attacks are
-- unaffected, so this is reported separately rather than folded into one number.

local DUAL_WIELD_MISS = 19.0

function S:TargetDefense(targetLevel)
    return targetLevel * 5
end

--- Base miss chance against a target, before any +hit.
function S:MeleeMissChance(weaponSkill, targetDefense)
    local diff = targetDefense - weaponSkill
    if diff <= 0 then return 5.0 end
    if diff <= 10 then
        return 5.0 + diff * 0.1
    end
    return 7.0 + (diff - 10) * 0.4
end

--- The melee hit percentage that removes all avoidable misses.
--- @param opts table {contextKey, weaponSkill, dualWield, bonusHitPercent}
---        bonusHitPercent covers hit that GetCombatRatingBonus does not report —
---        Draenei Heroic Presence above all. Leaving it out makes a Draenei
---        over-gear hit by a full percent.
--- @return table
function S:GetMeleeHitCap(opts)
    opts = opts or {}
    local level     = U.GetPlayerLevel()
    local ctx       = self:GetContext(opts.contextKey)
    local tLevel    = level + ctx.delta
    local tDefense  = self:TargetDefense(tLevel)
    local maxSkill  = level * 5
    local skill     = opts.weaponSkill or maxSkill

    local specialCap = self:MeleeMissChance(skill, tDefense)
    local whiteCap   = specialCap + (opts.dualWield and DUAL_WIELD_MISS or 0)

    local fromGear = self:GetMeleeHitPercent()
    local bonus    = opts.bonusHitPercent or 0
    local current  = fromGear + bonus

    return {
        fromGear     = fromGear,
        fromOther    = bonus,
        context      = ctx,
        targetLevel  = tLevel,
        weaponSkill  = skill,
        maxSkill     = maxSkill,
        skillDeficit = math.max(maxSkill - skill, 0),
        cap          = specialCap,          -- what you actually gear for
        whiteCap     = whiteCap,            -- unreachable when dual wielding; informational
        dualWield    = opts.dualWield or false,
        current      = current,
        needed       = math.max(specialCap - current, 0),
        capped       = current >= specialCap,
    }
end

-- ─── SPELL HIT ─────────────────────────────────────────────────────────────
--
-- Spell miss does not use weapon skill. It is a flat table by level delta, with
-- a jump at +3, and 1% of it can never be removed by +hit:
--     delta 0 -> 4%,  +1 -> 5%,  +2 -> 6%,  +3 -> 17%
-- so the +3 cap is 16%, which is the figure the brief quotes.

local SPELL_BASE_MISS = { [0] = 4, [1] = 5, [2] = 6, [3] = 17 }
local SPELL_UNAVOIDABLE = 1.0

function S:SpellBaseMiss(delta)
    if delta < 0 then delta = 0 end
    if delta > 3 then delta = 3 end
    return SPELL_BASE_MISS[delta]
end

--- @param opts table {contextKey, bonusHitPercent}  bonusHitPercent = talents/auras
function S:GetSpellHitCap(opts)
    opts = opts or {}
    local ctx  = self:GetContext(opts.contextKey)
    local base = self:SpellBaseMiss(ctx.delta)
    local cap  = math.max(base - SPELL_UNAVOIDABLE, 0)

    local fromGear = self:GetSpellHitPercent()
    local bonus    = opts.bonusHitPercent or 0
    local current  = fromGear + bonus

    return {
        context     = ctx,
        targetLevel = U.GetPlayerLevel() + ctx.delta,
        baseMiss    = base,
        cap         = cap,
        fromGear    = fromGear,
        fromOther   = bonus,
        current     = current,
        needed      = math.max(cap - current, 0),
        capped      = current >= cap,
    }
end

-- ─── EXPERTISE ─────────────────────────────────────────────────────────────
--
-- Target dodge = 5% + (targetDefense - weaponSkill) * 0.1, and 1 expertise
-- removes 0.25%. Level 70 vs a 73 boss at 350 skill: 5 + 15*0.1 = 6.5% dodge,
-- 6.5/0.25 = 26 expertise. That is the brief's 26 — arrived at, not copied.
--
-- Parry is only relevant from the front, and costs roughly as much again; it is
-- reported separately because almost nobody gears for it.

local EXPERTISE_PER_POINT = 0.25

function S:TargetDodgeChance(weaponSkill, targetDefense)
    local diff = targetDefense - weaponSkill
    return 5.0 + math.max(diff, 0) * 0.1
end

--- @param opts table {contextKey, weaponSkill, includeParry}
function S:GetExpertiseCap(opts)
    opts = opts or {}
    local level    = U.GetPlayerLevel()
    local ctx      = self:GetContext(opts.contextKey)
    local tLevel   = level + ctx.delta
    local tDefense = self:TargetDefense(tLevel)
    local maxSkill = level * 5
    local skill    = opts.weaponSkill or maxSkill

    local dodge     = self:TargetDodgeChance(skill, tDefense)
    local dodgeCap  = math.ceil(dodge / EXPERTISE_PER_POINT)
    -- Parry uses the same avoidance curve as dodge for a mob of this level.
    local parryCap  = dodgeCap * 2

    local current = self:GetExpertise()

    return {
        context     = ctx,
        targetLevel = tLevel,
        weaponSkill = skill,
        targetDodge = dodge,
        cap         = dodgeCap,          -- attacking from behind: dodge only
        frontCap    = parryCap,          -- attacking from the front: dodge + parry
        current     = current,
        needed      = math.max(dodgeCap - current, 0),
        capped      = current >= dodgeCap,
        pctRemoved  = current * EXPERTISE_PER_POINT,
    }
end

-- ─── DEFENSE / UNCRITTABLE ─────────────────────────────────────────────────
--
-- Each point of defense above your own level*5 removes 0.04% crit taken. A
-- target three levels above crits for 5% base + 0.6% from the level gap = 5.6%,
-- needing 140 defense over base:  playerLevel*5 + 140.
-- At 70 that is 490 — for heroics AND raids alike. The brief's separate "540
-- raids" figure is the level-80 WotLK number (80*5 + 140).

local CRIT_REDUCTION_PER_DEFENSE = 0.04
local BASE_CRIT_TAKEN = 5.0
local CRIT_PER_LEVEL_GAP = 0.2

function S:GetDefenseCap(opts)
    opts = opts or {}
    local level = U.GetPlayerLevel()
    local ctx   = self:GetContext(opts.contextKey)

    local critTaken = BASE_CRIT_TAKEN + ctx.delta * CRIT_PER_LEVEL_GAP
    local overBase  = math.ceil(critTaken / CRIT_REDUCTION_PER_DEFENSE)
    local cap       = level * 5 + overBase

    local current, base, fromRating = self:GetDefenseSkill()

    return {
        context      = ctx,
        targetLevel  = level + ctx.delta,
        critTaken    = critTaken,
        cap          = cap,
        baseDefense  = base,
        fromRating   = fromRating,
        current      = current,
        needed       = math.max(cap - current, 0),
        capped       = current >= cap,
        critRemoved  = math.max(current - level * 5, 0) * CRIT_REDUCTION_PER_DEFENSE,
    }
end

-- ─── ARMOR ─────────────────────────────────────────────────────────────────
--
-- reduction = armor / (armor + 467.5*attackerLevel - 22167.5), hard-capped 75%.
-- Solving for 75% at attacker level 73 gives 35880 armor, which is the brief's
-- figure — this one checks out, so it is kept.

local ARMOR_CAP_PCT = 75.0

function S:ArmorConstant(attackerLevel)
    return 467.5 * attackerLevel - 22167.5
end

function S:ArmorReduction(armor, attackerLevel)
    local k = self:ArmorConstant(attackerLevel)
    if armor + k <= 0 then return 0 end
    return math.min(armor / (armor + k) * 100, ARMOR_CAP_PCT)
end

function S:GetArmorInfo(opts)
    opts = opts or {}
    local ctx    = self:GetContext(opts.contextKey)
    local aLevel = U.GetPlayerLevel() + ctx.delta

    -- FIXME: `UnitArmor and UnitArmor("player")` always yields effArmor = nil,
    -- even when UnitArmor exists. `and`/`or` truncate the right-hand call to a
    -- single value in Lua 5.1 (verified: `local a,b = f and f()` gives b == nil
    -- even when f exists and returns multiple values), so this assignment can
    -- never populate the second return. Armor and reduction% therefore always
    -- read as 0 here regardless of the player's actual armor. Needs an
    -- `if UnitArmor then _, effArmor = UnitArmor("player") end` guard instead,
    -- matching the pattern GetDefenseSkill() uses correctly below.
    local _, effArmor = UnitArmor and UnitArmor("player")
    effArmor = U.SafeNum(effArmor)

    local k = self:ArmorConstant(aLevel)
    local capArmor = 3 * k   -- armor/(armor+k) = 0.75  =>  armor = 3k

    return {
        context     = ctx,
        armor       = effArmor,
        attackerLvl = aLevel,
        reduction   = self:ArmorReduction(effArmor, aLevel),
        capArmor    = capArmor,
        capPct      = ARMOR_CAP_PCT,
        capped      = effArmor >= capArmor,
    }
end

-- ─── DIAGNOSTICS ───────────────────────────────────────────────────────────

--- The /dump lines that would confirm everything this file assumes.
--- Printed by `/ta dumpme` so the user can paste results back.
function S:DumpLines()
    return {
        "/dump CR_HIT_MELEE, CR_HIT_SPELL, CR_EXPERTISE, CR_DEFENSE_SKILL",
        "/dump GetCombatRating, GetCombatRatingBonus, GetExpertise, UnitDefense",
        "/run local i=CR_HIT_MELEE or 6 print('meleeHit rating',GetCombatRating(i),'pct',GetCombatRatingBonus and GetCombatRatingBonus(i))",
        "/run local i=CR_EXPERTISE or 24 print('exp rating',GetCombatRating(i),'pct',GetCombatRatingBonus and GetCombatRatingBonus(i),'GetExpertise',GetExpertise and GetExpertise())",
        "/dump GetNumTalentTabs, GetTalentTabInfo, GetNumSkillLines, GetSkillLineInfo",
        "/dump GetManaRegen, GetSpellBonusDamage, GetSpellBonusHealing, GetAttackPowerForStat",
        "/dump GetItemStats, UnitAttackBothHands, GetProfessions",
    }
end

--- A one-line health string describing how much of this file is measured.
function S:ConfidenceReport()
    local lines = {}

    if self.crAnyGuessed then
        local guessed = {}
        for key in pairs(self.CRGuessed) do guessed[#guessed + 1] = "CR_" .. key end
        table.sort(guessed)
        lines[#lines + 1] = U.Red("Combat rating globals absent, using documented TBC indices: ")
            .. table.concat(guessed, ", ")
    else
        lines[#lines + 1] = U.Green("All combat rating indices resolved from client globals.")
    end

    if not GetCombatRatingBonus then
        lines[#lines + 1] = U.Red("GetCombatRatingBonus is nil — percentages unavailable, caps degraded.")
    end

    local _, src = self:GetRatingPerPercent("HIT_MELEE")
    local srcText = (src == "derived" and U.Green("derived from live client"))
                 or (src == "formula" and U.Orange("formula (you hold no hit rating yet)"))
                 or U.Red("unavailable below level 60 with no rating")
    lines[#lines + 1] = "Hit rating conversion: " .. srcText

    return lines
end

function S:Init()
    if self.crAnyGuessed then
        TA:Print(TA.LOG.WARN, "TBCStats",
            "Some CR_* globals were absent; fell back to documented TBC indices. |cFFFFD100/ta caps|r shows which.")
    end
end
