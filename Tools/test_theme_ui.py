#!/usr/bin/env python3
"""UI.lua tokens match the literals they replaced at bccb4cf.

Every colour, alpha, size, font, texture and |cFF code that Core/UI.lua now
reads from TA.Theme is checked against that commit, in Lua 5.1. Chat print
colour codes are not swaps and are not listed.

Usage:  python3 Tools/test_theme_ui.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from theme_literal_check import run

SWAPS = [
    ("metrics.frame_w", "900", "local FRAME_WIDTH   = 900"),
    ("metrics.frame_h", "580", "local FRAME_HEIGHT  = 580"),
    ("metrics.sidebar_w", "210", "local SIDEBAR_WIDTH = 210"),
    ("metrics.tab_h", "30", "local TAB_HEIGHT    = 30"),
    ("metrics.titlebar_h", "34", "local TITLEBAR_H    = 34"),
    ("metrics.content_pad", "14", "local CONTENT_PAD   = 14"),
    ("metrics.row_pad", "6", "local ROW_PAD       = 6"),
    ("text_tab_idle", "{ 0.55, 0.52, 0.48 }", "local r, g, b = 0.55, 0.52, 0.48"),
    ("text_primary", "{ 0.92, 0.90, 0.87 }", "if hot then r, g, b = 0.92, 0.90, 0.87 end"),
    # bccb4cf UI.lua:43 and :45. The alpha on both the label and the glyph is 1
    # for the idle colour and the hot colour.
    ("text_tab_idle.4", "1", "btn.label:SetTextColor(r, g, b, 1)"),
    ("text_primary.4", "1", "btn.label:SetTextColor(r, g, b, 1)"),
    ("text_tab_idle.4", "1", "btn.glyph:SetVertexColor(r, g, b, 1)"),
    ("text_primary.4", "1", "btn.glyph:SetVertexColor(r, g, b, 1)"),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'bgFile   = "Interface\\\\Buttons\\\\WHITE8X8"'),
    ("tex.white", r'"Interface\\Buttons\\WHITE8X8"', 'edgeFile = "Interface\\\\Buttons\\\\WHITE8X8"'),
    ("metrics.edge", "1", "edgeSize = 1,"),
    ("ui_fallback_bg", "{ 0.05, 0.04, 0.02, 0.98 }", "br or 0.05, bg or 0.04, bb or 0.02, ba or 0.98"),
    ("ui_fallback_edge", "{ 0.55, 0.40, 0.08, 0.70 }", "er or 0.55, eg or 0.40, eb or 0.08, ea or 0.70"),
    ("ui_frame_bg", "{ 0.05, 0.05, 0.06, 0.94 }", "ApplyBackdrop(frame, 0.05, 0.05, 0.06, 0.94)"),
    ("ui_frame_edge", "{ 0.30, 0.30, 0.35, 1.00 }", "frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)"),
    ("ui_frame_edge", "{ 0.30, 0.30, 0.35, 1.00 }", "of:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)"),
    ("ui_title_bg", "{ 0.10, 0.10, 0.12, 1.00 }", "ApplyBackdrop(titleBar, 0.10, 0.10, 0.12, 1.00)"),
    ("tex.title_icon", r'"Interface\\Icons\\Achievement_Character_Human_Female"',
     'titleIcon:SetTexture("Interface\\\\Icons\\\\Achievement_Character_Human_Female")'),
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'titleLabel:SetFont("Fonts\\\\FRIZQT__.TTF", 13, "OUTLINE")'),
    ("metrics.title_font", "13", 'titleLabel:SetFont("Fonts\\\\FRIZQT__.TTF", 13, "OUTLINE")'),
    ("text_primary", "{ 0.92, 0.90, 0.87, 1.00 }", "titleLabel:SetTextColor(0.92, 0.90, 0.87, 1.00)"),
    ("metrics.type_caption", "9", 'versionLabel:SetFont("Fonts\\\\FRIZQT__.TTF", 9, "OUTLINE")'),
    ("text_version", "{ 0.55, 0.52, 0.45, 1.00 }", "versionLabel:SetTextColor(0.55, 0.52, 0.45, 1.00)"),
    ("metrics.tab_font", "11", 'fs:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")'),
    ("metrics.tab_font", "11", 'errF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")'),
    ("metrics.tab_font", "11", 'titleLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")'),
    ("text_secondary", "{ 0.62, 0.59, 0.55, 1 }", "fs:SetTextColor(0.62, 0.59, 0.55, 1)"),
    ("text_primary", "{ 0.92, 0.90, 0.87, 1 }", "fs:SetTextColor(0.92, 0.90, 0.87, 1)"),
    ("metrics.gear_font", "14", 'optIcon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")'),
    ("text_secondary", "{ 0.62, 0.59, 0.55, 1 }", "optIcon:SetTextColor(0.62, 0.59, 0.55, 1)"),
    ("text_primary", "{ 0.92, 0.90, 0.87, 1 }", "optIcon:SetTextColor(0.92, 0.90, 0.87, 1)"),
    ("ui_tab_bg", "{ 0.07, 0.07, 0.09, 1.00 }", "ApplyBackdrop(tabBar, 0.07, 0.07, 0.09, 1.00)"),
    ("ui_sidebar_bg", "{ 0.05, 0.05, 0.06, 0.96 }", "ApplyBackdrop(sidebar, 0.05, 0.05, 0.06, 0.96)"),
    ("code.error", '"|cFFFF4444"', '"|cFFFF4444Error rendering "'),
    ("font", r'"Fonts\\FRIZQT__.TTF"', 'lbl:SetFont("Fonts\\\\FRIZQT__.TTF", 11, "")'),
    ("metrics.tab_font", "11", 'lbl:SetFont("Fonts\\\\FRIZQT__.TTF", 11, "")'),
    ("text_accent", "{ 0.40, 0.75, 1.00, 1.00 }", "line:SetColorTexture(0.40, 0.75, 1.00, 1.00)"),
    ("code.gold", '"|cFFFFD100"', '"|cFFFFD100ToonAge|r"'),
    ("code.white", '"|cFFFFFFFF"', '"Loaded on |cFFFFFFFF"'),
    ("code.gold", '"|cFFFFD100"', "type |cFFFFD100/ta errors|r"),
    ("ui_notice_bg", "{ 0.07, 0.07, 0.08, 0.94 }", "ApplyBackdrop(card, 0.07, 0.07, 0.08, 0.94, 0.30, 0.28, 0.24, 1)"),
    ("ui_notice_edge", "{ 0.30, 0.28, 0.24, 1 }", "0.30, 0.28, 0.24, 1"),
    ("tex.ring", r'"Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga"',
     'glyph:SetTexture("Interface\\\\AddOns\\\\ToonAge\\\\Media\\\\frame\\\\ring_32.tga")'),
    ("gold_heading", "{ 1, 0.82, 0 }", "glyph:SetVertexColor(1, 0.82, 0)"),
    ("gold_heading", "{ 1, 0.82, 0 }", "heading:SetTextColor(1, 0.82, 0)"),
    ("ui_copy_bg", "{ 0.05, 0.05, 0.06, 0.96 }", "f:SetBackdropColor(0.05, 0.05, 0.06, 0.96)"),
    ("ui_copy_edge", "{ 0.85, 0.65, 0.13, 0.85 }", "f:SetBackdropBorderColor(0.85, 0.65, 0.13, 0.85)"),
    ("code.gold", '"|cFFFFD100"', '"|cFFFFD100" .. label'),
    ("ui_frame_bg", "{ 0.05, 0.05, 0.06, 0.94 }", "ApplyBackdrop(of, 0.05, 0.05, 0.06, 0.94)"),
    ("metrics.type_h2", "12", 'hdr:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")'),
    ("code.gold", '"|cFFFFD100"', '"|cFFFFD100ToonAge Options|r"'),
    ("metrics.type_body", "10", 'layoutHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")'),
    ("metrics.type_body", "10", 'tabsHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")'),
    ("amber", "{ 0.55, 0.40, 0.08, 1 }", "layoutHdr:SetTextColor(0.55, 0.40, 0.08, 1)"),
    ("metrics.tab_font", "11", 'layoutLbl:SetFont(STANDARD_TEXT_FONT, 11, "")'),
    ("metrics.tab_font", "11", 'lbl:SetFont(STANDARD_TEXT_FONT, 11, "")'),
    ("ui_label", "{ 0.78, 0.73, 0.48, 1 }", "layoutLbl:SetTextColor(0.78, 0.73, 0.48, 1)"),
    ("metrics.type_caption", "9", 'layoutNote:SetFont(STANDARD_TEXT_FONT, 9, "")'),
    ("metrics.type_caption", "9", "note:SetFont(STANDARD_TEXT_FONT, 9)"),
    ("ui_note", "{ 0.50, 0.47, 0.36, 1 }", "layoutNote:SetTextColor(0.50, 0.47, 0.36, 1)"),
    ("amber_divider", "{ 0.55, 0.40, 0.08, 0.40 }", "divider:SetColorTexture(0.55, 0.40, 0.08, 0.40)"),
    ("amber", "{ 0.55, 0.40, 0.08, 1 }", "tabsHdr:SetTextColor(0.55, 0.40, 0.08, 1)"),
    ("ui_label", "{ 0.78, 0.73, 0.48, 1 }", "lbl:SetTextColor(0.78, 0.73, 0.48, 1)"),
    ("code.ok", '"|cFF4AFF7A"', '"|cFF4AFF7AAll changes apply immediately.|r"'),
    ("ui_drawer_bg", "{ 0.04, 0.04, 0.05, 0.97 }", "ApplyBackdrop(drawer, 0.04, 0.04, 0.05, 0.97)"),
    ("ui_drawer_edge", "{ 0.55, 0.40, 0.08, 0.8 }", "drawer:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.8)"),
    ("code.gold", '"|cFFFFD100"', '"|cFFFFD100ToonAge Settings|r"'),
]

if __name__ == "__main__":
    sys.exit(run("UI", "Core/UI.lua", SWAPS))
