-- CharacterAdvisor/Data/Zones.lua
-- Midnight Season 1 ilvl data (Patch 12.0.5)
-- Source: Official Blizzard gear track table + community verification

local CA = CharacterAdvisor
CA.Data = CA.Data or {}
CA.Data.Zones = {}
local Z = CA.Data.Zones

-- ── Content type enum ──────────────────────────────────────────────────
Z.TYPE = {
    WORLD   = "world",
    DUNGEON = "dungeon",
    MYTHIC  = "mythic_plus",
    RAID    = "raid",
    PVP     = "pvp",
    DELVE   = "delve",
}

-- ── Upgrade track data (Midnight Season 1, Patch 12.0.5) ──────────────
-- Source document confirmed exact ranges:
-- Adventurer: 220-237  Veteran: 233-250  Champion: 246-263
-- Hero: 259-276        Myth: 272-289     Hard cap: 298 (Voidforge/Sporefused)
Z.TRACKS = {
    adventurer = { name="Adventurer", ilvlMin=220, ilvlMax=237,
        source="Heroic Dungeons, Delves Tier 1-4",
        currency="Weathered Harbinger Crest",
        note="Entry level — good starting point for fresh 90s" },
    veteran    = { name="Veteran",    ilvlMin=233, ilvlMax=250,
        source="Low Mythic+ Keys, Bountiful Delves Tier 5-6",
        currency="Carved Harbinger Crest",
        note="Mid catch-up — accessible without a static group" },
    champion   = { name="Champion",   ilvlMin=246, ilvlMax=263,
        source="Mythic 0 Dungeons, Normal Raid (Voidspire/Dreamrift)",
        currency="Runed Harbinger Crest",
        note="Serious endgame entry — requires coordinated group" },
    hero       = { name="Hero",       ilvlMin=259, ilvlMax=276,
        source="Heroic Raid, Mythic+ Keys (+6 to +10)",
        currency="Gilded Harbinger Crest",
        note="High-end content — weekly key reward at +7 and above" },
    myth       = { name="Myth",       ilvlMin=272, ilvlMax=289,
        source="Mythic Raid, Weekly Great Vault (+10 keys)",
        currency="Myth Track Upgrade",
        note="Pinnacle tier — requires Mythic raid or 10+ keys" },
    voidforge  = { name="Voidforge",  ilvlMin=290, ilvlMax=298,
        source="Voidforge upgrades (12.0.5) + Sporefused Mythic lockout drops",
        currency="Voidforged Shard",
        note="Hard ceiling — for fully optimized Mythic raiders only" },
}

-- ── Get track for a given ilvl ─────────────────────────────────────────
function Z:GetTrack(ilvl)
    if ilvl >= 290 then return self.TRACKS.voidforge
    elseif ilvl >= 272 then return self.TRACKS.myth
    elseif ilvl >= 259 then return self.TRACKS.hero
    elseif ilvl >= 246 then return self.TRACKS.champion
    elseif ilvl >= 233 then return self.TRACKS.veteran
    elseif ilvl >= 220 then return self.TRACKS.adventurer
    else return nil end
end

-- ── Readiness thresholds ───────────────────────────────────────────────
-- What avg ilvl you need to participate meaningfully in each content type
Z.READINESS = {
    -- Open world / leveling
    world_questing  = { min=0,   rec=220, label="World quests" },
    delve_low       = { min=210, rec=220, label="Delves Tier 1-4" },
    delve_high      = { min=233, rec=246, label="Delves Tier 5-8" },
    -- Dungeons
    heroic_dungeon  = { min=210, rec=220, label="Heroic dungeon" },
    mythic0         = { min=220, rec=233, label="Mythic 0" },
    mythic_low      = { min=233, rec=246, label="Mythic+ (+2 to +5)" },
    mythic_mid      = { min=246, rec=259, label="Mythic+ (+6 to +9)" },
    mythic_high     = { min=259, rec=272, label="Mythic+ (+10 and above)" },
    -- Raids
    raid_lfr        = { min=220, rec=233, label="LFR (Voidspire/Dreamrift)" },
    raid_normal     = { min=233, rec=246, label="Normal raid" },
    raid_heroic     = { min=246, rec=259, label="Heroic raid" },
    raid_mythic     = { min=259, rec=272, label="Mythic raid" },
}

-- ── Content type detection from instance type ──────────────────────────
function Z:GetContentType()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return Z.TYPE.WORLD end
    if instanceType == "raid"    then return Z.TYPE.RAID    end
    if instanceType == "party"   then return Z.TYPE.DUNGEON end
    if instanceType == "pvp"     then return Z.TYPE.PVP     end
    if instanceType == "scenario"then return Z.TYPE.DELVE   end
    return Z.TYPE.WORLD
end

