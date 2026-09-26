-- ToonAge/Modules/Combat/CombatReport.lua
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── THE WASTE AUDIT ───────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Reads what Modules/Combat/CombatRecorder.lua wrote down and answers the
-- question no other addon answers: which of your buttons are doing nothing.
--
-- The recorder keeps three sets, and the gaps between them ARE the findings:
--
--   known  \ bars    You own it and it is not on a bar. Forgotten, not unused.
--   bars   \ cast    It is on a bar and you have never pressed it. Dead space.
--   cast, no output  You press it and nothing measurable happens.
--
-- Nothing here is researched. Every number is a count of your own play, which
-- is why this can exist on WoW Forever -- where no verified game data does --
-- as readily as on Retail.
--
-- ── THE RULE THIS FILE LIVES BY ───────────────────────────────────────────
--
-- A conclusion from four casts is not a conclusion. Below MIN_CASTS an
-- ability is listed as "not enough casts to say" rather than judged, and
-- below MIN_FIGHTS the whole report refuses to rank anything at all. That is
-- the same rule the Character tab follows when it prints "n/a" instead of
-- zero: a confident wrong answer is worse than an honest blank, and this
-- report is the one place in the addon where a wrong answer would tell you to
-- unbind a button you need.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local M = {}
TA:RegisterModule("CombatReport", M)

local L   -- Core/Layout.lua, resolved at render

-- Below these, the report describes and does not conclude.
local MIN_FIGHTS = 5
local MIN_CASTS  = 10

-- An ability under this share of your total output, with enough casts to be
-- sure, is the "does nothing for me" case worth surfacing.
local LOW_SHARE = 0.01

local function Store()
    return TA.charDB and TA.charDB.combatLog or nil
end

local function SpellName(id, row)
    if row and row.name and row.name ~= tostring(id) then return row.name end
    local n
    if C_Spell and C_Spell.GetSpellName then
        local ok, v = pcall(C_Spell.GetSpellName, id); if ok then n = v end
    elseif GetSpellInfo then
        local ok, v = pcall(GetSpellInfo, id); if ok then n = v end
    end
    return n or ("spell " .. tostring(id))
end

