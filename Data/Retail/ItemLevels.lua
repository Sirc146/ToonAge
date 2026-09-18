-- ToonAge/Data/Zones.lua
-- Midnight Season 2 "Curse of Ula'tek" ilvl data (Patch 12.1)
-- Re-verified 2026-09-05 — see comment block below for sourcing and what
-- changed from the Season 1 numbers this file used to carry.
--
-- ┌─────────────────────────────────────────────────────────────────────┐
-- │ SOURCING / CONFIDENCE NOTES                                         │
-- │                                                                     │
-- │ Two independent research passes confirmed a full ilvl rebase for    │
-- │ Season 2 (Blizzard did this deliberately — a community-manager      │
-- │ forum post, quoted below, confirms a late +7 ilvl bump was added on │
-- │ top of an already-planned +39, for a total +46 shift). EVERY        │
-- │ absolute ilvl number in this file's Season 1 version is stale.      │
-- │                                                                     │
-- │ HIGH CONFIDENCE (directly quoted from icy-veins.com, wowhead.com,   │
-- │ method.gg, and news.blizzard.com / us.forums.blizzard.com):         │
-- │  • Gear track ilvl ranges (Z.TRACKS below)                          │
-- │  • Raid name: "Curse of Ula'tek: The Venomous Abyss" (8 bosses)     │
-- │  • Raid Finder minimum item level to queue: 273 (Blizzard's own     │
-- │    news post, verbatim: "Raid Finder Minimum Item Level: 273")      │
-- │  • Mythic+ Season 2 dungeon pool: complete swap from Season 1 —     │
-- │    Altar of Fangs, Murder Row, Den of Nalorakk, The Blinding Vale,  │
-- │    Voidscar Arena (new), plus legacy returns King's Rest, Temple of │
-- │    Sethraliss, Ruby Life Pools. Confirmed by Wowhead + method.gg.   │
-- │                                                                     │
-- │ MODERATE CONFIDENCE (consistent across 2-3 secondary sources, not   │
-- │ independently re-verified against a primary Blizzard source):       │
-- │  • Per-difficulty raid loot ilvl (LFR/Normal/Heroic/Mythic)         │
-- │  • Mythic+ key-bracket → reward ilvl mapping                        │
-- │  • Crest currency renamed to "Mistcrest" (tiered same as tracks)    │
-- │  • Chase-tier cap above Myth: ~341-344 via a new "Ascendant         │
-- │    Venomstones" currency, dropped by the raid's last two Mythic     │
-- │    bosses only                                                      │
-- │                                                                     │
-- │ LOW CONFIDENCE / UNRESOLVED — do not treat as accurate:              │
-- │  • PvP gear ilvl (Honor/Conquest). Sources disagreed with each      │
-- │    other (324 vs 331 for Honor from the same secondary article) and │
-- │    no source could confirm what ilvl PvP gear scales UP to inside   │
-- │    rated arenas/BGs (Season 1 had this hard-coded at 276 — that     │
-- │    number is now IN NO WAY confirmed for Season 2 and has been      │
-- │    removed rather than guessed at). Verify at the in-game PvP       │
-- │    vendor before trusting any PvP ilvl figure from this file.       │
-- │                                                                     │
-- │ NOT INCLUDED — per-zone map IDs (Z[mapID] entries the Season 1      │
-- │ version of this file had for specific dungeons/raids/zones). The    │
-- │ Season 1 IDs were suspiciously clean sequential numbers (2432-2436, │
-- │ 2450-2457, 2480-2487) rather than the arbitrary values real         │
-- │ Blizzard map IDs actually have — they were very likely placeholder  │
-- │ guesses that happened to silently never match a real zone, the same │
-- │ class of bug already found and fixed once in this addon's PvP       │
-- │ talent data (nodeID=0 placeholders that could never match a live    │
-- │ client's real IDs). Rather than repeat that mistake with fabricated │
-- │ IDs for the new Season 2 raid/dungeons, this table is left empty;   │
-- │ Z:GetIlvlRequirement()'s content-type fallback covers the general   │
-- │ case without needing them. To populate it for real: stand in a zone │
-- │ in-game and run `/dump C_Map.GetBestMapForUnit("player")` to get    │
-- │ its true map ID, then add a Z[thatID] = {...} entry below.          │
-- │                                                                     │
-- │ Sources: icy-veins.com/wow/delves-guide, icy-veins.com/wow/news/    │
-- │ item-level-of-loot-in-midnight-season-2/, method.gg/guides/all-     │
-- │ midnight-season-2-upgrade-tracks-and-item-levels, wowhead.com/guide │
-- │ /midnight/mythic-plus-season-overview, news.blizzard.com articles   │
-- │ 24295090 (pre-season) and 24294062 (raid launch), and a Blizzard    │
-- │ community-manager (Kaivax) forum post on the +46 ilvl adjustment.   │
-- └─────────────────────────────────────────────────────────────────────┘

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Zones = {}
local Z = TA.Data.Zones

-- ── Content type enum ──────────────────────────────────────────────────
Z.TYPE = {
    WORLD = "world",
    DUNGEON = "dungeon",
    MYTHIC = "mythic_plus",
    RAID = "raid",
    PVP = "pvp",
    DELVE = "delve",
}

-- ── Upgrade track data (Midnight Season 2, Patch 12.1) ─────────────────
-- Sources re-checked 2026-09-16: Icy Veins "Five Mistcrests" (2026-08-11) for crest
-- sources, Wowhead Mythic+ Season 2 overview (2026-08-14) for key-level loot/vault ilvls.
-- Each track's 6 upgrade steps, low → high. Ranges deliberately overlap at
-- the edges (e.g. Adventurer 6/6 = 282, Veteran 1/6 = 279) — that's how
-- Blizzard's own track system works, not a data error.
Z.TRACKS = {
    adventurer = {
        name = "Adventurer",
        ilvlMin = 266,
        ilvlMax = 282,
        source = "Delves Tier 1-4, repeatable outdoor events",
        currency = "Adventurer Mistcrest",
        note = "Entry level — good starting point for fresh 90s",
    },
    veteran = {
        name = "Veteran",
        ilvlMin = 279,
        ilvlMax = 295,
        source = "Heroic Dungeons, LFR, Delves Tier 5-6",
        currency = "Veteran Mistcrest",
        note = "Mid catch-up — accessible without a static group (Mythic+ starts at Champion)",
    },
    champion = {
        name = "Champion",
        ilvlMin = 292,
        ilvlMax = 308,
        source = "Mythic 0, Mythic+ +2 to +5, Normal Raid, Delves Tier 7-10",
        currency = "Champion Mistcrest",
        note = "Serious endgame entry — requires coordinated group",
    },
    hero = {
        name = "Hero",
        ilvlMin = 305,
        ilvlMax = 321,
        source = "Heroic Raid, Mythic+ +6 and up, Great Vault from +2 keys",
        currency = "Hero Mistcrest",
        note = "High-end content — Hero Mistcrests from +4 to +8 keys and Delve Tier 11",
    },
    myth = {
        name = "Myth",
        ilvlMin = 318,
        ilvlMax = 334,
        source = "Mythic Raid, Great Vault from +10 keys or Heroic raid (12.1)",
        currency = "Myth Mistcrest",
        note = "Pinnacle tier — Myth Mistcrests from +9 keys and Mythic raid",
    },
}

-- Above Myth 6/6 (334) there's an additional ~337-344 chase tier upgraded
-- with a separate currency ("Ascendant Venomstones") rather than Mistcrests,
-- dropped only by the raid's last two Mythic bosses — moderate confidence,
-- not a formal named track, so it's not in Z.TRACKS above. Referenced here
-- so GetTrack() below doesn't mis-report a fully BiS player as "Myth" only.
Z.CHASE_TIER_ILVL = 337

-- ── Get track for a given ilvl ─────────────────────────────────────────
function Z:GetTrack(ilvl)
    if ilvl >= self.TRACKS.myth.ilvlMin then
        return self.TRACKS.myth
    elseif ilvl >= self.TRACKS.hero.ilvlMin then
        return self.TRACKS.hero
    elseif ilvl >= self.TRACKS.champion.ilvlMin then
        return self.TRACKS.champion
    elseif ilvl >= self.TRACKS.veteran.ilvlMin then
        return self.TRACKS.veteran
    elseif ilvl >= self.TRACKS.adventurer.ilvlMin then
        return self.TRACKS.adventurer
    else
        return nil
    end
end

-- ── Readiness thresholds ───────────────────────────────────────────────
-- What avg ilvl you need to participate meaningfully in each content type.
-- Moderate confidence — Blizzard doesn't publish crisp gates for most of
-- this; these are triangulated from guide commentary plus the one hard
-- number Blizzard did publish (raid_lfr's min=273, "Raid Finder Minimum
-- Item Level: 273", quoted verbatim from their own raid-launch news post).
Z.READINESS = {
    -- Open world / leveling
    world_questing = { min = 0, rec = 266, label = "World quests" },
    delve_low = { min = 255, rec = 266, label = "Delves Tier 1-4" },
    delve_high = { min = 279, rec = 292, label = "Delves Tier 5-8 (loot caps at T8)" },
    -- Dungeons
    heroic_dungeon = { min = 255, rec = 266, label = "Heroic dungeon" },
    mythic0 = { min = 272, rec = 292, label = "Mythic 0" },
    mythic_low = { min = 285, rec = 295, label = "Mythic+ (+2 to +5)" },
    mythic_mid = { min = 298, rec = 305, label = "Mythic+ (+6 to +9)" },
    mythic_high = { min = 305, rec = 311, label = "Mythic+ (+10 and above)" },
    -- Raids
    raid_lfr = { min = 255, rec = 273, label = "Raid Finder (Curse of Ula'tek)" },
    raid_normal = { min = 273, rec = 292, label = "Normal raid" },
    raid_heroic = { min = 292, rec = 305, label = "Heroic raid" },
    raid_mythic = { min = 305, rec = 318, label = "Mythic raid" },
}

-- ── Content type detection from instance type ──────────────────────────
function Z:GetContentType()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return Z.TYPE.WORLD
    end
    if instanceType == "raid" then
        return Z.TYPE.RAID
    end
    if instanceType == "party" then
        return Z.TYPE.DUNGEON
    end
    if instanceType == "pvp" then
        return Z.TYPE.PVP
    end
    if instanceType == "scenario" then
        return Z.TYPE.DELVE
    end
    return Z.TYPE.WORLD
end

-- ── Content readiness assessment ────────────────────────────────────────
-- Reads its numbers from Z.READINESS above (single source of truth) —
-- this list only supplies the display order/label, not a second copy of
-- the thresholds, so the two tables can't drift out of sync with each other.
function Z:GetReadiness(avgIlvl)
    -- Find the highest content tier this character is ready for
    local tiers = {
        { key = "mythic_high", label = "Mythic+ 10+" },
        { key = "raid_mythic", label = "Mythic Raid" },
        { key = "mythic_mid", label = "Mythic+ 6-9" },
        { key = "raid_heroic", label = "Heroic Raid" },
        { key = "mythic_low", label = "Mythic+ 2-5" },
        { key = "raid_normal", label = "Normal Raid" },
        { key = "mythic0", label = "Mythic 0" },
        { key = "delve_high", label = "Delves Tier 5+" },
        { key = "heroic_dungeon", label = "Heroic Dungeon" },
        { key = "delve_low", label = "Delves Tier 1-4" },
        { key = "world_questing", label = "World content" },
    }

    local highestReady = nil
    local nextTarget = nil

    for _, tier in ipairs(tiers) do
        local threshold = self.READINESS[tier.key]
        if threshold then
            if avgIlvl >= threshold.rec and not highestReady then
                highestReady = tier
            elseif avgIlvl < threshold.rec and not nextTarget and avgIlvl >= threshold.min then
                nextTarget = tier
            end
        end
    end

    return highestReady, nextTarget
end

-- ── ilvl gap analysis ────────────────────────────────────────────────────
function Z:GetGapAnalysis(avgIlvl)
    -- How far from each major milestone
    local milestones = {
        { ilvl = 266, label = "Heroic Dungeon ready", color = { 0.29, 1, 0.48 } },
        { ilvl = 273, label = "Raid Finder ready", color = { 0.29, 1, 0.48 } },
        { ilvl = 292, label = "Mythic 0 / Normal Raid / Champion", color = { 1, 0.82, 0 } },
        { ilvl = 305, label = "Heroic Raid / Hero gear", color = { 1, 0.82, 0 } },
        { ilvl = 318, label = "Mythic Raid / Myth gear", color = { 1, 0.60, 0.10 } },
        { ilvl = 334, label = "Myth max ilvl (6/6)", color = { 1, 0.27, 0.27 } },
        { ilvl = 344, label = "Season chase cap (Mythic Ula'tek drops)", color = { 0.80, 0.27, 1.00 } },
    }

    local result = {}
    for _, m in ipairs(milestones) do
        local gap = m.ilvl - avgIlvl
        if gap > 0 then
            table.insert(result, {
                label = m.label,
                ilvl = m.ilvl,
                gap = gap,
                color = m.color,
            })
        end
    end
    return result
end

-- ── Zone-specific map data ───────────────────────────────────────────────
-- Intentionally empty for Season 2 — see the sourcing note at the top of
-- this file for why. Z:GetIlvlRequirement() below falls back to
-- content-type defaults when a zone isn't listed here, so nothing breaks;
-- this table can be filled in with real map IDs captured from a live
-- client (see the note at the top of the file for how) as they're found.

-- ── Zone ilvl lookup ─────────────────────────────────────────────────────
function Z:GetCurrent()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID and self[mapID] or nil
end

function Z:GetIlvlRequirement()
    local zone = self:GetCurrent()
    if zone then
        return zone.recMin, zone.recIlvl
    end
    -- Default by content type
    local ct = self:GetContentType()
    if ct == Z.TYPE.RAID then
        return 273, 292
    end
    if ct == Z.TYPE.DUNGEON then
        return 255, 266
    end
    if ct == Z.TYPE.DELVE then
        return 255, 266
    end
    return 0, 266
end

function Z:GetContentTypeName()
    local ct = self:GetContentType()
    local zone = self:GetCurrent()
    if zone then
        return zone.name
    end
    local names = {
        [Z.TYPE.WORLD] = "world content",
        [Z.TYPE.DUNGEON] = "dungeon",
        [Z.TYPE.MYTHIC] = "Mythic+",
        [Z.TYPE.RAID] = "raid",
        [Z.TYPE.PVP] = "PvP",
        [Z.TYPE.DELVE] = "delve",
    }
    return names[ct] or "current content"
end

function Z:IsReady(playerIlvl)
    local min, rec = self:GetIlvlRequirement()
    if playerIlvl >= rec then
        return "ready", rec
    end
    if playerIlvl >= min then
        return "marginal", rec
    end
    return "not_ready", min
end

-- ── Upgrade sources by content type ─────────────────────────────────────
Z.UPGRADE_SOURCES = {
    solo = {
        {
            name = "Delves Tier 1-4",
            ilvl = "266-276",
            track = "Adventurer",
            note = "Solo or duo — fastest catch-up route",
        },
        {
            name = "World quests",
            ilvl = "266-282",
            track = "Adventurer",
            note = "Check for high ilvl item rewards daily",
        },
        {
            name = "Delves Tier 5-6",
            ilvl = "279-282",
            track = "Veteran",
            note = "Harder solo content, Veteran track gear",
        },
        {
            name = "Delves Tier 7-8 (loot cap)",
            ilvl = "292-295",
            track = "Champion",
            note = "Loot doesn't improve past Tier 8 — Tiers 9-11 give crests only",
        },
        {
            name = "Bountiful Delve",
            ilvl = "282-305",
            track = "Veteran/Champion",
            note = "Weekly cache from highest tier delve",
        },
    },
    lfg = {
        { name = "Heroic dungeon", ilvl = "266-282", track = "Adventurer", note = "Queue via Dungeon Finder" },
        { name = "Mythic 0", ilvl = "292", track = "Champion", note = "Requires premade group — no timer" },
        {
            name = "Raid Finder (Curse of Ula'tek)",
            ilvl = "273-289",
            track = "Adventurer/Veteran",
            note = "Looking for Raid — no group needed; 273 to queue",
        },
        { name = "Normal Raid", ilvl = "292-302", track = "Champion", note = "Curse of Ula'tek: The Venomous Abyss, Normal" },
        { name = "Mythic+ 2-5", ilvl = "295-302", track = "Champion", note = "End-of-dungeon chest" },
        { name = "Mythic+ 6-9", ilvl = "305-308", track = "Hero", note = "Weekly vault at +6 gives Hero gear" },
        { name = "Heroic Raid", ilvl = "305-315", track = "Hero", note = "Curse of Ula'tek: The Venomous Abyss, Heroic" },
        { name = "Mythic+ 10+", ilvl = "311-318", track = "Myth", note = "Weekly vault at +10 gives Myth gear" },
        { name = "Mythic Raid", ilvl = "318-328", track = "Myth", note = "Last 2 bosses drop ~344 chase items (Ascendant Venomstones to upgrade)" },
    },
    pvp = {
        {
            name = "Unranked BG / Skirmish",
            ilvl = "?",
            track = "Honor",
            note = "PvP ilvl for Season 2 is unconfirmed — verify at the Honor/Conquest vendor in-game rather than trusting a fixed number here",
        },
        {
            name = "Rated Arena / RBG",
            ilvl = "?",
            track = "Conquest",
            note = "Conquest gear — requires rating; exact ilvl unconfirmed for Season 2, check vendor",
        },
    },
}

-- ── Scaling system detection ─────────────────────────────────────────────
-- The four scaling systems from the document:
-- 1. Timewalking: your ilvl is DOWN-scaled to legacy baseline
-- 2. PvP: your gear UP-scales to PvP ilvl (shown on item tooltip)
-- 3. Chromie Time: world scales TO you while leveling
-- 4. Max-level open world: monsters scale slightly WITH your ilvl

function Z:GetScalingContext()
    local inInstance, instanceType = IsInInstance()
    local level = UnitLevel("player")
    local avgIlvl = 0
    local _, equipped = GetAverageItemLevel()
    avgIlvl = math.floor(equipped or 0)

    -- Timewalking detection
    -- C_PlayerInfo.GetContentDifficultyCreatureForPlayer or check instance difficulty
    local difficultyID = select(3, GetInstanceInfo())
    -- Timewalking difficulties: 24=Normal TW, 33=Heroic TW, others
    local isTW = (difficultyID == 24 or difficultyID == 33 or difficultyID == 151 or difficultyID == 152)

    -- PvP detection
    local inPvP = false
    if C_PvP and C_PvP.IsActiveBattlefield then
        inPvP = C_PvP.IsActiveBattlefield() or false
    end
    if not inPvP and instanceType == "pvp" then
        inPvP = true
    end

    -- Chromie Time / leveling detection
    local isChromieTime = false
    if C_ChromieTime and C_ChromieTime.GetChromieTimeExpansionOption then
        local opt = C_ChromieTime.GetChromieTimeExpansionOption()
        isChromieTime = opt ~= nil and opt ~= 0
    end
    -- Also detect via level — Midnight max is 90
    local isLeveling = (level < 90)

    -- Effective ilvl context
    local effectiveIlvl = avgIlvl
    local scalingNote = nil

    if isTW then
        -- Timewalking compresses gear to ~50 of that expansion
        effectiveIlvl = math.min(avgIlvl, 50)
        scalingNote = "Timewalking: your gear is DOWN-scaled to legacy ilvl ~" .. effectiveIlvl
    elseif inPvP then
        -- PvP gear ilvl scaling for Season 2 isn't reliably confirmed (see
        -- Z.UPGRADE_SOURCES.pvp note) — deliberately not stating a specific
        -- "scales up to X" number here since the last one we had (276, from
        -- Season 1) is stale and no verified Season 2 replacement was found.
        scalingNote = "PvP: gear scales UP in arenas/BGs — check the Honor/Conquest vendor for this season's actual PvP ilvl"
    elseif isChromieTime or isLeveling then
        scalingNote = "Leveling: world scales to your level — gear ilvl matters less than levels gained"
    elseif not inInstance then
        scalingNote = "Open world: enemies scale softly with your ilvl — you outscale most world content above 282"
    end

    return {
        effectiveIlvl = effectiveIlvl,
        isTW = isTW,
        inPvP = inPvP,
        isLeveling = isLeveling,
        isChromieTime = isChromieTime,
        scalingNote = scalingNote,
    }
end

-- ── PvP ilvl helper ──────────────────────────────────────────────────────
-- PvP gear has two ilvl values — base and PvP-scaled
-- The scaled value is what matters in arenas/BGs
-- We read this from item tooltip data when available
function Z:GetPvPScaledIlvl(itemLink)
    if not itemLink then
        return nil
    end
    -- PvP ilvl is in the item tooltip as a bonus stat line
    -- Format: "In PvP combat: Item Level X"
    -- C_Item.GetItemStatDelta or tooltip scanning needed
    -- For now return nil (not easily readable without tooltip scan)
    return nil
end
