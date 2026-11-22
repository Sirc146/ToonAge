#!/usr/bin/env python3
"""Phase 13 tests: All-9-class faction/location Trainer Locator + Mage Teleports & Portals.

Usage: python Tools/test_forever_trainers_portals.py [-v]
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
    ToonAge = { modules = {}, Data = {}, Utils = {}, flavor = "forever" }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    function ToonAge:GetModule(name) return self.modules[name] end
    function ToonAge:QueueUIRefresh() end
    """)
    lua.execute(read("Data/Forever/Trainers.lua"))
    lua.execute(read("Modules/Forever/SpellPlaybook.lua"))

    # 1. All 9 classes x 2 factions present with valid coords
    lua.execute(r"""
        local SP = ToonAge.SpellPlaybook
        local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
        ALL_18 = 0
        for _, cls in ipairs(classes) do
            for _, side in ipairs({ "Horde", "Alliance" }) do
                local info = SP.FindNearestTrainer(cls, side, nil)
                if info and info.trainer and info.trainer.zone and info.trainer.x and info.trainer.y then
                    ALL_18 = ALL_18 + 1
                end
            end
        end
    """)
    check("All 9 classes x 2 factions resolve sourced trainers with coords", lua.eval("ALL_18"), 18)

    # 2. Same-zone and continent-aware trainer routing
    lua.execute(r"""
        local SP = ToonAge.SpellPlaybook
        local r1 = SP.FindNearestTrainer("MAGE", "Horde", "Tirisfal Glades")
        ZONE_BRILL = r1 and (r1.trainer.zone .. "|" .. r1.trainer.district .. "|" .. tostring(r1.sameZone)) or ""

        local r2 = SP.FindNearestTrainer("MAGE", "Horde", "The Barrens")
        CONT_KAL_MAGE = r2 and r2.trainer.zone or ""

        local r3 = SP.FindNearestTrainer("MAGE", "Horde", "Silverpine Forest")
        CONT_EK_MAGE = r3 and r3.trainer.zone or ""

        local r4 = SP.FindNearestTrainer("SHAMAN", "Horde", "The Barrens")
        ZONE_XROADS = r4 and r4.trainer.district or ""

        local r5 = SP.FindNearestTrainer("PALADIN", "Horde", "Orgrimmar")
        HORDE_PAL_KAL = r5 and r5.trainer.zone or ""
        HORDE_PAL_NOTE = r5 and r5.note or ""

        local r6 = SP.FindNearestTrainer("SHAMAN", "Alliance", "Stormwind City")
        ALLI_SHA_EK = r6 and r6.trainer.zone or ""
        ALLI_SHA_NOTE = r6 and r6.note or ""

        local r7 = SP.FindNearestTrainer("WARRIOR", "Alliance", "Darkshore")
        ALLI_WAR_KAL = r7 and r7.trainer.zone or ""
    """)
    check("Horde Mage in Tirisfal Glades matches Brill (sameZone=true)",
          lua.eval("ZONE_BRILL"), "Tirisfal Glades|Brill|true")
    check("Horde Mage in The Barrens routes to Kalimdor Orgrimmar", lua.eval("CONT_KAL_MAGE"), "Orgrimmar")
    check("Horde Mage in Silverpine Forest routes to EK Undercity", lua.eval("CONT_EK_MAGE"), "Undercity")
    check("Horde Shaman in The Barrens matches The Crossroads", lua.eval("ZONE_XROADS"), "The Crossroads")
    check("Horde Paladin in Orgrimmar routes to Kalimdor Thunder Bluff", lua.eval("HORDE_PAL_KAL"), "Thunder Bluff")
    check("Horde Paladin advisory warns no trainer in Orgrimmar",
          "NO Paladin trainer in Orgrimmar" in lua.eval("HORDE_PAL_NOTE"), True)
    check("Alliance Shaman in Stormwind routes to Ironforge", lua.eval("ALLI_SHA_EK"), "Ironforge")
    check("Alliance Shaman advisory warns no trainer in Stormwind",
          "NO Shaman trainer in Stormwind" in lua.eval("ALLI_SHA_NOTE"), True)
    check("Alliance Warrior in Darkshore routes to Kalimdor Darnassus", lua.eval("ALLI_WAR_KAL"), "Darnassus")

    # 3. Mage Teleports & Portals reminders (Horde + Alliance + Dalaran)
    lua.execute(r"""
        local SP = ToonAge.SpellPlaybook
        local p19 = SP.GetMagePortals(19, "Horde", {})
        P19_DUE = #p19.due
        P19_UP  = #p19.upcoming

        local p20 = SP.GetMagePortals(20, "Horde", {})
        P20_DUE = #p20.due
        P20_NAMES = (p20.due[1] and p20.due[1].name or "") .. "|" .. (p20.due[2] and p20.due[2].name or "")

        local p30 = SP.GetMagePortals(30, "Horde", {
            ["Teleport: Orgrimmar"] = { name = "Teleport: Orgrimmar" },
            ["Teleport: Undercity"] = { name = "Teleport: Undercity" },
        })
        P30_KNOWN = #p30.known
        P30_DUE   = #p30.due
        P30_TB_NPC = p30.due[1] and (p30.due[1].name .. "|" .. p30.due[1].npc) or ""

        local p50A = SP.GetMagePortals(50, "Alliance", {})
        P50A_HAS_HORDE = false
        P50A_DAL_UNVER = false
        for _, p in ipairs(p50A.due) do
            if p.side == "Horde" then P50A_HAS_HORDE = true end
            if p.name == "Teleport: Dalaran" and p.verified == false then P50A_DAL_UNVER = true end
        end
    """)
    check("Lv 19 Horde Mage has 0 teleports due yet", lua.eval("P19_DUE"), 0)
    check("Lv 19 Horde Mage sees 7 upcoming teleports/portals", lua.eval("P19_UP"), 7)
    check("Lv 20 Horde Mage has 2 teleports due (Orgrimmar & Undercity)", lua.eval("P20_DUE"), 2)
    check("Lv 20 Horde Mage names Teleport: Orgrimmar and Teleport: Undercity",
          lua.eval("P20_NAMES"), "Teleport: Orgrimmar|Teleport: Undercity")
    check("Lv 30 Horde Mage marks learned Org/UC as known", lua.eval("P30_KNOWN"), 2)
    check("Lv 30 Horde Mage has 1 teleport due (Thunder Bluff)", lua.eval("P30_DUE"), 1)
    check("Teleport: Thunder Bluff names Birgitte Cranston",
          lua.eval("P30_TB_NPC"), "Teleport: Thunder Bluff|Birgitte Cranston")
    check("Alliance Lv 50 Mage never sees Horde portals", lua.eval("P50A_HAS_HORDE"), False)
    check("Teleport: Dalaran stays honestly marked verified=false", lua.eval("P50A_DAL_UNVER"), True)

    # 4. ForeverPins ToggleTargetPin wiring
    pins_src = read("Modules/Forever/Pins.lua")
    check("ForeverPins defines ToggleTargetPin", "function M:ToggleTargetPin" in pins_src, True)

    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
