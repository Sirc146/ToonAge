#!/usr/bin/env python3
"""
Regenerates the EVENT_ROUTES block in Core/Init.lua.

High-frequency events (bag, inventory, item-info, quest-log, aura, stat ...)
are sent only to modules whose source file mentions that event by name, instead
of to every module. The route is a superset by construction: any module that
filters on the event must name it. Run after adding an event to a module:

    python Tools/gen_event_routes.py          # rewrite Core/Init.lua
    python Tools/gen_event_routes.py --check  # exit 1 if the block is stale
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INIT = ROOT / "Core" / "Init.lua"

HIGH_FREQ = [
    "BAG_UPDATE", "UNIT_INVENTORY_CHANGED", "GET_ITEM_INFO_RECEIVED",
    "QUEST_LOG_UPDATE", "UNIT_AURA", "UNIT_STATS", "COMBAT_RATING_UPDATE",
    "UNIT_POWER_UPDATE", "UNIT_HEALTH", "CHAT_MSG_SYSTEM", "PLAYER_XP_UPDATE",
    "ACTIONBAR_SLOT_CHANGED", "SPELL_UPDATE_COOLDOWN", "PLAYER_TARGET_CHANGED",
    "UNIT_ATTACK_POWER", "BAG_UPDATE_DELAYED", "ZONE_CHANGED",
]

BEGIN = "-- BEGIN GENERATED EVENT_ROUTES (Tools/gen_event_routes.py)"
END = "-- END GENERATED EVENT_ROUTES"


def build():
    routes = {e: set() for e in HIGH_FREQ}
    for f in sorted((ROOT / "Modules").rglob("*.lua")) + sorted((ROOT / "Core").glob("*.lua")):
        src = f.read_text(encoding="utf-8-sig")
        names = re.findall(r'RegisterModule\(\s*"([^"]+)"', src)
        if not names:
            continue
        for ev in HIGH_FREQ:
            if re.search(r'["\[]%s["\]]|\b%s\s*=' % (ev, ev), src):
                routes[ev].update(names)
    lines = [BEGIN, "local EVENT_ROUTES = {"]
    for ev in HIGH_FREQ:
        mods = ", ".join('"%s"' % m for m in sorted(routes[ev]))
        lines.append("    %s = { %s }," % (ev, mods))
    lines.append("}")
    lines.append(END)
    return "\n".join(lines)


def main():
    src = INIT.read_text(encoding="utf-8")
    block = build()
    new = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), block, src, flags=re.S)
    if "--check" in sys.argv:
        ok = new == src
        print("[OK] EVENT_ROUTES up to date." if ok else "[FAIL] EVENT_ROUTES stale: run Tools/gen_event_routes.py")
        return 0 if ok else 1
    INIT.write_text(new, encoding="utf-8")
    print(block)
    return 0


if __name__ == "__main__":
    sys.exit(main())
