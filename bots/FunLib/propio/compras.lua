-- dota-bot's own bot: purchases and courier (phase 1, trabajo/bot-propio.md). The build is Valve's own core loadout
-- for the hero (scripts/npc/bot_loadouts.txt, 7.41f; docs/api/README.md), expanded to the parts the shop sells with
-- the engine's own recipes (GetItemComponents), bought in order as the gold allows, and brought by the courier.
local P = {}

local LOADOUTS = {
	npc_dota_hero_sniper = { 'item_power_treads', 'item_mjollnir', 'item_hurricane_pike', 'item_black_king_bar',
		'item_greater_crit', 'item_satanic' },
}

-- The basic parts of an item, in buying order (recipes last within each item), from the engine's first recipe.
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

-- The queue of parts for a bot, built once.
function P.Queue(bot, s)
	if s.buyQueue ~= nil then return s.buyQueue end
	s.buyQueue = {}
	for _, item in ipairs(LOADOUTS[bot:GetUnitName()] or {}) do
		for _, part in ipairs(Parts(item, {})) do table.insert(s.buyQueue, { part = part, of = item }) end
	end
	s.buyIndex = 1
	return s.buyQueue
end

local function MainSlotsUsed(bot)
	local n = 0
	for slot = 0, 5 do if bot:GetItemInSlot(slot) ~= nil then n = n + 1 end end
	return n
end

-- Makes room: with the six main slots full, sells a branch (the cheapest filler); returns a log line or nil.
local function MakeRoom(bot)
	if MainSlotsUsed(bot) < 6 then return nil end
	local slot = bot:FindItemSlot('item_branches')
	if slot < 0 then return nil end
	bot:ActionImmediate_SellItem(bot:GetItemInSlot(slot))
	return 'vendo item_branches para hacer sitio'
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
		s.buyIndex = s.buyIndex + 1
		return string.format('%s (para %s) coste=%d oro=%d%s', next.part, next.of, cost, bot:GetGold(),
			room and (' · ' .. room) or '')
	end
	-- Not bought (out of stock...): logged once per part, retried at most once a second.
	if s.buyFailed ~= next.part then
		s.buyFailed = next.part
		return string.format('%s (para %s) no comprado, codigo=%s', next.part, next.of, tostring(code))
	end
	return nil
end

-- A finished item left in the backpack (slots 6-8) gives nothing: swap it with an empty or consumable main slot.
function P.Arrange(bot, s, now)
	if now - (s.arrangeAt or -1000) < 3 then return nil end
	for back = 6, 8 do
		local item = bot:GetItemInSlot(back)
		if item ~= nil and item:GetName() ~= 'item_branches' and item:GetName() ~= 'item_tango'
			and not string.find(item:GetName(), '^item_recipe_') then
			for main = 0, 5 do
				local m = bot:GetItemInSlot(main)
				if m == nil or m:GetName() == 'item_branches' or m:GetName() == 'item_tango' then
					s.arrangeAt = now
					bot:ActionImmediate_SwapItems(back, main)
					return string.format('paso %s de la mochila a la ranura %d', item:GetName(), main)
				end
			end
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
