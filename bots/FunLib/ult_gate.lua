-- Ultimate gate (benchmark variant filtro_ultis; off by default). Pedro, 2026-10-31: ultimates were seen cast on
-- creeps or at nothing in the own base. Measured in the observer logs: 10 % of dota-bot's ultimates had no enemy
-- hero within 1200 (Valve's bots: 23 %); most were legitimate (pushing buildings, global or ally-saving ultimates),
-- but Skywrath's Mystic Flare hit nothing in its own base 6 times and Dragon Knight's dragon form was spent at home.
-- It wraps the bot's cast orders once, here, instead of touching the 127 hero files, and only judges ultimates:
--   allowed always: global, ally-saving and escape ultimates (ALWAYS);
--   on a unit: an ally, or an enemy hero; a creep or a building only for the ultimates in ON_UNITS;
--   on a point: a visible enemy hero within POINT_RADIUS of it;
--   with no target: a visible enemy hero within SELF_RADIUS of the caster, or, for PUSH ultimates, an enemy building
--   within BUILDING_RADIUS (Death Prophet's exorcism and Chaos Knight's illusions take towers down).
-- A refused cast does nothing this frame; the hero's ability logic tries again when it sees a reason.
local variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
if not variant.filtro_ultis then return end
local observe = dofile(GetScriptDirectory()..'/FunLib/bench_observe')

local POINT_RADIUS = 700
local SELF_RADIUS = 1600
local BUILDING_RADIUS = 1000

local ALWAYS = {
	zuus_thundergods_wrath = true, silencer_global_silence = true, furion_wrath_of_nature = true,
	spectre_haunt = true, ancient_apparition_ice_blast = true, oracle_false_promise = true,
	omniknight_guardian_angel = true, vengefulspirit_nether_swap = true, abaddon_borrowed_time = true,
	wisp_relocate = true, tinker_rearm = true, invoker_invoke = true, mirana_invis = true,
	storm_spirit_ball_lightning = true, weaver_time_lapse = true, slark_shadow_dance = true,
	nyx_assassin_vendetta = true, chen_hand_of_god = true, dazzle_bad_juju = true,
	keeper_of_the_light_spirit_form = true, morphling_replicate = true, morphling_morph_replicate = true,
	lone_druid_true_form = true, lycan_shapeshift = true, terrorblade_sunder = true,
}
local ON_UNITS = { chen_holy_persuasion = true, enchantress_enchant = true }
local PUSH = { death_prophet_exorcism = true, chaos_knight_phantasm = true, dragon_knight_elder_dragon_form = true }

local function EnemyHeroNear(loc, radius)
	for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if enemy and enemy:IsAlive() and not enemy:IsIllusion() and GetUnitToLocationDistance(enemy, loc) <= radius then
			return true
		end
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
	if ability == nil or ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE then return true end
	local name = ability:GetName()
	if ALWAYS[name] then return true end
	if kind == 'none' then
		local here = bot:GetLocation()
		return EnemyHeroNear(here, SELF_RADIUS) or (PUSH[name] == true and EnemyBuildingNear(here, BUILDING_RADIUS))
	end
	if kind == 'unit' then
		if target == nil then return true end
		if target:GetTeam() == bot:GetTeam() then return true end
		if target:IsHero() and not target:IsIllusion() then return true end
		return ON_UNITS[name] == true
	end
	return target == nil or EnemyHeroNear(target, POINT_RADIUS)
end

local function Refuse(bot, ability)
	if observe then
		print(string.format("[bench] ult_bloqueada t=%d pid=%d %s %s", math.floor(DotaTime()), bot:GetPlayerID(),
			bot:GetUnitName(), ability:GetName()))
	end
end

-- Every order a hero script can cast with, same signatures as the API: (ability), (ability, unit), (ability, point).
local function Wrap(method, kind)
	local original = CDOTA_Bot_Script[method]
	if original == nil then return end
	CDOTA_Bot_Script[method] = function(bot, ability, target)
		-- Any error in the gate lets the cast through: it must never stop a hero from casting.
		local ok, allowed = pcall(Allowed, bot, ability, kind, target)
		if not ok or allowed then return original(bot, ability, target) end
		Refuse(bot, ability)
	end
end

for _, prefix in ipairs({ 'Action_', 'ActionPush_', 'ActionQueue_' }) do
	Wrap(prefix .. 'UseAbility', 'none')
	Wrap(prefix .. 'UseAbilityOnEntity', 'unit')
	Wrap(prefix .. 'UseAbilityOnLocation', 'point')
end
