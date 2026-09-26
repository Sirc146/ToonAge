-- ToonAge/Modules/Automation/AutoQuest.lua
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Auto-accept and auto-turn-in used to live inside QuestTracker, buried in the
-- guide stack. That was fine while every flavour shipped guides. It stopped
-- being fine the moment Forever shipped without them: dropping the guide
-- dropped the tracker, and the tracker took auto-quest down with it, so the
-- feature simply had nowhere to run. "Auto accept isn't working" on Forever was
-- not a bug in the handler -- the handler was never loaded.
--
-- So the automation lives here now, on its own, depending on nothing but the
-- quest API. QuestTracker keeps its copy for the flavours that have it, and
-- this module STANDS DOWN whenever a live QuestTracker is present, because
-- handling QUEST_COMPLETE twice picks the reward twice.
--
-- Every client call goes through Try(). Forever's API set is only partly
-- mapped, and an unguarded call to an absent function is exactly the failure
-- that took GatherTracker offline on the same client.
--
-- Nothing here is on by default. Quest turn-ins spend things you cannot get
-- back, so the switches live in the Automation tab and start OFF.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local AQ = {}
TA:RegisterModule("AutoQuest", AQ)

AQ.frames = {}

-- ── Guarded client calls ──────────────────────────────────────────────────

--- Calls fn only when this client really has it, and swallows errors from it.
--- nil means "no answer" -- never a fabricated zero or false.
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g
end

-- ── Settings access ───────────────────────────────────────────────────────
--
-- Read without creating: charDB.tracker being nil is how onboarding knows no
-- layout preset was ever applied, and pre-creating it would convert "never
-- set" into "set to empty" across the presence checks that rely on it. The
-- table is created at the WRITE site only, when the player flips a switch.

local function Get(key)
    return TA.charDB and TA.charDB.tracker and TA.charDB.tracker[key] == true
end

local function Set(key, value)
    if not TA.charDB then return end
    TA.charDB.tracker = TA.charDB.tracker or {}
    TA.charDB.tracker[key] = value
end

local function Toggle(key)
    Set(key, not Get(key))
end

-- ── Safety lists ──────────────────────────────────────────────────────────
--
-- NPCs and quests whose turn-in spends currency, consumes materials, or locks
-- a permanent choice. None of these should ever be clicked by a machine.
-- Carried over verbatim from QuestTracker so the two paths behave identically.

local NPC_BLOCKLIST = {
    -- Bonus-roll / seal vendors (spend currency)
    [111243] = true, [87391] = true, [142063] = true, [199257] = true,
    -- Wartime donation NPCs (consume trade goods)
    [142564] = true, [142993] = true, [143004] = true,
    [143005] = true, [143006] = true, [143007] = true,
    -- Faction choices that lock a path
    [18166]  = true,
    -- Reputation token turn-ins
    [18257]  = true, [18252] = true,
}

local QUEST_BLOCKLIST = {
    -- Threads of Fate / campaign skips (irreversible)
    [62716] = true, [62714] = true, [60972] = true,
    -- Dragonflight waygate skips
    [72366] = true, [72367] = true,
}

-- ── Should this module act at all? ────────────────────────────────────────

--- True when something else already owns auto-quest on this client.
--- QuestTracker ships the same handler for the guide flavours; both running
--- means AcceptQuest() twice and, worse, a reward picked twice.
local function TrackerOwnsIt()
    local QT = TA:GetModule("QuestTracker")
    return QT ~= nil and QT.HandleAutoQuest ~= nil
end

local function ShouldAct()
    if not Get("autoQuest") then return false end
    if TrackerOwnsIt() then return false end
    -- Shift is the universal "not this one" override.
    if Try(IsShiftKeyDown) then return false end
    -- Zygor drives accept/turn-in/rewards itself.
    if U and U.DeferToZygor and U.DeferToZygor() then return false end
    return true
end

local function BlockedNPC()
    local guid = Try(UnitGUID, "npc") or Try(UnitGUID, "questnpc") or ""
    -- UnitGUID can hand back an opaque "secret" value under execution taint;
    -- :match() on one of those throws, so the match is guarded too.
    local idStr = Try(string.match, guid, "Creature%-0%-%d+%-%d+%-%d+%-(%d+)")
    local id = idStr and tonumber(idStr) or nil
    return id ~= nil and NPC_BLOCKLIST[id] == true
end

-- ── Handlers ──────────────────────────────────────────────────────────────

