-- CharacterAdvisor/Data/Talents.lua
-- Polymorphic talent string data for Midnight 12.0.5 
-- Matches the schema expected by Modules\Talents.lua

local CA = CharacterAdvisor
CA.Data = CA.Data or {}
CA.Data.Talents = {}
local T = CA.Data.Talents

local DB = {}

-- ── EVOKER ────────────────────────────────────────────────────────────
DB[1468] = { -- Preservation
    builds = {
        mplus = { name = "Chronowarden AoE", desc = "Echo-centric build maximizing Temporal Anomaly and Dream Breath.", string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiEiIJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA" },
        raid  = { name = "Chronowarden ST", desc = "Focuses on Reversion uptime and Stasis burst healing.", string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiESLJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA" },
        solo  = { name = "Open World Solo", desc = "Living Flame damage optimization with self-sustain.", string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiEgIJJJJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA" }
    }
}
DB[1467] = { -- Devastation
    builds = {
        mplus = { name = "Scalecommander AoE", desc = "Massive Fire Breath spread and Shattering Star windows.", string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJAAAAA" },
        raid  = { name = "Scalecommander ST", desc = "Disintegrate channeling and Dragonrage optimization.", string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJJkBAA" },
        solo  = { name = "Leveling & Delves", desc = "High survivability with instant cast priority.", string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIJJJiIBAAAAAgkkEJJJJJSiEJJAAAAA" }
    }
}

-- ── WARLOCK ───────────────────────────────────────────────────────────
DB[265] = { -- Affliction
    builds = {
        mplus = { name = "Hellcaller M+", desc = "Seed of Corruption spread and rapid Agony stacking.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA" },
        raid  = { name = "Hellcaller Raid", desc = "Malefic Rapture dump windows and sustained single-target DoTs.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA" },
        solo  = { name = "Voidwalker Solo", desc = "High leech and pet survivability for open-world farming.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA" }
    }
}
DB[266] = { -- Demonology
    builds = {
        mplus = { name = "Diabolist Cleave", desc = "Implosion loops and massive demon swarm generation.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAA" },
        raid  = { name = "Diabolist ST", desc = "Tyrant maximization and sustained Felguard cleave.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAA" },
        solo  = { name = "Felguard Solo", desc = "Beefed up Felguard with quick Dreadstalker resets.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAA" }
    }
}
DB[267] = { -- Destruction
    builds = {
        mplus = { name = "Hellcaller AoE", desc = "Rain of Fire spam and Havoc cleave efficiency.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAAQSSSC" },
        raid  = { name = "Hellcaller ST", desc = "Chaos Bolt optimization and Infernal burst windows.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAAQSSSC" },
        solo  = { name = "Voidwalker Burst", desc = "Quick burst setups to instantly delete quest mobs.", string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAAQSSSC" }
    }
}

-- ── MONK ──────────────────────────────────────────────────────────────
DB[268] = { -- Brewmaster
    builds = {
        mplus = { name = "Master of Harmony M+", desc = "High Stagger mitigation with exceptional AoE threat generation.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA" },
        raid  = { name = "Master of Harmony ST", desc = "Smooth physical damage intake and Purifying Brew efficiency.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJAAAAAQSSSCJJgEJSSgkkkBAA" },
        solo  = { name = "Ox Stance Solo", desc = "Self-healing and rapid clear speed for open world.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA" }
    }
}
DB[269] = { -- Windwalker
    builds = {
        mplus = { name = "Shado-Pan Cleave", desc = "Spinning Crane Kick maximization and clone synchronization.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA" },
        raid  = { name = "Shado-Pan ST", desc = "Fists of Fury channeling and single-target burst prioritization.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAA" },
        solo  = { name = "Swift Clearing", desc = "High mobility and rapid chi generation for fast kills.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA" }
    }
}
DB[270] = { -- Mistweaver
    builds = {
        mplus = { name = "Conduit of the Celestials", desc = "Fistweaving melee-heals prioritizing Ancient Teachings.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC" },
        raid  = { name = "Conduit Raid", desc = "Ranged Soothing Mist channeling and Essence Font blanketing.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAAQSSSC" },
        solo  = { name = "Fistweaver Solo", desc = "High DPS output while maintaining self-sustainability.", string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC" }
    }
}

function T:GetBySpecID(specID)
    return DB[specID]
end
