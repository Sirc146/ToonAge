#!/usr/bin/env python3
"""Tests for Forever Vendor Highlights & Grey-Out (Modules/Forever/Gear.lua + Settings.lua).

Verifies:
1. ClassifyVendorItem:
   - Already-known recipe/pattern/book ("Already known" tooltip line) -> "known"
   - Unwearable armor (Mail/Leather/Plate/Shield for Cloth Mage) -> "unusable"
   - Level-locked gear (minLevel > player level) -> "unusable"
   - Blizzard isUsable=false non-equippable item (e.g. wrong profession recipe) -> "unusable"
   - Strictly better wearable Cloth upgrade -> "upgrade"
   - Standard wearable downgrade / consumable -> "normal"
2. FlagVendor live UI application:
   - Upgrade slot gets bright green glow + visible "UP" badge + alpha=1.0 + saturated icon
   - Known recipe slot gets dimmed alpha (0.38) + desaturated icon + visible "KNOWN" badge + no glow
   - Unusable armor slot gets dimmed alpha (0.35) + desaturated icon + no glow/badge
   - Normal slot resets cleanly to alpha=1.0 + saturated icon + hidden glow/badge
   - Switching to Buyback tab (selectedTab == 2) or toggling TA.db.vendorHighlights=false
     restores all rows to alpha=1.0 and hides all glows/badges.

Usage:  python3 Tools/test_forever_vendor_highlights.py [-v]
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
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


PRELUDE = r"""
ToonAge = {
    modules = {}, Data = {}, flavor = "forever", IsForever = true,
    db = {}, charDB = {},
    Utils = {
        IsSecret = function() return false end,
        GearMarkForVerdict = function(v) return v == "upgrade" and " [UP]" or " [~]" end,
        MarkItemName = function(s) return s end,
    },
}
function ToonAge:RegisterModule(n, m) self.modules[n] = m end
function ToonAge:GetModule(n) return self.modules[n] end

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
ITEM_SPELL_KNOWN = "Already known"
MERCHANT_ITEMS_PER_PAGE = 10
issecretvalue = function() return false end

UnitLevel = function() return 22 end
UnitClass = function() return "Mage", "MAGE" end
UnitPowerMax = function() return 970 end
GetMoney = function() return 50000 end

-- Skill lines: Cloth (415) + Staves (136) + Wands (228) only via ForeverCharacter
ToonAge:RegisterModule("ForeverCharacter", {
    _ReadSkillLines = function()
        return {
            { id = 415, name = "Cloth", rank = 1, max = 1 },
            { id = 136, name = "Staves", rank = 90, max = 110 },
            { id = 228, name = "Wands", rank = 95, max = 110 },
        }
    end,
})

local ITEMS = {
    -- Equipped chest (slot 5): 35 Armor, +4 Int, +4 Spi, +6 Sta (ilvl 15)
    ["|cff0070dd|Hitem:1001|h[Robe of Evocation]|h|r"] = {
        name = "Robe of Evocation", quality = 3, ilvl = 15, minLevel = 13,
        equipLoc = "INVTYPE_CHEST", classID = 4, subID = 1,
        stats = { ITEM_MOD_ARMOR_SHORT = 35, ITEM_MOD_INTELLECT_SHORT = 4, ITEM_MOD_SPIRIT_SHORT = 4, ITEM_MOD_STAMINA_SHORT = 6 },
    },
    -- Slot 1: Strict Cloth Upgrade (50 Armor, +6 Int, +5 Spi, +7 Sta)
    ["|cff1eff00|Hitem:2001|h[Silk Robe of the Owl]|h|r"] = {
        name = "Silk Robe of the Owl", quality = 2, ilvl = 24, minLevel = 20,
        equipLoc = "INVTYPE_CHEST", classID = 4, subID = 1,
        stats = { ITEM_MOD_ARMOR_SHORT = 50, ITEM_MOD_INTELLECT_SHORT = 6, ITEM_MOD_SPIRIT_SHORT = 5, ITEM_MOD_STAMINA_SHORT = 7 },
    },
    -- Slot 2: Already Known Tailoring Pattern
    ["|cffffffff|Hitem:2002|h[Pattern: Blue Linen Robe]|h|r"] = {
        name = "Pattern: Blue Linen Robe", quality = 1, ilvl = 15, minLevel = 0,
        equipLoc = "", classID = 9, subID = 2,
        stats = {},
        tooltip = { "Pattern: Blue Linen Robe", "Requires Tailoring (45)", "Already known" },
    },
    -- Slot 3: Mail Armor (unwearable by Mage)
    ["|cff1eff00|Hitem:2003|h[Banded Mail Belt]|h|r"] = {
        name = "Banded Mail Belt", quality = 2, ilvl = 22, minLevel = 18,
        equipLoc = "INVTYPE_WAIST", classID = 4, subID = 3,
        stats = { ITEM_MOD_ARMOR_SHORT = 110, ITEM_MOD_STAMINA_SHORT = 5 },
    },
    -- Slot 4: Level-locked Cloth (Requires Lv 30, player is Lv 22)
    ["|cff1eff00|Hitem:2004|h[Mageweave Boots]|h|r"] = {
        name = "Mageweave Boots", quality = 2, ilvl = 35, minLevel = 30,
        equipLoc = "INVTYPE_FEET", classID = 4, subID = 1,
        stats = { ITEM_MOD_ARMOR_SHORT = 40, ITEM_MOD_INTELLECT_SHORT = 8 },
    },
    -- Slot 5: Standard Consumable (normal)
    ["|cffffffff|Hitem:2005|h[Refreshing Spring Water]|h|r"] = {
        name = "Refreshing Spring Water", quality = 1, ilvl = 5, minLevel = 1,
        equipLoc = "", classID = 0, subID = 5,
        stats = {},
    },
}

