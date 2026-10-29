-- dota-bot benchmark: the A/B variant this match plays, so one series can alternate versions of the bot under the same
-- conditions. tools/bench/orquestador.mjs writes Customize/bench_variant.lua (git-ignored) for each match, e.g.
-- "return { empuje = false, thinkless = 1 }", and deletes it when the match ends. Without that file it returns an
-- empty table and the bot plays its normal, current code. Fields:
--   empuje    false: the push caps before PR #11 (no relaxing with a 10k net worth lead), FunLib/aba_push.lua
--   thinkless number: overrides Customize.ThinkLess, Customize/general.lua
-- dofile (not require) so a stale answer is never cached between matches.
local ok, variant = pcall(dofile, GetScriptDirectory()..'/Customize/bench_variant')
if ok and type(variant) == 'table' then return variant end
return {}