-- ── Content readiness assessment ──────────────────────────────────────
function Z:GetReadiness(avgIlvl)
    -- Find the highest content tier this character is ready for
    local tiers = {
        { key="mythic_high",  label="Mythic+ 10+",    recMin=272 },
        { key="raid_mythic",  label="Mythic Raid",    recMin=272 },
        { key="mythic_mid",   label="Mythic+ 6-9",    recMin=259 },
        { key="raid_heroic",  label="Heroic Raid",    recMin=259 },
        { key="mythic_low",   label="Mythic+ 2-5",    recMin=246 },
        { key="raid_normal",  label="Normal Raid",    recMin=246 },
        { key="mythic0",      label="Mythic 0",       recMin=233 },
        { key="delve_high",   label="Delves Tier 5+", recMin=233 },
        { key="heroic_dungeon",label="Heroic Dungeon",recMin=220 },
        { key="delve_low",    label="Delves Tier 1-4",recMin=210 },
        { key="world_questing",label="World content", recMin=0   },
    }

    local highestReady = nil
    local nextTarget   = nil

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

-- ── ilvl gap analysis ─────────────────────────────────────────────────
function Z:GetGapAnalysis(avgIlvl)
    -- How far from each major milestone
    local milestones = {
        { ilvl=220, label="Heroic Dungeon ready",   color={0.29,1,0.48}   },
        { ilvl=233, label="Mythic 0 / Veteran gear",color={0.29,1,0.48}   },
        { ilvl=246, label="Normal Raid / Champion", color={1,0.82,0}       },
        { ilvl=259, label="Heroic Raid / Hero gear",color={1,0.82,0}       },
        { ilvl=272, label="Mythic Raid / Myth gear",color={1,0.60,0.10}    },
        { ilvl=289, label="Myth max ilvl",          color={1,0.27,0.27}    },
        { ilvl=298, label="Hard cap (Voidforge)",   color={0.80,0.27,1.00} },
    }

    local result = {}
    for _, m in ipairs(milestones) do
        local gap = m.ilvl - avgIlvl
        if gap > 0 then
            table.insert(result, {
                label = m.label,
                ilvl  = m.ilvl,
                gap   = gap,
                color = m.color,
            })
        end
    end
    return result
end

-- ── Zone-specific map data ─────────────────────────────────────────────
Z[2432] = { name="Quel'Thalas",      type=Z.TYPE.WORLD,   recMin=220, recIlvl=233 }
Z[2433] = { name="Silvermoon City",  type=Z.TYPE.WORLD,   recMin=0,   recIlvl=0   }
Z[2434] = { name="Dead Scar",        type=Z.TYPE.WORLD,   recMin=233, recIlvl=246 }
Z[2435] = { name="Dawnspire",        type=Z.TYPE.WORLD,   recMin=246, recIlvl=259 }
Z[2436] = { name="Void Quarter",     type=Z.TYPE.WORLD,   recMin=259, recIlvl=272 }
Z[2450] = { name="Magister's Terrace",     type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2451] = { name="Maisara Caverns",        type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2452] = { name="Nexus Point Xenas",      type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2453] = { name="Windrunner Spire",       type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2454] = { name="Algeth'ar Academy",      type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2455] = { name="Pit of Saron",           type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2456] = { name="Seat of the Triumvirate",type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2457] = { name="Skyreach",              type=Z.TYPE.DUNGEON, recMin=220, recIlvl=233 }
Z[2480] = { name="Voidspire (LFR)",   type=Z.TYPE.RAID, recMin=220, recIlvl=233 }
Z[2481] = { name="Voidspire (N)",     type=Z.TYPE.RAID, recMin=233, recIlvl=246 }
Z[2482] = { name="Voidspire (H)",     type=Z.TYPE.RAID, recMin=246, recIlvl=259 }
Z[2483] = { name="Voidspire (M)",     type=Z.TYPE.RAID, recMin=259, recIlvl=272 }
Z[2484] = { name="Dreamrift (LFR)",   type=Z.TYPE.RAID, recMin=220, recIlvl=233 }
Z[2485] = { name="Dreamrift (N)",     type=Z.TYPE.RAID, recMin=233, recIlvl=246 }
Z[2486] = { name="Dreamrift (H)",     type=Z.TYPE.RAID, recMin=246, recIlvl=259 }
Z[2487] = { name="Dreamrift (M)",     type=Z.TYPE.RAID, recMin=259, recIlvl=272 }
Z[2490] = { name="Delves (Tier 1-4)", type=Z.TYPE.DELVE, recMin=210, recIlvl=220 }
Z[2491] = { name="Delves (Tier 5-8)", type=Z.TYPE.DELVE, recMin=233, recIlvl=246 }

-- ── Zone ilvl lookup ──────────────────────────────────────────────────
function Z:GetCurrent()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID and self[mapID] or nil
end

