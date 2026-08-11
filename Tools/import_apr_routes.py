#!/usr/bin/env python3
"""
ToonAge — APR Route Importer (Dev-Time Only)
=============================================
Reads APR route files and extracts quest IDs in route order to generate
ToonAge guide stub files. Runs ONCE on the developer's machine. The output
is static Lua data committed to the repo — zero runtime dependency on APR.

What this extracts (game facts, not copyrightable):
- Quest IDs in sequence
- Step types (pickup, objective, turnin)
- Zone/mapID associations

What this does NOT copy:
- APR's text descriptions or UI
- APR's optimization algorithms
- APR's coordinate data (left as 0,0 for CoordHarvester to fill)

Output files go to Data/Guides/ and must be added to ToonAge.toc.

Usage:
    python Tools/import_apr_routes.py --list          # show available routes
    python Tools/import_apr_routes.py Midnight        # import Midnight routes
    python Tools/import_apr_routes.py --all           # import all expansions
"""

import sys
import re
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent
GUIDES_DIR = REPO_ROOT / "Data" / "Guides"

# Auto-detect APR location
WOW_ROOT = REPO_ROOT.parent.parent.parent.parent  # AddOns → Interface → _ptr_ → WoW root
APR_CANDIDATES = [
    WOW_ROOT / "_ptr_" / "Interface" / "AddOns" / "APR" / "Routes",
    WOW_ROOT / "_retail_" / "Interface" / "AddOns" / "APR" / "Routes",
]
APR_ROUTES = None
for p in APR_CANDIDATES:
    if p.exists():
        APR_ROUTES = p
        break

EXPANSION_MAP = {
    "ExilesReach": ("exilesreach", 1, 10),
    "Vanilla": ("vanilla", 10, 60),
    "TheBurningCrusade": ("tbc", 10, 60),
    "WrathOfTheLichKing": ("wrath", 10, 60),
    "Cataclysm": ("cata", 10, 60),
    "MistsOfPandaria": ("mop", 10, 60),
    "WarlordsOfDraenor": ("wod", 10, 60),
    "Legion": ("legion", 10, 60),
    "BattleForAzeroth": ("bfa", 10, 60),
    "Shadowlands": ("shadowlands", 10, 60),
    "Dragonflight": ("dragonflight", 60, 70),
    "TheWarWithin": ("warwithin", 70, 80),
    "Midnight": ("midnight", 80, 90),
}


def parse_quest_ids(filepath: Path) -> list:
    """Extract quest IDs from an APR route in file order."""
    content = filepath.read_text(encoding="utf-8", errors="replace")
    quests = []
    seen = set()

    # Combined pattern to capture all quest references in order
    pattern = re.compile(
        r'(PickUp|Done|Qpart)\s*=\s*\{\s*(?:\[)?(\d+)'
    )

    for match in pattern.finditer(content):
        action = match.group(1)
        qid = int(match.group(2))

        if action == "PickUp":
            step_type = "pickup"
        elif action == "Done":
            step_type = "turnin"
        else:
            step_type = "quest"

        key = f"{qid}_{step_type}"
        if key not in seen:
            seen.add(key)
            quests.append({"questID": qid, "type": step_type, "pos": match.start()})

    quests.sort(key=lambda x: x["pos"])
    return quests


def extract_map_id(filepath: Path) -> int:
    content = filepath.read_text(encoding="utf-8", errors="replace")
    match = re.search(r'mapID\s*=\s*(\d+)', content)
    return int(match.group(1)) if match else 0


