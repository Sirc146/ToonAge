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

-- Stat bars. ONE hue for every attribute: the split between what your level
-- gives you and what gear adds is tonal, not chromatic, so bar LENGTH stays the
-- only thing the eye compares across five rows. Green/orange/red stay reserved
-- for cap states (armour at 75%, a skill below its cap), so colour means one
-- thing everywhere in the addon. Class colour belongs on identity -- the name
-- in the sidebar -- not on data.
L.C_STAT_BASE = { 0.24, 0.44, 0.60 }   -- from level and race
L.C_STAT_GEAR = { 0.40, 0.75, 1.00 }   -- added by gear and buffs (C_ACCENT)

L.STATUS.stat = L.C_STAT_BASE

L.PAD  = 14   -- side padding
L.RPAD = 8    -- between rows

local FONT = "Fonts\\FRIZQT__.TTF"
local MONO = "Fonts\\ARIALN.TTF"

-- ─── Text Helpers ───────────────────────────────────────────────────────────

local function Colour(key)
    if type(key) == "table" then return key end
    return L.STATUS[key or "neutral"] or L.C_PRIMARY
end

-- The last line of defence against a secret reaching a frame.
--
-- A FontString holding tostring(secret) makes its frame's height secret, which
-- makes the scroll child's height secret, which makes Blizzard's own scroll
-- arithmetic raise and take the entire tab down with it (Forever, 2026-09-23 --
-- the full account is in Core/Utils.lua). Every row in the addon is built here,
-- so one test here covers every caller, including ones not written yet.
local SECRET_PLACEHOLDER = "|cFF6E6A62hidden|r"

local function IsSecretText(v)
    if not issecretvalue then return false end
    local ok, res = pcall(issecretvalue, v)
    return ok and res == true
end

