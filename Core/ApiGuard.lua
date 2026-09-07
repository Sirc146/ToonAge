-- ToonAge/Core/ApiGuard.lua (Anniversary — TBC Classic / Interface 20506)
-- Resolves every API in Data/ApiManifest.lua against the running client.
-- Identical logic to Retail — works on any client.

-- ─── Module Setup & State ──────────────────────────────────────────────────

local TA = ToonAge
local Guard = {}
TA:RegisterModule("ApiGuard", Guard)

Guard.missing      = {}
Guard.missingNS    = {}
Guard.present      = 0
Guard.checked      = 0
Guard.hasRun       = false

-- ─── Name Resolution Helper ────────────────────────────────────────────────

local function Resolve(path)
    local ns, fn = path:match("^([%w_]+)%.([%w_]+)$")
    if ns then
        local nsTable = _G[ns]
        if type(nsTable) ~= "table" then
            return nil, ns
        end
        return nsTable[fn], nil
    end
    return _G[path], nil
end

-- ─── Probe · CountMissing · HasAPI ─────────────────────────────────────────

function Guard:Probe()
    wipe(self.missing)
    wipe(self.missingNS)
    self.present = 0
    self.checked = 0

    local manifest = TA.Data and TA.Data.ApiManifest
    if not manifest then
        TA:Print(TA.LOG.ERROR, "ApiGuard",
            "Data/ApiManifest.lua did not load — run gen_api_manifest and check the TOC.")
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
                if absentNS then self.missingNS[absentNS] = true end
            end
        end
    end

    self.hasRun = true
    return self:CountMissing()
end

function Guard:CountMissing()
    local n = 0
    for _ in pairs(self.missing) do n = n + 1 end
    return n
end

function TA:HasAPI(path)
    if not Guard.hasRun then return true end
    return Guard.missing[path] == nil
end

-- ─── Report ─────────────────────────────────────────────────────────────────

local function Report()
    -- FIXME: if the manifest failed to load, Probe() returns -1 without ever
    -- setting hasRun, so this branch re-runs it and falls straight through to
    -- CountMissing() on the freshly-wiped (empty) table below, printing
    -- "Nothing missing." — masking the load error Probe() already logged.
    if not Guard.hasRun then Guard:Probe() end

    local missing = Guard:CountMissing()
    TA:Printf(TA.LOG.OUTPUT, "ApiGuard", "%d of %d APIs resolved on this client.",
        Guard.present, Guard.checked)
    -- FIXME: GetBuildInfo() returns (version, build, date, tocversion); the
    -- labels below are swapped — "Client build" prints tocversion (index 4)
    -- and "interface" prints the version string (index 1), the opposite of
    -- what each label claims.
    TA:Printf(TA.LOG.OUTPUT, nil, "Client build |cFFFFFFFF%s|r  interface |cFFFFFFFF%s|r",
        tostring(select(4, GetBuildInfo())), tostring((select(1, GetBuildInfo()))))

    if missing == 0 then
        TA:Print(TA.LOG.OUTPUT, nil, "|cFF4AFF7ANothing missing.|r")
        return
    end

    local nsList = {}
    for ns in pairs(Guard.missingNS) do nsList[#nsList + 1] = ns end
    table.sort(nsList)
    if #nsList > 0 then
        TA:Printf(TA.LOG.OUTPUT, nil, "|cFFFF9A1A%d namespace(s) absent entirely:|r", #nsList)
        for _, ns in ipairs(nsList) do
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFF4444" .. ns .. "|r")
        end
    end

    local removed = {}
    for path, files in pairs(Guard.missing) do
        local ns = path:match("^([%w_]+)%.")
        if not ns or not Guard.missingNS[ns] then
            removed[#removed + 1] = { path = path, files = files }
        end
    end
    table.sort(removed, function(a, b) return a.path < b.path end)

    if #removed > 0 then
        TA:Printf(TA.LOG.OUTPUT, nil, "|cFFFF4444%d function(s) missing from a present namespace:|r", #removed)
        for _, e in ipairs(removed) do
            TA:Raw(TA.LOG.OUTPUT, string.format("  |cFFFF4444%s|r  |cFF888780%s|r",
                e.path, table.concat(e.files, ", ")))
        end
    end
end

-- ─── Init & Slash Commands ─────────────────────────────────────────────────

Guard.SlashCommands = {
    apiprobe = function() Report() end,
}

function Guard:Init()
    local missing = self:Probe()
    if missing > 0 then
        TA:Printf(TA.LOG.WARN, "ApiGuard",
            "%d API(s) unavailable on this client — |cFFFFD100/ta apiprobe|r for detail.", missing)
    end
end

return Guard
