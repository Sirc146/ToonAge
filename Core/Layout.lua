-- ToonAge/Core/Layout.lua (Anniversary — TBC Classic / Interface 20506)
-- Component factory. Every tab draws through these, nothing hand-rolls a row.
--
-- .rules.md asks new code to prefer a component factory over bespoke frames, and
-- Docs/NEXT_SESSION_BRIEF.md's bug list is entirely layout drift: overlapping
-- text, rows that shift when clicked, content taller than its scroll child.
-- Three rules here prevent all of that:
--
--   1. Every builder takes `y` and RETURNS the next `y`. Callers never compute
--      an offset themselves, so an offset can never be missed.
--   2. Every coordinate is math.floor()ed before SetPoint. Sub-pixel positions
--      blur fonts and tear borders (.kiro/steering/precision.md §4).
--   3. Finish(content, y) sets the scroll child's height from the SAME y the
--      builders returned, so the scrollable area always matches the content.
--
-- Colours and type sizes come from .rules.md's palette.

local TA = ToonAge
local U  = TA.Utils

local L = {}
TA.Layout = L

-- ─── Palette (.rules.md) ────────────────────────────────────────────────────
L.C_PRIMARY   = { 0.92, 0.90, 0.87 }
L.C_SECONDARY = { 0.62, 0.59, 0.55 }
L.C_ACCENT    = { 0.40, 0.75, 1.00 }
L.C_SUCCESS   = { 0.30, 0.92, 0.40 }
L.C_WARNING   = { 1.00, 0.65, 0.20 }
L.C_DANGER    = { 1.00, 0.35, 0.30 }
L.C_HEADER    = { 1.00, 0.82, 0.00 }
L.C_DIM       = { 0.45, 0.43, 0.40 }

L.STATUS = {
    good    = L.C_SUCCESS,
    warn    = L.C_WARNING,
    bad     = L.C_DANGER,
    neutral = L.C_PRIMARY,
    dim     = L.C_SECONDARY,
}

L.PAD  = 14   -- side padding
L.RPAD = 8    -- between rows

local FONT = "Fonts\\FRIZQT__.TTF"
local MONO = "Fonts\\ARIALN.TTF"

-- ─── Text Helpers ───────────────────────────────────────────────────────────

local function Colour(key)
    if type(key) == "table" then return key end
    return L.STATUS[key or "neutral"] or L.C_PRIMARY
end

local function Text(parent, opts)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(opts.font or FONT, opts.size or 10, opts.flags or "")
    local c = Colour(opts.color)
    fs:SetTextColor(c[1], c[2], c[3], opts.alpha or 1)
    if opts.text then fs:SetText(opts.text) end
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

--- Usable width for a row inside a scroll child.
--- GetWidth() returns 0 — not nil — on a frame whose layout has not resolved
--- yet, which is the case during the very first SetTab() before the window has
--- ever been shown. An `or` fallback does not catch 0, and the negative width
--- that results is a hard error out of SetWidth. Hence the explicit test.
local DEFAULT_CONTENT_WIDTH = 660

function L:Width(parent)
    local w = parent and parent:GetWidth()
    if not w or w <= 0 then w = DEFAULT_CONTENT_WIDTH end
    return math.floor(math.max(w - L.PAD * 2, 40))
end

-- ─── BUILDERS ───────────────────────────────────────────────────────────────
-- All take (parent, y, ...) and return the next y.

-- ── Structured rows ───────────────────────────────────────────────────
--- Gold section title with a rule under it.
function L:SectionHeader(parent, y, title, subtitle)
    y = math.floor(y)
    local fs = Text(parent, { text = title, size = 12, flags = "OUTLINE", color = L.C_HEADER })
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)
    y = y - 16

    if subtitle then
        local sub = Text(parent, { text = subtitle, size = 9, color = L.C_SECONDARY })
        sub:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)
        sub:SetWidth(self:Width(parent))
        sub:SetHeight(0)
        y = y - math.max(12, math.floor(sub:GetStringHeight() + 2))
    end

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  L.PAD, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -L.PAD, y)
    line:SetColorTexture(0.30, 0.28, 0.22, 0.60)

    return y - 10
