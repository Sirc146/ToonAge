-- ToonAge/Modules/Character/Spells.lua (Anniversary — TBC Classic / 20506)
-- "Your spellbook has a spell/rank your action bars don't" check — requested
-- 2026-09-07: "is there a way to know when my Spell book has new spells and
-- my action bar does not have them equipped like different ranks", answered
-- as BOTH an on-demand check (this tab / /ta spells) and a proactive chat
-- alert right when a new spell/rank is learned (M:OnEvent below).
--
-- Uses U.ScanSpellbook() / U.ScanActionBarRanks() / U.FindMissingSpellRanks()
-- (Core/Utils.lua) — matched by spell NAME, not spellID; see that file's
-- comment for why. Passives are excluded (they're never meant to be on a
-- bar); stance/vehicle bars aren't scanned (contextual, not "your bars").
-- This is a best-effort checklist, not a hard rule — some players
-- deliberately leave certain buffs off a visible bar slot.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("Spells", M)

function M:Render(content, side)
    L:CharacterSidebar(side)
    local y = -8

    y = L:SectionHeader(content, y, "SPELLS NOT ON YOUR ACTION BARS",
        "|cFF888780Checked against your live spellbook vs. every action bar slot (stance/vehicle bars "
        .. "excluded, passives skipped). Best-effort checklist, not a hard rule — some buffs are "
        .. "intentionally left off a bar.|r")

    local missing = U.FindMissingSpellRanks()
    if #missing == 0 then
        y = L:Paragraph(content, y,
            "Everything in your spellbook is on a bar at its best known rank. Nothing to fix.",
            { color = L.C_SUCCESS })
        L:Finish(content, y)
        return
    end

    for _, e in ipairs(missing) do
        local value, status
        if not e.onBar then
            value = e.knownRank > 0 and ("Rank " .. e.knownRank .. " — not on any bar") or "Not on any bar"
            status = "bad"
        else
            value = string.format("bar has Rank %d, you know Rank %d", e.barRank, e.knownRank)
            status = "warn"
        end
        y = L:DataRow(content, y, { label = e.name, value = value, status = status, bold = true })
    end

    y = L:Spacer(y, 4)
    y = L:Paragraph(content, y,
        "Drag the spell from your spellbook onto a bar slot to fix it.",
        { color = L.C_DIM, size = 9 })

    L:Finish(content, y)
end

-- ── Proactive "you just learned X" alert ────────────────────────────────
-- Baseline of the highest rank seen per spell name, persisted per-character
-- in TA.charDB.seenSpellRanks so it survives /reload and relog.

function M:CheckNewlyLearned()
    TA.charDB.seenSpellRanks = TA.charDB.seenSpellRanks or {}
    local seen = TA.charDB.seenSpellRanks
    local known = U.ScanSpellbook()
    local onBars = U.ScanActionBarRanks()

    local newlyLearned = {}
    for name, rank in pairs(known) do
        local before = seen[name]
        if not before or rank > before then
            local barRank = onBars[name]
            if not barRank or barRank < rank then
                newlyLearned[#newlyLearned + 1] = {
                    name = name, rank = rank, onBar = barRank ~= nil, barRank = barRank or 0,
                }
            end
        end
    end

    -- Update the baseline for every known spell regardless of whether it was
    -- flagged, so nothing re-fires next session just for existing already.
    for name, rank in pairs(known) do
        seen[name] = rank
    end

    if #newlyLearned == 0 then return end
    table.sort(newlyLearned, function(a, b) return a.name < b.name end)

    TA:Print(TA.LOG.OUTPUT, nil, "|cFFFFD100New spell(s) not on your action bars:|r")
    for _, e in ipairs(newlyLearned) do
        local rankText = e.rank > 0 and (" (Rank " .. e.rank .. ")") or ""
        local where = e.onBar and (" — bar still has Rank " .. e.barRank) or ""
        TA:Raw(TA.LOG.OUTPUT, string.format("  |cFF4AFF7A%s|r%s%s", e.name, rankText, where))
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFF888780/ta spells for the full list.|r")
end

function M:OnEvent(event, ...)
    -- Seed the baseline the first time this module sees ANY event post-login
    -- (not just LEARNED_SPELL_IN_TAB), so a character's already-known spells
    -- don't all look "newly learned" the first time this feature runs on
    -- them. Retries on the next event if the spellbook wasn't populated yet
    -- (a brief window right at login) rather than seeding from an empty scan.
    if not self._seededOnce then
        TA.charDB.seenSpellRanks = TA.charDB.seenSpellRanks or {}
        if next(TA.charDB.seenSpellRanks) then
            self._seededOnce = true
        else
            local known = U.ScanSpellbook()
            if next(known) then
                for name, rank in pairs(known) do TA.charDB.seenSpellRanks[name] = rank end
                self._seededOnce = true
            end
        end
    end

    if event ~= "LEARNED_SPELL_IN_TAB" then return end

    -- Debounced: training multiple spells at once fires this event once per
    -- spell in a tight burst — coalesce into one check/one chat message
    -- rather than spamming.
    if self._pendingCheck then return end
    self._pendingCheck = true
    if C_Timer and C_Timer.After then
        C_Timer.After(1.0, function()
            self._pendingCheck = nil
            M:CheckNewlyLearned()
        end)
    else
        self._pendingCheck = nil
        self:CheckNewlyLearned()
    end
end
