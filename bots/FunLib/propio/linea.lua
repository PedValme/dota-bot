-- dota-bot's own bot, full-control test (trabajo/prueba-control.md): one hero playing its lane with nothing of Valve's
-- or OHA's decision code. Each tick: perceive (a snapshot), decide (ordered rules, each with its reason), act (an order
-- only when the intent changes, never cutting an attack's wind-up), log ("[bench] prop ..." lines).
-- What it does: walks to its lane behind its own creeps, predicts each creep's health when its own attack would land
-- (attacks in flight, the next hits of the units attacking it) and hits once at the right moment, denies, retreats on
-- low health, tower aggro or the damage of enemies that can reach it, uses salve and tango and levels up by its own
-- build. Phase 1 (trabajo/bot-propio.md, signed 2026-11-03) adds: its item build bought by parts with the courier
-- (compras.lua), the hero's abilities to harass and finish (sniper.lua), right-clicking the enemy laner when the trade
-- favours it, and kills, chases and runes (combate.lua). Rotations are off (DECISIONES 2026-11-04).
-- Only the Bot API listed in docs/api/volcado.md. The team's VM is shared with OHA, whose FunLib/aba_global_overrides
-- wraps a few calls (GetHealth, GetLocation, GetNearby*...): for visible units they answer as Valve's.
local L = {}

local out = BenchRawPrint or print
local Registro = require(GetScriptDirectory()..'/FunLib/propio/registro_linea')
local Compras = require(GetScriptDirectory()..'/FunLib/propio/compras')
local Combate = require(GetScriptDirectory()..'/FunLib/propio/combate')
local Intercambio = require(GetScriptDirectory()..'/FunLib/propio/intercambio')
local Medio = require(GetScriptDirectory()..'/FunLib/propio/medio')
-- The lane of two as one unit (positions 1+5 and 3+4 while the lane lasts): entries, leaving together and the support's spot.
local Dos = require(GetScriptDirectory()..'/FunLib/propio/dos')
-- Per-hero ability rules (Finish, Harass...) and data (heroes.lua); a hero without a module plays the lane without abilities.
local Heroes = require(GetScriptDirectory()..'/FunLib/propio/heroes')
local HEROES = Heroes.MODULES
-- Benchmark variant "sin_combate": no kills, abilities on heroes or trades, to measure what the fighting costs in farm.
local Variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
-- Observer mode: the lane of two's shadow line (dos.lua, Sombra), the same one OHA's bots log, to read both with one vara.
local OBSERVE = dofile(GetScriptDirectory()..'/FunLib/bench_observe')
local NO_COMBAT = Variant.sin_combate == true
-- Package 4 (signed by Pedro on 2026-11-14): the pair follows its openings, presses 2 against 2, no tango in a fight, Magic Wand.
local P4 = Variant.paquete4 == true
local Pareja = require(GetScriptDirectory()..'/FunLib/propio/pareja')

