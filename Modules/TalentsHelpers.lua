-- Modules/TalentsHelpers.lua
local TA = ToonAge
local U  = TA.Utils
TA.TalentsAPI = TA.TalentsAPI or {}

local function safeInsert(t, v)
  if v and type(v) == "number" then table.insert(t, v) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: Blizzard Import String Decoder
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- Decodes Blizzard talent loadout strings (base64 bit-packed format) to extract
-- the selected node IDs. This replaces the previous "intentionally NOT used"
-- approach. Uses ExportUtil.MakeImportDataStream (Blizzard built-in) + the same
-- algorithm as TalentTreeTweaks/TalentTreeViewer.
--
-- Format (serialization version 2):
--   8 bits  → version (= 2)
--   16 bits → specID
--   128 bits → tree hash (16 × 8-bit values; all-zero = skip validation)
--   Body: per node in C_Traits.GetTreeNodes() order:
--     1 bit → isNodeSelected
--     if selected:
--       1 bit → isNodePurchased (vs granted/free)
--       if purchased:
--         1 bit → isPartiallyRanked
--         if partially ranked:
--           6 bits → ranksPurchased
--         1 bit → isChoiceNode
--         if choice:
--           2 bits → entryIndex (0-based)
-- ═══════════════════════════════════════════════════════════════════════════════

local BIT_WIDTH_VERSION = 8
local BIT_WIDTH_SPEC_ID = 16
local BIT_WIDTH_RANKS   = 6
local SERIALIZATION_VERSION = 2

--- Node cache per treeID for performance
local _treeNodeCache = {}
local function GetCachedTreeNodes(treeID)
    if not _treeNodeCache[treeID] then
        _treeNodeCache[treeID] = C_Traits.GetTreeNodes(treeID)
    end
    return _treeNodeCache[treeID]
end

local _treeHashCache = {}
local function GetCachedTreeHash(treeID)
    if not _treeHashCache[treeID] then
        _treeHashCache[treeID] = C_Traits.GetTreeHash(treeID)
    end
    return _treeHashCache[treeID]
end

--- Validate a tree hash from an import string against the current game data.
--- All-zero hash always passes (used by TalentTreeViewer for cross-patch compat).
local function IsTreeHashValid(importedHash, treeID)
    if not importedHash or #importedHash ~= 16 then return false end
    local expected = GetCachedTreeHash(treeID)
    if not expected then return false end

    local allZero = true
    for i, val in ipairs(importedHash) do
        if val ~= 0 then allZero = false end
        if not allZero and val ~= expected[i] then
            return false
        end
    end
    return true  -- all-zero passes, or matched
end

--- Decode a Blizzard talent export string into structured node data.
--- @param importString string — the base64 loadout string
--- @return table|nil result — { specID, classID, treeHashValid, nodes = { {nodeID, isSelected, isPurchased, ...} } }
--- @return string|nil error — error message on failure
function TA.TalentsAPI.DecodeImportString(importString)
    if not importString or importString == "" then
        return nil, "Empty import string"
    end

    -- Requires Blizzard's ExportUtil (available since Dragonflight)
    if not ExportUtil or not ExportUtil.MakeImportDataStream then
        return nil, "ExportUtil not available (requires Dragonflight+)"
    end

    local ok, importStream = pcall(ExportUtil.MakeImportDataStream, importString)
    if not ok or not importStream then
        return nil, "Failed to parse base64 string"
    end

    -- ── Read header ──────────────────────────────────────────────────
    local totalBits = importStream:GetNumberOfBits()
    local headerBits = BIT_WIDTH_VERSION + BIT_WIDTH_SPEC_ID + 128
    if totalBits < headerBits then
        return nil, "String too short for header"
    end

    local version = importStream:ExtractValue(BIT_WIDTH_VERSION)
    if version ~= SERIALIZATION_VERSION then
        return nil, "Unsupported serialization version: " .. tostring(version)
    end

    local specID = importStream:ExtractValue(BIT_WIDTH_SPEC_ID)

    -- Tree hash: 16 × 8-bit values
    local treeHash = {}
    for i = 1, 16 do
        treeHash[i] = importStream:ExtractValue(8)
    end

    -- ── Resolve treeID from specID ───────────────────────────────────
    -- Need classID to get treeID via C_Traits
    local _, _, _, _, _, classFileName = GetSpecializationInfoByID(specID)
    if not classFileName then
        return nil, "Unknown specID: " .. tostring(specID)
    end

    -- Get classID from the class file name
    local classID = nil
    for i = 1, GetNumClasses() do
        local _, cFile, cID = GetClassInfo(i)
        if cFile == classFileName then classID = cID; break end
    end
    if not classID then
        return nil, "Could not resolve classID for " .. classFileName
    end

    -- Get treeID — prefer C_ClassTalents if available
    local treeID = nil
    if C_ClassTalents and C_ClassTalents.GetTraitTreeForSpec then
        treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    end
    -- Fallback: try the LibTalentTree pattern or iterate configs
    if not treeID and C_Traits and C_Traits.GetConfigInfo then
        local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
        if configID then
            local info = C_Traits.GetConfigInfo(configID)
            if info and info.treeIDs and #info.treeIDs > 0 then
                treeID = info.treeIDs[1]
            end
        end
    end
    if not treeID then
        return nil, "Could not resolve talent treeID"
    end

    -- ── Validate tree hash ───────────────────────────────────────────
    local hashValid = IsTreeHashValid(treeHash, treeID)

    -- ── Read body: per-node selection data ────────────────────────────
    local treeNodes = GetCachedTreeNodes(treeID)
    if not treeNodes or #treeNodes == 0 then
        return nil, "No tree nodes found for treeID " .. tostring(treeID)
    end

    local nodes = {}
    local selectedNodeIDs = {}

    for i, nodeID in ipairs(treeNodes) do
        local isSelected = importStream:ExtractValue(1) == 1
        local isPurchased = false
        local isPartiallyRanked = false
        local ranksPurchased = 0
        local isChoice = false
        local choiceIndex = 0

        if isSelected then
            isPurchased = importStream:ExtractValue(1) == 1
            if isPurchased then
                isPartiallyRanked = importStream:ExtractValue(1) == 1
                if isPartiallyRanked then
                    ranksPurchased = importStream:ExtractValue(BIT_WIDTH_RANKS)
                end
                isChoice = importStream:ExtractValue(1) == 1
                if isChoice then
                    choiceIndex = importStream:ExtractValue(2)  -- 0-based
                end
            end
        end

        nodes[i] = {
            nodeID            = nodeID,
            isSelected        = isSelected,
            isPurchased       = isPurchased,
            isPartiallyRanked = isPartiallyRanked,
            ranksPurchased    = ranksPurchased,
            isChoice          = isChoice,
            choiceIndex       = choiceIndex + 1,  -- convert to 1-based
        }

        if isSelected and isPurchased then
            table.insert(selectedNodeIDs, nodeID)
        end
    end

    return {
        specID         = specID,
        classID        = classID,
        treeID         = treeID,
        treeHashValid  = hashValid,
        nodes          = nodes,
        selectedNodeIDs = selectedNodeIDs,
    }, nil