function AQ:OnQuestDetail()
    local questID = Try(GetQuestID)
    if questID and QUEST_BLOCKLIST[questID] then return end

    -- A quest offered by another PLAYER is a share. Accept shares only from
    -- friends and guildmates; a stranger's share is how you get dragged into
    -- something you did not ask for.
    local fromTrigger = Try(QuestIsFromAreaTrigger)
    local offeredByPlayer = (fromTrigger ~= true) and Try(UnitIsPlayer, "questnpc")
    if offeredByPlayer then
        local name = Try(UnitName, "questnpc")
        local isFriend = name and (
            (C_FriendList and Try(C_FriendList.IsFriend, name))
            or (C_BattleNet and Try(C_BattleNet.GetAccountInfoByGUID, Try(UnitGUID, "questnpc")))
        )
        local isGuild = name and Try(IsInGuild) and Try(UnitIsInMyGuild, "questnpc")
        if not isFriend and not isGuild then return end
    end

    Try(AcceptQuest)
    if QuestFrame and Try(QuestFrame.IsShown, QuestFrame) then
        Try(HideUIPanel, QuestFrame)
    end
end

function AQ:OnQuestProgress()
    -- Never auto-complete something that costs money.
    if Try(QuestProgressRequiresGold) then return end
    local toGet = Try(GetQuestMoneyToGet)
    if toGet and toGet > 0 then return end

    -- Never hand over crafting reagents automatically: the player may well be
    -- saving them for a profession rather than a quest.
    local numItems = Try(GetNumQuestItems) or 0
    for i = 1, numItems do
        local _, _, numRequired = Try(GetQuestItemInfo, "required", i)
        if numRequired and numRequired > 0 then
            local link = Try(GetQuestItemLink, "required", i)
            if link then
                local itemType, itemSubType
                if C_Item and C_Item.GetItemInfo then
                    local _, _, _, _, _, t, s = Try(C_Item.GetItemInfo, link)
                    itemType, itemSubType = t, s
                else
                    local _, _, _, _, _, t, s = Try(GetItemInfo, link)
                    itemType, itemSubType = t, s
                end
                if itemType == "Tradeskill" or itemSubType == "Reagent" then return end
            end
        end
    end

    if Try(IsQuestCompletable) then Try(CompleteQuest) end
end

function AQ:OnQuestComplete()
    local numChoices = Try(GetNumQuestChoices) or 0

    -- Nothing to decide: finish it.
    if numChoices <= 1 then
        Try(GetQuestReward, numChoices == 1 and 1 or nil)
        return
    end

    -- More than one reward. This deliberately does NOT click for you by
    -- default. A reward choice is one of the few permanent, personal decisions
    -- in levelling -- a weapon kept for the look, a piece for an offspec,
    -- something to sell. Automation that answers it for you is the kind people
    -- switch off. So ToonAge scores the options, says which it likes, and
    -- leaves the window open.
    local bestIdx, bestScore = 1, -1
    local GearMod = TA:GetModule("Gear")
    for i = 1, numChoices do
        local link = Try(GetQuestItemLink, "choice", i)
        if link then
            local score = (U and U.GetItemIlvl and U.GetItemIlvl(link)) or 0
            if GearMod and GearMod.CalculateItemScore then
                local specID = U and U.GetPlayerSpec and U.GetPlayerSpec()
                local s = Try(GearMod.CalculateItemScore, link, specID,
                              (TA.charDB and TA.charDB.pvxMode) or "pve")
                if type(s) == "number" and s > 0 then score = s end
            end
            if score > bestScore then bestScore, bestIdx = score, i end
        end
    end

    if Get("autoRewardPick") then
        Try(GetQuestReward, bestIdx)
        return
    end

    local bestLink = Try(GetQuestItemLink, "choice", bestIdx)
    local name = (bestLink and Try(GetItemInfo, bestLink)) or ("choice " .. bestIdx)
    TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r %d rewards to choose from — paused for you. ")
          :format(numChoices)
          .. ("Best for you looks like |cFF4AFF7A%s|r."):format(tostring(name)))
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780Pick one to finish the turn-in. "
          .. "Automation → Auto-pick quest rewards makes ToonAge choose instead.|r")
end

function AQ:OnGossip()
    if not C_GossipInfo then return end

    -- Turn in what is ready, then take what is offered. Order matters: a
    -- turn-in can unlock the follow-up sitting in the same gossip window.
    local active = Try(C_GossipInfo.GetActiveQuests)
    if type(active) == "table" then
        for _, q in ipairs(active) do
            if q.isComplete and not (q.questID and QUEST_BLOCKLIST[q.questID]) then
                Try(C_GossipInfo.SelectActiveQuest, q.questID or q.index)
                return
            end
        end
    end

    local available = Try(C_GossipInfo.GetAvailableQuests)
    if type(available) == "table" then
        for _, q in ipairs(available) do
            if not (q.questID and QUEST_BLOCKLIST[q.questID]) then
                Try(C_GossipInfo.SelectAvailableQuest, q.questID or q.index)
                return
            end
        end
    end
end

