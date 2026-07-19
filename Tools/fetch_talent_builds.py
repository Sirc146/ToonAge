#!/usr/bin/env python3
"""
ToonAge — Talent Build Fetcher
================================
Fetches current recommended talent import strings from public theorycraft
sources and generates the Data/Talents.lua build entries.

Sources tried (in priority order):
  1. Archon.gg (community-submitted top-performing builds with usage %)
  2. Wowhead talent calculator links (parsed into import strings)
  3. Manual fallback: prompts for paste if no API source works

The output is a ready-to-paste Lua snippet for each spec/content-type
combination. It does NOT replace the full Data/Talents.lua — it outputs
a fragment you merge in.

Usage:
  python fetch_talent_builds.py --all
  python fetch_talent_builds.py --spec survival --type pvp
  python fetch_talent_builds.py --class hunter

Requires: pip install requests beautifulsoup4
"""

import argparse
import json
import sys
import time
from pathlib import Path

try:
    import requests
    from bs4 import BeautifulSoup
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False

# All 39 specs with their IDs, class, and Archon/Wowhead slug patterns
SPECS = {
    # Death Knight
    250: {"name": "Blood",          "class": "death-knight", "role": "tank"},
    251: {"name": "Frost",          "class": "death-knight", "role": "dps"},
    252: {"name": "Unholy",         "class": "death-knight", "role": "dps"},
    # Demon Hunter
    577: {"name": "Havoc",          "class": "demon-hunter", "role": "dps"},
    581: {"name": "Vengeance",      "class": "demon-hunter", "role": "tank"},
    # Druid
    102: {"name": "Balance",        "class": "druid",        "role": "dps"},
    103: {"name": "Feral",          "class": "druid",        "role": "dps"},
    104: {"name": "Guardian",       "class": "druid",        "role": "tank"},
    105: {"name": "Restoration",    "class": "druid",        "role": "healer"},
    # Evoker
    1467: {"name": "Devastation",   "class": "evoker",       "role": "dps"},
    1468: {"name": "Preservation",  "class": "evoker",       "role": "healer"},
    1473: {"name": "Augmentation",  "class": "evoker",       "role": "dps"},
    # Hunter
    253: {"name": "Beast Mastery",  "class": "hunter",       "role": "dps"},
    254: {"name": "Marksmanship",   "class": "hunter",       "role": "dps"},
    255: {"name": "Survival",       "class": "hunter",       "role": "dps"},
    # Mage
    62:  {"name": "Arcane",         "class": "mage",         "role": "dps"},
    63:  {"name": "Fire",           "class": "mage",         "role": "dps"},
    64:  {"name": "Frost",          "class": "mage",         "role": "dps"},
    # Monk
    268: {"name": "Brewmaster",     "class": "monk",         "role": "tank"},
    269: {"name": "Windwalker",     "class": "monk",         "role": "dps"},
    270: {"name": "Mistweaver",     "class": "monk",         "role": "healer"},
    # Paladin
    65:  {"name": "Holy",           "class": "paladin",      "role": "healer"},
    66:  {"name": "Protection",     "class": "paladin",      "role": "tank"},
    70:  {"name": "Retribution",    "class": "paladin",      "role": "dps"},
    # Priest
    256: {"name": "Discipline",     "class": "priest",       "role": "healer"},
    257: {"name": "Holy",           "class": "priest",       "role": "healer"},
    258: {"name": "Shadow",         "class": "priest",       "role": "dps"},
    # Rogue
    259: {"name": "Assassination",  "class": "rogue",        "role": "dps"},
    260: {"name": "Outlaw",         "class": "rogue",        "role": "dps"},
    261: {"name": "Subtlety",       "class": "rogue",        "role": "dps"},
    # Shaman
    262: {"name": "Elemental",      "class": "shaman",       "role": "dps"},
    263: {"name": "Enhancement",    "class": "shaman",       "role": "dps"},
    264: {"name": "Restoration",    "class": "shaman",       "role": "healer"},
    # Warlock
    265: {"name": "Affliction",     "class": "warlock",      "role": "dps"},
    266: {"name": "Demonology",     "class": "warlock",      "role": "dps"},
    267: {"name": "Destruction",    "class": "warlock",      "role": "dps"},
    # Warrior
    71:  {"name": "Arms",           "class": "warrior",      "role": "dps"},
    72:  {"name": "Fury",           "class": "warrior",      "role": "dps"},
    73:  {"name": "Protection",     "class": "warrior",      "role": "tank"},
}

