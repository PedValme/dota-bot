-- dota-bot's own bot: how a trade against an enemy hero looks, with numbers read live, so each one can be checked in the
-- log (Pedro, 2026-11-05: «no tiene en cuenta sus propias ventajas, rango skills», «ventaja de highground»). Who kills
-- whom first at the current damage and health, counting his allies near, the creeps that would turn on us, the range we
-- have on him and the high ground. Replaces Valve's GetEstimatedDamageToTarget, which cannot be supervised.
-- The factors below are judgement, not data: they are tuned with the smokes.
local I = {}

local K = {
	creepAggro = 0.33,  -- creeps near turn on us only for a moment after we hit a hero: this share of their damage
	othersNear = 1200,  -- other enemy heroes this close count in full
	creepsNear = 500,
	outrange = 0.75,    -- his damage if we outrange him by rangeMargin and he is out of his range: he must walk in first
	rangeMargin = 100,
	highGround = 0.75,  -- damage of whoever shoots uphill
	measuredShare = 0.6, -- how much of the damage measured over the last 2 s counts as sustained
}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Valid(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end

-- One unit per hero, the nearest. The API does not tell an enemy illusion from its hero (fase1i: three Zeus from a rune,
-- IsIllusion false in 2.114 of 2.114 lines), and each copy counted as a whole hero sank the trade: a false flight.
function I.OnePerHero(loc, heroes)
	local nearest = {}
	for _, h in ipairs(heroes) do
		if Valid(h) then
			local name = h:GetUnitName()
			if nearest[name] == nil or D2(loc, h:GetLocation()) < D2(loc, nearest[name]:GetLocation()) then nearest[name] = h end
		end
	end
	local list = {}
	for _, h in pairs(nearest) do table.insert(list, h) end
	return list
end

-- One attacker's damage per second on a target, armour included.
local function Dps(attacker, target)
	return target:GetActualIncomingDamage(attacker:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL) / math.max(attacker:GetSecondsPerAttack(), 0.1)
end

-- What an enemy can do to the target in these seconds: its hits, and the direct damage of each ability ready now.
-- Damage over time and effects do not count: GetAbilityDamage gives 0 for many.
function I.Threat(e, target, seconds)
	local hits = 1 + math.floor(seconds / math.max(e:GetSecondsPerAttack(), 0.1))
	local dmg = hits * target:GetActualIncomingDamage(e:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
	for slot = 0, 5 do
		local ab = e:GetAbilityInSlot(slot)
		if ab ~= nil and not ab:IsPassive() and ab:IsFullyCastable() then
			dmg = dmg + target:GetActualIncomingDamage(ab:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
		end
	end
	return dmg
end

-- The trade with this enemy now. ratio: seconds he needs to kill us over seconds we need to kill him; above 1 we win it.
function I.Eval(bot, p, e)
	local mine, his = Dps(bot, e), Dps(e, bot)
	local eLoc = e:GetLocation()
	local dist = D2(p.loc, eLoc)
	local creeps = 0
	for _, c in ipairs(p.enemyCreeps) do
		if Valid(c) and D2(p.loc, c:GetLocation()) < K.creepsNear then
			creeps = creeps + Dps(c, bot) * K.creepAggro
		end
	end
	local others = 0
	for _, o in ipairs(p.enemyHeroes) do
		if Valid(o) and o ~= e and D2(p.loc, o:GetLocation()) < K.othersNear then others = others + Dps(o, bot) end
	end
	-- Our side as his: the allied heroes near us (linea.lua's Perceive, one per hero, none retreating) hit him as his partner hits
	-- us, within the same distance. It added his partner and not ours, so a 2 against 2 read as 1 against 2 and was never answered
	-- (trabajo/plan-mejora-equipo.md: «el intercambio no suma al compañero»). With no ally near, as before: the lone mid is unchanged.
	local allies = 0
	for _, a in ipairs(p.allyHeroes or {}) do
		if Valid(a) and D2(p.loc, a:GetLocation()) < K.othersNear then
			mine = mine + Dps(a, e)
			allies = allies + 1
		end
	end
	local outranged = e:GetAttackRange() + K.rangeMargin <= p.range and dist > e:GetAttackRange()
	if outranged then his = his * K.outrange end
	-- What this enemy has really done to us alone in this match counts (linea.lua, Perceive): venom, toxin and passives are in no
	-- reading beforehand, and the hero walked into Viper again and again with ratio 1,9 (presion8: 9 deaths in one match).
	local learned = p.enemyDps ~= nil and p.enemyDps[e:GetUnitName()] or 0
	his = math.max(his, learned * K.measuredShare)
	local myHeight, hisHeight = GetHeightLevel(p.loc), GetHeightLevel(eLoc)
	if myHeight > hisHeight then his = his * K.highGround
	elseif myHeight < hisHeight then mine = mine * K.highGround end
	-- What is really coming in over the last 2 s counts if it is more: attacks alone leave out crits, abilities and lifesteal
	-- (lobby 2026-11-05: Bloodseeker read 258 and did 476; Alchemist read 35 and did 128), and the hero traded to its death.
	-- At a share of it: over 2 s a single spell reads as sustained damage, and in lane it stopped hitting back at nukes
	-- (presion6: no answer in 49 % of harassed windows, with ratio under 0,7 from out of range).
	local against = math.max(his + creeps + others, (p.dps or 0) * K.measuredShare)
	local tHim = e:GetHealth() / math.max(mine, 1)
	local tMe = p.hpAbs / math.max(against, 1)
	return { ratio = tMe / math.max(tHim, 0.1), mine = mine, against = against, height = myHeight - hisHeight, outranged = outranged,
		allies = allies }
end

return I
