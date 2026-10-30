-- dota-bot benchmark: observer mode. tools/bench/orquestador.mjs --observar writes Customize/bench_observe.lua
-- (git-ignored, "return true") for one match and deletes it when the match ends. With it, print reaches the console
-- log (FunLib/aba_global_overrides.lua otherwise silences it) and each bot logs its active mode every 2 seconds
-- (ability_item_usage_generic.lua). Without that file it returns false and the bot plays and logs as always.
-- dofile (not require) so a stale answer is never cached between matches.
local ok, on = pcall(dofile, GetScriptDirectory()..'/Customize/bench_observe')
return ok and on == true
