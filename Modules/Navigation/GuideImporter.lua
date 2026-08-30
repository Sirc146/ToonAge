-- ToonAge/Modules/Navigation/GuideImporter.lua
-- Dynamically discovers ALL quest chains from ALL installed BtWQuests expansion
-- modules and generates ToonAge guides. Also provides quest-log matching
-- ("which guide has this quest?"), dungeon/delve context suggestions, and
-- zone-entry auto-selection.
--
-- Covers: Classic, TBC, WotLK, Cataclysm, MoP, WoD, Legion, BfA,
--         Shadowlands, Dragonflight, The War Within, Midnight
--         (any BtWQuests module that's installed)
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U = TA.Utils

local GI = {}
TA:RegisterModule("GuideImporter", GI)

-- ── State ─────────────────────────────────────────────────────────────────────
GI.questToGuide = {} -- { [questID] = guideID } — reverse lookup for "which guide has this quest?"
GI.imported = 0

-- ── Chain walking (DAG linearization) ─────────────────────────────────────────

local function LinearizeChain(items)
    if not items or #items == 0 then
        return {}
    end
    local questIDs = {}
    local seen = {}

    for _, item in ipairs(items) do
        local questID = nil
        if item.type == "quest" and item.id then
            questID = item.id
        elseif item.variations then
            for _, var in ipairs(item.variations) do
                if var.type == "quest" and var.id then
                    questID = var.id
                    break
                end
            end
        end
        if questID and not seen[questID] then
            seen[questID] = true
            table.insert(questIDs, questID)
        end
    end
    return questIDs
end

-- ── Guide generation ──────────────────────────────────────────────────────────

local function GenerateGuide(guideID, title, zoneMapID, levelRange, questIDs)
    local steps = {}
    for _, questID in ipairs(questIDs) do
        table.insert(steps, {
            type = "pickup",
            questID = questID,
            text = "Accept quest",
            coord = { map = zoneMapID or 0, x = 0, y = 0 },
        })
        table.insert(steps, {
            type = "turnin",
            questID = questID,
            text = "Complete quest",
            coord = { map = zoneMapID or 0, x = 0, y = 0 },
        })
    end

    return {
        id = guideID,
        title = title,
        zone = zoneMapID or 0,
        minLevel = levelRange and levelRange[1] or 1,
        maxLevel = levelRange and levelRange[2] or 999,
        steps = steps,
        _imported = true,
        _source = "BtWQuests",
    }
end

-- ── Dynamic BtWQuests discovery ───────────────────────────────────────────────
-- Instead of hardcoded zone lists, we iterate BtWQuests' Database directly
-- for ALL registered chains and categorize them by their category/expansion.

-- BtWQuests expansion modules are LoadOnDemand — they must be explicitly
-- loaded before their chain data becomes available.
local BTWQUESTS_MODULES = {
    "BtWQuestsMidnight",
    "BtWQuestsTheWarWithin",
    "BtWQuestsDragonflight",
    "BtWQuestsDragonflightPrologue",
    "BtWQuestsShadowlands",
    "BtWQuestsShadowlandsPrologue",
    "BtWQuestsBattleForAzeroth",
    "BtWQuestsBattleForAzerothPrologue",
    "BtWQuestsLegion",
    "BtWQuestsWarlordsOfDraenor",
    "BtWQuestsMistsOfPandaria",
    "BtWQuestsCataclysm",
    "BtWQuestsWrathOfTheLichKing",
    "BtWQuestsTheBurningCrusade",
    "BtWQuestsClassic",
}

local function LoadBtWQuestsModules()
    local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if not LoadAddOn then
        return
    end

    for _, addonName in ipairs(BTWQUESTS_MODULES) do
        -- Check if addon exists and isn't already loaded
        local isLoaded = TA.Utils.IsAddOnLoaded(addonName)

        if not isLoaded then
            -- Check if it's available (installed but not loaded)
            local exists = false
            if C_AddOns and C_AddOns.GetAddOnInfo then
                local ok, name = pcall(C_AddOns.GetAddOnInfo, addonName)
                exists = ok and name ~= nil
            elseif GetAddOnInfo then
                local ok, name = pcall(GetAddOnInfo, addonName)
                exists = ok and name ~= nil
            end

            if exists then
                pcall(LoadAddOn, addonName)
            end
        end
    end
end

function GI:ImportAllFromBtWQuests()
    -- First, ensure BtWQuests expansion modules are loaded
    LoadBtWQuestsModules()

    if not BtWQuests or not BtWQuests.Database then
        return 0
    end

    local Database = BtWQuests.Database
    local count = 0

    -- BtWQuests.Database stores chains indexed by numeric chain ID.
    -- We can iterate using Database:GetChainIterator() or walk the internal
    -- table directly. The safest approach is to use the Categories system
    -- to discover chains per zone.

    -- Method: Iterate all categories, then all chains within each category.
    -- BtWQuests.Database:GetCategoryIterator() or :GetCategories()
    local categories = {}

    -- Try to get all categories
    if Database.GetCategories then
        categories = Database:GetCategories() or {}
    elseif Database.categories then
        categories = Database.categories
    end

    -- Fallback: iterate constants to find chain IDs
    if (not categories or not next(categories)) and BtWQuests.Constant and BtWQuests.Constant.Chain then
        -- Walk BtWQuests.Constant.Chain tree: expansion → zone → chainName = chainID
        for expansionName, zones in pairs(BtWQuests.Constant.Chain) do
            if type(zones) == "table" then
                for zoneName, chains in pairs(zones) do
                    if type(chains) == "number" then
                        -- Single flat chain ID (common for prologues: Chain.Shadowlands.PrologueAlliance = 90091)
                        local chainID = chains
                        local chainData = nil
                        if Database.GetChainByID then
                            local ok, data = pcall(Database.GetChainByID, Database, chainID)
                            if ok then
                                chainData = data
                            end
                        end
                        if not chainData and Database.chains then
                            chainData = Database.chains[chainID]
                        end

                        if chainData and chainData.items then
                            local questIDs = LinearizeChain(chainData.items)
                            if #questIDs > 0 then
                                local guideID = "btw_"
                                    .. expansionName:lower():gsub("[^%a%d]", "")
                                    .. "_"
                                    .. zoneName:lower():gsub("[^%a%d]", "")
                                if not TA.Guides[guideID] or TA.Guides[guideID]._imported then
                                    local title = expansionName .. ": " .. zoneName .. " (auto)"
                                    local levelRange = chainData.range
                                    local mapID = 0
                                    if chainData.category then
                                        local catData = Database.categories and Database.categories[chainData.category]
                                        if catData and catData.mapID then
                                            mapID = catData.mapID
                                        end
                                    end

                                    local guide = GenerateGuide(guideID, title, mapID, levelRange, questIDs)
                                    guide._chainInfo = {
                                        {
                                            name = chainData.name or zoneName,
                                            major = chainData.major or false,
                                            count = #questIDs,
                                        },
                                    }
                                    TA.Guides[guideID] = guide
                                    TA.GuideData = TA.GuideData or {}
                                    TA.GuideData[guideID] = guide
                                    for _, qid in ipairs(questIDs) do
                                        self.questToGuide[qid] = guideID
                                    end
                                    count = count + 1
                                end
                            end
                        end
                    elseif type(chains) == "table" then
                        local allQuestIDs = {}
                        local chainNames = {}

                        for chainName, chainID in pairs(chains) do
                            if type(chainID) == "number" then
                                local chainData = nil
                                -- Try Database:GetChainByID
                                if Database.GetChainByID then
                                    local ok, data = pcall(Database.GetChainByID, Database, chainID)
                                    if ok then
                                        chainData = data
                                    end
                                end
                                -- Fallback: Database.chains[chainID]
                                if not chainData and Database.chains then
                                    chainData = Database.chains[chainID]
                                end

                                if chainData and chainData.items then
                                    local questIDs = LinearizeChain(chainData.items)
                                    if #questIDs > 0 then
                                        table.insert(chainNames, {
                                            name = chainData.name or chainName,
                                            major = chainData.major or false,
                                            count = #questIDs,
                                        })
                                        for _, qid in ipairs(questIDs) do
                                            table.insert(allQuestIDs, qid)
                                        end
                                    end
                                end
                            end
                        end

                        if #allQuestIDs > 0 then
                            local guideID = "btw_"
                                .. expansionName:lower():gsub("[^%a%d]", "")
                                .. "_"
                                .. zoneName:lower():gsub("[^%a%d]", "")

                            -- Don't overwrite hand-authored guides
                            if not TA.Guides[guideID] or TA.Guides[guideID]._imported then
                                -- Try to determine mapID from chain data
                                local mapID = 0
                                for _, cn in pairs(chains) do
                                    if type(cn) == "number" then
                                        local cd = Database.chains and Database.chains[cn]
                                        if cd and cd.category then
                                            -- Category often has mapID
                                            local catData = Database.categories and Database.categories[cd.category]
                                            if catData and catData.mapID then
                                                mapID = catData.mapID
                                                break
                                            end
                                        end
                                    end
                                end

                                -- Determine level range from chain data
                                local levelRange = nil
                                for _, cn in pairs(chains) do
                                    if type(cn) == "number" then
                                        local cd = Database.chains and Database.chains[cn]
                                        if cd and cd.range then
                                            levelRange = cd.range
                                            break
                                        end
                                    end
                                end

                                local title = expansionName .. ": " .. zoneName .. " (auto)"
                                local guide = GenerateGuide(guideID, title, mapID, levelRange, allQuestIDs)
                                guide._chainInfo = chainNames

                                TA.Guides[guideID] = guide
                                TA.GuideData = TA.GuideData or {}
                                TA.GuideData[guideID] = guide

                                -- Build reverse lookup
                                for _, qid in ipairs(allQuestIDs) do
                                    self.questToGuide[qid] = guideID
                                end

                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end

    self.imported = count
    return count
end

-- ── Blizzard C_QuestLine API fallback ─────────────────────────────────────────

function GI:ImportFromQuestLineAPI()
    if not C_QuestLine or not C_QuestLine.GetAvailableQuestLines then
        return 0
    end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then
        return 0
    end

    local count = 0
    local questLines = C_QuestLine.GetAvailableQuestLines(currentMap)
    if not questLines then
        return 0
    end

    for _, qlInfo in pairs(questLines) do
        local guideID = "ql_" .. qlInfo.questLineID
        if TA.Guides[guideID] then
            break
        end -- already imported

        local quests = C_QuestLine.GetQuestLineQuests(qlInfo.questLineID)
        if quests and #quests > 0 then
            local steps = {}
            for _, questID in ipairs(quests) do
                table.insert(steps, {
                    type = "pickup",
                    questID = questID,
                    text = "Accept quest",
                    coord = { map = currentMap, x = 0, y = 0 },
                })
                table.insert(steps, {
                    type = "turnin",
                    questID = questID,
                    text = "Complete quest",
                    coord = { map = currentMap, x = 0, y = 0 },
                })
                self.questToGuide[questID] = guideID
            end

            local guide = {
                id = guideID,
                title = (qlInfo.questLineName or "Questline " .. qlInfo.questLineID) .. " (auto)",
                zone = currentMap,
                minLevel = 1,
                maxLevel = 999,
                steps = steps,
                _imported = true,
                _source = "C_QuestLine",
            }
            TA.Guides[guideID] = guide
            count = count + 1
        end
    end

    return count
end

-- ── Quest-to-Guide lookup ("which guide has this quest?") ─────────────────────

--- Find the guide that contains a specific quest ID.
--- @param questID number
--- @return string|nil guideID
function GI:FindGuideForQuest(questID)
    -- Check reverse lookup first (fast)
    if self.questToGuide[questID] then
        return self.questToGuide[questID]
    end

    -- Fallback: scan all guides
    for id, guide in pairs(TA.Guides or {}) do
        for _, step in ipairs(guide.steps) do
            if step.questID == questID then
                self.questToGuide[questID] = id
                return id
            end
        end
    end

    return nil
end

--- Suggest a guide based on the player's current quest log.
--- Returns the guide with the most matching active quests.
--- @return string|nil guideID, number matchCount
function GI:SuggestGuideFromLog()
    local activeQuests = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            activeQuests[info.questID] = true
        end
    end

    local bestID, bestCount = nil, 0
    for id, guide in pairs(TA.Guides or {}) do
        local matches = 0
        for _, step in ipairs(guide.steps) do
            if step.questID and activeQuests[step.questID] then
                matches = matches + 1
            end
        end
        if matches > bestCount then
            bestCount = matches
            bestID = id
        end
    end

    return bestID, bestCount
end

-- ── Context-aware suggestions ─────────────────────────────────────────────────

--- Called on zone change — check if there's a guide for the new zone.
function GI:SuggestForCurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    for id, guide in pairs(TA.Guides or {}) do
        if guide.zone == mapID then
            return id, guide.title
        end
    end
    return nil
end

--- Called when entering an instance — suggest a dungeon/delve guide.
function GI:SuggestForInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return nil
    end

    local instanceName = GetInstanceInfo()
    -- Look for a guide matching this instance name
    for id, guide in pairs(TA.Guides or {}) do
        if guide.title and guide.title:find(instanceName or "NOMATCH") then
            return id, guide.title
        end
    end
    return nil
end

-- ── Event handling ────────────────────────────────────────────────────────────

function GI:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        -- On zone change: check if a guide matches and offer suggestion
        local QT = TA:GetModule("QuestTracker")
        if QT and not QT.guideID then
            local guideID, title = self:SuggestForCurrentZone()
            if guideID then
                QT:SetGuide(guideID)
                TA:Raw(TA.LOG.INFO, string.format("|cFFFFD100[ToonAge]|r Auto-selected guide: |cFFFFFFFF%s|r", title))
            end
        end

        -- Also try to import questlines for the new zone
        self:ImportFromQuestLineAPI()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function GI:Init()
    -- Delay import to let BtWQuests fully initialize.
    -- BtWQuests may load its Database lazily (via ADDON_LOADED of expansion
    -- sub-modules). We try at 4s, then retry at 12s if count is low.
    C_Timer.After(4, function()
        local count = GI:ImportAllFromBtWQuests()
        if count > 0 then
            TA:Raw(
                TA.LOG.INFO,
                string.format("|cFFFFD100[ToonAge]|r Auto-imported %d zone guide(s) from BtWQuests.", count)
            )
        end

        -- Also try questline API
        local qlCount = GI:ImportFromQuestLineAPI()
        if qlCount > 0 then
            TA:Raw(
                TA.LOG.INFO,
                string.format("|cFFFFD100[ToonAge]|r Imported %d questline(s) from Blizzard API.", qlCount)
            )
        end

        -- Re-run auto-select if no guide active — BUT respect the user's saved choice.
        -- If charDB has a saved guideID that now exists (because BtWQuests just loaded),
        -- restore it instead of auto-selecting a different one.
        local QT = TA:GetModule("QuestTracker")
        if QT then
            local savedID = TA.charDB and TA.charDB.tracker and TA.charDB.tracker.guideID
            if savedID and TA.Guides[savedID] then
                -- Restore the user's saved guide (it just became available)
                if QT.guideID ~= savedID then
                    QT:SetGuide(savedID)
                end
            elseif not QT.guideID then
                QT:AutoSelectGuide()
            end
        end

        -- If BtWQuests is loaded but returned 0, retry after more time
        -- (some BtWQuests expansion modules load their data lazily)
        if count == 0 and (BtWQuests or TA.Utils.IsAddOnLoaded("BtWQuests")) then
            C_Timer.After(8, function()
                local retry = GI:ImportAllFromBtWQuests()
                if retry > 0 then
                    TA:Raw(
                        TA.LOG.INFO,
                        string.format(
                            "|cFFFFD100[ToonAge]|r Late import: %d additional guide(s) from BtWQuests.",
                            retry
                        )
                    )
                    -- Refresh browser if open
                    local GB = TA:GetModule("GuideBrowser")
                    if GB and GB.frame and GB.frame:IsShown() then
                        GB:RefreshBrowser()
                    end
                end
            end)
        end

        if TA.debug then
            TA:Raw(
                TA.LOG.INFO,
                string.format("|cFFFFD100[ToonAge]|r Total guides available: %d", U.TableLength(TA.Guides or {}))
            )
        end
    end)
end

-- ── Slash commands ────────────────────────────────────────────────────────────

GI.SlashCommands = {
    import = function(self)
        -- Show diagnostic info about BtWQuests data availability
        if BtWQuests then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r BtWQuests global: found")
            if BtWQuests.Database then
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r BtWQuests.Database: found")
            else
                TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r BtWQuests.Database: nil (not loaded yet?)")
            end
            if BtWQuests.Constant and BtWQuests.Constant.Chain then
                local expCount = 0
                for _ in pairs(BtWQuests.Constant.Chain) do
                    expCount = expCount + 1
                end
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r BtWQuests.Constant.Chain: " .. expCount .. " expansion(s)")
            else
                TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r BtWQuests.Constant.Chain: nil")
            end
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r BtWQuests not loaded. Install BtWQuests + expansion modules.")
        end

        local count = self:ImportAllFromBtWQuests()
        local qlCount = self:ImportFromQuestLineAPI()
        local total = count + qlCount
        if total > 0 then
            TA:Raw(
                TA.LOG.OUTPUT,
                string.format(
                    "|cFFFFD100[ToonAge]|r Imported %d guide(s). Total: %d. Use /ta guides to list.",
                    total,
                    U.TableLength(TA.Guides or {})
                )
            )
        else
            TA:Raw(
                TA.LOG.OUTPUT,
                "|cFFFFD100[ToonAge]|r No new guides found. Total available: " .. U.TableLength(TA.Guides or {})
            )
        end
    end,

    suggest = function(self)
        local guideID, count = self:SuggestGuideFromLog()
        if guideID then
            local guide = TA.Guides[guideID]
            TA:Raw(
                TA.LOG.OUTPUT,
                string.format(
                    "|cFFFFD100[ToonAge]|r Best guide match: |cFFFFFFFF%s|r (%d quest overlaps)",
                    guide and guide.title or guideID,
                    count
                )
            )
            -- Auto-set it
            local QT = TA:GetModule("QuestTracker")
            if QT then
                QT:SetGuide(guideID)
            end
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r No matching guide found for your current quest log.")
        end
    end,
}
