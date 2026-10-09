-- ToonAge/Modules/Character/ProfessionSkills.lua
-- One profession readout for every version.
--
-- Which bar to draw is not chosen by game version. The loaded data file
-- (Data/<Flavor>/ProfessionSkills.lua) lists `prefer` in the order that
-- flavor wants, and this file uses the first entry whose calls exist:
--   segments    GetProfessions + GetProfessionInfo
--               + C_TradeSkillUI.GetProfessionInfoBySkillLineID
--   professions GetProfessions + GetProfessionInfo
--   skilllines  GetNumSkillLines + GetSkillLineInfo
--   skillinfo   C_SkillInfo.GetNumSkillLines + C_SkillInfo.GetSkillLineInfo
-- Caps answers the check when the client ships it. Otherwise the global is
-- read directly, so a TOC that does not load Caps still works.
--
-- A reader that ran and found nothing returns an empty list. A reader whose
-- calls are missing returns nil so the next prefer entry can run.

local TA = ToonAge
TA.Data = TA.Data or {}

local PS = {}
TA.ProfessionSkills = PS

local FEATURES = {
    segments = {
        "GetProfessions",
        "GetProfessionInfo",
        "C_TradeSkillUI.GetProfessionInfoBySkillLineID",
    },
    professions = { "GetProfessions", "GetProfessionInfo" },
    skilllines  = { "GetNumSkillLines", "GetSkillLineInfo" },
    skillinfo   = { "C_SkillInfo.GetNumSkillLines", "C_SkillInfo.GetSkillLineInfo" },
}

-- GetProfessions() slot order is the API's, on every client that has it:
-- two primary professions, then archaeology, fishing, cooking, first aid.
local PROFESSION_SLOTS = {
    { header = "Professions",      secondary = false },
    { header = "Professions",      secondary = false },
    { header = "Secondary Skills", secondary = true  },
    { header = "Secondary Skills", secondary = true  },
    { header = "Secondary Skills", secondary = true  },
    { header = "Secondary Skills", secondary = true  },
}

local function Num(v)
    if type(v) == "number" then return v end
    return tonumber(v)
end

local function Lookup(path)
    local Caps = TA.Caps
    if Caps and Caps.Fn then
        return Caps.Fn(path)
    end
    local node = _G
    for seg in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[seg]
        if node == nil then return nil end
    end
    if type(node) == "function" then return node end
    return nil
end

local function Ready(name)
    local need = FEATURES[name]
    if not need then return false end
    for _, path in ipairs(need) do
        if not Lookup(path) then return false end
    end
    return true
end

local function Index(data)
    local byId, byName = {}, {}
    for _, line in ipairs(data.lines or {}) do
        if line.id ~= nil then byId[line.id] = line end
        if type(line.name) == "string" then byName[line.name] = line end
    end
    return byId, byName
end

local function HeaderSet(data)
    local set = {}
    for _, name in ipairs(data.headers or {}) do
        if type(name) == "string" then set[name] = true end
    end
    return set
end

--- The client's max when it is a real ceiling; otherwise the data-file cap.
local function Ceiling(reported, fallback)
    local n = Num(reported)
    if n and n > 0 then return n end
    local f = Num(fallback)
    if f and f > 0 then return f end
    return n or 0
end

local function UsefulName(name)
    if type(name) ~= "string" or name == "" or name == "Unknown" then return nil end
    return name
end

local function SlotFor(index)
    return PROFESSION_SLOTS[index] or PROFESSION_SLOTS[1]
end

