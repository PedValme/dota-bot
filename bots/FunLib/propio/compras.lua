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

-- Buys the next part when the gold allows; returns a log line when something happened, else nil.
function P.Buy(bot, s)
	local queue = P.Queue(bot, s)
	local next = queue[s.buyIndex]
	if next == nil then return nil end
	local cost = GetItemCost(next.part)
	bot:SetNextItemPurchaseValue(cost)
	if bot:GetGold() < cost then return nil end
	local code = bot:ActionImmediate_PurchaseItem(next.part)
	if code == PURCHASE_ITEM_SUCCESS then
		s.buyIndex = s.buyIndex + 1
		return string.format('%s (para %s) coste=%d oro=%d', next.part, next.of, cost, bot:GetGold())
	end
	-- Not sold here (a secret shop part, out of stock...): logged once per part, retried later.
	if s.buyFailed ~= next.part then
		s.buyFailed = next.part
		return string.format('%s (para %s) no comprado, codigo=%s', next.part, next.of, tostring(code))
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
	for slot = 9, 15 do if bot:GetItemInSlot(slot) ~= nil then n = n + 1 end end
	return n
end

-- Sends the courier with whatever is in the stash, when it is home and free; returns a log line or nil.
function P.Courier(bot, s, now)
	if StashCount(bot) == 0 or now - (s.courierAt or -1000) < 5 then return nil end
	local c = MyCourier(bot)
	if c == nil then return nil end
	local state = GetCourierState(c)
	if state ~= COURIER_STATE_AT_BASE and state ~= COURIER_STATE_IDLE then return nil end
	bot:ActionImmediate_Courier(c, COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS)
	s.courierAt = now
	return string.format('mensajero lleva %d objetos (estado=%d)', StashCount(bot), state)
end

return P