end

--- Convenience: extract just the node IDs from an import string.
--- @param importString string
--- @return table nodeIDs — array of selected/purchased node IDs, or empty table on error
function TA.TalentsAPI.GetNodeIDsFromString(importString)
    local result, err = TA.TalentsAPI.DecodeImportString(importString)
    if not result then
        if TA.debug then
            print("|cFFFF4444[TA Talents]|r Decode error: " .. (err or "unknown"))
        end
        return {}
    end
    return result.selectedNodeIDs or {}
end

--- Validate whether a stored build string is still valid for the current tree.
--- @param importString string
--- @return boolean isValid
--- @return string|nil reason — nil if valid, otherwise explanation
function TA.TalentsAPI.ValidateBuildString(importString)
    local result, err = TA.TalentsAPI.DecodeImportString(importString)
    if not result then return false, err end
    if not result.treeHashValid then
        return false, "Tree structure has changed since this build was created"
    end
    if #result.selectedNodeIDs == 0 then
        return false, "No talent selections found in string"
    end
    return true, nil
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
      -- C_Traits.GetConfigInfo unavailable or returned no nodes.
      -- Export-string parsing is NOT attempted here — it extracts every digit
      -- sequence in the blob, yielding version bytes, level values, and
      -- coordinate data alongside any real node IDs. See the comment above
      -- tryClassTalentsNodes for details. Return empty; callers will fall
      -- through to tryCTraitsActiveConfig or the talent-frame scan.
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
  -- 1. Try modern C_ClassTalents + C_Traits path (preferred)
  local ids = tryClassTalentsNodes()
  if ids and #ids > 0 then return ids end

  -- 2. Try direct C_Traits active config (some clients expose only this)
  ids = tryCTraitsActiveConfig()
  if ids and #ids > 0 then return ids end

  -- 3. Legacy fallback: scan talent frame if open
  ids = scanTalentFrameForSelectedNodes()
  if ids and #ids > 0 then return ids end

  -- 4. Final fallback: return empty table (safe; callers check #ids > 0)
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


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION: Algorithmic Leveling Path Generator
-- ═══════════════════════════════════════════════════════════════════════════════
-- Given an endgame import string, compute the optimal level-by-level talent
-- point order by topologically sorting nodes based on tree prerequisites.
-- This eliminates manual levelPath data entry for all 39 specs.
--
-- Algorithm:
--   1. Decode the import string → get list of selected nodeIDs
--   2. Query C_Traits for each node's prerequisites (edges[nodeID] = {prereqIDs})
--   3. Topological sort: nodes with no prereqs first, then depth-first
--   4. Map sorted order to levels (10, 11, 12, ...) based on WoW's talent
--      point grant schedule
--   5. Return a levelPath table: { [10]="Talent A", [11]="Talent B", ... }
-- ═══════════════════════════════════════════════════════════════════════════════

--- Generate a leveling path from an import string for the current spec.
--- Must be called while the player is in the target spec (C_Traits needs it).
--- @param importString string — the endgame build import string
--- @return table|nil levelPath — { [level] = "Talent Name", ... } or nil on failure
function TA.TalentsAPI.GenerateLevelingPath(importString)
    if not importString or importString == "" then return nil end
    if not C_Traits or not C_Traits.GetConfigIDBySystemID then return nil end

    -- Step 1: Get selected node IDs from the import string
    local selectedNodes = TA.TalentsAPI.GetNodeIDsFromString(importString)
    if not selectedNodes or #selectedNodes == 0 then return nil end

    -- Step 2: Get the active talent config to query tree structure
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                  and C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end

    -- Step 3: Build dependency graph for selected nodes
    local nodeInfo = {}   -- [nodeID] = { name, prereqs={}, depth=0 }
    local selectedSet = {}
    for _, nodeID in ipairs(selectedNodes) do
        selectedSet[nodeID] = true
    end

    for _, nodeID in ipairs(selectedNodes) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        if info then
            local name = ""
            -- Get talent name from the first entry
            if info.entryIDs and info.entryIDs[1] then
                local entryInfo = C_Traits.GetEntryInfo(configID, info.entryIDs[1])
                if entryInfo and entryInfo.definitionID then
                    local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    if defInfo then
                        name = defInfo.overrideName or (defInfo.spellID and U.GetSpellInfo(defInfo.spellID)) or ""
                    end
                end
            end

            -- Get prerequisites (only those also in our selected set)
            local prereqs = {}
            if info.visibleEdges then
                for _, edge in ipairs(info.visibleEdges) do
                    if edge.targetNode and selectedSet[edge.targetNode] then
                        -- Note: edges point FROM prereq TO this node
                    end
                end
            end
            -- Check incoming edges via the node's prerequisiteIDs
            if info.prerequisiteIDs then
                for _, prereqID in ipairs(info.prerequisiteIDs) do
                    if selectedSet[prereqID] then
                        table.insert(prereqs, prereqID)
                    end
                end
            end

            nodeInfo[nodeID] = {
                name = name,
                prereqs = prereqs,
                depth = 0,
                row = info.posY or 0,  -- tree row position (higher = deeper in tree)
            }
        end
    end

    -- Step 4: Calculate depth for each node (max depth of any prereq + 1)
    local function CalcDepth(nID, visited)
        if visited[nID] then return nodeInfo[nID] and nodeInfo[nID].depth or 0 end
        visited[nID] = true
        local ni = nodeInfo[nID]
        if not ni then return 0 end
        local maxPrereqDepth = 0
        for _, pID in ipairs(ni.prereqs) do
            local pd = CalcDepth(pID, visited)
            if pd >= maxPrereqDepth then maxPrereqDepth = pd + 1 end
        end
        ni.depth = math.max(ni.depth, maxPrereqDepth)
        return ni.depth
    end

    local visited = {}
    for nodeID in pairs(nodeInfo) do
        CalcDepth(nodeID, visited)
    end

    -- Step 5: Sort nodes by depth (shallowest first), then by row position
    local sorted = {}
    for nodeID, info in pairs(nodeInfo) do
        if info.name and info.name ~= "" then
            table.insert(sorted, { nodeID = nodeID, name = info.name, depth = info.depth, row = info.row })
        end
    end
    table.sort(sorted, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        return a.row < b.row
    end)

    -- Step 6: Map to levels. WoW grants talent points at: 10, 11, 12, ... up to max.
    -- Each spec has slightly different point counts but ~60-70 total points.
    local levelPath = {}
    local startLevel = 10
    for i, node in ipairs(sorted) do
        local level = startLevel + (i - 1)
        levelPath[level] = node.name
    end

    return levelPath
end

--- Convenience: generate and cache the leveling path for the player's current spec.
--- Stores result in TA.charDB.computedLevelPaths[specID].
function TA.TalentsAPI.ComputeAndCacheLevelPath()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = GetSpecializationInfo(specIndex)
    if not specID then return nil end

    -- Get the endgame build string for this spec
    local T = TA.Data and TA.Data.Talents
    local specData = T and T:GetBySpecID(specID)
    if not specData or not specData.builds then return nil end

    -- Prefer mplus build (most popular), fallback to raid, then solo
    local buildStr = (specData.builds.mplus and specData.builds.mplus.string)
                  or (specData.builds.raid and specData.builds.raid.string)
                  or (specData.builds.solo and specData.builds.solo.string)
    if not buildStr or buildStr == "" then return nil end

    local path = TA.TalentsAPI.GenerateLevelingPath(buildStr)
    if path then
        TA.charDB.computedLevelPaths = TA.charDB.computedLevelPaths or {}
        TA.charDB.computedLevelPaths[specID] = path
        local count = 0
        for _ in pairs(path) do count = count + 1 end
        print(string.format("|cFF4AFF7A[ToonAge]|r Generated leveling path for spec %d (%d talents).", specID, count))
    end
    return path
end
