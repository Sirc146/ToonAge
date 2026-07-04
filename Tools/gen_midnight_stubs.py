#!/usr/bin/env python3
"""
CharacterAdvisor -- Midnight PTR Guide Stub Generator
======================================================
Reads the local WoWDB CSV (produced by crawl_wowdb_quests.py) and writes
one guide stub .lua per Midnight zone into Data/Guides/.

Quest ORDER is sorted by questID (ascending) as an approximation.
Verify real order in-game with /caquestscan, then re-order steps.
Fill coords with /coord at each quest-turn-in NPC.

Usage:
    python gen_midnight_stubs.py
"""

import csv, os, sys
from pathlib import Path

CSV_PATH = Path(r"E:\OneDrive\Desktop\wowdb\quests_database.csv")

# Resolve output dir relative to this script's location
SCRIPT_DIR = Path(__file__).parent
OUT_DIR    = SCRIPT_DIR.parent / "Data" / "Guides"

# ── Zone definitions ──────────────────────────────────────────────────────────
# categories: WoWDB "Category" column values to include (case-sensitive).
# min_id:     Skip quests with questID below this (filters out pre-Midnight
#             reuse of the same category names).
# zone:       WoW map ID — confirm with /coord in-game (/coord shows "Map: NNN").

MIDNIGHT_ZONES = [
    {
        "guide_id":   "Hallowfall",
        "title":      "The War Within: Hallowfall",
        "zone":       2248,       # confirm in-game
        "minLevel":   70,
        "maxLevel":   80,
        "categories": ["Hallowfall"],
        "min_id":     70000,
    },
    {
        "guide_id":   "Eversong_Midnight",
        "title":      "Midnight: Eversong Woods",
        "zone":       2434,       # placeholder -- confirm in-game
        "minLevel":   80,
        "maxLevel":   90,
        "categories": ["Eversong Woods"],
        "min_id":     70000,
    },
    {
        "guide_id":   "Silvermoon_Midnight",
        "title":      "Midnight: Silvermoon City",
        "zone":       2434,       # placeholder -- confirm in-game
        "minLevel":   80,
        "maxLevel":   90,
        "categories": ["Silvermoon City"],
        "min_id":     70000,
    },
    {
        "guide_id":   "Naigtal",
        "title":      "Midnight: Naigtal",
        "zone":       0,          # unknown -- confirm in-game
        "minLevel":   80,
        "maxLevel":   90,
        "categories": ["Naigtal", "Void Assaults"],
        "min_id":     70000,
    },
    # Add more zones here once you find their category names in quests_database.csv.
    # Quick lookup:  grep -i "Val," quests_database.csv | head -5
]


# ── Lua generation ────────────────────────────────────────────────────────────

def esc_lua(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')

def generate_stub(zdef, quests):
    gid = zdef["guide_id"]
    lines = [
        f'-- CharacterAdvisor/Data/Guides/CAG_{gid}.lua',
        '-- STUB -- auto-generated from WoWDB PTR HTML dump by gen_midnight_stubs.py',
        '-- Quest ORDER approximated by questID.  Confirm in-game with /caquestscan.',
        '-- Fill coords by standing at each NPC and running /coord.',
        '',
        'local CA = CharacterAdvisor',
        'CA.GuideData = CA.GuideData or {}',
        '',
        f'CA.GuideData["{gid.lower()}"] = {{',
        f'    id       = "{gid.lower()}",',
        f'    title    = "{esc_lua(zdef["title"])}",',
        f'    zone     = {zdef["zone"]},   -- TODO: confirm with /coord',
        f'    minLevel = {zdef["minLevel"]},',
        f'    maxLevel = {zdef["maxLevel"]},',
        '    steps = {',
    ]
    for i, (qid, name, mn, mx, cat) in enumerate(quests, 1):
        lines += [
            f'        -- Step {i}  [{cat}]',
            '        {',
            '            type    = "quest",',
            f'            questID = {qid},',
            f'            text    = "{esc_lua(name)}",',
            '            coord   = { map = 0, x = 0.00, y = 0.00 },',
            '        },',
        ]
    lines += ['    },', '}', '']
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not CSV_PATH.exists():
        print(f"[ERR] CSV not found: {CSV_PATH}")
        print("      Run crawl_wowdb_quests.py first.")
        sys.exit(1)

    all_rows = []
    with open(CSV_PATH, encoding='utf-8') as f:
        for r in csv.DictReader(f):
            all_rows.append(r)
    print(f"Loaded {len(all_rows)} quests from {CSV_PATH.name}")
    print(f"Output dir: {OUT_DIR}")
    print()

    for zdef in MIDNIGHT_ZONES:
        cats   = set(zdef["categories"])
        min_id = zdef.get("min_id", 0)

        quests = [
            (int(r["questID"]), r["name"],
             int(r["minLevel"]), int(r["maxLevel"]), r["category"])
            for r in all_rows
            if r["category"] in cats and int(r["questID"]) >= min_id
        ]
        quests.sort(key=lambda x: x[0])

        if not quests:
            print(f"  [SKIP] {zdef['guide_id']} -- no quests found for categories {cats}")
            continue

        lua = generate_stub(zdef, quests)
        out = OUT_DIR / f"CAG_{zdef['guide_id']}.lua"
        with open(out, "w", encoding="utf-8") as f:
            f.write(lua)
        print(f"  {len(quests):4d} steps  ->  {out.name}")

    print()
    print("Next steps:")
    print("  1. /reload in-game  ->  /ca tracker  to browse the stubs")
    print("  2. Play through each zone; /caquestscan captures the real quest order")
    print("  3. Paste /caquestscan output here and I'll re-order the stub steps")
    print("  4. Stand at each accept NPC and run /coord to fill the coord fields")


if __name__ == "__main__":
    main()
