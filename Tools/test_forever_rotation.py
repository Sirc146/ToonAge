#!/usr/bin/env python3
"""Forever Mage next-spell suggestion.

The icon is a suggestion. It never casts, never glows an action button, and
the priority is the Forever Frost leveling guide already cited by the Mage
guidance module:

    https://www.icy-veins.com/wow-forever/frost-mage-leveling

Spell ids come from the Forever data files the picker is given. A secret or
nil cooldown, mana, or aura value leaves that rule unknown.

Usage:  python3 Tools/test_forever_rotation.py [-v]
"""
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

SUGGEST = ROOT / "Modules/Forever/MageSuggest.lua"
HARNESS = ROOT / "Modules/Infrastructure/TestHarness.lua"
COMPAT = ROOT / "Core/Compat/API.lua"
CAMELOT = ROOT / "ToonAge_Camelot.toc"
PROTECTED = (
    "CastSpellByName",
    "CastSpellByID",
    "CastSpell",
    "UseAction",
    "RunMacro",
    "SecureActionButtonTemplate",
    "ActionButton_ShowOverlayGlow",
    "LibButtonGlow",
    "SetOverrideBinding",
    "loadstring",
)


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(path):
    return path.read_text(encoding="utf-8")


def listed(toc):
    files = []
    for line in read(toc).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        s = s.split("[")[0].strip().replace("\\", "/")
        if s.endswith(".lua"):
            files.append(s)
    return files


