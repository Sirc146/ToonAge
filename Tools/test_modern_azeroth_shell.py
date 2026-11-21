#!/usr/bin/env python3
"""Tests for Phase 2: Modern Azeroth 68px glass shell, Now lead tab, TGA kit, and Appearance settings.

Verifies:
- All 7 new Phase 2 TGA assets (type=2, 32-bit BGRA, desc=0x08, power-of-2, non-empty alpha)
- Compact 68px crown (34px title + 34px tabs), solid dark content well (zero glass-on-glass)
- Custom 24x24 r6 window controls (no macOS traffic lights, no UIPanelCloseButton)
- Full 12-tab Forever strip (Now first left of Character, monochrome glyphs, fits inside 900px)
- Live TA:ApplyTheme() switching between Modern Azeroth / Classic and Class / Gold / Blizzard packs
- Reduced motion snapping animations in Core/UIModern.lua with 0 tickers
- Modules/Forever/Now.lua fact->action prioritization, 0-churn pooled re-render, CountDescendants == 0
- Settings drawer APPEARANCE section live cycling

Usage:  python3 Tools/test_modern_azeroth_shell.py [-v]
"""
import struct
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
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def audit_tga(rel, want_w, want_h):
    p = ROOT / rel
    check(f"TGA exists: {rel}", p.exists(), True)
    if not p.exists():
        return
    b = p.read_bytes()
    imgtype = b[2]
    w, h, bpp, desc = struct.unpack("<HHBB", b[12:18])
    check(f"{rel}: uncompressed 32-bit BGRA desc=0x08", (imgtype, bpp, desc), (2, 32, 0x08))
    check(f"{rel}: dimensions {want_w}x{want_h}", (w, h), (want_w, want_h))
    pixel_bytes = w * h * 4
    check(f"{rel}: exact TGA 2.0 size", len(b), 18 + pixel_bytes + 26)
    alphas = b[18 + 3 : 18 + pixel_bytes : 4]
    check(f"{rel}: has non-zero alpha pixels", any(a > 0 for a in alphas), True)
    check(f"{rel}: valid TGA 2.0 footer", b[-18:], b"TRUEVISION-XFILE.\x00")


