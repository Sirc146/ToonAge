-- ToonAge/Data/TBCPvP.lua (Anniversary — TBC Classic / Interface 20506)
-- Arena and battleground reference data.
--
-- ─── CONFIDENCE, STATED UP FRONT ─────────────────────────────────────────────
--
-- This file mixes three grades of certainty and labels each one, because a PvP
-- tab that presents a half-remembered rating requirement with the same
-- confidence as a formula is worse than no tab.
--
--   EXACT      Computed elsewhere from client data. The PvP hit and expertise
--              caps are not in this file at all — an enemy player is a
--              same-level target, so Core/TBCStats.lua already produces them
--              correctly the moment PvP mode forces the "same" context.
--
--   FORMULA    The arena point curve. Widely documented and reproducible, but
--              NOT verified against this client. Marked `unverified` so the tab
--              can say so, and trivially correctable if your first payout
--              disagrees.
--
--   REFERENCE  Diminishing-returns categories, gear sources, rating gates.
--              Text for a human to read. Nothing computes from it.
--
-- Numbers most likely to be wrong are the season rating gates — they moved
-- between seasons and between the original TBC and Anniversary. They are marked
-- and grouped so one correction fixes them all.

local TA = ToonAge
TA.Data = TA.Data or {}

-- ─── RESILIENCE (EXACT — effects computed in Core/TBCStats.lua) ──────────────

TA.Data.ResilienceNotes = {
    "One percent of resilience does three things at once: −1% chance to be crit, "
        .. "−2% damage from crits that still land, and −1% damage from every "
        .. "damage-over-time effect on you.",
    "There is no cap and no breakpoint. Anyone quoting a magic resilience number "
        .. "is describing a comfort level, not a mechanic.",
    "It is worth nothing in PvE. If an item's only edge is resilience, it is a "
        .. "downgrade for raiding — which is why this addon scores it separately "
        .. "in PvP mode.",
    "Against burst specs the crit-damage half matters more than the crit-chance "
        .. "half, because it applies to every crit you fail to avoid.",
}

-- ─── DIMINISHING RETURNS (REFERENCE) ─────────────────────────────────────────
-- The single most important PvP mechanic that has no UI anywhere in the game.
-- Categories share a DR chain: full duration, then half, then a quarter, then
-- immune. The chain resets after roughly 15 seconds without a new application.

TA.Data.DRWindowSeconds = 15
TA.Data.DRChain = { "100%", "50%", "25%", "immune" }

TA.Data.DRCategories = {
    { name = "Stun",         examples = "Cheap Shot, Kidney Shot, Hammer of Justice, Concussion Blow, War Stomp" },
    { name = "Fear",         examples = "Fear, Howl of Terror, Intimidating Shout, Psychic Scream, Scare Beast" },
    { name = "Incapacitate", examples = "Polymorph, Sap, Gouge, Repentance, Freezing Trap" },
    { name = "Root",         examples = "Frost Nova, Entangling Roots, Frostbite, Improved Hamstring" },
    { name = "Disorient",    examples = "Blind, Scatter Shot, Turn Evil" },
    { name = "Silence",      examples = "Silence, Garrote - Silence, Arcane Torrent, Spell Lock" },
    { name = "Horror",       examples = "Death Coil, Psychic Horror" },
}

TA.Data.DRNotes = {
    "Different categories do not share a chain — a stun after a fear both land at "
        .. "full duration.",
    "The chain applies to the TARGET, per category, and it ticks from the moment "
        .. "the effect ends rather than when it lands.",
    "This is why chain-CC comps open with the longest effect: you spend the full "
        .. "duration first, not last.",
    "PvP trinkets break one effect on a two-minute cooldown and do not reset DR. "
        .. "Not carrying one is the single most common gearing mistake in arena.",
}

-- ─── ARENA POINTS (FORMULA — unverified on this client) ──────────────────────
--
-- The documented TBC curve. Points are awarded weekly per team, scaled by
-- bracket, and you must have played enough of the team's games to be paid.
--
--   rating <= 1500 :  points = 0.22 * rating + 14
--   rating >  1500 :  points = 1511.26 / (1 + 1639.28 * e^(-0.00412 * rating))
--
-- Then multiplied by the bracket factor below. The 5v5 bracket pays the most for
-- the same rating, which is why point-farming teams historically lived there.

