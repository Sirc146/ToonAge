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
-- Ranks come from the rank text the client reports ("Rank 2"), or, when that
-- is blank, from C_Spell.GetSpellLevelLearned (the level each rank is trained);
-- spell IDs are never used to guess an order. If the client reports neither
-- text, the check says so and makes no claim.
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

--- Rank number from rank text such as "Rank 3". nil when there is none.
local function RankNumber(text)
    if type(text) ~= "string" then return nil end
    return tonumber(text:match("(%d+)"))
end
M._RankNumber = RankNumber

--- Rank text for a spell ID, from the spellbook entry first, then the client.
local function RankText(subName, spellID)
    if subName and subName ~= "" then return tostring(subName) end
    if spellID and C_Spell and C_Spell.GetSpellSubtext then
        local sub = Try(C_Spell.GetSpellSubtext, spellID)
        if sub and sub ~= "" then return tostring(sub) end
    end
    return nil
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
                                rank    = RankText(item.subName, item.spellID),
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
                    rank    = RankText(rank, spellID),
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
-- only the top rank), the spell's own name and rank text are read from
-- C_Spell. A bar spell whose rank cannot be read makes no claim.

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
    return name, RankText(nil, spellID)
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

--- How one spell's ranks are ordered: by rank text when EVERY copy has it,
--- else by learned level when every copy has that, else not at all.
--- @return string|nil mode "rank" | "level"
local function GroupMode(entries)
    local allRank, allLevel = true, true
    for _, e in ipairs(entries) do
        if not e.n then allRank = false end
        if not e.learned then allLevel = false end
    end
    if allRank then return "rank" end
    if allLevel then return "level" end
    return nil
end

local function Key(e, mode) if mode == "rank" then return e.n end return e.learned end

--- Human label for one copy of a spell under a mode.
local function Label(e, mode)
    if mode == "rank" then return "Rank " .. e.n end
    return "the level " .. e.learned .. " rank"
end
M._Label = Label

