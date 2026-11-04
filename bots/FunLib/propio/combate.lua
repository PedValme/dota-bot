-- dota-bot's own bot: kills, chases, runes and rotations of the laning phase (phase 1, DECISIONES 2026-11-03: «buscar
-- kill, perseguir pertinentemente, moverse de línea»). Each rule returns a decision with its reason, or nil; a chase
-- keeps its state in s.chase and ends with a logged reason (kill, lost sight, tower, danger, too long, too far).
-- Damage estimates are Valve's own (GetEstimatedDamageToTarget: attacks and abilities, mana and cooldowns included).
local C = {}

local K = {
	killMargin = 1.15,    -- go for a kill when our side's 4 s damage is this many times the target's health
	window = 4.0,         -- seconds of damage counted for a kill
	alliesRadius = 1200,  -- allies this close to the target help with their own estimate
	minHp = 0.35,         -- never start a kill below this health fraction
	dangerShare = 0.60,   -- abort if the other enemy heroes near can deal this share of our health in 3 s
	towerSafe = 800,      -- a target this close to its tower is not chased unless it dies to one more hit
	chaseMax = 8.0,       -- seconds a chase may last
	chaseLost = 1.5,      -- seconds without seeing the target before giving up
	chaseFar = 1400,      -- give up when the target gets this far away
	rotateMin = 1200,     -- a kill farther than this from us is a rotation (moving out of the lane)... (below chaseFar,
	                      -- or a rotation would end as "far" the moment it arrives: review of 2026-11-03)
	banAfter = 12,        -- seconds a target is not chased again after a chase that ended without a kill
	rotateMax = 4500,     -- ...and is only considered up to this distance
	rotateTravel = 12,    -- seconds of walking allowed to reach a rotation
	runeReach = 1800,     -- runes are checked only this close
	runeNear = 700,       -- with a wave to farm, only a rune this close is worth it
}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

local function VisibleEnemies()
	local list = {}
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsInvulnerable() then table.insert(list, e) end
	end
	return list
end

-- Towers count even in the fog (a dive check that only sees visible towers dives into fogged ones).
local function NearestEnemyTower(loc)
	local best, dist = nil, 1e9
	for _, tw in ipairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS) or {}) do
		if tw ~= nil and not tw:IsNull() and tw:IsAlive() and tw:IsTower() then
			local d = D2(loc, tw:GetLocation())
			if d < dist then best, dist = tw, d end
		end
	end
	return best, dist
end

-- Our side's damage on the target in the window: ours plus that of allied heroes near it.
local function SideDamage(bot, e)
	local total = bot:GetEstimatedDamageToTarget(true, e, K.window, DAMAGE_TYPE_ALL)
	local helpers = 0
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Seen(a) and D2(a:GetLocation(), e:GetLocation()) < K.alliesRadius then
			total = total + a:GetEstimatedDamageToTarget(true, e, K.window, DAMAGE_TYPE_ALL)
			helpers = helpers + 1
		end
	end
	return total, helpers
end

-- Damage the enemy heroes other than the target, near us or near the target (where a chase or rotation leads), can
-- deal to us in 3 s.
local function OthersBurst(bot, target, loc)
	local dmg = 0
	local tloc = target:GetLocation()
	for _, o in ipairs(VisibleEnemies()) do
		if o ~= target and (D2(loc, o:GetLocation()) < 1400 or D2(tloc, o:GetLocation()) < 1200) then
			dmg = dmg + o:GetEstimatedDamageToTarget(true, bot, 3.0, DAMAGE_TYPE_ALL)
		end
	end
	return dmg
end

-- Why the target cannot be attacked safely now (nil when it can).
local function Unsafe(bot, p, e)
	if p.hp < K.minHp then return string.format('vida %.2f < %.2f', p.hp, K.minHp) end
	local burst = OthersBurst(bot, e, p.loc)
	if burst > K.dangerShare * p.hpAbs then return string.format('otros_enemigos %d > %.0f%% de %d', burst, K.dangerShare * 100, p.hpAbs) end
	local tower, td = NearestEnemyTower(e:GetLocation())
	if tower ~= nil and td < K.towerSafe then
		local oneHit = e:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
		if e:GetHealth() > oneHit then return string.format('objetivo bajo su torre (%d)', td) end
	end
	return nil
end

