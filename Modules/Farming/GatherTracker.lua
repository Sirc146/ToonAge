-- ToonAge/Modules/GatherTracker.lua (Classic — MoP 50504)
-- Gathering Route on NavHud — records herb/ore node positions on LOOT_OPENED,
-- renders them as faded dots on the NavHud using the same bearing math.
-- Inspired by GatherMate2 + FarmHud.
--
-- Uses LOOT_OPENED, GetNumLootItems, GetLootSlotLink, GetItemInfoInstant,
-- C_Map.GetPlayerMapPosition — all available in MoP Classic.
-- ═══════════════════════════════════════════════════════════════════════════════

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
-- subclassID: 7=Metal & Stone (Ore), 9=Herb
local GATHER_SUBCLASS_HERB = 9
local GATHER_SUBCLASS_ORE  = 7

-- Colors
local COLOR_HERB = { 0.30, 0.90, 0.35 }  -- green
local COLOR_ORE  = { 0.85, 0.55, 0.20 }  -- brown/orange

-- ── State ─────────────────────────────────────────────────────────────────────
GatherTracker.dotPool    = {}
GatherTracker.hookActive = false

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function DistSq(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

local function DetectGatherType()
    local numItems = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, numItems do
        local link = GetLootSlotLink(i)
        if link then
            -- GetItemInfoInstant is available in MoP Classic
            local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(link)
            if classID == 7 then
                if subclassID == GATHER_SUBCLASS_HERB then return "herb" end
                if subclassID == GATHER_SUBCLASS_ORE  then return "ore" end
            end
        end
    end
    return nil
end

-- ── Recording nodes ───────────────────────────────────────────────────────────
function GatherTracker:RecordNode()
    local gatherType = DetectGatherType()
    if not gatherType then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end

    local px, py = pos:GetXY()
    if px == 0 and py == 0 then return end

    -- Ensure DB structure
    if not TA.charDB then return end
    TA.charDB.gatherHistory = TA.charDB.gatherHistory or {}
    TA.charDB.gatherHistory[mapID] = TA.charDB.gatherHistory[mapID] or {}

    local nodes = TA.charDB.gatherHistory[mapID]

    -- Deduplicate: don't save if a node already exists nearby
    local dedupSq = DEDUP_DISTANCE * DEDUP_DISTANCE
    for _, node in ipairs(nodes) do
        if DistSq(node.x, node.y, px, py) < dedupSq then
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
end

-- ── OnEvent ───────────────────────────────────────────────────────────────────
function GatherTracker:OnEvent(event, ...)
    if event == "LOOT_OPENED" then
        self:RecordNode()
    end
end

-- ── NavHud integration: render dots ───────────────────────────────────────────
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

            if node.type == "herb" then
                dot:SetVertexColor(COLOR_HERB[1], COLOR_HERB[2], COLOR_HERB[3], DOT_ALPHA_HERB)
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

    hooksecurefunc(NavHud, "Tick", function()
        GatherTracker:UpdateDotsOnNavHud()
    end)

    self.hookActive = true
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function GatherTracker:Init()
    if TA.charDB then
        TA.charDB.gatherHistory = TA.charDB.gatherHistory or {}
    end

    TA.eventFrame:RegisterEvent("LOOT_OPENED")

    -- Install NavHud hook (may need to defer if NavHud not yet init)
    local NavHud = TA:GetModule("NavHud")
    if NavHud and NavHud.frame then
        self:InstallNavHudHook()
    else
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
        local oreCount   = 0

        for mapID, nodes in pairs(TA.charDB.gatherHistory) do
            zoneCount = zoneCount + 1
            for _, node in ipairs(nodes) do
                totalNodes = totalNodes + 1
                if node.type == "herb" then herbCount = herbCount + 1
                else oreCount = oreCount + 1 end
            end
        end

        TA:Raw(TA.LOG.OUTPUT, string.format(
            "|cFFFFD100[ToonAge Gather]|r %d nodes across %d zones (|cFF4AFF7A%d herbs|r, |cFFFF9A1A%d ore|r)",
            totalNodes, zoneCount, herbCount, oreCount))
    end,
}
