-- dota-bot benchmark: true when this team must play with Valve's default bots instead of this script.
-- tools/bench/orquestador.mjs writes Customize/bench_valve_team.lua (git-ignored) with "return 2" (Radiant) or
-- "return 3" (Dire) for the run and deletes it afterwards; without that file every team plays with this script.
-- Every entry file (bot_generic, hero_selection, ability_item_usage, item_purchase, mode_*) starts with:
--   if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end
-- so that, for the Valve team, it defines nothing and the game falls back to its own bots. dofile (not require) so
-- the answer is never cached across teams.
local ok, team = pcall(dofile, GetScriptDirectory()..'/Customize/bench_valve_team')
return ok and team ~= nil and team == GetTeam()
