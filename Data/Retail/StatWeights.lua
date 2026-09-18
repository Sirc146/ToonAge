-- ToonAge/Data/StatWeights.lua
-- Stat weights per spec for PvE and PvP (Midnight 12.1 "Curse of Ula'tek", Season 2)
-- Re-verified 2026-09-05 across icy-veins.com (primary), wowhead.com, and method.gg
-- for all 40 specs (Devourer added 2026-09-16), both PvE and PvP, in one pass (see per-spec comments for exact
-- sourcing/disagreements found). Higher = more valuable.
--
-- METHODOLOGY: numbers are derived from each spec's researched rank order (1st/2nd/
-- 3rd/4th best secondary stat), not independently simmed -- multiple guide sites
-- often disagree on the exact order (frequently the middle two stats, occasionally
-- the top one), and those disagreements are noted per spec below rather than
-- silently resolved. Treat these as directional priority, not precise sim weights --
-- every source consulted makes the same caveat for its own numbers.
--
-- Rank->weight scale used throughout: 1st=1.30  2nd=1.10  3rd=0.95  4th=0.80
-- (tied ranks are averaged). Primary stat: 1.70 (healer) / 1.60 (dps) / 1.50 (tank).
-- Off-primary stats (e.g. Agility for an Intellect spec) sit at a flat 0.20 -- never
-- itemized for, but non-zero since some trinkets/enchants can't avoid them.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.StatWeights = {}
local SW = TA.Data.StatWeights

-- ── Weight table format ────────────────────────────────────────────────
-- SW[specID] = { pve = {...}, pvp = {...} }
-- Stat keys: INT, AGI, STR, STAM, HASTE, CRIT, MASTERY, VERS, ARMOR

