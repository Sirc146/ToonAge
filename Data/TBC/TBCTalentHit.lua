-- ToonAge/Data/TBCTalentHit.lua (Anniversary — TBC Classic / 20506)
-- Talents that grant hit chance, which the rating API does not report.
--
-- ══════════════════════════════════════════════════════════════════════════════
-- ── THE BUG THIS FIXES ────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════
--
-- GetCombatRatingBonus reports hit from RATING. It does not report hit granted
-- by a talent. So a Fury warrior with 3/3 Precision is walking around with 3%
-- more hit than this addon can see, and Stat Caps was telling them to go find
-- another 3% — roughly 47 rating at level 70 — that they already had.
--
-- That is the flagship tab being wrong, on maybe a third of all specs, in the
-- direction of "buy more of a stat you have enough of". Worse than useless.
--
-- ══════════════════════════════════════════════════════════════════════════════
-- ── SCHOOL-SPECIFIC HIT IS NOT THE SAME AS HIT ────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Several of these only apply to one school or one spell family:
--   Arcane Focus   arcane spells only
--   Suppression    affliction spells only
--   Shadow Focus   shadow spells only
--   Elemental Precision (mage)  frost and fire only
--
-- A Shadow priest with 5/5 Shadow Focus is hit-capped for Mind Blast and NOT
-- for Holy Fire. Treating those as a flat account-wide bonus would swap one
-- wrong answer for a subtler one, so `school` is recorded and shown, and the
-- Stat Caps tab says which spells the bonus actually covers.
--
-- ══════════════════════════════════════════════════════════════════════════════
-- ── CONFIDENCE ────────────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════
--
-- UNVERIFIED. Talent names and per-rank values below are from knowledge, not
-- from a dump, and they are exactly the kind of plausible-looking data this
-- project has been burned by before. Three guards:
--
--   1. `/ta hitbonus <melee> <spell>` sets a manual override that wins over
--      everything here. That is the reliable floor and it needs no talent data
--      to be correct.
--   2. Detection reports its provenance — "3.0% from Precision 3/3" — so a
--      wrong value is visible rather than silently folded into a total.
--   3. Names are matched in English. A miss shows no bonus rather than a wrong
--      one, and the tab says detection found nothing.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.TalentHitUnverified = true

-- perRank is percent of hit per talent rank.
-- kind: "melee" (also covers ranged) or "spell".
-- school: nil = all spells of that kind; otherwise the family it is limited to.
TA.Data.HitTalents = {
    WARRIOR = {
        { name = "Precision", perRank = 1, maxRank = 3, kind = "melee" },
    },
    ROGUE = {
        { name = "Precision", perRank = 1, maxRank = 5, kind = "melee" },
    },
    -- Precision (Protection) has read "melee weapons AND spells" since 2.3, so it
    -- feeds both buckets (fixed 2026-09-16; it used to count melee only).
    PALADIN = {
        -- Since 2.3 Precision reads "melee weapons AND spells": kind "both".
        { name = "Precision", perRank = 1, maxRank = 3, kind = "both" },
    },
    -- Fixed 2026-09-07: Surefooted is a single-point Survival talent, not 3
    -- ranks of 1%. Its tooltip is a flat "+3% hit, both melee and ranged" the
    -- moment it is taken, so GetTalentInfo returns rank 1 for a Hunter who has
    -- it — the old { perRank = 1, maxRank = 3 } clamped `effective` to 1 and
    -- credited only 1% instead of the real 3%, a 2-point undercount in the
    -- same direction ("go find hit you already have") the file header calls
    -- out as the flagship failure mode.
    -- Re-corrected 2026-09-16: Surefooted is 3 ranks at 1% each in TBC (Wowhead
    -- TBC spell 24283 is the rank-3 tooltip, "+3%"; TBC Survival build guides
    -- list it as 3/3). The 2026-09-07 change to a single 3% rank over-credited
    -- a hunter with 1/3 or 2/3 by up to 2%.
    HUNTER = {
        { name = "Surefooted", perRank = 1, maxRank = 3, kind = "melee" },
    },
    MAGE = {
        { name = "Elemental Precision", perRank = 1, maxRank = 3, kind = "spell",
          school = "Frost and Fire" },
        { name = "Arcane Focus",        perRank = 2, maxRank = 5, kind = "spell",
          school = "Arcane only" },
    },
    WARLOCK = {
        { name = "Suppression", perRank = 2, maxRank = 5, kind = "spell",
          school = "Affliction spells only" },
    },
    PRIEST = {
        { name = "Shadow Focus", perRank = 2, maxRank = 5, kind = "spell",
          school = "Shadow only" },
    },
    -- Corrected 2026-09-16. Icy Veins TBC Elemental stat page: "Totem of Wrath,
    -- Elemental Precision, and Nature's Guidance talents provide 12% Spell Hit"
    -- = 3% (totem) + 6% (EP 3/3, so 2% per rank, not 1%) + 3% (NG 3/3).
    -- Nature's Guidance also gives MELEE hit, and Dual Wield Specialization
    -- (Enhancement, 3 ranks, 2/4/6%) only applies while dual wielding — both were
    -- missing, so an Enhancement Shaman was told to find up to 9% hit they had.
    -- Totem of Wrath is a totem buff, not a passive, so it is not counted here.
    SHAMAN = {
        { name = "Elemental Precision", perRank = 2, maxRank = 3, kind = "spell",
          school = "Fire, Frost and Nature" },
        { name = "Nature's Guidance", perRank = 1, maxRank = 3, kind = "both" },
        { name = "Dual Wield Specialization", perRank = 2, maxRank = 3, kind = "melee",
          school = "only while dual wielding", requiresDualWield = true },
    },
    DRUID = {
        { name = "Balance of Power", perRank = 2, maxRank = 2, kind = "spell" },
    },
}

