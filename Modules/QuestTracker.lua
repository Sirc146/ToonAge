-- ToonAge/Modules/QuestTracker.lua
-- Floating tracker window showing the current guide step with live objectives.
--
-- Features:
--   Live Objectives   — injects real C_QuestLog objective text into the step display
--   FFWD Catch-up     — backward+forward sync against the quest log on every log change
--   Smart Phrase Parse— accept/speak/talk steps auto-complete when the quest enters the log
--   Auto-Quest Engine — opt-in auto-accept and auto-turn-in (hold Shift to pause any step)
--   Blizzard Replace  — optionally hides the default Objective Tracker while active
--   Arrow Integration — live distance/ETA from Arrow.lua displayed inline in the status bar

local TA = ToonAge
local U  = TA.Utils

local QT = {}
TA:RegisterModule("QuestTracker", QT)

QT.window        = nil
QT.optionsFrame  = nil
QT.guideID       = nil
QT.stepIdx       = 1
QT.statusThrottle = 0
QT.stickySteps   = {}     -- { stepIdx, ... } — sticky steps persist at top of display
QT.skippedSteps  = {}     -- { [stepIdx] = true } — manually skipped steps
local STATUS_UPDATE_HZ = 0.2   -- distance/ETA refresh rate, matches Arrow's own tick budget

-- Debounce timer for high-frequency quest log events.
-- QUEST_LOG_UPDATE and UNIT_QUEST_LOG_CHANGED can fire 10-20 times in a single
-- turn-in or loot sequence. FastForward() scans every guide step backward then
-- forward — doing that 20 times in one frame wastes CPU and violates the
-- Blizzard "no negative impact on realm performance" policy rule.
-- We coalesce all log-change firings within a 0.15s window into one sync.
local logSyncTimer = nil
local LOG_SYNC_DELAY = 0.15

-- ── Quest state helpers ───────────────────────────────────────────────────────

local function IsComplete(questID)
    if not questID then return false end
    return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
end

local function IsInLog(questID)
    if not questID then return false end
    return C_QuestLog.GetLogIndexForQuestID(questID) ~= nil
end

local function IsReadyForTurnIn(questID)
    if not questID then return false end
    if C_QuestLog.ReadyForTurnIn then
        return C_QuestLog.ReadyForTurnIn(questID) == true
    end
    local idx = C_QuestLog.GetLogIndexForQuestID(questID)
    if not idx then return false end
    local info = C_QuestLog.GetInfo(idx)
    return info ~= nil and info.isComplete == true
end

function QT:GetQuestStatus(questID)
    if not questID then return "available" end
    if IsComplete(questID)       then return "complete"   end
    if IsReadyForTurnIn(questID) then return "turnin"     end
    if IsInLog(questID)          then return "inprogress" end
    return "available"
end

-- ── Step evaluation & Smart Phrase Parsing ────────────────────────────────────

function QT:IsStepApplicable(step)
    -- Delegate to GuideParser's filter which covers faction, class, race, spec, minLevel
    local GP = TA:GetModule("GuideParser")
    if GP and GP.IsStepApplicable then
        return GP:IsStepApplicable(step)
    end
    -- Fallback inline check (should not be reached if GuideParser is loaded)
    if step.class then
        local _, pClass = UnitClass("player")
        if pClass ~= step.class then return false end
    end
    if step.spec then
        local specID = GetSpecializationInfo(GetSpecialization())
        if specID ~= step.spec then return false end
    end
    if step.minLevel then
        local lvl = UnitLevel("player") or 1
        if lvl < step.minLevel then return false end
    end
    return true
end

--- Determine if the player is currently flying (dragonriding, flying mount, or flight path).
local function IsPlayerFlying()
    return IsFlying() or UnitOnTaxi("player")
end

--- Check if a specific quest objective is finished.
--- @param questID number
--- @param objectiveIndex number (1-based)
--- @return boolean
local function IsObjectiveFinished(questID, objectiveIndex)
    if not questID or not objectiveIndex then return false end
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if not objectives then return false end
    local obj = objectives[objectiveIndex]
    return obj and obj.finished == true
end

function QT:IsStepComplete(step)
    if not self:IsStepApplicable(step) then return true end
    if step.type == "text"             then return true end
    if step._manualDone                then return true end

    local sType = step.type or "quest"

    -- ─── Pickup / Accept: complete when quest enters the log ───────────
    if sType == "pickup" or sType == "accept" then
        if step.questID then
            return IsInLog(step.questID) or IsComplete(step.questID)
        end
        -- Smart Phrase Parsing fallback for pickup steps without explicit questID
        return false
    end

    -- ─── Turnin: complete when IsQuestFlaggedCompleted ─────────────────
    if sType == "turnin" then
        if step.questID then
            return IsComplete(step.questID)
        end
        return false
    end

    -- ─── Objective: complete when specific objective index is finished ──
    if sType == "objective" then
        if step.questID and step.objectiveIndex then
            return IsObjectiveFinished(step.questID, step.objectiveIndex)
                or IsComplete(step.questID)
        end
        return false
    end

    -- ─── Waypoint: proximity-only (checked in CheckProximityAdvance) ───
    -- Also auto-skip if player is flying and step doesn't forbid it.
    if sType == "waypoint" then
        if IsPlayerFlying() then return true end  -- auto-skip waypoints while flying
        return false  -- otherwise only proximity advance
    end

    -- ─── Legacy "quest" type: complete when flagged complete ───────────
    if sType == "quest" then
        if step.questID then
            if IsComplete(step.questID) then return true end
            -- Smart Phrase Parsing: accept/speak/talk steps finish when quest is in log
            local text = (step.text or ""):lower()
            local isAcceptStep = text:match("^accept")
                              or text:match("^speak")
                              or text:match("^talk")
            if isAcceptStep and IsInLog(step.questID) then return true end
        end
        return false
    end

    -- ─── Travel: NOT auto-skipped when flying (mandatory path step) ────
    if sType == "travel" then
        return false  -- only completes via proximity
    end

    -- ─── Flyto: complete when player arrives in target zone ────────────
    if sType == "flyto" then
        if step.coord and step.coord.map and step.coord.map ~= 0 then
            local currentMap = C_Map.GetBestMapForUnit("player")
            return currentMap == step.coord.map
        end
        return false
    end

    -- ─── All other types (npc, item, action, sethearth): no auto-complete
    return false
end

-- ── WoW-Pro-Inspired Step Evaluation (Sticky, PRE, Rank, Loot, Active) ────────

--- Check if a step's prerequisite chain is satisfied.
--- step.pre = questID or {questID, ...} — all must be flagged complete.
--- step.preOr = {questID, ...} — any one must be flagged complete.
function QT:IsPrerequisiteMet(step)
    if not step.pre and not step.preOr then return true end

    -- AND prerequisites: all must be complete
    if step.pre then
        local pre = type(step.pre) == "table" and step.pre or { step.pre }
        for _, qid in ipairs(pre) do
            if not IsComplete(qid) then return false end
        end
    end

    -- OR prerequisites: any one is enough
    if step.preOr then
        local anyDone = false
        for _, qid in ipairs(step.preOr) do
            if IsComplete(qid) then anyDone = true; break end
        end
        if not anyDone then return false end
    end

    return true
end

--- Check if a step passes the rank filter.
--- step.rank = number (1=speed, 2=normal, 3=completionist)
--- Player's rank stored in charDB.tracker.rank (default 2)
function QT:PassesRankFilter(step)
    if not step.rank then return true end
    local playerRank = (TA.charDB and TA.charDB.tracker and TA.charDB.tracker.rank) or 2
    if step.rank > 0 then
        return playerRank >= step.rank
    else
        -- Negative rank = exact match only
        return playerRank == math.abs(step.rank)
    end
end

--- Check if a step should be visible based on its ACTIVE requirement.
--- step.active = questID — only show if that quest is currently in the log.
function QT:IsActiveConditionMet(step)
    if not step.active then return true end
    return IsInLog(step.active)
end

--- Check if a step's loot requirement is met (item in bags).
--- step.lootItem = { itemID, quantity }
function QT:IsLootMet(step)
    if not step.lootItem then return false end
    local itemID = step.lootItem[1]
    local needed = step.lootItem[2] or 1
    local count = C_Item.GetItemCount(itemID, true) or 0
    return count >= needed
end

--- Mark a step as sticky (persists at top of display while other steps advance).
function QT:SetSticky(stepIdx)
    -- Avoid duplicates
    for _, idx in ipairs(self.stickySteps) do
        if idx == stepIdx then return end
    end
    table.insert(self.stickySteps, stepIdx)
end

--- Remove a sticky step (called when its unsticky condition is met).
function QT:RemoveSticky(stepIdx)
    for i, idx in ipairs(self.stickySteps) do
        if idx == stepIdx then
            table.remove(self.stickySteps, i)
            return
        end
    end
end

--- Skip a step and cascade to all steps that have PRE pointing to this step's questID.
function QT:SkipStep(stepIdx)
    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    if not guide then return end

    self.skippedSteps[stepIdx] = true
    local skippedQID = guide.steps[stepIdx] and guide.steps[stepIdx].questID

    -- Cascade: skip all later steps whose PRE references this questID
    if skippedQID then
        for i = stepIdx + 1, #guide.steps do
            local s = guide.steps[i]
            if s and s.pre then
                local preList = type(s.pre) == "table" and s.pre or { s.pre }
                for _, pqid in ipairs(preList) do
                    if pqid == skippedQID then
                        self.skippedSteps[i] = true
                        break
                    end
                end
            end
        end
    end
end

--- Check if a step should be shown/evaluated (combines all filters).
function QT:ShouldShowStep(step, stepIdx)
    -- Skipped steps are never shown
    if self.skippedSteps[stepIdx] then return false end

    -- Applicability (class, race, faction, spec, level)
    if not self:IsStepApplicable(step) then return false end

    -- Prerequisite chain
    if not self:IsPrerequisiteMet(step) then return false end

    -- Rank filter
    if not self:PassesRankFilter(step) then return false end

    -- Active condition (only show if specific quest is in log)
    if not self:IsActiveConditionMet(step) then return false end

    return true
end

-- ── Fast Forward ─────────────────────────────────────────────────────────────
-- Scans the entire guide against the quest log and quest-completion flags to
-- find the first step that isn't done yet.
--
-- Two-pass strategy:
--   Pass 1 — walk every step and find the LAST step that is fully complete
--             (IsQuestFlaggedCompleted). This is the true progress anchor.
--             IsInLog alone is NOT used as an anchor — a quest being in-progress
--             means the player is ON that step, not past it.
--   Pass 2 — from the step after the last-complete anchor, find the first step
--             that IsStepComplete() returns false for. That's where we land.
--
-- If no completed quest is found at all (fresh guide), Pass 2 starts from
-- step 1 and lands on the first applicable incomplete step.

-- ── Spatial Routing (TSP nearest-neighbor) ────────────────────────────────────
-- When multiple guide steps are simultaneously active (parallel quests in the
-- same zone), reorder stepIdx to point at the CLOSEST objective. This creates
-- the Zygor "smart routing" effect where the arrow always sends you to the
-- nearest task first, minimizing total travel distance.

