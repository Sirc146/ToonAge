-- ToonAge/Modules/Harvest/Packs/Forever.lua  (harvest pack: WoW Forever)
--
-- Forever is Vanilla content on Midnight's API, and no outside source has
-- numbers for it. Wowhead, Icy Veins and the theorycrafting sites all cover
-- Retail or Classic Era; none of them describe this game. Copying Vanilla
-- values across would produce advice that LOOKS researched and is quietly
-- wrong, which is worse than the honest "n/a" the Character tab prints today.
-- So the client is the only source, and the player is the only instrument.
--
-- This pack says what Forever records and how its Harvest tab reads
-- (Docs/SPEC_HARVEST_SENSOR_ARRAY.md section 4.4): which domains run, the
-- order of the Copy row, the summary, the probe report and the Full report,
-- the spell-ID ranges the catalog walks, Forever's own probes (R6: the
-- Comprehension and scroll probes, the C_SkillInfo skill lines) and its World
-- refresh row, and one store repair. It replaces Modules/Forever/
-- DataHarvester.lua (T4); only ToonAge_Camelot.toc lists it.
--
-- HOW THE DATA GETS OUT: the saved file is the primary path --
--   <WoW>\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables\ToonAge.lua
-- written when you log out or /reload. The Copy buttons on the Harvest tab are
-- the fallback; Tools/export_harvest.lua turns the saved file into the same
-- stamped text.

local TA = ToonAge
local Hv, Caps = TA.Harvester, TA.Caps

local IsSecret = Hv.IsSecret

-- ── Probes only Forever runs ──────────────────────────────────────────────

local probes = {}

