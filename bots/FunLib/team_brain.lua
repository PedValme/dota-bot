-- dota-bot team brain ("cerebro", Pedro 2026-10-30; design in trabajo/cerebro-equipo.md). OHA has no team_desires.lua
-- and every bot decides alone; here one plan per team decides what the five do together. Benchmark variant
-- "cerebro = true" only: team_desires.lua calls B.Update() once per frame and the bots' modes read B.plan (push,
-- defend, farm, assemble, roshan, team_roam) through the helpers below. Without the variant nothing calls or reads it.
-- Module state is shared between team_desires.lua and the bots of the same team (checked in game 2026-10-30).
--
-- States (one per team, with hold times so it does not swing):
--   DEFENDER   enemy heroes or creeps at our T3, barracks, T4 or Ancient: the nearest allies defend, whatever the lead
--   TOMAR      a fight just won (enemies dead): take the nearest objective before they respawn
--   ROSHAN     clear lead and numbers: Roshan together
--   AGRUPAR    clear lead: gather at the rally point of one lane before pushing
--   EMPUJAR    push that lane together; CERRAR when the push can go into the enemy base (Aegis or a big lead)
--   REAGRUPAR  a fight lost or outnumbered: no one avenges alone; fall back to a tower and farm, come back together
--   LINEA      none of the above: OHA's own behaviour
-- Data behind the numbers: docs/investigacion/2026-10-30-datos-pro.md (relative thresholds, not pro minutes).
local B = {}

B.plan = { state = 'LINEA', lane = nil, rally = nil, focus = nil, engage = nil, defendLane = nil, defenders = {},
	since = -1000, reason = '' }

local J = nil -- jmz_func, required lazily: the bots load it, and team_desires.lua may run first
local nextUpdate = -1000
local wasAlive = {}
local deathTimes = { ally = {}, enemy = {} }
local enemyUltSeen = {} -- unit name -> DotaTime() we last saw it cast its ultimate (enemy cooldowns are hidden)
local holdUntil = -1000      -- REAGRUPAR, TOMAR and ROSHAN windows
local lineaHoldUntil = -1000 -- farming after a stalled push or a failed Roshan
local lastRoshanFail = -1000
local pushStart = { time = -1000, enemyTowers = 0 }

local UPDATE_EVERY = 0.2
local LEAD_GROUP = 5000      -- with +5k a team wins 85% (pro data): group and push
local LEAD_CLOSE = 10000     -- with +10k a team wins 96%: go into the base
local FIGHT_WINDOW = 20      -- seconds that count as "the last fight"
local PUSH_STALL = 75        -- seconds pushing without a building falling: regroup and come back

local LANES = { LANE_TOP, LANE_MID, LANE_BOT }

local function Dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end

local function Allies()
	local list = {}
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local m = GetTeamMember(i)
		if m ~= nil and m:IsHero() and not m:IsIllusion() then table.insert(list, m) end
	end
	return list
end

local function AliveCount(team)
	local n = 0
	for _, pid in ipairs(GetTeamPlayers(team)) do if IsHeroAlive(pid) then n = n + 1 end end
	return n
end

local function VisibleEnemies()
	local list = {}
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
		if e ~= nil and e:IsAlive() and e:IsHero() and not e:IsIllusion() and e:CanBeSeen() then table.insert(list, e) end
	end
	return list
end

local function Centroid(units)
	local x, y, n = 0, 0, 0
	for _, u in ipairs(units) do
		if u:IsAlive() then local l = u:GetLocation(); x, y, n = x + l.x, y + l.y, n + 1 end
	end
	if n == 0 then return nil end
	return Vector(x / n, y / n, 0)
end

-- Deaths in the last FIGHT_WINDOW seconds, from alive -> dead transitions.
local function TrackDeaths(now)
	for side, team in pairs({ ally = GetTeam(), enemy = GetOpposingTeam() }) do
		for _, pid in ipairs(GetTeamPlayers(team)) do
			local alive = IsHeroAlive(pid)
			if wasAlive[pid] == true and not alive then deathTimes[side][pid] = now end
			wasAlive[pid] = alive
		end
	end
end

local function RecentDeaths(side, now)
	local n = 0
	for _, t in pairs(deathTimes[side]) do if now - t <= FIGHT_WINDOW then n = n + 1 end end
	return n
