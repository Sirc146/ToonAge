#!/usr/bin/env python3
"""Level-12 Forever Mage spell guidance.

The slice is the rev3 10-19 baseline only. A spell is suggested when a
runtime check positively confirms it. An absent or unreadable check stays
unknown, which is not the same as unlearned. Tier A is a computed next
action only when every gate is a verified boolean. Player-chosen situations
stay conditional. Disabled talent and proc rows never surface.

Usage:  python3 Tools/test_mage_level12_guidance.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

GUIDE = ROOT / "Modules/Forever/MageGuidance.lua"
ROTATION = ROOT / "Modules/Forever/Rotation.lua"


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
    ToonAge = { modules = {}, Data = {}, Caps = {} }
    function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
    function ToonAge:QueueUIRefresh(reason) self._refreshed = reason end
    """)
    lua.execute(GUIDE.read_text(encoding="utf-8"))
    return lua


def main():
    check("guidance module exists", GUIDE.exists(), True)
    if not GUIDE.exists():
        print(f"[FAIL] 0/{len(_results)} passed; module missing.")
        return 1

    src = GUIDE.read_text(encoding="utf-8")
    check("no UnitHealth read", "UnitHealth" not in src, True)
    check("no UnitPower read", "UnitPower" not in src, True)
    check("no tostring on values", "tostring" not in src, True)
    check("no 15 percent numeric cutoff", "0.15" not in src, True)
    check("no saved-variable writes", "charDB" not in src and "ToonAgeDB" not in src, True)
    check("library does not register a second module",
          'TA:RegisterModule' not in src, True)
    check("accelerant id is not a data literal", "11069" not in src, True)

    lua = runtime()
    G = lua.eval("ToonAge.MageLevel12")
    check("library is installed", G is not None, True)

    lua.execute(r"""
        local G = ToonAge.MageLevel12
        local ids, names, verified = {}, {}, {}
        local bad_active = 0
        for _, e in ipairs(G.DATA.entries) do
            names[#names + 1] = e.name
            if e.active ~= true or e.designNoteOnly or (e.requires and e.requires.talentKnown) then
                bad_active = bad_active + 1
            end
            if e.tacticalVerified == true then verified[#verified + 1] = e.name end
            for _, id in ipairs(e.rankIDs or {}) do ids[#ids + 1] = tostring(id) end
            if e.spellID then ids[#ids + 1] = tostring(e.spellID) end
        end
        DATA_STATUS = G.DATA.status
        DATA_WHOLE = G.DATA.verifiedAsWhole
        DATA_REV = G.DATA.rev
        DATA_DATE = G.DATA.revDate
        DATA_BAND = G.DATA.band
        DATA_LABEL = G.DATA.label
        DATA_NAMES = table.concat(names, "|")
        DATA_VERIFIED = table.concat(verified, "|")
        DATA_IDS = table.concat(ids, ",")
        DATA_BAD = bad_active
        DATA_OTHER = (G.DATA["1-9"] or G.DATA["20-39"] or G.DATA["40-49"]) and 1 or 0
    """)
    check("status is the research draft", lua.eval("DATA_STATUS"), "research_draft")
    check("the subset is not verified as a whole", lua.eval("DATA_WHOLE"), False)
    check("rev is 3", lua.eval("DATA_REV"), 3)
    check("rev date is 2026-11-08", lua.eval("DATA_DATE"), "2026-11-08")
    check("only the 10-19 band is shipped", lua.eval("DATA_BAND"), "10-19")
    check("no other band table is shipped", lua.eval("DATA_OTHER"), 0)
    check("label names the draft", lua.eval("DATA_LABEL"),
          "MAGE_FOREVER rev3 2026-11-08, research_draft")
    check("entries are the 10-19 baseline and wand row",
          lua.eval("DATA_NAMES"),
          "Fireball|Arcane Missiles|Fire Blast|Frostbolt|Shoot|"
          "Arcane Explosion|Flamestrike|Frost Nova|Polymorph|"
          "Frost Armor|Arcane Intellect|Conjure Food|Conjure Water|"
          "Dampen Magic|Slow Fall|Amplify Magic")
    check("page-stated rows are Fireball, Shoot, and the pack spells",
          lua.eval("DATA_VERIFIED"),
          "Fireball|Shoot|Arcane Explosion|Flamestrike|Frost Nova")
    check("no disabled row is active", lua.eval("DATA_BAD"), 0)
    check("confirmed ids are only Fireball and Arcane Missiles",
          lua.eval("DATA_IDS"), "133,143,145,3140,133,5143,5144,5143")

    def eval_case(body):
        lua.execute(body)
        return lua.eval("OUT")

    base = r"""
        local G = ToonAge.MageLevel12
        G._situation = nil
        G._notes = ""
        local asked = {}
        local function ask(id)
            asked[#asked + 1] = id
            if id == 145 or id == 5143 then return "yes" end
            return "no"
        end
        local ctx = {
            class = "MAGE", level = 12, situation = "pull",
            situationObserved = false,
            ask = ask,
            spellbook = {
                { name = "Fireball", spellID = 145 },
                { name = "Arcane Missiles", spellID = 5143 },
            },
            wand = "unknown",
            version = "2.0.0-dev.1",
            build = "70862",
            interface = "16001",
            errors = {},
        }
    """

    out = eval_case(base + r"""
        local view = G.Evaluate(ctx)
        OUT = table.concat({
            tostring(view.applies), tostring(view.computed), tostring(view.press),
            view.label or "", view.tier or "", view.confidence or "",
            view.situationSource or "",
        }, "|")
        HEAD = view.headline or ""
        WHY = view.why or ""
        CHANGES = view.changes or ""
        FEED = G.Feedback(view, "the opener was late")
    """)
    check("pull with Fireball confirmed is a conditional press",
          out, "true|false|true|Fireball|A|page-stated|player")
    check("headline names the conditional next action",
          "Fireball" in lua.eval("HEAD") and "conditional" in lua.eval("HEAD").lower(), True)
    check("why is the opener before the enemy reaches you",
          "before the enemy reaches you" in lua.eval("WHY"), True)
    check("the change note is present",
          len(lua.eval("CHANGES") or "") > 20, True)
    feed = lua.eval("FEED")
    for part in (
        "2.0.0-dev.1", "70862", "16001", "MAGE", "12",
        "MAGE_FOREVER rev3 2026-11-08, research_draft", "10-19",
        "Fireball", "tier A", "IV-Fire", "page-stated",
        "Arcane Missiles", "the opener was late",
        "target health: not read", "player mana: not read", "enemy count: not read",
    ):
        check(f"feedback contains {part}", part in feed, True)
    check("feedback does not say unlearned", "unlearned" not in feed.lower(), True)
    check("feedback does not say not learned", "not learned" not in feed.lower(), True)
    check("feedback does not collect a name", "\nName:" not in feed, True)
    check("feedback does not collect a GUID", "GUID" not in feed, True)
    check("empty error log is reported as none captured",
          "none captured" in feed, True)
    check("feedback separates semantic version, data revision, source base, and candidate",
          "Addon semantic version:" in feed
          and "Source data revision: MAGE_FOREVER rev3 2026-11-08, research_draft" in feed
          and "Patch source base: b652f246c0d79edcad934cd0a1021bd4feb74ff4" in feed
          and "Candidate code revision: not injected" in feed
          and "74f54bd" not in feed and "79d567bd" not in feed, True)

    check("an assumed pull is labeled, not computed",
          eval_case(base + r"""
            ctx.situation = nil
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. (view.situationSource or "") .. "|" .. (view.label or "")
          """),
          "false|assumed|Fireball")

    check("Arcane Missiles is not promoted when Fireball is unknown",
          eval_case(base + r"""
            ctx.ask = function() return "unknown" end
            ctx.spellbook = { { name = "Arcane Missiles", spellID = 5143 } }
            local view = G.Evaluate(ctx)
            local b = {}
            for _, tip in ipairs(view.tierB or {}) do b[#b + 1] = tip.name end
            OUT = tostring(view.press) .. "|" .. (view.label or "") .. "|" .. table.concat(b, ",")
          """),
          "false||Arcane Missiles")

    check("a false spell check is unknown, not a hidden absence",
          eval_case(base + r"""
            ctx.ask = function() return "no" end
            ctx.spellbook = {}
            local view = G.Evaluate(ctx)
            local unk = {}
            for _, row in ipairs(view.unknown or {}) do unk[#unk + 1] = row.name end
            OUT = tostring(view.press) .. "|" .. table.concat(unk, ",")
            FEED = G.Feedback(view, "")
          """),
          "false|Fireball,Arcane Missiles,Fire Blast,Frostbolt,Shoot,"
          "Arcane Explosion,Flamestrike,Frost Nova,Polymorph,"
          "Frost Armor,Arcane Intellect,Conjure Food,Conjure Water,"
          "Dampen Magic,Slow Fall,Amplify Magic")
    check("unknown feedback avoids unlearned",
          "unlearned" not in (lua.eval("FEED") or "").lower(), True)

    check("secret spell check stays unknown",
          eval_case(base + r"""
            ctx.ask = function() return "secret" end
            ctx.spellbook = {}
            local view = G.Evaluate(ctx)
            OUT = tostring(view.press) .. "|" .. ((view.unknown[1] and view.unknown[1].detail) or "")
          """),
          "false|unreadable")

    check("a missing spell API stays unknown when the other API is false",
          eval_case(r"""
            function ToonAge.Caps.Call(path, id)
                if path == "UnitHealth" or path == "UnitPower" then error("combat resource was read") end
                if path == "UnitLevel" then return true, 12 end
                if path == "UnitClass" then return true, "Mage", "MAGE" end
                if path == "IsPlayerSpell" then return false, "missing" end
                if path == "IsSpellKnown" then return true, false end
                return false, "missing"
            end
            local G = ToonAge.MageLevel12
            local ctx = G.ReadLive({})
            ctx.situation = "pull"
            local view = G.Evaluate(ctx)
            OUT = tostring(G.Applies(ctx)) .. "|" .. tostring(view.press)
          """),
          "true|false")

    lua.execute(r"""
        local asked = {}
        function ToonAge.Caps.Call(path, a)
            asked[#asked + 1] = path .. ":" .. tostring(a)
            if path == "UnitHealth" or path == "UnitPower" or path == "UnitHealthMax" then
                error("combat resource was read")
            end
            if path == "UnitLevel" then return true, "secret" end
            if path == "UnitClass" then return true, "Mage", "MAGE" end
            if path == "IsPlayerSpell" then return false, "missing" end
            if path == "IsSpellKnown" then return true, false end
            return false, "missing"
        end
        local G = ToonAge.MageLevel12
        local ok, ctx = pcall(G.ReadLive, nil)
        SECRET_OK = ok
        SECRET_APPLIES = ok and G.Applies(ctx)
        SECRET_LEVEL = ok and tostring(ctx.level)
    """)
    check("a secret level does not throw", lua.eval("SECRET_OK"), True)
    check("a secret level does not apply the band", lua.eval("SECRET_APPLIES"), False)
    check("a secret level is not stored as a number", lua.eval("SECRET_LEVEL"), "nil")

    lua.execute(r"""
        ToonAge.Compat = { GetItemInfo = function()
            return "Wand", "item:99", 2, 5, 1, "Weapon", "Wands", 1,
                "INVTYPE_RANGED", 0, 0, 2, 19
        end }
        function ToonAge.Caps.Call(path, a, b)
            if path == "UnitHealth" or path == "UnitPower" then error("combat resource was read") end
            if path == "UnitLevel" then return true, 12 end
            if path == "UnitClass" then return true, "Mage", "MAGE" end
            if path == "GetBuildInfo" then return true, "1.60.1", "70862", "Nov 8 2026", 16001 end
            if path == "IsPlayerSpell" then
                if a == 145 or a == 5143 then return true, true end
                return true, false
            end
            if path == "IsSpellKnown" then return true, false end
            if path == "GetInventoryItemID" then return true, 99 end
            if path == "GetItemInfo" then
                return true, "Lesser Magic Wand", "item:99", 2, 10, 1,
                    "Weapon", "Wands", 1, "INVTYPE_RANGED", 0, 0, 2, 19
            end
            return false, "missing"
        end
        ToonAge.version = "2.0.0-dev.1"
        ToonAge.ErrorLog = nil
        local G = ToonAge.MageLevel12
        local ctx = G.ReadLive({
            { name = "Fire", spells = {
                { name = "Fireball", spellID = 145 },
                { name = "Arcane Missiles", spellID = 5143 },
                { name = "Shoot" },
            } },
        })
        ctx.situation = "finish"
        local view = G.Evaluate(ctx)
        LIVE = table.concat({
            tostring(G.Applies(ctx)), tostring(view.press), view.label or "",
            tostring(view.computed), view.situationSource or "",
            ctx.wand or "", ctx.shootKnown or "", ctx.build or "", ctx.interface or "",
        }, "|")
        LIVE_FEED = G.Feedback(view, "")
        ctx.situation = "pull"
        local pull = G.Evaluate(ctx)
        LIVE_PULL = tostring(pull.computed) .. "|" .. (pull.label or "") .. "|" .. (pull.spellID or 0)
    """)
    check("live read applies and can conditionally finish with Shoot",
          lua.eval("LIVE"),
          "true|true|Shoot|false|player|yes|yes|70862|16001")
    check("Shoot feedback names the stationary note and refuses a cutoff",
          "Stand still" in lua.eval("LIVE_FEED")
          and "not a cutoff" in lua.eval("LIVE_FEED")
          and "official beta note, not confirmed on live 70862" in lua.eval("LIVE_FEED")
          and "does not use that number as a gate" in lua.eval("LIVE_FEED"), True)
    check("a player pull is not computed, and the confirmed rank is 145",
          lua.eval("LIVE_PULL"), "false|Fireball|145")

    check("rank 3 stays unconfirmed when only rank 1 answered",
          eval_case(base + r"""
            ctx.ask = function(id) if id == 133 then return "yes" end return "no" end
            ctx.spellbook = { { name = "Fireball", spellID = 133 } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.spellID)
            HINT = view.rankHint or ""
          """),
          "133")
    hint = lua.eval("HINT") or ""
    check("an unconfirmed Fireball rank 3 stays trainer-listed",
          "Fireball rank 3 (spell 145) is trainer-listed at 12 - not confirmed learned."
          in hint, True)
    check("a level 12 hint includes the nearby rank 14 reminders",
          "Frostbolt rank at 14 is trainer-listed, not confirmed learned." in hint
          and "Fire Blast rank at 14 is trainer-listed, not confirmed learned." in hint
          and "Fireball rank 4" not in hint
          and "Arcane Missiles rank 2" not in hint, True)
    ranks = eval_case(base + r"""
        ctx.ask = function(id) if id == 133 then return "yes" end return "no" end
        ctx.spellbook = { { name = "Fireball", spellID = 133 } }
        local function hint(level)
            ctx.level = level
            return G.Evaluate(ctx).rankHint or ""
        end
        OUT = hint(10) .. "\n" .. hint(14) .. "\n" .. hint(18)
    """)
    at10, at14, at18 = (ranks or "\n\n").split("\n")
    check("level 10 sees only ranks within two levels",
          "Fireball rank 3 (spell 145) is trainer-listed at 12 - not confirmed learned." in at10
          and "Frostbolt rank at 8 is trainer-listed, not confirmed learned." in at10
          and "Fireball rank 4" not in at10
          and "Arcane Missiles rank 2" not in at10
          and "Frostbolt rank at 14" not in at10
          and "Fire Blast rank at 14" not in at10, True)
    check("level 14 adds the rank 14 and rank 16 reminders",
          "Arcane Missiles rank 2 (spell 5144) is trainer-listed at 16 - not confirmed learned." in at14
          and "Fire Blast rank at 14 is trainer-listed, not confirmed learned." in at14
          and "Fireball rank 4" not in at14, True)
    check("level 18 lists every unconfirmed rank as its own sentence",
          at18.count("not confirmed learned.") == 6
          and ". Fireball rank 4" in at18
          and ". Arcane Missiles rank 2" in at18
          and ". Frostbolt rank at 8" in at18
          and ". Frostbolt rank at 14" in at18
          and ". Fire Blast rank" in at18, True)
    check("a confirmed higher rank is named before its trainer level",
          "Fireball rank 4 (spell 3140) is confirmed." in (eval_case(base + r"""
            ctx.level = 10
            ctx.ask = function(id)
                if id == 133 or id == 3140 then return "yes" end
                return "no"
            end
            ctx.spellbook = { { name = "Fireball", spellID = 133 }, { name = "Fireball", spellID = 3140 } }
            local view = G.Evaluate(ctx)
            OUT = view.rankHint or ""
          """) or ""), True)

    check("client name is used when the id is confirmed",
          eval_case(base + r"""
            ctx.spellbook = { { name = "Boule de feu", spellID = 145 } }
            local view = G.Evaluate(ctx)
            OUT = view.label or ""
          """),
          "Boule de feu")

    check("a localized name does not confirm a spell that has no id",
          eval_case(base + r"""
            ctx.situation = "finish"
            ctx.wand = "yes"
            ctx.ask = function() return "unknown" end
            ctx.spellbook = { { name = "Schießen" } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.press) .. "|" .. (view.shootKnown or "")
          """),
          "false|unknown")

    check("Shoot is withheld unless the wand is positively usable",
          eval_case(base + r"""
            ctx.situation = "finish"
            ctx.wand = "unknown"
            ctx.spellbook = { { name = "Shoot" }, { name = "Fireball", spellID = 145 } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.press) .. "|" .. (view.label or "")
          """),
          "false|")

    check("an empty wand slot is a no, not an unknown",
          eval_case(r"""
            local G = ToonAge.MageLevel12
            local function call(path)
                if path == "GetInventoryItemID" then return true, nil end
                return false, "missing"
            end
            OUT = G.ReadWand(call, 12)
          """),
          "no")

    check("a secret item id does not become a wand",
          eval_case(r"""
            local G = ToonAge.MageLevel12
            local function call(path)
                if path == "GetInventoryItemID" then return true, "secret" end
                return false, "missing"
            end
            OUT = G.ReadWand(call, 12)
          """),
          "unknown")

    check("a bow in the ranged slot is not a wand",
          eval_case(r"""
            local G = ToonAge.MageLevel12
            ToonAge.Compat = { GetItemInfo = function()
                return "Bow", "item:50", 2, 10, 1, "Weapon", "Bows", 1,
                    "INVTYPE_RANGED", 0, 0, 2, 2
            end }
            local function call(path)
                if path == "GetInventoryItemID" then return true, 50 end
                return false, "missing"
            end
            OUT = G.ReadWand(call, 12)
          """),
          "no")

    check("a wand above the player level is not usable",
          eval_case(r"""
            local G = ToonAge.MageLevel12
            ToonAge.Compat = { GetItemInfo = function()
                return "Wand", "item:77", 2, 20, 20, "Weapon", "Wands", 1,
                    "INVTYPE_RANGEDRIGHT", 0, 0, 2, 19
            end }
            local function call(path)
                if path == "GetInventoryItemID" then return true, 77 end
                return false, "missing"
            end
            OUT = G.ReadWand(call, 12)
          """),
          "no")

    check("an unreadable item requirement stays unknown",
          eval_case(r"""
            local G = ToonAge.MageLevel12
            ToonAge.Utils = ToonAge.Utils or {}
            ToonAge.Utils.IsSecret = function(v) return v == "secret" end
            ToonAge.Compat = { GetItemInfo = function()
                return "Wand", "item:77", 2, 20, "secret", "Weapon", "Wands", 1,
                    "INVTYPE_RANGED", 0, 0, 2, 19
            end }
            local function call(path)
                if path == "GetInventoryItemID" then return true, 77 end
                return false, "missing"
            end
            OUT = G.ReadWand(call, 12)
          """),
          "unknown")

    check("an unread spellbook is not reported as a finished name scan",
          eval_case(base + r"""
            ctx.spellbookRead = "unreadable"
            ctx.spellbook = {}
            ctx.ask = function(id) if id == 145 then return "yes" end return "unknown" end
            local view = G.Evaluate(ctx)
            local shoot
            for _, row in ipairs(view.unknown or {}) do
                if row.name == "Shoot" then shoot = row.detail end
            end
            local feed = G.Feedback(view, "")
            OUT = tostring(view.press) .. "|" .. (view.label or "") .. "|" .. (shoot or "")
                .. "|" .. (feed:find("no exact spellbook name", 1, true) and "scanned" or "clear")
          """),
          "true|Fireball|spellbook unread|clear")

    check("a finished read can say the exact name was absent",
          eval_case(base + r"""
            ctx.spellbookRead = "read"
            ctx.spellbook = { { name = "Fireball", spellID = 145 } }
            ctx.ask = function(id) if id == 145 then return "yes" end return "no" end
            local view = G.Evaluate(ctx)
            local shoot
            for _, row in ipairs(view.unknown or {}) do
                if row.name == "Shoot" then shoot = row.detail end
            end
            OUT = shoot or ""
          """),
          "no exact spellbook name")

    check("an incomplete enumeration stays unknown instead of name-absent",
          eval_case(base + r"""
            ctx.spellbookRead = "incomplete"
            ctx.spellbook = { { name = "Fireball", spellID = 145 } }
            ctx.ask = function(id) if id == 145 then return "yes" end return "unknown" end
            local view = G.Evaluate(ctx)
            local shoot
            for _, row in ipairs(view.unknown or {}) do
                if row.name == "Shoot" then shoot = row.detail end
            end
            OUT = shoot or ""
          """),
          "spellbook incomplete")

    check("a health percent cannot select Shoot",
          eval_case(base + r"""
            ctx.situationObserved = true
            ctx.observed = { targetHealthPct = 10, playerManaPct = 0 }
            ctx.wand = "yes"
            ctx.spellbook = { { name = "Shoot" }, { name = "Fireball", spellID = 145 } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. tostring(view.press) .. "|" .. (view.label or "")
          """),
          "false|false|")

    check("verified boolean gates can compute Fireball ahead of Shoot",
          eval_case(base + r"""
            ctx.situationObserved = true
            ctx.observed = { pullAtRange = true, targetLowHealth = true }
            ctx.wand = "yes"
            ctx.spellbook = {
                { name = "Fireball", spellID = 145 },
                { name = "Shoot" },
            }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. (view.label or "") .. "|" .. (view.confidence or "")
          """),
          "true|Fireball|page-stated")

    check("a verified finish computes Shoot only with both gates",
          eval_case(base + r"""
            ctx.situationObserved = true
            ctx.observed = { playerOutOfMana = true }
            ctx.wand = "yes"
            ctx.spellbook = { { name = "Shoot" }, { name = "Fireball", spellID = 145 } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. (view.label or "")
          """),
          "true|Shoot")

    check("Frost Nova waits for a confirmed area spell",
          eval_case(base + r"""
            ctx.situation = "pack"
            ctx.spellbook = { { name = "Frost Nova" }, { name = "Fireball", spellID = 145 } }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.press) .. "|" .. (view.label or "")
          """),
          "false|")

    check("a solo pack with Nova and Arcane Explosion suggests Nova",
          eval_case(base + r"""
            ctx.situation = "pack"
            ctx.spellbook = {
                { name = "Frost Nova" },
                { name = "Arcane Explosion" },
                { name = "Fireball", spellID = 145 },
            }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. tostring(view.press) .. "|" .. (view.label or "")
          """),
          "false|true|Frost Nova")

    check("an observed pack still needs the solo flag",
          eval_case(base + r"""
            ctx.situationObserved = true
            ctx.observed = { severalMobs = true, solo = false }
            ctx.spellbook = {
                { name = "Frost Nova" }, { name = "Flamestrike" },
                { name = "Fireball", spellID = 145 },
            }
            local view = G.Evaluate(ctx)
            OUT = tostring(view.computed) .. "|" .. tostring(view.press)
          """),
          "false|false")

    check("an ordinary fight has no page-stated press",
          eval_case(base + r"""
            ctx.situation = "engaged"
            local view = G.Evaluate(ctx)
            local b = {}
            for _, tip in ipairs(view.tierB or {}) do b[#b + 1] = tip.name end
            OUT = tostring(view.press) .. "|" .. table.concat(b, ",")
            WHY = view.why or ""
          """),
          "false|Arcane Missiles")
    check("an engaged enemy keeps the sourced control note",
          "Frostbolt" in (lua.eval("WHY") or "")
          and "not a cooldown press" in (lua.eval("WHY") or "")
          and "No page-stated next spell" not in (lua.eval("WHY") or ""), True)

    check("Fireball is labeled a Fire-style opener",
          "Fire-style opener" in (eval_case(base + r"""
            local view = G.Evaluate(ctx)
            OUT = view.why or ""
          """) or ""), True)

    check("learned reminders never become the press",
          eval_case(base + r"""
            ctx.spellbook = {
                { name = "Fireball", spellID = 145 },
                { name = "Frost Armor" },
                { name = "Arcane Intellect" },
                { name = "Conjure Food" },
                { name = "Conjure Water" },
                { name = "Dampen Magic" },
                { name = "Slow Fall" },
                { name = "Amplify Magic" },
                { name = "Frostbolt" },
                { name = "Arcane Missiles", spellID = 5143 },
                { name = "Fire Blast" },
                { name = "Polymorph" },
            }
            local view = G.Evaluate(ctx)
            local names = {}
            for _, row in ipairs(view.reminders or {}) do names[#names + 1] = row.name end
            local tips = {}
            for _, tip in ipairs(view.tierB or {}) do tips[#tips + 1] = tip.why end
            OUT = (view.label or "") .. "|" .. table.concat(names, ",")
            TIP = table.concat(tips, "\n")
          """),
          "Fireball|Frost Armor,Arcane Intellect,Conjure Food,Conjure Water,"
          "Dampen Magic,Slow Fall,Amplify Magic")
    tips = lua.eval("TIP") or ""
    check("sourced tips replace the old gap wording",
          "Frostbolt slow" in tips
          and "when you have to move" in tips
          and "extra pull" in tips
          and "The page lists Missiles without a Missile Barrage condition" in tips
          and "after core talents" in tips
          and "not a pre-talent rule" in tips
          and "Unverified" not in tips
          and "not stated" not in tips.lower()
          and "on cooldown" not in tips.lower(), True)
    arcane = eval_case(base + r"""
        ctx.spellbook = {
            { name = "Fireball", spellID = 145 },
            { name = "Frostbolt" },
            { name = "Arcane Missiles", spellID = 5143 },
            { name = "Shoot" },
        }
        ctx.wand = "yes"
        ctx.level = 13
        local view = G.Evaluate(ctx)
        OUT = tostring(view.press) .. "|" .. (view.label or "") .. "|"
            .. (view.arcaneLine or "") .. "|" .. (view.wandWhileMana or "")
            .. "|" .. (view.wandMilestone or "") .. "|" .. (view.unresolved or "")
    """)
    check("the arcane order does not replace the Fireball press",
          arcane.startswith("true|Fireball|"), True)
    check("the arcane tip names the order and refuses a damage claim",
          "Frostbolt, then Arcane Missiles" in arcane
          and "finish instead of spending mana" in arcane
          and "pushback" in arcane
          and "while mana remains" not in arcane
          and "does not claim the wand beats a spell" in arcane, True)
    check("a level 13 guide names the Greater Magic Wand milestone",
          "Greater Magic Wand" in arcane and "available at 13" in arcane, True)
    check("the curse level conflict is flagged and not recommended",
          "Remove Lesser Curse is omitted" in arcane
          and "level-18" in arcane and "says 20" in arcane, True)
    check("a level 12 guide does not show the level 13 wand milestone",
          "Greater Magic Wand" not in (eval_case(base + r"""
            local view = G.Evaluate(ctx)
            OUT = view.wandMilestone or ""
          """) or ""), True)
    check("an unlearned reminder is not shown as a tip",
          "Frost Armor" not in (eval_case(base + r"""
            local view = G.Evaluate(ctx)
            local names = {}
            for _, row in ipairs(view.reminders or {}) do names[#names + 1] = row.name end
            OUT = table.concat(names, ",")
          """) or ""), True)

    check("level 9 and level 20 and other classes do not apply",
          eval_case(base + r"""
            local function one(class, level)
                local c = {}
                for k, v in pairs(ctx) do c[k] = v end
                c.class, c.level = class, level
                return ToonAge.MageLevel12.Applies(c) and "Y" or "N"
            end
            OUT = one("MAGE", 9) .. one("MAGE", 10) .. one("MAGE", 12)
                .. one("MAGE", 19) .. one("MAGE", 20) .. one("WARRIOR", 12)
                .. one("MAGE", "12") .. one("MAGE", "secret")
          """),
          "NYYYN NNN".replace(" ", ""))

    check("disabled and accelerant rows cannot be poisoned into a suggestion",
          eval_case(base + r"""
            local poison = {
                status = "research_draft", verifiedAsWhole = false, rev = 3,
                revDate = "2026-11-08", band = "10-19",
                label = "poison",
                entries = {
                    { key = "fireball", name = "Fireball", group = "st", tier = "A",
                      situation = "pull", active = true, tacticalVerified = true,
                      idConf = "C", rankIDs = { 133, 8400 }, spellID = 133,
                      src = { "S1" }, tacticalSrc = "S1",
                      tacticalUsage = "opener before the enemy reaches you" },
                    { key = "proc", name = "Arcane Missiles", group = "talentBranches",
                      tier = "A", active = false, designNoteOnly = true,
                      requires = { talentKnown = "Missile Barrage" },
                      tacticalUsage = "cast on Missile Barrage proc",
                      tacticalVerified = false, spellID = 5143, rankIDs = { 5143 } },
                    { key = "accelerant", name = "Accelerant", spellID = 11069,
                      active = true, tacticalVerified = true, tier = "A",
                      situation = "pull", tacticalUsage = "cast", idConf = "C",
                      rankIDs = { 11069 } },
                },
            }
            local seen = {}
            ctx.ask = function(id) seen[#seen + 1] = id return "yes" end
            ctx.spellbook = {}
            local view = G.Evaluate(ctx, poison)
            local blob = (view.label or "") .. "|" .. (view.why or "") .. "|" .. G.Feedback(view, "")
            local asked = table.concat(seen, ",")
            OUT = blob:find("Accelerant") and "named" or "clean"
            OUT = OUT .. "|" .. (blob:find("11069") and "id" or "noid")
            OUT = OUT .. "|" .. (blob:find("Missile Barrage") and "proc" or "noproc")
            OUT = OUT .. "|" .. asked
            OUT = OUT .. "|" .. tostring(view.spellID)
          """),
          "clean|noid|noproc|133|133")

    check("level does not invent the unknown third spell",
          eval_case(base + r"""
            ctx.ask = function(id)
                if id == 145 or id == 5143 then return "yes" end
                return "unknown"
            end
            ctx.spellbook = {
                { name = "Fireball", spellID = 145 },
                { name = "Arcane Missiles", spellID = 5143 },
            }
            local view = G.Evaluate(ctx)
            local feed = G.Feedback(view, "")
            local guessed = view.label == "Fire Blast" or view.label == "Frostbolt"
                or view.label == "Frost Nova" or view.label == "Polymorph"
                or feed:find("third spell")
            OUT = (view.label or "") .. "|" .. (guessed and "guess" or "open")
          """),
          "Fireball|open")

    # UI integration: the paint path has to put the action, the reason, the
    # situation choices, and a real edit box on the Spells surface.
    lua.execute(r"""
        local calls = {}
        local L = {}
        function L:SectionHeader(_, y, title, subtitle)
            calls[#calls + 1] = "H:" .. tostring(title) .. ":" .. tostring(subtitle or "")
            return y - 1
        end
        function L:Paragraph(_, y, text)
            calls[#calls + 1] = "P:" .. tostring(text)
            return y - 1
        end
        function L:Bullet(_, y, text)
            calls[#calls + 1] = "B:" .. tostring(text)
            return y - 1
        end
        function L:ButtonRow(_, y, buttons)
            local names = {}
            ALL_BUTTONS = ALL_BUTTONS or {}
            for _, b in ipairs(buttons) do
                names[#names + 1] = b.label
                ALL_BUTTONS[#ALL_BUTTONS + 1] = b
            end
            calls[#calls + 1] = "BTN:" .. table.concat(names, ",")
            return y - 1
        end
        function L:Divider(_, y) return y - 1 end

        local function widget(kind, name)
            local w = {
                kind = kind, name = name, text = "", scripts = {},
                multi = false, highlighted = false,
            }
            function w:SetMultiLine(v) self.multi = v and true or false end
            function w:SetText(v) self.text = v or "" end
            function w:GetText() return self.text or "" end
            function w:SetPoint() end
            function w:SetSize() end
            function w:SetWidth() end
            function w:SetAutoFocus(v) self.autoFocus = v and true or false end
            function w:SetTextInsets() end
            function w:EnableMouse() end
            function w:SetFontObject() end
            function w:SetFont(file, size) self.fontFile = file; self.fontSize = size end
            function w:ClearFocus() self.cleared = true end
            function w:GetChildren()
                if not self.children then return end
                return unpack(self.children)
            end
            function w:SetParent(parent)
                self.parent = parent
                for _, child in ipairs(self.children or {}) do
                    child.parent = nil
                end
            end
            function w:SetFocus() self.focused = true end
            function w:HighlightText() self.highlighted = true end
            function w:SetScript(ev, fn) self.scripts[ev] = fn end
            function w:GetScript(ev) return self.scripts[ev] end
            _G[name] = w
            return w
        end
        function CreateFrame(kind, name, parent, template)
            local w = widget(kind, name)
            w.template = template
            w.parent = parent
            return w
        end
        UIParent = {}

        local G = ToonAge.MageLevel12
        G._situation = nil
        G._notes = ""
        local ctx = {
            class = "MAGE", level = 12, situation = nil,
            ask = function(id) if id == 145 then return "yes" end return "unknown" end,
            spellbook = { { name = "Fireball", spellID = 145 } },
            wand = "unknown",
            version = "2.0.0-dev.1", build = "70862", interface = "16001",
            errors = { { time = "2026-11-08 06:00", source = "Button", msg = "sample boom" } },
        }
        local view = G.Evaluate(ctx)
        local y = G.Paint({}, -8, L, view)
        PAINT_Y = y
        PAINT = table.concat(calls, "\n")
        local copy = _G.TAMageGuideCopy
        local notes = _G.TAMageGuideNotes
        COPY_MULTI = copy and copy.multi
        COPY_TEXT = copy and copy.text or ""
        notes:SetText("tune the opener")
        notes:GetScript("OnTextChanged")(notes)
        COPY_AFTER = copy.text
        local selectBtn
        for _, b in ipairs(ALL_BUTTONS) do
            if b.label == "Select feedback text" then selectBtn = b end
            if b.label == "Low health or no mana" then FINISH_BTN = b end
        end
        selectBtn.onClick()
        SELECTED = copy.highlighted
        local function clears(box, event)
            local fn = box and box.GetScript and box:GetScript(event)
            if not fn then return false end
            box.cleared = false
            fn(box)
            return box.cleared == true
        end
        FOCUS = (clears(copy, "OnEscapePressed") and clears(copy, "OnEnterPressed")
            and clears(notes, "OnEscapePressed") and clears(notes, "OnEnterPressed")) and "yes" or "no"
        FONT = (type(copy.fontFile) == "string" and copy.fontFile ~= ""
            and type(notes.fontFile) == "string" and copy.autoFocus == false
            and notes.autoFocus == false and copy.template == "BackdropTemplate"
            and notes.template == "BackdropTemplate") and "yes" or "no"
        local kid = { parent = copy, shown = true }
        function kid:SetParent(parent) self.parent = parent end
        function kid:Show() self.shown = true end
        copy.children = { kid }
        G.Paint({}, -8, L, view)
        KID_PARENT = (kid.parent == copy and kid.shown) and "box" or "lost"
        local shown = table.concat(calls, "\n")
        LIMIT = (shown:find("Ctrl%+A") and shown:find("mouse wheel")
            and shown:find("not checked on a live client")) and "yes" or "no"
        ToonAge._refreshed = nil
        FINISH_BTN.onClick()
        REFRESHED = ToonAge._refreshed
        SITUATION = G.Situation()
    """)
    painted = lua.eval("PAINT")
    paint_y = lua.eval("PAINT_Y")
    check("paint returns a cursor", isinstance(paint_y, (int, float)) and paint_y < 0, True)
    check("the section is marked experimental",
          "EXPERIMENTAL SPELL GUIDE" in painted, True)
    check("the painted action is Fireball", "Fireball" in painted, True)
    check("the painted reason is the opener",
          "before the enemy reaches you" in painted, True)
    check("situation choices are buttons",
          "Pulling at range" in painted and "Enemy has reached me" in painted
          and "Low health or no mana" in painted and "Several mobs, solo" in painted, True)
    check("the copy box is multiline", lua.eval("COPY_MULTI"), True)
    copy_text = lua.eval("COPY_TEXT")
    check("the copy box holds the suggestion and the captured error",
          "Fireball" in copy_text and "sample boom" in copy_text, True)
    check("notes flow into the copy text",
          "tune the opener" in lua.eval("COPY_AFTER"), True)
    check("select focuses the copy box", lua.eval("SELECTED"), True)
    check("enter and escape leave the copy and notes boxes", lua.eval("FOCUS"), "yes")
    check("boxes use a backdrop template, a real font, and no autofocus",
          lua.eval("FONT"), "yes")
    check("reparenting after a rebuild keeps the box children",
          lua.eval("KID_PARENT"), "box")
    check("the copy instructions name the clipboard and scroll limits",
          lua.eval("LIMIT"), "yes")

    # A long wrapped reason plus a tall error list must stay inside a
    # viewport. Notes sit below that viewport. The edit box still holds
    # the whole generated string, including the lines past the viewport.
    lua.execute(r"""
        _G.TAMageGuideCopy = nil
        _G.TAMageGuideCopyScroll = nil
        _G.TAMageGuideNotes = nil
        _G.TAMageGuideMeasure = nil
        local L = {}
        function L:SectionHeader(_, y) return y - 1 end
        function L:Paragraph(_, y) return y - 1 end
        function L:Bullet(_, y) return y - 1 end
        function L:ButtonRow(_, y) return y - 1 end
        function L:Divider(_, y) return y - 1 end

        local function widget(kind, name)
            local w = {
                kind = kind, name = name, text = "", scripts = {},
                children = {},
            }
            function w:SetMultiLine(v) self.multi = v and true or false end
            function w:SetText(v) self.text = v or "" end
            function w:GetText() return self.text or "" end
            function w:SetPoint(_, _, _, _, y)
                if type(y) == "number" then self.pointY = y end
            end
            function w:SetSize(width, height)
                self.width = width
                self.height = height
                self.sized = true
            end
            function w:SetWidth(width) self.width = width end
            function w:SetHeight(height) self.height = height end
            function w:GetWidth() return self.width or 0 end
            function w:GetHeight() return self.height or 0 end
            function w:SetAutoFocus() end
            function w:SetTextInsets() end
            function w:EnableMouse() end
            function w:SetFontObject() end
            function w:SetFont(file, size, flags)
                self.fontFile = file
                self.fontSize = size
                self.fontFlags = flags
            end
            function w:ClearFocus() end
            function w:SetFocus() self.focused = true end
            function w:HighlightText() self.highlighted = true end
            function w:SetScript(ev, fn) self.scripts[ev] = fn end
            function w:GetScript(ev) return self.scripts[ev] end
            function w:GetChildren() return unpack(self.children) end
            function w:SetParent(parent)
                self.parent = parent
                self.scrollChild = nil
                for _, child in ipairs(self.children) do
                    child.parent = nil
                end
            end
            function w:SetScrollChild(child)
                self.scrollChild = child
                if child then child.parent = self end
            end
            function w:UpdateScrollChildRect()
                local child = self.scrollChild
                local ch = (child and child.GetHeight and child:GetHeight()) or 0
                local vh = self:GetHeight() or 0
                self.scrollRange = ch - vh
                if self.scrollRange < 0 then self.scrollRange = 0 end
                self.rectUpdated = true
            end
            function w:GetVerticalScrollRange()
                return self.scrollRange or 0
            end
            -- FontString:GetStringHeight is the client call. It wraps only
            -- after the string has the same font as the edit box, width 432,
            -- and an unconstrained height. An edit box does not get this method.
            function w:CreateFontString()
                local fs = { text = "", width = 0 }
                function fs:SetFont(file, size, flags)
                    self.fontFile = file
                    self.fontSize = size
                    self.fontFlags = flags
                end
                function fs:SetText(v) self.text = v or "" end
                function fs:SetWidth(width) self.width = width end
                function fs:SetHeight(h) self.height = h end
                function fs:Hide() self.hidden = true end
                function fs:GetStringHeight()
                    local newlines = 1
                    for _ in (self.text or ""):gmatch("\n") do newlines = newlines + 1 end
                    local ready = self.width == 432 and self.fontSize == 10
                        and self.height == 0 and type(self.text) == "string"
                    if not ready then return newlines * 10 end
                    local lines = 0
                    for line in ((self.text or "") .. "\n"):gmatch("(.-)\n") do
                        if #line == 0 then
                            lines = lines + 1
                        else
                            lines = lines + math.ceil(#line / 72)
                        end
                    end
                    return lines * 14
                end
                self.measure = fs
                return fs
            end
            function w:Show() self.shown = true end
            function w:Hide() self.shown = false end
            _G[name] = w
            return w
        end
        function CreateFrame(kind, name, parent, template)
            local w = widget(kind, name)
            w.template = template
            w.parent = parent
            if type(parent) == "table" then
                parent.children = parent.children or {}
                parent.children[#parent.children + 1] = w
            end
            return w
        end

        local G = ToonAge.MageLevel12
        G._notes = ""
        G._situation = nil
        local errors = {}
        for i = 1, 12 do
            errors[i] = { time = "t", source = "Button", msg = string.format("boom-%02d", i) }
        end
        local why = string.rep("cast before the enemy reaches you. ", 24) .. "WHYTAIL"
        local ctx = {
            class = "MAGE", level = 12, situation = "pull",
            ask = function(id) if id == 145 then return "yes" end return "no" end,
            spellbook = { { name = "Fireball", spellID = 145 } },
            wand = "unknown",
            version = "2.0.0-dev.1", build = "70862", interface = "16001",
            errors = errors,
        }
        local view = G.Evaluate(ctx)
        view.why = why
        local content = {}
        G.Paint(content, -8, L, view)
        local scroll = _G.TAMageGuideCopyScroll
        local copy = _G.TAMageGuideCopy
        local notes = _G.TAMageGuideNotes
        local text = copy and copy:GetText() or ""
        if copy and copy.HighlightText then copy:HighlightText() end
        local after = copy and copy:GetText() or ""
        LONG_SCROLL = (scroll and scroll.kind == "ScrollFrame") and "yes" or "no"
        LONG_CHILD = (scroll and scroll.scrollChild == copy) and "yes" or "no"
        local host = _G.TAMageGuideMeasure
        local fs = host and host.measure
        local newlines = 1
        for _ in text:gmatch("\n") do newlines = newlines + 1 end
        local wrapped = fs and fs:GetStringHeight() or 0
        LONG_EDIT_H = copy and copy:GetHeight() or 0
        LONG_TEXT_H = wrapped
        LONG_VIEW_H = scroll and scroll:GetHeight() or 0
        LONG_NOTES = (scroll and notes and type(scroll.pointY) == "number"
            and type(notes.pointY) == "number"
            and notes.pointY <= scroll.pointY - scroll:GetHeight()) and "yes" or "no"
        local kept = copy and copy.highlighted and after == text and text:find("WHYTAIL", 1, true)
        LONG_KEEP = kept and "yes" or "no"
        LONG_NO_EB = (copy and copy.GetStringHeight == nil) and "yes" or "no"
        LONG_MEASURE = (fs and fs.width == 432 and fs.fontSize == 10
            and fs.height == 0 and fs.fontFile == copy.fontFile
            and wrapped > newlines * 14 and copy.sized
            and LONG_EDIT_H >= wrapped) and "yes" or "no"
        local range = scroll and scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or 0
        LONG_REACH = (scroll and scroll.rectUpdated and range > 0
            and range >= LONG_EDIT_H - LONG_VIEW_H - 1) and "yes" or "no"
        local truncated = text:find("boom%-01", 1) and not text:find("boom%-09", 1)
            and text:find("truncated", 1, true) and text:find("/ta errors copy", 1, true)
        LONG_TRUNC = truncated and "yes" or "no"
    """)
    check("long feedback is in its own scroll frame", lua.eval("LONG_SCROLL"), "yes")
    check("the copy box is the scroll child", lua.eval("LONG_CHILD"), "yes")
    edit_h = lua.eval("LONG_EDIT_H")
    text_h = lua.eval("LONG_TEXT_H")
    view_h = lua.eval("LONG_VIEW_H")
    check("the measured text is taller than the viewport",
          isinstance(text_h, (int, float)) and text_h > 200, True)
    check("the viewport stays bounded",
          isinstance(view_h, (int, float)) and view_h > 0 and view_h <= 200, True)
    check("the edit box is tall enough for the measured text",
          isinstance(edit_h, (int, float)) and edit_h >= text_h, True)
    check("wrap is measured on a font string, not the edit box",
          lua.eval("LONG_NO_EB"), "yes")
    check("432px font measurement is taller than a newline count and is the set height",
          lua.eval("LONG_MEASURE"), "yes")
    check("the scroll range reaches the wrapped lines",
          lua.eval("LONG_REACH"), "yes")
    check("notes start below the feedback viewport", lua.eval("LONG_NOTES"), "yes")
    check("select keeps the full generated text, including the wrapped why",
          lua.eval("LONG_KEEP"), "yes")
    check("error lines past the bound are truncated and name the full log",
          lua.eval("LONG_TRUNC"), "yes")
    check("a situation button stores the choice and asks for a redraw",
          lua.eval("SITUATION") == "finish" and lua.eval("REFRESHED") == "mage-guide", True)
    check("an off-class view paints nothing",
          eval_case(base + r"""
            ctx.class = "PRIEST"
            local calls = 0
            local L = {}
            function L:Paragraph() calls = calls + 1 return 0 end
            function L:SectionHeader() calls = calls + 1 return 0 end
            local view = G.Evaluate(ctx)
            G.Paint({}, 0, L, view)
            OUT = tostring(view.applies) .. "|" .. calls
          """),
          "false|0")

    rot = ROTATION.read_text(encoding="utf-8")
    render = rot.split("function M:Render", 1)[1].split("function M:Init", 1)[0]
    check("the Spells tab calls the guide", "MageLevel12" in render, True)
    check("the legacy numbered list waits on the guide",
          "guided" in render and render.index("guided") < render.index("DrawList"), True)
    paint = rot.split("function M:PaintBar", 1)[1].split("function M:OnEvent", 1)[0]
    check("the icon bar yields when the guide applies",
          "Gate" in paint and paint.index("Gate") < paint.index("Resolve"), True)

    lua.execute((ROOT / "Core/Utils.lua").read_text(encoding="utf-8"))
    lua.execute(rot)
    lua.execute(r"""
        local M = ToonAge.modules.ForeverRotation
        local G = ToonAge.MageLevel12
        G._gate = true
        local bar = { hidden = false }
        function bar:Hide() self.hidden = true end
        function bar:Show() self.hidden = false end
        M._bar = bar
        M._barIcons = {}
        M:PaintBar()
        BAR_HIDDEN = bar.hidden
        G._gate = false
    """)
    check("the icon bar hides while the guide owns the tab",
          lua.eval("BAR_HIDDEN"), True)

    lua.execute((ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
        local G = ToonAge.MageLevel12
        local function slot(id)
            return function(path)
                if path == "GetInventoryItemID" then return true, id end
                if path == "GetItemInfo" then error("raw GetItemInfo") end
                return false, "missing"
            end
        end
        local function wandRow(req, classID, subID, equip)
            return "Wand", "item:1", 2, 5, req, "Weapon", "Wands", 1,
                equip or "INVTYPE_RANGED", 0, 0, classID, subID
        end
        GetItemInfo = function() error("raw global GetItemInfo") end
        C_Item = { GetItemInfo = function() return wandRow(1, 2, 19) end }
        MODERN = G.ReadWand(slot(99), 12)
        C_Item = nil
        GetItemInfo = function() return wandRow(1, 2, 19) end
        LEGACY = G.ReadWand(slot(99), 12)
        C_Item = { GetItemInfo = function() return nil end }
        GetItemInfo = nil
        MISSING = G.ReadWand(slot(99), 12)
        C_Item = { GetItemInfo = function() error("item boom") end }
        THREW = G.ReadWand(slot(99), 12)
        ToonAge.Utils = ToonAge.Utils or {}
        ToonAge.Utils.IsSecret = function(v) return v == "secret" end
        C_Item = { GetItemInfo = function() return wandRow("secret", 2, 19) end }
        SECRET = G.ReadWand(slot(99), 12)
        C_Item = { GetItemInfo = function() return wandRow(1, 2, 2) end }
        BOW = G.ReadWand(slot(50), 12)
    """)
    check("a modern client reads the wand through C_Item", lua.eval("MODERN"), "yes")
    check("a legacy client reads the wand through the global", lua.eval("LEGACY"), "yes")
    check("missing item data is unknown, not wand-absent", lua.eval("MISSING"), "unknown")
    check("a throwing item lookup is unknown", lua.eval("THREW"), "unknown")
    check("a secret item field is unknown", lua.eval("SECRET"), "unknown")
    check("a positive non-wand weapon is not a usable wand", lua.eval("BOW"), "no")
    guide_src = GUIDE.read_text(encoding="utf-8")
    check("the guide does not call the raw GetItemInfo global",
          'call("GetItemInfo"' not in guide_src and "C_Item" not in guide_src, True)
    check("the guide asks Compat for item data",
          "GetItemInfo" in guide_src and "Compat" in guide_src, True)

    lua.execute(r"""
        local M = ToonAge.modules.ForeverRotation
        local G = ToonAge.MageLevel12
        local bar = { hidden = true }
        function bar:Hide() self.hidden = true end
        function bar:Show() self.hidden = false end
        M._bar = bar
        M._barIcons = { {}, {}, {} }
        ToonAge._level = 20
        ToonAge._class = "MAGE"
        function ToonAge.Caps.Call(path)
            if path == "UnitLevel" then return true, ToonAge._level end
            if path == "UnitClass" then return true, "Mage", ToonAge._class end
            return false, "missing"
        end
        G._gate = true
        G._ctx = { class = "MAGE", level = 12, spellbookRead = "read", spellbook = {} }
        M._loadAsked = {}
        ToonAge._refreshed = nil
        M:OnEvent("SPELL_DATA_LOAD_RESULT", 999)
        M:PaintBar()
        OFF_GATE = G.Gate() and "yes" or "no"
        OFF_LEVEL = G._ctx and G._ctx.level or 0
        OFF_REFRESH = ToonAge._refreshed == nil and "no" or "yes"
        OFF_BAR = bar.hidden and "hidden" or "shown"
        ToonAge._refreshed = nil
        M:OnEvent("PLAYER_LEVEL_UP")
        LEVEL_GATE = G.Gate() and "yes" or "no"
        LEVEL_NOW = G._ctx and G._ctx.level or 0
        LEVEL_REFRESH = ToonAge._refreshed == "PLAYER_LEVEL_UP" and "yes" or "no"
        ToonAge._level = 12
        ToonAge._class = "WARRIOR"
        G._gate = true
        G._ctx = { class = "MAGE", level = 12, spellbookRead = "read" }
        ToonAge._refreshed = nil
        M:OnEvent("SPELLS_CHANGED")
        WRONG = (G.Gate() == false and G._ctx and G._ctx.class == "WARRIOR"
            and ToonAge._refreshed == "SPELLS_CHANGED") and "cleared" or "stale"
    """)
    check("an unrelated spell-data load keeps the guide and hides the icon bar",
          lua.eval("OFF_GATE") == "yes" and lua.eval("OFF_LEVEL") == 12
          and lua.eval("OFF_REFRESH") == "no" and lua.eval("OFF_BAR") == "hidden", True)
    check("a real level change leaves the 10-19 guide and redraws",
          lua.eval("LEVEL_GATE") == "no" and lua.eval("LEVEL_NOW") == 20
          and lua.eval("LEVEL_REFRESH") == "yes", True)
    check("a positive class change does not keep the mage guide",
          lua.eval("WRONG"), "cleared")

    lua.execute(r"""
        local G = ToonAge.MageLevel12
        local secret = {}
        ToonAge._secret = secret
        ToonAge.Utils = ToonAge.Utils or {}
        ToonAge.Utils.IsSecret = function(v)
            if v == secret then error("issecretvalue") end
            return false
        end
        local function call(path)
            if path == "UnitLevel" then return true, secret end
            if path == "UnitClass" then return true, secret, secret end
            if path == "GetBuildInfo" then return true, secret, secret, secret, secret end
            if path == "GetInventoryItemID" then return true, secret end
            return false, "missing"
        end
        ToonAge.version = secret
        ToonAge.Compat = { GetItemInfo = function() return secret, secret, secret, secret, secret, secret, secret, secret, secret, secret, secret, secret, secret end }
        local saved = ToonAge.Caps
        ToonAge.Caps = { Call = call }
        local ok, ctx = pcall(G.ReadLive, { { name = secret, spellID = secret } }, "read")
        SECRET_OK = ok
        SECRET_CLASS = ctx and ctx.class or "nil"
        SECRET_LEVEL = ctx and ctx.level or "nil"
        SECRET_VER = ctx and ctx.version or "nil"
        SECRET_BUILD = ctx and ctx.build or "nil"
        SECRET_IFACE = ctx and ctx.interface or "nil"
        SECRET_WAND = ctx and ctx.wand or "nil"
        SECRET_SHOOT = ctx and ctx.shootKnown or "nil"
        local feedOk, feed = pcall(G.Feedback, {
            applies = true, press = false, level = secret, className = secret,
            version = secret, build = secret, interface = secret, wand = secret,
            learned = {}, unknown = {}, tierB = {},
        }, secret)
        FEED_OK = feedOk
        FEED_LEVEL = feedOk and (feed:find("Level: unknown", 1, true) and "unknown" or "leaked") or "throw"
        ToonAge.Utils.IsSecret = function() error("predicate down") end
        local ok2, ctx2 = pcall(G.ReadLive, { { name = "Shoot" } }, "read")
        CLOSED_OK = ok2
        CLOSED_LEVEL = ctx2 and ctx2.level or "nil"
        CLOSED_SHOOT = ctx2 and ctx2.shootKnown or "nil"
        ToonAge.Caps = saved
        ToonAge.Utils.IsSecret = function() return false end
        ToonAge.version = "2.0.0-dev.1"
    """)
    check("a throwing secret predicate does not accept class, level, version, build, or interface",
          lua.eval("SECRET_OK") == True and lua.eval("SECRET_CLASS") == "nil"
          and lua.eval("SECRET_LEVEL") == "nil" and lua.eval("SECRET_VER") == "nil"
          and lua.eval("SECRET_BUILD") == "nil" and lua.eval("SECRET_IFACE") == "nil"
          and lua.eval("SECRET_WAND") == "unknown" and lua.eval("SECRET_SHOOT") == "unknown"
          and lua.eval("FEED_OK") == True and lua.eval("FEED_LEVEL") == "unknown", True)
    check("a predicate that always throws fails closed",
          lua.eval("CLOSED_OK") == True and lua.eval("CLOSED_LEVEL") == "nil"
          and lua.eval("CLOSED_SHOOT") == "unknown", True)

    lua.execute(r"""
        local G = ToonAge.MageLevel12
        local secret = {}
        ToonAge._phase = "good"
        ToonAge.Utils = ToonAge.Utils or {}
        ToonAge.Utils.IsSecret = function(v) return v == secret end
        ToonAge.Compat = { GetItemInfo = function()
            if ToonAge._phase == "removed" then return nil end
            return "Wand", "item:99", 2, 5, 1, "Weapon", "Wands", 1,
                "INVTYPE_RANGED", 0, 0, 2, 19
        end }
        function ToonAge.Caps.Call(path)
            if path == "UnitLevel" then
                if ToonAge._phase == "levelsecret" then return true, secret end
                if ToonAge._phase == "throw" then error("read failed") end
                return true, 12
            end
            if path == "UnitClass" then
                if ToonAge._phase == "classmissing" or ToonAge._phase == "throw" then
                    return false, "missing"
                end
                return true, "Mage", "MAGE"
            end
            if path == "GetInventoryItemID" then
                if ToonAge._phase == "throw" then error("read failed") end
                if ToonAge._phase == "good" then return true, 99 end
                return true, nil
            end
            if path == "GetBuildInfo" then return true, "1.60.1", "70862", "d", 16001 end
            return false, "missing"
        end
        local function finish(view)
            return tostring(view.press) .. "|" .. (view.label or "") .. "|" .. (view.wand or "")
        end
        G._situation = "finish"
        G.RefreshGate({ { name = "Fireball", spellID = 145 }, { name = "Shoot" } }, "read")
        local first = G.Evaluate(G.Context())
        STALE_FIRST = finish(first)
        ToonAge._phase = "levelsecret"
        -- wand removed and Shoot dropped, while level is secret
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        local mid = G.Evaluate(G.Context())
        local feed = G.Feedback(mid, "")
        STALE_MID = finish(mid)
        STALE_HIST = (feed:find("not a current action", 1, true)
            and not feed:find("Suggestion: Shoot", 1, true)
            and not feed:find("Suggestion: Fireball", 1, true)) and "held" or "live"
        ToonAge._phase = "classmissing"
        G.RefreshGate({}, "read")
        local changed = G.Evaluate(G.Context())
        STALE_CHANGED = finish(changed)
        ToonAge._phase = "throw"
        G._ctx = { class = "MAGE", level = 12, wand = "yes", shootKnown = "yes",
            spellbook = { { name = "Shoot" } }, spellbookRead = "read", withheld = false }
        G._gate = true
        G.RefreshGate({ { name = "Shoot" } }, "read")
        local blown = G.Evaluate(G.Context())
        STALE_THROW = finish(blown)
        ToonAge._phase = "recover"
        G._situation = "pull"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        local back = G.Evaluate(G.Context())
        STALE_BACK = tostring(back.press) .. "|" .. (back.label or "") .. "|" .. (back.wand or "")
            .. "|" .. (G.Gate() and "guide" or "icons")
    """)
    check("a fresh Shoot and wand-type context is established",
          lua.eval("STALE_FIRST"), "true|Shoot|yes")
    check("removing the wand while level is secret does not keep Shoot as current",
          lua.eval("STALE_MID") == "false||no" and lua.eval("STALE_HIST") == "held", True)
    check("a changed spellbook while class is unknown does not revive the old wand",
          lua.eval("STALE_CHANGED"), "false||no")
    check("a thrown read does not keep Shoot or the old wand as current",
          lua.eval("STALE_THROW"), "false||unknown")
    check("a fresh class and level restore the guide from the new read",
          lua.eval("STALE_BACK"), "true|Fireball|no|guide")

    lua.execute(r"""
        local G = ToonAge.MageLevel12
        local secret = {}
        ToonAge._mode = "unread"
        ToonAge.Utils.IsSecret = function(v) return v == secret end
        function ToonAge.Caps.Call(path)
            local mode = ToonAge._mode
            if path == "UnitLevel" then
                if mode == "twenty" then return true, 20 end
                if mode == "level30" then return true, 30 end
                if mode == "secretlevel" then return true, secret end
                if mode == "unread" or mode == "warriorunknown" then return false, "missing" end
                return true, 12
            end
            if path == "UnitClass" then
                if mode == "warrior" or mode == "warriorunknown" then
                    return true, "Warrior", "WARRIOR"
                end
                if mode == "unread" or mode == "noclass" or mode == "level30" then
                    return false, "missing"
                end
                return true, "Mage", "MAGE"
            end
            if path == "GetInventoryItemID" then return true, nil end
            return false, "missing"
        end
        local function reset()
            G._gate = false
            G._ctx = nil
            G._scope = nil
            G._historical = nil
        end
        local function place()
            local on = G.Gate() and "on" or "off"
            local view = G.Evaluate(G.Context())
            return on .. "|" .. tostring(view.applies) .. "|" .. tostring(view.press)
                .. "|" .. (view.label or "")
        end
        reset()
        ToonAge._mode = "warrior"
        G.RefreshGate({}, "read")
        ToonAge._mode = "unread"
        G.RefreshGate(nil, "unreadable")
        SCOPE_WARRIOR = place()
        reset()
        ToonAge._mode = "twenty"
        G.RefreshGate({}, "read")
        ToonAge._mode = "unread"
        G.RefreshGate(nil, "unreadable")
        SCOPE_TWENTY = place()
        reset()
        ToonAge._mode = "unread"
        G.RefreshGate(nil, "unreadable")
        G.RefreshGate(nil, "unreadable")
        SCOPE_INITIAL = place()
        reset()
        ToonAge._mode = "mage"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        ToonAge._mode = "warrior"
        G.RefreshGate({}, "read")
        ToonAge._mode = "unread"
        G.RefreshGate(nil, "unreadable")
        SCOPE_AFTER_WARRIOR = place()
        reset()
        ToonAge._mode = "mage"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        ToonAge._mode = "twenty"
        G.RefreshGate({}, "read")
        ToonAge._mode = "secretlevel"
        G.RefreshGate(nil, "unreadable")
        SCOPE_AFTER_TWENTY = place()
        reset()
        ToonAge._mode = "mage"
        G.RefreshGate({ { name = "Fireball", spellID = 145 }, { name = "Shoot" } }, "read")
        ToonAge._mode = "unread"
        G.RefreshGate(nil, "unreadable")
        SCOPE_HELD = place()
        reset()
        ToonAge._mode = "mage"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        ToonAge._mode = "warriorunknown"
        G.RefreshGate({}, "read")
        SCOPE_WARRIOR_LEVEL = place()
        reset()
        ToonAge._mode = "mage"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        ToonAge._mode = "level30"
        G.RefreshGate({}, "read")
        SCOPE_LEVEL30 = place()
        ToonAge._mode = "mage"
        G._situation = "pull"
        G.RefreshGate({ { name = "Fireball", spellID = 145 } }, "read")
        local back = G.Evaluate(G.Context())
        SCOPE_BACK = (G.Gate() and "on" or "off") .. "|" .. tostring(back.press)
            .. "|" .. (back.label or "")
        ToonAge.Utils.IsSecret = function() return false end
        function ToonAge.Caps.Call(path)
            if path == "UnitLevel" then return true, 0/0 end
            if path == "UnitClass" then return true, "Mage", "MAGE" end
            return false, "missing"
        end
        local nanCtx = G.ReadLive({}, "read")
        local nanOk, nanFeed = pcall(G.Feedback, {
            level = 0/0, learned = {}, unknown = {}, tierB = {},
            errors = { { time = "t", source = "Button", msg = "kept-msg" } },
        }, "")
        NAN_LEVEL = nanCtx.level == nil and "nil" or "kept"
        NAN_FEED = (nanOk and nanFeed:find("Level: unknown", 1, true)
            and not nanFeed:find("nan", 1, true) and nanFeed:find("kept-msg", 1, true))
            and "ok" or "bad"
        function ToonAge.Caps.Call(path)
            if path == "UnitLevel" then return true, math.huge end
            if path == "UnitClass" then return true, "Mage", "MAGE" end
            return false, "missing"
        end
        local infCtx = G.ReadLive({}, "read")
        INF_LEVEL = infCtx.level == nil and "nil" or "kept"
    """)
    check("a warrior read then an unread stays off", lua.eval("SCOPE_WARRIOR"), "off|false|false|")
    check("a level 20 read then an unread stays off", lua.eval("SCOPE_TWENTY"), "off|false|false|")
    check("an initial unread stays off", lua.eval("SCOPE_INITIAL"), "off|false|false|")
    check("mage 12 then a warrior then an unread stays off",
          lua.eval("SCOPE_AFTER_WARRIOR"), "off|false|false|")
    check("mage 12 then level 20 then an unknown level stays off",
          lua.eval("SCOPE_AFTER_TWENTY"), "off|false|false|")
    check("a shown mage 12 guide can withhold on an unread without a current spell",
          lua.eval("SCOPE_HELD"), "on|true|false|")
    check("a known warrior turns the guide off even when level is unknown",
          lua.eval("SCOPE_WARRIOR_LEVEL"), "off|false|false|")
    check("a known level 30 turns the guide off even when class is unknown",
          lua.eval("SCOPE_LEVEL30"), "off|false|false|")
    check("NaN and infinity are not levels, and an error line stays text",
          lua.eval("NAN_LEVEL") == "nil" and lua.eval("INF_LEVEL") == "nil"
          and lua.eval("NAN_FEED") == "ok", True)
    check("a fresh mage 12 read after that unread shows the new guide",
          lua.eval("SCOPE_BACK"), "on|true|Fireball")

    passed = sum(_results)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
