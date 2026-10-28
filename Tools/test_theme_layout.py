#!/usr/bin/env python3
"""Layout tokens match the literals they replaced at bccb4cf.

Profession colours stay literals and are not listed. Comparison is in Lua 5.1
against Core/Layout.lua at bccb4cf. A token may be one channel longer than the
old literal only when the extra channel is 1.

Usage:  python3 Tools/test_theme_layout.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from theme_literal_check import run

SWAPS = [
    ("text_primary", "{ 0.92, 0.90, 0.87 }", "L.C_PRIMARY   = { 0.92, 0.90, 0.87 }"),
    ("text_secondary", "{ 0.62, 0.59, 0.55 }", "L.C_SECONDARY = { 0.62, 0.59, 0.55 }"),
    ("text_accent", "{ 0.40, 0.75, 1.00 }", "L.C_ACCENT    = { 0.40, 0.75, 1.00 }"),
    ("text_success", "{ 0.30, 0.92, 0.40 }", "L.C_SUCCESS   = { 0.30, 0.92, 0.40 }"),
    ("text_warning", "{ 1.00, 0.65, 0.20 }", "L.C_WARNING   = { 1.00, 0.65, 0.20 }"),
    ("text_danger", "{ 1.00, 0.35, 0.30 }", "L.C_DANGER    = { 1.00, 0.35, 0.30 }"),
    ("gold_heading", "{ 1.00, 0.82, 0.00 }", "L.C_HEADER    = { 1.00, 0.82, 0.00 }"),
    ("text_dim", "{ 0.45, 0.43, 0.40 }", "L.C_DIM       = { 0.45, 0.43, 0.40 }"),
    ("stat_base", "{ 0.24, 0.44, 0.60 }", "L.C_STAT_BASE = { 0.24, 0.44, 0.60 }"),
    ("stat_gear", "{ 0.40, 0.75, 1.00 }", "L.C_STAT_GEAR = { 0.40, 0.75, 1.00 }"),
    ("metrics.pad", "14", "L.PAD  = 14"),
    ("metrics.rpad", "8", "L.RPAD = 8"),
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'local FONT = "Fonts\\\\FRIZQT__.TTF"'),
    ("mono", r'"Fonts\\ARIALN.TTF"', 'local MONO = "Fonts\\\\ARIALN.TTF"'),
    ("code.secret", '"|cFF6E6A62"', '"|cFF6E6A62hidden|r"'),
    ("metrics.type_body", "10", 'fs:SetFont(FONT, 10, "")'),
    ("metrics.type_body", "10", 'r:SetFont(FONT, 10, "")'),
    ("metrics.type_body", "10", "opts.font or FONT, opts.size or 10, opts.flags or \"\""),
    ("layout_rule", "{ 0.30, 0.28, 0.22, 0.60 }", "line:SetColorTexture(0.30, 0.28, 0.22, 0.60)"),
    ("bar_track_bg", "{ 0.10, 0.09, 0.08, 1.00 }",
     "TA._ApplyBackdrop(track, 0.10, 0.09, 0.08, 1.00, 0.28, 0.26, 0.22, 1.00)"),
    ("bar_track_edge", "{ 0.28, 0.26, 0.22, 1.00 }",
     "TA._ApplyBackdrop(track, 0.10, 0.09, 0.08, 1.00, 0.28, 0.26, 0.22, 1.00)"),
    ("bar_fill_a", "0.90", "fill:SetColorTexture(rgb[1], rgb[2], rgb[3], 0.90)"),
    ("cap_dim", "0.55", "c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 0.85"),
    ("cap_dim_a", "0.85", "c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 0.85"),
    ("gilder_gold", "{ 0.910, 0.702, 0.353, 1 }", "card._tickMark:SetColorTexture(0.910, 0.702, 0.353, 1)"),
    ("bar_fill_a", "0.90", "fill:SetColorTexture(cBase[1], cBase[2], cBase[3], 0.90)"),
    ("bar_fill_a", "0.90", "extra:SetColorTexture(g[1], g[2], g[3], 0.90)"),
    ("code.secret", '"|cFF6E6A62"', '"|cFF6E6A62n/a|r"'),
    ("bar_fill_a", "0.90", "alpha or 0.90"),
    ("slot_current", "{ 0.45, 0.36, 0.08 }", "Paint(slot, { 0.45, 0.36, 0.08 }, 0.55)"),
    ("slot_current_a", "0.55", "Paint(slot, { 0.45, 0.36, 0.08 }, 0.55)"),
    ("slot_empty", "{ 0.16, 0.15, 0.13 }", "Paint(slot, { 0.16, 0.15, 0.13 }, 0.80)"),
    ("slot_empty_a", "0.80", "Paint(slot, { 0.16, 0.15, 0.13 }, 0.80)"),
    ("prof_fill_a", "0.95", "Paint(fill, current and L.C_HEADER or hue, 0.95)"),
    ("bar_fill_a", "0.90", "Paint(fill, hue, 0.90)"),
    ("stack_shade", "1.00", "(i % 2 == 1) and 1.00 or 0.70"),
    ("stack_shade_dim", "0.70", "(i % 2 == 1) and 1.00 or 0.70"),
    ("bar_fill_a", "0.90", "c[1] * shade, c[2] * shade, c[3] * shade, 0.90"),
    ("metrics.type_body", "10", "size = opts.size or 10"),
    ("layout_divider", "{ 0.25, 0.23, 0.20, 0.50 }", "line:SetColorTexture(0.25, 0.23, 0.20, 0.50)"),
    ("code.muted", '"|cFF555049"', "|cFF555049(%d slots)|r"),
    ("code.muted", '"|cFF555049"', "|cFF555049(inferred)|r"),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'bgFile   = "Interface\\\\Buttons\\\\WHITE8X8"'),
    ("metrics.edge", "1", "edgeSize = 1,"),
    ("layout_edge", "{ 0.3, 0.28, 0.24, 1 }", "er or 0.3, eg or 0.28, eb or 0.24, ea or 1"),
    ("button.danger_hover_bg", "{ 0.18, 0.06, 0.05, 1 }",
     "TA._ApplyBackdrop(btn, 0.18, 0.06, 0.05, 1, 1.00, 0.45, 0.40, 1)"),
    ("button.danger_hover_edge", "{ 1.00, 0.45, 0.40, 1 }",
     "TA._ApplyBackdrop(btn, 0.18, 0.06, 0.05, 1, 1.00, 0.45, 0.40, 1)"),
    ("button.danger_hover_text", "{ 1, 0.78, 0.74, 1 }", "lbl:SetTextColor(1, 0.78, 0.74, 1)"),
    ("button.danger_bg", "{ 0.10, 0.04, 0.04, 1 }",
     "TA._ApplyBackdrop(btn, 0.10, 0.04, 0.04, 1, 0.90, 0.30, 0.25, 1)"),
    ("button.danger_edge", "{ 0.90, 0.30, 0.25, 1 }",
     "TA._ApplyBackdrop(btn, 0.10, 0.04, 0.04, 1, 0.90, 0.30, 0.25, 1)"),
    ("button.gold_hover_bg", "{ 0.22, 0.16, 0.06, 1 }",
     "TA._ApplyBackdrop(btn, 0.22, 0.16, 0.06, 1, 0.910, 0.702, 0.353, 1)"),
    ("gilder_gold", "{ 0.910, 0.702, 0.353, 1 }",
     "TA._ApplyBackdrop(btn, 0.22, 0.16, 0.06, 1, 0.910, 0.702, 0.353, 1)"),
    ("button.text_on_gold", "{ 0.98, 0.94, 0.84, 1 }", "lbl:SetTextColor(0.98, 0.94, 0.84, 1)"),
    ("button.gold_bg", "{ 0.16, 0.12, 0.04, 1 }",
     "TA._ApplyBackdrop(btn, 0.16, 0.12, 0.04, 1, 0.910, 0.702, 0.353, 1)"),
    ("gilder_gold", "{ 0.910, 0.702, 0.353, 1 }", "lbl:SetTextColor(0.910, 0.702, 0.353, 1)"),
    ("button.active_bg", "{ 0.16, 0.13, 0.02, 1 }",
     "TA._ApplyBackdrop(btn, 0.16, 0.13, 0.02, 1, 1.00, 0.82, 0.00, 1)"),
    ("button.active_edge", "{ 1.00, 0.82, 0.00, 1 }",
     "TA._ApplyBackdrop(btn, 0.16, 0.13, 0.02, 1, 1.00, 0.82, 0.00, 1)"),
    ("gold_heading", "{ 1, 0.82, 0, 1 }", "lbl:SetTextColor(1, 0.82, 0, 1)"),
    ("button.hover_bg", "{ 0.13, 0.11, 0.08, 1 }",
     "TA._ApplyBackdrop(btn, 0.13, 0.11, 0.08, 1, 0.60, 0.52, 0.30, 1)"),
    ("button.hover_edge", "{ 0.60, 0.52, 0.30, 1 }",
     "TA._ApplyBackdrop(btn, 0.13, 0.11, 0.08, 1, 0.60, 0.52, 0.30, 1)"),
    ("text_primary", "{ 0.92, 0.90, 0.87, 1 }", "lbl:SetTextColor(0.92, 0.90, 0.87, 1)"),
    ("button.idle_bg", "{ 0.08, 0.07, 0.06, 1 }",
     "TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1, 0.30, 0.28, 0.24, 1)"),
    ("layout_edge", "{ 0.30, 0.28, 0.24, 1 }",
     "TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1, 0.30, 0.28, 0.24, 1)"),
    ("button.idle_text", "{ 0.78, 0.74, 0.68, 1 }", "lbl:SetTextColor(0.78, 0.74, 0.68, 1)"),
    ("metrics.type_caption", "9", 'lbl:SetFont(FONT, opts.size or 9, "")'),
]

if __name__ == "__main__":
    sys.exit(run("Layout", "Core/Layout.lua", SWAPS))
