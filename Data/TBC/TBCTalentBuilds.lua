-- ToonAge/Data/TBCTalentBuilds.lua (Anniversary — TBC Classic / Interface 20506)
-- Recommended talent builds per class, by role and context (PvE raid vs. PvP
-- arena). New file — not yet wired into a UI module or listed in the TOC.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── CONFIDENCE GRADING ────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Researched 2026-09-07 against current (2025-2026) TBC Classic Anniversary
-- guides — Wowhead TBC Classic, Icy Veins TBC Classic, Warcraft Tavern,
-- wowtbc.gg, Skill Capped, FrostyBoost, PvPSkills, and others, cited per
-- entry. Added 2026-09-09 to the reference set at the user's request: the
-- "Loon Best In Slot (BIS)" in-game addon (github.com/lgallucci/LoonBestInSlot,
-- curseforge.com/wow/addons/loon-best-in-slot — itself built on Wowhead's BiS
-- guides, TBC Classic supported) as a cross-check for gear-driven build
-- choices. Every build below is graded:
--
--   CONFIRMED   Point allocation independently corroborated by 2+ sources
--               that agree with each other and sum correctly to 61 (the
--               level-70 talent point total).
--   APPROX      Real, sourced build, but the exact point allocation came
--               from only one source, or independent sources gave slightly
--               different totals for the secondary/flex points. The tree
--               identity and capstone/key talents are still solid.
--   DISPUTED     Sources genuinely disagree on which build is "standard,"
--               not just on exact numbers — both/all named alternatives are
--               listed rather than one being silently picked.
--
-- Several entries below corrected a wrong assumption this project started
-- with, caught by the research rather than confirmed by it:
--   Warrior PvP  is Arms, not a Fury/Protection hybrid.
--   Hunter PvP   is Marksmanship (or a Survival/MM hybrid) at high rating,
--                not pure Survival — Survival is the PvE raid standard only.
--   Rogue PvP    is Subtlety, not "Combat Dagger" — no current guide
--                recommends Combat for arena.
-- Treat any future "this class's PvP spec is obviously X" assumption the
-- same way: verify against current TBC-specific guides before encoding it,
-- not general WoW knowledge or vanilla/original-TBC-era folklore.
--
-- Individual per-talent point costs were, in a number of cases, read from
-- guide prose rather than a live talent-calculator string (several guide
-- sites render their exact tree as a JS widget that doesn't scrape as
-- text). Tree-level allocation totals and named key/capstone talents are
-- solid; a `verifyPoints = true` flag marks builds where a secondary
-- talent's exact rank should be spot-checked against a live TBC talent
-- calculator before being treated as gospel.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.TalentBuilds = {

    -- ════════════════════════════════════════════════════════════════════
    WARRIOR = {
        {
            label = "Fury — Raid PvE DPS (standard)", context = "pve", role = "dps",
            allocation = "Arms 21 / Fury 40 / Protection 0", confidence = "CONFIRMED",
            keyTalents = {
                "Cruelty 5/5", "Unbridled Wrath 5/5", "Commanding Presence 5/5",
                "Dual Wield Specialization 5/5", "Enrage 5/5", "Sweeping Strikes 1/1",
                "Weapon Mastery 2/2", "Flurry 5/5", "Bloodthirst 1/1 (capstone)",
                "Improved Berserker Stance 5/5",
                "-- Arms dip: Improved Heroic Strike 3/3, Deflection 5/5, Iron Will 5/5,",
                "Deep Wounds 3/3, Impale 2/2, Death Wish 1/1, Anger Management 1/1",
            },
            notes = "The default raid DPS spec. Sources' itemized talent lists summed to ~39/20 rather than the stated 40/21 — treat the last 1-2 points as unplaced filler (commonly Booming Voice), not a fixed spot.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/warrior/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/fury-warrior-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-fury-warrior-talents-builds/",
            },
        },
        {
            label = "Arms — Raid PvE DPS (niche: Blood Frenzy debuff / cleave)", context = "pve", role = "dps",
            allocation = "Arms 33 / Fury 28 / Protection 0", confidence = "APPROX",
            keyTalents = {
                "Mortal Strike 1/1 (capstone)", "Blood Frenzy (unique raid-wide +4% physical damage taken debuff)",
                "Improved Slam (needed for the 2H Slam-weave rotation)", "Sweeping Strikes 1/1",
                "Impale, Death Wish (shared with the Fury build)",
            },
            notes = "Real niche, not the default: some raids run one Arms warrior specifically for the Blood Frenzy debuff or execute/cleave-heavy fights. A dual-wield Arms variant exists too, reported 3-5% lower than the two-hand version. Only Wowhead gave a full itemized breakdown.",
            sources = { "https://www.wowhead.com/tbc/guide/classes/warrior/dps-talent-builds-pve" },
        },
        {
            label = "Protection — Raid/Dungeon Tank", context = "pve", role = "tank",
            allocation = "Arms 12 / Fury 5 / Protection 43", confidence = "DISPUTED",
            keyTalents = {
                "Shield Slam 1/1", "Improved Sunder Armor 3/3", "Defiance 3/3",
                "Anticipation 5/5", "Focused Rage 3/3", "Shield Mastery, One-Handed Weapon Specialization",
                "Vitality, Toughness", "Last Stand 1/1", "Concussion Blow 1/1",
                "Situational: Improved Demoralizing Shout OR Improved Defensive Stance (physical vs. magic fights)",
            },
            notes = "12/5/43 is the standard default; two other splits (10/10/41 and 17/3/41) are also named by Wowhead as recognized situational alternates — treat all three as legitimate, not a single hard number. verifyPoints: Protection tank talent costs came from guide prose, not a scraped calculator.",
            verifyPoints = true,
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/warrior/protection/tank-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/protection-warrior-tank-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-protection-warrior-talents-builds/",
            },
        },
        {
            label = "Arms — Arena/PvP (standard; corrects the old 'Fury/Prot hybrid' assumption)", context = "pvp", role = "dps",
            allocation = "Arms 41 / Fury 17 / Protection 3 (close cousin: 41/20/0)", confidence = "CONFIRMED",
            keyTalents = {
                "Mortal Strike 1/1 (mandatory, 50% healing-reduction debuff)",
                "Mace Specialization 5/5", "Second Wind (rage + self-heal on being stunned)",
                "Tactical Mastery (retains rage on stance swap)", "Death Wish 1/1",
            },
            notes = "No current source recommends a Fury/Protection hybrid for arena — Wowhead's own Protection PvP page says Protection warriors should just use their raid tank build or switch to Arms. Alternate burst build 'Endless Rage' (37 Arms / 21 Fury / 0 Protection) trades Second Wind-style survivability for Fury damage talents. 33/28/0 (same shape as the PvE Arms niche build) is cited specifically for battlegrounds/5v5 rather than 2v2/3v3.",
            sources = {
                "https://frostyboost.com/blog/tbc-warrior-pvp-guide",
                "https://hitcap.io/tbc/pvp/warrior/",
                "https://www.mmogah.com/news/tbc-classic-anniversary/tbc-anniversary-arms-warrior-pvp-guide-unleash-the-burst-damage-build",
                "https://www.wowhead.com/tbc/guide/classes/warrior/dps-pvp-arena",
                "https://www.icy-veins.com/tbc-classic/arms-warrior-pvp-guide",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    PALADIN = {
        {
            label = "Holy — Raid PvE Healing", context = "pve", role = "healer",
            allocation = "Holy 45 / Protection 11 / Retribution 5 (alt: Holy 41 / Protection 20 / Retribution 0)", confidence = "DISPUTED",
            keyTalents = {
                "Spiritual Focus 5/5", "Healing Light 3/3", "Illumination 5/5",
                "Divine Favor 1/1", "Sanctified Light 3/3", "Holy Power 5/5",
                "Light's Grace 3/3", "Holy Shock 1/1", "Holy Guidance 5/5",
                "Divine Illumination 1/1 (41-point capstone)",
            },
            notes = "Real disagreement over where the 'flex' points outside core Holy go: dip into Retribution for Improved Blessing of Might, or deeper Protection for Blessing of Kings — both legitimate depending on whether another raider already covers Kings/Might. A third variant (~40/10/21) reaches into Retribution for Sanctity Aura when no Ret Paladin is present.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/holy-paladin-healer-pve-spec-builds-talents",
                "https://www.wowtbcarena.com/guides/paladin/holy/pve",
            },
        },
        {
            -- Added 2026-09-09: reported missing entirely — the Rotation tab
            -- (Data/TBCRotations.lua) has always had a Retribution DPS entry,
            -- but this file had no matching talent build, so a Retribution
            -- Paladin's Talents tab fell back to "show every Paladin spec"
            -- instead of a targeted build. Icy Veins/Wowhead/Warcraft Tavern
            -- render their talent trees as JS widgets that didn't scrape as
            -- plain text (same limitation noted elsewhere in this file), so
            -- the exact point totals are not independently confirmed from a
            -- scraped calculator — graded APPROX with verifyPoints.
            label = "Retribution — Raid PvE DPS (niche/off-spec; TBC Ret is a famously weak raid DPS spec)", context = "pve", role = "dps",
            allocation = "Deep Retribution capstone build (through Seal of Command / Crusader Strike) with "
                .. "a small Protection dip for Blessing of Kings + Guardian's Favor and a Holy dip for "
                .. "Divine Strength — exact point totals not independently confirmed from a scraped calculator",
            confidence = "APPROX",
            verifyPoints = true,
            keyTalents = {
                "Seal of Command 1/1 (capstone)", "Crusader Strike 1/1",
                "Benediction 5/5 (mana cost)", "Improved Seal of the Crusader 3/3 (party-wide crit buff)",
                "Sanctified Judgement 3/3 (mana refund)", "Two-Handed Weapon Specialization 5/5",
                "-- Protection dip: Blessing of Kings 1/1, Guardian's Favor 2/2",
                "-- Holy dip: Divine Strength (Str)",
            },
            notes = "TBC Retribution is well-documented as a weak raid DPS spec — it doesn't come into its own until Wrath. This entry exists for solo/leveling/off-spec/5-man play, matching why Data/TBCRotations.lua already carries a Retribution DPS priority list. It is not a recommendation to bring a Ret Paladin as a raid main-spec.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/paladin/retribution/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/retribution-paladin-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-retribution-paladin-talents-builds/",
            },
        },
        {
            label = "Protection — Raid/Dungeon Tank", context = "pve", role = "tank",
            allocation = "Holy 0 / Protection 49 / Retribution 12", confidence = "CONFIRMED",
            keyTalents = {
                "Redoubt 5/5", "Toughness 5/5", "Improved Righteous Fury 3/3",
                "Anticipation 5/5", "One-Handed Weapon Specialization 5/5", "Reckoning 5/5",
                "Combat Expertise 5/5", "Improved Holy Shield 2/2", "Holy Shield 1/1",
                "Ardent Defender 5/5", "Avenger's Shield 1/1",
            },
            notes = "0/49/12 (the 'Avenger's Shield' build) is the standard, agreed by two independent sources. A 'Sanctity Aura' hybrid (~0/33/28) sacrifices survivability to bring the raid-wide Sanctity Aura buff when no dedicated bot exists for it — exact split on that variant is not well-pinned-down, treat it as approximate.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/paladin/tank-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/protection-paladin-tank-pve-spec-builds-talents",
                "https://www.wowtbcarena.com/guides/paladin/protection/pve",
                "https://nottoolateforclassic.com/talents/",
            },
        },
        {
            label = "Holy — Arena/PvP (dominant Paladin PvP spec)", context = "pvp", role = "healer",
            allocation = "Holy 41 / Protection 20 / Retribution 0", confidence = "CONFIRMED",
            keyTalents = {
                "Divine Intellect 5/5", "Spiritual Focus 5/5", "Illumination 5/5",
                "Divine Favor 1/1", "Holy Shock 1/1", "Divine Illumination 1/1 (capstone)",
                "Improved Devotion Aura 5/5", "Guardian's Favor 2/2 (BoP/BoF cooldown+range)",
                "Improved Concentration Aura 3/3 (covers Holy Paladin's biggest PvP weakness: getting interrupted/silenced while casting)",
            },
            notes = "Highest-confidence PvP number in this file — 4 independent sources agree on 41/20/0. Retribution has a real but secondary PvP niche as a burst/support off-node spec; I could not confidently pin an exact point allocation for it, so it's omitted rather than guessed.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-pvp-arena",
                "https://www.icy-veins.com/tbc-classic/holy-paladin-pvp-guide",
                "https://wowtbc.gg/pvp-class-guides/holy-paladin/",
                "https://www.timelessazeroth.com/guides/classes/paladin/holy/pvp/talents",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    HUNTER = {
        {
            label = "Survival — Raid PvE DPS (standard)", context = "pve", role = "dps",
            allocation = "Beast Mastery 0 / Marksmanship 20 / Survival 41", confidence = "CONFIRMED",
            keyTalents = {
                "Expose Weakness (Survival — the reason to go Survival: raid-wide physical DPS buff)",
                "Mortal Shots 5/5 (Marksmanship, +30% crit damage)",
                "Improved Hunter's Mark (only if you're the raid's sole/primary Hunter, else take Efficiency 5/5)",
                "Surefooted 3/3", "Readiness (capstone, resets cooldowns)",
                "Killer Instinct / Lightning Reflexes (Agility/crit, also scale Expose Weakness proc rate)",
            },
            notes = "Marksmanship as a standalone raid spec has no niche — Icy Veins calls it outright 'the overall worst PvE spec.' It's only ever a 20-point donor tree inside the Survival build.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/hunter/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/survival-hunter-dps-pve-spec-builds-talents",
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-survival-hunter-talents",
            },
        },
        {
            -- Added 2026-09-09: same gap pattern as Retribution Paladin —
            -- Data/TBCRotations.lua has a Beast Mastery DPS entry but this
            -- file had no matching build, so a BM Hunter fell back to
            -- "show every Hunter spec." Exact point totals not independently
            -- confirmed from a scraped calculator (JS-widget limitation).
            label = "Beast Mastery — Raid PvE DPS (niche; pet-focused, weaker than Survival)", context = "pve", role = "dps",
            allocation = "Beast Mastery capstone build (through Bestial Wrath / The Beast Within) with a "
                .. "20-point Marksmanship floor for Mortal Shots — exact point totals not independently "
                .. "confirmed from a scraped calculator",
            confidence = "APPROX",
            verifyPoints = true,
            keyTalents = {
                "Bestial Wrath 1/1 (capstone)", "The Beast Within (pairs with Bestial Wrath)",
                "Frenzy 4/5 (pet haste — deliberately not 5/5; the 5th point is redundant once 100% uptime is reached)",
                "Unleashed Fury 5/5", "Ferocity 5/5", "Improved Mend Pet",
                "-- Marksmanship floor: Mortal Shots 5/5 (mandatory in every PvE Hunter build)",
                "-- flex: Efficiency OR Improved Hunter's Mark (situational, same tradeoff as the Survival build)",
            },
            notes = "Real but secondary to Survival for raid DPS — Icy Veins and Warcraft Tavern both frame Beast Mastery as pet-focused and lower-ceiling than Survival's Expose Weakness raid buff. This is the spec Data/TBCSecondaryRoles.lua's own Hunter pet-off-tanking entry assumes (deep Beast Mastery investment for a tanky pet), so it earns its own build entry rather than only existing as a rotation.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-beast-mastery-hunter-talents-builds/",
                "https://wowtbc.gg/class-guides/beast-mastery-hunter/",
            },
        },
        {
            label = "Marksmanship (or SV/MM hybrid) — Arena/PvP (corrects the old 'pure Survival' assumption)", context = "pvp", role = "dps",
            allocation = "~7 Beast Mastery / 43 Marksmanship / 11 Survival", confidence = "DISPUTED",
            keyTalents = {
                "Improved Revive Pet (keeps your pet alive through burst)",
                "Viper Sting (core mana-drain tool)", "Improved Stings",
                "Aimed Shot", "Scatter Shot", "Silencing Shot",
                "-- Survival dip: Deterrence, Clever Traps (10.4s Freezing Trap), Hawk Eye",
            },
            notes = "IMPORTANT: current (2026) guides say Marksmanship, not pure Survival, is the top-end arena spec — Survival/SV-MM hybrid (built around Wyvern Sting for CC-chain lockdown) is a secondary control-oriented alternative, not the standard. I found no current credible source calling pure Survival the PvP standard; that looks like an outdated assumption. Exact point splits varied across sources (7/43/11, 0/41/20 'MM Trueshot', 0/26/35 SV/MM hybrid) — re-verify against a live calculator before hardcoding.",
            verifyPoints = true,
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/hunter/dps-pvp-arena",
                "https://www.icy-veins.com/tbc-classic/marksmanship-hunter-pvp-guide",
                "https://www.icy-veins.com/tbc-classic/survival-hunter-pvp-guide",
                "https://www.skill-capped.com/wowarticles/tbc/guides/hunter-pvp-guide/",
                "https://frostyboost.com/blog/wow-anniversary-hunter-pvp-guide",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    ROGUE = {
        {
            label = "Combat — Raid PvE DPS (standard)", context = "pve", role = "dps",
            allocation = "Combat 41 / Assassination 20 / Subtlety 0 (variant: 41/15/5)", confidence = "APPROX",
            keyTalents = {
                "Combat Potency 3/3 (offhand procs generate Energy)",
                "Sword Specialization / Weapon Expertise 2/2 (weapon-dependent)",
                "Adrenaline Rush 1/1", "Blade Flurry 1/1", "Precision 5/5",
                "Dual Wield Specialization 5/5", "Improved Sinister Strike 2/2, Improved Slice and Dice 3/3",
            },
            notes = "20/41/0 is the dominant split; one source instead gives 15/41/5 (fewer Assassination points, +Camouflage). A full Assassination/Mutilate build (41/20/0) is a legitimate lower-ceiling alternative for players who prefer the dagger playstyle, not a specialized niche.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/rogue/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/rogue-dps-pve-spec-builds-talents",
                "https://expcarry.com/tbc-anniversary-rogue-pve-guide",
            },
        },
        {
            -- Added 2026-09-09: same gap pattern as above — the Combat
            -- build's own notes already namedropped "a full Assassination/
            -- Mutilate build (41/20/0) is a legitimate lower-ceiling
            -- alternative," but it never got its own entry, and
            -- Data/TBCRotations.lua has a standalone Assassination DPS
            -- rotation with nothing in this file to match it against.
            label = "Assassination — Raid PvE DPS (Mutilate build; legitimate lower-ceiling alternative to Combat)", context = "pve", role = "dps",
            allocation = "Assassination 41 (Mutilate capstone) / Combat 20 / Subtlety 0 — mirrors the Combat "
                .. "build's tree shape in reverse; exact point totals not independently confirmed from a "
                .. "scraped calculator",
            confidence = "APPROX",
            verifyPoints = true,
            keyTalents = {
                "Mutilate 1/1 (capstone — replaces Sinister Strike as the finisher-builder, requires Daggers)",
                "Cold Blood 1/1", "Seal Fate 5/5", "Lethality 5/5 (crit damage on finishers)",
                "Vile Poisons 5/5", "Puncturing Wounds", "Improved Expose Armor",
                "-- Combat dip: Combat Potency 3/3, Dual Wield Specialization",
            },
            notes = "Dagger-only playstyle, not a specialized raid-utility niche the way Arms Warrior's Blood Frenzy dip is — this is a straight lower-ceiling alternative to the Combat standard for players who prefer Mutilate. The Combat build entry above already flags this build's existence; this gives it its own sourced entry instead of leaving it buried in another spec's notes.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/rogue-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-assassination-rogue-talents-builds/",
                "https://wowtbc.gg/class-guides/assassination-rogue/",
            },
        },
        {
            label = "Subtlety — Arena/PvP (corrects the old 'Combat Dagger' assumption)", context = "pvp", role = "dps",
            allocation = "Subtlety 41 / Assassination 20 / Combat 0", confidence = "CONFIRMED",
            keyTalents = {
                "Vile Poisons 5/5 (resists poison dispels — the reason for the Assassination dip)",
                "Shadowstep 1/1", "Preparation 1/1 (resets Vanish/Sprint/Evasion/Cold Blood)",
                "Premeditation 1/1", "Cheat Death 3/3", "Master of Subtlety 3/3",
            },
            notes = "No current TBC-specific PvP guide recommends Combat Dagger or Mutilate for arena — one source calls Subtlety 'the only PvP-viable Rogue spec.' A close variant (41/15/5) is also cited (~90% play rate per PvPSkills); comp-specific deviations exist (14/3/44 vs. Shadow Priest comps, 17/0/44 vs. Rogue-Mage) but 20/0/41 is the general-purpose baseline.",
            sources = {
                "https://www.wowhead.com/tbc/guide/rogue-dps-pvp-arena-guide-burning-crusade-classic-wow",
                "https://www.icy-veins.com/tbc-classic/subtlety-rogue-pvp-guide",
                "https://www.pvpskills.com/builds/rogue",
                "https://frostyboost.com/blog/wow-anniversary-rogue-pvp-guide",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    PRIEST = {
        {
            label = "Holy — Raid PvE Healing (primary, 'Circle of Healing' build)", context = "pve", role = "healer",
            allocation = "Discipline 20 / Holy 41 / Shadow 0 (alt: Disc 23 / Holy 38, 'Improved Divine Spirit')", confidence = "CONFIRMED",
            keyTalents = {
                "Circle of Healing 1/1 (capstone, instant AoE heal)", "Spiritual Guidance 5/5",
                "Spiritual Healing 3/3", "Holy Reach 2/2", "Inspiration 3/3",
                "Improved Renew 3/3", "Meditation 3/3", "Spirit of Redemption 1/1",
            },
            notes = "The dominant raid build. The Improved Divine Spirit alt trades Circle of Healing for a raid-wide Spirit buff when the raid already has enough AoE healing.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/priest/healer-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/holy-priest-healer-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-holy-priest-healing-talents-builds/",
            },
        },
        {
            label = "Discipline — Raid PvE support role (secondary, not a co-equal raid healer)", context = "pve", role = "healer",
            allocation = "No fixed point split published — Discipline invested just deep enough for Power Infusion (~tier 7) or Pain Suppression (deeper)", confidence = "DISPUTED",
            keyTalents = { "Power Infusion 1/1 (primary reason to bring Disc to raid)", "Pain Suppression 1/1", "Improved Power Word: Shield" },
            notes = "Not a mirror of the Holy raid build. Guides describe Discipline's raid role as 'one per raid, as a Power Infusion/Pain Suppression bot,' not a full-time healing allocation — Holy dominates once AoE-heavy content matters. Don't encode a fake 41/20/0-style raid-Disc split; there isn't a consensus one.",
            sources = {
                "https://www.warcrafttavern.com/tbc/guides/pve-discipline-priest-healing-guide/",
                "https://www.icy-veins.com/tbc-classic/priest-class-overview",
            },
        },
        {
            label = "Shadow — Raid PvE DPS", context = "pve", role = "dps",
            allocation = "Discipline 14 / Holy 0 / Shadow 47", confidence = "CONFIRMED",
            keyTalents = {
                "Shadowform 1/1 (capstone)", "Misery 5/5 (raid-wide magic-damage-taken debuff — the 'bring a Shadow Priest' reason)",
                "Shadow Weaving ~5/5", "Vampiric Touch 1/1", "Mind Blast 5/5", "Darkness 5/5",
                "Meditation 3/3",
            },
            notes = "Once comfortably above the 16% spell hit cap, points move from Shadow Focus into Shadow Power for more damage — a real gear-dependent swap, not a fixed allocation.",
            verifyPoints = true,
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/priest/shadow/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/shadow-priest-dps-pve-spec-builds-talents",
            },
        },
        {
            label = "Discipline — Arena/PvP (dominant Priest PvP spec)", context = "pvp", role = "healer",
            allocation = "Discipline 41 / Holy 20 / Shadow 0 (variant: Disc 41 / Shadow 20, 'Blackout')", confidence = "CONFIRMED",
            keyTalents = {
                "Pain Suppression 1/1 (capstone, core defensive cooldown)", "Power Infusion 1/1",
                "Enlightenment 5/5", "Silent Resolve 5/5 (harder-to-dispel buffs — top arena utility pick)",
                "Martyrdom, Improved Inner Fire", "Mental Agility 3/3",
            },
            notes = "Every PvP-focused source treats Discipline as the default Priest arena spec. Shadow Priest PvP is a confirmed real but secondary niche (Discipline 20 / Holy 0 / Shadow 41, 'PvP Utility' build using Blackout stun procs) — viable in specific comps, not dominant.",
            sources = {
                "https://www.wowtbcarena.com/guides/priest/discipline/pvp",
                "https://wowtbc.gg/pvp-class-guides/discipline-priest/",
                "https://www.icy-veins.com/tbc-classic/discipline-priest-pvp-guide",
                "https://www.timelessazeroth.com/guides/classes/priest/discipline/pvp/talents",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    SHAMAN = {
        {
            label = "Restoration — Raid PvE Healing", context = "pve", role = "healer",
            allocation = "Elemental 8 / Enhancement 0 / Restoration 53 (alt: Elem 0 / Enh 12 / Resto 49, 'Enhancing Totems')", confidence = "APPROX",
            keyTalents = {
                "Improved Chain Heal 3/3 ('a must have when raid healing')", "Mana Tide Totem",
                "Totemic Mastery 1/1", "Nature's Swiftness 1/1", "Ancestral Healing 3/3",
                "Healing Focus 3/3", "Tidal Mastery 5/5", "Totemic Focus 5/5",
            },
            notes = "The Enhancing Totems variant is used when the raid lacks an Enhancement Shaman providing melee totems. Numeric tree totals came from a single scrapeable source; the talent priority list is corroborated by a second.",
            verifyPoints = true,
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/shaman/healer-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/restoration-shaman-healer-pve-spec-builds-talents",
            },
        },
        {
            label = "Elemental — Raid PvE DPS (standard)", context = "pve", role = "dps",
            allocation = "Elemental 41 / Enhancement 0 / Restoration 20", confidence = "CONFIRMED",
            keyTalents = {
                "Totem of Wrath 1/1 (capstone, raid-wide spell hit + crit buff)",
                "Elemental Fury", "Elemental Mastery 1/1 (on-demand guaranteed crit)",
                "Elemental Focus 1/1", "Unrelenting Storm", "Elemental Precision",
                "Tidal Mastery 5/5 (from the Restoration dip)",
            },
            notes = "Enhancement is a real but secondary raid role (not top-tier DPS): melee contribution plus Windfury/Unleashed Rage group support. Recommended raid Enhancement build: Elemental 17 / Enhancement 44 / Restoration 0.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/elemental-shaman-dps-pve-spec-builds-talents",
                "https://www.invenglobal.com/articles/14456/guide-elemental-enhancement-shaman-wow-tbc-classic-talents-gear-rotation",
            },
        },
        {
            -- Added 2026-09-09: the Elemental PvE entry's own notes already
            -- named this exact build ("Recommended raid Enhancement build:
            -- Elemental 17 / Enhancement 44 / Restoration 0") but it was
            -- never promoted to its own entry, so Data/TBCRotations.lua's
            -- standalone Enhancement DPS rotation had nothing to match
            -- against in this file.
            label = "Enhancement — Raid PvE DPS (secondary raid role: melee + Windfury/Unleashed Rage support)", context = "pve", role = "dps",
            allocation = "Elemental 17 / Enhancement 44 / Restoration 0 (an alternate Restoration-dip build "
                .. "trades some of the Elemental points for deeper totem support via Totemic Focus)",
            confidence = "APPROX",
            verifyPoints = true,
            keyTalents = {
                "Stormstrike 1/1 (capstone — extra attack that also debuffs the target for +20% Nature damage taken)",
                "Dual Wield 1/1", "Unleashed Rage 3/3 (raid-wide melee attack power buff)",
                "Shamanistic Rage 1/1", "Flurry 5/5", "Weapon Mastery",
                "-- Elemental dip: Elemental Devastation, Reverberation (shock cooldown, smooths totem-twisting)",
                "-- Restoration-variant alt: Totemic Focus, Totemic Mastery (stronger totem uptime, less personal damage)",
            },
            notes = "Real but secondary raid role, same framing as the Elemental entry above: melee contribution plus the Windfury/Unleashed Rage group buffs, not top-tier personal DPS. Two build variants exist (Elemental-dip for smoother shock/Stormstrike totem-twisting vs. Restoration-dip for stronger totem support on long fights) — neither guide crowns one as universally better.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-enhancement-shaman-talents-builds/",
                "https://www.invenglobal.com/articles/14456/guide-elemental-enhancement-shaman-wow-tbc-classic-talents-gear-rotation",
            },
        },
        {
            label = "Restoration — Arena/PvP (dominant Shaman PvP spec)", context = "pvp", role = "healer",
            allocation = "'Toughness' (2v2): Elem 0 / Enh 20 / Resto 41  |  'Mana Tide' (3v3/5v5/BG): Elem 0 / Enh 9 / Resto 52", confidence = "CONFIRMED",
            keyTalents = {
                "Toughness (movement-impair duration reduction + armor)", "Improved Ghost Wolf",
                "Guardian Totems (Grounding Totem cooldown)", "Nature's Guidance (PvP hit)",
                "Mana Tide Totem", "Nature's Guardian (passive self-heal)",
            },
            notes = "Confirmed dominant arena spec — two independent sources converge on both numeric splits. Elemental and Enhancement PvP are real but secondary niches (Elemental thrives in 5v5/BG where casting is safer; Enhancement viable in 3v3/5v5 melee-cleave comps, weak in 2v2).",
            sources = {
                "https://www.wowhead.com/tbc/guide/shaman-healer-pvp-arena-guide-burning-crusade-classic-wow",
                "https://www.timelessazeroth.com/guides/classes/shaman/restoration/pvp/talents",
                "https://www.icy-veins.com/tbc-classic/restoration-shaman-pvp-guide",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    MAGE = {
        {
            -- Added 2026-09-09: the Fire entry below has said since it was
            -- written that "Arcane, not Fire or Frost, is the actual #1 raid
            -- DPS spec... not researched here since it wasn't asked for" —
            -- an explicitly flagged, self-acknowledged gap. Filling it now.
            -- Confirmed directly from a live Icy Veins fetch (not just guide
            -- prose), unlike most of the other entries added in this pass.
            label = "Arcane — Raid PvE DPS (the actual #1 raid DPS Mage spec, ahead of Fire)", context = "pve", role = "dps",
            allocation = "Arcane 40 / Fire 0 / Frost 21 ('Arcane IV' / Arcane-Frost hybrid)", confidence = "CONFIRMED",
            keyTalents = {
                "Arcane Subtlety 2/2 (threat reduction + resist debuff)", "Arcane Focus 5/5 (Arcane spell hit)",
                "Arcane Power 1/1 (capstone — 30% damage cooldown, at the cost of +30% damage taken)",
                "Spell Power 3/3 (50% increased critical damage on Arcane spells)", "Presence of Mind 1/1",
                "-- Frost dip: Improved Frostbolt 5/5, Icy Veins 1/1 (casting speed + pushback immunity), "
                    .. "Cold Snap 1/1 (resets Icy Veins for a second burst window), Ice Shards 5/5",
            },
            notes = "Confirmed directly from Icy Veins' spec-builds page: Arcane Blast spammed during Arcane Power + Icy Veins/Bloodlust is the build's burst window, with Frostbolt as the between-cooldowns filler. This is the spec the Fire entry below has been pointing at since it was written.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/arcane-mage-dps-pve-spec-builds-talents",
                "https://www.icy-veins.com/tbc-classic/arcane-mage-dps-pve-guide",
                "https://www.warcrafttavern.com/tbc/guides/pve-arcane-mage-talents-builds/",
            },
        },
        {
            label = "Fire — Raid PvE DPS (#2 behind Arcane; Scorch debuff provider)", context = "pve", role = "dps",
            allocation = "Arcane 2 / Fire 48 / Frost 11", confidence = "APPROX",
            keyTalents = {
                "Ignite 5/5", "Combustion 3/3", "Molten Fury 2/2", "Improved Fireball 5/5",
                "Empowered Fireball 3/3", "Master of Elements 3/3", "Improved Scorch 3/3 (essential if others in the raid deal Fire damage)",
                "Critical Mass 3/3", "Fire Power 5/5", "Pyroblast 1/1", "Icy Veins 1/1 (Frost dip)",
            },
            notes = "Arcane, not Fire or Frost, is the actual #1 raid DPS spec ('absolutely the top-level spec' per Wowhead/Icy Veins) — see the Arcane entry above, added 2026-09-09 to close what had been a flagged, unfilled gap in this file. Fire is the real, commonly-used #2. An 'Arcane Fire' niche variant (40/17/3) stays mostly Arcane while still picking up the Scorch debuff.",
            verifyPoints = true,
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/fire-mage-dps-pve-spec-builds-talents",
            },
        },
        {
            label = "Frost — Raid PvE DPS (contested viability)", context = "pve", role = "dps",
            allocation = "Arcane 18 / Fire 0 / Frost 43", confidence = "DISPUTED",
            keyTalents = {
                "Improved Frostbolt 5/5", "Piercing Ice 3/3", "Ice Shards 5/5",
                "Elemental Precision 3/3", "Summon Water Elemental 1/1 (capstone)",
                "Icy Veins 1/1", "Cold Snap 1/1",
                "-- Arcane dip: Arcane Concentration 5/5, Arcane Meditation 3/3",
            },
            notes = "Genuine source disagreement, not just numbers: Wowhead's own overview page calls deep-Frost raid DPS non-viable for end-game ('largely only viable in PvP'), while its build-listing page describes the same build without disclaiming it, and Icy Veins takes a middle position ('decent... can burst well in short fights'). Treat Frost-PvE as real but niche/contested, not mainstream like Arcane/Fire.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-talent-builds-pve",
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-overview-pve",
                "https://www.icy-veins.com/tbc-classic/frost-mage-dps-pve-spec-builds-talents",
            },
        },
        {
            label = "Frost — Arena/PvP (dominant Mage PvP spec)", context = "pvp", role = "dps",
            allocation = "Arcane 17 / Fire 0 / Frost 44", confidence = "CONFIRMED",
            keyTalents = {
                "Ice Block 1/1", "Shatter 5/5 (enables the shatter-combo burst)",
                "Improved Blizzard / Blizzard slow 3/3", "Permafrost 3/3", "Improved Frost Nova 3/3",
                "Ice Barrier 1/1", "Icy Veins 1/1", "Cold Snap 1/1", "Summon Water Elemental 1/1",
                "Winter's Chill 5/5", "-- Arcane dip: Improved Counterspell, Arcane Fortitude",
            },
            notes = "The one point of unanimous agreement across every PvP source checked — no dispute found on Frost being the standard arena Mage spec.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/mage/dps-pvp-arena",
                "https://www.icy-veins.com/tbc-classic/frost-mage-pvp-guide",
                "https://www.skill-capped.com/wowarticles/tbc/guides/frost-mage-pvp-guide/talents/",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    WARLOCK = {
        {
            label = "Affliction — Raid PvE DPS (most popular)", context = "pve", role = "dps",
            allocation = "Affliction 41 / Demonology 0 / Destruction 20 (alt 'Ruin': 40/0/21)", confidence = "CONFIRMED",
            keyTalents = {
                "Suppression 3-5/5", "Improved Corruption 5/5", "Nightfall 2/2",
                "Empowered Corruption 3/3", "Shadow Mastery 5/5", "Malediction 3/3 (Curse of Elements to 13%)",
                "Unstable Affliction 1/1 (capstone)",
                "-- Destruction dip: Improved Shadow Bolt 5/5, Bane 5/5, Devastation 5/5, Shadowburn 1/1",
            },
            notes = "The Ruin variant (40/0/21) drops Dark Pact/Unstable Affliction for Ruin (bigger Shadow Bolt crit multiplier) once crit rating is high enough.",
            sources = {
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-affliction-warlock-talents",
                "https://www.wowhead.com/tbc/guide/classes/warlock/dps-talent-builds-pve",
            },
        },
        {
            label = "Destruction — Raid PvE DPS", context = "pve", role = "dps",
            allocation = "Affliction 0 / Demonology 21 / Destruction 40", confidence = "CONFIRMED",
            keyTalents = {
                "Shadow and Flame 5/5 (mandatory, buffs both Shadow Bolt and Incinerate)",
                "Bane 5/5", "Devastation 5/5", "Ruin 1/1", "Improved Shadow Bolt 5/5",
                "Emberstorm 5/5", "-- Demonology dip: Demonic Sacrifice 1/1 (required pickup)",
            },
            notes = "Cataclysm (mana-cost reduction) is deliberately skipped since it doesn't help when swapping Shadow Bolt/Incinerate. Late-tier variant shifts fully into Shadow once a 4-set bonus makes it stronger than Fire.",
            sources = {
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-destruction-warlock-talents",
                "https://www.wowhead.com/tbc/guide/classes/warlock/dps-talent-builds-pve",
            },
        },
        {
            label = "Demonology (Felguard) — Raid PvE DPS niche", context = "pve", role = "dps",
            allocation = "Affliction 1 / Demonology 41 / Destruction 19", confidence = "CONFIRMED",
            keyTalents = {
                "Master Demonologist 5/5", "Demonic Knowledge 3/3", "Demonic Tactics 5/5",
                "Summon Felguard 1/1 (capstone)", "Soul Link 1/1", "Demonic Sacrifice 1/1 (pass-through)",
            },
            notes = "Real, not obsolete — Icy Veins calls it 'the only Summon Felguard build you need in TBC.' Strongest on movement-heavy fights where pet uptime beats a caster standing still; not top-parse but a legitimate gear-scaling alternative.",
            sources = {
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-demonology-warlock-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-demonology-warlock/",
            },
        },
        {
            label = "SL/SL (Soul Link/Siphon Life) — Arena/PvP (dominant; majority-Demonology despite the name)", context = "pvp", role = "dps",
            allocation = "Affliction 25 / Demonology 36 / Destruction 0", confidence = "CONFIRMED",
            keyTalents = {
                "Siphon Life 1/1 (Affliction, the reason for the Affliction investment)",
                "Soul Link 1/1 (Demonology capstone — shares/reduces damage taken via pet)",
                "Master Demonologist 5/5", "Demonic Aegis", "Fel Domination 1/1",
                "Drain Life + Fel Armor for self-sustain",
            },
            notes = "Naming trap: sources file this under both 'Affliction PvP' and 'Demonology PvP' guides even though the majority of points (36) go into Demonology — it's really an extreme-survivability hybrid built to outlast rather than burst. Called 'the mandatory and undeniably best spec for Warlock arena' by one source, ~70% play rate per another. Destruction has essentially no arena niche (its PvP role is battlegrounds only — Shadowfury AoE-stun for flag capping).",
            sources = {
                "https://www.wowhead.com/tbc/guide/warlock-dps-pvp-arena-guide-burning-crusade-classic-wow",
                "https://www.skill-capped.com/wowarticles/tbc/guides/affliction-warlock-pvp-guide/talents/",
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════════
    DRUID = {
        {
            label = "Restoration — Raid PvE Healing ('Tree of Life')", context = "pve", role = "healer",
            allocation = "Restoration 41 (capstone) with ~20 flex points — exact remaining split disputed", confidence = "DISPUTED",
            keyTalents = {
                "Improved Mark of the Wild", "Intensity 3/3", "Nature's Swiftness 1/1",
                "Gift of Nature 5/5", "Empowered Rejuvenation 5/5", "Swiftmend 1/1",
                "Living Spirit 3/3", "Tree of Life 1/1 (capstone)",
            },
            notes = "The 41-point Restoration core (for Tree of Life) is the one hard agreed number. Where the remaining ~20 points go is genuinely disputed across guides: a Balance dip (e.g. 14/0/47) for Dreamstate/mana-regen ('Restokin'-adjacent) vs. staying almost entirely in Restoration — both are named, real variants.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/druid/healer-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/restoration-druid-healer-pve-spec-builds-talents",
            },
        },
        {
            -- Added 2026-09-09: reported missing entirely — DRUID's PvE
            -- entries covered Restoration (heal) and both Feral specs but
            -- had no Balance build at all, a real gap the schema validator
            -- never caught (it only checks that SOME PvE build exists per
            -- class, not that every real spec has one). Wowhead and Icy
            -- Veins both name the key/capstone talents clearly, but neither
            -- publishes their talent-calculator build as scrapeable plain
            -- text (same JS-widget limitation noted elsewhere in this
            -- file), so the exact secondary point split is not independently
            -- confirmed as a single hard number — graded APPROX with
            -- verifyPoints, same treatment as the other guide-prose-only
            -- entries above.
            label = "Balance — Raid PvE DPS ('Boomkin')", context = "pve", role = "dps",
            allocation = "Deep Balance capstone build (through Force of Nature) with a small Restoration "
                .. "dip for Intensity / Natural Shapeshifter / Improved Mark of the Wild — exact point "
                .. "totals not confirmed from a scraped calculator",
            confidence = "APPROX",
            verifyPoints = true,
            keyTalents = {
                "Starlight Wrath", "Improved Moonfire", "Insect Swarm", "Vengeance",
                "Lunar Guidance", "Nature's Grace", "Moonglow", "Moonfury",
                "Balance of Power", "Dreamstate", "Moonkin Form", "Wrath of Cenarius",
                "Force of Nature (capstone)",
                "-- Raid utility: Improved Faerie Fire (doesn't help your own damage, but is why raids want one)",
            },
            notes = "Icy Veins: 'Balance Druids are tight on points' — Naturalist/Nature's Focus/Natural "
                .. "Shapeshifter get swapped based on personal mana needs, so treat the Restoration tail as "
                .. "flexible rather than fixed. Moonkin Form's 5% raid-wide spell crit aura is a group buff, "
                .. "not just personal DPS.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/druid/balance/dps-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/balance-druid-dps-pve-spec-builds-talents",
                "https://wowtbc.gg/class-guides/balance-druid/",
            },
        },
        {
            label = "Feral (Bear) — Raid PvE Tank", context = "pve", role = "tank",
            allocation = "Balance 0 / Feral 44 / Restoration 17", confidence = "CONFIRMED",
            keyTalents = {
                "Ferocity 5/5", "Feral Instinct 3/3", "Thick Hide 3/3", "Feral Charge 1/1",
                "Leader of the Pack 1/1 (prerequisite for Mangle)", "Survival of the Fittest 3/3",
                "Mangle 1/1 (44-point capstone, best threat-per-rage bear ability)",
                "-- Restoration dip: Furor 5/5, Naturalist 5/5, Omen of Clarity 1/1",
            },
            notes = "The only spec in the game with two intended builds sharing one 44-point Feral chassis and the Mangle capstone — see the Feral Cat DPS entry below.",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/feral-druid-tank-pve-spec-builds-talents",
            },
        },
        {
            label = "Feral (Cat) — Raid PvE DPS", context = "pve", role = "dps",
            allocation = "Balance 0 / Feral 47 / Restoration 14", confidence = "CONFIRMED",
            keyTalents = { "Same Feral chassis as the bear tank build, pushed 3 points deeper (e.g. Predatory Instincts) with a trimmed Restoration tail." },
            notes = "Distinct, real build sharing the tank spec's core.",
            sources = {
                "https://www.icy-veins.com/tbc-classic/feral-druid-dps-pve-spec-builds-talents",
                "https://boosting-ground.com/wow-classic/guides/the-burning-crusade-guides/tbc-feral-druid-dps-talents",
            },
        },
        {
            label = "Restoration — Arena/PvP (dominant Druid PvP spec, S-tier)", context = "pvp", role = "healer",
            allocation = "'Tree of Life' (~41 Restoration + Barkskin/Subtlety/Natural Perfection) OR '13/11/37 Hybrid' (Balance 13/Feral 11/Resto 37, most versatile for 2v2)", confidence = "DISPUTED",
            keyTalents = {
                "Tree of Life build: deep Restoration + Barkskin, Subtlety, Natural Perfection",
                "Hybrid build: Insect Swarm (Balance) + Feral Charge (Feral) for pressure/interrupt utility — cannot take Tree of Life at this split",
            },
            notes = "Confirmed dominant/S-tier PvP healer. No guide crowns a single winner between Tree of Life and the 13/11/37 Hybrid — both are presented as mainline competitive options; a deep-Balance 'Restokin' exists as a weaker niche third option. Feral PvP is real but secondary, favoring battlegrounds/world PvP over structured arena (lacks a Rogue-style CC kit or Mortal-Strike-style debuff).",
            sources = {
                "https://www.wowhead.com/tbc/guide/druid-healer-pvp-arena-guide-burning-crusade-classic-wow",
                "https://www.icy-veins.com/tbc-classic/restoration-druid-pvp-guide",
                "https://overgear.com/guides/wow-classic/tbc-anniversary-pvp-tier-list/",
            },
        },
    },
}