-- ─── RECYCLING ──────────────────────────────────────────────────────────────
--
-- WoW never frees a frame, a FontString or a Texture. Every builder here used to
-- create new ones on every render, and Core/UI.lua's RebuildChild orphaned the
-- old ones -- so each tab refresh leaked everything it drew. Measured by
-- /ta test on 2026-09-28: 10-47 frames per Forever re-render, 307 per Retail
-- Guide re-render, plus the text and textures inside them.
--
-- Now each pane (the content and sidebar scroll children, marked _laPane by
-- RebuildChild) records what the builders handed out, and L:ReleasePane gives
-- it all back before the pane is rebuilt:
--   * row-type frames go to a per-kind pool on a hidden holder and are
--     re-parented and re-styled on the next Acquire. Their inner FontStrings
--     and Textures are built once with the frame and restyled, never recreated.
--   * FontStrings/Textures drawn straight onto a pane stay on that pane and go
--     back on its own free list (the pane itself is reused by UI.lua's pool).
-- Anything not drawn through this file is untouched and behaves as before.

local HOLDER = CreateFrame("Frame")
HOLDER:Hide()
local framePools = {}           -- kind -> array of free frames

--- The pane a builder is drawing into, or nil when `parent` is not inside one.
local function PaneOf(parent)
    local p, guard = parent, 0
    while p and guard < 8 do
        if p._laPane then return p end
        p = p.GetParent and p:GetParent()
        guard = guard + 1
    end
    return nil
end

local function Track(pane, obj)
    if not pane then return end
    local used = pane._laUsed
    if not used then used = {}; pane._laUsed = used end
    used[#used + 1] = obj
end

--- A FontString for a pooled frame's build(), with a font set immediately.
--- A pooled row can clear a string it never styled (DataRow's note on a row
--- that has never had one), and SetText on a FontString with no font raises
--- "Font not set" -- which took the Forever Talents and Spells tabs down on
--- 2026-09-28 until every built-in string got a font at creation.
local function NewFS(frame)
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, 10, "")
    return fs
end

--- A pooled frame of `kind`, built by build() the first time only.
local function AcquireFrame(kind, parent, build)
    local free = framePools[kind]
    local f = free and table.remove(free)
    if not f then
        f = build()
        f._laKind = kind
    end
    f:SetParent(parent)
    f:ClearAllPoints()
    f:Show()
    f:SetScript("OnEnter", nil)
    f:SetScript("OnLeave", nil)
    Track(PaneOf(parent), f)
    return f
end

--- A FontString or Texture drawn directly on `parent`. Reused from the pane's
--- free list when `parent` IS a pane; created fresh (old behaviour) otherwise.
local function TakeRegion(parent, kind, layer)
    local r
    if parent._laPane then
        local free = parent._laFree and parent._laFree[kind]
        r = free and table.remove(free)
    end
    if not r then
        if kind == "FontString" then
            r = parent:CreateFontString(nil, layer or "OVERLAY")
            r:SetFont(FONT, 10, "")
        else
            r = parent:CreateTexture(nil, layer or "ARTWORK")
        end
        r._laRegion = kind
    else
        r:SetDrawLayer(layer or (kind == "FontString" and "OVERLAY" or "ARTWORK"))
    end
    r:ClearAllPoints()
    r:SetWidth(0)
    r:SetHeight(0)
    r:Show()
    if parent._laPane then Track(parent, r) end
    return r
end

--- Give back everything the builders put on `pane`. Called by Core/UI.lua's
--- RebuildChild before it clears the pane.
function L:ReleasePane(pane)
    local used = pane and pane._laUsed
    if not used then return end
    for i = #used, 1, -1 do
        local o = used[i]
        used[i] = nil
        o:Hide()
        o:ClearAllPoints()
        if o._laKind then
            o:SetParent(HOLDER)
            local free = framePools[o._laKind]
            if not free then free = {}; framePools[o._laKind] = free end
            free[#free + 1] = o
        elseif o._laRegion then
            if o.SetText then o:SetText("") end
            pane._laFree = pane._laFree or {}
            local free = pane._laFree[o._laRegion]
            if not free then free = {}; pane._laFree[o._laRegion] = free end
            free[#free + 1] = o
        end
    end
end

--- Pool sizes, for /ta test and debugging.
function L:PoolStats()
    local out = {}
    for kind, free in pairs(framePools) do out[kind] = #free end
    return out
end

--- Apply text options to an existing FontString (shared by Text and the
--- pooled rows, whose inner strings are built once and restyled).
local function StyleText(fs, opts)
    fs:SetFont(opts.font or FONT, opts.size or 10, opts.flags or "")
    local c = Colour(opts.color)
    fs:SetTextColor(c[1], c[2], c[3], opts.alpha or 1)
    if opts.text ~= nil then
        fs:SetText(IsSecretText(opts.text) and SECRET_PLACEHOLDER or opts.text)
    end
    if opts.text == nil then fs:SetText("") end
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

local function Text(parent, opts)
    return StyleText(TakeRegion(parent, "FontString"), opts)
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


--- Hover tooltip on a pooled row, or none. Pooled frames keep their mouse
--- state between uses, so this always sets it explicitly.
local function RowTooltip(frame, title, lines)
    if lines then
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(title, 1, 0.82, 0)
            for _, line in ipairs(lines) do
                GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true)
            end
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        frame:EnableMouse(false)
    end
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

    local line = TakeRegion(parent, "Texture", "ARTWORK")
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

    local row = AcquireFrame("DataRow", parent, function()
        local f = CreateFrame("Frame", nil, HOLDER)
        f.label = NewFS(f)
        f.value = NewFS(f)
        f.note  = NewFS(f)
        return f
    end)
    row:SetSize(w, height)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    StyleText(row.label, { text = opts.label, size = 10, color = L.C_SECONDARY })
    row.label:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)

    StyleText(row.value, {
        text = opts.value, size = opts.valueSize or 11,
        flags = opts.bold and "OUTLINE" or "",
        color = opts.status, justify = "RIGHT",
    })
    row.value:ClearAllPoints()
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)

    if hasNote then
        StyleText(row.note, { text = opts.note, size = 9, color = opts.noteColor or L.C_DIM })
        row.note:ClearAllPoints()
        row.note:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -16)
        row.note:SetWidth(w)
        row.note:SetHeight(0)
        row.note:Show()
    else
        row.note:SetText("")
        row.note:Hide()
    end

    RowTooltip(row, opts.tooltipTitle or opts.label, opts.tooltip)
    return y - height - 2, row
