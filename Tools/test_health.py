#!/usr/bin/env python3
"""/ta health must report what is actually loaded.

It once reported "0 loaded / 0 off / 0 errored" on a client where every module
had loaded. Two locals in that handler were both called `report` -- the module
list, then the output window -- and the second shadowed the first, so the loop
walked the window. ipairs() over a window object yields nothing, so the counts
came out zero and no module line printed. It read like a total addon failure.

Part one pins that handler's shape. Part two is the general lint: a local name
declared twice in one function body is the shape of that bug, so it is flagged
everywhere, not just where it bit.
"""
import sys, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


init = open(os.path.join(ROOT, "Core/Init.lua"), encoding="utf-8").read()

# ── The handler itself ───────────────────────────────────────────────────
h = init[init.index("        health   = function()"):]
h = h[:h.index("\n        end,")]

m = re.search(r"local (\w+) = self:GetHealthReport\(\)", h)
check("the module list is bound to a name", m is not None)
list_name = m.group(1) if m else None

w = re.search(r"local (\w+) = TA\.BeginReport and TA:BeginReport", h)
check("the output window is bound to a name", w is not None)
win_name = w.group(1) if w else None

check("list and window have different names", list_name != win_name)
check("the loop walks the module list", f"ipairs({list_name})" in h)
check("the loop does not walk the window", f"ipairs({win_name})" not in h)

# Every counter must still be reachable: a status the loop never matches is
# the same failure wearing a different hat.
for status in ("loaded", "errored"):
    check(f"the {status} branch survives", f'entry.status == "{status}"' in h)
check("the off branch survives", "off = off + 1" in h)
check("profile-skipped modules are explained", "_profileSkipped" in h)

# ── The general lint ─────────────────────────────────────────────────────
# One block, one meaning per local name. Scope is approximated by indentation:
# any line indented LESS than a recorded declaration closes that declaration's
# block, so two sibling functions that both use `local row` are not a finding.
# What survives is the real shape -- a second `local x` in the SAME straight-
# line block, where the first binding is still meant to be live.
DECL = re.compile(r"^(\s*)local\s+([A-Za-z_]\w*)\s*=(?!=)")
offenders = []

for dirpath, _, files in os.walk(ROOT):
    if any(part in dirpath for part in (".git", "Libs", "Tools")):
        continue
    for fn in sorted(files):
        if not fn.endswith(".lua"):
            continue
        path = os.path.join(dirpath, fn)
        rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
        seen = {}                       # (indent, name) -> line number
        for i, line in enumerate(open(path, encoding="utf-8"), 1):
            if not line.strip() or line.lstrip().startswith("--"):
                continue
            indent = len(line) - len(line.lstrip())
            # Anything at this indent or shallower closes deeper blocks.
            for key in [k for k in seen if k[0] > indent]:
                del seen[key]
            d = DECL.match(line)
            if d:
                name = d.group(2)
                key = (indent, name)
                if key in seen:
                    offenders.append(f"{rel}:{i} re-declares `local {name}` "
                                     f"first bound at {rel}:{seen[key]}")
                seen[key] = i

check("no local is declared twice in one scope", offenders, [])

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
