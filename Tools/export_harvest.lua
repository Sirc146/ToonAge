-- Tools/export_harvest.lua
--
-- Exports a harvest from the SAVED FILE, one stamped TSV per section, through
-- the same formatter the in-game copy buttons use
-- (Modules/Infrastructure/HarvestFormat.lua). Spec R10: the two paths agree
-- byte for byte on every record; only the "exported" time differs.
--
--   lua Tools/export_harvest.lua <WTF\...\SavedVariables\ToonAge.lua> <out dir> [channel]
--
--   channel  beta | live | ptr -- what you know the data came from. If you
--            leave it off, the channel the store recorded is used (the Harvest
--            tab's Channel button, once that exists), else "unknown". It is
--            never guessed from a realm name (S3 decision, 2026-10-04).
--
-- Writes <out dir>/<section>.tsv for every section in the store and prints a
-- one-line count per file. Reads the current store (ToonAgeDB.harvest) or, for
-- a save written before the move, the Forever store (ToonAgeDB.foreverHarvest).

local svPath, outDir, channelArg = arg[1], arg[2], arg[3]
if not (svPath and outDir) then
    io.stderr:write("usage: lua export_harvest.lua <ToonAge.lua saved file> <out dir> [channel]\n")
    os.exit(2)
end

-- The formatter lives next to the addon code; find it from this script's path.
local here = (arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
ToonAge = {}
dofile(here .. "/../Modules/Infrastructure/HarvestFormat.lua")
local F = ToonAge.HarvestFormat

dofile(svPath)
local db = ToonAgeDB
if type(db) ~= "table" then
    io.stderr:write("no ToonAgeDB in " .. svPath .. "\n")
    os.exit(1)
end
local store, legacy = db.harvest, false
if type(store) ~= "table" and type(db.foreverHarvest) == "table" then
    store, legacy = db.foreverHarvest, true
end
if type(store) ~= "table" then
    io.stderr:write("no harvest store (ToonAgeDB.harvest / .foreverHarvest) in " .. svPath .. "\n")
    os.exit(1)
end

-- ── Stamp ─────────────────────────────────────────────────────────────────
-- Everything comes from what the store recorded. For a save written before
-- the store kept a client block, only what its records state verbatim is
-- used: the catalog's build number and the interface each character record
-- carries. Anything else prints "unknown".
local c = type(store.client) == "table" and store.client or {}

local function interfaceFromChars()
    local seen, list = {}, {}
    for _, line in pairs(store.chars or {}) do
        local f = {}
        for v in (tostring(line) .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = v end
        local iface = f[7]
        if iface and iface ~= "" and not seen[iface] then
            seen[iface] = true
            list[#list + 1] = iface
        end
    end
    table.sort(list)
    if #list == 0 then return nil end
    if #list == 1 then return list[1] end
    return "mixed:" .. table.concat(list, ",")   -- say so rather than pick one
end

local function harvestRange()
    local lo, hi
    for _, t in pairs(type(store.times) == "table" and store.times or {}) do
        if type(t) == "table" then
            if type(t.first) == "number" and (not lo or t.first < lo) then lo = t.first end
            if type(t.last) == "number" and (not hi or t.last > hi) then hi = t.last end
        end
    end
    -- Same rule as the in-game core (Harvester.lua Meta): records moved or
    -- merged in from foreverHarvest carry no write time, so the start is unknown.
    if c.migratedFrom or c.mergedFrom then lo = nil end
    return lo and os.date("%Y-%m-%d", lo) or nil, hi and os.date("%Y-%m-%d", hi) or nil
end

local first, last = harvestRange()
local meta = {
    flavor         = c.flavor or (legacy and "forever" or nil),
    version        = c.version,
    build          = c.build or store.catalogBuild,
    interface      = c.interface or interfaceFromChars(),
    project        = c.project,
    channel        = (channelArg and channelArg ~= "") and channelArg or c.channel,
    harvestedFirst = first,
    harvestedLast  = last,
    exported       = os.date("%Y-%m-%d %H:%M"),
    store          = store.version,
    toonage        = c.toonage,
}

-- ── Write ─────────────────────────────────────────────────────────────────
local function canWrite(dir)
    local probe = dir .. "/.toonage_probe"
    local f = io.open(probe, "wb")
    if f then f:close(); os.remove(probe); return true end
    return false
end
if not canWrite(outDir) then
    os.execute('mkdir "' .. outDir .. '"')
    if not canWrite(outDir) then
        io.stderr:write("cannot write to " .. outDir .. "\n")
        os.exit(1)
    end
end

local wrote = 0
for _, section in ipairs(F.Sections(store)) do
    local text = F.Text(store, section, meta)
    if text then
        local path = outDir .. "/" .. section .. ".tsv"
        local f = assert(io.open(path, "wb"))
        f:write(text)
        f:close()
        print(("%-14s %6d records -> %s"):format(section, #F.Rows(store[section]), path))
        wrote = wrote + 1
    end
end
print(("%d section(s) written from %s%s"):format(wrote, legacy and "ToonAgeDB.foreverHarvest" or "ToonAgeDB.harvest",
    (meta.channel and "" or " (channel unknown -- pass beta/live/ptr as the third argument if you know it)")))