end

--- A progress bar toward a cap, with the shortfall spelled out.
--- This is the core visual of the whole addon: current vs cap, and what to do.
function L:CapBar(parent, y, opts)
    y = math.floor(y)
    local w = self:Width(parent)

    local BAR_H  = 14
    local ROW_H  = 46

    local card = AcquireFrame("CapBar", parent, function()
        local f = CreateFrame("Frame", nil, HOLDER)
        f.title = NewFS(f)
        f.right = NewFS(f)
        f.track = CreateFrame("Frame", nil, f)
        f.fill  = f.track:CreateTexture(nil, "ARTWORK")
        f.note  = NewFS(f)
        return f
    end)
    card:SetSize(w, ROW_H)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    StyleText(card.title, { text = opts.label, size = 11, flags = "OUTLINE", color = L.C_PRIMARY })
    card.title:ClearAllPoints()
    card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)

    local status = opts.capped and "good" or (opts.urgent and "bad" or "warn")
    StyleText(card.right, { text = opts.value, size = 11, flags = "OUTLINE",
                            color = status, justify = "RIGHT" })
    card.right:ClearAllPoints()
    card.right:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)

    -- Track
    local track = card.track
    track:ClearAllPoints()
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

    local fill = card.fill
    fill:ClearAllPoints()
    fill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1, 1)
    fill:SetWidth(math.max(math.floor((w - 2) * pct), 1))
    local rgb = opts.fillRGB
    if type(rgb) == "table" then
        fill:SetColorTexture(rgb[1], rgb[2], rgb[3], 0.90)
    else
        local c = Colour(status)
        fill:SetColorTexture(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 0.85)
    end
    fill:Show()

    if not card._tickMark then
        card._tickMark = track:CreateTexture(nil, "OVERLAY")
        card._tickMark:SetColorTexture(0.910, 0.702, 0.353, 1)
    end
    if opts.tickAt then
        local x = math.floor((w - 2) * opts.tickAt)
        card._tickMark:ClearAllPoints()
        card._tickMark:SetSize(2, BAR_H - 2)
        card._tickMark:SetPoint("TOPLEFT", track, "TOPLEFT", math.max(x, 1), -1)
        card._tickMark:Show()
    else
        card._tickMark:Hide()
    end

    StyleText(card.note, { text = opts.note or "", size = 9, color = opts.capped and "good" or "dim" })
    card.note:ClearAllPoints()
    card.note:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -33)
    card.note:SetWidth(w)
    card.note:SetHeight(0)

    RowTooltip(card, opts.label, opts.tooltip)
    return y - ROW_H - L.RPAD
end

--- The shared maximum a group of stat bars is drawn against.
---
--- ONE denominator for the whole group, not one per row: per-row rounding makes
--- 49 and 51 draw at 98% and 51%, which the eye reads as "twice the stat".
--- Rounded UP to the next 50 so the axis is a round number, floored at 50 so a
--- level-1 character does not get a 20-wide axis, and never shrinks within a
--- session -- a buff falling off must not resize every bar on the sheet.
---
--- The scale is a DRAWING decision. It is never printed as a value and never
--- described as a cap: primary attributes have no cap in this game, and the
--- number beside each bar is always the real one.
--- @param values table list of numbers (nils are skipped)
--- @param previous number|nil the scale used last render, to keep it sticky
--- @return number
function L:StatScale(values, previous)
    local top = 0
    for _, v in pairs(values or {}) do
        local n = tonumber(v)
        if n and n > top then top = n end
    end
    local scale = math.max(50, math.ceil(top / 50) * 50)
    if previous and previous > scale then scale = previous end
    return scale
