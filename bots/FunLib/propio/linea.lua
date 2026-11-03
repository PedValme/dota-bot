-- dota-bot's own bot, full-control test (trabajo/prueba-control.md): one hero playing its lane with nothing of Valve's
-- or OHA's decision code. Each tick: perceive (a snapshot), decide (ordered rules, each with its reason), act (an order
-- only when the intent changes, never cutting an attack's wind-up), log ("[bench] prop ..." lines).
-- What it does: walks to its lane behind its own creeps, predicts each creep's health when its own attack would land
-- (attacks in flight, the next hits of the units attacking it) and hits once at the right moment, denies, retreats on
-- low health, tower aggro or enemy damage, uses salve and tango, buys its starting items and levels up with Valve's own
-- build for the hero (scripts/npc/bot_builds.txt, docs/api/README.md). It casts no ability and does not fight.
-- Only the Bot API listed in docs/api/volcado.md. The team's VM is shared with OHA, whose FunLib/aba_global_overrides
-- wraps a few calls (GetHealth, GetLocation, GetNearby*...): for visible units they answer as Valve's.
local L = {}

local out = BenchRawPrint or print
local Registro = require(GetScriptDirectory()..'/FunLib/propio/registro_linea')

-- Valve's own level-up order for the heroes this test may take (bot_builds.txt, 7.41f).
local BUILDS = {
	npc_dota_hero_sniper = { 'sniper_shrapnel', 'sniper_headshot', 'sniper_shrapnel', 'sniper_headshot',
		'sniper_shrapnel', 'sniper_assassinate', 'sniper_shrapnel', 'sniper_headshot', 'sniper_headshot',
		'special_bonus_unique_sniper_headshot_damage', 'sniper_take_aim', 'sniper_take_aim', 'sniper_assassinate',
		'sniper_take_aim', 'sniper_take_aim', 'special_bonus_unique_sniper_6', 'sniper_assassinate',
		'special_bonus_unique_sniper_4', 'special_bonus_unique_sniper_3', 'special_bonus_unique_sniper_5',
		'special_bonus_unique_sniper_1', 'special_bonus_unique_sniper_shrapnel_damage', 'special_bonus_unique_sniper_2' },
}
local STARTING_ITEMS = { 'item_tango', 'item_flask', 'item_branches', 'item_branches' }

-- Thresholds of the rules (one place, so the log and the rules agree).
local K = {
	retreatHp = 0.30,     -- retreat below this health fraction
	returnHp = 0.65,      -- come back to the lane above it
	fountainHp = 0.20,    -- below it, without a salve, go heal at the fountain
	enemyBurst = 0.80,    -- retreat if the visible enemy heroes can deal this share of our health in 3 s
	holdBack = 350,       -- stand this far behind our creeps' front, toward home
	towerMargin = 820,    -- keep this far from an enemy tower when it is not busy with creeps (range 700)
	windUp = 0.15,        -- extra seconds an attack order is protected after its attack point
	lookAhead = 2.0,      -- seconds ahead a creep is watched to stand ready for it
	moveRefresh = 1.0,    -- re-issue a move order at most this often unless the target moved
}

local S = {} -- pid -> state of this bot