end

-- Enemy ultimates: their cooldown cannot be read, so remember when we saw each one cast.
local function TrackEnemyUlts(enemies, now)
	for _, e in ipairs(enemies) do
		local active = e:GetCurrentActiveAbility()
		if active ~= nil and active:IsUltimate() then enemyUltSeen[e:GetUnitName()] = now end
	end
end

-- Net worth lead. Allies: their exact net worth. Enemies (theirs cannot be read): for each, the larger of the most
-- valuable inventory we have seen it carry and the typical net worth of an enemy hero at its level (GetHeroLevel works
-- on hidden enemies). Tried first and dropped (smoke games of 2026-10-30): items seen only (unseen enemies counted as
-- poor: +6k read in an even game) and our own items per level (our item lead vanished: -5k read while +5k ahead).
-- NW_BY_LEVEL: median net worth of Valve's bots per level in 33 observed Turbo-imitated matches (bench/observaciones).
local NW_BY_LEVEL = { 686, 892, 1111, 1400, 1785, 2088, 2569, 3251, 3808, 4454, 5167, 5736, 6670, 7708, 8407, 9275,
	10070, 11159, 12001, 13030, 13979, 15059, 16798, 18551, 18443, 21267, 25320, 26460, 29294, 32788 }
local enemyItems = {}
local function ItemsCost(u)
	local cost = 0
	for slot = 0, 8 do
		local item = u:GetItemInSlot(slot)
		if item ~= nil then cost = cost + GetItemCost(item:GetName()) end
	end
	return cost
end
local function NetWorthLead(allies, enemies)
	local mine = 0
	for _, a in ipairs(allies) do mine = mine + a:GetNetWorth() end
	for _, e in ipairs(enemies) do
		local name = e:GetUnitName()
		if not e:HasModifier('modifier_arc_warden_tempest_double') and not string.find(name, 'lone_druid_bear') then
			local pid = e:GetPlayerID()
			enemyItems[pid] = math.max(enemyItems[pid] or 0, ItemsCost(e))
		end
	end
	local theirs = 0
	for _, pid in ipairs(GetTeamPlayers(GetOpposingTeam())) do
		local level = math.max(1, math.min(30, GetHeroLevel(pid) or 1))
		theirs = theirs + math.max(enemyItems[pid] or 0, NW_BY_LEVEL[level])
	end
	return mine - theirs
end

local function Power(u, raw)
	local p = raw and u:GetRawOffensivePower() or u:GetOffensivePower()
	return (p or 0) * (0.4 + 0.6 * u:GetHealth() / math.max(1, u:GetMaxHealth()))
end

-- Fight evaluation around a location (replaces "we are stronger", which ignored cooldowns, reinforcements and fog):
-- allies that can arrive (cooldowns and mana respected), visible enemies near (raw power, less if we saw their
-- ultimate in the last 60 s), and enemies unseen for under 10 s that were last near. Returns allies / enemies.
function B.EvaluateFight(loc, now)
	now = now or DotaTime()
	local allyPower, allyCount = 0, 0
	for _, a in ipairs(Allies()) do
		if a:IsAlive() and Dist(a:GetLocation(), loc) <= 2400 then
			allyPower = allyPower + Power(a, false)
			allyCount = allyCount + 1
		end
	end
	local enemyPower, seen = 0, {}
	for _, e in ipairs(VisibleEnemies()) do
		if Dist(e:GetLocation(), loc) <= 1800 then
			local ultUsed = enemyUltSeen[e:GetUnitName()] ~= nil and now - enemyUltSeen[e:GetUnitName()] < 60
			enemyPower = enemyPower + Power(e, true) * (ultUsed and 0.8 or 1)
		end
		seen[e:GetPlayerID()] = true
	end
	local avgAlly = allyCount > 0 and allyPower / allyCount or 1
	for _, pid in ipairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(pid) and not seen[pid] then
			local info = GetHeroLastSeenInfo(pid)
			local last = info and info[1] or info
			if last and last.time_since_seen and last.time_since_seen < 10 and last.location
				and Dist(last.location, loc) <= 3000 then
				enemyPower = enemyPower + avgAlly * 0.8
			end
		end
	end
	return allyPower / math.max(1, enemyPower), allyCount