end

--- A stat as a bar against a shared, rounded scale.
---
--- The FILL is the real value. The faded remainder is headroom to the group's
--- scale and means nothing on its own -- it exists so the rows are comparable.
---
--- opts.base: the portion from level and race. When present the fill is drawn
--- in two tones, solid for base and lighter for what gear and buffs add, which
--- answers "how much of this is my gear?" without a second row of text.
---
--- Every anchor is TOPLEFT plus a computed offset. Nothing anchors to a right
--- edge: right-anchored text is what currently renders blank on the Character
--- tab, and a new component is the wrong place to inherit that.
--- @return number nextY, table row
function L:StatBar(parent, y, opts)
    y = math.floor(y)
    local w = self:Width(parent)

    local ROW_H   = 22
    local BAR_H   = 12
    local LABEL_W = math.min(110, math.floor(w * 0.28))
    local VALUE_W = 64
    local GAP     = 8
    local barW    = math.max(w - LABEL_W - VALUE_W - GAP * 2, 40)

    local row = AcquireFrame("StatBar", parent, function()
        local f = CreateFrame("Frame", nil, HOLDER)
        f.label = NewFS(f)
        f.track = CreateFrame("Frame", nil, f)
        f.fill  = f.track:CreateTexture(nil, "ARTWORK")
        f.extra = f.track:CreateTexture(nil, "ARTWORK")
        f.text  = NewFS(f)
        return f
    end)
    row:SetSize(w, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    StyleText(row.label, { text = opts.label, size = 10, color = L.C_SECONDARY })
    row.label:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -3)
    row.label:SetWidth(LABEL_W)
    row.label:SetHeight(0)

    local track = row.track
    track:ClearAllPoints()
    track:SetSize(barW, BAR_H)
    track:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_W + GAP, -2)
    if TA._ApplyBackdrop then
        TA._ApplyBackdrop(track, 0.10, 0.09, 0.08, 1.00, 0.28, 0.26, 0.22, 1.00)
    end

    local value = tonumber(opts.value)
    local scale = tonumber(opts.scale)
    row.fill:Hide()
    row.extra:Hide()

    if value and scale and scale > 0 then
        local inner = barW - 2
        local total = math.min(math.max(value / scale, 0), 1)
        local base  = tonumber(opts.base)
        local basePct = (base and base >= 0 and base <= value) and (base / scale) or total

        local cBase = Colour(opts.color or "stat")
        local fill = row.fill
        fill:ClearAllPoints()
        fill:SetPoint("TOPLEFT",    track, "TOPLEFT",    1, -1)
        fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1,  1)
        fill:SetWidth(math.max(math.floor(inner * basePct), 1))
        fill:SetColorTexture(cBase[1], cBase[2], cBase[3], 0.90)
        fill:Show()

        if base and value > base and total > basePct then
            local g = L.C_STAT_GEAR
            local extra = row.extra
            extra:ClearAllPoints()
            extra:SetPoint("TOPLEFT",    fill, "TOPRIGHT",    0, 0)
            extra:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
            extra:SetWidth(math.max(math.floor(inner * (total - basePct)), 1))
            extra:SetColorTexture(g[1], g[2], g[3], 0.90)
            extra:Show()
        end
    end

    -- The real number, right-justified inside a fixed-width box whose LEFT edge
    -- is computed -- same look as a right anchor, without depending on the
    -- parent's right edge being where we think it is.
    StyleText(row.text, {
        text = opts.text or (value and tostring(value)) or "|cFF6E6A62n/a|r",
        size = 11, flags = "OUTLINE", color = opts.status, justify = "RIGHT",
    })
    row.text:ClearAllPoints()
    row.text:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_W + GAP + barW + GAP, -3)
    row.text:SetWidth(VALUE_W)
    row.text:SetHeight(0)

    RowTooltip(row, opts.tooltipTitle or opts.label, opts.tooltip)
    return y - ROW_H - 2, row
