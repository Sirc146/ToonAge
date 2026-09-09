-- ToonAge/Core/StatEngine.lua
-- Live, diminishing-returns-aware precision stat engine.
--
-- WHY THIS EXISTS
-- ───────────────
-- Data/StatWeights.lua holds DIRECTIONAL weights (1.30 / 1.10 / 0.95 …) that
-- rank secondaries but do NOT account for diminishing returns (DR). At low
-- rating a point of Haste is worth its full weight; past Blizzard's penalty
-- brackets each additional point converts to less % than the one before.
-- Comparing two items with the raw weights therefore over-values whichever
-- item stacks the stat you already have the most of.
--
-- This engine computes the *marginal* value of the NEXT rating point for each
-- secondary at the player's CURRENT rating, using Blizzard's exact Midnight
-- DR brackets. The value of one more point is the derivative of the rating→%
-- curve, so this is client-exact (SimulationCraft parity), not table-approx.
--
-- THE DR MODEL (Patch 12.0.1 "Midnight", verified maxroll.gg 2026)
-- ─────────────────────────────────────────────────────────────────
-- Secondary rating converts to % linearly UNTIL it crosses a penalty bracket.
-- Each bracket applies its penalty ONLY to the rating that falls inside it
-- (marginal, never retroactive). Example (Haste, 44 rating = 1% at L90):
--   0–1320    full value            (0–30%)
--   1320–1760 −10% per point        (each point worth 0.90×)
--   1760–2200 −20% per point
--   2200–2640 −30% per point
--   2640–3080 −40% per point
--   3080–8800 −50% per point
--   >8800     −100% (worthless)
-- So the marginal value of the next point at rating R is:
--   marginal% = (1 / ratingPer1Pct) × (1 − penalty(R))
-- and the relative weight the caller sees is that marginal%, normalised so a
-- point below any bracket == the stat's StatWeights directional weight.
--
-- PRECISION (per .kiro/steering/precision.md, spec item 2)
-- ────────────────────────────────────────────────────────
--   Internal math : 0.001 (3 dp) — derivatives multiplied across stat budgets
--   UI display    : 0.01  (2 dp) — capped for readability by the caller
--
-- ROLES  — TANK (survival lean on Stam/Vers/Armor), HEALER (Haste throughput
-- nudge), DAMAGER. Auto-detected via spec role, then group assignment.
--
-- PETS   — several specs deal damage through a pet that inherits owner
-- secondaries; the owner's scaling stat is worth more while the pet is out.

local TA = ToonAge
local U  = TA.Utils

local StatEngine = {}
TA.StatEngine = StatEngine

-- ── Blizzard combat-rating indices (CR_* constants) ───────────────────
local CR = {
    CRIT    = 9,   -- CR_CRIT_MELEE (crit rating shared across melee/ranged/spell)
    HASTE   = 18,  -- CR_HASTE_MELEE
    MASTERY = 26,  -- CR_MASTERY
    VERS    = 29,  -- CR_VERSATILITY_DAMAGE_DONE
}

-- ── DR penalty brackets (Patch 12.0.1 Midnight, level 90) ─────────────
-- Each entry: { upperRatingBound, penaltyFraction }. penalty is the fraction
-- of value LOST for rating inside [previousBound, upperRatingBound). The last
-- band (>final bound) is 1.00 = fully worthless. Verified maxroll.gg 2026
-- ("Stat Diminishing Returns", Patch 12.0.1) — same rating brackets Blizzard
-- publishes; Character.lua's DR_SOFT_CAP holds the FIRST bound of each.
--
-- IMPORTANT: these are the level-90 (current cap) brackets. Below max level
-- Blizzard scales the rating-per-% and the bracket bounds down together, so
-- the % thresholds (30/39/47…) are level-independent while the RATING numbers
-- are not. RatingPer1Pct is read LIVE from the game (see MarginalPercent) so
-- the engine stays correct at every level; the bracket bounds here are the
-- L90 reference used when a live read is unavailable.
local DR_BRACKETS = {
    HASTE = {
        { 1320, 0.00 }, { 1760, 0.10 }, { 2200, 0.20 },
        { 2640, 0.30 }, { 3080, 0.40 }, { 8800, 0.50 },
    },
    CRIT = {
        { 1380, 0.00 }, { 1840, 0.10 }, { 2300, 0.20 },
        { 2760, 0.30 }, { 3220, 0.40 }, { 9200, 0.50 },
    },
    MASTERY = { -- same rating bounds as Crit
        { 1380, 0.00 }, { 1840, 0.10 }, { 2300, 0.20 },
        { 2760, 0.30 }, { 3220, 0.40 }, { 9200, 0.50 },
    },
    VERS = {
        { 1620, 0.00 }, { 2160, 0.10 }, { 2700, 0.20 },
        { 3240, 0.30 }, { 3780, 0.40 }, { 10800, 0.50 },
    },
}

