-- ToonAge/Modules/Harvest/Domains/Trainer.lua  (harvest domain: trainer services)
--
-- 2026-10-03. The spell catalog cannot get rank text for spells you don't know
-- (pass 2: "+0 ranks, 9815 still blank"). A class trainer lists every rank of
-- every spell with its required level -- in Vanilla it listed the ones you are
-- too low for as well, under the "Unavailable" filter, and Forever's does the
-- same (measured on build 70205: 35 "unavailable" rows up to level 60 on a
-- level-17 Mage). So ONE visit per class gives the whole rank table at any
-- level. Records only; it never changes the trainer's filters or buys
-- anything. What the client answered is kept in trainerApi.
--
-- PROFESSION TRAINERS (T4, option (a) approved 2026-10-04): a profession
-- trainer's recipes are recorded too, but under professions -- never as class
-- spells. Before T4 a Blacksmithing and a Mining visit were filed as 39 MAGE
-- "spells": the profession check looked at every row ever stored for the
-- class, and one "Apprentice Blacksmith" row at level 1 made the Mining visit
-- look like a class trainer. Each visit is now judged on its own rows, and the
-- rows already filed wrongly are moved once (Migrate), none dropped.
--
-- Every client API call goes through TA.Caps (spec R2). Moved here from
-- Modules/Forever/DataHarvester.lua in T4.
--
--   trainer[CLASS][spellID]          = name, rank text, level required,
--                                      category (available / unavailable / used), when
--   trainerProf[PROFESSION][spellID] = the same fields, from a profession trainer

local TA = ToonAge
local Hv, Caps = TA.Harvester, TA.Caps

local Try, Clean, Fields, Size = Hv.Try, Hv.Clean, Hv.Fields, Hv.Size

local CATEGORY = { available = true, unavailable = true, used = true, header = true }

-- A profession's own rank rows ("Apprentice Mining", "Journeyman Mining") name
-- the profession; class trainers sell no such rows.
local RANK_WORDS = { "Apprentice", "Journeyman", "Expert", "Artisan", "Master", "Grand Master" }

local D = {
    id = "trainer",
    events = { "TRAINER_SHOW", "TRAINER_UPDATE" },
    export = {
        { section = "trainer",     label = "Trainer ranks" },
        { section = "trainerProf", label = "Profession trainers" },
    },
}

local function LevelReq(line)
    return tonumber((tostring(line):match("^[^\t]*\t[^\t]*\t([^\t]*)")))
end

--- The profession a set of rows belongs to, from its rank row, or nil.
local function ProfessionOf(names)
    for _, name in ipairs(names) do
        for _, word in ipairs(RANK_WORDS) do
            local rest = name:match("^" .. word .. " (.+)$")
            if rest and rest ~= "" then return rest end
        end
    end
    return nil
end

--- A visit is a class trainer's when one of its rows needs a level above 1.
--- Profession recipes report level 0 on Forever (their rank rows 0 or 1).
local function LooksLikeClassVisit(lines)
    for _, line in ipairs(lines) do
        local req = LevelReq(line)
        if req and req > 1 then return true end
    end
    return false
end

local function ProfTable(s, prof)
    if not s.trainerProf then
        s.trainerProf = {}
        Hv:AdoptSection("trainerProf", s.trainerProf)
    end
    s.trainerProf[prof] = s.trainerProf[prof] or {}
    return s.trainerProf[prof]
end

