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

local function SpellIcon(e)
    if e.slot and GetSpellBookItemTexture then
        local ok, tex = pcall(GetSpellBookItemTexture, e.slot, BOOKTYPE_SPELL)
        if ok and tex then return tex end
    end
    if e.spellID and GetSpellTexture then
        local ok, tex = pcall(GetSpellTexture, e.spellID)
        if ok and tex then return tex end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function Notify(msg)
    TA:Print(TA.LOG.OUTPUT, nil, msg)
end

--- One spell: draggable icon, name, status, and an Add / Upgrade button.
local function SpellRow(content, y, e)
    y = math.floor(y)
    local w = L:Width(content)
    local rowH = 30

    local row = CreateFrame("Frame", nil, content)
    row:SetSize(w, rowH)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD, y)

    -- Icon: drag it (or click it) to put the spell on your cursor, then drop
    -- it on any action bar slot — the same as dragging from the spellbook.
    local icon = CreateFrame("Button", nil, row)
    icon:SetSize(26, 26)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(SpellIcon(e))
    icon:RegisterForDrag("LeftButton")
    icon:RegisterForClicks("LeftButtonUp")
    local function pickup()
        if not U.PickupSpellFromBook(e) then
            Notify((InCombatLockdown and InCombatLockdown()) and "Can't pick up spells in combat."
                or ("Couldn't pick up " .. e.name .. "."))
        end
    end
    icon:SetScript("OnDragStart", pickup)
    icon:SetScript("OnClick", pickup)
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local shown = false
        if e.slot and GameTooltip.SetSpellBookItem then
            shown = pcall(GameTooltip.SetSpellBookItem, GameTooltip, e.slot, BOOKTYPE_SPELL)
        end
        if not shown then GameTooltip:SetText(e.name, 1, 0.82, 0) end
        GameTooltip:AddLine("Drag onto an action bar slot.", 0.4, 0.75, 1, true)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetText(e.name .. (e.knownRank > 0 and ("  |cFF888780Rank " .. e.knownRank .. "|r") or ""))
    name:SetTextColor(0.92, 0.90, 0.87, 1)

    local status = row:CreateFontString(nil, "OVERLAY")
    status:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    status:SetPoint("LEFT", name, "RIGHT", 10, 0)
    if e.onBar then
        status:SetText(string.format("|cFFFF9A1Abar has Rank %d|r", e.barRank))
    else
        status:SetText("|cFFFF6E6Enot on any bar|r")
    end

    -- Action button, right-aligned
    local btn = CreateFrame("Button", nil, row)
    btn:SetSize(120, 22)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    lbl:SetPoint("CENTER")
    lbl:SetText(e.onBar and "Upgrade on bar" or "Add to bar")
    lbl:SetTextColor(1, 0.82, 0, 1)
    if TA._ApplyBackdrop then TA._ApplyBackdrop(btn, 0.12, 0.10, 0.04, 1, 0.60, 0.50, 0.15, 1) end
    btn:SetScript("OnClick", function()
        local target = e.onBar and e.barSlot or U.FindEmptyActionSlot()
        local ok, msg = U.PlaceSpellOnBar(e, target)
        if ok then
            Notify(string.format("%s %s on %s.", e.name, e.onBar and "upgraded" or "placed", msg))
            L:RefreshUI()
        else
            Notify(msg)
        end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if e.onBar then
            local bar, pos = U.ActionSlotName(e.barSlot or 0)
            GameTooltip:SetText("Upgrade on bar", 1, 0.82, 0)
            GameTooltip:AddLine(string.format("Replaces Rank %d on %s slot %d with Rank %d.",
                e.barRank, bar, pos, e.knownRank), 0.9, 0.9, 0.9, true)
        else
            local slot, bar, pos = U.FindEmptyActionSlot()
            GameTooltip:SetText("Add to bar", 1, 0.82, 0)
            GameTooltip:AddLine(slot and string.format("Goes into the first empty slot: %s slot %d.", bar, pos)
                or "No empty slot on your standard bars — drag the icon onto a slot instead.",
                0.9, 0.9, 0.9, true)
        end
        GameTooltip:AddLine("Out of combat only.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return y - rowH - 4
end

function M:Render(content, side)
    L:CharacterSidebar(side)
    local y = -8

    y = L:SectionHeader(content, y, "SPELLS NOT ON YOUR ACTION BARS",
        "|cFF888780Your spellbook checked against every action bar slot (stance bars excluded, "
        .. "passives skipped). Drag an icon onto a bar, or use the button to place it for you.|r")

    -- Duplicate copies (e.g. from repeated clicks before 2026-09-16, when a
    -- spell whose bar name differs from its book name never cleared).
    local dupes = U.FindDuplicateBarSpells()
    if #dupes > 0 then
        local names, seen = {}, {}
        for _, d in ipairs(dupes) do
            if not seen[d.name] then seen[d.name] = true; names[#names + 1] = d.name end
        end
        y = L:Paragraph(content, y, string.format(
            "|cFFFF9A1A%d extra cop%s on your bars:|r %s", #dupes, #dupes == 1 and "y" or "ies",
            table.concat(names, ", ")), { color = L.C_WARNING })
        y = L:ButtonRow(content, y, {
            { label = string.format("Remove %d extra cop%s", #dupes, #dupes == 1 and "y" or "ies"),
              onClick = function()
                  if InCombatLockdown and InCombatLockdown() then
                      Notify("Can't change action bars in combat.")
                      return
                  end
                  local n = U.ClearActionSlots(dupes)
                  Notify(string.format("Removed %d duplicate action%s. The first copy of each was kept.",
                      n, n == 1 and "" or "s"))
                  L:RefreshUI()
              end,
              tooltip = { "Remove extra copies", "Keeps the first copy of each spell on your standard bars and clears the rest. Out of combat only." } },
        })
        y = L:Spacer(y, 4)
    end

    local missing = U.FindMissingSpellRanks()
    if #missing == 0 then
        y = L:Paragraph(content, y,
            "Everything in your spellbook is on a bar at its best known rank. Nothing to fix.",
            { color = L.C_SUCCESS })
        L:Finish(content, y)
        return
    end

    local upgrades = 0
    for _, e in ipairs(missing) do if e.onBar then upgrades = upgrades + 1 end end

    y = L:ButtonRow(content, y, {
        { label = string.format("Place all %d", #missing), onClick = function()
            local placed, failed = 0, nil
            for _, e in ipairs(missing) do
                local target = e.onBar and e.barSlot or U.FindEmptyActionSlot()
                local ok, msg = U.PlaceSpellOnBar(e, target)
                if ok then placed = placed + 1 else failed = failed or msg end
            end
            Notify(string.format("Placed %d of %d spells.%s", placed, #missing,
                failed and ("  " .. failed) or ""))
            L:RefreshUI()
        end, tooltip = { "Place all", "Upgrades lower ranks where they sit, and puts new spells in empty slots. Out of combat only." } },
        upgrades > 0 and { label = string.format("Upgrade ranks only (%d)", upgrades), onClick = function()
            local placed = 0
            for _, e in ipairs(missing) do
                if e.onBar and U.PlaceSpellOnBar(e, e.barSlot) then placed = placed + 1 end
            end
            Notify(string.format("Upgraded %d spell rank%s.", placed, placed == 1 and "" or "s"))
            L:RefreshUI()
        end } or nil,
    })
    y = L:Spacer(y, 2)

    for _, e in ipairs(missing) do
        y = SpellRow(content, y, e)
    end

    y = L:Spacer(y, 4)
    y = L:Paragraph(content, y,
        "Healers who downrank on purpose (a low-rank Holy Light, Greater Heal or Healing Wave "
        .. "for mana efficiency) can ignore rank upgrades for those spells.",
        { color = L.C_DIM, size = 9 })

    L:Finish(content, y)
end

-- ── Proactive "you just learned X" alert ────────────────────────────────
-- Baseline of the highest rank seen per spell name, persisted per-character
-- in TA.charDB.seenSpellRanks so it survives /reload and relog.

function M:CheckNewlyLearned()
    TA.charDB.seenSpellRanks = TA.charDB.seenSpellRanks or {}
    local seen = TA.charDB.seenSpellRanks
    local known, idRanks = U.ScanSpellbook()
    local onBars = U.ScanActionBarRanks(idRanks)

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
    TA:Raw(TA.LOG.OUTPUT, "|cFF888780Open the Spells tab to drag them onto your bars.|r")
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
