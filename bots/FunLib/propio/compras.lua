-- dota-bot's own bot: purchases and courier (phase 1, trabajo/bot-propio.md). The build departs from Valve's (DECISIONES
-- 2026-11-04): stats from the start, Treads for agility, Dragon Lance soon, as ideas read in OHA. Each item is expanded
-- to the parts the shop sells with the engine's own recipes (GetItemComponents), bought in order as the gold allows,
-- and brought by the courier.
local P = {}

local LOADOUTS = {
	npc_dota_hero_sniper = { 'item_wraith_band', 'item_power_treads', 'item_dragon_lance', 'item_maelstrom',
		'item_black_king_bar', 'item_greater_crit', 'item_satanic' },
}

-- Items whose engine's first recipe is not the one wanted: Treads for agility, not strength.
local FIXED_PARTS = { item_power_treads = { 'item_boots', 'item_gloves', 'item_boots_of_elves' } }
-- Parts already bought as starting items (linea.lua): not bought again.
local HAVE_AT_START = { item_slippers = true, item_circlet = true }

-- The basic parts of an item, from the engine's first recipe.
local function Parts(item, out, depth)
	depth = depth or 0
	local recipes = GetItemComponents(item)
	local first = recipes ~= nil and recipes[1] or nil
	if depth > 6 or first == nil or #first == 0 then
		table.insert(out, item)
		return out
	end
	for _, part in ipairs(first) do Parts(part, out, depth + 1) end
	return out
end

-- Cheapest first and recipes last: gold turns into stats as soon as it can, instead of waiting whole for the dearest
-- part (1.596 idle at t=360, waiting for the hammer).
local function BuyingOrder(parts)
	local function rank(part) return string.find(part, '^item_recipe_') and 1e6 or GetItemCost(part) end
	table.sort(parts, function(a, b) return rank(a) < rank(b) end)
	return parts
end

-- The queue of parts for a bot, built once.
function P.Queue(bot, s)
	if s.buyQueue ~= nil then return s.buyQueue end
	s.buyQueue = {}
	for _, item in ipairs(LOADOUTS[bot:GetUnitName()] or {}) do
		local parts = FIXED_PARTS[item] or BuyingOrder(Parts(item, {}))
		for _, part in ipairs(parts) do
			if item ~= 'item_wraith_band' or not HAVE_AT_START[part] then table.insert(s.buyQueue, { part = part, of = item }) end
		end
	end
	s.buyIndex = 1
	return s.buyQueue
end

local function HasAnywhere(bot, name)
	local slot = bot:FindItemSlot(name)
	return slot >= 0 and slot <= 15
end

-- With the inventory nearly full, a branch goes, only near the shop: far from it the sale failed without a word while
-- the log said it sold (4 sales with 2 branches). Without this, a late item could never be assembled.
local function MakeRoom(bot)
	local used = 0
	for slot = 0, 8 do if bot:GetItemInSlot(slot) ~= nil then used = used + 1 end end
	if used < 8 or bot:DistanceFromFountain() > 800 then return nil end
	local slot = bot:FindItemSlot('item_branches')
	if slot < 0 or slot > 8 then return nil end
	bot:ActionImmediate_SellItem(bot:GetItemInSlot(slot))
	return 'vendo item_branches para hacer sitio, junto a la tienda'
end

-- One salve and one teleport scroll at hand: nothing refilled them (out of salves at minute 1, 70 s walking to the
-- fountain; no TP at all). The wait covers the courier's trip, when the bought one is in no slot of the hero's.
function P.Consumables(bot, s, now)
	if now - (s.consumablesAt or -1000) < 2 then return nil end
	s.consumablesAt = now
	-- The TP waits for t=180: the first gold goes to the Wraith Band, and nothing sends the hero home before that.
	for _, c in ipairs({ { name = 'item_flask', wait = 45, from = -1000 }, { name = 'item_tpscroll', wait = 45, from = 180 } }) do
		s.refillAt = s.refillAt or {}
		if DotaTime() >= c.from and not HasAnywhere(bot, c.name) and now - (s.refillAt[c.name] or -1000) >= c.wait
			and not (c.name == 'item_flask' and bot:HasModifier('modifier_flask_healing'))
			and bot:GetGold() >= GetItemCost(c.name) and bot:GetItemInSlot(14) == nil then
			s.refillAt[c.name] = now
			local code = bot:ActionImmediate_PurchaseItem(c.name)
			return string.format('repongo %s codigo=%s oro=%d', c.name, tostring(code), bot:GetGold())
		end
	end
	return nil
end

-- The Treads when they must change to agility and no enemy is near. The API reads intellect for real agility and the
-- other way round (read in OHA, ability_item_usage_generic; the log line of each change checks it).
function P.TreadsToAgility(bot, s, now)
	if now - (s.treadsAt or -1000) < 1 then return nil end
	local slot = bot:FindItemSlot('item_power_treads')
	if slot < 0 or slot > 5 then return nil end
	local item = bot:GetItemInSlot(slot)
	if item == nil or item:GetPowerTreadsStat() == ATTRIBUTE_INTELLECT then return nil end
	-- At most 6 changes a match: if the reading never moved, it would click once a second for ever.
	if (s.treadsClicks or 0) >= 6 then return nil end
	s.treadsAt, s.treadsClicks = now, (s.treadsClicks or 0) + 1
	return item