end

-- Profession colours.
--
-- The game defines none, so these are OUR convention -- and they are the same
-- one GatherTracker already draws with (herb green, ore brown, skinning red),
-- so a node on the map and a bar on this tab agree. Keyed on the ENGLISH skill
-- name because that is what a lookup can be written against; the client hands
-- back a LOCALISED name, so a non-English client falls through to the neutral
-- stat colour rather than mis-colouring a row. Localised keys can be added per
-- locale when someone runs one and reports the strings.
L.PROFESSION_COLORS = {
    herbalism      = { 0.30, 0.90, 0.35 },
    mining         = { 0.85, 0.55, 0.20 },
    skinning       = { 0.80, 0.30, 0.30 },
    alchemy        = { 0.62, 0.36, 0.86 },
    blacksmithing  = { 0.58, 0.60, 0.65 },
    enchanting     = { 0.55, 0.45, 0.92 },
    engineering    = { 0.95, 0.60, 0.22 },
    leatherworking = { 0.65, 0.45, 0.28 },
    tailoring      = { 0.40, 0.60, 0.92 },
    cooking        = { 0.95, 0.75, 0.30 },
    fishing        = { 0.35, 0.65, 0.85 },
    ["first aid"]  = { 0.92, 0.92, 0.92 },
}

--- Colour for a profession by the name the client reported, or nil when the
--- name is not one we have a colour for (any localised client, or a profession
--- this game added). nil means "use the default" -- never a wrong colour.
function L:ProfessionColor(name)
    if type(name) ~= "string" then return nil end
    return L.PROFESSION_COLORS[name:lower()]
end

--- A stat bar split into the pieces that make it up.
---
--- Same rules as StatBar -- fill is the real total, the faded remainder is
--- headroom to the group's scale -- but the fill is drawn as consecutive
--- segments, one per contributor, in alternating tones of the ONE stat hue.
--- Alternating tone rather than hue keeps bar LENGTH the thing being compared;
--- five multi-coloured rows would turn a stat sheet into a colour chart.
---
--- Built for the gear tab: "Stamina 12" is a fact, and "9 of it is your chest"
--- is the fact worth having. Every segment is a number the client reported for
--- that item, so the breakdown assumes nothing the total does not.
---
--- opts.segments = { { value = n, label = "Chest" }, ... }
function L:StackBar(parent, y, opts)
    y = math.floor(y)
    local w = self:Width(parent)

    local ROW_H   = 22
    local BAR_H   = 12
    local LABEL_W = math.min(110, math.floor(w * 0.28))
    local VALUE_W = 64
    local GAP     = 8
    local barW    = math.max(w - LABEL_W - VALUE_W - GAP * 2, 40)

    local row = AcquireFrame("StackBar", parent, function()
        local f = CreateFrame("Frame", nil, HOLDER)
        f.label = NewFS(f)
        f.track = CreateFrame("Frame", nil, f)
        f.segs  = {}                 -- grows to the most segments ever drawn
        f.text  = NewFS(f)
        return f
    end)
    row:SetSize(w, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y)

    StyleText(row.label, { text = opts.label, size = 10, color = L.C_SECONDARY })
    row.label:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -3)
    row.label:SetWidth(LABEL_W)
    row.label:SetHeight(0)

    local track = row.track
    track:ClearAllPoints()
    track:SetSize(barW, BAR_H)
    track:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_W + GAP, -2)
    if TA._ApplyBackdrop then
        TA._ApplyBackdrop(track, 0.10, 0.09, 0.08, 1.00, 0.28, 0.26, 0.22, 1.00)
    end
    for _, tex in ipairs(row.segs) do tex:Hide() end

    local scale = tonumber(opts.scale)
    local segs  = type(opts.segments) == "table" and opts.segments or {}
    local total = 0
    for _, s in ipairs(segs) do total = total + (tonumber(s.value) or 0) end

    if scale and scale > 0 and total > 0 then
        local inner = barW - 2
        local c = Colour(opts.color or "stat")
        local prev, used = nil, 0
        for i, s in ipairs(segs) do
            local v = tonumber(s.value) or 0
            if v > 0 then
                used = used + 1
                local tex = row.segs[used]
                if not tex then
                    tex = track:CreateTexture(nil, "ARTWORK")
                    row.segs[used] = tex
                end
                tex:ClearAllPoints()
                local shade = (i % 2 == 1) and 1.00 or 0.70
                if prev then
                    tex:SetPoint("TOPLEFT",    prev, "TOPRIGHT",    0, 0)
                    tex:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", 0, 0)
                else
                    tex:SetPoint("TOPLEFT",    track, "TOPLEFT",    1, -1)
                    tex:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1,  1)
                end
                tex:SetWidth(math.max(math.floor(inner * (v / scale)), 1))
                tex:SetColorTexture(c[1] * shade, c[2] * shade, c[3] * shade, 0.90)
                tex:Show()
                prev = tex
            end
        end
    end

    StyleText(row.text, {
        text = opts.text or tostring(total), size = 11, flags = "OUTLINE",
        color = opts.status, justify = "RIGHT",
    })
    row.text:ClearAllPoints()
    row.text:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_W + GAP + barW + GAP, -3)
    row.text:SetWidth(VALUE_W)
    row.text:SetHeight(0)

    -- The breakdown lives in the tooltip: a bar on screen, a list of which
    -- slots contributed what on hover.
    if #segs > 0 then
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tostring(opts.label), 1, 0.82, 0)
            for _, s in ipairs(segs) do
                local v = tonumber(s.value) or 0
                if v > 0 then
                    GameTooltip:AddDoubleLine(tostring(s.label), tostring(v), 0.9, 0.9, 0.9, 1, 1, 1)
                end
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        row:EnableMouse(false)
    end

    return y - ROW_H - 2, row
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
    local line = TakeRegion(parent, "Texture", "ARTWORK")
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

