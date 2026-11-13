-- dota-bot's own bot: Dragon Knight's abilities (phase 2, trabajo/fase2.md), position 3. Each rule returns a decision with its
-- reason, or nil. Ranges, cast points, costs, radii and damage are read live from the engine (GetCastRange, GetCastPoint,
-- GetSpecialValueInt), never from a table, so a patch that changes them changes the bot.
--
-- linea.lua's Act knows three ability orders, named after the Sniper's spells; this module reuses them by their shape:
--   'shrapnel' = cast on a point (Breathe Fire), 'rematar' = cast on a unit (Dragon Tail), 'apuntar' = cast with no target
--   (Elder Dragon Form). Each reason starts with the real ability's name, since Act's log line says the Sniper's.
local H = {}

-- What the shared code reads of each hero (heroes.lua): position, role, level-up order, starting items, fixed item list (when
-- the build profile gives none), Treads' stat and parts, and the starting parts not bought again for the first item.
H.DATOS = {
	pos = 3,
	rol = 'nucleo',
	-- Ranks and talent slots as Valve's Dragon Knight learned them in the bench (7.41f, build1-c and base2-oha-c logs), which the
	-- game accepted; Breathe Fire is maxed first instead of Wyrm's Wrath, since it is the lane harass. The point list is the order
	-- of points spent: talents sit at the 10th, 15th, 18th and 19th point (levels 10, 15, 20 and 25), the rest after.
	niveles = { 'dragon_knight_breathe_fire', 'dragon_knight_dragon_tail', 'dragon_knight_breathe_fire', 'dragon_knight_wyrms_wrath',
		'dragon_knight_breathe_fire', 'dragon_knight_elder_dragon_form', 'dragon_knight_breathe_fire', 'dragon_knight_wyrms_wrath',
		'dragon_knight_wyrms_wrath', 'special_bonus_attack_damage_15', 'dragon_knight_wyrms_wrath', 'dragon_knight_elder_dragon_form',
		'dragon_knight_dragon_tail', 'dragon_knight_dragon_tail', 'special_bonus_hp_300', 'dragon_knight_dragon_tail',
		'dragon_knight_elder_dragon_form', 'special_bonus_unique_dragon_knight_7', 'special_bonus_unique_dragon_knight_wyrms_wrath_damage',
		'special_bonus_unique_dragon_knight_3', 'special_bonus_unique_dragon_knight_2', 'special_bonus_unique_dragon_knight',
		'special_bonus_unique_dragon_knight_9' },
	-- OHA's pos_3 start (585 of 600 gold): the circlet and gauntlets are the Bracer.
	salida = { 'item_tango', 'item_branches', 'item_branches', 'item_quelling_blade', 'item_circlet', 'item_gauntlets' },
	primero = 'item_bracer', -- the starting parts above are not bought again for it
	-- Only items with a use rule (build.lua's USES): OHA's Orchid, Crimson Guard, Halberd and Blink have none yet.
	compras = { 'item_bracer', 'item_power_treads', 'item_desolator', 'item_black_king_bar', 'item_assault', 'item_heart',
		'item_satanic' },
	botas = 'fuerza',
}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

local function Ready(bot, name)
	local a = bot:GetAbilityByName(name)
	if a == nil or a:GetLevel() == 0 or not a:IsFullyCastable() then return nil end
	return a
end

-- Breathe Fire's numbers, read live: damage, how far the flame travels, its radius at start and end, and its speed.
local function Fire(a)
	local dmg = a:GetSpecialValueInt('damage')
	if dmg == nil or dmg <= 0 then dmg = a:GetAbilityDamage() end
	local travel = a:GetSpecialValueInt('range')
	if travel == nil or travel <= 0 then travel = a:GetCastRange() end
	local r0, r1 = a:GetSpecialValueInt('start_radius'), a:GetSpecialValueInt('end_radius')
	if r1 == nil or r1 <= 0 then r1 = r0 or 0 end
	if r0 == nil or r0 <= 0 then r0 = r1 end
	return { dmg = dmg, travel = travel, r0 = r0, r1 = r1, speed = a:GetSpecialValueInt('speed') or 0 }
end

-- Where to aim Breathe Fire at a unit: where it will be when the flame gets there (cast point plus the flight).
local function FireAt(a, f, from, e)
	local flight = f.speed > 0 and D2(from, e:GetLocation()) / f.speed or 0
	return e:GetExtrapolatedLocation(a:GetCastPoint() + flight), a:GetCastPoint() + flight
end

-- Whether a unit stands in the flame's cone, from `from` toward `at`: its distance to the line, against the radius there.
local function InCone(f, from, at, u)
	local dx, dy = at.x - from.x, at.y - from.y
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 1 then return D2(from, u:GetLocation()) <= f.r0 end
	local ux, uy = dx / len, dy / len
	local l = u:GetLocation()
	local along = (l.x - from.x) * ux + (l.y - from.y) * uy
	if along < 0 or along > f.travel then return false end
	local side = math.abs((l.x - from.x) * uy - (l.y - from.y) * ux)
	return side <= f.r0 + (f.r1 - f.r0) * along / math.max(f.travel, 1)
end

-- What one flame toward `at` hits: enemy heroes (not magic immune) and enemy lane creeps.
local function Hits(f, p, at)
	local heroes, creeps = 0, 0
	for _, o in ipairs(p.enemyHeroes) do
		if Seen(o) and not o:IsIllusion() and not o:IsMagicImmune() and InCone(f, p.loc, at, o) then heroes = heroes + 1 end
	end
	for _, c in ipairs(p.enemyCreeps) do
		if Seen(c) and InCone(f, p.loc, at, c) then creeps = creeps + 1 end
	end
	return heroes, creeps
end

-- The mana to keep: Dragon Tail's cost once learned and nearly ready (it is the stun that starts or saves a fight), and Elder
-- Dragon Form's when it is near too. Breathe Fire spends only what is above it.
local function ManaToKeep(bot)
	local keep = 0
	local t = bot:GetAbilityByName('dragon_knight_dragon_tail')
	if t ~= nil and t:GetLevel() > 0 and t:GetCooldownTimeRemaining() < 5 then keep = keep + t:GetManaCost() end
	local u = bot:GetAbilityByName('dragon_knight_elder_dragon_form')
	if u ~= nil and u:GetLevel() > 0 and u:GetCooldownTimeRemaining() < 10 then keep = keep + u:GetManaCost() end
	return keep
end

-- A disabled target does not need the stun yet: it is kept for when the disable ends or the target runs.
local function Locked(e) return e:IsStunned() or e:IsHexed() end

local function DragonTailOn(bot, s, p, e, why)
	local a = Ready(bot, 'dragon_knight_dragon_tail')
	if a == nil or not Seen(e) or e:IsMagicImmune() or e:IsInvulnerable() then return nil end
	-- Its cast range is a melee one (longer in Elder Dragon Form); a few steps more are walked by the engine.
	if D2(p.loc, e:GetLocation()) > a:GetCastRange() + 100 then return nil end
	return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
		reason = string.format('dragon_tail sobre %s: %s', Short(e), why) }
