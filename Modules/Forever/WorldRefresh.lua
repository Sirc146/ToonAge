-- ToonAge/Modules/Forever/WorldRefresh.lua  (WoW Forever beta)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS IS ──────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- The Forever beta pops "The world around you will refresh in 5 Minutes. Make
-- sure you are out of combat and in a safe area, or select refresh now."
-- (screenshot, 2026-09-30). Clicking Okay dismisses it and the countdown runs
-- on with nothing on screen. This module watches for that notice and:
--
--   * keeps a visible countdown until the refresh (movable, top of screen)
--   * warns at 60 and 10 seconds, louder if you are in combat
--   * logs every notice (time, zone, minutes) so how often it happens can be
--     read back: /ta refreshlog opens the log in the copy window
--
-- HOW IT IS SEEN -- NOT YET VERIFIED ON THE CLIENT. The notice looks like a
-- standard StaticPopup, so StaticPopup_Show is hooked (hooksecurefunc: after
-- the fact, never replacing it, so no taint) and the popup's text is matched
-- for "refresh" + "minute". The chat system channel is watched too, in case
-- the server also announces it there. If neither fires, the log stays empty
-- and /ta refreshlog says so -- and every popup key seen is recorded, so the
-- right one can be found and matched exactly on the next pass.
--
-- It never clicks anything. "Refresh Now" is the player's call.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local M = {}
TA:RegisterModule("ForeverWorldRefresh", M)

local LOG_MAX    = 50     -- refresh notices kept
local KEYS_MAX   = 30     -- distinct popup keys remembered, for diagnosis
local WARN_AT    = { 60, 10 }

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local isSecret = _G.issecretvalue or function() return false end
local function Text(v)
    if type(v) ~= "string" or isSecret(v) then return nil end
    return v
end

local function Store()
    if not TA.db then return nil end
    TA.db.worldRefresh = TA.db.worldRefresh or { log = {}, keys = {} }
    return TA.db.worldRefresh
end

--- "in 5 Minutes" / "in 30 seconds" -> seconds. nil if the text says neither.
local function ParseDelay(text)
    local lower = text:lower()
    local m = tonumber(lower:match("(%d+)%s*minute"))
    if m then return m * 60 end
    local s = tonumber(lower:match("(%d+)%s*second"))
    return s
end

local function IsRefreshNotice(text)
    local lower = text and text:lower()
    return lower and lower:find("refresh", 1, true) and lower:find("world", 1, true)
end

-- ─── COUNTDOWN ────────────────────────────────────────────────────────────

local bar   -- the countdown frame, built on first use

local function Warn(msg, loud)
    local inCombat = Try(InCombatLockdown)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        pcall(RaidNotice_AddMessage, RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r " .. msg
        .. (inCombat and " |cFFFF4444You are in combat.|r" or ""))
    if (loud or inCombat) and PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        pcall(PlaySound, SOUNDKIT.RAID_WARNING)
    end
end

local function BuildBar()
    local f = CreateFrame("Frame", "ToonAgeWorldRefreshBar", UIParent, "BackdropTemplate")
    f:SetSize(260, 26)
    local pos = Store() and Store().pos
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
    f:SetFrameStrata("HIGH")
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        f:SetBackdropColor(0.08, 0.06, 0.04, 0.9)
        f:SetBackdropBorderColor(1.0, 0.65, 0.2, 0.8)
    end
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        local s = Store()
        if s then s.pos = { p, rp, x, y } end
    end)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    f.text:SetPoint("CENTER")
    f:Hide()
    return f
end

local function StartCountdown(seconds)
    bar = bar or BuildBar()
    M._deadline = GetTime() + seconds
    M._warned = {}
    bar:Show()
    -- Throttled to 5 updates a second: the number only changes once a second.
    local acc = 0
    bar:SetScript("OnUpdate", function(self, elapsed)
        acc = acc + elapsed
        if acc < 0.2 then return end
        acc = 0
        local left = M._deadline - GetTime()
        if left <= 0 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end
        self.text:SetText(string.format("|cFFFFA633World refresh in %d:%02d|r",
            math.floor(left / 60), math.floor(left % 60)))
        for _, t in ipairs(WARN_AT) do
            if left <= t and not M._warned[t] then
                M._warned[t] = true
                Warn(string.format("World refresh in %d seconds -- get out of combat, somewhere safe.", t), t <= 10)
            end
        end
    end)
end

-- ─── DETECTION ────────────────────────────────────────────────────────────

