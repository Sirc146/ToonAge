#!/usr/bin/env python3
"""
ToonAge -- Gear Stage 1 (Forever stat priorities)
==================================================
Every Forever spec stores both guide orders and the status CONFLICT.
Feral is two rows, Cat and Bear. Nothing is marked confirmed.
Colouring: high -> green, low -> grey, useless -> red.
The new files load only from ToonAge_Camelot.toc.

Usage:  python3 Tools/test_gear_stage1.py [-v]
"""
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

IV_PREFIX = "https://www.icy-veins.com/wow-forever/"
WH_PREFIX = "https://www.wowhead.com/forever/"
STATUSES = {
    "confirmed (2 sources)",
    "UNVERIFIED (single source)",
    "CONFLICT",
}
TONE_STATUS = {"high": "good", "low": "dim", "useless": "bad"}
FOREIGN = ("Data/Retail/", "Data/TBC/", "Data/Mists/", "Data/Vanilla/",
           "Data\\Retail\\", "Data\\TBC\\", "Data\\Mists\\", "Data\\Vanilla\\")


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def section_names():
    text = read("Core/Compat/API.lua")
    block = re.search(r"local SECTION_NAMES = \{(.+?)\n\}", text, re.S)
    if not block:
        return {}
    out = {}
    for cls, body in re.findall(r'(\w+)\s*=\s*\{([^}]+)\}', block.group(1)):
        out[cls] = re.findall(r'"([^"]+)"', body)
    return out


def coach_specs():
    text = read("Data/Forever/Coach.lua")
    out = {}
    current = None
    for line in text.splitlines():
        m = re.match(r"\s{4}(\w+) = \{", line)
        if m and m.group(1).isupper():
            current = m.group(1)
            out[current] = []
            continue
        m = re.match(r'\s{8}(?:\["([^"]+)"\]|(\w+)) = \{', line)
        if m and current:
            out[current].append(m.group(1) or m.group(2))
    return out


def toc_text(name):
    return read(name)


def listed(name):
    rows = []
    for line in toc_text(name).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        rows.append(s.split("[")[0].strip().replace("\\", "/"))
    return rows


