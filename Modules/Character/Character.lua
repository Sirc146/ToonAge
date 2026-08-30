-- ToonAge/Modules/Character/Character.lua (Anniversary — TBC Classic / 20506)
-- The TBC stat breakdown: attributes, attack power, spell power, Mp5, avoidance,
-- resistances, and where your talent points went.
--

-- ─── WHAT WAS REMOVED FROM THE MoP VERSION AND WHY ───────────────────────────

--
-- The _classic_ build's Character tab opens UpdateData() with
--   local specID = U.GetPlayerSpec(); if not specID then return end
-- GetSpecialization() does not exist in TBC, so on this client that tab would
-- draw an empty panel and never say why — a silent blank, not an error. Nothing
-- in this file may branch on a spec ID.
--
-- Also gone: Mastery (added in Cataclysm) and Versatility (Warlords). Neither
-- stat exists here, and a row reading "Mastery 0.00%" is worse than no row.
--
-- Added, per the brief: Attack Power, Spell Power by school, Mp5 (split into the
-- while-casting and while-not-casting halves that TBC actually distinguishes),
-- Spirit, and resistances.
--
-- Every read goes through U.SafeGetNum, which reports whether the API answered
-- at all. A stat the client cannot supply is shown as "n/a" rather than 0 —
-- zero is a claim, and it would be a false one.

local TA = ToonAge
local U  = TA.Utils
local L  = TA.Layout

local M = {}
TA:RegisterModule("Character", M)

-- ─── READS ───────────────────────────────────────────────────────────────────

local STAT_INDEX = { STR = 1, AGI = 2, STA = 3, INT = 4, SPI = 5 }
local STAT_ORDER = { "STR", "AGI", "STA", "INT", "SPI" }
local STAT_NAMES = {
    STR = "Strength", AGI = "Agility", STA = "Stamina",
    INT = "Intellect", SPI = "Spirit",
}

--- @return number effective, number base, number buffed, boolean ok
local function ReadStat(key)
    local idx = STAT_INDEX[key]
    if not idx or not UnitStat then return 0, 0, 0, false end
    local ok, base, effective, posBuff, negBuff = pcall(UnitStat, "player", idx)
    if not ok then return 0, 0, 0, false end
    base      = U.SafeNum(base)
    effective = U.SafeNum(effective)
    posBuff   = U.SafeNum(posBuff)
    negBuff   = U.SafeNum(negBuff)
    return effective, base, posBuff + negBuff, true
end

--- Value plus whether the API existed. `nil` means "no answer", not "zero".
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local value, ok = U.SafeGetNum(fn, ...)
    if not ok then return nil end
    return value
end

local function Show(value, formatter)
    if value == nil then return "|cFF806E60n/a|r" end
    return (formatter or U.Rating)(value)
end

-- The seven TBC magic schools, in the order UnitResistance indexes them.
local SCHOOLS = {
    { index = 1, key = "Holy",   label = "Holy"   },
    { index = 2, key = "Fire",   label = "Fire"   },
    { index = 3, key = "Nature", label = "Nature" },
    { index = 4, key = "Frost",  label = "Frost"  },
    { index = 5, key = "Shadow", label = "Shadow" },
    { index = 6, key = "Arcane", label = "Arcane" },
}

-- ─── RENDER ──────────────────────────────────────────────────────────────────

local function RenderHeadline(content, y)
    -- NOTE: U.InferRole() (Core/Utils.lua) only ever returns "HEALER" via a manual
    -- /ta role override. A Holy Paladin, Restoration Druid or Restoration Shaman with
    -- no shield equipped infers as plain "MELEE" by default, so an untalented-looking
    -- healer can get a headline telling them to gear melee hit/expertise instead of
    -- the "no caps apply to you" message a healer should see.
    local role = U.InferRole()
    local caps = TA:GetModule("StatCaps")

    y = L:SectionHeader(content, y, "YOUR TOON RIGHT NOW")

    -- The single most actionable line the addon can produce: the nearest
    -- uncapped cap, or confirmation that there isn't one.
    local headline, status = "Nothing is below a cap — gear for throughput.", "good"

    if caps and caps.Collect then
        local ok, data = pcall(caps.Collect, caps)
        if ok and data then
            if data.noCaps then
                headline = "Healing role: no hit, expertise or defense targets apply to you."
                status = "neutral"
            else
                local worst, worstName, worstUnit
                local order = {
                    { "meleeHit",  "melee hit",  "pct" },
                    { "spellHit",  "spell hit",  "pct" },
                    { "defense",   "defense",    "points" },
                    { "expertise", "expertise",  "points" },
                }
                for _, entry in ipairs(order) do
                    local cap = data.caps[entry[1]]
                    if cap and not cap.capped and cap.needed > 0 then
                        worst, worstName, worstUnit = cap, entry[2], entry[3]
                        break
                    end
                end
                if worst then
                    headline = string.format("Priority: %s more %s to cap against %s.",
                        worstUnit == "pct" and U.Pct(worst.needed) or tostring(worst.needed),
                        worstName, data.context.label:lower())
                    status = "warn"
                end
            end
        end
    end

    y = L:Paragraph(content, y, headline, { color = L.STATUS[status], size = 11 })
    y = L:Paragraph(content, y,
        string.format("Role read as %s. |cFF555049/ta role to change it, /ta caps for detail.|r", role))
    return L:Spacer(y, 6)
