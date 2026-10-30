if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end -- benchmark: Valve's bots play this team
-- dota-bot team brain (FunLib/team_brain.lua): only with the benchmark variant "cerebro = true". Without it this file
-- defines nothing and the engine keeps its default team desires, as before this file existed.
local Customize = require(GetScriptDirectory()..'/Customize/general')
if Customize.BenchVariant.cerebro ~= true then return end

local Brain = require(GetScriptDirectory()..'/FunLib/team_brain')

function TeamThink()
	local ok, err = pcall(Brain.Update)
	if not ok then print('[bench] plan error ' .. tostring(err)) end
end
