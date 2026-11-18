#!/usr/bin/env python3
"""
ToonAge -- Forever Arcane Mage stat order
==========================================
The Arcane rows in Data/Forever/StatPriority.lua, checked 2026-11-18.

Wowhead (updated 2026/11/17) lists Spell Damage with no Arcane Damage, and
keeps the level-30 caveat. Icy Veins (updated Nov 4, 2026) keeps its order
and ranks Arcane Damage with Spell Power.

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
    "Hit Chance until 17% > Spell Damage > Critical Strike Chance > "
    "Spell Piercing > Haste > Intellect > Spirit > Stamina"
)
WH_STEPS = "Hit>SpellPower>Crit>SpellPierce>Haste>Intellect>Spirit>Stamina"
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
    start = text.find("        Arcane = row({")
    end = text.find("        Fire = row({", start)
    return text[start:end]


def main():
    text = (ROOT / DATA).read_text(encoding="utf-8")
    block = arcane_block(text)
    check("Arcane block is present", start_ok(block), True)
    check("Wowhead URL is commented on the Arcane row", WH_URL in block, True)
    check("Icy Veins URL is commented on the Arcane row", IV_URL in block, True)
    check("date checked is commented on the Arcane row", CHECKED in block, True)

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
    check("Wowhead Arcane order matches the page list", str(wh_list["line"]), WH_LINE)
    check("Wowhead Arcane stats drop Arcane Damage", steps(wh_list), WH_STEPS)
    check("Wowhead Arcane caveat is unchanged", str(wh["caveat"]), CAVEAT)

    check("Icy Veins Arcane date stays the page stamp", str(iv["updated"]), "Nov 4, 2026")
    check("Icy Veins Arcane URL", str(iv["url"]), IV_URL)
    check("Icy Veins Arcane order is otherwise unchanged", str(iv_list["line"]), IV_LINE)
    check("Icy Veins Arcane ranks Arcane Damage with Spell Power", steps(iv_list), IV_STEPS)

    fire_iv = source_named(fire, "Icy Veins")
    fire_list = lua_list(fire_iv["lists"])[0]
    check("Fire Icy Veins order is not pulled along", str(fire_list["line"]), IV_LINE)
    check("Fire Icy Veins stats do not gain Arcane Damage", steps(fire_list), FIRE_IV_STEPS)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


def start_ok(block):
    return block.startswith("        Arcane = row({") and "Fire = row({" not in block


if __name__ == "__main__":
    sys.exit(main())
