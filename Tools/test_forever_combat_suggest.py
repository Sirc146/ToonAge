#!/usr/bin/env python3
"""Phase 12 tests: Spec-aware Live Combat Suggest HUD (all 9 Forever classes)
and Spells tab / Settings HUD toggle wiring.

Usage: python Tools/test_forever_combat_suggest.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
    ToonAge = {
        modules = {},
        Data = {},
        flavor = "forever",
        db = { mageSuggest = {} },
        Utils = {},
    }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    function ToonAge:GetModule(name) return self.modules[name] end
    function ToonAge:Print(msg) self._lastPrint = msg end
    function ToonAge:QueueUIRefresh(tag) self._lastRefresh = tag end
    """)
    lua.execute(read("Data/Forever/SpellRanks.lua"))
    lua.execute(read("Data/Forever/Spells.lua"))
    lua.execute(read("Data/Forever/Talents.lua"))
    lua.execute(read("Data/Forever/RotationLists.lua"))
    lua.execute(read("Modules/Forever/MageSuggest.lua"))
    lua.execute(read("Modules/Forever/SpellPlaybook.lua"))

    # 1. Spec-aware Mage tests (Frost, Fire, Arcane, AoE)
    lua.execute(r"""
        local M = ToonAge.modules.ForeverMageSuggest
        local liveExtra = {
            ["Mage Armor"] = { 6117 },
            ["Arcane Blast"] = { 1312099 },
        }
        SPELLS = M.BuildSpells(
            ToonAge.Data.ForeverSpellRanks,
            ToonAge.Data.ForeverSpells.MAGE,
            ToonAge.Data.ForeverTalents.MAGE,
            liveExtra)

        local function kmap(ids)
            local t = {}
            for _, id in ipairs(ids) do t[id] = "yes" end
            return t
        end
        local READY = {}
        for _, row in pairs(SPELLS) do
            for _, id in ipairs(row.ids) do READY[id] = "ready" end
        end
        local function wcd(over)
            local t = {}
            for id, v in pairs(READY) do t[id] = v end
            for id, v in pairs(over or {}) do t[id] = v end
            return t
        end

        local mageKnown = kmap({
            116, 205, 133, 145, 2948, 2136, 122, 120,
            5143, 5144, 1449, 2120, 10, 5019, 168, 1459, 6117, 1312099,
        })

        -- Fire Mage: Fire Blast ready -> Fire Blast; Fire Blast down -> Fireball; both down -> Scorch
        local fire1 = M.Suggest({
            class = "MAGE", spec = "Fire", mode = "st",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Frost Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        FIRE_INSTANT = fire1 and (fire1.name .. "|" .. tostring(fire1.spec)) or ""

        local fire2 = M.Suggest({
            class = "MAGE", spec = "Fire", mode = "st",
            known = mageKnown, cooldown = wcd({ [2136] = "down" }), mana = "ok", melee = false,
            buffs = { ["Frost Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        FIRE_NUKE = fire2 and fire2.name or ""

        local fire3 = M.Suggest({
            class = "MAGE", spec = "Fire", mode = "st",
            known = mageKnown, cooldown = wcd({ [2136] = "down", [133] = "down", [145] = "down" }),
            mana = "ok", melee = false,
            buffs = { ["Frost Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        FIRE_FALLBACK = fire3 and fire3.name or ""

        -- Arcane Mage: prefers Mage Armor if missing; Clearcasting -> Arcane Missiles; otherwise Arcane Blast
        local arcArmor = M.Suggest({
            class = "MAGE", spec = "Arcane", mode = "st",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Arcane Intellect"] = true },
        }, SPELLS)
        ARCANE_ARMOR = arcArmor and arcArmor.name or ""

        local arcCC = M.Suggest({
            class = "MAGE", spec = "Arcane", mode = "st",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Mage Armor"] = true, ["Arcane Intellect"] = true, ["Clearcasting"] = true },
        }, SPELLS)
        ARCANE_CC = arcCC and arcCC.name or ""

        local arcMain = M.Suggest({
            class = "MAGE", spec = "Arcane", mode = "st",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Mage Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        ARCANE_MAIN = arcMain and arcMain.name or ""

        -- AoE mode: Frost -> Blizzard at range, Frost Nova in melee; Fire -> Flamestrike; Arcane -> Arcane Explosion
        local aoeFrost = M.Suggest({
            class = "MAGE", spec = "Frost", mode = "aoe",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Frost Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        AOE_FROST = aoeFrost and (aoeFrost.name .. "|" .. tostring(aoeFrost.mode)) or ""

        local aoeFire = M.Suggest({
            class = "MAGE", spec = "Fire", mode = "aoe",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Frost Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        AOE_FIRE = aoeFire and aoeFire.name or ""

        local aoeArcane = M.Suggest({
            class = "MAGE", spec = "Arcane", mode = "aoe",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = { ["Mage Armor"] = true, ["Arcane Intellect"] = true },
        }, SPELLS)
        AOE_ARCANE = aoeArcane and aoeArcane.name or ""
    """)

    check("Fire Mage suggests Fire Blast when ready", lua.eval("FIRE_INSTANT"), "Fire Blast|Fire")
    check("Fire Mage falls through to Fireball when Fire Blast is down", lua.eval("FIRE_NUKE"), "Fireball")
    check("Fire Mage falls through to Scorch when Fireball is down", lua.eval("FIRE_FALLBACK"), "Scorch")
    check("Arcane Mage prefers Mage Armor when unbuffed", lua.eval("ARCANE_ARMOR"), "Mage Armor")
    check("Arcane Mage suggests Arcane Missiles on Clearcasting", lua.eval("ARCANE_CC"), "Arcane Missiles")
    check("Arcane Mage suggests Arcane Blast when learned & ready", lua.eval("ARCANE_MAIN"), "Arcane Blast")
    check("Frost AoE suggests Blizzard at range", lua.eval("AOE_FROST"), "Blizzard|aoe")
    check("Fire AoE suggests Flamestrike at range", lua.eval("AOE_FIRE"), "Flamestrike")
    check("Arcane AoE suggests Arcane Explosion", lua.eval("AOE_ARCANE"), "Arcane Explosion")

    # 2. Multi-class Playbook suggestions (Warrior, Rogue, Priest, Hunter)
    lua.execute(r"""
        local M = ToonAge.modules.ForeverMageSuggest

        -- Warrior Arms: missing Battle Shout -> Battle Shout; buff up -> top known priority
        local wPb = M.BuildClassPlaybook("WARRIOR", "Arms", 15, "st", {
            ["Battle Shout"] = { 6673 },
            ["Rend"] = { 772 },
            ["Heroic Strike"] = { 78 },
        })
        local wKnown = { [6673] = "yes", [772] = "yes", [78] = "yes" }
        local wCd = { [6673] = "ready", [772] = "ready", [78] = "ready" }

        local wBuff = M.Suggest({
            class = "WARRIOR", spec = "Arms", mode = "st",
            known = wKnown, cooldown = wCd, buffs = {}, playbook = wPb,
        })
        WAR_BUFF = wBuff and wBuff.name or ""

        local wAttack = M.Suggest({
            class = "WARRIOR", spec = "Arms", mode = "st",
            known = wKnown, cooldown = wCd, buffs = { ["Battle Shout"] = true }, playbook = wPb,
        })
        WAR_ATTACK = wAttack and (wAttack.name .. "|" .. tostring(wAttack.unverified)) or ""

        -- Rogue Assassination: skips unknown high-level spells, picks highest known rank of Sinister Strike
        local rPb = M.BuildClassPlaybook("ROGUE", "Assassination", 12, "st", {
            ["Sinister Strike"] = { 1752, 1757 },
        })
        local rRes = M.Suggest({
            class = "ROGUE", spec = "Assassination", mode = "st",
            known = { [1752] = "yes", [1757] = "yes" },
            cooldown = { [1752] = "ready", [1757] = "ready" },
            playbook = rPb,
        })
        ROGUE_PICK = rRes and (tostring(rRes.spellID) .. "|" .. rRes.name) or ""

        -- Priest low mana with Shoot -> suggests wand
        local pPb = M.BuildClassPlaybook("PRIEST", "Shadow", 14, "st", {
            ["Shoot"] = { 5019 },
            ["Smite"] = { 585 },
        })
        local pWand = M.Suggest({
            class = "PRIEST", spec = "Shadow", mode = "st",
            mana = "low",
            known = { [5019] = "yes", [585] = "yes" },
            cooldown = { [5019] = "ready", [585] = "ready" },
            playbook = pPb,
        })
        PRIEST_WAND = pWand and pWand.name or ""

        -- All 9 Forever classes resolve a valid Playbook
        ALL_NINE = 0
        for _, cls in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
            local pb = M.BuildClassPlaybook(cls, nil, 25, "st", {})
            if pb and pb.spec and #(pb.entries or {}) > 0 then
                ALL_NINE = ALL_NINE + 1
            end
        end
    """)

    check("Warrior suggests missing Battle Shout first", lua.eval("WAR_BUFF"), "Battle Shout")
    check("Warrior falls through to Arms priority and flags unverified",
          lua.eval("WAR_ATTACK") != "" and lua.eval("WAR_ATTACK").endswith("|true"), True)
    check("Rogue picks highest known rank of Sinister Strike", lua.eval("ROGUE_PICK"), "1757|Sinister Strike")
    check("Priest on low mana suggests Shoot wand", lua.eval("PRIEST_WAND"), "Shoot")
    check("All 9 Forever classes resolve non-empty Playbooks", lua.eval("ALL_NINE"), 9)

    # 3. HUD Toggle / Lock / Mode / Slash / Combat Deferral / SpellPlaybook controls
    lua.execute(r"""
        local M = ToonAge.modules.ForeverMageSuggest
        local SP = ToonAge.SpellPlaybook
        local inCombat = false
        local shown = false
        local movable = true

        ToonAge.Compat = {
            InCombat = function() return inCombat end,
            UnitClass = function() return "Mage", "MAGE" end,
            SpellLearned = function() return "no" end,
            GetSpellCooldown = function() return 0, 0 end,
        }
        M._frame = {
            IsShown = function() return shown end,
            Show = function() shown = true end,
            Hide = function() shown = false end,
            SetMovable = function(_, v) movable = v end,
            SetBackdropColor = function() end,
            SetBackdropBorderColor = function() end,
            ClearAllPoints = function() end,
            SetPoint = function() end,
            icon = { SetTexture = function() end, Show = function() end, Hide = function() end },
            label = { SetText = function() end },
            badge = { SetText = function() end, SetTextColor = function() end },
            specular = { SetColorTexture = function() end },
        }

        -- Toggle off & on via API and slash command
        ENABLED_DEFAULT = M:IsEnabled()
        M:ToggleEnabled()
        ENABLED_OFF = M:IsEnabled()
        SHOWN_WHEN_OFF = shown

        M.SlashCommands.hud(M, "on")
        ENABLED_ON = M:IsEnabled()
        SHOWN_WHEN_ON = shown

        M.SlashCommands.hud(M, "lock")
        LOCKED_AFTER = M:Locked()
        MOVABLE_AFTER = movable

        M.SlashCommands.hud(M, "aoe")
        MODE_AOE = M:GetMode()

        -- Combat deferral: hiding during combat must NOT call frame:Hide() immediately
        inCombat = true
        M:SetEnabled(false)
        STILL_SHOWN_IN_COMBAT = shown
        DEFERRED_FLAG = M._deferred == true
        inCombat = false
        M:ApplyFrame()
        HIDDEN_AFTER_COMBAT = not shown

        -- SpellPlaybook renders HUD toggle pill when ForeverMageSuggest is registered
        local capturedBtns = {}
        local fakeL = {
            C_DIM = { 0.5, 0.5, 0.5 },
            SectionHeader = function(_, _, y) return y - 20 end,
            ButtonRow = function(_, _, y, btns) capturedBtns = btns; return y - 24 end,
            DataRow = function(_, _, y) return y - 18 end,
            Paragraph = function(_, _, y) return y - 16 end,
        }
        M:SetEnabled(true)
        SP.Render({}, 0, fakeL, {}, {}, { classToken = "MAGE", level = 20 })
        HAS_HUD_BTN = false
        HAS_LOCK_BTN = false
        for _, b in ipairs(capturedBtns) do
            if b.label == "HUD: On" then HAS_HUD_BTN = true end
            if b.label == "HUD: Locked" or b.label == "HUD: Unlocked" then HAS_LOCK_BTN = true end
        end
    """)

    check("HUD defaults to enabled", lua.eval("ENABLED_DEFAULT"), True)
    check("ToggleEnabled turns HUD off", lua.eval("ENABLED_OFF"), False)
    check("HUD frame hides when disabled out of combat", lua.eval("SHOWN_WHEN_OFF"), False)
    check("/ta hud on re-enables HUD", lua.eval("ENABLED_ON"), True)
    check("HUD frame shows when enabled out of combat", lua.eval("SHOWN_WHEN_ON"), True)
    check("/ta hud lock locks the HUD", lua.eval("LOCKED_AFTER"), True)
    check("Locked HUD sets frame movable=false", lua.eval("MOVABLE_AFTER"), False)
    check("/ta hud aoe sets mode to aoe", lua.eval("MODE_AOE"), "aoe")
    check("Disabling HUD in combat defers frame:Hide()", lua.eval("STILL_SHOWN_IN_COMBAT"), True)
    check("Combat deferral sets _deferred flag", lua.eval("DEFERRED_FLAG"), True)
    check("Leaving combat applies deferred Hide()", lua.eval("HIDDEN_AFTER_COMBAT"), True)
    check("Spells tab Playbook exposes HUD: On toggle pill", lua.eval("HAS_HUD_BTN"), True)
    check("Spells tab Playbook exposes HUD lock pill when active", lua.eval("HAS_LOCK_BTN"), True)

    # 4. Settings wiring check
    settings_src = read("Modules/Infrastructure/Settings.lua")
    check("Settings exposes Show Combat Suggest HUD toggle",
          "Show live Combat Suggest HUD" in settings_src, True)
    check("Settings exposes Lock Combat Suggest HUD toggle",
          "Lock the Combat Suggest HUD position" in settings_src, True)

    # 5. Journey.lua secret-string guard regression test (caught by live /ta test)
    lua.execute(read("Modules/Forever/Journey.lua"))
    lua.execute(r"""
        local J = ToonAge.Journey
        issecretvalue = function(v) return v == "SECRET_CHAT" end
        canaccessvalue = function(v) return v ~= "LOCKED_CHAT" end
        local okSys = pcall(function() J:OnXPMessage("CHAT_MSG_SYSTEM", "SECRET_CHAT") end)
        local okGain = pcall(function() J:OnXPMessage("CHAT_MSG_COMBAT_XP_GAIN", "LOCKED_CHAT") end)
        local okLoot = pcall(function() J:OnLoot("SECRET_CHAT") end)
        local parsedSecret = J.ParseXP("SECRET_CHAT")
        issecretvalue = nil
        canaccessvalue = nil
        JOURNEY_SAFE = okSys and okGain and okLoot and (parsedSecret == nil)
    """)
    check("ForeverJourney ignores secret/locked chat strings without throwing",
          lua.eval("JOURNEY_SAFE"), True)

    # 6. Forever RareGearQuests + Gear <-> Professions <-> Reputation sourcing
    lua.execute(read("Data/Forever/RareGearQuests.lua"))
    lua.execute(read("Data/Forever/FactionRewards.lua"))
    lua.execute(read("Data/Forever/Enchants.lua"))
    lua.execute(r"""
        -- Minimal stub to test ForeverGear sourcing helpers
        ToonAge.Utils = ToonAge.Utils or {}
        ToonAge.Compat = ToonAge.Compat or {}
        ToonAge.Data.ForeverRareGearQuests.quests = {
            {
                questID = 90001, name = "Sample Horde Rare Quest", zone = "The Barrens",
                giver = "Rare Mob", side = "Horde", minLevel = 15, maxLevel = 25,
                classes = { MAGE = true }, slot = "Weapon", reward = "Sample Staff",
                howToStart = "Drops from Rare Mob in The Barrens", verified = true,
            },
            {
                questID = 90002, name = "Sample Alliance Quest", zone = "Westfall",
                giver = "NPC", side = "Alliance", minLevel = 15, maxLevel = 25,
                slot = "Ring", reward = "Sample Band", verified = true,
            },
        }
    """)
    lua.execute(read("Modules/Forever/Gear.lua"))
    lua.execute(r"""
        local FG = ToonAge.modules.ForeverGear
        local hQuests = FG.GetRareGearQuests(19, "Horde", "MAGE", function(id) return false end)
        RARE_HORDE_CNT = #hQuests
        local hDone = FG.GetRareGearQuests(19, "Horde", "MAGE", function(id) return id == 90001 end)
        RARE_DONE_CNT = #hDone
        local hWrongClass = FG.GetRareGearQuests(19, "Horde", "WARRIOR", function() return false end)
        RARE_WRONG_CLS = #hWrongClass
        local facHorde = FG.GetFactionUpgradeSources("Horde", 2)
        FAC_HORDE_CNT = #facHorde
        FAC_HORDE_FIRST = facHorde[1] and facHorde[1].name or ""
    """)
    check("RareGearQuests filters by Horde + level + class", lua.eval("RARE_HORDE_CNT"), 1)
    check("RareGearQuests hides already-completed quests", lua.eval("RARE_DONE_CNT"), 0)
    check("RareGearQuests filters out mismatched classes", lua.eval("RARE_WRONG_CLS"), 0)
    check("Gear surfaces Horde Faction Quartermaster sources", lua.eval("FAC_HORDE_CNT"), 2)
    check("Gear Horde Faction source leads with Darkspear Raiders",
          lua.eval("FAC_HORDE_FIRST"), "Darkspear Raiders")

    # 7. Cross-flavor Socket & Jewelcrafting / BoP gem sourcing check
    gear_src = read("Modules/Gear/Gear.lua")
    check("Shared Gear.lua defines AuditItemSockets", "local function AuditItemSockets" in gear_src, True)
    check("Shared Gear.lua explains BoP / farmed gem sourcing",
          "BoP/unique gems cannot be bought" in gear_src, True)
    check("Shared Gear.lua recognizes Jewelcrafting BoP gem cutting",
          "You have Jewelcrafting" in gear_src, True)

    # 8. Profession tier trainer reminders + Professions scroll-flash fix
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(r"""
        local PB = ToonAge.modules.ProfessionBoard
        -- Skinning capped at 150/150 (Lv 19): triggers CAPPED bad alert for Expert (225)
        local rCap = PB.TrainerReminder({ name = "Skinning" }, 150, 150, 19)
        PROF_CAP_STATUS = rCap and rCap.status or ""
        PROF_CAP_READY = rCap and rCap.readyNow or false

        -- First Aid at 50/75 (Lv 19): Journeyman (150 cap) just opened!
        local rOpen = PB.TrainerReminder({ name = "First Aid", secondary = true }, 50, 75, 19)
        PROF_OPEN_STATUS = rOpen and rOpen.status or ""
        PROF_OPEN_BADGE = rOpen and rOpen.badge or ""

        -- First Aid at 46/75: below 50, no reminder yet
        local rBelow = PB.TrainerReminder({ name = "First Aid", secondary = true }, 46, 75, 19)
        PROF_BELOW_NIL = (rBelow == nil)

        -- Tailoring at 125/150 on Lv 19: skill ready, waiting on Lv 20 for Expert
        local rLvl = PB.TrainerReminder({ name = "Tailoring" }, 125, 150, 19)
        PROF_LVL_READY = rLvl and rLvl.readyNow
        PROF_LVL_BADGE = rLvl and rLvl.badge or ""

        -- Comprehension (28/95): non-standard level-scaled cap -> nil (no false alarm)
        local rComp = PB.TrainerReminder({ name = "Comprehension", secondary = true }, 28, 95, 19)
        PROF_COMP_NIL = (rComp == nil)
    """)
    check("Capped Skinning (150/150) triggers red bad trainer alert", lua.eval("PROF_CAP_STATUS"), "bad")
    check("Capped Skinning (150/150) at Lv 19 is readyNow=true", lua.eval("PROF_CAP_READY"), True)
    check("First Aid (50/75) triggers warn Journeyman reminder", lua.eval("PROF_OPEN_STATUS"), "warn")
    check("First Aid (50/75) names Journeyman (150 cap)", "Journeyman" in lua.eval("PROF_OPEN_BADGE"), True)
    check("First Aid (46/75) does not nag before skill 50", lua.eval("PROF_BELOW_NIL"), True)
    check("Tailoring (125/150) at Lv 19 notes Lv 20 gate (readyNow=false)", lua.eval("PROF_LVL_READY"), False)
    check("Tailoring (125/150) at Lv 19 shows Expert at Lv 20 badge", lua.eval("PROF_LVL_BADGE"), "Expert at Lv 20")
    check("Comprehension (28/95) gets no false tier reminder", lua.eval("PROF_COMP_NIL"), True)

    ui_src = read("Core/UI.lua")
    check("RebuildChild preserves scroll on same-tab refresh", "if not preserveScroll then" in ui_src, True)
    check("UI_IRRELEVANT filters UNIT_AURA / UNIT_POWER_UPDATE / SPELL_UPDATE_COOLDOWN",
          "UNIT_AURA = true, UNIT_POWER_UPDATE = true, SPELL_UPDATE_COOLDOWN = true" in ui_src, True)
    check("UI Refresh skips background rebuild while typing in EditBox",
          "GetCurrentKeyBoardFocus" in ui_src, True)

    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