function AQ:OnEvent(event)
    if not ShouldAct() then return end
    if BlockedNPC() then return end

    if     event == "QUEST_DETAIL"   then self:OnQuestDetail()
    elseif event == "QUEST_PROGRESS" then self:OnQuestProgress()
    elseif event == "QUEST_COMPLETE" then self:OnQuestComplete()
    elseif event == "GOSSIP_SHOW"    then self:OnGossip()
    elseif event == "QUEST_GREETING" then
        -- Vanilla-era greeting frame: take the first available quest.
        local numAvailable = Try(GetNumAvailableQuests) or 0
        if numAvailable > 0 then Try(SelectAvailableQuest, 1) end
        local numActive = Try(GetNumActiveQuests) or 0
        if numActive > 0 then Try(SelectActiveQuest, 1) end
    end
end

-- ── Tab ───────────────────────────────────────────────────────────────────
--
-- Buttons, not slash commands. On Forever this is the only place these
-- switches exist, because the Settings tab there is the guide-stack one.

local function ToggleRow(parent, y, width, label, note, key)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width - 28, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
                      edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    row:SetBackdropColor(0.06, 0.06, 0.06, 1)

    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(10, 10)
    dot:SetPoint("LEFT", row, "LEFT", 6, 0)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    lbl:SetText(label)
    lbl:SetTextColor(0.88, 0.83, 0.65, 1)
    lbl:SetPoint("LEFT", row, "LEFT", 22, 0)

    local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    status:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    local function Refresh()
        if Get(key) then
            dot:SetColorTexture(0.20, 0.92, 0.40, 1)
            status:SetText("|cFF4AFF7AON|r")
            row:SetBackdropBorderColor(0.20, 0.60, 0.30, 0.6)
        else
            dot:SetColorTexture(0.65, 0.20, 0.15, 1)
            status:SetText("|cFFFF4444OFF|r")
            row:SetBackdropBorderColor(0.30, 0.25, 0.08, 0.4)
        end
    end

    row:SetScript("OnClick", function() Toggle(key); Refresh() end)
    row:SetScript("OnEnter", function(f) f:SetBackdropColor(0.12, 0.10, 0.04, 1) end)
    row:SetScript("OnLeave", function(f) f:SetBackdropColor(0.06, 0.06, 0.06, 1) end)
    Refresh()
    table.insert(AQ.frames, row)

    y = y - 24
    if note then
        local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetFont(STANDARD_TEXT_FONT, 9, "")
        hint:SetText(note)
        hint:SetTextColor(0.53, 0.53, 0.50, 1)
        hint:SetWidth(width - 44)
        hint:SetJustifyH("LEFT")
        hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 22, y)
        table.insert(AQ.frames, hint)
        y = y - (hint:GetStringHeight() + 8)
    end
    return y - 4
end

function AQ:Render(content, side)
    local L = TA.Layout
    if not L then return end
    local w = L:Width(content)
    local y = -14

    y = L:SectionHeader(content, y, "Questing",
        "Hold Shift as a window opens to skip automation that once.")

    y = ToggleRow(content, y, w, "Auto-accept and turn in quests",
        "Accepts what an NPC offers and hands in what is finished. "
        .. "Quests that cost gold or consume crafting reagents are never "
        .. "turned in automatically.", "autoQuest")

    y = ToggleRow(content, y, w, "Auto-pick quest rewards",
        "Off by default on purpose: when a quest offers a choice, ToonAge "
        .. "stops, names the option it rates highest, and lets you click. "
        .. "Turn this on to have it choose for you.", "autoRewardPick")

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "At a vendor",
        "Both are off by default: one spends gold, the other cannot be undone "
        .. "once buyback scrolls away.")

    y = ToggleRow(content, y, w, "Sell grey items",
        "Poor quality only, never anything the vendor values at nothing, and "
        .. "at most a dozen stacks per visit so the client's own rate limit "
        .. "does not swallow the rest.", "autoSellJunk")

    y = ToggleRow(content, y, w, "Repair all",
        "Repairs on opening a vendor, from your own money, and says what it "
        .. "cost. Skipped rather than part-paid when you cannot afford it.",
        "autoRepair")

    y = ToggleRow(content, y, w, "Repair from guild funds when allowed",
        "Uses the guild bank first if your rank has a repair allowance big "
        .. "enough to cover the bill, then falls back to your own purse.",
        "repairFromGuild")

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Cutscenes")
    y = ToggleRow(content, y, w, "Skip cutscenes",
        "Cancels in-engine scenes and pre-rendered movies as they start.",
        "cutsceneSkip")

    if TrackerOwnsIt() then
        y = L:Divider(content, y)
        y = L:Paragraph(content, y,
            "|cFF888780The quest tracker is handling questing automation on "
            .. "this client, so these switches defer to it.|r")
    end

    L:Finish(content, y)
end

-- ── Init ──────────────────────────────────────────────────────────────────

function AQ:Init()
    TA:RegisterEvent("QUEST_DETAIL")
    TA:RegisterEvent("QUEST_PROGRESS")
    TA:RegisterEvent("QUEST_COMPLETE")
    TA:RegisterEvent("QUEST_GREETING")
    TA:RegisterEvent("GOSSIP_SHOW")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r AutoQuest module loaded.")
    end
end