function D:ScanTrainer()
    local s = Hv:Store()
    if not s then return end
    local api = {}
    for _, n in ipairs({ "GetNumTrainerServices", "GetTrainerServiceInfo",
                         "GetTrainerServiceLevelReq", "GetTrainerServiceTypeFilter" }) do
        api[#api + 1] = n .. "=" .. (Caps.Fn(n) and "yes" or "NO")
    end
    local hasTip = Caps.Fn("C_TooltipInfo.GetTrainerService") ~= nil
    api[#api + 1] = "C_TooltipInfo.GetTrainerService=" .. (hasTip and "yes" or "NO")

    local n = tonumber((Try("GetNumTrainerServices")))
    local _, class = Try("UnitClass", "player")
    if not (n and class) then
        s.trainerApi = table.concat(api, " ") .. " | services=nil"
        return
    end
    if n == 0 then
        -- TRAINER_UPDATE also fires as the window closes, with 0 services.
        -- Recording that would overwrite the real visit's status line.
        return
    end
    local unavailShown = Try("GetTrainerServiceTypeFilter", "unavailable")
    -- Record format 2 (2026-10-03). Format 1 keyed rows by name + the 2nd
    -- return, assumed to be rank text. MEASURED on Forever build 70205: the
    -- returns are (name, category, texture, ...) -- no rank text -- so every
    -- rank of a spell shared one key and only the last survived (Fireball
    -- kept its level-60 rank only). Keyed by spell ID now.
    if s.trainerFormat ~= 2 then s.trainer = {}; s.trainerFormat = 2; Hv:AdoptSection("trainer", s.trainer) end

    -- This visit's rows, read first and judged on their own.
    local keys, lines, names = {}, {}, {}
    local unavailable, noID = 0, 0
    local now = Hv.Now() or 0
    for i = 1, n do
        local r = { Try("GetTrainerServiceInfo", i) }
        local name = r[1]
        -- Category is whichever early return is a category word, so a client
        -- that does return rank text (Classic Era's order) still parses.
        local category, rankText
        for k = 2, 4 do
            local v = r[k]
            if type(v) == "string" then
                if CATEGORY[v] then category = category or v
                elseif v:find("%d") then rankText = rankText or v end
            end
        end
        -- A name the client marks secret comes back from Caps as "secret".
        if type(name) == "string" and name ~= "" and name ~= "secret" and category ~= "header" then
            local req = tonumber((Try("GetTrainerServiceLevelReq", i))) or 0
            local id
            if hasTip then
                local data = Try("C_TooltipInfo.GetTrainerService", i)
                if type(data) == "table" and type(data.id) == "number" then id = data.id end
            end
            local key = id and tostring(id) or (Clean(name) .. "@" .. req)
            if not id then noID = noID + 1 end
            keys[#keys + 1] = key
            names[#names + 1] = name
            lines[#lines + 1] = table.concat({ Clean(name), Clean(rankText), req, Clean(category), now }, "\t")
            if category == "unavailable" then unavailable = unavailable + 1 end
        end
    end
    local rows = #lines

    -- Class or profession? The client's own answer when it has one, else this
    -- visit's level requirements.
    local profession = rows > 0 and (Try("IsTradeskillTrainer") == true or not LooksLikeClassVisit(lines))
    local where = class
    if rows > 0 then
        local t
        if profession then
            where = ProfessionOf(names) or "unknown"
            t = ProfTable(s, where)
            Hv:Touch("trainerProf")
        else
            s.trainer[class] = s.trainer[class] or {}
            t = s.trainer[class]
            Hv:Touch("trainer")
        end
        for i = 1, rows do t[keys[i]] = lines[i] end
    end

    s.trainerApi = table.concat(api, " ")
        .. (" | %s%s: services=%d recorded=%d unavailable=%d noSpellID=%d filter(unavailable)=%s")
        :format(profession and "profession trainer " or "", where, n, rows, unavailable, noID, tostring(unavailShown))
end

--- One time: rows a profession trainer left under a class (before T4) move to
--- trainerProf, grouped by visit (the time field), named by the visit's rank
--- row. A visit with any row above level 1 stays where it is. Nothing is
--- dropped; a row already under the profession is kept as it is.
function D:Migrate(s)
    if s.trainerProfFiled or type(s.trainer) ~= "table" then return end
    local moved = 0
    for cls, rows in pairs(s.trainer) do
        if type(rows) == "table" then
            local visits = {}
            for key, line in pairs(rows) do
                local when = Fields(line)[5] or ""
                visits[when] = visits[when] or { keys = {}, lines = {}, names = {} }
                local v = visits[when]
                v.keys[#v.keys + 1] = key
                v.lines[#v.lines + 1] = line
                v.names[#v.names + 1] = Fields(line)[1] or ""
            end
            for _, v in pairs(visits) do
                if not LooksLikeClassVisit(v.lines) then
                    local t = ProfTable(s, ProfessionOf(v.names) or "unknown")
                    for i, key in ipairs(v.keys) do
                        if t[key] == nil then t[key] = v.lines[i] end
                        rows[key] = nil
                        moved = moved + 1
                    end
                end
            end
            if next(rows) == nil then s.trainer[cls] = nil end
        end
    end
    s.trainerProfFiled = moved
end

function D:OnEvent(event)
    -- TRAINER_UPDATE fires on every filter click; one scan per second.
    Hv:Once("trainer", 1, function() pcall(self.ScanTrainer, self) end)
end

D.summary = {
    { section = "trainer", label = "Trainer ranks (open a class trainer)",
      value = function(s)
          local token = Hv.PlayerClass and Hv:PlayerClass()
          if token then
              local t = s.trainer and s.trainer[token]
              local n = (type(t) == "table") and Size(t) or 0
              return (n > 0) and tostring(n) or "none yet"
          end
          local classes, rows = 0, 0
          for _, t in pairs(s.trainer or {}) do classes = classes + 1; rows = rows + Size(t) end
          return (rows > 0) and string.format("%d from %d class%s", rows, classes,
              classes == 1 and "" or "es") or "none yet"
      end,
      note = function(s)
          return s.trainerApi and ("Last trainer visit: " .. s.trainerApi) or nil
      end },
    { section = "trainerProf", label = "Profession trainers",
      value = function(s)
          local profs, rows = 0, 0
          for _, t in pairs(s.trainerProf or {}) do profs = profs + 1; rows = rows + Size(t) end
          return (rows > 0) and string.format("%d from %d profession%s", rows, profs,
              profs == 1 and "" or "s") or "none yet"
      end },
}

Hv:RegisterDomain(D)
