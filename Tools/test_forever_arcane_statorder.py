#!/usr/bin/env python3
"""
ToonAge -- Forever Arcane Mage stat order
==========================================
The Arcane rows in Data/Forever/StatPriority.lua, checked 2026-11-18.

Wowhead keeps Arcane Damage on the Spell Power step. The live list drops
the parenthetical; the owner retained it. Icy Veins ranks Arcane Damage
with Spell Power. Forever Era, Mobalytics, and Warcraft Tavern are notes.

Usage:  python3 Tools/test_forever_arcane_statorder.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
DATA = "Data/Forever/StatPriority.lua"
VERBOSE = "-v" in sys.argv
_results = []

WH_URL = "https://www.wowhead.com/forever/guide/classes/mage/arcane/stat-priority-pve-dps"
IV_URL = "https://www.icy-veins.com/wow-forever/arcane-mage-ranged-dps-pve-stat-priority"
CHECKED = "2026-11-18"
WH_LINE = (
    "Hit Chance until 17% > Spell Damage (+ Arcane Damage) > Critical Strike Chance > "
    "Spell Piercing > Haste > Intellect > Spirit > Stamina"
)
WH_STEPS = "Hit>SpellPower+ArcaneDamage>Crit>SpellPierce>Haste>Intellect>Spirit>Stamina"
WH_FLAG = (
    "delisted by Wowhead, retained — verified by Icy Veins, Forever Era, "
    "and Warcraft Tavern."
)
TFE_QUOTE = "Spell Power 1 Arcane damage 0.9"
MOBA_QUOTE = "Spell Power or the spell damage of your spec (fire / frost / arcane)"
TAVERN_QUOTE = "Raw Spell Power (Frost Damage Spell Power/Arcane Damage Spell Power)"
IV_EQUAL = "Value these equally to Spell Damage, as it applies to almost all of our damage"
IV_BUDGET = "the equivalent level item might be 10 Spell Damage vs 16 Arcane Damage"
IV_LINE = "Hit Chance (to 17%) > Spell Power > Critical Strike > Intellect > Spirit > Mp5"
IV_STEPS = "Hit>SpellPower+ArcaneDamage>Crit>Intellect>Spirit>MP5"
FIRE_IV_STEPS = "Hit>SpellPower>Crit>Intellect>Spirit>MP5"
CAVEAT = (
    "Given that the beta was level-locked at Level 30, it's unclear not only "
    "what stats are important for Arcane Mage, but also the availability of "
    "stats at Level 60. The priority below is purely speculative for endgame "
    "and is based on what we know from beta testing, but has not been tested "
    "in-game at Level 60."
)


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def lua_list(tbl):
    out = []
    i = 1
    while tbl[i] is not None:
        out.append(tbl[i])
        i += 1
    return out


def steps(list_obj):
    parts = []
    for step in lua_list(list_obj["stats"]):
        if hasattr(step, "keys"):
            parts.append("+".join(str(name) for name in lua_list(step)))
        else:
            parts.append(str(step))
    return ">".join(parts)


def source_named(row, name):
    for src in lua_list(row["sources"]):
        if str(src["name"]) == name:
            return src
    return None


def arcane_block(text):
    start = text.find("        -- Source notes (Arcane)")
    end = text.find("        Fire = row({", start)
    return text[start:end]


def main():
    text = (ROOT / DATA).read_text(encoding="utf-8")
    block = arcane_block(text)
    check("Arcane block is present", start_ok(block), True)
    check("Wowhead URL is commented on the Arcane row", WH_URL in block, True)
    check("Icy Veins URL is commented on the Arcane row", IV_URL in block, True)
    check("date checked is commented on the Arcane row", CHECKED in block, True)
    wh_note = block[block.find("wowhead.com/forever/guide/classes/mage/arcane"):]
    check("Wowhead Arcane Damage step uses the owner flag", WH_FLAG in wh_note, True)
    check("the old UNVERIFIED removal note is gone", "UNVERIFIED for owner decision" in block, False)
    check("Forever Era quote is recorded", TFE_QUOTE in block, True)
    check("Forever Era guide URL is recorded",
          "https://theforeverera.com/en/guides/classes/mage/" in block, True)
    check("Mobalytics quote is recorded", MOBA_QUOTE in block, True)
    check("Mobalytics URL is recorded",
          "https://mobalytics.gg/wow-forever/classes/arcane-mage-guide" in block, True)
    check("Warcraft Tavern quote is recorded", TAVERN_QUOTE in block, True)
    check("Warcraft Tavern URL is recorded",
          "https://www.warcrafttavern.com/wow-classic/guides/pve-arcane-mage-stat-priority/" in block, True)
    check("Icy Veins equal-value quote is recorded", IV_EQUAL in block, True)
    check("Icy Veins item-budget quote is recorded", IV_BUDGET in block, True)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { Data = {} }\n")
    lua.execute(text)
    data = lua.eval("ToonAge.Data.ForeverStatPriority")
    arcane = data["MAGE"]["Arcane"]
    fire = data["MAGE"]["Fire"]

    wh = source_named(arcane, "Wowhead")
    iv = source_named(arcane, "Icy Veins")
    wh_list = lua_list(wh["lists"])[0]
    iv_list = lua_list(iv["lists"])[0]
    check("Wowhead Arcane date is the page update", str(wh["updated"]), "2026/11/17")
    check("Wowhead Arcane URL", str(wh["url"]), WH_URL)
    check("Wowhead Arcane order keeps Arcane Damage", str(wh_list["line"]), WH_LINE)
    check("Wowhead Arcane Spell Power step keeps ArcaneDamage", steps(wh_list), WH_STEPS)
    check("Wowhead Arcane caveat is unchanged", str(wh["caveat"]), CAVEAT)

    check("Icy Veins Arcane date stays the page stamp", str(iv["updated"]), "Nov 4, 2026")
    check("Icy Veins Arcane URL", str(iv["url"]), IV_URL)
    check("Icy Veins Arcane order is otherwise unchanged", str(iv_list["line"]), IV_LINE)
    check("Icy Veins Arcane ranks Arcane Damage with Spell Power", steps(iv_list), IV_STEPS)
    names = [str(src["name"]) for src in lua_list(arcane["sources"])]
    check("Arcane scoring sources stay Icy Veins and Wowhead",
          names, ["Icy Veins", "Wowhead"])

    fire_iv = source_named(fire, "Icy Veins")
    fire_list = lua_list(fire_iv["lists"])[0]
    check("Fire Icy Veins order is not pulled along", str(fire_list["line"]), IV_LINE)
    check("Fire Icy Veins stats do not gain Arcane Damage", steps(fire_list), FIRE_IV_STEPS)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


def start_ok(block):
    return block.startswith("        -- Source notes (Arcane)") and "Fire = row({" not in block


if __name__ == "__main__":
    sys.exit(main())
