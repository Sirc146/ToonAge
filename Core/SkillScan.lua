-- ToonAge/Core/SkillScan.lua (Anniversary — TBC Classic / Interface 20506)
-- Reads the player's skill lines: weapon skills, professions, secondary skills.
--
-- ─── THE SIDE EFFECT, AND WHY IT IS HANDLED THIS WAY ───────────────────────
--
-- GetSkillLineInfo() only enumerates lines under EXPANDED headers. A player with
-- "Weapon Skills" collapsed — the default for many — is invisible to a plain
-- scan, and the module would silently report "no weapon skills" rather than
-- erroring. Fixing that requires ExpandSkillHeader(), which mutates the
-- player's own skill window.
--
-- So the scan expands what it must, records exactly which headers it touched,
-- and collapses them back. Header indices shift once you expand, so the restore
-- matches on header NAME, captured before the expansion.
--
-- The whole thing runs at most once per SKILL_LINES_CHANGED (and once on first
-- use), never per frame and never during a render loop.
--
-- ─── LOCALE ─────────────────────────────────────────────────────────────────
--
-- Skill and header names are localized. Nothing here classifies by matching an
-- English header name. Grouping is positional (a line belongs to the last header
-- seen above it), and weapon skills are identified by the locale-independent
-- fact that a weapon skill's maximum is exactly playerLevel * 5.
--
-- The one place English names are unavoidable is mapping a profession to its
-- perk data (Data/TBCProfessions.lua). That lookup misses gracefully and says so
-- rather than showing wrong perks.
--
-- UNVERIFIED on 20506 — see /ta dumpme:
--   * GetSkillLineInfo return order (assumed TBC order, documented below)
--   * that ExpandSkillHeader(0) expands all headers
--   * UnitAttackBothHands return shape

local TA = ToonAge
local U  = TA.Utils

local Scan = {}
TA.SkillScan = Scan
TA:RegisterModule("SkillScan", Scan)

-- TBC GetSkillLineInfo(i) returns, in order:
--   skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
--   skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, costType, description
local function ReadLine(i)
    local ok, name, isHeader, isExpanded, rank, tempPoints, modifier, maxRank =
        pcall(GetSkillLineInfo, i)
    if not ok or not name then return nil end
    return {
        index      = i,
        name       = name,
        isHeader   = isHeader and true or false,
        isExpanded = isExpanded and true or false,
        rank       = U.SafeNum(rank),
        tempPoints = U.SafeNum(tempPoints),
        modifier   = U.SafeNum(modifier),
        maxRank    = U.SafeNum(maxRank),
    }
end

local function NumLines()
    if not GetNumSkillLines then return 0 end
    return U.SafeGetNum(GetNumSkillLines)
end

