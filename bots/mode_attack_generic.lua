if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end -- benchmark: Valve's bots play this team
local bot = GetBot()
local botName = bot:GetUnitName()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local Utils = require( GetScriptDirectory()..'/FunLib/utils')

local local_mode_attack_generic
if bot:IsInvulnerable() or not bot:IsHero() or not string.find(botName, "hero") or bot:IsIllusion() then
	return
end

if Utils.BuggyHeroesDueToValveTooLazy[botName] then
	local_mode_attack_generic = dofile( GetScriptDirectory().."/FunLib/override_generic/mode_attack_generic" )
end

-- dota-bot brain v3, game 0 (benchmark variant "api_sonda" only): every other hero gets a GetDesire that a plan can
-- set to 0 and otherwise returns nil (Valve's own desire); Think stays Valve's. FunLib/api_probe.lua.
local Customize = require(GetScriptDirectory()..'/Customize/general')
if local_mode_attack_generic == nil and Customize.BenchVariant.api_sonda == true then
	local Probe = require(GetScriptDirectory()..'/FunLib/api_probe')
	function GetDesire() return Probe.AttackDesire(bot) end
end

if local_mode_attack_generic ~= nil then
	function GetDesire() return local_mode_attack_generic.GetDesire() end
	function Think() return local_mode_attack_generic.Think() end
	function OnStart() return local_mode_attack_generic.OnStart() end
	function OnEnd() return local_mode_attack_generic.OnEnd() end
end