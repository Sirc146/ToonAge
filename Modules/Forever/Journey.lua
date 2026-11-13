-- ToonAge/Modules/Forever/Journey.lua  (WoW Forever only)
--
-- Session journal for one login, from entering the world to logout or reload.
-- It grows the harvester's idea (watch the client, keep what it reports) into
-- a play log: XP by source, deaths, loot, money, zones, quests, and flights.
--
-- Storage is TA.db.journey and nothing else. It is not the harvest store, it
-- is not analytics, and it is never uploaded. Saved values are data: this
-- file never compiles them.
--
-- Every client read goes through Core/Compat/API.lua, which asks ApiGuard
-- (TA:HasAPI) and refuses a missing or throwing function. Every event goes
-- through TA:RegisterEvent, which records a name this client does not define
-- instead of throwing. A missing event or API is skipped.
--
-- Rows are short arrays in chunks. A chunk holds at most `chunk` entries
-- (default 32). The whole journal stays under `b` approximate bytes (default
-- 65536). Oldest chunks are dropped first. Session summary rows are dropped
-- only after the raw chunks are gone, and the oldest summary goes first.
-- Strings live once, in `s`, and entries store the numeric id.

local TA = ToonAge

local J = {}
TA.Journey = J
TA:RegisterModule("ForeverJourney", J)

local DEFAULT_BUDGET = 65536
local DEFAULT_CHUNK = 32

local K_XP, K_DEATH, K_LOOT, K_MONEY = 1, 2, 3, 4
local K_ZONE, K_ACCEPT, K_TURNIN, K_FLIGHT = 5, 6, 7, 8
local XP_KILL, XP_QUEST, XP_EXPLORE, XP_OTHER = 1, 2, 3, 4

local CORE_EVENTS = {
    "PLAYER_XP_UPDATE",
    "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_SYSTEM",
    "QUEST_TURNED_IN",
    "QUEST_ACCEPTED",
    "PLAYER_DEAD",
    "PLAYER_MONEY",
    "ZONE_CHANGED_NEW_AREA",
    "CHAT_MSG_LOOT",
    "PLAYER_LOGOUT",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_CONTROL_LOST",
    "PLAYER_CONTROL_GAINED",
}

-- ── Store ────────────────────────────────────────────────────────────────

local function Measure(v, seen)
    local ty = type(v)
    if ty == "number" then
        return #tostring(v) + 1
    elseif ty == "string" then
        return #v + 3
    elseif ty == "boolean" then
        return v and 4 or 5
    elseif ty ~= "table" then
        return 4
    end
    if seen[v] then return 0 end
    seen[v] = true
    local n = 2
    for k, val in pairs(v) do
        n = n + Measure(k, seen) + Measure(val, seen) + 2
    end
    return n
end

function J:Measure(v)
    if type(v) ~= "table" then return 0 end
    return Measure(v, {})
end

function J:BindStrings()
    local st = self._store
    self._intern = {}
    if type(st) ~= "table" or type(st.s) ~= "table" then return end
    for i = 1, #st.s do
        local s = st.s[i]
        if type(s) == "string" and self._intern[s] == nil then
            self._intern[s] = i
        end
    end
end

function J:Store()
    if self._stoodDown then return nil end
    if type(TA.db) ~= "table" then return nil end
    local j = TA.db.journey
    if type(j) ~= "table" then
        j = {
            v = 1, b = DEFAULT_BUDGET, chunk = DEFAULT_CHUNK,
            s = {}, ses = {}, chunks = {}, seq = 0, unv = {},
        }
        TA.db.journey = j
        self._intern = nil
    end
    if type(j.s) ~= "table" then j.s = {} end
    if type(j.ses) ~= "table" then j.ses = {} end
    if type(j.chunks) ~= "table" then j.chunks = {} end
    if type(j.unv) ~= "table" then j.unv = {} end
    if type(j.b) ~= "number" or j.b < 256 then j.b = DEFAULT_BUDGET end
    if type(j.chunk) ~= "number" or j.chunk < 1 then j.chunk = DEFAULT_CHUNK end
    if type(j.seq) ~= "number" then j.seq = 0 end
    j.v = 1
    if self._store ~= j then self._intern = nil end
    self._store = j
    if not self._intern then self:BindStrings() end
    return j
