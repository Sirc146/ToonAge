-- ToonAge/Modules/TargetMarker.lua
-- Marks quest objective NPCs on nameplates so you can identify them at a glance.
-- Inspired by APR's "skull above the mob" feature.
--
-- How it works:
--   1. When a guide step has a kill/objective quest, reads C_QuestLog.GetQuestObjectives()
--   2. Extracts creature objective names (the text before the count, e.g. "Kobold Vermin")
--   3. On NAME_PLATE_UNIT_ADDED, checks if the nameplate unit name matches an objective
--   4. If match: attaches a glowing quest icon above the nameplate
--   5. On NAME_PLATE_UNIT_REMOVED or objective completion, removes the icon
--
-- This is NOT a raid marker (SetRaidTarget requires group lead / no restrictions
-- in solo play but is intrusive). Instead we draw a custom texture on the nameplate
-- frame — works in all situations without affecting other players.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local TM = {}
TA:RegisterModule("TargetMarker", TM)

-- ── State ─────────────────────────────────────────────────────────────────────
TM.activeObjectives = {}   -- { [creatureName] = { questID, text, finished } }
TM.markedPlates    = {}   -- { [namePlateFrame] = iconFrame }
TM.enabled         = true

-- ── Constants ─────────────────────────────────────────────────────────────────
local ICON_SIZE = 24
local ICON_TEXTURE = "Interface\\GossipFrame\\AvailableQuestIcon"  -- yellow ! / quest star
local ICON_GLOW_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"

-- ── Objective scanning ────────────────────────────────────────────────────────

--- Scan the current guide step's quest objectives and extract creature names to watch for.
function TM:RefreshObjectives()
    wipe(self.activeObjectives)

    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return end

    -- Look at current step and next 2-3 steps for kill objectives
    local startIdx = QT.stepIdx or 1
    local endIdx = math.min(startIdx + 3, #guide.steps)

    for i = startIdx, endIdx do repeat
        local step = guide.steps[i]
        if not step or not step.questID then break end

        -- Only scan quests that are in the log (active)
        local logIdx = C_QuestLog.GetLogIndexForQuestID(step.questID)
        if not logIdx then break end

        -- Get objectives for this quest
        local objectives = C_QuestLog.GetQuestObjectives(step.questID)
        if not objectives then break end

        for _, obj in ipairs(objectives) do
            if not obj.finished and obj.type == "monster" then
                -- Extract creature name from objective text
                -- Format is usually "Creature Name: 3/8" or "0/8 Creature Name slain"
                local name = obj.text
                -- Strip count patterns: "0/8 " prefix or ": 3/8" suffix
                name = name:gsub("%d+/%d+%s*", ""):gsub(":%s*%d+/%d+", "")
                -- Strip common suffixes
                name = name:gsub("%s+slain$", ""):gsub("%s+killed$", ""):gsub("%s+defeated$", "")
                name = name:match("^%s*(.-)%s*$")  -- trim

                if name and name ~= "" then
                    self.activeObjectives[name:lower()] = {
                        questID  = step.questID,
                        text     = obj.text,
                        finished = obj.finished,
                    }
                end
            end
        end
    until true end
end

-- ── Nameplate management ──────────────────────────────────────────────────────

--- Check if a nameplate unit matches an active kill objective.
local function IsObjectiveTarget(unitToken)
    if not UnitExists(unitToken) then return false end
    if UnitIsDead(unitToken) then return false end
    if not UnitCanAttack("player", unitToken) then return false end

    local name = UnitName(unitToken)
    if not name then return false end

    return TM.activeObjectives[name:lower()] ~= nil
end

--- Attach a quest objective icon above a nameplate.
function TM:MarkNameplate(namePlate, unitToken)
    if self.markedPlates[namePlate] then return end  -- already marked

    -- Create the icon frame
    local icon = CreateFrame("Frame", nil, namePlate)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("BOTTOM", namePlate, "TOP", 0, 4)
    icon:SetFrameStrata("HIGH")

    -- Quest icon texture (yellow !)
    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(ICON_TEXTURE)
    tex:SetAllPoints(icon)
    tex:SetVertexColor(1, 0.82, 0, 1)
    icon.tex = tex

    -- Pulsing glow behind the icon
    local glow = icon:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(ICON_GLOW_TEXTURE)
    glow:SetSize(ICON_SIZE * 1.8, ICON_SIZE * 1.8)
    glow:SetPoint("CENTER", icon, "CENTER")
    glow:SetVertexColor(1, 0.82, 0, 0.4)
    glow:SetBlendMode("ADD")
    icon.glow = glow

    -- Pulse animation via simple OnUpdate
    local elapsed = 0
    icon:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local alpha = 0.3 + 0.3 * math.sin(elapsed * 3)
        glow:SetAlpha(alpha)
    end)

    icon:Show()
    self.markedPlates[namePlate] = icon
end

--- Remove the quest icon from a nameplate.
function TM:UnmarkNameplate(namePlate)
    local icon = self.markedPlates[namePlate]
    if icon then
        icon:Hide()
        icon:SetParent(nil)
        self.markedPlates[namePlate] = nil
    end
end

--- Scan all visible nameplates and mark/unmark as needed.
function TM:ScanAllNameplates()
    -- Mark matching plates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
            if namePlate then
                if IsObjectiveTarget(unit) then
                    self:MarkNameplate(namePlate, unit)
                else
                    self:UnmarkNameplate(namePlate)
                end
            end
        end
    end
end

-- ── Event handling ────────────────────────────────────────────────────────────

function TM:OnEvent(event, ...)
    if not self.enabled then return end

    if event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        if IsObjectiveTarget(unitToken) then
            local namePlate = C_NamePlate.GetNamePlateForUnit(unitToken)
            if namePlate then
                self:MarkNameplate(namePlate, unitToken)
            end
        end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unitToken = ...
        local namePlate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if namePlate then
            self:UnmarkNameplate(namePlate)
        end

    elseif event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" then
        -- Objectives may have changed — rescan
        self:RefreshObjectives()
        self:ScanAllNameplates()

    elseif event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
        self:RefreshObjectives()
        self:ScanAllNameplates()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function TM:Init()
    TA.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    TA.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Initial scan after a short delay (let QuestTracker init first)
    C_Timer.After(2, function()
        TM:RefreshObjectives()
        TM:ScanAllNameplates()
    end)
end

TM.SlashCommands = {}
