-- dota-bot's own bot: kills, chases, runes and rotations of the laning phase (phase 1, DECISIONES 2026-11-03: «buscar
-- kill, perseguir pertinentemente, moverse de línea»). Each rule returns a decision with its reason, or nil; a chase
-- keeps its state in s.chase and ends with a logged reason (kill, lost sight, tower, danger, too long, too far).
-- The kill check and the danger are ours, from hits and abilities read live (SideDamage, intercambio.lua), not Valve's
-- estimate, which cannot be supervised. Rotations were off from 2026-11-04 (8 of 8 with no kill) and are on again with
-- their cause fixed (MayRotate, Evaluate; DECISIONES 2026-11-04, acotado el 2026-11-12).
local C = {}
local Intercambio = require(GetScriptDirectory()..'/FunLib/propio/intercambio')
local Medio = require(GetScriptDirectory()..'/FunLib/propio/medio')
-- The allies' own kill numbers (KillBurst, Disable) come from their hero modules; the lane pair's board from pareja.lua (package 2).
local Heroes = require(GetScriptDirectory()..'/FunLib/propio/heroes')
local Pareja = require(GetScriptDirectory()..'/FunLib/propio/pareja')

local K = {
	rotar = true,         -- walking out of the lane for a kill, to an enemy an ally is near (MayRotate)
	-- Going for runes. Off: from the own Think() no form of the order picks one up, standing on it with its type read
	-- (Action_, ActionQueue_ and ActionPush_PickUpRune: 0 activations, fase1g and fase1h; open defect, ESTADO), so each trip
	-- only cost farm. The same Action_PickUpRune works in OHA, from its rune mode.
	runas = false,
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
	-- Package 2, killing as a pair (trabajo/plan-mejora-equipo.md). Assumptions, not measured: no series has tuned them, and they change
	-- only for a rule failure seen in the log (DECISIONES 2026-11-06).
	lockCap = 4.0,        -- the side's lock seconds added to the window, at most this: chained locks overlap and wear off in practice
	joinRadius = 1200,    -- a partner this close to the announced target joins (the lane's width, as alliesRadius)
	joinGrace = 1.5,      -- a lock's announcement lasts its cast point and lock plus this: the time to land the hits after it
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

-- The hits a unit lands on the target in these seconds (the first one at once), by its real damage per hit.
local function HitsDamage(u, e, seconds)
	local hits = seconds > 0 and 1 + math.floor(seconds / math.max(u:GetSecondsPerAttack(), 0.1)) or 0
	return hits * e:GetActualIncomingDamage(u:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
end

-- An ally's own numbers on the target, as its hero module reads them from where the ally stands (a hero without a module adds
-- nothing). Guarded: a nil from an ally's ability must not stop our Think, and the hero with it.
local function AllyView(a, p)
	return { loc = a:GetLocation(), range = a:GetAttackRange(), now = p.now, enemyHeroes = p.enemyHeroes }
end
local function HeroCall(a, name, pa, e, window)
	local m = Heroes.MODULES[a:GetUnitName()]
	if m == nil or m[name] == nil then return 0, 0 end
	local ok, x, y = pcall(m[name], a, pa, e, window)
	if not ok then return 0, 0 end
	return x or 0, y or 0
end

-- The allied heroes that count as the pair in the lane: near the target, not retreating (linea.lua's Perceive, p.allyActive) and with
-- the health to stay. Once the lane is over, none: the middle game is package 4 (trabajo/plan-mejora-equipo.md).
local function Partners(p, e, radius)
	local list = {}
	if p.late then return list end
	for _, a in ipairs(p.allyActive or {}) do
		if Seen(a) and D2(a:GetLocation(), e:GetLocation()) < radius
			and a:GetHealth() >= K.minHp * math.max(a:GetMaxHealth(), 1) then table.insert(list, a) end
	end
	return list
end

-- The player ids of the allies that count (p.allyActive: alive, seen, not retreating), for reading the board: an announcement from a
-- partner that has since retreated or died no longer calls anyone (review of package 2).
local function ActivePids(p)
	local set = {}
	for _, a in ipairs(p.allyActive or {}) do set[a:GetPlayerID()] = true end
	return set
end

-- Our side's damage on the target in the window. In the lane, the pair (package 2): our hits and abilities, and for each allied hero
-- near the target (Partners), its abilities (its module's KillBurst) and its hits once it has walked into range; the seconds of lock
-- the side can cast now (each module's Disable) lengthen the window, since a locked target cannot walk out of the hits. Only the allies
-- already hitting it counted before, with none of their spells: `aliados=0` in 97-99 % of the evaluations and Luna's best score 0,81
-- against a margin of 1,15 to minute 12, so no kill ever started in a lane of two (fase2-humo-equipo 1 and 2). Once the lane is over,
-- as before: the hits of allies already attacking it. With no ally near, nothing changes: the lone mid Sniper has no lock, so its window
-- stays K.window. Returns the damage, helpers, our hits, our abilities' damage, the lock seconds and the window used.
local function SideDamage(bot, p, e)
	local lock, partners = 0, Partners(p, e, K.alliesRadius)
	if not p.late then
		lock = HeroCall(bot, 'Disable', p, e)
		for _, a in ipairs(partners) do lock = lock + HeroCall(a, 'Disable', AllyView(a, p), e) end
		lock = math.min(lock, K.lockCap)
	end
	local window = K.window + lock
	local burst, casting = 0, 0
	if p.hero ~= nil then burst, casting = p.hero.KillBurst(bot, p, e, window) end
	local hits = HitsDamage(bot, e, window - casting)
	local allies, helpers = 0, 0
	if not p.late then
		for _, a in ipairs(partners) do
			local aBurst, aCasting = HeroCall(a, 'KillBurst', AllyView(a, p), e, window)
			local walk = math.max(0, D2(a:GetLocation(), e:GetLocation()) - a:GetAttackRange()) / math.max(a:GetCurrentMovementSpeed(), 1)
			allies = allies + aBurst + HitsDamage(a, e, window - aCasting - walk)
			helpers = helpers + 1
		end
	else
		for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
			if a ~= bot and Seen(a) and a:GetAttackTarget() == e and D2(a:GetLocation(), e:GetLocation()) < K.alliesRadius then
				allies = allies + HitsDamage(a, e, K.window)
				helpers = helpers + 1
			end
		end
	end
	return hits + burst + allies, helpers, hits, burst, lock, window
end

-- Damage the enemy heroes other than the target, near us or near the target (where a chase or rotation leads), can
-- deal to us in 3 s.
local function OthersBurst(bot, target, loc)
	local dmg = 0
	local tloc = target:GetLocation()
	for _, o in ipairs(VisibleEnemies()) do
		if o ~= target and o:GetUnitName() ~= target:GetUnitName()
			and (D2(loc, o:GetLocation()) < 1400 or D2(tloc, o:GetLocation()) < 1200) then
			dmg = dmg + Intercambio.Threat(o, bot, 3.0)
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

local Evaluate -- defined below (the kill's numbers); a joined chase in Continue reads it too

local function Ends(bot, s, p, why)
	local c = s.chase
	local kills = GetHeroKills(bot:GetPlayerID()) - c.kills0
	s.lastChaseEnd = p.now
	s.chase = nil
	-- The attack order goes on by itself: the next action must cancel it (linea.lua, Act). A chase without a kill in which the target
	-- escaped (out of sight, too far, to its tower, too long) bans it for a while, or it would restart two seconds later; joined chases
	-- too (Join keeps Start's gates). Not after our own retreat, a death or a kill that stopped holding: the ban fell just when the rival
	-- was low, 'veto_reciente' in 33 % of the seconds with a rival at 40 % of health or less within 900 of our laner (p2 logs, package 2
	-- round 2); Start's own estimate and the 2 s wait keep those from looping. 'otros_enemigos' bans too: the other enemies' burst does
	-- not pass in 2 s, and without the ban Start restarted the same target every 2 s, each time with a new announcement (review of round
	-- 2). An illusion's chase never bans: it shares the hero's name, and the real hero would be left alone 12 s (review of round 2).
	s.stopAttack = true
	local escaped = why == 'perdido_de_vista' or why == 'demasiado_larga' or why == 'me_meteria_bajo_torre'
		or string.find(why, '^lejos') ~= nil or string.find(why, 'bajo su torre') ~= nil or string.find(why, '^otros_enemigos') ~= nil
	if kills == 0 and escaped and not c.illusion then
		s.chaseBan = s.chaseBan or {}
		s.chaseBan[c.name] = p.now + K.banAfter
	end
	-- Our kill's announcement ends with it, so the partner does not stay on a fight we left; and the board no longer shows us on it.
	if c.join == nil then Pareja.Clear(bot, 'kill', why) end
	Pareja.SetChase(bot, nil)
	return string.format('%s %s duró %.1fs kills+%d motivo=%s%s', c.kind, c.name, p.now - c.since, kills, why,
		c.join ~= nil and string.format(' pareja=%d', c.join.pid) or '')
end

-- Ends the current chase from outside (a retreat); returns its log line.
function C.Stop(bot, s, p, why) return Ends(bot, s, p, why) end

-- Continues or ends the current chase; returns (decision or nil, end line or nil).
function C.Continue(bot, s, p)
	local c = s.chase
	if c == nil then return nil, nil end
	local e = c.target
	if GetHeroKills(bot:GetPlayerID()) > c.kills0 then return nil, Ends(bot, s, p, 'kill') end
	-- Dead only by the player slot read when the chase started (c.pid): IsAlive() alone read 6 of 18 'objetivo_muerto' on heroes alive
	-- in the fog (fase1c-f), and the slot read from the handle then still gave 41 of 48 'objetivo_muerto' with no kill in the custom
	-- game's log, 15 of those targets seen alive within 3 s (p2 logs, package 2 round 2): a fogged handle does not say whose it is. A
	-- handle gone or not visible is not a death: the lost-sight rules below decide.
	if c.pid ~= nil and c.pid >= 0 and not IsHeroAlive(c.pid) then return nil, Ends(bot, s, p, 'objetivo_muerto') end
	local gone = e == nil or e:IsNull()
	if not gone and Seen(e) then c.seenAt = p.now end
	if p.now - c.seenAt > K.chaseLost then return nil, Ends(bot, s, p, 'perdido_de_vista') end
	local limit = c.kind == 'rotar' and (K.rotateTravel + K.chaseMax) or K.chaseMax
	if p.now - c.since > limit then return nil, Ends(bot, s, p, 'demasiado_larga') end
	if gone or not Seen(e) then
		return { intent = c.kind, target = (not gone) and e or nil, to = c.lastLoc, reason = 'sigo a ' .. c.name .. ' (sin verlo)' }, nil
	end
	local d = D2(p.loc, e:GetLocation())
	if c.kind == 'matar' and d > K.chaseFar then return nil, Ends(bot, s, p, string.format('lejos %d', d)) end
	local why = Unsafe(bot, p, e)
	if why then return nil, Ends(bot, s, p, why) end
	-- A joined chase lasts while a partner's announcement on that target is live, read again each tick from the board: a partner that
	-- retreats or dies ends its kill's announcement (Ends, Pareja.Clear) and its locks stop counting (ActivePids), so the hero is not
	-- left on a fight the partner has left (review of package 2: the end it had at the join kept it there up to 8 s). With none live,
	-- the normal rules: outnumbered around us (package 1's p.alone, as Start) or the kill no longer holding by our own numbers ends it.
	if c.join ~= nil and Pareja.Until(bot, c.name, p.now, ActivePids(p)) == nil then
		if p.alone then return nil, Ends(bot, s, p, string.format('fin_de_pareja superado %d enemigos, %d de los nuestros', p.nEnemyNear or 0, p.nAllyNear or 0)) end
		local v = Evaluate(bot, p, e, d)
		if v.score < v.margin then
			return nil, Ends(bot, s, p, string.format('fin_de_pareja x%.2f < %.2f', v.score, v.margin))
		end
	end
	local myTower, mtd = NearestEnemyTower(p.loc)
	if myTower ~= nil and mtd < 750 and e:GetHealth() > e:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL) then
		return nil, Ends(bot, s, p, 'me_meteria_bajo_torre')
	end
	c.lastLoc = e:GetLocation()
	if c.kind == 'rotar' and d < K.rotateMin then
		c.kind, c.since = 'matar', p.now
		Pareja.SetChase(bot, c.name) -- now a lane kill: the partner's C.Committed reads it
	end
	return { intent = c.kind, target = e, reason = string.format('%s vida %d a %d', c.name, e:GetHealth(), d) }, nil
end

-- Walking out for a kill, only to an enemy an ally is already near, as OHA's early kills away from mid come in a group (9 of 9 after
-- TEAM_ROAM, ROAM or DEFEND_TOWER, ref-oha and base2-oha). Off on 2026-11-04 (8 of 8 with no kill: it chose targets the allies were
-- already killing); on again with that cause fixed in Evaluate (DECISIONES 2026-11-04, acotado el 2026-11-12).
local function MayRotate(bot, s, e)
	if not K.rotar then return false end
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Seen(a) and not a:IsIllusion() and D2(a:GetLocation(), e:GetLocation()) < K.alliesRadius then return true end
	end
	return false
end

-- What a kill on this enemy looks like now: the numbers Start() decides on.
Evaluate = function(bot, p, e, d)
	local dmg, helpers, hits, burst, lock, window = SideDamage(bot, p, e)
	local travel = math.max(0, d - p.range) / math.max(p.moveSpeed, 1)
	-- The allies keep hitting while we walk: the health left when we arrive. Scoring the health now made it rotate to the targets
	-- the allies were killing (12 of 18 'objetivo_muerto' died to another 0-3 s later, scores x7 to x236; fase1c-f).
	local allyDmg = dmg - hits - burst
	-- Every ally near it, not only those attacking it: they kill with spells too, and 11 of 15 rotations still ended 'objetivo_muerto'
	-- with '0 aliados' in the count (paquete1).
	local nearDmg = 0
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Seen(a) and not a:IsIllusion() and D2(a:GetLocation(), e:GetLocation()) < K.alliesRadius then nearDmg = nearDmg + HitsDamage(a, e, K.window) end
	end
	allyDmg = math.max(allyDmg, nearDmg)
	-- Spread over the window it was counted in (longer with the side's locks), so a lock does not make the allies hit faster.
	local hpArrive = e:GetHealth() - allyDmg * travel / window
	-- Up to chaseFar it is the lane's kill, not a rotation: 10 vetoes on the mid rival at 1.221-1.498 with the score above the margin
	-- (build2, to min 10).
	return { dmg = dmg, helpers = helpers, hits = hits, burst = burst, lock = lock, window = window,
		score = dmg / math.max(hpArrive, 1), travel = travel,
		withoutMe = travel > 0 and hpArrive <= 0,
		kind = d > K.chaseFar and 'rotar' or 'matar',
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
			local veto = (banned and 'veto_reciente') or (v.withoutMe and 'lo_matan_sin_mi') or (v.score < v.margin and 'margen')
				or (p.alone and 'superado') or (unsafe and 'inseguro')
				or (v.kind == 'rotar' and not (MayRotate(bot, s, e) and v.travel <= K.rotateTravel and p.hp > 0.6) and 'rotacion') or '-'
			lines = lines or {}
			-- intencion: the previous decision's. veto=- is not "it starts": the rules before Start() may still win.
			local trade = Intercambio.Eval(bot, p, e)
			-- dmg4s keeps its name for the readers of earlier logs; it is the damage in `ventana` seconds (4 plus the side's locks,
			-- `bloqueo`, in the lane: package 2).
			table.insert(lines, string.format('objetivo=%s ilusion=%d vida=%d dist=%d dmg4s=%d golpes=%d habilidades=%d aliados=%d score=%.2f margen=%.2f veto=%s intencion=%s ratio=%.2f mi_dps=%d su_dps=%d altura=%d fuera_de_alcance=%s unsafe=%s bloqueo=%.1f ventana=%.1f',
				Short(e), e:IsIllusion() and 1 or 0, e:GetHealth(), d, v.dmg, v.hits, v.burst, v.helpers, v.score, v.margin, veto,
				s.intent, trade.ratio, trade.mine, trade.against, trade.height, tostring(trade.outranged), unsafe or '-', v.lock, v.window))
		end
	end
	return lines
end

-- Whether we would die first: the visible enemies that reach us (linea.lua's Perceive, p.enemyBurst) take our whole health in 3 s. The
-- one danger that still ends a pair's kill under way (C.Committed, linea.lua's RuleRetreat), and so the one that keeps it from starting
-- (Start, Join): a kill must not start where the retreat would cut it at once (package 2 round 2).
-- The heroes' readings miss what p.dps measures (the health really lost over the last 2 s): creeps, and damage over time already on us.
-- The worse of the two counts (review of round 2).
local function DiesFirst(p)
	return math.max(p.enemyBurst or 0, 3 * (p.dps or 0)) >= p.hpAbs
end
C.DiesFirst = DiesFirst

-- Whether a pair's lane kill is under way and still given by the numbers: our chase is a kill ('matar'), its target in sight, a partner
-- near it chasing the same target (its chase on the board, pareja.lua: one merely near may be farming; review of round 2), and Evaluate
-- still over the margin. Then the soft retreats (a trade lost to the other enemy, 'expuesto', the 3 s burst over 80 %) yield to it
-- unless we would die first: they ended 51 of 129 lane chases whose score was a kill, 17 of them a trade lost to the enemy that was not
-- the target (p2 logs, e.g. p2-c t=75.9: the target at 14 of health, Lion out by the burst and Dragon Knight by the trade with the
-- other). Only with that partner, so the lone mid's kills keep their rules. Read at most four times a second per chase (Evaluate is the
-- costly part).
function C.Committed(bot, s, p)
	local c = s.chase
	if p.late or c == nil or c.kind ~= 'matar' or not Seen(c.target) then return false end
	if s.commitFor == c and p.now - (s.commitAt or -1000) < 0.25 then return s.commitOk end
	local e = c.target
	local ok = false
	for _, a in ipairs(Partners(p, e, K.joinRadius)) do
		if Pareja.Chasing(a:GetPlayerID()) == c.name then ok = true break end
	end
	if ok then
		local v = Evaluate(bot, p, e, D2(p.loc, e:GetLocation()))
		ok = v.score >= v.margin
	end
	s.commitFor, s.commitAt, s.commitOk = c, p.now, ok
	return ok
end

-- Starts a kill (in reach) or a rotation (farther), when our side's damage kills it and it is safe.
function C.Start(bot, s, p)
	if p.now - (s.lastChaseEnd or -1000) < 2 then return nil end
	-- Outnumbered in the lane (linea.lua, Perceive: p.alone), no kill starts: 8 of 16 deaths in the safe lane came some 2 s after an
	-- attack of our own, alone, with the second enemy near (trabajo/plan-mejora-equipo.md, package 1). A sure kill still goes: the
	-- hero's Finish runs before this.
	if p.alone then return nil end
	-- Many damage estimates per check (each enemy, each ally near it): four times a second is enough.
	if p.now - (s.killCheckAt or -1000) < 0.25 then return nil end
	s.killCheckAt = p.now
	local best, bestScore = nil, 0
	for _, e in ipairs(VisibleEnemies()) do
		local d = D2(p.loc, e:GetLocation())
		local banned = s.chaseBan ~= nil and (s.chaseBan[Short(e)] or -1000) > p.now
		-- No chase on a known illusion: its player slot is its owner's, so its death never read 'objetivo_muerto' and the chase
		-- ended banning the real hero (review of round 2).
		if d <= K.rotateMax and not banned and not e:IsIllusion() then
			local v = Evaluate(bot, p, e, d)
			if not v.withoutMe and v.score >= v.margin and Medio.MayStart(bot, s, v.score, v.margin)
				and (v.kind == 'matar' or (MayRotate(bot, s, e) and v.travel <= K.rotateTravel and p.hp > 0.6))
				and Unsafe(bot, p, e) == nil and v.score > bestScore
				-- A pair's kill only where the retreat would not cut it at once (DiesFirst, as C.Committed): 23 cut chases had started
				-- under 0,65 of health (package 2 round 2). Without a partner near the target, as before.
				and not (v.kind == 'matar' and not p.late and DiesFirst(p) and #Partners(p, e, K.joinRadius) > 0) then
				best, bestScore = { e = e, d = d, dmg = v.dmg, helpers = v.helpers, kind = v.kind, lock = v.lock, window = v.window }, v.score
			end
		end
	end
	if best == nil then return nil end
	local e = best.e
	-- pid: the player slot, read now that it is in sight; Continue tells a death by it alone (a fogged handle does not say whose it is).
	s.chase = { target = e, name = Short(e), kind = best.kind, since = p.now, seenAt = p.now, lastLoc = e:GetLocation(),
		kills0 = GetHeroKills(bot:GetPlayerID()), pid = e:GetPlayerID(), illusion = e:IsIllusion() }
	if best.kind == 'matar' then Pareja.SetChase(bot, s.chase.name) end
	-- A lane kill with a partner near the target is announced, so the partner opens with us (Join) instead of going on farming.
	if best.kind == 'matar' and not p.late and #Partners(p, e, K.joinRadius) > 0 then
		Pareja.Announce(bot, e, 'kill', p.now + K.chaseMax, p.now,
			string.format('kill x%.2f, %d aliados, bloqueo %.1fs', bestScore, best.helpers, best.lock))
	end
	return { intent = best.kind, target = e, start = true,
		-- The text before package 2 (`en 4s <daño>`, which tools/analisis/revision-2026-11-04/a6.mjs reads), then the window the damage
		-- was counted in (4 s plus the side's locks, in the lane) and the locks.
		reason = string.format('%s vida %d, daño de mi lado en %.0fs %d (x%.2f, %d aliados) a %d, ventana %.1fs, bloqueo %.1fs', s.chase.name,
			e:GetHealth(), K.window, best.dmg, bestScore, best.helpers, best.d, best.window, best.lock) }
end

-- Joining the partner (package 2): a live announcement on the board (pareja.lua) from an ally that started a kill, or cast a lock or an
-- opener (in a kill or in harass: Spike, Beam, Tail, Breathe Fire, Frost Blast; round 2), is answered at once, as a chase on that
-- target, so the hero's KillCast opens
-- on it in the same second (linea.lua, Decide) and Continue keeps it safe. The announcement says where and when; whether to go is ours,
-- with Start's gates (review of package 2): not within 2 s of a chase's end, not on a target banned after a failed chase, not
-- outnumbered around us (package 1's p.alone) nor around the target, not unsafe (low health, the other enemies' burst, the target under
-- its tower), and only when the pair's kill holds by our own numbers (Evaluate: score over the margin, not dead before we arrive). So
-- the ultimates KillCast may spend (Finger, Chain Frost, Elder Dragon Form) go only into a kill the estimate gives. A sure kill is still
-- the hero's Finish, which runs before. Re-checked four times a second while the announcement lives; the first refusal of each one is
-- logged, and each is joined at most once.
function C.Join(bot, s, p)
	if p.late or s.chase ~= nil or p.now - (s.lastChaseEnd or -1000) < 2 then return nil end
	if p.now - (s.joinCheckAt or -1000) < 0.25 then return nil end
	s.joinCheckAt = p.now
	s.joined, s.joinRefused = s.joined or {}, s.joinRefused or {}
	for _, call in ipairs(Pareja.Calls(bot, p.now, ActivePids(p))) do
		local e = call.target
		local d = D2(p.loc, e:GetLocation())
		-- Out of the lane's width it is not this pair's fight: no decision, no line (the board holds the other lane's too). No known
		-- illusion either (Pareja.Announce already leaves them out; review of round 2).
		if not s.joined[call.id] and d <= K.joinRadius and not e:IsIllusion() then
			-- One per hero: the API does not tell every enemy illusion from its hero (intercambio.lua, OnePerHero).
			local enemies, allies = 0, 1 + #Partners(p, e, K.joinRadius)
			for _, o in ipairs(Intercambio.OnePerHero(e:GetLocation(), VisibleEnemies())) do
				if D2(o:GetLocation(), e:GetLocation()) < K.joinRadius then enemies = enemies + 1 end
			end
			local v = Evaluate(bot, p, e, d)
			local why = nil
			if s.chaseBan ~= nil and (s.chaseBan[call.name] or -1000) > p.now then why = 'veto_reciente'
			elseif p.alone then why = string.format('superado_aqui %d enemigos, %d de los nuestros', p.nEnemyNear or 0, p.nAllyNear or 0)
			elseif enemies > allies then why = string.format('superado %d enemigos, %d de los nuestros', enemies, allies)
			elseif DiesFirst(p) then why = string.format('moriria_antes daño3s %d medido3s %d >= vida %d', p.enemyBurst, 3 * (p.dps or 0), p.hpAbs)
			elseif v.withoutMe then why = 'lo_matan_sin_mi'
			elseif v.score < v.margin then why = string.format('margen x%.2f < %.2f', v.score, v.margin)
			else why = Unsafe(bot, p, e) end
			local head = string.format('id=%d de_pid=%d tipo=%s objetivo=%s vida=%d dist=%d enemigos=%d nuestros=%d score=%.2f margen=%.2f',
				call.id, call.pid, call.kind, call.name, e:GetHealth(), d, enemies, allies, v.score, v.margin)
			if why ~= nil then
				if not s.joinRefused[call.id] then
					s.joinRefused[call.id] = true
					Pareja.Log(bot, 'no_me_uno ' .. head .. ' motivo=' .. why)
				end
			else
				s.joined[call.id] = true
				Pareja.Log(bot, 'me_uno ' .. head .. ' motivo=' .. call.why)
				s.chase = { target = e, name = call.name, kind = 'matar', since = p.now, seenAt = p.now, lastLoc = e:GetLocation(),
					kills0 = GetHeroKills(bot:GetPlayerID()), join = { id = call.id, pid = call.pid }, pid = e:GetPlayerID(), illusion = false }
				Pareja.SetChase(bot, call.name)
				return { intent = 'matar', target = e, start = true,
					reason = string.format('pareja con pid %d sobre %s (%s), vida %d a %d, x%.2f', call.pid, call.name, call.why, e:GetHealth(), d, v.score) }
			end
		end
	end
	return nil
end

-- An opening of ours on an enemy hero in the lane, with a partner near the target, goes on the board: the partner opens on it in the
-- same second (Join). For linea.lua's Act, on every cast a hero module marks as one (decision.opens: the enemy; decision.lockSec: its
-- lock, 0 for an opener that does not lock, as Lich's Frost Blast). Kind 'bloqueo' with a lock, 'apertura' without.
function C.AnnounceOpening(bot, s, p, d)
	local e = d.opens
	if p.late or not Seen(e) or e:IsIllusion() or #Partners(p, e, K.joinRadius) == 0 then return end
	local name = d.ability ~= nil and d.ability:GetName() or '?'
	local lock = d.lockSec or 0
	Pareja.Announce(bot, e, lock > 0 and 'bloqueo' or 'apertura', p.now + (d.castPoint or 0) + lock + K.joinGrace, p.now,
		string.format('%s %.1fs', name, lock))
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

C.WaveInReach = WaveInReach

function C.Rune(bot, s, p)
	if not K.runas then return nil end
	local wave = WaveInReach(p)
	local best, bestD = nil, wave and K.runeNear or K.runeReach
	for _, r in ipairs({ RUNE_POWERUP_1, RUNE_POWERUP_2, RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_BOUNTY_3, RUNE_BOUNTY_4 }) do
		local loc = GetRuneSpawnLocation(r)
		local d = D2(p.loc, loc)
		-- A far rune of unknown type (seen: available with type -1 at 1.784) is no reason to leave the lane.
		local known = d <= 300 or GetRuneType(r) ~= RUNE_INVALID
		-- One failed try (linea.lua, Act) bans the rune for a while: the near order is still not understood.
		local banned = s.runeBan ~= nil and (s.runeBan[r] or -1000) > p.now
		if GetRuneStatus(r) == RUNE_STATUS_AVAILABLE and known and not banned and d < bestD and SpotSafe(loc) then best, bestD = r, d end
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

-- For the lane of two (dos.lua): the same kill numbers and safety the pair decides on.
function C.Evaluate(bot, p, e, d) return Evaluate(bot, p, e, d) end
C.Unsafe = Unsafe

return C
