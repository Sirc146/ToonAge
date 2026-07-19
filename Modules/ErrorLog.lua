-- ToonAge/Modules/ErrorLog.lua
-- Captures all ToonAge Lua errors into a persistent log stored in SavedVariables.
-- View in-game with /ta errors, or copy from WTF/Account/.../SavedVariables/ToonAge.lua
--
-- Features:
--   • Hooks into pcall wrappers in Init.lua (InitModules, UpdateModules)
--   • Captures addon-wide errors via a custom error handler
--   • Stores last 200 errors with timestamp, module, message, stack
--   • /ta errors — prints recent errors to chat
--   • /ta errors clear — wipes the log
--   • /ta errors copy — opens a copyable edit box with full log text
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local EL = {}
TA:RegisterModule("ErrorLog", EL)

-- ── Constants ─────────────────────────────────────────────────────────────────
local MAX_LOG_SIZE = 200
local ADDON_PREFIX = "ToonAge"

-- ── State ─────────────────────────────────────────────────────────────────────
EL.copyFrame = nil

-- ── Core logging function ─────────────────────────────────────────────────────

--- Log an error entry. Called from Init.lua pcall wrappers and the global handler.
--- @param source string — module name or "Global"
--- @param msg string — error message
--- @param stack string|nil — stack trace
function EL:Log(source, msg, stack)
    if not TA.db then return end
    TA.db.errorLog = TA.db.errorLog or {}

    local entry = {
        time   = date("%Y-%m-%d %H:%M:%S"),
        epoch  = time(),
        source = source or "Unknown",
        msg    = tostring(msg or ""),
        stack  = stack or "",
    }

    table.insert(TA.db.errorLog, entry)

    -- Trim to max size (remove oldest)
    while #TA.db.errorLog > MAX_LOG_SIZE do
        table.remove(TA.db.errorLog, 1)
    end
end

--- Get the error log table.
function EL:GetLog()
    return (TA.db and TA.db.errorLog) or {}
end

--- Get error count.
function EL:GetCount()
    return #self:GetLog()
end

--- Clear the log.
function EL:Clear()
    if TA.db then
        TA.db.errorLog = {}
    end
end

--- Format the log as a copyable string.
function EL:FormatLog()
    local log = self:GetLog()
    if #log == 0 then return "No errors recorded." end

    local lines = { "=== ToonAge Error Log (" .. #log .. " entries) ===" }
    for i, entry in ipairs(log) do
        lines[#lines + 1] = string.format("\n[%d] %s | %s", i, entry.time, entry.source)
        lines[#lines + 1] = "  " .. entry.msg
        if entry.stack and entry.stack ~= "" then
            lines[#lines + 1] = "  Stack: " .. entry.stack
        end
    end
    return table.concat(lines, "\n")
end

-- ── Copy frame (scrollable edit box for copying log text) ─────────────────────

function EL:ShowCopyFrame()
    if not self.copyFrame then
        local f = CreateFrame("Frame", "TAErrorLogCopyFrame", UIParent, "BackdropTemplate")
        f:SetSize(600, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        f:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
        f:SetBackdropBorderColor(0.55, 0.40, 0.08, 1)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        title:SetText("|cFFFFD100ToonAge Error Log|r  (Ctrl+A to select, Ctrl+C to copy)")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local scroll = CreateFrame("ScrollFrame", "TAErrorLogScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 40)

        local editBox = CreateFrame("EditBox", "TAErrorLogEditBox", scroll)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        editBox:SetWidth(scroll:GetWidth() - 10)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(editBox)

        -- Clear button
        local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        clearBtn:SetSize(80, 22)
        clearBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
        clearBtn:SetText("Clear Log")
        clearBtn:SetScript("OnClick", function()
            EL:Clear()
            editBox:SetText("Log cleared.")
        end)

        -- Count label
        local countLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        countLbl:SetFont(STANDARD_TEXT_FONT, 10, "")
        countLbl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 14)
        f.countLbl = countLbl

        f.editBox = editBox
        self.copyFrame = f
    end

    -- Populate with current log
    local text = self:FormatLog()
    self.copyFrame.editBox:SetText(text)
    self.copyFrame.countLbl:SetText(self:GetCount() .. " errors")
    self.copyFrame:Show()
    self.copyFrame.editBox:HighlightText()
    self.copyFrame.editBox:SetFocus()
end

-- ── Global error handler ──────────────────────────────────────────────────────
-- Hooks into WoW's error handler to capture ToonAge-related errors specifically.

local function IsOurError(msg)
    if not msg then return false end
    return msg:find("ToonAge") or msg:find("/ToonAge/") or msg:find("\\ToonAge\\") or msg:find("%[TA%]")
end

local originalHandler = geterrorhandler()

local function ToonAgeErrorHandler(msg)
    -- Capture ALL ToonAge errors
    if IsOurError(msg) then
        local stack = debugstack(2, 6, 0) or ""
        EL:Log("Global", msg, stack)
    else
        -- Also check the stack trace for ToonAge references
        local stack = debugstack(2, 6, 0) or ""
        if stack:find("ToonAge") or stack:find("/ToonAge/") then
            EL:Log("Global (stack)", msg, stack)
        end
    end
    -- Always call the original handler too
    if originalHandler then
        return originalHandler(msg)
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function EL:Init()
    -- Ensure the log table exists
    if TA.db then
        TA.db.errorLog = TA.db.errorLog or {}
    end

    -- Install our error handler
    seterrorhandler(ToonAgeErrorHandler)
end

-- ── Slash commands ────────────────────────────────────────────────────────────

EL.SlashCommands = {
    errors = function(self)
        local log = self:GetLog()
        if #log == 0 then
            print("|cFFFFD100[ToonAge]|r ✓ No errors recorded. Everything is working!")
            return
        end

        print("|cFFFFD100━━━ ToonAge Error Log (" .. #log .. " total) ━━━|r")
        for i, e in ipairs(log) do
            local shortMsg = e.msg:sub(1, 150)
            print(string.format("  |cFF888780%s|r |cFFFF8800%s|r |cFFFF4444%s|r",
                e.time, e.source, shortMsg))
        end
        print("|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cFF888780/ta errors copy = copyable window  |  /ta errors clear = wipe log|r")

        -- Auto-open the copy window if there are many errors
        if #log > 10 then
            self:ShowCopyFrame()
        end
    end,

    ["errors clear"] = function(self)
        self:Clear()
        print("|cFFFFD100[ToonAge]|r Error log cleared.")
    end,

    ["errors copy"] = function(self)
        self:ShowCopyFrame()
    end,
}

-- ── Public API for other modules ──────────────────────────────────────────────
-- Init.lua can call TA.ErrorLog:Log() directly from pcall wrappers.

-- Make accessible globally on the TA table for cross-module access
TA.ErrorLog = EL