--- Everything the report needs, computed once per render.
local function Analyse(s)
    local a = {
        total = 0, casts = 0,
        ranked = {},        -- { id, name, casts, output, share }
        forgotten = {},     -- known, not on a bar
        dead = {},          -- on a bar, never cast
        lowValue = {},      -- cast enough to judge, contributes almost nothing
        thin = {},          -- cast, but too few times to judge
    }

    for id, row in pairs(s.spells or {}) do
        local out = (row.damage or 0) + (row.healing or 0)
        a.total = a.total + out
        a.casts = a.casts + (row.casts or 0)
    end

    for id, row in pairs(s.spells or {}) do
        local out   = (row.damage or 0) + (row.healing or 0)
        local share = a.total > 0 and (out / a.total) or 0
        a.ranked[#a.ranked + 1] = {
            id = id, name = SpellName(id, row),
            casts = row.casts or 0, output = out, share = share,
        }
        if (row.casts or 0) > 0 then
            if (row.casts or 0) < MIN_CASTS then
                a.thin[#a.thin + 1] = { name = SpellName(id, row), casts = row.casts or 0 }
            elseif share < LOW_SHARE then
                a.lowValue[#a.lowValue + 1] = {
                    name = SpellName(id, row), casts = row.casts, share = share }
            end
        end
    end
    table.sort(a.ranked, function(x, y) return x.output > y.output end)

    -- Known but not on a bar.
    for id in pairs(s.known or {}) do
        if not (s.bars or {})[id] then
            a.forgotten[#a.forgotten + 1] = SpellName(id, (s.spells or {})[id])
        end
    end
    -- On a bar but never cast.
    for id in pairs(s.bars or {}) do
        local row = (s.spells or {})[id]
        if not row or (row.casts or 0) == 0 then
            a.dead[#a.dead + 1] = SpellName(id, row)
        end
    end
    table.sort(a.forgotten)
    table.sort(a.dead)
    table.sort(a.lowValue, function(x, y) return x.casts > y.casts end)
    table.sort(a.thin, function(x, y) return x.casts > y.casts end)
    return a
end

local function Pct(x) return string.format("%.1f%%", x * 100) end

local function Big(n)
    if n >= 1e9 then return string.format("%.1fb", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fm", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fk", n / 1e3) end
    return string.format("%d", n)
end

function M:Render(content, side)
    L = L or TA.Layout
    if not L then return end

    local s = Store()
    local y = -14

    if not s or (s.fights or 0) == 0 then
        y = L:SectionHeader(content, y, "Nothing recorded yet")
        y = L:Paragraph(content, y,
            "This tab fills itself in as you fight. Nothing to switch on and "
            .. "nothing to configure -- every fight longer than a few seconds "
            .. "is counted, and what you see here is a tally of your own play "
            .. "rather than anyone's opinion about your class.")
        L:Finish(content, y)
        return
    end

    local a = Analyse(s)
    local mins = (s.seconds or 0) / 60

    y = L:SectionHeader(content, y, "Recorded so far")
    y = L:DataRow(content, y, { label = "Fights",  value = tostring(s.fights or 0) })
    y = L:DataRow(content, y, { label = "Time in combat",
        value = string.format("%d min %d sec", math.floor(mins), (s.seconds or 0) % 60) })
    y = L:DataRow(content, y, { label = "Casts", value = tostring(a.casts),
        note = mins > 0 and string.format("%.1f per minute", a.casts / mins) or nil })
    y = L:DataRow(content, y, { label = "Total output", value = Big(a.total) })

    -- The honesty gate. Under this, describe; never conclude.
    if (s.fights or 0) < MIN_FIGHTS then
        y = L:Divider(content, y)
        y = L:Paragraph(content, y,
            string.format("|cFFFFD100Too early to draw conclusions.|r %d fight%s "
                .. "recorded; this report starts ranking abilities at %d. The counts "
                .. "above are real -- the judgements below are the part that needs a "
                .. "sample.", s.fights, s.fights == 1 and "" or "s", MIN_FIGHTS))
        L:Finish(content, y)
        return
    end

    -- ── What is actually carrying you ────────────────────────────────────
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Where your output comes from")
    local shown = 0
    for _, e in ipairs(a.ranked) do
        if e.output > 0 and shown < 10 then
            shown = shown + 1
            y = L:CapBar(content, y, {
                label   = e.name,
                value   = string.format("%s  ·  %s", Big(e.output), Pct(e.share)),
                current = e.output, cap = a.ranked[1].output,
                capped  = shown == 1,
                note    = string.format("%d cast%s", e.casts, e.casts == 1 and "" or "s"),
            })
        end
    end

    -- ── The three gaps ───────────────────────────────────────────────────
    if #a.dead > 0 then
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "On your bars, never pressed",
            "Bar space doing nothing. Either it belongs on a bar you forgot "
            .. "about, or it does not belong on a bar.")
        for _, name in ipairs(a.dead) do y = L:Bullet(content, y, name) end
    end

    if #a.lowValue > 0 then
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "Pressed often, contributes almost nothing",
            string.format("Cast at least %d times and still under %s of your "
                .. "output. Worth knowing WHY before removing any of them -- a "
                .. "debuff, an interrupt or a cooldown does its job without "
                .. "showing up as damage.", MIN_CASTS, Pct(LOW_SHARE)))
        for _, e in ipairs(a.lowValue) do
            y = L:DataRow(content, y, {
                label = e.name, value = Pct(e.share),
                note = string.format("%d casts", e.casts) })
        end
    end

    if #a.forgotten > 0 then
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "Known, but not on a bar",
            "You have these and cannot press them.")
        for _, name in ipairs(a.forgotten) do y = L:Bullet(content, y, name) end
    end

    if #a.thin > 0 then
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "Not enough casts to say",
            string.format("Under %d casts each. Listed so they are not mistaken "
                .. "for abilities this report has cleared.", MIN_CASTS))
        for _, e in ipairs(a.thin) do
            y = L:Bullet(content, y, string.format("%s  |cFF888780(%d)|r", e.name, e.casts))
        end
    end

    y = L:Divider(content, y)
    y = L:ButtonRow(content, y, {
        { label = "Reset recording", onClick = function()
            if M._confirmReset then
                if TA.charDB then TA.charDB.combatLog = nil end
                M._confirmReset = nil
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Combat recording cleared.")
            else
                M._confirmReset = true
            end
            if L.RefreshUI then L:RefreshUI() end
          end,
          tooltip = { "Reset recording",
                      "Throws away every fight recorded so far. Useful after a "
                      .. "respec or a new set of bars, when the old record "
                      .. "describes a character you no longer play." } },
    }, { label = M._confirmReset and "Click again to confirm:" or "" })

    L:Finish(content, y)
end

function M:Init() end
