-- ToonAge/Core/Theme.lua
-- Shared colour, alpha, font, and size tokens for the three style systems
-- (Core/UIModern.lua, the amber chrome in Core/UI.lua, Core/Layout.lua).
--
-- Batch B0 of the frosted-glass skin. This file holds values and Theme:Select.
-- It does not draw, and it does not read SavedVariables. Nothing in the addon
-- calls Select yet, so the active palette is classic and the screen does not
-- change. The saved setting (ui.skin) is batch B2.
--
-- B2 note, not built here: on clients where the Settings API is nil, the skin
-- toggle has to fall back to the old options panel built in Core/UI.lua (the
-- block that used to sit around lines 1010-1046), not only the Blizzard page.
--
-- Load order: after Core/Init.lua (ToonAge exists) and Core/Compat/API.lua,
-- before Core/UI.lua. No dependency on Core/Layout.lua (absent on Cata/Wrath)
-- or Core/UIModern.lua. No game API calls.

local TA = ToonAge
TA.Theme = TA.Theme or {}
local Theme = TA.Theme

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do
        out[DeepCopy(k)] = DeepCopy(v)
    end
    return out
end

-- Write src into dst without replacing dst's tables. Callers that kept a
-- reference to a colour table (L.C_PRIMARY, M.CLR_TEXT_*) see the new numbers.
-- Keys the new skin does not have are cleared, so a glass-only path does not
-- linger after a return to classic. Colour tables that exist in both skins
-- keep their identity.
local function Sync(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            local cur = dst[k]
            if type(cur) ~= "table" then
                cur = {}
                dst[k] = cur
            end
            Sync(cur, v)
        else
            dst[k] = v
        end
    end
    for k in pairs(dst) do
        if src[k] == nil then dst[k] = nil end
    end
end

-- Classic is today's look, copied 1:1 from the three style files.
-- Three palettes stay distinct where their numbers differ. Shared roles
-- (text_primary and the rest) are one table each, which both UIModern and
-- Layout point at. A fourth component of 1 is the alpha those call sites
-- already passed; Layout only reads [1], [2], [3].
local classic = {
    name = "classic",

    -- Core/Layout.lua:56-57 and Core/UIModern.lua:19-22. Both skins use these
    -- two faces (style-guide question on shipping a new font is still open).
    font = "Fonts\\FRIZQT__.TTF",
    mono = "Fonts\\ARIALN.TTF",

    -- UIModern text colours (UIModern.lua:33-38) and Layout's matching RGB
    -- (Layout.lua:25-32). gold_heading is Layout C_HEADER / the section gold.
    text_primary   = { 0.92, 0.90, 0.87, 1.00 },
    text_secondary = { 0.62, 0.59, 0.55, 1.00 },
    text_accent    = { 0.40, 0.75, 1.00, 1.00 },
    text_success   = { 0.30, 0.92, 0.40, 1.00 },
    text_warning   = { 1.00, 0.65, 0.20, 1.00 },
    text_danger    = { 1.00, 0.35, 0.30, 1.00 },
    gold_heading   = { 1.00, 0.82, 0.00, 1 },
    text_dim       = { 0.45, 0.43, 0.40, 1 },

    -- Layout stat bars (Layout.lua:48-49). Separate tables from text_accent
    -- so a later skin can retint the accent without recolouring the bars.
    stat_base = { 0.24, 0.44, 0.60 },
    stat_gear = { 0.40, 0.75, 1.00 },

    -- Chrome textures the flat backdrops use today. Not the glass kit.
    tex = {
        white        = "Interface\\Buttons\\WHITE8X8",
        tooltip_bg   = "Interface\\Tooltips\\UI-Tooltip-Background",
        tooltip_edge = "Interface\\Tooltips\\UI-Tooltip-Border",
        title_icon   = "Interface\\Icons\\Achievement_Character_Human_Female",
        ring         = "Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga",
    },

    -- Exact |c escapes. These are not the same bytes as the float gold/dim
    -- above (FFD100 is 209/255, not 0.82). Chat prints keep their own literals.
    code = {
        gold   = "|cFFFFD100",
        white  = "|cFFFFFFFF",
        error  = "|cFFFF4444",
        ok     = "|cFF4AFF7A",
        muted  = "|cFF555049",
        secret = "|cFF6E6A62",
    },

    -- Sizes the three files already use. Numbers are copied at file load by
    -- the locals that hold them; colour tables are the ones Select can retint
    -- in place (see the note in UI.lua / Layout.lua).
    metrics = {
        frame_w      = 900,
        frame_h      = 580,
        sidebar_w    = 210,
        tab_h        = 30,
        titlebar_h   = 34,
        content_pad  = 14,
        row_pad      = 6,
        pad          = 14,
        rpad         = 8,
        edge         = 1,
        shadow_edge  = 12,
        shadow_outset = 4,
        glow_inset   = 2,
        type_h1      = 14,
        type_h2      = 12,
        type_h3      = 11,
        type_body    = 10,
        type_caption = 9,
        type_tiny    = 8,
        title_font   = 13,
        tab_font     = 11,
        gear_font    = 14,
    },

    -- UIModern backdrop styles (UIModern.lua:59-78). Seven styles, not eight:
    -- the else branch is "panel" (the spec's "default"). There is no "dark" key.
    backdrop = {
        card = {
            bg   = { 0.08, 0.08, 0.10, 0.92 },
            edge = { 0.28, 0.28, 0.32, 0.60 },
        },
        input = {
            bg   = { 0.04, 0.04, 0.05, 0.95 },
            edge = { 0.22, 0.22, 0.26, 0.50 },
        },
        header = {
            bg   = { 0.12, 0.12, 0.14, 0.96 },
            edge = { 0.30, 0.30, 0.35, 0.50 },
        },
        success = {
            bg   = { 0.04, 0.10, 0.04, 0.92 },
            edge = { 0.20, 0.80, 0.30, 0.55 },
        },
        danger = {
            bg   = { 0.10, 0.04, 0.04, 0.92 },
            edge = { 0.90, 0.30, 0.25, 0.55 },
        },
        warning = {
            bg   = { 0.10, 0.07, 0.02, 0.92 },
            edge = { 0.90, 0.60, 0.15, 0.50 },
        },
        panel = {
            bg   = { 0.06, 0.06, 0.08, 0.94 },
            edge = { 0.24, 0.24, 0.28, 0.50 },
        },
    },

    -- Current double-pane glass (UIModern.lua ApplyGlassBackdrop), which is
    -- part of today's look, not the future kit.
    glass_base   = { 0.05, 0.05, 0.06, 0.90 },
    glass_border = { 0.30, 0.30, 0.35, 1.00 },
    glass_frost  = { 0.08, 0.08, 0.10, 0.60 },
    glass_shadow = { 0, 0, 0, 0.70 },
    glow_alpha   = 0.7,
    glow_strength = 0.35,

    -- Status strips (UIModern.lua:222-236). The fade end is the same RGB at 0.
    strip_ok = { 0.15, 0.70, 0.30, 0.8 },
    strip_upgrade = { 0.12, 1.00, 0.00, 0.9 },
    strip_warning = { 1.00, 0.65, 0.10, 0.8 },
    strip_danger = { 1.00, 0.30, 0.25, 0.9 },

    -- Other UIModern surfaces.
    section_rule   = { 0.55, 0.40, 0.08, 0.25 },
    amber          = { 0.55, 0.40, 0.08, 1 },
    datarow_bg     = { 0.05, 0.05, 0.06, 0.8 },
    row_edge       = { 0.20, 0.20, 0.22, 0.4 },
    progress_bg    = { 0.04, 0.04, 0.05, 0.9 },
    progress_fill_a = 0.9,
    button_hover_bg = { 0.12, 0.12, 0.14, 1 },
    white          = { 1, 1, 1, 1 },
    modern_divider = { 0.25, 0.25, 0.28, 0.3 },

    -- UI.lua window chrome. Fallback is what ApplyBackdrop uses when a channel
    -- is omitted (amber edge). The painted frames pass their own colours.
    ui_fallback_bg   = { 0.05, 0.04, 0.02, 0.98 },
    ui_fallback_edge = { 0.55, 0.40, 0.08, 0.70 },
    ui_frame_bg      = { 0.05, 0.05, 0.06, 0.94 },
    ui_frame_edge    = { 0.30, 0.30, 0.35, 1.00 },
    ui_title_bg      = { 0.10, 0.10, 0.12, 1.00 },
    text_tab_idle    = { 0.55, 0.52, 0.48, 1 },
    text_version     = { 0.55, 0.52, 0.45, 1.00 },
    ui_tab_bg        = { 0.07, 0.07, 0.09, 1.00 },
    ui_sidebar_bg    = { 0.05, 0.05, 0.06, 0.96 },
    ui_notice_bg     = { 0.07, 0.07, 0.08, 0.94 },
    ui_notice_edge   = { 0.30, 0.28, 0.24, 1 },
    ui_copy_bg       = { 0.05, 0.05, 0.06, 0.96 },
    ui_copy_edge     = { 0.85, 0.65, 0.13, 0.85 },
    ui_label         = { 0.78, 0.73, 0.48, 1 },
    ui_note          = { 0.50, 0.47, 0.36, 1 },
    amber_divider    = { 0.55, 0.40, 0.08, 0.40 },
    ui_drawer_bg     = { 0.04, 0.04, 0.05, 0.97 },
    ui_drawer_edge   = { 0.55, 0.40, 0.08, 0.8 },

    -- Layout surfaces.
    layout_edge    = { 0.30, 0.28, 0.24, 1 },
    layout_rule    = { 0.30, 0.28, 0.22, 0.60 },
    layout_divider = { 0.25, 0.23, 0.20, 0.50 },
    bar_track_bg   = { 0.10, 0.09, 0.08, 1.00 },
    bar_track_edge = { 0.28, 0.26, 0.22, 1.00 },
    bar_fill_a     = 0.90,
    cap_dim        = 0.55,
    cap_dim_a      = 0.85,
    -- Gilder gold (#E8B35A-ish) for the cap tick and the gold button edge.
    gilder_gold    = { 0.910, 0.702, 0.353, 1 },
    slot_current   = { 0.45, 0.36, 0.08 },
    slot_current_a = 0.55,
    slot_empty     = { 0.16, 0.15, 0.13 },
    slot_empty_a   = 0.80,
    prof_fill_a    = 0.95,
    stack_shade    = 1.00,
    stack_shade_dim = 0.70,

    -- Layout StyleButton (Layout.lua:1103-1126). Text for the idle danger
    -- state is text_danger, read at the call site.
    button = {
        danger_hover_bg   = { 0.18, 0.06, 0.05, 1 },
        danger_hover_edge = { 1.00, 0.45, 0.40, 1 },
        danger_hover_text = { 1, 0.78, 0.74, 1 },
        danger_bg         = { 0.10, 0.04, 0.04, 1 },
        danger_edge       = { 0.90, 0.30, 0.25, 1 },
        gold_hover_bg     = { 0.22, 0.16, 0.06, 1 },
        gold_bg           = { 0.16, 0.12, 0.04, 1 },
        text_on_gold      = { 0.98, 0.94, 0.84, 1 },
        active_bg         = { 0.16, 0.13, 0.02, 1 },
        active_edge       = { 1.00, 0.82, 0.00, 1 },
        hover_bg          = { 0.13, 0.11, 0.08, 1 },
        hover_edge        = { 0.60, 0.52, 0.30, 1 },
        idle_bg           = { 0.08, 0.07, 0.06, 1 },
        idle_text         = { 0.78, 0.74, 0.68, 1 },
    },
}

-- Glass starts as the classic numbers, so selecting it cannot change today's
-- picture. The style guide that names the frosted palette was not in the repo
-- for this batch; later batches replace these colour values. Kit paths are the
-- names from the spec (section 4). The files themselves are batch B1, and
-- nothing reads these paths yet.
local glass = DeepCopy(classic)
glass.name = "glass"
glass.geometry = {
    sheen_h       = 48,
    slice_window  = 16,
    slice_card    = 12,
    slice_popup   = 8,
    tray_w        = 184,
    title_capsule = 44,
    tab_capsule   = 44,
}
do
    local dir = "Interface\\AddOns\\ToonAge\\Media\\glass\\"
    glass.kit = {
        shadow_r16 = dir .. "shadow_r16.tga",
        shadow_r8  = dir .. "shadow_r8.tga",
        rrect_fill_r16   = dir .. "rrect_fill_r16.tga",
        rrect_border_r16 = dir .. "rrect_border_r16.tga",
        rrect_fill_r12   = dir .. "rrect_fill_r12.tga",
        rrect_border_r12 = dir .. "rrect_border_r12.tga",
        rrect_fill_r8    = dir .. "rrect_fill_r8.tga",
        rrect_border_r8  = dir .. "rrect_border_r8.tga",
        glass_sheen_r16  = dir .. "glass_sheen_r16.tga",
        glass_highlight_64 = dir .. "glass_highlight_64.tga",
        capsule_fill_64   = dir .. "capsule_fill_64.tga",
        capsule_border_64 = dir .. "capsule_border_64.tga",
        capsule_fill_44   = dir .. "capsule_fill_44.tga",
        capsule_border_44 = dir .. "capsule_border_44.tga",
        capsule_glow_44   = dir .. "capsule_glow_44.tga",
        capsule_fill_32   = dir .. "capsule_fill_32.tga",
        capsule_border_32 = dir .. "capsule_border_32.tga",
        capsule_fill_28   = dir .. "capsule_fill_28.tga",
        capsule_border_28 = dir .. "capsule_border_28.tga",
        capsule_sheen_28  = dir .. "capsule_sheen_28.tga",
        capsule_gold_28   = dir .. "capsule_gold_28.tga",
        capsule_fill_20   = dir .. "capsule_fill_20.tga",
        capsule_border_20 = dir .. "capsule_border_20.tga",
        capsule_gold_20   = dir .. "capsule_gold_20.tga",
        capsule_fill_6    = dir .. "capsule_fill_6.tga",
        capsule_border_6  = dir .. "capsule_border_6.tga",
        circle_32         = dir .. "circle_32.tga",
        knob_32           = dir .. "knob_32.tga",
        check_fill_32     = dir .. "check_fill_32.tga",
        check_border_32   = dir .. "check_border_32.tga",
        vcapsule_fill_8   = dir .. "vcapsule_fill_8.tga",
        vcapsule_border_8 = dir .. "vcapsule_border_8.tga",
        bar_r2_16         = dir .. "bar_r2_16.tga",
        bar_gloss         = dir .. "bar_gloss.tga",
        icon_border       = dir .. "icon_border.tga",
        icon_glow         = dir .. "icon_glow.tga",
        icon_mask         = dir .. "icon_mask.tga",
    }
end

Theme.skins = {
    classic = classic,
    glass   = glass,
}
Theme.active = DeepCopy(classic)

--- Copy one skin into Theme.active, in place. Unknown names are classic.
--- Nothing calls this until batch B2. Safe to call before SavedVariables exist.
function Theme:Select(name)
    if type(name) ~= "string" or type(self.skins[name]) ~= "table" then
        name = "classic"
    end
    Sync(self.active, self.skins[name])
    self.active.name = name
end

Theme:Select("classic")
