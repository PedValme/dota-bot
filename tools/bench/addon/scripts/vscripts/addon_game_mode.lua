-- dota-bot benchmark custom game ("dotabench", local only, never published). Launched by tools/bench/orquestador.mjs
-- with "+dota_launch_custom_game dotabench dota". It does what console arguments cannot do after the map loads:
-- keeps the human out of both teams, adds ten bots asking for the same five heroes on each side (bench_partida.lua,
-- written by the orchestrator per match; only Radiant keeps them, Dire picks its own, seen 2026-10-30), speeds the
-- match up and logs a per-minute timeline of both teams. Who wins is read by the orchestrator through GSI.

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

-- Imitated Turbo (Pedro, 2026-10-29: the benchmark target is Turbo, and the real mode cannot run in a custom game).
-- Turbo couriers (1100 speed, which is also how dota-bot detects Turbo and switches to its Turbo logic), gold and
-- experience x2 and faster respawn. Towers, runes and other Turbo details stay as in normal mode.
local TURBO = { gold = 2, xp = 2, respawn = 0.75 }
-- Only income is doubled: death loss, buyback, purchases, sells and ability costs stay as they are.
local INCOME = {}
for _, name in ipairs({ "GameTick", "Building", "HeroKill", "CreepKill", "NeutralKill", "RoshanKill", "CourierKill",
	"BountyRune", "SharedGold", "AbilityGold", "WardKill" }) do
	local reason = _G["DOTA_ModifyGold_" .. name]
	if reason ~= nil then INCOME[reason] = true end
end

local function ApplyTurbo()
	local mode = GameRules:GetGameModeEntity()
	mode:SetUseTurboCouriers(true)
	mode:SetRespawnTimeScale(TURBO.respawn)
	mode:SetModifyGoldFilter(function(_, event)
		if event.gold > 0 and INCOME[event.reason_const] then event.gold = math.floor(event.gold * TURBO.gold) end
		return true
	end, {})
	mode:SetModifyExperienceFilter(function(_, event)
		event.experience = math.floor(event.experience * TURBO.xp)
		return true
	end, {})
	local n = 0
	for _ in pairs(INCOME) do n = n + 1 end
	print(string.format("[dotabench] turbo on gold=%s xp=%s respawn=%s couriers=turbo income_reasons=%d", TURBO.gold,
		TURBO.xp, TURBO.respawn, n))
end

local botsAdded = false

local function AddBots(cfg)
	if botsAdded then return end
	botsAdded = true
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		for slot, hero in ipairs(cfg.heroes) do
			local ok
			if team == DOTA_TEAM_BADGUYS and cfg.espejo == "entity" then
				-- Mirror test (2026-10-31): a bot added with its hero and team given directly.
				ok = pcall(function() GameRules:AddBotPlayerWithEntityScript(hero, "dire" .. slot, DOTA_TEAM_BADGUYS, "", false) end)
			else
				ok = Tutorial:AddBot(hero, LANES[team][slot], cfg.difficulty, team == DOTA_TEAM_GOODGUYS)
			end
			print(string.format("[dotabench] AddBot team=%d slot=%d %s -> %s", team, slot, hero, tostring(ok)))
		end
	end
	-- Only Radiant gets the asked heroes: hero selection, strategy and pre-game happen in the same second here, so no
	-- draft script runs and the engine gives Dire's bots random heroes. Tried and dropped on 2026-10-31: picking them
	-- in dota-bot's draft (it never runs), SetSelectedHero during selection and ReplaceHeroWith at pre-game (both "ok",
	-- no effect). A/B series stay fair because every variant plays both sides.
end

-- Humans never play: they watch as spectators (team 1), which gives the broadcast view with a choice of Radiant,
-- Dire or both teams' vision; out of every team they would only see the fog of war. The setup screen can still drop
-- the human into a free slot before the bots arrive, and then Dota gives them a random hero that nobody plays (seen
-- 2026-10-29), so it is checked again at every state change and any human hero is removed.
local SPECTATORS = 1 -- DOTA_TEAM_SPECTATOR
local function IsHuman(pid)
	return pid ~= nil and pid >= 0 and PlayerResource:IsValidPlayerID(pid) and not PlayerResource:IsFakeClient(pid)
