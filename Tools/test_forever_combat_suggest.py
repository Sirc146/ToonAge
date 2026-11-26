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

        -- Regression: C_UnitAuras returns applications = 0 for non-stacking buffs
        -- (Frost Armor, Arcane Intellect, etc.). IndexAuras must treat them as active,
        -- while keeping positive stack counts (Winter's Chill = 5) intact.
        local indexedZero = M.IndexAuras({
            { name = "Frost Armor", applications = 0 },
            { name = "Arcane Intellect", applications = 0 },
            { name = "Winter's Chill", applications = 5 },
        })
        local aoeArcaneZeroApps = M.Suggest({
            class = "MAGE", spec = "Arcane", mode = "aoe",
            known = mageKnown, cooldown = wcd(), mana = "ok", melee = false,
            buffs = indexedZero,
        }, SPELLS)
        AOE_ARCANE_ZERO_APPS = aoeArcaneZeroApps and aoeArcaneZeroApps.name or ""
        INDEXED_STACKS = indexedZero and indexedZero["Winter's Chill"] or 0
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
    check("Non-stacking buffs with applications=0 (Frost Armor + Arcane Intellect) are recognized as active",
          lua.eval("AOE_ARCANE_ZERO_APPS"), "Arcane Explosion")
    check("Stacking auras retain exact stack count in IndexAuras", lua.eval("INDEXED_STACKS"), 5)

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
        local activeClass = "MAGE"
        local paintedLabel = ""
        local paintedBadge = ""

        ToonAge.Compat = {
            InCombat = function() return inCombat end,
            UnitClass = function() return activeClass, activeClass end,
            SpellLearned = function(id) return (id == 116 or id == 6673) and "yes" or "no" end,
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
            label = { SetText = function(_, t) paintedLabel = t end },
            badge = { SetText = function(_, t) paintedBadge = t end, SetTextColor = function() end },
            specular = { SetColorTexture = function() end },
        }

        -- Option A: HUD defaults to opt-in OFF until player turns it on
        ENABLED_DEFAULT = M:IsEnabled()
        M:SetEnabled(true)
        ENABLED_ON = M:IsEnabled()
        SHOWN_WHEN_ON = shown

        M:ToggleEnabled()
        ENABLED_OFF = M:IsEnabled()
        SHOWN_WHEN_OFF = shown

        M.SlashCommands.hud(M, "on")
        SLASH_ON = M:IsEnabled()

        M.SlashCommands.hud(M, "lock")
        LOCKED_AFTER = M:Locked()
        MOVABLE_AFTER = movable

        M.SlashCommands.hud(M, "aoe")
        MODE_AOE = M:GetMode()

        -- Option A In-Combat: uses Blizzard C_AssistedCombat via Compat.AssistedNextSpell for ALL classes
        activeClass = "WARRIOR"
        inCombat = true
        local assistedReturn = 78
        ToonAge.Compat.AssistedNextSpell = function() return assistedReturn end
        C_Spell = { GetSpellName = function(id) return id == 78 and "Heroic Strike" or nil end }
        M:Refresh()
        ASSISTED_WAR_LABEL = paintedLabel
        ASSISTED_WAR_BADGE = paintedBadge
        ASSISTED_WAR_SRC = M._frame.suggestion and M._frame.suggestion.source or ""

        -- Secret return from C_AssistedCombat fails closed cleanly (nil suggestion, no error)
        issecretvalue = function(v) return v == 999 end
        assistedReturn = 999
        M:Refresh()
        ASSISTED_SECRET_NIL = (M._frame.suggestion == nil)
        issecretvalue = nil
        ToonAge.Compat.AssistedNextSpell = nil
        C_Spell = nil
        activeClass = "MAGE"

        -- Combat deferral: hiding during combat must NOT call frame:Hide() immediately
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

    check("Option A: HUD defaults to opt-in OFF", lua.eval("ENABLED_DEFAULT"), False)
    check("SetEnabled(true) turns HUD on", lua.eval("ENABLED_ON"), True)
    check("HUD frame shows when enabled out of combat", lua.eval("SHOWN_WHEN_ON"), True)
    check("ToggleEnabled turns HUD off", lua.eval("ENABLED_OFF"), False)
    check("HUD frame hides when disabled out of combat", lua.eval("SHOWN_WHEN_OFF"), False)
    check("/ta hud on re-enables HUD", lua.eval("SLASH_ON"), True)
    check("/ta hud lock locks the HUD", lua.eval("LOCKED_AFTER"), True)
    check("Locked HUD sets frame movable=false", lua.eval("MOVABLE_AFTER"), False)
    check("/ta hud aoe sets mode to aoe", lua.eval("MODE_AOE"), "aoe")
    check("Option A in-combat Warrior reads C_AssistedCombat spell", lua.eval("ASSISTED_WAR_LABEL"), "Heroic Strike")
    check("Option A in-combat badge says Assisted", lua.eval("ASSISTED_WAR_BADGE"), "Assisted")
    check("Option A in-combat suggestion tags source=assisted", lua.eval("ASSISTED_WAR_SRC"), "assisted")
    check("Option A secret C_AssistedCombat return fails closed to nil", lua.eval("ASSISTED_SECRET_NIL"), True)
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

    # 6. Forever RareGearQuests + Gear <-> Professions <-> Reputation sourcing (REAL data!)
    lua.execute(read("Data/Forever/RareGearQuests.lua"))
    lua.execute(read("Data/Forever/FactionRewards.lua"))
    lua.execute(read("Data/Forever/Enchants.lua"))
    lua.execute(r"""
        ToonAge.Utils = ToonAge.Utils or {}
        ToonAge.Compat = ToonAge.Compat or {}
    """)
    lua.execute(read("Modules/Forever/Gear.lua"))
    lua.execute(r"""
        local FG = ToonAge.modules.ForeverGear
        local function hasName(list, target)
            for _, q in ipairs(list) do
                if q.name == target then return true end
            end
            return false
        end

        -- Horde Lv 19 Mage: sees Arugal Must Die, Greater Friend of the Library, Blackfathom Villainy;
        -- NEVER sees Alliance-only Old Ironforge Incursion or Malignant Root, nor Rogue-only Horn of Xelthos.
        local hm19 = FG.GetRareGearQuests(19, "Horde", "MAGE", function() return false end)
        HM19_ARUGAL = hasName(hm19, "Arugal Must Die")
        HM19_LIB    = hasName(hm19, "Greater Friend of the Library (20 Books)")
        HM19_BFD    = hasName(hm19, "Blackfathom Villainy")
        HM19_NO_ALLI = (not hasName(hm19, "Old Ironforge Incursion")) and (not hasName(hm19, "Malignant Root (Rare Mob Turn-In)"))
        HM19_VERIFIED_FIRST = (hm19[1] and hm19[1].verified == true) or false

        -- Auto-hides Arugal Must Die (questID 1014) once flagged completed
        local hm19Done = FG.GetRareGearQuests(19, "Horde", "MAGE", function(id) return id == 1014 end)
        HM19_ARUGAL_HIDDEN = not hasName(hm19Done, "Arugal Must Die")

        -- Horde Lv 27 Warrior: sees Arugal Must Die, Elder Knowledge, Brutal Armor; does NOT see Mage-only BFD wand
        local hw27 = FG.GetRareGearQuests(27, "Horde", "WARRIOR", function() return false end)
        HW27_BRUTAL = hasName(hw27, "Brutal Armor (Warrior Class)")
        HW27_ELDER  = hasName(hw27, "Elder Knowledge / Lost Relic Carry")
        HW27_NO_BFD = not hasName(hw27, "Blackfathom Villainy")

        -- Alliance Lv 16 Hunter: sees Old Ironforge Incursion; NEVER sees Horde-only Arugal Must Die
        local ah16 = FG.GetRareGearQuests(16, "Alliance", "HUNTER", function() return false end)
        AH16_IRONFORGE = hasName(ah16, "Old Ironforge Incursion")
        AH16_NO_ARUGAL = not hasName(ah16, "Arugal Must Die")

        local facHorde = FG.GetFactionUpgradeSources("Horde", 2)
        FAC_HORDE_CNT = #facHorde
        FAC_HORDE_FIRST = facHorde[1] and facHorde[1].name or ""
    """)
    check("Horde Lv 19 Mage sees Arugal Must Die", lua.eval("HM19_ARUGAL"), True)
    check("Horde Lv 19 Mage sees Greater Friend of the Library", lua.eval("HM19_LIB"), True)
    check("Horde Lv 19 Mage sees Blackfathom Villainy (Gravestone Scepter)", lua.eval("HM19_BFD"), True)
    check("Horde Lv 19 Mage never sees Alliance-only rare quests", lua.eval("HM19_NO_ALLI"), True)
    check("RareGearQuests sorts verified Rare quests ahead of unverified", lua.eval("HM19_VERIFIED_FIRST"), True)
    check("RareGearQuests auto-hides completed questID 1014 (Arugal Must Die)", lua.eval("HM19_ARUGAL_HIDDEN"), True)
    check("Horde Lv 27 Warrior sees Brutal Armor class chain", lua.eval("HW27_BRUTAL"), True)
    check("Horde Lv 27 Warrior sees Elder Knowledge (Heavehammer)", lua.eval("HW27_ELDER"), True)
    check("Horde Lv 27 Warrior skips caster-only Blackfathom Villainy", lua.eval("HW27_NO_BFD"), True)
    check("Alliance Lv 16 Hunter sees Old Ironforge Incursion", lua.eval("AH16_IRONFORGE"), True)
    check("Alliance Lv 16 Hunter never sees Horde-only Arugal Must Die", lua.eval("AH16_NO_ARUGAL"), True)
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
