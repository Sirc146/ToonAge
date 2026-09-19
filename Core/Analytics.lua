-- ToonAge/Core/Analytics.lua  (SHARED ENGINE — optional usage reporting)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS IS, AND WHAT IT IS NOT ──────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- ToonAge itself has no network access; no addon does. This file records a
-- handful of aggregate facts into the Wago App's analytics addon, IF the
-- player has that app installed with data sharing switched on. The Wago App,
-- not ToonAge, decides whether anything is ever uploaded.
--
-- Three gates, all of which must be open before a single value is recorded:
--   1. The TOC carries an X-Wago-ID (blank until the Wago project exists).
--   2. The Wago App's WagoAnalytics addon is present — otherwise the shim in
--      Libs/WagoAnalytics hands back empty functions.
--   3. TA.db.analytics is not false (Settings -> Usage reporting).
--
-- What is recorded is deliberately coarse: which client, which layout, which
-- optional behaviors are on, how many modules loaded, how many errors were
-- caught. No character name, realm, guild, spec, item, quest or coordinate —
-- nothing that could identify a player or a session. Wago's own rules forbid
-- that too, and the list below is the whole of it.
--
-- The point is to answer questions that change what gets built: which flavors
-- are actually used, whether anyone turns the guide off, how often Safe Mode
-- fires in the wild.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge or {}
ToonAge = TA

local A = {}
TA.Analytics = A

A.enabled  = false
A.reason   = "not started"
local sink          -- the recorder handed back by the shim

--- Has the player opted out in ToonAge's own settings?
local function OptedOut()
    return TA.db and TA.db.analytics == false
end

function A:Init()
    if OptedOut() then
        self.enabled, self.reason = false, "turned off in settings"
        return
    end

    local lib = LibStub and LibStub("WagoAnalytics", true)
    if not lib then
        self.enabled, self.reason = false, "shim not loaded"
        return
    end

    -- RegisterAddon reads X-Wago-ID from the TOC, so there is no project id
    -- hardcoded here: filling the TOC field is what switches this on.
    local ok, recorder = pcall(lib.RegisterAddon, lib, "ToonAge")
    if not ok or not recorder then
        self.enabled, self.reason = false, "no X-Wago-ID in the TOC"
        return
    end

    sink = recorder
    self.enabled, self.reason = true, "ready"
end

-- ── Recording helpers ─────────────────────────────────────────────────────
-- Each is a no-op when analytics are off, and every call is wrapped: a fault
-- inside someone else's addon must never surface as a ToonAge error.

function A:Switch(name, value)
    if not (self.enabled and sink) then return end
    pcall(sink.Switch, sink, name, value and true or false)
end

function A:Count(name, n)
    if not (self.enabled and sink) then return end
    pcall(sink.IncrementCounter, sink, name, n or 1)
end

function A:Set(name, n)
    if not (self.enabled and sink) then return end
    pcall(sink.SetCounter, sink, name, n or 0)
end

-- ── The whole of what gets recorded ───────────────────────────────────────
-- Called once per session, after modules have initialized.

function A:RecordSession()
    if not self.enabled then return end
    local db      = TA.db or {}
    local charDB  = (TA.charDB) or {}
    local tracker = charDB.tracker or {}

    -- Which client. One switch per flavor so the dashboard reads as a split.
    for _, flavor in ipairs({ "retail", "tbc", "mists", "vanilla", "cata", "wrath", "forever" }) do
        self:Switch("client:" .. flavor, TA.flavor == flavor)
    end

    -- Product shape: which optional behaviors people actually run with.
    self:Switch("layout:unified",      db.layout ~= "fragmented")
    self:Switch("safeMode",            db.safeMode == true)
    self:Switch("autoQuest",           tracker.autoQuest == true)
    self:Switch("autoEquip",           tracker.autoEquip == true)
    self:Switch("cutsceneSkip",        tracker.cutsceneSkip == true)
    self:Switch("zygor:installed",     (TA.Utils and TA.Utils.ZygorLoaded and TA.Utils.ZygorLoaded()) or false)
    self:Switch("zygor:deferring",     (TA.Utils and TA.Utils.DeferToZygor and TA.Utils.DeferToZygor()) or false)

    -- How much of the addon is alive on this client. A low module count on
    -- retail means ApiGuard or a profile is blocking something it should not.
    local loaded = 0
    for _ in pairs(TA.modules or {}) do loaded = loaded + 1 end
    self:Set("modules:loaded", loaded)

    -- Errors caught this session, as a crash signal we would otherwise only
    -- hear about if someone bothered to open an issue.
    local errs = TA.ErrorLog and TA.ErrorLog.entries
    if type(errs) == "table" then self:Set("errors:session", #errs) end
end

--- One line for /ta health, so the state is inspectable rather than magic.
function A:StatusLine()
    if self.enabled then
        return "Usage reporting: on (Wago App present, opted in)."
    end
    return "Usage reporting: off (" .. tostring(self.reason) .. ")."
end

return A
