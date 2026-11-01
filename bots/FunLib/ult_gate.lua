-- Ultimate gate (benchmark variant filtro_ultis; off by default). Pedro, 2026-10-31: ultimates were seen cast on
-- creeps or at nothing in the own base. Measured in the observer logs: 10 % of dota-bot's ultimates had no enemy
-- hero within 1200 (Valve's bots: 23 %); most were legitimate (pushing buildings, global or ally-saving ultimates),
-- but Skywrath's Mystic Flare hit nothing in its own base 6 times and Dragon Knight's dragon form was spent at home.
-- It wraps the bot's cast orders once, here, instead of touching the 127 hero files, and only judges ultimates
-- (IsUltimate), never toggles (Leshrac must be able to switch Pulse Nova off). An ultimate needs a reason:
--   always: global, ally-saving, escape, summoning or farming ultimates (ALWAYS);
--   on a unit: an ally, an enemy hero (not an illusion) or an enemy building;
--   on a point: an enemy hero within POINT_RADIUS of it or an enemy building within BUILDING_RADIUS;
--   with no target: an enemy hero within SELF_RADIUS of the caster or an enemy building within BUILDING_RADIUS.
-- OHA's hero scripts clear the bot's orders before a cast (J.SetQueuePtToINT); with the gate on, that clear waits for
-- the cast (J.SetQueuePtToINT defers it, Flush runs it), so a refused cast leaves the mode's orders alone instead of
-- freezing the hero (review 2026-10-31).
local variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
if not variant.filtro_ultis then return end
local observe = dofile(GetScriptDirectory()..'/FunLib/bench_observe')
UltGateDeferPt = true

local POINT_RADIUS = 700
local SELF_RADIUS = 1600
local BUILDING_RADIUS = 1000

local ALWAYS = {
	-- global or ally-saving
	zuus_thundergods_wrath = true, silencer_global_silence = true, furion_wrath_of_nature = true,
	spectre_haunt = true, ancient_apparition_ice_blast = true, ancient_apparition_ice_blast_release = true,
	oracle_false_promise = true, omniknight_guardian_angel = true, vengefulspirit_nether_swap = true,
	abaddon_borrowed_time = true, wisp_relocate = true, chen_hand_of_god = true, dazzle_bad_juju = true,
	centaur_stampede = true, dawnbreaker_solar_guardian = true, terrorblade_sunder = true,
	-- escape, invisibility or mobility
	storm_spirit_ball_lightning = true, weaver_time_lapse = true, slark_shadow_dance = true,
	mirana_invis = true, nyx_assassin_vendetta = true, ember_spirit_fire_remnant = true,
	-- summons, farming and self forms cast away from enemies on purpose
	visage_summon_familiars = true, arc_warden_tempest_double = true, templar_assassin_psionic_trap = true,
	alchemist_chemical_rage = true, broodmother_insatiable_hunger = true, lone_druid_true_form = true,
	lycan_shapeshift = true, keeper_of_the_light_spirit_form = true, life_stealer_infest = true,
	life_stealer_consume = true, morphling_replicate = true, morphling_morph_replicate = true,
	tinker_rearm = true, invoker_invoke = true,
}

local J -- jmz_func, loaded lazily: it is not loaded yet when this file runs

local function RealEnemyHero(unit)
	if unit == nil or not unit:IsAlive() or not unit:IsHero() or unit:IsIllusion() then return false end
	J = J or require(GetScriptDirectory()..'/FunLib/jmz_func')
	return not (J.IsSuspiciousIllusion and J.IsSuspiciousIllusion(unit))
end

local function EnemyHeroNear(loc, radius)
	for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if RealEnemyHero(enemy) and GetUnitToLocationDistance(enemy, loc) <= radius then return true end
	end
	return false
end

local function EnemyBuildingNear(loc, radius)
	for _, b in pairs(GetUnitList(UNIT_LIST_ENEMY_BUILDINGS) or {}) do
		if b and b:IsAlive() and GetUnitToLocationDistance(b, loc) <= radius then return true end
	end
	return false
end

-- kind: 'none', 'unit' or 'point', from the order used.
local function Allowed(bot, ability, kind, target)
	if ability == nil or not ability:IsUltimate() or ability:IsToggle() then return true end
	if ALWAYS[ability:GetName()] then return true end
	if kind == 'none' then
		local here = bot:GetLocation()
		return EnemyHeroNear(here, SELF_RADIUS) or EnemyBuildingNear(here, BUILDING_RADIUS)
	end
	if kind == 'unit' then
		if target == nil or target:GetTeam() == bot:GetTeam() then return true end
		return RealEnemyHero(target) or target:IsBuilding()
	end
	return target == nil or EnemyHeroNear(target, POINT_RADIUS) or EnemyBuildingNear(target, BUILDING_RADIUS)
end

-- The clear and the power treads switch that J.SetQueuePtToINT deferred, done right before an allowed cast.
local function Flush(bot)
	local pending = bot.__ultGatePt
	if pending == nil then return end
	bot.__ultGatePt = nil
	J = J or require(GetScriptDirectory()..'/FunLib/jmz_func')
	J.SetQueuePtToINTNow(bot, pending.soul)
end

local refusedAt = {}
local function Refuse(bot, ability)
	bot.__ultGatePt = nil -- the mode's orders stay
	if observe then
		-- One line per hero and ultimate every 5 s at most: a hero that keeps asking shows as repeated lines.
		local key = bot:GetPlayerID() .. ability:GetName()
		if (refusedAt[key] or -99) + 5 <= DotaTime() then
			refusedAt[key] = DotaTime()
			print(string.format("[bench] ult_bloqueada t=%d pid=%d %s %s", math.floor(DotaTime()), bot:GetPlayerID(),
				bot:GetUnitName(), ability:GetName()))
		end
	end
end

local reported = false
-- Every order a hero script can cast with, same signatures as the API: (ability), (ability, unit), (ability, point).
local function Wrap(method, kind)
	local original = CDOTA_Bot_Script[method]
	if original == nil then return end
	CDOTA_Bot_Script[method] = function(bot, ability, target)
		-- An error in the gate lets the cast through (it must never stop a hero), and is reported once.
		local ok, allowed = pcall(Allowed, bot, ability, kind, target)
		if not ok and not reported and observe then
			reported = true
			print("[bench] ult_gate error: " .. tostring(allowed))
		end
		if not ok or allowed then
			Flush(bot)
			return original(bot, ability, target)
		end
		Refuse(bot, ability)
	end
end

for _, prefix in ipairs({ 'Action_', 'ActionPush_', 'ActionQueue_' }) do
	Wrap(prefix .. 'UseAbility', 'none')
	Wrap(prefix .. 'UseAbilityOnEntity', 'unit')
	Wrap(prefix .. 'UseAbilityOnLocation', 'point')
end
