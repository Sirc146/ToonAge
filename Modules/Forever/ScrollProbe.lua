-- ToonAge/Modules/Forever/ScrollProbe.lua
--
-- Settings > Debug button for the Forever client. One click opens the shared
-- copy window (Core/UI.lua ShowCopyWindow) with a paste-back report.
--
-- Read-only. It does not cast, run a macro, set a waypoint, write
-- SavedVariables, or touch the network. Setter APIs are passed to ProbeType
-- and are not called. Every read goes through Core/Compat/API.lua, which
-- asks ApiGuard (HasAPI) and pcalls the call. A missing or thrown API becomes
-- MISSING / nil / ERROR on its own line.
--
-- Loaded from ToonAge_Camelot.toc only.

local TA = ToonAge

local M = {}
TA.ScrollProbe = M
TA:RegisterModule("ForeverScrollProbe", M)

local TYPE_PATHS = {
    "C_Map.SetUserWaypoint",
    "C_Map.CanSetUserWaypointOnMap",
    "C_SuperTrack.SetSuperTrackedUserWaypoint",
    "C_Map.GetBestMapForUnit",
    "C_Map.GetPlayerMapPosition",
    "GetItemCount",
    "C_Item.GetItemCount",
    "C_Container.GetItemCount",
}

local SPELLS = {
    { id = 1296017, name = "Comprehend Scroll" },
    { id = 1302508, name = "Study" },
    { id = 1310041, name = "Research" },
}

local RESEARCH_ACCESS_QUEST = 97286
local COMPREHENSION_SKILL_LINE = 3012
local LIGHT_FEATHER = 17056

local BUILD_LABELS = { "version", "build", "date", "interface" }

local function OnForever()
    if TA.IsForever then return true end
    if TA.flavor == "forever" then return true end
    return false
end

local function Shown(value, quoteStrings)
    if value == nil then return "nil" end
    local okT, kind = pcall(type, value)
    if not okT then return "ERROR: " .. tostring(kind) end
    if kind == "string" then
        if quoteStrings then
            local okQ, quoted = pcall(string.format, "%q", value)
            if okQ then return quoted end
        end
        local okS, text = pcall(tostring, value)
        if okS then return text end
        return "ERROR: tostring"
    end
    if kind == "number" or kind == "boolean" then
        local okS, text = pcall(tostring, value)
        if okS then return text end
        return "ERROR: tostring"
    end
    if kind == "function" then return "function" end
    return kind
end

local function ValueText(status, packed)
    if status ~= "ok" then return tostring(status) end
    if type(packed) ~= "table" or (packed.n or 0) == 0 then return "nil" end
    local any = false
    local parts = {}
    for i = 1, packed.n do
        if packed[i] ~= nil then any = true end
        parts[i] = Shown(packed[i], false)
    end
    if not any then return "nil" end
    if packed.n == 1 then return parts[1] end
    return table.concat(parts, ", ")
end

