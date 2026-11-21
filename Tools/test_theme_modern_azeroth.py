#!/usr/bin/env python3
"""
ToonAge -- Phase 1a Modern Azeroth Design Tokens & Talent Theme Wiring
======================================================================
Verifies Core/Theme.lua Option B (Modern Azeroth) skin, the three theme packs
(class default, toonage_gold, blizzard), class-colour luminance guarding and
CTA contrast floors across all nine Forever classes, glass-vs-solid opacity
boundaries, zero traffic-light controls, reduced-motion state, classic parity,
and Modules/Forever/Talents.lua focus/route token wiring.

Usage:  python3 Tools/test_theme_modern_azeroth.py [-v]
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

FOREVER_CLASSES = (
    "MAGE", "WARRIOR", "HUNTER", "ROGUE", "PRIEST",
    "WARLOCK", "DRUID", "PALADIN", "SHAMAN",
)


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def check_ge(name, got, floor):
    ok = got is not None and got >= floor
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r} (want >= {floor!r})")
    return ok


def load(with_talents=False, prelude=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
ToonAge = { Data = {}, modules = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
ToonAge.Utils = { IsSecret = function() return false end }
""")
    if prelude:
        lua.execute(prelude)
    lua.execute((ROOT / "Core/Theme.lua").read_text(encoding="utf-8"))
    if with_talents:
        lua.execute((ROOT / "Modules/Forever/Talents.lua").read_text(encoding="utf-8"))
    return lua


def rgb_tuple(tbl):
    return (round(tbl[1] * 255), round(tbl[2] * 255), round(tbl[3] * 255))


