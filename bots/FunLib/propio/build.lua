-- dota-bot's own bot: the build chosen against the enemies (trabajo/build-estrategica.md, firmado por Pedro el 2026-11-08: «ok
-- firmo el diseño, dale»). Generic for any hero with a profile in perfiles/: its core, then its points, each decided by rules in order
-- over the threats of the enemy team (amenazas.lua), with no weights. Every choice is logged with the reason and what it left.
-- Decided at the boundaries between whole items, never in the middle of one (compras.lua asks again when an item is done).
local B = {}

local Amenazas = require(GetScriptDirectory()..'/FunLib/propio/amenazas')
local PROFILES = { npc_dota_hero_sniper = require(GetScriptDirectory()..'/FunLib/propio/perfiles/sniper') }

-- The rules that use each kind of item (medio.lua and linea.lua). An active item with no rule here is never offered: it was bought and
-- never pressed (Satanic and Mjollnir before this module).
B.USES = { pasivo = true, berserk = true, pike = true, blade = true, bkb = true }

local out = BenchRawPrint or print
local function Log(bot, text)
	out(string.format('[bench] prop build t=%.1f pid=%d %s', DotaTime(), bot:GetPlayerID(), text))
end

-- The enemy team's threats: how many heroes carry each tag, from their picks and the items seen on them, and who.
function B.Threats(bot)
	local t = { evasion = 0, control = 0, magia = 0, salta = 0, invis = 0, ilusiones = 0, curacion = 0, who = {} }
	local seen = {}
	for _, id in ipairs(GetTeamPlayers(GetOpposingTeam()) or {}) do
		local name = (string.gsub(GetSelectedHeroName(id) or '', 'npc_dota_hero_', ''))
		if name ~= '' then
			local tags = {}
			for tag, on in pairs(Amenazas.HEROES[name] or {}) do if on then tags[tag] = true end end
			for tag in pairs((B.itemsSeen or {})[name] or {}) do tags[tag] = true end
			for tag in pairs(tags) do
				t[tag] = t[tag] + 1
				t.who[tag] = (t.who[tag] and t.who[tag] .. ',' or '') .. name
			end
			seen[name] = true
		end
	end
	return t
end

-- Items seen on visible enemies: a Butterfly or a Blink changes what they threaten. Returns a log line when something new is seen.
B.itemsSeen = {}
function B.Look(bot)
	local news = nil
	for _, e in ipairs(GetUnitList(UNIT_LIST_ENEMY_HEROES) or {}) do
		if e ~= nil and not e:IsNull() and e:IsAlive() and e:CanBeSeen() and not e:IsIllusion() then
			local name = (string.gsub(e:GetUnitName(), 'npc_dota_hero_', ''))
			for slot = 0, 5 do
				local ok, item = pcall(function() return e:GetItemInSlot(slot) end)
				local tag = ok and item ~= nil and Amenazas.ITEMS[item:GetName()] or nil
				if tag ~= nil then
					B.itemsSeen[name] = B.itemsSeen[name] or {}
					if not B.itemsSeen[name][tag] then
						B.itemsSeen[name][tag] = true
						news = string.format('amenaza %s en %s: %s', tag, name, item:GetName())
					end
				end
			end
		end
	end
	return news
end

-- The signature of the threats, to know when the plan must be asked again.
function B.Signature(t)
	return string.format('e%d c%d m%d s%d', t.evasion, t.control, t.magia, t.salta)
end

-- Pure: the ordered list of items for a profile against these threats, without the ones already done, and one reason per choice.
function B.Choose(profile, t, done)
	done = done or {}
	local list, reasons, have = {}, {}, {}
	local function add(item, why)
		if have[item] or done[item] then return end
		have[item] = true
		table.insert(list, item)
		if why then table.insert(reasons, why) end
	end
	for _, item in ipairs(profile.core) do add(item) end
	for _, point in ipairs(profile.points) do
		local chosen, left = nil, {}
		for _, c in ipairs(point) do
			if not B.USES[c.uso] then
				table.insert(left, c.item .. ' sin regla de uso')
			elseif chosen == nil and (c.when == nil or c.when(t)) and not have[c.item] and not done[c.item] then
				chosen = c
			else
				table.insert(left, c.item)
			end
		end
		if chosen ~= nil then
			local tag = chosen.when ~= nil and string.format(' (%s)', chosen.why) or ''
			add(chosen.item, #point > 1 and string.format('%s: %s%s, frente a %s', point.name, chosen.item, tag, table.concat(left, ' y ')) or nil)
		end
	end
	return list, reasons
end

function B.Profile(bot) return PROFILES[bot:GetUnitName()] end

-- The plan for this bot now, logged: the items still to buy, and why each point went the way it did.
function B.Plan(bot, s, done)
	local profile = B.Profile(bot)
	if profile == nil then return nil end
	local t = B.Threats(bot)
	local list, reasons = B.Choose(profile, t, done)
	s.buildSignature = B.Signature(t)
	local who = {}
	for _, tag in ipairs({ 'evasion', 'control', 'magia', 'salta' }) do
		if t[tag] > 0 then table.insert(who, string.format('%s=%d(%s)', tag, t[tag], t.who[tag])) end
	end
	Log(bot, string.format('plan %s · amenazas %s', table.concat(list, ','), #who > 0 and table.concat(who, ' ') or 'ninguna'))
	for _, r in ipairs(reasons) do Log(bot, 'elige ' .. r) end
	return list
end

return B
