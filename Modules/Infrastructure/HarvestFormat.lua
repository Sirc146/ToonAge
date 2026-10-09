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
--   * STAMPED. Every export starts with the same four header lines (R9): what
--     produced the data (client, version, build, interface, project, channel),
--     which class the rows are (source, who recorded them, the current
--     character), and when (harvest range, export time, store and ToonAge
--     versions). A field nobody recorded prints "unknown" -- it is never
--     guessed.
--   * SORTED. Keys sort by their string form, so two exports of the same store
--     are identical and a diff between harvests shows only real change.

local TA = ToonAge

local F = {}
TA.HarvestFormat = F

local type, pairs, tostring = type, pairs, tostring
local sort, concat, floor = table.sort, table.concat, math.floor

F.PAGE_SIZE = 400   -- records per page; a copy window past this scrolls badly

-- Sections whose keys are one class. trainer nests trainer[CLASS][spellID];
-- spells and talents prefix the key with "CLASS:"; catalog is spell IDs, and
-- a class's slice is the IDs that class has in spells or trainer.
F.CLASS_SECTIONS = { trainer = true, spells = true, talents = true, catalog = true }

local CLASS_NAME = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
    PRIEST = "Priest", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage",
    WARLOCK = "Warlock", MONK = "Monk", DRUID = "Druid", DEMONHUNTER = "Demon Hunter",
    EVOKER = "Evoker",
}

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

--- Display name for a class token ("HUNTER" -> "Hunter"). Unknown tokens are
--- title-cased, never translated.
function F.ClassName(token)
    if type(token) ~= "string" or token == "" then return UNKNOWN end
    if CLASS_NAME[token] then return CLASS_NAME[token] end
    return token:sub(1, 1):upper() .. token:sub(2):lower()
end

