-- ToonAge/Data/ApiManifest.lua (Classic)
-- APIs used by the Classic build. Core/ApiGuard.lua probes each at load.
-- Cataclysm Classic (40402) expected API availability.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ApiManifest = {
    namespaced = {
        -- C_Map (available in Cata Classic)
        ["C_Map.GetBestMapForUnit"] = { "Core/Utils.lua", "Modules/Arrow.lua", "Modules/CoordResolver.lua", "Modules/AntTrail.lua", "Modules/NavHud.lua", "Modules/GatherTracker.lua", "Modules/DeathRecovery.lua", "Modules/DevHelpers.lua" },
        ["C_Map.GetPlayerMapPosition"] = { "Modules/Arrow.lua", "Modules/CoordResolver.lua", "Modules/AntTrail.lua", "Modules/NavHud.lua", "Modules/GatherTracker.lua", "Modules/DeathRecovery.lua", "Modules/DevHelpers.lua" },
        ["C_Map.GetMapInfo"] = { "Modules/Arrow.lua", "Modules/DevHelpers.lua", "Modules/QuestTracker.lua" },

        -- C_QuestLog (mostly available in Cata Classic)
        ["C_QuestLog.GetInfo"] = { "Modules/QuestTracker.lua", "Modules/DevHelpers.lua", "Modules/GuideImporter.lua" },
        ["C_QuestLog.GetNumQuestLogEntries"] = { "Modules/QuestTracker.lua", "Modules/DevHelpers.lua", "Modules/GuideImporter.lua" },
        ["C_QuestLog.IsQuestFlaggedCompleted"] = { "Modules/QuestTracker.lua", "Modules/GuideBrowser.lua", "Modules/DevHelpers.lua" },
        ["C_QuestLog.GetQuestObjectives"] = { "Modules/QuestTracker.lua" },
        ["C_QuestLog.GetTitleForQuestID"] = { "Modules/QuestTracker.lua", "Modules/Arrow.lua", "Modules/MapPins.lua" },
        ["C_QuestLog.GetLogIndexForQuestID"] = { "Modules/QuestTracker.lua", "Modules/Arrow.lua" },
        ["C_QuestLog.IsOnQuest"] = { "Modules/CoordResolver.lua" },
        ["C_QuestLog.ReadyForTurnIn"] = { "Modules/QuestTracker.lua" },
        ["C_QuestLog.SetSelectedQuest"] = { "Modules/QuestTracker.lua" },
        ["C_QuestLog.AbandonQuest"] = { "Modules/QuestTracker.lua" },
        ["C_QuestLog.SetAbandonQuest"] = { "Modules/QuestTracker.lua" },
        ["C_QuestLog.GetMaxNumQuestsCanAccept"] = { "Modules/QuestTracker.lua" },

        -- C_SuperTrack (available in Cata Classic)
        ["C_SuperTrack.GetSuperTrackedQuestID"] = { "Modules/QuestTracker.lua", "Modules/CoordResolver.lua", "Modules/GuideContextMenu.lua" },
        ["C_SuperTrack.SetSuperTrackedQuestID"] = { "Modules/QuestTracker.lua" },

        -- C_GossipInfo (available in Cata Classic)
        ["C_GossipInfo.GetActiveQuests"] = { "Modules/QuestTracker.lua" },
        ["C_GossipInfo.GetAvailableQuests"] = { "Modules/QuestTracker.lua" },
        ["C_GossipInfo.SelectActiveQuest"] = { "Modules/QuestTracker.lua" },
        ["C_GossipInfo.SelectAvailableQuest"] = { "Modules/QuestTracker.lua" },

        -- C_Timer (available in Cata Classic)
        ["C_Timer.After"] = { "Core/Init.lua", "Core/Utils.lua", "Modules/AutoMount.lua", "Modules/CutsceneSkip.lua", "Modules/GatherTracker.lua", "Modules/Gear.lua", "Modules/GuideContextMenu.lua", "Modules/GuideImporter.lua", "Modules/NavHud.lua", "Modules/QuestTracker.lua" },
        ["C_Timer.NewTicker"] = { "Modules/NavHud.lua", "Modules/XPTracker.lua" },

        -- C_MountJournal (available in Cata Classic, partial)
        ["C_MountJournal.GetMountIDs"] = { "Modules/AutoMount.lua" },
        ["C_MountJournal.GetMountInfoByID"] = { "Modules/AutoMount.lua" },
        ["C_MountJournal.SummonByID"] = { "Modules/AutoMount.lua" },

        -- C_FriendList (available in Cata Classic)
        ["C_FriendList.IsFriend"] = { "Modules/QuestTracker.lua" },

        -- C_CurrencyInfo (available in Cata Classic)
        ["C_CurrencyInfo.GetCurrencyInfo"] = { "Modules/Gear.lua" },
    },
    globals = {
        ["GetContainerItemLink"] = { "Modules/AutoEquip.lua", "Modules/Gear.lua", "Modules/GatherTracker.lua" },
        ["GetContainerNumSlots"] = { "Modules/AutoEquip.lua", "Modules/Gear.lua", "Modules/QuestTracker.lua" },
        ["GetContainerItemInfo"] = { "Modules/Gear.lua", "Modules/QuestTracker.lua" },
        ["GetInventoryItemLink"] = { "Modules/AutoEquip.lua", "Modules/Gear.lua", "Modules/Character.lua" },
        ["GetInventoryItemID"] = { "Core/Utils.lua" },
        ["GetItemInfo"] = { "Core/Utils.lua", "Modules/AutoEquip.lua", "Modules/Gear.lua", "Modules/QuestTracker.lua", "Modules/GatherTracker.lua" },
        ["GetItemInfoInstant"] = { "Modules/Gear.lua", "Modules/GatherTracker.lua" },
        ["GetSpellInfo"] = { "Core/Utils.lua", "Data/Spells.lua" },
        ["GetSpellCooldown"] = { "Core/Utils.lua" },
        ["IsSpellKnown"] = { "Core/Utils.lua", "Data/Spells.lua" },
        ["GetSpecialization"] = { "Core/Utils.lua", "Modules/Character.lua", "Modules/Gear.lua", "Modules/GuideParser.lua", "Modules/AutoEquip.lua" },
        ["GetSpecializationInfo"] = { "Core/Utils.lua", "Modules/Character.lua", "Modules/Gear.lua", "Modules/AutoEquip.lua" },
        ["GetProfessions"] = { "Core/Utils.lua", "Modules/Gear.lua" },
        ["GetProfessionInfo"] = { "Core/Utils.lua", "Modules/Gear.lua" },
        ["GetAverageItemLevel"] = { "Core/Utils.lua", "Modules/Character.lua" },
        ["GetCombatRating"] = { "Modules/Character.lua" },
        ["GetCombatRatingBonus"] = { "Modules/Character.lua" },
        ["IsInInstance"] = { "Core/Utils.lua", "Modules/AutoMount.lua" },
        ["GetInstanceInfo"] = { "Modules/AutoMount.lua" },
        ["UnitXP"] = { "Modules/XPTracker.lua" },
        ["UnitXPMax"] = { "Modules/XPTracker.lua" },
        ["UnitLevel"] = { "Core/Utils.lua", "Modules/XPTracker.lua" },
        ["GetXPExhaustion"] = { "Modules/XPTracker.lua", "Modules/RestOptimizer.lua" },
        ["IsResting"] = { "Modules/XPTracker.lua", "Modules/RestOptimizer.lua" },
        ["GetPlayerFacing"] = { "Modules/Arrow.lua", "Modules/NavHud.lua" },
        ["hooksecurefunc"] = { "Core/Init.lua", "Modules/AntTrail.lua", "Modules/GatherTracker.lua", "Modules/Gear.lua", "Modules/GuideContextMenu.lua" },
        ["geterrorhandler"] = { "Modules/ErrorLog.lua" },
        ["seterrorhandler"] = { "Modules/ErrorLog.lua" },
        ["EquipItemByName"] = { "Modules/AutoEquip.lua" },
        ["GetMaxPlayerLevel"] = { "Modules/XPTracker.lua" },
    },
}
