#!/usr/bin/env python3
"""
ToonAge -- Forever Enchants & Faction Rewards Tests (Milestone 2B)
==================================================================
Verifies:
  1. Data/Forever/Enchants.lua (pure data, zero gems, Necklace/Off-Hand/Relic/
     Enchanter Ring Forever differences, all 5 roles & 9 classes, source URLs).
  2. Modules/Forever/Gear.lua (ResolveEnchantRole, GetEnchantGuide, Render
     enchant status & role guide, Lv<60 note, class-specific Relic perk).
  3. Data/Forever/FactionRewards.lua (Darkspear Raiders, Theramore Expeditionary
     Force, WSG/AB/AV, Argent Dawn, Thorium Brotherhood, Timbermaw Hold; all
     4 tiers, quartermasters, Forever URLs).
  4. Modules/Progression/FactionTracker.lua (LookupForeverFaction, NextRewardTier,
     Horde/Alliance FilterForeverFactions, tooltip enrichment, and Render).

Usage:  python Tools/test_forever_enchants_factions.py [-v]
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
    _results.append((ok, name, got, want))
    if VERBOSE or not ok:
        mark = "  ok  " if ok else " FAIL "
        print(f"[{mark}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def new_lua():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = {
            flavor = "forever",
            modules = {},
            Data = {},
            db = {},
            charDB = {},
            Utils = {
                MarkItemName = function(n) return n end,
                GearMarkForVerdict = function() return "" end,
            },
            Compat = {
                UnitClass = function() return "Mage", "MAGE" end,
            },
        }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        function ToonAge:GetModule(name) return self.modules[name] end
        function ToonAge:Print() end
        function ToonAge:QueueUIRefresh() end
        C_Timer = { After = function(_, fn) if fn then fn() end end }
        STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        function hooksecurefunc() end
    """)
    return lua