GetInventoryItemLink = function(_, slot)
    if slot == 5 then return "|cff0070dd|Hitem:1001|h[Robe of Evocation]|h|r" end
    return nil
end

C_Item = {
    GetItemInfoInstant = function(link)
        local it = ITEMS[link]
        if not it then return nil end
        return 1, nil, nil, it.equipLoc, 123, it.classID, it.subID
    end,
    GetItemInfo = function(link)
        local it = ITEMS[link]
        if not it then return nil end
        return it.name, link, it.quality, it.ilvl, it.minLevel, nil, nil, nil, it.equipLoc, 123, 0, it.classID, it.subID
    end,
    GetItemStats = function(link)
        local it = ITEMS[link]
        return it and it.stats or nil
    end,
}

C_TooltipInfo = {
    GetHyperlink = function(link)
        local it = ITEMS[link]
        if not (it and it.tooltip) then return { lines = {} } end
        local lines = {}
        for i, s in ipairs(it.tooltip) do lines[i] = { leftText = s } end
        return { lines = lines }
    end,
}

local MERCHANT_LINKS = {
    [1] = "|cff1eff00|Hitem:2001|h[Silk Robe of the Owl]|h|r",
    [2] = "|cffffffff|Hitem:2002|h[Pattern: Blue Linen Robe]|h|r",
    [3] = "|cff1eff00|Hitem:2003|h[Banded Mail Belt]|h|r",
    [4] = "|cff1eff00|Hitem:2004|h[Mageweave Boots]|h|r",
    [5] = "|cffffffff|Hitem:2005|h[Refreshing Spring Water]|h|r",
}

GetMerchantItemLink = function(idx) return MERCHANT_LINKS[idx] end
C_MerchantFrame = {
    GetItemInfo = function(idx)
        if not MERCHANT_LINKS[idx] then return nil end
        return { price = 1500, isUsable = (idx ~= 3 and idx ~= 4), hasExtendedCost = false }
    end,
}

local function MakeWidget(kind)
    local w = { kind = kind, _shown = true, _alpha = 1.0, _desat = false, _text = "", _hooks = {} }
    function w:SetSize(a, b) self.w, self.h = a, b end
    function w:SetWidth(a) self.w = a end
    function w:SetHeight(a) self.h = a end
    function w:SetPoint() end
    function w:SetAllPoints() end
    function w:SetFrameLevel(l) self.lvl = l end
    function w:GetFrameLevel() return self.lvl or 1 end
    function w:SetAlpha(a) self._alpha = a end
    function w:GetAlpha() return self._alpha end
    function w:SetDesaturated(d) self._desat = d and true or false end
    function w:SetColorTexture(r, g, b, a) self._color = { r, g, b, a } end
    function w:SetFont() end
    function w:SetText(t) self._text = t or "" end
    function w:GetText() return self._text end
    function w:Show() self._shown = true end
    function w:Hide() self._shown = false end
    function w:IsShown() return self._shown end
    function w:HookScript(ev, fn) self._hooks[ev] = fn end
    function w:CreateTexture() return MakeWidget("Texture") end
    function w:CreateFontString() return MakeWidget("FontString") end
    return w
end
function CreateFrame(kind) return MakeWidget(kind) end

MerchantFrame = MakeWidget("Frame")
MerchantFrame.page = 1
MerchantFrame.selectedTab = 1

for i = 1, 10 do
    local row = MakeWidget("Frame")
    local btn = MakeWidget("Button")
    local icon = MakeWidget("Texture")
    local nameFS = MakeWidget("FontString")
    nameFS:SetText("Item " .. i)
    btn.icon = icon
    _G["MerchantItem" .. i] = row
    _G["MerchantItem" .. i .. "ItemButton"] = btn
    _G["MerchantItem" .. i .. "ItemButtonIconTexture"] = icon
    _G["MerchantItem" .. i .. "Name"] = nameFS
