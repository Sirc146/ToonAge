-- ToonAge/Data/TBCProfessions.lua (Anniversary — TBC Classic / Interface 20506)
-- Which professions actually give combat power in The Burning Crusade.
--
-- ─── CORRECTIONS TO Docs/CLASSIC_ANNIVERSARY_BRIEF.md ────────────────────────
--
-- The brief's profession list carries two Wrath-era perks and omits the largest
-- TBC one:
--
--   * "Blacksmithing: Extra socket on bracers/gloves (later TBC)". Socket
--     Bracer / Socket Gloves are Wrath of the Lich King (3.0) recipes. They do
--     not exist at any point in TBC. Blacksmithing's TBC combat value is its
--     bind-on-pickup crafted weapons and the specialisation-gated plate sets.
--   * "Alchemy: Mixology (better flask effect)". Mixology is also 3.0. In TBC
--     the alchemist's edge is the bind-on-pickup Alchemist's Stone family and
--     the discovery/specialisation extra-potion procs.
--   * Engineering is missing entirely, and in TBC it is arguably the strongest
--     combat profession — bind-on-pickup goggles that beat contemporary drops,
--     plus usable grenades, rocket boots and a parachute.
--
-- Herbalism, Mining and Skinning have NO combat perk in TBC. Lifeblood,
-- Toughness and Master of Anatomy are all Wrath additions. They are listed here
-- explicitly as "gathering only" so the tab can say so, rather than leaving the
-- player to wonder whether the addon simply failed to find them.
--
-- Profession names are matched in English. On a localized client the lookup
-- misses and the tab says so instead of showing another profession's perks.

local TA = ToonAge
TA.Data = TA.Data or {}

-- ─── TIER GATES ──────────────────────────────────────────────────────────────
--
-- GetSkillLineInfo reports the CURRENT tier ceiling, not the eventual 375. A
-- freshly learned profession reads 1/75, and that 75 is a training gate, not a
-- goal. The distinction is the difference between useful advice and useless
-- advice: at 75/75 the answer is "go see a trainer", not "keep grinding".
--
-- The 300 → 375 step is the one that actually strands people. Master rank is
-- only trainable in Outland, so a character who caps Artisan at level 40 has
-- nowhere to go until 58+ regardless of how much they farm.
--
-- Secondary skills use the same ladder: Master Cooking, First Aid and Fishing
-- trainers are Outland-side too.

TA.Data.PROFESSION_MIN_LEVEL = 5
TA.Data.PRIMARY_SLOTS = 2

TA.Data.ProfessionTiers = {
    [75]  = { name = "Apprentice", nextName = "Journeyman", nextCap = 150,
              where = "any profession trainer" },
    [150] = { name = "Journeyman", nextName = "Expert",     nextCap = 225,
              where = "any profession trainer" },
    [225] = { name = "Expert",     nextName = "Artisan",    nextCap = 300,
              where = "any profession trainer" },
    [300] = { name = "Artisan",    nextName = "Master",     nextCap = 375,
              where = "an |cFFFFD100Outland|r trainer — not available in Azeroth at any level" },
    [375] = { name = "Master" },
}

--- @return table|nil tier  info for a skill line's current ceiling
function TA.Data.GetTier(maxRank)
    return TA.Data.ProfessionTiers[maxRank]
end