end

--- Label on the left, value on the right, optional grey note underneath.
function L:DataRow(parent, y, opts)
    y = math.floor(y)
    local w = self:Width(parent)
    local hasNote = opts.note and opts.note ~= ""
    local height = hasNote and 32 or 20

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(w, height)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    local label = Text(row, { text = opts.label, size = 10, color = L.C_SECONDARY })
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)

    local value = Text(row, {
        text = opts.value, size = opts.valueSize or 11,
        flags = opts.bold and "OUTLINE" or "",
        color = opts.status, justify = "RIGHT",
    })
    value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)

    if hasNote then
        local note = Text(row, { text = opts.note, size = 9, color = L.C_DIM })
        note:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -16)
        note:SetWidth(w)
        note:SetHeight(0)
    end

    if opts.tooltip then
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.tooltipTitle or opts.label, 1, 0.82, 0)
            for _, line in ipairs(opts.tooltip) do
                GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return y - height - 2, row
end

--- A progress bar toward a cap, with the shortfall spelled out.
--- This is the core visual of the whole addon: current vs cap, and what to do.
function L:CapBar(parent, y, opts)
    y = math.floor(y)
    local w = self:Width(parent)

    local BAR_H  = 14
    local ROW_H  = 46

    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(w, ROW_H)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    local title = Text(card, { text = opts.label, size = 11, flags = "OUTLINE", color = L.C_PRIMARY })
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)

    local status = opts.capped and "good" or (opts.urgent and "bad" or "warn")
    local right = Text(card, { text = opts.value, size = 11, flags = "OUTLINE",
                               color = status, justify = "RIGHT" })
    right:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)

    -- Track
    local track = CreateFrame("Frame", nil, card)
    track:SetSize(w, BAR_H)
    track:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -16)
    if TA._ApplyBackdrop then
        TA._ApplyBackdrop(track, 0.10, 0.09, 0.08, 1.00, 0.28, 0.26, 0.22, 1.00)
    end

    local pct = 0
    if opts.cap and opts.cap > 0 then
        pct = math.min(math.max((opts.current or 0) / opts.cap, 0), 1)
    elseif opts.capped then
        pct = 1
    end

    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1, 1)
    fill:SetWidth(math.max(math.floor((w - 2) * pct), 1))
    local c = Colour(status)
    fill:SetColorTexture(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 0.85)

    local note = Text(card, { text = opts.note or "", size = 9, color = opts.capped and "good" or "dim" })
    note:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -33)
    note:SetWidth(w)
    note:SetHeight(0)

    if opts.tooltip then
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.label, 1, 0.82, 0)
            for _, line in ipairs(opts.tooltip) do
                GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true)
            end
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return y - ROW_H - L.RPAD
end

-- ── Text builders ─────────────────────────────────────────────────────
--- Free-form paragraph. Wraps, and the height it consumes is measured after
--- wrapping rather than assumed — assuming a fixed row height is what makes
--- text overlap when it wraps to two lines.
function L:Paragraph(parent, y, text, opts)
    opts = opts or {}
    y = math.floor(y)
    local fs = Text(parent, { text = text, size = opts.size or 10, color = opts.color or "dim" })
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)
    fs:SetWidth(self:Width(parent))
    fs:SetHeight(0)
    local h = math.max(12, math.floor(fs:GetStringHeight() + 2))
    return y - h - (opts.gap or 4)
end

--- A bullet list item.
function L:Bullet(parent, y, text, opts)
    opts = opts or {}
    y = math.floor(y)
    local w = self:Width(parent) - 12

    local dot = Text(parent, { text = opts.marker or "•", size = 10, color = opts.color or "dim" })
    dot:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    local fs = Text(parent, { text = text, size = 10, color = opts.color or L.C_PRIMARY })
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD + 12, y)
    fs:SetWidth(w)
    fs:SetHeight(0)

    local h = math.max(13, math.floor(fs:GetStringHeight() + 2))
    return y - h - 2
