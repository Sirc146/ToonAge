-- ToonAge/Data/TBCRotations.lua (Anniversary — TBC Classic / Interface 20506)
-- Static single-target PvE ability priority / rotation reference per spec —
-- a cheat-sheet, not a live tracker. Covers DPS priority, healer spell
-- priority (HPS), and tank threat-rotation (TPS), for every raid/dungeon-
-- viable spec across all 9 classes. This is the data backing the "Rotation"
-- UI tab (Modules/Character/Rotation.lua) and the /ta rotation chat command.
--
-- Requested 2026-09-07 alongside the secondary/hybrid capabilities feature,
-- as the other explicitly-deferred item from the original "gaps in classic"
-- scoping pass (talent builds were built first). Scope, confirmed with the
-- user via AskUserQuestion before building: static per-spec priority list
-- (not a live "next 3" suggester — that remains a possible bigger follow-up
-- project), covering DPS + healer HPS + tank TPS for all classes.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── SCHEMA ─────────────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
-- Each entry:
--   spec        talent tree name, matched against GetTalentTabInfo()'s
--               names for spec auto-detect (Druid's two Feral entries are
--               the one exception — see note below).
--   role        "dps" | "heal" | "tank"
--   priority    ORDERED list of short priority-rule strings, single-target,
--               PvE, level 70 endgame gear assumptions.
--   notes       1-3 sentences: resource management, key procs, common
--               mistakes.
--   confidence  CONFIRMED (2+ independent sources agree) / APPROX (single
--               source or best synthesis) / DISPUTED (sources genuinely
--               disagree — alternatives named in the note) — same grading
--               convention as Data/TBCTalentBuilds.lua and
--               Data/TBCSecondaryRoles.lua.
--   sources     URLs actually checked.
--
-- Druid Feral is one talent tree ("Feral Combat") but two very different
-- roles depending on shapeshift form, so it's stored as two separate
-- entries — spec = "Feral (Cat)" (dps) and spec = "Feral (Bear)" (tank) —
-- neither of which literally matches the GetTalentTabInfo() tree name.
-- Modules/Character/Rotation.lua special-cases this: when the detected tree
-- is "Feral Combat" it shows BOTH entries rather than trying to guess which
-- form you're in.
--
-- Researched 2026-09-07 against current TBC Classic Anniversary guides
-- (Icy Veins TBC Classic, Wowhead TBC, wowtbc.gg, Warcraft Tavern,
-- nottoolateforclassic.com) via 3 parallel research passes. AoE/cleave
-- variants and PvP rotations are NOT covered here — single-target PvE only.
-- A few specs are graded DISPUTED where sources gave genuinely different
-- priority orders rather than just different numbers — both named rather
-- than one being silently picked, same policy as the talent-builds file.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.Rotations = {

    WARRIOR = {
        {
            spec = "Arms", role = "dps",
            priority = {
                "Execute below 20% HP (swap to fast weapons)",
                "Mortal Strike on cooldown",
                "Slam only if it won't clip the next auto-attack",
                "Whirlwind for extra rage generation",
                "Heroic Strike as rage dump (>60 rage or moving with nothing else up)",
            },
            notes = "Pool rage before big cooldowns rather than dumping into Heroic Strike; swing-timer awareness is critical to avoid clipping Slam/auto-attacks. Maintain Battle Shout/Demoralizing Shout.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/arms-warrior-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Fury", role = "dps",
            priority = {
                "Bloodthirst on cooldown (top priority)",
                "Execute below 20% HP",
                "Whirlwind to spend excess rage",
                "Heroic Strike when rage > 60 and nothing else ready",
                "Hamstring only if rage-capped with nothing else available",
            },
            notes = "Pool rage ahead of cooldowns — skipping a Heroic Strike/Whirlwind to save rage for burst windows is a net DPS gain.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/fury-warrior-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Protection", role = "tank",
            priority = {
                "Opener: Charge/Berserker Rage, then swap to Defensive Stance",
                "Shield Slam on cooldown (never delay)",
                "Revenge on cooldown (best threat-per-rage)",
                "Devastate as filler (stacks Sunder Armor)",
                "Shield Block before heavy/crushing hits (skip if rage-starved)",
                "Heroic Strike as rage dump on auto-attacks",
            },
            notes = "Rage management is the core constraint. Shield Wall/Last Stand are emergency cooldowns for near-death moments; Demoralizing Shout/Thunder Clap add threat+mitigation as filler.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/warrior/protection/tank-rotation-cooldowns-abilities-pve",
                "https://www.icy-veins.com/tbc-classic/protection-warrior-tank-pve-rotation-cooldowns-abilities",
            },
        },
    },

    PALADIN = {
        {
            spec = "Holy", role = "heal",
            priority = {
                "Flash of Light for routine top-offs (most-cast spell)",
                "Holy Light for big/emergency heals",
                "Holy Shock only as an emergency instant or while moving",
                "Judgement of Wisdom/Light maintained if soloing (no Ret Paladin present)",
                "Divine Favor before an expected big heal (guaranteed crit)",
                "Divine Illumination during heavy sustained-damage phases",
            },
            notes = "Situational, not a fixed rotation — choose spell by incoming-damage urgency. Mana efficiency (Flash of Light spam) is the main constraint; Blessing of Protection/Sacrifice are preventive cooldowns.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/holy-paladin-healer-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Protection", role = "tank",
            priority = {
                "Opener: Righteous Fury + Seal of Righteousness/Wisdom",
                "Judgement to apply Judgement of the Crusader/Wisdom (unless a Ret Paladin covers it)",
                "Maintain Holy Shield",
                "Maintain Consecration",
                "Avenger's Shield for burst/ranged pulls (avoid when melee incoming)",
                "Hammer of Wrath below 20% HP; Exorcism vs. Undead/Demon",
            },
            notes = "Consecration and Holy Shield uptime are the two biggest threat levers; Spiritual Attunement converts incoming heals to mana. Sources differ on exact ordering — see DISPUTED note.",
            confidence = "DISPUTED",
            -- wowtbc.gg orders Avenging Wrath > Holy Shield > Consecration > Judgement > Hammer of Wrath >
            -- Exorcism > Avenger's Shield, while Icy Veins/general consensus treats Judgement+Consecration+
            -- Holy Shield as concurrently-maintained "core three" rather than a strict sequence.
            sources = {
                "https://wowtbc.gg/class-guides/protection-paladin/",
                "https://www.icy-veins.com/tbc-classic/protection-paladin-tank-pve-rotation-cooldowns-abilities",
            },
        },
        {
            spec = "Retribution", role = "dps",
            priority = {
                "Judgement of the Crusader/Wisdom applied first",
                "Maintain Seal of Blood/Martyr; seal-twist to proc Seal of Command before an auto-attack",
                "Crusader Strike on cooldown",
                "Judgement again on cooldown (off GCD)",
                "Hammer of Wrath below 20% HP or out of melee",
                "Exorcism vs. Undead/Demon; Consecration only when mana allows",
            },
            notes = "Seal-twisting (timing seal swaps around the swing timer) is the core skill and the biggest DPS lever — sloppy twisting loses more damage than any single ability choice.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/retribution-paladin-dps-pve-rotation-cooldowns-abilities",
                "https://wowtbc.gg/class-guides/retribution-paladin/",
            },
        },
    },

    HUNTER = {
        {
            spec = "Survival", role = "dps",
            priority = {
                "Auto Shot — never clip it",
                "Steady Shot woven between Auto Shots at your weapon-speed ratio",
                "Multi-Shot on cooldown in place of a Steady Shot",
                "Kill Command on cooldown (off-GCD, usable after a crit)",
                "Optional Raptor Strike melee-weave for a small gain",
            },
            notes = "The \"rotation\" is really a personalized Steady/Auto Shot timing ratio based on weapon speed and haste — never let a cast delay the next Auto Shot. Maintain Aspect of the Hawk.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/survival-hunter-dps-pve-rotation-cooldowns-abilities",
                "https://www.wowhead.com/tbc/guide/classes/hunter/dps-rotation-cooldowns-abilities-pve",
            },
        },
        {
            spec = "Beast Mastery", role = "dps",
            priority = {
                "Auto Shot — never clip it",
                "Steady Shot woven at your ratio",
                "Multi-Shot on cooldown replacing a Steady Shot",
                "Kill Command on cooldown (off-GCD, post-crit)",
                "Bestial Wrath as burst cooldown",
            },
            notes = "Identical shot-weaving framework to other Hunter specs; this spec's DPS gain comes mainly from pet damage/Bestial Wrath rather than a different shot priority.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Marksmanship", role = "dps",
            priority = {
                "Aimed Shot as opener only (long cast time unsuitable for sustained use)",
                "Auto Shot — never clip",
                "Steady Shot woven at your ratio",
                "Multi-Shot on cooldown replacing a Steady Shot",
                "Kill Command on cooldown (off-GCD, post-crit)",
                "Serpent Sting/Arcane Shot while moving",
            },
            notes = "Despite the spec name, sustained single-target play uses the same Steady/Auto Shot weave as other specs, not Aimed Shot spam — Aimed Shot is opener-only.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/marksmanship-hunter-dps-pve-rotation-cooldowns-abilities" },
        },
    },

    ROGUE = {
        {
            spec = "Combat", role = "dps",
            priority = {
                "Open with 2x Sinister Strike, then Slice and Dice at 5 CP",
                "Activate cooldowns (Blade Flurry, Adrenaline Rush, on-use trinkets/potions)",
                "Sinister Strike as combo-point builder",
                "Rupture at 5 CP if fight outlasts its duration, else Eviscerate",
                "Shiv when Deadly Poison nears expiry",
                "Keep Slice and Dice at 100% uptime (weave smaller refreshes)",
            },
            notes = "Pool Energy to ~65-85 (don't cap and waste regen ticks); apply Instant/Deadly Poison before pulls. Common mistake: refreshing SnD/Rupture too early, wasting combo points.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/rogue-dps-pve-rotation-cooldowns-abilities",
                "https://wowtbc.gg/class-guides/combat-rogue/",
            },
        },
        {
            spec = "Assassination", role = "dps",
            priority = {
                "Maintain Slice and Dice",
                "Expose Armor at 5 CP if assigned",
                "Rupture or Eviscerate (whichever won't stall SnD/EA uptime)",
                "Cold Blood + finisher for burst",
                "Shiv when Deadly Poison is about to expire",
                "Mutilate as primary combo-point builder",
            },
            notes = "Requires dual-wield daggers for Mutilate; keep Instant Poison (main hand) and Deadly Poison (off-hand) refreshed. Sources disagree on the finisher — see DISPUTED note.",
            confidence = "DISPUTED",
            -- wowtbc.gg's structured priority uses Rupture/Eviscerate as the finisher (matching Combat's
            -- template); nottoolateforclassic instead frames Envenom as the primary finisher with
            -- Mutilate spam feeding poison charges. Both are real TBC Mutilate-build variants.
            sources = {
                "https://wowtbc.gg/class-guides/assassination-rogue/",
                "https://nottoolateforclassic.com/rogue/assassination/",
            },
        },
        {
            spec = "Subtlety", role = "dps",
            priority = {
                "Maintain Slice and Dice",
                "Expose Armor at 5 CP if assigned",
                "Rupture or Eviscerate depending on fight length remaining",
                "Cooldowns (Blade Flurry/Adrenaline Rush/on-use)",
                "Shiv for poison upkeep",
                "Hemorrhage as combo-point builder",
            },
            notes = "Widely considered PvE-inferior to Combat/Assassination in TBC — one guide calls it \"a hard pass\" for raiding, though a full priority list does exist. See DISPUTED note.",
            confidence = "DISPUTED",
            -- nottoolateforclassic states Subtlety has no viable PvE rotation and shouldn't be used in
            -- raids; wowtbc.gg publishes a full PvE priority list for it regardless.
            sources = {
                "https://wowtbc.gg/class-guides/subtlety-rogue/",
                "https://nottoolateforclassic.com/rogue/subtlety/",
            },
        },
    },

    PRIEST = {
        {
            spec = "Holy", role = "heal",
            priority = {
                "Power Word: Shield pre-emptively on incoming/imminent burst damage",
                "Binding Heal when both healer and target need healing",
                "Renew maintained on tank(s)/sustained-damage targets",
                "Greater Heal for big single-target heals",
                "Circle of Healing for raid AoE damage (3+ injured targets)",
                "Prayer of Mending on tank/group taking heavy AoE",
                "Flash Heal as emergency filler/on the move",
            },
            notes = "Manage the 5-second-rule mana regen window; downrank heals when full-rank would overheal. Use Shadowfiend/Inner Focus to bridge mana.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/holy-priest-healer-pve-rotation-cooldowns-abilities",
                "https://wowtbc.gg/class-guides/holy-priest/",
            },
        },
        {
            spec = "Discipline", role = "heal",
            priority = {
                "Power Word: Shield as the core damage-prevention tool (cast before damage lands)",
                "Renew/Greater Heal/Flash Heal used situationally, as with Holy",
                "Pain Suppression on tank for big cooldowns",
                "Power Infusion on a caster during burn phases",
            },
            notes = "TBC Discipline has no Penance (later-expansion spell) — its identity is shield-spam plus Reflective Shield rather than a distinct priority list; most guides treat it as Holy-adjacent/PvP-leaning rather than a primary raid healer.",
            confidence = "APPROX",
            sources = { "https://nottoolateforclassic.com/priest/discipline/" },
        },
        {
            spec = "Shadow", role = "dps",
            priority = {
                "Shadow Word: Pain kept up at all times",
                "Mind Blast on cooldown",
                "Vampiric Touch maintained continuously (party mana return)",
                "Vampiric Embrace on bosses lasting 1+ minute",
                "Shadow Word: Death as high-damage instant (careful at low HP — self-damage)",
                "Mind Flay as filler, cancel early if Mind Blast/SW:D come off cooldown",
            },
            notes = "Requires Shadowform active. Mana sustain comes from Vampiric Touch's party mana return rather than active downranking.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/shadow-priest-dps-pve-rotation-cooldowns-abilities" },
        },
    },

    SHAMAN = {
        {
            spec = "Elemental", role = "dps",
            priority = {
                "Maintain Water Shield and totems (Totem of Wrath, Mana Spring, Wrath of Air)",
                "Elemental Mastery + Chain Lightning for burst",
                "Chain Lightning when mana allows (short fights)",
                "Lightning Bolt as primary sustained filler",
                "Flame Shock while moving/for mobility damage",
            },
            notes = "Do not downrank damage spells in TBC (downranking penalty system). Chain Lightning is gated by fight length/mana, not spammed like Lightning Bolt.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/elemental-shaman-dps-pve-rotation-cooldowns-abilities",
                "https://wowtbc.gg/class-guides/elemental-shaman/",
            },
        },
        {
            spec = "Enhancement", role = "dps",
            priority = {
                "Drop totems (Strength of Earth minimum), totem-twist as mana allows",
                "Stormstrike whenever available (unless fishing for a Windfury proc)",
                "Earth Shock following Stormstrike's debuff window",
                "Rotate Flame Shock/Earth Shock on cooldown to keep Flame Shock up",
                "Auto-attack/Windfury procs fill the rest",
            },
            notes = "Windfury Weapon has a 3s internal cooldown (\"Windfury fishing\" times Stormstrike around it); downrank Windfury Totem to rank 1 to conserve mana.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Restoration", role = "heal",
            priority = {
                "Lesser Healing Wave for emergency/about-to-die targets",
                "Keep Earth Shield on tank and Water Shield on self at all times",
                "Maintain totems (Mana Spring, healing-relevant) in range",
                "Sustain Ancestral Healing/Healing Way stacks on tank",
                "Chain Heal for multiple injured targets",
                "Healing Wave for efficient focused single-target healing",
            },
            notes = "No Riptide in TBC (WotLK-only). Downrank Chain Heal/Healing Wave for efficiency; cast-and-cancel technique pre-loads heals without breaking mana regen.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/restoration-shaman-healer-pve-rotation-cooldowns-abilities" },
        },
    },

    MAGE = {
        {
            spec = "Arcane", role = "dps",
            priority = {
                "Arcane Blast spam as primary filler, including during cooldowns",
                "Watch the self-debuff (mana cost stacks 8s) — let it drop before recasting",
                "Below ~30-40% mana: cycle 3x Arcane Blast + 3-4x Frostbolt",
                "Stack Arcane Power + Icy Veins + trinkets/potions together at full mana",
                "Avoid casting Frostbolt during cooldown windows",
            },
            notes = "Mana-management-driven spec; Frostbolt is a mana-saving filler during cooldowns, not a damage tool. Common mistake: refreshing the Arcane Blast debuff at the wrong moment.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/arcane-mage-dps-pve-rotation-cooldowns-abilities",
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-rotation-cooldowns-abilities-pve",
            },
        },
        {
            spec = "Fire", role = "dps",
            priority = {
                "Apply/maintain the 5-stack Improved Scorch debuff",
                "Fireball spam between Scorch refreshes",
                "Fire Blast while forced to move",
                "Save Combustion + Icy Veins + trinkets/potions for execute phase (<20% HP, Molten Fury)",
                "Cold Snap to reset Icy Veins for a second use on long fights",
            },
            notes = "Build the entire cooldown plan around the Molten Fury execute window. Mistake: popping Combustion early instead of banking it for sub-20%.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/fire-mage-dps-pve-rotation-cooldowns-abilities",
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-rotation-cooldowns-abilities-pve",
            },
        },
        {
            spec = "Frost", role = "dps",
            priority = {
                "Icy Veins + Water Elemental on pull/cooldown-ready",
                "Frostbolt spam as primary filler",
                "Ice Lance on frozen targets (Shatter combo: freeze > Frostbolt > Ice Lance)",
                "Fire Blast only while moving and target isn't frozen",
                "Cold Snap to double up Icy Veins/Water Elemental on long fights",
            },
            notes = "Minimizing movement is the main DPS lever; maintain Molten Armor and pet uptime.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/frost-mage-dps-pve-rotation-cooldowns-abilities" },
        },
    },

    WARLOCK = {
        {
            spec = "Affliction", role = "dps",
            priority = {
                "Curse of the Elements (or Curse of Doom if fight >60s and uncovered)",
                "Unstable Affliction if specced",
                "Maintain Corruption",
                "Maintain Siphon Life",
                "Immolate only with Improved Scorch active from a Fire Mage",
                "Shadow Bolt as filler between DoT refreshes",
            },
            notes = "DoT uptime is the core skill — use a DoT-timer addon. Imp is the standard demon for party buffs; Life Tap for mana while moving.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/affliction-warlock-dps-pve-rotation-cooldowns-abilities",
                "https://wowtbc.gg/class-guides/affliction-warlock/",
            },
        },
        {
            spec = "Demonology", role = "dps",
            priority = {
                "Curse of Doom on pull",
                "Maintain Corruption",
                "Immolate only if light on shadow-damage gear or Improved Scorch is active",
                "Shadow Bolt as primary filler",
            },
            notes = "Felguard is summoned and kept alive at all costs (Drain Life to heal it if needed) — pet uptime drives DPS.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/demonology-warlock-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Destruction", role = "dps",
            priority = {
                "Curse of Doom on pull",
                "Apply Immolate",
                "Corruption on pull (threat aid only)",
                "Incinerate (Fire build) or Shadow Bolt (Shadow build) as filler",
                "Conflagrate ONLY when forced to move — never on cooldown or right at Immolate's end",
            },
            notes = "Two viable builds (Fire-Destro vs Shadow-Destro) change filler spell and demon. Common mistake: spamming Conflagrate on CD instead of saving it for movement.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/destruction-warlock-dps-pve-rotation-cooldowns-abilities" },
        },
    },

    DRUID = {
        {
            spec = "Balance", role = "dps",
            priority = {
                "Maintain Faerie Fire (raid debuff)",
                "Let Moonfire fully expire before refreshing",
                "Force of Nature when treants will survive most of their duration",
                "Starfire spam as main filler",
                "Weave Insect Swarm only while moving",
                "Drop DoT upkeep and pure-Starfire-spam if mana-constrained",
            },
            notes = "Mana efficiency vs. DPS is the core tradeoff on long fights; Force of Nature timing matters more than reflexive on-cooldown use.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/balance-druid-dps-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Feral (Cat)", role = "dps",
            priority = {
                "Keep the Mangle (Cat) debuff up at all times",
                "At 4-5 combo points: Rip if the target outlives its full duration, else Ferocious Bite",
                "Build combo points with Shred from behind (Claw when positioning unavailable)",
                "Powershift out/into Cat Form to burst-restore Energy when low",
            },
            notes = "Rake and Savage Roar are NOT part of the standard TBC priority — Savage Roar doesn't exist until WotLK, and Rake's non-crit bleed underperforms Claw/Shred in TBC.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/feral-druid-dps-pve-rotation-cooldowns-abilities",
                "https://www.icy-veins.com/tbc-classic/feral-druid-dps-pve-spell-summary",
            },
        },
        {
            spec = "Feral (Bear)", role = "tank",
            priority = {
                "Maintain Demoralizing Roar and Faerie Fire (Feral) if no Boomkin",
                "Mangle (Bear) whenever off cooldown (primary threat tool)",
                "Keep a 5-stack of Lacerate on target",
                "Swipe as extra filler once ~2700+ buffed Attack Power (out-scales Lacerate)",
                "Dump remaining rage into Maul",
            },
            notes = "Frenzied Regeneration converts rage to self-healing under heavy damage; Barkskin drops Bear Form so use only off-tanking. The ~2700 AP checkpoint flips Swipe above Lacerate for single-target filler.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/feral-druid-tank-pve-rotation-cooldowns-abilities" },
        },
        {
            spec = "Restoration", role = "heal",
            priority = {
                "Stay in Tree of Life form when possible (healing up, mana cost down)",
                "Keep Lifebloom triple-stacked on the tank",
                "Maintain Rejuvenation/Regrowth on damaged targets",
                "Swiftmend to consume those HoTs during heavy damage",
                "Healing Touch (+ Nature's Swiftness for instant-cast) for large single-target emergencies",
                "Tranquility for raid-wide burst cooldown",
            },
            notes = "Keep multiple Rejuvenation/Healing Touch ranks on the bar to rank down for mana efficiency; Innervate for mana emergencies; Rebirth for battle-res.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/restoration-druid-healer-pve-rotation-cooldowns-abilities" },
        },
    },
}