function QT:ApplySpatialRouting(guide)
    if not guide or not guide.steps then return end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then return end
    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or px == 0 then return end

    local Arrow = TA:GetModule("Arrow")
    local GetCoord = Arrow and Arrow.GetEffectiveCoord

    -- Collect all simultaneously-active, incomplete steps in a small window
    local candidates = {}
    local LOOKAHEAD = 8  -- check up to 8 steps ahead for parallel quests

    for i = self.stepIdx, math.min(self.stepIdx + LOOKAHEAD, #guide.steps) do
        local step = guide.steps[i]
        if step and not self:IsStepComplete(step) and self:ShouldShowStep(step, i) then
            -- Must have coordinates and be in same zone
            local coordMap, cx, cy = 0, 0, 0
            if GetCoord and step.coord then
                coordMap, cx, cy = GetCoord(step)
            elseif step.coord then
                coordMap = step.coord.map or 0
                cx = step.coord.x or 0
                cy = step.coord.y or 0
            end

            -- Same zone (or unspecified zone) with valid coords
            if (coordMap == 0 or coordMap == currentMap) and (cx ~= 0 or cy ~= 0) then
                local dx = cx - px
                local dy = cy - py
                local distSq = dx * dx + dy * dy
                table.insert(candidates, { idx = i, distSq = distSq })
            end
        end
    end

    -- If we have multiple candidates, pick the closest
    if #candidates > 1 then
        table.sort(candidates, function(a, b) return a.distSq < b.distSq end)
        local closest = candidates[1]
        if closest.idx ~= self.stepIdx then
            self.stepIdx = closest.idx
            self._spatialRouted = true
            self:SaveState()
        else
            self._spatialRouted = false
        end
    end
end

function QT:FastForward(silent)
    if not self.guideID then return end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return end

    -- Pass 1: find the index of the last step that is GENUINELY complete.
    -- We only count steps that have their quest actually flagged done in the
    -- quest log. Inapplicable/filtered steps are invisible to progress scanning.
    -- We do NOT use IsStepComplete() here because it returns true for filtered
    -- steps (wrong class, rank, etc.) which would falsely anchor progress.
    local lastDoneIdx = 0
    for i = 1, #guide.steps do
        local step = guide.steps[i]
        -- Skip filtered/inapplicable steps entirely
        if not self:ShouldShowStep(step, i) then
            -- invisible, don't count
        elseif step.questID then
            -- Real quest step — only anchor if the quest is DONE in the log
            if C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
                lastDoneIdx = i
            end
        elseif step.type == "text" then
            -- Text steps auto-complete, count them as anchors
            lastDoneIdx = i
        elseif step._manualDone then
            lastDoneIdx = i
        end
    end

    -- Pass 2: starting from the step after the anchor, find the first
    -- incomplete step that passes all filters. If everything is done, land on the last step.
    local startIdx = lastDoneIdx + 1
    for i = startIdx, #guide.steps do
        local step = guide.steps[i]
        -- Skip steps that don't pass filters (rank, PRE, class, zone, etc.)
        if not self:ShouldShowStep(step, i) then
            -- Filtered step — treat as done for advancement purposes
        elseif not self:IsStepComplete(step) then
            self.stepIdx = i
            self:SaveState()
            -- Apply spatial routing: if multiple steps are active in the same
            -- zone, pick the closest one for the arrow to point at.
            self:ApplySpatialRouting(guide)
            self:UpdateWindow()
            if not silent then
                self:ShowToast("Step " .. self.stepIdx .. " / " .. #guide.steps)
            end
            return
        end
    end

    -- All steps complete (or guide has no quest steps at all)
    self.stepIdx = math.max(1, #guide.steps)
    self:SaveState()
    self:UpdateWindow()

    -- Route chaining: if this guide has a nextGuide, auto-transition.
    -- BUT: only chain if the guide had actual steps. Stub guides (0 steps)
    -- should NOT auto-chain — they represent "Quest Log Follow" mode where
    -- the player stays in that zone until they naturally finish and move on.
    if #guide.steps == 0 then
        -- Stub guide — stay here, Quest Log Follow mode handles display
        if not silent then
            self:ShowToast("Following: " .. (guide.title or self.guideID))
        end
        return
    end

    if guide.nextGuide and TA.Guides[guide.nextGuide] then
        local GP = TA:GetModule("GuideParser")
        local nextGuide = TA.Guides[guide.nextGuide]
        -- Only chain if the next guide is applicable to this player
        if not GP or GP:IsGuideApplicable(nextGuide) then
            if not silent then
                self:ShowToast("Guide complete! Next: " .. (nextGuide.title or guide.nextGuide))
            end
            self.guideID = guide.nextGuide
            self.stepIdx = 1
            self:FastForward(silent)  -- recurse to sync position in new guide
            return
        end
    end

    if not silent then
        self:ShowToast("Guide complete!")
    end
end

-- ── Guide management ──────────────────────────────────────────────────────────

-- Walk map hierarchy so a sub-zone player map still matches the guide's parent zone.
--- How closely does the player's current map match a guide's `zone`?
--- @return number|nil — 0 for an exact match, 1 for parent, 2 for grandparent,
---         and so on; nil when the guide's zone is not an ancestor at all.
---
--- Returning a distance rather than a boolean matters because guides legitimately
--- sit at different levels of the map tree. TAG_Midnight_Intro is keyed to
--- Quel'Thalas (2537) while TAG_Eversong_Midnight is keyed to Eversong (2395) —
--- and Eversong's parent *is* Quel'Thalas, so standing in Eversong matches both.
--- Without a specificity measure the winner came down to whichever had the lower
--- minLevel (and then alphabetical id), so the broad parent guide could beat the
--- specific zone guide. Callers should prefer the smallest distance.
local function MapZoneDistance(playerMapID, guideZone)
    if not guideZone or guideZone == 0 or not playerMapID then return nil end
    if playerMapID == guideZone then return 0 end
    local info, depth = C_Map.GetMapInfo(playerMapID), 0
    while info and info.parentMapID and info.parentMapID > 0 and depth < 12 do
        depth = depth + 1
        if info.parentMapID == guideZone then return depth end
        info = C_Map.GetMapInfo(info.parentMapID)
    end
    return nil
end

local function MapIsInZone(playerMapID, guideZone)
    return MapZoneDistance(playerMapID, guideZone) ~= nil
end

function QT:GetSortedGuideList()
    local list = {}
    for id, g in pairs(TA.Guides or {}) do
        table.insert(list, { id = id, title = g.title, minLevel = g.minLevel or 1 })
    end
    table.sort(list, function(a, b)
        return a.minLevel < b.minLevel or (a.minLevel == b.minLevel and a.id < b.id)
    end)
    return list
end

function QT:SetGuide(guideID)
    local guide = TA.Guides and TA.Guides[guideID]
    if not guide then return end
    self.guideID = guideID
    self.stepIdx = 1
    self._questLogFollowMode = (#guide.steps == 0)
    self:FastForward(true)   -- silently snap to the player's real position
    self:SaveState()
    -- Ensure BOTH views update (standalone tracker + drawer)
    self:UpdateWindow()
    if TA.db and TA.db.useUnifiedUI then
        self:UpdateDrawer()
    end
    -- Show the standalone tracker if not already visible
    if self.window and not self.window:IsVisible() then
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
    end
end

function QT:SmartMatchGuideFromLog()
    if not TA.Guides then return false end
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    if numEntries == 0 then return false end

    local activeIDs = {}
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            activeIDs[info.questID] = true
        end
    end

    local bestID, bestCount = nil, 0
    for id, guide in pairs(TA.Guides) do
        local count = 0
        for _, step in ipairs(guide.steps) do
            if step.questID and activeIDs[step.questID] then count = count + 1 end
        end
        if count > bestCount then bestCount = count; bestID = id end
    end

    -- Require at least 2 matching quests. A single match could be a quest that
    -- appears across multiple guides or a coincidental questID overlap — not
    -- strong enough signal to commit the player to a specific guide.
    if bestID and bestCount >= 2 then
        self:SetGuide(bestID)
        return true
    end

    -- Single match: accept it only if it's the ONLY guide with any match
    -- (unambiguous even at count=1).
    if bestID and bestCount == 1 then
        local ambiguous = false
        for id, guide in pairs(TA.Guides) do
            if id ~= bestID then
                for _, step in ipairs(guide.steps) do
                    if step.questID and activeIDs[step.questID] then
                        ambiguous = true; break
                    end
                end
            end
            if ambiguous then break end
        end
        if not ambiguous then
            self:SetGuide(bestID)
            return true
        end
    end

    return false
end

function QT:AutoSelectGuide()
    if self:SmartMatchGuideFromLog() then return end

    local level      = UnitLevel("player") or 1
    local currentMap = C_Map.GetBestMapForUnit("player")
    local list       = self:GetSortedGuideList()

    -- Pass 1: level + zone match, most specific zone wins.
    -- `list` is sorted by ascending minLevel, so iterating and taking the first
    -- hit would let a broad parent-zone guide beat the guide for the exact zone
    -- you're standing in. Score every candidate and keep the closest instead.
    local bestZoneID, bestDist = nil, math.huge
    for _, entry in ipairs(list) do
        local g = TA.Guides[entry.id]
        local levelMatch = level >= (g.minLevel or 1) and level <= (g.maxLevel or 999)
        if levelMatch then
            local dist = MapZoneDistance(currentMap, g.zone)
            -- Strict < keeps the existing sort order as the tie-breaker.
            if dist and dist < bestDist then
                bestDist   = dist
                bestZoneID = entry.id
            end
        end
    end
    if bestZoneID then
        self:SetGuide(bestZoneID)
        return
    end

    -- Pass 2: level match only — zone IDs on PTR guides are often placeholder
    -- map IDs (0 or wrong zone). If the zone doesn't match but the level does,
    -- pick the best level-range fit rather than leaving the player with nothing.
    local bestLevelID, bestLevelDiff = nil, math.huge
    for _, entry in ipairs(list) do
        local g = TA.Guides[entry.id]
        local gMin = g.minLevel or 1
        local gMax = g.maxLevel or 999
        if level >= gMin and level <= gMax then
            -- Prefer the guide whose midpoint is closest to the player's level
            local mid  = (gMin + gMax) / 2
            local diff = math.abs(level - mid)
            if diff < bestLevelDiff then
                bestLevelDiff = diff
                bestLevelID   = entry.id
            end
        end
    end
    if bestLevelID then
        self:SetGuide(bestLevelID)
        return
    end

    -- Pass 3: Universal starter fallback — if player is level 1-10 and nothing
    -- matched (e.g. in a race-specific starter zone with no dedicated guide),
    -- switch to Quest Log Follow mode. The tracker will show the player's
    -- supertracked quest from Blizzard's system directly.
    if level <= 10 then
        -- Try exiles_reach first (it covers the most common case)
        if TA.Guides["exiles_reach"] then
            -- Check if any Exile's Reach quests are in the log
            local erGuide = TA.Guides["exiles_reach"]
            for _, step in ipairs(erGuide.steps) do
                if step.questID and C_QuestLog.GetLogIndexForQuestID(step.questID) then
                    self:SetGuide("exiles_reach")
                    return
                end
            end
        end
        -- No Exile's Reach quests — player is in a race-specific zone.
        -- Set guideID to a special sentinel so the tracker shows quest-log mode.
        self.guideID = nil
        self.stepIdx = 1
        self._questLogFollowMode = true
        return
    end

    -- Pass 4: Any guide at all — absolute last resort for edge cases
    if #list > 0 then
        self:SetGuide(list[1].id)
        return
    end

    self.guideID = nil
    self.stepIdx = 1
end

-- ── Tracker diagnostic ────────────────────────────────────────────────────────
-- Prints to chat exactly what AutoSelectGuide sees: player level, current map,
-- loaded guides, and how many active quest log entries each guide matches.
-- Run /ta diagnose or /ta diag when the tracker shows "No Active Guide".
function QT:Diagnose()
    local p = function(msg) print("|cFFFFD100[TA Tracker]|r " .. msg) end

    local level      = UnitLevel("player") or 1
    local currentMap = C_Map.GetBestMapForUnit("player")
    local mapInfo    = currentMap and C_Map.GetMapInfo(currentMap)
    local mapName    = mapInfo and mapInfo.name or "unknown"

    p(string.format("Player: level %d  |  map %s (ID %s)",
        level, mapName, tostring(currentMap)))

    -- Active quest log
    local activeIDs = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            activeIDs[info.questID] = true
        end
    end
    p(string.format("Quest log: %d active quest(s)", #(function() local t={} for k in pairs(activeIDs) do t[#t+1]=k end return t end)()))

    -- Loaded guides
    local guides = TA.Guides or {}
    local count  = 0
    for _ in pairs(guides) do count = count + 1 end
    if count == 0 then
        p("|cFFFF4444No guides loaded. Check GuideParser output at login for errors.|r")
        return
    end
    p(string.format("%d guide(s) loaded:", count))

    local list = self:GetSortedGuideList()
    for _, entry in ipairs(list) do
        local g          = TA.Guides[entry.id]
        local gMin       = g.minLevel or 1
        local gMax       = g.maxLevel or 999
        local levelMatch = level >= gMin and level <= gMax
        local zoneMatch  = currentMap and MapIsInZone(currentMap, g.zone)

        -- Count quest log matches
        local matches = 0
        for _, step in ipairs(g.steps) do
            if step.questID and activeIDs[step.questID] then matches = matches + 1 end
        end

        local flags = {}
        if levelMatch then flags[#flags+1] = "|cFF4AFF7Alevel✓|r"  else flags[#flags+1] = "|cFFFF4444level✗|r" end
        if zoneMatch  then flags[#flags+1] = "|cFF4AFF7Azone✓|r"   else flags[#flags+1] = "|cFF888780zone✗|r"  end
        if matches > 0 then flags[#flags+1] = string.format("|cFFFFD100%d quest match(es)|r", matches) end

        p(string.format("  [%s] '%s'  lvl %d-%d  zone=%d  %s",
            entry.id, g.title, gMin, gMax, g.zone or 0,
            table.concat(flags, "  ")))
    end

    if self.guideID then
        p("Active guide: '" .. (TA.Guides[self.guideID] and TA.Guides[self.guideID].title or self.guideID) .. "'  step " .. self.stepIdx)
    else
        p("|cFFFF8800No guide selected. Use /ta autoselect or < > arrows in the tracker.|r")
    end
end

function QT:CycleGuide(dir)
    local list = self:GetSortedGuideList()
    if #list == 0 then return end
    local cur = 1
    for i, entry in ipairs(list) do
        if entry.id == self.guideID then cur = i; break end
    end
    cur = ((cur - 1 + dir + #list) % #list) + 1
    self:SetGuide(list[cur].id)
end

function QT:SaveState()
    if not TA.charDB then return end
    TA.charDB.tracker = TA.charDB.tracker or {}
    TA.charDB.tracker.guideID = self.guideID
    TA.charDB.tracker.stepIdx = self.stepIdx
end

-- ── Auto-Quest Engine ─────────────────────────────────────────────────────────
-- Guide-contextual helpers: extract the questID the current (and nearby) guide
-- steps are expecting so gossip selection can target them specifically rather
-- than blindly taking whatever NPC quest comes first.
local function GetGuideExpectedQuestIDs(self)
    if not self.guideID then return {} end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return {} end

    local ids = {}
    local startIdx = math.max(1, self.stepIdx - 1)
    local endIdx   = math.min(#guide.steps, self.stepIdx + 3)
    for i = startIdx, endIdx do
        local step = guide.steps[i]
        if step and step.questID then
            ids[step.questID] = true
        end
    end
    return ids
end

function QT:HandleAutoQuest(event)
    if not (TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest) then return end
    if IsShiftKeyDown() then return end

    -- ── Safety: NPC Blocklist ─────────────────────────────────────────
    -- NPCs that should NEVER be auto-accepted/completed because they have
    -- permanent consequences (spending currency, losing materials, branching
    -- choices). Based on Leatrix_Plus patterns.
    local targetGUID = UnitGUID("npc") or UnitGUID("questnpc") or ""
    local npcID = targetGUID:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)")
    npcID = npcID and tonumber(npcID)

    local NPC_BLOCKLIST = {
        -- Seal of Fate / Bonus Roll vendors (spend currency)
        [111243] = true, -- Archmage Timear (Seal of Tempered Fate)
        [87391]  = true, -- Fate-Twister Seress (Seal of Inevitable Fate)
        [142063] = true, -- Zurvan (Coins of Air)
        [199257] = true, -- Selector Renza (Aspect Tokens)
        -- Wartime Donation NPCs (lose trade goods)
        [142564] = true, [142993] = true, [143004] = true,
        [143005] = true, [143006] = true, [143007] = true,
        -- Choice NPCs that lock you into a path
        [18166]  = true, -- Khadgar (Aldor/Scryer choice)
        -- Reputation token turn-ins (Firewing Signets, etc.)
        [18257]  = true, -- Voren'thal the Seer (Scryer signets)
        [18252]  = true, -- Ishanah (Aldor marks)
    }

    if npcID and NPC_BLOCKLIST[npcID] then return end

    -- ── Safety: Quest ID Blocklist ────────────────────────────────────
    -- Quests with negative consequences if auto-completed (currency spend,
    -- consuming materials you might want to keep, etc.)
    local QUEST_BLOCKLIST = {
        -- Threads of Fate / campaign skip choices (irreversible)
        [62716] = true, [62714] = true, [60972] = true,
        -- Dragonflight waygate skip quests
        [72366] = true, [72367] = true,
    }

    if event == "QUEST_DETAIL" then
        -- Check if the offered quest is blocklisted
        local questID = GetQuestID and GetQuestID()
        if questID and QUEST_BLOCKLIST[questID] then return end

        -- Guide-Only Accept Mode: only auto-accept quests the guide expects
        if TA.charDB.tracker.autoQuestGuideOnly and questID then
            local expectedIDs = GetGuideExpectedQuestIDs(self)
            if not expectedIDs[questID] then return end
        end

        -- Safety: Don't auto-accept quests shared by unknown players.
        -- (QuestGetAutoAccept returns true for auto-accepted world quests)
        local offeredByPlayer = (QuestIsFromAreaTrigger and not QuestIsFromAreaTrigger())
                             and UnitIsPlayer("questnpc")
        if offeredByPlayer then
            -- Only auto-accept shares from friends/guild
            local name = UnitName("questnpc")
            local isFriend = name and (C_FriendList.IsFriend(name)
                          or (C_BattleNet and C_BattleNet.GetAccountInfoByGUID
                              and C_BattleNet.GetAccountInfoByGUID(UnitGUID("questnpc"))))
            local isGuild = name and IsInGuild() and UnitIsInMyGuild("questnpc")
            if not isFriend and not isGuild then return end
        end

        AcceptQuest()
        if QuestFrame and QuestFrame:IsShown() then
            HideUIPanel(QuestFrame)
        end

    elseif event == "QUEST_PROGRESS" then
        -- Safety: Don't auto-complete if quest requires currency or gold
        if QuestProgressRequiresGold and QuestProgressRequiresGold() then return end
        if GetQuestMoneyToGet and GetQuestMoneyToGet() > 0 then return end

        -- Safety: Don't auto-complete if progress items are crafting reagents
        -- or account-bound (warbound) items the player might want to keep
        local numItems = GetNumQuestItems and GetNumQuestItems() or 0
        for i = 1, numItems do
            local _, _, numRequired = GetQuestItemInfo("required", i)
            if numRequired and numRequired > 0 then
                local link = GetQuestItemLink("required", i)
                if link then
                    local _, _, _, _, _, itemType, itemSubType = C_Item.GetItemInfo(link)
                    -- Block if it's a trade good / crafting reagent
                    if itemType == "Tradeskill" or itemSubType == "Reagent" then return end
                end
            end
        end

        if IsQuestCompletable() then CompleteQuest() end

    elseif event == "QUEST_COMPLETE" then
        local numChoices = GetNumQuestChoices()

        -- No choices or single reward: auto-complete
        if numChoices <= 1 then
            GetQuestReward(numChoices == 1 and 1 or nil)
            return
        end

        -- Multiple choices: check if the guide specifies a preferred reward
        local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
        if guide then
            local step = guide.steps[self.stepIdx]
            if step and step.reward then
                -- Match the guide's preferred reward itemID against the choices
                for i = 1, numChoices do
                    local link = GetQuestItemLink("choice", i)
                    if link then
                        local itemID = GetItemInfoInstant(link)
                        if itemID == step.reward then
                            GetQuestReward(i)
                            return
                        end
                    end
                end
            end
        end

        -- Multiple choices, no guide preference: pick highest ilvl/score upgrade
        -- This is the Zygor-like "smart reward" — always picks the biggest upgrade.
        local bestIdx, bestScore = 1, -1
        local GearMod = TA:GetModule("Gear")
        for i = 1, numChoices do
            local link = GetQuestItemLink("choice", i)
            if link then
                local ilvl = U.GetItemIlvl and U.GetItemIlvl(link) or 0
                local score = ilvl  -- default to ilvl comparison
                -- Use Gear module's scoring if available
                if GearMod and GearMod.ScoreItem then
                    local s = GearMod:ScoreItem(link)
                    if s and s > 0 then score = s end
                end
                if score > bestScore then
                    bestScore = score
                    bestIdx = i
                end
            end
        end
        GetQuestReward(bestIdx)
        -- (don't auto-complete — this is the correct behavior)

    elseif event == "GOSSIP_SHOW" then
        if not C_GossipInfo then return end
        local expectedIDs = GetGuideExpectedQuestIDs(self)

        -- Safety: Don't auto-interact with gossip if options contain color
        -- codes or angle-bracket markers (indicates skip/choice dialogs like
        -- Threads of Fate, Chromie Time selectors, etc.)
        local gossipOptions = C_GossipInfo.GetOptions and C_GossipInfo.GetOptions()
        if gossipOptions then
            for _, opt in ipairs(gossipOptions) do
                local name = opt.name or ""
                if name:find("|c") or name:find("<") then
                    -- Potentially dangerous gossip choice — don't auto-interact
                    return
                end
            end
        end

        -- Phase 1: check active (in-progress) quests — try to turn in guide quests first.
        local active = C_GossipInfo.GetActiveQuests()
        if active then
            for _, q in ipairs(active) do
                if q.isComplete and expectedIDs[q.questID] then
                    C_GossipInfo.SelectActiveQuest(q.questID)
                    return
                end
            end
            for _, q in ipairs(active) do
                if q.isComplete then
                    C_GossipInfo.SelectActiveQuest(q.questID)
                    return
                end
            end
        end

        -- Phase 2: accept an available quest — guide-expected quests first.
        local available = C_GossipInfo.GetAvailableQuests()
        if available then
            for _, q in ipairs(available) do
                if expectedIDs[q.questID] then
                    C_GossipInfo.SelectAvailableQuest(q.questID)
                    return
                end
            end
            if available[1] then
                C_GossipInfo.SelectAvailableQuest(available[1].questID)
            end
        end

    elseif event == "QUEST_GREETING" then
        local expectedIDs = GetGuideExpectedQuestIDs(self)

        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            if isComplete then
                SelectActiveQuest(i)
                return
            end
        end
        if GetNumAvailableQuests() > 0 then
            SelectAvailableQuest(1)
        end
    end
end
-- ── Blizzard tracker ─────────────────────────────────────────────────────────

function QT:UpdateBlizzardTrackerVisibility()
    if not (TA.charDB and TA.charDB.tracker) then return end
    local shouldHide = TA.charDB.tracker.replaceBlizzTracker
                    and self.window and self.window:IsVisible()
    if ObjectiveTrackerFrame then
        if shouldHide then ObjectiveTrackerFrame:Hide() else ObjectiveTrackerFrame:Show() end
    end
end

-- ── Events ────────────────────────────────────────────────────────────────────

function QT:OnEvent(event, ...)
    if event == "QUEST_DETAIL"   or event == "QUEST_PROGRESS"
    or event == "QUEST_COMPLETE" or event == "GOSSIP_SHOW"
    or event == "QUEST_GREETING" then
        self:HandleAutoQuest(event)
        return
    end

    if event == "QUEST_ACCEPTED"           or event == "QUEST_TURNED_IN"
    or event == "QUEST_LOG_UPDATE"         or event == "UNIT_QUEST_LOG_CHANGED"
    or event == "QUEST_WATCH_LIST_CHANGED" then
        if not self.guideID then return end
        -- QUEST_LOG_UPDATE and UNIT_QUEST_LOG_CHANGED fire repeatedly during
        -- a single turn-in/loot/zone-change sequence (often 10-20 times in one
        -- frame). Coalesce them into one FastForward via a 0.15s debounce so
        -- we do one guide-step scan per real event cluster, not one per firing.
        if logSyncTimer then return end
        logSyncTimer = C_Timer.After(LOG_SYNC_DELAY, function()
            logSyncTimer = nil
            if QT.guideID then QT:FastForward(true) end
        end)

    elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdateWindow()
    end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function QT:Init()
    -- QUEST_ACCEPTED is in Core/Init.lua PERSISTENT_EVENTS — no re-registration needed.
    TA.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    TA.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    TA.eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    TA.eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    TA.eventFrame:RegisterEvent("QUEST_DETAIL")
    TA.eventFrame:RegisterEvent("QUEST_PROGRESS")
    TA.eventFrame:RegisterEvent("QUEST_COMPLETE")
    TA.eventFrame:RegisterEvent("GOSSIP_SHOW")
    TA.eventFrame:RegisterEvent("QUEST_GREETING")

    -- Preserve existing saved settings; only apply defaults for missing keys
    TA.charDB.tracker = TA.charDB.tracker or {}
    local t = TA.charDB.tracker
    if t.autoQuest           == nil then t.autoQuest           = false end
    if t.replaceBlizzTracker == nil then t.replaceBlizzTracker = false end
    if t.cutsceneSkip        == nil then t.cutsceneSkip        = false end
    if t.autoEquip           == nil then t.autoEquip           = false end
    if t.autoQuestGuideOnly  == nil then t.autoQuestGuideOnly  = false end
    if t.rank                == nil then t.rank                = 2     end  -- 1=speed, 2=normal, 3=completionist

    -- Guide display settings
    if t.showAvailableQuests  == nil then t.showAvailableQuests  = true  end
    if t.smallMapPins         == nil then t.smallMapPins         = false end
    if t.showCategoryGrid     == nil then t.showCategoryGrid     = false end
    if t.showCategoryHeaders  == nil then t.showCategoryHeaders  = true  end
    if t.groupCompleted       == nil then t.groupCompleted       = true  end
    if t.groupIgnored         == nil then t.groupIgnored         = true  end
    if t.showQuestChainTooltip == nil then t.showQuestChainTooltip = true end
    if t.spoilerFree          == nil then t.spoilerFree          = false end
    if t.useTomTomWaypoints   == nil then t.useTomTomWaypoints   = false end
    if t.accountBound         == nil then t.accountBound         = false end

    if t.guideID and TA.Guides and TA.Guides[t.guideID] then
        self.guideID = t.guideID
        self.stepIdx = t.stepIdx or 1
        self:FastForward(true)   -- re-sync on login in case progress happened offline
    elseif t.guideID then
        -- Guide was saved but isn't loaded yet (e.g. BtWQuests LoadOnDemand).
        -- Try a deferred restore after 2 seconds when imports may have finished.
        self.guideID = nil
        self.stepIdx = 1
        C_Timer.After(2, function()
            if not QT.guideID and t.guideID and TA.Guides and TA.Guides[t.guideID] then
                QT.guideID = t.guideID
                QT.stepIdx = t.stepIdx or 1
                QT:FastForward(true)
                QT:UpdateWindow()
            elseif not QT.guideID then
                -- Still no guide after deferred wait — scan quest log
                QT:AutoSelectGuide()
                if QT.guideID then QT:UpdateWindow() end
            end
        end)
    else
        self:AutoSelectGuide()
    end

    self:InitWindow()

    -- ALWAYS show the tracker on login if a guide is active (or will be).
    -- The 10/10 experience means the player never has to manually open anything.
    if self.guideID then
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
        self:UpdateBlizzardTrackerVisibility()
    elseif t.visible then
        self.window:Show()
        self:UpdateBlizzardTrackerVisibility()
    else
        -- No guide found yet — show anyway so player sees "scanning..." state
        -- rather than an invisible addon. Deferred: if AutoSelectGuide fires
        -- from the quest log scan, the window will update automatically.
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
    end

    -- Proactive quest log full detection — notify player after a brief delay
    -- so the window is visible and the toast has somewhere to show.
    C_Timer.After(3, function()
        if not QT.window then return end
        local MAX_QUESTS = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 35
        local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
        local count = 0
        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader then count = count + 1 end
        end
        if count >= MAX_QUESTS - 1 then
            QT:ShowToast("Quest log full (" .. count .. "/" .. MAX_QUESTS .. ") — right-click to clean up", 5)
        end
    end)
end

-- ── Window layout constants ───────────────────────────────────────────────────

local W, H = 310, 230
local PAD  = 8

local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
}

local function ApplyBD(f, br, bg, bb, ba, er, eg, eb)
    f:SetBackdrop(BD)
    f:SetBackdropColor(br, bg, bb, ba or 0.96)
    f:SetBackdropBorderColor(er or 0.55, eg or 0.40, eb or 0.08, 0.85)
end

local function Divider(parent, yOfs)
    local d = parent:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.55, 0.40, 0.08, 0.50)
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD, yOfs)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, yOfs)
end

local function MakeBtn(parent, w, h, label, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    if TA.Modern and TA.Modern.ApplyBackdrop then
        TA.Modern:ApplyBackdrop(btn, "card")
    else
        ApplyBD(btn, 0.18, 0.13, 0.01, 0.90, 0.55, 0.40, 0.08)
    end
    btn:EnableMouse(true)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    lbl:SetText(label)
    lbl:SetTextColor(1.00, 0.82, 0.00, 1.00)
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    btn:SetScript("OnClick",  onClick)
    btn:SetScript("OnEnter",  function(f) f:SetBackdropColor(0.30, 0.22, 0.03, 0.95) end)
    btn:SetScript("OnLeave",  function(f) f:SetBackdropColor(0.18, 0.13, 0.01, 0.90) end)
    btn._lbl = lbl
    return btn
end

local function MakeCheckbox(parent, x, y, label, dbKey, onChange)
    local cb = CreateFrame("Button", nil, parent, "BackdropTemplate")
    cb:SetSize(14, 14)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    ApplyBD(cb, 0.05, 0.05, 0.05, 1, 0.55, 0.40, 0.08)
    local chk = cb:CreateTexture(nil, "OVERLAY")
    chk:SetColorTexture(1, 0.82, 0, 1)
    chk:SetPoint("CENTER")
    chk:SetSize(8, 8)
    if TA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
    local lblStr = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblStr:SetFont(STANDARD_TEXT_FONT, 10, "")
    lblStr:SetText(label)
    lblStr:SetTextColor(0.88, 0.83, 0.65, 1)
    lblStr:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    cb:SetScript("OnClick", function()
        TA.charDB.tracker[dbKey] = not TA.charDB.tracker[dbKey]
        if TA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
        if onChange then onChange(TA.charDB.tracker[dbKey]) end
    end)
    return cb
end

local BADGE = {
    quest     = "|cFFFFD100", travel    = "|cFF1EBCFF", npc       = "|cFF78FF78",
    item      = "|cFFBB99FF", action    = "|cFFFF8833", text      = "|cFF999999",
    accept    = "|cFF4AFF7A",  -- green — complete once the quest is in the log
    pickup    = "|cFF4AFF7A",  -- green — accept quest
    turnin    = "|cFFFFD100",  -- gold  — turn in quest
    objective = "|cFFFFAA33",  -- orange — complete specific objective
    waypoint  = "|cFF1EBCFF",  -- blue  — travel waypoint (auto-skip if flying)
    flyto     = "|cFF55CCFF",  -- light blue — take flight path
    sethearth = "|cFFCC66FF",  -- purple — set hearthstone
}
local QUEST_STATUS = {
    complete   = "|cFF1EFF00[Complete]|r",
    turnin     = "|cFFFFD100[Ready to Turn In]|r",
    inprogress = "|cFF888780[In Progress]|r",
    available  = "|cFFAAAAAA[Not Started]|r",
}

-- ── InitWindow ────────────────────────────────────────────────────────────────

function QT:InitWindow()
    local win = CreateFrame("Frame", "TATrackerWindow", UIParent, "BackdropTemplate")
    win:SetSize(W, H)
    win:SetFrameStrata("HIGH")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetClampedToScreen(true)
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if TA.charDB then
            TA.charDB.tracker.x = f:GetLeft()
            TA.charDB.tracker.y = f:GetTop()
        end
    end)

    -- ── Right-Click Context Menu on the Tracker ──────────────────────────────
    -- This is the ENTIRE command surface for 10/10 UX. No slash commands needed.
    win:SetScript("OnMouseUp", function(f, button)
        if button == "RightButton" then
            QT:ShowTrackerMenu(f)
        end
    end)
    if TA.Modern and TA.Modern.ApplyGlassBackdrop then
        TA.Modern:ApplyGlassBackdrop(win)
    else
        ApplyBD(win, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)
    end

    local saved = TA.charDB and TA.charDB.tracker
    if saved and saved.x and saved.y then
        win:ClearAllPoints()
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    win:Hide()

    -- ── Title bar ────────────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, win, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(28)
    if TA.Modern and TA.Modern.ApplyBackdrop then
        TA.Modern:ApplyBackdrop(titleBar, "header")
    else
        ApplyBD(titleBar, 0.18, 0.13, 0.01, 1.00, 0.55, 0.40, 0.08)
    end

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    titleLabel:SetText("|cFFEBE8DEToonAge|r")
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)

    local xBtn = MakeBtn(titleBar, 22, 22, "x", function() self:ToggleWindow() end)
    xBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    xBtn._lbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    xBtn._lbl:SetTextColor(0.85, 0.30, 0.15, 1)

    -- "=" settings button → opens centralized settings drawer
    local optBtn = MakeBtn(titleBar, 22, 22, "=", function()
        TA:ToggleOptionsPanel()
    end)
    optBtn:SetPoint("RIGHT", xBtn, "LEFT", -3, 0)

    -- "Guides" button → opens main UI to Guide tab
    local browseBtn = MakeBtn(titleBar, 50, 22, "Guides", function()
        if TA.UI then
            if not TA.UI:IsVisible() then TA.UI:Show() end
            TA.UI:SetTab("guide")
        end
    end)
    browseBtn:SetPoint("RIGHT", optBtn, "LEFT", -3, 0)
    browseBtn._lbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    browseBtn._lbl:SetTextColor(0.29, 0.65, 1.00, 1)

    -- Legacy optionsFrame reference (some code references self.optionsFrame)
    -- Create a minimal hidden frame so :IsShown() calls don't error
    local optPanel = CreateFrame("Frame", nil, win)
    optPanel:SetSize(1, 1)
    optPanel:Hide()
    self.optionsFrame = optPanel

    -- ── Guide navigation row ─────────────────────────────────────────────────
    local prevBtn = MakeBtn(win, 24, 20, "<", function() self:CycleGuide(-1) end)
    prevBtn:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -34)

    local nextBtn = MakeBtn(win, 24, 20, ">", function() self:CycleGuide(1) end)
    nextBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -34)

    -- Browse button (opens guide shelf/picker)
    local browseBtn = MakeBtn(win, 20, 20, "☰", function()
        if TA.UI then
            if not TA.UI:IsVisible() then TA.UI:Show() end
            TA.UI:SetTab("guide")
        end
    end)
    browseBtn:SetPoint("RIGHT", nextBtn, "LEFT", -2, 0)
    browseBtn:SetScript("OnEnter", function(f)
        f:SetBackdropColor(0.30, 0.22, 0.03, 0.95)
        GameTooltip:SetOwner(f, "ANCHOR_TOP")
        GameTooltip:SetText("Browse All Guides")
        GameTooltip:AddLine("Organized by expansion & zone", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    browseBtn:SetScript("OnLeave", function(f)
        f:SetBackdropColor(0.18, 0.13, 0.01, 0.90)
        GameTooltip:Hide()
    end)

    win.guideTitleF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.guideTitleF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    win.guideTitleF:SetTextColor(1.00, 0.95, 0.75, 1)
    win.guideTitleF:SetPoint("LEFT",  prevBtn, "RIGHT", 4, 0)
    win.guideTitleF:SetPoint("RIGHT", browseBtn, "LEFT", -4, 0)
    win.guideTitleF:SetJustifyH("CENTER")

    -- ── Step area ────────────────────────────────────────────────────────────
    Divider(win, -58)

    win.stepNumF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepNumF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepNumF:SetTextColor(0.70, 0.55, 0.25, 1)
    win.stepNumF:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -64)

    win.stepBadgeF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepBadgeF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepBadgeF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -64)

    -- Step text + injected objectives, capped above the second divider.
    -- SetHeight(65): -80 top + 65px = -145, five pixels before the -150 divider.
    win.stepTextF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepTextF:SetFont(STANDARD_TEXT_FONT, 11, "")
    win.stepTextF:SetTextColor(0.92, 0.92, 0.88, 1)
    win.stepTextF:SetPoint("TOPLEFT",  win, "TOPLEFT",  PAD,  -80)
    win.stepTextF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -80)
    win.stepTextF:SetHeight(65)
    win.stepTextF:SetJustifyH("LEFT")
    win.stepTextF:SetWordWrap(true)
    win.stepTextF:SetNonSpaceWrap(false)

    -- ── Quest status / objective area ─────────────────────────────────────────
    Divider(win, -150)

    -- Next-step preview: sits in the unused gap between the divider (-150)
    -- and questStatusF's occupied area (~-178 upward from its y=38 anchor).
    win.nextStepF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.nextStepF:SetFont(STANDARD_TEXT_FONT, 9, "")
    win.nextStepF:SetTextColor(0.52, 0.48, 0.34, 1)
    win.nextStepF:SetPoint("TOPLEFT",  win, "TOPLEFT",  PAD,  -156)
    win.nextStepF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -156)
    win.nextStepF:SetJustifyH("LEFT")
    win.nextStepF:SetWordWrap(false)

    win.questStatusF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.questStatusF:SetFont(STANDARD_TEXT_FONT, 10, "")
    win.questStatusF:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, 38)
    win.questStatusF:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, 38)
    win.questStatusF:SetJustifyH("LEFT")

    -- Contextual tip line: rotating insights from XPTracker, RestOptimizer,
    -- SpecAdaptive, SocialAwareness, ProfQuesting, etc.
    win.tipF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.tipF:SetFont(STANDARD_TEXT_FONT, 9, "")
    win.tipF:SetTextColor(0.55, 0.75, 0.90, 1)
    win.tipF:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, 24)
    win.tipF:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, 24)
    win.tipF:SetJustifyH("LEFT")
    win.tipF:SetWordWrap(false)

    -- ── Bottom buttons ────────────────────────────────────────────────────────
    local backBtn = MakeBtn(win, 60, 22, "< Back", function()
        if not self.guideID then return end
        self.stepIdx = math.max(1, self.stepIdx - 1)
        self:SaveState()
        self:UpdateWindow()
    end)
    backBtn:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, PAD)

    win.doneBtn = MakeBtn(win, 108, 22, "Mark Done >", function()
        if not self.guideID then return end
        local guide = TA.Guides and TA.Guides[self.guideID]
        if not guide then return end
        local step = guide.steps[self.stepIdx]
        if step then step._manualDone = true end
        for i = self.stepIdx, #guide.steps do
            if not self:IsStepComplete(guide.steps[i]) then
                self.stepIdx = i; break
            end
        end
        self:SaveState()
        self:UpdateWindow()
        -- Signal the step advance: fade the new step text in rather than
        -- having it just snap into place.
        UIFrameFadeIn(win.stepTextF, 0.25, 0, 1)
    end)
    win.doneBtn:SetPoint("BOTTOM", win, "BOTTOM", 0, PAD)

    -- >> Sync: cross-references entire guide against quest log and snaps to position
    local ffwdBtn = MakeBtn(win, 60, 22, ">> Sync", function()
        self:FastForward()
    end)
    ffwdBtn:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, PAD)

    -- Throttled live distance/ETA refresh. WoW only fires OnUpdate while the
    -- frame is shown, so this naturally does nothing while the tracker is hidden.
    win:SetScript("OnUpdate", function(_, elapsed)
        self.statusThrottle = self.statusThrottle + elapsed
        if self.statusThrottle < STATUS_UPDATE_HZ then return end
        self.statusThrottle = 0
        self:RenderStatusLine()
        self:UpdateQuestItemButton()
        self:CheckProximityAdvance()
    end)

    -- ── Quest Item Button ─────────────────────────────────────────────────────
    -- A floating, click-to-use button that appears when the current guide step
    -- specifies a questItem (itemID).  Mirrors WoW-Pro's "quest item button"
    -- feature: the player clicks it instead of hunting for the item in bags.
    --
    -- The button is parented to UIParent (not the tracker window) so it can be
    -- independently positioned and remains visible even if the tracker is closed.
    -- Saved position: charDB.questItem.x / .y (TOPLEFT relative to BOTTOMLEFT).
    -- SecureActionButtonTemplate is required so the actual "use item" action
    -- survives combat lockdown. type/item attributes may only be written
    -- outside combat (guarded in UpdateQuestItemButton below) — but once
    -- set, the click-to-use itself works in or out of combat since Blizzard's
    -- own secure click handling performs it, not our Lua OnClick.
    local qib = CreateFrame("Button", "TAQuestItemButton", UIParent, "SecureActionButtonTemplate, BackdropTemplate")
    qib:SetSize(46, 46)
    qib:SetFrameStrata("HIGH")
    qib:SetMovable(true)
    qib:EnableMouse(true)
    qib:RegisterForDrag("LeftButton")
    qib:SetClampedToScreen(true)
    qib:SetAttribute("type", "item")
    qib:SetScript("OnDragStart", qib.StartMoving)
    qib:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        TA.charDB.questItem = TA.charDB.questItem or {}
        TA.charDB.questItem.x = f:GetLeft()
        TA.charDB.questItem.y = f:GetTop()
    end)

    -- Restore saved position or default below the tracker.
    local qibSaved = TA.charDB and TA.charDB.questItem
    if qibSaved and qibSaved.x and qibSaved.y then
        qib:ClearAllPoints()
        qib:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", qibSaved.x, qibSaved.y)
    else
        qib:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end

    ApplyBD(qib, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)

    local qibTex = qib:CreateTexture(nil, "ARTWORK")
    qibTex:SetPoint("TOPLEFT",  qib, "TOPLEFT",  3, -3)
    qibTex:SetPoint("BOTTOMRIGHT", qib, "BOTTOMRIGHT", -3, 3)
    qib.iconTex = qibTex

    -- Cooldown overlay (standard WoW cooldown swipe)
    local qibCD = CreateFrame("Cooldown", nil, qib, "CooldownFrameTemplate")
    qibCD:SetAllPoints(qibTex)
    qibCD:SetDrawEdge(true)
    qib.cooldownFrame = qibCD

    -- Count / stack text
    local qibCount = qib:CreateFontString(nil, "OVERLAY")
    qibCount:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    qibCount:SetTextColor(1, 1, 1, 1)
    qibCount:SetPoint("BOTTOMRIGHT", qib, "BOTTOMRIGHT", -3, 3)
    qibCount:SetJustifyH("RIGHT")
    qib.countF = qibCount

    qib:SetScript("OnEnter", function(f)
        if not f._itemID then return end
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(f._itemID)
        GameTooltip:Show()
    end)
    qib:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- No OnClick script: this is a secure "type=item" button now, so
    -- Blizzard's own protected click handling performs the actual item use
    -- based on the "item" attribute set in UpdateQuestItemButton. Adding a
    -- manual OnClick that calls UseContainerItem here would reintroduce the
    -- combat-taint problem this change exists to avoid.

    qib:Hide()
    win.questItemBtn = qib

    self.window = win
    self:UpdateWindow()
