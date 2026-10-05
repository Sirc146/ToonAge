-- ToonAge/Modules/Infrastructure/Harvester.lua  (harvest core, shared)
--
-- The client-agnostic half of the harvester. Spec:
-- Docs/SPEC_HARVEST_SENSOR_ARRAY.md (T3 of T1-T10). Follows the
-- CoordHarvester precedent: one store per client under TA.db, hard caps,
-- export as text, nothing interpreted.
--
-- What lives here (T3):
--   * the STORE: TA.db.harvest, version 3. A save written before this moved
--     the Forever store there from TA.db.foreverHarvest (D2, 2026-10-04) --
--     moved, not copied, so the saved file never holds the same table twice.
--   * the CLIENT STAMP: flavor, version, build, interface, project, ToonAge
--     version, channel ("unknown" until the player sets it -- never guessed),
--     first/last seen. Read through the capability layer (Core/Caps.lua).
--   * TIMES: first/last write per section, for the export's harvest range.
--   * EXPORT: every section through the one formatter
--     (Modules/Infrastructure/HarvestFormat.lua), stamped, paged, to the copy
--     window; plus the registry the Harvest tab builds its Copy row from.
-- What does not live here yet: the scans, probes, report and tab are still in
-- Modules/Forever/DataHarvester.lua and move in T4.

local TA = ToonAge

local type, pairs, ipairs, tostring, next = type, pairs, ipairs, tostring, next
local concat = table.concat

local Hv = {}
TA.Harvester = Hv

local STORE_VERSION = 3

-- Sections every store carries, empty until something is recorded. Others
-- (talentGates, talentConds, talentApi, catalog, ...) appear when written.
local BASE_SECTIONS = { "items", "spells", "talents", "chars", "counts", "racials", "trainer", "talentGeo", "catalog" }

-- Store fields that are not exportable sections (HarvestFormat skips them too).
local NOT_SECTIONS = { client = true, times = true }

-- section table -> section name, so a write through Put can stamp its section's
-- time without every call site naming it. Weak keys: a cleared store's tables go.
local sectionOf = setmetatable({}, { __mode = "k" })

local function Now()
    return (type(time) == "function") and time() or nil
end

-- Merge `from` into `into` without overwriting: first-seen wins, the same rule
-- every harvest write follows. Nested tables (trainer[CLASS]) merge per key.
local function MergeMissing(into, from)
    for k, v in pairs(from) do
        if into[k] == nil then
            into[k] = v
        elseif type(into[k]) == "table" and type(v) == "table" then
            MergeMissing(into[k], v)
        end
    end
end

-- ── Client stamp ──────────────────────────────────────────────────────────

function Hv:StampClient(s)
    local c = s.client
    local Caps = TA.Caps
    if Caps then
        local ok, version, build, _, interface = Caps.Call("GetBuildInfo")
        if ok then
            c.version, c.build, c.interface = version, build, interface
            -- Every build this store has been written on, first seen. The stamp
            -- above is the CURRENT build; records may come from older ones.
            if build ~= nil then
                c.buildsSeen = c.buildsSeen or {}
                local key = tostring(build)
                if c.buildsSeen[key] == nil then c.buildsSeen[key] = Now() or 0 end
            end
        end
        local project, state = Caps.Get("WOW_PROJECT_ID")
        if state == "present" then c.project = project end
    end
    c.flavor  = TA.flavor or c.flavor
    c.toonage = TA.version or c.toonage
    c.channel = c.channel or "unknown"   -- D1: set by the player only, never guessed
    local now = Now()
    c.firstSeen = c.firstSeen or now
    c.lastSeen  = now
end

-- ── Store ─────────────────────────────────────────────────────────────────

--- The harvest store for this client, created or migrated on first use.
--- Cheap after the first call in a session (identity check only).
function Hv:Store()
    local db = TA.db
    if type(db) ~= "table" then return nil end
    local s = db.harvest
    if type(s) == "table" and s == self._s and db.foreverHarvest == nil then return s end

    local old = db.foreverHarvest
    if type(s) ~= "table" then
        if type(old) == "table" then
            -- D2: move the Forever store. Same table object, new key.
            s = old
            s.client = s.client or {}
            s.client.migratedFrom    = "foreverHarvest"
            s.client.migratedAt      = Now()
            s.client.migratedVersion = old.version
        else
            s = {}
        end
        db.harvest = s
    elseif type(old) == "table" and old ~= s then
        -- Both keys present (an older build ran after the move and started a
        -- fresh foreverHarvest). Keep everything: fold its records in, first
        -- seen wins, then drop the old key.
        MergeMissing(s, old)
        s.client = s.client or {}
        s.client.mergedFrom = "foreverHarvest"
        s.client.mergedAt   = Now()
    end
    db.foreverHarvest = nil

    -- Backfill rather than reset: an older store still holds real observations.
    for _, k in ipairs(BASE_SECTIONS) do s[k] = s[k] or {} end
    s.client = s.client or {}
    s.times  = s.times  or {}
    s.version = STORE_VERSION

    for k, v in pairs(s) do
        if type(v) == "table" and not NOT_SECTIONS[k] then sectionOf[v] = k end
    end
    self:StampClient(s)
    self._s = s
    return s
