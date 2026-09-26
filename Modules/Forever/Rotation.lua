-- ToonAge/Modules/Forever/Rotation.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of the spells you actually know, grouped the way the spellbook
-- groups them (General, your class line, the profession/secondary lines). For
-- each spell it shows the name and, when the client reports one, the rank.
--
-- WHY IT IS NOT A "ROTATION". Vanilla has no rotation system for an addon to
-- read — no spec, no priority list, no assisted-combat API. Retail's Rotation
-- tab reads an engine that does not exist on this client. The honest thing the
-- client CAN answer is "what is in your spellbook", so that is what this shows.
-- When Data/Forever eventually carries per-class ability priorities, an
-- advisory layer can sit on top; until then this reports facts only, the same
-- line every Forever tab holds.
--
-- API REALITY: two spellbook APIs exist by client generation. Forever runs the
-- Midnight API, so C_SpellBook is tried first (the exact shape used by
-- DataHarvester:ScanSpellbook, which is known to work here), with the legacy
-- GetNumSpellTabs / GetSpellBookItem* globals as a fallback. If neither
-- answers, the tab says so rather than rendering an empty list.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverRotation", M)

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

--- Read the spellbook into ordered line groups.
--- @return table lines  { { name=, spells={ {name=, rank=}, ... } }, ... }
--- @return boolean readable
local function ReadSpellbook()
    local lines = {}

    -- Modern path — the shape DataHarvester uses and that resolves on Forever.
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
       and C_SpellBook.GetSpellBookItemInfo then
        local numLines = Try(C_SpellBook.GetNumSpellBookSkillLines) or 0
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        for line = 1, numLines do
            local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if type(info) == "table" and info.numSpellBookItems then
                local group = { name = tostring(info.name or ("Line " .. line)), spells = {} }
                for i = info.itemIndexOffset + 1,
                        info.itemIndexOffset + info.numSpellBookItems do
                    local item = Try(C_SpellBook.GetSpellBookItemInfo, i, bank)
                    if type(item) == "table" and item.name then
                        -- itemType FLAG spells are the "future rank" ghosts; skip
                        -- them so the list is only what you can actually cast.
                        local isFuture = (item.itemType ~= nil)
                            and Enum and Enum.SpellBookItemType
                            and item.itemType == Enum.SpellBookItemType.FutureSpell
                        if not isFuture then
                            group.spells[#group.spells + 1] = {
                                name = tostring(item.name),
                                rank = item.subName and tostring(item.subName) or nil,
                            }
                        end
                    end
                end
                if #group.spells > 0 then lines[#lines + 1] = group end
            end
        end
        if #lines > 0 then return lines, true end
    end

    -- Legacy path.
    local numTabs = Try(GetNumSpellTabs) or 0
    for tab = 1, numTabs do
        local tabName, _, offset, numSpells = Try(GetSpellTabInfo, tab)
        local group = { name = tostring(tabName or ("Tab " .. tab)), spells = {} }
        for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
            local name, rank = Try(GetSpellBookItemName, i, "spell")
            if name then
                group.spells[#group.spells + 1] = {
                    name = tostring(name),
                    rank = (rank and rank ~= "") and tostring(rank) or nil,
                }
            end
        end
        if #group.spells > 0 then lines[#lines + 1] = group end
    end

    return lines, (#lines > 0)
end

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderIntro(content, y, total)
    y = L:SectionHeader(content, y, "Spellbook",
        string.format("%d spell%s known.", total, total == 1 and "" or "s"))
    y = L:Paragraph(content, y,
        "Vanilla has no rotation the client can hand out, so this lists what you "
        .. "actually know — cast priorities are yours to set. Grouped the way the "
        .. "spellbook groups them.")
    return y
end

local function RenderLines(content, y, lines)
    for idx, group in ipairs(lines) do
        if idx > 1 then y = L:Divider(content, y) end
        y = L:SectionHeader(content, y, group.name,
            string.format("%d", #group.spells))
        for _, sp in ipairs(group.spells) do
            y = L:DataRow(content, y, {
                label = sp.name,
                value = sp.rank or "",
                status = sp.rank and "dim" or "neutral",
            })
        end
    end
    return y
end

local function RenderUnreadable(content, y)
    y = L:SectionHeader(content, y, "Spellbook")
    y = L:Paragraph(content, y,
        "The spellbook could not be read on this client. Neither the C_SpellBook "
        .. "API nor the legacy spell-tab globals answered, so ToonAge shows nothing "
        .. "rather than a wrong or empty list.", { color = L.C_WARNING })
    y = L:Paragraph(content, y,
        "Worth reporting with /ta apiprobe — it maps which spellbook calls the "
        .. "client actually exposes.")
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    -- Same identity sidebar as the other Forever tabs, when available.
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local lines, readable = ReadSpellbook()

    local y = -8
    if not readable then
        y = RenderUnreadable(content, y)
    else
        local total = 0
        for _, g in ipairs(lines) do total = total + #g.spells end
        y = RenderIntro(content, y, total)
        y = L:Divider(content, y)
        y = RenderLines(content, y, lines)
    end
    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_TAB",
    "PLAYER_LEVEL_UP",
    "SKILL_LINES_CHANGED",
}

return M
