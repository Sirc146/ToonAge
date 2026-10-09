-- Copies each standalone faction route into the guide registry.
-- rep/<faction>.lua stores TA.RepRoutes[factionID], which GuideParser does
-- not read. The tracker loads midnight_rep_<factionID> through QuestTracker.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

local routes = TA.RepRoutes
if type(routes) ~= "table" then return end

for id, route in pairs(routes) do
    if type(route) == "table" then
        local factionID = route.factionID or id
        if type(factionID) == "number" then
            local gid = "midnight_rep_" .. tostring(factionID)
            local steps = route.steps
            if type(steps) ~= "table" then steps = {} end
            TA.GuideData[gid] = {
                id = gid,
                title = (type(route.name) == "string" and route.name) or gid,
                expansion = "midnight",
                kind = "reputation",
                factionID = factionID,
                steps = steps,
            }
        end
    end
end
