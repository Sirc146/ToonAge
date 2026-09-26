-- ToonAge/Modules/GatherTracker.lua
-- Gathering Route on NavHud — records herb/ore node positions on LOOT_OPENED,
-- renders them as faded dots on the NavHud using the same bearing math.
-- Inspired by GatherMate2 + FarmHud.

local TA = ToonAge
local U  = TA.Utils

local GatherTracker = {}
TA:RegisterModule("GatherTracker", GatherTracker)

-- ── Constants ─────────────────────────────────────────────────────────────────
local MAX_NODES_PER_ZONE = 200
local MAX_VISIBLE_DOTS   = 60
local DOT_SIZE           = 6
local DOT_ALPHA_HERB     = 0.45
local DOT_ALPHA_ORE      = 0.50
local DEDUP_DISTANCE     = 0.004   -- map-unit threshold for duplicate detection
local DISPLAY_RANGE      = 0.18    -- max map-unit distance to show dots

-- Item classification: classID 7 = Tradeskill
-- subclassID: 5=Cloth, 6=Leather, 7=Metal & Stone (Ore), 8=Cooking, 9=Herb, 10=Elemental
local GATHER_SUBCLASS_HERB    = 9
local GATHER_SUBCLASS_ORE     = 7
local GATHER_SUBCLASS_LEATHER = 6   -- skinning

-- Skinning is not a node profession: the "node" is a corpse that was somewhere
-- a mob happened to die, and it is gone once looted. Recording it is still
-- worth it, because what a skinner actually wants is the same thing a herbalist
-- wants — where the density is. A month of skinned corpses in a zone is a map
-- of where the skinnable packs walk, which is exactly the route you want to run.

-- Colors
local COLOR_HERB = { 0.30, 0.90, 0.35 }  -- green
local COLOR_ORE  = { 0.85, 0.55, 0.20 }  -- brown/orange
local COLOR_SKIN = { 0.80, 0.30, 0.30 }  -- red, for skinned corpses