end

-- Our base structures under attack, per lane (T3 and barracks; T4 and Ancient count for mid). Creeps count too:
-- OHA's defend mode only reacted to heroes, and megacreeps took a base 18k ahead (docs/mapa.md, remate-ab game 17).
local BASE = {
	[LANE_TOP] = { towers = { TOWER_TOP_3 }, barracks = { BARRACKS_TOP_MELEE, BARRACKS_TOP_RANGED } },
	[LANE_MID] = { towers = { TOWER_MID_3, TOWER_BASE_1, TOWER_BASE_2 }, barracks = { BARRACKS_MID_MELEE, BARRACKS_MID_RANGED } },
	[LANE_BOT] = { towers = { TOWER_BOT_3 }, barracks = { BARRACKS_BOT_MELEE, BARRACKS_BOT_RANGED } },
}
local function BaseThreats()
	local team = GetTeam()
	local enemyCreeps = GetUnitList(UNIT_LIST_ENEMY_CREEPS) or {}
	local enemies = VisibleEnemies()
	local threats = {}
	for _, lane in ipairs(LANES) do
		local structures = {}
		for _, t in ipairs(BASE[lane].towers) do local u = GetTower(team, t); if u ~= nil and u:IsAlive() then table.insert(structures, u) end end
		for _, b in ipairs(BASE[lane].barracks) do local u = GetBarracks(team, b); if u ~= nil and u:IsAlive() then table.insert(structures, u) end end
		if lane == LANE_MID then local a = GetAncient(team); if a ~= nil then table.insert(structures, a) end end
		local heroes, creeps, at, inner = 0, 0, nil, false
		local t3 = GetTower(team, BASE[lane].towers[1])
		for _, s in ipairs(structures) do
			local loc = s:GetLocation()
			local h, c = 0, 0
			for _, e in ipairs(enemies) do if Dist(e:GetLocation(), loc) <= 1200 then h = h + 1 end end
			for _, cr in ipairs(enemyCreeps) do if cr:IsAlive() and Dist(cr:GetLocation(), loc) <= 900 then c = c + 1 end end
			if h > heroes or (h == heroes and c > creeps) then heroes, creeps, at, inner = h, c, loc, s ~= t3 end
		end
		-- Creeps alone threaten when they are many (a normal wave with its catapult at a T3 is not an emergency) or
		-- past the T3.
		if at ~= nil and (heroes >= 1 or creeps >= 7 or (inner and creeps >= 3)) then
			threats[lane] = { heroes = heroes, creeps = creeps, loc = at, inner = inner }
		end
	end
	return threats
end

-- Next enemy tower standing in a lane (outermost first) and how far into the enemy base the lane is.
local ENEMY_TOWERS = {
	[LANE_TOP] = { TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3 },
	[LANE_MID] = { TOWER_MID_1, TOWER_MID_2, TOWER_MID_3 },
	[LANE_BOT] = { TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3 },
}
local function NextEnemyTower(lane)
	for tier, t in ipairs(ENEMY_TOWERS[lane]) do
		local u = GetTower(GetOpposingTeam(), t)
		if u ~= nil and u:IsAlive() then return u, tier end
	end
	return GetAncient(GetOpposingTeam()), 4
end

local function EnemyStructuresStanding()
	local n = 0
	for _, lane in ipairs(LANES) do
		for _, t in ipairs(ENEMY_TOWERS[lane]) do local u = GetTower(GetOpposingTeam(), t); if u ~= nil and u:IsAlive() then n = n + 1 end end
	end
	for _, b in ipairs({ BARRACKS_TOP_MELEE, BARRACKS_TOP_RANGED, BARRACKS_MID_MELEE, BARRACKS_MID_RANGED, BARRACKS_BOT_MELEE, BARRACKS_BOT_RANGED }) do
		local u = GetBarracks(GetOpposingTeam(), b); if u ~= nil and u:IsAlive() then n = n + 1 end
	end
	return n
end

