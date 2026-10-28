-- dota-bot benchmark custom game ("dotabench", local only, never published). Launched by tools/bench/orquestador.mjs
-- with "+dota_launch_custom_game dotabench dota". It does what console arguments cannot do after the map loads:
-- keeps the human out of both teams, adds ten bots with the same five heroes on each side (bench_partida.lua, written
-- by the orchestrator per match) and speeds the match up. Who wins is read by the orchestrator through GSI.

local DEFAULT = {
	difficulty = "unfair",
	timescale = 4,
	heroes = { "npc_dota_hero_juggernaut", "npc_dota_hero_lina", "npc_dota_hero_axe", "npc_dota_hero_lion", "npc_dota_hero_crystal_maiden" },
}
-- Lane per slot (pos 1 to 5): safe lane is bot for Radiant and top for Dire.
local LANES = {
	[DOTA_TEAM_GOODGUYS] = { "bot", "mid", "top", "top", "bot" },
	[DOTA_TEAM_BADGUYS] = { "top", "mid", "bot", "bot", "top" },
}

local function MatchConfig()
	local ok, cfg = pcall(require, "bench_partida")
	if ok and type(cfg) == "table" then return cfg end
	print("[dotabench] no bench_partida.lua; using defaults")
	return DEFAULT
end

local botsAdded = false

local function AddBots(cfg)
	if botsAdded then return end
	botsAdded = true
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		for slot, hero in ipairs(cfg.heroes) do
			local ok = Tutorial:AddBot(hero, LANES[team][slot], cfg.difficulty, team == DOTA_TEAM_GOODGUYS)
			print(string.format("[dotabench] AddBot team=%d slot=%d %s -> %s", team, slot, hero, tostring(ok)))
		end
	end
end

local function OnStateChange()
	local cfg = MatchConfig()
	local state = GameRules:State_Get()
	if state == DOTA_GAMERULES_STATE_HERO_SELECTION or state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		AddBots(cfg)
	elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
		AddBots(cfg)
		SendToServerConsole("sv_cheats 1")
		SendToServerConsole("host_timescale " .. tostring(cfg.timescale or 1))
	end
end

-- Humans never get a team: they watch.
local function OnPlayerConnect(event)
	local pid = event.PlayerID
	if pid ~= nil and PlayerResource:IsValidPlayerID(pid) and not PlayerResource:IsFakeClient(pid) then
		PlayerResource:SetCustomTeamAssignment(pid, DOTA_TEAM_NOTEAM)
		print("[dotabench] human player " .. tostring(pid) .. " kept out of the teams")
	end
end

function Precache(context)
end

function Activate()
	print("[dotabench] loaded")
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 5)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 5)
	GameRules:SetCustomGameSetupAutoLaunchDelay(0)
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetHeroSelectionTime(5)
	GameRules:SetStrategyTime(0)
	GameRules:SetShowcaseTime(0)
	GameRules:SetPreGameTime(30)
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:GetGameModeEntity():SetBotThinkingEnabled(true)
	ListenToGameEvent("game_rules_state_change", OnStateChange, nil)
	ListenToGameEvent("player_connect_full", OnPlayerConnect, nil)
end
