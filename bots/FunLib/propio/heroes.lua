-- dota-bot's own bot: the heroes it knows (phase 2, trabajo/fase2.md). Each one brings, in its own files, its abilities module
-- (FunLib/propio/<hero>.lua, with H.DATOS: position, role, level-up order, starting items, fixed item list, Treads' stat) and its build
-- profile (FunLib/propio/perfiles/<hero>.lua). The shared code (linea.lua, compras.lua, build.lua) reads them only from here, so a
-- new hero touches no shared file but this list.
local R = {}

local NAMES = { 'sniper' }

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

-- Treads: the parts that give each stat, and the stat the API reads for it. The API reads intellect for real agility and the other way
-- round (read in OHA, ability_item_usage_generic; the log line of each change checks it); strength is assumed to read as itself.
R.BOTAS = {
	agilidad = { partes = { 'item_boots', 'item_gloves', 'item_boots_of_elves' }, api = ATTRIBUTE_INTELLECT },
	inteligencia = { partes = { 'item_boots', 'item_gloves', 'item_robe' }, api = ATTRIBUTE_AGILITY },
	fuerza = { partes = { 'item_boots', 'item_gloves', 'item_belt_of_strength' }, api = ATTRIBUTE_STRENGTH },
}

return R
