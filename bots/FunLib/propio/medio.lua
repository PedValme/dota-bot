-- dota-bot's own bot: the middle and late game of a long-range hero (Pedro, 2026-11-05: «no aprovechar sus ventajas con el
-- rango [...] deberia entrar oculto siempre, pero se pasea campante por las lineas, no se hace invisible, no salta [...] ese
-- criterio de riesgo-ataque-sigilo es lo que falta»). Once the lane is over: which lane is safe to farm, joining a fight from
-- maximum range and hidden, keeping melee away, leaving before being outnumbered, and the items for it. Each rule returns a
-- decision with its reason, or nil. Entered by the state of the match, not the clock (DECISIONES 2026-10-31). The thresholds
-- are judgement, not data: tuned with the smokes and Pedro's games.
local M = {}

local Intercambio = require(GetScriptDirectory()..'/FunLib/propio/intercambio')

local K = {
	lateLevel = 15,      -- the lane is over at this level, or when a mid tier 1 falls (12 came at t=417-616: inside the
	                     -- lane measured at minute 10; 14 at t=515-686)
	seenRecent = 8,      -- an enemy seen this many seconds ago still counts, where it could have walked to
	walkSpeed = 330,     -- how far an unseen enemy is supposed to walk per second
	riskRadius = 1400,   -- an enemy this close to a spot makes it risky
	missingRisk = 0.15,  -- each enemy missing from the map adds this to every spot
	allyWeight = 0.7,    -- each ally near a spot takes this off
	towerWeight = 1.0,   -- our tower near a spot takes this off
	laneEvery = 15,      -- seconds between changes of lane
	laneGain = 1.0,      -- a lane must be this much safer to walk to it
	laneTravel = 6000,   -- each this many units of walking cost 1 of risk
	fightReach = 3500,   -- a fight this far is worth walking to; farther, by teleport
	fightTpAllies = 2,   -- ...with this many allies in it
	fightAloneReach = 2500, -- a fight of one ally is walked to only from this close
	fightTpTower = 2000, -- ...and one of our towers this close to it
	fightTpHp = 0.6,
	groupReach = 6000,   -- a group this far is worth joining (with 3500: 4 % of the time with it, presion7)
	groupNear = 900,     -- allies this close to each other are a group
	groupBehind = 500,   -- ...and it stands this far behind them, toward home
	groupThere = 500,    -- this close to that spot is being with them
	farmHp = 0.5,        -- no neutrals below this health
	neutralNear = 900,   -- neutrals this close are hit
	ancientLevel = 20,   -- ancients from this level on
	campReach = 3000,    -- camps this far are worth walking to (1800 cost farm: 150 last hits at minute 25 against 213, presion3 and 4)
	campArrive = 300,    -- this close to a camp is being there
	allyEngaged = 1100,  -- an ally this close to a visible enemy, and hitting or being hit, is fighting
	fightOdds = 1,       -- join with at most this many enemies above our heroes there, ourselves counted: it shoots from behind
	                     -- the allies, and with 0 it skipped most fights (damage in 14 % of the windows against OHA's 28 %, presion7)
	fightHp = 0.5,       -- no walking into a fight below this health
	towerMargin = 820,   -- no walking this close to an enemy tower for a fight
	standBack = 100,     -- stand this much inside our range from the nearest enemy
	kiteNear = 450,      -- an enemy this close is stepped away from between attacks
	kiteStep = 350,
	outnumbered = 2,     -- this many more enemies within 1000 than allies within 1400: leave now
	outnumberedNear = 1000,
	alliesNear = 1400,   -- wider than for enemies: an ally a little farther is still in the fight
	hideTravel = 1200,   -- a walk this long, in sight of risk, is done hidden
	pushNear = 450,      -- Hurricane Pike reaches an enemy this close to push both apart
	facing = 30,         -- degrees within which a Force Staff on ourselves goes the way we want
	itemAgain = 1.5,     -- seconds before ordering the same item again: a push order takes a moment to start, and repeating it
	                     -- each tick left the hero standing there (lobby 2026-11-05: 5 Pike orders in 0,5 s while dying)
	enemyTower = 0.6,    -- an enemy tower near a spot adds this to its risk: alone, it does not stand at the foot of one
	enemyTowerNear = 1600,
	laneWalk = 2500,     -- a change of lane is walked only this far; farther needs the teleport ready: it was crossing the map on
	                     -- foot, in the middle of a fight, when it died (presion-propio: 6.000-7.000 from its lane)
	hideFar = 3000,      -- a walk this long is not done hidden: it will not last, and it left the Blade on cooldown for the fight
	blockNear = 1200,    -- a retreat does not take a tower with an enemy this near us standing closer to it than we are
	holdRisk = 0.9,      -- alone, a spot with this risk is not walked to: an enemy seen near it. With 0.4, three enemies missing
	                     -- were enough and it spent 13-24 % of the game waiting (medio2: 138,7 last hits at minute 25, 175,5 before)
	holdFromTower = 500, -- ...it stays this far from our nearest tower, toward the lane
	sureKill = 1.5,      -- alone, a chase starts only with this many times the margin (with 2.0: 2,7 kills from minute 10, 8,5 before)
}

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
local function Valid(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

-- Whether the lane is over. Once true it stays true, and it logs why.
function M.Late(bot, s, p)
	if s.late then return true end
	local why = nil
	if bot:GetLevel() >= K.lateLevel then why = 'nivel ' .. bot:GetLevel()
	elseif not Valid(GetTower(p.team, TOWER_MID_1)) then why = 'cayó nuestra T1 de mid'
	else
		local enemy = GetTower(GetOpposingTeam(), TOWER_MID_1)
		if enemy == nil or enemy:IsNull() or not enemy:IsAlive() then why = 'cayó su T1 de mid' end
	end
	if why == nil then return false end
	s.late, s.lateWhy = true, why
	return true
end

-- Every living enemy: where it was last seen and how long ago. A hero's copies do not add up: this reads the players.
local function Enemies()
	local list = {}
	-- true: the engine's own order, not OHA's override, which reorders Dire when it has humans.
	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam(), true) or {}) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id)
			local seen = info ~= nil and info[1] or nil
			table.insert(list, { location = seen and seen.location or nil, since = seen and seen.time_since_seen or 1e9 })
		end
	end
	return list