-- The lane to push: the nearest next enemy tower to the group, preferring lanes whose creep wave is ahead. Unless the
-- team can go into the base (closing), lanes already at the enemy T3 are skipped: high ground waits for Aegis or a big
-- lead (pro data: half of the first T3s fall with Aegis), and the outer towers are free gold meanwhile.
local function ChooseLane(center, closing)
	local best, bestScore = nil, math.huge
	for _, lane in ipairs(LANES) do
		local tower, tier = NextEnemyTower(lane)
		if tower ~= nil and (closing or tier < 3) then
			local score = Dist(center, tower:GetLocation()) - 1500 * GetLaneFrontAmount(GetTeam(), lane, false)
			if score < bestScore then best, bestScore = lane, score end
		end
	end
	return best
end

local function RallyPoint(lane)
	return GetLaneFrontLocation(GetTeam(), lane, -800)
end

-- Our safest standing tower near the group, to fall back to.
local function FallbackPoint(center)
	local best, bestD = nil, math.huge
	for _, lane in ipairs(LANES) do
		for _, t in ipairs({ ({ [LANE_TOP] = TOWER_TOP_3, [LANE_MID] = TOWER_MID_3, [LANE_BOT] = TOWER_BOT_3 })[lane],
			({ [LANE_TOP] = TOWER_TOP_2, [LANE_MID] = TOWER_MID_2, [LANE_BOT] = TOWER_BOT_2 })[lane] }) do
			local u = GetTower(GetTeam(), t)
			if u ~= nil and u:IsAlive() then
				local d = Dist(center, u:GetLocation())
				if d < bestD then best, bestD = u:GetLocation(), d end
			end
		end
	end
	return best or GetAncient(GetTeam()):GetLocation()
end

-- Roshan respawns 8 to 11 minutes after dying; counted as up only after the longest, also in Turbo (the benchmark's
-- imitated Turbo keeps Roshan as in normal mode, and waiting at an empty pit is worse than arriving late).
local function RoshanAlive(now)
	local killed = GetRoshanKillTime()
	if killed == nil or killed <= 0 then return now > 0 end
	return now - killed > 11 * 60
end
local ROSHAN_MAX = 60 -- seconds the team may spend on a Roshan attempt

local function SetState(state, info, now)
	local p = B.plan
	if p.state ~= state or p.lane ~= info.lane then
		print(string.format('[bench] plan t=%d team=%d %s -> %s lane=%s %s', math.floor(now), GetTeam(), p.state, state,
			tostring(info.lane), info.reason or ''))
		p.since = now
	end
	p.state = state
	p.lane = info.lane
	p.rally = info.rally
	p.defendLane = info.defendLane
	p.defenders = info.defenders or {}
	p.reason = info.reason or ''
end

