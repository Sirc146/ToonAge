-- Tools/fixtures/harvest_world_forever.lua
--
-- A deterministic WoW Forever client for the harvest tests
-- (Tools/test_harvest_packs.py): every API the recorder touches, with fixed
-- answers shaped like the ones measured on Forever 1.60.1 build 70205. Not
-- addon code; no TOC lists it. Globals ending in _LOG collect what the addon
-- did (events registered, windows opened, chat lines, Layout calls); TIMERS
-- queues C_Timer.After callbacks until FLUSH() runs them.

EVENTS_LOG, WINDOWS_LOG, CHAT_LOG, LAYOUT_LOG, SLASH_LOG = {}, {}, {}, {}, {}
TIMERS = {}
NOW = 1791160000

ToonAge = {
    flavor = "forever", version = "2.0.0-dev.1", IsForever = true, debug = false,
    LOG = { OUTPUT = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4 },
    modules = {}, charDB = { combatLog = { fights = 2, spells = { a = { casts = 3 }, b = { casts = 4 } } } },
}
local TA = ToonAge
function TA:RegisterModule(n, m) self.modules[n] = m end
function TA:GetModule(n) local m = self.modules[n]; if m and not m._disabled then return m end end
function TA:RegisterEvent(e) EVENTS_LOG[#EVENTS_LOG + 1] = e; return true end
function TA:Raw(level, msg) CHAT_LOG[#CHAT_LOG + 1] = tostring(level) .. "|" .. tostring(msg) end
function TA:ShowCopyWindow(title, text) WINDOWS_LOG[#WINDOWS_LOG + 1] = { title = title, text = text } end
function TA:SlashCommand(c) SLASH_LOG[#SLASH_LOG + 1] = c end

-- Bags as the Utils helpers see them (the scroll probe reads through these).
local BAG_LINKS = {
    [0] = { "|cffffffff|Hitem:2589::::::::18:::::::|h[Linen Cloth]|h|r",
            "|cff1eff00|Hitem:3013::::::::18:::::::|h[Scroll of Protection]|h|r",
            "|cffffffff|Hitem:118::::::::18:::::::|h[Minor Healing Potion]|h|r",
            "|cffffffff|Hitem:99999::::::::18:::::::|h[Uncached Thing]|h|r" },
}
TA.Utils = {
    SafeNum = function(v, d) return tonumber(v) or d end,
    GetContainerNumSlots = function(bag) return BAG_LINKS[bag] and #BAG_LINKS[bag] or 0 end,
    GetContainerItemLink = function(bag, slot) return BAG_LINKS[bag] and BAG_LINKS[bag][slot] end,
}

-- Layout: records every call; each moves y down by 10.
local function rec(s) LAYOUT_LOG[#LAYOUT_LOG + 1] = s end
TA.Layout = {
    C_DIM = "dim",
    SectionHeader = function(self, c, y, t, sub) rec("SectionHeader|" .. tostring(t) .. "|" .. tostring(sub)); return y - 10 end,
    DataRow = function(self, c, y, o) rec("DataRow|" .. tostring(o.label) .. "|" .. tostring(o.value)); return y - 10 end,
    Paragraph = function(self, c, y, t, o) rec("Paragraph|" .. tostring(t) .. "|" .. tostring(o and o.color)); return y - 10 end,
    ButtonRow = function(self, c, y, btns, o)
        local labels = {}
        for _, b in ipairs(btns) do labels[#labels + 1] = b.label end
        rec("ButtonRow|" .. table.concat(labels, ",") .. "|" .. tostring(o and o.label)); return y - 10 end,
    Divider = function(self, c, y) rec("Divider"); return y - 10 end,
    Finish = function(self, c, y) rec("Finish|" .. tostring(y)) end,
    RefreshUI = function() rec("RefreshUI") end,
}

function time() return NOW end
function date(f, t) return os.date(f, t or NOW) end
function debugprofilestop() return 0 end
function GetTime() return 0 end
C_Timer = { After = function(sec, fn) TIMERS[#TIMERS + 1] = fn end }
function FLUSH()
    local guard = 0
    while #TIMERS > 0 and guard < 10000 do
        guard = guard + 1
        local fn = table.remove(TIMERS, 1)
        fn()
    end
end
function issecretvalue(v) return false end

WOW_PROJECT_ID = 18
function GetBuildInfo() return "1.60.1", "70205", "Oct  2 2026", 16001, "", " " end
LEVEL = 18
function UnitClass() return "Mage", "MAGE", 8 end
function UnitLevel() return LEVEL end
function UnitName(unit)
    if unit == "npc" or unit == "target" then return "Aelthalyste" end
    return "Eramali"
end
function GetRealmName() return "Classic Beta PvE" end
function UnitRace() return "Undead", "Scourge" end
function UnitSex() return 3 end
function UnitGUID(unit)
    if unit == "npc" or unit == "target" then return "Creature-0-1-0-1454-5490-0000ABCD" end
    return "Player-4618-008D2110"
end
function UnitFactionGroup() return "Horde", "Horde" end

-- ── Items ────────────────────────────────────────────────────────────────
local ITEMS = {
    [2589]  = { "Linen Cloth", 5, 1, 0, "Trade Goods", "Cloth", 20, "INVTYPE_NON_EQUIP_IGNORE", 7, 5, 0, {} },
    [3013]  = { "Scroll of Protection", 10, 1, 1, "Consumable", "Scrolls", 20, "INVTYPE_NON_EQUIP_IGNORE", 0, 4, 0, {} },
    [118]   = { "Minor Healing Potion", 5, 1, 1, "Consumable", "Potions", 20, "INVTYPE_NON_EQUIP_IGNORE", 0, 1, 0, {} },
    [6242]  = { "Blue Linen Robe", 14, 2, 9, "Armor", "Cloth", 1, "INVTYPE_ROBE", 4, 1, 2, { ITEM_MOD_SPIRIT_SHORT = 3, RESISTANCE0_NAME = 26, ITEM_MOD_SPELL_POWER_SHORT = 2 } },
    [3446]  = { "Darkwood Staff", 13, 2, 0, "Weapon", "Staves", 1, "INVTYPE_2HWEAPON", 2, 10, 1, { ITEM_MOD_STAMINA_SHORT = 3 } },
    [5252]  = { "Wand of Decay", 21, 2, 0, "Weapon", "Wands", 1, "INVTYPE_RANGEDRIGHT", 2, 19, 1, { ITEM_MOD_INTELLECT_SHORT = 2 } },
    [2770]  = { "Copper Ore", 10, 1, 0, "Trade Goods", "Metal & Stone", 20, "INVTYPE_NON_EQUIP_IGNORE", 7, 7, 0, {} },
    [12223] = { "Meaty Bat Wing", 5, 1, 0, "Trade Goods", "Cooking", 20, "INVTYPE_NON_EQUIP_IGNORE", 7, 8, 0, {} },
}
local function idOf(link) return tonumber(tostring(link):match("item:(%d+)")) end
local function link(id) local i = ITEMS[id]; return ("|cffffffff|Hitem:%d::::::::18:::::::|h[%s]|h|r"):format(id, i and i[1] or "?") end
local EQUIPPED = { [5] = link(6242), [16] = link(3446), [18] = link(5252) }
function GetInventoryItemLink(unit, slot) return EQUIPPED[slot] end
C_Container = {
    GetContainerNumSlots = function(bag) return BAG_LINKS[bag] and #BAG_LINKS[bag] or 0 end,
    GetContainerItemLink = function(bag, slot) return BAG_LINKS[bag] and BAG_LINKS[bag][slot] end,
    PickupContainerItem = function() end,
}
C_Item = {
    GetItemInfoInstant = function(l) return idOf(l) end,
    GetItemInfo = function(l)
        local i = ITEMS[idOf(l)]
        if not i then return nil end
        return i[1], l, i[3], i[2], i[4], i[5], i[6], i[7], i[8], 134000, 10, i[9], i[10], i[11]
    end,
    GetItemStats = function(l) local i = ITEMS[idOf(l)]; return i and i[12] or nil end,
}
function GetNumLootItems() return 2 end
function GetLootSlotLink(i) return ({ link(2770), link(12223) })[i] end

-- ── Spellbook, spells, tooltips ──────────────────────────────────────────
SPELL = {   -- id = { name, subtext, learned }
    [133] = { "Fireball", "Rank 1", 1 }, [143] = { "Fireball", "Rank 2", 6 }, [145] = { "Fireball", "Rank 3", 12 },
    [3140] = { "Fireball", "Rank 4", 18 }, [116] = { "Frostbolt", "Rank 1", 4 }, [1459] = { "Arcane Intellect", "Rank 1", 1 },
    [7744] = { "Will of the Forsaken", "Racial", 0 }, [20577] = { "Cannibalize", "Racial", 0 },
    [81] = { "Dodge", "Passive", 1 }, [6603] = { "Attack", "", 0 },
    [11069] = { "Improved Fireball", "", 0 }, [11426] = { "Ice Barrier", "", 0 },
}
local BOOK = {
    { name = "General", items = { { 7744, false }, { 20577, false }, { 81, true }, { 6603, false } } },
    { name = "Fire", items = { { 133, false }, { 143, false }, { 145, false }, { 3140, false } } },
    { name = "Frost", items = { { 116, false } } },
    { name = "Arcane", items = { { 1459, false } } },
}
Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 } }
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return #BOOK end,
    GetSpellBookSkillLineInfo = function(line)
        local off = 0
        for i = 1, line - 1 do off = off + #BOOK[i].items end
        return { name = BOOK[line].name, itemIndexOffset = off, numSpellBookItems = #BOOK[line].items }
    end,
    GetSpellBookItemInfo = function(i, bank)
        local n = 0
        for _, ln in ipairs(BOOK) do
            for _, it in ipairs(ln.items) do
                n = n + 1
                if n == i then
                    local sp = SPELL[it[1]]
                    return { spellID = it[1], name = sp[1], subName = (it[1] == 133) and "" or sp[2], isPassive = it[2] }
                end
            end
        end
    end,
}
C_Spell = {
    GetSpellSubtext = function(id) local s = SPELL[id]; return s and s[2] or "" end,
    GetSpellLevelLearned = function(id) local s = SPELL[id]; return s and s[3] or 0 end,
    GetSpellName = function(id) local s = SPELL[id]; return s and s[1] or nil end,
    GetSpellTexture = function(id) return 135800 + (id % 100) end,
    GetSpellPowerCost = function(id) return { { cost = 30, name = "MANA", type = 0 } } end,
    GetSpellInfo = function(id) local s = SPELL[id]; return s and { name = s[1], spellID = id, castTime = 1000 } or nil end,
    RequestLoadSpellData = function() end,
}
C_TooltipInfo = {
    GetSpellByID = function(id)
        local s = SPELL[id]
        if not s then return nil end
        return { lines = { { leftText = s[1] }, { leftText = "Instant", rightText = "2 min cooldown" }, { leftText = s[1] .. " effect." } } }
    end,
    GetTrainerService = function(i) local r = TRAINER[i]; return r and { id = r[4] } or nil end,
    GetHyperlink = function(l) return { lines = { { leftText = "Scroll of Protection" }, { leftText = "Use: armor up." } } } end,
}

-- ── Trait tree ───────────────────────────────────────────────────────────
C_ClassTalents = { GetActiveConfigID = function() return 7 end }
NODES = {
    [105795] = { posX = 300, posY = 600, entry = 130524, def = 9001, spell = 11069, rank = 5, max = 5, edges = { { targetNode = 105796, type = 0 } }, conds = { 43463 } },
    [105762] = { posX = 900, posY = 1200, entry = 130491, def = 9002, spell = 11426, rank = 0, max = 1, edges = {}, conds = {} },
}
C_Traits = {
    GetConfigInfo = function(id) return { treeIDs = { 1112 } } end,
    GetTreeInfo = function(cfg, tree) return { gates = { { topLeftNodeID = 105762, conditionID = 43465 } } } end,
    GetConditionInfo = function(cfg, c) return { spentAmountRequired = c % 30, isMet = false } end,
    GetTreeNodes = function(tree) return { 105762, 105795 } end,
    GetNodeInfo = function(cfg, node)
        local n = NODES[node]
        return { ID = node, activeEntry = { entryID = n.entry }, activeRank = n.rank, maxRanks = n.max,
                 posX = n.posX, posY = n.posY, visibleEdges = n.edges, conditionIDs = n.conds, type = 0,
                 entryIDs = { n.entry } }
    end,
    GetEntryInfo = function(cfg, entry)
        for _, n in pairs(NODES) do if n.entry == entry then return { definitionID = n.def } end end
    end,
    GetDefinitionInfo = function(def)
        for _, n in pairs(NODES) do if n.def == def then return { spellID = n.spell } end end
    end,
}

-- ── Trainer (a class trainer visit) ──────────────────────────────────────
TRAINER = {   -- name, category, levelReq, id
    { "Fireball", "used", 1, 133 }, { "Fireball", "available", 18, 3140 }, { "Fireball", "unavailable", 24, 8400 },
    { "Frostbolt", "unavailable", 20, 7322 }, { "Class header", "header", 0, 1 },
}
function GetNumTrainerServices() return #TRAINER end
function GetTrainerServiceInfo(i) local r = TRAINER[i]; return r[1], r[2], 135812 end
function GetTrainerServiceLevelReq(i) return TRAINER[i][3] end
function GetTrainerServiceTypeFilter(f) return true end

-- ── Probe-only APIs ──────────────────────────────────────────────────────
function GetProfessions() return 7, 8, nil, 9, 6, 5 end
function GetProfessionInfo(i) return "Prof" .. i, 136000 + i, 10 * i, 75, 1, 40 + i, 100 + i, 0, -1, 0, "Prof" .. i end
C_TradeSkillUI = { GetProfessionInfoBySkillLineID = function(id) return { professionID = id, professionName = "Comprehension", skillLevel = 0 } end }
function IsSpellKnown(id) return id == 1296017 end
function GetSpellBonusDamage(s) return 10 + s end
function GetSpellBonusHealing() return 12 end
function GetManaRegen() return 12.5, 0.5 end
function GetHitModifier() return 0 end
function GetSpellHitModifier() return 0 end
function GetExpertise() return 0, 0, 0 end
function GetCritChance() return 3.9 end
function GetDodgeChance() return 4.7 end
function GetParryChance() return 0 end
function GetBlockChance() return 0 end
function UnitAttackSpeed() return 3.2, nil, 1.5 end
function UnitDamage() return 20.2, 29.2, 1.5, 1.5, 0, 0, 1 end
C_SkillInfo = {
    GetNumSkillLines = function() return 2 end,
    GetSkillLineInfo = function(i) return { name = "Skill" .. i, rank = i } end,
    GetSkillLineInfoByID = function(id) if id == 45 then return nil end return { name = "S" .. id, rank = id } end,
    GetSelectedSkill = function() return 0 end,
}
function UnitDefenseSkill() return 85, 0 end
function UnitWeaponAttackPower() return 83, 7, 0 end
C_PaperDollInfo = { OffhandHasWeapon = function() return false end }
C_AssistedCombat = { GetNextCastSpell = function() return nil end }
C_Map = { GetBestMapForUnit = function() return 1454 end }
NUM_BAG_SLOTS = 0