end

-- How risky a spot is: enemies seen and near it (or able to have walked there), the missing ones a little, allies and our
-- towers near it the other way. Roughly, the number of enemies more than friends the hero would meet there.
function M.Risk(bot, loc, noEnemyTower)
	local risk = 0
	for _, e in ipairs(Enemies()) do
		if e.location == nil or e.since > K.seenRecent then
			risk = risk + K.missingRisk
		elseif D2(loc, e.location) < K.riskRadius + K.walkSpeed * e.since then
			risk = risk + 1
		end
	end
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() and D2(loc, a:GetLocation()) < K.riskRadius then risk = risk - K.allyWeight end
	end
	for _, t in ipairs(GetUnitList(UNIT_LIST_ALLIED_BUILDINGS) or {}) do
		if t ~= nil and not t:IsNull() and t:IsAlive() and t:IsTower() and D2(loc, t:GetLocation()) < 900 then
			risk = risk - K.towerWeight
			break
		end
	end
	if noEnemyTower then return risk end
	for _, t in ipairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS) or {}) do
		if t ~= nil and not t:IsNull() and t:IsAlive() and t:IsTower() and D2(loc, t:GetLocation()) < K.enemyTowerNear then
			risk = risk + K.enemyTower
			break
		end
	end
	return risk
end

-- The lane to farm: the safest front, counting the walk, with a margin so it does not go back and forth. Returns a log line
-- when it changes.
function M.ChooseLane(bot, s, p)
	s.lane = s.lane or LANE_MID
	-- With an enemy in sight this is no time to leave for another lane.
	if p.now - (s.laneAt or -1000) < K.laneEvery or #p.enemyHeroes > 0 then return nil end
	s.laneAt = p.now
	local tp = bot:FindItemSlot('item_tpscroll')
	local canJump = tp >= 0 and (tp <= 5 or tp == 15) and bot:GetItemInSlot(tp) ~= nil and bot:GetItemInSlot(tp):IsFullyCastable()
	local scores, best, bestScore = {}, s.lane, 1e9
	for _, lane in ipairs({ LANE_TOP, LANE_MID, LANE_BOT }) do
		local front = GetLaneFrontLocation(p.team, lane, 0)
		local score = M.Risk(bot, front) + D2(p.loc, front) / K.laneTravel
		scores[lane] = score
		if score < bestScore and (lane == s.lane or canJump or D2(p.loc, front) <= K.laneWalk) then best, bestScore = lane, score end
	end
	if best ~= s.lane and bestScore + K.laneGain <= scores[s.lane] then
		local old = s.lane
		s.lane = best
		return string.format('línea %d -> %d: riesgo %.1f frente a %.1f', old, best, bestScore, scores[old])
	end
	return nil