--- Names of every currently-collapsed header.
local function CollapsedHeaderNames()
    local names = {}
    for i = 1, NumLines() do
        local line = ReadLine(i)
        if line and line.isHeader and not line.isExpanded then
            names[#names + 1] = line.name
        end
    end
    return names
end

--- Re-collapse headers by name. Indices moved during expansion, so we look each
--- one up again rather than trusting the index we saw before.
local function RestoreCollapsed(names)
    if #names == 0 or not CollapseSkillHeader then return end
    for _, wanted in ipairs(names) do
        for i = 1, NumLines() do
            local line = ReadLine(i)
            if line and line.isHeader and line.name == wanted and line.isExpanded then
                pcall(CollapseSkillHeader, i)
                break
            end
        end
    end
end

-- ─── THE SCAN ───────────────────────────────────────────────────────────────

Scan.cache = nil

--- @return table {groups = {[headerName] = {lines}}, order = {headerNames},
---                weapons = {lines}, weaponHeader = string|nil,
---                all = {lines}, expandedSomething = boolean}
function Scan:Scan(force)
    if self.cache and not force then return self.cache end

    if NumLines() == 0 then
        -- The skill list is genuinely empty (or the API is missing). Do not
        -- cache — a fresh login can report 0 before data arrives.
        return { groups = {}, order = {}, weapons = {}, all = {}, empty = true }
    end

    local collapsed = CollapsedHeaderNames()
    local expandedSomething = false
    if #collapsed > 0 and ExpandSkillHeader then
        local ok = pcall(ExpandSkillHeader, 0)
        expandedSomething = ok
    end

    local result = {
        groups = {}, order = {}, all = {}, weapons = {},
        expandedSomething = expandedSomething,
    }

    local currentHeader = nil
    for i = 1, NumLines() do
        local line = ReadLine(i)
        if line then
            if line.isHeader then
                currentHeader = line.name
                if not result.groups[currentHeader] then
                    result.groups[currentHeader] = {}
                    result.order[#result.order + 1] = currentHeader
                end
            else
                line.header = currentHeader or "?"
                if not result.groups[line.header] then
                    result.groups[line.header] = {}
                    result.order[#result.order + 1] = line.header
                end
                table.insert(result.groups[line.header], line)
                table.insert(result.all, line)
            end
        end
    end

    if expandedSomething then
        RestoreCollapsed(collapsed)
    end

    -- ── Identifying the weapon group ────────────────────────────────────
    -- A weapon skill's ceiling is exactly playerLevel * 5. That alone is not
    -- enough to identify the group, because at the levels where level*5 lands
    -- on 75 / 150 / 225 / 300 / 375 it collides with the profession tier caps,
    -- and 300 is also where Languages and Riding sit. At level 60 a caster with
    -- two languages and one weapon skill would have the Languages header chosen
    -- as "the weapon group", and their real weapon skills would then be
    -- reported as professions.
    --
    -- So: anchor on the weapon actually equipped. Its subtype maps to a skill
    -- line name, that line's header IS the weapon group, and no counting is
    -- involved. The count heuristic is kept only for the unarmed case.
    local levelCap = U.GetPlayerLevel() * 5

    -- NOTE: eq.mainSubType/offSubType come from U.GetItemInfo, a bare
    -- GetItemInfo passthrough with no cache-miss retry (Utils.lua). On a cold
    -- item cache — e.g. this scan firing from the very first SKILL_LINES_CHANGED
    -- right after login, before the client has cached the equipped weapon's
    -- item data — GetItemInfo returns nil and anchorName silently resolves to
    -- nil here, falling through to the count-heuristic below. The result then
    -- gets written to Scan.cache and stays wrong for the rest of the session
    -- unless SKILL_LINES_CHANGED or PLAYER_LEVEL_UP fires again to invalidate it.
    local anchorName
    local eq = self:GetEquippedWeaponSkill()
    local subToSkill = (TA.Data and TA.Data.SubTypeToSkill) or {}
    anchorName = (eq.mainSubType and subToSkill[eq.mainSubType])
              or (eq.offSubType  and subToSkill[eq.offSubType])

    local best
    if anchorName then
        for _, line in ipairs(result.all) do
            if line.name == anchorName then
                best = line.header
                result.weaponHeaderSource = "anchored on your equipped weapon"
                break
            end
        end
    end

    if not best then
        local bestCount = 0
        for header, lines in pairs(result.groups) do
            local n = 0
            for _, line in ipairs(lines) do
                if line.maxRank == levelCap then n = n + 1 end
            end
            if n > bestCount then best, bestCount = header, n end
        end
        if best then
            result.weaponHeaderSource = "guessed from skill ceilings — no weapon equipped"
        end
    end

    if best then
        result.weaponHeader = best
        for _, line in ipairs(result.groups[best]) do
            if line.maxRank == levelCap then
                table.insert(result.weapons, line)
            end
        end
    end

    table.sort(result.weapons, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.name < b.name
    end)

    self.cache = result
    return result
end

-- ─── EQUIPPED WEAPON SKILL ──────────────────────────────────────────────────

--- Skill of the weapons actually in your hands. No side effects — this does not
--- touch the skill window at all, so it is the reliable path even if the scan
--- above comes back empty.
--- @return table {main = {base, mod, total}, off = {...}|nil, dualWield = bool}
function Scan:GetEquippedWeaponSkill()
    local out = { dualWield = false }

    if UnitAttackBothHands then
        local ok, mainBase, mainMod, offBase, offMod = pcall(UnitAttackBothHands, "player")
        if ok then
            mainBase, mainMod = U.SafeNum(mainBase), U.SafeNum(mainMod)
            offBase,  offMod  = U.SafeNum(offBase),  U.SafeNum(offMod)
            if mainBase > 0 then
                out.main = { base = mainBase, mod = mainMod, total = mainBase + mainMod }
            end
            if offBase > 0 then
                out.off = { base = offBase, mod = offMod, total = offBase + offMod }
                out.dualWield = true
            end
        end
    end

    -- Confirm dual wield from the equipped items too: an off-hand weapon that
    -- shares the main hand's skill line reports 0 above on some builds.
    local offLink = GetInventoryItemLink and GetInventoryItemLink("player", 17)
    if offLink then
        local _, _, _, _, _, itemType, itemSubType = U.GetItemInfo(offLink)
        if itemType and itemType == "Weapon" then
            out.dualWield = true
        end
        out.offSubType = itemSubType
    end

    local mainLink = GetInventoryItemLink and GetInventoryItemLink("player", 16)
    if mainLink then
        local _, _, _, _, _, _, itemSubType = U.GetItemInfo(mainLink)
        out.mainSubType = itemSubType
    end

    return out
end

--- The weapon skill to use for cap maths: whatever is in the main hand, or the
--- level cap if we cannot tell (which makes caps read as the best case rather
--- than inventing a deficit that may not exist).
--- @return number skill, boolean measured
function Scan:GetActiveWeaponSkill()
    local eq = self:GetEquippedWeaponSkill()
    if eq.main and eq.main.total > 0 then
        return eq.main.total, true
    end
    return U.GetPlayerLevel() * 5, false
end

-- ─── PROFESSIONS ────────────────────────────────────────────────────────────
-- GetProfessions() does not exist in TBC (it arrived in 3.0), so professions
-- come from the same skill scan. Primary professions are the group that is not
-- the weapon group and whose lines cap at a multiple of 75.

-- ─── WHY THIS IS A WHITELIST AND NOT A HEURISTIC ───────────────────────────
--
-- The first version of this function took every non-weapon skill line whose
-- maxRank was 75/150/225/300/375. That set is not specific to professions, and
-- on a real character it over-collects badly:
--
--   * Riding caps at 75 / 150 / 225 / 300 depending on your rank — so every
--     character past level 40 would list "Riding" as a profession.
--   * Languages cap at 300. Common, Orcish, Thalassian, Draenei, Gutterspeak —
--     all of them would have been listed too.
--   * Defense and Lockpicking cap at playerLevel * 5, which lands exactly on
--     150 / 225 / 300 at levels 30 / 45 / 60.
--
-- So a level 60 Human rogue with two professions would have shown roughly nine
-- "professions", and the perk lookup would have missed on most of them — the
-- tab would have looked broken while being perfectly self-consistent.
--
-- The fix is a whitelist: the twelve names in Data/TBCProfessions.lua ARE the
-- professions, and anything else is not one. That trades locale independence
-- for correctness, which is the right trade here — a wrong list is worse than
-- an empty one, and the miss is reported rather than silent.

--- @return table professions, table unmatched
--- `professions` is the whitelist matches, primaries before secondaries.
--- `unmatched` holds profession-shaped lines whose names are not recognised —
--- the signature of a non-English client. Reported by the tab, never guessed at.
function Scan:GetProfessions()
    local scan = self:Scan()
    local known = (TA.Data and TA.Data.Professions) or {}
    local levelCap = U.GetPlayerLevel() * 5
    local PROFESSION_CAPS = { [75]=true, [150]=true, [225]=true, [300]=true, [375]=true }

    local out, unmatched = {}, {}

    for _, line in ipairs(scan.all or {}) do
        local entry = known[line.name]
        if entry then
            line.tier = entry.tier
            line.isSecondary = (entry.tier == "secondary")
            table.insert(out, line)
        elseif line.header ~= scan.weaponHeader
           and PROFESSION_CAPS[line.maxRank]
           and line.maxRank ~= levelCap then
            -- Shaped like a profession but not a name we know. Riding and
            -- languages also land here; the tab says "unrecognised" rather than
            -- presenting them as professions.
            table.insert(unmatched, line)
        end
    end

    -- Primaries first, then secondaries; alphabetical inside each group so the
    -- list does not reshuffle every time a skill point ticks up.
    table.sort(out, function(a, b)
        if a.isSecondary ~= b.isSecondary then return not a.isSecondary end
        return a.name < b.name
    end)

    return out, unmatched
end

function Scan:Init()
    -- Nothing to do at login; the first Render triggers the scan. Deferring
    -- keeps the skill-window expand/restore out of the login sequence, where a
    -- half-loaded skill list would produce a wrong cache.
end

function Scan:OnEvent(event)
    if event == "SKILL_LINES_CHANGED" or event == "PLAYER_LEVEL_UP" then
        self.cache = nil
    end
end
