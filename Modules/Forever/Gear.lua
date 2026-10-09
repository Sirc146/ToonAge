-- ToonAge/Modules/Forever/Gear.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS (AND ISN'T) ──────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of what you are wearing, nothing more. It lists every equipped
-- slot with the item's name (in its quality colour) and item level, then a
-- combined tally of the stats those items carry, read straight from the client.
--
-- It does NOT score gear, rank upgrades, or say "equip this". Vanilla stat
-- weights for this game have not been verified, and a scorer built on guessed
-- weights hands out confidently wrong advice — the same reason the Character
-- tab stays a readout. When real Data/Forever weights exist, an advisory layer
-- can sit on top of this; until then it reports facts.
--
-- APIs: C_Item.GetItemInfo / C_Item.GetItemStats (confirmed present in
-- Data/Forever/ApiManifest.lua) with the old globals as a fallback, and
-- GetInventoryItemLink for the equipped slots. Every call goes through Try(),
-- so a slot the client cannot answer is skipped rather than shown as a zero.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverGear", M)

-- ─── READS ─────────────────────────────────────────────────────────────────

--- Call an API that may not exist on this client. nil means "no answer".
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Num(v)
    if v == nil then return nil end
    return tonumber(tostring(v))
end

-- Equipped inventory slots that hold gear, in the order the character sheet
-- reads top-to-bottom. Slot 4 (shirt) and 19 (tabard) are cosmetic and left
-- out; ranged/relic (18) is kept because hunters and casters use it.
local SLOTS = {
    { id = 1,  name = "Head"      },
    { id = 2,  name = "Neck"      },
    { id = 3,  name = "Shoulder"  },
    { id = 15, name = "Back"      },
    { id = 5,  name = "Chest"     },
    { id = 9,  name = "Wrist"     },
    { id = 10, name = "Hands"     },
    { id = 6,  name = "Waist"     },
    { id = 7,  name = "Legs"      },
    { id = 8,  name = "Feet"      },
    { id = 11, name = "Ring 1"    },
    { id = 12, name = "Ring 2"    },
    { id = 13, name = "Trinket 1" },
    { id = 14, name = "Trinket 2" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand"  },
    { id = 18, name = "Ranged"    },
}

-- Item quality colours (Vanilla 0-5: poor/common/uncommon/rare/epic/legendary).
local QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
    [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}

--- name, itemLevel, quality, link for an item link/id, via C_Item then globals.
local function ItemInfo(link)
    if not link then return nil end
    -- C_Item.GetItemInfo is the modern form Forever exposes; the global is the
    -- fallback for any client that still answers it.
    local name, _, quality, ilvl
    if C_Item and C_Item.GetItemInfo then
        local r = { Try(C_Item.GetItemInfo, link) }
        name, quality, ilvl = r[1], r[3], r[4]
    end
    if not name then
        local r = { Try(GetItemInfo, link) }
        name, quality, ilvl = r[1], r[3], r[4]
    end
    return name, Num(ilvl), Num(quality)
end

--- Item stat table for a link, via C_Item.GetItemStats then the global.
local function ItemStats(link)
    if not link then return nil end
    if C_Item and C_Item.GetItemStats then
        local t = Try(C_Item.GetItemStats, link)
        if type(t) == "table" then return t end
    end
    local t = Try(GetItemStats, link)
    if type(t) == "table" then return t end
    return nil
end

-- Human labels for the stat keys C_Item.GetItemStats returns. Only the ones
-- that exist in Vanilla are listed; anything the client returns that isn't here
-- is shown under its raw key rather than hidden, so nothing is silently lost.
local STAT_LABELS = {
    ITEM_MOD_STRENGTH_SHORT          = "Strength",
    ITEM_MOD_AGILITY_SHORT           = "Agility",
    ITEM_MOD_STAMINA_SHORT           = "Stamina",
    ITEM_MOD_INTELLECT_SHORT         = "Intellect",
    ITEM_MOD_SPIRIT_SHORT            = "Spirit",
    ITEM_MOD_ATTACK_POWER_SHORT      = "Attack Power",
    ITEM_MOD_CRIT_RATING_SHORT       = "Critical Strike",
    ITEM_MOD_HIT_RATING_SHORT        = "Hit",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense",
    ITEM_MOD_DODGE_RATING_SHORT      = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT      = "Parry",
    ITEM_MOD_BLOCK_RATING_SHORT      = "Block",
    ITEM_MOD_BLOCK_VALUE_SHORT       = "Block Value",
    ITEM_MOD_SPELL_POWER_SHORT       = "Spell Power",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT= "Healing Power",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mana per 5s",
    ITEM_MOD_POWER_REGEN0_SHORT      = "Mana per 5s",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "Weapon DPS",
    ITEM_MOD_MANA_SHORT              = "Mana",
    ITEM_MOD_HEALTH_SHORT            = "Health",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Damage",
    RESISTANCE1_NAME                 = "Holy Resistance",
    RESISTANCE2_NAME                 = "Fire Resistance",
    RESISTANCE3_NAME                 = "Nature Resistance",
    RESISTANCE4_NAME                 = "Frost Resistance",
    RESISTANCE5_NAME                 = "Shadow Resistance",
    RESISTANCE6_NAME                 = "Arcane Resistance",
    ITEM_MOD_HEALTH_REGENERATION_SHORT = "Health per 5s",
    RESISTANCE0_NAME                 = "Armor",
    ITEM_MOD_FIRE_RESISTANCE_SHORT   = "Fire Resistance",
    ITEM_MOD_FROST_RESISTANCE_SHORT  = "Frost Resistance",
    ITEM_MOD_NATURE_RESISTANCE_SHORT = "Nature Resistance",
    ITEM_MOD_SHADOW_RESISTANCE_SHORT = "Shadow Resistance",
    ITEM_MOD_ARCANE_RESISTANCE_SHORT = "Arcane Resistance",
    -- School damage (measured in harvested items 2026-09-30: FIRE_ and
    -- HOLY_DAMAGE_DONE_SHORT showed up raw on the Gear tab).
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT   = "Fire Damage",
    ITEM_MOD_FROST_DAMAGE_DONE_SHORT  = "Frost Damage",
    ITEM_MOD_NATURE_DAMAGE_DONE_SHORT = "Nature Damage",
    ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = "Shadow Damage",
    ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT = "Arcane Damage",
    ITEM_MOD_HOLY_DAMAGE_DONE_SHORT   = "Holy Damage",
}

--- A readable name for any stat key: the table above, then the client's own
--- localized global of the same name, then the key tidied ("ITEM_MOD_X_Y_SHORT"
--- -> "X Y"). A raw ITEM_MOD_ constant never reaches the screen.
local function StatLabel(key)
    if STAT_LABELS[key] then return STAT_LABELS[key] end
    local g = _G[key]
    if type(g) == "string" and g ~= "" and not g:find("%%") then return g end
    local t = tostring(key):gsub("^ITEM_MOD_", ""):gsub("_SHORT$", ""):gsub("_NAME$", "")
    t = t:gsub("_DONE$", ""):gsub("_", " "):lower():gsub("(%a)(%w*)", function(a, b) return a:upper() .. b end)
    return t
end

-- Weapon DPS: labelled like any other stat, but deliberately kept OUT of the
-- combined totals -- see ScanEquipped.
local DPS_KEY = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"

-- Order the aggregated stats read sensibly: primaries, then offense, then
-- defense/resist. Keys not listed here fall to the end, alphabetically.
local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT",
    "RESISTANCE0_NAME", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT",
    "ITEM_MOD_FIRE_RESISTANCE_SHORT", "ITEM_MOD_FROST_RESISTANCE_SHORT",
    "ITEM_MOD_NATURE_RESISTANCE_SHORT", "ITEM_MOD_SHADOW_RESISTANCE_SHORT",
    "ITEM_MOD_ARCANE_RESISTANCE_SHORT",
}

-- ─── GEAR CHECK ──────────────────────────────────────────────────────────
--
-- Facts that point at an action, with no stat weights involved:
--   * WEAPONS: the weapon type in each hand, your skill with it against the
--     cap (C_SkillInfo, measured on Forever 2026-09-29), and whether your
--     race's weapon specialization is active. The racials come from
--     Data/Forever/Racials.lua, read verbatim from this client -- e.g. Human
--     "Sword Specialization: +2% crit while you have a sword or two-handed
--     sword equipped", Dwarf maces +1%, Orc axes +1%.
--   * OLDEST PIECES: equipped items ordered by item level, lowest first.
--   * IN YOUR BAGS: items you can equip right now (level, armour type and
--     weapon skill checked) with a higher item level than what is in that
--     slot, with the exact stat difference. Item level is a fact the client
--     reports; whether the trade is worth it is still yours to judge, which is
--     why the difference is spelled out stat by stat instead of scored.

local WEAPON_CLASS, ARMOR_CLASS = 2, 4

-- Weapon subclass -> skill line (the game's own pairing, unchanged since
-- Vanilla). Mirrors Modules/Forever/Character.lua.
local WEAPON_SKILL = {
    [0] = 44, [1] = 172, [2] = 45, [3] = 46, [4] = 54, [5] = 160, [6] = 229,
    [7] = 43, [8] = 55, [10] = 136, [13] = 473, [15] = 173, [16] = 176,
    [18] = 226, [19] = 228,
}
-- Armour subclass -> proficiency skill line (cloth/leather/mail/plate/shield).
local ARMOR_SKILL = { [1] = 415, [2] = 414, [3] = 413, [4] = 293, [6] = 433 }

-- Words in a racial's tooltip -> the weapon subclasses they name.
local SPEC_WORDS = {
    { "two%-handed sword", { 8 } }, { "sword", { 7, 8 } },
    { "two%-handed mace", { 5 } },  { "mace", { 4, 5 } },
    { "two%-handed ax", { 1 } },    { "ax", { 0, 1 } },
    { "dagger", { 15 } }, { "fist", { 13 } }, { "polearm", { 6 } },
    { "stave", { 10 } }, { "staff", { 10 } }, { "crossbow", { 18 } },
    { "bow", { 2 } }, { "gun", { 3 } }, { "thrown", { 16 } }, { "wand", { 19 } },
}

-- equipLoc -> the inventory slot(s) it goes in.
local EQUIP_SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
local SLOT_NAME = {}
for _, sl in ipairs(SLOTS) do SLOT_NAME[sl.id] = sl.name end

--- Everything the gear check needs about one item.
local function FullInfo(link)
    if not link then return nil end
    local r
    if C_Item and C_Item.GetItemInfo then r = { Try(C_Item.GetItemInfo, link) } end
    if not (r and r[1]) then r = { Try(GetItemInfo, link) } end
    if not r[1] then return nil end
    return {
        name = r[1], quality = Num(r[3]), ilvl = Num(r[4]), minLevel = Num(r[5]),
        equipLoc = r[9], classID = Num(r[12]), subclassID = Num(r[13]),
    }
end

--- skillID -> { rank, max } for every skill line, via the Character module.
local function SkillMap()
    local FC = TA:GetModule("ForeverCharacter")
    local out = {}
    if FC and FC._ReadSkillLines then
        for _, l in ipairs(FC._ReadSkillLines()) do
            if l.id then out[l.id] = { name = l.name, rank = l.rank, max = l.max } end
        end
    end
    return out
end

--- Your race's weapon specializations: { name, crit, subclasses = set }.
local function WeaponSpecs()
    local data = TA.Data and TA.Data.ForeverRacials
    local _, race = Try(UnitRace, "player")
    local faction = Try(UnitFactionGroup, "player")
    local list = data and race and faction and data[race] and data[race][faction]
    local out = {}
    for _, r in ipairs(list or {}) do
        local tip = (r.tooltip or ""):lower()
        if tip:find("equipped", 1, true) and tip:find("critical strike", 1, true) then
            local set, any = {}, false
            local rest = tip:match("while you have (.-) equipped") or tip
            for _, w in ipairs(SPEC_WORDS) do
                if rest:find(w[1]) then
                    for _, sc in ipairs(w[2]) do set[sc] = true; any = true end
                end
            end
            if any then
                out[#out + 1] = { name = r.name, crit = tonumber(tip:match("by (%d+)%%")),
                                  subclasses = set }
            end
        end
    end
    return out
end
M._WeaponSpecs = WeaponSpecs

--- Highest armour subclass you have the skill for (4 plate .. 1 cloth), or nil
--- when no armour skill line could be read (then nothing is filtered).
local function BestArmor(skills)
    for sub = 4, 1, -1 do
        if skills[ARMOR_SKILL[sub]] then return sub end
    end
    return nil
end

--- Can you equip this item now? @return ok, reason
local function CanEquip(info, level, skills)
    if not (info and info.equipLoc and EQUIP_SLOTS[info.equipLoc]) then return false, "not equippable" end
    if info.minLevel and level and info.minLevel > level then
        return false, "requires level " .. info.minLevel
    end
    if info.classID == WEAPON_CLASS then
        local sk = WEAPON_SKILL[info.subclassID or -1]
        if sk and not skills[sk] then return false, "untrained weapon type" end
    elseif info.classID == ARMOR_CLASS then
        local sk = ARMOR_SKILL[info.subclassID or -1]
        if sk and not skills[sk] then return false, "armour type you cannot wear" end
        -- Your best armour type only (2026-10-03): a plate wearer is offered
        -- plate, not every lighter type it can technically wear. "Best" comes
        -- from your skill lines, so a Warrior gets mail until Plate Mail is
        -- trained (Vanilla: level 40) and plate after. Cloaks are cloth for
        -- everyone; rings, necks, trinkets (subclass 0) and shields (6) are
        -- outside the cloth-to-plate ladder.
        local sub = info.subclassID
        if sub and sub >= 1 and sub <= 4 and info.equipLoc ~= "INVTYPE_CLOAK" then
            local best = BestArmor(skills)
            if best and sub < best then return false, "lighter than your best armour type" end
        end
    end
    return true
end

--- "+3 Intellect  -2 Stamina" between two stat tables. nil if identical.
--- Per-stat differences between two stat tables, weapon DPS included.
--- (Until 2026-10-03 DPS was left out, so a Skinning Knife read "same stats"
--- against an empty slot and nothing showed it was 1.5 DPS worse.)
--- @return list { key, d }  sorted gains first; nil when identical
local function StatDeltas(newStats, oldStats)
    local keys, diff = {}, {}
    for k in pairs(newStats or {}) do keys[k] = true end
    for k in pairs(oldStats or {}) do keys[k] = true end
    for k in pairs(keys) do
        local d = (Num((newStats or {})[k]) or 0) - (Num((oldStats or {})[k]) or 0)
        if math.abs(d) > 0.05 then diff[#diff + 1] = { key = k, d = d } end
    end
    if #diff == 0 then return nil end
    table.sort(diff, function(a, b) return a.d > b.d end)
    return diff
end

local function FormatDeltas(diff, ignore)
    if not diff then return nil end
    local parts = {}
    for _, x in ipairs(diff) do
        local fmt = (x.key == DPS_KEY) and "%+.1f %s" or "%+d %s"
        local txt = string.format(fmt, x.d, StatLabel(x.key))
        if ignore and ignore[x.key] then txt = txt .. " (no use without mana)" end
        parts[#parts + 1] = txt
    end
    return table.concat(parts, "  ")
end

local function StatDiff(newStats, oldStats)
    return FormatDeltas(StatDeltas(newStats, oldStats))
end

--- Can this character put a weapon in the off hand? CanDualWield() where the
--- client has it, else the Dual Wield spell (674) via IsPlayerSpell /
--- C_SpellBook.IsSpellKnown. Unknown counts as NO: a false "upgrade" is worse
--- than a missed one. (2026-10-03: a level-8 Warrior was offered a Skinning
--- Knife for the off hand -- Warriors learn Dual Wield at 20.)
local DUAL_WIELD_SPELL = 674
local function CanDualWield()
    local v = Try(_G.CanDualWield)
    if v ~= nil and not (issecretvalue and issecretvalue(v)) then return v == true end
    local known = Try(_G.IsPlayerSpell, DUAL_WIELD_SPELL)
    if known == nil and C_SpellBook and C_SpellBook.IsSpellKnown then
        known = Try(C_SpellBook.IsSpellKnown, DUAL_WIELD_SPELL)
    end
    return known == true
end
M._CanDualWield = CanDualWield

--- The slots an item can really go in for this character right now.
---   * Off hand is closed while a two-hander is equipped: anything there
---     would cost you the two-hander, so it is never an "upgrade over empty".
---   * A weapon (one-hand or off-hand weapon) only goes in the off hand with
---     Dual Wield. Shields and held-in-off-hand items are not weapons.
---   * A one-hander is never offered over an equipped two-hander.
local function SlotsFor(equipLoc, equipped, dualWield)
    local mh = equipped[16] and equipped[16].info
    local twoHanded = mh and mh.equipLoc == "INVTYPE_2HWEAPON"
    local out = {}
    for _, slot in ipairs(EQUIP_SLOTS[equipLoc] or {}) do
        local ok = true
        -- A one-hander is not a like-for-like upgrade over a two-hander: item
        -- level alone can't weigh a dagger against a greatsword.
        if slot == 16 and twoHanded and equipLoc ~= "INVTYPE_2HWEAPON" then ok = false end
        if slot == 17 then
            if twoHanded then ok = false end
            if (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND") and not dualWield then
                ok = false
            end
        end
        if ok then out[#out + 1] = slot end
    end
    return out
end
M._SlotsFor = SlotsFor

--- Mana-only stats, ignored when this character has no mana pool. Measured,
--- not assumed: UnitPowerMax(player, 0) is a plain number out of combat on
--- Forever (651 on a level-14 Mage, 2026-09-26); 0 means no mana.
local MANA_ONLY = {
    ITEM_MOD_INTELLECT_SHORT = true, ITEM_MOD_MANA_SHORT = true,
    ITEM_MOD_MANA_REGENERATION_SHORT = true, ITEM_MOD_POWER_REGEN0_SHORT = true,
    ITEM_MOD_SPELL_POWER_SHORT = true, ITEM_MOD_SPELL_HEALING_DONE_SHORT = true,
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true,
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = true, ITEM_MOD_FROST_DAMAGE_DONE_SHORT = true,
    ITEM_MOD_NATURE_DAMAGE_DONE_SHORT = true, ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = true,
    ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT = true, ITEM_MOD_HOLY_DAMAGE_DONE_SHORT = true,
}
local function ManaIgnore()
    local maxMana = Try(UnitPowerMax, "player", 0)
    if maxMana == nil or (issecretvalue and issecretvalue(maxMana)) then return nil end
    return (tonumber(maxMana) or 0) == 0 and MANA_ONLY or nil
end

--- Verdict for putting `newStats` in place of `curStats`. No weights: an item
--- is "better" only if it is at least as good on EVERY number the client
--- reports (weapon DPS and armor included) and higher on one; "trade" when it
--- gains some and loses others -- shown with the full difference so you
--- decide; nil when it is worse or the same everywhere. A weapon that loses
--- DPS is never offered: for a weapon slot that number is the point.
local function Judge(newStats, curStats, info, ignore)
    local diff = StatDeltas(newStats, curStats)
    if not diff then return nil end
    local gains, losses = 0, 0
    for _, x in ipairs(diff) do
        if not (ignore and ignore[x.key]) then
            if x.d > 0 then gains = gains + 1 else losses = losses + 1 end
        end
        if x.key == DPS_KEY and x.d < 0 and info.classID == WEAPON_CLASS then return nil end
    end
    if gains == 0 then return nil end
    return { verdict = (losses == 0) and "better" or "trade", text = FormatDeltas(diff, ignore) }
end

M._Judge = Judge
M._ManaIgnore = function() return MANA_ONLY end

--- Everything a verdict depends on that is the same for every item: what you
--- wear, your level and skills, Dual Wield, mana. Built once per scan.
local function JudgeContext()
    local equipped = {}
    for slot = 1, 18 do
        local link = Try(GetInventoryItemLink, "player", slot)
        if link then equipped[slot] = { link = link, info = FullInfo(link) } end
    end
    return {
        equipped = equipped, level = Num(Try(UnitLevel, "player")), skills = SkillMap(),
        dualWield = CanDualWield(), ignore = ManaIgnore(),
    }
end

--- One item against what you wear. Judged on what the client reports, not
--- item level. Each slot it can really go in is compared; the best verdict
--- wins (better > trade-off), ties going to the weaker current piece.
--- @return table|nil { verdict, slot, name, quality, ilvl, curName, curIlvl, diff }
local function EvaluateLink(link, ctx)
    local info = link and FullInfo(link)
    if not (info and CanEquip(info, ctx.level, ctx.skills)) then return nil end
    local newStats = ItemStats(link)
    local best
    for _, slot in ipairs(SlotsFor(info.equipLoc, ctx.equipped, ctx.dualWield)) do
        local cur = ctx.equipped[slot]
        local curIlvl = cur and cur.info and cur.info.ilvl or 0
        local v
        if newStats then
            v = Judge(newStats, cur and ItemStats(cur.link) or {}, info, ctx.ignore)
        elseif info.ilvl and info.ilvl > curIlvl then
            v = { verdict = "unchecked" }      -- stats not cached yet: say so
        end
        if v and v.verdict then
            local rank = (v.verdict == "better" and 3) or (v.verdict == "trade" and 2) or 1
            if not best or rank > best.rank or (rank == best.rank and curIlvl < best.curIlvl) then
                best = { rank = rank, v = v, slot = slot, cur = cur, curIlvl = curIlvl }
            end
        end
    end
    if not best then return nil end
    return {
        slot = SLOT_NAME[best.slot] or tostring(best.slot), name = info.name,
        quality = info.quality, ilvl = info.ilvl or 0,
        curName = best.cur and best.cur.info and best.cur.info.name, curIlvl = best.curIlvl,
        verdict = best.v.verdict, diff = best.v.text,
    }
end

--- Public: the same verdict for any item link -- the vendor flags and the
--- session check use this, so every place ToonAge calls something an
--- upgrade agrees.
function M:EvaluateItem(link, ctx)
    return EvaluateLink(link, ctx or JudgeContext())
end
M.JudgeContext = JudgeContext

local VERDICT_ORDER = { better = 1, trade = 2, unchecked = 3 }

--- Equippable bag items that beat what you wear on the client's own numbers.
local function BagUpgrades()
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink) then
        return nil
    end
    local ctx = JudgeContext()
    local out = {}
    for bag = 0, 4 do
        local n = Num(Try(C_Container.GetContainerNumSlots, bag)) or 0
        for i = 1, n do
            local link = Try(C_Container.GetContainerItemLink, bag, i)
            local r = link and EvaluateLink(link, ctx)
            if r then out[#out + 1] = r end
        end
    end
    table.sort(out, function(a, b)
        if VERDICT_ORDER[a.verdict] ~= VERDICT_ORDER[b.verdict] then
            return VERDICT_ORDER[a.verdict] < VERDICT_ORDER[b.verdict]
        end
        return (a.name or "") < (b.name or "")
    end)
    return out
end
M.BagUpgrades = function() return BagUpgrades() end

local function Colored(name, quality)
    if not name then return "|cFF6E6A62loading...|r" end
    return "|cFF" .. (QUALITY_HEX[quality or 1] or "ffffff") .. name .. "|r"
end

local function RenderGearCheck(content, y, rows)
    local level = Num(Try(UnitLevel, "player"))
    local skills = SkillMap()
    y = L:SectionHeader(content, y, "Gear Check",
        "What your gear says right now. Facts only: item levels, skills and racials the client reports.")

    -- Weapons: type, skill against cap, racial specialization.
    local specs = WeaponSpecs()
    local anyWeapon = false
    for _, hand in ipairs({ { 16, "Main Hand" }, { 17, "Off Hand" }, { 18, "Ranged" } }) do
        local link = Try(GetInventoryItemLink, "player", hand[1])
        local info = link and FullInfo(link)
        if info and info.classID == WEAPON_CLASS then
            anyWeapon = true
            local sk = skills[WEAPON_SKILL[info.subclassID or -1] or -1]
            local notes = {}
            if sk and sk.rank and sk.max then
                notes[#notes + 1] = string.format("%s skill %d / %d", sk.name, sk.rank, sk.max)
            end
            local status = "neutral"
            for _, sp in ipairs(specs) do
                if sp.subclasses[info.subclassID or -1] then
                    notes[#notes + 1] = string.format("%s active%s", sp.name,
                        sp.crit and string.format(" (+%d%% crit)", sp.crit) or "")
                    status = "good"
                end
            end
            if sk and sk.max and sk.rank and (sk.max - sk.rank) >= 10 then status = "warn" end
            y = L:DataRow(content, y, {
                label = hand[2], value = Colored(info.name, info.quality),
                note = table.concat(notes, "  ·  "), status = status,
                noteColor = (status == "warn") and "warn" or nil,
            })
        end
    end
    -- A racial specialization you are NOT using is worth one line.
    for _, sp in ipairs(specs) do
        local using = false
        for _, slot in ipairs({ 16, 17, 18 }) do
            local info = FullInfo(Try(GetInventoryItemLink, "player", slot))
            if info and info.classID == WEAPON_CLASS and sp.subclasses[info.subclassID or -1] then using = true end
        end
        if not using then
            y = L:Paragraph(content, y, string.format("Your %s%s is not active with the weapons you hold.",
                sp.name, sp.crit and string.format(" (+%d%% crit)", sp.crit) or ""), { color = L.C_DIM })
        end
    end
    if not anyWeapon then
        y = L:Paragraph(content, y, "No weapon equipped.", { color = L.C_WARNING })
    end

    -- Oldest pieces: lowest item level first.
    local worn = {}
    for _, r in ipairs(rows) do
        if not r.empty and r.ilvl and r.ilvl > 0 then worn[#worn + 1] = r end
    end
    table.sort(worn, function(a, b) return a.ilvl < b.ilvl end)
    if #worn > 0 then
        local parts = {}
        for i = 1, math.min(3, #worn) do
            parts[#parts + 1] = string.format("%s (%s, ilvl %d)", worn[i].name or "?", worn[i].slot, worn[i].ilvl)
        end
        y = L:DataRow(content, y, {
            label = "Oldest pieces", value = string.format("ilvl %d", worn[1].ilvl),
            note = table.concat(parts, "  ·  "), status = "dim",
        })
    end

    -- Bag items, judged on the client's own numbers (see Judge).
    local ups = BagUpgrades()
    if ups and #ups > 0 then
        local HEAD = {
            better    = { "Better on every number the client reports:", L.C_SUCCESS, "good" },
            trade     = { "Trade-offs -- gains some, loses some; your call:", L.C_WARNING, "warn" },
            unchecked = { "Not checked yet -- stats still loading:", L.C_DIM, "dim" },
        }
        local last
        for _, u in ipairs(ups) do
            if u.verdict ~= last then
                last = u.verdict
                local h = HEAD[u.verdict]
                y = L:Paragraph(content, y, "In your bags -- " .. h[1], { color = h[2] })
            end
            y = L:DataRow(content, y, {
                label = u.slot,
                value = string.format("%s  (ilvl %d vs %d)",
                    U.MarkItemName(Colored(u.name, u.quality),
                        (u.verdict == "better") and "upgrade" or "sidegrade", true),
                    u.ilvl, u.curIlvl or 0),
                note = (u.curName and ("vs " .. u.curName .. ": ") or "empty slot: ")
                    .. (u.diff or "stats not loaded"),
                status = HEAD[u.verdict][3],
            })
        end
    elseif ups then
        y = L:Paragraph(content, y, "Nothing in your bags beats what you wear on the numbers the "
            .. "client reports (weapon DPS, armor, stats).", { color = L.C_DIM })
    end
    return y
end

-- ─── SECTIONS ────────────────────────────────────────────────────────────

--- Scan equipped slots once, returning per-slot rows and the summed stat table.
--- Equip / Use / proc text for one item, or nil.
---
--- GetItemStats returns numeric stats only. "Equip: Increases damage and
--- healing done by magical spells and effects by up to 1." lives in the
--- tooltip and nowhere else, so it is read from a hidden tooltip through
--- Core/TooltipScan.lua -- the same scanner the TBC build uses, matched against
--- Blizzard's own localised trigger strings rather than English text.
---
--- DISPLAY ONLY. These lines are never added to the totals: modern clients
--- fold some of them into ITEM_MOD_SPELL_POWER already, so counting the text
--- as well would count the same point twice.
-- Scanned once per item link, then remembered.
--
-- A scan calls SetHyperlink, and an item the client has not cached yet answers
-- with a stub AND fires GET_ITEM_INFO_RECEIVED when the real data lands. That
-- event queues a UI refresh, the refresh re-renders this tab, the render scans
-- again -- a slow loop that also kept yanking the view back to the top. Caching
-- by link breaks it: each item is scanned once per session.
--
-- Only a CACHED result is stored. An uncached item is left out so it is picked
-- up on the next render, once its data has actually arrived.
local effectCache = {}

local function EffectLines(link)
    if not link then return nil end
    local hit = effectCache[link]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end

    local TS = TA.TooltipScan
    if not (TS and TS.GetItemFlags) then return nil end
    local ok, flags = pcall(TS.GetItemFlags, TS, link)
    if not ok or type(flags) ~= "table" then return nil end
    if not flags.cached then return nil end        -- try again once it loads

    if type(flags.effectLines) ~= "table" or #flags.effectLines == 0 then
        effectCache[link] = false
        return nil
    end
    effectCache[link] = flags.effectLines
    return flags.effectLines
end

--- One pass over the equipped slots.
--- @return table rows, table totals, table contributions, number equipped, number empty, number avgIlvl
local function ScanEquipped()
    local rows, totals, contrib = {}, {}, {}
    local equippedCount, emptyCount = 0, 0
    local ilvlSum, ilvlCount = 0, 0

    for _, slot in ipairs(SLOTS) do
        local link = Try(GetInventoryItemLink, "player", slot.id)
        if link then
            equippedCount = equippedCount + 1
            local name, ilvl, quality = ItemInfo(link)
            local row = {
                slot = slot.name, link = link, name = name, ilvl = ilvl,
                quality = quality, stats = {},
            }
            rows[#rows + 1] = row

            if ilvl and ilvl > 0 then
                ilvlSum   = ilvlSum + ilvl
                ilvlCount = ilvlCount + 1
            end

            local stats = ItemStats(link)
            if stats then
                for k, v in pairs(stats) do
                    local n = Num(v)
                    if n then
                        if k == DPS_KEY then
                            row.dps = n
                        else
                            totals[k] = (totals[k] or 0) + n
                            -- Which slot gave you this stat, kept for the
                            -- segmented bars. The total is the sum of exactly
                            -- these numbers, so the breakdown can never
                            -- disagree with the figure beside it.
                            contrib[k] = contrib[k] or {}
                            contrib[k][#contrib[k] + 1] = { label = slot.name, value = n }
                            row.stats[#row.stats + 1] = { key = k, value = n }
                        end
                    end
                end
            end

            row.effects = EffectLines(link)

            -- Read order from pairs() is arbitrary; sort so the same item always
            -- lists its stats the same way.
            table.sort(row.stats, function(a, b)
                return StatLabel(a.key) < StatLabel(b.key)
            end)
        else
            emptyCount = emptyCount + 1
            rows[#rows + 1] = { slot = slot.name, empty = true }
        end
    end

    for _, list in pairs(contrib) do
        table.sort(list, function(a, b) return a.value > b.value end)
    end

    local avg = (ilvlCount > 0) and (ilvlSum / ilvlCount) or nil
    return rows, totals, contrib, equippedCount, emptyCount, avg
end

local function RenderHeadline(content, y, rows, equippedCount, emptyCount, avgIlvl)
    y = L:SectionHeader(content, y, "Equipped Gear")

    -- Averaged over FILLED slots, not all of them.
    --
    -- GetAverageItemLevel counts an empty slot as zero, so a level 14 wearing
    -- nine items of level 10-15 was shown "6". That number is not wrong about
    -- its own arithmetic and is useless as a description of your gear. The
    -- client's figure is kept beside it, because that is what every other addon
    -- and Blizzard's own sheet will say.
    if avgIlvl then
        local blizz = Num(Try(GetAverageItemLevel))
        y = L:DataRow(content, y, {
            label = "Average item level",
            value = string.format("%.1f", avgIlvl),
            bold  = true,
            note  = blizz and string.format(
                "across %d equipped item%s; the client reports %d, counting empty slots as zero",
                equippedCount, equippedCount == 1 and "" or "s", math.floor(blizz)) or nil,
        })
    end

    y = L:DataRow(content, y, {
        label = "Slots filled",
        value = string.format("%d / %d", equippedCount, equippedCount + emptyCount),
    })

    -- Empty slots as ONE line instead of eight rows saying "empty". Eight
    -- repetitions of the same word was the loudest thing on this tab and the
    -- least informative; the list is the same information in a tenth the space.
    if emptyCount > 0 then
        local names = {}
        for _, r in ipairs(rows) do
            if r.empty then names[#names + 1] = r.slot end
        end
        y = L:DataRow(content, y, {
            label = "Empty",
            value = tostring(emptyCount),
            note  = table.concat(names, " · "),
            status = "dim",
        })
    end
    return y
end

--- "+3 Stamina  +1 Spirit" for one item.
local function StatSummary(row)
    if not row.stats or #row.stats == 0 then return nil end
    local parts = {}
    for _, s in ipairs(row.stats) do
        parts[#parts + 1] = string.format("%+d %s", s.value, StatLabel(s.key))
    end
    return table.concat(parts, "  ")
end

local function RenderSlots(content, y, rows)
    y = L:SectionHeader(content, y, "By Slot",
        "What each piece is carrying. Empty slots are listed above.")

    for _, r in ipairs(rows) do
        -- Empty slots are summarised in the headline; repeating them here is
        -- the noise this layout exists to remove.
        if not r.empty then
            local hex = QUALITY_HEX[r.quality or 1] or "ffffff"
            local shown = r.name and ("|cFF" .. hex .. r.name .. "|r") or "|cFF6E6A62loading...|r"

            local note = r.ilvl and ("Item level " .. r.ilvl) or nil
            if r.dps then
                local dps = string.format("%.1f DPS", r.dps)
                note = note and (note .. "  ·  " .. dps) or dps
            end

            y = L:DataRow(content, y, { label = r.slot, value = shown, note = note })

            local summary = StatSummary(r)
            if summary then
                y = L:Paragraph(content, y, summary, { color = L.C_SECONDARY, size = 9, gap = 0 })
            end

            -- Equip / Use / proc text, verbatim from the tooltip. Shown in the
            -- game's own green for effect lines so it reads the way it does on
            -- the item itself, and never folded into the totals below.
            if r.effects then
                for _, line in ipairs(r.effects) do
                    y = L:Paragraph(content, y, line, { color = L.C_SUCCESS, size = 9, gap = 0 })
                end
            end

            y = y - 4
        end
    end
    return y
end

local function RenderTotals(content, y, totals, contrib)
    y = L:SectionHeader(content, y, "Combined Stats",
        "Summed from equipped items as the client reports them. Hover a bar to "
        .. "see which slots it came from.")

    -- Ordered known stats first, then anything the client returned that has no
    -- label here -- surfaced under its raw key so an unknown stat is visible
    -- rather than silently dropped. An unknown key is Forever vocabulary nobody
    -- has written down yet, which is worth seeing.
    local ordered, shown = {}, {}
    for _, key in ipairs(STAT_ORDER) do
        local v = totals[key]
        if v and v ~= 0 then
            ordered[#ordered + 1] = { key = key, v = v }
            shown[key] = true
        end
    end
    local extras = {}
    for key, v in pairs(totals) do
        if not shown[key] and v and v ~= 0 then extras[#extras + 1] = { key = key, v = v } end
    end
    table.sort(extras, function(a, b) return a.key < b.key end)
    for _, e in ipairs(extras) do ordered[#ordered + 1] = e end

    if #ordered == 0 then
        y = L:Paragraph(content, y,
            "No item stats to total -- either nothing is equipped, or this client "
            .. "did not answer the item-stat calls.")
        return y
    end

    -- One scale for every bar in the section, so armour's 103 and stamina's 3
    -- are drawn to the same ruler and the comparison between them is real.
    local values = {}
    for _, e in ipairs(ordered) do values[#values + 1] = e.v end
    local scale = L.StatScale and L:StatScale(values) or nil

    for _, e in ipairs(ordered) do
        local segs = contrib[e.key]
        if scale and L.StackBar and segs and #segs > 0 then
            y = L:StackBar(content, y, {
                label = StatLabel(e.key),
                segments = segs, scale = scale,
                text = string.format("%d", e.v),
                status = STAT_LABELS[e.key] and nil or "dim",
            })
        else
            y = L:DataRow(content, y, {
                label = StatLabel(e.key),
                value = string.format("%d", e.v),
                status = STAT_LABELS[e.key] and "neutral" or "dim",
            })
        end
    end

    if totals["RESISTANCE0_NAME"] then
        y = L:Paragraph(content, y,
            "Armor above is the total from your gear. The Character tab shows a "
            .. "higher figure because it adds base armour from agility and level.",
            { color = L.C_DIM })
    end

    y = L:Paragraph(content, y,
        "Forever note: this realm treats Hit as one combined stat and Crit as "
        .. "one combined stat, so if items report melee/ranged/spell variants "
        .. "separately they all feed the same pool. Expertise counts here too, "
        .. "and healing power adds a third of its value as spell damage.",
        { color = L.C_DIM })

    y = L:Paragraph(content, y,
        "Equip and Use lines on the rows above are shown but NOT added here: "
        .. "the client already folds some of them into the stats it reports, and "
        .. "counting the text as well would count the same point twice.",
        { color = L.C_DIM })
    return y
end

local function RenderFooter(content, y)
    y = L:SectionHeader(content, y, "Scoring")
    y = L:Paragraph(content, y,
        "No stat weights yet: Forever's have not been measured, and a score built "
        .. "on guessed weights is confidently wrong. The Gear Check above sticks to "
        .. "what the client reports -- item level, your skills, your racials -- and "
        .. "shows bag upgrades stat by stat so the trade is visible. ForeverGear, "
        .. "the dedicated gear addon, ships Level-20 stat-priority profiles if you "
        .. "want a score.")
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

-- Defined further down (with the vendor and recipe code it shares helpers
-- with); declared here so Render, which comes first, can call it.
local RenderEnchants

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    -- Reuse the Character tab's identity sidebar if it is available, so Gear
    -- has the same left column and does not draw a blank one. Guarded: if that
    -- module or its helper is absent, the sidebar is simply left empty.
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local rows, totals, contrib, equippedCount, emptyCount, avgIlvl = ScanEquipped()

    local y = -8
    y = RenderGearCheck(content, y, rows)
    y = L:Divider(content, y)
    y = RenderEnchants(content, y)
    y = L:Divider(content, y)
    y = RenderHeadline(content, y, rows, equippedCount, emptyCount, avgIlvl)
    y = L:Divider(content, y)
    y = RenderSlots(content, y, rows)
    y = L:Divider(content, y)
    y = RenderTotals(content, y, totals, contrib)
    y = L:Divider(content, y)
    y = RenderFooter(content, y)
    L:Finish(content, y)
end

-- ─── ENCHANTS & CRAFTING (2026-10-03) ─────────────────────────────────────
-- Three questions: is each piece enchanted, which enchants do you know for the
-- ones that aren't, and can any of your professions make an upgrade?
--
--   * Enchanted or not: the item link's second field is the enchant id
--     (item:itemID:enchantID:...). Format, not API -- readable on every client.
--   * Your recipes: only visible while a profession window is open, so they
--     are RECORDED then (charDB.recipes) and used afterwards. Forever's trade
--     skill API is UNVERIFIED: the modern (C_TradeSkillUI) and the Vanilla
--     (GetTradeSkillInfo / GetCraftInfo -- Enchanting used the Craft frame)
--     forms are both tried, and which one answered is recorded with the list.
--   * Craftable upgrades: each recipe's product goes through EvaluateLink, the
--     same verdict as bags and vendors. "Can make now" is the client's own
--     count of how many your bags have materials for, as of the last time the
--     window was open -- said with its time, because it goes stale.
--
-- Enchant recipes are matched to slots by their English name ("Enchant
-- Bracer - ..."). Other locales: the slot list still shows, matching does not.

local ENCHANT_SLOTS = {        -- slot id -> what the enchant recipes call it
    [5] = "Chest", [8] = "Boots", [9] = "Bracer", [10] = "Gloves",
    [15] = "Cloak", [16] = "Weapon", [17] = "Shield",
}
local ENCHANT_NAME_SLOT = {    -- longest first: "2H Weapon" before "Weapon"
    { "Enchant 2H Weapon", 16, "2h" }, { "Enchant Weapon", 16 }, { "Enchant Bracer", 9 },
    { "Enchant Boots", 8 }, { "Enchant Chest", 5 }, { "Enchant Cloak", 15 },
    { "Enchant Gloves", 10 }, { "Enchant Shield", 17, "shield" },
}

--- Enchant id on an equipped item's link, 0 when none, nil when no link.
local function EnchantID(link)
    if not link then return nil end
    local e = link:match("item:%-?%d+:(%-?%d*)")
    return tonumber(e) or 0
end
M._EnchantID = EnchantID

--- Read the open profession window into charDB.recipes[profession].
function M:RecordRecipes()
    local c = TA.charDB
    if not c then return end
    local list, prof, api = {}, nil, nil
    local TS = C_TradeSkillUI
    if TS and TS.GetAllRecipeIDs and TS.GetRecipeInfo then
        local ids = Try(TS.GetAllRecipeIDs)
        if type(ids) == "table" and #ids > 0 then
            api = "C_TradeSkillUI"
            for _, id in ipairs(ids) do
                local info = Try(TS.GetRecipeInfo, id)
                if type(info) == "table" and info.learned ~= false and info.name then
                    list[#list + 1] = { name = info.name, avail = tonumber(info.numAvailable) or 0,
                        link = TS.GetRecipeItemLink and Try(TS.GetRecipeItemLink, id) or nil }
                end
            end
            local base = TS.GetBaseProfessionInfo and Try(TS.GetBaseProfessionInfo)
            prof = type(base) == "table" and base.professionName or nil
            if not prof and _G.GetTradeSkillLine then prof = Try(GetTradeSkillLine) end
        end
    end
    if not api and _G.GetNumTradeSkills then
        local n = tonumber(Try(GetNumTradeSkills)) or 0
        if n > 0 then
            api = "GetTradeSkillInfo"
            for i = 1, n do
                local name, kind, avail = Try(GetTradeSkillInfo, i)
                if name and kind ~= "header" then
                    list[#list + 1] = { name = name, avail = tonumber(avail) or 0,
                        link = Try(_G.GetTradeSkillItemLink, i) }
                end
            end
            prof = Try(_G.GetTradeSkillLine)
        end
    end
    if not api and _G.GetNumCrafts then
        local n = tonumber(Try(GetNumCrafts)) or 0
        if n > 0 then
            api = "GetCraftInfo"
            for i = 1, n do
                local name, _, kind, avail = Try(GetCraftInfo, i)
                if name and kind ~= "header" then
                    list[#list + 1] = { name = name, avail = tonumber(avail) or 0,
                        link = Try(_G.GetCraftItemLink, i) }
                end
            end
            prof = Try(_G.GetCraftDisplaySkillLine)
        end
    end
    c.recipeProbe = (date and date("%Y-%m-%d %H:%M") or "?") .. " | " .. tostring(api or "no trade skill API answered")
        .. " | profession=" .. tostring(prof) .. " recipes=" .. #list
    if not (api and prof and #list > 0) then return end
    c.recipes = c.recipes or {}
    c.recipes[tostring(prof)] = { at = time and time() or nil, api = api, list = list }
    if TA.QueueUIRefresh then TA:QueueUIRefresh("RECIPES_RECORDED") end
end

local recipePending = false
local function QueueRecipes()
    if recipePending then return end
    recipePending = true
    C_Timer.After(0.5, function() recipePending = false; pcall(M.RecordRecipes, M) end)
end

local function Ago(at)
    if not (at and time) then return "" end
    local m = math.floor((time() - at) / 60)
    if m < 60 then return m .. " min ago" end
    if m < 1440 then return math.floor(m / 60) .. " h ago" end
    return math.floor(m / 1440) .. " d ago"
end

RenderEnchants = function(content, y)
    y = L:SectionHeader(content, y, "Enchants & crafting",
        "What is enchanted, what you know for the rest, and what your professions can make.")
    local mh = Try(GetInventoryItemLink, "player", 16)
    local mhInfo = mh and FullInfo(mh)
    local twoHanded = mhInfo and mhInfo.equipLoc == "INVTYPE_2HWEAPON"
    local ohInfo = FullInfo(Try(GetInventoryItemLink, "player", 17))
    local hasShield = ohInfo and ohInfo.equipLoc == "INVTYPE_SHIELD"

    -- Known enchants, by slot, from every recorded profession.
    local recipes = (TA.charDB and TA.charDB.recipes) or {}
    local bySlot = {}
    for prof, rec in pairs(recipes) do
        for _, r in ipairs(rec.list or {}) do
            for _, m in ipairs(ENCHANT_NAME_SLOT) do
                if r.name:sub(1, #m[1]) == m[1] then
                    local fits = (m[3] == nil) or (m[3] == "2h" and twoHanded) or (m[3] == "shield" and hasShield)
                    if m[1] == "Enchant Weapon" and twoHanded then fits = true end   -- 1H enchants fit 2H too
                    if fits then
                        bySlot[m[2]] = bySlot[m[2]] or {}
                        table.insert(bySlot[m[2]], { name = r.name, avail = r.avail, at = rec.at })
                    end
                    break
                end
            end
        end
    end

    local missing = 0
    local missingRows = {}
    local hasEnchanting = recipes["Enchanting"] ~= nil
    for _, slot in ipairs({ 15, 5, 9, 10, 8, 16, 17 }) do
        local link = Try(GetInventoryItemLink, "player", slot)
        local relevant = link and (slot ~= 17 or hasShield)
        if relevant then
            local enchanted = (EnchantID(link) or 0) > 0
            if not enchanted then
                missing = missing + 1
                missingRows[#missingRows + 1] = slot
            end
        end
    end
    if missing == 0 then
        y = L:Paragraph(content, y, "Every enchantable piece you wear is enchanted.", { color = L.C_SUCCESS })
    elseif not hasEnchanting then
        y = L:Paragraph(content, y, "No Enchanting profession, so empty slots are not listed one by one.",
            { color = L.C_DIM })
    else
        for _, slot in ipairs(missingRows) do
            local known = bySlot[slot]
            local note
            if known and #known > 0 then
                table.sort(known, function(a, b) return a.avail > b.avail end)
                local parts = {}
                for k = 1, math.min(3, #known) do
                    local e = known[k]
                    parts[#parts + 1] = e.name:gsub("^Enchant [^-]+%- ", "")
                        .. ((e.avail > 0) and (" (materials for " .. e.avail .. ")") or "")
                end
                note = "you know: " .. table.concat(parts, "; ")
            else
                note = "no enchant for this slot among your recorded recipes"
            end
            y = L:DataRow(content, y, { label = (SLOT_NAME[slot] or tostring(slot)) .. " — not enchanted",
                value = (known and #known > 0) and "you can enchant this" or "", note = note,
                status = (known and #known > 0) and "warn" or "dim" })
        end
    end

    -- Craftable upgrades: every recipe product through the shared verdict.
    local ctx, craft = JudgeContext(), {}
    for prof, rec in pairs(recipes) do
        for _, r in ipairs(rec.list or {}) do
            local v = r.link and EvaluateLink(r.link, ctx)
            if v and v.verdict ~= "unchecked" then
                craft[#craft + 1] = { v = v, avail = r.avail, prof = prof, at = rec.at }
            end
        end
    end
    local function NetNegative(diff)
        if not diff or diff == "" then return false end
        local anyPos = false
        for n in tostring(diff):gmatch("([%+%-]%d+)") do
            local v = tonumber(n)
            if v and v > 0 then anyPos = true end
        end
        return not anyPos and tostring(diff):find("%-%d") ~= nil
    end
    local shown = {}
    for _, c in ipairs(craft) do
        if not NetNegative(c.v.diff) then shown[#shown + 1] = c end
    end
    table.sort(shown, function(a, b)
        if (a.v.verdict == "better") ~= (b.v.verdict == "better") then return a.v.verdict == "better" end
        return a.avail > b.avail
    end)
    for k = 1, math.min(6, #shown) do
        local c = shown[k]
        local note = c.v.diff or ""
        if c.avail and c.avail > 0 then
            note = "materials for " .. c.avail .. ((note ~= "") and (" · " .. note) or "")
        end
        y = L:DataRow(content, y, {
            label = c.v.slot .. " — " .. c.prof,
            value = U.MarkItemName(Colored(c.v.name, c.v.quality),
                (c.v.verdict == "better") and "upgrade" or "sidegrade", true),
            note = note,
            status = (c.v.verdict == "better") and "good" or "warn",
        })
    end

    -- What has not been read yet, by name, from the professions you have.
    local unread = {}
    local p1, p2, _, fishing, cooking = Try(GetProfessions)
    for _, idx in ipairs({ p1, p2, cooking, fishing }) do
        local name = idx and Try(GetProfessionInfo, idx)
        if name and not recipes[name] and name ~= "Fishing" then unread[#unread + 1] = name end
    end
    local footer = {}
    if #unread > 0 then
        footer[#footer + 1] = "Open your " .. table.concat(unread, ", ")
            .. " window once so ToonAge can read your recipes."
    end
    local oldest
    for _, rec in pairs(recipes) do if rec.at and (not oldest or rec.at < oldest) then oldest = rec.at end end
    if oldest then
        footer[#footer + 1] = "Material counts are from when each window was last open (oldest " .. Ago(oldest)
            .. "). Enchants other players can make are not listed: only your own recipes are known."
    end
    if #footer > 0 then
        y = L:Paragraph(content, y, table.concat(footer, " "), { color = L.C_DIM })
    end
    return y
end

-- ─── VENDOR FLAGS (2026-10-03) ────────────────────────────────────────────
-- At a vendor, items that would be an upgrade get a small badge on their
-- button -- "UP" (green) for better on every reported number, "+/-" (orange)
-- for a trade-off -- and a ToonAge line in their tooltip with the difference.
-- One quiet line on the vendor window counts them. No popup, no chat, no
-- sound, nothing bought: the same verdict as the Gear tab (EvaluateLink).
--
-- UNVERIFIED ON FOREVER: the merchant frame names (MerchantItem<N>ItemButton,
-- MerchantFrame.page / selectedTab) are Mainline's. Every lookup is guarded;
-- what was found is recorded in ToonAgeDB.vendorProbe on the first visit so a
-- silent no-show can be diagnosed.

local MERCHANT_PER_PAGE = tonumber(_G.MERCHANT_ITEMS_PER_PAGE) or 10
local vendorPending = false

local function MerchantLink(index)
    if C_MerchantFrame and C_MerchantFrame.GetItemLink then
        local l = Try(C_MerchantFrame.GetItemLink, index)
        if l then return l end
    end
    return Try(_G.GetMerchantItemLink, index)
end

--- Price in copper for a gold-priced item, or nil (unknown, or paid in
--- tokens/honor -- then affordability isn't judged).
local function MerchantPrice(index)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = Try(C_MerchantFrame.GetItemInfo, index)
        if type(info) == "table" then
            if info.hasExtendedCost then return nil end
            return tonumber(info.price)
        end
    end
    local r = { Try(_G.GetMerchantItemInfo, index) }
    -- name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost
    if r[1] == nil then return nil end
    if r[8] then return nil end
    return tonumber(r[3])
end

local function Badge(btn)
    if btn._taBadge then return btn._taBadge end
    local f = CreateFrame("Frame", nil, btn)
    f:SetSize(22, 12)
    f:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
    f:SetFrameLevel((btn:GetFrameLevel() or 1) + 5)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.75)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    f.text:SetPoint("CENTER")
    f:Hide()
    btn._taBadge = f
    -- Tooltip line, added after Blizzard has drawn the item tooltip. HookScript
    -- runs after the original handler and never replaces it.
    btn:HookScript("OnEnter", function(self)
        local r = self._taVerdict
        if not (r and GameTooltip and GameTooltip:IsOwned(self)) then return end
        local head = (r.verdict == "better") and "|cFF4AE07AToonAge: upgrade|r"
            or "|cFFFFA633ToonAge: trade-off|r"
        local nameFS = _G["GameTooltipTextLeft1"]
        if nameFS and nameFS.GetText and nameFS.SetText then
            nameFS:SetText(U.MarkItemName(nameFS:GetText() or "",
                (r.verdict == "better") and "upgrade" or "sidegrade", true))
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(head .. "  (" .. r.slot .. (r.curName and (", vs " .. r.curName) or ", empty slot") .. ")")
        if r.diff then GameTooltip:AddLine(r.diff, 0.85, 0.85, 0.85, true) end
        if r.short then
            GameTooltip:AddLine("Not affordable yet: " .. (Try(GetMoneyString, r.short) or (r.short .. "c"))
                .. " short.", 1, 0.45, 0.4)
        end
        GameTooltip:Show()
    end)
    return f
end

local function MerchantNote()
    local mf = _G.MerchantFrame
    if not mf then return nil end
    if not mf._taNote then
        local fs = mf:CreateFontString(nil, "OVERLAY")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        fs:SetPoint("BOTTOMLEFT", mf, "BOTTOMLEFT", 16, 34)
        mf._taNote = fs
    end
    return mf._taNote
end

function M:FlagVendor()
    vendorPending = false
    local mf = _G.MerchantFrame
    -- Only the buyback tab (2) is excluded. MEASURED on Forever 70205: the buy
    -- view does not report selectedTab == 1, so "== 1" skipped every vendor.
    local onBuyTab = mf and mf:IsShown() and mf.selectedTab ~= 2
    local page = (mf and tonumber(mf.page)) or 1
    local ctx = onBuyTab and JudgeContext() or nil
    local money = tonumber(Try(GetMoney)) or nil
    -- Counts for the window line AND for vendorProbe, so a silent vendor can
    -- be told apart: no buttons (frame names differ -> code fix) vs. links not
    -- read vs. scanned and nothing qualified (working as intended).
    local c = { buttons = 0, links = 0, better = 0, trade = 0, short = 0, none = 0 }
    for i = 1, MERCHANT_PER_PAGE do
        local btn = _G["MerchantItem" .. i .. "ItemButton"]
        if btn then
            c.buttons = c.buttons + 1
            local r
            if ctx then
                local index = (page - 1) * MERCHANT_PER_PAGE + i
                local link = MerchantLink(index)
                if link then
                    c.links = c.links + 1
                    r = EvaluateLink(link, ctx)
                    if r and r.verdict == "unchecked" then r = nil end
                    if r then
                        local price = MerchantPrice(index)
                        r.short = (price and money and price > money) and (price - money) or nil
                    else
                        c.none = c.none + 1
                    end
                end
            end
            btn._taVerdict = r
            -- The badge frame only exists so its OnEnter hook can run. The
            -- mark itself is 4px after the item name, not in the corner.
            local b = Badge(btn)
            b:Hide()
            local nameFS = _G["MerchantItem" .. i .. "Name"]
            if nameFS and nameFS.GetText and nameFS.SetText then
                local plain = (nameFS:GetText() or ""):gsub("|T.-|t", "")
                local mark = ""
                if r then
                    mark = U.GearMarkForVerdict((r.verdict == "better") and "upgrade" or "sidegrade", true)
                end
                nameFS:SetText(plain .. mark)
            end
            if r then
                if r.verdict == "better" then c.better = c.better + 1 else c.trade = c.trade + 1 end
                if r.short then c.short = c.short + 1 end
            end
        end
    end
    local note = MerchantNote()
    if note then
        if c.better + c.trade > 0 then
            local parts = {}
            if c.better > 0 then
                parts[#parts + 1] = string.format("|cFF4AE07A%d upgrade%s|r", c.better, c.better == 1 and "" or "s")
            end
            if c.trade > 0 then
                parts[#parts + 1] = string.format("|cFFFFA633%d trade-off%s|r", c.trade, c.trade == 1 and "" or "s")
            end
            local tail = (c.short > 0) and string.format(" (%d not affordable yet)", c.short) or ""
            note:SetText("|cFFFFD100ToonAge|r: " .. table.concat(parts, ", ") .. tail
                .. " on this page -- hover for the difference")
            note:Show()
        else
            note:Hide()
        end
    end
    if TA.db then
        local why
        if not onBuyTab then why = "not on the buy tab"
        elseif c.buttons == 0 then why = "NO merchant buttons found -- frame names differ on this client (code fix)"
        elseif c.links == 0 then why = "buttons found but no item links read -- link API differs (code fix)"
        elseif c.better + c.trade == 0 then why = "working: scanned, nothing qualified"
        else why = "working: flagged items" end
        TA.db.vendorProbe = string.format("%s | %s | tab=%s page=%s buttons=%d links=%d better=%d trade=%d "
            .. "notAffordable=%d notOffered=%d | C_MerchantFrame.GetItemLink=%s GetMerchantItemLink=%s price=%s",
            date and date("%Y-%m-%d %H:%M") or "?", why, tostring(mf and mf.selectedTab), tostring(mf and mf.page),
            c.buttons, c.links, c.better, c.trade, c.short, c.none,
            tostring(C_MerchantFrame and C_MerchantFrame.GetItemLink ~= nil),
            tostring(_G.GetMerchantItemLink ~= nil),
            (C_MerchantFrame and C_MerchantFrame.GetItemInfo) and "C_MerchantFrame.GetItemInfo"
                or (_G.GetMerchantItemInfo and "GetMerchantItemInfo" or "none"))
    end
end

local function QueueVendor()
    if vendorPending then return end
    vendorPending = true
    C_Timer.After(0.1, function() pcall(M.FlagVendor, M) end)
end

local function HideVendorFlags()
    for i = 1, MERCHANT_PER_PAGE do
        local btn = _G["MerchantItem" .. i .. "ItemButton"]
        if btn then
            btn._taVerdict = nil
            if btn._taBadge then btn._taBadge:Hide() end
        end
        local nameFS = _G["MerchantItem" .. i .. "Name"]
        if nameFS and nameFS.GetText and nameFS.SetText then
            nameFS:SetText((nameFS:GetText() or ""):gsub("|T.-|t", ""))
        end
    end
    local mf = _G.MerchantFrame
    if mf and mf._taNote then mf._taNote:Hide() end
end

function M:OnEvent(event)
    if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        -- Page turns and the buy/buyback tabs redraw through MerchantFrame_Update;
        -- hooked once, after the fact, so Blizzard's own code runs untouched.
        if not self._merchantHooked and type(_G.MerchantFrame_Update) == "function" then
            self._merchantHooked = true
            hooksecurefunc("MerchantFrame_Update", QueueVendor)
        end
        QueueVendor()
        return
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE"
        or event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
        QueueRecipes()
        return
    elseif event == "PLAYER_MONEY" then
        if _G.MerchantFrame and _G.MerchantFrame:IsShown() then QueueVendor() end
        return
    elseif event == "MERCHANT_CLOSED" then
        HideVendorFlags()
        return
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if _G.MerchantFrame and _G.MerchantFrame:IsShown() then QueueVendor() end
        return
    end
    -- Gear or skills changed with the vendor open: the verdicts changed too.
    if _G.MerchantFrame and _G.MerchantFrame:IsShown() then QueueVendor() end
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    -- PLAYER_AVG_ITEM_LEVEL_UPDATE is gone on purpose: this tab computes its
    -- own average from the equipped slots, so the client's figure changing is
    -- not news, and the event fires often enough to be felt as the view
    -- jumping while you read.
    "PLAYER_EQUIPMENT_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    -- Bag contents feed the "in your bags" check.
    "BAG_UPDATE_DELAYED",
    "SKILL_LINES_CHANGED",
    -- Vendor flags.
    "MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED", "GET_ITEM_INFO_RECEIVED",
    "PLAYER_MONEY",   -- selling junk can make a flagged item affordable
    -- Recipe recording (absorbed if this client lacks any of them).
    "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_UPDATE", "CRAFT_SHOW", "CRAFT_UPDATE",
}

return M
