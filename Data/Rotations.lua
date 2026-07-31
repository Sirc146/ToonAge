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
R[1468] = {
    solo = {
        tip = "Solo at level 82: simpler loop — Living Flame for damage and self-healing. Dream Breath and Stasis unlock at higher levels.",
        priorities = {
            { spellID=361469, name="Living Flame",      priority=1, why="Damage on enemies, self-heal when below 60%. Your primary filler.", tags={"core"} },
            { spellID=364343, name="Echo",              priority=2, why="Use before every Reversion — doubles the HoT via echo.", tags={"core"} },
            { spellID=366155, name="Reversion",         priority=3, why="Primary HoT. Always pair with Echo. Keep rolling on yourself.", tags={"core"} },
            { spellID=355913, name="Emerald Blossom",   priority=4, why="On cooldown. Instant AoE heal — use below 70% health.", condition="On cooldown", tags={"core"}, when=C.HealthBelow(70) },
            { spellID=360995, name="Verdant Embrace",   priority=5, why="Strong burst heal, 2 charges (Wings of Liberty).", condition="On cooldown, burst heal", tags={} },
            { spellID=363916, name="Obsidian Scales",   priority=6, why="Personal defensive — use before difficult pulls.", isCd=true, tags={"defensive"} },
            { spellID=374251, name="Temporal Anomaly",  priority=7, why="On cooldown — applies Echo to nearby targets even solo.", condition="On cooldown", tags={} },
            { spellID=382614, name="Dream Breath",      priority=nil, why="Not yet unlocked.", unlockLv=85, tags={} },
            { spellID=370537, name="Stasis",            priority=nil, why="Not yet unlocked.", unlockLv=90, tags={} },
        },
    },
    aoe = {
        tip = "M+ (Chronowarden): Echo-centric rotation. Everything revolves around Temporal Anomaly spreading Echo then healing into it.",
        chain = {
            { spellID=364343, name="Echo" },
            { spellID=366155, name="Reversion" },
            { spellID=374251, name="Temporal Anomaly" },
            { spellID=355913, name="Em. Blossom" },
            { spellID=364343, name="Echo" },
            { spellID=366155, name="Reversion" },
        },
        priorities = {
            { spellID=364343, name="Echo → Reversion",      priority=1, why="Core combo — Echo a player, immediately Reversion them for doubled HoT.", tags={"core"} },
            { spellID=374251, name="Temporal Anomaly",       priority=2, why="On cooldown — applies Echo to 4 players. Supercharged by Nozdormu Adept.", condition="On cooldown", tags={"core","cd"} },
            { spellID=355913, name="Emerald Blossom",        priority=3, why="On cooldown when 2+ players injured. Does not break casting.", condition="2+ injured allies", tags={"core"} },
            { spellID=360995, name="Verdant Embrace",        priority=4, why="Strong targeted heal with 2 charges. Do not cap charges.", condition="On cooldown", tags={} },
            { spellID=361469, name="Living Flame",           priority=5, why="Filler — generates Essence Burst via Spark of Insight.", tags={} },
            { spellID=382614, name="Dream Breath (Empower 3)", priority=nil, isCd=true, why="PRIMARY AoE heal — unlocks at level 85. Empower to rank 3.", unlockLv=85, tags={"core","cd"} },
            { spellID=370452, name="Tip the Scales → Dream Breath", priority=nil, isCd=true, why="Instant full empower — use on burst damage. Unlocks at 85.", unlockLv=85, tags={"cd"} },
            { spellID=370960, name="Emerald Communion",      priority=nil, isCd=true, isMajorCd=true, why="Channel 5 sec — heals all nearby allies. Use on sustained group damage.", tags={"major-cd"} },
            { spellID=370537, name="Stasis",                 priority=nil, isCd=true, why="Store Echo+Reversion+Dream Breath, release at pull start. Unlocks at 90.", unlockLv=90, tags={"cd"} },
        },
    },
    st = {
        tip = "Raid (Chronowarden): deliberate rotation focused on Reversion uptime on tanks. Temporal Anomaly less powerful in spread raid but still core.",
        priorities = {
            { spellID=366155, name="Reversion — maintain on tank", priority=1, why="Keep rolling on main tank always. Apply to off-tank on cooldown.", tags={"core"} },
            { spellID=364343, name="Echo → Reversion (injured DPS)", priority=2, why="Echo then Reversion on injured DPS — doubles HoT for free.", tags={"core"} },
            { spellID=374251, name="Temporal Anomaly",       priority=3, why="On cooldown — position centrally for best reach.", condition="On cooldown", tags={"core","cd"} },
            { spellID=360995, name="Verdant Embrace + Lifebind", priority=4, why="Cast on tank — Lifebind shares heals between you and the tank.", tags={} },
            { spellID=355913, name="Emerald Blossom",        priority=5, why="On cooldown targeting most clustered injured players.", condition="Clustered injured players", tags={} },
            { spellID=361469, name="Living Flame",           priority=6, why="Filler targeting most injured player.", tags={} },
            { spellID=382614, name="Dream Breath (Empower 3)", priority=nil, isCd=true, why="Primary raid CD — unlocks at 85. Empower rank 3 on stacked players.", unlockLv=85, tags={"core","cd"} },
            { spellID=370960, name="Emerald Communion",      priority=nil, isCd=true, isMajorCd=true, why="Coordinate with healers — use during predictable raid damage phases.", tags={"major-cd"} },
            { spellID=370537, name="Stasis",                 priority=nil, isCd=true, why="Store Reversion+Dream Breath+EC, release at burst phase. Unlocks at 90.", unlockLv=90, tags={"cd"} },
        },
    },
}

-- ── Devastation Evoker (specID 1467) ──────────────────────────────────
R[1467] = {
    solo = {
        tip = "Devastation solo: maintain Disintegrate on high-value targets. Use Fire Breath Empower 3 on packs.",
        priorities = {
            { spellID=357208, name="Fire Breath (Empower 2-3)", priority=1, why="Strongest DPS cooldown — empower to rank 2+ for DoT spread.", tags={"core"} },
            { spellID=356995, name="Disintegrate",       priority=2, why="Main DPS channel — high damage if fully channeled. Don't clip.", tags={"core"} },
            { spellID=361469, name="Living Flame",       priority=3, why="Filler and proc generator. Cast during Dragonrage.", tags={} },
            { spellID=355939, name="Azure Strike",       priority=4, why="2-target cleave filler. Hits 2 enemies baseline.", tags={} },
            { spellID=368847, name="Eternity Surge",     priority=5, why="On cooldown during Dragonrage — high burst window.", isCd=true, tags={"cd"} },
            { spellID=375087, name="Dragonrage",         priority=nil, isCd=true, isMajorCd=true, why="Major DPS cooldown — all spells become instant during duration.", tags={"major-cd"} },
        },
    },
    aoe = {
        tip = "Devastation AoE: Fire Breath Empower 3 for DoT spread, Shattering Star to debuff, Eternity Surge during Dragonrage.",
        priorities = {
            { spellID=357208, name="Fire Breath (Empower 3)", priority=1, why="Maximum AoE — Empower 3 spreads DoT to all targets in cone.", tags={"core"} },
            { spellID=370462, name="Shattering Star",    priority=2, why="On cooldown — debuffs target, your spells deal 20% more for 4 sec.", condition="On cooldown", tags={"core"} },
            { spellID=368847, name="Eternity Surge",     priority=3, why="On cooldown or during Dragonrage — high burst.", isCd=true, tags={"core","cd"} },
            { spellID=356995, name="Disintegrate",       priority=4, why="Channel on priority target — DoTs spread damage.", tags={} },
            { spellID=361469, name="Living Flame",       priority=5, why="Filler between cooldowns.", tags={} },
            { spellID=375087, name="Dragonrage",         priority=nil, isCd=true, isMajorCd=true, why="Use during highest enemy count — spam Eternity Surge inside.", tags={"major-cd"} },
        },
    },
    st = {
        tip = "Devastation single target: maintain Disintegrate, weave Eternity Surge on cooldown, Dragonrage on cooldown.",
        priorities = {
            { spellID=357208, name="Fire Breath (Empower 2)", priority=1, why="Applies DoT — Empower 2 is more efficient than 3 for single target.", tags={"core"} },
            { spellID=370462, name="Shattering Star",    priority=2, why="On cooldown — 20% damage amp window. Cast strongest spells inside.", condition="On cooldown", tags={"core"} },
            { spellID=368847, name="Eternity Surge",     priority=3, why="High damage on cooldown. Priority during Dragonrage.", isCd=true, tags={"core"} },
            { spellID=356995, name="Disintegrate",       priority=4, why="Main DPS channel — do not clip early.", tags={"core"} },
            { spellID=361469, name="Living Flame",       priority=5, why="Filler and proc spender.", tags={} },
            { spellID=375087, name="Dragonrage",         priority=nil, isCd=true, isMajorCd=true, why="Major DPS CD — on cooldown. Stack with Bloodlust when available.", tags={"major-cd"} },
        },
    },
}

-- ── Augmentation Evoker (specID 1473) ─────────────────────────────────
-- SpellIDs marked nil are unverified for Midnight 12.0.5 — verify in-game
R[1473] = {
    solo = {
        tip = "Augmentation solo: keep Ebon Might active at all times — it is your most important button. Prescience yourself between casts. Fill with Upheaval and Eruption.",
        priorities = {
            { spellID=nil, name="Ebon Might",      priority=1, why="Core buff — empowers your allies (and yourself solo). Never let it drop.", tags={"core"} },
            { spellID=nil, name="Prescience",      priority=2, why="Apply to yourself for the Fate Mirror proc chance. 2 charges.", tags={"core"} },
            { spellID=nil, name="Upheaval",        priority=3, why="On cooldown — strong personal damage and empowers nearby targets.", isCd=true, tags={"core","cd"} },
            { spellID=nil, name="Eruption",        priority=4, why="Primary filler — deals damage scaled by your active empowerment stacks.", tags={"core"} },
            { spellID=361469, name="Living Flame",  priority=5, why="Filler between Eruption casts. Generates Essence Burst.", tags={"active"} },
            { spellID=nil, name="Breath of Eons",  priority=nil, isCd=true, isMajorCd=true, why="Major cooldown — align with ally burst windows. Coordinate pull timing.", tags={"major-cd"} },
        },
    },
    aoe = {
        tip = "Augmentation M+: your job is buff uptime, not personal damage. Ebon Might on all 4 allies. Prescience the two highest DPS. Eruption for Essence Burst windows. Position centrally.",
        chain = {
            { spellID=nil,    name="Ebon Might" },
            { spellID=nil,    name="Prescience" },
            { spellID=nil,    name="Prescience" },
            { spellID=nil,    name="Upheaval" },
            { spellID=nil,    name="Eruption" },
            { spellID=361469, name="Living Flame" },
        },
        priorities = {
            { spellID=nil, name="Ebon Might",      priority=1, why="Must be 100% uptime on all 4 allies. Refresh 1-2s before expiry — never let it drop in combat.", tags={"core"} },
            { spellID=nil, name="Prescience",      priority=2, why="Cast on the two highest DPS before every major pull. 2 charges — always have one ready.", tags={"core"} },
            { spellID=nil, name="Eruption",        priority=3, why="Your primary damage contribution — empowers allies via Fate Mirror. Use Essence Burst procs immediately.", tags={"core"} },
            { spellID=nil, name="Upheaval",        priority=4, why="On cooldown — strong group empowerment. Cast during Ebon Might window.", isCd=true, tags={"core","cd"} },
            { spellID=361469, name="Living Flame", priority=5, why="Filler. Generates Essence Burst for Eruption.", tags={"active"} },
            { spellID=nil, name="Breath of Eons",  priority=nil, isCd=true, isMajorCd=true, why="Use on large pack pulls or boss burn phase. Coordinate with tank to ensure enemies are grouped.", tags={"major-cd"} },
        },
    },
    st = {
        tip = "Augmentation raid: pure support role. Your personal DPS is low — your value is in how much damage you add to your buffed allies. Communicate Breath of Eons timing with raid leader.",
        priorities = {
            { spellID=nil, name="Ebon Might",      priority=1, why="100% uptime is mandatory. Late refreshes cost your raid more damage than any personal mistake.", tags={"core"} },
            { spellID=nil, name="Prescience",      priority=2, why="Maintain on the two highest-damage allies. Track their buff durations. 2 charges.", tags={"core"} },
            { spellID=nil, name="Eruption",        priority=3, why="ST filler with Fate Mirror value — cast immediately on Essence Burst procs.", tags={"core"} },
            { spellID=nil, name="Upheaval",        priority=4, why="On cooldown — aligns well with Bloodlust burst windows.", isCd=true, tags={"cd"} },
            { spellID=361469, name="Living Flame", priority=5, why="Filler. Aim at most injured ally if healing is needed.", tags={"active"} },
            { spellID=nil, name="Breath of Eons",  priority=nil, isCd=true, isMajorCd=true, why="Coordinate with raid leader — use when cooldowns and Bloodlust align for maximum amplification.", tags={"major-cd"} },
        },
    },
}


