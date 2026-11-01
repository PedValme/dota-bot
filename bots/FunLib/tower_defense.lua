-- Tower defense with judgement (benchmark variant defensa_t12; off by default). Pedro, 2026-10-31: towers fall
-- undefended because each hero goes its own way, «con cabeza». Measured in the observer logs: of ~65 towers dota-bot
-- lost, most fell with no ally within 1500; 8 outer towers fell to only two attackers with nobody coming (defendable),
-- while 23 fell to three or more (better conceded than fed one by one).
-- For an own tier 1 or 2 tower with visible enemy heroes within ATTACK_RADIUS, once a second per tower:
--   defend if enough allies (at least as many as the attackers) can be there within ARRIVE_SECONDS, walking or by
--   teleport; those allies, nearest first, get a high defend desire for that lane;
--   concede if they cannot: allies that are not already near the tower get no defend desire for it, so nobody runs
--   alone into three or more.
-- Returns nil when it has no opinion, and OHA's own defend logic decides.
local D = {}
local variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
local observe = dofile(GetScriptDirectory()..'/FunLib/bench_observe')

local ATTACK_RADIUS = 1200
local NEAR_RADIUS = 1600
local ARRIVE_SECONDS = 18
local TP_SECONDS = 5
local DEFEND_DESIRE = 0.9

local TOWERS = {
	[LANE_TOP] = { TOWER_TOP_1, TOWER_TOP_2 },
	[LANE_MID] = { TOWER_MID_1, TOWER_MID_2 },
	[LANE_BOT] = { TOWER_BOT_1, TOWER_BOT_2 },
}

local plans = {} -- lane -> { at = time, tower, defenders = { [pid] = true }, concede = bool, attackers = n }

function D.Enabled()
	return variant.defensa_t12 == true
end

local function HasReadyTp(hero)
	for slot = 0, 16 do
		local item = hero:GetItemInSlot(slot)
		if item and (item:GetName() == "item_tpscroll" or item:GetName():find("item_travel_boots")) then
			return item:IsFullyCastable()
		end
	end
	return false
end

local function ArriveSeconds(hero, loc)
	local walk = GetUnitToLocationDistance(hero, loc) / math.max(hero:GetCurrentMovementSpeed(), 200)
	if walk > TP_SECONDS and HasReadyTp(hero) then return TP_SECONDS end
	return walk
end

local function AttackedTower(lane)
	for _, which in ipairs(TOWERS[lane] or {}) do
		local tower = GetTower(GetTeam(), which)
		if tower and tower:IsAlive() then
			local attackers = 0
			for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
				if enemy:IsAlive() and not enemy:IsIllusion() and GetUnitToUnitDistance(enemy, tower) <= ATTACK_RADIUS then
					attackers = attackers + 1
				end
			end
			if attackers > 0 then return tower, attackers end
			return nil, 0 -- the outermost standing tower is the one that matters on this lane
		end
	end
	return nil, 0
end

local function Plan(lane)
	local now = DotaTime()
	local plan = plans[lane]
	if plan and now - plan.at < 1 then return plan end
	local tower, attackers = AttackedTower(lane)
	plan = { at = now, tower = tower, attackers = attackers, defenders = {}, concede = false }
	if tower then
		local loc = tower:GetLocation()
		local candidates = {}
		for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
			if ally:IsAlive() and not ally:IsIllusion() then
				local t = ArriveSeconds(ally, loc)
				if t <= ARRIVE_SECONDS then table.insert(candidates, { pid = ally:GetPlayerID(), t = t }) end
			end
		end
		table.sort(candidates, function(a, b) return a.t < b.t end)
		if #candidates >= attackers then
			for i = 1, math.min(#candidates, attackers + 1) do plan.defenders[candidates[i].pid] = true end
		else
			plan.concede = true
		end
		if observe then
			print(string.format("[bench] defensa t=%d lane=%d atacantes=%d llegan=%d %s", math.floor(now), lane,
				attackers, #candidates, plan.concede and "concede" or "defiende"))
		end
	end
	plans[lane] = plan
	return plan
end

function D.DefendDesire(bot, lane)
	if not D.Enabled() then return nil end
	local plan = Plan(lane)
	if plan.tower == nil then return nil end
	if plan.defenders[bot:GetPlayerID()] then return DEFEND_DESIRE end
	if plan.concede and GetUnitToUnitDistance(bot, plan.tower) > NEAR_RADIUS then return 0 end
	return nil
end

return D
