-- ToonAge/Data/TBCLevelingRotations.lua (Anniversary — TBC Classic / Interface 20506)
-- The LEVELING counterpart to Data/TBCRotations.lua. That file's priority
-- lists assume level 70 with a full 61-point talent build — genuinely wrong
-- advice for a character still leveling, who is often missing the exact
-- ability the list leads with (Bloodthirst/Mortal Strike at 40, Mangle at
-- 50, Steady Shot at 62, Shadowform at 40, Vampiric Touch at 50, and so on).
-- Requested 2026-09-09: "make sure that while leveling there is rotations
-- for current levels and skills and not for max level unless the max level
-- has been reached."
--
-- Modules/Character/Rotation.lua picks this table instead of
-- TA.Data.Rotations whenever U.GetPlayerLevel() < 70, and switches back to
-- the max-level table automatically at 70 — no manual toggle.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── CONFIDENCE GRADING ────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Same convention as every other data file here (TBCTalentBuilds.lua,
-- TBCRotations.lua, TBCSecondaryRoles.lua):
--
--   CONFIRMED   2+ independent sources agree on the leveling-specific
--               priority described.
--   APPROX      Real, sourced leveling guidance, but only one source gave
--               spec-level detail, or the guidance is a close variant of a
--               sibling spec's page (flagged explicitly where that happened
--               — see Marksmanship Hunter below).
--   DISPUTED    Sources genuinely disagree on a real point (both named,
--               not silently resolved) — see Affliction Warlock's pet
--               choice below.
--
-- Researched 2026-09-09 via 3 parallel research passes (one per class
-- group), reading each class/spec's dedicated TBC Classic LEVELING guide —
-- distinct from the max-level PvE rotation pages TBCRotations.lua cites —
-- on Icy Veins (*-leveling-guide), Wowhead (*/leveling-tips), noobtoboss.com,
-- and boosting-ground.com. Every entry below documents, in its own `notes`,
-- what is genuinely DIFFERENT about the leveling version versus the
-- max-level entry for the same spec (a missing ability, a simpler priority,
-- a different resource constraint) rather than just restating a weaker copy
-- of the raid rotation.
--
-- Schema — identical to TBCRotations.lua's:
--   spec        spec name, same spelling TBCRotations.lua uses for that
--               class (Feral is a partial exception — see DRUID below)
--   role        "dps" | "heal" | "tank"
--   priority    ordered array of plain-English steps
--   notes       what's different from max level, in prose
--   confidence  CONFIRMED | APPROX | DISPUTED
--   sources     URLs actually fetched during research
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.LevelingRotations = {

    WARRIOR = {
        {
            spec = "Arms", role = "dps",
            priority = {
                "Bloodrage before/at the start of a pull so Rage doesn't decay between mobs",
                "Charge to open (extra Rage plus initial damage)",
                "Rend at the start of the fight (early levels, before Mortal Strike)",
                "Overpower whenever an attack is dodged or parried",
                "Mortal Strike on cooldown once learned at level 40 — becomes the core ability, converting Rage into damage",
                "Whirlwind to spend excess Rage, holding back ~30 Rage for the next Mortal Strike",
                "Sunder Armor / Heroic Strike as Rage-dump filler when nothing else is ready",
                "Execute below 20% HP",
            },
            notes = "Pre-40 Arms leveling is mostly Charge + Rend + Heroic Strike filler — there is no Mortal Strike yet, so it doesn't resemble the max-level rotation at all. Wowhead's leveling guide further describes a level-64+ shift where Slam (via the Improved Slam talent) overtakes Mortal Strike as the highest damage-per-rage ability, but that requires deep Arms talent investment most leveling builds (which split points for survivability/utility) won't have; the Mortal Strike/Whirlwind priority above is what most players actually run through the leveling phase. No Sweeping Strikes-based AoE tuning either, unlike max level.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/arms-warrior-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/warrior/arms/leveling-tips",
            },
        },
        {
            spec = "Fury", role = "dps",
            priority = {
                "Bloodrage before/at the start of a pull so Rage doesn't decay between mobs",
                "Charge to open",
                "Rend at the start of combat (early levels, before Bloodthirst)",
                "Bloodthirst on cooldown once learned at level 40 — top priority from that point on",
                "Whirlwind to spend excess Rage, keeping ~30 Rage in reserve for Bloodthirst",
                "Overpower on a dodge/parry",
                "Heroic Strike / Sunder Armor as Rage-dump filler",
                "Execute below 20% HP",
            },
            notes = "Below level 40 there is no Bloodthirst at all, so leveling Fury is really just auto-attack plus Charge/Rend/Heroic Strike — nothing like the Bloodthirst-anchored max-level priority. Wowhead's leveling guide explicitly advises SKIPPING Rampage even after it's talented, until you have Outland-level crit chance and rage generation to sustain the buff — the opposite of max level, where near-100% Rampage uptime is a core damage lever.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/fury-warrior-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/warrior/fury/leveling-tips",
            },
        },
        {
            spec = "Protection", role = "tank",
            priority = {
                "Solo/questing: spam Devastate while dual-wielding in Berserker Stance, with Whirlwind/Heroic Strike as Rage allows — this is a DPS rotation, not a tank rotation",
                "Dungeon tanking — Shield Slam on cooldown (highest single-target threat)",
                "Revenge on cooldown",
                "Demoralizing Shout / Thunder Clap to open and to reduce incoming damage (Thunder Clap first if 2+ targets, for even threat)",
                "Devastate as the rage-efficient filler (stacks Sunder Armor)",
                "Shield Block for mitigation or to guarantee the next Revenge proc",
                "Heroic Strike only when Rage is otherwise going to waste",
            },
            notes = "Leveling Protection actually splits into two very different rotations depending on activity: solo questing uses a dual-wield Berserker-Stance Devastate-spam DPS rotation (no shield, no threat concerns), while dungeon tanking uses a simplified version of the max-level threat rotation without the Shield Wall/Last Stand emergency-cooldown layer (lower Block Value/fewer defensive talent points make those less reliable anyway). Icy Veins notes Protection levels noticeably slower than Arms/Fury before ~level 50 and recommends tanking dungeon groups frequently rather than pure solo questing.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/protection-warrior-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/warrior/protection/leveling-tips",
            },
        },
    },

    PALADIN = {
        {
            spec = "Holy", role = "heal",
            priority = {
                "Flash of Light as the primary spam heal",
                "Weave in a downranked Holy Light periodically (roughly every 15s) for a bigger heal/mana-return tick",
                "Holy Shock as an instant heal or emergency/on-the-move option",
                "Divine Favor / Divine Illumination on cooldown to stretch mana further",
                "Cleanse and Blessing of Freedom situationally for utility",
            },
            notes = "Both sources are explicit that Holy is a WEAK solo-leveling spec — low personal damage means questing alone is slow, and the guides directly recommend leveling as Retribution or Protection instead, using Holy mainly in duo/group/dungeon content. The rotation itself is also simpler than max level: no Circle-of-Healing-style AoE tool, and without the full Holy tree invested you won't have the mana-efficiency talents that shape the level-70 Flash-of-Light-spam rotation, so mana runs out faster relative to healing done.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/holy-paladin-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/paladin/holy/leveling-tips",
            },
        },
        {
            spec = "Protection", role = "tank",
            priority = {
                "Have your seal and Holy Shield up before pulling",
                "Open with Avenger's Shield",
                "Judgement on cooldown IF mana allows, then re-apply your seal",
                "Holy Shield on cooldown, mana permitting",
                "Consecration for 2+ targets if mana allows (Seal of Wisdom helps mana sustain in AoE pulls)",
                "Exorcism against Undead/Demon targets",
                "Auto-attack fills the rest — once threat is secure, weigh whether another spell is even worth the mana versus saving it for the next pull",
            },
            notes = "The binding constraint while leveling is MANA, not talent points — a leveling Protection Paladin can't sustain Judgement + Consecration + Holy Shield all on cooldown the way the max-level 'core three' rotation does, so the priority above is heavily conditional ('if mana allows') rather than a fixed loop. Icy Veins also notes that if you can't find a dungeon group, Protection has meaningfully lower single-target damage and higher mana cost than Retribution for solo questing, and suggests swapping specs for that content instead of trying to solo as Protection.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/protection-paladin-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/paladin/protection/leveling-tips",
            },
        },
        {
            spec = "Retribution", role = "dps",
            priority = {
                "Seal of Command as your primary seal (switch to Seal of Blood around level 64 once it's available)",
                "Judgement of Wisdom on pull only if mana sustain is a concern — otherwise don't Judgement on cooldown, ration it",
                "Crusader Strike on cooldown",
                "Exorcism against Undead/Demon targets",
                "Consecration on cooldown only against groups of enemies, mana permitting (down-rank it to conserve mana)",
                "Auto-attack under your active seal as the main damage source — no seal-twisting",
                "Avoid Hammer of Wrath except to finish a fleeing target — it costs a lot of mana and resets your swing timer",
            },
            notes = "The single biggest difference from max level: NO seal-twisting. Wowhead is explicit that this is 'not a more advanced seal twisting rotation like you would do against a raid boss' — twisting costs too much mana for too little gain before Seal of Blood is available, so you just hold one seal and auto-attack. Judgement is also rationed rather than used on cooldown, the opposite of the max-level priority.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/retribution-paladin-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/paladin/retribution/leveling-tips",
            },
        },
    },

    HUNTER = {
        {
            spec = "Survival", role = "dps",
            priority = {
                "Send pet in first and let it establish threat/tank the target",
                "Hunter's Mark on the target",
                "Auto Shot — never clip it; kite backwards to fit in as many Auto Shots as possible before the target reaches you",
                "Before level 62: Arcane Shot as your first ability after Auto Shot, Multi-Shot on cooldown (careful not to pull off your pet), optional Raptor Strike melee filler",
                "From level 62: Steady Shot replaces Arcane Shot as the primary filler between Auto Shots — the real '1:1' shot weave begins here",
                "From level 66: Kill Command whenever available (usable after a crit)",
                "Serpent Sting to keep a DoT ticking",
            },
            notes = "Pre-62 Survival leveling has no Steady Shot, so it's really just Auto Shot + Arcane/Multi-Shot filler plus pet-threat management (kiting, watching for pulled aggro) — Icy Veins calls this phase 'slow and boring.' Icy Veins' general Hunter leveling guide also flags Survival as 'the worst of the choices' for leveling DPS/pet tankiness and recommends Beast Mastery instead — worth noting since a leveling Survival Hunter is, per that source, deliberately using a suboptimal leveling spec even though the rotation itself is confirmed by both sources.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/survival-hunter-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/hunter/survival/leveling-tips",
            },
        },
        {
            spec = "Beast Mastery", role = "dps",
            priority = {
                "Send pet in first and let it tank whenever possible",
                "Hunter's Mark on the target",
                "Kill Command whenever available",
                "Auto Shot — never clip it; kite backwards between shots",
                "Before level 62: Arcane Shot after each Auto Shot, Multi-Shot on cooldown, optional Raptor Strike filler",
                "From level 62: Steady Shot replaces Arcane Shot as the primary Auto Shot filler",
                "Bestial Wrath as a burst cooldown; Intimidation for utility/CC",
                "Serpent Sting to maintain a DoT",
            },
            notes = "Same core shot-weave framework as the other two Hunter specs while leveling — the real differentiator is pet quality/tankiness plus Bestial Wrath, not a different shot priority (mirrors how the max-level BM entry in TBCRotations.lua is framed). Multi-Shot is flagged as risky pre-62 because it can pull threat off your pet, a leveling-specific concern that matters far less at max level with better pet AI/gear and Misdirection-less threat tools.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/hunter/beast-mastery/leveling-tips",
            },
        },
        {
            spec = "Marksmanship", role = "dps",
            priority = {
                "Send pet in first, Hunter's Mark on the target",
                "Aimed Shot as an opener once available at level 20",
                "Auto Shot — never clip it; kite backwards between shots",
                "Before level 62: Arcane Shot after each Auto Shot, Multi-Shot on cooldown, optional Raptor Strike filler",
                "From level 62: Steady Shot replaces Arcane Shot as the primary Auto Shot filler",
                "Kill Command from level 66",
                "Serpent Sting to maintain a DoT",
            },
            notes = "Despite the spec name, leveling Marksmanship uses essentially the same Auto/Steady Shot weave as Survival and Beast Mastery — both sources' leveling guidance for MM is nearly identical to the other two specs' leveling pages, echoing the max-level MM entry's own note that Aimed Shot is opener-only rather than a spam tool. As with BM, Multi-Shot/Aimed Shot risk pulling threat off a leveling pet, a concern that fades at max level.",
            confidence = "APPROX",
            -- Graded APPROX rather than CONFIRMED: both sources' MM-specific leveling content is so close to
            -- their Survival/BM pages that it's unclear how much is genuinely MM-tailored guidance versus a
            -- shared template being reused across all three Hunter leveling pages — flagging rather than
            -- presenting borrowed generic content as MM-specific confirmed research.
            sources = {
                "https://www.icy-veins.com/tbc-classic/marksmanship-hunter-leveling-guide",
                "https://www.wowhead.com/tbc/guide/classes/hunter/marksmanship/leveling-tips",
            },
        },
    },

    ROGUE = {
        {
            spec = "Combat", role = "dps",
            priority = {
                "Open with Cheap Shot (from stealth), then a 2-combo-point Slice and Dice",
                "Sinister Strike as your combo-point builder",
                "Eviscerate once at/near 5 CP — most quest mobs die before a full-duration Rupture pays off",
                "Rupture instead of Eviscerate only against something tough enough to outlast it (rare while leveling)",
                "Kidney Shot instead of a finisher if you need the mob locked down rather than dead faster",
                "Blade Flurry + Eviscerate together on multi-mob pulls",
                "Riposte (10 Energy, free from level 20) whenever a parry procs it — punishes mobs hard for almost no Energy",
                "Adrenaline Rush (level 40+) on pulls where you want to burn through Energy faster",
            },
            notes = "Simpler than the max-level version: Rupture is a situational tool rather than a real alternative to Eviscerate, because virtually nothing you fight while leveling lives long enough to make it worthwhile — Icy Veins' leveling guide says this outright. Riposte (unlocked at 20) is a leveling-specific gain that doesn't factor into the endgame priority at all. Poison choice matters less solo than in the max-level Assassination-style upkeep game. Adrenaline Rush (40) and Blade Flurry (30) come online mid-leveling, well before the level-70 talent build assumed by TBCRotations.lua.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/rogue/combat/leveling-tips",
                "https://www.icy-veins.com/tbc-classic/combat-rogue-leveling-guide",
            },
        },
        {
            spec = "Assassination", role = "dps",
            priority = {
                "Apply Deadly Poison to BOTH weapons (not the endgame Instant-MH/Deadly-OH split) so the poison debuff is always up for Mutilate's damage bonus",
                "Maintain Slice and Dice above all else",
                "Mutilate as your combo-point builder",
                "Eviscerate at 5 CP as the default finisher (Improved Eviscerate makes this a safe reflex, not a judgment call)",
                "Kidney Shot instead of a finisher when you need to reposition behind a mob for Mutilate/Backstab rather than just to kill faster",
            },
            notes = "Meaningfully simpler than the level-70 Mutilate priority: no Rupture-vs-Eviscerate decision tree (Improved Eviscerate lets you just always Eviscerate), and no Expose Armor/Cold Blood cooldown layering since that's a raid-assignment tool. Running Deadly Poison on both weapons (rather than the endgame Instant/Deadly split) is a leveling-specific call to guarantee the Mutilate poison-debuff bonus without needing precise proc uptime.",
            confidence = "APPROX",
            sources = { "https://www.wowhead.com/tbc/guide/classes/rogue/assassination/leveling-tips" },
        },
        {
            spec = "Subtlety", role = "dps",
            priority = {
                "Open from stealth with Cheap Shot — Subtlety's talents (e.g. Master of Subtlety) reward using it often, not just as a pull opener",
                "Sinister Strike as your combo-point builder",
                "Maintain Slice and Dice above all else",
                "Eviscerate at 5 CP if the target won't survive Rupture's full duration",
                "Rupture instead, on tougher/longer-lived targets, without overwriting an already-ticking Rupture",
            },
            notes = "Uses the same builder/SnD/Eviscerate-or-Rupture shape as leveling Combat, but leans harder on repeated stealth openers (Cheap Shot) since Subtlety's talent kit rewards re-entering stealth, which the max-level single-target priority in TBCRotations.lua doesn't call out. No Hemorrhage or Expose Armor assignment — those are raid-context tools this guide doesn't mention for solo leveling. Unlike the max-level entry (graded DISPUTED there over PvE viability), no source treats Subtlety leveling itself as a bad choice — the leveling guide just describes it as more survivability-oriented than a smaller Combat-clone rotation.",
            confidence = "APPROX",
            sources = { "https://www.wowhead.com/tbc/guide/classes/rogue/subtlety/leveling-tips" },
        },
    },

    PRIEST = {
        {
            spec = "Holy", role = "heal",
            priority = {
                "Dispel Magic preemptively on dangerous enemy buffs",
                "Power Word: Shield before damage lands",
                "Renew on yourself/party members taking sustained damage",
                "Flash Heal for anything urgent",
                "Holy Nova only for cheap, limited AoE — mana-inefficient, use sparingly",
                "Wand between casts to conserve mana rather than spamming Smite",
            },
            notes = "Icy Veins is explicit that Holy is not recommended for solo leveling at all — it's meant to be leveled through group dungeons as a healer, where this priority list is really just a simplified version of the max-level HPS list (no Circle of Healing/Prayer of Mending assignment nuance, since group content pre-70 rarely needs it). If you do solo as Holy, damage output is wand + occasional Smite, not a real rotation.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/holy-priest-leveling-guide" },
        },
        {
            spec = "Discipline", role = "heal",
            priority = {
                "Pain Suppression / Dispel Magic / Power Word: Shield for immediate threats",
                "Prayer of Mending, Binding Heal, Flash Heal, or Renew depending on the damage pattern",
                "Prayer of Healing or Holy Nova only when multiple party members are hurt",
                "Greater Heal for a big single-target top-up",
            },
            notes = "Same conclusion as Holy: not recommended for solo leveling (Icy Veins says leveling as a healer is much slower than Shadow) — Discipline is really a dungeon-group healing spec pre-70, and its leveling priority is a lighter version of its max-level list rather than a distinct rotation. TBC Discipline still has no Penance, matching the note on its max-level TBCRotations.lua entry. Holy Nova is called out as unreliable, secondary damage at best.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/discipline-priest-leveling-guide" },
        },
        {
            spec = "Shadow", role = "dps",
            priority = {
                "Levels 1-19: Power Word: Shield before pulling, Shadow Word: Pain if the mob has enough HP to matter, Mind Blast for burst, then wand it down to save mana",
                "Levels ~20-25: same as above, but replace part of the wand phase with Mind Flay once it's trained",
                "Level 40+: get into Shadowform and stay in it — don't drop form to heal/bandage",
                "Level 50+: apply Vampiric Touch on anything with meaningful HP for the mana return",
                "Shadow Word: Death as an execute on low-HP targets",
                "Mind Flay as filler between Mind Blast/SW:D cooldowns; wand only weak/near-dead targets to save mana",
            },
            notes = "Genuinely different from the max-level rotation, not just a weaker version of it: for roughly the first 20 levels you have neither Mind Flay nor Shadowform nor Vampiric Touch, so you're mostly wanding with Shadow Word: Pain/Mind Blast layered on top, not channeling Mind Flay at all. Vampiric Touch (the party-mana-return tool the max-level notes rely on) doesn't exist until level 50. Sources differ slightly on the exact level Mind Flay unlocks (Icy Veins says 25, noobtoboss says 20) so it's given as a range here.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/shadow-priest-leveling-guide",
                "https://noobtoboss.com/tbc-classic-shadow-priest-leveling-guide/",
            },
        },
    },

    SHAMAN = {
        {
            spec = "Elemental", role = "dps",
            priority = {
                "Lightning Bolt as your opener and primary single-target spell (best Mana efficiency)",
                "Chain Lightning on cooldown against multiple enemies, or whenever Elemental Focus is up",
                "Drop Searing Totem and Strength of Earth Totem as basic damage/buff support",
                "Stoneclaw Totem when multiple mobs are on you — it frequently stuns attackers, a much bigger deal in TBC than earlier expansions",
                "Totem of Wrath / Wrath of Air Totem once available (~level 50+) for extra damage",
            },
            notes = "Structurally the same spell as max level (Lightning Bolt filler, Chain Lightning gated by target count/mana) but leveling play leans harder on defensive/CC totems like Stoneclaw since you're soloing without a healer, and totem access is progressively unlocked rather than all available at once. Both sources agree Elemental out-kills Enhancement in bursts but drinks more between fights.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/elemental-shaman-leveling-guide",
                "https://noobtoboss.com/tbc-classic-shaman-leveling-guide/",
            },
        },
        {
            spec = "Enhancement", role = "dps",
            priority = {
                "Levels 1-39: use a two-handed weapon with Rockbiter Weapon applied, Lightning Shield up, auto-attack between shocks",
                "Earth Shock / Flame Shock whenever available as extra burst",
                "Level 40+: Stormstrike whenever it's off cooldown (also boosts your next two Earth Shocks)",
                "Level 41+: switch to dual-wielded one-handers",
                "Apply Windfury Weapon as soon as it's available — one weapon first, then both once you can afford re-applying it on two weapons (~level 50+)",
                "Water Shield replaces Lightning Shield once trained, for better mana sustain",
                "Shamanistic Rage on cooldown once available, to keep mana up without drinking",
            },
            notes = "The leveling version is a staged progression rather than one fixed priority: pre-40 Enhancement is Rockbiter + shocks + auto-attack with a 2H weapon (no Stormstrike, no dual Windfury), and only from level 40-50 onward does it start to resemble the max-level Stormstrike/dual-Windfury rotation in TBCRotations.lua. Both sources agree on the Rockbiter-to-Windfury weapon-imbue transition as the defining leveling milestone.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/enhancement-shaman-leveling-guide",
                "https://noobtoboss.com/tbc-classic-shaman-leveling-guide/",
            },
        },
        {
            spec = "Restoration", role = "heal",
            priority = {
                "Preferred path: level through group dungeons as a healer — keep Earth Shield on the tank, Water Shield on yourself at all times",
                "Chain Heal when 2+ party members are hurt; Healing Wave for big single-target heals; Lesser Healing Wave for quick top-offs",
                "Nature's Swiftness + Healing Wave for an instant emergency heal; Mana Tide Totem on cooldown",
                "If soloing anyway: Searing Totem down, open with Lightning Bolt, apply Flame Shock, use Earth Shock as filler/interrupt, then melee whatever closes the distance",
            },
            notes = "This is the one leveling spec that is a genuinely different playstyle from its max-level entry, not just a smaller version of it — both sources explicitly call Restoration the slowest/worst spec to solo-level with and recommend dungeon-healing instead. When it is soloed anyway, it plays as a caster/melee hybrid (Lightning Bolt/Flame Shock/Earth Shock, then auto-attack) rather than anything resembling the max-level healing priority, since sustained solo healing-through-damage isn't viable pre-70. Only one source (noobtoboss) actually details that solo hybrid rotation, so it's graded APPROX rather than CONFIRMED despite both sources agreeing on the general 'don't solo this' recommendation.",
            confidence = "APPROX",
            sources = {
                "https://www.icy-veins.com/tbc-classic/restoration-shaman-leveling-guide",
                "https://noobtoboss.com/tbc-classic-restoration-shaman-leveling-guide/",
            },
        },
    },

    MAGE = {
        {
            spec = "Arcane", role = "dps",
            priority = {
                "Open with Frostbolt to slow the target, then channel Arcane Missiles",
                "Arcane Missiles as primary sustained damage (5/5 Improved Arcane Missiles removes pushback)",
                "Finish weak/near-dead targets with your wand instead of another cast, to save mana",
                "Frost Nova (+ Blink/Slow) to disengage if something reaches melee",
                "Arcane Explosion only against 2+ tightly clustered adds",
            },
            notes = "Nothing like the max-level Arcane Blast-spam rotation — there is no Arcane Blast mana-cost debuff to manage at all while leveling. The leveling priority is Frostbolt-opener into Arcane Missiles plus heavy wand use between casts to conserve mana, per Icy Veins' Arcane leveling guide. Only one detailed source found, so treat this as a best-synthesis rather than a cross-confirmed rotation.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/arcane-mage-leveling-guide" },
        },
        {
            spec = "Fire", role = "dps",
            priority = {
                "Pull with Fireball (or Pyroblast at level 20+, for the extra DoT tick)",
                "Fireball spam as the main sustained damage spell",
                "Fire Blast or Scorch to finish low-HP targets instead of waiting on a full Fireball cast",
                "Frost Nova / Blast Wave to create distance if something closes to melee",
                "Combustion as an occasional burst button, not a banked execute-phase cooldown",
            },
            notes = "No Improved Scorch debuff-stacking and no banking Combustion for a Molten Fury sub-20% execute window — both are raid-only optimizations. Icy Veins' leveling guide explicitly says Improved Scorch 'isn't essential for solo leveling' and treats Combustion as optional rather than plan-your-whole-fight-around-it. Simple Fireball spam plus Arcane Concentration's free procs replaces the max-level nuance. Single detailed source, so graded APPROX.",
            confidence = "APPROX",
            sources = { "https://www.icy-veins.com/tbc-classic/fire-mage-leveling-guide" },
        },
        {
            spec = "Frost", role = "dps",
            priority = {
                "Frostbolt spam as the entire single-target rotation — no Fireball weave",
                "Frost Nova to root anything that reaches melee, then resume kiting/Frostbolting at range",
                "Fire Blast (or Ice Lance once Shatter is talented at 25) to finish frozen/low-HP targets without waiting on the next Frostbolt cast",
                "AoE pulls: gather with Frost Nova, get 2 Blizzard casts off before it wears, then Cone of Cold/Arcane Explosion/wand to clean up survivors",
                "Icy Veins (20+) on cooldown for burst",
            },
            notes = "Icy Veins' single-target leveling guide and an independent noobtoboss guide both boil this down to 'Frostbolt until it dies' plus Frost Nova/Cone of Cold kiting — none of the max-level Ice Barrier/Winter's Chill raid-coordination nuance applies. Summon Water Elemental doesn't unlock until level 70, so it's a non-factor for nearly the entire leveling process, unlike the max-level rotation where it's summoned on every pull.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/frost-single-target-mage-leveling-guide",
                "https://noobtoboss.com/tbc-classic-frost-mage-leveling-guide/",
                "https://www.icy-veins.com/tbc-classic/frost-aoe-mage-leveling-guide",
            },
        },
    },

    WARLOCK = {
        {
            spec = "Affliction", role = "dps",
            priority = {
                "Send the pet in first to establish tanking/aggro",
                "Corruption, then Curse of Agony as the core DoT pair (Curse of the Elements only if grouped)",
                "Immolate while mana allows; drop it around level 50 when Unstable Affliction takes over as the priority DoT",
                "Siphon Life once talented, for passive self-healing while it ticks",
                "Drain Life (or wand) to finish a target and top off health while your DoTs run; Drain Soul only as the killing blow when a shard is needed",
                "Life Tap between pulls (not mid-fight) to keep mana flowing",
            },
            notes = "This is a drain-tanking rotation, not the raid DoT-uptime rotation — instead of weaving Shadow Bolt between refreshes on a tank-held target, you let your own pet tank and self-sustain via Drain Life/Siphon Life while DoTs run. Sources genuinely disagree on the best pet: Icy Veins' Affliction leveling guide recommends Voidwalker for survivability (reserving Succubus for SM/Demonic Sacrifice builds at 60+), while noobtoboss recommends Succubus throughout for its higher pet DPS and Seduction crowd control. Both are legitimate leveling choices; Voidwalker is the safer default.",
            confidence = "DISPUTED",
            -- Icy Veins' Affliction leveling guide names Voidwalker as the primary leveling pet; noobtoboss's
            -- warlock leveling guide instead recommends Succubus throughout for DPS + CC. Both named rather
            -- than one silently picked.
            sources = {
                "https://www.icy-veins.com/tbc-classic/affliction-warlock-leveling-guide",
                "https://noobtoboss.com/tbc-classic-warlock-leveling-guide/",
            },
        },
        {
            spec = "Demonology", role = "dps",
            priority = {
                "Summon Felguard (available at level 50) and send it in first — it tanks, cleaves, and can even Intercept",
                "Corruption + Immolate (mana permitting) on pull",
                "Shadow Bolt spam as the primary filler while the Felguard carries a large share of the kill",
                "Drain Life/wand to finish; Drain Soul for the killing blow when a shard is needed",
                "Fear/Howl of Terror only as emergency crowd control — it risks pulling additional mobs",
            },
            notes = "Demonology doesn't really have a distinct leveling rotation before level 50: both Icy Veins and noobtoboss agree the standard advice is to level as Affliction from 1-49 and respec into Demonology once Summon Felguard unlocks, since the tree has nothing worth leveling around before that. From 50-70 it's markedly lower-effort than the max-level Felguard rotation — pet damage/uptime carries the kill rather than a Corruption/Immolate/Shadow Bolt priority puzzle.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/demonology-warlock-leveling-guide",
                "https://noobtoboss.com/tbc-classic-warlock-leveling-guide/",
            },
        },
        {
            spec = "Destruction", role = "dps",
            priority = {
                "Immolate on pull",
                "Shadow Bolt spam as the primary filler (skip Incinerate — it needs Fire-Destro talent investment most leveling builds don't take)",
                "Conflagrate once Immolate is about to fall off, to consume it for burst rather than clip its DoT tick early",
                "Wand between casts to stretch mana rather than chain-casting Shadow Bolt",
                "Life Tap/Drain Life between or during pulls — expect more downtime than other Warlock specs",
            },
            notes = "Two independent sources actively steer players away from Destruction as a leveling spec: Icy Veins' general Warlock leveling guide calls it 'Mana-intensive' with excessive eating/drinking downtime, and noobtoboss says it 'burns through mana quickly,' making it slower to solo-quest than Affliction or Demonology. If leveled anyway, the rotation collapses to plain Immolate + Shadow Bolt spam — none of the max-level Curse of Doom opener or Fire-Destro-vs-Shadow-Destro filler branching applies.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/warlock-leveling-guide",
                "https://noobtoboss.com/tbc-classic-warlock-leveling-guide/",
            },
        },
    },

    DRUID = {
        {
            spec = "Balance", role = "dps",
            priority = {
                "Faerie Fire on pull if grouped/talented (Improved Faerie Fire) — mostly skippable solo",
                "Moonfire, then Insect Swarm (from level 20) — apply both and let them run",
                "Starfire as the main filler once learned — hits harder and is more mana-efficient per cast than Wrath despite the longer cast time",
                "Wrath instead of Starfire only pre-20, or when a target is closing to melee and you need the faster cast",
                "Force of Nature on cooldown when the treants will live out most of their duration",
                "Mana-tight: drop Moonfire first, then Faerie Fire, and finish on Starfire alone",
                "Entangling Roots to peel one of two adds so the other can be burned down solo",
            },
            notes = "Multi-dotting — spreading Moonfire across several adds while pulling more, then falling back to single-target — replaces the max-level Moonfire/Starfire/Insect Swarm priority, since Balance still has no real AoE spell while leveling. Icy Veins and an independent noobtoboss guide both converge on the same Moonfire+Insect Swarm+Starfire core and the same Starfire-over-Wrath mana-efficiency reasoning.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/balance-druid-leveling-guide",
                "https://noobtoboss.com/tbc-classic-balance-druid-leveling-guide/",
            },
        },
        {
            -- Deliberately ONE entry covering Cat Form rather than the max-level file's
            -- Feral (Cat)/Feral (Bear) split — while leveling, Cat is the default solo
            -- spec regardless of eventual raid role; Bear gets a brief mention as the
            -- dungeon-tanking option rather than a fully separate leveling rotation.
            spec = "Feral (Cat)", role = "dps",
            priority = {
                "Open from Prowl with Pounce (stun) or Ravage/Shred from behind",
                "Before level 50 (no Mangle yet): build combo points with Claw, optionally weaving Rake's bleed on tougher targets",
                "From level 50 on: apply Mangle (Cat) first and keep it up — it becomes your combo-point builder via Shred (Claw when you can't get behind the target)",
                "At 4-5 combo points: Rip on anything that will outlive its duration, Ferocious Bite to finish anything already low",
                "Powershift (drop and re-enter Cat Form) when Energy bottoms out — Furor refunds ~40 Energy instantly, faster than waiting on regen",
                "Shift out between pulls to self-heal/reduce downtime; Bear Form is for defense and dungeon tanking, not the primary solo damage form",
            },
            notes = "Cat Form is the default recommended way to solo-level a Druid over Balance or Restoration, since Feral 'doubles as a tank spec' and needs little food/water downtime — both sources agree on this and on the Mangle/Shred/Rip/Bite framework once Mangle unlocks at 50, so this is written as a single leveling entry covering Cat Form rather than splitting Cat/Bear the way the max-level raid rotation does. Bear Form gets only a brief mention here since while leveling it's a defensive/dungeon-tanking tool, not a distinct solo damage rotation — a player leveling primarily as a group tank should lean on the max-level Feral (Bear) entry, simplified for missing high-end talents. One minor, non-critical disagreement: noobtoboss's pre-50 rotation weaves in Rake, Icy Veins' does not — consistent with the max-level file's note that Rake underperforms Claw/Shred generally in TBC.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/feral-druid-leveling-guide",
                "https://noobtoboss.com/tbc-classic-feral-druid-leveling-guide/",
                "https://www.icy-veins.com/tbc-classic/druid-leveling-guide",
            },
        },
        {
            spec = "Restoration", role = "heal",
            priority = {
                "Leveling through dungeons (the recommended path for this spec): Rejuvenation/Regrowth on the tank, Healing Touch for big/emergency heals, Nature's Swiftness to make one instant in a pinch",
                "Maintain Mark of the Wild/Thorns on the group",
                "Faerie Fire to help the tank's threat if needed",
                "If soloing anyway: Moonfire/Wrath/Faerie Fire as filler damage instead of a real DPS rotation — expect it to be slow",
                "Shift to Cat Form between heals for movement or emergency melee while soloing",
            },
            notes = "Both sources explicitly recommend AGAINST solo-leveling as Restoration: Icy Veins says 'we recommend the use of a different specialization if you intend to solo level,' and an independent guide calls solo Resto 'extremely slow and frustrating,' instead pointing to dungeon-group leveling as a healer or a temporary respec to Balance/Feral for solo stretches. Lifebloom, Swiftmend, and Tranquility — all core to the max-level HPS rotation — are higher-level talent/spell unlocks not available for most of the leveling process, so this entry is necessarily a simpler Rejuvenation/Regrowth/Healing Touch toolkit rather than a scaled-down copy of the raid rotation.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/restoration-druid-leveling-guide",
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-resto-druid-leveling",
            },
        },
    },
}
