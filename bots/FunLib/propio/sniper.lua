-- dota-bot's own bot: Sniper's abilities (phase 1, trabajo/bot-propio.md). Each rule returns a decision with its
-- reason, or nil. Ranges, cast points, costs and damage are read live from the engine (GetCastRange, GetCastPoint,
-- GetSpecialValueInt), never from a table, so a patch that changes them changes the bot.
local H = {}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

-- How close another enemy may be during Assassinate's long cast: 900 alone, 500 with allies beside us, who draw them. In a team
-- fight there is always someone at 900, and it never fired there (4,0 kills at minute 25 against OHA's 13,8, presion5).
local function CastClear(bot)
	for _, a in ipairs(bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE) or {}) do
		if a ~= bot and Seen(a) and not a:IsIllusion() then return 500 end
	end
	return 900
end

-- The hits a unit lands on the target in these seconds (the first one at once), by its real damage per hit.
local function HitsDamage(u, e, seconds)
	local hits = seconds > 0 and 1 + math.floor(seconds / math.max(u:GetSecondsPerAttack(), 0.1)) or 0
	return hits * e:GetActualIncomingDamage(u:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
end

-- Whether an Assassinate on this target is wasted: it dies before the cast ends anyway, to our hits in range or to the allies already
-- hitting it, or it is teleporting away, or the engine just refused it. 38 of 91 orders never went off, and in 29 the hero stood still
-- for the whole cast (equipo2, revisión del 2026-11-08). OHA's Sniper leaves the same cases (hero_sniper.lua:536-545).
local out = BenchRawPrint or print
-- Why it was left, once per target every 5 s: the retouch cut the casts from 5,0 to 2,0 between minutes 10 and 20 with no trace of
-- which filter did it (MEDICIONES 2026-11-08, «Marcador»).
local function Left(bot, s, p, e, why)
	s.leftLog = s.leftLog or {}
	if p.now - (s.leftLog[Short(e)] or -1000) >= 5 then
		s.leftLog[Short(e)] = p.now
		out(string.format('[bench] prop habilidad t=%.1f pid=%d descarto assassinate sobre %s: %s', DotaTime(), bot:GetPlayerID(), Short(e), why))
	end
	return true
end
local function Wasted(bot, s, p, e, castPoint)
	if (s.castBan or {})[Short(e)] ~= nil and s.castBan[Short(e)] > p.now then return Left(bot, s, p, e, 'rechazado hace poco') end
	if e:HasModifier('modifier_teleporting') then return Left(bot, s, p, e, 'se teletransporta') end
	local hp, others = e:GetHealth(), 0
	if D2(p.loc, e:GetLocation()) <= p.range and HitsDamage(bot, e, castPoint) >= hp then return Left(bot, s, p, e, 'lo matan mis golpes') end
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and Seen(a) and not a:IsIllusion() and a:GetAttackTarget() == e then others = others + HitsDamage(a, e, castPoint) end
	end
	if others >= hp then return Left(bot, s, p, e, string.format('lo matan los aliados (%d de %d)', others, hp)) end
	return false
end

-- Assassinate: only to finish a visible enemy hero it kills for sure, with no other enemy hero on top of us during its
-- long cast.
local SHARED_NEAR = 900 -- an ally this close to a target in attack range: shoot it instead
function H.Finish(bot, s, p)
	local a = bot:GetAbilityByName('sniper_assassinate')
	if a == nil or not a:IsFullyCastable() then return nil end
	local range = a:GetCastRange()
	local clear = CastClear(bot)
	local dmg = a:GetSpecialValueInt('damage')
	if dmg == nil or dmg <= 0 then dmg = a:GetAbilityDamage() end
	-- Every visible enemy hero in the ability's real range (it reaches farther than the 1500 of the lane snapshot).
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= range then
			local real = e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
			local others = 0
			for _, o in ipairs(p.enemyHeroes) do
				if Seen(o) and o ~= e and D2(p.loc, o:GetLocation()) < clear then others = others + 1 end
			end
			-- In attack range with an ally on it, it keeps shooting: the 2 s cast stopped its hits just when the kill fell, and of 18
			-- finishes 9 went to another 0-2 s later, many to spells the ally-attack count in Wasted does not see (build2).
			local shared = false
			if real >= e:GetHealth() and D2(p.loc, e:GetLocation()) <= p.range then
				for _, al in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
					if al ~= bot and Seen(al) and not al:IsIllusion() and D2(al:GetLocation(), e:GetLocation()) < SHARED_NEAR then shared = true break end
				end
				if shared then Left(bot, s, p, e, 'a tiro con un aliado encima: sigo pegando') end
			end
			if not shared and real >= e:GetHealth() and others == 0 and not Wasted(bot, s, p, e, a:GetCastPoint()) then
				return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('%s vida %d, assassinate quita %d (punto %.1fs)', Short(e), e:GetHealth(), real, a:GetCastPoint()) }
			end
		end
	end
	return nil