TA.Data.ArenaPointsUnverified = true

TA.Data.ArenaBrackets = {
    { size = 2, label = "2v2", factor = 0.76 },
    { size = 3, label = "3v3", factor = 0.88 },
    { size = 5, label = "5v5", factor = 1.00 },
}

TA.Data.ArenaMinGamesPerWeek = 10
TA.Data.ArenaPersonalParticipation = 0.30   -- share of the team's games you must play

--- Weekly arena points for a team rating in a bracket.
--- @return number points
function TA.Data.ArenaPointsFor(rating, bracketFactor)
    rating = tonumber(rating) or 0
    bracketFactor = tonumber(bracketFactor) or 1.0
    if rating <= 0 then return 0 end

    local base
    if rating <= 1500 then
        base = 0.22 * rating + 14
    else
        base = 1511.26 / (1 + 1639.28 * math.exp(-0.00412 * rating))
    end
    return base * bracketFactor
end

-- ─── GEAR SOURCES (REFERENCE) ────────────────────────────────────────────────

TA.Data.PvPGearSources = {
    {
        name = "Honor gear",
        cost = "Honor points + battleground marks",
        note = "No rating requirement at all. This is the floor every PvP character "
            .. "should stand on before queueing arena — resilience from anywhere "
            .. "beats none.",
        gated = false,
    },
    {
        name = "Arena gear — most slots",
        cost = "Arena points",
        note = "Chest, legs, gloves, helm and boots historically carried no personal "
            .. "rating gate. Points alone.",
        gated = false,
    },
    {
        name = "Arena gear — weapons and shoulders",
        cost = "Arena points + a personal and team rating requirement",
        note = "The gated pieces. Exact thresholds moved between seasons; check the "
            .. "vendor tooltip in game rather than trusting any addon, including "
            .. "this one.",
        gated = true,
    },
    {
        name = "Season-behind arena gear",
        cost = "Honor points + marks",
        note = "Each new season pushes the previous season's set onto the honor "
            .. "vendor. The cheapest large resilience jump available to a fresh 70.",
        gated = false,
    },
}

TA.Data.RatingGateWarning =
    "Rating requirements on arena weapons and shoulders are NOT hardcoded here. "
    .. "They changed between seasons and this build has not verified them against "
    .. "Anniversary. The vendor tooltip is authoritative — read it there."

-- ─── POWER SPIKES ────────────────────────────────────────────────────────────
--
-- PvP strength in TBC arrives in steps, not as a smooth curve. Three of the four
-- steps are things this addon can MEASURE rather than describe:
--
--   Armor spike   — computed from class + level + what is equipped (TBCArmor)
--   Talent spike  — computed from points in your deepest tree (30 -> 31-point
--                   talent, 40 -> 41-point talent)
--   Stat spike    — computed by the cap engine and the resilience readout
--   Weapon spike  — REFERENCE only; "slow versus fast" is a playstyle claim,
--                   not a number the client reports
--
-- The talent thresholds are structural, not opinion: in TBC a tree's tier N
-- requires 5*(N-1) points in that tree, so the tier 7 talent needs 30 points
-- spent and the tier 9 talent needs 40.

TA.Data.TALENT_SPIKE_31 = 30   -- points in tree required to reach the 31-point talent
TA.Data.TALENT_SPIKE_41 = 40   -- points in tree required to reach the 41-point talent