-- ── Warrior ──────────────────────────────────────────────────
SW[71] = { -- Arms
    name = "Arms",
    role = "DAMAGER",
    primary = "STR",
    -- PvE: full 3-source agreement, re-confirmed 2026-09-06 (icy-veins/Wowhead/method.gg
    -- all give the identical "Crit, Haste, Mastery, Vers" order). No disagreement found.
    -- PvP: confirmed via BOTH icy-veins' explicit list AND Skill Capped's dedicated Midnight
    -- Season 2 Arms PvP guide -- both give "Versatility, Haste, Mastery, Critical Strike"
    -- verbatim; murlok.io's real top-rated-player gear data matches the same order too.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[72] = { -- Fury
    name = "Fury",
    role = "DAMAGER",
    primary = "STR",
    -- PvE: re-confirmed 2026-09-06. icy-veins and method.gg agree Mastery > Haste up top
    -- (method.gg ties the tail Crit=Vers); Wowhead instead leads Haste > Mastery and flips
    -- the tail to Crit > Vers -- flagged disagreement, kept icy-veins/majority order.
    -- PvP: genuine unresolved disagreement, NOT silently resolved -- icy-veins' own numbered
    -- list ("Vers, Haste, Mastery, Crit") is corroborated by murlok.io's real top-rated-player
    -- gear data (same order), but icy-veins' own PROSE self-contradicts its list ("Haste...
    -- only slightly outclassed by Mastery at present... slightly more Mastery heavy"), and
    -- Skill Capped's dedicated Midnight S2 Fury PvP guide explicitly ranks Mastery above
    -- Haste ("Vers > Mastery > Haste > Crit") citing near-permanent Enrage uptime. Unlike
    -- Windwalker Monk's PvP row above (where Skill Capped was the clear, uncontested
    -- tiebreaker), here real player gear data actively disagrees with Skill Capped, so the
    -- majority/empirical order (Haste 2nd) is kept rather than deferring to Skill Capped.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.95,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[73] = { -- Protection
    name = "Protection",
    role = "TANK",
    primary = "STR",
    -- PvE: re-confirmed 2026-09-06, full 3-source agreement on the skeleton (icy-veins/
    -- Wowhead/method.gg) -- Haste > Crit >= Vers > Mastery (method.gg ties Crit/Vers; icy-veins
    -- notes the Crit/Vers gap narrows further on magic-heavy fights).
    -- PvP: icy-veins' explicit list ("Vers, Haste, Mastery, Crit") matches murlok.io's real
    -- top-rated-player gear data exactly. No dedicated Skill Capped Protection Warrior PvP
    -- guide exists (checked skill-capped.com directly -- 404), and Wowhead has no PvP
    -- stat-priority page for this spec, so only the two sources above were available.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.20,
        MASTERY = 0.80,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.30,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
-- ── Paladin ──────────────────────────────────────────────────
SW[65] = { -- Holy
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    -- PvE: confirmed 2026-09-06 (icy-veins/Wowhead/method.gg) Mastery > Haste > Crit > Versatility;
    -- Wowhead and method.gg tie Haste/Crit rather than ranking Haste strictly above it. method.gg also
    -- notes Versatility overtakes Mastery specifically in Mythic+ (not raid) -- flagged, as before.
    -- PvP: confirmed 2026-09-06 via icy-veins and murlok.io, both explicit: Versatility > Mastery >
    -- Haste > Crit. Skill Capped's dedicated Midnight S2 Holy PvP guide instead leads with Mastery >
    -- Versatility (Haste/Crit order agrees with the other two) -- flagged disagreement on the top two.
    -- Weights below match the 2-source majority (icy-veins/murlok); unchanged from the prior pass.
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[66] = { -- Protection
    name = "Protection",
    role = "TANK",
    primary = "STR",
    -- PvE: confirmed 2026-09-06. icy-veins 'offensive' list and method.gg agree exactly: Haste > Crit >
    -- Versatility > Mastery. icy-veins 'defensive' list instead runs Haste > Versatility > Mastery > Crit,
    -- and Wowhead disagrees with both again (DPS: Haste > Crit > Mastery > Versatility; survivability:
    -- Haste > Mastery > Crit > Versatility) -- only Haste-first is universal, middle three heavily contested.
    -- PvP: confirmed 2026-09-06 -- a dedicated Skill Capped Protection Paladin PvP guide does not exist,
    -- but two spec-specific current guides do: murlok.io gives Versatility > Haste > Mastery > Crit;
    -- u.gg's top-players stat priority instead gives Versatility > Mastery > Haste > Crit -- both ends
    -- agree, middle two swapped. Weights below match murlok.io; unchanged from the prior pass.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.20,
        MASTERY = 0.80,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.30,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
SW[70] = { -- Retribution
    name = "Retribution",
    role = "DAMAGER",
    primary = "STR",
    -- PvE: confirmed 2026-09-06, full 3-source agreement (icy-veins, Wowhead, method.gg): Mastery >
    -- Haste > Crit > Versatility.
    -- PvP: CORRECTED 2026-09-06. icy-veins' Retribution PvP page is still dated 12.0.7 (not 12.1) and
    -- ranks Crit above Haste -- Versatility > Mastery > Crit > Haste -- which is what the old row below
    -- used. Two current Midnight S2 sources instead agree Haste ranks above Crit: Skill Capped's
    -- dedicated Midnight S2 Retribution PvP guide and murlok.io both give Versatility > Mastery >
    -- Haste > Crit. Swapped Haste/Crit weights to match the current-patch sources over the stale one.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Hunter ──────────────────────────────────────────────────
SW[253] = { -- Beast Mastery
    name = "Beast Mastery",
    role = "DAMAGER",
    primary = "AGI",
    -- PvE: confirmed 2026-09-06 via icy-veins, Wowhead, and method.gg (single-target default). icy-veins'
    -- and method.gg's single-target rows both agree exactly on Mastery>Haste>Crit>Versatility (kept here);
    -- their own AoE/M+ variants instead swap to Mastery>Crit>Vers/Haste, and Wowhead's Dark Ranger
    -- single-target build flips the top two to Crit>Mastery -- middle/top order is build- and
    -- content-dependent, only Mastery-first/Versatility-last hold everywhere. AoE priority differs -- see
    -- module comment.
    -- PvP: confirmed 2026-09-06 via icy-veins and Skill Capped's Midnight Season 2 BM PvP guide -- full
    -- agreement on "Versatility (to ~24%) > Mastery > Haste > Critical Strike". Versatility leads for its
    -- dual damage/damage-reduction value on a squishy spec; Crit is lowest since it's the least consistent
    -- stat in PvP burst trading.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[254] = { -- Marksmanship
    name = "Marksmanship",
    role = "DAMAGER",
    primary = "AGI",
    -- PvE: confirmed 2026-09-06 -- full 3-source agreement (icy-veins, Wowhead, method.gg), all giving the
    -- identical order Critical Strike > Mastery > Versatility > Haste ("Crit is king, Mastery pretty close
    -- behind, Versatility a chunk behind that, Haste worst by some margin" -- icy-veins). Cleanest Hunter
    -- spec, unchanged from prior pass.
    -- PvP: confirmed 2026-09-06 via icy-veins and Skill Capped's Midnight Season 2 MM PvP guide -- full
    -- agreement on "Versatility (to ~24%) > Mastery: Sniper Training > Haste > Critical Strike", same
    -- reasoning as BM (Versatility's dual value, Crit lowest).
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.10,
        VERS = 0.95,
        HASTE = 0.80,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[255] = { -- Survival
    name = "Survival",
    role = "DAMAGER",
    primary = "AGI",
    -- PvE: confirmed 2026-09-06 via icy-veins, Wowhead, and method.gg. Mastery-first/Versatility-last agreed
    -- universally. Middle Crit/Haste order is explicitly called "close enough to be interchangeable" by
    -- icy-veins, tied by Wowhead's Pack Leader build and method.gg's single-target rotation, and only
    -- splits apart in method.gg's AoE (Haste>Crit) vs icy-veins/Wowhead-Sentinel single-target (Crit>Haste,
    -- kept here).
    -- PvP: confirmed 2026-09-06 -- icy-veins and Skill Capped's Midnight Season 2 SV PvP guide DISAGREE on
    -- the top two. icy-veins: "Versatility (to ~24%) > Mastery > Haste > Crit". Skill Capped explicitly
    -- flips it to "Mastery: Spirit Bond > Versatility > Haste > Crit", reasoning that Spirit Bond's
    -- damage-dealt/damage-taken bonus (boosted within 25yd of your pet) outweighs Versatility for this
    -- spec specifically. Following Skill Capped's spec-specific reasoning here, same pattern as the
    -- Windwalker Monk PvP correction -- flagged as not unanimous.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.30,
        VERS = 1.10,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Death Knight ──────────────────────────────────────────────────
SW[250] = { -- Blood
    name = "Blood",
    role = "TANK",
    primary = "STR",
    -- PvE: San'layn build (icy-veins/Wowhead explicit; method.gg agrees Haste is the top secondary but ties Crit/Mastery/Vers below it) runs Str>Haste>Crit>Mastery>Vers -- used below as the default build. Deathbringer build instead drops Haste to LAST (icy-veins/Wowhead: Str>Crit>Mastery/Vers>Haste; method.gg: Str>Crit=Vers=Mastery>Haste) -- flagged, see module comment.
    -- PvP: confirmed 2026-09-06 via u.gg's top-players gear analysis and murlok.io's Blitz guide, both explicit and in agreement -- Versatility > Haste > Mastery > Critical Strike. No dedicated icy-veins or Skill Capped Blood PvP guide was found. Replaces the earlier guess, which had ranked Mastery above Haste.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.20,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.50,
        STAM = 1.30,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
SW[251] = { -- Frost
    name = "Frost",
    role = "DAMAGER",
    primary = "STR",
    -- PvE: re-confirmed 2026-09-06 -- icy-veins order is Crit>Haste>Mastery>Vers; Wowhead/method.gg both rank Mastery above Haste instead (Crit>Mastery>Haste>Vers, method.gg ties Mastery/Haste and notes Mastery pulls ahead in AoE) -- flagged (2-against-1 vs primary source), row kept on icy-veins' order.
    -- PvP: confirmed 2026-09-06 via Skill Capped's Midnight Season 2 Frost PvP gearing guide AND icy-veins' dedicated PvP stat-priority page, both explicit and in full agreement -- Versatility > Mastery > Haste > Critical Strike ("Crit is inherently your worst stat" per Skill Capped). No disagreement found; row already matched this order.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[252] = { -- Unholy
    name = "Unholy",
    role = "DAMAGER",
    primary = "STR",
    -- PvE: re-confirmed 2026-09-06, full 3-source agreement (icy-veins/Wowhead/method.gg) -- Crit > Mastery > Haste > Versatility.
    -- PvP: confirmed 2026-09-06, but sources DISAGREE on the middle two -- Skill Capped's Midnight S2 gearing guide gives Versatility > Haste > Mastery > Crit, while icy-veins' PvP stat-priority page AND murlok.io's 3v3 guide both give Versatility > Mastery > Haste > Crit (2-against-1 vs Skill Capped) -- flagged; row kept at the majority (icy-veins/murlok) order, unlike Blood/Frost this one is NOT unanimous.
    pve = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.30,
        MASTERY = 1.10,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 0.20,
        STR = 1.60,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Druid ──────────────────────────────────────────────────
SW[102] = { -- Balance
    name = "Balance",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified for Midnight S2: PvE Mastery>Haste>Crit>Vers confirmed by icy-veins/Wowhead/
    -- method.gg for Elune's Chosen (default); Keeper of the Grove ties Haste/Crit -- flagged.
    -- PvP Vers>Haste>Mastery>Crit confirmed by Skill Capped (explicit, self-consistent list+text)
    -- and matches icy-veins' own prose ("Versatility is the strongest... Haste is the next
    -- strongest"), even though icy-veins' own PvP stat-priority list header instead reads
    -- Haste>Vers>Mastery>Crit, contradicting its own page's text -- flagged, values unchanged.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[103] = { -- Feral
    name = "Feral",
    role = "DAMAGER",
    primary = "AGI",
    -- Re-verified for Midnight S2: PvE single-target/Druid of the Claw default Mastery>Haste>
    -- Crit>Vers agrees icy-veins+Wowhead; AoE/Wildstalker swaps to Mastery>Crit>Haste>Vers per
    -- both sites too. method.gg declines to rank at all, calling all 4 secondaries near-equal.
    -- PvP Vers>Mastery>Haste>Crit confirmed by Skill Capped (explicit, self-consistent list+
    -- text) and matches icy-veins' own prose ("Versatility is the strongest... Mastery is the
    -- next strongest"), even though icy-veins' own PvP list header instead reads Mastery>Vers>
    -- Haste>Crit, contradicting its own page's text -- flagged, values unchanged.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[104] = { -- Guardian
    name = "Guardian",
    role = "TANK",
    primary = "AGI",
    -- Re-verified for Midnight S2: PvE 'damage output' list Haste>Vers>Crit>Mastery matches
    -- Wowhead + method.gg (Haste>Vers>=Crit>Mastery); icy-veins' own 'survivability' list
    -- instead ranks Mastery above Crit -- flagged. No Skill Capped PvP guide exists for this
    -- spec, but u.gg's PvP page gives Vers>Haste>Mastery>Crit while murlok.io's top-player
    -- gear-percentage data instead shows Vers>Mastery>Haste>Crit -- flagged disagreement on the
    -- Haste/Mastery order (both agree Vers is #1 and Crit is #4); kept the u.gg ordering below.
    pve = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.20,
        MASTERY = 0.80,
        VERS = 1.10,
        HASTE = 1.30,
        CRIT = 0.95,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.30,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
SW[105] = { -- Restoration
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    -- Re-verified for Midnight S2: PvE raid/default Haste>Mastery>Vers>Crit confirmed by
    -- icy-veins raid list + Wowhead; icy-veins' own dungeon-healing variant instead leads
    -- Mastery>Haste; method.gg ties Haste=Mastery at the top and ranks Crit>=Vers for raiding
    -- (M+ instead: Vers>Crit) -- flagged. PvP CORRECTED: Mastery>Vers>Haste>Crit, confirmed by
    -- Skill Capped (explicit), icy-veins' own PvP list, AND murlok.io's top-player gear data
    -- (Mastery ~38% of secondary investment vs Haste's ~12%) -- three-source agreement. The
    -- prior version of this row ranked Versatility above Mastery, which no source supports;
    -- fixed to match the Windwalker Monk-style error caught in this same file.
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.10,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 1.30,
        VERS = 1.10,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Demon Hunter ──────────────────────────────────────────────────
SW[577] = { -- Havoc
    name = "Havoc",
    role = "DAMAGER",
    primary = "AGI",
    -- Dedicated re-verification 2026-09-06 for Midnight S2 (12.1).
    -- PvE: icy-veins, Wowhead, and method.gg unanimously agree: Crit > Mastery > Haste > Versatility
    -- (Crit favored for Know Your Enemy interactions/crit-damage scaling; Mastery multiplies Chaos
    -- damage; Versatility falls to the bottom); no ST/AoE split noted. Values already matched this
    -- order, unchanged.
    -- PvP: confirmed via Skill Capped's Midnight S2 Havoc PvP gearing guide and icy-veins' PvP stat
    -- page, both explicit: Versatility > Mastery > Haste > Crit (Versatility for its dual damage/
    -- mitigation value, Mastery for Chaos damage and movement speed). Murlok.io's Solo Shuffle guide
    -- instead ranks Mastery above Versatility -- flagged disagreement; Skill Capped and icy-veins are
    -- weighted higher as dedicated PvP sources, consistent with the Windwalker PvP precedent. Values
    -- already matched this order, unchanged.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.10,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[581] = { -- Vengeance
    name = "Vengeance",
    role = "TANK",
    primary = "AGI",
    -- Dedicated re-verification 2026-09-06 for Midnight S2 (12.1).
    -- PvE: icy-veins order kept -- Haste > Mastery > Versatility > Crit. Wowhead instead ranks
    -- Crit above Mastery (Haste > Crit > Vers > Mastery) and method.gg also puts Mastery last,
    -- near-tied with Crit/Versatility ("currently tuned very poorly defensively") -- flagged,
    -- 2-of-3 newer sources now rate Mastery as the weakest of the three behind Haste, but icy-veins
    -- strict order is kept per file convention (see Fury) pending a dedicated sim check. All sources
    -- agree Haste is the clear #1 defensive/offensive stat. Values unchanged.
    -- PvP: no dedicated Vengeance PvP guide found (confirmed 2026-09-06 -- Skill Capped's Demon
    -- Hunter guide list carries only a Havoc PvP guide for Midnight S2; no Wowhead/icy-veins
    -- Vengeance PvP stat page exists either). PvP row remains inferred from tank convention
    -- (matches Brewmaster's pattern): Versatility > Mastery > Haste > Crit. Values unchanged.
    pve = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.20,
        MASTERY = 1.10,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.30,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
SW[1480] = { -- Devourer
    name = "Devourer",
    role = "DAMAGER",
    primary = "INT",
    -- Added 2026-09-16 (spec was missing entirely -- Midnight's third DH spec, specID 1480
    -- per warcraft.wiki.gg SpecializationID). PvE sources DISAGREE, flagged not resolved:
    --   Wowhead (updated 2026-08-12): Haste (to ~800 rating / 18-20%) > Crit > Mastery > Vers,
    --     "very important you do not go much higher" than 800 Haste.
    --   Styka Sheets S2 table (Wowhead/Icy Veins 2026-09-10): 800 Haste > Crit >= Mastery >> Vers.
    --   Method.gg 12.1: Mastery > Haste > Crit > Vers (no breakpoint).
    -- Kept the 2-of-3 order (Haste>Crit>=Mastery>Vers) and recorded the 800 Haste breakpoint in
    -- softCaps so Gear/Character can stop valuing Haste past it.
    -- PvP: no spec-specific published order found (Icy Veins' Devourer PvP guide gives none);
    -- uses the generic caster PvP shape (Vers>Haste>Mastery>Crit) -- LOW confidence.
    softCaps = { HASTE = 800 },
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.025,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 1.025,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Evoker ──────────────────────────────────────────────────
SW[1467] = { -- Devastation
    name = "Devastation",
    role = "DAMAGER",
    primary = "INT",
    -- PvE: re-verified 2026-09-06. icy-veins gives Crit>Haste>Mastery>Vers; Wowhead
    -- swaps the middle two (Crit>Mastery>Haste>Vers); method.gg ties them
    -- (Crit>Haste=Mastery>Vers). Crit-first/Vers-last is unanimous -- flagged: Haste/Mastery order.
    -- PvP: confirmed 2026-09-06 via Skill Capped's Midnight Season 2 Devastation PvP gearing
    -- guide, which matches icy-veins exactly -- "Versatility, Mastery, Haste, Critical Strike".
    -- Both sources cite Versatility's damage+mitigation dual role as the reason it leads, and
    -- Crit as weakest since it "doesn't synergize as well with Devastation's toolkit." No disagreement.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[1468] = { -- Preservation
    name = "Preservation",
    role = "HEALER",
    primary = "INT",
    -- PvE: re-verified 2026-09-06. Raid default: icy-veins and method.gg agree
    -- Mastery>Crit>Haste>Vers (method.gg ties Haste/Vers); Wowhead instead swaps the top two
    -- (Crit>Mastery>Haste>Vers) -- flagged, not the "full agreement" previously claimed here.
    -- Wowhead/method.gg both note the top 3 (or all 4) flatten toward near-parity in M+.
    -- PvP: confirmed 2026-09-06 via Skill Capped's Midnight Season 2 Preservation PvP guide,
    -- which matches icy-veins exactly -- "Versatility > Haste > Mastery: Life-Binder > Critical
    -- Strike." Both cite Versatility's healing+mitigation dual role, Haste for faster casts/GCD,
    -- and Crit as weakest since it "doesn't synergize as well with Preservation's toolkit." No disagreement.
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[1473] = { -- Augmentation
    name = "Augmentation",
    role = "DAMAGER",
    primary = "INT",
    -- PvE: re-verified 2026-09-06. Wowhead gives an explicit Mastery>Crit>Haste>Vers; icy-veins
    -- agrees Mastery is well ahead of the field and Vers is "awful" (last), but says Crit/Haste
    -- order is hero-talent-dependent (Chronowarden: Crit slightly ahead; Scalecommander: tied) --
    -- flagged. method.gg gives no explicit ranked list for this patch.
    -- PvP: icy-veins gives Vers>Haste>Mastery>Crit (kept). Murlok.io's Solo Shuffle guide instead
    -- ranks Crit above Mastery (Vers>Haste>Crit>Mastery) -- flagged disagreement. No current-patch
    -- Skill Capped Augmentation PvP guide exists yet (checked 2026-09-06 -- their guide is still
    -- the pre-Midnight TWW 11.2.7 version), so icy-veins is kept as the more current dedicated source.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Mage ──────────────────────────────────────────────────
SW[62] = { -- Arcane
    name = "Arcane",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06, dedicated pass (like Rogue/Monk).
    -- PvE: icy-veins and method.gg agree on Haste > Versatility > Crit > Mastery; Wowhead splits by
    -- hero talent build -- one config matches, the other (higher Mastery) instead ranks Mastery 2nd
    -- and Crit/Vers lower. All 3 sources agree Haste is the clear #1. Corrects the prior pass, which
    -- had Crit above Mastery/Vers based on icy-veins alone.
    -- PvP: Skill Capped's Midnight Season 2 Arcane PvP guide gives an explicit order --
    -- "Versatility > Haste > Mastery > Critical Strike". Versatility leads because it's both damage
    -- and damage-reduction for a squishy caster with little built-in mitigation. icy-veins instead
    -- ranks Haste 1st and Versatility 2nd -- disagreement noted, but Skill Capped's dedicated-PvP
    -- framing is preferred here (same precedent as the WW Monk correction). Corrects the prior pass,
    -- which had Haste above Versatility.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.80,
        VERS = 1.10,
        HASTE = 1.30,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[63] = { -- Fire
    name = "Fire",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06, dedicated pass (like Rogue/Monk).
    -- PvE: icy-veins/Wowhead agree exactly on Haste > Mastery > Versatility > Crit; method.gg swaps
    -- Mastery/Vers (Haste > Vers > Mastery > Crit) -- flagged, unchanged from prior pass since the
    -- majority (2 of 3) still favors Mastery 2nd.
    -- PvP: Skill Capped's Midnight Season 2 Fire PvP guide gives an explicit order --
    -- "Versatility > Haste > Mastery: Ignite > Critical Strike". Versatility leads for its dual
    -- damage/mitigation value; Crit is called out as the weakest since it's "less reliable than other
    -- stats" despite synergy with Hot Streak. icy-veins instead ranks Haste 1st and Versatility 2nd --
    -- disagreement noted, but Skill Capped's dedicated-PvP framing is preferred (same precedent as the
    -- WW Monk correction). Corrects the prior pass, which had Haste above Versatility for PvP.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.10,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[64] = { -- Frost
    name = "Frost",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06, dedicated pass (like Rogue/Monk).
    -- PvE: full 3-source agreement -- icy-veins and Wowhead both give Mastery > Crit > Haste >
    -- Versatility exactly; method.gg ties Mastery and Crit for the top two, then Haste, then
    -- Versatility -- consistent with the same order. Cleanest Mage spec; values unchanged.
    -- PvP: icy-veins and Skill Capped's Midnight Season 2 Frost PvP guide both give the same explicit
    -- order -- "Haste > Versatility > Mastery: Freeze and Shatter > Critical Strike" -- no disagreement
    -- found between the two, unusual for PvP. Values unchanged; comment updated to record the
    -- dedicated verification pass and Skill Capped confirmation.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.10,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Monk ──────────────────────────────────────────────────
SW[268] = { -- Brewmaster
    name = "Brewmaster",
    role = "TANK",
    primary = "AGI",
    -- icy-veins 'defensive' default; Wowhead treats Vers/Crit/Mastery as near-tied. No PvP guide exists for this spec; PvP row inferred from tank convention.
    pve = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.20,
        MASTERY = 0.95,
        VERS = 1.10,
        HASTE = 0.80,
        CRIT = 1.30,
        ARMOR = 0.30,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.50,
        STR = 0.20,
        STAM = 1.30,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.30,
    },
}
SW[269] = { -- Windwalker
    name = "Windwalker",
    role = "DAMAGER",
    primary = "AGI",
    -- PvE: Haste-first/Vers-last agreed by all sources; Crit/Mastery order contested (Wowhead/method.gg tie them).
    -- PvP: confirmed 2026-09-06 via Skill Capped's Midnight Season 2 Windwalker PvP guide --
    -- explicit order "Mastery (Combo Strikes) > Versatility > Critical Strike > Haste". Mastery
    -- leads because Combo Strikes punishes repeating an ability, so more Mastery raises the
    -- payoff of good sequencing; Haste ranks last since WW gets comparatively little from a
    -- faster GCD in PvP versus the other three. Replaces the earlier unconfirmed PvP guess.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 1.30,
        VERS = 1.10,
        HASTE = 0.80,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
}
SW[270] = { -- Mistweaver
    name = "Mistweaver",
    role = "HEALER",
    primary = "INT",
    -- Raid default (Wowhead confirms exactly); M+ variant instead runs Haste>Mastery>Crit>Vers -- see module comment. PvP source has an internal rank-vs-prose contradiction -- flagged.
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 0.80,
        VERS = 0.95,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Priest ──────────────────────────────────────────────────
SW[256] = { -- Discipline
    name = "Discipline",
    role = "HEALER",
    primary = "INT",
    -- Confirmed 2026-09-06. PvE: icy-veins, Wowhead, and method.gg all independently
    -- give Haste > Mastery > Crit > Versatility for both raid and M+, and for both
    -- Oracle and Voidweaver builds (Voidweaver just targets a higher Haste breakpoint,
    -- ~1800 rating vs Oracle's ~1300) -- full agreement, no change from prior values.
    -- PvP: icy-veins' PvP stat-priority page and murlok.io's 3v3 guide agree
    -- Versatility > Mastery > Haste > Crit, but Skill Capped's Midnight S2 PvP gearing
    -- guide instead gives Mastery > Versatility > Haste > Crit (Mastery first) -- flagged
    -- disagreement; kept the 2-source majority order (unchanged from prior values).
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.10,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[257] = { -- Holy
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    -- Confirmed 2026-09-06. Raid PvE: Wowhead and method.gg agree exactly on Crit >
    -- Mastery > Versatility > Haste; icy-veins matches Crit-first/Haste-last but ties
    -- Mastery = Versatility in the middle -- used as the default per file convention
    -- (raid list is the baseline; M+ variant noted below), unchanged from prior values.
    -- M+ PvE disagrees sharply across all 3 sources -- icy-veins: Vers > Crit > Haste >
    -- Mastery; Wowhead: Crit > Vers > Haste > Mastery; method.gg: Haste > Vers = Crit >
    -- Mastery -- flagged, not reflected in the single pve row above (see module comment).
    -- PvP: icy-veins' PvP stat-priority page and murlok.io's 3v3 guide agree
    -- Versatility > Mastery > Haste > Crit, but Skill Capped's Midnight S2 PvP gearing
    -- guide instead gives Mastery > Versatility > Haste > Crit (Mastery first) -- same
    -- Skill-Capped-vs-rest split found on Discipline; flagged, kept the 2-source
    -- majority order (unchanged from prior values).
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.10,
        VERS = 0.95,
        HASTE = 0.80,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[258] = { -- Shadow
    name = "Shadow",
    role = "DAMAGER",
    primary = "INT",
    -- Confirmed 2026-09-06. PvE: icy-veins splits the order by hero talent AND content
    -- (Archon single-target: Mastery > Crit > Haste > Vers; Voidweaver single-target:
    -- Mastery > Haste > Crit > Vers; Archon AoE/M+: Mastery > Haste > Crit > Vers;
    -- Voidweaver AoE/M+: Haste > Mastery > Crit > Vers), while Wowhead and method.gg
    -- both give a flat Haste >= Mastery > Crit > Vers for both builds; murlok.io's M+
    -- page gives Mastery > Haste > Crit > Vers. Mastery-vs-Haste for the #1 slot is
    -- genuinely split across sources and stays flagged (kept Mastery first, matching
    -- the majority of the build/content-specific pages). What IS corrected here: every
    -- source except icy-veins' single Archon-ST variant ranks Haste above Crit, so
    -- Haste and Crit are swapped from the prior pass (which had Crit 2nd, Haste 3rd);
    -- Versatility is undisputed last across every source.
    -- PvP: confirmed via Skill Capped's Midnight S2 PvP gearing guide, which
    -- independently matches icy-veins' own numbered stat list -- both give
    -- Haste > Versatility > Mastery > Crit (unchanged from prior values). icy-veins'
    -- prose elsewhere claims Versatility is the single best PvP stat, contradicting its
    -- own list; disregarded since two independent numbered lists agree with each other.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.10,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Rogue ──────────────────────────────────────────────────
SW[259] = { -- Assassination
    name = "Assassination",
    role = "DAMAGER",
    primary = "AGI",
    -- 3-of-4 sources agree (MythicSim sim-weights are the outlier, swapping Haste/Crit). No dedicated PvP stat page found; PvP row inferred from general convention -- flagged low confidence.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[260] = { -- Outlaw
    name = "Outlaw",
    role = "DAMAGER",
    primary = "AGI",
    -- icy-veins order; Wowhead/method.gg instead lead with Haste -- flagged. Single-target favors ~30% Haste vs ~25% in AoE. PvP row inferred, low confidence.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.80,
        VERS = 0.95,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[261] = { -- Subtlety
    name = "Subtlety",
    role = "DAMAGER",
    primary = "AGI",
    -- icy-veins/Wowhead agree (non-split); method.gg splits by hero talent (Trickster vs Deathstalker) with different Crit/Vers placement -- flagged. PvP row inferred, low confidence.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.95,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Shaman ──────────────────────────────────────────────────
SW[262] = { -- Elemental
    name = "Elemental",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06. PvE: icy-veins (Mastery>Haste>Crit>Vers) agrees with Wowhead
    -- that Mastery is #1 and Vers is #4, but Wowhead ties Crit/Haste for 2nd/3rd -- flagged.
    -- PvP: icy-veins AND Skill Capped's dedicated 12.1 S2 PvP guide agree unanimously --
    -- Vers>Haste>Mastery>Crit, the reverse top stat from PvE.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 0.95,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[263] = { -- Enhancement
    name = "Enhancement",
    role = "DAMAGER",
    primary = "AGI",
    -- Re-verified 2026-09-06. Stormbringer is icy-veins' confirmed S2 meta build (raid AND
    -- M+); its PvE order per icy-veins is Mastery>Crit>Haste>Vers (used below), though Wowhead
    -- instead ties Crit=Mastery for Stormbringer, and ranks Totemic as Mastery=Haste(tied)>Crit>Vers.
    -- method.gg's build-agnostic list conflicts further: Mastery>=Haste>Crit>=Vers -- flagged.
    -- PvP: icy-veins AND Skill Capped agree unanimously -- Vers>Haste>Mastery>Crit.
    pve = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        VERS = 0.80,
        HASTE = 0.95,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 0.20,
        AGI = 1.60,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[264] = { -- Restoration
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    -- Re-verified 2026-09-06. PvE: icy-veins (Crit>Vers>Haste>Mastery) and Wowhead
    -- (Crit>[Haste=Vers tied]>Mastery, "Mastery performing historically bad this season")
    -- agree Crit is #1 and Mastery is #4; middle two contested/near-tied -- flagged. Mastery
    -- regains value in prog raiding/low-health-heavy fights per icy-veins. PvP: icy-veins
    -- (Vers>Mastery>Haste>Crit) matches murlok.io's real top-rated-player gear data, but
    -- Skill Capped's dedicated PvP guide instead has Mastery>Vers>Crit>Haste (Mastery #1,
    -- Crit #3 not last) -- unresolved 1-vs-2 disagreement, majority order kept below.
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 0.80,
        VERS = 1.10,
        HASTE = 0.95,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        MASTERY = 1.10,
        VERS = 1.30,
        HASTE = 0.95,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
-- ── Warlock ──────────────────────────────────────────────────
SW[265] = { -- Affliction
    name = "Affliction",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06. PvE: icy-veins and Wowhead both lead Haste>Crit; method.gg
    -- (single-target) instead leads with Crit. Kept Haste>Crit>Mastery>Vers (icy-veins exact
    -- order); Wowhead flips the bottom two to Vers>Mastery -- flagged.
    -- PvP: icy-veins (12.1, current), ArenaCoach, and murlok.io 3v3 top-player data all agree
    -- Versatility>Haste as the top two. ArenaCoach/murlok then rank Mastery>Crit; icy-veins
    -- reverses to Crit>Mastery -- flagged, went with the 2-source majority (Mastery 3rd, not
    -- last as previously modeled). Skill Capped's Midnight S2 guide instead claims
    -- Haste>Versatility>Mastery>Crit (Haste #1) -- an outlier contradicted by 3 other
    -- current-season sources including icy-veins itself, so NOT adopted here (unlike the
    -- Windwalker Monk case where Skill Capped was the uniquely correct source).
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[266] = { -- Demonology
    name = "Demonology",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06. PvE: icy-veins, Wowhead, and method.gg all agree Crit is #1 and
    -- Vers is #4, but disagree on Haste vs Mastery placement (Wowhead ties Haste=Crit at #1,
    -- method ties Haste=Mastery in the middle, icy-veins ranks Mastery above the
    -- post-breakpoint remainder of Haste) -- went with Crit>Haste>Mastery>Vers as the closest
    -- average across sources; corrects the prior (incorrect) Haste-first value.
    -- PvP: confirmed via murlok.io 3v3 AND RBG top-player data (both current Midnight S2):
    -- Versatility>Haste>Mastery>Crit, matching the pattern of icy-veins' own PvP page (though
    -- that page is explicitly still dated 12.0.7, not confirmed current). Skill Capped's
    -- current 12.1 guide instead gives Haste>Versatility>Crit>Mastery -- flagged disagreement,
    -- not adopted since two independent current top-player-data sources agree against it.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.10,
        CRIT = 1.30,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.30,
        HASTE = 1.10,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[267] = { -- Destruction
    name = "Destruction",
    role = "DAMAGER",
    primary = "INT",
    -- Re-verified 2026-09-06. PvE: Wowhead and method.gg agree Haste leads and Vers trails;
    -- the Crit/Mastery middle two are given as a near-tie by both ("Mastery>=Crit" /
    -- "Crit=Mastery"), while icy-veins ranks Crit outright above Mastery -- kept
    -- Haste>Crit>Mastery>Vers (icy-veins' explicit order, within the other sources' tie).
    -- PvP: confirmed via TWO current Midnight S2 sources -- icy-veins (12.1) and Skill
    -- Capped's dedicated PvP guide -- both give the identical order
    -- Haste>Versatility>Mastery>Crit (Haste-first, NOT Versatility -- the one Warlock spec
    -- where Vers isn't PvP-#1). u.gg's top-player-data page instead shows
    -- Versatility>Haste>Mastery>Crit -- flagged minority disagreement, not adopted given the
    -- 2-source agreement including a fresh, spec-specific Skill Capped citation.
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 0.95,
        VERS = 0.80,
        HASTE = 1.30,
        CRIT = 1.10,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        MASTERY = 0.95,
        VERS = 1.10,
        HASTE = 1.30,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Lookup helper ─────────────────────────────────────────────────────
function SW:GetWeights(specID, mode)
    local spec = self[specID]
    if not spec then
        return nil
    end
    return spec[mode or "pve"]
end

function SW:GetRole(specID)
    local spec = self[specID]
    return spec and spec.role or "DAMAGER"
end

function SW:GetPrimary(specID)
    local spec = self[specID]
    return spec and spec.primary or "INT"
end

function SW:ScoreItem(stats, specID, mode)
    local weights = self:GetWeights(specID, mode)
    if not weights then
        return 0
    end
    local score = 0
    for stat, value in pairs(stats) do
        score = score + (weights[stat] or 0.2) * value
    end
    return math.floor(score)
end
