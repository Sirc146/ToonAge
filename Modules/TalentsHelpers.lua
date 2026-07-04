-- Modules/TalentsHelpers.lua
local TA = ToonAge
TA.TalentsAPI = TA.TalentsAPI or {}

local function safeInsert(t, v)
  if v and type(v) == "number" then table.insert(t, v) end
end

local function parseExportStringForIDs(export)
  local ids = {}
  if not export or type(export) ~= "string" then return ids end
  -- Many export strings include numeric node IDs; extract sequences of digits
  for num in export:gmatch("(%d+)") do
    local n = tonumber(num)
    if n then table.insert(ids, n) end
  end
  -- Remove duplicates while preserving order
  local seen = {}
  local uniq = {}
  for _, v in ipairs(ids) do
    if not seen[v] then seen[v] = true; table.insert(uniq, v) end
  end
  return uniq
end

local function tryClassTalentsNodes()
  local ids = {}
  if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
    local cfgID = C_ClassTalents.GetActiveConfigID()
    if cfgID then
      -- Preferred: C_Traits.GetConfigInfo returns nodes table on modern clients
      if C_Traits and C_Traits.GetConfigInfo then
        local ok, info = pcall(C_Traits.GetConfigInfo, cfgID)
        if ok and info and info.nodes then
          for _, node in ipairs(info.nodes) do
            if node and node.id then safeInsert(ids, node.id) end
          end
          if #ids > 0 then return ids end
        end
      end
      -- Fallback: try export string from C_ClassTalents
      if C_ClassTalents.GetExportString then
        local ok, export = pcall(C_ClassTalents.GetExportString, cfgID)
        if ok and export and type(export) == "string" then
          local parsed = parseExportStringForIDs(export)
          if #parsed > 0 then return parsed end
        end
      end
    end
  end
  return ids
end

local function tryCTraitsActiveConfig()
  local ids = {}
  if C_Traits and C_Traits.GetActiveConfigID and C_Traits.GetConfigInfo then
    local ok, cfg = pcall(C_Traits.GetActiveConfigID)
    if ok and cfg then
      local ok2, info = pcall(C_Traits.GetConfigInfo, cfg)
      if ok2 and info and info.nodes then
        for _, node in ipairs(info.nodes) do
          if node and node.id then safeInsert(ids, node.id) end
        end
        if #ids > 0 then return ids end
      end
    end
  end
  return ids
end

local function scanTalentFrameForSelectedNodes()
  local ids = {}
  -- Best-effort scan of common talent frame containers
  local frames = {
    _G["PlayerTalentFrame"],
    _G["ClassTalentFrame"],
    _G["TalentFrame"],
    _G["PlayerTalentFrameTalents"],
    _G["ClassTalentFrameTalents"]
  }
  for _, f in ipairs(frames) do
    if f and f:IsShown() then
      for _, child in ipairs({ f:GetChildren() }) do
        -- Common properties used by various Blizzard frames
        local nid = child.nodeID or child.talentID or (child.GetTalentID and child.GetTalentID and child:GetTalentID())
        if nid and type(nid) == "number" then
          -- Determine selection state: many legacy buttons expose GetChecked or a selected texture
          local selected = false
          if child.GetChecked and child.GetChecked() then selected = true end
          if child.IsSelected and child:IsSelected() then selected = true end
          -- Some frames use a .selected or .active boolean
          if child.selected or child.active then selected = true end
          if selected then safeInsert(ids, nid) end
        end
      end
      if #ids > 0 then return ids end
    end
  end
  return ids
end

function TA.TalentsAPI.GetActiveTalentIDs()
  -- 1. Try modern C_ClassTalents + C_Traits path
  local ids = tryClassTalentsNodes()
  if ids and #ids > 0 then return ids end

  -- 2. Try direct C_Traits active config (some clients expose only this)
  ids = tryCTraitsActiveConfig()
  if ids and #ids > 0 then return ids end

  -- 3. Try parsing export strings from other APIs if present
  -- (some addons or clients expose export strings in other places)
  -- No-op here; already attempted export via C_ClassTalents above.

  -- 4. Legacy fallback: scan talent frame if open
  ids = scanTalentFrameForSelectedNodes()
  if ids and #ids > 0 then return ids end

  -- 5. Final fallback: return empty table (safe)
  return {}
