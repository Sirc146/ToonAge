#!/usr/bin/env python3
"""An abbreviated /ta command uses the same module gate as an exact one.

The exact path refuses a module that is off, skipped by Safe Mode, or absent
from this client. The prefix path used to call the handler anyway, so /ta mis
could run a module that /ta missed had just refused. Both paths share
RunModuleSlash.
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_onboarding import PRELUDE, _read  # noqa: E402

VERBOSE = "-v" in sys.argv
_results = []


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def boot():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(r"""
        ToonAgeDB = {}
        local TA = ToonAge
        TA:InitDB()
        _hits = {}
        local function mod(name, cmd, flags)
            local m = {
                SlashCommands = {
                    [cmd] = function(self, args)
                        _hits[#_hits + 1] = name .. ":" .. cmd .. ":" .. tostring(args)
                    end,
                },
            }
            for k, v in pairs(flags or {}) do m[k] = v end
            TA.modules[name] = m
        end
        mod("OffMod", "zzmissed", { _disabled = true })
        mod("SafeMod", "zzsafeway", { _disabled = true, _safeSkipped = true })
        mod("WrongMod", "zzforever", {
            _disabled = true,
            _profileSkipped = true,
            _profileReason = "wrong build for this client",
        })
        mod("LiveMod", "zzarrow", {})
        function Hits()
            local out = {}
            for i = 1, #_hits do out[i] = _hits[i] end
            return table.concat(out, "|")
        end
        function Printed()
            local out = {}
            for i = 1, #_printed do out[#out + 1] = _printed[i] end
            return table.concat(out, "\n")
        end
        function Run(msg)
            _printed = {}
            _hits = {}
            TA:SlashCommand(msg)
        end
    """)
    return lua


def main():
    lua = boot()
    run = lua.eval("Run")
    hits = lua.eval("Hits")
    printed = lua.eval("Printed")

    run("zzmissed extra")
    check("exact command does not run a disabled module", hits(), "")
    check("exact command names the module",
          "belongs to OffMod, which is not running here (switched off)." in printed())

    run("zzm extra")
    check("abbreviation does not run a disabled module", hits(), "")
    check("abbreviation uses the exact-match message",
          "/ta zzmissed belongs to OffMod, which is not running here (switched off)." in printed())

    run("zzsafe")
    check("abbreviation does not run a Safe Mode module", hits(), "")
    check("Safe Mode abbreviation explains itself",
          "/ta zzsafeway belongs to SafeMod, which is not running here (switched off)." in printed())

    run("zzf")
    check("abbreviation does not run a wrong-client module", hits(), "")
    check("wrong-client abbreviation names the reason",
          "/ta zzforever belongs to WrongMod, which is not running here (wrong build for this client)." in printed())

    run("zza 12")
    check("abbreviation still runs a live module", hits(), "LiveMod:zzarrow:12")
    run("zzarrow 9")
    check("exact command still runs a live module", hits(), "LiveMod:zzarrow:9")

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