-- ── State ─────────────────────────────────────────────────────────────────────
GatherTracker.dotPool    = {}    -- reusable texture frames
GatherTracker.hookActive = false

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function DistSq(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

-- Calls fn only when it is really a function on this client, and swallows
-- errors from it. Older/alternate clients (Forever) are missing some of the
-- loot API, and an unguarded call there takes the whole module down.
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g
end

--- classID, subclassID for an item link, whatever this client exposes.
---
--- MEASURED 2026-09-23: on Forever, GetNumLootItems and GetLootSlotLink are
--- functions but GetItemInfoInstant is NIL. This module classified loot only
--- through GetItemInfoInstant, so Try() returned nil, classID never matched,
--- and the recorder wrote down NOTHING on this client -- silently, for its
--- entire life. That is the exact failure shape ApiGuard exists to catch, and
--- it slipped past because a call made through Try() is invisible to the
--- manifest generator.
---
--- Three routes, in order of preference. GetItemInfo's returns 12 and 13 are
--- classID and subclassID, and .rules.md records the verification that
--- C_Item.GetItemInfo mirrors the global exactly, so positional reads are safe.
local function ItemClass(link)
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID, subclassID = Try(C_Item.GetItemInfoInstant, link)
        if classID then return classID, subclassID end
    end
    if GetItemInfoInstant then
        local _, _, _, _, _, classID, subclassID = Try(GetItemInfoInstant, link)
        if classID then return classID, subclassID end
    end
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if getInfo then
        local r = { Try(getInfo, link) }
        if r[12] then return r[12], r[13] end
    end
    return nil, nil
end

local function DetectGatherType()
    -- Scan loot window for herb/ore items
    local numItems = Try(GetNumLootItems) or 0
    for i = 1, numItems do
        local link = Try(GetLootSlotLink, i)
        if link then
            local classID, subclassID = ItemClass(link)
            if classID == 7 then
                if subclassID == GATHER_SUBCLASS_HERB then return "herb" end
                if subclassID == GATHER_SUBCLASS_ORE  then return "ore" end
                -- Leather in a loot window means this corpse was skinned. Mob
                -- drops are class 15 (Miscellaneous) or armor/weapons, so a
                -- tradeskill-leather stack is a reliable tell.
                if subclassID == GATHER_SUBCLASS_LEATHER then return "skin" end
            end
        end
    end
    return nil
end

-- ── Recording nodes ───────────────────────────────────────────────────────────
function GatherTracker:RecordNode()
    local gatherType = DetectGatherType()
    if not gatherType then return end

    if type(C_Map) ~= "table" then return end

    local mapID = Try(C_Map.GetBestMapForUnit, "player")
    if not mapID then return end

    local pos = Try(C_Map.GetPlayerMapPosition, mapID, "player")
    if not pos or type(pos.GetXY) ~= "function" then return end

    local px, py = pos:GetXY()
    if not px or not py then return end
    if px == 0 and py == 0 then return end

    -- Ensure DB structure
    if not TA.charDB then return end
    TA.charDB.gatherHistory = TA.charDB.gatherHistory or {}
    TA.charDB.gatherHistory[mapID] = TA.charDB.gatherHistory[mapID] or {}

    local nodes = TA.charDB.gatherHistory[mapID]

    -- Deduplicate: don't save if a node already exists nearby.
    --
    -- Herb and ore nodes respawn in the same spot, so a second reading near an
    -- existing dot is the SAME node and should only refresh its timestamp.
    -- Skinned corpses are the opposite: each one is a separate kill, and two
    -- kills a few yards apart are two data points, not one. Deduping them at
    -- the node radius would flatten a busy camp into a single dot and hide the
    -- density that makes the map worth having. Only merge skins that land
    -- almost exactly on top of each other, which is the double-loot case.
    local radius  = (gatherType == "skin") and (DEDUP_DISTANCE * 0.15) or DEDUP_DISTANCE
    local dedupSq = radius * radius
    for _, node in ipairs(nodes) do
        if node.type == gatherType and DistSq(node.x, node.y, px, py) < dedupSq then
            -- Update timestamp of existing node
            node.time = time()
            return
        end
    end

    -- Insert new node
    table.insert(nodes, {
        x    = px,
        y    = py,
        type = gatherType,
        time = time(),
    })

    -- Cap size: remove oldest entries
    while #nodes > MAX_NODES_PER_ZONE do
        table.remove(nodes, 1)
    end

    -- Visible confirmation while testing. Silent unless /ta debug is on: this
    -- fires on every gather, and nobody wants a line per herb all evening.
    if TA.debug then
        TA:Raw(TA.LOG.OUTPUT, ("|cFF888780[TA Gather]|r recorded %s at %.1f, %.1f (%d in this zone)")
              :format(gatherType, px * 100, py * 100, #nodes))
    end
end

-- ── OnEvent ───────────────────────────────────────────────────────────────────
function GatherTracker:OnEvent(event, ...)
    if event == "LOOT_OPENED" then
        self:RecordNode()
    end
end

-- ── NavHud integration: render dots ───────────────────────────────────────────
-- Called from a hooksecurefunc on NavHud:Tick()
function GatherTracker:UpdateDotsOnNavHud()
    local NavHud = TA:GetModule("NavHud")
    if not NavHud or not NavHud.frame or not NavHud.frame:IsShown() then
        self:HideAllDots()
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then self:HideAllDots(); return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then self:HideAllDots(); return end

    local playerX, playerY = pos:GetXY()
    local bearing = GetPlayerFacing() or 0
    local hudRadius = NavHud.hudRadius or 300

    -- Get gather nodes for current zone
    local nodes = TA.charDB and TA.charDB.gatherHistory and TA.charDB.gatherHistory[mapID]
    if not nodes or #nodes == 0 then
        self:HideAllDots()
        return
    end

    local dotIdx = 0
    local rangeSq = DISPLAY_RANGE * DISPLAY_RANGE

    for _, node in ipairs(nodes) do
        local dSq = DistSq(node.x, node.y, playerX, playerY)
        if dSq < rangeSq then
            dotIdx = dotIdx + 1
            if dotIdx > MAX_VISIBLE_DOTS then break end

            local dot = self:GetDot(dotIdx, NavHud.frame)

            -- Position using NavHud's bearing math
            local dx = node.x - playerX
            local dy = node.y - playerY
            local dist = math.sqrt(dSq)
            local angle = math.atan2(dx, -dy)
            local screenAngle = angle - bearing

            local normDist = math.min(dist / DISPLAY_RANGE, 1.0)
            local hudDist  = normDist * hudRadius * 0.85

            local screenX = math.sin(screenAngle) * hudDist
            local screenY = math.cos(screenAngle) * hudDist

            dot:ClearAllPoints()
            dot:SetPoint("CENTER", NavHud.frame, "CENTER", screenX, screenY)

            -- Color by type
            if node.type == "herb" then
                dot:SetVertexColor(COLOR_HERB[1], COLOR_HERB[2], COLOR_HERB[3], DOT_ALPHA_HERB)
            elseif node.type == "skin" then
                dot:SetVertexColor(COLOR_SKIN[1], COLOR_SKIN[2], COLOR_SKIN[3], DOT_ALPHA_ORE)
            else
                dot:SetVertexColor(COLOR_ORE[1], COLOR_ORE[2], COLOR_ORE[3], DOT_ALPHA_ORE)
            end

            dot:Show()
        end
    end

    -- Hide unused dots
    for i = dotIdx + 1, #self.dotPool do
        if self.dotPool[i] then
            self.dotPool[i]:Hide()
        end
    end
end

function GatherTracker:GetDot(index, parent)
    if self.dotPool[index] then return self.dotPool[index] end

    local dot = parent:CreateTexture(nil, "ARTWORK")
    dot:SetTexture("Interface\\Buttons\\WHITE8X8")
    dot:SetSize(DOT_SIZE, DOT_SIZE)
    dot:Hide()
    self.dotPool[index] = dot
    return dot
end

function GatherTracker:HideAllDots()
    for _, dot in ipairs(self.dotPool) do
        dot:Hide()
    end
end

-- ── Hook into NavHud tick ─────────────────────────────────────────────────────
function GatherTracker:InstallNavHudHook()
    if self.hookActive then return end

    local NavHud = TA:GetModule("NavHud")
    if not NavHud then return end

    -- Use tick listener registry (consolidates 3 hooks → 1 dispatch loop)
    if NavHud.RegisterTickListener then
        NavHud:RegisterTickListener("GatherTracker", function()
            GatherTracker:UpdateDotsOnNavHud()
        end)
    else
        hooksecurefunc(NavHud, "Tick", function()
            GatherTracker:UpdateDotsOnNavHud()
        end)
    end

    self.hookActive = true
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function GatherTracker:Init()
    -- Ensure DB tables exist
    if TA.charDB then
        TA.charDB.gatherHistory = TA.charDB.gatherHistory or {}
    end

    -- Register LOOT_OPENED (not in PERSISTENT_EVENTS)
    TA:RegisterEvent("LOOT_OPENED")

    -- Install NavHud hook (may need to defer if NavHud not yet init)
    local NavHud = TA:GetModule("NavHud")
    if NavHud and NavHud.frame then
        self:InstallNavHudHook()
    else
        -- Retry after 2 seconds (NavHud defers frame creation)
        C_Timer.After(2, function()
            GatherTracker:InstallNavHudHook()
        end)
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────
GatherTracker.SlashCommands = {
    gather = function(self)
        if not TA.charDB or not TA.charDB.gatherHistory then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r No gather data recorded yet.")
            return
        end

        local totalNodes = 0
        local zoneCount  = 0
        local herbCount  = 0
        local skinCount  = 0
        local oreCount   = 0

        for mapID, nodes in pairs(TA.charDB.gatherHistory) do
            zoneCount = zoneCount + 1
            for _, node in ipairs(nodes) do
                totalNodes = totalNodes + 1
                if node.type == "skin" then skinCount = skinCount + 1
                elseif node.type == "herb" then herbCount = herbCount + 1
                else oreCount = oreCount + 1 end
            end
        end

        TA:Raw(TA.LOG.OUTPUT, string.format(
            "|cFFFFD100[ToonAge Gather]|r %d nodes across %d zones (|cFF4AFF7A%d herbs|r, |cFFFF9A1A%d ore|r, |cFFCC4A4A%d skinned|r)",
            totalNodes, zoneCount, herbCount, oreCount, skinCount))
    end,
}