end

-- ── Spec role & style ──────────────────────────────────────────────────
-- role: TANK / HEALER / DAMAGER  (mirrors GetSpecializationInfo 5th return)
-- style: melee / ranged  (only meaningful for DAMAGER; informs display label)
local SpecInfoDB = {
  -- Death Knight
  [250] = { role="TANK",    style="melee"  }, -- Blood
  [251] = { role="DAMAGER", style="melee"  }, -- Frost
  [252] = { role="DAMAGER", style="melee"  }, -- Unholy
  -- Demon Hunter
  [577] = { role="DAMAGER", style="melee"  }, -- Havoc
  [581] = { role="TANK",    style="melee"  }, -- Vengeance
  -- Druid
  [102] = { role="DAMAGER", style="ranged" }, -- Balance
  [103] = { role="DAMAGER", style="melee"  }, -- Feral
  [104] = { role="TANK",    style="melee"  }, -- Guardian
  [105] = { role="HEALER",  style="ranged" }, -- Restoration
  -- Evoker
  [1467] = { role="DAMAGER", style="ranged" }, -- Devastation
  [1468] = { role="HEALER",  style="ranged" }, -- Preservation
  [1473] = { role="DAMAGER", style="ranged" }, -- Augmentation
  -- Hunter
  [253] = { role="DAMAGER", style="ranged" }, -- Beast Mastery
  [254] = { role="DAMAGER", style="ranged" }, -- Marksmanship
  [255] = { role="DAMAGER", style="melee"  }, -- Survival
  -- Mage
  [62]  = { role="DAMAGER", style="ranged" }, -- Arcane
  [63]  = { role="DAMAGER", style="ranged" }, -- Fire
  [64]  = { role="DAMAGER", style="ranged" }, -- Frost
  -- Monk
  [268] = { role="TANK",    style="melee"  }, -- Brewmaster
  [269] = { role="DAMAGER", style="melee"  }, -- Windwalker
  [270] = { role="HEALER",  style="melee"  }, -- Mistweaver
  -- Paladin
  [65]  = { role="HEALER",  style="melee"  }, -- Holy
  [66]  = { role="TANK",    style="melee"  }, -- Protection
  [70]  = { role="DAMAGER", style="melee"  }, -- Retribution
  -- Priest
  [256] = { role="HEALER",  style="ranged" }, -- Discipline
  [257] = { role="HEALER",  style="ranged" }, -- Holy
  [258] = { role="DAMAGER", style="ranged" }, -- Shadow
  -- Rogue
  [259] = { role="DAMAGER", style="melee"  }, -- Assassination
  [260] = { role="DAMAGER", style="melee"  }, -- Outlaw
  [261] = { role="DAMAGER", style="melee"  }, -- Subtlety
  -- Shaman
  [262] = { role="DAMAGER", style="ranged" }, -- Elemental
  [263] = { role="DAMAGER", style="melee"  }, -- Enhancement
  [264] = { role="HEALER",  style="ranged" }, -- Restoration
  -- Warlock
  [265] = { role="DAMAGER", style="ranged" }, -- Affliction
  [266] = { role="DAMAGER", style="ranged" }, -- Demonology
  [267] = { role="DAMAGER", style="ranged" }, -- Destruction
  -- Warrior
  [71]  = { role="DAMAGER", style="melee"  }, -- Arms
  [72]  = { role="DAMAGER", style="melee"  }, -- Fury
  [73]  = { role="TANK",    style="melee"  }, -- Protection
}

function TA.TalentsAPI.GetSpecInfo(specID)
  return SpecInfoDB[specID] or { role="DAMAGER", style="melee" }
end

-- Scores active talent node IDs against a stored profile node list.
-- Returns 0-100 (integer %) or nil when profileNodes is empty (no data).
function TA.TalentsAPI.ScoreProfile(activeIDs, profileNodes)
  if not profileNodes or #profileNodes == 0 then return nil end
  if not activeIDs    or #activeIDs    == 0 then return 0    end
  local active = {}
  for _, id in ipairs(activeIDs) do active[id] = true end
  local hits = 0
  for _, id in ipairs(profileNodes) do
    if active[id] then hits = hits + 1 end
  end
  return math.floor((hits / #profileNodes) * 100)
end
