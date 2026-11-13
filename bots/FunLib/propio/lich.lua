-- dota-bot's own bot: Lich's abilities (phase 2, trabajo/fase2.md), in the Sniper's style. Each rule returns a decision with its
-- reason, or nil. Ranges, cast points, costs and damage are read live from the engine (GetCastRange, GetCastPoint,
-- GetSpecialValueInt), never from a table, so a patch that changes them changes the bot.
local H = {}

-- What the shared code reads of each hero (heroes.lua): position, role, level-up order, starting items, fixed item list (when
-- the build profile gives none), Treads' stat and parts.
H.DATOS = {
	pos = 5,
	rol = 'apoyo',
	-- Frost Blast first and maxed: it is the lane's pressure. Frost Shield second (protects the carry), Chain Frost at 6, 12 and 18,
	-- Sinister Gaze last: no rule casts it yet. Order and talent names as the bench's Lich bots learned them, 7.41f (bench/observaciones,
	-- 11 matches with this exact sequence); a wrong name is just skipped by LevelUp.
	niveles = { 'lich_frost_nova', 'lich_frost_shield', 'lich_frost_nova', 'lich_sinister_gaze', 'lich_frost_nova', 'lich_chain_frost',
		'lich_frost_nova', 'lich_frost_shield', 'lich_frost_shield', 'special_bonus_unique_lich_6', 'lich_frost_shield', 'lich_chain_frost',
		'lich_sinister_gaze', 'lich_sinister_gaze', 'special_bonus_unique_lich_3', 'lich_sinister_gaze', 'lich_chain_frost',
		'special_bonus_unique_lich_4', 'special_bonus_unique_lich_5', 'special_bonus_unique_lich_8', 'special_bonus_unique_lich_2',
		'special_bonus_unique_lich_7', 'special_bonus_unique_lich_1' },
	-- A support's start (545 of 600): sustain for the lane, two tangos since the lane is shared. No clarities or wards: nothing uses
	-- them yet (the healing rule knows only salve and tango).
	salida = { 'item_tango', 'item_tango', 'item_flask', 'item_branches', 'item_branches', 'item_circlet' },
	-- Only items with a use rule (build.lua's USES); the build profile decides when there is one.
	compras = { 'item_power_treads', 'item_force_staff', 'item_aether_lens', 'item_ultimate_scepter', 'item_octarine_core' },
	botas = 'inteligencia',
}

-- Unit-target casts go through Act's 'rematar' (Action_UseAbilityOnEntity with the cast point protected); it logs them as
-- "assassinate". A generic intent for unit casts in linea.lua would be the clean way; changing this constant is all it takes here.
local ON_UNIT = 'rematar'

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end
local function Castable(u) return Seen(u) and not u:IsMagicImmune() and not u:IsInvulnerable() end

-- A learned, ready ability by name, or nil.
local function Ready(bot, name)
	local a = bot:GetAbilityByName(name)
	if a == nil or a:GetLevel() == 0 or not a:IsFullyCastable() then return nil end
	return a
end

-- Frost Blast's damage on its main target: the target's own damage and the area's, both land on it (OHA's hero_lich.lua adds them
-- the same way). Read live; the key names are assumed from OHA and the damage falls back to the ability's base.
local function BlastDamage(a)
	local main = a:GetAbilityDamage() or 0
	if main <= 0 then main = a:GetSpecialValueInt('damage') or 0 end
	return main + (a:GetSpecialValueInt('aoe_damage') or 0)
end

local function ChainDamage(u)
	local dmg = u:GetSpecialValueInt('damage')
	if dmg == nil or dmg <= 0 then dmg = u:GetAbilityDamage() end
	return dmg or 0
end

-- The mana to keep for Chain Frost, and Frost Shield once learned: Chain Frost's cost once learned and nearly off cooldown. Frost Blast
-- spent at will in lane left no mana for the ultimate when a fight came.
local function ManaToKeep(bot)
	local keep = 0
	local u = bot:GetAbilityByName('lich_chain_frost')
	if u ~= nil and u:GetLevel() > 0 and u:GetCooldownTimeRemaining() <= 10 then keep = keep + u:GetManaCost() end
	local w = bot:GetAbilityByName('lich_frost_shield')
	if w ~= nil and w:GetLevel() > 0 then keep = keep + w:GetManaCost() end
	return keep
