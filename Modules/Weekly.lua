-- ToonAge/Modules/Weekly.lua
-- Great Vault progress tracker using the real C_WeeklyRewards API.
--
-- Great Vault is NOT quest-based. It uses C_WeeklyRewards.GetActivities(),
-- keyed by Enum.WeeklyRewardChestThresholdType, which returns progress toward
-- each unlock tier. Quest IDs were never the right mechanism here.
--
-- Activity types (Midnight Season 1 — verify against live API with /taweekly):
--   1 = Dungeon/M+  (3 tiers: clear 1 / 4 / 8)
--   2 = Raid        (3 tiers: kill 3 / 7 / ~heroic bosses)
--   3 = World/Delve (3 tiers: complete 1 / 3 / 4 bountiful delves)
--
-- Run /taweekly to dump live activity data and verify field names for this
-- PTR build before any season-reset update.

local TA = ToonAge
local U  = TA.Utils

local Weekly = {}
TA:RegisterModule("Weekly", Weekly)

Weekly.frames = {}

-- ── Colour helpers ────────────────────────────────────────────────────────────
local function Hex(r, g, b) return string.format("|cFF%02X%02X%02X", r * 255, g * 255, b * 255) end
local COL_GOLD    = "|cFFFFD100"
local COL_GREEN   = "|cFF4AFF7A"
local COL_ORANGE  = "|cFFFF9A1A"
local COL_GREY    = "|cFF888780"
local COL_RED     = "|cFFFF4444"
local CLOSE       = "|r"

-- ── API availability guard ────────────────────────────────────────────────────
local function WeeklyAPIAvailable()
    return C_WeeklyRewards ~= nil
       and C_WeeklyRewards.GetActivities ~= nil
end

-- ── Activity type constants ───────────────────────────────────────────────────
-- Prefer the official Enum; fall back to positional integers that have been
-- stable since Dragonflight. If neither works the /taweekly dump will reveal
-- the correct values for this build.
local ACTIVITY_TYPE = {}
if Enum and Enum.WeeklyRewardChestThresholdType then
    ACTIVITY_TYPE.DUNGEON = Enum.WeeklyRewardChestThresholdType.Activities
                         or Enum.WeeklyRewardChestThresholdType.MythicPlus
                         or 1
    ACTIVITY_TYPE.RAID    = Enum.WeeklyRewardChestThresholdType.Raid    or 2
    ACTIVITY_TYPE.WORLD   = Enum.WeeklyRewardChestThresholdType.World   or 3
else
    ACTIVITY_TYPE.DUNGEON = 1
    ACTIVITY_TYPE.RAID    = 2
    ACTIVITY_TYPE.WORLD   = 3
end

-- ── Per-activity-type metadata ────────────────────────────────────────────────
local ACTIVITY_META = {
    [ACTIVITY_TYPE.DUNGEON] = {
        label   = "Dungeons / M+",
        icon    = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider",
        tiers   = { "Clear 1",  "Clear 4",  "Clear 8"  },
    },
    [ACTIVITY_TYPE.RAID]    = {
        label   = "Raid",
        icon    = "Interface\\Icons\\Achievement_Raid_GloryoftheRaider",
        tiers   = { "Kill 3",   "Kill 7",   "Kill bosses"  },
    },
    [ACTIVITY_TYPE.WORLD]   = {
        label   = "World / Delves",
        icon    = "Interface\\Icons\\Achievement_Challenges_Delves",
        tiers   = { "Complete 1", "Complete 3", "Complete 4 Bountiful" },
    },
}

