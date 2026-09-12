-- ToonAge/Core/State.lua (Anniversary — TBC Classic / Interface 20506)
-- Central display-state cache. Identical to Retail — uses only GetTime() and TA.Utils.

-- ─── Module Setup & State ──────────────────────────────────────────────────

local TA = ToonAge
local U  = TA.Utils

local State = {}
TA.State = State

TA:RegisterModule("State", State)

-- Owners that may never write here, with the reason.
local BARRED_OWNERS = {
    CombatState = "taint isolation",
}

-- key -> { owner = string, events = { [EVENT] = true } }
local registry = {}
-- key -> { value = any, stamp = number }   (absent means "no valid value")
local entries = {}

-- ─── Registration ────────────────────────────────────────────────────────────

function State:Register(key, owner, invalidatedBy)
    if type(key) ~= "string" or type(owner) ~= "string" then
        return false
    end
    -- NOTE: enforcement of BARRED_OWNERS lives entirely here — a barred owner
    -- can never claim a key, so it can never reach the reg.owner == owner
    -- check in Set(). The write is still refused there, just reported under
    -- the generic "unregistered key" / "owned by someone else" message
    -- instead of naming the bar explicitly.
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

-- ─── Read / Write ────────────────────────────────────────────────────────────

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
    -- NOTE: U.SafeNum(value) is called with no explicit fallback, so it
    -- defaults to 0 on a failed conversion (tainted secret number, NaN,
    -- etc). That 0 is stored and stamped exactly like a legitimately-written
    -- zero — a reader has no way to tell "scrubbed from garbage" apart from
    -- "owner really did write 0".
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

-- WARN: an owner calling State:Set(key, nil, owner) stores a live entry whose
-- .value field is nil (entries[key] is a non-nil wrapper table). Has() checks
-- `entries[key] ~= nil`, so it reports true for that key while Get() returns
-- nil for the value — indistinguishable from an unset/invalidated key to any
-- caller that only looks at Get()'s first return.
function State:Has(key)
    return entries[key] ~= nil
end

function State:Clear(key)
    entries[key] = nil
end

-- ─── Invalidation ────────────────────────────────────────────────────────────

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

-- ─── Diagnostics ─────────────────────────────────────────────────────────────

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