end

local function ElderForm(bot, s, p, why)
	local a = Ready(bot, 'dragon_knight_elder_dragon_form')
	if a == nil or bot:HasModifier('modifier_dragon_knight_dragon_form') then return nil end
	-- Not again within 3 s: an order the engine took and did nothing with would hold the hero each tick.
	if p.now - (s.edfAt or -1000) < 3 then return nil end
	s.edfAt = p.now
	return { intent = 'apuntar', ability = a, castPoint = a:GetCastPoint(), reason = 'elder_dragon_form: ' .. why }
end

-- Breathe Fire: only to finish a visible enemy hero it surely kills, counting the health it regains while the flame flies.
function H.Finish(bot, s, p)
	local a = Ready(bot, 'dragon_knight_breathe_fire')
	if a == nil or p.now - (s.shrapnelAt or -1000) < 1 then return nil end
	local f = Fire(a)
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and not e:IsMagicImmune() and not e:IsInvulnerable() and D2(p.loc, e:GetLocation()) <= a:GetCastRange() then
			local at, eta = FireAt(a, f, p.loc, e)
			local real = e:GetActualIncomingDamage(f.dmg, DAMAGE_TYPE_MAGICAL)
			if real >= e:GetHealth() + e:GetHealthRegen() * eta then
				return { intent = 'shrapnel', ability = a, at = at, castPoint = a:GetCastPoint(),
					reason = string.format('breathe_fire remata a %s: vida %d, quita %d', Short(e), e:GetHealth(), real) }
			end
		end
	end
	return nil
end

