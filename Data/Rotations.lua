-- ToonAge/Data/Rotations.lua
-- Rotation priority data per spec (Midnight 12.0.5)
-- SpellIDs are Midnight build IDs — verify with GetSpellInfo() in-game

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Rotations = {}
local R = TA.Data.Rotations

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
            { spellID=355913, name="Emerald Blossom",   priority=4, why="On cooldown. Instant AoE heal — use below 70% health.", condition="On cooldown", tags={"core"} },
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
            { spellID=257284, name="Hunter's Mark",        priority=1,  why="+3% damage to target — apply before every pull, always maintain.",         tags={"core"} },
            { spellID=nil,    name="Takedown",             priority=2,  why="Primary cooldown — charges to target, grants +20% damage for 8s. Open every pull.", tags={"core","cd"}, isCd=true },
            { spellID=269752, name="Wildfire Bomb",        priority=3,  why="Highest damage ability — use empowered by Tip of the Spear.", tags={"core"} },
            { spellID=34026,  name="Kill Command",         priority=4,  why="Primary spender — send pet, empowered by Tip of the Spear stacks.", tags={"core"} },
            { spellID=259489, name="Raptor Strike",        priority=5,  why="Primary generator — builds Tip of the Spear. Cast between every spender.", tags={"core"} },
            { spellID=190925, name="Harpoon",              priority=6,  why="Gap closer — resets on kill in Midnight. Chain pull packs efficiently.", tags={"active"} },
            { spellID=53351,  name="Kill Shot",            priority=7,  why="Execute under 20% HP. Pack Leader procs allow use at any HP in burst.", tags={"active"} },
            { spellID=187650, name="Freezing Trap",        priority=8,  why="CC — freeze a mob 60s. Pull around it or use on dangerous adds.",   tags={"active"} },
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
            { spellID=53351,  name="Kill Shot",            priority=8,  why="Execute under 20% — always priority on low-HP targets.",            tags={"active"} },
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
            { spellID=257284, name="Hunter's Mark",        priority=1,  why="+3% flat damage — apply pre-pull, maintain throughout the fight.", tags={"core"} },
            { spellID=nil,    name="Takedown",             priority=2,  why="Major cooldown — on cooldown, align with Bloodlust when available.", tags={"core","cd"}, isCd=true, isMajorCd=true },
            { spellID=34026,  name="Kill Command",         priority=3,  why="Primary ST spender — use when empowered by Tip of the Spear.", tags={"core"} },
            { spellID=269752, name="Wildfire Bomb",        priority=4,  why="Strong ST damage — never hold >1 charge. Always Tip-empowered.", tags={"core"} },
            { spellID=259489, name="Raptor Strike",        priority=5,  why="Generator — keeps Tip of the Spear rolling. Fill every GCD.", tags={"core"} },
            { spellID=53351,  name="Kill Shot",            priority=6,  why="Execute under 20% — highest priority during execute phase.",               tags={"active"} },
            { spellID=190925, name="Harpoon",              priority=7,  why="If needed for positioning — does not break Tip stacks.",  tags={"active"} },
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
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% damage — maintain at all times.", tags={"core"} },
            { spellID=217200, name="Barbed Shot",       priority=2, why="Maintain Frenzy stacks on pet — never let stacks drop. 2 charges.", tags={"core"} },
            { spellID=34026,  name="Kill Command",      priority=3, why="Primary damage ability — on cooldown always.", tags={"core"} },
            { spellID=193455, name="Cobra Shot",        priority=4, why="Filler — generates Focus, reduces Kill Command CD by 1s.", tags={"active"} },
            { spellID=19574,  name="Bestial Wrath",     priority=5, why="Primary cooldown — +25% pet damage for 15s. On cooldown.", tags={"cd"}, isCd=true },
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20% HP — always priority.", tags={"active"} },
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
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20%.", tags={"active"} },
        },
    },
}

-- ── Marksmanship Hunter (specID 254) ──────────────────────────────────
R[254] = {
    solo = {
        tip = "MM solo: cast Trueshot on cooldown, spam Aimed Shot with Precise Shots procs. Rapid Fire as your second major ability. Arcane Shot as filler. Fully ranged — great for questing safety.",
        priorities = {
            { spellID=257284, name="Hunter's Mark",     priority=1, why="+3% damage — maintain at all times.", tags={"core"} },
            { spellID=19434,  name="Aimed Shot",        priority=2, why="Primary nuke — cast with Precise Shots buff for reduced cast time.", tags={"core"} },
            { spellID=257044, name="Rapid Fire",        priority=3, why="Channeled — highest DPS per GCD. On cooldown.", tags={"core"} },
            { spellID=185358, name="Arcane Shot",       priority=4, why="Filler — spends Precise Shots procs, generates Focus.", tags={"active"} },
            { spellID=288613, name="Trueshot",          priority=nil, isCd=true, isMajorCd=true, why="Primary CD — on cooldown. Aimed Shot and Rapid Fire both grant Precise Shots inside.", tags={"major-cd"} },
            { spellID=271788, name="Kill Shot",         priority=5, why="Execute under 20%.", tags={"active"} },
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
            { spellID=271788, name="Kill Shot",         priority=6, why="Execute under 20%.", tags={"active"} },
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
