-- ToonAge/Modules/TestBar.lua
-- A clickable panel of every registered /ta command, for testing without typing.
--
-- Why this exists rather than a set of macros: the command list cannot be
-- enumerated statically. Only three commands are registered with a literal key
-- (`SlashCommands["auradump"]`); every other module builds its table as a
-- literal, so grepping the tree undercounts badly. TA:GetAllCommandNames()
-- reads the truth off the live registry, which means this panel picks up a new
-- command the moment its module registers one -- no list here to go stale, and
-- no macro slots consumed against the per-character cap.
--
-- Clicks route through TA:SlashCommand, the same entry point the chat handler
-- and the `tacommand:` hyperlinks already use, so a button and a typed command
-- are indistinguishable downstream.
--
-- Taint: every frame here is addon-created and every action is insecure
-- (printing, and Show/Hide on our own frames). Nothing calls into a protected
-- API, so this panel needs no combat lockout -- and adding one would be cargo
-- cult. The buttons deliberately stay live in combat, because the probes that
-- motivated this panel (/ta secretprobe, /ta auradump) must be run mid-fight.

local TA = ToonAge
local M  = TA.Modern

local TestBar = {}
TA:RegisterModule("TestBar", TestBar)

-- ── Layout constants ──────────────────────────────────────────────────────────
local BTN_W, BTN_H   = 104, 20
local BTN_GAP        = 4
local COLS           = 3
local PAD            = 10
local HEADER_H       = 24
local SECTION_GAP    = 6

-- ── Command classification ────────────────────────────────────────────────────
-- Only affects grouping and colour. A command absent from every set still gets
-- a button, under "Other" -- that fallback is what keeps this file from needing
-- an edit every time a module gains a command.
local CAT_PROBE  = "Probes & Diagnostics"
local CAT_PANEL  = "Panels"
local CAT_TOGGLE = "Toggles"
local CAT_OTHER  = "Other"
local CAT_DANGER = "Destructive"

local CATEGORY = {
    -- Probes: the measurement commands. These are the reason the panel exists.
    apiprobe    = CAT_PROBE,  secretprobe = CAT_PROBE,
    auradump    = CAT_PROBE,  talentscan  = CAT_PROBE,
    health      = CAT_PROBE,  errors      = CAT_PROBE,
    diagnose    = CAT_PROBE,  diag        = CAT_PROBE,

    -- Panels: open a tab. Cheap, idempotent, safe to mash.
    gear = CAT_PANEL, talents = CAT_PANEL, rotation = CAT_PANEL,
    prof = CAT_PANEL, pets    = CAT_PANEL, weekly   = CAT_PANEL,
    guide = CAT_PANEL, options = CAT_PANEL, open    = CAT_PANEL,
    help = CAT_PANEL, copychat = CAT_PANEL, copy   = CAT_PANEL,

    -- Toggles: flip a flag. Reversible by clicking again, so they are safe on a
    -- one-click surface even though they do change state.
    debug = CAT_TOGGLE, layout = CAT_TOGGLE, safemode = CAT_TOGGLE,
    toggle = CAT_TOGGLE, verbose = CAT_TOGGLE,
}

-- Commands that destroy data. `reset` nils ToonAgeDB and re-runs InitDB with no
-- confirmation of its own (Core/Init.lua:568) -- a stray click would wipe every
-- character's saved state. The panel supplies the confirmation the command
-- does not have.
local DESTRUCTIVE = {
    reset = "This wipes ToonAgeDB for ALL characters and re-initialises defaults.\n\nA UI reload is still required afterwards.",
}

local CATEGORY_ORDER = { CAT_PROBE, CAT_PANEL, CAT_TOGGLE, CAT_OTHER, CAT_DANGER }

local CATEGORY_COLOR = {
    [CAT_PROBE]  = M.CLR_TEXT_ACCENT,
    [CAT_PANEL]  = M.CLR_TEXT_PRIMARY,
    [CAT_TOGGLE] = M.CLR_TEXT_WARNING,
    [CAT_OTHER]  = M.CLR_TEXT_SECONDARY,
    [CAT_DANGER] = M.CLR_TEXT_DANGER,
}

-- ── Confirmation popup for destructive commands ───────────────────────────────
StaticPopupDialogs["TOONAGE_TESTBAR_CONFIRM"] = {
    text         = "|cFFFFD100ToonAge|r\n\n/ta %s\n\n%s",
    button1      = YES,
    button2      = CANCEL,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    -- Not exclusive: this must be able to appear over the ToonAge panel.
    OnAccept     = function(self, data) TA:SlashCommand(data) end,
}

-- ── Frame construction ────────────────────────────────────────────────────────
local frame          -- created lazily; most sessions never open this panel
local buttonPool = {}

--- Reposition the frame from saved coordinates, falling back to centre.
local function RestorePosition(f)
    local pos = TA.db and TA.db.testBar
    f:ClearAllPoints()
    if pos and pos.point and pos.x and pos.y then
        f:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function SavePosition(f)
    if not TA.db then return end
    TA.db.testBar = TA.db.testBar or {}
    local point, _, _, x, y = f:GetPoint()
    TA.db.testBar.point = point
    TA.db.testBar.x     = x
    TA.db.testBar.y     = y
end

