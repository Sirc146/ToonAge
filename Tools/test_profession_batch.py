#!/usr/bin/env python3
"""Manual batch calculator and the learned-recipe gate.

The calculator is usable from typed fields. A missing ingredient list is not
free profit. Per-craft reagent need is multiplied by the batch size. Buy
quantity is the cash paid. The open profession window is not treated as this
character's learned list unless ownership is explicitly verified.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def main():
    src_batch = (ROOT / "Modules/Character/ProfessionBatch.lua").read_text(encoding="utf-8")
    src_api = (ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8")
    src_board = (ROOT / "Modules/Character/ProfessionBoard.lua").read_text(encoding="utf-8")
    src_manifest = (ROOT / "Data/Forever/ApiManifest.lua").read_text(encoding="utf-8")
    check("batch file does not register events", "RegisterEvent" not in src_batch, True)
    check("batch file does not call UnitGUID", "UnitGUID" not in src_batch, True)
    check("batch file does not call GetBuildInfo", "GetBuildInfo" not in src_batch, True)
    for banned in ("TRADE_SKILL_UPDATE", "TRADE_SKILL_SHOW", "CRAFT_SHOW", "CRAFT_UPDATE", "LEARNED_SPELL_IN_TAB"):
        check(f"batch file does not name {banned}", banned not in src_batch, True)
    check("board reads the form, not an unset manualBatch", "PB.manualBatch" not in src_board, True)
    check("board builds the batch from the fields", "InputFromForm" in src_board, True)
    check("manifest lists UnitGUID", '["UnitGUID"]' in src_manifest, True)
    check("manifest lists GetBuildInfo", '["GetBuildInfo"]' in src_manifest, True)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { flavor = 'forever', IsForever = true, modules = {} }\nfunction ToonAge:RegisterModule() end\n")
    lua.execute(src_batch)
    lua.execute(r"""
PB = ToonAge.ProfessionBatch
id = { guid = "Player-1", flavor = "forever", build = "70840", interface = 16001, project = 18, ruleset = "PvE" }
owned = { { id = 197, name = "Tailoring" }, { id = 185, name = "Cooking" } }
store = { history = {} }

function names(list)
    local t = {}
    for i = 1, #list do t[#t + 1] = list[i].profession .. ":" .. list[i].name end
    table.sort(t)
    return table.concat(t, ",")
end

r1 = PB.ApplyLearned(store, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = {
        { id = 10, name = "Bolt of Linen", learned = true },
        { id = 11, name = "White Bandit Mask", learned = nil },
        { id = 12, name = "Red Linen Robe", learned = false },
    },
}, owned)
shown = names(PB.WorkingRecipes(store, id, owned))
rEmpty = PB.ApplyLearned(store, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false, rows = {},
}, owned)
afterEmpty = names(PB.WorkingRecipes(store, id, owned))
rFail = PB.ApplyLearned(store, id, { status = "unreadable", professionID = 197 }, owned)
afterFail = names(PB.WorkingRecipes(store, id, owned))
rCook = PB.ApplyLearned(store, id, {
    status = "read", professionID = 185, ownerContext = "verified", linked = false,
    rows = { { id = 99, name = "Spice Bread", learned = true } },
}, owned)
other = { guid = "Player-1", flavor = "forever", build = "70862", interface = 16001, project = 18, ruleset = "PvE" }
PB.ApplyLearned(store, other, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = { { id = 20, name = "Bolt of Wool", learned = true } },
}, owned)
oldKept = store.history[1].professions[197].recipes["10"].name
currentNames = names(PB.WorkingRecipes(store, other, owned))
staleNames = names(PB.WorkingRecipes(store, id, owned))
incomplete = { guid = "Player-1", flavor = "forever", build = "70840", interface = 16001, project = 18 }
rIdentity = PB.ApplyLearned(store, incomplete, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = { { id = 30, name = "Should Not Save", learned = true } },
}, owned)
noGhost = store.current.professions[197].recipes["30"] == nil
issecretvalue = function(v) return v == "SECRET" end
rSecret = PB.ApplyLearned(store, {
    guid = "SECRET", flavor = "forever", build = "70840", interface = 16001, project = 18, ruleset = "PvE",
}, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = { { id = 31, name = "Secret Guild", learned = true } },
}, owned)
unavailable = PB.ApplyLearned(store, id, { status = "unavailable" }, owned)