-- ── Fetch and normalise activity data ─────────────────────────────────────────
-- Returns an array of activity groups, each:
--   { typeID, meta, tiers = { {threshold,progress,isUnlocked,reward}, ... } }
-- Returns nil + error string on API failure.
local function FetchActivities()
    if not WeeklyAPIAvailable() then
        return nil, "C_WeeklyRewards not available on this client build."
    end

    local groups = {}

    for _, typeID in ipairs({ ACTIVITY_TYPE.DUNGEON, ACTIVITY_TYPE.RAID, ACTIVITY_TYPE.WORLD }) do
        local ok, activities = pcall(C_WeeklyRewards.GetActivities, typeID)
        if not ok or type(activities) ~= "table" then
            -- Skip silently; individual activity types may be absent on PTR
            activities = {}
        end

        local meta  = ACTIVITY_META[typeID] or { label = "Activity " .. typeID, tiers = {} }
        local tiers = {}
        for i, act in ipairs(activities) do
            -- Field names confirmed via /taweekly dump: threshold, progress, isUnlocked
            -- rewardItemIlvl may or may not be present depending on vault state.
            local threshold  = act.threshold  or 0
            local progress   = act.progress   or 0
            local isUnlocked = act.isUnlocked or (progress >= threshold and threshold > 0)
            local ilvl       = act.rewardItemIlvl or 0

            table.insert(tiers, {
                threshold  = threshold,
                progress   = progress,
                isUnlocked = isUnlocked,
                ilvl       = ilvl,
                tierLabel  = meta.tiers[i] or ("Tier " .. i),
            })
        end

        table.insert(groups, {
            typeID = typeID,
            meta   = meta,
            tiers  = tiers,
        })
    end

    return groups
end

-- ── Check whether the vault has any claim available ───────────────────────────
local function HasVaultReward()
    if not WeeklyAPIAvailable() or not C_WeeklyRewards.HasAvailableRewards then
        return false
    end
    local ok, has = pcall(C_WeeklyRewards.HasAvailableRewards)
    return ok and has == true
end

-- ── Render helpers ────────────────────────────────────────────────────────────
local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function MkBackdrop(f, br, bg, bb, ba, er, eg, eb, ea)
    f:SetBackdrop(BD)
    f:SetBackdropColor(br or 0.05, bg or 0.04, bb or 0.02, ba or 1)
    f:SetBackdropBorderColor(er or 0.20, eg or 0.20, eb or 0.20, ea or 0.6)
end

