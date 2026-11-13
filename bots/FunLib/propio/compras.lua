-- dota-bot's own bot: purchases and courier (phase 1, trabajo/bot-propio.md). The build departs from Valve's (DECISIONES
-- 2026-11-04): stats from the start, Treads for agility, Dragon Lance soon, as ideas read in OHA. Each item is expanded
-- to the parts the shop sells with the engine's own recipes (GetItemComponents), bought in order as the gold allows,
-- and brought by the courier.
local P = {}

local Build = require(GetScriptDirectory()..'/FunLib/propio/build')

local Heroes = require(GetScriptDirectory()..'/FunLib/propio/heroes')

-- The basic parts of an item, from the engine's first recipe, leaving out what is already in the build (have).
local function Parts(item, out, have, depth)
	depth = depth or 0
	if depth > 0 and have[item] then return out end
	local recipes = GetItemComponents(item)
	local first = recipes ~= nil and recipes[1] or nil
	if depth > 6 or first == nil or #first == 0 then
		table.insert(out, item)
		return out
	end
	for _, part in ipairs(first) do Parts(part, out, have, depth + 1) end
	return out
end

-- Cheapest first and recipes last: gold turns into stats as soon as it can, instead of waiting whole for the dearest
-- part (1.596 idle at t=360, waiting for the hammer).
local function BuyingOrder(parts)
	local function rank(part) return string.find(part, '^item_recipe_') and 1e6 or GetItemCost(part) end
	table.sort(parts, function(a, b) return rank(a) < rank(b) end)
	return parts
end