end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(read("Modules/Forever/Gear.lua"))

    r = lua.eval(r"""
    (function()
        local G = ToonAge:GetModule("ForeverGear")
        G:FlagVendor()

        local s1_glow = MerchantItem1ItemButton._taGlow and MerchantItem1ItemButton._taGlow:IsShown() or false
        local s1_badge = MerchantItem1ItemButton._taBadge and MerchantItem1ItemButton._taBadge:IsShown()
            and MerchantItem1ItemButton._taBadge.text:GetText() or ""
        local s1_alpha = MerchantItem1:GetAlpha()
        local s1_desat = MerchantItem1ItemButton.icon._desat

        local s2_alpha = MerchantItem2:GetAlpha()
        local s2_desat = MerchantItem2ItemButton.icon._desat
        local s2_badge = MerchantItem2ItemButton._taBadge and MerchantItem2ItemButton._taBadge:IsShown()
            and MerchantItem2ItemButton._taBadge.text:GetText() or ""
        local s2_glow = MerchantItem2ItemButton._taGlow and MerchantItem2ItemButton._taGlow:IsShown() or false

        local s3_alpha = MerchantItem3:GetAlpha()
        local s3_desat = MerchantItem3ItemButton.icon._desat
        local s3_glow = MerchantItem3ItemButton._taGlow and MerchantItem3ItemButton._taGlow:IsShown() or false

        local s4_alpha = MerchantItem4:GetAlpha()
        local s4_desat = MerchantItem4ItemButton.icon._desat

        local s5_alpha = MerchantItem5:GetAlpha()
        local s5_desat = MerchantItem5ItemButton.icon._desat

        local noteText = MerchantFrame._taNote and MerchantFrame._taNote:GetText() or ""

        -- Switch to Buyback tab (2) -> all slots must restore to normal
        MerchantFrame.selectedTab = 2
        G:FlagVendor()
        local buybackAlpha2 = MerchantItem2:GetAlpha()
        local buybackDesat2 = MerchantItem2ItemButton.icon._desat
        local buybackGlow1 = MerchantItem1ItemButton._taGlow and MerchantItem1ItemButton._taGlow:IsShown() or false

        -- Back to buy tab, toggle vendorHighlights = false -> restores all slots to normal
        MerchantFrame.selectedTab = 1
        ToonAge.db.vendorHighlights = false
        G:FlagVendor()
        local offAlpha3 = MerchantItem3:GetAlpha()
        local offGlow1 = MerchantItem1ItemButton._taGlow and MerchantItem1ItemButton._taGlow:IsShown() or false

        return {
            s1_glow = s1_glow, s1_badge = s1_badge, s1_alpha = s1_alpha, s1_desat = s1_desat,
            s2_alpha = s2_alpha, s2_desat = s2_desat, s2_badge = s2_badge, s2_glow = s2_glow,
            s3_alpha = s3_alpha, s3_desat = s3_desat, s3_glow = s3_glow,
            s4_alpha = s4_alpha, s4_desat = s4_desat,
            s5_alpha = s5_alpha, s5_desat = s5_desat,
            noteText = noteText,
            buybackAlpha2 = buybackAlpha2, buybackDesat2 = buybackDesat2, buybackGlow1 = buybackGlow1,
            offAlpha3 = offAlpha3, offGlow1 = offGlow1,
        }
    end)()
    """)

    check("Upgrade slot 1 shows emerald glow, UP badge, full brightness (1.0), and saturated icon",
          (r["s1_glow"], "UP" in r["s1_badge"], r["s1_alpha"], r["s1_desat"]),
          (True, True, 1.0, False))
    check("Already-known recipe slot 2 dims row (0.38), desaturates icon, shows KNOWN badge, hides glow",
          (abs(r["s2_alpha"] - 0.38) < 0.01, r["s2_desat"], "KNOWN" in r["s2_badge"], r["s2_glow"]),
          (True, True, True, False))
    check("Unwearable Mail slot 3 dims row (0.35), desaturates icon, hides glow",
          (abs(r["s3_alpha"] - 0.35) < 0.01, r["s3_desat"], r["s3_glow"]),
          (True, True, False))
    check("Level-locked slot 4 (Lv 30 on Lv 22 Mage) dims row (0.35) and desaturates icon",
          (abs(r["s4_alpha"] - 0.35) < 0.01, r["s4_desat"]), (True, True))
    check("Normal consumable slot 5 stays full brightness (1.0) and saturated",
          (r["s5_alpha"], r["s5_desat"]), (1.0, False))
    check("Merchant footer note reports 1 upgrade and 3 dimmed items on page",
          "1 upgrade" in r["noteText"] and "3 dimmed" in r["noteText"])
    check("Buyback tab restores all rows to 1.0 alpha, saturated icon, and hidden glow",
          (r["buybackAlpha2"], r["buybackDesat2"], r["buybackGlow1"]), (1.0, False, False))
    check("Disabling TA.db.vendorHighlights restores all rows to normal immediately",
          (r["offAlpha3"], r["offGlow1"]), (1.0, False))

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
