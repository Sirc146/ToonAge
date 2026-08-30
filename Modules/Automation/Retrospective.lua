-- ToonAge/Modules/Automation/Retrospective.lua
-- "What Did I Miss?" — when you out-level a zone or skip content, shows
-- notable skipped quests with collectible rewards (transmog, pets, mounts,
-- achievements). Links to BtWQuests chain data.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local Retro = {}
TA:RegisterModule("Retrospective", Retro)

-- ── Notable reward types worth going back for ─────────────────────────────────
local NOTABLE_FLAGS = {
    mount = true,
    pet = true,
    toy = true,
    transmog = true,
    achievement = true,
    recipe = true,
    title = true,
}

-- ── Zone completion tracking ──────────────────────────────────────────────────

--- Check how many quests in a guide the player has completed vs skipped.
--- @param guideID string
--- @return table { total, completed, skipped, notableSkipped }
function Retro:AnalyzeGuide(guideID)
    local guide = TA.Guides and TA.Guides[guideID]
    if not guide then
        return nil
    end

    local total = 0
    local completed = 0
    local skipped = {}

    for _, step in ipairs(guide.steps) do
        if step.questID then
            total = total + 1
            if C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
                completed = completed + 1
            else
                table.insert(skipped, step)
            end
        end
    end

    return {
        guideID = guideID,
        title = guide.title,
        total = total,
        completed = completed,
        skipped = skipped,
        pct = total > 0 and (completed / total * 100) or 100,
    }
end

--- Check if a quest has notable rewards worth going back for.
--- Uses Blizzard's quest reward API to detect mounts, pets, toys, etc.
--- @param questID number
--- @return table|nil { type, name } or nil
function Retro:CheckNotableReward(questID)
    if not questID then
        return nil
    end

    -- Check if quest grants an achievement
    -- (Would need a static DB — placeholder for now)

    -- Check quest rewards via API (only works if quest is available)
    -- For completed quests, we can't easily check rewards retroactively.
    -- This is primarily useful for NOT-YET-COMPLETED quests.

    return nil -- Extend with static DB later
end

--- Get a summary of what the player missed in zones they've out-leveled.
--- @return table array of { guideName, skippedCount, pct }
function Retro:GetMissedContent()
    local results = {}
    local playerLevel = UnitLevel("player") or 1

    for id, guide in pairs(TA.Guides or {}) do
        -- Only analyze guides the player has out-leveled
        if guide.maxLevel and playerLevel > (guide.maxLevel + 3) then
            local analysis = self:AnalyzeGuide(id)
            if analysis and #analysis.skipped > 0 and analysis.pct < 90 then
                table.insert(results, {
                    title = analysis.title,
                    completed = analysis.completed,
                    total = analysis.total,
                    skipped = #analysis.skipped,
                    pct = analysis.pct,
                })
            end
        end
    end

    -- Sort by most incomplete first
    table.sort(results, function(a, b)
        return a.pct < b.pct
    end)
    return results
end

-- ── Display ───────────────────────────────────────────────────────────────────

function Retro:ShowMissedContent()
    local missed = self:GetMissedContent()

    if #missed == 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r You haven't skipped any significant content. Nice!")
        return
    end

    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ What Did I Miss? ━━━|r")
    for _, entry in ipairs(missed) do
        local color = entry.pct < 50 and "|cFFFF6666" or "|cFFFFD100"
        TA:Raw(
            TA.LOG.OUTPUT,
            string.format(
                "  %s%s|r — %d/%d quests done (%.0f%%), %d skipped",
                color,
                entry.title,
                entry.completed,
                entry.total,
                entry.pct,
                entry.skipped
            )
        )
    end
    TA:Raw(
        TA.LOG.OUTPUT,
        "|cFF888780Use /ta guides to see available guides. Return anytime for transmog/achievements.|r"
    )
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function Retro:Init()
    -- Show a subtle tracker toast when entering a city if content was missed.
    -- No chat spam — just a brief visual hint on the tracker window.
    C_Timer.After(15, function()
        if IsResting() then -- in a city/inn
            local missed = Retro:GetMissedContent()
            if #missed > 0 then
                local QT = TA:GetModule("QuestTracker")
                if QT and QT.ShowToast then
                    QT:ShowToast(
                        missed[1].skipped .. " quests skipped in " .. missed[1].title .. " — right-click tracker",
                        4
                    )
                end
            end
        end
    end)
end

Retro.SlashCommands = {
    missed = function(self)
        self:ShowMissedContent()
    end,
}
