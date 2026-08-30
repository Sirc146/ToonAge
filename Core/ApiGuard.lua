-- ToonAge/Core/ApiGuard.lua
-- Resolves every API in Data/ApiManifest.lua against the running client.
--
-- Why this exists
-- ---------------
-- C_ClassTalents.GetExportString was removed in 12.1.0 and sat dead for weeks.
-- Nothing errored, because all four call sites were guarded:
--
--     if C_ClassTalents.GetExportString then ... end
--
-- The guard turned a removed API into a silent no-op, so the code that fills
-- every talent build string simply never ran and Data/Talents.lua stayed empty.
-- From inside the game that is indistinguishable from "there is no data yet".
--
-- The same shape of failure is what separates clients: Classic Era has no
-- C_Traits at all, and a module that needs it should say so rather than quietly
-- doing nothing. Both cases are one question -- did this name resolve? -- so
-- both get one answer here.
--
-- This module only measures. It does not disable anything yet; module gating
-- reads TA:HasAPI() once modules declare their requirements.

local TA = ToonAge
local Guard = {}
TA:RegisterModule("ApiGuard", Guard)

-- Results, populated by Probe(). Kept on the module rather than in the DB:
-- this is a fact about the running client, not a user setting, and it must be
-- recomputed every load rather than restored from a previous session's client.
Guard.missing = {} -- { ["C_Traits.Foo"] = { files } }
Guard.missingNS = {} -- { ["C_Traits"] = true }  whole namespace absent
Guard.present = 0
Guard.checked = 0
Guard.hasRun = false

-- Resolve "C_Traits.GetNodeInfo" or "GetItemInfo" against the global table.
--
-- Deliberately not using loadstring: a name from the manifest is data, and
-- compiling data as code to read it is a habit worth not forming. Two levels is
-- all the manifest ever produces.
local function Resolve(path)
    local ns, fn = path:match("^([%w_]+)%.([%w_]+)$")
    if ns then
        local nsTable = _G[ns]
        if type(nsTable) ~= "table" then
            return nil, ns -- namespace itself is absent
        end
        return nsTable[fn], nil
    end
    return _G[path], nil
end

-- ── Probe ─────────────────────────────────────────────────────────────────

--- Probe every manifest entry. Safe to call more than once.
--- @return number missingCount
function Guard:Probe()
    wipe(self.missing)
    wipe(self.missingNS)
    self.present = 0
    self.checked = 0

    local manifest = TA.Data and TA.Data.ApiManifest
    if not manifest then
        -- The manifest is generated; a missing one means the TOC is out of step
        -- with the repository, which is worth shouting about rather than
        -- silently reporting "0 problems".
        TA:Print(
            TA.LOG.ERROR,
            "ApiGuard",
            "Data/ApiManifest.lua did not load -- run Tools/gen_api_manifest.py and check the TOC."
        )
        return -1
    end

    for _, group in ipairs({ manifest.namespaced, manifest.globals }) do
        for path, files in pairs(group or {}) do
            self.checked = self.checked + 1
            local fn, absentNS = Resolve(path)
            if type(fn) == "function" then
                self.present = self.present + 1
            else
                self.missing[path] = files
                if absentNS then
                    self.missingNS[absentNS] = true
                end
            end
        end
    end

    self.hasRun = true
    return self:CountMissing()
end

function Guard:CountMissing()
    local n = 0
    for _ in pairs(self.missing) do
        n = n + 1
    end
    return n
end

--- Has this API resolved on the running client?
--- Modules will gate on this once they declare requirements. Returns true when
--- the probe has not run, so a caller can never be *more* restricted than the
--- client actually is by asking too early.
function TA:HasAPI(path)
    if not Guard.hasRun then
        return true
    end
    return Guard.missing[path] == nil
end

-- ── Report ────────────────────────────────────────────────────────────────
-- Everything here is LOG.OUTPUT: the player typed a command and must get an
-- answer regardless of the configured verbosity.

local function Report()
    if not Guard.hasRun then
        Guard:Probe()
    end

    local missing = Guard:CountMissing()
    TA:Printf(TA.LOG.OUTPUT, "ApiGuard", "%d of %d APIs resolved on this client.", Guard.present, Guard.checked)
    TA:Printf(
        TA.LOG.OUTPUT,
        nil,
        "Client build |cFFFFFFFF%s|r  interface |cFFFFFFFF%s|r",
        tostring(select(4, GetBuildInfo())),
        tostring((select(1, GetBuildInfo())))
    )

    if missing == 0 then
        TA:Print(TA.LOG.OUTPUT, nil, "|cFF4AFF7ANothing missing.|r")
        return
    end

    -- Whole absent namespaces first. On Classic this is most of the report, and
    -- listing 17 individual C_QuestLog functions would bury the one fact that
    -- matters: the namespace is not there.
    local nsList = {}
    for ns in pairs(Guard.missingNS) do
        nsList[#nsList + 1] = ns
    end
    table.sort(nsList)
    if #nsList > 0 then
        TA:Printf(TA.LOG.OUTPUT, nil, "|cFFFF9A1A%d namespace(s) absent entirely:|r", #nsList)
        for _, ns in ipairs(nsList) do
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFF4444" .. ns .. "|r")
        end
    end

    -- Then individual removals: the namespace exists but the function is gone.
    -- This is the GetExportString case, and it is the one that signals a patch
    -- broke something rather than that this is simply a different game.
    local removed = {}
    for path, files in pairs(Guard.missing) do
        local ns = path:match("^([%w_]+)%.")
        if not ns or not Guard.missingNS[ns] then
            removed[#removed + 1] = { path = path, files = files }
        end
    end
    table.sort(removed, function(a, b)
        return a.path < b.path
    end)

    if #removed > 0 then
        TA:Printf(TA.LOG.OUTPUT, nil, "|cFFFF4444%d function(s) missing from a present namespace:|r", #removed)
        for _, e in ipairs(removed) do
            TA:Raw(
                TA.LOG.OUTPUT,
                string.format("  |cFFFF4444%s|r  |cFF888780%s|r", e.path, table.concat(e.files, ", "))
            )
        end
    end
end

-- ── Init & Slash Commands ────────────────────────────────────────────────

Guard.SlashCommands = {
    apiprobe = function()
        Report()
    end,
}

function Guard:Init()
    -- Probe at Init rather than lazily on first command. The whole point is to
    -- know at login, before a module quietly does nothing all session.
    local missing = self:Probe()

    if missing > 0 then
        -- WARN, so it surfaces at the default log level. A healthy client says
        -- nothing; a client missing APIs says exactly one line and offers the
        -- detail on request.
        TA:Printf(
            TA.LOG.WARN,
            "ApiGuard",
            "%d API(s) unavailable on this client -- |cFFFFD100/ta apiprobe|r for detail.",
            missing
        )
    end
end

return Guard