function batch(extra, clear)
    local input = {
        n = 1, cut = 0.05, vendorBuy = 1,
        outputs = { { count = 1, price = 100 }, { count = 1, price = 40 } },
        reagents = { { need = 30, owned = 20, price = 2, buyQty = 10, buyPrice = 3 } },
        lostCraftDeposit = 2, lostRawDeposit = 1, activeSeconds = 120,
        refundableDeposit = 5,
    }
    for k, v in pairs(extra or {}) do input[k] = v end
    for _, k in ipairs(clear or {}) do input[k] = nil end
    return PB.CompareBatch(input)
end
full = batch()
missingPrice = batch({ outputs = { { count = 1, price = 100 }, { count = 1 } } })
missingCount = batch({ outputs = { { count = 1 }, { count = 1, price = 40 } } })
noTime = batch(nil, { "activeSeconds" })
unknownLoss = batch(nil, { "lostCraftDeposit" })
noBuy = batch({ reagents = { { need = 30, owned = 20, price = 2 } } })
noOwned = batch({ reagents = { { need = 30, price = 2, buyQty = 30, buyPrice = 3 } } })
noVendor = batch(nil, { "vendorBuy" })
nilReagents = PB.CompareBatch({
    n = 1, cut = 0, vendorBuy = 0,
    outputs = { { count = 1, price = 100 } },
    lostCraftDeposit = 0, lostRawDeposit = 0,
})
overBuy = batch({ reagents = { { need = 30, owned = 20, price = 2, buyQty = 50, buyPrice = 3 } } })
huge = batch({ n = math.huge })
local secretRefund = setmetatable({}, { __tostring = function() error("tostring deposit") end })
issecretvalue = function(v) return rawequal(v, secretRefund) end
secretRefundResult = batch({ refundableDeposit = secretRefund })
noRefund = batch(nil, { "refundableDeposit" })
double = batch({
    n = 2,
    reagents = { { need = 30, owned = 20, price = 2, buyQty = 40, buyPrice = 3 } },
})
local secretName = setmetatable({}, { __tostring = function() error("tostring name") end })
local secretId = setmetatable({}, { __tostring = function() error("tostring id") end })
issecretvalue = function(v) return rawequal(v, secretName) or rawequal(v, secretId) end
secretStore = { history = {} }
rSecretRow = PB.ApplyLearned(secretStore, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = {
        { id = secretId, name = secretName, learned = true },
        { id = 10, name = "Bolt of Linen", learned = true },
    },
}, owned)
secretKept = secretStore.current.professions[197].recipes["10"].name
local foundSecretKey = false
for k in pairs(secretStore.current.professions[197].recipes) do
    if type(k) ~= "string" or k == "10" then else foundSecretKey = true end
end
secretKeyed = foundSecretKey

rSchn = PB.ApplyLearned({ history = {} }, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = { { id = 10, name = "Bolt of Linen", learned = true } },
}, { { id = 197, name = "Schneiderei" } })
schnName = names(PB.WorkingRecipes(rSchn and { current = nil } or {}, id, {}))
schnStore = { history = {} }
PB.ApplyLearned(schnStore, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = { { id = 10, name = "Bolt of Linen", learned = true } },
}, { { id = 197, name = "Schneiderei" } })
schnName = names(PB.WorkingRecipes(schnStore, id, { { id = 197, name = "Schneiderei" } }))
rLinked = PB.ApplyLearned({ history = {} }, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = true,
    rows = { { id = 77, name = "OtherPlayersBolt", learned = true } },
}, owned)
unknownOwner = PB.ApplyLearned({ history = {} }, id, {
    status = "read", professionID = 197, linked = false,
    rows = { { id = 77, name = "OtherPlayersBolt", learned = true } },
}, owned)

PB.views = {}
two = { history = {} }
PB.ApplyLearned(two, id, {
    status = "read", professionID = 197, ownerContext = "verified", linked = false,
    rows = {
        { id = 10, name = "Bolt of Linen", learned = true },
        { id = 20, name = "Bolt of Wool", learned = true },
    },
}, owned)
PB.Read = function() return { status = "unreadable", professionID = 197 } end
PB.LiveIdentity = function() return id end
PB:Refresh(owned)
failNote = PB.lastNote
failView = names(PB.CurrentView(id))
PB.Read = function()
    return {
        status = "read", professionID = 197, ownerContext = "verified", linked = false,
        rows = { { id = 10, name = "Bolt of Linen", learned = true } },
    }
end
PB.Store = function() return two end
PB:Refresh(owned)
filterView = names(PB.CurrentView(id))

local typed = {}
PB.form = { reagents = 1, outputs = 2, text = {} }
PB.boxes = {}
local function field(key)
    if not PB.boxes[key] then
        PB.boxes[key] = {
            hidden = false, fieldKey = key,
            GetText = function(self) return typed[self.fieldKey] or "" end,
        }
    end