-- Breathe Fire to harass the enemy laner(s), from where we stand (its cast range is longer than our melee reach, so no walking
-- in for it). Freely when the flame takes two heroes or a hero and a creep wave; on a lone hero only with plenty of mana, since
-- the pool is small and Dragon Tail's mana is kept. Not on a hero already under its damage reduction, unless it hits two.
local SOLO_MANA = 0.6  -- a flame on one hero alone only with this share of mana left after it
local WAVE_CREEPS = 2  -- creeps in the flame that make a hero's flame worth it
function H.Harass(bot, s, p)
	local a = Ready(bot, 'dragon_knight_breathe_fire')
	if a == nil or p.now - (s.shrapnelAt or -1000) < 1.5 then return nil end
	local after = bot:GetMana() - a:GetManaCost()
	if after < ManaToKeep(bot) then return nil end
	local f = Fire(a)
	local range = a:GetCastRange()
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and not e:IsIllusion() and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= range then
			local at = FireAt(a, f, p.loc, e)
			local heroes, creeps = Hits(f, p, at)
			local reduced = e:HasModifier('modifier_dragonknight_breathefire_reduction')
			local share = after / math.max(bot:GetMaxMana(), 1)
			local kind = nil
			if heroes >= 2 then kind = 'dos héroes'
			elseif not reduced and creeps >= WAVE_CREEPS then kind = 'héroe y oleada'
			elseif not reduced and share >= SOLO_MANA then kind = 'héroe solo' end
			if kind ~= nil then
				return { intent = 'shrapnel', ability = a, at = at, castPoint = a:GetCastPoint(),
					reason = string.format('breathe_fire %s: %s a %d, %d héroes y %d creeps, maná tras %.0f%%', kind, Short(e),
						D2(p.loc, e:GetLocation()), heroes, creeps, 100 * share) }
			end
		end
	end
	return nil
end

-- During a kill: Elder Dragon Form as the fight starts near, Dragon Tail to start or hold it (not on a target already locked),
-- then Breathe Fire on the target, keeping the mana for the stun while it is still to come.
local KILL_FORM_NEAR = 700 -- the target this close: the fight is here, worth the form
function H.KillCast(bot, s, p, e)
	if not Seen(e) then return nil end
	local d = D2(p.loc, e:GetLocation())
	if d <= KILL_FORM_NEAR then
		local form = ElderForm(bot, s, p, string.format('kill sobre %s a %d', Short(e), d))
		if form then return form end
	end
	if not Locked(e) then
		local tail = DragonTailOn(bot, s, p, e, string.format('kill, vida %d', e:GetHealth()))
		if tail then return tail end
	end
	local a = Ready(bot, 'dragon_knight_breathe_fire')
	if a == nil or e:IsMagicImmune() or p.now - (s.shrapnelAt or -1000) < 1 or d > a:GetCastRange() then return nil end
	if e:HasModifier('modifier_dragonknight_breathefire_reduction') then return nil end
	local t = bot:GetAbilityByName('dragon_knight_dragon_tail')
	local keep = (t ~= nil and t:GetLevel() > 0 and t:GetCooldownTimeRemaining() < 3) and t:GetManaCost() or 0
	if bot:GetMana() - a:GetManaCost() < keep then return nil end
	return { intent = 'shrapnel', ability = a, at = (FireAt(a, Fire(a), p.loc, e)), castPoint = a:GetCastPoint(),
		reason = string.format('breathe_fire en la kill sobre %s, vida %d', Short(e), e:GetHealth()) }
end

-- Dragon Knight has no attack steroid to press before a hit; Elder Dragon Form goes by KillCast and FightCast.
function H.Aim(bot, s, p, e) return nil end

-- In a team fight (medio.lua): Dragon Tail first on an enemy channelling near, which it interrupts; then Elder Dragon Form when
-- the fight is close enough to join now.
local FIGHT_NEAR = 900 -- an enemy hero this close: the fight has reached us
function H.FightCast(bot, s, p)
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and e:IsChanneling() then
			local tail = DragonTailOn(bot, s, p, e, 'canaliza: lo interrumpo')
			if tail then return tail end
		end
	end
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= FIGHT_NEAR then
			return ElderForm(bot, s, p, string.format('pelea con %s a %d', Short(e), D2(p.loc, e:GetLocation())))
		end
	end
	return nil
end

-- What the abilities add to a kill on this enemy within the window, read live, counting only what would really be cast:
-- Breathe Fire if ready, in range and paid for, and Dragon Tail's damage if ready (the stun also keeps the target in reach of
-- our hits). Returns the damage and the seconds of casting, in which no attack lands. For combate.lua.
function H.KillBurst(bot, p, e, window)
	local total, casting = 0, 0
	if e:IsMagicImmune() then return 0, 0 end
	local mana = bot:GetMana()
	local d = D2(p.loc, e:GetLocation())
	local t = Ready(bot, 'dragon_knight_dragon_tail')
	if t ~= nil and mana >= t:GetManaCost() then
		local dmg = t:GetSpecialValueInt('damage')
		if dmg == nil or dmg <= 0 then dmg = t:GetAbilityDamage() end
		total = total + e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
		casting = casting + t:GetCastPoint()
		mana = mana - t:GetManaCost()
	end
	local a = Ready(bot, 'dragon_knight_breathe_fire')
	if a ~= nil and mana >= a:GetManaCost() and d <= a:GetCastRange() then
		total = total + e:GetActualIncomingDamage(Fire(a).dmg, DAMAGE_TYPE_MAGICAL)
		casting = casting + a:GetCastPoint()
	end
	return total, casting
end

return H