TA.Data.Professions = {
    ["Engineering"] = {
        tier = "top",
        summary = "The strongest raw combat profession in TBC.",
        perks = {
            "Bind-on-pickup goggles (Destruction/Justicebringer/Hyper-Vision and friends) "
                .. "that out-stat most gear available when you can first make them",
            "Usable explosives — grenades stun, Super Sapper Charge is real burst AoE",
            "Rocket Boots and Nitro-style escapes for movement fights",
            "Gnomish vs Goblin sub-specialisation: Goblin for damage, Gnomish for utility",
        },
        pairsWith = "Mining",
        note = "Head slot is a hard slot to fill for most of TBC; the goggles solve it.",
    },
    ["Jewelcrafting"] = {
        tier = "top",
        summary = "Exclusive gems, and one of the few flat stat gains.",
        perks = {
            "Bind-on-pickup jewelcrafter-only gems that beat every equivalent cut",
            "Figurine trinkets — solid, and available long before comparable drops",
            "Every socket you own benefits, so the value scales with your gear",
        },
        pairsWith = "Mining",
    },
    ["Enchanting"] = {
        tier = "top",
        summary = "Ring enchants nobody else can have.",
        perks = {
            "Enchant Ring — two rings, and only enchanters can use them",
            "Roughly +2x12 spell power or +2x20 attack power at max rank",
            "Disenchanting keeps the profession paying for itself",
        },
        pairsWith = "Tailoring",
        note = "A pure, permanent stat gain with no cooldown and nothing to press.",
    },
    ["Leatherworking"] = {
        tier = "high",
        summary = "Drums — a party-wide raid cooldown.",
        perks = {
            "Drums of Battle: haste for your whole party, on rotation with other drummers",
            "Drums of Restoration and Drums of Panic for utility groups",
            "Fur Lining bracer enchants, leatherworker-only, resistance or attack power",
        },
        pairsWith = "Skinning",
        note = "Drums are why raids bring leatherworkers; the personal stats are secondary.",
    },
    ["Tailoring"] = {
        tier = "high",
        summary = "Leg enchants and the caster crafted sets.",
        perks = {
            "Spellthread leg enchants — the tailor-only versions beat the tradeable ones",
            "Spellfire / Shadoweave / Primal Mooncloth three-piece sets with real set bonuses",
            "Cloth is a caster profession end to end",
        },
        note = "Pairs naturally with Enchanting — no gathering profession needed for either.",
    },
    ["Blacksmithing"] = {
        tier = "medium",
        summary = "Crafted weapons and specialisation-gated plate.",
        perks = {
            "Bind-on-pickup crafted weapons that hold up against raid drops",
            "Weaponsmith sub-specialisations (Sword/Axe/Hammer) unlock the best of them",
            "Armorsmith plate sets for tanks and plate DPS",
        },
        pairsWith = "Mining",
        note = "No socket recipes in TBC — Socket Bracer and Socket Gloves are Wrath.",
    },
    ["Alchemy"] = {
        tier = "medium",
        summary = "Alchemist's Stone, and more consumables than you use.",
        perks = {
            "Alchemist's Stone family: bind-on-pickup trinkets with strong passive stats",
            "Specialisation (Elixir / Potion / Transmute) gives extra-yield procs",
            "Transmute cooldowns are a steady gold income for gems and consumables",
        },
        pairsWith = "Herbalism",
        note = "Mixology — the flask-duration perk — is Wrath, not TBC.",
    },
    ["Herbalism"] = {
        tier = "gathering",
        summary = "Gathering only — no combat perk in TBC.",
        perks = { "Feeds Alchemy", "Lifeblood, the self-heal, is a Wrath addition and is absent here" },
    },
    ["Mining"] = {
        tier = "gathering",
        summary = "Gathering only — no combat perk in TBC.",
        perks = { "Feeds Blacksmithing, Engineering and Jewelcrafting",
                  "Toughness, the stamina perk, is a Wrath addition and is absent here" },
    },
    ["Skinning"] = {
        tier = "gathering",
        summary = "Gathering only — no combat perk in TBC.",
        perks = { "Feeds Leatherworking",
                  "Master of Anatomy, the crit perk, is a Wrath addition and is absent here" },
    },
    ["Cooking"] = {
        tier = "secondary",
        summary = "Secondary — but the food buffs are not optional at raid level.",
        perks = { "Well Fed buffs worth 20-30 of a stat for the whole raid night",
                  "Spicy Hot Talbuk, Skullfish Soup and Golden Fish Sticks are staples" },
    },
    ["First Aid"] = {
        tier = "secondary",
        summary = "Secondary — a free heal on a class that has none.",
        perks = { "Heavy Netherweave Bandage is significant self-healing out of combat",
                  "Genuinely useful in five-mans for non-healers" },
    },
    ["Fishing"] = {
        tier = "secondary",
        summary = "Secondary — feeds Cooking.",
        perks = { "The best TBC food buffs need fished mats" },
    },
}

-- ─── THE GATHER-THEN-SWAP PLAN ───────────────────────────────────────────────
--
-- Level gathering professions 1-70, bank the mats, then drop them for the
-- crafting professions you actually want. You arrive at 70 with the materials
-- to level a craft instead of the gold bill for buying them.
--
-- It is a good plan. It is not universally a good plan, and which of the two it
-- is depends on ONE property of the target craft:
--
-- There are TWO separate mat costs, and conflating them produces bad advice:
--
--   SKILL-UP COST    Levelling the craft 1-375. One-time, and large — it is the
--                    single biggest gold sink in taking a profession. Banking
--                    gathered mats covers this completely, for every craft
--                    including the consumable ones. This is the cost the plan
--                    exists to defeat, and it defeats it.
--
--   ONGOING COST     Mats consumed after you are capped. Only some crafts have
--                    one. It is much smaller than the skill-up cost, but it
--                    never stops.
--
--   one-time     Engineering goggles, Jewelcrafting gems, Blacksmithing weapons.
--                Crafted once per gear slot. Skill-up cost only. Bank, swap,
--                spend, done — the gatherer is never needed again.
--
--   consumable   Leatherworking drums, Alchemy flasks and potions. Banking still
--                covers the whole 1-375 skill-up, so the plan works for the
--                expensive part. What it does not cover is production after
--                that: drums are spent every raid night. Budget for buying
--                those, or re-take the gatherer once the other craft is capped.
--                This is a residual, not a reason to abandon the plan.
--
--   self-feeding Enchanting eats the gear you disenchant. It never wanted a
--                gathering slot. Tailoring runs on mob-drop cloth, which no
--                gathering profession produces either. For the caster and healer
--                pair (Tailoring + Enchanting) the plan is simply moot — there
--                is nothing to gather and nothing to swap.
--
-- Unlearning also wipes the skill to zero. There is no parking a profession: if
-- you drop Mining at 375 and want it back, it is 1-375 again from scratch.

