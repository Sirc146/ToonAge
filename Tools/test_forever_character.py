#!/usr/bin/env python3
"""The Forever Character tab reports, and never invents.

Everything on that tab is a value the client itself returns. There is no
researched Data/Forever yet, so any ranking, weighting or "you should" would be
fabricated. These assertions keep it honest, and keep the two Forever-specific
API differences we found the hard way from coming back.
"""
import sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


src = open(os.path.join(ROOT, "Modules/Forever/Character.lua"), encoding="utf-8").read()

# Comments explain the findings, so they legitimately mention Archaeology,
# weights and Holy. Assertions about what the tab DOES must read code only.
code = "\n".join(l for l in src.split("\n") if not l.strip().startswith("--"))

# Reads must never throw on a client whose API set is only partly mapped.
check("every read goes through Try()", "local function Try(fn, ...)" in src)
check("Try returns nil rather than 0 on failure", "if not res[1] then return nil end" in src)
check("a missing answer shows as n/a", 'return "|cFF6E6A62n/a|r"' in src)

# Vanilla stat model, confirmed on the beta's own character sheet.
check("Spirit is a primary attribute", 'SPI = 5' in src)
check("no mastery", "Mastery" not in src)
check("no versatility", "Versatility" not in src)
resist = code[code.index("local RESIST_ORDER"):]
resist = resist[:resist.index("\n}")]   # the table's own closing brace, not a row's
check("five resistance schools, no Holy",
      all(s in resist for s in ("Arcane", "Fire", "Frost", "Nature", "Shadow")) and "Holy" not in resist)

# Finding 1: UnitClass/UnitRace return the display name FIRST and the token
# second. Reading the token printed "Level 7 Scourge MAGE".
head = code[code.index("local function RenderHeadline"):code.index("local function RenderAttributes")]
check("class uses the display name", "local class = UnitClass(\"player\")" in head)
check("race uses the display name", "local race  = UnitRace(\"player\")" in head)

# Finding 2: Forever does not return profession slots in Retail's order — First
# Aid came back where Retail puts archaeology.
prof = code[code.index("local function RenderProfessions"):code.index("local function RenderSkills")]
check("professions are labelled by client name, not position",
      "label = tostring(name or (\"Slot \" .. i))" in prof)
check("position only distinguishes the two primaries", '(i == 1) and "First Profession"' in prof)
check("no hardcoded Archaeology slot", "Archaeology" not in prof)

# Skills: the beta sheet shows "Defense 13 / 15" but UnitDefense answered
# nothing, so the skill-lines API is the way in.
skills = code[code.index("local function RenderSkills"):code.index("local function RenderFooter")]
check("skills read the skill book", "GetSkillLineInfo" in skills)
check("skills guard the API's absence", 'type(GetNumSkillLines) ~= "function"' in skills)
check("professions are not listed twice", "professionNames[tostring(name)]" in skills)
check("a capped-short skill is called out", "below the cap for your level" in skills)

# The whole point: no advice.
for word in ("weight", "score(", "recommend", "best in slot", "upgrade"):
    check(f"no advice: '{word}' absent", word.lower() in code.lower(), False)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
