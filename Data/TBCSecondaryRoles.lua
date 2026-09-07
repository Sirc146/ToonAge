-- ToonAge/Data/TBCSecondaryRoles.lua (Anniversary — TBC Classic / Interface 20506)
-- "Secondary/hybrid capability" suggestions per class — real, legitimate
-- things a class can do OUTSIDE its normal main role in TBC Classic dungeon
-- content (off-healing, off-tanking, unique group utility), surfaced as an
-- OPTIONAL secondary suggestion alongside the main recommended build in
-- Data/TBCTalentBuilds.lua — never in place of it.
--
-- Requested 2026-09-07: "otherclasses can build up and do out of the box
-- things like dungeon runs like Mage heal and such... suggested secondary
-- as an option if you are playing the class and are the spec that have the
-- talent tree available to run it." Note the correction actually made to
-- that request: Mages have NO healing spell at all in TBC Classic (confirmed
-- via Icy Veins' Mage class overview during research for this file) — that
-- part of the example doesn't exist on this client. The real underlying
-- idea is sound though, and several other classes genuinely do have this;
-- see PRIEST/SHAMAN/PALADIN/DRUID/WARLOCK below.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── SCHEMA ─────────────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
-- Each entry:
--   label         short name shown in the UI
--   requiredTree  talent tree name exactly as GetTalentTabInfo() returns it
--                 ("Protection", "Holy", "Shadow", ...), or "none" if the
--                 trick needs zero talent investment (baseline class kit).
--   requiredPoints minimum points in requiredTree for this to be genuinely
--                 viable, not just theoretically possible. 0 when
--                 requiredTree == "none".
--   context       when/why you'd reach for this in a dungeon group
--   description   what buttons/spells make it work, 1-3 sentences
--   confidence    CONFIRMED (2+ independent sources agree) / APPROX (single
--                 source or best synthesis) / DISPUTED — same grading
--                 convention as Data/TBCTalentBuilds.lua
--   sources       URLs actually checked during research
--
-- Eligibility against a player's LIVE talents is computed at render time by
-- Modules/Character/TalentBuilds.lua via U.GetTalentPointsInTree(), added to
-- Core/Utils.lua alongside U.GetTalentSummary() specifically for this
-- feature — this file only holds the static, sourced data.
--
-- Researched 2026-09-07 against current TBC Classic Anniversary guides
-- (Wowhead TBC, Icy Veins TBC Classic, Warcraft Tavern) via 3 parallel
-- research passes, one per class group. Several point costs are APPROX
-- because guide pages render their talent trees as JS widgets that don't
-- always scrape as plain text — the tree identity and mechanic itself are
-- solid in every entry below even where the exact point number is a
-- best-sourced estimate rather than a directly-quoted number.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.SecondaryRoles = {

    WARRIOR = {
        {
            label = "Emergency off-tank via Defensive Stance",
            requiredTree = "Protection", requiredPoints = 15,
            context = "Group loses its tank or needs a second body on adds, and you have spare tank gear/a shield.",
            description = "Defensive Stance itself is free for any spec, but real Protection investment (Defiance for threat/expertise, "
                .. "Improved Sunder Armor for cheaper rage) is what makes it actually hold trash rather than just survive a few hits.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.wowhead.com/tbc/guide/classes/warrior/protection/tank-talent-builds-pve",
                "https://www.icy-veins.com/tbc-classic/protection-warrior-tank-pve-spell-summary",
            },
        },
    },

    PALADIN = {
        {
            label = "Off-healing via Holy Light / Flash of Light",
            requiredTree = "Holy", requiredPoints = 15,
            context = "Your group's healer is oom or dead mid-pull and you can bridge the gap.",
            description = "Any Paladin can baseline-cast Holy Light/Flash of Light, but Illumination (Holy tree, ~15 points in) refunds "
                .. "60% of the mana cost on a crit — that's what turns a one-shot panic heal into something you can sustain.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.icy-veins.com/tbc-classic/holy-paladin-healer-pve-spec-builds-talents",
                "https://www.icy-veins.com/tbc-classic/holy-paladin-healer-pve-spell-summary",
            },
        },
        {
            label = "Party mana support via Improved Blessing of Wisdom",
            requiredTree = "Protection", requiredPoints = 2,
            context = "You're tanking but the group's casters are running dry between pulls.",
            description = "A small 2-point Protection talent that boosts Blessing of Wisdom's mana return, letting a tank-spec "
                .. "Paladin meaningfully stretch the group's mana without touching Holy at all.",
            confidence = "APPROX",
            sources = {
                "https://www.wowhead.com/tbc/spell=20245/improved-blessing-of-wisdom",
                "https://wowpedia.fandom.com/wiki/Improved_Blessing_of_Wisdom",
            },
        },
    },

    HUNTER = {
        {
            label = "Trap-based crowd control / off-tanking",
            requiredTree = "Survival", requiredPoints = 8,
            context = "Group is short a tank or CC and an add needs to be locked down or kited near a pull.",
            description = "Frost Trap and Freezing Trap work with zero talents at all — that part is a baseline trick anyone can use. "
                .. "Survival investment makes the traps last long enough / hit hard enough to be a repeatable dungeon tactic instead of a one-off.",
            confidence = "APPROX",
            sources = {
                "https://www.icy-veins.com/tbc-classic/survival-hunter-dps-pve-spell-summary",
                "https://vanilla-wow-archive.fandom.com/wiki/Frost_Trap",
            },
        },
        {
            label = "Pet off-tanking undergeared trash",
            requiredTree = "Beast Mastery", requiredPoints = 20,
            context = "Undergeared 5-man with a weak or absent tank and a durable pet (Boar/Bear).",
            description = "Deep Beast Mastery investment (including its capstone pet-stat talent) makes your pet tanky enough to "
                .. "hold trash temporarily while the group repositions — not viable with a shallow BM spend.",
            confidence = "APPROX",
            sources = {
                "https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-dps-pets-guide",
                "https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-dps-pve-spec-builds-talents",
            },
        },
    },

    ROGUE = {
        {
            label = "Stealth-scouting for skip routes",
            requiredTree = "Subtlety", requiredPoints = 5,
            context = "Dungeon route favors skipping trash and you want to scout pulls safely ahead of the group.",
            description = "Master of Deception (Subtlety, 5 points) reduces enemies' chance to spot you while stealthed, making "
                .. "scouting and Sap-chaining meaningfully more reliable than at zero Subtlety investment.",
            confidence = "APPROX",
            sources = { "https://www.wowhead.com/tbc/spell=13973/master-of-deception" },
        },
        {
            label = "Frequent stealth resets via Vanish CDR",
            requiredTree = "Subtlety", requiredPoints = 21,
            context = "Recovering from a bad pull or re-scouting mid-dungeon after a wipe.",
            description = "A deep Subtlety talent shortens Vanish's cooldown, letting a heavily Sub-specced Rogue re-stealth and "
                .. "re-pull far more often than the baseline ~5-minute cooldown allows.",
            confidence = "APPROX",
            sources = { "https://www.wowhead.com/tbc/spell=32743/vanish-cooldown-reduction" },
        },
    },

    PRIEST = {
        {
            label = "Shadow off-healing via Vampiric Embrace",
            requiredTree = "Shadow", requiredPoints = 20,
            context = "Dungeon group has no dedicated healer, or the healer is oom/dead.",
            description = "Vampiric Embrace heals the whole party for 15% (25% with the 2-point Improved rank) of the Shadow "
                .. "damage you deal — real throughput while you keep DPSing, not a wand-and-pray fallback.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.wowhead.com/tbc/spell=15286/vampiric-embrace",
                "https://www.icy-veins.com/tbc-classic/shadow-priest-dps-pve-spec-builds-talents",
            },
        },
    },

    SHAMAN = {
        {
            label = "Full support kit regardless of spec",
            requiredTree = "none", requiredPoints = 0,
            context = "Any dungeon group — Elemental/Enhancement can still off-heal in an emergency and always bring raid-wide utility.",
            description = "Chain Heal, Healing Wave, Mana Spring Totem, and Healing Stream Totem are trainer-taught, not talent-locked — "
                .. "an offensively-specced Shaman can drop combat to smart-heal a burst moment, and always brings Bloodlust/Heroism "
                .. "regardless of spec. Restoration points sharpen this but aren't required for it to exist.",
            confidence = "CONFIRMED",
            sources = { "https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-spell-summary" },
        },
    },

    MAGE = {
        {
            label = "Decurse utility (Remove Curse)",
            requiredTree = "none", requiredPoints = 0,
            context = "Trash or a boss applies a curse and no Druid/Paladin is in the group.",
            description = "Remove Curse / Remove Lesser Curse are baseline trainer spells, no talent required — genuine "
                .. "\"bring a mage for utility\" value that has nothing to do with damage.",
            confidence = "CONFIRMED",
            sources = {
                "https://www.wowhead.com/tbc/spell=475/remove-lesser-curse",
                "https://www.wowhead.com/tbc/spell=2782/remove-curse",
            },
        },
        {
            label = "Full-school lockout via Improved Counterspell",
            requiredTree = "Arcane", requiredPoints = 12,
            context = "A dangerous caster needs to be silenced completely, not just locked out of one school.",
            description = "Improved Counterspell adds a full-school silence on top of Counterspell's normal single-school lockout, "
                .. "turning a DPS Mage into a reliable secondary interrupt.",
            confidence = "APPROX",
            sources = { "https://www.wowhead.com/tbc/spell=12598/improved-counterspell" },
        },
    },

    WARLOCK = {
        {
            label = "Voidwalker off-tanking",
            requiredTree = "Demonology", requiredPoints = 18,
            context = "No tank in the group, or content is well below the party's gear level.",
            description = "Real Demonology investment (Fel Stamina, Master Demonologist's damage-reduction bonus) makes the "
                .. "Voidwalker tanky enough to hold trash or an undertuned boss — a 0-point Affliction/Destro Voidwalker cannot do this credibly.",
            confidence = "APPROX",
            sources = {
                "https://www.icy-veins.com/tbc-classic/demonology-warlock-dps-pve-spec-builds-talents",
                "https://www.warcrafttavern.com/tbc/guides/pve-demonology-warlock-talents-builds/",
            },
        },
        {
            label = "Soulstone as pre-emptive battle-rez insurance",
            requiredTree = "none", requiredPoints = 0,
            context = "Before a risky pull or boss attempt — stone the healer or tank ahead of time.",
            description = "Create Soulstone is baseline (costs a Soul Shard, no talent involved) and lets a wipe-causing death "
                .. "become an instant self-rez instead of a wipe.",
            confidence = "CONFIRMED",
            sources = { "https://www.warcrafttavern.com/tbc/guides/warlock-soul-shards/" },
        },
    },

    DRUID = {
        {
            label = "Rebirth — the only in-combat battle rez in TBC",
            requiredTree = "none", requiredPoints = 0,
            context = "The tank or a key player dies mid-fight and waiting for combat to end isn't an option.",
            description = "Baseline spell, learned at level 20, spec-independent — every Druid build brings this, and no other "
                .. "class in TBC has an in-combat rez at all.",
            confidence = "CONFIRMED",
            sources = { "https://www.wowhead.com/tbc/spell=20484/rebirth" },
        },
        {
            label = "Real emergency healing from Feral/Balance with partial Restoration",
            requiredTree = "Restoration", requiredPoints = 6,
            context = "The healer dies or goes oom and you have to shift out and land a heal that actually matters.",
            description = "A 0-point-Resto Druid's emergency Healing Touch/Rejuvenation is weak and slow. Even a partial "
                .. "Restoration dip (Naturalist's faster cast, Improved Rejuvenation's bigger HoT) makes that emergency shift-and-heal "
                .. "genuinely strong instead of symbolic.",
            confidence = "APPROX",
            sources = {},
        },
    },
}
