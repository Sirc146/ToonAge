#!/usr/bin/env python3
"""Versatility percent on the Character tab.

The sheet adds GetCombatRatingBonus(index) and GetVersatilityBonus(index).
The index is CR_VERSATILITY_DAMAGE_DONE (29) or CR_VERSATILITY_DAMAGE_TAKEN
(31), not the rating amount. Passing the rating (618) to GetVersatilityBonus
reads a combat-rating id that does not exist, so the tab showed 618 rating
and 0.00%. A secret value is not added or formatted; the caller shows a dash.
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
_results = []


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if not ok or "-v" in sys.argv:
        print(f"[{' ok ' if ok else 'FAIL'}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")


def load(prelude):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(prelude)
    lua.execute((ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / "Modules/Character/Character.lua").read_text(encoding="utf-8"))
    return lua, lua.globals().ToonAge.modules.Character


PRELUDE = r"""
ToonAge = { Data = {}, modules = {}, Utils = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge.Utils.IsSecret(v)
    if type(issecretvalue) ~= "function" then return false end
    local ok, res = pcall(issecretvalue, v)
    return ok and res == true
end
calls = {}
function note(kind, index)
    calls[#calls + 1] = kind .. ":" .. tostring(index)
end
"""


def test_sheet_formula_uses_rating_index_not_amount():
    lua, ch = load(PRELUDE + r"""
CR_VERSATILITY_DAMAGE_DONE = 29
CR_VERSATILITY_DAMAGE_TAKEN = 31
GetCombatRating = function(i) note("rating", i); if i == 29 then return 618 end return 0 end
GetCombatRatingBonus = function(i)
    note("bonus", i)
    if i == 29 then return 10 end
    if i == 31 then return 5 end
    return 0
end
GetVersatilityBonus = function(i)
    note("vers", i)
    if i == 29 then return 1 end
    if i == 31 then return 0.5 end
    return 0
end
""")
    done, taken = ch.ReadVersatility()
    check("damage percent is bonus + versatility at index 29", done, 11)
    check("reduction is bonus + versatility at index 31", taken, 5.5)
    seen = lua.eval("table.concat(calls, ',')")
    check("versatility bonus asked for 29", "vers:29" in seen, True)
    check("versatility bonus asked for 31", "vers:31" in seen, True)
    check("versatility bonus is not passed the rating amount", "vers:618" in seen, False)
    check("rating bonus asked for 29", "bonus:29" in seen, True)
    check("rating bonus asked for 31", "bonus:31" in seen, True)


def test_named_constants_override_the_fallback():
    _, ch = load(PRELUDE + r"""
CR_VERSATILITY_DAMAGE_DONE = 40
CR_VERSATILITY_DAMAGE_TAKEN = 41
GetCombatRatingBonus = function(i) note("bonus", i); return i == 40 and 7 or 2 end
GetVersatilityBonus = function(i) note("vers", i); return 0 end
""")
    done, taken = ch.ReadVersatility()
    check("named done index is used", done, 7)
    check("named taken index is used", taken, 2)


def test_missing_api_is_nil_not_zero():
    _, ch = load(PRELUDE)
    done, taken = ch.ReadVersatility()
    check("no rating bonus api", done, None)
    check("no versatility bonus api", taken, None)


def test_secret_value_is_not_added():
    _, ch = load(PRELUDE + r"""
issecretvalue = function(v) return v == "secret" end
GetCombatRatingBonus = function(i) return "secret" end
GetVersatilityBonus = function(i) return 1 end
""")
    done, taken = ch.ReadVersatility()
    check("secret damage percent is not a number", done, None)
    check("secret reduction is not a number", taken, None)


def test_missing_percent_is_a_dash():
    # A Forever Mage has no versatility API. The row must show a dash,
    # not 0.00% left over from a failed call.
    src = (ROOT / "Modules/Character/Character.lua").read_text(encoding="utf-8")
    check("a missing versatility percent renders a dash", 'row.pctLbl:SetText("-")' in src, True)
    check("a missing versatility rating renders a dash", 'row.ratingLbl:SetText("-")' in src, True)


def test_half_reduction_is_gone():
    src = (ROOT / "Modules/Character/Character.lua").read_text(encoding="utf-8")
    check("damage reduction is not half the damage percent", "pct / 2" not in src, True)


def main():
    test_sheet_formula_uses_rating_index_not_amount()
    test_named_constants_override_the_fallback()
    test_missing_api_is_nil_not_zero()
    test_secret_value_is_not_added()
    test_missing_percent_is_a_dash()
    test_half_reduction_is_gone()
    passed = sum(_results)
    total = len(_results)
    print()
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
