-- dota-bot's own bot: Lion's abilities (phase 2, trabajo/fase2.md), in the Sniper's style. Each rule returns a decision with its
-- reason, or nil. Ranges, cast points, costs and damage are read live from the engine (GetCastRange, GetCastPoint,
-- GetSpecialValueInt), never from a table, so a patch that changes them changes the bot.
local H = {}

-- What the shared code reads of each hero (heroes.lua): position, role, level-up order, starting items, fixed item list (when
-- the build profile gives none), Treads' stat and parts, and the starting parts not bought again for the first item.
H.DATOS = {
	pos = 4,
	rol = 'apoyo',
	-- Earth Spike and Hex first (the lock is what a support brings), Finger at 6, 12 and 18. Mana Drain last: no rule casts it yet.
	-- Talents and attribute points in the slots where Valve's Lion learns them in 7.41f (bench/observaciones, `learn` lines): a wrong
	-- name does not just skip, LevelUp moves on and shifts the rest (OHA's names never appeared in a match).
	niveles = { 'lion_impale', 'lion_voodoo', 'lion_impale', 'lion_voodoo', 'lion_impale', 'lion_finger_of_death',
		'lion_impale', 'lion_voodoo', 'lion_voodoo', 'special_bonus_movement_speed_20', 'special_bonus_attributes',
		'lion_finger_of_death', 'lion_mana_drain', 'lion_mana_drain', 'lion_mana_drain', 'special_bonus_unique_lion_5',
		'special_bonus_attributes', 'lion_finger_of_death', 'lion_mana_drain', 'special_bonus_unique_lion_10',
		'special_bonus_unique_lion_6', 'special_bonus_unique_lion_11', 'special_bonus_unique_lion_8', 'special_bonus_unique_lion_4',
		'special_bonus_unique_lion_2' },
	-- All the starting gold (595 of 600). Mantle and circlet are the Null Talisman. No clarities or wards: nothing uses them yet.
	salida = { 'item_tango', 'item_flask', 'item_branches', 'item_branches', 'item_mantle', 'item_circlet' },
	primero = 'item_null_talisman', -- the starting parts above are not bought again for it
	-- Only items with a use rule (build.lua's USES); the build profile decides when there is one.
	compras = { 'item_null_talisman', 'item_power_treads', 'item_force_staff', 'item_aether_lens', 'item_ultimate_scepter',
		'item_black_king_bar', 'item_octarine_core' },
	botas = 'inteligencia',
}

local function D2(a, b)
	if a == nil or b == nil then return 1e9 end
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end
local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end

-- The intents Act (linea.lua) knows today: 'rematar' casts on a unit, 'shrapnel' on the ground. Their logs name the Sniper's spells;
-- once Act has generic cast intents, only these two lines change.
local ON_UNIT, ON_GROUND = 'rematar', 'shrapnel'

-- Seconds left of a modifier on a unit, 0 when it has none.
local function Left(u, name)
	local i = u:GetModifierByName(name)
	if i == nil or i < 0 then return 0 end
	return u:GetModifierRemainingDuration(i) or 0
end

-- Already locked: stunned, hexed or under our spike, for longer than a cast takes to land. Another lock on it would be wasted.
local function Locked(e, margin)
	if e:IsHexed() or e:IsStunned() then
		return math.max(Left(e, 'modifier_lion_voodoo'), Left(e, 'modifier_lion_impale'), e:IsStunned() and 0.5 or 0) > margin
	end
	return false
end

local function Learned(bot, name)
	local a = bot:GetAbilityByName(name)
	if a == nil or a:GetLevel() == 0 then return nil end
	return a
end

-- A spell's damage: its special value, or the engine's ability damage when the key is missing.
local function Damage(a, key)
	local d = a:GetSpecialValueInt(key)
	if d == nil or d <= 0 then d = a:GetAbilityDamage() end
	return d or 0
end

-- Finger's damage now: base (or the Scepter's), plus the bonus each hero kill with it has stacked.
local function FingerDamage(bot, a)
	local dmg = Damage(a, 'damage')
	if bot:HasScepter() then
		local sc = a:GetSpecialValueInt('damage_scepter')
		if sc ~= nil and sc > dmg then dmg = sc end
	end
	local i = bot:GetModifierByName('modifier_lion_finger_of_death_kill_counter')
	if i ~= nil and i >= 0 then
		dmg = dmg + (bot:GetModifierStackCount(i) or 0) * math.max(a:GetSpecialValueInt('damage_per_kill') or 0, 0)
	end
	return dmg
end

-- The mana to keep for the lock and the kill: Hex and Finger once learned and nearly off cooldown.
local function ManaToKeep(bot)
	local keep = 0
	local hex = Learned(bot, 'lion_voodoo')
	if hex ~= nil and hex:GetCooldownTimeRemaining() < 5 then keep = keep + hex:GetManaCost() end
	local finger = Learned(bot, 'lion_finger_of_death')
	if finger ~= nil and finger:GetCooldownTimeRemaining() < 10 then keep = keep + finger:GetManaCost() end
	return keep
end

-- The enemy heroes Earth Spike's line hits when aimed at this point: those within its width of the segment from us, as long as the
-- cast range plus a little (the spikes travel past the point). Predicted where they will be when the spikes arrive.
local function SpikeHits(bot, p, a, at)
	local width = math.max(a:GetSpecialValueInt('width') or 0, 125) + 40 -- plus a hero's hull
	local reach = a:GetCastRange() + 150
	local dx, dy = at.x - p.loc.x, at.y - p.loc.y
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 1 then return 0 end
	dx, dy = dx / len, dy / len
	local n = 0
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsMagicImmune() and not e:IsIllusion() then
			local loc = e:GetExtrapolatedLocation(a:GetCastPoint() + 0.3)
			local along = (loc.x - p.loc.x) * dx + (loc.y - p.loc.y) * dy
			local side = math.abs((loc.x - p.loc.x) * dy - (loc.y - p.loc.y) * dx)
			if along >= 0 and along <= reach and side <= width then n = n + 1 end
		end
	end
	return n
end

-- Seconds a lock lasts, read live: its special value, else the ability's own duration, else LOCK_UNKNOWN. 'duration' is the key OHA
-- reads for Lion's spells (hero_lion.lua:716, Mana Drain) and is assumed for Earth Spike and Hex; a wrong key degrades to the fallbacks.
local LOCK_UNKNOWN = 1.0 -- an assumption, not measured: the order of a lane stun, so a key that reads 0 still counts the lock
local function LockSeconds(a, key)
	local v = a:GetSpecialValueFloat(key)
	if v == nil or v <= 0 then v = a:GetDuration() end
	if v == nil or v <= 0 then v = LOCK_UNKNOWN end
	return v
end

-- Each lock decision names the enemy it locks and for how long (opens, lockSec): linea.lua's Act puts it on the pair's board, so the
-- partner opens in the same second (combate.lua, package 2).
local function SpikeOn(bot, s, p, e, why)
	local a = bot:GetAbilityByName('lion_impale')
	if a == nil or not a:IsFullyCastable() or not Seen(e) or e:IsMagicImmune() then return nil end
	if D2(p.loc, e:GetLocation()) > a:GetCastRange() then return nil end
	return { intent = ON_GROUND, ability = a, at = e:GetExtrapolatedLocation(a:GetCastPoint() + 0.3), castPoint = a:GetCastPoint(),
		opens = e, lockSec = LockSeconds(a, 'duration'), reason = string.format('earth spike sobre %s: %s', Short(e), why) }
end

local function HexOn(bot, s, p, e, why)
	local a = bot:GetAbilityByName('lion_voodoo')
	if a == nil or not a:IsFullyCastable() or not Seen(e) or e:IsMagicImmune() then return nil end
	if D2(p.loc, e:GetLocation()) > a:GetCastRange() then return nil end
	return { intent = ON_UNIT, ability = a, target = e, castPoint = a:GetCastPoint(),
		opens = e, lockSec = LockSeconds(a, 'duration'), reason = string.format('hex sobre %s: %s', Short(e), why) }
end

-- Finger of Death: only to finish a visible enemy hero it kills for sure, its magic damage after resistance against the health it will
-- have when the damage lands (its regeneration over the cast point and the delay). Illusions are not worth the ultimate.
local FINGER_DELAY = 0.25 -- seconds between the cast and the damage, read in game data; a margin, not a measurement
function H.Finish(bot, s, p)
	local a = bot:GetAbilityByName('lion_finger_of_death')
	if a == nil or not a:IsFullyCastable() then return nil end
	local range = a:GetCastRange()
	local dmg = FingerDamage(bot, a)
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if Seen(e) and not e:IsMagicImmune() and not e:IsIllusion() and not e:IsInvulnerable()
			and D2(p.loc, e:GetLocation()) <= range
			and not ((s.castBan or {})[Short(e)] ~= nil and s.castBan[Short(e)] > p.now) then
			local real = e:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
			local hp = e:GetHealth() + e:GetHealthRegen() * (a:GetCastPoint() + FINGER_DELAY)
			if real >= hp then
				return { intent = ON_UNIT, ability = a, target = e, castPoint = a:GetCastPoint(),
					reason = string.format('finger sobre %s: vida %d, quita %d (punto %.1fs)', Short(e), e:GetHealth(), real, a:GetCastPoint()) }
			end
		end
	end
	return nil
end

-- In a team fight: Hex on one channelling (it interrupts it), else on the most dangerous enemy in range not already locked; then
-- Earth Spike where its line hits two or more. For the fight rule (medio.lua). Not again within a second: the order needs to land.
function H.FightCast(bot, s, p)
	if p.now - (s.lionCastAt or -1000) < 1.0 then return nil end
	local hex = bot:GetAbilityByName('lion_voodoo')
	if hex ~= nil and hex:IsFullyCastable() then
		local best, bestThreat = nil, -1
		for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
			if Seen(e) and not e:IsMagicImmune() and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= hex:GetCastRange()
				and not ((s.castBan or {})[Short(e)] ~= nil and s.castBan[Short(e)] > p.now) then
				if e:IsChanneling() then
					s.lionCastAt = p.now
					return HexOn(bot, s, p, e, 'canaliza, lo interrumpo')
				end
				if not Locked(e, 0.3) then
					-- Who hurts our side most in the next seconds, by the engine's own estimate against us.
					local threat = e:GetEstimatedDamageToTarget(true, bot, 3.0, DAMAGE_TYPE_ALL) or 0
					if threat > bestThreat then best, bestThreat = e, threat end
				end
			end
		end
		if best ~= nil then
			s.lionCastAt = p.now
			return HexOn(bot, s, p, best, string.format('el más peligroso (%d en 3s)', bestThreat))
		end
	end
	local spike = bot:GetAbilityByName('lion_impale')
	if spike ~= nil and spike:IsFullyCastable() then
		local range = spike:GetCastRange()
		local bestAt, bestN = nil, 1
		for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
			if Seen(e) and not e:IsMagicImmune() and not e:IsIllusion() and D2(p.loc, e:GetLocation()) <= range then
				local at = e:GetExtrapolatedLocation(spike:GetCastPoint() + 0.3)
				local n = SpikeHits(bot, p, spike, at)
				if n > bestN then bestAt, bestN = at, n end
			end
		end
		if bestAt ~= nil then
			s.lionCastAt = p.now
			return { intent = ON_GROUND, ability = spike, at = bestAt, castPoint = spike:GetCastPoint(),
				reason = string.format('earth spike en la pelea: %d héroes en la línea', bestN) }
		end
	end
	return nil
end

-- Earth Spike to harass, rarely: on an enemy hero in range, only when the mana left still pays for Hex and Finger and half the pool,
-- and not within 20 s of the last one. A support that spends its mana in lane has no lock when the kill comes.
-- Package 3: with a gap of 20 s and half the pool kept it cast 9,8 spikes a lane against OHA's 18,8 (MEDICIONES 2026-11-13). OHA casts it
-- on its target with the spell at level 2 or the mana over 68 % (hero_lion.lua:367-383); here a gap of 6 s and Hex and Finger's mana.
local HARASS_EVERY = 6
function H.Harass(bot, s, p)
	local a = bot:GetAbilityByName('lion_impale')
	if a == nil or not a:IsFullyCastable() then return nil end
	if p.now - (s.spikeHarassAt or -1000) < HARASS_EVERY then return nil end
	local left = bot:GetMana() - a:GetManaCost()
	if left < ManaToKeep(bot) then return nil end
	if not (a:GetLevel() >= 2 or bot:GetMana() / math.max(bot:GetMaxMana(), 1) > 0.68) then return nil end
	for _, e in ipairs(p.enemyHeroes) do
		if Seen(e) and not e:IsMagicImmune() and not e:IsIllusion() and not Locked(e, 0.3)
			and D2(p.loc, e:GetLocation()) <= a:GetCastRange() then
			local d = SpikeOn(bot, s, p, e, string.format('acoso, maná %.0f%%', 100 * bot:GetMana() / math.max(bot:GetMaxMana(), 1)))
			-- The spike keeps its `opens` (SpikeOn): a harass spike goes on the pair's board too, announced only with the partner near
			-- the target (54 harass spikes against 13 in kills, never announced: p2 logs, package 2 round 2). It drags no one in: the
			-- partner joins only when its own pair estimate gives the kill (combate.lua, Join).
			if d ~= nil then s.spikeHarassAt = p.now end
			return d
		end
	end
	return nil
end

-- Package 3: on the hero we trade hits with, as OHA on its attack target: Earth Spike with the spell at level 2, the mana over 68 % or
-- the target under half (hero_lion.lua:367-383), else Hex once the spike is not just out (0,8 s, hero_lion.lua:518) and the target is
-- not locked (611-628). Finger stays for Finish and the kills.
function H.TradeCast(bot, s, p, e)
	if not Seen(e) or e:IsMagicImmune() or e:IsIllusion() or p.now - (s.lionCastAt or -1000) < 0.8 or Locked(e, 0.3) then return nil end
	local spike = bot:GetAbilityByName('lion_impale')
	local d = nil
	if spike ~= nil and spike:IsFullyCastable() and (spike:GetLevel() >= 2 or bot:GetMana() / math.max(bot:GetMaxMana(), 1) > 0.68
		or e:GetHealth() < 0.5 * e:GetMaxHealth()) then
		d = SpikeOn(bot, s, p, e, 'en el intercambio')
	end
	d = d or HexOn(bot, s, p, e, 'en el intercambio')
	if d ~= nil then s.lionCastAt = p.now end
	return d
end

-- During a kill: lock it, then the ultimate. Earth Spike first (it stuns on landing), else Hex; a new lock only once the last one is
-- about to end. Finger when it kills (Finish catches that first) or when the target is locked and nothing else is ready.
function H.KillCast(bot, s, p, e)
	if not Seen(e) or e:IsMagicImmune() or p.now - (s.lionCastAt or -1000) < 0.5 then return nil end
	local d = nil
	if not Locked(e, 0.4) then
		d = SpikeOn(bot, s, p, e, 'en la kill') or HexOn(bot, s, p, e, 'en la kill')
	else
		local f = bot:GetAbilityByName('lion_finger_of_death')
		local spike, hex = bot:GetAbilityByName('lion_impale'), bot:GetAbilityByName('lion_voodoo')
		local otherReady = (spike ~= nil and spike:IsFullyCastable()) or (hex ~= nil and hex:IsFullyCastable())
		if f ~= nil and f:IsFullyCastable() and D2(p.loc, e:GetLocation()) <= f:GetCastRange() and not otherReady then
			d = { intent = ON_UNIT, ability = f, target = e, castPoint = f:GetCastPoint(),
				reason = string.format('finger sobre %s: bloqueado, vida %d', Short(e), e:GetHealth()) }
		end
	end
	if d ~= nil then s.lionCastAt = p.now end
	return d
end

-- Lion has nothing to cast before attacking.
function H.Aim(bot, s, p, e) return nil end

-- The seconds of lock Lion can cast on this enemy now, from where it stands (p.loc), and the longest cast range among them: Earth
-- Spike's stun, then Hex with the mana left, each ready and in range. For the pair's kill estimate (combate.lua, package 2), which
-- calls it for an ally too, with the ally's place: a locked target cannot walk out of the side's hits. Lion's lock is what it brings
-- to the lane's kill; OHA's kills in that lane open with it (fase2-ref-oha 2, t=454 Spike, 457 Hex, 459 Finger).
function H.Disable(bot, p, e)
	if e:IsMagicImmune() then return 0, 0 end
	local mana, d = bot:GetMana(), D2(p.loc, e:GetLocation())
	local secs, range = 0, 0
	for _, name in ipairs({ 'lion_impale', 'lion_voodoo' }) do
		local a = bot:GetAbilityByName(name)
		if a ~= nil and a:GetLevel() > 0 and a:IsFullyCastable() and mana >= a:GetManaCost() and d <= a:GetCastRange() then
			secs, range, mana = secs + LockSeconds(a, 'duration'), math.max(range, a:GetCastRange()), mana - a:GetManaCost()
		end
	end
	return secs, range
end

-- What the abilities add to a kill on this enemy within the window, read live, counting only what would really be cast with the mana
-- it has, in the chain's order: Earth Spike, Hex (no damage, but its cast point counts), Finger. Returns the damage and the seconds of
-- casting, in which no attack lands. For combate.lua.
function H.KillBurst(bot, p, e, window)
	local total, casting = 0, 0
	if e:IsMagicImmune() then return 0, 0 end
	local mana = bot:GetMana()
	local d = D2(p.loc, e:GetLocation())
	local spike = bot:GetAbilityByName('lion_impale')
	if spike ~= nil and spike:IsFullyCastable() and mana >= spike:GetManaCost() and d <= spike:GetCastRange() then
		total = total + e:GetActualIncomingDamage(Damage(spike, 'damage'), DAMAGE_TYPE_MAGICAL)
		casting = casting + spike:GetCastPoint()
		mana = mana - spike:GetManaCost()
	end
	local hex = bot:GetAbilityByName('lion_voodoo')
	if hex ~= nil and hex:IsFullyCastable() and mana >= hex:GetManaCost() and d <= hex:GetCastRange() then
		casting = casting + hex:GetCastPoint()
		mana = mana - hex:GetManaCost()
	end
	local f = bot:GetAbilityByName('lion_finger_of_death')
	if f ~= nil and f:IsFullyCastable() and mana >= f:GetManaCost() and d <= f:GetCastRange() then
		total = total + e:GetActualIncomingDamage(FingerDamage(bot, f), DAMAGE_TYPE_MAGICAL)
		casting = casting + f:GetCastPoint()
	end
	return total, casting
end

return H