end

-- More enemies than friends right next to us: why it should leave now, or nil.
function M.Outnumbered(bot, p)
	local enemies, allies = 0, 0
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p.loc, e:GetLocation()) < K.outnumberedNear then enemies = enemies + 1 end
	end
	for _, a in ipairs(bot:GetNearbyHeroes(K.alliesNear, false, BOT_MODE_NONE) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() then allies = allies + 1 end
	end
	-- With an ally beside it, one enemy more is tolerated, like Fight's odds: else it joined and left in a loop.
	if enemies - allies >= K.outnumbered + (allies > 0 and 1 or 0) then return string.format('superado %d enemigos, %d aliados', enemies, allies) end
	return nil
end

local function ReadyItem(bot, s, p, names)
	for _, name in ipairs(names) do
		local slot = bot:FindItemSlot(name)
		if slot >= 0 and slot <= 5 and p.now - ((s.itemUsed or {})[name] or -1000) >= K.itemAgain then
			local item = bot:GetItemInSlot(slot)
			if item ~= nil and item:IsFullyCastable() then return item, name end
		end
	end
	return nil
end

-- Allies with us. One of the frailest heroes in the game (Pedro, 2026-11-05: «atacando solo a pesar de que es uno de los
-- heroes mas endebles»): alone, it does not start anything.
function M.Allies(bot)
	local n = 0
	for _, a in ipairs(bot:GetNearbyHeroes(K.alliesNear, false, BOT_MODE_NONE) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() then n = n + 1 end
	end
	return n
end

-- Whether a chase or a press may start: always in the lane, then with company or a kill beyond doubt.
function M.MayStart(bot, s, score, margin)
	if not s.late or M.Allies(bot) > 0 then return true end
	return score ~= nil and margin ~= nil and score >= margin * K.sureKill
end

-- Alone and with risk at the spot, it stays by our nearest tower instead of walking down the lane. Returns that spot, or nil.
function M.HoldSpot(bot, s, p, spot)
	-- The tower does not count here: when we push, the front is at theirs, and LanePoint already keeps its distance.
	if M.Allies(bot) > 0 or M.Risk(bot, spot, true) < K.holdRisk then return nil end
	local tower = M.NearestTower(p.loc)
	if tower == nil or D2(spot, tower:GetLocation()) <= K.holdFromTower then return nil end
	return Toward(tower:GetLocation(), spot, K.holdFromTower)
end
local INVIS = { 'item_silver_edge', 'item_invis_sword' }
local PUSH = { 'item_hurricane_pike', 'item_force_staff' }

local function CanHide(bot)
	return not bot:IsInvisible() and not bot:HasModifier('modifier_item_dustofappearance')
end

-- While leaving with an enemy on us: push it away, jump, or vanish, whichever is ready, in that order.
function M.Escape(bot, s, p, home)
	if not bot:WasRecentlyDamagedByAnyHero(3.0) and #p.enemyHeroes == 0 then return nil end
	local pike = ReadyItem(bot, s, p, { 'item_hurricane_pike' })
	if pike ~= nil then
		for _, e in ipairs(p.enemyHeroes) do
			if Valid(e) and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) < K.pushNear then
				return { intent = 'usar_objeto', item = pike, target = e, reason = string.format('me separo de %s', Short(e)) }
			end
		end
	end
	local push = ReadyItem(bot, s, p, PUSH)
	if push ~= nil and bot:IsFacingLocation(home, K.facing) and bot:DistanceFromFountain() > 600 then
		return { intent = 'usar_objeto', item = push, target = bot, reason = 'salto hacia casa' }
	end
	if CanHide(bot) then
		local blade = ReadyItem(bot, s, p, INVIS)
		if blade ~= nil then return { intent = 'usar_objeto', item = blade, reason = 'desaparezco al huir' } end
	end
	return nil
end

-- A walk that is long enough, toward a spot with risk and with no enemy tower near (towers see through it), is done hidden.
function M.Hide(bot, s, p, to)
	if to == nil or D2(p.loc, to) < K.hideTravel or D2(p.loc, to) > K.hideFar or not CanHide(bot) or #p.enemyTowers > 0 then return nil end
	local blade = ReadyItem(bot, s, p, INVIS)
	if blade == nil or M.Risk(bot, to) <= 0 then return nil end
	return { intent = 'usar_objeto', item = blade, reason = string.format('entro oculto, a %d del destino', D2(p.loc, to)) }
end

-- The visible heroes of the other team, one per hero.
local function VisibleEnemies(loc)
	local list = {}
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Valid(e) and not e:IsInvulnerable() then table.insert(list, e) end
	end
	return Intercambio.OnePerHero(loc, list)
end

-- Between attacks, a step away from whoever is on top of us: the range is the advantage.
function M.Kite(bot, s, p, home)
	local cooldown = bot:GetLastAttackTime() + bot:GetSecondsPerAttack() - p.now
	if cooldown < 0.3 then return nil end
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p.loc, e:GetLocation()) < K.kiteNear then
			local away = Toward(p.loc, e:GetLocation(), -K.kiteStep)
			for _, tw in ipairs(p.enemyTowers) do
				if Valid(tw) and D2(away, tw:GetLocation()) < K.towerMargin then away = Toward(p.loc, home, K.kiteStep) end
			end
			return { intent = 'alejarse', reason = string.format('kite %s a %d', Short(e), D2(p.loc, e:GetLocation())), to = away }
		end
	end
	return nil