local function NearestAllies(loc, k)
	local list = {}
	for _, a in ipairs(Allies()) do if a:IsAlive() then table.insert(list, a) end end
	table.sort(list, function(x, y) return Dist(x:GetLocation(), loc) < Dist(y:GetLocation(), loc) end)
	local set = {}
	for i = 1, math.min(k, #list) do set[list[i]:GetPlayerID()] = true end
	return set
end

function B.Update()
	local now = DotaTime()
	if now < nextUpdate then return end
	nextUpdate = now + UPDATE_EVERY
	if J == nil then
		local ok, mod = pcall(require, GetScriptDirectory()..'/FunLib/jmz_func')
		if ok then J = mod end
	end

	local allies = Allies()
	local enemies = VisibleEnemies()
	TrackDeaths(now)
	TrackEnemyUlts(enemies, now)
	local center = Centroid(allies) or GetAncient(GetTeam()):GetLocation()
	local aliveA, aliveE = AliveCount(GetTeam()), AliveCount(GetOpposingTeam())
	local lead = NetWorthLead(allies, enemies)
	if now - (B.lastTick or -1000) >= 30 then
		B.lastTick = now
		print(string.format('[bench] plan_tick t=%d team=%d state=%s lead=%d alive=%d-%d', math.floor(now), GetTeam(),
			B.plan.state, lead, aliveA, aliveE))
	end
	local okAegis, aegis = pcall(function() return J ~= nil and J.DoesTeamHaveAegis() end)
	local hasAegis = okAegis and aegis == true
	local p = B.plan

	-- Focus target and engage signal for fights near the group (used by team_roam and initiator ultimates).
	local focus, focusHp = nil, math.huge
	local near = 0
	for _, e in ipairs(enemies) do
		if Dist(e:GetLocation(), center) <= 1600 then
			near = near + 1
			if e:GetHealth() < focusHp then focus, focusHp = e, e:GetHealth() end
		end
	end
	p.focus = focus
	if near >= 2 and p.state ~= 'REAGRUPAR' and p.state ~= 'LINEA' and B.EvaluateFight(center, now) >= 1.1 then
		p.engage = { loc = center, time = now }
	end

	if now < 0 then SetState('LINEA', { reason = 'pregame' }, now) return end

	-- 1) Defend the base first, whatever the lead. Two or more enemy heroes, or any past the T3, make the whole plan
	-- DEFENDER. A lone hero at a T3 (a split-pusher) or creeps alone only send the nearest one or two allies
	-- (p.creepDefense) and the rest keep the plan: in v1 a lone split-pusher pulled two defenders out of every push
	-- (series cerebro-ab, games lost on Dire).
	local threats = BaseThreats()
	local worstLane, worst = nil, nil
	for lane, t in pairs(threats) do
		if worst == nil or t.heroes > worst.heroes or (t.heroes == worst.heroes and t.creeps > worst.creeps) then worstLane, worst = lane, t end
	end
	p.creepDefense = nil
	if worst ~= nil and (worst.heroes >= 2 or (worst.heroes >= 1 and worst.inner)) then
		local k = worst.heroes >= 3 and 5 or worst.heroes + 1
		SetState('DEFENDER', { lane = worstLane, defendLane = worstLane, rally = worst.loc,
			defenders = NearestAllies(worst.loc, k), reason = string.format('heroes=%d creeps=%d k=%d', worst.heroes, worst.creeps, k) }, now)
		return
	elseif worst ~= nil then
		local k = ((worst.heroes >= 1 and worst.creeps >= 5) or worst.creeps >= 8) and 2 or 1
		p.creepDefense = { lane = worstLane, defenders = NearestAllies(worst.loc, k) }
	end

	-- Hold the current state a little unless something above overrides it.
	local allyDeaths, enemyDeaths = RecentDeaths('ally', now), RecentDeaths('enemy', now)

	-- 2) Fight lost or outnumbered: regroup, no one avenges alone.
	if allyDeaths - enemyDeaths >= 2 or aliveA <= aliveE - 2 then
		SetState('REAGRUPAR', { rally = FallbackPoint(center), reason = string.format('deaths %d-%d alive %d-%d', allyDeaths, enemyDeaths, aliveA, aliveE) }, now)
		holdUntil = now + 25
		return
	end
	if p.state == 'REAGRUPAR' and now < holdUntil then return end

	-- Roshan is an option only once a team can kill it (from minute 10 in Turbo, 20 in normal) and not within 3 min of
	-- a failed attempt.
	local turbo = J ~= nil and J.IsModeTurbo and J.IsModeTurbo()
	local roshanReady = RoshanAlive(now) and not hasAegis and now > (turbo and 10 or 20) * 60 and now - lastRoshanFail > 180

	-- 3) Fight won: take the nearest objective before they respawn.
	if enemyDeaths - allyDeaths >= 2 and aliveA >= aliveE + 2 then
		if p.state == 'TOMAR' or p.state == 'ROSHAN' then return end -- keep the objective chosen for this window
		local okR, roshLoc = pcall(function() return J.GetCurrentRoshanLocation() end)
		local lane = ChooseLane(center, true)
		if roshanReady and okR and roshLoc ~= nil and Dist(center, roshLoc) < 3500 then
			SetState('ROSHAN', { reason = 'tras pelea' }, now)
		elseif lane ~= nil then
			SetState('TOMAR', { lane = lane, rally = RallyPoint(lane), reason = string.format('deaths %d-%d', allyDeaths, enemyDeaths) }, now)
		end
		holdUntil = now + 15
		return
	end
	if p.state == 'ROSHAN' and now - p.since > ROSHAN_MAX then
		SetState('LINEA', { reason = 'roshan sin exito' }, now)
		lastRoshanFail = now
		lineaHoldUntil = now + 20
		return
	end
	if (p.state == 'TOMAR' or p.state == 'ROSHAN') and now < holdUntil and aliveA > aliveE then return end
	-- After a stalled push or a failed Roshan, farm for a while (OHA's behaviour) before trying again.
	if p.state == 'LINEA' and now < lineaHoldUntil then return end

	-- 4) Clear lead at even or better numbers: Roshan, or group and push one lane; into the base with Aegis or +10k.
	-- Hysteresis: a group already formed keeps going while the lead stays above 3.5k and at most one hero is down.
	local grouped = p.state == 'AGRUPAR' or p.state == 'EMPUJAR' or p.state == 'CERRAR'
	if (lead >= LEAD_GROUP and aliveA >= aliveE) or (grouped and lead >= LEAD_GROUP - 1500 and aliveA >= aliveE - 1) then
		if roshanReady and aliveA >= 4 and lead >= LEAD_GROUP and (p.state == 'ROSHAN' or aliveE <= 3) then
			SetState('ROSHAN', { reason = string.format('lead=%d', lead) }, now)
			return
		end
		-- Into the enemy base only with the fight in favour, not just Aegis or a lead: in v1 the team went up the high
		-- ground, lost the fight there and the base after it (series cerebro-ab). Needs at least four alive, no fewer
		-- than them, and the fight around the group evaluated clearly ours.
		local fightHere = B.EvaluateFight(center, now)
		local close = (hasAegis or lead >= LEAD_CLOSE) and aliveA >= 4 and aliveA >= aliveE and fightHere >= 1.2
		-- And back out in time: once the closing goes wrong (an ally down and the fight no longer ours), stop and farm
		-- instead of feeding the rest of the team into the towers.
		if p.state == 'CERRAR' and allyDeaths >= 1 and fightHere < 1.0 then
			SetState('LINEA', { reason = string.format('retirada del high ground eval=%.2f', fightHere) }, now)
			lineaHoldUntil = now + 25
			return
		end
		local lane = p.lane
		local laneAtT3 = false
		if lane ~= nil then local _, tier = NextEnemyTower(lane); laneAtT3 = tier >= 3 and not close end
		if lane == nil or not grouped or laneAtT3 or (p.state == 'AGRUPAR' and now - p.since > 40) then
			lane = ChooseLane(center, close)
		end
		if lane == nil then
			-- Every lane is at the enemy T3 and the team cannot go in yet: farm and wait for Aegis or a bigger lead.
			SetState('LINEA', { reason = string.format('esperando high ground lead=%d', lead) }, now)
			return
		end
		local rally = RallyPoint(lane)
		local gathered = 0
		for _, a in ipairs(allies) do if a:IsAlive() and Dist(a:GetLocation(), rally) <= 1800 then gathered = gathered + 1 end end
		local need = math.max(3, math.min(4, aliveA - 1))
		local pushing = p.state == 'EMPUJAR' or p.state == 'CERRAR'
		-- Gathering has a time limit: after 35 s the push starts with whoever is there.
		if pushing or gathered >= need or (p.state == 'AGRUPAR' and now - p.since > 35) then
			if not pushing then pushStart = { time = now, enemyTowers = EnemyStructuresStanding() } end
			local standing = EnemyStructuresStanding()
			if standing < pushStart.enemyTowers then pushStart = { time = now, enemyTowers = standing } end
			if now - pushStart.time > PUSH_STALL then
				SetState('LINEA', { reason = 'empuje estancado' }, now)
				lineaHoldUntil = now + 30
				return
			end
			SetState(close and 'CERRAR' or 'EMPUJAR', { lane = lane, rally = rally, reason = string.format('lead=%d gathered=%d', lead, gathered) }, now)
		else
			SetState('AGRUPAR', { lane = lane, rally = rally, reason = string.format('lead=%d gathered=%d/%d', lead, gathered, need) }, now)
		end
		return
	end

	SetState('LINEA', { reason = string.format('lead=%d alive %d-%d', lead, aliveA, aliveE) }, now)