end

-- Frost Shield on an allied hero (ourselves too) that enemy heroes are hitting: the most attackers first, and on a tie the richest,
-- which is the carry. Not on one already shielded. The carry dies in lane to the enemy's trades, and the shield cuts that damage.
local function Shield(bot, s, p)
	local w = Ready(bot, 'lich_frost_shield')
	if w == nil then return nil end
	local range = w:GetCastRange()
	local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}
	local best, bestN, bestWorth = nil, 0, -1
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if Seen(a) and not a:IsIllusion() and not a:HasModifier('modifier_lich_frost_shield') and D2(p.loc, a:GetLocation()) <= range then
			local n = 0
			for _, e in ipairs(enemies) do
				if Seen(e) and not e:IsIllusion() and e:GetAttackTarget() == a then n = n + 1 end
			end
			-- Spells leave no attack target: a hero hurt by heroes in the last second with one of them close counts too.
			if n == 0 and a:WasRecentlyDamagedByAnyHero(1.0) then
				for _, e in ipairs(enemies) do
					if Seen(e) and not e:IsIllusion() and D2(a:GetLocation(), e:GetLocation()) < 800 then n = 1 break end
				end
			end
			local worth = a:GetNetWorth() or 0
			if n > 0 and (n > bestN or (n == bestN and worth > bestWorth)) then best, bestN, bestWorth = a, n, worth end
		end
	end
	if best == nil then return nil end
	return { intent = ON_UNIT, ability = w, target = best, castPoint = w:GetCastPoint(),
		reason = string.format('escudo a %s: %d héroes le pegan', Short(best), bestN) }
end

-- Frost Blast: to finish a visible enemy hero it kills for sure, counting its regeneration during the cast point.
function H.Finish(bot, s, p)
	local a = Ready(bot, 'lich_frost_nova')
	if a == nil then return nil end
	local range = a:GetCastRange()
	local dmg = BlastDamage(a)
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Castable(e) and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= range then
			local real = e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
			local hp = e:GetHealth() + e:GetHealthRegen() * a:GetCastPoint()
			if real >= hp then
				return { intent = ON_UNIT, ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('%s vida %d, frost blast quita %d', Short(e), e:GetHealth(), real) }
			end
		end
	end
	return nil
end

-- Chain Frost in a team fight: on the visible enemy hero with the most other enemy heroes within a bounce, only with at least one
-- (two heroes or more). Bouncing between heroes is where its damage is; on a lone hero it bounces to creeps. Frost Shield first,
-- on an ally being hit. For the fight rule (medio.lua).
function H.FightCast(bot, s, p)
	local shield = Shield(bot, s, p)
	if shield ~= nil then return shield end
	local u = Ready(bot, 'lich_chain_frost')
	if u == nil then return nil end
	local range = u:GetCastRange()
	local jump = u:GetSpecialValueInt('jump_range')
	if jump == nil or jump <= 0 then jump = 600 end
	local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}
	local best, bestN = nil, 0
	for _, e in ipairs(enemies) do
		if Castable(e) and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= range then
			local n = 0
			for _, o in ipairs(enemies) do
				if o ~= e and Seen(o) and not o:IsIllusion() and D2(o:GetLocation(), e:GetLocation()) <= jump then n = n + 1 end
			end
			if n > bestN then best, bestN = e, n end
		end
	end
	if best == nil then return nil end
	return { intent = ON_UNIT, ability = u, target = best, castPoint = u:GetCastPoint(),
		reason = string.format('chain frost sobre %s: %d héroes más a %d', Short(best), bestN, jump) }
end

