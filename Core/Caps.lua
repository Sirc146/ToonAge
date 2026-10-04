-- ToonAge/Core/Caps.lua  (all clients that ship the harvester)
--
-- The capability layer: the ONE place the harvester asks "what does this
-- client expose". Spec: Docs/SPEC_HARVEST_SENSOR_ARRAY.md section 4.2 (T1).
--
-- Why a separate layer: the harvester and its probe packs run on five clients
-- with five different API sets, and G3 (Docs/G3_API_GATE.md) will later own
-- runtime capability detection for the whole addon. So nothing in the
-- harvester detects APIs by hand -- no `_G[name]`, no `X and X.Y` checks, no
-- `type(fn) == "function"`. Everything asks this table, and when G3's resolver
-- lands it is plugged in with Caps.SetProvider("g3", ...) and no harvester or
-- pack changes. Tools/test_harvest_caps.py proves the swap and lints the packs.
--
-- Vocabulary is G3's (APIState): "present" | "missing" | "secret".
--   present -- the dotted path resolves to a value on this client
--   missing -- it does not (or a segment along the way is not a table)
--   secret  -- it exists but reads as a secret value right now (Midnight-era
--              clients, in combat). NEVER reported as missing: absent and
--              unreadable-at-the-moment are different facts.
--
-- Paths are dotted names resolved against _G one segment at a time, e.g.
-- "GetBuildInfo" or "Namespace.Function". This file names no client API on
-- purpose: it is generic, and the API manifest generator scans every shipped
-- file for namespaced calls.
--
-- Lua 5.1, no client calls except the optional issecretvalue, so the unit
-- tests run it unchanged outside the game.

local TA = ToonAge

local _G, type, pcall, pairs, select, tostring, unpack = _G, type, pcall, pairs, select, tostring, unpack
local gmatch = string.gmatch

local Caps = {}
TA.Caps = Caps

--- Who answers State(). "harvest-local" until G3 plugs its resolver in.
Caps.Provider = "harvest-local"

local seen    = {}   -- path -> last state answered this session (Seen())
local present = {}   -- path -> resolved value; only "present" is cached, since a
                     -- load-on-demand Blizzard addon can define a missing path later

-- issecretvalue is looked up per call, not captured at load: it is itself an
-- API this layer must not assume, and a test may install it after loading.
local function IsSecret(v)
    local f = _G.issecretvalue
    if type(f) ~= "function" then return false end
    local ok, r = pcall(f, v)
    return ok and r == true
end

local function Index(node, key) return node[key] end

--- Local resolution: value, state. Used by the default provider and by Fn,
--- Call and Get under any provider (G3 answers WHETHER, this finds WHAT).
local function Resolve(path)
    if type(path) ~= "string" or path == "" then return nil, "missing" end
    local hit = present[path]
    if hit ~= nil then return hit, "present" end
    local node = _G
    for seg in gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then return nil, "missing" end
        -- pcall: indexing a table with a protective metatable must not throw
        -- out of a probe.
        local ok, v = pcall(Index, node, seg)
        if not ok or v == nil then return nil, "missing" end
        if IsSecret(v) then return nil, "secret" end
        node = v
    end
    present[path] = node
    return node, "present"
end

local function LocalState(path)
    local _, state = Resolve(path)
    return state
end

local stateFn = LocalState

--- "present" | "missing" | "secret" for a dotted path. Recorded for Seen().
function Caps.State(path)
    local ok, state = pcall(stateFn, path)
    if not ok or (state ~= "present" and state ~= "missing" and state ~= "secret") then
        state = "missing"     -- a provider that errors or answers nonsense never
    end                       -- turns an unknown into "present"
    if type(path) == "string" then seen[path] = state end
    return state
end

--- The callable at `path` when the provider says present and the value is a
--- function; nil otherwise.
function Caps.Fn(path)
    if Caps.State(path) ~= "present" then return nil end
    local v = Resolve(path)
    if type(v) == "function" then return v end
    return nil
end

--- Value at `path` (constants such as a project ID), plus its state. A secret
--- comes back as the string "secret"; a missing path as nil.
function Caps.Get(path)
    local state = Caps.State(path)
    if state == "secret" then return "secret", state end
    if state ~= "present" then return nil, state end
    local v = Resolve(path)
    return v, state
end

-- Pack pcall's results, turning secret return values into the literal
-- "secret" so a store never records one as a number or as empty.
local function Results(ok, ...)
    local n = select("#", ...)
    if not ok then return false, "error: " .. tostring((...)) end
    local out = { ... }
    for i = 1, n do
        if IsSecret(out[i]) then out[i] = "secret" end
    end
    return true, unpack(out, 1, n)
end

--- ok, ... -- calls the function at `path`. Never throws.
---   missing/secret path -> false, "missing" | "secret"
---   the call errors     -> false, "error: <message>"
---   success             -> true, <every return value, nils kept>
function Caps.Call(path, ...)
    local state = Caps.State(path)
    if state ~= "present" then return false, state end
    local fn = Resolve(path)
    if type(fn) ~= "function" then return false, "missing" end
    return Results(pcall(fn, ...))
end

--- Every path asked this session and the state it got: { [path] = state }.
--- A copy, so a caller recording it into the store cannot alter this table.
function Caps.Seen()
    local copy = {}
    for k, v in pairs(seen) do copy[k] = v end
    return copy
end

--- Plug in another resolver (G3). `fn(path)` must return present / missing /
--- secret. Passing nil restores the local resolver.
function Caps.SetProvider(name, fn)
    if type(fn) == "function" then
        stateFn = fn
        Caps.Provider = tostring(name or "custom")
    else
        stateFn = LocalState
        Caps.Provider = "harvest-local"
    end
    seen = {}
end
