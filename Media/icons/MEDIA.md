# ToonAge icon media list (`Interface\AddOns\ToonAge\Media\icons\`)

Shipped set, 2026-10-09. Every file from the three delivered archives is in this folder: the original set, the redraw (`tab_caps`, `tab_weapons`, `tab_weekly` and their `_32` cuts), then the final archive over the top (`tab_delves`, `tab_delves_32`, replacement `tab_caps_32` and `tab_weekly_32`, and `util_pip_8`, `util_pip_8_ring`, `util_pip_8_charged`). Name aliases `tab_guide`, `tab_rotation` and `util_harvest` are byte-copies of `tab_scrolls`, `tab_casts` and `tab_harvest`. 62 TGA files. Nothing in those archives is still pending.

The earlier rev-3 draft counted 71 by also listing `tab_racials`, `tab_professions`, `tab_pets` (64 and `_32`) and `util_lock` (64, `_32`, `_16`). Those nine files were not in any archive, so they are not in this folder.

Final icon set, signed off by the art director (Gilder) on 2026-10-08. Specs: `toonage/style-guide.md` (rev 2) §9b–§11 and `toonage/prompt-sheet-2026-10-08.md` §4. This manifest is the per-file usage list. The style guide stays the source of truth for the design rules.

All files are 32-bit uncompressed TGA (type 2) with straight alpha and power-of-two sizes. Mono glyphs are pure white `#FFFFFF` plus alpha, tinted in code with `SetVertexColor`. 45 files: 19 icons × (64 + `_32`) plus 7 `_16`. `tab_endgame` is not built (Endgame tab undecided).

## Display rules

1. **Scrolls tab:** at **32 px** display, use the 64 master **`tab_scrolls.tga`** (2 text lines). **`tab_scrolls_32.tga`** has no lines and is used **only at 20 px** (compact glyph-only pills).
2. **Compartment:** **`compartment.tga` / `compartment_32.tga`** stay **flat `#E8B35A`** with **no gradient**, on a transparent background. Do not tint or recolour. Unlike `logo_mark` and `minimap`, they carry no gold gradient, even though all three use the same hourglass mark.
3. **Title-bar dots** (close / minimize / expand): at **idle** the dot is **plain colour** at 0.85 alpha, **with no glyph**. On **hover** the dot goes to 1.0 and shows its `util_*_16` glyph at 8 UI units, tinted `text_on_gold` `#1A0E02`. The expand hover glyph is a **plus** (`util_expand_16`).
4. Small display sizes come from the hand-built `_16` files (8 px dot glyphs, 12 px list glyphs), never from shrinking `_32`.

## Files

