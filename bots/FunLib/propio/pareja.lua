-- dota-bot's own bot: the lane pair's shared board (trabajo/plan-mejora-equipo.md, package 2, «matar en pareja»). A hero that starts a
-- kill or casts a lock (stun, hex) on an enemy hero writes it here; its lane partner reads it and joins in the same second
-- (combate.lua, Join). OHA kills this way: Breathe Fire and Earth Spike in the same second, then Dragon Tail and Hex (fase2-ref-oha 2,
-- t=454 Spike, 457 Hex, 459 Finger -> kill), and Frost Blast within 3 s of a Lucent Beam 8-12 times a lane against our 1-2. Ours never
-- opened together: each hero decided alone, and a kill counted only the allies already hitting the target (`aliados=0` in 97-99 % of
-- kill_eval lines, fase2-humo-equipo 1 and 2).
-- The decisions are in combate.lua and linea.lua; this module only keeps the board and logs it ("[bench] prop pareja ..."). Our five
-- bots share the team's VM, so a module-level table is seen by all of them (linea.lua's S works the same way); it is keyed by team
-- anyway, in case a VM ever holds both.
local P = {}

local out = BenchRawPrint or print

local BOARD = {} -- team -> player id -> { id, pid, from, target, name, kind, why, at, untilT }
local seq = 0    -- announcement ids, so a partner decides on each one once

local function Short(u) return (string.gsub(u:GetUnitName(), 'npc_dota_hero_', '')) end
local function Seen(u) return u ~= nil and not u:IsNull() and u:IsAlive() and u:CanBeSeen() end

local function Board()
	local team = GetTeam()
	BOARD[team] = BOARD[team] or {}
	return BOARD[team]
end

function P.Log(bot, text)
	out(string.format('[bench] prop pareja t=%.1f pid=%d %s', DotaTime(), bot:GetPlayerID(), text))
end

-- Writes this bot's announcement (one per bot: a new one replaces the last). kind: 'kill' (a kill started), 'bloqueo' (a lock cast) or
-- 'apertura' (an opening spell with no lock, Lich's Frost Blast in a kill).
function P.Announce(bot, target, kind, untilT, now, why)
	if not Seen(target) or target:IsIllusion() then return end
	-- A lock cast inside our own kill keeps the kill's end: it replaces the announcement (a new id, so the partner answers this opening
	-- too) but must not cut the kill short for the partner.
	local old = Board()[bot:GetPlayerID()]
	if old ~= nil and old.name == Short(target) and old.untilT > untilT then untilT, kind = old.untilT, old.kind end
	seq = seq + 1
	Board()[bot:GetPlayerID()] = { id = seq, pid = bot:GetPlayerID(), from = bot, target = target, name = Short(target), kind = kind,
		why = why, at = now, untilT = untilT }
	P.Log(bot, string.format('anuncio id=%d tipo=%s objetivo=%s vida=%d hasta=+%.1fs motivo=%s', seq, kind, Short(target),
		target:GetHealth(), untilT - now, why))
end

-- Removes this bot's announcement of this kind (a kill that ended), with its reason.
function P.Clear(bot, kind, why)
	local b = Board()
	local a = b[bot:GetPlayerID()]
	if a ~= nil and (kind == nil or a.kind == kind) then
		b[bot:GetPlayerID()] = nil
		P.Log(bot, string.format('fin_anuncio id=%d objetivo=%s motivo=%s', a.id, a.name, why))
	end
end

-- Whether another bot's announcement still calls: running, and from an ally in `active` (player ids of the allies alive and not
-- retreating, from the caller's snapshot): a partner that retreated or died calls no one (review of package 2).
local function Live(bot, pid, a, now, active)
	return pid ~= bot:GetPlayerID() and a.untilT > now and (active == nil or active[pid] == true)
end

-- Which enemy each of our bots is chasing in a lane kill ('matar'), by its short name, or nil: a partner's C.Committed (combate.lua) asks
-- whether the ally near the target is really on it, not merely near it (review of round 2). Written at a chase's start and end.
local CHASE = {} -- team -> player id -> short name
function P.SetChase(bot, name)
	local team = GetTeam()
	CHASE[team] = CHASE[team] or {}
	CHASE[team][bot:GetPlayerID()] = name
end
function P.Chasing(pid)
	local t = CHASE[GetTeam()]
	return t ~= nil and t[pid] or nil
end

-- The other bots' live announcements, on visible enemy heroes.
function P.Calls(bot, now, active)
	local list = {}
	for pid, a in pairs(Board()) do
		if Live(bot, pid, a, now, active) and Seen(a.target) then table.insert(list, a) end
	end
	table.sort(list, function(x, y) return x.id < y.id end)
	return list
end

-- When the latest of the other bots' live announcements on this enemy (by name: the handles of one hero may differ between bots)
-- ends, or nil when none is live.
function P.Until(bot, name, now, active)
	local best = nil
	for pid, a in pairs(Board()) do
		if Live(bot, pid, a, now, active) and a.name == name and (best == nil or a.untilT > best) then best = a.untilT end
	end
	return best
end

return P
