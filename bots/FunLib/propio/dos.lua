-- dota-bot's own bot: the lane of two as one unit (trabajo/plan-mejora-equipo.md, «Estudio de OHA»; Pedro, 2026-11-13: «Estudiar a
-- OHA y reescribir la línea de dos»). Written anew for the safe lane (positions 1 and 5) and the hard one (3 and 4) while the lane
-- lasts; the lone mid and the middle game keep their rules (linea.lua, combate.lua, medio.lua).
--
-- What OHA's winning pairs do in the fine record (12 lanes of two, MEDICIONES 2026-11-13, oha-dos-*), and so what this does:
-- - they stay together, some 600-700 apart, 100-400 ahead of their wave: the support keeps near its core (Spot);
-- - they go in both at once, at full health: both hit in 78-95 % of their kill fights, their first spells 1 s apart; here the PAIR
--   decides one entry on one target (the board), and both open on it in the same second with their hero's KillCast;
-- - they chase: the entry holds while the pair's numbers still give it, not one hero's;
-- - what loses (OHA's own safe lane, 9,2 deaths a lane): dying at 90 % health 10 s before, to the two enemies with no ally near, after
--   hitting a hero alone, already retreating. Here no hero is hit by one of ours without the partner near (partnerNear), and when the
--   enemies that reach us can take most of the weaker one's health, the pair leaves together before the hits land ('salir').
-- Hard safety stays in linea.lua (tower aggro, health under 0,30, sustained damage, the fountain, salves, teleport); the soft
-- retreats of the 1 against 1 (burst, exposed, lost trade and their holds) yield to the pair for these heroes.
--
-- One decider per pair (the lower player id of those playing the lane), so the board does not flip between two views; the other
-- decides only when it is alone. Thresholds: assumptions from the study, not tuned; they change only for a rule failure seen in the
-- log (DECISIONES 2026-11-06). Each change of the board is logged as "[bench] prop dos ..." with its reason. Reviewed by Opus on
-- 2026-11-13 before its first smoke (oscillation between entering and leaving, entries left hanging, the partner's own safety, leaving
-- forever before two enemies, one decider, sight margin and bans, the support's spot).
local D = {}

local out = BenchRawPrint or print
local Heroes = require(GetScriptDirectory()..'/FunLib/propio/heroes')
local Intercambio = require(GetScriptDirectory()..'/FunLib/propio/intercambio')
local Combate = require(GetScriptDirectory()..'/FunLib/propio/combate')
local Pareja = require(GetScriptDirectory()..'/FunLib/propio/pareja')

local K = {
	pairNear = 800,     -- the partner this close (alive, seen) makes hitting a hero allowed: OHA's pairs fight 573-673 apart
	follow = 600,       -- the support stays this close to its core (OHA: 520-740)
	enterHp = 0.5,      -- each of ours at or above this to go in (OHA's kill fights start at 94-100 %)
	entryMax = 8,       -- seconds an entry may last: combate.lua's chaseMax, so the chases and the entry end together
	sightLost = 1.5,    -- an entry ends after this long without seeing its target (combate.lua's chaseLost)
	banAfter = 12,      -- seconds a target is not entered again after an entry that ended without a kill (combate.lua's banAfter)
	leaveShare = 0.6,   -- leave together when the enemies that reach us could take this share of our weaker hero's health in 3 s;
	                    -- also the gate to enter (under it), so entering and leaving cannot flip on the same reading
	leaveHold = 3,      -- stay out this long after it stops being true...
	leaveMax = 8,       -- ...but at most this long in a row (linea.lua's holdOutMax: two nukers in lane read as danger at full health)
	leaveRest = 4,      -- ...and then not again for this long
	reachWalk = 0.5,    -- an enemy reaches a hero within its attack range or a ready spell's range plus this many seconds walking
	reachCap = 1200,    -- cast ranges above this (global ultimates) count as this
	enemyAround = 1600, -- enemy heroes this close to one of ours are the lane's
	evalEvery = 0.25,   -- the pair's board is decided at most this often
	joinMax = 1400,     -- one of ours this far from the target does not join the entry
	-- The race (dos-humo: combate.lua's 4 s kill estimate stayed under half its margin in 80 % of the readings with an enemy within
	-- 900, so the pair entered 10 times in two matches, while OHA goes in on rivals at 91-95 % of health and wins by chasing 15-21 s).
	raceWindow = 10,    -- seconds of the race: our damage on the target against the enemies' on the weaker of ours
	raceKill = 1.0,     -- enter when our damage in the window takes the target's health...
	raceEdge = 1.3,     -- ...and our share of its health is this many times their share of our weaker one's
	raceKeep = 0.8,     -- an entry holds while our share stays at this or more
	lockCap = 4,        -- our lock seconds on the target, at most this, take its own damage out of the race
}

-- team -> lane -> board: { mode = 'linea'|'entrar'|'salir', target, name, pid, id, since, untilT, why, decidedAt, seenAt, ban, ... }
local BOARD = {}
local seq = 0

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end
local function Toward(from, to, dist)
	local d = D2(from, to)
	if d < 1 then return from end
	return Vector(from.x + (to.x - from.x) * dist / d, from.y + (to.y - from.y) * dist / d, from.z)
end
local function Log(bot, text)
	out(string.format('[bench] prop dos t=%.1f pid=%d %s', DotaTime(), bot:GetPlayerID(), text))
end

local PARTNER_POS = { [1] = 5, [5] = 1, [3] = 4, [4] = 3 }

-- The allied hero of the same lane of two, alive or dead (nil when there is none: mid, or a hero without our module).
local function Partner(bot)
	local pos = Heroes.Datos(bot:GetUnitName()).pos
	local want = pos and PARTNER_POS[pos]
	if want == nil then return nil end
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and not a:IsIllusion() and Heroes.Datos(a:GetUnitName()).pos == want then return a end
	end
	return nil
end

local function Board(lane)
	local team = GetTeam()
	BOARD[team] = BOARD[team] or {}
	BOARD[team][lane] = BOARD[team][lane] or { mode = 'linea', id = 0, decidedAt = -1000, untilT = -1000, ban = {}, restUntil = -1000 }
	return BOARD[team][lane]
end

-- How far an enemy reaches now: its attack range, or the range of a spell ready to cast, plus half a second walking.
local function Reach(e)
	local reach = e:GetAttackRange()
	for slot = 0, 5 do
		local ab = e:GetAbilityInSlot(slot)
		if ab ~= nil and not ab:IsPassive() and ab:IsFullyCastable() then
			reach = math.max(reach, math.min(ab:GetCastRange() or 0, K.reachCap))
		end
	end
	return reach + K.reachWalk * e:GetCurrentMovementSpeed()
end

-- The damage the visible enemies that reach `h` now can deal to it in 3 s.
local function ThreatOn(h, enemies)
	local dmg = 0
	for _, e in ipairs(enemies) do
		if D2(e:GetLocation(), h:GetLocation()) <= Reach(e) then dmg = dmg + Intercambio.Threat(e, h, 3.0) end
	end
	return dmg
end

-- The lane's enemy heroes: visible, one per hero (illusions apart), near one of ours.
local function LaneEnemies(ours)
	local list = {}
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsIllusion() then
			for _, h in ipairs(ours) do
				if D2(e:GetLocation(), h:GetLocation()) <= K.enemyAround then table.insert(list, e) break end
			end
		end
	end
	return Intercambio.OnePerHero(ours[1]:GetLocation(), list)
end

local function HitsIn(a, e, seconds)
	if seconds <= 0 then return 0 end
	return (1 + math.floor(seconds / math.max(a:GetSecondsPerAttack(), 0.1))) * e:GetActualIncomingDamage(a:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
end
local function HeroCall(a, name, view, e, window)
	local m = Heroes.MODULES[a:GetUnitName()]
	if m == nil or m[name] == nil then return 0, 0 end
	local ok, x, y = pcall(m[name], a, view, e, window)
	if not ok then return 0, 0 end
	return x or 0, y or 0
end

-- The race on target e over raceWindow: our share (our damage, each of ours within joinMax of it: its hero's abilities and its hits
-- after casting and walking, over e's health and regeneration) and theirs (all enemies near the weaker of ours, their hits and ready
-- abilities, e's own shortened by our locks, over its health). Each hero module's KillBurst and Disable give the abilities.
local function Race(bot, p, mate, e, enemies, weakest, weakHp)
	local W = K.raceWindow
	local us, lock = 0, 0
	for _, h in ipairs({ bot, mate or false }) do
		if h and D2(h:GetLocation(), e:GetLocation()) <= K.joinMax then
			local view = h == bot and p or { loc = h:GetLocation(), range = h:GetAttackRange(), now = p.now, enemyHeroes = p.enemyHeroes }
			lock = lock + HeroCall(h, 'Disable', view, e)
			local burst, casting = HeroCall(h, 'KillBurst', view, e, W)
			local walk = math.max(0, D2(h:GetLocation(), e:GetLocation()) - h:GetAttackRange()) / math.max(h:GetCurrentMovementSpeed(), 1)
			us = us + burst + HitsIn(h, e, W - casting - walk)
		end
	end
	lock = math.min(lock, K.lockCap)
	local them = 0
	for _, o in ipairs(enemies) do
		if D2(o:GetLocation(), weakest:GetLocation()) <= Reach(o) + 600 then
			them = them + Intercambio.Threat(o, weakest, o == e and math.max(0, W - lock) or W)
		end
	end
	return us / math.max(e:GetHealth() + e:GetHealthRegen() * W, 1), them / math.max(weakHp, 1)
end

-- An ally's own safety on the target, as combate.lua's Unsafe reads it from where the ally stands.
local function MateUnsafe(mate, e)
	local hp = mate:GetHealth()
	return Combate.Unsafe(mate, { hp = hp / math.max(mate:GetMaxHealth(), 1), hpAbs = hp, loc = mate:GetLocation() }, e)
end

local function Set(bot, b, mode, why, now, target, untilT)
	local changed = b.mode ~= mode or (target ~= nil and b.name ~= Short(target))
	if changed and b.mode == 'salir' then b.leaveSince = nil end
	if changed and mode == 'salir' then b.leaveSince = now end
	b.mode, b.why = mode, why
	if changed then b.since = now end
	b.untilT = untilT or now
	if target ~= nil then
		if changed then seq = seq + 1 b.id = seq end
		b.target, b.name, b.pid, b.seenAt = target, Short(target), target:GetPlayerID(), now
	elseif mode ~= 'entrar' then
		b.target, b.name, b.pid = nil, nil, nil
	end
	if changed then Log(bot, string.format('pareja %s%s motivo=%s', mode, target and (' objetivo=' .. Short(target)) or '', why)) end
end

-- Ends the entry under way for both (a hero's chase ended by combate.lua's safety, or a retreat): 'salir' when the reason is danger,
-- else the lane. A target escaped (out of sight, too long, far, under its tower) is not entered again for banAfter.
local function EndEntry(bot, b, why, now)
	if b.mode ~= 'entrar' then return end
	local escaped = string.find(why, 'perdido_de_vista') or string.find(why, 'demasiado_larga') or string.find(why, 'lejos')
		or string.find(why, 'torre')
	if escaped and b.name ~= nil then b.ban[b.name] = now + K.banAfter end
	local danger = string.find(why, '^vida') or string.find(why, 'otros_enemigos') or string.find(why, 'moririamos')
		or string.find(why, 'retirada') or string.find(why, 'daño')
	if danger then
		Set(bot, b, 'salir', 'fin_entrada ' .. why, now, nil, now + K.leaveHold)
	else
		Set(bot, b, 'linea', 'fin_entrada ' .. why, now)
	end
end

-- The pair's decision, from the decider's view (its Perceive, p). mate: the partner when it plays the lane with us (seen, alive, not
-- in the middle game), else nil.
local function Decide(bot, s, p, mate, b)
	local ours = { bot }
	if mate then table.insert(ours, mate) end
	local enemies = LaneEnemies(ours)
	local together = mate ~= nil and D2(p.loc, mate:GetLocation()) <= K.pairNear
	local weakest, weakHp = bot, bot:GetHealth()
	if mate and mate:GetHealth() < weakHp then weakest, weakHp = mate, mate:GetHealth() end
	local threat = ThreatOn(weakest, enemies)

	-- An entry under way holds while its target is alive and seen (with combate.lua's margin), in time, the pair's score still near the
	-- margin and none of ours about to die (all that reaches the weaker one takes its whole health in 3 s).
	if b.mode == 'entrar' then
		local e = b.target
		if Seen(e) then b.seenAt = p.now end
		local why = nil
		if b.pid ~= nil and not IsHeroAlive(b.pid) then why = 'objetivo_muerto'
		elseif p.now - (b.seenAt or p.now) > K.sightLost then why = 'perdido_de_vista'
		elseif p.now > b.untilT then why = 'demasiado_larga'
		elseif threat >= weakHp then why = string.format('moririamos %s daño3s %d vida %d', Short(weakest), threat, weakHp)
		elseif Seen(e) then
			local ours, theirs = Race(bot, p, mate, e, enemies, weakest, weakHp)
			if ours < K.raceKeep then why = string.format('ya_no_da nuestro %.2f < %.2f', ours, K.raceKeep)
			elseif theirs >= 1 then why = string.format('moririamos carrera suyo %.2f', theirs) end
		end
		if why ~= nil then EndEntry(bot, b, why, p.now) end
		return
	end

	-- Leaving: the enemies that reach the weaker of ours could take most of its health and we have no kill. Capped in time, then a
	-- rest, so two nukers in lane do not keep the pair out of it for as long as they stay.
	local leaving = b.mode == 'salir' and p.now < b.untilT
	if b.mode == 'salir' and p.now - (b.leaveSince or p.now) > K.leaveMax then
		b.restUntil = p.now + K.leaveRest
		Set(bot, b, 'linea', 'salida_demasiado_larga', p.now)
		leaving = false
	end

	-- Going in, never while leaving: the enemy on which the pair wins the race (Race: our damage and our partner's,
	-- abilities and locks, against the enemies' on the weaker of ours), with each of ours near the target healthy and safe by its own reading, not more of them around
	-- the target than of us, and the enemies' reach on the weaker of ours under the leaving share. Alone (the partner dead, away or in
	-- the middle game), only an enemy with no other enemy near it.
	if not leaving then
		local best, bestScore, bestWhy = nil, 0, ''
		for _, e in ipairs(enemies) do
			local name = Short(e)
			if (b.ban[name] or -1000) <= p.now then
				local around = 0
				for _, o in ipairs(enemies) do if D2(o:GetLocation(), e:GetLocation()) <= 1200 then around = around + 1 end end
				local ours, theirs = Race(bot, p, mate, e, enemies, weakest, weakHp)
				local score = ours / math.max(theirs, 0.1)
				local ok = D2(p.loc, e:GetLocation()) <= K.joinMax and ours >= K.raceKill and theirs < 1 and score >= K.raceEdge
					and p.hp >= K.enterHp and Combate.Unsafe(bot, p, e) == nil and threat < K.leaveShare * weakHp
				if ok and mate ~= nil and D2(mate:GetLocation(), e:GetLocation()) <= K.joinMax then
					ok = mate:GetHealth() >= K.enterHp * mate:GetMaxHealth() and MateUnsafe(mate, e) == nil
				end
				if ok and together then
					ok = around <= #ours
				elseif ok then
					ok = around <= 1
				end
				if ok and score > bestScore then best, bestScore, bestWhy = e, score, string.format('nuestro %.2f suyo %.2f', ours, theirs) end
			end
		end
		if best ~= nil then
			Set(bot, b, 'entrar', string.format('%s %s vida %d', bestWhy, together and 'juntos' or 'solo', best:GetHealth()), p.now,
				best, p.now + K.entryMax)
			return
		end
	end

	if p.now >= b.restUntil and threat >= K.leaveShare * weakHp then
		Set(bot, b, 'salir', string.format('daño3s %d sobre %s vida %d', threat, Short(weakest), weakHp), p.now, nil, p.now + K.leaveHold)
		return
	end
	if leaving then return end
	Set(bot, b, 'linea', enemies[1] and 'sin_entrada' or 'sin_rivales', p.now)
end

-- Whether this bot plays the lane of two now; returns the state linea.lua reads (p.dos) or nil. stateOf(pid): linea.lua's state of an
-- allied bot (its `late` says whether it left the lane's rules).
function D.Applies(bot, s, p, stateOf)
	if p.late then return nil end
	local partner = Partner(bot)
	if partner == nil then return nil end
	local mateState = stateOf(partner:GetPlayerID())
	local mate = Seen(partner) and not (mateState ~= nil and mateState.late) and partner or nil
	local b = Board(s.lane)
	-- One decider: the lower player id of the two while both play the lane; alone, this one.
	local decider = mate == nil or bot:GetPlayerID() < partner:GetPlayerID()
	if decider and p.now - b.decidedAt >= K.evalEvery then
		b.decidedAt = p.now
		Decide(bot, s, p, mate, b)
	end
	local near = mate ~= nil and D2(p.loc, mate:GetLocation()) <= K.pairNear
	return { partner = partner, mate = mate, partnerNear = near, board = b,
		support = Heroes.Datos(bot:GetUnitName()).rol == 'apoyo' }
end

-- A retreat of this hero (linea.lua) or the end of its chase ends the pair's entry for both.
function D.End(bot, s, p, why)
	if p.dos == nil then return end
	EndEntry(bot, p.dos.board, why, p.now)
end

local function StopChase(bot, s, p, why)
	if s.chase ~= nil then Log(bot, 'persecucion ' .. Combate.Stop(bot, s, p, why)) end
end

-- The pair's action for this bot: an entry (a chase on the board's target, opened with the hero's KillCast by linea.lua), a step out
-- of the enemies' reach, or nil (the lane: last hits and Spot).
function D.Act(bot, s, p, home)
	local b = p.dos.board
	if b.mode == 'entrar' and b.target ~= nil and not b.target:IsNull() then
		local e = b.target
		-- Its own chase of this entry ended: not again into the same one (the board ends it for both, End).
		if s.dosEnded == b.id then return nil end
		if not Seen(e) then
			-- Out of sight: combate.lua's Continue follows to the last place for its margin, if a chase is under way.
			if s.chase ~= nil and s.chase.dos == b.id then
				local r, ended = Combate.Continue(bot, s, p)
				if ended then Log(bot, 'persecucion ' .. ended) s.dosEnded = b.id EndEntry(bot, b, ended, p.now) end
				return r
			end
			return nil
		end
		local dist = D2(p.loc, e:GetLocation())
		if dist > K.joinMax then
			if s.chase ~= nil and s.chase.dos == b.id then StopChase(bot, s, p, string.format('lejos %d', dist)) s.dosEnded = b.id end
			return nil -- too far to join in time: it stays on the lane
		end
		if s.chase == nil or s.chase.dos ~= b.id then
			StopChase(bot, s, p, 'cambio_de_objetivo')
			s.chase = { target = e, name = b.name, kind = 'matar', since = p.now, seenAt = p.now, lastLoc = e:GetLocation(),
				kills0 = GetHeroKills(bot:GetPlayerID()), pid = e:GetPlayerID(), illusion = false, dos = b.id }
			Pareja.SetChase(bot, b.name)
			return { intent = 'matar', target = e, start = true, reason = string.format('pareja_entra %s (%s) a %d', b.name, b.why, dist) }
		end
		local r, ended = Combate.Continue(bot, s, p)
		if ended then
			Log(bot, 'persecucion ' .. ended)
			s.dosEnded = b.id
			EndEntry(bot, b, ended, p.now)
		end
		return r
	end
	-- Not in an entry: a chase left from one ends now (the pair left it).
	if s.chase ~= nil and s.chase.dos ~= nil then StopChase(bot, s, p, 'pareja_' .. b.mode) end
	if b.mode == 'salir' then
		-- Out of every enemy's reach (Perceive's reachNeed), together: both read the same board.
		if p.reachNeed > -100 then
			return { intent = 'alejarse', reason = 'pareja_sale ' .. (b.why or ''), to = Toward(p.loc, home, math.max(350, p.reachNeed + 100)) }
		end
		-- Already out: stay out, a short step home, not back to the creeps.
		return { intent = 'alejarse', reason = 'pareja_fuera ' .. (b.why or ''), to = Toward(p.loc, home, 80) }
	end
	return nil
end

-- Where the support stands in the lane: its own lane point (laneAt), kept within `follow` of its core. nil for the core, or when the
-- core is not in the lane. Also once there: returning nil handed it to the lane point, beyond `follow`, and it flipped every tick.
function D.Spot(bot, s, p, laneAt)
	local d = p.dos
	if not d.support or d.mate == nil then return nil end
	local core = d.mate:GetLocation()
	if D2(core, p.front) > 2500 then return nil end -- the core is not in the lane
	local spot = laneAt
	if D2(spot, core) > K.follow then spot = Toward(core, spot, K.follow) end
	return spot
end

return D
