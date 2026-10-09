-- ToonAge/Modules/Infrastructure/BlockWatch.lua
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── FINDING (AND SURVIVING) THE "BLOCKED ACTION" POPUP ────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- When an addon calls a protected function without a hardware event (a real
-- key or mouse click), the client refuses and shows:
--
--     "<Addon> has been blocked from an action only available to the
--      Blizzard UI. You can disable this addon and reload the UI."
--
-- That refusal is NOT a Lua error -- pcall does not catch it -- so nothing in
-- the normal error log records what caused it. The only in-code signal is the
-- ADDON_ACTION_BLOCKED / ADDON_ACTION_FORBIDDEN events, which carry the name
-- of the addon and the protected function that was refused.
--
-- This module listens for those two events and keeps a small ring buffer of
-- what got blocked, so a player who hits the popup can run one command and see
-- the culprit instead of turning on WoW's taint log and reading a file.
--
-- Commands (all output goes to the copyable window, same as /ta errors and
-- /ta health, via TA:BeginReport):
--   /ta blocks     -- what got blocked this session
--   /ta doctor     -- the master check: module health + API probe + which
--                     action-taking features are on + captured blocks +
--                     recent errors, all in one report
--   /ta dontpanic  -- turn OFF the action-taking features and reload; saves
--                     what was on so it can be put back
--   /ta restore    -- re-enable exactly what /ta dontpanic turned off
--   /ta taintlog   -- turn on WoW's own taintLog and explain how to reproduce
--
-- Nothing here takes a protected action or touches a secure frame, so the
-- watcher itself can never be the thing that trips the block.

local TA = ToonAge

local BW = {}
TA:RegisterModule("BlockWatch", BW)

-- Ring buffer of captured blocks. Session-only: a block is a fact about what
-- just happened, not a setting to persist, and a stale block from three days
-- ago in a copy window is a false lead, not evidence.
BW.blocks = {}
local MAX_BLOCKS = 40

-- ── Action-taking features this build still ships ──────────────────────────
--
-- Everything protected that a player can switch on. AutoMount, AutoEquip and
-- CutsceneSkip were removed from the addon, so they are deliberately NOT here.
-- Each entry says where its enabled-state lives, because they do not all live
-- in the same table: the quest/vendor switches are per-character (charDB), and
-- reading the wrong one would report a feature as off when it is on.
--
--   label  -- what the player sees
--   get()  -- true when the feature is currently enabled
--   set(v) -- turn it on/off (used by dontpanic/restore)
-- Empty by design. ToonAge no longer ships ANY feature that takes a protected
-- action -- AutoMount, AutoEquip, CutsceneSkip, AutoQuest and VendorAssist have
-- all been removed, because on modern/Forever clients they only ever produced
-- the blocked-action popup. The list is kept (rather than deleted) so that if a
-- protected, toggleable feature is ever added back, /ta dontpanic and /ta
-- restore already know how to reach it -- just add an entry here.
local ACTION_FEATURES = {}

-- ── Capture ─────────────────────────────────────────────────────────────────

--- Record one blocked/forbidden action. WoW passes the tainting addon and the
--- protected function name as the event args; both are kept verbatim because
--- the whole point is to name them exactly.
-- Pull the first ToonAge frame out of a debugstack() dump. WoW's block events
-- often carry no function name (the /ta doctor "UNKNOWN()" case), so the stack
-- is what actually says which ToonAge file and line was executing when the
-- client refused the action -- the real culprit.
local function FirstToonAgeFrame(stack)
    if not stack then return nil end
    for line in stack:gmatch("[^\n]+") do
        -- e.g. "...AddOns/ToonAge/Modules/Automation/VendorAssist.lua:79: in function..."
        local path = line:match("(ToonAge[/\\][%w/\\_%.%-]+%.lua:%d+)")
        if path then
            path = path:gsub("\\", "/")
            -- Never report our own frames or the central event dispatcher: the
            -- block event is delivered on a fresh stack (eventFrame -> Init.lua
            -- dispatch -> BlockWatch), so those are always present and are never
            -- the culprit. Skipping them avoids BlockWatch blaming itself.
            if not path:find("BlockWatch%.lua")
               and not path:find("Core/Init%.lua") then
                return path
            end
        end
    end
    return nil
end