probes.professions = { title = "Professions and skills", run = function(P, L)
    local getProfessions = Caps.Fn("GetProfessions")
    local slots = getProfessions and { pcall(getProfessions) } or { false }
    if slots[1] then
        for i = 2, 7 do
            if slots[i] then P.Call(L, "GetProfessionInfo(" .. tostring(slots[i]) .. ")", "GetProfessionInfo", slots[i]) end
        end
    else
        L[#L + 1] = "GetProfessions()  ->  " .. (getProfessions and "error" or "missing")
    end
    P.Call(L, "C_TradeSkillUI.GetProfessionInfoBySkillLineID(3012) [Comprehension]",
        "C_TradeSkillUI.GetProfessionInfoBySkillLineID", 3012)
    P.Call(L, "IsSpellKnown(1296017) [Comprehend Scroll]", "IsSpellKnown", 1296017)
    P.Call(L, "C_SpellBook.GetNumSpellBookSkillLines()", "C_SpellBook.GetNumSpellBookSkillLines")
    local getLines = Caps.Fn("C_SpellBook.GetNumSpellBookSkillLines")
    local okN, n = false, nil
    if getLines then okN, n = pcall(getLines) end
    if okN and type(n) == "number" and not IsSecret(n) then
        local getInfo = Caps.Fn("C_SpellBook.GetSpellBookSkillLineInfo")
        for i = 1, math.min(n, 12) do
            local ok, info = false, nil
            if getInfo then ok, info = pcall(getInfo, i) end
            L[#L + 1] = ("  skill line %d  ->  %s"):format(i,
                ok and type(info) == "table" and P.Show(info.name) or "n/a")
        end
    end
end }

probes.skillinfo = { title = "Skill lines: C_SkillInfo", run = function(P, L)
    -- FOUND 2026-09-28 by the API-discovery probe on a level 1 Hunter: the
    -- classic skill globals are gone, but C_SkillInfo carries their modern
    -- replacements, and UnitDefenseSkill / UnitWeaponAttackPower stand in for
    -- UnitDefense / UnitAttackBothHands (the client's own PaperDollFrame_SetDefense
    -- and PaperDollFrame_SetWeaponSkill exist, so the sheet reads them somehow).
    -- This records the exact return shapes before any tab is built on them.
    P.Call(L, "C_SkillInfo.GetNumSkillLines()", "C_SkillInfo.GetNumSkillLines")
    local getNum = Caps.Fn("C_SkillInfo.GetNumSkillLines")
    local okSI, nSI = false, nil
    if getNum then okSI, nSI = pcall(getNum) end
    if okSI and type(nSI) == "number" and not IsSecret(nSI) then
        for i = 1, math.min(nSI, 40) do
            P.Call(L, ("  C_SkillInfo.GetSkillLineInfo(%d)"):format(i), "C_SkillInfo.GetSkillLineInfo", i)
        end
    end
    P.Call(L, "C_SkillInfo.GetSkillLineInfoByID(95) [Defense]", "C_SkillInfo.GetSkillLineInfoByID", 95)
    P.Call(L, "C_SkillInfo.GetSkillLineInfoByID(45) [Bows]", "C_SkillInfo.GetSkillLineInfoByID", 45)
    P.Call(L, "C_SkillInfo.GetSkillLineInfoByID(43) [Swords]", "C_SkillInfo.GetSkillLineInfoByID", 43)
    P.Call(L, "C_SkillInfo.GetSelectedSkill()", "C_SkillInfo.GetSelectedSkill")
    P.Call(L, "UnitDefenseSkill(player)", "UnitDefenseSkill", "player")
    P.Call(L, "UnitWeaponAttackPower(player)", "UnitWeaponAttackPower", "player")
    P.Call(L, "C_PaperDollInfo.OffhandHasWeapon()", "C_PaperDollInfo.OffhandHasWeapon")
end }

probes.scrolls = { title = "Scroll tooltips in your bags", run = function(P, L)
    local found = 0
    local lastBag = tonumber((Caps.Get("NUM_TOTAL_EQUIPPED_BAG_SLOTS")))
        or tonumber((Caps.Get("NUM_BAG_SLOTS"))) or 4
    local U = TA.Utils
    local getLink = Caps.Fn("C_TooltipInfo.GetHyperlink")
    for bag = 0, lastBag do
        local slots2 = U.SafeNum(U.GetContainerNumSlots(bag), 0)
        for slot = 1, slots2 do
            local link = U.GetContainerItemLink(bag, slot)
            if link and not IsSecret(link) and link:lower():find("scroll", 1, true) and found < 5 then
                found = found + 1
                L[#L + 1] = link:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                local ok, data = false, nil
                if getLink then ok, data = pcall(getLink, link) end
                if ok and type(data) == "table" and type(data.lines) == "table" then
                    for i, ln in ipairs(data.lines) do
                        L[#L + 1] = ("  %d: %s"):format(i, P.Show(type(ln) == "table" and ln.leftText or nil))
                    end
                else
                    L[#L + 1] = "  C_TooltipInfo.GetHyperlink  ->  " .. (ok and "no lines" or "missing or error")
                end
            end
        end
    end
    if found == 0 then L[#L + 1] = "(no item with \"Scroll\" in its name in your bags)" end
end }

-- ── Repair (one time) ─────────────────────────────────────────────────────
-- 2026-10-04 17:23: a catalog scan run from a Mage session dropped 8 stored
-- ranks whose text that session had not loaded (the scan then started from an
-- empty catalog; since T4 it never removes a rank). These lines are the
-- records as the client wrote them on build 70205, read back from the saved
-- file of 2026-10-04 17:21:36. Each is added only if missing, and only on the
-- build they were measured on.
local LOST_CATALOG_70205 = {
    ["78"]   = "Heroic Strike\tRank 1\t1",
    ["100"]  = "Charge\tRank 1\t4",
    ["772"]  = "Rend\tRank 1\t4",
    ["1244"] = "Power Word: Fortitude\tRank 2\t12",
    ["6343"] = "Thunder Clap\tRank 1\t6",
    ["6673"] = "Battle Shout\tRank 1\t1",
    ["8091"] = "Armor\tRank 1\t10",
    ["8112"] = "Spirit\tRank 1\t10",
}

local function Repair(s)
    if s.catalogRepair then return end
    local build = s.client and s.client.build
    if tostring(build) ~= "70205" and tostring(s.catalogBuild) ~= "70205" then return end
    local merged, added = {}, 0
    for k, line in pairs(s.catalog or {}) do merged[k] = line end
    for k, line in pairs(LOST_CATALOG_70205) do
        if merged[k] == nil then merged[k] = line; added = added + 1 end
    end
    if added > 0 then
        -- A new table, so the Spells tab's cached catalog rebuilds.
        s.catalog = merged
        Hv:AdoptSection("catalog", merged)
        Hv:Touch("catalog")
    end
    s.catalogRepair = ("2026-10-04 lost ranks: +%d"):format(added)
end

-- ── The pack ──────────────────────────────────────────────────────────────

Hv:RegisterPack{
    client  = "forever",
    -- No legacy talent trees: Forever has no GetNumTalentTabs (measured).
    domains = { "character", "items", "spellbook", "racials", "traitTree", "trainer" },

    exportOrder    = { "items", "spells", "talents", "chars", "racials", "trainer", "trainerProf", "catalog" },
    summaryOrder   = { "items", "spells", "talents", "chars", "racials", "trainer", "trainerProf", "catalog" },
    reportTitle    = "ToonAge Forever -- full report",
    reportSections = { "items", "spells", "talents", "chars", "racials" },

    -- Vanilla IDs, the Season of Discovery block Forever reuses (Penance
    -- 402174, Divine Aegis 431622), and Forever's own (1259xxx racials,
    -- 1293xxx, 1309950).
    catalogRanges = { { 1, 60000 }, { 400000, 440000 }, { 1220000, 1330000 } },

    probeOrder = { "client", "professions", "professionLines", "sheet", "skillinfo",
                   "talentGeometry", "spellRanks", "combat", "map", "scrolls" },
    probes = probes,
    probesBlurb = "Runs every open check from the Forever brief -- professions and "
        .. "Comprehension, weapon skill, spell power, combat recording, scroll "
        .. "tooltips -- and opens the results in a copyable window.",

    tabRows = function(L, content, y)
        y = L:Divider(content, y)
        y = L:SectionHeader(content, y, "World refresh")
        y = L:Paragraph(content, y,
            "Every \"world around you will refresh\" notice the beta has shown, with "
            .. "time, zone and the gap between them. Also /ta refreshlog.")
        y = L:ButtonRow(content, y, {
            { label = "World refresh log", onClick = function() TA:SlashCommand("refreshlog") end },
        })
        return y
    end,

    repair = Repair,

    -- Skill lines for Scan now. No skill-line id is invented: a missing id
    -- stays blank. The classic walker is only the fallback.
    scanSkills = function()
        local Try, Clean = Hv.Try, Hv.Clean
        local rows = {}
        local n = tonumber((Try("C_SkillInfo.GetNumSkillLines")))
        if n and n > 0 then
            for i = 1, n do
                local info = Try("C_SkillInfo.GetSkillLineInfo", i)
                if type(info) == "table" and type(info.name) == "string"
                    and info.name ~= "" and info.name ~= "secret" and not info.isHeader then
                    local id = info.skillID
                    rows[tostring(id or i)] = table.concat({
                        Clean(info.name), Clean(info.rank), Clean(info.maxRank), Clean(id),
                    }, "\t")
                end
            end
        end
        if not next(rows) then
            local legacy = tonumber((Try("GetNumSkillLines")))
            if legacy and legacy > 0 then
                for i = 1, legacy do
                    local name, isHeader, _, rank, _, _, maxRank = Try("GetSkillLineInfo", i)
                    if type(name) == "string" and name ~= "" and name ~= "secret" and not isHeader then
                        rows[tostring(i)] = table.concat({
                            Clean(name), Clean(rank), Clean(maxRank), "",
                        }, "\t")
                    end
                end
            end
        end
        return rows
    end,
}
