#!/usr/bin/env python3
"""Heirloom cap stays unknown until the 12.x returns are verified.

GetHeirloomMaxUpgradeLevel and GetHeirloomInfo are pcalled. An error, nil,
a secret, or a normal number is not a player level. The warning does not fire.
/ta heirlooms probe prints the raw returns for one equipped heirloom.
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
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


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, Data = { StatWeights = {} }, Utils = {}, LOG = { OUTPUT = 1, WARN = 3 }, charDB = {} }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        function ToonAge:GetModule(name) return self.modules[name] end
        function ToonAge:RegisterEvent() end
        function ToonAge:Raw() end
        ToonAge.Utils.IsSecret = function(v) return v == "secret" end
        ToonAge.Compat = {
            GetItemInfo = function(link)
                if link == "item:9" then return "Tattered", "item:9", 7 end
                return "Other", link, 4
            end,
            GetItemInfoInstant = function(link)
                local id = tostring(link):match("item:(%d+)")
                return id and tonumber(id) or nil
            end,
        }
        NOTES = {}
        function ToonAge:Raw(_, text) NOTES[#NOTES + 1] = text end
        UnitLevel = function() return 80 end
        GetInventoryItemLink = function(_, slot)
            if slot == 1 then return "item:9" end
        end
    """)
    lua.execute((ROOT / "Modules/Automation/RoleMorph.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
        local RM = ToonAge.modules.RoleMorph
        local function warnCount()
            local n = 0
            for _, line in ipairs(NOTES) do
                if tostring(line):find("stopped scaling", 1, true) then n = n + 1 end
            end
            return n
        end
        local function run(maxFn, infoFn)
            NOTES = {}
            CALLS = 0
            local function count(fn)
                return function(...)
                    CALLS = CALLS + 1
                    return fn(...)
                end
            end
            C_Heirloom = {
                GetHeirloomMaxUpgradeLevel = count(maxFn),
                GetHeirloomInfo = count(infoFn or function() return "Name", "INVTYPE_HEAD" end),
            }
            local ok, cap = pcall(RM.GetHeirloomCap, "item:9")
            RAN, CAP = ok, cap
            local okCheck = pcall(RM.CheckHeirlooms, RM)
            CHECK_OK, WARNS, CAP_CALLS = okCheck, warnCount(), CALLS
            local probe = table.concat(RM.HeirloomProbe(), "\n")
            PROBE = probe
        end
        run(function() error("boom") end, function() error("info-broke") end)
        ERR_OK, ERR_CAP, ERR_CHECK, ERR_WARNS = RAN, CAP, CHECK_OK, WARNS
        ERR_PROBE = PROBE
        run(function() return nil end)
        NIL_CAP, NIL_WARNS = CAP, WARNS
        NIL_PROBE = PROBE
        run(function() return "secret" end)
        SEC_CAP, SEC_WARNS = CAP, WARNS
        SEC_PROBE = PROBE
        run(function() return 3 end, function()
            return "Dreadmist", "INVTYPE_HEAD", false, 136, 2, "source", false, 29, 1, 49
        end)
        NUM_CAP, NUM_WARNS = CAP, WARNS
        NUM_PROBE = PROBE
    """)
    check("an erroring upgrade call does not escape", lua.eval("ERR_OK"), True)
    check("the cap does not call C_Heirloom", lua.eval("CAP_CALLS"), 0)
    check("an erroring upgrade call is unknown", lua.eval("ERR_CAP"), None)
    check("check still runs after an error", lua.eval("ERR_CHECK"), True)
    check("an error does not warn", lua.eval("ERR_WARNS"), 0)
    err_probe = lua.eval("ERR_PROBE") or ""
    check("probe records the upgrade error", "error:" in err_probe and "boom" in err_probe)
    check("probe records the info error", "info-broke" in err_probe)
    check("a nil upgrade is unknown", lua.eval("NIL_CAP"), None)
    check("a nil upgrade does not warn", lua.eval("NIL_WARNS"), 0)
    check("probe records a nil upgrade", "GetHeirloomMaxUpgradeLevel(9) -> nil" in (lua.eval("NIL_PROBE") or ""))
    check("a secret upgrade is unknown", lua.eval("SEC_CAP"), None)
    check("a secret upgrade does not warn", lua.eval("SEC_WARNS"), 0)
    check("probe records a secret upgrade", "GetHeirloomMaxUpgradeLevel(9) -> secret" in (lua.eval("SEC_PROBE") or ""))
    check("a normal tier count is still unknown", lua.eval("NUM_CAP"), None)
    check("a normal tier count does not warn", lua.eval("NUM_WARNS"), 0)
    probe = lua.eval("NUM_PROBE") or ""
    check("probe prints the tier count raw", "GetHeirloomMaxUpgradeLevel(9) -> 3" in probe)
    check("probe prints every info return", "Dreadmist, INVTYPE_HEAD, false, 136, 2, source, false, 29, 1, 49" in probe)
    check("probe says the cap is unverified", "UNVERIFIED on 12.x" in probe)

    manifest = (ROOT / "Data/Retail/ApiManifest.lua").read_text(encoding="utf-8")
    check("retail manifest drops the GetSpellInfo global", '["GetSpellInfo"]' not in manifest)
    check("retail manifest drops the GetSpellCooldown global", '["GetSpellCooldown"]' not in manifest)
    info = manifest.split('["GetItemInfo"]', 1)[1].split("},", 1)[0]
    check("retail GetItemInfo no longer cites Utils", "Core/Utils.lua" not in info)
    harness = (ROOT / "Modules/Infrastructure/TestHarness.lua").read_text(encoding="utf-8")
    check("self-test prints the build first", harness.index('build %s') < harness.index("Self-test running"))
    tocs = [p.name for p in ROOT.glob("ToonAge*.toc")]
    for name in tocs:
        text = (ROOT / name).read_text(encoding="utf-8")
        check(f"{name} is 2.0.0-dev.2", "## Version: 2.0.0-dev.2" in text)

    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