CONTENT_TYPES = ["mplus", "raid", "pvp", "delves", "solo"]

# Archon.gg URL patterns (they expose talent builds per spec + content)
ARCHON_BASE = "https://www.archon.gg/wow/builds"

def archon_url(spec_info, content_type):
    """Build an Archon.gg URL for a spec + content type."""
    cls = spec_info["class"]
    spec_slug = spec_info["name"].lower().replace(" ", "-")
    
    # Archon content type mapping
    archon_type = {
        "mplus": "mythic-plus",
        "raid": "raid",
        "pvp": "pvp",
        "delves": "delves",
        "solo": "leveling",
    }.get(content_type, "mythic-plus")
    
    # e.g. https://www.archon.gg/wow/builds/hunter/survival/mythic-plus/talents
    return f"{ARCHON_BASE}/{cls}/{spec_slug}/{archon_type}/talents"


def try_fetch_archon(spec_id, spec_info, content_type, session):
    """
    Attempt to fetch the talent import string from Archon.gg.
    Returns the import string or None.
    """
    url = archon_url(spec_info, content_type)
    try:
        resp = session.get(url, timeout=15)
        if resp.status_code != 200:
            return None
        
        soup = BeautifulSoup(resp.text, "html.parser")
        
        # Archon embeds talent strings in data attributes or code blocks
        # Pattern 1: look for a <code> or <pre> or data-export-string attribute
        for tag in soup.find_all(attrs={"data-export-string": True}):
            s = tag["data-export-string"].strip()
            if len(s) > 20:  # valid talent strings are long
                return s
        
        # Pattern 2: look for copy-button patterns
        for btn in soup.find_all("button", class_=lambda c: c and "copy" in c.lower()):
            val = btn.get("data-clipboard-text", "") or btn.get("data-value", "")
            if len(val) > 20 and val[0].isalpha():
                return val.strip()
        
        # Pattern 3: textarea or input with the string
        for inp in soup.find_all(["textarea", "input"]):
            val = inp.get("value", "") or inp.string or ""
            if len(val) > 50 and not val.startswith("http"):
                return val.strip()
        
        # Pattern 4: look in script tags for JSON data containing talent strings
        for script in soup.find_all("script"):
            text = script.string or ""
            # Look for base64-like talent strings (start with letter, long)
            import re
            matches = re.findall(r'"([A-Za-z][A-Za-z0-9+/=]{50,})"', text)
            for m in matches:
                # Talent strings typically start with specific prefixes
                if m[0] in "BCDEFb" and len(m) > 60:
                    return m
        
        return None
    except Exception:
        return None


def try_fetch_icyveins(spec_id, spec_info, content_type, session):
    """
    Attempt to fetch from Icy Veins talent page.
    Returns the import string or None.
    """
    cls = spec_info["class"]
    spec_slug = spec_info["name"].lower().replace(" ", "-")
    
    iv_type = {
        "mplus": "mythic-plus",
        "raid": "raiding",
        "pvp": "pvp",
        "delves": "open-world",
        "solo": "leveling",
    }.get(content_type, "raiding")
    
    url = f"https://www.icy-veins.com/wow/{spec_slug}-{cls}-{iv_type}-talent-build"
    try:
        resp = session.get(url, timeout=15)
        if resp.status_code != 200:
            return None
        
        soup = BeautifulSoup(resp.text, "html.parser")
        
        # Icy Veins puts talent strings in copy-paste boxes
        for elem in soup.find_all(class_=lambda c: c and ("talent-string" in c or "copy-text" in c)):
            text = elem.get_text(strip=True)
            if len(text) > 40 and text[0].isalpha():
                return text
        
        import re
        for script in soup.find_all("script"):
            text = script.string or ""
            matches = re.findall(r'"([A-Za-z][A-Za-z0-9+/=]{50,})"', text)
            for m in matches:
                if m[0] in "BCDEFb" and len(m) > 60:
                    return m
        
        return None
    except Exception:
        return None


def fetch_build(spec_id, spec_info, content_type, session):
    """Try all sources in order. Returns import string or empty string."""
    # Try Archon first
    result = try_fetch_archon(spec_id, spec_info, content_type, session)
    if result:
        return result
    
    time.sleep(0.5)  # rate limit
    
    # Try Icy Veins
    result = try_fetch_icyveins(spec_id, spec_info, content_type, session)
    if result:
        return result
    
    return ""


