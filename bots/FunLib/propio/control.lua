-- dota-bot's own bot, first step: the full-control test (DECISIONES 2026-11-03; trabajo/prueba-control.md).
-- Benchmark variant "control_completo = <hero>[,<hero>...]" (e.g. "sniper") only: those heroes are played by FunLib/propio/linea.lua
-- through a Think() of its own in bot_generic.lua, and nothing of OHA decides for it. OHA's entry points that the
-- engine may still call for that bot (ability, item, courier, buyback and level-up thinks, purchases, a few mode
-- desires) ask Intercept() first: under control it counts the call and tells them to return without acting.
-- Without the variant, Active() is false and Intercept() is false: everything plays exactly as before.
local Variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
local C = {}

local out = BenchRawPrint or print
local calls = {}        -- pid -> { name -> count since the last report }
local lastReport = {}   -- pid -> game time of the last report

-- The heroes this match puts under full control: "sniper", or a list "luna,sniper,dragon_knight,lion,lich" (phase 2,
-- trabajo/fase2.md). A set of names, or nil.
local heroes = nil
function C.Heroes()
	local h = Variant.control_completo
	if type(h) ~= 'string' then return nil end
	if heroes == nil then
		heroes = {}
		for name in string.gmatch(h, '[^,%s]+') do heroes[name] = true end
	end
	return heroes
end

-- Is the bot running this script one under full control?
function C.Active(bot)
	local set = C.Heroes()
	if set == nil then return false end
	bot = bot or GetBot()
	if bot == nil or not bot:IsHero() or bot:IsIllusion() then return false end
	return set[(string.gsub(bot:GetUnitName(), 'npc_dota_hero_', ''))] == true
end

-- For OHA's entry points: true means "this bot is under control: do nothing". Counts each call, and every 30 s of game
-- time prints which of them the engine still calls for this bot (checklist item 3 of trabajo/prueba-control.md).
function C.Intercept(name)
	local bot = GetBot()
	if not C.Active(bot) then return false end
	local pid = bot:GetPlayerID()
	calls[pid] = calls[pid] or {}
	calls[pid][name] = (calls[pid][name] or 0) + 1
	local t = DotaTime()
	if t - (lastReport[pid] or -1000) >= 30 then
		local parts = {}
		for k, n in pairs(calls[pid]) do table.insert(parts, k .. '=' .. n) end
		table.sort(parts)
		out(string.format('[bench] prop llamadas t=%d pid=%d %s', math.floor(t), pid, table.concat(parts, ' ')))
		lastReport[pid], calls[pid] = t, {}
	end
	return true
end

return C