| File | Size | Use | Display size |
|---|---|---|---|
| `logo_mark.tga` | 64×64 | Brand mark: gold-gradient hourglass (helm upper bulb) on `#14202A` rounded square r12 with 2 px `#B8C6D1` edge, full colour | 64 (about panel, addon list) |
| `logo_mark_32.tga` | 32×32 | Same, hinted | 32 (title, optional) |
| `minimap.tga` | 64×64 | Minimap button art: same hourglass on a `#14202A` disc, full colour; cropped by `SetTexCoord(0.08,0.92,0.08,0.92)` | 21 inside `ToonAgeMinimapButton` |
| `minimap_32.tga` | 32×32 | Same, hinted | 21 (alternative source) |
| `compartment.tga` | 64×64 | Retail addon-compartment icon (TOC `## IconTexture`): same hourglass, **flat `#E8B35A`, transparent** (rule 2) | 16–20 |
| `compartment_32.tga` | 32×32 | Same, hinted | 16–20 |
| `tab_character.tga` | 64×64 | Character tab: bust in a ring | 32 |
| `tab_character_32.tga` | 32×32 | Same, hinted | 20 (glyph-only pill), 32 |
| `tab_gear.tga` | 64×64 | Gear tab: heater shield with centre diamond | 32 |
| `tab_gear_32.tga` | 32×32 | Same, hinted (pixel-hinted 6×6 diamond) | 20, 32 |
| `tab_talents.tga` | 64×64 | Talents tab: three nodes in a triangle | 32 |
| `tab_talents_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `tab_spells.tga` | 64×64 | Spells tab: four-point star outline | 32 |
| `tab_spells_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `tab_pvp.tga` | 64×64 | PvP tab: crossed swords | 32 |
| `tab_pvp_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `tab_scrolls.tga` | 64×64 | Scrolls (guides) tab: rolled scroll **with 2 text lines** | **32** (rule 1) |
| `tab_scrolls_32.tga` | 32×32 | Scrolls tab, small cut **without lines** | **20 only** (rule 1) |
| `tab_casts.tga` | 64×64 | Casts (rotations) tab: lightning bolt outline | 32 |
| `tab_casts_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `tab_harvest.tga` | 64×64 | Harvest (data harvester) tab: map pin with record dot and ground line | 32 |
| `tab_harvest_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `util_settings.tga` | 64×64 | Settings cog (opens `TASettingsDrawer`) | master |
| `util_settings_32.tga` | 32×32 | Same, hinted | 16 (icon button) |
| `util_close.tga` | 64×64 | Close ×, master | master |
| `util_close_32.tga` | 32×32 | Close ×, icon-button glyph | 16 (icon button) |
| `util_close_16.tga` | 16×16 | Close ×, red title-dot **hover** glyph (2 px) | 8 on 12 px dot (rule 3) |
| `util_minimize.tga` | 64×64 | Minimize −, master | master |
| `util_minimize_32.tga` | 32×32 | Minimize −, icon-button glyph | 16 (icon button) |
| `util_minimize_16.tga` | 16×16 | Minimize −, yellow title-dot **hover** glyph (2 px) | 8 on 12 px dot (rule 3) |
| `util_expand.tga` | 64×64 | Expand: two outward corner brackets, master (not used for the dot hover) | master |
| `util_expand_32.tga` | 32×32 | Expand corners, icon-button glyph (not used for the dot hover) | 16 (icon button) |
| `util_expand_16.tga` | 16×16 | Expand, green title-dot **hover** glyph: **plain + (2 px)** | 8 on 12 px dot (rule 3) |
| `util_clock.tga` | 64×64 | Clock (10:10), master | master |
| `util_clock_32.tga` | 32×32 | Clock (10:10), hinted | 16+ |
| `util_clock_16.tga` | 16×16 | Clock, list glyph: **hands at 12 and 3 (L shape)**, 1 px | 12 (Toon Age list, `text_muted`) |
| `util_calendar.tga` | 64×64 | Calendar page, master | master |
| `util_calendar_32.tga` | 32×32 | Same, hinted | 16+ |
| `util_calendar_16.tga` | 16×16 | Calendar, list glyph, 1 px + 2×2 date marker | 12 (list) |
| `util_skull.tga` | 64×64 | Skull (deaths), master | master |
| `util_skull_32.tga` | 32×32 | Same, hinted | 16+ |
| `util_skull_16.tga` | 16×16 | Skull, list glyph: two 3×3 eye sockets, flat jaw, no teeth | 12 (list) |
| `util_chevron.tga` | 64×64 | Right chevron, master (rotate with `SetRotation` for open) | master |
| `util_chevron_32.tga` | 32×32 | Same, hinted | 16+ |
| `util_chevron_16.tga` | 16×16 | Chevron, 1 px, bbox centred on (8,8) for clean rotation | 12 (collapsible sections, Diagnostics back chevron) |

Note: the clock's 64 and `_32` files still show the 10:10 pose. Only `util_clock_16` (the 12 px list glyph) uses the 12-and-3 L shape, per the AD's final fix. Likewise, the expand 64/`_32` keep the corner brackets, and only the `_16` hover glyph is a plus.
