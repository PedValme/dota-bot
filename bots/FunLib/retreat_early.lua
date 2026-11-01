-- Early retreat (benchmark variant retirada_temprana; off by default). Pedro, 2026-11-01: two thirds of dota-bot's
-- deaths happen while retreating, 70 % within 4 s of starting to: it runs too late (OHA's main fight rule waits for
-- 30 % health with two enemies near). Measured with the observer (series humo-ret, 14 deaths): every death had the
-- threat (the damage visible enemy heroes within 1200 can deal in 5 s, OHA's estimate, over the health left) at 1 or
-- more 1 to 10 s before (half of them 7 s or more), and 6 of those heroes were still attacking. A threat of 1+ outside
-- a retreat is often survived (the bot wins the fight), so the rule also asks for a fight that is not won:
--   threat >= THREAT and (enemies near >= allies near, or health below LOW_HP) -> retreat desire DESIRE.
-- It only raises OHA's retreat desire (mode_retreat_generic.lua keeps the higher), and is not asked when OHA rules
-- retreat out (invulnerable or shielded states, evasive maneuvers).
local R = {}
local variant = dofile(GetScriptDirectory()..'/FunLib/bench_variant')

local THREAT = 1.5
local LOW_HP = 0.5
local RADIUS = 1200
local DESIRE = 0.9

local J

function R.Enabled()
	return variant.retirada_temprana == true
end

function R.Desire(bot)
	if not R.Enabled() or not bot:IsAlive() then return 0 end
	J = J or require(GetScriptDirectory()..'/FunLib/jmz_func')
	local here = bot:GetLocation()
	local enemies = J.GetEnemiesNearLoc(here, RADIUS)
	if #enemies == 0 then return 0 end
	local threat = J.GetTotalEstimatedDamageToTarget(enemies, bot) / math.max(bot:GetHealth(), 1)
	if threat < THREAT then return 0 end
	local allies = J.GetAlliesNearLoc(here, RADIUS) -- includes the bot itself
	if #enemies >= #allies or J.GetHP(bot) < LOW_HP then return DESIRE end
	return 0
end

return R
