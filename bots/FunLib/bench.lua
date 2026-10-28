-- dota-bot benchmark logger. One bot per team running this script (the lowest player ID) prints the match state to
-- the console as "[BENCH] key=value ..." lines: once at the horn, every 30 s of game time, on every check while an
-- Ancient is below 1500 HP, and once when the game ends (if bots still think in post-game). tools/bench/resumen.mjs
-- reads them from console.log (Dota launched with -condebug). Only reads game state; off with Customize.Bench = false.
local Customize = require(GetScriptDirectory()..'/Customize/general')

local X = {}

local VERSION = 1
local CHECK_EVERY = 0.25 -- real seconds; the caller runs every frame and DotaTime() stops when the game ends
local towers = {
	TOWER_TOP_1, TOWER_TOP_2, TOWER_TOP_3, TOWER_MID_1, TOWER_MID_2, TOWER_MID_3,
	TOWER_BOT_1, TOWER_BOT_2, TOWER_BOT_3, TOWER_BASE_1, TOWER_BASE_2,
}

local nextReport = nil
local nextCheck = 0
local reportedEnd = false

local function IsReporter(bot)
	local lowest = nil
	for _, id in ipairs(GetTeamPlayers(GetTeam())) do
		if IsPlayerBot(id) and (lowest == nil or id < lowest) then lowest = id end
	end
	return lowest ~= nil and bot:GetPlayerID() == lowest
end

local function AncientHealth(team)
	local ancient = GetAncient(team)
	if ancient ~= nil and ancient:IsAlive() then return ancient:GetHealth() end
	return 0
end

local function TeamState(team)
	local kills, deaths, heroes = 0, 0, {}
	for _, id in ipairs(GetTeamPlayers(team)) do
		kills = kills + GetHeroKills(id)
		deaths = deaths + GetHeroDeaths(id)
		local name = string.gsub(GetSelectedHeroName(id) or '', 'npc_dota_hero_', '')
		table.insert(heroes, name)
	end
	local standing = 0
	for _, id in ipairs(towers) do
		local tower = GetTower(team, id)
		if tower ~= nil and tower:IsAlive() then standing = standing + 1 end
	end
	return kills, deaths, standing, AncientHealth(team), table.concat(heroes, ',')
end

local function Report(event)
	local rk, rd, rt, rhp, rh = TeamState(TEAM_RADIANT)
	local dk, dd, dt, dhp, dh = TeamState(TEAM_DIRE)
	print(string.format(
		'[BENCH] v=%d event=%s me=%d t=%d real=%.0f rk=%d rd=%d rt=%d rhp=%d dk=%d dd=%d dt=%d dhp=%d rh=%s dh=%s',
		VERSION, event, GetTeam(), DotaTime(), RealTime(), rk, rd, rt, rhp, dk, dd, dt, dhp, rh, dh))
end

-- Called every frame from BuybackUsageThink, which every bot runs, alive or dead.
function X.Tick(bot)
	if Customize.Bench == false or reportedEnd or RealTime() < nextCheck then return end
	nextCheck = RealTime() + CHECK_EVERY
	local state = GetGameState()
	if state ~= GAME_STATE_GAME_IN_PROGRESS and state ~= GAME_STATE_POST_GAME then return end
	if not IsReporter(bot) then return end
	if state == GAME_STATE_POST_GAME then
		reportedEnd = true
		Report('end')
		return
	end
	local now = DotaTime()
	if nextReport == nil then
		nextReport = now + 30
		Report('start')
		return
	end
	if now >= nextReport or AncientHealth(TEAM_RADIANT) < 1500 or AncientHealth(TEAM_DIRE) < 1500 then
		nextReport = now + 30
		Report('tick')
	end
end

return X
