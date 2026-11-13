-- dota-bot's own bot: Lion's build profile (trabajo/build-estrategica.md), position 4. A fixed core, then points where the enemies decide:
-- in each, the first candidate whose rule holds wins, the last one is the default. `uso` names the rule that uses the item (build.lua's
-- USES): an active item with none is never bought, so no Glimmer, Blink, Mekansm or Wand until they have a rule.
return {
	-- Core: stats, intelligence Treads for the mana, Force Staff (the 'pike' rule pushes it home when leaving) and Aether Lens, whose
	-- cast range keeps Hex and Finger out of the enemy's reach.
	core = { 'item_null_talisman', 'item_power_treads', 'item_force_staff', 'item_aether_lens' },
	points = {
		-- Against a team built on magic or lock, the Black King Bar before the Scepter: a hexed or stunned Lion locks no one.
		{ name = 'A',
			{ item = 'item_black_king_bar', uso = 'bkb', when = function(t) return t.magia >= 3 or t.control >= 4 end, why = 'mucha magia o control' },
			{ item = 'item_ultimate_scepter', uso = 'pasivo', why = 'finger en área' } },
		{ name = 'Scepter', { item = 'item_ultimate_scepter', uso = 'pasivo', why = 'finger en área' } },
		{ name = 'Octarine', { item = 'item_octarine_core', uso = 'pasivo', why = 'menos enfriamiento' } },
		{ name = 'BKB', { item = 'item_black_king_bar', uso = 'bkb', why = 'pelear sin ser bloqueado' } },
	},
}