end

-- The fight worth joining: allies with enemies on them, near enough, and odds we can live with. Shoot the weakest enemy in
-- range; if none is, walk to the nearest one's edge of our range, on our side, hidden when the item is ready.
-- Allies fighting within this reach of us: how many, around which enemy, and how many enemies there.
local function FightWithin(bot, p, enemies, reach)
	local engaged, center = 0, nil
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() and D2(p.loc, a:GetLocation()) < reach then
			-- Hitting or being hit: an enemy merely in sight of an ally is no reason to drop the farm.
			local target = a:GetAttackTarget()
			local hurt = a:WasRecentlyDamagedByAnyHero(2.0)
			for _, e in ipairs(enemies) do
				-- Only allies in the same fight count: one in top and one in bot are not two against three.
				if (center == nil or D2(center:GetLocation(), e:GetLocation()) < K.riskRadius)
					and D2(a:GetLocation(), e:GetLocation()) < K.allyEngaged and (target == e or hurt) then
					engaged, center = engaged + 1, center or e
					break
				end
			end
		end
	end
	local near = 0
	if center ~= nil then
		for _, e in ipairs(enemies) do
			if D2(center:GetLocation(), e:GetLocation()) < K.riskRadius then near = near + 1 end
		end
	end
	return engaged, center, near
end

function M.Fight(bot, s, p)
	local enemies = VisibleEnemies(p.loc)
	if #enemies == 0 then return nil end
	local engaged, center, near = FightWithin(bot, p, enemies, K.fightReach)
	if engaged == 0 or near - (engaged + 1) > K.fightOdds then return nil end
	-- One ally alone is worth the walk only when close: else it drops the wave for a fight it will not reach.
	if engaged < K.fightTpAllies and D2(p.loc, center:GetLocation()) > K.fightAloneReach then return nil end
	local weakest, weakestHp, nearest, nearestD = nil, 1e9, nil, 1e9
	for _, e in ipairs(enemies) do
		local d = D2(p.loc, e:GetLocation())
		-- The one to walk to is in that fight, not the nearest enemy anywhere on the map.
		if d < nearestD and not e:IsAttackImmune() and D2(center:GetLocation(), e:GetLocation()) < K.riskRadius then nearest, nearestD = e, d end
		if d <= p.range and e:GetHealth() < weakestHp and not e:IsAttackImmune() then weakest, weakestHp = e, e:GetHealth() end
	end
	if weakest ~= nil then
		return { intent = 'acosar', target = weakest, reason = string.format('pelea: %s vida %d, %d aliados, %d enemigos', Short(weakest), weakestHp, engaged, near) }
	end
	if nearest == nil or p.hp < K.fightHp then return nil end
	local spot = Toward(nearest:GetLocation(), p.loc, p.range - K.standBack)
	-- Every tower, also in the fog: seeing it only once near made it turn back and walk in again.
	for _, tw in ipairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS) or {}) do
		if tw ~= nil and not tw:IsNull() and tw:IsAlive() and tw:IsTower() and D2(spot, tw:GetLocation()) < K.towerMargin then return nil end
	end
	if CanHide(bot) and nearestD > p.range + K.hideTravel / 3 then
		local blade = ReadyItem(bot, s, p, INVIS)
		if blade ~= nil then return { intent = 'usar_objeto', item = blade, reason = string.format('entro oculto a la pelea, a %d', nearestD) } end
	end
	return { intent = 'a_la_pelea', to = spot, reason = string.format('a %d de %s, %d aliados, %d enemigos', nearestD, Short(nearest), engaged, near) }