def main():
    names = section_names()
    check("Forever section names come from Compat", len(names) >= 9, True)
    coach = coach_specs()
    check("coach specs match the trait section names", coach, names)

    data_rel = "Data/Forever/StatPriority.lua"
    mod_rel = "Modules/Forever/StatPriority.lua"
    for rel in (data_rel, mod_rel):
        check(f"{rel} exists", (ROOT / rel).is_file(), True)

    camelot = listed("ToonAge_Camelot.toc")
    check("Camelot lists the priority data", "Data/Forever/StatPriority.lua" in camelot, True)
    check("Camelot lists the priority module", "Modules/Forever/StatPriority.lua" in camelot, True)
    for toc in ("ToonAge_Mainline.toc", "ToonAge.toc"):
        body = toc_text(toc)
        check(f"{toc} does not list StatPriority", "StatPriority.lua" in body, False)

    if not (ROOT / data_rel).is_file() or not (ROOT / mod_rel).is_file():
        passed = sum(_results)
        print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
        return 0 if passed == len(_results) else 1

    for rel in (data_rel, mod_rel, "Modules/Forever/Gear.lua"):
        text = read(rel)
        foreign = [p for p in FOREIGN if p in text]
        check(f"{rel} has no other expansion path", foreign, [])

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { Data = {} }\n")
    lua.execute(read(data_rel))
    lua.execute(read(mod_rel))
    SP = lua.eval("ToonAge.StatPriority")
    data = lua.eval("ToonAge.Data.ForeverStatPriority")
    unknown = lua.eval("ToonAge.Data.ForeverStatPriorityUnknown")

    check("module API is present", SP is not None and data is not None, True)
    missing_unknown = []
    if unknown is None:
        missing_unknown.append("table missing")
    else:
        for cls, specs in names.items():
            class_tbl = data[cls]
            for spec in specs:
                got = SP.Get(SP, cls, spec)
                listed_unknown = False
                if unknown[cls] is not None:
                    for row in unknown[cls].values():
                        if str(row) == spec or (hasattr(row, "spec") and str(row["spec"]) == spec):
                            listed_unknown = True
                if got is None and not listed_unknown:
                    missing_unknown.append(f"{cls}/{spec}")
                if got is not None and listed_unknown:
                    missing_unknown.append(f"{cls}/{spec} both stored and UNKNOWN")
    check("every Forever spec is stored or listed UNKNOWN", missing_unknown, [])

    bad_sources = []
    if data is not None:
        for cls in data.keys():
            for spec in data[cls].keys():
                entry = SP.Get(SP, cls, spec)
                for row in SP.Rows(SP, entry).values():
                    label = f"{cls}/{spec}"
                    if row["label"]:
                        label = label + "/" + str(row["label"])
                    if str(row["status"] or "") != "CONFLICT":
                        bad_sources.append((label, str(row["status"] or "")))
                    sources = row["sources"]
                    urls = []
                    if sources is None:
                        bad_sources.append((label, "no sources"))
                        continue
                    for src in sources.values():
                        url = str(src["url"] or "")
                        urls.append(url)
                        if not (url.startswith(IV_PREFIX) or url.startswith(WH_PREFIX)):
                            bad_sources.append((label, url))
                        if not str(src["updated"] or ""):
                            bad_sources.append((label, "missing updated"))
                        lists = src["lists"]
                        if lists is None or len(list(lists.values())) == 0:
                            bad_sources.append((label, "no order"))
                        else:
                            for lst in lists.values():
                                line = str(lst["line"] or "")
                                if ">" not in line:
                                    bad_sources.append((label, line))
                    if not any(u.startswith(IV_PREFIX) for u in urls):
                        bad_sources.append((label, "missing Icy Veins"))
                    if not any(u.startswith(WH_PREFIX) for u in urls):
                        bad_sources.append((label, "missing Wowhead"))
                    if str(row["status"] or "") == "confirmed (2 sources)":
                        bad_sources.append((label, "confirmed"))
    check("every row has both Forever sources, a date, an order and CONFLICT", bad_sources, [])

    for tone, status in TONE_STATUS.items():
        check(f"colour {tone} -> {status}", str(SP.BarStatus(SP, tone)), status)
    check("unknown tone has no colour", SP.BarStatus(SP, None) is None, True)

    rows = []
    confirmed = []
    if data is not None:
        for cls in list(data.keys()):
            for spec in list(data[cls].keys()):
                entry = SP.Get(SP, cls, spec)
                for row in SP.Rows(SP, entry).values():
                    rows.append((cls, spec, str(row["label"] or ""), str(row["status"] or "")))
                    if str(row["status"] or "") != "CONFLICT":
                        confirmed.append((cls, spec, str(row["status"] or "")))
    check("28 level-60 rows (Feral is Cat and Bear)", len(rows), 28)
    check("no order is marked confirmed or unverified", confirmed, [])
    feral = SP.Get(SP, "DRUID", "Feral")
    labels = []
    if feral is not None:
        for row in SP.Rows(SP, feral).values():
            labels.append(str(row["label"] or ""))
    check("Feral stores Cat and Bear", sorted(labels), ["Bear", "Cat"])

    # Arcane: Hit is in the top three of both guides. Strength is not, and
    # neither guide calls it useless, so it stays grey.
    check("Arcane Get returns the row", SP.Get(SP, "MAGE", "Arcane") is not None, True)
    check("Arcane Hit is high", str(SP.Tone(SP, "MAGE", "Arcane", "Hit")), "high")
    check("Arcane Strength is grey, not red", str(SP.Tone(SP, "MAGE", "Arcane", "Strength")), "low")
    check("Arcane Strength bar is grey", str(SP.BarStatus(SP, SP.Tone(SP, "MAGE", "Arcane", "Strength"))), "dim")
    check("Arcane Hit bar is green", str(SP.BarStatus(SP, SP.Tone(SP, "MAGE", "Arcane", "Hit"))), "good")
    check("item key follows the same tone",
          str(SP.ToneForItemKey(SP, "MAGE", "Arcane", "ITEM_MOD_STRENGTH_SHORT")), "low")
    check("default guide view is both", str(SP.View(SP)), "both")

    blob = "\n".join(read(rel) for rel in (data_rel, mod_rel, "Modules/Forever/Gear.lua"))
    check("wand damage is not said to scale with spell damage",
          "Wand Damage" in blob or "increases Wand" in blob, False)

    gear = read("Modules/Forever/Gear.lua")
    check("Gear tab asks StatPriority for the bar colour",
          "TA.StatPriority" in gear and "BarStatus" in gear and "ToneForItemKey" in gear, True)
    check("Gear tab prints the priority line", "Suggested stat priority" in gear, True)
    check("Gear tab can show both guides or one",
          "Both" in gear and "Icy Veins" in gear and "Wowhead" in gear, True)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