-- ─── BUTTONS ────────────────────────────────────────────────────────────────
-- Tabs offer every action as a button. Slash commands still work for people
-- who like them, but no tab should require typing one.

--- Backdrop helper used by every hand-built button. Referenced by StatCaps and
--- PvPAdvisor as TA._ApplyBackdrop but never defined before 2026-09-16, so
--- those buttons rendered as bare text with no visible box.
function TA._ApplyBackdrop(frame, br, bg, bb, ba, er, eg, eb, ea)
    if not frame then return end
    if not frame.SetBackdrop and BackdropTemplateMixin and Mixin then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropSizeChanged then
            frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged)
        end
    end
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(br, bg, bb, ba or 1)
    frame:SetBackdropBorderColor(er or 0.3, eg or 0.28, eb or 0.24, ea or 1)
end

local function StyleButton(btn, lbl, active, hover, danger)
    if danger then
        -- Same red as a danger action (L.C_DANGER text, dark red fill).
        if hover then
            TA._ApplyBackdrop(btn, 0.18, 0.06, 0.05, 1, 1.00, 0.45, 0.40, 1)
            lbl:SetTextColor(1, 0.78, 0.74, 1)
        else
            TA._ApplyBackdrop(btn, 0.10, 0.04, 0.04, 1, 0.90, 0.30, 0.25, 1)
            lbl:SetTextColor(L.C_DANGER[1], L.C_DANGER[2], L.C_DANGER[3], 1)
        end
    elseif active then
        TA._ApplyBackdrop(btn, 0.16, 0.13, 0.02, 1, 1.00, 0.82, 0.00, 1)
        lbl:SetTextColor(1, 0.82, 0, 1)
    elseif hover then
        TA._ApplyBackdrop(btn, 0.13, 0.11, 0.08, 1, 0.60, 0.52, 0.30, 1)
        lbl:SetTextColor(0.92, 0.90, 0.87, 1)
    else
        TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1, 0.30, 0.28, 0.24, 1)
        lbl:SetTextColor(0.78, 0.74, 0.68, 1)
    end
