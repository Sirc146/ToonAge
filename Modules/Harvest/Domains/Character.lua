-- ToonAge/Modules/Harvest/Domains/Character.lua  (harvest domain: character snapshot)
--
-- One line per character, overwritten each login and level-up. Not a log --
-- just enough context to know which class and level a spell or talent record
-- came from. Every client API call goes through TA.Caps (spec R2). Moved here
-- from Modules/Forever/DataHarvester.lua in T4.
--
--   chars[GUID] = name, realm, class, race, level, sex, interface

local TA = ToonAge
local Hv = TA.Harvester

local Try, Clean = Hv.Try, Hv.Clean

local D = {
    id = "character",
    events = { "PLAYER_LEVEL_UP" },
    rescan = { { "character", "RecordCharacter" } },
    export = { { section = "chars", label = "Characters" } },
    summary = { { section = "chars", label = "Characters contributing" } },
}

function D:RecordCharacter()
    local s = Hv:Store()
    if not s then return end
    local name  = Try("UnitName", "player") or "?"
    local realm = Try("GetRealmName") or "?"
    local cls   = select(2, Try("UnitClass", "player")) or "?"
    local race  = select(2, Try("UnitRace", "player")) or "?"
    -- Keyed by GUID, not Name-Realm: the same Mage was recorded twice
    -- ("Eramali Stryfe" at 15, "Eramali" at 17) because the name the client
    -- reported changed between sessions. A GUID never does. Name and realm are
    -- kept as fields so the export still reads naturally. A GUID the client
    -- marks secret comes back from Caps as the word "secret": not a key.
    local guid = Try("UnitGUID", "player")
    if guid == "secret" then guid = nil end
    local key = guid or (name .. "-" .. realm)
    s.chars[key] = table.concat({
        Clean(name), Clean(realm),
        Clean(cls), Clean(race), Clean(Try("UnitLevel", "player")),
        Clean(Try("UnitSex", "player")), Clean(select(4, Try("GetBuildInfo"))),
    }, "\t")
    -- The v1 record for this character (Name-Realm key) is superseded.
    if guid then s.chars[name .. "-" .. realm] = nil end
    Hv:Touch("chars")
end

function D:OnEvent(event)
    if event == "PLAYER_LEVEL_UP" then self:RecordCharacter() end
end

function D:OnEnterWorld()
    self:RecordCharacter()
end

Hv:RegisterDomain(D)
