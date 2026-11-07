-- dota-bot benchmark: one line per minute of game time with the lane numbers of one hero, the same for both arms of
-- the full-control test (trabajo/prueba-control.md): "[bench] linea t=300 pid=7 heroe=sniper lh=21 dn=4 nw=2100 ...".
-- Benchmark variant "linea_heroe = <hero>" only; without it Tick() returns at once. Called every frame from OHA's
-- BuybackUsageThink and from the own Think(): it prints at most once per minute per hero, whoever calls it.
local Variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
local R = {}

local out = BenchRawPrint or print
local lastMinute = {} -- pid -> last minute printed

function R.Tick(bot)
	local hero = Variant.linea_heroe
	if type(hero) ~= 'string' or bot == nil or bot:GetUnitName() ~= 'npc_dota_hero_' .. hero then return end
	local t = DotaTime()
	local minute = math.floor(t / 60)
	local pid = bot:GetPlayerID()
	if t < 0 or minute <= (lastMinute[pid] or -1) then return end
	lastMinute[pid] = minute
	out(string.format('[bench] linea t=%d pid=%d team=%d heroe=%s lh=%d dn=%d nw=%d oro=%d nivel=%d muertes=%d kills=%d vivo=%d control=%s',
		math.floor(t), pid, GetTeam(), hero, bot:GetLastHits(), bot:GetDenies(), bot:GetNetWorth(), bot:GetGold(),
		bot:GetLevel(), GetHeroDeaths(pid), GetHeroKills(pid), bot:IsAlive() and 1 or 0,
		tostring(Variant.control_completo ~= nil)))
	-- In a human's lobby there is no observer: the gold of the allies, to see whether OHA also leaves it unspent in real Turbo.
	if Variant.lobby_mid == nil then return end
	for _, a in ipairs(GetUnitList(UNIT_LIST_ALLIED_HEROES) or {}) do
		if a ~= bot and a:IsHero() and not a:IsIllusion() then
			out(string.format('[bench] aliado t=%d pid=%d heroe=%s nw=%d oro=%d', math.floor(t), a:GetPlayerID(),
				(string.gsub(a:GetUnitName(), 'npc_dota_hero_', '')), a:GetNetWorth() or -1, a:GetGold() or -1))
		end
	end
end

return R