-- ── Survival Hunter (specID 255) ──────────────────────────────────────
-- Source: Icy Veins 12.0.7, Maxroll, Azortharion — updated Jun 2026
-- Hero talent: Pack Leader (recommended for all content)
-- Core loop: Raptor Strike generates Tip of the Spear → spend into
--            Kill Command (ST) or Wildfire Bomb (AoE)
-- New in Midnight: Takedown replaces Coordinated Assault, Aspect of the
--   Eagle is now a core rotational tool (15s ranged window)
-- ── Survival Hunter (specID 255) ──────────────────────────────────────
-- SpellIDs verified against Midnight 12.0.5 combat log and tooltip data
-- Raptor Strike (259489) and Kill Command (34026) confirmed from combat log
-- Hunter's Mark = 257284, Wildfire Bomb = 269752
-- Takedown (Pack Leader signature) = use nil until verified ingame
R[255] = {
    solo = {
        tip = "Survival solo: Misdirect to your pet before pulling. Wildfire Bomb into packs, Harpoon gap-closes. Ferocity pet provides Primal Rage (Bloodlust) and passive leech healing.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",        priority=1,  why="+3% damage to target — apply before every pull, always maintain.",         tags={"core"},
              when=C.DebuffRefresh(257284, 3) },
            { spellID=nil,    name="Takedown",             priority=2,  why="Primary cooldown — charges to target, grants +20% damage for 8s. Open every pull.", tags={"core","cd"}, isCd=true },
            { spellID=269752, name="Wildfire Bomb",        priority=3,  why="Highest damage ability — use empowered by Tip of the Spear.", tags={"core"} },
            { spellID=34026,  name="Kill Command",         priority=4,  why="Primary spender — send pet, empowered by Tip of the Spear stacks.", tags={"core"} },
            { spellID=259489, name="Raptor Strike",        priority=5,  why="Primary generator — builds Tip of the Spear. Cast between every spender.", tags={"core"} },
            { spellID=190925, name="Harpoon",              priority=6,  why="Gap closer — resets on kill in Midnight. Chain pull packs efficiently.", tags={"active"},
              -- Positioning tool, not damage. Suppress on a target about to die.
              when=C.TargetLives(4) },
            { spellID=53351,  name="Kill Shot",            priority=7,  why="Execute under 20% HP. Pack Leader procs allow use at any HP in burst.", tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=187650, name="Freezing Trap",        priority=8,  why="CC — freeze a mob 60s. Pull around it or use on dangerous adds.",   tags={"active"},
              -- CC is for live packs, never for something already dying.
              when=C.And(C.TargetLives(6), C.AoE(2)) },
        },
    },
    aoe = {
        tip = "Survival M+: Wildfire Bomb is your primary AoE — always Tip-empowered. Raptor Strike/Swipe generates stacks on all targets. Position Takedown's Stampede to hit the whole pack.",
        chain = {
            { spellID=257284, name="Hunter's Mark" },
            { spellID=nil,    name="Takedown" },
            { spellID=269752, name="Wildfire Bomb" },
            { spellID=259489, name="Raptor Strike" },
            { spellID=34026,  name="Kill Command" },
            { spellID=269752, name="Wildfire Bomb" },
        },
        priorities = {
            { spellID=257284, name="Hunter's Mark",        priority=1,  why="+3% flat damage — maintain on primary target at all times.",         tags={"core"} },
            { spellID=nil,    name="Takedown",             priority=2,  why="On cooldown — triggers Stampede! (Pack Leader). Position to hit all targets.", tags={"core","cd"}, isCd=true },
            { spellID=269752, name="Wildfire Bomb",        priority=3,  why="Primary AoE — always Tip-of-the-Spear empowered for max damage.", tags={"core"} },
            { spellID=259489, name="Raptor Strike",        priority=4,  why="Generator — becomes Raptor Swipe on 2+ targets. Builds Tip stacks.", tags={"core"} },
            { spellID=34026,  name="Kill Command",         priority=5,  why="Strong in AoE — pet cleaves via Beast Cleave. Use between bombs.", tags={"core"} },
            { spellID=190925, name="Harpoon",              priority=6,  why="Gap closer — resets on kill. Essential for chaining M+ pulls.",  tags={"active"} },
            { spellID=187650, name="Freezing Trap",        priority=7,  why="CC — freeze dangerous casters or priority adds.",            tags={"active"} },
            { spellID=53351,  name="Kill Shot",            priority=8,  why="Execute under 20% — always priority on low-HP targets.",            tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=nil,    name="Boomstick",            priority=nil, isCd=true, isMajorCd=true,
              why="Large cone AoE cooldown — position to hit entire pack. Strongest on 5+ target pulls.", tags={"major-cd"} },
            { spellID=186265, name="Aspect of the Turtle", priority=nil, isCd=true,
              why="Full immunity + 30% DR. Use on dangerous mechanics or when about to die.", tags={"defensive"} },
            { spellID=264735, name="Survival of the Fittest", priority=nil, isCd=true,
              why="30% DR, 2 charges, 1.5min CD. Best personal defensive — use freely on damage spikes.", tags={"defensive"} },
        },
    },
    st = {
        tip = "Survival Raid: Focus Kill Command as primary ST spender. Raptor Strike between every spender. Takedown on cooldown — align with Bloodlust. Aspect of Eagle during ranged phases.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",        priority=1,  why="+3% flat damage — apply pre-pull, maintain throughout the fight.", tags={"core"},
              when=C.DebuffRefresh(257284, 3) },
            { spellID=nil,    name="Takedown",             priority=2,  why="Major cooldown — on cooldown, align with Bloodlust when available.", tags={"core","cd"}, isCd=true, isMajorCd=true },
            { spellID=34026,  name="Kill Command",         priority=3,  why="Primary ST spender — use when empowered by Tip of the Spear.", tags={"core"} },
            { spellID=269752, name="Wildfire Bomb",        priority=4,  why="Strong ST damage — never hold >1 charge. Always Tip-empowered.", tags={"core"} },
            { spellID=259489, name="Raptor Strike",        priority=5,  why="Generator — keeps Tip of the Spear rolling. Fill every GCD.", tags={"core"} },
            { spellID=53351,  name="Kill Shot",            priority=6,  why="Execute under 20% — highest priority during execute phase.",               tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=190925, name="Harpoon",              priority=7,  why="If needed for positioning — does not break Tip stacks.",  tags={"active"},
              when=C.TargetLives(4) },
            { spellID=186265, name="Aspect of the Turtle", priority=nil, isCd=true,
              why="Immunity — use when assigned to soak a mechanic or healer is overwhelmed.", tags={"defensive"} },
            { spellID=264735, name="Survival of the Fittest", priority=nil, isCd=true,
              why="Personal DR — 2 charges. Use on predictable raid damage spikes.", tags={"defensive"} },
        },
    },
}

-- ── Beast Mastery Hunter (specID 253) ─────────────────────────────────
R[253] = {
    solo = {
        tip = "BM solo: your pet does most of the work. Keep Kill Command on cooldown, spam Barbed Shot to maintain Frenzy stacks on your pet, fill with Cobra Shot. Ferocity pet for Primal Rage (Bloodlust).",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% damage — maintain at all times.", tags={"core"},
              -- Debuff shares the cast ID. Only suggest when missing or in the
              -- last 3s, otherwise it wins slot 1 forever and the bar never moves.
              when=C.DebuffRefresh(257284, 3) },
            { spellID=217200, name="Barbed Shot",       priority=2, why="Maintain Frenzy stacks on pet — never let stacks drop. 2 charges.", tags={"core"} },
            { spellID=34026,  name="Kill Command",      priority=3, why="Primary damage ability — on cooldown always.", tags={"core"} },
            { spellID=193455, name="Cobra Shot",        priority=4, why="Filler — generates Focus, reduces Kill Command CD by 1s.", tags={"active"} },
            { spellID=19574,  name="Bestial Wrath",     priority=5, why="Primary cooldown — +25% pet damage for 15s. On cooldown.", tags={"cd"}, isCd=true },
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20% HP — always priority.", tags={"active"}, when=C.ExecuteOrProc(20) },
        },
    },
    aoe = {
        tip = "BM AoE: Multi-Shot to apply Beast Cleave to pet, then maintain Barbed Shot and Kill Command as normal. Beast Cleave makes your pet hit all nearby enemies for 4 seconds.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% damage on primary target.", tags={"core"} },
            { spellID=2643,   name="Multi-Shot",        priority=2, why="Apply Beast Cleave — pet hits all nearby targets for 4 sec. Refresh every 3-4s.", tags={"core"} },
            { spellID=217200, name="Barbed Shot",       priority=3, why="Maintain Frenzy — 2 charges, never let drop.", tags={"core"} },
            { spellID=34026,  name="Kill Command",      priority=4, why="On cooldown — spreads damage via Beast Cleave.", tags={"core"} },
            { spellID=193455, name="Cobra Shot",        priority=5, why="Filler — refreshes Beast Cleave duration.", tags={"active"} },
            { spellID=19574,  name="Bestial Wrath",     priority=nil, isCd=true, isMajorCd=true, why="Major CD — use on large packs with Beast Cleave active.", tags={"major-cd"} },
        },
    },
    st = {
        tip = "BM Raid: same as solo priority. Bestial Wrath on cooldown, align with Bloodlust when possible. Keep Barbed Shot at 2 stacks always — this is your highest-skill requirement.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% flat damage — maintain throughout the fight.", tags={"core"} },
            { spellID=217200, name="Barbed Shot",       priority=2, why="Frenzy maintenance — never let stacks drop to 0. Highest priority at 1 stack.", tags={"core"} },
            { spellID=34026,  name="Kill Command",      priority=3, why="Primary damage — on cooldown always.", tags={"core"} },
            { spellID=19574,  name="Bestial Wrath",     priority=4, why="On cooldown — align with Bloodlust. Stack with trinket on-use.", tags={"cd"}, isCd=true },
            { spellID=193455, name="Cobra Shot",        priority=5, why="Filler — do not overcap Focus.", tags={"active"} },
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20%.", tags={"active"}, when=C.ExecuteOrProc(20) },
        },
    },
}

-- ── Marksmanship Hunter (specID 254) ──────────────────────────────────
R[254] = {
    solo = {
        tip = "MM solo: cast Trueshot on cooldown, spam Aimed Shot with Precise Shots procs. Rapid Fire as your second major ability. Arcane Shot as filler. Fully ranged — great for questing safety.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% damage — maintain at all times.", tags={"core"} },
            { spellID=19434,  name="Aimed Shot",        priority=2, why="Primary nuke — cast with Precise Shots buff for reduced cast time.", tags={"core"},
              -- Aimed Shot costs 35 Focus. Below that it is not castable, so
              -- suggesting it wastes a slot the filler should hold.
              when=C.PowerAtLeast(35) },
            { spellID=257044, name="Rapid Fire",        priority=3, why="Channeled — highest DPS per GCD. On cooldown.", tags={"core"} },
            { spellID=185358, name="Arcane Shot",       priority=4, why="Filler — spends Precise Shots procs, generates Focus.", tags={"active"},
              -- Filler: only worth a slot with Focus to spend. Keeps the bar
              -- from recommending a shot that will not fire.
              when=C.PowerAtLeast(40) },
            { spellID=288613, name="Trueshot",          priority=nil, isCd=true, isMajorCd=true, why="Primary CD — on cooldown. Aimed Shot and Rapid Fire both grant Precise Shots inside.", tags={"major-cd"} },
            { spellID=271788, name="Kill Shot",         priority=5, why="Execute under 20%.", tags={"active"}, when=C.ExecuteOrProc(20) },
        },
    },
    aoe = {
        tip = "MM AoE: Multi-Shot applies Trick Shots — Aimed Shot and Rapid Fire then ricochet to all nearby targets. Volley for large packs. Trick Shots is the AoE mechanic — maintain it.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% on primary target.", tags={"core"} },
            { spellID=257620, name="Multi-Shot",        priority=2, why="Apply Trick Shots — makes Aimed Shot and Rapid Fire ricochet to all targets.", tags={"core"} },
            { spellID=19434,  name="Aimed Shot",        priority=3, why="Ricochets via Trick Shots — primary AoE damage inside Trick Shots window.", tags={"core"} },
            { spellID=257044, name="Rapid Fire",        priority=4, why="Channels and ricochets — strong AoE, use on cooldown.", tags={"core"} },
            { spellID=260243, name="Volley",            priority=5, why="Sustained ground AoE — strong on 5+ stationary targets.", tags={"active"} },
            { spellID=288613, name="Trueshot",          priority=nil, isCd=true, isMajorCd=true, why="Major CD — cast with Trick Shots active and on large pull.", tags={"major-cd"} },
        },
    },
    st = {
        tip = "MM Raid: pure ranged, safest Hunter spec for mechanics. Aimed Shot with Precise Shots, Rapid Fire on cooldown. Trueshot aligned with Bloodlust. Double Tap before Trueshot for opener.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% flat damage — maintain throughout.", tags={"core"} },
            { spellID=19434,  name="Aimed Shot",        priority=2, why="Primary nuke — always with Precise Shots. Never cast without it.", tags={"core"} },
            { spellID=257044, name="Rapid Fire",        priority=3, why="On cooldown — generates Precise Shots.", tags={"core"} },
            { spellID=288613, name="Trueshot",          priority=4, why="Align with Bloodlust — opener: Trueshot → Aimed Shot → Volley (if talented).", tags={"cd"}, isCd=true, isMajorCd=true },
            { spellID=185358, name="Arcane Shot",       priority=5, why="Filler — spends Precise Shots, do not overcap.", tags={"active"} },
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20%.", tags={"active"}, when=C.ExecuteOrProc(20) },
        },
    },
}