-- The parts of these items, in order, at the end of the queue. `have` holds the items already in it: a Pike only buys what the Lance
-- lacks.
-- The Treads by the hero's stat (heroes.lua), not the engine's first recipe; the first item does not buy again what the starting items
-- already hold (the Sniper's slippers and circlet are its Wraith Band).
local function Append(s, items, have, datos)
	local treads = Heroes.BOTAS[datos.botas or 'agilidad']
	local atStart = {}
	for _, it in ipairs(datos.salida or {}) do atStart[it] = true end
	for _, item in ipairs(items) do
		local parts = (item == 'item_power_treads' and treads.partes) or BuyingOrder(Parts(item, {}, have))
		for _, part in ipairs(parts) do
			if item ~= datos.primero or not atStart[part] then table.insert(s.buyQueue, { part = part, of = item }) end
		end
		have[item] = true
	end
end

-- The queue of parts for a bot: from its build plan against the enemies (build.lua) when it has a profile, else its fixed list.
function P.Queue(bot, s)
	if s.buyQueue ~= nil then return s.buyQueue end
	s.buyQueue = {}
	local datos = Heroes.Datos(bot:GetUnitName())
	Append(s, Build.Plan(bot, s) or datos.compras or {}, {}, datos)
	s.buyIndex = 1
	return s.buyQueue
end

-- At the boundary between two whole items, if what the enemies threaten changed (an item seen on one), the rest of the plan is chosen
-- again; what is bought stays. Returns a log line or nil.
local function Replan(bot, s)
	local queue = s.buyQueue
	local next = queue[s.buyIndex]
	if next == nil or Build.Profile(bot) == nil then return nil end
	if s.buyIndex > 1 and queue[s.buyIndex - 1].of == next.of then return nil end
	if s.buildSignature == Build.Signature(Build.Threats(bot)) then return nil end
	local done, kept = {}, {}
	for i = 1, s.buyIndex - 1 do
		done[queue[i].of] = true
		table.insert(kept, queue[i])
	end
	s.buyQueue = kept
	-- A courier sent for a secret part of the old plan would make the next one look late and skip it.
	s.secretSince = nil
	Append(s, Build.Plan(bot, s, done) or {}, done, Heroes.Datos(bot:GetUnitName()))
	return 'plan de nuevo: cambió lo que amenazan'
end

local function HasAnywhere(bot, name)
	local slot = bot:FindItemSlot(name)
	return slot >= 0 and slot <= 15
end

-- With the inventory nearly full, the least useful item goes, only near the shop: far from it the sale failed without a
-- word while the log said it sold (4 sales with 2 branches). Without this, a late item could never be assembled.
-- The Mask last: once the six slots are full of the late items, it is what gives way (else the answer to evasion stayed in the backpack).
local SELL_ORDER = { 'item_branches', 'item_tango', 'item_clarity', 'item_flask', 'item_wraith_band', 'item_mask_of_madness' }
local function MakeRoom(bot)
	local used = 0
	for slot = 0, 8 do if bot:GetItemInSlot(slot) ~= nil then used = used + 1 end end
	if used < 8 or bot:DistanceFromFountain() > 800 then return nil end
	for _, name in ipairs(SELL_ORDER) do
		local slot = bot:FindItemSlot(name)
		if slot >= 0 and slot <= 8 then
			bot:ActionImmediate_SellItem(bot:GetItemInSlot(slot))
			return string.format('vendo %s para hacer sitio, junto a la tienda', name)
		end
	end
	return nil
end

-- Far from the shop, with the inventory nearly full, a branch on the ground: else the last parts stay on the courier and
-- their item never comes together. Once every 5 s; the caller gives the order.
function P.FillerToDrop(bot, s, now)
	if now - (s.dropAt or -1000) < 5 then return nil end
	local used = 0
	for slot = 0, 8 do if bot:GetItemInSlot(slot) ~= nil then used = used + 1 end end
	-- In the lane only with the nine full: there a branch still gives stats.
	if used < (s.late and 8 or 9) then return nil end
	local slot = bot:FindItemSlot('item_branches')
	if slot < 0 or slot > 8 then return nil end
	s.dropAt = now
	return bot:GetItemInSlot(slot)
end

-- One salve and one teleport scroll at hand: nothing refilled them (out of salves at minute 1, 70 s walking to the
-- fountain; no TP at all). The wait covers the courier's trip, when the bought one is in no slot of the hero's.
function P.Consumables(bot, s, now)
	if now - (s.consumablesAt or -1000) < 2 then return nil end
	s.consumablesAt = now
	-- The TP waits for t=180: the first gold goes to the Wraith Band, and nothing sends the hero home before that. Salves stop
	-- with the lane: their slot is for items, and 130 gold no longer heals what a fight takes. Which ones by role (heroes.lua,
	-- R.ROL): a support also keeps a clarity, under the salve's rules; one that is working is not bought again.
	local list = {}
	for _, name in ipairs((Heroes.Rol(bot)).consumibles or { 'item_flask' }) do
		table.insert(list, { name = name, wait = 45, from = -1000, upTo = 15 })
	end
	table.insert(list, { name = 'item_tpscroll', wait = 45, from = 180, upTo = 99 })
	local working = { item_flask = 'modifier_flask_healing', item_clarity = 'modifier_clarity_potion' }
	for _, c in ipairs(list) do
		s.refillAt = s.refillAt or {}
		if DotaTime() >= c.from and bot:GetLevel() < c.upTo and not HasAnywhere(bot, c.name) and now - (s.refillAt[c.name] or -1000) >= c.wait
			and not (working[c.name] ~= nil and bot:HasModifier(working[c.name]))
			and bot:GetGold() >= GetItemCost(c.name) and bot:GetItemInSlot(14) == nil then
			s.refillAt[c.name] = now
			local code = bot:ActionImmediate_PurchaseItem(c.name)
			return string.format('repongo %s codigo=%s oro=%d', c.name, tostring(code), bot:GetGold())
		end
	end
	return nil
end

-- The Treads when they must change to the hero's stat (heroes.lua: the API reads intellect for real agility and the other way round).
function P.TreadsToAgility(bot, s, now)
	if now - (s.treadsAt or -1000) < 1 then return nil end
	local slot = bot:FindItemSlot('item_power_treads')
	if slot < 0 or slot > 5 then return nil end
	local item = bot:GetItemInSlot(slot)
	if item == nil or item:GetPowerTreadsStat() == Heroes.BOTAS[Heroes.Datos(bot:GetUnitName()).botas or 'agilidad'].api then return nil end
	-- At most 6 changes a match: if the reading never moved, it would click once a second for ever.
	if (s.treadsClicks or 0) >= 6 then return nil end
	s.treadsAt, s.treadsClicks = now, (s.treadsClicks or 0) + 1
	return item
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

-- A secret shop part, with the gold in hand: the courier goes, buys it there and brings it. If it cannot in a minute from the
-- order, that whole item is skipped (its recipe without the part is gold and a slot wasted), so the build never stops for good
-- (without this the build ended at minute 20: 17.087 gold unspent, 2026-11-05). Only with the hero alive: the courier would
-- bring it to nobody.
local function BuySecret(bot, s, now, next, cost)
	local c = MyCourier(bot)
	if c == nil or not bot:IsAlive() then return nil end
	local state = GetCourierState(c)
	if state == COURIER_STATE_DEAD then s.secretSince = nil return nil end
	if s.secretSince ~= nil and now - s.secretSince > 60 then
		local skipped = next.of
		local queue = s.buyQueue
		while queue[s.buyIndex] ~= nil and queue[s.buyIndex].of == skipped do s.buyIndex = s.buyIndex + 1 end
		s.secretSince = nil
		return string.format('salto %s: el mensajero no compró %s en la tienda secreta en 60 s', skipped, next.part)
	end
	if c:DistanceFromSecretShop() == 0 then
		local code = c:ActionImmediate_PurchaseItem(next.part)
		if code == PURCHASE_ITEM_SUCCESS then
			s.buyIndex, s.secretSince = s.buyIndex + 1, nil
			bot:ActionImmediate_Courier(c, COURIER_ACTION_TRANSFER_ITEMS)
			s.courierAt = now
			return string.format('%s (para %s) comprado por el mensajero, coste=%d oro=%d', next.part, next.of, cost, bot:GetGold())
		end
		return nil
	end
	if (state == COURIER_STATE_AT_BASE or state == COURIER_STATE_IDLE) and now - (s.secretOrderAt or -1000) >= 5 then
		s.secretOrderAt, s.secretSince = now, s.secretSince or now
		bot:ActionImmediate_Courier(c, COURIER_ACTION_SECRET_SHOP)
		return string.format('mensajero a la tienda secreta a por %s', next.part)
	end
	return nil
end

-- Buys the next part when the gold allows; returns a log line when something happened, else nil.
function P.Buy(bot, s, now)
	P.Queue(bot, s)
	-- Every 2 s, the items on the enemies in sight; at a boundary between items, the plan again if that changed what they threaten.
	if now - (s.lookAt or -1000) >= 2 then
		s.lookAt = now
		local seen = Build.Look(bot)
		if seen ~= nil then return seen end
		local again = Replan(bot, s)
		if again ~= nil then return again end
	end
	local queue = s.buyQueue
	local next = queue[s.buyIndex]
	if next == nil then return nil end
	-- The next item waits until the Treads are assembled. A Belt of Strength (Dragon Lance) arriving with their parts makes them
	-- strength Treads, leaves the Boots of Elves over and the Lance without its part: it never came together, the inventory
	-- filled and the courier went back and forth for minutes (presion-propio 3, t=210-575). A minute at most.
	if not s.treadsDone and next.of ~= 'item_power_treads' and next.of ~= 'item_wraith_band' then
		local slot = bot:FindItemSlot('item_power_treads')
		s.treadsWait = s.treadsWait or now
		if slot >= 0 or now - s.treadsWait > 60 then s.treadsDone = true else return nil end
	end
	local cost = GetItemCost(next.part)
	bot:SetNextItemPurchaseValue(cost)
	if IsItemPurchasedFromSecretShop(next.part) then
		if bot:GetGold() < cost then s.secretSince = nil return nil end
		-- Directly first, as any other part: the bench's Turbo sells them at any shop, and the line says whether real Turbo does too.
		-- One refusal is enough: from then on, the courier.
		if s.secretDirect ~= false then
			if bot:GetItemInSlot(14) ~= nil then return nil end
			local room = MakeRoom(bot)
			local code = bot:ActionImmediate_PurchaseItem(next.part)
			if code == PURCHASE_ITEM_SUCCESS then
				s.secretDirect, s.buyIndex, s.secretSince = true, s.buyIndex + 1, nil
				return string.format('%s (para %s) secreta, compra directa, codigo=%s coste=%d oro=%d%s', next.part, next.of, tostring(code), cost, bot:GetGold(),
					room and (' · ' .. room) or '')
			end
			s.secretDirect = false
			return string.format('%s (para %s) secreta, sin compra directa, codigo=%s: uso el mensajero', next.part, next.of, tostring(code))
		end
		return BuySecret(bot, s, now, next, cost)
	end
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

-- An item left in the backpack (slots 6-8) gives nothing: swap it with an empty main slot, else with a branch. In the lane
-- never with a tango, which from the backpack could not be used; a tango that fell there comes back like any other item.
-- Once the lane is over, consumables and the Wraith Band give way too: a Blade in the backpack is a fight lost.
local LATE_FILLER = { item_tango = true, item_flask = true, item_clarity = true, item_wraith_band = true, item_mask_of_madness = true }
function P.Arrange(bot, s, now)
	if now - (s.arrangeAt or -1000) < 3 then return nil end
	local function filler(name) return name == 'item_branches' or (s.late and LATE_FILLER[name]) end
	local function mainSlot()
		for main = 0, 5 do if bot:GetItemInSlot(main) == nil then return main end end
		for main = 0, 5 do if bot:GetItemInSlot(main):GetName() == 'item_branches' then return main end end
		for main = 0, 5 do if filler(bot:GetItemInSlot(main):GetName()) then return main end end
		return nil
	end
	for back = 6, 8 do
		local item = bot:GetItemInSlot(back)
		if item ~= nil and not filler(item:GetName()) and not string.find(item:GetName(), '^item_recipe_') then
			local main = mainSlot()
			if main == nil then return nil end
			s.arrangeAt = now
			bot:ActionImmediate_SwapItems(back, main)
			return string.format('paso %s de la mochila a la ranura %d', item:GetName(), main)
		end
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
	if now - (s.courierAt or -1000) < 5 then return nil end
	local c = MyCourier(bot)
	if c == nil then return nil end
	local state = GetCourierState(c)
	if state ~= COURIER_STATE_AT_BASE and state ~= COURIER_STATE_IDLE and state ~= COURIER_STATE_AT_SECRET_SHOP then return nil end
	-- Paid parts left on the courier, or a courier parked at the secret shop waiting for gold, are sent on: with the
	-- inventory full they stayed there for good (lobby-202611052104, t=1211 to 1778). Not while it waits to buy there.
	local secretNext = s.buyQueue ~= nil and s.buyQueue[s.buyIndex] ~= nil and IsItemPurchasedFromSecretShop(s.buyQueue[s.buyIndex].part)
	if secretNext and s.secretDirect == false and bot:GetGold() >= GetItemCost(s.buyQueue[s.buyIndex].part) then return nil end
	if bot:IsAlive() and bot:GetCourierValue() > 0 and StashCount(bot) == 0 then
		bot:ActionImmediate_Courier(c, COURIER_ACTION_TRANSFER_ITEMS)
		s.courierAt = now
		return string.format('mensajero entrega lo que lleva (estado=%d)', state)
	end
	if StashCount(bot) == 0 then return nil end
	local n = StashCount(bot)
	bot:ActionImmediate_Courier(c, COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS)
	s.courierAt = now
	return string.format('mensajero lleva %d objetos (estado=%d)', n, state)
end

-- Gold has no other use once the build is far along: dead for long with plenty of it, back at once.
function P.Buyback(bot, s, now)
	if bot:IsAlive() or not bot:HasBuyback() or now - (s.buybackAt or -1000) < 5 then return nil end
	if not s.late or bot:GetRespawnTime() < 25 then return nil end
	local cost = bot:GetBuybackCost()
	if bot:GetGold() < cost + 2000 then return nil end
	s.buybackAt = now
	bot:ActionImmediate_Buyback()
	return string.format('recompro, coste=%d oro=%d', cost, bot:GetGold())
end

return P