end

--- Refresh the window after a button changed state.
function L:RefreshUI()
    if TA.UI and TA.UI.Refresh then TA.UI:Refresh() end
end

--- A row of buttons that wraps onto new lines when it runs out of width.
--- buttons: array of { label, onClick, active, danger, tooltip = { title, lines... } }
--- danger uses the red destructive style (Clear store, clear this character).
--- @return number y
function L:ButtonRow(parent, y, buttons, opts)
    opts = opts or {}
    y = math.floor(y)
    local w      = self:Width(parent)
    local h      = opts.height or 22
    local gap    = 6
    local x      = 0

    if opts.label then
        local fs = Text(parent, { text = opts.label, size = 9, color = L.C_DIM })
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD, y - 6)
        x = math.floor(fs:GetStringWidth() + 8)
    end

    for _, def in ipairs(buttons) do
        local btn = AcquireFrame("Button", parent, function()
            local f = CreateFrame("Button", nil, HOLDER)
            f.lbl = NewFS(f)
            return f
        end)
        local lbl = btn.lbl
        lbl:SetFont(FONT, opts.size or 9, "")
        lbl:SetText(def.label)
        lbl:ClearAllPoints()
        lbl:SetPoint("CENTER")
        local bw = math.floor(math.max(opts.minWidth or 54, lbl:GetStringWidth() + 18))
        if x > 0 and x + bw > w then
            x = 0
            y = y - h - 4
        end
        btn:SetSize(bw, h)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", L.PAD + x, y)
        btn:EnableMouse(true)
        StyleButton(btn, lbl, def.active, false, def.danger)

        btn:SetScript("OnClick", function()
            if def.onClick then
                local ok, err = pcall(def.onClick)
                if not ok and TA.ErrorLog then TA.ErrorLog:Log("Button " .. tostring(def.label), tostring(err), "") end
            end
        end)
        btn:SetScript("OnEnter", function(self)
            StyleButton(self, lbl, def.active, true, def.danger)
            if def.tooltip then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(def.tooltip[1], 1, 0.82, 0)
                for i = 2, #def.tooltip do
                    GameTooltip:AddLine(def.tooltip[i], 0.9, 0.9, 0.9, true)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            StyleButton(self, lbl, def.active, false, def.danger)
            GameTooltip:Hide()
        end)

        x = x + bw + gap
    end

    return y - h - 6
end

local ROLE_CHOICES = {
    { key = "auto",   label = "Auto"   },
    { key = "MELEE",  label = "Melee"  },
    { key = "RANGED", label = "Ranged" },
    { key = "CASTER", label = "Caster" },
    { key = "HEALER", label = "Healer" },
    { key = "TANK",   label = "Tank"   },
}

--- Role picker shared by every tab that depends on role (replaces /ta role).
function L:RoleButtons(parent, y)
    local current = (TA.charDB and TA.charDB.roleOverride) or "auto"
    local buttons = {}
    for _, choice in ipairs(ROLE_CHOICES) do
        buttons[#buttons + 1] = {
            label  = choice.label,
            active = (current == choice.key),
            tooltip = choice.key == "auto"
                and { "Auto role", "Read your role from class, talents, form and weapon." }
                or  { choice.label, "Use " .. choice.label:lower() .. " caps, weights and advice on every tab." },
            onClick = function()
                if TA.charDB then TA.charDB.roleOverride = choice.key end
                L:RefreshUI()
            end,
        }
    end
    return self:ButtonRow(parent, y, buttons, { label = "Role:" })
end

--- Switch to another tab (replaces "/ta caps for detail" style hints).
function L:OpenTab(tabID)
    if TA.UI and TA.UI.SetTab then TA.UI:SetTab(tabID) end
end
