-- ToonAge/Modules/Infrastructure/HarvestFormat.lua  (pure Lua 5.1, no client calls)
--
-- The ONE formatter for harvest exports. Spec: Docs/SPEC_HARVEST_SENSOR_ARRAY.md
-- sections 4.5 and R9/R10 (T2).
--
-- Two paths export a harvest and they must agree byte for byte:
--   * in game, the Harvest tab's copy buttons (wired to this in T3)
--   * outside the game, Tools/export_harvest.lua reading the saved file
-- Both call F.Lines with the same store and the same meta, so the section
-- output is identical by construction, not by keeping two copies in step.
-- Tools/test_harvest_format.py runs this file both ways and compares.
--
-- Rules this file keeps:
--   * PURE. No client API, no date(), no os.*. Times arrive pre-formatted in
--     `meta`, because the game has date() and the Tools runtime has os.date().
--   * VERBATIM. Records are emitted exactly as stored: key, tab, line. Nothing
--     is parsed, reordered within a line, or interpreted.
--   * STAMPED. Every export starts with the same three header lines (R9): what
--     produced the data (client, version, build, interface, project, channel),
--     when (harvest range, export time) and how (store and ToonAge versions).
--     A field nobody recorded prints "unknown" -- it is never guessed.
--   * SORTED. Keys sort by their string form, so two exports of the same store
--     are identical and a diff between harvests shows only real change.

local TA = ToonAge

local F = {}
TA.HarvestFormat = F

local type, pairs, tostring = type, pairs, tostring
local sort, concat, floor = table.sort, table.concat, math.floor

F.PAGE_SIZE = 400   -- records per page; a copy window past this scrolls badly

local UNKNOWN = "unknown"

local function S(v)
    if v == nil or v == "" then return UNKNOWN end
    return tostring(v)
end

local function ByString(a, b) return tostring(a) < tostring(b) end

--- Sorted keys of a table (string order).
function F.SortedKeys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys + 1] = k end
    sort(keys, ByString)
    return keys
end

--- Rows of a section as { key, line } pairs, sorted by key. Nested tables
--- flatten to "outer:inner" keys (trainer[CLASS][spellID] -> "CLASS:spellID"),
--- at any depth, so every section exports as one flat TSV.
function F.Rows(tbl)
    local rows = {}
    local function walk(t, prefix)
        for k, v in pairs(t) do
            local key = prefix and (prefix .. ":" .. tostring(k)) or tostring(k)
            if type(v) == "table" then
                walk(v, key)
            else
                rows[#rows + 1] = { key, tostring(v) }
            end
        end
    end
    if type(tbl) == "table" then walk(tbl, nil) end
    sort(rows, function(a, b) return a[1] < b[1] end)
    return rows
end

--- Names of the exportable sections in a store: every table-valued field,
--- sorted. Scalars (version, catalogBuild, trainerFormat ...) are store
--- metadata, not sections, and travel in the header instead.
function F.Sections(store)
    local out = {}
    for k, v in pairs(store or {}) do
        if type(v) == "table" and k ~= "client" and k ~= "times" then out[#out + 1] = k end
    end
    sort(out, ByString)
    return out
end

--- The three stamp lines (R9).
---   meta = { flavor, version, build, interface, project, channel,
---            harvestedFirst, harvestedLast, exported, store, toonage }
---   page = 0 means the whole section in one block.
function F.Header(meta, section, page, pages, first, last, total)
    meta = meta or {}
    local what
    if page == 0 then
        what = ("-- ToonAge harvest · %s · all %d records"):format(S(section), total or 0)
    else
        what = ("-- ToonAge harvest · %s · page %d/%d · records %d-%d of %d")
            :format(S(section), page or 1, pages or 1, first or 0, last or 0, total or 0)
    end
    local client = ("-- client %s · %s · build %s · interface %s · project %s · channel %s")
        :format(S(meta.flavor), S(meta.version), S(meta.build), S(meta.interface),
                S(meta.project), S(meta.channel))
    local when = ("-- harvested %s .. %s · exported %s · store v%s · ToonAge %s")
        :format(S(meta.harvestedFirst), S(meta.harvestedLast), S(meta.exported),
                S(meta.store), S(meta.toonage))
    return { what, client, when }
end

--- One page of a section as lines: the header, a blank line, then one
--- "key<TAB>record" line per record. Returns lines, page, pages; nil when the
--- section is not a table in this store.
---   page 0 = every record in one block; pages count from 1 and clamp.
function F.Lines(store, section, page, meta, pageSize)
    local tbl = store and store[section]
    if type(tbl) ~= "table" then return nil end
    local rows = F.Rows(tbl)
    local total = #rows
    page = page or 1
    pageSize = pageSize or F.PAGE_SIZE

    local first, last, pages
    if page == 0 then
        first, last, pages = 1, total, 1
    else
        pages = (total == 0) and 1 or floor((total + pageSize - 1) / pageSize)
        if page > pages then page = pages end
        if page < 1 then page = 1 end
        first = (page - 1) * pageSize + 1
        last = page * pageSize
        if last > total then last = total end
    end

    local out = F.Header(meta, section, page, pages, (total == 0) and 0 or first, last, total)
    out[#out + 1] = ""
    for i = first, last do
        local r = rows[i]
        if r then out[#out + 1] = r[1] .. "\t" .. r[2] end
    end
    return out, (page == 0) and 1 or page, pages
end

--- Whole-section text, as written to a file or shown in a copy window.
function F.Text(store, section, meta)
    local lines = F.Lines(store, section, 0, meta)
    if not lines then return nil end
    return concat(lines, "\n") .. "\n"
end