end

-- Assassinate in a team fight, to open it up: on the enemy it hurts most, or on one channelling, which it interrupts. OHA's Sniper does
-- 2.685 a match with it, this one 310-680 (fijo-oha, presion6), since it only fired for a sure kill. Only with nobody on top of us during
-- the cast. For the fight rule (medio.lua).
local FIGHT_SHARE = 0.35 -- it must take at least this share of the target's health
function H.FightCast(bot, s, p)
	local a = bot:GetAbilityByName('sniper_assassinate')
	if a == nil or not a:IsFullyCastable() then return nil end
	local clear = CastClear(bot)
	for _, o in ipairs(p.enemyHeroes) do
		if Seen(o) and D2(p.loc, o:GetLocation()) < clear then return nil end
	end
	local range = a:GetCastRange()
	local dmg = a:GetSpecialValueInt('damage')
	if dmg == nil or dmg <= 0 then dmg = a:GetAbilityDamage() end
	local best, bestShare = nil, FIGHT_SHARE
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= range and not Wasted(bot, s, p, e, a:GetCastPoint()) then
			if e:IsChanneling() then
				return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(), reason = string.format('%s canaliza: la interrumpo', Short(e)) }
			end
		end
		-- Within attack range it shoots: 32 openings, 5 kills its own, 12 another's and 15 alive, and the ult on cooldown for the
		-- finishes, which fell from 38 to 18 (retoque to build2). Only the ones its attacks do not reach.
		if Seen(e) and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= range and D2(p.loc, e:GetLocation()) > p.range
			and not Wasted(bot, s, p, e, a:GetCastPoint()) then
			local share = e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL) / math.max(e:GetHealth(), 1)
			if share > bestShare then best, bestShare = e, share end
		end
	end
	if best == nil then return nil end
	return { intent = 'rematar', ability = a, target = best, castPoint = a:GetCastPoint(),
		reason = string.format('%s en la pelea: quita %.0f%% de su vida %d', Short(best), 100 * bestShare, best:GetHealth()) }
end

-- The mana to keep for Assassinate: its cost once learned and nearly off cooldown, else none.
local function ManaToKeep(bot)
	local u = bot:GetAbilityByName('sniper_assassinate')
	if u == nil or u:GetLevel() == 0 or u:GetCooldownTimeRemaining() > 10 then return 0 end
	return u:GetManaCost()
end

-- Shrapnel: harass the enemy laner whenever a charge is ready, only within our attack range plus a little (from afar it was
-- spent with nothing to follow it), aiming where it will be when the shards fall, and not on one already slowed by it.
-- The build learns it at the fifth point, which keeps it from the first minutes (mana was 27 % by t=38). It kept half its mana
-- and waited 4 s between casts: 8 casts by minute 10 against OHA's 13, and a third less damage there (MEDICIONES 2026-11-08,
-- «Marcador»). Now only Assassinate's mana is kept, and the charges set the pace.
function H.Harass(bot, s, p)
	local a = bot:GetAbilityByName('sniper_shrapnel')
	if a == nil or not a:IsFullyCastable() then return nil end
	if p.now - (s.shrapnelAt or -1000) < 1.5 then return nil end
	if bot:GetMana() - a:GetManaCost() < ManaToKeep(bot) then return nil end
	local range = math.min(a:GetCastRange(), p.range + 200)
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and D2(p.loc, e:GetLocation()) <= range and not e:HasModifier('modifier_sniper_shrapnel_slow') then
			local at = e:GetExtrapolatedLocation(1.2)
			return { intent = 'shrapnel', ability = a, at = at, castPoint = a:GetCastPoint(),
				reason = string.format('%s a %d (alcance %d), maná %.0f%%', Short(e), D2(p.loc, e:GetLocation()), range,
					100 * bot:GetMana() / math.max(bot:GetMaxMana(), 1)) }
		end
	end
	return nil
