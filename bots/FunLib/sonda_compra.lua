-- dota-bot benchmark: what the engine answers when a bot buys a secret shop item (evaluation of 2026-11-06, step 1 of its route). Variant
-- "sonda_compra = true" only: it replaces OHA's purchases, so the bot saves its gold, and each bot tries once when it can pay, then every
-- 30 s, far from the secret shop or not. One line per try with the code: -1 bought, 62 not at the secret shop.
-- Also a plain item, to tell a shop rule from a broken call. Never for a measure: the bots stop buying.
local M = {}

local ITEMS = { 'item_point_booster', 'item_hyperstone', 'item_ogre_axe' }
local CONTROL = 'item_ogre_axe'
local AGAIN = 30

local tried = {}

function M.Tick(bot)
	local pid = bot:GetPlayerID()
	local t = DotaTime()
	tried[pid] = tried[pid] or {}
	for _, item in ipairs(ITEMS) do
		local cost = GetItemCost(item)
		-- The plain item waits for the secret one: it is cheaper, and if it is bought, it spends the gold that one needs.
		local ready = item ~= CONTROL or tried[pid][ITEMS[1]] ~= nil
		if ready and bot:GetGold() >= cost and t - (tried[pid][item] or -1000) >= AGAIN then
			tried[pid][item] = t
			local gold = bot:GetGold()
			local secret, stock = IsItemPurchasedFromSecretShop(item), GetItemStockCount(item)
			local code = bot:ActionImmediate_PurchaseItem(item)
			print(string.format('[bench] compra_sonda t=%.1f pid=%d item=%s secreta=%s stock=%s coste=%d oro=%d d_secreta=%d d_casa=%d codigo=%s',
				t, pid, item, tostring(secret), tostring(stock), cost, gold, bot:DistanceFromSecretShop(), bot:DistanceFromFountain(), tostring(code)))
			return
		end
	end
end

return M