-- A missing location (OHA's GetLocation override answers nil for a unit we cannot see) counts as far away: the
-- 2026-11-03 smoke failed on it 6 and 11 times per match.
local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Toward(from, to, dist)
	local d = D2(from, to)
	if d < 1 then return from end
	return Vector(from.x + (to.x - from.x) * dist / d, from.y + (to.y - from.y) * dist / d, from.z)
end
local function Fmt(v) return type(v) == 'number' and string.format('%.2f', v) or tostring(v) end
local function Valid(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end

local function Log(s, bot, kind, text)
	out(string.format('[bench] prop %s t=%.1f pid=%d %s', kind, DotaTime(), bot:GetPlayerID(), text))
end

local function State(bot)
	local pid = bot:GetPlayerID()
	if S[pid] == nil then
		S[pid] = { intent = 'ninguna', reason = '', nextSkill = 1, bought = false, busyUntil = -1, lastMoveAt = -1,
			moveTo = nil, pending = nil, lastStatus = -1000, thinkN = 0, thinkCost = 0, thinkMax = 0, thinkSince = nil,
			retreating = false }
	end
	return S[pid]
end

local function Home(team) return GetAncient(team):GetLocation() end
local function Fountain(team) return GetShopLocation(team, SHOP_HOME) end

-- Where to stand safe: behind our first standing mid tower, else the ancient.
local function SafeSpot(team)
	for _, t in ipairs({ TOWER_MID_1, TOWER_MID_2, TOWER_MID_3 }) do
		local tower = GetTower(team, t)
		if Valid(tower) then return Toward(tower:GetLocation(), Home(team), 250), 'torre_mid_' .. t end
	end
	return Home(team), 'ancient'
end

----------------------------------------------------------------------------------------------------------------------
-- Perception
----------------------------------------------------------------------------------------------------------------------

-- The units attacking a creep now (creeps and towers of the other side), from their attack targets.
local function Attackers(creep, units)
	local list = {}
	for _, a in ipairs(units) do
		if Valid(a) and a:GetAttackTarget() == creep then table.insert(list, a) end
	end
	return list
end

-- Health the creep will have in dt seconds: minus the attacks already flying at it that land in time, and the next
-- hit of each unit attacking it that lands in time (melee: when its next swing executes; ranged: plus the flight).
-- Returns the health, how many projectiles and next hits it counted.
local function PredictHealth(creep, dt, attackers, now)
	local hp = creep:GetHealth()
	local loc = creep:GetLocation()
	local nProj, nHits = 0, 0
	for _, p in ipairs(creep:GetIncomingTrackingProjectiles() or {}) do
		if p.is_attack and Valid(p.caster) then
			local speed = p.caster:GetAttackProjectileSpeed()
			if speed > 0 and D2(p.location, loc) / speed <= dt then
				hp = hp - creep:GetActualIncomingDamage(p.caster:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
				nProj = nProj + 1
			end
		end
	end
	for _, a in ipairs(attackers) do
		local nextShot = a:GetLastAttackTime() + a:GetSecondsPerAttack() - now
		if nextShot < 0 then nextShot = a:GetAttackPoint() end
		local speed = a:GetAttackProjectileSpeed()
		local flight = (speed and speed > 0) and D2(a:GetLocation(), loc) / speed or 0
		if nextShot + flight <= dt then
			hp = hp - creep:GetActualIncomingDamage(a:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
			nHits = nHits + 1
		end
	end
	return hp, nProj, nHits
end

local function Perceive(bot)
	local team = GetTeam()
	local p = {
		team = team, now = GameTime(), t = DotaTime(), loc = bot:GetLocation(),
		hp = bot:GetHealth() / math.max(bot:GetMaxHealth(), 1), hpAbs = bot:GetHealth(),
		range = bot:GetAttackRange(), point = bot:GetAttackPoint(), projSpeed = bot:GetAttackProjectileSpeed(),
		moveSpeed = bot:GetCurrentMovementSpeed(),
		dmgMin = bot:GetAttackDamage() - bot:GetBaseDamageVariance(),
		enemyCreeps = bot:GetNearbyLaneCreeps(1500, true) or {},
		allyCreeps = bot:GetNearbyLaneCreeps(1500, false) or {},
		enemyHeroes = bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE) or {},
		enemyTowers = bot:GetNearbyTowers(1500, true) or {},
		allyTowers = bot:GetNearbyTowers(1500, false) or {},
		front = GetLaneFrontLocation(team, LANE_MID, 0),
	}
	-- Damage the visible enemy heroes can deal to us in 3 s (Valve's own estimate, mana and cooldowns included).
	p.enemyBurst = 0
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and e:CanBeSeen() then
			p.enemyBurst = p.enemyBurst + e:GetEstimatedDamageToTarget(true, bot, 3.0, DAMAGE_TYPE_ALL)
		end
	end
	p.towerOnMe = false
	for _, tw in ipairs(p.enemyTowers) do
		if Valid(tw) and tw:GetAttackTarget() == bot then p.towerOnMe = true end
	end
	return p
end

----------------------------------------------------------------------------------------------------------------------
-- Decision: ordered rules; the first that fires wins. Each returns an intent, its reason and what it acts on.
----------------------------------------------------------------------------------------------------------------------

local function HasItem(bot, name)
	local slot = bot:FindItemSlot(name)
	if slot < 0 or slot > 5 then return nil end
	return bot:GetItemInSlot(slot)
end

local function RuleRetreat(bot, s, p)
	local reason = nil
	if p.towerOnMe then reason = 'torre_me_ataca'
	elseif p.hp < K.retreatHp then reason = string.format('vida %.2f < %.2f', p.hp, K.retreatHp)
	elseif p.enemyBurst > K.enemyBurst * p.hpAbs then
		reason = string.format('daño_enemigo_3s %d > %.0f%% de %d', p.enemyBurst, K.enemyBurst * 100, p.hpAbs)
	elseif s.retreating and p.hp < K.returnHp then reason = string.format('recuperando %.2f < %.2f', p.hp, K.returnHp) end
	s.retreating = reason ~= nil
	if reason == nil then s.toFountain = false return nil end
	-- Once heading for the fountain it keeps going until healed (returnHp), not back and forth with the tower.
	if s.toFountain or (p.hp < K.fountainHp and HasItem(bot, 'item_flask') == nil) then
		s.toFountain = true
		return { intent = 'retirada_fuente', reason = reason .. ', sin salvia', to = Fountain(p.team) }
	end
	if p.towerOnMe then
		return { intent = 'salir_de_torre', reason = reason, to = Toward(p.loc, Home(p.team), 500) }
	end
	local spot, name = SafeSpot(p.team)
	return { intent = 'retirada', reason = reason .. ' -> ' .. name, to = spot }
end

local function RuleHeal(bot, s, p)
	if bot:HasModifier('modifier_flask_healing') or bot:HasModifier('modifier_tango_heal') then return nil end
	local safe = #p.enemyHeroes == 0 and not bot:WasRecentlyDamagedByAnyHero(2.0) and not bot:WasRecentlyDamagedByTower(2.0)
	local salve = HasItem(bot, 'item_flask')
	if salve ~= nil and p.hp < 0.55 and safe then
		return { intent = 'curar_salvia', reason = string.format('vida %.2f, sin enemigos cerca', p.hp), item = salve }
	end
	local tango = HasItem(bot, 'item_tango')
	if tango ~= nil and bot:GetMaxHealth() - p.hpAbs > 120 then
		local trees = bot:GetNearbyTrees(350)
		if trees ~= nil and trees[1] ~= nil then
			return { intent = 'curar_tango', reason = string.format('faltan %d de vida', bot:GetMaxHealth() - p.hpAbs),
				item = tango, tree = trees[1] }
		end
	end
	return nil
end

-- Last hit (enemy creep) or deny (our creep under half health): the creep whose predicted health when our attack
-- lands is above 0 and within our damage. Also returns the creep to stand ready for, if one is about to be killable.
local function RuleLastHit(bot, s, p)
	local best, ready = nil, nil
	local function consider(list, attackersFrom, deny)
		for _, c in ipairs(list) do
			if Valid(c) and (not deny or c:GetHealth() < 0.5 * c:GetMaxHealth()) then
				local d = D2(p.loc, c:GetLocation())
				local walk = math.max(0, d - p.range) / math.max(p.moveSpeed, 1)
				local flight = p.projSpeed > 0 and math.min(d, p.range) / p.projSpeed or 0
				-- Our own attack may still be cooling down: the next swing starts at last attack + seconds per attack.
				local cooldown = math.max(0, bot:GetLastAttackTime() + bot:GetSecondsPerAttack() - p.now)
				local tLand = math.max(walk, cooldown) + p.point + flight
				local attackers = Attackers(c, attackersFrom)
				local hpAt, nProj, nHits = PredictHealth(c, tLand, attackers, p.now)
				local dmg = c:GetActualIncomingDamage(p.dmgMin, DAMAGE_TYPE_PHYSICAL)
				if hpAt > 0 and hpAt <= dmg and walk < 0.5 then
					if best == nil or tLand < best.tLand then
						-- dLast: seconds since the first attacker's last attack, to check GetLastAttackTime's clock.
						local dLast = attackers[1] ~= nil and (p.now - attackers[1]:GetLastAttackTime()) or -1
						best = { creep = c, tLand = tLand, flight = flight, hpAt = hpAt, dmg = dmg, nProj = nProj,
							nHits = nHits, deny = deny, dLast = dLast }
					end
				elseif ready == nil and hpAt > 0 then
					local hpSoon = PredictHealth(c, tLand + K.lookAhead, attackers, p.now)
					if hpSoon <= dmg then ready = c end
				end
			end
		end
	end
	local enemies = {}
	for _, u in ipairs(p.enemyCreeps) do table.insert(enemies, u) end
	for _, u in ipairs(p.enemyTowers) do table.insert(enemies, u) end
	local allies = {}
	for _, u in ipairs(p.allyCreeps) do table.insert(allies, u) end
	for _, u in ipairs(p.allyTowers) do table.insert(allies, u) end
	consider(p.enemyCreeps, allies, false)
	if best == nil then consider(p.allyCreeps, enemies, true) end
	if best ~= nil then
		local c = best.creep
		return { intent = best.deny and 'denegar' or 'ultimo_golpe', target = c, hit = best,
			reason = string.format('%s vida %d -> %.0f al llegar en %.2fs (proy=%d golpes=%d dlast=%.2f), mi daño %.0f',
				(string.gsub(c:GetUnitName(), 'npc_dota_', '')), c:GetHealth(), best.hpAt, best.tLand, best.nProj,
				best.nHits, best.dLast, best.dmg) }
	end
	return nil, ready
end

-- Where to stand in lane: behind our creeps' front, out of an idle enemy tower's reach.
local function LanePoint(p)
	local spot = Toward(p.front, Home(p.team), K.holdBack)
	for _, tw in ipairs(p.enemyTowers) do
		if Valid(tw) and D2(spot, tw:GetLocation()) < K.towerMargin then
			spot = Toward(tw:GetLocation(), spot, K.towerMargin)
		end
	end
	return spot
end

local function Decide(bot, s, p)
	if p.t < -5 and not s.bought then return { intent = 'comprar', reason = 'objetos iniciales' } end
	local r = RuleRetreat(bot, s, p)
	-- Retreating for health alone (no tower on us, no enemy burst), healing comes first: RuleHeal itself requires
	-- no enemy hero near and no recent hero or tower damage.
	if r and not p.towerOnMe and p.enemyBurst <= K.enemyBurst * p.hpAbs then
		local h = RuleHeal(bot, s, p)
		if h then return h end
	end
	if r then return r end
	r = RuleHeal(bot, s, p)
	if r then return r end
	local ready
	r, ready = RuleLastHit(bot, s, p)
	if r then return r end
	if ready ~= nil then
		local spot = Toward(ready:GetLocation(), p.loc, p.range * 0.9)
		return { intent = 'preparar_golpe', reason = string.format('%s cae en ~%.0fs', string.gsub(ready:GetUnitName(), 'npc_dota_', ''), K.lookAhead),
			to = D2(p.loc, ready:GetLocation()) > p.range and spot or nil }
	end
	return { intent = 'linea', reason = string.format('detrás del frente a %d', K.holdBack), to = LanePoint(p) }
end

----------------------------------------------------------------------------------------------------------------------
-- Action
----------------------------------------------------------------------------------------------------------------------

local function MoveTo(bot, s, p, to)
	if to == nil or D2(p.loc, to) < 60 then return end
	-- The same destination is not ordered again within moveRefresh, whatever the current action.
	if s.moveTo ~= nil and D2(s.moveTo, to) < 150 and p.now - s.lastMoveAt < K.moveRefresh then return end
	bot:Action_MoveToLocation(to)
	s.moveTo, s.lastMoveAt = to, p.now
end

local function Buy(bot, s)
	for _, item in ipairs(STARTING_ITEMS) do
		local code = bot:ActionImmediate_PurchaseItem(item)
		Log(s, bot, 'compra', string.format('%s codigo=%s oro=%d', item, tostring(code), bot:GetGold()))
	end
	s.bought = true
end

local function LevelUp(bot, s)
	local build = BUILDS[bot:GetUnitName()]
	if build == nil or bot:GetAbilityPoints() <= 0 or s.nextSkill > #build then return end
	local name = build[s.nextSkill]
	bot:ActionImmediate_LevelAbility(name)
	Log(s, bot, 'nivel', string.format('%s nivel=%d puntos=%d', name, bot:GetLevel(), bot:GetAbilityPoints()))
	s.nextSkill = s.nextSkill + 1
end

-- After an attack lands, did the last hit or deny happen? Compares the counters (checklist item 6 and 7).
local function CheckPending(bot, s, p)
	local q = s.pending
	if q == nil or p.now < q.landAt + 0.4 then return end
	local lh, dn = bot:GetLastHits() - q.lh0, bot:GetDenies() - q.dn0
	local alive = Valid(q.creep)
	Log(s, bot, 'golpe_res', string.format('%s %s lh+%d dn+%d creep_vivo=%s vida=%s prevista=%.0f',
		q.deny and 'denegar' or 'ultimo_golpe', ((q.deny and dn > 0) or (not q.deny and lh > 0)) and 'acierto' or 'fallo',
		lh, dn, tostring(alive), alive and tostring(q.creep:GetHealth()) or '-', q.hpAt))
	s.pending = nil
end

local function Act(bot, s, p, d)
	if d.intent == 'comprar' then Buy(bot, s) return end
	-- An item order is not repeated each frame while the healing buff has not appeared yet.
	if d.intent == 'curar_salvia' then bot:Action_UseAbilityOnEntity(d.item, bot) s.busyUntil = p.now + 0.6 return end
	if d.intent == 'curar_tango' then bot:Action_UseAbilityOnTree(d.item, d.tree) s.busyUntil = p.now + 1.0 return end
	if (d.intent == 'ultimo_golpe' or d.intent == 'denegar') then
		if s.pending ~= nil then
			Log(s, bot, 'golpe_res', string.format('%s reemplazado', s.pending.deny and 'denegar' or 'ultimo_golpe'))
		end
		bot:Action_AttackUnit(d.target, true)
		s.lastAttackOrder = p.now
		-- Protect the wind-up only (walk and attack point), not the projectile's flight.
		s.busyUntil = p.now + d.hit.tLand - d.hit.flight + K.windUp
		s.pending = { creep = d.target, landAt = p.now + d.hit.tLand, hpAt = d.hit.hpAt, deny = d.hit.deny,
			lh0 = bot:GetLastHits(), dn0 = bot:GetDenies() }
		Log(s, bot, 'golpe', d.reason)
		return
	end
	-- No destination: no order (clearing the queue would leave the hero idle, free to auto-attack).
	MoveTo(bot, s, p, d.to)
end

----------------------------------------------------------------------------------------------------------------------

-- An attack we did not order (the engine's auto-attack while idle or moving): its target, so the log shows whether the
-- engine still acts on its own (checklist item 5). Our own orders are marked by lastAttackOrder.
local function WatchAutoAttack(bot, s, p)
	local last = bot:GetLastAttackTime()
	if s.seenAttack ~= nil and last > s.seenAttack + 0.01 and p.now - (s.lastAttackOrder or -1000) > 2.0 then
		local target = bot:GetAttackTarget()
		Log(s, bot, 'autoataque', string.format('objetivo=%s intencion=%s accion=%d',
			Valid(target) and (string.gsub(target:GetUnitName(), 'npc_dota_', '')) or '?', s.intent, bot:GetCurrentActionType()))
	end
	s.seenAttack = last
end

local function Status(bot, s, p)
	if p.t - s.lastStatus < 2 then return end
	s.lastStatus = p.t
	Log(s, bot, 'estado', string.format('intencion=%s vida=%.2f modo=%s accion=%d cola=%d creeps_e=%d creeps_a=%d heroes_e=%d daño3s=%d',
		s.intent, p.hp, tostring(bot:GetActiveMode()), bot:GetCurrentActionType(), bot:NumQueuedActions(),
		#p.enemyCreeps, #p.allyCreeps, #p.enemyHeroes, p.enemyBurst))
end

-- How often the engine calls this Think and what it costs (checklist item 11): one line per minute of game time.
local function Cost(bot, s, t, ms)
	s.thinkN = s.thinkN + 1
	s.thinkCost = s.thinkCost + ms
	if ms > s.thinkMax then s.thinkMax = ms end
	if s.thinkSince == nil then s.thinkSince = t return end
	if t - s.thinkSince >= 60 then
		Log(s, bot, 'think', string.format('llamadas=%d por_s=%.1f ms_media=%.3f ms_max=%.2f', s.thinkN,
			s.thinkN / (t - s.thinkSince), s.thinkCost / s.thinkN, s.thinkMax))
		s.thinkSince, s.thinkN, s.thinkCost, s.thinkMax = t, 0, 0, 0
	end
end

function L.Think()
	local bot = GetBot()
	local started = RealTime()
	local s = State(bot)
	Registro.Tick(bot)
	if not bot:IsAlive() then
		-- Dead time counts too, so the calls per second compare with the other bots' (the smoke read 25 against 30).
		s.pending, s.retreating, s.toFountain = nil, false, false
		Cost(bot, s, DotaTime(), (RealTime() - started) * 1000)
		return
	end
	local p = Perceive(bot)
	CheckPending(bot, s, p)
	WatchAutoAttack(bot, s, p)
	LevelUp(bot, s)
	if p.now >= s.busyUntil then
		local d = Decide(bot, s, p)
		-- Logged when the intent or the kind of reason changes (its first word), not each time a number in it moves.
		local kind = string.match(d.reason, '^(%S+)') or ''
		if (d.intent ~= s.intent or kind ~= s.reasonKind) and d.intent ~= 'ultimo_golpe' and d.intent ~= 'denegar' then
			Log(s, bot, 'decision', string.format('intencion=%s motivo=%s', d.intent, d.reason))
		end
		s.intent, s.reason, s.reasonKind = d.intent, d.reason, kind
		Act(bot, s, p, d)
	end
	Status(bot, s, p)
	Cost(bot, s, p.t, (RealTime() - started) * 1000)
end

-- If Think fails, log it and walk to safety, so a bug shows in the log instead of a frozen hero.
local lastError = {} -- message -> game time it was last printed (at most once per 5 s each)
function L.OnError(err)
	local bot = GetBot()
	local msg = tostring(err)
	if DotaTime() - (lastError[msg] or -1000) >= 5 then
		lastError[msg] = DotaTime()
		out(string.format('[bench] prop error t=%.1f pid=%d %s', DotaTime(), bot:GetPlayerID(), msg))
	end
	pcall(function() bot:Action_MoveToLocation((SafeSpot(GetTeam()))) end)
end

return L