local function Ends(bot, s, p, why)
	local c = s.chase
	local kills = GetHeroKills(bot:GetPlayerID()) - c.kills0
	s.lastChaseEnd = p.now
	s.chase = nil
	-- The attack order goes on by itself: the next action must cancel it (linea.lua, Act). A chase without a kill
	-- bans its target for a while, or it would restart two seconds later.
	s.stopAttack = true
	if kills == 0 then
		s.chaseBan = s.chaseBan or {}
		s.chaseBan[c.name] = p.now + K.banAfter
	end
	return string.format('%s %s duró %.1fs kills+%d motivo=%s', c.kind, c.name, p.now - c.since, kills, why)
end

-- Ends the current chase from outside (a retreat); returns its log line.
function C.Stop(bot, s, p, why) return Ends(bot, s, p, why) end

-- Continues or ends the current chase; returns (decision or nil, end line or nil).
function C.Continue(bot, s, p)
	local c = s.chase
	if c == nil then return nil, nil end
	local e = c.target
	if GetHeroKills(bot:GetPlayerID()) > c.kills0 then return nil, Ends(bot, s, p, 'kill') end
	if e == nil or e:IsNull() or not e:IsAlive() then return nil, Ends(bot, s, p, 'objetivo_muerto') end
	if Seen(e) then c.seenAt = p.now end
	if p.now - c.seenAt > K.chaseLost then return nil, Ends(bot, s, p, 'perdido_de_vista') end
	local limit = c.kind == 'rotar' and (K.rotateTravel + K.chaseMax) or K.chaseMax
	if p.now - c.since > limit then return nil, Ends(bot, s, p, 'demasiado_larga') end
	if not Seen(e) then
		return { intent = c.kind, target = e, to = c.lastLoc, reason = 'sigo a ' .. c.name .. ' (sin verlo)' }, nil
	end
	local d = D2(p.loc, e:GetLocation())
	if c.kind == 'matar' and d > K.chaseFar then return nil, Ends(bot, s, p, string.format('lejos %d', d)) end
	local why = Unsafe(bot, p, e)
	if why then return nil, Ends(bot, s, p, why) end
	local myTower, mtd = NearestEnemyTower(p.loc)
	if myTower ~= nil and mtd < 750 and e:GetHealth() > e:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL) then
		return nil, Ends(bot, s, p, 'me_meteria_bajo_torre')
	end
	c.lastLoc = e:GetLocation()
	if c.kind == 'rotar' and d < K.rotateMin then c.kind = 'matar' c.since = p.now end
	return { intent = c.kind, target = e, reason = string.format('%s vida %d a %d', c.name, e:GetHealth(), d) }, nil
end

-- What a kill on this enemy looks like now: the numbers Start() decides on.
local function Evaluate(bot, p, e, d)
	local dmg, helpers = SideDamage(bot, e)
	local travel = math.max(0, d - p.range) / math.max(p.moveSpeed, 1)
	return { dmg = dmg, helpers = helpers, score = dmg / math.max(e:GetHealth(), 1), travel = travel,
		kind = d > K.rotateMin and 'rotar' or 'matar',
		-- The damage window starts when we arrive: walking time asks for a bigger margin.
		margin = K.killMargin * (1 + travel / K.window) }
end

-- One line per second with an enemy hero within 1500, whatever rule is deciding: why a kill does not start, or does
-- (no line of the log said it, trabajo/fase1-plan.md). Returns the lines to log.
function C.KillEval(bot, s, p)
	if p.now - (s.killEvalAt or -1000) < 1 then return nil end
	local lines = nil
	for _, e in ipairs(VisibleEnemies()) do
		local d = D2(p.loc, e:GetLocation())
		if d <= 1500 then
			s.killEvalAt = p.now
			local v = Evaluate(bot, p, e, d)
			local unsafe = Unsafe(bot, p, e)
			local banned = s.chaseBan ~= nil and (s.chaseBan[Short(e)] or -1000) > p.now
			local veto = (banned and 'veto_reciente') or (v.score < v.margin and 'margen') or (unsafe and 'inseguro') or '-'
			lines = lines or {}
			table.insert(lines, string.format('objetivo=%s vida=%d dist=%d dmg4s=%d aliados=%d score=%.2f margen=%.2f veto=%s intencion=%s unsafe=%s',
				Short(e), e:GetHealth(), d, v.dmg, v.helpers, v.score, v.margin, veto, s.intent, unsafe or '-'))
		end
	end
	return lines
