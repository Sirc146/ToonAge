#!/usr/bin/env python3
"""
CharacterAdvisor -- Guide Stub Generator
=========================================
Fetches a Wowhead quest page, extracts the full in-order storyline chain
from the "quick-facts-storyline-list" sidebar, and writes a skeleton .lua
guide file ready to drop into the addon.

Usage:
    python generate_guide_stub.py

Edit the CHAINS list at the bottom.  Run once per zone.
Fill in coords with /coord and step text while playing.

Requirements:  pip install requests beautifulsoup4
"""

import re
import sys
import time
import requests
from html.parser import HTMLParser

from paths import GUIDES_DIR, ensure

HEADERS  = {"User-Agent": "Mozilla/5.0 (CharacterAdvisor/1.0 guide-stub-generator)"}
BASE     = "https://www.wowhead.com/quest={}"
BASE_PTR = "https://www.wowhead.com/ptr-2/quest={}"
DELAY    = 0.35   # seconds between requests


# ── Minimal HTML parser (no external deps beyond requests) ────────────────────

class StorylineParser(HTMLParser):
    """Walks the Wowhead quest page and collects the ordered storyline list."""

    def __init__(self):
        super().__init__()
        self._in_storyline   = False
        self._depth          = 0
        self._capture_text   = False
        self.storyline_name  = ""
        self.quests          = []          # [ (questID, quest_name), ... ]
        self._current_id     = None
        self._current_name   = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)

        # Detect storyline title link
        if tag == "a" and "quick-facts-storyline-title" in attrs.get("class", ""):
            self._capture_text = True
            self._current_name = []
            return

        # Detect start of ordered list inside the storyline div
        if tag == "div" and "quick-facts-storyline-list" in attrs.get("class", ""):
            self._in_storyline = True
            self._depth        = 0
            return

        if self._in_storyline:
            if tag == "ol":
                self._depth += 1
            if tag == "li":
                self._current_id   = None
                self._current_name = []
            if tag == "a":
                href = attrs.get("href", "")
                m = re.search(r'/quest=(\d+)', href)
                if m:
                    self._current_id = int(m.group(1))
                self._capture_text = True
                self._current_name = []
            if tag == "span":   # current quest (no link)
                self._capture_text = True
                self._current_name = []

    def handle_endtag(self, tag):
        if not self._in_storyline:
            if tag == "a" and self._capture_text:
                self.storyline_name = "".join(self._current_name).strip()
                self._capture_text  = False
            return

        if tag in ("a", "span") and self._capture_text:
            name = "".join(self._current_name).strip()
            self._capture_text = False
            # Only append if we have a real quest ID (spans for the current quest
            # have no href; we inject the page's own ID separately below)
            if name and self._current_id is not None:
                self.quests.append((self._current_id, name))
            self._current_id   = None
            self._current_name = []

        if tag == "ol":
            self._depth -= 1
            if self._depth <= 0:
                self._in_storyline = False

    def handle_data(self, data):
        if self._capture_text:
            self._current_name.append(data)


def fetch_storyline(start_id, ptr=False):
    """Fetch one quest page and extract the complete in-order storyline chain."""
    url = (BASE_PTR if ptr else BASE).format(start_id)
    print(f"  Fetching storyline from quest {start_id} ({url})...")
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"  [ERR] {e}")
        return [], ""

    parser = StorylineParser()
    parser.feed(r.text)

    # Extract quest name from <title> tag as fallback for current quest
    title_m = re.search(r'<title>([^<]+)', r.text)
    page_title = title_m.group(1).split(" - ")[0].strip() if title_m else f"Quest {start_id}"

    quests = parser.quests

    # If this quest had no href (it's the "current" page shown as <span>),
    # Wowhead marks it with class="current" and the span holds its name.
    # Make sure start_id appears in the list.
    ids_in_list = {q[0] for q in quests}
    if start_id not in ids_in_list:
        # Inject it at position 0 (it's the current quest)
        quests.insert(0, (start_id, page_title))

    return quests, parser.storyline_name


# ── Also fetch questIDs for multi-chain zones (multiple storylines) ───────────

def fetch_multiple_storylines(start_ids, ptr=False):
    """Merge chains from multiple starting quest IDs (for zones with parallel chains)."""
    seen   = set()
    merged = []
    for sid in start_ids:
        quests, sname = fetch_storyline(sid, ptr=ptr)
        print(f"  Storyline '{sname}': {len(quests)} quests")
        for qid, qname in quests:
            if qid not in seen:
                seen.add(qid)
                merged.append((qid, qname))
        time.sleep(DELAY)
    return merged


# ── Lua generator ─────────────────────────────────────────────────────────────

