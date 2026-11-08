-- Manual batch comparison, and a learned-recipe store that does not
-- guess who owns the open profession window.
--
-- The calculator uses numbers typed into the professions tab. It does not
-- read bags, the bank, or the auction house, and it does not craft or trade.
-- Reagent need and output count are per craft and are multiplied by the
-- batch size. Buy cost is the quantity paid times the price paid.
--
-- A client recipe row becomes a saved learned recipe only when the caller
-- passes ownerContext "verified" and linked false, and the profession id is
-- one of this character's Tailoring (197), Leatherworking (165), or
-- Blacksmithing (164) cards. The live reader never sets that owner context.
-- An empty, failed, or unverified read does not erase a previous positive.

local TA = ToonAge

local PB = {}
TA.ProfessionBatch = PB

local IDENTITY = { "guid", "flavor", "build", "interface", "project", "ruleset" }
local RECOGNITION = { [197] = true, [165] = true, [164] = true }

local function Unusable(v)
    local pred = _G.issecretvalue
    if type(pred) ~= "function" then return false end
    local ok, secret = pcall(pred, v)
    if not ok or secret == true then return true end
    return false
end

local function PlainNumber(v)
    if Unusable(v) or type(v) ~= "number" then return nil end
    if v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end

local function Whole(v)
    local n = PlainNumber(v)
    if not n or n < 0 or n ~= math.floor(n) then return nil end
    return n
end

local function PlainString(v)
    if Unusable(v) or type(v) ~= "string" then return nil end
    local ok, blank = pcall(function() return v == "" end)
    if not ok or blank then return nil end
    return v
end

function PB.IdentityComplete(identity)
    if type(identity) ~= "table" then return false end
    for _, key in ipairs(IDENTITY) do
        local v = identity[key]
        if Unusable(v) then return false end
        if v == nil or v == "" then return false end
        if type(v) ~= "string" and type(v) ~= "number" then return false end
    end
    return true
end

local function SameIdentity(a, b)
    for _, key in ipairs(IDENTITY) do
        local av, bv = a[key], b[key]
        if Unusable(av) or Unusable(bv) then return false end
        if tostring(av) ~= tostring(bv) then return false end
    end
    return true
end

local function OwnedCraft(cards, professionID)
    if Unusable(professionID) or type(professionID) ~= "number" then return nil end
    if professionID ~= professionID or not RECOGNITION[professionID] then return nil end
    for _, card in ipairs(cards or {}) do
        if type(card) == "table" and not Unusable(card.id) and type(card.id) == "number"
            and card.id == professionID then
            return card
        end
    end
    return nil
end

local function CleanRow(row, professionID, label)
    if type(row) ~= "table" then return nil end
    if Unusable(row.learned) or row.learned ~= true then return nil end
    if Unusable(row.id) or type(row.id) ~= "number" or row.id ~= row.id then return nil end
    local name = PlainString(row.name)
    if not name then return nil end
    return { id = row.id, name = name, professionID = professionID, profession = label }
end