def test_enchants_data_and_gear():
    lua = new_lua()
    lua.execute(read("Data/Forever/Enchants.lua"))
    lua.execute(read("Modules/Forever/Gear.lua"))

    check("ForeverEnchants loaded", lua.eval("type(ToonAge.Data.ForeverEnchants) == 'table'"))
    check("Forever has no gem sockets", lua.eval("ToonAge.Data.ForeverEnchants.meta.noGems"), True)
    check("Enchants cites Icy Veins and Wowhead Forever",
          lua.eval("""
              (function()
                  local s = ToonAge.Data.ForeverEnchants.meta.sources
                  return s[1]:find("icy-veins.com/wow-forever/", 1, true) ~= nil
                     and s[2]:find("wowhead.com/forever/", 1, true) ~= nil
              end)()
          """))

    for role in ("caster", "healer", "melee_str", "melee_agi", "tank"):
        check(f"role '{role}' has Necklace [foreverNew]",
              lua.eval(f"""
                  (function()
                      for _, s in ipairs(ToonAge.Data.ForeverEnchants.roles.{role}.slots) do
                          if s.slotID == 2 and s.foreverNew == true then return true end
                      end
                      return false
                  end)()
              """))

    for role in ("caster", "healer"):
        check(f"role '{role}' has Off-Hand Wisdom [foreverNew]",
              lua.eval(f"""
                  (function()
                      for _, s in ipairs(ToonAge.Data.ForeverEnchants.roles.{role}.slots) do
                          if s.slotID == 17 and s.foreverNew == true and s.enchant:find("Wisdom", 1, true) then
                              return true
                          end
                      end
                      return false
                  end)()
              """))

    check("Enchanter Ring Enchants perk tagged foreverNew",
          lua.eval("ToonAge.Data.ForeverEnchants.perks.enchanterRings.foreverNew"), True)
    check("Crafted Class Relics perk tagged foreverNew",
          lua.eval("ToonAge.Data.ForeverEnchants.perks.classRelics.foreverNew"), True)

    # Role resolution across all 9 classes
    role_cases = [
        ("MAGE", "Frost", "caster"),
        ("WARLOCK", None, "caster"),
        ("PRIEST", "Shadow", "caster"),
        ("PRIEST", "Holy", "healer"),
        ("WARRIOR", "Protection", "tank"),
        ("WARRIOR", "Arms", "melee_str"),
        ("ROGUE", "Combat", "melee_agi"),
        ("HUNTER", "Marksmanship", "melee_agi"),
        ("PALADIN", "Protection", "tank"),
        ("PALADIN", "Retribution", "melee_str"),
        ("SHAMAN", "Restoration", "healer"),
        ("SHAMAN", "Enhancement", "melee_str"),
        ("DRUID", "Feral (Bear)", "tank"),
        ("DRUID", "Restoration", "healer"),
    ]
    for cls, spec, want in role_cases:
        spec_arg = f'"{spec}"' if spec else "nil"
        got = lua.eval(f'ToonAge.modules.ForeverGear.ResolveEnchantRole("{cls}", {spec_arg})')
        check(f"ResolveEnchantRole({cls}, {spec}) == {want}", got, want)

    # Render Gear tab for a Lv 12 Mage with enchanted Chest (5) and unenchanted Neck (2) + Off-Hand (17)
    lua.execute(r"""
        ROWS = {}
        HEADERS = {}
        PARAS = {}
        function UnitLevel() return 12 end
        function GetProfessions() return nil end
        function GetInventoryItemLink(_, slot)
            if slot == 2  then return "|cff1eff00|Hitem:2000:0:0:0|h[Apprentice Pendant]|h|r" end
            if slot == 5  then return "|cff1eff00|Hitem:2001:41:0:0|h[Enchanted Robe]|h|r" end
            if slot == 16 then return "|cff1eff00|Hitem:2002:0:0:0|h[Wand Staff]|h|r" end
            if slot == 17 then return "|cff1eff00|Hitem:2003:0:0:0|h[Spell Orb]|h|r" end
            return nil
        end
        function GetItemInfo(link)
            if link:find("2003") then return "Spell Orb", link, 2, 12, 10, "Armor", "Miscellaneous", 1, "INVTYPE_HOLDABLE" end
            if link:find("2002") then return "Wand Staff", link, 2, 12, 10, "Weapon", "Daggers", 1, "INVTYPE_WEAPONMAINHAND" end
            if link:find("2001") then return "Enchanted Robe", link, 2, 12, 10, "Armor", "Cloth", 1, "INVTYPE_CHEST" end
            return "Apprentice Pendant", link, 2, 12, 10, "Armor", "Miscellaneous", 1, "INVTYPE_NECK"
        end
        function GetItemStats() return { ITEM_MOD_INTELLECT_SHORT = 3 } end
        local L = { C_DIM = {0.6,0.6,0.6}, C_HEADER = {1,1,1}, C_SUCCESS = {0,1,0} }
        function L:SectionHeader(_, y, title, sub)
            HEADERS[#HEADERS + 1] = title .. "|" .. tostring(sub or "")
            return y - 20
        end
        function L:Paragraph(_, y, text) PARAS[#PARAS + 1] = text; return y - 14 end
        function L:DataRow(_, y, opts)
            ROWS[#ROWS + 1] = tostring(opts.label) .. "|" .. tostring(opts.value) .. "|" .. tostring(opts.status) .. "|" .. tostring(opts.note or "")
            return y - 16
        end
        function L:Divider(_, y) return y - 8 end
        function L:Spacer(y, px) return y - (px or 6) end
        function L:Finish() end
        ToonAge.Layout = L
        ToonAge.modules.ForeverGear:Render({})
    """)

    headers = [lua.eval(f"HEADERS[{i}]") for i in range(1, int(lua.eval("#HEADERS")) + 1)]
    rows = [lua.eval(f"ROWS[{i}]") for i in range(1, int(lua.eval("#ROWS")) + 1)]

    check("Gear renders Forever Enchant Guide header for Caster DPS",
          any("Forever Enchant Guide (Caster DPS)" in h for h in headers))
    check("Gear flags Endgame (Lv 60) reference when player < 60",
          any("Endgame (Lv 60) reference" in h for h in headers))
    check("Gear marks unenchanted Neck [New] as Needs enchant (warn)",
          any(r.startswith("Neck [New]|Needs enchant|warn|Spell Power") for r in rows))
    check("Gear marks enchanted Chest as Enchanted (good)",
          any(r.startswith("Chest|Enchanted|good|Greater Stats") for r in rows))
    check("Gear marks unenchanted Off-Hand [New] with Wisdom",
          any(r.startswith("Off-Hand [New]|Needs enchant|warn|Wisdom") for r in rows))
    check("Gear shows Enchanter Ring Enchants [New]",
          any(r.startswith("Enchanter Ring Enchants [New]|") for r in rows))
    check("Gear omits Crafted Class Relics for Mage",
          not any(r.startswith("Crafted Class Relics") for r in rows))

    # Switch class to DRUID and confirm Crafted Class Relics appears
    lua.execute(r"""
        ROWS = {}
        ToonAge.Compat.UnitClass = function() return "Druid", "DRUID" end
        ToonAge.modules.ForeverGear:Render({})
    """)
    druid_rows = [lua.eval(f"ROWS[{i}]") for i in range(1, int(lua.eval("#ROWS")) + 1)]
    check("Gear shows Crafted Class Relics [New] for Druid",
          any(r.startswith("Crafted Class Relics [New]|") for r in druid_rows))


