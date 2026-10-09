-- ToonAge/Modules/Infrastructure/Harvester.lua  (harvest core, shared)
--
-- The client-agnostic half of the harvester, and since T4 the registered
-- module itself (still named "DataHarvester", so profile allow-lists, the
-- `harvest` tab entry, /ta health and the module toggles keep working). Spec:
-- Docs/SPEC_HARVEST_SENSOR_ARRAY.md. Follows the CoordHarvester precedent: one
-- store per client under TA.db, hard caps, export as text, nothing
-- interpreted.
--
-- What lives here:
--   * the STORE: TA.db.harvest, version 3. A save written before T3 moved the
--     Forever store there from TA.db.foreverHarvest (D2, 2026-10-04) -- moved,
--     not copied, so the saved file never holds the same table twice.
--   * the CLIENT STAMP: flavor, version, build, interface, project, ToonAge
--     version, channel ("unknown" until the player sets it -- never guessed),
--     first/last seen. Read through the capability layer (Core/Caps.lua).
--   * TIMES: first/last write per section, for the export's harvest range.
--   * EXPORT: every section through the one formatter
--     (Modules/Infrastructure/HarvestFormat.lua), stamped, paged, to the copy
--     window; plus the registry the Harvest tab builds its Copy row from.
--   * RECORD HELPERS the domains write through (Put, PutOrUpgrade, Clean),
--     the guarded call (Try, through Caps), and the event fan-out.
--   * the SPELL CATALOG engine (the ID ranges are client config, in the pack),
--     the FULL REPORT, the PROBE report and the HARVEST TAB.
--
-- What the clients add (T4):
--   * Modules/Harvest/Domains/*.lua -- one per kind of data (items, spellbook,
--     trait tree, trainer ...). Logic only; every client API call goes
--     through TA.Caps. Each registers with Hv:RegisterDomain.
--   * Modules/Harvest/Packs/<Client>.lua -- which domains this client runs,
--     its catalog ranges, its own probes and tab rows. The TOC is the
--     packaging gate: a client's TOC lists only its own pack. With no pack for
--     this client the module stands down at Init.

local TA = ToonAge

local type, pairs, ipairs, tostring, tonumber, next, select, pcall, error =
      type, pairs, ipairs, tostring, tonumber, next, select, pcall, error
local concat, sort = table.concat, table.sort

local Hv = {}
TA.Harvester = Hv

local STORE_VERSION = 3

-- Sections every store carries, empty until something is recorded. Others
-- (talentGates, talentConds, talentApi, trainerProf, ...) appear when written.
local BASE_SECTIONS = { "items", "spells", "talents", "chars", "counts", "racials", "trainer", "talentGeo", "catalog" }

-- Store fields that are not exportable sections (HarvestFormat skips them too).
-- captures is per character and per scan; the section exporter does not flatten it.
local NOT_SECTIONS = { client = true, times = true, captures = true }

-- section table -> section name, so a write through Put can stamp its section's
-- time without every call site naming it. Weak keys: a cleared store's tables go.
local sectionOf = setmetatable({}, { __mode = "k" })

local function Now()
    return (type(time) == "function") and time() or nil
end
Hv.Now = Now

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
    s.client   = s.client   or {}
    s.times    = s.times    or {}
    s.captures = s.captures or {}
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

--- Makes `tbl` a section of the store (a section created after the store was
--- opened, such as trainerProf), so Put can stamp its time.
function Hv:AdoptSection(section, tbl)
    if type(tbl) == "table" and section and not NOT_SECTIONS[section] then sectionOf[tbl] = section end
    return tbl
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

-- ── Record helpers (the domains write through these) ─────────────────────
--
-- The rules the recorder has always held to (moved here from
-- Modules/Forever/DataHarvester.lua in T4):
--   * IDEMPOTENT. A known key is never rewritten, so a full bag scan after
--     the first is nearly free and the store does not grow with playtime.
--   * BOUNDED. Every table has a hard cap; SavedVariables that grow forever
--     eventually corrupt on write, and a lost store costs weeks of play.
--   * FLAT STRINGS. One tab-separated line per record: small, diffable, and
--     trivial to parse outside the game.

--- Number of keys in a table (one level).
function Hv.Size(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end
local Size = Hv.Size

--- Writes key -> line if the key is new and the table is under its cap.
--- Returns true when something was actually recorded.
--- Character scans do not use this. A probe, trainer, spellbook or talent
--- run overwrites that character's capture (SaveCapture); a known key here
--- stays so the shared class catalog does not grow on every login.
function Hv.Put(tbl, key, line, cap)
    if tbl[key] ~= nil then return false end
    if cap and Size(tbl) >= cap then return false end
    tbl[key] = line
    Hv:TouchTable(tbl)
    return true
end

--- Like Put, but replaces a record written by an older schema: one with fewer
--- than `minFields` tab-separated fields. Everything else stays first-seen.
function Hv.PutOrUpgrade(tbl, key, line, cap, minFields)
    local old = tbl[key]
    if old ~= nil then
        local _, tabs = tostring(old):gsub("\t", "")
        if tabs + 1 >= minFields then return false end
        tbl[key] = line
        Hv:TouchTable(tbl)
        return true
    end
    return Hv.Put(tbl, key, line, cap)
end

--- Tabs separate fields, so any tab inside a value would corrupt the record.
function Hv.Clean(v)
    v = tostring(v or "")
    return (v:gsub("[\t\r\n]", " "))
end

--- Splits a stored line into its fields (empty fields kept).
function Hv.Fields(line)
    local f = {}
    for v in (tostring(line) .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = v end
    return f
end

local function Strip(ok, ...)
    if not ok then return nil end
    return ...
end

--- The guarded client call: the values the client returned, or nil when the
--- path is missing or the call errors. Through Caps, so a secret return comes
--- back as the word "secret" and is never stored as a number or as empty.
function Hv.Try(path, ...)
    local Caps = TA.Caps
    if not Caps then return nil end
    return Strip(Caps.Call(path, ...))
end

--- True for a value the client marks secret (Midnight-era clients, combat).
function Hv.IsSecret(v)
    local Caps = TA.Caps
    local f = Caps and Caps.Fn("issecretvalue")
    if not f then return false end
    local ok, r = pcall(f, v)
    return ok and r == true
end

--- Runs fn after `sec` seconds (C_Timer.After), if this client has it.
function Hv.After(sec, fn)
    local Caps = TA.Caps
    local f = Caps and Caps.Fn("C_Timer.After")
    if f then f(sec, fn) end
end

--- At most one pending call per key: the first request schedules fn after
--- `delay` seconds, later requests inside that window are dropped. Bag events
--- fire several times per loot, and TRAINER_UPDATE on every filter click.
Hv._pending = Hv._pending or {}
function Hv:Once(key, delay, fn)
    if self._pending[key] then return end
    self._pending[key] = true
    Hv.After(delay, function()
        self._pending[key] = nil
        fn()
    end)
end

-- Automatic captures run at most once every 10 seconds per type. The first
-- request in a window runs now. A later one is kept and runs once the window
-- ends, so a spell learned a second later is not dropped.
local THROTTLE_SEC = 10
Hv._throttleAt = Hv._throttleAt or {}
Hv._throttlePending = Hv._throttlePending or {}
Hv._throttleWaiting = Hv._throttleWaiting or {}

function Hv:Clock()
    if type(GetTime) == "function" then
        local ok, t = pcall(GetTime)
        if ok and type(t) == "number" then return t end
    end
    return 0
end

function Hv:InCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

--- One line, e.g. "Harvest: trainer saved (Solm Hargrin, 12 spells)".
--- TA.db.harvestToast == false turns every notice off. A scan in progress
--- stays quiet and reports once when it finishes.
function Hv:Toast(line)
    if self._quiet then return end
    if type(line) ~= "string" or line == "" then return end
    if TA.db and TA.db.harvestToast == false then return end
    if TA.Raw then TA:Raw(TA.LOG.OUTPUT, line) end
end

function Hv:NoticesOn()
    return not (TA.db and TA.db.harvestToast == false)
end

function Hv:Request(kind, fn)
    if type(fn) ~= "function" then return end
    local now = self:Clock()
    local last = self._throttleAt[kind]
    if last and (now - last) < THROTTLE_SEC then
        self._throttlePending[kind] = fn
        if not self._throttleWaiting[kind] then
            self._throttleWaiting[kind] = true
            local wait = THROTTLE_SEC - (now - last)
            if wait < 0 then wait = 0 end
            Hv.After(wait, function()
                self._throttleWaiting[kind] = nil
                local pending = self._throttlePending[kind]
                self._throttlePending[kind] = nil
                if pending then
                    self._throttleAt[kind] = self:Clock()
                    pending()
                end
            end)
        end
        return
    end
    self._throttleAt[kind] = now
    fn()
end

function Hv:CaptureCount(kind)
    local s = self:Store()
    local key = self:CharacterKey()
    local scan = s and key and s.captures and s.captures[key] and s.captures[key][kind]
    if type(scan) ~= "table" or type(scan.rows) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(scan.rows) do n = n + 1 end
    return n
end

--- 12-hour clock, "6:18 AM". Nil when this character has no capture yet.
function Hv:LastScannedLabel()
    local s = self:Store()
    local key = self:CharacterKey()
    local entry = s and key and s.captures and s.captures[key]
    if type(entry) ~= "table" or type(date) ~= "function" then return "Not scanned yet" end
    local best
    for _, scan in pairs(entry) do
        if type(scan) == "table" and type(scan.timestamp) == "number" then
            if not best or scan.timestamp > best then best = scan.timestamp end
        end
    end
    if not best then return "Not scanned yet" end
    local ok, formatted = pcall(date, "%I:%M %p", best)
    if not ok or type(formatted) ~= "string" or formatted == "" then return "Not scanned yet" end
    return "Last scanned " .. (formatted:gsub("^0", ""))
end

--- Skill lines the client reports. The pack reads them (Forever's skill
--- API is not a shared assumption). The character's previous entry is replaced.
function Hv:ScanSkills()
    local pack = self._pack
    local rows = {}
    if pack and type(pack.scanSkills) == "function" then
        local got = pack.scanSkills()
        if type(got) == "table" then rows = got end
    end
    self:SaveCapture("skills", { rows = rows })
    return self:CaptureCount("skills")
end

--- Professions from GetProfessions, plus the open trade-skill list when the
--- client has one. Replaces this character's professions entry.
function Hv:ScanProfessions()
    local rows = {}
    local a, b, c, d, e, f = self.Try("GetProfessions")
    local slots = { a, b, c, d, e, f }
    for i = 1, 6 do
        local idx = tonumber(slots[i])
        if idx then
            local name, _, rank, maxRank, _, _, skillLine = self.Try("GetProfessionInfo", idx)
            if type(name) == "string" and name ~= "" and name ~= "secret" then
                rows[tostring(skillLine or idx)] = concat({
                    self.Clean(name), self.Clean(rank), self.Clean(maxRank), self.Clean(skillLine),
                }, "\t")
            end
        end
    end
    local listed = tonumber((self.Try("GetNumTradeSkills")))
    if listed and listed > 0 then
        local title = self.Try("GetTradeSkillLine")
        if type(title) == "string" and title ~= "" and title ~= "secret" then
            rows.trade = concat({ self.Clean(title), self.Clean(listed) }, "\t")
        end
    end
    self:SaveCapture("professions", { rows = rows })
    return self:CaptureCount("professions")
end

--- Heirlooms, when that module is loaded. Forever does not ship it until
--- heirlooms are confirmed, so the capture records that instead of a guess.
function Hv:ScanHeirlooms()
    local rows = {}
    local note = "not on this client"
    local mod = TA.GetModule and TA:GetModule("Heirlooms")
    if mod and type(mod.HarvestRows) == "function" then
        local list, why = mod:HarvestRows()
        if type(list) == "table" then
            note = nil
            for i, line in ipairs(list) do
                if type(line) == "string" and line ~= "" then rows[tostring(i)] = line end
            end
        elseif type(why) == "string" and why ~= "" then
            note = why
        end
    end
    self:SaveCapture("heirlooms", { rows = rows, note = note })
    return note, self:CaptureCount("heirlooms")
end

--- Scan now: probe, spellbook, catalog, skills, talents, professions,
--- heirlooms. Each step replaces that character's previous entry. One step
--- per frame. In combat the scan waits for PLAYER_REGEN_ENABLED.
function Hv:StartScan()
    if self._scanRunning then
        self._scanQueued = true
        return
    end
    if self:InCombat() then
        self._scanQueued = true
        self:Toast("Harvest: scan queued until combat ends")
        return
    end
    self._scanQueued = false
    local steps = {}
    steps[#steps + 1] = { run = function()
        local lines = self:BuildProbeLines()
        self:SaveCapture("probe", { text = concat(lines, "\n") })
    end }
    steps[#steps + 1] = { run = function()
        local d = self:Domain("spellbook")
        if d and d.ScanSpellbook then d:ScanSpellbook() end
    end }
    steps[#steps + 1] = { async = true, run = function(done)
        self:ScanCatalog(done)
    end }
    steps[#steps + 1] = { run = function() self:ScanSkills() end }
    steps[#steps + 1] = { run = function()
        local d = self:Domain("traitTree") or self:Domain("talentTrees")
        if d and d.ScanTraitTree then d:ScanTraitTree()
        elseif d and d.ScanTalents then d:ScanTalents() end
    end }
    steps[#steps + 1] = { run = function() self:ScanProfessions() end }
    steps[#steps + 1] = { run = function() self:ScanHeirlooms() end }
    self._scanQueue = steps
    self._scanStep = 1
    self._scanRunning = true
    Hv.After(0, function() self:RunScanStep() end)
end

function Hv:RunScanStep()
    if not self._scanRunning then return end
    if self:InCombat() then
        self._scanRunning = false
        self._scanQueued = true
        self._quiet = false
        self:Toast("Harvest: scan queued until combat ends")
        return
    end
    local step = self._scanQueue and self._scanQueue[self._scanStep]
    if not step then
        self._scanRunning = false
        self._quiet = false
        local id = self:CharacterIdentity()
        self:Toast("Harvest: scan saved (" .. ((id and id.name) or "this character") .. ")")
        if TA.Layout and TA.Layout.RefreshUI then TA.Layout:RefreshUI() end
        if self._scanQueued and not self:InCombat() then self:StartScan() end
        return
    end
    self._scanStep = self._scanStep + 1
    local function Next()
        self._quiet = false
        Hv.After(0, function() self:RunScanStep() end)
    end
    self._quiet = true
    if step.async then
        local ok = pcall(step.run, Next)
        if not ok then Next() end
    else
        pcall(step.run)
        Next()
    end
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

--- The player's class token and localized display name, or nil when the
--- client has not answered. The formatter never calls this; exports pass the
--- result in so the saved-file path can omit it.
function Hv:PlayerClass()
    if type(UnitClass) ~= "function" then return nil, nil end
    local ok, display, token = pcall(UnitClass, "player")
    if not ok or type(token) ~= "string" or token == "" then return nil, nil end
    if type(display) ~= "string" or display == "" then
        local F = TA.HarvestFormat
        display = (F and F.ClassName) and F.ClassName(token) or token
    end
    return token, display
end

--- Who is logged in, plus the client build this scan is taken on.
--- Name or class nil means the client has not answered; CharacterKey then
--- refuses to write, so a scan is never filed under a blank identity.
function Hv:CharacterIdentity()
    local name = Hv.Try("UnitName", "player")
    if type(name) ~= "string" or name == "" or name == "secret" or name == "?" then
        name = nil
    else
        name = Hv.Clean(name)
    end
    local realm = Hv.Try("GetRealmName")
    if type(realm) ~= "string" or realm == "" or realm == "?" then
        realm = ""
    else
        realm = Hv.Clean(realm)
    end
    -- The same answer the tab's class filter uses. Caps caches the first
    -- function it resolved, so a later UnitClass would otherwise disagree
    -- with PlayerClass and a new character would still export the old one.
    local token, display = self:PlayerClass()
    if token then token = Hv.Clean(token) end
    if display then display = Hv.Clean(display) end
    local level = tonumber((Hv.Try("UnitLevel", "player")))
    local version, build = Hv.Try("GetBuildInfo")
    if type(version) ~= "string" or version == "" then version = nil end
    if build == nil or build == "" then
        build = nil
    else
        build = tostring(build)
    end
    local timestamp = Now()
    local when
    if type(date) == "function" and type(timestamp) == "number" then
        local ok, formatted = pcall(date, "%Y-%m-%d %H:%M", timestamp)
        if ok and type(formatted) == "string" and formatted ~= "" then when = formatted end
    end
    return {
        realm = realm, name = name, class = token, className = display,
        level = level, version = version, build = build,
        timestamp = timestamp, when = when,
    }
end

--- realm, character name, class token. Nil until both name and class exist.
function Hv:CharacterKey(id)
    id = id or self:CharacterIdentity()
    if type(id) ~= "table" then return nil end
    if type(id.name) ~= "string" or id.name == "" then return nil end
    if type(id.class) ~= "string" or id.class == "" then return nil end
    return (id.realm or "") .. "\t" .. id.name .. "\t" .. id.class
end

--- Replace this character's saved scan of `kind` (probe, trainer, spellbook,
--- talents). Other characters, and this character's other scan types, stay.
--- Version, build, timestamp, when, level and class always come from this
--- run, so a caller cannot leave a stale stamp in place.
function Hv:SaveCapture(kind, body)
    if type(kind) ~= "string" or kind == "" then return nil end
    local s = self:Store()
    if not s then return nil end
    s.captures = s.captures or {}
    local id = self:CharacterIdentity()
    local key = self:CharacterKey(id)
    if not key then return nil end
    local entry = s.captures[key]
    if type(entry) ~= "table" then entry = {} end
    entry.realm = id.realm
    entry.name = id.name
    entry.class = id.class
    entry.className = id.className
    local scan = {
        version = id.version, build = id.build, timestamp = id.timestamp,
        when = id.when, level = id.level, class = id.class,
    }
    if type(body) == "table" then
        for k, v in pairs(body) do
            if k == "rows" and type(v) == "table" then
                local copy = {}
                for rk, rv in pairs(v) do copy[rk] = rv end
                scan.rows = copy
            elseif k ~= "version" and k ~= "build" and k ~= "timestamp"
                and k ~= "when" and k ~= "level" and k ~= "class" then
                scan[k] = v
            end
        end
    end
    entry[kind] = scan
    s.captures[key] = entry
    return key
end

--- Drop one character's captures. Nil key means the current character.
--- The shared class catalog and every other character stay.
function Hv:ClearCharacter(key)
    local s = self:Store()
    if not s then return false end
    s.captures = s.captures or {}
    if key == nil or key == "" then key = self:CharacterKey() end
    if not key then return false end
    s.captures[key] = nil
    return true
end

--- Copy window for one scan type. scope "all" is every character who has
--- that scan; anything else is the current character (an empty sentence
--- when they have not been recorded yet).
function Hv:ExportCapture(kind, scope, page)
    local s = self:Store()
    local F = TA.HarvestFormat
    if not (s and F and F.CaptureLines) then return nil end
    s.captures = s.captures or {}
    local id = self:CharacterIdentity()
    local key = (scope == "all") and "all" or self:CharacterKey(id)
    local lines, p, pages = F.CaptureLines(s.captures, kind, key, id, page or 1)
    if not lines then return nil end
    if TA.ShowCopyWindow then
        TA:ShowCopyWindow(("ToonAge harvest — %s (%d/%d)"):format(tostring(kind), p, pages),
                          concat(lines, "\n"))
    end
    return p, pages
end

--- Stamp for an export. scope "class" limits a per-class section to the
--- current character; anything else exports every class. The current
--- character's display name is filled whenever the client answered.
function Hv:StampMeta(scope)
    local meta = self:Meta()
    local token, display = self:PlayerClass()
    if display then meta.currentClass = display end
    if scope == "class" and token then meta.class = token end
    return meta
end

--- One page of a section, stamped. page 0 = every record. scope "class"
--- keeps only the current character's class (a class with no rows exports
--- the empty sentence, not another class). A section this store has not
--- written yet exports as a stamped header with 0 records, so its Copy
--- button always opens a window.
function Hv:ExportLines(section, page, scope)
    local s = self:Store()
    local F = TA.HarvestFormat
    if not (s and F) then return nil end
    local view = s
    if type(s[section]) ~= "table" then
        view = {}
        for k, v in pairs(s) do view[k] = v end
        view[section] = {}
    end
    return F.Lines(view, section, page or 1, self:StampMeta(scope))
end

--- Opens one page of a section in the copy window. Returns page, pages.
function Hv:Export(section, page, scope)
    local out, p, pages = self:ExportLines(section, page, scope)
    if not out then return nil end
    if TA.ShowCopyWindow then
        TA:ShowCopyWindow(("ToonAge harvest — %s (%d/%d)"):format(tostring(section), p, pages),
                          concat(out, "\n"))
    end
    return p, pages
end

-- The Copy row: { section, label } in registration order. The core registers
-- the enabled domains' export entries in the pack's order at Init, so each
-- client shows exactly what it records.
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

--- Muted label when this section's saved rows are another class and the
--- current character has none. Nil when the shown rows are theirs, or when
--- the client has not said which class they are.
function Hv:ForeignNote(section, store)
    local F = TA.HarvestFormat
    if not (F and F.ClassesIn and F.Scoped and F.Rows and F.SavedLabel) then return nil end
    local token = self:PlayerClass()
    if not token then return nil end
    if #F.Rows(F.Scoped(store, section, token)) > 0 then return nil end
    local others = {}
    for _, cls in ipairs(F.ClassesIn(store, section)) do
        if cls ~= token then others[#others + 1] = cls end
    end
    if #others == 0 then return nil end
    return F.SavedLabel(others)
end

--- True when the store has at least one record in the section.
function Hv:Has(section)
    local s = self:Store()
    return s ~= nil and type(s[section]) == "table" and next(s[section]) ~= nil
end

-- ── Domains and packs (T4, spec section 4.4) ─────────────────────────────
--
-- A domain is a table registered by its file:
--   id        unique name ("items", "trainer", ...)
--   needs     dotted API paths that must all be present (Caps.State) for the
--             domain to run; a domain with a missing need is skipped and the
--             Full report says which path was missing -- never an error
--   events    event names it handles; the core registers them through
--             TA:RegisterEvent and routes each one back to OnEvent
--   OnEvent(self, event, ...), OnEnterWorld(self), Migrate(self, store)
--   rescan    { { label, methodName }, ... } -- the Full report's Rescan rows
--   probes    { name = { title =, run = function(P, L) } } -- probe sections
--   export    { { section =, label = }, ... } -- Copy-row buttons
--   summary   { { section =, label =, value = fn(s)?, note = fn(s)? }, ... }
-- A pack (one per client, Hv:RegisterPack) names the domains this client runs
-- and the order of the Copy row, the summary rows, the probe sections and the
-- report; plus catalogRanges, its own probes, tab rows and one-time repairs.

Hv._domains = Hv._domains or {}

function Hv:RegisterDomain(d)
    if type(d) == "table" and type(d.id) == "string" then self._domains[d.id] = d end
    return d
end

function Hv:RegisterPack(p)
    if type(p) == "table" then self._pack = p end
    return p
end

function Hv:Pack()
    return self._pack
end

--- The domain if it is running on this client (in the pack, registered, and
--- every need present); nil otherwise.
function Hv:Domain(id)
    return self._active and self._active[id] or nil
end

--- Resolves the pack's domains: running ones in pack order, skipped ones with
--- the first missing path. Called by Init; safe to call again.
function Hv:Activate()
    local pack = self._pack
    local Caps = TA.Caps
    self._order, self._active, self._skipped = {}, {}, {}
    if not (pack and Caps) then return end
    for _, id in ipairs(pack.domains or {}) do
        local d = self._domains[id]
        if not d then
            self._skipped[#self._skipped + 1] = { id = id, why = "domain file not loaded" }
        else
            local missing
            for _, path in ipairs(d.needs or {}) do
                if Caps.State(path) ~= "present" then missing = path break end
            end
            if missing then
                self._skipped[#self._skipped + 1] = { id = id, why = "missing " .. missing }
            else
                self._order[#self._order + 1] = d
                self._active[id] = d
            end
        end
    end
end

--- Running domains, in pack order.
function Hv:ActiveDomains()
    return self._order or {}
end

-- High-frequency events reach a module only when that module's own file names
-- them: Tools/gen_event_routes.py builds Core/Init.lua's EVENT_ROUTES by
-- scanning each file that calls RegisterModule. The domains declare their
-- events, but they are not modules, so the core names the routed ones it
-- forwards here. Tools/test_harvest_packs.py fails if a domain uses a routed
-- event that is missing from this list.
local ROUTED_EVENTS = { "BAG_UPDATE_DELAYED" }
Hv.ROUTED_EVENTS = ROUTED_EVENTS

-- ── Spell catalog engine ─────────────────────────────────────────────────
--
-- The spellbook lists only spells you know (measured 2026-09-29: a level-1
-- Priest shows Smite and Lesser Heal, nothing else). But C_Spell answers for
-- ANY spell ID, known or not -- the probes read Fireball's rank text, trained
-- level and cost on a Warrior. So every trainable rank of every spell can be
-- read by walking spell IDs, with no leveling.
--
-- Kept: IDs whose rank text is "Rank N" AND whose trained level is > 0. That
-- is the client's own definition of a trainable ranked spell; NPC copies of a
-- spell ("Fireball" cast by a mob) report no trained level and drop out.
--
-- The ID ranges are client config (pack.catalogRanges). Each frame spends at
-- most FRAME_BUDGET_MS so the game never stutters; the whole walk takes a few
-- seconds. Class is NOT known per spell -- the Spells tab matches by name
-- against your own spellbook, which is always right for your class.
--   catalog["spellID"] = name, rank text, trained level
--
-- ADDITIVE (T4, approved 2026-10-04). A scan writes new and changed ranks and
-- never removes one. Rank text loads per session: a Mage session read the
-- Warrior's and Priest's ranks blank, and the old scan -- which started from
-- an empty catalog -- dropped 8 stored ranks (2026-10-04 17:23, 85 -> 77).
-- Whatever this pass reads blank is still dropped from the PASS (the blanks
-- are mostly NPC copies; keeping them cost ~400 KB of saved file), but a rank
-- already in the store stays.

local FRAME_BUDGET_MS = 8
local RANK_PASSES     = 3    -- extra passes over spells whose rank text was blank
local RANK_PASS_DELAY = 3    -- seconds between passes, for the client to load them

function Hv:ScanCatalog(onDone)
    local s = self:Store()
    local pack = self._pack
    local ranges = pack and pack.catalogRanges
    if not (s and ranges) or self._catalogRunning then
        if onDone then onDone(0, 0, 0, 0) end
        return
    end
    local Caps = TA.Caps
    local getName    = Caps and Caps.Fn("C_Spell.GetSpellName")
    local getLearned = Caps and Caps.Fn("C_Spell.GetSpellLevelLearned")
    if not (getName and getLearned) then
        if TA.Raw and not self._quiet then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r Spell catalog: C_Spell.GetSpellName / "
                .. "GetSpellLevelLearned are missing on this client.")
        end
        if onDone then onDone(0, 0, 0, 0) end
        return
    end
    local getSub      = Caps.Fn("C_Spell.GetSpellSubtext")
    local requestLoad = Caps.Fn("C_Spell.RequestLoadSpellData")
    local clock = Caps.Fn("debugprofilestop")
    if not clock then
        local getTime = Caps.Fn("GetTime")
        clock = function() return (getTime and getTime() or 0) * 1000 end
    end

    -- This pass's reads. The store's catalog is not touched until Finish, so
    -- the Spells tab keeps reading the full catalog while the walk runs.
    local fresh = {}
    s.catalogPasses = {}
    self._catalogRunning = true
    local Clean = Hv.Clean
    local range, id, found = 1, ranges[1][1], 0
    local blanks = {}
    local RetryBlanks, Finish

    local function Step()
        local t0 = clock()
        while range <= #ranges do
            local last = ranges[range][2]
            while id <= last do
                local okN, name = pcall(getName, id)
                if okN and type(name) == "string" and name ~= "" then
                    local okL, learned = pcall(getLearned, id)
                    if okL and type(learned) == "number" and learned > 0 then
                        local rank = getSub and select(2, pcall(getSub, id)) or ""
                        if type(rank) ~= "string" then rank = "" end
                        if rank == "" or rank:find("^Rank %d+$") then
                            fresh[tostring(id)] = concat(
                                { Clean(name), Clean(rank), Clean(learned) }, "\t")
                            found = found + 1
                            if rank == "" then
                                blanks[#blanks + 1] = id
                                if requestLoad then pcall(requestLoad, id) end
                            end
                        end
                    end
                end
                id = id + 1
                if (id % 500) == 0 and clock() - t0 > FRAME_BUDGET_MS then
                    Hv.After(0, Step)
                    return
                end
            end
            range = range + 1
            id = ranges[range] and ranges[range][1]
        end
        -- Pass 2+. Rank text loads asynchronously: the first scan of
        -- 2026-09-29 stored 9891 spells and only 77 had "Rank N" -- Fireball
        -- 8400 read "Rank 5" but 10148 (its rank 8) read "". Asking once
        -- starts the load, so blanks are asked again after a pause, up to
        -- RANK_PASSES times, stopping early when a pass resolves nothing.
        RetryBlanks(1)
    end

    function RetryBlanks(pass)
        if #blanks == 0 or pass > RANK_PASSES or not getSub then return Finish() end
        Hv.After(RANK_PASS_DELAY, function()
            local i, still, resolved = 1, {}, 0
            local function Chunk()
                local t0 = clock()
                while i <= #blanks do
                    local bid = blanks[i]
                    local okR, rank = pcall(getSub, bid)
                    if okR and type(rank) == "string" and rank:find("^Rank %d+$") then
                        local line = fresh[tostring(bid)]
                        if line then
                            local nm, _, lv = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
                            fresh[tostring(bid)] = concat({ nm, rank, lv }, "\t")
                        end
                        resolved = resolved + 1
                    else
                        still[#still + 1] = bid
                    end
                    i = i + 1
                    if (i % 500) == 0 and clock() - t0 > FRAME_BUDGET_MS then
                        Hv.After(0, Chunk)
                        return
                    end
                end
                blanks = still
                -- Pass results go to the store (shown in the Full report), not
                -- to chat: chat gets the start line and the final count only.
                s.catalogPasses = s.catalogPasses or {}
                s.catalogPasses[#s.catalogPasses + 1] = ("pass %d: +%d ranks, %d still blank")
                    :format(pass + 1, resolved, #blanks)
                if resolved == 0 then return Finish() end
                RetryBlanks(pass + 1)
            end
            Chunk()
        end)
    end

    function Finish()
        self._catalogRunning = false
        s.catalogBuild = select(2, Hv.Try("GetBuildInfo"))
        -- Merge: every stored rank stays; this pass adds new ranks and
        -- rewrites changed ones. Blanks from this pass are not kept.
        local merged, ranked, added, changed = {}, 0, 0, 0
        for k, line in pairs(s.catalog or {}) do merged[k] = line end
        for k, line in pairs(fresh) do
            if line:find("\tRank %d+\t") then
                ranked = ranked + 1
                local old = merged[k]
                if old == nil then added = added + 1 elseif old ~= line then changed = changed + 1 end
                merged[k] = line
            end
        end
        -- A new table, so a reader caching on the old one (the Spells tab's
        -- CatalogByName) rebuilds.
        s.catalog = merged
        self:AdoptSection("catalog", merged)
        if added + changed > 0 then self:Touch("catalog") end
        -- This character's catalog entry is this pass only. The shared
        -- catalog above stays additive so a blank session cannot drop ranks
        -- another character already stored.
        local mine = {}
        for k, line in pairs(fresh) do
            if type(line) == "string" and line:find("\tRank %d+\t") then mine[k] = line end
        end
        self:SaveCapture("catalog", { rows = mine })
        if TA.Raw and not self._quiet then
            TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Spell catalog: %d spells, %d with rank text this pass. "
                .. "Catalog holds %d (+%d new, %d changed, none removed)."):format(
                found, ranked, Size(merged), added, changed))
        end
        if TA.Layout and TA.Layout.RefreshUI then TA.Layout:RefreshUI() end
        if onDone then onDone(found, ranked, added, changed) end
    end
    if TA.Raw and not self._quiet then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Spell catalog: scanning spell IDs (a few seconds)...")
    end
    Hv.After(0, Step)
end

-- ── Probe primitives ─────────────────────────────────────────────────────
-- Probes answer the questions a client brief still has open, in one click,
-- in the copyable window -- never chat. Every call is guarded: a missing
-- function prints "missing", an error prints the error, a secret prints
-- "secret".

local P = {}
Hv.Probe = P

function P.Show(v, depth)
    depth = depth or 0
    if v == nil then return "nil" end
    if Hv.IsSecret(v) then return "secret" end
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" then return tostring(v) end
    if depth >= 2 then return "{...}" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = tostring(k) .. "=" .. P.Show(v[k], depth + 1)
        if #out >= 40 then out[#out + 1] = "..." break end
    end
    return "{ " .. concat(out, ", ") .. " }"
end

--- One probe line: label -> every return value. `fn` is a dotted API path
--- (resolved through Caps) or a function.
function P.Call(lines, label, fn, ...)
    if type(fn) == "string" then
        local Caps = TA.Caps
        fn = Caps and Caps.Fn(fn) or nil
    end
    if type(fn) ~= "function" then
        lines[#lines + 1] = label .. "  ->  missing"
        return
    end
    local res = { pcall(fn, ...) }
    if not res[1] then
        lines[#lines + 1] = label .. "  ->  error: " .. tostring(res[2])
        return
    end
    local parts = {}
    for i = 2, math.max(#res, 2) do parts[#parts + 1] = P.Show(res[i]) end
    lines[#lines + 1] = label .. "  ->  " .. concat(parts, ", ")
end

--- "label -> true/false": whether a path is present on this client.
function P.Present(lines, label, path)
    local Caps = TA.Caps
    P.Call(lines, label, function() return Caps ~= nil and Caps.State(path) == "present" end)
end

--- The probe sections every client has. Packs order them (pack.probeOrder)
--- together with the domains' and their own.
local CORE_PROBES = {
    client = { title = "Client", run = function(P, L)
        P.Call(L, "GetBuildInfo()", "GetBuildInfo")
        local Caps = TA.Caps
        L[#L + 1] = "WOW_PROJECT_ID  ->  " .. P.Show(Caps and (Caps.Get("WOW_PROJECT_ID")) or nil)
        P.Call(L, "UnitClass(player)", "UnitClass", "player")
        P.Call(L, "UnitLevel(player)", "UnitLevel", "player")
    end },

    sheet = { title = "Character sheet", run = function(P, L)
        P.Call(L, "UnitAttackBothHands(player) [weapon skill]", "UnitAttackBothHands", "player")
        P.Call(L, "UnitRangedAttack(player)", "UnitRangedAttack", "player")
        P.Call(L, "UnitDefense(player)", "UnitDefense", "player")
        for school = 2, 7 do
            P.Call(L, "GetSpellBonusDamage(" .. school .. ")", "GetSpellBonusDamage", school)
        end
        P.Call(L, "GetSpellBonusHealing()", "GetSpellBonusHealing")
        P.Call(L, "GetManaRegen()", "GetManaRegen")
        -- Forever folds Hit into one stat and adds Expertise (Forever/Character.lua
        -- note). Record what each of the classic stat getters answers here.
        P.Call(L, "GetHitModifier()", "GetHitModifier")
        P.Call(L, "GetSpellHitModifier()", "GetSpellHitModifier")
        P.Call(L, "GetExpertise()", "GetExpertise")
        P.Call(L, "GetCritChance()", "GetCritChance")
        P.Call(L, "GetDodgeChance()", "GetDodgeChance")
        P.Call(L, "GetParryChance()", "GetParryChance")
        P.Call(L, "GetBlockChance()", "GetBlockChance")
        P.Call(L, "UnitAttackSpeed(player)", "UnitAttackSpeed", "player")
        P.Call(L, "UnitDamage(player)", "UnitDamage", "player")
    end },

    combat = { title = "Combat", run = function(P, L)
        local Caps = TA.Caps
        L[#L + 1] = "C_AssistedCombat  ->  " .. ((Caps and Caps.State("C_AssistedCombat") == "present") and "present" or "missing")
        P.Call(L, "C_AssistedCombat.GetNextCastSpell()", "C_AssistedCombat.GetNextCastSpell")
        local rec = TA.GetModule and TA:GetModule("CombatRecorder")
        L[#L + 1] = "CombatRecorder  ->  " .. (rec and "running" or "not running")
        if rec and rec.HasOutput then L[#L + 1] = "  combat log readable  ->  " .. tostring(rec:HasOutput()) end
        local store = TA.charDB and TA.charDB.combatLog
        if store then
            local casts = 0
            for _, row in pairs(store.spells or {}) do casts = casts + (row.casts or 0) end
            L[#L + 1] = ("  fights %d, casts recorded %d"):format(store.fights or 0, casts)
        end
    end },

    map = { title = "Map", run = function(P, L)
        P.Call(L, "C_Map.GetBestMapForUnit(player)", "C_Map.GetBestMapForUnit", "player")
    end },

    -- One line per profession skill line the running client can read:
    -- id, name, rank, max rank, header. ProfessionSkills picks the reader
    -- from the data file's prefer list and the calls that exist.
    professionLines = { title = "Professions", run = function(P, L)
        local PS = TA.ProfessionSkills
        if not PS or not PS.ProbeLines then
            L[#L + 1] = "profession reader not loaded"
            return
        end
        local ok, lines = pcall(PS.ProbeLines)
        if not ok then
            L[#L + 1] = "error: " .. tostring(lines)
            return
        end
        for _, line in ipairs(lines or {}) do
            L[#L + 1] = line
        end
    end },
}
Hv.CORE_PROBES = CORE_PROBES

local function FindProbe(name)
    local pack = Hv._pack
    if pack and pack.probes and pack.probes[name] then return pack.probes[name] end
    for _, d in ipairs(Hv:ActiveDomains()) do
        if d.probes and d.probes[name] then return d.probes[name] end
    end
    return CORE_PROBES[name]
end

--- Every probe section, as lines, in the pack's order.
function Hv:BuildProbeLines()
    local L = {}
    local pack = self._pack
    local order = (pack and pack.probeOrder) or { "client", "sheet", "combat", "map" }
    for _, name in ipairs(order) do
        local pr = FindProbe(name)
        if pr then
            L[#L + 1] = ""
            L[#L + 1] = "== " .. pr.title .. " =="
            pr.run(P, L)
        end
    end
    if L[1] == "" then table.remove(L, 1) end
    return L
end

-- ══════════════════════════════════════════════════════════════════════════
-- ── The module ────────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- SILENT. No frames, no timers you can feel, no chat spam. If you notice the
-- recorder while playing, it is doing something wrong. Chat is used only to
-- answer a button the player just clicked.

local H = {}
TA:RegisterModule("DataHarvester", H)
Hv.module = H

-- Each running domain handles a call in pack order. One failing domain does
-- not stop the others; the first error is re-raised afterwards so the module
-- dispatcher still logs it (/ta errors).
local function RunEach(list, method, ...)
    local firstErr
    for _, d in ipairs(list) do
        local fn = d[method]
        if fn then
            local ok, err = pcall(fn, d, ...)
            if not ok and not firstErr then firstErr = d.id .. ": " .. tostring(err) end
        end
    end
    if firstErr then error(firstErr, 0) end
end

function H:View()
    if self._view == "all" then return "all" end
    return "character"
end

function H:OnEvent(event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        if Hv._scanQueued then Hv:StartScan() end
        return
    end
    if event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_LIST_UPDATE" then
        Hv:Request("professions", function()
            local n = Hv:ScanProfessions()
            Hv:Toast(("Harvest: professions saved (%d profession%s)"):format(n, n == 1 and "" or "s"))
        end)
    end
    local route = Hv._routes and Hv._routes[event]
    if route then RunEach(route, "OnEvent", event, ...) end
    if event == "PLAYER_LEVEL_UP" then
        Hv:Request("full", function() Hv:StartScan() end)
    end
end

function H:OnEnterWorld()
    RunEach(Hv:ActiveDomains(), "OnEnterWorld")
    Hv:Request("full", function() Hv:StartScan() end)
end

-- ── Run all ───────────────────────────────────────────────────────────────
--
-- One click: rescan everything this character can show right now, run every
-- probe, and put the probes plus every harvested record into ONE copy window.
-- The scans normally run on their own (login, level-up, bags, loot, spells,
-- talents); forcing them first means the report is current even if an event
-- was missed. Each scan is pcall'd so one failing read cannot stop the rest --
-- the report says which one failed.

function Hv:RunAll()
    local s = self:Store()
    if not s then
        if TA.Raw then TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r Harvest store not available yet.") end
        return
    end
    local pack = self._pack or {}
    local sections = pack.reportSections or {}

    local before = {}
    for _, k in ipairs(sections) do before[k] = Size(s[k] or {}) end

    -- The same stamp every export carries (client, build, interface, project,
    -- channel, source, harvest range, report time, versions). The full report
    -- is every record, so its source is "all".
    local meta = self:StampMeta("all")
    local F = TA.HarvestFormat
    if F and F.RecordedBy then meta.recordedBy = F.RecordedBy(s, "all") end
    meta.source = "all"
    local stamp = F and F.Header(meta, "full report", 0, 1, 0, 0, 0) or {}
    local out = {
        pack.reportTitle or "ToonAge -- full report",
        stamp[2] or "",
        stamp[3] or "",
        stamp[4] or "",
        "",
        "== Rescan ==",
    }
    for _, d in ipairs(self:ActiveDomains()) do
        for _, sc in ipairs(d.rescan or {}) do
            local fn = d[sc[2]]
            local ok, err = true, nil
            if fn then ok, err = pcall(fn, d) end
            out[#out + 1] = ("%-11s %s"):format(sc[1],
                not fn and "not available"
                or ok and "ok" or ("FAILED: " .. tostring(err)))
        end
    end
    for _, sk in ipairs(self._skipped or {}) do
        out[#out + 1] = ("%-11s skipped: %s"):format(sk.id, sk.why)
    end
    if pack.catalogRanges then
        local ranked = 0
        for _, line in pairs(s.catalog or {}) do
            if tostring(line):find("\tRank %d+\t") then ranked = ranked + 1 end
        end
        out[#out + 1] = ("%-11s %d spells, %d with rank text%s"):format("catalog", Size(s.catalog or {}), ranked,
            next(s.catalog or {}) and "" or " (not scanned yet: Harvest -> Run catalog scan)")
        for _, p in ipairs(s.catalogPasses or {}) do out[#out + 1] = "            " .. p end
    end
    for _, k in ipairs(sections) do
        local now = Size(s[k] or {})
        out[#out + 1] = ("%-11s %d records (%s)"):format(k, now,
            now > before[k] and ("+" .. (now - before[k]) .. " new") or "no new")
    end

    out[#out + 1] = ""
    out[#out + 1] = "== Probes =="
    local okP, probe = pcall(self.BuildProbeLines, self)
    if okP and type(probe) == "table" then
        self:SaveCapture("probe", { text = concat(probe, "\n") })
        for _, l in ipairs(probe) do out[#out + 1] = l end
    else
        out[#out + 1] = "probes FAILED: " .. tostring(probe)
    end

    for _, k in ipairs(sections) do
        out[#out + 1] = ""
        out[#out + 1] = "== Harvest: " .. k .. " =="
        local lines = self:ExportLines(k, 0, "all")
        for _, l in ipairs(lines or { "(unavailable)" }) do out[#out + 1] = l end
    end

    if TA.ShowCopyWindow then TA:ShowCopyWindow("ToonAge -- full report", concat(out, "\n")) end
    local L = TA.Layout
    if L and L.RefreshUI then L:RefreshUI() end
end

function Hv:RunProbes()
    local lines = self:BuildProbeLines()
    self:SaveCapture("probe", { text = concat(lines, "\n") })
    if self:ExportCapture("probe", "character", 0) then return end
    if TA.ShowCopyWindow then
        TA:ShowCopyWindow("ToonAge client probes", concat(lines, "\n"))
    end
end

-- Module-level names the tab, slash commands and older callers use.
function H:RunAll() return Hv:RunAll() end
function H:RunProbes() return Hv:RunProbes() end
function H:BuildProbeLines() return Hv:BuildProbeLines() end
function H:ScanCatalog(onDone) return Hv:ScanCatalog(onDone) end

--- One page of a section as lines. page = 0 means every record, one block.
function H:ExportLines(section, page, scope)
    return Hv:ExportLines(section or "items", page, scope)
end

-- Catalog still copies one class. Spells, talents and trainer copy the
-- current character's latest capture; "all" is every character.
local CLASS_EXPORT = { spells = true, talents = true, trainer = true, catalog = true }
local CAPTURE_KIND = { spells = "spellbook", talents = "talents", trainer = "trainer" }
local ALL_LABEL = { catalog = "All catalog classes" }

function H:Export(section, page, scope)
    section = section or "items"
    local kind = CAPTURE_KIND[section]
    if kind and scope ~= "legacy" then
        if scope == nil or scope == "class" or scope == "character" then scope = "character" end
        local p, pages = Hv:ExportCapture(kind, scope, page)
        if not p then return end
        self._page, self._pages, self._section, self._scope = p, pages, section, scope
        return
    end
    if scope == nil and CLASS_EXPORT[section] then scope = "class" end
    local p, pages = Hv:Export(section, page, scope)
    if not p then return end
    self._page, self._pages, self._section, self._scope = p, pages, section, scope
end

H.SlashCommands = H.SlashCommands or {}
H.SlashCommands.probe   = function(self) self:RunProbes() end
H.SlashCommands.catalog = function(self) self:ScanCatalog() end
H.SlashCommands.report  = function(self) self:RunAll() end

-- ── Tab ───────────────────────────────────────────────────────────────────

local function SummaryEntry(section)
    if section == "catalog" then
        return { section = "catalog", label = "Spell catalog (every trainable rank)",
                 value = function(s)
                     return Hv._catalogRunning and "scanning..." or tostring(Size(s.catalog or {}))
                 end }
    end
    for _, d in ipairs(Hv:ActiveDomains()) do
        for _, e in ipairs(d.summary or {}) do
            if e.section == section then return e end
        end
    end
    return nil
end

function H:Render(content, side)
    local L = TA.Layout
    if not L then return end
    local s = Hv:Store()
    local pack = Hv._pack or {}
    local y = -14
    local view = self:View()

    y = L:ButtonRow(content, y, {
        { label = "This character", active = view ~= "all",
          onClick = function()
              H._view = "character"
              if L.RefreshUI then L:RefreshUI() end
          end },
        { label = "All characters", active = view == "all",
          onClick = function()
              H._view = "all"
              if L.RefreshUI then L:RefreshUI() end
          end },
    }, { label = "This character · All characters" })
    y = L:ButtonRow(content, y, {
        { label = Hv._scanRunning and "Scanning..." or "Scan now", gold = true,
          tooltip = { "Scan now", "Probe, spellbook, catalog, skills, talents, professions and heirlooms for this character. Spread across frames. Waits until you leave combat." },
          onClick = function() Hv:StartScan() end },
        { label = Hv:NoticesOn() and "Notices on" or "Notices off",
          tooltip = { "Harvest notices", "One line when a capture is saved, such as Harvest: trainer saved (Solm Hargrin, 12 spells)." },
          onClick = function()
              TA.db = TA.db or {}
              if TA.db.harvestToast == false then TA.db.harvestToast = nil
              else TA.db.harvestToast = false end
              if L.RefreshUI then L:RefreshUI() end
          end },
    }, { note = Hv:LastScannedLabel() })

    y = L:SectionHeader(content, y, "Harvested so far",
        "Everything below is what the client said, recorded verbatim. Nothing "
        .. "here is interpreted, weighted or ranked.")

    if not s then
        y = L:Paragraph(content, y, "|cFFFF4444The database is not available yet.|r")
        L:Finish(content, y)
        return
    end

    for _, section in ipairs(pack.summaryOrder or {}) do
        local e = SummaryEntry(section)
        if e and (section ~= "catalog" or pack.catalogRanges) then
            local value
            if e.value then
                value = e.value(s)
            else
                local Fmt = TA.HarvestFormat
                local token = Hv:PlayerClass()
                if token and Fmt and Fmt.CLASS_SECTIONS and Fmt.CLASS_SECTIONS[section] then
                    local n = #Fmt.Rows(Fmt.Scoped(s, section, token))
                    value = (n > 0) and tostring(n) or "none yet"
                else
                    value = tostring(Size(s[section] or {}))
                end
            end
            y = L:DataRow(content, y, { label = e.label, value = value })
            local note = e.note and e.note(s)
            if note then y = L:Paragraph(content, y, note, { color = L.C_DIM }) end
        end
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Full report")
    y = L:Paragraph(content, y,
        "Rescans this character now (gear, bags, spellbook, talents), runs every "
        .. "client probe, and opens one copy window with the probes and every "
        .. "harvested record. Paste that one window -- nothing else needed. Also /ta report.")
    y = L:ButtonRow(content, y, {
        { label = "Full report", onClick = function() H:RunAll() end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Export")
    y = L:Paragraph(content, y,
        "The saved file is the better path and needs none of these buttons: it "
        .. "lives under WTF\\Account\\<your account>\\SavedVariables\\ToonAge.lua "
        .. "and is written when you log out or /reload. Use the buttons when "
        .. "that file cannot be reached.")

    -- One button per registered section, in the pack's order. Per-class
    -- sections copy the current character's class; shift-click, or the button
    -- beside them, copies every class. Each only opens a copy window.
    do
        local row, notes = {}, {}
        local function shifted()
            return type(IsShiftKeyDown) == "function" and IsShiftKeyDown()
        end
        for _, e in ipairs(Hv:Exports()) do
            local section = e.section
            if CAPTURE_KIND[section] then
                row[#row + 1] = {
                    label = e.label,
                    tooltip = { e.label, "Copies this character's latest scan. Shift-click to copy every character." },
                    onClick = function()
                        local scope = "character"
                        if shifted() or H:View() == "all" then scope = "all" end
                        H:Export(section, 1, scope)
                    end,
                }
                row[#row + 1] = {
                    label = "All characters",
                    tooltip = { "All characters", "Copies this scan for every character saved on this account." },
                    onClick = function() H:Export(section, 1, "all") end,
                }
                local note = Hv:ForeignNote(section, s)
                if note then notes[#notes + 1] = e.label .. ": " .. note end
            elseif CLASS_EXPORT[section] then
                row[#row + 1] = {
                    label = e.label,
                    tooltip = { e.label, "Copies this character's class. Shift-click to copy every class." },
                    onClick = function()
                        H:Export(section, 1, shifted() and "all" or "class")
                    end,
                }
                row[#row + 1] = {
                    label = ALL_LABEL[section],
                    tooltip = { ALL_LABEL[section], "Copies every class saved on this account." },
                    onClick = function() H:Export(section, 1, "all") end,
                }
                local note = Hv:ForeignNote(section, s)
                if note then notes[#notes + 1] = e.label .. ": " .. note end
            else
                row[#row + 1] = { label = e.label, onClick = function() H:Export(section, 1) end }
            end
        end
        y = L:ButtonRow(content, y, row, { label = "Copy:" })
        for _, note in ipairs(notes) do
            y = L:Paragraph(content, y, note, { color = L.C_DIM })
        end
    end

    if (self._pages or 1) > 1 then
        y = L:ButtonRow(content, y, {
            { label = "< Prev", onClick = function()
                H:Export(H._section, math.max(1, (H._page or 1) - 1), H._scope) end },
            { label = "Next >", onClick = function()
                H:Export(H._section, math.min(H._pages or 1, (H._page or 1) + 1), H._scope) end },
        }, { label = ("Page %d of %d:"):format(self._page or 1, self._pages or 1) })
    end

    -- Client-only rows (Forever: World refresh).
    if pack.tabRows then y = pack.tabRows(L, content, y) or y end

    if pack.catalogRanges then
        -- Named so it cannot be mistaken for the Copy row's "Spell catalog"
        -- button, which only opens a window (2026-10-04: a scan run from here
        -- by mistake is how 8 stored ranks were lost, before scans were made
        -- additive).
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "Catalog scan")
        y = L:Paragraph(content, y,
            "Reads every trainable spell rank straight from the client -- name, rank "
            .. "and the level it is trained -- including spells no character of yours "
            .. "knows yet. Adds new and changed ranks to the catalog and never removes "
            .. "one, so it is safe on any character. Takes a few seconds and the game "
            .. "stays responsive. Also /ta catalog.")
        y = L:ButtonRow(content, y, {
            { label = Hv._catalogRunning and "Scanning..." or "Run catalog scan",
              onClick = function() H:ScanCatalog() end },
        })
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Client probes")
    y = L:Paragraph(content, y, pack.probesBlurb or
        "Runs every client probe and opens the results in a copyable window.")
    y = L:ButtonRow(content, y, {
        { label = "Run probes", onClick = function() H:RunProbes() end },
        { label = "All characters",
          tooltip = { "All characters", "Copies the saved probe for every character." },
          onClick = function() Hv:ExportCapture("probe", "all", 0) end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Dev tools",
        "For building ToonAge: API mapping and the quest-coordinate recorder.")
    y = L:ButtonRow(content, y, {
        { label = "Missing APIs", onClick = function() TA:SlashCommand("apiprobe") end },
        { label = "Coord stats",  onClick = function() TA:SlashCommand("coordstats") end },
        { label = "Coord export", onClick = function() TA:SlashCommand("coordexport") end },
        { label = H._confirmCoord and "Really clear?" or "Coord clear", onClick = function()
            if H._confirmCoord then
                H._confirmCoord = nil
                TA:SlashCommand("coordclear")
            else
                H._confirmCoord = true
            end
            if TA.Layout and TA.Layout.RefreshUI then TA.Layout:RefreshUI() end
        end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Reset")
    y = L:Paragraph(content, y,
        "|cFF888780Clear this character drops only that character's probe, "
        .. "trainer, spellbook and talent captures. Other characters stay. "
        .. "Clear store throws away every observation from every character "
        .. "and cannot be undone.|r")
    local id = Hv:CharacterIdentity()
    local who = ("%s (%s)"):format((id and id.name) or "unknown", (id and id.className) or "unknown")
    y = L:ButtonRow(content, y, {
        { danger = true,
          label = self._confirmClearOne and ("Clear saved data for %s?"):format(who) or "Clear this character",
          onClick = function()
            if H._confirmClearOne then
                local gone = Hv:CharacterIdentity()
                local named = ("%s (%s)"):format((gone and gone.name) or "unknown",
                    (gone and gone.className) or "unknown")
                Hv:ClearCharacter()
                H._confirmClearOne = nil
                if TA.Raw then
                    TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Saved harvest data for %s cleared."):format(named))
                end
            else
                H._confirmClearOne = true
                H._confirmClear = nil
            end
            if L.RefreshUI then L:RefreshUI() end
          end },
        { danger = true,
          label = self._confirmClear and "Really clear store?" or "Clear store",
          onClick = function()
            if H._confirmClear then
                Hv:Clear()
                H._confirmClear = nil
                if TA.Raw then TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Harvest store cleared.") end
            else
                H._confirmClear = true
                H._confirmClearOne = nil
            end
            if L.RefreshUI then L:RefreshUI() end
          end },
    })

    L:Finish(content, y)
end

-- ── Init ──────────────────────────────────────────────────────────────────

function H:Init()
    -- The pack is the packaging gate's runtime half: a client's TOC lists only
    -- its own pack, so no pack (or another client's) means this client does
    -- not record. Only Forever ships a pack so far (spec T6-T9 add the rest).
    local pack = Hv._pack
    if not pack or pack.client ~= TA.flavor then
        self._disabled = true
        return
    end
    Hv:Activate()

    -- Combat end resumes a scan that was queued. Skill and trade-skill
    -- updates rescan professions. Login and level-up use the full scan.
    for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE" }) do
        TA:RegisterEvent(ev)
    end

    -- Event fan-out: every running domain's events, registered once, each
    -- routed back to the domains that asked for it (pack order).
    Hv._routes = {}
    local registered = {}
    for _, d in ipairs(Hv:ActiveDomains()) do
        for _, ev in ipairs(d.events or {}) do
            Hv._routes[ev] = Hv._routes[ev] or {}
            local list = Hv._routes[ev]
            list[#list + 1] = d
            if not registered[ev] then
                registered[ev] = true
                -- Absorbed and recorded by TA:RegisterEvent if this client
                -- does not define the event (it once killed this module's Init).
                TA:RegisterEvent(ev)
            end
        end
    end

    -- The Copy row, in the pack's order: enabled domains' entries, plus the
    -- catalog on clients that walk spell IDs.
    local entries = {}
    for _, d in ipairs(Hv:ActiveDomains()) do
        for _, e in ipairs(d.export or {}) do entries[e.section] = e.label end
    end
    if pack.catalogRanges then entries.catalog = "Spell catalog" end
    for _, section in ipairs(pack.exportOrder or {}) do
        if entries[section] then Hv:RegisterExport(section, entries[section]) end
    end

    -- One-time store repairs: the domains' (trainer rows filed under
    -- professions), then the pack's (Forever: 8 catalog ranks lost 2026-10-04).
    local s = Hv:Store()
    if s then
        for _, d in ipairs(Hv:ActiveDomains()) do
            if d.Migrate then d:Migrate(s) end
        end
        if pack.repair then pack.repair(s) end
    end

    if TA.debug and TA.Raw then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r DataHarvester recording.")
    end
end
