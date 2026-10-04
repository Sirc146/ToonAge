#!/usr/bin/env python3
"""Harvest capability layer -- Core/Caps.lua (harvest spec T1, section 4.2).

Runs the real Core/Caps.lua under Lua 5.1 against a mock _G and checks:

  * State: present / missing / secret for plain and dotted paths, bad input,
    a non-table segment, and "secret" never collapsed to "missing"
  * Fn / Get / Call: callables only, constants, nils kept in returns, errors
    and secret returns reported, never thrown
  * Seen: every path asked, with its state
  * Provider swap: a stub resolver (G3 stand-in) replaces the local one with no
    change to callers; a provider that errors or answers nonsense is "missing"
  * the file names no client API (the manifest generator scans shipped files)
  * Lint: nothing under Modules/Harvest/ detects APIs by hand (_G[...],
    type(...) == "function", `Namespace and Namespace.Fn`). Vacuous until the
    packs exist (T4); enforced from then on.

Usage:  python Tools/test_harvest_caps.py [-v]
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


src_path = os.path.join(ROOT, "Core/Caps.lua")
src = open(src_path, encoding="utf-8").read()

check("Caps.lua names no namespaced client API",
      re.findall(r"\bC_[A-Za-z]+\.[A-Za-z0-9_]+", src), [])

WORLD = r"""
ToonAge = {}
SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(v) return v == SECRET end
function CreateFrame() return {} end
PROJECT_ID = 18
NS = {
    Double  = function(x) return x * 2 end,
    Pair    = function() return nil, 2 end,
    Boom    = function() error("boom") end,
    Hidden  = function() return SECRET, 5 end,
    Const   = 7,
    Inner   = { Deep = function() return "deep" end },
}
SECRET_GLOBAL = SECRET
Guarded = setmetatable({}, { __index = function() error("no peeking") end })
"""

L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute(WORLD)
L.execute(src)
C = L.eval("ToonAge.Caps")
g = L.globals()

# ── State ────────────────────────────────────────────────────────────────
check("provider defaults to harvest-local", C.Provider, "harvest-local")
check("plain global present", C.State("CreateFrame"), "present")
check("plain global missing", C.State("NoSuchThing"), "missing")
check("dotted function present", C.State("NS.Double"), "present")
check("dotted nested present", C.State("NS.Inner.Deep"), "present")
check("dotted missing leaf", C.State("NS.Nope"), "missing")
check("segment through a non-table is missing", C.State("NS.Const.More"), "missing")
check("empty path is missing", C.State(""), "missing")
check("nil path is missing", C.State(None), "missing")
check("number constant present", C.State("PROJECT_ID"), "present")
check("secret value reads secret, not missing", C.State("SECRET_GLOBAL"), "secret")
check("a throwing __index is missing, not an error", C.State("Guarded.Anything"), "missing")

# ── Fn / Get ─────────────────────────────────────────────────────────────
check("Fn returns the function", C.Fn("NS.Double") is not None)
check("Fn is nil for a missing path", C.Fn("NS.Nope"), None)
check("Fn is nil for a present non-function", C.Fn("NS.Const"), None)
check("Fn is nil for a namespace table", C.Fn("NS"), None)
check("Get returns a constant", tuple(C.Get("PROJECT_ID")), (18, "present"))
check("Get of a secret returns the word secret", tuple(C.Get("SECRET_GLOBAL")), ("secret", "secret"))
check("Get of a missing path", tuple(C.Get("NS.Nope")), (None, "missing"))

# ── Call ─────────────────────────────────────────────────────────────────
check("Call passes args and returns values", tuple(C.Call("NS.Double", 21)), (True, 42))
pack = L.eval("function(...) return select('#', ...), ... end")
n_and = pack(*C.Call("NS.Pair"))
check("Call keeps nil returns (count and order)", tuple(n_and), (3, True, None, 2))
ok, msg = C.Call("NS.Boom")
check("Call reports an error instead of throwing", ok, False)
check("Call error message names the error", "boom" in str(msg))
check("Call on a missing path", tuple(C.Call("NS.Nope")), (False, "missing"))
check("Call on a secret path", tuple(C.Call("SECRET_GLOBAL")), (False, "secret"))
check("Call turns a secret return into the word secret",
      tuple(C.Call("NS.Hidden")), (True, "secret", 5))
check("Call on a non-function value is missing", tuple(C.Call("NS.Const")), (False, "missing"))

# ── Seen ─────────────────────────────────────────────────────────────────
seen = C.Seen()
check("Seen records a present path", seen["NS.Double"], "present")
check("Seen records a missing path", seen["NoSuchThing"], "missing")
check("Seen records a secret path", seen["SECRET_GLOBAL"], "secret")
seen["NS.Double"] = "tampered"
check("Seen returns a copy", C.Seen()["NS.Double"], "present")

# ── issecretvalue absent ─────────────────────────────────────────────────
g.issecretvalue = None
check("no issecretvalue: State still answers", C.State("NS.Double"), "present")
check("no issecretvalue: Call still works", tuple(C.Call("NS.Double", 2)), (True, 4))
L.execute("function issecretvalue(v) return v == SECRET end")

# ── Provider swap (G3 stand-in) ──────────────────────────────────────────
L.execute(r"""
G3_ASKED = {}
function G3_STUB(path)
    G3_ASKED[#G3_ASKED + 1] = path
    if path == "NS.Double" then return "present" end
    if path == "SECRET_GLOBAL" then return "secret" end
    return "missing"
end
""")
C.SetProvider("g3", g.G3_STUB)
check("provider name switches", C.Provider, "g3")
check("Seen resets on swap", len(list(C.Seen().keys())), 0)
check("swapped provider answers State", C.State("NS.Double"), "present")
check("swapped provider can veto a locally present path", C.State("CreateFrame"), "missing")
check("Fn honours the provider veto", C.Fn("CreateFrame"), None)
check("Call still works through the provider", tuple(C.Call("NS.Double", 5)), (True, 10))
check("provider was actually consulted", len(list(g.G3_ASKED.values())) >= 3)

L.execute('function BAD_PROVIDER(p) error("resolver down") end')
C.SetProvider("broken", g.BAD_PROVIDER)
check("an erroring provider reads missing", C.State("NS.Double"), "missing")
L.execute('function SILLY_PROVIDER(p) return "yes" end')
C.SetProvider("silly", g.SILLY_PROVIDER)
check("a nonsense answer reads missing", C.State("NS.Double"), "missing")

C.SetProvider(None, None)
check("nil restores the local provider", C.Provider, "harvest-local")
check("local provider answers again", C.State("CreateFrame"), "present")

# ── Lint: no hand-rolled detection in the harvest packs ──────────────────
HAND_ROLLED = [
    (re.compile(r"_G\s*\["), "_G[...] lookup"),
    (re.compile(r"type\s*\([^)]*\)\s*[~=]=\s*[\"']function[\"']"), "type(...) == \"function\""),
    (re.compile(r"\b([A-Z][A-Za-z_]+)\s+and\s+\1\s*\.\s*[A-Za-z_]"), "Namespace and Namespace.Fn"),
]
harvest_dir = os.path.join(ROOT, "Modules", "Harvest")
offenders = []
if os.path.isdir(harvest_dir):
    for dirpath, _, files in os.walk(harvest_dir):
        for fn in files:
            if not fn.endswith(".lua"):
                continue
            full = os.path.join(dirpath, fn)
            for lineno, line in enumerate(open(full, encoding="utf-8"), 1):
                code = line.split("--", 1)[0]
                for rx, what in HAND_ROLLED:
                    if rx.search(code):
                        offenders.append(f"{os.path.relpath(full, ROOT)}:{lineno}: {what}")
elif VERBOSE:
    print("          (Modules/Harvest/ not present yet -- lint has nothing to scan until T4)")
check("harvest packs detect APIs only through TA.Caps", offenders, [])

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
