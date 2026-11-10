-- ToonAge/Modules/Forever/MageGuidance.lua
--
-- Experimental level 10-19 Mage spell guide for the Forever Spells tab.
-- This is not a talent guide and it does not replace the spellbook list.
--
-- The rows below are hand-copied from the opened rev3 research draft, and
-- only from the active 10-19 baseline plus the wand row. The whole mage.lua
-- file is not loaded. Disabled talent and proc rows are not copied in.
--
-- Opened bundle (hashes matched the bundle's SHA256SUMS on 2026-11-08):
--   mage.lua                 8d7bda22aa13834124ae11892a00785b95e4f9821f42a962d3b92900dbc4a5c4
--   MAGE-SUBSET-MANIFEST.md  bf250a16109271dd7f67356d471efdb1700affa6ebfc6de946043606d2f9df00
--   mage.md                  bd7c3be3e90bea78f814e5d8db3bd7143054f30716edec279547ea7bdf8a6a13
--   READINESS.md             460b8d4b45649f93c7a00e5f2c49c9740fb1b7a463109b665be90ad9635280f7
-- Provenance on those pages: status research_draft, rev 3, 2026-11-08,
-- verifiedAsWhole false. Last observed build 1.60.1.70862. S1 is the opened
-- Icy Veins Fire leveling page. Spell ids are only the ones that page set
-- marks confirmed: Fireball 133/143/145/3140 and Arcane Missiles 5143/5144.
--
-- A suggestion is pressable only when this character's own check confirms
-- the spell. Anything absent or unreadable stays unknown. Unknown is not
-- an unlearned claim. A computed next action requires verified boolean
-- gates. A situation the player picks stays conditional. Health, mana, and
-- enemy count are not read here, and no percent is treated as a cutoff.

local TA = ToonAge

local M = {}
TA.MageLevel12 = M

-- The commit this candidate was written against. It is not a published
-- package SHA, and it is not the moving test branch.
local PATCH_SOURCE_BASE = "b652f246c0d79edcad934cd0a1021bd4feb74ff4"

local Secret, ShownString, ShownNumber

local ALLOW = {
    [133] = true, [143] = true, [145] = true, [3140] = true,
    [5143] = true, [5144] = true,
}

local CHAIN = {
    Fireball = { 133, 143, 145, 3140 },
    ["Arcane Missiles"] = { 5143, 5144 },
}

local SITUATION_LABEL = {
    pull = "Pulling at range",
    engaged = "Enemy has reached me",
    finish = "Low health or no mana",
    pack = "Several mobs, solo",
}

M.DATA = {
    status = "research_draft",
    verifiedAsWhole = false,
    rev = 3,
    revDate = "2026-11-08",
    band = "10-19",
    label = "MAGE_FOREVER rev3 2026-11-08, research_draft",
    entries = {
        {
            key = "fireball", name = "Fireball", group = "st", tier = "A",
            situation = "pull", level = 1, spellID = 133,
            rankIDs = { 133, 143, 145, 3140 }, idConf = "C",
            active = true, tacticalVerified = true,
            tacticalUsage = "opener before the enemy reaches you",
            tacticalSrc = "S1", src = { "S1" },
            spellLevelSrc = "S2/S3 trainer list, wowfdb, client 1.60.1.70862",
        },
        {
            key = "arcane_missiles", name = "Arcane Missiles", group = "st", tier = "B",
            level = 8, spellID = 5143, rankIDs = { 5143, 5144 }, idConf = "C",
            active = true, tacticalVerified = false,
            tacticalUsage = "filler",
            tacticalUnresolved = "baseline filler use not stated without Missile Barrage",
            tacticalSrc = "S2/S3", src = { "S2", "S3" },
        },
        {
            key = "fire_blast", name = "Fire Blast", group = "st", tier = "B",
            level = 6, idConf = "none", active = true, tacticalVerified = false,
            tacticalUsage = "on cooldown",
            tacticalUnresolved = "S1 on cooldown is inside the Heating Up sequence only",
            tacticalSrc = "S2/S3", src = { "S2", "S3" },
        },
        {
            key = "frostbolt", name = "Frostbolt", group = "st", tier = "B",
            level = 4, idConf = "none", active = true, tacticalVerified = false,
            tacticalUsage = "Frost-style opener / kiting",
            tacticalUnresolved = "kiting use not stated",
            tacticalSrc = "S2/S3", src = { "S2", "S3" },
        },
        {
            key = "shoot", name = "Shoot", group = "st", tier = "A",
            situation = "finish", kind = "wand", idConf = "none",
            active = true, tacticalVerified = true, optional = true,
            tacticalUsage = "finish a low-health target or when out of mana",
            tacticalSrc = "S1", src = { "W1", "W2", "W3" },
            acquisitionRequires = { shootKnown = true, equippedUsableWand = true },
            runtimeContext = { stationary = true, appliesTo = "autorepeat", src = "W2" },
        },
        {
            key = "arcane_explosion", name = "Arcane Explosion", group = "aoe", tier = "A",
            level = 14, idConf = "none", active = true, tacticalVerified = true,
            tacticalUsage = "finish a pack (3+ targets)",
            tacticalSrc = "S1", src = { "S1" },
        },
        {
            key = "flamestrike", name = "Flamestrike", group = "aoe", tier = "A",
            level = 16, idConf = "none", active = true, tacticalVerified = true,
            tacticalUsage = "under a clustered pack (3+)",
            tacticalSrc = "S1", src = { "S1" },
        },
        {
            key = "frost_nova", name = "Frost Nova", group = "emergency", tier = "A",
            situation = "pack", level = 10, idConf = "none",
            active = true, tacticalVerified = true,
            tacticalUsage = "solo: freeze a cluster before AoE",
            tacticalSrc = "S1", src = { "S1" },
            requiresAoe = true,
        },
        {
            key = "polymorph", name = "Polymorph", group = "emergency", tier = "B",
            level = 8, idConf = "none", active = true, tacticalVerified = false,
            tacticalUsage = "CC an add",
            tacticalUnresolved = "not in S1",
            tacticalSrc = "S2/S3", src = { "S2", "S3" },
        },
    },
}

local function Denied(entry)
    if type(entry) ~= "table" then return true end
    if entry.active ~= true then return true end
    if entry.designNoteOnly then return true end
    if entry.group == "talentBranches" then return true end
    if entry.name == "Accelerant" then return true end
    if type(entry.requires) == "table" and entry.requires.talentKnown then return true end
    return false
end

local function IdsFor(entry)
    if entry.idConf ~= "C" then return {} end
    local chain = CHAIN[entry.name]
    if not chain then return {} end
    local have = {}
    for _, id in ipairs(entry.rankIDs or {}) do
        if ALLOW[id] then have[id] = true end
    end
    if ALLOW[entry.spellID] then have[entry.spellID] = true end
    local out = {}
    for _, id in ipairs(chain) do
        if have[id] then out[#out + 1] = id end
    end
    return out
end

local function BookRows(ctx)
    local rows = {}
    local book = ctx and ctx.spellbook
    if type(book) ~= "table" then return rows end
    for _, sp in ipairs(book) do
        if type(sp) == "table" then rows[#rows + 1] = sp end
    end
    return rows
end

local function ClientName(ctx, spellID)
    for _, sp in ipairs(BookRows(ctx)) do
        if sp.spellID == spellID and type(sp.name) == "string"
            and sp.name ~= "" and sp.name ~= "secret" then
            return sp.name
        end
    end
    return nil
end

local function BookHasID(ctx, spellID)
    if Secret(spellID) then return false end
    for _, sp in ipairs(BookRows(ctx)) do
        if not Secret(sp.spellID) and sp.spellID == spellID then return true end
    end
    return false
end

local function BookHasName(ctx, name)
    if Secret(name) then return false end
    for _, sp in ipairs(BookRows(ctx)) do
        if not Secret(sp.name) and sp.name == name then return true end
    end
    return false
end

local function Learn(entry, ctx)
    local ids = IdsFor(entry)
    if #ids > 0 then
        local confirmed = {}
        local anyUnknown = false
        local anyNo = false
        for _, id in ipairs(ids) do
            local answer = "unknown"
            if type(ctx.ask) == "function" then
                local value = ctx.ask(id)
                if value == "yes" or value == true then answer = "yes"
                elseif value == "no" or value == false then answer = "no"
                else answer = "unknown" end
            end
            if BookHasID(ctx, id) then answer = "yes" end
            if answer == "yes" then confirmed[#confirmed + 1] = id
            elseif answer == "unknown" then anyUnknown = true
            else anyNo = true end
        end
        if #confirmed > 0 then
            local id = confirmed[#confirmed]
            return "yes", id, ClientName(ctx, id), nil, confirmed
        end
        if anyUnknown or not anyNo then
            return "unknown", nil, nil, "unreadable"
        end
        return "unknown", nil, nil, "not confirmed"
    end
    if BookHasName(ctx, entry.name) then
        return "yes", nil, entry.name
    end
    local read = ctx.spellbookRead
    if read ~= "read" and read ~= "incomplete" and read ~= "unreadable" then
        read = type(ctx.spellbook) == "table" and "read" or "unreadable"
    end
    if read == "read" then
        return "unknown", nil, nil, "no exact spellbook name"
    end
    if read == "incomplete" then
        return "unknown", nil, nil, "spellbook incomplete"
    end
    return "unknown", nil, nil, "spellbook unread"
end

local function Flag(obs, key)
    if type(obs) ~= "table" then return nil end
    local value = obs[key]
    if value == true then return true end
    if value == false then return false end
    return nil
end

local function ResolveSituation(ctx)
    if ctx.situationObserved == true then
        local obs = ctx.observed
        if Flag(obs, "pullAtRange") == true then return "pull", "observed" end
        if Flag(obs, "targetLowHealth") == true or Flag(obs, "playerOutOfMana") == true then
            return "finish", "observed"
        end
        if Flag(obs, "severalMobs") == true and Flag(obs, "solo") == true then
            return "pack", "observed"
        end
        return "none", "observed"
    end
    local situation = ctx.situation
    if situation == "pull" or situation == "engaged" or situation == "finish" or situation == "pack" then
        return situation, "player"
    end
    return "pull", "assumed"
end

local function ByKey(rows)
    local map = {}
    for _, row in ipairs(rows) do map[row.key] = row end
    return map
end

local function TipWhy(entry)
    if entry.key == "arcane_missiles" then
        return "Unverified tip, not an optimum: filler. The opened page does not state that use without Missile Barrage, and the proc row is not part of this guide."
    elseif entry.key == "fire_blast" then
        return "Unverified tip, not an optimum: on cooldown. That wording sits inside the Heating Up sequence, which this guide does not use."
    elseif entry.key == "frostbolt" then
        return "Unverified tip, not an optimum. A kiting use is not stated. S1 says not to waste mana kiting a half-dead enemy."
    elseif entry.key == "polymorph" then
        return "Unverified tip, not an optimum: crowd-control an add. Polymorph is not in the S1 text."
    end
    return "Unverified tip, not an optimum."
end

local function ActionCopy(entry, label, spellID, computed)
    local why, changes, src
    if entry.key == "fireball" then
        why = "Cast Fireball before the enemy reaches you. S1 states this as the opener."
        changes = "This pick changes if the enemy has already reached you, if the target is low health, or if you are out of mana and Shoot is confirmed with a wand in the ranged slot whose required level you have met. That is type and level only, not a check that combat can use it."
        src = "S1"
    elseif entry.key == "shoot" then
        why = "Shoot finishes a low-health target or conserves mana when you are out of mana. Stand still. S1's example was under 15 percent; that is not a cutoff, and no cast time or global cooldown is claimed."
        changes = "This pick changes if you still have mana and the target is not low health. The opener before the enemy reaches you is Fireball, when Fireball is confirmed."
        src = "S1"
    else
        why = "Frost Nova freezes the enemies together before an area spell. S1 says avoid area spells on fewer than three targets. The pack size is your choice, not a counted number."
        changes = "This pick changes if you are not solo, or if fewer than three enemies are on you. Fireball remains the opener before a single enemy reaches you."
        src = "S1"
    end
    local headline
    if computed then
        headline = "Next (gates verified, research draft): " .. label
    else
        headline = "Next (conditional, not a computed optimum): " .. label
    end
    return {
        press = true,
        label = label,
        guideName = entry.name,
        spellID = spellID,
        tier = "A",
        src = src,
        confidence = "page-stated",
        why = why,
        changes = changes,
        headline = headline,
    }
end

local function Gap(situation, rows, wand)
    local map = ByKey(rows)
    local headline = "No confirmed next spell for this situation"
    local why, changes
    if situation == "pull" then
        why = "Fireball is the page-stated opener before the enemy reaches you, but it is not confirmed, so there is no spell to press."
        changes = "This pick changes if the enemy has already reached you, if the target is low health, or if you are out of mana and Shoot is confirmed with a wand in the ranged slot whose required level you have met. That is type and level only, not a check that combat can use it."
    elseif situation == "finish" then
        local shoot = map.shoot and map.shoot.state or "unknown"
        if wand ~= "yes" and wand ~= "no" and wand ~= "unknown" then wand = "unknown" end
        why = "Shoot would finish a low-health target or conserve mana, but only when Shoot is confirmed and the ranged slot holds a wand whose required level you have met. That is type and level only, not a check that combat can use it. Shoot: "
            .. shoot .. ". Ranged-slot wand type and required level: " .. wand
            .. ". Stand still. S1's example was under 15 percent; that is not a cutoff, and no cast time or global cooldown is claimed."
        changes = "This pick changes if you still have mana and the target is not low health. The opener before the enemy reaches you is Fireball, when Fireball is confirmed."
    elseif situation == "pack" then
        local nova = map.frost_nova and map.frost_nova.state or "unknown"
        local ae = map.arcane_explosion and map.arcane_explosion.state or "unknown"
        local fs = map.flamestrike and map.flamestrike.state or "unknown"
        why = "The page-stated pack step is Frost Nova, and only when Frost Nova plus Arcane Explosion or Flamestrike is confirmed. Frost Nova: "
            .. nova .. ". Arcane Explosion: " .. ae .. ". Flamestrike: " .. fs
            .. ". S1 says avoid area spells on fewer than three targets. Arcane Explosion is trainer-listed at 14 and Flamestrike at 16."
        changes = "This pick changes if you are not solo, or if fewer than three enemies are on you."
    else
        why = "No page-stated next spell once the enemy has reached you, unless the target is low health, you are out of mana, or several mobs are on you while you are solo."
        changes = "Choose Pulling at range for Fireball, Low health or no mana for Shoot, or Several mobs, solo for Frost Nova. A chosen situation stays conditional."
    end
    return {
        press = false,
        headline = headline,
        why = why,
        changes = changes,
    }
end

function M.Applies(ctx)
    if type(ctx) ~= "table" then return false end
    if ctx.class ~= "MAGE" then return false end
    if type(ctx.level) ~= "number" then return false end
    if ctx.level < 10 or ctx.level > 19 then return false end
    return true
end

local function WithheldView(ctx)
    -- RefreshGate only stores "no" or "unknown" here. A previous "yes" is not copied in.
    local wand = (ctx.wand == "no" or ctx.wand == "unknown") and ctx.wand or "unknown"
    return {
        applies = ctx.placed == true,
        withheld = true,
        press = false,
        computed = false,
        headline = "No current spell. This read is unknown.",
        why = "Class or level could not be read, so no current spell is suggested.",
        changes = "A later read of class and level can show a suggestion from that fresh read.",
        situationLine = "Read: unknown. Target health: not read. Player mana: not read. Enemy count: not read.",
        wand = wand,
        shootKnown = "unknown",
        learned = {},
        unknown = {},
        tierB = {},
        historical = ctx.historical,
        experimentalLine = "Research draft. Not a talent guide. No talent-point recommendation.",
        dataLabel = M.DATA.label,
        band = "10-19",
    }
end

function M.Evaluate(ctx, data)
    ctx = ctx or {}
    if ctx.withheld then
        return WithheldView(ctx)
    end
    data = data or M.DATA
    if not M.Applies(ctx) then
        return {
            applies = false, press = false, computed = false,
            learned = {}, unknown = {}, tierB = {},
        }
    end
    local rows = {}
    for _, entry in ipairs(data.entries or {}) do
        if not Denied(entry) then
            local state, spellID, client, detail, confirmed = Learn(entry, ctx)
            rows[#rows + 1] = {
                entry = entry, key = entry.key, state = state,
                spellID = spellID, client = client, detail = detail,
                confirmed = confirmed,
            }
        end
    end

    local map = ByKey(rows)
    local situation, source = ResolveSituation(ctx)
    local action
    local function learned(key)
        return map[key] and map[key].state == "yes"
    end
    if situation == "pull" and learned("fireball") then
        local row = map.fireball
        local label = row.client or row.entry.name
        action = ActionCopy(row.entry, label, row.spellID, source == "observed")
    elseif situation == "finish" and learned("shoot") and ctx.wand == "yes" then
        local row = map.shoot
        action = ActionCopy(row.entry, row.client or row.entry.name, nil, source == "observed")
    elseif situation == "pack" and learned("frost_nova")
        and (learned("arcane_explosion") or learned("flamestrike")) then
        local row = map.frost_nova
        action = ActionCopy(row.entry, row.client or row.entry.name, nil, source == "observed")
        local extra = {}
        if learned("arcane_explosion") then extra[#extra + 1] = "Arcane Explosion" end
        if learned("flamestrike") then extra[#extra + 1] = "Flamestrike" end
        action.why = action.why .. " Confirmed area spell: " .. table.concat(extra, ", ") .. "."
    else
        action = Gap(situation, rows, ctx.wand)
    end

    local learnedRows, unknownRows, tierB = {}, {}, {}
    for _, row in ipairs(rows) do
        if row.state == "yes" then
            learnedRows[#learnedRows + 1] = {
                name = row.entry.name,
                spellID = row.spellID,
                client = row.client,
            }
            if row.entry.tier == "B" then
                tierB[#tierB + 1] = {
                    name = row.entry.name,
                    why = TipWhy(row.entry),
                    confidence = "inferred",
                }
            end
        else
            unknownRows[#unknownRows + 1] = {
                name = row.entry.name,
                detail = row.detail or "unreadable",
            }
        end
    end
    local rankConfirmed = false
    local fire = map.fireball
    if fire and fire.confirmed then
        for _, id in ipairs(fire.confirmed) do
            if id == 145 then rankConfirmed = true end
        end
    end

    local shoot = "unknown"
    if map.shoot and map.shoot.state == "yes" then shoot = "yes" end
    local wand = ctx.wand
    if wand ~= "yes" and wand ~= "no" and wand ~= "unknown" then wand = "unknown" end

    local rankHint
    if rankConfirmed then
        rankHint = "Fireball rank 3 (spell 145) is confirmed."
    else
        rankHint = "Fireball rank 3 is trainer-listed at 12 - not confirmed learned"
    end

    local situationLine
    if source == "observed" then
        situationLine = "Situation: " .. (SITUATION_LABEL[situation] or "not matched")
            .. " (verified boolean, not a health percent). Target health: not read. Player mana: not read. Enemy count: not read."
    elseif source == "assumed" then
        situationLine = "Situation: Pulling at range, assumed until you choose. This is conditional, not a computed optimum. Target health: not read. Player mana: not read. Enemy count: not read."
    else
        situationLine = "Situation: " .. (SITUATION_LABEL[situation] or situation)
            .. " (your choice, not a computed optimum). Target health: not read. Player mana: not read. Enemy count: not read."
    end

    local view = {
        applies = true,
        press = action.press and true or false,
        computed = action.press and source == "observed" and true or false,
        label = action.press and action.label or nil,
        guideName = action.guideName,
        spellID = action.press and action.spellID or nil,
        tier = action.press and action.tier or nil,
        src = action.src,
        confidence = action.press and action.confidence or nil,
        headline = action.headline,
        why = action.why,
        changes = action.changes,
        situation = situation,
        situationSource = source,
        situationLine = situationLine,
        rankHint = rankHint,
        learned = learnedRows,
        unknown = unknownRows,
        tierB = tierB,
        shootKnown = shoot,
        wand = wand,
        className = ctx.class,
        level = ctx.level,
        version = type(ctx.version) == "string" and ctx.version or nil,
        build = type(ctx.build) == "string" and ctx.build or nil,
        interface = type(ctx.interface) == "string" and ctx.interface or nil,
        errors = ctx.errors,
        experimentalLine = "Research draft. Not a talent guide. No talent-point recommendation.",
        dataLabel = type(data.label) == "string" and data.label or M.DATA.label,
        band = "10-19",
    }
    if map.shoot then ctx.shootKnown = shoot end
    return view
end

-- The feedback box shows this many captured errors. The rest stay in the
-- existing error log; /ta errors copy opens that full text.
local MAX_ERROR_LINES = 8

local function JoinNames(rows, withID)
    local parts = {}
    for _, row in ipairs(rows or {}) do
        local text = row.name or ""
        local spellNumber = ShownNumber(row.spellID)
        if withID and spellNumber then
            text = text .. " (spell " .. string.format("%.0f", spellNumber) .. ")"
        end
        if row.detail and row.detail ~= "" then
            text = text .. " [" .. row.detail .. "]"
        end
        parts[#parts + 1] = text
    end
    if #parts == 0 then return "(none)" end
    return table.concat(parts, ", ")
end

function M.Feedback(view, notes)
    view = view or {}
    notes = ShownString(notes) or ""
    local lines = {}
    local function add(text) lines[#lines + 1] = text end
    local function wandWord(value)
        if Secret(value) then return "unknown" end
        if value == "yes" or value == "no" or value == "unknown" then return value end
        return "unknown"
    end
    add("ToonAge experimental Mage spell guide")
    add("Select this text and press Ctrl+C, then paste it to the person reviewing the guide. Nothing here is sent.")
    add("Addon semantic version: " .. (ShownString(view.version) or "unknown"))
    add("Source data revision: " .. (ShownString(view.dataLabel) or M.DATA.label))
    add("Patch source base: " .. PATCH_SOURCE_BASE)
    add("Candidate code revision: not injected")
    add("Client build: " .. (ShownString(view.build) or "unknown"))
    add("Interface: " .. (ShownString(view.interface) or "unknown"))
    add("Class: " .. (ShownString(view.className) or "unknown"))
    local levelText = ShownNumber(view.level)
    if levelText then
        add("Level: " .. string.format("%.0f", levelText))
    else
        add("Level: unknown")
    end
    add("Band: " .. (view.band or "10-19"))
    if view.press then
        add("Suggestion: " .. (view.label or view.guideName or "")
            .. " | tier " .. (view.tier or "")
            .. " | " .. (view.src or "")
            .. " | " .. (view.confidence or "")
            .. (view.computed and " | computed from verified gates" or " | conditional, not a computed optimum"))
        if type(view.spellID) == "number" then
            add("Confirmed spell id: " .. string.format("%.0f", view.spellID))
        end
    else
        add("Suggestion: none. " .. (view.headline or ""))
    end
    add("Why: " .. (view.why or ""))
    add("What would change the pick: " .. (view.changes or ""))
    add(view.situationLine or "")
    add("target health: not read")
    add("player mana: not read")
    add("enemy count: not read")
    add("Confirmed learned: " .. JoinNames(view.learned, true))
    add("Unknown: " .. JoinNames(view.unknown, false))
    add("Shoot: " .. (ShownString(view.shootKnown) or "unknown"))
    add("Ranged-slot wand type and required level: " .. wandWord(view.wand))
    add("Wand line means equipped weapon type and required level only, not that combat can use it.")
    if type(view.historical) == "table" then
        add("Historical context (not a current action): previous ranged-slot reading was "
            .. wandWord(view.historical.wand) .. ".")
    end
    add("Rank hint: " .. (view.rankHint or ""))
    if type(view.errors) ~= "table" then
        add("Errors: not available")
    elseif #view.errors == 0 then
        add("Errors: none captured")
    else
        add("Errors already captured:")
        local shown = 0
        for _, entry in ipairs(view.errors) do
            if shown >= MAX_ERROR_LINES then break end
            if type(entry) == "table" then
                shown = shown + 1
                local time = ShownString(entry.time) or ""
                local source = ShownString(entry.source) or ""
                local msg = ShownString(entry.msg) or ""
                add("  " .. time .. " | " .. source .. " | " .. msg)
            end
        end
        if #view.errors > shown then
            add(string.format(
                "Showing %d of %d captured errors. The rest are truncated here. Full log: /ta errors copy.",
                shown, #view.errors))
        end
    end
    local tips = {}
    for _, tip in ipairs(view.tierB or {}) do
        tips[#tips + 1] = (tip.name or "") .. " (inferred)"
    end
    if #tips > 0 then
        add("Unverified tips: " .. table.concat(tips, ", "))
    end
    add("Notes: " .. notes)
    return table.concat(lines, "\n")
end

function M.SetSituation(key)
    if key ~= "pull" and key ~= "engaged" and key ~= "finish" and key ~= "pack" then
        return
    end
    M._situation = key
    if TA.QueueUIRefresh then TA:QueueUIRefresh("mage-guide") end
end

function M.Situation()
    return M._situation
end

function M.Gate()
    return M._gate == true
end

-- A throwing secret predicate fails closed. The check runs before any
-- comparison, length test, format, or table use of the value.
function Secret(value)
    local util = TA.Utils
    local pred = util and util.IsSecret
    if type(pred) ~= "function" then return false end
    local ok, result = pcall(pred, value)
    if not ok then return true end
    return result == true
end

function ShownString(value)
    if Secret(value) then return nil end
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

function ShownNumber(value)
    if Secret(value) then return nil end
    if type(value) ~= "number" then return nil end
    if value ~= value then return nil end
    if value == math.huge or value == -math.huge then return nil end
    return value
end

local function Plain(value)
    local number = ShownNumber(value)
    if number then return string.format("%.0f", number) end
    return ShownString(value)
end

local function Call(path, ...)
    local caps = TA.Caps
    if not caps or type(caps.Call) ~= "function" then return false, "missing" end
    return caps.Call(path, ...)
end

-- Item rows come from Compat, which picks the flavor's item API. A missing
-- or unreadable row is unknown. "no" is only a positive empty slot, a
-- positive non-wand, or a positive level the character has not reached.
local function ItemInfo(itemID)
    local compat = TA.Compat
    if not compat or type(compat.GetItemInfo) ~= "function" then return nil end
    local ok, _, _, _, _, reqLevel, _, _, _, equipLoc, _, _, classID, subclassID =
        pcall(compat.GetItemInfo, itemID)
    if not ok then return nil end
    if Secret(classID) or Secret(subclassID) or Secret(reqLevel) or Secret(equipLoc) then
        return nil
    end
    return {
        reqLevel = reqLevel,
        equipLoc = equipLoc,
        classID = classID,
        subclassID = subclassID,
    }
end

function M.ReadWand(call, level)
    if type(call) ~= "function" then return "unknown" end
    local ok, itemID = call("GetInventoryItemID", "player", 18)
    if not ok then return "unknown" end
    if Secret(itemID) then return "unknown" end
    if itemID == nil or itemID == false then return "no" end
    if type(itemID) ~= "number" or itemID <= 0 then return "unknown" end
    local info = ItemInfo(itemID)
    if not info then return "unknown" end
    if type(info.classID) ~= "number" or type(info.subclassID) ~= "number" then
        return "unknown"
    end
    if info.classID ~= 2 or info.subclassID ~= 19 then return "no" end
    if type(info.equipLoc) == "string" and info.equipLoc ~= ""
        and info.equipLoc ~= "INVTYPE_RANGED" and info.equipLoc ~= "INVTYPE_RANGEDRIGHT" then
        return "unknown"
    end
    if type(info.reqLevel) ~= "number" or type(level) ~= "number" then return "unknown" end
    if info.reqLevel > level then return "no" end
    return "yes"
end

local function AddSpell(book, sp)
    if type(sp) ~= "table" then return end
    if Secret(sp.name) or Secret(sp.spellID) then return end
    local name, spellID
    if type(sp.name) == "string" and sp.name ~= "" and sp.name ~= "secret" then
        name = sp.name
    end
    if type(sp.spellID) == "number" then spellID = sp.spellID end
    if not name and not spellID then return end
    book[#book + 1] = { name = name, spellID = spellID }
end

local function SpellbookFrom(spellLines)
    local book = {}
    local incomplete = false
    if type(spellLines) ~= "table" then return book, true end
    local function consider(sp)
        if type(sp) ~= "table" then
            incomplete = true
            return
        end
        if Secret(sp.name) or Secret(sp.spellID) then
            incomplete = true
            return
        end
        local before = #book
        AddSpell(book, sp)
        if #book == before and sp.name ~= nil and sp.spellID ~= nil then
            incomplete = true
        end
    end
    for _, row in ipairs(spellLines) do
        if type(row) == "table" and type(row.spells) == "table" then
            for _, sp in ipairs(row.spells) do consider(sp) end
        else
            consider(row)
        end
    end
    return book, incomplete
end

local function Ask(id)
    if type(id) ~= "number" then return "unknown" end
    local function one(path)
        local ok, value = Call(path, id)
        if not ok then return "unknown" end
        if Secret(value) then return "unknown" end
        if value == true then return "yes" end
        if value == false then return "no" end
        return "unknown"
    end
    local first = one("IsPlayerSpell")
    local second = one("IsSpellKnown")
    if first == "yes" or second == "yes" then return "yes" end
    if first == "unknown" or second == "unknown" then return "unknown" end
    if first == "no" and second == "no" then return "no" end
    return "unknown"
end

local function CapturedErrors()
    local log = TA.modules and TA.modules.ErrorLog
    if not log and TA.GetModule then
        local ok, mod = pcall(TA.GetModule, TA, "ErrorLog")
        if ok then log = mod end
    end
    if not log or type(log.GetLog) ~= "function" then return nil end
    local ok, entries = pcall(log.GetLog, log)
    if not ok or type(entries) ~= "table" then return nil end
    local out = {}
    for _, entry in ipairs(entries) do
        if type(entry) == "table" then
            out[#out + 1] = {
                time = type(entry.time) == "string" and entry.time or "",
                source = type(entry.source) == "string" and entry.source or "",
                msg = type(entry.msg) == "string" and entry.msg or "",
            }
        end
    end
    return out
end

function M.ReadLive(spellLines, readStatus)
    local status = readStatus
    if status ~= "read" and status ~= "unreadable" and status ~= "incomplete" then
        status = type(spellLines) == "table" and "read" or "unreadable"
    end
    local book = {}
    if status == "read" then
        local incomplete
        book, incomplete = SpellbookFrom(spellLines)
        if incomplete then status = "incomplete" end
    end
    local ctx = {
        spellbook = book,
        spellbookRead = status,
        ask = Ask,
        situationObserved = false,
        errors = CapturedErrors(),
    }
    local levelOk, level = Call("UnitLevel", "player")
    if levelOk then
        local number = ShownNumber(level)
        if number then ctx.level = number end
    end
    local classOk, _, token = Call("UnitClass", "player")
    if classOk then
        local name = ShownString(token)
        if name then ctx.class = name end
    end
    local buildOk, _, build, _, iface = Call("GetBuildInfo")
    if buildOk then
        ctx.build = Plain(build)
        ctx.interface = Plain(iface)
    end
    local version = ShownString(TA.version)
    if version then ctx.version = version end
    ctx.wand = M.ReadWand(Call, ctx.level)
    ctx.shootKnown = "unknown"
    if ctx.spellbookRead == "read" or ctx.spellbookRead == "incomplete" then
        for _, sp in ipairs(ctx.spellbook) do
            if not Secret(sp.name) and sp.name == "Shoot" then
                ctx.shootKnown = "yes"
            end
        end
    end
    return ctx
end

local function Remember(prior)
    if type(prior) ~= "table" or prior.withheld then return end
    M._historical = {
        historical = true,
        wand = prior.wand,
        className = prior.class,
        level = prior.level,
        shootKnown = prior.shootKnown,
    }
end

local function Withheld(fresh)
    local held = {
        withheld = true,
        spellbook = {},
        spellbookRead = "unreadable",
        wand = "unknown",
        shootKnown = "unknown",
        situationObserved = false,
        historical = M._historical,
    }
    -- Fresh negatives stay. A positive wand or learned spell is not current
    -- proof while class or level is unknown, and the previous yes is not copied back.
    if type(fresh) == "table" then
        if fresh.wand == "no" or fresh.wand == "unknown" then
            held.wand = fresh.wand
        end
        if fresh.spellbookRead == "read" or fresh.spellbookRead == "incomplete" then
            held.spellbook = fresh.spellbook or {}
            held.spellbookRead = fresh.spellbookRead
            held.shootKnown = fresh.shootKnown == "yes" and "yes" or "unknown"
        end
    end
    return held
end

local function ClearScope(fresh, className, level)
    M._scope = false
    M._historical = nil
    M._gate = false
    if type(fresh) == "table" then
        fresh.class = className
        fresh.level = level
        fresh.withheld = nil
        fresh.placed = nil
        M._ctx = fresh
    else
        M._ctx = nil
    end
end

function M.RefreshGate(spellLines, readStatus)
    local ok, ctx = pcall(M.ReadLive, spellLines, readStatus)
    local fresh = (ok and type(ctx) == "table") and ctx or nil
    local className = fresh and ShownString(fresh.class) or nil
    local level = fresh and ShownNumber(fresh.level) or nil
    -- A positive other class, or a positive level outside 10-19, ends the
    -- guide even when the other field could not be read.
    if className and className ~= "MAGE" then
        ClearScope(fresh, className, level)
        return false
    end
    if level and (level < 10 or level > 19) then
        ClearScope(fresh, className, level)
        return false
    end
    if not className or not level then
        -- Only a guide that was actually shown for Mage 10-19 may stay up.
        if M._scope == true then
            Remember(M._ctx)
            local held = Withheld(fresh)
            held.placed = true
            M._ctx = held
            M._gate = true
            return true
        end
        M._gate = false
        M._ctx = nil
        return false
    end
    fresh.class = className
    fresh.level = level
    fresh.withheld = nil
    fresh.placed = nil
    M._historical = nil
    M._ctx = fresh
    local inBand = M.Applies(fresh) and true or false
    M._scope = inBand
    M._gate = inBand
    return M._gate
end

function M.Context()
    local ctx = M._ctx
    if type(ctx) ~= "table" then ctx = {} end
    ctx.situation = M._situation
    return ctx
end

local function HideBox(name)
    local box = _G[name]
    if box and box.Hide then box:Hide() end
end

local function FontFile()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function ApplyBoxChrome(box)
    if not box then return end
    if box.SetFontObject and GameFontHighlightSmall then
        box:SetFontObject(GameFontHighlightSmall)
    end
    if box.SetFont then box:SetFont(FontFile(), 10, "") end
    if box.SetAutoFocus then box:SetAutoFocus(false) end
    if box.SetTextColor then box:SetTextColor(0.92, 0.90, 0.87, 1) end
    if box.EnableMouse then box:EnableMouse(true) end
    if box.SetBackdrop then
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        if box.SetBackdropColor then box:SetBackdropColor(0.05, 0.05, 0.05, 0.95) end
        if box.SetBackdropBorderColor then
            box:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.90)
        end
    end
end

local function BindFocus(box)
    if not box or not box.SetScript then return end
    local function release(self)
        if self and self.ClearFocus then self:ClearFocus() end
    end
    box:SetScript("OnEscapePressed", release)
    box:SetScript("OnEnterPressed", release)
end

-- RebuildChild detaches every child of the Spells pane, and SetParent on
-- the way back detaches that frame's own children. Capture them first and
-- put them back on the same frame.
local function Attach(frame, parent)
    if not frame then return end
    local kids = {}
    if frame.GetChildren then
        for _, kid in ipairs({ frame:GetChildren() }) do
            kids[#kids + 1] = kid
        end
    end
    if parent and frame.SetParent then frame:SetParent(parent) end
    for _, kid in ipairs(kids) do
        if kid.SetParent then kid:SetParent(frame) end
        if kid.Show then kid:Show() end
    end
    if frame.Show then frame:Show() end
end

local function Box(name, parent)
    local box = _G[name]
    if not box then
        if type(CreateFrame) ~= "function" then return nil end
        box = CreateFrame("EditBox", name, parent, "BackdropTemplate")
        _G[name] = box
    else
        Attach(box, parent)
    end
    if box.Show then box:Show() end
    ApplyBoxChrome(box)
    BindFocus(box)
    return box
end

local COPY_VIEW_H = 200
local COPY_W = 460
-- 460px well minus the scroll-bar column. The font string is measured at
-- this width with the same font the edit box uses.
local COPY_TEXT_W = 432

-- Layout.lua measures a paragraph the same way: set the font, the text, and
-- the wrap width, clear the height so the string is not clamped, then read
-- GetStringHeight. An edit box does not provide that measurement.
local function MeasureText(text)
    if type(CreateFrame) ~= "function" then return nil end
    local host = _G.TAMageGuideMeasure
    if not (host and host.CreateFontString) then
        host = CreateFrame("Frame", "TAMageGuideMeasure", UIParent)
        if host.Hide then host:Hide() end
        if not host.CreateFontString then return nil end
        _G.TAMageGuideMeasure = host
    end
    local fs = host._measure
    if not fs then
        fs = host:CreateFontString(nil, "OVERLAY")
        host._measure = fs
    end
    if not fs or not fs.SetText or not fs.GetStringHeight then return nil end
    if fs.SetFont then fs:SetFont(FontFile(), 10, "") end
    fs:SetText(text or "")
    if fs.SetWidth then fs:SetWidth(COPY_TEXT_W) end
    if fs.SetHeight then fs:SetHeight(0) end
    local h = fs:GetStringHeight()
    if type(h) ~= "number" or h <= 0 then return nil end
    return h
end

local function ScrollFrame(name, parent)
    local frame = _G[name]
    if not frame then
        if type(CreateFrame) ~= "function" then return nil end
        frame = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
        _G[name] = frame
    else
        Attach(frame, parent)
    end
    if frame.Show then frame:Show() end
    return frame
end

-- The visible well stays COPY_VIEW_H. The edit box is the scroll child and
-- is as tall as the measured text, so lines past the well stay reachable
-- and Ctrl+A still selects the whole generated string.
local function FitFeedback(scroll, copy, content, y, text)
    if copy and copy.SetText then copy:SetText(text or "") end
    local textH = MeasureText(text)
    if not textH or textH < COPY_VIEW_H then textH = COPY_VIEW_H end
    -- Multiline edit boxes do not grow to their text. The height has to be set.
    if copy and copy.SetSize then copy:SetSize(COPY_TEXT_W, textH) end
    if scroll then
        if scroll.SetSize then scroll:SetSize(COPY_W, COPY_VIEW_H) end
        if scroll.SetPoint then
            scroll:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
        end
        if scroll.SetScrollChild and copy then scroll:SetScrollChild(copy) end
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
        if scroll.EnableMouse then scroll:EnableMouse(true) end
    elseif copy and copy.SetPoint then
        copy:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
    end
    return y - COPY_VIEW_H - 8
end

function M.Paint(content, y, L, view)
    if not view or not view.applies or not L then
        HideBox("TAMageGuideCopyScroll")
        HideBox("TAMageGuideCopy")
        HideBox("TAMageGuideNotes")
        return y
    end
    y = L:SectionHeader(content, y, "EXPERIMENTAL SPELL GUIDE", view.experimentalLine)
    y = L:Paragraph(content, y, view.headline or "")
    if view.why and view.why ~= "" then
        y = L:Paragraph(content, y, view.why)
    end
    if view.changes and view.changes ~= "" then
        y = L:Paragraph(content, y, view.changes)
    end
    if view.situationLine then
        y = L:Paragraph(content, y, view.situationLine)
    end
    if view.rankHint then
        y = L:Paragraph(content, y, view.rankHint)
    end
    y = L:Paragraph(content, y, "No talent-point recommendation. This is a spell guide only.")
    y = L:Paragraph(content, y, "Confirmed learned: " .. JoinNames(view.learned, true))
    y = L:Paragraph(content, y, "Unknown: " .. JoinNames(view.unknown, false))
    y = L:Paragraph(content, y, "Shoot: " .. (view.shootKnown or "unknown")
        .. ". Ranged-slot wand type and required level: " .. (view.wand or "unknown") .. ".")
    if view.tierB and #view.tierB > 0 then
        y = L:Paragraph(content, y, "Unverified tips, not an optimum")
        for _, tip in ipairs(view.tierB) do
            y = L:Bullet(content, y, tip.name .. " - " .. tip.why)
        end
    end
    local function choice(key, label)
        return {
            label = label,
            active = view.situation == key,
            onClick = function() M.SetSituation(key) end,
        }
    end
    y = L:ButtonRow(content, y, {
        choice("pull", "Pulling at range"),
        choice("engaged", "Enemy has reached me"),
        choice("finish", "Low health or no mana"),
        choice("pack", "Several mobs, solo"),
    })
    y = L:Paragraph(content, y,
        "Click the feedback box or Select feedback text. Escape or Enter leaves the box. Then Ctrl+A and Ctrl+C. That selects the full generated feedback, including the lines past the first screen. The game does not let an addon put text on the clipboard. Use the feedback scroll bar to read past the viewport. The mouse wheel may still move the Spells tab. This path was not checked on a live client. Use the notes line for what felt wrong or what to tune.")
    local scroll = ScrollFrame("TAMageGuideCopyScroll", content)
    local copy = Box("TAMageGuideCopy", scroll or content)
    local notes = Box("TAMageGuideNotes", content)
    M._lastView = view
    if copy and copy.SetMultiLine then copy:SetMultiLine(true) end
    local anchor = y
    local feedbackText = M.Feedback(view, M._notes or "")
    y = FitFeedback(scroll, copy, content, anchor, feedbackText)
    y = L:Paragraph(content, y, "What felt wrong / what to tune")
    if notes then
        if notes.SetTextInsets then notes:SetTextInsets(6, 6, 0, 0) end
        if notes.SetSize then notes:SetSize(460, 22) end
        if notes.SetPoint then notes:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y) end
        y = y - 28
    end
    M._painting = true
    if notes and notes.SetScript then
        notes:SetScript("OnTextChanged", function(self)
            if M._painting then return end
            local text = ""
            if self and self.GetText then text = self:GetText() or "" end
            if type(text) ~= "string" then text = "" end
            M._notes = text
            if M._lastView then
                FitFeedback(scroll, copy, content, anchor, M.Feedback(M._lastView, text))
            end
        end)
    end
    if notes and notes.SetText then notes:SetText(M._notes or "") end
    if copy and copy.SetText then
        copy:SetText(M.Feedback(view, M._notes or ""))
    end
    M._painting = false
    y = L:ButtonRow(content, y, {
        {
            label = "Select feedback text",
            onClick = function()
                if copy and copy.SetFocus then copy:SetFocus() end
                if copy and copy.HighlightText then copy:HighlightText() end
            end,
        },
    })
    return y
end

return M