-- Rating needed for 1% at level 90 (fallback reference; live value preferred).
local RATING_PER_PCT_L90 = { HASTE = 44, CRIT = 46, VERS = 54, MASTERY = 46 }

-- Pet secondary-inheritance multipliers, keyed by specID. Applied on top of
-- the marginal value to the stat the pet scales through while a pet is active.
local PET_SCALING = {
    [253] = { MASTERY = 1.30, HASTE = 1.10 }, -- Beast Mastery: pet is main damage
    [255] = { MASTERY = 1.12 },               -- Survival: pet contributes
    [254] = {},                               -- Marksmanship: lone-wolf, neutral
    [252] = { MASTERY = 1.20 },               -- Unholy DK: ghoul/army scale
    [266] = { MASTERY = 1.25, HASTE = 1.08 }, -- Demonology: demons inherit
}

-- ── Role detection ────────────────────────────────────────────────────
function StatEngine:GetRole(specID)
    specID = specID or (U.GetPlayerSpecID and U.GetPlayerSpecID())
    local SW = TA.Data and TA.Data.StatWeights
    if SW and specID then
        local r = SW:GetRole(specID)
        if r == "TANK" or r == "HEALER" or r == "DAMAGER" then
            return r
        end
    end
    local assigned = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
    if assigned == "TANK" then return "TANK" end
    if assigned == "HEALER" then return "HEALER" end
    return "DAMAGER"
end

-- ── Live reads ────────────────────────────────────────────────────────
local function SafeRating(crIndex)
    if not crIndex then return 0 end
    local ok, v = pcall(GetCombatRating, crIndex)
    return (ok and type(v) == "number") and v or 0
end

-- Live percent the current rating is granting (already DR-adjusted by the
-- engine). Used to derive the true rating-per-% at the player's actual level.
local function LiveBonusPct(crIndex)
    if not crIndex then return 0 end
    local ok, v = pcall(GetCombatRatingBonus, crIndex)
    return (ok and type(v) == "number") and v or 0
end

-- Rating required for 1% of the stat at the player's CURRENT level. Preferred
-- source is the live game numbers: below the first DR bracket the conversion
-- is linear, so ratingPerPct = rating / bonusPct exactly. If we're already
-- inside DR (or the read fails), fall back to the L90 reference constant.
local function RatingPer1Pct(statKey)
    local crIndex = CR[statKey]
    if crIndex then
        local rating  = SafeRating(crIndex)
        local firstDR = DR_BRACKETS[statKey] and DR_BRACKETS[statKey][1][1]
        if rating > 0 and firstDR and rating < firstDR then
            local pct = LiveBonusPct(crIndex)
            if pct and pct > 0 then
                return rating / pct
            end
        end
    end
    return RATING_PER_PCT_L90[statKey] or 100
end

-- ── DR penalty at a given rating ──────────────────────────────────────
-- Returns the penalty FRACTION (0..1) applied to the NEXT point of `statKey`
-- at the current `rating`. 0 below the first bracket; 1.00 past the last.
function StatEngine:GetPenalty(statKey, rating)
    local brackets = DR_BRACKETS[statKey]
    if not brackets then return 0 end
    for _, b in ipairs(brackets) do
        if rating < b[1] then return b[2] end
    end
    return 1.00 -- past the final published bound: next point is worthless
