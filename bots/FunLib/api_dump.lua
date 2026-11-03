-- dota-bot: first-hand map of the Bot API (DECISIONES 2026-11-03). Valve's wiki page is from 2016-2017 and the engine
-- offers more than it documents, so this asks the engine itself, from inside a bot script, what it gives scripts:
--   g    every global: name, type (and the value of numbers and strings: the constants);
--   t    every member of every global table (Valve's classes, the Lua libraries the sandbox keeps);
--   h    the methods a handle of each kind really answers (hero, ability, item, creep, tower, courier), walking its
--        metatable chain and naming each level by the global table it is;
--   u    the stats of each non-hero unit seen (lane creeps, towers, barracks...), first sighting only, for the last-hit
--        and lane maths (Valve's npc_units.txt is packed in the game files).
-- Benchmark variant "api_volcado = true" only: team_desires.lua calls Dump.Tick() once per frame for the team. It only
-- reads and prints "[bench] apidump ..." lines with the engine's print; it never orders a bot. Everything runs under
-- pcall: a failing read prints "err=" and goes on. Reading what the engine exposes to Lua is not reverse engineering.
local D = {}

local out = BenchRawPrint or print
local function P(s) out('[bench] apidump ' .. s) end

local done = { globals = false, handles = false }
local seenUnits = {}
local nextScan = -1000
local UNIT_UNTIL = 23 * 60 -- stop reading unit kinds after minute 23 (bands 0, 7.5 and 15 minutes)

local function Sorted(tbl)
	local keys = {}
	for k in pairs(tbl) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	return keys
end

-- Functions say where they come from: "C" is the engine's own; "Lua" is a script (OHA replaces some of Valve's API
-- calls in FunLib/aba_global_overrides.lua, and the team's VM is shared with OHA's scripts), with its file and line.
local function Origin(f)
	if type(debug) ~= 'table' or type(debug.getinfo) ~= 'function' then return 'origen=sin-debug' end
	local ok, info = pcall(debug.getinfo, f, 'S')
	if not ok or type(info) ~= 'table' then return 'origen=?' end
	if info.what == 'C' then return 'C' end
	return 'Lua ' .. tostring(info.short_src) .. ':' .. tostring(info.linedefined)
end

local function Val(v)
	local ty = type(v)
	if ty == 'number' or ty == 'boolean' then return ty .. ' ' .. tostring(v) end
	if ty == 'string' then return 'string ' .. string.format('%q', v):gsub('\n', 'n') end
	if ty == 'function' then return 'function ' .. Origin(v) end
	return ty
end

-- Global tables by identity, to name the levels of a handle's metatable chain.
local function TableNames()
	local names = {}
	for _, k in ipairs(Sorted(_G)) do
		local v = rawget(_G, k)
		if type(v) == 'table' and names[v] == nil then names[v] = tostring(k) end
	end
	return names
end

local function DumpGlobals()
	local n = 0
	local tables = {}
	for _, k in ipairs(Sorted(_G)) do
		local v = rawget(_G, k)
		P('g ' .. tostring(k) .. ' ' .. Val(v))
		n = n + 1
		if type(v) == 'table' and v ~= _G then table.insert(tables, tostring(k)) end
	end
	for _, name in ipairs(tables) do
		local tbl = rawget(_G, name)
		local ok, err = pcall(function()
			for _, k in ipairs(Sorted(tbl)) do P('t ' .. name .. '.' .. tostring(k) .. ' ' .. Val(rawget(tbl, k))) end
		end)
		if not ok then P('t ' .. name .. ' err=' .. tostring(err)) end
	end
	-- Globals the sandbox may serve through _G's own metatable instead of storing them in _G.
	local gmt = getmetatable(_G)
	if type(gmt) == 'table' and type(rawget(gmt, '__index')) == 'table' then
		local idx = rawget(gmt, '__index')
		for _, k in ipairs(Sorted(idx)) do P('gmeta ' .. tostring(k) .. ' ' .. Val(rawget(idx, k))) end
	else
		P('gmeta ' .. (gmt == nil and 'sin metatabla' or ('__index=' .. type(type(gmt) == 'table' and rawget(gmt, '__index') or gmt))))
	end
	P(string.format('fin globales n=%d tablas=%d', n, #tables))
end

local function DumpHandle(kind, h)
	if h == nil then P('h ' .. kind .. ' nil') return end
	local names = TableNames()
	P('h ' .. kind .. ' type=' .. type(h))
	local mt = getmetatable(h)
	local level = 0
	if mt ~= nil and type(mt) ~= 'table' then P('h ' .. kind .. ' metatabla protegida=' .. type(mt)) end
	while type(mt) == 'table' and level < 8 do
		local idx = rawget(mt, '__index')
		if type(idx) ~= 'table' then
			P(string.format('h %s nivel=%d __index=%s', kind, level, type(idx)))
			break
		end
		P(string.format('h %s nivel=%d clase=%s', kind, level, names[idx] or '?'))
		for _, k in ipairs(Sorted(idx)) do P(string.format('h %s %d %s %s', kind, level, tostring(k), Val(rawget(idx, k)))) end
		mt = getmetatable(idx)
		level = level + 1
	end
	if mt == nil and level == 0 then P('h ' .. kind .. ' sin metatabla') end
end

local function FirstItem(hero)
	for slot = 0, 16 do
		local it = hero:GetItemInSlot(slot)
		if it ~= nil then return it end
	end
	return nil
end

local function FirstOf(listType)
	local list = GetUnitList(listType)
	return list ~= nil and list[1] or nil
end

local function DumpHandles()
	local hero = GetTeamMember(1)
	if hero == nil then return false end
	pcall(function() DumpHandle('heroe', hero) end)
	pcall(function() DumpHandle('habilidad', hero:GetAbilityInSlot(0)) end)
	pcall(function() DumpHandle('objeto', FirstItem(hero)) end)
	pcall(function() DumpHandle('creep', FirstOf(UNIT_LIST_ALLIED_CREEPS)) end)
	pcall(function() DumpHandle('edificio', FirstOf(UNIT_LIST_ALLIED_BUILDINGS)) end)
	pcall(function() DumpHandle('mensajero', GetCourier(0)) end)
	P('fin handles')
	return true
end

local GETTERS = { 'GetMaxHealth', 'GetHealthRegen', 'GetBaseDamage', 'GetBaseDamageVariance', 'GetAttackDamage',
	'GetAttackRange', 'GetAttackSpeed', 'GetSecondsPerAttack', 'GetAttackPoint', 'GetAttackProjectileSpeed',
	'GetAcquisitionRange', 'GetArmor', 'GetMagicResist', 'GetBaseMovementSpeed', 'GetCurrentMovementSpeed',
	'GetBoundingRadius', 'GetBountyGoldMin', 'GetBountyGoldMax', 'GetBountyXP', 'GetDayTimeVisionRange',
	'GetNightTimeVisionRange' }

local function DumpUnit(u)
	local parts = { 'u t=' .. string.format('%.0f', DotaTime()), u:GetUnitName(), 'team=' .. tostring(u:GetTeam()) }
	for _, g in ipairs(GETTERS) do
		local ok, v = pcall(function() return u[g](u) end)
		table.insert(parts, g:gsub('^Get', '') .. '=' .. (ok and (type(v) == 'number' and string.format('%.3f', v) or tostring(v)) or 'err'))
	end
	P(table.concat(parts, ' '))
end

-- Lane creeps grow stronger as the game goes on, so each kind is read again every 7.5 minutes of game time.
local function ScanUnits()
	local band = math.floor(DotaTime() / 450)
	for _, u in ipairs(GetUnitList(UNIT_LIST_ALL) or {}) do
		local ok, name = pcall(function() return (u ~= nil and not u:IsHero()) and u:GetUnitName() or nil end)
		if ok and name ~= nil and not seenUnits[name .. '#' .. band] then
			seenUnits[name .. '#' .. band] = true
			pcall(DumpUnit, u)
		end
	end
end

function D.Tick()
	if not done.globals then
		done.globals = true
		local ok, err = pcall(DumpGlobals)
		if not ok then P('globales err=' .. tostring(err)) end
	end
	local t = DotaTime()
	if not done.handles and t > 0 then
		local ok, res = pcall(DumpHandles)
		if not ok then P('handles err=' .. tostring(res)) end
		done.handles = (not ok) or res
	end
	if t > nextScan and t < UNIT_UNTIL then
		nextScan = t + 5
		local ok, err = pcall(ScanUnits)
		if not ok then P('unidades err=' .. tostring(err)) end
	end
end

return D