def generate_lua_snippet(results):
    """Generate a Lua code snippet from fetched results."""
    lines = []
    lines.append("-- AUTO-GENERATED talent import strings")
    lines.append("-- Run fetch_talent_builds.py --all to refresh")
    lines.append(f"-- Generated: {time.strftime('%Y-%m-%d %H:%M')}")
    lines.append("")
    
    for spec_id, spec_data in sorted(results.items(), key=lambda x: x[0]):
        spec_info = SPECS[spec_id]
        lines.append(f"-- {spec_info['class'].title()} / {spec_info['name']} (specID {spec_id})")
        for ctype, string in spec_data.items():
            if string:
                lines.append(f'-- DB[{spec_id}].builds.{ctype}.string = "{string}"')
            else:
                lines.append(f'-- DB[{spec_id}].builds.{ctype}.string = ""  -- NOT FOUND')
        lines.append("")
    
    return "\n".join(lines)


def interactive_mode(spec_id, spec_info, content_type):
    """Prompt user to paste a talent string manually."""
    print(f"\n  No auto-fetch for {spec_info['name']} {spec_info['class']} ({content_type})")
    print(f"  To get it manually:")
    print(f"    1. Open WoW Talent UI → select your {content_type} loadout")
    print(f"    2. Click 'Share' / 'Export' → copy the string")
    print(f"    3. Paste below (or press Enter to skip):")
    val = input("  > ").strip()
    return val if len(val) > 20 else ""


def main():
    if not HAS_DEPS:
        print("Missing dependencies. Install with: pip install requests beautifulsoup4")
        print("Or use --manual mode to paste strings by hand.")
        sys.exit(1)
    
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--all", action="store_true", help="Fetch all 39 specs × 5 types")
    ap.add_argument("--spec", help="Single spec name (e.g. 'survival', 'holy')")
    ap.add_argument("--class", dest="cls", help="Fetch all specs for one class")
    ap.add_argument("--type", help="Single content type (mplus/raid/pvp/delves/solo)")
    ap.add_argument("--manual", action="store_true", help="Interactive paste mode")
    ap.add_argument("--out", default="talent_builds_output.lua", help="Output file path")
    args = ap.parse_args()
    
    # Filter specs
    target_specs = {}
    if args.all:
        target_specs = SPECS
    elif args.cls:
        target_specs = {k: v for k, v in SPECS.items() if v["class"] == args.cls}
    elif args.spec:
        target_specs = {k: v for k, v in SPECS.items()
                       if v["name"].lower() == args.spec.lower()}
    else:
        print("Specify --all, --class <name>, or --spec <name>")
        sys.exit(1)
    
    target_types = [args.type] if args.type else CONTENT_TYPES
    
    if not target_specs:
        print(f"No specs matched. Available: {', '.join(s['name'] for s in SPECS.values())}")
        sys.exit(1)
    
    print(f"Fetching builds for {len(target_specs)} spec(s) × {len(target_types)} type(s)...")
    
    session = requests.Session()
    session.headers["User-Agent"] = "ToonAge-BuildFetcher/1.0 (WoW addon helper)"
    
    results = {}
    total = len(target_specs) * len(target_types)
    done = 0
    
    for spec_id, spec_info in target_specs.items():
        results[spec_id] = {}
        for ctype in target_types:
            done += 1
            label = f"{spec_info['name']} {spec_info['class']} [{ctype}]"
            
            if args.manual:
                s = interactive_mode(spec_id, spec_info, ctype)
            else:
                print(f"  [{done}/{total}] {label}...", end=" ", flush=True)
                s = fetch_build(spec_id, spec_info, ctype, session)
                print("✓" if s else "✗")
                time.sleep(1.0)  # rate limit between requests
            
            results[spec_id][ctype] = s
    
    # Output
    output = generate_lua_snippet(results)
    out_path = Path(args.out)
    out_path.write_text(output, encoding="utf-8")
    
    found = sum(1 for sd in results.values() for s in sd.values() if s)
    print(f"\nDone. {found}/{total} strings found.")
    print(f"Output: {out_path}")
    print("\nTo apply: open the output file and copy each string into")
    print("Data/Talents.lua's DB[specID].builds.X.string field.")
    print("Or use '/ta talentscan' in-game to capture your own loadouts.")


if __name__ == "__main__":
    main()
