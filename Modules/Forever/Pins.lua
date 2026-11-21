-- ToonAge/Modules/Forever/Pins.lua
--
-- Suggestions, not instructions. Two buttons on the Character tab ask for a
-- pin. The arrow still works when the unverified waypoint calls are absent.
--
-- Library coordinates and both librarian ids are the points Icy Veins lists:
--   Owen Thadd 211022, Undercity 73.7, 33.1
--     https://db.icy-veins.com/wow-forever/npcs/211022
--   Garion Wendell 211033, Stormwind City 49.0, 86.5
--     https://db.icy-veins.com/wow-forever/npcs/211033
--   Quest Research Access 97286 names both points
--     https://db.icy-veins.com/wow-forever/quests/97286
-- City uiMapIDs are not stored. Arrow.MapIDForZone asks the client at pin
-- time. Until that answers, the id is unverified and no pin is placed.
--
-- Each auction house uses one coordinate that Icy Veins lists on that
-- auctioneer's Forever page. Pages list several pins. This file does not
-- average them. A city with no such page is omitted.
--   Orgrimmar, Auctioneer Wabang 8724, 55.5, 63.1
--     https://db.icy-veins.com/wow-forever/npcs/8724
--   Undercity, Auctioneer Epitwee 8721, 63.2, 51.3
--     https://db.icy-veins.com/wow-forever/npcs/8721
--   Thunder Bluff, Auctioneer Stampi 8674, 39.3, 51.5
--     https://db.icy-veins.com/wow-forever/npcs/8674
--   Stormwind City, Auctioneer Chilton 8670, 61.3, 70.0
--     https://db.icy-veins.com/wow-forever/npcs/8670
--   Ironforge, Auctioneer Lympkin 9859, 25.7, 74.0
--     https://db.icy-veins.com/wow-forever/npcs/9859
--   Darnassus, Auctioneer Cazarez 15679, 55.6, 52.7
--     https://db.icy-veins.com/wow-forever/npcs/15679
--
-- Light Feather is item 17056.
--   https://db.icy-veins.com/wow-forever/items/17056
-- The button suggests an auction house when the bag holds fewer than one.
-- A count that cannot be read is not treated as zero.
--
-- The beam and the flag are original textures generated for this marker:
--   Media/frame/beam_gold.tga
--   Media/frame/flag_gold.tga
-- The ring is the existing Media/frame/ring_32.tga, tinted gold here.

local TA = ToonAge
local U  = TA.Utils

local M = {}
TA:RegisterModule("ForeverPins", M)

local BEAM_TEX = "Interface\\AddOns\\ToonAge\\Media\\frame\\beam_gold.tga"
local FLAG_TEX = "Interface\\AddOns\\ToonAge\\Media\\frame\\flag_gold.tga"

M.LIGHT_FEATHER = 17056
M.FEATHER_TARGET = 1

M.LIBRARIES = {
    Horde = {
        name = "Owen Thadd",
        npcID = 211022,
        zone = "Undercity",
        x = 73.7, y = 33.1,
        questID = 97286,
        source = "https://db.icy-veins.com/wow-forever/npcs/211022",
        questSource = "https://db.icy-veins.com/wow-forever/quests/97286",
    },
    Alliance = {
        name = "Garion Wendell",
        npcID = 211033,
        zone = "Stormwind City",
        x = 49.0, y = 86.5,
        questID = 97286,
        source = "https://db.icy-veins.com/wow-forever/npcs/211033",
        questSource = "https://db.icy-veins.com/wow-forever/quests/97286",
    },
}

