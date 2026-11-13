-- dota-bot's own bot: Luna's abilities (phase 2, trabajo/fase2.md). Each rule returns a decision with its reason, or nil.
-- Ranges, cast points, costs and damage are read live from the engine (GetCastRange, GetCastPoint, GetManaCost,
-- GetSpecialValueInt), never from a table, so a patch that changes them changes the bot.
-- Moon Glaives and Lunar Blessing are passive: the attack itself carries them, and the main target of an attack takes its full
-- damage, which combate.lua already counts from GetAttackDamage. Lunar Orbit has no rule yet.
local H = {}

-- What the shared code reads of each hero (heroes.lua): position, role, level-up order, starting items, fixed item list (when
-- the build profile gives none), Treads' stat, and the starting parts not bought again for the first item.
H.DATOS = {
	pos = 1,
	rol = 'nucleo',
	-- Valve's own order for this patch (scripts/npc/bot_builds.txt, 7.41f): Lucent Beam maxed first for the lane kills, Moon
	-- Glaives second for the farm, Lunar Orbit last. The 23 entries are the ability points from level 1 to 30.
	niveles = { 'luna_lucent_beam', 'luna_moon_glaive', 'luna_lucent_beam', 'luna_moon_glaive', 'luna_lucent_beam',
		'luna_eclipse', 'luna_lucent_beam', 'luna_moon_glaive', 'luna_moon_glaive', 'special_bonus_unique_luna_7',
		'luna_lunar_orbit', 'luna_lunar_orbit', 'luna_eclipse', 'luna_lunar_orbit', 'luna_lunar_orbit',
		'special_bonus_unique_luna_1', 'luna_eclipse', 'special_bonus_unique_luna_6', 'special_bonus_unique_luna_3',
		'special_bonus_unique_luna_4', 'special_bonus_unique_luna_lunar_orbit_glaive_count',
		'special_bonus_unique_luna_lunar_orbit_speed_damage', 'special_bonus_unique_luna_5' },
	-- The same start as the Sniper's: all the starting gold, slippers and circlet are the Wraith Band.
	salida = { 'item_tango', 'item_flask', 'item_branches', 'item_branches', 'item_slippers', 'item_circlet' },
	primero = 'item_wraith_band', -- the starting parts above are not bought again for it
	-- From OHA's pos_1 list, keeping only items with a use rule (build.lua's USES); the profile decides the order.
	compras = { 'item_wraith_band', 'item_power_treads', 'item_mask_of_madness', 'item_dragon_lance', 'item_manta',
		'item_black_king_bar', 'item_satanic', 'item_butterfly' },
	botas = 'agilidad',
}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

-- The hits a unit lands on the target in these seconds (the first one at once), by its real damage per hit.
local function HitsDamage(u, e, seconds)
	local hits = seconds > 0 and 1 + math.floor(seconds / math.max(u:GetSecondsPerAttack(), 0.1)) or 0
	return hits * e:GetActualIncomingDamage(u:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
end

-- Lucent Beam's damage on this target, after its magic resistance. The special value first; the ability's base damage if the
-- name ever changes, so a renamed key degrades to a number instead of a zero that would never cast.
local function BeamDamage(a, e)
	local dmg = a:GetSpecialValueInt('beam_damage')
	if dmg == nil or dmg <= 0 then dmg = a:GetAbilityDamage() end
	return e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
end

-- Whether this target can take a Lucent Beam: visible, a real hero, not magic immune, in the beam's range, and not a target the
-- engine just refused (linea.lua bans it for a few seconds when a unit-target order does not start).
local function Beamable(s, p, a, e)
	if not Seen(e) or e:IsIllusion() or e:IsMagicImmune() then return false end
	if D2(p.loc, e:GetLocation()) > a:GetCastRange() then return false end
	local ban = (s.castBan or {})[Short(e)]
	return ban == nil or ban <= p.now
end

-- The mana to keep for Eclipse: its cost once learned and nearly off cooldown, else none. Eclipse is what wins Luna's fights.
local function ManaToKeep(bot)
	local u = bot:GetAbilityByName('luna_eclipse')
	if u == nil or u:GetLevel() == 0 or u:GetCooldownTimeRemaining() > 10 then return 0 end
	return u:GetManaCost()
end

local function Beam(bot)
	local a = bot:GetAbilityByName('luna_lucent_beam')
	if a == nil or a:GetLevel() == 0 or not a:IsFullyCastable() then return nil end
	return a
end

-- Lucent Beam to finish a visible enemy hero it surely kills. Not when our own hits in range kill it before the beam's cast point
-- ends: the beam would be spent for nothing and miss the next kill.
function H.Finish(bot, s, p)
	local a = Beam(bot)
	if a == nil then return nil end
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Beamable(s, p, a, e) then
			local real, hp = BeamDamage(a, e), e:GetHealth()
			local hitsKill = D2(p.loc, e:GetLocation()) <= p.range and HitsDamage(bot, e, a:GetCastPoint()) >= hp
			if real >= hp and not hitsKill then
				return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('%s vida %d, lucent beam quita %d', Short(e), hp, real) }
			end
		end
	end
	return nil
