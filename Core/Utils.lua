-- ToonAge/Core/Utils.lua
-- Shared utility functions available to all modules via ToonAge.Utils

local TA = ToonAge
TA.Utils = {}
local U = TA.Utils

-- ══════════════════════════════════════════════════════════════════════════════
-- ── TAINT SAFETY UTILITIES (12.0) ─────────────────────────────────────────────
-- WoW 12.0 marks many API return values as "secret" when addon execution is
-- tainted. These cannot be used in arithmetic, comparisons, or as table keys.
--
-- ⚠ THE CLAIM THAT USED TO BE HERE IS FALSE. This block previously read
-- "SafeNum strips the taint via tonumber(tostring(x))". Measured on retail
-- 12.0.7 with /ta secretprobe, it does not and cannot. Every route that pulls
-- a number OUT of a secret errors outright:
--
--     tonumber(v)            attempt to perform numeric conversion on a
--                            secret number value (execution tainted by 'ToonAge')
--     v + 0 / math.floor(v)  arithmetic on a secret number value
--     v > 0                  attempt to compare
--     t[v] = x               table cannot be indexed with secret keys
--     #tostring(v)           attempt to get length of a secret string value
--     tostring(v):match(..)  attempt to index a secret string value
--
-- tostring(v) alone survives and renders the true number on screen, which is
-- why a chat dump shows an ID a human can read while Lua cannot touch it.
-- tonumber(tostring(v)) therefore returns nil, and SafeNum falls through to
-- its fallback -- 0. That is not a conversion failure to be fixed; it is the
-- designed behaviour of the value.
--
-- 10 of 11 player buffs measured secret in combat. The one exception was
-- 404464 Flight Style: Skyriding. Combat-relevant aura data is secret;
-- cosmetic state is not.
--
-- SafeNum is still correct for ordinary values and is used widely, so it
-- stays. What it must NOT be relied on for is recovering an ID from aura
-- data -- it will hand back 0 and every `id > 0` guard downstream will
-- silently drop the aura. Ask about a known ID instead of reading one out.
-- ══════════════════════════════════════════════════════════════════════════════

--- Strip WoW chat markup, leaving plain text.
--- Shared by ChatCopy (so a paste reads the way the line looked) and by the
--- probe commands (so what lands in SavedVariables is machine-readable).
---
--- MUST be non-throwing. Secrecy is contagious through string.format: a line
--- built as ("%s"):format(tostring(aura.spellId)) is itself a SECRET STRING,
--- and every string method on it -- gsub, len, sub, match -- raises
--- "attempt to index a secret string value". That is not hypothetical; it
--- crashed the first version of this function on the line below, logged as
--- Core/Utils.lua:50 by the very probe it was added to serve.
---
--- A markup stripper is a formatting nicety. It must never be the reason a
--- caller dies, so a secret input yields a marker rather than an error, and
--- the caller keeps running.
--- @param s any
--- @return string plain, boolean wasSecret
function U.StripMarkup(s)
    if s == nil then return "", false end

    local ok, out = pcall(function()
        local t = tostring(s)
        t = t:gsub("|c%x%x%x%x%x%x%x%x", "")   -- colour open
        t = t:gsub("|C%x%x%x%x%x%x%x%x", "")
        t = t:gsub("|r", "")                    -- colour close
        t = t:gsub("|H.-|h(.-)|h", "%1")        -- hyperlink -> its display text
        t = t:gsub("|T.-|t", "")                -- inline texture
        t = t:gsub("|A.-|a", "")                -- inline atlas
        t = t:gsub("|n", "\n")
        return t
    end)

    if ok then return out, false end

    -- The value exists and renders on screen -- the chat frame resolves it in a
    -- secure context -- but no addon-side route can read it. Say so in the
    -- saved copy rather than dropping the row, so a gap is visible as a gap.
    return "<secret value -- readable on screen only>", true
end

