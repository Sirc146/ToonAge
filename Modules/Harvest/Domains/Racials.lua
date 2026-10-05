-- ToonAge/Modules/Harvest/Domains/Racials.lua  (harvest domain: racial abilities)
--
-- For the PvP tab's matchups (what your race counters, what theirs counters).
-- spells[] is keyed by CLASS, so it cannot say which race a racial belongs to;
-- this table can. Faction is part of the key because Forever splits racials by
-- it (measured 2026-09-29: Skyborne Alliance gets Read Ley Line, Skyborne Horde
-- gets Skysight, both Warriors). The tooltip is stored verbatim -- it is where
-- the effect and cooldown live ("2 min cooldown", "removes Fear effects");
-- nothing is interpreted here.
--
-- Recorded from the spellbook scan (Domains/Spellbook.lua) when a spell's rank
-- text says "Racial". Every client API call goes through TA.Caps (spec R2).
-- Moved here from Modules/Forever/DataHarvester.lua in T4.
--
--   racials["RACE:FACTION:spellID"] = name, rank text, "passive" or "",
--                                     classes seen (comma list), tooltip text

local TA = ToonAge
local Hv = TA.Harvester

local Try, Clean, Fields, IsSecret = Hv.Try, Hv.Clean, Hv.Fields, Hv.IsSecret

local D = {
    id = "racials",
    export = { { section = "racials", label = "Racials" } },
    summary = { { section = "racials", label = "Racials (race + faction)" } },
}

local function TooltipText(spellID)
    local data = Try("C_TooltipInfo.GetSpellByID", spellID)
    if not (type(data) == "table" and type(data.lines) == "table") then return "" end
    local parts = {}
    for i = 2, #data.lines do          -- line 1 is the spell name
        local ln = data.lines[i]
        for _, t in ipairs({ ln.leftText, ln.rightText }) do
            if type(t) == "string" and t ~= "" and not IsSecret(t) then
                parts[#parts + 1] = t
            end
        end
    end
    return table.concat(parts, " | ")
end

function D:Record(spellID, name, rank, passive)
    local s = Hv:Store()
    if not (s and spellID) then return end
    local race    = select(2, Try("UnitRace", "player")) or "?"
    local faction = Try("UnitFactionGroup", "player") or "?"
    local class   = select(2, Try("UnitClass", "player")) or "?"
    local key = race .. ":" .. faction .. ":" .. spellID
    local f = s.racials[key] and Fields(s.racials[key]) or {}
    local classes = f[4] or ""
    if not ("," .. classes .. ","):find("," .. class .. ",", 1, true) then
        classes = (classes == "") and class or (classes .. "," .. class)
    end
    local tip = f[5]
    if not tip or tip == "" then tip = TooltipText(spellID) end
    s.racials[key] = table.concat({ Clean(name), Clean(rank),
        Clean(passive and "passive" or ""), Clean(classes), Clean(tip) }, "\t")
    Hv:Touch("racials")
end

Hv:RegisterDomain(D)