-- Lane pressure: Frost Shield on an ally being hit, else Frost Blast on the enemy laner in cast range (the weakest), keeping the mana for
-- Chain Frost and the shield. Only where it is: walking out to cast it put the support in the enemy's reach.
function H.Harass(bot, s, p)
	local shield = Shield(bot, s, p)
	if shield ~= nil then return shield end
	local a = Ready(bot, 'lich_frost_nova')
	if a == nil then return nil end
	if bot:GetMana() - a:GetManaCost() < ManaToKeep(bot) then return nil end
	local range = a:GetCastRange()
	local best = nil
	for _, e in ipairs(p.enemyHeroes) do
		if Castable(e) and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= range then
			if best == nil or e:GetHealth() < best:GetHealth() then best = e end
		end
	end
	if best == nil then return nil end
	-- opens (no lock, lockSec 0): the Blast goes on the pair's board, announced only with the partner near the target (67 harass Blasts
	-- against 10 in kills, never announced: p2 logs, package 2 round 2). Luna joins only when her own pair estimate gives the kill
	-- (combate.lua, Join).
	return { intent = ON_UNIT, ability = a, target = best, castPoint = a:GetCastPoint(), opens = best, lockSec = 0,
		reason = string.format('frost blast a %s a %d (alcance %d), maná %.0f%%', Short(best), D2(p.loc, best:GetLocation()), range,
			100 * bot:GetMana() / math.max(bot:GetMaxMana(), 1)) }
end

-- During a kill: Frost Blast on the target (damage and slow), then Chain Frost if learned and in range. The mana is spent: this is
-- what it was kept for.
function H.KillCast(bot, s, p, e)
	if not Castable(e) then return nil end
	local d = D2(p.loc, e:GetLocation())
	local a = Ready(bot, 'lich_frost_nova')
	if a ~= nil and d <= a:GetCastRange() then
		-- opens: on the pair's board with no lock (lockSec 0), so Luna, if she did not open, joins the Frost Blast with her Beam and hits
		-- (combate.lua, package 2), when her own pair estimate gives the kill.
		return { intent = ON_UNIT, ability = a, target = e, castPoint = a:GetCastPoint(), opens = e, lockSec = 0,
			reason = string.format('en la kill sobre %s', Short(e)) }
	end
	local u = Ready(bot, 'lich_chain_frost')
	if u ~= nil and d <= u:GetCastRange() then
		return { intent = ON_UNIT, ability = u, target = e, castPoint = u:GetCastPoint(),
			reason = string.format('chain frost en la kill sobre %s', Short(e)) }
	end
	return nil
end

-- Before hitting an enemy hero: Frost Shield on an ally being hit (Lich has no attack buff to take).
function H.Aim(bot, s, p, e)
	return Shield(bot, s, p)
end

-- What may still be cast when outnumbered in the lane, where linea.lua does not call Harass (package 1): Frost Shield on an ally
-- being hit, which is when it matters most. A hero without Protect casts nothing then.
function H.Protect(bot, s, p)
	return Shield(bot, s, p)
end

-- The seconds of lock Lich can cast now: none. Frost Blast slows and does not lock, and Sinister Gaze, which does, has no rule yet
-- (package 3). For the pair's kill estimate (combate.lua, package 2); Lich's part in the safe lane's opening is its Frost Blast, cast by
-- KillCast when it joins Luna's Beam.
function H.Disable(bot, p, e) return 0, 0 end

-- What the abilities add to a kill on this enemy within the window, read live, counting only what would really be cast: Frost
-- Blast, then Chain Frost if the mana left pays for it and its projectile arrives within the window. Returns the damage and the
-- seconds of casting, in which no attack lands. For combate.lua.
function H.KillBurst(bot, p, e, window)
	local total, casting = 0, 0
	if e:IsMagicImmune() then return 0, 0 end
	local mana = bot:GetMana()
	local d = D2(p.loc, e:GetLocation())
	local a = Ready(bot, 'lich_frost_nova')
	if a ~= nil and d <= a:GetCastRange() and mana >= a:GetManaCost() then
		total = total + e:GetActualIncomingDamage(BlastDamage(a), DAMAGE_TYPE_MAGICAL)
		casting = casting + a:GetCastPoint()
		mana = mana - a:GetManaCost()
	end
	local u = Ready(bot, 'lich_chain_frost')
	if u ~= nil and d <= u:GetCastRange() and mana >= u:GetManaCost() then
		local speed = u:GetSpecialValueInt('projectile_speed')
		if speed == nil or speed <= 0 then speed = 850 end
		if casting + u:GetCastPoint() + d / speed <= window then
			total = total + e:GetActualIncomingDamage(ChainDamage(u), DAMAGE_TYPE_MAGICAL)
			casting = casting + u:GetCastPoint()
		end
	end
	return total, casting
end

return H