end
local function set(key, value) typed[key] = value; field(key) end
local linenFields = {
    n = "1", cut = "0.05", vendor = "1", lostCraft = "2", lostRaw = "1", refund = "5", seconds = "120",
    reag1need = "30", reag1owned = "20", reag1price = "2", reag1buyQty = "10", reag1buyPrice = "3",
    out1count = "1", out1price = "100", out2count = "1", out2price = "40",
}
for key, value in pairs(linenFields) do set(key, value) end
formOk = PB.CompareBatch(PB.InputFromForm())
set("lostCraft", "abc")
badDeposit = PB.CompareBatch(PB.InputFromForm())
set("lostCraft", "2")
set("refund", "abc")
badRefund = PB.CompareBatch(PB.InputFromForm())
set("refund", "5")
set("reag1need", "30")
set("reag1owned", "30")
set("reag1buyQty", "nope")
set("reag1buyPrice", "")
badBuy = PB.CompareBatch(PB.InputFromForm())
set("reag1buyQty", "")
set("reag1buyPrice", "nope")
badBuyPrice = PB.CompareBatch(PB.InputFromForm())
set("reag1buyQty", "")
set("reag1buyPrice", "")
coveredBlank = PB.CompareBatch(PB.InputFromForm())

overflowCraft = batch({
    cut = 0, vendorBuy = 0,
    outputs = { { count = 2, price = 1e308 } },
    reagents = { { need = 1, owned = 1, price = 0 } },
    lostCraftDeposit = 0, lostRawDeposit = 0,
}, { "refundableDeposit" })
overflowRate = batch({
    cut = 0, vendorBuy = 0,
    outputs = { { count = 1, price = 1e306 } },
    reagents = { { need = 1, owned = 1, price = 0 } },
    lostCraftDeposit = 0, lostRawDeposit = 0,
    activeSeconds = 1,
}, { "refundableDeposit" })

readerCalls = 0
PB.Read = function()
    readerCalls = readerCalls + 1
    return {
        status = "read", professionID = 197,
        rows = { { id = 99, name = "Live Bolt", learned = true } },
    }
