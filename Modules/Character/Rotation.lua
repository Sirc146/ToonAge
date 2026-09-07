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
    local allSpecs = TA.Data.Rotations and TA.Data.Rotations[class]
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
    -- on shapeshift form — show both rather than guessing which form you're
    -- currently in.
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

    y = L:SectionHeader(content, y, "ROTATION / PRIORITY",
        "|cFF888780Single-target PvE priority list — a reference, not a live tracker. "
        .. "|cFF4AFF7AGreen|r = confirmed by 2+ sources, |cFFFF9A1Aorange|r = single source or "
        .. "approximate, |cFFFF6E6Ered|r = sources genuinely disagree — see notes below each.")

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
        .. "or Data/TBCRotations.lua on disk.", { color = L.C_DIM, size = 9 })

    L:Finish(content, y)
end
