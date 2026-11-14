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

function M:Pin(place, quest)
    local Arrow = TA:GetModule("Arrow")
    if not (Arrow and type(Arrow.SetWaypoint) == "function" and type(Arrow.MapIDForZone) == "function") then
        self:Say("Suggestion withheld: the arrow is not running.")
        return false
    end
    local mapID = Arrow.MapIDForZone(place.zone)
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
    local note = quest and "Library quest. Optional." or "Auction house. Optional."
    self:Say(string.format("Suggestion: %s, %s (%.1f, %.1f). %s",
        title, place.zone, place.x, place.y, note))
    return true
end

function M:SuggestLibrary()
    local C = TA.Compat
    local faction = C and type(C.PlayerFaction) == "function" and C.PlayerFaction() or nil
    local list = M.AsLibraryList(faction and M.LIBRARIES[faction])
    if not list then
        self:Say("Suggestion withheld: the faction could not be read, so no library was chosen.")
        return false
    end
    local Arrow = TA:GetModule("Arrow")
    local mapID, _, origin = PlayerHere()
    local infoFn = C and C.MapInfo
    local playerCont = Arrow and Arrow.WalkContinent and select(1, Arrow.WalkContinent(mapID, infoFn)) or nil
    local function contOf(place)
        if not (Arrow and type(Arrow.MapIDForZone) == "function" and type(Arrow.WalkContinent) == "function") then
            return nil
        end
        local id = Arrow.MapIDForZone(place.zone)
        return select(1, Arrow.WalkContinent(id, infoFn))
    end
    local function worldOf(place)
        if not (Arrow and type(Arrow.MapIDForZone) == "function") then return nil end
        local id = Arrow.MapIDForZone(place.zone)
        if type(id) ~= "number" then return nil end
        return WorldPoint(id, place.x, place.y)
    end
    local place = M.ChooseLibrary(list, playerCont, contOf, origin, worldOf)
    if not place then
        self:Say("Suggestion withheld: no library on this continent could be measured.")
        return false
    end
    return self:Pin(place, true)
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
    return self:Pin(place, false)
end

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
