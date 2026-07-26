-- ToonAge/Core/State.lua
-- Central display-state cache.
--
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- WHY THIS IS NOT JUST A TABLE
--
-- The goal is "modules stop stepping on each other's data". An unowned shared
-- mutable table is the *mechanism* for that problem, not the cure -- it just
-- moves the collision somewhere less visible. So every key here has exactly one
-- registered writer. Everyone else reads. A write from anyone but the owner is
-- refused and logged rather than silently accepted.
--
-- INVALIDATION
--
-- Entries are invalidated by event name, declared when the key is registered.
-- This deliberately reuses the vocabulary of UI.lua's TAB_EVENTS rather than
-- inventing a parallel scheme: there are already three refresh mechanisms in
-- this addon (QueueUIRefresh's 0.15s coalescer, TAB_EVENTS' per-tab filter, and
-- CoordResolver's own zone-change ClearCache). A fourth that didn't line up
-- with them would produce the worst possible bug -- a tab that believes it
-- refreshed while reading a stale slot.
--
-- Init.lua invalidates BEFORE dispatching to modules, so a module handling an
-- event always recomputes from a cleared cache rather than reading its own
-- stale value from the previous tick.
--
-- TAINT
--
-- Numbers are scrubbed through U.SafeNum on write. On the 12.x PTR the WoW API
-- can hand back tainted "secret" numbers, and U.SafeNum's tonumber(tostring(v))
-- turns those -- and NaN, which stringifies to "-nan(ind)" and fails to convert
-- back -- into a plain fallback.
--
-- CombatState is BARRED from writing here entirely. Its private event frame
-- exists specifically so health/power/aura queries don't share a frame with
-- MapPins and CoordResolver (see CombatState.lua's Init). Letting it deposit
-- those values into a table those same modules read would rebuild the exact
-- contamination path that isolation was built to prevent, just through data
-- instead of through a frame.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local State = {}
TA.State = State

-- Registered as a module purely so `/ta state` is discoverable -- Init.lua finds
-- slash commands by iterating TA.modules. State has no Init and no OnEvent, so
-- UpdateModules skips it; it is Core infrastructure, not an event consumer, and
-- is invalidated by the dispatcher directly rather than through module dispatch.
TA:RegisterModule("State", State)

-- Owners that may never write here, with the reason. See the header.
local BARRED_OWNERS = {
    CombatState = "taint isolation -- health/power/aura must not enter shared state",
}

-- key -> { owner = string, events = { [EVENT] = true } }
local registry = {}

-- key -> { value = any, stamp = number }   (absent means "no valid value")
local entries = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- Registration
-- ═══════════════════════════════════════════════════════════════════════════════

--- Claim a key. Must be called before Set/Get, normally from a module's Init.
--- @param key string
--- @param owner string — module name, the only permitted writer
--- @param invalidatedBy table|nil — array of event names that clear this key.
---        nil or empty means the value is never invalidated by an event and the
---        owner is responsible for clearing it.
--- @return boolean ok
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
        -- Two modules claiming one key is the collision this file exists to
        -- prevent. Refuse the second claim rather than let the later loader win.
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- Read / write
-- ═══════════════════════════════════════════════════════════════════════════════

--- @param key string
--- @param value any — numbers are scrubbed through U.SafeNum
--- @param owner string — must match the registered owner
--- @return boolean ok
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

    -- Scrub scalars. Tables are stored as given -- deep-copying every write
    -- would cost more than it saves, so an owner storing a table of API values
    -- is responsible for having scrubbed them. Documented, not enforced.
    if type(value) == "number" then
        value = U.SafeNum(value)
    end

    entries[key] = { value = value, stamp = GetTime() }
    return true
end

--- @param key string
--- @return any value, number|nil age — nil if unset or invalidated
function State:Get(key)
    local e = entries[key]
    if not e then return nil, nil end
    return e.value, GetTime() - e.stamp
end

--- True if the key currently holds a valid value.
function State:Has(key)
    return entries[key] ~= nil
end

--- Drop one key's value. The registration survives.
function State:Clear(key)
    entries[key] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Invalidation
-- ═══════════════════════════════════════════════════════════════════════════════

--- Clear every entry that declared this event. Called from Init.lua's dispatcher
--- before modules run.
--- @param event string
--- @return number cleared
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

--- Drop every cached value. Registrations survive. Used by /ta reset and on
--- logout-ish transitions where everything is suspect.
function State:Wipe()
    entries = {}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Diagnostics
-- ═══════════════════════════════════════════════════════════════════════════════

State.SlashCommands = {
    state = function(self)
        local keys = {}
        for key in pairs(registry) do keys[#keys + 1] = key end
        table.sort(keys)

        if #keys == 0 then
            print("|cFFFFD100[ToonAge State]|r No keys registered.")
            return
        end

        print("|cFFFFD100━━━ ToonAge State (" .. #keys .. " keys) ━━━|r")
        for _, key in ipairs(keys) do
            local reg = registry[key]
            local e   = entries[key]

            local events = {}
            for event in pairs(reg.events) do events[#events + 1] = event end
            table.sort(events)
            local trigger = #events > 0 and table.concat(events, ", ") or "manual only"

            if e then
                print(("  |cFF4AFF7A●|r %s |cFF888780(%s, %.1fs old)|r"):format(key, reg.owner, GetTime() - e.stamp))
            else
                print(("  |cFF888780○ %s (%s, empty)|r"):format(key, reg.owner))
            end
            print(("     |cFF888780cleared by: %s|r"):format(trigger))
        end
        print("|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
    end,
}