--- "Showing saved Hunter data", or several classes joined in token order.
function F.SavedLabel(tokens)
    local names = {}
    for i = 1, #(tokens or {}) do names[i] = F.ClassName(tokens[i]) end
    if #names == 0 then return nil end
    if #names == 1 then return "Showing saved " .. names[1] .. " data" end
    if #names == 2 then return "Showing saved " .. names[1] .. " and " .. names[2] .. " data" end
    local last = names[#names]
    local head = {}
    for i = 1, #names - 1 do head[i] = names[i] end
    return "Showing saved " .. concat(head, ", ") .. " and " .. last .. " data"
end

--- Character names in chars whose class matches `source` ("all" = every name).
--- Nil when nobody was recorded, so the stamp prints "unknown".
function F.RecordedBy(store, source)
    local chars = store and store.chars
    if type(chars) ~= "table" then return nil end
    local names, seen = {}, {}
    for _, line in pairs(chars) do
        if type(line) ~= "table" then
            local name, _, cls = tostring(line):match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
            if name and name ~= "" and name ~= "?" and (source == "all" or source == cls) then
                if not seen[name] then
                    seen[name] = true
                    names[#names + 1] = name
                end
            end
        end
    end
    sort(names, ByString)
    if #names == 0 then return nil end
    return concat(names, ", ")
end

--- Spell IDs this class has actually recorded (spellbook keys and trainer rows).
function F.SpellIDsForClass(store, token)
    local ids = {}
    if type(token) ~= "string" or token == "" then return ids end
    local pfx = token .. ":"
    local spells = store and store.spells
    if type(spells) == "table" then
        for k in pairs(spells) do
            local key = tostring(k)
            if key:sub(1, #pfx) == pfx then
                local id = key:sub(#pfx + 1)
                if id:match("^%d+$") then ids[id] = true end
            end
        end
    end
    local trainer = store and store.trainer
    local sub = type(trainer) == "table" and trainer[token] or nil
    if type(sub) == "table" then
        for id in pairs(sub) do
            local s = tostring(id)
            if s:match("^%d+$") then ids[s] = true end
        end
    end
    return ids
end

--- The section limited to one class. Trainer keeps the CLASS: key prefix.
--- A class with nothing stored returns an empty table, never another class.
function F.Scoped(store, section, token)
    local tbl = store and store[section]
    if type(tbl) ~= "table" then return {} end
    if section == "trainer" then
        local sub = tbl[token]
        if type(sub) ~= "table" then return {} end
        return { [token] = sub }
    end
    if section == "spells" or section == "talents" then
        local out, pfx = {}, token .. ":"
        for k, v in pairs(tbl) do
            if tostring(k):sub(1, #pfx) == pfx then out[k] = v end
        end
        return out
    end
    if section == "catalog" then
        local ids = F.SpellIDsForClass(store, token)
        local out = {}
        for k, v in pairs(tbl) do
            if ids[tostring(k)] then out[k] = v end
        end
        return out
    end
    return tbl
end

--- Class tokens that have rows in this section, sorted. Catalog counts a class
--- only when one of its recorded spell IDs is in the catalog.
function F.ClassesIn(store, section)
    local seen, list = {}, {}
    local function add(token)
        if type(token) == "string" and token ~= "" and not seen[token] then
            seen[token] = true
            list[#list + 1] = token
        end
    end
    store = store or {}
    if section == "trainer" then
        for cls, rows in pairs(store.trainer or {}) do
            if type(rows) == "table" and next(rows) ~= nil then add(cls) end
        end
    elseif section == "spells" or section == "talents" then
        for k, v in pairs(store[section] or {}) do
            if type(v) ~= "table" then add(tostring(k):match("^([^:]+)")) end
        end
    elseif section == "catalog" then
        local candidates, marked = {}, {}
        local function consider(token)
            if type(token) == "string" and token ~= "" and not marked[token] then
                marked[token] = true
                candidates[#candidates + 1] = token
            end
        end
        for cls, rows in pairs(store.trainer or {}) do
            if type(rows) == "table" and next(rows) ~= nil then consider(cls) end
        end
        for k, v in pairs(store.spells or {}) do
            if type(v) ~= "table" then consider(tostring(k):match("^([^:]+)")) end
        end
        for _, cls in ipairs(candidates) do
            local ids = F.SpellIDsForClass(store, cls)
            for key in pairs(store.catalog or {}) do
                if ids[tostring(key)] then add(cls) break end
            end
        end
    end
    sort(list, ByString)
    return list
end

--- What an empty class-scoped export says instead of another class's rows.
function F.EmptyLine(section, token)
    local up = tostring(token or "")
    local name = up:lower()
    if section == "trainer" then
        return ("No %s trainer data yet. Open a %s trainer to record it."):format(up, name)
    elseif section == "spells" then
        return ("No %s spell data yet. Open your spellbook to record it."):format(up)
    elseif section == "talents" then
        return ("No %s talent data yet. Open your talent frame to record it."):format(up)
    elseif section == "catalog" then
        return ("No %s spell catalog data yet. Open a %s trainer or your spellbook to record it."):format(up, name)
    end
end

--- The four stamp lines (R9). Line 3 is the class the rows came from.
---   meta = { flavor, version, build, interface, project, channel,
---            harvestedFirst, harvestedLast, exported, store, toonage,
---            source, recordedBy, currentClass }
---   source defaults to "all" (the whole section). A missing name prints
---   "unknown". page = 0 means the whole section in one block.
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
    local source = meta.source
    if source == nil or source == "" then source = "all" end
    local who = ("-- source %s %s · recorded by %s · current character %s")
        :format(S(source), S(section), S(meta.recordedBy), S(meta.currentClass))
    local when = ("-- harvested %s .. %s · exported %s · store v%s · ToonAge %s")
        :format(S(meta.harvestedFirst), S(meta.harvestedLast), S(meta.exported),
                S(meta.store), S(meta.toonage))
    return { what, client, who, when }
end

--- One page of a section as lines: the header, a blank line, then one
--- "key<TAB>record" line per record. Returns lines, page, pages; nil when the
--- section is not a table in this store.
---   page 0 = every record in one block; pages count from 1 and clamp.
function F.Lines(store, section, page, meta, pageSize)
    local tbl = store and store[section]
    if type(tbl) ~= "table" then return nil end
    meta = meta or {}
    local token = meta.class
    local filtering = type(token) == "string" and token ~= "" and token ~= "all"
        and F.CLASS_SECTIONS[section] == true
    local rows = F.Rows(filtering and F.Scoped(store, section, token) or tbl)
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

    local source = filtering and token or "all"
    local stamp = {
        flavor = meta.flavor, version = meta.version, build = meta.build,
        interface = meta.interface, project = meta.project, channel = meta.channel,
        harvestedFirst = meta.harvestedFirst, harvestedLast = meta.harvestedLast,
        exported = meta.exported, store = meta.store, toonage = meta.toonage,
        source = source,
        recordedBy = (meta.recordedBy ~= nil and meta.recordedBy ~= "") and meta.recordedBy
            or F.RecordedBy(store, source),
        currentClass = meta.currentClass,
    }
    local out = F.Header(stamp, section, page, pages, (total == 0) and 0 or first, last, total)
    out[#out + 1] = ""
    if filtering and total == 0 then
        local sentence = F.EmptyLine(section, token)
        if sentence then out[#out + 1] = sentence end
    else
        for i = first, last do
            local r = rows[i]
            if r then out[#out + 1] = r[1] .. "\t" .. r[2] end
        end
    end
    return out, (page == 0) and 1 or page, pages
end

--- Whole-section text, as written to a file or shown in a copy window.
function F.Text(store, section, meta)
    local lines = F.Lines(store, section, 0, meta)
    if not lines then return nil end
    return concat(lines, "\n") .. "\n"
end
