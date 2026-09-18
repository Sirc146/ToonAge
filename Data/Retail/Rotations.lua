-- ToonAge/Data/Rotations.lua
-- Rotation priority data per spec (Midnight 12.0.5)
-- SpellIDs are Midnight build IDs — verify with GetSpellInfo() in-game

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Rotations = {}
local R = TA.Data.Rotations

-- Condition helpers for entries' `when` field. Data/RotationConditions.lua is
-- listed above this file in the TOC, so it is already populated by now.
local C = TA.Data.RotationConditions

-- ── Entry format ───────────────────────────────────────────────────────
-- Each entry: {
--   spellID   = number,        -- for icon, name, drag-to-bar
--   name      = string,        -- fallback display name
--   priority  = number,        -- 1=highest, nil=cooldown
--   isCD      = bool,          -- true = cooldown section
--   isMajorCD = bool,          -- true = major cooldown (defensive/lust)
--   why       = string,        -- one-line tooltip explanation
--   condition = string,        -- when to use (displayed as note)
--   unlockLv  = number,        -- level required (nil = always available)
--   talentReq = string,        -- talent name required (nil = baseline)
--   talentAlt = string,        -- alternative if talent NOT taken
--   tags      = {string,...},  -- "core","aoe","st","cd","defensive"
-- }

-- ── Preservation Evoker (specID 1468) ────────────────────────────────
-- Rewritten 2026-08-30 against Icy Veins' current 12.1 (Midnight S2) guides.
-- Two Hero Talent trees exist: Flameshaper (current recommended default —
-- higher healing/damage ceiling, an extra Dream Breath/Fire Breath charge,
-- Lifecinders shares Obsidian Scales) and Chronowarden (competitive
-- alternative — more Haste/burst, worse mana, less total output). Tips below
-- assume Flameshaper and call out the Chronowarden difference where it
-- changes what to press.
--
-- The single biggest mechanical fact driving priority order: Merithra's
-- Blessing (the Midnight Apex talent) transforms your next Reversion after
-- an Essence-spending ability procs it. Rank 2 makes that transformed
-- Reversion both heal AND reduce damage taken — which is why "keep Reversion
-- on as many players as possible" beats "keep Reversion parked on the tank."
-- Consuming Echo any other way (Verdant Embrace, Dream Breath, plain
-- Reversion) is a real healing loss in raid; Mythic+ has more leeway since
-- damage is spikier and less predictable.
R[1468] = {
    solo = {
        tip = "Solo at level 82: simpler loop — Living Flame for damage and self-healing. Dream Breath and Stasis unlock at higher levels.",
        priorities = {
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 1,
                why = "Damage on enemies, self-heal when below 60%. Your primary filler — direct healing was increased in 12.1.",
                tags = { "core" },
            },
            {
                spellID = 364343,
                name = "Echo",
                priority = 2,
                why = "Use before every Reversion — doubles the HoT via Echo, and gives Merithra's Blessing a target to consume.",
                tags = { "core" },
            },
            {
                spellID = 366155,
                name = "Reversion",
                priority = 3,
                why = "Primary HoT. Always pair with Echo. Keep rolling on yourself — watch for it transforming into Merithra's Blessing.",
                tags = { "core" },
            },
            {
                spellID = 355913,
                name = "Emerald Blossom",
                priority = 4,
                why = "On cooldown. Instant AoE heal — use below 70% health. No longer consumes active Echo, so it never interrupts a ramp; Twin Echoes additionally grants a bonus Echo application on cast.",
                condition = "On cooldown",
                tags = { "core" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 360995,
                name = "Verdant Embrace",
                priority = 5,
                why = "Strong burst heal — healing was increased in 12.1. 2 charges with Wings of Liberty; do not let them cap.",
                condition = "On cooldown, burst heal",
                tags = {},
            },
            {
                spellID = 363916,
                name = "Obsidian Scales",
                priority = 6,
                why = "Personal defensive — use before difficult pulls.",
                isCd = true,
                tags = { "defensive" },
            },
            {
                spellID = 373861,
                name = "Temporal Anomaly",
                priority = 7,
                why = "On cooldown — applies Echo baseline now (Resonating Sphere was removed in Midnight S1). Reaches nearby targets even solo.",
                condition = "On cooldown",
                tags = {},
            },
            {
                spellID = 355936,
                name = "Dream Breath",
                priority = nil,
                why = "Not yet unlocked. With Flameshaper this gets a 2nd charge and guarantees a Merithra's Blessing proc on cast.",
                unlockLv = 85,
                tags = {},
            },
            { spellID = 370537, name = "Stasis", priority = nil, why = "Not yet unlocked.", unlockLv = 90, tags = {} },
        },
    },
    aoe = {
        tip = "M+ (Flameshaper recommended): Echo-centric rotation built around Temporal Anomaly's baseline Echo spread, healing into it, then triggering Consume Flame with Verdant Embrace/Emerald Blossom. Chronowarden trades that ceiling for more Haste and Temporal Anomaly-focused shielding via Nozdormu Adept. More leeway here than raid on what consumes Echo — Verdant Embrace, Dream Breath, and Reversion are all fine.",
        chain = {
            { spellID = 364343, name = "Echo" },
            { spellID = 366155, name = "Reversion" },
            { spellID = 373861, name = "Temporal Anomaly" },
            { spellID = 355913, name = "Emerald Blossom" },
            { spellID = 364343, name = "Echo" },
            { spellID = 366155, name = "Reversion" },
        },
        priorities = {
            {
                spellID = 364343,
                name = "Echo → Reversion",
                priority = 1,
                why = "Core combo — Echo a player, immediately Reversion them for doubled HoT. In Mythic+ any of Verdant Embrace/Dream Breath/Reversion is a fine Echo consumer, unlike raid.",
                tags = { "core" },
            },
            {
                spellID = 373861,
                name = "Temporal Anomaly",
                priority = 2,
                why = "On cooldown — applies Echo to 4 players baseline. If you've taken Temporal Barrier instead, this button is replaced by a 4-player shield at 30% Echo effectiveness.",
                condition = "On cooldown",
                tags = { "core", "cd" },
            },
            {
                spellID = 355913,
                name = "Emerald Blossom",
                priority = 3,
                why = "On cooldown when 2+ players injured. No longer consumes active Echo, so cast it freely without breaking a ramp; Twin Echoes grants a bonus Echo on cast. Also triggers Consume Flame (Flameshaper) on Dream Breath targets.",
                condition = "2+ injured allies",
                tags = { "core" },
            },
            {
                spellID = 360995,
                name = "Verdant Embrace",
                priority = 4,
                why = "Strong targeted heal, increased in 12.1. Do not cap charges. Also triggers Consume Flame (Flameshaper).",
                condition = "On cooldown",
                tags = {},
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 5,
                why = "Filler — generates Essence Burst via Spark of Insight. Direct healing increased in 12.1.",
                tags = {},
            },
            {
                spellID = 355936,
                name = "Dream Breath (Empower 3)",
                priority = nil,
                isCd = true,
                why = "PRIMARY AoE heal — unlocks at level 85. Empower to rank 3. Periodic healing was increased in 12.1 (upfront reduced) and guarantees a Merithra's Blessing proc. Flameshaper gets a 2nd charge.",
                unlockLv = 85,
                tags = { "core", "cd" },
            },
            {
                spellID = 370553,
                name = "Tip the Scales → Dream Breath",
                priority = nil,
                isCd = true,
                why = "Instant full empower — use on burst damage. Unlocks at 85. Chronowarden-flavored (that tree builds around Tip the Scales/Temporal Burst); still usable either way.",
                unlockLv = 85,
                tags = { "cd" },
            },
            {
                spellID = 363534,
                name = "Rewind",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Strongest healing cooldown in the game — no theoretical cap, scales with damage taken. Use on incoming AoE burst, not preemptively.",
                tags = { "major-cd" },
            },
            {
                spellID = 370537,
                name = "Stasis",
                priority = nil,
                isCd = true,
                why = "Stores your next 3 healing spells, recast on the same targets on release. Order matters — end with Temporal Anomaly rather than opening with it, or its free Echoes get consumed immediately by the next stored spell instead of your live rotation. M+ burst combo: Dream Breath, Temporal Anomaly, Verdant Embrace. Damage spells and major CDs (Rewind) cannot be stored. Unlocks at 90.",
                unlockLv = 90,
                tags = { "cd" },
            },
            {
                spellID = 359816,
                name = "Dream Flight",
                priority = nil,
                isCd = true,
                why = "Shares a choice node with Stasis — usually the weaker pick, but simpler: big upfront heal while flying over players, plus a HoT on everyone hit. Fine if you'd rather skip Stasis's setup.",
                tags = { "cd" },
            },
            {
                spellID = 374227,
                name = "Zephyr",
                priority = nil,
                isCd = true,
                why = "You + 4 closest allies take 20% less AoE damage for 8 sec (also +30% movement speed). Easier to land value in M+ (small group) than raid.",
                tags = { "defensive" },
            },
        },
    },
    st = {
        tip = "Raid (Flameshaper recommended): Flameshaper's 2nd Dream Breath charge means more reliable Merithra's Blessing procs, plus Lifecinders shares Obsidian Scales with allies for extra external defensives. Chronowarden remains competitive but with tighter mana and lower total output. Either tree: consume Echo via Merithra's Blessing, not plain Reversion — that's where the actual healing is, and Rank 2 rewards spreading Reversion across the raid rather than parking it on the tank.",
        priorities = {
            {
                spellID = 364343,
                name = "Echo, consumed via Merithra's Blessing",
                priority = 1,
                why = "Apply Echo, then let your next Reversion transform into Merithra's Blessing to consume it — your strongest single-target heal, and with Rank 2 also a damage-reduction effect. Consuming Echo any other way in raid is a real healing loss.",
                tags = { "core" },
            },
            {
                spellID = 366155,
                name = "Reversion — spread across the raid",
                priority = 2,
                why = "Merithra's Blessing Rank 2 rewards having Reversion on as many players as possible, as often as possible — not just the tank. Prioritize letting casts land as Merithra's Blessing when it's up.",
                tags = { "core" },
            },
            {
                spellID = 373861,
                name = "Temporal Anomaly",
                priority = 3,
                why = "On cooldown — applies Echo baseline now (Resonating Sphere was removed in Midnight S1). If you've taken Temporal Barrier instead, that talent replaces this button and shields 4 players (30% Echo effectiveness) rather than pure Echo spread.",
                condition = "On cooldown",
                tags = { "core", "cd" },
            },
            {
                spellID = 360995,
                name = "Verdant Embrace",
                priority = 4,
                why = "Cast on tank or injured target for a strong direct heal, increased in 12.1. Lifebind (sharing healing with the target) is no longer baseline on this — only if you've talented it; Dream Breath was buffed to help cover the gap when you haven't. Also triggers Consume Flame (Flameshaper) on Dream Breath targets.",
                tags = {},
            },
            {
                spellID = 355913,
                name = "Emerald Blossom",
                priority = 5,
                why = "On cooldown targeting most clustered injured players. No longer consumes active Echo — safe to weave in without breaking a Merithra's Blessing ramp. Also triggers Consume Flame (Flameshaper).",
                condition = "Clustered injured players",
                tags = {},
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 6,
                why = "Filler targeting most injured player. Direct healing increased in 12.1. Reserve as an Echo consumer for truly desperate single-target moments only — never in raid.",
                tags = {},
            },
            {
                spellID = 355936,
                name = "Dream Breath (Empower 3)",
                priority = nil,
                isCd = true,
                why = "Primary raid CD — unlocks at 85. Empower rank 3 on stacked players. Guarantees a Merithra's Blessing proc on cast; Flameshaper gives this a 2nd charge for more reliable procs.",
                unlockLv = 85,
                tags = { "core", "cd" },
            },
            {
                spellID = 363534,
                name = "Rewind",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Strongest healing cooldown in the game — heals based on damage taken over the last 5 sec, no theoretical cap. Don't hold it too long waiting for the 'perfect' moment — use it as soon as the raid is falling behind, not just in the most extreme cases.",
                tags = { "major-cd" },
            },
            {
                spellID = 370537,
                name = "Stasis",
                priority = nil,
                isCd = true,
                why = "Stores your next 3 healing spells, recast on the same targets on release. Order matters — end with Temporal Anomaly rather than opening with it. Common raid combo (Flameshaper): Dream Breath x2, Temporal Anomaly. Rewind and damage spells cannot be stored. Unlocks at 90.",
                unlockLv = 90,
                tags = { "cd" },
            },
            {
                spellID = 357170,
                name = "Time Dilation",
                priority = nil,
                isCd = true,
                why = "Cast on an ally to stagger a percentage of their incoming damage over time instead of all at once. Flameshaper's Lifecinders additionally lets you place Obsidian Scales on an ally — combined, gives Flameshaper a real external-defensive niche.",
                tags = { "defensive" },
            },
            {
                spellID = 374227,
                name = "Zephyr",
                priority = nil,
                isCd = true,
                why = "You + 4 closest allies take 20% less AoE damage for 8 sec (also +30% movement speed). Harder to land full value in raid (only 4 allies covered) than M+ — use ahead of a known AoE hit, not damage in general.",
                tags = { "defensive" },
            },
        },
    },
}

-- ── Devastation Evoker (specID 1467) ──────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins, Wowhead, and Method's 12.1
-- (Midnight S2) Devastation guides.
--
-- Hero Talents: Flameshaper (shared with Preservation) and Scalecommander
-- (shared with Augmentation) -- Devastation cannot take Chronowarden.
-- Scalecommander is the default pick for BOTH raid single-target and M+/
-- cleave this tier: Bombardments adds a second, cheaper Deep Breath and
-- Imminent Destruction converts spent Essence into stacking Deep Breath
-- damage, giving Deep Breath a real single-target slot instead of being a
-- pure mobility/AoE button.
--
-- Corrected 2026-09-06: the previous version of this block cited a
-- Flameshaper spender named "Engulf" as competitive/ahead on raid single
-- target. That ability was removed from the game in patch 12.0.0 (confirmed
-- via Warcraft Wiki, which explicitly flags it as removed) -- Flameshaper's
-- actual current capstone is Consume Flame, a PASSIVE that triggers when
-- Disintegrate or Pyre is cast while Fire Breath's DoT is still ticking:
-- Disintegrate consumes 2s of that DoT to detonate it for 150% AoE damage,
-- Pyre consumes 10s for the same. There is no separate button to press for
-- it -- it just makes Disintegrate/Pyre hit harder when Fire Breath is up,
-- and per Method.gg's current guide it makes Flameshaper "incredible in
-- AoE" rather than a single-target winner. Method.gg states Scalecommander
-- "outperforms Flameshaper in almost all types of damage profiles" as of
-- this pass, so Flameshaper is no longer called out as raid-ST-competitive
-- here. The dead "Engulf" priority entries were removed rather than given a
-- placeholder spellID, since recommending a cast of a spell that no longer
-- exists is worse than recommending nothing.
--
-- The single biggest mechanical fact driving cooldown priority is still
-- Animosity: every empowered spell cast (Fire Breath, Eternity Surge) while
-- Dragonrage is active extends its duration. That's why those buttons get
-- front-loaded the instant Dragonrage is up instead of being cast on their
-- own natural cooldown.
--
-- Season 2 tier set (Curse of Ula'tek) leans further into that loop by
-- adding extra Essence Burst procs off empowered casts -- keep Living
-- Flame/Disintegrate ready to spend them immediately rather than letting
-- them queue. Exact 2pc/4pc numbers weren't re-verified from a live tooltip
-- this pass -- check Icy Veins' gear page or the in-game tooltip before
-- trusting a specific percentage.
R[1467] = {
    solo = {
        tip = "Devastation solo (Scalecommander recommended -- extra Deep Breath damage and mobility edge out Flameshaper outside of pure single-target): weave Deep Breath in for real damage now, Fire Breath and Eternity Surge on cooldown, spend Essence via Disintegrate, fill with Living Flame/Azure Strike.",
        priorities = {
            {
                spellID = 357210,
                name = "Deep Breath",
                priority = 1,
                why = "On cooldown -- real single-target damage now via Scalecommander's Imminent Destruction stacks, not just a mobility tool. Cancel the flight early if there's nothing left to hit.",
                isCd = true,
                tags = { "core", "cd" },
            },
            {
                spellID = 357208,
                name = "Fire Breath (Empower 1)",
                priority = 2,
                why = "Rank 1 is the efficient single-target Empower -- cast on cooldown. Crits build Iridescence stacks; Causality (Flameshaper) shaves time off the recharge.",
                tags = { "core" },
            },
            {
                spellID = 359073,
                name = "Eternity Surge (Empower 1)",
                priority = 3,
                why = "Rank 1 for single target -- cast on cooldown, front-load it the instant Dragonrage is up since Animosity extends the duration per empowered cast.",
                tags = { "core" },
            },
            {
                spellID = 356995,
                name = "Disintegrate",
                priority = 4,
                why = "Main Essence spender -- channel fully, don't clip early. With Flameshaper, cast it while Fire Breath's DoT is ticking to trigger Consume Flame (150% AoE detonation of 2s of the DoT) -- see block comment.",
                tags = { "core" },
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 5,
                why = "Filler and Essence Burst generator -- cast on Burnout procs. Crits also build Iridescence.",
                tags = {},
            },
            {
                spellID = 362969,
                name = "Azure Strike",
                priority = 6,
                why = "Lowest-priority filler when nothing else is ready.",
                tags = {},
            },
            {
                spellID = 374348,
                name = "Renewing Blaze",
                priority = nil,
                isCd = true,
                why = "Personal defensive -- heals you over time for a share of the damage it prevents. Use before a hard-hitting scripted ability.",
                tags = { "defensive" },
            },
            {
                spellID = 375087,
                name = "Dragonrage",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major DPS cooldown -- align with Bloodlust. All Empowers become instant inside it, and every empowered cast extends it via Animosity -- front-load them rather than casting on natural cooldown.",
                tags = { "major-cd" },
            },
        },
    },
    aoe = {
        tip = "Devastation AoE, 3+ targets (Scalecommander): Deep Breath once enemies are grouped, Eternity Surge ranked to match target count, Shattering Star on cooldown, swap Disintegrate to Pyre at 3+ targets (Mass Disintegrate/Scalecommander pushes that swap out to roughly 5, since Disintegrate itself starts cleaving).",
        priorities = {
            {
                spellID = 357210,
                name = "Deep Breath",
                priority = 1,
                why = "Use once enemies are grouped -- hits everything in its flight path and builds Imminent Destruction stacks (Scalecommander).",
                isCd = true,
                tags = { "core", "cd" },
            },
            {
                spellID = 357208,
                name = "Fire Breath (Empower 3)",
                priority = 2,
                why = "Empower to rank 3 for AoE -- spreads the DoT to the whole cone.",
                tags = { "core" },
            },
            {
                spellID = 359073,
                name = "Eternity Surge",
                priority = 3,
                why = "Empower level should roughly match target count -- 2/4/6 targets per rank.",
                tags = { "core" },
            },
            {
                spellID = 357211,
                name = "Pyre",
                priority = 5,
                why = "Switch to this at 3+ targets -- it outdamages Disintegrate from that count up. Benefits from Charged Blast and refunds Essence on crit.",
                tags = { "core" },
                when = C.AoE(3),
            },
            {
                spellID = 356995,
                name = "Disintegrate",
                priority = 6,
                why = "Use below the Pyre swap point. With Mass Disintegrate (Scalecommander) it cleaves nearby enemies itself, so it stays competitive out to a wider target count than baseline.",
                tags = {},
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 7,
                why = "Filler on Burnout procs.",
                tags = {},
            },
            {
                spellID = 375087,
                name = "Dragonrage",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Use on the largest pull -- spam Empowers inside it; each one extends it further via Animosity.",
                tags = { "major-cd" },
            },
            { spellID = 370553, name = "Tip the Scales", priority = nil, isCd = true, why = "Instant max-rank empower — pair with Fire Breath/Eternity Surge in Dragonrage.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Devastation raid single target (Scalecommander is the current recommendation -- Method.gg's 12.1 guide has it outperforming Flameshaper in almost all damage profiles, not just AoE): Deep Breath and both Empowers on cooldown, Shattering Star before your burst, Disintegrate as the Essence dump.",
        priorities = {
            {
                spellID = 357210,
                name = "Deep Breath",
                priority = 1,
                why = "On cooldown -- real single-target damage now, not just a mobility tool.",
                isCd = true,
                tags = { "core", "cd" },
            },
            {
                spellID = 357208,
                name = "Fire Breath (Empower 1)",
                priority = 2,
                why = "Rank 1 is the efficient single-target Empower -- cast on cooldown. Builds Iridescence on crit.",
                tags = { "core" },
            },
            {
                spellID = 359073,
                name = "Eternity Surge (Empower 1)",
                priority = 3,
                why = "Rank 1 for single target -- cast on cooldown, priority inside Dragonrage since Animosity extends it per empowered cast.",
                tags = { "core" },
            },
            {
                spellID = 356995,
                name = "Disintegrate",
                priority = 5,
                why = "Main Essence spender -- do not clip the channel early. With Flameshaper, time it while Fire Breath's DoT is up to trigger Consume Flame's bonus detonation.",
                tags = { "core" },
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 6,
                why = "Filler and Essence Burst generator. Season 2 tier's bonus Essence Burst procs make it worth spending promptly rather than banking.",
                tags = {},
            },
            {
                spellID = 374348,
                name = "Renewing Blaze",
                priority = nil,
                isCd = true,
                why = "Personal defensive -- heals over time for a share of damage prevented. Use ahead of a known raid-damage spike.",
                tags = { "defensive" },
            },
            {
                spellID = 375087,
                name = "Dragonrage",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major DPS CD -- on cooldown, stack with Bloodlust when available. Front-load Empowers to extend it via Animosity.",
                tags = { "major-cd" },
            },
            { spellID = 370553, name = "Tip the Scales", priority = nil, isCd = true, why = "Instant max-rank empower — pair with Fire Breath/Eternity Surge in Dragonrage.", tags = { "cd" } },
        },
    },
}

-- ── Augmentation Evoker (specID 1473) ─────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins, Wowhead, and Method's 12.1
-- (Midnight S2) Augmentation guides.
--
-- Hero Talents: Chronowarden (shared with Preservation) and Scalecommander
-- (shared with Devastation) -- Augmentation cannot take Flameshaper, which
-- only pairs with Devastation/Preservation. Chronowarden remains the
-- default for raid: its capstone, Time Skip, rewinds a few recent seconds
-- on demand -- effectively a partial cooldown reset you can line up with a
-- boss's burst phase -- and Motes of Possibility grants Mastery-scaling
-- procs that reward the stat priority raid Augmentation already wants.
-- Scalecommander is the M+/cleave pick: Menacing Presence debuffs a target
-- to take more damage from you and your buffed allies alike, which fits
-- Augmentation's amplify-everyone identity, and Bombardments/Maneuverability
-- make Deep Breath a stronger, more frequent button on 2+ targets.
--
-- The single biggest mechanical fact driving priority order is still Ebon
-- Might uptime feeding Interwoven Threads: every Prescience application and
-- point of damage dealt during Ebon Might chips time off Ebon Might's and
-- Breath of Eons's cooldowns, so 100% Prescience/Ebon Might uptime is worth
-- more than any amount of personal Eruption damage. Fate Mirror layers on
-- top -- your Prescience'd allies' crits have a chance to grant you Essence
-- Burst, so keep Eruption ready to spend those procs immediately.
--
-- Season 2 tier set (Curse of Ula'tek) adds more of the same: extra Essence
-- Burst procs off Upheaval, making it worth casting on cooldown even when
-- Ebon Might doesn't strictly need the Sands of Time extension yet. Exact
-- 2pc/4pc numbers weren't re-verified from a live tooltip this pass -- check
-- Icy Veins' gear page or the in-game tooltip before trusting a specific
-- percentage.
R[1473] = {
    solo = {
        tip = "Augmentation solo (Chronowarden favored for single-target this tier; Scalecommander still fine for 2-target cleave/M+ via Menacing Presence): keep Ebon Might active at all times -- it is your most important button. Prescience yourself between casts. Fill with Upheaval and Eruption.",
        priorities = {
            {
                spellID = 395152,
                name = "Ebon Might",
                priority = 1,
                why = "Core buff -- empowers you (and allies in a group). Never let it drop; each refresh also feeds Interwoven Threads' cooldown reduction on itself and Breath of Eons.",
                isCd = true,
                tags = { "core" },
                when = C.BuffRefresh(395296, 3),
            },
            {
                spellID = 409311,
                name = "Prescience",
                priority = 2,
                why = "Apply to yourself for the Fate Mirror proc chance. 2 charges -- don't let them cap.",
                tags = { "core" },
            },
            {
                spellID = 396286,
                name = "Upheaval",
                priority = 3,
                why = "On cooldown -- strong personal damage, and extends Ebon Might via Sands of Time. Season 2 tier adds bonus Essence Burst procs off this cast.",
                isCd = true,
                tags = { "core", "cd" },
            },
            {
                spellID = 395160,
                name = "Eruption",
                priority = 4,
                why = "Primary filler -- damage scales with your active empowerment stacks. Spend Essence Burst procs (from Fate Mirror or Upheaval) immediately rather than banking them.",
                tags = { "core" },
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 5,
                why = "Filler between Eruption casts. Generates Essence Burst.",
                tags = { "active" },
            },
            {
                spellID = 357210,
                name = "Deep Breath",
                priority = 6,
                why = "On cooldown -- solid personal damage and mobility. Bombardments/Maneuverability (Scalecommander) make this hit harder and recharge faster.",
                isCd = true,
                tags = { "cd" },
            },
            {
                spellID = 363916,
                name = "Obsidian Scales",
                priority = nil,
                isCd = true,
                why = "Baseline personal defensive -- 30% damage reduction. Use before a scripted hard-hitting mechanic.",
                tags = { "defensive" },
            },
            {
                spellID = 403631,
                name = "Breath of Eons",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major cooldown -- align with your own burst windows solo. Chronowarden's Time Skip can partially refresh this on a tight timeline.",
                tags = { "major-cd" },
            },
            { spellID = 357208, name = "Fire Breath", priority = 7, why = "Empower on cooldown — the 30-sec cycle is built around it and Upheaval.", tags = { "core" } },
            { spellID = 362969, name = "Azure Strike", priority = 8, why = "Filler when moving or out of Essence.", tags = { "active" } },
        },
    },
    aoe = {
        tip = "Augmentation M+ (Scalecommander for 2-target cleave via Menacing Presence, Chronowarden also fine): your job is buff uptime, not personal damage. Ebon Might on all 4 allies. Prescience the two highest DPS. Eruption for Essence Burst windows. Position centrally.",
        chain = {
            { spellID = 395152, name = "Ebon Might" },
            { spellID = 409311, name = "Prescience" },
            { spellID = 409311, name = "Prescience" },
            { spellID = 396286, name = "Upheaval" },
            { spellID = 395160, name = "Eruption" },
            { spellID = 361469, name = "Living Flame" },
        },
        priorities = {
            {
                spellID = 395152,
                name = "Ebon Might",
                priority = 1,
                why = "Must be 100% uptime on all 4 allies. Refresh 1-2s before expiry -- never let it drop in combat. Every refresh feeds Interwoven Threads' cooldown reduction.",
                tags = { "core" },
                when = C.BuffRefresh(395296, 3),
            },
            {
                spellID = 409311,
                name = "Prescience",
                priority = 2,
                why = "Cast on the two highest DPS before every major pull. 2 charges -- always have one ready. Fate Mirror turns their crits into Essence Burst for you.",
                tags = { "core" },
            },
            {
                spellID = 395160,
                name = "Eruption",
                priority = 3,
                why = "Your primary damage contribution -- empowers allies via Fate Mirror. Use Essence Burst procs immediately.",
                tags = { "core" },
            },
            {
                spellID = 396286,
                name = "Upheaval",
                priority = 4,
                why = "On cooldown -- strong group empowerment, extends Ebon Might, and Season 2 tier adds bonus Essence Burst procs off it.",
                isCd = true,
                tags = { "core", "cd" },
            },
            {
                spellID = 357210,
                name = "Deep Breath",
                priority = 5,
                why = "On cooldown once enemies are grouped -- real AoE damage now. Bombardments (Scalecommander) adds a second, cheaper cast.",
                isCd = true,
                tags = { "cd" },
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 6,
                why = "Filler. Generates Essence Burst for Eruption.",
                tags = { "active" },
            },
            {
                spellID = 403631,
                name = "Breath of Eons",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Use on large pack pulls or boss burn phase. Coordinate with tank to ensure enemies are grouped.",
                tags = { "major-cd" },
            },
            { spellID = 357208, name = "Fire Breath", priority = 7, why = "Empower on cooldown — the 30-sec cycle is built around it and Upheaval.", tags = { "core" } },
            { spellID = 362969, name = "Azure Strike", priority = 8, why = "Filler when moving or out of Essence.", tags = { "active" } },
            { spellID = 360827, name = "Blistering Scales", priority = 9, why = "Keep on the tank.", tags = { "active" } },
            { spellID = 404977, name = "Time Skip", priority = nil, isCd = true, isMajorCd = true, why = "Cooldown reset — use after Breath of Eons/empowers are spent.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Augmentation raid (Chronowarden favored this tier -- Motes of Possibility's Mastery-scaling procs and Time Skip's cooldown flexibility edge out Scalecommander on single target): pure support role. Your personal DPS is low -- your value is in how much damage you add to your buffed allies. Communicate Breath of Eons timing with raid leader.",
        priorities = {
            {
                spellID = 395152,
                name = "Ebon Might",
                priority = 1,
                why = "100% uptime is mandatory. Late refreshes cost your raid more damage than any personal mistake, and each refresh feeds Interwoven Threads' CDR loop on itself and Breath of Eons.",
                tags = { "core" },
                when = C.BuffRefresh(395296, 3),
            },
            {
                spellID = 409311,
                name = "Prescience",
                priority = 2,
                why = "Maintain on the two highest-damage allies. Track their buff durations. 2 charges. Fate Mirror converts their crits into Essence Burst for you.",
                tags = { "core" },
            },
            {
                spellID = 395160,
                name = "Eruption",
                priority = 3,
                why = "ST filler with Fate Mirror value -- cast immediately on Essence Burst procs rather than banking them.",
                tags = { "core" },
            },
            {
                spellID = 396286,
                name = "Upheaval",
                priority = 4,
                why = "On cooldown -- aligns well with Bloodlust burst windows, extends Ebon Might, and generates bonus Essence Burst via the Season 2 tier set.",
                isCd = true,
                tags = { "cd" },
            },
            {
                spellID = 361469,
                name = "Living Flame",
                priority = 5,
                why = "Filler. Aim at most injured ally if healing is needed.",
                tags = { "active" },
            },
            {
                spellID = 363916,
                name = "Obsidian Scales",
                priority = nil,
                isCd = true,
                why = "Baseline personal defensive -- 30% damage reduction. Use before a scripted mechanic hits you.",
                tags = { "defensive" },
            },
            {
                spellID = 403631,
                name = "Breath of Eons",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Coordinate with raid leader -- use when cooldowns and Bloodlust align for maximum amplification. Chronowarden's Time Skip gives some flexibility to re-align it if a pull goes long.",
                tags = { "major-cd" },
            },
            { spellID = 357208, name = "Fire Breath", priority = 6, why = "Empower on cooldown — the 30-sec cycle is built around it and Upheaval.", tags = { "core" } },
            { spellID = 362969, name = "Azure Strike", priority = 7, why = "Filler when moving or out of Essence.", tags = { "active" } },
            { spellID = 360827, name = "Blistering Scales", priority = 8, why = "Keep on the tank.", tags = { "active" } },
            { spellID = 404977, name = "Time Skip", priority = nil, isCd = true, isMajorCd = true, why = "Cooldown reset — use after Breath of Eons/empowers are spent.", tags = { "cd" } },
        },
    },
}

-- ── Survival Hunter (specID 255) ──────────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek: The Venomous Abyss). Sources cross-checked: Icy Veins Survival
-- Hunter DPS rotation guide (12.1) and Icy Veins Survival DPS guide (12.1).
-- Hero talent: Sentinel is now the generally recommended pick for both raid
--   and M+ — Sentinel's Mark procs cut Wildfire Bomb's cooldown and its
--   capstone converts the Takedown follow-up into Moonlight Chakram for
--   sustained AoE pressure. Pack Leader (beast summons + Stampede lines)
--   remains a fully competitive alternative, especially for cleave-heavy M+.
-- Apex Talent: Raptor Swipe — every 2nd Raptor Strike auto-upgrades into an
--   AoE hit that also deals noticeably more single-target damage, so
--   Raptor Strike/Swipe below is one generator slot that alternates itself.
-- Tier set (Venomous Abyss): 2pc — Mongoose Fury (from Wildfire Bomb) deals
--   10% more damage; 4pc — Boomstick extends Mongoose Fury by 1s and boosts
--   its effect by another 10%. Folded into the Wildfire Bomb / Boomstick
--   `why` text below; it does not reorder priority — both are already used
--   on cooldown.
-- SpellIDs: core kit confirmed via combat log/tooltip. Takedown, Boomstick,
--   and Moonlight Chakram are new Midnight abilities without a stable
--   spellID yet — left nil, verify with GetSpellInfo() in-game.
R[255] = {
    solo = {
        tip = "Survival solo (Sentinel favored — Sentinel's Mark procs cut Wildfire Bomb cooldown, pulling ahead of Pack Leader): Misdirect to your pet before pulling. Wildfire Bomb into packs, Harpoon gap-closes. Ferocity pet provides Primal Rage (Bloodlust) and passive leech healing.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% damage to target — apply before every pull, always maintain.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 1250646,
                name = "Takedown",
                priority = 2,
                why = "Primary cooldown — charges to target, grants +20% damage for 8s. Open every pull.",
                tags = { "core", "cd" },
                isCd = true,
            },
            {
                spellID = 259495,
                name = "Wildfire Bomb",
                priority = 3,
                why = "Highest damage ability — use empowered by Tip of the Spear. Triggers Mongoose Fury (tier 2pc: +10% damage).",
                tags = { "core" },
            },
            {
                spellID = 259489,
                name = "Kill Command",
                priority = 4,
                why = "Primary spender — send pet, empowered by Tip of the Spear stacks.",
                tags = { "core" },
            },
            {
                spellID = 186270,
                name = "Raptor Strike",
                priority = 5,
                why = "Primary generator — builds Tip of the Spear. Apex Talent Raptor Swipe auto-upgrades every 2nd cast into an AoE hit that also hits harder single-target.",
                tags = { "core" },
            },
            {
                spellID = 190925,
                name = "Harpoon",
                priority = 6,
                why = "Gap closer — resets on kill in Midnight. Chain pull packs efficiently.",
                tags = { "active" },
                -- Positioning tool, not damage. Suppress on a target about to die.
                when = C.TargetLives(4),
            },
            {
                spellID = 320976,
                name = "Kill Shot",
                priority = 7,
                why = "Execute under 20% HP. Pack Leader procs allow use at any HP in burst.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 187650,
                name = "Freezing Trap",
                priority = 8,
                why = "CC — freeze a mob 60s. Pull around it or use on dangerous adds.",
                tags = { "active" },
                -- CC is for live packs, never for something already dying.
                when = C.And(C.TargetLives(6), C.AoE(2)),
            },
        },
    },
    aoe = {
        tip = "Survival M+ (Sentinel favored — Wildfire Bomb synergy plus Moonlight Chakram as a ranged AoE nuke): Wildfire Bomb is your primary AoE — always Tip-empowered. Raptor Strike/Swipe generates stacks on all targets. Position Takedown's Stampede to hit the whole pack.",
        chain = {
            { spellID = 257284, name = "Hunter's Mark" },
            { spellID = 1250646, name = "Takedown" },
            { spellID = 259495, name = "Wildfire Bomb" },
            { spellID = 186270, name = "Raptor Strike" },
            { spellID = 259489, name = "Kill Command" },
            { spellID = 1264902, name = "Moonlight Chakram" },
            { spellID = 259495, name = "Wildfire Bomb" },
        },
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% flat damage — maintain on primary target at all times.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 1250646,
                name = "Takedown",
                priority = 2,
                why = "On cooldown — triggers Stampede! (Pack Leader) or empowers Moonlight Chakram (Sentinel). Position to hit all targets.",
                tags = { "core", "cd" },
                isCd = true,
            },
            {
                spellID = 259495,
                name = "Wildfire Bomb",
                priority = 3,
                why = "Primary AoE — always Tip-of-the-Spear empowered for max damage. Triggers Mongoose Fury (tier 2pc/4pc).",
                tags = { "core" },
            },
            {
                spellID = 186270,
                name = "Raptor Strike",
                priority = 4,
                why = "Generator — Apex Talent Raptor Swipe auto-upgrades every 2nd cast into an AoE hit. Builds Tip stacks.",
                tags = { "core" },
            },
            {
                spellID = 259489,
                name = "Kill Command",
                priority = 5,
                why = "Strong in AoE — pet cleaves via Beast Cleave. Use between bombs.",
                tags = { "core" },
            },
            {
                spellID = 1264902,
                name = "Moonlight Chakram",
                priority = 6,
                why = "Sentinel hero talent — ranged AoE nuke, use on cooldown for sustained cleave pressure.",
                tags = { "active" },
                talentReq = "Sentinel",
            },
            {
                spellID = 190925,
                name = "Harpoon",
                priority = 7,
                why = "Gap closer — resets on kill. Essential for chaining M+ pulls.",
                tags = { "active" },
            },
            {
                spellID = 187650,
                name = "Freezing Trap",
                priority = 8,
                why = "CC — freeze dangerous casters or priority adds.",
                tags = { "active" },
            },
            {
                spellID = 320976,
                name = "Kill Shot",
                priority = 9,
                why = "Execute under 20% — always priority on low-HP targets.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 1261193,
                name = "Boomstick",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Large cone AoE cooldown — position to hit entire pack. Strongest on 5+ target pulls. Tier 4pc: extends and strengthens Mongoose Fury on cast.",
                tags = { "major-cd" },
            },
            {
                spellID = 186265,
                name = "Aspect of the Turtle",
                priority = nil,
                isCd = true,
                why = "Full immunity + 30% DR. Use on dangerous mechanics or when about to die.",
                tags = { "defensive" },
            },
            {
                spellID = 264735,
                name = "Survival of the Fittest",
                priority = nil,
                isCd = true,
                why = "30% DR, 2 charges, 1.5min CD. Best personal defensive — use freely on damage spikes.",
                tags = { "defensive" },
            },
        },
    },
    st = {
        tip = "Survival Raid (Sentinel favored overall this tier): Focus Kill Command as primary ST spender. Raptor Strike/Swipe between every spender. Takedown on cooldown — align with Bloodlust. Boomstick as your major burst window alongside it.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% flat damage — apply pre-pull, maintain throughout the fight.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 1250646,
                name = "Takedown",
                priority = 2,
                why = "Major cooldown — on cooldown, align with Bloodlust when available.",
                tags = { "core", "cd" },
                isCd = true,
                isMajorCd = true,
            },
            {
                spellID = 259495,
                name = "Wildfire Bomb",
                priority = 3,
                why = "Strong ST damage — never hold >1 charge. Always Tip-empowered. Triggers Mongoose Fury (tier 2pc: +10% damage).",
                tags = { "core" },
            },
            {
                spellID = 259489,
                name = "Kill Command",
                priority = 4,
                why = "Primary ST spender — use when empowered by Tip of the Spear.",
                tags = { "core" },
            },
            {
                spellID = 186270,
                name = "Raptor Strike",
                priority = 5,
                why = "Generator — keeps Tip of the Spear rolling. Apex Talent Raptor Swipe upgrades every 2nd cast for bonus single-target damage. Fill every GCD.",
                tags = { "core" },
            },
            {
                spellID = 320976,
                name = "Kill Shot",
                priority = 6,
                why = "Execute under 20% — highest priority during execute phase.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 190925,
                name = "Harpoon",
                priority = 7,
                why = "If needed for positioning — does not break Tip stacks.",
                tags = { "active" },
                when = C.TargetLives(4),
            },
            {
                spellID = 1261193,
                name = "Boomstick",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major single-target burst cooldown — align with Takedown and Bloodlust. Tier 4pc extends/strengthens Mongoose Fury on cast.",
                tags = { "major-cd" },
            },
            {
                spellID = 186265,
                name = "Aspect of the Turtle",
                priority = nil,
                isCd = true,
                why = "Immunity — use when assigned to soak a mechanic or healer is overwhelmed.",
                tags = { "defensive" },
            },
            {
                spellID = 264735,
                name = "Survival of the Fittest",
                priority = nil,
                isCd = true,
                why = "Personal DR — 2 charges. Use on predictable raid damage spikes.",
                tags = { "defensive" },
            },
        },
    },
}

-- ── Beast Mastery Hunter (specID 253) ─────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek: The Venomous Abyss). Sources cross-checked: Icy Veins Beast
-- Mastery Hunter DPS rotation guide (12.1) and Method.gg Beast Mastery
-- Hunter playstyle/rotation guide (12.1).
-- Hero talent: Pack Leader remains the default for most content -- smoother
--   Focus via Howl of the Pack Leader empowering Kill Command; Dark Ranger
--   is a competitive M+/burst alternative via Wailing Arrow procs off
--   Bestial Wrath. Both trees are treated as equal-weight in the priority
--   below since neither adds a separate button to press.
-- Apex Talent: Nature's Ally -- Kill Command has a chance to grant Nature's
--   Ally, a buff that empowers your very next Kill Command. Chase it on
--   single target/light cleave; on 4+ targets it is fine to just fire Kill
--   Command on cooldown and let Nature's Ally procs go to waste.
-- Tier set (Venomous Abyss): 2pc -- Barbed Shot has a chance to trigger an
--   extra (50%-effectiveness) Stomp from your pet; 4pc -- each Stomp grants
--   a stack of Cobra Fang (max 4), and Cobra Shot deals bonus damage/crit at
--   max stacks. Folded into the Cobra Shot `why` text below -- hold Cobra
--   Shot slightly to spend it near 4 Cobra Fang stacks when it doesn't cost
--   a Kill Command cooldown.
R[253] = {
    solo = {
        tip = "BM solo (Pack Leader favored for raid -- smoother Focus regen via Howl of the Pack Leader; Dark Ranger for M+ burst via Wailing Arrow): Bestial Wrath is your rotational anchor, not just another cooldown -- the vast majority of your damage happens inside its window.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% damage — maintain at all times.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 217200,
                name = "Barbed Shot",
                priority = 2,
                why = "Maintain Frenzy stacks on pet. Time your last cast before Bestial Wrath comes off cooldown so you enter its window at full stacks. 2 charges. Tier 2pc: chance for an extra pet Stomp.",
                tags = { "core" },
            },
            {
                spellID = 19574,
                name = "Bestial Wrath",
                priority = 3,
                why = "On cooldown -- this is where most of your damage happens, not a side cooldown. Build the rest of the rotation around its timing.",
                tags = { "core", "cd" },
                isCd = true,
            },
            {
                spellID = 34026,
                name = "Kill Command",
                priority = 4,
                why = "Primary spender -- on cooldown always, especially inside Bestial Wrath. Prioritize it while Nature's Ally (Apex Talent) is active.",
                tags = { "core" },
            },
            {
                spellID = 193455,
                name = "Cobra Shot",
                priority = 5,
                why = "Filler -- generates Focus, reduces Kill Command CD by 1s. Extra damage/crit at 4 Cobra Fang stacks (tier 4pc, from pet Stomps).",
                tags = { "active" },
            },
            {
                spellID = 53351,
                name = "Kill Shot",
                priority = 6,
                why = "Execute under 20% HP -- always priority.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
        },
    },
    aoe = {
        tip = "BM AoE: Wild Thrash applies Beast Cleave to your pet, then maintain Barbed Shot and Kill Command as normal. Beast Cleave makes your pet hit all nearby enemies for 4 seconds. Tier set turns Barbed Shot's bonus pet Stomps and Cobra Shot's Cobra Fang stacks into extra passive AoE.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% damage on primary target.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 1264359,
                name = "Wild Thrash",
                priority = 2,
                why = "Applies Beast Cleave -- pet hits all nearby targets. Recast after Bestial Wrath or once Beast Cleave expires; hold on cooldown otherwise to line up with Bestial Wrath timing.",
                tags = { "core" },
            },
            {
                spellID = 217200,
                name = "Barbed Shot",
                priority = 3,
                why = "Maintain Frenzy -- 2 charges, use on reaching 2 charges so you don't waste one. Tier 2pc bonus Stomp hits all Beast Cleave targets.",
                tags = { "core" },
            },
            {
                spellID = 19574,
                name = "Bestial Wrath",
                priority = 4,
                why = "On cooldown -- use with Beast Cleave active for maximum AoE.",
                tags = { "core", "cd" },
                isCd = true,
            },
            {
                spellID = 34026,
                name = "Kill Command",
                priority = 5,
                why = "On cooldown -- spreads damage via Beast Cleave. Fine to ignore Nature's Ally stacking at 4+ targets.",
                tags = { "core" },
            },
            {
                spellID = 193455,
                name = "Cobra Shot",
                priority = 6,
                why = "Filler -- refreshes Beast Cleave duration. Extra value at 4 Cobra Fang stacks (tier 4pc).",
                tags = { "active" },
            },
            { spellID = 359844, name = "Call of the Wild", priority = nil, isCd = true, isMajorCd = true, why = "Major burst — line up with Bestial Wrath.", tags = { "cd" } },
            { spellID = 321530, name = "Bloodshed", priority = nil, isCd = true, why = "Pet bleed cooldown — use inside Bestial Wrath.", tags = { "cd" } },
            { spellID = 120679, name = "Dire Beast", priority = 7, why = "Extra beast + Focus on cooldown when talented.", tags = { "active" } },
        },
    },
    st = {
        tip = "BM Raid: same anchor as solo -- Bestial Wrath is the core of the rotation, not a side cooldown. Barbed Shot timed to enter its window at full Frenzy stacks, Kill Command on cooldown inside it, align with Bloodlust when possible.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% flat damage — maintain throughout the fight.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 217200,
                name = "Barbed Shot",
                priority = 2,
                why = "Frenzy maintenance -- never let stacks drop to 0. Time the last charge to land right before Bestial Wrath comes off cooldown. Tier 2pc: chance for a bonus pet Stomp.",
                tags = { "core" },
            },
            {
                spellID = 19574,
                name = "Bestial Wrath",
                priority = 3,
                why = "On cooldown, aligned with Bloodlust -- your rotational anchor, not a side cooldown. Most damage happens here.",
                tags = { "core", "cd" },
                isCd = true,
            },
            {
                spellID = 34026,
                name = "Kill Command",
                priority = 4,
                why = "Primary damage -- on cooldown always, especially inside Bestial Wrath. Prioritize while Nature's Ally is active.",
                tags = { "core" },
            },
            {
                spellID = 193455,
                name = "Cobra Shot",
                priority = 5,
                why = "Filler -- do not overcap Focus. Extra damage/crit at 4 Cobra Fang stacks (tier 4pc).",
                tags = { "active" },
            },
            {
                spellID = 53351,
                name = "Kill Shot",
                priority = 6,
                why = "Execute under 20%.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            { spellID = 359844, name = "Call of the Wild", priority = nil, isCd = true, isMajorCd = true, why = "Major burst — line up with Bestial Wrath.", tags = { "cd" } },
            { spellID = 321530, name = "Bloodshed", priority = nil, isCd = true, why = "Pet bleed cooldown — use inside Bestial Wrath.", tags = { "cd" } },
            { spellID = 120679, name = "Dire Beast", priority = 7, why = "Extra beast + Focus on cooldown when talented.", tags = { "active" } },
        },
    },
}

-- ── Marksmanship Hunter (specID 254) ──────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek: The Venomous Abyss). Sources cross-checked: Icy Veins Marksmanship
-- Hunter DPS rotation guide (12.1) and Wowhead "How to Play Marksmanship
-- Hunter in Midnight Season 2".
-- Hero talent: Dark Ranger remains favored for raid single-target (Trueshot
--   procs Wailing Arrow); Sentinel is the pick for AoE/cleave M+ (Trueshot
--   into Moonlight Chakram). Both trees share the button list below.
-- Apex Talent: Take Aim -- Rapid Fire cuts Aimed Shot's cooldown by 5s
--   (doubled to 10s vs 2+ targets with Aspect of the Hydra), and Spotter's
--   Mark increases the damage of your next Rapid Fire against that target
--   by 20%. This is why Rapid Fire is pushed onto cooldown aggressively
--   rather than held for Trueshot windows only.
-- Redesigned core kit: Explosive Shot replaces Steady Shot as the ranged
--   DoT filler/generator, and Steady Shot is now the true 0-cost filler for
--   movement or Focus droughts.
-- Tier set (Venomous Abyss) 4pc: Explosive Shot's DoT ticks each reduce
--   Aimed Shot and Rapid Fire's cooldowns by 0.5s -- spread Explosive Shot
--   across targets in AoE to maximize total ticks/CDR.
-- SpellIDs: Explosive Shot is a new Midnight ability without a confirmed
--   spellID yet -- left nil, verify with GetSpellInfo() in-game.
R[254] = {
    solo = {
        tip = "MM solo (Dark Ranger favored for raid via Trueshot->Wailing Arrow; Sentinel viable on cleave fights): cast Trueshot on cooldown, spam Aimed Shot with Precise Shots procs, Rapid Fire on cooldown for Take Aim's Aimed Shot CDR. Explosive Shot as a DoT generator, Steady Shot as true filler. Fully ranged — great for questing safety.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% damage — maintain at all times.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 19434,
                name = "Aimed Shot",
                priority = 2,
                why = "Primary nuke — cast with Precise Shots buff for reduced cast time. Apex Talent Take Aim shortens its cooldown every time you cast Rapid Fire.",
                tags = { "core" },
                -- Aimed Shot costs 35 Focus. Below that it is not castable, so
                -- suggesting it wastes a slot the filler should hold.
                when = C.PowerAtLeast(35),
            },
            {
                spellID = 257044,
                name = "Rapid Fire",
                priority = 3,
                why = "Channeled — very high DPS per GCD. On cooldown -- also cuts Aimed Shot's cooldown by 5s (Apex Talent Take Aim) and gains +20% damage from Spotter's Mark.",
                tags = { "core" },
            },
            {
                spellID = 212431,
                name = "Explosive Shot",
                priority = 4,
                why = "DoT generator — on cooldown. Ticks each shave 0.5s off Aimed Shot and Rapid Fire's cooldowns (tier 4pc).",
                tags = { "core" },
            },
            {
                spellID = 185358,
                name = "Arcane Shot",
                priority = 5,
                why = "Spends Precise Shots procs, generates Focus.",
                tags = { "active" },
                -- Filler: only worth a slot with Focus to spend. Keeps the bar
                -- from recommending a shot that will not fire.
                when = C.PowerAtLeast(40),
            },
            {
                spellID = 56641,
                name = "Steady Shot",
                priority = 6,
                why = "True 0-cost filler — press when nothing else is up or while moving.",
                tags = { "active" },
                when = C.PowerBelow(40),
            },
            {
                spellID = 288613,
                name = "Trueshot",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Primary CD — on cooldown. Aimed Shot and Rapid Fire both grant Precise Shots inside; Dark Ranger's Trueshot procs Wailing Arrow.",
                tags = { "major-cd" },
            },
            {
                spellID = 53351,
                name = "Kill Shot",
                priority = 7,
                why = "Execute under 20%.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
        },
    },
    aoe = {
        tip = "MM AoE (Sentinel favored on cleave -- Trueshot into Moonlight Chakram): Multi-Shot applies Trick Shots — Aimed Shot and Rapid Fire then ricochet to all nearby targets. Spread Explosive Shot across targets to maximize tier-set cooldown reduction. Volley for large packs.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% on primary target.",
                tags = { "core" },
            },
            {
                spellID = 257620,
                name = "Multi-Shot",
                priority = 2,
                why = "Apply Trick Shots — makes Aimed Shot and Rapid Fire ricochet to all targets. Also spends Precise Shots at 2+ targets.",
                tags = { "core" },
            },
            {
                spellID = 19434,
                name = "Aimed Shot",
                priority = 3,
                why = "Ricochets via Trick Shots — primary AoE damage inside the Trick Shots window.",
                tags = { "core" },
            },
            {
                spellID = 257044,
                name = "Rapid Fire",
                priority = 4,
                why = "Channels and ricochets — strong AoE, use on cooldown. Take Aim doubles its Aimed Shot CDR to 10s vs 2+ targets with Aspect of the Hydra.",
                tags = { "core" },
            },
            {
                spellID = 212431,
                name = "Explosive Shot",
                priority = 5,
                why = "Spread its DoT across targets — each tick on each target shaves 0.5s off Aimed Shot/Rapid Fire cooldowns (tier 4pc).",
                tags = { "core" },
            },
            {
                spellID = 260243,
                name = "Volley",
                priority = 6,
                why = "Sustained ground AoE — strong on 5+ stationary targets.",
                tags = { "active" },
            },
            {
                spellID = 56641,
                name = "Steady Shot",
                priority = 7,
                why = "Filler when Focus-starved or nothing else is up.",
                tags = { "active" },
                when = C.PowerBelow(40),
            },
            {
                spellID = 288613,
                name = "Trueshot",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major CD — cast with Trick Shots active and on large pulls; Sentinel's Trueshot empowers Moonlight Chakram.",
                tags = { "major-cd" },
            },
        },
    },
    st = {
        tip = "MM Raid (Dark Ranger favored for raid single-target): pure ranged, safest Hunter spec for mechanics. Aimed Shot with Precise Shots, Rapid Fire on cooldown for Take Aim's CDR, Explosive Shot to fill. Trueshot aligned with Bloodlust.",
        priorities = {
            {
                spellID = 257284,
                name = "Hunter's Mark",
                priority = 1,
                why = "+3% flat damage — maintain throughout.",
                tags = { "core" },
                when = C.DebuffRefresh(257284, 3),
            },
            {
                spellID = 19434,
                name = "Aimed Shot",
                priority = 2,
                why = "Primary nuke — always with Precise Shots. Never cast without it.",
                tags = { "core" },
            },
            {
                spellID = 257044,
                name = "Rapid Fire",
                priority = 3,
                why = "On cooldown — generates Precise Shots and shortens Aimed Shot's cooldown by 5s (Apex Talent Take Aim).",
                tags = { "core" },
            },
            {
                spellID = 212431,
                name = "Explosive Shot",
                priority = 4,
                why = "DoT generator — on cooldown. Ticks reduce Aimed Shot/Rapid Fire cooldowns by 0.5s each (tier 4pc).",
                tags = { "core" },
            },
            {
                spellID = 288613,
                name = "Trueshot",
                priority = 5,
                why = "Align with Bloodlust — opener: pre-cast Aimed Shot, Explosive Shot, Trueshot with potion, then Rapid Fire and back into priority.",
                tags = { "cd" },
                isCd = true,
                isMajorCd = true,
            },
            {
                spellID = 185358,
                name = "Arcane Shot",
                priority = 6,
                why = "Spends Precise Shots, do not overcap.",
                tags = { "active" },
            },
            {
                spellID = 56641,
                name = "Steady Shot",
                priority = 7,
                why = "True filler — press when Focus-starved and nothing else is up.",
                tags = { "active" },
                when = C.PowerBelow(40),
            },
            {
                spellID = 53351,
                name = "Kill Shot",
                priority = 8,
                why = "Execute under 20%.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
        },
    },
}

-- ── WARRIOR ───────────────────────────────────────────────────────────

-- ── Arms Warrior (specID 71) ─────────────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 guides (DPS
-- rotation/cooldowns page, spec/talents page) and cross-checked against
-- Wowhead (spell tooltips + the "Master of Whatfare?" apex-talent
-- analysis) for Patch 12.1 Season 2, raid Curse of Ula'tek: The Venomous
-- Abyss. Two Hero Talent trees: Slayer (Execute/Bladestorm — extra Sudden
-- Death procs and a stronger Execute phase; best for ST raid and current
-- M+) and Colossus (Mortal Strike/bleeds/Demolish — trades Bladestorm for
-- Ravager + Demolish, better sustained multi-target). The Apex Talent,
-- Master of Warfare (spell 1269306), is a passive you don't press: single-
-- target abilities build stacks (each with its own duration) that get
-- consumed by Colossus Smash to temporarily replace Slam with a harder-
-- hitting Heroic Strike. Guides agree the 4th point (Colossus Smash CDR on
-- Heroic Strike use) desyncs CS from Avatar and is a net loss — take only
-- the first 3 points. Season 2 tier set (Jade Warlord's Dominion, from
-- Curse of Ula'tek): 2pc Mortal Strike/Execute +10% damage and Slam
-- splashes nearby enemies (falls off past 5 targets); 4pc Overpower +15%
-- damage, and Mortal Strike/Overpower each stack a "next Slam" damage buff
-- up to 5 stacks — this is why Slam is no longer pure filler once the set
-- is on.
R[71] = { -- Arms
    solo = {
        tip = "Arms solo: Mortal Strike on CD, Overpower on procs. With the tier set, Slam is a real priority once MS/OP have stacked its buff — not pure filler. Execute below 20%. Avatar + Colossus Smash for burst; Sweeping Strikes for 2+ mobs.",
        priorities = {
            {
                spellID = 12294,
                name = "Mortal Strike",
                priority = 1,
                why = "Primary nuke. Use on cooldown — also stacks the 4pc next-Slam buff.",
                tags = { "core" },
            },
            {
                spellID = 7384,
                name = "Overpower",
                priority = 2,
                why = "Free proc — use immediately, never waste. Also stacks the 4pc next-Slam buff.",
                tags = { "core" },
            },
            {
                spellID = 163201,
                name = "Execute",
                priority = 3,
                why = "Below 20% — replaces Slam in execute.",
                tags = { "core" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 1464,
                name = "Slam",
                priority = 4,
                why = "Rage dump when MS and OP are on CD — hits much harder with a stacked 4pc buff, and 2pc makes it splash nearby enemies.",
                tags = { "active" },
            },
            {
                spellID = 260708,
                name = "Sweeping Strikes",
                priority = 5,
                why = "2+ targets — enables cleave for 12s.",
                tags = { "aoe" },
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Strength/damage cooldown — line up with Colossus Smash for burst.",
                tags = { "cd" },
            },
            {
                spellID = 1269306,
                name = "Master of Warfare",
                priority = nil,
                why = "Apex Talent, passive — single-target hits build stacks that Colossus Smash consumes to upgrade Slam into Heroic Strike. Take only the first 3 points; the CS-CDR 4th point desyncs your cooldowns.",
                tags = { "passive" },
            },
            {
                spellID = 18499,
                name = "Berserker Rage",
                priority = nil,
                isCd = true,
                why = "Enrage on demand + fear break.",
                tags = { "defensive" },
            },
            {
                spellID = 97462,
                name = "Rallying Cry",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency group heal — use when low.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Arms AoE: Sweeping Strikes + Cleave → Mortal Strike, cleaved by SS. Colossus's Ravager (spin before Colossus Smash) and Demolish (channel during CS) beat Slayer's Bladestorm here; keep Avatar and CS on cooldown.",
        chain = {
            { spellID = 260708, name = "Sweeping Strikes" },
            { spellID = 845, name = "Cleave" },
            { spellID = 167105, name = "Colossus Smash" },
            { spellID = 228920, name = "Ravager" },
            { spellID = 12294, name = "Mortal Strike" },
            { spellID = 7384, name = "Overpower" },
        },
        priorities = {
            {
                spellID = 260708,
                name = "Sweeping Strikes",
                priority = 1,
                why = "Enable cleave on every use — 12s uptime.",
                tags = { "core" },
            },
            {
                spellID = 845,
                name = "Cleave",
                priority = 2,
                why = "AoE rage spender, replaces Slam. Splashes further with 2pc-buffed Slam windows.",
                tags = { "core" },
            },
            {
                spellID = 12294,
                name = "Mortal Strike",
                priority = 3,
                why = "Still strongest single hit, cleaved by SS.",
                tags = { "core" },
            },
            {
                spellID = 7384,
                name = "Overpower",
                priority = 4,
                why = "Proc — still use between MS.",
                tags = { "active" },
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Damage cooldown — line up with Colossus Smash and your AoE burst window.",
                tags = { "cd" },
            },
            {
                spellID = 228920,
                name = "Ravager",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Colossus",
                talentAlt = "Bladestorm",
                why = "Colossus's AoE cooldown — spinning cleave buff, use just before Colossus Smash on every pull.",
                tags = { "cd" },
            },
            {
                spellID = 436358,
                name = "Demolish",
                priority = nil,
                isCd = true,
                talentReq = "Colossus",
                talentAlt = "Bladestorm",
                why = "Colossus finisher — channel during Colossus Smash; hits the target hard plus everything within 10yd, and you can still block/parry/dodge through it.",
                tags = { "cd" },
            },
            {
                spellID = 227847,
                name = "Bladestorm",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Slayer",
                talentAlt = "Ravager",
                why = "Slayer's massive AoE — use on 4+ packs.",
                tags = { "cd" },
            },
            {
                spellID = 376079,
                name = "Champion's Spear",
                priority = nil,
                isCd = true,
                why = "Optional M+ pull tool — roots a pack at the impact point for a few seconds of extra damage.",
                tags = { "cd", "utility" },
            },
        },
    },
    st = {
        tip = "Arms ST: Colossus Smash on CD, Mortal Strike inside the window, Overpower procs, Execute below 20%. Slayer's Bladestorm or Colossus's Demolish during CS depending on hero talent.",
        priorities = {
            {
                spellID = 167105,
                name = "Colossus Smash",
                priority = 1,
                why = "Debuff window — dump rage during this.",
                tags = { "core" },
            },
            {
                spellID = 12294,
                name = "Mortal Strike",
                priority = 2,
                why = "Highest priority inside CS window. Stacks the 4pc next-Slam buff.",
                tags = { "core" },
            },
            {
                spellID = 7384,
                name = "Overpower",
                priority = 3,
                why = "Free damage — never cap 2 charges. Stacks the 4pc next-Slam buff.",
                tags = { "core" },
            },
            {
                spellID = 163201,
                name = "Execute",
                priority = 4,
                why = "Sub-20% replaces Slam entirely.",
                tags = { "core" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 1464,
                name = "Slam",
                priority = 5,
                why = "Filler outside CS window — much harder-hitting with a stacked 4pc buff.",
                tags = { "active" },
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Damage cooldown — pair with Colossus Smash for the biggest burst window.",
                tags = { "cd" },
            },
            {
                spellID = 1269306,
                name = "Master of Warfare",
                priority = nil,
                why = "Apex Talent, passive — builds stacks off single-target hits, consumed by Colossus Smash to upgrade Slam into Heroic Strike. Skip the 4th point (CS CDR desyncs Avatar).",
                tags = { "passive" },
            },
            {
                spellID = 436358,
                name = "Demolish",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Colossus",
                talentAlt = "Bladestorm",
                why = "Colossus's ST burst — channel during Colossus Smash for a huge finisher; immune to CC and can still block/parry/dodge while channeling.",
                tags = { "cd" },
            },
            {
                spellID = 228920,
                name = "Ravager",
                priority = nil,
                isCd = true,
                talentReq = "Colossus",
                why = "Colossus — spin just before Colossus Smash for extra bleed/cleave uptime.",
                tags = { "cd" },
            },
            {
                spellID = 227847,
                name = "Bladestorm",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Slayer",
                talentAlt = "Demolish",
                why = "Slayer — use during Colossus Smash for the Execute-phase Sudden Death synergy.",
                tags = { "cd" },
            },
            {
                spellID = 376079,
                name = "Champion's Spear",
                priority = nil,
                isCd = true,
                why = "Situational — small extra ST burst on cooldown, mostly used for the utility root in M+.",
                tags = { "cd", "utility" },
            },
        },
    },
}
-- ── Fury Warrior (specID 72) ─────────────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 guides (DPS guide +
-- rotation/cooldowns page, which gives the ST/AoE opener and priority
-- order used below) and cross-checked against Wowhead/warcraft.wiki (spell
-- tooltips, Rampaging Berserker apex-talent data) for Patch 12.1 Season 2,
-- raid Curse of Ula'tek: The Venomous Abyss. Two Hero Talent trees: Slayer
-- (AoE burst via Reap the Storm + stacking Executioner for a bigger
-- Execute) and Mountain Thane (sustained AoE — Storm Surge upgrades
-- Thunder Clap into Thunder Blast during Avatar, plus Impending Victory
-- healing). The Apex Talent, Rampaging Berserker (1269308/1269309/1269310
-- across its points), is passive: each Rampage grants a stacking Strength
-- buff, Rampage gets cheaper and hits harder during Recklessness, and the
-- final point extends Recklessness and grants it free stacks on cast —
-- this is why Rampage charges are worth holding for a Recklessness window
-- rather than dumping the instant they're up. Season 2 tier set (Jade
-- Warlord's Dominion): 2pc Raging Blow +15% damage and, if it procs during
-- Recklessness, extends Recklessness's duration; 4pc Bloodthirst +10%
-- damage plus a bigger crit bonus during Recklessness — both reward
-- funneling Raging Blow/Bloodthirst into the Recklessness window instead
-- of spreading them out.
R[72] = { -- Fury
    solo = {
        tip = "Fury solo: Rampage at 80+ rage, Bloodthirst on CD for Enrage, Raging Blow (or Crushing Blow, if talented) as filler, Thunder Blast when it procs. Nearly unkillable with Enrage healing.",
        priorities = {
            {
                spellID = 184367,
                name = "Rampage",
                priority = 1,
                why = "At 80+ rage — triggers Enrage. Hold a charge for Recklessness if it's about to come up.",
                tags = { "core" },
            },
            {
                spellID = 23881,
                name = "Bloodthirst",
                priority = 2,
                why = "On cooldown — Enrage proc + self-heal. 4pc makes this hit harder and crit more during Recklessness.",
                tags = { "core" },
            },
            {
                spellID = 335098,
                name = "Crushing Blow",
                priority = 3,
                why = "Talent alternative to Raging Blow — dual-weapon strike that can reset its own cooldown on a 25% chance.",
                tags = { "core" },
                talentReq = "Crushing Blow",
                talentAlt = "Raging Blow",
            },
            {
                spellID = 85288,
                name = "Raging Blow",
                priority = 3,
                why = "2 charges — dump between BT/Rampage.",
                tags = { "core" },
                talentAlt = "Crushing Blow",
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 4,
                why = "Proc off Bloodthirst (Mountain Thane amplifies it further) — free rage-positive hit, use it before it falls off.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                when = C.HasBuff(435607),
            },
            {
                spellID = 163201,
                name = "Execute",
                priority = 5,
                why = "Sub-20% — replaces Raging Blow.",
                tags = { "core" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 190411,
                name = "Whirlwind",
                priority = 6,
                why = "Only for 2+ mobs (enables Meat Cleaver).",
                tags = { "aoe" },
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Strength cooldown — line up with Recklessness.",
                tags = { "cd" },
            },
            {
                spellID = 205545,
                name = "Odyn's Fury",
                priority = nil,
                isCd = true,
                talentReq = "Odyn's Fury",
                why = "Instant Enrage trigger plus solid AoE fire damage — good non-cooldown-window opener/filler.",
                tags = { "cd" },
            },
            {
                spellID = 1269308,
                name = "Rampaging Berserker",
                priority = nil,
                why = "Apex Talent, passive — every Rampage stacks a Strength buff; Rampage gets cheaper/harder-hitting during Recklessness, which also gets extended and pre-stacked at max investment.",
                tags = { "passive" },
            },
            {
                spellID = 1719,
                name = "Recklessness",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst CD — Rampage spam during, empowered further by Rampaging Berserker and the 2pc/4pc tier bonuses.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Fury AoE: Whirlwind (enables Meat Cleaver) → Rampage → Bloodthirst/Crushing Blow, weaving Thunder Blast procs. Odyn's Fury as an opener, Recklessness on large pulls.",
        chain = {
            { spellID = 190411, name = "Whirlwind" },
            { spellID = 184367, name = "Rampage" },
            { spellID = 23881, name = "Bloodthirst" },
            { spellID = 435607, name = "Thunder Blast" },
            { spellID = 85288, name = "Raging Blow" },
        },
        priorities = {
            {
                spellID = 190411,
                name = "Whirlwind",
                priority = 1,
                why = "Always first — enables Meat Cleaver for next 2 hits, and maintains Improved Whirlwind uptime on 6+ targets.",
                tags = { "core" },
            },
            {
                spellID = 184367,
                name = "Rampage",
                priority = 2,
                why = "At 80 rage — cleaves via Meat Cleaver.",
                tags = { "core" },
            },
            { spellID = 23881, name = "Bloodthirst", priority = 3, why = "Enrage + healing.", tags = { "core" } },
            {
                spellID = 335098,
                name = "Crushing Blow",
                priority = 4,
                why = "Talent alternative to Raging Blow between Whirlwind refreshes.",
                tags = { "active" },
                talentReq = "Crushing Blow",
                talentAlt = "Raging Blow",
            },
            {
                spellID = 85288,
                name = "Raging Blow",
                priority = 4,
                why = "Fill between WW refreshes.",
                tags = {
                    "active",
                },
                talentAlt = "Crushing Blow",
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 5,
                why = "Proc off Bloodthirst — Mountain Thane's Storm Surge upgrades this further during Avatar. Free rage-positive AoE hit.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                when = C.HasBuff(435607),
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Damage cooldown — Mountain Thane's Storm Surge buffs Thunder Clap/Thunder Blast heavily during it.",
                tags = { "cd" },
            },
            {
                spellID = 205545,
                name = "Odyn's Fury",
                priority = nil,
                isCd = true,
                talentReq = "Odyn's Fury",
                why = "Multitarget opener — instant Enrage plus AoE fire damage to everything nearby.",
                tags = { "cd" },
            },
            {
                spellID = 1719,
                name = "Recklessness",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big packs — pop and Rampage spam; 2pc/4pc both scale up while it's active.",
                tags = { "cd" },
            },
            {
                spellID = 376079,
                name = "Champion's Spear",
                priority = nil,
                isCd = true,
                why = "Niche in current tuning — mostly a soft-CC pull tool in M+, occasionally worth the small extra AoE hit.",
                tags = { "cd", "utility" },
            },
        },
    },
    st = {
        tip = "Fury ST: Rampage at 80 rage (hold for Recklessness), BT/Crushing Blow on CD for Enrage uptime, Raging Blow filler, Thunder Blast on proc. Execute phase is massive with Enrage up.",
        priorities = {
            {
                spellID = 184367,
                name = "Rampage",
                priority = 1,
                why = "80+ rage — Enrage proc is your damage steroid. Bank a charge into Recklessness when it's close.",
                tags = { "core" },
            },
            {
                spellID = 23881,
                name = "Bloodthirst",
                priority = 2,
                why = "On CD — Enrage uptime is everything. 4pc adds bonus damage and crit during Recklessness.",
                tags = { "core" },
            },
            {
                spellID = 335098,
                name = "Crushing Blow",
                priority = 3,
                why = "Talent alternative to Raging Blow — self-resetting dual strike.",
                tags = { "core" },
                talentReq = "Crushing Blow",
                talentAlt = "Raging Blow",
            },
            {
                spellID = 85288,
                name = "Raging Blow",
                priority = 3,
                why = "Dump charges between BT.",
                tags = { "core" },
                talentAlt = "Crushing Blow",
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 4,
                why = "Reactive — use the proc from Bloodthirst before it expires.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                when = C.HasBuff(435607),
            },
            {
                spellID = 163201,
                name = "Execute",
                priority = 5,
                why = "Sub-20% — massive with Enrage.",
                tags = { "core" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 107574,
                name = "Avatar",
                priority = nil,
                isCd = true,
                why = "Line up with Recklessness/Bloodlust for the biggest burst window.",
                tags = { "cd" },
            },
            {
                spellID = 1269308,
                name = "Rampaging Berserker",
                priority = nil,
                why = "Apex Talent, passive — stacking Strength off Rampage; cheaper/stronger Rampage and an extended, pre-stacked Recklessness at max rank.",
                tags = { "passive" },
            },
            {
                spellID = 1719,
                name = "Recklessness",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Align with Bloodlust. Rampage freely — 2pc/4pc and Rampaging Berserker all scale up during this window.",
                tags = { "cd" },
            },
        },
    },
}
-- ── Protection Warrior (specID 73) ───────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 tank guide and
-- cross-checked against Wowhead/warcraft.wiki (Phalanx apex-talent spell
-- data, Thunder Blast/Demolish/Champion's Spear/Odyn's Fury tooltips) for
-- Patch 12.1 Season 2, raid Curse of Ula'tek: The Venomous Abyss. Two Hero
-- Talent trees: Mountain Thane (better Rage economy and rotational flow —
-- the default pick, largely unchanged this patch) and Colossus (niche AoE
-- via Earthquaker/Boneshaker-buffed Shockwave, plus knockback immunity
-- while channeling Demolish). The Apex Talent, Phalanx (spell 1269312), has
-- Thunder Clap trigger an empowered Shield Slam (extra cone damage behind
-- the target plus a damage-reduction debuff) and boosts both Thunder Clap
-- and Phalanx's Shockwave damage. Season 2 tier set (Jade Warlord's
-- Dominion): 2pc free Revenges deal 15% more damage and buff your next
-- Shield Slam by 20%; 4pc Ravager and free Revenges apply a bleed to
-- everything they hit and cut Ravager's cooldown by 30s — 4pc is why
-- Ravager moves from "big packs only" to "essentially on cooldown."
R[73] = { -- Protection
    solo = {
        tip = "Prot Warrior solo: Shield Slam on CD (watch for Thunder Blast procs off it), Thunder Clap for AoE threat, Revenge procs. Nearly unkillable — pull big.",
        priorities = {
            {
                spellID = 23922,
                name = "Shield Slam",
                priority = 1,
                why = "Hardest hit + rage gen. Use on CD — has a chance to grant Thunder Blast, and the 2pc buff makes the next cast hit 20% harder.",
                tags = { "core" },
            },
            {
                spellID = 6572,
                name = "Revenge",
                priority = 2,
                why = "Free proc or 20 rage — strong AoE. Free procs hit 15% harder and apply a bleed with 2pc/4pc.",
                tags = { "core" },
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 3,
                why = "Proc off Shield Slam — upgraded Thunder Clap, use it before it falls off. Empowered further by the Phalanx apex talent.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                talentAlt = "Thunder Clap",
                when = C.HasBuff(435607),
            },
            {
                spellID = 6343,
                name = "Thunder Clap",
                priority = 4,
                why = "AoE threat + slow. Maintain on packs — also arms Phalanx's empowered Shield Slam.",
                tags = { "core" },
                talentAlt = "Thunder Blast",
            },
            {
                spellID = 2565,
                name = "Shield Block",
                priority = 5,
                why = "Active mitigation — keep up vs melee.",
                tags = { "defensive" },
            },
            {
                spellID = 190456,
                name = "Ignore Pain",
                priority = 6,
                why = "Absorb shield — dump excess rage here.",
                tags = { "defensive" },
            },
            {
                spellID = 1269312,
                name = "Phalanx",
                priority = nil,
                why = "Apex Talent, passive — Thunder Clap empowers your next Shield Slam with cone damage and a target debuff, and boosts Thunder Clap/Shockwave damage.",
                tags = { "passive" },
            },
            {
                spellID = 1160,
                name = "Demoralizing Shout",
                priority = nil,
                isCd = true,
                why = "Big pulls — 20% less damage taken.",
                tags = { "defensive" },
            },
            {
                spellID = 12975,
                name = "Last Stand",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency — 30% max HP.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Prot AoE: Thunder Clap/Thunder Blast priority, Revenge on proc, Shield Slam for rage. With 4pc, Ravager is close to on-cooldown rather than save-for-big-pulls; Demolish is the Colossus alternative.",
        chain = {
            { spellID = 6343, name = "Thunder Clap" },
            { spellID = 6572, name = "Revenge" },
            { spellID = 23922, name = "Shield Slam" },
            { spellID = 435607, name = "Thunder Blast" },
            { spellID = 2565, name = "Shield Block" },
        },
        priorities = {
            {
                spellID = 6343,
                name = "Thunder Clap",
                priority = 1,
                why = "AoE threat baseline — always on CD in packs, arms Phalanx's Shield Slam empowerment.",
                tags = { "core" },
                talentAlt = "Thunder Blast",
            },
            { spellID = 6572, name = "Revenge", priority = 2, why = "Strong AoE + free procs; bleeds everything hit with 4pc.", tags = { "core" } },
            {
                spellID = 23922,
                name = "Shield Slam",
                priority = 3,
                why = "Rage gen for Shield Block uptime, plus a chance at Thunder Blast.",
                tags = { "core" },
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 4,
                why = "Proc off Shield Slam — take it over a plain Thunder Clap cast when it's up.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                when = C.HasBuff(435607),
            },
            {
                spellID = 2565,
                name = "Shield Block",
                priority = 5,
                why = "100% uptime in M+ pulls.",
                tags = { "defensive" },
            },
            {
                spellID = 228920,
                name = "Ravager",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Colossus",
                talentAlt = "Demolish",
                why = "Massive AoE CD — 4pc's 30s CDR and bleed-on-hit make this close to an on-cooldown press, not just for big pulls.",
                tags = { "cd" },
            },
            {
                spellID = 436358,
                name = "Demolish",
                priority = nil,
                isCd = true,
                talentReq = "Colossus",
                talentAlt = "Ravager",
                why = "Colossus alternative burst channel — immune to knockback/stun while channeling, still lets you block/parry/dodge.",
                tags = { "cd" },
            },
            {
                spellID = 376079,
                name = "Champion's Spear",
                priority = nil,
                isCd = true,
                why = "Strong M+ pull tool — roots the pack at the impact point, reactivate to leap in and hit everything again.",
                tags = { "cd", "utility" },
            },
            {
                spellID = 205545,
                name = "Odyn's Fury",
                priority = nil,
                isCd = true,
                talentReq = "Odyn's Fury",
                why = "Optional AoE burst — instant fire damage to everything nearby.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Prot ST: Shield Slam > Revenge (proc) > Thunder Blast (proc) > Thunder Clap. Maintain Shield Block + Ignore Pain; Ravager is close to on-CD with 4pc.",
        priorities = {
            { spellID = 23922, name = "Shield Slam", priority = 1, why = "Hardest hit + rage; 2pc buffs your next cast.", tags = { "core" } },
            {
                spellID = 6572,
                name = "Revenge",
                priority = 2,
                why = "Only on free proc (save rage for IP) — free procs hit 15% harder with 2pc.",
                tags = { "core" },
            },
            {
                spellID = 435607,
                name = "Thunder Blast",
                priority = 3,
                why = "Reactive — spend the proc from Shield Slam before it expires.",
                tags = { "active" },
                talentReq = "Thunder Blast",
                when = C.HasBuff(435607),
            },
            { spellID = 6343, name = "Thunder Clap", priority = 4, why = "Filler + slow; arms Phalanx's Shield Slam.", tags = { "active" }, talentAlt = "Thunder Blast" },
            {
                spellID = 2565,
                name = "Shield Block",
                priority = 5,
                why = "Maintain vs physical bosses.",
                tags = { "defensive" },
            },
            {
                spellID = 190456,
                name = "Ignore Pain",
                priority = 6,
                why = "Dump rage above 60.",
                tags = { "defensive" },
            },
            {
                spellID = 1269312,
                name = "Phalanx",
                priority = nil,
                why = "Apex Talent, passive — Thunder Clap sets up an empowered Shield Slam (cone damage + target debuff) and boosts Thunder Clap/Shockwave.",
                tags = { "passive" },
            },
            {
                spellID = 228920,
                name = "Ravager",
                priority = nil,
                isCd = true,
                talentReq = "Colossus",
                talentAlt = "Demolish",
                why = "4pc's bleed + 30s CDR make this worth using on cooldown on single targets too, not just packs.",
                tags = { "cd" },
            },
            {
                spellID = 436358,
                name = "Demolish",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Colossus",
                talentAlt = "Ravager",
                why = "Colossus's ST burst channel — big finisher, immune to CC while channeling.",
                tags = { "cd" },
            },
        },
    },
}

-- ── PALADIN ───────────────────────────────────────────────────────────

-- ── Holy Paladin (specID 65) ─────────────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 healing guides
-- (rotation/cooldowns page + easy mode) and cross-checked against
-- Wowhead's Holy Paladin rotation guide and Method's Season 2 tier-set
-- breakdown for Patch 12.1 Season 2, raid Curse of Ula'tek: The Venomous
-- Abyss. Two Hero Talent trees: Herald of the Sun (raid default —
-- Divine Toll and Holy Prism generate Dawnlight procs that buff Holy
-- Shock) and Lightsmith (Mythic+ pick — Holy Armaments grants Sacred
-- Weapon, a buff you refresh on cooldown instead of leaning on Divine
-- Toll/Holy Prism). The Apex Talent, Beacon of the Savior, is passive:
-- it auto-applies a shielding, damage-reducing beacon to whoever is
-- lowest on health every 8 seconds, so it needs no button of its own.
-- Season 2 tier set (Radiance of the Consecrated Flame): 2pc doubles
-- what Infusion of Light adds to Flash of Light's healing and to
-- Judgment's absorb; 4pc gives Judgment a 20% chance to grant Infusion
-- of Light and makes Holy Light always grant it (at a 60% higher mana
-- cost) — together this is why Judgment moves up in priority and Flash
-- of Light, not Holy Light, becomes the go-to way to spend a proc.
R[65] = { -- Holy Paladin
    solo = {
        tip = "Holy Paladin solo: Holy Shock for damage/self-heal, Judgment on CD, Crusader Strike filler, Word of Glory when hurt. Hero talents (Herald of the Sun / Lightsmith) unlock at 71.",
        priorities = {
            {
                spellID = 20473,
                name = "Holy Shock",
                priority = 1,
                why = "Instant — damages an enemy or heals yourself depending on target, and your main source of Infusion of Light procs.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 2,
                why = "Ranged damage plus Holy Power. Use on CD — at max level this also has a tier-set chance to grant Infusion of Light.",
                tags = { "core" },
            },
            {
                spellID = 35395,
                name = "Crusader Strike",
                priority = 3,
                why = "Melee Holy Power filler between Holy Shock/Judgment cooldowns.",
                tags = { "core" },
            },
            {
                spellID = 85673,
                name = "Word of Glory",
                priority = 4,
                why = "At 3 Holy Power — self-heal when below 60%.",
                tags = { "core" },
            },
            {
                spellID = 19750,
                name = "Flash of Light",
                priority = 5,
                why = "Consume an Infusion of Light proc here rather than let it fall off — cheap, fast heal.",
                tags = { "active" },
                when = C.HasBuff(54149),
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 6,
                why = "Execute range, or any time during Avenging Wrath.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 31884,
                name = "Avenging Wrath",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst CD — damage and healing both increase.",
                tags = { "cd" },
            },
            { spellID = 114165, name = "Holy Prism", priority = 7, why = "Short cooldown — keep on cooldown (Icy Veins 12.1 priority).", tags = { "core" } },
            { spellID = 156322, name = "Eternal Flame", priority = 8, why = "Holy Power spender (talent replacing Word of Glory).", tags = { "core" } },
            { spellID = 216331, name = "Avenging Crusader", priority = nil, isCd = true, isMajorCd = true, why = "Alternative to Avenging Wrath when talented.", tags = { "cd" } },
        },
    },
    aoe = {
        tip = "Holy M+ (Lightsmith default): keep Sacred Weapon refreshed and Divine Toll on CD, Holy Shock constantly, Flash of Light on Infusion of Light procs, Judgment for extra procs, Word of Glory/Holy Light to spend Holy Power. Herald of the Sun trades Sacred Weapon upkeep for extra Divine Toll/Holy Prism value.",
        chain = {
            { spellID = 20473, name = "Holy Shock" },
            { spellID = 304971, name = "Divine Toll" },
            { spellID = 20271, name = "Judgment" },
            { spellID = 19750, name = "Flash of Light" },
            { spellID = 85673, name = "Word of Glory" },
            { spellID = 20473, name = "Holy Shock" },
        },
        priorities = {
            {
                spellID = 20473,
                name = "Holy Shock",
                priority = 1,
                why = "Core heal and HP gen — use on the most injured target, on CD.",
                tags = { "core" },
            },
            {
                spellID = 304971,
                name = "Divine Toll",
                priority = 2,
                why = "On cooldown — hits several allies with Holy Shock-style healing and feeds Herald of the Sun's Dawnlight procs.",
                condition = "On cooldown",
                tags = { "core" },
            },
            {
                spellID = 432472,
                name = "Sacred Weapon",
                priority = 3,
                why = "Lightsmith — refresh on cooldown, buffs your next several casts.",
                condition = "On cooldown",
                tags = { "core" },
                talentReq = "Lightsmith",
                talentAlt = "Herald of the Sun (skip — lean on extra Divine Toll/Holy Prism procs instead)",
            },
            {
                spellID = 19750,
                name = "Flash of Light",
                priority = 4,
                why = "Consume Infusion of Light here — the 2pc doubles the extra healing it grants.",
                tags = { "core" },
                when = C.HasBuff(54149),
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 5,
                why = "Filler with a real payoff at 4pc — 20% chance to grant Infusion of Light, so don't skip it mid-heal-check.",
                tags = { "active" },
            },
            {
                spellID = 85673,
                name = "Word of Glory",
                priority = 6,
                why = "At 3 Holy Power — burst heal (or rolling HoT if you've talented it into Eternal Flame, same button).",
                tags = { "core" },
            },
            {
                spellID = 82326,
                name = "Holy Light",
                priority = 7,
                why = "Mana-heavy filler heal — 4pc makes it always grant Infusion of Light, but at 60% more mana, so don't spam it purely to force procs.",
                tags = { "active" },
            },
            {
                spellID = 200025,
                name = "Beacon of Virtue",
                priority = nil,
                isCd = true,
                why = "Raid CD — cast the instant a damage event lands; heals and starts HoTs on up to 4 injured allies.",
                tags = { "cd" },
            },
            {
                spellID = 31821,
                name = "Aura Mastery",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Raid CD — massive damage reduction.",
                tags = { "cd" },
            },
            { spellID = 114165, name = "Holy Prism", priority = 8, why = "Short cooldown — keep on cooldown (Icy Veins 12.1 priority).", tags = { "core" } },
            { spellID = 156322, name = "Eternal Flame", priority = 9, why = "Holy Power spender (talent replacing Word of Glory).", tags = { "core" } },
            { spellID = 216331, name = "Avenging Crusader", priority = nil, isCd = true, isMajorCd = true, why = "Alternative to Avenging Wrath when talented.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Holy Raid (Herald of the Sun default): Holy Shock and Divine Toll on CD, Flash of Light on Infusion of Light procs, Word of Glory on tanks, Light of Dawn on stacked groups, Judgment as filler for extra procs.",
        priorities = {
            {
                spellID = 20473,
                name = "Holy Shock",
                priority = 1,
                why = "Highest priority — heals and generates Holy Power.",
                tags = { "core" },
            },
            {
                spellID = 304971,
                name = "Divine Toll",
                priority = 2,
                why = "On cooldown — strong multi-target burst heal.",
                condition = "On cooldown",
                tags = { "core" },
            },
            {
                spellID = 19750,
                name = "Flash of Light",
                priority = 3,
                why = "Consume Infusion of Light procs here — 2pc doubles the bonus healing.",
                tags = { "core" },
                when = C.HasBuff(54149),
            },
            {
                spellID = 85673,
                name = "Word of Glory",
                priority = 4,
                why = "At 3 Holy Power — strong single-target heal, usually the tank.",
                tags = { "core" },
            },
            {
                spellID = 85222,
                name = "Light of Dawn",
                priority = 5,
                why = "At 3 Holy Power if the group is stacked.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 6,
                why = "Filler — 4pc gives it a chance to grant Infusion of Light, don't neglect it.",
                tags = { "active" },
            },
            {
                spellID = 200025,
                name = "Beacon of Virtue",
                priority = nil,
                isCd = true,
                why = "Raid CD — use the instant damage lands on the raid.",
                tags = { "cd" },
            },
            {
                spellID = 31884,
                name = "Avenging Wrath",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Align with damage events.",
                tags = { "cd" },
            },
            { spellID = 114165, name = "Holy Prism", priority = 7, why = "Short cooldown — keep on cooldown (Icy Veins 12.1 priority).", tags = { "core" } },
            { spellID = 156322, name = "Eternal Flame", priority = 8, why = "Holy Power spender (talent replacing Word of Glory).", tags = { "core" } },
            { spellID = 216331, name = "Avenging Crusader", priority = nil, isCd = true, isMajorCd = true, why = "Alternative to Avenging Wrath when talented.", tags = { "cd" } },
        },
    },
}

-- ── Protection Paladin (specID 66) ───────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 tank guide
-- (rotation/cooldowns page + opener) and cross-checked against Method's
-- Protection Paladin playstyle/rotation guide and Season 2 tier-set
-- breakdown for Patch 12.1 Season 2, raid Curse of Ula'tek: The Venomous
-- Abyss. Two Hero Talent trees: Templar (top priority becomes Hammer of
-- Light, fed by Wake of Ashes/Judgment procs, plus the Shake the
-- Heavens buff and Hammerfall's offensive Word of Glory) and Lightsmith
-- (Holy Armaments grants Sacred Weapon/Holy Bulwark, extending Grand
-- Crusader procs and Sacred Weapon uptime). The Apex Talent, Glory of
-- the Vanguard, has Judgment and Hammer of Wrath build stacks of
-- Vanguard (up to 3 during Avenging Wrath) that Avenger's Shield
-- consumes for bonus Holy Power, 20% extra damage to the primary
-- target, and minor splash damage — this is why Avenger's Shield is
-- worth holding half a second for a Vanguard stack rather than firing
-- the instant it's off cooldown. Season 2 tier set (Radiance of the
-- Consecrated Flame): 2pc makes Consecration 30% bigger and gives
-- enemies standing in it +5% chance to be critically struck; 4pc adds
-- 20% additional Holy damage to Judgment/Blessed Hammer hits, doubled
-- again on a crit — both push Judgment and Blessed Hammer up in
-- priority and make Critical Strike noticeably more valuable this tier.
R[66] = { -- Protection Paladin
    solo = {
        tip = "Prot Paladin solo: Shield of the Righteous at 3 HP, Judgment/Hammer of Wrath on CD for Vanguard stacks, Avenger's Shield to consume them, Consecration down. Insanely durable.",
        priorities = {
            {
                spellID = 53600,
                name = "Shield of the Righteous",
                priority = 1,
                why = "At 3+ Holy Power — active mitigation and damage. Never cap Holy Power.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 2,
                why = "HP gen and damage — also builds a stack of Vanguard toward your next Avenger's Shield.",
                tags = { "core" },
            },
            {
                spellID = 31935,
                name = "Avenger's Shield",
                priority = 3,
                why = "Bouncing shield — worth a beat to line up with a Vanguard stack; interrupts on the way in.",
                tags = { "core" },
            },
            {
                spellID = 204019,
                name = "Blessed Hammer",
                priority = 4,
                why = "Melee HP filler — 4pc makes this hit noticeably harder, especially on a crit.",
                tags = { "active" },
                talentReq = "Blessed Hammer",
                talentAlt = "Hammer of the Righteous",
            },
            {
                spellID = 88263,
                name = "Hammer of the Righteous",
                priority = 4,
                why = "Melee HP filler if you didn't take Blessed Hammer — still benefits from the 4pc bonus damage.",
                tags = { "active" },
                talentAlt = "Blessed Hammer",
            },
            {
                spellID = 26573,
                name = "Consecration",
                priority = 5,
                why = "Ground AoE — stand in it; 2pc makes it bigger and grants bonus crit chance to enemies inside.",
                tags = { "core" },
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 6,
                why = "Execute range, or usable any time during Avenging Wrath — also builds Vanguard.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 31850,
                name = "Ardent Defender",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "40% damage reduction plus cheat death.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Prot M+: Hammer of Light (Templar) or Sacred Weapon upkeep (Lightsmith) first, Avenger's Shield for threat and Vanguard payoff, Consecration always down, SotR for mitigation, Judgment/Hammer of Wrath to build Vanguard.",
        chain = {
            { spellID = 26573, name = "Consecration" },
            { spellID = 31935, name = "Avenger's Shield" },
            { spellID = 20271, name = "Judgment" },
            { spellID = 53600, name = "Shield of the Righteous" },
            { spellID = 204019, name = "Blessed Hammer" },
        },
        priorities = {
            {
                spellID = 429826,
                name = "Hammer of Light",
                priority = 1,
                why = "Templar — top-priority spender, fed by Wake of Ashes and Judgment procs; hits harder than a plain Shield of the Righteous cast.",
                tags = { "core" },
                talentReq = "Templar",
                talentAlt = "Lightsmith (use Sacred Weapon upkeep instead)",
            },
            {
                spellID = 432472,
                name = "Sacred Weapon",
                priority = 1,
                why = "Lightsmith — refresh on cooldown for a multi-cast buff instead of chasing Hammer of Light procs.",
                condition = "On cooldown",
                tags = { "core" },
                talentReq = "Lightsmith",
                talentAlt = "Templar (use Hammer of Light instead)",
            },
            {
                spellID = 31935,
                name = "Avenger's Shield",
                priority = 2,
                why = "AoE threat snap, bounces to 3 targets — consumes a Vanguard stack for extra Holy Power and splash damage.",
                tags = { "core" },
            },
            {
                spellID = 26573,
                name = "Consecration",
                priority = 3,
                why = "AoE damage and threat — always stand in it; bigger and crittier with 2pc.",
                tags = { "core" },
            },
            {
                spellID = 53600,
                name = "Shield of the Righteous",
                priority = 4,
                why = "Mitigation — maintain uptime, don't overcap Holy Power.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 5,
                why = "HP gen, builds a Vanguard stack.",
                tags = { "active" },
            },
            {
                spellID = 204019,
                name = "Blessed Hammer",
                priority = 6,
                why = "Filler — AoE damage, boosted by 4pc.",
                tags = { "active" },
                talentReq = "Blessed Hammer",
                talentAlt = "Hammer of the Righteous",
            },
            {
                spellID = 88263,
                name = "Hammer of the Righteous",
                priority = 6,
                why = "Filler if Blessed Hammer isn't talented — still boosted by 4pc.",
                tags = { "active" },
                talentAlt = "Blessed Hammer",
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 7,
                why = "Execute range or during Avenging Wrath — also builds Vanguard.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 304971,
                name = "Divine Toll",
                priority = nil,
                isCd = true,
                why = "On cooldown — Judgment-like damage and Holy Power to several enemies; good on the pull.",
                tags = { "cd" },
            },
            {
                spellID = 31850,
                name = "Ardent Defender",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Tankbuster or emergency — 40% DR plus cheat death.",
                tags = { "defensive" },
            },
        },
    },
    st = {
        tip = "Prot ST: Hammer of Light (Templar) or Sacred Weapon (Lightsmith) first, SotR uptime, Judgment/Hammer of Wrath to build Vanguard, Avenger's Shield to consume it, Consecration always down.",
        priorities = {
            {
                spellID = 429826,
                name = "Hammer of Light",
                priority = 1,
                why = "Templar — top-priority spender off Wake of Ashes/Judgment procs.",
                tags = { "core" },
                talentReq = "Templar",
                talentAlt = "Lightsmith (use Sacred Weapon upkeep instead)",
            },
            {
                spellID = 432472,
                name = "Sacred Weapon",
                priority = 1,
                why = "Lightsmith — refresh on cooldown.",
                condition = "On cooldown",
                tags = { "core" },
                talentReq = "Lightsmith",
                talentAlt = "Templar (use Hammer of Light instead)",
            },
            {
                spellID = 53600,
                name = "Shield of the Righteous",
                priority = 2,
                why = "Active mitigation — maintain, don't overcap.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 3,
                why = "HP gen plus damage, builds Vanguard.",
                tags = { "core" },
            },
            {
                spellID = 31935,
                name = "Avenger's Shield",
                priority = 4,
                why = "On a Vanguard stack — free extra Holy Power and damage.",
                tags = { "core" },
            },
            {
                spellID = 26573,
                name = "Consecration",
                priority = 5,
                why = "Maintain the ground effect — 2pc crit bonus.",
                tags = { "core" },
            },
            {
                spellID = 53595,
                name = "Hammer of the Righteous",
                priority = 6,
                why = "Filler, boosted by 4pc.",
                tags = { "active" },
                talentAlt = "Blessed Hammer",
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 7,
                why = "Execute or Avenging Wrath — builds Vanguard.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 31850,
                name = "Ardent Defender",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Tankbuster window.",
                tags = { "defensive" },
            },
        },
    },
}

-- ── Retribution Paladin (specID 70) ──────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' current 12.1 DPS guide
-- (rotation/cooldowns page + easy mode) and cross-checked against
-- Timesaver's Season 2 Retribution guide and Method's tier-set
-- breakdown for Patch 12.1 Season 2, raid Curse of Ula'tek: The
-- Venomous Abyss. Two Hero Talent trees: Herald of the Sun (Icy Veins'
-- pick for both raid and Mythic+ — more Hammer of Wrath uptime and
-- Divine Storm value) and Templar (an alternative other guides favor —
-- routes Wake of Ashes procs into Hammer of Light as your hardest-
-- hitting spender). The Apex Talent, Light Within, gives Art of War and
-- Righteous Cause an extra charge each, so a proc can be banked through
-- forced movement instead of wasted. Season 2 tier set (Radiance of the
-- Consecrated Flame): 2pc adds 10% Divine Purpose proc chance and has
-- consuming a free Divine Purpose grant Divine Power (+10% Holy damage,
-- 12s); 4pc has that same free-Divine-Purpose Divine Storm make your
-- next Final Verdict free and unleash a Divine Arbiter splash around
-- the primary target — which is why Divine Storm gets woven in on a
-- Divine Purpose proc even on single-target, not saved purely for AoE.
R[70] = { -- Retribution
    solo = {
        tip = "Ret solo: Final Verdict at 5 HP, Blade of Justice/Judgment on CD, Crusader Strike filler, Wake of Ashes and Wings for burst. Hero talents and Hammer of Light unlock later.",
        priorities = {
            {
                spellID = 383328,
                name = "Final Verdict",
                priority = 1,
                why = "At 5 Holy Power — primary spender.",
                tags = { "core" },
            },
            {
                spellID = 184575,
                name = "Blade of Justice",
                priority = 2,
                why = "2 HP gen — always on CD, and builds Art of War stacks.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 3,
                why = "HP gen plus a damage debuff window.",
                tags = { "core" },
            },
            {
                spellID = 35395,
                name = "Crusader Strike",
                priority = 4,
                why = "Filler HP gen when nothing else is up.",
                tags = { "active" },
                talentAlt = "Templar Strikes (Templar hero talent)",
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 5,
                why = "Execute range, or any time during Avenging Wrath.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 255937,
                name = "Wake of Ashes",
                priority = nil,
                isCd = true,
                why = "Free Holy Power plus an AoE stun. Use on CD.",
                tags = { "cd" },
            },
            {
                spellID = 429826,
                name = "Hammer of Light",
                priority = nil,
                why = "Not yet unlocked — Templar's hero-talent finisher, fed by Wake of Ashes procs.",
                unlockLv = 80,
                tags = {},
            },
            {
                spellID = 31884,
                name = "Avenging Wrath",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst window — enables extra Hammer of Wrath casts.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Ret AoE (2+ targets): Divine Storm at 5 HP — free casts off Divine Purpose turn into a free Final Verdict plus Divine Arbiter splash with 4pc — Wake of Ashes/Divine Toll for HP and damage, Blade of Justice/Judgment on CD.",
        chain = {
            { spellID = 53385, name = "Divine Storm" },
            { spellID = 255937, name = "Wake of Ashes" },
            { spellID = 184575, name = "Blade of Justice" },
            { spellID = 20271, name = "Judgment" },
            { spellID = 383328, name = "Final Verdict" },
        },
        priorities = {
            {
                spellID = 53385,
                name = "Divine Storm",
                priority = 1,
                why = "At 5 Holy Power — AoE spender; free off a Divine Purpose proc, and 4pc turns that free cast into a free Final Verdict plus Divine Arbiter splash.",
                tags = { "core" },
            },
            {
                spellID = 383328,
                name = "Final Verdict",
                priority = 2,
                why = "Take this over Divine Storm specifically when Divine Arbiter just handed you a free cast.",
                tags = { "core" },
            },
            {
                spellID = 255937,
                name = "Wake of Ashes",
                priority = 3,
                why = "Free Holy Power plus massive AoE damage — short cooldown, use it on CD.",
                tags = { "core" },
            },
            {
                spellID = 184575,
                name = "Blade of Justice",
                priority = 4,
                why = "HP gen, builds Art of War.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 5,
                why = "HP gen.",
                tags = { "active" },
            },
            {
                spellID = 304971,
                name = "Divine Toll",
                priority = 6,
                why = "On cooldown — extra Holy Power and damage to several targets.",
                condition = "On cooldown",
                tags = { "active" },
            },
            {
                spellID = 26573,
                name = "Consecration",
                priority = 7,
                why = "Ground AoE if talented.",
                tags = { "active" },
            },
        },
    },
    st = {
        tip = "Ret ST: Final Verdict dump — weave in Divine Storm on a Divine Purpose proc for the free Final Verdict/Divine Arbiter payoff — Blade of Justice and Judgment on CD, Wake of Ashes/Divine Toll on CD, align Execution Sentence with Wings.",
        priorities = {
            {
                spellID = 383328,
                name = "Final Verdict",
                priority = 1,
                why = "At 5 Holy Power — primary single-target damage.",
                tags = { "core" },
            },
            {
                spellID = 53385,
                name = "Divine Storm",
                priority = 2,
                why = "Weave this in on a free Divine Purpose proc even on single-target — 4pc turns it into a free Final Verdict plus Divine Arbiter splash.",
                tags = { "core" },
            },
            {
                spellID = 184575,
                name = "Blade of Justice",
                priority = 3,
                why = "HP gen priority.",
                tags = { "core" },
            },
            {
                spellID = 20271,
                name = "Judgment",
                priority = 4,
                why = "HP gen plus debuff window.",
                tags = { "core" },
            },
            {
                spellID = 255937,
                name = "Wake of Ashes",
                priority = 5,
                why = "Burst HP gen on CD.",
                tags = { "core" },
            },
            {
                spellID = 304971,
                name = "Divine Toll",
                priority = 6,
                why = "On cooldown.",
                condition = "On cooldown",
                tags = { "active" },
            },
            {
                spellID = 24275,
                name = "Hammer of Wrath",
                priority = 7,
                why = "Execute or Wings-enabled.",
                tags = { "active" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 343527,
                name = "Execution Sentence",
                priority = nil,
                isCd = true,
                why = "Raid CD — delayed burst damage, line up with Avenging Wrath.",
                tags = { "cd" },
            },
            {
                spellID = 31884,
                name = "Avenging Wrath",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst — align with Bloodlust/Execution Sentence.",
                tags = { "cd" },
            },
        },
    },
}

-- ── DEATH KNIGHT ──────────────────────────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek — The Venomous Abyss). Sources cross-checked: Icy Veins DK
-- rotation/tier-set pages, Method.gg DK playstyle guides (Midnight 12.1),
-- Wowhead ability/talent guides and live spell pages, Warcraft Wiki talent
-- pages. SpellIDs for new/reworked abilities were looked up on Wowhead's
-- live spell pages; long-standing baseline abilities (Death Strike,
-- Obliterate, Howling Blast, etc.) keep their long-stable IDs. Verify with
-- GetSpellInfo() in-game if anything looks off after a hotfix.
--
-- All three specs share the Deathbringer hero tree paired with one other:
-- Blood = Deathbringer + San'layn, Frost = Deathbringer + Rider of the
-- Apocalypse, Unholy = San'layn + Rider of the Apocalypse. Deathbringer's
-- signature Reaper's Mark (439843) is a stacking Shadow/Frost debuff that
-- explodes after 12s or 40 stacks; its payoff, Exterminate (441378),
-- empowers your next big spender for free (Marrowrend for Blood, Obliterate
-- for Frost).

-- ── Blood Death Knight (specID 250) ────────────────────────────────
-- Hero talents: San'layn (recommended default for all content — Gift of
-- the San'layn periodically replaces Heart Strike with Vampiric Strike for
-- Shadow damage plus Essence of the Blood Queen Haste stacks) vs
-- Deathbringer (Reaper's Mark-centric, competitive alternative, simpler
-- execution). Apex talent Dance of Midnight: parries grant an empowered
-- Heart Strike, active Dancing Rune Weapons return 3% damage/4% damage
-- reduction per stack, and spending runes has a chance to spawn extra
-- temporary Dancing Rune Weapons — never let runes sit unspent.
-- Season 2 tier (Venomous Abyss): 2pc — Death Strike stacks Strength
-- (0.5%/stack, max 10); at 10 stacks your next Marrowrend grants an extra
-- 10% Strength for 10s. 4pc — a Marrowrend that consumes a full Blood Debt
-- stack grants 3 bonus Bone Shield charges and deals heavy AoE damage.
-- Practical effect: don't let Death Strike stacks or Blood Debt go to
-- waste — dump them into Marrowrend, ideally inside Dancing Rune Weapon.
R[250] = { -- Blood
    solo = {
        tip = "Blood DK solo (San'layn recommended): Death Strike is your heal, Heart Strike/Vampiric Strike for RP, Marrowrend keeps Bone Shield up and spends Death Strike Strength stacks. Pull everything — Blood is built to solo content.",
        priorities = {
            {
                spellID = 49998,
                name = "Death Strike",
                priority = 1,
                why = "Self-heal — spend RP here, never overcap. Each cast also stacks Strength via the Venomous Abyss 2pc set bonus (max 10 stacks).",
                tags = { "core" },
            },
            {
                spellID = 206930,
                name = "Heart Strike",
                priority = 2,
                why = "RP generator, cleaves 2 targets. San'layn hero talent periodically replaces this with Vampiric Strike during Gift of the San'layn.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike replaces this during Gift of the San'layn windows",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 3,
                why = "San'layn: replaces Heart Strike during Gift of the San'layn for Shadow damage and Essence of the Blood Queen Haste stacks.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 195182,
                name = "Marrowrend",
                priority = 4,
                why = "Maintain 5+ Bone Shield stacks. Spend your Death Strike Strength stacks and any full Blood Debt stack here (Venomous Abyss 2pc/4pc).",
                tags = { "core" },
                when = C.Not(C.BuffStacks(195181, 5)),
            },
            {
                spellID = 50842,
                name = "Blood Boil",
                priority = 5,
                why = "AoE threat + Blood Plague uptime (feeds Coagulopathy). 2 charges — don't cap them.",
                tags = { "core" },
            },
            {
                spellID = 195292,
                name = "Death's Caress",
                priority = 6,
                why = "Ranged pull opener, and a free extra Bone Shield charge when Marrowrend is on cooldown.",
                tags = { "active" },
            },
            {
                spellID = 55233,
                name = "Vampiric Blood",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "30% max HP + healing received — use before dangerous solo pulls.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Blood M+ (San'layn recommended, Deathbringer competitive): Blood Boil + Death and Decay for AoE threat and Blood Plague spread, cleave with Heart Strike/Vampiric Strike, Death Strike to stay topped. Dance of Midnight (Apex) rewards spending every rune.",
        chain = {
            { spellID = 50842, name = "Blood Boil" },
            { spellID = 43265, name = "Death and Decay" },
            { spellID = 206930, name = "Heart Strike" },
            { spellID = 49998, name = "Death Strike" },
            { spellID = 195182, name = "Marrowrend" },
        },
        priorities = {
            {
                spellID = 50842,
                name = "Blood Boil",
                priority = 1,
                why = "Snap AoE threat + Blood Plague spread. Never cap charges.",
                tags = { "core" },
            },
            {
                spellID = 43265,
                name = "Death and Decay",
                priority = 2,
                why = "Ground AoE — lets Heart Strike/Vampiric Strike cleave up to 5 targets and can proc Crimson Scourge resets.",
                tags = { "core" },
            },
            {
                spellID = 206930,
                name = "Heart Strike",
                priority = 3,
                why = "Cleave inside Death and Decay.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike during Gift of the San'layn",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 4,
                why = "San'layn: replaces Heart Strike during Gift of the San'layn — bonus Shadow cleave and Haste stacks.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 49998,
                name = "Death Strike",
                priority = 5,
                why = "Heal — spend RP above 80. Stacks Strength (tier 2pc).",
                tags = { "core" },
            },
            {
                spellID = 195182,
                name = "Marrowrend",
                priority = 6,
                why = "Bone Shield maintenance — dump Death Strike Strength stacks and full Blood Debt here.",
                tags = { "active" },
                when = C.Not(C.BuffStacks(195181, 5)),
            },
            {
                spellID = 439843,
                name = "Reaper's Mark",
                priority = 7,
                why = "Deathbringer: mark a target on cooldown — the debuff explosion hits nearby enemies too, and Exterminate empowers a free Marrowrend after.",
                tags = { "core", "cd" },
                talentReq = "Deathbringer",
            },
            {
                spellID = 49028,
                name = "Dancing Rune Weapon",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major cooldown — doubles Bone Shield generation from Marrowrend and mirrors your Heart Strike/Vampiric Strike attacks. Line up with Reaper's Mark on pull.",
                tags = { "cd" },
            },
            {
                spellID = 55233,
                name = "Vampiric Blood",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big damage phases or heavy pulls.",
                tags = { "defensive" },
            },
        },
    },
    st = {
        tip = "Blood ST/raid (San'layn favored, Deathbringer viable): Heart Strike/Vampiric Strike for RP, Death Strike to heal, Marrowrend below 5 stacks. Open with Death's Caress into Dancing Rune Weapon, align Reaper's Mark if Deathbringer.",
        priorities = {
            {
                spellID = 49998,
                name = "Death Strike",
                priority = 1,
                why = "Primary heal — don't overcap RP. Stacks Strength (Venomous Abyss 2pc).",
                tags = { "core" },
            },
            {
                spellID = 206930,
                name = "Heart Strike",
                priority = 2,
                why = "RP generator.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike during Gift of the San'layn",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 3,
                why = "San'layn: replaces Heart Strike during Gift of the San'layn.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 195182,
                name = "Marrowrend",
                priority = 4,
                why = "Below 5 Bone Shield stacks only — spend Death Strike Strength/Blood Debt here.",
                tags = { "core" },
                when = C.Not(C.BuffStacks(195181, 5)),
            },
            {
                spellID = 50842,
                name = "Blood Boil",
                priority = 5,
                why = "Blood Plague maintenance for Coagulopathy's damage buff.",
                tags = { "active" },
            },
            {
                spellID = 439843,
                name = "Reaper's Mark",
                priority = 6,
                why = "Deathbringer: cast on cooldown ahead of Dancing Rune Weapon for the Exterminate payoff.",
                tags = { "core", "cd" },
                talentReq = "Deathbringer",
            },
            {
                spellID = 49028,
                name = "Dancing Rune Weapon",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Align with Bloodlust and big damage phases — doubles Marrowrend's Bone Shield generation.",
                tags = { "cd" },
            },
            {
                spellID = 55233,
                name = "Vampiric Blood",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big damage phases.",
                tags = { "defensive" },
            },
            {
                spellID = 48792,
                name = "Icebound Fortitude",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Scripted high-damage mechanics or stuns.",
                tags = { "defensive" },
            },
        },
    },
}
-- ── Frost Death Knight (specID 251) ────────────────────────────────
-- Hero talents: Deathbringer (Reaper's Mark ramping debuff feeds free
-- Obliterates via Exterminate — strong and consistent) vs Rider of the
-- Apocalypse (rune spending has a chance to summon a Horseman; its
-- capstone can bring all Four Horsemen for burst). Both viable;
-- Deathbringer is the simpler, slightly higher default.
-- Apex talent Chosen of Frostbrood: +10% Frost damage, and Frostwyrm's
-- Fury can be recast at 50% power within 45s of the first cast — spend
-- both casts inside a single Pillar of Frost window rather than spacing
-- them out.
-- Season 2 tier (Venomous Abyss): 2pc — Remorseless Winter's pulses stack
-- a self-buff boosting attack speed and Icy Death Torrent damage. 4pc —
-- Remorseless Winter pulses 25% more often and the buff lasts longer.
-- Practical effect: keep Remorseless Winter as close to 100% uptime as
-- talents allow (Frozen Dominion triggers it automatically off Pillar of
-- Frost) — the tier set rewards passive uptime, not a new button.
R[251] = { -- Frost DK
    solo = {
        tip = "Frost DK solo (Deathbringer recommended): Obliterate on Killing Machine/Exterminate procs, Howling Blast free on Rime, Frost Strike to dump RP, Reaper's Mark to open.",
        priorities = {
            {
                spellID = 49020,
                name = "Obliterate",
                priority = 1,
                why = "Core rune spender — always free/empowered with Killing Machine, or with Exterminate after a Reaper's Mark explosion.",
                tags = { "core" },
            },
            {
                spellID = 49184,
                name = "Howling Blast",
                priority = 2,
                why = "Free with Rime, or to refresh Frost Fever.",
                tags = { "core" },
                when = C.HasBuff(59052),
            },
            {
                spellID = 49143,
                name = "Frost Strike",
                priority = 3,
                why = "RP dump — never overcap. Frostbane/Shattering Blade (talent choice) consumes or benefits from Razorice stacks here.",
                tags = { "core" },
            },
            {
                spellID = 196770,
                name = "Remorseless Winter",
                priority = 4,
                why = "AoE on 3+ targets; pulses build the Venomous Abyss 2pc/4pc Haste buff.",
                tags = { "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 439843,
                name = "Reaper's Mark",
                priority = 5,
                why = "Deathbringer: cast on cooldown — stacking debuff explodes after 12s/40 stacks and grants Exterminate (a free, extra-scythe Obliterate).",
                tags = { "core", "cd" },
                talentReq = "Deathbringer",
            },
            {
                spellID = 47568,
                name = "Empower Rune Weapon",
                priority = 6,
                why = "Use before capping charges — generates Runic Power and guarantees a Killing Machine proc.",
                tags = { "active" },
            },
            {
                spellID = 51271,
                name = "Pillar of Frost",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst — Obliterate spam during. Line up Reaper's Mark and Frostwyrm's Fury inside it.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Frost M+ (Deathbringer or Rider of the Apocalypse): Remorseless Winter for sustained AoE and tier uptime, Howling Blast on Rime, Glacial Advance to dump RP. Chosen of Frostbrood (Apex) wants both Frostwyrm's Fury casts inside one Pillar window.",
        chain = {
            { spellID = 196770, name = "Remorseless Winter" },
            { spellID = 49184, name = "Howling Blast" },
            { spellID = 194913, name = "Glacial Advance" },
            { spellID = 49020, name = "Obliterate" },
            { spellID = 49184, name = "Howling Blast" },
        },
        priorities = {
            {
                spellID = 196770,
                name = "Remorseless Winter",
                priority = 1,
                why = "Sustained AoE — keep it up as close to 100% as possible; pulses feed the Venomous Abyss tier buff.",
                tags = { "core" },
            },
            {
                spellID = 49184,
                name = "Howling Blast",
                priority = 2,
                why = "Rime procs for free AoE spread and Frost Fever uptime.",
                tags = { "core" },
                when = C.HasBuff(59052),
            },
            {
                spellID = 194913,
                name = "Glacial Advance",
                priority = 3,
                why = "AoE RP spender — interacts with Razorice via Frostbane/Shattering Blade.",
                tags = { "core" },
            },
            {
                spellID = 49020,
                name = "Obliterate",
                priority = 4,
                why = "Killing Machine/Exterminate procs only in heavy AoE — otherwise let Glacial Advance/Howling Blast carry.",
                tags = { "active" },
            },
            {
                spellID = 439843,
                name = "Reaper's Mark",
                priority = 5,
                why = "Deathbringer: mark the highest-value target — the explosion also hits nearby enemies.",
                tags = { "core", "cd" },
                talentReq = "Deathbringer",
            },
            {
                spellID = 51271,
                name = "Pillar of Frost",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst on big pulls — hold your second Frostwyrm's Fury (Chosen of Frostbrood) for inside this window.",
                tags = { "cd" },
            },
            {
                spellID = 279302,
                name = "Frostwyrm's Fury",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Line stun + big burst. Chosen of Frostbrood (Apex) grants a second cast at 50% power within 45s — spend both inside Pillar of Frost.",
                tags = { "cd" },
            },
            { spellID = 207230, name = "Frostscythe", priority = 6, why = "AoE builder replacing Obliterate on packs when talented.", tags = { "core" } },
            { spellID = 43265, name = "Death and Decay", priority = 7, why = "AoE ground effect on packs.", tags = { "active" } },
        },
    },
    st = {
        tip = "Frost ST/raid (Deathbringer favored): Obliterate with KM/Exterminate, Frost Strike to dump RP, Howling Blast only on Rime. Reaper's Mark and Pillar of Frost on cooldown; Breath of Sindragosa is an alternative cooldown build.",
        priorities = {
            {
                spellID = 49020,
                name = "Obliterate",
                priority = 1,
                why = "Primary — especially with Killing Machine or Exterminate.",
                tags = { "core" },
            },
            {
                spellID = 49143,
                name = "Frost Strike",
                priority = 2,
                why = "Dump RP. Never overcap.",
                tags = { "core" },
            },
            {
                spellID = 49184,
                name = "Howling Blast",
                priority = 3,
                why = "Only on Rime proc.",
                tags = { "core" },
                when = C.HasBuff(59052),
            },
            {
                spellID = 439843,
                name = "Reaper's Mark",
                priority = 4,
                why = "Deathbringer: on cooldown ahead of Pillar of Frost for the Exterminate payoff.",
                tags = { "core", "cd" },
                talentReq = "Deathbringer",
            },
            {
                spellID = 47568,
                name = "Empower Rune Weapon",
                priority = 5,
                why = "Before capping charges — RP plus a guaranteed Killing Machine.",
                tags = { "active" },
            },
            {
                spellID = 152279,
                name = "Breath of Sindragosa",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Alternative ST cooldown build — pool 60 RP first, extend the channel with Killing Machine/Rime procs. Mutually exclusive with spamming Empower Rune Weapon.",
                tags = { "cd" },
            },
            {
                spellID = 51271,
                name = "Pillar of Frost",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Align with Bloodlust, Reaper's Mark, and Frostwyrm's Fury.",
                tags = { "cd" },
            },
            {
                spellID = 279302,
                name = "Frostwyrm's Fury",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big burst — Chosen of Frostbrood grants a second, weaker cast within 45s.",
                tags = { "cd" },
            },
        },
    },
}
-- ── Unholy Death Knight (specID 252) ───────────────────────────────
-- MAJOR REWORK vs prior tiers — verify every spellID below in-game before
-- relying on it. Apocalypse is gone from the kit; Army of the Dead plus
-- the new Putrefy (a ghoul that leaps to your target and explodes) now
-- carry the burst-summon role. Festering Wound is renamed/reworked into
-- Lesser Ghoul stacks (Festering Strike still applies 2-3, Scourge Strike
-- still pops them 1 at a time); every other Festering Strike auto-converts
-- into Festering Scythe, a cone hit that also spreads plagues — there is
-- no separate button for it. Outbreak is replaced by Blightfall for the
-- duration of Dark Transformation, consuming every active plague within
-- 40yd for damage equal to their remaining duration and refunding Putrefy
-- charges. Soul Reaper is the execute (<35%).
-- Hero talents: San'layn (Vampiric Strike periodically replaces Scourge
-- Strike, with leech — good for M+ self-sustain) vs Rider of the
-- Apocalypse (rune spending has a chance to summon a Horseman; its
-- capstone can bring all Four Horsemen off Army of the Dead — Method.gg's
-- default for raid burst alignment).
-- Apex talent Forbidden Knowledge: for 30s after Army of the Dead, Death
-- Coil becomes Necrotic Coil (hits up to 3 targets in a line) and Epidemic
-- becomes Graveyard (uncapped AoE plague damage) — RP-dump priority
-- doesn't change, but its AoE ceiling does during that window.
-- Season 2 tier (Venomous Abyss): 2pc — empowers Magus of the Dead/Lord of
-- the Dead pet abilities (stronger Necrotic Bolt/Withering Grasp). 4pc —
-- empowered abilities (Putrefy, pet spells) deal 130% more damage to
-- targets below 35% — pairs directly with Soul Reaper execute windows, so
-- hold a Putrefy charge into execute range when it's close.
-- Sources cross-checked 2026-09-05: Icy Veins Unholy DK rotation guide,
-- Method.gg Unholy DK playstyle guide (Midnight 12.1), Wowhead Unholy DK
-- abilities/talents guide, Warcraft Wiki (Putrefy, Blightfall, Festering
-- Scythe, Forbidden Knowledge talent pages).
R[252] = { -- Unholy DK
    solo = {
        tip = "Unholy DK solo (San'layn for sustain, Rider of the Apocalypse for burst): Festering Strike stacks Lesser Ghoul, Scourge Strike/Vampiric Strike pops them, Death Coil dumps RP, Dark Transformation on cooldown. Apocalypse is gone — Army of the Dead + Putrefy now do that job.",
        priorities = {
            {
                spellID = 85948,
                name = "Festering Strike",
                priority = 1,
                why = "Builds 2-3 Lesser Ghoul stacks. Every other cast auto-converts into Festering Scythe, a cone that also spreads plagues.",
                tags = { "core" },
            },
            {
                spellID = 55090,
                name = "Scourge Strike",
                priority = 2,
                why = "Pops 1 Lesser Ghoul stack for damage.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike replaces this during Gift of the San'layn",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 3,
                why = "San'layn: replaces Scourge Strike during Gift of the San'layn — Shadow damage plus self-healing leech.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 47541,
                name = "Death Coil",
                priority = 4,
                why = "RP dump — free with Sudden Doom.",
                tags = { "core" },
            },
            {
                spellID = 63560,
                name = "Dark Transformation",
                priority = 5,
                why = "Pet steroid, +200% pet damage for 15s — use on cooldown, pairs with Putrefy.",
                tags = { "core" },
            },
            {
                spellID = 77575,
                name = "Outbreak",
                priority = 6,
                why = "Refresh Virulent Plague before it falls off.",
                tags = { "active" },
                when = C.DebuffRefresh(191587, 3),
            },
            {
                spellID = 1247378,
                name = "Putrefy",
                priority = 7,
                why = "Summons a ghoul that leaps to your target and explodes — solid single-target burst with light AoE splash. 2 charges, don't cap them.",
                tags = { "cd" },
            },
            {
                spellID = 42650,
                name = "Army of the Dead",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major cooldown — 8 ghouls over 4s. Pair with Dark Transformation, and with Forbidden Knowledge (Apex) your next 30s of Death Coil/Epidemic become AoE.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Unholy M+ (Rider of the Apocalypse favored for burst, San'layn for sustain): Death and Decay + Festering Scythe cone spread plagues fast, Epidemic for AoE RP dump (becomes uncapped Graveyard for 30s after Army of the Dead via Forbidden Knowledge).",
        chain = {
            { spellID = 77575, name = "Outbreak" },
            { spellID = 85948, name = "Festering Strike" },
            { spellID = 43265, name = "Death and Decay" },
            { spellID = 55090, name = "Scourge Strike" },
            { spellID = 207317, name = "Epidemic" },
        },
        priorities = {
            {
                spellID = 43265,
                name = "Death and Decay",
                priority = 1,
                why = "Ground AoE — extends Putrefy/Army of the Dead value with Cycle of Death, boosts Scourge Strike/Vampiric Strike cleave.",
                tags = { "core" },
            },
            {
                spellID = 85948,
                name = "Festering Strike",
                priority = 2,
                why = "Stack Lesser Ghoul on the primary target; every-other-cast Festering Scythe cone hits everything nearby and spreads plagues — your main AoE wound tool now.",
                tags = { "core" },
            },
            {
                spellID = 55090,
                name = "Scourge Strike",
                priority = 3,
                why = "Pop Lesser Ghoul stacks; cleaves inside Death and Decay.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 4,
                why = "San'layn: replaces Scourge Strike during Gift of the San'layn.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 207317,
                name = "Epidemic",
                priority = 5,
                why = "AoE RP dump, extends plague durations on every target hit. Becomes uncapped Graveyard for 30s after Army of the Dead (Forbidden Knowledge, Apex).",
                tags = { "core" },
            },
            {
                spellID = 77575,
                name = "Outbreak",
                priority = 6,
                why = "Disease maintenance across the pull.",
                tags = { "active" },
                when = C.DebuffRefresh(191587, 3),
            },
            {
                spellID = 1247378,
                name = "Putrefy",
                priority = 7,
                why = "On cooldown — hits your primary target plus moderate AoE splash. 2 charges, don't cap.",
                tags = { "cd" },
            },
            {
                spellID = 63560,
                name = "Dark Transformation",
                priority = 8,
                why = "On cooldown — pairs with Army of the Dead roughly every 45s in this build.",
                tags = { "core" },
            },
            {
                spellID = 42650,
                name = "Army of the Dead",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major cooldown — with Forbidden Knowledge your Death Coil/Epidemic go AoE for 30s; with Rider of the Apocalypse's capstone this can summon all Four Horsemen.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Unholy ST/raid (Rider of the Apocalypse default per Method.gg, San'layn alternative): Outbreak to open, wound up with Festering Strike, Army of the Dead/Dark Transformation on a tight ~45s cadence, Blightfall replaces Outbreak during Dark Transformation, Soul Reaper below 35%.",
        priorities = {
            {
                spellID = 77575,
                name = "Outbreak",
                priority = 1,
                why = "Apply/refresh Virulent Plague.",
                tags = { "core" },
                when = C.DebuffRefresh(191587, 3),
            },
            {
                spellID = 85948,
                name = "Festering Strike",
                priority = 2,
                why = "Build Lesser Ghoul stacks; every other cast becomes the Festering Scythe cone.",
                tags = { "core" },
            },
            {
                spellID = 63560,
                name = "Dark Transformation",
                priority = 3,
                why = "On cooldown, aligned tightly with Army of the Dead (~45s cadence in this build).",
                tags = { "core" },
            },
            {
                spellID = 1242616,
                name = "Blightfall",
                priority = 4,
                why = "Replaces Outbreak while Dark Transformation is active — consumes every plague within 40yd for damage equal to their remaining duration and refunds Putrefy charges.",
                tags = { "core" },
                when = C.Usable(),
            },
            {
                spellID = 1247378,
                name = "Putrefy",
                priority = 5,
                why = "During Dark Transformation for the big window, otherwise on cooldown. 2 charges.",
                tags = { "cd" },
            },
            {
                spellID = 343294,
                name = "Soul Reaper",
                priority = 6,
                why = "Execute — cast below 35%, consumes Lesser Ghoul stacks for extra damage and debuffs the target's minion/disease damage taken. Venomous Abyss 4pc makes empowered hits land much harder here.",
                tags = { "active" },
                when = C.Execute(35),
            },
            {
                spellID = 55090,
                name = "Scourge Strike",
                priority = 7,
                why = "Pop Lesser Ghoul stacks.",
                tags = { "core" },
                talentAlt = "San'layn: Vampiric Strike",
            },
            {
                spellID = 433901,
                name = "Vampiric Strike",
                priority = 8,
                why = "San'layn: replaces Scourge Strike during Gift of the San'layn.",
                tags = { "core" },
                talentReq = "San'layn",
                when = C.HasBuff(434152),
            },
            {
                spellID = 47541,
                name = "Death Coil",
                priority = 9,
                why = "RP dump — free with Sudden Doom, or Necrotic Coil (hits 3 in a line) during the post-Army of the Dead Forbidden Knowledge window.",
                tags = { "core" },
            },
            {
                spellID = 42650,
                name = "Army of the Dead",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major cooldown on a short (~45s) leash in this build — align with Dark Transformation and burst windows.",
                tags = { "cd" },
            },
        },
    },
}

-- ── DEMON HUNTER ──────────────────────────────────────────────────────
-- Havoc (577) and Vengeance (581) rewritten 2026-09-05 against Icy Veins'
-- current 12.1 (Midnight S2, Curse of Ula'tek: The Venomous Abyss) guides
-- ("DPS/Tank Rotation, Cooldowns, and Abilities" and "DPS/Tank Spec,
-- Builds, and Talents"), Method.gg's Havoc Playstyle & Rotation guide, and
-- warcraft.wiki.gg for the season 2 tier set. Devourer (Demon Hunter's new
-- third spec) is out of scope for this file — not listed here.
--
-- Midnight reshuffled the hero-talent pairings: Fel-Scarred is now
-- Havoc-exclusive, and Vengeance pairs Aldrachi Reaver with a brand-new
-- tree, Annihilator, instead. Aldrachi Reaver (both specs) builds Rending
-- Strike (ST) / Glaive Flurry (AoE) via Art of the Glaive builders and
-- spends them on the extra button Reaver's Glaive.
R[577] = { -- Havoc
    -- Hero trees: Fel-Scarred is the default pick this season for both raid
    -- and M+ — Metamorphosis triggers Demonsurge, upgrading the next Blade
    -- Dance/Chaos Strike into Death Sweep/Annihilation for a front-loaded
    -- ~2 min burst window; easier to execute. Aldrachi Reaver is
    -- competitive in higher M+ keys via Reaver's Glaive funnel damage.
    -- Apex Talent: Eternal Hunt — empowers Eye Beam after casting The Hunt,
    -- cuts The Hunt's cooldown by 15 sec/point, and resets Blade Dance's
    -- cooldown after a fully-channeled Eye Beam (why The Hunt and Eye Beam
    -- are paired below). Tier set (Abyssal Doomhound's Pursuit): 2pc Blade
    -- Dance/Chaos Strike/Essence Break deal 12% increased damage; 4pc
    -- Essence Break applies and benefits from Cycle of Hatred, +35%
    -- increased initial strike damage and +2.0 sec duration.
    solo = {
        tip = "Havoc solo: Demon's Bite to gen Fury, Chaos Strike (Annihilation in Metamorphosis) at 40+ Fury, Eye Beam and Blade Dance for AoE.",
        priorities = {
            {
                spellID = 162243,
                name = "Demon's Bite",
                priority = 1,
                why = "Fury generator — filler between spenders.",
                tags = { "core" },
            },
            {
                spellID = 162794,
                name = "Chaos Strike",
                priority = 2,
                why = "At 40+ Fury — primary ST spender. Becomes Annihilation while Metamorphosis is active.",
                tags = { "core" },
                when = C.PowerAtLeast(40),
            },
            {
                spellID = 198013,
                name = "Eye Beam",
                priority = 3,
                why = "Massive AoE/cleave — use on 2+ targets, or to build toward your next Metamorphosis.",
                tags = { "core" },
            },
            {
                spellID = 188499,
                name = "Blade Dance",
                priority = 4,
                why = "AoE + dodge. Becomes Death Sweep while Metamorphosis is active. Use on 2+ mobs.",
                tags = { "core" },
                when = C.AoE(2),
            },
            {
                spellID = 195072,
                name = "Fel Rush",
                priority = 5,
                why = "Mobility + damage — don't waste charges.",
                tags = { "active" },
            },
            {
                spellID = 232893,
                name = "Felblade",
                priority = 6,
                why = "Fury generator with a gap-closer — free to cast if already in melee range.",
                tags = { "active" },
            },
            {
                spellID = 191427,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst cooldown — Annihilation replaces Chaos Strike, Death Sweep replaces Blade Dance, plus extra mobility.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "M+ (Fel-Scarred default): Eye Beam to open every pull, Immolation Aura on CD, Death Sweep/Blade Dance + Glaive Tempest for cleave, Chaos Strike/Annihilation only to dump excess Fury. Essence Break before big pulls.",
        chain = {
            { spellID = 198013, name = "Eye Beam" },
            { spellID = 258920, name = "Immolation Aura" },
            { spellID = 188499, name = "Blade Dance" },
            { spellID = 342817, name = "Glaive Tempest" },
        },
        priorities = {
            {
                spellID = 198013,
                name = "Eye Beam",
                priority = 1,
                why = "Primary AoE — triggers Demonic (free Metamorphosis) and, with Fel-Scarred, the Demonsurge burst window.",
                tags = { "core" },
            },
            {
                spellID = 258920,
                name = "Immolation Aura",
                priority = 2,
                why = "AoE Fury generator, 2 charges — dump before Metamorphosis so it isn't wasted; it refunds a charge on Meta entry.",
                condition = "On cooldown, don't cap at 2 charges",
                tags = { "core" },
            },
            {
                spellID = 188499,
                name = "Blade Dance",
                priority = 3,
                why = "AoE + Fury spender, 12% increased damage from the season 2pc tier set. Called Death Sweep while Metamorphosis is active.",
                tags = { "core" },
                when = C.AoE(2),
            },
            {
                spellID = 342817,
                name = "Glaive Tempest",
                priority = 4,
                why = "Extra AoE cleave if talented.",
                tags = { "core" },
            },
            {
                spellID = 442294,
                name = "Reaver's Glaive",
                priority = 5,
                why = "Aldrachi Reaver only — consumes Rending Strike/Glaive Flurry stacks built by Art of the Glaive; funnels damage onto Reaver's Mark.",
                talentReq = "Aldrachi Reaver",
                tags = { "core" },
            },
            {
                spellID = 258860,
                name = "Essence Break",
                priority = nil,
                isCd = true,
                why = "Damage amplifier — hold slightly so it lands right as Eye Beam comes off cooldown. Season 4pc has it apply/benefit from Cycle of Hatred, +35% initial hit, +2 sec duration.",
                tags = { "cd" },
            },
            {
                spellID = 162794,
                name = "Chaos Strike",
                priority = 6,
                why = "Fury dump only in AoE — Annihilation while Metamorphosis is active. Don't let Fury cap.",
                tags = { "active" },
                when = C.PowerAtLeast(85),
            },
            {
                spellID = 162243,
                name = "Demon's Bite",
                priority = 7,
                why = "Filler for Fury generation.",
                tags = { "active" },
            },
            {
                spellID = 191427,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Every 1.5-2 min — align with a big pull. Fel-Scarred empowers Blade Dance/Chaos Strike via Demonsurge; Aldrachi Reaver extends duration and feeds more Reaver's Glaive procs.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Raid (Fel-Scarred default): Immolation Aura before Metamorphosis, Vengeful Retreat into Eye Beam, Essence Break timed to Eye Beam's cooldown, Death Sweep/Annihilation inside Metamorphosis to consume Demonsurge.",
        priorities = {
            {
                spellID = 258920,
                name = "Immolation Aura",
                priority = 1,
                why = "Dump both charges before entering Metamorphosis — it refunds a charge on Meta entry, so never waste it capped.",
                condition = "Before Metamorphosis / on cooldown",
                tags = { "core" },
            },
            {
                spellID = 370965,
                name = "The Hunt",
                priority = 2,
                why = "Empowers Eye Beam via the Eternal Hunt Apex talent, and grants a guaranteed Reaver's Glaive proc (Aldrachi Reaver). Use on cooldown, ideally lined up with Eye Beam.",
                tags = { "core", "cd" },
            },
            {
                spellID = 198793,
                name = "Vengeful Retreat → Eye Beam",
                priority = 3,
                why = "Vengeful Retreat grants Initiative/Exergy — immediately follow with Eye Beam to spend the buff at full value.",
                tags = { "core" },
            },
            {
                spellID = 198013,
                name = "Eye Beam",
                priority = 4,
                why = "Core rotational button outside Metamorphosis too — big cleave hit and Demonic trigger. Time it with The Hunt and Vengeful Retreat.",
                tags = { "core" },
            },
            {
                spellID = 258860,
                name = "Essence Break",
                priority = nil,
                isCd = true,
                why = "Hold if Eye Beam has ≤4 sec left on its cooldown so the amplify window covers it. Boosted by the 2pc (+12%) and 4pc (Cycle of Hatred proc, +35% initial hit, +2 sec duration).",
                tags = { "cd" },
            },
            {
                spellID = 442294,
                name = "Reaver's Glaive",
                priority = 5,
                why = "Aldrachi Reaver only — spend Rending Strike before it falls off.",
                talentReq = "Aldrachi Reaver",
                tags = { "core" },
            },
            {
                spellID = 188499,
                name = "Blade Dance",
                priority = 6,
                why = "On cooldown — inside Metamorphosis it's Death Sweep and triggers Demonsurge (Fel-Scarred), or consumes Rending Strike (Aldrachi Reaver).",
                tags = { "core" },
            },
            {
                spellID = 162794,
                name = "Chaos Strike",
                priority = 7,
                why = "Primary Fury spender — Annihilation during Metamorphosis, Chaos Strike outside it. Consumes Demonsurge procs after Death Sweep (Fel-Scarred).",
                tags = { "core" },
                when = C.PowerAtLeast(40),
            },
            {
                spellID = 232893,
                name = "Felblade",
                priority = 8,
                why = "Fury + gap-closer, especially valuable with Inertia to reset Fel Rush.",
                tags = { "active" },
            },
            {
                spellID = 191427,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Time it so Eye Beam and Blade Dance are already on cooldown before popping — Chaotic Transformation (Fel-Scarred) resets both, so popping early wastes the reset.",
                tags = { "cd" },
            },
        },
    },
}
R[581] = { -- Vengeance
    -- Hero trees: Aldrachi Reaver builds Rending Strike/Glaive Flurry via
    -- Art of the Glaive and spends them on Reaver's Glaive, with Wounded
    -- Quarry funneling extra-target damage/healing onto a priority target —
    -- popular for M+ self-sustain. Annihilator (new this expansion, replaces
    -- Fel-Scarred as Vengeance's second tree) stacks Voidfall off Fracture
    -- casts and automatically rains meteors at 3 stacks; World Killer cuts
    -- Metamorphosis's cooldown by 10 sec per meteor volley consumed — a
    -- cooldown-centric, bursty pick. Both are viable this tier.
    -- Apex Talent: Untethered Rage — consuming Soul Fragments (Spirit Bomb
    -- or Soul Cleave) has a chance to grant a second, 10-sec charge of
    -- Metamorphosis; further points raise fragments consumed and the proc
    -- chance, so don't hoard Metamorphosis once fragments are flowing.
    -- Tier set (Abyssal Doomhound's Pursuit): 2pc Sigil of Flame's DoT
    -- deals 50% increased damage and Soul Cleave extends its duration on
    -- your primary target by 2 sec; 4pc Immolation Aura and Sigil of Spite
    -- deal 100% increased damage to targets already afflicted by Sigil of
    -- Flame — pre-place Sigil of Flame before those cooldowns for value.
    solo = {
        tip = "Vengeance solo: Soul Cleave to heal, Immolation Aura on CD, Fracture for Soul Fragments, Sigil of Flame for extra AoE DoT. Extremely durable.",
        priorities = {
            {
                spellID = 228477,
                name = "Soul Cleave",
                priority = 1,
                why = "Heal + damage — spend Fury here; heals for more per Soul Fragment consumed.",
                tags = { "core" },
            },
            {
                spellID = 258920,
                name = "Immolation Aura",
                priority = 2,
                why = "Fury gen + AoE DoT, 2 charges — always on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 263642,
                name = "Fracture",
                priority = 3,
                why = "Generates 2 Soul Fragments and Fury.",
                tags = { "core" },
            },
            {
                spellID = 204596,
                name = "Sigil of Flame",
                priority = 4,
                why = "Ground AoE DoT — the season 2pc increases its damage-over-time by 50% and Soul Cleave extends it.",
                tags = { "core" },
            },
            {
                spellID = 204021,
                name = "Fiery Brand",
                priority = nil,
                isCd = true,
                why = "40% damage reduction on your target for 12 sec.",
                tags = { "defensive" },
            },
            {
                spellID = 187827,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency — massive armor + HP. Untethered Rage can grant a bonus charge once you're consuming fragments regularly.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "M+: Immolation Aura + Sigil of Flame to open, Spirit Bomb at 5+ Soul Fragments, Soul Cleave otherwise, Sigil of Spite/Soul Carver on CD. Annihilator's Voidfall meteors want more targets hit; Aldrachi Reaver's Wounded Quarry funnels onto a marked target.",
        chain = {
            { spellID = 258920, name = "Immolation Aura" },
            { spellID = 204596, name = "Sigil of Flame" },
            { spellID = 263642, name = "Fracture" },
            { spellID = 247454, name = "Spirit Bomb" },
        },
        priorities = {
            {
                spellID = 258920,
                name = "Immolation Aura",
                priority = 1,
                why = "AoE Fury generator — keep both charges from overcapping, especially at pull.",
                tags = { "core" },
            },
            {
                spellID = 204596,
                name = "Sigil of Flame",
                priority = 2,
                why = "Pre-place before pulls — the 2pc/4pc tier set reward keeping this active before Sigil of Spite/Immolation Aura land.",
                condition = "Pre-pull / on cooldown",
                tags = { "core" },
            },
            {
                spellID = 247454,
                name = "Spirit Bomb",
                priority = 3,
                why = "At 5+ Soul Fragments — the core AoE payoff, heal and damage together.",
                tags = { "core" },
                when = C.BuffStacks(203981, 5),
            },
            {
                spellID = 442294,
                name = "Reaver's Glaive",
                priority = 4,
                why = "Aldrachi Reaver only — consumes Glaive Flurry stacks from Art of the Glaive.",
                talentReq = "Aldrachi Reaver",
                tags = { "core" },
            },
            {
                spellID = 389860,
                name = "Sigil of Spite",
                priority = nil,
                isCd = true,
                why = "On cooldown — AoE damage, spawns 3 Soul Fragments, resets Art of the Glaive (Aldrachi Reaver). Season 4pc: +100% damage vs. Sigil of Flame targets.",
                tags = { "cd" },
            },
            {
                spellID = 207407,
                name = "Soul Carver",
                priority = nil,
                isCd = true,
                why = "Strong AoE cooldown, spawns extra Soul Fragments — line up with Spirit Bomb.",
                tags = { "cd" },
            },
            {
                spellID = 228477,
                name = "Soul Cleave",
                priority = 5,
                why = "Under 5 Soul Fragments — spend here instead of waiting on Spirit Bomb.",
                tags = { "core" },
                when = C.Not(C.BuffStacks(203981, 5)),
            },
            {
                spellID = 263642,
                name = "Fracture",
                priority = 6,
                why = "Keep on cooldown for Fury and Soul Fragments — also feeds Annihilator's Voidfall stacks.",
                tags = { "active" },
            },
            {
                spellID = 212084,
                name = "Fel Devastation",
                priority = nil,
                isCd = true,
                why = "AoE damage + self-heal — great with multiple targets, or paired with a Fiery Brand target for extra Fire synergy (Annihilator).",
                tags = { "cd" },
            },
            {
                spellID = 204021,
                name = "Fiery Brand",
                priority = nil,
                isCd = true,
                why = "Rotate onto the hardest-hitting target — Down in Flames gives a 2nd charge for more frequent use.",
                tags = { "defensive" },
            },
            {
                spellID = 187827,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Strongest single button in the kit — simultaneously your best offensive and defensive cooldown. Annihilator wants it aligned with a fresh Voidfall meteor volley; Untethered Rage often refunds a second charge from fragment consumption.",
                tags = { "cd", "defensive" },
            },
        },
    },
    st = {
        tip = "Raid: Soul Cleave for healing under 5 Fragments, Fracture for Fragments, Immolation Aura + Sigil of Flame on CD, Spirit Bomb only above 5 Fragments, Fiery Brand for tank swaps/dangerous hits.",
        priorities = {
            {
                spellID = 228477,
                name = "Soul Cleave",
                priority = 1,
                why = "Primary heal + spend — under 5 Soul Fragments, use this instead of Spirit Bomb.",
                tags = { "core" },
                when = C.Not(C.BuffStacks(203981, 5)),
            },
            {
                spellID = 263642,
                name = "Fracture",
                priority = 2,
                why = "Soul Fragment + Fury generator, on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 258920,
                name = "Immolation Aura",
                priority = 3,
                why = "Fury generator on cooldown — watch for overcapping charges.",
                tags = { "core" },
            },
            {
                spellID = 204596,
                name = "Sigil of Flame",
                priority = 4,
                why = "Extra damage, and with the season tier set sets up Sigil of Spite/Immolation Aura for +100% damage.",
                tags = { "core" },
            },
            {
                spellID = 442294,
                name = "Reaver's Glaive",
                priority = 5,
                why = "Aldrachi Reaver only — spend Rending Strike before it falls off.",
                talentReq = "Aldrachi Reaver",
                tags = { "core" },
            },
            {
                spellID = 247454,
                name = "Spirit Bomb",
                priority = 6,
                why = "At 5+ Soul Fragments — bigger AoE heal/damage than Soul Cleave, but don't hold fragments waiting for it on single-target.",
                tags = { "core" },
                when = C.BuffStacks(203981, 5),
            },
            {
                spellID = 389860,
                name = "Sigil of Spite",
                priority = nil,
                isCd = true,
                why = "On cooldown — extra Soul Fragments, and with the 4pc tier set 100% more damage against Sigil of Flame targets.",
                tags = { "cd" },
            },
            {
                spellID = 207407,
                name = "Soul Carver",
                priority = nil,
                isCd = true,
                why = "Cooldown — big single-target hit plus Soul Fragments.",
                tags = { "cd" },
            },
            {
                spellID = 204021,
                name = "Fiery Brand",
                priority = nil,
                isCd = true,
                why = "Tank-buster mitigation — Down in Flames gives a 2nd charge; Annihilator gets bonus Fire damage pairing it with Metamorphosis.",
                tags = { "defensive" },
            },
            {
                spellID = 187827,
                name = "Metamorphosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Use on cooldown around dangerous raid damage — Untethered Rage often grants a bonus charge from fragment consumption, so don't hold it too preciously.",
                tags = { "defensive" },
            },
        },
    },
}

-- ── DRUID ─────────────────────────────────────────────────────────────
-- ── DRUID ─────────────────────────────────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek — The Venomous Abyss). Sources cross-checked: Icy Veins'
-- rotation/cooldown and talent pages for Balance, Feral, Guardian, and
-- Restoration (all current 12.1), Wowhead live spell pages (used to verify
-- spellIDs for new/reworked Midnight abilities — Chomp, Feral Frenzy,
-- Frantic Frenzy, Ravage, Lunar Beam, Red Moon, Raze, Wild Guardian, Dream
-- Burst, Everbloom), and Method.gg's Balance/Feral/Guardian/Restoration
-- guides for hero-talent-tree recommendations. Long-standing baseline
-- abilities (Moonfire, Sunfire, Rip, Rake, Mangle, Rejuvenation, etc.) keep
-- their long-stable IDs; verify with GetSpellInfo() in-game if anything
-- looks off after a hotfix.
--
-- Every Druid spec now runs one of two Hero Talent trees that pair up
-- across specs: Elune's Chosen (Balance+Feral), Keeper of the Grove
-- (Balance+Restoration), Druid of the Claw (Feral+Guardian), and
-- Wildstalker (Guardian+Restoration). Tips below name the current
-- guide-recommended default per spec and call out what changes on the
-- alternative.
--
-- Season 2 tier set for all four specs is Bark of the Enigmatic
-- Dreamwatcher (Curse of Ula'tek). Its 2pc/4pc effects differ per spec and
-- are called out in each spec's header comment below and folded into the
-- relevant entries' `why` text rather than modeled as new schema fields.

-- ── Balance Druid (specID 102) ───────────────────────────────────────
-- Two Hero Talent trees: Elune's Chosen (Icy Veins' pick for both raid
-- single-target and most Mythic+ — Lunar Calling removes Solar Eclipse so
-- you always cast Starfire, giving the highest sustained/cleave damage) and
-- Keeper of the Grove (short-cooldown burst via Dream Burst and Force of
-- Nature, only ahead when targets die very fast). Tips below assume
-- Elune's Chosen and call out the Keeper swap.
--
-- Apex Talent — Ascendant Eclipses — is the single biggest priority driver:
-- rank 1 makes your first Wrath/Starfire after an Eclipse pops instant, and
-- buffs the first 3 Starsurges/Starfalls cast during that Eclipse by 20%;
-- rank 3 has Eclipse activation itself launch auto-crit Solar/Lunar bolts.
-- This is why you dump Astral Power the instant Eclipse starts instead of
-- banking it through the whole window.
--
-- Season 2 tier (Bark of the Enigmatic Dreamwatcher): 2pc — Starsurge
-- damage +20%, and Starfall also deals instant Astral damage to everything
-- in its radius on cast (so it's worth pressing even at 1 target). 4pc —
-- flat +10% damage while in any Eclipse, tapering to +2% at the Eclipse
-- midpoint and back to +10% at the end — reinforces "spend big at Eclipse
-- start/end, coast through the middle."
R[1480] = { -- Devourer (Demon Hunter, ranged Intellect DPS -- new in Midnight)
    -- Added 2026-09-16: spec had no rotation data (fell through to R.fallback).
    -- Sources: Icy Veins Devourer rotation (12.1) and Wowhead Devourer rotation guide;
    -- every spellID below verified against Wowhead tooltips.
    -- Hero trees: Void-Scarred is Icy Veins' pick for both raid and M+ (faster ramp,
    -- easier access to cooldown windows); Annihilator is the alternative.
    -- Resources: Consume generates Fury + Soul Fragments; Reap spends 4+ souls;
    -- Void Ray channels at 100 Fury; Void Metamorphosis is entered once enough souls
    -- are gathered and lasts while Fury holds out.
    solo = {
        tip = "Devourer solo: Consume to build Fury and souls, Reap at 4+ souls, Void Ray at 100 Fury, Void Metamorphosis when souls allow. Soul Immolation up before pulls.",
        priorities = {
            { spellID = 1241937, name = "Soul Immolation", priority = 1, why = "Keep active -- precast ~2 sec before a pull.", tags = { "core" } },
            { spellID = 1226019, name = "Reap", priority = 2, why = "Spend at 4+ Soul Fragments.", tags = { "core" } },
            { spellID = 473728, name = "Void Ray", priority = 3, why = "Channel at 100 Fury -- your main Fury spender.", tags = { "core" }, when = C.PowerAtLeast(100) },
            { spellID = 1239519, name = "Hungering Slash", priority = 4, why = "Use whenever available.", tags = { "active" } },
            { spellID = 473662, name = "Consume", priority = 5, why = "Filler -- generates Fury and a Soul Fragment.", tags = { "active" } },
            { spellID = 1217607, name = "Void Metamorphosis", priority = nil, isCd = true, isMajorCd = true, why = "Enter once you have the souls for it; the form lasts while Fury holds.", tags = { "cd" } },
            { spellID = 1246167, name = "The Hunt", priority = nil, isCd = true, why = "On cooldown.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Devourer ST (Void-Scarred): Consume when it procs Soulburst, Reap at 4+ souls, keep Soul Immolation up, Voidblade right before Void Metamorphosis (Vengeful Retreat after it if The Hunt is ready), Hungering Slash, Void Ray at 100 Fury, Consume filler.",
        priorities = {
            { spellID = 1226019, name = "Reap", priority = 1, why = "At 4+ Soul Fragments.", tags = { "core" } },
            { spellID = 1241937, name = "Soul Immolation", priority = 2, why = "If not active.", tags = { "core" } },
            { spellID = 1245412, name = "Voidblade", priority = 3, why = "Right before entering Void Metamorphosis.", tags = { "core" } },
            { spellID = 198793, name = "Vengeful Retreat", priority = 4, why = "After Voidblade when The Hunt is available.", tags = { "active" } },
            { spellID = 1239519, name = "Hungering Slash", priority = 5, why = "As available.", tags = { "active" } },
            { spellID = 473728, name = "Void Ray", priority = 6, why = "With 100+ Fury (outside Void Metamorphosis).", tags = { "core" }, when = C.PowerAtLeast(100) },
            { spellID = 473662, name = "Consume", priority = 7, why = "Filler; move it to the top when it will proc Soulburst.", tags = { "active" } },
            { spellID = 1246167, name = "The Hunt", priority = nil, isCd = true, why = "On cooldown.", tags = { "cd" } },
            { spellID = 1217607, name = "Void Metamorphosis", priority = nil, isCd = true, isMajorCd = true, why = "With enough souls -- use potion and trinkets with it.", tags = { "cd" } },
            { spellID = 1221167, name = "Collapsing Star", priority = nil, isCd = true, why = "Burst inside Void Metamorphosis (Annihilator leans on it most).", tags = { "cd" } },
        },
    },
    aoe = {
        tip = "Devourer AoE (outside Void Metamorphosis): Consume with Soulburst, Eradicate at 10 souls or before its buff expires, Void Ray at 100 Fury, Voidblade before transforming, The Hunt, then Void Metamorphosis.",
        priorities = {
            { spellID = 1226033, name = "Eradicate", priority = 1, why = "At 10 Soul Fragments, or before its buff expires.", tags = { "core" } },
            { spellID = 473728, name = "Void Ray", priority = 2, why = "At 100 Fury.", tags = { "core" }, when = C.PowerAtLeast(100) },
            { spellID = 1245412, name = "Voidblade", priority = 3, why = "Before entering Void Metamorphosis.", tags = { "core" } },
            { spellID = 1226019, name = "Reap", priority = 4, why = "At 4+ souls.", tags = { "core" } },
            { spellID = 473662, name = "Consume", priority = 5, why = "Filler; top priority when it procs Soulburst.", tags = { "active" } },
            { spellID = 1246167, name = "The Hunt", priority = nil, isCd = true, why = "On cooldown.", tags = { "cd" } },
            { spellID = 1217607, name = "Void Metamorphosis", priority = nil, isCd = true, isMajorCd = true, why = "With sufficient souls.", tags = { "cd" } },
        },
    },
}

R[102] = { -- Balance
    solo = {
        tip = "Balance solo leveling: Moonfire/Sunfire to DoT, Wrath/Starfire generate Astral Power, Starsurge as the AP dump. Eclipse-triggering cooldowns unlock progressively.",
        priorities = {
            {
                spellID = 93402,
                name = "Sunfire",
                priority = 1,
                why = "Maintain DoT and spread — also generates Astral Power on tick.",
                tags = { "core" },
                when = C.DebuffRefresh(164815, 3),
            },
            {
                spellID = 8921,
                name = "Moonfire",
                priority = 2,
                why = "Maintain DoT on target — generates Astral Power on tick.",
                tags = { "core" },
                when = C.DebuffRefresh(164812, 3),
            },
            {
                spellID = 78674,
                name = "Starsurge",
                priority = 3,
                why = "At 40+ Astral Power — primary spender, and the tier 2pc's +20% damage makes it worth prioritizing over fillers.",
                tags = { "core" },
                when = C.PowerAtLeast(40),
            },
            {
                spellID = 190984,
                name = "Wrath",
                priority = 4,
                why = "Solar filler — faster cast, generates Astral Power. Free/instant right after an Ascendant Eclipses proc.",
                tags = { "active" },
            },
            {
                spellID = 194153,
                name = "Starfire",
                priority = 5,
                why = "Lunar filler — AoE cleave, generates Astral Power.",
                tags = { "active" },
            },
            {
                spellID = 191034,
                name = "Starfall",
                priority = nil,
                isCd = true,
                unlockLv = 20,
                why = "3+ targets, or spend at 50 AP even on one target for the tier 2pc's instant Astral burst.",
                tags = { "cd" },
            },
            {
                spellID = 205636,
                name = "Force of Nature",
                priority = nil,
                isCd = true,
                unlockLv = 30,
                why = "Not yet unlocked. Summons 3 Treants that generate Astral Power — bigger priority under Keeper of the Grove.",
                tags = { "cd" },
            },
            {
                spellID = 202770,
                name = "Fury of Elune",
                priority = nil,
                isCd = true,
                unlockLv = 40,
                why = "Not yet unlocked. 1-min CD beam — 40 Astral Power over its duration, use on cooldown.",
                tags = { "cd" },
            },
            {
                spellID = 194223,
                name = "Celestial Alignment",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 45,
                why = "Major burst — both Eclipses active plus Haste. Replaced by Incarnation: Chosen of Elune once talented.",
                tags = { "cd" },
                talentAlt = "Incarnation: Chosen of Elune",
            },
            {
                spellID = 102560,
                name = "Incarnation: Chosen of Elune",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 90,
                why = "Not yet unlocked. Upgraded Celestial Alignment — longer duration plus bonus Crit, and Ascendant Eclipses rank 3 launches auto-crit bolts on activation.",
                tags = { "cd" },
                talentReq = "Incarnation: Chosen of Elune",
            },
        },
    },
    aoe = {
        tip = "Balance AoE/M+ (Elune's Chosen): keep Starfall active as the AoE aura, spread Sunfire, and Starfire is free cleave since Lunar Calling removes Solar Eclipse entirely. Keeper of the Grove trades this for Dream Burst/Force of Nature burst when packs die fast.",
        chain = {
            { spellID = 191034, name = "Starfall" },
            { spellID = 93402, name = "Sunfire" },
            { spellID = 194153, name = "Starfire" },
        },
        priorities = {
            {
                spellID = 191034,
                name = "Starfall",
                priority = 1,
                why = "Keep it active on pulls — sustained AoE damage aura, and tier 2pc makes the cast itself hit everything in range instantly too.",
                tags = { "core" },
                when = C.AoE(3),
            },
            {
                spellID = 93402,
                name = "Sunfire",
                priority = 2,
                why = "Spread and maintain on all targets — Astral Power engine for the pull.",
                tags = { "core" },
                when = C.DebuffRefresh(164815, 3),
            },
            {
                spellID = 194153,
                name = "Starfire",
                priority = 3,
                why = "Lunar cleave filler — hits all nearby targets, free of the old Solar/Lunar tradeoff under Elune's Chosen.",
                tags = { "core" },
            },
            {
                spellID = 78674,
                name = "Starsurge",
                priority = 4,
                why = "Dump Astral Power here on 8 or fewer targets — beyond that, Starfall/Starfire out-damage it per cast.",
                tags = { "active" },
                when = C.And(C.PowerAtLeast(40), C.Not(C.AoE(9))),
            },
            {
                spellID = 8921,
                name = "Moonfire",
                priority = 5,
                why = "Maintain on high-value or high-HP adds Sunfire hasn't reached yet.",
                tags = { "active" },
                when = C.DebuffRefresh(164812, 4),
            },
            {
                spellID = 205636,
                name = "Force of Nature",
                priority = nil,
                isCd = true,
                why = "On cooldown — Treants cleave everything nearby. The centerpiece of a Keeper of the Grove AoE pull.",
                tags = { "cd" },
            },
            {
                spellID = 202770,
                name = "Fury of Elune",
                priority = nil,
                isCd = true,
                why = "On cooldown — beam hits everything it crosses, ramps Astral Power fast for the next Eclipse.",
                tags = { "cd" },
            },
            {
                spellID = 194223,
                name = "Celestial Alignment",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Pop on big packs — both Eclipses active for the whole window. Replaced by Incarnation once talented.",
                tags = { "cd" },
                talentAlt = "Incarnation: Chosen of Elune",
            },
            {
                spellID = 102560,
                name = "Incarnation: Chosen of Elune",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Pop on big packs — Ascendant Eclipses rank 3 auto-crit bolts hit every nearby enemy on activation.",
                tags = { "cd" },
                talentReq = "Incarnation: Chosen of Elune",
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = nil,
                isCd = true,
                why = "On cooldown under 40 AP so it doesn't waste overcapped Astral Power — random spells hit everything nearby.",
                tags = { "cd" },
                when = C.PowerBelow(40),
            },
        },
    },
    st = {
        tip = "Balance Raid ST (Elune's Chosen): dump Astral Power into Starsurge/Starfall the instant Eclipse pops for the Ascendant Eclipses + tier 2pc burst, coast on Wrath/Starfire the rest of the window, never let a DoT lapse. Align Celestial Alignment/Incarnation, Fury of Elune, Force of Nature, and Convoke with Bloodlust.",
        priorities = {
            {
                spellID = 78674,
                name = "Starsurge",
                priority = 1,
                why = "At 40+ Astral Power — spend immediately on an Eclipse pop for the Ascendant Eclipses damage window, and always for the tier 2pc's +20% damage.",
                tags = { "core" },
                when = C.PowerAtLeast(40),
            },
            {
                spellID = 93402,
                name = "Sunfire",
                priority = 2,
                why = "Never let this fall off — Astral Power income and raw damage both suffer.",
                tags = { "core" },
                when = C.DebuffRefresh(164815, 3),
            },
            {
                spellID = 8921,
                name = "Moonfire",
                priority = 3,
                why = "Maintain alongside Sunfire — same Pandemic-window refresh rule.",
                tags = { "core" },
                when = C.DebuffRefresh(164812, 3),
            },
            {
                spellID = 191034,
                name = "Starfall",
                priority = 4,
                why = "Spend at 50 AP even on single target — tier 2pc makes the cast itself deal instant Astral damage, so it competes with Starsurge as a spender now.",
                tags = { "core" },
                when = C.PowerAtLeast(50),
            },
            {
                spellID = 190984,
                name = "Wrath",
                priority = 5,
                why = "Solar filler — free and instant right after an Ascendant Eclipses proc, so cast it first when that's up.",
                tags = { "active" },
            },
            {
                spellID = 194153,
                name = "Starfire",
                priority = 6,
                why = "Lunar filler when Wrath's proc isn't up.",
                tags = { "active" },
            },
            {
                spellID = 205636,
                name = "Force of Nature",
                priority = nil,
                isCd = true,
                why = "On cooldown, ideally lined up with an Eclipse — bonus Astral Power and damage from the Treants.",
                tags = { "cd" },
            },
            {
                spellID = 202770,
                name = "Fury of Elune",
                priority = nil,
                isCd = true,
                why = "On cooldown — line up with cooldown windows and Bloodlust when possible.",
                tags = { "cd" },
            },
            {
                spellID = 194223,
                name = "Celestial Alignment",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst — align with Bloodlust. Replaced by Incarnation once talented.",
                tags = { "cd" },
                talentAlt = "Incarnation: Chosen of Elune",
            },
            {
                spellID = 102560,
                name = "Incarnation: Chosen of Elune",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst, aligned with Bloodlust — longer window and bonus Crit over base Celestial Alignment.",
                tags = { "cd" },
                talentReq = "Incarnation: Chosen of Elune",
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = nil,
                isCd = true,
                why = "Cast under 40 AP inside your major cooldown window so it never overlaps a manual Astral Power dump.",
                tags = { "cd" },
                when = C.PowerBelow(40),
            },
        },
    },
}

-- ── Feral Druid (specID 103) ─────────────────────────────────────────
-- Hero Talents: Druid of the Claw (raid single-target default — Claw
-- Rampage procs from Swipe during Berserk grant Ravage, and Tear Down the
-- Mighty amplifies Feral Frenzy/Chomp) and Wildstalker (AoE-leaning
-- alternative — Strategic Infusion boosts Shred during Tiger's Fury,
-- smoother multi-target transitions). Icy Veins calls the two "close enough
-- that it almost comes down to preference" for raid ST; tips below default
-- to Druid of the Claw and call out the Wildstalker AoE difference.
--
-- Apex Talent — Unseen Predator — is the reason "always finish at 5 combo
-- points" is now a hard rule, not just Rip/Bite efficiency: Ferocious Bite
-- has a per-combo-point chance to proc Unseen Slash (or Unseen Swipe in
-- AoE), which grants a stacking damage buff that lasts as long as the combo
-- points spent to trigger it. Rank 4 also boosts Rip damage 30% and makes
-- Tiger's Fury guarantee two max-strength procs.
--
-- Season 2 tier (Bark of the Enigmatic Dreamwatcher): 2pc — when Berserk
-- ends, gain 10% damage for 1 second per combo point spent during it. 4pc —
-- Berserk lasts 10 seconds longer. No new buttons, but a harder push to
-- spend every combo point during Berserk/Tiger's Fury windows rather than
-- banking them.
R[103] = { -- Feral
    solo = {
        tip = "Feral solo leveling: Rake from Prowl, Shred to build combo points, Rip to maintain the bleed, Ferocious Bite to finish at 5 CP. Chomp, Feral Frenzy, and Berserk unlock progressively.",
        priorities = {
            {
                spellID = 1822,
                name = "Rake",
                priority = 1,
                why = "Maintain the bleed — massively stronger from Prowl/Stealth, so open with it.",
                tags = { "core" },
                when = C.DebuffRefresh(155722, 3),
            },
            {
                spellID = 5221,
                name = "Shred",
                priority = 2,
                why = "Primary combo point generator.",
                tags = { "core" },
            },
            {
                spellID = 1079,
                name = "Rip",
                priority = 3,
                why = "At 5 combo points — apply and maintain, never let it lapse.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 22568,
                name = "Ferocious Bite",
                priority = 4,
                why = "At 5 combo points with Rip already up — finisher, and each cast has a chance to proc Unseen Predator (Apex Talent).",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 1244258,
                name = "Chomp",
                priority = nil,
                unlockLv = 15,
                why = "Not yet unlocked. Energy-efficient finisher-adjacent filler — use on cooldown once available.",
                tags = { "active" },
            },
            {
                spellID = 5217,
                name = "Tiger's Fury",
                priority = nil,
                isCd = true,
                unlockLv = 20,
                why = "Not yet unlocked. Instant Energy plus a damage buff — snapshots your bleeds, so refresh Rake/Rip right after.",
                tags = { "cd" },
            },
            {
                spellID = 274837,
                name = "Feral Frenzy",
                priority = nil,
                isCd = true,
                unlockLv = 40,
                why = "Not yet unlocked. Instant bleed plus combo points — use on cooldown, ideally inside Tiger's Fury.",
                tags = { "cd" },
            },
            {
                spellID = 106951,
                name = "Berserk",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 90,
                why = "Not yet unlocked. Major burst — sync with Tiger's Fury. Replaced by Incarnation once talented.",
                tags = { "cd" },
                talentAlt = "Incarnation: Avatar of Ashamane",
            },
            {
                spellID = 102543,
                name = "Incarnation: Avatar of Ashamane",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 90,
                why = "Not yet unlocked. Upgraded Berserk — cheaper abilities and a free in-combat Prowl for an empowered Rake.",
                tags = { "cd" },
                talentReq = "Incarnation: Avatar of Ashamane",
            },
        },
    },
    aoe = {
        tip = "Feral AoE/M+: Primal Wrath at 5 CP for AoE Rip plus bleed spread, Chomp/Swipe for combo points (fish Claw Rampage under Druid of the Claw), Rake cycled across the top 2-3 HP targets, Berserk/Tiger's Fury/Feral Frenzy/Frantic Frenzy stacked together on the pull.",
        chain = {
            { spellID = 285381, name = "Primal Wrath" },
            { spellID = 106785, name = "Swipe" },
            { spellID = 1822, name = "Rake" },
        },
        priorities = {
            {
                spellID = 5217,
                name = "Tiger's Fury",
                priority = 1,
                isCd = true,
                why = "On cooldown at 70+ Energy below cap — line up Berserk and Feral Frenzy/Frantic Frenzy inside it.",
                tags = { "core", "cd" },
            },
            {
                spellID = 285381,
                name = "Primal Wrath",
                priority = 2,
                why = "At 5 combo points — applies Rip and a bleed to every nearby target if inactive or in Pandemic range.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 274837,
                name = "Feral Frenzy",
                priority = nil,
                isCd = true,
                why = "On cooldown, during Tiger's Fury — instant bleed plus combo points on your primary target.",
                tags = { "cd" },
            },
            {
                spellID = 1243807,
                name = "Frantic Frenzy",
                priority = nil,
                isCd = true,
                why = "On cooldown, during Tiger's Fury when possible.",
                tags = { "cd" },
            },
            {
                spellID = 106785,
                name = "Swipe",
                priority = 3,
                why = "Combo point generator on 3+ targets — also fishes for Claw Rampage procs during Berserk under Druid of the Claw.",
                tags = { "core" },
                when = C.AoE(3),
            },
            {
                spellID = 1822,
                name = "Rake",
                priority = 4,
                why = "Cycle across the 2-3 highest-HP targets — refresh before Tiger's Fury fades to snapshot the bleed.",
                tags = { "active" },
            },
            {
                spellID = 22568,
                name = "Ferocious Bite",
                priority = 5,
                why = "With an Apex Predator's Craving proc, or at 5 CP/50+ Energy with Rips already active for Rampant Ferocity.",
                tags = { "active" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 5221,
                name = "Shred",
                priority = 6,
                why = "Fallback combo point generator below 3 targets.",
                tags = { "active" },
                when = C.Not(C.AoE(3)),
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = nil,
                isCd = true,
                why = "During Berserk, before Tiger's Fury expires and at low combo points, so its random casts aren't wasted overcapping.",
                tags = { "cd" },
                when = C.ComboBelow(3),
            },
            {
                spellID = 106951,
                name = "Berserk",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big AoE burst — synced with Tiger's Fury. Replaced by Incarnation once talented.",
                tags = { "cd" },
                talentAlt = "Incarnation: Avatar of Ashamane",
            },
            {
                spellID = 102543,
                name = "Incarnation: Avatar of Ashamane",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Big AoE burst, synced with Tiger's Fury — grants an in-combat Prowl for an empowered Rake on the pull.",
                tags = { "cd" },
                talentReq = "Incarnation: Avatar of Ashamane",
            },
        },
    },
    st = {
        tip = "Feral Raid ST (Druid of the Claw): Tiger's Fury on cooldown anchors everything else — Berserk synced with it, Feral Frenzy/Frantic Frenzy inside it, Chomp on cooldown, Rip/Rake kept up via Pandemic refresh, Ferocious Bite/Convoke round out the finisher windows.",
        priorities = {
            {
                spellID = 5217,
                name = "Tiger's Fury",
                priority = 1,
                isCd = true,
                why = "On cooldown, aiming for 5 combo points or 50 Energy below cap when you press it.",
                tags = { "core", "cd" },
            },
            {
                spellID = 106951,
                name = "Berserk",
                priority = 2,
                isCd = true,
                isMajorCd = true,
                why = "On cooldown, synced with Tiger's Fury — most of your burst happens here. Replaced by Incarnation once talented.",
                tags = { "core", "cd" },
                talentAlt = "Incarnation: Avatar of Ashamane",
            },
            {
                spellID = 102543,
                name = "Incarnation: Avatar of Ashamane",
                priority = 2,
                isCd = true,
                isMajorCd = true,
                why = "On cooldown, synced with Tiger's Fury — cheaper abilities plus an empowered Prowl-Rake.",
                tags = { "core", "cd" },
                talentReq = "Incarnation: Avatar of Ashamane",
            },
            {
                spellID = 274837,
                name = "Feral Frenzy",
                priority = 3,
                isCd = true,
                why = "On cooldown, during Tiger's Fury.",
                tags = { "core", "cd" },
            },
            {
                spellID = 1243807,
                name = "Frantic Frenzy",
                priority = 4,
                isCd = true,
                why = "On cooldown, preferably during Tiger's Fury.",
                tags = { "core", "cd" },
            },
            {
                spellID = 1244258,
                name = "Chomp",
                priority = 5,
                why = "On cooldown — efficient filler damage between finishers.",
                tags = { "core" },
            },
            {
                spellID = 22568,
                name = "Ferocious Bite",
                priority = 6,
                why = "With an Apex Predator's Craving proc — always take the free cast.",
                tags = { "core" },
            },
            {
                spellID = 1079,
                name = "Rip",
                priority = 7,
                why = "At 5 combo points if inactive or in Pandemic range — snapshot during Tiger's Fury when you can.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = 8,
                isCd = true,
                why = "Lined up with Berserk plus Tiger's Fury, at low combo points so its random casts aren't wasted.",
                tags = { "cd" },
                when = C.ComboBelow(3),
            },
            {
                spellID = 22568,
                name = "Ferocious Bite",
                priority = 9,
                why = "At 5 combo points with Rip active and 50+ Energy — standard finisher.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 1822,
                name = "Rake",
                priority = 10,
                why = "If inactive or in Pandemic range — refresh before Tiger's Fury fades to snapshot the bleed.",
                tags = { "core" },
                when = C.DebuffRefresh(155722, 4),
            },
            {
                spellID = 8921,
                name = "Moonfire",
                priority = 11,
                why = "If inactive or in Pandemic range — only with Lunar Inspiration talented.",
                tags = { "active" },
                talentReq = "Lunar Inspiration",
                when = C.DebuffRefresh(155625, 4),
            },
            {
                spellID = 5221,
                name = "Shred",
                priority = 12,
                why = "Combo point generator — filler when nothing above is ready.",
                tags = { "active" },
            },
        },
    },
}

-- ── Guardian Druid (specID 104) ──────────────────────────────────────
-- Hero Talents: Druid of the Claw (default recommendation for both raid
-- single-target and Mythic+ — reduces Thrash/Mangle cooldowns and makes
-- Mangle hit 3 targets during Incarnation) and Wildstalker (secondary
-- option, closer in AoE-heavy content). Tips below assume Druid of the
-- Claw.
--
-- Apex Talent — Wild Guardian — turns your Thrash/Red Moon spirit damage
-- into passive Rage income, but only while Mangle/Raze keep landing at
-- least once every 12 seconds — so "never let the Mangle/Raze window
-- lapse" is now a Rage-income rule, not just a damage one.
--
-- Season 2 tier (Bark of the Enigmatic Dreamwatcher): 2pc — Thrash has a
-- 20% chance to make your next Mangle deal 100% increased damage (hold
-- Mangle a beat if this just proc'd and you're not already at risk).
-- 4pc — Thrash calls down up to 3 thorns that each impale a target for
-- Nature damage, and extends Incarnation: Guardian of Ursoc by 5 seconds.
R[104] = { -- Guardian
    solo = {
        tip = "Guardian solo leveling: Mangle for Rage and the hardest single hit, Thrash for bleed stacks, Ironfur to mitigate, Raze/Swipe to spend leftover Rage. Pull big — Guardian is built to solo packs.",
        priorities = {
            {
                spellID = 33917,
                name = "Mangle",
                priority = 1,
                why = "Primary Rage generator and hardest hit — keep landing at least every 12s to sustain Wild Guardian's passive Rage income.",
                tags = { "core" },
            },
            {
                spellID = 77758,
                name = "Thrash",
                priority = 2,
                why = "Maintain bleed stacks — also the spirit-damage source that feeds Wild Guardian (Apex Talent) Rage.",
                tags = { "core" },
                when = C.DebuffRefresh(192090, 3),
            },
            {
                spellID = 400254,
                name = "Raze",
                priority = 3,
                unlockLv = 15,
                why = "Not yet unlocked. Frontal-cone Rage spender — primary offensive dump once available.",
                tags = { "active" },
            },
            {
                spellID = 213764,
                name = "Swipe",
                priority = 4,
                why = "AoE filler Rage spender before Raze unlocks, or as a secondary dump afterward.",
                tags = { "active" },
            },
            {
                spellID = 192081,
                name = "Ironfur",
                priority = 5,
                why = "Active mitigation — spend excess Rage here before a big incoming hit.",
                tags = { "defensive" },
            },
            {
                spellID = 22842,
                name = "Frenzied Regeneration",
                priority = 6,
                why = "Below 70% health — strong heal over time off banked Rage/HP.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 22812,
                name = "Barkskin",
                priority = nil,
                isCd = true,
                unlockLv = 20,
                why = "Not yet unlocked. Flat damage reduction, no GCD — use before a dangerous pull.",
                tags = { "defensive" },
            },
            {
                spellID = 61336,
                name = "Survival Instincts",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 30,
                why = "Not yet unlocked. 50% damage reduction — emergency button.",
                tags = { "defensive" },
                when = C.Critical(),
            },
            {
                spellID = 102558,
                name = "Incarnation: Guardian of Ursoc",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 90,
                why = "Not yet unlocked. Big health/mitigation cooldown — Mangle hits 3 targets and its cooldown shrinks for the duration.",
                tags = { "cd" },
            },
            { spellID = 8921, name = "Moonfire", priority = 7, why = "Keep DoT up (Galactic Guardian procs).", tags = { "active" } },
            { spellID = 6807, name = "Maul", priority = 8, why = "Rage dump alternative to Raze when not needed for Ironfur.", tags = { "active" } },
        },
    },
    aoe = {
        tip = "Guardian AoE/M+: Thrash for bleed and Wild Guardian spirit uptime on everything, Mangle/Raze on cooldown, Ironfur stacked heavier on big pulls, Lunar Beam on cooldown for the AoE stun and healing-taken debuff.",
        chain = {
            { spellID = 77758, name = "Thrash" },
            { spellID = 33917, name = "Mangle" },
            { spellID = 400254, name = "Raze" },
        },
        priorities = {
            {
                spellID = 77758,
                name = "Thrash",
                priority = 1,
                why = "Bleed stacks on every nearby target — the main Wild Guardian Rage-income source on a full pull.",
                tags = { "core" },
                when = C.DebuffRefresh(192090, 3),
            },
            {
                spellID = 204066,
                name = "Lunar Beam",
                priority = nil,
                isCd = true,
                why = "On cooldown, dropped on the pull — reduces enemy healing taken and roots anything that steps in.",
                tags = { "cd" },
            },
            {
                spellID = 33917,
                name = "Mangle",
                priority = 2,
                why = "On cooldown — Rage generator, and the 2pc's free double-damage proc only fires off this cast.",
                tags = { "core" },
            },
            {
                spellID = 400254,
                name = "Raze",
                priority = 3,
                why = "Primary AoE Rage dump — frontal cone hits everything in front of you.",
                tags = { "core" },
            },
            {
                spellID = 213764,
                name = "Swipe",
                priority = 4,
                why = "Secondary AoE filler once Raze is on cooldown.",
                tags = { "active" },
            },
            {
                spellID = 192081,
                name = "Ironfur",
                priority = 5,
                why = "Keep uptime high — stack extra charges before a big pull's damage lands.",
                tags = { "defensive" },
            },
            {
                spellID = 22842,
                name = "Frenzied Regeneration",
                priority = 6,
                why = "Below 70% health during sustained pull damage.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 1253582,
                name = "Red Moon",
                priority = nil,
                isCd = true,
                why = "On cooldown — spirit DoT that spreads to nearby enemies and feeds Wild Guardian Rage income.",
                tags = { "cd" },
            },
            {
                spellID = 102558,
                name = "Incarnation: Guardian of Ursoc",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Pop on the pull for the 3-target Mangle and shorter Thrash/Mangle cooldowns — tier 4pc extends its duration.",
                tags = { "cd" },
            },
            {
                spellID = 61336,
                name = "Survival Instincts",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency 50% damage reduction on a dangerous pull.",
                tags = { "defensive" },
                when = C.Critical(),
            },
            { spellID = 8921, name = "Moonfire", priority = 7, why = "Keep DoT up (Galactic Guardian procs).", tags = { "active" } },
            { spellID = 6807, name = "Maul", priority = 8, why = "Rage dump alternative to Raze when not needed for Ironfur.", tags = { "active" } },
        },
    },
    st = {
        tip = "Guardian Raid: Thrash and Mangle on cooldown (both feed Wild Guardian Rage via spirit damage), Raze as the primary Rage dump, Ironfur uptime, Lunar Beam/Red Moon on cooldown, Incarnation for a big damage phase or an emergency.",
        priorities = {
            {
                spellID = 77758,
                name = "Thrash",
                priority = 1,
                why = "On cooldown — bleed uptime plus Wild Guardian Rage income, and the tier 2pc's chance at a free double-damage Mangle.",
                tags = { "core" },
                when = C.DebuffRefresh(192090, 3),
            },
            {
                spellID = 33917,
                name = "Mangle",
                priority = 2,
                why = "On cooldown — biggest single hit and Rage generator. Prioritize immediately after a tier 2pc proc.",
                tags = { "core" },
            },
            {
                spellID = 204066,
                name = "Lunar Beam",
                priority = nil,
                isCd = true,
                why = "On cooldown — healing-taken debuff on the boss plus periodic damage.",
                tags = { "cd" },
            },
            {
                spellID = 1253582,
                name = "Red Moon",
                priority = nil,
                isCd = true,
                why = "On cooldown — spirit damage feeding Wild Guardian Rage.",
                tags = { "cd" },
            },
            {
                spellID = 400254,
                name = "Raze",
                priority = 3,
                why = "Primary offensive Rage dump between Mangle/Thrash casts.",
                tags = { "core" },
            },
            {
                spellID = 192081,
                name = "Ironfur",
                priority = 4,
                why = "Keep uptime as close to 100% as Rage allows — the core of your mitigation plan.",
                tags = { "defensive" },
            },
            {
                spellID = 22842,
                name = "Frenzied Regeneration",
                priority = 5,
                why = "Below 70% health — heal over time paid for with banked Rage.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 213764,
                name = "Swipe",
                priority = 6,
                why = "Filler Rage spender when Raze is on cooldown.",
                tags = { "active" },
            },
            {
                spellID = 22812,
                name = "Barkskin",
                priority = nil,
                isCd = true,
                why = "On cooldown ahead of a known tankbuster — flat damage reduction, no GCD.",
                tags = { "defensive" },
            },
            {
                spellID = 102558,
                name = "Incarnation: Guardian of Ursoc",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Line up with a tankbuster or burn phase — 3-target Mangle, shorter cooldowns, and tier 4pc adds 5s to its duration.",
                tags = { "cd" },
            },
            {
                spellID = 61336,
                name = "Survival Instincts",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "50% damage reduction — save for the biggest scheduled or unscheduled hit.",
                tags = { "defensive" },
                when = C.Critical(),
            },
            { spellID = 8921, name = "Moonfire", priority = 7, why = "Keep DoT up (Galactic Guardian procs).", tags = { "active" } },
            { spellID = 6807, name = "Maul", priority = 8, why = "Rage dump alternative to Raze when not needed for Ironfur.", tags = { "active" } },
        },
    },
}

-- ── Restoration Druid (specID 105) ───────────────────────────────────
-- Hero Talents: Wildstalker and Keeper of the Grove. Icy Veins notes the
-- core healing rotation "does not meaningfully change" between them —
-- Wildstalker leans on Efflorescence/Lifebloom synergy (Lifetreading moves
-- Efflorescence to follow your Lifebloom target), Keeper of the Grove leans
-- on Dream Burst/Force of Nature for extra throughput bursts. Pick by group
-- composition rather than for a rotation difference.
--
-- Apex Talent — Everbloom — has Lifebloom auto-stack to 3 and its Bloom
-- cleave 20-40% of its healing to up to 6 nearby allies, and makes Swiftmend
-- trigger three rapid Lifebloom blooms. This is why Lifebloom now lives on
-- the whole raid's healing plan and not just as a tank HoT.
--
-- Season 2 tier (Bark of the Enigmatic Dreamwatcher): 2pc — Rejuvenation
-- has a 15% chance to grant Genesis, a stacking buff giving +15% HoT
-- healing for 8s. 4pc — Genesis duration +8s, and Nature's Swiftness,
-- Tranquility, Convoke the Spirits, and Incarnation all guarantee a Genesis
-- application. No rotation change, but it rewards pressing cooldowns often.
-- This season's core rotation is, per Icy Veins, "enormously Regrowth-
-- focused" once Abundance (5 active Rejuvenations) is up, discounting and
-- crit-buffing Regrowth into your primary filler.
R[105] = { -- Restoration Druid
    solo = {
        tip = "Resto Druid solo leveling: Moonfire/Sunfire/Wrath to kill things, Rejuvenation and Swiftmend to stay alive. Lifebloom, Wild Growth, and Tranquility unlock progressively.",
        priorities = {
            {
                spellID = 93402,
                name = "Sunfire",
                priority = 1,
                why = "DoT — primary solo damage source.",
                tags = { "core" },
                when = C.DebuffRefresh(164815, 3),
            },
            {
                spellID = 8921,
                name = "Moonfire",
                priority = 2,
                why = "DoT — maintain on target alongside Sunfire.",
                tags = { "core" },
                when = C.DebuffRefresh(164812, 3),
            },
            {
                spellID = 5176,
                name = "Wrath",
                priority = 3,
                why = "Filler nuke between DoT refreshes.",
                tags = { "active" },
            },
            {
                spellID = 774,
                name = "Rejuvenation",
                priority = 4,
                why = "Self-HoT — keep up any time you're below 80%.",
                tags = { "core" },
                when = C.HealthBelow(80),
            },
            {
                spellID = 8936,
                name = "Regrowth",
                priority = 5,
                why = "Bigger direct heal plus a short HoT — use on sharper dips than Rejuvenation alone covers.",
                tags = { "core" },
                when = C.HealthBelow(60),
            },
            {
                spellID = 18562,
                name = "Swiftmend",
                priority = 6,
                why = "Instant heal for emergencies — consumes an active Rejuvenation/Regrowth.",
                tags = { "core" },
                when = C.Hurt(),
            },
            {
                spellID = 33763,
                name = "Lifebloom",
                priority = nil,
                unlockLv = 20,
                why = "Not yet unlocked. Strong single-target HoT, cheap to refresh — keep on yourself while soloing.",
                tags = { "core" },
            },
            {
                spellID = 48438,
                name = "Wild Growth",
                priority = nil,
                unlockLv = 30,
                why = "Not yet unlocked. Group AoE heal — only matters once you're grouping.",
                tags = {},
            },
            {
                spellID = 740,
                name = "Tranquility",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 40,
                why = "Not yet unlocked. Massive AoE burst heal — emergency button once available.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Resto M+: Efflorescence positioned under the group, Lifebloom on the tank or heaviest-damage target, Swiftmend into Rejuvenation/Regrowth chains for burst damage, Wild Growth on cooldown for sustained AoE, pre-build 5 Rejuvenations (Abundance) before a scripted big pull.",
        chain = {
            { spellID = 145205, name = "Efflorescence" },
            { spellID = 48438, name = "Wild Growth" },
            { spellID = 18562, name = "Swiftmend" },
        },
        priorities = {
            {
                spellID = 145205,
                name = "Efflorescence",
                priority = 1,
                why = "Ground HoT — keep it down under the group; Wildstalker's Lifetreading moves it to follow your Lifebloom target automatically.",
                tags = { "core" },
            },
            {
                spellID = 33763,
                name = "Lifebloom",
                priority = 2,
                why = "Keep on the tank or the target taking the most sustained damage — Everbloom (Apex Talent) auto-stacks it to 3 and cleaves its Bloom to 6 nearby allies.",
                tags = { "core" },
                when = C.BuffRefresh(33763, 4),
            },
            {
                spellID = 48438,
                name = "Wild Growth",
                priority = 3,
                why = "On cooldown during any real group damage — hits the 5 lowest-health targets.",
                tags = { "core" },
            },
            {
                spellID = 774,
                name = "Rejuvenation",
                priority = 4,
                why = "Blanket injured players and build toward 5 active (Abundance) ahead of a known damage burst.",
                tags = { "core" },
            },
            {
                spellID = 18562,
                name = "Swiftmend",
                priority = 5,
                why = "Instant heal on the most urgent target — follow up immediately with Rejuvenation or Regrowth.",
                tags = { "core" },
                when = C.HealthBelow(60),
            },
            {
                spellID = 8936,
                name = "Regrowth",
                priority = 6,
                why = "Cheap and crit-buffed once Abundance (5 Rejuvenations) is active — your go-to filler heal during that window.",
                tags = { "core" },
            },
            {
                spellID = 102342,
                name = "Ironbark",
                priority = nil,
                isCd = true,
                why = "Proactively on the tank or whoever is about to take a big hit — 20% damage reduction.",
                tags = { "defensive" },
            },
            {
                spellID = 29166,
                name = "Innervate",
                priority = nil,
                isCd = true,
                why = "Cast around 75% mana or lower rather than waiting to go oom — frequent, not saved.",
                tags = { "cd" },
                when = C.PowerPctBelow(75),
            },
            {
                spellID = 132158,
                name = "Nature's Swiftness",
                priority = nil,
                isCd = true,
                why = "Instant, empowered Regrowth for a sudden spike — emergency single-target save. Guarantees a Genesis application (tier 4pc).",
                tags = { "defensive" },
                when = C.Critical(),
            },
            {
                spellID = 33891,
                name = "Incarnation: Tree of Life",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Sustain-focused burst window — 10% healing, an instant Regrowth, and Wild Growth hits 2 extra targets. Guarantees Genesis (tier 4pc).",
                tags = { "cd" },
                talentAlt = "Convoke the Spirits",
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = nil,
                isCd = true,
                why = "Burst window for dangerous pulls — random heals/damage over 4 seconds. Guarantees Genesis (tier 4pc).",
                tags = { "cd" },
                talentReq = "Convoke the Spirits",
            },
        },
    },
    st = {
        tip = "Resto Raid: Lifebloom plus 1-2 Rejuvenations on yourself for Photosynthesis procs, Efflorescence under the melee/stack, Swiftmend on cooldown followed by a Rejuvenation, Wild Growth during damage, Regrowth as the primary filler once Abundance (5 Rejuvenations) is active. Tranquility during peak raid damage after a ramp; Flourish to extend everything into a burn/execute phase.",
        priorities = {
            {
                spellID = 33763,
                name = "Lifebloom",
                priority = 1,
                why = "Keep on yourself with 1-2 Rejuvenations layered for Photosynthesis procs — Everbloom (Apex Talent) auto-stacks and cleaves its Bloom to 6 allies.",
                tags = { "core" },
                when = C.BuffRefresh(33763, 4),
            },
            {
                spellID = 774,
                name = "Rejuvenation",
                priority = 2,
                why = "Blanket the raid — maintain on 5+ targets to keep Abundance active for cheap Regrowth casts.",
                tags = { "core" },
            },
            {
                spellID = 145205,
                name = "Efflorescence",
                priority = 3,
                why = "Under the melee/stacked group — near-permanent uptime.",
                tags = { "core" },
            },
            {
                spellID = 18562,
                name = "Swiftmend",
                priority = 4,
                why = "On cooldown — consumes a Rejuvenation/Regrowth, always follow up by reapplying it.",
                tags = { "core" },
            },
            {
                spellID = 48438,
                name = "Wild Growth",
                priority = 5,
                why = "On cooldown during raid damage — also refreshes Genesis stacks (tier 2pc) across the group.",
                tags = { "core" },
            },
            {
                spellID = 8936,
                name = "Regrowth",
                priority = 6,
                why = "Primary filler once Abundance (5 active Rejuvenations) makes it cheap and crit-buffed — this season's rotation is built around this cast.",
                tags = { "core" },
            },
            {
                spellID = 102342,
                name = "Ironbark",
                priority = nil,
                isCd = true,
                why = "Proactively on the tank ahead of a known tankbuster.",
                tags = { "defensive" },
            },
            {
                spellID = 29166,
                name = "Innervate",
                priority = nil,
                isCd = true,
                why = "Around 75% mana — cast it regularly rather than banking it for later.",
                tags = { "cd" },
                when = C.PowerPctBelow(75),
            },
            {
                spellID = 132158,
                name = "Nature's Swiftness",
                priority = nil,
                isCd = true,
                why = "Instant empowered Regrowth for a sudden spike. Guarantees a Genesis application (tier 4pc).",
                tags = { "defensive" },
                when = C.Critical(),
            },
            {
                spellID = 740,
                name = "Tranquility",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "During peak raid damage after ramping Rejuvenation/Wild Growth/Regrowth — extends and buffs every active HoT. Guarantees Genesis (tier 4pc).",
                tags = { "cd" },
            },
            {
                spellID = 197721,
                name = "Flourish",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Extends every active HoT by 8s — line up with a burn/execute phase or right after a Tranquility ramp.",
                tags = { "cd" },
            },
            {
                spellID = 33891,
                name = "Incarnation: Tree of Life",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Sustain-focused burst window — instant Regrowth, +2 Wild Growth targets. Guarantees Genesis (tier 4pc).",
                tags = { "cd" },
                talentAlt = "Convoke the Spirits",
            },
            {
                spellID = 391528,
                name = "Convoke the Spirits",
                priority = nil,
                isCd = true,
                why = "Burst window, lined up with other cooldowns — random heals/damage. Guarantees Genesis (tier 4pc).",
                tags = { "cd" },
                talentReq = "Convoke the Spirits",
            },
        },
    },
}

-- ── MAGE ──────────────────────────────────────────────────────────────
-- Arcane/Fire/Frost rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2
-- (Curse of Ula'tek: The Venomous Abyss). Cross-checked against Icy Veins'
-- live 12.1 DPS rotation + spec/talent guides, Method's 12.1 Mage guides,
-- and Maxroll's 12.1 class guides.
--
-- Hero talents: three trees, each pairing two Mage specs — Sunfury
-- (Arcane+Fire), Frostfire (Fire+Frost), Spellslinger (Frost+Arcane). Each
-- block below calls out the currently recommended pick; the other option is
-- a legitimate alternative (usually better in heavy M+ cleave), not a
-- mistake, so it's modeled with talentReq/talentAlt rather than omitted.
R[62] = { -- Arcane
    -- Hero talent: Sunfury is the current raid/ST pick — Arcane Soul plus a
    -- 25-stack Arcane Salvo cap (vs Spellslinger's 20) out-values once Nether
    -- Precision is rolling. Spellslinger remains the M+/cleave alternative via
    -- Charged Orb. Apex talent is Prismatic Bolt: consuming an Arcane Salvo
    -- stack has a 1% chance per stack to replace your next Arcane Blast with a
    -- free, instant, cleaving Prismatic Bolt that also grants 4 Arcane
    -- Charges — this is why the priority favors spending high Salvo stacks
    -- through Barrage/Missiles rather than letting them sit idle. Season 2
    -- tier (Primal Leywarden's Attire) 2pc: Arcane Missiles fires an extra
    -- missile for 20% more damage. 4pc: each Missiles volley buffs your next
    -- Arcane Blast, Arcane Orb, or Prismatic Bolt, stacking to 40% — this
    -- turns Missiles into a setup cast for your next big spender, not just a
    -- free Clearcasting dump.
    solo = {
        tip = "Arcane solo: Arcane Blast to 4 charges, Arcane Barrage to dump, Arcane Missiles on Clearcasting. Evocation to reset mana.",
        priorities = {
            {
                spellID = 44425,
                name = "Arcane Barrage",
                priority = 1,
                why = "At 4 Arcane Charges — dump and reset.",
                tags = { "core" },
            },
            {
                spellID = 5143,
                name = "Arcane Missiles",
                priority = 2,
                why = "On Clearcasting proc only — free, and refreshes Nether Precision.",
                tags = { "core" },
                when = C.HasBuff(263725),
            },
            {
                spellID = 30451,
                name = "Arcane Blast",
                priority = 3,
                why = "Charge builder — core filler. May auto-transform into a free Prismatic Bolt once the Apex Talent is unlocked.",
                tags = { "core" },
            },
            {
                spellID = 365350,
                name = "Arcane Surge",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst CD — massive damage + full mana restore over its duration.",
                unlockLv = 58,
                tags = { "cd" },
            },
            {
                spellID = 12051,
                name = "Evocation",
                priority = nil,
                isCd = true,
                why = "Mana recovery — use when low on mana, outside cooldown windows.",
                tags = { "cd" },
                when = C.PowerPctBelow(30),
            },
        },
    },
    aoe = {
        tip = "Arcane M+ (Sunfury): Arcane Orb to spread Charges/Salvo, Barrage to dump at 4 Charges, Missiles on Clearcasting to feed the 4pc buff. Touch of the Magi + Arcane Surge for burst windows.",
        chain = {
            { spellID = 153626, name = "Arcane Orb" },
            { spellID = 44425, name = "Arcane Barrage" },
            { spellID = 5143, name = "Arcane Missiles" },
            { spellID = 30451, name = "Arcane Blast" },
        },
        priorities = {
            {
                spellID = 153626,
                name = "Arcane Orb",
                priority = 1,
                why = "At 0 Arcane Charges — hits everything nearby and refills Charges + Salvo for free.",
                condition = "At 0 Charges",
                tags = { "aoe", "core" },
            },
            {
                spellID = 44425,
                name = "Arcane Barrage",
                priority = 2,
                why = "At 4 Charges with high Arcane Salvo — cleaves nearby targets on the dump.",
                condition = "At 4 Charges",
                tags = { "aoe", "core" },
            },
            {
                spellID = 5143,
                name = "Arcane Missiles",
                priority = 3,
                why = "On Clearcasting — sets up the 4pc buff on your next Blast/Orb/Prismatic Bolt.",
                tags = { "aoe", "core" },
                when = C.HasBuff(263725),
            },
            {
                spellID = 1449,
                name = "Arcane Explosion",
                priority = 4,
                why = "Baseline PBAoE filler when Orb is down and there's no Salvo dump ready.",
                tags = { "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 30451,
                name = "Arcane Blast",
                priority = 5,
                why = "Charge builder filler between Orb/Barrage windows.",
                tags = { "aoe" },
            },
            {
                spellID = 321507,
                name = "Touch of the Magi",
                priority = nil,
                isCd = true,
                why = "Pop with Orb/Barrage burst for extra accumulated AoE damage.",
                tags = { "cd" },
            },
            {
                spellID = 365350,
                name = "Arcane Surge",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst AoE + mana refill — line up with Touch of the Magi.",
                unlockLv = 58,
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Arcane raid ST (Sunfury): dump Barrage at 4 Charges/high Salvo, Missiles on Clearcasting, Arcane Blast filler. Open with Touch of the Magi ticking into Arcane Surge.",
        priorities = {
            {
                spellID = 44425,
                name = "Arcane Barrage",
                priority = 1,
                why = "At 4 Arcane Charges with near-max Arcane Salvo (25 Sunfury / 20 Spellslinger) — the biggest single dump, resets Charges.",
                condition = "At 4 Charges, high Salvo",
                tags = { "core", "st" },
            },
            {
                spellID = 5143,
                name = "Arcane Missiles",
                priority = 2,
                why = "On Clearcasting — refreshes Nether Precision and, with 4pc, buffs your next Blast/Orb/Prismatic Bolt up to 40%.",
                tags = { "core", "st" },
                when = C.HasBuff(263725),
            },
            {
                spellID = 30451,
                name = "Arcane Blast",
                priority = 3,
                why = "Core charge-builder/filler. Watch for it auto-becoming a free instant Prismatic Bolt (Apex Talent) that cleaves and grants 4 Charges.",
                tags = { "core", "st" },
            },
            {
                spellID = 153626,
                name = "Arcane Orb",
                priority = 4,
                why = "At 0 Charges — free Charge and Salvo generation, don't let it sit unused.",
                condition = "At 0 Charges",
                tags = { "core", "st" },
            },
            {
                spellID = 205025,
                name = "Presence of Mind",
                priority = 5,
                why = "Instant Arcane Blast for movement — use without breaking the priority list.",
                tags = { "active" },
            },
            {
                spellID = 321507,
                name = "Touch of the Magi",
                priority = nil,
                isCd = true,
                why = "45s CD, accumulates 20% of damage dealt then explodes and grants 4 Charges. Time it exactly on half of Arcane Surge's cooldown so it's always up to pair.",
                tags = { "cd" },
            },
            {
                spellID = 365350,
                name = "Arcane Surge",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "90s CD — drains mana for one huge hit, then +35% spell damage for 15s while refilling mana. Open with Touch of the Magi already ticking.",
                unlockLv = 58,
                tags = { "cd" },
            },
            {
                spellID = 12051,
                name = "Evocation",
                priority = nil,
                isCd = true,
                why = "Mana recovery — only outside cooldown windows.",
                tags = { "cd" },
                when = C.PowerPctBelow(20),
            },
        },
    },
}
R[63] = { -- Fire
    -- Hero talent: Frostfire is the current raid pick — Isothermic Core lets
    -- Frostfire Bolt casts (which replace Fireball) build sustained value
    -- between Fire spells without losing Hot Streak progress; it's the same
    -- tree Frost mages take, just with Fire-side nodes. Sunfury remains
    -- strong for M+/burst windows via Sun King's Blessing. Apex talent (Fired
    -- Up, reworked for Midnight): an extra Fire Blast charge, and each Fire
    -- Blast/Phoenix Flames/Scorch crit cuts your remaining Fire Blast cooldown
    -- — this is what lets you chain extra Fire Blasts inside Combustion.
    -- Season 2 tier (Primal Leywarden's Attire) 2pc: Pyroclasm procs guarantee
    -- critical strikes on Flamestrike and Pyroblast. 4pc: those Pyroclasm-
    -- empowered casts also get 20% faster cast time and their damage bonus
    -- rises to 25% — Pyroclasm procs now jump to the top of the priority list
    -- alongside Hot Streak, not just a nice-to-have.
    solo = {
        tip = "Fire solo: Fireball for Hot Streak procs, Pyroblast on Hot Streak (instant). Fire Blast to force crits.",
        priorities = {
            {
                spellID = 11366,
                name = "Pyroblast",
                priority = 1,
                why = "On Hot Streak proc — instant cast.",
                tags = { "core" },
                when = C.HasBuff(48108),
            },
            {
                spellID = 108853,
                name = "Fire Blast",
                priority = 2,
                why = "Always crits — use to convert Heating Up into Hot Streak.",
                tags = { "core" },
            },
            {
                spellID = 133,
                name = "Fireball",
                priority = 3,
                why = "Filler — fishing for crits to build Heating Up.",
                tags = { "core" },
            },
            {
                spellID = 257541,
                name = "Phoenix Flames",
                priority = 4,
                why = "Guaranteed crit — 3 charges, backup Heating Up source.",
                tags = { "active" },
            },
            {
                spellID = 190319,
                name = "Combustion",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Guaranteed crits — Pyroblast spam window.",
                unlockLv = 58,
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Fire M+: Flamestrike on Hot Streak/Pyroclasm (2pc guarantees the crit), Meteor on CD, Phoenix Flames for AoE crits, Fire Blast to chain Hot Streak.",
        chain = {
            { spellID = 190319, name = "Combustion" },
            { spellID = 153561, name = "Meteor" },
            { spellID = 2120, name = "Flamestrike" },
        },
        priorities = {
            {
                spellID = 2120,
                name = "Flamestrike",
                priority = 1,
                why = "On Hot Streak, or on a Pyroclasm proc — 2pc guarantees the crit, 4pc speeds the cast and boosts the damage bonus to 25%.",
                tags = { "aoe", "core" },
                when = C.Or(C.HasBuff(48108), C.HasBuff(269651)),
            },
            {
                spellID = 153561,
                name = "Meteor",
                priority = 2,
                why = "On cooldown — big AoE hit that also seeds Hot Streak.",
                isCd = true,
                tags = { "aoe" },
            },
            {
                spellID = 257541,
                name = "Phoenix Flames",
                priority = 3,
                why = "AoE guaranteed crit — keeps Heating Up/Hot Streak rolling in AoE.",
                tags = { "aoe", "core" },
            },
            {
                spellID = 108853,
                name = "Fire Blast",
                priority = 4,
                why = "Chain Hot Streaks and fish for Pyroclasm procs. Never cap charges.",
                tags = { "aoe", "core" },
            },
            {
                spellID = 133,
                name = "Fireball",
                priority = 5,
                why = "Filler between procs.",
                talentAlt = "Frostfire Bolt",
                tags = { "active" },
            },
            {
                spellID = 431044,
                name = "Frostfire Bolt",
                priority = 5,
                why = "Frostfire hero talent filler — replaces Fireball, same slot in the priority.",
                talentReq = "Frostfire",
                tags = { "active" },
            },
            {
                spellID = 190319,
                name = "Combustion",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Guaranteed crits — chain Flamestrikes and Meteor together.",
                unlockLv = 58,
                tags = { "cd" },
            },
            { spellID = 382440, name = "Shifting Power", priority = nil, isCd = true, why = "Channel outside Combustion to cool down Fire Blast/Combustion.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Fire raid ST: Pyroblast on Hot Streak/Pyroclasm, Fire Blast to convert Heating Up, Scorch below 30% or on Heat Shimmer. Meteor on CD (save the last cast for the Combustion tail). Combustion for burst.",
        priorities = {
            {
                spellID = 11366,
                name = "Pyroblast",
                priority = 1,
                why = "Hot Streak — always instant. Also fires free and guaranteed-crit on a Pyroclasm proc (faster cast with 4pc).",
                tags = { "core", "st" },
                when = C.Or(C.HasBuff(48108), C.HasBuff(269651)),
            },
            {
                spellID = 108853,
                name = "Fire Blast",
                priority = 2,
                why = "Convert Heating Up into Hot Streak. Never cap charges — each crit also shaves time off its own cooldown (Apex Talent).",
                tags = { "core", "st" },
                when = C.HasBuff(48107),
            },
            {
                spellID = 2948,
                name = "Scorch",
                priority = 3,
                why = "Execute filler below 30%, or free cast on a Heat Shimmer proc.",
                tags = { "active" },
                when = C.Execute(30),
            },
            {
                spellID = 257541,
                name = "Phoenix Flames",
                priority = 4,
                why = "Backup guaranteed-crit charge to keep Heating Up alive.",
                tags = { "core", "st" },
            },
            {
                spellID = 133,
                name = "Fireball",
                priority = 5,
                why = "Filler, fishing for Heating Up.",
                talentAlt = "Frostfire Bolt",
                tags = { "core", "st" },
            },
            {
                spellID = 431044,
                name = "Frostfire Bolt",
                priority = 5,
                why = "Frostfire hero talent filler — replaces Fireball, same slot in the priority.",
                talentReq = "Frostfire",
                tags = { "core", "st" },
            },
            {
                spellID = 153561,
                name = "Meteor",
                priority = nil,
                isCd = true,
                why = "On cooldown outside Combustion; inside Combustion, save the last cast for its final 2-8s for max crit value.",
                tags = { "cd" },
            },
            {
                spellID = 190319,
                name = "Combustion",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "60s guaranteed-crit window — Pyroblast spam, pool Fire Blast/Phoenix Flames charges beforehand.",
                unlockLv = 58,
                tags = { "cd" },
            },
            { spellID = 382440, name = "Shifting Power", priority = nil, isCd = true, why = "Channel outside Combustion to cool down Fire Blast/Combustion.", tags = { "cd" } },
        },
    },
}
R[64] = { -- Frost Mage
    -- Hero talent: Frostfire is the current default for Frost (Frostfire Bolt
    -- filler + Isothermic Core) — the same tree Fire mages share. Spellslinger
    -- remains the M+ alternative via Splitting Ice/Charged Orb. Apex talent
    -- Hand of Frost: Shatter events (a fully-Frozen target hit by Ice Lance,
    -- Frostbolt, etc.) have a chance to fire a bonus damage bolt — this was
    -- nerfed in 12.1 to curb burst, so it's a nice bonus rather than something
    -- to play around. Also note the 12.1 secondary-target cleave nerfs: Ice
    -- Lance's 2nd-target hit was cut from 100% to 50% of its damage, and
    -- Frostbolt/Flurry/Glacial Spike secondary-target damage was cut from 80%
    -- to 50% — Frost's 2-target cleave is meaningfully weaker this patch, so
    -- the AoE rotation below leans on Blizzard/Frozen Orb rather than pure
    -- single-target cleave once you're at 3+ targets. Season 2 tier (Primal
    -- Leywarden's Attire) 2pc: Freezing (the Shatter-tracking stack) has a
    -- chance to generate Icicles, and Glacial Spike deals 20% more damage.
    -- 4pc: Glacial Spike can rapidly generate 5 Icicles at once, and Shatter
    -- damage is up 5% — keeping the Freezing stack flowing into Glacial Spike
    -- is now the core throughput loop, not just Fingers of Frost/Brain Freeze.
    solo = {
        tip = "Frost Mage solo: Frostbolt for procs, Ice Lance on Fingers of Frost, Flurry on Brain Freeze. Frozen Orb for AoE.",
        priorities = {
            {
                spellID = 44614,
                name = "Flurry",
                priority = 1,
                why = "On Brain Freeze — shatters your next Ice Lance.",
                tags = { "core" },
                when = C.HasBuff(190446),
            },
            {
                spellID = 30455,
                name = "Ice Lance",
                priority = 2,
                why = "After a Flurry shatter, or on Fingers of Frost.",
                tags = { "core" },
                when = C.HasBuff(44544),
            },
            { spellID = 116, name = "Frostbolt", priority = 3, why = "Filler — generates procs.", tags = { "core" } },
            {
                spellID = 84714,
                name = "Frozen Orb",
                priority = 4,
                why = "AoE + generates Fingers of Frost.",
                tags = { "core" },
            },
            {
                spellID = 12472,
                name = "Icy Veins",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Haste burst — more procs.",
                unlockLv = 58,
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Frost M+ (3+ targets): Frozen Orb + Blizzard carry more of the damage this patch after the 12.1 cleave nerfs. Dump Freezing stacks into Ice Lance/Glacial Spike for the tier bonus, Comet Storm on CD.",
        chain = {
            { spellID = 84714, name = "Frozen Orb" },
            { spellID = 190356, name = "Blizzard" },
            { spellID = 153595, name = "Comet Storm" },
            { spellID = 30455, name = "Ice Lance" },
        },
        priorities = {
            {
                spellID = 84714,
                name = "Frozen Orb",
                priority = 1,
                why = "On cooldown — mass Fingers of Frost generation plus its own AoE tick.",
                tags = { "aoe", "core" },
            },
            {
                spellID = 190356,
                name = "Blizzard",
                priority = 2,
                why = "Ground AoE — with 12.1's cleave nerfs this now carries more of the 3+ target damage than Ice Lance splash.",
                tags = { "aoe", "core" },
                when = C.AoE(3),
            },
            {
                spellID = 153595,
                name = "Comet Storm",
                priority = 3,
                why = "On cooldown — big AoE burst.",
                talentReq = "Comet Storm",
                tags = { "aoe", "active" },
            },
            {
                spellID = 30455,
                name = "Ice Lance",
                priority = 4,
                why = "Dump Fingers of Frost / high Freezing stacks — feeds the 2pc/4pc Icicle generation for Glacial Spike.",
                tags = { "aoe", "core" },
                when = C.HasBuff(44544),
            },
            {
                spellID = 199786,
                name = "Glacial Spike",
                priority = 5,
                why = "Spend Icicles for a big hit even in AoE — 4pc lets it generate 5 Icicles at once.",
                tags = { "aoe" },
            },
            {
                spellID = 44614,
                name = "Flurry",
                priority = 6,
                why = "On Brain Freeze, or to refresh Freezing stacks when nothing else is ready.",
                tags = { "aoe" },
            },
            {
                spellID = 12472,
                name = "Icy Veins",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Pop together with Frozen Orb for the biggest AoE window.",
                unlockLv = 58,
                tags = { "cd" },
            },
            { spellID = 382440, name = "Shifting Power", priority = nil, isCd = true, why = "Channel to reduce Frozen Orb/Icy Veins cooldowns.", tags = { "cd" } },
        },
    },
    st = {
        tip = "Frost raid ST: Glacial Spike to spend Icicles, Comet Storm on CD, Flurry on Brain Freeze into Ice Lance at 2 Fingers of Frost, Ray of Frost and Frozen Orb to refill. Icy Veins for burst.",
        priorities = {
            {
                spellID = 199786,
                name = "Glacial Spike",
                priority = 1,
                why = "Spend Icicles for the biggest single hit — boosted 20% by 2pc, and 4pc lets you rebuild 5 Icicles at once.",
                tags = { "core", "st" },
            },
            {
                spellID = 153595,
                name = "Comet Storm",
                priority = 2,
                why = "On cooldown — strong burst, worth delaying a GCD for.",
                talentReq = "Comet Storm",
                tags = { "st", "active" },
            },
            {
                spellID = 44614,
                name = "Flurry",
                priority = 3,
                why = "On Brain Freeze — cast immediately, sets up your next Ice Lance as a guaranteed Shatter.",
                tags = { "core", "st" },
                when = C.HasBuff(190446),
            },
            {
                spellID = 30455,
                name = "Ice Lance",
                priority = 4,
                why = "At 2 Fingers of Frost stacks (or with Thermal Void active) — maximum Freezing/Icicle consumption per cast.",
                tags = { "core", "st" },
                when = C.BuffStacks(44544, 2),
            },
            {
                spellID = 205021,
                name = "Ray of Frost",
                priority = 5,
                why = "Channel — cut it short at 2 Fingers of Frost stacks or whenever a higher-priority spell needs to fire.",
                tags = { "active" },
            },
            {
                spellID = 84714,
                name = "Frozen Orb",
                priority = 6,
                why = "On cooldown for Fingers of Frost generation.",
                tags = { "core", "st" },
            },
            {
                spellID = 30455,
                name = "Ice Lance",
                priority = 7,
                why = "Dump at high Freezing stacks even without Fingers of Frost, to trigger tier Icicle generation before overcapping.",
                condition = "High Freezing stacks, no FoF",
                tags = { "st" },
            },
            {
                spellID = 44614,
                name = "Flurry",
                priority = 8,
                why = "Off-cooldown filler-refresh even without Brain Freeze, to keep Freezing stacks topped up.",
                tags = { "st" },
            },
            {
                spellID = 116,
                name = "Frostbolt",
                priority = 9,
                why = "Filler.",
                talentAlt = "Frostfire Bolt",
                tags = { "core", "st" },
            },
            {
                spellID = 431044,
                name = "Frostfire Bolt",
                priority = 9,
                why = "Frostfire hero talent filler — replaces Frostbolt, same slot in the priority.",
                talentReq = "Frostfire",
                tags = { "core", "st" },
            },
            {
                spellID = 12472,
                name = "Icy Veins",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Haste burst — more procs, more Shatter windows.",
                unlockLv = 58,
                tags = { "cd" },
            },
            { spellID = 382440, name = "Shifting Power", priority = nil, isCd = true, why = "Channel to reduce Frozen Orb/Icy Veins cooldowns.", tags = { "cd" } },
        },
    },
}

-- ── PRIEST ────────────────────────────────────────────────────────────
-- Discipline (256), Holy (257), and Shadow (258) rewritten 2026-09-05
-- against Icy Veins' current 12.1 (Midnight S2, Curse of Ula'tek: The
-- Venomous Abyss) guides (the PvE Healing/DPS "Rotation, Cooldowns, and
-- Abilities" and "Spec, Builds, and Talents" pages per spec, plus the
-- Shadow Priest rework retrospective), Method.gg's Discipline/Holy/Shadow
-- Playstyle & Rotation and Talents guides, and conquestcapped.com for the
-- season 2 tier set bonuses. Spell IDs are Midnight 12.1 build IDs — a
-- few newly-reworked buttons (Void Blast, Void Shield, Entropic Rift,
-- Tentacle Slam, Benediction) are cross-checked against Wowhead's current
-- spell pages but still worth confirming with GetSpellInfo() in-game.
--
-- Hero talent pairings this expansion: Oracle (Discipline + Holy — extra
-- Penance/Prayer of Mending charges via Guiding Light, plus Prompt
-- Prognosis), Archon (Holy + Shadow — Halo empowering Prayer of
-- Healing/Voidform), and Voidweaver (Discipline + Shadow — Mind Blast
-- opens Entropic Rift, Penance grows it, and your builder becomes Void
-- Blast while it's active).
--
-- Note: Devouring Plague was renamed Shadow Word: Madness this expansion
-- (same spell, spellID 335467) as part of Shadow's rework — it is still
-- the primary Insanity spender, just under the new name.
R[256] = { -- Discipline
    -- Voidweaver is the season 2 raid pick (Entropic Rift + a Void Shield
    -- that reflects absorbed damage into Atonement healing); Oracle is the
    -- M+ pick (3rd Penance charge via Guiding Light, Prompt Prognosis).
    -- Apex Talent: Master the Darkness — Penance has a chance to turn your
    -- next Power Word: Shield into a Void Shield that splashes to 2 more
    -- allies; higher ranks add passive Atonement/shadow damage, and at
    -- rank 4 Void Shield reflects absorbed damage as Atonement healing and
    -- Mind Blast guarantees the Void Shield proc. Tier set: 2pc boosts
    -- Penance damage/healing 20% and casting it cuts Mind Blast's cooldown
    -- by 2 sec; 4pc makes your next Shield/Void Shield after Mind Blast
    -- absorb 25% more — the tier is why Mind Blast is now core, not filler.
    solo = {
        tip = "Disc solo: Smite for damage (heals via Atonement), SW:Pain DoT, Penance and Mind Blast on CD, Shield when hurt.",
        priorities = {
            {
                spellID = 585,
                name = "Smite",
                priority = 1,
                why = "Damage filler — heals via Atonement.",
                tags = { "core" },
            },
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 2,
                why = "Maintain DoT — refresh inside the pandemic window, don't clip early.",
                tags = { "core" },
                when = C.DebuffRefresh(589, 4),
            },
            {
                spellID = 47540,
                name = "Penance",
                priority = 3,
                why = "Offensive on CD — damage + Atonement heal. Tier 2pc cuts Mind Blast's cooldown when you cast this.",
                tags = { "core" },
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 4,
                why = "On CD — tier 4pc makes your next Shield absorb 25% more after this lands.",
                tags = { "core" },
            },
            {
                spellID = 17,
                name = "Power Word: Shield",
                priority = 5,
                why = "When taking damage.",
                tags = { "defensive" },
                when = C.HealthBelow(85),
            },
            {
                spellID = 34433,
                name = "Shadowfiend",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Damage + mana return.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Disc M+ (Oracle): Radiance for AoE Atonement, then Penance (3rd charge via Guiding Light)/Mind Blast/Smite to heal the group through damage.",
        priorities = {
            {
                spellID = 194509,
                name = "Power Word: Radiance",
                priority = 1,
                why = "AoE Atonement application.",
                tags = { "core" },
            },
            {
                spellID = 47540,
                name = "Penance",
                priority = 2,
                why = "Highest Atonement throughput — Oracle's Guiding Light gives it a 3rd charge, so don't sit on it.",
                tags = { "core" },
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 3,
                why = "On CD — cheap damage that also feeds the tier's Shield-absorb bonus.",
                tags = { "core" },
            },
            { spellID = 585, name = "Smite", priority = 4, why = "Sustained Atonement heals.", tags = { "core" } },
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 5,
                why = "DoT for passive Atonement.",
                tags = { "active" },
                when = C.DebuffRefresh(589, 4),
            },
            {
                spellID = 62618,
                name = "Power Word: Barrier",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "25% DR zone for party.",
                tags = { "cd" },
            },
            { spellID = 32379, name = "Shadow Word: Death", priority = 6, why = "Damage + Atonement; Icy Veins 12.1 lists it in the core priority.", tags = { "core" } },
        },
    },
    st = {
        tip = "Disc Raid (Voidweaver): pre-Atonement with Shield/Radiance, Mind Blast to open Entropic Rift, Penance to grow it, Void Blast replaces Smite while it's active.",
        priorities = {
            {
                spellID = 194509,
                name = "Power Word: Radiance",
                priority = 1,
                why = "Apply Atonement to the group — Evangelism makes your next 2 casts instant for a fast ramp.",
                tags = { "core" },
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 2,
                why = "Opens Entropic Rift (Voidweaver); tier 2pc also shortens its cooldown after Penance.",
                tags = { "core" },
            },
            {
                spellID = 47540,
                name = "Penance",
                priority = 3,
                why = "Highest throughput per GCD — also grows Entropic Rift while it's up.",
                tags = { "core" },
            },
            {
                spellID = 450215,
                name = "Void Blast",
                priority = 4,
                why = "Replaces Smite while Entropic Rift is active — bigger hit, same Atonement heal.",
                tags = { "core" },
                talentReq = "Voidweaver",
                when = C.Usable(),
            },
            {
                spellID = 585,
                name = "Smite",
                priority = 5,
                why = "Filler damage → heals when Entropic Rift isn't active.",
                tags = { "core" },
                talentAlt = "Void Blast (Voidweaver, while Entropic Rift is active)",
            },
            {
                spellID = 17,
                name = "Power Word: Shield",
                priority = 6,
                why = "Tank maintenance — chance to become a Void Shield off Penance (Master the Darkness).",
                tags = { "active" },
            },
            {
                spellID = 472433,
                name = "Evangelism",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Casts a 150% Power Word: Radiance and makes your next 2 Radiance casts instant — extend Atonements before burst.",
                tags = { "cd" },
            },
            {
                spellID = 421453,
                name = "Ultimate Penitence",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Choice node with Power Word: Barrier — big Atonement-healing burst instead of the raid-wide DR zone.",
                tags = { "cd" },
                talentAlt = "Power Word: Barrier",
            },
            { spellID = 32379, name = "Shadow Word: Death", priority = 7, why = "Damage + Atonement; Icy Veins 12.1 lists it in the core priority.", tags = { "core" } },
        },
    },
}
R[257] = { -- Holy Priest
    -- Oracle is the season 2 raid single-target pick (Prayer of Mending as
    -- primary throughput, 3rd charge via Guiding Light, Prompt Prognosis
    -- heals PoM's target); Archon is the AoE/M+ pick (Prayer of Healing as
    -- the spammable button, Halo empowered via Spiritwell/Surge of Light).
    -- Apex Talent: Benediction — Holy Word: Serenity has a 100% chance to
    -- upgrade your next Flash Heal into Benediction, a free empowered cast
    -- — use it immediately, it doesn't persist. Tier set: 2pc grants 2%
    -- Haste per target you have Renew on, stacking to 6% at 3 Renews; 4pc
    -- boosts Renew healing 10% and gives Prayer of Mending's first heal
    -- target a free Renew — keep 3 Renews rolling on the raid at all
    -- times, not just as an emergency HoT.
    solo = {
        tip = "Holy Priest solo: Smite for damage, Holy Fire on CD, SW:Pain DoT. Flash Heal when hurt.",
        priorities = {
            { spellID = 14914, name = "Holy Fire", priority = 1, why = "DoT + instant. On CD.", tags = { "core" } },
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 2,
                why = "Maintain DoT.",
                tags = { "core" },
                when = C.DebuffRefresh(589, 4),
            },
            { spellID = 585, name = "Smite", priority = 3, why = "Filler nuke.", tags = { "core" } },
            {
                spellID = 2061,
                name = "Flash Heal",
                priority = 4,
                why = "Self-heal when needed.",
                tags = { "active" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 200183,
                name = "Apotheosis",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Holy Word CDR + 70% cheaper Holy Words for burst.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Holy M+ (Archon): keep 3 Renews rolling for the tier's Haste stacks, Sanctify/Prayer of Mending on CD, Halo for extra AoE, Benediction Flash Heal for urgent targets.",
        priorities = {
            {
                spellID = 139,
                name = "Renew",
                priority = 1,
                why = "Keep on 3 targets — tier 2pc grants 2% Haste per Renew (up to 6%), and 4pc buffs its healing 10%.",
                tags = { "core" },
                when = C.BuffRefresh(139, 3),
            },
            {
                spellID = 34861,
                name = "Holy Word: Sanctify",
                priority = 2,
                why = "AoE instant heal — on CD.",
                tags = { "core" },
            },
            {
                spellID = 33076,
                name = "Prayer of Mending",
                priority = 3,
                why = "Bouncing heal — also seeds a free Renew on its first target (tier 4pc).",
                tags = { "core" },
            },
            {
                spellID = 120517,
                name = "Halo",
                priority = 4,
                why = "Archon empowers this — smart AoE heal + damage.",
                tags = { "core" },
            },
            {
                spellID = 1262760,
                name = "Benediction",
                priority = 5,
                why = "Free, empowered Flash Heal proc'd by Holy Word: Serenity (Apex talent) — cast it immediately, it doesn't last.",
                tags = { "active" },
                when = C.HasBuff(1262760),
            },
            {
                spellID = 2061,
                name = "Flash Heal",
                priority = 6,
                why = "Urgent single target.",
                tags = { "active" },
            },
            {
                spellID = 64843,
                name = "Divine Hymn",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Channel raid heal — also grants Guardian Spirit while channeling.",
                tags = { "cd" },
            },
            { spellID = 88625, name = "Holy Word: Chastise", priority = 7, why = "Holy Word that triggers Divine Image (Icy Veins 12.1 raid priority #3).", tags = { "core" } },
            { spellID = 596, name = "Prayer of Healing", priority = 8, why = "Group heal — cast with Surge of Light / Lightweaver.", tags = { "core" } },
        },
    },
    st = {
        tip = "Holy Raid (Oracle): maintain 3 Renews for the tier, Prayer of Mending and Holy Word: Serenity on CD, cast Benediction the instant it procs.",
        priorities = {
            {
                spellID = 139,
                name = "Renew",
                priority = 1,
                why = "Keep on 3 raiders for the tier's 2pc Haste stacks and 4pc healing boost.",
                tags = { "core" },
                when = C.BuffRefresh(139, 3),
            },
            {
                spellID = 33076,
                name = "Prayer of Mending",
                priority = 2,
                why = "Always bouncing — Oracle gives it a 3rd charge.",
                tags = { "core" },
            },
            {
                spellID = 2050,
                name = "Holy Word: Serenity",
                priority = 3,
                why = "On CD — guarantees a Benediction proc on your next Flash Heal (Apex talent).",
                tags = { "core" },
            },
            {
                spellID = 1262760,
                name = "Benediction",
                priority = 4,
                why = "Free, empowered Flash Heal after Serenity — cast it immediately, it's the Apex talent's entire payoff.",
                tags = { "core" },
                when = C.HasBuff(1262760),
            },
            {
                spellID = 34861,
                name = "Holy Word: Sanctify",
                priority = 5,
                why = "AoE heal on CD.",
                tags = { "core" },
            },
            { spellID = 2060, name = "Heal", priority = 6, why = "Mana-efficient filler.", tags = { "core" } },
            {
                spellID = 2061,
                name = "Flash Heal",
                priority = 7,
                why = "Urgent only (expensive).",
                tags = { "active" },
            },
            {
                spellID = 64843,
                name = "Divine Hymn",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Raid CD — channel heals the group and grants Guardian Spirit throughout.",
                tags = { "cd" },
            },
            {
                spellID = 47788,
                name = "Guardian Spirit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Cheat-death external — also +60% healing received.",
                tags = { "defensive" },
            },
            { spellID = 88625, name = "Holy Word: Chastise", priority = 8, why = "Holy Word that triggers Divine Image (Icy Veins 12.1 raid priority #3).", tags = { "core" } },
            { spellID = 596, name = "Prayer of Healing", priority = 9, why = "Group heal — cast with Surge of Light / Lightweaver.", tags = { "core" } },
        },
    },
}
R[258] = { -- Shadow
    -- Archon is the season 2 raid single-target pick (Voidform-centric —
    -- Mind Flay: Insanity as a big spender, Halo empowers Voidform,
    -- Perfected Form adds +5% damage while Voidform is active); Voidweaver
    -- is the AoE/M+ pick (Void Torrent opens Entropic Rift, Void Blast
    -- replaces Mind Blast while it pulses, Devour Matter for extra AoE).
    -- Apex Talent: Void Apparitions — builds around Shadowy Apparitions
    -- generation and their damage, which is exactly what the season 2
    -- tier set buffs. Tier set: 2pc cuts Tentacle Slam's cooldown by 3 sec
    -- and doubles its damage; 4pc makes the Vampiric Touch cast right
    -- after Tentacle Slam instant, grants 4 bonus Insanity, and summons
    -- Shadowy Apparitions dealing 200% damage — Tentacle Slam is now a
    -- core AoE opener/reset button, not just a pull tool.
    solo = {
        tip = "Shadow solo: SW:Pain + Vampiric Touch DoTs, Mind Blast on CD, Shadow Word: Madness at 50 Insanity. Mind Flay filler.",
        priorities = {
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 1,
                why = "Maintain DoT.",
                tags = { "core" },
                when = C.DebuffRefresh(589, 4),
            },
            {
                spellID = 34914,
                name = "Vampiric Touch",
                priority = 2,
                why = "Maintain DoT — self-heal.",
                tags = { "core" },
                when = C.DebuffRefresh(34914, 4),
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 3,
                why = "Insanity gen + big hit. On CD.",
                tags = { "core" },
            },
            {
                spellID = 335467,
                name = "Shadow Word: Madness",
                priority = 4,
                why = "At 50 Insanity — primary spender (renamed from Devouring Plague this expansion).",
                tags = { "core" },
                when = C.PowerAtLeast(50),
            },
            { spellID = 15407, name = "Mind Flay", priority = 5, why = "Filler channel.", tags = { "active" } },
            {
                spellID = 228260,
                name = "Voidform",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Enter Voidform for burst (12.1: Void Eruption is gone; Voidform grants 3 Void Volley casts).",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Shadow AoE (Voidweaver): Tentacle Slam to multi-DoT and trigger the tier's instant Vampiric Touch reset, Shadow Word: Madness on a new target each time Insanity allows, Void Volley charges during Voidform, Mind Flay filler.",
        chain = {
            { spellID = 1227280, name = "Tentacle Slam" },
            { spellID = 589, name = "Shadow Word: Pain" },
            { spellID = 34914, name = "Vampiric Touch" },
        },
        priorities = {
            {
                spellID = 1227280,
                name = "Tentacle Slam",
                priority = 1,
                why = "Multi-DoT opener — applies SW:Pain/Vampiric Touch to nearby targets. Tier 2pc/4pc turn it into a core AoE reset (bigger hit, shorter CD, free instant Vampiric Touch + apparitions after).",
                tags = { "core" },
            },
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 2,
                why = "Spread to all targets.",
                tags = { "core" },
                when = C.DebuffRefresh(589, 4),
            },
            {
                spellID = 34914,
                name = "Vampiric Touch",
                priority = 3,
                why = "Spread to 3-4 targets — free instant cast right after Tentacle Slam via the tier 4pc.",
                tags = { "core" },
                when = C.DebuffRefresh(34914, 4),
            },
            {
                spellID = 335467,
                name = "Shadow Word: Madness",
                priority = 4,
                why = "Highest HP/priority target.",
                tags = { "core" },
                when = C.PowerAtLeast(50),
            },
            {
                spellID = 450215,
                name = "Void Blast",
                priority = 5,
                why = "Replaces Mind Blast while Entropic Rift (Voidweaver) is pulsing.",
                tags = { "core" },
                talentReq = "Voidweaver",
                when = C.Usable(),
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 6,
                why = "Insanity gen.",
                tags = { "active" },
                talentAlt = "Void Blast (Voidweaver, during Entropic Rift)",
            },
            { spellID = 1242173, name = "Void Volley", priority = 7, why = "12.1: Voidform grants 3 uses — spend them inside the window (Mind Sear no longer exists).", tags = { "active" } },
            {
                spellID = 263165,
                name = "Void Torrent",
                priority = nil,
                isCd = true,
                why = "Opens Entropic Rift (Voidweaver) — channel it to start the Void Blast window.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Shadow ST (Archon): DoTs up, Mind Blast on CD, Shadow Word: Madness at 50+, Mind Flay: Insanity while Shadow Word: Madness is active. Voidform + Halo + Power Infusion for burst.",
        priorities = {
            {
                spellID = 34914,
                name = "Vampiric Touch",
                priority = 1,
                why = "Maintain.",
                tags = { "core" },
                when = C.DebuffRefresh(34914, 4),
            },
            {
                spellID = 589,
                name = "Shadow Word: Pain",
                priority = 2,
                why = "Maintain.",
                tags = { "core" },
                when = C.DebuffRefresh(589, 4),
            },
            {
                spellID = 8092,
                name = "Mind Blast",
                priority = 3,
                why = "On CD — Insanity gen.",
                tags = { "core" },
            },
            {
                spellID = 335467,
                name = "Shadow Word: Madness",
                priority = 4,
                why = "At 50 Insanity — primary spender (renamed from Devouring Plague this expansion).",
                tags = { "core" },
                when = C.PowerAtLeast(50),
            },
            {
                spellID = 391403,
                name = "Mind Flay: Insanity",
                priority = 5,
                why = "Archon's big Voidform spender — prioritize over plain Mind Flay while Voidform is up.",
                tags = { "core" },
                talentReq = "Archon",
                when = C.Or(C.HasBuff(194249), C.HasBuff(228260)),
            },
            { spellID = 15407, name = "Mind Flay", priority = 6, why = "Filler outside Voidform.", tags = { "active" } },
            {
                spellID = 32379,
                name = "Shadow Word: Death",
                priority = 7,
                why = "Execute — free Insanity below 20% target health.",
                tags = { "active" },
                when = C.Execute(20),
            },
            {
                spellID = 120644,
                name = "Halo",
                priority = 8,
                why = "Archon empowers Voidform when cast alongside it.",
                tags = { "active" },
            },
            {
                spellID = 228260,
                name = "Voidform",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Enter Voidform for burst — line up with Power Infusion and Halo (Archon). Grants 3 Void Volley casts.",
                tags = { "cd" },
            },
            {
                spellID = 10060,
                name = "Power Infusion",
                priority = nil,
                isCd = true,
                why = "Haste burst — sync with Voidform.",
                tags = { "cd" },
            },
        },
    },
}

-- ── ROGUE ─────────────────────────────────────────────────────────────
-- Rewritten 2026-09-05 against Icy Veins' and Method's current 12.1
-- (Midnight S2) guides, cross-checked between the two per spec. Season 2
-- tier set (Curse of Ula'tek: The Venomous Abyss) 2pc/4pc effects are noted
-- per spec below; where a source says it "only boosts damage" with no
-- priority change, that is called out explicitly so it isn't mistaken for
-- an oversight.
R[259] = { -- Assassination
    -- Hero talents: Deathstalker is the current default (~2-5% ahead in all
    -- content — Garrote applies Deathstalker's Mark, which builds toward the
    -- Darkest Night buff that makes a 7-CP Envenom guaranteed-crit for +50%
    -- damage). Fatebound is a simpler, still-viable alternative for pure
    -- single-target. Apex talent Implacable (4 points): points 1-3 add bonus
    -- Energy on Envenom and extra Bleed/Nature damage scaling; point 4 makes
    -- Kingsbane itself grant 10 poison stacks and 5 CP toward an immediate
    -- Envenom, letting you ramp Kingsbane's DoT to full speed almost
    -- instantly. Tier set (Curse of Ula'tek) 2pc/4pc are pure damage amps —
    -- no rotation-order impact.
    solo = {
        tip = "Assassination leveling: Garrote from stealth, Mutilate to 5 CP, Rupture to maintain the bleed, Envenom to dump. Deathmark/Kingsbane and hero-talent Marks unlock with your Hero Talent tree at 71.",
        priorities = {
            {
                spellID = 703,
                name = "Garrote",
                priority = 1,
                why = "Apply/refresh from stealth when possible — core bleed, and the opener for both hero trees.",
                tags = { "core" },
                when = C.DebuffRefresh(703, 4),
            },
            {
                spellID = 1943,
                name = "Rupture",
                priority = 2,
                why = "Maintain at 5 CP — never let it fall off, it scales with Deathmark's bleed multiplier later.",
                tags = { "core" },
                when = C.And(C.ComboAtLeast(5), C.DebuffRefresh(1943, 4)),
            },
            {
                spellID = 32645,
                name = "Envenom",
                priority = 3,
                why = "CP finisher — spend at 5 with Rupture already up.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            { spellID = 1329, name = "Mutilate", priority = 4, why = "Primary combo point generator.", tags = { "core" } },
            {
                spellID = 8676,
                name = "Ambush",
                priority = nil,
                why = "Big CP generator from Stealth/Vanish — use instead of Mutilate whenever it's usable.",
                tags = { "active" },
            },
            {
                spellID = 385627,
                name = "Kingsbane",
                priority = nil,
                isCd = true,
                unlockLv = 71,
                why = "Unlocks with your Hero Talent tree. On CD once available — big poison ramp.",
                tags = { "cd" },
            },
            {
                spellID = 360194,
                name = "Deathmark",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 71,
                why = "Main burst CD — duplicates poison procs and multiplies bleed damage for its duration.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Assassination AoE: double-Garrote the pull for pandemic overlap, Crimson Tempest to copy Garrote and Rupture onto nearby targets, then Fan of Knives for CP.",
        chain = {
            { spellID = 703, name = "Garrote" },
            { spellID = 1247227, name = "Crimson Tempest" },
            { spellID = 51723, name = "Fan of Knives" },
        },
        priorities = {
            {
                spellID = 703,
                name = "Garrote",
                priority = 1,
                why = "Apply twice on the pull for maximum pandemic overlap, then keep it on 2-3 priority targets.",
                tags = { "core", "aoe" },
            },
            {
                spellID = 1247227,
                name = "Crimson Tempest",
                priority = 2,
                why = "Energy builder (1 CP) — copies your Garrote and Rupture onto up to 2 more targets.",
                tags = { "core", "aoe" },
                when = C.And(C.ComboAtLeast(5), C.AoE(3)),
            },
            {
                spellID = 32645,
                name = "Envenom",
                priority = 3,
                why = "At 5+ CP (7 during Darkest Night) once bleeds are already spread — don't clip a Crimson Tempest refresh for it.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 51723,
                name = "Fan of Knives",
                priority = 4,
                why = "Switch to this for CP generation once every target already has a bleed up.",
                tags = { "core", "aoe" },
            },
            {
                spellID = 385627,
                name = "Kingsbane",
                priority = nil,
                isCd = true,
                unlockLv = 71,
                why = "On CD, synced with Deathmark when possible.",
                tags = { "cd" },
            },
            {
                spellID = 360194,
                name = "Deathmark",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 71,
                why = "Burst CD — pop once bleeds are spread across the pull for maximum duplicated procs.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Assassination raid ST (Deathstalker hero tree): Garrote/Rupture uptime, build Deathstalker's Mark via Garrote, sync Deathmark+Kingsbane, Envenom at 5 CP (hold for 7 during Darkest Night).",
        priorities = {
            {
                spellID = 703,
                name = "Garrote",
                priority = 1,
                why = "Maintain the bleed and, with Deathstalker, apply Deathstalker's Mark toward Darkest Night.",
                tags = { "core" },
                when = C.DebuffRefresh(703, 4),
            },
            {
                spellID = 1943,
                name = "Rupture",
                priority = 2,
                why = "Maintain at 5+ CP — never clip it early, it's a real DPS loss.",
                tags = { "core" },
                when = C.And(C.ComboAtLeast(5), C.DebuffRefresh(1943, 4)),
            },
            {
                spellID = 360194,
                name = "Deathmark",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                unlockLv = 71,
                why = "2-minute burst CD — duplicates poison procs and multiplies bleed damage. Sync Kingsbane into its window.",
                tags = { "cd" },
            },
            {
                spellID = 385627,
                name = "Kingsbane",
                priority = nil,
                isCd = true,
                unlockLv = 71,
                why = "1-minute CD, synced with Deathmark. Keep 100% melee/Envenom uptime while it ticks — Implacable's 4th point turns the cast itself into 10 poison stacks and 5 CP toward an immediate Envenom.",
                tags = { "cd" },
            },
            {
                spellID = 32645,
                name = "Envenom",
                priority = 3,
                why = "Primary finisher at 5+ CP; hold for 7 CP when Darkest Night (Deathstalker capstone) is up for the guaranteed crit and +50% damage.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 8676,
                name = "Ambush",
                priority = 4,
                why = "Use whenever it's up (Vanish, proc) instead of Mutilate — the bigger CP generator.",
                tags = { "active" },
            },
            { spellID = 1329, name = "Mutilate", priority = 5, why = "Combo point generator filler.", tags = { "core" } },
            {
                spellID = 457052,
                name = "Deathstalker's Mark",
                priority = nil,
                talentReq = "Deathstalker",
                why = "Applied by Garrote — builds toward the Darkest Night Envenom buff. Use Mark for Death to relocate it before it procs if you must target-swap.",
                tags = { "active" },
            },
            {
                spellID = 5938,
                name = "Shiv",
                priority = nil,
                talentReq = "Deathstalker",
                why = "On cooldown under Deathstalker — extra poison application woven into the Mark loop.",
                tags = { "active" },
            },
            {
                spellID = 381623,
                name = "Thistle Tea",
                priority = nil,
                why = "Energy cooldown, one charge per minute and auto-activates below 30 Energy. Use to avoid capping charges or to chain Envenoms during a CD window.",
                tags = { "active" },
                when = C.PowerBelow(30),
            },
        },
    },
}
R[260] = { -- Outlaw
    -- Hero talents: Trickster is the current default for essentially all
    -- content, in both single-target and AoE. Fatebound is a viable
    -- alternative whose main rotational difference is a slightly different
    -- CP threshold for Dispatch. Apex talent: Gravedigger — each Between the
    -- Eyes has a chance to add a stack of its buff, building toward a free
    -- BtE that costs neither a GCD-worthy resource nor its cooldown. Tier
    -- set (Curse of Ula'tek) 2pc/4pc are pure damage amps with no rotation
    -- impact — they just let Energy flow more smoothly.
    solo = {
        tip = "Outlaw leveling: Roll the Bones for a buff stage, Sinister Strike/Pistol Shot to build CP, Dispatch to spend, Between the Eyes on CD. Adrenaline Rush on CD.",
        priorities = {
            {
                spellID = 193316,
                name = "Roll the Bones",
                priority = 1,
                why = "Cast on CD unless already at Stage 2+ — rerolling a good buff loses value.",
                tags = { "core" },
            },
            { spellID = 315496, name = "Slice and Dice", priority = 2, why = "Maintain the attack-speed buff.", tags = { "core" } },
            {
                spellID = 315341,
                name = "Between the Eyes",
                priority = 3,
                why = "On CD with 6+ CP — stacking crit debuff, and feeds Gravedigger once unlocked.",
                tags = { "active" },
            },
            { spellID = 2098, name = "Dispatch", priority = 4, why = "Primary finisher at 5-6+ CP.", tags = { "core" }, when = C.ComboAtLeast(5) },
            {
                spellID = 193315,
                name = "Sinister Strike",
                priority = 5,
                why = "Main combo point generator.",
                tags = { "active" },
            },
            {
                spellID = 185763,
                name = "Pistol Shot",
                priority = nil,
                why = "Free/cheap CP generator at 6 Opportunity stacks — use it before it falls off.",
                tags = { "active" },
                when = C.BuffStacks(195627, 6),
            },
            {
                spellID = 13750,
                name = "Adrenaline Rush",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Energy regen, max Energy, and attack speed. Use on CD, ideally at low CP.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Outlaw AoE: Blade Flurry on CD once a 2nd target is in range (ideally at low CP), then the single-target priority — every finisher and generator cleaves.",
        chain = {
            { spellID = 13877, name = "Blade Flurry" },
            { spellID = 193315, name = "Sinister Strike" },
            { spellID = 2098, name = "Dispatch" },
        },
        priorities = {
            {
                spellID = 13877,
                name = "Blade Flurry",
                priority = 1,
                why = "On CD with 2+ targets in range — try to use it at low Combo Points so you don't waste a nearly-capped resource.",
                tags = { "core", "aoe" },
                when = C.AoE(2),
            },
            {
                spellID = 193316,
                name = "Roll the Bones",
                priority = 2,
                why = "On CD unless already Stage 2+.",
                tags = { "core" },
            },
            {
                spellID = 381989,
                name = "Keep It Rolling",
                priority = nil,
                why = "Extends Roll the Bones 30s — best at Stage 3+, still fine at Stage 2+ for consistency.",
                tags = { "active" },
            },
            {
                spellID = 315341,
                name = "Between the Eyes",
                priority = 3,
                why = "On CD with 6+ CP.",
                tags = { "active" },
            },
            { spellID = 2098, name = "Dispatch", priority = 4, why = "At 5-6+ CP, cleaved by Blade Flurry.", tags = { "core" }, when = C.ComboAtLeast(5) },
            {
                spellID = 193315,
                name = "Sinister Strike",
                priority = 5,
                why = "CP generator — cleaved by Blade Flurry.",
                tags = { "core", "aoe" },
            },
            {
                spellID = 51690,
                name = "Killing Spree",
                priority = nil,
                isCd = true,
                why = "At 6+ CP while Supercharger is active — hits every nearby enemy.",
                tags = { "cd", "aoe" },
            },
            {
                spellID = 13750,
                name = "Adrenaline Rush",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst cleave window — Energy/attack-speed CD on cooldown.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Outlaw raid ST (Trickster): RtB on CD (Keep It Rolling at Stage 3+), Adrenaline Rush on CD at low CP, Between the Eyes at 6+ CP, Killing Spree under Supercharger, Dispatch/Sinister Strike/Pistol Shot to fill.",
        priorities = {
            {
                spellID = 193316,
                name = "Roll the Bones",
                priority = 1,
                why = "Cast on CD unless already at Stage 2 or higher — don't roll away a good buff.",
                tags = { "core" },
            },
            {
                spellID = 381989,
                name = "Keep It Rolling",
                priority = nil,
                why = "Extends the current Roll the Bones buff by 30s — best used at Stage 3+, acceptable at Stage 2+ for consistency.",
                tags = { "active" },
            },
            {
                spellID = 13750,
                name = "Adrenaline Rush",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Use on cooldown, ideally at low Combo Points — Energy regen, max Energy, attack speed, and a hidden GCD-haste bonus.",
                tags = { "cd" },
            },
            {
                spellID = 315341,
                name = "Between the Eyes",
                priority = 2,
                why = "Main finisher for damage — cast on CD with 6+ CP; each cast has a chance to build toward Gravedigger's free BtE.",
                tags = { "core" },
                when = C.ComboAtLeast(6),
            },
            {
                spellID = 51690,
                name = "Killing Spree",
                priority = nil,
                isCd = true,
                why = "At 6+ CP while the Supercharger proc is active — don't use it outside that window.",
                tags = { "cd" },
            },
            {
                spellID = 2098,
                name = "Dispatch",
                priority = 3,
                why = "Primary finisher at 5-6+ CP whenever the CD-gated finishers above aren't available.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            {
                spellID = 193315,
                name = "Sinister Strike",
                priority = 4,
                why = "Main combo point generator.",
                tags = { "core" },
            },
            {
                spellID = 185763,
                name = "Pistol Shot",
                priority = nil,
                why = "Cheap, high-value CP generator at 6 stacks of Opportunity — spend it before the buff falls off.",
                tags = { "active" },
                when = C.BuffStacks(195627, 6),
            },
            {
                spellID = 315496,
                name = "Slice and Dice",
                priority = nil,
                why = "Baseline attack-speed maintenance buff — keep it up if you're not fully covered by Roll the Bones stages.",
                tags = { "active" },
                when = C.BuffRefresh(315496, 4),
            },
            {
                spellID = 271877,
                name = "Blade Rush",
                priority = nil,
                isCd = true,
                why = "Opener/on-CD burst — leads into the CP-building phase before Between the Eyes.",
                tags = { "cd" },
            },
        },
    },
}
R[261] = { -- Subtlety
    -- Hero talents: Deathstalker is the clear default for both single-target
    -- and AoE (its Darkest Night capstone — 30 Energy plus a guaranteed-crit,
    -- +50%-damage 5+ CP Eviscerate — outdamages Trickster in every scenario
    -- tested). Apex talent: Ancient Arts — consuming Shadow Techniques
    -- stacks on a builder spawns a damaging Shadow clone, passively boosts
    -- all Shadow damage and regenerates stacks as clones spawn, and at rank 3
    -- lets a builder with 5+ stacks remaining make your next finisher consume
    -- them all for a free, fully-comboed back-to-back finisher. Tier set
    -- (Curse of Ula'tek): 2pc cuts Backstab/Shuriken Storm Energy cost so
    -- almost every non-Dance GCD is filled; 4pc extends Lingering Shadow to
    -- also buff Eviscerate/Black Powder, making Lingering Shadow mandatory
    -- with the set (swap it for Dark Shadow if you don't have 4pc) and
    -- shifting damage later into the Shadow Blades window.
    solo = {
        tip = "Subtlety leveling: Shadow Dance → Shadowstrike for CP, Eviscerate at 5+ CP, Backstab outside Dance, Symbols of Death on CD. Goremaw's Bite and the hero-talent capstones unlock at 71.",
        priorities = {
            {
                spellID = 185438,
                name = "Shadowstrike",
                priority = 1,
                why = "During Shadow Dance (or from Stealth) — the biggest single-hit CP generator.",
                tags = { "core" },
            },
            {
                spellID = 196819,
                name = "Eviscerate",
                priority = 2,
                why = "At 5+ CP — primary finisher.",
                tags = { "core" },
                when = C.ComboAtLeast(5),
            },
            { spellID = 53, name = "Backstab", priority = 3, why = "CP generator outside Shadow Dance.", tags = { "core" } },
            {
                spellID = 185313,
                name = "Shadow Dance",
                priority = 4,
                why = "Enter stealth to empower Shadowstrike and other Stealth-only effects.",
                tags = { "core" },
            },
            {
                spellID = 212283,
                name = "Symbols of Death",
                priority = nil,
                isCd = true,
                why = "Flat damage buff — use on CD.",
                tags = { "cd" },
            },
            {
                spellID = 209782,
                name = "Goremaw's Bite",
                priority = nil,
                isCd = true,
                unlockLv = 71,
                why = "Unlocks with your Hero Talent tree — cast right before your other cooldowns.",
                tags = { "cd" },
            },
            {
                spellID = 121471,
                name = "Shadow Blades",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst CD — extra CP generation from every builder.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Subtlety AoE: Shuriken Storm to build CP, Black Powder at 6 CP, Shadow Dance to empower and reset the loop; Goremaw's Bite before cooldowns.",
        chain = {
            { spellID = 197835, name = "Shuriken Storm" },
            { spellID = 319175, name = "Black Powder" },
            { spellID = 185313, name = "Shadow Dance" },
        },
        priorities = {
            {
                spellID = 209782,
                name = "Goremaw's Bite",
                priority = 1,
                why = "Cast whenever ready, right before your other cooldowns.",
                tags = { "cd" },
                isCd = true,
                unlockLv = 71,
            },
            {
                spellID = 185313,
                name = "Shadow Dance",
                priority = 2,
                why = "Pair 2 casts with every Shadow Blades window; otherwise on CD for empowered effects.",
                tags = { "core" },
            },
            {
                spellID = 121471,
                name = "Shadow Blades",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "AoE burst — always land 2 Shadow Dance casts inside its 90s window; don't open a Dance with less than 10s of Shadow Blades left.",
                tags = { "cd" },
            },
            {
                spellID = 196819,
                name = "Eviscerate",
                priority = 3,
                why = "At 6+ CP when Darkest Night is active — always take priority over Black Powder while the buff is up.",
                tags = { "active" },
                when = C.And(C.ComboAtLeast(6), C.HasBuff(457058)),
            },
            {
                spellID = 319175,
                name = "Black Powder",
                priority = 4,
                why = "AoE finisher at 6 CP once Darkest Night isn't active.",
                tags = { "core", "aoe" },
                when = C.ComboAtLeast(6),
            },
            {
                spellID = 197835,
                name = "Shuriken Storm",
                priority = 5,
                why = "AoE combo point generator.",
                tags = { "core", "aoe" },
            },
        },
    },
    st = {
        tip = "Subtlety raid ST (Deathstalker): Goremaw's Bite before cooldowns, Shadow Dance timed around Secret Technique/Shadow Blades, Eviscerate at 6 CP (guaranteed crit under Darkest Night), Coup de Grace and Shadowstrike/Backstab to fill.",
        priorities = {
            {
                spellID = 209782,
                name = "Goremaw's Bite",
                priority = 1,
                why = "Cast whenever it's ready, right before your other cooldowns — unlocks with your Hero Talent tree.",
                tags = { "cd" },
                isCd = true,
                unlockLv = 71,
            },
            {
                spellID = 185313,
                name = "Shadow Dance",
                priority = 2,
                why = "At 6+ CP (or ≤2 CP to dump into a fresh builder chain) whenever Secret Technique is ready or Shadow Blades is active. Always fit 2 casts inside every Shadow Blades window; never open one with under 10s of Shadow Blades left.",
                tags = { "core" },
            },
            {
                spellID = 121471,
                name = "Shadow Blades",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Cast during Shadow Dance. Major burst CD every 90s — line up potions/racials with it.",
                tags = { "cd" },
            },
            {
                spellID = 196819,
                name = "Eviscerate",
                priority = 3,
                why = "At 6+ CP while Darkest Night is active — guaranteed crit and +50% damage takes priority over everything else.",
                tags = { "active" },
                when = C.And(C.ComboAtLeast(6), C.HasBuff(457058)),
            },
            {
                spellID = 280719,
                name = "Secret Technique",
                priority = 4,
                why = "During Shadow Dance with 6+ CP — high-value hard-hitting finisher.",
                tags = { "active" },
                when = C.And(C.ComboAtLeast(6), C.HasBuff(185422)),
            },
            {
                spellID = 37171,
                name = "Coup de Grace",
                priority = 5,
                why = "At 6+ CP once Secret Technique and the Darkest Night Eviscerate aren't available.",
                tags = { "active" },
                when = C.ComboAtLeast(6),
            },
            {
                spellID = 196819,
                name = "Eviscerate",
                priority = 6,
                why = "Default finisher at 6+ CP when nothing above applies.",
                tags = { "core" },
                when = C.ComboAtLeast(6),
            },
            {
                spellID = 185438,
                name = "Shadowstrike",
                priority = 7,
                why = "Use whenever available (Stealth, Shadow Dance, proc) — otherwise fall back to Backstab.",
                tags = { "core" },
            },
            { spellID = 53, name = "Backstab", priority = 8, why = "Combo point generator outside Shadowstrike windows.", tags = { "core" } },
            {
                spellID = 212283,
                name = "Symbols of Death",
                priority = nil,
                isCd = true,
                why = "Flat damage buff — on CD, ideally lined up with Shadow Dance.",
                tags = { "cd" },
            },
            {
                spellID = 1856,
                name = "Vanish",
                priority = nil,
                isCd = true,
                why = "Opener/re-opener — guarantees a Stealth Shadowstrike. Weave into cooldown windows when available mid-fight.",
                tags = { "cd" },
            },
        },
    },
}

-- ── MONK ──────────────────────────────────────────────────────────────
-- Brewmaster/Windwalker/Mistweaver rewritten 2026-09-05 for Patch 12.1
-- "Midnight" Season 2 (Curse of Ula'tek: The Venomous Abyss). Cross-checked
-- against Icy Veins' rotation/cooldown/talent guides, Wowhead's class
-- guides, and Method.gg's talent guides (all current as of 2026-09).
--
-- Hero talent trees are shared in pairs across the 3 specs:
--   Master of Harmony (Brewmaster + Mistweaver) -- Harmonic Surge /
--   Aspect of Harmony vitality stacks feed Keg Smash and Celestial Brew
--   (BrM) or pair Thunder Focus Tea with burst windows (MW). Smoother and
--   more consistent than the alternative.
--   Shado-Pan (Brewmaster + Windwalker) -- autoattacks generate Flurry
--   Strikes, unleashed through Keg Smash or your Chi spenders for spread
--   cleave damage. Higher ceiling, spikier, favored for wide M+ pulls.
--   Conduit of the Celestials (Windwalker + Mistweaver) -- built around
--   Celestial Conduit and Heart of the Jade Serpent cooldown reduction.
--   The current default/recommended pick for both WW and MW; Shado-Pan
--   and Master of Harmony are this tier's raid-oriented alternatives.
-- Each spec's Apex talent (the single capstone above the talent tree) is
-- called out in that spec's comment below.

-- Brewmaster -- default hero talent Master of Harmony (smoother Stagger
-- mitigation via Celestial Brew-fed Harmonic Surge); Shado-Pan trades that
-- for more Flurry Strikes/Keg Smash-driven cleave in wide M+ pulls.
-- Apex talent: Bring Me Another -- brews have a chance for your next Keg
-- Smash to throw a bonus barrel; catching a barrel resets Keg Smash and
-- makes the next cast free and stronger, and drinking a defensive brew
-- heals nearby allies and buffs barrel damage. This is why Keg Smash and
-- the brew cooldowns are kept on as tight a shared cadence as possible
-- instead of spaced out.
-- Season 2 tier set (Curse of Ula'tek): 2pc -- Breath of Fire ignites your
-- next Keg Smash, making it explode for bonus Fire damage; 4pc -- those
-- ignited Keg Smashes add an 8% Physical-damage-taken debuff on the target
-- plus a burning ground patch. Keep Breath of Fire and Keg Smash close
-- together to chain the ignite-and-detonate loop.
R[268] = { -- Brewmaster
    solo = {
        tip = "Brewmaster solo (Master of Harmony default): Keg Smash on CD to build Shuffle and reduce brew CDs, Blackout Kick/Tiger Palm fill the gaps, Purifying/Celestial Brew when hit hard. Pull big -- cleave carries solo content.",
        priorities = {
            {
                spellID = 121253,
                name = "Keg Smash",
                priority = 1,
                why = "AoE hit that reduces brew cooldowns by 3s and applies a slow -- the backbone of the rotation. Use on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 205523,
                name = "Blackout Kick",
                priority = 2,
                why = "Refreshes Shuffle (avoidance) and reduces brew cooldowns by 1s.",
                tags = { "core" },
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 3,
                why = "Energy dump / Blackout Combo consumer between Keg Smash casts.",
                tags = { "active" },
            },
            {
                spellID = 123986,
                name = "Chi Burst",
                priority = 4,
                why = "AoE damage plus a self-heal on the return trip -- use on cooldown if talented.",
                tags = { "core" },
            },
            {
                spellID = 119582,
                name = "Purifying Brew",
                priority = 5,
                why = "Clears Stagger -- press when the Stagger bar is yellow/red rather than banking both charges.",
                tags = { "defensive" },
                when = C.HealthBelow(80),
            },
            {
                spellID = 322507,
                name = "Celestial Brew",
                priority = 6,
                why = "Absorb shield, fed by Harmonic Surge under Master of Harmony -- use before a big hit or on cooldown.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 115203,
                name = "Fortifying Brew",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency defensive -- extra max health and damage reduction. Save for dangerous pulls or a healer being overwhelmed.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Brewmaster M+ (Shado-Pan favored for wide pulls, Flurry Strikes spreads damage): open with Invoke Niuzao, weave Breath of Fire and Keg Smash while he is up, keep Keg Smash/Breath of Fire on the tightest cadence the tier set's ignite loop allows, and only Purify above light Stagger.",
        chain = {
            { spellID = 121253, name = "Keg Smash" },
            { spellID = 115181, name = "Breath of Fire" },
            { spellID = 205523, name = "Blackout Kick" },
            { spellID = 100780, name = "Tiger Palm" },
            { spellID = 121253, name = "Keg Smash" },
        },
        priorities = {
            {
                spellID = 121253,
                name = "Keg Smash",
                priority = 1,
                why = "Highest-priority filler -- brew CDR, slow, and (with the 2pc) sets up the Breath of Fire ignite. Cast on the tightest cadence you can manage.",
                tags = { "core" },
            },
            {
                spellID = 115181,
                name = "Breath of Fire",
                priority = 2,
                why = "Cone DoT; with the tier set it ignites your next Keg Smash for bonus Fire damage plus (4pc) a Physical-damage-taken debuff and burning ground.",
                tags = { "core" },
            },
            {
                spellID = 205523,
                name = "Blackout Kick",
                priority = 3,
                why = "Refreshes Shuffle and reduces brew cooldowns.",
                tags = { "core" },
            },
            {
                spellID = 101546,
                name = "Spinning Crane Kick",
                priority = 4,
                why = "PBAoE filler once 3+ enemies are in range -- do not spam it ahead of Keg Smash/Breath of Fire.",
                tags = { "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 5,
                why = "Energy dump / Blackout Combo filler between casts.",
                tags = { "active" },
            },
            {
                spellID = 123986,
                name = "Chi Burst",
                priority = 6,
                why = "AoE damage plus healing on the return trip -- on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 119582,
                name = "Purifying Brew",
                priority = 7,
                why = "Clear Stagger before it turns red -- do not bank both charges.",
                tags = { "defensive" },
                when = C.HealthBelow(80),
            },
            {
                spellID = 322507,
                name = "Celestial Brew",
                priority = 8,
                why = "Absorb shield -- use ahead of a scripted damage spike.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 132578,
                name = "Invoke Niuzao, the Black Ox",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Primary damage/threat cooldown -- commit to a pull that will last 25+ seconds before popping. Align with Bring Me Another barrel procs.",
                tags = { "cd" },
            },
            {
                spellID = 325153,
                name = "Exploding Keg",
                priority = nil,
                isCd = true,
                why = "Resets Keg Smash charges for a burst window -- use alongside Niuzao or a tier-set ignite chain.",
                tags = { "cd" },
            },
            {
                spellID = 115203,
                name = "Fortifying Brew",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency defensive -- extra max health and damage reduction for a dangerous pull.",
                tags = { "defensive" },
            },
            { spellID = 115399, name = "Black Ox Brew", priority = nil, isCd = true, why = "Off the GCD — refills brews (Icy Veins 12.1 priority #1).", tags = { "cd" } },
            { spellID = 116847, name = "Rushing Jade Wind", priority = 9, why = "Keep up when talented.", tags = { "active" } },
        },
    },
    st = {
        tip = "Brewmaster raid (Master of Harmony default for consistent physical mitigation): same core loop as M+ -- Keg Smash, Blackout Kick, Tiger Palm -- spend Purifying/Celestial Brew proactively into scripted damage, and save Invoke Niuzao/Exploding Keg for your assigned cooldown window.",
        priorities = {
            {
                spellID = 121253,
                name = "Keg Smash",
                priority = 1,
                why = "On cooldown -- brew CDR, slow, sets up the tier-set ignite with Breath of Fire.",
                tags = { "core" },
            },
            {
                spellID = 205523,
                name = "Blackout Kick",
                priority = 2,
                why = "Refreshes Shuffle and reduces brew cooldowns.",
                tags = { "core" },
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 3,
                why = "Energy dump / Blackout Combo filler.",
                tags = { "active" },
            },
            {
                spellID = 123986,
                name = "Chi Burst",
                priority = 4,
                why = "AoE damage plus healing -- on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 119582,
                name = "Purifying Brew",
                priority = 5,
                why = "Clear Stagger proactively into known damage windows, not only when already high.",
                tags = { "defensive" },
                when = C.HealthBelow(80),
            },
            {
                spellID = 322507,
                name = "Celestial Brew",
                priority = 6,
                why = "Absorb shield -- time it just ahead of a scripted raid mechanic.",
                tags = { "defensive" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 132578,
                name = "Invoke Niuzao, the Black Ox",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major damage/threat cooldown -- align with your assigned raid CD window.",
                tags = { "cd" },
            },
            {
                spellID = 325153,
                name = "Exploding Keg",
                priority = nil,
                isCd = true,
                why = "Resets Keg Smash charges -- pair with Niuzao for a burst window.",
                tags = { "cd" },
            },
            {
                spellID = 115203,
                name = "Fortifying Brew",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency defensive for unavoidable raid damage or a healer in trouble.",
                tags = { "defensive" },
            },
            { spellID = 115399, name = "Black Ox Brew", priority = nil, isCd = true, why = "Off the GCD — refills brews (Icy Veins 12.1 priority #1).", tags = { "cd" } },
            { spellID = 116847, name = "Rushing Jade Wind", priority = 7, why = "Keep up when talented.", tags = { "active" } },
        },
    },
}

-- Windwalker -- default hero talent Conduit of the Celestials (built
-- around Celestial Conduit and Invoke Xuen's Heart of the Jade Serpent
-- cooldown reduction); Shado-Pan is the raid/M+ alternative for very wide
-- pulls (Flurry Strikes spreads damage more evenly across many targets).
-- Apex talent: Tigereye Brew -- combat generates brew stacks, spent when
-- you cast Zenith for bonus Critical Strike chance; space Zenith casts out
-- rather than chaining them back to back so stacks have time to build.
-- Season 2 tier set (Curse of Ula'tek): 2pc -- Fists of Fury strikes an
-- extra time (50% effectiveness) at the start of its channel; 4pc
-- (Unbroken Rhythm) -- each Fists of Fury tick empowers your next Rising
-- Sun Kick (+10% damage) or Spinning Crane Kick (+20% damage), stacking up
-- to 6 times. On 2+ targets this pulls Spinning Crane Kick up the priority
-- list to spend those stacks before they fall off.
R[269] = { -- Windwalker
    solo = {
        tip = "Windwalker solo: Combo Strikes mastery -- never repeat the exact same ability twice in a row. Tiger Palm/Blackout Kick build and spend Chi, Rising Sun Kick and Fists of Fury on cooldown, Spinning Crane Kick at 3+ targets.",
        priorities = {
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 1,
                why = "Hardest-hitting spender and its cooldown is reduced by Teachings of the Monastery -- use whenever available.",
                tags = { "core" },
            },
            {
                spellID = 113656,
                name = "Fists of Fury",
                priority = 2,
                why = "Channel -- biggest single-target and cleave chunk. Use on cooldown; empowered further by Heart of the Jade Serpent from Xuen/Celestial Conduit.",
                tags = { "core" },
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 3,
                why = "Chi spender -- alternate with Tiger Palm to keep Combo Strikes rolling.",
                tags = { "core" },
                when = C.ComboAtLeast(2),
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 4,
                why = "Chi generator -- never cast back-to-back with itself; alternate with Blackout Kick.",
                tags = { "core" },
                when = C.ComboBelow(4),
            },
            {
                spellID = 101546,
                name = "Spinning Crane Kick",
                priority = 5,
                why = "3+ targets, or to spend Unbroken Rhythm stacks before they fall off.",
                tags = { "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 152175,
                name = "Whirling Dragon Punch",
                priority = 6,
                why = "Free burst hit unlocked after landing Rising Sun Kick and Fists of Fury close together -- use immediately when up.",
                tags = { "active" },
            },
            {
                spellID = 123904,
                name = "Invoke Xuen, the White Tiger",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Primary burst cooldown -- summons Xuen and enables a follow-up Celestial Conduit for the big damage window.",
                tags = { "cd" },
            },
            {
                spellID = 122470,
                name = "Touch of Karma",
                priority = nil,
                isCd = true,
                why = "Personal defensive that reflects a portion of absorbed damage back at the target -- use ahead of a big hit.",
                tags = { "defensive" },
            },
        },
    },
    aoe = {
        tip = "Windwalker M+/cleave (Conduit of the Celestials, or Shado-Pan for the widest spread): priority barely shifts from single-target -- Spinning Crane Kick moves up once Unbroken Rhythm stacks (tier 4pc) or 3+ targets are up. Keep landing Rising Sun Kick and Fists of Fury close together for Whirling Dragon Punch and Strike of the Windlord resets. Storm, Earth, and Fire has been removed from the kit -- Invoke Xuen + Celestial Conduit is now the burst package.",
        chain = {
            { spellID = 107428, name = "Rising Sun Kick" },
            { spellID = 113656, name = "Fists of Fury" },
            { spellID = 152175, name = "Whirling Dragon Punch" },
            { spellID = 392983, name = "Strike of the Windlord" },
            { spellID = 101546, name = "Spinning Crane Kick" },
        },
        priorities = {
            {
                spellID = 113656,
                name = "Fists of Fury",
                priority = 1,
                why = "Channel hits everyone in range and feeds Unbroken Rhythm stacks (tier 4pc) for Spinning Crane Kick/Rising Sun Kick. On cooldown.",
                tags = { "core" },
            },
            {
                spellID = 101546,
                name = "Spinning Crane Kick",
                priority = 2,
                why = "Primary AoE spender once Unbroken Rhythm stacks are up or 3+ targets are in range -- spend stacks before they fall off.",
                tags = { "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 3,
                why = "Still core damage in AoE -- keep on cooldown, empowered by Unbroken Rhythm stacks.",
                tags = { "core" },
            },
            {
                spellID = 392983,
                name = "Strike of the Windlord",
                priority = 4,
                why = "Big cleave hit on its own cooldown -- use as soon as available.",
                tags = { "active" },
            },
            {
                spellID = 152175,
                name = "Whirling Dragon Punch",
                priority = 5,
                why = "Free reset window when Rising Sun Kick and Fists of Fury landed close together.",
                tags = { "active" },
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 6,
                why = "Spender filler between bigger hits -- keep Combo Strikes going.",
                tags = { "core" },
                when = C.ComboAtLeast(2),
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 7,
                why = "Generator filler.",
                tags = { "active" },
                when = C.ComboBelow(4),
            },
            {
                spellID = 123904,
                name = "Invoke Xuen, the White Tiger",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst cooldown -- commit before a big pull, pairs with Celestial Conduit.",
                tags = { "cd" },
            },
            {
                spellID = 443028,
                name = "Celestial Conduit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Channeled burst cooldown that grants Heart of the Jade Serpent -- align with Xuen and any raid cooldowns/trinkets.",
                tags = { "cd" },
            },
            {
                spellID = 122470,
                name = "Touch of Karma",
                priority = nil,
                isCd = true,
                why = "Personal defensive with a damage-reflect component -- use ahead of a predictable spike.",
                tags = { "defensive" },
            },
        },
    },
    st = {
        tip = "Windwalker raid single-target: Rising Sun Kick and Fists of Fury on cooldown, Blackout Kick/Tiger Palm filling Chi between them, Whirling Dragon Punch and Strike of the Windlord for their free windows. Storm, Earth, and Fire has been removed from the kit -- Invoke Xuen + Celestial Conduit is the burst package, timed with raid cooldowns.",
        priorities = {
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 1,
                why = "Highest-priority spender -- use whenever available.",
                tags = { "core" },
            },
            {
                spellID = 113656,
                name = "Fists of Fury",
                priority = 2,
                why = "On cooldown -- channel, further empowered by Heart of the Jade Serpent.",
                tags = { "core" },
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 3,
                why = "Chi spender -- alternate with Tiger Palm for Combo Strikes.",
                tags = { "core" },
                when = C.ComboAtLeast(2),
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 4,
                why = "Chi generator filler.",
                tags = { "core" },
                when = C.ComboBelow(4),
            },
            {
                spellID = 392983,
                name = "Strike of the Windlord",
                priority = 5,
                why = "On cooldown -- strong cleave hit that also hits your primary target hard.",
                tags = { "active" },
            },
            {
                spellID = 152175,
                name = "Whirling Dragon Punch",
                priority = 6,
                why = "Free burst hit after Rising Sun Kick + Fists of Fury landed close together.",
                tags = { "active" },
            },
            {
                spellID = 123904,
                name = "Invoke Xuen, the White Tiger",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Burst cooldown -- align with your raid cooldown window.",
                tags = { "cd" },
            },
            {
                spellID = 443028,
                name = "Celestial Conduit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Channeled burst cooldown, grants Heart of the Jade Serpent -- pair with Xuen.",
                tags = { "cd" },
            },
            {
                spellID = 322109,
                name = "Touch of Death",
                priority = nil,
                isCd = true,
                why = "Big single hit for burst -- use on cooldown alongside your other cooldowns.",
                tags = { "cd" },
            },
            {
                spellID = 122470,
                name = "Touch of Karma",
                priority = nil,
                isCd = true,
                why = "Personal defensive/offensive hybrid -- use ahead of a predictable hit.",
                tags = { "defensive" },
            },
        },
    },
}

-- Mistweaver -- default hero talent Conduit of the Celestials (Thunder
-- Focus Tea timed with Heart of the Jade Serpent cooldown reduction);
-- Master of Harmony is the alternative, built around Aspect of Harmony
-- vitality stacks paired with Thunder Focus Tea for burst healing windows.
-- Apex talent: Unity Within -- summons all four Celestials (Xuen, Niuzao,
-- Chi-Ji, and Yu'lon) together for a short, massively amplified cooldown;
-- save it for the raid's single biggest incoming-damage window.
-- Season 2 tier set (Curse of Ula'tek: The Venomous Abyss): 2pc -- Rising
-- Sun Kick deals 30% more damage and Rushing Wind Kick's healing is +100%;
-- 4pc -- Rising Sun Kick and Rushing Wind Kick have a chance to make their
-- next cast free (cooldown reset, -100% mana cost). This keeps fistweaving
-- (Rising Sun Kick/Blackout Kick/Tiger Palm) worth pressing even in a
-- pure-healing setup.
R[270] = { -- Mistweaver
    solo = {
        tip = "Mistweaver solo: fistweave -- Rising Sun Kick and Blackout Kick for damage that also heals via Ancient Teachings, Tiger Palm filler, Vivify when you dip low, Soothing Mist to top off on the move.",
        priorities = {
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 1,
                why = "Best damage-to-healing return via Ancient Teachings, and buffed by the Season 2 tier 2pc. Use on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 2,
                why = "Melee filler that also heals via Ancient Teachings.",
                tags = { "core" },
            },
            {
                spellID = 100780,
                name = "Tiger Palm",
                priority = 3,
                why = "Chi filler between Rising Sun Kick casts.",
                tags = { "active" },
            },
            {
                spellID = 116670,
                name = "Vivify",
                priority = 4,
                why = "Direct heal -- press when you drop below roughly 50%.",
                tags = { "core" },
                when = C.HealthBelow(50),
            },
            {
                spellID = 115175,
                name = "Soothing Mist",
                priority = 5,
                why = "Channeled heal while moving; lets you instant-cast other spells on the channel target without breaking it.",
                tags = { "active" },
            },
            {
                spellID = 116849,
                name = "Life Cocoon",
                priority = nil,
                isCd = true,
                why = "Absorb shield that also boosts incoming HoT healing by 50% -- use ahead of a big hit.",
                tags = { "defensive" },
            },
            {
                spellID = 115310,
                name = "Revival",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Emergency group heal plus a dispel -- save for real trouble.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Mistweaver M+ (Conduit of the Celestials default): keep 3 charges of Renewing Mist rolling, dump Thunder Focus Tea into Renewing Mist/Enveloping Mist, fistweave Rising Sun Kick/Blackout Kick between casts for extra healing and tier-set procs, Life Cocoon on anyone about to die.",
        chain = {
            { spellID = 115151, name = "Renewing Mist" },
            { spellID = 107428, name = "Rising Sun Kick" },
            { spellID = 100784, name = "Blackout Kick" },
            { spellID = 116670, name = "Vivify" },
        },
        priorities = {
            {
                spellID = 115151,
                name = "Renewing Mist",
                priority = 1,
                why = "Keep 3 charges rolling on cooldown -- enables Vivify's cleave heal and Spiritfont procs.",
                tags = { "core" },
            },
            {
                spellID = 116680,
                name = "Thunder Focus Tea",
                priority = 2,
                why = "Empowers your next Renewing Mist/Rising Sun Kick/Enveloping Mist -- use on cooldown, do not let it cap.",
                tags = { "active" },
            },
            {
                spellID = 116670,
                name = "Vivify",
                priority = 3,
                why = "Heals the cast target plus everyone with your Renewing Mist active -- spam between bigger casts.",
                tags = { "core" },
            },
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 4,
                why = "Fistweave damage-into-healing, buffed by the tier set -- keep on cooldown even while actively healing.",
                tags = { "core" },
            },
            {
                spellID = 124682,
                name = "Enveloping Mist",
                priority = 5,
                why = "Strong HoT plus damage reduction on whoever is taking the most damage.",
                tags = { "core" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 101546,
                name = "Spinning Crane Kick",
                priority = 6,
                why = "5+ targets, or when a Dance of Chi-Ji proc is up.",
                tags = { "aoe" },
                when = C.AoE(5),
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 7,
                why = "Fistweave filler between spenders.",
                tags = { "active" },
            },
            {
                spellID = 197908,
                name = "Mana Tea",
                priority = 8,
                why = "Banks stacks passively -- drink at 20 stacks for a large mana refund rather than letting it cap.",
                tags = { "active" },
            },
            {
                spellID = 116849,
                name = "Life Cocoon",
                priority = nil,
                isCd = true,
                why = "Absorb plus 50% HoT boost -- save for a target about to take a big hit.",
                tags = { "defensive" },
            },
            {
                spellID = 322118,
                name = "Invoke Yu'lon, the Jade Serpent",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "25-second effigy giving periodic raid heals and Chi Cocoon shields, and reduces Enveloping Mist cast time -- primary raid cooldown under Conduit of the Celestials.",
                tags = { "cd" },
            },
            {
                spellID = 325197,
                name = "Invoke Chi-Ji, the Red Crane",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Alternative raid cooldown -- makes Rising Sun Kick/Blackout Kick/Spinning Crane Kick trigger free healing on 2 allies plus a cheap instant Enveloping Mist.",
                tags = { "cd" },
            },
            {
                spellID = 443028,
                name = "Celestial Conduit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Channeled burst-heal cooldown that grants Heart of the Jade Serpent -- pair with Thunder Focus Tea and your Invoke choice. Unity Within (Conduit of the Celestials apex talent, passive -- there is no separate button for it) automatically empowers the recast that triggers when this expires, so plan for two strong healing windows back to back rather than saving a cooldown for it.",
                tags = { "cd" },
            },
            {
                spellID = 115310,
                name = "Revival",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Raid-wide heal plus a Magic/Disease/Poison dispel -- group emergency.",
                tags = { "cd" },
            },
            {
                spellID = 388615,
                name = "Restoral",
                priority = nil,
                isCd = true,
                why = "Revival alternative usable while stunned or silenced -- no dispel, so pick based on the pull's mechanics.",
                tags = { "cd" },
            },
            { spellID = 399491, name = "Sheilun's Gift", priority = 9, why = "Spend clouds for burst healing.", tags = { "active" } },
            { spellID = 388193, name = "Jadefire Stomp", priority = 10, why = "On cooldown when talented.", tags = { "active" } },
        },
    },
    st = {
        tip = "Mistweaver raid (Conduit of the Celestials default, Master of Harmony alt for Aspect of Harmony burst windows): blanket Renewing Mist, Vivify off of it, Enveloping Mist on the tank/heaviest damage, Thunder Focus Tea on cooldown, fistweave Rising Sun Kick/Blackout Kick when nobody is low.",
        priorities = {
            {
                spellID = 115151,
                name = "Renewing Mist",
                priority = 1,
                why = "Blanket the raid -- always on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 116670,
                name = "Vivify",
                priority = 2,
                why = "Primary raid-damage heal; cleaves onto everyone with your Renewing Mist active.",
                tags = { "core" },
            },
            {
                spellID = 124682,
                name = "Enveloping Mist",
                priority = 3,
                why = "Tank or high-damage target HoT plus a damage-taken reduction.",
                tags = { "core" },
                when = C.HealthBelow(70),
            },
            {
                spellID = 116680,
                name = "Thunder Focus Tea",
                priority = 4,
                why = "Empowers your next heal -- use on cooldown, do not cap it.",
                tags = { "active" },
            },
            {
                spellID = 107428,
                name = "Rising Sun Kick",
                priority = 5,
                why = "Fistweave into calm phases for free healing via Ancient Teachings and tier-set damage.",
                tags = { "core" },
            },
            {
                spellID = 100784,
                name = "Blackout Kick",
                priority = 6,
                why = "Fistweave filler when the raid is topped off.",
                tags = { "active" },
            },
            {
                spellID = 116849,
                name = "Life Cocoon",
                priority = nil,
                isCd = true,
                why = "Absorb plus 50% HoT boost -- use ahead of a scripted mechanic.",
                tags = { "defensive" },
            },
            {
                spellID = 322118,
                name = "Invoke Yu'lon, the Jade Serpent",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Primary raid cooldown under Conduit of the Celestials -- periodic raid heals, Chi Cocoon shields, faster Enveloping Mist.",
                tags = { "cd" },
            },
            {
                spellID = 325197,
                name = "Invoke Chi-Ji, the Red Crane",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Alternative raid cooldown -- fistweave hits trigger free group healing plus a cheap instant Enveloping Mist.",
                tags = { "cd" },
            },
            {
                spellID = 443028,
                name = "Celestial Conduit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Channeled burst-heal cooldown -- align with Thunder Focus Tea and raid cooldowns. Unity Within (Conduit of the Celestials apex talent, passive) automatically empowers the recast triggered when this expires -- no separate button, plan for two windows back to back.",
                tags = { "cd" },
            },
            {
                spellID = 115310,
                name = "Revival",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Raid emergency heal plus dispel.",
                tags = { "cd" },
            },
            {
                spellID = 388615,
                name = "Restoral",
                priority = nil,
                isCd = true,
                why = "Revival alternative usable while stunned/silenced -- no dispel.",
                tags = { "cd" },
            },
            { spellID = 399491, name = "Sheilun's Gift", priority = 7, why = "Spend clouds for burst healing.", tags = { "active" } },
            { spellID = 388193, name = "Jadefire Stomp", priority = 8, why = "On cooldown when talented.", tags = { "active" } },
        },
    },
}

-- ── SHAMAN ────────────────────────────────────────────────────────────
-- Elemental / Enhancement / Restoration rewritten 2026-09-05 for Patch 12.1
-- "Midnight" Season 2 (Curse of Ula'tek: The Venomous Abyss).
--
-- Hero talents: all three specs share the Farseer / Stormbringer / Totemic
-- pool, but each spec only chooses between two of the three.
--   Elemental:   Farseer (recommended default) vs Stormbringer (needs 4+
--                targets before Earthquake pulls ahead; Aftershock can
--                overcap Maelstrom in AoE).
--   Enhancement: Stormbringer (recommended default this season, especially
--                at 5-6 targets) vs Totemic (steadier, but behind in most
--                Season 2 content).
--   Restoration: Totemic (recommended default this season -- Lively Totems
--                auto-casts Chain Heal off your totems) vs Farseer (fallen
--                off; its Ancestral Swiftness/Unleash Life Ancestors are
--                weaker than they used to be).
--
-- Apex Talents (Midnight capstone):
--   Elemental:   Feedback Loop -- passive Maelstrom generation + Mastery
--                gain. Doesn't change what you press.
--   Enhancement: Storm Unleashed -- Maelstrom Weapon spent has a chance to
--                refund Crash Lightning's cooldown, lets its weapon buff
--                stack/overlap, and boosts Maelstrom Weapon spenders +
--                weapon imbues.
--   Restoration: Stormstream Totem -- Riptide (and Nature's/Ancestral
--                Swiftness) has a chance to drop a free, empowered Healing
--                Stream Totem outside its normal charges.
--
-- Season 2 tier set "Curse of Ula'tek" (Venomous Abyss) class sets:
--   Elemental:   2pc is a flat spender-damage buff (no priority change).
--                4pc stacks a builder buff (Flowing Elements) and grants
--                free-spender charges (Overcharge); Elemental Blast/Earth
--                Shock move up in priority while both are active.
--   Enhancement: 2pc/4pc both reward keeping Voltaic Blaze on cooldown --
--                it was already a priority ability, the tier just raises
--                the cost of skipping it.
--   Restoration: 2pc -- Healing Wave and Chain Heal drop a temporary
--                Healing Rain at the target's location. 4pc -- allies
--                standing in an active Healing Rain periodically gain an
--                absorb shield, so stacked healing outperforms spread.
--
-- Sources (cross-checked): icy-veins.com "Elemental/Enhancement/Restoration
-- Shaman PvE DPS|Healing Rotation, Cooldowns, and Abilities" (12.1) and
-- "...Spec, Builds, and Talents" (12.1) pages; method.gg "Elemental/
-- Enhancement Shaman Playstyle and Rotation" and "Restoration Shaman
-- Talents" guides (Midnight 12.1). Checked 2026-09-05.
R[262] = { -- Elemental
    solo = {
        tip = "Ele solo: Flame Shock DoT, Lava Burst on CD (guaranteed crit with FS up), Earth Shock at 60+ Maelstrom, Lightning Bolt filler. Farseer's Ancestral Swiftness is a free instant -- use it on CD.",
        priorities = {
            {
                spellID = 188389,
                name = "Flame Shock",
                priority = 1,
                why = "Maintain the DoT -- enables guaranteed Lava Burst crits. Refresh inside the last few seconds, not early.",
                tags = { "core" },
                when = C.DebuffRefresh(188389, 6),
            },
            {
                spellID = 51505,
                name = "Lava Burst",
                priority = 2,
                why = "On cooldown -- always crits with Flame Shock active.",
                tags = { "core" },
            },
            {
                spellID = 8042,
                name = "Earth Shock",
                priority = 3,
                why = "Primary Maelstrom spender at 60+.",
                tags = { "core" },
                when = C.PowerAtLeast(60),
            },
            {
                spellID = 117014,
                name = "Elemental Blast",
                priority = 4,
                why = "Alternate spender -- grants a crit/haste/mastery buff. Interchangeable with Earth Shock on its own cooldown.",
                tags = { "core" },
            },
            {
                spellID = 188196,
                name = "Lightning Bolt",
                priority = 5,
                why = "Filler -- Maelstrom generation.",
                tags = { "active" },
            },
            {
                spellID = 443454,
                name = "Ancestral Swiftness",
                priority = nil,
                isCd = true,
                why = "Farseer -- free instant cast, ideal on Lava Burst or Elemental Blast. Use on cooldown.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            {
                spellID = 191634,
                name = "Stormkeeper",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Empowers your next 2 Lightning Bolt/Chain Lightning casts.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "Ele M+ (Farseer default -- Earthquake is fine at 5 or fewer targets even with no Ancestors up; Stormbringer wants 4+ targets before it's worth it): Flame Shock on 2-3 targets, Voltaic Blaze on CD, Earthquake spender, Chain Lightning filler.",
        chain = {
            { spellID = 191634, name = "Stormkeeper" },
            { spellID = 443454, name = "Ancestral Swiftness" },
            { spellID = 470057, name = "Voltaic Blaze" },
            { spellID = 114050, name = "Ascendance" },
            { spellID = 188389, name = "Flame Shock" },
            { spellID = 61882, name = "Earthquake" },
        },
        priorities = {
            {
                spellID = 188389,
                name = "Flame Shock",
                priority = 1,
                why = "Keep on 2-3 targets for Lava Burst resets and Voltaic Blaze value. Not worth spreading further.",
                tags = { "core" },
                when = C.AoE(2),
            },
            {
                spellID = 470057,
                name = "Voltaic Blaze",
                priority = 2,
                why = "On cooldown -- refreshes Flame Shock and empowers your next Fire spender. Also the class-set 2pc/4pc lever this tier.",
                tags = { "core" },
            },
            {
                spellID = 61882,
                name = "Earthquake",
                priority = 3,
                why = "Ground-target spender at 60+ Maelstrom.",
                tags = { "core" },
                when = C.PowerAtLeast(60),
            },
            {
                spellID = 188443,
                name = "Chain Lightning",
                priority = 4,
                why = "AoE Maelstrom generator/filler.",
                tags = { "core" },
            },
            {
                spellID = 117014,
                name = "Elemental Blast",
                priority = 5,
                why = "Use on a target without Lightning Rod while holding 1 or fewer Tempest stacks.",
                tags = { "active" },
            },
            {
                spellID = 51505,
                name = "Lava Burst",
                priority = 6,
                why = "Off cooldown from multi-Flame Shock procs, or to consume a Lava Surge/Purging Flames proc -- never hardcast in AoE.",
                tags = { "active" },
                when = C.HasBuff(77762),
            },
            {
                spellID = 443454,
                name = "Ancestral Swiftness",
                priority = nil,
                isCd = true,
                why = "Farseer -- on cooldown.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            {
                spellID = 191634,
                name = "Stormkeeper",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Delay slightly on pull-in fights until you can land a 5-target Chain Lightning with it up; otherwise on cooldown.",
                tags = { "cd" },
            },
            {
                spellID = 114050,
                name = "Ascendance",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Sync with Bloodlust, on-use trinkets, and a fresh Stormkeeper.",
                tags = { "cd" },
            },
            { spellID = 196840, name = "Frost Shock", priority = 7, why = "Talented Icefury/movement filler (Icy Veins 12.1 priority).", tags = { "active" } },
        },
    },
    st = {
        tip = "Ele raid (Farseer): Flame Shock up, Lava Burst on CD, Earth Shock/Elemental Blast as spenders, Tempest/Lightning Bolt filler. Class-set 4pc briefly promotes Elemental Blast + Earth Shock when both tier buffs (Flowing Elements, Overcharge) are active.",
        priorities = {
            {
                spellID = 188389,
                name = "Flame Shock",
                priority = 1,
                why = "Maintain -- refresh inside the pandemic window, not early.",
                tags = { "core" },
                when = C.DebuffRefresh(188389, 6),
            },
            {
                spellID = 51505,
                name = "Lava Burst",
                priority = 2,
                why = "On cooldown -- guaranteed crit with Flame Shock up.",
                tags = { "core" },
            },
            {
                spellID = 454009,
                name = "Tempest",
                priority = 3,
                why = "Free cast when it lights up (Static Accumulation) -- always take it over a hardcast spender.",
                tags = { "core" },
            },
            {
                spellID = 8042,
                name = "Earth Shock",
                priority = 4,
                why = "Primary spender at 60+ Maelstrom. Push this and Elemental Blast up in priority when both class-set 4pc buffs (Flowing Elements + Overcharge) are active.",
                tags = { "core" },
                when = C.PowerAtLeast(60),
            },
            {
                spellID = 117014,
                name = "Elemental Blast",
                priority = 5,
                why = "Alternate spender on its own cooldown -- buffs a stat as well as dealing damage.",
                tags = { "core" },
            },
            {
                spellID = 188196,
                name = "Lightning Bolt",
                priority = 6,
                why = "Filler -- prioritize while Master of the Elements is active.",
                tags = { "active" },
                when = C.HasBuff(260734),
            },
            {
                spellID = 443454,
                name = "Ancestral Swiftness",
                priority = nil,
                isCd = true,
                why = "Farseer -- free instant cast, spawns an Ancestor. Use on cooldown, ideally on Lava Burst.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            {
                spellID = 191634,
                name = "Stormkeeper",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Used more or less on cooldown in single-target -- don't hold it more than ~10 sec past availability.",
                tags = { "cd" },
            },
            {
                spellID = 114050,
                name = "Ascendance",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst CD -- sync with Bloodlust/Heroism, on-use trinkets, and a fresh Stormkeeper. Avoid casting into forced movement.",
                tags = { "cd" },
            },
            {
                spellID = 198067,
                name = "Fire Elemental",
                priority = nil,
                isCd = true,
                why = "Long-cooldown pet -- summon on every pull.",
                tags = { "cd" },
            },
            { spellID = 196840, name = "Frost Shock", priority = 7, why = "Talented Icefury/movement filler (Icy Veins 12.1 priority).", tags = { "active" } },
        },
    },
}
R[263] = { -- Enhancement
    solo = {
        tip = "Enh solo: Stormstrike on CD, Lava Lash filler, Flame Shock via Voltaic Blaze. Spend Maelstrom Weapon on Tempest at 10 stacks, otherwise Lightning Bolt at 5+.",
        priorities = {
            {
                spellID = 17364,
                name = "Stormstrike",
                priority = 1,
                why = "Primary melee hit. On cooldown.",
                tags = { "core" },
            },
            {
                spellID = 470057,
                name = "Voltaic Blaze",
                priority = 2,
                why = "Keeps Flame Shock up and empowers your next Fire spender. On cooldown.",
                tags = { "core" },
            },
            {
                spellID = 60103,
                name = "Lava Lash",
                priority = 3,
                why = "Secondary melee hit -- spreads Flame Shock, stronger with Hot Hand.",
                tags = { "core" },
            },
            {
                spellID = 454009,
                name = "Tempest",
                priority = 4,
                why = "Free cast at 10 Maelstrom Weapon stacks -- take this over Lightning Bolt.",
                tags = { "core" },
                when = C.BuffStacks(344179, 10),
            },
            {
                spellID = 188196,
                name = "Lightning Bolt",
                priority = 5,
                why = "Instant spender at 5+ Maelstrom Weapon stacks. Never hold stacks at cap.",
                tags = { "core" },
                when = C.BuffStacks(344179, 5),
            },
            {
                spellID = 51533,
                name = "Feral Spirit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Wolf summons -- Maelstrom Weapon generation + burst.",
                tags = { "cd" },
            },
            { spellID = 188389, name = "Flame Shock", priority = 6, why = "Baseline DoT — keep it up for Lava Lash value.", tags = { "core" } },
        },
    },
    aoe = {
        tip = "Enh M+ (Stormbringer default this season, strongest at 5-6 targets; Totemic is steadier but behind): Crash Lightning for the cleave buff (and Storm Unleashed procs), Voltaic Blaze on CD, Chain Lightning replaces Lightning Bolt the moment there's a 2nd target.",
        chain = {
            { spellID = 470057, name = "Voltaic Blaze" },
            { spellID = 187874, name = "Crash Lightning" },
            { spellID = 335902, name = "Doom Winds" },
            { spellID = 17364, name = "Stormstrike" },
            { spellID = 197214, name = "Sundering" },
            { spellID = 60103, name = "Lava Lash" },
            { spellID = 1218090, name = "Primordial Storm" },
        },
        priorities = {
            {
                spellID = 187874,
                name = "Crash Lightning",
                priority = 1,
                why = "AoE weapon buff that lets Stormstrike/Lava Lash cleave; stacks and overlaps with Storm Unleashed (Apex talent).",
                tags = { "core" },
                when = C.AoE(2),
            },
            {
                spellID = 470057,
                name = "Voltaic Blaze",
                priority = 2,
                why = "On cooldown -- Flame Shock refresh + the class-set 2pc/4pc lever this tier.",
                tags = { "core" },
            },
            {
                spellID = 17364,
                name = "Stormstrike",
                priority = 3,
                why = "Cleaves after Crash Lightning.",
                tags = { "core" },
            },
            {
                spellID = 197214,
                name = "Sundering",
                priority = 4,
                why = "Line-AoE spender -- sync every other cast with Surging Totem.",
                tags = { "core" },
            },
            {
                spellID = 60103,
                name = "Lava Lash",
                priority = 5,
                why = "Cleaves + spreads Flame Shock, stronger with Hot Hand/Whirling Fire.",
                tags = { "core" },
            },
            {
                spellID = 188443,
                name = "Chain Lightning",
                priority = 6,
                why = "Replaces Lightning Bolt the moment there's a 2nd target.",
                tags = { "active" },
                when = C.AoE(2),
            },
            {
                spellID = 454009,
                name = "Tempest",
                priority = 7,
                why = "Free cast at 10 Maelstrom Weapon stacks.",
                tags = { "active" },
                when = C.BuffStacks(344179, 10),
            },
            {
                spellID = 455630,
                name = "Surging Totem",
                priority = nil,
                isCd = true,
                why = "Baseline burst totem -- cast roughly every minute, and time Sundering/Doom Winds into its window.",
                tags = { "cd" },
            },
            {
                spellID = 335902,
                name = "Doom Winds",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Primary 60-sec burst CD -- bank 1-2 charges of Stormstrike/Crash Lightning to fill every GCD and trigger Thorim's Invocation.",
                tags = { "cd" },
            },
            {
                spellID = 114051,
                name = "Ascendance",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "2-min burst window -- 2 free Windstrikes. Talent alternative to a 2nd Doom Winds charge.",
                talentReq = "Ascendance",
                tags = { "cd" },
            },
            {
                spellID = 1218090,
                name = "Primordial Storm",
                priority = nil,
                isCd = true,
                why = "At capped Maelstrom Weapon during Doom Winds -- large AoE nuke, don't let it go to waste.",
                tags = { "cd" },
                when = C.BuffStacks(344179, 10),
            },
            { spellID = 188389, name = "Flame Shock", priority = 8, why = "Baseline DoT — keep it up for Lava Lash value.", tags = { "core" } },
        },
    },
    st = {
        tip = "Enh raid: Voltaic Blaze/Stormstrike priority, Lava Lash filler, Tempest at 10 stacks else Lightning Bolt at 5+. Doom Winds (or Ascendance) on CD.",
        priorities = {
            {
                spellID = 17364,
                name = "Stormstrike",
                priority = 1,
                why = "Highest priority, always. On cooldown.",
                tags = { "core" },
            },
            {
                spellID = 470057,
                name = "Voltaic Blaze",
                priority = 2,
                why = "Maintains Flame Shock and empowers your next Fire spender -- the class-set 2pc/4pc lever this tier. Keep on cooldown.",
                tags = { "core" },
            },
            {
                spellID = 60103,
                name = "Lava Lash",
                priority = 3,
                why = "Filler melee, stronger with Hot Hand.",
                tags = { "core" },
            },
            {
                spellID = 454009,
                name = "Tempest",
                priority = 4,
                why = "Free cast at 10 Maelstrom Weapon stacks -- always take it over a hardcast.",
                tags = { "core" },
                when = C.BuffStacks(344179, 10),
            },
            {
                spellID = 188196,
                name = "Lightning Bolt",
                priority = 5,
                why = "Instant spender at 5+ Maelstrom Weapon stacks.",
                tags = { "core" },
                when = C.BuffStacks(344179, 5),
            },
            {
                spellID = 335902,
                name = "Doom Winds",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Main burst CD -- bank 1-2 Stormstrike/Crash Lightning charges to fill every GCD during it.",
                tags = { "cd" },
            },
            {
                spellID = 114051,
                name = "Ascendance",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Talent alternative to Doom Winds -- 2 free Windstrikes per cast.",
                talentReq = "Ascendance",
                tags = { "cd" },
            },
            {
                spellID = 51533,
                name = "Feral Spirit",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Wolves -- burst + Maelstrom Weapon generation.",
                tags = { "cd" },
            },
            { spellID = 188389, name = "Flame Shock", priority = 6, why = "Baseline DoT — keep it up for Lava Lash value.", tags = { "core" } },
        },
    },
}
R[264] = { -- Restoration Shaman
    solo = {
        tip = "Resto solo: Flame Shock + Lava Burst for damage, Earth Shock spender, Healing Surge/Riptide to top yourself off.",
        priorities = {
            {
                spellID = 188389,
                name = "Flame Shock",
                priority = 1,
                why = "Maintain DoT for Lava Burst crits.",
                tags = { "core" },
            },
            {
                spellID = 51505,
                name = "Lava Burst",
                priority = 2,
                why = "Guaranteed crit with Flame Shock up.",
                tags = { "core" },
            },
            {
                spellID = 188196,
                name = "Lightning Bolt",
                priority = 3,
                why = "Filler damage.",
                tags = { "active" },
            },
            {
                spellID = 61295,
                name = "Riptide",
                priority = 4,
                why = "HoT + instant heal -- keep on yourself while soloing.",
                tags = { "core" },
            },
            {
                spellID = 8004,
                name = "Healing Surge",
                priority = 5,
                why = "Self-heal when hurt.",
                tags = { "core" },
                when = C.Hurt(),
            },
            {
                spellID = 5394,
                name = "Healing Stream Totem",
                priority = 6,
                why = "Passive heal -- drop on cooldown.",
                tags = { "active" },
            },
            { spellID = 974, name = "Earth Shield", priority = 7, why = "Keep on the tank (or yourself solo) — Icy Veins pre-pull checklist.", tags = { "core" } },
        },
    },
    aoe = {
        tip = "Resto M+ (Totemic default -- Lively Totems auto-casts Chain Heal off your totems): Riptide on CD, Healing Rain/Surging Totem down, Chain Heal for the stacked group, Unleash Life to amplify a big heal.",
        chain = {
            { spellID = 61295, name = "Riptide" },
            { spellID = 73685, name = "Unleash Life" },
            { spellID = 73920, name = "Healing Rain" },
            { spellID = 1064, name = "Chain Heal" },
            { spellID = 455630, name = "Surging Totem" },
        },
        priorities = {
            {
                spellID = 61295,
                name = "Riptide",
                priority = 1,
                why = "On cooldown -- HoT + instant heal, and a chance to drop a free empowered Healing Stream Totem via the Stormstream Totem Apex talent.",
                tags = { "core" },
            },
            {
                spellID = 73920,
                name = "Healing Rain",
                priority = 2,
                why = "Ground AoE HoT -- drop under a stacked group and keep it down. Class-set 2pc also drops one from Healing Wave/Chain Heal casts.",
                tags = { "core" },
                when = C.AoE(3),
            },
            {
                spellID = 1064,
                name = "Chain Heal",
                priority = 3,
                why = "Primary spender for a stacked, injured group. Totemic auto-casts a version of this off Surging Totem via Lively Totems.",
                tags = { "core" },
                when = C.AoE(3),
            },
            {
                spellID = 73685,
                name = "Unleash Life",
                priority = 4,
                why = "Amplify and speed up your next heal -- use right before a big Chain Heal or Healing Wave.",
                tags = { "core" },
            },
            {
                spellID = 8004,
                name = "Healing Surge",
                priority = 5,
                why = "Urgent single-target heal.",
                tags = { "active" },
                when = C.Critical(),
            },
            {
                spellID = 455630,
                name = "Surging Totem",
                priority = nil,
                isCd = true,
                why = "Baseline burst-heal totem, reposition with Totemic Projection -- Totemic further boosts its healing and auto-Chain Heals via Lively Totems.",
                tags = { "cd" },
            },
            {
                spellID = 378081,
                name = "Nature's Swiftness",
                priority = nil,
                isCd = true,
                why = "Free, instant, mana-free next cast -- also a chance to proc Stormstream Totem. Pair with Chain Heal or Healing Wave.",
                tags = { "cd" },
            },
            {
                spellID = 443454,
                name = "Ancestral Swiftness",
                priority = nil,
                isCd = true,
                why = "Farseer version of the above -- also spawns an Ancestor.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            {
                spellID = 192077,
                name = "Wind Rush Totem",
                priority = nil,
                isCd = true,
                why = "Group movement speed -- use to skip mechanics or save a bad pull.",
                tags = { "utility" },
            },
            {
                spellID = 108280,
                name = "Healing Tide Totem",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Group cooldown for heavy AoE damage.",
                tags = { "cd" },
            },
            {
                spellID = 98008,
                name = "Spirit Link Totem",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Redistributes group health and cuts damage taken 15% -- use on a spiky AoE hit or before a mechanic that could one-shot low-health players.",
                tags = { "cd", "defensive" },
            },
            { spellID = 974, name = "Earth Shield", priority = 6, why = "Keep on the tank (or yourself solo) — Icy Veins pre-pull checklist.", tags = { "core" } },
        },
    },
    st = {
        tip = "Resto raid (Totemic default this season -- Farseer has fallen off): Riptide on CD, Healing Rain under melee, Chain Heal for stacked damage, Unleash Life before your biggest heal. Class-set 4pc rewards keeping people stacked in Healing Rain.",
        priorities = {
            {
                spellID = 61295,
                name = "Riptide",
                priority = 1,
                why = "Maintain on tanks and injured raiders. On cooldown -- also a chance to proc a free Stormstream Totem.",
                tags = { "core" },
            },
            {
                spellID = 73920,
                name = "Healing Rain",
                priority = 2,
                why = "Drop under the melee/stacked group and keep it down -- class-set 2pc also seeds one from Healing Wave/Chain Heal, and 4pc shields allies standing in it.",
                tags = { "core" },
            },
            {
                spellID = 73685,
                name = "Unleash Life",
                priority = 3,
                why = "Use right before your next big heal to amplify and speed it up.",
                tags = { "core" },
            },
            {
                spellID = 1064,
                name = "Chain Heal",
                priority = 4,
                why = "Primary spender on stacked raid damage.",
                tags = { "active" },
                when = C.AoE(3),
            },
            {
                spellID = 77472,
                name = "Healing Wave",
                priority = 5,
                why = "Mana-efficient single-target filler on the most injured player.",
                tags = { "core" },
            },
            {
                spellID = 378081,
                name = "Nature's Swiftness",
                priority = nil,
                isCd = true,
                why = "Free instant cast -- pair with Chain Heal or Healing Wave. Chance to proc Stormstream Totem.",
                tags = { "cd" },
            },
            {
                spellID = 443454,
                name = "Ancestral Swiftness",
                priority = nil,
                isCd = true,
                why = "Farseer alternative -- also spawns an Ancestor.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            {
                spellID = 455630,
                name = "Surging Totem",
                priority = nil,
                isCd = true,
                why = "Burst-heal totem, cast roughly every minute -- Totemic amplifies it and auto-Chain Heals off it via Lively Totems.",
                tags = { "cd" },
            },
            {
                spellID = 108280,
                name = "Healing Tide Totem",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major raid cooldown for heavy incoming damage.",
                tags = { "cd" },
            },
            {
                spellID = 98008,
                name = "Spirit Link Totem",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Redistributes raid health and cuts damage taken 15% -- best on a known AoE spike.",
                tags = { "cd", "defensive" },
            },
            {
                spellID = 114052,
                name = "Ascendance",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Farseer -- Healing Wave always crits and heals an extra ally, Chain Heal jumps to 3 more targets.",
                talentReq = "Farseer",
                tags = { "cd" },
            },
            { spellID = 974, name = "Earth Shield", priority = 6, why = "Keep on the tank (or yourself solo) — Icy Veins pre-pull checklist.", tags = { "core" } },
        },
    },
}

-- ── WARLOCK ───────────────────────────────────────────────────────────
-- Rewritten 2026-09-05 for Patch 12.1 "Midnight" Season 2 (raid: Curse of
-- Ula'tek: The Venomous Abyss). Cross-checked against Icy Veins' and
-- Method.gg's current 12.1 guides for all three specs (icy-veins.com/wow/
-- {affliction,demonology,destruction}-warlock-pve-dps-guide and -rotation
-- -cooldowns-abilities, method.gg/guides/{affliction,demonology,
-- destruction}-warlock/{talents,playstyle-and-rotation}), plus Wowhead
-- spell pages for exact IDs (Wither 445465, Dark Harvest 1257052,
-- Malevolence 442726, Dominion of Argus 1276222, Diabolic Oculi 1268709).
--
-- Hero talent trees pair up the same way for all three specs: Hellcaller
-- (Affliction + Destruction), Diabolist (Destruction + Demonology), Soul
-- Harvester (Affliction + Demonology). Every spec below defaults its
-- talentReq/talentAlt pairs to the higher-parsing tree per the sources
-- above, with the other tree's version listed as the talentAlt.
R[265] = { -- Affliction
    -- Hellcaller turns Corruption into Wither (445465, instant-cast Shadowflame
    -- DoT, same shard economy) and adds the Malevolence (442726) 1-min haste
    -- cooldown. Soul Harvester keeps Corruption but adds Dark Harvest (1257052,
    -- 1-min CD) which detonates every DoT'd target for heavy Shadowflame damage
    -- and heals for 50% of it — currently the higher-parsing pick for most
    -- content since its payoff isn't gated on cleave. Apex Talent (4 ranks,
    -- background power) amplifies Haunt: rank 1 adds AoE splash, ranks 2-3 add
    -- +4% Haunt damage/amp per rank, rank 4 makes Haunt's damage call down
    -- meteors for extra AoE — it doesn't change what you press, but it's why
    -- Haunt stays on cooldown outside execute too.
    -- Season 2 tier (Curse of Ula'tek class set): 2pc — Wither/Corruption damage
    -- +25%, Agony damage +15%; 4pc — each active Unstable Affliction gives +2%
    -- damage dealt (max 3 stacks, so +6%) and Seed of Corruption applies UA to
    -- its target at 20% effectiveness. The 4pc is why AoE now wants 2-3 Unstable
    -- Afflictions rolling instead of just Agony + Seed.
    solo = {
        tip = "Leveling/world content: Agony + Corruption + UA, Malefic Grasp/Drain Life filler. Hero trees and the tier set below assume max level with your Season 2 build; this loop still works before you have either.",
        priorities = {
            { spellID = 980, name = "Agony", priority = 1, why = "Maintain — damage ramps the longer it's up, so don't clip it early.", tags = { "core" }, when = C.DebuffRefresh(980, 4) },
            { spellID = 172, name = "Corruption", priority = 2, why = "Maintain DoT. Becomes Wither once you have the Hellcaller hero talent.", tags = { "core" }, when = C.DebuffRefresh(146739, 4) },
            {
                spellID = 30108,
                name = "Unstable Affliction",
                priority = 3,
                why = "Maintain — your main Soul Shard spender and the source of Malefic Rapture's damage.",
                tags = { "core" },
                when = C.DebuffRefresh(30108, 4),
            },
            {
                spellID = 324536,
                name = "Malefic Rapture",
                priority = 4,
                why = "Spend shards here — bursts all active DoTs at once.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 234153,
                name = "Drain Life",
                priority = 5,
                why = "Filler + self-heal — better than Malefic Grasp while leveling or soloing content.",
                tags = { "active" },
            },
            {
                spellID = 205180,
                name = "Summon Darkglare",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Extends all active DoTs by 8s and hastes their ticks — refresh DoTs just before pressing this.",
                tags = { "cd" },
            },
            { spellID = 686, name = "Shadow Bolt", priority = 6, why = "Filler (Icy Veins 12.1) when nothing above is ready.", tags = { "active" } },
            { spellID = 198590, name = "Drain Soul", priority = 7, why = "Talented filler that replaces Shadow Bolt.", tags = { "active" } },
        },
    },
    aoe = {
        tip = "M+/cleave: spread Agony, Sow the Seeds triples Seed of Corruption for the AoE DoT, keep 2-3 Unstable Afflictions up for the 4pc, Dark Harvest hits everything that's DoT'd.",
        chain = {
            { spellID = 980, name = "Agony" },
            { spellID = 27243, name = "Seed of Corruption" },
            { spellID = 30108, name = "Unstable Affliction" },
            { spellID = 1257052, name = "Dark Harvest" },
            { spellID = 324536, name = "Malefic Rapture" },
        },
        priorities = {
            { spellID = 980, name = "Agony", priority = 1, why = "On every target — ramps, so get it up early on adds that will live.", tags = { "core" }, when = C.DebuffRefresh(980, 4) },
            {
                spellID = 27243,
                name = "Seed of Corruption",
                priority = 2,
                why = "Sow the Seeds makes this hit 3 targets — main AoE DoT spread, and applies partial Unstable Affliction with the Season 2 4pc.",
                tags = { "core", "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 30108,
                name = "Unstable Affliction",
                priority = 3,
                why = "Keep 2-3 up on top targets for the 4pc's stacking damage buff, not just one.",
                tags = { "core" },
                when = C.DebuffRefresh(30108, 4),
            },
            {
                spellID = 445465,
                name = "Wither",
                priority = 4,
                why = "Hellcaller only — replaces Corruption. Maintain on cleave targets same as Corruption.",
                talentReq = "Hellcaller",
                talentAlt = "Corruption",
                tags = { "core" },
                when = C.DebuffRefresh(445474, 4),
            },
            {
                spellID = 172,
                name = "Corruption",
                priority = 4,
                why = "Soul Harvester baseline — maintain on cleave targets.",
                talentAlt = "Wither",
                tags = { "core" },
                when = C.DebuffRefresh(146739, 4),
            },
            {
                spellID = 324536,
                name = "Malefic Rapture",
                priority = 5,
                why = "Shard dump — hits all targets with active DoTs.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 1257052,
                name = "Dark Harvest",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Soul Harvester",
                talentAlt = "Malevolence",
                why = "Soul Harvester capstone CD — hits every DoT'd target and heals you for half the damage. Best AoE burst window in the kit; use once DoTs are spread.",
                tags = { "cd", "aoe" },
            },
            {
                spellID = 442726,
                name = "Malevolence",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Hellcaller",
                talentAlt = "Dark Harvest",
                why = "Hellcaller CD — haste burst window. Save shards to dump into Malefic Rapture/UA during it.",
                tags = { "cd" },
            },
            {
                spellID = 205180,
                name = "Summon Darkglare",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Extends and hastes every active DoT across all targets — line up with your Dark Harvest/Malevolence window.",
                tags = { "cd" },
            },
            { spellID = 686, name = "Shadow Bolt", priority = 6, why = "Filler (Icy Veins 12.1) when nothing above is ready.", tags = { "active" } },
            { spellID = 198590, name = "Drain Soul", priority = 7, why = "Talented filler that replaces Shadow Bolt.", tags = { "active" } },
        },
    },
    st = {
        tip = "Raid ST: Agony/Wither(or Corruption)/UA all up, Malefic Grasp filler between shard dumps, Malefic Rapture on 2+ shards. Save shards for Dark Harvest/Malevolence and pop Darkglare with DoTs freshly refreshed.",
        priorities = {
            { spellID = 980, name = "Agony", priority = 1, why = "Maintain — never let it fall off, it ramps.", tags = { "core" }, when = C.DebuffRefresh(980, 4) },
            {
                spellID = 445465,
                name = "Wither",
                priority = 2,
                why = "Hellcaller only — replaces Corruption, refresh in the pandemic window (last ~20% duration).",
                talentReq = "Hellcaller",
                talentAlt = "Corruption",
                tags = { "core" },
                when = C.DebuffRefresh(445474, 4),
            },
            {
                spellID = 172,
                name = "Corruption",
                priority = 2,
                why = "Soul Harvester baseline — maintain.",
                talentAlt = "Wither",
                tags = { "core" },
                when = C.DebuffRefresh(146739, 4),
            },
            {
                spellID = 30108,
                name = "Unstable Affliction",
                priority = 3,
                why = "Maintain — enables Malefic Rapture and, with the 4pc, is a personal damage buff while active.",
                tags = { "core" },
                when = C.DebuffRefresh(30108, 4),
            },
            {
                spellID = 48181,
                name = "Haunt",
                priority = 4,
                why = "On cooldown — damage amp on the target, and the Apex Talent turns its damage into extra AoE/meteors passively.",
                tags = { "core" },
            },
            {
                spellID = 324536,
                name = "Malefic Rapture",
                priority = 5,
                why = "Primary spender at 2+ shards — bursts all active DoTs.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 235155,
                name = "Malefic Grasp",
                priority = 6,
                why = "Channel filler when you have no shards to spend and nothing to refresh.",
                tags = { "active" },
                when = C.PowerBelow(2),
            },
            {
                spellID = 1257052,
                name = "Dark Harvest",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Soul Harvester",
                talentAlt = "Malevolence",
                why = "Use with DoTs freshly applied — hits the target and heals you for half the damage.",
                tags = { "cd" },
            },
            {
                spellID = 442726,
                name = "Malevolence",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Hellcaller",
                talentAlt = "Dark Harvest",
                why = "Save shards beforehand and dump into Malefic Rapture/UA during the haste window.",
                tags = { "cd" },
            },
            {
                spellID = 205180,
                name = "Summon Darkglare",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Refresh all 3 DoTs right before this — extends and hastes them for the full burst window.",
                tags = { "cd" },
            },
            { spellID = 686, name = "Shadow Bolt", priority = 7, why = "Filler (Icy Veins 12.1) when nothing above is ready.", tags = { "active" } },
            { spellID = 198590, name = "Drain Soul", priority = 8, why = "Talented filler that replaces Shadow Bolt.", tags = { "active" } },
        },
    },
}
R[266] = { -- Demonology
    -- Hero trees: Diabolist tracks a Diabolic Ritual meter toward Abyssal
    -- Dominion (boosted Tyrant damage) and adds Diabolic Oculi (1268709,
    -- shard-spend procs that explode for AoE) plus a choice node, Grimoire:
    -- Imp Lord (1276452, buffs Wild Imps) vs Grimoire: Fel Ravager (1276467,
    -- summons an interrupting demon) — take Imp Lord for pure damage, Fel
    -- Ravager when you need the extra interrupt. Soul Harvester instead
    -- procs Demonic Soul/Succulent Soul off shard spenders for sustained,
    -- less-bursty damage. Apex Talent Dominion of Argus (1276222) is the
    -- defining cooldown: Summon Demonic Tyrant opens a 25s portal where
    -- every 2nd Hand of Gul'dan refunds a shard and summons an extra demon
    -- for 14s — 35-40s of very high output, then a lower-output stretch
    -- until it's back up, so pool Wild Imps and Dreadstalkers into that
    -- window rather than spending them evenly.
    -- Season 2 tier (Curse of Ula'tek class set): 2pc — Wild Imp damage +10%,
    -- Implosion damage +20%; 4pc — when a Wild Imp's energy depletes it has a
    -- 20% chance to fling itself at its target and Implode for 250%/225%
    -- effectiveness (main/other targets) on its own. That passive-implosion
    -- chance means holding imps a little longer before a manual Implosion is
    -- now slightly better than dumping the instant it's up.
    solo = {
        tip = "Leveling/world content: Call Dreadstalkers on CD, Hand of Gul'dan at 3+ shards, Demonbolt on Demonic Core procs, Shadow Bolt filler.",
        priorities = {
            {
                spellID = 104316,
                name = "Call Dreadstalkers",
                priority = 1,
                why = "On cooldown — strong shard-spending summon.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 105174,
                name = "Hand of Gul'dan",
                priority = 2,
                why = "At 3+ Soul Shards — summons Wild Imps.",
                tags = { "core" },
                when = C.PowerAtLeast(3),
            },
            {
                spellID = 264178,
                name = "Demonbolt",
                priority = 3,
                why = "Instant cast on a Demonic Core proc — free damage, don't let procs go to waste.",
                tags = { "core" },
                when = C.HasBuff(264173),
            },
            { spellID = 686, name = "Shadow Bolt", priority = 4, why = "Filler — generates Soul Shards.", tags = { "active" } },
            {
                spellID = 265187,
                name = "Summon Demonic Tyrant",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Extends every active demon's duration and buffs their damage — use with as many demons out as possible.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "M+: Hand of Gul'dan for Wild Imps, hold 6+ imps then Implosion, spread Doom with instant Demonbolts, Dreadstalkers on CD.",
        chain = {
            { spellID = 104316, name = "Call Dreadstalkers" },
            { spellID = 105174, name = "Hand of Gul'dan" },
            { spellID = 105174, name = "Hand of Gul'dan" },
            { spellID = 196277, name = "Implosion" },
        },
        priorities = {
            {
                spellID = 105174,
                name = "Hand of Gul'dan",
                priority = 1,
                why = "At 3+ shards — summon Wild Imps to bank for Implosion.",
                tags = { "core", "aoe" },
                when = C.PowerAtLeast(3),
            },
            {
                spellID = 196277,
                name = "Implosion",
                priority = 2,
                why = "Detonate Wild Imps once you're holding 6+ — earlier than that is a DPS loss. Season 2 4pc also auto-detonates some imps on their own when their energy runs out.",
                tags = { "core", "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 104316,
                name = "Call Dreadstalkers",
                priority = 3,
                why = "On cooldown regardless of target count.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 264178,
                name = "Demonbolt",
                priority = 4,
                why = "Instant cast on targets without Doom to spread it, or on a Demonic Core proc.",
                tags = { "core", "aoe" },
                when = C.HasBuff(264173),
            },
            { spellID = 686, name = "Shadow Bolt", priority = 5, why = "Filler / shard generation between summons.", tags = { "active" } },
            {
                spellID = 1268709,
                name = "Diabolic Oculi",
                priority = nil,
                isCd = true,
                talentReq = "Diabolist",
                why = "Diabolist only — procs off shard spenders and explodes for AoE. Passive proc, just spend shards on cooldown to trigger it.",
                tags = { "cd", "aoe" },
            },
            {
                spellID = 265187,
                name = "Summon Demonic Tyrant",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Dominion of Argus opens a 25s window where every 2nd Hand of Gul'dan refunds a shard and summons a bonus demon — pool Imps/Dreadstalkers into this.",
                tags = { "cd" },
            },
        },
    },
    st = {
        tip = "Raid ST: don't overcap shards or Demonic Core, Dreadstalkers on CD, Hand of Gul'dan at 3+, Demonbolt on procs, Shadow Bolt filler. Bank summons for the Dominion of Argus window.",
        priorities = {
            {
                spellID = 104316,
                name = "Call Dreadstalkers",
                priority = 1,
                why = "On cooldown — don't let it sit banked.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 105174,
                name = "Hand of Gul'dan",
                priority = 2,
                why = "At 3+ shards — never overcap Soul Shards.",
                tags = { "core" },
                when = C.PowerAtLeast(3),
            },
            {
                spellID = 264178,
                name = "Demonbolt",
                priority = 3,
                why = "Instant on a Demonic Core proc — never let a stack expire unused.",
                tags = { "core" },
                when = C.HasBuff(264173),
            },
            {
                spellID = 264130,
                name = "Power Siphon",
                priority = 4,
                why = "If talented — consumes 2 Wild Imps for 2 Demonic Core stacks. Use before Implosion/Tyrant, not right after summoning imps.",
                tags = { "core" },
            },
            { spellID = 686, name = "Shadow Bolt", priority = 5, why = "Filler — generates shards.", tags = { "active" } },
            {
                spellID = 18540,
                name = "Summon Doomguard",
                priority = nil,
                isCd = true,
                why = "Cooldown reduced by spending Demonic Cores — weave in as it comes up.",
                tags = { "cd" },
            },
            {
                spellID = 1276452,
                name = "Grimoire: Imp Lord",
                priority = nil,
                isCd = true,
                talentReq = "Diabolist",
                talentAlt = "Grimoire: Fel Ravager",
                why = "Diabolist choice node — buffs Wild Imp damage. Use on cooldown, ideally lined up with a Tyrant window.",
                tags = { "cd" },
            },
            {
                spellID = 1276467,
                name = "Grimoire: Fel Ravager",
                priority = nil,
                isCd = true,
                talentReq = "Diabolist",
                talentAlt = "Grimoire: Imp Lord",
                why = "Diabolist choice node — take instead of Imp Lord when the fight needs another interrupt.",
                tags = { "cd" },
            },
            {
                spellID = 265187,
                name = "Summon Demonic Tyrant",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Dominion of Argus: opens a 25s portal where every 2nd Hand of Gul'dan during it refunds a shard and summons a bonus demon for 14s. Have every demon out and shards banked before pressing this.",
                tags = { "cd" },
            },
        },
    },
}
R[267] = { -- Destruction
    -- Hellcaller replaces Immolate with Wither (445465, instant-cast, same
    -- shard economy) and adds Malevolence (442726, 1-min CD, +8% haste) plus
    -- Blackened Soul (shard spenders stack Wither on your primary target).
    -- Diabolist instead builds toward Diabolic Ritual: casting Chaos Bolt,
    -- Rain of Fire or Shadowburn advances it, and completing it grants
    -- Demonic Art, which empowers your next cast via a rotating demon
    -- (Overlord: 5% damage-taken debuff; Mother of Chaos: 2 free shards;
    -- Pit Lord: a free Ruination for AoE). Apex Talent Embers of Nihilam
    -- (4 ranks, background power) makes Incinerate proc Echo of Sargeras;
    -- rank 4 extends that proc to Chaos Bolt/Shadowburn/Rain of Fire at
    -- 50/50/60% effectiveness — more shard spenders means more Echo procs,
    -- which is also what the tier set is built around.
    -- Season 2 tier (Curse of Ula'tek class set): 2pc — Incinerate damage
    -- +25% and +10% chance to evoke an Echo of Sargeras; 4pc — targets hit by
    -- Echo of Sargeras take +6% damage from you for 6s. Weave an extra
    -- Incinerate cast before a big shard dump when you can afford the GCD, to
    -- land the dump inside that 6% window.
    solo = {
        tip = "Leveling/world content: Immolate DoT up, Chaos Bolt at 2+ shards, Conflagrate for shards, Incinerate filler.",
        priorities = {
            {
                spellID = 348,
                name = "Immolate",
                priority = 1,
                why = "Maintain — passive shard generation while it ticks.",
                tags = { "core" },
                when = C.DebuffRefresh(157736, 4),
            },
            {
                spellID = 116858,
                name = "Chaos Bolt",
                priority = 2,
                why = "At 2+ shards — biggest single hit in the kit.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 17962,
                name = "Conflagrate",
                priority = 3,
                why = "Instant shard generator, 2 charges — don't let them cap.",
                tags = { "core" },
            },
            { spellID = 29722, name = "Incinerate", priority = 4, why = "Filler — generates shards.", tags = { "active" } },
            {
                spellID = 1122,
                name = "Summon Infernal",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "AoE burst + haste buff.",
                tags = { "cd" },
            },
        },
    },
    aoe = {
        tip = "M+: Cataclysm/Channel Demonfire to spread Immolate (or Wither), Rain of Fire to dump shards past 8 targets or when you'd otherwise overcap, Havoc to duplicate Chaos Bolt/Shadowburn onto a 2nd target below that.",
        chain = {
            { spellID = 152108, name = "Cataclysm" },
            { spellID = 348, name = "Immolate" },
            { spellID = 80240, name = "Havoc" },
            { spellID = 116858, name = "Chaos Bolt" },
            { spellID = 5740, name = "Rain of Fire" },
        },
        priorities = {
            {
                spellID = 152108,
                name = "Cataclysm",
                priority = 1,
                why = "On cooldown — applies Immolate/Wither to every target it hits.",
                tags = { "core", "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 348,
                name = "Immolate",
                priority = 2,
                why = "Maintain on 3-4 targets Cataclysm didn't reach. Becomes Wither with Hellcaller.",
                talentAlt = "Wither",
                tags = { "core" },
                when = C.DebuffRefresh(157736, 4),
            },
            {
                spellID = 445465,
                name = "Wither",
                priority = 2,
                why = "Hellcaller only — replaces Immolate, spread the same way.",
                talentReq = "Hellcaller",
                talentAlt = "Immolate",
                tags = { "core" },
                when = C.DebuffRefresh(445474, 4),
            },
            {
                spellID = 80240,
                name = "Havoc",
                priority = 3,
                why = "Below 8 targets — duplicates your next Chaos Bolt/Shadowburn onto the marked target instead of pure Rain of Fire.",
                tags = { "core" },
                when = C.AoE(2),
            },
            {
                spellID = 5740,
                name = "Rain of Fire",
                priority = 4,
                why = "Main AoE spender once you're at 8+ targets, or any time you'd otherwise overcap Soul Shards.",
                tags = { "core", "aoe" },
                when = C.AoE(3),
            },
            {
                spellID = 17962,
                name = "Conflagrate",
                priority = 5,
                why = "Shard generator, 2 charges — keep using it, also procs Embers of Nihilam.",
                tags = { "core" },
            },
            { spellID = 29722, name = "Incinerate", priority = 6, why = "Filler — also triggers Echo of Sargeras via Embers of Nihilam.", tags = { "active" } },
            {
                spellID = 1122,
                name = "Summon Infernal",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Massive AoE burst — use on the biggest pack of the pull.",
                tags = { "cd" },
            },
            {
                spellID = 442726,
                name = "Malevolence",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Hellcaller",
                why = "Hellcaller CD — line up with Infernal and dump every available shard spender during the haste window.",
                tags = { "cd" },
            },
            { spellID = 196447, name = "Channel Demonfire", priority = 7, why = "Icy Veins 12.1 priority filler/generator when talented.", tags = { "active" } },
            { spellID = 387976, name = "Dimensional Rift", priority = 8, why = "Charge-based shard generator — don't sit at max charges.", tags = { "active" } },
        },
    },
    st = {
        tip = "Raid ST: Wither/Immolate up in the pandemic window, Shadowburn on execute or Fiendish Cruelty procs, Chaos Bolt to avoid overcapping shards, Soulfire on Backdraft, Conflagrate charges, Incinerate filler.",
        priorities = {
            {
                spellID = 445465,
                name = "Wither",
                priority = 1,
                why = "Hellcaller only — replaces Immolate, refresh in the pandemic window.",
                talentReq = "Hellcaller",
                talentAlt = "Immolate",
                tags = { "core" },
                when = C.DebuffRefresh(445474, 4),
            },
            {
                spellID = 348,
                name = "Immolate",
                priority = 1,
                why = "Diabolist baseline — maintain in the pandemic window.",
                talentAlt = "Wither",
                tags = { "core" },
                when = C.DebuffRefresh(157736, 4),
            },
            {
                spellID = 17877,
                name = "Shadowburn",
                priority = 2,
                why = "Execute range, or on a Fiendish Cruelty proc, or to avoid overcapping shards — it's a free reset on kill.",
                tags = { "core" },
                when = C.ExecuteOrProc(20),
            },
            {
                spellID = 116858,
                name = "Chaos Bolt",
                priority = 3,
                why = "Primary shard spender — cast before you'd overcap Soul Shards.",
                tags = { "core" },
                when = C.PowerAtLeast(2),
            },
            {
                spellID = 6353,
                name = "Soulfire",
                priority = 4,
                why = "Best with a Backdraft proc for the reduced cast time — also applies/refreshes Immolate.",
                tags = { "core" },
            },
            {
                spellID = 17962,
                name = "Conflagrate",
                priority = 5,
                why = "2 charges — don't sit at cap, it's pure shard generation.",
                tags = { "core" },
            },
            { spellID = 29722, name = "Incinerate", priority = 6, why = "Filler — also your main Echo of Sargeras proc source via Embers of Nihilam.", tags = { "active" } },
            {
                spellID = 1122,
                name = "Summon Infernal",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                why = "Major burst — line up with Malevolence/Diabolic Ritual completion when possible.",
                tags = { "cd" },
            },
            {
                spellID = 442726,
                name = "Malevolence",
                priority = nil,
                isCd = true,
                isMajorCd = true,
                talentReq = "Hellcaller",
                why = "Save shards beforehand and dump into Chaos Bolt/Shadowburn during the haste window.",
                tags = { "cd" },
            },
            { spellID = 196447, name = "Channel Demonfire", priority = 7, why = "Icy Veins 12.1 priority filler/generator when talented.", tags = { "active" } },
            { spellID = 387976, name = "Dimensional Rift", priority = 8, why = "Charge-based shard generator — don't sit at max charges.", tags = { "active" } },
        },
    },
}

-- ── Healer gates ────────────────────────────────────────────────────────
-- The next-3 bar used to rank heals by fixed priority with no idea whether
-- anyone was hurt: Flash of Light and Vivify were suggested at full health.
-- Reactive heals get a group-health condition here, by name, in one place,
-- combined with any condition the entry already has. Maintenance HoTs
-- (Riptide, Rejuvenation, Renewing Mist, Lifebloom...) and damage abilities are
-- deliberately left alone -- they are correct to keep up at full health.
-- Thresholds: single-target heals when anyone is below 85% (big heals 75%);
-- group heals when 3 people (capped at group size) are below 90%.
local HEAL_GATES = {
    [65]   = { -- Holy Paladin
        ["Flash of Light"] = C.AllyBelow(85), ["Holy Light"] = C.AllyBelow(75),
        ["Word of Glory"] = C.AllyBelow(85), ["Eternal Flame"] = C.AllyBelow(90),
        ["Holy Prism"] = C.GroupHurt(3, 90),
    },
    [105]  = { -- Restoration Druid
        ["Regrowth"] = C.AllyBelow(80), ["Swiftmend"] = C.AllyBelow(80),
        ["Wild Growth"] = C.GroupHurt(3, 90),
    },
    [257]  = { -- Holy Priest
        ["Flash Heal"] = C.AllyBelow(85), ["Heal"] = C.AllyBelow(80),
        ["Holy Word: Serenity"] = C.AllyBelow(70),
        ["Holy Word: Sanctify"] = C.GroupHurt(3, 90), ["Prayer of Healing"] = C.GroupHurt(3, 90),
        ["Halo"] = C.GroupHurt(3, 90),
    },
    [264]  = { -- Restoration Shaman
        ["Healing Surge"] = C.AllyBelow(85), ["Healing Wave"] = C.AllyBelow(80),
        ["Chain Heal"] = C.GroupHurt(3, 90), ["Healing Rain"] = C.GroupHurt(3, 90),
        ["Unleash Life"] = C.AllyBelow(90),
    },
    [270]  = { -- Mistweaver
        ["Vivify"] = C.AllyBelow(85), ["Enveloping Mist"] = C.AllyBelow(80),
        ["Sheilun's Gift"] = C.AllyBelow(80),
    },
    [1468] = { -- Preservation
        ["Verdant Embrace"] = C.AllyBelow(85), ["Emerald Blossom"] = C.GroupHurt(3, 90),
        ["Temporal Anomaly"] = C.GroupHurt(2, 90),
    },
}

do
    for specID, gates in pairs(HEAL_GATES) do
        local spec = R[specID]
        if type(spec) == "table" then
            for _, view in pairs(spec) do
                if type(view) == "table" and type(view.priorities) == "table" then
                    for _, e in ipairs(view.priorities) do
                        local base = e.name and e.name:gsub("%s*%b()", "")
                        local gate = base and gates[base]
                        if gate and not e._healGated then
                            e.when = e.when and C.And(e.when, gate) or gate
                            e._healGated = true
                        end
                    end
                end
            end
        end
    end
end
R._HEAL_GATES = HEAL_GATES

-- ── Generic fallback for unimplemented specs ───────────────────────────
R.fallback = {
    solo = {
        tip = "Rotation data for this spec coming soon. Use Icy Veins or Method for current guidance.",
        priorities = {},
    },
    aoe = { tip = "Rotation data for this spec coming soon.", priorities = {} },
    st = { tip = "Rotation data for this spec coming soon.", priorities = {} },
}

-- ── Lookup helper ──────────────────────────────────────────────────────
function R:Get(specID, view)
    local spec = self[specID] or self.fallback
    return spec[view] or spec.solo or {}
end