end

local function RenderAttributes(content, y)
    y = L:SectionHeader(content, y, "ATTRIBUTES")

    for _, key in ipairs(STAT_ORDER) do
        local effective, base, buff, ok = ReadStat(key)
        local note
        if ok and buff ~= 0 then
            note = string.format("%d base %s %d from buffs and gear",
                base, buff >= 0 and "+" or "-", math.abs(buff))
        end
        y = L:DataRow(content, y, {
            label  = STAT_NAMES[key],
            value  = ok and U.Rating(effective) or "|cFF806E60n/a|r",
            bold   = true,
            status = "neutral",
            note   = note,
        })
    end

    local hp   = Try(UnitHealthMax, "player")
    local mana = Try(UnitManaMax, "player") or Try(UnitPowerMax, "player", 0)

    y = L:DataRow(content, y, { label = "Health", value = Show(hp, U.FormatNumber), status = "neutral" })
    if mana and mana > 0 then
        y = L:DataRow(content, y, { label = "Mana", value = Show(mana, U.FormatNumber), status = "neutral" })
    end

    return L:Spacer(y, 6)
end

local function RenderOffense(content, y, role)
    y = L:SectionHeader(content, y, "OFFENSE")

    -- ── Melee / ranged ────────────────────────────────────────────────
    if role ~= "CASTER" and role ~= "HEALER" then
        local apBase, apPos, apNeg
        if UnitAttackPower then
            local ok, b, p, n = pcall(UnitAttackPower, "player")
            if ok then apBase, apPos, apNeg = U.SafeNum(b), U.SafeNum(p), U.SafeNum(n) end
        end
        if apBase then
            y = L:DataRow(content, y, {
                label = "Attack Power", value = U.Rating(apBase + apPos + apNeg), bold = true,
                note = string.format("%d base, %+d from buffs and gear", apBase, apPos + apNeg),
            })
        end

        if role == "RANGED" and UnitRangedAttackPower then
            local ok, b, p, n = pcall(UnitRangedAttackPower, "player")
            if ok then
                y = L:DataRow(content, y, {
                    label = "Ranged Attack Power",
                    value = U.Rating(U.SafeNum(b) + U.SafeNum(p) + U.SafeNum(n)), bold = true,
                })
            end
        end

        -- WARN: classic Lua ternary trap. If Try(GetRangedCritChance) ever answers nil
        -- (API missing or the pcall inside SafeGetNum fails), `a and b or c` falls
        -- through to Try(GetCritChance) even though role == "RANGED" — the label below
        -- still reads "Ranged Crit" but the value shown would silently be melee crit.
        local crit = (role == "RANGED") and Try(GetRangedCritChance) or Try(GetCritChance)
        y = L:DataRow(content, y, {
            label = (role == "RANGED") and "Ranged Crit" or "Melee Crit",
            value = Show(crit, U.Pct),
            note = "TBC has no crit-depression mechanic to plan around, but hit and "
                .. "expertise both rank above crit until they are capped.",
        })

        local haste = Try(GetMeleeHaste) or Try(GetHaste)
        if haste then
            y = L:DataRow(content, y, { label = "Melee Haste", value = U.Pct(haste) })
        end
    end

    -- ── Spell ─────────────────────────────────────────────────────────
    if role == "CASTER" or role == "HEALER" then
        if GetSpellBonusDamage then
            local best, bestSchool = -1, nil
            local lines = {}
            for _, school in ipairs(SCHOOLS) do
                local v = Try(GetSpellBonusDamage, school.index)
                if v then
                    lines[#lines + 1] = { label = school.label, value = v }
                    if v > best then best, bestSchool = v, school.label end
                end
            end

            if bestSchool then
                y = L:DataRow(content, y, {
                    label = "Spell Power", value = U.Rating(best), bold = true,
                    note = "Highest school: " .. bestSchool
                        .. ". TBC reports spell power per school — an item that only boosts "
                        .. "one school is worth nothing to a spell of another.",
                })
                for _, entry in ipairs(lines) do
                    if entry.value ~= best then
                        y = L:DataRow(content, y, {
                            label = "  " .. entry.label, value = U.Rating(entry.value),
                            status = "dim",
                        })
                    end
                end
            end
        end

        local healing = Try(GetSpellBonusHealing)
        if healing and healing > 0 then
            y = L:DataRow(content, y, {
                label = "Healing Power", value = U.Rating(healing), bold = (role == "HEALER"),
            })
        end

        -- Spell crit is per-school in TBC. Reading one school hardcoded would
        -- show a Fire mage their Holy crit; take the highest instead and name it.
        local bestCrit, bestCritSchool
        for _, school in ipairs(SCHOOLS) do
            local v = Try(GetSpellCritChance, school.index)
            if v and (not bestCrit or v > bestCrit) then
                bestCrit, bestCritSchool = v, school.label
            end
        end
        y = L:DataRow(content, y, {
            label = "Spell Crit", value = Show(bestCrit, U.Pct),
            note = bestCritSchool and ("Highest school: " .. bestCritSchool
                .. ". Crit is reported per school, so this is your best one, not an average.") or nil,
        })

        -- ── Mp5. TBC splits regen into "while not casting" and "while casting",
        --    and gear-granted Mp5 is the part that continues through a cast.
        --    Reporting one combined number hides the distinction that decides
        --    whether Spirit or Mp5 is the better stat for a given spec.
        if GetManaRegen then
            local ok, notCasting, whileCasting = pcall(GetManaRegen)
            if ok then
                notCasting   = U.SafeNum(notCasting) * 5
                whileCasting = U.SafeNum(whileCasting) * 5
                y = L:DataRow(content, y, {
                    label = "Mana per 5s (casting)", value = U.Rating(whileCasting), bold = true,
                    note = string.format("%d while not casting. The casting number is the one "
                        .. "that matters in a fight — Spirit only feeds the other half unless "
                        .. "a talent converts it.", notCasting),
                })
            end
        end
    end

    return L:Spacer(y, 6)
end

local function RenderDefense(content, y, role)
    y = L:SectionHeader(content, y, "DEFENSE")

    local armorBase, effArmor
    if UnitArmor then
        local ok, b, e = pcall(UnitArmor, "player")
        if ok then armorBase, effArmor = U.SafeNum(b), U.SafeNum(e) end
    end
    if effArmor then
        local S = TA.TBCStats
        local ctx = S:ActiveContext()
        local reduction = S:ArmorReduction(effArmor, U.GetPlayerLevel() + ctx.delta)
        y = L:DataRow(content, y, {
            label = "Armor", value = U.FormatNumber(effArmor), bold = true,
            note = string.format("%s physical damage reduction against a level %d attacker.",
                U.Pct(reduction), U.GetPlayerLevel() + ctx.delta),
        })
    end

    y = L:DataRow(content, y, { label = "Dodge",  value = Show(Try(GetDodgeChance), U.Pct) })
    y = L:DataRow(content, y, { label = "Parry",  value = Show(Try(GetParryChance), U.Pct) })

    local block = Try(GetBlockChance)
    if block and block > 0 then
        y = L:DataRow(content, y, { label = "Block", value = U.Pct(block),
            note = "Block value " .. Show(Try(GetShieldBlock), U.Rating) })
    end

    local defTotal, defBase, defRating = TA.TBCStats:GetDefenseSkill()
    y = L:DataRow(content, y, {
        label = "Defense skill", value = U.Rating(defTotal),
        bold = (role == "TANK"),
        note = string.format("%d from level, +%d from defense rating.", defBase, defRating),
    })

    -- Resistances only earn their space when you actually have some.
    local resistRows = {}
    if UnitResistance then
        for _, school in ipairs(SCHOOLS) do
            local ok, base = pcall(UnitResistance, "player", school.index)
            local value = ok and U.SafeNum(base) or 0
            if value > 0 then
                resistRows[#resistRows + 1] = { label = school.label, value = value }
            end
        end
    end
    if #resistRows > 0 then
        y = L:Spacer(y, 4)
        local parts = {}
        for _, r in ipairs(resistRows) do
            parts[#parts + 1] = string.format("%s %d", r.label, r.value)
        end
        y = L:DataRow(content, y, {
            label = "Resistances", value = "", status = "dim",
            note = table.concat(parts, "   "),
        })
    end

    return L:Spacer(y, 6)
end

local function RenderTalents(content, y)
    local specName, points, trees, total = U.GetTalentSummary()

    y = L:SectionHeader(content, y, "TALENTS",
        string.format("%d points spent. TBC gives 61 by level 70, and a respec costs gold "
            .. "that climbs each time — this is a commitment, not a loadout.", total or 0))

    if not trees or #trees == 0 then
        y = L:Paragraph(content, y,
            "Talent tabs could not be read on this client.", { color = L.C_WARNING })
        return L:Spacer(y, 6)
    end

    for _, tree in ipairs(trees) do
        local isMain = specName and tree.name == specName
        y = L:DataRow(content, y, {
            label  = tree.name .. (isMain and "  |cFFFFD100● main|r" or ""),
            value  = tostring(tree.points),
            bold   = isMain,
            status = isMain and "neutral" or "dim",
        })
    end

    if not specName and (total or 0) > 0 then
        y = L:Paragraph(content, y,
            "No tree has enough points to call a specialisation yet. This addon infers "
            .. "your role from class and gear until one does.")
    end

    return L:Spacer(y, 6)
end

function M:Render(content, side)
    L:CharacterSidebar(side)

    local role = U.InferRole()
    local y = -8

    y = RenderHeadline(content, y)
    y = L:Divider(content, y)
    y = RenderAttributes(content, y)
    y = L:Divider(content, y)
    y = RenderOffense(content, y, role)
    y = L:Divider(content, y)
    y = RenderDefense(content, y, role)
    y = L:Divider(content, y)
    y = RenderTalents(content, y)

    L:Finish(content, y)
end