def generate_guide(route_name: str, expansion: str, min_lv: int, max_lv: int,
                   map_id: int, quests: list) -> str:
    safe_id = re.sub(r'[^a-zA-Z0-9_]', '_', route_name)

    lines = [
        f'-- ToonAge Guide: {route_name}',
        f'-- Generated from APR quest IDs (game facts). Coords filled by CoordHarvester.',
        f'-- NO runtime dependency on APR.',
        f'',
        f'local TA = ToonAge',
        f'TA.GuideData = TA.GuideData or {{}}',
        f'',
        f'TA.GuideData["{safe_id}"] = {{',
        f'    id         = "{safe_id}",',
        f'    title      = "{route_name}",',
        f'    zone       = {map_id},',
        f'    minLevel   = {min_lv},',
        f'    maxLevel   = {max_lv},',
        f'    expansion  = "{expansion}",',
        f'    steps = {{',
    ]

    for i, q in enumerate(quests, 1):
        lines.append(f'        {{ type = "{q["type"]}", questID = {q["questID"]},')
        lines.append(f'          coord = {{ map = {map_id}, x = 0, y = 0 }} }},')

    lines.append('    },')
    lines.append('}')
    lines.append('')
    return '\n'.join(lines)


def list_routes():
    if not APR_ROUTES:
        print("APR not found. Install APR and retry.")
        return

    total_quests = 0
    for exp_dir in sorted(APR_ROUTES.iterdir()):
        if not exp_dir.is_dir():
            continue
        files = list(exp_dir.glob("*.lua"))
        if not files:
            continue
        print(f"\n{exp_dir.name} ({len(files)} routes):")
        for f in sorted(files):
            quests = parse_quest_ids(f)
            total_quests += len(quests)
            print(f"  {f.stem}: {len(quests)} quest steps, {f.stat().st_size // 1024}KB")

    print(f"\nTotal: {total_quests} quest steps across all routes")


def import_routes(zone_filter: str = None):
    if not APR_ROUTES:
        print("APR not found. Install APR and retry.")
        sys.exit(1)

    GUIDES_DIR.mkdir(parents=True, exist_ok=True)
    imported = 0
    total_steps = 0

    for exp_dir in sorted(APR_ROUTES.iterdir()):
        if not exp_dir.is_dir():
            continue
        if zone_filter and zone_filter.lower() not in exp_dir.name.lower():
            continue

        exp_key, min_lv, max_lv = EXPANSION_MAP.get(exp_dir.name, (exp_dir.name.lower(), 1, 90))

        for route_file in sorted(exp_dir.glob("*.lua")):
            if "Speedrun" in route_file.name or "Prof" in route_file.name or "Glyph" in route_file.name:
                continue

            quests = parse_quest_ids(route_file)
            if len(quests) < 5:  # Skip tiny files
                continue

            map_id = extract_map_id(route_file)
            route_name = route_file.stem.replace("-", " ").replace("_", " ")

            content = generate_guide(route_name, exp_key, min_lv, max_lv, map_id, quests)

            out_name = f"TAG_{route_file.stem.replace('-', '_')}.lua"
            out_path = GUIDES_DIR / out_name
            out_path.write_text(content, encoding="utf-8")

            print(f"  {out_name}: {len(quests)} steps (map {map_id})")
            imported += 1
            total_steps += len(quests)

    print(f"\n{imported} guides generated, {total_steps} total steps")
    print(f"Output: {GUIDES_DIR}")
    print("\nNext steps:")
    print("  1. Add new TAG_*.lua files to ToonAge.toc")
    print("  2. Play through zones — CoordHarvester fills coords automatically")
    print("  3. /ta coordexport <mapID> to verify data")


def main():
    args = sys.argv[1:]

    if "--list" in args:
        list_routes()
    elif "--all" in args:
        import_routes()
    elif args:
        import_routes(args[0])
    else:
        print("Usage:")
        print("  python Tools/import_apr_routes.py --list")
        print("  python Tools/import_apr_routes.py Midnight")
        print("  python Tools/import_apr_routes.py --all")
        print()
        print("This is a DEV-TIME tool. Output is static Lua data.")
        print("ToonAge has ZERO runtime dependency on APR.")


if __name__ == "__main__":
    main()
