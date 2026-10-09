# ToonAge icon media list (`Interface\AddOns\ToonAge\Media\icons\`)

Shipped set, 2026-10-09. 95 TGA files are in this folder. The first 62 came from the three earlier archives: the original set, the redraw (`tab_caps`, `tab_weapons`, `tab_weekly` and their `_32` cuts), then the final archive over the top (`tab_delves`, `tab_delves_32`, replacement `tab_caps_32` and `tab_weekly_32`, and `util_pip_8`, `util_pip_8_ring`, `util_pip_8_charged`). Name aliases `tab_guide`, `tab_rotation` and `util_harvest` are byte-copies of `tab_scrolls`, `tab_casts` and `tab_harvest`.

The waypoint and gear archive added nine more: `util_waypoint`, `util_waypoint_hollow`, `util_waypoint_arrived` (64, full colour), and `util_upgrade`, `util_downgrade`, `util_sidegrade` (32 masters plus `_16`). The last archive added the remaining nine: `tab_racials`, `tab_professions`, `tab_pets` (64 and `_32`) and `util_lock`, `util_lock_32`, `util_lock_16`. The named set is 95, and all 95 are in this folder. Gilder's 2026-10-09 list-glyph archive added fifteen 16×16 cuts: check, cross, warn, people, heart, herb, pick, diamond, star, menu, flight, square, and the left, up, and down chevrons.

Final icon set, signed off by the art director (Gilder) on 2026-10-08. Specs: `toonage/style-guide.md` (rev 2) §9b–§11 and `toonage/prompt-sheet-2026-10-08.md` §4. This manifest is the per-file usage list. The style guide stays the source of truth for the design rules.

All files are 32-bit uncompressed TGA (type 2) with straight alpha and power-of-two sizes. Mono glyphs are pure white `#FFFFFF` plus alpha, tinted in code with `SetVertexColor`. 45 files: 19 icons × (64 + `_32`) plus 7 `_16`. `tab_endgame` is not built (Endgame tab undecided).

## Display rules

1. **Scrolls tab:** at **32 px** display, use the 64 master **`tab_scrolls.tga`** (2 text lines). **`tab_scrolls_32.tga`** has no lines and is used **only at 20 px** (compact glyph-only pills).
2. **Compartment:** **`compartment.tga` / `compartment_32.tga`** stay **flat `#E8B35A`** with **no gradient**, on a transparent background. Do not tint or recolour. Unlike `logo_mark` and `minimap`, they carry no gold gradient, even though all three use the same hourglass mark.
3. **Title-bar dots** (close / minimize / expand): at **idle** the dot is **plain colour** at 0.85 alpha, **with no glyph**. On **hover** the dot goes to 1.0 and shows its `util_*_16` glyph at 8 UI units, tinted `text_on_gold` `#1A0E02`. The expand hover glyph is a **plus** (`util_expand_16`).
4. Small display sizes come from the hand-built `_16` files (8 px dot glyphs, 12 px list glyphs), never from shrinking `_32`.
5. **Quest waypoint** (`util_waypoint`, `util_waypoint_hollow`, `util_waypoint_arrived`): 64 masters, full colour. Do not tint them with `SetVertexColor`. Draw at 48 px by default, adjustable from 32 to 64, rotated with `SetRotation` around the texture centre. The hollow cut is for an estimated coordinate or an unverified step, and it is not drawn below 40 px (at 32 it reads as solid). Distance text is `124 yd`, with `~` in front when the location is estimated. Fade the arrow from 8 yards down to 5, then show the arrived ring. Hide the arrow in an instance, and when the player has no position.
6. **Gear marks** (`util_upgrade`, `util_downgrade`, `util_sidegrade`, plus `_16`): white art. Tint them in the `|T...|t` string, not by recolouring the file. Upgrade uses the success colour, downgrade the danger colour, sidegrade `text_muted`. The mark sits 4 px after the item name, never at the start of the row. The downgrade mark appears only in a comparison. List rows use the `_16` cut.

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
| `util_chevron_16.tga` | 16×16 | Right chevron. Forward, and a collapsed section | 12 |
| `util_chevron_left_16.tga` | 16×16 | Left chevron. Back | 12 |
| `util_chevron_up_16.tga` | 16×16 | Up chevron | 12 |
| `util_chevron_down_16.tga` | 16×16 | Down chevron. An open section | 12 |
| `util_check_16.tga` | 16×16 | Check | 12 |
| `util_cross_16.tga` | 16×16 | Cross | 12 |
| `util_warn_16.tga` | 16×16 | Warning | 12 |
| `util_people_16.tga` | 16×16 | People | 12 |
| `util_heart_16.tga` | 16×16 | Heart | 12 |
| `util_herb_16.tga` | 16×16 | Herb | 12 |
| `util_pick_16.tga` | 16×16 | Pick | 12 |
| `util_diamond_16.tga` | 16×16 | Diamond | 12 |
| `util_star_16.tga` | 16×16 | Star. Not the spells-tab star | 12 |
| `util_menu_16.tga` | 16×16 | Menu | 12 |
| `util_flight_16.tga` | 16×16 | Flight | 12 |
| `util_square_16.tga` | 16×16 | Filled square | 12 |
| `util_waypoint.tga` | 64×64 | Quest arrow, full colour (rule 5) | 48 default, 32–64 |
| `util_waypoint_hollow.tga` | 64×64 | Same arrow, hollow, for an estimated or unverified step (rule 5) | 40–64 (never 32) |
| `util_waypoint_arrived.tga` | 64×64 | Arrived ring, full colour, shown at 5 yards and closer (rule 5) | 48 default, 32–64 |
| `util_upgrade.tga` | 32×32 | Upgrade mark, white, success tint in the `|T|t` string (rule 6) | master |
| `util_upgrade_16.tga` | 16×16 | Upgrade mark, list cut (rule 6) | 16, 4 px after the item name |
| `util_downgrade.tga` | 32×32 | Downgrade mark, white, danger tint (rule 6) | master; comparison views only |
| `util_downgrade_16.tga` | 16×16 | Downgrade mark, list cut (rule 6) | 16, comparison views only |
| `util_sidegrade.tga` | 32×32 | Sidegrade mark, white, `text_muted` tint (rule 6) | master |
| `util_sidegrade_16.tga` | 16×16 | Sidegrade mark, list cut (rule 6) | 16, 4 px after the item name |
| `tab_racials.tga` | 64×64 | Racials tab: swallowtail banner with a round emblem | 32 |
| `tab_racials_32.tga` | 32×32 | Same, hinted | 20 (glyph-only pill), 32 |
| `tab_professions.tga` | 64×64 | Professions tab: anvil, side view | 32 |
| `tab_professions_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `tab_pets.tga` | 64×64 | Pets tab: paw print | 32 |
| `tab_pets_32.tga` | 32×32 | Same, hinted | 20, 32 |
| `util_lock.tga` | 64×64 | Lock, master | master |
| `util_lock_32.tga` | 32×32 | Lock, hinted | 16+ |
| `util_lock_16.tga` | 16×16 | Lock, list and talent-node glyph | 12–16 |

Note: the clock's 64 and `_32` files still show the 10:10 pose. Only `util_clock_16` (the 12 px list glyph) uses the 12-and-3 L shape, per the AD's final fix. Likewise, the expand 64/`_32` keep the corner brackets, and only the `_16` hover glyph is a plus.