-- ── WARRIOR ───────────────────────────────────────────────────────────
R[71] = { -- Arms
    solo = {
        tip = "Arms solo: Mortal Strike is king. Use Overpower on procs, Slam as filler. Execute below 20%. Sweeping Strikes for 2+ mobs.",
        priorities = {
            { spellID=12294,  name="Mortal Strike",     priority=1, why="Primary nuke. Use on cooldown.", tags={"core"} },
            { spellID=7384,   name="Overpower",         priority=2, why="Free proc — use immediately, never waste.", tags={"core"} },
            { spellID=163201, name="Execute",           priority=3, why="Below 20% — replaces Slam in execute.", tags={"core"}, when=C.ExecuteOrProc(20) },
            { spellID=1464,   name="Slam",              priority=4, why="Rage dump filler when MS and OP are on CD.", tags={"active"} },
            { spellID=260708, name="Sweeping Strikes",  priority=5, why="2+ targets — enables cleave for 12s.", tags={"aoe"} },
            { spellID=18499,  name="Berserker Rage",    priority=nil, isCd=true, why="Enrage on demand + fear break.", tags={"defensive"} },
            { spellID=97462,  name="Rallying Cry",      priority=nil, isCd=true, isMajorCd=true, why="Emergency group heal — use when low.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Arms AoE: Sweeping Strikes + Cleave/Whirlwind → Mortal Strike. Bladestorm for massive packs.",
        priorities = {
            { spellID=260708, name="Sweeping Strikes",  priority=1, why="Enable cleave on every use — 12s uptime.", tags={"core"} },
            { spellID=845,    name="Cleave",            priority=2, why="AoE rage spender, replaces Slam.", tags={"core"} },
            { spellID=12294,  name="Mortal Strike",     priority=3, why="Still strongest single hit, cleaved by SS.", tags={"core"} },
            { spellID=7384,   name="Overpower",         priority=4, why="Proc — still use between MS.", tags={"active"} },
            { spellID=227847, name="Bladestorm",        priority=nil, isCd=true, isMajorCd=true, why="Massive AoE — use on 4+ packs.", tags={"cd"} },
        },
    },
    st = {
        tip = "Arms ST: Mortal Strike on CD, Overpower procs, Execute in window. Align Colossus Smash with burst.",
        priorities = {
            { spellID=167105, name="Colossus Smash",    priority=1, why="Debuff window — dump rage during this.", tags={"core"} },
            { spellID=12294,  name="Mortal Strike",     priority=2, why="Highest priority inside CS window.", tags={"core"} },
            { spellID=7384,   name="Overpower",         priority=3, why="Free damage — never cap 2 charges.", tags={"core"} },
            { spellID=163201, name="Execute",           priority=4, why="Sub-20% replaces Slam entirely.", tags={"core"}, when=C.ExecuteOrProc(20) },
            { spellID=1464,   name="Slam",              priority=5, why="Filler outside CS window.", tags={"active"} },
            { spellID=227847, name="Bladestorm",        priority=nil, isCd=true, isMajorCd=true, why="Use during Colossus Smash if talented.", tags={"cd"} },
        },
    },
}
R[72] = { -- Fury
    solo = {
        tip = "Fury solo: Rampage at 80+ rage, Bloodthirst on CD for Enrage, Raging Blow as filler. Nearly unkillable with Enrage healing.",
        priorities = {
            { spellID=184367, name="Rampage",           priority=1, why="At 80+ rage — triggers Enrage.", tags={"core"} },
            { spellID=23881,  name="Bloodthirst",       priority=2, why="On cooldown — Enrage proc + self-heal.", tags={"core"} },
            { spellID=85288,  name="Raging Blow",       priority=3, why="2 charges — dump between BT/Rampage.", tags={"core"} },
            { spellID=163201, name="Execute",           priority=4, why="Sub-20% — replaces Raging Blow.", tags={"core"}, when=C.ExecuteOrProc(20) },
            { spellID=190411, name="Whirlwind",         priority=5, why="Only for 2+ mobs (enables Meat Cleaver).", tags={"aoe"} },
            { spellID=1719,   name="Recklessness",      priority=nil, isCd=true, isMajorCd=true, why="Major burst CD — Rampage spam during.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Fury AoE: Whirlwind (enables cleave) → Rampage → Bloodthirst. Recklessness on large pulls.",
        priorities = {
            { spellID=190411, name="Whirlwind",         priority=1, why="Always first — enables Meat Cleaver for next 2 hits.", tags={"core"} },
            { spellID=184367, name="Rampage",           priority=2, why="At 80 rage — cleaves via Meat Cleaver.", tags={"core"} },
            { spellID=23881,  name="Bloodthirst",       priority=3, why="Enrage + healing.", tags={"core"} },
            { spellID=85288,  name="Raging Blow",       priority=4, why="Fill between WW refreshes.", tags={"active"} },
            { spellID=1719,   name="Recklessness",      priority=nil, isCd=true, isMajorCd=true, why="Big packs — pop and Rampage spam.", tags={"cd"} },
        },
    },
    st = {
        tip = "Fury ST: Rampage at 80 rage, BT on CD for Enrage uptime, Raging Blow filler. Execute phase is massive.",
        priorities = {
            { spellID=184367, name="Rampage",           priority=1, why="80+ rage — Enrage proc is your damage steroid.", tags={"core"} },
            { spellID=23881,  name="Bloodthirst",       priority=2, why="On CD — Enrage uptime is everything.", tags={"core"} },
            { spellID=85288,  name="Raging Blow",       priority=3, why="Dump charges between BT.", tags={"core"} },
            { spellID=163201, name="Execute",           priority=4, why="Sub-20% — massive with Enrage.", tags={"core"}, when=C.ExecuteOrProc(20) },
            { spellID=1719,   name="Recklessness",      priority=nil, isCd=true, isMajorCd=true, why="Align with Bloodlust. Rampage freely.", tags={"cd"} },
        },
    },
}
R[73] = { -- Protection
    solo = {
        tip = "Prot Warrior solo: Shield Slam on CD, Thunder Clap for AoE threat, Revenge procs. Nearly unkillable — pull big.",
        priorities = {
            { spellID=23922,  name="Shield Slam",       priority=1, why="Hardest hit + rage gen. Use on CD.", tags={"core"} },
            { spellID=6572,   name="Revenge",           priority=2, why="Free proc or 20 rage — strong AoE.", tags={"core"} },
            { spellID=6343,   name="Thunder Clap",      priority=3, why="AoE threat + slow. Maintain on packs.", tags={"core"} },
            { spellID=2565,   name="Shield Block",      priority=4, why="Active mitigation — keep up vs melee.", tags={"defensive"} },
            { spellID=190456, name="Ignore Pain",       priority=5, why="Absorb shield — dump excess rage here.", tags={"defensive"} },
            { spellID=1160,   name="Demoralizing Shout",priority=nil, isCd=true, why="Big pulls — 20% less damage taken.", tags={"defensive"} },
            { spellID=12975,  name="Last Stand",        priority=nil, isCd=true, isMajorCd=true, why="Emergency — 30% max HP.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Prot AoE: Thunder Clap priority, Revenge on proc, Shield Slam for rage. Ravager/Bladestorm for burst AoE.",
        priorities = {
            { spellID=6343,   name="Thunder Clap",      priority=1, why="AoE threat baseline — always on CD in packs.", tags={"core"} },
            { spellID=6572,   name="Revenge",           priority=2, why="Strong AoE + free procs.", tags={"core"} },
            { spellID=23922,  name="Shield Slam",       priority=3, why="Rage gen for Shield Block uptime.", tags={"core"} },
            { spellID=2565,   name="Shield Block",      priority=4, why="100% uptime in M+ pulls.", tags={"defensive"} },
            { spellID=228920, name="Ravager",           priority=nil, isCd=true, isMajorCd=true, why="Massive AoE CD — use on big pulls.", tags={"cd"} },
        },
    },
    st = {
        tip = "Prot ST: Shield Slam > Revenge (proc) > Thunder Clap. Maintain Shield Block + Ignore Pain.",
        priorities = {
            { spellID=23922,  name="Shield Slam",       priority=1, why="Hardest hit + rage.", tags={"core"} },
            { spellID=6572,   name="Revenge",           priority=2, why="Only on free proc (save rage for IP).", tags={"core"} },
            { spellID=6343,   name="Thunder Clap",      priority=3, why="Filler + slow.", tags={"active"} },
            { spellID=2565,   name="Shield Block",      priority=4, why="Maintain vs physical bosses.", tags={"defensive"} },
            { spellID=190456, name="Ignore Pain",       priority=5, why="Dump rage above 60.", tags={"defensive"} },
        },
    },
}

-- ── PALADIN ───────────────────────────────────────────────────────────
R[65] = { -- Holy Paladin
    solo = {
        tip = "Holy Paladin solo: Crusader Strike to generate Holy Power, Judgment on CD, Holy Shock offensively. Word of Glory when needed.",
        priorities = {
            { spellID=35395,  name="Crusader Strike",   priority=1, why="Holy Power generator — melee range.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=2, why="Ranged damage + HP gen. On CD.", tags={"core"} },
            { spellID=20473,  name="Holy Shock",        priority=3, why="Instant — damage or heal based on target.", tags={"core"} },
            { spellID=85673,  name="Word of Glory",     priority=4, why="At 3 HP — self-heal when below 60%.", tags={"core"} },
            { spellID=275773, name="Hammer of Wrath",   priority=5, why="Execute or during Avenging Wrath.", tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=31884,  name="Avenging Wrath",    priority=nil, isCd=true, isMajorCd=true, why="Burst CD — damage and healing increase.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Holy M+: Holy Shock on CD for healing, Light of Dawn at 3 HP, Crusader Strike between.",
        priorities = {
            { spellID=20473,  name="Holy Shock",        priority=1, why="Core heal — use on most injured.", tags={"core"} },
            { spellID=85222,  name="Light of Dawn",     priority=2, why="At 3 HP — AoE heal cone.", tags={"core"} },
            { spellID=35395,  name="Crusader Strike",   priority=3, why="HP gen + CDR on Holy Shock.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=4, why="HP gen from range.", tags={"active"} },
            { spellID=31821,  name="Aura Mastery",      priority=nil, isCd=true, isMajorCd=true, why="Raid CD — massive damage reduction.", tags={"cd"} },
        },
    },
    st = {
        tip = "Holy Raid: maintain Beacon, Holy Shock on CD, Word of Glory on tanks, Light of Dawn on stacked groups.",
        priorities = {
            { spellID=20473,  name="Holy Shock",        priority=1, why="Highest priority — heals and generates HP.", tags={"core"} },
            { spellID=85673,  name="Word of Glory",     priority=2, why="At 3 HP — strong single-target heal on tank.", tags={"core"} },
            { spellID=85222,  name="Light of Dawn",     priority=3, why="At 3 HP if group is stacked.", tags={"core"} },
            { spellID=35395,  name="Crusader Strike",   priority=4, why="Filler for HP generation.", tags={"active"} },
            { spellID=31884,  name="Avenging Wrath",    priority=nil, isCd=true, isMajorCd=true, why="Align with damage events.", tags={"cd"} },
        },
    },
}
R[66] = { -- Protection Paladin
    solo = {
        tip = "Prot Paladin solo: Shield of the Righteous at 3 HP, Judgment on CD, Avenger's Shield procs. Insanely durable.",
        priorities = {
            { spellID=53600,  name="Shield of the Righteous", priority=1, why="At 3 HP — active mitigation + damage.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=2, why="Generates HP + damage.", tags={"core"} },
            { spellID=31935,  name="Avenger's Shield",  priority=3, why="Bouncing shield — interrupts + big damage.", tags={"core"} },
            { spellID=275779, name="Hammer of the Righteous", priority=4, why="HP gen melee filler.", tags={"active"} },
            { spellID=26573,  name="Consecration",      priority=5, why="Ground AoE — stand in it for DR.", tags={"core"} },
            { spellID=31850,  name="Ardent Defender",    priority=nil, isCd=true, isMajorCd=true, why="40% DR + cheat death.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Prot M+: Avenger's Shield for snap threat, Consecration always down, SotR for mitigation, Judgment for HP.",
        priorities = {
            { spellID=31935,  name="Avenger's Shield",  priority=1, why="AoE threat snap — bounces to 3 targets.", tags={"core"} },
            { spellID=26573,  name="Consecration",      priority=2, why="AoE DoT — always stand in it.", tags={"core"} },
            { spellID=53600,  name="Shield of the Righteous", priority=3, why="Mitigation — maintain uptime.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=4, why="HP gen.", tags={"active"} },
            { spellID=275779, name="Hammer of the Righteous", priority=5, why="Filler — AoE damage.", tags={"active"} },
        },
    },
    st = {
        tip = "Prot ST: SotR uptime, Judgment on CD, Avenger's Shield on proc. Consecration always down.",
        priorities = {
            { spellID=53600,  name="Shield of the Righteous", priority=1, why="Active mitigation — maintain.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=2, why="HP gen + damage.", tags={"core"} },
            { spellID=31935,  name="Avenger's Shield",  priority=3, why="On proc — free damage.", tags={"core"} },
            { spellID=26573,  name="Consecration",      priority=4, why="Maintain ground effect.", tags={"core"} },
            { spellID=275779, name="Hammer of the Righteous", priority=5, why="Filler.", tags={"active"} },
        },
    },
}
R[70] = { -- Retribution
    solo = {
        tip = "Ret solo: Templar's Verdict at 3+ HP, Blade of Justice on CD, Judgment on CD, Crusader Strike filler. Wings for burst.",
        priorities = {
            { spellID=85256,  name="Templar's Verdict", priority=1, why="At 3+ Holy Power — primary spender.", tags={"core"} },
            { spellID=184575, name="Blade of Justice",  priority=2, why="2 HP gen — always on CD.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=3, why="HP gen + damage buff window.", tags={"core"} },
            { spellID=35395,  name="Crusader Strike",   priority=4, why="Filler HP gen.", tags={"active"} },
            { spellID=275773, name="Hammer of Wrath",   priority=5, why="Execute or during Wings.", tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=255937, name="Wake of Ashes",     priority=nil, isCd=true, why="3 HP instant + AoE stun. Use on CD.", tags={"cd"} },
            { spellID=31884,  name="Avenging Wrath",    priority=nil, isCd=true, isMajorCd=true, why="Burst window — enables HoW spam.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Ret AoE: Divine Storm at 3+ HP, Wake of Ashes for HP gen, Consecration.",
        priorities = {
            { spellID=53385,  name="Divine Storm",      priority=1, why="At 3+ HP — AoE spender replaces TV.", tags={"core"} },
            { spellID=255937, name="Wake of Ashes",     priority=2, why="3 HP + massive AoE damage.", tags={"core"} },
            { spellID=184575, name="Blade of Justice",  priority=3, why="HP gen.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=4, why="HP gen.", tags={"active"} },
            { spellID=26573,  name="Consecration",      priority=5, why="Ground AoE if talented.", tags={"active"} },
        },
    },
    st = {
        tip = "Ret ST: Templar's Verdict dump, Blade of Justice and Judgment on CD, align Wake of Ashes with Wings.",
        priorities = {
            { spellID=85256,  name="Templar's Verdict", priority=1, why="At 3+ HP — primary damage.", tags={"core"} },
            { spellID=184575, name="Blade of Justice",  priority=2, why="HP gen priority.", tags={"core"} },
            { spellID=20271,  name="Judgment",          priority=3, why="HP gen + debuff window.", tags={"core"} },
            { spellID=255937, name="Wake of Ashes",     priority=4, why="3 HP burst on CD.", tags={"core"} },
            { spellID=275773, name="Hammer of Wrath",   priority=5, why="Execute or Wings-enabled.", tags={"active"}, when=C.ExecuteOrProc(20) },
            { spellID=31884,  name="Avenging Wrath",    priority=nil, isCd=true, isMajorCd=true, why="Major burst — align with Bloodlust.", tags={"cd"} },
        },
    },
}

-- ── DEATH KNIGHT ──────────────────────────────────────────────────────
R[250] = { -- Blood
    solo = {
        tip = "Blood DK solo: Death Strike is your heal. Heart Strike for RP gen. Marrowrend to maintain Bone Shield. Pull everything.",
        priorities = {
            { spellID=49998,  name="Death Strike",      priority=1, why="Self-heal — spend RP here. Never cap.", tags={"core"} },
            { spellID=206930, name="Heart Strike",      priority=2, why="RP generator — cleaves 2+ targets.", tags={"core"} },
            { spellID=195182, name="Marrowrend",        priority=3, why="Maintain 5+ Bone Shield stacks.", tags={"core"} },
            { spellID=50842,  name="Blood Boil",        priority=4, why="AoE threat + disease. 2 charges.", tags={"core"} },
            { spellID=55233,  name="Vampiric Blood",    priority=nil, isCd=true, isMajorCd=true, why="30% max HP + healing received.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Blood AoE: Blood Boil for diseases, Heart Strike cleave, Death and Decay for extra RP. Death Strike to stay alive.",
        priorities = {
            { spellID=50842,  name="Blood Boil",        priority=1, why="AoE snap threat. Never cap charges.", tags={"core"} },
            { spellID=43265,  name="Death and Decay",   priority=2, why="Ground AoE + empowers Heart Strike.", tags={"core"} },
            { spellID=206930, name="Heart Strike",      priority=3, why="Cleave inside D&D.", tags={"core"} },
            { spellID=49998,  name="Death Strike",      priority=4, why="Heal — spend RP above 80.", tags={"core"} },
            { spellID=195182, name="Marrowrend",        priority=5, why="Bone Shield maintenance.", tags={"active"} },
        },
    },
    st = {
        tip = "Blood ST: Heart Strike for RP, Death Strike to heal, Marrowrend at <5 Bone Shield.",
        priorities = {
            { spellID=49998,  name="Death Strike",      priority=1, why="Primary heal — don't overcap RP.", tags={"core"} },
            { spellID=206930, name="Heart Strike",      priority=2, why="RP gen.", tags={"core"} },
            { spellID=195182, name="Marrowrend",        priority=3, why="Below 5 stacks only.", tags={"core"} },
            { spellID=50842,  name="Blood Boil",        priority=4, why="Disease maintenance.", tags={"active"} },
            { spellID=55233,  name="Vampiric Blood",    priority=nil, isCd=true, isMajorCd=true, why="Big damage phases.", tags={"defensive"} },
        },
    },
}
R[251] = { -- Frost DK
    solo = {
        tip = "Frost DK solo: Obliterate with Killing Machine procs, Howling Blast for AoE/Rime procs, Frost Strike to dump RP.",
        priorities = {
            { spellID=49020,  name="Obliterate",        priority=1, why="Core hit — empowered by Killing Machine.", tags={"core"} },
            { spellID=49184,  name="Howling Blast",     priority=2, why="On Rime proc (free) or to apply Frost Fever.", tags={"core"} },
            { spellID=49143,  name="Frost Strike",      priority=3, why="RP dump — never overcap.", tags={"core"} },
            { spellID=196770, name="Remorseless Winter", priority=4, why="AoE on 3+ targets.", tags={"aoe"} },
            { spellID=51271,  name="Pillar of Frost",   priority=nil, isCd=true, isMajorCd=true, why="Major burst — Obliterate spam during.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Frost AoE: Remorseless Winter, Howling Blast (Rime), Glacial Advance. Obliterate with KM procs.",
        priorities = {
            { spellID=196770, name="Remorseless Winter", priority=1, why="Sustained AoE — always up in packs.", tags={"core"} },
            { spellID=49184,  name="Howling Blast",     priority=2, why="Rime procs for AoE spread.", tags={"core"} },
            { spellID=194913, name="Glacial Advance",   priority=3, why="AoE RP spender (if talented).", tags={"core"} },
            { spellID=49020,  name="Obliterate",        priority=4, why="KM procs only in AoE.", tags={"active"} },
            { spellID=51271,  name="Pillar of Frost",   priority=nil, isCd=true, isMajorCd=true, why="Burst on big pulls.", tags={"cd"} },
        },
    },
    st = {
        tip = "Frost ST: Obliterate with KM, Frost Strike to dump RP, Howling Blast only on Rime. Pillar of Frost on CD.",
        priorities = {
            { spellID=49020,  name="Obliterate",        priority=1, why="Primary — especially with Killing Machine.", tags={"core"} },
            { spellID=49143,  name="Frost Strike",      priority=2, why="Dump RP. Never overcap.", tags={"core"} },
            { spellID=49184,  name="Howling Blast",     priority=3, why="Only on Rime proc.", tags={"core"} },
            { spellID=51271,  name="Pillar of Frost",   priority=nil, isCd=true, isMajorCd=true, why="Align with Bloodlust.", tags={"cd"} },
        },
    },
}
R[252] = { -- Unholy DK
    solo = {
        tip = "Unholy DK solo: Festering Strike to apply wounds, Scourge Strike to pop them, Death Coil at 80+ RP. Dark Transformation pet buff.",
        priorities = {
            { spellID=85948,  name="Scourge Strike",    priority=1, why="Pops Festering Wounds for damage.", tags={"core"} },
            { spellID=194311, name="Festering Strike",  priority=2, why="Apply 2-3 wounds to target.", tags={"core"} },
            { spellID=47541,  name="Death Coil",        priority=3, why="RP dump — empowers pet via Sudden Doom.", tags={"core"} },
            { spellID=63560,  name="Dark Transformation", priority=4, why="Pet steroid — use on CD.", tags={"core"} },
            { spellID=77575,  name="Outbreak",          priority=5, why="Apply Virulent Plague (disease).", tags={"active"} },
            { spellID=275699, name="Apocalypse",        priority=nil, isCd=true, isMajorCd=true, why="Pops 4 wounds + summons ghouls.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Unholy AoE: Death and Decay → Scourge Strike (becomes Clawing Shadows AoE inside), Epidemic for RP dump.",
        priorities = {
            { spellID=43265,  name="Death and Decay",   priority=1, why="Empowers SS to cleave inside.", tags={"core"} },
            { spellID=85948,  name="Scourge Strike",    priority=2, why="Cleaves inside D&D.", tags={"core"} },
            { spellID=207317, name="Epidemic",          priority=3, why="AoE RP dump — replaces Death Coil.", tags={"core"} },
            { spellID=194311, name="Festering Strike",  priority=4, why="Wound application.", tags={"active"} },
            { spellID=77575,  name="Outbreak",          priority=5, why="Spread disease.", tags={"active"} },
        },
    },
    st = {
        tip = "Unholy ST: Wound up → pop wounds → Death Coil dump. Dark Transformation and Apocalypse on CD.",
        priorities = {
            { spellID=85948,  name="Scourge Strike",    priority=1, why="Pop wounds at 4+.", tags={"core"} },
            { spellID=194311, name="Festering Strike",  priority=2, why="Below 4 wounds on target.", tags={"core"} },
            { spellID=47541,  name="Death Coil",        priority=3, why="RP dump. Sudden Doom = free.", tags={"core"} },
            { spellID=63560,  name="Dark Transformation", priority=4, why="On CD.", tags={"core"} },
            { spellID=275699, name="Apocalypse",        priority=nil, isCd=true, isMajorCd=true, why="At 4 wounds for max burst.", tags={"cd"} },
        },
    },
}

-- ── DEMON HUNTER ──────────────────────────────────────────────────────
R[577] = { -- Havoc
    solo = {
        tip = "Havoc solo: Demon's Bite to gen Fury, Chaos Strike at 40+ Fury, Eye Beam on 2+ mobs. Blade Dance for AoE.",
        priorities = {
            { spellID=162243, name="Demon's Bite",      priority=1, why="Fury generator — filler between spenders.", tags={"core"} },
            { spellID=162794, name="Chaos Strike",      priority=2, why="At 40+ Fury — primary ST spender.", tags={"core"} },
            { spellID=198013, name="Eye Beam",          priority=3, why="Massive AoE — use on 2+ targets or with Demonic.", tags={"core"} },
            { spellID=188499, name="Blade Dance",       priority=4, why="AoE + dodge. Use on 2+ mobs.", tags={"core"} },
            { spellID=232893, name="Fel Rush",          priority=5, why="Mobility + damage (don't waste charges).", tags={"active"} },
            { spellID=191427, name="Metamorphosis",     priority=nil, isCd=true, isMajorCd=true, why="Major burst — Annihilation replaces Chaos Strike.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Havoc AoE: Eye Beam > Blade Dance > Glaive Tempest. Chaos Strike only to avoid capping Fury.",
        priorities = {
            { spellID=198013, name="Eye Beam",          priority=1, why="Primary AoE — triggers Demonic.", tags={"core"} },
            { spellID=188499, name="Blade Dance",       priority=2, why="AoE on CD.", tags={"core"} },
            { spellID=342817, name="Glaive Tempest",    priority=3, why="AoE if talented.", tags={"core"} },
            { spellID=162794, name="Chaos Strike",      priority=4, why="Dump fury to avoid capping.", tags={"active"} },
            { spellID=162243, name="Demon's Bite",      priority=5, why="Filler for Fury.", tags={"active"} },
        },
    },
    st = {
        tip = "Havoc ST: Chaos Strike spam, Eye Beam with Demonic, Blade Dance on CD. Metamorphosis for burst.",
        priorities = {
            { spellID=162794, name="Chaos Strike",      priority=1, why="Primary ST damage.", tags={"core"} },
            { spellID=198013, name="Eye Beam",          priority=2, why="Demonic trigger + damage.", tags={"core"} },
            { spellID=188499, name="Blade Dance",       priority=3, why="On CD — high per-hit.", tags={"core"} },
            { spellID=162243, name="Demon's Bite",      priority=4, why="Fury gen filler.", tags={"active"} },
            { spellID=191427, name="Metamorphosis",     priority=nil, isCd=true, isMajorCd=true, why="Burst window.", tags={"cd"} },
        },
    },
}
R[581] = { -- Vengeance
    solo = {
        tip = "Vengeance solo: Soul Cleave to heal, Immolation Aura on CD, Fracture for Soul Fragments. Extremely durable.",
        priorities = {
            { spellID=228477, name="Soul Cleave",       priority=1, why="Heal + damage. Spend Fury here.", tags={"core"} },
            { spellID=258920, name="Immolation Aura",   priority=2, why="Fury gen + AoE. Always on CD.", tags={"core"} },
            { spellID=263642, name="Fracture",          priority=3, why="Generates 2 Soul Fragments.", tags={"core"} },
            { spellID=204596, name="Sigil of Flame",    priority=4, why="AoE ground DoT.", tags={"core"} },
            { spellID=204021, name="Fiery Brand",       priority=nil, isCd=true, why="40% DR on target.", tags={"defensive"} },
            { spellID=187827, name="Metamorphosis",     priority=nil, isCd=true, isMajorCd=true, why="Emergency — massive armor + HP.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Vengeance AoE: Immolation Aura, Sigil of Flame, Spirit Bomb at 4+ Souls, Soul Cleave otherwise.",
        priorities = {
            { spellID=258920, name="Immolation Aura",   priority=1, why="AoE Fury gen.", tags={"core"} },
            { spellID=204596, name="Sigil of Flame",    priority=2, why="Ground AoE.", tags={"core"} },
            { spellID=247454, name="Spirit Bomb",       priority=3, why="At 4+ Souls — AoE heal + damage.", tags={"core"} },
            { spellID=228477, name="Soul Cleave",       priority=4, why="When below 4 Souls.", tags={"core"} },
            { spellID=263642, name="Fracture",          priority=5, why="Soul gen between.", tags={"active"} },
        },
    },
    st = {
        tip = "Vengeance ST: Soul Cleave for healing, Fracture for Souls, Immolation Aura on CD. Fiery Brand for DR.",
        priorities = {
            { spellID=228477, name="Soul Cleave",       priority=1, why="Primary heal + spend.", tags={"core"} },
            { spellID=263642, name="Fracture",          priority=2, why="Soul Fragment gen.", tags={"core"} },
            { spellID=258920, name="Immolation Aura",   priority=3, why="Fury gen on CD.", tags={"core"} },
            { spellID=204596, name="Sigil of Flame",    priority=4, why="Extra damage.", tags={"active"} },
            { spellID=204021, name="Fiery Brand",       priority=nil, isCd=true, why="Tank buster mitigation.", tags={"defensive"} },
        },
    },
}

-- ── DRUID ─────────────────────────────────────────────────────────────
R[102] = { -- Balance
    solo = {
        tip = "Balance solo: Moonfire/Sunfire to DoT, Starsurge at 40+ AP, Wrath/Starfire as fillers. Starfall for 3+ mobs.",
        priorities = {
            { spellID=93402,  name="Sunfire",           priority=1, why="Maintain DoT — AoE spread.", tags={"core"} },
            { spellID=8921,   name="Moonfire",          priority=2, why="Maintain DoT on target.", tags={"core"} },
            { spellID=78674,  name="Starsurge",         priority=3, why="At 40+ Astral Power — ST spender.", tags={"core"} },
            { spellID=190984, name="Wrath",             priority=4, why="Solar filler — faster cast.", tags={"active"} },
            { spellID=194153, name="Starfire",          priority=5, why="Lunar filler — AoE cleave.", tags={"active"} },
            { spellID=191034, name="Starfall",          priority=nil, isCd=true, why="3+ targets — replaces Starsurge.", tags={"cd"} },
            { spellID=194223, name="Celestial Alignment", priority=nil, isCd=true, isMajorCd=true, why="Burst — haste + damage.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Balance AoE: Starfall at 50 AP, maintain Sunfire, Starfire for Lunar cleave.",
        priorities = {
            { spellID=191034, name="Starfall",          priority=1, why="At 50 AP — sustained AoE.", tags={"core"} },
            { spellID=93402,  name="Sunfire",           priority=2, why="AoE DoT spread.", tags={"core"} },
            { spellID=194153, name="Starfire",          priority=3, why="Lunar cleave filler.", tags={"core"} },
            { spellID=8921,   name="Moonfire",          priority=4, why="Maintain on high-HP targets.", tags={"active"} },
            { spellID=194223, name="Celestial Alignment", priority=nil, isCd=true, isMajorCd=true, why="Pop on big packs.", tags={"cd"} },
        },
    },
    st = {
        tip = "Balance ST: Starsurge dump, maintain DoTs, Wrath filler. Align CA with Bloodlust.",
        priorities = {
            { spellID=78674,  name="Starsurge",         priority=1, why="AP spender — buffs next Wrath/Starfire.", tags={"core"} },
            { spellID=93402,  name="Sunfire",           priority=2, why="Maintain.", tags={"core"} },
            { spellID=8921,   name="Moonfire",          priority=3, why="Maintain.", tags={"core"} },
            { spellID=190984, name="Wrath",             priority=4, why="Filler.", tags={"active"} },
            { spellID=194223, name="Celestial Alignment", priority=nil, isCd=true, isMajorCd=true, why="Major burst.", tags={"cd"} },
        },
    },
}
R[103] = { -- Feral
    solo = {
        tip = "Feral solo: Rake from stealth, Shred to 5 CP, Rip to maintain bleed, Ferocious Bite at 5 CP when Rip is up.",
        priorities = {
            { spellID=1822,   name="Rake",              priority=1, why="Maintain bleed — massive from stealth/Prowl.", tags={"core"} },
            { spellID=5221,   name="Shred",             priority=2, why="CP generator — use from behind.", tags={"core"} },
            { spellID=1079,   name="Rip",               priority=3, why="At 5 CP — maintain bleed always.", tags={"core"} },
            { spellID=22568,  name="Ferocious Bite",    priority=4, why="At 5 CP with Rip up — finisher.", tags={"core"} },
            { spellID=106951, name="Berserk",           priority=nil, isCd=true, isMajorCd=true, why="Burst — energy refund on finishers.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Feral AoE: Primal Wrath at 5 CP (AoE Rip), Swipe for AoE CP gen, Rake highest HP targets.",
        priorities = {
            { spellID=285381, name="Primal Wrath",      priority=1, why="At 5 CP — AoE Rip application.", tags={"core"} },
            { spellID=106785, name="Swipe",             priority=2, why="AoE CP generator.", tags={"core"} },
            { spellID=1822,   name="Rake",              priority=3, why="On 2-3 highest HP targets.", tags={"active"} },
            { spellID=5221,   name="Shred",             priority=4, why="If below 3 targets.", tags={"active"} },
            { spellID=106951, name="Berserk",           priority=nil, isCd=true, isMajorCd=true, why="Big AoE burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "Feral ST: Rake > Rip uptime > Shred to 5 CP > Ferocious Bite. Tiger's Fury on CD for energy.",
        priorities = {
            { spellID=1822,   name="Rake",              priority=1, why="Maintain. Snapshot Tiger's Fury.", tags={"core"} },
            { spellID=1079,   name="Rip",               priority=2, why="At 5 CP. Maintain always.", tags={"core"} },
            { spellID=5221,   name="Shred",             priority=3, why="CP gen.", tags={"core"} },
            { spellID=22568,  name="Ferocious Bite",    priority=4, why="At 5 CP with Rip up.", tags={"core"} },
            { spellID=5217,   name="Tiger's Fury",      priority=nil, isCd=true, why="Energy + damage buff. On CD.", tags={"cd"} },
            { spellID=106951, name="Berserk",           priority=nil, isCd=true, isMajorCd=true, why="Major burst.", tags={"cd"} },
        },
    },
}
R[104] = { -- Guardian
    solo = {
        tip = "Guardian solo: Mangle on CD, Thrash for bleed stacks, Ironfur to mitigate. Pull massive packs.",
        priorities = {
            { spellID=33917,  name="Mangle",            priority=1, why="Rage gen + hardest hit.", tags={"core"} },
            { spellID=77758,  name="Thrash",            priority=2, why="Bleed stacks — maintain 3.", tags={"core"} },
            { spellID=213764, name="Swipe",             priority=3, why="Filler AoE.", tags={"active"} },
            { spellID=192081, name="Ironfur",           priority=4, why="Active mitigation — spend rage.", tags={"defensive"} },
            { spellID=22842,  name="Frenzied Regen",    priority=5, why="Below 70% — heal over time.", tags={"defensive"} },
            { spellID=61336,  name="Survival Instincts", priority=nil, isCd=true, isMajorCd=true, why="50% DR emergency.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Guardian AoE: Thrash for stacks, Swipe filler, Mangle on CD. Ironfur always up.",
        priorities = {
            { spellID=77758,  name="Thrash",            priority=1, why="Bleed stacks on all mobs.", tags={"core"} },
            { spellID=213764, name="Swipe",             priority=2, why="AoE filler.", tags={"core"} },
            { spellID=33917,  name="Mangle",            priority=3, why="Rage gen.", tags={"core"} },
            { spellID=192081, name="Ironfur",           priority=4, why="100% uptime.", tags={"defensive"} },
            { spellID=22842,  name="Frenzied Regen",    priority=5, why="Heal when below 70%.", tags={"defensive"} },
        },
    },
    st = {
        tip = "Guardian ST: Mangle > Thrash (maintain) > Swipe. Ironfur uptime, Frenzied Regen for healing.",
        priorities = {
            { spellID=33917,  name="Mangle",            priority=1, why="Primary rage + damage.", tags={"core"} },
            { spellID=77758,  name="Thrash",            priority=2, why="Maintain bleed.", tags={"core"} },
            { spellID=213764, name="Swipe",             priority=3, why="Filler.", tags={"active"} },
            { spellID=192081, name="Ironfur",           priority=4, why="Keep up always.", tags={"defensive"} },
        },
    },
}
R[105] = { -- Restoration Druid
    solo = {
        tip = "Resto Druid solo: Moonfire/Sunfire to kill mobs, Wrath filler. Rejuv + Swiftmend when hurt.",
        priorities = {
            { spellID=93402,  name="Sunfire",           priority=1, why="DoT — primary solo damage.", tags={"core"} },
            { spellID=8921,   name="Moonfire",          priority=2, why="DoT — maintain on target.", tags={"core"} },
            { spellID=5176,   name="Wrath",             priority=3, why="Filler nuke.", tags={"active"} },
            { spellID=774,    name="Rejuvenation",      priority=4, why="Self-HoT when below 80%.", tags={"core"} },
            { spellID=18562,  name="Swiftmend",         priority=5, why="Instant heal emergency.", tags={"core"} },
        },
    },
    aoe = {
        tip = "Resto M+: Wild Growth on group damage, Rejuv blanketing, Swiftmend urgent targets, Efflorescence down.",
        priorities = {
            { spellID=48438,  name="Wild Growth",       priority=1, why="Group AoE heal — on CD when damage.", tags={"core"} },
            { spellID=774,    name="Rejuvenation",      priority=2, why="Blanket on injured players.", tags={"core"} },
            { spellID=18562,  name="Swiftmend",         priority=3, why="Urgent single-target.", tags={"core"} },
            { spellID=145205, name="Efflorescence",     priority=4, why="Ground HoT — keep under melee.", tags={"core"} },
            { spellID=33891,  name="Incarnation: Tree", priority=nil, isCd=true, isMajorCd=true, why="Burst healing phase.", tags={"cd"} },
        },
    },
    st = {
        tip = "Resto Raid: Rejuv blanketing, Wild Growth on CD, Efflorescence on melee. Flourish to extend.",
        priorities = {
            { spellID=774,    name="Rejuvenation",      priority=1, why="Blanket raid — maintain on 5+ targets.", tags={"core"} },
            { spellID=48438,  name="Wild Growth",       priority=2, why="On CD during damage.", tags={"core"} },
            { spellID=145205, name="Efflorescence",     priority=3, why="Under melee stack.", tags={"core"} },
            { spellID=18562,  name="Swiftmend",         priority=4, why="Emergency ST.", tags={"core"} },
            { spellID=197721, name="Flourish",          priority=nil, isCd=true, isMajorCd=true, why="Extend all HoTs by 8s.", tags={"cd"} },
        },
    },
}

-- ── MAGE ──────────────────────────────────────────────────────────────
R[62] = { -- Arcane
    solo = {
        tip = "Arcane solo: Arcane Blast to 4 charges, Arcane Barrage to dump, Arcane Missiles on Clearcasting. Evocation to reset mana.",
        priorities = {
            { spellID=44425,  name="Arcane Barrage",    priority=1, why="At 4 charges — dump and reset.", tags={"core"} },
            { spellID=5143,   name="Arcane Missiles",   priority=2, why="On Clearcasting proc only — free.", tags={"core"} },
            { spellID=30451,  name="Arcane Blast",      priority=3, why="Charge builder — core filler.", tags={"core"} },
            { spellID=365350, name="Arcane Surge",      priority=nil, isCd=true, isMajorCd=true, why="Burst CD — massive damage + mana restore.", tags={"cd"} },
            { spellID=12051,  name="Evocation",         priority=nil, isCd=true, why="Mana recovery — use when OOM.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Arcane AoE: Arcane Explosion spam, Barrage at 4 charges for AoE cleave.",
        priorities = {
            { spellID=1449,   name="Arcane Explosion",  priority=1, why="PBAoE — primary AoE builder.", tags={"core"} },
            { spellID=44425,  name="Arcane Barrage",    priority=2, why="At 4 charges — AoE cleave dump.", tags={"core"} },
            { spellID=5143,   name="Arcane Missiles",   priority=3, why="Clearcasting procs.", tags={"active"} },
            { spellID=365350, name="Arcane Surge",      priority=nil, isCd=true, isMajorCd=true, why="Burst AoE.", tags={"cd"} },
        },
    },
    st = {
        tip = "Arcane ST: Build to 4 charges, Barrage, Missiles on CC. Arcane Surge + Touch of the Magi for burst.",
        priorities = {
            { spellID=5143,   name="Arcane Missiles",   priority=1, why="Clearcasting — highest priority.", tags={"core"} },
            { spellID=44425,  name="Arcane Barrage",    priority=2, why="At 4 charges.", tags={"core"} },
            { spellID=30451,  name="Arcane Blast",      priority=3, why="Charge builder.", tags={"core"} },
            { spellID=321507, name="Touch of the Magi", priority=nil, isCd=true, why="Damage accumulation bomb.", tags={"cd"} },
            { spellID=365350, name="Arcane Surge",      priority=nil, isCd=true, isMajorCd=true, why="Burst with TotM.", tags={"cd"} },
        },
    },
}
R[63] = { -- Fire
    solo = {
        tip = "Fire solo: Fireball for Hot Streak procs, Pyroblast on Hot Streak (instant). Fire Blast to force crits.",
        priorities = {
            { spellID=11366,  name="Pyroblast",         priority=1, why="On Hot Streak proc — instant cast.", tags={"core"} },
            { spellID=108853, name="Fire Blast",        priority=2, why="Always crits — use to force Hot Streak.", tags={"core"} },
            { spellID=133,    name="Fireball",          priority=3, why="Filler — fishing for crits.", tags={"core"} },
            { spellID=257541, name="Phoenix Flames",    priority=4, why="Guaranteed crit — 3 charges.", tags={"active"} },
            { spellID=190319, name="Combustion",        priority=nil, isCd=true, isMajorCd=true, why="Guaranteed crits — Pyro spam.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Fire AoE: Flamestrike on Hot Streak, Phoenix Flames for AoE crits, Fire Blast to chain Hot Streak.",
        priorities = {
            { spellID=2120,   name="Flamestrike",       priority=1, why="On Hot Streak — AoE version of Pyro.", tags={"core"} },
            { spellID=257541, name="Phoenix Flames",    priority=2, why="AoE guaranteed crit.", tags={"core"} },
            { spellID=108853, name="Fire Blast",        priority=3, why="Chain Hot Streaks.", tags={"core"} },
            { spellID=133,    name="Fireball",          priority=4, why="Filler between procs.", tags={"active"} },
            { spellID=190319, name="Combustion",        priority=nil, isCd=true, isMajorCd=true, why="Guaranteed crits = chain Flamestrikes.", tags={"cd"} },
        },
    },
    st = {
        tip = "Fire ST: Fireball fishing, Fire Blast to force HS, Pyroblast on HS. Combustion for burst.",
        priorities = {
            { spellID=11366,  name="Pyroblast",         priority=1, why="Hot Streak — always instant.", tags={"core"} },
            { spellID=108853, name="Fire Blast",        priority=2, why="Force Hot Streak. Never cap charges.", tags={"core"} },
            { spellID=257541, name="Phoenix Flames",    priority=3, why="Backup crit source.", tags={"core"} },
            { spellID=133,    name="Fireball",          priority=4, why="Filler.", tags={"active"} },
            { spellID=190319, name="Combustion",        priority=nil, isCd=true, isMajorCd=true, why="Pyro spam window.", tags={"cd"} },
        },
    },
}
R[64] = { -- Frost Mage
    solo = {
        tip = "Frost Mage solo: Frostbolt for procs, Ice Lance on Fingers of Frost, Flurry on Brain Freeze. Frozen Orb for AoE.",
        priorities = {
            { spellID=44614,  name="Flurry",            priority=1, why="On Brain Freeze — shatters next Ice Lance.", tags={"core"} },
            { spellID=30455,  name="Ice Lance",         priority=2, why="After Flurry (shatter) or Fingers of Frost.", tags={"core"} },
            { spellID=116,    name="Frostbolt",         priority=3, why="Filler — generates procs.", tags={"core"} },
            { spellID=84714,  name="Frozen Orb",        priority=4, why="AoE + generates Fingers of Frost.", tags={"core"} },
            { spellID=12472,  name="Icy Veins",         priority=nil, isCd=true, isMajorCd=true, why="Haste burst — more procs.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Frost AoE: Frozen Orb, Blizzard, Ice Lance FoF procs. Comet Storm if talented.",
        priorities = {
            { spellID=84714,  name="Frozen Orb",        priority=1, why="AoE + mass FoF procs.", tags={"core"} },
            { spellID=190356, name="Blizzard",          priority=2, why="Ground AoE — slow + damage.", tags={"core"} },
            { spellID=30455,  name="Ice Lance",         priority=3, why="FoF procs from Frozen Orb.", tags={"core"} },
            { spellID=153595, name="Comet Storm",       priority=4, why="If talented — massive AoE burst.", tags={"active"} },
            { spellID=12472,  name="Icy Veins",         priority=nil, isCd=true, isMajorCd=true, why="Pop with Orb for max AoE.", tags={"cd"} },
        },
    },
    st = {
        tip = "Frost ST: Flurry on Brain Freeze → Ice Lance (shatter combo). Frostbolt filler. Icy Veins for burst.",
        priorities = {
            { spellID=44614,  name="Flurry",            priority=1, why="Brain Freeze → immediate Ice Lance.", tags={"core"} },
            { spellID=30455,  name="Ice Lance",         priority=2, why="After Flurry or on FoF.", tags={"core"} },
            { spellID=116,    name="Frostbolt",         priority=3, why="Filler.", tags={"core"} },
            { spellID=84714,  name="Frozen Orb",        priority=4, why="On CD for FoF gen.", tags={"active"} },
            { spellID=12472,  name="Icy Veins",         priority=nil, isCd=true, isMajorCd=true, why="Burst.", tags={"cd"} },
        },
    },
}

-- ── PRIEST ────────────────────────────────────────────────────────────
R[256] = { -- Discipline
    solo = {
        tip = "Disc solo: Smite for damage (heals via Atonement), SW:Pain DoT, Penance offensively. Shield when hurt.",
        priorities = {
            { spellID=585,    name="Smite",             priority=1, why="Damage filler — heals via Atonement.", tags={"core"} },
            { spellID=589,    name="Shadow Word: Pain", priority=2, why="Maintain DoT.", tags={"core"} },
            { spellID=47540,  name="Penance",           priority=3, why="Offensive on CD — damage + Atonement heal.", tags={"core"} },
            { spellID=17,     name="Power Word: Shield", priority=4, why="When taking damage.", tags={"defensive"} },
            { spellID=34433,  name="Shadowfiend",       priority=nil, isCd=true, isMajorCd=true, why="Damage + mana return.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Disc M+: Radiance for AoE Atonement, then Penance/Smite to heal group through damage.",
        priorities = {
            { spellID=194509, name="Power Word: Radiance", priority=1, why="AoE Atonement application.", tags={"core"} },
            { spellID=47540,  name="Penance",           priority=2, why="Highest Atonement throughput.", tags={"core"} },
            { spellID=585,    name="Smite",             priority=3, why="Sustained Atonement heals.", tags={"core"} },
            { spellID=589,    name="Shadow Word: Pain", priority=4, why="DoT for passive Atonement.", tags={"active"} },
            { spellID=62618,  name="Power Word: Barrier", priority=nil, isCd=true, isMajorCd=true, why="25% DR zone for party.", tags={"cd"} },
        },
    },
    st = {
        tip = "Disc Raid: pre-Atonement with Shield/Radiance, then burst damage through Schism/Penance.",
        priorities = {
            { spellID=194509, name="Power Word: Radiance", priority=1, why="Apply Atonement to group.", tags={"core"} },
            { spellID=47540,  name="Penance",           priority=2, why="Highest throughput per GCD.", tags={"core"} },
            { spellID=585,    name="Smite",             priority=3, why="Filler damage → heals.", tags={"core"} },
            { spellID=17,     name="Power Word: Shield", priority=4, why="Tank maintenance.", tags={"active"} },
            { spellID=246287, name="Evangelism",        priority=nil, isCd=true, isMajorCd=true, why="Extend Atonements before burst.", tags={"cd"} },
        },
    },
}
R[257] = { -- Holy Priest
    solo = {
        tip = "Holy Priest solo: Smite for damage, Holy Fire on CD, SW:Pain DoT. Flash Heal when hurt.",
        priorities = {
            { spellID=14914,  name="Holy Fire",         priority=1, why="DoT + instant. On CD.", tags={"core"} },
            { spellID=589,    name="Shadow Word: Pain", priority=2, why="Maintain DoT.", tags={"core"} },
            { spellID=585,    name="Smite",             priority=3, why="Filler nuke.", tags={"core"} },
            { spellID=2061,   name="Flash Heal",        priority=4, why="Self-heal when needed.", tags={"active"} },
            { spellID=200183, name="Apotheosis",        priority=nil, isCd=true, isMajorCd=true, why="Holy Word CDR burst.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Holy M+: Prayer of Mending, Circle of Healing, Holy Word: Sanctify. Flash Heal urgent targets.",
        priorities = {
            { spellID=34861,  name="Holy Word: Sanctify", priority=1, why="AoE instant heal — on CD.", tags={"core"} },
            { spellID=204883, name="Circle of Healing", priority=2, why="Smart AoE heal.", tags={"core"} },
            { spellID=33076,  name="Prayer of Mending", priority=3, why="Bouncing heal — always active.", tags={"core"} },
            { spellID=2061,   name="Flash Heal",        priority=4, why="Urgent single target.", tags={"active"} },
            { spellID=64843,  name="Divine Hymn",       priority=nil, isCd=true, isMajorCd=true, why="Channel raid heal.", tags={"cd"} },
        },
    },
    st = {
        tip = "Holy Raid: maintain Prayer of Mending, Sanctify on CD, Heal for mana efficiency.",
        priorities = {
            { spellID=33076,  name="Prayer of Mending", priority=1, why="Always bouncing.", tags={"core"} },
            { spellID=34861,  name="Holy Word: Sanctify", priority=2, why="AoE heal on CD.", tags={"core"} },
            { spellID=2060,   name="Heal",              priority=3, why="Mana-efficient filler.", tags={"core"} },
            { spellID=2061,   name="Flash Heal",        priority=4, why="Urgent only (expensive).", tags={"active"} },
            { spellID=64843,  name="Divine Hymn",       priority=nil, isCd=true, isMajorCd=true, why="Raid CD.", tags={"cd"} },
        },
    },
}
R[258] = { -- Shadow
    solo = {
        tip = "Shadow solo: SW:Pain + Vampiric Touch DoTs, Mind Blast on CD, Devouring Plague at 50 Insanity. Mind Flay filler.",
        priorities = {
            { spellID=589,    name="Shadow Word: Pain", priority=1, why="Maintain DoT.", tags={"core"} },
            { spellID=34914,  name="Vampiric Touch",    priority=2, why="Maintain DoT — self-heal.", tags={"core"} },
            { spellID=8092,   name="Mind Blast",        priority=3, why="Insanity gen + big hit. On CD.", tags={"core"} },
            { spellID=335467, name="Devouring Plague",  priority=4, why="At 50 Insanity — primary spender.", tags={"core"} },
            { spellID=15407,  name="Mind Flay",         priority=5, why="Filler channel.", tags={"active"} },
            { spellID=228260, name="Void Eruption",     priority=nil, isCd=true, isMajorCd=true, why="Enter Voidform for burst.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Shadow AoE: Multi-DoT SW:Pain/VT, Mind Sear filler, Devouring Plague on highest HP.",
        priorities = {
            { spellID=589,    name="Shadow Word: Pain", priority=1, why="Spread to all targets.", tags={"core"} },
            { spellID=34914,  name="Vampiric Touch",    priority=2, why="Spread to 3-4 targets.", tags={"core"} },
            { spellID=335467, name="Devouring Plague",  priority=3, why="Highest HP target.", tags={"core"} },
            { spellID=8092,   name="Mind Blast",        priority=4, why="Insanity gen.", tags={"active"} },
            { spellID=48045,  name="Mind Sear",         priority=5, why="AoE filler channel.", tags={"active"} },
        },
    },
    st = {
        tip = "Shadow ST: DoTs up, Mind Blast on CD, Devouring Plague at 50+, Mind Flay filler. Voidform for burst.",
        priorities = {
            { spellID=34914,  name="Vampiric Touch",    priority=1, why="Maintain.", tags={"core"} },
            { spellID=589,    name="Shadow Word: Pain", priority=2, why="Maintain.", tags={"core"} },
            { spellID=8092,   name="Mind Blast",        priority=3, why="On CD — Insanity gen.", tags={"core"} },
            { spellID=335467, name="Devouring Plague",  priority=4, why="At 50 Insanity.", tags={"core"} },
            { spellID=15407,  name="Mind Flay",         priority=5, why="Filler.", tags={"active"} },
            { spellID=228260, name="Void Eruption",     priority=nil, isCd=true, isMajorCd=true, why="Burst phase.", tags={"cd"} },
        },
    },
}

-- ── ROGUE ─────────────────────────────────────────────────────────────
R[259] = { -- Assassination
    solo = {
        tip = "Assa solo: Garrote from stealth, Mutilate to 5 CP, Rupture to maintain, Envenom at 5 CP.",
        priorities = {
            { spellID=703,    name="Garrote",           priority=1, why="Maintain bleed — empowered from stealth.", tags={"core"} },
            { spellID=1329,   name="Mutilate",          priority=2, why="CP generator.", tags={"core"} },
            { spellID=1943,   name="Rupture",           priority=3, why="At 5 CP — maintain bleed always.", tags={"core"} },
            { spellID=32645,  name="Envenom",           priority=4, why="At 5 CP with Rupture up.", tags={"core"} },
            { spellID=79140,  name="Vendetta",          priority=nil, isCd=true, isMajorCd=true, why="30% more damage on target.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Assa AoE: Fan of Knives to 5 CP, Crimson Tempest, maintain Garrote on 2-3 targets.",
        priorities = {
            { spellID=51723,  name="Fan of Knives",     priority=1, why="AoE CP gen.", tags={"core"} },
            { spellID=121411, name="Crimson Tempest",   priority=2, why="At 5 CP — AoE bleed.", tags={"core"} },
            { spellID=703,    name="Garrote",           priority=3, why="On 2-3 priority targets.", tags={"active"} },
            { spellID=1943,   name="Rupture",           priority=4, why="On high-HP targets.", tags={"active"} },
        },
    },
    st = {
        tip = "Assa ST: Garrote + Rupture uptime, Mutilate to 5, Envenom spam. Vendetta on CD.",
        priorities = {
            { spellID=703,    name="Garrote",           priority=1, why="Maintain.", tags={"core"} },
            { spellID=1943,   name="Rupture",           priority=2, why="At 5 CP. Maintain.", tags={"core"} },
            { spellID=1329,   name="Mutilate",          priority=3, why="CP gen.", tags={"core"} },
            { spellID=32645,  name="Envenom",           priority=4, why="At 5 CP dump.", tags={"core"} },
            { spellID=79140,  name="Vendetta",          priority=nil, isCd=true, isMajorCd=true, why="Burst on CD.", tags={"cd"} },
        },
    },
}
R[260] = { -- Outlaw
    solo = {
        tip = "Outlaw solo: Sinister Strike to 5 CP, Dispatch finisher, Roll the Bones buff, Between the Eyes for big hits.",
        priorities = {
            { spellID=315496, name="Slice and Dice",    priority=1, why="Maintain attack speed buff at 5 CP.", tags={"core"} },
            { spellID=193315, name="Dispatch",          priority=2, why="At 5+ CP — primary finisher.", tags={"core"} },
            { spellID=193316, name="Roll the Bones",    priority=3, why="Maintain buff — reroll 1-buffs.", tags={"core"} },
            { spellID=1752,   name="Sinister Strike",   priority=4, why="CP generator.", tags={"active"} },
            { spellID=315341, name="Between the Eyes",  priority=5, why="Big crit finisher.", tags={"active"} },
            { spellID=13750,  name="Adrenaline Rush",   priority=nil, isCd=true, isMajorCd=true, why="Energy + GCD speed.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Outlaw AoE: Blade Flurry, then normal rotation — all hits cleave.",
        priorities = {
            { spellID=13877,  name="Blade Flurry",      priority=1, why="Enable cleave — all hits splash.", tags={"core"} },
            { spellID=193315, name="Dispatch",          priority=2, why="At 5 CP — cleaved.", tags={"core"} },
            { spellID=1752,   name="Sinister Strike",   priority=3, why="CP gen — cleaved.", tags={"core"} },
            { spellID=193316, name="Roll the Bones",    priority=4, why="Maintain buffs.", tags={"active"} },
            { spellID=13750,  name="Adrenaline Rush",   priority=nil, isCd=true, isMajorCd=true, why="Burst cleave.", tags={"cd"} },
        },
    },
    st = {
        tip = "Outlaw ST: SnD uptime, Dispatch at 5 CP, RtB maintenance, SS filler. AR on CD.",
        priorities = {
            { spellID=315496, name="Slice and Dice",    priority=1, why="Maintain always.", tags={"core"} },
            { spellID=193315, name="Dispatch",          priority=2, why="At 5+ CP.", tags={"core"} },
            { spellID=193316, name="Roll the Bones",    priority=3, why="Maintain 2+ buff.", tags={"core"} },
            { spellID=315341, name="Between the Eyes",  priority=4, why="On CD for crit buff.", tags={"active"} },
            { spellID=1752,   name="Sinister Strike",   priority=5, why="Filler.", tags={"active"} },
            { spellID=13750,  name="Adrenaline Rush",   priority=nil, isCd=true, isMajorCd=true, why="Burst.", tags={"cd"} },
        },
    },
}
R[261] = { -- Subtlety
    solo = {
        tip = "Sub solo: Shadow Dance → Shadowstrike for CP, Eviscerate at 5 CP. Backstab outside Dance. Symbols of Death on CD.",
        priorities = {
            { spellID=185438, name="Shadowstrike",      priority=1, why="During Shadow Dance — huge CP gen from stealth.", tags={"core"} },
            { spellID=196819, name="Eviscerate",        priority=2, why="At 5+ CP — primary finisher.", tags={"core"} },
            { spellID=53,     name="Backstab",          priority=3, why="CP gen outside Dance.", tags={"core"} },
            { spellID=185313, name="Shadow Dance",      priority=4, why="Enter stealth for Shadowstrike.", tags={"core"} },
            { spellID=212283, name="Symbols of Death",  priority=nil, isCd=true, why="10% damage buff. On CD.", tags={"cd"} },
            { spellID=121471, name="Shadow Blades",     priority=nil, isCd=true, isMajorCd=true, why="Major burst — extra CP gen.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Sub AoE: Shuriken Storm for AoE CP, Black Powder at 5 CP, Shadow Dance for Shuriken Tornado.",
        priorities = {
            { spellID=197835, name="Shuriken Storm",    priority=1, why="AoE CP gen.", tags={"core"} },
            { spellID=319175, name="Black Powder",      priority=2, why="At 5 CP — AoE finisher.", tags={"core"} },
            { spellID=185313, name="Shadow Dance",      priority=3, why="Empower abilities.", tags={"core"} },
            { spellID=185438, name="Shadowstrike",      priority=4, why="During Dance for extra CP.", tags={"active"} },
            { spellID=121471, name="Shadow Blades",     priority=nil, isCd=true, isMajorCd=true, why="AoE burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "Sub ST: Shadow Dance > Shadowstrike to 5 CP > Eviscerate. Symbols on CD. Backstab outside Dance.",
        priorities = {
            { spellID=185438, name="Shadowstrike",      priority=1, why="During Dance.", tags={"core"} },
            { spellID=196819, name="Eviscerate",        priority=2, why="At 5 CP.", tags={"core"} },
            { spellID=53,     name="Backstab",          priority=3, why="Outside Dance.", tags={"core"} },
            { spellID=185313, name="Shadow Dance",      priority=4, why="On CD.", tags={"core"} },
            { spellID=212283, name="Symbols of Death",  priority=nil, isCd=true, why="On CD.", tags={"cd"} },
            { spellID=121471, name="Shadow Blades",     priority=nil, isCd=true, isMajorCd=true, why="Burst.", tags={"cd"} },
        },
    },
}

-- ── MONK ──────────────────────────────────────────────────────────────
R[268] = { -- Brewmaster
    solo = {
        tip = "Brew solo: Keg Smash on CD, Blackout Kick, Tiger Palm filler. Purifying Brew at high Stagger. Pull big.",
        priorities = {
            { spellID=121253, name="Keg Smash",         priority=1, why="AoE + brew CDR + slow. On CD.", tags={"core"} },
            { spellID=205523, name="Blackout Kick",     priority=2, why="Primary melee + brew CDR.", tags={"core"} },
            { spellID=100784, name="Tiger Palm",        priority=3, why="Filler — energy dump.", tags={"active"} },
            { spellID=119582, name="Purifying Brew",    priority=4, why="Clear Stagger (yellow/red).", tags={"defensive"} },
            { spellID=322507, name="Celestial Brew",    priority=5, why="Absorb shield — on CD.", tags={"defensive"} },
            { spellID=115203, name="Fortifying Brew",   priority=nil, isCd=true, isMajorCd=true, why="Emergency — 20% DR.", tags={"defensive"} },
        },
    },
    aoe = {
        tip = "Brew AoE: Keg Smash, Breath of Fire, Spinning Crane Kick. Purify at high Stagger.",
        priorities = {
            { spellID=121253, name="Keg Smash",         priority=1, why="AoE threat + CDR.", tags={"core"} },
            { spellID=115181, name="Breath of Fire",    priority=2, why="Cone AoE DoT.", tags={"core"} },
            { spellID=101546, name="Spinning Crane Kick", priority=3, why="PBAoE filler.", tags={"core"} },
            { spellID=205523, name="Blackout Kick",     priority=4, why="CDR on brews.", tags={"active"} },
            { spellID=119582, name="Purifying Brew",    priority=5, why="Clear Stagger.", tags={"defensive"} },
        },
    },
    st = {
        tip = "Brew ST: Keg Smash > Blackout Kick > Tiger Palm. Purify at medium+ Stagger.",
        priorities = {
            { spellID=121253, name="Keg Smash",         priority=1, why="On CD.", tags={"core"} },
            { spellID=205523, name="Blackout Kick",     priority=2, why="CDR + damage.", tags={"core"} },
            { spellID=100784, name="Tiger Palm",        priority=3, why="Filler.", tags={"active"} },
            { spellID=119582, name="Purifying Brew",    priority=4, why="Clear Stagger.", tags={"defensive"} },
            { spellID=322507, name="Celestial Brew",    priority=5, why="Absorb.", tags={"defensive"} },
        },
    },
}
R[269] = { -- Windwalker
    solo = {
        tip = "WW solo: Never repeat abilities. Tiger Palm → Blackout Kick → Rising Sun Kick → Fists of Fury. Combo Strikes mastery.",
        priorities = {
            { spellID=107428, name="Rising Sun Kick",   priority=1, why="Hardest hit. On CD.", tags={"core"} },
            { spellID=113656, name="Fists of Fury",     priority=2, why="Channel — massive ST+AoE.", tags={"core"} },
            { spellID=100784, name="Blackout Kick",     priority=3, why="Chi spender — alternate with TP.", tags={"core"} },
            { spellID=100780, name="Tiger Palm",        priority=4, why="Chi gen — alternate with BoK.", tags={"core"} },
            { spellID=101546, name="Spinning Crane Kick", priority=5, why="3+ targets.", tags={"aoe"} },
            { spellID=137639, name="Storm, Earth, Fire", priority=nil, isCd=true, isMajorCd=true, why="Clone burst — splits damage.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "WW AoE: Spinning Crane Kick at 3+, Fists of Fury, RSK. Mark of the Crane stacking.",
        priorities = {
            { spellID=101546, name="Spinning Crane Kick", priority=1, why="Primary AoE at Mark stacks.", tags={"core"} },
            { spellID=113656, name="Fists of Fury",     priority=2, why="AoE channel.", tags={"core"} },
            { spellID=107428, name="Rising Sun Kick",   priority=3, why="Still use for Mastery rotation.", tags={"core"} },
            { spellID=100780, name="Tiger Palm",        priority=4, why="Chi gen between SCK.", tags={"active"} },
            { spellID=137639, name="Storm, Earth, Fire", priority=nil, isCd=true, isMajorCd=true, why="AoE burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "WW ST: RSK > FoF > BoK > TP. Never repeat same ability (Combo Strikes mastery). SEF for burst.",
        priorities = {
            { spellID=107428, name="Rising Sun Kick",   priority=1, why="Highest priority always.", tags={"core"} },
            { spellID=113656, name="Fists of Fury",     priority=2, why="On CD — channel.", tags={"core"} },
            { spellID=100784, name="Blackout Kick",     priority=3, why="Chi spender.", tags={"core"} },
            { spellID=100780, name="Tiger Palm",        priority=4, why="Chi gen.", tags={"active"} },
            { spellID=137639, name="Storm, Earth, Fire", priority=nil, isCd=true, isMajorCd=true, why="Burst window.", tags={"cd"} },
        },
    },
}
R[270] = { -- Mistweaver
    solo = {
        tip = "MW solo: Tiger Palm + Blackout Kick (fistweaving), Rising Sun Kick on CD. Vivify when hurt.",
        priorities = {
            { spellID=107428, name="Rising Sun Kick",   priority=1, why="Damage + heals via Ancient Teachings.", tags={"core"} },
            { spellID=100784, name="Blackout Kick",     priority=2, why="Melee damage + triggers healing.", tags={"core"} },
            { spellID=100780, name="Tiger Palm",        priority=3, why="Filler + CDR on RSK.", tags={"active"} },
            { spellID=116670, name="Vivify",            priority=4, why="Direct heal when below 50%.", tags={"core"} },
            { spellID=115310, name="Revival",           priority=nil, isCd=true, isMajorCd=true, why="Emergency full heal.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "MW M+: Renewing Mist on CD, Vivify for cleave, RSK + BoK for fistweaving throughput.",
        priorities = {
            { spellID=115151, name="Renewing Mist",     priority=1, why="On CD — enables Vivify cleave.", tags={"core"} },
            { spellID=116670, name="Vivify",            priority=2, why="Heals target + all ReM targets.", tags={"core"} },
            { spellID=107428, name="Rising Sun Kick",   priority=3, why="Fistweave damage → healing.", tags={"core"} },
            { spellID=100784, name="Blackout Kick",     priority=4, why="Fistweave filler.", tags={"active"} },
            { spellID=115310, name="Revival",           priority=nil, isCd=true, isMajorCd=true, why="Emergency AoE heal.", tags={"cd"} },
        },
    },
    st = {
        tip = "MW Raid: Renewing Mist blanket, Vivify spam, Enveloping Mist on tank. Thunder Focus Tea for efficiency.",
        priorities = {
            { spellID=115151, name="Renewing Mist",     priority=1, why="On CD always.", tags={"core"} },
            { spellID=116670, name="Vivify",            priority=2, why="Primary heal.", tags={"core"} },
            { spellID=124682, name="Enveloping Mist",   priority=3, why="Tank HoT + heal buff.", tags={"core"} },
            { spellID=116680, name="Thunder Focus Tea", priority=4, why="Empowers next heal.", tags={"active"} },
            { spellID=115310, name="Revival",           priority=nil, isCd=true, isMajorCd=true, why="Raid emergency.", tags={"cd"} },
        },
    },
}

-- ── SHAMAN ────────────────────────────────────────────────────────────
R[262] = { -- Elemental
    solo = {
        tip = "Ele solo: Flame Shock DoT, Lava Burst on CD (always crits with FS), Lightning Bolt filler, Earth Shock at 60 Maelstrom.",
        priorities = {
            { spellID=188389, name="Flame Shock",       priority=1, why="Maintain DoT — enables Lava Burst crits.", tags={"core"} },
            { spellID=51505,  name="Lava Burst",        priority=2, why="Always crits with FS up. On CD.", tags={"core"} },
            { spellID=8042,   name="Earth Shock",       priority=3, why="At 60+ Maelstrom — primary spender.", tags={"core"} },
            { spellID=188196, name="Lightning Bolt",    priority=4, why="Filler — Maelstrom gen.", tags={"active"} },
            { spellID=191634, name="Stormkeeper",       priority=nil, isCd=true, isMajorCd=true, why="Empowers next 2 LB/CL.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Ele AoE: Flame Shock spread, Chain Lightning filler, Earthquake at 60 Maelstrom. Stormkeeper for burst.",
        priorities = {
            { spellID=188389, name="Flame Shock",       priority=1, why="On 2-3 targets for LvB resets.", tags={"core"} },
            { spellID=61882,  name="Earthquake",        priority=2, why="At 60 Maelstrom — AoE ground.", tags={"core"} },
            { spellID=188443, name="Chain Lightning",   priority=3, why="AoE Maelstrom gen.", tags={"core"} },
            { spellID=51505,  name="Lava Burst",        priority=4, why="Procs from multi-FS.", tags={"active"} },
            { spellID=191634, name="Stormkeeper",       priority=nil, isCd=true, isMajorCd=true, why="Empowered CL.", tags={"cd"} },
        },
    },
    st = {
        tip = "Ele ST: FS up, LvB on CD, ES at 60+ MS, LB filler. Stormkeeper empowered LBs for burst.",
        priorities = {
            { spellID=188389, name="Flame Shock",       priority=1, why="Maintain.", tags={"core"} },
            { spellID=51505,  name="Lava Burst",        priority=2, why="On CD — guaranteed crit.", tags={"core"} },
            { spellID=8042,   name="Earth Shock",       priority=3, why="At 60+ Maelstrom.", tags={"core"} },
            { spellID=188196, name="Lightning Bolt",    priority=4, why="Filler.", tags={"active"} },
            { spellID=191634, name="Stormkeeper",       priority=nil, isCd=true, isMajorCd=true, why="Burst.", tags={"cd"} },
        },
    },
}
R[263] = { -- Enhancement
    solo = {
        tip = "Enh solo: Stormstrike on CD, Lava Lash filler, Flame Shock DoT. Lightning Bolt at 5+ Maelstrom Weapon stacks.",
        priorities = {
            { spellID=17364,  name="Stormstrike",       priority=1, why="Primary melee hit. On CD.", tags={"core"} },
            { spellID=60103,  name="Lava Lash",         priority=2, why="Secondary melee — spreads Flame Shock.", tags={"core"} },
            { spellID=188389, name="Flame Shock",       priority=3, why="Maintain DoT.", tags={"core"} },
            { spellID=188196, name="Lightning Bolt",    priority=4, why="At 5+ Maelstrom Weapon stacks — instant.", tags={"core"} },
            { spellID=51533,  name="Feral Spirit",      priority=nil, isCd=true, isMajorCd=true, why="Wolf summons — massive burst.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Enh AoE: Crash Lightning for AoE buff, then Stormstrike/Lava Lash cleave. Chain Lightning at 5 MW.",
        priorities = {
            { spellID=187874, name="Crash Lightning",   priority=1, why="AoE + enables SS/LL cleave.", tags={"core"} },
            { spellID=17364,  name="Stormstrike",       priority=2, why="Cleaves after Crash.", tags={"core"} },
            { spellID=60103,  name="Lava Lash",         priority=3, why="Cleaves + FS spread.", tags={"core"} },
            { spellID=188443, name="Chain Lightning",   priority=4, why="At 5+ MW — instant AoE.", tags={"active"} },
            { spellID=51533,  name="Feral Spirit",      priority=nil, isCd=true, isMajorCd=true, why="AoE burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "Enh ST: Stormstrike priority, Lava Lash, FS maintenance, LB at 5 MW. Feral Spirit on CD.",
        priorities = {
            { spellID=17364,  name="Stormstrike",       priority=1, why="Highest priority always.", tags={"core"} },
            { spellID=60103,  name="Lava Lash",         priority=2, why="Filler melee.", tags={"core"} },
            { spellID=188389, name="Flame Shock",       priority=3, why="Maintain.", tags={"core"} },
            { spellID=188196, name="Lightning Bolt",    priority=4, why="5+ MW stacks.", tags={"core"} },
            { spellID=51533,  name="Feral Spirit",      priority=nil, isCd=true, isMajorCd=true, why="Burst.", tags={"cd"} },
        },
    },
}
R[264] = { -- Restoration Shaman
    solo = {
        tip = "Resto Shaman solo: Lightning Bolt damage, Flame Shock DoT, Lava Burst on CD. Healing Surge when hurt.",
        priorities = {
            { spellID=188389, name="Flame Shock",       priority=1, why="Maintain DoT for LvB crits.", tags={"core"} },
            { spellID=51505,  name="Lava Burst",        priority=2, why="Guaranteed crit with FS.", tags={"core"} },
            { spellID=188196, name="Lightning Bolt",    priority=3, why="Filler damage.", tags={"active"} },
            { spellID=8004,   name="Healing Surge",     priority=4, why="Self-heal when below 60%.", tags={"core"} },
            { spellID=5394,   name="Healing Stream Totem", priority=5, why="Passive heal on CD.", tags={"active"} },
        },
    },
    aoe = {
        tip = "Resto M+: Healing Rain, Riptide on CD, Healing Wave/Surge. Chain Heal for stacked group.",
        priorities = {
            { spellID=73920,  name="Healing Rain",      priority=1, why="Ground AoE HoT — keep down.", tags={"core"} },
            { spellID=61295,  name="Riptide",           priority=2, why="On CD — HoT + instant heal.", tags={"core"} },
            { spellID=1064,   name="Chain Heal",        priority=3, why="Stacked group healing.", tags={"core"} },
            { spellID=8004,   name="Healing Surge",     priority=4, why="Urgent single target.", tags={"active"} },
            { spellID=108280, name="Healing Tide Totem", priority=nil, isCd=true, isMajorCd=true, why="Raid CD.", tags={"cd"} },
        },
    },
    st = {
        tip = "Resto Raid: Riptide on tanks, Healing Rain under melee, Chain Heal for stacked. HTT for emergencies.",
        priorities = {
            { spellID=61295,  name="Riptide",           priority=1, why="Maintain on tanks + injured.", tags={"core"} },
            { spellID=73920,  name="Healing Rain",      priority=2, why="Under melee stack.", tags={"core"} },
            { spellID=77472,  name="Healing Wave",      priority=3, why="Mana-efficient filler.", tags={"core"} },
            { spellID=1064,   name="Chain Heal",        priority=4, why="Stacked damage.", tags={"active"} },
            { spellID=108280, name="Healing Tide Totem", priority=nil, isCd=true, isMajorCd=true, why="Major raid CD.", tags={"cd"} },
        },
    },
}

-- ── WARLOCK ───────────────────────────────────────────────────────────
R[265] = { -- Affliction
    solo = {
        tip = "Aff solo: Agony + Corruption + UA DoTs, Drain Life filler (heals you). Malefic Rapture to burst DoTs down.",
        priorities = {
            { spellID=980,    name="Agony",             priority=1, why="Maintain — ramps over time.", tags={"core"} },
            { spellID=172,    name="Corruption",        priority=2, why="Maintain DoT.", tags={"core"} },
            { spellID=316099, name="Unstable Affliction", priority=3, why="Maintain — enables Malefic Rapture.", tags={"core"} },
            { spellID=324536, name="Malefic Rapture",   priority=4, why="Primary spender — bursts all DoTs.", tags={"core"} },
            { spellID=234153, name="Drain Life",        priority=5, why="Filler + self-heal.", tags={"active"} },
            { spellID=205180, name="Summon Darkglare",  priority=nil, isCd=true, isMajorCd=true, why="Extends all DoTs + burst.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Aff AoE: Spread Agony to all, Corruption via Seed, UA on 2-3, Malefic Rapture spam.",
        priorities = {
            { spellID=980,    name="Agony",             priority=1, why="On all targets — ramps.", tags={"core"} },
            { spellID=27243,  name="Seed of Corruption", priority=2, why="AoE Corruption spread.", tags={"core"} },
            { spellID=316099, name="Unstable Affliction", priority=3, why="On priority targets.", tags={"core"} },
            { spellID=324536, name="Malefic Rapture",   priority=4, why="Burst all DoTs.", tags={"core"} },
            { spellID=205180, name="Summon Darkglare",  priority=nil, isCd=true, isMajorCd=true, why="Extends + burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "Aff ST: All 3 DoTs up, Malefic Rapture dump, Drain Life filler. Darkglare with all DoTs fresh.",
        priorities = {
            { spellID=980,    name="Agony",             priority=1, why="Maintain.", tags={"core"} },
            { spellID=172,    name="Corruption",        priority=2, why="Maintain.", tags={"core"} },
            { spellID=316099, name="Unstable Affliction", priority=3, why="Maintain.", tags={"core"} },
            { spellID=324536, name="Malefic Rapture",   priority=4, why="Shards dump.", tags={"core"} },
            { spellID=234153, name="Drain Life",        priority=5, why="Filler.", tags={"active"} },
            { spellID=205180, name="Summon Darkglare",  priority=nil, isCd=true, isMajorCd=true, why="With fresh DoTs.", tags={"cd"} },
        },
    },
}
R[266] = { -- Demonology
    solo = {
        tip = "Demo solo: Hand of Gul'dan at 3+ shards, Call Dreadstalkers on CD, Demonbolt with procs, Shadow Bolt filler.",
        priorities = {
            { spellID=105174, name="Hand of Gul'dan",   priority=1, why="At 3+ Soul Shards — summons imps.", tags={"core"} },
            { spellID=104316, name="Call Dreadstalkers", priority=2, why="On CD — strong summon.", tags={"core"} },
            { spellID=264178, name="Demonbolt",         priority=3, why="On Demonic Core proc — instant.", tags={"core"} },
            { spellID=686,    name="Shadow Bolt",       priority=4, why="Filler — shard gen.", tags={"active"} },
            { spellID=265187, name="Summon Demonic Tyrant", priority=nil, isCd=true, isMajorCd=true, why="Extends all demons + burst.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Demo AoE: Hand of Gul'dan for imps, Implosion to detonate them, Dreadstalkers, Demonbolt procs.",
        priorities = {
            { spellID=105174, name="Hand of Gul'dan",   priority=1, why="Summon imps for Implosion.", tags={"core"} },
            { spellID=196277, name="Implosion",         priority=2, why="Detonate imps for AoE.", tags={"core"} },
            { spellID=104316, name="Call Dreadstalkers", priority=3, why="On CD.", tags={"core"} },
            { spellID=264178, name="Demonbolt",         priority=4, why="Demonic Core procs.", tags={"active"} },
            { spellID=686,    name="Shadow Bolt",       priority=5, why="Filler.", tags={"active"} },
        },
    },
    st = {
        tip = "Demo ST: Dreadstalkers on CD, Hand of Gul'dan at 3, Demonbolt on procs, Shadow Bolt filler. Tyrant with max demons.",
        priorities = {
            { spellID=104316, name="Call Dreadstalkers", priority=1, why="On CD.", tags={"core"} },
            { spellID=105174, name="Hand of Gul'dan",   priority=2, why="At 3 shards.", tags={"core"} },
            { spellID=264178, name="Demonbolt",         priority=3, why="Demonic Core procs.", tags={"core"} },
            { spellID=686,    name="Shadow Bolt",       priority=4, why="Filler.", tags={"active"} },
            { spellID=265187, name="Summon Demonic Tyrant", priority=nil, isCd=true, isMajorCd=true, why="With max demons out.", tags={"cd"} },
        },
    },
}
R[267] = { -- Destruction
    solo = {
        tip = "Destro solo: Immolate DoT, Chaos Bolt at 2+ shards, Conflagrate for shards, Incinerate filler.",
        priorities = {
            { spellID=348,    name="Immolate",          priority=1, why="Maintain DoT — shard gen over time.", tags={"core"} },
            { spellID=116858, name="Chaos Bolt",        priority=2, why="At 2+ shards — big nuke.", tags={"core"} },
            { spellID=17962,  name="Conflagrate",       priority=3, why="Instant shard gen. 2 charges.", tags={"core"} },
            { spellID=29722,  name="Incinerate",        priority=4, why="Filler — shard gen.", tags={"active"} },
            { spellID=1122,   name="Summon Infernal",   priority=nil, isCd=true, isMajorCd=true, why="AoE + haste buff.", tags={"cd"} },
        },
    },
    aoe = {
        tip = "Destro AoE: Rain of Fire at 3 shards, Immolate spread, Conflagrate, Incinerate filler. Infernal on big packs.",
        priorities = {
            { spellID=5740,   name="Rain of Fire",      priority=1, why="At 3 shards — sustained AoE.", tags={"core"} },
            { spellID=348,    name="Immolate",          priority=2, why="Spread to 3-4 targets.", tags={"core"} },
            { spellID=17962,  name="Conflagrate",       priority=3, why="Shard gen.", tags={"core"} },
            { spellID=29722,  name="Incinerate",        priority=4, why="Filler.", tags={"active"} },
            { spellID=1122,   name="Summon Infernal",   priority=nil, isCd=true, isMajorCd=true, why="Massive AoE burst.", tags={"cd"} },
        },
    },
    st = {
        tip = "Destro ST: Immolate up, Chaos Bolt at 2+ shards, Conflagrate charges, Incinerate filler.",
        priorities = {
            { spellID=348,    name="Immolate",          priority=1, why="Maintain.", tags={"core"} },
            { spellID=116858, name="Chaos Bolt",        priority=2, why="Primary nuke at 2+ shards.", tags={"core"} },
            { spellID=17962,  name="Conflagrate",       priority=3, why="Shard gen. Don't cap charges.", tags={"core"} },
            { spellID=29722,  name="Incinerate",        priority=4, why="Filler.", tags={"active"} },
            { spellID=1122,   name="Summon Infernal",   priority=nil, isCd=true, isMajorCd=true, why="Burst on CD.", tags={"cd"} },
        },
    },
}

-- ── Generic fallback for unimplemented specs ───────────────────────────
R.fallback = {
    solo = { tip="Rotation data for this spec coming soon. Use Icy Veins or Method for current guidance.", priorities={} },
    aoe  = { tip="Rotation data for this spec coming soon.", priorities={} },
    st   = { tip="Rotation data for this spec coming soon.", priorities={} },
}

-- ── Lookup helper ──────────────────────────────────────────────────────
function R:Get(specID, view)
    local spec = self[specID] or self.fallback
    return spec[view] or spec.solo or {}
end
