-- ToonAge/Modules/PullPlanner.lua
-- Smart AoE Pull Planning: clusters nearby kill-objective mobs and suggests
-- efficient pull groups. Shows on NavHud/nameplates which mobs to pull together.
--
-- No other guide addon provides combat-aware routing or pull optimization.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local PP = {}
TA:RegisterModule("PullPlanner", PP)

-- ── Constants ─────────────────────────────────────────────────────────────────
local CLUSTER_RANGE   = 15    -- yards: mobs within this distance form a cluster
local MAX_PULL_SIZE   = 5     -- don't suggest pulling more than this
local UPDATE_INTERVAL = 1.0   -- seconds between re-scans
local PULL_COLOR      = { 0.12, 0.74, 1.00, 0.8 }  -- blue cluster indicator

-- ── State ─────────────────────────────────────────────────────────────────────
PP.objectiveCreatures = {}  -- { [npcName:lower()] = true }
PP.clusters           = {}  -- { { units={unit1,unit2,...}, center={x,y} }, ... }
PP.ticker             = nil

-- ── Objective detection ───────────────────────────────────────────────────────

function PP:RefreshObjectiveTargets()
    wipe(self.objectiveCreatures)

    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return end
    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return end

    local step = guide.steps[QT.stepIdx]
    if not step or not step.questID then return end

    local objectives = C_QuestLog.GetQuestObjectives(step.questID)
    if not objectives then return end

    for _, obj in ipairs(objectives) do
        if not obj.finished and obj.type == "monster" then
            local name = obj.text:gsub("%d+/%d+%s*", ""):gsub(":%s*%d+/%d+", "")
            name = name:gsub("%s+slain$", ""):gsub("%s+killed$", ""):gsub("%s+defeated$", "")
            name = name:match("^%s*(.-)%s*$")
            if name and name ~= "" then
                self.objectiveCreatures[name:lower()] = true
            end
        end
    end
end

-- ── Nameplate clustering ──────────────────────────────────────────────────────

function PP:ScanAndCluster()
    wipe(self.clusters)
    if not next(self.objectiveCreatures) then return end

    -- Collect all objective mobs currently visible on nameplates
    local mobs = {}  -- { { unit, name, x, y } }
    local playerMap = C_Map.GetBestMapForUnit("player")
    if not playerMap then return end

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and not UnitIsDead(unit) and UnitCanAttack("player", unit) then
            local name = UnitName(unit)
            if name and self.objectiveCreatures[name:lower()] then
                -- Get position relative to player (use nameplate position as proxy)
                local plate = C_NamePlate.GetNamePlateForUnit(unit)
                if plate then
                    table.insert(mobs, { unit = unit, name = name, plate = plate })
                end
            end
        end
    end

    if #mobs < 2 then return end  -- need at least 2 mobs to form a cluster

    -- Simple greedy clustering: for each unassigned mob, find all mobs
    -- within CLUSTER_RANGE and group them together.
    -- Since we can't get exact world positions from nameplates easily,
    -- use the number of mobs per cluster as the grouping hint.
    -- The TargetMarker already shows which mobs to hit — PullPlanner
    -- adds a count indicator showing how many are nearby.
    local assigned = {}
    for i, mob in ipairs(mobs) do
        if not assigned[i] then
            local cluster = { mobs[i] }
            assigned[i] = true

            -- Group all nearby unassigned mobs (within screen proximity)
            -- Since we can't measure world distance between nameplates,
            -- use frame distance as a proxy
            local plateA = mob.plate
            local ax, ay = plateA:GetCenter()

            for j = i + 1, #mobs do
                if not assigned[j] and #cluster < MAX_PULL_SIZE then
                    local plateB = mobs[j].plate
                    local bx, by = plateB:GetCenter()
                    -- Screen distance in pixels — roughly correlates with world distance
                    local screenDist = math.sqrt((ax - bx)^2 + (ay - by)^2)
                    if screenDist < 200 then  -- ~200px = roughly CLUSTER_RANGE at normal zoom
                        table.insert(cluster, mobs[j])
                        assigned[j] = true
                    end
                end
            end

            if #cluster >= 2 then
                table.insert(self.clusters, cluster)
            end
        end
    end

    -- Show cluster count on the first mob's nameplate in each cluster
    self:ShowClusterIndicators()
end

-- ── Visual indicators ─────────────────────────────────────────────────────────

PP._indicators = {}  -- reusable indicator frames

function PP:ShowClusterIndicators()
    -- Hide all existing indicators
    for _, ind in ipairs(self._indicators) do
        ind:Hide()
    end

    for i, cluster in ipairs(self.clusters) do
        if #cluster >= 2 then
            -- Show "Pull x3" indicator on the first mob's nameplate
            local plate = cluster[1].plate
            local ind = self._indicators[i]

            if not ind then
                ind = CreateFrame("Frame", nil, UIParent)
                ind:SetSize(40, 16)
                ind:SetFrameStrata("HIGH")

                local bg = ind:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(PULL_COLOR[1], PULL_COLOR[2], PULL_COLOR[3], 0.7)

                local text = ind:CreateFontString(nil, "OVERLAY")
                text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
                text:SetAllPoints()
                text:SetJustifyH("CENTER")
                ind.text = text

                self._indicators[i] = ind
            end

            ind:SetParent(plate)
            ind:ClearAllPoints()
            ind:SetPoint("TOP", plate, "TOP", 0, 18)
            ind.text:SetText(string.format("|cFF1EBCFF⚔ Pull %d|r", #cluster))
            ind:Show()
        end
    end
end

-- ── Event handling ────────────────────────────────────────────────────────────

function PP:OnEvent(event, ...)
    if event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        self:RefreshObjectiveTargets()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function PP:Init()
    C_Timer.After(3, function()
        PP:RefreshObjectiveTargets()
    end)

    -- Periodic cluster scan
    self.ticker = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        if next(PP.objectiveCreatures) then
            PP:ScanAndCluster()
        end
    end)
end

PP.SlashCommands = {}
