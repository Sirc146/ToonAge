-- ToonAge/Modules/TravelRouter.lua
-- Lightweight travel route planner: when the next guide step is in a different
-- zone, suggests the best travel method (flight path, portal, hearthstone,
-- class teleport) rather than just pointing an arrow across the continent.
--
-- Architecture:
--   • Discovers known flight paths from C_TaxiMap at login
--   • Maintains a static portal/transport database (Data/Zones.lua can extend)
--   • When QuestTracker detects a cross-zone step, queries for best route
--   • Injects a "travel suggestion" into the tracker status line
--   • Max 3-4 hops, no pre-cached mega-graph (keeps it lightweight)
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local TR = {}
TA:RegisterModule("TravelRouter", TR)

-- ── Transport database ────────────────────────────────────────────────────────
-- Static knowledge of inter-zone transport. Expandable via Data/Zones.lua.
-- Format: { fromZone, toZone, method, label, cost? }

TR.PORTALS = {
    -- ── Major city portals (Retail) ───────────────────────────────────
    -- Stormwind portals
    { from = 84,   to = 1978, method = "portal", label = "SW → Dragon Isles" },
    { from = 84,   to = 2112, method = "portal", label = "SW → Valdrakken" },
    { from = 84,   to = 2339, method = "portal", label = "SW → Dornogal (Khaz Algar)" },
    { from = 84,   to = 2537, method = "portal", label = "SW → Quel'Thalas (Midnight)" },
    -- Removed 2026-07-25: a "SW → Hallowfall" entry pointing at 2339, which is
    -- Dornogal — it duplicated the Khaz Algar portal above under a wrong name.
    -- Also removed "SW → Emerald Dream" pointing at 2215, which is Hallowfall.
    -- Re-add the Emerald Dream portal once its real map ID is confirmed in-game.
    { from = 84,   to = 619,  method = "portal", label = "SW → Jade Forest" },

    -- Orgrimmar portals
    { from = 85,   to = 1978, method = "portal", label = "Org → Dragon Isles" },
    { from = 85,   to = 2112, method = "portal", label = "Org → Valdrakken" },
    { from = 85,   to = 2339, method = "portal", label = "Org → Dornogal (Khaz Algar)" },
    { from = 85,   to = 2537, method = "portal", label = "Org → Quel'Thalas (Midnight)" },
    -- Same two removals as the Stormwind block above.
    { from = 85,   to = 619,  method = "portal", label = "Org → Jade Forest" },

    -- Valdrakken hub portals
    { from = 2112, to = 84,   method = "portal", label = "Valdrakken → Stormwind" },
    { from = 2112, to = 85,   method = "portal", label = "Valdrakken → Orgrimmar" },
    { from = 2112, to = 2339, method = "portal", label = "Valdrakken → Dornogal (Khaz Algar)" },
    { from = 2112, to = 2537, method = "portal", label = "Valdrakken → Quel'Thalas" },

    -- Oribos (Shadowlands hub)
    { from = 1670, to = 84,   method = "portal", label = "Oribos → Stormwind" },
    { from = 1670, to = 85,   method = "portal", label = "Oribos → Orgrimmar" },

    -- Midnight zones internal connections.
    -- Corrected 2026-07-25. Previous values were 2435/2436/2437 off a 2434 hub —
    -- every one of them wrong. 2437 is Zul'Aman; 2435/2436 aren't Midnight maps;
    -- and 2434 is Dead Scar, a sub-area of Eversong (see Data/Zones.lua:158),
    -- not the Quel'Thalas hub it was being used as.
    { from = 2537, to = 2395, method = "portal", label = "Quel'Thalas → Eversong Woods" },
    { from = 2537, to = 2393, method = "portal", label = "Quel'Thalas → Silvermoon City" },
    { from = 2537, to = 2600, method = "portal", label = "Quel'Thalas → Naigtal" },
}