end

--- Throws the store away (the Harvest tab's two-click Clear).
function Hv:Clear()
    if type(TA.db) ~= "table" then return end
    TA.db.harvest = nil
    TA.db.foreverHarvest = nil
    self._s = nil
end

--- Stamp a section's write time (first and last).
function Hv:Touch(section)
    local s = self:Store()
    local now = Now()
    if not (s and section and now) then return end
    local t = s.times[section]
    if type(t) ~= "table" then
        t = {}
        s.times[section] = t
    end
    t.first = t.first or now
    t.last  = now
end

--- Stamp the section a table belongs to, if it is a section table.
function Hv:TouchTable(tbl)
    local section = tbl and sectionOf[tbl]
    if section then self:Touch(section) end
end

--- Record count of a section, nested tables included (trainer[CLASS][id]).
function Hv:Count(section)
    local s = self:Store()
    local n = 0
    local function walk(t)
        for _, v in pairs(t) do
            if type(v) == "table" then walk(v) else n = n + 1 end
        end
    end
    if s and type(s[section]) == "table" then walk(s[section]) end
    return n
end

-- ── Export ────────────────────────────────────────────────────────────────

--- The stamp an export carries (R9). Built from the store's client block and
--- its section times, formatted with the client's date().
function Hv:Meta()
    local s = self:Store() or {}
    local c = s.client or {}
    local lo, hi
    for _, t in pairs(s.times or {}) do
        if type(t) == "table" then
            if type(t.first) == "number" and (not lo or t.first < lo) then lo = t.first end
            if type(t.last) == "number" and (not hi or t.last > hi) then hi = t.last end
        end
    end
    -- Records moved or merged in from foreverHarvest were written before the
    -- store kept write times, so nothing says when the oldest was harvested.
    -- The range starts "unknown" rather than at the first write since the
    -- move (which would date old records to today). Clear starts a fresh,
    -- fully dated store.
    if c.migratedFrom or c.mergedFrom then lo = nil end
    local fmt = (type(date) == "function") and date or nil
    return {
        flavor         = c.flavor,
        version        = c.version,
        build          = c.build,
        interface      = c.interface,
        project        = c.project,
        channel        = c.channel,
        harvestedFirst = (fmt and lo) and fmt("%Y-%m-%d", lo) or nil,
        harvestedLast  = (fmt and hi) and fmt("%Y-%m-%d", hi) or nil,
        exported       = fmt and fmt("%Y-%m-%d %H:%M") or nil,
        store          = s.version,
        toonage        = c.toonage,
    }
end

--- One page of a section, stamped. page 0 = every record.
function Hv:ExportLines(section, page)
    local s = self:Store()
    local F = TA.HarvestFormat
    if not (s and F) then return nil end
    return F.Lines(s, section, page or 1, self:Meta())
end

--- Opens one page of a section in the copy window. Returns page, pages.
function Hv:Export(section, page)
    local out, p, pages = self:ExportLines(section, page)
    if not out then return nil end
    if TA.ShowCopyWindow then
        TA:ShowCopyWindow(("ToonAge harvest — %s (%d/%d)"):format(tostring(section), p, pages),
                          concat(out, "\n"))
    end
    return p, pages
end

-- The Copy row: { section, label } in registration order. Whoever records a
-- section registers its button, so each client shows exactly what it has.
Hv._exports = Hv._exports or {}

function Hv:RegisterExport(section, label)
    for _, e in ipairs(self._exports) do
        if e.section == section then e.label = label or e.label return end
    end
    self._exports[#self._exports + 1] = { section = section, label = label or section }
end

function Hv:Exports()
    return self._exports
end

--- True when the store has at least one record in the section.
function Hv:Has(section)
    local s = self:Store()
    return s ~= nil and type(s[section]) == "table" and next(s[section]) ~= nil
end