PRELUDE = r"""
WOW_PROJECT_ID = 1
GetBuildInfo = function() return "1.60.1", "70888", "Nov 2026", 16001 end
UnitClass = function() return "Hunter", "HUNTER" end
UnitLevel = function() return 24 end
UnitExists = function() return true end
UnitName = function() return "Examplechar" end
GetRealmName = function() return "ForeverRealm" end
tinsert = table.insert
wipe = function(t) for k in pairs(t) do t[k] = nil end end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ChatFontNormal = "ChatFontNormal"
UISpecialFrames = {}
StaticPopupDialogs = {}
RAID_CLASS_COLORS = {
    HUNTER = { r = 0.667, g = 0.827, b = 0.447 },
    MAGE   = { r = 0.247, g = 0.780, b = 0.922 },
}

tickersStarted = 0
C_Timer = {
    After = function(_, fn) if fn then fn() end end,
    NewTicker = function()
        tickersStarted = tickersStarted + 1
        return { Cancel = function() end }
    end,
}

createdFrames = 0

local function Widget(kind, name, template)
    local f = {
        _kind = kind, _name = name, _template = template,
        _children = {}, _regions = {}, _shown = true, _alpha = 1,
        _width = 0, _height = 0, _text = "", _fontSize = 11,
        _anchors = {}, _scripts = {}, _backdropColor = nil, _borderColor = nil,
        _texture = nil, _vertexColor = nil, _colorTex = nil, _level = 1,
    }
    local mt = {
        __index = function(_, key)
            if type(key) ~= "string" then return nil end
            if key == "GetChildren" then
                return function(self) return unpack(self._children) end
            end
            if key == "GetRegions" then
                return function(self) return unpack(self._regions) end
            end
            local head = key:sub(1, 3)
            if head == "Set" or head == "Get" or head == "Ena" or head == "Is"
                or head == "Reg" or key == "Hide" or key == "Show" or key == "ClearAllPoints" then
                return function() end
            end
            return nil
        end,
    }
    setmetatable(f, mt)
    function f:SetParent(parent)
        if self._parent and self._parent._children then
            for i = #self._parent._children, 1, -1 do
                if self._parent._children[i] == self then
                    table.remove(self._parent._children, i)
                end
            end
        end
        self._parent = parent
        if type(parent) == "table" and parent._children then
            local seen = false
            for i = 1, #parent._children do
                if parent._children[i] == self then seen = true end
            end
            if not seen then parent._children[#parent._children + 1] = self end
        end
    end
    function f:GetParent() return self._parent end
    function f:ClearAllPoints() self._anchors = {} end
    function f:SetPoint(point, rel, relPoint, x, y)
        if type(rel) == "number" then
            self._anchors[#self._anchors + 1] = { point = point, x = rel, y = relPoint or 0 }
        else
            self._anchors[#self._anchors + 1] = {
                point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0,
            }
        end
    end
    function f:SetAllPoints(rel)
        self:ClearAllPoints()
        self:SetPoint("ALL", rel or self._parent, "ALL", 0, 0)
    end
    function f:SetSize(w, h) self._width = w; self._height = h end
    function f:SetWidth(w) self._width = w end
    function f:SetHeight(h) self._height = h end
    function f:GetWidth() return self._width or 0 end
    function f:GetHeight() return self._height or 0 end
    function f:SetAlpha(a) self._alpha = a end
    function f:GetAlpha() return self._alpha or 1 end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:IsVisible() return self._shown end
    function f:SetFrameLevel(n) self._level = n end
    function f:GetFrameLevel() return self._level or 1 end
    function f:SetBackdrop(bd) self._backdrop = bd end
    function f:SetBackdropColor(r, g, b, a) self._backdropColor = { r, g, b, a } end
    function f:SetBackdropBorderColor(r, g, b, a) self._borderColor = { r, g, b, a } end
    function f:SetTexture(path) self._texture = path end
    function f:GetTexture() return self._texture end
    function f:SetVertexColor(r, g, b, a) self._vertexColor = { r, g, b, a } end
    function f:SetColorTexture(r, g, b, a) self._colorTex = { r, g, b, a } end
    function f:SetTextColor(r, g, b, a) self._textColor = { r, g, b, a } end
    function f:SetFont(_, size) if size then self._fontSize = size end end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text or "" end
    function f:GetStringWidth()
        local clean = tostring(self._text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return #clean * ((self._fontSize or 11) * 0.56)
    end
    function f:GetStringHeight() return (self._fontSize or 11) + 4 end
    function f:SetScript(ev, fn) self._scripts[ev] = fn end
    function f:GetScript(ev) return self._scripts[ev] end
    function f:CreateTexture()
        local t = Widget("Texture")
        t._parent = self
        self._regions[#self._regions + 1] = t
        return t
    end
    function f:CreateFontString()
        local fs = Widget("FontString")
        fs._parent = self
        self._regions[#self._regions + 1] = fs
        return fs
    end
    function f:SetScrollChild(ch) self._scrollChild = ch end
    function f:GetScrollChild() return self._scrollChild end
    function f:SetVerticalScroll(v) self._vscroll = v end
    function f:GetVerticalScroll() return self._vscroll or 0 end
    function f:GetVerticalScrollRange() return 0 end
    return f
end

function CreateFrame(kind, name, parent, template)
    createdFrames = createdFrames + 1
    local f = Widget(kind, name, template)
    if parent then f:SetParent(parent) end
    if name then _G[name] = f end
    return f
end

UIParent = Widget("Frame", "UIParent")
UIParent:SetSize(1920, 1080)

function CountDescendants(frame)
    if not frame or not frame.GetChildren then return 0 end
    local n = 0
    for _, child in ipairs({ frame:GetChildren() }) do
        if not child._laKind then
            n = n + 1 + CountDescendants(child)
        end
    end
    return n
end

ToonAge = {
    version = "2.0.0-dev.1",
    modules = {},
    Data = {},
    db = { disabledTabs = {}, harvest = { captures = {} } },
    charDB = {},
    Utils = {
        IsSecret = function() return false end,
        Glyph = function() return "*" end,
    },
    LOG = { OUTPUT = 0, ERROR = 1, WARN = 2 },
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
function ToonAge:GetRegisteredModule(name) return self.modules[name] end
function ToonAge:Print() end
"""


def rgb_tuple(t):
    return (round(t[1] * 255), round(t[2] * 255), round(t[3] * 255))