--- Known professions from GetProfessions / GetProfessionInfo. `children`
--- is true only for the segmented reader, which then asks for each expansion.
local function ReadProfessionSlots(data, children)
    local getP = Lookup("GetProfessions")
    local getInfo = Lookup("GetProfessionInfo")
    local getBy = children and Lookup("C_TradeSkillUI.GetProfessionInfoBySkillLineID") or nil
    if not getP or not getInfo then return nil end
    if children and not getBy then return nil end

    local ok, a, b, c, d, e, f = pcall(getP)
    if not ok then return {} end

    local byId = Index(data)
    local cards = {}
    -- Numeric loop: a nil primary must not stop the walk before fishing.
    local slots = { a, b, c, d, e, f }
    for index = 1, 6 do
        local profIndex = slots[index]
        if profIndex then
            local okInfo, name, icon, rank, maxRank, _, _, skillLine =
                pcall(getInfo, profIndex)
            if okInfo and name then
                local spec = skillLine and byId[skillLine] or nil
                local slot = SlotFor(index)
                local secondary = (spec and spec.secondary) or slot.secondary
                local header = secondary and "Secondary Skills" or "Professions"
                if spec and spec.secondary then header = "Secondary Skills" end
                local card = {
                    id        = skillLine,
                    name      = tostring(name),
                    icon      = icon,
                    rank      = Num(rank) or 0,
                    max       = Ceiling(maxRank, data.cap),
                    header    = header,
                    secondary = secondary and true or false,
                }
                if children and spec and type(spec.children) == "table" and #spec.children > 1 then
                    local segs = {}
                    for i, childId in ipairs(spec.children) do
                        local exp = data.expansions and data.expansions[i] or nil
                        local childRank, childMax, childName = 0, exp and exp.cap or data.cap, nil
                        local okChild, info = pcall(getBy, childId)
                        if okChild and type(info) == "table" then
                            childRank = Num(info.skillLevel) or Num(info.rank) or 0
                            childMax = Ceiling(info.maxSkillLevel or info.maxRank, exp and exp.cap or data.cap)
                            childName = UsefulName(info.professionName) or UsefulName(info.name)
                        elseif okChild and type(info) == "string" then
                            childName = UsefulName(info)
                        end
                        segs[#segs + 1] = {
                            id      = childId,
                            name    = childName or card.name,
                            label   = exp and exp.label or tostring(childId),
                            rank    = childRank,
                            max     = childMax,
                            current = exp and exp.current and true or false,
                            header  = exp and exp.label or header,
                        }
                    end
                    card.segments = segs
                end
                cards[#cards + 1] = card
            end
        end
    end
    return cards
end

local function ReadSegments(data)
    if not Ready("segments") then return nil end
    return ReadProfessionSlots(data, true)
end

local function ReadProfessions(data)
    if not Ready("professions") then return nil end
    return ReadProfessionSlots(data, false)
end

--- Classic GetSkillLineInfo rows, headers expanded when the client allows it
--- and put back afterwards. Returns every non-header line with the header
--- name that sat above it.
local function ScanSkillLines()
    local getNum = Lookup("GetNumSkillLines")
    local getInfo = Lookup("GetSkillLineInfo")
    if not getNum or not getInfo then return nil end

    local function LineAt(i)
        local ok, name, isHeader, isExpanded, rank, _, _, maxRank = pcall(getInfo, i)
        if not ok or not name then return nil end
        return {
            name       = tostring(name),
            isHeader   = isHeader and true or false,
            isExpanded = isExpanded and true or false,
            rank       = Num(rank) or 0,
            max        = Num(maxRank) or 0,
        }
    end

    local function Count()
        local ok, n = pcall(getNum)
        if not ok then return 0 end
        return Num(n) or 0
    end

    local expand = Lookup("ExpandSkillHeader")
    local collapse = Lookup("CollapseSkillHeader")
    local collapsed = {}
    if expand then
        for i = 1, Count() do
            local line = LineAt(i)
            if line and line.isHeader and not line.isExpanded then
                collapsed[#collapsed + 1] = line.name
            end
        end
        if #collapsed > 0 then pcall(expand, 0) end
    end

    local rows = {}
    local header = nil
    for i = 1, Count() do
        local line = LineAt(i)
        if line then
            if line.isHeader then
                header = line.name
            else
                line.header = header
                rows[#rows + 1] = line
            end
        end
    end

    if collapse and #collapsed > 0 then
        for _, wanted in ipairs(collapsed) do
            for i = 1, Count() do
                local line = LineAt(i)
                if line and line.isHeader and line.name == wanted and line.isExpanded then
                    pcall(collapse, i)
                    break
                end
            end
        end
    end
    return rows
end

local function ReadSkillLines(data)
    if not Ready("skilllines") then return nil end
    local rows = ScanSkillLines()
    if not rows then return nil end
    local headers = HeaderSet(data)
    local _, byName = Index(data)
    local cards = {}
    for _, row in ipairs(rows) do
        if row.header and headers[row.header] then
            local spec = byName[row.name]
            local secondaryName = data.headers and data.headers[2]
            local secondary = (spec and spec.secondary) or (secondaryName ~= nil and row.header == secondaryName)
            cards[#cards + 1] = {
                id        = spec and spec.id or nil,
                name      = row.name,
                rank      = row.rank,
                max       = Ceiling(row.max, data.cap),
                header    = row.header,
                secondary = secondary and true or false,
            }
        end
    end
    return cards
end

local function ReadSkillInfo(data)
    if not Ready("skillinfo") then return nil end
    local getNum = Lookup("C_SkillInfo.GetNumSkillLines")
    local getInfo = Lookup("C_SkillInfo.GetSkillLineInfo")
    local okN, n = pcall(getNum)
    if not okN then return {} end
    n = Num(n) or 0
    local byId, byName = Index(data)
    local headers = HeaderSet(data)
    local cards = {}
    local header = nil
    for i = 1, n do
        local ok, info = pcall(getInfo, i)
        if ok and type(info) == "table" and info.name then
            if info.isHeader then
                header = tostring(info.name)
            else
                local id = Num(info.skillID)
                local spec = (id and byId[id]) or byName[tostring(info.name)]
                local under = header and headers[header]
                if spec or under then
                    local rank = Num(info.rank) or 0
                    local rawMax = Num(info.maxRank)
                    -- A zero ceiling with no points is not a learned profession.
                    -- Comprehension is reported that way when the character
                    -- does not have it. A missing ceiling with a real rank
                    -- still counts; the data-file cap fills in the bar.
                    if (rawMax and rawMax > 0) or rank > 0 then
                        local secondaryName = data.headers and data.headers[2]
                        local secondary = (spec and spec.secondary) or (secondaryName ~= nil and header == secondaryName)
                        local lineHeader = header
                        if not lineHeader then
                            lineHeader = secondary and (secondaryName or "Secondary Skills")
                                or (data.headers and data.headers[1]) or "Professions"
                        end
                        cards[#cards + 1] = {
                            id        = id or (spec and spec.id) or nil,
                            name      = tostring(info.name),
                            rank      = rank,
                            max       = Ceiling(rawMax, data.cap),
                            header    = lineHeader,
                            secondary = secondary and true or false,
                        }
                    end
                end
            end
        end
    end
    return cards
end

local READERS = {
    segments    = ReadSegments,
    professions = ReadProfessions,
    skilllines  = ReadSkillLines,
    skillinfo   = ReadSkillInfo,
}

--- @return table { reader = string|nil, cards = {card...}, unverified = bool }
function PS.Collect()
    local data = TA.Data and TA.Data.ProfessionSkills
    if type(data) ~= "table" then
        return { cards = {}, unverified = false }
    end
    local unverified = data.unverified and true or false
    for _, name in ipairs(data.prefer or {}) do
        local reader = READERS[name]
        if reader and Ready(name) then
            local cards = reader(data)
            if cards then
                return { reader = name, cards = cards, unverified = unverified }
            end
        end
    end
    return { cards = {}, unverified = unverified }
end

local function Field(v)
    if v == nil or v == "" then return "unknown" end
    return tostring(v)
end

local function DumpLine(id, name, rank, max, header)
    return table.concat({
        Field(id), Field(name), Field(rank), Field(max), Field(header),
    }, "\t")
end

--- One line per skill line the chosen reader saw: id, name, rank, max, header.
--- Retail segments emit one line per expansion. The first line names the reader.
function PS.ProbeLines()
    local result = PS.Collect()
    local lines = {}
    if not result.reader then
        lines[#lines + 1] = "profession reader unavailable"
        return lines
    end
    local tag = "reader " .. result.reader
    if result.unverified then tag = tag .. " (unverified)" end
    lines[#lines + 1] = tag
    for _, card in ipairs(result.cards or {}) do
        if type(card.segments) == "table" and #card.segments > 1 then
            for _, seg in ipairs(card.segments) do
                lines[#lines + 1] = DumpLine(seg.id, seg.name or card.name, seg.rank, seg.max,
                    seg.header or seg.label or card.header)
            end
        else
            lines[#lines + 1] = DumpLine(card.id, card.name, card.rank, card.max, card.header)
        end
    end
    if #(result.cards or {}) == 0 then
        lines[#lines + 1] = "no profession skill lines"
    end
    return lines
end

return PS