end

function J:Budget()
    local st = self:Store()
    if st and type(st.b) == "number" then return st.b end
    return DEFAULT_BUDGET
end

function J:Used()
    local st = self._store
    if type(st) ~= "table" and type(TA.db) == "table" then st = TA.db.journey end
    if type(st) ~= "table" then return 0 end
    return self:Measure(st)
end

function J:SetBudget(n)
    if type(n) ~= "number" or n < 256 then return end
    local st = self:Store()
    if not st then return end
    st.b = math.floor(n)
    self:Prune()
end

function J:SetChunkCap(n)
    if type(n) ~= "number" or n < 1 then return end
    n = math.floor(n)
    if n > 200 then n = 200 end
    local st = self:Store()
    if not st then return end
    st.chunk = n
end

function J:Intern(text)
    if type(text) ~= "string" or text == "" then return 0 end
    text = text:gsub("[\r\n\t]", " "):sub(1, 64)
    if text == "" then return 0 end
    local st = self:Store()
    if not st then return 0 end
    local id = self._intern[text]
    if id then return id end
    st.s[#st.s + 1] = text
    id = #st.s
    self._intern[text] = id
    return id
end

local function StoredString(st, id)
    if type(id) ~= "number" or id <= 0 then return nil end
    if type(st) ~= "table" or type(st.s) ~= "table" then return nil end
    local s = st.s[id]
    if type(s) ~= "string" then return nil end
    return s
end

function J:CompactStrings()
    local st = self._store
    if type(st) ~= "table" or type(st.s) ~= "table" then return end
    local used = {}
    local function mark(id)
        if type(id) == "number" and id > 0 then used[id] = true end
    end
    local chunks = st.chunks or {}
    for ci = 1, #chunks do
        local ch = chunks[ci]
        if type(ch) == "table" and type(ch.e) == "table" then
            for ei = 1, #ch.e do
                local e = ch.e[ei]
                if type(e) == "table" then
                    local k = e[1]
                    if k == K_DEATH then mark(e[4]); mark(e[5])
                    elseif k == K_ZONE or k == K_ACCEPT or k == K_TURNIN then mark(e[4])
                    elseif k == K_FLIGHT then mark(e[3]); mark(e[4])
                    end
                end
            end
        end
    end
    local old = st.s
    local new, map = {}, {}
    local changed = #old == 0
    for i = 1, #old do
        if used[i] and type(old[i]) == "string" then
            new[#new + 1] = old[i]
            map[i] = #new
            if map[i] ~= i then changed = true end
        else
            changed = true
        end
    end
    if not changed then
        self:BindStrings()
        return
    end
    local function mapped(id)
        if type(id) ~= "number" or id <= 0 then return 0 end
        return map[id] or 0
    end
    for ci = 1, #chunks do
        local ch = chunks[ci]
        if type(ch) == "table" and type(ch.e) == "table" then
            for ei = 1, #ch.e do
                local e = ch.e[ei]
                if type(e) == "table" then
                    local k = e[1]
                    if k == K_DEATH then
                        e[4], e[5] = mapped(e[4]), mapped(e[5])
                    elseif k == K_ZONE or k == K_ACCEPT or k == K_TURNIN then
                        e[4] = mapped(e[4])
                    elseif k == K_FLIGHT then
                        e[3], e[4] = mapped(e[3]), mapped(e[4])
                    end
                end
            end
        end
    end
    st.s = new
    self:BindStrings()
end

function J:Prune()
    local st = self:Store()
    if not st then return end
    local budget = st.b or DEFAULT_BUDGET
    local guard = 0
    while self:Measure(st) > budget and guard < 2000 do
        guard = guard + 1
        if #st.chunks > 0 then
            table.remove(st.chunks, 1)
            self:CompactStrings()
        elseif #st.ses > 1 then
            table.remove(st.ses, 1)
        else
            break
        end
    end
end

-- ── Rows ─────────────────────────────────────────────────────────────────

function J:Now()
    local C = TA.Compat
    if C and type(C.ServerTime) == "function" then
        local ok, t = pcall(C.ServerTime)
        if ok and type(t) == "number" then return math.floor(t) end
    end
    return 0
end

function J:Num(name, ...)
    local C = TA.Compat
    if not C or type(C[name]) ~= "function" then return nil end
    local ok, v = pcall(C[name], ...)
    if not ok or type(v) ~= "number" then return nil end
    return v
end

function J:ReadMap()
    local C = TA.Compat
    if not C or type(C.PlayerMap) ~= "function" then return nil, nil end
    local ok, id, name = pcall(C.PlayerMap)
    if not ok then return nil, nil end
    if type(id) ~= "number" then id = nil end
    if type(name) ~= "string" or name == "" then name = nil end
    return id, name
end

function J:PlainName(unit)
    local C = TA.Compat
    if not C or type(C.UnitName) ~= "function" then return nil end
    local ok, name = pcall(C.UnitName, unit)
    if not ok or type(name) ~= "string" or name == "" then return nil end
    return name
end

function J:Append(entry)
    if self._stoodDown then return end
    if not self._sid then self:OpenSession() end
    local st = self:Store()
    if not st or not self._sid then return end
    local cap = st.chunk or DEFAULT_CHUNK
    local chunks = st.chunks
    local last = chunks[#chunks]
    if type(last) ~= "table" or last.i ~= self._sid or type(last.e) ~= "table" or #last.e >= cap then
        last = { i = self._sid, e = {} }
        chunks[#chunks + 1] = last
    end
    last.e[#last.e + 1] = entry
    self:Prune()
end

function J:OpenSession()
    if self._stoodDown then return end
    if self._sid then return end
    local st = self:Store()
    if not st then return end
    st.seq = (st.seq or 0) + 1
    local row = {
        i = st.seq, a = self:Now(), b = 0,
        x = { 0, 0, 0, 0 },
        d = 0, l = 0, mi = 0, mo = 0, z = 0, qa = 0, qt = 0, f = 0,
    }
    st.ses[#st.ses + 1] = row
    self._sid = st.seq
    self._sum = row
    self._xpBook = self:Num("PlayerXP")
    self._money = self:Num("PlayerMoney")
    self._map, self._zone = nil, nil
    self._chat = nil
    self._questXP = false
    self._taxiFrom, self._taxiAir = nil, nil
    self:NoteZone()
end

function J:CloseSession()
    if not self._sid then return end
    self:ReconcileXP(true)
    if self._sum then self._sum.b = self:Now() end
    self._sid = nil
    self._sum = nil
    self._xpBook = nil
    self._money = nil
    self._map, self._zone = nil, nil
    self._chat = nil
    self._questXP = false
    self._taxiFrom, self._taxiAir = nil, nil
end

function J:Summary()
    if not self._sum or not self._sid then self:OpenSession() end
    return self._sum
end

function J:NoteZone()
    local map, name = self:ReadMap()
    if type(map) ~= "number" or map <= 0 then map = 0 end
    if type(name) ~= "string" or name == "" then name = nil end
    if map == 0 and not name then return end
    if map == self._map and name == self._zone then return end
    self._map, self._zone = map, name
    local sm = self._sum
    if not sm then return end
    sm.z = (sm.z or 0) + 1
    self:Append({ K_ZONE, self:Now(), map, self:Intern(name) })
end

function J:RecordXP(src, amount)
    if type(amount) ~= "number" or amount <= 0 then return end
    if type(src) ~= "number" or src < XP_KILL or src > XP_OTHER then src = XP_OTHER end
    amount = math.floor(amount)
    local sm = self:Summary()
    if not sm then return end
    sm.x[src] = (sm.x[src] or 0) + amount
    self:Append({ K_XP, self:Now(), src, amount })
end

function J:RecordLoot(itemID, count, quality)
    if self._stoodDown then return end
    if type(itemID) ~= "number" or itemID <= 0 then return end
    count = (type(count) == "number" and count >= 1) and math.floor(count) or 1
    quality = type(quality) == "number" and math.floor(quality) or 0
    local sm = self:Summary()
    if not sm then return end
    sm.l = (sm.l or 0) + count
    self:Append({ K_LOOT, self:Now(), math.floor(itemID), count, quality })
end

function J:ReconcileXP(flush)
    local chat = self._chat or {}
    self._chat = {}
    local cur = self:Num("PlayerXP")
    if not cur then
        for i = 1, #chat do self:RecordXP(chat[i][1], chat[i][2]) end
        return
    end
    if self._xpBook == nil then
        self._xpBook = cur
        if flush then
            for i = 1, #chat do self:RecordXP(chat[i][1], chat[i][2]) end
        end
        return
    end
    local delta = cur - self._xpBook
    if delta < 0 then
        for i = 1, #chat do self:RecordXP(chat[i][1], chat[i][2]) end
        self._xpBook = cur
        return
    end
    if delta == 0 and flush then
        for i = 1, #chat do self:RecordXP(chat[i][1], chat[i][2]) end
        return
    end
    local used = 0
    for i = 1, #chat do
        local src, amt = chat[i][1], chat[i][2]
        if type(amt) == "number" and amt > 0 and used < delta then
            local take = amt
            if used + take > delta then take = delta - used end
            self:RecordXP(src, take)
            used = used + take
        end
    end
    if delta - used > 0 then self:RecordXP(XP_OTHER, delta - used) end
    self._xpBook = cur
end

function J:NoteXP(src, amount)
    if type(amount) ~= "number" or amount <= 0 then return end
    self._chat = self._chat or {}
    self._chat[#self._chat + 1] = { src, math.floor(amount) }
    local cur = self:Num("PlayerXP")
    if cur and self._xpBook and (cur - self._xpBook) > 0 then
        self:ReconcileXP(false)
    end
end

function J.ParseXP(msg)
    if type(msg) ~= "string" then return nil end
    local base = tonumber(msg:match("[Gg]ain%s+(%d+)%s+experience"))
        or tonumber(msg:match("(%d+)%s+experience%s+gained"))
    if not base then return nil end
    local bonus = tonumber(msg:match("%+%s*(%d+)%s+exp")) or 0
    return base + bonus
end

function J.SourceFor(event, msg, questRecent)
    if type(msg) ~= "string" then return nil, nil end
    if event == "CHAT_MSG_SYSTEM" then
        if msg:find("iscover", 1, true) then return XP_EXPLORE, J.ParseXP(msg) end
        return nil, nil
    end
    if event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local n = J.ParseXP(msg)
        if not n then return nil, nil end
        if questRecent then return XP_QUEST, n end
        return XP_KILL, n
    end
    return nil, nil
end

function J:OnXPMessage(event, msg)
    if event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local src, amt = J.SourceFor(event, msg, self._questXP and true or false)
        self._questXP = false
        if src and amt then self:NoteXP(src, amt) end
        return
    end
    if event == "CHAT_MSG_SYSTEM" then
        if type(msg) ~= "string" then return end
        if not msg:find("experience", 1, true) and not msg:find("iscover", 1, true) then return end
        local src, amt = J.SourceFor(event, msg, false)
        if src and amt then self:NoteXP(src, amt) end
    end
end

function J:OnDeath()
    local map, zone = self:ReadMap()
    local killer = self:PlainName("target")
    local me = self:PlainName("player")
    if not killer or killer == me then killer = nil end
    local sm = self:Summary()
    if not sm then return end
    sm.d = (sm.d or 0) + 1
    if type(map) ~= "number" or map <= 0 then map = 0 end
    self:Append({ K_DEATH, self:Now(), map, self:Intern(zone), self:Intern(killer) })
end

function J:OnLoot(msg)
    if type(msg) ~= "string" then return end
    if not msg:find("You receive loot", 1, true) and not msg:find("You receive item", 1, true) then
        return
    end
    local id = tonumber(msg:match("|Hitem:(%d+)"))
    if not id then return end
    local count = tonumber(msg:match("|h|r?x(%d+)")) or tonumber(msg:match("x(%d+)%s*$")) or 1
    local quality = self:Num("ItemQuality", id) or 0
    self:RecordLoot(id, count, quality)
end

function J:OnMoney()
    local cur = self:Num("PlayerMoney")
    if not cur then return end
    if self._money == nil then
        self._money = cur
        return
    end
    local d = cur - self._money
    self._money = cur
    if d == 0 then return end
    d = (d > 0) and math.floor(d) or -math.floor(-d)
    if d == 0 then return end
    local sm = self:Summary()
    if not sm then return end
    if d > 0 then sm.mi = (sm.mi or 0) + d else sm.mo = (sm.mo or 0) - d end
    self:Append({ K_MONEY, self:Now(), d })
end

function J:OnQuest(kind, qid)
    if type(qid) ~= "number" or qid <= 0 then return end
    qid = math.floor(qid)
    local title
    local C = TA.Compat
    if C and type(C.QuestTitle) == "function" then
        local ok, t = pcall(C.QuestTitle, qid)
        if ok and type(t) == "string" and t ~= "" then title = t end
    end
    local sm = self:Summary()
    if not sm then return end
    if kind == K_ACCEPT then sm.qa = (sm.qa or 0) + 1 else sm.qt = (sm.qt or 0) + 1 end
    self:Append({ kind, self:Now(), qid, self:Intern(title) })
end

function J:FinishFlight()
    local _, name = self:ReadMap()
    local startName = self._taxiFrom or ""
    self._taxiFrom = nil
    self._taxiAir = false
    if startName == "" and (type(name) ~= "string" or name == "") then return end
    local sm = self:Summary()
    if not sm then return end
    sm.f = (sm.f or 0) + 1
    self:Append({ K_FLIGHT, self:Now(), self:Intern(startName), self:Intern(name) })
end

-- ── Events ───────────────────────────────────────────────────────────────

function J:Listen(event)
    self._live = self._live or {}
    if type(TA.RegisterEvent) ~= "function" then
        self._live[event] = false
        return false
    end
    local ok, accepted = pcall(function() return TA:RegisterEvent(event) end)
    local live = (ok and accepted) and true or false
    self._live[event] = live
    if not live then
        TA.unknownEvents = TA.unknownEvents or {}
        TA.unknownEvents[event] = true
    end
    return live
end

function J:ListenAll()
    for i = 1, #CORE_EVENTS do self:Listen(CORE_EVENTS[i]) end
    local taxi = self:Listen("TAXIMAP_OPENED")
    self:Listen("TAXIMAP_CLOSED")
    self._flightUnverified = not taxi
    local st = self:Store()
    if st then
        if taxi then st.unv.f = nil else st.unv.f = 1 end
    end
end

function J:FlightState()
    if self._flightUnverified then return "UNVERIFIED" end
    return "ready"
end

function J:OnEvent(event, ...)
    if self._stoodDown then return end
    if event == "PLAYER_LOGOUT" then
        self:CloseSession()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if not self._sid then self:OpenSession() else self:NoteZone() end
        return
    end
    if event == "PLAYER_XP_UPDATE" then
        self:ReconcileXP(false)
        return
    end
    if event == "CHAT_MSG_COMBAT_XP_GAIN" or event == "CHAT_MSG_SYSTEM" then
        self:OnXPMessage(event, (...))
        return
    end
    if event == "QUEST_ACCEPTED" then
        local a, b = ...
        local qid = (type(b) == "number") and b or a
        self:OnQuest(K_ACCEPT, qid)
        return
    end
    if event == "QUEST_TURNED_IN" then
        local qid, xp = ...
        self:OnQuest(K_TURNIN, qid)
        self._questXP = true
        if not (self._live and self._live["CHAT_MSG_COMBAT_XP_GAIN"]) and type(xp) == "number" then
            self:NoteXP(XP_QUEST, xp)
        end
        return
    end
    if event == "PLAYER_DEAD" then
        self:OnDeath()
        return
    end
    if event == "PLAYER_MONEY" then
        self:OnMoney()
        return
    end
    if event == "CHAT_MSG_LOOT" then
        self:OnLoot((...))
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then
        if self._taxiAir then self:FinishFlight() else self:NoteZone() end
        return
    end
    if self._flightUnverified then return end
    if event == "TAXIMAP_OPENED" then
        local _, name = self:ReadMap()
        self._taxiFrom = name or ""
        self._taxiAir = false
        return
    end
    if event == "TAXIMAP_CLOSED" then
        if not self._taxiAir then self._taxiFrom = nil end
        return
    end
    if event == "PLAYER_CONTROL_LOST" then
        if self._taxiFrom == nil then return end
        -- false means the client says this is not a taxi. nil means it
        -- could not answer, and the taxi map we just opened is the evidence.
        local on
        local C = TA.Compat
        if C and type(C.OnTaxi) == "function" then
            local ok, v = pcall(C.OnTaxi)
            if ok then on = v end
        end
        if on == false then return end
        self._taxiAir = true
        return
    end
    if event == "PLAYER_CONTROL_GAINED" then
        if self._taxiAir then self:FinishFlight() end
    end
end

function J:OnEnterWorld()
    if self._stoodDown then return end
    if not self._sid then self:OpenSession() else self:NoteZone() end
end

-- ── Summary window and clear ─────────────────────────────────────────────

function J:FormatWhen(t)
    local C = TA.Compat
    if C and type(C.FormatTime) == "function" and type(t) == "number" and t > 0 then
        local ok, text = pcall(C.FormatTime, t)
        if ok and type(text) == "string" and text ~= "" then return text end
    end
    return tostring(t or 0)
end

function J:FormatEntry(st, e)
    if type(e) ~= "table" then return nil end
    local k = e[1]
    if k == K_DEATH then
        local zone = StoredString(st, e[4]) or "unknown"
        local killer = StoredString(st, e[5])
        if killer then return "  death at " .. zone .. " by " .. killer end
        return "  death at " .. zone
    elseif k == K_ACCEPT or k == K_TURNIN then
        local title = StoredString(st, e[4]) or ("quest " .. tostring(e[3] or "?"))
        if k == K_ACCEPT then return "  accepted " .. title end
        return "  turned in " .. title
    elseif k == K_FLIGHT then
        local a = StoredString(st, e[3]) or "?"
        local b = StoredString(st, e[4]) or "?"
        return "  flight " .. a .. " -> " .. b
    end
    return nil
end

function J:FormatSession(st, sm)
    local x = type(sm.x) == "table" and sm.x or {}
    local head = string.format("Session %s  %s -> %s",
        tostring(sm.i or "?"),
        self:FormatWhen(sm.a),
        (type(sm.b) == "number" and sm.b > 0) and self:FormatWhen(sm.b) or "open")
    local xp = string.format("XP  kill %d, quest %d, explore %d, other %d",
        x[1] or 0, x[2] or 0, x[3] or 0, x[4] or 0)
    local rest = string.format(
        "deaths %d, loot %d, money in %d copper, out %d copper, zones %d, quests accepted %d, turned in %d, flights %d",
        sm.d or 0, sm.l or 0, sm.mi or 0, sm.mo or 0, sm.z or 0, sm.qa or 0, sm.qt or 0, sm.f or 0)
    local lines = { head, "  " .. xp, "  " .. rest }
    local sid = sm.i
    local shown = 0
    local chunks = st.chunks or {}
    for ci = 1, #chunks do
        local ch = chunks[ci]
        if type(ch) == "table" and ch.i == sid and type(ch.e) == "table" then
            for ei = 1, #ch.e do
                local line = self:FormatEntry(st, ch.e[ei])
                if line then
                    lines[#lines + 1] = line
                    shown = shown + 1
                    if shown >= 12 then return table.concat(lines, "\n") end
                end
            end
        end
    end
    return table.concat(lines, "\n")
end

function J:SummaryText()
    local st = self:Store()
    local lines = {
        "ToonAge session journal",
        "Local only, saved in ToonAgeDB.journey. Not uploaded. Independent of usage stats.",
    }
    if type(st) ~= "table" then
        lines[#lines + 1] = "No sessions yet."
        return table.concat(lines, "\n")
    end
    lines[#lines + 1] = string.format("Approx %d bytes of %d budget.", self:Measure(st), st.b or DEFAULT_BUDGET)
    if st.unv and st.unv.f == 1 then
        lines[#lines + 1] = "Flights: UNVERIFIED (TAXIMAP_OPENED is not on this client)."
    else
        lines[#lines + 1] = "Flights: taxi map events are available."
    end
    lines[#lines + 1] = "Killer: readable target name only. Death recap API: UNVERIFIED."
    local ses = st.ses or {}
    if #ses == 0 then
        lines[#lines + 1] = "No sessions yet."
        return table.concat(lines, "\n")
    end
    local first = 1
    if #ses > 8 then first = #ses - 7 end
    if first > 1 then
        lines[#lines + 1] = string.format("%d older sessions omitted.", first - 1)
    end
    for i = first, #ses do
        local sm = ses[i]
        if type(sm) == "table" then
            lines[#lines + 1] = self:FormatSession(st, sm)
        end
    end
    return table.concat(lines, "\n")
end

function J:ShowSummary()
    local text = self:SummaryText()
    if type(TA.ShowCopyWindow) == "function" then
        pcall(TA.ShowCopyWindow, TA, "ToonAge session journal", text)
    end
    return text
end

function J:Clear()
    local st = self._store
    local b = (type(st) == "table" and type(st.b) == "number") and st.b or DEFAULT_BUDGET
    local n = (type(st) == "table" and type(st.chunk) == "number") and st.chunk or DEFAULT_CHUNK
    local unv = (type(st) == "table" and type(st.unv) == "table") and st.unv or {}
    self._sid = nil
    self._sum = nil
    self._intern = {}
    self._xpBook = nil
    self._money = nil
    self._map, self._zone = nil, nil
    self._chat = nil
    self._questXP = false
    self._taxiFrom, self._taxiAir = nil, nil
    self._confirmClear = nil
    if type(TA.db) ~= "table" then return end
    TA.db.journey = {
        v = 1, b = b, chunk = n, s = {}, ses = {}, chunks = {}, seq = 0, unv = unv,
    }
    self._store = TA.db.journey
end

function J:RequestClear()
    if self._confirmClear then
        self._confirmClear = nil
        self:Clear()
        return true
    end
    self._confirmClear = true
    return false
end

function J:Init()
    if TA.flavor ~= "forever" then
        self._stoodDown = true
        return
    end
    self._stoodDown = false
    self:Store()
    self:ListenAll()
    self:OpenSession()
end

return J