def main():
    # 1. TGA Art Audit
    audit_tga("Media/icons/tab_now.tga", 64, 64)
    audit_tga("Media/icons/tab_now_32.tga", 32, 32)
    audit_tga("Media/icons/tab_reputation.tga", 64, 64)
    audit_tga("Media/icons/tab_reputation_32.tga", 32, 32)
    audit_tga("Media/glass/spec_top.tga", 256, 32)
    audit_tga("Media/glass/panel_r12.tga", 64, 64)
    audit_tga("Media/glass/button_r6.tga", 32, 32)

    # 2. Load real engine + shell + ForeverNow + Settings
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Core/Environment.lua"))
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Profile.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Core/UI.lua"))
    lua.execute(read("Core/UIModern.lua"))
    lua.execute(read("Modules/Forever/Now.lua"))
    lua.execute(read("Modules/Infrastructure/Settings.lua"))

    # Stub the other Forever tab modules so all 12 Forever tabs are available
    lua.execute(r"""
        local dummyMods = {
            "ForeverCharacter", "ForeverGear", "ProfessionBoard", "FactionTracker",
            "ForeverTalents", "ForeverRotation", "ForeverPets", "ForeverPvP",
            "ForeverScrolls", "ForeverCastLog", "DataHarvester",
        }
        for _, name in ipairs(dummyMods) do
            ToonAge:RegisterModule(name, {
                Render = function(_, content, side)
                    content:SetHeight(200)
                    if side then side:SetHeight(200) end
                end,
            })
        end
        -- Provide realistic data sources for ForeverNow
        ToonAge.modules.ForeverRotation.TrainableNow = function()
            return { { name = "Arcane Shot (Rank 3)" }, { name = "Multi-Shot (Rank 1)" } }, 12, 12
        end
        ToonAge.modules.ForeverTalents.GetNextPlannedPoint = function()
            return {
                hasPlan = true,
                targetName = "Bestial Wrath",
                unspent = 1,
                gateNeed = 0,
                summary = "1 unspent. Next: Ferocity (toward Bestial Wrath).",
            }
        end
        ToonAge.modules.ForeverCharacter._ReadSkillLines = function()
            return {
                { id = 45, name = "Bows", rank = 90, max = 120 },
                { id = 95, name = "Defense", rank = 115, max = 120 },
            }
        end
        ToonAge.modules.ForeverCharacter._WeaponSkillFor = function(slot)
            if slot == 18 then return 45 end
            return nil
        end
        ToonAge.modules.ForeverCharacter.RenderSidebarPublic = function(_, side)
            if side then side:SetHeight(320) end
        end
        ToonAge.Harvester = { CharacterKey = function() return "ForeverRealm\tExamplechar\tHUNTER" end }
        ToonAge.db.harvest.captures["ForeverRealm\tExamplechar\tHUNTER"] = {
            spellbook = {}, talents = {},
        }

        ToonAge:InitUI()
    """)

    # 3. Verify 68px Modern Azeroth crown, controls, surfaces, and 12-tab fit
    res = lua.execute(r"""
        local f = ToonAge.UI
        local nowBtn = f.tabButtons.now
        local harvBtn = f.tabButtons.harvest
        local maxRight = 0
        local allHaveGlyphs = true
        local tabCount = 0
        for id, b in pairs(f.tabButtons) do
            tabCount = tabCount + 1
            if not b.glyph then allHaveGlyphs = false end
            local x = 0
            for _, a in ipairs(b._anchors) do
                if a.point == "LEFT" then x = a.x or 0 end
            end
            local right = x + b:GetWidth()
            if right > maxRight then maxRight = right end
        end
        local nowX = 999
        for _, a in ipairs(nowBtn._anchors) do
            if a.point == "LEFT" then nowX = a.x or 0 end
        end
        local charX = 999
        for _, a in ipairs(f.tabButtons.character._anchors) do
            if a.point == "LEFT" then charX = a.x or 0 end
        end
        return {
            skin = ToonAge.Theme.active.name,
            pack = ToonAge.Theme.active.pack,
            titleH = f.titleBar:GetHeight(),
            tabH = f.tabBar:GetHeight(),
            specShown = f.titleBar.specTop:IsShown(),
            logoTex = f.titleBar.titleIcon:GetTexture(),
            closeTemplate = f.closeBtn._template,
            closeIcon = f.closeBtn.icon:GetTexture(),
            closeW = f.closeBtn:GetWidth(),
            closeH = f.closeBtn:GetHeight(),
            optTexShown = f.optionsBtn.texIcon:IsShown(),
            optTex = f.optionsBtn.texIcon:GetTexture(),
            contentWellShown = f.contentWell:IsShown(),
            contentWellAlpha = f.contentWell._backdropColor[4],
            shellAlpha = f._backdropColor[4],
            tabCount = tabCount,
            allHaveGlyphs = allHaveGlyphs,
            nowX = nowX,
            charX = charX,
            maxRight = maxRight,
            activeTab = f.activeTab,
            activeLineColor = nowBtn.activeLine._colorTex,
            nowGlyphTex = nowBtn.glyph:GetTexture(),
            repGlyphTex = f.tabButtons.reputations.glyph:GetTexture(),
        }
    """)
    check("InitUI activates modern_azeroth + class pack by default", (res.skin, res.pack), ("modern_azeroth", "class"))
    check("Compact 68px crown (34px title + 34px tab bar)", (res.titleH, res.tabH, res.titleH + res.tabH), (34, 34, 68))
    check("Top glass specular highlight shown on modern_azeroth", res.specShown, True)
    check("Title icon uses ToonAge logo_mark_32.tga", "logo_mark_32.tga" in (res.logoTex or ""), True)
    check("Close button is custom 24x24 (no UIPanelCloseButton, no traffic lights)", (res.closeTemplate, res.closeW, res.closeH), (None, 24, 24))
    check("Close button uses audited util_close_16.tga", "util_close_16.tga" in (res.closeIcon or ""), True)
    check("Settings button uses audited util_settings_16.tga", (res.optTexShown, "util_settings_16.tga" in (res.optTex or "")), (True, True))
    check("Solid dark content well shown with alpha >= 0.95 (zero glass-on-glass)", (res.contentWellShown, res.contentWellAlpha >= 0.95), (True, True))
    check("Outer glass shell alpha <= 0.85", res.shellAlpha <= 0.85, True)
    check("All 12 Forever tabs mounted with monochrome glyphs", (res.tabCount, res.allHaveGlyphs), (12, True))
    check("Now tab is first, left of Character", res.nowX < res.charX and res.nowX == 8, True)
    check("All 12 Forever tabs fit inside 900px without clipping", res.maxRight <= 892, True)
    check("Initial active tab defaults to Now", res.activeTab, "now")
    check("Now active underline uses Hunter class color #AAD372", rgb_tuple(res.activeLineColor), (170, 211, 114))
    check("Now tab uses tab_now_32.tga", "tab_now_32.tga" in (res.nowGlyphTex or ""), True)
    check("Reputation tab uses tab_reputation_32.tga", "tab_reputation_32.tga" in (res.repGlyphTex or ""), True)

    # 4. Live TA:ApplyTheme() pack & skin switching (zero /reload)
    res = lua.execute(r"""
        local f = ToonAge.UI
        ToonAge:ApplyTheme(nil, "toonage_gold", nil)
        local goldLine = f.tabButtons.now.activeLine._colorTex
        local goldPack = ToonAge.Theme.active.pack

        ToonAge:ApplyTheme("classic", nil, nil)
        local classicTabH = f.tabBar:GetHeight()
        local classicSpec = f.titleBar.specTop:IsShown()
        local classicWell = f.contentWell:IsShown()

        ToonAge:ApplyTheme("modern_azeroth", "blizzard", true)
        local blizzTabH = f.tabBar:GetHeight()
        local blizzLine = f.tabButtons.now.activeLine._colorTex
        local blizzPack = ToonAge.Theme.active.pack

        -- Reduced motion: AnimateWidth/Height/Alpha must snap with 0 tickers
        local box = CreateFrame("Frame")
        box:SetSize(10, 10)
        box:SetAlpha(0.2)
        local done = 0
        tickersStarted = 0
        ToonAge.Modern:AnimateWidth(box, 200, 0.25, function() done = done + 1 end)
        ToonAge.Modern:AnimateHeight(box, 120, 0.20, function() done = done + 1 end)
        ToonAge.Modern:AnimateAlpha(box, 1.0, 0.15, function() done = done + 1 end)

        return {
            goldPack = goldPack,
            goldLine = goldLine,
            classicTabH = classicTabH,
            classicSpec = classicSpec,
            classicWell = classicWell,
            blizzTabH = blizzTabH,
            blizzPack = blizzPack,
            blizzLine = blizzLine,
            boxW = box:GetWidth(),
            boxH = box:GetHeight(),
            boxA = box:GetAlpha(),
            animDone = done,
            tickers = tickersStarted,
        }
    """)
    check("Live pack switch to ToonAge Gold retints active underline to #E8B35A", (res.goldPack, rgb_tuple(res.goldLine)), ("toonage_gold", (232, 179, 90)))
    check("Live switch to Classic restores 30px tab bar and hides glass layers", (res.classicTabH, res.classicSpec, res.classicWell), (30, False, False))
    check("Live switch back to Modern Azeroth + Blizzard Modern restores 34px tab bar and #F0C45A", (res.blizzTabH, res.blizzPack, rgb_tuple(res.blizzLine)), (34, "blizzard", (240, 196, 90)))
    check("Reduced motion snaps AnimateWidth/Height/Alpha with 0 tickers", (res.boxW, res.boxH, res.boxA, res.animDone, res.tickers), (200, 120, 1.0, 3, 0))

    # 5. ForeverNow fact->action priority + pooled 0-churn re-render
    res = lua.execute(r"""
        local Now = ToonAge:GetModule("ForeverNow")
        local items = Now:BuildItems()
        local cats = {}
        local prios = {}
        local allHaveActions = true
        for i, it in ipairs(items) do
            cats[i] = it.category
            prios[i] = it.priority
            if not (it.actionLabel and it.actionTab) then allHaveActions = false end
        end

        local content = CreateFrame("Frame")
        content:SetSize(640, 1)
        content._laPane = true
        local side = CreateFrame("Frame")
        side:SetSize(184, 1)

        Now:Render(content, side)
        local orphan1 = CountDescendants(content)
        ToonAge.Layout:ReleasePane(content)
        local before2 = createdFrames
        Now:Render(content, side)
        local added2 = createdFrames - before2
        local orphan2 = CountDescendants(content)

        return {
            count = #items,
            p1 = prios[1], p2 = prios[2], p3 = prios[3], p4 = prios[4],
            c1 = cats[1], c2 = cats[2], c3 = cats[3], c4 = cats[4],
            allHaveActions = allHaveActions,
            orphan1 = orphan1,
            added2 = added2,
            orphan2 = orphan2,
        }
    """)
    check("ForeverNow produces 4 fact->action briefing cards", res.count, 4)
    check("ForeverNow sorts urgent (priority 1) items first", res.p1 == 1 and res.p2 == 1 and res.p3 == 2 and res.p4 == 3, True)
    check("ForeverNow every card ends in a next-step action tab", res.allHaveActions, True)
    check("ForeverNow pass 1 has 0 orphaned descendants", res.orphan1, 0)
    check("ForeverNow pass 2 allocates 0 new frames and has 0 orphans", (res.added2, res.orphan2), (0, 0))

    # 6. Settings drawer APPEARANCE section live cycling
    res = lua.execute(r"""
        ToonAge:ApplyTheme("modern_azeroth", "class", false)
        local S = ToonAge:GetModule("Settings")
        local content = CreateFrame("Frame")
        content:SetSize(230, 1)
        local sidebar = CreateFrame("Frame")
        sidebar:SetSize(148, 1)
        S:Render(content, sidebar)

        local foundAppearance = false
        local packRow = nil
        for _, r in ipairs(content._regions) do
            if r._kind == "FontString" and r._text == "APPEARANCE" then
                foundAppearance = true
            end
        end
        for _, ch in ipairs(content._children) do
            for _, r in ipairs(ch._regions) do
                if r._kind == "FontString" and r._text == "Accent theme pack" then
                    packRow = ch
                end
            end
        end
        local beforePack = ToonAge.Theme.active.pack
        if packRow and packRow._scripts.OnClick then
            packRow._scripts.OnClick(packRow)
        end
        local afterPack = ToonAge.Theme.active.pack
        return {
            foundAppearance = foundAppearance,
            hasPackRow = packRow ~= nil,
            beforePack = beforePack,
            afterPack = afterPack,
        }
    """)
    check("Settings drawer renders APPEARANCE section", res.foundAppearance, True)
    check("Settings APPEARANCE has Accent theme pack row", res.hasPackRow, True)
    check("Clicking Accent theme pack cycles class -> toonage_gold live", (res.beforePack, res.afterPack), ("class", "toonage_gold"))

    # 7. Reputation tab visual upgrade: standing colors, badges, in-tier text, group headers, 0-churn
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Progression/FactionTracker.lua"))
    res = lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        C_Reputation = {
            GetNumFactions = function() return 4 end,
            GetFactionDataByIndex = function(i)
                local rows = {
                    { name = "Horde", isHeader = true, isCollapsed = false, factionID = 67 },
                    { name = "Darkspear Trolls", factionID = 530, reaction = 4, isHeader = false,
                      currentReactionThreshold = 0, nextReactionThreshold = 3000, currentStanding = 2943 },
                    { name = "Orgrimmar", factionID = 76, reaction = 5, isHeader = false,
                      currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 3963 },
                    { name = "Undercity", factionID = 68, reaction = 6, isHeader = false,
                      currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 11108 },
                }
                return rows[i]
            end,
        }
        local content = CreateFrame("Frame")
        content:SetSize(640, 1)
        content._laPane = true
        local side = CreateFrame("Frame")
        side:SetSize(184, 1)

        FT:Render(content, side)
        local orphan1 = CountDescendants(content)
        local sideH = side:GetHeight()
        local bars = {}
        for _, ch in ipairs(content._children) do
            if ch._laKind == "StatBar" then
                bars[ch.label:GetText()] = {
                    badge = ch.badge and ch.badge:GetText() or "",
                    barText = ch.barText and ch.barText:GetText() or "",
                    text = ch.text and ch.text:GetText() or "",
                    fillColor = ch.fill and ch.fill._colorTex,
                }
            end
        end
        local sawHordeHeader = false
        local sawClosest = false
        for _, r in ipairs(content._regions) do
            if r._kind == "FontString" then
                if r._text == "Horde" then sawHordeHeader = true end
                if string.find(r._text or "", "Closest: Darkspear Trolls %(57 to Friendly%)", 1) then
                    sawClosest = true
                end
            end
        end

        ToonAge.Layout:ReleasePane(content)
        local before2 = createdFrames
        FT:Render(content, side)
        local added2 = createdFrames - before2
        local orphan2 = CountDescendants(content)

        return {
            sideH = sideH,
            orphan1 = orphan1,
            added2 = added2,
            orphan2 = orphan2,
            sawHordeHeader = sawHordeHeader,
            sawClosest = sawClosest,
            orgBadge = bars["Orgrimmar"] and bars["Orgrimmar"].badge,
            orgBarText = bars["Orgrimmar"] and bars["Orgrimmar"].barText,
            orgText = bars["Orgrimmar"] and bars["Orgrimmar"].text,
            orgFill = bars["Orgrimmar"] and bars["Orgrimmar"].fillColor,
            ucBadge = bars["Undercity"] and bars["Undercity"].badge,
            ucText = bars["Undercity"] and bars["Undercity"].text,
        }
    """)
    check("Reputation renders persistent 3D character sidebar", res.sideH > 100, True)
    check("Reputation emits client group header (Horde)", res.sawHordeHeader, True)
    check("Reputation subtitle names closest next standing (57 to Friendly)", res.sawClosest, True)
    check("Orgrimmar shows Friendly badge, 16% bar text, and in-tier 963 / 6,000",
          (res.orgBadge, res.orgBarText, res.orgText), ("Friendly", "16%", "963 / 6,000"))
    check("Orgrimmar Friendly bar uses emerald green fill (g > r and g > b)",
          res.orgFill[2] > res.orgFill[1] and res.orgFill[2] > res.orgFill[3], True)
    check("Undercity shows Honored badge and in-tier 2,108 / 12,000",
          (res.ucBadge, res.ucText), ("Honored", "2,108 / 12,000"))
    check("Reputation pass 1 & pass 2 have 0 orphans and 0 new frames on pass 2",
          (res.orphan1, res.added2, res.orphan2), (0, 0, 0))

    passed = sum(1 for r in _results if r)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