end

-- ── Layout primitives ────────────────────────────────────────────────
function L:Divider(parent, y)
    y = math.floor(y) - 4
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  L.PAD, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -L.PAD, y)
    line:SetColorTexture(0.25, 0.23, 0.20, 0.50)
    return y - 8
end

function L:Spacer(y, amount)
    return math.floor(y) - (amount or L.RPAD)
end

function L:EmptyState(parent, text)
    local fs = Text(parent, { text = text, size = 11, color = L.C_SECONDARY, justify = "LEFT" })
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, -20)
    fs:SetWidth(self:Width(parent))
    fs:SetHeight(0)
    parent:SetHeight(math.max(60, math.floor(fs:GetStringHeight() + 40)))
    return -20 - math.floor(fs:GetStringHeight() + 10)
end

--- Small coloured tag, drawn to the right of a row. Returns the frame so the
--- caller can anchor it; does not consume vertical space.
function L:Badge(parent, anchorTo, text, status)
    local c = Colour(status)
    local fs = Text(parent, { text = text, size = 9, color = c })
    fs:SetPoint("RIGHT", anchorTo, "RIGHT", 0, 0)
    return fs
end

--- MUST be the last call in every Render(). Sets the scroll child's height from
--- the y the builders actually produced, so the scrollbar range matches reality
--- even when content wrapped to more lines than expected.
function L:Finish(parent, y)
    parent:SetHeight(math.max(math.floor(math.abs(y) + 20), 40))
end

-- ─── SIDEBAR ────────────────────────────────────────────────────────────────

--- The identity block every tab shows in the sidebar. Kept in one place so six
--- tabs cannot drift apart.
function L:CharacterSidebar(side)
    if not side then return end
    local y = -12
    local sw = side:GetWidth()
    if not sw or sw <= 0 then sw = 202 end   -- see L:Width — 0, not nil, before layout resolves
    local w = math.floor(math.max(sw - 16, 40))

    local name = Text(side, { text = U.GetPlayerName(), size = 15, flags = "OUTLINE", color = L.C_HEADER })
    name:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    name:SetWidth(w)
    y = y - 20

    -- NOTE: raceToken is captured but never used below — only raceName renders.
    local raceToken, raceName = U.GetPlayerRace()
    local sub = Text(side, {
        text = string.format("Level %d %s", U.GetPlayerLevel(), U.GetPlayerClassLocalized()),
        size = 10, color = L.C_PRIMARY })
    sub:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    sub:SetWidth(w)
    y = y - 14

    local race = Text(side, { text = raceName, size = 10, color = L.C_SECONDARY })
    race:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    race:SetWidth(w)
    y = y - 18

    local specName = U.GetSpecLabel()
    local spec = Text(side, { text = specName, size = 10, color = L.C_ACCENT })
    spec:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    spec:SetWidth(w)
    spec:SetHeight(0)
    y = y - math.max(14, math.floor(spec:GetStringHeight() + 2))

    local ilvl, counted = U.GetAverageIlvl()
    local ilvlFS = Text(side, {
        text = string.format("Avg item level %d  |cFF555049(%d slots)|r", ilvl, counted),
        size = 9, color = L.C_SECONDARY })
    ilvlFS:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    ilvlFS:SetWidth(w)
    y = y - 18

    local role = U.InferRole()
    local roleFS = Text(side, { text = "Role: " .. role .. "  |cFF555049(inferred)|r",
                                size = 9, color = L.C_DIM })
    roleFS:SetPoint("TOPLEFT", side, "TOPLEFT", 10, y)
    roleFS:SetWidth(w)
    y = y - 20

    side:SetHeight(math.abs(y) + 10)
    return y
end
