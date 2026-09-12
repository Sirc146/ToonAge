-- ToonAge/Data/TBCArmor.lua (Anniversary — TBC Classic / 20506)
-- Armor type by class, and the level-40 switch.
--
-- ══════════════════════════════════════════════════════════════════════════════
-- ── WHY THIS TABLE IS SMALL ───────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Nine classes, one armor type each, one switch in the whole game. That is short
-- enough to be confident about and short enough to check by eye, which is the
-- only reason it is hardcoded at all — the cross-class weapon proficiency table
-- from the same source was not, because it was long, and six of its nine entries
-- were wrong.
--
-- The valuable part is not the table. It is that Hunters and Shamans go from
-- Leather to Mail at level 40 and NOBODY TELLS THEM. There is no quest, no
-- popup, no highlight — the trainer just starts offering it. Players routinely
-- run around at level 45 still wearing the leather they levelled in, giving up
-- a large amount of armor for free.
--
-- That is checkable: compare each equipped piece's subtype (GetItemInfo return
-- 7) against what the class can wear at its current level. Everything in this
-- file exists to support that one check.
--
-- Armor subtype strings are English, matching GetItemInfo. Callers that miss
-- report the miss rather than assuming the piece is wrong.

local TA = ToonAge
TA.Data = TA.Data or {}

TA.Data.MAIL_UNLOCK_LEVEL = 40

TA.Data.ClassArmor = {
    WARRIOR = { final = "Plate",   from = 1,  early = "Plate",
                note = "Plate from level one. No switch, and no armor spike to wait for." },
    PALADIN = { final = "Plate",   from = 1,  early = "Plate",
                note = "Plate from level one. No switch." },
    HUNTER  = { final = "Mail",    from = 40, early = "Leather",
                note = "Leather until 40, then Mail. This is a large, silent survivability "
                    .. "jump that the game never announces." },
    SHAMAN  = { final = "Mail",    from = 40, early = "Leather",
                note = "Leather until 40, then Mail. The same silent jump as Hunters." },
    ROGUE   = { final = "Leather", from = 1,  early = "Leather",
                note = "Leather throughout. Survivability comes from avoidance and control, "
                    .. "not from armor." },
    DRUID   = { final = "Leather", from = 1,  early = "Leather",
                note = "Leather throughout, but forms carry their own armor multipliers — "
                    .. "Bear reaches plate-equivalent mitigation." },
    MAGE    = { final = "Cloth",   from = 1,  early = "Cloth",
                note = "Cloth throughout. Defence is shields, slows and range." },
    PRIEST  = { final = "Cloth",   from = 1,  early = "Cloth",
                note = "Cloth throughout. Defence is shields and dispels." },
    WARLOCK = { final = "Cloth",   from = 1,  early = "Cloth",
                note = "Cloth throughout. Defence is the pet, drains and fear." },
}

-- Armor subtypes a class can equip, in ascending weight. A class can always wear
-- everything lighter than its own type.
local WEIGHT_ORDER = { "Cloth", "Leather", "Mail", "Plate" }

TA.Data.ArmorWeightOrder = WEIGHT_ORDER

--- The best armor type this class can wear at this level.
--- @return string|nil best, boolean switchPending, number|nil switchLevel
function TA.Data.BestArmorFor(class, level)
    local entry = TA.Data.ClassArmor[class]
    if not entry then return nil, false, nil end

    if level >= entry.from then
        return entry.final, false, nil
    end
    return entry.early, true, entry.from
end

--- Is `subType` lighter than `best`? Slots are only flagged when a strictly
--- better armor class is available — a cloak or a ring reports "Miscellaneous"
--- and must never be flagged.
--- @return boolean
function TA.Data.IsLighterArmor(subType, best)
    local rankOf = {}
    for i, name in ipairs(WEIGHT_ORDER) do rankOf[name] = i end

    local a, b = rankOf[subType], rankOf[best]
    if not a or not b then return false end   -- not an armor class we track
    return a < b
end