-- Thresholds of the rules (one place, so the log and the rules agree).
local K = {
	retreatHp = 0.30,     -- retreat below this health fraction
	coreNear = 1500,
	holdOutMax = 8,       -- seconds a hero may wait out of reach of two enemies before going back (an assumption, not measured)
	holdStep = 80,        -- the step when already out of their reach      -- a support leaves the last hits to a core ally this close
	exposedHp = 0.45,     -- ...or below this one with an enemy hero able to reach us
	learnFade = 0.9954,   -- per second, what is learned of an enemy's damage fades by this: half in 150 s
	returnHp = 0.65,      -- come back to the lane above it
	fountainHp = 0.20,    -- below it, without a salve, go heal at the fountain
	enemyBurst = 0.80,    -- retreat if the visible enemy heroes can deal this share of our health in 3 s
	holdBack = 350,       -- stand this far behind our creeps' front, toward home
	towerMargin = 820,    -- keep this far from an enemy tower when it is not busy with creeps (range 700)
	windUp = 0.15,        -- extra seconds an attack order is protected after its attack point
	lookAhead = 2.0,      -- seconds ahead a creep is watched to stand ready for it
	moveRefresh = 1.0,    -- re-issue a move order at most this often unless the target moved
	burstHold = 2.0,      -- once in danger, stay away this long after the danger is gone (no back and forth)
	ttdRetreat = 6.0,     -- retreat when, at the health lost over the last 2 s, we would die within this many seconds
	                      -- (fase1c smoke: two deaths standing in lane losing health for 6-8 s with no single burst)
	aggroStep = 350,      -- step back this far to drop the aggro of enemy creeps hitting us
	reachMargin = 150,    -- an enemy hero counts as dangerous within its reach plus this, plus half a second walking
	reachCap = 1200,      -- cast ranges above this (global ultimates) count as this
	tradeHp = 0.35,       -- no trade below this health
	tradeEvery = 0.2,     -- seconds between two right-clicks on a hero: the attack's own cooldown sets the pace. With 1 s, the
	                      -- gap sent it walking between shots: 2,1 attacks per fighting window against OHA's 4,4 (presion6)
	-- How far beyond our range a hit is answered is by reach now (heroes.lua, R.ALCANCE: 200 for a ranged hero, as it was).
	pressEdge = 1.2,      -- step forward and hit, with nothing else to do, if the trade (intercambio.lua: his time to kill
	                      -- us over ours) reaches this
	pressReach = 300,     -- how far beyond our range we walk to press him
	freeShotGap = 250,    -- a free shot, alone, from at least this much beyond its attack range
	freeShotHp = 0.5,
	-- When hit there is no third way: step away if the trade is below loseEdge and we are under loseHp, else hit back.
	-- With a gap between both it stood there taking hits (fase1j: 10 of 23 harassed windows with no answer, ratio 0,5-0,8).
	loseEdge = 0.7,
	loseHp = 0.8,
	loseEdgeFull = 0.5,   -- ...at or above loseHp, only this far below: a nuke at level 1 reads 0,5-0,8 (fase1j), and it must not leave the lane for that
	healNear = 900,       -- no salve with an enemy hero this close, or within its attack range plus healMargin (it was 1500)
	healMargin = 300,
	treeSafe = 800,       -- how far a tree is worth walking to with no enemy near (OHA's distance)...
	treeNear = 350,       -- ...and with one near
	treeTower = 920,      -- no tree this close to an enemy tower
	runePick = 80,        -- from this close, the order to pick up the rune: from afar it leaves the hero idle
	runeTry = 3.0,        -- seconds of trying before giving up on a rune...
	runeBan = 60,         -- ...and seconds before trying that one again
	tpFrom = 3500,        -- this far from the lane's front, go back by teleport
	tpRisk = 2,           -- no teleport to a tower with this risk (medio.lua)
	lateHomeHp = 0.45,    -- once the lane is over and with no salve, home below this health
	recoverWait = 15,     -- seconds of regeneration worth waiting for at a tower, without going home
	-- Package 1, surviving the lane of two (trabajo/plan-mejora-equipo.md). Role and reach parameters are in heroes.lua (R.ROL, R.ALCANCE).
	allyNear = 1200,      -- allied heroes this close count in the trade, as the enemy's partner does (intercambio.lua's othersNear)
	aloneEnemy = 1200,    -- outnumbered: more enemy heroes this close than our heroes, ourselves included, within aloneAlly
	aloneAlly = 800,
	clarityMana = 0.4,    -- a clarity under this share of mana, safe and away from the fountain: OHA's numbers
	clarityFountain = 2000, -- (ability_item_usage_generic, item_clarity)
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

-- The lane of each position (trabajo/fase2.md): 1 and 5 the safe one, 2 mid, 3 and 4 the hard one. Radiant's safe lane is bottom.
local function StartLane(bot)
	local pos = Heroes.Datos(bot:GetUnitName()).pos or 2
	if pos == 2 then return LANE_MID end
	local safe = GetTeam() == TEAM_RADIANT and LANE_BOT or LANE_TOP
	local hard = GetTeam() == TEAM_RADIANT and LANE_TOP or LANE_BOT
	return (pos == 1 or pos == 5) and safe or hard
end

local function State(bot)
	local pid = bot:GetPlayerID()
	if S[pid] == nil then
		S[pid] = { intent = 'ninguna', reason = '', nextSkill = 1, bought = false, busyUntil = -1, lastMoveAt = -1,
			moveTo = nil, pending = nil, lastStatus = -1000, thinkN = 0, thinkCost = 0, thinkMax = 0, thinkSince = nil,
			retreating = false, lane = StartLane(bot) }
	end
	return S[pid]
end

local function Home(team) return GetAncient(team):GetLocation() end
local function Fountain(team) return GetShopLocation(team, SHOP_HOME) end

-- The towers of a lane, from the front back.
local function LaneTowers(lane)
	if lane == LANE_TOP then return { TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3 } end
	if lane == LANE_BOT then return { TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3 } end
	return { TOWER_MID_1, TOWER_MID_2, TOWER_MID_3 }
end

-- Where to stand safe: behind the first standing tower of the lane we play, else the ancient.
local function SafeSpot(team, lane)
	for _, t in ipairs(LaneTowers(lane or LANE_MID)) do
		local tower = GetTower(team, t)
		if Valid(tower) then return Toward(tower:GetLocation(), Home(team), 250), 'torre_' .. t end
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
	local p0 = bot:GetLocation()
	local p = {
		hero = HEROES[bot:GetUnitName()],
		team = team, now = GameTime(), t = DotaTime(), loc = bot:GetLocation(),
		hp = bot:GetHealth() / math.max(bot:GetMaxHealth(), 1), hpAbs = bot:GetHealth(),
		range = bot:GetAttackRange(), point = bot:GetAttackPoint(), projSpeed = bot:GetAttackProjectileSpeed(),
		moveSpeed = bot:GetCurrentMovementSpeed(),
		dmgMin = bot:GetAttackDamage() - bot:GetBaseDamageVariance(),
		enemyCreeps = bot:GetNearbyLaneCreeps(1500, true) or {},
		allyCreeps = bot:GetNearbyLaneCreeps(1500, false) or {},
		enemyHeroes = Intercambio.OnePerHero(p0, bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE) or {}),
		enemyTowers = bot:GetNearbyTowers(1500, true) or {},
		allyTowers = bot:GetNearbyTowers(1500, false) or {},
		front = GetLaneFrontLocation(team, State(bot).lane or LANE_MID, 0),
	}
	-- Damage the visible enemy heroes can deal to us in 3 s (intercambio.lua: their hits and ready abilities), counted
	-- only for those that can reach us: within their attack range or the cast range of a ready ability, plus a margin
	-- and half a second walking. The smoke of 2026-11-03 retreated from an enemy far out of reach (MEDICIONES).
	p.enemyBurst, p.enemyBurstAll = 0, 0
	-- reachNeed: how far we still are inside the reach of the visible enemy heroes (attack, and abilities ready now or within
	-- burstHold, when we would be back), the worst of them; 0 or less when out of all of them. A step back of 350 left Lion inside
	-- Cask and Maledict, losing 0,81 to 0,49 of health with no enemy reading as in reach (fase2-humo-equipo 1, t=280-286).
	p.reachNeed = -1e9
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) then
			-- At least what this enemy has really done to us per second, learned below.
			local learned = (State(bot).enemyDps or {})[e:GetUnitName()] or 0
			local dmg = math.max(Intercambio.Threat(e, bot, 3.0), learned * 3)
			p.enemyBurstAll = p.enemyBurstAll + dmg
			local reach, reachSoon = e:GetAttackRange(), e:GetAttackRange()
			for slot = 0, 5 do
				local ab = e:GetAbilityInSlot(slot)
				if ab ~= nil and not ab:IsPassive() then
					-- Guarded: a nil from an enemy's ability would stop Think, and the hero with it.
					local range = math.min(ab:GetCastRange() or 0, K.reachCap)
					if ab:IsFullyCastable() then reach = math.max(reach, range) end
					if ab:IsFullyCastable() or ((ab:GetLevel() or 0) > 0 and (ab:GetCooldownTimeRemaining() or 1e9) <= K.burstHold) then
						reachSoon = math.max(reachSoon, range)
					end
				end
			end
			local walk = K.reachMargin + 0.5 * e:GetCurrentMovementSpeed()
			local d = D2(p.loc, e:GetLocation())
			if d <= reach + walk then p.enemyBurst = p.enemyBurst + dmg end
			p.reachNeed = math.max(p.reachNeed, reachSoon + walk - d)
		end
	end
	-- Two enemy heroes in sight: the new holds of the retreat apply only then, so the Sniper's 1 against 1 in mid is unchanged.
	p.pair = #p.enemyHeroes >= 2
	-- The allied heroes near, one per hero (no illusions), and none retreating: one leaving is no company (its state is in S,
	-- shared by our bots in the team's VM). For the trade (intercambio.lua) and for being outnumbered.
	-- allyActive: the same at any distance, for the pair's kill (combate.lua, package 2), which looks for them near the target.
	p.allyHeroes, p.allyActive = {}, {}
	local nAlly = 1
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() then
			local st = S[a:GetPlayerID()]
			if st == nil or not st.retreating then
				table.insert(p.allyActive, a)
				if D2(p0, a:GetLocation()) < K.allyNear then
					table.insert(p.allyHeroes, a)
					if D2(p0, a:GetLocation()) < K.aloneAlly then nAlly = nAlly + 1 end
				end
			end
		end
	end
	-- The lane's rules or the middle game's (medio.lua, Late), as last decided: combate.lua counts the pair only in the lane.
	p.late = State(bot).late == true
	-- Outnumbered in the lane: more enemy heroes near than ours, ourselves included. Then no attack or harass spell on a hero and no
	-- kill starts, only a sure kill (Finish): 8 of 16 deaths in the safe lane came some 2 s after an attack of our own, alone, with
	-- the second enemy near (plan, package 1). Once the lane is over, medio.lua has its own count (Outnumbered, Allies).
	local nEnemy = 0
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p0, e:GetLocation()) < K.aloneEnemy then nEnemy = nEnemy + 1 end
	end
	p.nEnemyNear, p.nAllyNear = nEnemy, nAlly
	p.alone = not State(bot).late and nEnemy > nAlly
	-- Health lost per second over the last 2 s (samples every 0.5 s), and the enemy creeps hitting us now.
	local s = State(bot)
	s.hpHist = s.hpHist or {}
	if #s.hpHist == 0 or p.now - s.hpHist[#s.hpHist].t >= 0.5 then
		table.insert(s.hpHist, { t = p.now, hp = p.hpAbs })
		while #s.hpHist > 0 and p.now - s.hpHist[1].t > 2.0 do table.remove(s.hpHist, 1) end
	end
	local oldest = s.hpHist[1]
	p.dps = (oldest ~= nil and p.now - oldest.t >= 1.0) and math.max(0, (oldest.hp - p.hpAbs) / (p.now - oldest.t)) or 0
	-- How hard each enemy hits, learned from the health lost with only that one near. It fades slowly (half in 150 s): levels and items change.
	s.enemyDps = s.enemyDps or {}
	local since = p.now - (s.enemyDpsAt or p.now)
	s.enemyDpsAt = p.now
	for name, v in pairs(s.enemyDps) do s.enemyDps[name] = v * K.learnFade ^ since end
	if #p.enemyHeroes == 1 and p.dps > 0 and bot:WasRecentlyDamagedByAnyHero(1.0) and Valid(p.enemyHeroes[1]) then
		local name = p.enemyHeroes[1]:GetUnitName()
		if p.dps > (s.enemyDps[name] or 0) then s.enemyDps[name] = p.dps end
	end
	p.enemyDps = s.enemyDps
	p.heroOnMe = bot:WasRecentlyDamagedByAnyHero(2.0) == true
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p.loc, e:GetLocation()) < 600 then p.heroOnMe = true end
	end
	p.creepsOnMe = 0
	for _, c in ipairs(p.enemyCreeps) do
		if Valid(c) and c:GetAttackTarget() == bot then p.creepsOnMe = p.creepsOnMe + 1 end
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
	local danger = false -- the reason is the enemy heroes' damage: with two of them in sight, the holds below start
	-- A pair's kill under way that the numbers still give (combate.lua, C.Committed): the soft reasons below (marked Soft) yield to it
	-- unless we would die first (C.DiesFirst). They ended 51 of 129 lane chases whose score was a kill (package 2 round 2). The hard
	-- ones (tower, health under retreatHp, the sustained damage measured on us, a retreat already held) are untouched: the sustained
	-- damage is health really being lost, creeps and damage over time included, which no reading of the enemies sees (review of round
	-- 2). What was yielded is logged once a second.
	local committed = not NO_COMBAT and not Combate.DiesFirst(p) and Combate.Committed(bot, s, p)
	local held = nil
	local function Soft(name)
		-- In a lane of two (dos.lua) the pair leaves together, before the hits: one hero's soft retreat would split it.
		if p.dos then return false end
		if committed then held = held or name return false end
		return true
	end
	if p.towerOnMe then reason = 'torre_me_ataca'
	elseif p.hp < K.retreatHp then
		reason = string.format('vida %.2f < %.2f', p.hp, K.retreatHp)
		s.lowHp = true
	-- The burst alone was a false alarm (fase1d: 108 s fleeing with over 60 % health, every 4 s). It counts only if a hero
	-- is really on us: it hit us in the last 2 s, or stands within 600.
	elseif p.enemyBurst > K.enemyBurst * p.hpAbs and p.heroOnMe and Soft('daño_enemigo_3s') then
		reason = string.format('daño_enemigo_3s %d > %.0f%% de %d', p.enemyBurst, K.enemyBurst * 100, p.hpAbs)
		s.burstUntil = p.now + K.burstHold
		danger = true
	elseif p.dps > 0 and p.hpAbs / p.dps < K.ttdRetreat then
		reason = string.format('daño_sostenido %.0f/s, muerto en %.1fs', p.dps, p.hpAbs / p.dps)
		s.burstUntil = p.now + K.burstHold
		danger = bot:WasRecentlyDamagedByAnyHero(2.0)
	elseif p.now < (s.burstUntil or -1000) then
		reason = string.format('peligro_reciente %.1fs', s.burstUntil - p.now)
	-- Only a retreat for low health waits to recover up to returnHp; one for danger ends when the danger does.
	elseif s.lowHp and p.hp < K.returnHp then reason = string.format('recuperando %.2f < %.2f', p.hp, K.returnHp)
	-- Once the lane is over, with no salves and under this health it neither farms (Neutrals) nor helps anyone: home.
	elseif s.late and p.hp < K.lateHomeHp and HasItem(bot, 'item_flask') == nil then
		reason = string.format('vida %.2f < %.2f sin salvia', p.hp, K.lateHomeHp)
		s.lowHp = true
	-- Touched, and an enemy that can reach us: out now, before its next spell decides it (presion4: three deaths in lane to Lina,
	-- from 0,3-0,5 of health; Pedro, 2026-11-05: «asume mas daño [d]el necesario antes de escapar»).
	elseif p.hp < K.exposedHp and p.enemyBurst > 0 and Soft('expuesto') then
		reason = string.format('expuesto %.2f < %.2f', p.hp, K.exposedHp)
		s.burstUntil = p.now + K.burstHold
		danger = true
	-- Once the lane is over, more enemies than friends on us is reason enough, before any damage.
	elseif s.late and Medio.Outnumbered(bot, p) ~= nil then
		reason = Medio.Outnumbered(bot, p)
		s.burstUntil = p.now + K.burstHold
	-- A trade we are losing: a step out, early and short, not the whole way to the tower: the farm is still there
	-- (Pedro, 2026-11-05: «asume mas daño [d]el necesario antes de escapar»).
	-- At full health too, if it is lost by far: on top of it with ratio 0,22-0,48 and a full bar it went on hitting back, and died in some
	-- 8 s (lobby 2026-11-05, t=1451, 1981, 2094).
	elseif not p.dos and bot:WasRecentlyDamagedByAnyHero(2.0) then
		local edge = p.hp < K.loseHp and K.loseEdge or K.loseEdgeFull
		for _, e in ipairs(p.enemyHeroes) do
			if Valid(e) and D2(p.loc, e:GetLocation()) <= e:GetAttackRange() + 200 then
				local trade = Intercambio.Eval(bot, p, e)
				-- Against the target itself a lost trade still counts: the kill is not going our way. Against the other enemy it is the
				-- price of the kill (17 of the 51 cut chases, all of them against the enemy that was not the target).
				local onTarget = s.chase ~= nil and Valid(s.chase.target) and s.chase.target:GetUnitName() == e:GetUnitName()
				if trade.ratio < edge and (onTarget or Soft('intercambio_perdido')) then
					reason = string.format('intercambio_perdido %.2f < %.2f frente a %s', trade.ratio, edge,
						(string.gsub(e:GetUnitName(), 'npc_dota_hero_', '')))
					s.burstUntil, s.stepBack = p.now + K.burstHold, true
					danger = true
					break
				end
			end
		end
	end
	if held ~= nil and reason == nil and p.now - (s.heldLogAt or -1000) >= 1 then
		s.heldLogAt = p.now
		Log(s, bot, 'pareja', string.format('sigo_en_la_kill objetivo=%s ignoro=%s daño3s=%d vida=%d vida_frac=%.2f', s.chase.name, held,
			p.enemyBurst, p.hpAbs, p.hp))
	end
	-- Holds of a retreat from two enemy heroes (package 1). It went back to the lane as soon as burstHold ran out, at 0,38-0,42 of
	-- health, and died: Luna and Lich, t=479-496 of fase2-humo-equipo 1, four 'expuesto' and 'linea' in a row each. With only one
	-- enemy in sight they do not start, so the lone mid keeps its rules; once the lane is over neither (medio.lua retreats by its
	-- own count, and the middle game is package 4).
	if p.dos then s.holdOut, s.holdHp = false, false end
	if danger and p.pair and not s.late and not p.dos then
		if not s.holdOut then s.holdOutAt = p.now end
		s.holdOut = true
		-- Not lowHp: that kept 'recuperando' firing and, with stepBack left from a lost trade, walked it across the map in steps of 350
		-- (Luna, p1-prueba-a-1, t=276-300); 0 'recuperando_ante_dos' in 6 matches. waitLong below reads holdHp instead.
		if p.hp < K.returnHp then s.holdHp = true end
	end
	-- The health hold lasts while both are in sight; with them gone it is a normal lane again.
	if not p.pair then s.holdHp = false end
	-- The holds are the lane's: in the middle game Medio.Fight must not be blocked by one left from the lane (review of 2026-11-13).
	if s.late then s.holdOut, s.holdHp = false, false end
	-- A salve at work ends the health hold: it heals the rest on the way (the plan: «no vuelve hasta 0,65 de vida o tras usar salvia»).
	if p.hp >= K.returnHp or bot:HasModifier('modifier_flask_healing') then s.holdHp = false end
	if reason == nil and s.holdHp then
		reason = string.format('recuperando_ante_dos %.2f < %.2f', p.hp, K.returnHp)
	end
	local outOnly = false -- held only to stay out of their reach: a step out, not the walk to the tower
	if reason == nil and s.holdOut then
		outOnly = true
		-- Hero damage still landing with no visible enemy able to reach us: a damage over time (Maledict, poison) or one in the fog.
		-- Lion went back with Maledict on and lost 0,81 to 0,49 with 'daño3s=0' (fase2-humo-equipo 1, t=280-286).
		if p.enemyBurst == 0 and bot:WasRecentlyDamagedByAnyHero(1.0) then
			reason = 'daño_en_el_tiempo'
		-- Walking back in, all of them could still take this share of our health in 3 s: wait out of reach.
		-- Capped in time: the burst of all visible enemies counts them at any distance, and with two nukers in lane it exceeded the
		-- share even at full health, which held the hero out for as long as they stayed (review of 2026-11-13).
		elseif p.enemyBurstAll > K.enemyBurst * p.hpAbs and p.now - (s.holdOutAt or p.now) < K.holdOutMax then
			reason = string.format('rafaga_si_vuelvo %d > %.0f%% de %d', p.enemyBurstAll, K.enemyBurst * 100, p.hpAbs)
		else
			s.holdOut = false
		end
	end
	if p.hp >= K.returnHp then s.lowHp = false end
	s.retreating = reason ~= nil
	if reason == nil then s.toFountain, s.stepBack, s.retreatTower = false, false, nil return nil end
	-- A retreat to recover health is not a step out of reach: it goes by the tower, the fountain or the teleport below (p1-prueba).
	if reason ~= nil and string.find(reason, '^recuperando') then s.stepBack = false end
	if (s.stepBack or outOnly) and not p.towerOnMe and p.hp >= K.retreatHp then
		-- With two enemies in sight, the step goes out of all of their reach (reachNeed), not 350: else Cask and Maledict still
		-- reached it. Already out, it stays where it is (no order). With one, the 350 as before.
		if p.pair or outOnly then
			-- Already out of reach, a short step: with no order the previous one went on, or the engine auto-attacked.
			local to = Toward(p.loc, Home(p.team), p.reachNeed > 0 and math.max(K.aggroStep, p.reachNeed) or K.holdStep)
			return { intent = 'alejarse', reason = reason .. string.format(', fuera de alcance %d', math.min(-p.reachNeed, 9999)), to = to }
		end
		return { intent = 'alejarse', reason = reason, to = Toward(p.loc, Home(p.team), K.aggroStep) }
	end
	-- Once heading for the fountain it keeps going until healed (returnHp), not back and forth with the tower.
	-- Waiting long for its regeneration, with no salve and a teleport to come back, it goes home instead of standing there
	-- (lobby 2026-11-05: 20 s still at a tower with 0,27 of health).
	local waitLong = (s.lowHp or s.holdHp) and HasItem(bot, 'item_flask') == nil and bot:FindItemSlot('item_tpscroll') == 15
		and bot:GetItemInSlot(15):IsFullyCastable()
		and (K.returnHp - p.hp) * bot:GetMaxHealth() / math.max(bot:GetHealthRegen(), 0.1) > K.recoverWait
	-- Once the lane is over nothing heals it at a tower (2.000 of health at 5 a second): any retreat for health ends at home.
	if s.toFountain or waitLong or ((p.hp < K.fountainHp or (s.late and s.lowHp)) and HasItem(bot, 'item_flask') == nil) then
		s.toFountain = true
		-- Home by teleport during the lane, as OHA does (all 19 of its trips home in oha-dos-*, against 0 of 39 for ours, walking):
		-- far from the fountain, the scroll ready, and no enemy hero near or hitting us, since the channel is cut.
		if not s.late and D2(p.loc, Fountain(p.team)) > 4000 and p.now - (s.tpAt or -1000) >= 5 and #p.enemyHeroes == 0
			and not bot:WasRecentlyDamagedByAnyHero(2.0) then
			local slot = bot:FindItemSlot('item_tpscroll')
			local item = (slot >= 0 and (slot <= 5 or slot == 15)) and bot:GetItemInSlot(slot) or nil
			if item ~= nil and item:IsFullyCastable() then
				s.tpAt = p.now
				return { intent = 'teleporte', item = item, at = Fountain(p.team), reason = reason .. ', a la fuente' }
			end
		end
		return { intent = 'retirada_fuente', reason = reason .. ', sin salvia', to = Fountain(p.team) }
	end
	if p.towerOnMe then
		return { intent = 'salir_de_torre', reason = reason, to = Toward(p.loc, Home(p.team), 500) }
	end
	local spot, name = SafeSpot(p.team, s.lane)
	if s.late then
		local tower = Medio.RetreatTower(bot, s, p)
		if tower ~= nil then spot, name = Toward(tower:GetLocation(), Home(p.team), 250), 'torre_cercana'
		else spot, name = Fountain(p.team), 'fuente' end
	end
	return { intent = 'retirada', reason = reason .. ' -> ' .. name, to = spot }