M.AUCTION = {
    Horde = {
        {
            npc = "Auctioneer Wabang", npcID = 8724,
            zone = "Orgrimmar", city = "Orgrimmar",
            x = 55.5, y = 63.1,
            source = "https://db.icy-veins.com/wow-forever/npcs/8724",
        },
        {
            npc = "Auctioneer Epitwee", npcID = 8721,
            zone = "Undercity", city = "Undercity",
            x = 63.2, y = 51.3,
            source = "https://db.icy-veins.com/wow-forever/npcs/8721",
        },
        {
            npc = "Auctioneer Stampi", npcID = 8674,
            zone = "Thunder Bluff", city = "Thunder Bluff",
            x = 39.3, y = 51.5,
            source = "https://db.icy-veins.com/wow-forever/npcs/8674",
        },
    },
    Alliance = {
        {
            npc = "Auctioneer Chilton", npcID = 8670,
            zone = "Stormwind City", city = "Stormwind City",
            x = 61.3, y = 70.0,
            source = "https://db.icy-veins.com/wow-forever/npcs/8670",
        },
        {
            npc = "Auctioneer Lympkin", npcID = 9859,
            zone = "Ironforge", city = "Ironforge",
            x = 25.7, y = 74.0,
            source = "https://db.icy-veins.com/wow-forever/npcs/9859",
        },
        {
            npc = "Auctioneer Cazarez", npcID = 15679,
            zone = "Darnassus", city = "Darnassus",
            x = 55.6, y = 52.7,
            source = "https://db.icy-veins.com/wow-forever/npcs/15679",
        },
    },
}

--- True when the bag is empty or short of the target. A non-number is not short.
function M.NeedsFeathers(count, target)
    if type(count) ~= "number" or count ~= count then return false end
    if type(target) ~= "number" then target = 0 end
    return count <= 0 or count < target
end

--- "717 yd" or "717 yd · about 2 min". ETA only when speed toward the pin
--- is a positive number. An unknown speed omits the ETA.
function M.BeamCaption(yards, speed)
    if type(yards) ~= "number" or yards ~= yards or yards < 0 then return "" end
    local yd = string.format("%d yd", math.floor(yards + 0.5))
    if type(speed) ~= "number" or speed ~= speed or speed <= 0.5 then return yd end
    local eta = yards / speed
    if eta ~= eta or eta < 0 or eta >= 3600 then return yd end
    if eta < 45 then
        local secs = math.max(1, math.floor(eta + 0.5))
        return yd .. " · about " .. secs .. " sec"
    end
    local mins = math.max(1, math.floor(eta / 60 + 0.5))
    return yd .. " · about " .. mins .. " min"
end

--- A single library record, or a list of them. One record stays one record.
function M.AsLibraryList(entry)
    if type(entry) ~= "table" then return nil end
    if type(entry[1]) == "table" then return entry end
    return { entry }
end

--- The library on the player's continent. One entry is returned as-is.
--- Several on that continent: the nearest world point. None on it: nil.
function M.ChooseLibrary(list, playerCont, contOf, origin, worldOf)
    if type(list) ~= "table" or #list == 0 then return nil end
    if #list == 1 then return list[1] end
    local on = {}
    for _, place in ipairs(list) do
        local cont = type(contOf) == "function" and contOf(place) or nil
        if playerCont ~= nil and cont == playerCont then
            on[#on + 1] = place
        end
    end
    if #on == 0 then return nil end
    if #on == 1 then return on[1] end
    if type(worldOf) ~= "function" then return nil end
    local points = {}
    for i, place in ipairs(on) do
        points[i] = worldOf(place) or {}
    end
    local idx = M.NearestIndex(origin, points)
    if not idx then return nil end
    return on[idx]
end

--- Index of the closest point that has north and west. Nil when origin or
--- every point is missing those numbers.
function M.NearestIndex(origin, points)
    if type(origin) ~= "table" or type(origin.north) ~= "number" or type(origin.west) ~= "number" then
        return nil
    end
    if type(points) ~= "table" then return nil end
    local best, bestD
    for i, p in ipairs(points) do
        if type(p) == "table" and type(p.north) == "number" and type(p.west) == "number" then
            if origin.cont == nil or p.cont == nil or origin.cont == p.cont then
                local dN = p.north - origin.north
                local dW = p.west - origin.west
                local d = dN * dN + dW * dW
                if not bestD or d < bestD then
                    best, bestD = i, d
                end
            end
        end
    end
    return best
end

function M:Say(text)
    if TA.Print and TA.LOG then
        TA:Print(TA.LOG.OUTPUT, "Pins", text)
    end
end

local function WorldPoint(mapID, xPct, yPct)
    local C = TA.Compat
    if not (C and type(C.WorldPosFromMapPos) == "function") then return nil end
    if type(mapID) ~= "number" then return nil end
    local cont, north, west = C.WorldPosFromMapPos(mapID, xPct / 100, yPct / 100)
    if type(north) ~= "number" or type(west) ~= "number" then return nil end
    return { cont = cont, north = north, west = west }
end

local function PlayerHere()
    local C = TA.Compat
    if not (C and type(C.BestMapForUnit) == "function") then return nil end
    local mapID = C.BestMapForUnit("player")
    if type(mapID) ~= "number" then return nil end
    local Arrow = TA:GetModule("Arrow")
    local name = Arrow and Arrow.MapName and Arrow.MapName(mapID) or nil
    local x, y
    if type(C.PlayerMapFraction) == "function" then
        x, y = C.PlayerMapFraction(mapID)
    end
    local origin
    if type(x) == "number" and type(y) == "number" and type(C.WorldPosFromMapPos) == "function" then
        local cont, north, west = C.WorldPosFromMapPos(mapID, x, y)
        if type(north) == "number" and type(west) == "number" then
            origin = { cont = cont, north = north, west = west }
        end
    end
    if not origin and type(C.PlayerWorldPosition) == "function" then
        local cont, north, west = C.PlayerWorldPosition()
        if type(north) == "number" and type(west) == "number" then
            origin = { cont = cont, north = north, west = west }
        end
    end
    return mapID, name, origin
end

function M:TryTomTom(mapID, xPct, yPct, title)
    local Arrow = TA:GetModule("Arrow")
    if not (Arrow and type(Arrow.TomTomLoaded) == "function" and Arrow.TomTomLoaded()) then
        return false
    end
    if type(TomTom) ~= "table" or type(TomTom.AddWaypoint) ~= "function" then
        return false
    end
    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, mapID, xPct, yPct, { title = title })
    if ok then
        local A = TA:GetModule("Arrow")
        if A then A._tomtomUid = uid end
    end
    return ok and true or false
