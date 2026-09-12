-- ToonAge/Modules/Character/Rotation.lua (Anniversary — TBC Classic / 20506)
-- Single-target PvE ability priority / rotation reference for your CURRENT
-- spec — the panel view of Data/TBCRotations.lua. Auto-detects your spec
-- from live talent points (same U.GetTalentSummary() the Talents tab and
-- sidebar already use) and shows that spec's DPS/HPS/TPS priority list.
--
-- This is a static reference, not a live "next 3" suggester that watches
-- your buffs/cooldowns in real time — that's a bigger separate project,
-- deliberately out of scope for this pass (confirmed with the user before
-- building). AoE/cleave variants and PvP rotations aren't covered either —
-- single-target PvE only, same scope as the underlying data file.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("Rotation", M)

local CONFIDENCE_STATUS = { CONFIRMED = "good", APPROX = "warn", DISPUTED = "bad" }
local ROLE_LABEL = { dps = "DPS", heal = "HPS (healer)", tank = "TPS (tank/threat)" }

-- Added 2026-09-09: this used to always read Data/TBCRotations.lua, which
-- assumes level 70 with a full 61-point talent build — actively wrong
-- advice for anyone still leveling, who is usually missing the exact
-- ability the max-level list leads with (Bloodthirst/Mortal Strike at 40,
-- Mangle at 50, Steady Shot at 62, Shadowform at 40, Vampiric Touch at 50,
-- and so on). Requested: "make sure that while leveling there is rotations
-- for current levels and skills and not for max level unless the max level
-- has been reached." Below level 70 this now reads the parallel
-- Data/TBCLevelingRotations.lua table instead, switching back to the
-- max-level table automatically at 70 — no manual toggle needed.
local MAX_LEVEL = 70  -- TBC Classic Anniversary's level cap

--- @return table|nil specs, boolean usingLeveling
local function ActiveSpecsFor(class)
    local isMaxLevel = U.GetPlayerLevel() >= MAX_LEVEL
    if not isMaxLevel then
        local levelingSpecs = TA.Data.LevelingRotations and TA.Data.LevelingRotations[class]
        if levelingSpecs and #levelingSpecs > 0 then
            return levelingSpecs, true
        end
        -- Defensive fallback only — every class has leveling data as of
        -- this writing, but don't show nothing if that ever changes.
    end
    return TA.Data.Rotations and TA.Data.Rotations[class], false
end

local function RenderSpecBlock(content, y, s)
    y = L:DataRow(content, y, {
        label = s.spec .. "  —  " .. (ROLE_LABEL[s.role] or s.role),
        value = s.confidence,
        status = CONFIDENCE_STATUS[s.confidence] or "neutral",
        bold = true,
    })
    for i, step in ipairs(s.priority) do
        y = L:Bullet(content, y, string.format("%d. %s", i, step), { color = L.C_PRIMARY })
    end
    if s.notes then
        y = L:Spacer(y, 2)
        y = L:Paragraph(content, y, s.notes, { color = L.C_DIM, size = 9 })
    end
    y = L:Spacer(y, 6)
    return y
end

function M:Render(content, side)
    L:CharacterSidebar(side)

    local class = U.GetPlayerClass()
    local level = U.GetPlayerLevel()
    local allSpecs, usingLeveling = ActiveSpecsFor(class)
    local y = -8

    if not allSpecs or #allSpecs == 0 then
        y = L:SectionHeader(content, y, "ROTATION / PRIORITY")
        y = L:Paragraph(content, y, string.format(
            "No rotation data for '%s' yet.", tostring(class)), { color = L.C_WARNING })
        L:Finish(content, y)
        return
    end

    local specName, specPoints = U.GetTalentSummary()

    -- Druid Feral is one talent tree but two very different roles depending
    -- on shapeshift form at max level (Bear tank vs. Cat dps) — show both
    -- rather than guessing which form you're currently in. The leveling
    -- table only has a single combined "Feral (Cat)" entry (see that file's
    -- header comment for why), so this only ever finds two matches on the
    -- max-level table.
    local matched = {}
    if class == "DRUID" and specName == "Feral Combat" then
        for _, s in ipairs(allSpecs) do
            if s.spec == "Feral (Cat)" or s.spec == "Feral (Bear)" then matched[#matched + 1] = s end
        end
    else
        for _, s in ipairs(allSpecs) do
            if s.spec == specName then matched[#matched + 1] = s end
        end
    end

    local headerTitle = usingLeveling
        and string.format("ROTATION / PRIORITY — LEVELING (%d/%d)", level, MAX_LEVEL)
        or "ROTATION / PRIORITY"
    local headerNote = usingLeveling
        and ("|cFFFFD100This is the simplified leveling-phase priority, not the level-" .. MAX_LEVEL
            .. " raid rotation|r — it switches automatically once you reach " .. MAX_LEVEL .. ". "
            .. "|cFF4AFF7AGreen|r = confirmed by 2+ sources, |cFFFF9A1Aorange|r = single source or "
            .. "approximate, |cFFFF6E6Ered|r = sources genuinely disagree — see notes below each.")
        or ("|cFF888780Single-target PvE priority list — a reference, not a live tracker. "
            .. "|cFF4AFF7AGreen|r = confirmed by 2+ sources, |cFFFF9A1Aorange|r = single source or "
            .. "approximate, |cFFFF6E6Ered|r = sources genuinely disagree — see notes below each.")

    y = L:SectionHeader(content, y, headerTitle, headerNote)

    if #matched == 0 then
        if not specPoints or specPoints == 0 then
            y = L:Paragraph(content, y,
                "You haven't spent any talent points yet, so your spec can't be auto-detected. "
                .. "Showing every " .. tostring(class) .. " spec below — spend points to narrow this to yours.",
                { color = L.C_WARNING })
        else
            y = L:Paragraph(content, y, string.format(
                "No rotation data for '%s' specifically — showing every %s spec below.",
                tostring(specName), tostring(class)), { color = L.C_WARNING })
        end
        y = L:Spacer(y, 4)
        for i, s in ipairs(allSpecs) do
            y = RenderSpecBlock(content, y, s)
            if i < #allSpecs then y = L:Divider(content, y) end
        end
    else
        for i, s in ipairs(matched) do
            y = RenderSpecBlock(content, y, s)
            if i < #matched then y = L:Divider(content, y) end
        end

        local others = {}
        for _, s in ipairs(allSpecs) do
            local isMatched = false
            for _, m in ipairs(matched) do if m == s then isMatched = true break end end
            if not isMatched then others[#others + 1] = s.spec .. " (" .. (ROLE_LABEL[s.role] or s.role) .. ")" end
        end
        if #others > 0 then
            y = L:Spacer(y, 4)
            y = L:Divider(content, y)
            y = L:Paragraph(content, y,
                "Other " .. tostring(class) .. " specs: " .. table.concat(others, ", ")
                .. " — |cFFFFD100/ta rotation " .. tostring(class) .. " <spec>|r prints any of them to chat.",
                { color = L.C_DIM, size = 9 })
        end
    end

    y = L:Spacer(y, 4)
    y = L:Paragraph(content, y,
        "Full source links: |cFFFFD100/ta rotation " .. tostring(class) .. "|r in chat, "
        .. "or Data/" .. (usingLeveling and "TBCLevelingRotations.lua" or "TBCRotations.lua")
        .. " on disk.", { color = L.C_DIM, size = 9 })

    L:Finish(content, y)
end