end

local function KeepHumanOut(pid, why)
	local team = PlayerResource:GetTeam(pid)
	if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
		print(string.format("[dotabench] human player %d was on team %d (%s); moving out", pid, team, why))
	end
	-- Spectator only once the setup screen is over: assigning team 1 there keeps the custom game stuck in setup
	-- (seen 2026-10-29).
	local target = GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME and SPECTATORS or DOTA_TEAM_NOTEAM
	PlayerResource:SetCustomTeamAssignment(pid, target)
	local player = PlayerResource:GetPlayer(pid)
	-- pcall: a failure here must not skip the bots or the speed-up in OnStateChange.
	if player and team ~= target then pcall(player.SetTeam, player, target) end
end

local function KeepHumansOut(why)
	for pid = 0, 23 do
		if IsHuman(pid) then KeepHumanOut(pid, why) end
	end
end

-- Mirror test "replace" (2026-10-31): once a Dire bot's hero really exists, swap it for its slot's hero (at pre-game
-- ReplaceHeroWith said ok and changed nothing, maybe because the hero did not exist yet).
local mirrored = {}
local function MirrorOnSpawn(unit, pid)
	local cfg = MatchConfig()
	if cfg.espejo ~= "replace" or mirrored[pid] or unit:GetTeamNumber() ~= DOTA_TEAM_BADGUYS then return end
	for slot = 1, PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) do
		if PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, slot) == pid then
			local hero = cfg.heroes[slot]
			if hero == nil or unit:GetUnitName() == hero then return end
			mirrored[pid] = true
			GameRules:GetGameModeEntity():SetThink(function()
				local ok, err = pcall(function() PlayerResource:ReplaceHeroWith(pid, hero, PlayerResource:GetGold(pid), 0) end)
				print(string.format("[dotabench] mirror slot=%d pid=%d %s -> %s ok=%s %s now=%s", slot, pid, unit:GetUnitName(),
					hero, tostring(ok), tostring(err or ""), tostring(PlayerResource:GetSelectedHeroName(pid))))
				return nil
			end, "dotabench_mirror_" .. pid, 0.5)
			return
		end
	end
end

local function OnNpcSpawned(event)
	local unit = EntIndexToHScript(event.entindex)
	if not unit or not unit.IsRealHero or not unit:IsRealHero() then return end
	local pid = unit:GetPlayerOwnerID()
	if pid ~= nil and pid >= 0 and PlayerResource:IsFakeClient(pid) then MirrorOnSpawn(unit, pid) end
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
	for pid = 0, 23 do
		if IsHuman(pid) then print(string.format("[dotabench] human player %d watches from team %d", pid, PlayerResource:GetTeam(pid))) end
	end
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

-- Abilities and items cast per team since the start: the footprint of how they play in every match (a variant that
-- changes ThinkLess changes it). The bots' own print reaches the log only in observer mode (OHA silences it otherwise).
local casts = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
local function OnAbilityUsed(event)
	local pid = event.PlayerID
	if pid == nil or not PlayerResource:IsValidPlayerID(pid) then return end
	local team = PlayerResource:GetTeam(pid)
	if casts[team] then casts[team] = casts[team] + 1 end
end

local function PrintTimeline(event)
	local r, d = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS
	print(string.format(
		"[dotabench] timeline event=%s min=%d rk=%d dk=%d rt=%d dt=%d rb=%d db=%d rhp=%d dhp=%d rnw=%d dnw=%d rc=%d dc=%d",
		event, math.floor(GameRules:GetDOTATime(false, false) / 60),
		PlayerResource:GetTeamKills(r), PlayerResource:GetTeamKills(d),
		CountStanding("npc_dota_tower", r), CountStanding("npc_dota_tower", d),
		CountStanding("npc_dota_barracks", r), CountStanding("npc_dota_barracks", d),
		AncientHealth(r), AncientHealth(d), NetWorth(r), NetWorth(d), casts[r], casts[d]))
