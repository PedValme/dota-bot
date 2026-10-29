-- dota-bot benchmark custom game ("dotabench", local only, never published). Launched by tools/bench/orquestador.mjs
-- with "+dota_launch_custom_game dotabench dota". It does what console arguments cannot do after the map loads:
-- keeps the human out of both teams, adds ten bots with the same five heroes on each side (bench_partida.lua, written
-- by the orchestrator per match), speeds the match up and logs a per-minute timeline of both teams. Who wins is read
-- by the orchestrator through GSI.

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

-- Humans never get a team: they watch. The setup screen can still drop the human into a free slot before the bots
-- arrive, and then Dota gives them a random hero that nobody plays (seen 2026-10-29), so it is checked again at every
-- state change and any human hero is removed.
local function IsHuman(pid)
	return pid ~= nil and pid >= 0 and PlayerResource:IsValidPlayerID(pid) and not PlayerResource:IsFakeClient(pid)
end

local function KeepHumanOut(pid, why)
	local team = PlayerResource:GetTeam(pid)
	if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
		print(string.format("[dotabench] human player %d was on team %d (%s); moving out", pid, team, why))
	end
	PlayerResource:SetCustomTeamAssignment(pid, DOTA_TEAM_NOTEAM)
	local player = PlayerResource:GetPlayer(pid)
	-- pcall: a failure here must not skip the bots or the speed-up in OnStateChange.
	if player and team ~= DOTA_TEAM_NOTEAM then pcall(player.SetTeam, player, DOTA_TEAM_NOTEAM) end
end

local function KeepHumansOut(why)
	for pid = 0, 23 do
		if IsHuman(pid) then KeepHumanOut(pid, why) end
	end
end

local function OnNpcSpawned(event)
	local unit = EntIndexToHScript(event.entindex)
	if not unit or not unit.IsRealHero or not unit:IsRealHero() then return end
	local pid = unit:GetPlayerOwnerID()
	if not IsHuman(pid) then return end
	print(string.format("[dotabench] human hero removed pid=%d team=%d %s", pid, unit:GetTeamNumber(), unit:GetUnitName()))
	KeepHumanOut(pid, "hero spawned")
	GameRules:GetGameModeEntity():SetThink(function()
		if IsValidEntity(unit) then UTIL_Remove(unit) end
		return nil
	end, "dotabench_remove_" .. tostring(event.entindex), 0.1)
end

-- Who really plays each slot, once per match: the heroes the bots end up with can differ from the ones asked for.
local function PrintRoster()
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		for i = 1, PlayerResource:GetPlayerCountForTeam(team) do
			local pid = PlayerResource:GetNthPlayerIDOnTeam(team, i)
			if pid >= 0 then
				print(string.format("[dotabench] roster team=%d pid=%d bot=%d hero=%s name=%s", team, pid,
					PlayerResource:IsFakeClient(pid) and 1 or 0, PlayerResource:GetSelectedHeroName(pid),
					tostring(PlayerResource:GetPlayerName(pid))))
			end
		end
	end
end

-- The A/B variant file the orchestrator left for dota-bot this match (bots/Customize/bench_variant.lua, the same
-- file the bots read), so the orchestrator can check the match played the variant it was meant to.
local function PrintVariant()
	local ok, variant = pcall(require, "bots.Customize.bench_variant")
	if not ok or type(variant) ~= "table" then
		print("[dotabench] variant none")
		return
	end
	local fields = {}
	for k, v in pairs(variant) do
		if k ~= "name" then table.insert(fields, tostring(k) .. "=" .. tostring(v)) end
	end
	table.sort(fields)
	print("[dotabench] variant name=" .. tostring(variant.name) .. " " .. table.concat(fields, " "))
end

local function OnStateChange()
	local cfg = MatchConfig()
	local state = GameRules:State_Get()
	KeepHumansOut("state " .. tostring(state))
	if state == DOTA_GAMERULES_STATE_HERO_SELECTION or state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		AddBots(cfg)
	elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
		AddBots(cfg)
		PrintRoster()
		PrintVariant()
		SendToServerConsole("sv_cheats 1")
		SendToServerConsole("host_timescale " .. tostring(cfg.timescale or 1))
	end
end

-- Match timeline for the benchmark: one console line per game minute (and one at the end) with both teams'
-- structures, kills and net worth. The orchestrator reads them from console.log (Dota runs with -condebug).
local function CountStanding(classname, team)
	local n = 0
	for _, unit in ipairs(Entities:FindAllByClassname(classname)) do
		if unit:GetTeamNumber() == team and unit:IsAlive() then n = n + 1 end
	end
	return n
end

local function AncientHealth(team)
	for _, unit in ipairs(Entities:FindAllByClassname("npc_dota_fort")) do
		if unit:GetTeamNumber() == team then return unit:IsAlive() and unit:GetHealth() or 0 end
	end
	return 0
end

local function NetWorth(team)
	local total = 0
	for i = 1, PlayerResource:GetPlayerCountForTeam(team) do
		local pid = PlayerResource:GetNthPlayerIDOnTeam(team, i)
		if pid >= 0 and not IsHuman(pid) then total = total + PlayerResource:GetNetWorth(pid) end
	end
	return total
end

local function PrintTimeline(event)
	local r, d = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS
	print(string.format(
		"[dotabench] timeline event=%s min=%d rk=%d dk=%d rt=%d dt=%d rb=%d db=%d rhp=%d dhp=%d rnw=%d dnw=%d",
		event, math.floor(GameRules:GetDOTATime(false, false) / 60),
		PlayerResource:GetTeamKills(r), PlayerResource:GetTeamKills(d),
		CountStanding("npc_dota_tower", r), CountStanding("npc_dota_tower", d),
		CountStanding("npc_dota_barracks", r), CountStanding("npc_dota_barracks", d),
		AncientHealth(r), AncientHealth(d), NetWorth(r), NetWorth(d)))
end

local lastMinute = -1
local function TimelineThink()
	local state = GameRules:State_Get()
	if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local minute = math.floor(GameRules:GetDOTATime(false, false) / 60)
		if minute > lastMinute then
			lastMinute = minute
			PrintTimeline("minute")
		end
	elseif state >= DOTA_GAMERULES_STATE_POST_GAME then
		PrintTimeline("end")
		return nil
	end
	return 1
end

local function OnPlayerConnect(event)
	local pid = event.PlayerID
	if IsHuman(pid) then
		KeepHumanOut(pid, "connect")
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
	ListenToGameEvent("npc_spawned", OnNpcSpawned, nil)
	-- The bots announce in chat the A/B variant they loaded (mode_farm_generic.lua); their print never reaches the log.
	ListenToGameEvent("player_chat", function(event)
		if type(event.text) == "string" and string.find(event.text, "[dotabench-bot]", 1, true) then
			print("[dotabench] bot chat " .. event.text)
		end
	end, nil)
	GameRules:GetGameModeEntity():SetThink(function() return TimelineThink() end, "dotabench_timeline", 1)
end
