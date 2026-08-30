-- ToonAge/Core/State.lua (Classic)
-- Central display-state cache. Identical to Retail — uses only GetTime() and TA.Utils.

local TA = ToonAge
local U  = TA.Utils

local State = {}
TA.State = State

TA:RegisterModule("State", State)

local BARRED_OWNERS = {
    CombatState = "taint isolation",
}

local registry = {}
local entries = {}

function State:Register(key, owner, invalidatedBy)
    if type(key) ~= "string" or type(owner) ~= "string" then
        return false
    end
    if BARRED_OWNERS[owner] then
        local msg = ("%s may not use TA.State (%s)"):format(owner, BARRED_OWNERS[owner])
        if TA.ErrorLog then TA.ErrorLog:Log("State:Register", msg, key) end
        return false
    end
    local existing = registry[key]
    if existing and existing.owner ~= owner then
        local msg = ("key '%s' already owned by %s, refused claim by %s")
            :format(key, existing.owner, owner)
        if TA.ErrorLog then TA.ErrorLog:Log("State:Register", msg, "") end
        return false
    end
    local events = {}
    if type(invalidatedBy) == "table" then
        for _, event in ipairs(invalidatedBy) do
            events[event] = true
        end
    end
    registry[key] = { owner = owner, events = events }
    return true
end

function State:Set(key, value, owner)
    local reg = registry[key]
    if not reg then
        if TA.ErrorLog then
            TA.ErrorLog:Log("State:Set", "write to unregistered key '" .. tostring(key) .. "'", tostring(owner))
        end
        return false
    end
    if reg.owner ~= owner then
        if TA.ErrorLog then
            TA.ErrorLog:Log("State:Set",
                ("'%s' is owned by %s, refused write from %s"):format(key, reg.owner, tostring(owner)), "")
        end
        return false
    end
    if type(value) == "number" then
        value = U.SafeNum(value)
    end
    entries[key] = { value = value, stamp = GetTime() }
    return true
end

function State:Get(key)
    local e = entries[key]
    if not e then return nil, nil end
    return e.value, GetTime() - e.stamp
end

function State:Has(key)
    return entries[key] ~= nil
end

function State:Clear(key)
    entries[key] = nil
end

function State:Invalidate(event)
    if not event then return 0 end
    local cleared = 0
    for key, reg in pairs(registry) do
        if reg.events[event] and entries[key] then
            entries[key] = nil
            cleared = cleared + 1
        end
    end
    return cleared
end

function State:Wipe()
    entries = {}
end

State.SlashCommands = {
    state = function(self)
        local keys = {}
        for key in pairs(registry) do keys[#keys + 1] = key end
        table.sort(keys)
        if #keys == 0 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge State]|r No keys registered.")
            return
        end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge State (" .. #keys .. " keys) ━━━|r")
        for _, key in ipairs(keys) do
            local reg = registry[key]
            local e   = entries[key]
            if e then
                TA:Raw(TA.LOG.OUTPUT, ("  |cFF4AFF7A●|r %s |cFF888780(%s, %.1fs old)|r"):format(key, reg.owner, GetTime() - e.stamp))
            else
                TA:Raw(TA.LOG.OUTPUT, ("  |cFF888780○ %s (%s, empty)|r"):format(key, reg.owner))
            end
        end
    end,
}