end

-- During a kill: Shrapnel on the target (slows it and adds damage), keeping Assassinate's mana, if it is not slowed already.
function H.KillCast(bot, s, p, e)
	local a = bot:GetAbilityByName('sniper_shrapnel')
	if a == nil or not a:IsFullyCastable() or p.now - (s.shrapnelAt or -1000) < 2 then return nil end
	if not Seen(e) or e:HasModifier('modifier_sniper_shrapnel_slow') or D2(p.loc, e:GetLocation()) > a:GetCastRange() then
		return nil
	end
	if bot:GetMana() - a:GetManaCost() < ManaToKeep(bot) then return nil end
	return { intent = 'shrapnel', ability = a, at = e:GetExtrapolatedLocation(1.2), castPoint = a:GetCastPoint(),
		reason = string.format('en la kill sobre %s', Short(e)) }
end

-- Take Aim, before attacking a hero in range: more range and headshots while it lasts (OHA: 7-15 casts a match; ours, 0).
function H.Aim(bot, s, p, e)
	local a = bot:GetAbilityByName('sniper_take_aim')
	if a == nil or a:GetLevel() == 0 or a:IsPassive() or not a:IsFullyCastable() then return nil end
	if not Seen(e) or D2(p.loc, e:GetLocation()) > p.range then return nil end
	-- Not again within 3 s: if the engine took the order and did nothing, it would keep the attack from ever starting.
	if p.now - (s.aimAt or -1000) < 3 then return nil end
	s.aimAt = p.now
	return { intent = 'apuntar', ability = a, castPoint = a:GetCastPoint(),
		reason = string.format('antes de pegar a %s', Short(e)) }
end

-- What the abilities add to a kill on this enemy within the window, read live, counting only what would really be
-- cast: Assassinate first (under Finish's own conditions), then Shrapnel if the mana left pays for it or it is already
-- on the target. Returns the damage and the seconds of casting, in which no attack lands. For combate.lua.
function H.KillBurst(bot, p, e, window)
	local total, casting = 0, 0
	local mana = bot:GetMana()
	local u = bot:GetAbilityByName('sniper_assassinate')
	if u ~= nil and u:IsFullyCastable() and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= u:GetCastRange() then
		local others = 0
		local clear = CastClear(bot)
		for _, o in ipairs(p.enemyHeroes) do
			if Seen(o) and o ~= e and D2(p.loc, o:GetLocation()) < clear then others = others + 1 end
		end
		if others == 0 then
			local dmg = u:GetSpecialValueInt('damage')
			if dmg == nil or dmg <= 0 then dmg = u:GetAbilityDamage() end
			total = total + e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
			casting = casting + u:GetCastPoint()
			mana = mana - u:GetManaCost()
		end
	end
	local a = bot:GetAbilityByName('sniper_shrapnel')
	if a ~= nil and a:GetLevel() > 0 then
		local slowed = e:HasModifier('modifier_sniper_shrapnel_slow')
		if slowed or (a:IsFullyCastable() and mana >= a:GetManaCost()) then
			total = total + e:GetActualIncomingDamage(a:GetSpecialValueInt('shrapnel_damage') * window, DAMAGE_TYPE_MAGICAL)
			if not slowed then casting = casting + a:GetCastPoint() end
		end
	end
	return total, casting
end

return H