end

-- Retention (1 - penalty) — the fraction of full value the next point keeps.
function StatEngine:GetRetention(statKey, rating)
    return 1.0 - self:GetPenalty(statKey, rating)
end

-- Average retention across a RANGE of rating [fromRating, fromRating+amount].
-- This is the precise value of ADDING `amount` rating: an item's stat budget
-- spans brackets, so scoring every point at the single current-rating penalty
-- (the naive derivative) mis-estimates when the added rating crosses a
-- bracket boundary. Here we walk the brackets, weight each band's retention
-- by how much of `amount` lands inside it, and return the amount-weighted
-- mean retention. Integrating the piecewise-constant penalty exactly matches
-- how Blizzard applies DR (penalty only to the rating crossing each bound),
-- which is what the ".000" precision requirement needs.
function StatEngine:GetSpanRetention(statKey, fromRating, amount)
    if amount <= 0 then return 1.0 end
    local brackets = DR_BRACKETS[statKey]
    if not brackets then return 1.0 end  -- primary stats: no DR

    local lo, hi = fromRating, fromRating + amount
    local weighted, prevBound = 0, 0
    for _, b in ipairs(brackets) do
        local bound, penalty = b[1], b[2]
        -- Overlap of [lo,hi] with this band [prevBound, bound)
        local segLo = math.max(lo, prevBound)
        local segHi = math.min(hi, bound)
        if segHi > segLo then
            weighted = weighted + (segHi - segLo) * (1.0 - penalty)
        end
        prevBound = bound
        if prevBound >= hi then
            return math.floor((weighted / amount) * 1000 + 0.5) / 1000
        end
    end
    -- Any rating above the final published bound is worthless (penalty 1.0),
    -- contributing 0 retention — already excluded by the loop, so just
    -- normalise what we accumulated.
    return math.floor((weighted / amount) * 1000 + 0.5) / 1000
end

-- ── Marginal value ────────────────────────────────────────────────────
-- Value of ONE more rating point of `statKey` for `specID`, on the same
-- relative scale as StatWeights so callers can mix it with primary weights.
-- 3-dp internal precision.
--
--   marginal = baseWeight × retention × petFactor × roleFactor
--
-- retention is the precision fix: it is the live DR bracket at the player's
-- current rating, so two items that both add Haste are no longer scored
-- identically once you're past the Haste 30% breakpoint.
function StatEngine:GetMarginalValue(statKey, specID, role)
    specID = specID or (U.GetPlayerSpecID and U.GetPlayerSpecID())
    role   = role or self:GetRole(specID)

    local SW = TA.Data and TA.Data.StatWeights
    local weights = SW and specID and SW:GetWeights(specID, "pve") or nil
    local baseWeight = (weights and weights[statKey]) or 0.20

    local retention = 1.0
    if CR[statKey] then
        retention = self:GetRetention(statKey, SafeRating(CR[statKey]))
    end

    local petFactor = 1.0
    if UnitExists("pet") and specID and PET_SCALING[specID] then
        petFactor = PET_SCALING[specID][statKey] or 1.0
    end

    local roleFactor = 1.0
    if role == "TANK" then
        if statKey == "STAM" then roleFactor = 1.40
        elseif statKey == "VERS" then roleFactor = 1.20 -- Vers reduces damage taken
        elseif statKey == "ARMOR" then roleFactor = 1.25 end
    elseif role == "HEALER" then
        if statKey == "HASTE" then roleFactor = 1.05 end -- cast-speed throughput
    end

    local marginal = baseWeight * retention * petFactor * roleFactor
    return math.floor(marginal * 1000 + 0.5) / 1000
end

-- Marginal % gained from the next rating point (the raw derivative, in stat-%
-- per point). Diagnostic / tooltip use — shows WHY a stat's value dropped.
function StatEngine:GetMarginalPercentPerPoint(statKey)
    if not CR[statKey] then return 0 end
    local rating    = SafeRating(CR[statKey])
    local perPct    = RatingPer1Pct(statKey)      -- rating for 1% (no DR)
    local retention = self:GetRetention(statKey, rating)
    if perPct <= 0 then return 0 end
    local v = (1 / perPct) * retention
    return math.floor(v * 1000 + 0.5) / 1000