--- Read the creature ID out of a unit's GUID, distinguishing "no NPC here"
--- from "the GUID exists but cannot be read".
---
--- In 12.0 a GUID can come back as a SECRET STRING, and every route into it --
--- match, sub, len -- raises "attempt to index a secret string value". Callers
--- that use the ID for a *safety* decision must be able to tell the two cases
--- apart: an absent NPC is a fact, an unreadable one is a blind spot, and only
--- the second is a reason to refuse to act.
---
--- Returns nil,true for "there is no NPC on any of these units" and nil,false
--- for "there is one, but its GUID is secret".
--- @param ... string unit tokens, tried in order
--- @return number|nil npcID, boolean readable
function U.ReadNpcID(...)
    for i = 1, select("#", ...) do
        local guid = UnitGUID((select(i, ...)))
        if guid then
            -- tonumber lives INSIDE the pcall on purpose. The measured block
            -- at the top of this file lists tonumber(v) as one of the routes
            -- that raises on a secret, and it is not established that :match
            -- against a secret string always raises rather than returning a
            -- secret substring. Guarding both makes the helper correct under
            -- either behaviour, which matters because callers use it to decide
            -- whether it is safe to act.
            local ok, id = pcall(function()
                local m = guid:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)")
                return m and tonumber(m) or nil
            end)
            if not ok then return nil, false end     -- secret: present but unreadable
            if id then return id, true end
        end
    end
    return nil, true                                 -- no NPC on any unit given
end

--- Convert a potentially tainted "secret number" to a safe Lua number.
--- Returns the number, or the fallback (default 0) if conversion fails.
--- @param val any — the potentially tainted value
--- @param fallback number|nil — value to return on failure (default 0)
--- @return number
function U.SafeNum(val, fallback)
    if val == nil then return fallback or 0 end
    local n = tonumber(tostring(val))
    return n or (fallback or 0)
end

--- Safely call a WoW API function that might return tainted values.
--- Returns: ok (bool), followed by sanitized return values (numbers are cleaned).
--- On failure, returns false and the fallback values.
--- @param func function — the function to call
--- @param ... any — arguments to pass
--- @return boolean, any...
function U.SafeCall(func, ...)
    local results = { pcall(func, ...) }
    if results[1] then
        -- Success — sanitize numeric returns
        for i = 2, #results do
            if type(results[i]) == "number" or type(results[i]) == "userdata" then
                results[i] = tonumber(tostring(results[i])) or 0
            end
        end
        return unpack(results)
    else
        return false
    end
end

--- Safely get a numeric value from a WoW API, returning fallback on taint/error.
--- Usage: local hp = U.SafeGetNum(UnitHealth, "player", 0)
--- @param func function
--- @param ... any — args to func (last numeric arg is NOT the fallback)
--- @return number
function U.SafeGetNum(func, ...)
    local ok, val = pcall(func, ...)
    if ok and val ~= nil then
        local n = tonumber(tostring(val))
        return n or 0
    end
    return 0
end

-- ── Colour helpers ────────────────────────────────────────────────────
U.GOLD    = "|cFFFFD100"
U.GREEN   = "|cFF4AFF7A"
U.ORANGE  = "|cFFFF9A1A"
U.RED     = "|cFFFF4444"
U.GREY    = "|cFF888780"
U.PURPLE  = "|cFF9988FF"
U.WHITE   = "|cFFFFFFFF"
U.CLOSE   = "|r"

function U.Colour(text, colour)
    return (colour or U.WHITE) .. tostring(text) .. U.CLOSE
end

function U.Gold(text)   return U.Colour(text, U.GOLD)   end
function U.Green(text)  return U.Colour(text, U.GREEN)  end
function U.Orange(text) return U.Colour(text, U.ORANGE) end
function U.Red(text)    return U.Colour(text, U.RED)    end

-- ── Item quality colours (matches WoW quality colour system) ─────────
local QUALITY_COLOURS = {
    [0] = "|cFF9D9D9D",  -- Poor (grey)
    [1] = "|cFFFFFFFF",  -- Common (white)
    [2] = "|cFF1EFF00",  -- Uncommon (green)
    [3] = "|cFF0070DD",  -- Rare (blue)
    [4] = "|cFFA335EE",  -- Epic (purple)
    [5] = "|cFFFF8000",  -- Legendary (orange)
    [6] = "|cFFE6CC80",  -- Artifact
    [7] = "|cFF0CF4EC",  -- Heirloom
}

function U.QualityColour(quality)
    return QUALITY_COLOURS[quality or 1] or QUALITY_COLOURS[1]
end

function U.ColourItemName(name, quality)
    return U.Colour(name, U.QualityColour(quality))
end