--- Compare bar spells against the highest rank known per spell name.
--- Pure: takes the spellbook groups and the bar list, touches no API.
--- @return table outdated { { slot=, name=, have=, best=, haveLabel=, bestLabel= } } by slot
--- @return boolean ranked  false when no spell could be ordered at all
--- @return table byName   name -> { outdated entries for that spell }
--- @return table onBar    name -> true when the best copy is also on a bar
local function FindOutdated(lines, bars)
    -- Every copy of every spell, book and bar, grouped by name.
    local groups, byID = {}, {}
    local function add(name, e)
        groups[name] = groups[name] or { book = {}, all = {} }
        table.insert(groups[name].all, e)
        return groups[name]
    end
    for _, group in ipairs(lines or {}) do
        for _, sp in ipairs(group.spells) do
            local e = { id = sp.spellID, n = RankNumber(sp.rank), learned = sp.learned }
            table.insert(add(sp.name, e).book, e)
            if sp.spellID then byID[sp.spellID] = { name = sp.name, e = e } end
        end
    end
    local barCopies = {}
    for _, b in ipairs(bars or {}) do
        local known = byID[b.spellID]
        local name = known and known.name or b.name
        if name and groups[name] then
            local e = known and known.e
                or { id = b.spellID, n = RankNumber(b.rank), learned = b.learned }
            if not known then add(name, e) end
            barCopies[#barCopies + 1] = { slot = b.slot, name = name, e = e }
        end
    end

    -- Per name: ordering mode and the best copy in the spellbook.
    local ranked, best, mode = false, {}, {}
    for name, g in pairs(groups) do
        local m = GroupMode(g.all)
        if m and #g.all > 0 then
            mode[name] = m
            for _, e in ipairs(g.book) do
                if Key(e, m) and (not best[name] or Key(e, m) > Key(best[name], m)) then
                    best[name] = e
                end
            end
            if #g.book > 1 or #g.all > 1 then ranked = true end
        end
    end

    local outdated, byName, onBar = {}, {}, {}
    for _, c in ipairs(barCopies) do
        local m, top = mode[c.name], best[c.name]
        if m and top then
            if Key(c.e, m) >= Key(top, m) then
                onBar[c.name] = true
            else
                local o = { slot = c.slot, name = c.name,
                            have = Key(c.e, m), best = Key(top, m),
                            haveLabel = Label(c.e, m), bestLabel = Label(top, m) }
                outdated[#outdated + 1] = o
                byName[c.name] = byName[c.name] or {}
                table.insert(byName[c.name], o)
            end
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
--- (by rank text, else by learned level). `count` is how many ranks you know.
local function Collapse(spells)
    local out, at = {}, {}
    for _, sp in ipairs(spells) do
        local n = RankNumber(sp.rank)
        local i = at[sp.name]
        if not i then
            out[#out + 1] = { name = sp.name, rank = sp.rank, n = n,
                              learned = sp.learned, topLearned = sp.learned, count = 1 }
            at[sp.name] = #out
        else
            local r = out[i]
            r.count = r.count + 1
            -- Highest trained level among the ranks you know: the anchor for
            -- "next rank", independent of whether rank text has loaded.
            if sp.learned and (not r.topLearned or sp.learned > r.topLearned) then
                r.topLearned = sp.learned
            end
            local better
            if n and r.n then better = n > r.n
            elseif not n and not r.n and sp.learned and r.learned then better = sp.learned > r.learned
            else better = (n ~= nil and r.n == nil) end
            if better then r.rank, r.n, r.learned = sp.rank, n, sp.learned end
        end
    end
    -- Rank text blank but several ranks known: say which one this row is.
    for _, r in ipairs(out) do
        if not r.rank and r.count > 1 and r.learned then
            r.rank = string.format("%d ranks · top learned at %d", r.count, r.learned)
        end
    end
    return out
end
M._Collapse = Collapse

-- ─── TRAINING (from the spell catalog) ──────────────────────────────────
--
-- Every trainable rank of every spell, read from the client by ID: shipped as
-- Data/Forever/SpellRanks.lua, or taken live from the harvest store when the
-- Harvest tab's "Scan spell catalog" has run on this install. Matched by NAME
-- against your own spellbook, so it only ever talks about spells your class
-- has; a new spell you have never learned stays out of it (the catalog cannot
-- say which class owns a spell).

--- name -> { { id=, n=, learned= }, ... } sorted by trained level. nil when
--- no catalog. `n` (the rank number) is nil when the client had not loaded the
--- rank text yet: measured 2026-09-29, C_Spell.GetSpellSubtext returned "" for
--- every Mage spell right after login and "Rank 2" later. The TRAINED LEVEL is
--- answered either way, so ranks are ordered by it, and the rank number is
--- only a label when present.
local function CatalogByName()
    -- This install's own scan wins over the shipped file: it is newer, and
    -- it was taken on this client build.
    local shipped = TA.Data and TA.Data.ForeverSpellRanks
    -- The harvest store (TA.db.harvest since harvest spec T3), via the core.
    local harvest = TA.Harvester and TA.Harvester:Store() or nil
    local store = harvest and harvest.catalog
    -- Trainer ranks (2026-10-03): one trainer visit records every rank the
    -- class trainer teaches, with the level each needs and its spell ID --
    -- including ranks you are too low for (measured on Forever 70205: 35
    -- "unavailable" rows up to level 60 on a level-17 Mage). Format 2 only.
    local _, class = UnitClass("player")
    local trainer = harvest and harvest.trainerFormat == 2 and harvest.trainer
        and class and harvest.trainer[class]
    local hasStore = type(store) == "table" and next(store) ~= nil
    local hasTrainer = type(trainer) == "table" and next(trainer) ~= nil
    if not hasStore and not hasTrainer then return shipped end
    -- Rows are added to the same trainer table on each visit, so identity
    -- alone would keep a stale cache: the row count is part of the stamp.
    local stamp = hasStore and 1 or 0
    if hasTrainer then for _ in pairs(trainer) do stamp = stamp + 2 end end
    if M._catalogCache and M._catalogSrc == store and M._catalogTrainer == trainer
       and M._catalogStamp == stamp then
        return M._catalogCache
    end
    local out = {}
    local seenID = {}
    if hasTrainer then
        for id, line in pairs(trainer) do
            local name, rankText, req = tostring(line):match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
            req = tonumber(req)
            id = tonumber(id)
            if name and name ~= "" and req then
                out[name] = out[name] or {}
                table.insert(out[name], { id = id, n = RankNumber(rankText), learned = req })
                if id then seenID[id] = true end
            end
        end
    end
    store = hasStore and store or {}
    for id, line in pairs(store) do
        local name, rank, learned = tostring(line):match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
        learned = tonumber(learned)
        -- Only entries with "Rank N" text. Measured 2026-09-29: the client
        -- reports a trained level for NPC copies too (Fireball 9053, 20823 --
        -- "learned" 20, no rank text), so rank text is what separates the
        -- player's ranks from them. The catalog scan re-asks blanks until
        -- the text loads.
        if name and name ~= "" and learned and RankNumber(rank) and not seenID[tonumber(id)] then
            out[name] = out[name] or {}
            table.insert(out[name], { id = tonumber(id), n = RankNumber(rank), learned = learned })
        end
    end
    for _, list in pairs(out) do
        table.sort(list, function(a, b)
            if a.learned ~= b.learned then return a.learned < b.learned end
            return (a.id or 0) < (b.id or 0)
        end)
    end
    M._catalogCache, M._catalogSrc = out, (hasStore and harvest.catalog or nil)
    M._catalogTrainer, M._catalogStamp = trainer, stamp
    return out
end

M._CatalogByName = function() return CatalogByName() end

--- The next rank above the one you know, by trained level. `haveLearned` is
--- the trained level of your top rank. A spell with one entry (unranked) has
--- no next rank.
local function RankLabel(r)
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
            local value = sp.rank or ""
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
                status    = warn and "warn" or (sp.rank and "dim" or "neutral"),
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
            "The client reported neither rank text nor learned levels for your "
            .. "spells, so ranks cannot be compared. Nothing is guessed from spell IDs."), nil
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

function M:OnEvent(event)
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
}

return M