end
savedBeforeRefresh = names(PB.CurrentView(id))
blockedRefresh = PB:Refresh(owned)
refreshView = names(PB.CurrentView(id))
refreshNote = PB.lastNote or ""
""")
    g = lua.globals()
    check("a positive learned flag is stored", g.r1.saved, True)
    check("the working list is the learned tailoring recipe", g.shown, "Tailoring:Bolt of Linen")
    check("an empty read does not erase the positive row", g.afterEmpty, "Tailoring:Bolt of Linen")
    check("a failed read does not erase the positive row", g.afterFail, "Tailoring:Bolt of Linen")
    check("cooking is not a calculator profession", g.rCook.reason, "profession")
    check("a build change keeps the old record", g.oldKept, "Bolt of Linen")
    check("the new build's list is only its own positive row", g.currentNames, "Tailoring:Bolt of Wool")
    check("the old build is not the current list", g.staleNames, "")
    check("a missing ruleset does not save", g.rIdentity.saved, False)
    check("a missing ruleset does not add the row", g.noGhost, True)
    check("a secret guid does not save", g.rSecret.saved, False)
    check("an unavailable read does not save", g.unavailable.saved, False)
    check("the linen example net is 63", g.full.net, 63)
    check("the refundable deposit is tied up, not subtracted", g.full.tiedUp, 5)
    check("known losses make the net complete", g.full.incomplete, False)
    check("the active hour uses 120 measured seconds", g.full.rate, 1890)
    check("a missing output price blocks the net", g.missingPrice.ok, False)
    check("a missing output count blocks the net", g.missingCount.reason, "output")
    check("missing active seconds withholds the rate", g.noTime.rate, None)
    check("missing active seconds still returns the net", g.noTime.ok, True)
    check("an unknown listing loss is conditional", g.unknownLoss.incomplete, True)
    check("an unknown craft loss is omitted, and the known raw loss is added", g.unknownLoss.net, 65)
    check("a shortfall without a buy price blocks the net", g.noBuy.reason, "shortfall")
    check("a missing owned count blocks the net", g.noOwned.reason, "reagent")
    check("a missing vendor entry blocks the net", g.noVendor.reason, "vendor")
    check("the result has no elapsed-throughput field", g.full.elapsed, None)
    check("the net is not realized profit", g.full.realized, False)
    check("a missing reagent list is not free profit", g.nilReagents.reason, "reagent")
    check("a missing reagent list has no net", g.nilReagents.net, None)
    check("buy quantity above the shortfall is the cash paid", g.overBuy.net, -57)
    check("an infinite batch size is rejected", g.huge.ok, False)
    check("a secret refundable deposit is not a finished net", g.secretRefundResult.ok, False)
    check("a secret refundable deposit is withheld", g.secretRefundResult.reason, "deposit")
    check("a secret refundable deposit has no net", g.secretRefundResult.net, None)
    check("a secret refundable deposit is not reported as zero tied up", g.secretRefundResult.tiedUp, None)
    check("an omitted refundable deposit stays a zero tie-up", g.noRefund.tiedUp, 0)
    check("an omitted refundable deposit still has the linen net", g.noRefund.net, 63)
    check("batch size multiplies the per-craft reagent need", g.double.net, 106)
    check("a secret recipe id is not stored", g.secretKept, "Bolt of Linen")
    check("a secret id is not used as a key", g.secretKeyed, False)
    check("Schneiderei is accepted by skill line id", g.schnName, "Schneiderei:Bolt of Linen")
    check("a linked profession window is not saved", g.rLinked.reason, "linked")
    check("a missing owner context is not the player's", g.unknownOwner.reason, "owner")
    check("a failed read keeps both saved names", g.failView, "Tailoring:Bolt of Linen,Tailoring:Bolt of Wool")
    check("a failed read does not say the ruleset blocked it", "ruleset" not in g.failNote, True)
    check("a filtered read does not shrink the saved view", g.filterView, "Tailoring:Bolt of Linen,Tailoring:Bolt of Wool")
    check("typed linen fields still net 63", g.formOk.net, 63)
    check("a non-numeric deposit is not a blank", g.badDeposit.ok, False)
    check("a non-numeric deposit names the field", g.badDeposit.reason, "lostCraft is not a number")
    check("a non-numeric deposit has no net", g.badDeposit.net, None)
    check("a non-numeric refund is not tied up at zero", g.badRefund.ok, False)
    check("a non-numeric refund names the field", g.badRefund.reason, "refund is not a number")
    check("a non-numeric refund has no tied-up figure", g.badRefund.tiedUp, None)
    check("a bad buy quantity is not ignored when stock covers the craft", g.badBuy.reason, "reag1buyQty is not a number")
    check("a bad buy price is not ignored when stock covers the craft", g.badBuyPrice.reason, "reag1buyPrice is not a number")
    check("a blank buy stays optional when stock covers the craft", g.coveredBlank.ok, True)
    check("a blank buy when stock covers the craft has a finite net", g.coveredBlank.net, 74)
    check("finite output arithmetic that overflows is withheld", g.overflowCraft.ok, False)
    check("overflow names the reason", g.overflowCraft.reason, "overflow")
    check("an overflowing craft has no net", g.overflowCraft.net, None)
    check("an overflowing craft has no infinite rate", g.overflowCraft.rate, None)
    check("a finite net whose hour overflows is withheld", g.overflowRate.ok, False)
    check("an overflowing hour has no net", g.overflowRate.net, None)
    check("an overflowing hour has no rate", g.overflowRate.rate, None)
    check("refresh does not enumerate live recipe ids", g.readerCalls, 0)
    check("refresh does not invent an owner", g.blockedRefresh.reason, "owner")
    check("refresh keeps the saved recipes", g.refreshView, g.savedBeforeRefresh)
    check("refresh says the recipe list was not read", "not read" in (g.refreshNote or ""), True)

    lua.execute(src_api)
    lua.execute(r"""
guidCalls = 0
function ToonAge:HasAPI(path) return path ~= "UnitGUID" end
UnitGUID = function() guidCalls = guidCalls + 1; return "Player-1" end
blockedGuid = ToonAge.Compat.PlayerGUID()
function ToonAge:HasAPI() return true end
C_TradeSkillUI = {
    GetAllRecipeIDs = function() return { 10, 11 } end,
    GetRecipeInfo = function(id)
        if id == 10 then return { name = "Bolt of Linen", learned = true } end
        return { name = "White Bandit Mask" }
    end,
    GetBaseProfessionInfo = function() return { professionID = 197, professionName = "Tailoring" } end,
}
obs = ToonAge.Compat.ReadTradeSkillRecipes()
positive = 0
for _, row in ipairs(obs.rows) do if row.learned == true then positive = positive + 1 end end
liveAdopt = PB.ApplyLearned({ history = {} }, id, obs, owned)
C_TradeSkillUI = nil
missing = ToonAge.Compat.ReadTradeSkillRecipes()
""")
    check("ApiGuard blocks a raw UnitGUID call", g.guidCalls, 0)
    check("a blocked guid is not returned", g.blockedGuid, None)
    check("the client read keeps a positive learned flag", g.positive, 1)
    check("the client read does not invent learned for a missing flag", g.obs.rows[2].learned, None)
    check("presence of the recipe API is not an owner proof", g.obs.ownerContext, None)
    check("an unverified client read is not saved as the player's", g.liveAdopt.reason, "owner")
    check("a missing trade-skill API is unavailable", g.missing.status, "unavailable")

    ui = lua51.LuaRuntime(unpack_returned_tuples=True)
    ui.execute(r"""