end

-- Helpers for the bots' modes. Each returns nil when the plan has nothing to say, so the mode keeps OHA's logic.
local enabled = nil -- the variant is read once per match (Customize/general.lua at load)
local function Enabled()
	if enabled == nil then
		local ok, Customize = pcall(require, GetScriptDirectory()..'/Customize/general')
		enabled = ok and type(Customize.BenchVariant) == 'table' and Customize.BenchVariant.cerebro == true
	end
	return enabled
end
B.Enabled = Enabled

function B.IsDefender(bot)
	local pid = bot:GetPlayerID()
	if B.plan.state == 'DEFENDER' and B.plan.defenders[pid] == true then return true, B.plan.defendLane end
	local cd = B.plan.creepDefense
	if cd ~= nil and cd.defenders[pid] == true then return true, cd.lane end
	return false, nil
end

-- Push desire for one lane (FunLib/aba_push.lua).
function B.PushDesire(bot, lane)
	local p = B.plan
	if p.state == 'DEFENDER' then
		if B.IsDefender(bot) then return 0 end
		return nil
	end
	if p.state == 'REAGRUPAR' or p.state == 'ROSHAN' or p.state == 'AGRUPAR' then return 0 end
	if p.state == 'EMPUJAR' or p.state == 'CERRAR' or p.state == 'TOMAR' then
		if lane ~= p.lane then return 0 end
		local hp = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
		if hp < 0.35 then return 0.2 end
		-- Into the enemy base only when closing (Aegis or +10k) or right after a won fight.
		local _, tier = NextEnemyTower(lane)
		if tier >= 3 and p.state == 'EMPUJAR' then return 0.3 end
		return 0.8
	end
	return nil