end

--- Auto-learned Study library locations saved in TA.db.studyLibraries[faction].
--- Recorded dynamically when the player successfully casts Study in-game so
--- every confirmed spot on either continent joins nearest-library routing.
function M.LearnedLibraries(faction)
    if type(faction) ~= "string" or faction == "" then return {} end
    local store = TA.db and TA.db.studyLibraries
    local list = type(store) == "table" and store[faction] or nil
    if type(list) ~= "table" then return {} end
    return list
end

--- Record a verified Study spot measured live from the player's position.
--- Deduplicates spots within 3 map units in the same zone.
function M.RecordStudySpot(faction, zone, mapID, xPct, yPct, subzone)
    if type(faction) ~= "string" or faction == "" then return false end
    if type(zone) ~= "string" or zone == "" then return false end
    if type(xPct) ~= "number" or type(yPct) ~= "number" then return false end
    if not TA.db then return false end
    TA.db.studyLibraries = TA.db.studyLibraries or {}
    TA.db.studyLibraries[faction] = TA.db.studyLibraries[faction] or {}
    local list = TA.db.studyLibraries[faction]
    for _, existing in ipairs(list) do
        if existing.zone == zone and type(existing.x) == "number" and type(existing.y) == "number" then
            local dx = existing.x - xPct
            local dy = existing.y - yPct
            if (dx * dx + dy * dy) <= 9 then
                return false
            end
        end
    end
    local label = (type(subzone) == "string" and subzone ~= "") and ("Study: " .. subzone) or ("Study: " .. zone)
    local entry = {}
    entry.name = label
    entry.zone = zone
    entry.mapID = type(mapID) == "number" and mapID or nil
    entry.x = math.floor(xPct * 10 + 0.5) / 10
    entry.y = math.floor(yPct * 10 + 0.5) / 10
    entry.learned = true
    list[#list + 1] = entry
    return true
end

--- Combined library list for a faction: built-in librarian(s) plus any
--- live-confirmed Study locations learned by this account.
function M.AllLibraries(faction)
    local out = {}
    local base = M.AsLibraryList(faction and M.LIBRARIES[faction])
    if base then
        for _, item in ipairs(base) do out[#out + 1] = item end
    end
    for _, item in ipairs(M.LearnedLibraries(faction)) do
        out[#out + 1] = item
    end
    return #out > 0 and out or nil
end

--- True when the active manual waypoint matches the given pin kind ("library" or "feathers").
function M:IsPinned(kind)
    local Arrow = TA:GetModule("Arrow")
    local wp = Arrow and Arrow.manualWaypoint
    if type(wp) ~= "table" then return false end
    if kind == "library" then return wp._pinKind == "library" or wp.quest == true end
    if kind == "feathers" then return wp._pinKind == "feathers" end
    return true
end

--- Clear the active manual waypoint / beam immediately.
function M:ClearPin()
    local Arrow = TA:GetModule("Arrow")
    if Arrow and type(Arrow.ClearActiveWaypoint) == "function" then
        Arrow:ClearActiveWaypoint("button")
        return true
    end
    return false
end

function M:Pin(place, quest, pinKind)
    local Arrow = TA:GetModule("Arrow")
    if not (Arrow and type(Arrow.SetWaypoint) == "function" and type(Arrow.MapIDForZone) == "function") then
        self:Say("Suggestion withheld: the arrow is not running.")
        return false
    end
    local mapID = (type(place.mapID) == "number" and place.mapID) or Arrow.MapIDForZone(place.zone)
    if type(mapID) ~= "number" then
        self:Say(string.format(
            "Suggestion: %s in %s at %.1f, %.1f. This client did not name that map, so no pin was placed.",
            place.name or place.npc or place.city or "That stop",
            place.zone or "that city", place.x or 0, place.y or 0))
        return false
    end
    local title = place.name or place.npc or place.city or "Pin"
    Arrow:SetWaypoint(mapID, place.x / 100, place.y / 100, title)
    if type(Arrow.manualWaypoint) == "table" then
        Arrow.manualWaypoint.quest = quest and true or false
        Arrow.manualWaypoint.questID = place.questID
        Arrow.manualWaypoint.zone = place.zone
        Arrow.manualWaypoint._pinKind = pinKind or (quest and "library" or "feathers")
    end
    local C = TA.Compat
    if C and type(C.TryUserWaypoint) == "function" then
        if C.TryUserWaypoint(mapID, place.x / 100, place.y / 100) then
            Arrow._userWaypointSet = true
        end
    end
    self:TryTomTom(mapID, place.x / 100, place.y / 100, title)
    local MP = TA:GetModule("MapPins")
    if MP and type(MP.Refresh) == "function" then MP:Refresh() end
    local note = quest and "Library. Optional." or "Auction house. Optional."
    self:Say(string.format("Suggestion: %s, %s (%.1f, %.1f). %s",
        title, place.zone, place.x, place.y, note))
    return true
end

function M:SuggestLibrary()
    local C = TA.Compat
    local faction = C and type(C.PlayerFaction) == "function" and C.PlayerFaction() or nil
    local list = M.AllLibraries(faction)
    if not list then
        self:Say("Suggestion withheld: the faction could not be read, so no library was chosen.")
        return false
    end
    local Arrow = TA:GetModule("Arrow")
    local mapID, _, origin = PlayerHere()
    local infoFn = C and C.MapInfo
    local playerCont = Arrow and Arrow.WalkContinent and select(1, Arrow.WalkContinent(mapID, infoFn)) or nil
    local function contOf(place)
        if not (Arrow and type(Arrow.WalkContinent) == "function") then return nil end
        local id = (type(place.mapID) == "number" and place.mapID)
            or (type(Arrow.MapIDForZone) == "function" and Arrow.MapIDForZone(place.zone))
        return select(1, Arrow.WalkContinent(id, infoFn))
    end
    local function worldOf(place)
        local id = (type(place.mapID) == "number" and place.mapID)
            or (Arrow and type(Arrow.MapIDForZone) == "function" and Arrow.MapIDForZone(place.zone))
        if type(id) ~= "number" then return nil end
        return WorldPoint(id, place.x, place.y)
    end
    local place = M.ChooseLibrary(list, playerCont, contOf, origin, worldOf)
    if not place then
        -- Fallback to the faction's primary capital librarian so players on
        -- another continent still get a route (e.g. zeppelin/boat).
        local fallback = M.AsLibraryList(faction and M.LIBRARIES[faction])
        place = fallback and fallback[1] or nil
    end
    if not place then
        self:Say("Suggestion withheld: no library on this continent could be measured.")
        return false
    end
    return self:Pin(place, true, "library")
end

function M:ToggleLibraryPin()
    if self:IsPinned("library") then
        self:ClearPin()
        return false
    end
    return self:SuggestLibrary()
end

function M:ToggleFeathersPin()
    if self:IsPinned("feathers") then
        self:ClearPin()
        return false
    end
    return self:SuggestFeathers()
end

function M:NearestAuction()
    local C = TA.Compat
    local faction = C and type(C.PlayerFaction) == "function" and C.PlayerFaction() or nil
    local list = faction and M.AUCTION[faction]
    if not list then
        return nil, "Suggestion withheld: the faction could not be read, so no auction house was chosen."
    end
    local Arrow = TA:GetModule("Arrow")
    if not (Arrow and type(Arrow.MapIDForZone) == "function") then
        return nil, "Suggestion withheld: the arrow is not running."
    end
    local _, mapName, origin = PlayerHere()
    local points, places, here = {}, {}, nil
    for _, place in ipairs(list) do
        if mapName and place.zone == mapName then here = place end
        local id = Arrow.MapIDForZone(place.zone)
        local world = id and WorldPoint(id, place.x, place.y) or nil
        points[#points + 1] = world or {}
        places[#places + 1] = place
    end
    local idx = origin and M.NearestIndex(origin, points) or nil
    if idx and places[idx] then return places[idx] end
    if here then return here end
    return nil, "Suggestion withheld: distance to a sourced auction house could not be measured, so none was pinned."
end

function M:SuggestFeathers()
    local C = TA.Compat
    if not (C and type(C.CountItem) == "function") then
        self:Say("Suggestion withheld: the bag count for Light Feather could not be read.")
        return false
    end
    local count = C.CountItem(M.LIGHT_FEATHER)
    if type(count) ~= "number" then
        self:Say("Suggestion withheld: the bag count for Light Feather could not be read.")
        return false
    end
    if not M.NeedsFeathers(count, M.FEATHER_TARGET) then
        self:Say(string.format("Suggestion: you have %d Light Feather%s. No auction house pin.",
            count, count == 1 and "" or "s"))
        return false
    end
    local place, why = self:NearestAuction()
    if not place then
        self:Say(why or "Suggestion withheld: no sourced auction house could be measured from here.")
        return false
    end
    return self:Pin(place, false, "feathers")
end

-- Auto-learn any location where the player successfully casts Study (Mage
-- Comprehension) so future "Pin nearest library" clicks find it automatically.
function M:OnEvent(event, unit, _, spellID)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" then return end
    if type(spellID) ~= "number" then return end
    local spName
    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local ok, nm = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(nm) == "string" then spName = nm end
    end
    if spName ~= "Study" then return end
    local C = TA.Compat
    local faction = C and type(C.PlayerFaction) == "function" and C.PlayerFaction() or nil
    local mapID, zone = PlayerHere()
    local x, y = (C and type(C.PlayerMapFraction) == "function" and mapID) and C.PlayerMapFraction(mapID) or nil
    if faction and zone and type(x) == "number" and type(y) == "number" then
        local sub = (type(GetSubZoneText) == "function") and select(2, pcall(GetSubZoneText)) or nil
        if M.RecordStudySpot(faction, zone, mapID, x * 100, y * 100, sub) then
            self:Say(string.format("Learned Study library in %s (%.1f, %.1f).", zone, x * 100, y * 100))
        end
    end
end

M.Events = { "UNIT_SPELLCAST_SUCCEEDED" }

-- ── Beam marker ───────────────────────────────────────────────────────────
-- Assigned onto Arrow so Tick can paint it. Retail never calls PaintBeam.

local function BuildBeam(f)
    if f._taBeam then return end
    f._taBeam = true
    if f.SetSize then f:SetSize(150, 180) end

    local beam = f:CreateTexture(nil, "ARTWORK")
    beam:SetSize(16, 78)
    beam:SetPoint("TOP", f, "TOP", 0, -2)
    beam:SetTexture(BEAM_TEX)
    f.beamTex = beam

    local ring = f:CreateTexture(nil, "OVERLAY")
    ring:SetSize(22, 22)
    ring:SetPoint("TOP", beam, "BOTTOM", 0, 10)
    if U and U.TEX_RING then ring:SetTexture(U.TEX_RING) end
    if type(ring.SetVertexColor) == "function" then
        pcall(ring.SetVertexColor, ring, 1, 0.82, 0, 1)
    end
    f.ringTex = ring

    local flag = f:CreateTexture(nil, "OVERLAY")
    flag:SetSize(12, 12)
    flag:SetPoint("CENTER", ring, "CENTER", 1, 0)
    flag:SetTexture(FLAG_TEX)
    f.flagTex = flag

    local pill = f:CreateTexture(nil, "BACKGROUND")
    pill:SetHeight(16)
    pill:SetPoint("TOP", ring, "BOTTOM", 0, -4)
    if type(pill.SetColorTexture) == "function" then
        pcall(pill.SetColorTexture, pill, 0.05, 0.04, 0.02, 0.75)
    end
    f.pill = pill

    if f.distF and f.distF.ClearAllPoints then
        f.distF:ClearAllPoints()
        f.distF:SetPoint("CENTER", pill, "CENTER", 0, 0)
        if f.distF.SetTextColor then f.distF:SetTextColor(1, 0.82, 0, 1) end
    end
    if f.titleF and f.titleF.ClearAllPoints then
        f.titleF:ClearAllPoints()
        f.titleF:SetPoint("TOP", pill, "BOTTOM", 0, -3)
        if f.titleF.SetTextColor then f.titleF:SetTextColor(0.92, 0.90, 0.87, 1) end
    end
end

function M.Paint(arrow, f, info)
    if not f or type(f.CreateTexture) ~= "function" then return end
    info = info or {}
    BuildBeam(f)
    if f.arrowTex and f.arrowTex.Hide then f.arrowTex:Hide() end
    if f.arrivedTex and f.arrivedTex.Hide then f.arrivedTex:Hide() end
    if f.beamTex and f.beamTex.Show then f.beamTex:Show() end
    if f.ringTex and f.ringTex.Show then f.ringTex:Show() end
    if f.flagTex and f.flagTex.Show then
        f.flagTex:Show()
        if info.angle and type(f.flagTex.SetRotation) == "function" then
            pcall(f.flagTex.SetRotation, f.flagTex, info.angle)
        end
    end

    local now = (type(GetTime) == "function") and GetTime() or 0
    if info.arrived then
        if f.distF then f.distF:SetText("") end
        if f.pill and f.pill.Hide then f.pill:Hide() end
        if f.titleF then f.titleF:SetText("") end
        if f.etaF and f.etaF.SetText then f.etaF:SetText("") end
        if not arrow._arrived then
            arrow._arrived = true
            arrow._arrivedTime = now
        end
        return
    end
    arrow._arrived = false

    local caption = M.BeamCaption(info.yards, info.speed)
    if f.distF then
        f.distF:SetText(caption)
        if f.distF.SetTextColor then f.distF:SetTextColor(1, 0.82, 0, 1) end
        if f.distF.Show then f.distF:Show() end
    end
    if f.pill then
        if caption == "" then
            if f.pill.Hide then f.pill:Hide() end
        else
            local w = 88
            if f.distF and type(f.distF.GetStringWidth) == "function" then
                local okW, measured = pcall(f.distF.GetStringWidth, f.distF)
                if okW and type(measured) == "number" and measured > 0 then
                    w = measured + 16
                end
            end
            if f.pill.SetWidth then f.pill:SetWidth(w) end
            if f.pill.Show then f.pill:Show() end
        end
    end
    local name = info.label or ""
    if info.quest and name ~= "" then
        name = name .. " |cFFFFFF00!|r"
    end
    if f.titleF then
        f.titleF:SetText(name)
        if f.titleF.SetTextColor then f.titleF:SetTextColor(0.92, 0.90, 0.87, 1) end
    end
    if f.etaF and f.etaF.SetText then f.etaF:SetText("") end
end

local ArrowMod = TA.GetRegisteredModule and TA:GetRegisteredModule("Arrow")
if ArrowMod then
    function ArrowMod:PaintBeam(frame, info)
        M.Paint(self, frame, info)
    end
end

return M