ToonAge = { flavor = "forever", IsForever = true, modules = {}, UI = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:HasAPI() return true end
texts = {}
buttons = {}
edits = {}
function CreateFrame(kind)
    local f = { kind = kind, text = "", scripts = {}, shown = true }
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:SetPoint() end
    function f:SetSize() end
    function f:SetFontObject() end
    function f:SetAutoFocus() end
    function f:SetFocus() self.focused = true end
    function f:ClearFocus() end
    function f:Show() self.shown = true; self.hidden = false end
    function f:Hide() self.shown = false; self.hidden = true end
    function f:SetTextInsets() end
    function f:SetJustifyH() end
    if kind == "EditBox" then edits[#edits + 1] = f end
    return f
end
ToonAge.Layout = {
    CharacterSidebar = function() end,
    SectionHeader = function(_, _, y, title) texts[#texts + 1] = title; return (y or 0) - 8 end,
    Paragraph = function(_, _, y, text) texts[#texts + 1] = text; return (y or 0) - 8 end,
    ProfessionCard = function(_, _, y) return (y or 0) - 8 end,
    ButtonRow = function(_, _, y, btns)
        for _, b in ipairs(btns) do buttons[b.label] = b.onClick end
        return (y or 0) - 8
    end,
    Finish = function() end,
}
ToonAge.ProfessionSkills = { Collect = function()
    return { reader = "skillinfo", cards = { { id = 197, name = "Schneiderei", rank = 23, max = 75 } } }
end }
content = {}
ToonAge.UI = { contentChild = content, sideChild = {}, activeTab = "professions" }
""")
    ui.execute(src_batch)
    ui.execute(src_board)
    ui.execute(r"""
ToonAge.modules.ProfessionBoard:Render(content, {})
buttons["Add output"]()
function put(key, value)
    for i = 1, #edits do
        if edits[i].fieldKey == key then edits[i]:SetText(value) end
    end
end
put("n", "1")
put("cut", "0.05")
put("vendor", "1")
put("lostCraft", "2")
put("lostRaw", "1")
put("refund", "5")
put("seconds", "120")
put("reag1need", "30")
put("reag1owned", "20")
put("reag1price", "2")
put("reag1buyQty", "10")
put("reag1buyPrice", "3")
put("out1count", "1")
put("out1price", "100")
put("out2count", "1")
put("out2price", "40")
texts = {}
buttons["Calculate batch"]()
firstResult = table.concat(texts, "\n")
put("reag1buyQty", "50")
texts = {}
buttons["Calculate batch"]()
secondResult = table.concat(texts, "\n")
texts = {}
ToonAge.modules.ProfessionBoard:Render(content, {})
keptN = nil
for i = 1, #edits do
    if edits[i].fieldKey == "n" and not edits[i].hidden then keptN = edits[i]:GetText() end
end
tabbed = false
for i = 1, #edits do
    if edits[i].fieldKey == "n" and edits[i].scripts.OnTabPressed then
        edits[i].scripts.OnTabPressed()
        tabbed = true
    end
end
""")
    ug = ui.globals()
    check("typing the linen batch produces 63 gold", "63.0000" in ug.firstResult, True)
    check("the result says it is not realized profit", "not realized profit" in ug.firstResult, True)
    check("changing the buy quantity in the field changes the result", "63.0000" not in ug.secondResult and "-57.0000" in ug.secondResult, True)
    check("a redraw keeps the typed batch size", ug.keptN, "1")
    check("tab moves focus to the next field", ug.tabbed, True)
    ui.execute(r"""
put("n", "")
texts = {}
buttons["Calculate batch"]()
withheld = table.concat(texts, "\n")
""")
    check("an empty batch size says why it was withheld", "withheld: batch" in ui.globals().withheld, True)

    passed = sum(_results)
    total = len(_results)
    print(f"\n{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