-- ── Number formatting ─────────────────────────────────────────────────
function U.FormatNumber(n)
    if not n then return "0" end
    n = math.floor(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fk", n / 1000)
    end
    return tostring(n)
end

function U.FormatIlvl(ilvl)
    return string.format("%d", math.floor(ilvl or 0))
end

-- ── Player identity ───────────────────────────────────────────────────
function U.GetPlayerName()
    return UnitName("player") or "Unknown"
end

function U.GetPlayerLevel()
    return UnitLevel("player") or 1
end

function U.GetPlayerClass()
    local _, class = UnitClass("player")
    return class or "UNKNOWN"
end

function U.GetPlayerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then return nil, nil, nil end
    local id, name, _, icon = GetSpecializationInfo(specIndex)
    return id, name, icon
end

function U.GetPlayerRole()
    local specIndex = GetSpecialization()
    if not specIndex then return "NONE" end
    local _, _, _, _, role = GetSpecializationInfo(specIndex)
    return role or "NONE"
end

function U.IsHealer()
    return U.GetPlayerRole() == "HEALER"
end

function U.IsTank()
    return U.GetPlayerRole() == "TANK"
end

function U.IsDPS()
    local role = U.GetPlayerRole()
    return role == "DAMAGER"
end

-- ── Group detection ───────────────────────────────────────────────────
function U.GetGroupType()
    if IsInRaid() then return "raid"
    elseif IsInGroup() then return "party"
    else return "solo" end
end

function U.GetGroupSize()
    if IsInRaid() then return GetNumGroupMembers()
    elseif IsInGroup() then return GetNumGroupMembers()
    else return 1 end
end

-- ── Zone detection ────────────────────────────────────────────────────
function U.GetCurrentZone()
    return GetRealZoneText() or "Unknown"
end

function U.GetCurrentMapID()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID
end

function U.IsInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance, instanceType
end

-- ── Spell utilities ───────────────────────────────────────────────────
function U.GetSpellName(spellID)
    local name = C_Spell.GetSpellName(spellID)
    return name
end

function U.GetSpellTexture(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.iconID
end

function U.IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        if C_SpellBook.IsSpellKnown(spellID) then return true end
    elseif IsSpellKnown and IsSpellKnown(spellID) then
        return true
    end
    return IsPlayerSpell(spellID) or false
end

--- Cooldown for a spell, normalised to the pre-11.0 (start, duration) shape.
--- Every caller in the addon should go through this rather than touching
--- C_Spell.GetSpellCooldown or the bare global directly — see .rules.md.
--- @return number start, number duration — both 0 when off cooldown/unknown
function U.GetSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if not info then return 0, 0 end
        return info.startTime or 0, info.duration or 0
    end
    local start, duration = GetSpellCooldown(spellID)
    if not start then return 0, 0 end
    return start, duration
end

--- Spell name/icon/castTime lookup. C_Spell.GetSpellInfo returns a table in
--- 11.0+; the bare global is a compat shim that Blizzard has been retiring
--- API-by-API, so route through here instead of calling either directly.
--- @return string|nil name, number|nil iconID, number|nil castTime
function U.GetSpellInfo(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if not info then return nil end
        return info.name, info.iconID, info.castTime
    end
    local name, _, icon, castTime = GetSpellInfo(spellID)
    return name, icon, castTime
end

-- ── Addon-presence utilities ──────────────────────────────────────────
--- Is another addon loaded? Used for optional interop checks only — ToonAge
--- never hard-depends on another addon (see .rules.md).
function U.IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

--- Returns the addon's display title, or nil if it isn't installed.
function U.GetAddOnTitle(name)
    if C_AddOns and C_AddOns.GetAddOnInfo then
        return select(2, C_AddOns.GetAddOnInfo(name))
    elseif GetAddOnInfo then
        return select(2, GetAddOnInfo(name))
    end
    return nil
end

-- ── Item utilities ────────────────────────────────────────────────────
function U.GetEquippedItemID(slot)
    return GetInventoryItemID("player", slot)
end

--- Single call site for GetItemInfo. The bare global is still current at
--- Interface 120007, but C_Item is where Blizzard is moving it — keeping one
--- wrapper means a future removal is a one-line fix, not a 19-site hunt.
function U.GetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    end
    return GetItemInfo(item)
end

-- ── Async item data ───────────────────────────────────────────────────
--
-- GetItemInfo returns nil for an item the client has not cached yet — common
-- right after login and whenever an item is seen for the first time. The usual
-- workaround is a retry loop on a timer. This is not that, because the game
-- already tells us exactly when the data lands.
--
-- GET_ITEM_INFO_RECEIVED is registered in Core/Init.lua's PERSISTENT_EVENTS and
-- fires with (itemID, success). Measured on 12.1.0, 2026-07-26:
--
--     GIIR#1  122284  true
--
-- Two things that measurement settled, neither of which was safe to assume:
--
--   * arg2 is a success boolean, so a genuinely bad item ID is distinguishable
--     from one that simply has not arrived. A fixed retry count cannot tell
--     those apart — it burns the same attempts on both and then gives up on
--     the good one, which is the failure it was supposed to prevent.
--   * the event fires repeatedly for the same itemID. Resolution therefore has
--     to be idempotent: callbacks are cleared before they run, so a duplicate
--     event finds nothing left to do.

local pendingItems = {}   -- itemID -> { callbacks = {fn,...}, requested = time }

-- Nothing should wait forever. If the event never arrives for an ID -- the
-- request silently dropped, or an ID the server never answers for at all --
-- callbacks would leak and their callers would hang waiting. This is the only
-- place a timer is involved, and it is a backstop, not the mechanism.
local ITEM_REQUEST_TIMEOUT = 10

--- Extract a numeric itemID from an ID or an item link.
--- Parsed rather than resolved through an API, so it cannot break when
--- Blizzard moves item functions between namespaces.
local function ToItemID(item)
    if type(item) == "number" then return item end
    if type(item) ~= "string" then return nil end
    return tonumber(item:match("item:(%d+)")) or tonumber(item)
end

--- Resolve `item`'s data now if the client has it, otherwise ask the server and
--- invoke `callback` when it arrives.
--- @param item number|string — itemID or item link
--- @param callback function|nil — called as callback(itemID, success)
--- @return boolean cached — true if data was already available (callback ran immediately)
function U.RequestItemInfo(item, callback)
    local itemID = ToItemID(item)
    if not itemID then
        if callback then callback(nil, false) end
        return false
    end

    -- Already cached? A non-nil name is the signal the whole tuple is populated.
    if U.GetItemInfo(itemID) then
        if callback then callback(itemID, true) end
        return true
    end

    local entry = pendingItems[itemID]
    if not entry then
        entry = { callbacks = {}, requested = GetTime() }
        pendingItems[itemID] = entry

        -- Test the member, not the namespace. C_Navigation.GetDestination was
        -- removed in 12.1.0 while C_Navigation itself stayed, and the resulting
        -- nil failed silently for weeks.
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end

        C_Timer.After(ITEM_REQUEST_TIMEOUT, function()
            local stale = pendingItems[itemID]
            if stale and stale.requested == entry.requested then
                U.OnItemInfoReceived(itemID, false)
            end
        end)
    end

    if callback then table.insert(entry.callbacks, callback) end
    return false
end

--- Called from Core/Init.lua's dispatcher on GET_ITEM_INFO_RECEIVED.
--- @param itemID number
--- @param success boolean — false means the server could not resolve this ID
function U.OnItemInfoReceived(itemID, success)
    local entry = pendingItems[itemID]
    if not entry then return end

    -- Clear BEFORE running callbacks. The event repeats for the same itemID,
    -- and a callback that requests another item must not see a half-torn-down
    -- entry for this one.
    pendingItems[itemID] = nil

    for _, callback in ipairs(entry.callbacks) do
        local ok, err = pcall(callback, itemID, success and true or false)
        if not ok and TA.ErrorLog then
            TA.ErrorLog:Log("RequestItemInfo callback", tostring(err), tostring(itemID))
        end
    end
end

--- How many item requests are outstanding. Diagnostics only.
function U.PendingItemCount()
    local n = 0
    for _ in pairs(pendingItems) do n = n + 1 end
    return n
end

function U.GetItemIlvl(itemLink)
    if not itemLink then return 0 end
    local _, _, _, ilvl = U.GetItemInfo(itemLink)
    return ilvl or 0
end

function U.GetItemQuality(itemLink)
    if not itemLink then return 1 end
    local _, _, quality = U.GetItemInfo(itemLink)
    return quality or 1
end

-- ── Average ilvl ──────────────────────────────────────────────────────
-- GetAverageItemLevel() returns: overall, equipped
-- "equipped" matches the character sheet exactly — best-of-two-rings,
-- two-hand vs dual-wield weighting, empty slot penalties all included.
function U.GetAverageIlvl()
    local _, equipped = GetAverageItemLevel()
    return math.floor(equipped or 0)
end

-- ── Talent utilities ──────────────────────────────────────────────────
function U.GetTalentString()
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end
    return C_Traits.GenerateImportString(configID)
end

-- True plus the spent rank when nodeID has points in the active config.
--
-- This passed treeID to C_Traits.GetNodeInfo until 2026-07-26. The signature is
-- (configID, nodeID) -- confirmed live in-game, and against TalentsHelpers.lua:448
-- and TalentsPvP.lua:89, which always had it right. The wrong form returned nil
-- for every node, so a fully-matching build scored as matching nothing, with no
-- error to explain it. Nothing called this yet, which is why it never surfaced.
--
-- The loop over config.treeIDs went with it: a node resolves from the config,
-- not from a tree, so iterating trees only repeated the same lookup.
function U.IsNodeSelected(nodeID)
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return false end
    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if nodeInfo and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
        return true, nodeInfo.activeRank
    end
    return false
end

-- ── Profession utilities ──────────────────────────────────────────────
function U.GetProfessions()
    local profs = {}
    local p1, p2, p3, p4, p5, p6 = GetProfessions()
    for _, profIndex in ipairs({p1, p2, p3, p4, p5, p6}) do
        if profIndex then
            local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(profIndex)
            if name then
                table.insert(profs, {
                    index    = profIndex,
                    name     = name,
                    icon     = icon,
                    rank     = rank,
                    maxRank  = maxRank,
                    skillLine = skillLine,
                })
            end
        end
    end
    return profs
end

-- ── Table utilities ───────────────────────────────────────────────────
function U.TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function U.CopyTable(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = U.CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function U.TableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

-- ── String utilities ──────────────────────────────────────────────────
function U.Trim(s)
    return s:match("^%s*(.-)%s*$")
end

function U.Truncate(s, len)
    if #s > len then
        return s:sub(1, len - 3) .. "..."
    end
    return s
end

-- ── Distance / travel ─────────────────────────────────────────────────
-- Flat-map approximation: WoW map coords are normalized [0,1]; this scale
-- factor converts normalized distance to approximate yards. Shared by
-- Arrow.lua (HUD waypoint) and QuestTracker.lua (in-window distance/ETA)
-- so both display identical numbers for the same step.
local YARD_SCALE = 2000

function U.ComputeDistance(px, py, tx, ty)
    local dx = (tx - px) * YARD_SCALE
    local dy = (ty - py) * YARD_SCALE
    return math.sqrt(dx * dx + dy * dy)
end

function U.FormatDistance(yards)
    if yards >= 1000 then
        -- Convert yards to meters (1 yd = 0.9144 m) before dividing into km —
        -- yards/1000 was being mislabeled "km", ~9% short of the real value.
        return string.format("%.1f km", (yards * 0.9144) / 1000)
    end
    return string.format("%d yds", math.floor(yards))
end

function U.FormatETA(yards, speed)
    if not speed or speed <= 0 then return "" end
    local secs = yards / speed
    if secs < 60 then
        return string.format("%ds", math.ceil(secs))
    else
        return string.format("%dm %ds", math.floor(secs / 60), math.ceil(secs % 60))
    end
end

-- ── Time formatting ───────────────────────────────────────────────────
function U.FormatTime(seconds)
    if seconds >= 3600 then
        return string.format("%dh %dm", math.floor(seconds/3600), math.floor((seconds%3600)/60))
    elseif seconds >= 60 then
        return string.format("%dm %ds", math.floor(seconds/60), math.floor(seconds%60))
    else
        return string.format("%ds", math.floor(seconds))
    end
end

-- ── Texture path helper ───────────────────────────────────────────────
function U.GetTextureStr(texturePath, size)
    size = size or 16
    return string.format("|T%s:%d|t", texturePath, size)
end

function U.GetSpellTextureStr(spellID, size)
    local tex = U.GetSpellTexture(spellID)
    if not tex then return "" end
    return U.GetTextureStr(tex, size or 16)
end

-- ── Smart Step Text Resolution ────────────────────────────────────────────────
-- Resolves placeholder step text ("Quest 12345") into real quest titles and
-- objective descriptions at display time using the live WoW API.
-- This makes generated guide stubs (from import_apr_routes.py) show real
-- quest names without requiring pre-authored text in the data files.

--- Resolve a guide step's display text. If the step has a real authored text
--- that isn't a placeholder, returns it as-is. Otherwise queries the API.
--- @param step table — guide step with .questID, .type, .text
--- @return string displayText — human-readable step description
function U.ResolveStepText(step)
    if not step then return "" end

    -- If text is already authored (not a placeholder), use it
    local text = step.text or ""
    if text ~= "" and not text:match("^Quest %d+$") then
        return text
    end

    -- No questID — nothing to resolve
    local qid = step.questID
    if not qid or qid == 0 then return text end

    -- Resolve quest title from the API
    local title = C_QuestLog.GetTitleForQuestID(qid)
    if not title or title == "" then
        -- Quest data might not be cached yet — return what we have
        return text
    end

    -- Build contextual text based on step type
    local stepType = step.type or "quest"
    if stepType == "pickup" then
        return "Pick up: " .. title
    elseif stepType == "turnin" then
        return "Turn in: " .. title
    elseif stepType == "quest" or stepType == "objective" then
        -- Try to get the current objective text for richer display
        local objectives = C_QuestLog.GetQuestObjectives(qid)
        if objectives and #objectives > 0 then
            -- Find first incomplete objective
            for _, obj in ipairs(objectives) do
                if not obj.finished and obj.text and obj.text ~= "" then
                    return title .. " — " .. obj.text
                end
            end
            -- All complete
            return title .. " (complete)"
        end
        return title
    else
        return title
    end
end

--- Resolve text for an array of steps (batch, for rendering lists).
--- Modifies nothing — returns a new display string per step.
--- @param steps table — array of guide steps
--- @param startIdx number
--- @param endIdx number
--- @return table — array of { idx = N, text = "resolved text" }
function U.ResolveStepTexts(steps, startIdx, endIdx)
    local results = {}
    for i = startIdx, endIdx do
        local step = steps[i]
        if step then
            results[#results + 1] = { idx = i, text = U.ResolveStepText(step) }
        end
    end
    return results
end

-- ── Auto-Pilot Mode ───────────────────────────────────────────────────────────
-- When no guide is active or the guide has stub coords, Auto-Pilot reads the
-- player's quest log directly and navigates to objectives using Blizzard's own
-- waypoint system. No pre-authored data required.

--- Get the best quest to navigate to right now (Auto-Pilot logic).
--- Priority: supertracked quest → closest objective → most progressed quest.
--- @return table|nil — { questID, title, mapID, x, y, objectiveText }
function U.GetAutoPilotTarget()
    -- Priority 1: Player's explicitly supertracked quest
    local superQID = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
                 and C_SuperTrack.GetSuperTrackedQuestID()
    if superQID and superQID > 0 then
        local target = U._BuildQuestTarget(superQID)
        if target then return target end
    end

    -- Priority 2: Find the quest with the closest waypoint
    local playerMap = C_Map.GetBestMapForUnit("player")
    if not playerMap then return nil end

    local bestTarget = nil
    local bestDist = 999999

    local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            if not C_QuestLog.IsQuestFlaggedCompleted(info.questID) then
                local target = U._BuildQuestTarget(info.questID)
                if target and target.x and target.y then
                    -- Estimate distance (simple map-unit distance)
                    local pos = C_Map.GetPlayerMapPosition(playerMap, "player")
                    if pos then
                        local px, py = pos:GetXY()
                        local dx = (target.x or 0) - px
                        local dy = (target.y or 0) - py
                        local dist = dx * dx + dy * dy
                        if dist < bestDist then
                            bestDist = dist
                            bestTarget = target
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

--- Build a navigation target from a quest ID using Blizzard's waypoint API.
--- @param questID number
--- @return table|nil — { questID, title, mapID, x, y, objectiveText }
function U._BuildQuestTarget(questID)
    if not questID or questID == 0 then return nil end

    local title = C_QuestLog.GetTitleForQuestID(questID) or ""

    -- Try GetNextWaypoint (gives the real objective location)
    local wpMap, wpX, wpY
    if C_QuestLog.GetNextWaypoint then
        local ok, m, x, y = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and m and x and y and (x ~= 0 or y ~= 0) then
            wpMap, wpX, wpY = m, x, y
        end
    end

    -- Fallback: GetNextWaypointForMap with current map
    if not wpMap and C_QuestLog.GetNextWaypointForMap then
        local playerMap = C_Map.GetBestMapForUnit("player")
        if playerMap then
            local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questID, playerMap)
            if ok and x and y and (x ~= 0 or y ~= 0) then
                wpMap, wpX, wpY = playerMap, x, y
            end
        end
    end

    if not wpMap then return nil end

    -- Get objective text
    local objText = ""
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if objectives then
        for _, obj in ipairs(objectives) do
            if not obj.finished and obj.text then
                objText = obj.text
                break
            end
        end
    end

    return {
        questID       = questID,
        title         = title,
        mapID         = wpMap,
        x             = wpX,
        y             = wpY,
        objectiveText = objText,
    }
end
