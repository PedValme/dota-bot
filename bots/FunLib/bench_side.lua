-- dota-bot benchmark: true when this team must play with Valve's default bots instead of this script.
-- tools/bench/orquestador.mjs writes Customize/bench_valve_team.lua (git-ignored) with "return 2" (Radiant) or
-- "return 3" (Dire) for the run and deletes it afterwards; without that file every team plays with this script.
-- Every entry file (bot_generic, hero_selection, ability_item_usage, item_purchase, mode_*) starts with:
--   if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end
-- so that, for the Valve team, it defines nothing and the game falls back to its own bots. dofile (not require) so
-- the answer is never cached across teams.
local ok, team = pcall(dofile, GetScriptDirectory()..'/Customize/bench_valve_team')
local valve = ok and team ~= nil and team == GetTeam()
-- Each bot this script plays says so once per match ("[bench] load pid=6 team=3", one console line, also outside the
-- benchmark): the orchestrator rejects a match where one belongs to Valve's team (S6 in MEDICIONES.md), which is
-- exactly when the team file was missing. The engine's print, not OHA's silenced one.
-- All of it under pcall: at map load (hero_selection, team_desires) there is no real bot, and a failure here must
-- never stop dota-bot's scripts in a normal game.
if not valve then
	pcall(function()
		local bot = GetBot()
		if bot == nil then return end
		BenchLoaded = BenchLoaded or {}
		local pid = bot:GetPlayerID()
		if not BenchLoaded[pid] then
			BenchLoaded[pid] = true;
			(BenchRawPrint or print)(string.format("[bench] load pid=%d team=%d %s", pid, GetTeam(), bot:GetUnitName()))
		end
	end)
end
return valve