end

local function RuleHeal(bot, s, p)
	local heroNear = false
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p.loc, e:GetLocation()) < math.max(K.healNear, e:GetAttackRange() + K.healMargin) then heroNear = true end
	end
	local safe = not heroNear and not bot:WasRecentlyDamagedByAnyHero(2.0) and not bot:WasRecentlyDamagedByTower(2.0)
	-- A clarity (a support's, heroes.lua R.ROL) under the salve's safety, which hero damage also breaks: Lich spent 17-22 % of the lane
	-- under 0,3 of mana (fase2-humo-equipo 1 and 2). Also while a salve or tango heals: they do not stack on the same thing.
	local clarity = HasItem(bot, 'item_clarity')
	if clarity ~= nil and clarity:IsFullyCastable() and safe and not bot:HasModifier('modifier_clarity_potion')
		and bot:GetMana() < K.clarityMana * bot:GetMaxMana() and bot:DistanceFromFountain() > K.clarityFountain then
		return { intent = 'clarity', reason = string.format('maná %.2f, sin enemigos cerca', bot:GetMana() / math.max(bot:GetMaxMana(), 1)),
			item = clarity }
	end
	if bot:HasModifier('modifier_flask_healing') or bot:HasModifier('modifier_tango_heal') then return nil end
	local salve = HasItem(bot, 'item_flask')
	if salve ~= nil and salve:IsFullyCastable() and p.hp < 0.55 and safe then
		return { intent = 'curar_salvia', reason = string.format('vida %.2f, sin enemigos cerca', p.hp), item = salve }
	end
	local tango = HasItem(bot, 'item_tango')
	-- Package 4: the tango under the salve's safety too: 15-20 deaths in h2 had a tango eaten with an enemy hero within 1000.
	if tango ~= nil and tango:IsFullyCastable() and bot:GetMaxHealth() - p.hpAbs > 120 and (safe or not P4) then
		-- Far trees only with nothing to farm and no enemy near (the walk leaves the wave), and the nearest one that
		-- is not under an enemy tower.
		local reach = (safe and not Combate.WaveInReach(p)) and K.treeSafe or K.treeNear
		local tree, treeD = nil, 1e9
		for _, t in ipairs(bot:GetNearbyTrees(reach) or {}) do
			local loc = GetTreeLocation(t)
			local d = D2(p.loc, loc)
			local underTower = false
			for _, tw in ipairs(p.enemyTowers) do
				if Valid(tw) and D2(loc, tw:GetLocation()) < K.treeTower then underTower = true end
			end
			if d < treeD and not underTower then tree, treeD = t, d end
		end
		if tree ~= nil then
			-- The nearest enemy hero this bot sees, and hero damage in the last 2 s: the analysis counted enemies from the omniscient
			-- record, not from what the bot saw (package 4, round 1 diagnosis).
			local nearD = 99999
			for _, e in ipairs(p.enemyHeroes) do
				if Valid(e) then nearD = math.min(nearD, D2(p.loc, e:GetLocation())) end
			end
			return { intent = 'curar_tango', reason = string.format('faltan %d de vida, árbol a %d, rival visible a %d, daño_heroe2s %s',
				bot:GetMaxHealth() - p.hpAbs, treeD, nearD, tostring(bot:WasRecentlyDamagedByAnyHero(2.0))),
				item = tango, tree = tree }
		end
	end
	return nil
end

-- Whether standing there means standing under an enemy tower that is not busy with something else: going in for a
-- creep took health from 0,94 to 0,20 in seven seconds (fase1 m3, t=45-52).
local function TowerBlocks(bot, p, spot)
	for _, tw in ipairs(p.enemyTowers) do
		if Valid(tw) and D2(spot, tw:GetLocation()) < K.towerMargin then
			local target = tw:GetAttackTarget()
			if not Valid(target) or target == bot then return true end
		end
	end
	return false
end

-- Where the hero would attack this creep from.
local function StandFor(p, c)
	if D2(p.loc, c:GetLocation()) <= p.range then return p.loc end
	return Toward(c:GetLocation(), p.loc, p.range)
end

-- Last hit (enemy creep) or deny (our creep under half health): the creep whose predicted health when our attack
-- lands is above 0 and within our damage. Also returns the creep to stand ready for, if one is about to be killable.
-- No deny when a last hit matures within our next attack: the deny would spend that attack.
local function RuleLastHit(bot, s, p)
	local best, ready, soon = nil, nil, false
	local spa = bot:GetSecondsPerAttack()
	local function consider(list, attackersFrom, deny)
		for _, c in ipairs(list) do
			if Valid(c) and (not deny or c:GetHealth() < 0.5 * c:GetMaxHealth()) and not TowerBlocks(bot, p, StandFor(p, c)) then
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
				elseif hpAt > 0 then
					if not deny and walk < 0.5 and PredictHealth(c, tLand + spa, attackers, p.now) <= dmg then soon = true end
					if ready == nil and PredictHealth(c, tLand + K.lookAhead, attackers, p.now) <= dmg then ready = c end
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
	-- A support leaves the last hits to a core ally beside it (trabajo/fase2.md, step 3), and still denies. A hero it does not know counts
	-- as a core.
	local leave = false
	if Heroes.Datos(bot:GetUnitName()).rol == 'apoyo' then
		for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
			if a ~= bot and Valid(a) and not a:IsIllusion() and Heroes.Datos(a:GetUnitName()).rol ~= 'apoyo'
				and D2(p.loc, a:GetLocation()) < K.coreNear then leave = true break end
		end
	end
	if not leave then consider(p.enemyCreeps, allies, false) end
	if best == nil and not soon then consider(p.allyCreeps, enemies, true) end
	if best ~= nil then
		local c = best.creep
		return { intent = best.deny and 'denegar' or 'ultimo_golpe', target = c, hit = best,
			reason = string.format('%s vida %d -> %.0f al llegar en %.2fs (proy=%d golpes=%d dlast=%.2f), mi daño %.0f',
				(string.gsub(c:GetUnitName(), 'npc_dota_', '')), c:GetHealth(), best.hpAt, best.tLand, best.nProj,
				best.nHits, best.dLast, best.dmg) }
	end
	return nil, ready, soon
end

-- Where to stand in lane: behind our creeps' front, by holdBack or, for a long range, by range − 200 (at range − 100
-- it made fewer last-hit attempts, fase1d: 41-56 against 62-72), out of an idle enemy tower's reach.
local function LanePoint(p)
	local spot = Toward(p.front, Home(p.team), math.max(K.holdBack, p.range - 200))
	for _, tw in ipairs(p.enemyTowers) do
		if Valid(tw) and D2(spot, tw:GetLocation()) < K.towerMargin then
			spot = Toward(tw:GetLocation(), spot, K.towerMargin)
		end
	end
	return spot