--- The signature talent each class gains at its deep thresholds. Reference text:
--- keyed by class, NOT by tree, because tree names are localized and this is
--- only ever shown as "what you are working toward".
-- FIXME: the WARRIOR line below misattributes Blood Frenzy to the Fury 41-point
-- tier alongside Rampage. Blood Frenzy (bleed targets take +4% physical damage)
-- is an Arms-tree talent sitting well below the 41-point capstone, not a second
-- Fury talent at that threshold — Rampage is Fury's sole 41-point talent. The
-- value is left as-is per this pass's no-data-changes scope; a future data fix
-- should either drop "and Blood Frenzy" or move it into a separate Arms clause.
TA.Data.ClassSpikes = {
    WARRIOR = "Mortal Strike (Arms) or Bloodthirst (Fury) at 31; Rampage and Blood Frenzy at 41.",
    PALADIN = "Repentance and Crusader Strike shape Retribution; Holy Shock defines Holy.",
    HUNTER  = "Bestial Wrath at 31 Beast Mastery, then The Beast Within at 41 — the largest "
           .. "single PvP jump any hunter gets.",
    SHAMAN  = "Dual Wield and Stormstrike in Enhancement; the dual-wield unlock changes the "
           .. "spec's whole rhythm.",
    ROGUE   = "Cold Blood (Assassination) and Preparation (Subtlety) at 31 — both are burst "
           .. "or reset cooldowns rather than passives.",
    MAGE    = "Ice Barrier in Frost, then Summon Water Elemental at 41.",
    WARLOCK = "Soul Link at 31 Demonology; Unstable Affliction at 41 Affliction.",
    PRIEST  = "Vampiric Touch at 41 Shadow; Pain Suppression at 41 Discipline.",
    DRUID   = "Moonkin Form at 31 Balance; Mangle at 41 Feral; Lifebloom at 41 Restoration.",
}

TA.Data.WeaponSpikeNotes = {
    "Slow two-handers turn crit into a kill window — Mortal Strike, Seal of Command "
        .. "and Windfury all scale with weapon damage per swing.",
    "Fast one-handers turn haste and hit into pressure: poison uptime, proc frequency "
        .. "and interrupt availability all rise with swing count.",
    "Dual wielding adds 19% white-swing miss that hit rating cannot remove, so it "
        .. "trades burst reliability for pressure. Gear to the special-attack cap.",
    "Caster weapons are pure stat sticks — spell power is the burst, and weapon speed "
        .. "is irrelevant except for wanding.",
}

TA.Data.TrinketSpikeNotes = {
    "A PvP trinket that breaks crowd control is not optional. Two minutes of cooldown "
        .. "is the difference between one full chain and two.",
    "On-use burst trinkets decide when your kill window is, which means they decide "
        .. "your whole opener. Line them up with your talent cooldowns, not separately.",
    "Trinkets are the only slots whose value this addon cannot score — their power is "
        .. "in an effect, not a stat. The Gear tab marks them 'not ranked' rather than "
        .. "pretending otherwise.",
}

-- ─── PRIORITIES BY ROLE (REFERENCE) ──────────────────────────────────────────

TA.Data.PvPPriorities = {
    MELEE = {
        "Resilience and Stamina first — you cannot deal damage while dead, and "
            .. "melee eats the most incoming burst.",
        "Hit only to 5%: an enemy player is your level, so the 9% raid figure is "
            .. "four percent of wasted budget.",
        "Expertise is far weaker than in PvE — players dodge less than bosses and "
            .. "you are rarely behind them anyway.",
    },
    RANGED = {
        "Resilience and Stamina first; you are the kill target in most comps.",
        "Hit to 5% against players, not 9%.",
        "Survivability beats raw ranged attack power — a hunter who lives to fire "
            .. "twice outdamages one who does not.",
    },
    CASTER = {
        "Resilience and Stamina before spell power. Every arena game is decided by "
            .. "whether you survive the opener.",
        "Spell hit to 3% against players, not 16%. This is the single largest "
            .. "PvE-to-PvP budget shift in the game.",
        "Stamina is disproportionately good — most burst is tuned to kill a "
            .. "clothie through a global.",
    },
    HEALER = {
        "Resilience, Stamina, then throughput. You are the primary target in "
            .. "essentially every arena game.",
        "Spell hit is worth nothing — heals cannot miss.",
        "Mana matters less than in PvE: games end long before you go out of mana, "
            .. "so raw throughput and survivability beat Mp5.",
    },
    TANK = {
        "There is no tank role in arena. Set your spec's real PvP role with "
            .. "|cFFFFD100/ta role|r — this tab is showing you tank advice because "
            .. "you have a shield equipped.",
        "Defense and the uncrittable threshold do not apply to players: player "
            .. "crits are reduced by resilience, not by defense skill.",
    },
}
