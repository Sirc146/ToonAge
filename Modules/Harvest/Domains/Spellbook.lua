-- ToonAge/Modules/Harvest/Domains/Spellbook.lua  (harvest domain: spells you know)
--
-- Every spell in your spellbook, per class: name, the level you were when it
-- was first seen, its spellbook line, its rank text and the level that rank is
-- trained at. Two spellbook APIs exist depending on client generation: the
-- modern C_SpellBook path is tried first, and the legacy globals are kept for
-- clients that only have those (and because a client whose API set is only
-- partly mapped would otherwise silently collect nothing). Every client API
-- call goes through TA.Caps (spec R2). Moved here from
-- Modules/Forever/DataHarvester.lua in T4.
--
-- v2 (2026-09-28): spell records carry their rank text. 2026-09-29: they gain
-- a 6th field, the level the rank is trained at (C_Spell.GetSpellLevelLearned),
-- and a record whose rank text was stored blank is rewritten once the client
-- reports it. Older records are upgraded in place on the next scan.
--   spells["CLASS:spellID"] = name, first-seen level, spellbook line, rank text,
--                             "passive" or "", trained level

local TA = ToonAge
local Hv, Caps = TA.Harvester, TA.Caps

local Try, Put, Clean = Hv.Try, Hv.Put, Hv.Clean

local MAX_SPELLS = 6000   -- the spell set is small and finite by nature

