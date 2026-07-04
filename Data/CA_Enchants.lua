-- CharacterAdvisor/Data/CA_Enchants.lua
-- Midnight Expansion enchant → profession mapping.
-- Keys are the enchantID field from the item link (item:id:enchantID:...).
-- spellID is the crafting spell checked with IsSpellKnown() to verify recipe ownership.

local CA = CharacterAdvisor
CA.Data = CA.Data or {}

CA.Data.EnchantProfessionMap = {
    -- ── Weapon Enchants ───────────────────────────────────────────────
    [74001] = { profession = "ENCHANTING", name = "Authority of the Depths",    spellID = 445001 },
    [74002] = { profession = "ENCHANTING", name = "Acuity of the Ren'dorei",    spellID = 445002 },
    [74003] = { profession = "ENCHANTING", name = "Arcane Mastery",              spellID = 445003 },
    [74004] = { profession = "ENCHANTING", name = "Berserker's Rage",            spellID = 445004 },
    [74005] = { profession = "ENCHANTING", name = "Flames of the Sin'dorei",    spellID = 445005 },
    -- ── Helm & Shoulder Enchants ──────────────────────────────────────
    [74101] = { profession = "ENCHANTING", name = "Empowered Hex of Leeching",  spellID = 445101 },
    [74102] = { profession = "ENCHANTING", name = "Empowered Rune of Avoidance", spellID = 445102 },
    [74201] = { profession = "ENCHANTING", name = "Akil'zon's Swiftness",       spellID = 445201 },
    [74202] = { profession = "ENCHANTING", name = "Amirdrassil's Grace",        spellID = 445202 },
    [74203] = { profession = "ENCHANTING", name = "Silvermoon's Mending",       spellID = 445203 },
    -- ── Ring Enchants ─────────────────────────────────────────────────
    [74301] = { profession = "ENCHANTING", name = "Amani Mastery",              spellID = 445301 },
    [74302] = { profession = "ENCHANTING", name = "Silvermoon's Alacrity",      spellID = 445302 },
    [74303] = { profession = "ENCHANTING", name = "Thalassian Versatility",     spellID = 445303 },
    [74304] = { profession = "ENCHANTING", name = "Nature's Fury",              spellID = 445304 },
    -- ── Engineering Scopes ────────────────────────────────────────────
    [74401] = { profession = "ENGINEERING", name = "Smuggler's Lynxeye Scope",  spellID = 445401 },
}
