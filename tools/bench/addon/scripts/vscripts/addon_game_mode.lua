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

-- Gold and XP each player earned by reason, after the x2 (observer mode prints it every 30 s): the gap against OHA by
-- source, instead of a regression over net worth (trabajo/fase1-plan.md). pid -> { gold = { reason -> n }, xp = {...} }.
-- Not the total: the passive gold does not show up in this filter (nor gets the x2; MEDICIONES fase1f-reg).
local earned = {}
local function NoteEarned(kind, pid, reason, amount)
	if pid == nil or pid < 0 or amount == nil or amount <= 0 then return end
	earned[pid] = earned[pid] or { gold = {}, xp = {} }
	local into = earned[pid][kind]
	into[reason] = (into[reason] or 0) + amount
end

-- A note taken inside a filter or an event must never change what the game does, nor fail in silence: a renamed field
-- would read as "Shrapnel does not hit". One line per name, the analyzers count them.
local noteFailed = {}
local function Note(name, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok and not noteFailed[name] then
		noteFailed[name] = true
		print("[dotabench] obs error " .. name .. " " .. tostring(err))
	end
end

local function ApplyTurbo()
	local mode = GameRules:GetGameModeEntity()
	mode:SetUseTurboCouriers(true)
	-- Secret shop items at any shop. OHA's Turbo purchase path never goes to the secret shop: refused (code 62, stock 0 for every item), it
	-- drops the part in silence, and its teams left a median 37 % of their net worth unspent at minute 25 (MEDICIONES 2026-11-06).
	GameRules:SetUseUniversalShopMode(true)
	mode:SetRespawnTimeScale(TURBO.respawn)
	mode:SetModifyGoldFilter(function(_, event)
		if event.gold > 0 and INCOME[event.reason_const] then event.gold = math.floor(event.gold * TURBO.gold) end
		Note("ingresos_oro", NoteEarned, "gold", event.player_id_const, event.reason_const, event.gold)
		return true
	end, {})
	mode:SetModifyExperienceFilter(function(_, event)
		event.experience = math.floor(event.experience * TURBO.xp)
		Note("ingresos_xp", NoteEarned, "xp", event.player_id_const, event.reason_const, event.experience)
		return true
	end, {})
	local n = 0
	for _ in pairs(INCOME) do n = n + 1 end
	print(string.format("[dotabench] turbo on tienda=universal gold=%s xp=%s respawn=%s couriers=turbo income_reasons=%d", TURBO.gold,
		TURBO.xp, TURBO.respawn, n))
end

local botsAdded = {}

-- Each team asks for its own drawn heroes, none shared (heroes, heroes_dire): the engine gives them if both teams
-- join in the same instant. Without heroes_dire ("--espejo no", debugging) Dire asks for Radiant's and gets random
-- ones instead. Measured 2026-10-31: a team added a second later got no heroes at all.
local function AddBots(cfg, team)
	if botsAdded[team] then return end
	botsAdded[team] = true
	local list = (team == DOTA_TEAM_BADGUYS and cfg.heroes_dire) or cfg.heroes
	for slot, hero in ipairs(list) do
		local ok = Tutorial:AddBot(hero, LANES[team][slot], cfg.difficulty, team == DOTA_TEAM_GOODGUYS)
		print(string.format("[dotabench] AddBot team=%d slot=%d %s -> %s", team, slot, hero, tostring(ok)))
	end
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

-- No hero is ever swapped or created (DECISIONES 2026-10-31). Tried and dropped that day: swapping Dire's random
-- heroes with ReplaceHeroWith (Dota closed itself in 5 of 16 matches, with or without removing the old hero) and
-- creating them with CreateHeroForPlayer (Dota closed too, and the engine did not count them as the players' heroes).
-- The engine never gives one hero to both teams (0 of 112 matches), so each team asks for its own draw.

-- First spawn of each hero entity, with the game time (negative before the horn): one hero per side used to spawn
-- late, Radiant's slot 1 most of all (open defect, ESTADO.md), and the orchestrator checks it.
-- Keyed by the unit handle, not the entity index: a removed hero (the human's) frees its index for a later hero.
local spawned = {}
local function OnNpcSpawned(event)
	local unit = EntIndexToHScript(event.entindex)
	if not unit or not unit.IsRealHero or not unit:IsRealHero() then return end
	local pid = unit:GetPlayerOwnerID()
	if not spawned[unit] then
		spawned[unit] = true
		print(string.format("[dotabench] spawn pid=%d team=%d hero=%s t=%.1f", pid or -1, unit:GetTeamNumber(),
			unit:GetUnitName(), GameRules:GetDOTATime(false, true)))
	end
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

-- Once every bot has its hero (at most 60 s after the horn): the hero each player really controls (its entity, not
-- the selection) and its net worth, so the orchestrator can check each team plays its draw and both start alike.
local function PrintStart()
	local waited = 0
	GameRules:GetGameModeEntity():SetThink(function()
		local players, ready = {}, true
		for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
			for i = 1, PlayerResource:GetPlayerCountForTeam(team) do
				local pid = PlayerResource:GetNthPlayerIDOnTeam(team, i)
				if pid >= 0 and not IsHuman(pid) then
					local hero = PlayerResource:GetSelectedHeroEntity(pid)
					if hero == nil then ready = false end
					table.insert(players, { team = team, pid = pid, hero = hero })
				end
			end
		end
		if not ready and waited < 60 then
			waited = waited + 1
			return 1
		end
		for _, p in ipairs(players) do
			print(string.format("[dotabench] start team=%d pid=%d hero=%s nw=%d waited=%d", p.team, p.pid,
				p.hero and p.hero:GetUnitName() or "none", PlayerResource:GetNetWorth(p.pid), waited))
		end
		return nil
	end, "dotabench_start", 0)
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
		-- Both teams in the same instant, each with its own draw (AddBots).
		AddBots(cfg, DOTA_TEAM_GOODGUYS)
		AddBots(cfg, DOTA_TEAM_BADGUYS)
	elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
		AddBots(cfg, DOTA_TEAM_GOODGUYS)
		AddBots(cfg, DOTA_TEAM_BADGUYS)
		PrintRoster()
		PrintVariant()
		SendToServerConsole("sv_cheats 1")
		SendToServerConsole("host_timescale " .. tostring(cfg.timescale or 1))
	elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		PrintStart()
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
	-- Per team, alive, for the orchestrator's validity: nobody had couriers before 2026-10-29.
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		local alive = {}
		for _, courier in ipairs(Entities:FindAllByClassname("npc_dota_courier")) do
			if courier:GetTeamNumber() == team and courier:IsAlive() then
				table.insert(alive, tostring(math.floor(courier:GetIdealSpeed())))
			end
		end
		print(string.format("[dotabench] couriers team=%d n=%d speeds=%s", team, #alive, table.concat(alive, "/")))
	end
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

-- The lane the variant follows (linea_heroe, e.g. the Sniper) and its rival, the other team's position 2 in the draw.
-- Same lines in both arms; a match with no such variant logs none of them.
local lane = nil
local function LanePlayers()
	if lane ~= nil then return lane end
	local ok, variant = pcall(require, "bots.Customize.bench_variant")
	local hero = ok and type(variant) == "table" and variant.linea_heroe or nil
	-- --rival dotabot: the variant is per team, and the followed hero comes from whichever team has one.
	if hero == nil and ok and type(variant) == "table" and type(variant.teams) == "table" then
		for _, t in pairs(variant.teams) do hero = hero or t.linea_heroe end
	end
	if type(hero) ~= "string" then
		lane = { own = -1, rival = -1 }
		return lane
	end
	local own, rival = -1, -1
	for pid = 0, 23 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:GetSelectedHeroName(pid) == "npc_dota_hero_" .. hero then
			own = pid
		end
	end
	if own < 0 then return { own = -1, rival = -1 } end -- not picked yet: asked again later
	local cfg = MatchConfig()
	local other = PlayerResource:GetTeam(own) == DOTA_TEAM_GOODGUYS and cfg.heroes_dire or cfg.heroes
	for pid = 0, 23 do
		if other and PlayerResource:IsValidPlayerID(pid) and PlayerResource:GetSelectedHeroName(pid) == other[2] then
			rival = pid
		end
	end
	local found = { own = own, rival = rival }
	if rival >= 0 then lane = found end
	return found
end

-- A call that may not exist in this engine's API answers -1 instead of losing the whole line.
local function Try(unit, method, ...)
	local fn = unit[method]
	if fn == nil then return -1 end
	local ok, value = pcall(fn, unit, ...)
	if ok and type(value) == "number" then return value end
	return -1
end

-- Every 5 s, for the followed hero and its rival: what the 30 s snapshot lacks to read a trade.
local function LaneSnapshot()
	local l = LanePlayers()
	for _, pid in ipairs({ l.own, l.rival }) do
		local hero = pid >= 0 and PlayerResource:GetSelectedHeroEntity(pid) or nil
		if hero then
			local pos = hero:GetAbsOrigin()
			Obs("linea pid=%d %s alive=%d x=%d y=%d hp=%d maxhp=%d mp=%d xp=%d dmg=%d aps=%.2f rango=%d", pid, HeroOf(pid),
				hero:IsAlive() and 1 or 0, pos.x, pos.y, hero:GetHealth(), hero:GetMaxHealth(), hero:GetMana(),
				Try(hero, "GetCurrentXP"), Try(hero, "GetAverageTrueAttackDamage", hero), Try(hero, "GetAttacksPerSecond", false),
				Try(hero, "Script_GetAttackRange"))
		end
	end
end

-- Gold and XP by reason, accumulated (see ApplyTurbo), every 30 s for the followed hero and its rival.
local function ReasonName(prefix, code)
	for name, value in pairs(_G) do
		if value == code and type(name) == "string" and string.sub(name, 1, #prefix) == prefix then
			return string.sub(name, #prefix + 1)
		end
	end
	return "r" .. tostring(code)
end
local function Reasons(prefix, map)
	local parts = {}
	for code, n in pairs(map) do table.insert(parts, ReasonName(prefix, code) .. ":" .. n) end
	table.sort(parts)
	return table.concat(parts, ",")
end
local function EarnedSnapshot()
	local l = LanePlayers()
	for _, pid in ipairs({ l.own, l.rival }) do
		if pid >= 0 and earned[pid] then
			Obs("ingresos pid=%d %s oro=%s xp=%s", pid, HeroOf(pid), Reasons("DOTA_ModifyGold_", earned[pid].gold),
				Reasons("DOTA_ModifyXP_", earned[pid].xp))
		end
	end
end

-- Damage to and from the followed hero, by source (attack or ability), printed and reset every 10 s: says whether
-- Shrapnel hits and who hurts the hero. As the filter receives it; whether armour is already applied is not checked.
local damage = {}
local function NoteDamage(e)
	local l = LanePlayers()
	if l.own < 0 then return end
	local attacker = e.entindex_attacker_const and EntIndexToHScript(e.entindex_attacker_const)
	local victim = e.entindex_victim_const and EntIndexToHScript(e.entindex_victim_const)
	if not attacker or not victim or not victim.IsRealHero or not attacker.GetUnitName then return end
	local hero = PlayerResource:GetSelectedHeroEntity(l.own)
	if not hero or (attacker ~= hero and victim ~= hero) then return end
	if not victim:IsRealHero() then return end -- creeps and towers hit by the hero: creepkill tells those
	-- IsHero, not IsRealHero: an illusion is its hero's name, not a creep. A count with a total of 0 is a blocked hit.
	local from = attacker:IsHero() and attacker:GetUnitName():gsub("npc_dota_hero_", "")
		or (attacker:IsTower() and "torre") or "creep"
	local inflictor = e.entindex_inflictor_const and EntIndexToHScript(e.entindex_inflictor_const)
	local source = inflictor and inflictor.GetAbilityName and inflictor:GetAbilityName() or "ataque"
	local key = from .. ">" .. victim:GetUnitName():gsub("npc_dota_hero_", "") .. ":" .. source
	local d = damage[key] or { total = 0, n = 0 }
	d.total, d.n = d.total + e.damage, d.n + 1
	damage[key] = d
end
local function DamageSnapshot()
	local parts = {}
	for key, d in pairs(damage) do table.insert(parts, string.format("%s:%d:%d", key, math.floor(d.total), d.n)) end
	if #parts == 0 then return end
	table.sort(parts)
	Obs("dano %s", table.concat(parts, ","))
	damage = {}
end

-- A creep killed within 1000 of the followed hero: by whom and with what (attack or Shrapnel), and the denominator
-- of its last hits, which no line gave before.
local function NoteCreepKill(e, unit, victim, vteam)
	local l = LanePlayers()
	local hero = l.own >= 0 and PlayerResource:GetSelectedHeroEntity(l.own) or nil
	if not hero or not unit.IsCreep or not unit:IsCreep() or unit:IsHero() then return end
	local pos, from = unit:GetAbsOrigin(), hero:GetAbsOrigin()
	local dist = (pos - from):Length2D()
	if dist >= 1000 then return end
	local killer, kteam, kpid = UnitName(e.entindex_attacker)
	local inflictor = e.entindex_inflictor and EntIndexToHScript(e.entindex_inflictor)
	Obs("creepkill victim=%s vteam=%d killer=%s kteam=%d kpid=%d inflictor=%s x=%d y=%d d=%d heroe_vivo=%d", victim, vteam,
		killer, kteam, kpid, inflictor and inflictor.GetAbilityName and inflictor:GetAbilityName() or "ataque", pos.x, pos.y,
		dist, hero:IsAlive() and 1 or 0)
end

local function Listen(event, handler)
	ListenToGameEvent(event, function(e)
		local ok, err = pcall(handler, e)
		if not ok then print("[dotabench] obs error " .. event .. " " .. tostring(err)) end
	end, nil)
end

local function StartObserver()
	print("[dotabench] observer on")
	-- Reads only: always lets the damage through as it came, also if the note fails.
	GameRules:GetGameModeEntity():SetDamageFilter(function(_, e)
		Note("dano", NoteDamage, e)
		return true
	end, {})
	Listen("dota_item_purchased", function(e)
		Obs("buy pid=%s %s %s cost=%s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.itemname), tostring(e.itemcost))
	end)
	Listen("dota_player_learned_ability", function(e)
		Obs("learn pid=%s %s %s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.abilityname))
	end)
	Listen("dota_player_used_ability", function(e)
		Obs("cast pid=%s %s %s", tostring(e.PlayerID), HeroOf(e.PlayerID), tostring(e.abilityname))
		-- Ultimates (Pedro, 2026-10-31: ultimates thrown at creeps or at nothing in the own base): where the caster is
		-- and which enemy heroes were near, to tell wasted ones from global ones (e.g. Zeus) that are fine from base.
		local hero = e.PlayerID ~= nil and e.PlayerID >= 0 and PlayerResource:GetSelectedHeroEntity(e.PlayerID) or nil
		local ability = hero and e.abilityname and hero:FindAbilityByName(e.abilityname) or nil
		if ability and ability:GetAbilityType() == ABILITY_TYPE_ULTIMATE then
			local pos = hero:GetAbsOrigin()
			local enemies = FindUnitsInRadius(hero:GetTeamNumber(), pos, nil, 2500, DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			local near = 0
			for _, en in ipairs(enemies) do if en:IsRealHero() and (en:GetAbsOrigin() - pos):Length2D() <= 1200 then near = near + 1 end end
			local nearest = enemies[1] and math.floor((enemies[1]:GetAbsOrigin() - pos):Length2D()) or -1
			Obs("ult pid=%d team=%d %s %s x=%d y=%d enemies1200=%d nearest=%d", e.PlayerID, hero:GetTeamNumber(),
				HeroOf(e.PlayerID), e.abilityname, pos.x, pos.y, near, nearest)
		end
	end)
	Listen("entity_killed", function(e)
		local victim, vteam, vpid = UnitName(e.entindex_killed)
		local unit = EntIndexToHScript(e.entindex_killed)
		if unit then Note("creepkill", NoteCreepKill, e, unit, victim, vteam) end
		local important = unit and (unit:IsRealHero() or unit:IsTower() or unit:IsBuilding() or unit:IsCourier()
			or victim == "npc_dota_roshan")
		if not important then return end
		local killer, kteam, kpid = UnitName(e.entindex_attacker)
		-- For towers (Pedro, 2026-10-31: towers left undefended while each hero goes its own way): how many heroes of
		-- each team were near when it fell.
		local around = ""
		if unit:IsTower() then
			local pos, own, foe = unit:GetAbsOrigin(), 0, 0
			for _, h in ipairs(HeroList:GetAllHeroes()) do
				if h:IsRealHero() and h:IsAlive() and (h:GetAbsOrigin() - pos):Length2D() <= 1500 then
					if h:GetTeamNumber() == vteam then own = own + 1 else foe = foe + 1 end
				end
			end
			around = string.format(" defenders1500=%d attackers1500=%d", own, foe)
		end
		Obs("kill victim=%s vteam=%d vpid=%d killer=%s kteam=%d kpid=%d%s", victim, vteam, vpid, killer, kteam, kpid, around)
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
	local nextSnapshot, nextLane, nextDamage = 0, 0, 0
	local function Safely(name, fn)
		local ok, err = pcall(fn)
		if not ok then print("[dotabench] obs error " .. name .. " " .. tostring(err)) end
	end
	GameRules:GetGameModeEntity():SetThink(function()
		local state = GameRules:State_Get()
		-- pcall: a failing snapshot must not stop this timer for the rest of the match.
		if state >= DOTA_GAMERULES_STATE_POST_GAME then
			pcall(Snapshot)
			return nil
		end
		local now = GameRules:GetDOTATime(false, true)
		if state >= DOTA_GAMERULES_STATE_PRE_GAME and now >= nextSnapshot then
			nextSnapshot = nextSnapshot + 30
			Safely("snapshot", Snapshot)
			Safely("ingresos", EarnedSnapshot)
		end
		if state >= DOTA_GAMERULES_STATE_PRE_GAME and now >= nextLane then
			nextLane = now + 5
			Safely("linea", LaneSnapshot)
		end
		if state >= DOTA_GAMERULES_STATE_PRE_GAME and now >= nextDamage then
			nextDamage = now + 10
			Safely("dano", DamageSnapshot)
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
	GameRules:SetHeroSelectionTime(5) -- 30 s did not give the second team its heroes either (2026-10-31)
	GameRules:SetStrategyTime(0)
	GameRules:SetShowcaseTime(0)
	-- 90 s, as in normal Dota (it was 30): the first bot added spawns 15-50 s after the rest, and with 30 s it often
	-- missed the horn and its lane time (2026-10-31). No gold ticks before the horn, so it changes nothing else.
	GameRules:SetPreGameTime(90)
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