local D = {
    id = "spellbook",
    -- Both names on purpose. LEARNED_SPELL_IN_TAB is the classic-era event and
    -- LEARNED_SPELL_IN_SKILL_LINE the modern one; Forever answers to the
    -- second and threw on the first, which is what killed this recorder's Init
    -- before TA:RegisterEvent started absorbing that. Asking for both costs
    -- nothing now and means the recorder works on either client.
    events = { "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "LEARNED_SPELL_IN_SKILL_LINE", "PLAYER_LEVEL_UP" },
    rescan = { { "spellbook", "ScanSpellbook" } },
    export = { { section = "spells", label = "Spells" } },
    summary = { { section = "spells", label = "Spells seen in spellbooks" } },
}

function D:ScanSpellbook()
    local s = Hv:Store()
    if not s then return 0 end

    local _, class = Try("UnitClass", "player")
    class = class or "UNKNOWN"
    local level = Try("UnitLevel", "player") or 0
    local n = 0
    local racials = Hv:Domain("racials")
    -- Every spell read this run, including ones the class catalog already
    -- holds. The character capture is this table, replaced wholesale.
    local rows = {}
    local modernRead, legacyRead = false, false

    local function Keep(key, spellID, line)
        rows[tostring(spellID)] = line
        if s.spells[key] ~= nil then
            s.spells[key] = line
            Hv:Touch("spells")
        elseif Put(s.spells, key, line, MAX_SPELLS) then
            n = n + 1
        end
    end

    if Caps.State("C_SpellBook.GetNumSpellBookSkillLines") == "present"
       and Caps.State("C_SpellBook.GetSpellBookItemInfo") == "present" then
        local rawLines = Try("C_SpellBook.GetNumSpellBookSkillLines")
        if rawLines ~= nil then
            modernRead = true
            local bank = Caps.Get("Enum.SpellBookSpellBank.Player")
            local lines = tonumber(rawLines) or 0
            for line = 1, lines do
                local info = Try("C_SpellBook.GetSpellBookSkillLineInfo", line)
                if type(info) == "table" and info.numSpellBookItems then
                    for i = info.itemIndexOffset + 1,
                            info.itemIndexOffset + info.numSpellBookItems do
                        local item = Try("C_SpellBook.GetSpellBookItemInfo", i, bank)
                        if type(item) == "table" and item.spellID then
                            -- Rank text ("Rank 2"), the same source the Spells tab
                            -- reads: the item's own subName, else C_Spell.GetSpellSubtext.
                            local rank = item.subName
                            if not rank or rank == "" then
                                rank = Try("C_Spell.GetSpellSubtext", item.spellID)
                            end
                            local key = class .. ":" .. item.spellID
                            -- An updated record keeps the level it was first seen at.
                            local old = s.spells[key]
                            local seen = old and old:match("^[^\t]*\t([^\t]*)") or level
                            -- Trainer level for this rank (C_Spell.GetSpellLevelLearned,
                            -- measured working on Forever 2026-09-29: Fireball 1/6/12).
                            local learned = Try("C_Spell.GetSpellLevelLearned", item.spellID) or nil
                            local rec = table.concat({ Clean(item.name), Clean(seen),
                                                  Clean(info.name), Clean(rank),
                                                  Clean(item.isPassive and "passive" or ""),
                                                  Clean(learned) }, "\t")
                            if racials and tostring(rank or ""):find("Racial") then
                                racials:Record(item.spellID, item.name, rank, item.isPassive)
                            end
                            Keep(key, item.spellID, rec)
                        end
                    end
                end
            end
        end
        -- A book that answered is this character's scan. Do not also walk
        -- the legacy API, which would replace the capture with a second read.
        if modernRead and next(rows) ~= nil then
            Hv:SaveCapture("spellbook", { rows = rows })
            return n
        end
    end

    -- Legacy path. Used when the modern book is absent or came back empty.
    local rawTabs = Try("GetNumSpellTabs")
    if rawTabs ~= nil then
        legacyRead = true
        local numTabs = tonumber(rawTabs) or 0
        for tab = 1, numTabs do
            local tabName, _, offset, numSpells = Try("GetSpellTabInfo", tab)
            for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
                local spellName, subName = Try("GetSpellBookItemName", i, "spell")
                local _, spellID = Try("GetSpellBookItemInfo", i, "spell")
                if spellID and spellName then
                    local key = class .. ":" .. spellID
                    local seen = s.spells[key] and s.spells[key]:match("^[^\t]*\t([^\t]*)") or level
                    Keep(key, spellID, table.concat({ Clean(spellName), Clean(seen),
                                   Clean(tabName), Clean(subName), "" }, "\t"))
                end
            end
        end
    end
    if modernRead or legacyRead then
        Hv:SaveCapture("spellbook", { rows = rows })
    end
    return n
end

function D:OnEvent(event)
    -- SPELLS_CHANGED and LEARNED_SPELL_IN_SKILL_LINE, at most once per 10s.
    -- PLAYER_LEVEL_UP is included so the first call still runs here; the
    -- full scan on that event replaces the book again once combat allows.
    Hv:Request("spellbook", function()
        D:ScanSpellbook()
        local n = Hv:CaptureCount("spellbook")
        Hv:Toast(("Harvest: spellbook saved (%d spell%s)"):format(n, n == 1 and "" or "s"))
    end)
end

function D:OnEnterWorld()
    self:ScanSpellbook()
end

-- ── Probe: spell ranks ────────────────────────────────────────────────────
-- The Spells tab's lower-rank-on-bar check needs a rank order. The first full
-- report showed EVERY spell with an empty rank field (item.subName and
-- C_Spell.GetSpellSubtext both blank, even Fireball 133/143/145/3140), so this
-- looks for where the client keeps it instead. Up to 4 spell names with more
-- than one ID in the harvest store; C_Spell answers by ID, so this works on
-- any character.
D.probes = {
    spellRanks = { title = "Spell ranks", run = function(P, L)
        local s = Hv:Store()
        local byName = {}
        for key, line in pairs((s and s.spells) or {}) do
            local id = tonumber(tostring(key):match(":(%d+)$"))
            local name = tostring(line):match("^([^\t]*)")
            if id and name and name ~= "" then
                byName[name] = byName[name] or {}
                local seen = false
                for _, v in ipairs(byName[name]) do if v == id then seen = true end end
                if not seen then table.insert(byName[name], id) end
            end
        end
        local names = {}
        for n, ids in pairs(byName) do if #ids > 1 then names[#names + 1] = n end end
        table.sort(names, function(a, b)
            if a == "Fireball" then return true elseif b == "Fireball" then return false end
            return a < b end)
        if #names == 0 then L[#L + 1] = "(no spell with more than one ID in the store yet)" end
        for i = 1, math.min(4, #names) do
            local ids = byName[names[i]]
            table.sort(ids)
            L[#L + 1] = names[i] .. "  ids " .. table.concat(ids, "/")
            for _, id in ipairs(ids) do
                L[#L + 1] = "  -- " .. id
                P.Call(L, "    C_Spell.GetSpellSubtext", "C_Spell.GetSpellSubtext", id)
                P.Call(L, "    C_Spell.GetSpellLevelLearned", "C_Spell.GetSpellLevelLearned", id)
                P.Call(L, "    GetSpellLevelLearned(id)", "GetSpellLevelLearned", id)
                P.Call(L, "    C_Spell.GetSpellPowerCost", "C_Spell.GetSpellPowerCost", id)
                P.Call(L, "    C_Spell.GetSpellInfo", "C_Spell.GetSpellInfo", id)
                P.Call(L, "    C_Spell.GetSpellRank", "C_Spell.GetSpellRank", id)
                local tipFn = Caps.Fn("C_TooltipInfo.GetSpellByID")
                if not tipFn then
                    L[#L + 1] = "    C_TooltipInfo.GetSpellByID  ->  missing"
                else
                    local ok, data = pcall(tipFn, id)
                    if ok and type(data) == "table" and type(data.lines) == "table" then
                        for li = 1, math.min(4, #data.lines) do
                            local ln = data.lines[li]
                            L[#L + 1] = ("    tooltip[%d]  ->  %s  |  %s"):format(li,
                                P.Show(ln.leftText), P.Show(ln.rightText))
                        end
                    else
                        L[#L + 1] = "    C_TooltipInfo.GetSpellByID  ->  "
                            .. (ok and P.Show(data) or ("error: " .. tostring(data)))
                    end
                end
            end
        end
    end },
}

Hv:RegisterDomain(D)
