-- dota-bot benchmark: the heroes drawn for this match, one per position (Pedro, 2026-10-31: a side must not compare
-- different line-ups). tools/bench/orquestador.mjs writes Customize/bench_heroes.lua (git-ignored) for each match and
-- deletes it when the match ends; hero_selection.lua then picks these instead of drafting. The custom game gives
-- Radiant its heroes itself, but Dire's bots pick their own, so this mirrors them whenever dota-bot plays Dire. Without
-- that file it returns nil and the draft runs as always.
-- dofile (not require) so a stale answer is never cached between matches.
local ok, heroes = pcall(dofile, GetScriptDirectory()..'/Customize/bench_heroes')
if ok and type(heroes) == 'table' then return heroes end
return nil