end

-- ── UpdateQuestItemButton ─────────────────────────────────────────────────────
-- Called on the OnUpdate throttle. Shows the quest-item button when the current
-- step has a questItem field AND that item exists in the player's bags.

function QT:UpdateQuestItemButton()
    local win = self.window
    if not (win and win.questItemBtn) then return end
    local qib = win.questItemBtn

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local step  = guide and guide.steps[self.stepIdx]
    local itemID = step and step.questItem

    if not itemID then
        qib:Hide()
        qib._itemID = nil
        return
    end

    -- Count how many we have in bags
    local count = 0
    for bag = 0, 4 do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                   or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local id
            if C_Container and C_Container.GetContainerItemID then
                id = C_Container.GetContainerItemID(bag, slot)
            else
                id = GetContainerItemID(bag, slot)
            end
            if id == itemID then
                if C_Container and C_Container.GetContainerItemInfo then
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    count = count + (info and info.stackCount or 1)
                else
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    count = count + (itemCount or 1)
                end
            end
        end
    end

    if count == 0 then
        qib:Hide()
        qib._itemID = nil
        return
    end

    qib._itemID = itemID

    -- Set icon from item cache (may require a server round-trip on first call)
    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if itemTexture then
        qib.iconTex:SetTexture(itemTexture)
    else
        qib.iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Secure "item" attribute drives the actual click-to-use action and can
    -- only be written outside combat. If the step changes mid-combat before
    -- the name is known, the button stays on whatever item it last pointed
    -- at until combat ends and this runs again — a known secure-button
    -- limitation, not a bug.
    if itemName and not InCombatLockdown() and qib:GetAttribute("item") ~= itemName then
        qib:SetAttribute("item", itemName)
    end

    qib.countF:SetText(count > 1 and tostring(count) or "")

    -- Cooldown sweep
    local start, duration = GetItemCooldown(itemID)
    if start and start > 0 then
        qib.cooldownFrame:SetCooldown(start, duration)
    else
        qib.cooldownFrame:SetCooldown(0, 0)
    end

    qib:Show()