function PB.Positives(observation, ownedCards)
    if type(observation) ~= "table" then return {} end
    if Unusable(observation.linked) or observation.linked ~= false then return {} end
    if Unusable(observation.ownerContext) or observation.ownerContext ~= "verified" then return {} end
    local card = OwnedCraft(ownedCards, observation.professionID)
    if not card then return {} end
    local label = PlainString(card.name) or ("skill " .. tostring(observation.professionID))
    local out = {}
    for _, row in ipairs(observation.rows or {}) do
        local clean = CleanRow(row, observation.professionID, label)
        if clean then out[#out + 1] = clean end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function PB.Remember(identity, professionID, pack, label)
    local guid = PlainString(identity.guid)
    if not guid or Unusable(professionID) or type(professionID) ~= "number" then return end
    local recipes = {}
    for _, rec in pairs(pack.recipes or {}) do
        local name = PlainString(rec.name)
        if name and not Unusable(rec.id) and type(rec.id) == "number" then
            recipes[#recipes + 1] = {
                id = rec.id, name = name, professionID = professionID,
                profession = label or rec.profession or ("skill " .. tostring(professionID)),
            }
        end
    end
    table.sort(recipes, function(a, b) return a.name < b.name end)
    PB.views = PB.views or {}
    PB.views[guid .. ":" .. tostring(professionID)] = {
        guid = guid, professionID = professionID, recipes = recipes, historical = true,
    }
end

function PB.CurrentView(identity)
    local guid = type(identity) == "table" and PlainString(identity.guid) or nil
    if not guid then return {} end
    local out = {}
    for _, view in pairs(PB.views or {}) do
        if not Unusable(view.guid) and view.guid == guid then
            for _, rec in ipairs(view.recipes or {}) do out[#out + 1] = rec end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function PB.ApplyLearned(store, identity, observation, ownedCards)
    if type(store) ~= "table" then return { saved = false, reason = "store" } end
    store.history = store.history or {}
    if type(observation) ~= "table" or observation.status ~= "read" then
        return { saved = false, reason = (type(observation) == "table" and observation.status) or "unavailable" }
    end
    if Unusable(observation.linked) or observation.linked == nil then
        return { saved = false, reason = "owner" }
    end
    if observation.linked == true then
        return { saved = false, reason = "linked" }
    end
    if observation.linked ~= false or Unusable(observation.ownerContext) or observation.ownerContext ~= "verified" then
        return { saved = false, reason = "owner" }
    end
    local prof = observation.professionID
    local card = OwnedCraft(ownedCards, prof)
    if not card then return { saved = false, reason = "profession" } end
    if not PB.IdentityComplete(identity) then
        return { saved = false, reason = "identity" }
    end
    if store.current and not SameIdentity(store.current.identity, identity) then
        store.history[#store.history + 1] = store.current
        store.current = nil
    end
    if not store.current then
        store.current = { identity = identity, professions = {} }
    end
    local pack = store.current.professions[prof]
    if not pack then
        pack = { recipes = {} }
        store.current.professions[prof] = pack
    end
    local label = PlainString(card.name) or ("skill " .. tostring(prof))
    local added = 0
    for _, row in ipairs(observation.rows or {}) do
        local clean = CleanRow(row, prof, label)
        if clean then
            local key = tostring(clean.id)
            if not pack.recipes[key] then added = added + 1 end
            pack.recipes[key] = { id = clean.id, name = clean.name, profession = label, professionID = prof }
        end
    end
    PB.Remember(identity, prof, pack, label)
    return { saved = true, added = added }
end

function PB.WorkingRecipes(store, identity, ownedCards)
    if type(store) ~= "table" or type(store.current) ~= "table" then return {} end
    if not PB.IdentityComplete(identity) or not SameIdentity(store.current.identity, identity) then
        return {}
    end
    local out = {}
    for key, pack in pairs(store.current.professions or {}) do
        local professionID = key
        if type(professionID) ~= "number" then professionID = tonumber(professionID) end
        if OwnedCraft(ownedCards, professionID) then
            for _, rec in pairs(pack.recipes or {}) do
                local name = PlainString(rec.name)
                if name and not Unusable(rec.id) and type(rec.id) == "number" then
                    out[#out + 1] = {
                        id = rec.id, name = name, professionID = professionID,
                        profession = rec.profession or ("skill " .. tostring(professionID)),
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function Finite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function Product(a, b)
    if not Finite(a) or not Finite(b) then return nil end
    local p = a * b
    if not Finite(p) then return nil end
    return p
end

local function Add(a, b)
    if not Finite(a) or not Finite(b) then return nil end
    local s = a + b
    if not Finite(s) then return nil end
    return s
end

local function Sub(a, b)
    if not Finite(a) or not Finite(b) then return nil end
    local d = a - b
    if not Finite(d) then return nil end
    return d
end

function PB.CompareBatch(input)
    if type(input) ~= "table" then return { ok = false, reason = "input" } end
    if type(input.malformed) == "string" and input.malformed ~= "" then
        return { ok = false, reason = input.malformed .. " is not a number" }
    end
    local n = Whole(input.n)
    if not n or n <= 0 then return { ok = false, reason = "batch" } end
    local cut = PlainNumber(input.cut)
    if not cut or cut < 0 or cut >= 1 then return { ok = false, reason = "cut" } end
    if type(input.outputs) ~= "table" or #input.outputs == 0 then
        return { ok = false, reason = "output" }
    end
    local craft = 0
    for _, output in ipairs(input.outputs) do
        if type(output) ~= "table" then return { ok = false, reason = "output" } end
        local count = Whole(output.count)
        local price = PlainNumber(output.price)
        if not count or count <= 0 or not price or price < 0 then
            return { ok = false, reason = "output" }
        end
        local piece = Product(count, n)
        piece = piece and Product(piece, price)
        piece = piece and Product(piece, 1 - cut)
        piece = piece and Add(craft, piece)
        if not piece then return { ok = false, reason = "overflow" } end
        craft = piece
    end
    if type(input.reagents) ~= "table" or #input.reagents == 0 then
        return { ok = false, reason = "reagent" }
    end
    local raw, buy = 0, 0
    for _, reagent in ipairs(input.reagents) do
        if type(reagent) ~= "table" then return { ok = false, reason = "reagent" } end
        local need = Whole(reagent.need)
        local owned = Whole(reagent.owned)
        local price = PlainNumber(reagent.price)
        if not need or not owned or not price or price < 0 then
            return { ok = false, reason = "reagent" }
        end
        local batchNeed = Product(need, n)
        if not batchNeed then return { ok = false, reason = "overflow" } end
        local used = math.min(owned, batchNeed)
        local short = batchNeed - used
        if not Finite(short) then return { ok = false, reason = "overflow" } end
        if Unusable(reagent.buyQty) or Unusable(reagent.buyPrice) then
            return { ok = false, reason = "reagent" }
        end
        local buyQty = Whole(reagent.buyQty)
        local buyPrice = PlainNumber(reagent.buyPrice)
        if short > 0 or reagent.buyQty ~= nil or reagent.buyPrice ~= nil then
            if not buyQty or not buyPrice or buyPrice < 0 or buyQty < short then
                return { ok = false, reason = "shortfall" }
            end
            local paid = Product(buyQty, buyPrice)
            paid = paid and Add(buy, paid)
            if not paid then return { ok = false, reason = "overflow" } end
            buy = paid
        end
        local rawPiece = Product(used, price)
        rawPiece = rawPiece and Product(rawPiece, 1 - cut)
        rawPiece = rawPiece and Add(raw, rawPiece)
        if not rawPiece then return { ok = false, reason = "overflow" } end
        raw = rawPiece
    end
    if Unusable(input.vendorBuy) or input.vendorBuy == nil then
        return { ok = false, reason = "vendor" }
    end
    local vendor = PlainNumber(input.vendorBuy)
    if not vendor or vendor < 0 then return { ok = false, reason = "vendor" } end
    local function knownLoss(v)
        if Unusable(v) then return nil, false end
        if v == nil then return 0, true end
        local nloss = PlainNumber(v)
        if not nloss or nloss < 0 then return nil, false end
        return nloss, false
    end
    local craftLoss, craftUnknown = knownLoss(input.lostCraftDeposit)
    local rawLoss, rawUnknown = knownLoss(input.lostRawDeposit)
    if craftLoss == nil or rawLoss == nil then return { ok = false, reason = "deposit" } end
    if Unusable(input.refundableDeposit) then
        return { ok = false, reason = "deposit" }
    end
    local tied = 0
    if input.refundableDeposit ~= nil then
        tied = PlainNumber(input.refundableDeposit)
        if not tied or tied < 0 then return { ok = false, reason = "deposit" } end
    end
    local net = Sub(craft, raw)
    net = net and Sub(net, buy)
    net = net and Sub(net, vendor)
    net = net and Sub(net, craftLoss)
    net = net and Add(net, rawLoss)
    if not net then return { ok = false, reason = "overflow" } end
    local rate
    if Unusable(input.activeSeconds) then return { ok = false, reason = "time" } end
    if input.activeSeconds ~= nil then
        local seconds = PlainNumber(input.activeSeconds)
        if not seconds or seconds <= 0 then return { ok = false, reason = "time" } end
        local scaled = Product(net, 3600)
        if not scaled then return { ok = false, reason = "overflow" } end
        rate = scaled / seconds
        if not Finite(rate) then return { ok = false, reason = "overflow" } end
    end
    return {
        ok = true, net = net, rate = rate, tiedUp = tied,
        incomplete = craftUnknown or rawUnknown, realized = false, currency = "gold",
        timeBasis = rate and "active crafting seconds" or nil,
    }
end

function PB.LiveIdentity()
    local C = TA.Compat
    local guid = C and type(C.PlayerGUID) == "function" and C.PlayerGUID() or nil
    local built = C and type(C.ClientBuild) == "function" and C.ClientBuild() or {}
    if type(built) ~= "table" then built = {} end
    local project = _G.WOW_PROJECT_ID
    if Unusable(project) or type(project) ~= "number" then project = nil end
    local flavor = TA.flavor
    if Unusable(flavor) then flavor = nil end
    return {
        guid = guid, flavor = flavor, build = built.build,
        interface = built.interface, project = project, ruleset = nil,
    }
end

function PB.Store()
    if type(TA.db) ~= "table" then return { history = {} } end
    TA.db.professionLearned = TA.db.professionLearned or { history = {} }
    return TA.db.professionLearned
end

function PB.InputFromForm()
    PB.form = PB.form or { outputs = 1, reagents = 1, text = {} }
    PB.form.text = PB.form.text or {}
    local function textOf(key)
        local box = PB.boxes and PB.boxes[key]
        if box and box.GetText and not box.hidden then
            local ok, text = pcall(box.GetText, box)
            if ok and not Unusable(text) and type(text) == "string" then
                PB.form.text[key] = text
                return text
            end
        end
        local saved = PB.form.text[key]
        if type(saved) == "string" then return saved end
        return ""
    end
    local malformed
    local function num(key)
        local text = textOf(key)
        if malformed then return nil end
        if text == "" then return nil end
        local n = tonumber(text)
        if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
            malformed = key
            return nil
        end
        return n
    end
    local reagents, outputs = {}, {}
    for i = 1, PB.form.reagents do
        reagents[i] = {
            need = num("reag" .. i .. "need"),
            owned = num("reag" .. i .. "owned"),
            price = num("reag" .. i .. "price"),
            buyQty = num("reag" .. i .. "buyQty"),
            buyPrice = num("reag" .. i .. "buyPrice"),
        }
    end
    for i = 1, PB.form.outputs do
        outputs[i] = { count = num("out" .. i .. "count"), price = num("out" .. i .. "price") }
    end
    return {
        n = num("n"), cut = num("cut"), vendorBuy = num("vendor"),
        lostCraftDeposit = num("lostCraft"), lostRawDeposit = num("lostRaw"),
        refundableDeposit = num("refund"), activeSeconds = num("seconds"),
        reagents = reagents, outputs = outputs,
        malformed = malformed,
    }
end

-- The live recipe read does not run. Nothing confirms that the open
-- profession window belongs to this character, so its recipe ids are not
-- this character's learned list. Refresh does not call the reader and does
-- not invent owner context. ApplyLearned still accepts a caller that already
-- has ownerContext "verified" and linked false. The manual calculator does
-- not use the read.
function PB:Refresh(ownedCards)
    self.lastApplied = { saved = false, reason = "owner" }
    self.lastNote = "Learned recipes are not enabled from the open window. Ownership of that window is not a verified field, so the recipe list was not read. The previous list was kept."
    return self.lastApplied
end

return PB
