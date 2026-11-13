#!/usr/bin/env python3
"""Forever's install folder in Tools/build_flavors.ps1.

WoW Forever's client directory is _forever_. The build must install there
and must not install into _classic_beta_.

Usage:  python3 Tools/test_build_flavors.py [-v]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def install_dirs(text):
    match = re.search(r"(?m)^\$InstallDirs\s*=\s*@\{(.*?)^\}", text, re.S)
    if not match:
        return None
    found = {}
    for line in match.group(1).splitlines():
        entry = re.match(r"\s*'([^']+)'\s*=\s*@\(([^)]*)\)", line)
        if not entry:
            continue
        found[entry.group(1)] = re.findall(r"'([^']*)'", entry.group(2))
    return found


def main():
    text = (ROOT / "Tools" / "build_flavors.ps1").read_text(encoding="utf-8")
    dirs = install_dirs(text)
    check("InstallDirs map is present", dirs is not None, True)
    forever = (dirs or {}).get("Forever")
    check("Forever installs to _forever_", forever, ["_forever_"])
    check("Forever does not install to _classic_beta_",
          "_classic_beta_" in (forever or []), False)
    passed = sum(1 for ok in _res if ok)
    total = len(_res)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
