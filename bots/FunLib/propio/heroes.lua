-- dota-bot's own bot: the heroes it knows (phase 2, trabajo/fase2.md). Each one brings, in its own files, its abilities module
-- (FunLib/propio/<hero>.lua, with H.DATOS: position, role, level-up order, starting items, fixed item list, Treads' stat) and its build
-- profile (FunLib/propio/perfiles/<hero>.lua). The shared code (linea.lua, compras.lua, build.lua) reads them only from here, so a
-- new hero touches no shared file but this list.
local R = {}

local NAMES = { 'luna', 'sniper', 'dragon_knight', 'lion', 'lich' }

R.MODULES, R.PROFILES = {}, {}
for _, name in ipairs(NAMES) do
	R.MODULES['npc_dota_hero_' .. name] = require(GetScriptDirectory()..'/FunLib/propio/' .. name)
	R.PROFILES['npc_dota_hero_' .. name] = require(GetScriptDirectory()..'/FunLib/propio/perfiles/' .. name)
end

-- The hero's data (H.DATOS), or an empty table for a hero it does not know.
function R.Datos(name)
	local m = R.MODULES[name]
	return m ~= nil and m.DATOS or {}
end

-- What differs by role and by reach, in one place (trabajo/plan-mejora-equipo.md, package 1: the lane rules were made for the
-- Sniper's 1 against 1, and every hero played them as a ranged core). Keys in Spanish, as H.DATOS.
-- consumibles: what Consumables (compras.lua) keeps at hand in the lane, besides the teleport. salidaExtra: bought at the start
-- after the hero's own items, when the gold left pays for it. A support gets clarities: Lich spent 17-22 % of the lane under 0,3
-- of mana (fase2-humo-equipo 1 and 2, estado lines to t=720), and Lion 74-92 s of each smoke walking to the fountain.
R.ROL = {
	nucleo = { consumibles = { 'item_flask' } },
	apoyo = { consumibles = { 'item_flask', 'item_clarity' }, salidaExtra = { 'item_clarity' } },
}
-- soltarAggroHp: a step back from two or more creeps hitting us only at or under this health. A melee hero stands among the
-- creeps to last-hit: Dragon Knight stepped back 43 times in one smoke, at 0,75-0,99 of health (fase2-humo-equipo 1). For it, the
-- health under which a retreat holds it out of the lane (linea.lua, returnHp); a ranged hero steps back at any health, as before.
-- contestaDesde: how far beyond its attack range it walks to answer a hit (linea.lua, RuleTrade). A melee hero only from its reach
-- (the 50 of RuleTrade's inRange), so it does not walk into the two of them; a ranged one keeps the 200 it had (linea.lua's old
-- answerReach: one step, not letting nukes go free).
-- presionaDesde (guides package, rule A, variant guias1_presion): how far beyond its range a melee hero walks to press, from 0,6 of
-- health up. linea.lua's K.pressReach (300) was set for the Sniper: Dragon Knight (150 + 300 = 450) stood idle with the laner at 450-700
-- and the trade in its favour (p4r2 logs); two DK guides trade hits with the laner (trabajo/guias/dragon_knight.md, rule 7).
R.ALCANCE = {
	cuerpo = { soltarAggroHp = 0.65, contestaDesde = 50, presionaDesde = 550, presionaHp = 0.6 },
	distancia = { soltarAggroHp = 1.0, contestaDesde = 200 },
}
-- Under this attack range a hero is melee (Dragon Knight 150; the shortest ranged one here, Luna, 330). Read live each time, so
-- Elder Dragon Form, which makes Dragon Knight ranged, counts as ranged.
R.CUERPO_A_CUERPO = 300

-- The role's and the reach's parameters for this bot. A hero it does not know counts as a core, as in linea.lua's RuleLastHit.
function R.Rol(bot)
	local rol = R.ROL[R.Datos(bot:GetUnitName()).rol or 'nucleo'] or R.ROL.nucleo
	local alcance = bot:GetAttackRange() < R.CUERPO_A_CUERPO and R.ALCANCE.cuerpo or R.ALCANCE.distancia
	return rol, alcance
end

-- Treads: the parts that give each stat, and the stat the API reads for it. The API reads intellect for real agility and the other way
-- round (read in OHA, ability_item_usage_generic; the log line of each change checks it); strength is assumed to read as itself.
R.BOTAS = {
	agilidad = { partes = { 'item_boots', 'item_gloves', 'item_boots_of_elves' }, api = ATTRIBUTE_INTELLECT },
	inteligencia = { partes = { 'item_boots', 'item_gloves', 'item_robe' }, api = ATTRIBUTE_AGILITY },
	fuerza = { partes = { 'item_boots', 'item_gloves', 'item_belt_of_strength' }, api = ATTRIBUTE_STRENGTH },
}

return R