--- Record one blocked/forbidden action. WoW's args vary by client and by what
--- was blocked -- sometimes (addon, function), sometimes just (addon), sometimes
--- a frame/attribute name -- so every vararg is kept, plus a stack snapshot.
function BW:Record(event, ...)
    local n = select("#", ...)
    local args = {}
    for i = 1, n do args[i] = tostring(select(i, ...)) end

    -- debugstack(2,...) skips this function; the block-causing frame is deeper.
    -- Grab a generous window and let FirstToonAgeFrame find the relevant line.
    local stack = debugstack(2, 12, 0) or ""

    local entry = {
        time   = date("%H:%M:%S"),
        event  = event,
        addon  = args[1] or "?",             -- arg1, usually the addon name
        args   = args,                       -- everything WoW passed, verbatim
        func   = args[2],                    -- arg2 when present (function name)
        source = FirstToonAgeFrame(stack),   -- ToonAge file:line on the stack, if any
        stack  = stack,                      -- full snapshot for the copy window
        combat = InCombatLockdown() and true or false,
    }
    table.insert(self.blocks, entry)
    while #self.blocks > MAX_BLOCKS do
        table.remove(self.blocks, 1)
    end

    -- One quiet line at the time it happens. Prefer the stack source, since the
    -- function name is frequently missing.
    TA:Printf(TA.LOG.WARN, "BlockWatch",
        "Blocked action captured (%s). |cFFFFD100/ta blocks|r for detail.",
        entry.source or entry.func or entry.addon or "source unknown")
end

function BW:OnEvent(event, ...)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        self:Record(event, ...)
    end
end

-- ── Shared report helper ──────────────────────────────────────────────────
--
-- Everything routes through TA:BeginReport so short output stays in chat and
-- anything long opens in the selectable copy window -- the same behaviour as
-- /ta errors and /ta health. `force` opens the window regardless of length,
-- which the master check wants because it is always worth pasting whole.

local function NewReport(title, force)
    local r = TA.BeginReport and TA:BeginReport(title)
    if r and force then r.threshold = 0 end
    local say = function(text)
        if r then r:Add(text) else TA:Raw(TA.LOG.OUTPUT, text) end
    end
    return r, say
end

-- ── /ta blocks ─────────────────────────────────────────────────────────────

