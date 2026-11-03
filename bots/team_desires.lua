if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end -- benchmark: Valve's bots play this team
-- dota-bot team brain (FunLib/team_brain.lua): only with the benchmark variant "cerebro = true". The API probe of the
-- brain v3's game 0 (FunLib/api_probe.lua): only with "api_sonda = true". Without either, this file defines nothing and
-- the engine keeps its default team desires, as before this file existed.
local Customize = require(GetScriptDirectory()..'/Customize/general')
local brainOn = Customize.BenchVariant.cerebro == true
local probeOn = Customize.BenchVariant.api_sonda == true
-- The first-hand map of the Bot API (FunLib/api_dump.lua, DECISIONES 2026-11-03): only with "api_volcado = true".
local dumpOn = Customize.BenchVariant.api_volcado == true
if not brainOn and not probeOn and not dumpOn then return end

local Brain = brainOn and require(GetScriptDirectory()..'/FunLib/team_brain') or nil
local Probe = probeOn and require(GetScriptDirectory()..'/FunLib/api_probe') or nil
local Dump = dumpOn and require(GetScriptDirectory()..'/FunLib/api_dump') or nil

function TeamThink()
	if Brain ~= nil then
		local ok, err = pcall(Brain.Update)
		if not ok then
			print('[bench] plan error ' .. tostring(err))
			pcall(Brain.OnError)
		end
	end
	if Probe ~= nil then
		local ok, err = pcall(Probe.Tick)
		if not ok then print('[bench] api error ' .. tostring(err)) end
	end
	if Dump ~= nil then
		local ok, err = pcall(Dump.Tick)
		if not ok then (BenchRawPrint or print)('[bench] apidump error ' .. tostring(err)) end
	end
end
