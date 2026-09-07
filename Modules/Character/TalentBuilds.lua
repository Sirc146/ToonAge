-- ToonAge/Modules/Character/TalentBuilds.lua (Anniversary — TBC Classic / 20506)
-- Recommended talent builds for your class, by role and context — the panel
-- view of Data/TBCTalentBuilds.lua.
--
-- This tab shows RECOMMENDATIONS, not your own current talent spend — for
-- that, see the "deepest tree" line the sidebar already shows on every tab
-- (U.GetSpecLabel(), Core/Layout.lua:CharacterSidebar). A real "your talents
-- vs. the recommended build, tree by tree" comparison view is a reasonable
-- next step but is not what this tab does today.
--
-- Confidence grading (CONFIRMED/APPROX/DISPUTED) and full source citations
-- live in Data/TBCTalentBuilds.lua's header and per-build `sources` field —
-- this tab shows the graded label and notes but not the raw URLs; use
-- /ta builds [class] to print sources to chat, or open the data file.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("TalentBuilds", M)

local CONFIDENCE_STATUS = { CONFIRMED = "good", APPROX = "warn", DISPUTED = "bad" }

function M:Render(content, side)
    L:CharacterSidebar(side)

    local class = U.GetPlayerClass()
    local allBuilds = TA.Data.TalentBuilds and TA.Data.TalentBuilds[class]
    local y = -8

    if not allBuilds or #allBuilds == 0 then
        y = L:SectionHeader(content, y, "TALENT BUILDS")
        y = L:Paragraph(content, y, string.format(
            "No talent build data for '%s' yet.", tostring(class)), { color = L.C_WARNING })
        L:Finish(content, y)
        return
    end

    -- Fixed 2026-09-07: this tab used to list every build regardless of mode,
    -- so switching /ta pvp on left it showing PvE builds first (or mixed in)
    -- instead of following the same one-flag-flips-everything pattern every
    -- other tab (Caps, Gear, PvPAdvisor) already uses. Filter to the active
    -- context, same as they do.
    local pvpMode = TA.db and TA.db.pvpMode
    local wantContext = pvpMode and "pvp" or "pve"

    local builds = {}
    for _, b in ipairs(allBuilds) do
        if b.context == wantContext then builds[#builds + 1] = b end
    end

    local headerTitle = pvpMode and "RECOMMENDED TALENT BUILDS — PVP" or "RECOMMENDED TALENT BUILDS — PVE"
    local headerColor = pvpMode and "|cFFFF6E6E" or "|cFF4AFF7A"

    if #builds == 0 then
        y = L:SectionHeader(content, y, headerTitle)
        y = L:Paragraph(content, y, string.format(
            "No %s build data for %s yet — showing nothing rather than the wrong mode's build.",
            wantContext, tostring(class)), { color = L.C_WARNING })
        L:Finish(content, y)
        return
    end

    y = L:SectionHeader(content, y, headerTitle,
        headerColor .. (pvpMode and "PvP mode is ON" or "PvE mode") .. "|r  |cFF888780(/ta pvp to switch)|r"
        .. " — researched against current TBC Classic guides, graded by how well sources agree. "
        .. "|cFF4AFF7AGreen|r = confirmed by 2+ sources, |cFFFF9A1Aorange|r = single source or "
        .. "approximate, |cFFFF6E6Ered|r = sources genuinely disagree — see notes below each.")

    for i, b in ipairs(builds) do
        y = L:DataRow(content, y, {
            label = b.label, value = b.confidence,
            status = CONFIDENCE_STATUS[b.confidence] or "neutral",
            bold = true, note = b.allocation,
        })

        if b.keyTalents then
            for _, t in ipairs(b.keyTalents) do
                y = L:Bullet(content, y, t, { color = L.C_SECONDARY })
            end
        end

        if b.notes then
            y = L:Spacer(y, 2)
            y = L:Paragraph(content, y, b.notes, { color = L.C_DIM, size = 9 })
        end

        if b.verifyPoints then
            y = L:Paragraph(content, y,
                "|cFFFF9A1A⚠|r Some secondary talent point costs here came from guide prose, "
                .. "not a scraped calculator — spot-check before treating them as exact.",
                { color = L.C_WARNING, size = 9 })
        end

        y = L:Spacer(y, 6)
        if i < #builds then y = L:Divider(content, y) end
    end

    y = L:Spacer(y, 4)
    y = L:Paragraph(content, y,
        "Full source links: |cFFFFD100/ta builds " .. tostring(class) .. "|r in chat, "
        .. "or Data/TBCTalentBuilds.lua on disk.", { color = L.C_DIM, size = 9 })

    y = M:RenderSecondaryRoles(content, y, class)

    L:Finish(content, y)
end

-- Added 2026-09-07: "out of the box" secondary/hybrid capability suggestions
-- — real things this class can do OUTSIDE its normal role in dungeon
-- content (off-healing, off-tanking, unique utility), gated behind the
-- player's LIVE talent investment via U.GetTalentPointsInTree() rather than
-- shown just because the class theoretically can. Explicitly a SECONDARY,
-- optional section below the main recommended build above — never a
-- replacement for it. See Data/TBCSecondaryRoles.lua for the sourced data
-- and confidence grading.
function M:RenderSecondaryRoles(content, y, class)
    local roles = TA.Data.SecondaryRoles and TA.Data.SecondaryRoles[class]
    if not roles or #roles == 0 then return y end

    local available, locked = {}, {}
    for _, r in ipairs(roles) do
        if r.requiredTree == "none" then
            available[#available + 1] = r
        else
            local have = U.GetTalentPointsInTree(r.requiredTree)
            if have >= (r.requiredPoints or 0) then
                available[#available + 1] = r
            else
                r._have = have
                locked[#locked + 1] = r
            end
        end
    end

    y = L:Spacer(y, 8)
    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "SECONDARY / HYBRID OPTIONS",
        "|cFF888780Optional — not the recommended build above. Real \"out of the box\" plays this class "
        .. "can pull off in dungeons, shown only when your CURRENT talent investment actually supports them.|r")

    for _, r in ipairs(available) do
        y = L:DataRow(content, y, {
            label = r.label, value = "AVAILABLE NOW",
            status = "good", bold = true,
        })
        y = L:Paragraph(content, y, r.description, { color = L.C_DIM, size = 9 })
        y = L:Paragraph(content, y, "|cFF888780When: " .. r.context .. "|r", { color = L.C_SECONDARY, size = 9 })
        y = L:Spacer(y, 4)
    end

    for _, r in ipairs(locked) do
        y = L:DataRow(content, y, {
            label = r.label,
            value = string.format("needs %d in %s (have %d)", r.requiredPoints or 0, r.requiredTree, r._have or 0),
            status = "dim", bold = false,
        })
        y = L:Spacer(y, 2)
    end

    return y
end