end

-- A fight of two or more allies too far to walk to: by teleport to our tower next to it. It kept farming alone while the team
-- fought: 1,5 kills from minute 10 against OHA's 9,5 (presion-propio, presion-oha).
function M.TeleportToFight(bot, s, p)
	if p.hp < K.fightTpHp or #p.enemyHeroes > 0 or p.now - (s.tpAt or -1000) < 5 then return nil end
	local slot = bot:FindItemSlot('item_tpscroll')
	if slot < 0 or (slot > 5 and slot ~= 15) then return nil end
	local item = bot:GetItemInSlot(slot)
	if item == nil or not item:IsFullyCastable() then return nil end
	local enemies = VisibleEnemies(p.loc)
	local engaged, center, near = FightWithin(bot, p, enemies, 1e9)
	if engaged < K.fightTpAllies or near - (engaged + 1) > K.fightOdds or D2(p.loc, center:GetLocation()) < K.fightReach then return nil end
	local tower = M.NearestTower(center:GetLocation())
	if tower == nil or D2(tower:GetLocation(), center:GetLocation()) > K.fightTpTower then return nil end
	s.tpAt = p.now
	-- The lane it plays is now the one there: else, after the fight, it would cross the map on foot back to the old one.
	local nearestLane, laneD = s.lane, 1e9
	for _, lane in ipairs({ LANE_TOP, LANE_MID, LANE_BOT }) do
		local d = D2(tower:GetLocation(), GetLaneFrontLocation(p.team, lane, 0))
		if d < laneD then nearestLane, laneD = lane, d end
	end
	s.lane = nearestLane
	return { intent = 'teleporte', item = item, at = tower:GetLocation(),
		reason = string.format('a la pelea: %d aliados, %d enemigos, a %d', engaged, near, D2(p.loc, center:GetLocation())) }
end

-- With no creeps in the lane, neutrals: the one in reach, else the nearest camp on our side with no risk. It spent 62 % of the time
-- from minute 12 standing in the lane (presion-propio), and OHA's Sniper takes 53 neutrals in a match. Returns a decision or nil.
function M.Neutrals(bot, s, p)
	-- With risk right here it does not stay hitting a creep until someone hits it.
	if p.hp < K.farmHp or M.Risk(bot, p.loc) >= K.holdRisk then return nil end
	local best, bestHp = nil, 1e9
	local ancients = bot:GetLevel() >= K.ancientLevel
	for _, c in ipairs(bot:GetNearbyNeutralCreeps(K.neutralNear) or {}) do
		if Valid(c) and (ancients or not c:IsAncientCreep()) and c:GetHealth() < bestHp then best, bestHp = c, c:GetHealth() end
	end
	if best ~= nil then
		return { intent = 'farmear', target = best, reason = string.format('%s vida %d', (string.gsub(best:GetUnitName(), 'npc_dota_', '')), bestHp) }
	end
	-- Walking to a camp only with no creeps in the lane and no enemy near. A camp begun is finished, above.
	if #p.enemyHeroes > 0 or #p.enemyCreeps > 0 then return nil end
	s.campEmpty = s.campEmpty or {}
	-- pairs, as OHA reads this list; the keys are not documented. The camp is chosen once a second: Risk per camp each tick is dear.
	if s.camps == nil then
		s.camps = {}
		for _, c in pairs(GetNeutralSpawners() or {}) do
			if c.location ~= nil then
				table.insert(s.camps, { loc = c.location, ancient = c.type == 'ancient', key = string.format('%d_%d', c.location.x, c.location.y) })
			end
		end
		print(string.format('[bench] prop medio t=%.1f pid=%d campamentos=%d', p.t, bot:GetPlayerID(), #s.camps))
	end
	for _, c in ipairs(s.camps) do
		-- Arrived and nothing to hit: empty until the next minute, when camps refill.
		if D2(p.loc, c.loc) < K.campArrive then s.campEmpty[c.key] = p.t - p.t % 60 + 60 end
	end
	if p.now - (s.campPickAt or -1000) >= 1 then
		s.campPickAt = p.now
		s.campPick = nil
		local home, enemyHome = GetAncient(p.team):GetLocation(), GetAncient(GetOpposingTeam()):GetLocation()
		local bestD = K.campReach
		for _, c in ipairs(s.camps) do
			local d = D2(p.loc, c.loc)
			if d < bestD and (ancients or not c.ancient) and (s.campEmpty[c.key] or -1000) <= p.t
				and D2(c.loc, home) < D2(c.loc, enemyHome) and M.Risk(bot, c.loc) < K.holdRisk then
				s.campPick, bestD = c, d
			end
		end
	end
	local pick = s.campPick
	if pick == nil or (s.campEmpty[pick.key] or -1000) > p.t then return nil end
	return { intent = 'a_neutrales', to = pick.loc, reason = string.format('campamento a %d', D2(p.loc, pick.loc)) }
end

-- With the group: two or more allies together, near enough, are where the fights are about to be. Behind them by its range. OHA's
-- Sniper spends 27 % of its time pushing and defending with its team, and has damage to heroes in 28 % of the windows against 17 %
-- (presion-oha, presion6). Returns a decision or nil.
function M.Group(bot, s, p)
	if p.hp < K.fightHp then return nil end
	local allies = {}
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Valid(a) and not a:IsIllusion() and D2(p.loc, a:GetLocation()) < K.groupReach then table.insert(allies, a) end
	end
	local best, bestN = nil, 1
	for _, a in ipairs(allies) do
		local n = 0
		for _, o in ipairs(allies) do
			if D2(a:GetLocation(), o:GetLocation()) < K.groupNear then n = n + 1 end
		end
		if n > bestN then best, bestN = a, n end
	end
	if best == nil then return nil end
	local spot = Toward(best:GetLocation(), GetAncient(p.team):GetLocation(), K.groupBehind)
	if D2(p.loc, spot) < K.groupThere then return nil end
	for _, tw in ipairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS) or {}) do
		if tw ~= nil and not tw:IsNull() and tw:IsAlive() and tw:IsTower() and D2(spot, tw:GetLocation()) < K.towerMargin then return nil end
	end
	return { intent = 'con_el_grupo', to = spot, reason = string.format('%d aliados juntos, a %d', bestN, D2(p.loc, spot)) }