def main():
    # 1. Default boot remains classic (zero unintended drift until opted in)
    lua = load(with_talents=True)
    Theme = lua.globals().ToonAge.Theme
    Talents = lua.globals().ToonAge.modules.ForeverTalents

    check("default skin is classic", Theme.active.name, "classic")
    check("default reduced motion is false", Theme.IsReducedMotion(Theme), False)
    check("classic crown titlebar stays 34", Theme.active.metrics.titlebar_h, 34)
    check("classic tab height stays 30", Theme.active.metrics.tab_h, 30)
    check("classic talent focus stays Gilder gold", rgb_tuple(Talents.FocusColor()), (232, 179, 90))

    # Reference identity check: callers keeping table refs see in-place Sync updates
    lua.execute("savedTextPrimary = ToonAge.Theme.active.text_primary")
    lua.execute("savedTalentFocus = ToonAge.Theme.active.talent.focus")

    # 2. Switch to modern_azeroth (default pack = class, Mage)
    lua.execute('ToonAge.Theme:Select("modern_azeroth", "class", "MAGE")')
    active = Theme.active

    check("modern_azeroth skin selected", active.name, "modern_azeroth")
    check("modern_azeroth default pack is class", active.pack, "class")
    check("text_primary table identity preserved across Select", lua.eval("savedTextPrimary == ToonAge.Theme.active.text_primary"), True)
    check("talent.focus table identity preserved across Select", lua.eval("savedTalentFocus == ToonAge.Theme.active.talent.focus"), True)

    # Compact 68px crown & window metrics
    check("compact title strip is 34px", active.metrics.titlebar_h, 34)
    check("compact tab strip is 34px", active.metrics.tab_h, 34)
    check("total compact crown is 68px", active.metrics.crown_h, 68)
    check("sidebar stays 210px", active.metrics.sidebar_w, 210)
    check("next-step footer is 34px", active.metrics.footer_h, 34)
    check("concentric radii: shell 16, well 12, control 6",
          (active.geometry.radius_shell, active.geometry.radius_well, active.geometry.radius_control),
          (16, 12, 6))
    check("sheen height stays fixed 48px", active.glass.sheen_h, 48)
    check("title icon uses ToonAge hourglass mark", "logo_mark_32.tga" in active.tex.title_icon, True)

    # Hard guardrails: no macOS traffic lights, glass on chrome only, solid content wells
    check("traffic lights explicitly forbidden", active.controls.traffic_lights, False)
    check("glass shell fill alpha is translucent (0.78)", round(active.glass.shell_fill[4], 2), 0.78)
    check("glass sheet fill alpha is heavier than shell (0.86)", active.glass.sheet_fill[4] > active.glass.shell_fill[4], True)
    check("glass capsule alpha is 0.68", round(active.glass.capsule_fill[4], 2), 0.68)
    check_ge("content well is solid dark (>= 0.94 alpha)", active.surface.content[4], 0.94)
    check_ge("sidebar column is solid dark (>= 0.94 alpha)", active.surface.sidebar[4], 0.94)
    check_ge("footer dock is solid dark (>= 0.96 alpha)", active.surface.footer[4], 0.96)
    check_ge("inner cards are solid dark (>= 0.94 alpha)", active.surface.card[4], 0.94)

    # Primary text contrast on solid dark content well must meet AAA (>= 7:1)
    primary_contrast = lua.eval("ToonAge.Theme.ContrastRatio(ToonAge.Theme.active.text_primary, ToonAge.Theme.active.surface.content)")
    check_ge("text_primary on solid content well >= 7.0 WCAG AAA", primary_contrast, 7.0)

    # Mage class accent flows into accent.primary and Talents.FocusColor / PlanRouteColor
    check("Mage accent is #3FC7EB", rgb_tuple(active.accent.primary), (63, 199, 235))
    check("Talents.FocusColor tracks Mage accent", rgb_tuple(Talents.FocusColor()), (63, 199, 235))
    check("Talents.PlanRouteColor tracks Mage accent", rgb_tuple(Talents.PlanRouteColor()), (63, 199, 235))
    # Classic/Retail talent node states stay untouched (Gilder §21)
    check("talent available state stays #46C86A", rgb_tuple(active.talent.available), (70, 200, 106))
    check("talent partial state stays #F5F7FA", rgb_tuple(active.talent.partial), (245, 247, 250))
    check("talent maxed state stays #FBE08F", rgb_tuple(active.talent.maxed), (251, 224, 143))
    check("talent locked state stays #7A828C", rgb_tuple(active.talent.locked), (122, 130, 140))

    # 3. All 9 Forever classes: luminance lift for dark classes + >= 7:1 CTA text contrast
    for cls in FOREVER_CLASSES:
        lua.execute(f'ToonAge.Theme:SelectPack("class", "{cls}")')
        cta_ratio = lua.eval("ToonAge.Theme.ContrastRatio(ToonAge.Theme.active.accent.cta_text, ToonAge.Theme.active.accent.cta_bg)")
        ring_ratio = lua.eval("ToonAge.Theme.ContrastRatio(ToonAge.Theme.active.accent.primary, ToonAge.Theme.active.surface.content)")
        check_ge(f"{cls}: CTA text contrast >= 7.0", cta_ratio, 7.0)
        check_ge(f"{cls}: accent ring on dark well >= 4.5", ring_ratio, 4.5)

    # Specifically verify Shaman (#0070DD, low luminance) is lifted above raw blue
    lua.execute('ToonAge.Theme:SelectPack("class", "SHAMAN")')
    shaman_rgb = rgb_tuple(Theme.active.accent.primary)
    check("Shaman low-luminance blue is lifted on red channel (> 0)", shaman_rgb[0] > 0, True)
    check("Shaman blue stays recognizably blue-dominant", shaman_rgb[2] > shaman_rgb[1] and shaman_rgb[1] > shaman_rgb[0], True)

    # 4. ToonAge Gold theme pack (Gilder #E8B35A + dark text_on_gold)
    lua.execute('ToonAge.Theme:SelectPack("toonage_gold")')
    check("toonage_gold pack selected", Theme.active.pack, "toonage_gold")
    check("toonage_gold accent is #E8B35A", rgb_tuple(Theme.active.accent.primary), (232, 179, 90))
    check("toonage_gold CTA text is #1A0E02", rgb_tuple(Theme.active.accent.cta_text), (26, 14, 2))
    gold_cta_ratio = lua.eval("ToonAge.Theme.ContrastRatio(ToonAge.Theme.active.accent.cta_text, ToonAge.Theme.active.accent.cta_bg)")
    check_ge("toonage_gold CTA text contrast >= 7.0", gold_cta_ratio, 7.0)
    check("Talents.FocusColor switches to Gilder gold under toonage_gold", rgb_tuple(Talents.FocusColor()), (232, 179, 90))

    # 5. Blizzard Modern theme pack (#111419 @ 0.84 + warm bronze rim + #F0C45A)
    lua.execute('ToonAge.Theme:SelectPack("blizzard")')
    check("blizzard pack selected", Theme.active.pack, "blizzard")
    check("blizzard accent is #F0C45A", rgb_tuple(Theme.active.accent.primary), (240, 196, 90))
    check("blizzard shell alpha is 0.84", round(Theme.active.glass.shell_fill[4], 2), 0.84)
    blizz_cta_ratio = lua.eval("ToonAge.Theme.ContrastRatio(ToonAge.Theme.active.accent.cta_text, ToonAge.Theme.active.accent.cta_bg)")
    check_ge("blizzard CTA text contrast >= 7.0", blizz_cta_ratio, 7.0)

    # 6. CUSTOM_CLASS_COLORS > RAID_CLASS_COLORS > fallback priority order
    lua_custom = load(prelude="""
CUSTOM_CLASS_COLORS = { MAGE = { r = 0.20, g = 0.80, b = 0.60 } }
RAID_CLASS_COLORS = { MAGE = { r = 0.10, g = 0.10, b = 0.90 } }
""")
    lua_custom.execute('ToonAge.Theme:Select("modern_azeroth", "class", "MAGE")')
    check("CUSTOM_CLASS_COLORS takes precedence over RAID_CLASS_COLORS",
          rgb_tuple(lua_custom.globals().ToonAge.Theme.active.accent.primary), (51, 204, 153))

    lua_raid = load(prelude="""
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.75, b = 0.95 } }
""")
    lua_raid.execute('ToonAge.Theme:Select("modern_azeroth", "class", "MAGE")')
    check("RAID_CLASS_COLORS takes precedence over fallback table",
          rgb_tuple(lua_raid.globals().ToonAge.Theme.active.accent.primary), (64, 191, 242))

    # 7. Reduced motion persists across skin switches
    lua.execute("ToonAge.Theme:SetReducedMotion(true)")
    check("reduced motion enabled", Theme.IsReducedMotion(Theme), True)
    check("active.motion.reduced is true", Theme.active.motion.reduced, True)
    lua.execute('ToonAge.Theme:Select("classic")')
    check("returning to classic restores classic name", Theme.active.name, "classic")
    check("returning to classic clears modern-only controls table", Theme.active.controls, None)
    check("reduced motion survives skin switch", Theme.IsReducedMotion(Theme), True)
    check("returning to classic restores gold talent focus", rgb_tuple(Talents.FocusColor()), (232, 179, 90))

    # 8. Unknown skin/pack fail closed cleanly
    lua.execute('ToonAge.Theme:Select("nonexistent_skin")')
    check("unknown skin falls back to classic", Theme.active.name, "classic")
    lua.execute('ToonAge.Theme:Select("modern_azeroth", "unknown_pack", "MAGE")')
    check("unknown pack falls back to class", Theme.active.pack, "class")

    passed = sum(1 for r in _results if r)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