local function FormatBuild(packed)
    if type(packed) ~= "table" or (packed.n or 0) == 0 then return "nil" end
    local parts = {}
    for i = 1, packed.n do
        local label = BUILD_LABELS[i] or ("extra" .. (i - #BUILD_LABELS))
        parts[#parts + 1] = label .. "=" .. Shown(packed[i], true)
    end
    return table.concat(parts, " ")
end

local function Field(info, key)
    if type(info) ~= "table" then return "nil" end
    local ok, value = pcall(function() return info[key] end)
    if not ok then return "ERROR: " .. tostring(value) end
    return Shown(value, false)
end

local function RawTable(info)
    local ok, text = pcall(function()
        local keys = {}
        for k in pairs(info) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, key in ipairs(keys) do
            local vok, value = pcall(function() return info[key] end)
            local shown
            if not vok then
                shown = "ERROR: " .. tostring(value)
            else
                -- Shown prints "function" and does not call the field.
                shown = Shown(value, true)
            end
            parts[#parts + 1] = tostring(key) .. "=" .. shown
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    end)
    if not ok then return "ERROR: " .. tostring(text) end
    return text
end

function M:Report()
    if not OnForever() then
        return "ToonAge Scroll Probe (read-only)\n"
            .. "Forever only. This client is not the Forever flavor, so nothing was read."
    end

    local C = TA.Compat
    local lines = {}

    local function Add(producer)
        local ok, row = pcall(producer)
        if not ok then
            lines[#lines + 1] = "ERROR: " .. tostring(row)
            return
        end
        if type(row) == "table" then
            for i = 1, #row do lines[#lines + 1] = row[i] end
        elseif row ~= nil then
            lines[#lines + 1] = row
        end
    end

    local stamp = "MISSING"
    if C and C.ProbeDate then
        local ok, value = pcall(function() return C.ProbeDate() end)
        stamp = ok and tostring(value) or ("ERROR: " .. tostring(value))
    else
        stamp = "ERROR: Compat guard missing"
    end
    lines[#lines + 1] = "ToonAge Scroll Probe (read-only)  " .. stamp

    Add(function()
        if not (C and C.ProbeGetBuildInfo) then return "Client build: ERROR: Compat guard missing" end
        local status, packed = C.ProbeGetBuildInfo()
        if status ~= "ok" then return "Client build: " .. tostring(status) end
        return "Client build: " .. FormatBuild(packed)
    end)

    Add(function()
        if not (C and C.ProbeType) then return "ERROR: Compat guard missing" end
        local out = {}
        for _, path in ipairs(TYPE_PATHS) do
            out[#out + 1] = "type " .. path .. ": " .. tostring(C.ProbeType(path))
        end
        return out
    end)

    Add(function()
        if not (C and C.ProbeBestMap and C.ProbeMapXY) then
            return "uiMapID: ERROR: Compat guard missing"
        end
        local status, packed = C.ProbeBestMap()
        local mapText
        local mapID
        if status ~= "ok" then
            mapText = tostring(status)
        elseif type(packed) ~= "table" or packed[1] == nil then
            mapText = "nil"
        elseif type(packed[1]) ~= "number" then
            mapText = Shown(packed[1], false)
        else
            mapID = packed[1]
            mapText = tostring(mapID)
        end
        local xy
        if type(mapID) ~= "number" then
            xy = "player x,y C_Map.GetPlayerMapPosition: nil (no uiMapID)"
        else
            local xyStatus, x, y = C.ProbeMapXY(mapID)
            local body
            if xyStatus == "ok" and type(x) == "number" and type(y) == "number" then
                body = string.format("%.4f, %.4f (%.1f, %.1f)", x, y, x * 100, y * 100)
            else
                body = tostring(xyStatus)
            end
            xy = "player x,y C_Map.GetPlayerMapPosition(" .. mapID .. ", \"player\"): " .. body
        end
        return {
            "uiMapID C_Map.GetBestMapForUnit(\"player\"): " .. mapText,
            xy,
        }
    end)

    Add(function()
        if not (C and C.ProbeIsSpellKnown and C.ProbeIsPlayerSpell) then
            return "ERROR: Compat guard missing"
        end
        local out = {}
        for _, spell in ipairs(SPELLS) do
            local knownStatus, knownPacked = C.ProbeIsSpellKnown(spell.id)
            local playerStatus, playerPacked = C.ProbeIsPlayerSpell(spell.id)
            out[#out + 1] = "IsSpellKnown(" .. spell.id .. ") " .. spell.name .. ": "
                .. ValueText(knownStatus, knownPacked)
            out[#out + 1] = "IsPlayerSpell(" .. spell.id .. ") " .. spell.name .. ": "
                .. ValueText(playerStatus, playerPacked)
        end
        return out
    end)

    Add(function()
        if not (C and C.ProbeQuestFlagNS and C.ProbeQuestFlagGlobal) then
            return "ERROR: Compat guard missing"
        end
        local nsStatus, nsPacked = C.ProbeQuestFlagNS(RESEARCH_ACCESS_QUEST)
        local gStatus, gPacked = C.ProbeQuestFlagGlobal(RESEARCH_ACCESS_QUEST)
        return {
            "C_QuestLog.IsQuestFlaggedCompleted(" .. RESEARCH_ACCESS_QUEST
                .. ") Research Access: " .. ValueText(nsStatus, nsPacked),
            "IsQuestFlaggedCompleted(" .. RESEARCH_ACCESS_QUEST
                .. ") Research Access: " .. ValueText(gStatus, gPacked),
        }
    end)

    Add(function()
        local id = COMPREHENSION_SKILL_LINE
        local prefix = "C_SkillInfo.GetSkillLineInfoByID(" .. id .. ") Comprehension"
        if not (C and C.ProbeSkillLine) then return prefix .. ": ERROR: Compat guard missing" end
        local status, packed = C.ProbeSkillLine(id)
        if status ~= "ok" then return prefix .. ": " .. tostring(status) end
        local info = packed and packed[1]
        if type(info) ~= "table" then
            return prefix .. ": " .. ValueText(status, packed)
        end
        return {
            prefix .. " rank: " .. Field(info, "rank"),
            prefix .. " maxRank: " .. Field(info, "maxRank"),
            prefix .. " raw: " .. RawTable(info),
        }
    end)

    Add(function()
        if not (C and C.ProbeCItemCount and C.ProbeCContainerCount and C.ProbeGlobalItemCount) then
            return "ERROR: Compat guard missing"
        end
        local note = " (bags only, includeBank false)"
        local cItem, cPacked = C.ProbeCItemCount(LIGHT_FEATHER)
        local cCont, contPacked = C.ProbeCContainerCount(LIGHT_FEATHER)
        local glob, gPacked = C.ProbeGlobalItemCount(LIGHT_FEATHER)
        return {
            "C_Item.GetItemCount Light Feather " .. LIGHT_FEATHER .. ": "
                .. ValueText(cItem, cPacked) .. note,
            "C_Container.GetItemCount Light Feather " .. LIGHT_FEATHER .. ": "
                .. ValueText(cCont, contPacked) .. note,
            "GetItemCount Light Feather " .. LIGHT_FEATHER .. ": "
                .. ValueText(glob, gPacked) .. note,
        }
    end)

    return table.concat(lines, "\n")
end

function M:Open()
    local ok, text = pcall(function() return self:Report() end)
    if not ok then
        text = "ToonAge Scroll Probe (read-only)\nERROR: " .. tostring(text)
    end
    if type(TA.ShowCopyWindow) == "function" then
        pcall(TA.ShowCopyWindow, TA, "ToonAge Scroll Probe", text)
    end
    return text
end

return M