--- Acquire a button from the pool, creating one only when the pool is dry.
--- Rebuilds happen on every Show, so pooling keeps that free after the first.
local function AcquireButton(parent, index)
    local btn = buttonPool[index]
    if btn then return btn end

    btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(BTN_W, BTN_H)
    M:ApplyBackdrop(btn, "input")

    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(M.FONT_BODY, M.SIZE_BODY)
    btn.label:SetPoint("CENTER")
    btn.label:SetJustifyH("CENTER")

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.40, 0.75, 1.00, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("/ta " .. (self.cmd or "?"), 1, 0.82, 0)
        if self.destructive then
            GameTooltip:AddLine("Destructive - asks for confirmation.", 1, 0.35, 0.30, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.28, 0.28, 0.32, 0.60)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(self)
        if not self.cmd then return end
        if self.destructive then
            local dialog = StaticPopup_Show("TOONAGE_TESTBAR_CONFIRM", self.cmd, DESTRUCTIVE[self.cmd])
            if dialog then dialog.data = self.cmd end
            return
        end
        TA:SlashCommand(self.cmd)
    end)

    buttonPool[index] = btn
    return btn
end

--- Group the live command list into ordered categories.
local function BuildGroups()
    local names = TA:GetAllCommandNames() or {}
    table.sort(names)

    local groups, seen = {}, {}
    for _, name in ipairs(names) do
        -- GetAllCommandNames walks every module's table, and two modules can
        -- legitimately expose the same alias; dedupe so one command yields one
        -- button rather than a silent duplicate row.
        if not seen[name] then
            seen[name] = true
            local cat = DESTRUCTIVE[name] and CAT_DANGER or (CATEGORY[name] or CAT_OTHER)
            groups[cat] = groups[cat] or {}
            table.insert(groups[cat], name)
        end
    end
    return groups
end

--- Lay the panel out from scratch. Called on every Show so a command registered
--- after the panel was last opened still appears.
local function Rebuild()
    local groups = BuildGroups()
    local y      = -(HEADER_H + PAD)
    local index  = 0

    -- Retire every pooled button first: a rebuild can produce fewer buttons
    -- than the last pass, and a stale one left shown would still be clickable.
    for _, btn in ipairs(buttonPool) do btn:Hide() end
    for _, hdr in ipairs(frame.headers or {}) do hdr:Hide() end
    frame.headers = frame.headers or {}
    local headerIndex = 0

    for _, cat in ipairs(CATEGORY_ORDER) do
        local list = groups[cat]
        if list and #list > 0 then
            headerIndex = headerIndex + 1
            local hdr = frame.headers[headerIndex]
            if not hdr then
                hdr = frame:CreateFontString(nil, "OVERLAY")
                hdr:SetFont(M.FONT_HEADER, M.SIZE_H3, "OUTLINE")
                frame.headers[headerIndex] = hdr
            end
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
            hdr:SetText(cat)
            local c = CATEGORY_COLOR[cat] or M.CLR_TEXT_PRIMARY
            hdr:SetTextColor(c[1], c[2], c[3], c[4])
            hdr:Show()

            y = y - (M.SIZE_H3 + SECTION_GAP)

            for i, name in ipairs(list) do
                index = index + 1
                local btn = AcquireButton(frame, index)
                local col = (i - 1) % COLS
                local row = math.floor((i - 1) / COLS)

                btn.cmd         = name
                btn.destructive = DESTRUCTIVE[name] ~= nil
                btn.label:SetText(name)
                local lc = btn.destructive and M.CLR_TEXT_DANGER or M.CLR_TEXT_PRIMARY
                btn.label:SetTextColor(lc[1], lc[2], lc[3], lc[4])

                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", frame, "TOPLEFT",
                    PAD + col * (BTN_W + BTN_GAP),
                    y - row * (BTN_H + BTN_GAP))
                btn:Show()
            end

            local rows = math.ceil(#list / COLS)
            y = y - rows * (BTN_H + BTN_GAP) - SECTION_GAP
        end
    end

    frame:SetSize(PAD * 2 + COLS * BTN_W + (COLS - 1) * BTN_GAP, math.abs(y) + PAD)
    frame.countText:SetText(index .. " commands")
end

local function CreateFrameOnce()
    if frame then return frame end

    frame = CreateFrame("Frame", "ToonAgeTestBar", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    M:ApplyBackdrop(frame, "panel")

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(M.FONT_HEADER, M.SIZE_H2, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    title:SetText("ToonAge Test Bar")
    title:SetTextColor(unpack(M.CLR_TEXT_ACCENT))

    frame.countText = frame:CreateFontString(nil, "OVERLAY")
    frame.countText:SetFont(M.FONT_CAPTION, M.SIZE_CAPTION)
    frame.countText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD - 18, -PAD - 2)
    frame.countText:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() frame:Hide() end)

    RestorePosition(frame)
    frame:Hide()
    return frame
end

-- ── Public API ────────────────────────────────────────────────────────────────
function TestBar:Toggle()
    CreateFrameOnce()
    if frame:IsShown() then
        frame:Hide()
    else
        Rebuild()          -- always current: rebuilt from the live registry
        RestorePosition(frame)
        frame:Show()
    end
end

function TestBar:Show()
    CreateFrameOnce()
    Rebuild()
    RestorePosition(frame)
    frame:Show()
end

-- ── Slash commands ────────────────────────────────────────────────────────────
-- Dispatched by TA:SlashCommand as fn(mod, args); neither argument is used.
TestBar.SlashCommands = {
    testbar = function() TestBar:Toggle() end,
    tb      = function() TestBar:Toggle() end,
}

-- Global wrapper so Bindings.xml can drive this from a keybind, matching the
-- ToonAge_TogglePanel / ToonAge_ToggleNavHud convention already in that file.
function ToonAge_ToggleTestBar()
    TestBar:Toggle()
end
