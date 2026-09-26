#!/usr/bin/env python3
"""Guards that survived the NavHud revert.

The HUD was rolled back to its pre-2026-09-19 state at the user's request, so
the movable-frame, fade, borrow-the-minimap and segment-ring assertions are
gone with the code they tested. What remains is the crash they exposed, which
lives in Core/Utils and still matters on every specless client.
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


ut = open(os.path.join(ROOT, "Core/Utils.lua"), encoding="utf-8").read()
spec = ut[ut.index("function U.GetPlayerSpec"):]
spec = spec[:spec.index("\nend") + 4]
check("spec lookup checks the API exists", 'type(GetSpecialization) ~= "function"' in spec)
check("spec lookup guards GetSpecializationInfo too",
      'type(GetSpecializationInfo) ~= "function"' in spec)
check("spec lookup cannot throw", spec.count("pcall") >= 2)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
