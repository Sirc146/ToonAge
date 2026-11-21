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

    -- Talent node tokens matching Modules/Forever/Talents.lua M.Theme.
    talent = {
        available  = { 70 / 255, 200 / 255, 106 / 255, 1 },
        partial    = { 245 / 255, 247 / 255, 250 / 255, 1 },
        maxed      = { 251 / 255, 224 / 255, 143 / 255, 1 },
        locked     = { 122 / 255, 130 / 255, 140 / 255, 0.50 },
        focus      = { 232 / 255, 179 / 255, 90 / 255, 1 },
        plan_route = { 232 / 255, 179 / 255, 90 / 255, 0.95 },
        line       = { 0.62, 0.58, 0.48, 0.90 },
    },

    motion = {
        reduced = false,
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

-- Option B (Modern Azeroth) — compact 68px Liquid Glass crown (34px title +
-- 34px segmented/underlit tab strip), solid dark content well (#0B0E12 @ 0.96),
-- elevated solid dark sidebar (#0E131A @ 0.96), custom non-traffic-light
-- controls, and single dynamic accent (Class Color default; ToonAge Gold and
-- Blizzard Modern one click away).
local CLASS_FALLBACK_COLORS = {
    MAGE        = { 0.247, 0.780, 0.922 }, -- #3FC7EB
    WARRIOR     = { 0.776, 0.608, 0.427 }, -- #C69B6D
    HUNTER      = { 0.667, 0.827, 0.447 }, -- #AAD372
    ROGUE       = { 1.000, 0.957, 0.408 }, -- #FFF468
    PRIEST      = { 1.000, 1.000, 1.000 }, -- #FFFFFF
    WARLOCK     = { 0.529, 0.533, 0.933 }, -- #8788EE
    DRUID       = { 1.000, 0.486, 0.039 }, -- #FF7C0A
    PALADIN     = { 0.957, 0.549, 0.729 }, -- #F48CBA
    SHAMAN      = { 0.000, 0.439, 0.867 }, -- #0070DD
    DEATHKNIGHT = { 0.769, 0.118, 0.227 }, -- #C41E3A
    MONK        = { 0.000, 1.000, 0.596 }, -- #00FF98
    DEMONHUNTER = { 0.639, 0.188, 0.788 }, -- #A330C9
    EVOKER      = { 0.200, 0.576, 0.498 }, -- #33937F
}

local GOLD_ACCENT = { 0.910, 0.702, 0.353, 1.00 } -- #E8B35A
local BLIZZ_ACCENT = { 0.941, 0.769, 0.353, 1.00 } -- #F0C45A

local function Linearize(channel)
    local c = tonumber(channel) or 0
    if c < 0 then c = 0 elseif c > 1 then c = 1 end
    if c <= 0.03928 then
        return c / 12.92
    end
    return ((c + 0.055) / 1.055) ^ 2.4
end

--- WCAG 2.1 relative luminance for 0..1 sRGB channels.
function Theme.Luminance(r, g, b)
    return 0.2126 * Linearize(r) + 0.7152 * Linearize(g) + 0.0722 * Linearize(b)
end

--- WCAG 2.1 contrast ratio between two { r, g, b } colour tables (1..21).
function Theme.ContrastRatio(a, b)
    local la = Theme.Luminance(a and a[1] or 0, a and a[2] or 0, a and a[3] or 0)
    local lb = Theme.Luminance(b and b[1] or 0, b and b[2] or 0, b and b[3] or 0)
    if lb > la then la, lb = lb, la end
    return (la + 0.05) / (lb + 0.05)
end

local function LiftForDarkBg(r, g, b)
    if Theme.Luminance(r, g, b) < 0.18 then
        local t = 0.15
        r = r + (1 - r) * t
        g = g + (1 - g) * t
        b = b + (1 - b) * t
    end
    return { r, g, b, 1.00 }
end

local function DarkTintedCTA(rgb)
    return {
        rgb[1] * 0.18,
        rgb[2] * 0.18,
        rgb[3] * 0.18,
        0.94,
    }
end

local function DetectClassToken(classToken)
    if type(classToken) == "string" and classToken ~= "" then
        return string.upper(classToken)
    end
    if type(UnitClass) == "function" then
        local ok, _, tok = pcall(UnitClass, "player")
        if ok and type(tok) == "string" and tok ~= "" then
            return string.upper(tok)
        end
    end
    return nil
end

--- Resolve a player class colour using CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS,
--- or the verified Forever/Retail fallback table. Avoids unmanifested C_ APIs.
function Theme:ResolveClassColor(classToken)
    local tok = DetectClassToken(classToken)
    if tok then
        local custom = type(CUSTOM_CLASS_COLORS) == "table" and CUSTOM_CLASS_COLORS[tok]
        if type(custom) == "table" and type(custom.r) == "number" then
            return { custom.r, custom.g, custom.b, 1.00 }
        end
        local raid = type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[tok]
        if type(raid) == "table" and type(raid.r) == "number" then
            return { raid.r, raid.g, raid.b, 1.00 }
        end
        local fb = CLASS_FALLBACK_COLORS[tok]
        if fb then
            return { fb[1], fb[2], fb[3], 1.00 }
        end
    end
    return { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 1.00 }
end

local modernAzeroth = DeepCopy(glass)
modernAzeroth.name = "modern_azeroth"
modernAzeroth.pack = "class"

modernAzeroth.text_primary   = { 0.961, 0.969, 0.980, 1.00 } -- #F5F7FA
modernAzeroth.text_secondary = { 0.788, 0.804, 0.824, 1.00 } -- #C9CDD2
modernAzeroth.text_dim       = { 0.549, 0.576, 0.604, 1.00 } -- #8C939A
modernAzeroth.gold_heading   = { 0.788, 0.643, 0.424, 1.00 } -- #C9A46C
modernAzeroth.text_success   = { 0.275, 0.784, 0.416, 1.00 } -- #46C86A
modernAzeroth.text_warning   = { 0.949, 0.765, 0.298, 1.00 } -- #F2C34C
modernAzeroth.text_danger    = { 0.839, 0.353, 0.290, 1.00 } -- #D65A4A
modernAzeroth.text_tab_idle  = { 0.788, 0.804, 0.824, 0.80 } -- #C9CDD2 @ 0.80
modernAzeroth.text_version   = { 0.549, 0.576, 0.604, 1.00 } -- #8C939A

modernAzeroth.tex.title_icon = "Interface\\AddOns\\ToonAge\\Media\\icons\\logo_mark_32.tga"

modernAzeroth.metrics.frame_w    = 900
modernAzeroth.metrics.frame_h    = 580
modernAzeroth.metrics.min_w      = 568
modernAzeroth.metrics.min_h      = 440
modernAzeroth.metrics.max_w      = 1280
modernAzeroth.metrics.max_h      = 800
modernAzeroth.metrics.sidebar_w  = 210
modernAzeroth.metrics.titlebar_h = 34
modernAzeroth.metrics.tab_h      = 34
modernAzeroth.metrics.crown_h    = 68
modernAzeroth.metrics.footer_h   = 34
modernAzeroth.metrics.outer_pad  = 4

modernAzeroth.geometry = {
    sheen_h        = 48,
    radius_shell   = 16,
    radius_well    = 12,
    radius_control = 6,
    crown_h        = 68,
    title_h        = 34,
    tab_h          = 34,
    footer_h       = 34,
}

-- Liquid Glass chrome tiers (control layer ONLY; never on tab content).
modernAzeroth.glass = {
    shell_fill   = { 0.059, 0.090, 0.122, 0.78 }, -- #0F171F @ 0.78
    sheet_fill   = { 0.055, 0.082, 0.110, 0.86 }, -- #0E151C @ 0.86
    capsule_fill = { 0.094, 0.141, 0.180, 0.68 }, -- #18242E @ 0.68
    rim          = { 0.722, 0.776, 0.820, 0.50 }, -- #B8C6D1 @ 0.50
    specular     = { 0.902, 0.910, 0.918, 0.40 }, -- #E6E8EA @ 0.40
    shadow       = { 0.000, 0.000, 0.000, 0.60 }, -- #000000 @ 0.60
    sheen_h      = 48,
}

-- Solid dark content surfaces (minimum 0.96 alpha for AAA legibility).
modernAzeroth.surface = {
    content     = { 0.043, 0.055, 0.071, 0.96 }, -- #0B0E12 @ 0.96
    sidebar     = { 0.055, 0.075, 0.102, 0.96 }, -- #0E131A @ 0.96
    footer      = { 0.035, 0.047, 0.063, 0.98 }, -- #090C10 @ 0.98
    card        = { 0.071, 0.090, 0.122, 0.96 }, -- #12171F @ 0.96
    divider     = { 0.137, 0.157, 0.173, 1.00 }, -- #23282C @ 1.00
    well_border = { 0.290, 0.322, 0.361, 0.45 }, -- #4A525C @ 0.45
}

-- Custom ToonAge window controls (explicitly zero macOS traffic lights).
modernAzeroth.controls = {
    traffic_lights = false,
    size           = 24,
    radius         = 6,
    idle_fill      = { 0.110, 0.149, 0.188, 0.65 }, -- #1C2630 @ 0.65
    hover_fill     = { 0.169, 0.224, 0.275, 0.85 }, -- #2B3946 @ 0.85
    rim            = { 0.722, 0.776, 0.820, 0.25 }, -- #B8C6D1 @ 0.25
    close_hover_bg = { 0.839, 0.353, 0.290, 0.20 }, -- danger @ 0.20
    close_glyph    = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_close_16.tga",
    settings_glyph = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_settings_16.tga",
    minimize_glyph = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_minimize_16.tga",
    expand_glyph   = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_expand_16.tga",
}

modernAzeroth.accent = {
    primary    = { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 1.00 },
    cta_bg     = DarkTintedCTA(GOLD_ACCENT),
    cta_text   = { 0.961, 0.969, 0.980, 1.00 },
    cta_border = { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 1.00 },
    tab_wash   = { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 0.10 },
}

modernAzeroth.ui_frame_bg    = DeepCopy(modernAzeroth.glass.shell_fill)
modernAzeroth.ui_frame_edge  = DeepCopy(modernAzeroth.glass.rim)
modernAzeroth.ui_title_bg    = DeepCopy(modernAzeroth.glass.shell_fill)
modernAzeroth.ui_tab_bg      = DeepCopy(modernAzeroth.glass.shell_fill)
modernAzeroth.ui_sidebar_bg  = DeepCopy(modernAzeroth.surface.sidebar)
modernAzeroth.ui_drawer_bg   = DeepCopy(modernAzeroth.glass.sheet_fill)
modernAzeroth.ui_drawer_edge = DeepCopy(modernAzeroth.glass.rim)
modernAzeroth.ui_copy_bg     = DeepCopy(modernAzeroth.glass.sheet_fill)
modernAzeroth.ui_copy_edge   = DeepCopy(modernAzeroth.glass.rim)
modernAzeroth.backdrop.panel.bg   = DeepCopy(modernAzeroth.surface.content)
modernAzeroth.backdrop.panel.edge = DeepCopy(modernAzeroth.surface.well_border)
modernAzeroth.backdrop.card.bg    = DeepCopy(modernAzeroth.surface.card)
modernAzeroth.backdrop.card.edge  = DeepCopy(modernAzeroth.surface.divider)

-- Theme packs available under modern_azeroth (Class default, ToonAge Gold, Blizzard Modern).
Theme.packs = {
    class = {
        name       = "class",
        label      = "Class Theme",
        shell_fill = { 0.059, 0.090, 0.122, 0.78 }, -- #0F171F @ 0.78
        rim        = { 0.722, 0.776, 0.820, 0.50 }, -- #B8C6D1 @ 0.50
        solid_cta  = false,
    },
    toonage_gold = {
        name       = "toonage_gold",
        label      = "ToonAge Gold",
        shell_fill = { 0.078, 0.125, 0.165, 0.76 }, -- #14202A @ 0.76
        rim        = { 0.722, 0.776, 0.820, 0.52 }, -- #B8C6D1 @ 0.52
        accent     = { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 1.00 },
        cta_bg     = { GOLD_ACCENT[1], GOLD_ACCENT[2], GOLD_ACCENT[3], 1.00 },
        cta_text   = { 0.102, 0.055, 0.008, 1.00 }, -- #1A0E02 text_on_gold
        solid_cta  = true,
    },
    blizzard = {
        name       = "blizzard",
        label      = "Blizzard Modern",
        shell_fill = { 0.067, 0.078, 0.098, 0.84 }, -- #111419 @ 0.84
        rim        = { 0.561, 0.482, 0.345, 0.45 }, -- #8F7B58 @ 0.45
        accent     = { BLIZZ_ACCENT[1], BLIZZ_ACCENT[2], BLIZZ_ACCENT[3], 1.00 },
        solid_cta  = false,
    },
}

Theme.skins = {
    classic        = classic,
    glass          = glass,
    modern_azeroth = modernAzeroth,
}
Theme.active = DeepCopy(classic)
Theme._pack = "class"
Theme._classToken = nil
Theme._reducedMotion = false

--- Return the active single accent colour { r, g, b, a } with luminance guard.
function Theme:GetAccent(classToken)
    local pack = self.packs[self._pack] or self.packs.class
    if pack.name == "class" then
        local raw = self:ResolveClassColor(classToken or self._classToken)
        return LiftForDarkBg(raw[1], raw[2], raw[3])
    end
    local c = pack.accent or GOLD_ACCENT
    return { c[1], c[2], c[3], c[4] or 1.00 }
end

local function ApplyPackToActive(self, packName, classToken)
    if type(packName) ~= "string" or type(self.packs[packName]) ~= "table" then
        packName = "class"
    end
    self._pack = packName
    if classToken ~= nil then
        self._classToken = classToken
    end
    if self.active.name ~= "modern_azeroth" then
        return
    end
    local pack = self.packs[packName]
    local accent = self:GetAccent(self._classToken)
    self.active.pack = packName

    Sync(self.active.glass.shell_fill, pack.shell_fill)
    Sync(self.active.glass.rim, pack.rim)
    Sync(self.active.ui_frame_bg, pack.shell_fill)
    Sync(self.active.ui_frame_edge, pack.rim)
    Sync(self.active.ui_title_bg, pack.shell_fill)
    Sync(self.active.ui_tab_bg, pack.shell_fill)

    Sync(self.active.accent.primary, accent)
    Sync(self.active.accent.cta_border, accent)
    Sync(self.active.accent.tab_wash, { accent[1], accent[2], accent[3], 0.10 })
    Sync(self.active.text_accent, accent)

    if pack.solid_cta and pack.cta_bg and pack.cta_text then
        Sync(self.active.accent.cta_bg, pack.cta_bg)
        Sync(self.active.accent.cta_text, pack.cta_text)
    else
        Sync(self.active.accent.cta_bg, DarkTintedCTA(accent))
        Sync(self.active.accent.cta_text, self.active.text_primary)
    end

    if type(self.active.talent) == "table" then
        Sync(self.active.talent.focus, accent)
        Sync(self.active.talent.plan_route, { accent[1], accent[2], accent[3], 0.95 })
    end
end

--- Switch only the theme pack (class / toonage_gold / blizzard) while keeping
--- the active skin and existing table identities intact.
function Theme:SelectPack(packName, classToken)
    ApplyPackToActive(self, packName, classToken)
end

--- Set reduced-motion preference. Nothing functional may depend on animation.
function Theme:SetReducedMotion(enabled)
    local on = enabled and true or false
    self._reducedMotion = on
    if type(self.active.motion) ~= "table" then
        self.active.motion = {}
    end
    self.active.motion.reduced = on
end

function Theme:IsReducedMotion()
    return self._reducedMotion == true
end

--- Copy one skin into Theme.active, in place. Unknown names fall back to classic.
--- Safe to call before SavedVariables exist. Optional packName and classToken
--- configure modern_azeroth in one step.
function Theme:Select(name, packName, classToken)
    if type(name) ~= "string" or type(self.skins[name]) ~= "table" then
        name = "classic"
    end
    Sync(self.active, self.skins[name])
    self.active.name = name
    if name == "modern_azeroth" then
        ApplyPackToActive(self, packName or self._pack or "class", classToken)
    end
    self:SetReducedMotion(self._reducedMotion)
end

Theme:Select("classic")