TA.Data.ProfessionEconomy = {
    Engineering    = { feeder = "Mining",    output = "one-time"     },
    Jewelcrafting  = { feeder = "Mining",    output = "one-time"     },
    Blacksmithing  = { feeder = "Mining",    output = "one-time"     },
    Leatherworking = { feeder = "Skinning",  output = "consumable"   },
    Alchemy        = { feeder = "Herbalism", output = "consumable"   },
    Enchanting     = { feeder = nil,         output = "self-feeding" },
    Tailoring      = { feeder = nil,         output = "one-time"     },
}

-- A second gatherer taken purely to sell. Picked when the target crafts need
-- fewer than two feeders, so the spare slot still earns.
TA.Data.GoldGatherers = { "Skinning", "Herbalism", "Mining" }

--- The levelling plan for a role.
--- @return table {targets, feeders, spare, applies, caveats, moot}
function TA.Data.GetLevelingPlan(role)
    local advice = TA.Data.ProfessionAdvice[role]
    if not advice then return nil end

    local targets = advice.best
    local feeders, seen, caveats = {}, {}, {}

    for _, craft in ipairs(targets) do
        local econ = TA.Data.ProfessionEconomy[craft]
        if econ and econ.feeder and not seen[econ.feeder] then
            seen[econ.feeder] = true
            feeders[#feeders + 1] = econ.feeder
        end
        if econ and econ.output == "consumable" then
            caveats[#caveats + 1] = string.format(
                "%s keeps eating mats after it is capped — drums and flasks are spent every "
                .. "raid night. Your banked %s still covers the entire 1-375 skill-up, which "
                .. "is the expensive part; only ongoing production is left to buy. Re-taking "
                .. "%s later is an option once %s is finished.",
                craft, econ.feeder or "mats", econ.feeder or "it",
                (targets[1] ~= craft and targets[1]) or "your other craft")
        end
        if econ and econ.output == "self-feeding" then
            caveats[#caveats + 1] = string.format(
                "%s feeds itself by disenchanting gear — it never needed a gathering slot.", craft)
        end
    end

    -- Fill any spare slot with a gatherer taken for gold rather than for mats.
    local spare
    if #feeders < 2 then
        for _, g in ipairs(TA.Data.GoldGatherers) do
            if not seen[g] then spare = g break end
        end
    end

    return {
        targets = targets,
        feeders = feeders,
        spare   = spare,
        moot    = (#feeders == 0),
        caveats = caveats,
    }
end

--- Best pairings by role. Deliberately short: these are the ones where the
--- answer is not contested.
TA.Data.ProfessionAdvice = {
    CASTER = {
        best = { "Tailoring", "Enchanting" },
        why  = "Spellthread plus two ring enchants is the largest permanent spell-power "
            .. "gain available from professions, and neither needs a gathering slot.",
        also = { "Jewelcrafting", "Engineering" },
    },
    MELEE = {
        best = { "Engineering", "Jewelcrafting" },
        why  = "Goggles fill the head slot for most of the expansion, and jewelcrafter-only "
            .. "gems scale with every socket you pick up.",
        also = { "Enchanting", "Blacksmithing", "Leatherworking" },
    },
    RANGED = {
        best = { "Engineering", "Leatherworking" },
        why  = "Engineering goggles and ammo-adjacent gadgets, plus Drums of Battle for the party.",
        also = { "Jewelcrafting", "Enchanting" },
    },
    TANK = {
        best = { "Blacksmithing", "Jewelcrafting" },
        why  = "Crafted plate covers awkward slots early, and gems let you tune defense "
            .. "to exactly the uncrittable threshold instead of overshooting it.",
        also = { "Engineering", "Leatherworking" },
    },
    HEALER = {
        best = { "Tailoring", "Enchanting" },
        why  = "Primal Mooncloth and spellthread, with ring enchants on top.",
        also = { "Jewelcrafting", "Alchemy" },
    },
}
