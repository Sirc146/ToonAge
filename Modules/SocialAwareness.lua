-- ToonAge/Modules/SocialAwareness.lua
-- Social Awareness: detects friends/guildmates in the same zone with similar
-- quest progress. Suggests party-up opportunities.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local Social = {}
TA:RegisterModule("SocialAwareness", Social)

-- ── State ─────────────────────────────────────────────────────────────────────
Social.lastCheck     = 0
Social.nearbyFriends = {}
local CHECK_INTERVAL = 30  -- seconds between scans

-- ── Scanning ──────────────────────────────────────────────────────────────────

--- Scan friends list and guild roster for players in the same zone.
function Social:ScanNearbyPlayers()
    wipe(self.nearbyFriends)

    local playerZone = GetRealZoneText()
    local playerLevel = UnitLevel("player") or 1
    if not playerZone or playerZone == "" then return end

    -- ── Check BattleNet friends ───────────────────────────────────────
    if C_BattleNet and C_BattleNet.GetFriendNumGameAccounts then
        local numFriends = BNGetNumFriends and BNGetNumFriends() or 0
        for i = 1, numFriends do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo and accountInfo.gameAccountInfo then
                local gameInfo = accountInfo.gameAccountInfo
                if gameInfo.isOnline and gameInfo.clientProgram == "WoW" then
                    local friendZone = gameInfo.areaName or ""
                    local friendLevel = gameInfo.characterLevel or 0
                    local friendName = gameInfo.characterName or accountInfo.accountName

                    if friendZone == playerZone and math.abs(friendLevel - playerLevel) <= 5 then
                        table.insert(self.nearbyFriends, {
                            name   = friendName,
                            level  = friendLevel,
                            zone   = friendZone,
                            source = "BNet",
                            bnetID = accountInfo.bnetAccountID,
                        })
                    end
                end
            end
        end
    end

    -- ── Check guild roster ────────────────────────────────────────────
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, level, _, zone, _, _, online = GetGuildRosterInfo(i)
            if online and name and zone == playerZone then
                local cleanName = name:match("^([^-]+)") or name
                -- Skip self
                if cleanName ~= UnitName("player") then
                    if math.abs(level - playerLevel) <= 5 then
                        table.insert(self.nearbyFriends, {
                            name   = cleanName,
                            level  = level,
                            zone   = zone,
                            source = "Guild",
                        })
                    end
                end
            end
        end
    end
end

--- Get a formatted suggestion if friends are nearby.
--- @return string|nil
function Social:GetSuggestion()
    if #self.nearbyFriends == 0 then return nil end

    if #self.nearbyFriends == 1 then
        local f = self.nearbyFriends[1]
        return string.format("|cFF55CCFF👥 %s (%s, lvl %d) is in %s — party up?|r",
            f.name, f.source, f.level, f.zone)
    else
        return string.format("|cFF55CCFF👥 %d friends/guildmates nearby in %s!|r",
            #self.nearbyFriends, GetRealZoneText())
    end
end

-- ── Event handling ────────────────────────────────────────────────────────────

function Social:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "GROUP_ROSTER_UPDATE" then
        local now = GetTime()
        if now - self.lastCheck > CHECK_INTERVAL then
            self.lastCheck = now
            self:ScanNearbyPlayers()
            local suggestion = self:GetSuggestion()
            if suggestion then
                print("|cFFFFD100[ToonAge]|r " .. suggestion)
            end
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function Social:Init()
    -- Periodic scan
    C_Timer.NewTicker(CHECK_INTERVAL, function()
        Social:ScanNearbyPlayers()
    end)

    -- Initial scan after delay (guild roster needs time to load)
    C_Timer.After(10, function()
        Social:ScanNearbyPlayers()
    end)
end

Social.SlashCommands = {}
