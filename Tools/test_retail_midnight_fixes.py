#!/usr/bin/env python3
"""
ToonAge -- Retail Midnight 12.x Bugfix Regression Suite (Phase 11, R1-R7)
=========================================================================
Verifies fixes from the 10-screen Retail Midnight 12.x audit:
  R2. Character.lua: Versatility % uses GetCombatRatingBonus(29) + GetVersatilityBonus(29)
      with enum ID 29 (never passes the player's rating number).
  R3. Rotation.lua: Unverified Midnight specs with priority data render the
      reference banner + rows instead of a blank tab (keeping empty fallback).
  R4. ProfessionSkills.lua + ProfessionBoard.lua + Layout.lua: Live GetProfessionInfo
      rank seeds Midnight current segment when child skill lines return 0, and
      ProfessionCard tooltip anchors to ANCHOR_CURSOR with SetClampedToScreen(true).
  R5. Weekly.lua: Great Vault tier labels derive from live threshold (Kill 2/4/6),
      and prior-week claimable reward is clearly labeled.
  R6. Gear.lua: Shirt/Tabard marked isCosmetic (never flagged red Missing Item),
      single-line GEAR ADVISOR header, empty Heirlooms skipped at Lv 80+.
  R7. QuestTracker.lua + FactionTracker.lua: Chromie Time Suggested badge gated
      to level < 80, and Retail Reputation populates CharacterSidebar.

Usage:  python Tools/test_retail_midnight_fixes.py [-v]
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


def test_r2_versatility():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, Data = { StatWeights = {} }, Utils = {} }
        function ToonAge:RegisterModule(n, m) self.modules[n] = m end
        CR_VERSATILITY_DAMAGE_DONE = 29
        CALLED = {}
        function GetCombatRating(id) return 618 end
        function GetCombatRatingBonus(id)
            CALLED.bonusArg = id
            return (id == 29) and 7.73 or 0
        end
        function GetVersatilityBonus(id)
            CALLED.versArg = id
            return (id == 29) and 2.00 or 0
        end
    """)
    lua.execute(read("Modules/Character/Character.lua"))
    got = round(float(lua.eval("ToonAge.modules.Character._GetVers()")), 2)
    check("R2: GetVers passes enum 29 to GetCombatRatingBonus", lua.eval("CALLED.bonusArg"), 29)
    check("R2: GetVers passes enum 29 to GetVersatilityBonus", lua.eval("CALLED.versArg"), 29)
    check("R2: GetVers sums rating bonus + aura bonus (9.73%)", got, 9.73)


def test_r3_rotation_reference():
    src = read("Modules/Combat/Rotation.lua")
    check("R3: Rotation renders reference guide banner for unverified specs with priorities",
          "Reference guide (unverified):" in src)
    check("R3: Rotation keeps 'No suggestions for this spec' for empty specs",
          src.count('SetText("No suggestions for this spec")') >= 2)