end

-- Buys the next part when the gold allows; returns a log line when something happened, else nil. A part the shop
-- near the hero cannot sell (secret shop: Hyperstone, Demon Edge, Reaver...) is skipped for now and logged: buying it
-- with the courier at the secret shop is not part of phase 1 (it comes after minute 10 for this build).
function P.Buy(bot, s, now)
	local queue = P.Queue(bot, s)
	local next = queue[s.buyIndex]
	if next == nil then return nil end
	if IsItemPurchasedFromSecretShop(next.part) then
		-- The rest of that item is skipped too: its recipe without the secret part is wasted gold and a slot (seen in
		-- the 2026-11-03 phase 1 smoke: Mjollnir's recipe bought without the Hyperstone).
		local skipped = next.of
		while queue[s.buyIndex] ~= nil and queue[s.buyIndex].of == skipped do s.buyIndex = s.buyIndex + 1 end
		return string.format('%s (para %s) es de la tienda secreta: salto lo que queda de %s', next.part, skipped, skipped)
	end
	local cost = GetItemCost(next.part)
	bot:SetNextItemPurchaseValue(cost)
	if bot:GetGold() < cost or now - (s.buyTriedAt or -1000) < 1 then return nil end
	if bot:GetItemInSlot(14) ~= nil then return nil end -- stash full: wait for the courier
	s.buyTriedAt = now
	local room = MakeRoom(bot)
	local code = bot:ActionImmediate_PurchaseItem(next.part)
	if code == PURCHASE_ITEM_SUCCESS then
		s.buyIndex, s.buyFails = s.buyIndex + 1, 0
		return string.format('%s (para %s) coste=%d oro=%d%s', next.part, next.of, cost, bot:GetGold(),
			room and (' · ' .. room) or '')
	end
	-- Not bought (out of stock...): retried once a second, skipped after 30 so one part cannot stop the whole build.
	s.buyFails = (s.buyFails or 0) + 1
	if s.buyFails >= 30 then
		s.buyIndex, s.buyFails = s.buyIndex + 1, 0
		return string.format('%s (para %s) saltado tras 30 intentos, codigo=%s', next.part, next.of, tostring(code))
	end
	if s.buyFails == 1 then
		return string.format('%s (para %s) no comprado, codigo=%s', next.part, next.of, tostring(code))
	end
	return nil
end

-- An item left in the backpack (slots 6-8) gives nothing: swap it with an empty main slot, else with a branch. Never
-- with a tango, which from the backpack could not be used; a tango that fell there comes back like any other item.
function P.Arrange(bot, s, now)
	if now - (s.arrangeAt or -1000) < 3 then return nil end
	local function mainSlot()
		for main = 0, 5 do if bot:GetItemInSlot(main) == nil then return main end end
		for main = 0, 5 do if bot:GetItemInSlot(main):GetName() == 'item_branches' then return main end end
		return nil
	end
	for back = 6, 8 do
		local item = bot:GetItemInSlot(back)
		if item ~= nil and item:GetName() ~= 'item_branches' and not string.find(item:GetName(), '^item_recipe_') then
			local main = mainSlot()
			if main == nil then return nil end
			s.arrangeAt = now
			bot:ActionImmediate_SwapItems(back, main)
			return string.format('paso %s de la mochila a la ranura %d', item:GetName(), main)
		end
	end
	return nil
end

local function MyCourier(bot)
	local ok, c = pcall(GetCourierForPlayer, bot:GetPlayerID())
	if ok and c ~= nil then return c end
	for i = 0, 4 do
		local k = GetCourier(i)
		if k ~= nil and k:GetPlayerID() == bot:GetPlayerID() then return k end
	end
	return nil
end

local function StashCount(bot)
	local n = 0
	-- The stash is slots 9-14 (15 is the teleport scroll, 16 the neutral item): counting 15 sent the courier out empty.
	for slot = 9, 14 do if bot:GetItemInSlot(slot) ~= nil then n = n + 1 end end
	return n
end

-- Sends the courier with whatever is in the stash, when it is home and free; returns a log line or nil.
function P.Courier(bot, s, now)
	if StashCount(bot) == 0 or now - (s.courierAt or -1000) < 5 then return nil end
	local c = MyCourier(bot)
	if c == nil then return nil end
	local state = GetCourierState(c)
	if state ~= COURIER_STATE_AT_BASE and state ~= COURIER_STATE_IDLE then return nil end
	local n = StashCount(bot)
	bot:ActionImmediate_Courier(c, COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS)
	s.courierAt = now
	return string.format('mensajero lleva %d objetos (estado=%d)', n, state)
end

return P