end

-- Starts a kill (in reach) or a rotation (farther), when our side's damage kills it and it is safe.
function C.Start(bot, s, p)
	if p.now - (s.lastChaseEnd or -1000) < 2 then return nil end
	-- Many damage estimates per check (each enemy, each ally near it): four times a second is enough.
	if p.now - (s.killCheckAt or -1000) < 0.25 then return nil end
	s.killCheckAt = p.now
	local best, bestScore = nil, 0
	for _, e in ipairs(VisibleEnemies()) do
		local d = D2(p.loc, e:GetLocation())
		local banned = s.chaseBan ~= nil and (s.chaseBan[Short(e)] or -1000) > p.now
		if d <= K.rotateMax and not banned then
			local v = Evaluate(bot, p, e, d)
			if v.score >= v.margin and (v.kind == 'matar' or (v.travel <= K.rotateTravel and p.hp > 0.6))
				and Unsafe(bot, p, e) == nil and v.score > bestScore then
				best, bestScore = { e = e, d = d, dmg = v.dmg, helpers = v.helpers, kind = v.kind }, v.score
			end
		end
	end
	if best == nil then return nil end
	local e = best.e
	s.chase = { target = e, name = Short(e), kind = best.kind, since = p.now, seenAt = p.now, lastLoc = e:GetLocation(),
		kills0 = GetHeroKills(bot:GetPlayerID()) }
	return { intent = best.kind, target = e, start = true,
		reason = string.format('%s vida %d, daño de mi lado en %.0fs %d (x%.2f, %d aliados) a %d', s.chase.name,
			e:GetHealth(), K.window, best.dmg, bestScore, best.helpers, best.d) }
end

-- Runes: a visible rune near is picked up; at a power rune's spawn time (every 2 min from 6:00, as in normal Dota,
-- which the imitated Turbo keeps: ESTADO, known problems) the nearer power rune spot is checked if the lane allows.
-- A rune spot with a visible enemy hero near it is not worth the walk.
local function SpotSafe(loc)
	for _, e in ipairs(VisibleEnemies()) do
		if D2(loc, e:GetLocation()) < 1200 then return false end
	end
	return true
end

-- Runes never take the hero from a wave it can farm (fase1c/d: 24-34 s away from the lane up to minute 10, just when
-- the gap against OHA opens): with enemy creeps in reach only a rune very close counts, and no trip to wait for one.
local function WaveInReach(p)
	for _, c in ipairs(p.enemyCreeps) do
		if c ~= nil and not c:IsNull() and c:IsAlive() and D2(p.loc, c:GetLocation()) < p.range + 300 then return true end
	end
	return false
end

function C.Rune(bot, s, p)
	local wave = WaveInReach(p)
	local best, bestD = nil, wave and K.runeNear or K.runeReach
	for _, r in ipairs({ RUNE_POWERUP_1, RUNE_POWERUP_2, RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4 }) do
		local loc = GetRuneSpawnLocation(r)
		local d = D2(p.loc, loc)
		if GetRuneStatus(r) == RUNE_STATUS_AVAILABLE and d < bestD and SpotSafe(loc) then best, bestD = r, d end
	end
	if best ~= nil then
		return { intent = 'runa', rune = best, to = GetRuneSpawnLocation(best),
			reason = string.format('runa %d disponible a %d', best, bestD) }
	end
	local t = p.t
	if not wave and (t >= 355 and (t - 360) % 120 >= 110 or (t >= 360 and (t - 360) % 120 < 10)) then
		local spot, sd = nil, K.runeReach
		-- Before the spawn the spot reads MISSING (empty): that is exactly when to go; after it, the branch above.
		local spawned = t >= 360 and (t - 360) % 120 < 10
		for _, r in ipairs({ RUNE_POWERUP_1, RUNE_POWERUP_2 }) do
			local loc = GetRuneSpawnLocation(r)
			local d = D2(p.loc, loc)
			if d < sd and SpotSafe(loc) and not (spawned and GetRuneStatus(r) == RUNE_STATUS_MISSING) then spot, sd = r, d end
		end
		if spot ~= nil then
			return { intent = 'ir_a_runa', to = GetRuneSpawnLocation(spot),
				reason = string.format('runa de poder %d por aparecer, a %d', spot, sd) }
		end
	end
	return nil
end

return C