def test_faction_rewards_and_tracker():
    lua = new_lua()
    lua.execute(read("Data/Forever/FactionRewards.lua"))
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Progression/FactionTracker.lua"))

    check("ForeverFactionRewards loaded",
          lua.eval("type(ToonAge.Data.ForeverFactionRewards) == 'table'"))
    check("11 notable Forever factions defined",
          lua.eval("#ToonAge.Data.ForeverFactionRewards.factions"), 11)
    check("Every faction has 4 tiers, quartermaster, activity, and Forever URL",
          lua.eval("""
              (function()
                  for _, f in ipairs(ToonAge.Data.ForeverFactionRewards.factions) do
                      if not (f.name and f.side and f.activity and f.quartermaster and f.source) then return false end
                      if not (f.source:find("wow-forever/", 1, true) or f.source:find("wowhead.com/forever/", 1, true)) then
                          return false
                      end
                      local t = f.tiers
                      if not (t and t.Friendly and t.Honored and t.Revered and t.Exalted) then return false end
                  end
                  return true
              end)()
          """))

    # Case-insensitive lookup + NextRewardTier transitions
    check("LookupForeverFaction finds Darkspear Raiders case-insensitively",
          lua.eval('ToonAge.FactionTracker.LookupForeverFaction("darkspear raiders").name'),
          "Darkspear Raiders")
    check("NextRewardTier: Neutral -> Friendly",
          lua.eval('ToonAge.FactionTracker.NextRewardTier(ToonAge.FactionTracker.LookupForeverFaction("Darkspear Raiders"), "Neutral").tier'),
          "Friendly")
    check("NextRewardTier: Friendly -> Honored",
          lua.eval('ToonAge.FactionTracker.NextRewardTier(ToonAge.FactionTracker.LookupForeverFaction("Darkspear Raiders"), "Friendly").tier'),
          "Honored")
    check("NextRewardTier: Honored -> Revered",
          lua.eval('ToonAge.FactionTracker.NextRewardTier(ToonAge.FactionTracker.LookupForeverFaction("Darkspear Raiders"), "Honored").tier'),
          "Revered")
    check("NextRewardTier: Revered -> Exalted",
          lua.eval('ToonAge.FactionTracker.NextRewardTier(ToonAge.FactionTracker.LookupForeverFaction("Darkspear Raiders"), "Revered").tier'),
          "Exalted")
    check("NextRewardTier: Exalted -> maxed",
          lua.eval('ToonAge.FactionTracker.NextRewardTier(ToonAge.FactionTracker.LookupForeverFaction("Darkspear Raiders"), "Exalted").maxed'),
          True)

    # Faction-side filtering (Horde vs Alliance)
    horde_names = lua.eval("""
        (function()
            local out = {}
            for _, f in ipairs(ToonAge.FactionTracker.FilterForeverFactions("Horde")) do
                out[#out + 1] = f.name
            end
            return table.concat(out, "|")
        end)()
    """)
    alliance_names = lua.eval("""
        (function()
            local out = {}
            for _, f in ipairs(ToonAge.FactionTracker.FilterForeverFactions("Alliance")) do
                out[#out + 1] = f.name
            end
            return table.concat(out, "|")
        end)()
    """)
    check("Horde filter includes Darkspear Raiders & Argent Dawn",
          "Darkspear Raiders" in horde_names and "Argent Dawn" in horde_names)
    check("Horde filter excludes Theramore Expeditionary Force & Stormpike Guard",
          "Theramore Expeditionary Force" not in horde_names and "Stormpike Guard" not in horde_names)
    check("Alliance filter includes Theramore Expeditionary Force & Stormpike Guard",
          "Theramore Expeditionary Force" in alliance_names and "Stormpike Guard" in alliance_names)
    check("Alliance filter excludes Darkspear Raiders & Frostwolf Clan",
          "Darkspear Raiders" not in alliance_names and "Frostwolf Clan" not in alliance_names)

    # Render FactionTracker on Forever (Horde) with observed Darkspear Raiders at Friendly
    lua.execute(r"""
        FT_HEADERS = {}
        FT_BAR_TIPS = {}
        FT_ROWS = {}
        function UnitFactionGroup() return "Horde", "Horde" end
        C_Reputation = {
            GetNumFactions = function() return 2 end,
            GetFactionDataByIndex = function(i)
                local rows = {
                    { name = "Battlegrounds", isHeader = true, factionID = 100 },
                    { name = "Darkspear Raiders", factionID = 9999, reaction = 5,
                      currentReactionThreshold = 3000, nextReactionThreshold = 9000,
                      currentStanding = 4500, isHeader = false },
                }
                return rows[i]
            end,
        }
        local L = { C_DIM = {0.6,0.6,0.6} }
        function L:SectionHeader(_, y, title, sub)
            FT_HEADERS[#FT_HEADERS + 1] = title .. "|" .. tostring(sub or "")
            return y - 20
        end
        function L:Paragraph(_, y) return y - 14 end
        function L:StatBar(_, y, opts)
            FT_BAR_TIPS[opts.label] = table.concat(opts.tooltip or {}, "\n")
            return y - 20
        end
        function L:DataRow(_, y, opts)
            FT_ROWS[#FT_ROWS + 1] = tostring(opts.label) .. "|" .. tostring(opts.value) .. "|" .. tostring(opts.status) .. "|" .. tostring(opts.note or "")
            return y - 18
        end
        function L:Divider(_, y) return y - 8 end
        function L:Spacer(y, px) return y - (px or 6) end
        function L:Finish() end
        ToonAge.Layout = L
        ToonAge.FactionTracker:Render({})
    """)

    ft_headers = [lua.eval(f"FT_HEADERS[{i}]") for i in range(1, int(lua.eval("#FT_HEADERS")) + 1)]
    ft_rows = [lua.eval(f"FT_ROWS[{i}]") for i in range(1, int(lua.eval("#FT_ROWS")) + 1)]
    dr_tip = lua.eval('FT_BAR_TIPS["Darkspear Raiders"]') or ""

    check("Observed Darkspear Raiders tooltip includes Quartermaster",
          "Quartermaster: Creeg Bothunk" in dr_tip)
    check("Observed Darkspear Raiders tooltip shows Next unlock (Honored)",
          "Next unlock (Honored):" in dr_tip)
    check("FactionTracker renders Forever Faction Rewards section for Horde",
          any("Forever Faction Rewards|Key Forever PvP & PvE unlocks (Horde + Neutral)" in h for h in ft_headers))
    check("Darkspear Raiders reward row reflects live Friendly -> Honored progression",
          any(r.startswith("Darkspear Raiders|Friendly -> Honored|warn|Next (Honored):") for r in ft_rows))
    check("Theramore Expeditionary Force is hidden for Horde",
          not any(r.startswith("Theramore Expeditionary Force|") for r in ft_rows))


def main():
    test_enchants_data_and_gear()
    test_faction_rewards_and_tracker()
    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    if passed == total:
        print(f"OK: {passed}/{total} checks passed")
        sys.exit(0)
    print(f"FAIL: {passed}/{total} passed; {total - passed} failed")
    sys.exit(1)


if __name__ == "__main__":
    main()
