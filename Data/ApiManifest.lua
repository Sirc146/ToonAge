-- ToonAge/Data/ApiManifest.lua (Anniversary — TBC Classic / Interface 20506)
-- APIs probed at load by Core/ApiGuard.lua, which only resolves each path
-- against the running client's globals/namespaces — it never checks whether
-- the file listed in the second column actually exists in this build, so
-- none of the inaccuracy documented below has ever produced a wrong runtime
-- result; it only made the "which file uses this" column of /ta apiprobe
-- unreliable.
--
-- Corrected 2026-09-06, in two passes:
--   1. This file previously claimed a "Cataclysm Classic (40402)" target,
--      then briefly "Mists of Pandaria Classic (50504)". Both were wrong —
--      the live device TOC (ToonAge.toc, ## Interface: 20506) confirms this
--      addon is actually TBC Classic Anniversary. Neither Cata nor MoP ever
--      applied here.
--   2. Nearly every entry below named files that do not exist anywhere in
--      this build (Modules/Arrow.lua, GatherTracker.lua, XPTracker.lua,
--      QuestTracker.lua, GuideImporter.lua, GuideBrowser.lua,
--      GuideContextMenu.lua, MapPins.lua, CoordResolver.lua, AntTrail.lua,
--      NavHud.lua, DeathRecovery.lua, DevHelpers.lua, RestOptimizer.lua,
--      AutoMount.lua, CutsceneSkip.lua, Data/Spells.lua, and flat paths
--      like Modules/Gear.lua / Modules/ErrorLog.lua from before the
--      Character/Gear/PvP/Infrastructure subfolders existed). This build is
--      advisory-only per the TOC (Core/*, Data/TBC*.lua, Modules/
--      Infrastructure/ErrorLog.lua, Modules/Character/*, Modules/Gear/
--      Gear.lua, Modules/PvP/PvPAdvisor.lua — nothing else); the manifest
--      had been carried over wholesale from a different, larger guide/
--      leveling addon and never re-derived from this build's own files.
--      Rebuilt below by grepping this build's actual Core/, Data/, and
--      Modules/ tree for every API call site — every file listed under an
--      entry is a real, confirmed call in this build, not a guess. Entries
--      with no confirmed caller left in this build were dropped rather than
--      kept as dead rows (UnitXP/UnitXPMax/GetXPExhaustion/IsResting,
--      GetPlayerFacing, hooksecurefunc, EquipItemByName, GetMaxPlayerLevel,
--      GetInstanceInfo, GetItemInfoInstant, and most of the C_QuestLog/
--      C_SuperTrack/C_GossipInfo/C_MountJournal/C_FriendList/C_CurrencyInfo
--      namespace — this build has no quest tracker, mount, friend-list, or
--      currency module of any kind).

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ApiManifest = {
    namespaced = {
        -- C_Map: only GetBestMapForUnit is actually called, inside
        -- U.GetCurrentMapID (guarded — TBC 20506 may not resolve it).
        ["C_Map.GetBestMapForUnit"] = { "Core/Utils.lua" },

        -- C_Timer.After: both call sites are guarded fallbacks/delays, not a
        -- load-bearing dependency.
        ["C_Timer.After"] = { "Core/Init.lua", "Core/Utils.lua" },
    },
    globals = {
        ["GetContainerItemLink"] = { "Core/Utils.lua", "Modules/Gear/Gear.lua" },
        ["GetContainerNumSlots"] = { "Core/Utils.lua", "Modules/Gear/Gear.lua" },
        ["GetContainerItemInfo"] = { "Core/Utils.lua" },
        ["GetInventoryItemLink"] = { "Core/Utils.lua", "Modules/Gear/Gear.lua", "Modules/PvP/PvPAdvisor.lua", "Core/SkillScan.lua" },
        ["GetInventoryItemID"]   = { "Core/Utils.lua" },
        ["GetItemInfo"] = { "Core/Utils.lua", "Modules/Gear/Gear.lua", "Modules/PvP/PvPAdvisor.lua", "Core/SkillScan.lua" },
        ["GetSpellInfo"]     = { "Core/Utils.lua" },
        ["GetSpellCooldown"] = { "Core/Utils.lua" },
        -- Added 2026-09-07 for U.ScanSpellbook/ScanActionBarRanks/
        -- FindMissingSpellRanks (Core/Utils.lua) — the "spellbook has a
        -- spell/rank not on your action bars" check, Modules/Character/Spells.lua.
        ["GetNumSpellTabs"]       = { "Core/Utils.lua" },
        ["GetSpellTabInfo"]       = { "Core/Utils.lua" },
        ["GetSpellBookItemName"]  = { "Core/Utils.lua" },
        ["IsPassiveSpell"]        = { "Core/Utils.lua" },
        ["GetActionInfo"]         = { "Core/Utils.lua" },
        ["IsSpellKnown"]     = { "Core/Utils.lua" },

        -- MoP-only API (introduced 5.0.4). Does not exist on TBC (20506),
        -- this build's real target. Only Core/Utils.lua's U.GetPlayerSpec/
        -- U.GetPlayerRole call these, and both are dead stubs on this
        -- client — see the corrected comment above them in Core/Utils.lua.
        -- Confirmed unused by every TBC-native module in this build.
        ["GetSpecialization"]     = { "Core/Utils.lua" },
        ["GetSpecializationInfo"] = { "Core/Utils.lua" },

        -- Also does not exist on TBC — arrived in patch 3.0 per Core/
        -- SkillScan.lua's own header comment. U.GetProfessions/
        -- U.GetProfessionInfo (Core/Utils.lua) are dead stubs for the same
        -- reason GetSpecialization is above; the real profession read path
        -- is Core/SkillScan.lua's own Scan:GetProfessions() method (an
        -- addon-defined function, not this Blizzard API), which scans the
        -- skill list instead and is what Modules/Character/
        -- ProfessionAdvisor.lua actually calls.
        ["GetProfessions"]     = { "Core/Utils.lua" },
        ["GetProfessionInfo"]  = { "Core/Utils.lua" },

        -- Guarded fallback in U.GetAverageIlvl; TBC likely does not resolve
        -- this either, in which case Utils.lua computes it manually instead.
        ["GetAverageItemLevel"] = { "Core/Utils.lua" },

        ["GetCombatRating"]       = { "Core/TBCStats.lua" },
        ["GetCombatRatingBonus"]  = { "Core/TBCStats.lua" },

        ["IsInInstance"] = { "Core/Utils.lua" },
        ["UnitLevel"]    = { "Core/Utils.lua" },
        ["UnitClass"]    = { "Core/Utils.lua" },
        ["UnitRace"]     = { "Core/Utils.lua" },

        -- Added 2026-09-07 alongside the GetSpecLabel fix (see Core/Utils.lua)
        -- — real vanilla/TBC-era API, unrelated to the dead MoP
        -- GetSpecialization() stubs above.
        ["GetNumTalentTabs"] = { "Core/Utils.lua" },
        ["GetTalentTabInfo"] = { "Core/Utils.lua" },

        ["geterrorhandler"] = { "Modules/Infrastructure/ErrorLog.lua" },
        ["seterrorhandler"] = { "Modules/Infrastructure/ErrorLog.lua" },
    },
}
