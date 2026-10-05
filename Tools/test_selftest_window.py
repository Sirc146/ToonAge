#!/usr/bin/env python3
"""Self-test report always ends in a selectable window, never in chat (S7, 2026-10-04).

TestHarness is sometimes dropped onto an install older than 2026-09-22, which has
no TA:ShowCopyWindow. The report used to fall back to printing every line to chat,
where it cannot be selected or copied. TestHarness now carries its own copy window.

This test lifts ShowReport out of TestHarness.lua and runs it under Lua 5.1 with a
recording CreateFrame mock:

  * ShowCopyWindow present and working  -> used, no harness window built
  * ShowCopyWindow missing              -> harness window built, shown, colour-free,
                                           Esc-closable, reused on the next call
  * ShowCopyWindow present but throws   -> harness window used instead
  * _Finish has no chat-print path left

Usage:  python Tools/test_selftest_window.py [-v]
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


src = open(os.path.join(ROOT, "Modules/Infrastructure/TestHarness.lua"), encoding="utf-8").read()

# Lift Plain + the report window block (reportWindow local through ShowReport's end).
plain = re.search(r"local function Plain\(text\)\n.*?\nend\n", src, re.S)
block = re.search(r"local reportWindow\nlocal function ShowReport\(title, text\)\n.*?\nend\n", src, re.S)
check("Plain() found", plain is not None)
check("ShowReport() found", block is not None)

finish = src[src.index("function H:_Finish("):]
finish = finish[:finish.index("\nend\n")]
check("_Finish routes the report through ShowReport", "ShowReport(" in finish)
check("_Finish no longer prints the report to chat line by line",
      re.search(r"for\s+_,\s*l\s+in\s+ipairs\(lines\)\s+do\s+print", finish) is None)

MOCKS = r"""
created = {}
UIParent = {}
ChatFontNormal = {}
UISpecialFrames = {}
local function Mock(kind, name)
    local f = { _kind = kind, _name = name, _shown = false, _text = nil }
    local mt = { __index = function(t, k)
        return function(self, ...) return self end   -- permissive: every method chains
    end }
    setmetatable(f, mt)
    f.Show = function(self) self._shown = true end
    f.Hide = function(self) self._shown = false end
    f.IsShown = function(self) return self._shown end
    f.SetText = function(self, t) self._text = t end
    f.GetText = function(self) return self._text end
    f.CreateFontString = function(self) return Mock("FontString") end
    return f
end
function CreateFrame(kind, name, parent, template)
    local f = Mock(kind, name)
    created[#created + 1] = f
    return f
end
TA = {}
"""

PROBE = r"""
return function(mode)
    created = {}
    shownBy = nil
    if mode == "works" then
        TA.ShowCopyWindow = function(self, title, text) shownBy = "ui" end
    elseif mode == "throws" then
        TA.ShowCopyWindow = function(self, title, text) error("boom") end
    else
        TA.ShowCopyWindow = nil
    end
    local where = ShowReport("ToonAge Self-Test", "|cFFFF4444FAIL|r  one\nPASS  two")
    local frame, edit
    for _, f in ipairs(created) do
        if f._name == "ToonAgeSelfTestWindow" then frame = f end
        if f._kind == "EditBox" then edit = f end
    end
    return where, #created, frame ~= nil and frame._shown or false,
           edit and edit._text or nil, shownBy, #UISpecialFrames,
           reportWindow ~= nil and reportWindow._shown or false
end
"""

if plain and block:
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(MOCKS)
    # Plain + ShowReport as globals in the mock world (strip `local` on the two
    # definitions so the probe can reach them).
    code = plain.group(0).replace("local function Plain", "function Plain", 1)
    code += block.group(0).replace("local reportWindow\nlocal function ShowReport",
                                   "reportWindow = nil\nfunction ShowReport", 1)
    L.execute(code)
    probe = L.execute(PROBE)

    where, n, shown, text, by, nspecial, _ = probe("works")
    check("working ShowCopyWindow is used", by, "ui")
    check("working ShowCopyWindow: no harness window built", n, 0)
    check("working ShowCopyWindow: chat line says copy window", where, "full report in the copy window")

    where, n, shown, text, by, nspecial, _ = probe("missing")
    check("missing ShowCopyWindow: harness window built", n > 0)
    check("missing ShowCopyWindow: window shown", shown)
    check("missing ShowCopyWindow: colour codes stripped", text, "FAIL  one\nPASS  two")
    check("missing ShowCopyWindow: Esc-closable", nspecial, 1)
    check("missing ShowCopyWindow: chat line names the fallback",
          "harness's own" in str(where))

    where, n, shown, text, by, nspecial, reused_shown = probe("missing")
    check("second run reuses the window (no new frames)", n, 0)
    check("second run: reused window shown", reused_shown)
    check("second run: not registered twice for Esc", nspecial, 1)

    where, n, shown, text, by, nspecial, reused_shown = probe("throws")
    check("throwing ShowCopyWindow falls back to the harness window", reused_shown)
    check("throwing ShowCopyWindow: chat line names the fallback", "harness's own" in str(where))

passed = sum(_res)
total = len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