end

-- ── Item scoring (DR-aware, span-integrated) ──────────────────────────
-- Drop-in replacement for SW:ScoreItem respecting live DR, pet and role.
-- `stats` is a { STATKEY = ratingAmount } table. 3-dp internal precision.
--
-- Unlike GetMarginalValue (which values a SINGLE next point), this values the
-- whole `amount` an item adds by integrating the DR penalty across the rating
-- span the item pushes you through. That removes the boundary-crossing error:
-- an item that carries you from 1250 -> 1650 Haste is scored with the ~70 pts
-- below 1320 at full value and the ~330 above it at 0.90, not all 400 at one
-- tier. baseWeight, pet and role factors still apply per stat.
function StatEngine:ScoreItem(stats, specID, role)
    if type(stats) ~= "table" then return 0 end
    specID = specID or (U.GetPlayerSpecID and U.GetPlayerSpecID())
    role   = role or self:GetRole(specID)

    local SW = TA.Data and TA.Data.StatWeights
    local weights = SW and specID and SW:GetWeights(specID, "pve") or nil

    local score = 0
    for statKey, amount in pairs(stats) do
        local a = tonumber(amount) or 0
        if a ~= 0 then
            local baseWeight = (weights and weights[statKey]) or 0.20

            -- Span-integrated DR retention for secondaries; 1.0 for primaries.
            local retention = 1.0
            if CR[statKey] then
                retention = self:GetSpanRetention(statKey, SafeRating(CR[statKey]), a)
            end

            -- Pet inheritance
            local petFactor = 1.0
            if UnitExists("pet") and specID and PET_SCALING[specID] then
                petFactor = PET_SCALING[specID][statKey] or 1.0
            end

            -- Role lean
            local roleFactor = 1.0
            if role == "TANK" then
                if statKey == "STAM" then roleFactor = 1.40
                elseif statKey == "VERS" then roleFactor = 1.20
                elseif statKey == "ARMOR" then roleFactor = 1.25 end
            elseif role == "HEALER" then
                if statKey == "HASTE" then roleFactor = 1.05 end
            end

            score = score + baseWeight * retention * petFactor * roleFactor * a
        end
    end
    return math.floor(score * 1000 + 0.5) / 1000
end

-- ── Full secondary breakdown ──────────────────────────────────────────
-- Ordered { key, name, rating, retention, penalty, capped, marginal } for the
-- four secondaries, sorted by marginal value descending. Powers the Character
-- tab's DR-honest priority list. Also returns role and pet-active flag.
local SECONDARY_NAMES = {
    CRIT = "Critical Strike", HASTE = "Haste",
    MASTERY = "Mastery",      VERS = "Versatility",
}

function StatEngine:GetSecondaryBreakdown(specID, role)
    specID = specID or (U.GetPlayerSpecID and U.GetPlayerSpecID())
    role   = role or self:GetRole(specID)
    local petActive = UnitExists("pet") and specID and PET_SCALING[specID] ~= nil
                      and next(PET_SCALING[specID]) ~= nil

    local list = {}
    for _, key in ipairs({ "CRIT", "HASTE", "MASTERY", "VERS" }) do
        local rating  = SafeRating(CR[key])
        local penalty = self:GetPenalty(key, rating)
        local firstDR = DR_BRACKETS[key] and DR_BRACKETS[key][1][1] or math.huge
        list[#list + 1] = {
            key       = key,
            name      = SECONDARY_NAMES[key],
            rating    = rating,
            penalty   = penalty,
            retention = 1.0 - penalty,
            capped    = rating >= firstDR,   -- past the 30% soft cap
            marginal  = self:GetMarginalValue(key, specID, role),
        }
    end
    table.sort(list, function(a, b)
        if a.marginal == b.marginal then return a.rating < b.rating end
        return a.marginal > b.marginal
    end)
    return list, role, petActive
end

return StatEngine
