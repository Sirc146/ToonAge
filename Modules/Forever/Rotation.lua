-- ToonAge/Modules/Forever/Rotation.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of the spells you actually know, grouped the way the spellbook
-- groups them (General, your class line, the profession/secondary lines). For
-- each spell it shows the name and, when the client reports one, the rank.
--
-- WHY IT IS NOT A "ROTATION". Vanilla has no rotation system for an addon to
-- read — no spec, no priority list, no assisted-combat API. Retail's Rotation
-- tab reads an engine that does not exist on this client. The honest thing the
-- client CAN answer is "what is in your spellbook", so that is what this shows.
-- When Data/Forever eventually carries per-class ability priorities, an
-- advisory layer can sit on top; until then this reports facts only, the same
-- line every Forever tab holds.
--
-- API REALITY: two spellbook APIs exist by client generation. Forever runs the
-- Midnight API, so C_SpellBook is tried first (the exact shape used by
-- DataHarvester:ScanSpellbook, which is known to work here), with the legacy
-- GetNumSpellTabs / GetSpellBookItem* globals as a fallback. If neither
-- answers, the tab says so rather than rendering an empty list.
--
-- RANK CHECK. Forever keeps Vanilla's spell ranks, one spell ID per rank
-- (measured: Fireball 133/143/145/3140, Frostbolt 116/205). A bar
-- slot holding a lower rank than you know is either an oversight or a
-- deliberate downrank for mana, so the tab LISTS it -- it does not call it an
-- error. Each spell row in the list carries the note inline ("Lower rank in
-- use: Rank 2 on Bar 1 button 3"), and a summary above counts them.
-- The rank is that spell's position in the chain in Data/Forever/SpellRanks.lua.
-- A spell the file does not list is ordered by C_Spell.GetSpellLevelLearned.
-- GetSpellSubtext is display text only: the same ID returned "Rank 1" in one
-- probe and "" in another, because the text is not always loaded yet. Empty
-- text asks C_Spell.RequestLoadSpellData and the tab redraws on
-- SPELL_DATA_LOAD_RESULT. Spell IDs are never used to guess an order.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverRotation", M)

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

--- Rank number from display text such as "Rank 3". The self-test uses this
--- to compare the data file with loaded subtext. Rank order does not.
local function RankNumber(text)
    return U.RankNumberFromSubtext(text)
end
M._RankNumber = RankNumber

--- Subtext for display. Spellbook subName first, then GetSpellSubtext.
--- Empty means the client has not loaded the text yet: ask once, and redraw
--- when SPELL_DATA_LOAD_RESULT fires. Never a source of rank order.
local function DisplaySubtext(subName, spellID)
    if type(subName) == "string" and subName ~= "" then return subName end
    local sub
    if spellID and C_Spell and C_Spell.GetSpellSubtext then
        sub = Try(C_Spell.GetSpellSubtext, spellID)
    end
    if type(sub) == "string" and sub ~= "" then
        if spellID and M._loadAsked then M._loadAsked[spellID] = nil end
        return sub
    end
    if spellID and C_Spell and C_Spell.RequestLoadSpellData then
        M._loadAsked = M._loadAsked or {}
        if not M._loadAsked[spellID] then
            M._loadAsked[spellID] = true
            Try(C_Spell.RequestLoadSpellData, spellID)
        end
    end
    return nil
end

--- The flavor's shipped rank chains. Forever's module defaults to its own
--- file when a test has not set TA.flavor.
local function ActiveChains()
    local data = TA.Data
    if type(data) ~= "table" or not U.SpellRankTableName then return nil end
    local key = U.SpellRankTableName(TA.flavor or "forever")
    local t = key and data[key]
    if type(t) == "table" then return t end
    return nil
end

local CatalogByName

--- Chain used to number ranks: the live catalog when this install has one
--- (it extends the shipped file), otherwise the shipped file alone.
local function ChainsForRanks()
    if TA.Harvester and TA.Harvester.Store and type(UnitClass) == "function" then
        local ok, cat = pcall(CatalogByName)
        if ok and type(cat) == "table" then return cat end
    end
    return ActiveChains()
end

--- Level a spell ID is learned at, from the client. nil when unanswered.
--- Measured on Forever: Fireball 133/143/145/3140, one ID per rank. Arcane
--- Intellect 1459/1460 -> 1/14. Used ONLY when rank text is blank, as a
--- second source of rank order; it is the client's own trainer data, not a
--- guess from spell IDs (which do not follow rank: Battle Shout R1 is 6673,
--- R2 is 5242).
local function LearnedLevel(spellID)
    if not (spellID and C_Spell and C_Spell.GetSpellLevelLearned) then return nil end
    local v = Try(C_Spell.GetSpellLevelLearned, spellID)
    if type(v) == "number" and v > 0 then return v end
    return nil
end
M._LearnedLevel = LearnedLevel

--- Read the spellbook into ordered line groups.
--- @return table lines  { { name=, spells={ {name=, rank=}, ... } }, ... }
--- @return boolean readable
local function ReadSpellbook()
    local lines = {}

    -- Modern path — the shape DataHarvester uses and that resolves on Forever.
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
       and C_SpellBook.GetSpellBookItemInfo then
        local numLines = Try(C_SpellBook.GetNumSpellBookSkillLines) or 0
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        for line = 1, numLines do
            local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if type(info) == "table" and info.numSpellBookItems then
                local group = { name = tostring(info.name or ("Line " .. line)), spells = {} }
                for i = info.itemIndexOffset + 1,
                        info.itemIndexOffset + info.numSpellBookItems do
                    local item = Try(C_SpellBook.GetSpellBookItemInfo, i, bank)
                    if type(item) == "table" and item.name then
                        -- itemType FLAG spells are the "future rank" ghosts; skip
                        -- them so the list is only what you can actually cast.
                        local isFuture = (item.itemType ~= nil)
                            and Enum and Enum.SpellBookItemType
                            and item.itemType == Enum.SpellBookItemType.FutureSpell
                        if not isFuture then
                            group.spells[#group.spells + 1] = {
                                name    = tostring(item.name),
                                spellID = item.spellID,
                                rank    = DisplaySubtext(item.subName, item.spellID),
                                learned = LearnedLevel(item.spellID),
                            }
                        end
                    end
                end
                if #group.spells > 0 then lines[#lines + 1] = group end
            end
        end
        if #lines > 0 then return lines, true end
    end

    -- Legacy path.
    local numTabs = Try(GetNumSpellTabs) or 0
    for tab = 1, numTabs do
        local tabName, _, offset, numSpells = Try(GetSpellTabInfo, tab)
        local group = { name = tostring(tabName or ("Tab " .. tab)), spells = {} }
        for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
            local name, rank = Try(GetSpellBookItemName, i, "spell")
            local _, spellID = Try(GetSpellBookItemInfo, i, "spell")
            if name then
                group.spells[#group.spells + 1] = {
                    name    = tostring(name),
                    spellID = spellID,
                    rank    = DisplaySubtext(rank, spellID),
                    learned = LearnedLevel(spellID),
                }
            end
        end
        if #group.spells > 0 then lines[#lines + 1] = group end
    end

    return lines, (#lines > 0)
end

-- ─── RANK CHECK ───────────────────────────────────────────────────────────
--
-- Learning a new rank never moves it onto your bars; the old rank stays in the
-- slot until you drag the new one over. So every spell row in the list below
-- checks the bars itself and says so inline when a slot still holds a lower
-- rank. A summary section above the list counts them.
--
-- A bar spell is resolved by ID. The spellbook is asked first; if the
-- spellbook does not list that exact rank (a Mainline-style spellbook may show
-- only the top rank), the spell's name is read from C_Spell. Its rank is the
-- chain position, not the subtext. A spell with no chain and no trained
-- level makes no claim.

-- Action slots 1-180 cover every bar the Mainline UI can show, including the
-- extra bars; empty and non-spell slots are skipped.
local MAX_ACTION_SLOT = 180

--- Human name for an action slot, using the Mainline bar layout.
--- 1-12 bar 1, 13-24 bar 1 page 2, 25-36 bar 4 (right), 37-48 bar 5 (right 2),
--- 49-60 bar 3, 61-72 bar 2, 73-120 stance/form pages of bar 1,
--- 145-156 bar 6, 157-168 bar 7, 169-180 bar 8.
local function SlotName(slot)
    local btn = (slot - 1) % 12 + 1
    local bar
    if slot <= 12 then bar = "Bar 1"
    elseif slot <= 24 then bar = "Bar 1 page 2"
    elseif slot <= 36 then bar = "Bar 4"
    elseif slot <= 48 then bar = "Bar 5"
    elseif slot <= 60 then bar = "Bar 3"
    elseif slot <= 72 then bar = "Bar 2"
    elseif slot <= 120 then bar = "Bar 1 (stance/form page)"
    elseif slot >= 145 and slot <= 156 then bar = "Bar 6"
    elseif slot >= 157 and slot <= 168 then bar = "Bar 7"
    elseif slot >= 169 then bar = "Bar 8"
    else bar = "Bar page" end
    return string.format("%s button %d", bar, btn)
end
M._SlotName = SlotName


--- Name and rank text for a spell ID straight from the client.
local function SpellNameRank(spellID)
    local name
    if C_Spell and C_Spell.GetSpellName then name = Try(C_Spell.GetSpellName, spellID) end
    if not name and C_Spell and C_Spell.GetSpellInfo then
        local info = Try(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" then name = info.name end
    end
    if type(name) ~= "string" or name == "" then return nil end
    return name, DisplaySubtext(nil, spellID)
end

--- Spell IDs placed on action bars.
--- @return table|nil list { { slot=, spellID=, name=, rank=, learned= } }; nil if unreadable
local function ReadBarSpells()
    if type(GetActionInfo) ~= "function" then return nil end
    local out = {}
    for slot = 1, MAX_ACTION_SLOT do
        local kind, id = Try(GetActionInfo, slot)
        if kind == "spell" and type(id) == "number" then
            local name, rank = SpellNameRank(id)
            out[#out + 1] = { slot = slot, spellID = id, name = name, rank = rank,
                              learned = LearnedLevel(id) }
        end
    end
    return out
end

--- Human label for one copy. Chain position when we have one, else the
--- trained level. The client's subtext is not part of this label: it may
--- still be unloaded, and the row itself shows it once it arrives.
local function Label(e)
    if e.n then return "Rank " .. e.n end
    if e.learned then return "the level " .. e.learned .. " rank" end
    return "a rank"
end
M._Label = Label

--- Compare bar spells against the highest rank known per spell name.
--- Rank numbers come from the chain (data file, or the catalog built from
--- it). Subtext on the spell rows is ignored. Touches no client API except
--- through ChainsForRanks, which reads the harvest store when one exists.
--- @return table outdated { { slot=, name=, have=, best=, haveLabel=, bestLabel= } } by slot
--- @return boolean ranked  false when no spell could be ordered at all
--- @return table byName   name -> { outdated entries for that spell }
--- @return table onBar    name -> true when the best copy is also on a bar
local function FindOutdated(lines, bars)
    local flat, bookOf, barCopies = {}, {}, {}
    for _, group in ipairs(lines or {}) do
        for _, sp in ipairs(group.spells or {}) do
            local e = {
                spellID = sp.spellID, name = sp.name, learned = sp.learned, book = true,
            }
            flat[#flat + 1] = e
            if sp.spellID then bookOf[sp.spellID] = e end
        end
    end
    for _, b in ipairs(bars or {}) do
        local known = b.spellID and bookOf[b.spellID]
        if known then
            if not known.learned and b.learned then known.learned = b.learned end
            barCopies[#barCopies + 1] = { slot = b.slot, e = known }
        else
            local e = { spellID = b.spellID, name = b.name, learned = b.learned }
            flat[#flat + 1] = e
            barCopies[#barCopies + 1] = { slot = b.slot, e = e }
        end
    end
    U.AssignSpellRanks(flat, ChainsForRanks())

    local groups = {}
    for _, e in ipairs(flat) do
        if type(e.name) == "string" and e.name ~= "" then
            local g = groups[e.name]
            if not g then
                g = { book = {}, all = {} }
                groups[e.name] = g
            end
            table.insert(g.all, e)
            if e.book then table.insert(g.book, e) end
        end
    end

    local ranked, best = false, {}
    for name, g in pairs(groups) do
        local keys = 0
        for _, e in ipairs(g.all) do
            if e.n or (type(e.learned) == "number" and e.learned > 0) then keys = keys + 1 end
        end
        if keys >= 2 then ranked = true end
        for _, e in ipairs(g.book) do
            if e.n or (type(e.learned) == "number" and e.learned > 0) then
                if not best[name] or U.SpellRankHigher(e, best[name]) then best[name] = e end
            end
        end
    end

    local outdated, byName, onBar = {}, {}, {}
    for _, c in ipairs(barCopies) do
        local name = c.e.name
        local top = name and best[name]
        if top and U.SpellRankHigher(top, c.e) then
            local o = { slot = c.slot, name = name,
                        have = c.e.n, best = top.n,
                        haveLabel = Label(c.e), bestLabel = Label(top) }
            outdated[#outdated + 1] = o
            byName[name] = byName[name] or {}
            table.insert(byName[name], o)
        elseif top and not U.SpellRankHigher(c.e, top) then
            -- Same rank, or not distinguishable. A higher bar rank is not
            -- "outdated"; mark the name current only when it is not lower.
            if c.e.n or c.e.fromChain or c.e.learned then onBar[name] = true end
        end
    end
    table.sort(outdated, function(a, b) return a.slot < b.slot end)
    for _, list in pairs(byName) do
        table.sort(list, function(a, b) return a.slot < b.slot end)
    end
    return outdated, ranked, byName, onBar
end
M._FindOutdated = FindOutdated

--- Inline note for one spell row. nil when every bar copy is current.
local function BarNote(entries, bestOnBar)
    if not entries or #entries == 0 then return nil end
    local parts = {}
    for i, o in ipairs(entries) do
        if i > 2 then
            parts[#parts + 1] = string.format("+%d more", #entries - 2)
            break
        end
        parts[#parts + 1] = string.format("%s on %s", o.haveLabel, SlotName(o.slot))
    end
    local top = entries[1].bestLabel
    local tail = bestOnBar
        and string.format(" (%s is also on a bar)", top)
        or  string.format(" -- drag %s from the spellbook", top)
    return "Lower rank in use: " .. table.concat(parts, ", ") .. tail
end
M._BarNote = BarNote

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderIntro(content, y, total)
    y = L:SectionHeader(content, y, "Spellbook",
        string.format("%d spell%s known.", total, total == 1 and "" or "s"))
    y = L:Paragraph(content, y,
        "Vanilla has no rotation the client can hand out, so this lists what you "
        .. "actually know — cast priorities are yours to set. Grouped the way the "
        .. "spellbook groups them.")
    return y
end

--- Collapse a group to one row per spell name, keeping the highest rank
--- (chain position, else trained level). `count` is how many ranks you know.
--- `rank` stays the subtext of that highest rank, which may still be empty.
local function Collapse(spells)
    if U.AssignSpellRanks then U.AssignSpellRanks(spells, ChainsForRanks()) end
    local out, at = {}, {}
    for _, sp in ipairs(spells) do
        local i = at[sp.name]
        if not i then
            out[#out + 1] = { name = sp.name, rank = sp.rank, n = sp.n,
                              learned = sp.learned, topLearned = sp.learned,
                              fromChain = sp.fromChain, spellID = sp.spellID, count = 1 }
            at[sp.name] = #out
        else
            local r = out[i]
            r.count = r.count + 1
            -- Highest trained level among the ranks you know: the anchor for
            -- "next rank", independent of whether subtext has loaded.
            if sp.learned and (not r.topLearned or sp.learned > r.topLearned) then
                r.topLearned = sp.learned
            end
            if U.SpellRankHigher(sp, r) then
                r.rank, r.n, r.learned = sp.rank, sp.n, sp.learned
                r.fromChain, r.spellID = sp.fromChain, sp.spellID
            end
        end
    end
    return out
end
M._Collapse = Collapse

-- ─── TRAINING (from the spell catalog) ──────────────────────────────────
--
-- Every trainable rank of every spell. The chain is Data/Forever/SpellRanks.lua.
-- A harvest (trainer visit or spell catalog) adds ranks that file does not
-- list, ordered by trained level; it does not renumber the file. Matched by
-- NAME against your own spellbook, so it only ever talks about spells your
-- class has; a new spell you have never learned stays out of it (the catalog
-- cannot say which class owns a spell).

--- name -> { { id=, n=, learned= }, ... }. `n` is the position in the chain.
--- The shipped file is the chain. Trainer and catalog rows add spells the
--- file does not list, ordered by trained level, and may extend a shipped
--- chain with a higher trained level. Subtext is not read: a blank
--- GetSpellSubtext used to drop real ranks and keep the number unstable.
-- Assigned (not `local function`) so ChainsForRanks, defined above, calls this.
CatalogByName = function()
    -- Shipped chains stay authoritative for the IDs they list. A harvest adds
    -- ranks the file does not have; it does not renumber the file.
    local function CopyChains(src)
        local copy, seen = {}, {}
        if type(src) ~= "table" then return copy, seen end
        for name, list in pairs(src) do
            if type(list) == "table" then
                local rows = {}
                for i, r in ipairs(list) do
                    if type(r) == "table" and type(r.id) == "number" then
                        rows[#rows + 1] = { id = r.id, learned = r.learned, n = i }
                        seen[r.id] = true
                    end
                end
                if #rows > 0 then copy[name] = rows end
            end
        end
        return copy, seen
    end

    local harvest = TA.Harvester and TA.Harvester:Store() or nil
    local store = harvest and harvest.catalog
    -- Trainer ranks (2026-10-03): one trainer visit records every rank the
    -- class trainer teaches, with the level each needs and its spell ID --
    -- including ranks you are too low for (measured on Forever 70205: 35
    -- "unavailable" rows up to level 60 on a level-17 Mage). Format 2 only.
    local class
    if type(UnitClass) == "function" then
        local okU, _, token = pcall(UnitClass, "player")
        if okU then class = token end
    end
    local trainer = harvest and harvest.trainerFormat == 2 and harvest.trainer
        and class and harvest.trainer[class]
    local hasStore = type(store) == "table" and next(store) ~= nil
    local hasTrainer = type(trainer) == "table" and next(trainer) ~= nil
    if not hasStore and not hasTrainer then
        local copy = CopyChains(ActiveChains())
        return next(copy) and copy or nil
    end
    -- Rows are added to the same trainer table on each visit, so identity
    -- alone would keep a stale cache: the row count is part of the stamp.
    local stamp = hasStore and 1 or 0
    if hasTrainer then for _ in pairs(trainer) do stamp = stamp + 2 end end
    if M._catalogCache and M._catalogSrc == store and M._catalogTrainer == trainer
       and M._catalogStamp == stamp then
        return M._catalogCache
    end
    local out, seenID = CopyChains(ActiveChains())
    local extra = {}
    local function add(name, id, learned)
        if not name or name == "" or not id or not learned or learned <= 0 or seenID[id] then
            return
        end
        seenID[id] = true
        extra[name] = extra[name] or {}
        table.insert(extra[name], { id = id, learned = learned })
    end
    if hasTrainer then
        for id, line in pairs(trainer) do
            local name, _, req = tostring(line):match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
            add(name, tonumber(id), tonumber(req))
        end
    end
    if hasStore then
        for id, line in pairs(store) do
            local name, _, learned = tostring(line):match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
            -- Trained level only. NPC copies that also report a level used to
            -- be dropped by requiring "Rank N" text; names the shipped file
            -- already covers are not renumbered by those rows (see below).
            add(name, tonumber(id), tonumber(learned))
        end
    end
    for name, list in pairs(extra) do
        table.sort(list, function(a, b)
            if a.learned ~= b.learned then return a.learned < b.learned end
            return (a.id or 0) < (b.id or 0)
        end)
        local base = out[name]
        if not base then
            out[name] = {}
            for i, r in ipairs(list) do
                out[name][i] = { id = r.id, learned = r.learned, n = i }
            end
        else
            -- Keep the file's positions. Only a rank trained above the whole
            -- chain is appended, so a mid-chain NPC copy cannot shift them.
            local maxL = 0
            for _, r in ipairs(base) do
                if type(r.learned) == "number" and r.learned > maxL then maxL = r.learned end
            end
            for _, r in ipairs(list) do
                if r.learned > maxL then
                    base[#base + 1] = { id = r.id, learned = r.learned, n = #base + 1 }
                    maxL = r.learned
                end
            end
        end
    end
    M._catalogCache, M._catalogSrc = out, (hasStore and harvest.catalog or nil)
    M._catalogTrainer, M._catalogStamp = trainer, stamp
    return next(out) and out or nil
end

M._CatalogByName = function() return CatalogByName() end

--- The next rank above the one you know, by trained level. `haveLearned` is
--- the trained level of your top rank. A spell with one entry (unranked) has
--- no next rank.
local function RankLabel(r)
    local sub = DisplaySubtext(nil, r.id)
    if sub and sub ~= "" then return sub end
    return r.n and ("Rank " .. r.n) or ("the level " .. r.learned .. " rank")
end

local function NextRank(catalog, name, haveLearned)
    local list = catalog and catalog[name]
    if not (list and haveLearned) or #list < 2 then return nil end
    for _, r in ipairs(list) do
        if r.learned and r.learned > haveLearned then return r end
    end
    return nil
end
M._NextRank = NextRank

--- Does the catalog actually know this spell's ranks? Only if it lists a rank
--- trained ABOVE the one you know. A catalog that holds only your own rank
--- (the spellbook's text is all the scan could load) or nothing at all for
--- your class (the shipped data is Mage-only, 2026-09-30) cannot tell
--- "up to date" from "unknown" -- and must not claim the first.
local function Covered(catalog, sp)
    local list = catalog and catalog[sp.name]
    if not list then return false end
    local top = sp.topLearned or 0
    for _, r in ipairs(list) do
        if r.learned and r.learned > top then return true end
    end
    return false
end

local function IsRanked(sp)
    return sp.n ~= nil or (sp.count or 1) > 1
end

--- Next ranks due at `level`, plus coverage: how many of your ranked spells
--- the catalog can actually answer for.
--- @return table due, number ranked, number covered
local function DueAndCoverage(lines, catalog, level)
    local due, seen, ranked, covered = {}, {}, 0, 0
    for _, g in ipairs(lines) do
        for _, sp in ipairs(Collapse(g.spells)) do
            if not seen[sp.name] then
                seen[sp.name] = true
                if IsRanked(sp) then
                    ranked = ranked + 1
                    if Covered(catalog, sp) then covered = covered + 1 end
                end
                -- The HIGHEST rank your level allows, not merely the next one:
                -- a returning player at 30 trains straight to the level-24 rank.
                local best
                for _, r in ipairs((catalog and catalog[sp.name]) or {}) do
                    if r.learned and r.learned > (sp.topLearned or 0) and level and r.learned <= level
                       and (not best or r.learned > best.learned) then
                        best = r
                    end
                end
                if best then
                    due[#due + 1] = { name = sp.name, label = RankLabel(best), learned = best.learned }
                end
            end
        end
    end
    table.sort(due, function(a, b) return a.name < b.name end)
    return due, ranked, covered
end
M._DueAndCoverage = DueAndCoverage   -- self-test / offline check


local function RenderLines(content, y, lines, check, catalog, level)
    for idx, group in ipairs(lines) do
        if idx > 1 then y = L:Divider(content, y) end
        local rows = Collapse(group.spells)
        y = L:SectionHeader(content, y, group.name, string.format("%d", #rows))
        for _, sp in ipairs(rows) do
            local barNote = check
                and BarNote(check.byName[sp.name], check.onBar[sp.name])
            local nxt = NextRank(catalog, sp.name, sp.topLearned)
            local trainNow = nxt and level and nxt.learned <= level
            local trainNote = nxt and (trainNow
                and string.format("%s is trainable now (level %d) -- visit your trainer", RankLabel(nxt), nxt.learned)
                or  string.format("Next: %s at level %d", RankLabel(nxt), nxt.learned))
            local note = barNote
            if trainNote then note = note and (trainNote .. ". " .. note) or trainNote end
            local value = (sp.rank and sp.rank ~= "" and sp.rank)
                or (sp.n and ("Rank " .. sp.n))
                or ""
            if barNote then value = value .. "  |cFFFFA633(bar: lower)|r" end
            if trainNow then value = value .. "  |cFFFFA633(train)|r" end
            local warn = barNote or trainNow
            local tip
            if barNote then
                tip = {
                    "Learning a rank does not replace it on your bars.",
                    "Open the spellbook and drag " .. (sp.rank or "the top rank")
                        .. " onto the slot(s) listed.",
                    "Keep the low rank only if you downrank on purpose to save mana.",
                }
            end
            y = L:DataRow(content, y, {
                label     = sp.name,
                value     = value,
                status    = warn and "warn" or (value ~= "" and "dim" or "neutral"),
                note      = note or nil,
                noteColor = warn and "warn" or nil,
                tooltipTitle = tip and sp.name or nil,
                tooltip   = tip,
            })
        end
    end
    return y
end

--- "Train now": every spell whose next rank is at or below your level.
local function RenderTraining(content, y, lines, catalog, level)
    if not catalog then
        y = L:SectionHeader(content, y, "Training")
        y = L:Paragraph(content, y,
            "No spell catalog yet, so next ranks cannot be shown. Scanning takes a "
            .. "few seconds and the game stays responsive.", { color = L.C_DIM })
        return L:ButtonRow(content, y, {
            { label = "Scan spell catalog", onClick = function() TA:SlashCommand("catalog") end },
        })
    end
    local due, ranked, covered = DueAndCoverage(lines, catalog, level)
    local unchecked = ranked - covered
    if #due == 0 then
        if ranked > 0 and covered == 0 then
            y = L:SectionHeader(content, y, "Training", "no rank data for your class yet")
            return L:Paragraph(content, y, "ToonAge does not know the higher ranks of your "
                .. "spells yet, so it cannot say what is due. Your class trainer lists "
                .. "every rank and the level it needs.", { color = L.C_DIM })
        elseif unchecked > 0 then
            y = L:SectionHeader(content, y, "Training",
                string.format("%d of %d checked", covered, ranked))
            return L:Paragraph(content, y, string.format("Nothing due among the %d spells "
                .. "ToonAge has rank data for. The other %d cannot be checked yet -- "
                .. "your trainer can.", covered, unchecked), { color = L.C_DIM })
        end
        y = L:SectionHeader(content, y, "Training", "up to date")
        return L:Paragraph(content, y, "Every ranked spell you know is at the highest "
            .. "rank your level allows.")
    end
    y = L:SectionHeader(content, y, "Training",
        string.format("%d rank%s to train", #due, #due == 1 and "" or "s"))
    y = L:Paragraph(content, y, "Your trainer has these now. After training, drag "
        .. "the new rank onto your bars -- it is not moved there for you.",
        { color = L.C_WARNING })
    for _, d in ipairs(due) do
        y = L:DataRow(content, y, { label = d.name,
            value = string.format("%s  (level %d)", d.label, d.learned), status = "warn" })
    end
    if unchecked > 0 then
        y = L:Paragraph(content, y, string.format("%d more ranked spell%s could not be "
            .. "checked (no rank data yet).", unchecked, unchecked == 1 and "" or "s"),
            { color = L.C_DIM })
    end
    return y
end

--- Summary above the list. Returns y and the check result (nil if no check).
local function RenderRankCheck(content, y, lines)
    local bars = ReadBarSpells()
    if not bars then
        y = L:SectionHeader(content, y, "Action bar ranks")
        return L:Paragraph(content, y,
            "The client did not answer GetActionInfo, so the bars could not be "
            .. "checked.", { color = L.C_WARNING }), nil
    end
    local outdated, ranked, byName, onBar = FindOutdated(lines, bars)
    local check = { byName = byName, onBar = onBar }
    if not ranked then
        y = L:SectionHeader(content, y, "Action bar ranks")
        return L:Paragraph(content, y,
            "No rank chain in the data files, and no trained levels, so ranks "
            .. "cannot be compared. Nothing is guessed from spell IDs or from "
            .. "rank text."), nil
    end
    if #outdated == 0 then
        y = L:SectionHeader(content, y, "Action bar ranks", "all current")
        return L:Paragraph(content, y,
            string.format("Every ranked spell on your bars (%d spell slots checked) "
                .. "is the highest rank you know.", #bars)), check
    end
    local spells = 0
    for _ in pairs(byName) do spells = spells + 1 end
    y = L:SectionHeader(content, y, "Action bar ranks",
        string.format("%d slot%s below your best", #outdated, #outdated == 1 and "" or "s"))
    y = L:Paragraph(content, y, string.format(
        "%d spell%s on your bars %s a lower rank than you know. New ranks are never "
        .. "moved onto bars for you -- each one is marked in orange in the list "
        .. "below with the exact bar and button. Leave it if you downrank on "
        .. "purpose to save mana.",
        spells, spells == 1 and "" or "s", spells == 1 and "uses" or "use"),
        { color = L.C_WARNING })
    return y, check
end

local function RenderUnreadable(content, y)
    y = L:SectionHeader(content, y, "Spellbook")
    y = L:Paragraph(content, y,
        "The spellbook could not be read on this client. Neither the C_SpellBook "
        .. "API nor the legacy spell-tab globals answered, so ToonAge shows nothing "
        .. "rather than a wrong or empty list.", { color = L.C_WARNING })
    y = L:Paragraph(content, y,
        "Worth reporting with /ta apiprobe — it maps which spellbook calls the "
        .. "client actually exposes.")
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

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

    -- Same identity sidebar as the other Forever tabs, when available.
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local lines, readable = ReadSpellbook()

    local y = -8
    if not readable then
        y = RenderUnreadable(content, y)
    else
        local total = 0
        for _, g in ipairs(lines) do total = total + #g.spells end
        y = RenderIntro(content, y, total)
        y = L:Divider(content, y)
        local catalog = CatalogByName()
        local level = tonumber(Try(UnitLevel, "player"))
        y = RenderTraining(content, y, lines, catalog, level)
        y = L:Divider(content, y)
        local check
        y, check = RenderRankCheck(content, y, lines)
        y = L:Divider(content, y)
        y = RenderLines(content, y, lines, check, catalog, level)
    end
    L:Finish(content, y)
end

function M:OnEvent(event, spellID)
    -- Spell data loads one ID at a time. Redraw only for an ID this tab asked
    -- for, so an unrelated load does not rebuild the window.
    if event == "SPELL_DATA_LOAD_RESULT" then
        if not (spellID and M._loadAsked and M._loadAsked[spellID]) then return end
    end
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

-- ─── PUBLIC (used by Modules/Forever/SessionCheck.lua) ──────────────────

--- Spells whose next rank your level already allows.
--- @return table|nil due { { name=, label=, learned= } }, number ranked,
---   number covered; nil when there is no catalog or the spellbook can't be read
function M:TrainableNow(level)
    local lines, readable = ReadSpellbook()
    local catalog = CatalogByName()
    if not (readable and catalog and level) then return nil end
    return DueAndCoverage(lines, catalog, level)
end

--- Action-bar slots holding a lower rank than you know.
--- @return table|nil list { { slot=, name=, haveLabel=, bestLabel=, where= } }
function M:BarsBelow()
    local lines, readable = ReadSpellbook()
    local bars = ReadBarSpells()
    if not (readable and bars) then return nil end
    local outdated = FindOutdated(lines, bars)
    for _, o in ipairs(outdated) do o.where = SlotName(o.slot) end
    return outdated
end

M.Events = {
    "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_TAB",
    "PLAYER_LEVEL_UP",
    "SKILL_LINES_CHANGED",
    "ACTIONBAR_SLOT_CHANGED",
    "SPELL_DATA_LOAD_RESULT",
}

return M
