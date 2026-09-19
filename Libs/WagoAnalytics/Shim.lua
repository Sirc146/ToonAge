-- WagoAnalytics Shim — vendored from https://github.com/wagoio/WagoAnalyticsShim
--
-- Wago publish this file for addons to bundle. It is THEIR code, kept here
-- verbatim except for this header, so that every ToonAge build (hand-built zip,
-- GitHub release, Wago upload) ships an identical package. Upstream carries no
-- license header.
--
-- What it does: if the player has the Wago App installed, its WagoAnalytics
-- addon is present and Register returns a real recorder. If not, Register
-- returns a table of empty functions, so calling code never has to nil-check.
-- Nothing here sends anything by itself.

local WagoAnalyticsShim = LibStub:NewLibrary("WagoAnalytics", 2)

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

if not WagoAnalyticsShim then
	return
end

function WagoAnalyticsShim:Register(wagoID)
	local WagoAnalytics = WagoAnalytics
	if WagoAnalytics then
		return WagoAnalytics:Register(wagoID)
	else
		return setmetatable({}, {
			__index = {
				IncrementCounter = function() end,
				DecrementCounter = function() end,
				SetCounter = function() end,
				Switch = function() end,
				Error = function() end,
				Breadcrumb = function() end
			}
		})
	end
end

function WagoAnalyticsShim:RegisterAddon(addonName)
	local wagoID = GetAddOnMetadata(addonName, "X-Wago-ID")
	if not wagoID then
		return false
	end
	return self:Register(wagoID)
end

WagoAnalyticsShim.RegisterAddOn = WagoAnalyticsShim.RegisterAddon
