"""Compare theme tokens with the literals they replaced at bccb4cf.

A swap is one old literal site. The classic token has to compare equal in
Lua 5.1 (the same parser WoW uses), the old line has to be in that commit's
file, and the new file has to have dropped that line. An extra channel on a
token is allowed only when it is 1, which is the alpha the old call already
passed or defaulted.
"""

import subprocess
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
# Short name bccb4cf. CI clones are shallow, and a short id is not a remote
# ref, so the fetch uses the full commit.
BASE = "bccb4cf6f3b6c791b63dc876356ee298505544a5"


def check(name, got, want=True):
    ok = got == want
    if not ok:
        print(f"[ FAIL ] {name}")
        print(f"          got:  {got!r}")
        print(f"          want: {want!r}")
    return ok


def _git(*args):
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        check=False, capture_output=True, text=True,
    )


def file_at_base(rel):
    """The file as it was at bccb4cf. Fetch that commit if this clone is shallow."""
    if _git("cat-file", "-e", f"{BASE}^{{commit}}").returncode != 0:
        fetched = _git("fetch", "--depth=1", "origin", BASE)
        if fetched.returncode != 0 or _git("cat-file", "-e", f"{BASE}^{{commit}}").returncode != 0:
            raise RuntimeError(
                "bccb4cf is not in this clone and could not be fetched. "
                + fetched.stderr.strip()
            )
    shown = _git("show", f"{BASE}:{rel}")
    if shown.returncode != 0:
        raise RuntimeError(shown.stderr.strip())
    return shown.stdout


def run(label, rel, swaps):
    """swaps: (token path under Theme.active, Lua literal, old source snippet)."""
    results = []
    old = file_at_base(rel)
    new = (ROOT / rel).read_text(encoding="utf-8")
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    lua.execute((ROOT / "Core/Theme.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
    local function dig(path)
        local t = ToonAge.Theme.skins.classic
        for part in string.gmatch(path, "[^%.]+") do
            t = t[part]
            if t == nil then return nil end
        end
        return t
    end
    local function same(got, expect)
        if type(expect) ~= "table" then
            return got == expect
        end
        if type(got) ~= "table" then return false end
        for i = 1, #expect do
            if got[i] ~= expect[i] then return false end
        end
        for i = #expect + 1, #got do
            if got[i] ~= 1 then return false end
        end
        return true
    end
    function CheckSwap(path, literal)
        local got = dig(path)
        local expect = literal
        if not same(got, expect) then
            return false
        end
        -- active is a copy of classic, so the table the style file reads matches too
        local live = ToonAge.Theme.active
        for part in string.gmatch(path, "[^%.]+") do
            live = live[part]
        end
        return same(live, expect)
    end
    """)
    for token, literal, snippet in swaps:
        in_old = old.count(snippet)
        in_new = new.count(snippet)
        results.append(check(
            f"{label}: bccb4cf still has {snippet!r}",
            in_old > 0, True,
        ))
        results.append(check(
            f"{label}: current file dropped {snippet!r}",
            in_new, 0,
        ))
        # Compare inside Lua so 0.92 == 0.92 uses WoW's parser, not Python's.
        lua.execute(
            "RESULT = CheckSwap([===[" + token + "]===], " + literal + ")"
        )
        results.append(check(
            f"{label}: classic {token} == {literal}",
            lua.eval("RESULT") == True, True,
        ))

    passed = sum(1 for ok in results if ok)
    total = len(results)
    sites = len(swaps)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed ({sites} {label} swaps).")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed ({sites} swaps).")
    return 1