-- True when the off-hand slot holds a weapon (not a shield or held item).
local function IsDualWielding()
    if type(GetInventoryItemLink) ~= "function" then return false end
    local link = GetInventoryItemLink("player", 17)
    if not link then return false end
    local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if getInstant then
        local ok, _, _, _, equipLoc = pcall(getInstant, link)
        if ok and equipLoc then
            return equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND"
        end
    end
    return false
end

--- Walk every talent in every tree and total the hit granted.
--- Requires GetNumTalentTabs / GetNumTalents / GetTalentInfo.
--- @return number meleePct, number spellPct, table found, boolean apiOK
function TA.Data.DetectTalentHit()
    local U = TA.Utils
    local class = U.GetPlayerClass()
    local wanted = TA.Data.HitTalents[class]
    if not wanted then return 0, 0, {}, true end

    if type(GetNumTalentTabs) ~= "function"
    or type(GetNumTalents)    ~= "function"
    or type(GetTalentInfo)    ~= "function" then
        return 0, 0, {}, false
    end

    -- Index the talents we care about by name for a single pass.
    local byName = {}
    for _, entry in ipairs(wanted) do byName[entry.name] = entry end

    local melee, spell, found = 0, 0, {}
    local numTabs = U.SafeGetNum(GetNumTalentTabs)

    for tab = 1, numTabs do
        local numTalents = U.SafeGetNum(GetNumTalents, tab)
        for i = 1, numTalents do
            local ok, name, _, _, _, rank = pcall(GetTalentInfo, tab, i)
            if ok and name then
                local entry = byName[name]
                rank = U.SafeNum(rank)
                if entry and entry.requiresDualWield and not IsDualWielding() then
                    entry = nil
                end
                if entry and rank > 0 then
                    -- Clamp: a rank above the expected maximum means this table
                    -- is wrong about the talent, so do not multiply it out.
                    local effective = math.min(rank, entry.maxRank)
                    local amount = effective * entry.perRank

                    if entry.kind == "melee" then
                        melee = melee + amount
                    elseif entry.kind == "both" then
                        melee = melee + amount
                        spell = spell + amount
                    else
                        spell = spell + amount
                    end

                    found[#found + 1] = {
                        name = name, rank = rank, maxRank = entry.maxRank,
                        amount = amount, kind = entry.kind, school = entry.school,
                        overRank = rank > entry.maxRank,
                    }
                end
            end
        end
    end

    return melee, spell, found, true
end


-- ─── CRIT-TAKEN REDUCTION (feeds the defense "uncrittable" cap) ─────────────
-- A boss three levels up crits a level-70 tank 5.6% of the time; defense above
-- 350 removes 0.04% per point, hence 490. Anything else that lowers the chance
-- to be crit lowers that target: Feral's Survival of the Fittest (1% per rank,
-- 3 ranks) is why bear tanks cap at 415 defense, not 490, and resilience counts
-- the same way. Without this the Stat Caps tab told every bear to chase 75
-- defense points it did not need.
TA.Data.CritTakenTalents = {
    DRUID = {
        { name = "Survival of the Fittest", perRank = 1, maxRank = 3 },
    },
}

--- @return number pct, table found, boolean apiOK
function TA.Data.DetectCritTakenReduction()
    local U = TA.Utils
    local wanted = TA.Data.CritTakenTalents[U.GetPlayerClass()]
    if not wanted then return 0, {}, true end
    if type(GetNumTalentTabs) ~= "function" or type(GetNumTalents) ~= "function"
    or type(GetTalentInfo) ~= "function" then
        return 0, {}, false
    end
    local byName = {}
    for _, e in ipairs(wanted) do byName[e.name] = e end
    local pct, found = 0, {}
    for tab = 1, U.SafeGetNum(GetNumTalentTabs) do
        for i = 1, U.SafeGetNum(GetNumTalents, tab) do
            local ok, name, _, _, _, rank = pcall(GetTalentInfo, tab, i)
            local e = ok and name and byName[name]
            rank = U.SafeNum(rank)
            if e and rank > 0 then
                local amount = math.min(rank, e.maxRank) * e.perRank
                pct = pct + amount
                found[#found + 1] = { name = name, rank = rank, maxRank = e.maxRank, amount = amount }
            end
        end
    end
    return pct, found, true
end