end

-- Our nearest standing tower, wherever it is: a retreat does not cross the map to the lane it came to play.
function M.NearestTower(loc)
	local best, bestD = nil, 1e9
	for _, t in ipairs(GetUnitList(UNIT_LIST_ALLIED_BUILDINGS) or {}) do
		if t ~= nil and not t:IsNull() and t:IsAlive() and t:IsTower() then
			local d = D2(loc, t:GetLocation())
			if d < bestD then best, bestD = t, d end
		end
	end
	return best
end

-- The tower to run to: the nearest one that does not lead through them: none with an enemy near us who stands closer to it than
-- we are. Nil means the fountain.
function M.RetreatTower(bot, s, p)
	-- The same tower through the whole flight: an enemy running beside it made the choice jump between two.
	local kept = s.retreatTower
	if kept ~= nil and not kept:IsNull() and kept:IsAlive() then return kept end
	local best, bestD = nil, 1e9
	for _, t in ipairs(GetUnitList(UNIT_LIST_ALLIED_BUILDINGS) or {}) do
		if t ~= nil and not t:IsNull() and t:IsAlive() and t:IsTower() then
			local d = D2(p.loc, t:GetLocation())
			if d < bestD then
				local blocked = false
				for _, e in ipairs(p.enemyHeroes) do
					if Valid(e) and D2(p.loc, e:GetLocation()) < K.blockNear and D2(e:GetLocation(), t:GetLocation()) < d then blocked = true end
				end
				if not blocked then best, bestD = t, d end
			end
		end
	end
	s.retreatTower = best
	return best
end

-- Black King Bar when several enemies are on us.
function M.Bkb(bot, s, p)
	if bot:IsMagicImmune() or not bot:WasRecentlyDamagedByAnyHero(2.0) then return nil end
	local near = 0
	for _, e in ipairs(p.enemyHeroes) do
		if Valid(e) and D2(p.loc, e:GetLocation()) < 800 then near = near + 1 end
	end
	if near < 2 then return nil end
	local bkb = ReadyItem(bot, s, p, { 'item_black_king_bar' })
	if bkb == nil then return nil end
	return { intent = 'usar_objeto', item = bkb, reason = string.format('%d enemigos encima', near) }
end

return M
