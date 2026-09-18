#!/usr/bin/env python3
"""
ToonAge -- per-flavor main-window tab set tests
===============================================
Guards against a flavor showing a tab that renders blank: every tab the
active profile lists must point at a module that is (a) registered by a file
in that flavor's TOC and (b) allowed by that flavor's profile. Also checks the
retail-only systems (Guide on TBC, Delves, Weekly) never appear on Classic
flavors, and that UI.lua's default set still covers retail.

Setup:  python -m pip install --user lupa
Usage:  python Tools/test_tab_set.py [-v]
"""

import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

FLAVORS = {
    # key: (WOW_PROJECT_ID, interface, toc)
    "retail": (1, 120007, "ToonAge_Mainline.toc"),
    "tbc":    (5, 20506,  "ToonAge_TBC.toc"),
    "mists":  (19, 50504, "ToonAge_Mists.toc"),
}

_results = []


def check(name, ok, detail=""):
    _results.append((bool(ok), name, detail))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"\n        {detail}" if detail and not ok else ""))


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8-sig")


def registered_modules(toc):
    names = set()
    for line in read(toc).splitlines():
        line = line.strip().replace("\\", "/")
        if not line.endswith(".lua") or line.startswith("#"):
            continue
        for m in re.finditer(r'RegisterModule\(\s*"([^"]+)"', read(line)):
            names.add(m.group(1))
    return names


def load(project_id, interface):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(f'WOW_PROJECT_ID = {project_id}\n'
                f'GetBuildInfo = function() return "x","0","d",{interface} end\n'
                'ToonAge = {}')
    lua.execute(read("Core/Environment.lua"))
    lua.execute(read("Core/Profile.lua"))
    return lua.globals().ToonAge


def default_tabs():
    src = read("Core/UI.lua")
    block = re.search(r"local DEFAULT_TABS = \{(.*?)\n\}", src, re.S).group(1)
    return re.findall(r'id\s*=\s*"([^"]+)".*?module\s*=\s*"([^"]+)"', block)


def lua_tabs(ta):
    tabs = ta.ProfileTabs(ta)
    if tabs is None:
        return None
    return [(tabs[i].id, tabs[i].module) for i in range(1, len(tabs) + 1)]


def main():
    for flavor, (pid, iface, toc) in FLAVORS.items():
        print(f"\n-- {flavor} ({toc})")
        ta = load(pid, iface)
        check(f"{flavor}: flavor resolves", ta.flavor == flavor, ta.flavor)
        mods = registered_modules(toc)
        tabs = lua_tabs(ta)
        if flavor == "retail":
            check("retail uses UI.lua default tab set", tabs is None)
            tabs = default_tabs()
        check(f"{flavor}: has tabs", bool(tabs))
        ids = [t[0] for t in tabs]
        check(f"{flavor}: tab ids unique", len(ids) == len(set(ids)), ids)
        check(f"{flavor}: character tab present", "character" in ids)
        for tab_id, module in tabs:
            check(f"{flavor}: tab '{tab_id}' module {module} registered by TOC",
                  module in mods, f"not registered by any file in {toc}")
            allowed = ta.ModuleAllowed(ta, module)
            allowed = allowed[0] if isinstance(allowed, tuple) else allowed
            check(f"{flavor}: tab '{tab_id}' module {module} allowed by profile", allowed)
        if flavor != "retail":
            for banned in ("delves", "weekly"):
                check(f"{flavor}: no '{banned}' tab", banned not in ids)
        if flavor == "tbc":
            check("tbc: no 'guide' tab (Dugi handles questing)", "guide" not in ids)
            for want in ("talents", "professions", "pets"):
                check(f"tbc: shared id '{want}' kept for /ta commands", want in ids)

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
