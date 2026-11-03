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

-- Assassinate: only to finish a visible enemy hero it kills for sure, with no other enemy hero near us during its
-- long cast.
function H.Finish(bot, s, p)
	local a = bot:GetAbilityByName('sniper_assassinate')
	if a == nil or not a:IsFullyCastable() then return nil end
	local range = a:GetCastRange()
	local dmg = a:GetSpecialValueInt('damage')
	if dmg == nil or dmg <= 0 then dmg = a:GetAbilityDamage() end
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= range then
			local real = e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
			local others = 0
			for _, o in ipairs(p.enemyHeroes) do
				if Seen(o) and o ~= e and D2(p.loc, o:GetLocation()) < 900 then others = others + 1 end
			end
			if real >= e:GetHealth() and others == 0 then
				return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('%s vida %d, assassinate quita %d (punto %.1fs)', Short(e), e:GetHealth(), real, a:GetCastPoint()) }
			end
		end
	end
	return nil
end

-- Shrapnel: harass the enemy laner in reach when mana allows, aiming where it will be when the shards fall, and not
-- on one already slowed by it.
function H.Harass(bot, s, p)
	local a = bot:GetAbilityByName('sniper_shrapnel')
	if a == nil or not a:IsFullyCastable() then return nil end
	if bot:GetMana() < 0.5 * bot:GetMaxMana() or p.now - (s.shrapnelAt or -1000) < 4 then return nil end
	local range = a:GetCastRange()
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

return H