end

-- Defend desire for one lane (FunLib/aba_defend.lua).
function B.DefendDesire(bot, lane)
	local defender, defendLane = B.IsDefender(bot)
	if defender then return lane == defendLane and 0.95 or 0 end
	return nil
end

-- Rally point for mode_assemble: gather before a push, or fall back after a lost fight.
function B.RallyFor(bot)
	local p = B.plan
	if p.rally == nil or B.IsDefender(bot) then return nil end
	local d = Dist(bot:GetLocation(), p.rally)
	if p.state == 'AGRUPAR' and d > 700 then return p.rally, 0.8 end
	if p.state == 'REAGRUPAR' and d > 2500 then return p.rally, 0.75 end
	return nil
end

-- Whether farming is the plan (mode_farm_generic.lua lifts its "no farming with a 6k lead" rule): only after a lost
-- fight; in LINEA OHA's own rule stays.
function B.FarmAllowed()
	return B.plan.state == 'REAGRUPAR'
end

-- Roshan desire (mode_roshan_generic.lua); a badly hurt bot is left to its own modes.
function B.RoshanDesire(bot)
	if B.plan.state == 'ROSHAN' and not B.IsDefender(bot) and bot:GetHealth() / math.max(1, bot:GetMaxHealth()) >= 0.35 then
		return 0.9
	end
	return nil
end

-- A teamfight the brain called (initiator ultimates wait for this instead of "2 allies already in ATTACK mode"), with
-- follow-up at hand: at least two other allies within 1200, so an area control ultimate is followed by their damage
-- instead of landing alone (the general form of ultimate combos).
function B.InEngage(bot)
	local e = B.plan.engage
	if e == nil or DotaTime() - e.time >= 3 or Dist(bot:GetLocation(), e.loc) > 1600 then return false end
	local followUp = 0
	for _, a in ipairs(Allies()) do
		if a ~= bot and a:IsAlive() and Dist(a:GetLocation(), bot:GetLocation()) <= 1200 then followUp = followUp + 1 end
	end
	return followUp >= 2
end

-- Whether helping a caught ally is worth it: not while regrouping, and only if the fight there looks winnable.
-- The evaluation is cached 0.2 s per ally (it runs every frame per bot during fights) and the bar is 0.9, not 1.0,
-- because it is asymmetric: allies count with cooldowns, enemies without, plus the unseen ones.
local helpCache = {}
function B.ShouldHelpAlly(bot, ally)
	if B.plan.state == 'REAGRUPAR' and Dist(bot:GetLocation(), ally:GetLocation()) > 900 then return false end
	local pid, now = ally:GetPlayerID(), DotaTime()
	local c = helpCache[pid]
	if c == nil or now - c.time > 0.2 then
		c = { time = now, value = B.EvaluateFight(ally:GetLocation(), now) }
		helpCache[pid] = c
	end
	return c.value >= 0.9
end

function B.Focus(bot)
	local f = B.plan.focus
	if f ~= nil and f:IsAlive() and f:CanBeSeen() and Dist(bot:GetLocation(), f:GetLocation()) <= bot:GetAttackRange() + 700 then
		return f
	end
	return nil
end

return B