end

-- Courier speeds at minute 1: Turbo couriers run at 1100, which is how dota-bot detects Turbo
-- (FunLib/jmz_func.lua J.IsModeTurbo), so this shows whether its Turbo logic is on.
local function PrintMode()
	local speeds = {}
	local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_COURIER, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER, false)
	for _, courier in ipairs(units) do
		table.insert(speeds, tostring(math.floor(courier:GetIdealSpeed())))
	end
	print("[dotabench] mode couriers=" .. #speeds .. " speeds=" .. table.concat(speeds, "/")
		.. " by_class=" .. #Entities:FindAllByClassname("npc_dota_courier"))
end

local lastMinute = -1
local function TimelineThink()
	local state = GameRules:State_Get()
	if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local minute = math.floor(GameRules:GetDOTATime(false, false) / 60)
		if minute > lastMinute then
			lastMinute = minute
			PrintTimeline("minute")
			if minute == 1 then PrintMode() end
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

-- Observer mode (bench_partida.lua: observar = true; orchestrator --observar), to map how the bots really play. The
-- server sees what the bots' VM cannot log: per hero every 30 game seconds (level, gold, last hits, K/D/A, position,
-- items) and every purchase, skill point, cast, kill, rune, buyback, glyph and ward. Lines start with
-- "[dotabench] obs" and the orchestrator copies them to bench/observaciones/. Off by default: plain matches log as before.
local function Obs(fmt, ...)
	print("[dotabench] obs t=" .. math.floor(GameRules:GetDOTATime(false, true)) .. " " .. string.format(fmt, ...))
end

local function HeroOf(pid)
	if pid == nil or pid < 0 or not PlayerResource:IsValidPlayerID(pid) then return "?" end
	return (PlayerResource:GetSelectedHeroName(pid) or "?"):gsub("npc_dota_hero_", "")
end

local function UnitName(index)
	local unit = index and EntIndexToHScript(index)
	if not unit then return "?", -1, -1 end
	local pid = unit.GetPlayerOwnerID and unit:GetPlayerOwnerID() or -1
	return unit:GetUnitName():gsub("npc_dota_hero_", ""), unit:GetTeamNumber(), pid
end

local function Items(hero)
	local names = {}
	for slot = 0, 16 do
		local item = hero:GetItemInSlot(slot)
		if item then table.insert(names, slot .. ":" .. item:GetAbilityName():gsub("^item_", "")) end
	end
	return table.concat(names, "|")
end

local function Snapshot()
	for pid = 0, 23 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:IsFakeClient(pid) then
			local hero = PlayerResource:GetSelectedHeroEntity(pid)
			if hero then
				local pos = hero:GetAbsOrigin()
				Obs("hero pid=%d team=%d %s lvl=%d gold=%d nw=%d lh=%d dn=%d k=%d d=%d a=%d alive=%d x=%d y=%d hp=%d mp=%d items=%s",
					pid, hero:GetTeamNumber(), HeroOf(pid), hero:GetLevel(), PlayerResource:GetGold(pid),
					PlayerResource:GetNetWorth(pid), PlayerResource:GetLastHits(pid), PlayerResource:GetDenies(pid),
					PlayerResource:GetKills(pid), PlayerResource:GetDeaths(pid), PlayerResource:GetAssists(pid),
					hero:IsAlive() and 1 or 0, pos.x, pos.y, hero:GetHealth(), hero:GetMana(), Items(hero))
			end
		end
	end
	-- Couriers: dota-bot's Turbo logic needs a living allied one at 1100, and it looks couriers up by team index.
	for _, courier in ipairs(Entities:FindAllByClassname("npc_dota_courier")) do
		local pos = courier:GetAbsOrigin()
		Obs("courier team=%d pid=%d speed=%d alive=%d x=%d y=%d items=%s", courier:GetTeamNumber(),
			courier:GetPlayerOwnerID(), math.floor(courier:GetIdealSpeed()), courier:IsAlive() and 1 or 0, pos.x, pos.y,
			Items(courier))
	end