-- MAP ID VERIFICATION STATUS
--
-- All of the following were confirmed in-game via /coord on the Midnight PTR,
-- 2026-07-25. Treat this block as the reference when adding routes — every ID
-- here has been stood on, which is a stronger guarantee than any addon's data
-- files provide.
--
--   Midnight    2537 Quel'Thalas    2395 Eversong Woods   2393 Silvermoon City
--               2405 Voidstorm      2413 Harandar         2576 The Den
--               2541 Arcantina      2600 Naigtal*
--   Khaz Algar  2274 Khaz Algar     2248 Isle of Dorn     2339 Dornogal
--               2215 Hallowfall
--   Hubs        84  Stormwind        85  Orgrimmar*       87  Ironforge
--               103 The Exodar      111  Shattrath City   125 Dalaran (Northrend)
--               627 Dalaran (Broken Isles)              734 Hall of the Guardian
--               622 Stormshield     390  Vale of Eternal Blossoms
--               1161 Boralus        1670 Oribos          2112 Valdrakken
--   Zones       62  Darkshore        70  Dustwallow Marsh  81 Silithus
--               245 Tol Barad Pen.  1355 Nazjatar
--   Continents  12 Kalimdor  13 Eastern Kingdoms  101 Outland  113 Northrend
--               424 Pandaria  572 Draenor  619 Broken Isles  876 Kul Tiras
--               1550 The Shadowlands  1978 Dragon Isles  947 Azeroth
--
--   * 85 Orgrimmar is the one hub ID not personally verified — Alliance
--     character. It is long-standing and low risk.
--
-- Two Dalarans: 125 (Northrend, under Crystalsong 127) and 627 (Broken Isles).
-- Distinct maps, distinct teleports — do not conflate them.
--
-- Confirmed map trees:
--
--   Quel'Thalas 2537  (> Eastern Kingdoms 13 > Azeroth 947 > Cosmic 946)
--     ├── Eversong Woods 2395
--     │     └── Silvermoon City 2393        ← city nests inside its zone
--     ├── Harandar 2413
--     │     └── The Den 2576
--     ├── Voidstorm 2405
--     ├── Arcantina 2541
--     └── Naigtal 2600*
--
--   Khaz Algar 2274  (> Azeroth 947)
--     ├── Isle of Dorn 2248
--     │     └── Dornogal 2339
--     └── Hallowfall 2215
--
-- Both regions share one shape: settlements nest inside their zone, zones are
-- siblings under the region. Assume that for any zone not yet walked
-- (Zul'Aman 2437, Val 2599, Broken Throne 2585, Daggerspine Point 2594) rather
-- than assuming a flat list — the nesting is what makes specificity ranking
-- necessary in MapZoneDistance.
--
-- * Naigtal 2600 has not been walked personally, but is confirmed twice over:
--   HandyNotes_Midnight/zones/naigtal.lua binds it as the primary map, and
--   HandyNotes_NaigtalTeleports/Core.lua:11 carries the note "Confirmed in-game
--   via: /dump C_Map.GetBestMapForUnit". HandyNotes_Midnight has since matched
--   6 of 6 IDs verified independently here, so treat 2600 as reliable.
--
-- Hallowfall and Isle of Dorn are siblings, not parent/child. That is why
-- TAG_Hallowfall.lua's old `zone = 2248` was worse than a stub: standing in
-- Hallowfall, 2248 is not an ancestor, so the zone match failed outright and
-- the guide could only ever be reached by the level-only fallback.
--
-- Note Silvermoon nests *inside* Eversong rather than beside it. Guide zone
-- matching therefore has to rank by specificity, not just take the first hit —
-- see MapZoneDistance in QuestTracker.lua.
--
-- ⚠ STILL UNVERIFIED:
--   2600  Naigtal — inferred from a map binding, not yet walked.
--   Emerald Dream portals — removed rather than left pointing at 2215
--     (Hallowfall). Re-add once the real destination ID is confirmed.
--
-- A wrong ID here routes the player to the wrong zone silently, which is worse
-- than having no route at all. Take the portal and run /coord on arrival.

-- Class teleports (gated by U.IsSpellKnown at query time).
--
-- Destination map IDs below were confirmed in-game 2026-07-25 by taking each
-- teleport and running /coord on arrival. The spellIDs are long-standing values
-- but have NOT been read from a live spellbook — run /tateleports on each class
-- to confirm them.
--
-- Failure modes differ, which is why it was worth shipping these unverified:
-- a wrong spellID makes IsSpellKnown fail and the route silently not appear
-- (benign, just a missing suggestion), whereas a wrong destination map ID would
-- route the player to the wrong place (harmful). The harmful half is verified.
TR.CLASS_TELEPORTS = {
    -- ── Mage, Alliance ────────────────────────────────────────────────
    { spellID = 3561,   toZone = 84,   class = "MAGE",   label = "Teleport: Stormwind" },
    { spellID = 3562,   toZone = 87,   class = "MAGE",   label = "Teleport: Ironforge" },
    { spellID = 3565,   toZone = 62,   class = "MAGE",   label = "Teleport: Darnassus (Rut'theran, Darkshore)" },
    { spellID = 32271,  toZone = 103,  class = "MAGE",   label = "Teleport: Exodar" },
    { spellID = 49359,  toZone = 70,   class = "MAGE",   label = "Teleport: Theramore (Dustwallow Marsh)" },
    { spellID = 88342,  toZone = 245,  class = "MAGE",   label = "Teleport: Tol Barad" },
    { spellID = 176248, toZone = 622,  class = "MAGE",   label = "Teleport: Stormshield (Ashran)" },

    -- ── Mage, Horde ───────────────────────────────────────────────────
    -- Destinations NOT yet confirmed — no Horde mage has walked these. The
    -- Alliance block above is the model: verify with /coord on arrival.
    { spellID = 3567,   toZone = 85,   class = "MAGE",   label = "Teleport: Orgrimmar" },

    -- ── Mage, neutral hubs ────────────────────────────────────────────
    -- Note the two distinct Dalarans: 125 is the Northrend city (parented to
    -- Crystalsong Forest), 627 is the Broken Isles one. They are separate maps
    -- and separate spells; conflating them sends the player to the wrong
    -- expansion's hub.
    { spellID = 33690,  toZone = 111,  class = "MAGE",   label = "Teleport: Shattrath" },
    { spellID = 53140,  toZone = 125,  class = "MAGE",   label = "Teleport: Dalaran - Northrend" },
    { spellID = 224869, toZone = 627,  class = "MAGE",   label = "Teleport: Dalaran - Broken Isles" },
    { spellID = 193759, toZone = 734,  class = "MAGE",   label = "Teleport: Hall of the Guardian" },
    { spellID = 132621, toZone = 390,  class = "MAGE",   label = "Teleport: Vale of Eternal Blossoms" },
    { spellID = 281403, toZone = 1161, class = "MAGE",   label = "Teleport: Boralus" },
    { spellID = 344587, toZone = 1670, class = "MAGE",   label = "Teleport: Oribos" },
    { spellID = 395277, toZone = 2112, class = "MAGE",   label = "Teleport: Valdrakken" },
    { spellID = 446540, toZone = 2339, class = "MAGE",   label = "Teleport: Dornogal" },

    -- Druid Dreamwalk. toZone was 2215 (Hallowfall) — wrong, that is not the
    -- Emerald Dream. Left unset rather than guessed; Dreamwalk still shows as a
    -- travel option, it just won't be matched to a specific destination zone.
    { spellID = 18960,  toZone = nil,  class = "DRUID",  label = "Dreamwalk (Emerald Dream)" },
    -- DK Death Gate
    { spellID = 50977,  toZone = 23,   class = "DEATHKNIGHT", label = "Death Gate (Acherus)" },
    -- Monk Zen Pilgrimage
    { spellID = 126892, toZone = 809,  class = "MONK",   label = "Zen Pilgrimage" },
    -- Shaman Astral Recall (hearth alternative)
    { spellID = 556,    toZone = nil,  class = "SHAMAN", label = "Astral Recall" },
}

-- ── State ─────────────────────────────────────────────────────────────────────
TR.knownFlightPaths = {}  -- [taxiNodeID] = { name, mapID }
TR.lastSuggestion   = nil
TR.lastTargetZone   = nil

-- ── Flight path discovery ─────────────────────────────────────────────────────

function TR:DiscoverFlightPaths()
    -- This can only run when the taxi map is open, or we can use
    -- C_TaxiMap.GetAllTaxiNodes() if available
    if not C_TaxiMap or not C_TaxiMap.GetAllTaxiNodes then return end

    local nodes = C_TaxiMap.GetAllTaxiNodes(C_Map.GetBestMapForUnit("player") or 0)
    if not nodes then return end

    for _, node in ipairs(nodes) do
        if node.state == Enum.FlightPathState.Current or
           node.state == Enum.FlightPathState.Reachable then
            self.knownFlightPaths[node.nodeID] = {
                name  = node.name,
                mapID = node.mapID or 0,
                x     = node.position and node.position.x or 0,
                y     = node.position and node.position.y or 0,
            }
        end
    end
end

-- ── Zone utility ──────────────────────────────────────────────────────────────

local function GetContinent(mapID)
    if not mapID or mapID == 0 then return 0 end
    local info = C_Map.GetMapInfo(mapID)
    while info do
        if info.mapType == Enum.UIMapType.Continent then
            return info.mapID
        end
        if info.parentMapID and info.parentMapID > 0 then
            info = C_Map.GetMapInfo(info.parentMapID)
        else
            break
        end
    end
    return 0
end

local function IsSameContinent(mapA, mapB)
    if mapA == mapB then return true end
    return GetContinent(mapA) == GetContinent(mapB) and GetContinent(mapA) ~= 0
end

-- ── Route finding ─────────────────────────────────────────────────────────────

--- Find the best travel suggestion from current zone to target zone.
--- Returns a table: { method, label, hops } or nil if no suggestion.
function TR:FindRoute(fromZone, toZone)
    if not fromZone or not toZone or fromZone == toZone then return nil end
    if fromZone == 0 or toZone == 0 then return nil end

    local _, playerClass = UnitClass("player")
    local playerFaction = UnitFactionGroup("player")

    -- ── Direct portal check (1 hop) ──────────────────────────────────
    for _, p in ipairs(self.PORTALS) do
        if p.from == fromZone and p.to == toZone then
            return { method = p.method, label = p.label, hops = 1 }
        end
    end

    -- ── Class teleport check (1 hop) ─────────────────────────────────
    for _, ct in ipairs(self.CLASS_TELEPORTS) do
        if ct.class == playerClass and ct.toZone == toZone then
            if U.IsSpellKnown(ct.spellID) then
                return { method = "class", label = ct.label, hops = 1 }
            end
        end
    end

    -- ── Hearthstone check (1 hop if hearth is in target zone) ─────────
    local hearthMapID = self:GetHearthZone()
    if hearthMapID and hearthMapID == toZone then
        local cdInfo = C_Spell.GetSpellCooldown(8690)  -- Hearthstone
        local ready = not cdInfo or cdInfo.duration == 0 or
                      ((cdInfo.startTime + cdInfo.duration) - GetTime()) <= 0
        if ready then
            return { method = "hearth", label = "Hearthstone (ready!)", hops = 1 }
        else
            local remaining = (cdInfo.startTime + cdInfo.duration) - GetTime()
            return { method = "hearth", label = string.format("Hearth (%d:%02d cd)", math.floor(remaining/60), remaining%60), hops = 1 }
        end
    end

    -- ── 2-hop: portal to hub → flight/portal to target ───────────────
    -- Check if a major hub has a portal to the target
    local HUBS = { 84, 85, 2112, 1670 }  -- SW, Org, Valdrakken, Oribos
    for _, hub in ipairs(HUBS) do
        -- Can we reach the hub from here?
        local toHub = nil
        for _, p in ipairs(self.PORTALS) do
            if p.from == fromZone and p.to == hub then
                toHub = p
                break
            end
        end
        -- Check class teleport to hub
        if not toHub then
            for _, ct in ipairs(self.CLASS_TELEPORTS) do
                if ct.class == playerClass and ct.toZone == hub and U.IsSpellKnown(ct.spellID) then
                    toHub = { method = "class", label = ct.label }
                    break
                end
            end
        end
        if toHub then
            -- Does the hub have a portal to the target?
            for _, p in ipairs(self.PORTALS) do
                if p.from == hub and p.to == toZone then
                    return {
                        method = "multi",
                        label  = toHub.label .. " → " .. p.label,
                        hops   = 2,
                    }
                end
            end
        end
    end

    -- ── Same continent: suggest flight path ──────────────────────────
    if IsSameContinent(fromZone, toZone) then
        return { method = "fly", label = "Fly (same continent)", hops = 1 }
    end

    -- ── Hearth to hub → portal (2-hop) ───────────────────────────────
    if hearthMapID then
        for _, p in ipairs(self.PORTALS) do
            if p.from == hearthMapID and p.to == toZone then
                return {
                    method = "multi",
                    label  = "Hearth → " .. p.label,
                    hops   = 2,
                }
            end
        end
    end

    -- ── No route found ───────────────────────────────────────────────
    return nil
end

-- ── Hearthstone location ──────────────────────────────────────────────────────

function TR:GetHearthZone()
    -- GetBindLocation returns the zone name, not mapID.
    -- We can't reliably convert name→mapID without a lookup table.
    -- Store the mapID when the player sets their hearth (HEARTHSTONE_BOUND event).
    return TA.charDB and TA.charDB.hearthZoneID
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Get a travel suggestion for the current guide step.
--- Called by QuestTracker when rendering status line.
--- @return string|nil — formatted suggestion text, or nil if not needed
function TR:GetSuggestionForCurrentStep()
    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return nil end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return nil end

    local step = guide.steps[QT.stepIdx]
    if not step or not step.coord then return nil end

    local targetMap = step.coord.map
    if not targetMap or targetMap == 0 then return nil end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then return nil end

    -- Same zone: no travel suggestion needed
    if currentMap == targetMap then
        self.lastSuggestion = nil
        return nil
    end

    -- Check parent-zone containment (sub-zones don't need travel)
    local info = C_Map.GetMapInfo(currentMap)
    while info and info.parentMapID and info.parentMapID > 0 do
        if info.parentMapID == targetMap then
            self.lastSuggestion = nil
            return nil
        end
        info = C_Map.GetMapInfo(info.parentMapID)
    end

    -- Cache: don't re-calculate if target zone hasn't changed
    if self.lastTargetZone == targetMap and self.lastSuggestion then
        return self.lastSuggestion
    end

    local route = self:FindRoute(currentMap, targetMap)
    self.lastTargetZone = targetMap

    if route then
        self.lastSuggestion = "|cFF55CCFF[Travel]|r " .. route.label
    else
        self.lastSuggestion = "|cFF55CCFF[Travel]|r Different zone — check map for routes"
    end

    return self.lastSuggestion
end

-- ── Event handling ────────────────────────────────────────────────────────────

function TR:OnEvent(event, ...)
    if event == "HEARTHSTONE_BOUND" then
        -- Record current zone as hearth location
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID and TA.charDB then
            TA.charDB.hearthZoneID = mapID
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        -- Invalidate cached suggestion when zone changes
        self.lastSuggestion = nil
        self.lastTargetZone = nil
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function TR:Init()
    TA.eventFrame:RegisterEvent("HEARTHSTONE_BOUND")

    -- Try to discover flight paths (works best after taxi map has been opened)
    C_Timer.After(5, function()
        TR:DiscoverFlightPaths()
    end)

    -- Record current hearth zone if not yet saved
    if TA.charDB and not TA.charDB.hearthZoneID then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then TA.charDB.hearthZoneID = mapID end
    end
end

TR.SlashCommands = {}
