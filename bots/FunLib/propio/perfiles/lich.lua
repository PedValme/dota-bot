-- dota-bot's own bot: Lich's build profile (trabajo/build-estrategica.md), position 5. A fixed core, then points where the enemies
-- decide: in each, the first candidate whose rule holds wins, the last one is the default. `uso` names the rule that uses the item
-- (build.lua's USES): an active item with none is never bought, so no Glimmer, Urn, Spirit Vessel, Pipe or Solar Crest (OHA's pos 5)
-- until they have a rule.
return {
	-- Core: intelligence Treads for the mana Frost Blast spends, then the Force Staff (the 'pike' rule pushes it home when leaving).
	core = { 'item_power_treads', 'item_force_staff' },
	points = {
		-- Aether Lens before the Scepter: its cast range keeps Frost Blast and the shield out of the enemy's reach. Against a team built
		-- on magic or lock, the Black King Bar first: a stunned support shields no one.
		{ name = 'A',
			{ item = 'item_black_king_bar', uso = 'bkb', when = function(t) return t.magia >= 3 or t.control >= 4 end, why = 'mucha magia o control' },
			{ item = 'item_aether_lens', uso = 'pasivo', why = 'alcance de lanzamiento' } },
		{ name = 'Aether', { item = 'item_aether_lens', uso = 'pasivo', why = 'alcance de lanzamiento' } },
		-- The Scepter improves Chain Frost by itself (no active to press).
		{ name = 'Scepter', { item = 'item_ultimate_scepter', uso = 'pasivo', why = 'chain frost mejorado' } },
		{ name = 'Octarine', { item = 'item_octarine_core', uso = 'pasivo', why = 'menos enfriamiento' } },
	},
}