function BW:ReportBlocks(force, wantStack)
    local r, say = NewReport("ToonAge Blocked Actions", force or wantStack)

    -- "/ta blocks stack": dump the full captured stack of the newest block.
    -- This is the deepest detail for pinning a block whose function name WoW
    -- did not report.
    if wantStack then
        say("--- Blocked Action — full stack ---")
        local e = self.blocks[#self.blocks]
        if not e then
            say("Nothing captured this session.")
        else
            say(("[%s] addon=%s func=%s%s"):format(
                e.time, tostring(e.addon), tostring(e.func or "?"),
                e.combat and "  (in combat)" or ""))
            if e.source then say("source: " .. e.source) end
            say("")
            say(e.stack ~= "" and e.stack or "(no stack captured)")
        end
        say("------------------------------")
        if r then r:Finish() end
        return
    end

    say("--- ToonAge Blocked Actions ---")
    if #self.blocks == 0 then
        say("Nothing blocked this session.")
        say("If the popup appeared before login this session, reproduce it and run this again,")
        say("or use |cFFFFD100/ta taintlog|r to capture it through WoW's own log.")
    else
        say(("%d blocked action(s) captured this session (newest last):"):format(#self.blocks))
        for _, e in ipairs(self.blocks) do
            say(("  [%s] %s%s"):format(
                e.time,
                e.event == "ADDON_ACTION_FORBIDDEN" and "forbidden" or "blocked",
                e.combat and "  |cFFFF4444(in combat)|r" or ""))
            say(("      addon: %s   function: |cFFFFD100%s|r"):format(
                tostring(e.addon), tostring(e.func or "not reported")))
            -- The stack source is the useful part when the function name is
            -- missing: it points at the ToonAge line that was executing.
            if e.source then
                say("      source: |cFF4AFF7A" .. e.source .. "|r")
            end
            -- Any extra args WoW passed beyond addon/function, verbatim.
            if e.args and #e.args > 2 then
                local extra = {}
                for i = 3, #e.args do extra[#extra + 1] = e.args[i] end
                say("      args: " .. table.concat(extra, ", "))
            end
        end
        say("")
        say("Note: the block event is delivered AFTER the protected call returns, so a")
        say("'source' line is only shown when the culprit frame is still on the stack.")
        say("When function is 'not reported' and there is no source, WoW handed us nothing")
        say("useful -- use |cFFFFD100/ta taintlog|r, which records the real call in WoW's own log.")
    end
    say("------------------------------")

    if r then r:Finish() end
end

-- ── /ta doctor  (the master check) ──────────────────────────────────────────

function BW:Doctor()
    -- Always opens the window: this is a paste-into-a-bug-report command.
    local r, say = NewReport("ToonAge Doctor", true)

    say("--- ToonAge Doctor ---")
    say(("client %s · interface %s · build %s"):format(
        tostring(TA.flavor),
        tostring(select(1, GetBuildInfo())),
        tostring(select(4, GetBuildInfo()))))
    say("")

    -- 1. Module health
    say("-- Modules --")
    if TA.GetHealthReport then
        local entries = TA:GetHealthReport()
        local loaded, off, errored = 0, 0, 0
        for _, e in ipairs(entries) do
            if e.status == "loaded" then
                loaded = loaded + 1
            elseif e.status == "errored" then
                errored = errored + 1
                say(("  errored: %s — %s"):format(e.name, tostring(e.error)))
            else
                off = off + 1
            end
        end
        say(("  %d loaded · %d off · %d errored"):format(loaded, off, errored))
    else
        say("  (health report unavailable)")
    end
    say("")

    -- 2. API probe
    say("-- API probe --")
    local Guard = TA.GetRegisteredModule and TA:GetRegisteredModule("ApiGuard")
    if Guard and Guard.Probe then
        if not Guard.hasRun then Guard:Probe() end
        local missing = Guard.CountMissing and Guard:CountMissing() or 0
        say(("  %d of %d APIs resolved · %d missing"):format(
            Guard.present or 0, Guard.checked or 0, missing))
        if missing > 0 then
            local nsList = {}
            for ns in pairs(Guard.missingNS or {}) do nsList[#nsList + 1] = ns end
            table.sort(nsList)
            if #nsList > 0 then
                say("  absent namespaces: " .. table.concat(nsList, ", "))
            end
            local removed = {}
            for path in pairs(Guard.missing or {}) do
                local ns = path:match("^([%w_]+)%.")
                if not ns or not (Guard.missingNS and Guard.missingNS[ns]) then
                    removed[#removed + 1] = path
                end
            end
            table.sort(removed)
            for _, path in ipairs(removed) do
                say("  missing function: " .. path)
            end
        end
    else
        say("  (ApiGuard not present on this client)")
    end
    say("")

    -- 3. Action-taking features -- the ones that can trip the block
    say("-- Action features (protected) --")
    if #ACTION_FEATURES == 0 then
        say("  none — ToonAge ships no features that take a protected action.")
    else
        local anyOn = false
        for _, feat in ipairs(ACTION_FEATURES) do
            local on = feat.get()
            if on then anyOn = true end
            say(("  %s: %s"):format(feat.label, on and "|cFF4AFF7AON|r" or "|cFF888780off|r"))
        end
        if anyOn then
            say("  Something above is ON. If you are hitting the block, |cFFFFD100/ta dontpanic|r turns these off.")
        else
            say("  All off — none of ToonAge's protected features are active.")
        end
    end
    say("")

    -- 4. Captured blocks
    say("-- Blocked actions this session --")
    if #self.blocks == 0 then
        say("  none captured")
    else
        for _, e in ipairs(self.blocks) do
            say(("  [%s] addon=%s func=%s%s"):format(
                e.time, tostring(e.addon), tostring(e.func or "?"),
                e.combat and " (in combat)" or ""))
            if e.source then
                say("      source: " .. e.source)
            end
        end
    end
    say("")

    -- 5. Recent errors (from the same log /ta errors shows)
    say("-- Recent errors --")
    if TA.ErrorLog and TA.ErrorLog.GetLog then
        local log = TA.ErrorLog:GetLog()
        if #log == 0 then
            say("  none recorded")
        else
            local start = math.max(1, #log - 9)
            say(("  %d total; showing last %d:"):format(#log, #log - start + 1))
            for i = start, #log do
                local e = log[i]
                say(("  [%s] %s: %s"):format(
                    tostring(e.time), tostring(e.source), tostring(e.msg):sub(1, 200)))
            end
        end
    else
        say("  (error log unavailable)")
    end
    say("-----------------------")

    if r then r:Finish() end
end

-- ── /ta dontpanic  and  /ta restore ─────────────────────────────────────────
--
-- dontpanic turns every protected feature off and remembers which were on, so
-- restore can put back exactly that set rather than blindly enabling all of
-- them (which could switch on something the player never used). The saved set
-- lives in TA.db so it survives the reload dontpanic triggers.

function BW:DontPanic()
    local r, say = NewReport("ToonAge — Don't Panic", true)
    say("--- Don't Panic ---")

    local saved = {}
    local turnedOff = 0
    for _, feat in ipairs(ACTION_FEATURES) do
        if feat.get() then
            saved[feat.label] = true
            feat.set(false)
            turnedOff = turnedOff + 1
            say("  turned off: " .. feat.label)
        end
    end

    if TA.db then TA.db.blockWatchRestore = saved end

    if turnedOff == 0 then
        say("  Nothing was on. All protected features are already off.")
        say("------------------")
        if r then r:Finish() end
        return
    end

    say(("  %d feature(s) off. Saved so |cFFFFD100/ta restore|r can put them back."):format(turnedOff))
    say("  Reloading the UI to apply...")
    say("------------------")
    if r then r:Finish() end
    C_Timer.After(0.5, function() ReloadUI() end)
end

function BW:Restore()
    local r, say = NewReport("ToonAge — Restore", true)
    say("--- Restore ---")

    local saved = TA.db and TA.db.blockWatchRestore
    if not saved or not next(saved) then
        say("  Nothing to restore — /ta dontpanic has not turned anything off.")
        say("--------------")
        if r then r:Finish() end
        return
    end

    local turnedOn = 0
    for _, feat in ipairs(ACTION_FEATURES) do
        if saved[feat.label] then
            feat.set(true)
            turnedOn = turnedOn + 1
            say("  re-enabled: " .. feat.label)
        end
    end

    if TA.db then TA.db.blockWatchRestore = nil end

    say(("  %d feature(s) restored. Reloading the UI to apply..."):format(turnedOn))
    say("--------------")
    if r then r:Finish() end
    C_Timer.After(0.5, function() ReloadUI() end)
end

-- ── /ta taintlog ─────────────────────────────────────────────────────────────
--
-- WoW's own capture. "taint" is Blizzard's term: the CVar is taintLog and the
-- file is Logs/taint.log. This just turns it on and explains the loop, because
-- the taint log catches blocks this addon-side watcher can miss (a block that
-- fires before BlockWatch has initialised, or one with no event args).

function BW:TaintLog()
    local r, say = NewReport("ToonAge — Taint Log", true)
    say("--- WoW Taint Log ---")

    local ok = pcall(function() SetCVar("taintLog", "1") end)
    if ok then
        say("  WoW's taint log is now |cFF4AFF7AON|r (level 1).")
    else
        say("  Could not set the taintLog CVar automatically. Run this yourself:")
        say("    |cFFFFD100/console taintLog 1|r")
    end

    say("")
    say("  To capture the block:")
    say("    1. |cFFFFD100/reload|r")
    say("    2. Reproduce the action that shows the popup.")
    say("    3. Fully log out (not just /reload) so the file is flushed.")
    say("    4. Open this file in a text editor:")
    say("       |cFF888780World of Warcraft\\<version>\\Logs\\taint.log|r")
    say("  Look for lines with 'blocked' or 'ToonAge' — the addon and function")
    say("  named there is the source.")
    say("")
    say("  Turn it back off with |cFFFFD100/console taintLog 0|r when done (it is verbose).")
    say("--------------------")
    if r then r:Finish() end
end

-- ── Slash commands ────────────────────────────────────────────────────────────
-- Dispatched as fn(mod, args) by Core/Init.lua.
BW.SlashCommands = {
    blocks    = function(self, args)
        local sub = ((args or ""):match("^(%S*)") or ""):lower()
        self:ReportBlocks(false, sub == "stack")
    end,
    doctor    = function(self) self:Doctor() end,
    dontpanic = function(self) self:DontPanic() end,
    restore   = function(self) self:Restore() end,
    taintlog  = function(self) self:TaintLog() end,
}

-- ── Init ──────────────────────────────────────────────────────────────────────

function BW:Init()
    -- These two events are not in Core/Init.lua's route table, so an unrouted
    -- event is broadcast to every module's OnEvent -- registering them here is
    -- enough for this module to receive them.
    TA:RegisterEvent("ADDON_ACTION_BLOCKED")
    TA:RegisterEvent("ADDON_ACTION_FORBIDDEN")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r BlockWatch module loaded.")
    end
end

return BW
