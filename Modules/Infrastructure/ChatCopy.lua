-- ToonAge/Modules/Infrastructure/ChatCopy.lua
-- Dump a chat frame's scrollback into a selectable edit box.
--
-- Exists because the probe workflow is worthless if the output cannot leave the
-- game. /ta secretprobe and /ta apiprobe print 20+ lines that have to be read by
-- a human outside WoW, and retyping them by hand loses exactly the characters
-- that matter -- an ID transcribed as 466904 when it was 4669O4 is a bug hunt
-- that never terminates.
--
-- Markup is stripped rather than preserved: |cFFFFD100 sequences are noise in a
-- paste, and the hyperlink form |Htacommand:x|h[text]|h collapses to its display
-- text so a pasted line reads the way it looked on screen.
--
-- Taint: reads message text off the frame and writes it into our own EditBox.
-- Nothing protected, no combat restriction -- which matters, because the probes
-- this exists to capture are run mid-fight.

local TA = ToonAge
local M = TA.Modern

local ChatCopy = {}
TA:RegisterModule("ChatCopy", ChatCopy)

local frame

-- Markup stripping lives in Core/Utils.lua so the probe commands, which write
-- the same text into SavedVariables, cannot drift from what a copy produces.
local StripMarkup = TA.Utils.StripMarkup

--- Collect scrollback from a chat frame, oldest first.
local function Collect(chatFrame)
    local lines = {}
    -- Guarded rather than assumed: these are ScrollingMessageFrame methods and
    -- a UI replacement can hand back a frame that does not implement them. If
    -- that happens, say so loudly instead of returning an empty box, which is
    -- the silent-no-op failure this project keeps getting bitten by.
    if not chatFrame or not chatFrame.GetNumMessages or not chatFrame.GetMessageInfo then
        return nil, "Chat frame does not expose GetNumMessages/GetMessageInfo."
    end

    local ok, count = pcall(chatFrame.GetNumMessages, chatFrame)
    if not ok or not count then
        return nil, "GetNumMessages failed on this frame."
    end

    for i = 1, count do
        local mok, text = pcall(chatFrame.GetMessageInfo, chatFrame, i)
        if mok and text then
            lines[#lines + 1] = StripMarkup(text)
        end
    end
    return lines
end

local function CreateFrameOnce()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "ToonAgeChatCopy", UIParent, "BackdropTemplate")
    frame:SetSize(640, 420)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    M:ApplyBackdrop(frame, "panel")

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(M.FONT_HEADER, M.SIZE_H2, "OUTLINE")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("ToonAge Chat Copy")
    title:SetTextColor(unpack(M.CLR_TEXT_ACCENT))

    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(M.FONT_CAPTION, M.SIZE_CAPTION)
    hint:SetPoint("TOPLEFT", 12, -28)
    hint:SetText("Already selected - press Ctrl+C. Esc closes.")
    hint:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    local scroll = CreateFrame("ScrollFrame", "ToonAgeChatCopyScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -46)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(590)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    -- Read-only in effect: any edit is discarded on the next open anyway, but
    -- blocking cursor-driven changes keeps a stray keypress from corrupting the
    -- text between Ctrl+A and Ctrl+C.
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(self.taText or "")
        end
    end)
    scroll:SetScrollChild(edit)

    frame.edit = edit
    frame:Hide()
    return frame
end

--- Populate and show. Defaults to ChatFrame1 (the "General" tab).
--- @param chatFrame table|nil
function ChatCopy:Open(chatFrame)
    CreateFrameOnce()

    -- SELECTED_CHAT_FRAME tracks whichever tab the user last clicked, so the
    -- copy matches what they are looking at rather than always the first tab.
    local target = chatFrame or SELECTED_CHAT_FRAME or _G.ChatFrame1
    local lines, err = Collect(target)

    if not lines then
        TA:Print(TA.LOG.ERROR, "ChatCopy", err or "Could not read the chat frame.")
        return
    end
    if #lines == 0 then
        TA:Print(TA.LOG.OUTPUT, "ChatCopy", "That chat frame has no scrollback to copy.")
        return
    end

    local text = table.concat(lines, "\n")
    frame.edit.taText = text
    frame.edit:SetText(text)
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText() -- pre-selected, so it really is one Ctrl+C
end

function ChatCopy:Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        self:Open()
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────
-- Dispatched as fn(mod, args); args is unused.
ChatCopy.SlashCommands = {
    copychat = function()
        ChatCopy:Toggle()
    end,
    copy = function()
        ChatCopy:Toggle()
    end,
}

function ToonAge_ToggleChatCopy()
    ChatCopy:Toggle()
end