def code_only(text):
    """Drop line comments so a ban listed in a comment is not a call."""
    return "\n".join(re.sub(r"--.*$", "", line) for line in text.splitlines())


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
    ToonAge = { modules = {}, Data = {} }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    """)
    lua.execute(read(SUGGEST))
    return lua


def main():
    check("suggestion module exists", SUGGEST.exists(), True)
    if not SUGGEST.exists():
        print(f"[FAIL] 0/{len(_results)} passed; module missing.")
        return 1

    src = read(SUGGEST)
    code = code_only(src)
    for name in PROTECTED:
        check(f"rotation code has no {name}", name not in code, True)
    check("no secure click-to-cast template", "SecureActionButton" not in code, True)
    check("no action-button glow", "OverlayGlow" not in code and "ButtonGlow" not in code, True)

    check("cooldown read is guarded", "GetSpellCooldown" in src, True)
    check("modern cooldown is named before the legacy one",
          src.find("C_Spell.GetSpellCooldown") < src.find("GetSpellCooldown"), True)
    check("aura read names C_UnitAuras", "C_UnitAuras" in src, True)
    check("aura read names AuraUtil", "AuraUtil" in src, True)
    check("mana read uses UnitPower", "UnitPower" in src, True)
    check("mana read uses UnitPowerMax", "UnitPowerMax" in src, True)
    check("secret-value guard names issecretvalue", "issecretvalue" in src, True)
    check("secret-value guard names canaccessvalue", "canaccessvalue" in src, True)
    check("learned check names IsPlayerSpell", "IsPlayerSpell" in src, True)
    check("learned check names IsSpellKnown", "IsSpellKnown" in src, True)
    check("retail Ice Lance id is not invented here", "30455" not in src, True)

    compat = read(COMPAT)
    check("Compat learns spells by IsPlayerSpell", "IsPlayerSpell" in compat, True)
    check("Compat learns spells by IsSpellKnown", "IsSpellKnown" in compat, True)
    check("Compat reads UnitPower", "UnitPower" in compat, True)
    check("Compat reads auras", "GetAuraDataByIndex" in compat or "ForEachAura" in compat, True)

    camelot = listed(CAMELOT)
    check("Camelot TOC lists the suggestion", "Modules/Forever/MageSuggest.lua" in camelot, True)
    for toc in (ROOT / "ToonAge_Mainline.toc", ROOT / "ToonAge.toc"):
        check(f"{toc.name} does not list the suggestion",
              "Modules/Forever/MageSuggest.lua" not in listed(toc), True)

    harness = read(HARNESS)
    check("self-test registers ADDON_ACTION_BLOCKED", "ADDON_ACTION_BLOCKED" in harness, True)
    check("self-test registers ADDON_ACTION_FORBIDDEN", "ADDON_ACTION_FORBIDDEN" in harness, True)
    check("self-test reports a block count", "rotation frame blocked=" in harness, True)
    check("suggestion frame also watches the block events",
          "ADDON_ACTION_BLOCKED" in src and "ADDON_ACTION_FORBIDDEN" in src, True)

    lua = runtime()
    lua.execute(read(ROOT / "Data/Forever/SpellRanks.lua"))
    lua.execute(read(ROOT / "Data/Forever/Spells.lua"))
    lua.execute(read(ROOT / "Data/Forever/Talents.lua"))
    lua.execute(r"""
        local M = ToonAge.modules.ForeverMageSuggest
        SPELLS = M.BuildSpells(
            ToonAge.Data.ForeverSpellRanks,
            ToonAge.Data.ForeverSpells.MAGE,
            ToonAge.Data.ForeverTalents.MAGE)
        function ids(key)
            local row = SPELLS[key]
            if not row then return "" end
            local t = {}
            for _, id in ipairs(row.ids) do t[#t + 1] = tostring(id) end
            return table.concat(t, ",")
        end
        function suggest(state)
            local row = M.Suggest(state, SPELLS)
            if not row then return "" end
            return tostring(row.spellID) .. "|" .. row.name
        end
        function known_map(list)
            local t = {}
            for _, id in ipairs(list) do t[id] = "yes" end
            return t
        end
        READY = {}
        for _, row in pairs(SPELLS) do
            for _, id in ipairs(row.ids) do READY[id] = "ready" end
        end
        function with_cd(over)
            local t = {}
            for id, st in pairs(READY) do t[id] = st end
            for id, st in pairs(over or {}) do t[id] = st end
            return t
        end
    """)

    check("Frostbolt ranks come from SpellRanks",
          lua.eval('ids("frostbolt")'), "116,205,837,7322,8406,8407,8408")
    check("Shoot id comes from Spells", lua.eval('ids("shoot")'), "5019")
    check("Ice Lance id is the measured talent spell", lua.eval('ids("iceLance")'), "1312002")
    check("no retail Ice Lance id in the catalog",
          "30455" not in (lua.eval('ids("iceLance")') or ""), True)

    # All measured ranks known, everything ready, at range, mana fine.
    lua.execute(r"""
        BASE = {
            class = "MAGE",
            known = known_map({116, 205, 2136, 122, 5019, 168, 1459}),
            cooldown = with_cd(),
            mana = "ok",
            melee = false,
        }
        AT_RANGE = suggest(BASE)
        NOVA_DOWN = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd({ [122] = "down", [116] = "down", [205] = "down" }),
            mana = "ok",
            melee = false,
        })
        LOW_MANA = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd(),
            mana = "low",
            melee = false,
        })
        LOW_NO_WAND = suggest({
            class = "MAGE",
            known = known_map({116, 2136}),
            cooldown = with_cd(),
            mana = "low",
            melee = true,
        })
        MELEE = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd(),
            mana = "ok",
            melee = true,
        })
        MELEE_NOVA_DOWN = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd({ [122] = "down" }),
            mana = "ok",
            melee = true,
        })
        UNKNOWN_MANA = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd(),
            mana = "unknown",
            melee = false,
        })
        NOT_MAGE = suggest({ class = "WARRIOR", known = BASE.known, cooldown = with_cd(), mana = "ok" })
        ARMOR = suggest({
            class = "MAGE",
            known = BASE.known,
            cooldown = with_cd(),
            mana = "ok",
            melee = false,
            buffs = {},
        })
    """)
    check("at range the suggestion is Frostbolt", lua.eval("AT_RANGE"), "205|Frostbolt")
    check("Frostbolt on cooldown falls through to Fire Blast", lua.eval("NOVA_DOWN"), "2136|Fire Blast")
    check("low mana suggests the wand", lua.eval("LOW_MANA"), "5019|Shoot")
    check("low mana with no wand suggests nothing", lua.eval("LOW_NO_WAND"), "")
    check("an enemy in melee suggests Frost Nova", lua.eval("MELEE"), "122|Frost Nova")
    check("melee with Frost Nova down suggests Fire Blast", lua.eval("MELEE_NOVA_DOWN"), "2136|Fire Blast")
    check("unknown mana does not force the wand", lua.eval("UNKNOWN_MANA"), "205|Frostbolt")
    check("other classes get no suggestion", lua.eval("NOT_MAGE"), "")
    check("a missing armor buff is suggested first", lua.eval("ARMOR"), "168|Frost Armor")

    lua.execute(r"""
        issecretvalue = function(v) return v == "SECRET" end
        canaccessvalue = function(v) return v ~= "LOCKED" end
        local M = ToonAge.modules.ForeverMageSuggest
        MANA_SECRET = M.ManaState("SECRET", 100)
        MANA_LOCKED = M.ManaState(10, "LOCKED")
        MANA_LOW = M.ManaState(10, 100)
        MANA_OK = M.ManaState(50, 100)
        CD_SECRET = M.CooldownState("SECRET", 0)
        CD_READY = M.CooldownState(0, 0)
        CD_DOWN = M.CooldownState(10, 8)
        CD_GCD = M.CooldownState(10, 1.5)
        issecretvalue = nil
        canaccessvalue = nil
        MANA_PLAIN = M.ManaState(0, 100)
    """)
    check("a secret mana value is unknown", lua.eval("MANA_SECRET"), "unknown")
    check("an inaccessible mana value is unknown", lua.eval("MANA_LOCKED"), "unknown")
    check("a small mana fraction is low", lua.eval("MANA_LOW"), "low")
    check("a healthy mana fraction is ok", lua.eval("MANA_OK"), "ok")
    check("a secret cooldown is unknown", lua.eval("CD_SECRET"), "unknown")
    check("a zero cooldown is ready", lua.eval("CD_READY"), "ready")
    check("a long cooldown is down", lua.eval("CD_DOWN"), "down")
    check("the global cooldown still counts as ready", lua.eval("CD_GCD"), "ready")
    check("empty mana is low when the guard is absent", lua.eval("MANA_PLAIN"), "low")

    passed = sum(_results)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
