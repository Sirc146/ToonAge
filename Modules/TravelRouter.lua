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
    { from = 84,   to = 2215, method = "portal", label = "SW → Emerald Dream" },
    { from = 84,   to = 2248, method = "portal", label = "SW → Khaz Algar" },
    { from = 84,   to = 2339, method = "portal", label = "SW → Hallowfall" },
    { from = 84,   to = 2434, method = "portal", label = "SW → Quel'Thalas (Midnight)" },
    { from = 84,   to = 619,  method = "portal", label = "SW → Jade Forest" },

    -- Orgrimmar portals
    { from = 85,   to = 1978, method = "portal", label = "Org → Dragon Isles" },
    { from = 85,   to = 2112, method = "portal", label = "Org → Valdrakken" },
    { from = 85,   to = 2215, method = "portal", label = "Org → Emerald Dream" },
    { from = 85,   to = 2248, method = "portal", label = "Org → Khaz Algar" },
    { from = 85,   to = 2339, method = "portal", label = "Org → Hallowfall" },
    { from = 85,   to = 2434, method = "portal", label = "Org → Quel'Thalas (Midnight)" },
    { from = 85,   to = 619,  method = "portal", label = "Org → Jade Forest" },

    -- Valdrakken hub portals
    { from = 2112, to = 84,   method = "portal", label = "Valdrakken → Stormwind" },
    { from = 2112, to = 85,   method = "portal", label = "Valdrakken → Orgrimmar" },
    { from = 2112, to = 2248, method = "portal", label = "Valdrakken → Khaz Algar" },
    { from = 2112, to = 2434, method = "portal", label = "Valdrakken → Quel'Thalas" },

    -- Oribos (Shadowlands hub)
    { from = 1670, to = 84,   method = "portal", label = "Oribos → Stormwind" },
    { from = 1670, to = 85,   method = "portal", label = "Oribos → Orgrimmar" },

    -- Midnight zones internal connections
    { from = 2434, to = 2435, method = "portal", label = "Quel'Thalas → Eversong" },
    { from = 2434, to = 2436, method = "portal", label = "Quel'Thalas → Silvermoon" },
    { from = 2434, to = 2437, method = "portal", label = "Quel'Thalas → Naigtal" },
}

-- Class teleports (known by checking IsSpellKnown)
TR.CLASS_TELEPORTS = {
    -- Mage portals to capitals
    { spellID = 3561,   toZone = 84,   class = "MAGE",   label = "Teleport: Stormwind" },
    { spellID = 3567,   toZone = 85,   class = "MAGE",   label = "Teleport: Orgrimmar" },
    { spellID = 395277, toZone = 2112, class = "MAGE",   label = "Teleport: Valdrakken" },
    -- Druid Dreamwalk
    { spellID = 18960,  toZone = 2215, class = "DRUID",  label = "Dreamwalk (Emerald Dream)" },
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
            if IsSpellKnown(ct.spellID) then
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
                if ct.class == playerClass and ct.toZone == hub and IsSpellKnown(ct.spellID) then
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