end

-- ── UpdateWindow ──────────────────────────────────────────────────────────────

function QT:UpdateWindow()
    local win = self.window
    if not win then return end

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]

    if not guide then
        -- Instead of showing a dead "No Active Guide" state, actively try to
        -- find a guide from the quest log. The player should NEVER see this
        -- state for more than a brief moment.
        if not self._autoSelectAttempted then
            self._autoSelectAttempted = true
            C_Timer.After(0.5, function()
                if not QT.guideID then
                    QT:AutoSelectGuide()
                    if QT.guideID then
                        QT:UpdateWindow()
                        QT:ShowToast("Following: " .. (TA.Guides[QT.guideID].title or QT.guideID))
                    else
                        QT:UpdateWindow()
                    end
                end
            end)
        end

        win.guideTitleF:SetText("|cFF888780Scanning quests...|r")
        win.stepNumF:SetText("")
        win.stepBadgeF:SetText("")

        local loaded = 0
        for _ in pairs(TA.Guides or {}) do loaded = loaded + 1 end

        -- Detect quest log capacity
        local numQuests = C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() or 0
        local MAX_QUESTS = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 35
        -- Count actual quests (not headers)
        local actualQuestCount = 0
        for i = 1, numQuests do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader then
                actualQuestCount = actualQuestCount + 1
            end
        end
        local isLogFull = (actualQuestCount >= MAX_QUESTS - 1)  -- -1 buffer

        local body
        if loaded == 0 then
            body = "|cFFFF4444No guides loaded.|r\n"
               .. "Check for GuideParser errors at login."
        elseif isLogFull then
            -- FULL QUEST LOG — offer both paths: finish quests OR drop old ones
            win.guideTitleF:SetText("|cFFFF9A1AQuest Log Full|r")
            body = string.format(
                "|cFFFF9A1AYour quest log is full (%d/%d).|r\n\n"
             .. "|cFFFFD100Right-click this tracker|r for options:\n\n"
             .. "|cFF4AFF7A• Quest Log Advisor|r\n"
             .. "  See which quests are closest to done.\n"
             .. "  Finish them to free slots naturally.\n\n"
             .. "|cFFFF9A1A• Clean Up Quest Log|r\n"
             .. "  Drop old/grey quests you've outleveled.",
                actualQuestCount, MAX_QUESTS)
        else
            -- ── QUEST LOG FOLLOW MODE ─────────────────────────────────────
            -- No guide matches this zone. Instead of a dead state, show the
            -- player's currently tracked/supertracked quest from WoW's system.
            -- This gives useful guidance in any zone without guide data.
            local trackedQuestID = nil
            local trackedTitle = nil
            local trackedObjectives = nil

            -- Try supertracked quest first
            if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
                trackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
                if trackedQuestID and trackedQuestID > 0 then
                    trackedTitle = C_QuestLog.GetTitleForQuestID(trackedQuestID)
                    trackedObjectives = C_QuestLog.GetQuestObjectives(trackedQuestID)
                end
            end

            -- Fallback: find the first in-progress quest in the log
            if not trackedTitle then
                local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
                for i = 1, numEntries do
                    local info = C_QuestLog.GetInfo(i)
                    if info and not info.isHeader and info.questID then
                        local idx = C_QuestLog.GetLogIndexForQuestID(info.questID)
                        if idx and not C_QuestLog.IsQuestFlaggedCompleted(info.questID) then
                            trackedQuestID = info.questID
                            trackedTitle = info.title
                            trackedObjectives = C_QuestLog.GetQuestObjectives(info.questID)
                            break
                        end
                    end
                end
            end

            if trackedTitle then
                win.guideTitleF:SetText("|cFF1EBCFFFollowing Quest Log|r")

                local lines = {}
                lines[#lines + 1] = "|cFFFFD100" .. trackedTitle .. "|r"

                if trackedObjectives and #trackedObjectives > 0 then
                    for _, obj in ipairs(trackedObjectives) do
                        if obj.text and obj.text ~= "" then
                            local clr = obj.finished and "|cFF4AFF7A✓ " or "|cFFFFFFFF  "
                            lines[#lines + 1] = clr .. obj.text .. "|r"
                        end
                    end
                end

                lines[#lines + 1] = ""
                lines[#lines + 1] = "|cFF888780No ToonAge guide for this zone yet.|r"
                lines[#lines + 1] = "|cFF888780Following your quest tracker instead.|r"

                body = table.concat(lines, "\n")

                -- Point the arrow at this quest's waypoint
                if trackedQuestID and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                    pcall(C_SuperTrack.SetSuperTrackedQuestID, trackedQuestID)
                end
            else
                body = "|cFF888780No active quests found.|r\n\n"
                   .. "Pick up a quest from a nearby NPC\n"
                   .. "and ToonAge will start tracking it."
            end
        end

        win.stepTextF:SetText(body)
        win.questStatusF:SetText("")
        win.nextStepF:SetText("")
        win.doneBtn._lbl:SetText("Mark Done >")
        win.doneBtn:SetBackdropColor(0.10, 0.08, 0.01, 0.70)
        return
    end

    local total = #guide.steps

    -- Stub guide (0 steps) — show Quest Log Follow mode with the guide's title
    if total == 0 then
        win.guideTitleF:SetText(guide.title or "Guide")
        win.stepNumF:SetText("|cFF1EBCFFQuest Log Follow|r")
        win.stepBadgeF:SetText("")

        -- Show tracked quest from Blizzard's system
        local trackedQuestID, trackedTitle, trackedObjectives
        if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
            trackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
            if trackedQuestID and trackedQuestID > 0 then
                trackedTitle = C_QuestLog.GetTitleForQuestID(trackedQuestID)
                trackedObjectives = C_QuestLog.GetQuestObjectives(trackedQuestID)
            end
        end
        if not trackedTitle then
            local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
            for i = 1, numEntries do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID
                   and not C_QuestLog.IsQuestFlaggedCompleted(info.questID) then
                    trackedQuestID = info.questID
                    trackedTitle = info.title
                    trackedObjectives = C_QuestLog.GetQuestObjectives(info.questID)
                    break
                end
            end
        end

        if trackedTitle then
            local lines = {}
            lines[#lines+1] = "|cFFFFD100" .. trackedTitle .. "|r"
            if trackedObjectives then
                for _, obj in ipairs(trackedObjectives) do
                    if obj.text and obj.text ~= "" then
                        local clr = obj.finished and "|cFF4AFF7A\226\156\147 " or "|cFFFFFFFF  "
                        lines[#lines+1] = clr .. obj.text .. "|r"
                    end
                end
            end
            win.stepTextF:SetText(table.concat(lines, "\n"))
        else
            win.stepTextF:SetText("|cFF888780Follow quests in this zone.\nThe arrow tracks your active quest.|r")
        end

        win.questStatusF:SetText("")
        win.nextStepF:SetText("|cFF888780Guide data coming soon — using quest tracker|r")

        -- Ensure arrow points to tracked quest
        if trackedQuestID and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
            pcall(C_SuperTrack.SetSuperTrackedQuestID, trackedQuestID)
        end

        -- Contextual hint
        local hint = "|cFF1EBCFF\226\134\146 Following your quest log|r"
        win.tipF:SetText(hint)
        return
    end

    self.stepIdx = math.max(1, math.min(total, self.stepIdx))
    local step = guide.steps[self.stepIdx]

    local titleStr = guide.title
    if #titleStr > 30 then titleStr = titleStr:sub(1, 27) .. "..." end
    win.guideTitleF:SetText(titleStr)
    win.stepNumF:SetText("Step " .. self.stepIdx .. " / " .. total)

    local sType = step.type or "text"
    self._badgeBase = (BADGE[sType] or "|cFFFFFFFF") .. "[" .. sType:upper() .. "]|r"
    win.stepBadgeF:SetText(self._badgeBase)

    if not self:IsStepApplicable(step) then
        win.stepTextF:SetText("|cFF888780(Not applicable to your spec/class — skipped)|r")
    else
        -- Fixed-height text region (see stepTextF setup in InitWindow): title,
        -- step prose, and the stub-coord hint always fit and always show.
        -- Live objectives are the one open-ended part (a quest can have 4-5
        -- sub-objectives), so they're the part we trim if the text overflows
        -- the box, rather than letting it spill into the divider below.
        local headLines = {}

        -- Line 1: live quest title from client (gold) if available
        if step.questID then
            local liveTitle = C_QuestLog.GetTitleForQuestID
                           and C_QuestLog.GetTitleForQuestID(step.questID)
            if liveTitle and liveTitle ~= "" then
                headLines[#headLines + 1] = "|cFFFFD100" .. liveTitle .. "|r"
            end
        end

        -- Line 1.5: Smart action status — tell the player WHAT to do
        if step.questID then
            local questStatus = self:GetQuestStatus(step.questID)
            if questStatus == "available" then
                -- Quest not in log, not complete — player needs to PICK IT UP
                headLines[#headLines + 1] = "|cFF4AFF7A→ Go pick up this quest|r"
            elseif questStatus == "turnin" then
                headLines[#headLines + 1] = "|cFFFFD100→ Turn in this quest|r"
            elseif questStatus == "complete" then
                headLines[#headLines + 1] = "|cFF888780✓ Already done|r"
            end
            -- "inprogress" shows objectives below, no extra line needed
        end

        -- Line 2: guide step prose
        headLines[#headLines + 1] = step.text or ""

        -- Live objectives (injected when quest is in log)
        local objLines = {}
        if step.questID and IsInLog(step.questID) then
            local objectives = C_QuestLog.GetQuestObjectives
                            and C_QuestLog.GetQuestObjectives(step.questID)
            if objectives and #objectives > 0 then
                for _, obj in ipairs(objectives) do
                    local color = obj.finished and "|cFF888780" or "|cFFFFFFFF"
                    objLines[#objLines + 1] = color .. "  - " .. (obj.text or "") .. "|r"
                end
            end
        end

        -- Stub coord hint
        local tailLines = {}
        local coord = step.coord
        if coord and coord.map == 0 and coord.x == 0 and coord.y == 0 then
            -- Check if the Arrow can resolve coordinates via its fallback chain
            local Arrow = TA:GetModule("Arrow")
            local resolved = false
            if Arrow and Arrow.GetEffectiveCoord then
                local rm, rx, ry = Arrow.GetEffectiveCoord(step)
                if rm and rm ~= 0 and (rx ~= 0 or ry ~= 0) then
                    resolved = true  -- Arrow found it, no need for a hint
                end
            end
            if not resolved then
                tailLines[#tailLines + 1] = "|cFF888780[Follow the arrow or check your map (M)]|r"
            end
        end

        local function Assemble(shownObjCount)
            local lines = {}
            for _, l in ipairs(headLines) do lines[#lines + 1] = l end
            for i = 1, shownObjCount do lines[#lines + 1] = objLines[i] end
            if shownObjCount < #objLines then
                lines[#lines + 1] = string.format(
                    "|cFF888780  ... +%d more objective(s) — see quest log|r",
                    #objLines - shownObjCount)
            end
            for _, l in ipairs(tailLines) do lines[#lines + 1] = l end
            return table.concat(lines, "\n")
        end

        local BOX_HEIGHT = 65
        local shown = #objLines
        win.stepTextF:SetText(Assemble(shown))
        while shown > 0 and win.stepTextF:GetStringHeight() > BOX_HEIGHT do
            shown = shown - 1
            win.stepTextF:SetText(Assemble(shown))
        end
        win.stepTextF:SetTextColor(0.92, 0.92, 0.88, 1)
    end

    -- Quest status line (base text; RenderStatusLine appends live distance/ETA)
    if step.questID then
        local st = QUEST_STATUS[self:GetQuestStatus(step.questID)] or ""
        self._statusBase = "|cFFAAAAAA#" .. step.questID .. "|r  " .. st
    elseif step._manualDone then
        self._statusBase = "|cFF1EFF00Marked as done|r"
    else
        self._statusBase = ""
    end
    self:RenderStatusLine()

    -- Next-step preview
    local nextStep = guide.steps[self.stepIdx + 1]
    if nextStep then
        local nextText = nextStep.text or ""
        if #nextText > 42 then nextText = nextText:sub(1, 39) .. "..." end
        win.nextStepF:SetText("|cFF8B7040Next:|r " .. nextText)
    else
        win.nextStepF:SetText(self.stepIdx >= total and "|cFF8B7040Final step|r" or "")
    end

    -- Contextual hint: explain WHY this step is currently selected
    local hint = self:GetStepContextHint(guide, self.stepIdx)
    if hint then
        win.tipF:SetText(hint)
    end

    -- Done button state
    local isLast = self.stepIdx >= total
    win.doneBtn._lbl:SetText(self:IsStepComplete(step) and "Done >" or "Mark Done >")
    if isLast then
        win.doneBtn:SetBackdropColor(0.10, 0.08, 0.01, 0.70)
        win.doneBtn._lbl:SetTextColor(0.45, 0.35, 0.10, 1)
    else
        win.doneBtn:SetBackdropColor(0.18, 0.13, 0.01, 0.90)
        win.doneBtn._lbl:SetTextColor(1.00, 0.82, 0.00, 1.00)
    end

    -- Refresh world map pins when step changes
    local MapPins = TA:GetModule("MapPins")
    if MapPins and MapPins.Refresh then MapPins:Refresh() end
end

-- ── RenderStatusLine ──────────────────────────────────────────────────────────
-- Rebuilds just the quest-status line (base text + live distance/ETA), so the
-- throttled ticker can refresh distance without re-running all of UpdateWindow.
function QT:RenderStatusLine()
    local win = self.window
    if not win then return end

    -- No active guide: UpdateWindow() already blanked these fields directly
    -- (its "No Active Guide" branch) — don't let a stale cached _statusBase/
    -- _badgeBase from a previously-selected guide bleed back in on the next tick.
    if not (self.guideID and TA.Guides and TA.Guides[self.guideID]) then
        win.questStatusF:SetText("")
        if win.stepBadgeF then win.stepBadgeF:SetText("") end
        return
    end

    local base = self._statusBase or ""
    local distStr = ""
    local hasLiveTarget = false

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local step  = guide and guide.steps[self.stepIdx]
    if step and step.coord and step.type ~= "text" then
        local Arrow = TA:GetModule("Arrow")
        if Arrow and Arrow.GetEffectiveCoord then
            local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
            local currentMap = C_Map.GetBestMapForUnit("player")
            if not (coordMap == 0 and cx == 0 and cy == 0)
               and currentMap and (coordMap == 0 or coordMap == currentMap) then
                local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
                if pos then
                    hasLiveTarget = true
                    local px, py = pos:GetXY()
                    local yards  = U.ComputeDistance(px, py, cx, cy)
                    local TM     = TA:GetModule("TravelModes")
                    local speed  = (TM and TM:GetSpeed()) or 7
                    distStr = "  |cFF888780" .. U.FormatDistance(yards)
                              .. "  " .. U.FormatETA(yards, speed) .. "|r"
                end
            end
        end
    end

    -- Arrow-status indicator: a soft-pulsing green dot next to the step
    -- badge when the HUD arrow has a real live target for this step, a
    -- static grey dot otherwise — ties the tracker and arrow together
    -- visually without needing a whole new UI element.
    if win.stepBadgeF then
        local dot
        if hasLiveTarget then
            local glow = 0.5 + 0.5 * math.sin(GetTime() * 4)   -- 0..1
            local g    = math.floor(140 + glow * 115)          -- brightness pulse, 140-255
            dot = string.format("|cFF1E%02X30●|r ", g)
        else
            dot = "|cFF555555●|r "
        end
        win.stepBadgeF:SetText(dot .. (self._badgeBase or ""))
    end

    win.questStatusF:SetText(base .. distStr)

    -- Travel suggestion: show when step is in a different zone
    local TR = TA:GetModule("TravelRouter")
    if TR and TR.GetSuggestionForCurrentStep and not hasLiveTarget then
        local suggestion = TR:GetSuggestionForCurrentStep()
        if suggestion then
            win.questStatusF:SetText(suggestion)
        end
    end

    -- ── Contextual tip rotation ──────────────────────────────────────────────
    -- Cycles through available module tips every 5 seconds, showing the most
    -- relevant contextual information without requiring user action.
    if win.tipF then
        local tips = {}

        -- XP ETA (highest priority when leveling)
        local XPMod = TA:GetModule("XPTracker")
        if XPMod and XPMod.GetETAString then
            local eta = XPMod:GetETAString()
            if eta and eta ~= "" then table.insert(tips, eta) end
        end

        -- Rest suggestion
        local RO = TA:GetModule("RestOptimizer")
        if RO and RO.GetSuggestion then
            local rest = RO:GetSuggestion()
            if rest then table.insert(tips, rest) end
        end

        -- Spec-adaptive dungeon tip
        local SA = TA:GetModule("SpecAdaptive")
        if SA and SA.GetDungeonSuggestion then
            local dung = SA:GetDungeonSuggestion()
            if dung then table.insert(tips, dung) end
        end

        -- Social awareness
        local Soc = TA:GetModule("SocialAwareness")
        if Soc and Soc.GetSuggestion then
            local social = Soc:GetSuggestion()
            if social then table.insert(tips, social) end
        end

        -- Profession tip
        local PQ = TA:GetModule("ProfQuesting")
        if PQ and PQ.GetGatheringTip then
            local prof = PQ:GetGatheringTip()
            if prof then table.insert(tips, prof) end
        end

        if #tips > 0 then
            -- Rotate every 5 seconds
            local idx = math.floor(GetTime() / 5) % #tips + 1
            win.tipF:SetText(tips[idx])
        else
            win.tipF:SetText("")
        end
    end
end

-- ── ToggleWindow ──────────────────────────────────────────────────────────────

function QT:ToggleWindow()
    -- Always toggle the floating tracker window. The side-drawer is a
    -- supplementary view inside the main ToonAge frame, not a replacement
    -- for the always-visible HUD tracker.
    if not self.window then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r Tracker window not initialised — check for errors at login.")
        return
    end
    if self.window:IsVisible() then
        self.window:Hide()
        if self.optionsFrame then self.optionsFrame:Hide() end
        if TA.charDB then TA.charDB.tracker.visible = false end
        self:UpdateBlizzardTrackerVisibility()
    else
        self.window:Show()
        self:UpdateWindow()
        if TA.charDB then TA.charDB.tracker.visible = true end
        self:UpdateBlizzardTrackerVisibility()
        if self.guideID and TA.Guides and TA.Guides[self.guideID] then
            local g = TA.Guides[self.guideID]
            TA:Raw(TA.LOG.INFO, string.format("|cFFFFD100[TA Tracker]|r '%s' — step %d/%d",
                g.title, self.stepIdx, #g.steps))
        end
    end
end

-- ── Drop Unrelated Quests ─────────────────────────────────────────────────────
-- Shows a popup listing all quests in the player's log that are NOT part of the
-- active guide. Player reviews the list and confirms before any quests are abandoned.

-- ── Smart Quest Log Analyzer ──────────────────────────────────────────────────
-- Categorizes ALL quests in the log by expansion/relevance and suggests safe drops.
-- Works even without an active guide selected.

function QT:AnalyzeQuestLog()
    local playerLevel = UnitLevel("player") or 1
    local results = {
        currentExpansion = {},  -- quests matching player's level bracket
        oldExpansion     = {},  -- quests from previous expansions (safe to drop)
        lowLevel         = {},  -- grey/trivial quests
        guideRelated     = {},  -- quests in the active guide
        unknown          = {},  -- can't classify
    }

    -- Build set of guide quest IDs
    local guideQuestIDs = {}
    if self.guideID and TA.Guides[self.guideID] then
        for _, step in ipairs(TA.Guides[self.guideID].steps or {}) do
            if step.questID then guideQuestIDs[step.questID] = true end
        end
    end

    -- Also check all midnight guides for quest IDs (protect current expansion quests)
    local midnightQuestIDs = {}
    for id, guide in pairs(TA.Guides or {}) do
        if guide.expansion == "midnight" or (guide.minLevel and guide.minLevel >= 80) then
            for _, step in ipairs(guide.steps or {}) do
                if step.questID then midnightQuestIDs[step.questID] = true end
            end
        end
    end

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local entry = {
                questID = info.questID,
                title   = info.title or ("Quest #" .. info.questID),
                level   = info.difficultyLevel or 0,
                isComplete = info.isComplete,
            }

            if guideQuestIDs[info.questID] then
                table.insert(results.guideRelated, entry)
            elseif midnightQuestIDs[info.questID] then
                table.insert(results.currentExpansion, entry)
            elseif entry.level > 0 and entry.level < (playerLevel - 15) then
                table.insert(results.lowLevel, entry)
            elseif entry.level > 0 and entry.level < (playerLevel - 5) then
                table.insert(results.oldExpansion, entry)
            else
                table.insert(results.currentExpansion, entry)
            end
        end
    end

    results.totalQuests = #results.currentExpansion + #results.oldExpansion
                        + #results.lowLevel + #results.guideRelated + #results.unknown
    results.safeToDropCount = #results.lowLevel + #results.oldExpansion

    return results
end

function QT:ShowQuestLogCleanup()
    local analysis = self:AnalyzeQuestLog()

    if analysis.safeToDropCount == 0 then
        self:ShowToast("No old quests found to clean up!")
        return
    end

    -- Build categorized list
    local lines = {}
    if #analysis.lowLevel > 0 then
        table.insert(lines, "\n|cFFFF4444Trivial / Grey Quests (safe to drop):|r")
        for i, q in ipairs(analysis.lowLevel) do
            if i <= 10 then
                table.insert(lines, "  • " .. q.title)
            end
        end
        if #analysis.lowLevel > 10 then
            table.insert(lines, "  ... +" .. (#analysis.lowLevel - 10) .. " more")
        end
    end

    if #analysis.oldExpansion > 0 then
        table.insert(lines, "\n|cFFFF9A1AOld Expansion Quests (likely safe):|r")
        for i, q in ipairs(analysis.oldExpansion) do
            if i <= 10 then
                table.insert(lines, "  • " .. q.title)
            end
        end
        if #analysis.oldExpansion > 10 then
            table.insert(lines, "  ... +" .. (#analysis.oldExpansion - 10) .. " more")
        end
    end

    local listText = table.concat(lines, "\n")

    -- Combine safe-to-drop quests
    local dropList = {}
    for _, q in ipairs(analysis.lowLevel) do table.insert(dropList, q) end
    for _, q in ipairs(analysis.oldExpansion) do table.insert(dropList, q) end

    StaticPopupDialogs["TOONAGE_QUEST_CLEANUP"] = {
        text = string.format(
            "|cFFFFD100ToonAge — Quest Log Cleanup|r\n\n"
         .. "Your log has |cFFFF9A1A%d quest(s)|r from old content\n"
         .. "that are blocking new quest pickups.\n"
         .. "%s\n\n"
         .. "|cFF888780Protected: %d quest(s) in your active guide\n"
         .. "and %d Midnight quest(s) are untouched.|r\n\n"
         .. "|cFFFF4444Drop %d old quest(s)?|r",
            analysis.safeToDropCount,
            listText,
            #analysis.guideRelated,
            #analysis.currentExpansion,
            analysis.safeToDropCount
        ),
        button1 = "Drop Old Quests",
        button2 = "Cancel",
        OnAccept = function()
            local dropped = 0
            for _, q in ipairs(dropList) do
                C_QuestLog.SetSelectedQuest(q.questID)
                C_QuestLog.SetAbandonQuest()
                C_QuestLog.AbandonQuest()
                dropped = dropped + 1
            end
            QT:ShowToast(dropped .. " old quests dropped — log cleared!")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("TOONAGE_QUEST_CLEANUP")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- QUEST LOG ADVISOR — For the Lorewalker who won't drop quests
-- ══════════════════════════════════════════════════════════════════════════════
-- Instead of suggesting abandonment, this mode analyzes the quest log and
-- tells the player which quests are CLOSEST to completion so they can finish
-- them naturally and free up slots for new content.

function QT:AnalyzeQuestProgress()
    local quests = {
        readyToTurnIn = {},   -- complete, just need to visit the NPC
        almostDone    = {},   -- 1 objective remaining
        inProgress    = {},   -- partially complete
        notStarted    = {},   -- accepted but 0 progress
    }

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local questID = info.questID
            local title   = info.title or ("Quest #" .. questID)

            -- Check if ready for turn-in
            local readyForTurnIn = false
            if C_QuestLog.ReadyForTurnIn then
                readyForTurnIn = C_QuestLog.ReadyForTurnIn(questID)
            elseif info.isComplete then
                readyForTurnIn = true
            end

            if readyForTurnIn then
                table.insert(quests.readyToTurnIn, { questID = questID, title = title })
            else
                -- Check objective progress
                local objectives = C_QuestLog.GetQuestObjectives(questID)
                if objectives and #objectives > 0 then
                    local totalObj  = #objectives
                    local doneObj   = 0
                    local totalProg = 0
                    local maxProg   = 0

                    for _, obj in ipairs(objectives) do
                        if obj.finished then
                            doneObj = doneObj + 1
                        end
                        if obj.numRequired and obj.numRequired > 0 then
                            totalProg = totalProg + (obj.numFulfilled or 0)
                            maxProg   = maxProg + obj.numRequired
                        else
                            maxProg   = maxProg + 1
                            totalProg = totalProg + (obj.finished and 1 or 0)
                        end
                    end

                    local pct = maxProg > 0 and math.floor((totalProg / maxProg) * 100) or 0
                    local entry = { questID = questID, title = title, pct = pct,
                                    doneObj = doneObj, totalObj = totalObj }

                    if doneObj >= totalObj - 1 and totalObj > 1 then
                        table.insert(quests.almostDone, entry)
                    elseif pct > 0 then
                        table.insert(quests.inProgress, entry)
                    else
                        table.insert(quests.notStarted, entry)
                    end
                else
                    -- No objectives data — treat as in-progress
                    table.insert(quests.inProgress, { questID = questID, title = title, pct = 0, doneObj = 0, totalObj = 0 })
                end
            end
        end
    end

    -- Sort in-progress by completion % (highest first = closest to done)
    table.sort(quests.inProgress, function(a, b) return a.pct > b.pct end)
    table.sort(quests.almostDone, function(a, b) return a.pct > b.pct end)

    return quests
end

--- Show the Quest Log Advisor — a completionist-friendly alternative to dropping quests.
--- Tells the player which quests to FINISH first to free up slots.
function QT:ShowQuestLogAdvisor()
    local progress = self:AnalyzeQuestProgress()
    local MAX_QUESTS = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 35

    -- Count total
    local total = #progress.readyToTurnIn + #progress.almostDone
                + #progress.inProgress + #progress.notStarted

    -- Build the advisor text for chat output (formatted nicely)
    local function PrintSection(header, color, items, showPct)
        if #items == 0 then return end
        TA:Raw(TA.LOG.OUTPUT, color .. "── " .. header .. " (" .. #items .. ") ──|r")
        for i, q in ipairs(items) do
            if i > 8 then
                TA:Raw(TA.LOG.OUTPUT, "  |cFF888780... +" .. (#items - 8) .. " more|r")
                break
            end
            local suffix = ""
            if showPct and q.pct then
                suffix = " |cFF888780(" .. q.pct .. "%)|r"
            end
            TA:Raw(TA.LOG.OUTPUT, "  " .. q.title .. suffix)
        end
    end

    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100═══ ToonAge Quest Log Advisor ═══|r")
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFF888780%d/%d quests in log|r", total, MAX_QUESTS))
    TA:Raw(TA.LOG.OUTPUT, "")

    if #progress.readyToTurnIn > 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A★ TURN THESE IN NOW — they're already done!|r")
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A  Each one you turn in frees a quest slot.|r")
        PrintSection("Ready to Turn In", "|cFF4AFF7A", progress.readyToTurnIn, false)
        TA:Raw(TA.LOG.OUTPUT, "")
    end

    if #progress.almostDone > 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100★ ALMOST DONE — just one objective left:|r")
        PrintSection("Almost Done", "|cFFFFD100", progress.almostDone, true)
        TA:Raw(TA.LOG.OUTPUT, "")
    end

    if #progress.inProgress > 0 then
        PrintSection("In Progress (sorted by completion)", "|cFF888780", progress.inProgress, true)
        TA:Raw(TA.LOG.OUTPUT, "")
    end

    if #progress.notStarted > 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF9A1A★ NOT STARTED — you could turn these in later.\n  Consider finishing nearby ones or saving for a future session.|r")
        PrintSection("Not Started", "|cFFFF9A1A", progress.notStarted, false)
        TA:Raw(TA.LOG.OUTPUT, "")
    end

    -- Smart suggestion
    local freeableNow = #progress.readyToTurnIn
    local freeableSoon = #progress.almostDone
    if freeableNow > 0 then
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFF4AFF7A→ You can free %d slot(s) immediately by turning in completed quests.|r", freeableNow))
    elseif freeableSoon > 0 then
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100→ Finish %d almost-done quest(s) to free up slots without dropping anything.|r", freeableSoon))
    else
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF9A1A→ No quests are close to completion. Consider finishing the highest-% ones first,|r")
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF9A1A  or use 'Clean Up Quest Log' to safely remove trivial/grey quests.|r")
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100═══════════════════════════════════|r")
end

function QT:GetUnrelatedQuests()
    local unrelated = {}
    local guideQuestIDs = {}

    -- Build set of quest IDs in the active guide
    if self.guideID and TA.Guides[self.guideID] then
        local guide = TA.Guides[self.guideID]
        for _, step in ipairs(guide.steps or {}) do
            if step.questID then
                guideQuestIDs[step.questID] = true
            end
        end
    end

    -- Scan quest log for quests NOT in the guide
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            if not guideQuestIDs[info.questID] then
                table.insert(unrelated, {
                    questID = info.questID,
                    title   = info.title or ("Quest #" .. info.questID),
                    level   = info.difficultyLevel or 0,
                })
            end
        end
    end

    return unrelated
end

function QT:ShowDropUnrelatedPopup()
    local unrelated = self:GetUnrelatedQuests()

    if #unrelated == 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A[ToonAge]|r All quests in your log are part of the active guide. Nothing to drop.")
        return
    end

    if not self.guideID then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r No active guide selected. Select a guide first via /ta browser.")
        return
    end

    -- Build the confirmation popup
    local questList = ""
    for i, q in ipairs(unrelated) do
        questList = questList .. "\n  • " .. q.title .. " (ID: " .. q.questID .. ")"
        if i >= 15 then
            questList = questList .. "\n  ... and " .. (#unrelated - 15) .. " more"
            break
        end
    end

    StaticPopupDialogs["TOONAGE_DROP_UNRELATED"] = {
        text = string.format(
            "|cFFFFD100ToonAge|r\n\nDrop |cFFFF9A1A%d quest(s)|r not in your active guide?\n%s\n\n|cFFFF4444This cannot be undone!|r",
            #unrelated, questList
        ),
        button1 = "Drop All Listed",
        button2 = "Cancel",
        OnAccept = function()
            local dropped = 0
            for _, q in ipairs(unrelated) do
                C_QuestLog.SetSelectedQuest(q.questID)
                C_QuestLog.SetAbandonQuest()
                C_QuestLog.AbandonQuest()
                dropped = dropped + 1
            end
            TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[ToonAge]|r Dropped %d unrelated quest(s).", dropped))
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("TOONAGE_DROP_UNRELATED")
end

-- ── Tab Render (for main panel "Guide" tab) ───────────────────────────────────
-- 3-Panel Guide Architecture:
--   Panel 1 (sidebar) = Expansion filter list with Chromie Time suggestion
--   Panel 2 (content) = Zone guides for selected expansion + retrospective
--   Panel 3 (drawer)  = Active tracker or zone summary via TA.Modern:RebuildDrawerChild()

-- Frame recycler for the middle panel (prevents ghost elements on re-render)
QT.middlePanelFrames = {}
QT._contentFrame = nil  -- reference to the content scroll child for isolated re-renders

-- Expansion data for the sidebar filter
QT._expansions = {
    { key = "midnight",   label = "Midnight",         maxLevel = 90 },
    { key = "warwithin",  label = "The War Within",   maxLevel = 80 },
    { key = "df",         label = "Dragonflight",     maxLevel = 70 },
    { key = "sl",         label = "Shadowlands",      maxLevel = 60 },
    { key = "bfa",        label = "Battle for Azeroth", maxLevel = 50 },
    { key = "legion",     label = "Legion",           maxLevel = 50 },
    { key = "wod",        label = "Warlords of Draenor", maxLevel = 50 },
    { key = "mop",        label = "Mists of Pandaria", maxLevel = 50 },
    { key = "cata",       label = "Cataclysm",        maxLevel = 50 },
    { key = "wotlk",      label = "Wrath of the Lich King", maxLevel = 50 },
    { key = "tbc",        label = "The Burning Crusade", maxLevel = 50 },
    { key = "classic",    label = "Classic",           maxLevel = 50 },
    { key = "starter",    label = "Starter Zones",    maxLevel = 20 },
}

QT._selectedExpansion = nil  -- nil = auto-detect on first render

--- Determine the best expansion filter based on active guide, player level, or zone.
function QT:DetectBestExpansion()
    -- Priority 1: If a guide is active, use its expansion
    if self.guideID and TA.Guides and TA.Guides[self.guideID] then
        local guide = TA.Guides[self.guideID]
        if guide.expansion then return guide.expansion end
        -- Infer from level range
        local lvl = guide.minLevel or 1
        if lvl >= 80 then return "midnight" end
        if lvl >= 70 then return "warwithin" end
        if lvl >= 60 then return "df" end
        if lvl >= 50 then return "sl" end
        if lvl <= 20 then return "starter" end
    end

    -- Priority 2: Based on player level
    local playerLevel = UnitLevel("player") or 1
    if playerLevel >= 80 then return "midnight" end
    if playerLevel >= 70 then return "warwithin" end
    if playerLevel >= 60 then return "df" end
    if playerLevel >= 50 then return "sl" end
    if playerLevel >= 45 then return "bfa" end
    if playerLevel >= 10 then
        -- Check Chromie Time
        if C_ChromieTime and C_ChromieTime.GetChromieTimeExpansionOption then
            local ok, result = pcall(C_ChromieTime.GetChromieTimeExpansionOption)
            if ok and result then return result end
        end
        return "bfa"  -- default timewalking expansion
    end
    return "starter"
end

function QT:Render(content, sidebar)
    local padL = 14
    local y = -10
    local w = content:GetWidth() - 28

    -- Auto-detect expansion filter if not manually selected yet
    if not self._selectedExpansion then
        self._selectedExpansion = self:DetectBestExpansion()
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- PANEL 1: LEFT SIDEBAR — Expansion Filter
    -- ══════════════════════════════════════════════════════════════════════════
    local sideY = -8
    local sideW = sidebar:GetWidth() - 12

    local sideTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sideTitle:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    sideTitle:SetText("EXPANSIONS")
    sideTitle:SetTextColor(0.55, 0.40, 0.08, 1)
    sideTitle:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, sideY)
    sideY = sideY - 16

    -- Detect Chromie Time for suggested badge
    local chromieExpansion = nil
    if C_ChromieTime and C_ChromieTime.GetChromieTimeExpansionOption then
        local ok, result = pcall(C_ChromieTime.GetChromieTimeExpansionOption)
        if ok and result then chromieExpansion = result end
    end

    -- Store sidebar buttons for highlight updates without full re-render
    local sideButtons = {}

    for _, expDef in ipairs(self._expansions) do
        local isSelected = (self._selectedExpansion == expDef.key)
        local isSuggested = (chromieExpansion and expDef.key == chromieExpansion)

        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetHeight(22)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, sideY)
        btn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -4, sideY)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, isSelected and "OUTLINE" or "")
        local text = expDef.label
        if isSuggested then
            text = text .. " |cFF66BBFF(Suggested)|r"
        elseif expDef.key == self:DetectBestExpansion() then
            text = text .. " |cFF4AE0FF★|r"
        end
        lbl:SetText(text)
        lbl:SetPoint("LEFT", btn, "LEFT", 6, 0)
        lbl:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)

        btn._expKey = expDef.key
        btn._lbl = lbl
        table.insert(sideButtons, btn)

        -- Apply initial visual state
        if isSelected then
            btn:SetBackdropColor(0.12, 0.10, 0.04, 1)
            btn:SetBackdropBorderColor(0.40, 0.75, 1.00, 0.80)
            lbl:SetTextColor(0.92, 0.90, 0.87, 1)
        else
            btn:SetBackdropColor(0.04, 0.04, 0.04, 0.80)
            btn:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.30)
            lbl:SetTextColor(0.65, 0.60, 0.50, 1)
        end

        local expKey = expDef.key
        btn:SetScript("OnClick", function()
            self._selectedExpansion = expKey

            -- Update ALL sidebar button visuals immediately (no re-render needed)
            for _, sb in ipairs(sideButtons) do
                local sel = (sb._expKey == expKey)
                if sel then
                    sb:SetBackdropColor(0.12, 0.10, 0.04, 1)
                    sb:SetBackdropBorderColor(0.40, 0.75, 1.00, 0.80)
                    sb._lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
                    sb._lbl:SetTextColor(0.92, 0.90, 0.87, 1)
                else
                    sb:SetBackdropColor(0.04, 0.04, 0.04, 0.80)
                    sb:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.30)
                    sb._lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
                    sb._lbl:SetTextColor(0.65, 0.60, 0.50, 1)
                end
            end

            -- Re-render ONLY the middle panel (aggressive wipe built in)
            if self._contentFrame then
                self:RenderMiddlePanel(self._contentFrame)
            end
        end)
        btn:SetScript("OnEnter", function(f)
            if f._expKey ~= self._selectedExpansion then
                f:SetBackdropColor(0.10, 0.08, 0.04, 1)
            end
        end)
        btn:SetScript("OnLeave", function(f)
            if f._expKey ~= self._selectedExpansion then
                f:SetBackdropColor(0.04, 0.04, 0.04, 0.80)
            end
        end)

        sideY = sideY - 24
    end

    sidebar:SetHeight(math.abs(sideY) + 10)

    -- Store content frame reference for isolated re-renders from sidebar clicks
    self._contentFrame = content

    -- ══════════════════════════════════════════════════════════════════════════
    -- PANEL 2: MIDDLE CONTENT (delegated to isolated function with wipe loop)
    -- ══════════════════════════════════════════════════════════════════════════
    self:RenderMiddlePanel(content)

    -- ══════════════════════════════════════════════════════════════════════════
    -- PANEL 3: RIGHT DRAWER — Active Tracker or Quest Log Follow
    -- ══════════════════════════════════════════════════════════════════════════
    if TA.Modern and TA.Modern.RebuildDrawerChild and TA.db and TA.db.useUnifiedUI then
        -- UpdateDrawer handles both states: active guide OR Quest Log Follow mode
        self:UpdateDrawer()
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- RenderMiddlePanel: Isolated middle content renderer with frame wipe loop.
-- Called on expansion click WITHOUT rebuilding the sidebar.
-- ══════════════════════════════════════════════════════════════════════════════

--- Classify a guide into an expansion key based on its metadata.
--- @param guide table
--- @return string expansionKey
function QT:ClassifyGuideExpansion(guide)
    -- Explicit expansion field (best)
    if guide.expansion then return guide.expansion end

    -- Heuristic by level range
    local minLvl = guide.minLevel or 1
    local maxLvl = guide.maxLevel or 99

    if minLvl >= 80 then return "midnight" end
    if minLvl >= 70 then return "warwithin" end
    if minLvl >= 60 and maxLvl <= 70 then return "df" end
    if minLvl >= 50 and maxLvl <= 60 then return "sl" end
    if minLvl >= 45 and maxLvl <= 50 then return "bfa" end
    if maxLvl <= 20 then return "starter" end

    -- Heuristic by guide ID prefix
    local id = guide.id or ""
    if id:match("^midnight") or id:match("^eversong") or id:match("^silvermoon") or id:match("^naigtal") then
        return "midnight"
    end
    if id:match("^hallowfall") or id:match("^dorn") or id:match("^azj") or id:match("^ringing") then
        return "warwithin"
    end
    if id:match("^exile") then return "starter" end

    -- Default: bucket into the expansion matching the midpoint level
    local mid = (minLvl + maxLvl) / 2
    if mid >= 80 then return "midnight" end
    if mid >= 70 then return "warwithin" end
    if mid >= 60 then return "df" end
    if mid >= 50 then return "sl" end
    if mid >= 40 then return "bfa" end
    return "starter"
end

function QT:RenderMiddlePanel(content)
    if not content then return end

    -- Prevent re-entrant renders (e.g. from events firing during render)
    if self._renderingMiddle then return end
    self._renderingMiddle = true

    -- ══════════════════════════════════════════════════════════════════════════
    -- AGGRESSIVE CANVAS WIPE — nothing survives from previous render
    -- ══════════════════════════════════════════════════════════════════════════

    -- Step 1: Hide all tracked frames from previous render
    for _, f in ipairs(self.middlePanelFrames) do
        if f and f.Hide then f:Hide() end
        if f and f.SetParent then f:SetParent(nil) end
    end
    wipe(self.middlePanelFrames)

    -- Step 2: Destroy all FontStrings and Textures on the content frame
    for _, region in ipairs({ content:GetRegions() }) do
        region:Hide()
        if region.SetText then region:SetText("") end
        if region.SetTexture then region:SetTexture(nil) end
    end

    -- Step 3: Destroy all child frames (buttons, cards, etc.)
    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Step 4: Reset scroll position if parent is a scroll frame
    local parent = content:GetParent()
    if parent and parent.SetVerticalScroll then
        parent:SetVerticalScroll(0)
    end

    local padL = 14
    local y = -10
    local w = content:GetWidth() - 28
    local selectedExp = self._selectedExpansion or "midnight"

    -- Helper: track created elements
    local function Track(f) table.insert(self.middlePanelFrames, f); return f end

    -- ── Gather guides for the selected expansion ─────────────────────────────
    local zoneGuides = {}
    for id, guide in pairs(TA.Guides or {}) do
        local guideExp = self:ClassifyGuideExpansion(guide)
        if guideExp == selectedExp then
            local total, completed = 0, 0
            for _, step in ipairs(guide.steps) do
                if step.questID then
                    total = total + 1
                    if C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
                        completed = completed + 1
                    end
                end
            end
            local pct = total > 0 and math.floor((completed / total) * 100) or 0
            table.insert(zoneGuides, {
                id = id, title = guide.title or id,
                minLevel = guide.minLevel or 1, maxLevel = guide.maxLevel or 99,
                total = total, completed = completed, pct = pct,
            })
        end
    end
    table.sort(zoneGuides, function(a, b) return a.minLevel < b.minLevel end)

    -- ── Header ───────────────────────────────────────────────────────────────
    local expLabel = selectedExp
    for _, def in ipairs(self._expansions) do
        if def.key == selectedExp then expLabel = def.label; break end
    end

    -- Check if this is the recommended expansion for the player's level
    local recommended = (self:DetectBestExpansion() == selectedExp)

    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    if recommended then
        hdr:SetText(expLabel .. " Guides  |cFF4AE0FF(Recommended)|r")
    else
        hdr:SetText(expLabel .. " Guides")
    end
    hdr:SetTextColor(0.92, 0.90, 0.87, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 22

    -- ── Empty state ──────────────────────────────────────────────────────────
    if #zoneGuides == 0 then
        local noData = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        noData:SetFont(STANDARD_TEXT_FONT, 11, "")
        noData:SetText("No guides available for " .. expLabel .. " yet.\nGuides are added in Data/Guides/.")
        noData:SetTextColor(0.55, 0.50, 0.40, 1)
        noData:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        noData:SetWidth(w)
        noData:SetWordWrap(true)
        content:SetHeight(100)
        self._renderingMiddle = false
        return
    end

    -- ── Zone cards ───────────────────────────────────────────────────────────
    for _, zg in ipairs(zoneGuides) do
        local card = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
        card:SetHeight(58)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL - 4, y)
        card:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL + 4, y)
        card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        card:SetBackdropColor(0.06, 0.06, 0.08, 0.90)
        card:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.50)

        -- Level range (anchored first)
        local lvlF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lvlF:SetFont(STANDARD_TEXT_FONT, 9, "")
        lvlF:SetText(string.format("Lv %d-%d", zg.minLevel, zg.maxLevel))
        lvlF:SetTextColor(0.55, 0.52, 0.45, 1)
        lvlF:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)

        -- Title (constrained)
        local titleF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        titleF:SetText(zg.title)
        titleF:SetTextColor(0.92, 0.90, 0.87, 1)
        titleF:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
        titleF:SetPoint("RIGHT", lvlF, "LEFT", -8, 0)
        titleF:SetJustifyH("LEFT")
        titleF:SetWordWrap(false)

        -- Progress bar bg
        local barBg = card:CreateTexture(nil, "ARTWORK")
        barBg:SetHeight(4)
        barBg:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -26)
        barBg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -26)
        barBg:SetColorTexture(0.15, 0.15, 0.18, 1)

        -- Progress bar fill
        local barFill = card:CreateTexture(nil, "OVERLAY")
        barFill:SetHeight(4)
        barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
        local fillPx = math.max(2, math.floor((w - 4) * zg.pct / 100))
        barFill:SetWidth(fillPx)
        if zg.pct >= 100 then
            barFill:SetColorTexture(0.29, 1.00, 0.48, 0.9)
        elseif zg.pct >= 50 then
            barFill:SetColorTexture(0.40, 0.75, 1.00, 0.8)
        else
            barFill:SetColorTexture(1.00, 0.82, 0.00, 0.7)
        end

        -- Completion text
        local pctF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctF:SetFont(STANDARD_TEXT_FONT, 9, "")
        if zg.total == 0 then
            pctF:SetText("|cFF1EBCFFQuest Log Follow|r")
            pctF:SetTextColor(0.40, 0.75, 1.00, 1)
        else
            pctF:SetText(string.format("%d%% (%d/%d)", zg.pct, zg.completed, zg.total))
            pctF:SetTextColor(0.62, 0.59, 0.55, 1)
        end
        pctF:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 6)

        -- Follow button
        local isActive = (self.guideID == zg.id)
        local fBg = isActive and {0.08, 0.15, 0.08} or {0.08, 0.06, 0.02}
        local fBd = isActive and {0.29, 1.00, 0.48} or {0.40, 0.75, 1.00}

        local followBtn = Track(CreateFrame("Button", nil, card, "BackdropTemplate"))
        followBtn:SetSize(60, 18)
        followBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 6)
        followBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        followBtn:SetBackdropColor(fBg[1], fBg[2], fBg[3], 1)
        followBtn:SetBackdropBorderColor(fBd[1], fBd[2], fBd[3], 0.7)

        local followLbl = followBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        followLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        followLbl:SetText(isActive and "Active" or "Follow")
        followLbl:SetTextColor(fBd[1], fBd[2], fBd[3], 1)
        followLbl:SetAllPoints(followBtn)
        followLbl:SetJustifyH("CENTER")

        local guideID = zg.id
        followBtn:SetScript("OnClick", function()
            self:SetGuide(guideID)
            self:ShowToast("Following: " .. zg.title)
            self:RenderMiddlePanel(content)
        end)
        followBtn:SetScript("OnEnter", function(f) f:SetBackdropColor(fBg[1]+0.06, fBg[2]+0.06, fBg[3]+0.03, 1) end)
        followBtn:SetScript("OnLeave", function(f) f:SetBackdropColor(fBg[1], fBg[2], fBg[3], 1) end)

        -- View Missed button
        if zg.pct < 100 and zg.pct > 0 then
            local mBtn = Track(CreateFrame("Button", nil, card, "BackdropTemplate"))
            mBtn:SetSize(72, 18)
            mBtn:SetPoint("RIGHT", followBtn, "LEFT", -4, 0)
            mBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            mBtn:SetBackdropColor(0.08, 0.04, 0.02, 1)
            mBtn:SetBackdropBorderColor(1.00, 0.55, 0.20, 0.5)

            local mLbl = mBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            mLbl:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
            mLbl:SetText("View Missed")
            mLbl:SetTextColor(1.00, 0.65, 0.20, 1)
            mLbl:SetAllPoints(mBtn)
            mLbl:SetJustifyH("CENTER")

            local mGuideID = zg.id
            mBtn:SetScript("OnClick", function()
                self._showMissedForGuide = mGuideID
                self:RenderMiddlePanel(content)
            end)
            mBtn:SetScript("OnEnter", function(f) f:SetBackdropColor(0.12, 0.07, 0.03, 1) end)
            mBtn:SetScript("OnLeave", function(f) f:SetBackdropColor(0.08, 0.04, 0.02, 1) end)
        end

        y = y - 62
    end

    -- ── Retrospective detail view ────────────────────────────────────────────
    if self._showMissedForGuide then
        local Retro = TA:GetModule("Retrospective")
        if Retro and Retro.AnalyzeGuide then
            local analysis = Retro:AnalyzeGuide(self._showMissedForGuide)
            if analysis and #analysis.skipped > 0 then
                y = y - 10
                local missHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                missHdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
                missHdr:SetText("Missed in: " .. (analysis.title or ""))
                missHdr:SetTextColor(1.00, 0.65, 0.20, 1)
                missHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                y = y - 16

                local closeBtn = Track(CreateFrame("Button", nil, content))
                closeBtn:SetSize(50, 14)
                closeBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y + 14)
                local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                closeLbl:SetFont(STANDARD_TEXT_FONT, 9, "")
                closeLbl:SetText("|cFF888780[Close]|r")
                closeLbl:SetAllPoints(closeBtn)
                closeLbl:SetJustifyH("RIGHT")
                closeBtn:SetScript("OnClick", function()
                    self._showMissedForGuide = nil
                    self:RenderMiddlePanel(content)
                end)

                for i, step in ipairs(analysis.skipped) do
                    if i > 20 then
                        local moreF = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                        moreF:SetFont(STANDARD_TEXT_FONT, 9, "")
                        moreF:SetText(string.format("|cFF888780... and %d more|r", #analysis.skipped - 20))
                        moreF:SetPoint("TOPLEFT", content, "TOPLEFT", padL + 8, y)
                        y = y - 14
                        break
                    end
                    local questName = step.text or ""
                    if step.questID then
                        local title = C_QuestLog.GetTitleForQuestID(step.questID)
                        if title and title ~= "" then questName = title end
                    end
                    local qRow = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
                    qRow:SetFont(STANDARD_TEXT_FONT, 10, "")
                    qRow:SetText("  \226\151\139 " .. questName)
                    qRow:SetTextColor(0.75, 0.70, 0.60, 1)
                    qRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL + 4, y)
                    qRow:SetWidth(w - 8)
                    qRow:SetJustifyH("LEFT")
                    y = y - 15
                end
            end
        end
    end

    content:SetHeight(math.abs(y) + 20)
    self._renderingMiddle = false
end

-- ── Toast Notification System ─────────────────────────────────────────────────
-- A subtle, non-intrusive notification that appears briefly when guide state
-- changes. Replaces chat spam with a visual indicator on the tracker.

function QT:ShowToast(message, duration)
    duration = duration or 2.5
    local win = self.window
    if not win then return end

    -- Create toast frame on first use
    if not win._toast then
        local toast = CreateFrame("Frame", nil, win, "BackdropTemplate")
        toast:SetSize(win:GetWidth() - 16, 24)
        toast:SetPoint("TOP", win, "BOTTOM", 0, -4)
        toast:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        toast:SetBackdropColor(0.04, 0.08, 0.04, 0.95)
        toast:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.70)
        toast:SetFrameStrata("HIGH")

        local text = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        text:SetAllPoints(toast)
        text:SetJustifyH("CENTER")
        text:SetTextColor(0.29, 1.00, 0.48, 1)
        toast._text = text

        toast:Hide()
        win._toast = toast
    end

    local toast = win._toast
    toast._text:SetText(message)
    toast:SetAlpha(1)
    toast:Show()

    -- Cancel any existing fade timer
    if toast._fadeTimer then toast._fadeTimer:Cancel(); toast._fadeTimer = nil end

    -- Fade out after duration
    toast._fadeTimer = C_Timer.NewTimer(duration, function()
        toast._fadeTimer = nil
        UIFrameFadeOut(toast, 0.5, 1, 0)
        C_Timer.After(0.5, function() toast:Hide() end)
    end)
end

-- ── Contextual Step Hint ──────────────────────────────────────────────────────
-- Generates a short "why this step" explanation for the tracker display.
-- Called by UpdateWindow to show below the step text.

function QT:GetStepContextHint(guide, stepIdx)
    if not guide or not guide.steps then return nil end
    local step = guide.steps[stepIdx]
    if not step then return nil end

    -- Spatial routing: if we re-ordered to nearest objective
    if self._spatialRouted then
        return "|cFF1EBCFF\226\134\146 Closest objective|r"
    end

    -- Chain prerequisite
    if step.pre then
        return "|cFF888780\226\134\146 Chain prerequisite met|r"
    end

    -- Accept step for a quest not yet in log
    if (step.type == "accept" or step.type == "pickup") and step.questID then
        if not C_QuestLog.GetLogIndexForQuestID(step.questID) then
            return "|cFF4AFF7A\226\134\146 Pick up this quest|r"
        end
    end

    -- Turn-in step
    if step.type == "turnin" and step.questID then
        if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(step.questID) then
            return "|cFFFFD100\226\134\146 Ready to turn in|r"
        end
    end

    -- In-progress quest with objectives
    if step.questID and C_QuestLog.GetLogIndexForQuestID(step.questID) then
        local objectives = C_QuestLog.GetQuestObjectives(step.questID)
        if objectives then
            local done, total = 0, #objectives
            for _, obj in ipairs(objectives) do
                if obj.finished then done = done + 1 end
            end
            if total > 0 and done < total then
                return string.format("|cFF888780\226\134\146 %d/%d objectives done|r", done, total)
            end
        end
    end

    return nil
end

-- ── Right-Click Tracker Menu ──────────────────────────────────────────────────
-- The player right-clicks the tracker window to access everything ToonAge offers
-- without ever typing a slash command. This IS the UI.

function QT:ShowTrackerMenu(anchor)
    -- Use the modern Menu API if available (11.0+), otherwise create a simple frame menu
    if Menu and Menu.CreateContextMenu then
        self:ShowTrackerMenuModern(anchor)
    else
        self:ShowTrackerMenuLegacy(anchor)
    end
end

function QT:ShowTrackerMenuModern(anchor)
    MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
        rootDescription:SetTag("TOONAGE_TRACKER_MENU")

        -- ── Open ToonAge Panel ────────────────────────────────────────
        rootDescription:CreateButton("Open ToonAge Panel", function()
            TA:ToggleUI()
        end)

        -- ── Guide Section ─────────────────────────────────────────────
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("Guide")

        rootDescription:CreateButton("Browse All Guides", function()
            if TA.UI then
                if not TA.UI:IsVisible() then TA.UI:Show() end
                TA.UI:SetTab("guide")
            end
        end)

        rootDescription:CreateButton("Re-Sync Position", function()
            self:FastForward(false)
        end)

        rootDescription:CreateButton("Auto-Select Best Guide", function()
            self:AutoSelectGuide()
            if self.guideID then
                self:ShowToast("Following: " .. (TA.Guides[self.guideID].title or self.guideID))
            end
            self:UpdateWindow()
        end)

        rootDescription:CreateButton("Clean Up Quest Log", function()
            self:ShowQuestLogCleanup()
        end)

        rootDescription:CreateButton("Quest Log Advisor (Don't Drop)", function()
            self:ShowQuestLogAdvisor()
        end)

        -- ── What Did I Miss? ──────────────────────────────────────────
        local Retro = TA:GetModule("Retrospective")
        if Retro then
            rootDescription:CreateButton("What Did I Miss?", function()
                if TA.UI then
                    if not TA.UI:IsVisible() then TA.UI:Show() end
                    TA.UI:SetTab("guide")
                end
            end)
        end

        -- ── Navigation ────────────────────────────────────────────────
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("Navigation")

        local Arrow = TA:GetModule("Arrow")
        if Arrow then
            local arrowOn = Arrow.frame and Arrow.frame:IsVisible()
            rootDescription:CreateButton(arrowOn and "Hide Arrow" or "Show Arrow", function()
                Arrow:Toggle()
            end)
        end

        local NavHud = TA:GetModule("NavHud")
        if NavHud then
            local hudOn = NavHud.frame and NavHud.frame:IsShown()
            rootDescription:CreateButton(hudOn and "Hide NavHud" or "Show NavHud", function()
                NavHud:Toggle()
            end)
        end

        local CR = TA:GetModule("CoordResolver")
        if CR then
            rootDescription:CreateButton("Show Coordinates", function()
                CR.SlashCommands.coord(CR)
            end)
        end

        -- ── Automation ────────────────────────────────────────────────
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("Automation")

        local autoQuest = TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest
        rootDescription:CreateCheckbox(
            "Auto-Accept/Turn-In Quests",
            function() return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest end,
            function()
                TA.charDB.tracker.autoQuest = not TA.charDB.tracker.autoQuest
            end
        )

        local autoEquip = TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoEquip
        rootDescription:CreateCheckbox(
            "Auto-Equip Upgrades",
            function() return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoEquip end,
            function()
                TA.charDB.tracker.autoEquip = not TA.charDB.tracker.autoEquip
            end
        )

        -- ── View ──────────────────────────────────────────────────────
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("View")

        rootDescription:CreateButton("Toggle Settings", function()
            if self.optionsFrame:IsShown() then
                self.optionsFrame:Hide()
            else
                self.optionsFrame:Show()
            end
        end)

        rootDescription:CreateButton("Hide Tracker", function()
            self:ToggleWindow()
        end)
    end)
end

--- Fallback for pre-11.0 builds without MenuUtil.CreateContextMenu
function QT:ShowTrackerMenuLegacy(anchor)
    -- Create a simple dropdown-style frame menu
    if not self._legacyMenu then
        local menu = CreateFrame("Frame", "TATrackerContextMenu", UIParent, "BackdropTemplate")
        menu:SetSize(200, 280)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetClampedToScreen(true)

        if TA.Modern and TA.Modern.ApplyGlassBackdrop then
            TA.Modern:ApplyGlassBackdrop(menu)
        else
            menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            menu:SetBackdropColor(0.05, 0.04, 0.02, 0.97)
            menu:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.85)
        end

        menu:EnableMouse(true)
        menu:Hide()

        -- Close when clicking elsewhere
        menu:SetScript("OnShow", function()
            C_Timer.After(0.1, function()
                menu._closeListener = menu._closeListener or CreateFrame("Button", nil, UIParent)
                local cl = menu._closeListener
                cl:SetAllPoints(UIParent)
                cl:SetFrameStrata("TOOLTIP")
                cl:SetFrameLevel(menu:GetFrameLevel() - 1)
                cl:EnableMouse(true)
                cl:SetScript("OnClick", function()
                    menu:Hide()
                    cl:Hide()
                end)
                cl:Show()
            end)
        end)
        menu:SetScript("OnHide", function()
            if menu._closeListener then menu._closeListener:Hide() end
        end)

        self._legacyMenu = menu
    end

    local menu = self._legacyMenu

    -- Clear old buttons
    if menu._buttons then
        for _, btn in ipairs(menu._buttons) do btn:Hide() end
    end
    menu._buttons = {}

    local y = -8
    local function AddButton(text, onClick)
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(184, 20)
        btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, y)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
        lbl:SetText(text)
        lbl:SetTextColor(0.88, 0.83, 0.65, 1)
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("LEFT")

        btn:SetScript("OnClick", function()
            menu:Hide()
            onClick()
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 0.95, 0.75, 1) end)
        btn:SetScript("OnLeave", function() lbl:SetTextColor(0.88, 0.83, 0.65, 1) end)

        y = y - 22
        table.insert(menu._buttons, btn)
    end

    AddButton("|cFF4AE0FFOpen ToonAge Panel|r", function() TA:ToggleUI() end)
    AddButton("Browse All Guides", function()
        if TA.UI then
            if not TA.UI:IsVisible() then TA.UI:Show() end
            TA.UI:SetTab("guide")
        end
    end)
    AddButton("Re-Sync Position", function() self:FastForward(false) end)
    AddButton("Auto-Select Best Guide", function()
        self:AutoSelectGuide()
        if self.guideID then
            self:ShowToast("Following: " .. (TA.Guides[self.guideID].title or self.guideID))
        end
        self:UpdateWindow()
    end)
    AddButton("Clean Up Quest Log", function()
        self:ShowQuestLogCleanup()
    end)
    AddButton("Quest Log Advisor (Don't Drop)", function()
        self:ShowQuestLogAdvisor()
    end)
    AddButton("What Did I Miss?", function()
        if TA.UI then
            if not TA.UI:IsVisible() then TA.UI:Show() end
            TA.UI:SetTab("guide")
        end
    end)
    AddButton("─────────────────────", function() end)
    AddButton((TA:GetModule("Arrow") and TA:GetModule("Arrow").frame and TA:GetModule("Arrow").frame:IsVisible())
        and "Hide Arrow" or "Show Arrow", function()
        local Arrow = TA:GetModule("Arrow")
        if Arrow then Arrow:Toggle() end
    end)
    AddButton((TA:GetModule("NavHud") and TA:GetModule("NavHud").frame and TA:GetModule("NavHud").frame:IsShown())
        and "Hide NavHud" or "Show NavHud", function()
        local NavHud = TA:GetModule("NavHud")
        if NavHud then NavHud:Toggle() end
    end)
    AddButton("Show Coordinates", function()
        local CR = TA:GetModule("CoordResolver")
        if CR and CR.SlashCommands and CR.SlashCommands.coord then
            CR.SlashCommands.coord(CR)
        end
    end)
    AddButton("─────────────────────", function() end)
    AddButton("Toggle Settings", function()
        if self.optionsFrame:IsShown() then self.optionsFrame:Hide()
        else self.optionsFrame:Show() end
    end)
    AddButton("Hide Tracker", function() self:ToggleWindow() end)

    -- Size to content
    menu:SetHeight(math.abs(y) + 12)

    -- Position near the anchor
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 0)
    menu:Show()
end

QT.SlashCommands = {
    tracker = function(self) self:ToggleWindow() end,

    drop = function(self) self:ShowDropUnrelatedPopup() end,

    autoselect = function(self)
        self:AutoSelectGuide()
        self:UpdateWindow()
        if self.guideID and TA.Guides and TA.Guides[self.guideID] then
            local g = TA.Guides[self.guideID]
            TA:Raw(TA.LOG.INFO, string.format("|cFFFFD100[TA Tracker]|r Auto-selected: '%s' — step %d/%d",
                g.title, self.stepIdx, #g.steps))
            TA:Raw(TA.LOG.INFO, "|cFF888780Use /ta diag to see why this guide was chosen.|r")
        else
            TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA Tracker]|r No guide matched. Run |cFFFFD100/ta diag|r to see what the tracker sees.")
        end
    end,

    -- /ta diag  or  /ta diagnose — dump matching details to chat
    diag     = function(self) self:Diagnose() end,
    diagnose = function(self) self:Diagnose() end,
}


-- =============================================================================
-- PROXIMITY-BASED AUTO-ADVANCE (APR-style)
-- =============================================================================
-- When the current step is a 'travel' or 'Waypoint'-type step (no quest
-- action, just movement), auto-advance to the next step when the player
-- arrives within range. This eliminates manual "Mark Done" for travel steps.

local PROXIMITY_RANGE = 15  -- yards — advance when within this distance

function QT:CheckProximityAdvance()
    if not self.guideID then return end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return end
    local step = guide.steps[self.stepIdx]
    if not step then return end

    -- Determine which step types support proximity-based advancement.
    -- Core proximity types: waypoint, travel
    -- Extended: any step with an explicit "range" field is opt-in to proximity advance
    local stepType = step.type or ""
    local isProximityType = (stepType == "travel" or stepType == "waypoint" or stepType == "run")
    local hasExplicitRange = (step.range ~= nil and step.range > 0)

    if not isProximityType and not hasExplicitRange then
        return
    end

    -- Need a coord to measure distance against
    if not step.coord then return end
    local Arrow = TA:GetModule("Arrow")
    if not Arrow or not Arrow.GetEffectiveCoord then return end

    local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
    if coordMap == 0 and cx == 0 and cy == 0 then return end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then return end

    -- Zone-gating: don't auto-advance if the player is in a completely different zone.
    -- Allow advancement if coordMap is 0 (placeholder) or matches the player's zone tree.
    if coordMap ~= 0 and coordMap ~= currentMap then
        -- Walk map parents to check sub-zone containment
        local info = C_Map.GetMapInfo(currentMap)
        local inZone = false
        while info do
            if info.mapID == coordMap then inZone = true; break end
            if info.parentMapID and info.parentMapID > 0 then
                info = C_Map.GetMapInfo(info.parentMapID)
            else
                break
            end
        end
        if not inZone then return end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()

    -- Use step-specific range if provided, otherwise fall back to global default
    local range = step.range or PROXIMITY_RANGE
    local yards = TA.Utils.ComputeDistance(px, py, cx, cy)
    if yards <= range then
        -- Auto-advance: mark current step done and move to next incomplete
        step._manualDone = true
        for i = self.stepIdx + 1, #guide.steps do
            if not self:IsStepComplete(guide.steps[i]) then
                self.stepIdx = i
                self:SaveState()
                self:UpdateWindow()
                -- Subtle chat notification
                TA:Raw(TA.LOG.INFO, string.format("|cFF4AFF7A[TA]|r Arrived — advancing to step %d.", i))
                return
            end
        end
        -- All subsequent steps done — trigger route chaining via FastForward
        self:FastForward(false)
    end
end



-- =============================================================================
-- SIDE-DRAWER INTEGRATION
-- =============================================================================
-- When the modern UI drawer is available (TA.Modern.drawer), QuestTracker
-- renders a compact tracker view inside the drawer panel. The floating window
-- is hidden in this mode but remains available if the user switches to
-- fragmented layout.

function QT:InitDrawerMode()
    local M = TA.Modern
    if not M or not M.drawer then return end

    -- The floating window remains the primary always-visible tracker.
    -- The drawer provides a secondary view when the main ToonAge frame is open.
    -- Show the floating window if a guide is active.
    if self.guideID and TA.Guides and TA.Guides[self.guideID] then
        if self.window then
            self.window:Show()
            self:UpdateWindow()
            if TA.charDB then TA.charDB.tracker.visible = true end
        end
    end

    -- Render into the drawer (will only display when main frame is shown)
    self:UpdateDrawer()
end

--- Render the current guide step into the side-drawer content area.
--- Called from InitDrawerMode and hooked into UpdateWindow.
function QT:UpdateDrawer()
    local M = TA.Modern
    if not M or not M.drawer or not M.drawer:IsVisible() then return end

    local content = M:RebuildDrawerChild()
    if not content then return end

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local PAD = 8
    local contentW = M.DRAWER_WIDTH - 28

    if not guide then
        -- ── QUEST LOG FOLLOW MODE (mirrored from UpdateWindow) ────────────────
        local trackedQuestID = nil
        local trackedTitle = nil
        local trackedObjectives = nil

        if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
            trackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
            if trackedQuestID and trackedQuestID > 0 then
                trackedTitle = C_QuestLog.GetTitleForQuestID(trackedQuestID)
                trackedObjectives = C_QuestLog.GetQuestObjectives(trackedQuestID)
            end
        end

        if not trackedTitle then
            local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
            for i = 1, numEntries do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID then
                    if not C_QuestLog.IsQuestFlaggedCompleted(info.questID) then
                        trackedQuestID = info.questID
                        trackedTitle = info.title
                        trackedObjectives = C_QuestLog.GetQuestObjectives(info.questID)
                        break
                    end
                end
            end
        end

        local y = -PAD
        if trackedTitle then
            local headerF = M:CreateCaption(content, "Following Quest Log")
            headerF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            headerF:SetTextColor(unpack(M.CLR_TEXT_ACCENT))
            y = y - 14

            local titleF = M:CreateBody(content, trackedTitle)
            titleF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            titleF:SetWidth(contentW - PAD * 2)
            titleF:SetTextColor(1, 0.82, 0, 1)
            y = y - 16

            if trackedObjectives and #trackedObjectives > 0 then
                for _, obj in ipairs(trackedObjectives) do
                    if obj.text and obj.text ~= "" then
                        local objF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        objF:SetFont(M.FONT_BODY, M.SIZE_CAPTION, "")
                        objF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + 8, y)
                        objF:SetWidth(contentW - PAD * 2 - 8)
                        objF:SetJustifyH("LEFT")
                        if obj.finished then
                            objF:SetText("\226\156\147 " .. obj.text)
                            objF:SetTextColor(unpack(M.CLR_TEXT_SUCCESS))
                        else
                            objF:SetText("\226\151\139 " .. obj.text)
                            objF:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
                        end
                        y = y - 13
                    end
                end
            end

            y = y - 8
            local noteF = M:CreateCaption(content, "No ToonAge guide for this zone yet.")
            noteF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            noteF:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
            y = y - 12
            local noteF2 = M:CreateCaption(content, "Following your quest tracker instead.")
            noteF2:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            noteF2:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
            y = y - 14
        else
            local noGuide = M:CreateBody(content, "No active quests. Pick one up!")
            noGuide:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -PAD)
            noGuide:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
            y = -40
        end

        content:SetHeight(math.abs(y) + PAD)
        return
    end

    local total = #guide.steps
    local step  = guide.steps[self.stepIdx] or {}
    local y = -PAD

    -- Guide title
    local titleF = M:CreateCaption(content, guide.title or "Guide")
    titleF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    titleF:SetWidth(contentW - PAD * 2)
    titleF:SetJustifyH("LEFT")
    y = y - 14

    -- Step progress
    local progressF = M:CreateData(content, string.format("Step %d / %d", self.stepIdx, total))
    progressF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    y = y - 16

    -- Progress bar
    local barBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
    barBg:SetSize(contentW - PAD * 2, 4)
    barBg:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    barBg:SetBackdrop(M.BACKDROP_FLAT)
    barBg:SetBackdropColor(0.15, 0.15, 0.18, 1)
    barBg:SetBackdropBorderColor(0, 0, 0, 0)

    local barFill = barBg:CreateTexture(nil, "OVERLAY")
    barFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
    local pct = total > 0 and (self.stepIdx / total) or 0
    barFill:SetWidth(math.max(1, (contentW - PAD * 2) * pct))
    barFill:SetVertexColor(0.30, 0.80, 0.45, 0.9)
    y = y - 12

    -- Divider
    local div = content:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(0.30, 0.30, 0.35, 0.50)
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    div:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, y)
    y = y - 8

    -- Step type badge
    local typeBadge = step.type or "quest"
    local badgeColors = {
        quest  = M.CLR_TEXT_WARNING,
        travel = M.CLR_TEXT_ACCENT,
        npc    = M.CLR_TEXT_SUCCESS,
        item   = { 0.73, 0.60, 1.00, 1.00 },
        action = M.CLR_TEXT_WARNING,
        text   = M.CLR_TEXT_SECONDARY,
        accept = M.CLR_TEXT_SUCCESS,
    }
    local badgeF = M:CreateCaption(content, string.upper(typeBadge))
    badgeF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    local bClr = badgeColors[typeBadge] or M.CLR_TEXT_SECONDARY
    badgeF:SetTextColor(unpack(bClr))
    y = y - 14

    -- Step text
    local stepTextF = M:CreateBody(content, step.text or "")
    stepTextF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    stepTextF:SetWidth(contentW - PAD * 2)
    stepTextF:SetWordWrap(true)
    stepTextF:SetJustifyH("LEFT")
    local textH = stepTextF:GetStringHeight() or 14
    y = y - math.max(textH, 14) - 6

    -- Live objectives (if quest is in log)
    if step.questID and IsInLog(step.questID) then
        local objectives = C_QuestLog.GetQuestObjectives
                        and C_QuestLog.GetQuestObjectives(step.questID)
        if objectives and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                local objF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                objF:SetFont(M.FONT_BODY, M.SIZE_CAPTION, "")
                objF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + 8, y)
                objF:SetWidth(contentW - PAD * 2 - 8)
                objF:SetJustifyH("LEFT")
                if obj.finished then
                    objF:SetText("✓ " .. (obj.text or ""))
                    objF:SetTextColor(unpack(M.CLR_TEXT_SUCCESS))
                else
                    objF:SetText("○ " .. (obj.text or ""))
                    objF:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
                end
                y = y - 13
            end
            y = y - 4
        end
    end

    -- Quest status
    if step.questID then
        local statusText = ""
        local statusClr = M.CLR_TEXT_SECONDARY
        local qs = self:GetQuestStatus(step.questID)
        if qs == "complete"   then statusText = "Complete";       statusClr = M.CLR_TEXT_SUCCESS end
        if qs == "turnin"     then statusText = "Ready to Turn In"; statusClr = M.CLR_TEXT_WARNING end
        if qs == "inprogress" then statusText = "In Progress";    statusClr = M.CLR_TEXT_SECONDARY end
        if qs == "available"  then statusText = "Not Started";    statusClr = M.CLR_TEXT_SECONDARY end

        local stF = M:CreateCaption(content, statusText)
        stF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
        stF:SetTextColor(unpack(statusClr))
        y = y - 14
    end

    -- Distance / ETA from arrow
    local Arrow = TA:GetModule("Arrow")
    if Arrow and Arrow.GetEffectiveCoord and step.coord and step.type ~= "text" then
        local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
        local currentMap = C_Map.GetBestMapForUnit("player")
        if currentMap and not (coordMap == 0 and cx == 0 and cy == 0) then
            local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
            if pos then
                local px, py = pos:GetXY()
                local yards = TA.Utils.ComputeDistance(px, py, cx, cy)
                local TM    = TA:GetModule("TravelModes")
                local speed = (TM and TM:GetSpeed()) or 7
                local distF = M:CreateCaption(content,
                    TA.Utils.FormatDistance(yards) .. "  " .. TA.Utils.FormatETA(yards, speed))
                distF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
                distF:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
                y = y - 14
            end
        end
    end

    -- Final height
    content:SetHeight(math.abs(y) + PAD)
end

-- Hook UpdateWindow to also update the drawer when in unified mode.
-- This is done by wrapping the original UpdateWindow.
do
    local origUpdateWindow = QT.UpdateWindow
    if origUpdateWindow then
        QT.UpdateWindow = function(self)
            origUpdateWindow(self)
            -- Also update drawer if in unified mode
            if TA.db and TA.db.useUnifiedUI and TA.Modern and TA.Modern.drawer then
                self:UpdateDrawer()
            end
        end
    end
end