def test_r4_professions_and_tooltip():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { flavor = "retail", modules = {}, Data = {} }
        function ToonAge:RegisterModule(n, m) self.modules[n] = m end
        function GetProfessions() return 1, 2, nil, 3, nil, nil end
        function GetProfessionInfo(idx)
            if idx == 1 then return "Herbalism", 136246, 64, 100, 0, 0, 182 end
            if idx == 2 then return "Skinning",  134366, 82, 100, 0, 0, 393 end
            if idx == 3 then return "Fishing",   136245, 45, 100, 0, 0, 356 end
        end
        C_TradeSkillUI = {
            -- Simulate client returning 0 for every child skill line before window open
            GetProfessionInfoBySkillLineID = function(id)
                return { skillLevel = 0, maxSkillLevel = 100, professionName = "" }
            end
        }
    """)
    lua.execute(read("Data/Retail/ProfessionSkills.lua"))
    lua.execute(read("Modules/Character/ProfessionSkills.lua"))
    lua.execute(r"""
        RES = ToonAge.ProfessionSkills.Collect()
        HERB = RES.cards[1]
        MID = nil
        for _, s in ipairs(HERB.segments or {}) do
            if s.current then MID = s end
        end
    """)
    check("R4: Herbalism card retains live GetProfessionInfo rank 64", lua.eval("HERB.rank"), 64)
    check("R4: Midnight current segment seeded from live rank when child APIs return 0",
          lua.eval("MID and MID.rank"), 64)

    # Also check ProfessionBoard RankOf fallback when current segment is 0
    board_src = read("Modules/Character/ProfessionBoard.lua")
    check("R4: ProfessionBoard RankOf falls back to card.rank when current segment is 0",
          "if (seg.rank and seg.rank > 0) or not (rank and rank > 0) then" in board_src)

    layout_src = read("Core/Layout.lua")
    check("R4: ProfessionCard tooltip anchors to ANCHOR_CURSOR",
          'GameTooltip:SetOwner(self, "ANCHOR_CURSOR")' in layout_src)
    check("R4: ProfessionCard tooltip clamps to screen",
          "GameTooltip:SetClampedToScreen(true)" in layout_src)


def test_r5_weekly_vault():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, Utils = {}, charDB = {} }
        function ToonAge:RegisterModule(n, m) self.modules[n] = m end
        function ToonAge:GetModule(n) return self.modules[n] end
        Enum = { WeeklyRewardChestThresholdType = { Activities = 1, Raid = 2, World = 3 } }
        C_WeeklyRewards = {
            HasAvailableRewards = function() return true end,
            GetActivities = function(t)
                if t == 2 then
                    return {
                        { id = 1, threshold = 2, progress = 0, isUnlocked = false },
                        { id = 2, threshold = 4, progress = 0, isUnlocked = false },
                        { id = 3, threshold = 6, progress = 0, isUnlocked = false },
                    }
                end
                return {}
            end,
        }
        STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    """)
    lua.execute(read("Modules/Progression/Weekly.lua"))
    check("R5: Raid tier label derives 'Kill 2' from live threshold=2",
          lua.eval('ToonAge.modules.Weekly._FormatTierLabel({ verb = "Kill" }, 1, 2)'), "Kill 2")
    check("R5: Raid tier label derives 'Kill 4' from live threshold=4",
          lua.eval('ToonAge.modules.Weekly._FormatTierLabel({ verb = "Kill" }, 2, 4)'), "Kill 4")
    check("R5: Raid tier label derives 'Kill 6' from live threshold=6",
          lua.eval('ToonAge.modules.Weekly._FormatTierLabel({ verb = "Kill" }, 3, 6)'), "Kill 6")

    lua.execute("RECS = ToonAge.modules.Weekly:BuildRecommendations()")
    check("R5: Prior-week claimable reward clearly labeled",
          lua.eval("""
              (function()
                  for _, r in ipairs(RECS) do
                      if r.text == "Claim last week's Great Vault reward!" and r.reason == "Prior week" then
                          return true
                      end
                  end
                  return false
              end)()
          """))


def test_r6_gear_tab():
    src = read("Modules/Gear/Gear.lua")
    check("R6: Shirt marked isCosmetic = true", '{ slotID = 4,  name = "Shirt",     isCosmetic = true }' in src)
    check("R6: Tabard marked isCosmetic = true", '{ slotID = 19, name = "Tabard",    isCosmetic = true }' in src)
    check("R6: Cosmetic slots show Optional (Cosmetic) instead of Missing Item",
          "Optional (Cosmetic)" in src and "Cosmetic Slot" in src)
    check("R6: Single-line GEAR ADVISOR header avoids wrap collision",
          'hdr:SetText(self.viewMode == "player" and "GEAR ADVISOR" or "TARGET SCOUTER")' in src)
    check("R6: Empty max-level Heirlooms card skipped at level 80+",
          "skipEmptyMaxHeirlooms" in src)


def test_r7_guide_and_reputation():
    qt_src = read("Modules/Navigation/QuestTracker.lua")
    check("R7: Chromie Time Suggested badge gated to pLevel < 80",
          "if pLevel < 80 and timeline and timeline.eligible then" in qt_src)

    # Verify FactionTracker calls CharacterSidebar on Retail when ForeverCharacter is absent
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { flavor = "retail", modules = {}, Reputations = { midnight = {} } }
        function ToonAge:RegisterModule(n, m) self.modules[n] = m end
        function ToonAge:GetModule(n) return self.modules[n] end
        SIDEBAR_CALLED = false
        ToonAge.Layout = {
            CharacterSidebar = function(_, side) SIDEBAR_CALLED = (side ~= nil) end,
            SectionHeader = function(_, _, y) return y - 20 end,
            Paragraph = function(_, _, y) return y - 14 end,
            Finish = function() end,
        }
    """)
    lua.execute(read("Modules/Progression/FactionTracker.lua"))
    lua.execute("ToonAge.FactionTracker:Render({}, {})")
    check("R7: Retail Reputation populates CharacterSidebar", lua.eval("SIDEBAR_CALLED"), True)


def main():
    test_r2_versatility()
    test_r3_rotation_reference()
    test_r4_professions_and_tooltip()
    test_r5_weekly_vault()
    test_r6_gear_tab()
    test_r7_guide_and_reputation()
    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    if passed == total:
        print(f"OK: {passed}/{total} checks passed")
        sys.exit(0)
    print(f"FAIL: {passed}/{total} passed; {total - passed} failed")
    sys.exit(1)


if __name__ == "__main__":
    main()
