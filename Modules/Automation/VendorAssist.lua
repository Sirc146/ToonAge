-- ToonAge/Modules/Automation/VendorAssist.lua
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── SELLING GREYS AND REPAIRING, WHEN YOU ASK FOR IT ──────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Two chores every levelling character does at every vendor. Both are opt-in
-- and both start OFF, because both spend or destroy something: repair spends
-- gold, and a sale cannot be undone once the buyback window closes.
--
-- Rules this module holds itself to:
--   * Poor quality ONLY (quality 0). Never greens "you probably don't want",
--     never soulbound blues, never anything with a quality the client did not
--     actually report. An unknown quality is a reason to skip, not to guess.
--   * Never sell something worth nothing -- hasNoValue items are usually quest
--     or profession junk the vendor will not buy anyway.
--   * A per-visit cap and a stagger between sales. Selling a full bag in one
--     frame trips Blizzard's action throttle and silently drops the tail of
--     the list, which looks exactly like the addon being broken.
--   * Repair only up to what you can afford, and only from your own purse
--     unless guild repair is explicitly switched on.
--
-- Container API differs by client: Midnight-era clients (Forever included)
-- moved it to C_Container, older ones keep the globals. Both are probed, and
-- every call goes through Try() because Forever's API set is only part mapped.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local VA = {}
TA:RegisterModule("VendorAssist", VA)

local POOR_QUALITY = 0

-- Bags 0..4 on every flavour. Reagent/extra bags are deliberately not swept:
-- nothing grey belongs in one, and scanning them only adds throttle pressure.
local FIRST_BAG, LAST_BAG = 0, 4

-- One merchant visit sells at most this many stacks, one every SELL_INTERVAL
-- seconds. Ten covers a full grind session's worth of grey; the stagger keeps
-- the client under its own rate limit.
local MAX_SELLS_PER_VISIT = 12
local SELL_INTERVAL       = 0.25

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g
end

local function Get(key)
    return TA.charDB and TA.charDB.tracker and TA.charDB.tracker[key] == true
end

-- ── Container API shim ────────────────────────────────────────────────────

local function NumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return Try(C_Container.GetContainerNumSlots, bag) or 0
    end
    return Try(GetContainerNumSlots, bag) or 0
end

--- Returns quality, link, hasNoValue for a slot, or nil when the client
--- would not say. The modern API returns a table; the legacy one a tuple.
local function SlotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = Try(C_Container.GetContainerItemInfo, bag, slot)
        if type(info) ~= "table" then return nil end
        return info.quality, info.hyperlink, info.hasNoValue
    end
    local _, _, _, quality, _, _, link, _, noValue = Try(GetContainerItemInfo, bag, slot)
    return quality, link, noValue
end

local function SellSlot(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        Try(C_Container.UseContainerItem, bag, slot)
    else
        Try(UseContainerItem, bag, slot)
    end
end

-- ── Selling ───────────────────────────────────────────────────────────────

--- Every grey slot currently in the bags, as { bag, slot, link } entries.
local function CollectJunk()
    local found = {}
    for bag = FIRST_BAG, LAST_BAG do
        for slot = 1, NumSlots(bag) do
            local quality, link, noValue = SlotInfo(bag, slot)
            -- An unreported quality is skipped on purpose: "I don't know" must
            -- never resolve to "sell it".
            if quality == POOR_QUALITY and not noValue then
                found[#found + 1] = { bag = bag, slot = slot, link = link }
            end
        end
    end
    return found
end

function VA:SellJunk()
    local junk = CollectJunk()
    if #junk == 0 then return end

    local count = math.min(#junk, MAX_SELLS_PER_VISIT)

    -- Sell back to front. Selling a slot can shuffle the ones after it, so
    -- walking backwards keeps the indices we already collected valid.
    for i = count, 1, -1 do
        local entry = junk[i]
        C_Timer.After((count - i) * SELL_INTERVAL, function()
            -- Re-check at fire time: the merchant window may have closed, or
            -- the player may have moved the item, in the quarter second since.
            if not (MerchantFrame and Try(MerchantFrame.IsShown, MerchantFrame)) then return end
            local quality, _, noValue = SlotInfo(entry.bag, entry.slot)
            if quality ~= POOR_QUALITY or noValue then return end
            SellSlot(entry.bag, entry.slot)
        end)
    end

    TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Selling %d grey %s.")
        :format(count, count == 1 and "item" or "items")
        .. (#junk > count
            and (" |cFF888780%d more left — vendor again to clear them.|r"):format(#junk - count)
            or ""))
end

-- ── Repairing ─────────────────────────────────────────────────────────────

function VA:Repair()
    if not Try(CanMerchantRepair) then return end

    local cost, canRepair = Try(GetRepairAllCost)
    if not canRepair or not cost or cost <= 0 then return end

    -- Guild funds first, when the player has opted in and the guild allows it.
    if Get("repairFromGuild") and CanGuildBankRepair and Try(CanGuildBankRepair) then
        local withdrawable = Try(GetGuildBankWithdrawMoney)
        -- -1 means unlimited (guild leader).
        if withdrawable and (withdrawable == -1 or withdrawable >= cost) then
            Try(RepairAllItems, true)
            TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Repaired for %s from guild funds.")
                :format(Try(GetMoneyString, cost) or tostring(cost)))
            return
        end
    end

    local money = Try(GetMoney) or 0
    if money < cost then
        TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Repair costs %s — you have %s. Skipped.")
            :format(Try(GetMoneyString, cost) or tostring(cost),
                    Try(GetMoneyString, money) or tostring(money)))
        return
    end

    Try(RepairAllItems, false)
    TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Repaired for %s.")
        :format(Try(GetMoneyString, cost) or tostring(cost)))
end

-- ── Events ────────────────────────────────────────────────────────────────

function VA:OnEvent(event)
    if event ~= "MERCHANT_SHOW" then return end
    -- Shift is the same escape hatch questing uses: hold it to open a vendor
    -- without ToonAge touching anything.
    if Try(IsShiftKeyDown) then return end

    if Get("autoRepair")    then self:Repair()   end
    if Get("autoSellJunk")  then self:SellJunk() end
end

-- ── Init ──────────────────────────────────────────────────────────────────

function VA:Init()
    TA:RegisterEvent("MERCHANT_SHOW")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r VendorAssist module loaded.")
    end
end