-- ── Main render ───────────────────────────────────────────────────────────────
function Weekly:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local y    = -10
    local padL = 10
    local w    = content:GetWidth() - 20

    local function Track(f) table.insert(self.frames, f); return f end
    local function Label(text, size, r, g, b, px, py)
        local f = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        f:SetFont(STANDARD_TEXT_FONT, size or 11, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL + (px or 0), py or y)
        return f
    end

    -- ── Header ────────────────────────────────────────────────────────────
    local hdrF = Label("GREAT VAULT", 13, 1.00, 0.82, 0.00)
    hdrF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

    -- Vault-open badge (top-right)
    if HasVaultReward() then
        local badge = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        badge:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        badge:SetText(COL_GREEN .. "⬛ Vault Open — claim your reward!" .. CLOSE)
        badge:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    end

    y = y - 22

    local sep = Track(content:CreateTexture(nil, "ARTWORK"))
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
    sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    sep:SetColorTexture(0.55, 0.40, 0.08, 0.25)
    y = y - 10

    -- ── API unavailable graceful fallback ─────────────────────────────────
    if not WeeklyAPIAvailable() then
        local warn = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        warn:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        warn:SetText(COL_RED .. "C_WeeklyRewards not available on this build." .. CLOSE
                  .. "\n\nRun " .. COL_GOLD .. "/taweekly" .. CLOSE
                  .. " on live to verify the correct API fields for this version.")
        warn:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        warn:SetWidth(w)
        warn:SetWordWrap(true)
        warn:SetJustifyH("LEFT")
        content:SetHeight(120)
        return
    end

    -- ── Fetch live data ───────────────────────────────────────────────────
    local groups, err = FetchActivities()
    if not groups then
        local errF = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        errF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        errF:SetText(COL_RED .. "Error reading weekly data: " .. tostring(err) .. CLOSE)
        errF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        errF:SetWidth(w)
        errF:SetWordWrap(true)
        content:SetHeight(100)
        return
    end

    -- ── Activity groups ───────────────────────────────────────────────────
    for _, group in ipairs(groups) do
        local meta  = group.meta
        local tiers = group.tiers

        -- Section header
        local gHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        gHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        gHdr:SetText(string.upper(meta.label))
        gHdr:SetTextColor(0.55, 0.40, 0.08, 1)
        gHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        y = y - 18

        if #tiers == 0 then
            -- No data from API for this activity type
            local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
            nodata:SetFont(STANDARD_TEXT_FONT, 9)
            nodata:SetText(COL_GREY .. "No data — open Great Vault or run /taweekly to diagnose." .. CLOSE)
            nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL + 8, y)
            y = y - 20
        else
            for i, tier in ipairs(tiers) do
                local unlocked  = tier.isUnlocked
                local progress  = tier.progress
                local threshold = tier.threshold
                local pct       = threshold > 0 and math.min(1.0, progress / threshold) or 0

                local cardH = 46
                local card  = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
                card:SetSize(w, cardH)
                card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                if unlocked then
                    MkBackdrop(card, 0.02, 0.08, 0.02, 1, 0.20, 0.55, 0.20, 0.8)
                else
                    MkBackdrop(card, 0.05, 0.05, 0.05, 1, 0.20, 0.20, 0.20, 0.6)
                end

                -- Status icon
                local statusF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                statusF:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
                statusF:SetText(unlocked and (COL_GREEN .. "✓" .. CLOSE) or (COL_GREY .. "○" .. CLOSE))
                statusF:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)

                -- Tier label
                local tierF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tierF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
                tierF:SetText(tier.tierLabel)
                tierF:SetTextColor(unlocked and 0.29 or 0.78, unlocked and 1.00 or 0.73, unlocked and 0.48 or 0.48, 1)
                tierF:SetPoint("TOPLEFT", card, "TOPLEFT", 28, -7)

                -- iLvl reward badge (top-right)
                if tier.ilvl and tier.ilvl > 0 then
                    local ilvlF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    ilvlF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
                    ilvlF:SetText(COL_GOLD .. tier.ilvl .. " iLvl" .. CLOSE)
                    ilvlF:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -7)
                end

                -- Progress bar
                local barW    = w - 40
                local filledW = math.max(2, math.floor(barW * pct))
                local barBG = card:CreateTexture(nil, "ARTWORK")
                barBG:SetSize(barW, 5)
                barBG:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 28, 10)
                barBG:SetColorTexture(0.10, 0.10, 0.10, 1)

                local barFG = card:CreateTexture(nil, "ARTWORK")
                barFG:SetSize(filledW, 5)
                barFG:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 28, 10)
                if unlocked then
                    barFG:SetColorTexture(0.22, 0.72, 0.22, 1)
                else
                    barFG:SetColorTexture(0.45, 0.35, 0.08, 1)
                end

                -- Progress text
                local progF = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                progF:SetFont(STANDARD_TEXT_FONT, 9)
                local progStr
                if threshold > 0 then
                    progStr = progress .. " / " .. threshold
                    if unlocked then
                        progStr = COL_GREEN .. progStr .. CLOSE
                    end
                else
                    progStr = COL_GREY .. "no data" .. CLOSE
                end
                progF:SetText(progStr)
                progF:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 28, 18)

                y = y - cardH - 4
            end
        end

        y = y - 8
    end

    -- ── Vault status footer ───────────────────────────────────────────────
    y = y - 4
    local footerLine = Track(content:CreateTexture(nil, "ARTWORK"))
    footerLine:SetHeight(1)
    footerLine:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
    footerLine:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    footerLine:SetColorTexture(0.25, 0.20, 0.05, 0.35)
    y = y - 8

    local footerNote = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    footerNote:SetFont(STANDARD_TEXT_FONT, 8)
    footerNote:SetText(COL_GREY
        .. "Data sourced from C_WeeklyRewards.GetActivities(). "
        .. "Run " .. COL_GOLD .. "/taweekly" .. COL_GREY
        .. " to inspect raw API output if values look wrong after a season reset."
        .. CLOSE)
    footerNote:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    footerNote:SetWidth(w)
    footerNote:SetWordWrap(true)
    footerNote:SetJustifyH("LEFT")
    y = y - 28

    content:SetHeight(math.abs(y) + 20)
end
