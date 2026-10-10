#!/usr/bin/env python3
"""/ta way, bare /way, and /ta talentsync.

Players type coordinates on a 0-100 scale. The arrow stores 0-1. A zone name
or a mapID may precede the pair, and a label may follow it. Bare /way is
registered on PLAYER_LOGIN, and only when TomTom is not loaded and no other
SlashCmdList entry already owns the command. A later ADDON_LOADED that claims
/way clears our binding, including hash_SlashCmdList['/WAY'] when that table
exists. /ta talentsync calls Data/Retail/Talents.lua SyncFromBetterTalents.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def near(got, want):
    return got is not None and abs(float(got) - want) < 0.0001


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


BOOT = r"""
_lines = {}
ToonAge = {
    modules = {},
    LOG = { OUTPUT = 0, INFO = 3, DEBUG = 4 },
    Utils = {},
    Data = {},
    TalentsAPI = {},
}
function ToonAge:RegisterModule(name, mod)
    self.modules[name] = mod
    self[name] = mod
end
function ToonAge:RegisterEvent() end
function ToonAge:Raw(_, msg) _lines[#_lines + 1] = tostring(msg) end
function ToonAge:Print(_, _, msg) _lines[#_lines + 1] = tostring(msg) end
-- Stand-in for the real dispatch. The guard test loads Core/Init.lua and
-- uses the real SlashCommand; this one only keeps the arrow file's checks
-- able to see the text bare /way hands over.
function ToonAge:SlashCommand(msg)
    BARE_DISPATCH = msg
    local A = self.modules.Arrow
    if not A or A._disabled or A._profileSkipped then
        self:Print(0, nil, "/ta way belongs to Arrow, which is not running here ("
            .. ((A and A._profileReason) or "switched off") .. ").")
        return
    end
    local raw = tostring(msg or ""):match("^%s*(.-)%s*$") or ""
    local rawArgs = raw:match("^%S+%s*(.*)$") or ""
    A.SlashCommands.way(A, rawArgs)
end
SlashCmdList = {}
C_Map = {
    GetBestMapForUnit = function() return 84 end,
    GetMapInfo = function(id)
        if id == 84 then return { name = "Stormwind City", mapType = 3 } end
        if id == 14 then return { name = "Arathi Highlands", mapType = 3 } end
        if id == 2372 then return { name = "Arathi Highlands", mapType = 3 } end
        return nil
    end,
}
function Way(args)
    _lines = {}
    local A = ToonAge.modules.Arrow
    A:ClearWaypoint()
    A.SlashCommands.way(A, args)
    local wp = A.manualWaypoint
    WAY_MAP = wp and wp.map or nil
    WAY_X = wp and wp.x or nil
    WAY_Y = wp and wp.y or nil
    WAY_TITLE = wp and wp.title or nil
    WAY_TEXT = table.concat(_lines, "\n")
end
function BootArrow()
    local A = ToonAge.modules.Arrow
    A.InitFrame = function() end
    A:Init()
end
function LoginArrow()
    ToonAge.modules.Arrow:OnWayWatch("PLAYER_LOGIN")
end
function AddonLoaded()
    ToonAge.modules.Arrow:OnWayWatch("ADDON_LOADED")
end
"""


def load_arrow(rel):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read(rel))
    return lua


def g(lua, name):
    return lua.eval(name)


def check_arrow(rel, label):
    lua = load_arrow(rel)
    check(f"{label} registers way", g(lua, "type(ToonAge.modules.Arrow.SlashCommands.way)"), "function")

    lua.execute('Way("45.2 67.8 My Place")')
    check(f"{label} current map", g(lua, "WAY_MAP"), 84)
    check(f"{label} x is divided by 100", near(g(lua, "WAY_X"), 0.452))
    check(f"{label} y is divided by 100", near(g(lua, "WAY_Y"), 0.678))
    check(f"{label} label is kept", g(lua, "WAY_TITLE"), "My Place")

    lua.execute('Way("45,2 67,8")')
    check(f"{label} comma decimals divide by 100", near(g(lua, "WAY_X"), 0.452) and near(g(lua, "WAY_Y"), 0.678))

    lua.execute('Way("45,67")')
    check(f"{label} single token A,B is x and y", near(g(lua, "WAY_X"), 0.45) and near(g(lua, "WAY_Y"), 0.67))

    lua.execute('Way("45.2,67.8 The Bank")')
    check(f"{label} dotted pair divides by 100", near(g(lua, "WAY_X"), 0.452) and near(g(lua, "WAY_Y"), 0.678))
    check(f"{label} dotted pair keeps the label", g(lua, "WAY_TITLE"), "The Bank")

    lua.execute('Way("45,67 The Bank")')
    check(f"{label} pair label keeps capitals", g(lua, "WAY_TITLE"), "The Bank")

    lua.execute('Way("2393 45,67 Spot")')
    check(f"{label} mapID plus A,B", g(lua, "WAY_MAP"), 2393)
    check(f"{label} mapID plus A,B divides by 100", near(g(lua, "WAY_X"), 0.45) and near(g(lua, "WAY_Y"), 0.67))
    check(f"{label} mapID plus A,B keeps the label", g(lua, "WAY_TITLE"), "Spot")

    lua.execute('Way("2393 10 20 My Spot")')
    check(f"{label} mapID is accepted", g(lua, "WAY_MAP"), 2393)
    check(f"{label} mapID x is divided by 100", near(g(lua, "WAY_X"), 0.10))
    check(f"{label} mapID y is divided by 100", near(g(lua, "WAY_Y"), 0.20))
    check(f"{label} mapID label is kept", g(lua, "WAY_TITLE"), "My Spot")

    lua.execute('Way("Stormwind City 45.2,67.8 The Bank")')
    check(f"{label} zone plus A,B resolves", g(lua, "WAY_MAP"), 84)
    check(f"{label} zone plus A,B divides by 100", near(g(lua, "WAY_X"), 0.452) and near(g(lua, "WAY_Y"), 0.678))
    check(f"{label} zone plus A,B keeps the label", g(lua, "WAY_TITLE"), "The Bank")

    lua.execute('Way("Stormwind City 12.5 34 The Bank")')
    check(f"{label} zone name resolves", g(lua, "WAY_MAP"), 84)
    check(f"{label} zone x is divided by 100", near(g(lua, "WAY_X"), 0.125))
    check(f"{label} zone y is divided by 100", near(g(lua, "WAY_Y"), 0.34))
    check(f"{label} zone label is kept", g(lua, "WAY_TITLE"), "The Bank")

    lua.execute('Way("Nopeville 10 20")')
    check(f"{label} unknown zone sets nothing", g(lua, "WAY_MAP") is None)
    check(f"{label} unknown zone is reported", "Unknown zone: Nopeville" in g(lua, "WAY_TEXT"))

    lua.execute("BootArrow()")
    check(f"{label} arrow setup does not register /way", g(lua, "SLASH_TOONAGEWAY1") is None)
    check(f"{label} arrow setup leaves no handler", g(lua, "SlashCmdList.TOONAGEWAY") is None)
    lua.execute("LoginArrow()")
    check(f"{label} PLAYER_LOGIN registers /way", g(lua, "SLASH_TOONAGEWAY1"), "/way")
    check(f"{label} PLAYER_LOGIN installs the handler", g(lua, "type(SlashCmdList.TOONAGEWAY)"), "function")
    lua.execute('ToonAge.modules.Arrow:ClearWaypoint(); SlashCmdList.TOONAGEWAY("10 20 Bare")')
    wp = g(lua, "ToonAge.modules.Arrow.manualWaypoint")
    check(f"{label} bare /way divides by 100",
          wp is not None and wp.map == 84 and near(wp.x, 0.10) and near(wp.y, 0.20) and wp.title == "Bare")

    lua.execute(r"""
        local A = ToonAge.modules.Arrow
        local orig = A.SlashCommands.way
        local seen
        A.SlashCommands.way = function(self, args)
            seen = args
            return orig(self, args)
        end
        A:ClearWaypoint()
        SlashCmdList.TOONAGEWAY("10 20 The Bank")
        BARE_SEEN = seen
        BARE_TITLE = A.manualWaypoint and A.manualWaypoint.title
        A.SlashCommands.way = orig
    """)
    check(f"{label} bare /way uses the way handler", g(lua, "BARE_SEEN"), "10 20 The Bank")
    check(f"{label} bare /way keeps label capitals", g(lua, "BARE_TITLE"), "The Bank")
    check(f"{label} bare /way goes through dispatch", g(lua, "BARE_DISPATCH"), "way 10 20 The Bank")

    claimed = load_arrow(rel)
    claimed.execute(r"""
        C_AddOns = { IsAddOnLoaded = function(name) return name == "TomTom" end }
        BootArrow()
        LoginArrow()
        TOMTOM_STILL = SLASH_TOONAGEWAY1
        TOMTOM_HANDLER = SlashCmdList.TOONAGEWAY
    """)
    check(f"{label} PLAYER_LOGIN skips /way when TomTom is loaded", g(claimed, "TOMTOM_STILL") is None)
    check(f"{label} TomTom leaves no ToonAge handler", g(claimed, "TOMTOM_HANDLER") is None)

    classic = load_arrow(rel)
    classic.execute(r"""
        C_AddOns = nil
        IsAddOnLoaded = function(name) return name == "TomTom" end
        BootArrow()
        LoginArrow()
        CLASSIC_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} IsAddOnLoaded blocks /way at login", g(classic, "CLASSIC_WAY") is None)

    thrown = load_arrow(rel)
    thrown.execute(r"""
        C_AddOns = { IsAddOnLoaded = function() error("missing") end }
        IsAddOnLoaded = function(name) return name == "TomTom" end
        BootArrow()
        LoginArrow()
        THROWN_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} a throwing C_AddOns check still honors IsAddOnLoaded", g(thrown, "THROWN_WAY") is None)

    foreign = load_arrow(rel)
    foreign.execute(r"""
        SlashCmdList.TOMTOM_WAY = function() end
        SLASH_TOMTOM_WAY1 = "/way"
        BootArrow()
        LoginArrow()
        FOREIGN_OURS = SLASH_TOONAGEWAY1
        FOREIGN_THEIRS = SlashCmdList.TOMTOM_WAY
    """)
    check(f"{label} an existing /way is not replaced at login", g(foreign, "FOREIGN_OURS") is None)
    check(f"{label} the other handler is left in place", g(foreign, "type(FOREIGN_THEIRS)"), "function")

    orphan = load_arrow(rel)
    orphan.execute(r"""
        SLASH_ORPHAN1 = "/way"
        BootArrow()
        LoginArrow()
        ORPHAN_OURS = SLASH_TOONAGEWAY1
    """)
    check(f"{label} a stray SLASH_ global does not block /way", g(orphan, "ORPHAN_OURS"), "/way")

    cheap = load_arrow(rel)
    cheap.execute(r"""
        local A = ToonAge.modules.Arrow
        SlashCmdList.OTHER = function() end
        SLASH_OTHER1 = "/other"
        SLASH_OTHER2 = "/WAY"
        SLASH_UNRELATED1 = "/way"
        CHEAP_ALIAS = A.ForeignWaySlash()
        SlashCmdList.OTHER = nil
        SLASH_OTHER1, SLASH_OTHER2 = nil, nil
        CHEAP_STRAY = A.ForeignWaySlash()
    """)
    check(f"{label} the cheap scan sees SLASH_<KEY>2", g(cheap, "CHEAP_ALIAS"), True)
    check(f"{label} the cheap scan ignores a SLASH_ global with no list key", g(cheap, "CHEAP_STRAY"), False)

    later = load_arrow(rel)
    later.execute(r"""
        BootArrow()
        LoginArrow()
        hash_SlashCmdList = { ["/WAY"] = SlashCmdList.TOONAGEWAY }
        C_AddOns = { IsAddOnLoaded = function(name) return name == "TomTom" end }
        SLASH_TOMTOM_WAY1 = "/way"
        SlashCmdList.TOMTOM_WAY = function() end
        AddonLoaded()
        LATER_OURS = SLASH_TOONAGEWAY1
        LATER_HANDLER = SlashCmdList.TOONAGEWAY
        LATER_HASH = hash_SlashCmdList["/WAY"]
        LATER_THEIRS = SLASH_TOMTOM_WAY1
    """)
    check(f"{label} ADDON_LOADED gives /way up once TomTom loads", g(later, "LATER_OURS") is None)
    check(f"{label} ADDON_LOADED clears the ToonAge handler", g(later, "LATER_HANDLER") is None)
    check(f"{label} ADDON_LOADED clears hash_SlashCmdList['/WAY']", g(later, "LATER_HASH") is None)
    check(f"{label} TomTom's /way stays", g(later, "LATER_THEIRS"), "/way")

    quiet = load_arrow(rel)
    quiet.execute(r"""
        BootArrow()
        LoginArrow()
        AddonLoaded()
        QUIET_OURS = SLASH_TOONAGEWAY1
        QUIET_HANDLER = SlashCmdList.TOONAGEWAY
    """)
    check(f"{label} an unrelated ADDON_LOADED keeps /way", g(quiet, "QUIET_OURS"), "/way")
    check(f"{label} an unrelated ADDON_LOADED keeps the handler", g(quiet, "type(QUIET_HANDLER)"), "function")

    yielded = load_arrow(rel)
    yielded.execute(r"""
        BootArrow()
        LoginArrow()
        hash_SlashCmdList = nil
        SlashCmdList.LATE = function() end
        SLASH_LATE1 = "/way"
        local ok, err = pcall(function() AddonLoaded() end)
        YIELD_OK = ok
        YIELD_ERR = err
        YIELD_OURS = SLASH_TOONAGEWAY1
        YIELD_HANDLER = SlashCmdList.TOONAGEWAY
        YIELD_THEIRS = SLASH_LATE1
    """)
    check(f"{label} giving /way up with no hash does not error", g(yielded, "YIELD_OK"), True)
    check(f"{label} a later addon takes /way back", g(yielded, "YIELD_OURS") is None and g(yielded, "YIELD_HANDLER") is None)
    check(f"{label} the later addon's slash stays", g(yielded, "YIELD_THEIRS"), "/way")

    quiet_mod = load_arrow(rel)
    quiet_mod.execute(r"""
        local A = ToonAge.modules.Arrow
        A._disabled = true
        BootArrow()
        LoginArrow()
        DISABLED_WAY = SLASH_TOONAGEWAY1
        A._disabled = nil
        A._profileSkipped = true
        A._profileReason = "not in this flavor's profile"
        LoginArrow()
        SKIPPED_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} a disabled arrow does not claim /way", g(quiet_mod, "DISABLED_WAY") is None)
    check(f"{label} a profile-skipped arrow does not claim /way", g(quiet_mod, "SKIPPED_WAY") is None)

    denied = load_arrow(rel)
    denied.execute(r"""
        function ToonAge:ModuleAllowed() return false, "not in profile" end
        BootArrow()
        LoginArrow()
        DENIED_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} an arrow that is not allowed for this client does not claim /way",
          g(denied, "DENIED_WAY") is None)

    toggled = load_arrow(rel)
    toggled.execute(r"""
        ToonAgeDB = { modules = { Arrow = false } }
        BootArrow()
        LoginArrow()
        TOGGLED_WAY = SLASH_TOONAGEWAY1
    """)
    check(f"{label} a switched-off arrow does not claim /way", g(toggled, "TOGGLED_WAY") is None)

    src = read(rel)
    check(f"{label} ForeignWaySlash does not scan _G", "pairs(_G)" not in src)
    check(f"{label} the hash clear is guarded", "if hash_SlashCmdList then" in src)
    check(f"{label} the hash key is /WAY", 'hash_SlashCmdList["/WAY"]' in src)


def check_label_case():
    """Dispatch lowercases every command except the text /ta way shows."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from test_onboarding import PRELUDE, _read  # noqa: E402
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(r"""
        ToonAgeDB = {}
        local TA = ToonAge
        TA:InitDB()
        local wayArgs, otherArgs
        TA.modules.Arrow = {
            SlashCommands = {
                way = function(self, args) wayArgs = args end,
            },
        }
        TA.modules.Notes = {
            SlashCommands = {
                zznote = function(self, args) otherArgs = args end,
            },
        }
        function Run(msg)
            wayArgs, otherArgs = nil, nil
            TA:SlashCommand(msg)
            WAY_ARGS, OTHER_ARGS = wayArgs, otherArgs
        end
    """)
    lua.eval("Run")("way 45.2 67.8 The Bank")
    check("/ta way keeps the label capitals", g(lua, "WAY_ARGS"), "45.2 67.8 The Bank")
    check("/ta way does not hand the label to another module", g(lua, "OTHER_ARGS") is None)
    lua.eval("Run")("wa 10 20 The Bank")
    check("an abbreviated /ta way keeps the label capitals", g(lua, "WAY_ARGS"), "10 20 The Bank")
    lua.eval("Run")("zznote The Bank")
    check("another command still receives lowercased args", g(lua, "OTHER_ARGS"), "the bank")
    check("another command does not see the way handler", g(lua, "WAY_ARGS") is None)


def check_arrow_paint(rel, label):
    """A /way point uses the guide arrow, then the arrived ring, and a body-color label."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, LOG = { OUTPUT = 0, INFO = 3 } }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod; self[name] = mod end
        function ToonAge:RegisterEvent() end
        function ToonAge:GetModule() return nil end
        function ToonAge:Raw() end
        function ToonAge:Print() end
        function Piece()
            local p = { shown = true }
            function p:SetTexture(v) self.tex = v end
            function p:SetSize() end
            function p:SetAlpha(a) self.alpha = a end
            function p:SetRotation() end
            function p:Show() self.shown = true end
            function p:Hide() self.shown = false end
            function p:SetText(t) self.text = t end
            function p:SetTextColor(r, g, b, a) self.r, self.g, self.b, self.a = r, g, b, a end
            function p:SetPoint(point, rel, relPoint, x, y)
                self.anchor = { point, rel, relPoint, x, y }
            end
            function p:IsVisible() return self.shown end
            function p:IsShown() return self.shown end
            return p
        end
        function Frame()
            local f = Piece()
            function f:SetAlpha(a) self.alpha = a end
            function f:EnableMouse() end
            f.arrowTex = Piece()
            f.arrivedTex = Piece()
            f.distF = Piece()
            f.etaF = Piece()
            f.titleF = Piece()
            f._arrowSize = 48
            return f
        end
        C_Map = {
            GetBestMapForUnit = function() return 84 end,
            GetPlayerMapPosition = function()
                return { GetXY = function() return 0.10, 0.20 end }
            end,
            GetMapInfo = function() return nil end,
        }
        GetPlayerFacing = function() return 0 end
        GetTime = function() return 1000 end
    """)
    lua.execute(read("Core/Utils.lua"))
    lua.execute(read(rel))
    lua.execute(r"""
        local A = ToonAge.modules.Arrow
        local f = Frame()
        A.frame = f
        -- 0.05 map units east of the player is 100 yards: one "%d yd" string.
        A:SetWaypoint(84, 0.15, 0.20, "The Bank")
        A:Tick(f)
        FAR_TEX = f.arrowTex.tex
        FAR_ARROW = f.arrowTex.shown
        FAR_ARRIVED = f.arrivedTex.shown
        FAR_TITLE = f.titleF.text
        FAR_R, FAR_G, FAR_B = f.titleF.r, f.titleF.g, f.titleF.b
        FAR_DIST = f.distF.text
        WANT_DIST = ToonAge.Utils.FormatDistance(ToonAge.Utils.ComputeDistance(0.10, 0.20, 0.15, 0.20))
        FAR_ETA = f.etaF.text
        local a = f.titleF.anchor
        FAR_POINT, FAR_TO, FAR_X, FAR_Y = a[1], a[3], a[4], a[5]
        FAR_ON_DIST = a[2] == f.distF
        local e = f.etaF.anchor
        FAR_ETA_POINT, FAR_ETA_TO, FAR_ETA_X, FAR_ETA_Y = e[1], e[3], e[4], e[5]
        FAR_ETA_ON_TITLE = e[2] == f.titleF
        A:SetWaypoint(84, 0.10, 0.20, "The Bank")
        A:Tick(f)
        NEAR_TEX = f.arrivedTex.tex
        NEAR_ARROW = f.arrowTex.shown
        NEAR_ARRIVED = f.arrivedTex.shown
        NEAR_DIST = f.distF.text
        NEAR_ETA = f.etaF.text
        NEAR_TITLE = f.titleF.text
        A:ClearWaypoint()
        A:Tick(f)
        IDLE_TITLE = f.titleF.text
        IDLE_R, IDLE_G, IDLE_B = f.titleF.r, f.titleF.g, f.titleF.b
        local idle = f.titleF.anchor
        IDLE_ON_ETA = idle[2] == f.etaF
        IDLE_Y = idle[5]
    """)
    far = g(lua, "FAR_TEX") or ""
    near = g(lua, "NEAR_TEX") or ""
    check(f"{label} /way uses the guide arrow art", "util_waypoint.tga" in far and "hollow" not in far and "arrived" not in far)
    check(f"{label} /way arrow is showing on the way", g(lua, "FAR_ARROW"), True)
    check(f"{label} /way hides the arrived ring on the way", g(lua, "FAR_ARRIVED"), False)
    check(f"{label} /way shows the label", g(lua, "FAR_TITLE"), "The Bank")
    check(f"{label} /way label is body text, not gold",
          (round(g(lua, "FAR_R"), 2), round(g(lua, "FAR_G"), 2), round(g(lua, "FAR_B"), 2)),
          (0.92, 0.90, 0.87))
    check(f"{label} distance is one string in one weight",
          g(lua, "FAR_DIST") == g(lua, "WANT_DIST")
          and str(g(lua, "FAR_DIST")).endswith(" yd")
          and "|c" not in str(g(lua, "FAR_DIST")))
    check(f"{label} distance has no color code", "|c" not in (g(lua, "FAR_DIST") or ""))
    check(f"{label} ETA is body text under the label", g(lua, "FAR_ETA"), "15s")
    check(f"{label} ETA has no color code", "|c" not in (g(lua, "FAR_ETA") or ""))
    check(f"{label} the ETA is the third line, 2px under the label",
          g(lua, "FAR_ETA_ON_TITLE") and g(lua, "FAR_ETA_POINT") == "TOP"
          and g(lua, "FAR_ETA_TO") == "BOTTOM" and g(lua, "FAR_ETA_X") == 0
          and g(lua, "FAR_ETA_Y") == -2)
    src = read(rel)
    check(f"{label} distance font is body weight, not outline",
          'distF:SetFont(STANDARD_TEXT_FONT, 14, "")' in src
          and 'distF:SetTextColor(0.92, 0.90, 0.87, 1)' in src)
    check(f"{label} ETA font is the same body weight",
          'etaF:SetFont(STANDARD_TEXT_FONT, 10, "")' in src
          and 'etaF:SetTextColor(0.92, 0.90, 0.87, 1)' in src)
    check(f"{label} a moving ETA stays a plain duration",
          "|cFFCCCCCC" not in src and "ETA|r" not in src)
    check(f"{label} the typed label is 2px under the distance",
          g(lua, "FAR_ON_DIST") and g(lua, "FAR_POINT") == "TOP" and g(lua, "FAR_TO") == "BOTTOM"
          and g(lua, "FAR_X") == 0 and g(lua, "FAR_Y") == -2)
    check(f"{label} arrival uses util_waypoint_arrived", "util_waypoint_arrived.tga" in near)
    check(f"{label} arrival hides the pointing arrow", g(lua, "NEAR_ARROW"), False)
    check(f"{label} arrival shows the ring", g(lua, "NEAR_ARRIVED"), True)
    check(f"{label} arrival hides the distance text", g(lua, "NEAR_DIST"), "")
    check(f"{label} arrival hides the ETA", g(lua, "NEAR_ETA"), "")
    check(f"{label} arrival hides the typed label", g(lua, "NEAR_TITLE"), "")
    check(f"{label} a guide step with no waypoint stays gold",
          g(lua, "IDLE_TITLE") == "No Waypoint"
          and (round(g(lua, "IDLE_R"), 2), round(g(lua, "IDLE_G"), 2), round(g(lua, "IDLE_B"), 2)) == (1.0, 0.82, 0.0))
    check(f"{label} a guide title stays under the ETA",
          g(lua, "IDLE_ON_ETA") and g(lua, "IDLE_Y") == -4)


def check_bare_dispatch():
    """Bare /way uses RunModuleSlash, and help on an arrow-less client omits it."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from test_onboarding import PRELUDE, _read  # noqa: E402
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(read("Modules/Navigation/Arrow.lua"))
    lua.execute(r"""
        ToonAgeDB = {}
        ToonAge:InitDB()
        C_Map = {
            GetBestMapForUnit = function() return 84 end,
            GetMapInfo = function(id)
                if id == 84 then return { name = "Stormwind City", mapType = 3 } end
                return nil
            end,
        }
        HELP = {}
        function ToonAge:BeginReport()
            return {
                Add = function(_, line) HELP[#HELP + 1] = tostring(line) end,
                Finish = function() end,
            }
        end
        local A = ToonAge.modules.Arrow
        A.InitFrame = function() end
        function HelpText()
            HELP = {}
            ToonAge:PrintInteractiveHelp()
            return table.concat(HELP, "\n")
        end
        function RunBare(msg)
            _printed = {}
            A:RunBareWay(msg)
            PRINTED = table.concat(_printed, "\n")
            local wp = A.manualWaypoint
            RAN_TITLE = wp and wp.title or nil
        end
    """)
    lua.execute(r"""
        local A = ToonAge.modules.Arrow
        A._disabled = true
        A:OnWayWatch("PLAYER_LOGIN")
        CLAIMED = SLASH_TOONAGEWAY1
        RunBare("10 20 The Bank")
        OFF_PRINTED = PRINTED
        OFF_TITLE = RAN_TITLE
        A._disabled = true
        A._safeSkipped = true
        A._profileReason = nil
        A._profileSkipped = nil
        RunBare("10 20 The Bank")
        SAFE_PRINTED = PRINTED
        SAFE_TITLE = RAN_TITLE
        A._disabled = true
        A._safeSkipped = nil
        A._profileSkipped = true
        A._profileReason = "wrong build for this client"
        RunBare("1 2 The Bank")
        SKIP_PRINTED = PRINTED
        HELP_OFF = HelpText()
        A._disabled = false
        A._profileSkipped = nil
        A._profileReason = nil
        A._safeSkipped = nil
        RunBare("10 20 The Bank")
        LIVE_PRINTED = PRINTED
        LIVE_TITLE = RAN_TITLE
        HELP_ON = HelpText()
    """)
    check("a disabled arrow's /way does not set a waypoint", g(lua, "OFF_TITLE") is None)
    check("a disabled arrow's /way says it is not running",
          "belongs to Arrow, which is not running here (switched off)." in g(lua, "OFF_PRINTED"))
    check("a safe-skipped arrow's /way says it is not running",
          "belongs to Arrow, which is not running here (switched off)." in g(lua, "SAFE_PRINTED")
          and g(lua, "SAFE_TITLE") is None)
    check("a wrong-client arrow's /way names the reason",
          "belongs to Arrow, which is not running here (wrong build for this client)." in g(lua, "SKIP_PRINTED"))
    check("a disabled arrow is left out of help", "tacommand:way" not in g(lua, "HELP_OFF"))
    check("bare /way keeps the label when the arrow is running", g(lua, "LIVE_TITLE"), "The Bank")
    check("help lists /ta way when the arrow is running", "tacommand:way" in g(lua, "HELP_ON"))
    check("PLAYER_LOGIN does not claim /way while the arrow is disabled", g(lua, "CLAIMED") is None)

    bare = lua51.LuaRuntime(unpack_returned_tuples=True)
    bare.execute(PRELUDE)
    bare.execute(_read("Core/Init.lua"))
    bare.execute(r"""
        ToonAgeDB = {}
        ToonAge:InitDB()
        HELP = {}
        function ToonAge:BeginReport()
            return {
                Add = function(_, line) HELP[#HELP + 1] = tostring(line) end,
                Finish = function() end,
            }
        end
        ToonAge:PrintInteractiveHelp()
        HELP_TEXT = table.concat(HELP, "\n")
    """)
    help_text = g(bare, "HELP_TEXT")
    check("help without an arrow does not mention /ta way", "/ta way" not in help_text and "tacommand:way" not in help_text)

    for toc in ("ToonAge_TBC.toc", "ToonAge_Vanilla.toc", "ToonAge_Wrath.toc",
                "ToonAge_Cata.toc", "ToonAge_Camelot.toc"):
        files = []
        for line in read(toc).splitlines():
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            s = s.split("[")[0].strip().replace("\\", "/")
            if s.lower().endswith(".lua"):
                files.append(s)
        hits = []
        for rel in files:
            body = read(rel)
            if ('"/ta way' in body or "'/ta way" in body
                    or '"/way"' in body or "'/way'" in body):
                hits.append(rel)
        check(f"{toc} has no help text for /ta way or /way", hits, [])


def check_talents():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BOOT)
    lua.execute(read("Data/Retail/Talents.lua"))
    lua.execute(read("Modules/Character/Talents.lua"))
    lua.execute(r"""
        local T = ToonAge.Data.Talents
        local spec = T:GetBySpecID(265)
        spec.builds.mplus.string = "KEEP"
        BetterTalents = {
            BuildData = {
                Affliction = { mplus_overall = "NEW", raid_mythic = "RAIDSTR" },
            },
        }
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        MPLUS = spec.builds.mplus.string
        RAID = spec.builds.raid.string
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        SECOND = table.concat(_lines, "\n")
        MPLUS2 = spec.builds.mplus.string
        RAID2 = spec.builds.raid.string
        BetterTalents = nil
        _lines = {}
        ToonAge.modules.Talents.SlashCommands.talentsync()
        MISSING = table.concat(_lines, "\n")
    """)
    check("talentsync keeps a pasted string", g(lua, "MPLUS"), "KEEP")
    check("talentsync fills an empty raid string", g(lua, "RAID"), "RAIDSTR")
    check("a second talentsync does not overwrite",
          g(lua, "MPLUS2") == "KEEP" and g(lua, "RAID2") == "RAIDSTR")
    check("a second talentsync says nothing new was filled",
          "No empty build slots were filled." in g(lua, "SECOND"))
    check("talentsync without BetterTalents explains itself",
          "BetterTalents is not loaded" in g(lua, "MISSING"))
    check("the data comment points at /ta talentsync",
          "/ta talentsync" in read("Data/Retail/Talents.lua"))


def main():
    check_arrow("Modules/Navigation/Arrow.lua", "retail")
    check_arrow("Modules/Mists/Arrow.lua", "mists")
    check_label_case()
    check_bare_dispatch()
    check_arrow_paint("Modules/Navigation/Arrow.lua", "retail")
    check_arrow_paint("Modules/Mists/Arrow.lua", "mists")
    check_talents()
    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