local function Record(source, key, text)
    local s = Store()
    if not s then return end
    local delay = ParseDelay(text)
    local zone = Text(Try(GetRealZoneText)) or "?"
    table.insert(s.log, 1, {
        at = time and time() or nil, source = source, key = key,
        seconds = delay, zone = zone, text = text,
    })
    while #s.log > LOG_MAX do table.remove(s.log) end
    -- The same notice can arrive by popup and by chat; one countdown is enough.
    if delay and not (M._deadline and M._deadline - GetTime() > 0) then
        StartCountdown(delay)
    end
end

--- Safe format: a dialog's text can hold one %s, two, or a %d. string.format
--- raised "bad argument #3" here on QUEST_ACCEPT (2026-09-30 error log) when
--- the text wanted two args and only one was passed. pcall, both args.
local function Fill(text, a1, a2)
    if not text then return nil end
    if not text:find("%%") then return text end
    local ok, out = pcall(string.format, text, a1 ~= nil and tostring(a1) or "",
        a2 ~= nil and tostring(a2) or "")
    return ok and Text(out) or text
end

--- The text actually on screen. GENERIC_CONFIRMATION (seen 2026-09-30 20:24,
--- likely the refresh notice) carries its text in the data table, not in
--- StaticPopupDialogs[which].text, so the dialog template alone misses it.
--- The shown frame is read after the fact: StaticPopup1..4, matched by .which.
local function ShownText(which)
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and f.IsShown and f:IsShown() and f.which == which then
            local fs = f.text or f.Text
            if not fs and f.GetTextFontString then fs = Try(f.GetTextFontString, f) end
            local t = fs and fs.GetText and Text(Try(fs.GetText, fs))
            if t then return t end
        end
    end
    return nil
end

local function OnPopup(which, text1, text2, data)
    if type(which) ~= "string" then return end
    local s = Store()
    if s and not s.keys[which] then
        local n = 0
        for _ in pairs(s.keys) do n = n + 1 end
        if n < KEYS_MAX then s.keys[which] = time and time() or true end
    end
    local dialog = StaticPopupDialogs and StaticPopupDialogs[which]
    local candidates = {
        ShownText(which),
        Fill(Text(dialog and dialog.text), text1, text2),
        type(data) == "table" and Fill(Text(data.text), data.text_arg1, data.text_arg2) or nil,
        Text(text1),
    }
    for i = 1, 4 do
        local t = candidates[i]
        if t and IsRefreshNotice(t) then Record("popup", which, t) return end
    end
end

function M:OnEvent(event, msg)
    if event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_RAID_BOSS_EMOTE" then
        local text = Text(msg)
        if IsRefreshNotice(text) then Record("chat", event, text) end
    end
end

M.Events = { "CHAT_MSG_SYSTEM", "CHAT_MSG_RAID_BOSS_EMOTE" }

-- ─── LOG ──────────────────────────────────────────────────────────────────

function M:ShowLog()
    local s = Store()
    local out = { "ToonAge -- world refresh notices (newest first)", "" }
    if not s or #s.log == 0 then
        out[#out + 1] = "None recorded yet."
        out[#out + 1] = ""
        out[#out + 1] = "If a refresh notice appeared after this module was installed and is not"
        out[#out + 1] = "listed, it did not come through StaticPopup_Show or system chat. The popup"
        out[#out + 1] = "keys seen this far are below -- one of them may be it:"
    else
        local prev
        for _, e in ipairs(s.log) do
            local when = e.at and date and date("%Y-%m-%d %H:%M:%S", e.at) or "?"
            local gap = (prev and e.at) and string.format("  (%d min before the next)",
                math.floor((prev - e.at) / 60)) or ""
            out[#out + 1] = string.format("%s  %s  in %s  [%s %s]%s", when,
                e.seconds and (e.seconds .. "s notice") or "?", e.zone or "?",
                e.source or "?", tostring(e.key), gap)
            prev = e.at
        end
        out[#out + 1] = ""
        out[#out + 1] = "Notice text: " .. tostring(s.log[1].text)
        out[#out + 1] = ""
        out[#out + 1] = "Popup keys seen:"
    end
    local keys = {}
    for k in pairs((s and s.keys) or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    out[#out + 1] = (#keys > 0) and ("  " .. table.concat(keys, ", ")) or "  (none)"
    if TA.ShowCopyWindow then TA:ShowCopyWindow("ToonAge -- world refresh", table.concat(out, "\n")) end
end

M.SlashCommands = {
    refreshlog = function(self) self:ShowLog() end,
}

function M:Init()
    if not TA.IsForever then self._disabled = true return end
    if type(StaticPopup_Show) == "function" and hooksecurefunc then
        -- pcall: a detection fault must never surface as an error on a game popup.
        hooksecurefunc("StaticPopup_Show", function(...) pcall(OnPopup, ...) end)
    end
end

M._ParseDelay, M._IsRefreshNotice = ParseDelay, IsRefreshNotice

return M