def escape_lua(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").replace("\r", "")

def generate_lua(quests, guide_id, title, zone_map_id=0, min_level=1, max_level=60):
    lines = []
    lines.append(f"-- CharacterAdvisor/Data/Guides/CAG_{guide_id}.lua")
    lines.append( "-- STUB -- auto-generated by generate_guide_stub.py")
    lines.append( "-- TODO: fill in zone map ID, coords (/coord), step text.")
    lines.append( "")
    lines.append( "local CA = CharacterAdvisor")
    lines.append( "CA.GuideData = CA.GuideData or {}")
    lines.append( "")
    lines.append(f'CA.GuideData["{guide_id.lower()}"] = {{')
    lines.append(f'    id       = "{guide_id.lower()}",')
    lines.append(f'    title    = "{escape_lua(title)}",')
    lines.append(f'    zone     = {zone_map_id},   -- TODO: replace with /coord map ID')
    lines.append(f'    minLevel = {min_level},')
    lines.append(f'    maxLevel = {max_level},')
    lines.append( '    steps = {')

    for i, (qid, qname) in enumerate(quests, 1):
        id_str = str(qid) if qid else "nil  -- TODO: find real ID"
        lines.append(f'        -- Step {i}')
        lines.append( '        {')
        lines.append( '            type    = "quest",')
        lines.append(f'            questID = {id_str},')
        lines.append(f'            text    = "{escape_lua(qname)}",')
        lines.append( '            coord   = { map = 0, x = 0.00, y = 0.00 },  -- TODO: /coord')
        lines.append( '        },')

    lines.append('    },')
    lines.append('}')
    lines.append('')
    return "\n".join(lines)


# ── Zone definitions ──────────────────────────────────────────────────────────
#
# start_ids   list of quest IDs — one per storyline in the zone.
#             Use a single quest from the very first storyline as entry point;
#             Wowhead's sidebar shows the entire ordered chain.
#             For multi-storyline zones add extra IDs (they'll be merged).
#
# Finding start_ids:
#   Option A: /caquestscan in-game at the start of the zone.
#   Option B: Open the zone page on Wowhead, click the first campaign quest, note the URL ID.
#   Option C: /script print(GetQuestID()) on the NPC's accept dialog (before clicking Accept).

CHAINS = [
    {
        "guide_id":    "Exiles_Reach",
        "title":       "Exile's Reach -- New Player Experience",
        "start_ids":   [59926],      # "Warming Up" -- confirmed first quest
        "zone_map_id": 1409,   # Exile's Reach confirmed map ID
        "min_level":   1,
        "max_level":   10,
        "ptr":         False,
        "output":      "CAG_Exiles_Reach.lua",
    },
    # ── Add Midnight PTR zones below once you have starting quest IDs ─────
    # Get the first quest ID via /caquestscan on PTR or /script print(GetQuestID())
    # {
    #     "guide_id":    "Midnight_QuelsThelas",
    #     "title":       "Midnight: Quel'Thalas Introduction",
    #     "start_ids":   [XXXXX],     # first PTR quest ID
    #     "zone_map_id": 2434,
    #     "min_level":   70,
    #     "max_level":   80,
    #     "ptr":         True,
    #     "output":      "CAG_Midnight_QuelsThelas.lua",
    # },
]


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if not CHAINS:
        print("No chains defined. Add entries to the CHAINS list.")
        sys.exit(1)

    for chain in CHAINS:
        print(f"\n{'='*60}")
        print(f"Guide  : {chain['title']}")
        print(f"Starts : {chain['start_ids']}")
        print(f"{'='*60}")

        quests = fetch_multiple_storylines(
            start_ids = chain["start_ids"],
            ptr       = chain.get("ptr", False),
        )

        if not quests:
            print("  No quests found. Check start_ids and your internet connection.")
            continue

        lua = generate_lua(
            quests      = quests,
            guide_id    = chain["guide_id"],
            title       = chain["title"],
            zone_map_id = chain.get("zone_map_id", 0),
            min_level   = chain.get("min_level", 1),
            max_level   = chain.get("max_level", 60),
        )

        # Writes straight into Data/Guides/ now. It used to write a bare
        # filename into the current directory and then tell you to copy it,
        # which put generated data outside the repo and made the destination
        # depend on where you happened to be standing.
        out = chain.get("output") or (ensure(GUIDES_DIR) / f"CAG_{chain['guide_id']}.lua")
        with open(out, "w", encoding="utf-8") as f:
            f.write(lua)

        print(f"\n  {len(quests)} quest stubs written to {out}")
        print(f"\n  Next steps:")
        print(f"    1. Rename CAG_ -> TAG_ . The addon's convention is")
        print(f"       TAG_ZoneName.lua; this generator still emits the old")
        print(f"       CharacterAdvisor prefix, and the body it writes still")
        print(f"       references the CA global, so it will NOT load as-is.")
        print(f"    2. Add the filename to ToonAge.toc before GuideParser.lua")
        print(f"    3. /reload in-game -- tracker shows the stub steps")
        print(f"    4. Stand at each accept NPC and run /coord to fill coords")
        print(f"    5. Replace stub text with real guide prose as you play through")

    print("\nDone.")