function Z:GetIlvlRequirement()
    local zone = self:GetCurrent()
    if zone then return zone.recMin, zone.recIlvl end
    -- Default by content type
    local ct = self:GetContentType()
    if ct == Z.TYPE.RAID    then return 233, 246 end
    if ct == Z.TYPE.DUNGEON then return 210, 220 end
    if ct == Z.TYPE.DELVE   then return 210, 220 end
    return 0, 220
end

function Z:GetContentTypeName()
    local ct = self:GetContentType()
    local zone = self:GetCurrent()
    if zone then return zone.name end
    local names = {
        [Z.TYPE.WORLD]  = "world content",
        [Z.TYPE.DUNGEON]= "dungeon",
        [Z.TYPE.MYTHIC] = "Mythic+",
        [Z.TYPE.RAID]   = "raid",
        [Z.TYPE.PVP]    = "PvP",
        [Z.TYPE.DELVE]  = "delve",
    }
    return names[ct] or "current content"
end

function Z:IsReady(playerIlvl)
    local min, rec = self:GetIlvlRequirement()
    if playerIlvl >= rec then return "ready", rec end
    if playerIlvl >= min then return "marginal", rec end
    return "not_ready", min
end

-- ── Upgrade sources by content type ──────────────────────────────────
Z.UPGRADE_SOURCES = {
    solo = {
        { name="Delves Tier 1-4",     ilvl="220-237", track="Adventurer", note="Solo or duo — fastest catch-up route" },
        { name="World quests",        ilvl="220-237", track="Adventurer", note="Check for high ilvl item rewards daily" },
        { name="Delves Tier 5-8",     ilvl="233-250", track="Veteran",    note="Harder solo content, Veteran track gear" },
        { name="Bountiful Delve",     ilvl="233-250", track="Veteran",    note="Weekly cache from highest tier delve" },
    },
    lfg = {
        { name="Heroic dungeon",       ilvl="220-237", track="Adventurer", note="Queue via Dungeon Finder" },
        { name="Mythic 0",             ilvl="233-250", track="Veteran",    note="Requires premade group — no timer" },
        { name="LFR (Voidspire)",      ilvl="220-237", track="Adventurer", note="Looking for Raid — no group needed" },
        { name="Normal Raid",          ilvl="246-263", track="Champion",   note="Voidspire or Dreamrift Normal" },
        { name="Mythic+ 2-5",          ilvl="233-250", track="Veteran",    note="End-of-dungeon chest" },
        { name="Mythic+ 6-9",          ilvl="259-276", track="Hero",       note="Weekly vault at +6 gives Hero gear" },
        { name="Heroic Raid",          ilvl="259-276", track="Hero",       note="Voidspire or Dreamrift Heroic" },
        { name="Mythic+ 10+",          ilvl="272-289", track="Myth",       note="Weekly vault at +10 gives Myth gear" },
    },
    pvp = {
        { name="Unranked BG / Skirmish", ilvl="220-237", track="Adventurer", note="Honor currency — starter PvP gear" },
        { name="Rated Arena / RBG",      ilvl="246-263", track="Champion",    note="Conquest gear — requires rating" },
        { name="Weekly PvP cache",       ilvl="259-276", track="Hero",        note="Bonus at end of week for rated play" },
    },
}

-- ── Scaling system detection ───────────────────────────────────────────
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
    local pvpScaledIlvl = avgIlvl
    if C_PvP and C_PvP.IsActiveBattlefield then
        inPvP = C_PvP.IsActiveBattlefield() or false
    end
    if not inPvP and instanceType == "pvp" then inPvP = true end

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
        -- PvP Honor gear scales up — show the PvP context
        -- Actual PvP ilvl shown on item, we approximate
        scalingNote = "PvP: Honor gear scales UP to 276 in arenas/BGs — raw ilvl less important than PvP ilvl"
    elseif isChromieTime or isLeveling then
        scalingNote = "Leveling: world scales to your level — gear ilvl matters less than levels gained"
    elseif not inInstance then
        scalingNote = "Open world: enemies scale softly with your ilvl — you outscale most world content above 233"
    end

    return {
        effectiveIlvl = effectiveIlvl,
        isTW          = isTW,
        inPvP         = inPvP,
        isLeveling    = isLeveling,
        isChromieTime = isChromieTime,
        scalingNote   = scalingNote,
    }
end

-- ── PvP ilvl helper ───────────────────────────────────────────────────
-- PvP gear has two ilvl values — base and PvP-scaled
-- The scaled value is what matters in arenas/BGs
-- We read this from item tooltip data when available
function Z:GetPvPScaledIlvl(itemLink)
    if not itemLink then return nil end
    -- PvP ilvl is in the item tooltip as a bonus stat line
    -- Format: "In PvP combat: Item Level X"
    -- C_Item.GetItemStatDelta or tooltip scanning needed
    -- For now return nil (not easily readable without tooltip scan)
    return nil
end
