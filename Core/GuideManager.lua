--[[
    ToonAge - GuideManager.lua
    Centralized Guide State Controller (Single Source of Truth)

    Loads after: Init.lua, Utils.lua
    Loads before: All modules (QuestTracker, Drawer, etc.)

    This service decouples guide state from UI frames. All consumers
    register as listeners and react to state changes uniformly.

    TODO: Patch QuestTracker.lua to:
      - Remove its local guideID / stepIdx variables
      - Use GM:GetGuide() / GM:GetStep() instead
      - Register UpdateWindow and UpdateDrawer as listeners via GM:RegisterListener()
      - This eliminates the manual "Re-Sync" button entirely
--]]

local TA = ToonAge
TA.GuideManager = TA.GuideManager or {}
local GM = TA.GuideManager

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
GM.guideID   = nil    -- (string|nil) active guide key
GM.stepIdx   = 1      -- (number) current step index
GM.listeners = {}     -- (table) array of callback functions

---------------------------------------------------------------------------
-- Listener Management
---------------------------------------------------------------------------

--- Register a callback that fires on any state change.
-- @param fn function(guideID, stepIdx)
function GM:RegisterListener(fn)
    if type(fn) ~= "function" then
        error("GuideManager:RegisterListener() expects a function, got " .. type(fn), 2)
    end
    self.listeners[#self.listeners + 1] = fn
end

--- Notify all registered listeners of the current state.
function GM:NotifyListeners()
    for i = 1, #self.listeners do
        local ok, err = pcall(self.listeners[i], self.guideID, self.stepIdx)
        if not ok then
            -- Protect against a single bad listener breaking the chain
            if TA.Utils and TA.Utils.Print then
                TA.Utils:Print("|cffff0000GuideManager listener error:|r " .. tostring(err))
            end
        end
    end
end

---------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------

--- Returns the active guide key.
-- @return string|nil
function GM:GetGuide()
    return self.guideID
end

--- Returns the current step index.
-- @return number
function GM:GetStep()
    return self.stepIdx
end

--- Returns the full guide data table for the active guide.
-- @return table|nil
function GM:GetGuideData()
    if not self.guideID then return nil end
    return TA.Guides and TA.Guides[self.guideID] or nil
end

--- Returns the current step table from the active guide.
-- @return table|nil
function GM:GetCurrentStep()
    local guide = self:GetGuideData()
    if not guide or not guide.steps then return nil end
    return guide.steps[self.stepIdx]
end

---------------------------------------------------------------------------
-- Setters / Navigation
---------------------------------------------------------------------------

--- Set the active guide and reset to step 1.
-- @param guideID string — key into TA.Guides
function GM:SetGuide(guideID)
    self.guideID = guideID
    self.stepIdx = 1
    self:NotifyListeners()
end

--- Set the current step index directly.
-- @param stepIdx number
function GM:SetStep(stepIdx)
    if type(stepIdx) ~= "number" or stepIdx < 1 then
        stepIdx = 1
    end

    local guide = self:GetGuideData()
    if guide and guide.steps then
        local maxStep = #guide.steps
        if stepIdx > maxStep then
            stepIdx = maxStep
        end
    end

    self.stepIdx = stepIdx
    self:NotifyListeners()
end

--- Advance to the next step (clamped to guide length).
function GM:AdvanceStep()
    local guide = self:GetGuideData()
    if not guide or not guide.steps then return end

    local maxStep = #guide.steps
    if self.stepIdx < maxStep then
        self.stepIdx = self.stepIdx + 1
        self:NotifyListeners()
    end
end

--- Retreat to the previous step (minimum 1).
function GM:RetreatStep()
    if self.stepIdx > 1 then
        self.stepIdx = self.stepIdx - 1
        self:NotifyListeners()
    end
end

---------------------------------------------------------------------------
-- Unified Display Update
---------------------------------------------------------------------------

--- Trigger a full UI refresh across all registered consumers.
-- This is the key unification point — both the standalone QuestTracker
-- window and the drawer panel receive the same notification, keeping
-- them in sync without a manual "Re-Sync" button.
function GM:UpdateDisplay()
    self:NotifyListeners()
end

---------------------------------------------------------------------------
-- Persistence
---------------------------------------------------------------------------

--- Save current state to the character-specific saved variables.
function GM:SaveState()
    if not TA.charDB then return end
    TA.charDB.tracker = TA.charDB.tracker or {}
    TA.charDB.tracker.guideID = self.guideID
    TA.charDB.tracker.stepIdx = self.stepIdx
end

--- Restore state from character-specific saved variables.
function GM:RestoreState()
    if not TA.charDB or not TA.charDB.tracker then return end
    local saved = TA.charDB.tracker
    self.guideID = saved.guideID or nil
    self.stepIdx = saved.stepIdx or 1
end
