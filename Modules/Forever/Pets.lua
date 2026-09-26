-- ToonAge/Modules/Forever/Pets.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of the pet you currently have out: name, family, level, and — for
-- Hunters — happiness and the food types that keep it fed. It is a facts-only
-- panel, the same as every other Forever tab: what the client reports about the
-- active pet, no training advice, no "best pet" claims.
--
-- WHY IT IS CONDITIONAL. Only Hunters and Warlocks command a persistent pet on
-- this client, so the tab is hidden for every other class via a `condition`
-- flag on its tab def (Core/UI.lua TabConditions.hasPetClass). This module is
-- therefore only ever rendered for a class that can actually have a pet — but
-- it still guards for "no pet summoned right now" so a petless Hunter sees an
-- explanation, not a blank tab.
--
-- API REALITY: pet info comes from the Vanilla-era globals UnitExists("pet"),
-- UnitName / UnitLevel / UnitCreatureFamily on the "pet" unit, GetPetHappiness,
-- and GetPetFoodTypes. Every one is guarded; a call the client does not answer
-- shows as unknown rather than a wrong value.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverPets", M)

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

-- tonumber() on a secret RAISES, and pet health is read in combat -- exactly
-- when this client makes health secret (measured on the player 2026-09-23;
-- assume the pet is no different until shown otherwise). Test first, and treat
-- a secret as "no answer" so the row reads n/a instead of the tab dying.
local isSecret = _G.issecretvalue or function() return false end

local function Num(v)
    if v == nil then return nil end
    if isSecret(v) then return nil end
    return tonumber(tostring(v))
end

--- Show a value or "n/a" — never a fabricated zero.
local function Show(value, fmt)
    if value == nil then return "n/a" end
    if fmt then return string.format(fmt, value) end
    return tostring(value)
end

-- Happiness is an enum: 1 unhappy, 2 content, 3 happy. Only Hunter pets have it.
local HAPPINESS = {
    [1] = { text = "Unhappy", status = "bad"  },
    [2] = { text = "Content", status = "warn" },
    [3] = { text = "Happy",   status = "good" },
}

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderNoPet(content, y)
    y = L:SectionHeader(content, y, "Pet")
    y = L:Paragraph(content, y,
        "No pet is out right now. Summon or call your pet and reopen this tab — "
        .. "it reports on the pet the client currently has active.")
    return y
end

local function RenderPet(content, y)
    local name  = Try(UnitName, "pet")
    local level = Num(Try(UnitLevel, "pet"))
    local family = Try(UnitCreatureFamily, "pet")

    y = L:SectionHeader(content, y, name and tostring(name) or "Pet",
        family and tostring(family) or nil)

    if level and level > 0 then
        y = L:DataRow(content, y, { label = "Level", value = Show(level) })
    end
    if family then
        y = L:DataRow(content, y, { label = "Family", value = tostring(family) })
    end

    -- Health / power, when the client answers for the pet unit.
    local hp    = Num(Try(UnitHealth, "pet"))
    local hpMax = Num(Try(UnitHealthMax, "pet"))
    if hp and hpMax and hpMax > 0 then
        y = L:DataRow(content, y, {
            label = "Health",
            value = string.format("%d / %d", hp, hpMax),
        })
    end

    -- Happiness — Hunter pets only. GetPetHappiness returns nil for a Warlock
    -- demon, which is correct: the section simply does not appear for them.
    local happiness = Num(Try(GetPetHappiness))
    if happiness and HAPPINESS[happiness] then
        local h = HAPPINESS[happiness]
        y = L:DataRow(content, y, {
            label = "Happiness", value = h.text, status = h.status,
        })

        local foods = { Try(GetPetFoodTypes) }
        if foods[1] then
            y = L:DataRow(content, y, {
                label = "Feeds on",
                value = table.concat(foods, ", "),
                status = "dim",
            })
        end
    end

    return y
end

local function RenderFooter(content, y)
    y = L:Divider(content, y)
    y = L:Paragraph(content, y,
        "Facts only — what the client reports about the active pet. No taming, "
        .. "training or best-pet advice; ToonAge stays a readout.",
        { color = L.C_DIM })
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

    local hasPet = Try(UnitExists, "pet")

    local y = -8
    if hasPet then
        y = RenderPet(content, y)
    else
        y = RenderNoPet(content, y)
    end
    y = RenderFooter(content, y)
    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "UNIT_PET",
    "PET_UI_UPDATE",
    "UNIT_HAPPINESS",
    "PET_BAR_UPDATE",
    "PLAYER_PET_CHANGED",
}

return M
