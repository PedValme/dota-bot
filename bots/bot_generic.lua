if dofile(GetScriptDirectory()..'/FunLib/bench_side') then return end -- benchmark: Valve's bots play this team
local bot = GetBot()
local botName = bot:GetUnitName()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not string.find(botName, "hero") or bot:IsIllusion() then return end

-- Full-control test (trabajo/prueba-control.md): with the benchmark variant "control_completo = <hero>", that hero
-- gets a Think() of its own here, so the engine runs neither Valve's modes nor OHA's for it (Valve's wiki, "Complete
-- takeover"); every other bot, and every match without the variant, defines no Think and plays as before.
local Control = require(GetScriptDirectory()..'/FunLib/propio/control')
if Control.Active(bot) then
	local Linea = require(GetScriptDirectory()..'/FunLib/propio/linea')
	function Think()
		local ok, err = pcall(Linea.Think)
		if not ok then pcall(Linea.OnError, err) end
	end
end

local Utils = require( GetScriptDirectory()..'/FunLib/utils' )
local BotBuild = dofile(GetScriptDirectory() .. "/BotLib/" .. string.gsub(botName, "npc_dota_", ""));

if BotBuild == nil
then
	print('[ERROR] No build config file found for bot: '..botName)
	return
end

function MinionThink(hMinionUnit)
	if not Utils.IsValidUnit(hMinionUnit) then return end
	if hMinionUnit.lastMinionFrameProcessTime == nil then hMinionUnit.lastMinionFrameProcessTime = DotaTime() end
	if DotaTime() - hMinionUnit.lastMinionFrameProcessTime < 0.3 then return end
	hMinionUnit.lastMinionFrameProcessTime = DotaTime()

	BotBuild.MinionThink(hMinionUnit)
end
