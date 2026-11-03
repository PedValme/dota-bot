-- Early retreat (benchmark variant retirada_temprana; off by default). Pedro, 2026-11-01: two thirds of dota-bot's
-- deaths happen while retreating, 70 % within 4 s of starting to: it runs too late (OHA's main fight rule waits for
-- 30 % health with two enemies near). Measured with the observer (series humo-ret, 14 deaths): every death had the
-- threat (the damage visible enemy heroes within 1200 can deal in 5 s, OHA's estimate, over the health left) at 1 or
-- more 1 to 10 s before (half of them 7 s or more), and 6 of those heroes were still attacking. The threat sums every
-- enemy as if all hit this hero, so in an even fight it is high for everyone; it must not pull heroes out of fights
-- they are winning (review 2026-11-01). The rule:
--   threat >= THREAT and (more enemies than allies near, or health below LOW_HP while taking hero damage now with no
--   more allies than enemies) -> retreat desire DESIRE, held HOLD_SECONDS while the threat stays >= KEEP_THREAT
--   (enemies spending their spells drop the estimate mid-escape, and the hero must not turn back into them).
-- Version 2 (smoke humo-rt, 2026-11-01): with 1.5, more enemies than allies and 50 %, the retreat started no earlier
-- than without the variant (median 4 s after the threat passed 1, both) and 9 heroes died without retreating: the
-- threshold came late and team fights are rarely outnumbered. Now 1.0, 60 % and "taking hero damage now".
-- It only raises OHA's retreat desire (mode_retreat_generic.lua keeps the higher), is asked only past OHA's deliberate
-- "stay" cases, and never for Huskar, whose low health is his strength.
local R = {}
local variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')
local observe = dofile(GetScriptDirectory()..'/FunLib/bench_observe')

local THREAT = 1.0
local KEEP_THREAT = 0.7
local LOW_HP = 0.6
local RADIUS = 1200
-- 0.9 on purpose: OHA's attack mode at 0.95 (a target about to fall) still wins, and in the smoke 20 of the 21 heroes
-- it kept in survived (review 2026-11-01). It works as the "this fight is won" filter.
local DESIRE = 0.9
local HOLD_SECONDS = 2.5

local J

function R.Enabled()
	return variant.retirada_temprana == true
end

function R.Desire(bot)
	if not R.Enabled() or not bot:IsAlive() or bot:GetUnitName() == "npc_dota_hero_huskar" then return 0 end
	J = J or require(GetScriptDirectory()..'/FunLib/jmz_func')
	-- Brain v3: no early retreat in the laning phase, OHA's own retreat only. In lane a lone hero nearly always has two
	-- enemies near, and the v3 retreat at 0.97 fired ~46 times per game before minute 10 and cut every trade (n3-v3-a,
	-- DECISIONES 2026-11-02).
	local TBl = J.TeamBrain()
	if TBl.Enabled() and TBl.V3() and TBl.TeamLaning() then
		bot.__retreatEarlyUntil = nil
		return 0
	end
	local here = bot:GetLocation()
	local enemies = J.GetEnemiesNearLoc(here, RADIUS)
	if #enemies == 0 then
		bot.__retreatEarlyUntil = nil
		return 0
	end
	local threat = J.GetTotalEstimatedDamageToTarget(enemies, bot) / math.max(bot:GetHealth(), 1)
	local now = DotaTime()
	-- Held while the threat stays: renewed, not a fixed time (review 2026-11-01: a Razor let go at threat 0.82 turned
	-- back and died).
	-- v3: a fight that turned ours (the verdict) ends the hold.
	local TBh = J.TeamBrain()
	local heldOurs = TBh.Enabled() and TBh.V3() and not TBh.Shadow() and TBh.FightVerdict(bot) == true
	if heldOurs then bot.__retreatEarlyUntil = nil end
	if bot.__retreatEarlyUntil and now < bot.__retreatEarlyUntil and threat >= KEEP_THREAT then
		bot.__retreatEarlyUntil = now + HOLD_SECONDS
		return bot.__retreatEarlyDesire or DESIRE
	end
	if threat < THREAT then return 0 end
	-- Brain v3, layer 2: the fight's evaluation is the filter instead of the 0.9 below the attack mode. A fight that
	-- does not hold (value under 0.8) makes the hero run at 0.97, above OHA's attack (0.95); a fight held as ours keeps
	-- it in (OHA's own retreat rules still apply).
	local TB = J.TeamBrain()
	if TB.Enabled() and TB.V3() and not TB.Shadow() then
		local strong, value = TB.FightVerdict(bot)
		if strong == true then return 0 end
		if value ~= nil and value < 0.8 then
			bot.__retreatEarlyUntil = now + HOLD_SECONDS
			bot.__retreatEarlyDesire = 0.97
			if observe then
				print(string.format('[bench] retirada_temprana t=%d pid=%d amenaza=%.2f valor=%.2f hp=%.2f v3',
					math.floor(now), bot:GetPlayerID(), threat, value, J.GetHP(bot)))
			end
			return 0.97
		end
	end
	local allies = #J.GetAlliesNearLoc(here, RADIUS) -- includes the bot itself
	local hit = bot:WasRecentlyDamagedByAnyHero(1) == true
	if #enemies > allies or (J.GetHP(bot) < LOW_HP and hit and allies <= #enemies) then
		bot.__retreatEarlyUntil = now + HOLD_SECONDS
		if observe then
			print(string.format('[bench] retirada_temprana t=%d pid=%d amenaza=%.2f enemigos=%d aliados=%d hp=%.2f',
				math.floor(now), bot:GetPlayerID(), threat, #enemies, allies, J.GetHP(bot)))
		end
		bot.__retreatEarlyDesire = DESIRE
		return DESIRE
	end
	return 0
end

return R