end

-- Lucent Beam on the enemy laner: only with mana for another beam on top of Eclipse's, so a sure kill (Finish) is never left
-- without one, and not more often than every HARASS_GAP seconds, so the mana goes to kills rather than to chip damage. Only on
-- a laner within our attack range plus a little: the hits that follow it are what turn the beam into a trade.
local HARASS_GAP = 8
function H.Harass(bot, s, p)
	local a = Beam(bot)
	if a == nil then return nil end
	if p.now - (s.beamAt or -1000) < HARASS_GAP then return nil end
	if bot:GetMana() - 2 * a:GetManaCost() < ManaToKeep(bot) then return nil end
	local reach = math.min(a:GetCastRange(), p.range + 200)
	for _, e in ipairs(p.enemyHeroes) do
		if Beamable(s, p, a, e) and D2(p.loc, e:GetLocation()) <= reach then
			s.beamAt = p.now
			return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
				reason = string.format('acoso a %s a %d (alcance %d), maná %.0f%%', Short(e), D2(p.loc, e:GetLocation()), reach,
					100 * bot:GetMana() / math.max(bot:GetMaxMana(), 1)) }
		end
	end
	return nil
end

-- During a kill: Lucent Beam on the target (damage and a short stun that stops it running), keeping Eclipse's mana.
function H.KillCast(bot, s, p, e)
	local a = Beam(bot)
	if a == nil or not Beamable(s, p, a, e) then return nil end
	if bot:GetMana() - a:GetManaCost() < ManaToKeep(bot) then return nil end
	s.beamAt = p.now
	return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
		reason = string.format('en la kill sobre %s', Short(e)) }
end

-- Eclipse in a team fight, when at least ECLIPSE_MIN real enemy heroes stand within its radius around us: its beams split among
-- the units near Luna, so with one enemy it is only a weaker Lucent Beam. Before that, a Lucent Beam on an enemy channelling,
-- which its stun interrupts. For the fight rule (medio.lua).
local ECLIPSE_MIN = 2
function H.FightCast(bot, s, p)
	local a = Beam(bot)
	if a ~= nil and bot:GetMana() - a:GetManaCost() >= ManaToKeep(bot) then
		for _, e in ipairs(p.enemyHeroes) do
			if Beamable(s, p, a, e) and e:IsChanneling() then
				return { intent = 'rematar', ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('%s canaliza: la interrumpo', Short(e)) }
			end
		end
	end
	local u = bot:GetAbilityByName('luna_eclipse')
	if u == nil or u:GetLevel() == 0 or not u:IsFullyCastable() then return nil end
	local radius = u:GetSpecialValueInt('radius')
	if radius == nil or radius <= 0 then radius = u:GetAOERadius() end
	if radius == nil or radius <= 0 then return nil end
	local near = 0
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsIllusion() and not e:IsMagicImmune() and D2(p.loc, e:GetLocation()) <= radius then near = near + 1 end
	end
	if near < ECLIPSE_MIN then return nil end
	local reason = string.format('eclipse: %d enemigos a menos de %d', near, radius)
	-- With Aghanim's Scepter Eclipse becomes a unit-target cast (on Luna or an ally), so the no-target order would not start.
	if bot:HasScepter() then
		return { intent = 'rematar', ability = u, target = bot, castPoint = u:GetCastPoint(), reason = reason }
	end
	-- 'apuntar' is Act's only no-target ability order (bot:Action_UseAbility); its log line says take_aim, but the cast is Eclipse.
	return { intent = 'apuntar', ability = u, castPoint = u:GetCastPoint(), reason = reason }
end

-- Nothing to cast before an attack: Luna has no attack buff of her own (Lunar Orbit has no rule yet).
function H.Aim(bot, s, p, e)
	return nil
end

-- What the abilities add to a kill on this enemy within the window, read live, counting only what would really be cast: a
-- Lucent Beam if it is ready, reaches the target and leaves Eclipse's mana. The attacks (and with them Moon Glaives, whose main
-- target takes the full hit) are counted by combate.lua. Returns the damage and the seconds of casting, in which no attack lands.
function H.KillBurst(bot, p, e, window)
	local a = Beam(bot)
	if a == nil or not Seen(e) or e:IsMagicImmune() or D2(p.loc, e:GetLocation()) > a:GetCastRange() then return 0, 0 end
	if bot:GetMana() - a:GetManaCost() < ManaToKeep(bot) then return 0, 0 end
	return BeamDamage(a, e), a:GetCastPoint()
end

return H
