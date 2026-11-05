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
	local outranged = e:GetAttackRange() + K.rangeMargin <= p.range and dist > e:GetAttackRange()
	if outranged then his = his * K.outrange end
	local myHeight, hisHeight = GetHeightLevel(p.loc), GetHeightLevel(eLoc)
	if myHeight > hisHeight then his = his * K.highGround
	elseif myHeight < hisHeight then mine = mine * K.highGround end
	local against = his + creeps + others
	local tHim = e:GetHealth() / math.max(mine, 1)
	local tMe = p.hpAbs / math.max(against, 1)
	return { ratio = tMe / math.max(tHim, 0.1), mine = mine, against = against, height = myHeight - hisHeight, outranged = outranged }
end

return I
