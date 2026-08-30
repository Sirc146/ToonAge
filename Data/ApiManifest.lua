-- ToonAge/Data/ApiManifest.lua (Anniversary — TBC Classic / Interface 20506)
-- Every API this build calls. Core/ApiGuard.lua resolves each one against the
-- running client at login and reports what is missing via /ta apiprobe.
--
-- This exists because the failure mode that hurts is not a crash. It is an API
-- that quietly is not there, sitting behind an existence check, returning nil
-- forever while the addon looks like it is working. The manifest turns that into
-- a line of output on the first login instead of a wrong number six weeks later.
--
-- Nothing here has been confirmed by a live dump on 20506 yet. The probe IS the
-- confirmation — run /ta apiprobe after the first login and anything listed as
-- missing is a real gap to fix, not a false alarm.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.ApiManifest = {
    namespaced = {
        -- The only C_ namespace this build depends on. TBC has C_Timer.
        ["C_Timer.After"] = { "Core/Init.lua", "Core/Utils.lua" },
    },
    globals = {
        -- ── Combat ratings and caps (Core/TBCStats.lua) ──────────────
        ["GetCombatRating"]        = { "Core/TBCStats.lua" },
        ["GetCombatRatingBonus"]   = { "Core/TBCStats.lua" },
        ["GetExpertise"]           = { "Core/TBCStats.lua" },
        ["UnitDefense"]            = { "Core/TBCStats.lua" },
        ["UnitArmor"]              = { "Core/TBCStats.lua", "Modules/Character/Character.lua" },

        -- ── Character sheet (Modules/Character/Character.lua) ────────
        ["UnitStat"]               = { "Modules/Character/Character.lua" },
        ["UnitAttackPower"]        = { "Modules/Character/Character.lua" },
        ["UnitRangedAttackPower"]  = { "Modules/Character/Character.lua" },
        ["UnitResistance"]         = { "Modules/Character/Character.lua" },
        ["GetCritChance"]          = { "Modules/Character/Character.lua" },
        ["GetRangedCritChance"]    = { "Modules/Character/Character.lua" },
        ["GetSpellCritChance"]     = { "Modules/Character/Character.lua" },
        ["GetDodgeChance"]         = { "Modules/Character/Character.lua" },
        ["GetParryChance"]         = { "Modules/Character/Character.lua" },
        ["GetBlockChance"]         = { "Modules/Character/Character.lua" },
        ["GetSpellBonusDamage"]    = { "Modules/Character/Character.lua" },
        ["GetSpellBonusHealing"]   = { "Modules/Character/Character.lua" },
        ["GetManaRegen"]           = { "Modules/Character/Character.lua" },

        -- ── Talents: TBC's only spec signal (Core/Utils.lua) ─────────
        ["GetNumTalentTabs"]       = { "Core/Utils.lua", "Data/TBCTalentHit.lua" },
        ["GetTalentTabInfo"]       = { "Core/Utils.lua" },
        -- Needed to read individual talent ranks, which is how hit granted by
        -- Precision / Suppression / Elemental Precision is found. Without these
        -- the Stat Caps targets are too high for every spec with a hit talent.
        ["GetNumTalents"]          = { "Data/TBCTalentHit.lua" },
        ["GetTalentInfo"]          = { "Data/TBCTalentHit.lua" },

        -- ── Skills: weapon skill and professions (Core/SkillScan.lua) ─
        ["GetNumSkillLines"]       = { "Core/SkillScan.lua" },
        ["GetSkillLineInfo"]       = { "Core/SkillScan.lua" },
        ["ExpandSkillHeader"]      = { "Core/SkillScan.lua" },
        ["CollapseSkillHeader"]    = { "Core/SkillScan.lua" },
        ["UnitAttackBothHands"]    = { "Core/SkillScan.lua" },

        -- ── Items and gear (Modules/Gear/Gear.lua) ───────────────────
        ["GetItemInfo"]            = { "Core/Utils.lua", "Modules/Gear/Gear.lua" },
        ["GetItemStats"]           = { "Modules/Gear/Gear.lua" },
        ["GetInventoryItemLink"]   = { "Core/Utils.lua", "Modules/Gear/Gear.lua" },
        ["GetContainerNumSlots"]   = { "Core/Utils.lua" },
        ["GetContainerItemLink"]   = { "Core/Utils.lua" },

        -- ── PvP (Modules/PvP/PvPAdvisor.lua) ─────────────────────────
        -- None of these is confirmed on 20506. The tab degrades to reference
        -- text when they are absent rather than showing zeros as if measured.
        ["GetNumArenaTeams"]       = { "Modules/PvP/PvPAdvisor.lua" },
        ["GetArenaTeam"]           = { "Modules/PvP/PvPAdvisor.lua" },

        -- ── Identity and misc ────────────────────────────────────────
        ["UnitRace"]               = { "Core/Utils.lua" },
        ["UnitClass"]              = { "Core/Utils.lua" },
        ["UnitLevel"]              = { "Core/Utils.lua" },
        ["UnitHealthMax"]          = { "Modules/Character/Character.lua" },
        ["GetRealmName"]           = { "Core/Init.lua" },
        ["geterrorhandler"]        = { "Modules/Infrastructure/ErrorLog.lua" },
        ["seterrorhandler"]        = { "Modules/Infrastructure/ErrorLog.lua" },
    },
}
