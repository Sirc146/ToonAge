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
    -- NOTE: Precision (Protection) has read as "melee weapons AND spells" since
    -- patch 2.3, not melee-only. This entry only feeds the melee bucket, so a
    -- Protection Paladin's spell hit (Judgement, Consecration, Holy Shock) never
    -- picks up its 3% share here and Stat Caps will ask for spell hit rating the
    -- Paladin already has from this talent.
    PALADIN = {
        { name = "Precision", perRank = 1, maxRank = 3, kind = "melee" },
    },
    -- FIXME: Surefooted is a single-point Survival talent, not 3 ranks of 1%. Its
    -- tooltip is a flat "+3% hit, both melee and ranged" the moment it is taken.
    -- GetTalentInfo will therefore return rank 1 for a Hunter who has it, and
    -- `effective = math.min(rank, maxRank)` clamps that to 1 against this table's
    -- maxRank = 3, crediting only 1% instead of the real 3% — a 2-point
    -- undercount in the same direction ("go find hit you already have") that the
    -- header above calls out as the flagship failure mode. Should be
    -- { perRank = 3, maxRank = 1 }.
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
    SHAMAN = {
        { name = "Elemental Precision", perRank = 1, maxRank = 3, kind = "spell",
          school = "Fire, Frost and Nature" },
    },
    DRUID = {
        { name = "Balance of Power", perRank = 2, maxRank = 2, kind = "spell" },
    },
}

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
                if entry and rank > 0 then
                    -- Clamp: a rank above the expected maximum means this table
                    -- is wrong about the talent, so do not multiply it out.
                    local effective = math.min(rank, entry.maxRank)
                    local amount = effective * entry.perRank

                    if entry.kind == "melee" then
                        melee = melee + amount
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
