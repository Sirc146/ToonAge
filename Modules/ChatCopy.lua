-- ToonAge/Modules/ChatCopy.lua (Classic — MoP 5.4.x / Interface 50504)
-- Dump a chat frame's scrollback into a selectable edit box.
-- API-agnostic — works identically to the Retail version.
--
-- Strips markup (colour codes, hyperlinks, textures) and shows the plain text
-- in a selectable, copyable edit box. Ctrl+C to copy to system clipboard.

local TA = ToonAge
local U  = TA.Utils

local ChatCopy = {}
TA:RegisterModule("ChatCopy", ChatCopy)

local frame

local StripMarkup = U.StripMarkup

--- Collect scrollback from a chat frame, oldest first.
local function Collect(chatFrame)
    local lines = {}
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
    if frame then return frame end

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
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.06, 0.97)
    frame:SetBackdropBorderColor(0.35, 0.32, 0.28, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("|cFFFFD100ToonAge Chat Copy|r")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetFont(STANDARD_TEXT_FONT, 9, "")
    hint:SetPoint("TOPLEFT", 12, -28)
    hint:SetText("Already selected — press Ctrl+C. Esc closes.")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() frame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", "ToonAgeChatCopyScroll", frame,
                               "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -46)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(590)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    -- Prevent user edits from corrupting copy data
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(self.taText or "") end
    end)
    scroll:SetScrollChild(edit)

    frame.edit = edit
    frame:Hide()
    return frame
end

--- Populate and show. Defaults to the active chat frame tab.
--- @param chatFrame table|nil
function ChatCopy:Open(chatFrame)
    CreateFrameOnce()

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
    frame.edit:HighlightText()
end

function ChatCopy:Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        self:Open()
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────
ChatCopy.SlashCommands = {
    copychat = function() ChatCopy:Toggle() end,
    copy     = function() ChatCopy:Toggle() end,
}

function ToonAge_ToggleChatCopy()
    ChatCopy:Toggle()
end
