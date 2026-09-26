#!/usr/bin/env python3
"""The engine runs on every flavor. The profile gate must not reach it.

A handful of pieces under Core/ register as modules so they get Init and
OnEvent like everything else. No flavor profile lists them -- a profile
answers "what does this flavor ship?", and for the engine the answer is
always "all of it". Leaving them to the gate broke two things silently:

  ApiGuard   Init is what calls Probe(). Skipped, Guard.hasRun stays false and
             TA:HasAPI() returns true for everything. The architecture is TWO
             gates; the second was off on every non-retail flavor -- including
             Forever, whose API surface is only part mapped.

  SkillScan  OnEvent clears the skill cache. A skipped module gets no events,
             so on TBC the cache went stale under StatCaps and WeaponSkill,
             the two features that read skill levels.

This pins the exemption and, more importantly, keeps profile and TOC honest
about everything that ISN'T engine.
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


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


init = read("Core/Init.lua")

# ── The exemption exists and is applied ──────────────────────────────────
check("ENGINE_MODULES is declared", "local ENGINE_MODULES = {" in init)
check("the flavor gate honours it",
      "if self.ModuleAllowed and not ENGINE_MODULES[name] then" in init)

eng = init[init.index("local ENGINE_MODULES = {"):]
eng = eng[:eng.index("}")]
for m in ("ApiGuard", "SkillScan", "ErrorLog", "State", "TBCStats"):
    check(f"{m} is exempt", f"{m} = true" in eng)

# ApiGuard is the load-bearing one: prove HasAPI really is inert until Probe.
guard = read("Core/ApiGuard.lua")
check("HasAPI short-circuits before Probe", "if not Guard.hasRun then return true end" in guard)
check("Probe runs from Init", "self:Probe()" in
      guard[guard.index("function Guard:Init"):guard.index("function Guard:Init") + 400])

# SkillScan's value is entirely in its OnEvent, which a skipped module never gets.
scan = read("Core/SkillScan.lua")
check("SkillScan invalidates on skill change", "SKILL_LINES_CHANGED" in scan)

# ── Everything that is NOT engine must still reconcile ───────────────────
# Profile and TOC disagreeing is what shipped a blank Character tab and let
# Forever load the whole retail product. Engine modules are the only exception.
prof = read("Core/Profile.lua")


def allowed_for(flavor):
    i = prof.index(f"{flavor} = {{")
    blk = prof[i:]
    end = min(blk.index(k) for k in ("tabs      = {", "data      =") if k in blk)
    blk = blk[:end]
    if "allowAll  = true" in blk:
        return None
    return set(re.findall(r"^\s*(\w+)\s*=\s*true,", blk, re.M))


def ships(toc):
    out = set()
    for line in open(os.path.join(ROOT, toc), encoding="utf-8"):
        t = line.strip()
        if not t or t.startswith("#"):
            continue
        t = t.split("[")[0].strip()
        if not t.endswith(".lua"):
            continue
        p = os.path.join(ROOT, t.replace("\\", "/"))
        if not os.path.exists(p):
            continue
        out |= set(re.findall(r'TA:RegisterModule\("(\w+)"', open(p, encoding="utf-8").read()))
    return out


ENGINE = set(re.findall(r"(\w+) = true", eng))

for flavor, toc in [("forever", "ToonAge_Camelot.toc"), ("tbc", "ToonAge_TBC.toc"),
                    ("mists", "ToonAge_Mists.toc")]:
    allow = allowed_for(flavor)
    if allow is None:
        continue
    # Engine modules are ignored on BOTH sides. Several profiles still list
    # ErrorLog explicitly, which is now redundant but deliberately kept: if it
    # ever leaves ENGINE_MODULES, the profile entry is what stops it silently
    # vanishing from every flavor at once.
    shipped = ships(toc) - ENGINE
    allow   = allow - ENGINE
    check(f"{toc}: ships nothing its profile denies", sorted(shipped - allow), [])
    check(f"{toc}: ships everything its profile allows", sorted(allow - shipped), [])

# ── The Forever API manifest must match what Forever actually ships ─────
#
# ApiGuard's whole value is that the manifest is MEASURED, never hand-kept --
# .rules.md says a probe seeded with guesses tells you about the guesses. A
# stale manifest is the same failure slower: it probes for APIs nothing calls
# any more and stays quiet about the ones that were just added. So rather than
# trust that someone reran the generator, re-measure and compare.
RE_NS = re.compile(r"\bC_([A-Za-z]+)\.([A-Za-z0-9_]+)")

manifest_path = os.path.join(ROOT, "Data/Forever/ApiManifest.lua")
check("Forever manifest exists", os.path.exists(manifest_path))

if os.path.exists(manifest_path):
    listed = set(re.findall(r'^\s*\["([A-Za-z_][\w.]*)"\]', read("Data/Forever/ApiManifest.lua"), re.M))

    measured = set()
    for line in read("ToonAge_Camelot.toc").splitlines():
        t = line.strip()
        if not t or t.startswith("#"):
            continue
        t = t.split("[")[0].strip()
        if not t.endswith(".lua"):
            continue
        rel = t.replace("\\", "/")
        if rel.endswith("ApiManifest.lua"):
            continue          # never scan the output into itself
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        code = "\n".join(re.sub(r"--.*$", "", ln) for ln in read(rel).split("\n"))
        for m in RE_NS.finditer(code):
            measured.add(f"C_{m.group(1)}.{m.group(2)}")

    # Only the namespaced half is re-measured here; the bare-global list is
    # curated in the generator and is not derivable from source alone.
    ns_listed = {n for n in listed if n.startswith("C_")}
    check("manifest lists no C_ API that Forever's files never call",
          sorted(ns_listed - measured), [])
    check("manifest is missing no C_ API that Forever's files do call",
          sorted(measured - ns_listed), [])

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