end

-- Hit the enemy laner when the numbers favour us (intercambio.lua), in two ways. Answer: it hit us, it is in range and
-- we win the trade (44 % of harassed windows got no answer against OHA's 17 %). Press: nothing to farm right now and we
-- win it clearly: walk in and hit, to make it back off (its farm: 15,3 last hits against 10,8 with OHA). No last hit
-- about to mature is given up for it, and no enemy tower is walked under.
local function RuleTrade(bot, s, p, ready, soon)
	-- A last hit about to mature keeps the attack, also when hit: answering anyway lowered the unanswered to 17 % but lost the lane
	-- (fijo-p3: 5,8 deaths from minute 5 on, rival 39,8 last hits; fijo-p2: 1,3 and 27,5).
	if soon or p.now - (s.tradeAt or -1000) < K.tradeEvery or p.hp < K.tradeHp then return nil end
	for _, tw in ipairs(p.enemyTowers) do
		if Valid(tw) and D2(p.loc, tw:GetLocation()) < K.towerMargin + 50 then return nil end
	end
	local hit = bot:WasRecentlyDamagedByAnyHero(2.0)
	local alone = #p.enemyHeroes == 1 -- one enemy hero in sight
	-- Two against two in the lane (package 2): a partner near, not retreating (Perceive's p.allyHeroes), and no more enemy heroes in
	-- sight than the two of us. The trade already counts the partner's hits as it counts his partner's (intercambio.lua), so pressing
	-- asks the same edge. Pressing needed one enemy in sight, and the lanes of two never pressed: a rival with its partner in sight
	-- was never pushed off its farm (trabajo/plan-mejora-equipo.md, «Presionar en 2 contra 2 cuando la suma de las parejas lo da»).
	local pair = not s.late and #p.allyHeroes >= 1 and #p.enemyHeroes <= #p.allyHeroes + 1
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and not e:IsIllusion() and not e:IsAttackImmune() then
			local d = D2(p.loc, e:GetLocation())
			local inRange = d <= p.range + 50
			if d <= p.range + K.pressReach and (inRange or not TowerBlocks(bot, p, Toward(e:GetLocation(), p.loc, p.range))) then
				local v = Intercambio.Eval(bot, p, e)
				local kind = nil
				-- Once the lane is over, alone: no pressing, and hitting back only from out of its reach.
				local company = not s.late or Medio.Allies(bot) > 0
				-- How far beyond our range we answer, by reach (heroes.lua, R.ALCANCE): a melee hero only from its own.
				local answerFrom = select(2, Heroes.Rol(bot)).contestaDesde
				local answer = d <= p.range + answerFrom and hit and (v.ratio >= (p.hp < K.loseHp and K.loseEdge or K.loseEdgeFull) or (v.outranged and alone))
					and (company or (v.outranged and alone))
				-- Outnumbered in the lane (Perceive, p.alone), no answer and no press: the rival's partner kills us in the next 2 s
				-- (plan, package 1: 8 of 16 deaths in the safe lane). Said once a second, so the log shows what was given up.
				-- In a lane of two (dos.lua) the pair alone takes the initiative: Luna pressed Bristleback by its own trade (ratio 1,79),
				-- got both enemies' answer and the pair left too late (dos-humo 2, t=453-461).
				-- Package 4: pressing again in the lane of two, with the partner near and the board on the lane: the hard lane hit 15 times
				-- less with attacks than OHA's from minute 0 (h2: Dragon Knight 186 against 2.758). The partner joins it (dos.lua).
				local pairPress = P4 and p.dos ~= nil and p.dos.partnerNear and p.dos.board.mode == 'linea'
				local press = (not p.dos or pairPress) and company and (alone or pair) and ready == nil and v.ratio >= K.pressEdge
				if (answer or press) and p.alone then
					if p.now - (s.aloneLogAt or -1000) >= 1 then
						s.aloneLogAt = p.now
						Log(s, bot, 'superado', string.format('%s a %s descartado: %d enemigos a %d, %d de los nuestros a %d, ratio %.2f',
							answer and 'contesto' or 'presiono', (string.gsub(e:GetUnitName(), 'npc_dota_hero_', '')), p.nEnemyNear, K.aloneEnemy,
							p.nAllyNear, K.aloneAlly, v.ratio))
					end
				elseif answer then kind = 'contesto'
				-- Against two without a partner, neither: pressing with a second enemy in sight gave 3 deaths in 15 cases, and answering 7
				-- in 32 (equipo1-2). With the partner near (pair), the press is the pair's, named apart so the log tells them.
				elseif press then kind = alone and 'presiono' or 'presiono_2c2'
				-- Alone, a free shot: in our range and well out of its reach, nobody else near, winning the trade. It is what the
				-- range is for, and it stood there instead (presion3: 66 of 74 such seconds without firing).
				elseif not company and ready == nil and d <= p.range and d >= e:GetAttackRange() + K.freeShotGap
					and #p.enemyHeroes == 1 and v.ratio >= K.pressEdge and p.hp >= K.freeShotHp then kind = 'disparo' end
				if kind ~= nil then
					-- At most once a second per target: RuleTrade runs every 0,2 s, and each call made a new id and log line (review of
					-- package 4).
					local ename = string.gsub(e:GetUnitName(), 'npc_dota_hero_', '')
					if P4 and p.dos ~= nil and string.find(kind, '^presiono')
						and (p.now - (s.pressAnnAt or -1000) >= 1 or s.pressAnnName ~= ename) then
						s.pressAnnAt, s.pressAnnName = p.now, ename
						Pareja.Announce(bot, e, 'apertura', p.now + 3, p.now, kind)
					end
					return { intent = 'acosar', target = e, walk = math.max(0, d - p.range) / math.max(p.moveSpeed, 1),
						reason = string.format('%s a %s: ratio %.2f, mi_dps %d, su_dps %d, altura %d, a %d, aliados %d', kind,
							(string.gsub(e:GetUnitName(), 'npc_dota_hero_', '')), v.ratio, v.mine, v.against, v.height, d, v.allies) }
				end
			end
		end
	end
	return nil
end

-- Back to the lane by teleport after the fountain or a death: walking cost the time OHA spends farming (4-19 TP a match
-- against 0). To the first standing tower of the lane we play, only from far enough and with no enemy near.
local function RuleTeleport(bot, s, p)
	if p.t < 0 or #p.enemyHeroes > 0 or D2(p.loc, p.front) < K.tpFrom then return nil end
	-- Farming a camp it is where it wants to be: the scroll stays for the next fight.
	if s.intent == 'a_neutrales' or s.intent == 'farmear' then return nil end
	-- With a team to be with, the scroll is not for going back to the lane: it left them at once (equipo1-c, t=914).
	if s.late and s.teamSpot ~= nil then return nil end
	if p.now - (s.tpAt or -1000) < 5 then return nil end -- an order the engine took and did nothing with is not repeated
	local slot = bot:FindItemSlot('item_tpscroll')
	if slot < 0 or (slot > 5 and slot ~= 15) then return nil end
	local item = bot:GetItemInSlot(slot)
	if item == nil or not item:IsFullyCastable() then return nil end
	for _, t in ipairs(LaneTowers(s.lane or LANE_MID)) do
		local tower = GetTower(p.team, t)
		if Valid(tower) then
			if D2(p.loc, tower:GetLocation()) < K.tpFrom then return nil end
			if s.late and Medio.Risk(bot, tower:GetLocation()) >= K.tpRisk then return nil end
			s.tpAt = p.now
			return { intent = 'teleporte', item = item, at = tower:GetLocation(),
				reason = string.format('a %d del frente, a la torre %d', D2(p.loc, p.front), t) }
		end
	end
	return nil
end

-- Take Aim first, when the decision is to hit a hero. Not while hidden: the first thing out of the stealth is the hit that
-- carries its bonus.
local function WithAim(bot, s, p, hero, r)
	if hero == nil or r == nil or r.target == nil or (r.intent ~= 'acosar' and r.intent ~= 'matar') or bot:IsInvisible() then return r end
	-- Package 3: trading hits with a hero, the hero's spells on it first, as OHA casts on its attack target (TradeCast).
	local trade = r.intent == 'acosar' and hero.TradeCast ~= nil and not p.late and hero.TradeCast(bot, s, p, r.target) or nil
	if trade then return trade end
	return Medio.Berserk(bot, s, p, r.target) or hero.Aim(bot, s, p, r.target) or r
end

local function Decide(bot, s, p)
	if p.t < -5 and not s.bought then return { intent = 'comprar', reason = 'objetos iniciales' } end
	local late = not NO_COMBAT and Medio.Late(bot, s, p)
	p.late = late == true
	if late then
		if not s.lateLogged then
			s.lateLogged = true
			Log(s, bot, 'medio', 'empieza el medio juego: ' .. s.lateWhy)
		end
		local changed = Medio.ChooseLane(bot, s, p)
		if changed then Log(s, bot, 'medio', changed) end
		local bkb = Medio.Bkb(bot, s, p)
		if bkb then return bkb end
	end
	p.dos = (not late and not NO_COMBAT) and Dos.Applies(bot, s, p, function(pid) return S[pid] end) or nil
	-- Package 4: Magic Wand under half health (an instant heal, no safety needed), as every OHA hero carries and uses one.
	if P4 and p.hp < 0.5 then
		local wand = HasItem(bot, 'item_magic_wand')
		-- Not muted or hexed (no item then, and the order would be sent each tick ahead of the retreat), not again within a second.
		if wand ~= nil and wand:IsFullyCastable() and (wand:GetCurrentCharges() or 0) >= 3 and not bot:IsMuted() and not bot:IsHexed()
			and p.now - ((s.itemUsed or {}).item_magic_wand or -1000) >= 1 then
			return { intent = 'usar_objeto', item = wand, reason = string.format('magic wand, vida %.2f, %d cargas', p.hp, wand:GetCurrentCharges()) }
		end
	end
	local r = RuleRetreat(bot, s, p)
	-- Retreating for health alone (no tower on us, no enemy burst), healing comes first: RuleHeal itself requires
	-- no enemy hero near and no recent hero or tower damage.
	if r and not p.towerOnMe and not (p.heroOnMe and p.enemyBurst > K.enemyBurst * p.hpAbs) then
		local h = RuleHeal(bot, s, p)
		if h then
			if s.chase ~= nil then Log(s, bot, 'persecucion', Combate.Stop(bot, s, p, 'curarse')) end
			if p.dos then Dos.End(bot, s, p, 'retirada curarse') end
			s.dosOpen = nil
			return h
		end
	end
	if r then
		if s.chase ~= nil then Log(s, bot, 'persecucion', Combate.Stop(bot, s, p, 'retirada')) end
		-- One of the pair retreating ends the pair's entry for both (dos.lua): the partner must not stay on it alone. It also forgets the
		-- opening it was following (package 4), or it went back to hit once the retreat's hold ran out (review of package 4).
		if p.dos then Dos.End(bot, s, p, 'retirada ' .. (r.reason or '')) end
		s.dosOpen = nil
		return (late and Medio.Escape(bot, s, p, Home(p.team))) or r
	end
	r = RuleHeal(bot, s, p)
	if r then return r end
	r = RuleTeleport(bot, s, p)
	if r then return r end
	local hero = p.hero
	if hero ~= nil and not NO_COMBAT then
		r = hero.Finish(bot, s, p)
		if r then return r end
	end
	-- The lane of two: the pair's entry (its hero opens with KillCast in the same second as the partner) or its leaving together.
	if p.dos then
		r = Dos.Act(bot, s, p, Home(p.team), (SafeSpot(p.team, s.lane)))
		if r then
			local cast = hero ~= nil and r.intent == 'matar' and hero.KillCast(bot, s, p, r.target) or nil
			return cast or WithAim(bot, s, p, hero, r)
		end
	end
	-- Kills: a chase under way goes on (or ends with its reason), else a new kill may start.
	if not NO_COMBAT and not p.dos then
		local ended
		r, ended = Combate.Continue(bot, s, p)
		if ended then Log(s, bot, 'persecucion', ended) end
		if r == nil then r = Combate.Start(bot, s, p) end
		-- The partner opened on an enemy (a kill or a lock on the board, pareja.lua): join it now, so KillCast lands in the same second
		-- (package 2). Lane only; it logs its own lines ("prop pareja").
		if r == nil then r = Combate.Join(bot, s, p) end
		if r then
			local cast = hero ~= nil and r.intent == 'matar' and hero.KillCast(bot, s, p, r.target) or nil
			return cast or WithAim(bot, s, p, hero, r)
		end
	end
	if late then
		r = Medio.Kite(bot, s, p, Home(p.team))
		if r then return r end
		r = Medio.Fight(bot, s, p)
		if r then
			local opening = hero ~= nil and not bot:IsInvisible() and hero.FightCast(bot, s, p) or nil
			if opening then return opening end
			local cast = hero ~= nil and r.intent == 'acosar' and not bot:IsInvisible() and hero.KillCast(bot, s, p, r.target) or nil
			return cast or WithAim(bot, s, p, hero, r)
		end
		r = Medio.TeleportToFight(bot, s, p)
		if r then return r end
		-- An enemy in range and safe: shoot, but a last hit ready without a step first (as with the team below).
		r = Medio.Shoot(bot, s, p)
		if r then
			local lh = RuleLastHit(bot, s, p)
			if lh ~= nil then return lh end
			local cast = hero ~= nil and hero.KillCast(bot, s, p, r.target) or nil
			return cast or WithAim(bot, s, p, hero, r)
		end
		-- Before the last hits: it leaves the creeps for the team, not the other way round.
		r = Medio.WithTeam(bot, s, p)
		if r then
			-- A last hit ready without a step is taken first: walking to them it let them fall (equipo2, about 2 a match).
			if r.intent == 'con_el_grupo' and not bot:IsInvisible() then
				local lh = RuleLastHit(bot, s, p)
				if lh ~= nil then return lh end
			end
			-- Farming first behind a lone ally (paquete2) gave the last hits back (126 to 154) but took kills 7,3 to 5,0, damage 24.549
			-- to 17.724 and deaths 0,7 to 2,0: undone, and Pedro's game decides between farm and presence (MEDICIONES 2026-11-12).
			local hide = r.intent == 'con_el_grupo' and Medio.Hide(bot, s, p, r.to) or nil
			return hide or r
		end
	end
	local hidden = bot:IsInvisible()
	-- Package 3: a spell to last-hit a lane creep the attack does not reach (Luna's Beam, Lich's Frost Blast), OHA's lane rule.
	if not NO_COMBAT and not late and not hidden and hero ~= nil and hero.FarmCast ~= nil then
		r = hero.FarmCast(bot, s, p)
		if r then return r end
	end
	local ready, soon
	if not hidden then
		r, ready, soon = RuleLastHit(bot, s, p)
		if r then return r end
	end
	-- Shrapnel right after a last hit that is ready, before trading, the aggro or runes: behind them it barely got its turn, with 90 % of
	-- the mana idle, 8,7 casts by minute 10 against OHA's 13,1 (MEDICIONES, `build1`).
	-- Outnumbered in the lane (Perceive, p.alone), no harass spell on a hero: only what protects an ally (Lich's Frost Shield, the
	-- hero's Protect). Lion's lone Earth Spike was the start of each of its deaths: the answer came, then the back and forth
	-- (trabajo/plan-mejora-equipo.md, package 1). Harass is not called at all, since some set their timers when they choose.
	if not NO_COMBAT and hero ~= nil and not hidden then
		-- In a lane of two, no harass without the partner near: OHA's safe lane died after hitting a hero alone (dos.lua).
		if p.alone or (p.dos and (not p.dos.partnerNear or p.dos.board.mode == 'salir')) then
			r = hero.Protect ~= nil and hero.Protect(bot, s, p) or nil
		else
			r = hero.Harass(bot, s, p)
		end
		if r then return r end
	end
	if not NO_COMBAT and not (p.dos and (not p.dos.partnerNear or p.dos.board.mode == 'salir')) then
		r = WithAim(bot, s, p, hero, RuleTrade(bot, s, p, ready, soon))
		if r then return r end
	end
	-- Enemy creeps hitting us: a step back drops the aggro, after the last hit that is ready and only with two or more:
	-- one creep's hits are the price of farming (fase1d: 18 s lost to it; fase1f-reg: 18 of 22 decisions with one).
	-- A melee hero only with low health (heroes.lua, R.ALCANCE): it stands among the creeps to last-hit.
	if s.chase == nil and p.creepsOnMe >= 2 and p.hp <= select(2, Heroes.Rol(bot)).soltarAggroHp then
		return { intent = 'soltar_aggro', reason = string.format('%d creeps me pegan, vida %.2f', p.creepsOnMe, p.hp),
			to = Toward(p.loc, Home(p.team), K.aggroStep) }
	end
	r = Combate.Rune(bot, s, p)
	if r then return r end
	if late and ready == nil and not hidden then
		r = Medio.Siege(bot, s, p) or Medio.Neutrals(bot, s, p)
		if r then return r end
	end
	local holdAt = late and Medio.HoldSpot(bot, s, p, LanePoint(p)) or nil
	-- The support with its core (dos.lua, Spot): OHA's pairs stand 520-740 apart.
	if p.dos then
		local spot = Dos.Spot(bot, s, p, LanePoint(p))
		-- Once there it holds the spot (no order within 60): leaving it to the lane point flipped every tick (dos-humo 2, t=380).
		if spot then return { intent = 'con_pareja', reason = 'junto a mi nucleo', to = spot } end
	end
	if ready ~= nil then
		local spot = Toward(ready:GetLocation(), p.loc, p.range * 0.9)
		-- Holding back, it takes the creeps that come within its range, and does not walk out for them.
		local moves = holdAt == nil and D2(p.loc, ready:GetLocation()) > p.range
		if not moves or not TowerBlocks(bot, p, spot) then
			return { intent = 'preparar_golpe', reason = string.format('%s cae en ~%.0fs', string.gsub(ready:GetUnitName(), 'npc_dota_', ''), K.lookAhead),
				to = moves and spot or nil }
		end
	end
	-- With them it stays: falling through to the lane walked it out again, ten times a second (equipo1-c, t=900-905).
	if late and s.atTeam then return { intent = 'con_el_grupo', reason = string.format('con ellos, %d aliados', s.teamN or 0) } end
	if holdAt ~= nil then
		return { intent = 'esperar', reason = string.format('solo y con riesgo %.1f: junto a la torre', Medio.Risk(bot, LanePoint(p))), to = holdAt }
	end
	local spot = LanePoint(p)
	local hide = late and Medio.Hide(bot, s, p, spot)
	if hide then return hide end
	return { intent = 'linea', reason = string.format('detrás del frente a %d', K.holdBack), to = spot }
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
	for _, item in ipairs(Heroes.Datos(bot:GetUnitName()).salida or {}) do
		local code = bot:ActionImmediate_PurchaseItem(item)
		Log(s, bot, 'compra', string.format('%s codigo=%s oro=%d', item, tostring(code), bot:GetGold()))
	end
	-- The role's extra (heroes.lua, R.ROL: a support's clarity), when the gold left pays for it; else Consumables buys it later.
	for _, item in ipairs((Heroes.Rol(bot)).salidaExtra or {}) do
		if bot:GetGold() >= GetItemCost(item) then
			local code = bot:ActionImmediate_PurchaseItem(item)
			Log(s, bot, 'compra', string.format('%s (rol) codigo=%s oro=%d', item, tostring(code), bot:GetGold()))
		end
	end
	s.bought = true
end

local function LevelUp(bot, s)
	local build = Heroes.Datos(bot:GetUnitName()).niveles
	if build == nil or bot:GetAbilityPoints() <= 0 or s.nextSkill > #build then return end
	local name = build[s.nextSkill]
	bot:ActionImmediate_LevelAbility(name)
	Log(s, bot, 'nivel', string.format('%s nivel=%d puntos=%d', name, bot:GetLevel(), bot:GetAbilityPoints()))
	s.nextSkill = s.nextSkill + 1
end

-- After each attack lands, did the last hit or deny happen? A queue, oldest first: a new attack used to overwrite the
-- pending one, which biased the hit rate (trabajo/fase1-plan.md). Each hit of the counter is spent on one attempt, so
-- two attempts in flight cannot both claim the same last hit.
local function CheckPending(bot, s, p)
	local queue = s.pending
	while queue ~= nil and queue[1] ~= nil and p.now >= queue[1].landAt + 0.4 do
		local q = table.remove(queue, 1)
		local lh, dn = bot:GetLastHits() - s.lhSeen, bot:GetDenies() - s.dnSeen
		local hit = (q.deny and dn > 0) or (not q.deny and lh > 0)
		if hit and q.deny then s.dnSeen = s.dnSeen + 1 elseif hit then s.lhSeen = s.lhSeen + 1 end
		local alive = Valid(q.creep)
		-- acierto: the counter rose, maybe by Shrapnel or Maelstrom; what killed it is in the custom game's creepkill.
		Log(s, bot, 'golpe_res', string.format('%s %s lh+%d dn+%d creep_vivo=%s vida=%s prevista=%.0f orden=%.1f',
			q.deny and 'denegar' or 'ultimo_golpe', hit and 'acierto' or 'fallo',
			lh, dn, tostring(alive), alive and tostring(q.creep:GetHealth()) or '-', q.hpAt, q.orden))
	end
end

-- An Assassinate, once its shot had time to land: did it kill? (3 of 23 OHA kills carry it; the revisers disagree.)
local function CheckAssassinate(bot, s, p)
	local q = s.assassinate
	if q == nil or p.now < q.at then return end
	local alive = Valid(q.target)
	Log(s, bot, 'assassinate_res', string.format('objetivo=%s ilusion=%d vida_antes=%d vida_ahora=%s kills+%d', q.name,
		q.illusion and 1 or 0, q.hp0, alive and tostring(q.target:GetHealth()) or '-', GetHeroKills(bot:GetPlayerID()) - q.kills0))
	s.assassinate = nil
end

-- What each rune order found and left, since the far orders leave the hero idle and the near ones took nothing:
-- the line that tells the cause (trabajo/fase1-plan.md, step 3).
local function RuneOrder(bot, s, p, d)
	Log(s, bot, 'runa_res', string.format('runa=%d d=%d x=%d y=%d estado=%d tipo=%d accion=%d visto=%.1f intento=%s', d.rune,
		D2(p.loc, d.to), p.loc.x, p.loc.y, GetRuneStatus(d.rune), GetRuneType(d.rune), bot:GetCurrentActionType(),
		GetRuneTimeSinceSeen(d.rune), s.runeTry ~= nil and 'si' or 'no'))
end

local function Act(bot, s, p, d)
	-- After a chase, its attack order would go on by itself (even under a tower): cancel it before anything else, and
	-- forget the last move so the next one is really sent (review of 2026-11-03).
	if s.stopAttack and d.intent ~= 'matar' then
		bot:Action_ClearActions(true)
		s.stopAttack, s.moveTo = false, nil
		if d.to == nil and d.intent ~= 'ultimo_golpe' and d.intent ~= 'denegar' then d.to = LanePoint(p) end
	end
	if d.intent ~= 'matar' and d.intent ~= 'farmear' then s.attacking = nil end
	if d.intent ~= 'runa' then s.runeTry = nil end
	if d.intent == 'comprar' then Buy(bot, s) return end
	-- An item order is not repeated each frame while the healing buff has not appeared yet.
	if d.intent == 'curar_salvia' or d.intent == 'clarity' then bot:Action_UseAbilityOnEntity(d.item, bot) s.busyUntil = p.now + 0.6 return end
	if d.intent == 'curar_tango' then bot:Action_UseAbilityOnTree(d.item, d.tree) s.busyUntil = p.now + 1.0 return end
	-- Abilities: protected for their cast point, so the cast is not cut by the next decision.
	if d.intent == 'rematar' then
		bot:Action_UseAbilityOnEntity(d.ability, d.target)
		-- A target a few steps out of the cast range (Dragon Tail's reach is a melee one) is walked to first: the check that the cast
		-- started waits that walk. Without it both of the smoke's Dragon Tails read 'no arranca' 0,3 s after the order, and the next
		-- decision cut them (fase2-humo-equipo 1 t=58.6, 2 t=541.5); that the walk is the cause is an assumption to check in the log.
		-- At most a second (an assumption: the rules cast from their range or a few steps more), and a target whose place reads nil
		-- (OHA's GetLocation for an unseen unit, D2 = 1e9) must not freeze the hero.
		local walk = math.min(1.0, math.max(0, D2(p.loc, d.target:GetLocation()) - d.ability:GetCastRange()) / math.max(p.moveSpeed, 1))
		s.busyUntil = p.now + d.castPoint + 0.3 + walk
		s.castCheck = { at = p.now + 0.3 + walk, name = string.gsub(d.target:GetUnitName(), 'npc_dota_hero_', ''), ability = d.ability:GetName() }
		-- Every hero's unit-target cast goes here (phase 2); the kill check after it is the Assassinate's.
		local name = d.ability:GetName()
		Log(s, bot, 'habilidad', (name == 'sniper_assassinate' and 'assassinate' or name) .. ': ' .. d.reason)
		-- An opening on an enemy hero (the hero module marks it: Hex, Dragon Tail, Lucent Beam, Lich's Frost Blast in a kill) goes on the
		-- pair's board (package 2).
		if d.opens ~= nil then Combate.AnnounceOpening(bot, s, p, d) end
		-- Package 4: the caster keeps hitting the hero it opened on (dos.lua, Act).
		if P4 and p.dos and d.opens ~= nil then s.dosOpen = { target = d.opens, untilT = p.now + d.castPoint + (d.lockSec or 0) + 3 } end
		if name == 'sniper_assassinate' then
			s.assassinate = { target = d.target, name = string.gsub(d.target:GetUnitName(), 'npc_dota_hero_', ''),
				hp0 = d.target:GetHealth(), kills0 = GetHeroKills(bot:GetPlayerID()), at = p.now + d.castPoint + 3.0,
				illusion = d.target:IsIllusion() }
		end
		return
	end
	if d.intent == 'usar_objeto' then
		if d.target ~= nil then bot:Action_UseAbilityOnEntity(d.item, d.target) else bot:Action_UseAbility(d.item) end
		s.busyUntil, s.moveTo = p.now + 0.1, nil
		s.itemUsed = s.itemUsed or {}
		s.itemUsed[d.item:GetName()] = p.now
		Log(s, bot, 'objeto', string.format('%s: %s', d.item:GetName(), d.reason))
		return
	end
	if d.intent == 'apuntar' then
		bot:Action_UseAbility(d.ability)
		s.busyUntil, s.moveTo = p.now + d.castPoint + 0.05, nil
		Log(s, bot, 'habilidad', (d.ability:GetName() == 'sniper_take_aim' and 'take_aim' or d.ability:GetName()) .. ': ' .. d.reason)
		return
	end
	if d.intent == 'teleporte' then
		bot:Action_UseAbilityOnLocation(d.item, d.at)
		s.busyUntil, s.moveTo = p.now + 0.5, nil -- then IsChanneling holds the decisions (L.Think)
		Log(s, bot, 'habilidad', 'tp: ' .. d.reason)
		return
	end
	if d.intent == 'shrapnel' then
		bot:Action_UseAbilityOnLocation(d.ability, d.at)
		s.busyUntil, s.shrapnelAt = p.now + d.castPoint + 0.2, p.now
		Log(s, bot, 'habilidad', (d.ability:GetName() == 'sniper_shrapnel' and 'shrapnel' or d.ability:GetName()) .. ': ' .. d.reason)
		-- Earth Spike's lock is cast on the ground: the module names the enemy it aims at (package 2).
		if d.opens ~= nil then Combate.AnnounceOpening(bot, s, p, d) end
		if P4 and p.dos and d.opens ~= nil then s.dosOpen = { target = d.opens, untilT = p.now + d.castPoint + (d.lockSec or 0) + 3 } end
		return
	end
	if d.intent == 'acosar' then
		bot:Action_AttackUnit(d.target, true)
		s.lastAttackOrder, s.tradeAt = p.now, p.now
		s.busyUntil = p.now + p.point + K.windUp + (d.walk or 0) + math.max(0, bot:GetLastAttackTime() + bot:GetSecondsPerAttack() - p.now)
		s.moveTo = nil
		Log(s, bot, 'acoso', d.reason)
		return
	end
	if (d.intent == 'ultimo_golpe' or d.intent == 'denegar') then
		bot:Action_AttackUnit(d.target, true)
		s.lastAttackOrder = p.now
		-- Protect the wind-up only (walk and attack point), not the projectile's flight.
		s.busyUntil = p.now + d.hit.tLand - d.hit.flight + K.windUp
		s.pending = s.pending or {}
		if #s.pending == 0 then s.lhSeen, s.dnSeen = bot:GetLastHits(), bot:GetDenies() end
		table.insert(s.pending, { creep = d.target, landAt = p.now + d.hit.tLand, hpAt = d.hit.hpAt, deny = d.hit.deny,
			orden = p.t })
		Log(s, bot, 'golpe', d.reason)
		return
	end
	-- A kill: keep attacking the target (one order per target or per second, not per frame); unseen, walk to where it
	-- was last seen. A rotation walks to it.
	if (d.intent == 'matar' or d.intent == 'farmear' or d.intent == 'derribar') and d.to == nil then
		if s.attacking ~= d.target or p.now - (s.attackOrderAt or -1000) > 1.0 then
			bot:Action_AttackUnit(d.target, false)
			s.attacking, s.attackOrderAt = d.target, p.now
		end
		s.lastAttackOrder = p.now
		return
	end
	s.attacking = nil
	if d.intent == 'rotar' and d.to == nil then MoveTo(bot, s, p, d.target:GetLocation()) return end
	if d.intent == 'runa' then
		if p.now - (s.runeOrderAt or -1000) > 1.0 then
			pcall(RuneOrder, bot, s, p, d) -- a logging failure must not stop the order
			s.runeOrderAt = p.now
		end
		-- From afar the order leaves the hero idle (accion=1 in 111 of 125 samples, MEDICIONES fase1f-reg): walk first.
		if s.runeTry == nil and D2(p.loc, d.to) > K.runePick then
			MoveTo(bot, s, p, d.to)
			return
		end
		-- Near, the order every tick as OHA does, without walking back: at d=0-57 it took the hero away and nothing was
		-- picked up (fase1 to fase1e), cause unknown. Three seconds, then that rune is left alone for a minute.
		s.runeTry = s.runeTry or p.now
		if p.now - s.runeTry > K.runeTry then
			s.runeBan = s.runeBan or {}
			s.runeBan[d.rune] = p.now + K.runeBan
			Log(s, bot, 'runa_res', string.format('runa=%d abandono tras %.0fs, d=%d', d.rune, K.runeTry, D2(p.loc, d.to)))
			s.runeTry = nil
			return
		end
		bot:Action_PickUpRune(d.rune)
		s.moveTo = nil
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
	Log(s, bot, 'estado', string.format('intencion=%s vida=%.2f mana=%.2f modo=%s accion=%d cola=%d creeps_e=%d creeps_a=%d heroes_e=%d daño3s=%d daño3s_todos=%d',
		s.intent, p.hp, bot:GetMana() / math.max(bot:GetMaxMana(), 1), tostring(bot:GetActiveMode()), bot:GetCurrentActionType(),
		bot:NumQueuedActions(), #p.enemyCreeps, #p.allyCreeps, #p.enemyHeroes, p.enemyBurst, p.enemyBurstAll))
	-- Where it stands against the lane, with the same period: distance to the creep front, nearest enemy tower and hero
	-- (-1 when none is in the snapshot).
	local nearest = function(list)
		local best = -1
		for _, u in ipairs(list) do
			if Valid(u) then
				local d = D2(p.loc, u:GetLocation())
				if best < 0 or d < best then best = d end
			end
		end
		return best
	end
	Log(s, bot, 'pos', string.format('x=%d y=%d frente=%d torre=%d heroe=%d', p.loc.x, p.loc.y, D2(p.loc, p.front),
		nearest(p.enemyTowers), nearest(p.enemyHeroes)))
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
	-- Purchases, courier and inventory run dead or alive (OHA also buys while dead).
	if s.bought then
		local now = GameTime()
		for _, line in ipairs({ Compras.Consumables(bot, s, now) or false, Compras.Buy(bot, s, now) or false,
			Compras.Courier(bot, s, now) or false, Compras.Arrange(bot, s, now) or false }) do
			if line then Log(s, bot, 'compra', line) end
		end
	end
	if not bot:IsAlive() then
		if s.chase ~= nil then
			Log(s, bot, 'persecucion', Combate.Stop(bot, s, { now = GameTime() }, 'muerto'))
		end
		local backLine = s.bought and Compras.Buyback(bot, s, GameTime()) or nil
		if backLine then Log(s, bot, 'compra', backLine) end
		-- Dead time counts too, so the calls per second compare with the other bots' (the smoke read 25 against 30).
		s.pending, s.retreating, s.toFountain, s.lowHp, s.burstUntil = nil, false, false, false, nil
		s.holdOut, s.holdHp = false, false
		Cost(bot, s, DotaTime(), (RealTime() - started) * 1000)
		return
	end
	local p = Perceive(bot)
	if OBSERVE then pcall(Dos.Sombra, bot) end
	CheckPending(bot, s, p)
	CheckAssassinate(bot, s, p)
	local evalOk, evalLines = pcall(Combate.KillEval, bot, s, p) -- a logging failure must not stop the bot
	for _, line in ipairs(evalOk and evalLines or {}) do Log(s, bot, 'kill_eval', line) end
	WatchAutoAttack(bot, s, p)
	LevelUp(bot, s)
	-- Once per match, the Treads as they come out of the recipe: in fase1g only 1 of 8 matches had to change them.
	if not s.treadsSeen and bot:FindItemSlot('item_power_treads') >= 0 and bot:FindItemSlot('item_power_treads') <= 5 then
		s.treadsSeen = true
		Log(s, bot, 'compra', string.format('botas montadas stat_api=%d agi=%d int=%d',
			bot:GetItemInSlot(bot:FindItemSlot('item_power_treads')):GetPowerTreadsStat(),
			bot:GetAttributeValue(ATTRIBUTE_AGILITY), bot:GetAttributeValue(ATTRIBUTE_INTELLECT)))
	end
	-- An Assassinate the engine did not start keeps the hero still for its whole cast: 29 of 38 such orders, some 14 s a match standing
	-- there (equipo2). Free again, and that target is left alone for a few seconds so the order does not loop.
	if s.castCheck ~= nil and p.now >= s.castCheck.at then
		local c = s.castCheck
		s.castCheck = nil
		if bot:GetCurrentActionType() ~= BOT_ACTION_TYPE_USE_ABILITY and not bot:IsCastingAbility() then
			s.busyUntil = p.now
			s.castBan = s.castBan or {}
			s.castBan[c.name] = p.now + 3
			Log(s, bot, 'habilidad', ((c.ability == nil or c.ability == 'sniper_assassinate') and 'assassinate' or c.ability) .. ' no arranca sobre ' .. c.name .. ': libre')
		end
	end
	local treads = (p.now >= s.busyUntil and not bot:IsChanneling()) and Compras.TreadsToAgility(bot, s, p.now) or nil
	local filler = (treads == nil and p.now >= s.busyUntil and not bot:IsChanneling()) and Compras.FillerToDrop(bot, s, p.now) or nil
	if filler ~= nil then
		bot:Action_DropItem(filler, p.loc)
		s.busyUntil, s.moveTo = p.now + 0.05, nil
		Log(s, bot, 'compra', 'tiro ' .. filler:GetName() .. ': inventario casi lleno')
	elseif treads ~= nil then
		-- Each change logs the attributes: the proof that the API's reading of the stat is the way round OHA says.
		Log(s, bot, 'compra', string.format('botas cambio stat_api=%d agi=%d int=%d', treads:GetPowerTreadsStat(),
			bot:GetAttributeValue(ATTRIBUTE_AGILITY), bot:GetAttributeValue(ATTRIBUTE_INTELLECT)))
		bot:Action_UseAbility(treads)
		s.busyUntil, s.moveTo = p.now + 0.05, nil
	elseif p.now >= s.busyUntil and not bot:IsChanneling() then
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
