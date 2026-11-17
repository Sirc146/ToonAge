-- Tools/fixtures/api/tbc.lua
-- Closed API list for the TBC boot test.
--
-- This is the surface Tools/test_tbc_boot.py used to install by hand:
-- WOW_PROJECT_ID 5, GetBuildInfo 2.5.6 / 00000 / date / 20506, and the classic
-- globals that prelude defined. There is no in-game probe behind it. Every
-- row is source=wiki, build 00000 (the prelude's build string), UNVERIFIED.
--
-- Names that are not listed stay nil, including Retail C_* namespaces.
-- enforce_events is false: that prelude's frame mock accepted every
-- RegisterEvent, and the boot test depends on that.
--
-- Player is the synthetic Tbctest-Tbcrealm mage from the old prelude, not a
-- real character.
return {
    id = "tbc",
    label = "TBC Anniversary stub",
    toc = "ToonAge_TBC.toc",
    interface = 20506,
    project_id = 5,
    version = "2.5.6",
    build = "00000",
    build_date = "date",
    text_font = "Fonts\\FRIZQT__.TTF",
    enforce_events = false,

    player = {
        name = "Tbctest", realm = "Tbcrealm", level = 65,
        class = "Mage", class_file = "MAGE", race = "Gnome", race_file = "Gnome",
    },
    apis = {
        ["C_Timer.After"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["C_Timer.NewTicker"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["CreateFrame"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetActionInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetAddOnInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetBlockChance"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetBuildInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetCombatRating"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetCombatRatingBonus"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetContainerItemID"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetContainerItemInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetContainerItemLink"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetContainerNumSlots"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetDodgeChance"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetExpertise"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetInventoryItemLink"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetInventoryItemsForSlot"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetItemInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetNumShapeshiftForms"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetNumSpellTabs"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetNumTalentTabs"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetParryChance"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetRealmName"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetShapeshiftFormInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellBonusDamage"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellBookItemInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellBookItemName"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellCritChance"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetSpellTabInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetTalentInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetTalentTabInfo"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["GetTime"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["InCombatLockdown"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["IsAddOnLoaded"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["IsPassiveSpell"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["STANDARD_TEXT_FONT"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "string" },
        ["UIParent"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "frame" },
        ["UnitClass"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["UnitLevel"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["UnitName"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["UnitRace"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["WOW_PROJECT_ID"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "number" },
        ["date"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["debugstack"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["geterrorhandler"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["hooksecurefunc"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["seterrorhandler"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
        ["time"] = { status = "present", source = "wiki", build = "00000", unverified = true, kind = "function" },
    },
    events = {
    },
}
