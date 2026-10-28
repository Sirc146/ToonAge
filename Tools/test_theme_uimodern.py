#!/usr/bin/env python3
"""UIModern tokens match the literals they replaced at bccb4cf.

Every colour, alpha, size, font and texture literal that Core/UIModern.lua
now reads from TA.Theme is checked against that commit. The comparison runs
in Lua 5.1. A token may be one channel longer than the old literal only when
the extra channel is 1.

Usage:  python3 Tools/test_theme_uimodern.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from theme_literal_check import run

# token path, Lua literal, exact snippet from bccb4cf:Core/UIModern.lua
SWAPS = [
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'M.FONT_HEADER  = "Fonts\\\\FRIZQT__.TTF"'),
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'M.FONT_BODY    = "Fonts\\\\FRIZQT__.TTF"'),
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'M.FONT_CAPTION = "Fonts\\\\FRIZQT__.TTF"'),
    ("mono", r'"Fonts\\ARIALN.TTF"', 'M.FONT_MONO    = "Fonts\\\\ARIALN.TTF"'),
    ("metrics.type_h1", "14", "M.SIZE_H1      = 14"),
    ("metrics.type_h2", "12", "M.SIZE_H2      = 12"),
    ("metrics.type_h3", "11", "M.SIZE_H3      = 11"),
    ("metrics.type_body", "10", "M.SIZE_BODY    = 10"),
    ("metrics.type_caption", "9", "M.SIZE_CAPTION = 9"),
    ("metrics.type_tiny", "8", "M.SIZE_TINY    = 8"),
    ("text_primary", "{ 0.92, 0.90, 0.87, 1.00 }", "M.CLR_TEXT_PRIMARY   = { 0.92, 0.90, 0.87, 1.00 }"),
    ("text_secondary", "{ 0.62, 0.59, 0.55, 1.00 }", "M.CLR_TEXT_SECONDARY = { 0.62, 0.59, 0.55, 1.00 }"),
    ("text_accent", "{ 0.40, 0.75, 1.00, 1.00 }", "M.CLR_TEXT_ACCENT    = { 0.40, 0.75, 1.00, 1.00 }"),
    ("text_success", "{ 0.30, 0.92, 0.40, 1.00 }", "M.CLR_TEXT_SUCCESS   = { 0.30, 0.92, 0.40, 1.00 }"),
    ("text_warning", "{ 1.00, 0.65, 0.20, 1.00 }", "M.CLR_TEXT_WARNING   = { 1.00, 0.65, 0.20, 1.00 }"),
    ("text_danger", "{ 1.00, 0.35, 0.30, 1.00 }", "M.CLR_TEXT_DANGER    = { 1.00, 0.35, 0.30, 1.00 }"),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'bgFile   = "Interface\\\\Buttons\\\\WHITE8X8"'),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'edgeFile = "Interface\\\\Buttons\\\\WHITE8X8"'),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'glow:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")'),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'mask:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")'),
    ("metrics.edge", "1", "edgeSize = 1,"),
    ("backdrop.card.bg", "{ 0.08, 0.08, 0.10, 0.92 }", "frame:SetBackdropColor(0.08, 0.08, 0.10, 0.92)"),
    ("backdrop.card.edge", "{ 0.28, 0.28, 0.32, 0.60 }", "frame:SetBackdropBorderColor(0.28, 0.28, 0.32, 0.60)"),
    ("backdrop.input.bg", "{ 0.04, 0.04, 0.05, 0.95 }", "frame:SetBackdropColor(0.04, 0.04, 0.05, 0.95)"),
    ("backdrop.input.edge", "{ 0.22, 0.22, 0.26, 0.50 }", "frame:SetBackdropBorderColor(0.22, 0.22, 0.26, 0.50)"),
    ("backdrop.header.bg", "{ 0.12, 0.12, 0.14, 0.96 }", "frame:SetBackdropColor(0.12, 0.12, 0.14, 0.96)"),
    ("backdrop.header.edge", "{ 0.30, 0.30, 0.35, 0.50 }", "frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 0.50)"),
    ("backdrop.success.bg", "{ 0.04, 0.10, 0.04, 0.92 }", "frame:SetBackdropColor(0.04, 0.10, 0.04, 0.92)"),
    ("backdrop.success.edge", "{ 0.20, 0.80, 0.30, 0.55 }", "frame:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.55)"),
    ("backdrop.danger.bg", "{ 0.10, 0.04, 0.04, 0.92 }", "frame:SetBackdropColor(0.10, 0.04, 0.04, 0.92)"),
    ("backdrop.danger.edge", "{ 0.90, 0.30, 0.25, 0.55 }", "frame:SetBackdropBorderColor(0.90, 0.30, 0.25, 0.55)"),
    ("backdrop.warning.bg", "{ 0.10, 0.07, 0.02, 0.92 }", "frame:SetBackdropColor(0.10, 0.07, 0.02, 0.92)"),
    ("backdrop.warning.edge", "{ 0.90, 0.60, 0.15, 0.50 }", "frame:SetBackdropBorderColor(0.90, 0.60, 0.15, 0.50)"),
    ("backdrop.panel.bg", "{ 0.06, 0.06, 0.08, 0.94 }", "frame:SetBackdropColor(0.06, 0.06, 0.08, 0.94)"),
    ("backdrop.panel.edge", "{ 0.24, 0.24, 0.28, 0.50 }", "frame:SetBackdropBorderColor(0.24, 0.24, 0.28, 0.50)"),
    ("tex.tooltip_bg", r'"Interface\\Tooltips\\UI-Tooltip-Background"', 'bgFile   = "Interface\\\\Tooltips\\\\UI-Tooltip-Background"'),
    ("tex.tooltip_edge", r'"Interface\\Tooltips\\UI-Tooltip-Border"', 'edgeFile = "Interface\\\\Tooltips\\\\UI-Tooltip-Border"'),
    ("metrics.shadow_edge", "12", "edgeSize = 12,"),
    ("glass_base", "{ 0.05, 0.05, 0.06, 0.90 }", "opts.baseTint or { 0.05, 0.05, 0.06, 0.90 }"),
    ("glass_border", "{ 0.30, 0.30, 0.35, 1.00 }", "opts.borderColor or { 0.30, 0.30, 0.35, 1.00 }"),
    ("glass_frost", "{ 0.08, 0.08, 0.10, 0.60 }", "opts.frostTint or { 0.08, 0.08, 0.10, 0.60 }"),
    ("metrics.shadow_outset", "4", 'shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)'),
    ("metrics.shadow_outset", "4", 'shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)'),
    ("glass_shadow", "{ 0, 0, 0, 0.70 }", "frame._glassShadow:SetBackdropBorderColor(0, 0, 0, 0.70)"),
    ("glow_alpha", "0.7", "a = a or 0.7"),
    ("metrics.glow_inset", "2", 'mask:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)'),
    ("metrics.glow_inset", "2", 'mask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)'),
    ("glow_strength", "0.35", "a * 0.35"),
    ("backdrop.panel.bg", "{ 0.06, 0.06, 0.08, 0.94 }", "frame._modernGlowMask:SetVertexColor(0.06, 0.06, 0.08, 0.94)"),
    ("strip_ok", "{ 0.15, 0.70, 0.30, 0.8 }", "CreateColor(0.15, 0.70, 0.30, 0.8)"),
    ("strip_upgrade", "{ 0.12, 1.00, 0.00, 0.9 }", "CreateColor(0.12, 1.00, 0.00, 0.9)"),
    ("strip_warning", "{ 1.00, 0.65, 0.10, 0.8 }", "CreateColor(1.00, 0.65, 0.10, 0.8)"),
    ("strip_danger", "{ 1.00, 0.30, 0.25, 0.9 }", "CreateColor(1.00, 0.30, 0.25, 0.9)"),
    # Fade end of each strip. RGB is the strip token; the old alpha is 0.0,
    # written as a literal 0 in the new file.
    ("strip_ok", "{ 0.15, 0.70, 0.30 }", "CreateColor(0.15, 0.70, 0.30, 0.0)", "prefix"),
    ("strip_upgrade", "{ 0.12, 1.00, 0.00 }", "CreateColor(0.12, 1.00, 0.00, 0.0)", "prefix"),
    ("strip_warning", "{ 1.00, 0.65, 0.10 }", "CreateColor(1.00, 0.65, 0.10, 0.0)", "prefix"),
    ("strip_danger", "{ 1.00, 0.30, 0.25 }", "CreateColor(1.00, 0.30, 0.25, 0.0)", "prefix"),
    ("metrics.type_h1", "14", 'toggleArrow:SetFont(self.FONT_BODY, 14, "OUTLINE")'),
    ("white", "{ 1, 1, 1, 1 }", "arrowLbl:SetTextColor(1, 1, 1, 1)"),
    ("gold_heading", "{ 1.00, 0.82, 0.00, 1 }", "hdr:SetTextColor(1.00, 0.82, 0.00, 1)"),
    ("section_rule", "{ 0.55, 0.40, 0.08, 0.25 }", "line:SetColorTexture(0.55, 0.40, 0.08, 0.25)"),
    ("amber", "{ 0.55, 0.40, 0.08, 1 }", "hdr:SetTextColor(0.55, 0.40, 0.08, 1)"),
    ("datarow_bg", "{ 0.05, 0.05, 0.06, 0.8 }", "row:SetBackdropColor(0.05, 0.05, 0.06, 0.8)"),
    ("row_edge", "{ 0.20, 0.20, 0.22, 0.4 }", "row:SetBackdropBorderColor(0.20, 0.20, 0.22, 0.4)"),
    ("progress_bg", "{ 0.04, 0.04, 0.05, 0.9 }", "container:SetBackdropColor(0.04, 0.04, 0.05, 0.9)"),
    ("row_edge", "{ 0.20, 0.20, 0.22, 0.4 }", "container:SetBackdropBorderColor(0.20, 0.20, 0.22, 0.4)"),
    ("text_accent", "{ 0.40, 0.75, 1.00 }", "opts.color or { 0.40, 0.75, 1.00 }"),
    ("progress_fill_a", "0.9", "fill:SetColorTexture(clr[1], clr[2], clr[3], 0.9)"),
    ("button_hover_bg", "{ 0.12, 0.12, 0.14, 1 }", "f:SetBackdropColor(0.12, 0.12, 0.14, 1)"),
    ("white", "{ 1, 1, 1, 1 }", "label:SetTextColor(1, 1, 1, 1)"),
    ("modern_divider", "{ 0.25, 0.25, 0.28, 0.3 }", "line:SetColorTexture(0.25, 0.25, 0.28, 0.3)"),
]

if __name__ == "__main__":
    sys.exit(run("UIModern", "Core/UIModern.lua", SWAPS))