end

local function Listen(event, handler)
	ListenToGameEvent(event, function(e)
		local ok, err = pcall(handler, e)
		if not ok then print("[dotabench] obs error " .. event .. " " .. tostring(err)) end
	end, nil)
end

local function StartObserver()
	print("[dotabench] observer on")
	Listen("dota_item_purchased", function(e)
		Obs("buy pid=%s %s %s cost=%s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.itemname), tostring(e.itemcost))
	end)
	Listen("dota_player_learned_ability", function(e)
		Obs("learn pid=%s %s %s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.abilityname))
	end)
	Listen("dota_player_used_ability", function(e)
		Obs("cast pid=%s %s %s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.abilityname))
	end)
	Listen("entity_killed", function(e)
		local victim, vteam, vpid = UnitName(e.entindex_killed)
		local unit = EntIndexToHScript(e.entindex_killed)
		local important = unit and (unit:IsRealHero() or unit:IsTower() or unit:IsBuilding() or unit:IsCourier()
			or victim == "npc_dota_roshan")
		if not important then return end
		local killer, kteam, kpid = UnitName(e.entindex_attacker)
		Obs("kill victim=%s vteam=%d vpid=%d killer=%s kteam=%d kpid=%d", victim, vteam, vpid, killer, kteam, kpid)
	end)
	Listen("dota_rune_activated_server", function(e)
		Obs("rune pid=%s %s rune=%s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.rune))
	end)
	Listen("dota_buyback", function(e)
		Obs("buyback pid=%s %s", tostring(e.player_id), HeroOf(e.player_id))
	end)
	Listen("dota_glyph_used", function(e)
		Obs("glyph team=%s", tostring(e.teamnumber))
	end)
	Listen("npc_spawned", function(e)
		local unit = EntIndexToHScript(e.entindex)
		if not unit then return end
		local name = unit:GetUnitName()
		if name == "npc_dota_observer_wards" or name == "npc_dota_sentry_wards" then
			-- At spawn the ward is still at 0,0: read its position a moment later.
			GameRules:GetGameModeEntity():SetThink(function()
				if IsValidEntity(unit) then
					local pos = unit:GetAbsOrigin()
					Obs("ward %s team=%d x=%d y=%d", name:gsub("npc_dota_", ""), unit:GetTeamNumber(), pos.x, pos.y)
				end
				return nil
			end, "dotabench_ward_" .. tostring(e.entindex), 0.1)
		end
	end)
	local nextSnapshot = 0
	GameRules:GetGameModeEntity():SetThink(function()
		local state = GameRules:State_Get()
		-- pcall: a failing snapshot must not stop this timer for the rest of the match.
		if state >= DOTA_GAMERULES_STATE_POST_GAME then
			pcall(Snapshot)
			return nil
		end
		if state >= DOTA_GAMERULES_STATE_PRE_GAME and GameRules:GetDOTATime(false, true) >= nextSnapshot then
			nextSnapshot = nextSnapshot + 30
			local ok, err = pcall(Snapshot)
			if not ok then print("[dotabench] obs error snapshot " .. tostring(err)) end
		end
		return 1
	end, "dotabench_observer", 1)
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
	-- One courier per player, as in normal Dota; custom games give none unless this is on.
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
	if MatchConfig().turbo then ApplyTurbo() else print("[dotabench] turbo off") end
	if MatchConfig().observar then StartObserver() end
	ListenToGameEvent("game_rules_state_change", OnStateChange, nil)
	ListenToGameEvent("player_connect_full", OnPlayerConnect, nil)
	ListenToGameEvent("npc_spawned", OnNpcSpawned, nil)
	ListenToGameEvent("dota_player_used_ability", OnAbilityUsed, nil)
	GameRules:GetGameModeEntity():SetThink(function() return TimelineThink() end, "dotabench_timeline", 1)
end
